--!nocheck
--==============================================================================
-- Steal a Seed :: EnchantedMistSpec (2026-10-11, stage 1 of the staged build)
--
-- Enchanted Mist's schedule and its shared sign, in Edit:
--
--   1. the numbers: the confirmed rules (carry 5, 10 per pod, 30 s hatch, the
--      15-cumulative example), the schedule, the confirmed odds and their picks
--   2. the sign's words: every state, truthful -- COMING SOON, "Next Mist in",
--      waiting with an ESTIMATE, resetting, active, syncing; and how big it
--      draws: its built studs near, never under MinHeaderUnits far, growing
--      upward
--   3. the coordinator on a fake clock: off while switched off or missing a
--      binding; a random 20-60 min first eligibility; starts only on an
--      eligible, natural, completed dawn with the road open; never twice for
--      one dawn; 300 s active; the next eligibility 60 min from the START; a
--      forced night ends it; its start and end heard once each; AN ADMIN'S
--      MIST (2026-10-11): the console's start and end, with the schedule on
--      (it counts as a start) and OFF (it runs anyway, the schedule
--      untouched, back to disabled at its end); refused while one runs, at
--      Night, or with a binding missing
--   4. WorldCycleService's dawn hook: told after a completed dawn, natural or
--      forced (with its source), never for a night or a failed dawn, and a
--      throwing listener cannot fail the dawn
--   5. the wiring: the event off by default; the shared sign ON (the owner,
--      2026-10-11), drawn to its MaxDistance at its smallest size
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local EnchantedMistStatus = require(Shared:WaitForChild("EnchantedMistStatus"))

local STATES = EnchantedMistConfig.States
local WORDS = EnchantedMistConfig.Sign.Words
local ATTR = EnchantedMistConfig.Attributes

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

local Server = ServerScriptService:WaitForChild("SeedGameServer")

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE NUMBERS
	--==========================================================================
	say("-- the numbers --")
	local D = EnchantedMistData
	check(D.CarryCap == 5 and D.BerriesPerPod == 10 and D.HatchSeconds == 30,
		"confirmed: carry 5, ten deposited berries a pod, a 30-second hatch")
	check(D.Schedule.ActiveSeconds == 300 and D.Schedule.CooldownSeconds == 3600 and D.Schedule.FirstEligibleMin == 1200
			and D.Schedule.FirstEligibleMax == 3600,
		"confirmed schedule: 5 minutes active, eligible 60 min after a start, a new server's first 20-60 min in")
	local p1, r1 = D.deliver(0, 5)
	local p2, r2 = D.deliver(r1, 5)
	local p3, r3 = D.deliver(r2, 5)
	check(p1 == 0 and r1 == 5 and p2 == 1 and r2 == 0 and p3 == 0 and r3 == 5,
		"15 delivered, five at a time: 5/10, then a pod and 0/10, then 5/10 toward the next")
	local p4, r4 = D.deliver(9, 5)
	check(p4 == 1 and r4 == 4, "9 saved + 5 carried: one pod, 4 left (a delivery earns at most one)")
	local total = 0
	for _, e in ipairs(D.Pool.Entries) do
		total += e.Weight
	end
	-- CONFIRMED by the owner 2026-10-11, weights and versions as they stood.
	check(math.abs(total - 100) < 1e-9 and D.Pool.Approved == true and D.Sizes.Approved == true
			and D.Pool.Version == 1 and D.Sizes.Version == 1,
		"the creature odds add to 100%; both tables confirmed, versions unchanged", total)
	check(D.pickCreature(0).Id == "mossbristle" and D.pickCreature(0.5999).Id == "mossbristle"
			and D.pickCreature(0.6).Id == "briarstag" and D.pickCreature(0.999).Id == "snarlbloom"
			and D.pickCreature(0.995).Id == "gnarlmaw",
		"a uniform draw lands on the right creature at each boundary")
	local grovemaw = false
	for _, e in ipairs(D.Pool.Entries) do
		if e.Id == "grovemaw" then
			grovemaw = true
		end
	end
	check(not grovemaw and not D.isSized("Secret") and D.isSized("Legendary") and D.isSized("Divine"),
		"Grovemaw is never in the pool; Secrets roll no size, Legendary to Divine do")
	check(D.pickSize(0) == 1 and D.pickSize(0.9999) == 7 and math.abs(D.sizeChance(1) - 53.25) < 0.01
			and math.abs(D.creatureChance("gnarlmaw") - 0.8) < 1e-9,
		"sizes Tiny..Colossal from the same weights the Odds panel shows")

	--==========================================================================
	-- 2. THE SIGN'S WORDS
	--==========================================================================
	say("-- the sign --")
	local function v(t)
		t.nightPhase = "Night"
		t.nightSeconds = 15
		return t
	end
	local now = 1000
	local a, b = EnchantedMistStatus.describe(v({ state = STATES.Disabled }), now)
	check(a == WORDS.ComingSoon and b == nil, "switched off or missing a binding: COMING SOON")
	a, b = EnchantedMistStatus.describe(v({ state = STATES.Cooldown, eligibleAt = now + 3600 }), now)
	check(a == "Next Mist in 60:00" and b == WORDS.CooldownNote and WORDS.CooldownNote == "Begins after biome reset",
		"cooling down: Next Mist in (the owner's words for kids, 2026-10-12), and it begins after a reset", tostring(a))
	a, b = EnchantedMistStatus.describe(v({ state = STATES.Eligible, eligibleAt = now - 5, worldPhase = "Day",
		worldPhaseEndsAt = now + 100 }), now)
	check(a == WORDS.Eligible and b == "Estimated start in ~01:55",
		"eligible by day: Waiting for biome reset, and the start only as an ESTIMATE (dusk + the night)", tostring(b))
	a, b = EnchantedMistStatus.describe(v({ state = STATES.Eligible, eligibleAt = now - 5, worldPhase = "Night",
		worldPhaseEndsAt = now + 15 }), now)
	check(a == "Biomes resetting · 00:15" and b == nil, "eligible during the reset: Biomes resetting", tostring(a))
	a = EnchantedMistStatus.describe(v({ state = STATES.Active, endsAt = now + 300 }), now)
	check(a == "ACTIVE · Ends in 05:00", "active: ACTIVE · Ends in 05:00", tostring(a))
	check(EnchantedMistStatus.describe(v({ state = STATES.Active, endsAt = now - 1 }), now) == WORDS.Syncing
			and EnchantedMistStatus.describe(v({}), now) == WORDS.Syncing
			and EnchantedMistStatus.describe(v({ state = STATES.Cooldown }), now) == WORDS.Syncing,
		"a deadline past, no state, or a state without its time: Syncing -- never a stale 00:00")
	check(EnchantedMistStatus.clock(0.2) == "00:01" and EnchantedMistStatus.clock(0) == "00:00"
			and EnchantedMistStatus.clock(61) == "01:01",
		"the clock rounds up: it never shows 00:00 while time is left")
	-- How big it draws (EnchantedMistConfig.Sign, READ FROM THE PLOTS): a
	-- phone's screen (the owner's, 367 points tall) and a 1080p window's (1022
	-- pixels), the default FieldOfView.
	local SIGN = EnchantedMistConfig.Sign
	local tall = SIGN.Height + SIGN.SubHeight + SIGN.NoteHeight
	local function headerUnits(distance, screen)
		return SIGN.Height * EnchantedMistStatus.signScale(distance, screen, 70) * (screen / 2)
			/ math.tan(math.rad(35)) / distance
	end
	check(EnchantedMistStatus.signScale(20, 367, 70) == 1 and EnchantedMistStatus.signScale(112.6, 1022, 70) == 1
			and headerUnits(112.6, 1022) > SIGN.MinHeaderUnits,
		"near, or a computer's camera at a plot's gate (112.6 away): the studs it is built at")
	local phone = EnchantedMistStatus.signScale(112.6, 367, 70)
	check(phone > 1.5 and math.abs(headerUnits(112.6, 367) - SIGN.MinHeaderUnits) < 1e-6
			and math.abs(headerUnits(257, 367) - SIGN.MinHeaderUnits) < 1e-6
			and math.abs(headerUnits(257, 1022) - SIGN.MinHeaderUnits) < 1e-6
			and EnchantedMistStatus.signScale(257, 367, 70) > phone,
		"a phone's camera at a gate, or anybody's at the deepest plot's back: it grows just enough to hold "
			.. "its header's box at MinHeaderUnits", string.format("x%.2f at a phone's gate", phone))
	local w1, h1, l1 = EnchantedMistStatus.signFrame(1)
	local w2, h2, l2 = EnchantedMistStatus.signFrame(2.5)
	check(w1 == SIGN.Width and math.abs(h1 - tall) < 1e-9 and l1 == 0 and math.abs(w2 - SIGN.Width * 2.5) < 1e-9
			and math.abs(h2 - tall * 2.5) < 1e-9 and math.abs((l2 - h2 / 2) - (l1 - h1 / 2)) < 1e-9,
		"it grows upward: its bottom edge stays where it is built, over the surround")
	check(EnchantedMistStatus.signScale(100, 0, 70) == 1, "a viewport not yet measured leaves it as built")
	check(SIGN.MinHeaderUnits >= 19 and SIGN.MaxDistance >= GameConfig.Plot.MaxReach + 12,
		"its header's box never under 19 screen units (its words ~16 tall: capitals about a player's name over their "
			.. "head on a phone, 11.4 points), drawn past the deepest plot's back", SIGN.MinHeaderUnits)

	--==========================================================================
	-- 3. THE COORDINATOR, ON A FAKE CLOCK
	--==========================================================================
	say("-- the coordinator --")
	local moduleScript = Server:WaitForChild("EnchantedMistService")
	local dawnFns = {}
	local fakeCycle = {
		OnDawn = function(fn)
			table.insert(dawnFns, fn)
			return function() end
		end,
	}
	local configCopy = table.clone(EnchantedMistConfig)
	local function standInRequire(target)
		if target.Name == "WorldCycleService" then
			return fakeCycle
		elseif target.Name == "EnchantedMistConfig" then
			return configCopy
		end
		return require(target)
	end
	local chunk = loadstring(moduleScript.Source, "=EnchantedMistService")
	setfenv(chunk, setmetatable({ script = moduleScript, require = standInRequire }, { __index = getfenv(1) }))
	local M = chunk()
	local published = {}
	M.Hooks.publish = function(values)
		published = table.clone(values)
	end
	M.Hooks.random = function()
		return 1800
	end

	-- The switch off (as it was until 2026-10-12): disabled, no eligibility.
	configCopy.Enabled = false
	M._boot(0)
	check(M.State() == STATES.Disabled and published[ATTR.State] == STATES.Disabled
			and published[ATTR.EligibleAt] == nil,
		"with the switch off: published disabled, no eligibility")
	configCopy.Enabled = EnchantedMistConfig.Enabled
	local missing = M.MissingBindings()
	local text = table.concat(missing, " | ")
	-- Since 2026-10-11 every piece is built (the Look last), every pool creature
	-- registered (SeedData.MistSpecies) and both odds tables confirmed.
	check(#missing == 0, "nothing is missing: every piece built, every creature registered, both tables confirmed",
		text)
	-- ON (the owner, 2026-10-12, item 14): the real switch, every binding in place.
	M._boot(0)
	check(EnchantedMistConfig.Enabled == true and M.State() == STATES.Cooldown and M.EligibleAt() == 1800
			and published[ATTR.State] == STATES.Cooldown and published[ATTR.EligibleAt] == 1800,
		"switched on, every binding in place: a new server cools down, first eligible 20-60 minutes in (here 30), "
			.. "published for the sign", M.State())

	-- The guard still holds: with a piece unbuilt, switching on does nothing.
	configCopy.Enabled = true
	M.Built.Look = false
	local unbuilt = table.concat(M.MissingBindings(), " | ")
	M._boot(0)
	check(M.State() == STATES.Disabled and string.find(unbuilt, "Look", 1, true) ~= nil,
		"switched on but with a binding missing: still off", unbuilt)
	M.Built.Look = true
	M.MissingBindings = function()
		return {}
	end
	M._boot(0)
	check(M.State() == STATES.Cooldown and M.EligibleAt() == 1800 and published[ATTR.EligibleAt] == 1800,
		"on: cooling down, eligible a random 20-60 minutes in (here 30)")
	local starts, ends = {}, {}
	M.OnStart(function(info)
		table.insert(starts, info)
	end)
	M.OnEnd(function(info)
		table.insert(ends, info)
	end)
	local function dawn(index, source, open, short)
		return { cycleIndex = index, built = if short then 3 else 16, wanted = 16, short = short == true,
			barrierOpen = open ~= false, source = source or "cycle", at = 0 }
	end
	check(M._onDawn(dawn(2), 1000) == "NOT_ELIGIBLE" and M.State() == STATES.Cooldown,
		"a dawn before eligibility starts nothing")
	M._tick(1799)
	check(M.State() == STATES.Cooldown, "one second short: still cooling down")
	M._tick(1800)
	check(M.State() == STATES.Eligible and published[ATTR.State] == STATES.Eligible, "at its time: eligible")
	check(M._onDawn(dawn(4, "admin"), 1900) == "NOT_NATURAL" and M._onDawn(dawn(4, "cycle", false), 1900) == "ROAD_SHUT"
			and M.State() == STATES.Eligible,
		"an admin-forced dawn, or a dawn that left the road shut, starts nothing")
	check(M._onDawn(dawn(5, "cycle", true, true), 2000) == "STARTED" and M.State() == STATES.Active
			and published[ATTR.EndsAt] == 2300 and published[ATTR.StartedAt] == 2000 and M.EligibleAt() == 5600,
		"an eligible natural dawn (even a short batch) starts it: 300 s, next eligible 60 min from the START")
	check(M._onDawn(dawn(5), 2010) == "ALREADY_ACTIVE" and M._onDawn(dawn(6), 2010) == "ALREADY_ACTIVE",
		"a second callback while it runs starts nothing")
	M._tick(2299)
	check(M.IsActive(), "one second before its end: still active")
	M._tick(2300)
	check(not M.IsActive() and M.State() == STATES.Cooldown and published[ATTR.EndsAt] == nil,
		"at 300 s it ends, and cools down; no reset is asked for")
	check(M._onDawn(dawn(5), 2400) == "DUPLICATE" and M._onDawn(dawn(6), 3000) == "NOT_ELIGIBLE",
		"the same dawn again is a duplicate; the next dawns are inside the cooldown")
	M._tick(5600)
	check(M._onDawn(dawn(14), 5700) == "STARTED" and M.EventId() ~= nil, "after the cooldown the next natural dawn starts the next one")
	local second = M.EventId()
	M._onNight(5800)
	check(not M.IsActive() and M.State() == STATES.Cooldown, "a forced night ends it early")
	task.wait(0.1)
	check(#starts == 2 and #ends == 2 and starts[1].degraded == true and ends[2].reason == "night"
			and starts[1].eventId ~= second and ends[1].reason == "time",
		"its start and end are heard once each, with the degraded stock and the reason", #starts .. "/" .. #ends)

	-- AN ADMIN'S MIST (the console's START MIST NOW / END MIST NOW, 2026-10-11).
	say("-- an admin's Mist --")
	local night = false
	M.Hooks.isNight = function()
		return night
	end
	local startsFrom, endsFrom = #starts, #ends
	-- The schedule ON (as above, cooling down until 9300): it counts as a start.
	local onOk, onWhy = M.AdminStart(6000, "SpecAdmin")
	check(onOk and onWhy == "STARTED" and M.IsActive() and published[ATTR.StartedAt] == 6000
			and published[ATTR.EndsAt] == 6300 and M.EligibleAt() == 9600
			and string.find(M.EventId() or "", "-admin-", 1, true) ~= nil,
		"the schedule on: an admin's start is a normal 300 s Mist, and the next eligibility counts from it",
		tostring(M.EligibleAt()))
	local twiceOk, twiceWhy = M.AdminStart(6010, "SpecAdmin")
	check(not twiceOk and twiceWhy == "ALREADY_ACTIVE" and M.EndsAt() == 6300,
		"a second start while one runs: refused, nothing changed", twiceWhy)
	local endOk, endWhy = M.AdminEnd(6100, "SpecAdmin")
	check(endOk and endWhy == "ENDED" and not M.IsActive() and M.State() == STATES.Cooldown
			and published[ATTR.EndsAt] == nil and published[ATTR.EventId] == nil,
		"END: over at once, through the Mist's own end; the schedule cools down", endWhy)
	local endAgainOk, endAgainWhy = M.AdminEnd(6110, "SpecAdmin")
	check(not endAgainOk and endAgainWhy == "NOT_ACTIVE", "END with none running: refused", endAgainWhy)
	-- The schedule OFF (the owner's choice: Enabled false), every binding built.
	configCopy.Enabled = false
	M._boot(7000)
	check(M.State() == STATES.Disabled and published[ATTR.EligibleAt] == nil and M.EligibleAt() == 0,
		"the schedule off: disabled, no eligibility")
	night = true
	local nightOk, nightWhy = M.AdminStart(7010, "SpecAdmin")
	night = false
	check(not nightOk and nightWhy == "NIGHT" and M.State() == STATES.Disabled,
		"at Night: refused (the road is shut, and a forced Night would end it)", nightWhy)
	local realMissing = M.MissingBindings
	M.MissingBindings = function()
		return { "binding: a spec's missing piece" }
	end
	local unbuiltOk, unbuiltWhy = M.AdminStart(7020, "SpecAdmin")
	M.MissingBindings = realMissing
	check(not unbuiltOk and unbuiltWhy == "NOT_BUILT" and M.State() == STATES.Disabled,
		"a binding missing: refused", unbuiltWhy)
	local offOk = M.AdminStart(7100, "SpecAdmin")
	check(offOk and M.IsActive() and published[ATTR.State] == STATES.Active and published[ATTR.StartedAt] == 7100
			and published[ATTR.EndsAt] == 7400 and published[ATTR.EventId] == M.EventId()
			and published[ATTR.EligibleAt] == nil and M.EligibleAt() == 0,
		"the schedule OFF, an admin's start still runs: active for 300 s, the sign's countdown published, the "
			.. "schedule's eligibility untouched")
	check(M._onDawn(dawn(30), 7200) == "OFF" and M.IsActive(), "and the schedule stays off: a natural dawn starts nothing")
	M._tick(7399)
	check(M.IsActive(), "one second before its end: still active")
	M._tick(7400)
	check(not M.IsActive() and M.State() == STATES.Disabled and published[ATTR.State] == STATES.Disabled
			and published[ATTR.EligibleAt] == nil and published[ATTR.EndsAt] == nil and M.EligibleAt() == 0,
		"at 300 s it ends on its own, back to disabled -- the sign's COMING SOON -- the schedule untouched")
	M.AdminStart(7500, "SpecAdmin")
	M._onNight(7550)
	check(not M.IsActive() and M.State() == STATES.Disabled, "a forced Night ends it, back to disabled")
	M.AdminStart(7600, "SpecAdmin")
	M.AdminEnd(7650, "SpecAdmin")
	check(not M.IsActive() and M.State() == STATES.Disabled and M.EligibleAt() == 0,
		"END with the schedule off: over at once, back to disabled")
	task.wait(0.1)
	local reasons = {}
	for i = endsFrom + 1, #ends do
		table.insert(reasons, ends[i].reason)
	end
	local fromAdmin = true
	for i = startsFrom + 1, #starts do
		fromAdmin = fromAdmin and starts[i].source == "admin" and starts[i].endsAt == starts[i].startedAt + 300
	end
	check(#starts == startsFrom + 4 and fromAdmin and table.concat(reasons, ",") == "admin,time,night,admin",
		"the berries, Mosskeeper and the look hear each admin start and end once, source admin",
		table.concat(reasons, ","))
	local coordinator = moduleScript.Source
	check(string.find(coordinator, "started (source admin%s)%s; ends in %ds.", 1, true) ~= nil
			and string.find(coordinator, "ended (%s). The schedule stays off.", 1, true) ~= nil,
		"its log says source admin, and that the schedule stays off at the end")
	configCopy.Enabled = EnchantedMistConfig.Enabled

	--==========================================================================
	-- 4. WorldCycleService's DAWN HOOK
	--==========================================================================
	say("-- the dawn hook --")
	local wcsScript = Server:WaitForChild("WorldCycleService")
	local function thaw(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, x in pairs(value) do
			copy[k] = thaw(x)
		end
		return copy
	end
	local config = thaw(GameConfig)
	config.Tags.SeedPod = "EnchantedMistSpecLoosePod"
	local C = config.WorldCycle
	local brokenStock = false
	local standIns = {
		MapService = { SetNightBarrier = function() end, GetNightBarrier = function()
			return nil
		end },
		NestService = {
			ClearForNight = function()
				return 0
			end,
			ResetParents = function()
				return 0
			end,
			StockAll = function()
				if brokenStock then
					error("EnchantedMistSpec: a restock that throws")
				end
				return 4, 5
			end,
			PodCount = function()
				return 5, 5
			end,
			NestCount = function()
				return 1
			end,
		},
		CarryService = { IsCarrying = function()
			return false
		end, IsLiveEventPod = function()
			return false
		end },
		BiomeGateService = { OrderAt = function()
			return 0
		end, SweepNow = function()
			return 0
		end },
	}
	local configScript = Shared:WaitForChild("GameConfig")
	local wcsChunk = loadstring(wcsScript.Source, "=WorldCycleService")
	setfenv(wcsChunk, setmetatable({ script = wcsScript, require = function(target)
		if target == configScript then
			return config
		end
		local s = standIns[target.Name]
		assert(s ~= nil, "WorldCycleService asked for " .. target:GetFullName() .. ", which has no stand-in")
		return s
	end }, { __index = getfenv(1) }))
	local W = wcsChunk()
	local names = { GameConfig.Attributes.WorldPhase, GameConfig.Attributes.WorldPhaseEndsAt,
		GameConfig.Attributes.WorldCycleIndex }
	local before = {}
	for i, name in ipairs(names) do
		before[i] = Workspace:GetAttribute(name)
	end
	local told = {}
	local ran, hookErr = pcall(function()
		C.DaySeconds, C.NightSeconds = 30, 0.4
		W.Init()
		W.Start()
		W.OnDawn(function(info)
			table.insert(told, info)
		end)
		W.OnDawn(function()
			error("EnchantedMistSpec: a listener that throws")
		end)
		local unhook = W.OnDawn(function(info)
			table.insert(told, { cycleIndex = -1 })
		end)
		unhook()
		W.StartNight()
		task.wait(0.05)
		check(#told == 0, "a night tells no dawn listener")
		local done, why = W.StartDay()
		task.wait(0.05)
		check(done == true and why == "OK" and #told == 1 and told[1].source == "admin" and told[1].short == true
				and told[1].built == 4 and told[1].wanted == 5 and told[1].barrierOpen == true
				and told[1].cycleIndex == W.CycleIndex(),
			"a forced dawn tells each listener once, as \"admin\", with its short batch -- and a throwing listener "
				.. "did not fail it", tostring(why) .. " " .. #told)
		W.StartNight()
		task.wait(0.8)
		check(#told == 2 and told[2].source == "cycle" and W.IsDay(), "the loop's own dawn tells them as \"cycle\"",
			#told)
		brokenStock = true
		W.StartNight()
		local failed, fwhy = W.StartDay()
		task.wait(0.05)
		check(failed == false and fwhy == "FAILED" and #told == 2, "a failed dawn tells nobody", tostring(fwhy))
		brokenStock = false
	end)
	W.Init()
	for i, name in ipairs(names) do
		Workspace:SetAttribute(name, before[i])
	end
	if not ran then
		check(false, "the dawn-hook tests ran to the end", tostring(hookErr))
	end

	--==========================================================================
	-- 5. THE WIRING
	--==========================================================================
	say("-- the wiring --")
	check(EnchantedMistConfig.Enabled == true and EnchantedMistConfig.ShowSign == true,
		"the event's schedule ON (the owner, 2026-10-12, item 14); the shared sign ON (2026-10-11): its real states, "
			.. "COMING SOON only while the schedule is off")
	local signSrc = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("EnchantedMistSign").Source
	check(string.find(signSrc, "sign.gui.MaxDistance = SIGN.MaxDistance\n", 1, true)
			and string.find(signSrc, "local middle = Vector3.new(centre.X, (GameConfig.Map :: any).GroundY + HUB.FloorY + "
				.. "SIGN.Above, centre.Z)", 1, true)
			and string.find(signSrc, "RunService:BindToRenderStep(\"SeedMistSignClamp\", Enum.RenderPriority.Camera.Value + 1,",
				1, true)
			and string.find(signSrc, "EnchantedMistStatus.signScale((middle - camera.CFrame.Position).Magnitude, "
				.. "camera.ViewportSize.Y,", 1, true)
			and string.find(signSrc, "sign.gui.Size = UDim2.fromScale(width, tall)\n", 1, true)
			and string.find(signSrc, "sign.gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)\n", 1, true),
		"the sign: over the plaza's middle, drawn to MaxDistance, held at its smallest size after the camera moves")
	local wcs = wcsScript.Source
	check(string.find(wcs, "tellDawn(built, wanted, source or \"cycle\")", 1, true)
			and string.find(wcs, "transition(false, \"admin\")", 1, true)
			and string.find(wcs, "local okListener, err = pcall(fn, info)", 1, true),
		"WorldCycleService tells dawn listeners after the pcall, each in its own thread; Start Day is \"admin\"")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nEnchantedMistSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
