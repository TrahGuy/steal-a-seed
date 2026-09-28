--!nocheck
--==============================================================================
-- Steal a Seed :: RobuxPriceSpec
--
-- A Robux price on screen is THIS player's, asked of Roblox at run time, or it
-- is not shown (RobuxPrice, 2026-09-24). Drives every state through a stand-in
-- for GetProductInfoAsync, then checks the two places a price is drawn -- the
-- Shop's tiles and the Instant Hatch prompt's capsule -- never print the
-- manifest's number. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RobuxPriceSpec"))
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local RobuxPrice = require(Shared.RobuxPrice)

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
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

-- What each id answers, and how many times it was asked.
local answers = {}
local asked = {}
local function stub(kind, id)
	local key = kind .. ":" .. id
	asked[key] = (asked[key] or 0) + 1
	local a = answers[key]
	if type(a) == "function" then
		return a(asked[key])
	end
	if a == nil then
		return false, "HTTP 500"
	end
	return true, a
end

-- Waits for `predicate` a short while; the stub answers on a spawned thread.
local function eventually(predicate)
	local t = os.clock()
	while os.clock() - t < 2 do
		if predicate() then
			return true
		end
		task.wait()
	end
	return predicate()
end

local savedRetry, savedStale = RobuxPrice.RetryAfter, RobuxPrice.StaleAfter

local ok, err = pcall(function()
	RobuxPrice.RetryAfter = { 0.02, 0.02, 0.02 }
	RobuxPrice.setAskerForTests(stub)

	--==========================================================================
	-- 1. LOADING, THEN THIS PLAYER'S PRICE
	--==========================================================================
	say("-- a pass --")
	answers["pass:1975418369"] = { PriceInRobux = 79, IsForSale = true }
	local seen = {}
	local stop = RobuxPrice.watch("pass", 1975418369, function(state, price)
		table.insert(seen, state .. ":" .. tostring(price))
	end)
	check(seen[1] == "loading:nil", "the first word is 'loading', with no number", seen[1])
	check(eventually(function()
		return seen[#seen] == "ready:79"
	end), "then the price Roblox gave THIS player -- 79 here, not the manifest's 199", table.concat(seen, ", "))

	local second = {}
	RobuxPrice.watch("pass", 1975418369, function(state, price)
		table.insert(second, state .. ":" .. tostring(price))
	end)
	check(second[1] == "ready:79" and asked["pass:1975418369"] == 1,
		"a second tile for the same id gets the answer at once, and Roblox was asked once",
		string.format("%s / asked %s", tostring(second[1]), tostring(asked["pass:1975418369"])))

	stop()
	local before = #seen
	answers["pass:1975418369"] = { PriceInRobux = 99, IsForSale = true }
	RobuxPrice.StaleAfter = -1
	RobuxPrice.refresh()
	check(eventually(function()
		return second[#second] == "ready:99"
	end) and #seen == before,
		"a stale price is asked for again, and a listener that stopped hears nothing",
		string.format("%s / %d vs %d", tostring(second[#second]), #seen, before))
	RobuxPrice.StaleAfter = savedStale

	--==========================================================================
	-- 2. NOT FOR SALE, AND NO ANSWER AT ALL
	--==========================================================================
	say("\n-- off sale and failure --")
	answers["pass:5"] = { PriceInRobux = nil, IsForSale = false }
	local off = {}
	RobuxPrice.watch("pass", 5, function(state, price)
		table.insert(off, state .. ":" .. tostring(price))
	end)
	check(eventually(function()
		return off[#off] == "offsale:nil"
	end), "a pass Roblox says is off sale is 'offsale', with no number", table.concat(off, ", "))

	local failed = {}
	RobuxPrice.watch("product", 77, function(state, price)
		table.insert(failed, state .. ":" .. tostring(price))
	end)
	check(eventually(function()
		return failed[#failed] == "failed:nil"
	end), "no answer after every retry is 'failed' -- and never a number", table.concat(failed, ", "))
	check(asked["product:77"] == #RobuxPrice.RetryAfter + 1,
		"it asked once and retried " .. #RobuxPrice.RetryAfter .. " times before giving up", asked["product:77"])
	local numbers = 0
	for _, s in ipairs(failed) do
		if not string.find(s, ":nil", 1, true) then
			numbers += 1
		end
	end
	check(numbers == 0, "no fallback price was ever offered on the way", table.concat(failed, ", "))

	answers["product:77"] = { PriceInRobux = 29 }
	RobuxPrice.refresh()
	check(eventually(function()
		return failed[#failed] == "ready:29"
	end), "a failed price is asked for again on refresh (the Shop opening) and heals",
		table.concat(failed, ", "))

	-- A refresh that fails keeps what was right a moment ago.
	answers["product:77"] = nil
	RobuxPrice.StaleAfter = -1
	RobuxPrice.refresh()
	task.wait(0.3)
	RobuxPrice.StaleAfter = savedStale
	check(failed[#failed] == "ready:29", "a failed REFRESH keeps the price already shown", failed[#failed])

	-- A developer product answers without IsForSale.
	answers["product:88"] = { PriceInRobux = 149 }
	local product = {}
	RobuxPrice.watch("product", 88, function(state, price)
		table.insert(product, state .. ":" .. tostring(price))
	end)
	check(eventually(function()
		return product[#product] == "ready:149"
	end), "a developer product (no IsForSale field) reads its PriceInRobux", table.concat(product, ", "))

	answers["product:89"] = { PriceInRobux = "garbage" }
	local bad = {}
	RobuxPrice.watch("product", 89, function(state, price)
		table.insert(bad, state .. ":" .. tostring(price))
	end)
	check(eventually(function()
		return bad[#bad] == "failed:nil"
	end), "an answer with no usable price is a failure, not a zero", table.concat(bad, ", "))

	--==========================================================================
	-- 3. THE NUMBER
	--==========================================================================
	say("\n-- format --")
	check(RobuxPrice.format(0) == "0" and RobuxPrice.format(199) == "199"
			and RobuxPrice.format(1500) == "1,500" and RobuxPrice.format(1234567) == "1,234,567",
		"199, 1,500, 1,234,567 -- grouped as the purchase prompt groups them",
		RobuxPrice.format(1234567))

	--==========================================================================
	-- 4. WHERE A PRICE IS DRAWN
	--==========================================================================
	say("\n-- the two places a price is drawn --")
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local shopSrc = sourceOf(scripts:FindFirstChild("ShopUI"))
	local promptSrc = sourceOf(scripts:FindFirstChild("PromptUI"))
	local plantSrc = sourceOf(game:GetService("ServerScriptService").SeedGameServer:FindFirstChild("PlantService"))
	check(shopSrc ~= "" and not has(shopSrc, "item.robux")
			and has(shopSrc, 'showPrice(card, "pass", passId)')
			and has(shopSrc, 'showPrice(card, "product", productId)'),
		"the Shop's pass and product tiles print RobuxPrice's answer, never the manifest's robux")
	check(has(promptSrc, "local productId = tonumber(prompt:GetAttribute(ROBUX_PRODUCT))")
			and has(promptSrc, 'number.Text = "..."')
			and has(promptSrc, 'entry.unwatch = RobuxPrice.watch("product", productId,')
			and not has(promptSrc, "tostring(math.floor(robux))"),
		"the Instant Hatch capsule shows dots, then this player's price, and never the attribute's 99")
	check(has(promptSrc, "shownCapsule.Visible = false")
			and has(promptSrc, "if capsule and amount and capsule.Visible then"),
		"with no product id or no answer the capsule is hidden, and the panel narrows to fit")
	check(has(plantSrc, 'prompt:SetAttribute("RobuxProduct", instantProductId())'),
		"the server names the product on the prompt, so the client can price it")
end)

RobuxPrice.RetryAfter, RobuxPrice.StaleAfter = savedRetry, savedStale
RobuxPrice.setAskerForTests(nil)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRobuxPriceSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
