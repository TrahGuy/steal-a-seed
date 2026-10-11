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

	--==========================================================================
	-- 5. THE GREEN ROBUX TAG (2026-10-12, the owner: every Robux buy button on
	--    the green Robux art, the price right of its mark, no glyph of ours)
	--==========================================================================
	say("\n-- the green Robux tag --")
	local UIKit = require(Shared.UIKit)
	local RAIL = require(Shared.GameConfig).Rail
	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromOffset(200, 40)
	local tag = UIKit.priceTag(holder, "SpecTag", 3)
	local shape = tag.frame:FindFirstChildOfClass("UIAspectRatioConstraint")
	local spot = RAIL.StuddedShopDesktopWord
	check(shape ~= nil and math.abs(shape.AspectRatio - RAIL.StuddedShopDesktopAspect) < 1e-4
			and tag.art.Image == RAIL.StuddedShopDesktopArt and tag.art.ScaleType == Enum.ScaleType.Fit
			and tag.art.Size == UDim2.fromScale(1, 1),
		"the owner's green plate (the desktop Shop's) at its own 3 : 1, fitted, never stretched")
	check(tag.price.Font == Enum.Font.LuckiestGuy and tag.price.TextColor3 == Color3.new(1, 1, 1)
			and tag.price:FindFirstChildOfClass("UIStroke") ~= nil and tag.price.TextScaled
			and math.abs(tag.price.Position.X.Scale - spot.Left) < 1e-6
			and math.abs(tag.price.Size.X.Scale - (spot.Right - spot.Left)) < 1e-6
			and tag.price.ZIndex > tag.art.ZIndex,
		"the price right of the plate's mark, in the HUD's outlined white type, over the picture")
	holder:Destroy()
	local loadoutSrc = sourceOf(scripts:FindFirstChild("LoadoutUI"))
	local wheelSrc = sourceOf(scripts:FindFirstChild("WheelUI"))
	local panelSrc = sourceOf(Shared:FindFirstChild("InventoryPanel"))
	check(has(shopSrc, "local function dressTag(p: Price, buying: boolean)")
			and has(shopSrc, 'local tag = UIKit.priceTag(plate, "RobuxTag", z + 3)')
			and has(shopSrc, "\t\tface(\"go\")\n\t\tbuying = true\n") and has(shopSrc, "\tdressTag(p, buying)\nend")
			and has(shopSrc, "tag.price.Text = p.price.Text"),
		"the Shop's buy buttons: a buy state's whole face is the tag; SOON, OWNED, OPENING... and OFF SALE keep theirs")
	check(has(loadoutSrc, "robux = if credits <= 0 and price then RobuxPrice.format(price) else nil")
			and not has(loadoutSrc, 'R$%s')
			and has(panelSrc, "if action.robux then")
			and has(panelSrc, 'local tag = UIKit.priceTag(mb.plate, "RobuxTag", mb.label.ZIndex)'),
		"the Bag's Instant Hatch: its words, and its price on the tag at the button's right end; a saved one free")
	check(has(promptSrc, 'local tag = UIKit.priceTag(content, "Price", 3)') and not has(promptSrc, "robux@3x")
			and has(wheelSrc, 'local tag = UIKit.priceTag(b, "Capsule", 3)') and not has(wheelSrc, "robux@3x")
			and has(wheelSrc, "choice.capsule.BackgroundTransparency = if tagged then 1 else 0")
			and has(wheelSrc, "choice.capsule.Size = UDim2.new(0, 72, 0, 24)")
			and math.ceil(24 * RAIL.StuddedShopDesktopAspect) == 72,
		"a prompt that sells something and the Wheel's ticket packs: the tag, no glyph of ours; off sale the white pill")
end)

RobuxPrice.RetryAfter, RobuxPrice.StaleAfter = savedRetry, savedStale
RobuxPrice.setAskerForTests(nil)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRobuxPriceSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
