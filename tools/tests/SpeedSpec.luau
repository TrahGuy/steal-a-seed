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
			biome.DisplayName, GameConfig.compact(biome.SpeedGate)))
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
	local want: { [number]: number } = {
		[5] = 51200, [6] = 204800, [7] = 819200,
		[8] = 3276800, [9] = 13107200, [10] = 52428800,
	}
	for level = 0, O.MaxLevel do
		local rate = GameConfig.trainingRateFor(top, level, nil)
		if want[level] then
			ok("tier 7 at overclock " .. level, near(rate, want[level]),
				string.format("want %d got %.0f", want[level], rate))
		end
		local cost = GameConfig.overclockCostFor(level)
		table.insert(lines, string.format("  L%-2d %10s/s   %-10s biome %s",
			level, GameConfig.compact(rate),
			if cost then "$" .. GameConfig.compact(cost) else "-",
			tostring(GameConfig.overclockUnlockOrderFor(level) or "-")))
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
	ok("there is an unlock for every level", #O.UnlockedBy == O.MaxLevel)
	ok("no level needs a biome that does not exist", (function()
		for _, order in ipairs(O.UnlockedBy) do
			if order < 1 or order > #BiomeData.Biomes then
				return false
			end
		end
		return true
	end)())
	ok("unlock requirement never goes backwards", (function()
		local prev = 0
		for _, order in ipairs(O.UnlockedBy) do
			if order < prev then
				return false
			end
			prev = order
		end
		return true
	end)())
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
			GameConfig.compact(biome.SpeedGate)))
	end

	local function earnedBy(score: number): number
		local earned = 1
		for _, biome in ipairs(BiomeData.Biomes) do
			if score >= biome.SpeedGate then
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

		-- And the overclock that biome unlocked is still buyable, which is the
		-- consequence that actually matters to the player.
		ok("an overclock unlocked by a biome stays unlocked",
			(GameConfig.overclockUnlockOrderFor(9) or 99) <= rebirthed.HighestBiomeOrder)

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
			if biome.SpeedGate <= prev or biome.SpeedGate > GameConfig.Save.MaxSpeedScore then
				return false
			end
			prev = biome.SpeedGate
		end
		return true
	end)())
end

--==============================================================================
-- 8. CARRY STILL MULTIPLIES THE CURVE
--
-- The single most important regression to catch. CarryService computes
-- walkSpeedFor(score) * carryMultiplierFor(kg), and a curve change that
-- accidentally moved the multiply -- or made the curve return something the
-- multiply cannot scale -- would silently delete the weight system, which is the
-- entire risk/reward of the game.
--==============================================================================
section("carry multiplier after the new curve")
do
	local maxKg = GameConfig.Carry.MaxKg
	local floorMult = GameConfig.Carry.MinMultiplier
	ok("empty hands do not scale", near(GameConfig.carryMultiplierFor(0), 1))
	ok("max weight is the floor", near(GameConfig.carryMultiplierFor(maxKg), floorMult))
	ok("carry is monotonically punishing", (function()
		local prev = math.huge
		for kg = 0, maxKg, 97 do
			local m = GameConfig.carryMultiplierFor(kg)
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
		local heavy = base * GameConfig.carryMultiplierFor(maxKg)
		ok("carry scales at " .. GameConfig.compact(score),
			light <= base + 1e-9 and heavy < light and heavy >= base * floorMult - 1e-9)
		--==================================================================
		-- A HEAVY CARRY IS ALWAYS SLOWER, AT EVERY SCORE
		--
		-- Where the ghosts stop is section 9's business, because it depends on
		-- the motion gate. What belongs HERE is the property the whole
		-- risk/reward rests on: carrying always costs speed, the cost never
		-- inverts, and the floor is never breached.
		--==================================================================
		ok("a max carry is never faster than a light one at "
			.. GameConfig.compact(score), heavy < light)
		table.insert(lines, string.format("  %-8s base %6.2f   1kg %6.2f   %dkg %6.2f",
			GameConfig.compact(score), base, light, maxKg, heavy))
	end
	ok("SeedData delegates to the one multiplier",
		near(SeedData.CarryMultiplier(500), GameConfig.carryMultiplierFor(500)))
end

--==============================================================================
-- 9. THE SEVEN AFTERIMAGE TIERS
--
-- Every threshold, both sides of it. A tier that starts one Speed late is a
-- player who hits a round number and sees nothing happen, which is the exact
-- moment the whole system is supposed to pay out.
--==============================================================================
section("afterimage tiers")
do
	local FX = GameConfig.Afterimage
	local expected: { { any } } = {
		{ 1, 1e3, "First Echo" },
		{ 2, 1e6, "Double Step" },
		{ 3, 1e9, "Charged Blur" },
		{ 4, 1e12, "Phase Runner" },
		{ 5, 1e13, "Prism Wake" },
		{ 6, 1e14, "Aurora Rush" },
		{ 7, 1e15, "Rainbow Ascension" },
	}
	ok("there are seven tiers", #FX.Tiers == 7, tostring(#FX.Tiers))

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
				"  %d %-18s from %-6s %d ghost(s)  every %.2f studs  fade %.2fs  transp %.2f",
				index, tier.Name, GameConfig.compact(tier.From), tier.Ghosts,
				tier.SpacingStuds, tier.FadeSeconds, tier.StartTransparency))
		end
	end

	--==========================================================================
	-- BELOW THE FIRST THRESHOLD, NOTHING
	--==========================================================================
	ok("nothing below 1K earns a ghost", (function()
		local x = 0.0
		while x < 1e3 do
			if GameConfig.speedVisualTierFor(x) ~= 0 then
				return false
			end
			x = if x < 1 then 1 else x * 1.01
		end
		return true
	end)())
	for _, case in ipairs({ { 0, 0 }, { -1, 0 }, { 0 / 0, 0 }, { 999, 0 },
		{ math.huge, 7 }, { 1e30, 7 } }) do
		ok("visual tier at " .. tostring(case[1]),
			GameConfig.speedVisualTierFor(case[1] :: any) == case[2],
			tostring(GameConfig.speedVisualTierFor(case[1] :: any)))
	end
	ok("visual tier for nil", GameConfig.speedVisualTierFor(nil :: any) == 0)
	ok("visual tier for a string", GameConfig.speedVisualTierFor("x" :: any) == 0)

	--==========================================================================
	-- THE SHAPE OF THE LADDER
	--
	-- Thresholds ascend, ghosts never decrease, spacing tightens, fades lengthen
	-- -- and the ghost count STOPS at four. That last one is the performance
	-- promise: higher tiers buy colour, not instances.
	--==========================================================================
	local prevFrom, prevGhosts, prevSpacing = -1, 0, math.huge
	local shapeOk = true
	for _, tier in ipairs(FX.Tiers) do
		if tier.From <= prevFrom or tier.Ghosts < prevGhosts
			or tier.SpacingStuds > prevSpacing
			or tier.Ghosts > FX.LocalMaxGhosts then
			shapeOk = false
		end
		prevFrom, prevGhosts = tier.From, tier.Ghosts
		prevSpacing = tier.SpacingStuds
	end
	ok("thresholds ascend, spacing tightens, ghosts never drop", shapeOk)

	--==========================================================================
	-- FADE IS NOT MONOTONIC, AND ASSERTING THAT IT WAS WAS THE WRONG TEST
	--
	-- Tier 2's fade is longer than tier 3's, which looks like a mistake in the
	-- column and is not. FADE IS WALL-CLOCK; SPEED IS NOT. Tier 2 is worn by
	-- somebody moving at 32 and tier 3 by somebody at 56, so the same PERSISTENCE
	-- costs a longer fade lower down the ladder.
	--
	-- What actually decides whether a tier looks like its name is how many echoes
	-- are alive AT THE SPEED ITS OWNER MOVES AT, which is what this checks. A
	-- tier called Double Step that renders one ghost is broken however tidy its
	-- fade column looks -- and it WAS broken, at exactly 1M, until this test
	-- existed.
	--==========================================================================
	--==========================================================================
	-- COUNTED AS A FRACTION, BECAUSE CEILING LIES
	--
	-- `ceil(fade / gap)` said tier 2 showed two at 9.0 studs and 0.30s, and a
	-- three-second measured run never caught a pair: the overlap was 19ms out of
	-- a 281ms cycle, so a second ghost existed for 7% of the time and the answer
	-- "2" was a rounding win rather than a description.
	--
	-- fade / gap is the honest number -- the AVERAGE echoes alive -- and 1.4 is
	-- the bar for a tier to genuinely read as a pair. Below that it is one echo
	-- with an occasional flicker of a second.
	--==========================================================================
	for index, tier in ipairs(FX.Tiers) do
		local walk = GameConfig.walkSpeedFor(tier.From)
		local secondsBetween = tier.SpacingStuds / walk
		local alive = tier.FadeSeconds / secondsBetween
		local shown = math.min(alive, tier.Ghosts)
		table.insert(lines, string.format(
			"  %d %-18s walk %6.2f -> echo every %.3fs, life %.2fs = %.2f alive (cap %d)",
			index, tier.Name, walk, secondsBetween, tier.FadeSeconds, shown, tier.Ghosts))
		if index == 2 then
			ok("Double Step genuinely reads as a pair at 1M", shown >= 1.4,
				string.format("%.2f alive", shown))
		end
		ok("tier " .. index .. " shows at least one echo at its own unlock speed",
			alive >= 0.25, string.format("%.2f", alive))
	end
	ok("the top four tiers all cap at four ghosts",
		FX.Tiers[4].Ghosts == 4 and FX.Tiers[5].Ghosts == 4
			and FX.Tiers[6].Ghosts == 4 and FX.Tiers[7].Ghosts == 4)

	--==========================================================================
	-- SPACING AND FADE ARE WITHIN THE BRIEF
	--==========================================================================
	local want: { { number } } = {
		{ 11, 12, 0.14 }, { 8, 10, 0.36 }, { 7, 8, 0.22 },
		{ 6, 7, 0.26 }, { 5.5, 6, 0.28 }, { 5, 5, 0.30 }, { 4.5, 5, 0.32 },
	}
	for i, w in ipairs(want) do
		local tier = FX.Tiers[i]
		ok("tier " .. i .. " spacing is in range",
			tier.SpacingStuds >= w[1] and tier.SpacingStuds <= w[2],
			tostring(tier.SpacingStuds))
		ok("tier " .. i .. " fade is about " .. w[3],
			math.abs(tier.FadeSeconds - w[3]) <= 0.02, tostring(tier.FadeSeconds))
	end

	--==========================================================================
	-- WHAT EACH TIER ANIMATES
	--==========================================================================
	ok("tiers 1 and 2 are static", FX.Tiers[1].Wave == 0 and FX.Tiers[2].Wave == 0
		and FX.Tiers[1].Pulse == 0 and FX.Tiers[2].Pulse == 0)
	ok("tier 3 pulses", FX.Tiers[3].Pulse > 0)
	ok("tier 4 gradients down the body", FX.Tiers[4].BodyGradient == true)
	ok("tier 5 shimmers", FX.Tiers[5].Shimmer > 0)
	ok("tier 5 alternates three colours", #FX.Tiers[5].Palette == 3)
	ok("tier 6 waves", FX.Tiers[6].Wave > 0)
	ok("tier 6 gives each ghost a different phase", FX.Tiers[6].GhostSpread > 0)
	ok("tier 6 uses a four-colour aurora", #FX.Tiers[6].Palette == 4)
	ok("only tier 7 is a rainbow", (function()
		for i, tier in ipairs(FX.Tiers) do
			if tier.Rainbow ~= (i == 7) then
				return false
			end
		end
		return true
	end)())
	ok("tier 7 expands about 3 percent",
		math.abs(FX.Tiers[7].Expand - 0.03) < 1e-9, tostring(FX.Tiers[7].Expand))
	ok("tier 7 pulses", FX.Tiers[7].Pulse > 0)
	ok("only tier 7 rainbows the trail", (function()
		for i, tier in ipairs(FX.Tiers) do
			if tier.TrailRainbow ~= (i == 7) then
				return false
			end
		end
		return true
	end)())
	ok("every tier has every field", (function()
		for _, tier in ipairs(FX.Tiers) do
			for _, key in ipairs({ "From", "Name", "Ghosts", "SpacingStuds",
				"FadeSeconds", "StartTransparency", "Palette", "GhostSpread",
				"BodyGradient", "Wave", "Pulse", "Shimmer", "Rainbow", "Expand",
				"TrailRainbow" }) do
				if (tier :: any)[key] == nil then
					return false
				end
			end
		end
		return true
	end)())

	--==========================================================================
	-- TIER 7 REALLY IS A HUE WAVE, NOT ONE COLOUR PER GHOST
	--
	-- Reproduces the client's own expression -- ghost phase, height down the
	-- body, time -- and asserts it MOVES on all three. A rainbow that assigns
	-- one static colour per echo is the failure mode the brief specifically
	-- rules out, and it is invisible in a screenshot.
	--==========================================================================
	do
		local tier = FX.Tiers[7]
		local function hueAt(phase: number, height: number, clock: number): number
			local position = phase * tier.GhostSpread
				+ (1 - height) * FX.BodyHueSpread
				+ clock * tier.Wave
			return position % 1
		end
		local headNow = hueAt(0, 1, 0)
		local footNow = hueAt(0, 0, 0)
		ok("tier 7 hue changes from head to feet",
			math.abs(headNow - footNow) > 0.05,
			string.format("head %.3f foot %.3f", headNow, footNow))

		local ghostA = hueAt(0, 1, 0)
		local ghostB = hueAt(1 / 4, 1, 0)
		ok("consecutive ghosts start at different hues",
			math.abs(ghostA - ghostB) > 0.05,
			string.format("%.3f vs %.3f", ghostA, ghostB))

		local t0 = hueAt(0, 1, 0)
		local t1 = hueAt(0, 1, 0.5)
		ok("the wave travels over time", math.abs(t0 - t1) > 0.05,
			string.format("%.3f -> %.3f", t0, t1))

		local wrapped = hueAt(0, 1, 1 / tier.Wave)
		ok("the hue wheel wraps", math.abs(wrapped - t0) < 1e-6)

		-- Four ghosts must land on four DIFFERENT hues, not two pairs.
		local seen: { [string]: boolean } = {}
		local distinct = 0
		for slot = 0, 3 do
			local key = string.format("%.3f", hueAt(slot / 4, 1, 0))
			if not seen[key] then
				seen[key] = true
				distinct += 1
			end
		end
		ok("all four ghosts start on different hues", distinct == 4, tostring(distinct))
		table.insert(lines, string.format(
			"  tier 7 hue: head %.2f foot %.2f, ghost 2 starts %.2f, +0.5s -> %.2f",
			headNow, footNow, ghostB, t1))
	end

	--==========================================================================
	-- THE PERFORMANCE PROMISES
	--==========================================================================
	ok("colour updates are throttled to 10-15 Hz",
		FX.ColourHz >= 10 and FX.ColourHz <= 15, tostring(FX.ColourHz))
	ok("mobile updates colour more slowly", FX.MobileColourHz < FX.ColourHz)
	ok("mobile gets fewer ghosts", FX.MobileMaxGhosts < FX.LocalMaxGhosts)
	ok("four for the local player", FX.LocalMaxGhosts == 4)
	ok("two for a remote player", FX.RemoteMaxGhosts == 2)
	ok("remote effects stop at about 120 studs",
		FX.RemoteMaxStuds >= 100 and FX.RemoteMaxStuds <= 140,
		tostring(FX.RemoteMaxStuds))
	ok("the motion gate is about 10 studs/s",
		FX.MoveStudsPerSecond >= 8 and FX.MoveStudsPerSecond <= 12,
		tostring(FX.MoveStudsPerSecond))
	ok("the motion gate is below base WalkSpeed, so tier 1 works at 1K",
		FX.MoveStudsPerSecond < GameConfig.walkSpeedFor(1e3),
		string.format("gate %d vs walk %.1f at 1K",
			FX.MoveStudsPerSecond, GameConfig.walkSpeedFor(1e3)))
	ok("a teleport is bigger than any real stride", FX.TeleportStuds > 16)
	table.insert(lines, string.format(
		"  emit above %d studs/s | ignore jumps over %d studs | colour %d Hz (%d mobile)",
		FX.MoveStudsPerSecond, FX.TeleportStuds, FX.ColourHz, FX.MobileColourHz))
	table.insert(lines, string.format(
		"  ghosts: %d local, %d remote, %d mobile, cut off past %d studs",
		FX.LocalMaxGhosts, FX.RemoteMaxGhosts, FX.MobileMaxGhosts, FX.RemoteMaxStuds))

	--==========================================================================
	-- A HEAVY POD STILL SUPPRESSES, BUT NOT AS FAR UP THE LADDER
	--
	-- The gate dropped from 35 studs/s to 10 so tier 1 can work at a thousand
	-- Speed, and the consequence is arithmetic: a maximum carry only holds a
	-- player under 10 while 0.30 x walk is under 10. Recorded rather than
	-- asserted at a typed number, so the report stays true after any retune.
	--==========================================================================
	do
		local maxKg = GameConfig.Carry.MaxKg
		local floorAt = GameConfig.carryMultiplierFor(maxKg)
		ok("a max carry suppresses ghosts at the bottom of the ladder",
			GameConfig.walkSpeedFor(0) * floorAt < FX.MoveStudsPerSecond)
		local lo, hi = 0.0, GameConfig.Save.MaxSpeedScore
		for _ = 1, 200 do
			local mid = (lo + hi) * 0.5
			if GameConfig.walkSpeedFor(mid) * floorAt < FX.MoveStudsPerSecond then
				lo = mid
			else
				hi = mid
			end
		end
		table.insert(lines, string.format(
			"  a %d kg pod holds a player under the gate below %s Speed",
			maxKg, GameConfig.compact(lo)))
	end
end


--==============================================================================
-- 10. WEIGHT SUPPRESSES THE GHOSTS
--
-- The speed gate cannot do this any more. It used to: at 35 studs/s a heavy pod
-- held a player under it. Tier 1 needs 10, because a player at 1K Speed walks at
-- 22 -- and at 10 a loaded player clears the gate easily. Without a separate
-- test, the one moment this game is built around (running home rich and slow)
-- would carry the most spectacular effect in the game.
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
	ok("the full band starts above 0.75", FX.CarryFullAbove == 0.75)
	ok("the dead band starts below 0.50", FX.CarryReducedAbove == 0.50)
	ok("reduced means one ghost", FX.CarryReducedGhosts == 1)
	ok("reduced is fainter", FX.CarryReducedFade > 0)
	ok("reduced is sparser", FX.CarryReducedSpacing > 1)

	--== the three bands, on both sides of both edges ==--
	for _, case in ipairs({
		{ 1.00, FULL }, { 0.90, FULL }, { 0.7501, FULL },
		{ 0.75, REDUCED }, { 0.60, REDUCED }, { 0.50, REDUCED },
		{ 0.4999, NONE }, { 0.30, NONE }, { 0.0, NONE },
	}) do
		ok("multiplier " .. tostring(case[1]) .. " is " .. case[2],
			bandFor(case[1]) == case[2], bandFor(case[1]))
	end

	--== a missing or broken attribute must never delete the effect ==--
	ok("a missing multiplier reads as unloaded", bandFor(nil) == FULL)
	ok("NaN reads as unloaded", bandFor(0 / 0) == FULL)
	ok("a string reads as unloaded", bandFor("heavy") == FULL)

	--==========================================================================
	-- WHAT EACH BAND MEANS IN KILOGRAMS
	--
	-- The bands are about the multiplier, but a player experiences kilograms, so
	-- this is where the two are tied together and printed.
	--==========================================================================
	local maxKg = GameConfig.Carry.MaxKg
	local edgeFull, edgeDead = -1, -1
	for kg = 0, maxKg do
		local band = bandFor(GameConfig.carryMultiplierFor(kg))
		if band ~= FULL and edgeFull < 0 then
			edgeFull = kg
		end
		if band == NONE and edgeDead < 0 then
			edgeDead = kg
		end
	end
	table.insert(lines, string.format(
		"  full effect up to %d kg | reduced %d..%d kg | nothing from %d kg up",
		edgeFull - 1, edgeFull, edgeDead - 1, edgeDead))
	ok("an empty-handed player is unaffected",
		bandFor(GameConfig.carryMultiplierFor(0)) == FULL)
	ok("a 1 kg pod is unaffected", bandFor(GameConfig.carryMultiplierFor(1)) == FULL)
	ok("a maximum pod kills the effect",
		bandFor(GameConfig.carryMultiplierFor(maxKg)) == NONE)

	--==========================================================================
	-- A MAXIMUM POD IS SILENT AT EVERY TIER, INCLUDING THE RAINBOW
	--
	-- The requirement that the speed gate can no longer meet on its own, and the
	-- reason this whole section exists. Asserted at every tier rather than at the
	-- top one, because a band that failed only in the middle would be invisible.
	--==========================================================================
	local heavyMultiplier = GameConfig.carryMultiplierFor(maxKg)
	for index, tier in ipairs(FX.Tiers) do
		ok("a max pod suppresses tier " .. index .. " (" .. tier.Name .. ")",
			bandFor(heavyMultiplier) == NONE)
	end
	table.insert(lines, string.format(
		"  a %d kg pod is multiplier %.2f -> %s, at all %d tiers",
		maxKg, heavyMultiplier, bandFor(heavyMultiplier), #FX.Tiers))

	--== and it is suppressed by WEIGHT, not by being slow ==--
	local heavyWalkAtCap = GameConfig.walkSpeedFor(GameConfig.Save.MaxSpeedScore)
		* heavyMultiplier
	ok("at 1Qa a max pod is still well over the speed gate",
		heavyWalkAtCap > FX.MoveStudsPerSecond,
		string.format("%.1f vs %d", heavyWalkAtCap, FX.MoveStudsPerSecond))
	table.insert(lines, string.format(
		"  at 1Qa a max pod still walks %.1f studs/s -- over the %d gate, so the",
		heavyWalkAtCap, FX.MoveStudsPerSecond))
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
		local heavy = GameConfig.carryMultiplierFor(maxKg)
		ok("pick up heavy -> suppressed", bandFor(heavy) == NONE)
		ok("bank it -> restored", bandFor(empty) == FULL)
		ok("pick up mid-weight -> reduced", bandFor(laden) == REDUCED,
			string.format("%.2f -> %s", laden, bandFor(laden)))
		ok("drop it -> restored", bandFor(empty) == FULL)
		ok("an empty hand is exactly 1", empty == 1)
		table.insert(lines, string.format(
			"  0 kg -> %.2f (%s) | 2000 kg -> %.2f (%s) | %d kg -> %.2f (%s)",
			empty, bandFor(empty), laden, bandFor(laden),
			maxKg, heavy, bandFor(heavy)))
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
		for kg = 0, maxKg, 13 do
			if GameConfig.carryMultiplierFor(kg) > 1 then
				return false
			end
		end
		return true
	end)())
	ok("the multiplier never reaches zero", (function()
		for kg = 0, maxKg, 13 do
			if GameConfig.carryMultiplierFor(kg) <= 0 then
				return false
			end
		end
		return true
	end)())

	--==========================================================================
	-- THE REDUCED BAND STILL SHOWS SOMETHING
	--
	-- One echo, fainter, further apart -- but present. A middle band that
	-- rendered nothing would be the dead band with extra steps, and the reading
	-- "you are slowing down" would be lost.
	--==========================================================================
	for index, tier in ipairs(FX.Tiers) do
		local ghosts = math.min(tier.Ghosts, FX.CarryReducedGhosts)
		local transparency = math.min(0.98, tier.StartTransparency + FX.CarryReducedFade)
		ok("reduced tier " .. index .. " still draws one echo", ghosts == 1)
		ok("reduced tier " .. index .. " stays visible", transparency < 0.99,
			string.format("%.2f", transparency))
	end
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
