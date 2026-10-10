--!nocheck
--==============================================================================
-- Steal a Seed :: BagMenuSpec
--
-- THE BAG'S ITEM MENU ON EVERY SCREEN (2026-10-10, the owner's phone
-- screenshot: a pod's menu ran off the bottom of a landscape phone, "Hold in
-- hands" cut in half and WHAT'S INSIDE? gone). Edit mode, by arithmetic and by
-- source:
--
--   1. InventoryPanel.menuFit on every listed screen, for the menus the game
--      opens (a pod's, a held pod's on a slot, a trap's, the longest, one
--      button, none): never past the screen's room; the old one-column menu
--      exactly where it fits; side by side only where it does not; a column
--      scrolls only where even that is too tall, and never under one button
--   2. the owner's own menu (a pod: six lines, five buttons) never scrolls on
--      any listed phone, and every desktop keeps the one column
--   3. InventoryPanel: the two columns, laid out on an open and again whenever
--      the words or the screen change size; a scroll is never a press
--   4. LoadoutUI: a pod already in hand offers "Put away", not "Hold in hands"
--
-- Not here, seen in Play instead: the menu drawn on a forced phone.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local InventoryPanel = require(Shared.InventoryPanel)

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

-- The menu's measures, as InventoryPanel keeps them.
local MENU_W, INNER, SIDE_GAP = 228, 208, 10
local PAD, ROW_GAP, BUTTON, BUTTON_GAP, MARGIN = 18, 4, 44, 4, 8
local function column(count)
	return if count > 0 then count * BUTTON + (count - 1) * BUTTON_GAP else 0
end
-- A sheet's words: the title (15 + 4) and each line (12 + 4), 4 apart.
local function words(lines)
	return 19 + lines * 16 + lines * 4
end

-- The Bag's gui: under the top bar (58), inside a notched phone's safe area.
local TOPBAR = 58
local function guiOf(w, h, inset)
	inset = inset or 0
	return Vector2.new(w - inset * 2, h - TOPBAR - (if inset > 0 then 21 else 0))
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the menu's shape on every listed screen --")
	--==========================================================================
	local screens = {
		{ 1280, 720, false }, { 1366, 768, false }, { 1920, 1080, false }, { 1000, 609, false }, { 860, 700, false },
		{ 700, 400, false }, { 640, 360, true }, { 705, 338, true }, { 772, 360, true }, { 801, 392, true },
		{ 874, 402, true, 62 }, { 896, 414, true, 48 }, { 956, 440, true, 62 }, { 844, 390, true, 47 },
		{ 640, 480, true },
	}
	local menus = {
		{ "a pod", words(5), 5 },
		{ "a held pod on a slot", words(5), 6 },
		{ "a trap", words(8), 4 },
		{ "the longest", words(10), 7 },
		{ "one button", words(2), 1 },
		{ "no buttons", words(2), 0 },
	}
	local inRoom, oldWhereFits, sideOnlyIfNeeded, scrollFloor, ownerNoScroll, desktopOne = {}, {}, {}, {}, {}, {}
	local sides = 0
	for _, s in ipairs(screens) do
		local g = guiOf(s[1], s[2], s[4])
		local roomX, roomY = g.X - 2 * MARGIN, g.Y - 2 * MARGIN
		for _, m in ipairs(menus) do
			local info, count = m[2], m[3]
			local fit = InventoryPanel.menuFit(g, info, count)
			local tag = string.format("%dx%d %s", s[1], s[2], m[1])
			if fit.width > roomX + 1e-6 or fit.height > roomY + 1e-6 then
				table.insert(inRoom, string.format("%s (%gx%g in %gx%g)", tag, fit.width, fit.height, roomX, roomY))
			end
			local gap = if count > 0 then ROW_GAP else 0
			local stacked = PAD + info + gap + column(count)
			if stacked <= roomY then
				if fit.side or fit.width ~= MENU_W or fit.height ~= stacked or fit.infoView ~= info
					or fit.actionsView ~= column(count) then
					table.insert(oldWhereFits, tag)
				end
			elseif not fit.side and MENU_W + SIDE_GAP + INNER <= roomX and count > 0 then
				table.insert(sideOnlyIfNeeded, tag .. " (one column, too tall, though two fit)")
			end
			if fit.side then
				sides += 1
				if stacked <= roomY or fit.width ~= MENU_W + SIDE_GAP + INNER then
					table.insert(sideOnlyIfNeeded, tag)
				end
			end
			if fit.actions ~= column(count) or fit.actionsView > fit.actions + 1e-6 or fit.infoView > info + 1e-6
				or fit.actionsView < math.min(fit.actions, BUTTON) - 1e-6 or fit.infoView < math.min(info, BUTTON) - 1e-6 then
				table.insert(scrollFloor, string.format("%s (info %g of %g, buttons %g of %g)", tag, fit.infoView, info,
					fit.actionsView, fit.actions))
			end
			if s[3] and m[1] == "a pod" and (fit.actionsView ~= fit.actions or fit.infoView ~= info) then
				table.insert(ownerNoScroll, tag)
			end
			if not s[3] and s[1] >= 1280 and fit.side then
				table.insert(desktopOne, tag)
			end
		end
	end
	check(#inRoom == 0, "every menu stays 8 clear of each edge of the Bag's screen", table.concat(inRoom, "; "))
	check(#oldWhereFits == 0, "where one column fits, the menu is the old one exactly: 228 wide, words over buttons, "
		.. "nothing scrolling", table.concat(oldWhereFits, "; "))
	check(#sideOnlyIfNeeded == 0 and sides > 0, "side by side (words left, buttons right) only where one column is "
		.. "too tall, and always then where two fit", table.concat(sideOnlyIfNeeded, "; "))
	check(#scrollFloor == 0, "a column's window is never taller than its content, never under one button's "
		.. "height, and the buttons' column is their own sum", table.concat(scrollFloor, "; "))

	--==========================================================================
	say("-- 2. the owner's own menu --")
	--==========================================================================
	check(#ownerNoScroll == 0, "a pod's menu (six lines, five buttons) shows every word and button on every listed "
		.. "phone, nothing scrolling", table.concat(ownerNoScroll, "; "))
	check(#desktopOne == 0, "every desktop from 1280 x 720 keeps the one column, for every menu",
		table.concat(desktopOne, "; "))
	-- The screenshot's own phone, the shortest listed: side by side.
	local shortest = InventoryPanel.menuFit(guiOf(705, 338), words(5), 5)
	check(shortest.side and shortest.height <= guiOf(705, 338).Y - 2 * MARGIN,
		"on the shortest listed phone the pod's menu stands side by side, inside the screen",
		string.format("side %s, %g tall", tostring(shortest.side), shortest.height))

	--==========================================================================
	say("-- 3. InventoryPanel lays the two columns out --")
	--==========================================================================
	local panel = sourceOf(Shared, "InventoryPanel")
	check(has(panel, 'local menuInfo, infoList = menuColumn("MenuInfo", 1, 4)')
			and has(panel, 'local menuActions = menuColumn("MenuActions", 2, MENU_BUTTON_GAP)')
			and has(panel, "local fit = InventoryPanel.menuFit(gui.AbsoluteSize / k, words, menuCount)")
			and has(panel, 'infoList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitMenu)')
			and has(panel, 'gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitMenu)')
			and has(panel, "placeBeside(menu, anchor, fit.width, fit.height)")
			and has(panel, "\t\tfitMenu()\n\t\ttask.defer(fitMenu)"),
		"the words and the buttons are two columns, fitted on an open and again when the words or the screen resize")
	check(has(panel, "column.ScrollingEnabled = scrolls") and has(panel, "column.ClipsDescendants = scrolls")
			and has(panel, "column.ScrollBarThickness = if scrolls then MENU_BAR else 0")
			and has(panel, "actionsClear.PaddingLeft = UDim.new(0, if scrolls then MENU_CLEAR else 0)"),
		"a column scrolls, clips and shows its bar only while its content is taller; a scrolling column's buttons "
			.. "keep clear of the clip")
	check(has(panel, "local mb = MenuKit.button(menuActions,")
			and has(panel, "MenuKit.tap(b, menuActions, function()")
			and has(panel, "table.insert(menuHolds, holdButton(mb, hold, chosen))")
			and not has(panel, "b.Activated:Connect(chosen)"),
		"the buttons live in their column; a tap presses, the end of a scroll never does; HATCH is still held")
	check(has(panel, "fillLines(menuInfo, spec.title, spec.lines, 83, menu)") and has(panel, "h.gate = gate or parent"),
		"the words live in theirs, a rarity's light still paused by the menu's own Visible")

	--==========================================================================
	say("-- 4. LoadoutUI's hold action --")
	--==========================================================================
	local lo = sourceOf(Scripts, "LoadoutUI")
	check(has(lo, 'label = if held ~= nil and it.tool == held then "Put away" else "Hold in hands" })')
			and has(lo, "elseif id == \"hold\" and ref then\n\t\t\tholdRef(ref)"),
		"a pod already in hand offers Put away (the same press: holdTool puts a held tool away)")
end)

if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nBagMenuSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
