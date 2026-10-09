--!nocheck
--==============================================================================
-- Steal a Seed :: CompactMenusSpec
--
-- The compact Index (Plant Almanac) and Shop (2026-10-03, the owner's
-- redesign), by arithmetic and by their own pure modules:
--
--   1. the panel: between the rails on every listed desktop (clear of every
--      rail button, nothing to cover), the safe area on every listed phone
--      (and then it covers the rail); inside the safe area, never past the
--      on-screen keyboard
--   2. the header: the title, the controls and the close all fit one row --
--      the search and the filter on every listed phone
--   3. the grids: columns from the width and a readable minimum (3-6 Index
--      columns on a landscape phone, more on a desktop; two Shop rows on a
--      phone, three tiles on a desktop), at least one whole row in view
--   4. discovery: a locked card says "???", a search never finds a plant by a
--      name not yet grown, and the filter splits grown from missing
--   5. the catalogue: every configured product once, with its own id, the
--      exact amount in words, the one speed icon, SOON for id 0, Spin Tickets
--      only when allowed, and no price anywhere
--   6. the wiring: the purchase calls, the claim, the rail cover, the admin
--      button stepping aside, and nothing that grants
--
-- Not here, seen in Play instead: the panels on screen, taps, the dropdown,
-- the detail pages, prices from Roblox, a real prompt.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local MenuLayout = require(Shared.MenuLayout)
local AlmanacView = require(Shared.AlmanacView)
local AlmanacData = require(Shared.AlmanacData)
local ShopCatalog = require(Shared.ShopCatalog)
local SeedData = require(Shared.SeedData)
local WheelData = require(Shared.WheelData)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
-- The code without its comments, for the checks that are about what RUNS.
local function code(src)
	return (src:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", ""))
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
local function overlaps(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
local function titleW(text, short, icon)
	local size = if short then 21 else 25
	local iconSize = if short then 24 else 28
	local words = TextService:GetTextSize(text, size, Enum.Font.LuckiestGuy, Vector2.new(4000, 200)).X + 6
	return (if icon then iconSize + 6 else 0) + words
end

local DESKS = { { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 1000, 609 } }
local PHONES = { { 640, 360 }, { 705, 338 }, { 772, 360 }, { 874, 402, 62 }, { 896, 414, 48 }, { 956, 440, 62 },
	{ 844, 390, 47 }, { 1000, 609 } }

local ok, err = pcall(function()
	--==========================================================================
	-- 1-3. EVERY SCREEN
	--==========================================================================
	say("-- the panels, their headers and grids --")
	local cases = {}
	for _, d in ipairs(DESKS) do
		table.insert(cases, { tag = string.format("desk %dx%d", d[1], d[2]), input = screen(d[1], d[2], false, true),
			phone = false })
	end
	for _, d in ipairs(PHONES) do
		table.insert(cases, { tag = string.format("phone %dx%d", d[1], d[2]),
			input = screen(d[1], d[2], true, false, d[3]), phone = true, landscape = d[1] > d[2] })
	end
	local panelProblems, headerProblems, gridProblems = {}, {}, {}
	local indexCols, shopCols = {}, {}
	-- The Shop's one page (2026-10-06): every shelf's count, Spin Tickets too.
	local shopCounts: { number } = {}
	for _, category in ipairs(ShopCatalog.categories(true)) do
		table.insert(shopCounts, #ShopCatalog.entries(category.id))
	end
	-- The Index's one page (2026-10-06): every biome's every plant.
	local indexCounts: { number } = {}
	for _, biome in ipairs(AlmanacView.road()) do
		table.insert(indexCounts, #AlmanacView.shelf(biome.Id))
	end
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local s = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		for _, which in ipairs({ "Index", "Shop" }) do
			local p = if which == "Index" then MenuLayout.indexPanel(s, OUTLINE, indexCounts)
				else MenuLayout.shopPanel(s, OUTLINE, shopCounts)
			local r = p.rect
			local tag = case.tag .. " " .. which
			-- Inside the safe area, 8 off its edges.
			if r.x < 8 or r.y < 8 or r.x + r.w > L.safe.X - 8 or r.y + r.h > L.safe.Y - 8 + 1 then
				table.insert(panelProblems, tag .. " leaves the safe area")
			end
			if case.phone and not p.covers then
				table.insert(panelProblems, tag .. " is a phone panel that does not cover the rail")
			end
			-- A desktop window too small for the desktop's rail is compact (1000 x 609
			-- since 2026-10-09, Garden and the Bag having no room under the rail):
			-- its panels cover the rail as a phone's do.
			if not case.phone and L.compact and not p.covers then
				table.insert(panelProblems, tag .. " is a compact window's panel that does not cover the rail")
			end
			if not case.phone and not L.compact then
				if p.covers then
					table.insert(panelProblems, tag .. " covers the rail on a desktop")
				end
				for _, name in ipairs({ "index", "shop", "settings", "walk", "garden", "bag" }) do
					if L[name] and overlaps(r, L[name]) then
						table.insert(panelProblems, tag .. " overlaps the rail's " .. name)
					end
				end
			end
			-- The header row: everything between the title and the close.
			local b = MenuLayout.blocks(p)
			local closeX = p.shell.X - p.pad - MenuLayout.Config.Touch
			local row
			if which == "Index" then
				row = MenuLayout.indexHeader(p, titleW("Plant Almanac", p.short, true))
				if not row.search then
					row = MenuLayout.indexHeader(p, titleW("Almanac", p.short, true))
				end
				-- One page since 2026-10-06: no biome to choose, so no sidebar and
				-- no dropdown.
				if p.sidebar or row.chooser then
					table.insert(headerProblems, tag .. " still has a biome sidebar or dropdown")
				end
				local need = { "filter" }
				if case.phone then
					table.insert(need, "search")
				end
				for _, id in ipairs(need) do
					local it = row[id]
					if not it then
						table.insert(headerProblems, tag .. " drops its " .. id)
					elseif it.x + it.w > closeX - 4 or it.w < 40 then
						table.insert(headerProblems, string.format("%s %s at %d+%d meets the close at %d", tag, id,
							it.x, it.w, closeX))
					end
				end
			else
				row = MenuLayout.shopHeader(p, titleW("Shop", p.short, false))
				-- One page since 2026-10-06: no category to choose, so no sidebar
				-- and no dropdown.
				if p.sidebar or row.chooser then
					table.insert(headerProblems, tag .. " still has a category sidebar or dropdown")
				end
				if row.odds and row.odds.x + row.odds.w > closeX - 4 then
					table.insert(headerProblems, tag .. " REWARDS & ODDS meets the close")
				end
				if case.phone and not row.odds then
					table.insert(headerProblems, tag .. " has no room for REWARDS & ODDS")
				end
			end
			-- The page: the whole main block for both (2026-10-06). The Index's first
			-- row of cards stands under its biome's heading.
			local main = b.main
			local gridH = if which == "Index" then main.h - (if p.short then MenuLayout.Index.ProgressShort
				else MenuLayout.Index.ProgressTall) - MenuLayout.Index.HeadingGap else main.h
			local cg = if which == "Index" then MenuLayout.indexCards(p, main.w - 5) else MenuLayout.shopCards(p, main.w - 5)
			local minW = if p.short then MenuLayout[which].CardMinShort else MenuLayout[which].CardMinTall
			if cg.cardW < math.min(minW, main.w - 21) then
				table.insert(gridProblems, string.format("%s cards %d wide under the minimum %d", tag, cg.cardW, minW))
			end
			if gridH < cg.cardH + cg.grid.inset * 2 then
				table.insert(gridProblems, string.format("%s shows no whole row (%d tall for %d)", tag, gridH, cg.cardH))
			end
			if which == "Index" then
				indexCols[case.tag] = cg.grid.columns
			else
				shopCols[case.tag] = cg.grid.columns
			end
		end
	end
	check(#panelProblems == 0, "every panel stays in the safe area: between the rails on a desktop, covering the rail on a phone",
		table.concat(panelProblems, "; "))
	check(#headerProblems == 0, "every header row fits between the title and the close (search and filter on every phone)",
		table.concat(headerProblems, "; "))
	check(#gridProblems == 0, "cards never fall under their minimum, and a whole row is always in view",
		table.concat(gridProblems, "; "))
	local bad = {}
	for _, case in ipairs(cases) do
		local ic, sc = indexCols[case.tag], shopCols[case.tag]
		if case.phone and case.landscape and case.tag ~= "phone 1000x609" then
			if ic < 3 or ic > 6 then
				table.insert(bad, case.tag .. " Index " .. ic)
			end
			if sc ~= 2 then
				table.insert(bad, case.tag .. " Shop " .. sc)
			end
		elseif not case.phone and case.tag ~= "desk 1000x609" then
			if ic < 5 then
				table.insert(bad, case.tag .. " Index " .. ic)
			end
			if sc < 3 then
				table.insert(bad, case.tag .. " Shop " .. sc)
			end
		end
	end
	local summary = {}
	for _, case in ipairs(cases) do
		table.insert(summary, string.format("%s %d/%d", case.tag, indexCols[case.tag], shopCols[case.tag]))
	end
	check(#bad == 0, "Index 3-6 columns on a landscape phone and 5+ on a desktop; Shop two on a phone, three+ on a desktop",
		table.concat(bad, "; "))
	say("  note  columns (Index/Shop): " .. table.concat(summary, ", "))

	-- MY PLANTS (2026-10-04): every screen -- the tabs and the close in the
	-- header, the four footer pieces side by side, a whole row of cards above
	-- them, and readable columns.
	do
		local problems, cols = {}, {}
		for _, case in ipairs(cases) do
			local L = HudLayout.solve(case.input)
			local s = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
			local p = MenuLayout.plantsPanel(s, OUTLINE)
			local r = p.rect
			local P = MenuLayout.Plants
			if r.x < 8 or r.y < 8 or r.x + r.w > L.safe.X - 8 or r.y + r.h > L.safe.Y - 7 or p.sidebar then
				table.insert(problems, case.tag .. " panel")
			end
			local closeX = p.shell.X - p.pad - MenuLayout.Config.Touch
			local row = MenuLayout.plantsHeader(p, titleW("MY PLANTS", p.short, true))
			if not row.tabs or row.tabs.x + row.tabs.w > closeX - 4 then
				table.insert(problems, case.tag .. " tabs")
			end
			local main = MenuLayout.blocks(p).main
			local foot = MenuLayout.plantsFooter(main.w)
			for _, id in ipairs({ "income", "action", "best", "clear" }) do
				local it = foot[id]
				if not it or it.x + it.w > main.w + 0.5 then
					table.insert(problems, case.tag .. " footer " .. id)
				end
			end
			local cg = MenuLayout.plantsCards(p, main.w - 5)
			local gridH = main.h - P.FooterH - MenuLayout.Config.Gap
			if gridH < cg.cardH + cg.grid.inset * 2 then
				table.insert(problems, string.format("%s no whole row (%d for %d)", case.tag, gridH, cg.cardH))
			end
			table.insert(cols, case.tag .. " " .. cg.grid.columns)
		end
		check(#problems == 0, "MY PLANTS fits every listed screen: header, footer outside the scroll, a whole row of cards",
			table.concat(problems, "; "))
		say("  note  MY PLANTS columns: " .. table.concat(cols, ", "))
	end

	-- A desktop panel ends where its content does, its sidebar still whole; a
	-- phone's takes the whole height.
	do
		local desk = HudLayout.solve(screen(1280, 720, false, true))
		local ds = { safe = desk.safe, compact = desk.compact, railRight = desk.railRight, rightLeft = desk.rightLeft }
		local phone = HudLayout.solve(screen(772, 360, true, false))
		local ps = { safe = phone.safe, compact = phone.compact, railRight = phone.railRight, rightLeft = phone.rightLeft }
		local roadCounts: { number } = {}
		for _, biome in ipairs(AlmanacView.road()) do
			table.insert(roadCounts, #AlmanacView.shelf(biome.Id))
		end
		local di, dsh = MenuLayout.indexPanel(ds, OUTLINE, { 5 }), MenuLayout.shopPanel(ds, OUTLINE, { 6 })
		local pi = MenuLayout.indexPanel(ps, OUTLINE, roadCounts)
		local wholeIndex = MenuLayout.indexPanel(ds, OUTLINE, roadCounts)
		local wholeCards = MenuLayout.indexCards(wholeIndex, MenuLayout.blocks(wholeIndex).main.w - 5)
		-- The Shop's page (2026-10-06): one shelf of six is a short panel; the
		-- whole shop is taller than MaxH, so the panel stops there and scrolls.
		local whole: { number } = {}
		for _, category in ipairs(ShopCatalog.categories(true)) do
			table.insert(whole, #ShopCatalog.entries(category.id))
		end
		local full = MenuLayout.shopPanel(ds, OUTLINE, whole)
		local fullCards = MenuLayout.shopCards(full, MenuLayout.blocks(full).main.w - 5)
		check(not di.sidebar and not dsh.sidebar and not full.sidebar and not wholeIndex.sidebar
				and di.rect.h < MenuLayout.Index.MaxH and dsh.rect.h < MenuLayout.Shop.MaxH
				and full.rect.h <= MenuLayout.Shop.MaxH and wholeIndex.rect.h <= MenuLayout.Index.MaxH
				and (full.rect.h == MenuLayout.Shop.MaxH
					or MenuLayout.shopPageHeight(fullCards, whole) <= MenuLayout.blocks(full).main.h)
				and (wholeIndex.rect.h == MenuLayout.Index.MaxH
					or MenuLayout.indexPageHeight(wholeIndex, wholeCards, roadCounts) <= MenuLayout.blocks(wholeIndex).main.h)
				and pi.rect.h >= phone.safe.Y - 16,
			"a desktop panel ends where its content does (the Index and the Shop are one page each, as tall as all of "
				.. "it up to MaxH, no sidebar); a phone panel takes the whole height",
			string.format("desk index %d (all %d), shop %d (all %d); phone %d of %d", di.rect.h, wholeIndex.rect.h,
				dsh.rect.h, full.rect.h, pi.rect.h, phone.safe.Y))
	end

	-- The keyboard: a panel never reaches under it.
	do
		local L = HudLayout.solve(screen(772, 360, true, false))
		local p = MenuLayout.panel({ safe = L.safe, compact = true, railRight = L.railRight, rightLeft = L.rightLeft,
			keyboardTop = 180 }, MenuLayout.Index.MaxW, MenuLayout.Index.MaxH, OUTLINE)
		check(p.rect.y + p.rect.h <= 172 and p.rect.h >= 120 and p.header == MenuLayout.Config.HeaderShort,
			"with the keyboard up the panel ends above it, its header row still there", p.rect.y + p.rect.h)
	end

	-- pack: drops by rank, grows within its caps.
	do
		local row = MenuLayout.pack(0, 300, 6, {
			{ id = "a", w = 100 }, { id = "b", grow = true, minW = 50, maxW = 80 }, { id = "c", w = 120, drop = 1 },
		})
		local row2 = MenuLayout.pack(0, 200, 6, {
			{ id = "a", w = 100 }, { id = "b", grow = true, minW = 50, maxW = 80 }, { id = "c", w = 120, drop = 1 },
		})
		check(row.a.x == 0 and row.b.w == 68 and row.c and row.c.x == 180 and row2.c == nil and row2.b.w == 80,
			"MenuLayout.pack places, grows to its caps and drops the lowest rank first")
	end

	--==========================================================================
	-- 4. DISCOVERY
	--==========================================================================
	say("\n-- the almanac's discovery rules --")
	local none = {}
	local hidden = true
	local namedNothing = true
	for _, s in ipairs(SeedData.Species) do
		if AlmanacView.face(s, false).name ~= "???" then
			hidden = false
		end
		local list = AlmanacView.list(none, s.Biome, "all", string.lower(s.Name))
		for _, e in ipairs(list) do
			if e.species.Id == s.Id then
				namedNothing = false
			end
		end
	end
	check(hidden, "a locked card's name is ??? for every species; its rarity stays on it")
	check(namedNothing, "searching any plant's own name finds nothing until it has been grown")
	local grownOne = { nubkin = true }
	local found = AlmanacView.list(grownOne, "starbloom", "all", "nub")
	check(#found == 1 and found[1].species.Id == "nubkin" and found[1].known,
		"a grown plant is found by name, from any biome")
	local commons = AlmanacView.list(none, "greenhollow", "all", "common")
	local allCommon = #commons > 0
	for _, e in ipairs(commons) do
		allCommon = allCommon and string.find(string.lower(e.species.Rarity), "common", 1, true) ~= nil and not e.known
	end
	check(allCommon, "a rarity word finds the cards that show it, locked or not, and nothing else")
	local shelf = AlmanacData.SpeciesIn("greenhollow")
	local listed = AlmanacView.list(grownOne, "greenhollow", "all", "")
	local same = #listed == #shelf
	for i, e in ipairs(listed) do
		same = same and e.species.Id == shelf[i].Id
	end
	local grown = AlmanacView.list(grownOne, "greenhollow", "grown", "")
	local missing = AlmanacView.list(grownOne, "greenhollow", "missing", "")
	check(same and #grown == 1 and grown[1].species.Id == "nubkin" and #missing == #shelf - 1,
		"a biome lists its shelf in AlmanacData's order; Grown and Missing split it")
	local _, isSearch = AlmanacView.list(none, "greenhollow", "all", "   ")
	check(not isSearch and AlmanacView.normalise("  NuB ") == "nub", "blank words are no search; case and spaces do not count")
	local everyBiome = true
	for _, biome in ipairs(AlmanacData.Biomes()) do
		local list = AlmanacView.list(none, biome.Id, "all", "")
		everyBiome = everyBiome and #list == #AlmanacData.SpeciesIn(biome.Id) and #list > 0
	end
	check(everyBiome and #AlmanacView.road() == #AlmanacData.Biomes() and AlmanacView.road()[#AlmanacView.road()].Id == "starbloom",
		"every biome is reachable, Starbloom last, each with its whole shelf")

	--==========================================================================
	-- 5. THE CATALOGUE
	--==========================================================================
	say("\n-- the shop's catalogue --")
	local cats = ShopCatalog.categories(false)
	local catsPaid = ShopCatalog.categories(true)
	local sections = GameConfig.Store.Sections
	local order = #cats == #sections
	for i, spec in ipairs(sections) do
		order = order and cats[i] and cats[i].id == spec.id
	end
	check(order and #catsPaid == #sections + 1 and catsPaid[#catsPaid].id == ShopCatalog.TicketsId,
		"one category per configured shelf in its order, Spin Tickets after them only when allowed")
	local headings = {}
	for i, spec in ipairs(sections) do
		headings[i] = cats[i].label .. "<" .. spec.heading
	end
	check(cats[4] and cats[4].label == "???", "the owner's ??? heading is kept as it is", table.concat(headings, ", "))
	local seen, missingIds, kinds = {}, {}, true
	for _, spec in ipairs(sections) do
		local items = GameConfig.Store.Items[spec.id] or {}
		local entries = ShopCatalog.entries(spec.id)
		for _, item in ipairs(items) do
			local hit = nil
			for _, e in ipairs(entries) do
				if e.key == item.key then
					hit = e
				end
			end
			local id = tonumber(if spec.layout == "pass" then item.pass else item.product) or 0
			if not hit or hit.id ~= id or seen[item.key] then
				table.insert(missingIds, tostring(item.key))
			else
				seen[item.key] = true
				local want = if id <= 0 then "soon" elseif spec.layout == "pass" then "pass" else "product"
				kinds = kinds and hit.kind == want
			end
		end
	end
	check(#missingIds == 0 and kinds, "every configured product appears once with its own id; id 0 reads SOON",
		table.concat(missingIds, ", "))
	local spins = ShopCatalog.entries(ShopCatalog.TicketsId)
	local spinOk = #spins == #WheelData.Products
	for i, product in ipairs(WheelData.Products) do
		spinOk = spinOk and spins[i].kind == "spin" and spins[i].spinKey == product.key and spins[i].id == product.productId
	end
	check(spinOk, "the Spin Ticket cards are WheelData's packs, sent to the server by key")
	local speed = ShopCatalog.entries("Speed")
	local cash = ShopCatalog.entries("Cash")
	local icons = #speed > 0
	for _, e in ipairs(speed) do
		icons = icons and e.icon == GameConfig.SourceIcons.speed and e.fallback == GameConfig.Store.Icons[e.key]
	end
	for _, e in ipairs(cash) do
		icons = icons and e.icon == GameConfig.Store.Icons[e.key]
	end
	check(icons and catsPaid[2].icon == GameConfig.SourceIcons.speed,
		"every Speed card and the category wear the catalogue's one speed icon; cash its own packs")
	check(speed[1].benefit == "Adds 150,000 Speed" and cash[1].benefit == "Adds $24,000 cash"
			and ShopCatalog.group(1e9) == "1,000,000,000",
		"the exact amount in words", speed[1].benefit .. " / " .. cash[1].benefit)
	local catSrc = sourceOf(Shared, "ShopCatalog")
	check(not has(code(catSrc), ".robux") and not has(code(catSrc), "MarketplaceService"),
		"the catalogue carries no price and opens no prompt")

	--==========================================================================
	-- 6. THE WIRING
	--==========================================================================
	say("\n-- the wiring --")
	local shop = sourceOf(Scripts, "ShopUI")
	local index = sourceOf(Scripts, "IndexUI")
	local kit = sourceOf(Shared, "UIKit")
	local admin = sourceOf(ServerScriptService, "AdminConsoleUI")
	check(has(shop, "MarketplaceService:PromptGamePassPurchase(player, entry.id)")
			and has(shop, "MarketplaceService:PromptProductPurchase(player, entry.id)")
			and has(shop, "channel:FireServer(WheelData.Actions.Buy, entry.spinKey)")
			and not has(code(shop), "ProcessReceipt") and not has(code(shop), ".robux"),
		"Shop: a pass prompts a pass, a product a product, a spin pack asks the server; no receipt, no list price")
	check(has(shop, "if busy then") and has(shop, "PromptProductPurchaseFinished") and has(shop, "PromptGamePassPurchaseFinished")
			and has(shop, "task.delay(PROMPT_PATIENCE"),
		"one purchase prompt at a time: the buttons wait until it closes (or a timeout frees them)")
	check(has(shop, "UserOwnsGamePassAsync") and has(shop, "OWNED") and has(shop, 'price.Text = "SOON"')
			and has(shop, "price.Text = PRICE_OFF_SALE"),
		"Shop: owned, SOON and OFF SALE faces")
	check(has(shop, "player:SetAttribute(WheelData.OpenOddsAttribute, os.clock())") and has(shop, "REWARDS & ODDS"),
		"REWARDS & ODDS opens the wheel's odds sheet, before any Spin Ticket purchase")
	check(has(index, "channel:FireServer(ALMANAC.ClaimAction, biomeId)") and has(index, "HatchRoll.sealedSpecies(player)")
			and has(index, "AlmanacView.face("),
		"Index: CLAIM asks the server; a first discovery waits for its reveal; names through AlmanacView")
	local plainNames = 0
	for line in string.gmatch(index, "[^\n]+") do
		if has(line, "species.Name") then
			plainNames += 1
		end
	end
	check(plainNames == 0, "IndexUI never prints a species' name except through AlmanacView.face", plainNames)
	local processReceipts = 0
	for _, d in ipairs(ServerScriptService:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			local okSrc, src = pcall(function()
				return (d :: any).Source
			end)
			src = if okSrc and type(src) == "string" then src else ""
			for _ in string.gmatch(src, "ProcessReceipt%s*=") do
				processReceipts += 1
			end
		end
	end
	check(processReceipts == 1, "still exactly one ProcessReceipt in the server", processReceipts)
	check(has(kit, "function UIKit.coverRail(") and has(kit, "local RAIL_COVERED_ORDER = 29")
			and has(kit, "layer.DisplayOrder = if covered then RAIL_COVERED_ORDER else 40")
			and has(index, "UIKit.coverRail(playerGui, PANEL_NAME, panelOpen and p.covers)")
			and has(shop, "UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)"),
		"a covering panel puts the rail layer under the panels' dimmers while open, and back at 40 when the last one shuts")
	check(has(admin, 'button.Visible = railLayer:GetAttribute("Covered") ~= true')
			and has(admin, 'railLayer:GetAttributeChangedSignal("Covered"):Connect(place)'),
		"the admin button steps aside while a menu covers the rail, and comes back")
	check(has(index, 'local PANEL_NAME = "Index"') and has(shop, 'local PANEL_NAME = "Shop"')
			and has(index, "player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)") and has(shop, "player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)"),
		"one panel at a time: both still take turns through OpenPanel under their old names")
	check(has(index, "MenuKit.bindBumpers(\"SeedIndexPad\", stepBiome)") and has(shop, "MenuKit.bindBumpers(\"SeedShopPad\", stepCategory)")
			and has(index, "MenuKit.bindBack(backName, closeDetail)") and has(shop, "MenuKit.bindBack(backName, closeDetail)"),
		"a controller: LB/RB step biomes or categories; B leaves a detail page before it closes the panel")
	local kitSrc = sourceOf(Shared, "MenuKit")
	check(has(kitSrc, 'if state == "scroll" then') and has(kitSrc, "PressGesture.begin("),
		"a finger that scrolls a list presses nothing in it")

	-- The biome pictures (2026-10-04): one mapping, by stable id, every biome.
	local icons = GameConfig.Almanac.BiomeIcons
	local allIcons = type(icons) == "table"
	for _, biome in ipairs(AlmanacData.Biomes()) do
		allIcons = allIcons and type(icons[biome.Id]) == "string" and string.match(icons[biome.Id], "^rbxassetid://%d+$") ~= nil
	end
	check(allIcons and GameConfig.Almanac.TabIcons == nil,
		"every biome has its uploaded picture in GameConfig.Almanac.BiomeIcons; the emoji table is gone")
	local emoji = { "\u{1F331}", "\u{1F3DC}", "\u{1F344}", "\u{1F30B}", "\u{2728}" }
	local noEmoji = true
	for _, e in ipairs(emoji) do
		noEmoji = noEmoji and not has(code(index), e)
	end
	check(noEmoji and has(index, "local image = BIOME_ICONS[biome.Id]")
			and has(index, "local pic = MenuKit.picture(heading, image, nil, Z + 3)")
			and has(index, "biomeIcon, biomeIconFor = biomePicture(biomeRow, biomeIcon, biomeIconFor, biomeId)")
			and has(index, "MenuKit.picture(face, BIOME_ICONS[species.Biome]"),
		"the Almanac draws the biome pictures on every biome's heading on its one page, the detail and search cards")
	check(has(kitSrc, "pic.ScaleType = Enum.ScaleType.Fit") and has(kitSrc, "pic.Active = false")
			and has(kitSrc, "pic.BackgroundTransparency = 1")
			and has(kitSrc, 'warn("[Seed/MenuKit] a picture did not load: " .. pic.Image'),
		"a picture is Fit, on no plate, never takes a press, and one that never loads is reported by id")

	--==========================================================================
	-- 7. THE ADMIN CONSOLE (redesigned 2026-10-07: tabs, one target bar, a log)
	--
	-- Its arithmetic is AdminConsoleSpec's -- every listed screen, every button's
	-- payload, the amount box. Here: that it keeps the compact menus' rules.
	--==========================================================================
	say("\n-- the admin console --")
	local console = sourceOf(ServerScriptService, "AdminConsoleUI")
	local service = sourceOf(ServerScriptService, "AdminService")
	local model = sourceOf(ServerScriptService, "ConsoleModel")
	check(has(console, "local L = Model.layout({") and has(model, "local p = MenuLayout.panel(s, M.MaxW, M.MaxH, outline)")
			and has(console, "menu.place(L.panel)"),
		"it stands where ConsoleModel puts it, on MenuLayout's panel (AdminConsoleSpec checks every screen)")
	check(not has(code(console), "UIKit.menuGui(") and not has(code(console), 'Instance.new("UIScale")')
			and has(console, "keyboardTop = keyboardTop(),") and has(console, "deck.IgnoreGuiInset = false"),
		"no UIScale shrinks it: it is laid out in the safe area itself, and above the keyboard")
	-- Its tabs, in the owner's order.
	check(has(model, '{ id = "player", label = "PLAYER" },\n\t{ id = "spawn", label = "SPAWN" },\n'
			.. '\t{ id = "world", label = "WORLD" },\n\t{ id = "announce", label = "ANNOUNCE" },'),
		"four tabs in order -- PLAYER, SPAWN, WORLD, ANNOUNCE")
	-- Every command the server takes, still asked for: nothing dropped.
	local actionBlock = string.match(service, "local ACTIONS: { %[string%]: boolean } = {(.-)\n}") or ""
	local actions = {}
	for name in string.gmatch(actionBlock, "\n\t(%u%a+) = true,") do
		table.insert(actions, name)
	end
	local BUILDER = { AddMoney = "addMoney", AddSpeed = "addSpeed", ResetPlayerProgress = "reset",
		StartNight = "startNight", StartDay = "startDay", Announce = "announce", Spawn = "spawn",
		Weather = "weather", MiniEvent = "miniEvent" }
	local missing = {}
	for _, action in ipairs(actions) do
		local builder = BUILDER[action]
		local asked = builder ~= nil and has(console, "Model.args." .. builder .. "(")
			and has(model, 'args("' .. action .. '"')
		if not asked then
			table.insert(missing, action)
		end
	end
	check(#actions == 9 and #missing == 0, "every one of the server's nine actions is reachable from the console",
		table.concat(actions, ",") .. " | missing: " .. table.concat(missing, ","))
	-- One handler per control: no duplicate connections.
	local doubled = {}
	for control in string.gmatch(console, "\n(ui%.[%w]+)%.hit%.Activated:Connect%(") do
		local pattern = "\n" .. string.gsub(control, "%.", "%%.") .. "%.hit%.Activated:Connect%("
		local _, n = string.gsub(console, pattern, "")
		if n ~= 1 then
			table.insert(doubled, control .. " x" .. n)
		end
	end
	check(#doubled == 0, "every control has exactly one handler", table.concat(doubled, ", "))
	-- Switching tabs starts and clears nothing; a question left open on the last tab goes with it.
	local setTab = string.match(console, "\nlocal function setTab%(id: string%)(.-)\nend\n") or ""
	check(setTab ~= "" and not has(setTab, "InvokeServer") and not has(setTab, "send(") and not has(setTab, ".Text = ")
			and has(setTab, "setAsking(nil, nil)"),
		"choosing a tab only shows it: no request, no text cleared; a question left open on the tab it left is closed")
	-- The states: pending, restricted, unavailable.
	-- The weather is every admin's since 2026-10-07: nothing about the owner is on the gui any more.
	check(not has(service, 'gui:SetAttribute("IsOwner"')
			and has(service, 'gui:SetAttribute("Spawning", AdminService.Config.Spawning == true)')
			and has(console, 'Model.sections("world")') and has(console, 'word = "\u{2026}"')
			and has(console, 'word = "SPAWNING IS OFF"'),
		"the weather shown to every admin, \"\u{2026}\" while a request is on its way, SPAWN locked while the "
			.. "server's switch is off; the server still decides every press")
	check(has(console, '"MINI EVENTS \\u{00B7} EVERY SERVER"') and has(console, '"WEATHER \\u{00B7} THIS SERVER"')
			and has(console, '"SEND TO ALL SERVERS" else "SEND TO THIS SERVER"')
			and has(console, '"TARGET: %s (@%s, UserId %d)%s"') and has(model, '" -> " .. (targetName or "you")')
			and has(console, '"DAY & NIGHT \\u{00B7} WHOLE SERVER"'),
		"each action says whom it reaches: every server, this server, the target bar's player, you, everyone here")
	check(has(console, 'face(ui.endMini, "danger")') and has(console, 'ui.startMini.style("go")')
			and has(console, 'ui.send.style("done")') and has(console, 'lockable(ui.resetButton, match and not state.busy, "danger"'),
		"START, END and SEND look different: green, red, gold; the reset red")
end)

if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nCompactMenusSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
