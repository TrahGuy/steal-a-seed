--!nocheck
--==============================================================================
-- Steal a Seed :: UpdateLogSpec (2026-10-05, the owner's WHAT'S NEW)
--
-- The owner-editable update log and the rules its panel and button keep, in
-- Edit, with no Play:
--
--   1. THE LIST AS SHIPPED: no rule broken -- ids unique, newest first, every
--      date readable ("5 Oct 2026"), a short title, 2 to 5 bullets each, every
--      bullet one line under BulletMax -- and every word fitting the cards: a
--      bullet at most two lines on the narrowest screen the button stands on and
--      one on a desktop, a title and a date whole; a short log a short panel.
--   2. THE RULES CATCH WHAT THEY SHOULD: a twice-used id, an older entry above
--      a newer one, an unreadable date, one bullet or six, a long or two-line
--      bullet, an empty list -- each reported.
--   3. DATES: the reader's arithmetic against fixed UTC days, leap years, and
--      junk.
--   4. THE NEW DOT BY DATE: on under NewDays after the newest entry's day,
--      off at it and after; an unreadable date never new; only the newest
--      entry decides; and the panel's list is the newest Shown, newest first.
--   5. THE WIRING, read off the source: no remote and no server; the dot
--      cleared when the panel opens this session and never saved; the panel
--      on the OpenPanel mutex, rim-themed and laid out by MenuLayout.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UpdateLog = require(Shared:WaitForChild("UpdateLog"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local C = GameConfig.UpdateLog
local DAY = 86400

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
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
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
local function entry(id, date, bullets, title)
	return { id = id, date = date, title = title or "A title", bullets = bullets or { "One line.", "Two line." } }
end
local function anyHas(list, needle)
	for _, s in ipairs(list) do
		if string.find(s, needle, 1, true) then
			return true
		end
	end
	return false
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the list as shipped --")
	--==========================================================================
	local problems = UpdateLog.problems()
	check(#problems == 0 and #UpdateLog.Entries >= 1, string.format("the %d entries break no rule", #UpdateLog.Entries),
		table.concat(problems, "; "))
	local ids, newestFirst, last = {}, true, math.huge
	for _, e in ipairs(UpdateLog.Entries) do
		ids[e.id] = (ids[e.id] or 0) + 1
		local at = UpdateLog.dayOf(e.date)
		if not at or at > last then
			newestFirst = false
		end
		last = at or last
	end
	local twice = {}
	for id, n in pairs(ids) do
		if n > 1 then
			table.insert(twice, id)
		end
	end
	check(#twice == 0 and newestFirst, "ids unique, and newest first", table.concat(twice, ", "))
	-- The words against the cards they stand on. The NARROWEST is the 430-px
	-- screen, the narrowest HudLayoutSpec lists where the button stands (a 430 x
	-- 500 window and touch screen: 442 px under the topbar); there a bullet may
	-- wrap onto a second line, never a third, and a title and a date stay whole.
	-- A desktop's panel (1280 x 720, between the rails) draws every bullet on one.
	local U = MenuLayout.Updates
	local LOOK = GameConfig.BagLook
	local OUTLINE = GameConfig.Rail.OutlineThickness
	local HUD = HudLayout.solve({ safe = Vector2.new(430, 442), touch = false, keyboard = true,
		viewport = Vector2.new(430, 500), insetTop = 58 })
	check(HUD.compact and HUD.updates.w > 0, "the 430 x 500 window shows the button, so its panel is the narrowest asked")
	local narrow = MenuLayout.updatesPanel({ safe = Vector2.new(430, 442), compact = true, railRight = 0,
		rightLeft = 430 }, OUTLINE)
	local desk = MenuLayout.updatesPanel({ safe = Vector2.new(1280, 662), compact = false, railRight = 142,
		rightLeft = 1218 }, OUTLINE)
	local function size(text, px, font, width)
		return TextService:GetTextSize(text, px, font, Vector2.new(width, 10000))
	end
	local oneLine = size("Xg", U.BulletSize, LOOK.BodyFont, 4000).Y
	local function lines(text, width)
		return math.round(size(text, U.BulletSize, LOOK.BodyFont, width).Y / oneLine)
	end
	local thin, wide = MenuLayout.updateText(narrow), MenuLayout.updateText(desk)
	local over, maxLines, oneDesk = {}, 0, true
	for _, e in ipairs(UpdateLog.Entries) do
		for _, line in ipairs(e.bullets) do
			local n = lines(line, thin)
			maxLines = math.max(maxLines, n)
			if n > 2 then
				table.insert(over, string.format("%q: %d lines at %d px", line, n, thin))
			end
			if lines(line, wide) > 1 then
				oneDesk = false
				table.insert(over, string.format("%q wraps on a desktop (%d px)", line, wide))
			end
		end
	end
	check(#over == 0 and oneDesk and thin > 200,
		string.format("every bullet is at most two lines on the narrowest card (%d px; the most is %d) and one on a "
			.. "desktop's (%d px)", thin, maxLines, wide), table.concat(over, "; "))
	local whole = {}
	local inner = MenuLayout.updateWidth(narrow)
	for i, e in ipairs(UpdateLog.Entries) do
		local titleW = size(e.title, U.TitleSize, LOOK.LabelFont, 4000).X
		local dateW = size(e.date, U.DateSize, LOOK.LabelFont, 4000).X
		local dateRoom = inner - (if i == 1 then U.TagW + U.TagGap else 0)
		if titleW > inner or dateW > dateRoom then
			table.insert(whole, string.format("%s: title %d / %d, date %d / %d", e.id, titleW, inner, dateW, dateRoom))
		end
	end
	local tagWord = math.max(size("NEW", 12, LOOK.LabelFont, 4000).X, size("LATEST", 12, LOOK.LabelFont, 4000).X)
	check(#whole == 0 and tagWord + 8 <= U.TagW and U.TagH <= U.DateH,
		string.format("every title and date is whole on one line of the narrowest card (%d px), the date short of the "
			.. "newest card's tag, whose LATEST fits its %d px", inner, U.TagW), table.concat(whole, "; "))

	-- A short log is a short panel; a long one stops at MaxH and scrolls.
	local counts = {}
	for _, e in ipairs(UpdateLog.shown()) do
		table.insert(counts, #e.bullets)
	end
	local content = MenuLayout.updatesContent(counts)
	local fitted = MenuLayout.updatesPanel({ safe = Vector2.new(1280, 662), compact = false, railRight = 142,
		rightLeft = 1218 }, OUTLINE, content)
	local well = MenuLayout.blocks(fitted).main.h
	local many = {}
	for _ = 1, GameConfig.UpdateLog.Shown do
		table.insert(many, GameConfig.UpdateLog.MaxBullets)
	end
	local tall = MenuLayout.updatesPanel({ safe = Vector2.new(1280, 662), compact = false, railRight = 142,
		rightLeft = 1218 }, OUTLINE, MenuLayout.updatesContent(many))
	check(well >= content + U.ListInset * 2 and well < content + U.ListInset * 2 + 1 and fitted.rect.h < desk.rect.h
			and tall.rect.h == desk.rect.h and fitted.rect.w == desk.rect.w,
		string.format("the shipped %d cards (%d px) get a %d-px panel whose well holds them exactly; six full cards "
			.. "get the %d-px panel and scroll", #counts, content, fitted.rect.h, tall.rect.h),
		string.format("well %d", well))

	--==========================================================================
	say("\n-- 2. the rules catch what they should --")
	--==========================================================================
	local good = { entry("b", "5 Oct 2026"), entry("a", "4 Oct 2026") }
	check(#UpdateLog.problems(good) == 0, "a good two-entry list passes")
	local cases = {
		{ "the same id twice", { entry("a", "5 Oct 2026"), entry("a", "4 Oct 2026") }, "used twice" },
		{ "an older entry above a newer one", { entry("a", "4 Oct 2026"), entry("b", "5 Oct 2026") }, "newest first" },
		{ "an unreadable date", { entry("a", "Oct 5th") }, "the date" },
		{ "an impossible date", { entry("a", "31 Feb 2026") }, "the date" },
		{ "one bullet", { entry("a", "5 Oct 2026", { "Only one." }) }, "bullets" },
		{ "six bullets", { entry("a", "5 Oct 2026", { "1", "2", "3", "4", "5", "6" }) }, "bullets" },
		{ "a two-line bullet", { entry("a", "5 Oct 2026", { "One\nTwo", "Fine." }) }, "more than one line" },
		{ "a long bullet", { entry("a", "5 Oct 2026", { string.rep("x", C.BulletMax + 1), "Fine." }) }, "characters" },
		{ "an empty bullet", { entry("a", "5 Oct 2026", { "", "Fine." }) }, "empty" },
		{ "a long title", { entry("a", "5 Oct 2026", nil, string.rep("T", C.TitleMax + 1)) }, "title" },
		{ "no title", { entry("a", "5 Oct 2026", nil, "") }, "no title" },
		{ "an empty list", {}, "empty" },
	}
	local missed = {}
	for _, case in ipairs(cases) do
		if not anyHas(UpdateLog.problems(case[2]), case[3]) then
			table.insert(missed, case[1])
		end
	end
	check(#missed == 0, string.format("each of %d broken lists is reported: %s", #cases,
		"a twice-used id, older above newer, a bad or impossible date, 1 or 6 bullets, a two-line, long or empty "
			.. "bullet, a long or missing title, an empty list"), table.concat(missed, ", "))

	--==========================================================================
	say("\n-- 3. dates --")
	--==========================================================================
	check(UpdateLog.dayOf("1 Jan 1970") == 0 and UpdateLog.dayOf("2 Jan 1970") == DAY
			and UpdateLog.dayOf("5 Oct 2026") == 1791158400 and UpdateLog.dayOf("05 Oct 2026") == 1791158400
			and UpdateLog.dayOf("5 oct 2026") == 1791158400,
		"\"5 Oct 2026\" is 2026-10-05 00:00 UTC (1791158400); a leading zero and the month's case do not matter",
		UpdateLog.dayOf("5 Oct 2026"))
	check(UpdateLog.dayOf("29 Feb 2028") == UpdateLog.dayOf("28 Feb 2028") + DAY
			and UpdateLog.dayOf("1 Mar 2028") == UpdateLog.dayOf("29 Feb 2028") + DAY
			and UpdateLog.dayOf("29 Feb 2027") == nil and UpdateLog.dayOf("1 Mar 2027") == UpdateLog.dayOf("28 Feb 2027") + DAY,
		"leap years: 29 Feb 2028 exists, 29 Feb 2027 does not")
	check(UpdateLog.dayOf("2026-10-05") == nil and UpdateLog.dayOf("5 October 2026") == nil and UpdateLog.dayOf(nil) == nil
			and UpdateLog.dayOf("32 Oct 2026") == nil and UpdateLog.dayOf("0 Oct 2026") == nil
			and UpdateLog.dayOf("5 Okt 2026") == nil,
		"anything not \"d Mon yyyy\" reads as no date")

	--==========================================================================
	say("\n-- 4. the NEW dot by date --")
	--==========================================================================
	local list = { entry("new", "5 Oct 2026"), entry("old", "1 Sep 2026") }
	local at = UpdateLog.dayOf("5 Oct 2026")
	check(UpdateLog.isNew(at, list) and UpdateLog.isNew(at + C.NewDays * DAY - 1, list)
			and not UpdateLog.isNew(at + C.NewDays * DAY, list) and not UpdateLog.isNew(at + 30 * DAY, list),
		string.format("on from the newest entry's day until %d days after it, then off", C.NewDays))
	check(UpdateLog.isNew(at - DAY, list), "an entry dated a day ahead (a publish written in advance) is new")
	check(not UpdateLog.isNew(at, { entry("x", "someday") }) and not UpdateLog.isNew(at, {})
			and not UpdateLog.isNew(0 / 0, list),
		"an unreadable date, an empty list or a junk clock is never new")
	check(not UpdateLog.isNew(at, { entry("old", "1 Sep 2026"), entry("older", "1 Aug 2026") }),
		"only the newest entry decides: an old newest entry is not new")
	check(C.NewDays == 3, "NewDays is 3 (GameConfig.UpdateLog)")
	local many = {}
	for i = 1, C.Shown + 3 do
		table.insert(many, entry("e" .. i, string.format("%d Sep 2026", 28 - i)))
	end
	local shown = UpdateLog.shown(many)
	check(#shown == C.Shown and shown[1].id == "e1" and shown[#shown].id == "e" .. C.Shown
			and #UpdateLog.shown() == math.min(C.Shown, #UpdateLog.Entries),
		string.format("the panel lists the newest %d, newest first", C.Shown))

	--==========================================================================
	say("\n-- 5. the wiring --")
	--==========================================================================
	local mod = sourceOf(Shared, "UpdateLog")
	local ui = sourceOf(StarterPlayer, "UpdateLogUI")
	check(mod ~= "" and not has(mod, "Remote") and not has(mod, "FireServer") and not has(mod, "DataStore"),
		"the log is a pure module: no remote, no server, no store")
	check(ui ~= "" and not has(ui, "FireServer") and not has(ui, "InvokeServer") and not has(ui, "SetAttribute(\"Seen")
			and not has(ui, "DataStore") and has(ui, "UpdateLog.isNew(") and has(ui, "seenThisSession = true"),
		"the dot: newest entry under NewDays old, cleared when the panel opens this session -- nothing saved, nothing sent")
	check(has(ui, "MenuKit.modal(gui, PANEL_NAME") and has(ui, "UIKit.scrollIcon(")
			and has(ui, "player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)") and has(ui, "UIKit.coverRail(playerGui, PANEL_NAME")
			and has(ui, "MenuLayout.updatesPanel("),
		"the panel: MenuKit's rim-themed modal with the scroll beside its title, on the OpenPanel mutex, covering the "
			.. "rail off a desktop, laid out by MenuLayout")
	check(has(ui, "Enum.KeyCode.Escape, Enum.KeyCode.Backspace") and has(ui, "MenuOpened"),
		"Escape and Backspace close it while it is open (and the Roblox menu opening); B is PadFocus's, by the mutex")
	local kit = sourceOf(Shared, "UIKit")
	local menuKit = sourceOf(Shared, "MenuKit")
	check(has(ui, "UIKit.scrollIcon(holder, z)\nend, true)") and has(menuKit, "stillWhenReduced = stillWhenReduced,")
			and has(kit, "scale.Scale = if still then userScale else 0.92 * userScale")
			and select(2, string.gsub(kit, "if not still then", "")) == 2 and has(kit, "ReducedMotionEnabled"),
		"reduced motion: the panel asks MenuKit for no pop (stillWhenReduced), and UIKit's modal then opens and shuts "
			.. "at its own size, the fade only, under the game's motion Off or the device's Reduce Motion")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nUpdateLogSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
