--!strict
-- Steal a Seed :: SpeedSpec
--
-- The Speed system's tests. Run it, read the tail.
--
--==============================================================================
-- HOW TO RUN IT
--
-- There is no test runner in this repo and no Node on this machine, so this is
-- a plain module that asserts and counts. Two ways in:
--
--   STUDIO COMMAND BAR (Edit is enough -- nothing here needs a running game):
--       require(game.ServerScriptService.SeedGameServer.Parent).SpeedSpec
--     ...does not work, because tools/ is deliberately NOT synced by Rojo.
--     Serve the repo and fetch it instead, which is the same trick CLAUDE.md
--     documents for compile-checking:
--
--       python -m http.server 8731        (from the repo root)
--
--       local s = game:GetService("HttpService"):GetAsync(
--           "http://127.0.0.1:8731/tools/tests/SpeedSpec.luau", true)
--       print(loadstring(s)())
--
--   NOT SHIPPED. tools/ is outside default.project.json's tree on purpose: a
--   test that reaches the place is a test that can break the place.
--
--==============================================================================
-- WHAT IT DOES NOT COVER, AND WHY
--
-- The afterimage's POOLS, its cleanup on respawn, and its refusal to emit while
-- ragdolled are all statements about a running client with a character in it.
-- They are checked in a Play session instead -- asserting on the real Folder,
-- the real part count, and the real Humanoid -- because a mock of all three
-- would be testing the mock.
--
-- What IS covered here is every pure function those visuals are built on: which
-- tier a score earns, where the boundaries are, and that nothing below 10B ever
-- earns one.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ProfileSchema = require(
	ServerScriptService:WaitForChild("SeedGameServer"):WaitForChild("ProfileSchema"))

local passed = 0
local failures: { string } = {}
local lines: { string } = {}

local function ok(name: string, condition: boolean, detail: string?)
	if condition then
		passed += 1
	else
		table.insert(failures, name .. (if detail then "  -- " .. detail else ""))
	end
end

local function near(a: number, b: number, tol: number?): boolean
	return math.abs(a - b) <= (tol or 1e-9)
end

local function section(title: string)
	table.insert(lines, "")
	table.insert(lines, "== " .. title .. " ==")
end

--==============================================================================
-- 1. EVERY ANCHOR IS EXACT
--
-- Not "close to". The anchors are the design statement -- 167M IS 42 -- and an
-- interpolator that lands at 41.98 on its own control point has a bug in it
-- even though nobody could feel the difference.
--==============================================================================
section("walk speed anchors")
for _, anchor in ipairs(GameConfig.Speed.Anchors) do
	local score, want = anchor[1], anchor[2]
	local got = GameConfig.walkSpeedFor(score)
	ok("anchor " .. GameConfig.compact(score), near(got, want),
		string.format("want %d got %.6f", want, got))
	table.insert(lines, string.format("  %-8s -> %6.2f  (want %3d)",
		GameConfig.compact(score), got, want))
end

--==============================================================================
-- 2. MONOTONIC, AND NOT ONLY AT THE ANCHORS
--
-- The property that must survive any retune: more score is never slower. Walked
-- geometrically so the sample density is even in LOG space, which is where the
-- curve actually lives -- a linear sweep would put 99.99% of its samples in the
-- last decade and test almost nothing.
--==============================================================================
section("monotonic")
do
	local prev = -math.huge
	local dips, samples = 0, 0
	local x = 0.0
	while x <= 1e15 do
		local w = GameConfig.walkSpeedFor(x)
		samples += 1
		if w < prev - 1e-9 then
			dips += 1
		end
		prev = w
		x = if x < 1 then 1 else x * 1.02
	end
	ok("monotonic across the ladder", dips == 0, dips .. " dip(s)")
	table.insert(lines, string.format("  %d samples, %d dips", samples, dips))

	-- And specifically BETWEEN anchors, where interpolation could misbehave in
	-- a way the endpoints would hide.
	local betweenDips = 0
	for i = 1, #GameConfig.Speed.Anchors - 1 do
		local lo = GameConfig.Speed.Anchors[i][1]
		local hi = GameConfig.Speed.Anchors[i + 1][1]
		local last = GameConfig.walkSpeedFor(lo)
		for step = 1, 200 do
			local at = lo + (hi - lo) * (step / 200)
			local w = GameConfig.walkSpeedFor(at)
			if w < last - 1e-9 then
				betweenDips += 1
			end
			last = w
		end
	end
	ok("monotonic inside every span", betweenDips == 0, betweenDips .. " dip(s)")
end

--==============================================================================
-- 3. FLOOR, CAP, AND EVERY BAD INPUT
--
-- A game where a corrupted number freezes the player in place is worse than one
-- where they walk at 16, so every one of these has a defined landing spot.
--==============================================================================
section("floor, cap, bad input")
do
	local S = GameConfig.Speed
	local cases: { { any } } = {
		{ "zero", 0, S.BaseWalkSpeed },
		{ "negative", -5, S.BaseWalkSpeed },
		{ "very negative", -1e18, S.BaseWalkSpeed },
		{ "NaN", 0 / 0, S.BaseWalkSpeed },
		{ "nil", nil, S.BaseWalkSpeed },
		{ "string", "fast", S.BaseWalkSpeed },
		{ "table", {}, S.BaseWalkSpeed },
		{ "infinity", math.huge, S.MaxWalkSpeed },
		{ "-infinity", -math.huge, S.BaseWalkSpeed },
		{ "save cap", 1e15, S.MaxWalkSpeed },
		{ "oversized", 1e30, S.MaxWalkSpeed },
	}
	for _, case in ipairs(cases) do
		local got = GameConfig.walkSpeedFor(case[2] :: any)
		ok("walkSpeedFor " .. case[1], near(got, case[3]),
			string.format("want %.2f got %.2f", case[3], got))
		table.insert(lines, string.format("  %-14s -> %6.2f", case[1], got))
	end

	-- Nothing anywhere on the ladder may leave the band.
	local outOfBand = 0
	local x = 0.0
	while x <= 1e16 do
		local w = GameConfig.walkSpeedFor(x)
		if w < S.BaseWalkSpeed - 1e-9 or w > S.MaxWalkSpeed + 1e-9 then
			outOfBand += 1
		end
		x = if x < 1 then 1 else x * 1.1
	end
	ok("never leaves [base, max]", outOfBand == 0, outOfBand .. " sample(s) outside")
end

--==============================================================================
-- 4. THE FORMATTER, THROUGH Qa
--==============================================================================
section("compact")
do
	local cases: { { any } } = {
		{ 0, "0" }, { 7, "7" }, { 110, "110" }, { 999, "999" },
		{ 1000, "1K" }, { 1250, "1.25K" }, { 1500, "1.5K" }, { 2000, "2K" },
		{ 3500, "3.5K" }, { 39000, "39K" }, { 100000, "100K" }, { 51200, "51.2K" },
		{ 553000000, "553M" }, { 3276800, "3.28M" }, { 52428800, "52.4M" },
		{ 12400000000, "12.4B" }, { 999000000000, "999B" },
		{ 1e12, "1T" }, { 1e15, "1Qa" },
		{ -1500, "-1.5K" },
		-- Rounding must not print a four-digit mantissa at a unit boundary.
		{ 999600000, "1B" }, { 999600000000, "1T" },
		-- Nothing in this game is legitimately infinite; the cap is the honest
		-- answer and "inf" is a bug report nobody can act on.
		{ math.huge, "1Qa" }, { 0 / 0, "0" },
	}
	for _, case in ipairs(cases) do
		local got = GameConfig.compact(case[1] :: any)
		ok("compact " .. tostring(case[1]), got == case[2],
			string.format("want %s got %s", case[2], got))
	end
	table.insert(lines, string.format("  %d formatting cases", #cases))

	-- Every gate and every overclock cost has to be printable, since both are
	-- on signs.
	for _, biome in ipairs(BiomeData.Biomes) do
		table.insert(lines, string.format("  gate %-12s %s",
			biome.DisplayName, GameConfig.compact(biome.RecommendedSpeed)))
	end
end

--==============================================================================
-- 5. PROFILE MIGRATION
--
-- The important case is the ABSENT field: every save written before this pass
-- has no MillOverclock and no HighestBiomeOrder, and must load as a player who
-- has bought neither and unlocked only Greenhollow -- which is exactly what
-- they are.
--==============================================================================
section("profile migration")
do
	local fresh = ProfileSchema.Default()
	ok("default overclock is 0", fresh.MillOverclock == 0)
	ok("default biome is 1", fresh.HighestBiomeOrder == 1)

	-- A v1 save from before either field existed.
	local old = ProfileSchema.Sanitise({
		Version = 1, Cash = 5000, Speed = 12345, PlotTier = 2, MillTier = 3,
	})
	ok("absent overclock migrates to 0", old.MillOverclock == 0,
		tostring(old.MillOverclock))
	ok("absent biome migrates to 1", old.HighestBiomeOrder == 1,
		tostring(old.HighestBiomeOrder))
	ok("migration leaves the rest alone",
		old.Cash == 5000 and old.Speed == 12345 and old.MillTier == 3)

	-- And every way a hostile or corrupted save can spell them.
	local junk: { { any } } = {
		{ "string", "9" }, { "NaN", 0 / 0 }, { "negative", -4 },
		{ "huge", 1e30 }, { "table", {} }, { "boolean", true },
		{ "infinity", math.huge }, { "fractional", 3.7 },
	}
	for _, case in ipairs(junk) do
		local p = ProfileSchema.Sanitise({ MillOverclock = case[2], HighestBiomeOrder = case[2] })
		local maxOC = GameConfig.Mill.Overclock.MaxLevel
		ok("overclock survives " .. case[1],
			p.MillOverclock >= 0 and p.MillOverclock <= maxOC
				and p.MillOverclock == math.floor(p.MillOverclock),
			tostring(p.MillOverclock))
		ok("biome survives " .. case[1],
			p.HighestBiomeOrder >= 1 and p.HighestBiomeOrder <= #BiomeData.Biomes
				and p.HighestBiomeOrder == math.floor(p.HighestBiomeOrder),
			tostring(p.HighestBiomeOrder))
	end
	table.insert(lines, "  fractional 3.7 -> overclock "
		.. tostring(ProfileSchema.Sanitise({ MillOverclock = 3.7 }).MillOverclock))
	table.insert(lines, "  the save cap is unchanged at "
		.. GameConfig.compact(GameConfig.Save.MaxSpeedScore))
	ok("save cap is still 1e15", GameConfig.Save.MaxSpeedScore == 1e15)
end

--==============================================================================
-- 6. THE TRAINING RATE
--==============================================================================
section("overclock rates")
do
	local O = GameConfig.Mill.Overclock
	local top = #GameConfig.Mill.Tiers

	--==========================================================================
	-- THE TOP TIER, AT SIX OVERCLOCK LEVELS
	--
	-- These were 51200 .. 52428800, which is the ladder as it stood when the top
	-- mill ran at 1600/s. It runs at 400M/s now and the mill has ten tiers rather
	-- than seven, so every one of the six was out by a factor of 250,000 -- and
	-- because the spec threw further up, not one of them had been reported since.
	--
	-- Two literals rather than six: the BASE and the DOUBLING are the contract,
	-- and the six expectations follow from them arithmetically. Typed as a table
	-- of literals below all the same, because a test that computes what it is
	-- checking with the formula it is checking cannot fail -- and this pair of
	-- lines is exactly where a retune should have to stop and think.
	--==========================================================================
	ok("the top mill runs at 400M/s", GameConfig.Mill.Tiers[top].speed == 400e6,
		tostring(GameConfig.Mill.Tiers[top].speed))
	ok("each overclock level doubles it", O.Multiplier == 2, tostring(O.Multiplier))
	ok("the ladder is ten tiers deep", top == 10, tostring(top))
	local want: { [number]: number } = {
		[5] = 12.8e9, [6] = 25.6e9, [7] = 51.2e9,
		[8] = 102.4e9, [9] = 204.8e9, [10] = 409.6e9,
	}
	for level = 0, O.MaxLevel do
		local rate = GameConfig.trainingRateFor(top, level, nil)
		if want[level] then
			ok("the top tier at overclock " .. level, near(rate, want[level]),
				string.format("want %.0f got %.0f", want[level], rate))
		end
		local cost = GameConfig.overclockCostFor(level)
		-- No biome column: overclock has no biome gate. GameConfig.Mill.Overclock
		-- says it outright -- "Level N costs Costs[N], and that is the entire
		-- requirement" -- and the call that used to print one here was to
		-- overclockUnlockOrderFor, a function that does not exist. It threw, and
		-- the throw took the whole spec with it.
		table.insert(lines, string.format("  L%-2d %10s/s   %s",
			level, GameConfig.compact(rate),
			if cost then "$" .. GameConfig.compact(cost) else "-"))
	end

	ok("rate is strictly increasing in level", (function()
		local prev = -1
		for level = 0, O.MaxLevel do
			local r = GameConfig.trainingRateFor(top, level, nil)
			if r <= prev then
				return false
			end
			prev = r
		end
		return true
	end)())
	ok("cost is strictly increasing", (function()
		local prev = -1
		for level = 1, O.MaxLevel do
			local c = O.Costs[level]
			if not c or c <= prev then
				return false
			end
			prev = c
		end
		return true
	end)())
	ok("there is a cost for every level", #O.Costs == O.MaxLevel)
	--==========================================================================
	-- THREE MORE CHECKS ON A GATE THAT IS NOT THERE
	--
	-- These read O.UnlockedBy -- an unlock order per overclock level -- and
	-- asserted it had one entry per level, named a biome that exists, and never
	-- went backwards. GameConfig.Mill.Overclock has no such table: it is
	-- Multiplier, MaxLevel, Costs and Label, and its own comment says "Level N
	-- costs Costs[N], and that is the entire requirement".
	--
	-- Indexing a nil threw rather than failed, which is why this spec has been
	-- reporting an ERROR rather than a failure and why nothing after this line
	-- has run for however long the table has been gone. Cost IS the ladder now,
	-- and the two checks either side of this -- every level has a cost, costs
	-- strictly increase -- are what guard it.
	--==========================================================================
	ok("level 11 is not for sale", GameConfig.overclockCostFor(11) == nil)
	ok("rebirth seam returns 1", GameConfig.rebirthMultiplierFor(nil) == 1
		and GameConfig.rebirthMultiplierFor({}) == 1)

	-- Bad input on the payout path must produce a number, not a nil.
	for _, bad in ipairs({ 0 / 0, -3, 1e9, math.huge }) do
		local r = GameConfig.trainingRateFor(top, bad, nil)
		ok("rate stays finite for " .. tostring(bad),
			type(r) == "number" and r == r and r < math.huge, tostring(r))
	end
end

--==============================================================================
-- 7. THE GATE MATH
--
-- BiomeGateService is a server module and is exercised live in the playtest.
-- What is checked here is the arithmetic it is built on: which segment a Z
-- coordinate is in, and which biome a score has earned. Those are the two
-- statements the whole gate rests on.
--==============================================================================
section("gate math")
do
	local MAP = GameConfig.Map
	local function orderAt(z: number): number
		local depth = -z - MAP.FieldFront
		if depth < 0 then
			return 0
		end
		return math.min(math.floor(depth / MAP.SegmentLength) + 1, #BiomeData.Biomes)
	end

	ok("the field is order 0", orderAt(0) == 0 and orderAt(-169) == 0)
	ok("the mouth is biome 1", orderAt(-MAP.FieldFront) == 1)
	for _, biome in ipairs(BiomeData.Biomes) do
		local nearZ, farZ = BiomeData.SegmentBounds(biome)
		ok("segment " .. biome.Id .. " starts in itself", orderAt(nearZ) == biome.Order,
			string.format("z %.0f -> %d", nearZ, orderAt(nearZ)))
		ok("segment " .. biome.Id .. " ends in itself", orderAt(farZ + 1) == biome.Order,
			string.format("z %.0f -> %d", farZ + 1, orderAt(farZ + 1)))
		table.insert(lines, string.format("  %-12s order %d   z %6.0f .. %6.0f   needs %s",
			biome.DisplayName, biome.Order, nearZ, farZ,
			GameConfig.compact(biome.RecommendedSpeed)))
	end

	--==========================================================================
	-- THIS MIRRORS BiomeGateService.EarnedBy
	--
	-- Deliberately a copy: the harness runs in Edit with no services started,
	-- and requiring BiomeGateService would drag PlayerDataService and SaveService
	-- into a session that is supposed to touch neither.
	--
	-- The cost of a copy is drift, and it has already been paid once. Every read
	-- here was `biome.SpeedGate`, a field renamed to RecommendedSpeed when the
	-- hard gate became a recommendation -- comparing nil THREW rather than
	-- failed, so this spec reported an error and every check below it stopped
	-- running. If EarnedBy changes shape again, this is what changes with it.
	--==========================================================================
	local function earnedBy(score: number): number
		local earned = 1
		for _, biome in ipairs(BiomeData.Biomes) do
			if score >= biome.RecommendedSpeed then
				earned = math.max(earned, biome.Order)
			end
		end
		return earned
	end
	--==========================================================================
	-- THE UNLOCK SURVIVES THE SCORE GOING AWAY
	--
	-- This is the whole reason HighestBiomeOrder exists as its own field, and it
	-- is a property of the SAVE, so the save is where it is tested: write a
	-- profile that has reached Starbloom, zero its Speed the way a rebirth
	-- would, put it through the sanitiser as a reload does -- and it must come
	-- back still holding Starbloom.
	--
	-- A gate reading the live score instead would hand back every biome the
	-- player had earned, at the exact moment the game asked them to start again.
	--==========================================================================
	do
		local veteran = ProfileSchema.Sanitise({
			Speed = 10e9, HighestBiomeOrder = 5, MillOverclock = 8,
		})
		ok("a veteran profile keeps its biome", veteran.HighestBiomeOrder == 5)

		local rebirthed = ProfileSchema.Sanitise({
			Speed = 0, HighestBiomeOrder = veteran.HighestBiomeOrder,
			MillOverclock = veteran.MillOverclock,
		})
		ok("zeroing Speed does not take the biome back",
			rebirthed.HighestBiomeOrder == 5, tostring(rebirthed.HighestBiomeOrder))
		ok("zeroing Speed does not take the overclock back",
			rebirthed.MillOverclock == 8, tostring(rebirthed.MillOverclock))
		ok("but the score really is zero", rebirthed.Speed == 0)

		--==================================================================
		-- THERE IS NO BIOME-GATED OVERCLOCK TO CHECK
		--
		-- This asserted that "an overclock unlocked by a biome stays unlocked"
		-- through a rebirth, via GameConfig.overclockUnlockOrderFor. No such
		-- function exists and no such gate does either: Overclock's own config
		-- says "Level N costs Costs[N], and that is the entire requirement".
		--
		-- The assertion was testing a design that was either dropped or never
		-- built, and because it CALLED a nil it did not fail -- it threw, and
		-- every check after it in this spec stopped running. Removed rather
		-- than repaired: there is nothing left for it to be about, and the
		-- three checks above already cover what a rebirth must not take away.
		--==================================================================

		-- A client claiming a biome it has not earned changes nothing here: the
		-- field is only ever written by the server from its own profile, and the
		-- sanitiser clamps whatever is on disk to the real range.
		local liar = ProfileSchema.Sanitise({ HighestBiomeOrder = 9999 })
		ok("a forged unlock is clamped to what exists",
			liar.HighestBiomeOrder == #BiomeData.Biomes, tostring(liar.HighestBiomeOrder))
	end

	ok("zero earns Greenhollow only", earnedBy(0) == 1)
	ok("one below a gate does not open it", earnedBy(167e6 - 1) == 1)
	ok("exactly the gate opens it", earnedBy(167e6) == 2)
	ok("the last gate", earnedBy(10e9) == 5)
	ok("past the last gate stays there", earnedBy(1e15) == 5)
	ok("every gate is reachable and ordered", (function()
		local prev = -1
		for _, biome in ipairs(BiomeData.Biomes) do
			if biome.RecommendedSpeed <= prev or biome.RecommendedSpeed > GameConfig.Save.MaxSpeedScore then
				return false
			end
			prev = biome.RecommendedSpeed
		end
		return true
	end)())
end

--==============================================================================
-- 8. CARRY STILL MULTIPLIES THE CURVE
--
-- The single most important regression to catch. CarryService computes
-- walkSpeedFor(score) * carryMultiplierFor(tier), and a curve change that
-- accidentally moved the multiply -- or made the curve return something the
-- multiply cannot scale -- would silently delete the weight system, which is the
-- entire risk/reward of the game.
--==============================================================================
section("carry multiplier after the new curve")
do
	-- Carry.MaxKg until size tiers replaced kilograms. carryMultiplierFor takes
	-- a TIER VALUE now; the maths is unchanged and only the name moved, but the
	-- old name read as nil here and `for tier = 0, nil` threw -- which is why
	-- every check below this point had stopped running.
	local topTier = GameConfig.Carry.TopTierValue
	local floorMult = GameConfig.Carry.MinMultiplier
	ok("empty hands do not scale", near(GameConfig.carryMultiplierFor(0), 1))
	ok("max weight is the floor", near(GameConfig.carryMultiplierFor(topTier), floorMult))
	ok("carry is monotonically punishing", (function()
		local prev = math.huge
		for tier = 0, topTier, 97 do
			local m = GameConfig.carryMultiplierFor(tier)
			if m > prev + 1e-9 then
				return false
			end
			prev = m
		end
		return true
	end)())

	for _, score in ipairs({ 0, 1e4, 167e6, 800e6, 3e9, 10e9, 100e9, 1e12, 1e15 }) do
		local base = GameConfig.walkSpeedFor(score)
		local light = base * GameConfig.carryMultiplierFor(1)
		local heavy = base * GameConfig.carryMultiplierFor(topTier)
		ok("carry scales at " .. GameConfig.compact(score),
			light <= base + 1e-9 and heavy < light and heavy >= base * floorMult - 1e-9)
		--==================================================================
		-- A HEAVY CARRY IS ALWAYS SLOWER, AT EVERY SCORE
		--
		-- Where the ribbon stops is section 10's business, because it is decided
		-- by the carry band and not by this curve. What belongs HERE is the property the whole
		-- risk/reward rests on: carrying always costs speed, the cost never
		-- inverts, and the floor is never breached.
		--==================================================================
		ok("a max carry is never faster than a light one at "
			.. GameConfig.compact(score), heavy < light)
		table.insert(lines, string.format("  %-8s base %6.2f   t1 %6.2f   t%d %6.2f",
			GameConfig.compact(score), base, light, topTier, heavy))
	end
	--==========================================================================
	-- THERE IS ONE CARRY CURVE, AND SeedData USES IT
	--
	-- This compared SeedData.CarryMultiplier(500) against carryMultiplierFor(500)
	-- and they are not the same question: SeedData takes a tier INDEX and passes
	-- that tier's .value on, so 500 meant "tier 500, clamped to Colossal" on one
	-- side and "a pod of value 500" on the other. It failed for a reason that had
	-- nothing to do with the thing it was guarding.
	--
	-- Asked over the whole ladder now instead of at one sample, because the risk
	-- being guarded against is a SECOND curve appearing -- and a second curve that
	-- agreed at one point would pass the old check.
	--==========================================================================
	ok("SeedData delegates to the one multiplier, at every tier", (function()
		for index, tier in ipairs(SeedData.Tiers) do
			if not near(SeedData.CarryMultiplier(index),
				GameConfig.carryMultiplierFor(tier.value)) then
				return false
			end
		end
		return true
	end)())
	ok("the top tier's value IS the carry cap",
		SeedData.Tiers[#SeedData.Tiers].value == GameConfig.Carry.TopTierValue,
		string.format("%d vs %d", SeedData.Tiers[#SeedData.Tiers].value,
			GameConfig.Carry.TopTierValue))
end

--==============================================================================
-- 9. THE TEN RIBBON TIERS
--
-- Every threshold, both sides of it. A tier that starts one Speed late is a
-- player who hits a round number and sees nothing happen, which is the exact
-- moment the whole system is supposed to pay out.
--
-- THIS SECTION USED TO TEST A DIFFERENT EFFECT. It asserted seven tiers named
-- "First Echo" through "Rainbow Ascension", each rendering up to four cloned
-- character limbs at a spacing in studs. That system is gone: GameConfig now
-- drives ONE Trail per character, and the ladder is ten tiers deep with new
-- names, new thresholds and new columns.
--
-- Ten of the fifteen Afterimage fields this section asked for no longer exist,
-- so it was not repairable field by field -- the whole thing described a design
-- that had been replaced. It is rewritten here against the ribbon, and the old
-- expectations are NOT preserved as comments: the config's own history section
-- already explains why the echoes went, and a spec carrying a second account of
-- it is a second thing to keep true.
--==============================================================================
section("ribbon tiers")
do
	local FX = GameConfig.Afterimage

	--==========================================================================
	-- THE LADDER, TYPED OUT
	--
	-- Written as literals rather than read off the table, because a test that
	-- derives its expectations from the thing it is testing cannot fail. These
	-- ten rows are the contract; if a retune moves a threshold, this is the line
	-- that must be changed deliberately.
	--==========================================================================
	local expected: { { any } } = {
		{ 1, 1e3, "Breeze Whisper" },
		{ 2, 10e3, "Aqua Surge" },
		{ 3, 1e6, "Thunder Strike" },
		{ 4, 100e6, "Violet Phantom" },
		{ 5, 1e9, "Solar Flare" },
		{ 6, 10e9, "Glacial Frostbite" },
		{ 7, 100e9, "Heartwood Bloom" },
		{ 8, 1e12, "Hellfire Inferno" },
		{ 9, 10e12, "Seraphic Divinity" },
		{ 10, 100e12, "Void Singularity" },
	}
	ok("ten tiers", #FX.Tiers == 10, tostring(#FX.Tiers))
	ok("the table is exactly as long as the contract", #FX.Tiers == #expected)

	for _, row in ipairs(expected) do
		local index, from, name = row[1], row[2], row[3]
		local tier = FX.Tiers[index]
		ok("tier " .. index .. " exists", tier ~= nil)
		if tier then
			ok("tier " .. index .. " starts at " .. GameConfig.compact(from),
				tier.From == from, tostring(tier.From))
			ok("tier " .. index .. " is named " .. name, tier.Name == name,
				tostring(tier.Name))
			ok("at " .. GameConfig.compact(from) .. " the tier is " .. index,
				GameConfig.speedVisualTierFor(from) == index,
				tostring(GameConfig.speedVisualTierFor(from)))
			ok("one below " .. GameConfig.compact(from) .. " it is not",
				GameConfig.speedVisualTierFor(from - 1) == index - 1,
				tostring(GameConfig.speedVisualTierFor(from - 1)))
			table.insert(lines, string.format(
				"  %2d %-18s from %-6s life %.2fs  wide %.2f  head %.2f  light %.2f",
				index, tier.Name, GameConfig.compact(tier.From), tier.Lifetime,
				tier.WidthStuds, tier.HeadTransparency, tier.LightEmission))
		end
	end

	--==========================================================================
	-- BELOW THE FIRST THRESHOLD, NOTHING
	--==========================================================================
	ok("nothing below 1K earns a ribbon", (function()
		local x = 0.0
		while x < 1e3 do
			if GameConfig.speedVisualTierFor(x) ~= 0 then
				return false
			end
			x = if x == 0 then 1 else x * 1.7
		end
		return true
	end)())
	ok("bad input is tier 0", GameConfig.speedVisualTierFor(0 / 0) == 0
		and GameConfig.speedVisualTierFor(-5) == 0)

	--==========================================================================
	-- THE SHAPE CLIMBS AT EVERY STEP
	--
	-- The guarantee the config makes in prose and the reason the ghosts were
	-- replaced: Lifetime, WidthStuds and HeadTransparency are strictly monotonic
	-- from 1 to 10, so no tier is ever shorter, narrower or fainter than the one
	-- below it. The old ladder could not promise this -- its ghost count capped
	-- at four, and every tier above the fourth had nothing structural left.
	--
	-- HeadTransparency runs the OTHER WAY on purpose. Lower is more solid, so
	-- "never fainter" means strictly DECREASING, and asserting it increases is
	-- the mistake this comment exists to stop.
	--==========================================================================
	local function strictly(field: string, wantRising: boolean): (boolean, string)
		local prev: number? = nil
		for index, tier in ipairs(FX.Tiers) do
			local v = tier[field]
			if type(v) ~= "number" then
				return false, "tier " .. index .. " has no numeric " .. field
			end
			if prev then
				if v == prev or (v > prev) ~= wantRising then
					return false, string.format("tier %d: %.3f after %.3f",
						index, v, prev)
				end
			end
			prev = v
		end
		return true, string.format("%.2f -> %.2f", FX.Tiers[1][field],
			FX.Tiers[#FX.Tiers][field])
	end

	for _, case in ipairs({
		{ "Lifetime", true, "the ribbon never gets shorter" },
		{ "WidthStuds", true, "the ribbon never gets narrower" },
		{ "HeadTransparency", false, "the ribbon never gets fainter" },
	}) do
		local pass, detail = strictly(case[1] :: string, case[2] :: boolean)
		ok(case[3] .. " (" .. case[1] .. ")", pass, detail)
	end

	--==========================================================================
	-- LIGHT CLIMBS TO NINE, THEN THE VOID TAKES IT
	--
	-- Tier 10 breaks the ramp deliberately: every tier reaches for more light and
	-- Void Singularity is the one that removes it, which only reads as an ending
	-- because the nine below it went the other way. So the ramp is asserted over
	-- 1..9, and the break is asserted as a REQUIREMENT rather than tolerated --
	-- a tenth tier quietly "corrected" back onto the ramp would delete the one
	-- moment the ladder was built to arrive at.
	--==========================================================================
	ok("light climbs from tier 1 to tier 9", (function()
		for index = 2, 9 do
			if FX.Tiers[index].LightEmission <= FX.Tiers[index - 1].LightEmission then
				return false
			end
		end
		return true
	end)())
	ok("and the void gives it up",
		FX.Tiers[10].LightEmission < FX.Tiers[9].LightEmission,
		string.format("%.2f after %.2f", FX.Tiers[10].LightEmission,
			FX.Tiers[9].LightEmission))
	ok("the void is the only tier that does", (function()
		local drops = 0
		for index = 2, #FX.Tiers do
			if FX.Tiers[index].LightEmission < FX.Tiers[index - 1].LightEmission then
				drops += 1
			end
		end
		return drops == 1
	end)())

	--==========================================================================
	-- THE ANIMATION DIALS ARE SET BY THEME, NOT BY RANK
	--
	-- Wave and Shimmer deliberately do NOT ramp -- Thunder Strike flickers harder
	-- than the Violet Phantom above it because that is what those two things are.
	-- The config says in as many words: do not "correct" them into a ramp.
	--
	-- So the inversion is asserted rather than merely allowed. A spec that only
	-- permitted non-monotonic values would pass just as happily after somebody
	-- tidied them into a ramp, which is the exact edit the config warns against
	-- and the exact edit nothing else in the codebase would catch.
	--==========================================================================
	for _, field in ipairs({ "Wave", "Shimmer" }) do
		local inversions = 0
		for index = 2, #FX.Tiers do
			if FX.Tiers[index][field] < FX.Tiers[index - 1][field] then
				inversions += 1
			end
		end
		ok(field .. " is set by theme, not by rank", inversions > 0,
			tostring(inversions) .. " inversion(s)")
	end
	ok("every tier has both dials, and neither is negative", (function()
		for _, tier in ipairs(FX.Tiers) do
			if type(tier.Wave) ~= "number" or type(tier.Shimmer) ~= "number"
				or tier.Wave < 0 or tier.Shimmer < 0 then
				return false
			end
		end
		return true
	end)())

	--==========================================================================
	-- EVERY TIER IS FULLY DRESSED
	--
	-- A tier missing its Palette or its emitter is a tier that renders as a grey
	-- streak, and it would reach a player before it reached anybody reading the
	-- table -- the fields are only read at the moment the effect is built.
	--==========================================================================
	for index, tier in ipairs(FX.Tiers) do
		ok("tier " .. index .. " has at least two palette colours",
			type(tier.Palette) == "table" and #tier.Palette >= 2,
			tostring(if type(tier.Palette) == "table" then #tier.Palette else "none"))
		ok("tier " .. index .. " palette holds Color3s", (function()
			if type(tier.Palette) ~= "table" then
				return false
			end
			for _, c in ipairs(tier.Palette) do
				if typeof(c) ~= "Color3" then
					return false
				end
			end
			return true
		end)())
		local p = tier.Particle
		ok("tier " .. index .. " has an emitter", type(p) == "table")
		if type(p) == "table" then
			ok("tier " .. index .. " emitter is complete",
				type(p.Texture) == "string" and typeof(p.Color) == "Color3"
					and type(p.Rate) == "number" and type(p.Speed) == "number"
					and type(p.Size) == "number")
			ok("tier " .. index .. " emitter rate is positive", p.Rate > 0,
				tostring(p.Rate))
		end
	end

	--==========================================================================
	-- THE PALETTE GROWS WITH THE LADDER
	--
	-- Not strictly -- four tiers share two colours at the bottom -- but it must
	-- never SHRINK, or a higher tier would cycle through less than the one below
	-- it, which is the same regression as a narrower ribbon in a different column.
	--==========================================================================
	ok("the palette never shrinks going up", (function()
		for index = 2, #FX.Tiers do
			if #FX.Tiers[index].Palette < #FX.Tiers[index - 1].Palette then
				return false
			end
		end
		return true
	end)())
	table.insert(lines, "  palette sizes: " .. (function()
		local out = {}
		for _, tier in ipairs(FX.Tiers) do
			table.insert(out, tostring(#tier.Palette))
		end
		return table.concat(out, " ")
	end)())

	--==========================================================================
	-- THE COLUMN THAT WAS DELETED MUST STAY DELETED
	--
	-- The old top tier ended the ladder by abandoning its palette for the whole
	-- hue wheel, on a boolean column. Nothing sets it now, and the config is
	-- explicit that a branch no row can reach is a branch nobody tests. This
	-- asserts the column did not creep back in with a single row using it.
	--==========================================================================
	ok("no tier carries a Rainbow flag", (function()
		for _, tier in ipairs(FX.Tiers) do
			if tier.Rainbow ~= nil then
				return false
			end
		end
		return true
	end)())
	ok("only the void names its own core colour", (function()
		for index, tier in ipairs(FX.Tiers) do
			if (tier.CoreColor ~= nil) ~= (index == #FX.Tiers) then
				return false
			end
		end
		return true
	end)())

	--==========================================================================
	-- THE MOVEMENT GATES
	--
	-- Standing still at a high WalkSpeed must not smear a ribbon across a plot,
	-- and a respawn must not draw one across the map.
	--==========================================================================
	ok("there is a minimum ground speed", FX.MinGroundSpeed > 0,
		tostring(FX.MinGroundSpeed))
	ok("a teleport is further than a stride", FX.TeleportStuds > FX.MinGroundSpeed,
		tostring(FX.TeleportStuds))
	ok("a remote ribbon is dropped at a distance", FX.RemoteMaxStuds > 0,
		tostring(FX.RemoteMaxStuds))
	ok("the repaint interval is a real frame budget",
		FX.ColourInterval > 0 and FX.ColourInterval < 1,
		string.format("%.4f", FX.ColourInterval))
	ok("the quality attribute is named",
		type(FX.QualityAttribute) == "string" and #FX.QualityAttribute > 0)
	table.insert(lines, string.format(
		"  gates: moves past %d studs/s, teleport past %d, remote cut at %d, repaint %.0f Hz",
		FX.MinGroundSpeed, FX.TeleportStuds, FX.RemoteMaxStuds, 1 / FX.ColourInterval))

	--==========================================================================
	-- A PHONE GETS THE SAME EFFECT, SMALLER
	--
	-- The whole point of moving off ghosts is that every machine can have every
	-- tier. So the reduced settings must SCALE the ribbon, never switch it off:
	-- a scale of 0 would be the old "phones get fewer echoes" compromise back
	-- again under a new name.
	--==========================================================================
	for _, field in ipairs({ "ReducedLifetimeScale", "ReducedWidthScale" }) do
		ok(field .. " shrinks without deleting",
			FX[field] > 0 and FX[field] < 1, string.format("%.2f", FX[field]))
	end
	table.insert(lines, string.format(
		"  reduced: %.0f%% of the length, %.0f%% of the width -- still every tier",
		FX.ReducedLifetimeScale * 100, FX.ReducedWidthScale * 100))

	--==========================================================================
	-- WHERE A MAXIMUM CARRY LEAVES A PLAYER ON THE SPEED GATE
	--
	-- Recorded rather than asserted at a typed number, so the report stays true
	-- after any retune. Whether the ribbon actually draws is section 10's
	-- business, because that is decided by the carry band and not by this gate.
	--==========================================================================
	do
		local topTier = GameConfig.Carry.TopTierValue
		local floorAt = GameConfig.carryMultiplierFor(topTier)
		local lo, hi = 0.0, GameConfig.Save.MaxSpeedScore
		for _ = 1, 200 do
			local mid = (lo + hi) * 0.5
			if GameConfig.walkSpeedFor(mid) * floorAt < FX.MinGroundSpeed then
				lo = mid
			else
				hi = mid
			end
		end
		table.insert(lines, string.format(
			"  a tier %d pod holds a player under the %d studs/s gate below %s Speed",
			topTier, FX.MinGroundSpeed, GameConfig.compact(lo)))
	end
end


--==============================================================================
-- 10. WEIGHT SUPPRESSES THE RIBBON
--
-- The speed gate cannot do this on its own. It used to: at 35 studs/s a heavy
-- pod held a player under it. The gate is 2 now, because a ribbon should appear
-- the moment you are actually moving -- and at 2 a loaded player clears it while
-- barely walking. Without a separate test, the one moment this game is built
-- around (running home rich and slow) would carry the most spectacular effect in
-- the game.
--==============================================================================
section("carry bands")
do
	local FX = GameConfig.Afterimage

	--==========================================================================
	-- THE SAME DECISION THE CLIENT MAKES
	--
	-- Reproduced here rather than imported, because the client is a LocalScript
	-- and cannot be required from a spec. Kept to three lines so that the copy
	-- cannot drift into something the original does not do.
	--==========================================================================
	local FULL, REDUCED, NONE = "full", "reduced", "none"
	local function bandFor(multiplier: any): string
		if type(multiplier) ~= "number" or multiplier ~= multiplier
			or multiplier > FX.CarryFullAbove then
			return FULL
		end
		if multiplier < FX.CarryReducedAbove then
			return NONE
		end
		return REDUCED
	end

	ok("the bands are ordered", FX.CarryReducedAbove < FX.CarryFullAbove)
	ok("the full band starts above 0.92", FX.CarryFullAbove == 0.92,
		tostring(FX.CarryFullAbove))
	ok("the dead band starts below 0.55", FX.CarryReducedAbove == 0.55,
		tostring(FX.CarryReducedAbove))

	--==========================================================================
	-- A LOAD SCALES THE RIBBON, IT DOES NOT RE-DRESS IT
	--
	-- The old middle band had its own ghost count, its own spacing and its own
	-- fade -- three numbers describing a different effect. A ribbon needs only to
	-- be shortened, narrowed and faded, so the loaded look is the SAME ribbon
	-- under three multipliers. Each must do something, and none may erase it.
	--==========================================================================
	ok("a load shortens it", FX.CarryLifetimeScale > 0 and FX.CarryLifetimeScale < 1,
		string.format("%.2f", FX.CarryLifetimeScale))
	ok("a load narrows it", FX.CarryWidthScale > 0 and FX.CarryWidthScale < 1,
		string.format("%.2f", FX.CarryWidthScale))
	ok("a load fades it", FX.CarryFadeAdd > 0, string.format("%.2f", FX.CarryFadeAdd))

	--== the three bands, on both sides of both edges ==--
	for _, case in ipairs({
		{ 1.00, FULL }, { 0.96, FULL }, { 0.9201, FULL },
		{ 0.92, REDUCED }, { 0.70, REDUCED }, { 0.55, REDUCED },
		{ 0.5499, NONE }, { 0.30, NONE }, { 0.0, NONE },
	}) do
		ok("multiplier " .. tostring(case[1]) .. " is " .. tostring(case[2]),
			bandFor(case[1]) == case[2], bandFor(case[1]))
	end

	--== a missing or broken attribute must never delete the effect ==--
	ok("a missing multiplier reads as unloaded", bandFor(nil) == FULL)
	ok("NaN reads as unloaded", bandFor(0 / 0) == FULL)
	ok("a string reads as unloaded", bandFor("heavy") == FULL)

	--==========================================================================
	-- WHAT EACH BAND MEANS IN POD SIZE
	--
	-- The bands are about the multiplier, but a player experiences pod size, so
	-- this is where the two are tied together and printed.
	--==========================================================================
	local topTier = GameConfig.Carry.TopTierValue
	local edgeFull, edgeDead = -1, -1
	for tier = 0, topTier do
		local band = bandFor(GameConfig.carryMultiplierFor(tier))
		if band ~= FULL and edgeFull < 0 then
			edgeFull = tier
		end
		if band == NONE and edgeDead < 0 then
			edgeDead = tier
		end
	end
	table.insert(lines, string.format(
		"  full effect up to tier %d | reduced %d..%d | nothing from tier %d up",
		edgeFull - 1, edgeFull, edgeDead - 1, edgeDead))
	ok("an empty-handed player is unaffected",
		bandFor(GameConfig.carryMultiplierFor(0)) == FULL)
	ok("a tier 1 pod is unaffected", bandFor(GameConfig.carryMultiplierFor(1)) == FULL)
	ok("a maximum pod kills the effect",
		bandFor(GameConfig.carryMultiplierFor(topTier)) == NONE)

	--==========================================================================
	-- A MAXIMUM POD IS SILENT AT EVERY TIER, THE VOID INCLUDED
	--
	-- The requirement the speed gate can no longer meet on its own, and the
	-- reason this whole section exists. Asserted at every tier rather than at the
	-- top one, because a band that failed only in the middle would be invisible.
	--==========================================================================
	local heavyMultiplier = GameConfig.carryMultiplierFor(topTier)
	for index, tier in ipairs(FX.Tiers) do
		ok("a max pod suppresses tier " .. index .. " (" .. tier.Name .. ")",
			bandFor(heavyMultiplier) == NONE)
	end
	table.insert(lines, string.format(
		"  a tier %d pod is multiplier %.2f -> %s, at all %d tiers",
		topTier, heavyMultiplier, bandFor(heavyMultiplier), #FX.Tiers))

	--== and it is suppressed by WEIGHT, not by being slow ==--
	local heavyWalkAtCap = GameConfig.walkSpeedFor(GameConfig.Save.MaxSpeedScore)
		* heavyMultiplier
	ok("at 1Qa a max pod is still well over the speed gate",
		heavyWalkAtCap > FX.MinGroundSpeed,
		string.format("%.1f vs %d", heavyWalkAtCap, FX.MinGroundSpeed))
	table.insert(lines, string.format(
		"  at 1Qa a max pod still walks %.1f studs/s -- over the %d gate, so the",
		heavyWalkAtCap, FX.MinGroundSpeed))
	table.insert(lines, "  band is what stops it, exactly as intended")

	--==========================================================================
	-- PUTTING IT DOWN GIVES IT BACK
	--
	-- Dropping and banking both end with nothing carried, which is multiplier 1
	-- -- so restoration is not a separate code path, it is the same publish with
	-- an empty hand. Tested as the round trip a player actually performs.
	--==========================================================================
	do
		local empty = GameConfig.carryMultiplierFor(0)
		local laden = GameConfig.carryMultiplierFor(2000)
		local heavy = GameConfig.carryMultiplierFor(topTier)
		ok("pick up heavy -> suppressed", bandFor(heavy) == NONE)
		ok("bank it -> restored", bandFor(empty) == FULL)
		ok("pick up mid-weight -> reduced", bandFor(laden) == REDUCED,
			string.format("%.2f -> %s", laden, bandFor(laden)))
		ok("drop it -> restored", bandFor(empty) == FULL)
		ok("an empty hand is exactly 1", empty == 1)
		table.insert(lines, string.format(
			"  tier 0 -> %.2f (%s) | tier 2000 -> %.2f (%s) | tier %d -> %.2f (%s)",
			empty, bandFor(empty), laden, bandFor(laden),
			topTier, heavy, bandFor(heavy)))
	end

	--==========================================================================
	-- IT IS THE SERVER'S NUMBER, AND IT IS ON THE PLAYER
	--
	-- Both halves matter. On the PLAYER so it replicates to every client without
	-- a remote, which is what lets somebody else's loaded run look loaded. From
	-- the SERVER so it cannot be argued with -- a client that derived this from a
	-- replicated weight could decide not to.
	--==========================================================================
	ok("the attribute exists in config",
		type(GameConfig.Attributes.CarrySpeedMultiplier) == "string")
	ok("it is not the weight", GameConfig.Attributes.CarrySpeedMultiplier
		~= GameConfig.Attributes.CarryingKg)
	ok("the multiplier can never exceed 1", (function()
		for tier = 0, topTier, 13 do
			if GameConfig.carryMultiplierFor(tier) > 1 then
				return false
			end
		end
		return true
	end)())
	ok("the multiplier never reaches zero", (function()
		for tier = 0, topTier, 13 do
			if GameConfig.carryMultiplierFor(tier) <= 0 then
				return false
			end
		end
		return true
	end)())

	--==========================================================================
	-- THE REDUCED BAND STILL SHOWS SOMETHING
	--
	-- Shorter, narrower and fainter -- but present. A middle band that rendered
	-- nothing would be the dead band with extra steps, and the reading "you are
	-- slowing down" would be lost.
	--
	-- The fade is the one that could actually reach nothing: it ADDS to a
	-- transparency that is already 0.55 at tier 1, so the check is on the SUM
	-- rather than on the add, at every tier rather than at the top one.
	--==========================================================================
	for index, tier in ipairs(FX.Tiers) do
		local lifetime = tier.Lifetime * FX.CarryLifetimeScale
		local width = tier.WidthStuds * FX.CarryWidthScale
		local transparency = math.min(0.98, tier.HeadTransparency + FX.CarryFadeAdd)
		ok("reduced tier " .. index .. " still has length", lifetime > 0,
			string.format("%.2fs", lifetime))
		ok("reduced tier " .. index .. " still has width", width > 0,
			string.format("%.2f", width))
		ok("reduced tier " .. index .. " stays visible", transparency < 0.99,
			string.format("%.2f", transparency))
	end
	table.insert(lines, string.format(
		"  loaded tier 1 is the faintest case: %.2f + %.2f = %.2f, still under 0.99",
		FX.Tiers[1].HeadTransparency, FX.CarryFadeAdd,
		FX.Tiers[1].HeadTransparency + FX.CarryFadeAdd))
end

--==============================================================================
-- THE TAIL
--==============================================================================
table.insert(lines, "")
table.insert(lines, string.rep("-", 62))
if #failures == 0 then
	table.insert(lines, string.format("PASS -- %d assertions", passed))
else
	table.insert(lines, string.format("FAIL -- %d passed, %d FAILED", passed, #failures))
	for _, f in ipairs(failures) do
		table.insert(lines, "  x " .. f)
	end
end

return table.concat(lines, "\n")
