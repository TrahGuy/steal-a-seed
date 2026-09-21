--!nocheck
--==============================================================================
-- Podnappers :: OfflineEarningsSpec
--
-- A garden that earned while its owner was away, end to end without a Play
-- session:
--
--   1. OfflineEarnings.garden / accrue on plain profile tables: the 20-minute
--      threshold, half speed, the 8-hour cap, carry-over, pods and junk rows,
--      clock skew, NaN, the cash cap.
--   2. ProfileSchema: the three new fields migrate by being absent and are
--      clamped like every other number.
--   3. The REAL EconomyService.ClaimOffline, loaded from its Source with its
--      neighbours stood in: pays pending x pass once, then nothing.
--   4. The wiring, by text: credited at load before anything can write,
--      claimed by one verb, and a card with no close button.
--
-- Not here: the card itself and the attributes on a real Player, which need a
-- client. The Play notes in KB/HANDOFF cover those.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Offline = require(Server:WaitForChild("OfflineEarnings"))
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local OFF = SeedData.Offline
local GROWN, POD = CreatureModel.STAGE_GROWN, CreatureModel.STAGE_POD
local MAX_CASH = GameConfig.Save.MaxCash

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

local function row(id, tier, stage)
	return { SpeciesId = id, Tier = tier, Stage = stage, PlantedAt = 0, HatchAt = 0, X = 0, Z = 0, Facing = 0 }
end
local NOW = 1800000000
local function profile(awaySeconds, plants, extra)
	local p = { LastSeen = NOW - awaySeconds, Plants = plants, OfflineCash = 0, OfflineSeconds = 0, OfflineAway = 0 }
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	return p
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE ARITHMETIC
	--==========================================================================
	say("-- the garden --")
	local nub, bell = SeedData.Get("nubkin"), SeedData.Get("bellchime")
	local rows = { row("nubkin", 1, GROWN), row("bellchime", 7, GROWN), row("nubkin", 7, POD),
		row("no_such_plant", 3, GROWN), row("nubkin", 0 / 0, GROWN), "junk" }
	local garden = Offline.garden(rows)
	local rate = SeedData.IncomePerSecond(nub, 1) + SeedData.IncomePerSecond(bell, 7)
	check(garden.grown == 2 and garden.rate == rate,
		"only grown plants of real species with a real tier earn; pods and junk rows do not",
		string.format("%d grown, %.0f/s (want %.0f)", garden.grown, garden.rate, rate))
	check(garden.best == "bellchime" and garden.bestTier == 7, "the best earner is the card's portrait",
		tostring(garden.best))
	local good = { row("nubkin", 1, GROWN), row("bellchime", 7, GROWN) }

	say("-- one absence --")
	local p = profile(OFF.MinAwaySeconds - 60, good)
	local added = Offline.accrue(p, NOW)
	check(added == 0 and p.OfflineCash == 0 and p.OfflineSeconds == 0,
		"gone 19 minutes: nothing -- a server hop is not away")
	p = profile(OFF.MinAwaySeconds, good)
	local credited
	added, credited = Offline.accrue(p, NOW)
	check(credited == OFF.MinAwaySeconds and added == math.floor(rate * OFF.MinAwaySeconds * OFF.Efficiency),
		"gone exactly 20 minutes: all 20 are credited, at half speed", string.format("%s / %s", added, credited))
	p = profile(3 * 3600, good)
	added, credited = Offline.accrue(p, NOW)
	check(credited == 3 * 3600 and added == math.floor(rate * 3 * 3600 * OFF.Efficiency)
		and p.OfflineCash == added and p.OfflineSeconds == 3 * 3600 and p.OfflineAway == 3 * 3600,
		"gone 3 hours: 3 hours at half speed, recorded as the claim", string.format("%s", added))
	p = profile(30 * 86400, good)
	added, credited = Offline.accrue(p, NOW)
	check(credited == OFF.MaxCreditSeconds and p.OfflineAway == 30 * 86400,
		"gone 30 days: credited the 8-hour cap, and the real absence is kept for the card")

	say("-- carrying an unclaimed claim --")
	local earlier = math.floor(rate * 6 * 3600 * OFF.Efficiency)
	p = profile(5 * 3600, good, { OfflineCash = earlier, OfflineSeconds = 6 * 3600, OfflineAway = 6 * 3600 })
	added, credited = Offline.accrue(p, NOW)
	check(credited == 2 * 3600 and p.OfflineSeconds == OFF.MaxCreditSeconds
		and p.OfflineCash == earlier + math.floor(rate * 2 * 3600 * OFF.Efficiency)
		and p.OfflineAway == 11 * 3600,
		"an unopened 6-hour claim plus 5 more hours tops up to the 8-hour cap, not 11")
	p = profile(5 * 3600, good, { OfflineCash = 99, OfflineSeconds = OFF.MaxCreditSeconds })
	added = Offline.accrue(p, NOW)
	check(added == 0 and p.OfflineCash == 99, "a claim already at the cap takes no more")

	say("-- what must credit nothing --")
	p = profile(-3600, good)
	check(Offline.accrue(p, NOW) == 0 and p.OfflineCash == 0, "a LastSeen in the future (clock skew) credits nothing")
	p = profile(0, good)
	p.LastSeen = 0 / 0
	check(Offline.accrue(p, NOW) == 0, "a NaN LastSeen credits nothing")
	p = profile(3 * 3600, { row("nubkin", 7, POD) })
	check(Offline.accrue(p, NOW) == 0 and p.OfflineCash == 0 and p.OfflineSeconds == 0,
		"a garden of pods earns nothing and leaves no claim behind")
	p = profile(3 * 3600, good, { OfflineCash = MAX_CASH - 5 })
	Offline.accrue(p, NOW)
	check(p.OfflineCash == MAX_CASH, "the claim is capped at the cash cap")

	--==========================================================================
	-- 2. THE SAVE FORMAT
	--==========================================================================
	say("\n-- the save --")
	local d = ProfileSchema.Default()
	check(d.OfflineCash == 0 and d.OfflineSeconds == 0 and d.OfflineAway == 0, "a new profile has no claim")
	local old = ProfileSchema.Sanitise({ Cash = 5 })
	check(old.OfflineCash == 0 and old.OfflineSeconds == 0 and old.OfflineAway == 0,
		"a save from before offline earnings migrates by being absent")
	local junk = ProfileSchema.Sanitise({ OfflineCash = "lots", OfflineSeconds = 0 / 0, OfflineAway = -5 })
	check(junk.OfflineCash == 0 and junk.OfflineSeconds == 0 and junk.OfflineAway == 0,
		"strings, NaN and negatives read as no claim")
	local huge = ProfileSchema.Sanitise({ OfflineCash = 1e99, OfflineSeconds = 1e9, OfflineAway = 12345.7 })
	check(huge.OfflineCash == MAX_CASH and huge.OfflineSeconds == OFF.MaxCreditSeconds and huge.OfflineAway == 12345,
		"a corrupt claim is clamped to the cash cap and the 8-hour cap")
	local kept = ProfileSchema.Sanitise({ OfflineCash = 5000, OfflineSeconds = 3600, OfflineAway = 7200 })
	check(kept.OfflineCash == 5000 and kept.OfflineSeconds == 3600 and kept.OfflineAway == 7200,
		"a real claim survives a save and load")

	--==========================================================================
	-- 3. THE PAYOUT, THROUGH THE REAL ECONOMYSERVICE
	--==========================================================================
	say("\n-- the claim --")
	local fakePlayers = {}
	local claimant = { Name = "SpecClaimant", UserId = 4244, Parent = fakePlayers }
	function fakePlayers:GetPlayers()
		return { claimant }
	end
	local pending = { cash = 1234567, seconds = 3600, away = 5400 }
	local ready = true
	local wallet = 0
	local adds, takes = 0, 0
	local PlayerDataService = {
		IsReady = function()
			return ready
		end,
		TakeOffline = function()
			takes += 1
			if pending.cash > 0 then
				local c, s, a = pending.cash, pending.seconds, pending.away
				pending.cash, pending.seconds, pending.away = 0, 0, 0
				return c, s, a
			end
			return nil, 0, 0
		end,
		AddCash = function(_, amount)
			adds += 1
			wallet = math.clamp(wallet + amount, 0, MAX_CASH)
			return wallet
		end,
		Get = function()
			return { Cash = wallet }
		end,
	}
	local PassService = {
		CashMultiplier = function()
			return 2
		end,
	}
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return fakePlayers
		end
		return game:GetService(name)
	end
	local siblings = {
		PlotService = {}, PlantService = {}, PlayerDataService = PlayerDataService,
		CarryService = {}, PassService = PassService,
	}
	local module = Server:WaitForChild("EconomyService")
	local chunk, loadErr = loadstring(module.Source, "=EconomyService")
	assert(chunk, tostring(loadErr))
	local parent = {}
	function parent:WaitForChild(name)
		assert(siblings[name] ~= nil, "EconomyService asked for an unexpected sibling " .. name)
		return { __standIn = siblings[name] }
	end
	local outerRequire = require
	setfenv(chunk, setmetatable({
		game = fakeGame,
		script = { Name = "EconomyService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Economy = chunk()

	local paid, reason = Economy.ClaimOffline(claimant)
	check(paid == 2469134 and reason == "OK" and wallet == 2469134 and adds == 1,
		"the claim pays pending x the pass, through AddCash, once", string.format("%s %s", tostring(paid), reason))
	local again, why = Economy.ClaimOffline(claimant)
	check(again == nil and why == "NOTHING" and adds == 1 and wallet == 2469134,
		"a second claim -- a double tap, a spammed remote -- pays nothing")
	pending.cash = 500
	ready = false
	local takesBefore = takes
	local early, whyEarly = Economy.ClaimOffline(claimant)
	check(early == nil and whyEarly == "NOT_READY" and takes == takesBefore and pending.cash == 500,
		"before the profile is ready the claim is not touched")
	ready = true
	claimant.Parent = nil
	local gone, whyGone = Economy.ClaimOffline(claimant)
	check(gone == nil and whyGone == "GONE" and pending.cash == 500, "a player who has left is not paid")
	claimant.Parent = fakePlayers
	pending.cash = MAX_CASH
	wallet = MAX_CASH - 10
	Economy.ClaimOffline(claimant)
	check(wallet == MAX_CASH, "a claim cannot push the wallet past the cash cap")

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("\n-- the wiring --")
	local pds = (Server:WaitForChild("PlayerDataService") :: any).Source :: string
	local accrueAt = pds:find("OfflineEarnings.accrue(profile, os.time())", 1, true)
	local entryAt = pds:find("entries[player] = {", 1, true)
	check(accrueAt ~= nil and entryAt ~= nil and accrueAt < entryAt
		and pds:find('if status == "ok" then', 1, true) ~= nil
		and pds:find('dirty = status == "new" or offlineAdded > 0', 1, true) ~= nil,
		"the absence is credited at load, before the entry exists to be written, and marks it dirty")
	check(pds:find("function PlayerDataService.TakeOffline", 1, true) ~= nil
		and pds:find("PlayerDataService.PublishOffline(player)", 1, true) ~= nil,
		"the claim is published to the player and taken in one place")
	local eco = module.Source
	check(eco:find("if action ~= OFFLINE.ClaimAction then", 1, true) ~= nil
		and eco:find("EconomyService.ClaimOffline(player)", 1, true) ~= nil,
		"one verb on GameEvent claims, carrying nothing")
	local ui = StarterPlayer:WaitForChild("StarterPlayerScripts"):FindFirstChild("OfflineUI")
	local uiSource = if ui then (ui :: any).Source :: string else ""
	check(uiSource:find("modal.close.Visible = false", 1, true) ~= nil
		and uiSource:find("channel:FireServer(OFFLINE.ClaimAction)", 1, true) ~= nil,
		"the card has no close button and claims with the bare verb")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw: " .. tostring(err))
end

say(string.format("\nOfflineEarningsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
