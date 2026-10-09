--!nocheck
--==============================================================================
-- Steal a Seed :: WheelSpec
--
-- The obby reward wheel (2026-09-27), everything that can be driven without a
-- Play session:
--
--   1. the prizes    WheelData: thirteen prizes, their weights and sectors, the
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
--   5. paid spins    the three packs, switched ON as shipped (2026-10-01) and off
--                    on a copy, and PolicyService's
--                    answer: never bought or spent without both, never silently;
--                    and where the panel stands GET SPINS, its card and the
--                    question on 26 screens (its own layout code, run here)
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
-- Not here: the panel drawn, the animation, the world wheel, the OBBY button's
-- teleport (ObbySpec, PlotTeleportSpec), a receipt (StoreSpec; end to end with
-- the real WheelService in SpinPurchaseSpec), and two people at once (Play).
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
check(#R == 13 and total == 10000 and WheelData.TotalWeight == 10000,
	"thirteen prizes whose weights add to exactly 10,000 -- 100%", string.format("%d prizes, %d", #R, total))
check(kinds.cash == 3 and kinds.speed == 2 and kinds.pod == 4 and kinds.boost == 2 and kinds.trail == 1
		and kinds.invite == 1,
	"three cash prizes, two Speed, four pods (regular, Rare, Titan, Colossal), two boosts, the trail and the invite plant")
check(B.invite.weight == 20 and B.cash_small.weight == 2180,
	"the invite plant's 20 in 10,000 (0.2%) came off the small cash prize (2200 -> 2180)")
check(B.cash_small.amount < B.cash_medium.amount and B.cash_medium.amount < B.cash_jackpot.amount
	and B.speed_small.amount < B.speed_large.amount, "small, medium and jackpot cash; small and large Speed")
check(B.pod_colossal.weight < B.pod_titan.weight, "the Colossal pod is rarer than the Titan pod",
	B.pod_colossal.weight .. " vs " .. B.pod_titan.weight)
local rarest = true
for _, r in ipairs(R) do
	if (r ~= B.invite and r.weight <= B.invite.weight)
		or (r ~= B.trail and r ~= B.invite and r.weight <= B.trail.weight) then
		rarest = false
	end
end
check(rarest, "the invite plant is the rarest prize of all (0.2%), then the Bloomrunner Trail (0.4%)",
	B.invite.weight .. " / " .. B.trail.weight)
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
-- PAID SPINS AS SHIPPED: switched ON by the owner on 2026-10-01, with paid
-- random items declared in the questionnaire and sales outside the game off
-- (KB/HANDOFF.md, the paid-spins entries). This check is the tripwire that
-- switching it off again has to pass on purpose.
check(WheelData.Paid.Enabled == true and WheelData.paidLive() == true,
	"as shipped, paid spins are switched ON (the owner's word, 2026-10-01)")
-- THE THREE SPIN-TICKET PACKS (2026-10-01), and the two first products retired.
-- (In a block: this file is at Luau's 200 locals; P1 and P10 stay, as before.)
local P1, P10 = WheelData.ProductByKey.spin1, WheelData.ProductByKey.spin10
do
local P5 = WheelData.ProductByKey.spin5
check(#WheelData.Products == 3 and P1 ~= nil and P5 ~= nil and P10 ~= nil
		and WheelData.Products[1] == P1 and WheelData.Products[2] == P5 and WheelData.Products[3] == P10
		and P1.productId == 3715745320 and P1.spins == 1 and P1.robux == 19 and P1.icon == 74250574261417
		and P5.productId == 3715745407 and P5.spins == 5 and P5.robux == 85 and P5.icon == 129968452678126
		and P10.productId == 3715745552 and P10.spins == 10 and P10.robux == 180 and P10.icon == 109596534013386
		and WheelData.ProductById[3715745320] == P1 and WheelData.ProductById[3715745407] == P5
		and WheelData.ProductById[3715745552] == P10,
	"three spin-ticket packs, the owner's: x1 (3715745320) grants 1, x5 (3715745407) 5, x10 (3715745552) 10")
local R1, R10 = WheelData.RetiredProducts[1], WheelData.RetiredProducts[2]
check(#WheelData.RetiredProducts == 2 and R1.productId == 3715369823 and R1.spins == 1
		and R10.productId == 3715370108 and R10.spins == 10
		and WheelData.ProductById[3715369823] == nil and WheelData.ProductById[3715370108] == nil
		and WheelData.ProductByKey[R1.key] == nil and WheelData.ProductByKey[R10.key] == nil
		and #WheelData.receiptProducts() == 5,
	"the two first products are retired: never sold or asked for by key, still named for their receipts")
local bestTag = false
for _, product in ipairs(WheelData.Products) do
	for field in pairs(product) do
		if string.find(string.lower(tostring(field)), "best", 1, true) then
			bestTag = true
		end
	end
end
check(not bestTag and P5.robux * 2 < P10.robux,
	"no pack is marked the best value -- at the list prices two x5 cost less than one x10")
end
check(WheelData.Actions.Buy == "WheelBuy" and WheelData.Paid.PromptCooldown >= 1,
	"buying has a verb of its own, and a wait between two prompts")
check(WheelData.MaxBoughtHeld >= 10 and WheelData.Daily.Limit == 5,
	"a bought balance has a ceiling of its own; the daily allowance is still five EARNED spins")

-- The sectors: in prize order, each exactly its share of the circle.
local sectors = WheelData.sectors()
local shapeOk = #sectors == #R and math.abs(sectors[1].start) < 1e-9 and math.abs(sectors[#R].finish - 360) < 1e-9
for i, s in ipairs(sectors) do
	if s.reward ~= R[i] or math.abs((s.finish - s.start) - s.reward.weight / 10000 * 360) > 1e-9
		or (i > 1 and math.abs(s.start - sectors[i - 1].finish) > 1e-9) then
		shapeOk = false
	end
end
check(shapeOk, string.format("the sectors run round the wheel in prize order, each exactly its share of 360 degrees "
	.. "(the trail a %.2f-degree sliver, never an equal slice)",
	sectors[table.find(R, B.trail) or 1].finish - sectors[table.find(R, B.trail) or 1].start))

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
check(WheelData.prizeAt(2180) == B.cash_small and WheelData.prizeAt(2181) == B.speed_small
	and WheelData.prizeAt(9940) == B.pod_colossal and WheelData.prizeAt(9941) == B.trail
	and WheelData.prizeAt(9980) == B.trail and WheelData.prizeAt(9981) == B.invite
	and WheelData.prizeAt(10000) == B.invite, "the boundaries fall where the weights put them")
check(WheelData.prizeAt(0) == B.cash_small and WheelData.prizeAt(-7) == B.cash_small
	and WheelData.prizeAt(10001) == B.invite, "a pick out of range is clamped onto the wheel, never nothing")

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
	-- No Backpack: WheelService's Spin Ticket has nowhere to go (CommunitySpec
	-- holds the tickets).
	function p:FindFirstChildOfClass()
		return nil
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
	-- The invite plants' attribute (2026-10-08): heard, not drawn.
	PublishInvites = function(player)
		record("PublishInvites", player)
	end,
}
local payThrows = false
local EconomyService = {
	-- A garden's income per second, per player (THE PRIZES SCALE WITH THE
	-- PLAYER): 0 unless a section sets it, so the floors are what is paid.
	rates = {},
	PayReward = function(player, amount, reason)
		record("PayCash", player, amount, reason)
		if payThrows then
			error("spec: the cash faucet threw")
		end
		profiles[player].Cash += amount
		return true
	end,
}
function EconomyService.RateFor(player)
	return EconomyService.rates[player] or 0
end
local TreadmillService = {
	PayReward = function(player, amount, reason)
		record("PaySpeed", player, amount, reason)
		profiles[player].Speed += amount
		return true
	end,
}
local heldRestored = true
-- A pod being carried home keeps a place in the saved record (2026-09-30), and
-- CarryService.HeldRoom counts it; this stands in for one in the arms.
local carryingPod = false
-- TWO ROOMS SINCE 2026-10-09 (pods hatch in the Bag): pod rows and a pod in the
-- arms against Save.MaxPods, plant rows against Save.MaxHeld -- CarryService's
-- PodRoom and HeldRoom. Built in a closure, so the counter is no top-level
-- local: this file is at Luau's limit of them.
local CarryService = (function()
local function rowsOf(player, pods)
		local n = 0
		for _, row in ipairs(profiles[player].Held) do
			if (row.Hatched ~= true) == pods then
				n += 1
			end
		end
		return n
end
return {
	IsHeldRestored = function()
		return heldRestored
	end,
	HeldRoom = function(player)
		local count = rowsOf(player, false)
		return math.max(GameConfig.Save.MaxHeld - count, 0), count, true
	end,
	PodRoom = function(player)
		local count = rowsOf(player, true) + (if carryingPod then 1 else 0)
		return math.max(GameConfig.Save.MaxPods - count, 0), count, true
	end,
	GivePod = function(player, species, tier)
		record("GivePod", player, species, tier)
		table.insert(profiles[player].Held, { Id = species, Tier = tier, Hatched = false })
		return true
	end,
	-- An invite plant, grown, onto the record (2026-10-08): the Bag's room
	-- counted, or nothing.
	GiveHatched = function(player, species, tier, equipAfter, revealAt, onRecord)
		local count = rowsOf(player, false)
		if onRecord and GameConfig.Save.MaxHeld - count < 1 then
			record("GiveHatchedFull", player, species.Id)
			return false, "STORAGE_FULL"
		end
		record("GiveHatched", player, species.Id, tier)
		table.insert(profiles[player].Held, { Id = species.Id, Tier = tier, Hatched = true })
		return true
	end,
}
end)()
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
-- WheelService hooks the hatch reveal for the hatch bonus (2026-10-01);
-- HatchBonusSpec drives that. Here it hears nothing.
local PlantService = {
	OnRevealed = function()
		return function() end
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
	-- Paid spins are ON as shipped (2026-10-01). A copy that names no WheelData
	-- of its own sees them switched OFF, so the earned path is tested alone and
	-- "off" keeps its checks; section 5 loads the shipped WheelData on purpose.
	if overrides == nil or overrides.WheelData == nil then
		overrides = table.clone(overrides or {})
		overrides.WheelData = setmetatable({
			Paid = { Enabled = false, PromptCooldown = WheelData.Paid.PromptCooldown },
			paidLive = function()
				return false
			end,
		}, { __index = WheelData })
	end
	local W = loadWith(Server:WaitForChild("WheelService"), {
		PlayerDataService = PlayerDataService,
		EconomyService = EconomyService,
		TreadmillService = TreadmillService,
		CarryService = CarryService,
		BonusChestService = BonusChestService,
		Metrics = Metrics,
		WheelModel = WheelModel,
		PlantService = PlantService,
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
-- Bought spins never touch it. Switched off (this copy) nothing can be granted
-- at all; a copy that sees them switched on grants into the SAME profile, for a
-- player PolicyService allows.
check(not W.GrantBought(p1, 4) and prof.WheelBought == 0,
	"switched off, a grant of bought spins lands nothing")
local paidOn = setmetatable({
	Paid = { Enabled = true, PromptCooldown = 0 },
	paidLive = function()
		return true
	end,
}, { __index = WheelData })
local WPaid = loadWheel({ WheelData = paidOn })
policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
WPaid.CheckPolicy(p1)
local windowAt, windowCount, earnedBefore = prof.WheelDayAt, prof.WheelDayCount, prof.WheelEarned
check(WPaid.GrantBought(p1, 4) and prof.WheelBought == 4 and prof.WheelDayCount == 5
		and prof.WheelDayAt == windowAt and prof.WheelDayCount == windowCount and prof.WheelEarned == earnedBefore,
	"four bought spins land in their own balance and change nothing about the allowance or its reset")
check(not WPaid.GrantBought(p1, 0) and not WPaid.GrantBought(p1, -3) and not WPaid.GrantBought(p1, 0 / 0)
	and not WPaid.GrantBought(p1, WheelData.MaxBoughtHeld) and prof.WheelBought == 4,
	"a grant of nothing, of a negative, of not-a-number or past the cap lands nothing")
-- And a run completed with bought spins in hand is still counted against five.
kind = WPaid.AwardCompletion(p1, "run-7b", 1800)
check(kind == "speed" and prof.WheelDayCount == 5 and prof.WheelBought == 4,
	"holding bought spins earns no extra spin: the sixth run of the window still pays Speed")
WPaid.useClock(nil)
WPaid.useReply(nil)

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
		and rep.within >= 0 and rep.within < 1
		and rep.species == (if r.kind == "invite" then GameConfig.InviteRewards.Forms[1] else nil)
		and pr.WheelEarned == before.earned - 1 and #pr.WheelPending == 0 and count("Save") >= 1
		and count("wheelSpun") == 1 and lastArgs("wheelSpun")[2] == r.id
	local how = r.kind
	-- What a new player's spin pays (THE PRIZES SCALE): no garden income here,
	-- so the cash floors; a tier-1 mill, so 60 s of it where that beats a floor.
	local expect = WheelData.amountFor(r, 0, GameConfig.Mill.Tiers[1].speed)
	if r.kind == "cash" then
		local pay = lastArgs("PayCash")
		good = good and count("PayCash") == 1 and pay[2] == expect and pr.Cash == before.cash + expect
			and count("PaySpeed") == 0 and rep.amount == expect
		how = "the cash faucet, $" .. WheelData.commas(expect)
	elseif r.kind == "speed" then
		local pay = lastArgs("PaySpeed")
		good = good and count("PaySpeed") == 1 and pay[2] == expect and pr.Speed == before.speed + expect
			and count("PayCash") == 0 and rep.amount == expect
		how = "the Speed faucet, +" .. WheelData.commas(expect)
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
	elseif r.kind == "invite" then
		local first = GameConfig.InviteRewards.Forms[1]
		good = good and count("GiveHatched") == 1 and lastArgs("GiveHatched")[2] == first
			and table.find(pr.InviteOwned, first) ~= nil and #pr.Held == before.held + 1
		how = "the first invite plant not owned, grown, onto the record"
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

-- A full bag -- the POD room, since pods have their own (2026-10-09): owed,
-- never discarded.
while (CarryService.PodRoom(sp)) > 0 do
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
while (CarryService.PodRoom(sp)) < 1 do
	table.remove(pr.Held)
end
local landed, left = W.DeliverPending(sp)
check(landed == 1 and left == 0 and #pr.WheelPending == 0, "and the next delivery pass hands it over")

-- A pod being carried home keeps its place (2026-09-30, the owner's decision:
-- "Wheel waits its turn"): an owed pod does not take that place and leave the
-- carried pod nowhere to bank. In a block of its own: the file is at Luau's
-- limit of top-level locals.
do
	while (CarryService.PodRoom(sp)) < 1 do
		table.remove(pr.Held)
	end
	local heldBeforeCarry = #pr.Held
	local podsBeforeCarry = select(2, CarryService.PodRoom(sp))
	carryingPod = true
	table.insert(pr.WheelPending, { Id = "carry-1", Rolled = "pod_common", Prize = "pod_common", Species = "nubkin",
		Source = "earned", At = clock })
	table.clear(trace)
	local landedCarry, leftCarry = W.DeliverPending(sp)
	check(podsBeforeCarry == GameConfig.Save.MaxPods - 1 and landedCarry == 0 and leftCarry == 1
		and count("GivePod") == 0 and #pr.Held == heldBeforeCarry,
		"with 59 pods saved and a pod being carried home, an owed pod waits: the carried pod's place is not taken")
	table.clear(replies)
	W.Claim(sp)
	check(last().claim == true and last().ok == false and last().reason == "NO_ROOM" and #pr.WheelPending == 1
		and count("GivePod") == 0, "CLAIM says NO_ROOM while the pod is carried, and nothing is lost")
	-- Banked: the carried pod's row takes the place kept for it, and the prize still waits.
	carryingPod = false
	table.insert(pr.Held, { Id = "petalpip", Tier = 1, Hatched = false })
	local landedFull = W.DeliverPending(sp)
	check(landedFull == 0 and #pr.WheelPending == 1 and count("GivePod") == 0,
		"the pod is banked into its place, and the prize goes on waiting for room")
	table.remove(pr.Held)
	local landedRoom, leftRoom = W.DeliverPending(sp)
	check(landedRoom == 1 and leftRoom == 0 and #pr.WheelPending == 0 and count("GivePod") == 1,
		"once there is room, the next delivery pass hands it over")
end

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
	and handler:find("equip(player, payload)", 1, true) ~= nil and handler:find("buy(player, payload)", 1, true) ~= nil
	and not handler:find("DebugForce", 1, true) and not handler:find("usePrompt", 1, true)
	and not handler:find("useClock", 1, true) and not handler:find("GrantBought", 1, true),
	"the remote reaches spin, claim, equip and buy only: no forcing, no clock, no spins granted")
-- A PROMPT IS NOT A PURCHASE. Nothing on the server listens for a prompt ending,
-- and the one thing that grants bought spins is called by the receipt alone.
local grantCalls = select(2, wheelSource:gsub("GrantBought%(", ""))
check(not wheelSource:find("PromptProductPurchaseFinished", 1, true)
		and not wheelSource:find("PromptPurchaseFinished", 1, true)
		and select(2, wheelSource:gsub(":PromptProductPurchase%(", "")) == 1
		and grantCalls == 1,
	"WheelService opens the prompt in one place, listens for no prompt ending, and never calls its own grant",
	grantCalls)
local storeSource = sourceOf(Server:FindFirstChild("StoreService"))
check(storeSource ~= "" and not storeSource:find("PromptProductPurchaseFinished", 1, true)
		and select(2, storeSource:gsub("WheelService%.GrantBought%(", "")) == 1
		and select(2, storeSource:gsub("MarketplaceService%.ProcessReceipt = ", "")) == 1,
	"StoreService is the grant's only caller, from the experience's one ProcessReceipt")
local otherGrants = {}
for _, inst in ipairs(Server:GetDescendants()) do
	if inst:IsA("LuaSourceContainer") and inst.Name ~= "StoreService" and inst.Name ~= "WheelService" then
		local src = sourceOf(inst)
		if src:find("GrantBought", 1, true) or src:find("ProcessReceipt =", 1, true)
			or src:find("PromptProductPurchaseFinished", 1, true) then
			table.insert(otherGrants, inst.Name)
		end
	end
end
check(#otherGrants == 0, "no other server script grants bought spins, takes the receipt callback or hears a prompt end",
	table.concat(otherGrants, ", "))
local seamsOk = true
for _, seam in ipairs({ "useClock", "DebugForce", "useReply", "usePrompt" }) do
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
	"switched off (a copy), paid spins are off even for an eligible account")
table.clear(replies)
W.Spin(buyer, "bought")
local refusedBought = last().reason
W.Spin(buyer, "earned")
check(refusedBought == "PAID_UNAVAILABLE" and last().reason == "NO_SPINS" and bp.WheelBought == 2,
	"a bought spin is refused, and asking for an earned one never falls back to a bought one",
	tostring(refusedBought) .. " / " .. tostring(last().reason))

-- THE SHIPPED SWITCH (2026-10-01): a copy loaded with the real WheelData.
-- PolicyService still decides: an eligible player is shown the x5 prompt, a
-- restricted one nothing.
do
	local WS = loadWheel({ WheelData = WheelData })
	local shown = {}
	WS.usePrompt(function(who, productId)
		table.insert(shown, { who = who, productId = productId })
	end)
	local fan, barredFan = makePlayer("SpecShippedFan", 5130), makePlayer("SpecShippedBarred", 5131)
	profiles[fan] = ProfileSchema.Default()
	profiles[barredFan] = ProfileSchema.Default()
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WS.CheckPolicy(fan)
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
	WS.CheckPolicy(barredFan)
	table.clear(replies)
	WS.Buy(fan, "spin5")
	WS.Buy(barredFan, "spin5")
	local barredWhy = last().reason
	check(#shown == 1 and shown[1].who == fan and shown[1].productId == 3715745407
			and fan:GetAttribute(A.PaidAllowed) == true and barredFan:GetAttribute(A.PaidAllowed) == nil
			and barredWhy == "PAID_UNAVAILABLE" and profiles[fan].WheelBought == 0,
		"as shipped, an eligible player asking for x5 is shown product 3715745407 (and granted nothing yet); "
			.. "a restricted player is shown nothing",
		string.format("%d prompt(s), %s", #shown, tostring(barredWhy)))
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WS.usePrompt(nil)
	WS.useClock(nil)
	WS.useReply(nil)
end

-- The packs switched on for a copy of the service with no wait between
-- prompts; the wait has its own copy below.
local live = setmetatable({
	Paid = { Enabled = true, PromptCooldown = 0 },
	paidLive = function()
		return true
	end,
}, { __index = WheelData })
local liveOk, WP = pcall(loadWheel, { WheelData = live })
check(liveOk, "a copy that sees paid spins switched on loads", if liveOk then nil else WP)
if liveOk then
	-- Every prompt the service asks for lands here; none is ever opened.
	local prompts = {}
	WP.usePrompt(function(who, productId)
		table.insert(prompts, { who = who, productId = productId })
	end)
	local function bought()
		local r = last()
		return if r.buy == true then r else {}
	end

	--==========================================================================
	-- BEFORE PolicyService HAS ANSWERED: closed
	--==========================================================================
	table.clear(replies)
	WP.Buy(buyer, "spin1")
	check(#prompts == 0 and bought().ok == false and bought().reason == "PAID_UNAVAILABLE"
			and buyer:GetAttribute(A.PaidAllowed) == nil and not WP.PaidAllowed(buyer),
		"before PolicyService has answered for a player, nothing is offered and no prompt opens",
		tostring(bought().reason))

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

	-- A check that FAILS says nothing about the player. For one PolicyService
	-- has never answered for, that is "may not"; so is an answer without the field.
	local unknown = makePlayer("SpecUnknown", 5112)
	profiles[unknown] = ProfileSchema.Default()
	policyAnswer = { ok = false }
	local answered = WP.CheckPolicy(unknown)
	local failed = WP.PaidAllowed(unknown)
	policyAnswer = { ok = true, info = {} }
	WP.CheckPolicy(unknown)
	check(answered == false and not failed and not WP.PaidAllowed(unknown)
			and unknown:GetAttribute(A.PaidAllowed) == nil,
		"a policy check that fails, or answers without the field, counts as \"may not\"")
	-- For one it HAS answered for, only an answer replaces the answer: two
	-- checks can be in the air at once (the join's, and a receipt's), and a
	-- failure that comes back late must neither open the door to a restricted
	-- player nor shut out one who was just allowed to buy.
	policyAnswer = { ok = false }
	WP.CheckPolicy(buyer)
	local stillShut = not WP.PaidAllowed(buyer) and buyer:GetAttribute(A.PaidAllowed) == nil
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WP.CheckPolicy(buyer)
	policyAnswer = { ok = false }
	local known = WP.CheckPolicy(buyer)
	check(stillShut and known == true and WP.PaidAllowed(buyer) and buyer:GetAttribute(A.PaidAllowed) == true,
		"a check that fails after PolicyService has answered changes nothing: restricted stays restricted, "
			.. "allowed stays allowed")
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
	WP.CheckPolicy(buyer)
	check(not WP.PaidAllowed(buyer) and buyer:GetAttribute(A.PaidAllowed) == nil,
		"and a later ANSWER of \"restricted\" shuts the door again at once")

	--==========================================================================
	-- BUYING: the server opens the prompt, for the right product, and only for
	-- a player it may sell to. A prompt grants nothing.
	--==========================================================================
	say("\n-- 5b. buying --")
	local function promptsFor(who)
		local n = 0
		for _, p in ipairs(prompts) do
			if p.who == who then
				n += 1
			end
		end
		return n
	end
	local shopper = makePlayer("SpecShopper", 5111)
	profiles[shopper] = ProfileSchema.Default()
	local sp2 = profiles[shopper]
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WP.CheckPolicy(shopper)
	table.clear(prompts)
	table.clear(replies)
	WP.Buy(shopper, "spin1")
	local one = prompts[1]
	WP.Buy(shopper, "spin5")
	local five = prompts[2]
	WP.Buy(shopper, "spin10")
	local ten = prompts[3]
	check(#prompts == 3 and one.who == shopper and one.productId == 3715745320
			and five.who == shopper and five.productId == 3715745407
			and ten.who == shopper and ten.productId == 3715745552 and bought().ok == true and bought().key == "spin10",
		"an eligible player asking for x1 is shown product 3715745320, for x5 3715745407, for x10 3715745552",
		string.format("%d prompt(s)", #prompts))
	check(sp2.WheelBought == 0 and sp2.WheelEarned == 0 and #sp2.WheelPending == 0
			and shopper:GetAttribute(A.Bought) == 0,
		"and a prompt grants NOTHING: the balance is what it was, whatever the player does with the prompt")

	-- What the client sends is a key, and only a key this build sells.
	local forgedBuys = 0
	local echoed = 0
	for _, forged in ipairs({ 3715369823, "3715369823", "spin100", "", true, { key = "spin1" }, { spins = 1e6 },
		"SPIN1", "spin1 ", string.rep("spin1", 20000), "retired1", "retired10", 3715745320 }) do
		table.clear(prompts)
		table.clear(replies)
		WP.Buy(shopper, forged)
		if #prompts ~= 0 or bought().ok ~= false or bought().reason ~= "UNKNOWN_PRODUCT" then
			forgedBuys += 1
		end
		if bought().key ~= nil then
			echoed += 1
		end
	end
	table.clear(prompts)
	WP.Buy(shopper, nil)
	check(forgedBuys == 0 and #prompts == 0,
		"a product id, a quantity, a made-up key or nothing at all opens no prompt: the key picks a row, never an amount",
		forgedBuys)
	check(echoed == 0, "and whatever was sent in a key's place is not sent back, however long it is", echoed)

	-- Restricted, unanswered, unsaved, no profile, no room: no prompt.
	local function refusedWith(who, key)
		table.clear(prompts)
		table.clear(replies)
		WP.Buy(who, key)
		return #prompts == 0 and bought().ok == false, tostring(bought().reason)
	end
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
	WP.CheckPolicy(shopper)
	local r1, why1 = refusedWith(shopper, "spin1")
	local r10, why10 = refusedWith(shopper, "spin10")
	check(r1 and r10 and why1 == "PAID_UNAVAILABLE" and why10 == "PAID_UNAVAILABLE"
			and shopper:GetAttribute(A.PaidAllowed) == nil,
		"a player restricted from paid random items is shown no prompt for either product", why1 .. "/" .. why10)
	policyAnswer = { ok = false }
	WP.CheckPolicy(shopper)
	local rFail, whyFail = refusedWith(shopper, "spin1")
	policyAnswer = { ok = true, info = {} }
	WP.CheckPolicy(shopper)
	local rBlank, whyBlank = refusedWith(shopper, "spin1")
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = "false" } }
	WP.CheckPolicy(shopper)
	local rOdd, whyOdd = refusedWith(shopper, "spin1")
	check(rFail and rBlank and rOdd and whyFail == "PAID_UNAVAILABLE" and whyBlank == "PAID_UNAVAILABLE"
			and whyOdd == "PAID_UNAVAILABLE",
		"PolicyService failing, answering without the field, or with anything but false: no prompt (fails closed)",
		whyFail .. "/" .. whyBlank .. "/" .. whyOdd)
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WP.CheckPolicy(shopper)

	persistent[shopper] = false
	local rTemp, whyTemp = refusedWith(shopper, "spin1")
	persistent[shopper] = nil
	profiles[shopper] = nil
	local rNone, whyNone = refusedWith(shopper, "spin1")
	profiles[shopper] = sp2
	check(rTemp and whyTemp == "NOT_SAVED" and rNone and whyNone == "NOT_READY",
		"a profile that is not saving, or has not loaded, is shown no prompt", whyTemp .. "/" .. whyNone)

	sp2.WheelBought = WheelData.MaxBoughtHeld - 5
	local rFull, whyFull = refusedWith(shopper, "spin10")
	table.clear(prompts)
	WP.Buy(shopper, "spin1")
	check(rFull and whyFull == "BALANCE_FULL" and #prompts == 1 and prompts[1].productId == 3715745320,
		"a balance with no room for ten is not sold ten -- and is still sold one, which fits", whyFull)
	sp2.WheelBought = 0

	-- The wait between prompts, on a copy that has one.
	local waits = setmetatable({
		Paid = { Enabled = true, PromptCooldown = 0.3 },
		paidLive = function()
			return true
		end,
	}, { __index = WheelData })
	local WW = loadWheel({ WheelData = waits })
	local waited = {}
	WW.usePrompt(function(who, productId)
		table.insert(waited, productId)
	end)
	WW.CheckPolicy(shopper)
	table.clear(replies)
	WW.Buy(shopper, "spin1")
	WW.Buy(shopper, "spin10")
	local hurried = bought().reason
	task.wait(0.35)
	WW.Buy(shopper, "spin10")
	check(#waited == 2 and waited[1] == 3715745320 and waited[2] == 3715745552 and hurried == "PROMPT_BUSY",
		"a second prompt inside the wait is refused, and one after it opens", tostring(hurried))
	WW.usePrompt(nil)
	WW.useClock(nil)
	WW.useReply(nil)

	-- A prompt that cannot open says so, and still grants nothing.
	WP.usePrompt(function()
		error("spec: the prompt could not open")
	end)
	table.clear(replies)
	local survived = pcall(WP.Buy, shopper, "spin1")
	check(survived and bought().ok == false and bought().reason == "PROMPT_FAILED" and sp2.WheelBought == 0,
		"a prompt that fails to open is a refusal, not an error, and grants nothing", tostring(bought().reason))
	WP.usePrompt(function(who, productId)
		table.insert(prompts, { who = who, productId = productId })
	end)

	--==========================================================================
	-- THE GRANT: what StoreService's receipt calls. The same questions again,
	-- because a receipt can arrive with no prompt of ours behind it.
	--==========================================================================
	say("\n-- 5c. the grant a receipt asks for --")
	local outsider = makePlayer("SpecOutsider", 5112)
	profiles[outsider] = ProfileSchema.Default()
	local op = profiles[outsider]
	-- Never asked about: a receipt that arrives on the join, before `watch` got
	-- an answer. The grant asks PolicyService itself, once.
	table.clear(trace)
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	local landed = WP.GrantBought(outsider, 10)
	check(landed and op.WheelBought == 10 and count("Policy") == 1 and outsider:GetAttribute(A.Bought) == 10
			and promptsFor(outsider) == 0,
		"a receipt with no prompt behind it (bought outside the game, or re-delivered on a join) is granted to an "
			.. "eligible player: the grant asks PolicyService itself", count("Policy"))
	table.clear(trace)
	WP.GrantBought(outsider, 1)
	check(op.WheelBought == 11 and count("Policy") == 0, "and does not ask again once it has an answer")

	local barred = makePlayer("SpecBarred", 5113)
	profiles[barred] = ProfileSchema.Default()
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
	local barredLanded = WP.GrantBought(barred, 10)
	check(not barredLanded and profiles[barred].WheelBought == 0 and barred:GetAttribute(A.PaidAllowed) == nil,
		"a restricted player's receipt grants nothing: it stays unacknowledged and Roblox returns the Robux")
	local silent = makePlayer("SpecSilent", 5114)
	profiles[silent] = ProfileSchema.Default()
	policyAnswer = { ok = false }
	table.clear(trace)
	local silentLanded = WP.GrantBought(silent, 1)
	local askedOnce = count("Policy")
	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	local later = WP.GrantBought(silent, 1)
	check(not silentLanded and askedOnce == 1 and later and profiles[silent].WheelBought == 1,
		"PolicyService failing at the receipt: nothing granted (closed) -- and the re-delivered receipt asks again "
			.. "and pays once it answers")
	persistent[outsider] = false
	local tempLanded = WP.GrantBought(outsider, 1)
	persistent[outsider] = nil
	check(not tempLanded and op.WheelBought == 11,
		"a profile that is not saving is granted nothing, rather than spins that vanish with the server")
	op.WheelBought = WheelData.MaxBoughtHeld - 3
	local overLanded = WP.GrantBought(outsider, 10)
	check(not overLanded and op.WheelBought == WheelData.MaxBoughtHeld - 3,
		"a pack the balance has no room for is not granted in part: all ten or none")
	op.WheelBought = 11

	-- Bought spins, spent: one at a time, by name, never against the allowance.
	op.WheelEarned, op.WheelDayAt, op.WheelDayCount = 0, 0, 0
	table.clear(replies)
	WP.DebugForce(outsider, "cash_small")
	WP.Spin(outsider, "bought")
	check(last().ok == true and last().source == "bought" and op.WheelBought == 10 and op.WheelDayCount == 0
			and op.WheelDayAt == 0,
		"a bought spin spends one bought spin and opens no earning window")
	local kindB, nB = WP.AwardCompletion(outsider, "run-bought-1", 1800)
	check(kindB == "spin" and nB == 1 and op.WheelEarned == 1 and op.WheelDayCount == 1 and op.WheelBought == 10,
		"and the first obby run of the day still earns its spin: bought spins used none of the five")

	policyAnswer = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
	WP.usePrompt(nil)
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
	and not ui:find("PromptPurchase", 1, true) and not ui:find("ProcessReceipt", 1, true),
	"the panel opens no purchase prompt of its own and hears no purchase: the server prompts, the receipt grants")
check(ui:find("remote:FireServer(ACT.Spin, source)", 1, true) ~= nil and ui:find("send(\"bought\")", 1, true) ~= nil
	and ui:find("showConfirm(true)", 1, true) ~= nil
	and ui:find("remote:FireServer(ACT.Buy, choice.product.key)", 1, true) ~= nil
	and ui:find("remote:FireServer(ACT.Claim)", 1, true) ~= nil
	and ui:find("remote:FireServer(ACT.Open)", 1, true) ~= nil and fires == 4,
	"it sends one word to spin -- \"bought\" only from the yes of the question naming it -- CLAIM, OPEN (carrying "
		.. "nothing: the server works the amounts out), and to buy a product's key and nothing else", fires)
-- BUYING, IN THE PANEL (2026-09-29).
check(ui:find("local may = paidAllowed()", 1, true) ~= nil and ui:find("getSpins.Visible = may", 1, true) ~= nil
		and ui:find("if shop.open and not may then", 1, true) ~= nil
		and ui:find("return player:GetAttribute(A.PaidAllowed) == true", 1, true) ~= nil
		and ui:find("if not remote or not paidAllowed() or not choice.onSale then", 1, true) ~= nil,
	"GET SPINS and its card are shown only while the SERVER says this player may buy, and a choice sends "
		.. "nothing otherwise")
check(ui:find("RobuxPrice.watch(\"product\", choice.product.productId,", 1, true) ~= nil
		and ui:find("choice.price.Text = RobuxPrice.format(amount)", 1, true) ~= nil
		and not ui:find(".robux", 1, true) and not ui:find("%d+ Robux") and not ui:find("R%$%s*%d"),
	"each price is what Roblox quotes THIS player (RobuxPrice): the list price is never read and no price is typed in")
check(select(2, ui:gsub("RobuxPrice%.watch%(", "")) == 1 and select(2, ui:gsub("shop%.watch%(%)", "")) == 1
		and ui:find("if may then%s+shop%.watch%(%)%s+end") ~= nil
		and ui:find("shop.watch = function()", 1, true) ~= nil,
	"and Roblox is asked for a price only once this player may buy: never while paid spins are switched off")
check(select(2, ui:gsub("\"REWARDS & ODDS\"", "")) == 2 and ui:find("shop.infoWord.Text = \"ODDS\"", 1, true) ~= nil
		and ui:find("shop.returnTo = \"shop\"", 1, true) ~= nil and ui:find("shop.returnTo = \"confirm\"", 1, true) ~= nil
		and ui:find("shop.infoWord.Visible = may", 1, true) ~= nil,
	"the odds are one press away and the way to them is WORDED: on the card to buy, on the question before a "
		.. "bought spin, and under the round \"?\"")
check(ui:find("if confirm.Visible and not may then", 1, true) ~= nil
		and ui:find("local card = shop.open == true or confirm.Visible", 1, true) ~= nil
		and ui:find("local behind = sheetOpen or card", 1, true) ~= nil
		and ui:find("info.Selectable = not behind", 1, true) ~= nil
		and ui:find("close.Selectable = not behind", 1, true) ~= nil
		and ui:find("getSpins.Selectable = may and not busy and not behind", 1, true) ~= nil
		and ui:find("padFirst.Value = if shop.open then shop.first()", 1, true) ~= nil,
	"a card over the hub keeps the controller inside it (nothing behind is selectable, and a controller picked up "
		.. "starts on the card), and the question goes too when the server stops saying this player may")
-- WHERE THE BUYING CONTROLS STAND, ON EVERY SCREEN. The panel's own layout code,
-- cut out of its source and run over stand-ins that only record what they were
-- given: a LocalScript cannot be required, and these are numbers, not drawing.
do
	local src = string.gsub(ui, "\r\n", "\n")
	local g0 = src:find("shop.grow = function(", 1, true)
	local g1 = g0 and src:find("\nend\n", g0, true)
	local a = src:find("shop.layout = function(", 1, true)
	local b = src:find("local function layoutSheet(", 1, true)
	local maxWheel = tonumber(src:match("\nlocal MAX_WHEEL = (%d+)"))
	local cut = g0 ~= nil and g1 ~= nil and a ~= nil and b ~= nil and a < b and maxWheel ~= nil
	check(cut, "the panel's layout can be found in its source (shop.grow, shop.layout, layoutStage)")
	-- What the stand-ins take for granted, so it is checked: where each piece is
	-- held from.
	check(ui:find("shop.card.AnchorPoint = Vector2.new(0.5, 0.5)", 1, true) ~= nil
			and ui:find("confirm.AnchorPoint = Vector2.new(0.5, 0.5)", 1, true) ~= nil
			and ui:find("hubButton.AnchorPoint = Vector2.new(0.5, 0.5)", 1, true) ~= nil
			and ui:find("r.button.AnchorPoint = Vector2.new(0.5, 0.5)", 1, true) ~= nil,
		"the card, the question, the hub and the round buttons are held by their centres")
	local layoutStage = nil
	if cut then
		local prelude = table.concat({
			"type ShopChoice = any",
			"local env = ...",
			"local shop, place, buildWheel, MAX_WHEEL = env.shop, env.place, env.buildWheel, env.MAX_WHEEL",
			"local wheelHolder, wheelBlock, pin, hubFace, hubButton = env.wheelHolder, env.wheelBlock, env.pin, nil, env.hubButton",
			"local infoButton, closeButton, topbarBand = env.infoButton, env.closeButton, env.topbarBand",
			"local lineText, claimButton, claimWords, lineRow = env.lineText, env.claimButton, env.claimWords, env.lineRow",
			"local confirm, confirmText, confirmYes, confirmNo = env.confirm, env.confirmText, env.confirmYes, env.confirmNo",
			"",
		}, "\n")
		local chunk, err = loadstring(prelude .. string.sub(src, g0, g1 + 4) .. "\n" .. string.sub(src, a, b - 1)
			.. "\nreturn layoutStage", "=WheelUI.layout")
		check(chunk ~= nil, "and it compiles on its own", err)
		if chunk then
			local function piece(anchorX: number, anchorY: number)
				return { AnchorPoint = Vector2.new(anchorX, anchorY), Position = UDim2.new(), Size = UDim2.new() }
			end
			local function round()
				local button = piece(0.5, 0.5)
				return { button = button, resize = function(d: number)
					button.Size = UDim2.fromOffset(d, d)
				end }
			end
			local env = {
				MAX_WHEEL = maxWheel,
				place = function(g, x: number, y: number, w: number, h: number)
					g.Position = UDim2.fromOffset(x, y)
					g.Size = UDim2.fromOffset(w, h)
				end,
				buildWheel = function() end,
				wheelHolder = piece(0, 0), wheelBlock = piece(0, 0),
				pin = { headEdge = piece(0.5, 0.5), head = piece(0.5, 0.5), tipEdge = piece(0.5, 0.5),
					tip = piece(0.5, 0.5), dot = piece(0.5, 0.5) },
				hubButton = piece(0.5, 0.5),
				infoButton = round(), closeButton = round(),
				-- Roblox's own buttons, as Studio's phone has them.
				topbarBand = function(k: number, W: number)
					return 58 / k, math.min(208, W * 0.3) / k, W
				end,
				lineText = piece(0, 0), claimButton = piece(0, 0), claimWords = piece(0, 0), lineRow = piece(0, 0),
				confirm = piece(0.5, 0.5), confirmText = piece(0, 0), confirmYes = piece(0, 0), confirmNo = piece(0, 0),
				shop = {
					button = piece(0.5, 0.5), card = piece(0.5, 0.5), title = piece(0, 0), note = piece(0, 0),
					odds = piece(0, 0), close = piece(0, 0), confirmOdds = piece(0, 0), infoWord = piece(0.5, 0),
					buttonScale = { Scale = 1 }, cardScale = { Scale = 1 }, questionScale = { Scale = 1 },
					choices = {},
				},
			}
			for i = 1, #WheelData.Products do
				env.shop.choices[i] = { button = piece(0, 0), icon = piece(0, 0), name = piece(0, 0),
					capsule = piece(0.5, 0) }
			end
			layoutStage = chunk(env)

			-- A piece's rect: its offsets at the scale it is drawn at (`s`, its
			-- parent's), its own size times its own UIScale, held from its anchor.
			local function rectOf(g, parent, own: number?)
				local s, mine = parent.s, own or 1
				local w = (g.Size.X.Offset * s + g.Size.X.Scale * parent.w) * mine
				local h = (g.Size.Y.Offset * s + g.Size.Y.Scale * parent.h) * mine
				return {
					x = parent.x + g.Position.X.Offset * s + g.Position.X.Scale * parent.w - g.AnchorPoint.X * w,
					y = parent.y + g.Position.Y.Offset * s + g.Position.Y.Scale * parent.h - g.AnchorPoint.Y * h,
					w = w, h = h, s = s * mine,
				}
			end
			local function meets(p, q): boolean
				return p.x < q.x + q.w and q.x < p.x + p.w and p.y < q.y + q.h and q.y < p.y + p.h
			end
			local function within(p, q): boolean
				return p.x >= q.x - 0.01 and p.y >= q.y - 0.01 and p.x + p.w <= q.x + q.w + 0.01
					and p.y + p.h <= q.y + q.h + 0.01
			end

			-- Landscape and upright phones, tablets, small windows, desktops, and a
			-- TV's canvas (1422 x 800 is 1920 x 1080 at its 1.35).
			local SCREENS = {
				{ 705, 338 }, { 568, 320 }, { 640, 360 }, { 667, 375 }, { 750, 369 }, { 812, 375 }, { 926, 428 },
				{ 360, 640 }, { 390, 844 }, { 1024, 768 }, { 1180, 820 }, { 1366, 1024 }, { 560, 420 }, { 600, 480 },
				{ 640, 480 }, { 720, 540 }, { 800, 600 }, { 1024, 600 }, { 1280, 720 }, { 1366, 768 }, { 1600, 900 },
				{ 1920, 1080 }, { 2560, 1440 }, { 3840, 2160 }, { 1422, 800, 1.35 }, { 1422, 800, 2.7 },
			}
			local wrong = {}
			local places = { right = 0, under = 0, corner = 0 }
			local smallest, largest = math.huge, 0
			for _, screen in ipairs(SCREENS) do
				local W, H, k = screen[1], screen[2], screen[3] or 1
				layoutStage(W, H, k)
				local shop = env.shop
				local whole = { x = 0, y = 0, w = W, h = H, s = 1 }
				local tag = string.format("%dx%d", W, H)
				local wheel = rectOf(env.wheelHolder, whole)
				local cx, cy, radius = wheel.x + wheel.w / 2, wheel.y + wheel.h / 2, wheel.w / 2
				local f = shop.buttonScale.Scale
				local get = rectOf(shop.button, whole, f)
				local row = rectOf(env.lineRow, whole)
				local nearX = math.clamp(cx, get.x, get.x + get.w)
				local nearY = math.clamp(cy, get.y, get.y + get.h)
				if not within(get, whole) then
					table.insert(wrong, tag .. ": GET SPINS leaves the screen")
				end
				if math.sqrt((nearX - cx) ^ 2 + (nearY - cy) ^ 2) < radius then
					table.insert(wrong, tag .. ": GET SPINS is on the wheel")
				end
				if meets(get, row) then
					table.insert(wrong, tag .. ": GET SPINS is in the line's row")
				end
				if meets(get, rectOf(env.infoButton.button, whole)) or meets(get, rectOf(env.closeButton.button, whole)) then
					table.insert(wrong, tag .. ": GET SPINS meets a round button")
				end
				if get.h * k < 46 - 0.01 then
					table.insert(wrong, tag .. ": GET SPINS is under a thumb tall")
				end
				smallest, largest = math.min(smallest, f), math.max(largest, f)
				if math.abs(get.y + get.h / 2 - cy) < 0.01 and get.x > cx + radius then
					places.right += 1
				elseif get.y >= row.y + row.h - 0.01 then
					places.under += 1
				else
					places.corner += 1
				end
				if shop.cardScale.Scale ~= f or shop.questionScale.Scale ~= f then
					table.insert(wrong, tag .. ": the cards are not drawn at the button's size")
				end
				local card = rectOf(shop.card, whole, f)
				local ask = rectOf(env.confirm, whole, f)
				if not within(card, whole) then
					table.insert(wrong, tag .. ": the card leaves the screen")
				end
				if not within(ask, whole) then
					table.insert(wrong, tag .. ": the question leaves the screen")
				end
				local inCard = { shop.title, shop.note, shop.odds, shop.close }
				for _, choice in ipairs(shop.choices) do
					table.insert(inCard, choice.button)
				end
				local rects = {}
				for i, g in ipairs(inCard) do
					rects[i] = rectOf(g, card)
					if not within(rects[i], card) or rects[i].w < 40 * f or rects[i].h < 12 * f then
						table.insert(wrong, tag .. ": a piece of the card does not sit in it")
					end
				end
				for i = 1, #rects do
					for j = i + 1, #rects do
						if meets(rects[i], rects[j]) then
							table.insert(wrong, tag .. ": two pieces of the card meet")
						end
					end
				end
				for _, g in ipairs({ env.confirmText, env.confirmYes, env.confirmNo, shop.confirmOdds }) do
					if not within(rectOf(g, ask), ask) then
						table.insert(wrong, tag .. ": a piece of the question leaves it")
					end
				end
			end
			check(#wrong == 0, string.format("on %d screens GET SPINS is whole, a thumb tall, and never on the wheel, "
				.. "the round buttons or the line; its card and the question stand whole with every piece inside",
				#SCREENS), wrong[1])
			check(places.right >= 15 and places.under == 2 and places.corner >= 1,
				"it stands right of the wheel on every landscape phone and desktop, under the line on a phone held "
					.. "upright, and in the free corner above the line in a small 4:3 window",
				string.format("right %d, under %d, corner %d", places.right, places.under, places.corner))
			layoutStage(705, 338, 1)
			local phone = env.shop.buttonScale.Scale
			layoutStage(1920, 1080, 1)
			check(phone == 1 and env.shop.buttonScale.Scale == 1.25 and smallest == 1 and largest == 1.25,
				"drawn at the phone's size on a phone and a quarter bigger on a desktop, never smaller, never more",
				string.format("phone %s, desktop %s", tostring(phone), tostring(env.shop.buttonScale.Scale)))
		end
	end
end
check(not ui:find("SetAttribute(A.Bought", 1, true) and not ui:find("SetAttribute(A.Earned", 1, true)
		and not ui:find("SetAttribute(A.PaidAllowed", 1, true)
		and ui:find("player:GetAttributeChangedSignal(A.Bought):Connect(function()", 1, true) ~= nil,
	"the panel only READS the balances and the permission the server publishes")
check(ui:find("\"%d hidden species, %s each\" else \"%d species, %s each\"", 1, true) ~= nil
		and ui:find("WheelData.percent(pool[1].probability)", 1, true) ~= nil,
	"every pod row says how many species it holds and each one's odds, before it is opened")
-- What the rows will say, from the same numbers: each pod's species add up to
-- the pod's own odds, and all the final outcomes to exactly 100%.
do
	local sum, lines = 0, {}
	for _, r in ipairs(R) do
		local pool = WheelData.poolOdds(r)
		if #pool > 0 then
			local each = pool[1].probability
			local same = true
			for _, entry in ipairs(pool) do
				same = same and math.abs(entry.probability - each) < 1e-12
				sum += entry.probability
			end
			check(same and math.abs(each * #pool - r.weight / WheelData.TotalWeight) < 1e-12,
				string.format("%s: %d species at %s each make its %s", r.short, #pool, WheelData.percent(each),
					WheelData.percent(r.weight / WheelData.TotalWeight)))
			table.insert(lines, WheelData.percent(each))
		else
			sum += r.weight / WheelData.TotalWeight
		end
	end
	check(math.abs(sum - 1) < 1e-9, "every final outcome's odds, species by species, add to exactly 100%", sum)
	-- For a player who owns the trail, the trail's share pays its replacement:
	-- still every outcome, still 100%.
	local owned, replaced = 0, 0
	for _, o in ipairs(WheelData.outcomes(true)) do
		owned += o.probability
		if o.note == "replacement" then
			replaced += 1
		end
	end
	check(math.abs(owned - 1) < 1e-9 and replaced == 1,
		"and for a trail owner too, with the trail's line saying what it pays instead", owned)
end
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
