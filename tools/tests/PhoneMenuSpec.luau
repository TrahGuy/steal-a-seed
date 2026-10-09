--!nocheck
--==============================================================================
-- Steal a Seed :: PhoneMenuSpec
--
-- Every menu panel smaller on a phone (2026-10-08, the owner: "make the ui
-- smaller on phones"; every menu panel, 85%). Edit mode, by arithmetic and by
-- the pure modules:
--
--   1. the rule: a phone is touch with the viewport's shorter side under 500
--      (the prompts' rule); it draws menus at 0.85, everything else at 1
--   2. a menu gui's scale on a phone: 0.85 at NORMAL, times a larger choice,
--      never past what fits, never under 0.85 (UIKit.menuScaleFor's rule)
--   3. MenuLayout's covering panel with `fill`: on every listed phone the same
--      logical panel as at 1:1 -- the same room, the same layout -- drawn 85%
--      the size, centred, short of every edge; nothing changes on a desktop
--   4. the Bag: 85% of its footprint, centred where it was, drawn 85% the
--      size, with exactly the insides it had; nothing changes off a phone
--   5. the plain modals (Settings, Marigold, Sell, Offline, Sacrifice): their
--      fractions and their content's room taken of the phone's share
--   6. the wiring: every menu passes the share, the Wheel's shell takes it,
--      the HUD never does
--
-- Not here, seen in Play instead: the panels on a phone's screen.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local MenuLayout = require(Shared.MenuLayout)

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
local function count(src, needle)
	local n, at = 0, 1
	while true do
		local i = string.find(src, needle, at, true)
		if not i then
			return n
		end
		n += 1
		at = i + #needle
	end
end
-- The code without its comments, for the checks that are about what RUNS.
local function code(src)
	return (src:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", ""))
end
local function near(a, b, tol)
	return math.abs(a - b) <= (tol or 1)
end

local OUTLINE = GameConfig.Rail.OutlineThickness
local TOPBAR, BAR_LEFT = 58, 208
local function rect(x, y, w, h)
	return { x = x, y = y, w = w, h = h }
end
-- CompactMenusSpec's screens: the safe area under the 58 of top bar, a notch's
-- inset each side and 21 under it.
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

local DESKS = { { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 1000, 609 } }
local PHONES = { { 640, 360 }, { 705, 338 }, { 772, 360 }, { 801, 392 }, { 874, 402, 62 }, { 896, 414, 48 },
	{ 956, 440, 62 }, { 844, 390, 47 } }
local M = GameConfig.MenuSize

local ok, err = pcall(function()
	--==========================================================================
	say("1. The rule")
	--==========================================================================
	check(M.PhoneScale == 0.85 and M.PhoneShortSide == 500, "a phone draws menus at 0.85; a phone's shorter side is under 500")
	local wrong = {}
	for _, d in ipairs(PHONES) do
		local v = Vector2.new(d[1], d[2])
		if GameConfig.menuPhoneScale(v, true) ~= 0.85 then
			table.insert(wrong, string.format("%dx%d touch", d[1], d[2]))
		end
		if GameConfig.menuPhoneScale(v, false) ~= 1 then
			table.insert(wrong, string.format("%dx%d no touch", d[1], d[2]))
		end
		if GameConfig.menuPhoneScale(Vector2.new(d[2], d[1]), true) ~= 0.85 then
			table.insert(wrong, string.format("%dx%d upright", d[2], d[1]))
		end
	end
	check(#wrong == 0, "every listed phone, either way up, is a phone by touch; the same window without touch is not",
		table.concat(wrong, "; "))
	check(GameConfig.menuPhoneScale(Vector2.new(1024, 768), true) == 1
			and GameConfig.menuPhoneScale(Vector2.new(1000, 609), true) == 1
			and GameConfig.menuPhoneScale(Vector2.new(1180, 820), true) == 1,
		"a tablet keeps today's size")
	check(GameConfig.menuPhoneScale(nil, true) == 1 and GameConfig.menuPhoneScale(Vector2.zero, true) == 1,
		"no viewport yet: today's size")
	local prompt = GameConfig.Labels.Prompt
	check(prompt.PhoneShortSide == M.PhoneShortSide, "the same phones as the prompts' 75%")

	--==========================================================================
	say("2. A menu gui's scale on a phone")
	--==========================================================================
	local kit = sourceOf(Shared, "UIKit")
	check(has(kit, "function UIKit.phoneMenuScale(): number")
			and has(kit, "GameConfig.menuPhoneScale(if camera then camera.ViewportSize else nil, UserInputService.TouchEnabled)")
			and has(kit, "local want = UIKit.menuScale() * phone")
			and has(kit, "return math.max(phone, math.min(want, fitW, fitH))"),
		"UIKit.menuScaleFor: the phone's scale times the choice, as far as it fits, never under the phone's")
	-- The rule, for every listed phone and option: what applyTenFoot is handed.
	local bad = {}
	for _, d in ipairs(PHONES) do
		local input = screen(d[1], d[2], true, false, d[3])
		for _, option in ipairs(M.Options) do
			local phone = GameConfig.menuPhoneScale(input.viewport, true)
			local fitW = input.safe.X * 0.9 / 300
			local fitH = input.safe.Y * 0.86 / 220
			local k = math.max(phone, math.min(option.Scale * phone, fitW, fitH))
			if option.Scale == 1 and k ~= 0.85 then
				table.insert(bad, string.format("%dx%d normal %.3f", d[1], d[2], k))
			end
			if k < 0.85 or k > option.Scale * 0.85 + 1e-9 then
				table.insert(bad, string.format("%dx%d %s %.3f", d[1], d[2], option.Id, k))
			end
		end
	end
	check(#bad == 0, "0.85 at NORMAL on every phone; a larger choice larger, never past it times 0.85",
		table.concat(bad, "; "))

	--==========================================================================
	say("3. The covering panel")
	--==========================================================================
	local panels = {
		{ "Index", function(s) return MenuLayout.indexPanel(s, OUTLINE, { 12, 9, 7 }) end },
		{ "Shop", function(s) return MenuLayout.shopPanel(s, OUTLINE, { 4, 6, 3 }) end },
		{ "MY PLANTS", function(s) return MenuLayout.plantsPanel(s, OUTLINE) end },
		{ "EVENTS", function(s) return MenuLayout.eventsPanel(s, OUTLINE) end },
		{ "WHAT'S NEW", function(s) return MenuLayout.updatesPanel(s, OUTLINE, 900) end },
		{ "Rebirth 860x640", function(s) return MenuLayout.panel(s, 860, 640, OUTLINE) end },
		{ "Sprout Dash 820x520", function(s) return MenuLayout.panel(s, 820, 520, OUTLINE) end },
	}
	local room, centred, edges, same = {}, {}, {}, {}
	local margins = {}
	for _, d in ipairs(PHONES) do
		local input = screen(d[1], d[2], true, false, d[3])
		local L = HudLayout.solve(input)
		local f = GameConfig.menuPhoneScale(input.viewport, true)
		-- At 1:1, and as the menu gui sees it at f: a canvas 1/f larger, the
		-- rails in its units, and the share.
		local s1 = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		local sf = { safe = L.safe / f, compact = L.compact, railRight = L.railRight / f,
			rightLeft = L.rightLeft / f, fill = math.min(1, f) }
		for _, entry in ipairs(panels) do
			local tag = string.format("%dx%d %s", d[1], d[2], entry[1])
			local a, b = entry[2](s1), entry[2](sf)
			if not (near(a.rect.w, b.rect.w) and near(a.rect.h, b.rect.h)) then
				table.insert(room, string.format("%s %dx%d at 1:1, %dx%d at 85%%", tag, a.rect.w, a.rect.h, b.rect.w, b.rect.h))
			end
			if a.short ~= b.short or a.header ~= b.header or a.sidebar ~= b.sidebar or a.covers ~= b.covers then
				table.insert(same, tag)
			end
			-- On screen: its gui's units times f.
			local x, y, w, h = b.rect.x * f, b.rect.y * f, b.rect.w * f, b.rect.h * f
			if not (near(x + w / 2, L.safe.X / 2, 1.5) and near(y + h / 2, L.safe.Y / 2, 1.5)) then
				table.insert(centred, string.format("%s centre %.1f,%.1f", tag, x + w / 2, y + h / 2))
			end
			local mx, my = L.safe.X * (1 - f) / 2, L.safe.Y * (1 - f) / 2
			if x < mx - 1 or y < my - 1 or x + w > L.safe.X - mx + 1 or y + h > L.safe.Y - my + 1 then
				table.insert(edges, string.format("%s at %.0f,%.0f %.0fx%.0f", tag, x, y, w, h))
			end
			if entry[1] == "Shop" then
				table.insert(margins, string.format("%dx%d %.0f/%.0f px", d[1], d[2], x, y))
			end
		end
	end
	check(#room == 0, "on every phone, every menu keeps its room: the same logical panel as at 1:1",
		table.concat(room, "; "))
	check(#same == 0, "and the same layout: the same short header, sidebar and cover", table.concat(same, "; "))
	check(#centred == 0, "drawn centred on the safe area", table.concat(centred, "; "))
	check(#edges == 0, "and short of every edge by 7.5% of the safe area or more", table.concat(edges, "; "))
	say("    the Shop's left / top margin on screen: " .. table.concat(margins, ", "))
	-- With the keyboard up the panel still stops above it.
	do
		local input = screen(801, 392, true, false)
		local L = HudLayout.solve(input)
		local f = 0.85
		local sf = { safe = L.safe / f, compact = L.compact, railRight = L.railRight / f,
			rightLeft = L.rightLeft / f, fill = f, keyboardTop = 200 / f }
		local p = MenuLayout.shopPanel(sf, OUTLINE, { 4, 6, 3 })
		check(p.rect.y + p.rect.h <= 200 / f - 8 + 1, "an on-screen keyboard still stops the panel 8 above it",
			string.format("%.1f", p.rect.y + p.rect.h))
	end
	-- Nothing moves on a desktop: no share, or a share of 1.
	local moved = {}
	for _, d in ipairs(DESKS) do
		local L = HudLayout.solve(screen(d[1], d[2], false, true))
		local s = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		local s1 = table.clone(s)
		s1.fill = 1
		for _, entry in ipairs(panels) do
			local a, b = entry[2](s), entry[2](s1)
			if a.rect.x ~= b.rect.x or a.rect.y ~= b.rect.y or a.rect.w ~= b.rect.w or a.rect.h ~= b.rect.h then
				table.insert(moved, string.format("%dx%d %s", d[1], d[2], entry[1]))
			end
		end
	end
	check(#moved == 0, "on a desktop every panel stands exactly where it did", table.concat(moved, "; "))

	--==========================================================================
	say("4. The Bag")
	--==========================================================================
	local bagBad = {}
	for _, d in ipairs(PHONES) do
		local input = screen(d[1], d[2], true, false, d[3])
		local L = HudLayout.solve(input)
		for _, chosen in ipairs({ 1, 1.3 }) do
			local base = { hotTop = L.namePopup.y, stripHidden = L.touch, scale = chosen }
			local small = table.clone(base)
			small.phone = GameConfig.menuPhoneScale(input.viewport, true)
			local a, b = HudLayout.bag(L, base), HudLayout.bag(L, small)
			local tag = string.format("%dx%d at %.2f", d[1], d[2], chosen)
			if not (near(b.panel.w, a.panel.w * 0.85, 0.01) and near(b.panel.h, a.panel.h * 0.85, 0.01)) then
				table.insert(bagBad, tag .. " footprint")
			end
			if not (near(b.panel.x + b.panel.w / 2, a.panel.x + a.panel.w / 2, 0.01)
				and near(b.panel.y + b.panel.h / 2, a.panel.y + a.panel.h / 2, 0.01)
				and b.centre == a.centre) then
				table.insert(bagBad, tag .. " centre")
			end
			if not near(b.scale, a.scale * 0.85, 1e-9) then
				table.insert(bagBad, tag .. " scale")
			end
			if not (near(b.panel.w / b.scale, a.panel.w / a.scale, 0.01) and near(b.panel.h / b.scale, a.panel.h / a.scale, 0.01)) then
				table.insert(bagBad, tag .. " logical size")
			end
			if b.rows ~= a.rows or b.columns ~= a.columns or b.catH ~= a.catH or b.compactHeader ~= a.compactHeader
				or b.body.w ~= a.body.w or b.body.h ~= a.body.h or b.grid.w ~= a.grid.w or b.grid.h ~= a.grid.h then
				table.insert(bagBad, tag .. " insides")
			end
		end
	end
	check(#bagBad == 0, "on every phone, at NORMAL and LARGER: 85% of its footprint, centred where it was, "
		.. "drawn 85% the size, the same insides", table.concat(bagBad, "; "))
	local deskBag = {}
	for _, d in ipairs(DESKS) do
		local L = HudLayout.solve(screen(d[1], d[2], false, true))
		local base = { hotTop = L.namePopup.y, stripHidden = L.touch }
		local one = table.clone(base)
		one.phone = 1
		local a, b = HudLayout.bag(L, base), HudLayout.bag(L, one)
		if a.panel.w ~= b.panel.w or a.panel.h ~= b.panel.h or a.panel.x ~= b.panel.x or a.scale ~= b.scale then
			table.insert(deskBag, string.format("%dx%d", d[1], d[2]))
		end
	end
	check(#deskBag == 0, "off a phone the Bag is exactly what it was", table.concat(deskBag, "; "))
	local loadout = sourceOf(Scripts, "LoadoutUI")
	check(has(loadout, "phone = UIKit.phoneMenuScale(),") and has(loadout, "modal.setUserScale(bag.scale)")
			and has(loadout, "modal.group.Size = UDim2.fromOffset(bag.panel.w / bag.scale, bag.panel.h / bag.scale)"),
		"LoadoutUI hands the Bag the phone's scale and draws it at the scale the Bag answers")

	--==========================================================================
	say("5. The plain modals")
	--==========================================================================
	check(has(kit, "local function share(): number")
			and has(kit, "return math.min(1, HudLayout.scaleOf(gui) * userScale)")
			and count(kit, "local screen = gui.AbsoluteSize.Y / HudLayout.scaleOf(gui) * share()") == 2
			and has(kit, "group.Size = UDim2.new(0.9 * share() / userScale, 0, 0, want)")
			and has(kit, "math.min(limit.MaxSize.Y, math.floor(screen * 0.86 / userScale)) - MODAL_CHROME"),
		"a modal's width and its content's room are taken of its share of the screen")
	check(has(kit, "local s = math.max(phone, math.min(UIKit.menuScale() * phone,")
			and has(kit, "group.Size = UDim2.fromScale(0.9 * part / s, 0.82 * part / s)")
			and has(kit, "group.Size = UDim2.fromScale(0.9 * part / userScale, 0.82 * part / userScale)")
			and has(kit, "fitScreen = fitScreen,"),
		"a panel that follows the menu size on itself takes the phone's scale too; fitScreen re-sizes a fractions panel")
	check(has(kit, "local menu = (if HudLayout.isTenFoot() then math.max(1, HudLayout.scaleOf(gui) / k)\n\t\t\telse HudLayout.scaleOf(gui)) * userScale"),
		"the header's rail padding is handed back at the drawn scale, below 1 on a phone")
	-- The arithmetic: a modal on a 801x392 phone, 334 safe tall, 801 wide.
	do
		local px = Vector2.new(801, 334)
		local f = 0.85
		-- 1:1: 90% wide (capped 460), content room 86% tall.
		local oldW, oldH = math.min(460, 0.9 * px.X), math.floor(px.Y * 0.86)
		-- At 0.85 on its gui: the canvas px / f, the share f.
		local canvas = px / f
		local newW, newH = math.min(460, 0.9 * f * canvas.X), math.floor(canvas.Y * f * 0.86)
		check(near(newW, oldW, 0.01) and near(newH, oldH, 0.01),
			"Settings on the owner's phone: the room it had, in its gui's units (so drawn at 85%)",
			string.format("%.1f x %d, was %.1f x %d", newW, newH, oldW, oldH))
	end
	local marigold = sourceOf(Scripts, "MarigoldShopUI")
	check(has(marigold, "UIKit.menuGui(gui)") and has(marigold, "task.defer(modal.fitScreen)")
			and has(marigold, 'gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitScreen)')
			and has(marigold, "UIKit.onMenuSize(fitScreen)"),
		"Marigold's fractions panel is re-sized after its gui's scale changes")
	check(has(sourceOf(Scripts, "SettingsUI"), "modal.fitContent(ROW_H * 4 + ROW_GAP * 3)"),
		"Settings sizes to its content, of its share")
	for _, name in ipairs({ "SellUI", "OfflineUI", "SacrificeUI" }) do
		check(has(sourceOf(Scripts, name), "modal.followMenuSize()"), name .. " follows the menu size, phone included")
	end

	--==========================================================================
	say("6. The wiring")
	--==========================================================================
	local missing = {}
	for _, name in ipairs({ "EventsUI", "GardenUI", "IndexUI", "InviteUI", "RebirthUI", "ShopUI", "SproutDashUI",
		"UpdateLogUI" }) do
		local src = sourceOf(Scripts, name)
		if count(src, "fill = math.min(1, k),") ~= 1 or not has(src, "UIKit.menuGui(gui") then
			table.insert(missing, name)
		end
	end
	check(#missing == 0, "every MenuLayout menu is a menu gui and hands MenuLayout its share", table.concat(missing, ", "))
	local wheel = sourceOf(Scripts, "WheelUI")
	check(has(wheel, "local fill = math.min(1, k)")
			and has(wheel, "shell.Size = UDim2.new(fill, -(left + right) * fill, fill, -(top + bottom) * fill)")
			and has(wheel, "local area = whole * fill")
			and has(wheel, "local bottom = inset.Max.Y / k - shellAt.Y")
			and has(wheel, "layoutSheet(W, H, k, insetL + shellAt.X, insetR + shellAt.X)"),
		"the Wheel's shell takes the share, lays out in the room it had, and reads the topbar in its own units")
	local hud = {}
	for _, name in ipairs({ "CashUI", "WorldClock", "ActionToastUI", "PlotTeleportUI", "BiomeGuideUI", "TutorialUI",
		"RailDrawerUI", "WalkModeUI", "AlertUI", "PromptUI" }) do
		local src = code(sourceOf(Scripts, name))
		if has(src, "phoneMenuScale") or has(src, "menuGui") or has(src, "followMenuSize") then
			table.insert(hud, name)
		end
	end
	check(#hud == 0, "the HUD and the prompts never take it: the HUD buttons stay as they are", table.concat(hud, ", "))
	local layout = sourceOf(Shared, "HudLayout")
	check(not has(code(layout), "phoneMenuScale") and has(layout, "phone: number?,"),
		"HudLayout places the HUD as before; only the Bag is handed the phone's scale")
end)

if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nPhoneMenuSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
