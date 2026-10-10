--!nocheck
--==============================================================================
-- Steal a Seed :: SortSpec (2026-10-10, the owner's SORT)
--
-- The owner: "dont forget to add sort", then a SORT button stepping Rarity,
-- Income and Newest, saved per player, in the Bag and in MY PLANTS. In Edit:
--
--   1. the options: three ids in order, Rarity the default; the next one,
--      round again; junk refused; each button's words
--   2. the Bag's order (InventoryModel.groups / sort): income is the order
--      the Bag always had; rarity the rarest first across every category, bats
--      and traps by their own, what shows no rarity last; newest the latest
--      item first, equipment the dearest; favourites first in every one
--   3. the headers on every listed screen: the Bag's SORT between the search
--      and the heart, the search still its 140; MY PLANTS' SORT beside the
--      tabs, clear of the close, and never dropped before the count
--   4. the wiring: the profile's two fields and their defaults, the load's
--      sanitising, PlayerDataService's publish / set / reset-keep / verbs; the
--      Bag's and MY PLANTS' buttons, their sends and their saved attributes
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))

local SORT = GameConfig.Sort
local TIER = GameConfig.RarityTier

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

local function item(kind, speciesId, tier, extra)
	local i = { ref = nil, kind = kind, speciesId = speciesId, tier = tier, hatched = kind == "plant",
		sealed = false, restoring = false, count = 1, worn = false, favourite = false, order = 1 }
	for k, v in pairs(extra or {}) do
		i[k] = v
	end
	return i
end

local function names(list)
	local t = {}
	for _, g in ipairs(list) do
		table.insert(t, g.face.name)
	end
	return table.concat(t, ", ")
end

local function src(parent, path)
	local node = parent
	for _, name in ipairs(string.split(path, "/")) do
		node = node and node:FindFirstChild(name)
	end
	local ok, text = pcall(function()
		return node.Source
	end)
	return if ok and type(text) == "string" then text else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

local RAIL = GameConfig.Rail
local OUTLINE = RAIL.OutlineThickness
local TOPBAR, BAR_LEFT = 58, 208
local function rect(x, y, w, h)
	return { x = x, y = y, w = w, h = h }
end
local function screen(w, h, touch, keyboard, inset)
	inset = inset or 0
	return {
		safe = Vector2.new(w - inset * 2, h - TOPBAR - (if inset > 0 then 21 else 0)),
		touch = touch,
		keyboard = keyboard,
		viewport = Vector2.new(w, h),
		topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
		insetTop = TOPBAR,
	}
end
local function titleW(text, short, icon)
	local size = if short then 21 else 25
	local iconSize = if short then 24 else 28
	local words = TextService:GetTextSize(text, size, Enum.Font.LuckiestGuy, Vector2.new(4000, 200)).X + 6
	return (if icon then iconSize + 6 else 0) + words
end
local DESKS = { { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 1000, 609 }, { 1148, 716 } }
local PHONES = { { 640, 360 }, { 705, 338 }, { 772, 360 }, { 874, 402, 62 }, { 896, 414, 48 }, { 956, 440, 62 },
	{ 844, 390, 47 }, { 640, 480 }, { 801, 392 } }

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE OPTIONS
	--==========================================================================
	say("-- the options --")
	local ids = {}
	for _, o in ipairs(SORT.Options) do
		table.insert(ids, o.Id)
	end
	check(table.concat(ids, ",") == "rarity,income,newest" and SORT.Default == "rarity",
		"three orders, Rarity, Income, Newest; Rarity the default", table.concat(ids, ","))
	check(GameConfig.nextSort("rarity") == "income" and GameConfig.nextSort("income") == "newest"
			and GameConfig.nextSort("newest") == "rarity" and GameConfig.nextSort("junk") == "rarity"
			and GameConfig.nextSort(nil) == "rarity",
		"a press steps to the next, round again; anything unknown starts over")
	check(GameConfig.sortOption("income") == "income" and GameConfig.sortOption("INCOME") == nil
			and GameConfig.sortOption(1) == nil and GameConfig.sortOption(nil) == nil,
		"only an option id is one: junk, another case, a number and nil are refused")
	check(GameConfig.sortLabel("rarity") == "RARITY" and GameConfig.sortLabel("newest") == "NEWEST"
			and GameConfig.sortLabel("junk") == "RARITY" and SORT.Word == "SORT",
		"the button says SORT over RARITY / INCOME / NEWEST; junk shows the default")
	check(SORT.Bag.Action ~= SORT.Plants.Action and SORT.Bag.Attribute ~= SORT.Plants.Attribute
			and SORT.Bag.Action ~= GameConfig.MenuSize.Action,
		"the Bag and MY PLANTS keep their own, each its own verb and attribute")

	--==========================================================================
	-- 2. THE BAG'S ORDER
	--==========================================================================
	say("-- the Bag's order --")
	local items = {
		item("plant", "nubkin", 2, { ref = "i:11", order = 11 }),
		item("plant", "toadcap", 2, { ref = "i:14", order = 14 }),
		item("plant", "gloomlotus", 4, { ref = "i:12", order = 12 }),
		item("plant", "suncrown", 2, { ref = "i:13", order = 13 }),
		item("pod", "toadcap", 3, { ref = "i:15", order = 15, hatched = false }),
		item("weapon", nil, 1, { ref = "w:rootwood_bat", weaponId = "rootwood_bat", order = 1 }),
		item("weapon", nil, 1, { ref = "w:comet_bat", weaponId = "comet_bat", order = 6 }),
		item("weapon", nil, 1, { ref = "w:bramblejaw_trap", weaponId = "bramblejaw_trap", order = 7 }),
		item("trail", nil, 1, { order = 100 }),
		item("ticket", nil, 1, { count = 3, order = 0 }),
	}
	local function groups(mode)
		return InventoryModel.groups(items, {}, 0, nil, nil, mode)
	end
	local old, income = groups(nil), groups("income")
	check(names(old) == names(income), "Income is the order the Bag always had (no mode at all)", names(income))
	local incomeOk, lastIncome = true, math.huge
	for _, g in ipairs(income) do
		if g.category == "plants" then
			local base = PlantInfo.BaseIncome(g.items[1].speciesId, g.items[1].tier, true) or 0
			if base > lastIncome then
				incomeOk = false
			end
			lastIncome = base
		end
	end
	check(incomeOk and income[1].category == "plants" and income[#income].category == "tickets",
		"Income: plants best earner first, then pods, equipment, tickets", names(income))

	local rarity = groups("rarity")
	local falling, last, seenNone = true, math.huge, false
	for _, g in ipairs(rarity) do
		local t = if g.face.rarity then TIER[g.face.rarity] else 0
		if t > last then
			falling = false
		end
		if t == 0 then
			seenNone = true
		end
		last = t
	end
	check(falling and seenNone, "Rarity: rarest first across every category; what shows no rarity after them all",
		names(rarity))
	check(rarity[1].face.name == "Gloomlotus" and rarity[2].face.name == "Comet Bat",
		"two Mythics: the plant before the bat (category breaks a tie)", names(rarity))
	local podAt, commonAt = 0, 0
	for i, g in ipairs(rarity) do
		if g.category == "pods" then
			podAt = i
		elseif g.face.rarity == "Common" then
			commonAt = math.max(commonAt, i)
		end
	end
	check(podAt > commonAt, "an ordinary pod (its shell says nothing) after every Common", names(rarity))

	local newest = groups("newest")
	local plantsNewest, equip = {}, {}
	for _, g in ipairs(newest) do
		if g.category == "plants" then
			table.insert(plantsNewest, g.items[1].order)
		elseif g.category == "equipment" then
			table.insert(equip, g.face.name)
		end
	end
	check(table.concat(plantsNewest, ",") == "14,13,12,11" and newest[1].category == "plants",
		"Newest: by category, the latest item first", table.concat(plantsNewest, ","))
	check(equip[1] == "Bramblejaw Trap" and equip[2] == "Comet Bat" and equip[3] == "Rootwood Bat"
			and string.find(equip[4] or "", "Trail", 1, true) ~= nil,
		"Newest: equipment, which keeps no date, the dearest first; the trail after them", table.concat(equip, ", "))

	items[1].favourite = true
	local favFirst = true
	for _, mode in ipairs({ "income", "rarity", "newest" }) do
		local list = groups(mode)
		if list[1].face.name ~= "Nubkin" then
			favFirst = false
		end
	end
	check(favFirst, "a favourite (a Common) first in every order")
	items[1].favourite = false

	--==========================================================================
	-- 3. THE HEADERS, ON EVERY LISTED SCREEN
	--==========================================================================
	say("-- the headers --")
	local B = HudLayout.Config.Bag
	local bagBad, plantsBad, dropped = {}, {}, {}
	local cases = {}
	for _, d in ipairs(DESKS) do
		table.insert(cases, { tag = string.format("desk %dx%d", d[1], d[2]), input = screen(d[1], d[2], false, true) })
	end
	for _, d in ipairs(PHONES) do
		table.insert(cases, { tag = string.format("phone %dx%d", d[1], d[2]),
			input = screen(d[1], d[2], true, false, d[3]) })
	end
	local bagTitle = TextService:GetTextSize("Bag", 26, Enum.Font.LuckiestGuy, Vector2.new(1000, 100)).X
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local bag = HudLayout.bag(L, { hotTop = L.namePopup.y, stripHidden = L.touch })
		local shellW = bag.panel.w / bag.scale - OUTLINE * 2
		local s, h, so = HudLayout.bagSearch(bag, shellW, bagTitle + 34, 0, 0)
		if not so or so.w ~= B.SortW or so.y ~= s.y or so.h ~= s.h or so.x < s.x + s.w + 4
			or so.x + so.w + 4 > h.x or s.w < B.SearchMinW then
			table.insert(bagBad, string.format("%s search %d+%d sort %s heart %d", case.tag, s.x, s.w,
				if so then tostring(so.x) .. "+" .. tostring(so.w) else "none", h.x))
		end
		local sv = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		local p = MenuLayout.plantsPanel(sv, OUTLINE)
		local closeX = p.shell.X - p.pad - MenuLayout.Config.Touch
		local row = MenuLayout.plantsHeader(p, titleW("MY PLANTS", p.short, true))
		local sr, tr = row.sort, row.tabs
		if not sr then
			table.insert(dropped, case.tag)
		elseif sr.x < tr.x + tr.w + 4 or sr.x + sr.w > closeX - 4 or (row.count and row.count.x < sr.x + sr.w) then
			table.insert(plantsBad, case.tag)
		end
	end
	check(#bagBad == 0, "the Bag: SORT between the search and the heart, 78 wide, the search still 140 or more",
		table.concat(bagBad, "; "))
	check(#plantsBad == 0 and #dropped == 0,
		"MY PLANTS: SORT after the tabs and before the count, clear of the close, on every listed screen",
		"bad: " .. table.concat(plantsBad, ", ") .. " dropped: " .. table.concat(dropped, ", "))
	local layoutSrc = src(Shared, "MenuLayout")
	check(has(layoutSrc, "{ id = \"sort\", w = P.SortW, drop = 2 },")
			and has(layoutSrc, "{ id = \"count\", w = P.CountW, drop = 1 },"),
		"on a header too narrow for both, the count goes first and SORT stays")

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("-- the wiring --")
	local server = ServerScriptService:FindFirstChild("SeedGameServer")
	local schema = src(server, "ProfileSchema")
	check(has(schema, "BagSort: string,") and has(schema, "PlantsSort: string,")
			and has(schema, "BagSort = GameConfig.Sort.Default,") and has(schema, "PlantsSort = GameConfig.Sort.Default,")
			and has(schema, "p.BagSort = GameConfig.sortOption(raw.BagSort) or GameConfig.Sort.Default")
			and has(schema, "p.PlantsSort = GameConfig.sortOption(raw.PlantsSort) or GameConfig.Sort.Default"),
		"the profile keeps both, Rarity by default; an old save or junk loads as the default")
	local data = src(server, "PlayerDataService")
	local _, publishes = string.gsub(data, "PlayerDataService%.PublishSorts%(player%)", "")
	check(has(data, "function PlayerDataService.PublishSorts(player: Player)")
			and has(data, "function PlayerDataService.SetSort(player: Player, which: any, id: any): boolean")
			and has(data, "not field or GameConfig.sortOption(id) == nil then")
			and publishes >= 3,
		"PlayerDataService stamps both on load and after a reset, and refuses a panel or an order it does not know",
		publishes)
	check(has(data, "BagSort = GameConfig.sortOption(profile.BagSort) or GameConfig.Sort.Default,")
			and has(data, "PlantsSort = GameConfig.sortOption(profile.PlantsSort) or GameConfig.Sort.Default,"),
		"a progress reset keeps them: settings, not progress")
	check(has(data, "if action == GameConfig.Sort.Bag.Action or action == GameConfig.Sort.Plants.Action then")
			and has(data, "if type(payload) == \"string\" and PlayerDataService.SetSort(player, which, payload) then"),
		"each panel's verb on the GameEvent remote: a string, or nothing")
	local panel = src(Shared, "InventoryPanel")
	check(has(panel, "local sortButton = MenuKit.sortButton(shell, 5)")
			and has(panel, "local box, heart, sortAt = HudLayout.bagSearch(bag, shellW, titleWidth, padLeft, padRight)")
			and has(panel, "state.sort = GameConfig.nextSort(state.sort)") and has(panel, "cb.sorted(state.sort)")
			and has(panel, "setSort = setSort,"),
		"the Bag: its SORT button where HudLayout says, stepping and handing the new order on")
	local Client = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local loadout = src(Client, "LoadoutUI")
	check(has(loadout, "remote:FireServer(GameConfig.Sort.Bag.Action, id)")
			and has(loadout, "panel.state.sort)")
			and has(loadout, "player:GetAttributeChangedSignal(GameConfig.Sort.Bag.Attribute):Connect(applyBagSort)")
			and has(loadout, "if id ~= bagSortPending then"),
		"LoadoutUI saves a press, sorts the grid by it, and follows the saved attribute -- never an older echo")
	local garden = src(Client, "GardenUI")
	check(has(garden, "local sortButton = MenuKit.sortButton(body, Z)")
			and has(garden, "return before(a, b, placedOf)") and has(garden, "return before(a, b, itemOf)")
			and has(garden, "channel:FireServer(GameConfig.Sort.Plants.Action, plantsSort)")
			and has(garden, "player:GetAttributeChangedSignal(GameConfig.Sort.Plants.Attribute):Connect(applyPlantsSort)")
			and has(garden, "local sr = row.sort"),
		"MY PLANTS: its SORT in the header row, both tabs in its order, saved and followed the same way")
	check(has(garden, "if plantsSort == \"rarity\" then") and has(garden, "elseif plantsSort == \"newest\" then")
			and has(garden, "return a.kind ~= \"pod\""),
		"MY PLANTS: rarer first, or the newest; the pods stay after the earners, soonest first")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nSortSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
