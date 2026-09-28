--!nocheck
--==============================================================================
-- Steal a Seed :: CashFormatSpec
--
-- How a balance is spelled (GameConfig.money, 2026-09-24): one precision at
-- every size, never rounded up, and the same spelling wherever a balance is
-- shown -- the corner HUD, the player list and Marigold's header. Plus the one
-- money number a shop tile prints that is not the player's: the x2 pass's list
-- price. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("CashFormatSpec"))
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)

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
local function sourceOf(instance)
	if instance == nil then
		return ""
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local UNIT = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15 }
-- What a spelled balance claims the player has, back as a number.
local function claimed(text)
	local sign = 1
	if string.sub(text, 1, 1) == "-" then
		sign, text = -1, string.sub(text, 2)
	end
	local digits, suffix = string.match(text, "^([%d,%.]+)(%a*)$")
	if not digits then
		return nil
	end
	local n = tonumber((string.gsub(digits, ",", "")))
	if not n then
		return nil
	end
	if suffix ~= "" then
		local scale = UNIT[suffix]
		if not scale then
			return nil
		end
		n *= scale
	end
	return sign * n
end

local ok, err = pcall(function()
	local money = GameConfig.money
	check(type(money) == "function", "GameConfig.money exists")

	--==========================================================================
	-- 1. THE SPELLINGS
	--==========================================================================
	say("-- spellings --")
	local cases = {
		{ 0, "0" }, { 7, "7" }, { 99.5, "99" }, { 999, "999" }, { 1000, "1,000" },
		{ 1234.56, "1,234" }, { 5000, "5,000" }, { 9999, "9,999" }, { 9999.99, "9,999" },
		{ 12345, "12,345" }, { 99999, "99,999" }, { 99999.6, "99,999" }, { 100000, "100K" },
		{ 123456, "123K" }, { 999999.9, "999K" }, { 1e6, "1.00M" }, { 1.5e6, "1.50M" },
		{ 1.234e6, "1.23M" }, { 1.239e6, "1.23M" }, { 12345678, "12.3M" }, { 123456789, "123M" },
		{ 3427039827, "3.42B" }, { 1e15, "1.00Qa" }, { -5, "-5" }, { 0 / 0, "0" },
	}
	local wrong = {}
	for _, c in ipairs(cases) do
		local got = money(c[1])
		if got ~= c[2] then
			table.insert(wrong, string.format("%s -> %s (want %s)", tostring(c[1]), got, c[2]))
		end
	end
	check(#wrong == 0, "the table: whole dollars with commas below 100K, three kept digits above",
		table.concat(wrong, "; "))
	check(money(9999) ~= "10K" and money(9999.99) == "9,999",
		"$9,999 no longer reads as the $10K a player cannot yet pay")
	check(money(math.huge) == money(GameConfig.Save.MaxCash), "an infinite balance reads as the cap")

	--==========================================================================
	-- 2. NEVER ROUNDED UP, ONE PRECISION BELOW 100K
	--==========================================================================
	say("\n-- properties --")
	local rng = Random.new(20260924)
	local up, mixed = nil, nil
	for _ = 1, 2000 do
		local v = 10 ^ rng:NextNumber(0, 15)
		local text = money(v)
		local back = claimed(text)
		if back == nil or back > v + 1e-6 then
			up = string.format("%.4f -> %s", v, text)
		end
		if v < 1e5 and (string.find(text, ".", 1, true) or not string.match(text, "^[%d,]+$")) then
			mixed = string.format("%.4f -> %s", v, text)
		end
	end
	check(up == nil, "2,000 balances from $1 to $1Qa: the spelling never claims more than the balance", up)
	check(mixed == nil, "below 100K it is always whole dollars -- never a decimal", mixed)
	local widths = true
	for v = 1000, 99999, 7 do
		local text = money(v + 0.73)
		local digits = #tostring(math.floor(v))
		if #text ~= digits + math.floor((digits - 1) / 3) then
			widths = false
		end
	end
	check(widths, "below 100K the text is exactly its digits and commas, so it only widens when a digit is gained")

	--==========================================================================
	-- 3. EVERY BALANCE READOUT USES IT
	--==========================================================================
	say("\n-- the readouts --")
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local cashSrc = sourceOf(scripts:FindFirstChild("CashUI"))
	local shopSrc = sourceOf(scripts:FindFirstChild("MarigoldShopUI"))
	local dataSrc = sourceOf(game:GetService("ServerScriptService").SeedGameServer:FindFirstChild("PlayerDataService"))
	check(string.find(cashSrc, 'local text = "$" .. GameConfig.money(shown)', 1, true) ~= nil,
		"the corner HUD spells the balance with GameConfig.money")
	check(string.find(dataSrc, 'local cash = "$" .. GameConfig.money(profile.Cash)', 1, true) ~= nil
			and string.find(dataSrc, 'local speed = GameConfig.compact(profile.Speed)', 1, true) ~= nil,
		"the player list's Cash column does too, and Speed stays compact")
	local _, shopUses = string.gsub(shopSrc, 'cashLabel.Text = "%$" %.%. GameConfig%.money%(cash%)', "")
	check(shopUses == 2, "Marigold's header balance, in both places it is written", shopUses)
	check(string.find(cashSrc, "local textWidth = math.max(steadyWidth(), 0)", 1, true) ~= nil,
		"the x2 card is placed off a steady width, so it does not shuffle as digits change")

	--==========================================================================
	-- 4. A SHOP TILE PRINTS THIS PLAYER'S PRICE, NEVER THE MANIFEST'S
	--
	-- Roblox prices by region, so no number in GameConfig is right for every
	-- player: the tile asks Roblox at run time (RobuxPrice), shows dots until it
	-- knows, and BUY -- no price -- if it never does. The manifest keeps the list
	-- price for the server's receipts and logs.
	--==========================================================================
	say("\n-- the x2 pass --")
	local row = nil
	for _, r in ipairs(GameConfig.Store.Items.Passes or {}) do
		if r.key == "x2money" then
			row = r
		end
	end
	check(row ~= nil and row.pass == 1975418369 and row.robux == 199,
		"x2money is pass 1975418369 ('Permanent 2x Earn'), list price 199 in the manifest",
		row and row.robux)
	-- The Robux shop (ShopUI), not Marigold's cash stall read above.
	local robuxShopSrc = sourceOf(scripts:FindFirstChild("ShopUI"))
	check(robuxShopSrc ~= "" and not string.find(robuxShopSrc, "item.robux", 1, true)
			and string.find(robuxShopSrc, 'showPrice(card, "pass", passId)', 1, true) ~= nil
			and string.find(robuxShopSrc, 'showPrice(card, "product", productId)', 1, true) ~= nil,
		"every live tile, pass and product, prints RobuxPrice's answer and never the manifest's robux")
	check(string.find(robuxShopSrc, 'local PRICE_LOADING = "..."', 1, true) ~= nil
			and string.find(robuxShopSrc, 'local PRICE_UNKNOWN = "BUY"', 1, true) ~= nil
			and string.find(robuxShopSrc, "RobuxPrice.refresh()", 1, true) ~= nil,
		"loading shows dots, a failed lookup shows BUY and no number, and opening the shop asks again")

	--==========================================================================
	-- 5. THE MONEY TICK (reported irritating 2026-09-26)
	--
	-- CashUI's readout replayed at 60 fps against a stream of balance updates,
	-- once under the old rule (a tick on every third printed change) and once
	-- under GameConfig.Sfx.CashTicks. Income lands once a second; a $500 sale
	-- lands at 5.0 s in the second run. The counts are ticks in 10 seconds.
	--==========================================================================
	say("\n-- the money tick --")
	local T = GameConfig.Sfx.CashTicks
	local function replay(rate, sale, newRule)
		local target, shown, text = 1000, 1000, "$" .. GameConfig.money(1000)
		local changes, ticks, lastTick, routine, counting = 0, 0, -math.huge, nil, false
		local routineTicks, countTicks = 0, 0
		local dt = 1 / 60
		for frame = 1, 600 do
			local t = frame * dt
			local step = 0
			if frame % 60 == 0 then
				step += rate
			end
			if sale and frame == 300 then
				step += sale
			end
			if step ~= 0 then
				if GameConfig.cashStepIsLump(step, routine) then
					counting = true
				end
				routine = GameConfig.cashRoutineStep(routine, step)
				target += step
			end
			local gap = target - shown
			local landed = math.abs(gap) < 0.5
			if landed then
				shown = target
			else
				shown += gap * math.min(1, dt * 6)
			end
			local now = "$" .. GameConfig.money(shown)
			if now ~= text then
				text = now
				changes += 1
				if newRule then
					if t - lastTick >= (if counting then T.CountSeconds else T.RoutineSeconds) then
						lastTick = t
						ticks += 1
						if counting then countTicks += 1 else routineTicks += 1 end
					end
				elseif changes % 3 == 0 then
					ticks += 1
				end
			end
			if landed then
				counting = false
			end
		end
		return ticks, routineTicks, countTicks
	end
	local old4 = replay(4, nil, false)
	local new4 = replay(4, nil, true)
	local old100 = replay(100, nil, false)
	local new100 = replay(100, nil, true)
	say(string.format("  $4/s: %d ticks before, %d after.  $100/s: %d before, %d after.",
		old4, new4, old100, new100))
	check(new4 <= math.ceil(10 / T.RoutineSeconds) and new100 <= math.ceil(10 / T.RoutineSeconds),
		"plant income ticks at most once every RoutineSeconds, at any rate", string.format("%d / %d", new4, new100))
	check(old100 >= 3 * new100, "-- a third or less of what a $100/s garden used to tick", string.format("%d vs %d", old100, new100))
	check(T.RoutineVolume < 1 and T.RoutineVolume > 0, "and it ticks quieter than the cue's level", T.RoutineVolume)
	local _, routineSale, countSale = replay(4, 500, true)
	check(countSale >= 3, "a $500 sale is still counted in with a run of ticks", countSale)
	check(countSale <= math.ceil(10 / T.CountSeconds), "never faster than one per CountSeconds", countSale)
	check(routineSale <= math.ceil(10 / T.RoutineSeconds), "and the income around it stays routine", routineSale)
	check(not GameConfig.cashStepIsLump(4, nil), "the first change of a session is not a lump -- nothing to compare it to")
	check(GameConfig.cashStepIsLump(500, 4) and not GameConfig.cashStepIsLump(8, 4),
		"a sale is a lump against $4 steps; a garden that doubles is not")
	local r = 4
	r = GameConfig.cashRoutineStep(r, 900)
	check(not GameConfig.cashStepIsLump(900, r), "income that jumps to $900 is a lump once and routine the next second", r)
	check(GameConfig.cashStepIsLump(-500, 4), "a purchase is counted down like a sale")

	check(string.find(cashSrc, "if GameConfig.cashStepIsLump(step, routineStep) then", 1, true) ~= nil
			and string.find(cashSrc, 'SoundKit.play("CashTick", if counting then nil else ROUTINE_TICK)', 1, true) ~= nil
			and string.find(cashSrc, "if landed then\n\t\tcounting = false", 1, true) ~= nil,
		"CashUI sorts each change as it arrives and ticks by that rule")
	check(not string.find(cashSrc, "tickCount % 3", 1, true), "and the every-third-change tick is gone")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nCashFormatSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
