--!nocheck
--==============================================================================
-- Steal a Seed :: HudLayoutSpec
--
-- The responsive HUD contract: every permanent group placed clear of every
-- other and of Roblox's own touch controls, on every screen the owner listed,
-- with the desktop left exactly as it shipped. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HudLayoutSpec"))
--
-- THE DEFECT, MEASURED 2026-09-18 IN THE OWNER'S EMULATED 801 x 392 SESSION:
-- the cash block 68 px into the hotbar, WALK MODE 10 px into the cash block,
-- the thumbstick's ring over the cash block, the jump button under BAT/TRAP,
-- and the left rail 64% of the safe height.
--
-- WHAT THIS DRIVES: the real HudLayout, fresh-required, with the safe area
-- each screen gives a HUD ScreenGui -- a 58 px topbar off the top and, for the
-- notched phones, the landscape insets off the sides and the bottom -- and
-- Roblox's touch controls modelled from the PlayerModule's own formulas. It
-- also reads the ten owner scripts, for the rules only their source can show.
--
-- WHAT IT CANNOT DO is look at a phone. The emulator is not drivable from
-- here and the physical device is the owner's; this is the arithmetic and the
-- wiring, and the live pass measures the rest.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local RAIL = GameConfig.Rail
local HOT = GameConfig.Hotbar
local CFG = HudLayout.Config
local rect = HudLayout.rect

local pass, fails = 0, {}
local out = {}
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function r2s(r)
	return string.format("(%g,%g %gx%g)", r.x, r.y, r.w, r.h)
end
local function udimEq(a, b)
	return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset
		and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end

-- A 58-px topbar, and its free span starting where the Roblox buttons end: 208
-- was measured live on the emulated phone, and is the narrower answer.
local TOPBAR = 58
local BAR_LEFT = 208

local function screen(w, h, opts)
	opts = opts or {}
	local left, right, bottom = opts.left or 0, opts.right or 0, opts.bottom or 0
	return {
		safe = Vector2.new(w - left - right, h - TOPBAR - bottom),
		touch = opts.touch == true,
		keyboard = opts.keyboard ~= false,
		viewport = Vector2.new(w, h),
		topbar = rect(opts.barLeft or BAR_LEFT, 0, w - (opts.barLeft or BAR_LEFT), TOPBAR),
		insetTop = TOPBAR,
		cashWidth = opts.cashWidth,
	}
end

local ok, err = pcall(function()

--==============================================================================
-- 1. THE DESKTOP IS WHAT SHIPPED, TO THE PIXEL
--
-- The UDim2s every owner used to write inline, rebuilt here from GameConfig the
-- way the old code did, against what HudLayout.place now hands them.
--==============================================================================
say("-- desktop --")
local I, W, S, G6 = RAIL.Inset, RAIL.WideSize, RAIL.SquareSize, RAIL.Gap
local OLD = {
	index = UDim2.new(0, I, 0, I),
	shop = UDim2.new(0, I, 0, I + W.Y + G6),
	settings = UDim2.new(0, I, 0, I + (W.Y + G6) * 2),
	walk = UDim2.new(0, I, 0, I + (W.Y + G6) * 3),
	garden = UDim2.new(1, -I, 0, I),
	bag = UDim2.new(1, -I, 0, I + S.Y + G6),
	equipment = UDim2.new(1, -I, 0, I + (S.Y + G6) * 2 + 6),
	hotbar = UDim2.new(0.5, 0, 1, -HOT.BottomGap),
	cash = UDim2.new(0, 12, 1, -10),
	banner = UDim2.new(0.5, 0, 0, 84),
	skip = UDim2.new(0.5, 0, 0, 168),
}
for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1366, 768), Vector2.new(1600, 900),
	Vector2.new(1920, 1080), Vector2.new(2560, 1440) }) do
	local L = HudLayout.solve(screen(size.X, size.Y))
	local tag = string.format("%dx%d", size.X, size.Y)
	local same = not L.compact and L.slots == 10
		and udimEq(HudLayout.place(L.index, Vector2.zero, L.safe), OLD.index)
		and udimEq(HudLayout.place(L.shop, Vector2.zero, L.safe), OLD.shop)
		and udimEq(HudLayout.place(L.settings, Vector2.zero, L.safe), OLD.settings)
		and udimEq(HudLayout.place(L.walk, Vector2.zero, L.safe), OLD.walk)
		and udimEq(HudLayout.place(L.garden, Vector2.new(1, 0), L.safe), OLD.garden)
		and udimEq(HudLayout.place(L.bag, Vector2.new(1, 0), L.safe), OLD.bag)
		and udimEq(HudLayout.place(L.equipment, Vector2.new(1, 0), L.safe), OLD.equipment)
		and udimEq(HudLayout.place(L.hotbar, Vector2.new(0.5, 1), L.safe), OLD.hotbar)
		and udimEq(HudLayout.place(L.cashRoot, Vector2.new(0, 1), L.safe), OLD.cash)
		and udimEq(HudLayout.place(L.banner, Vector2.new(0.5, 0), L.safe), OLD.banner)
		and udimEq(HudLayout.place(L.skip, Vector2.new(0.5, 0), L.safe), OLD.skip)
	check(same, tag .. ": desktop, ten slots, and every group at the UDim2 it always had")
	check(L.index.w == W.X and L.walk.w == W.X and L.walk.h == 46 and L.settings.w == S.X
			and L.equipSlot == 68 and L.equipGap == 8 and L.banner.w == 560,
		tag .. ": the same sizes too -- 130-wide slabs, a 130x46 switch, 64x68 BAT/TRAP, a 560 banner")
	check(L.clock and math.abs((L.clock.x + L.clock.w / 2) - size.X / 2) < 0.01
			and math.abs(L.clock.w - math.clamp(size.X * 0.44, 190, 360)) < 0.01,
		tag .. ": the clock is its old width, centred", L.clock and r2s(L.clock))
	local problems = HudLayout.problems(L)
	check(#problems == 0, tag .. ": nothing overlaps", table.concat(problems, "; "))
end

-- A console has no keyboard: the desktop arrangement with five slots, as before.
local console = HudLayout.solve(screen(1920, 1080, { keyboard = false }))
check(not console.compact and console.slots == 5,
	"no keyboard and no touch keeps the desktop arrangement and five slots, as before")

-- A narrow desktop window: the old overlap is the cash block beside the strip.
local narrow = HudLayout.solve(screen(1000, 609))
check(not narrow.compact and narrow.slots == 10
		and narrow.cash.y + narrow.cash.h + CFG.Gap <= narrow.hotbar.y
		and #HudLayout.problems(narrow) == 0,
	"a 1000x609 desktop window keeps its rail and ten slots, and lifts the cash block above the strip",
	r2s(narrow.cash) .. " vs " .. r2s(narrow.hotbar))
check(HudLayout.solve(screen(1268, 720)).cash.y == HudLayout.solve(screen(1920, 720)).cash.y,
	"from 1268 px wide the cash block never moves off its corner")
local short = HudLayout.solve(screen(1400, 400))
check(short.compact and short.slots == 5 and #HudLayout.problems(short) == 0,
	"a desktop window too short for the column rail goes compact, clean",
	table.concat(HudLayout.problems(short), "; "))
check(HudLayout.solve(screen(899, 700)).compact,
	"and so does one narrower than 900")

--==============================================================================
-- 2. EVERY LISTED PHONE, EMULATED AND REAL, WITH ITS CONTROLS
--==============================================================================
say("-- phones --")
local PHONES = {
	{ 640, 480 }, { 772, 360 }, { 874, 402 }, { 896, 414 }, { 956, 440 }, { 1000, 609 },
}
-- The same screens with the notch and home-indicator insets a real iPhone
-- takes off in landscape: 62/62/21 on the 16 Pro and Pro Max, 48/48/21 on the
-- XR and 11. A HUD ScreenGui's AbsoluteSize is what is left.
local NOTCHED = {
	{ 874, 402, 62, 21, "iPhone 16 Pro" },
	{ 956, 440, 62, 21, "iPhone 16 Pro Max" },
	{ 896, 414, 48, 21, "iPhone 11" },
}
local cases = {}
for _, p in ipairs(PHONES) do
	table.insert(cases, { tag = string.format("%dx%d emulated", p[1], p[2]),
		input = screen(p[1], p[2], { touch = true, keyboard = true }) })
	table.insert(cases, { tag = string.format("%dx%d phone", p[1], p[2]),
		input = screen(p[1], p[2], { touch = true, keyboard = false }) })
end
for _, p in ipairs(NOTCHED) do
	table.insert(cases, { tag = string.format("%dx%d %s", p[1], p[2], p[5]),
		input = screen(p[1], p[2], { touch = true, keyboard = false,
			left = p[3], right = p[3], bottom = p[4] }) })
end
-- The owner's own session, which is where the overlaps were measured.
table.insert(cases, { tag = "801x392 the owner's session",
	input = screen(801, 392, { touch = true, keyboard = true }) })

local worstGap = math.huge
for _, case in ipairs(cases) do
	local L = HudLayout.solve(case.input)
	local tag = case.tag
	local sw, sh = L.safe.X, L.safe.Y
	local problems = HudLayout.problems(L)
	check(L.compact and L.slots == 5 and L.fits and #problems == 0,
		tag .. ": compact, five slots, every group clear by 8 px and inside the margin",
		table.concat(problems, "; "))

	-- the rail row
	local cells = { L.index, L.shop, L.settings, L.walk }
	local even = true
	for i, c in ipairs(cells) do
		even = even and c.w == cells[1].w and c.h == cells[1].h and c.w >= 44 and c.h >= 44
			and c.y == CFG.Margin
		if i > 1 then
			even = even and c.x - (cells[i - 1].x + cells[i - 1].w) == RAIL.Gap
		end
	end
	check(even, tag .. ": Index, Shop, Settings and WALK MODE in one row, same size, same gap, 44+")
	check(L.garden.w >= 44 and L.bag.w >= 44 and L.garden.y == L.bag.y
			and L.bag.x + L.bag.w == sw - CFG.Margin,
		tag .. ": Garden and the Bag in one row, the Bag in the corner")
	local indexBadge, gardenBadge = HudLayout.badges(L)
	check(indexBadge.y >= 0 and gardenBadge.y >= 0 and indexBadge.x + indexBadge.w < L.shop.x,
		tag .. ": both badges on the glass, and Index's clear of Shop",
		r2s(indexBadge))

	-- the hotbar
	local thumb, jump = L.thumb, L.jump
	check(thumb ~= nil and jump ~= nil, tag .. ": the thumbstick and jump button are reserved")
	check(L.hotbar.w == HudLayout.hotbarWidth(5, L.chip) and HOT.SlotWidth >= 44
			and L.hotbar.y + L.hotbar.h == sh - HOT.BottomGap,
		tag .. ": the strip is five 64-px slots on the bottom edge", r2s(L.hotbar))
	check(math.abs((L.hotbar.x + L.hotbar.w / 2) - sw / 2) <= 8,
		tag .. ": and within 8 px of the middle",
		(L.hotbar.x + L.hotbar.w / 2) - sw / 2)
	check(HudLayout.gap(L.hotbar, thumb) >= 8 and HudLayout.gap(L.hotbar, jump) >= 8,
		tag .. ": clear of both thumbs",
		string.format("%.1f / %.1f", HudLayout.gap(L.hotbar, thumb), HudLayout.gap(L.hotbar, jump)))

	-- cash
	check(L.cash.w >= CFG.CashReserve and L.cash.h == 110
			and L.cash.y + L.cash.h + 8 <= thumb.y,
		tag .. ": the cash block is full size and stands above the thumbstick", r2s(L.cash))
	-- The cash line's 3 px outline draws left of the root: measured live, the
	-- "$" reached x = 5 when the root sat on the plain 8 px margin.
	check(L.cash.x - 3 >= CFG.Margin,
		tag .. ": and the first character's outline is still 8 px inside the safe edge", L.cash.x - 3)

	-- BAT/TRAP
	check(L.equipment.x + L.equipment.w == sw - CFG.Margin
			and L.equipment.y + L.equipment.h + 8 <= jump.y
			and L.equipment.y >= L.railBottom + 8 and L.equipSlot >= 52,
		tag .. ": BAT over TRAP against the right edge, above the jump button",
		r2s(L.equipment) .. " slot " .. L.equipSlot)

	-- the clock
	local clock = L.clock
	local bar = case.input.topbar
	check(clock and math.abs(clock.x + clock.w / 2 - case.input.viewport.X / 2) < 0.01
			and clock.x >= bar.x + 8 and clock.x + clock.w <= bar.x + bar.w - 8
			and clock.w >= CFG.ClockFloor,
		tag .. ": the clock is centred, 8 px clear of the Roblox buttons", clock and r2s(clock))

	-- the tutorial banner, against everything permanent
	local clearOfAll = true
	for _, group in ipairs(HudLayout.groups(L, true)) do
		clearOfAll = clearOfAll and HudLayout.gap(L.banner, group.rect) >= 8
			and HudLayout.gap(L.skip, group.rect) >= 8
	end
	clearOfAll = clearOfAll and HudLayout.gap(L.banner, thumb) >= 8
		and HudLayout.gap(L.banner, jump) >= 8
	check(clearOfAll and L.banner.x >= 8 and L.banner.x + L.banner.w <= sw - 8,
		tag .. ": the tutorial banner and its skip line touch nothing", r2s(L.banner))

	-- the report: every group, and the smallest gap between any two
	local groups = HudLayout.groups(L, true)
	table.insert(groups, { name = "thumb", rect = thumb })
	table.insert(groups, { name = "jump", rect = jump })
	local least, pair = math.huge, ""
	for i = 1, #groups do
		for j = i + 1, #groups do
			if not (groups[i].name == "thumb" and groups[j].name == "jump") then
				local apart = HudLayout.gap(groups[i].rect, groups[j].rect)
				if apart < least then
					least, pair = apart, groups[i].name .. "/" .. groups[j].name
				end
			end
		end
	end
	worstGap = math.min(worstGap, least)
	local line = {}
	for _, group in ipairs(groups) do
		table.insert(line, group.name .. r2s(group.rect))
	end
	say(string.format("    %s  safe %dx%d  min gap %.1f (%s)", tag, sw, sh, least, pair))
	say("      " .. table.concat(line, " "))
end
check(worstGap >= 8, "the smallest gap on any listed phone is at least 8 px", worstGap)

-- Rotating and resizing a phone never changes its slot count.
local counts = {}
for _, case in ipairs(cases) do
	counts[HudLayout.solve(case.input).slots] = true
end
check(counts[5] and not counts[10],
	"every phone case is five slots, so resizing or rotating one never releases an assignment")

-- Without touch, a small window keeps its cash block in the corner when there is room.
local window = HudLayout.solve(screen(860, 700, { touch = false }))
check(window.compact and window.thumb == nil and #HudLayout.problems(window) == 0,
	"a small desktop window is compact with no thumb reservations", r2s(window.cash))

--==============================================================================
-- 3. THE BIOME NOTICE, EVERY NAME, EVERY PHONE
--==============================================================================
say("-- the biome notice --")
local widest = 0
for _, biome in pairs(BiomeData.ById) do
	local word = string.upper(biome.DisplayName)
	local width = TextService:GetTextSize(word, 24, Enum.Font.LuckiestGuy,
		Vector2.new(4000, 100)).X + 3
	widest = math.max(widest, width)
end
check(widest > 100, "the widest biome name was measured", widest)
local centred, clear = true, true
for _, case in ipairs(cases) do
	local L = HudLayout.solve(case.input)
	local dx, top = HudLayout.notice(L, widest, 30, 50 - TOPBAR)
	local box = rect(L.safe.X / 2 + dx - widest / 2, top, widest, 30)
	centred = centred and dx == 0 and top == 50 - TOPBAR
	for _, group in ipairs(HudLayout.groups(L, true)) do
		clear = clear and HudLayout.gap(box, group.rect) >= 8
	end
end
check(centred, "the widest name stays centred at its old height on every listed phone")
check(clear, "and clears both top rows by 8 px on all of them")
local tiny = HudLayout.solve(screen(560, 320, { touch = true }))
local dx = HudLayout.notice(tiny, widest, 30, 50 - TOPBAR)
check(dx ~= 0 or select(2, HudLayout.notice(tiny, widest, 30, 50 - TOPBAR)) ~= 50 - TOPBAR,
	"where it cannot stay centred between the rows it moves rather than overlap them")

--==============================================================================
-- 4. THE CLOCK ON A SCREEN WHERE THE TOPBAR BITES
--==============================================================================
say("-- the clock --")
local squeezed = HudLayout.solve(screen(640, 480, { touch = true, barLeft = 250 }))
local c = squeezed.clock
check(c and c.x >= 258 and c.x + c.w <= 632 and c.w >= CFG.ClockFloor,
	"with Roblox buttons out to 250 px the clock narrows, then slides, and never covers them",
	c and r2s(c))

--==============================================================================
-- 5. A MEASURED CASH BLOCK WIDER THAN ITS RESERVATION STILL PLACES CLEAR
--==============================================================================
local wide = HudLayout.solve(screen(1000, 609, { touch = true, cashWidth = 300 }))
check(wide.cash.w == 300 and #HudLayout.problems(wide) == 0,
	"a cash block measured at 300 px is placed at 300 px, clear of everything",
	table.concat(HudLayout.problems(wide), "; "))

--==============================================================================
-- 6. THE WIRING, READ FROM THE SOURCE
--==============================================================================
say("-- the owners --")
local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local function sourceOf(name)
	local s = scripts and scripts:FindFirstChild(name)
	return s and s.Source or nil
end
local layoutSource = Shared:FindFirstChild("HudLayout").Source
check(not layoutSource:find("Instance.new", 1, true) and not layoutSource:find(":Connect(", 1, true)
		and not layoutSource:find("RunService", 1, true) and not layoutSource:find("task.", 1, true),
	"HudLayout builds nothing, listens to nothing and runs on no clock")

-- Per-frame hooks, counted before this change; none may be added.
local FRAME_HOOKS = {
	CashUI = 2, IndexUI = 0, ShopUI = 0, SettingsUI = 0, WalkModeUI = 1, GardenUI = 1,
	LoadoutUI = 2, WorldClock = 1, TutorialUI = 1, BiomeGuideUI = 0,
}
local function count(text, needle)
	local n, at = 0, 1
	while true do
		local found = text:find(needle, at, true)
		if not found then
			return n
		end
		n += 1
		at = found + #needle
	end
end
for name, hooks in pairs(FRAME_HOOKS) do
	local src = sourceOf(name)
	check(src ~= nil and src:find("HudLayout.solve(", 1, true) ~= nil
			and src:find("HudLayout.measure(", 1, true) ~= nil,
		name .. " asks HudLayout for its place")
	local found = if src then count(src, "RenderStepped") + count(src, "Heartbeat")
		+ count(src, "BindToRenderStep") + count(src, "RunService.Stepped") else -1
	check(found == hooks, name .. " has no new per-frame hook", found)
	check(src ~= nil and src:find('GetPropertyChangedSignal("AbsoluteSize"):Connect(', 1, true) ~= nil,
		name .. " asks again only when a ScreenGui's size changes")
	check(src ~= nil and count(src, 'Instance.new("ScreenGui")') == (if name == "WalkModeUI" then 0 else 1)
			and not src:find('Instance.new("RemoteEvent")', 1, true),
		name .. " made no second ScreenGui and no remote")
end
local loadout = sourceOf("LoadoutUI") or ""
check(loadout:find("return layout.slots", 1, true) ~= nil
		and loadout:find("layout.chip", 1, true) ~= nil,
	"LoadoutUI takes its slot count and the Bag cell from the same answer that places the strip")
check(loadout:find('hotbar:GetPropertyChangedSignal("Position"):Connect(follow)', 1, true) ~= nil,
	"and the painted tray follows the strip when it slides")
check(loadout:find("assigned[i] = nil", 1, true) ~= nil and loadout:find("if want < activeSlots then", 1, true) ~= nil,
	"and the rule for 6-10 on a desktop window going compact is the one that shipped")
local walk = sourceOf("WalkModeUI") or ""
check(walk:find("STACKED_LABEL", 1, true) and walk:find("WALK.OnText", 1, true)
		and walk:find("WALK.OffText", 1, true) and walk:find("relayout:Disconnect()", 1, true),
	"the compact switch still says WALK MODE and ON or OFF, and drops its hook on the shared layer with itself")
local settings = sourceOf("SettingsUI") or ""
check(settings:find("plate.Visible = layout.compact", 1, true) ~= nil,
	"Settings stands on a plate in the compact row, and only there")
local cash = sourceOf("CashUI") or ""
check(cash:find("HudLayout.measure(gui, groupWidth())", 1, true) ~= nil
		and cash:find("if groupWidth() > placedFor then", 1, true) ~= nil,
	"the cash block is measured as one group and placed again only if it outgrows its reservation")
--==============================================================================
-- EVERY PANEL DRAWS OVER THE HOTBAR
--
-- Found by the owner 2026-09-18: the almanac's ScreenGui and the hotbar's were
-- both DisplayOrder 30, so the strip drew over the bottom of the open panel --
-- on a phone, and on a 720-px desktop too. Every modal's ScreenGui sits above
-- SeedLoadout and below the rail layer, which must stay clickable over all.
--==============================================================================
local function displayOrder(src)
	return src and tonumber(src:match("gui%.DisplayOrder = (%d+)")) or nil
end
local hotbarOrder = displayOrder(sourceOf("LoadoutUI"))
local railOrder = tonumber(Shared:FindFirstChild("UIKit").Source:match("layer%.DisplayOrder = (%d+)"))
for _, name in ipairs({ "IndexUI", "GardenUI", "SettingsUI", "ShopUI", "MarigoldShopUI" }) do
	local order = displayOrder(sourceOf(name))
	check(order and hotbarOrder and railOrder and order > hotbarOrder and order < railOrder,
		string.format("%s's panel draws over the hotbar and under the rail", name),
		string.format("%s vs hotbar %s, rail %s", tostring(order), tostring(hotbarOrder), tostring(railOrder)))
end

local kit = Shared:FindFirstChild("UIKit").Source
check(kit:find("function UIKit.railShape", 1, true) and kit:find("function UIKit.railBadge", 1, true)
		and kit:find("if layout.compact then", 1, true),
	"UIKit reshapes a rail button for its owner and steps modal headers clear of the compact rows")

end)

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, 0 failed"):format(pass)
