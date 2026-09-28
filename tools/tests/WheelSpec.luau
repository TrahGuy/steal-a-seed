--!nocheck
--==============================================================================
-- Steal a Seed :: WheelSpec
--
-- The obby reward wheel (2026-09-27), everything that can be driven without a
-- Play session:
--
--   1. the prizes    WheelData: twelve prizes, their weights and sectors, the
--                    roll, the trail's swap, the landing point, every final
--                    outcome's exact odds, and the words each sector prints
--                    against what it pays; and the wheel as DRAWN (the approved
--                    mockup's readable sectors, where a spin comes to rest on
--                    them, the rarity words and each pod's species odds)
--   2. the save      ProfileSchema's wheel fields: defaults, migration by
--                    absence, and a mangled save read back to something
--                    WheelService could have written
--   3. earning       the REAL WheelService.AwardCompletion against stand-ins and
--                    a clock the spec turns: five per 24-hour window from the
--                    first spin earned, the boundary second, time offline, a new
--                    server, a completion credited once, spending that never
--                    refills, bought spins that never count
--   4. spinning      the REAL spin: all twelve delivered through their own
--                    faucets, the trail's swap, a full bag, a failed save, a
--                    second request mid-spin, an error mid-spin, forged payloads,
--                    the trail worn and taken off
--   5. paid spins    the (unconfigured) product and PolicyService's answer:
--                    never spent without both, never silently
--
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("WheelSpec"))
--
-- The stand-ins only RECORD, so what was paid, through which faucet and how
-- often is the evidence. WheelService's own Studio seams stand in the clock
-- (useClock), force a prize (DebugForce) and hear the answers (useReply); none
-- of them has a remote.
--
-- Not here: the panel, the animation, the world wheel, the OBBY button's
-- teleport (ObbySpec, PlotTeleportSpec), a real receipt (StoreSpec), and two
-- people at once (Play).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local A = WheelData.Attributes
local DAY = WheelData.Daily
local R = WheelData.Rewards
local B = WheelData.ById

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

local function sourceOf(instance)
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok then src else ""
end

--==============================================================================
-- 1. THE PRIZES
--==============================================================================
say("-- 1. the prizes --")
local total = 0
local kinds = {}
for _, r in ipairs(R) do
	total += r.weight
	kinds[r.kind] = (kinds[r.kind] or 0) + 1
end
check(#R == 12 and total == 10000 and WheelData.TotalWeight == 10000,
	"twelve prizes whose weights add to exactly 10,000 -- 100%", string.format("%d prizes, %d", #R, total))
check(kinds.cash == 3 and kinds.speed == 2 and kinds.pod == 4 and kinds.boost == 2 and kinds.trail == 1,
	"three cash prizes, two Speed, four pods (regular, Rare, Titan, Colossal), two boosts and the trail")
check(B.cash_small.amount < B.cash_medium.amount and B.cash_medium.amount < B.cash_jackpot.amount
	and B.speed_small.amount < B.speed_large.amount, "small, medium and jackpot cash; small and large Speed")
check(B.pod_colossal.weight < B.pod_titan.weight, "the Colossal pod is rarer than the Titan pod",
	B.pod_colossal.weight .. " vs " .. B.pod_titan.weight)
local rarest = true
for _, r in ipairs(R) do
	if r ~= B.trail and r.weight <= B.trail.weight then
		rarest = false
	end
end
check(rarest, "and the Bloomrunner Trail is the rarest prize of all", B.trail.weight)
check(B.pod_titan.tier == 6 and B.pod_colossal.tier == 7 and SeedData.Tier(6).name == "Titan"
	and SeedData.Tier(7).name == "Colossal", "the Titan and Colossal pods carry their size tiers, 6 and 7")

local poolsOk = true
for _, id in ipairs(WheelData.Pools.rare) do
	if SeedData.Get(id).Rarity ~= "Rare" then
		poolsOk = false
	end
end
for _, id in ipairs(WheelData.Pools.common) do
	local rarity = SeedData.Get(id).Rarity
	if rarity ~= "Common" and rarity ~= "Uncommon" then
		poolsOk = false
	end
end
check(poolsOk and B.pod_rare.pool == "rare" and B.pod_common.pool == "common" and B.pod_titan.pool == "common"
	and B.pod_colossal.pool == "common",
	"the Rare pod holds only Rare species; the regular, Titan and Colossal pods only Common and Uncommon ones")

-- What each sector prints is what it pays.
local wordsOk, wrong = true, ""
for _, r in ipairs(R) do
	if r.kind == "cash" and r.label ~= "$" .. WheelData.commas(r.amount) then
		wordsOk, wrong = false, wrong .. " " .. r.id
	elseif r.kind == "speed" and r.label ~= "+" .. WheelData.commas(r.amount) .. " SPEED" then
		wordsOk, wrong = false, wrong .. " " .. r.id
	end
end
check(wordsOk, "every cash and Speed sector prints exactly the amount it pays", wrong)
local chest = GameConfig.BonusChest
local income, training = GameConfig.bonusChestReward("income"), GameConfig.bonusChestReward("training")
check(income and training and B.boost_income.boost == "income" and B.boost_training.boost == "training"
	and B.boost_income.label == string.format("+%d%% INCOME", math.floor((income.Multiplier - 1) * 100 + 0.5))
	and B.boost_income.title:find(string.format("for %d min", chest.BoostSeconds // 60), 1, true) ~= nil,
	"the boost prizes are the Bonus Chest's own boosts, named from its own numbers",
	B.boost_income.label .. " / " .. B.boost_income.title)
check(WheelData.Product.Enabled == false and WheelData.Product.ProductId == 0 and WheelData.Product.Quantity == 0,
	"the spin pack is disabled, with no product id and no pack size")

-- The sectors: in prize order, each exactly its share of the circle.
local sectors = WheelData.sectors()
local shapeOk = #sectors == 12 and math.abs(sectors[1].start) < 1e-9 and math.abs(sectors[12].finish - 360) < 1e-9
for i, s in ipairs(sectors) do
	if s.reward ~= R[i] or math.abs((s.finish - s.start) - s.reward.weight / 10000 * 360) > 1e-9
		or (i > 1 and math.abs(s.start - sectors[i - 1].finish) > 1e-9) then
		shapeOk = false
	end
end
check(shapeOk, string.format("the sectors run round the wheel in prize order, each exactly its share of 360 degrees "
	.. "(the trail a %.2f-degree sliver, never an equal slice)", sectors[12].finish - sectors[12].start))

-- The roll: every whole pick 1..10,000 lands on one prize, each on its weight.
local counts = {}
for pick = 1, 10000 do
	local r = WheelData.prizeAt(pick)
	counts[r.id] = (counts[r.id] or 0) + 1
end
local exact = true
for _, r in ipairs(R) do
	if counts[r.id] ~= r.weight then
		exact = false
	end
end
check(exact, "each of the 10,000 picks lands on exactly one prize, and each prize on exactly its weight")
check(WheelData.prizeAt(2200) == B.cash_small and WheelData.prizeAt(2201) == B.speed_small
	and WheelData.prizeAt(9960) == B.pod_colossal and WheelData.prizeAt(9961) == B.trail
	and WheelData.prizeAt(10000) == B.trail, "the boundaries fall where the weights put them")
check(WheelData.prizeAt(0) == B.cash_small and WheelData.prizeAt(-7) == B.cash_small
	and WheelData.prizeAt(10001) == B.trail, "a pick out of range is clamped onto the wheel, never nothing")

-- The trail's swap, for its owners only.
local paid, swapped = WheelData.resolve(B.trail, true)
local mine, notSwapped = WheelData.resolve(B.trail, false)
local othersSame = true
for _, r in ipairs(R) do
	if r ~= B.trail then
		local p2, s2 = WheelData.resolve(r, true)
		if p2 ~= r or s2 then
			othersSame = false
		end
	end
end
check(paid == B.cash_jackpot and swapped and mine == B.trail and not notSwapped and othersSame,
	"an owner who lands the trail is paid the cash jackpot instead; nobody else, and no other prize, changes")

-- Where the wheel stops: inside the rolled sector, never on a divider.
local inside = true
for _, s in ipairs(sectors) do
	for _, w in ipairs({ -1, 0, 0.05, 0.5, 0.95, 1, 2 }) do
		local a = WheelData.landingAngle(s.reward, w)
		local span = s.finish - s.start
		if a < s.start + span * 0.1 - 1e-9 or a > s.start + span * 0.9 + 1e-9 then
			inside = false
		end
	end
end
check(inside, "the wheel always stops inside the rolled sector, at least a tenth of its width from either edge")

-- The disclosure: every final outcome, adding to exactly 100%.
for _, owns in ipairs({ false, true }) do
	local sum = 0
	for _, o in ipairs(WheelData.outcomes(owns)) do
		sum += o.probability
	end
	check(math.abs(sum - 1) < 1e-12, (if owns then "a trail owner's" else "a new player's")
		.. " list of outcomes adds to exactly 100%", string.format("%.15f", sum))
end
local list = WheelData.outcomes(false)
local podLines, podOk = 0, true
for _, r in ipairs(R) do
	if r.kind == "pod" then
		local pool = WheelData.Pools[r.pool]
		for _, id in ipairs(pool) do
			local species = SeedData.Get(id)
			local found = false
			for _, o in ipairs(list) do
				if o.prize == r.title and o.line:find(species.Name .. " pod", 1, true) == 1
					and o.line:find(species.Rarity .. " species", 1, true) ~= nil
					and o.line:find(SeedData.Tier(r.tier).name .. " size", 1, true) ~= nil
					and math.abs(o.probability - r.weight / 10000 / #pool) < 1e-15 then
					found = true
				end
			end
			if found then
				podLines += 1
			else
				podOk = false
			end
		end
	end
end
check(podOk, string.format("every pod prize lists each species it can hold, with its rarity, its size and its "
	.. "own exact share (%d lines)", podLines))
local ownerTrail = nil
for _, o in ipairs(WheelData.outcomes(true)) do
	if o.prize == B.trail.title then
		ownerTrail = o
	end
end
check(ownerTrail ~= nil and ownerTrail.line:find(B.cash_jackpot.title, 1, true) ~= nil
	and math.abs(ownerTrail.probability - B.trail.weight / 10000) < 1e-15,
	"an owner's list says the trail's slice pays the jackpot instead, at the trail's own odds",
	ownerTrail and ownerTrail.line)
check(WheelData.percent(0.22) == "22%" and WheelData.percent(0.004) == "0.4%" and WheelData.percent(0.0012) == "0.12%"
	and WheelData.percent(0.00625) == "0.625%" and WheelData.percent(0.003) == "0.3%" and WheelData.percent(1) == "100%",
	"odds are printed exactly: 22%, 0.4%, 0.12%, 0.625%",
	WheelData.percent(0.00625) .. " " .. WheelData.percent(0.0012))

-- The averages, for the handoff (not pinned: balance is the owner's).
do
	local cash, speed, pods, boosts = 0, 0, 0, 0
	for _, r in ipairs(R) do
		local share = r.weight / 10000
		if r.kind == "cash" then
			cash += share * r.amount
		elseif r.kind == "speed" then
			speed += share * r.amount
		elseif r.kind == "pod" then
			pods += share
		elseif r.kind == "boost" then
			boosts += share
		end
	end
	say(string.format("  (per spin on average: $%.0f cash ($%.0f for a trail owner), %.0f Speed; a pod %.1f%%, "
		.. "a boost %.1f%%, the trail %s)", cash, cash + B.trail.weight / 10000 * B.cash_jackpot.amount, speed,
		pods * 100, boosts * 100, WheelData.percent(B.trail.weight / 10000)))
end

--==============================================================================
-- 1b. THE WHEEL AS DRAWN (display only, the approved mockup)
--==============================================================================
say("\n-- 1b. the wheel as drawn --")
local shown = WheelData.displaySectors()
local seenIds, drawnOk = {}, #shown == #R
local floor = WheelData.DisplayFloor
for i, s in ipairs(shown) do
	local span = s.finish - s.start
	if seenIds[s.reward.id] or span < floor - 1e-9 or (i > 1 and math.abs(s.start - shown[i - 1].finish) > 1e-9)
		or math.abs(s.mid - (s.start + s.finish) / 2) > 1e-9 then
		drawnOk = false
	end
	seenIds[s.reward.id] = true
end
check(drawnOk and math.abs(shown[1].start) < 1e-9 and math.abs(shown[#shown].finish - 360) < 1e-9,
	string.format("the drawn wheel shows every prize once, end to end round exactly 360 degrees, none under %d degrees",
		floor))
local bySize = true
for _, a in ipairs(shown) do
	for _, b in ipairs(shown) do
		if a.reward.weight < b.reward.weight and (a.finish - a.start) >= (b.finish - b.start) then
			bySize = false
		end
	end
end
local trailShown = 0
for _, s in ipairs(shown) do
	if s.reward == B.trail then
		trailShown = s.finish - s.start
	end
end
check(bySize, string.format("its sizes follow the odds -- a rarer prize is never drawn as big (the trail %.1f "
	.. "degrees, the smallest)", trailShown))
-- The spin comes to rest inside the rolled prize's DRAWN sector, whatever the
-- server's `within`, so the pointer always shows what was won.
local restsOk = true
for _, s in ipairs(shown) do
	for _, w in ipairs({ -1, 0, 0.05, 0.37, 0.5, 0.95, 1, 2 }) do
		local a = WheelData.displayLanding(s.reward, w)
		local span = s.finish - s.start
		local under = nil
		for _, t in ipairs(shown) do
			if a >= t.start and a < t.finish then
				under = t.reward
			end
		end
		if under ~= s.reward or a < s.start + span * 0.1 - 1e-9 or a > s.start + span * 0.9 + 1e-9 then
			restsOk = false
		end
	end
end
check(restsOk, "a spin always comes to rest inside the rolled prize's drawn sector, a tenth in from either edge")

-- Rarity words: real names, strictly by odds.
local namesOk, monotone = true, true
for _, r in ipairs(R) do
	if GameConfig.RarityTier[r.rarity] == nil or type(r.short) ~= "string" or r.short == "" then
		namesOk = false
	end
	for _, other in ipairs(R) do
		if r.weight < other.weight and GameConfig.RarityTier[r.rarity] < GameConfig.RarityTier[other.rarity] then
			monotone = false
		end
	end
end
check(namesOk, "every prize names a rarity the game has (GameConfig.Rarities) and a short name for Reward info")
check(monotone and B.trail.rarity == "Mythic" and B.cash_small.rarity == "Common",
	"the rarity words follow the odds: a rarer prize never carries a lower one (Common $5,000 ... Mythic trail)")
check(B.trail.rainbow == true and B.pod_colossal.note ~= nil and B.pod_colossal.note:find("hidden", 1, true) ~= nil,
	"the trail is the rainbow prize, and the Colossal pod's row says its species stays hidden until it hatches")

-- A pod prize's species, each at its exact share: what the cards print.
local poolsAdd, sortedOk = true, true
for _, r in ipairs(R) do
	local entries = WheelData.poolOdds(r)
	if r.kind == "pod" then
		local sum = 0
		for i, e in ipairs(entries) do
			sum += e.probability
			local species = SeedData.Get(e.id)
			if not species or species.Name ~= e.name or species.Rarity ~= e.rarity
				or math.abs(e.probability - r.weight / 10000 / #WheelData.Pools[r.pool]) > 1e-15 then
				poolsAdd = false
			end
			local nextEntry = entries[i + 1]
			if nextEntry then
				local ta, tb = GameConfig.RarityTier[e.rarity], GameConfig.RarityTier[nextEntry.rarity]
				if ta < tb or (ta == tb and e.name > nextEntry.name) then
					sortedOk = false
				end
			end
		end
		if #entries ~= #WheelData.Pools[r.pool] or math.abs(sum - r.weight / 10000) > 1e-12 then
			poolsAdd = false
		end
	elseif #entries ~= 0 then
		poolsAdd = false
	end
end
check(poolsAdd, "each pod prize's species cards add up to exactly the prize's own odds (Pod "
	.. WheelData.percent(B.pod_common.weight / 10000 / #WheelData.Pools.common) .. " each, Colossal "
	.. WheelData.percent(B.pod_colossal.weight / 10000 / #WheelData.Pools.common) .. " each)")
check(sortedOk, "and they are listed rarest first, then by name")

--==============================================================================
-- 2. THE SAVE
--==============================================================================
say("\n-- 2. the save --")
local d = ProfileSchema.Default()
check(d.WheelEarned == 0 and d.WheelBought == 0 and d.WheelDayAt == 0 and d.WheelDayCount == 0
	and #d.WheelRuns == 0 and #d.WheelPending == 0 and d.WheelSeq == 0 and next(d.Cosmetics) == nil
	and d.EquippedTrail == "", "a new profile has no spins, no window, nothing owed and no trail")
local old = ProfileSchema.Sanitise({ Cash = 10 })
check(old.WheelEarned == 0 and old.WheelDayAt == 0 and #old.WheelPending == 0 and old.EquippedTrail == "",
	"a save from before the wheel reads exactly that: the fields migrate by being absent")
local now = os.time()
local mangled = ProfileSchema.Sanitise({
	WheelEarned = 1e9, WheelBought = -5, WheelDayAt = now + 3600, WheelDayCount = 99, WheelSeq = 7.6,
	WheelRuns = { "a", "", 5, string.rep("x", 65), "b" },
	WheelPending = {
		{ Id = "ok-1", Rolled = "pod_titan", Prize = "pod_titan", Species = "nubkin", Source = "earned", At = now },
		{ Id = "ok-2", Rolled = "trail", Prize = "cash_jackpot", Species = "", Source = "bought", At = now },
		{ Id = "bad-species", Rolled = "pod_rare", Prize = "pod_rare", Species = "nubkin", Source = "earned", At = now },
		{ Id = "bad-prize", Rolled = "megacash", Prize = "megacash", Source = "earned", At = now },
		{ Id = "bad-source", Rolled = "cash_small", Prize = "cash_small", Source = "gift", At = now },
		{ Id = "bad-pair", Rolled = "cash_small", Prize = "pod_colossal", Species = "nubkin", Source = "earned", At = now },
		"junk",
	},
	Cosmetics = { bloomrunner = true, golden = true },
	EquippedTrail = "golden",
})
check(mangled.WheelEarned == WheelData.MaxEarnedHeld and mangled.WheelBought == 0 and mangled.WheelSeq == 7,
	"balances are whole and capped: a billion earned reads as the cap, a negative bought as none")
check(mangled.WheelDayAt <= os.time() and mangled.WheelDayCount <= DAY.Limit,
	"a window cannot have opened in the future, and never holds more than the daily limit",
	mangled.WheelDayAt .. " / " .. mangled.WheelDayCount)
check(#mangled.WheelRuns == 2 and mangled.WheelRuns[1] == "a" and mangled.WheelRuns[2] == "b",
	"only real completion ids are remembered")
check(#mangled.WheelPending == 2 and mangled.WheelPending[1].Id == "ok-1" and mangled.WheelPending[2].Id == "ok-2",
	"an owed prize is kept only if all of it is real and consistent: a pod's species from its own pool, "
		.. "a paid prize that is the one rolled or the trail's replacement, a known source",
	#mangled.WheelPending)
check(mangled.Cosmetics.bloomrunner == true and mangled.Cosmetics.golden == nil and mangled.EquippedTrail == "",
	"only the real trail can be owned, and wearing anything else reads as wearing nothing")
local worn = ProfileSchema.Sanitise({ Cosmetics = { bloomrunner = true }, EquippedTrail = "bloomrunner" })
local unowned = ProfileSchema.Sanitise({ EquippedTrail = "bloomrunner" })
check(worn.EquippedTrail == "bloomrunner" and worn.Cosmetics.bloomrunner == true and unowned.EquippedTrail == "",
	"a worn trail is still worn after a rejoin, and cannot be worn without being owned")
local many = { WheelPending = {} }
for i = 1, 20 do
	table.insert(many.WheelPending, { Id = "r" .. i, Rolled = "cash_small", Prize = "cash_small", Source = "earned",
		At = now })
end
check(#ProfileSchema.Sanitise(many).WheelPending == WheelData.MaxPending, "at most MaxPending prizes are kept owed")
local pdsSource = sourceOf(Server:FindFirstChild("PlayerDataService"))
check(pdsSource:find("WheelBought = profile.WheelBought or 0", 1, true) ~= nil
	and pdsSource:find("WheelPending = table.clone(profile.WheelPending or {})", 1, true) ~= nil
	and pdsSource:find("Cosmetics = table.clone(profile.Cosmetics or {})", 1, true) ~= nil,
	"an admin progress reset keeps bought spins, owed prizes and the trail -- none of them is progress")

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
local function lastArgs(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i].args
		end
	end
	return nil
end

local fakePlayers = {}
local noSignal = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
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
	return p
end

local profiles = {}
local persistent = {}
local saveWorks = true
local saveDelay = 0
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
		local p = profiles[player]
		if not p then
			return false
		end
		return change(p) == true
	end,
	Save = function(player)
		record("Save", player)
		if saveDelay > 0 then
			task.wait(saveDelay)
		end
		return saveWorks
	end,
}
local payThrows = false
local EconomyService = {
	PayReward = function(player, amount, reason)
		record("PayCash", player, amount, reason)
		if payThrows then
			error("spec: the cash faucet threw")
		end
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
local heldRestored = true
local CarryService = {
	IsHeldRestored = function()
		return heldRestored
	end,
	GivePod = function(player, species, tier)
		record("GivePod", player, species, tier)
		table.insert(profiles[player].Held, { Id = species, Tier = tier, Hatched = false })
		return true
	end,
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
		record("build")
		return nil
	end,
}
local policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
local fakePolicy = {}
function fakePolicy:GetPolicyInfoForPlayerAsync(player)
	record("Policy", player)
	if not policyAnswer.ok then
		error("spec: PolicyService is unavailable")
	end
	return policyAnswer.info
end

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	elseif name == "PolicyService" then
		return fakePolicy
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

local clock = 1000000
local replies = {}
local function loadWheel(overrides)
	local W = loadWith(Server:WaitForChild("WheelService"), {
		PlayerDataService = PlayerDataService,
		EconomyService = EconomyService,
		TreadmillService = TreadmillService,
		CarryService = CarryService,
		BonusChestService = BonusChestService,
		Metrics = Metrics,
		WheelModel = WheelModel,
	}, overrides)
	W.Init()
	W.useClock(function()
		return clock
	end)
	W.useReply(function(_, payload)
		table.insert(replies, payload)
	end)
	return W
end
local function last()
	return replies[#replies] or {}
end

local ok, W = pcall(loadWheel)
check(ok, "WheelService loads against the stand-ins", if ok then nil else W)
if not ok then
	return string.format("WheelSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
end

--==============================================================================
-- 3. EARNING: FIVE A WINDOW, FROM THE FIRST SPIN EARNED
--==============================================================================
say("\n-- 3. earning --")
local p1 = makePlayer("SpecEarner", 5101)
profiles[p1] = ProfileSchema.Default()
local prof = profiles[p1]
local opened = clock
local kind, n = W.AwardCompletion(p1, "run-1", 1800)
check(kind == "spin" and n == 1 and prof.WheelEarned == 1 and prof.WheelDayCount == 1 and prof.WheelDayAt == opened
	and count("PaySpeed") == 0, "the first completion earns a spin, pays no Speed, and opens the window that moment",
	string.format("%s %s earned=%d", tostring(kind), tostring(n), prof.WheelEarned))
check(p1:GetAttribute(A.Earned) == 1 and p1:GetAttribute(A.DayCount) == 1
	and p1:GetAttribute(A.DayEndsAt) == opened + DAY.WindowSeconds,
	"the balance, the count and when the window closes are published")
check(count("wheelSpinEarned") == 1 and lastArgs("wheelSpinEarned")[2] == 1, "and analytics heard the spin earned")
kind = W.AwardCompletion(p1, "run-1", 1800)
check(kind == "none" and prof.WheelEarned == 1 and prof.WheelDayCount == 1 and count("PaySpeed") == 0,
	"the same completion again -- a repeated finish touch -- earns nothing and pays nothing")
for i = 2, 5 do
	clock += 600
	W.AwardCompletion(p1, "run-" .. i, 1800)
end
check(prof.WheelEarned == 5 and prof.WheelDayCount == 5 and prof.WheelDayAt == opened,
	"completions two to five earn one each, in the same window")
clock += 600
table.clear(trace)
kind, n = W.AwardCompletion(p1, "run-6", 1800)
local sixth = lastArgs("PaySpeed")
check(kind == "speed" and n == 1800 and count("PaySpeed") == 1 and sixth and sixth[2] == 1800
	and prof.WheelEarned == 5 and prof.WheelDayCount == 5,
	"the sixth pays the run's own Speed instead -- never both, never neither", string.format("%s %s", kind, tostring(n)))

-- Spending never refills the allowance.
for _ = 1, 3 do
	W.DebugForce(p1, "cash_small")
	W.Spin(p1, "earned")
end
kind = W.AwardCompletion(p1, "run-7", 1800)
check(prof.WheelEarned == 2 and prof.WheelDayCount == 5 and kind == "speed",
	"spending three spins gives nothing back: the window is still full and the next run pays Speed")
-- Bought spins never touch it.
check(W.GrantBought(p1, 4) and prof.WheelBought == 4 and prof.WheelDayCount == 5,
	"four bought spins land in their own balance and change nothing about the allowance")
check(not W.GrantBought(p1, 0) and not W.GrantBought(p1, -3) and not W.GrantBought(p1, 0 / 0)
	and not W.GrantBought(p1, WheelData.MaxBoughtHeld) and prof.WheelBought == 4,
	"a grant of nothing, of a negative, of not-a-number or past the cap lands nothing")

-- The boundary second.
clock = opened + DAY.WindowSeconds - 1
kind = W.AwardCompletion(p1, "run-8", 1800)
check(kind == "speed" and prof.WheelDayCount == 5, "one second before the window closes it is still full")
clock = opened + DAY.WindowSeconds
kind, n = W.AwardCompletion(p1, "run-9", 1800)
check(kind == "spin" and n == 1 and prof.WheelDayAt == clock and prof.WheelDayCount == 1,
	"the second it closes, the next completion earns again and opens a new window from then")
check(prof.WheelEarned == 3, "and the spins left from the last window are all still there -- a reset takes none away",
	prof.WheelEarned)

-- Two completions in the same instant at 4/5: exactly one more spin.
local p2 = makePlayer("SpecRace", 5102)
profiles[p2] = ProfileSchema.Default()
for i = 1, 4 do
	W.AwardCompletion(p2, "race-" .. i, 900)
end
local first, second = W.AwardCompletion(p2, "race-a", 900), W.AwardCompletion(p2, "race-b", 900)
check(first == "spin" and second == "speed" and profiles[p2].WheelDayCount == 5 and profiles[p2].WheelEarned == 5,
	"two completions landing together at 4/5: one spin and one Speed, never six", first .. " / " .. second)
local wheelSource = sourceOf(Server:FindFirstChild("WheelService"))
local award = wheelSource:match("function WheelService%.AwardCompletion(.-)\nend\n") or ""
local inner = award:match("UpdateWheel%(player, function%(p: Profile%): boolean(.-)\n\t\tend%)") or ""
check(#inner > 0 and not inner:find("task%.") and not inner:find("Save") and not inner:find("wait")
	and award:find("task.spawn(PlayerDataService.Save, player)", 1, true) ~= nil,
	"and nothing can come between the count and the grant: the step never yields, the save is spawned after it")

-- A new server, the same save: the window goes on; time offline counts.
local copy = ProfileSchema.Sanitise(prof)
local p3 = makePlayer("SpecEarner", 5101)
profiles[p3] = copy
local W2 = loadWheel()
local windowAt = copy.WheelDayAt
clock = windowAt + 10 * 3600
for i = 1, 4 do
	W2.AwardCompletion(p3, "s2-" .. i, 1800)
end
check(copy.WheelDayAt == windowAt and copy.WheelDayCount == 5 and copy.WheelEarned == prof.WheelEarned + 4,
	"on another server ten hours later, from the saved profile, the same window goes on to 5/5")
kind = W2.AwardCompletion(p3, "s2-5", 1800)
check(kind == "speed", "and then pays Speed: rejoining or changing servers restarts nothing")
kind = W2.AwardCompletion(p3, "run-9", 1800)
check(kind == "none", "a completion the old server credited is still known here")
clock = windowAt + DAY.WindowSeconds + 3 * 24 * 3600
kind, n = W2.AwardCompletion(p3, "s2-6", 1800)
check(kind == "spin" and n == 1 and copy.WheelDayAt == clock,
	"three days offline: the window closed while they were away, and they earn again at once")

-- A profile that cannot save earns no spin: the run pays its Speed.
local p4 = makePlayer("SpecTemporary", 5104)
profiles[p4] = ProfileSchema.Default()
persistent[p4] = false
table.clear(trace)
kind = W.AwardCompletion(p4, "t-1", 1800)
check(kind == "speed" and count("PaySpeed") == 1 and profiles[p4].WheelEarned == 0,
	"a profile that is not saving (DataStores down) is paid the Speed, not a spin it could lose")
persistent[p4] = nil

--==============================================================================
-- 4. SPINNING
--==============================================================================
say("\n-- 4. spinning --")
local nobody = makePlayer("SpecNobody", 5105)
table.clear(replies)
W.Spin(nobody, "earned")
check(last().ok == false and last().reason == "NOT_READY", "no profile yet: NOT_READY", last().reason)
local empty = makePlayer("SpecEmpty", 5106)
profiles[empty] = ProfileSchema.Default()
W.Spin(empty, "earned")
check(last().ok == false and last().reason == "NO_SPINS" and #profiles[empty].WheelPending == 0,
	"no spins: NO_SPINS, and nothing rolled", last().reason)

local sp = makePlayer("SpecSpinner", 5107)
profiles[sp] = ProfileSchema.Default()
local pr = profiles[sp]
pr.WheelEarned = 40
for _, r in ipairs(R) do
	table.clear(trace)
	table.clear(replies)
	local before = { cash = pr.Cash, speed = pr.Speed, earned = pr.WheelEarned, held = #pr.Held }
	W.DebugForce(sp, r.id)
	W.Spin(sp, "earned")
	local rep = last()
	local good = rep.ok == true and rep.rolled == r.id and rep.prize == r.id and rep.swapped == false
		and rep.owed == false and rep.source == "earned" and type(rep.within) == "number"
		and rep.within >= 0 and rep.within < 1 and rep.species == nil
		and pr.WheelEarned == before.earned - 1 and #pr.WheelPending == 0 and count("Save") >= 1
		and count("wheelSpun") == 1 and lastArgs("wheelSpun")[2] == r.id
	local how = r.kind
	if r.kind == "cash" then
		local pay = lastArgs("PayCash")
		good = good and count("PayCash") == 1 and pay[2] == r.amount and pr.Cash == before.cash + r.amount
			and count("PaySpeed") == 0
		how = "the cash faucet, $" .. WheelData.commas(r.amount)
	elseif r.kind == "speed" then
		local pay = lastArgs("PaySpeed")
		good = good and count("PaySpeed") == 1 and pay[2] == r.amount and pr.Speed == before.speed + r.amount
			and count("PayCash") == 0
		how = "the Speed faucet, +" .. WheelData.commas(r.amount)
	elseif r.kind == "boost" then
		good = good and count("GrantBoost") == 1 and lastArgs("GrantBoost")[2] == r.boost
		how = "the Bonus Chest's " .. r.boost .. " boost"
	elseif r.kind == "pod" then
		local give = lastArgs("GivePod")
		good = good and count("GivePod") == 1 and give[3] == r.tier and table.find(WheelData.Pools[r.pool], give[2]) ~= nil
			and #pr.Held == before.held + 1
		how = string.format("a %s pod from the %s pool", SeedData.Tier(r.tier).name, r.pool)
	elseif r.kind == "trail" then
		good = good and pr.Cosmetics.bloomrunner == true and pr.EquippedTrail == "bloomrunner"
			and sp:GetAttribute(A.TrailOwned) == true and sp:GetAttribute(A.Trail) == "bloomrunner"
		how = "owned, and worn at once"
	end
	check(good, string.format("%s: recorded, saved, delivered once (%s), answered", r.title, how),
		string.format("ok=%s rolled=%s prize=%s", tostring(rep.ok), tostring(rep.rolled), tostring(rep.prize)))
end

-- The trail again, now owned: the jackpot, and the answer says why.
table.clear(trace)
table.clear(replies)
W.DebugForce(sp, "trail")
W.Spin(sp, "earned")
check(last().ok and last().rolled == "trail" and last().prize == "cash_jackpot" and last().swapped == true
	and count("PayCash") == 1 and lastArgs("PayCash")[2] == B.cash_jackpot.amount,
	"an owner who lands the trail is paid the $75,000 jackpot, and the answer says it was swapped")

-- A pod's species: forced within its pool, never outside it.
table.clear(trace)
W.DebugForce(sp, "pod_titan", "paddlehop")
W.Spin(sp, "earned")
local titan = lastArgs("GivePod")
W.DebugForce(sp, "pod_rare", "nubkin")
W.Spin(sp, "earned")
local rare = lastArgs("GivePod")
check(titan and titan[2] == "paddlehop" and titan[3] == 6 and rare and rare[3] == 2
	and table.find(WheelData.Pools.rare, rare[2]) ~= nil,
	"a Titan pod is always Titan-sized, and a Rare pod always a Rare species -- even when told otherwise",
	rare and rare[2])

-- A full bag: owed, never discarded.
while #pr.Held < GameConfig.Save.MaxHeld do
	table.insert(pr.Held, { Id = "nubkin", Tier = 1, Hatched = false })
end
table.clear(trace)
table.clear(replies)
W.DebugForce(sp, "pod_colossal")
W.Spin(sp, "earned")
check(last().ok and last().owed == true and #pr.WheelPending == 1 and count("GivePod") == 0
	and sp:GetAttribute(A.Pending) == 1,
	"a pod won with a full bag is kept owed on the saved profile -- recorded, saved, never discarded")
local owedRow = pr.WheelPending[1]
check(owedRow and owedRow.Prize == "pod_colossal" and table.find(WheelData.Pools.common, owedRow.Species) ~= nil
	and owedRow.Source == "earned", "the owed row names the prize, its species and where the spin came from")
table.clear(replies)
W.Claim(sp)
check(last().claim == true and last().ok == false and last().reason == "NO_ROOM" and #pr.WheelPending == 1,
	"CLAIM with the bag still full: told NO_ROOM, nothing lost")
table.remove(pr.Held)
table.clear(trace)
table.clear(replies)
W.Claim(sp)
local handed = lastArgs("GivePod")
check(last().ok == true and #pr.WheelPending == 0 and count("GivePod") == 1 and handed and handed[3] == 7
	and handed[2] == owedRow.Species, "with room it is handed over: the same species, still Colossal")

-- A bag not yet restored (mid-respawn): owed, then paid by the timer's pass.
heldRestored = false
table.clear(replies)
W.DebugForce(sp, "pod_common")
W.Spin(sp, "earned")
check(last().owed == true and #pr.WheelPending == 1, "a pod won while the bag is between bodies waits owed")
heldRestored = true
while #pr.Held >= GameConfig.Save.MaxHeld do
	table.remove(pr.Held)
end
local landed, left = W.DeliverPending(sp)
check(landed == 1 and left == 0 and #pr.WheelPending == 0, "and the next delivery pass hands it over")

-- Too much owed: no more spins until it is claimed.
heldRestored = false
for i = 1, WheelData.MaxPending do
	table.insert(pr.WheelPending, { Id = "cap-" .. i, Rolled = "pod_common", Prize = "pod_common", Species = "nubkin",
		Source = "earned", At = clock })
end
local earnedBefore = pr.WheelEarned
table.clear(replies)
W.Spin(sp, "earned")
check(last().reason == "PENDING_FULL" and pr.WheelEarned == earnedBefore,
	"with MaxPending prizes owed a spin is refused, and nothing is taken")
heldRestored = true
while #pr.Held > 0 do
	table.remove(pr.Held)
end
W.DeliverPending(sp)
while #pr.Held > 0 do
	table.remove(pr.Held)
end

-- A save that fails: put back exactly, and said so.
saveWorks = false
local e0, c0 = pr.WheelEarned, pr.Cash
table.clear(trace)
table.clear(replies)
W.DebugForce(sp, "cash_jackpot")
W.Spin(sp, "earned")
saveWorks = true
check(last().ok == false and last().reason == "SAVE_FAILED" and pr.WheelEarned == e0 and pr.Cash == c0
	and #pr.WheelPending == 0 and count("PayCash") == 0,
	"a spin whose save fails is put back exactly and says so: nothing used, nothing won")
persistent[sp] = false
table.clear(replies)
W.Spin(sp, "earned")
check(last().reason == "NOT_SAVED" and pr.WheelEarned == e0, "a profile that is not saving cannot spin at all")
persistent[sp] = nil

-- One spin at a time: a second request while the first is saving.
saveDelay = 0.3
table.clear(replies)
W.DebugForce(sp, "cash_small")
task.spawn(W.Spin, sp, "earned")
W.Spin(sp, "earned")
local secondAnswer = replies[1]
task.wait(0.6)
saveDelay = 0
check(secondAnswer and secondAnswer.ok == false and secondAnswer.reason == "BUSY" and #replies == 2
	and replies[2].ok == true and pr.WheelEarned == e0 - 1,
	"a second request while a spin is saving is refused BUSY, and the first finishes normally: one spin used")

-- An error after the save: the prize stays owed, the player is not locked out.
payThrows = true
local e1 = pr.WheelEarned
table.clear(replies)
W.DebugForce(sp, "cash_small")
W.Spin(sp, "earned")
payThrows = false
check(last().ok == false and last().reason == "FAILED" and #pr.WheelPending == 1 and pr.WheelEarned == e1 - 1,
	"an error after the save leaves the prize owed and says so -- never \"nothing was used\"")
table.clear(replies)
W.DebugForce(sp, "speed_small")
W.Spin(sp, "earned")
check(last().ok == true and #pr.WheelPending == 0, "and the next spin works, paying the owed prize with it")

-- Forged requests choose nothing.
local forgedOk = true
for _, forged in ipairs({ { prize = "trail" }, "trail", 99, true, { amount = 1e9 } }) do
	table.clear(replies)
	W.DebugForce(sp, "cash_small")
	W.Spin(sp, forged)
	if not (last().ok and last().rolled == "cash_small" and last().source == "earned") then
		forgedOk = false
	end
end
check(forgedOk, "a request naming a prize, an amount or anything else is just a spin: the server's roll decides")
local handler = wheelSource:match("remote%.OnServerEvent:Connect%((function.-)\n\t\tend%)%)") or ""
check(handler:find("spin(player, payload)", 1, true) ~= nil and handler:find("claim(player)", 1, true) ~= nil
	and handler:find("equip(player, payload)", 1, true) ~= nil and not handler:find("DebugForce", 1, true)
	and not handler:find("useClock", 1, true) and not handler:find("GrantBought", 1, true),
	"the remote reaches spin, claim and equip only: no forcing, no clock, no spins granted")
local seamsOk = true
for _, seam in ipairs({ "useClock", "DebugForce", "useReply" }) do
	local body = wheelSource:match("function WheelService%." .. seam .. "(.-)\nend\n") or ""
	if not body:find("^%([^\n]*%)[^\n]*\n\tif not RunService:IsStudio%(%)") then
		seamsOk = false
	end
end
check(seamsOk, "and the test seams refuse outside Studio")

-- The trail: worn, taken off, and never worn without owning it.
W.Equip(sp, false)
local off = pr.EquippedTrail == "" and sp:GetAttribute(A.Trail) == nil
W.Equip(sp, true)
local on = pr.EquippedTrail == "bloomrunner" and sp:GetAttribute(A.Trail) == "bloomrunner"
W.Equip(empty, true)
check(off and on and profiles[empty].EquippedTrail == "" and empty:GetAttribute(A.Trail) == nil,
	"the trail comes off and goes back on for its owner, and cannot be put on by anybody else")

--==============================================================================
-- 5. PAID SPINS
--==============================================================================
say("\n-- 5. paid spins --")
local buyer = makePlayer("SpecBuyer", 5110)
profiles[buyer] = ProfileSchema.Default()
local bp = profiles[buyer]
bp.WheelBought = 2
policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
W.CheckPolicy(buyer)
check(buyer:GetAttribute(A.PaidAllowed) == nil and not W.PaidAllowed(buyer),
	"as shipped -- no product configured -- paid spins are off even for an eligible account")
table.clear(replies)
W.Spin(buyer, "bought")
local refusedBought = last().reason
W.Spin(buyer, "earned")
check(refusedBought == "PAID_UNAVAILABLE" and last().reason == "NO_SPINS" and bp.WheelBought == 2,
	"a bought spin is refused, and asking for an earned one never falls back to a bought one",
	tostring(refusedBought) .. " / " .. tostring(last().reason))

local live = setmetatable({ Product = { Enabled = true, ProductId = 990003, Quantity = 5 } }, { __index = WheelData })
local liveOk, WP = pcall(loadWheel, { WheelData = live })
check(liveOk, "a copy that sees a configured, enabled product loads", if liveOk then nil else WP)
if liveOk then
	WP.CheckPolicy(buyer)
	check(buyer:GetAttribute(A.PaidAllowed) == true and WP.PaidAllowed(buyer),
		"configured, and PolicyService says this account may: paid spins are allowed")
	table.clear(replies)
	WP.Spin(buyer, "earned")
	check(last().ok == false and last().reason == "CONFIRM_BOUGHT" and bp.WheelBought == 2,
		"with only bought spins left, SPIN asks first and spends nothing")
	WP.DebugForce(buyer, "cash_small")
	WP.Spin(buyer, "bought")
	check(last().ok == true and last().source == "bought" and bp.WheelBought == 1 and bp.WheelDayCount == 0,
		"a yes spends exactly one bought spin, and never touches the daily allowance")
	bp.WheelEarned = 1
	WP.DebugForce(buyer, "cash_small")
	WP.Spin(buyer, "earned")
	check(last().source == "earned" and bp.WheelEarned == 0 and bp.WheelBought == 1, "earned spins are spent first")

	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
	WP.CheckPolicy(buyer)
	table.clear(replies)
	WP.Spin(buyer, "bought")
	local restricted = last().reason
	WP.Spin(buyer, "earned")
	check(buyer:GetAttribute(A.PaidAllowed) == nil and restricted == "PAID_UNAVAILABLE" and last().reason == "NO_SPINS"
		and bp.WheelBought == 1, "an account restricted from paid random items can neither spend a bought spin "
		.. "nor be asked to", tostring(restricted))
	bp.WheelEarned = 1
	WP.DebugForce(buyer, "cash_small")
	WP.Spin(buyer, "earned")
	check(last().ok == true, "while its earned spins still spin: the free path never depends on the policy")

	policyAnswer = { ok = false }
	WP.CheckPolicy(buyer)
	local failed = WP.PaidAllowed(buyer)
	policyAnswer = { ok = true, info = {} }
	WP.CheckPolicy(buyer)
	check(not failed and not WP.PaidAllowed(buyer) and buyer:GetAttribute(A.PaidAllowed) == nil,
		"a policy check that fails, or answers without the field, counts as \"may not\"")
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WP.useClock(nil)
	WP.useReply(nil)
end

-- The panel's side of it (WheelUI's source): no BUY anywhere, the question
-- before a bought spin, every odd read from WheelData, and the wheel it turns
-- landing on the drawn sector.
local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local ui = sourceOf(scripts and scripts:FindFirstChild("WheelUI"))
local fires = select(2, ui:gsub("FireServer%(", ""))
check(ui ~= "" and not ui:find("PromptProductPurchase", 1, true) and not ui:find("MarketplaceService", 1, true)
	and not ui:upper():find("\"BUY", 1, true),
	"the panel opens no purchase prompt and shows no BUY button")
check(ui:find("remote:FireServer(ACT.Spin, source)", 1, true) ~= nil and ui:find("send(\"bought\")", 1, true) ~= nil
	and ui:find("showConfirm(true)", 1, true) ~= nil and fires == 2,
	"it sends one word to spin -- \"bought\" only from the yes of the question naming it -- and CLAIM", fires)
check(ui:find("WheelData.percent(reward.weight / WheelData.TotalWeight)", 1, true) ~= nil
	and ui:find("WheelData.poolOdds(row.reward)", 1, true) ~= nil
	and ui:find("WheelData.percent(entry.probability)", 1, true) ~= nil
	and not ui:find("%d+%.?%d*%%\"") and not ui:find("%d%%%%"),
	"Reward info prints every prize's and every species' odds from WheelData, and types none in")
check(ui:find("WheelData.displayLanding(rolled, within)", 1, true) ~= nil
	and ui:find("WheelData.displaySectors()", 1, true) ~= nil and not ui:find("landingAngle", 1, true),
	"and the spin stops on the rolled prize's drawn sector, at the server's own point in it")

W.useClock(nil)
W.useReply(nil)
W2.useClock(nil)
W2.useReply(nil)
return string.format("WheelSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
