--!nocheck
--==============================================================================
-- Steal a Seed :: BagMenuSpec
--
-- THE BAG'S ITEM MENU ON EVERY SCREEN (2026-10-10, the owner's phone
-- screenshot: a pod's menu ran off the bottom of a landscape phone, "Hold in
-- hands" cut in half and WHAT'S INSIDE? gone; the owner's call: shrink it to
-- fit). Edit mode, by arithmetic and by source:
--
--   1. InventoryPanel.menuFit on every listed screen, for the menus the game
--      opens (a pod's, a held pod's on a slot, a trap's, one button, none) and
--      a longer one than any: never past the screen's room; the old menu
--      exactly, at full size, where it fits; smaller only where it does not,
--      and only as much as needed, never under half; a part scrolls only at
--      half size, and never under one button
--   2. the owner's own menu (a pod: six lines, five buttons) and every menu the
--      game opens fit every listed phone without scrolling; every desktop from
--      1280 x 720 keeps full size
--   3. InventoryPanel: the menu's own UIScale, set on an open and again
--      whenever the words or the screen change size; a scroll is never a
--      press; the rarity word placed by a list, never by TextBounds
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
local MENU_W, PAD, ROW_GAP, BUTTON, BUTTON_GAP, MARGIN, FLOOR = 228, 18, 4, 44, 4, 8, 0.5
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
	say("-- 1. the menu's size on every listed screen --")
	--==========================================================================
	local screens = {
		{ 1280, 720, false }, { 1366, 768, false }, { 1920, 1080, false }, { 1000, 609, false }, { 860, 700, false },
		{ 700, 400, false }, { 640, 360, true }, { 705, 338, true }, { 772, 360, true }, { 801, 392, true },
		{ 874, 402, true, 62 }, { 896, 414, true, 48 }, { 956, 440, true, 62 }, { 844, 390, true, 47 },
		{ 640, 480, true },
	}
	-- name, words, buttons, opened by the game (the last is longer than any).
	local menus = {
		{ "a pod", words(5), 5, true },
		{ "a held pod on a slot", words(5), 6, true },
		{ "a trap", words(8), 4, true },
		{ "one button", words(2), 1, true },
		{ "no buttons", words(2), 0, true },
		{ "longer than any", words(10), 7, false },
	}
	local inRoom, oldWhereFits, asNeeded, parts, gameScrolls, ownerScales, desktopFull = {}, {}, {}, {}, {}, {}, {}
	local shrunk, scrolled = 0, 0
	local smallest, smallestAt = math.huge, ""
	for _, s in ipairs(screens) do
		local g = guiOf(s[1], s[2], s[4])
		local roomX, roomY = g.X - 2 * MARGIN, g.Y - 2 * MARGIN
		for _, m in ipairs(menus) do
			local info, count = m[2], m[3]
			local fit = InventoryPanel.menuFit(g, info, count)
			local tag = string.format("%dx%d %s", s[1], s[2], m[1])
			if fit.width * fit.scale > roomX + 1e-6 or fit.height * fit.scale > roomY + 1e-6 then
				table.insert(inRoom, string.format("%s (%g x %g at %g in %g x %g)", tag, fit.width, fit.height, fit.scale,
					roomX, roomY))
			end
			local whole = PAD + info + (if count > 0 then ROW_GAP else 0) + column(count)
			local scrolls = fit.actionsView < fit.actions or fit.infoView < info
			if whole <= roomY and MENU_W <= roomX then
				if fit.scale ~= 1 or fit.width ~= MENU_W or fit.height ~= whole or scrolls then
					table.insert(oldWhereFits, tag)
				end
			else
				shrunk += 1
				-- Smaller only as far as needed: one step bigger would not fit.
				local stepBigger = math.min(1, fit.scale + 0.01)
				if fit.scale >= 1 or fit.scale < FLOOR or (fit.scale > FLOOR and whole * stepBigger <= roomY) then
					table.insert(asNeeded, string.format("%s (%g)", tag, fit.scale))
				end
			end
			if scrolls then
				scrolled += 1
				if fit.scale > FLOOR then
					table.insert(asNeeded, tag .. " (scrolls above half size)")
				end
			end
			if fit.actions ~= column(count) or fit.actionsView > fit.actions + 1e-6 or fit.infoView > info + 1e-6
				or fit.actionsView < math.min(fit.actions, BUTTON) - 1e-6 or fit.infoView < math.min(info, BUTTON) - 1e-6 then
				table.insert(parts, string.format("%s (words %g of %g, buttons %g of %g)", tag, fit.infoView, info,
					fit.actionsView, fit.actions))
			end
			if m[4] and scrolls then
				table.insert(gameScrolls, tag)
			end
			if s[3] and m[4] and fit.scale < smallest then
				smallest, smallestAt = fit.scale, tag
			end
			if s[3] and m[1] == "a pod" then
				table.insert(ownerScales, string.format("%dx%d %g", s[1], s[2], fit.scale))
			end
			if not s[3] and s[1] >= 1280 and fit.scale ~= 1 then
				table.insert(desktopFull, tag)
			end
		end
	end
	check(#inRoom == 0, "every menu is drawn 8 clear of each edge of the Bag's screen", table.concat(inRoom, "; "))
	check(#oldWhereFits == 0, "where it fits, the menu is the old one exactly: full size, 228 wide, words over "
		.. "buttons, nothing scrolling", table.concat(oldWhereFits, "; "))
	check(#asNeeded == 0 and shrunk > 0, "where it does not, it is drawn smaller by only as much as needed, never "
		.. "under half size, and scrolls only at half size", table.concat(asNeeded, "; "))
	check(#parts == 0 and scrolled > 0, "a part's window is never taller than its content, never under one "
		.. "button's height, and the buttons' part is their own sum", table.concat(parts, "; "))

	--==========================================================================
	say("-- 2. the menus the game opens --")
	--==========================================================================
	check(#gameScrolls == 0, "every menu the game opens shows every word and button on every listed screen, "
		.. "nothing scrolling", table.concat(gameScrolls, "; "))
	say("  the owner's pod menu, drawn at: " .. table.concat(ownerScales, ", "))
	say(string.format("  the smallest on a listed phone: %g (%s)", smallest, smallestAt))
	check(smallest >= 0.6, "no menu the game opens is drawn under 0.6 on a listed phone", smallestAt)
	check(#desktopFull == 0, "every desktop from 1280 x 720 draws every menu at full size", table.concat(desktopFull, "; "))
	local shortest = guiOf(705, 338)
	local fit = InventoryPanel.menuFit(shortest, words(5), 5)
	check(fit.scale < 1 and fit.scale >= 0.7 and fit.height * fit.scale <= shortest.Y - 2 * MARGIN,
		"on the shortest listed phone the owner's pod menu fits, drawn at 0.7", fit.scale)

	--==========================================================================
	say("-- 3. InventoryPanel draws the menu to fit --")
	--==========================================================================
	local panel = sourceOf(Shared, "InventoryPanel")
	check(has(panel, 'local menuScale = Instance.new("UIScale")') and has(panel, "menuScale.Parent = menu")
			and has(panel, "local words = infoList.AbsoluteContentSize.Y / (k * menuScale.Scale)")
			and has(panel, "local fit = InventoryPanel.menuFit(gui.AbsoluteSize / k, words, menuCount)")
			and has(panel, "if fresh or math.abs(fit.scale - menuScale.Scale) >= 0.02 then")
			and has(panel, "placeBeside(menu, anchor, fit.width * drawn, fit.height * drawn)")
			and has(panel, "\t\tfitMenu(true)\n\t\ttask.defer(fitMenu, true)")
			and has(panel, 'infoList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()\n\t\tfitMenu()')
			and has(panel, 'gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()\n\t\tfitMenu(true)')
			and not has(panel, "fit.side"),
		"the menu's own UIScale, set on an open and when the screen resizes, moved by a re-measure only past 0.02")
	check(has(panel, "part.ScrollingEnabled = scrolls") and has(panel, "part.ClipsDescendants = scrolls")
			and has(panel, "part.ScrollBarThickness = if scrolls then MENU_BAR else 0")
			and has(panel, "actionsClear.PaddingLeft = UDim.new(0, if scrolls then MENU_CLEAR else 0)"),
		"a part scrolls, clips and shows its bar only while its content is taller; a scrolling part's buttons keep "
			.. "clear of the clip")
	check(has(panel, "local mb = MenuKit.button(menuActions,")
			and has(panel, "MenuKit.tap(b, menuActions, function()")
			and has(panel, "table.insert(menuHolds, holdButton(mb, hold, chosen))")
			and not has(panel, "b.Activated:Connect(chosen)"),
		"the buttons live in their part; a tap presses, the end of a scroll never does; HATCH is still held")
	check(has(panel, "fillLines(menuInfo, spec.title, spec.lines, 83, menu)") and has(panel, "h.gate = gate or parent")
			and has(panel, "rowList.FillDirection = Enum.FillDirection.Horizontal")
			and not has(panel, "TextBounds.X + 4"),
		"the words live in theirs, a rarity's light paused by the menu's Visible; \"Rarity:\" and its word side by "
			.. "side by a list, which a UIScale never shifts")

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
