--!nocheck
--==============================================================================
-- Steal a Seed :: ServerBoostSpec (2026-10-12, the owner's item 9B: the three
-- Developer Products -- the Starter Pack, SERVER LUCK and SUMMON RAIN)
--
--   1. the manifest: the owner's ids and prices, the BOOSTS shelf on coral,
--      the owner's icons
--   2. the Shop's cards: their own words, the Starter Pack's offer and odds,
--      SUMMON RAIN's wait
--   3. SERVER LUCK in a nest's roll (SeedData.PoolWeights): every rarer species
--      exactly x2 in every biome with the pool's total kept; no luck is the old
--      roll, draw for draw
--   4. SERVER LUCK's clock (ServerBoost): stacking, standing still in the Mist,
--      running on after, running out
--   5. SUMMON RAIN's rules: the clashes, the cooldown, the button's words
--   6. the Starter Pack's offer: 3 days from the first join, never once given,
--      never without paid random items
--   7. ServerBoostService against stand-ins: the luck granted and said, still in
--      the Mist; a Rain owed, started the moment nothing clashes, never lost;
--      the cooldown; the offer on the player
--   8. StoreService's receipts: the Starter Pack all three or none (asked
--      first, the tickets taken back), one bought again still given; the luck;
--      the Rain owed
--   9. the profile's two fields, and the wiring: the nests' roll, the chip, the
--      Shop's cards
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local ServerBoost = require(Shared:WaitForChild("ServerBoost"))
local BoostIcons = require(Shared:WaitForChild("BoostIcons"))
local Notice = require(Shared:WaitForChild("Notice"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

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
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then s.Source else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

-- Loads a real server module with its siblings replaced by stand-ins and its
-- game:GetService answers from `services` where named (StoreSpec's loader).
local outerRequire = require
local function loadWith(module, siblings, services)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local fakeGame = {}
	function fakeGame:GetService(name)
		if services and services[name] ~= nil then
			return services[name]
		end
		return game:GetService(name)
	end
	local env = setmetatable({
		game = fakeGame,
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

local STORE = GameConfig.Store
local BOOST = GameConfig.ServerBoost
local DAY = 86400

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the manifest --")
	--==========================================================================
	local rows = {}
	for _, item in ipairs(STORE.Items.Boosts or {}) do
		rows[item.key] = item
	end
	local S, L, R = rows.starterpack, rows.serverluck, rows.summonrain
	check(S and S.product == 3717932975 and S.robux == 99 and S.kind == "starter" and S.amount == 800e3
			and S.species == "petalpip" and S.tier == 6 and S.spins == 5 and S.offer == "starter",
		"STARTER PACK: the owner's 3717932975 at 99 -- $800K, the Petalpip pod at 6, 5 Spin Tickets, an offer")
	check(SeedData.Get("petalpip") ~= nil and string.upper(SeedData.Tier(6).name) == "TITAN",
		"its pod is the store's TITAN PETALPIP", SeedData.Tier(6).name)
	check(L and L.product == 3717932858 and L.robux == 99 and L.kind == "luck" and L.seconds == 900
			and BOOST.Luck.Factor == 2,
		"SERVER LUCK: the owner's 3717932858 at 99 -- 15 minutes of rarer pods x2")
	check(R and R.product == 3717932732 and R.robux == 199 and R.kind == "rain" and BOOST.Rain.CooldownSeconds == 1800
			and BOOST.Rain.Seconds == GameConfig.Weather.Auto.DurationSeconds,
		"SUMMON RAIN: the owner's 3717932732 at 199, 30 minutes apart, as long as a natural Rain")
	local wears = {}
	for _, v in pairs(GameConfig.BagLook.StudsByRarity or {}) do
		wears[v] = true
	end
	for _, v in pairs(GameConfig.BagLook.StudsByKind or {}) do
		wears[v] = true
	end
	for _, v in pairs(GameConfig.BagLook.StudsBySpecies or {}) do
		wears[v] = true
	end
	local coralShelves = 0
	for _, spec in ipairs(STORE.Sections) do
		if spec.studs == "coral" then
			coralShelves += 1
		end
	end
	local second = STORE.Sections[2]
	check(second and second.id == "Boosts" and second.studs == "coral" and coralShelves == 1
			and GameConfig.BagLook.Studs.coral ~= nil and not wears.coral and STORE.Sections[1].id == "Passes",
		"the BOOSTS shelf stands right under the passes, on the coral card nothing else wears")
	check(STORE.Icons.starterpack == "rbxassetid://133935209044475"
			and STORE.Icons.serverluck == "rbxassetid://127834257988056"
			and STORE.Icons.summonrain == "rbxassetid://134495129410572"
			and GameConfig.SourceIcons.luck == STORE.Icons.serverluck,
		"the owner's three icons; SERVER LUCK's on its chip and its line too")

	--==========================================================================
	say("\n-- 2. the Shop's cards --")
	--==========================================================================
	local entries = ShopCatalog.entries("Boosts")
	local byKey = {}
	for _, e in ipairs(entries) do
		byKey[e.key] = e
	end
	local inCats = false
	for _, c in ipairs(ShopCatalog.categories(false)) do
		inCats = inCats or c.id == "Boosts"
	end
	local sp, lk, rn = byKey.starterpack, byKey.serverluck, byKey.summonrain
	check(inCats and #entries == 3 and sp and lk and rn and sp.kind == "product" and sp.id == S.product
			and lk.kind == "product" and lk.id == L.product and rn.kind == "product" and rn.id == R.product,
		"the Shop draws the shelf for everybody: three live product cards", #entries)
	check(sp.benefit == S.benefit and sp.detail == S.detail and lk.benefit == L.benefit and rn.detail == R.detail
			and sp.icon == STORE.Icons.starterpack and rn.icon == STORE.Icons.summonrain and sp.studs == "coral",
		"each says its own words, under its own icon, on coral")
	check(sp.offer == "starter" and sp.odds == true and lk.offer == nil and not lk.odds and rn.summon == true
			and not sp.summon and not lk.summon,
		"the Starter Pack waits on its offer and carries REWARDS & ODDS; SUMMON RAIN waits out a clash")
	check(has(S.detail, "REWARDS & ODDS") and has(S.detail, "random"),
		"the Starter Pack's details say its tickets' prizes are random, and where the odds are")

	--==========================================================================
	say("\n-- 3. SERVER LUCK in a nest's roll --")
	--==========================================================================
	-- "Rarer" is rarer than the biome's own commonest: Common in Greenhollow,
	-- Uncommon in Dustbowl, Rare further down the road.
	local same, exact, kept, least, biomes, lifted = true, true, true, math.huge, 0, 0
	for _, biome in ipairs(BiomeData.Biomes) do
		local pool = SeedData.InBiome(biome.Id)
		if #pool > 0 then
			biomes += 1
			local base = SeedData.PoolWeights(pool)
			local lucky = SeedData.PoolWeights(pool, BOOST.Luck.Factor)
			local top = 0
			for i in ipairs(pool) do
				top = math.max(top, base[i])
			end
			local t0, t1, rarer = 0, 0, 0
			for i, species in ipairs(pool) do
				t0 += base[i]
				t1 += lucky[i]
				if base[i] ~= SeedData.RarityWeight[species.Rarity] then
					same = false
				end
				if base[i] >= top then
					least = math.min(least, lucky[i] / base[i])
				else
					rarer += 1
					if math.abs(lucky[i] - BOOST.Luck.Factor * base[i]) > 1e-9 then
						exact = false
					end
				end
			end
			if rarer > 0 then
				lifted += 1
			end
			if math.abs(t0 - t1) > 1e-9 * t0 then
				kept = false
			end
		end
	end
	check(biomes > 0 and same, "with no luck every weight is its rarity's, as it always was", biomes)
	check(exact and kept and lifted == biomes,
		"SERVER LUCK in every biome: each species rarer than the biome's commonest weighed exactly x2, the pool's "
			.. "total kept -- so each turns up exactly twice as often", string.format("%d of %d biomes", lifted, biomes))
	check(least > 0 and least < 1, "the commonest give up the difference, and every biome keeps some",
		string.format("%.3f of its commonest at the least", least))
	-- Each biome's shares, before and with the luck (for the owner's table).
	for _, biome in ipairs(BiomeData.Biomes) do
		local pool = SeedData.InBiome(biome.Id)
		if #pool > 0 then
			local base = SeedData.PoolWeights(pool)
			local lucky = SeedData.PoolWeights(pool, BOOST.Luck.Factor)
			local top, t0, t1, r0, r1 = 0, 0, 0, 0, 0
			for i in ipairs(pool) do
				top = math.max(top, base[i])
			end
			for i in ipairs(pool) do
				t0 += base[i]
				t1 += lucky[i]
				if base[i] < top then
					r0 += base[i]
					r1 += lucky[i]
				end
			end
			local name = "?"
			for _, sp in ipairs(pool) do
				if SeedData.RarityWeight[sp.Rarity] == top then
					name = sp.Rarity
				end
			end
			say(string.format("        %-12s commonest %-9s %5.1f%% -> %5.1f%%   rarer %5.1f%% -> %5.1f%%", biome.Id,
				name, 100 * (1 - r0 / t0), 100 * (1 - r1 / t1), 100 * r0 / t0, 100 * r1 / t1))
		end
	end
	-- THE EDGE (no biome is near it): a pool whose rarer species already hold
	-- more than half its weight cannot pay for x2 -- the commonest would go
	-- below nothing. They go TO nothing instead, never below: the rarer share
	-- the whole pool, each in its own proportion to the others, and the roll
	-- draws over that smaller total.
	local heavy = { { Rarity = "Uncommon" } }
	for _ = 1, 5 do
		table.insert(heavy, { Rarity = "Rare" })
	end
	local hw = SeedData.PoolWeights(heavy, BOOST.Luck.Factor)
	local evenly = #hw == 6
	for i = 2, 6 do
		evenly = evenly and hw[i] == BOOST.Luck.Factor * SeedData.RarityWeight.Rare
	end
	check(hw[1] == 0 and evenly,
		"the edge: rarer species already over half the weight -- the commonest go to nothing, never below, and the "
			.. "rarer share the pool in their own proportions", hw[1])
	local function oldRoll(pool, rng)
		local total = 0
		for _, species in ipairs(pool) do
			total += SeedData.RarityWeight[species.Rarity]
		end
		local pick = rng:NextNumber() * total
		for _, species in ipairs(pool) do
			pick -= SeedData.RarityWeight[species.Rarity]
			if pick <= 0 then
				return species
			end
		end
		return pool[#pool]
	end
	local equal, draws = true, 0
	for _, biome in ipairs(BiomeData.Biomes) do
		local pool = SeedData.InBiome(biome.Id)
		if #pool > 0 then
			local a, b = Random.new(7), Random.new(7)
			for _ = 1, 400 do
				draws += 1
				if SeedData.Roll(biome.Id, a) ~= oldRoll(pool, b) then
					equal = false
				end
			end
		end
	end
	check(equal, "no luck: the roll is the old one, draw for draw", draws .. " seeded draws")
	local home = BiomeData.Biomes[1].Id
	local pool = SeedData.InBiome(home)
	local base = SeedData.PoolWeights(pool)
	local rare, total = 0, 0
	for i, species in ipairs(pool) do
		total += base[i]
		if species.Rarity ~= "Common" then
			rare += base[i]
		end
	end
	local rng, n, hits = Random.new(11), 40000, 0
	for _ = 1, n do
		local species = SeedData.Roll(home, rng, BOOST.Luck.Factor)
		if species and species.Rarity ~= "Common" then
			hits += 1
		end
	end
	local want = 2 * rare / total
	check(math.abs(hits / n - want) < 0.01, "40,000 lucky draws in " .. home .. ": a rarer pod twice as often",
		string.format("%.4f against %.4f (%.4f without)", hits / n, want, rare / total))

	--==========================================================================
	say("\n-- 4. SERVER LUCK's clock --")
	--==========================================================================
	local luck = ServerBoost.newLuck()
	ServerBoost.addLuck(luck, 900, 1000, false, "Nicky")
	check(luck.endsAt == 1900 and ServerBoost.luckLeft(luck, 1000) == 900 and ServerBoost.luckFactor(luck, 1000, false) == 2,
		"bought: it runs at once, 15 minutes of x2")
	ServerBoost.addLuck(luck, 900, 1300, false, "Rin")
	check(luck.endsAt == 2800 and luck.total == 1800 and luck.by == "Rin",
		"another stacks on what is left, and names its buyer")
	check(ServerBoost.stepLuck(luck, 1400, true) == "paused" and luck.endsAt == nil and luck.left == 1400
			and ServerBoost.luckFactor(luck, 1400, true) == 1,
		"the Enchanted Mist starts: the clock stands still, worth nothing")
	check(ServerBoost.stepLuck(luck, 9000, true) == nil and ServerBoost.luckLeft(luck, 9000) == 1400,
		"however long the Mist lasts")
	check(ServerBoost.stepLuck(luck, 9500, false) == "resumed" and luck.endsAt == 10900
			and ServerBoost.luckFactor(luck, 9500, false) == 2,
		"the Mist ends: it runs on with what it had")
	check(ServerBoost.luckFactor(luck, 9600, true) == 1, "and is worth nothing the moment a Mist is on, before a step")
	check(ServerBoost.stepLuck(luck, 10900, false) == "ended" and ServerBoost.luckLeft(luck, 10900) == 0
			and luck.total == 0 and ServerBoost.luckFactor(luck, 10900, false) == 1,
		"and it runs out")
	local banked = ServerBoost.newLuck()
	ServerBoost.addLuck(banked, 900, 100, true, "Nicky")
	check(banked.endsAt == nil and banked.left == 900 and ServerBoost.luckFactor(banked, 100, true) == 1,
		"bought during the Mist: banked whole for after it")

	--==========================================================================
	say("\n-- 5. SUMMON RAIN's rules --")
	--==========================================================================
	check(ServerBoost.rainClash(true, true, true) == "rain" and ServerBoost.rainClash(false, true, true) == "mist"
			and ServerBoost.rainClash(false, false, true) == "rush" and ServerBoost.rainClash(false, false, false) == nil,
		"a summon clashes with weather in any state, the Enchanted Mist and a Pod Rush")
	check(ServerBoost.mayStartRain(nil, 0, 50) and not ServerBoost.mayStartRain(nil, 100, 50)
			and not ServerBoost.mayStartRain("mist", 0, 50),
		"one may start only with nothing clashing and the last one's cooldown over")
	check(ServerBoost.summonWord("rain", 0, 0) == "RAINING" and ServerBoost.summonWord("mist", 0, 0) == "MIST ON"
			and ServerBoost.summonWord("rush", 0, 0) == "POD RUSH" and ServerBoost.summonWord(nil, 1801, 1) == "WAIT 30:00"
			and ServerBoost.summonWord(nil, 100, 100) == nil,
		"the Shop's button says why it waits -- RAINING, MIST ON, POD RUSH, WAIT 30:00 -- and nothing once it may",
		ServerBoost.summonWord(nil, 1801, 1))

	--==========================================================================
	say("\n-- 6. the Starter Pack's offer --")
	--==========================================================================
	check(ServerBoost.starterUntil(1000, 0) == 1000 + 3 * DAY and ServerBoost.starterUntil(1000, 1) == 0
			and ServerBoost.starterUntil(0, 0) == 0,
		"offered for 3 days from the first join, and never once one was given")
	check(ServerBoost.starterOffered(5000, 4999, true) and not ServerBoost.starterOffered(5000, 5000, true)
			and not ServerBoost.starterOffered(5000, 10, false),
		"shown only inside its window, and only to a player who may hold a paid random item")

	--==========================================================================
	say("\n-- 7. ServerBoostService --")
	--==========================================================================
	local fakePlayers = {}
	local function newPlayer(id, name)
		local p = { UserId = id, Name = name, DisplayName = name, Parent = fakePlayers, attrs = {} }
		function p:GetAttribute(key)
			return self.attrs[key]
		end
		function p:SetAttribute(key, value)
			self.attrs[key] = value
		end
		return p
	end
	local nicky, rin, gone = newPlayer(1, "Nicky"), newPlayer(2, "Rin"), newPlayer(3, "Gone")
	local profiles = {
		[nicky] = { RainOwed = 0, StarterPacks = 0, CreatedAt = 5000 },
		[rin] = { RainOwed = 0, StarterPacks = 0, CreatedAt = 0 },
		[gone] = { RainOwed = 1, StarterPacks = 0, CreatedAt = 0 },
	}
	local PDS = {
		Get = function(p)
			return profiles[p]
		end,
		IsReady = function()
			return true
		end,
		AddRainOwed = function(p, delta)
			local prof = profiles[p]
			if not prof then
				return nil
			end
			local owed = prof.RainOwed + delta
			if owed < 0 then
				return nil
			end
			prof.RainOwed = owed
			return owed
		end,
	}
	local SBS = loadWith(Server.ServerBoostService, {
		PlayerDataService = PDS,
		NestService = {
			useLuck = function() end,
			RushOn = function()
				return false
			end,
		},
		WeatherService = {
			State = function()
				return nil
			end,
			StartRain = function()
				return false, "stand-in"
			end,
		},
		EnchantedMistService = {
			IsActive = function()
				return false
			end,
		},
		PodRushService = {
			Current = function()
				return nil
			end,
		},
	}, { Players = fakePlayers })
	SBS.Init()
	local world = { weather = false, mist = false, rush = false, now = 1000, here = { nicky, rin }, refuse = false }
	local started, sent, attrs = {}, {}, {}
	local H = SBS.Hooks
	H.now = function()
		return world.now
	end
	H.players = function()
		return world.here
	end
	H.send = function(p, action, payload)
		table.insert(sent, { p = p, action = action, payload = payload })
	end
	H.weather = function()
		return world.weather
	end
	H.mist = function()
		return world.mist
	end
	H.rush = function()
		return world.rush
	end
	H.startRain = function(by, seconds)
		if world.weather or world.refuse then
			return false, "Rain is already falling"
		end
		table.insert(started, { by = by, seconds = seconds })
		world.weather = true
		return true, "started"
	end
	H.publish = function(name, value)
		attrs[name] = value
	end
	local LA, RA = BOOST.Luck.Attributes, BOOST.Rain.Attributes

	local granted = SBS.GrantLuck(nicky, 900)
	local first = sent[1]
	check(granted and SBS.Luck() == 2 and attrs[LA.EndsAt] == 1900 and attrs[LA.By] == "Nicky"
			and attrs[LA.Total] == 900 and attrs[LA.Left] == nil,
		"SERVER LUCK lands: x2 in the nests now, its end, its run and its buyer published")
	check(#sent == 2 and first.action == Notice.ServerNotice and first.payload.icon == "luck"
			and has(first.payload.title, "Nicky") and has(first.payload.title, "SERVER LUCK")
			and Notice.readServerNotice(first.payload) ~= nil,
		"and the buyer's name is said to everybody here", first and first.payload.title)
	world.mist = true
	SBS.Step()
	check(SBS.Luck() == 1 and attrs[LA.EndsAt] == nil and attrs[LA.Left] == 900,
		"the Enchanted Mist: it stands still, worth nothing, its time kept on the chip")
	world.now = 4000
	SBS.Step()
	check(attrs[LA.Left] == 900, "for as long as the Mist lasts")
	world.mist = false
	SBS.Step()
	check(SBS.Luck() == 2 and attrs[LA.EndsAt] == 4900 and attrs[LA.Left] == nil,
		"after it: x2 again, with all it had")
	world.now = 4900
	SBS.Step()
	check(SBS.Luck() == 1 and attrs[LA.EndsAt] == nil and attrs[LA.Total] == nil and attrs[LA.By] == nil,
		"and it runs out, the chip gone")

	table.clear(sent)
	world.now = 10000
	world.mist = true
	local owed = SBS.GrantRain(nicky)
	SBS.Step()
	check(owed and profiles[nicky].RainOwed == 1 and #started == 0 and attrs[RA.Clash] == "mist",
		"a Rain bought while the Mist is on (a race) is owed on the buyer's profile, not started; the button says why")
	world.mist = false
	SBS.Step()
	check(#started == 1 and started[1].by == nicky and started[1].seconds == BOOST.Rain.Seconds
			and profiles[nicky].RainOwed == 0 and attrs[RA.ReadyAt] == 10000 + BOOST.Rain.CooldownSeconds
			and attrs[RA.Clash] == "rain",
		"the moment nothing clashes it starts, for its buyer, owed no more; the cooldown runs; the button says RAINING")
	local told = 0
	for _, m in ipairs(sent) do
		if m.action == Notice.ServerNotice and has(m.payload.title, "Nicky summoned the RAIN") then
			told += 1
		end
	end
	check(told == 2, "and everybody is told who summoned it", told)
	world.weather = false
	SBS.GrantRain(rin)
	world.now = 10000 + BOOST.Rain.CooldownSeconds - 1
	SBS.Step()
	check(#started == 1 and profiles[rin].RainOwed == 1 and attrs[RA.Clash] == nil
			and attrs[RA.ReadyAt] == 10000 + BOOST.Rain.CooldownSeconds,
		"a second, bought within the cooldown, waits it out, owed")
	world.now = 10000 + BOOST.Rain.CooldownSeconds
	SBS.Step()
	check(#started == 2 and started[2].by == rin and profiles[rin].RainOwed == 0 and attrs[RA.ReadyAt] ~= nil,
		"and starts the moment it is over")
	check(profiles[gone].RainOwed == 1, "one owed to a player who left stays on their profile, for their next server")
	world.weather = false
	world.now = 99999
	world.refuse = true
	world.here = { gone }
	SBS.Step()
	check(#started == 2 and profiles[gone].RainOwed == 1,
		"and a Rain that will not start (the weather beat it) is never spent: still owed")
	world.refuse = false
	SBS.Step()
	check(#started == 3 and started[3].by == gone and profiles[gone].RainOwed == 0,
		"until it does, wherever its buyer is")

	SBS.PublishStarter(nicky)
	check(nicky.attrs[BOOST.Starter.Attribute] == 5000 + 3 * DAY,
		"the Starter Pack's offer on the player: 3 days from their first join")
	profiles[nicky].StarterPacks = 1
	SBS.PublishStarter(nicky)
	check(nicky.attrs[BOOST.Starter.Attribute] == 0, "and none once one is given")

	--==========================================================================
	say("\n-- 8. StoreService's receipts --")
	--==========================================================================
	local trace = {}
	local function rec(name, ...)
		table.insert(trace, { name = name, args = { ... } })
	end
	local function indexOf(name)
		for i, t in ipairs(trace) do
			if t.name == name then
				return i
			end
		end
		return nil
	end
	local profile = { Receipts = {}, Cash = 0, WheelBought = 0, StarterPacks = 0 }
	local policy = { known = false, ok = false }
	local carry = { room = 5, pod = true, backpack = true }
	local storePlayers = {}
	local buyer = { Name = "SpecBuyer", UserId = 4243, DisplayName = "SpecBuyer", Parent = storePlayers }
	function buyer:FindFirstChildOfClass(className)
		return if className == "Backpack" and carry.backpack then {} else nil
	end
	function storePlayers:GetPlayerByUserId(id)
		return if id == buyer.UserId then buyer else nil
	end
	local receiptCallback = nil
	local market = setmetatable({}, {
		__newindex = function(t, key, value)
			if key == "ProcessReceipt" then
				receiptCallback = value
			else
				rawset(t, key, value)
			end
		end,
	})
	local Store = loadWith(Server.StoreService, {
		PlayerDataService = {
			Get = function(p)
				return if p == buyer then profile else nil
			end,
			Save = function()
				rec("Save")
				return true
			end,
			AddCash = function(_, amount)
				rec("AddCash", amount)
				profile.Cash += amount
				return profile.Cash
			end,
			IsPersistent = function()
				return true
			end,
			AddStarterPack = function()
				rec("AddStarterPack")
				profile.StarterPacks += 1
				return profile.StarterPacks
			end,
		},
		CarryService = {
			PodRoom = function()
				return carry.room, 0, true
			end,
			GivePod = function(_, species, tier)
				rec("GivePod", species, tier)
				return carry.pod
			end,
		},
		TreadmillService = {
			PayReward = function()
				return true
			end,
		},
		PlantService = {
			InstantHatch = function()
				return true
			end,
		},
		WheelService = {
			PaidAllowed = function()
				return policy.known and policy.ok
			end,
			CheckPolicy = function()
				rec("CheckPolicy")
				policy.known = true
				return true
			end,
			GrantBought = function(_, quantity)
				rec("GrantBought", quantity)
				profile.WheelBought += quantity
				return true
			end,
			TakeBackBought = function(_, quantity)
				rec("TakeBackBought", quantity)
				profile.WheelBought -= quantity
				return true
			end,
		},
		ServerBoostService = {
			GrantLuck = function(_, seconds)
				rec("GrantLuck", seconds)
				return true
			end,
			GrantRain = function()
				rec("GrantRain")
				return true
			end,
			PublishStarter = function()
				rec("PublishStarter")
			end,
		},
	}, { MarketplaceService = market, Players = storePlayers })
	Store.Init()
	Store.Start()
	local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
	local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet
	local function receipt(productId, purchaseId)
		return receiptCallback({ PlayerId = buyer.UserId, ProductId = productId, PurchaseId = purchaseId })
	end
	local function nothingGiven()
		return indexOf("GrantBought") == nil and indexOf("GivePod") == nil and indexOf("AddCash") == nil
			and indexOf("AddStarterPack") == nil
	end
	check(type(receiptCallback) == "function", "StoreService takes the one ProcessReceipt")

	table.clear(trace)
	local restricted = receipt(S.product, "spec-starter-1")
	check(restricted == RETRY and indexOf("CheckPolicy") == 1 and nothingGiven() and profile.WheelBought == 0,
		"a player who may not hold paid random items: the policy is asked FIRST, nothing is given, not acknowledged")
	policy.ok = true
	carry.room = 0
	table.clear(trace)
	local noRoom = receipt(S.product, "spec-starter-1")
	carry.room = 5
	carry.backpack = false
	local noBag = receipt(S.product, "spec-starter-1")
	carry.backpack = true
	check(noRoom == RETRY and noBag == RETRY and nothingGiven(),
		"no room for the pod, or no Backpack to hand it into: nothing at all is given")
	carry.pod = false
	table.clear(trace)
	local podFailed = receipt(S.product, "spec-starter-1")
	carry.pod = true
	local back = indexOf("TakeBackBought")
	check(podFailed == RETRY and indexOf("GrantBought") ~= nil and back ~= nil and trace[back].args[1] == 5
			and indexOf("AddCash") == nil and profile.WheelBought == 0 and profile.Cash == 0,
		"the pod still would not land: its tickets taken back, no cash -- none of the three, and Roblox asks again")
	table.clear(trace)
	local whole = receipt(S.product, "spec-starter-1")
	local g, p, c, a, pub, sv = indexOf("GrantBought"), indexOf("GivePod"), indexOf("AddCash"), indexOf("AddStarterPack"),
		indexOf("PublishStarter"), indexOf("Save")
	check(whole == GRANTED and g and p and c and a and pub and sv and g < p and p < c and c < a and a < pub and pub < sv
			and trace[g].args[1] == 5 and trace[p].args[1] == "petalpip" and trace[p].args[2] == 6
			and trace[c].args[1] == 800e3,
		"all three, in one step: 5 tickets, the Titan Petalpip, $800K; counted, the offer withdrawn, then saved")
	check(profile.Cash == 800e3 and profile.WheelBought == 5 and profile.StarterPacks == 1,
		"the profile holds the pack", string.format("$%d, %d tickets, %d pack(s)", profile.Cash, profile.WheelBought,
			profile.StarterPacks))
	table.clear(trace)
	local again = receipt(S.product, "spec-starter-1")
	check(again == GRANTED and indexOf("AddCash") == nil and indexOf("GivePod") == nil,
		"the same receipt again: acknowledged, nothing given twice (the ledger)")
	table.clear(trace)
	local duplicate = receipt(S.product, "spec-starter-2")
	check(duplicate == GRANTED and profile.StarterPacks == 2 and profile.Cash == 1600e3,
		"a second Starter Pack bought anyway is still given whole -- it is the player's Robux -- and logged")
	table.clear(trace)
	local luckReceipt = receipt(L.product, "spec-luck-1")
	local rainReceipt = receipt(R.product, "spec-rain-1")
	local gl, gr = indexOf("GrantLuck"), indexOf("GrantRain")
	check(luckReceipt == GRANTED and rainReceipt == GRANTED and gl and trace[gl].args[1] == 900 and gr ~= nil,
		"SERVER LUCK's receipt grants its 15 minutes; SUMMON RAIN's owes its Rain; both saved, then acknowledged")

	--==========================================================================
	say("\n-- 9. the profile, and the wiring --")
	--==========================================================================
	local d = ProfileSchema.Default()
	local s1 = ProfileSchema.Sanitise({ StarterPacks = 2, RainOwed = 3 })
	local s2 = ProfileSchema.Sanitise({ StarterPacks = -4, RainOwed = "x" })
	local s3 = ProfileSchema.Sanitise({ RainOwed = 1e9 })
	local s4 = ProfileSchema.Sanitise({})
	check(d.StarterPacks == 0 and d.RainOwed == 0 and s1.StarterPacks == 2 and s1.RainOwed == 3
			and s2.StarterPacks == 0 and s2.RainOwed == 0 and s3.RainOwed == GameConfig.Save.MaxRainOwed
			and s4.StarterPacks == 0 and s4.RainOwed == 0,
		"the profile's two fields: none at first, saved whole, clamped, an old save reads 0")
	local pds = sourceOf(Server, "PlayerDataService")
	check(has(pds, "StarterPacks = math.max(0, math.floor(tonumber(profile.StarterPacks) or 0)),")
			and has(pds, "RainOwed = math.max(0, math.floor(tonumber(profile.RainOwed) or 0)),"),
		"a progress reset keeps both: the pack is never offered again, a paid Rain never dropped")
	local nest = sourceOf(Server, "NestService")
	local boostSrc = sourceOf(Server, "ServerBoostService")
	local _, lucky = string.gsub(nest, "growPod%(nest, %w+, luckOf%(%)%)", "")
	check(has(nest, "local species = SeedData.Roll(nest.biome.Id, rng, luck)") and lucky == 2
			and has(nest, "growPod(nest, i, luckOf())") and has(nest, "growPod(nest, index, luckOf())")
			and has(nest, "\t\t\t\t\tgrowPod(nest, slot)\n")
			and has(boostSrc, "NestService.useLuck(ServerBoostService.Luck)"),
		"only NATURAL stocking takes the luck -- a nest built and the restock; a Pod Rush's regrow keeps normal odds",
		lucky)
	local rolls = 0
	for _, m in ipairs(Server:GetDescendants()) do
		if m:IsA("LuaSourceContainer") then
			local _, n = string.gsub(m.Source, "SeedData%.Roll%(", "")
			rolls += n
		end
	end
	local rainBatch = string.match(sourceOf(Shared, "SeedData"), "function SeedData%.RollRainBatch%((.-)\nend\n") or ""
	local secret = string.match(nest, "local function rollSecret%((.-)\nend\n") or ""
	check(rolls == 3 and has(sourceOf(Server, "PodRushService"), "SeedData.Roll(biomeId, Hooks.random())")
			and has(sourceOf(Server, "DebugService"), "SeedData.Roll(biome, Random.new(os.clock() * 1000 % 1e6))")
			and rainBatch ~= "" and not has(rainBatch, "luck") and not has(rainBatch, "PoolWeights")
			and secret ~= "" and not has(secret, "luck"),
		"and nothing else sees it: the Rain's event batch, the Pod Rush's Titan, a nest's Secret, a spawn; the Mist's "
			.. "and the Mysterious Pod's never roll a nest at all", rolls)
	local order = GameConfig.BoostIcons.Order
	check(order[1] == "weather" and order[2] == "luck", "SERVER LUCK's chip stands beside the weather's")
	local running = BoostIcons.entries({ now = 100, luckEndsAt = 700, luckTotal = 900, luckBy = "Nicky" })
	local standing = BoostIcons.entries({ now = 100, luckLeft = 450, luckTotal = 900 })
	local r1, s1e = running[1], standing[1]
	check(r1 and r1.id == "luck" and r1.source == "luck" and r1.endsAt == 700 and r1.total == 900
			and has(r1.hint or "", "Nicky") and has(r1.effect, "x2"),
		"its chip while it runs: its time, its ring, its buyer", r1 and r1.hint)
	check(s1e and s1e.id == "luck" and s1e.endsAt == 550 and s1e.hint == GameConfig.BoostIcons.Words.LuckPaused
			and BoostIcons.fraction(s1e, 100) == 0.5 and #BoostIcons.entries({ now = 100 }) == 0,
		"while the Mist stands it still: the time it has, unmoving, and why; none at all while it is off")
	check(BoostIcons.timeLine(s1e, 100) == "Paused: 7:30 left" and BoostIcons.timeLine(r1, 100) == "Ends in 10:00",
		"its time says what is left while it stands still, and when it ends while it runs",
		BoostIcons.timeLine(s1e, 100))
	local watchedLuck = 0
	for _, w in ipairs(BoostIcons.watched()) do
		for _, name in pairs(BOOST.Luck.Attributes) do
			if w.on == "workspace" and w.name == name then
				watchedLuck += 1
			end
		end
	end
	check(watchedLuck == 4, "and it redraws the moment any of its attributes change", watchedLuck)
	local shop = sourceOf(Scripts, "ShopUI")
	check(has(shop, "local shownNow = offered(entry)") and has(shop, "card.holder.Visible = shownNow")
			and has(shop, "if offered(entry) then")
			and has(shop, "if (entry.summon and summonWord() ~= nil) or not offered(entry) then")
			and has(shop, "elseif waitWord then")
			and has(shop, "detailOdds.hit.Visible = entry.kind == \"spin\" or entry.odds == true"),
		"the Shop: the Starter Pack shown and counted only while offered, SUMMON RAIN refused and grey while it waits, "
			.. "REWARDS & ODDS beside the pack")
	local store = sourceOf(Server, "StoreService")
	check(has(store, "return ServerBoostService.GrantLuck(player, item.seconds or 0)")
			and has(store, "return ServerBoostService.GrantRain(player)") and has(store, "return grantStarter(player, item)"),
		"StoreService grants all three kinds through the one ledger")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nServerBoostSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
