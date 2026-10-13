--!nocheck
--==============================================================================
-- Steal a Seed :: AdminConsoleSpec (2026-10-07, the console redesign)
--
-- The ADMIN CONSOLE's own arithmetic and words (AdminService.ConsoleModel) and
-- what its client asks for, by its source -- Edit mode, no Play:
--
--   1. the amount box: 1.5T, 1Qd, 999,999 and the rest worked out EXACTLY;
--      junk refused, each with a line that says why; the limit
--   2. the quick chips and the full-number line
--   3. the tabs: five (EVENTS its own since 2026-10-12), LB / RB wrapping, each
--      one's main button, the target bar on PLAYER and SPAWN only; the weather
--      for every admin account (2026-10-07; the owner's alone before); the
--      duration chips inside their limits; SPAWN's size stepper
--   4. what every button sends: the action and its three words -- the shapes
--      the console sent before the redesign, and SPAWN's request
--   5. the layout on every listed desktop, phone and TV: the panel inside the
--      safe area, every block inside the shell and none over another, SPAWN's
--      grid beside its controls (two columns on the 705 x 338 phone), a whole
--      card row in view, every tab, row and SPAWN a finger's height -- and THE
--      COMPACT CONSOLE (2026-10-12, item 11): every tab's height, worked out
--      row by row, fits the 640 x 360 phone and every desktop and TV with no
--      scroll; the other phones' are said
--   6. the client's source: each button calls its builder, one InvokeServer and
--      no FireServer, the weather drawn from ConsoleModel.sections, B and
--      Escape and the bumpers bound only while open, OpenPanel, no loop; the
--      log strip gone, the fading answer that never takes a press; every
--      confirm with its words and steps as before
--
-- Not here, seen in Play instead: the panel on screen, presses, the pictures.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local MenuLayout = require(Shared.MenuLayout)
local SeedData = require(Shared.SeedData)
local Admin = ServerScriptService.SeedGameServer.AdminService
local Model = require(Admin.ConsoleModel)
local EnchantedMistData = require(Shared.EnchantedMistData)
local SpawnCatalog = require(Admin.SpawnCatalog)

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
local function sourceOf(instance)
	local ok, src = pcall(function()
		return instance.Source
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

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE AMOUNT BOX
	--==========================================================================
	say("-- the amount box --")
	local LIMIT = GameConfig.Save.MaxCash
	local good = {
		{ "1.5T", 1.5e12 }, { "1Qd", 1e15 }, { "999,999", 999999 }, { "1,234,567", 1234567 },
		{ "250K", 250000 }, { "2.5m", 2500000 }, { "1qa", 1e15 }, { "1QD", 1e15 }, { "  1 000 000 ", 1e6 },
		{ "1_000", 1000 }, { "0.5K", 500 }, { "1.0", 1 }, { "1.10T", 1100000000000 }, { "1.1T", 1100000000000 },
		{ "999,999,999,999,999", 999999999999999 }, { "1000000000000000", 1e15 }, { "7", 7 },
		{ "12.345B", 12345000000 }, { "1.000000000000001Qd", nil },
	}
	local exact, wrong = true, {}
	for _, case in ipairs(good) do
		local n = Model.parseAmount(case[1], LIMIT)
		if case[2] == nil then
			if n ~= nil then
				exact = false
				table.insert(wrong, case[1])
			end
		elseif n ~= case[2] or n ~= math.floor(n) then
			exact = false
			table.insert(wrong, case[1] .. " -> " .. tostring(n))
		end
	end
	check(exact, "1.5T, 1Qd, 999,999, 250K, 2.5m, 1qa, spaces, underscores, 0.5K and 1.1T come out exact; "
		.. "1e15 + 1 written as 1.000000000000001Qd is over the limit", table.concat(wrong, ", "))
	local junk = { "", "   ", "abc", "1..5T", "1.5TT", "1e15", "-5", "1,5", "12,3456", "1,234,", ",123", "1,,234",
		"1.5", "inf", "nan", "NaN", "1.5X", "0", "0K", "1.", ".5K", "$100", "1 2 3 x", "0x10", "1.0000001K",
		"12.345678901234B", "10Qd", "1,000Qd" }
	local refused, why, leaked = true, true, {}
	for _, text in ipairs(junk) do
		local n, reason = Model.parseAmount(text, LIMIT)
		if n ~= nil then
			refused = false
			table.insert(leaked, string.format("%q -> %s", text, tostring(n)))
		end
		if type(reason) ~= "string" or reason == "" then
			why = false
		end
	end
	check(refused, "junk is refused: words, two points, two suffixes, scientific, negative, misplaced commas, a "
		.. "fraction left over, NaN, inf, zero, a currency sign, over the limit", table.concat(leaked, ", "))
	check(why, "and each refusal says why in a line")
	local over, overWhy = Model.parseAmount("1,000,000,000,000,001", LIMIT)
	check(over == nil and type(overWhy) == "string" and has(overWhy, "1,000,000,000,000,000"),
		"one over the limit is refused, naming the limit", overWhy)
	check(Model.parseAmount(nil, LIMIT) == nil and Model.parseAmount(5, LIMIT) == nil and Model.parseAmount({}, LIMIT) == nil,
		"anything but words is refused")
	check(Model.commas(1e15) == "1,000,000,000,000,000" and Model.commas(999999) == "999,999" and Model.commas(7) == "7",
		"the full number is written with its commas, exactly", Model.commas(1e15))

	--==========================================================================
	-- 2. THE CHIPS AND THE FULL-NUMBER LINE
	--==========================================================================
	say("\n-- the chips --")
	local chips = Model.chips(1e15)
	local labels = {}
	for _, c in ipairs(chips) do
		table.insert(labels, c.label .. "=" .. Model.commas(c.value))
	end
	check(#chips == 5 and chips[1].value == 1e6 and chips[2].value == 1e9 and chips[3].value == 1e12
			and chips[4].label == "1Qd" and chips[4].value == 1e15 and chips[5].label == "MAX" and chips[5].value == 1e15,
		"1M, 1B, 1T, 1Qd and MAX (the limit itself)", table.concat(labels, " "))
	local small = Model.chips(1e12)
	check(#small == 4 and small[4].label == "MAX" and small[4].value == 1e12 and small[3].value == 1e12,
		"under a lower limit the chips past it are left out and MAX is the limit")
	local line, fine = Model.fullLine("1.5T", 1e15, true)
	local speedLine = Model.fullLine("1.5T", 1e15, false)
	local junkLine, junkFine = Model.fullLine("1.5", 1e15, true)
	check(fine and line == "= $1,500,000,000,000" and speedLine == "= 1,500,000,000,000 Speed" and not junkFine
			and junkLine ~= "",
		"the box shows the full number before anything is sent (money with its $, Speed with its word), or why not",
		line .. " / " .. speedLine .. " / " .. junkLine)

	--==========================================================================
	-- 3. THE TABS
	--==========================================================================
	say("\n-- the tabs --")
	local ids = {}
	for _, tab in ipairs(Model.Tabs) do
		table.insert(ids, tab.id)
	end
	check(table.concat(ids, ",") == "player,spawn,world,mist,events,announce",
		"PLAYER, SPAWN, WORLD, MIST, EVENTS, ANNOUNCE -- the mini events their own tab since 2026-10-12 (item 11), the "
			.. "Enchanted Mist and its tools since item 12", table.concat(ids, ","))
	check(Model.stepTab("player", -1) == "announce" and Model.stepTab("announce", 1) == "player"
			and Model.stepTab("spawn", 1) == "world" and Model.stepTab("world", 1) == "mist"
			and Model.stepTab("mist", 1) == "events" and Model.stepTab("events", -1) == "mist"
			and Model.stepTab("events", 1) == "announce",
		"LB and RB step through them and wrap at both ends")
	-- The weather is every admin's (owner, 2026-10-07): ConsoleModel.sections no
	-- longer asks who is looking, so every console draws the same WORLD tab.
	-- The Enchanted Mist (2026-10-11) likewise, under the weather.
	local world = Model.sections("world")
	check(table.concat(world, ",") == "daynight,weather" and table.concat(Model.sections("events"), ",") == "events"
			and table.concat(Model.sections("mist"), ",") == "mist,around,forplayer",
		"WORLD shows night/day and the weather to every admin account -- the weather is no longer hidden for the two "
			.. "that are not the owner's -- EVENTS the mini events, MIST the Enchanted Mist, around you, for the target",
		table.concat(world, ","))
	local modelSrc = ServerScriptService.SeedGameServer.AdminService.ConsoleModel.Source
	check(string.find(modelSrc, "function ConsoleModel.sections(tabId: string): { string }", 1, true) ~= nil
			and string.find(modelSrc, "isOwner", 1, true) == nil,
		"and ConsoleModel has no notion of an owner left: every tab is the same for every admin account")
	check(Model.MainButton.player == "AddMoney" and Model.MainButton.spawn == "Spawn"
			and Model.MainButton.world == "StartNight" and Model.MainButton.mist == "StartMist"
			and Model.MainButton.events == "StartGlobalEvent"
			and Model.MainButton.announce == "Send",
		"a controller starts on each tab's main button")
	-- THE TARGET BAR ONLY WHERE AN ACTION IS A PLAYER'S (2026-10-12): elsewhere
	-- the page takes its room.
	local targeted = {}
	for _, tab in ipairs(Model.Tabs) do
		if Model.TargetTabs[tab.id] then
			table.insert(targeted, tab.id)
		end
	end
	check(table.concat(targeted, ",") == "player,spawn,mist",
		"the one target picker shows on PLAYER, SPAWN and MIST, the tabs that act on a player", table.concat(targeted, ","))
	-- THE MIST TAB (2026-10-12, item 12): its lengths and a pod's choice.
	check(table.concat(Model.MistSeconds, ",") == "120,300,600"
			and table.find(Model.MistSeconds, EnchantedMistData.Schedule.ActiveSeconds) ~= nil
			and Model.MistSeconds == EnchantedMistData.Schedule.AdminSeconds,
		"an admin's Mist lasts 2, 5 or 10 minutes -- the server's own list, the normal 5 among them")
	local chosen = Model.podChoice("elderbough", 7)
	local secret = Model.podChoice("snarlbloom", 7)
	check(Model.podChoice(nil, 7) == "random" and chosen.species == "elderbough" and chosen.size == 7
			and secret.species == "snarlbloom" and secret.size == nil,
		"a pod's choice: RANDOM, or a creature with its size -- a Secret's never asked")
	check(Model.title(true) == "ADMIN" and Model.title(false) == "ADMIN CONSOLE",
		"the title reads ADMIN on a short screen (room for the five tabs), ADMIN CONSOLE elsewhere")
	-- THE DURATION CHIPS (2026-10-12), in place of the seconds boxes.
	local W, MI = GameConfig.Weather, GameConfig.MiniEvent
	local outOfRange = {}
	for _, s in ipairs(Model.WeatherSeconds) do
		if s < W.MinSeconds or s > W.MaxSeconds or s ~= math.floor(s) then
			table.insert(outOfRange, "weather " .. s)
		end
	end
	for _, s in ipairs(Model.EventSeconds) do
		if s < MI.MinSeconds or s > MI.MaxSeconds or s ~= math.floor(s) then
			table.insert(outOfRange, "event " .. s)
		end
	end
	check(#outOfRange == 0 and table.find(Model.WeatherSeconds, W.DefaultSeconds) ~= nil
			and table.find(Model.EventSeconds, MI.DefaultSeconds) ~= nil
			and table.find(Model.EventSeconds, MI.Modes.podrush.Seconds) ~= nil,
		"the duration chips: every one whole seconds inside its event's limits (the weather's 20..1800, a mini "
			.. "event's 30..300), each default among them, and POD RUSH's own length", table.concat(outOfRange, ", "))
	check(Model.durationLabel(60) == "1 MIN" and Model.durationLabel(90) == "1:30" and Model.durationLabel(180) == "3 MIN"
			and Model.durationLabel(600) == "10 MIN",
		"each chip says its length short: 1 MIN, 1:30, 3 MIN, 10 MIN", Model.durationLabel(90))
	-- SPAWN'S SIZE STEPPER (2026-10-12): only ever to a size the species comes in.
	check(Model.sizeStep({ 1, 3, 7 }, 3, 1) == 7 and Model.sizeStep({ 1, 3, 7 }, 3, -1) == 1
			and Model.sizeStep({ 1, 3, 7 }, 7, 1) == nil and Model.sizeStep({ 1, 3, 7 }, 1, -1) == nil
			and Model.sizeStep({ 7 }, 7, 1) == nil and Model.sizeStep({ 7 }, 7, -1) == nil
			and Model.sizeStep({ 2, 5 }, 1, 1) == 2,
		"the size stepper skips the sizes a species lacks and stops at either end")
	local walkedOff = {}
	for _, species in ipairs(SpawnCatalog.all()) do
		local sizes = SpawnCatalog.sizesOf(species)
		table.sort(sizes)
		local walked, at = { sizes[1] }, sizes[1]
		while true do
			local nextSize = Model.sizeStep(sizes, at, 1)
			if not nextSize then
				break
			end
			table.insert(walked, nextSize)
			at = nextSize
		end
		if table.concat(walked, ",") ~= table.concat(sizes, ",") then
			table.insert(walkedOff, species.Id)
		end
	end
	check(#walkedOff == 0, "stepped up from its smallest, every spawnable species visits exactly the sizes it comes in",
		table.concat(walkedOff, ", "))

	--==========================================================================
	-- 4. WHAT EVERY BUTTON SENDS
	--==========================================================================
	say("\n-- what each button sends --")
	local function shape(a)
		local parts = {}
		for i = 1, 4 do
			local v = a[i]
			table.insert(parts, if type(v) == "table" then "{request}" else tostring(v))
		end
		return table.concat(parts, "|")
	end
	local req = Model.spawnRequest("lanterncap", "pod", 7, 3, "spec-console-0001")
	local cases = {
		{ Model.args.addMoney(5551, 1e15), "AddMoney|5551|" .. tostring(1e15) .. "|nil" },
		{ Model.args.addSpeed(5551, 250000), "AddSpeed|5551|250000|nil" },
		{ Model.args.reset(5551, "SpecTarget"), "ResetPlayerProgress|5551|nil|SpecTarget" },
		{ Model.args.startNight(5551), "StartNight|5551|nil|nil" },
		{ Model.args.startDay(5551), "StartDay|5551|nil|nil" },
		{ Model.args.weather("start", 300), "Weather|start|300|nil" },
		{ Model.args.weather("thunder", 300), "Weather|thunder|300|nil" },
		{ Model.args.weather("end", nil), "Weather|end|nil|nil" },
		{ Model.args.miniEvent("ticketdisco", 600), "MiniEvent|ticketdisco|600|nil" },
		{ Model.args.miniEvent("end", nil), "MiniEvent|end|nil|nil" },
		{ Model.args.mist("start"), "Mist|start|nil|nil" },
		{ Model.args.mist("end"), "Mist|end|nil|nil" },
		{ Model.args.mist("start", 600), "Mist|start|600|nil" },
		{ Model.args.mist("eligible"), "Mist|eligible|nil|nil" },
		{ Model.args.mist("burst"), "Mist|burst|nil|nil" },
		{ Model.args.mist("say", "Hi"), "Mist|say|Hi|nil" },
		{ Model.args.mistBerries(5551, 5), "MistBerries|5551|5|nil" },
		{ Model.args.mistProgress(5551, 7), "MistProgress|5551|7|nil" },
		{ Model.args.mistPod(5551, "random", "SpecTarget"), "MistPod|5551|random|SpecTarget" },
		{ Model.args.mistReady(5551), "MistReady|5551|nil|nil" },
		{ Model.args.announce("all", "Hello", true), "Announce|all|Hello|true" },
		{ Model.args.announce("server", "Hello", false), "Announce|server|Hello|false" },
		{ Model.args.spawn(5551, req, "SpecTarget"), "Spawn|5551|{request}|SpecTarget" },
		{ Model.args.spawn(5551, req, nil), "Spawn|5551|{request}|nil" },
		-- REBIRTHS (2026-10-13, item 9): how many to add; back to 0 behind the username.
		{ Model.args.addRebirths(5551, 5), "AddRebirths|5551|5|nil" },
		{ Model.args.resetRebirths(5551, "SpecTarget"), "ResetRebirths|5551|nil|SpecTarget" },
	}
	local mapped, off = true, {}
	for _, c in ipairs(cases) do
		local got = shape(c[1])
		if got ~= c[2] or c[1].n ~= 4 then
			mapped = false
			table.insert(off, got .. " ~= " .. c[2])
		end
	end
	check(mapped, "each button's action and three words: money, Speed, reset (the typed name), night and day (the "
		.. "target rides along unread, as before), the weather's three verbs, a mini event, an announcement, a spawn",
		table.concat(off, "; "))
	local keys = {}
	for k in pairs(req) do
		table.insert(keys, k)
	end
	table.sort(keys)
	check(table.concat(keys, ",") == "form,quantity,request,size,species" and req.species == "lanterncap"
			and req.form == "pod" and req.size == 7 and req.quantity == 3,
		"a spawn request is exactly AdminService's five fields", table.concat(keys, ","))
	local lantern = SeedData.Get("lanterncap")
	check(Model.preview(lantern, 7, "pod", 3, nil) == "3x Colossal Lanterncap pod -> you"
			and Model.preview(lantern, 7, "pod", 3, "SpecTarget") == "3x Colossal Lanterncap pod -> SpecTarget",
		"the preview line: \"3x Colossal Lanterncap pod -> you\"", Model.preview(lantern, 7, "pod", 3, nil))
	check(Model.giveQuestion(lantern, 7, "pod", 3, "SpecTarget") == "Give 3 Colossal Lanterncap pods to SpecTarget?",
		"the confirm for anybody else names them: \"Give 3 Colossal Lanterncap pods to <name>?\"",
		Model.giveQuestion(lantern, 7, "pod", 3, "SpecTarget"))
	local snarl = SeedData.Get("snarlbloom")
	check(Model.preview(snarl, SeedData.SecretTier, "plant", 1, nil) == "1x Snarlbloom grown plant -> you"
			and Model.defaultSize(snarl, 7) == SeedData.SecretTier,
		"a fixed-size species shows no size word and keeps its one size", Model.preview(snarl, 1, "plant", 1, nil))
	check(Model.quantityMax(21) == 21 and Model.quantityMax(99) == GameConfig.Save.MaxHeld and Model.quantityMax(nil) == 0
			and Model.clampQuantity(30, 21) == 21 and Model.clampQuantity(0, 21) == 1 and Model.clampQuantity(5, 0) == 1,
		"the quantity runs from 1 to the target's free bag room, never past the bag")

	--==========================================================================
	-- 5. THE LAYOUT, ON EVERY SCREEN
	--==========================================================================
	say("\n-- the layout --")
	local OUTLINE = GameConfig.Rail.OutlineThickness
	local TOPBAR, BAR_LEFT = 58, 208
	local function rect(x, y, w, h)
		return { x = x, y = y, w = w, h = h }
	end
	local function screen(w, h, touch, inset)
		inset = inset or 0
		return {
			safe = Vector2.new(w - inset * 2, h - TOPBAR - (if inset > 0 then 21 else 0)),
			touch = touch,
			keyboard = not touch,
			viewport = Vector2.new(w, h),
			topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
			insetTop = TOPBAR,
		}
	end
	local function inside(r, w, h)
		return r.x >= -0.01 and r.y >= -0.01 and r.x + r.w <= w + 0.01 and r.y + r.h <= h + 0.01
	end
	local function overlaps(a, b)
		return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
	end
	local function titleW(short)
		local size = if short then GameConfig.BagLook.TitleSizeShort else GameConfig.BagLook.TitleSize
		return TextService:GetTextSize(Model.title(short), size, Enum.Font.LuckiestGuy, Vector2.new(4000, 200)).X + 8
	end
	local list = {}
	for _, d in ipairs({ { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 2560, 1440 }, { 1000, 609 },
		{ 1024, 600 } }) do
		table.insert(list, { tag = string.format("desk %dx%d", d[1], d[2]), input = screen(d[1], d[2], false) })
	end
	for _, d in ipairs({ { 705, 338 }, { 640, 360 }, { 772, 360 }, { 874, 402, 62 }, { 896, 414, 48 }, { 956, 440, 62 },
		{ 844, 390, 47 }, { 1000, 609 } }) do
		table.insert(list, { tag = string.format("phone %dx%d", d[1], d[2]), input = screen(d[1], d[2], true, d[3]),
			phone = d[1] == 705 and d[2] == 338 })
	end
	for _, t in ipairs({ { 1920, 1080, 0 }, { 1280, 720, 36 }, { 3840, 2160, 0 } }) do
		table.insert(list, { tag = string.format("TV %dx%d", t[1], t[2]), input = HudLayout.tenFootInput({
			safe = Vector2.new(t[1], t[2] - t[3]), touch = false, keyboard = false, viewport = Vector2.new(t[1], t[2]),
			topbar = rect(0, 0, 0, t[3]), insetTop = t[3] }) })
	end
	local panelProblems, blockProblems, spawnProblems, touchProblems = {}, {}, {}, {}
	local fitProblems, tabStripProblems, fit640 = {}, {}, nil
	local MM = Model.Metrics
	local phone
	-- The group chips' widths, as the console measures them (MenuKit.textWidth).
	local chipWidths = {}
	for i, g in ipairs(SpawnCatalog.groups()) do
		chipWidths[i] = math.max(84, TextService:GetTextSize(g.label, 13, Enum.Font.FredokaOne, Vector2.new(4000, 200)).X + 24)
	end
	local chipProblems, wrapped, scrolled = {}, 0, 0
	for _, case in ipairs(list) do
		local L = HudLayout.solve(case.input)
		local s = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		local short = L.safe.Y - 16 < MenuLayout.Config.ShortBelow
		local C = Model.layout(s, OUTLINE, titleW(short), chipWidths)
		local p = C.panel
		-- THE GROUP CHIPS (2026-10-07: the search box hid every group past
		-- EMBERROOT). The search and the chips' strip apart, inside the row; and
		-- every chip either in view, wrapped, or behind arrows that scroll to it.
		local tw, th = C.toolbar.w, C.toolbar.h
		if not inside(C.search, tw, th) or not inside(C.chips, tw, th) or overlaps(C.search, C.chips) then
			table.insert(chipProblems, case.tag .. " search and chips overlap or leave the row")
		end
		if C.chipsWrap then
			wrapped += 1
			local places = Model.chipPlaces(chipWidths, C.chips.w, C.search.h, true)
			for i, at in ipairs(places) do
				if at[1] + chipWidths[i] > C.chips.w + 0.01 or at[2] + C.search.h > C.chips.h + 0.01 then
					table.insert(chipProblems, string.format("%s chip %d outside its rows", case.tag, i))
				end
			end
		else
			scrolled += 1
			local total = -Model.Metrics.ChipGap
			for _, w in ipairs(chipWidths) do
				total += w + Model.Metrics.ChipGap
			end
			if total > C.chips.w and not C.chipArrows then
				table.insert(chipProblems, case.tag .. " hides chips with no arrows")
			end
		end
		local r = p.rect
		if r.x < 8 or r.y < 8 or r.x + r.w > L.safe.X - 8 + 0.01 or r.y + r.h > L.safe.Y - 8 + 1 then
			table.insert(panelProblems, case.tag .. " leaves the safe area")
		end
		local w, h = p.shell.X, p.shell.Y
		local named = { tabs = C.tabs, target = C.target, page = C.page, pageFull = C.pageFull, answer = C.answer }
		for name, b in pairs(named) do
			if not inside(b, w, h) or b.w <= 0 or b.h <= 0 then
				table.insert(blockProblems, string.format("%s %s outside the shell", case.tag, name))
			end
		end
		local order = { "tabs", "target", "page" }
		for i = 1, #order do
			for j = i + 1, #order do
				if overlaps(named[order[i]], named[order[j]]) then
					table.insert(blockProblems, string.format("%s %s overlaps %s", case.tag, order[i], order[j]))
				end
			end
		end
		-- The page without the bar takes the bar's room and no more; the answer's
		-- line stands over the page's foot, inside it.
		if overlaps(C.tabs, C.pageFull) or C.pageFull.y + C.pageFull.h ~= C.page.y + C.page.h
			or C.pageFull.y > C.target.y + 0.01 then
			table.insert(blockProblems, case.tag .. " the page without the bar is not the bar's room and the page's")
		end
		local a = C.answer
		if a.h ~= MM.AnswerH or a.x < C.page.x or a.x + a.w > C.page.x + C.page.w or a.y < C.page.y
			or math.abs((a.y + a.h) - (C.page.y + C.page.h - MM.PagePad)) > 0.01 then
			table.insert(blockProblems, case.tag .. " the answer's line is not over the page's foot")
		end
		-- The tabs between the title and the close.
		local closeX = w - p.pad - MenuLayout.Config.Touch
		if C.tabs.x < p.pad + titleW(p.short) or C.tabs.x + C.tabs.w > closeX then
			table.insert(blockProblems, case.tag .. " tabs under the title or the close")
		end
		-- SPAWN, in the page's own coordinates.
		local pw, ph = C.page.w, C.page.h
		for name, b in pairs({ toolbar = C.toolbar, grid = C.grid, controls = C.controls }) do
			if not inside(b, pw, ph) then
				table.insert(spawnProblems, string.format("%s spawn %s outside the page", case.tag, name))
			end
		end
		if overlaps(C.toolbar, C.grid) or overlaps(C.grid, C.controls) or overlaps(C.toolbar, C.controls) then
			table.insert(spawnProblems, case.tag .. " spawn blocks overlap")
		end
		if C.grid.h < C.cardH then
			table.insert(spawnProblems, string.format("%s: a whole card row is not in view (%d < %d)", case.tag, C.grid.h,
				C.cardH))
		end
		if not C.spawnSplit then
			table.insert(spawnProblems, case.tag .. " stacks the grid over the controls")
		end
		if C.controls.h < (if p.short then 100 else 200) then
			table.insert(spawnProblems, string.format("%s: SPAWN's controls only %d tall", case.tag, C.controls.h))
		end
		-- A finger: the tabs, the target bar, the toolbar -- and on a phone or a
		-- short screen every row of the compact pages a finger's 40 (2026-10-12).
		local touchy = s.compact or p.short
		if C.tabs.h < 44 or C.target.h < 40 or C.toolbar.h < 30 or C.tabW < MM.TabMinShort or C.rowH < MM.RowDesk
			or (touchy and (C.rowH < 40 or C.toolbar.h < 40)) then
			table.insert(touchProblems, string.format("%s has a control below a finger (row %d, toolbar %d)", case.tag,
				C.rowH, C.toolbar.h))
		end
		if C.tabsScroll then
			table.insert(tabStripProblems, case.tag)
		end
		-- THE COMPACT CONSOLE (2026-10-12, item 11): every tab's height, row by
		-- row, against the room its page has -- under the target bar on PLAYER
		-- and SPAWN, in the bar's room too elsewhere; SPAWN's controls column
		-- against its own height.
		local inner = C.page.w - MM.PagePad * 2 - MM.ScrollBar
		local controlsInner = C.controls.w - MM.PagePad * 2 - MM.ScrollBar
		local parts, over = {}, {}
		for _, tab in ipairs(Model.Tabs) do
			local need, room
			if tab.id == "spawn" then
				need, room = Model.pageHeight("spawn", controlsInner, C.rowH), C.controls.h
			else
				need = Model.pageHeight(tab.id, inner, C.rowH, { split = C.playerSplit })
				room = if Model.TargetTabs[tab.id] then C.page.h else C.pageFull.h
			end
			table.insert(parts, string.format("%s %d/%d", string.upper(tab.id), need, room))
			-- MIST may scroll on a phone (the owner, 2026-10-12) -- and on a window
			-- shorter than a 1280 x 720 desktop's: every other tab fits.
			if need > room and not (tab.id == "mist" and (string.sub(case.tag, 1, 5) == "phone" or L.safe.Y < 650)) then
				table.insert(over, string.format("%s +%d", string.upper(tab.id), need - room))
			end
		end
		say(string.format("    %-16s %s%s", case.tag, table.concat(parts, "  "),
			if #over > 0 then "  -> SCROLLS " .. table.concat(over, ", ") else ""))
		-- Every screen at least as tall as the 640 x 360 phone (302 of safe area
		-- under the topbar) fits with no scroll; a shorter one is said above.
		if #over > 0 and L.safe.Y >= 302 - 0.01 then
			table.insert(fitProblems, case.tag .. " " .. table.concat(over, ", "))
		end
		if case.tag == "phone 640x360" then
			fit640 = #over == 0
		end
		if case.phone then
			phone = C
		end
	end
	check(#panelProblems == 0, "the panel stands inside the safe area on " .. #list .. " screens (desks, phones, TVs)",
		table.concat(panelProblems, "; "))
	check(#blockProblems == 0, "the tabs, the target bar and the page each inside the shell, none over another, the "
		.. "tabs between the title and the close; the page without the bar in the bar's room; the answer's line over "
		.. "the page's foot", table.concat(blockProblems, "; "))
	check(#spawnProblems == 0, "SPAWN's toolbar, grid and controls inside the page and apart, the grid beside the "
		.. "controls with a whole row of cards in view", table.concat(spawnProblems, "; "))
	check(#touchProblems == 0, "every tab, the target bar and the toolbar a finger's size, and on every phone and "
		.. "short screen every row and the toolbar 40 tall", table.concat(touchProblems, "; "))
	check(fit640 == true, "THE COMPACT CONSOLE (item 11): on the 640 x 360 phone every tab fits with no scroll -- "
		.. "MIST excepted, its tools too many for a phone (the owner: it may scroll there)")
	check(#fitProblems == 0, "and on every listed desk, phone and TV at least that tall (the heights above; a "
		.. "shorter screen is said, not held to it)", table.concat(fitProblems, "; "))
	check(#tabStripProblems == 0, "every listed screen -- desk, phone, TV -- shows all six tabs beside the title, the "
		.. "strip unscrolled",
		table.concat(tabStripProblems, ", "))
	check(#chipProblems == 0 and wrapped > 0, string.format("every SPAWN group reachable: the search beside or over "
		.. "the chips, never on them; all %d chips in view wrapped (%d screens), else arrows scroll to them (%d screens)",
		#chipWidths, wrapped, scrolled), table.concat(chipProblems, "; "))
	check(phone ~= nil and phone.columns == 2 and phone.panel.short and phone.tabsScroll ~= nil,
		"on the phone's 705 x 338 the spawn grid has two columns", phone and phone.columns)
	check(phone ~= nil and phone.answer.h == MM.AnswerH and phone.rowH == MM.RowTouch and MM.RowTouch >= 40,
		"and there the rows are a finger's 40 and the answer one line over the page's foot -- the log strip is gone")

	--==========================================================================
	-- 6. THE CLIENT, FROM ITS SOURCE
	--==========================================================================
	say("\n-- the client --")
	local src = sourceOf(Admin:FindFirstChild("AdminConsoleUI"))
	local run = code(src)
	check(src ~= "" and has(run, "remote:InvokeServer(a[1], a[2], a[3], a[4])") and not has(run, "FireServer")
			and select(2, string.gsub(run, "InvokeServer%(", "")) == 1,
		"it only ever asks, through one InvokeServer of what ConsoleModel built")
	local builders = { "Model.args.addMoney(", "Model.args.addSpeed(", "Model.args.reset(", "Model.args.startNight(",
		"Model.args.startDay(", "Model.args.weather(", "Model.args.miniEvent(", "Model.args.announce(",
		"Model.args.spawn(", "Model.spawnRequest(", "Model.args.mist(", "Model.args.mistBerries(",
		"Model.args.mistProgress(", "Model.args.mistPod(", "Model.args.mistReady(", "Model.args.addRebirths(",
		"Model.args.resetRebirths(" }
	local missing = {}
	for _, b in ipairs(builders) do
		if not has(run, b) then
			table.insert(missing, b)
		end
	end
	check(#missing == 0, "every button sends through its ConsoleModel builder", table.concat(missing, ", "))
	check(has(run, "Model.sections(\"world\")") and has(run, "ui.weatherSection.Visible")
			and has(run, "ui.mistSection.Visible = table.find(mistShown, \"mist\") ~= nil")
			and not has(run, "isOwner") and not has(run, "IsOwner") and not has(src, "OWNER ONLY"),
		"the weather section is shown from ConsoleModel.sections for every admin -- no owner check, no OWNER ONLY "
			.. "heading, and a press asks the server whoever presses it")
	check(has(run, "Enum.KeyCode.ButtonB") and has(run, "Enum.KeyCode.Escape") and has(run, "Enum.KeyCode.ButtonL1")
			and has(run, "UnbindAction(BACK_ACTION)") and has(run, "UnbindAction(ESC_ACTION)"),
		"B, Escape and the bumpers are bound while open and unbound on close")
	check(has(run, "SetAttribute(ATTR.OpenPanel, PANEL_NAME)") and has(run, "GetAttributeChangedSignal(ATTR.OpenPanel)"),
		"one centre panel at a time: it takes OpenPanel and steps aside for another")
	check(has(run, "HttpService:GenerateGUID(false)") and has(run, "state.unanswered")
			and has(run, "attr(\"SpawnAnswerSeconds\", 300)") and has(run, "attr(\"SpawnCooldown\", 6)"),
		"a spawn press has its own id, resent unchanged after no answer while the server remembers it, and its "
		.. "wait counted down on the button")
	check(has(run, "setAsking(\"give\"") and has(run, "currentTarget().Name") and has(run, "setAsking(\"weather\"")
			and has(run, "setAsking(\"mini\"") and has(run, "setAsking(\"all\"") and has(run, "typedMatches()")
			and has(run, "setAsking(\"mist\", verb)")
			and has(run, "{ { \"StartMist\", \"START MIST NOW\" },")
			and has(run, "{ \"EndMist\", \"END MIST NOW\" } })")
			and has(run, 'task.spawn(send, Model.args.mist(verb, if verb == "start" then secs else nil))'),
		"giving to anybody else, the weather, the Enchanted Mist's START / END MIST NOW, the events and ALL SERVERS "
			.. "ask in place; the reset waits for the name")
	--==========================================================================
	-- THE COMPACT CONSOLE'S CLIENT (2026-10-12, item 11)
	--==========================================================================
	-- THE LOG STRIP IS GONE; THE ANSWER FADES BY ITSELF.
	check(not has(run, "paintLog") and not has(run, "ui.logLines") and not has(run, "state.log")
			and not has(run, 'Name = "Log"') and MM.LogLine == nil and MM.LogLinesShort == nil,
		"the log strip is gone: no strip, no log lines, nothing of it left in the model")
	local noteBody = string.match(run, "\nlocal function note%(text: string, ok: boolean%?%)(.-)\nend\n") or ""
	check(has(noteBody, "task.delay(M.AnswerSeconds, function()") and has(noteBody, "TweenInfo.new(M.AnswerFade)")
			and has(noteBody, "if mine ~= answerSeq then") and has(noteBody, "pill.Visible = false")
			and MM.AnswerSeconds >= 2 and MM.AnswerSeconds <= 4 and MM.AnswerFade > 0 and MM.AnswerFade <= 1,
		"the answer fades by itself: up about three seconds, faded in under one, then gone; a newer answer has its own time",
		string.format("%s s, fade %s s", tostring(MM.AnswerSeconds), tostring(MM.AnswerFade)))
	check(has(noteBody, "if ok == true then GOOD elseif ok == false then BAD else NEUTRAL")
			and has(run, 'note(if type(reply.message) == "string" then reply.message else "No answer.", reply.ok == true)'),
		"in the server's own words: green done, red refused (grey where nothing was asked of anybody)")
	-- THE PEER'S GUARD 1: the answer, over the page's foot, never takes a press.
	local answerBlock = string.match(run, 'local answer = Instance%.new%("Frame"%)(.-)ui%.answer, ui%.answerWords, ui%.answerEdge = ')
		or ""
	check(answerBlock ~= "" and has(answerBlock, "answer.Active = false") and has(answerBlock, "answer.Selectable = false")
			and has(answerBlock, 'local answerWords = Instance.new("TextLabel")')
			and has(answerBlock, "answerWords.Active = false") and has(answerBlock, "answerWords.Selectable = false")
			and not has(answerBlock, "Button") and not has(answerBlock, "TextBox") and not has(answerBlock, "Activated")
			and not has(answerBlock, "Input") and not has(answerBlock, "clicks")
			and not string.find(run, "ui%.answer%w*%.Active = true") and not string.find(run, "ui%.answer%w*[%.:]Input")
			and not string.find(noteBody, "Active") and not string.find(noteBody, "Selectable"),
		"THE ANSWER NEVER TAKES A PRESS: a Frame and a TextLabel, neither Active nor Selectable, no button, box or "
			.. "handler in it, nothing that ever makes it one -- the row under it works the whole time it shows")
	-- THE PEER'S GUARD 2: every confirm as strong as before -- its words and its
	-- steps; only where it stands changed (in its own row's place).
	local function handler(control)
		local escaped = string.gsub(control, "%.", "%%.")
		return string.match(run, "\n" .. escaped .. "%.hit%.Activated:Connect%(function%(%)(.-)\nend%)") or ""
	end
	local function body(name)
		return string.match(run, "\nlocal function " .. name .. "%(verb: string%)(.-)\nend\n") or ""
	end
	-- Whether code asks the server anything: `send` as a word (task.spawn(send, ...)
	-- too), a ConsoleModel request, or the remote itself.
	local function sends(src)
		return string.find(src, "%f[%w_]send%f[^%w_]") ~= nil or has(src, "Model.args.") or has(src, "InvokeServer")
	end
	local askWeatherBody, askMistBody, askMiniBody = body("askWeather"), body("askMist"), body("askMini")
	check(has(handler("ui.startRain"), 'askWeather("start")') and has(handler("ui.startThunder"), 'askWeather("thunder")')
			and has(handler("ui.endRain"), 'askWeather("end")') and not sends(handler("ui.startRain"))
			and not sends(handler("ui.startThunder")) and not sends(handler("ui.endRain"))
			and has(askWeatherBody, '"Stop the weather on this server?"')
			and has(askWeatherBody, '"Start %s on this server for %s?"') and has(askWeatherBody, 'setAsking("weather", verb)')
			and askWeatherBody ~= "" and not sends(askWeatherBody)
			and has(handler("ui.weatherAsk.confirm"), "local secs = state.askSeconds")
			and has(handler("ui.weatherAsk.confirm"), 'Model.args.weather(verb, if verb == "end" then nil else secs)'),
		"THE WEATHER still asks first, in the same words, and CONFIRM sends the very duration it asked about")
	check(has(handler("ui.startMist"), 'askMist("start")') and has(handler("ui.endMist"), 'askMist("end")')
			and has(askMistBody, '"End the Enchanted Mist on this server now?"')
			and has(askMistBody, '"Start an Enchanted Mist on this server now, for %s?"')
			and has(askMistBody, 'setAsking("mist", verb)') and askMistBody ~= "" and not sends(askMistBody)
			and not sends(handler("ui.startMist")) and not sends(handler("ui.endMist"))
			and has(handler("ui.mistAsk.confirm"), "local secs = state.askSeconds")
			and has(handler("ui.mistAsk.confirm"), 'task.spawn(send, Model.args.mist(verb, if verb == "start" then secs else nil))'),
		"THE ENCHANTED MIST still asks first, in the same words -- and starts for the length it asked about")
	check(has(handler("ui.startMini"), "askMini(state.miniMode)") and has(handler("ui.endMini"), 'askMini("end")')
			and has(askMiniBody, '"End the global event on EVERY server?"')
			and has(askMiniBody, '"Start %s on EVERY server for %s?"') and has(askMiniBody, 'setAsking("mini", verb)')
			and askMiniBody ~= "" and not sends(askMiniBody)
			and not sends(handler("ui.startMini")) and not sends(handler("ui.endMini"))
			and has(handler("ui.miniAsk.confirm"), "local secs = state.askSeconds")
			and has(handler("ui.miniAsk.confirm"), 'Model.args.miniEvent(verb, if verb == "end" then nil else secs)'),
		"A GLOBAL MINI EVENT still asks first -- EVERY server, in the same words -- and sends what it asked about")
	local sendHandler = handler("ui.send")
	local _, trues = string.gsub(run, "announce%(true%)", "")
	check(has(sendHandler, 'if state.scope == "all" then') and has(sendHandler, '"Send this to EVERY server of this place?"')
			and has(sendHandler, 'setAsking("all", nil)') and has(sendHandler, "announce(false)")
			and not has(sendHandler, "announce(true)") and has(handler("ui.allAsk.confirm"), "announce(true)") and trues == 1
			and has(run, 'build.question(card, "AllQuestion", "full", "YES, ALL SERVERS")'),
		"ALL SERVERS still asks once more -- YES, ALL SERVERS -- and only that answer sends one")
	local resetHandler = handler("ui.resetButton")
	check(string.find(resetHandler, "^\n\tif state%.busy or not typedMatches%(%) then\n\t\treturn\n\tend") ~= nil
			and has(resetHandler, "task.spawn(send, Model.args.reset(currentTarget().UserId, typed))")
			and has(run, 'return trimmed ~= "" and string.lower(trimmed) == string.lower(currentTarget().Name)')
			and has(run, '"TYPE %s TO CONFIRM"') and has(run, 'lockable(ui.resetButton, match and not state.busy, "danger"')
			and not sends(handler("ui.openReset")) and has(handler("ui.openReset"), "state.resetOpen = true")
			and not sends(handler("ui.closeReset"))
			and has(run, "ui.resetCard.Visible = state.resetOpen"),
		"RESET PROGRESS still waits for the username typed back, locked till it matches -- now behind one red button "
			.. "that only opens its box")
	-- REBIRTHS (2026-10-13, the owner's item 9): the count beside REBIRTHS... in RESET PROGRESS's own row, so a
	-- phone's PLAYER still fits; the card opens under it; +1 and ADD send the count only; SET TO 0 asks first and
	-- its yes sends the target's username.
	local resetRebirth = handler("ui.rebirthReset")
	local rowW, rowH = 500, Model.Metrics.RowTouch
	local closed = Model.pageHeight("player", rowW, rowH, {})
	local opened = Model.pageHeight("player", rowW, rowH, { rebirthOpen = true })
	local cardW = rowW - Model.Metrics.CardPad * 2
	local card = Model.cardHeight({ Model.actionRowHeight(cardW, 2, rowH), Model.actionRowHeight(cardW, 2, rowH) })
	check(has(run, '{ { "OpenRebirths", "REBIRTHS\\u{2026}" },') and has(run, '{ "OpenReset", "RESET PROGRESS\\u{2026}" } }')
			and not sends(handler("ui.openRebirths")) and not sends(handler("ui.closeRebirths"))
			and has(handler("ui.rebirthOne"), "task.spawn(send, Model.args.addRebirths(currentTarget().UserId, 1))")
			and has(handler("ui.rebirthAdd"), 'Model.parseAmount(ui.rebirthBox.Text, attr("MaxRebirths", 1000))')
			and has(resetRebirth, 'setAsking("rebirthreset", nil)') and not sends(resetRebirth)
			and has(handler("ui.rebirthAsk.confirm"), "task.spawn(send, Model.args.resetRebirths(p.UserId, p.Name))")
			and has(run, 'build.question(rCard, "RebirthQuestion", "full", "SET TO 0")')
			and has(run, "GameConfig.rebirthCount(p:GetAttribute(GameConfig.Rebirth.Attributes.Rebirths))")
			and opened == closed + Model.Metrics.RowGap + card,
		"REBIRTHS: the target's count in RESET PROGRESS's row (no taller), the card opening under it; +1 and ADD send "
			.. "the count only, and SET TO 0 asks first, its yes sending the target's username",
		string.format("closed %d, opened %d, card %d", closed, opened, card))
	local beforeAsk = string.match(handler("ui.spawnButton"), "^(.-)setAsking%(\"give\", nil%)") or "send"
	check(has(handler("ui.spawnButton"), "if p ~= player then") and has(handler("ui.spawnButton"), 'setAsking("give", nil)')
			and not sends(beforeAsk)
			and has(handler("ui.giveConfirm"), "task.spawn(spawnNow, currentTarget().Name)"),
		"a give to anybody else still asks first, and GIVE sends their name as the confirm")
	check(has(run, 'local row = build.action(holder, name, scope, { { "Cancel", "CANCEL" }, { "Confirm", yes } })')
			and has(run, 'row.buttons[2].style("danger")') and has(run, "ui.weatherRow.Visible = not weatherAsk")
			and has(run, "ui.mistRow.Visible = not mistAsk") and has(run, "ui.miniRow.Visible = not miniAsk")
			and has(run, "ui.sendRow.Visible = not asking"),
		"each question stands in its own row's place, the same height (nothing under it moves), CONFIRM red")
	-- THE TARGET BAR, THE CHIPS, THE ROWS.
	check(has(run, "local targeted = Model.TargetTabs[state.tab] == true") and has(run, "ui.targetBar.Visible = targeted")
			and has(run, "put(ui.pages, if targeted then L.page else L.pageFull)"),
		"the target bar shows only on PLAYER and SPAWN; elsewhere the page takes its room")
	check(has(run, "rainSeconds = WEATHER.DefaultSeconds,") and has(run, "miniSeconds = MINI.DefaultSeconds,")
			and has(run, "for _, seconds in ipairs(Model.WeatherSeconds) do")
			and has(run, "for _, seconds in ipairs(Model.EventSeconds) do") and has(run, "Model.durationLabel(seconds)")
			and has(run, "state.askSeconds = secs") and not has(run, "rainBox") and not has(run, "miniBox"),
		"the durations are the chips (each starting on its default): the seconds boxes are gone")
	check(has(run, "Model.actionInline(w, n)") and has(run, "Model.actionRowHeight(w, n, rowH)")
			and has(run, "Model.perRow(w, g.min, g.max)") and has(run, "Model.spawnRowHeight(w, rowH)")
			and has(run, "local rowH = L.rowH") and has(run, "fit.MinTextSize = TEXT_MIN") and has(run, "local TEXT_MIN = 10"),
		"the console lays out every row by ConsoleModel's own rules -- the ones pageHeight counts -- at the screen's "
			.. "row height, no word drawn under 10")
	check(not has(run, "while true") and not has(run, "Heartbeat") and not has(run, "RenderStepped"),
		"no loop and no per-frame work: one task.delay chain while it is open")
	check(has(run, "layout.admin") and has(run, "button.Selectable = true"),
		"the ADMIN button is still placed by HudLayout and selectable for a controller")
	check(has(run, "MenuKit.baseplate(") and has(run, "WheelDraw.rainbow(0)") and has(run, "RedKeyline")
			and has(run, "MenuKit.heading("),
		"the look: the studded baseplate, the owner's rainbow badge title, the red keyline, ink-edged headings")
	-- What makes it to the client is only what AdminService gives an admin.
	local catalogSrc = sourceOf(Admin:FindFirstChild("SpawnCatalog"))
	local modelSrc = sourceOf(Admin:FindFirstChild("ConsoleModel"))
	check(catalogSrc ~= "" and modelSrc ~= "" and not has(code(catalogSrc), "Instance.new")
			and not has(code(modelSrc), "Instance.new"),
		"its two modules make no Instance: pure, so this spec is what runs")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nAdminConsoleSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
