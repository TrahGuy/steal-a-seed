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
local SeedData = require(Shared:WaitForChild("SeedData"))

local RAIL = GameConfig.Rail
local HOT = GameConfig.Hotbar
local CFG = HudLayout.Config
local rect = HudLayout.rect
-- The compact belt, as every compact answer carries it.
local COMPACT_HOT = HudLayout.hotMetrics(true)

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
	-- WHAT'S NEW in Garden's old place since Garden and the Bag moved to the
	-- left edge (2026-10-09, the owner: "put them on center left"); the pair is
	-- checked on its own below.
	updates = UDim2.new(1, -I, 0, I),
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
		and udimEq(HudLayout.place(L.shop, Vector2.zero, L.safe), OLD.shop)
		and udimEq(HudLayout.place(L.settings, Vector2.zero, L.safe), OLD.settings)
		and udimEq(HudLayout.place(L.walk, Vector2.zero, L.safe), OLD.walk)
		and udimEq(HudLayout.place(L.updates, Vector2.new(1, 0), L.safe), OLD.updates)
		and udimEq(HudLayout.place(L.hotbar, Vector2.new(0.5, 1), L.safe), OLD.hotbar)
		and udimEq(HudLayout.place(L.cashRoot, Vector2.new(0, 1), L.safe), OLD.cash)
		and udimEq(HudLayout.place(L.banner, Vector2.new(0.5, 0), L.safe), OLD.banner)
		and udimEq(HudLayout.place(L.skip, Vector2.new(0.5, 0), L.safe), OLD.skip)
	check(same, tag .. ": desktop, ten slots (2026-10-03), and every group at the UDim2 it always had -- WHAT'S "
		.. "NEW in Garden's old corner, Index's corner empty (2026-10-09)")
	-- INDEX, GARDEN AND THE BAG, ONE OVER ANOTHER AT THE RIGHT EDGE (2026-10-09,
	-- the owner: "do not put sidebar on desktop, just on phone"): in WHAT'S NEW's
	-- column, the rail's squares 6 px apart, on the safe area's middle -- or
	-- stepped 8 px under WHAT'S NEW and Index's tucked badge.
	do
		local stackH = S.Y * 3 + G6 * 2
		local highest = L.updates.y + L.updates.h + CFG.Gap + 4.5
		local columnOk = L.column == true and L.pairRow ~= true and L.gardenRight ~= true
			and L.index.x == L.updates.x and L.garden.x == L.index.x and L.bag.x == L.index.x
			and L.index.x + L.index.w == L.safe.X - I and L.index.w == S.X and L.garden.w == S.X and L.bag.w == S.X
			and L.garden.y == L.index.y + S.Y + G6 and L.bag.y == L.garden.y + S.Y + G6
			and L.index.y >= highest - 1e-6
			and (L.index.y == math.floor(L.safe.Y / 2 - stackH / 2) or math.abs(L.index.y - highest) < 1e-6)
			and L.rightLeft == L.updates.x
		check(columnOk, tag .. ": Index, Garden and the Bag one over another at the right edge, in WHAT'S NEW's "
			.. "column, on the middle or stepped 8 px under it and Index's badge",
			r2s(L.index) .. " " .. r2s(L.garden) .. " " .. r2s(L.bag))
		-- The desktop's badges keep their size (the owner shrank a phone's only):
		-- the round 31-px box, tucked into each square's top-LEFT corner.
		local ib, gb = HudLayout.badges(L)
		check(ib.w == 31 and ib.h == 31 and gb.w == 31 and gb.h == 31 and ib.x == L.index.x - 4.5
				and ib.y == L.index.y - 4.5 and gb.x == L.garden.x - 4.5 and gb.y == L.garden.y - 4.5,
			tag .. ": the desktop's badges are the round 31-px ones, tucked into the top-LEFT corners",
			r2s(ib) .. " " .. r2s(gb))
	end
	check(L.hot == HOT and L.cashStyle == CFG.CashStyle.Desktop
			and L.hotbar.w == 750 and L.hotbar.h == 64
			and L.cashRoot.w == 316 and L.cashRoot.h == 108 and L.cash.h == 110,
		tag .. ": the shipped faces -- GameConfig.Hotbar itself, the 750 x 64 strip (ten slots, 2026-10-03), the 316 x 108 cash block",
		r2s(L.hotbar) .. " " .. r2s(L.cashRoot))
	check(L.index.w == S.X and L.index.h == S.Y and L.shop.w == W.X and L.shop.h == W.Y
			and L.walk.w == W.X and L.walk.h == 46 and L.settings.w == S.X
			and L.banner.w == 560 and L.equipment == nil and L.chooser == nil,
		tag .. ": the same sizes too -- Index the owner's 50x50 square (2026-09-24), Shop the rail's 130x50 "
			.. "for its wide picture (2026-10-06), a 130x46 switch, a 560 banner -- and no BAT/TRAP column (2026-10-03)")
	check(L.clock and math.abs((L.clock.x + L.clock.w / 2) - size.X / 2) < 0.01
			and math.abs(L.clock.w - math.clamp(size.X * 0.44, 190, 360)) < 0.01,
		tag .. ": the clock is its old width, centred", L.clock and r2s(L.clock))
	local problems = HudLayout.problems(L)
	check(#problems == 0, tag .. ": nothing overlaps", table.concat(problems, "; "))
end

-- A console has no keyboard: the desktop arrangement with ten slots (LB / RB).
local console = HudLayout.solve(screen(1920, 1080, { keyboard = false }))
check(not console.compact and console.slots == 10 and console.hot == HOT
		and console.cashStyle == CFG.CashStyle.Desktop,
	"no keyboard and no touch keeps the desktop arrangement, its faces and ten slots")

--==============================================================================
-- THE DESKTOP FACES ARE THE NUMBERS THAT SHIPPED
--
-- The card's and the cash block's sizes were literals inside LoadoutUI and
-- CashUI until 2026-09-22, when the compact faces needed them named. Every one
-- is pinned here to the value it had as a literal, so the desktop strip and
-- the desktop cash block are drawn exactly as they were.
--==============================================================================
-- THE APPROVED LOOK (2026-10-01, the owner's reference): 64-px squares, 4 apart,
-- no tray, a 1-px edge, 6-px corners, the preview nearly the whole slot, a
-- 12-px number, the Bag a square of the same size; the name band 22 over it.
local SHIPPED_HOT = {
	SlotWidth = 64, SlotHeight = 64, Gap = 4, TrayPad = 0, BottomGap = 10,
	ChipWidth = 64, BagGap = 2, CardCorner = 6, CardStroke = 1,
	PreviewInset = 3, PreviewTop = 4, PreviewHeight = 56,
	NumeralSize = 12, NumeralInset = 4, StackSize = 10, StackInset = 3,
	HeldLift = 3, LitThickness = 2, AccentHeight = 2, AccentBottom = 3,
	BagIcon = 34, BagIconTop = 5, BagCountTop = 43, BagCountSize = 12,
	NamePopupHeight = 22, NamePopupGap = 4,
}
local hotDiff = {}
for key, want in pairs(SHIPPED_HOT) do
	if HOT[key] ~= want then
		table.insert(hotDiff, key .. " = " .. tostring(HOT[key]))
	end
end
check(#hotDiff == 0 and HudLayout.hotMetrics(false) == HOT
		and HudLayout.hotbarWidth(10, true) == 750 and HudLayout.hotbarHeight() == 64,
	"the desktop card's numbers are the approved look's, read from GameConfig.Hotbar itself: ten squares and the Bag, 750 x 64",
	table.concat(hotDiff, ", "))
check(HOT.PlateTransparency > 0.2 and HOT.PlateTransparency < 0.6 and HOT.EmptyPlateTransparency >= 0.8
		and HOT.EmptyEdgeTransparency >= 0.8 and HOT.EmptyNumeralTransparency >= 0.5
		and HOT.PreviewTop + HOT.PreviewHeight <= HOT.SlotHeight - HOT.AccentBottom
		and HOT.BagIconTop + HOT.BagIcon <= HOT.BagCountTop
		and HOT.BagCountTop + HOT.BagCountSize + 4 <= HOT.SlotHeight,
	"a translucent plate, an empty slot barely there, the preview and the accent inside the slot, the Bag's icon over its count")

local SHIPPED_CASH = {
	Reserve = 232, Drop = 2, SpeedSize = 39, CashSize = 47, SpeedX = 56, SpeedW = 260,
	SpeedBottom = 44, CashW = 300, SpeedStroke = 2, CashStroke = 3, ShoeScale = 1, ShoeBottom = 44,
	BuffSize = 46, BuffHit = 46, BuffGap = 10, BuffMinX = 120, BuffDrop = 2, TipSize = 15,
	-- The message's old `2 - BUFF_SIZE - 4` off the root's bottom edge.
	TipLift = 48, BuffCorner = 10,
}
local DESK = CFG.CashStyle.Desktop
local cashDiff = {}
for key, want in pairs(SHIPPED_CASH) do
	if DESK[key] ~= want then
		table.insert(cashDiff, key .. " = " .. tostring(DESK[key]))
	end
end
check(#cashDiff == 0 and DESK.Root == Vector2.new(316, 108) and CFG.CashRoot == DESK.Root
		and CFG.CashReserve == DESK.Reserve and CFG.CashDrop == DESK.Drop,
	"the desktop cash face is CashUI's shipped numbers: 316 x 108, 39 and 47, the 46-px card 10 px off the text",
	table.concat(cashDiff, ", "))

-- A narrow desktop window: the old overlap is the cash block beside the strip.
-- The 1024 x 600 class went compact on the afternoon of 2026-10-09 (Garden and
-- the Bag had no room at the left edge between OTHER PLANTS and the lifted cash
-- block); with the three at the right edge since that evening it keeps the
-- desktop again: its cash block over the strip's name band, clean.
local narrow = HudLayout.solve(screen(1000, 609))
check(not narrow.compact and narrow.column == true and narrow.slots == 10
		and (narrow.cash.y + narrow.cash.h + CFG.Gap <= narrow.namePopup.y
			or narrow.cash.x + narrow.cash.w + CFG.Gap <= narrow.hotbar.x)
		and #HudLayout.problems(narrow) == 0,
	"a 1000x609 desktop window keeps the desktop (the three at the right edge), ten slots, and the cash block "
		.. "clears the strip",
	r2s(narrow.cash) .. " vs " .. r2s(narrow.hotbar) .. " " .. table.concat(HudLayout.problems(narrow), "; "))
check(HudLayout.solve(screen(1268, 720)).cash.y == HudLayout.solve(screen(1920, 720)).cash.y,
	"from 1268 px wide the cash block never moves off its corner")
do
	local small = HudLayout.solve(screen(1024, 600))
	check(not small.compact and small.column == true and small.slots == 10
			and (small.cash.y + small.cash.h + CFG.Gap <= small.namePopup.y
				or small.cash.x + small.cash.w + CFG.Gap <= small.hotbar.x)
			and #HudLayout.problems(small) == 0,
		"a 1024x600 desktop keeps the desktop too, ten slots, the cash block clear of the strip, nothing overlapping",
		r2s(small.cash) .. " " .. table.concat(HudLayout.problems(small), "; "))
	local tall = HudLayout.solve(screen(1024, 768))
	check(not tall.compact and tall.column == true and #HudLayout.problems(tall) == 0,
		"a 1024x768 desktop keeps the desktop, the three at the right edge", r2s(tall.index))
end
local short = HudLayout.solve(screen(1400, 400))
check(short.compact and short.slots == 10 and #HudLayout.problems(short) == 0,
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
	-- Listed 2026-10-03, with the chooser gone: Studio's 705 x 338 emulation, which
	-- only failed for the chooser, and a 640 x 360 phone.
	{ 705, 338 }, { 640, 360 },
}
-- The same screens with the notch and home-indicator insets a real iPhone
-- takes off in landscape: 62/62/21 on the 16 Pro and Pro Max, 48/48/21 on the
-- XR and 11. A HUD ScreenGui's AbsoluteSize is what is left.
local NOTCHED = {
	{ 874, 402, 62, 21, "iPhone 16 Pro" },
	{ 956, 440, 62, 21, "iPhone 16 Pro Max" },
	{ 896, 414, 48, 21, "iPhone 11" },
	{ 844, 390, 47, 21, "iPhone 12/13/14" },
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
-- The phones too narrow for the guide's block to end Guide.Clear short of the middle,
-- and those where its least width reaches past Reach or 20 px short of the middle.
local guideNear = {}
local guidePast = {}
-- How wide each phone's row draws BIOMES and OBBY, and where ADMIN stands.
local rowTiers = {}
-- How large each phone's panel row draws its squares, and the column under it.
local panelTiles = {}
local columnSizes = {}
for _, case in ipairs(cases) do
	local L = HudLayout.solve(case.input)
	local tag = case.tag
	local sw, sh = L.safe.X, L.safe.Y
	local problems = HudLayout.problems(L)
	check(L.compact and L.slots == 5 and L.fits and #problems == 0,
		tag .. ": compact, five slots, every group clear by 8 px and inside the margin",
		table.concat(problems, "; "))

	-- the rail on a touch screen: Shop top-left with the two switches under it,
	-- and in the top-right corner (the owner, 2026-10-09: "(Night Day) /
	-- <sidebar / Index / Garden / Inventory") the panel as ONE ROW -- INVITE,
	-- EVENTS, WHAT'S NEW and Settings in that order, Panel.Gap apart -- with its
	-- "<" handle at the row's left end; Panel.Tile where the row's left end keeps
	-- RowClear right of the middle (the boost row's room), smaller to keep it,
	-- never under MinTile (InviteHudSpec holds the rest).
	local PP = CFG.Phone.Panel
	local dock, view = L.dock, L.dockView
	local tiles = { L.invite, L.events, L.updates, L.settings }
	local row = L.sidebar and dock ~= nil and view ~= nil and L.handle ~= nil and L.boost == nil
		and L.chooser == nil and L.equipment == nil
	for i, c in ipairs(tiles) do
		row = row and c.w == tiles[1].w and c.h == c.w and c.w >= PP.MinTile and c.w <= PP.Tile
			and c.y == CFG.Margin + PP.Pad and (i == 1 or c.x - (tiles[i - 1].x + tiles[i - 1].w) == PP.Gap)
	end
	local tile = L.invite.w
	local fixedW = CFG.Margin + PP.HandleH + PP.HandleGap + PP.Gap * (PP.Count - 1) + PP.Pad * 2
	local wantTile = math.clamp(math.floor((sw / 2 - PP.RowClear - fixedW) / PP.Count), PP.MinTile, PP.Tile)
	check(row and view ~= nil and L.handle ~= nil and tile == wantTile and view.x + view.w == sw - CFG.Margin
			and view.y == CFG.Margin and view.h == tile + PP.Pad * 2 and L.invite.x == view.x + PP.Pad
			and L.settings.x + L.settings.w + PP.Pad == view.x + view.w
			and L.handle.x + L.handle.w + PP.HandleGap == view.x and L.handle.y == view.y and L.handle.h == view.h
			and L.handle.w == PP.HandleH and L.railBottom == view.y + view.h and L.rightLeft == L.index.x
			and (L.handle.x >= sw / 2 + PP.RowClear - 1e-6 or tile == PP.MinTile),
		tag .. ": the panel is one row in the top-right corner -- INVITE, EVENTS, WHAT'S NEW, Settings -- its \"<\" "
			.. "handle at its left end; Tile where its left end keeps RowClear right of the middle, never under MinTile",
		dock and (r2s(dock) .. " tile " .. tostring(tile)))
	check(dock ~= nil and dock.y + dock.h + 8 <= L.jump.y,
		tag .. ": the panel ends 8 px above the jump button", dock and (L.jump.y - dock.y - dock.h))
	panelTiles[tag] = L.events.w
	check(L.shop.x == CFG.Margin and L.shop.y == CFG.Margin and L.shop.w == CFG.Phone.Shop.X
			and L.shop.h == CFG.Phone.Shop.Y,
		tag .. ": Shop stands in the top-left corner at its picture's own size", r2s(L.shop))
	-- OTHER PLANTS and WALK MODE (the owner, 2026-10-05): see-through rows under
	-- Shop, OTHER PLANTS first, a group's 8 px apart, at the margin -- and up
	-- where a thumb on the movement stick never reaches, 8 px over its zone.
	do
		local SW = CFG.Phone.Switch
		check(L.switchInline == true and L.others.x == CFG.Margin and L.walk.x == CFG.Margin
				and L.others.w == SW.W and L.others.h == SW.H and L.walk.w == SW.W and L.walk.h == SW.H
				and L.others.y == L.shop.y + L.shop.h + CFG.Gap and L.walk.y == L.others.y + L.others.h + SW.Gap
				and SW.Gap >= 8 and L.walk.y + L.walk.h + 8 <= L.thumb.y
				and HudLayout.gap(L.walk, L.jump) >= 8,
			tag .. ": OTHER PLANTS and WALK MODE are see-through rows under Shop, OTHER PLANTS first, 8 px "
				.. "apart, ending 8 px above the thumbstick",
			r2s(L.others) .. " " .. r2s(L.walk))
	end
	-- INDEX, GARDEN AND THE BAG (2026-10-09): one over another in that order
	-- under the row, centred under Settings, Column.Gap apart, 8 px under the
	-- row; Column.Size, shrinking to stand 8 px over the jump button (and the
	-- belt's band, a trap's REMOVE row up, where that shares the column), never
	-- under MinSize. The centre left is free again.
	do
		local C = CFG.Phone.Column
		local mid = L.settings.x + L.settings.w / 2
		local floorY = sh - CFG.Margin
		for _, other in ipairs({ L.jump, HudLayout.hotbarBand(L.hotbar, HudLayout.removeRowHeight(true) + HOT.RemoveGap) }) do
			if other.x < mid + C.Size / 2 + CFG.Gap and other.x + other.w + CFG.Gap > mid - C.Size / 2 then
				floorY = math.min(floorY, other.y - CFG.Gap)
			end
		end
		local s = L.index.w
		local wantS = math.clamp(math.floor((floorY - (L.railBottom + CFG.Gap) - C.Gap * 2) / 3), C.MinSize, C.Size)
		check(L.column == true and L.pairRow ~= true and s == wantS and L.index.h == s and L.garden.w == s
				and L.garden.h == s and L.bag.w == s and L.bag.h == s and L.index.x == mid - s / 2
				and L.garden.x == L.index.x and L.bag.x == L.index.x and L.index.y == L.railBottom + CFG.Gap
				and L.garden.y == L.index.y + s + C.Gap and L.bag.y == L.garden.y + s + C.Gap
				and L.bag.y + s <= floorY + 1e-6,
			tag .. ": Index, Garden and the Bag one over another 8 px under the row, centred under Settings, "
				.. "Column.Size shrinking to stand 8 px over the jump button, never under MinSize",
			r2s(L.index) .. " " .. r2s(L.garden) .. " " .. r2s(L.bag) .. string.format(" floor %.0f", floorY))
		columnSizes[tag] = s
	end
	-- THE OWNER'S SMALL PILLS (2026-10-09: "shrink the badges"): 22 px tall, two
	-- digits' width reserved, on the top-RIGHT corners Over past them so the
	-- pictures show -- Index's level with its top (8 px under the row), Garden's
	-- over the gap above it -- and on the glass.
	local PB = CFG.Phone.Badge
	local indexBadge, gardenBadge = HudLayout.badges(L)
	check(PB.Size == 22 and PB.Text >= 12 and indexBadge.h == PB.Size and gardenBadge.h == PB.Size
			and indexBadge.w == PB.Reserve and gardenBadge.w == PB.Reserve
			and indexBadge.y == L.index.y and indexBadge.x + indexBadge.w == L.index.x + L.index.w + PB.Over
			and gardenBadge.y == L.garden.y - PB.Over
			and gardenBadge.x + gardenBadge.w == L.garden.x + L.garden.w + PB.Over
			and gardenBadge.y >= L.index.y + L.index.h and indexBadge.x + indexBadge.w <= sw
			and indexBadge.y >= L.railBottom + CFG.Gap,
		tag .. ": the badges are the owner's small pills on the top-RIGHT corners -- Index's level with its top, "
			.. "8 px under the row; Garden's over the gap above it; on the glass",
		r2s(indexBadge) .. " " .. r2s(gardenBadge))

	-- the hotbar
	local thumb, jump = L.thumb, L.jump
	check(thumb ~= nil and jump ~= nil, tag .. ": the thumbstick and jump button are reserved")
	check(L.hot == COMPACT_HOT and L.slots == 5 and L.hotbar.w == HudLayout.hotbarWidth(5, L.chip, true)
			and L.hotbar.h == HudLayout.hotbarHeight(true)
			and L.hot.SlotWidth >= 44 and L.hot.SlotHeight >= 44
			and L.hotbar.y + L.hotbar.h == sh - HOT.BottomGap,
		tag .. ": the strip is the compact belt, five 52-px squares on the bottom edge", r2s(L.hotbar))
	check(L.namePopup.x == L.hotbar.x and L.namePopup.w == L.hotbar.w
			and L.namePopup.y + L.namePopup.h + HOT.NamePopupGap == L.hotbar.y
			and (L.toastTop or L.toast.y + L.toast.h + 8 <= L.namePopup.y)
			and HudLayout.gap(L.namePopup, L.cash) >= 8,
		tag .. ": the item name's band stands over the belt, clear of the notices and the cash",
		r2s(L.namePopup))
	check(math.abs((L.hotbar.x + L.hotbar.w / 2) - sw / 2) <= 8,
		tag .. ": and within 8 px of the middle",
		(L.hotbar.x + L.hotbar.w / 2) - sw / 2)
	check(HudLayout.gap(L.hotbar, thumb) >= 8 and HudLayout.gap(L.hotbar, jump) >= 8,
		tag .. ": clear of both thumbs",
		string.format("%.1f / %.1f", HudLayout.gap(L.hotbar, thumb), HudLayout.gap(L.hotbar, jump)))

	-- cash: the phone's face in the very corner -- 12 in and 10 up, level with
	-- the belt's bottom -- on the thumbstick's ring by the owner's approval of
	-- 2026-09-24; 8 px over the belt only where the corner would meet it.
	local face = L.cashStyle
	local inCorner = L.cash.x == CFG.CashLeft and L.cashRoot.y + L.cashRoot.h == sh - HOT.BottomGap
	local overBelt = L.cash.x == CFG.CashLeft and L.cash.y + L.cash.h + 8 == L.hotbar.y
	check(face == CFG.CashStyle.Phone and L.cash.w >= face.Reserve
			and L.cash.h == face.Root.Y + face.Drop
			and L.cashRoot.w == face.Root.X and L.cashRoot.h == face.Root.Y
			and (inCorner or overBelt) and HudLayout.gap(L.cash, L.hotbar) >= 8
			and L.cash.y >= L.walk.y + L.walk.h + 8,
		tag .. ": the cash block wears the phone's face in the bottom-left corner, clear of the belt and under "
			.. "the switches",
		r2s(L.cash))
	-- The cash line's outline draws left of the root: measured live, the "$"
	-- reached x = 5 when the root sat on the plain 8 px margin. 3 px is the
	-- desktop's outline, the thicker of the two.
	check(L.cash.x - 3 >= CFG.Margin,
		tag .. ": and the first character's outline is still 8 px inside the safe edge", L.cash.x - 3)
	-- On the thumbstick's ring is approved; on the jump button is not.
	check(HudLayout.gap(L.cash, jump) >= 8 and not table.find(HudLayout.problems(L), "cash is 0.0 px from a touch control"),
		tag .. ": the cash block may stand on the thumbstick, never near the jump button",
		r2s(L.cash) .. " / " .. r2s(jump))
	-- (The x2 card rides the cash line since 2026-10-05: THE x2 CARD BESIDE THE
	-- CASH, after this loop, holds it on every phone with the pass and without.)

	--======================================================================
	-- THE FOOTPRINT
	--
	-- What the owner asked for on 2026-09-22, as limits: on the smallest
	-- listed safe area (772 x 302) the desktop's cards and cash block took
	-- 419 x 104 and 232 x 110 -- 18.7% and 10.9% of the screen, 29.6%
	-- between them. The compact faces take 12.8% and 6.0%, and may not grow
	-- back past these bounds without this failing.
	--======================================================================
	local safeArea = sw * sh
	local hotShare = L.hotbar.w * L.hotbar.h / safeArea
	local cashShare = L.cash.w * L.cash.h / safeArea
	check(L.hotbar.w <= 360 and L.hotbar.h <= 88 and hotShare <= 0.14,
		tag .. ": the strip is at most 360 x 88 and 14% of the safe area",
		string.format("%s = %.1f%%", r2s(L.hotbar), hotShare * 100))
	check(L.cashRoot.w <= 220 and L.cashRoot.h <= 78 and cashShare <= 0.07,
		tag .. ": the cash block is at most 220 x 78 and its reservation 7% of the safe area",
		string.format("%s = %.1f%%", r2s(L.cash), cashShare * 100))
	check(hotShare + cashShare <= 0.20,
		tag .. ": the two together cover at most a fifth of the screen",
		string.format("%.1f%%", (hotShare + cashShare) * 100))

	-- the clock: on a phone a chip (2026-09-29), where it was 44% of the window --
	-- and since 2026-09-30 at the top row's RIGHT end, the owner's screenshot
	-- (BIOMES | TELEPORT TO PLOT | OBBY | ADMIN | the clock). Every listed
	-- phone's row holds the buttons.
	local clock = L.clock
	local bar = case.input.topbar
	local rowEnd = if L.rowHi then L.rowHi + (case.input.viewport.X - sw) / 2 else nil
	check(clock and L.topRow == true and rowEnd ~= nil and math.abs(clock.x + clock.w - rowEnd) < 0.01
			and clock.x >= bar.x + 8 and clock.x + clock.w <= bar.x + bar.w - 8
			and clock.w == CFG.Phone.Clock and clock.h == CFG.ClockHeight and L.clockChip == true
			and clock.w < case.input.viewport.X * 0.2,
		tag .. ": the clock is a chip -- under a fifth of the window -- at the row's right end, "
			.. "8 px clear of the topbar's end",
		clock and r2s(clock))

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
	-- Its words drawn smaller on a phone (owner, 2026-09-24), and since
	-- 2026-09-29 in the LEFT COLUMN rather than under the clock: right of Shop
	-- and the switches under it (until 2026-10-05, of the dock's handle), never
	-- past Guide.Reach of the width -- so the player's own forward view has
	-- nothing written across it. The step counter and Skip stand on one row
	-- above the words. Where that row is wider than the room it leaves (the
	-- 640-px phones) the block keeps its least width and may reach 8 px past
	-- the middle, no further.
	local ts = CFG.TutorialPhoneScale
	local GUIDE = CFG.Phone.Guide
	-- Under WALK MODE's row, and under the passing lines' band where the column
	-- starts lower (ADMIN hung under the clock, on the 640-px-wide phones).
	local guideTop = math.max(L.railBottom, (L.columnTop or 0) + CFG.Phone.NoticeTop + CFG.NoticeHeight) + 8
	-- The row above the words needs this much; the block is never narrower, and
	-- wider only while it ends Guide.Clear short of the middle of the screen.
	local leastGuide = CFG.Phone.Counter + 8 + CFG.Phone.Skip.X
	local atLeast = L.banner.w == leastGuide
	local within = L.banner.x + L.banner.w <= sw * GUIDE.Reach and L.banner.x + L.banner.w <= sw / 2 - 20
	check(ts < 1 and L.tutorialScale == ts and L.guide == true
			and L.banner.h == GUIDE.Height and L.banner.w <= GUIDE.Width
			and L.banner.w >= leastGuide
			and L.banner.x == L.railRight + 8 and L.railRight == L.walk.x + L.walk.w and L.banner.y == guideTop
			and (within or (atLeast and L.banner.x + L.banner.w <= sw / 2 + 8))
			and (atLeast or L.banner.x + L.banner.w <= sw / 2 - GUIDE.Clear),
		tag .. string.format(": the guide's words stand in the left column, drawn at %.2f, %g px wide at most, "
			.. "never past %.0f%% of the width, and %g px short of the middle wherever the row above them allows",
			ts, GUIDE.Width, GUIDE.Reach * 100, GUIDE.Clear),
		r2s(L.banner))
	if L.banner.w == leastGuide and L.banner.x + L.banner.w > sw / 2 - GUIDE.Clear then
		table.insert(guideNear, string.format("%s (%g px short)", tag, sw / 2 - L.banner.x - L.banner.w))
	end
	if not within then
		table.insert(guidePast, tag)
	end
	check(L.skip.w == CFG.Phone.Skip.X and L.skip.h == CFG.Phone.Skip.Y and L.skip.h == CFG.SkipSize.Y
			and L.skip.y == L.banner.y and L.skip.h <= GUIDE.Row
			and L.skip.x == L.banner.x + CFG.Phone.Counter + 8
			and L.skip.x + L.skip.w <= L.banner.x + L.banner.w,
		tag .. ": Skip stands on the row above the words, beside the step counter, as tall as it always was",
		r2s(L.skip))
	-- Two lines of instruction and two of advice fit under that row, as
	-- TutorialUI lays them out: 3 over each, 24 and 15 tall a line (LuckiestGuy's
	-- line is its size), 2 under -- at the phone's scale. The words themselves
	-- are measured further down (THE GUIDE'S WORDS, EVERY ONE).
	do
		local drawn = GUIDE.Height - GUIDE.Row
		local lines = ((3 + 2 * 24 + 2) + (3 + 2 * 15 + 2)) * ts
		check(drawn >= lines, tag .. ": the block holds two lines of instruction and two of advice",
			string.format("%.1f needed, %g there", lines, drawn))
	end

	-- THE TOP ROW (2026-09-29; in the owner's order since 2026-09-30; one even
	-- row since the owner's mobile corrections of 2026-10-05): BIOMES, PLOT and
	-- OBBY Phone.RowGap apart with PLOT on the screen's centre line (the owner,
	-- 2026-10-05 evening) -- every listed phone has the room -- each touch area
	-- exactly its plate drawn; ADMIN just left of the clock where the row has
	-- room for it, 8 px off it and off OBBY; the clock at the right end -- all
	-- in the topbar's band, inside its free span and the safe area across.
	do
		local originX = (case.input.viewport.X - sw) / 2
		local items = {
			{ "BIOMES", L.biomes }, { "TELEPORT", L.teleport }, { "OBBY", L.obby },
			{ "the clock", rect(clock.x - originX, clock.y - TOPBAR, clock.w, clock.h) },
		}
		local a = L.admin
		local hung = a ~= nil and a.y >= clock.y + clock.h
		if a and not hung then
			table.insert(items, 4, { "ADMIN", rect(a.x - originX, a.y - TOPBAR, a.w, a.h) })
		end
		local lo, hi = L.rowLo, L.rowHi
		local rowOk = L.topRow == true and lo ~= nil and hi ~= nil
		local note = ""
		for i, item in ipairs(items) do
			local r = item[2]
			if not rowOk or r.w <= 0 or r.x < lo - 1e-6 or r.x + r.w > hi + 1e-6
				or r.y + TOPBAR < 0 or r.y + r.h > 0
				or r.x + originX < bar.x + 8 - 1e-6 or r.x + r.w + originX > bar.x + bar.w - 8 + 1e-6
				or r.x < 8 - 1e-6 or r.x + r.w > sw - 8 + 1e-6 then
				rowOk = false
				note ..= " " .. item[1] .. " " .. r2s(r) .. " leaves the row"
			end
			for j = i + 1, #items do
				-- The three buttons are the one even row, RowGap apart; everything
				-- else keeps its 8 px.
				local least = if i <= 3 and j <= 3 then CFG.Phone.RowGap else 8
				if HudLayout.gap(r, items[j][2]) < least - 1e-6 then
					rowOk = false
					note ..= " " .. item[1] .. " meets " .. items[j][1]
				end
			end
		end
		-- In the owner's order: each button RowGap after the last from the row's
		-- start; the clock ending at the row's end; ADMIN, on the row, 8 px before it.
		local b, p, o = L.biomes, L.teleport, L.obby
		local c = items[#items][2]
		local RG = CFG.Phone.RowGap
		local ordered = rowOk and b.x >= lo - 1e-6 and math.abs(p.x + p.w / 2 - sw / 2) < 1e-6
			and math.abs(p.x - (b.x + b.w + RG)) < 1e-6
			and math.abs(o.x - (p.x + p.w + RG)) < 1e-6
			and math.abs(c.x + c.w - hi) < 1e-6
			and (hung or (a ~= nil and math.abs(a.x - originX + a.w + 8 - c.x) < 1e-6))
		if not ordered then
			rowOk = false
			note ..= " not in the owner's order"
		end
		-- One even row: the words alone, each plate drawn exactly its touch area,
		-- all three at the row's size or all three at the tight size.
		local k = L.teleportScale
		-- Each plate inset by its outline (RowStroke): drawn, the outline ends at the touch area's edge.
		local e = CFG.Phone.RowStroke * 2
		local function tierOf(sizes)
			return L.biomesPlate == Vector2.new(sizes.Biomes - e, 44 - e)
				and L.teleportPlate == Vector2.new(sizes.Plot - e, 44 - e)
				and L.obbyPlate == Vector2.new(sizes.Obby - e, 44 - e)
				and math.abs(b.w - sizes.Biomes * k) < 1e-6 and math.abs(p.w - sizes.Plot * k) < 1e-6
				and math.abs(o.w - sizes.Obby * k) < 1e-6
		end
		local tier = if L.biomesWide or L.obbyWide or not L.teleportShort then nil
			elseif tierOf(CFG.Phone.Row) then "words"
			elseif tierOf(CFG.Phone.RowTight) then "tight words"
			else nil
		if tier == nil then
			rowOk = false
			note ..= string.format(" widths %g / %g / %g match no tier", b.w, p.w, o.w)
		end
		rowTiers[tag] = (tier or "?") .. (if hung then ", ADMIN hung" else ", ADMIN on the row")
		check(rowOk, tag .. ": the top row -- BIOMES, PLOT, OBBY" .. (if hung then "" else ", ADMIN")
			.. ", the clock -- stands in the owner's order in the topbar's band, inside its free span and the "
			.. "safe area, the three buttons one even row " .. RG .. " px apart with PLOT on the screen's centre "
			.. "line, the rest 8", note)

		-- THE VIEW. What the owner asked for: "keeps the central play area
		-- clear". Nothing permanent stands in the middle third of the screen
		-- between the column's boost row and the belt, and what lasts in the
		-- column -- the boost row -- ends within 42 px of the topbar.
		local top = (L.columnTop or 0) + CFG.Phone.BoostTop + CFG.Phone.BoostHeight
		local view = rect(sw / 3, top, sw / 3, L.hotbar.y - 8 - top)
		local inView = {}
		for _, group in ipairs(HudLayout.groups(L, true)) do
			if HudLayout.gap(view, group.rect) < 0 then
				table.insert(inView, group.name .. " " .. r2s(group.rect))
			end
		end
		for _, zone in ipairs({ { "the thumbstick", thumb }, { "the jump button", jump },
			{ "BIOMES", L.biomes }, { "TELEPORT", L.teleport }, { "OBBY", L.obby } }) do
			if HudLayout.gap(view, zone[2]) < 0 then
				table.insert(inView, zone[1] .. " " .. r2s(zone[2]))
			end
		end
		-- (A hung ADMIN -- only where the row has no room for it -- starts the column
		-- right under it, and no lower.)
		local under = hung and a ~= nil and L.columnTop == a.y + a.h - TOPBAR
		check(#inView == 0 and L.columnTop ~= nil and (top <= 42 or under) and view.h >= sh * 0.45,
			tag .. ": nothing permanent stands in the middle third of the screen, from the boost row to the belt",
			string.format("view %s: %s", r2s(view), table.concat(inView, ", ")))
	end

	-- the report: every group, and the smallest gap between any two
	local groups = HudLayout.groups(L, true)
	table.insert(groups, { name = "thumb", rect = thumb })
	table.insert(groups, { name = "jump", rect = jump })
	local least, pair = math.huge, ""
	for i = 1, #groups do
		for j = i + 1, #groups do
			-- The thumbs are one control each side, and the handle is on the
			-- dock's edge by design; neither pair is a gap. The cash block on the
			-- thumbstick's ring is the owner's approved overlap (2026-09-24): it
			-- takes no input, and every other pair still keeps its 8 px.
			local names = groups[i].name .. "/" .. groups[j].name
			if names ~= "thumb/jump" and names ~= "dock/handle" and names ~= "cash/thumb" then
				local apart = HudLayout.gap(groups[i].rect, groups[j].rect)
				if apart < least then
					least, pair = apart, names
				end
			end
		end
	end
	worstGap = math.min(worstGap, least)
	local line = {}
	for _, group in ipairs(groups) do
		table.insert(line, group.name .. r2s(group.rect))
	end
	say(string.format("    %s  safe %dx%d  min gap %.1f (%s)  strip %.1f%%  cash %.1f%%",
		tag, sw, sh, least, pair, hotShare * 100, cashShare * 100))
	say("      " .. table.concat(line, " "))
end
check(worstGap >= 8, "the smallest gap on any listed phone is at least 8 px", worstGap)
do
	local lines = {}
	for _, case in ipairs(cases) do
		table.insert(lines, case.tag .. ": " .. tostring(rowTiers[case.tag]))
	end
	say("  (the top row's BIOMES and OBBY, by phone -- " .. table.concat(lines, "; ") .. ")")
	-- The owner's own session is the screenshot's: the words, and ADMIN on the row.
	check(rowTiers["801x392 the owner's session"] == "words, ADMIN on the row",
		"the owner's session draws the row as the screenshot does: BIOMES and OBBY as words, ADMIN on the row",
		rowTiers["801x392 the owner's session"])
end
do
	local lines = {}
	for _, case in ipairs(cases) do
		table.insert(lines, case.tag .. ": " .. tostring(panelTiles[case.tag]) .. " / "
			.. tostring(columnSizes[case.tag]))
	end
	say("  (the panel row's squares / Index, Garden and the Bag, by phone -- " .. table.concat(lines, "; ") .. ")")
	-- The owner's numbers (2026-10-09): 36 on 705 x 338, 40 on every other listed phone.
	local only705 = true
	for _, case in ipairs(cases) do
		local want = if string.find(case.tag, "^705x338") then 36 else CFG.Phone.Column.Size
		only705 = only705 and columnSizes[case.tag] == want
	end
	check(only705, "Index, Garden and the Bag are 36 px on 705 x 338 and 40 on every other listed phone")
end
say("  (the guide's block is at its least width, and nearer the middle than Guide.Clear, on: "
	.. (if #guideNear > 0 then table.concat(guideNear, ", ") else "none") .. ")")
do
	local only = true
	for _, tag in ipairs(guideNear) do
		only = only and (string.find(tag, "^640x") ~= nil or string.find(tag, "^705x") ~= nil)
	end
	check(only, "only the 640- and 705-px-wide phones have the guide's block nearer the middle than Guide.Clear",
		table.concat(guideNear, ", "))
	local past = true
	for _, tag in ipairs(guidePast) do
		past = past and string.find(tag, "^640x") ~= nil
	end
	check(past, "only the 640-px-wide phones have it reach past the middle (by 8 px at most)",
		table.concat(guidePast, ", "))
end

--==============================================================================
-- 2b. THE COMPACT FACES THEMSELVES
--
-- The belt and the cash block a phone gets, held to the owner's brief of
-- 2026-09-22 and to the geometry inside them: nothing in a card meets anything
-- else, every press is a thumb's size, and every word that can appear fits.
--==============================================================================
say("-- the compact faces --")
local C = COMPACT_HOT
local tray = HudLayout.hotbarHeight(true)
-- THE APPROVED LOOK'S PHONE FACE (2026-10-01): five squares since 2026-10-03, and
-- the Bag, no tray.
check(C.SlotWidth >= 48 and C.SlotWidth <= 56 and C.SlotHeight == C.SlotWidth and tray == C.SlotHeight
		and C.Gap >= 3 and C.Gap <= 4 and C.NumeralSize >= 9 and C.NumeralSize <= 11
		and C.PreviewHeight >= 42 and C.PreviewHeight <= 48 and C.ChipWidth == C.SlotWidth
		and HudLayout.hotbarWidth(5, true, true) <= 340,
	"the compact belt is in the brief's bands: 48-56 px squares, no tray, 3-4 gaps, a 9-11 number, a 42-48 preview, a Bag cell the slot's size, five and the Bag under 340 wide",
	string.format("%dx%d tray %d gap %d number %d preview %d bag %d width %d", C.SlotWidth, C.SlotHeight,
		tray, C.Gap, C.NumeralSize, C.PreviewHeight, C.ChipWidth, HudLayout.hotbarWidth(5, true, true)))
check(C.TrayPad == 0 and C.CardStroke == HOT.CardStroke and C.CardCorner == HOT.CardCorner
		and C.PlateTransparency == HOT.PlateTransparency,
	"no tray, and the desktop's thin edge, small corners and translucent plate")
check(C.SlotWidth >= 44 and C.SlotHeight >= 44 and C.ChipWidth >= 44
		and CFG.CashStyle.Compact.BuffHit >= 44,
	"every compact press is at least 44 x 44: a card, the Bag cell, and the x2 card's touch area")
check(C.PreviewTop + C.PreviewHeight <= C.SlotHeight - C.AccentBottom
		and C.StackInset + C.StackSize + 3 <= C.SlotHeight
		and C.BagIconTop + C.BagIcon <= C.BagCountTop and C.BagCountTop + C.BagCountSize + 4 <= C.SlotHeight,
	"inside a compact card nothing meets: the preview over the accent, the stack count in the corner, the Bag's icon over its count")

-- The widest stack count the tickets can show, at the compact size.
local stackWidth = TextService:GetTextSize("x999", C.StackSize, Enum.Font.FredokaOne, Vector2.new(400, 40)).X
check(stackWidth <= C.SlotWidth - C.StackInset * 2 - C.NumeralInset,
	"a three-figure stack count fits the compact slot's corner", stackWidth)

-- The compact belt is ONE table every compact answer shares, with every key the
-- desktop card has -- the colours too -- and no key the desktop lacks.
local a = HudLayout.solve(screen(801, 392, { touch = true })).hot
local b = HudLayout.solve(screen(956, 440, { touch = true, keyboard = false })).hot
check(a == b and a == COMPACT_HOT and a ~= HOT,
	"every compact answer carries the same belt table, so an owner redraws only on a change of face")
local missing, unknown = {}, {}
for key in pairs(HOT) do
	if COMPACT_HOT[key] == nil then
		table.insert(missing, key)
	end
end
for key in pairs(HOT.Compact) do
	if HOT[key] == nil then
		table.insert(unknown, key)
	end
end
check(#missing == 0, "the belt has every key the desktop card has", table.concat(missing, ", "))
check(#unknown == 0, "and the Compact block names no key the desktop card lacks, where a typo would be ignored",
	table.concat(unknown, ", "))

-- The compact cash face.
local CC = CFG.CashStyle.Compact
check(CC.Root.X >= 190 and CC.Root.X <= 220 and CC.Root.Y >= 68 and CC.Root.Y <= 78
		and CC.SpeedSize >= 25 and CC.SpeedSize <= 29 and CC.CashSize >= 33 and CC.CashSize <= 37
		and 50 * CC.ShoeScale >= 30 and 50 * CC.ShoeScale <= 34
		and CC.BuffSize >= 34 and CC.BuffSize <= 40 and CC.BuffHit >= 44,
	"the compact cash face is in the brief's bands: 190-220 x 68-78, speed 25-29, cash 33-37, a 30-34 shoe, a 34-40 card in a 44+ touch area")
local reserveOk = true
local reserveNote = {}
for _, face in ipairs({ DESK, CC }) do
	local widest = TextService:GetTextSize("$9.99Qa", face.CashSize, Enum.Font.LuckiestGuy,
		Vector2.new(4000, 200)).X
	local reach = math.floor(widest) + face.BuffGap + (face.BuffSize + face.BuffHit) / 2
	reserveOk = reserveOk and reach <= face.Reserve
	table.insert(reserveNote, string.format("%.0f of %d", reach, face.Reserve))
end
check(reserveOk, "in both faces the reservation holds the widest balance with the card and its touch area",
	table.concat(reserveNote, ", "))
local facesOk = true
for _, face in ipairs({ DESK, CC }) do
	facesOk = facesOk
		and face.SpeedBottom <= face.Root.Y - (face.CashSize + 4)
		and face.ShoeBottom - 38 * face.ShoeScale >= 0 and 50 * face.ShoeScale <= face.SpeedX
		and face.SpeedX + face.SpeedW <= face.Root.X and face.CashW <= face.Root.X
		and face.BuffDrop + (face.BuffHit - face.BuffSize) / 2 <= face.Drop
end
check(facesOk, "in both faces the speed line ends above the cash line, the shoe stays in the block, and the card's touch area is inside the reserved group")

-- A desktop window dragged into compact wears the compact faces too: the face
-- is the layout's, never TouchEnabled's.
local dragged = HudLayout.solve(screen(860, 700, { touch = false }))
check(dragged.compact and dragged.hot == COMPACT_HOT and dragged.cashStyle == CC,
	"a desktop window dragged into compact wears the compact faces -- decided by the layout, not by touch")

-- Rotating and resizing a phone never changes its slot count.
local counts = {}
for _, case in ipairs(cases) do
	counts[HudLayout.solve(case.input).slots] = true
end
check(counts[5] and not counts[4] and not counts[10],
	"every phone case is five slots, so resizing or rotating one never moves a key")

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
-- On a phone the name stands at the top of the centre column (2026-09-29):
-- TELEPORT TO PLOT is up beside the clock, the boost row is the first thing
-- under the topbar and the passing lines' band the second -- and the guide's
-- words are in the left column, 8 px clear, so a beginner keeps their
-- instructions while the name goes by (BiomeGuideUI).
local centred, clear, spared, noteMiss = true, true, true, ""
for _, case in ipairs(cases) do
	local L = HudLayout.solve(case.input)
	local dx, top = HudLayout.notice(L, widest, 30, 50 - TOPBAR)
	local box = rect(L.safe.X / 2 + dx - widest / 2, top, widest, 30)
	local want = if L.sidebar then L.columnTop + CFG.Phone.NoticeTop else 50 - TOPBAR
	if not (dx == 0 and top == want) then
		centred = false
		noteMiss ..= case.tag .. string.format(" dx %.1f top %.1f; ", dx, top)
	end
	for _, group in ipairs(HudLayout.groups(L, true)) do
		if HudLayout.gap(box, group.rect) < 8 then
			clear = false
			noteMiss ..= case.tag .. " meets " .. group.name .. "; "
		end
	end
	if HudLayout.gap(box, L.teleport) < 8 then
		clear = false
		noteMiss ..= case.tag .. " meets TELEPORT; "
	end
	if L.sidebar and (HudLayout.gap(box, L.banner) < 8 or HudLayout.gap(box, L.skip) < 8) then
		spared = false
		noteMiss ..= case.tag .. " meets the tutorial banner " .. r2s(L.banner) .. "; "
	end
end
check(spared, "on a phone the guide's words keep 8 px off the name, so the instructions stay up while it goes by",
	noteMiss)
do
	-- The phone's cash face (owner, 2026-09-24): compact's lines and shoe at 0.85.
	local P, K = CFG.CashStyle.Phone, CFG.CashStyle.Compact
	check(P ~= nil and P.SpeedSize == math.round(K.SpeedSize * 0.85) and P.CashSize == math.round(K.CashSize * 0.85)
			and math.abs(P.ShoeScale - K.ShoeScale * 0.85) < 0.001 and P.Root.X == math.round(K.Root.X * 0.85)
			and P.TipSize == K.TipSize and P.BuffHit == K.BuffHit and P.BuffSize == K.BuffSize,
		"the phone's cash face is compact's at 0.85 (speed 23, cash 30), the x2 button's numbers untouched")
end
check(centred, "the widest name stays centred on every listed phone -- at the top of the centre column there", noteMiss)
check(clear, "and clears both top rows and the teleport button by 8 px on all of them", noteMiss)
-- A top band too narrow for the widest name: a small desktop window's compact
-- rows, and a phone just too narrow for it -- both sized off the measured name,
-- so centring it is impossible and sliding it between the rows is not. (A 560 x
-- 320 PHONE is no longer such a case: its top-left row is only Walk Mode now,
-- and the name stays centred. Nor, since 2026-10-04, a 560 x 320 WINDOW: its
-- row is three squares now, Walk Mode's switch standing left of EVENTS.)
local squeezed = math.floor(widest + 336)
local squeezedWindow = math.floor(widest + 330)
for _, input in ipairs({ screen(squeezedWindow, 320, { touch = false }), screen(squeezed, 400, { touch = true }) }) do
	local tiny = HudLayout.solve(input)
	local dx, top = HudLayout.notice(tiny, widest, 30, 50 - TOPBAR)
	local box = rect(tiny.safe.X / 2 + dx - widest / 2, top, widest, 30)
	local apart, meets = true, ""
	for _, group in ipairs(HudLayout.groups(tiny, true)) do
		if HudLayout.gap(box, group.rect) < 8 then
			apart = false
			meets ..= " meets " .. group.name
		end
	end
	check((dx ~= 0 or top ~= 50 - TOPBAR) and apart,
		string.format("%dx%d%s: where it cannot stay centred between the rows it moves rather than overlap them",
			input.viewport.X, input.viewport.Y, if input.touch then " phone" else " window"),
		string.format("dx %.1f top %.1f box %s%s", dx, top, r2s(box), meets))
end

--==============================================================================
-- 4. THE CLOCK ON A SCREEN WHERE THE TOPBAR BITES
--==============================================================================
say("-- the clock --")
local squeezed = HudLayout.solve(screen(640, 480, { touch = true, barLeft = 250 }))
local c = squeezed.clock
check(c and c.x >= 258 and c.x + c.w <= 632 and c.w == CFG.Phone.Clock,
	"with Roblox buttons out to 250 px a phone's chip still stands clear of them, whole",
	c and r2s(c))
-- A free span that starts past the middle: the chip slides the least it can.
do
	-- (Out to 500: since the even row of 2026-10-05 a span from 408 holds the row.)
	local slid = HudLayout.solve(screen(772, 360, { touch = true, barLeft = 500 }))
	local s = slid.clock
	check(s and s.x == 508 and s.w == CFG.Phone.Clock and s.x + s.w <= 772 - 8 and not slid.topRow,
		"with Roblox buttons out past the middle the chip slides to the free span's edge and keeps its width",
		s and r2s(s))
end
-- A desktop window where the topbar bites keeps the old rule: narrower, then slid.
do
	local bitten = HudLayout.solve(screen(640, 480, { touch = false, barLeft = 250 })).clock
	check(bitten and bitten.x >= 258 and bitten.x + bitten.w <= 632 and bitten.w >= CFG.ClockFloor,
		"and a window that is not a phone still gets the bar: narrower, then slid, never over the buttons",
		bitten and r2s(bitten))
end

--==============================================================================
-- 5. A MEASURED CASH BLOCK WIDER THAN ITS RESERVATION STILL PLACES CLEAR
--==============================================================================
local wide = HudLayout.solve(screen(1000, 609, { touch = true, cashWidth = 300 }))
check(wide.cash.w == 300 and #HudLayout.problems(wide) == 0,
	"a cash block measured at 300 px is placed at 300 px, clear of everything",
	table.concat(HudLayout.problems(wide), "; "))

--==============================================================================
-- 5b. THE BAG PANEL: THE COMPACT GRID (2026-10-03, the owner's spec)
--
-- HudLayout.bag is the arithmetic LoadoutUI applies, `hotTop` the name band's
-- top as layoutBag passes it. On every desktop size, every listed phone and a
-- small window: the panel inside the safe area; five category buttons 34 px or
-- taller down the left; at least one whole row of tiles; the search box 140 px
-- or wider and clear of the title, the heart and the close button; the footer
-- inside the body. And every name the game shows on a tile fits it in two lines
-- at the smallest size it is drawn.
--==============================================================================
say("-- the bag --")
local BAGC = CFG.Bag
local OUTLINE = RAIL.OutlineThickness
local titleWidth = TextService:GetTextSize("Bag", 26, Enum.Font.LuckiestGuy, Vector2.new(1000, 100)).X

-- The header rule UIKit.modal applies: the title bar pads clear of the rail
-- band it shares rows with, and the close button moves in with it. The search
-- row is HudLayout.bagSearch's, as InventoryPanel places it.
local function header(L, bag)
	local shell = rect(bag.panel.x + OUTLINE, bag.panel.y + OUTLINE,
		bag.panel.w - OUTLINE * 2, bag.panel.h - OUTLINE * 2)
	local bar = rect(shell.x + 12, shell.y + 10, shell.w - 24, 40)
	local padLeft, padRight = 0, 0
	if bar.y + bar.h > L.railTop and bar.y < L.railBottom then
		padLeft = math.max(0, math.floor(L.railRight + 8 - bar.x))
		padRight = math.max(0, math.floor(bar.x + bar.w - (L.rightLeft - 8)))
	end
	local titleRect = rect(bar.x + padLeft, bar.y, titleWidth, bar.h)
	local close = rect(bar.x + bar.w - padRight - 44, bar.y + bar.h / 2 - 22, 44, 44)
	local s, h = HudLayout.bagSearch(bag, shell.w, titleWidth, padLeft, padRight)
	return shell, titleRect, rect(shell.x + s.x, shell.y + s.y, s.w, s.h),
		rect(shell.x + h.x, shell.y + h.y, h.w, h.h), close
end

local function bagHolds(tag, L, bag)
	local sw, sh = L.safe.X, L.safe.Y
	local p = bag.panel
	-- Half a pixel: the panel is centred on a whole pixel, so an odd size starts
	-- half a pixel inside the margin (the shipped arithmetic, unchanged).
	check(p.x >= 7.5 and p.y >= 7.5 and p.x + p.w <= sw - 7.5 and p.y + p.h <= sh - 7.5,
		tag .. ": the panel is inside the safe area", r2s(p))
	local col = bag.column
	check(bag.catH >= BAGC.CatMinH and 5 * bag.catH + 4 * bag.catGap <= col.h and col.w >= 100,
		tag .. ": five category buttons, 34 px or taller, down the left", string.format("%d tall in %s", bag.catH, r2s(col)))
	local tall = bag.rows * bag.tile.Y + (bag.rows - 1) * bag.gap + bag.pad * 2
	check(bag.rows >= 1 and tall <= bag.grid.h + 1e-6 and bag.columns >= 1
			and bag.grid.x >= col.x + col.w + 4 and bag.grid.x + bag.grid.w <= bag.body.w + 1e-6,
		tag .. ": at least one whole row of tiles beside the column", string.format("grid %s rows %d across %.1f",
			r2s(bag.grid), bag.rows, bag.columns))
	local f = bag.footer
	check(f.y >= bag.grid.y + bag.grid.h and f.y + f.h <= bag.body.h + 1e-6 and f.x + f.w <= bag.body.w + 1e-6
			and f.h >= 14,
		tag .. ": the storage line is a footer inside the body, under the grid", r2s(f))
	local _, title, search, heart, close = header(L, bag)
	local bodyTop = bag.body.y
	local clear = search.w >= BAGC.SearchMinW and search.h >= 34 and heart.w >= 34
		and HudLayout.gap(title, search) >= 4 and HudLayout.gap(search, heart) >= 4
		and HudLayout.gap(heart, close) >= 0 and HudLayout.gap(search, close) >= 4
		and search.y + search.h + 8 <= bodyTop + 1e-6
	-- On a phone the switch rows and the panel under the Bag step aside while a
	-- centre panel is open (WalkModeUI, OtherPlantsUI, RailDrawerUI): only the
	-- top-right row stays over its header.
	for _, g in ipairs(HudLayout.groups(L, true)) do
		if g.name == "garden+bag" or (g.name == "rail" and not L.sidebar) then
			clear = clear and HudLayout.gap(title, g.rect) >= 0 and HudLayout.gap(search, g.rect) >= 0
				and HudLayout.gap(heart, g.rect) >= 0 and HudLayout.gap(close, g.rect) >= 0
		end
	end
	check(clear, tag .. ": the search box (140+) and the heart stand clear of the title, the close button and the rail rows",
		string.format("title %s search %s heart %s close %s", r2s(title), r2s(search), r2s(heart), r2s(close)))
	say(string.format("    %s: panel %s  %s header  body %s  grid %s  %d row(s), %.1f across, buttons %d",
		tag, r2s(p), if bag.compactHeader then "one-row" else "two-row", r2s(bag.body), r2s(bag.grid),
		bag.rows, bag.columns, bag.catH))
end

-- Desktops: downward, above the strip and its name band; the review's numbers.
-- (1024 x 600, 1169 x 609 and 1000 x 609 go compact since 2026-10-09, below.)
local DESKTOP_GRIDS = {
	{ 1366, 768, 6, 4 }, { 1280, 720, 6, 3 }, { 1024, 768, nil, nil }, { 1920, 1080, nil, nil },
}
for _, case in ipairs(DESKTOP_GRIDS) do
	local L = HudLayout.solve(screen(case[1], case[2]))
	local tag = string.format("%dx%d desktop", case[1], case[2])
	local bag = HudLayout.bag(L, { hotTop = L.namePopup.y, stripHidden = L.touch })
	bagHolds(tag, L, bag)
	check(not L.compact and not bag.horizontal and bag.tile == BAGC.Tile and bag.panel.w <= BAGC.MaxW
			and bag.panel.h <= BAGC.MaxH and bag.panel.y + bag.panel.h + 8 <= L.namePopup.y,
		tag .. ": downward, 96 x 100 tiles, at most 860 x 600, 8 px above the strip's name band", r2s(bag.panel))
	if case[3] then
		check(math.floor(bag.columns) == case[3] and bag.rows == case[4],
			tag .. string.format(": %d tiles across and %d whole rows", case[3], case[4]),
			string.format("%.2f across, %d rows", bag.columns, bag.rows))
	end
end

-- Phones: the strip hidden, the panel down to the safe area's edge, sideways in
-- whole rows of the phone's taller tile.
local BAG_CASES = {
	{ tag = "iPhone 11 896x414", input = screen(896, 414, { touch = true }) },
	{ tag = "iPhone 11 896x414 notched", input = screen(896, 414, { touch = true, left = 48, right = 48, bottom = 21 }) },
	{ tag = "iPhone 16 Pro Max 956x440", input = screen(956, 440, { touch = true }) },
	{ tag = "Galaxy S22 Ultra 772x360", input = screen(772, 360, { touch = true }) },
	{ tag = "VGA 640x480", input = screen(640, 480, { touch = true }) },
	{ tag = "the owner's 801x392", input = screen(801, 392, { touch = true }) },
	{ tag = "Studio 705x338", input = screen(705, 338, { touch = true }) },
	{ tag = "844x390 notched", input = screen(844, 390, { touch = true, left = 47, right = 47, bottom = 21 }) },
	{ tag = "640x360", input = screen(640, 360, { touch = true }) },
}
for _, case in ipairs(BAG_CASES) do
	local L = HudLayout.solve(case.input)
	local bag = HudLayout.bag(L, { hotTop = L.namePopup.y, stripHidden = L.touch })
	bagHolds(case.tag, L, bag)
	check(bag.horizontal and bag.rows >= 1 and bag.tile == BAGC.TileCompact and bag.panel.y + bag.panel.h > L.hotbar.y,
		case.tag .. ": sideways, in whole rows of 96 x 116 tiles, over where the hidden strip was", r2s(bag.panel))
end

-- A small desktop window is compact without touch: the strip stays, so the Bag
-- still stops above it.
do
	-- And the 1024 x 600 class: compact on the afternoon of 2026-10-09, the
	-- desktop again since the three went to the right edge that evening -- the
	-- strip stays either way, and the Bag stops above it.
	for _, size in ipairs({ { 860, 700 }, { 1024, 600 }, { 1169, 609 }, { 1000, 609 } }) do
		local tag = string.format("%dx%d window", size[1], size[2])
		local L = HudLayout.solve(screen(size[1], size[2], { touch = false }))
		local bag = HudLayout.bag(L, { hotTop = L.namePopup.y, stripHidden = L.touch })
		bagHolds(tag, L, bag)
		check((L.compact or size[1] >= 1000) and not L.touch and L.slots == 10
				and bag.panel.y + bag.panel.h + 8 <= L.namePopup.y,
			tag .. ": a small desktop window keeps its strip, ten slots of it, and the Bag stops above it", r2s(bag.panel))
	end
end

-- Every name a tile shows, in two lines at the smallest size it is drawn: 10 pt
-- in the desktop's 88 x 26 box, 11 pt in the phone's 88 x 30. A pod is named by
-- its shell, never its species -- PlantInfo's titles.
do
	local WeaponData = require(Shared:WaitForChild("WeaponData"))
	local WheelData = require(Shared:WaitForChild("WheelData"))
	local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
	local names = { PlantInfo.PodTitle, "Secret pod", GameConfig.Community.TicketName .. "s", WheelData.Trail.Name }
	-- An ordinary pod is named by its biome since the Pod Guide (2026-10-09).
	local BiomeData = require(Shared:WaitForChild("BiomeData"))
	for _, biome in ipairs(BiomeData.Biomes) do
		table.insert(names, string.format(GameConfig.PodGuide.Words.BagTitle, biome.DisplayName))
	end
	for _, list in ipairs({ SeedData.Species, SeedData.SecretSpecies, SeedData.RainSpecies }) do
		for _, species in ipairs(list) do
			table.insert(names, species.Name)
		end
	end
	for _, pod in pairs(SeedData.RainPods) do
		table.insert(names, pod.Name)
	end
	for _, item in ipairs(WeaponData.Items) do
		table.insert(names, item.Name)
	end
	local tooLong = {}
	for _, name in ipairs(names) do
		local desk = TextService:GetTextSize(name, 10, Enum.Font.FredokaOne, Vector2.new(88, 1000))
		local phone = TextService:GetTextSize(name, 11, Enum.Font.FredokaOne, Vector2.new(88, 1000))
		if desk.Y > 26 or phone.Y > 30 then
			table.insert(tooLong, string.format("%s (%d / %d)", name, desk.Y, phone.Y))
		end
	end
	check(#tooLong == 0, "every shipped visible name fits a tile in two lines at its smallest size ("
		.. #names .. " names)", table.concat(tooLong, ", "))
end

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
	-- WalkModeUI 1 -> 0 (2026-10-04): its pop is UIKit.pressPop's and its slide a
	-- tween, neither a per-frame hook of its own.
	CashUI = 2, IndexUI = 0, ShopUI = 0, SettingsUI = 0, WalkModeUI = 0, GardenUI = 1,
	LoadoutUI = 2, WorldClock = 1, TutorialUI = 1, BiomeGuideUI = 0, RailDrawerUI = 0,
	ActionToastUI = 0, PlotTeleportUI = 0,
}
-- The two owners that draw into the shared rail layer and make no ScreenGui.
local LAYER_ONLY = { WalkModeUI = true, RailDrawerUI = true }
-- An owner with more than its one: TutorialUI's spotlight (2026-10-08) needs a
-- gui with no screen insets over every button (the dim covers the notch and
-- the topbar), and its world hand one under every HUD layer.
local GUIS = { TutorialUI = 3 }
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
	check(src ~= nil and count(src, 'Instance.new("ScreenGui")') == (if LAYER_ONLY[name] then 0 else GUIS[name] or 1)
			and not src:find('Instance.new("RemoteEvent")', 1, true),
		name .. " made no ScreenGui beyond its own (TutorialUI: its own, the spotlight's and the world hand's) "
			.. "and no remote")
end
local loadout = sourceOf("LoadoutUI") or ""
check(loadout:find("return layout.slots", 1, true) ~= nil
		and loadout:find("layout.chip", 1, true) ~= nil,
	"LoadoutUI takes its slot count and the Bag cell from the same answer that places the strip")
check(not loadout:find("HotbarTray", 1, true) and loadout:find("HotbarCard.build(hotbar, index, HOT, 4)", 1, true) ~= nil
		and loadout:find("namePopup.Position = HudLayout.place(layout.namePopup, namePopup.AnchorPoint, layout.safe)", 1, true) ~= nil,
	"no painted tray any more (2026-10-01): the slots are HotbarCard's squares, and the name band is placed from the same answer")
check(loadout:find("activeSlots = want\n\tredraw()", 1, true) ~= nil and not loadout:find("assigned[", 1, true),
	"a change of slot count hides and empties the slots past it and releases nothing: the roles never renumber")
local walk = sourceOf("WalkModeUI") or ""
check(walk:find('label.Text = WALK.Label .. ": " .. (if on then WALK.OnText else WALK.OffText)', 1, true)
		and not walk:find("STACKED_LABEL", 1, true) and walk:find("relayout:Disconnect()", 1, true),
	"the switch says WALK MODE: ON or OFF on one line over its track in every layout (2026-10-04), and drops its "
		.. "hook on the shared layer with itself")
local settings = sourceOf("SettingsUI") or ""
check(settings:find("plate.Visible = layout.compact and not layout.sidebar", 1, true) ~= nil,
	"Settings stands on a plate in the compact row, and only there -- on a phone the dock's tile replaces it")
local cash = sourceOf("CashUI") or ""
check(cash:find("HudLayout.measure(gui, groupWidth())", 1, true) ~= nil
		and cash:find("if groupWidth() > placedFor then", 1, true) ~= nil,
	"the cash block is measured as one group and placed again only if it outgrows its reservation")

-- The two faces are drawn from the answer that places them, by the owners that
-- already existed: one strip, one cash block, no second controller.
check(cash:find("applyStyle(layout.cashStyle)", 1, true) ~= nil
		and not cash:find("UserInputService.TouchEnabled", 1, true)
		and cash:find("math.floor(textWidth) + style.BuffGap", 1, true) ~= nil
		and cash:find("buffHit.Activated:Connect(", 1, true) ~= nil,
	"CashUI takes its face from HudLayout's answer, never from TouchEnabled, places the x2 card off the measured cash text, and takes the press on the full touch area")
check(loadout:find("local restyled = layout.hot ~= HOT", 1, true) ~= nil
		and count(loadout, "restyleHotbar()") == 2,
	"LoadoutUI takes its cards from the same answer, and restyles only from layoutHud")
local owners = 0
local strips = 0
for _, s in ipairs(scripts:GetChildren()) do
	if s:IsA("LuaSourceContainer") then
		owners += count(s.Source, 'gui.Name = "SeedCash"')
		strips += count(s.Source, 'hotbar.Name = "Hotbar"')
	end
end
check(owners == 1 and strips == 1, "still one cash block and one hotbar in the whole client",
	string.format("%d cash, %d hotbar", owners, strips))
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

check(loadout:find("hotbar.Visible = not ((bagOpen and not lifted and layout ~= nil and layout.touch) or view.yield)", 1, true) ~= nil
		and loadout:find("	bagOpen = want\n	showStrip()", 1, true) ~= nil,
	"on touch the strip hides while the Bag is open, shows while a card is in the air, and returns on close")
check(loadout:find("stripHidden = layout.touch", 1, true) ~= nil,
	"and the Bag grows into its space on exactly that condition")
local panelSrc = Shared:FindFirstChild("InventoryPanel") and Shared:FindFirstChild("InventoryPanel").Source or ""
check(loadout:find("HudLayout.bag(layout,", 1, true) ~= nil
		and select(2, panelSrc:gsub("grid.CanvasPosition = Vector2.zero", "")) >= 3,
	"LoadoutUI places the Bag from HudLayout.bag; the panel resets the scroll on a new search, the heart and a new direction")
check(layoutSource:find("right = shellW - 12 - 52 - padRight", 1, true) ~= nil
		and panelSrc:find("HudLayout.bagSearch(bag, shellW, titleWidth, padLeft, padRight)", 1, true) ~= nil,
	"the search row stops short of the close button wherever the header has moved it")
-- The second ScrollingFrame is the item menu's column (2026-10-10): its words
-- and its buttons, each built once by menuColumn (BagMenuSpec).
check(select(2, loadout:gsub('Instance.new%("ScrollingFrame"%)', "")) == 0
		and select(2, panelSrc:gsub('Instance.new%("ScrollingFrame"%)', "")) == 2
		and select(2, panelSrc:gsub("menuColumn%(\"Menu", "")) == 2
		and select(2, panelSrc:gsub('Instance.new%("UIGridLayout"%)', "")) == 1,
	"one Bag grid, InventoryPanel's, built once -- nothing rebuilt; the menu's two columns built once too")

local kit = Shared:FindFirstChild("UIKit").Source
check(kit:find("function UIKit.railShape", 1, true) and kit:find("function UIKit.railBadge", 1, true)
		and kit:find("if layout.compact or layout.frame ~= nil then", 1, true),
	"UIKit reshapes a rail button for its owner and steps modal headers clear of the compact rows (and a TV's framed ones)")

--==============================================================================
-- 7. THE PHONE'S SIDEBARS, WIRED
--
-- The approved mobile redesign of 2026-09-23, read from the owners that draw
-- it: every control still has exactly the owner it had, the dock is a frame
-- they stand in rather than a controller, the belt drops the weapons on a phone
-- only. (The BATS / TRAPS sidebar and its chooser went 2026-10-03: a bat is any
-- slot's, equipped through the shop's own verb.)
--==============================================================================
say("-- the sidebars, wired --")

-- Only a touch screen is a phone. Every non-touch answer carries none of it.
local plain = true
for _, input in ipairs({ screen(1920, 1080), screen(1000, 609), screen(860, 700, { touch = false }),
	screen(700, 400, { touch = false }), screen(1920, 1080, { keyboard = false }) }) do
	local L = HudLayout.solve(input)
	plain = plain and not L.sidebar and L.dock == nil and L.handle == nil and L.handleShut == nil
		and L.boost == nil and L.chooser == nil
end
check(plain, "no desktop, console or narrow non-touch window gets a dock, an x2 button or a chooser")
check(HudLayout.solve(screen(700, 400, { touch = false })).compact,
	"a 700 x 400 desktop window is compact, and still not a phone")
-- A portrait tablet and a small landscape phone still fit.
for _, case in ipairs({
	{ "768x1024 portrait tablet", screen(768, 1024, { touch = true, keyboard = false }) },
	{ "1366x1024 landscape tablet", screen(1366, 1024, { touch = true, keyboard = false }) },
}) do
	local L = HudLayout.solve(case[2])
	local problems = HudLayout.problems(L)
	check(L.sidebar and L.fits and #problems == 0, case[1] .. ": the sidebars fit, clean",
		table.concat(problems, "; "))
end

for _, name in ipairs({ "IndexUI", "ShopUI" }) do
	local src = sourceOf(name) or ""
	check(src:find("if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)", 1, true) ~= nil
			and src:find("UIKit.railShape(button,", 1, true) ~= nil
			and count(src, "UIKit.railButton(") == 1,
		name .. " still owns its one rail button, and on a phone stands it in the dock as a tile")
end
-- 2026-09-24: Index and Shop are the owner's square artwork, their own tile on
-- a phone, and only the Shop's rim turns -- one RenderStepped connection, made
-- while the button can be seen and dropped when it cannot.
do
	local shopSrc, indexSrc = sourceOf("ShopUI") or "", sourceOf("IndexUI") or ""
	check(shopSrc:find("art = RAIL.ShopArt,\n\trim = true,", 1, true) ~= nil
			and indexSrc:find("art = RAIL.IndexArt,", 1, true) ~= nil
			and not indexSrc:find("rim = true", 1, true)
			and not shopSrc:find("RAIL.ShopIcon", 1, true) and not indexSrc:find("RAIL.IndexIcon", 1, true)
			and shopSrc:find("UIKit.railShape(button, Vector2.new(layout.shop.w, layout.shop.h))", 1, true) ~= nil
			and indexSrc:find("UIKit.railShape(button, Vector2.new(layout.index.w, layout.index.h))", 1, true) ~= nil,
		"Index and Shop draw the approved artwork as their own tile, and only the Shop's rim turns")
	check(string.match(RAIL.ShopArt or "", "^rbxassetid://%d+$") ~= nil
			and string.match(RAIL.IndexArt or "", "^rbxassetid://%d+$") ~= nil
			and RAIL.Rim ~= nil and RAIL.Rim.Speed == 90 and #RAIL.Rim.Colours == 6,
		"both artworks are uploaded ids in GameConfig.Rail, and the rim is the reference's six colours at 90 degrees a second")
	-- The owner's studded pictures (2026-10-05): a phone's Index, Shop and
	-- Settings, each drawn whole at its own aspect, nothing of ours over it.
	local settingsSrc = sourceOf("SettingsUI") or ""
	check(indexSrc:find("UIKit.railPicture(button, RAIL.StuddedIndexArt, 1)", 1, true) ~= nil
			and shopSrc:find("UIKit.railPicture(button, if layout.shop.w > layout.shop.h then RAIL.StuddedShopArt else nil,\n"
				.. "\t\tRAIL.StuddedShopAspect)", 1, true) ~= nil
			and settingsSrc:find("UIKit.railPicture(button, if layout.sidebar then RAIL.StuddedSettingsArt else nil, 1)",
				1, true) ~= nil
			and indexSrc:find("if layout.sidebar then\n\t\tUIKit.railBadge(badge, true, \"right\", true, true)\n\telse\n"
				.. "\t\tUIKit.railBadge(badge, layout.compact or column, if column then \"left\" else \"right\")", 1, true)
				~= nil
			and string.match(RAIL.StuddedShopArt or "", "^rbxassetid://%d+$") ~= nil
			and string.match(RAIL.StuddedIndexArt or "", "^rbxassetid://%d+$") ~= nil
			and string.match(RAIL.StuddedSettingsArt or "", "^rbxassetid://%d+$") ~= nil
			and math.abs((RAIL.StuddedShopAspect or 0) - 2094 / 751) < 1e-9
			and math.abs(CFG.Phone.Shop.X - CFG.Phone.Shop.Y * RAIL.StuddedShopAspect) <= 1,
		"Index draws the owner's studded picture on every screen, Shop wherever its slot is wide, Settings on a "
			.. "phone (uploaded ids in GameConfig.Rail); a phone's Shop at its picture's own aspect to the pixel, "
			.. "Index's badge a small pill on a phone, on its left corner in a desktop's right-edge column (2026-10-09)")
	-- THE PHONE'S PILL (the owner, 2026-10-09), drawn by UIKit.railBadge: as wide
	-- as its count at Text px, never under its height, on the top-RIGHT corner;
	-- Garden's over the gap above it; the round badge put back off a phone.
	do
		local kitSrc = Shared:FindFirstChild("UIKit").Source
		local gardenSrc = sourceOf("GardenUI") or ""
		check(kitSrc:find("badge.AutomaticSize = Enum.AutomaticSize.X", 1, true) ~= nil
				and kitSrc:find("count.TextSize = PB.Text", 1, true) ~= nil
				and kitSrc:find("floor.MinSize = Vector2.new(inner, inner)", 1, true) ~= nil
				and kitSrc:find("badge.AnchorPoint = Vector2.new(1, 0)\n\t\tbadge.Position = UDim2.new(1, PB.Over - PB.Stroke, "
					.. "0, if flush then PB.Stroke else PB.Stroke - PB.Over)", 1, true) ~= nil
				and kitSrc:find("badge.Size = UDim2.fromOffset(26, 26)", 1, true) ~= nil
				and gardenSrc:find("if layout.sidebar then\n\t\tUIKit.railBadge(badge, true, \"right\", false, true)", 1, true)
					~= nil,
			"a phone's badges are UIKit.railBadge's small pills -- widening for two digits, never shrinking their "
				.. "words -- and every other screen keeps the round 26-px badge")
	end
	do
		local from = kit:find("function UIKit.railPicture", 1, true)
		local body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
		check(body:find("picture.ScaleType = Enum.ScaleType.Fit", 1, true) ~= nil
				and body:find("shape.AspectRatio = aspect or 1", 1, true) ~= nil
				and body:find("\"ArtBox\", \"Icon\", \"GearDrawn\", \"Label\", \"Tile\", \"TileLabel\", \"Plate\"", 1, true) ~= nil
				and body:find("made.Active = false", 1, true) ~= nil and body:find("picture.Active = false", 1, true) ~= nil,
			"UIKit.railPicture draws the picture whole at its aspect, hides everything of ours under it once it "
				.. "has loaded here (RailFallbackSpec), and takes no press")
	end
	check(kit:find("function UIKit.rainbowRim", 1, true) ~= nil
			and select(2, kit:gsub("RunService%.RenderStepped:Connect%(step%)", "")) == 1
			and kit:find("local run = onScreen() and not motionOff()", 1, true) ~= nil
			and kit:find("if tile and not button:FindFirstChild(\"ArtBox\") then", 1, true) ~= nil,
		"the rim spins on one connection, only while seen and motion is allowed; no dock plate ever covers an art button")
end

-- RailDrawerUI, and EVENTS / WHAT'S NEW / Settings in the panel: InviteHudSpec (2026-10-06).
check(kit:find("function UIKit.railDock", 1, true) ~= nil
		and kit:find("layer:FindFirstChild(options.name, true)", 1, true) ~= nil,
	"the dock is one shared frame, and a re-run rail button finds its old self inside it")

check(not loadout:find("HotbarRoles", 1, true) and not loadout:find("plantsOnly", 1, true)
		and loadout:find("HotbarSlots.arrive(shownBar(), ref, activeSlots, prof.planted)", 1, true) ~= nil,
	"the belt is freely assigned shortcuts (2026-10-03): ten on a desktop, the first five on a phone")
check(not loadout:find("chooser", 1, true) and not loadout:find("sideSlots", 1, true)
		and count(loadout, "FireServer(W.EquipAction") == 1,
	"no BATS / TRAPS chooser: a bat or a trap not out is equipped through the one equip verb, from its slot or tile")
check(loadout:find("UserInputService.InputBegan:Connect(", 1, true) ~= nil
		and loadout:find("endAssign()", 1, true) ~= nil
		and loadout:find("player.CharacterRemoving:Connect(function()\n\tcancelDrag()", 1, true) ~= nil,
	"a phone's assignment ends on an outside tap (without swallowing it), a panel closing and the character going")
-- Since the owner's mobile corrections (2026-10-05) the card rides the cash line
-- on a phone too, the artwork alone there, never nearer the stick than buffMinX.
check(count(cash, 'buff.Name = "MoneyBuff"') == 1 and not cash:find("layout.boost", 1, true)
		and cash:find("buff.Parent = root", 1, true) ~= nil and cash:find("layoutMinX = layout.buffMinX", 1, true) ~= nil
		and cash:find("math.max(layoutMinX or style.BuffMinX, math.floor(textWidth) + style.BuffGap)", 1, true) ~= nil
		and cash:find("buff.BackgroundTransparency = if plain then 1 else 0.08", 1, true) ~= nil
		and cash:find("buffEdge.Enabled = not plain", 1, true) ~= nil,
	"one x2 card, beside the cash line on every screen: on a phone the artwork alone -- no plate, no border -- and "
		.. "never nearer the thumbstick's zone than HudLayout's buffMinX")

--==============================================================================
-- 8. THE TOAST AND THE TELEPORT BUTTON, ON EVERY SCREEN
--
-- The two things that come and go (2026-09-23): a refused action's one line
-- above the belt, and TELEPORT TO PLOT under the clock. Neither is a
-- permanent group -- HudLayout.problems never decides desktop against compact
-- on them, so the desktop cannot move for them -- and so both are held here, on
-- every desktop size, every listed phone and two small windows: inside the safe
-- area, clear of every group, both thumbs and each other, and wide enough for
-- every word they can carry.
--==============================================================================
say("-- the toast and the teleport button --")
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local TOAST, TELE = CFG.Toast, CFG.Teleport
local everyScreen = {}
for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1366, 768), Vector2.new(1600, 900),
	Vector2.new(1920, 1080), Vector2.new(2560, 1440), Vector2.new(1000, 609) }) do
	table.insert(everyScreen, { tag = string.format("%dx%d desktop", size.X, size.Y),
		input = screen(size.X, size.Y) })
end
for _, case in ipairs(cases) do
	table.insert(everyScreen, case)
end
table.insert(everyScreen, { tag = "860x700 window", input = screen(860, 700, { touch = false }) })
table.insert(everyScreen, { tag = "700x400 window", input = screen(700, 400, { touch = false }) })

-- Every notice a refusal can put up (2026-09-27: a headline and a next step),
-- at the smallest sizes ActionToastUI allows them: the headline on ONE line
-- beside a 20 px icon, in LuckiestGuy 16; the next step in at most TWO lines of
-- GothamBold 11.
local Notice = require(Shared:WaitForChild("Notice"))
local longestHead, longestTitle = 0, ""
local detailLines = {}
for code, line in pairs(ActionRefusal.Notices) do
	local width = TextService:GetTextSize(line.title, 16, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X + 20 + 8
	if width > longestHead then
		longestHead, longestTitle = width, line.title
	end
	if line.detail then
		table.insert(detailLines, { code = code, text = line.detail })
	end
end
-- The sacrifice pedestal's notices (2026-09-28) go up through the same renderer
-- and are held to the same two rules: every refusal it can name, its COOLDOWN
-- with the longest time it can show, and the success with what it bought.
do
	local SACRIFICE = GameConfig.Sacrifice
	local lines = {}
	for code, line in pairs(SACRIFICE.Notices) do
		table.insert(lines, { code = "pedestal " .. code, title = line.title, detail = line.detail })
	end
	table.insert(lines, { code = "pedestal COOLDOWN's time", title = SACRIFICE.Notices.COOLDOWN.title,
		detail = GameConfig.sacrificeReadyIn(SeedData.Sacrifice.CooldownSeconds) })
	table.insert(lines, { code = "pedestal success", title = SACRIFICE.SuccessTitle,
		detail = GameConfig.sacrificeOffer(SeedData.Sacrifice.Multiplier, SeedData.Sacrifice.DurationSeconds) .. "." })
	for _, line in ipairs(lines) do
		local width = TextService:GetTextSize(line.title, 16, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X + 20 + 8
		if width > longestHead then
			longestHead, longestTitle = width, line.title
		end
		if line.detail then
			table.insert(detailLines, { code = line.code, text = line.detail })
		end
	end
end
local teleportWords = TextService:GetTextSize("TELEPORT TO PLOT", 10, Enum.Font.LuckiestGuy,
	Vector2.new(4000, 100)).X
-- A phone's word (the owner's mobile corrections, 2026-10-05), at the plate's own 16.
local plotWord = TextService:GetTextSize("PLOT", 16, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
local noticeBottom = CFG.NoticeTop + CFG.NoticeHeight - TOPBAR
-- The screens whose row is full, where ADMIN hangs under the clock.
local hungAdmin = {}

for _, case in ipairs(everyScreen) do
	local L = HudLayout.solve(case.input)
	local tag = case.tag
	local sw, sh = L.safe.X, L.safe.Y
	local t, p = L.toast, L.teleport
	local groups = HudLayout.groups(L, true)
	local zones = {}
	if L.thumb then
		table.insert(zones, L.thumb)
	end
	if L.jump then
		table.insert(zones, L.jump)
	end

	local toastClear = t.w >= TOAST.MinWidth and t.w <= TOAST.Width and t.h == TOAST.Height
		and t.x >= 8 and t.y >= 8 and t.x + t.w <= sw - 8 and t.y + t.h <= sh - 8
		and t.y + t.h <= L.hotbar.y - 8
	local toastNote = r2s(t)
	for _, g in ipairs(groups) do
		if HudLayout.gap(t, g.rect) < 8 then
			toastClear = false
			toastNote ..= " meets " .. g.name
		end
	end
	for _, zone in ipairs(zones) do
		toastClear = toastClear and HudLayout.gap(t, zone) >= 8
	end
	-- Over the belt on EVERY screen again (2026-10-04, the owner's order: the
	-- hotbar, the active icons, the short notices just over them). A phone's
	-- notices hung from the top of the centre column from 2026-09-29 until then.
	local onTop = false
	local beltTop = HudLayout.hotbarBand(L.hotbar).y
	toastClear = toastClear and L.toastTop == false and t.y + t.h <= beltTop - 8 + 0.01
	if not toastClear then
		toastNote ..= string.format(" (toastTop %s, bottom %.0f, belt band %.0f)", tostring(L.toastTop),
			t.y + t.h, beltTop)
	end
	check(toastClear, tag .. ": the toast is over the belt, 200-340 wide, clear of every group and both thumbs",
		toastNote)
	check(t.w >= longestHead,
		tag .. ": every refusal headline fits one line at 16 px -- the longest is \"" .. longestTitle .. "\"",
		string.format("%.0f of %d", longestHead, t.w))
	local tall = {}
	for _, d in ipairs(detailLines) do
		local b = TextService:GetTextSize(d.text, 11, Enum.Font.GothamBold, Vector2.new(t.w, 1000))
		if b.Y > 11 * 2.6 then
			table.insert(tall, d.code)
		end
	end
	check(#tall == 0, tag .. ": every next step fits two lines at 11 px", table.concat(tall, ", "))

	-- THE NOTICE STACK (2026-09-27): the whole area ActionToastUI's notices may
	-- stand in -- one on the toast rect, older ones above it -- clear of every
	-- group and both thumbs, and never into the middle band where the
	-- controller's reticle and its reason line sit. At both notice sizes.
	local middle = if case.input.viewport and case.input.insetTop
		then case.input.viewport.Y / 2 - case.input.insetTop else sh / 2
	for _, size in ipairs({ { one = 26 + 4 + 2 + 15 + 4 + 8, most = Notice.MaxShown },
		{ one = 21 + 4 + 1 + 13 + 4 + 6, most = Notice.MaxShownCompact } }) do
		local area, count = HudLayout.noticeStack(L, size.one, size.most, middle)
		local clear = count >= 1 and count <= size.most
		local note = r2s(area) .. " x" .. count
		if onTop then
			-- Hanging from the toast's top edge, and ending above the middle.
			clear = clear and area.y == t.y and area.x == t.x and area.w == t.w
			if count > 1 and area.y + area.h > middle - 8 then
				clear = false
				note ..= " reaches the middle of the screen"
			end
		else
			clear = clear and area.y + area.h == t.y + t.h
			if count > 1 and area.y < middle + HudLayout.MiddleBand then
				clear = false
				note ..= " reaches the middle band"
			end
		end
		if count > 1 then
			for _, g in ipairs(groups) do
				if HudLayout.gap(area, g.rect) < 8 then
					clear = false
					note ..= " meets " .. g.name
				end
			end
			for _, zone in ipairs(zones) do
				if HudLayout.gap(area, zone) < 8 then
					clear = false
					note ..= " meets a thumb"
				end
			end
		end
		check(clear, string.format("%s: a stack of up to %d notices (%d px each) stays clear of every group, "
			.. "both thumbs and the middle", tag, size.most, size.one), note)
	end

	-- On a phone it stands BESIDE the clock, on the clock's row (2026-09-29; it
	-- stood right under the clock from 2026-09-24), and since the owner's mobile
	-- corrections (2026-10-05) it says just PLOT: the Phone.Row plate drawn at
	-- PhoneScale, its touch area exactly that plate, 44 tall, up in the topbar's
	-- free span. Everywhere else it is under the notice band, drawn at 1,
	-- exactly as it was.
	local phone = L.sidebar == true
	local inset = p.h * (1 - L.teleportScale) / 2
	local wantTop = noticeBottom + 8
	if phone and L.clock then
		wantTop = L.clock.y + (L.clock.h - p.h) / 2 - TOPBAR
	end
	local bar = case.input.topbar
	local originX = (case.input.viewport.X - sw) / 2
	local inFreeSpan = p.y >= 0 or (bar ~= nil and p.x + originX >= bar.x + 8
		and p.x + p.w + originX <= bar.x + bar.w - 8)
	local rowEdge = CFG.Phone.RowStroke * 2
	local plotPlates = L.teleportPlate == Vector2.new(CFG.Phone.Row.Plot - rowEdge, TELE.Size.Y - rowEdge)
		or L.teleportPlate == Vector2.new(CFG.Phone.RowTight.Plot - rowEdge, TELE.Size.Y - rowEdge)
	local teleClear = p.h >= 44 and p.w >= 44
		and p.w == (if phone then (L.teleportPlate.X + rowEdge) * TELE.PhoneScale else TELE.Size.X)
		and (if phone then p.y == wantTop else p.y >= wantTop)
		and L.teleportScale == (if phone then TELE.PhoneScale else 1)
		and (if phone then plotPlates and L.teleportShort else L.teleportPlate == TELE.Size and not L.teleportShort)
		and L.topRow == phone
		and L.teleportPlate.X * L.teleportScale <= p.w and L.teleportPlate.Y * L.teleportScale <= p.h
		and p.x >= 8 and p.x + p.w <= sw - 8 and p.y + p.h <= sh - 8
		and (p.y >= 8 or (phone and inFreeSpan))
		and HudLayout.gap(p, t) >= 8
	local teleNote = r2s(p) .. string.format(" scale %.2f", L.teleportScale)
	for _, g in ipairs(groups) do
		if HudLayout.gap(p, g.rect) < 8 then
			teleClear = false
			teleNote ..= " meets " .. g.name
		end
	end
	for _, zone in ipairs(zones) do
		teleClear = teleClear and HudLayout.gap(p, zone) >= 8
	end
	check(teleClear, tag .. ": TELEPORT TO PLOT is 44+ tall, "
			.. (if phone then string.format("on the clock's row, PLOT's plate drawn at %.2f and its touch area exactly that",
					TELE.PhoneScale)
				else "under the notice band")
			.. ", clear of every group, the thumbs and the toast",
		teleNote)
	local clock = L.clock
	local viewport = case.input.viewport
	if phone and clock then
		-- On the clock's row, Phone.RowGap after BIOMES (the owner's order,
		-- 2026-09-30; one even row, 2026-10-05), the drawn plate level with the
		-- clock and inside the topbar's band; up there only inside the topbar's
		-- free span; and nothing of it under the topbar, where the view begins.
		local c = rect(clock.x - originX, clock.y - TOPBAR, clock.w, clock.h)
		local drawnTop, drawnBottom = p.y + inset, p.y + p.h - inset
		local b = L.biomes
		local beside = b.w > 0 and math.abs(p.x - (b.x + b.w + CFG.Phone.RowGap)) < 1e-6 and p.y == b.y
		check(beside and HudLayout.gap(p, c) >= 8 - 1e-6 and inFreeSpan
				and math.abs((drawnTop + drawnBottom) / 2 - (c.y + c.h / 2)) <= 0.5
				and drawnTop >= c.y - 0.5 and drawnBottom <= c.y + c.h + 0.5 and p.y + p.h <= 0,
			tag .. ": the phone's button stands on the clock's row, " .. CFG.Phone.RowGap .. " px after BIOMES and "
				.. "level with the clock, in the topbar's free span",
			string.format("%s after %s, clock %s, drawn %.1f to %.1f", r2s(p), r2s(b), r2s(c), drawnTop, drawnBottom))
	end
	-- The ADMIN button (window space) keeps 8 px off the whole touch area.
	local admin = L.admin
	if admin then
		local a = rect(admin.x - originX, admin.y - TOPBAR, admin.w, admin.h)
		check(HudLayout.gap(a, p) >= 8, tag .. ": the ADMIN button keeps 8 px off it", r2s(a) .. " / " .. r2s(p))
	end
	if clock and viewport and not phone then
		local under = clock.x + clock.w / 2 - (viewport.X - sw) / 2
		check(math.abs(p.x + p.w / 2 - under) <= 1,
			tag .. ": and centred under the clock", string.format("%.1f vs %.1f", p.x + p.w / 2, under))
	end
	check(HudLayout.gap(p, L.banner) >= 8 and HudLayout.gap(p, L.skip) >= 8,
		tag .. ": the tutorial banner keeps 8 px off it", r2s(L.banner))
	check(L.tutorialScale == (if phone then CFG.TutorialPhoneScale else 1)
			and L.guide == phone
			and L.banner.h == (if phone then CFG.Phone.Guide.Height else CFG.BannerSize.Y),
		tag .. ": the tutorial is drawn at " .. (if phone then "the phone's scale, in the left column"
			else "1, exactly as it was"),
		r2s(L.banner))
	local chooser = L.chooser
	if chooser then
		check(HudLayout.gap(p, chooser) >= 8, tag .. ": an open chooser keeps 8 px off it", r2s(chooser))
	end
	-- Its words are laid out in the plate before its scale: TELEPORT TO PLOT
	-- beside the sprout in 196 off a phone; on a phone PLOT alone, 6 px in from
	-- either side (the mobile corrections, 2026-10-05).
	if phone then
		check(L.teleportPlate.X - 12 >= plotWord,
			tag .. ": PLOT fits its plate whole at 16 px, no icon beside it",
			string.format("%.0f of %d", plotWord, L.teleportPlate.X - 12))
	else
		check(L.teleportPlate.X - 50 >= teleportWords,
			tag .. ": its words fit beside the sprout at 10 px",
			string.format("%.0f of %d", teleportWords, L.teleportPlate.X - 50))
	end

	-- THE ADMIN BUTTON (two accounts only): WINDOW space, in the topbar beside
	-- the clock, level with it, inside the free span, never on top of it. On a
	-- phone it stands just left of the clock at the row's end (2026-09-30), and
	-- hangs under the row's middle only where the row has no room for it (hung,
	-- below).
	local a, bar = L.admin, case.input.topbar
	local adminOk = a ~= nil and clock ~= nil and bar ~= nil
	local hung = false
	if adminOk then
		hung = phone and a.y >= clock.y + clock.h
		adminOk = a.w == CFG.Admin.Size.X and a.h == CFG.Admin.Size.Y
			and a.x >= bar.x + 8 and a.x + a.w <= bar.x + bar.w - 8
			and (hung or HudLayout.gap(a, clock) >= 8)
		if hung then
			-- Under the row's middle, 8 px under the buttons' touch areas ...
			adminOk = adminOk and a.y == p.y + TOPBAR + p.h + 8
				and math.abs((a.x + a.w / 2) - (L.columnCentre + originX)) <= 0.5
				-- ... and only because the row had no room for it before the clock.
				and clock.x - 8 - a.w - 8 < L.obby.x + L.obby.w + originX
				-- The column under the row starts under it.
				and L.columnTop >= a.y + a.h - TOPBAR
		else
			adminOk = adminOk and a.y >= 0 and a.y + a.h <= TOPBAR
				and math.abs((a.y + a.h / 2) - (clock.y + clock.h / 2)) <= 0.5
		end
	end
	if hung then
		table.insert(hungAdmin, tag)
	end
	check(adminOk, tag .. ": the ADMIN button stands in the topbar beside the clock, level with it, 8 px clear"
			.. (if hung then " -- or, the row being full, hangs under the row's middle" else ""),
		if a then r2s(a) else "nil")
	-- Hung, it keeps 8 px off the three buttons, the top rows and both badges.
	if hung and a then
		local ar = rect(a.x - originX, a.y - TOPBAR, a.w, a.h)
		local apart, meets = true, ""
		local others = { { "BIOMES", L.biomes }, { "TELEPORT", p }, { "OBBY", L.obby } }
		for _, g in ipairs(HudLayout.groups(L, true)) do
			table.insert(others, { g.name, g.rect })
		end
		local ib, gb = HudLayout.badges(L)
		table.insert(others, { "the Index badge", ib })
		table.insert(others, { "the Garden badge", gb })
		for _, other in ipairs(others) do
			if other[2].w > 0 and HudLayout.gap(ar, other[2]) < 8 - 1e-6 then
				apart = false
				meets ..= " meets " .. other[1]
			end
		end
		check(apart, tag .. ": hung, ADMIN keeps 8 px off the three buttons, the top rows and both badges", meets)
	end
end
say("  (ADMIN hangs under the row, the row being full, on: "
	.. (if #hungAdmin > 0 then table.concat(hungAdmin, ", ") else "none") .. ")")
do
	local only = true
	for _, tag in ipairs(hungAdmin) do
		only = only and (string.find(tag, "^640x") ~= nil or string.find(tag, "^705x") ~= nil)
	end
	check(only, "only the 640- and 705-px-wide phones hang ADMIN under the row; every other listed screen has it on the row",
		table.concat(hungAdmin, ", "))
end

-- NOT A GROUP: nothing is placed around it, so no player's HUD moves for it.
do
	local L = HudLayout.solve(screen(1920, 1080))
	local named = false
	for _, g in ipairs(HudLayout.groups(L, true)) do
		if g.name == "admin" then
			named = true
		end
	end
	check(not named, "the ADMIN button is not a permanent group -- nothing else is placed around it")
	-- Too narrow for either side of the clock: it hangs under the clock, in the
	-- notice band, still 8 px off TELEPORT TO PLOT (window y 88 on a 58 topbar).
	local tiny = HudLayout.solve(screen(430, 500, { touch = false }))
	local a, clock = tiny.admin, tiny.clock
	check(a ~= nil and clock ~= nil and a.y >= clock.y + clock.h
			and a.y + a.h + 8 <= tiny.teleport.y + TOPBAR,
		"a window too narrow beside the clock gets it under the clock, clear of the teleport button",
		a and r2s(a))
	local adminUi = game:GetService("ServerScriptService"):FindFirstChild("SeedGameServer")
	adminUi = adminUi and adminUi:FindFirstChild("AdminService")
	adminUi = adminUi and adminUi:FindFirstChild("AdminConsoleUI")
	local adminSrc = adminUi and (adminUi :: any).Source or ""
	check(adminSrc:find("layout.admin", 1, true) ~= nil and adminSrc:find("gui.IgnoreGuiInset", 1, true) == nil,
		"AdminConsoleUI places its button from HudLayout's `admin`, in the window-space gui AdminService builds")
end

-- The notice band itself, every biome name, on every screen: the button sits
-- under the name wherever the name stays centred, and a dropped name lands
-- under the button.
do
	local fine, note = true, ""
	for _, case in ipairs(everyScreen) do
		local L = HudLayout.solve(case.input)
		local dx, top = HudLayout.notice(L, widest, 30, 50 - TOPBAR)
		local box = rect(L.safe.X / 2 + dx - widest / 2, top, widest, 30)
		if HudLayout.gap(box, L.teleport) < 8 then
			fine = false
			note ..= " " .. case.tag
		end
	end
	check(fine, "the biome name and the teleport button never meet, centred or dropped", note)
end

-- THE PHONE WHOSE ROW CANNOT HOLD BOTH BUTTONS (2026-09-29). It keeps the
-- arrangement that shipped before the row: TELEPORT under the clock -- under
-- the topbar at the margin, where the free span cannot hold it raised -- OBBY
-- beside it, the lines under them, the notices over the belt, the guide's
-- banner under all of it. It has NO COLUMN, so every answer that reads one is
-- the old one; nothing is new there but the clock's chip. And nothing a player
-- had is hidden: the differential sweep of 2026-09-29 (6,990 touch screens
-- against the module at HEAD) found no screen that lost a button.
do
	-- (Roblox's buttons out to 500: since the even row of 2026-10-05 a span from
	-- 408 holds the row. PLOT keeps its phone plate under the clock as well, its
	-- touch area that plate drawn.)
	local input = screen(772, 360, { touch = true, barLeft = 500 })
	local blocked = HudLayout.solve(input)
	local t, o = blocked.teleport, blocked.obby
	-- Under the clock as it stood before the row: raised into the topbar only
	-- inside its free span (PLOT's narrow plate fits there now), else at the
	-- margin; OBBY beside it, or under the topbar at the margin where the span
	-- has no room beside it (obbyBeside).
	local bar = input.topbar
	local raised = t.y < 0 and t.x >= bar.x + 8 and t.x + t.w <= bar.x + bar.w - 8
	check(blocked.sidebar and (t.y == 8 or raised) and t.w == CFG.Phone.Row.Plot * TELE.PhoneScale
			and blocked.teleportScale == TELE.PhoneScale and blocked.teleportShort
			and o.w > 0 and (o.y == t.y or o.y == 8) and o.h == t.h and HudLayout.gap(o, t) >= 8 - 1e-6,
		"a phone whose topbar free span cannot hold the row stands PLOT under the clock and OBBY beside it, as "
			.. "they stood before the row -- PLOT as narrow as its plate",
		r2s(t) .. " / " .. r2s(o))
	check(blocked.topRow == false and blocked.columnTop == nil and blocked.columnCentre == nil
			and blocked.rowLo == nil and blocked.rowHi == nil and blocked.toastTop == false
			and blocked.guide == false and blocked.run.w == 0 and blocked.clockChip == true,
		"and it has no column: the notices stay over the belt, the guide keeps its banner, the run keeps its line")
	-- Its lines, by the rules every screen had before the row.
	local status, notice, boosts = HudLayout.statusRows(blocked, TOPBAR)
	local _, noticeTop = HudLayout.notice(blocked, 0, CFG.NoticeHeight, CFG.NoticeTop - TOPBAR)
	check(status.x == t.x and status.w == t.w and status.y == t.y + (t.h - CFG.Status.Height) / 2
			and notice.y == noticeTop and notice.y >= t.y + t.h + 8
			and boosts.y == math.max(t.y + t.h, notice.y + notice.h) + 8 and boosts.h == CFG.Status.BoostHeight
			and r2s(HudLayout.statusLine(blocked, TOPBAR, 178)) == r2s(HudLayout.centreIn(blocked, status, 178)),
		"and its warning, its passing lines and its boost row stand under the button, where they stood",
		r2s(status) .. " " .. r2s(notice) .. " " .. r2s(boosts))
	local rows, k = HudLayout.boostRows(blocked, boosts, { 150, 160 }, 16)
	local row = HudLayout.centreIn(blocked, boosts, 150 + 16 + 160)
	-- Side by side, as BonusChestUI always put them -- or, where the panel under
	-- the Bag (taller since it holds four squares, 2026-10-06) narrows the row,
	-- one over the other, each clear of the panel.
	local sideBySide = k == 1 and #rows == 2 and rows[1].x == row.x and rows[2].x == row.x + 150 + 16
		and rows[1].y == boosts.y and rows[2].y == boosts.y
	local stacked = #rows == 2 and rows[1].y == boosts.y and rows[2].y > rows[1].y
		and HudLayout.gap(rows[1], blocked.dock) >= 8 - 1e-6 and HudLayout.gap(rows[2], blocked.dock) >= 8 - 1e-6
	check(sideBySide or stacked,
		"and two boosts stand side by side in that row (or one over the other, clear of the panel under the Bag)",
		r2s(rows[1]) .. " " .. r2s(rows[2]))
	check(blocked.toast.y + blocked.toast.h <= blocked.hotbar.y - 8
			and blocked.toast.y > input.viewport.Y / 2 - TOPBAR,
		"and the toast is over the belt", r2s(blocked.toast))

	-- ALL OR NOTHING: a row with room for BIOMES and PLOT and none for OBBY is
	-- not used. 600 wide with the free span from 324 holds the clock and those
	-- two drawn tight (124 + 8 + 54 + 5 + 45) and not OBBY's 48 after them.
	local short = HudLayout.solve(screen(600, 338, { touch = true, barLeft = 324 }))
	check(short.topRow == false and short.obby.w > 0 and short.teleport.w == CFG.Phone.Row.Plot * TELE.PhoneScale
			and (short.obby.y == short.teleport.y or short.obby.y == 8),
		"a row with room for BIOMES and PLOT and none for OBBY is not used: OBBY stays on screen, beside PLOT",
		r2s(short.teleport) .. " / " .. r2s(short.obby))
	-- The narrowest free span that holds the row (2026-09-30; the even row of
	-- 2026-10-05): BIOMES, PLOT and OBBY at the tight size RowGap apart, and the
	-- chip 8 px after them -- and one pixel less does not.
	local RT, k = CFG.Phone.RowTight, TELE.PhoneScale
	local RG = CFG.Phone.RowGap
	local need = RT.Biomes * k + RG + RT.Plot * k + RG + RT.Obby * k + 8 + CFG.Phone.Clock
	local just = HudLayout.solve(screen(772, 360, { touch = true, barLeft = 772 - 8 - need - 8 }))
	local less = HudLayout.solve(screen(772, 360, { touch = true, barLeft = 772 - 8 - need - 8 + 1 }))
	check(just.topRow == true and just.obbyWide == false and just.biomesWide == false
			and just.obbyPlate == Vector2.new(RT.Obby - CFG.Phone.RowStroke * 2, 44 - CFG.Phone.RowStroke * 2)
			and just.biomesPlate == Vector2.new(RT.Biomes - CFG.Phone.RowStroke * 2, 44 - CFG.Phone.RowStroke * 2)
			and just.rowHi - just.rowLo == need and less.topRow == false,
		string.format("the row needs %d px of free span: BIOMES, PLOT, OBBY drawn tight and the chip", need),
		string.format("%s..%s / %s", tostring(just.rowLo), tostring(just.rowHi), tostring(less.topRow)))
	-- And every word fits whole even drawn tight, at the plate's own 16 px: a
	-- label's least size is a DRAWN size (measured in Play, 2026-09-30: a label
	-- at the phone's 0.75 clipped a word that fitted it unscaled), and here none
	-- has to shrink. BIOMES' label has 4 px sides, PLOT's and OBBY's 6.
	local function word16(text)
		return TextService:GetTextSize(text, 16, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	end
	local RE = CFG.Phone.RowStroke * 2
	check(RT.Biomes - RE - 8 >= word16("BIOMES") and RT.Plot - RE - 12 >= word16("PLOT")
			and RT.Obby - RE - 12 >= word16("OBBY")
			and RT.Biomes * k >= 44 and RT.Plot * k >= 44 and RT.Obby * k >= 44,
		"drawn tight, BIOMES, PLOT and OBBY still fit their words whole at the plates' 16 px, and every touch area "
			.. "is 44 or wider",
		string.format("%d/%d %d/%d %d/%d", word16("BIOMES"), RT.Biomes - RE - 8, word16("PLOT"), RT.Plot - RE - 12,
			word16("OBBY"), RT.Obby - RE - 12))
	local biomesSrc0 = sourceOf("BiomesButtonUI") or ""
	check(biomesSrc0:find("fit.MinTextSize = 9", 1, true) ~= nil
			and biomesSrc0:find("label.Position = UDim2.new(0, 4, 0.5, 1)", 1, true) ~= nil
			and biomesSrc0:find("label.Size = UDim2.new(1, -8, 0, 22)", 1, true) ~= nil,
		"and BiomesButtonUI draws the word alone that way: 4 px sides, 9 px at the least")

	-- ADMIN hung under a clock with no room beside it: TELEPORT keeps 8 px off it.
	-- Under it until 2026-10-04; since Walk Mode's switch left the phone's top
	-- row, the button may stand where the switch stood, beside the dock.
	local narrow = HudLayout.solve(screen(430, 500, { touch = true, barLeft = 250 }))
	local a, clock = narrow.admin, narrow.clock
	local under = a ~= nil and clock ~= nil and a.y >= clock.y + clock.h and narrow.topRow == false
	if under and a then
		local ax = a.x - (430 - narrow.safe.X) / 2
		under = HudLayout.gap(rect(ax, a.y - TOPBAR, a.w, a.h), narrow.teleport) >= 8
	end
	check(under, "a phone too narrow for ADMIN beside the clock: the button keeps 8 px off it",
		a and (r2s(a) .. " / " .. r2s(narrow.teleport)))
end

-- THE TELEPORT RULE ON EVERY SCREEN (2026-09-27): the biome name and the sale
-- line (window y 50) are exactly where they were on a desktop.
say("\n-- notices and TELEPORT TO PLOT --")
for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1920, 1080), Vector2.new(1000, 609) }) do
	local L = HudLayout.solve(screen(size.X, size.Y))
	local tag = string.format("%dx%d", size.X, size.Y)
	local _, bandTop = HudLayout.notice(L, 200, CFG.NoticeHeight, CFG.NoticeTop - TOPBAR)
	check(bandTop == CFG.NoticeTop - TOPBAR or L.compact,
		tag .. ": the biome name and the sale line keep their row", bandTop)
end

--==============================================================================
-- THE OBBY BUTTON (2026-09-27): RIGHT BESIDE TELEPORT TO PLOT
--
-- On TELEPORT's row and height, exactly 8 px off it, drawn at its scale: clear
-- of every group and badge, both thumbs, the toast, the tutorial banner, an
-- open chooser and the ADMIN reservation, inside the safe area -- up in the
-- topbar only inside its free span, like TELEPORT -- and its word fitting at
-- the smallest size the plate draws it. Every listed screen has room for it.
-- The biome name and the boost row keep 8 px off it too; the chase warning
-- shares TELEPORT's slot but never shows with it (the Safe Zone rule, below).
--
-- ON A PHONE (2026-09-29) that row is the clock's own, up in the topbar's band
-- (THE PHONE'S TOP ROW), and the button's slot is the run's clock's on the
-- course, where the button is hidden: `run`.
--==============================================================================
say("\n-- the OBBY button --")
do
	local OBBY = CFG.Obby
	local word = TextService:GetTextSize("OBBY", 10, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	local right, left, narrow, hidden, lowered = 0, 0, {}, {}, {}
	for _, case in ipairs(everyScreen) do
		local L = HudLayout.solve(case.input)
		local tag = case.tag
		local o, p = L.obby, L.teleport
		local sw, sh = L.safe.X, L.safe.Y
		-- The run's clock has the button's slot wherever the row holds it, and no
		-- slot of its own anywhere else (ObbyUI draws the whole run line there).
		check(r2s(L.run) == r2s(if L.topRow then o else rect(0, 0, 0, 0)),
			tag .. ": the run's clock has " .. (if L.topRow then "the OBBY button's slot on the row"
				else "no slot: the run line is where it was"), r2s(L.run))
		if o.w <= 0 then
			table.insert(hidden, tag)
		else
			local originX = (case.input.viewport.X - sw) / 2
			local bar = case.input.topbar
			local inFreeSpan = o.y >= 0 or (bar ~= nil and o.x + originX >= bar.x + 8
				and o.x + o.w + originX <= bar.x + bar.w - 8)
			-- A phone's row is one even row, RowGap apart (2026-10-05); 8 elsewhere.
			local apart = if L.topRow then CFG.Phone.RowGap else 8
			local onRight = math.abs(o.x - (p.x + p.w + apart)) < 1e-6
			local onLeft = math.abs(o.x + o.w + apart - p.x) < 1e-6
			if onRight then
				right += 1
			elseif onLeft then
				left += 1
			end
			-- On a phone's row it is on TELEPORT's right, toward ADMIN and the clock
			-- at the row's end (the owner's order, 2026-09-30); BIOMES has the left.
			local chip = L.clock
			if L.topRow and chip then
				check(onRight and chip.x - originX > o.x + o.w,
					tag .. ": on the row, OBBY is on TELEPORT's right, between it and the clock", r2s(o))
			end
			if not L.obbyWide then
				table.insert(narrow, tag)
			end
			-- TELEPORT's own row; or, on a small phone whose topbar has no room
			-- beside it, just under the topbar at the margin (obbyBeside).
			local sameRow = o.y == p.y
			if not sameRow and p.y < 8 and o.y == 8 then
				sameRow = true
				table.insert(lowered, tag)
			end
			-- Off a phone's row its own widths; on the row the words alone, its plate
			-- drawn exactly its touch area.
			local e = CFG.Phone.RowStroke * 2
			local rowPlate = L.obbyPlate == Vector2.new(CFG.Phone.Row.Obby - e, 44 - e)
				or L.obbyPlate == Vector2.new(CFG.Phone.RowTight.Obby - e, 44 - e)
			local ok = sameRow and o.h == p.h and o.h >= 44 and o.w >= 44 and (onRight or onLeft)
				and (if L.topRow then not L.obbyWide and rowPlate and o.w == (L.obbyPlate.X + e) * L.teleportScale
					else o.w == (if L.obbyWide then OBBY.Size.X else OBBY.Narrow))
				and o.x >= 8 and o.x + o.w <= sw - 8 and o.y + o.h <= sh - 8 and inFreeSpan
			local note = r2s(o) .. " beside " .. r2s(p)
			local others = { { "the toast", L.toast }, { "the tutorial banner", L.banner }, { "its skip line", L.skip } }
			for _, g in ipairs(HudLayout.groups(L, true)) do
				table.insert(others, { g.name, g.rect })
			end
			local indexBadge, gardenBadge = HudLayout.badges(L)
			table.insert(others, { "the Index badge", indexBadge })
			table.insert(others, { "the Garden badge", gardenBadge })
			if L.thumb then
				table.insert(others, { "the thumbstick", L.thumb })
			end
			if L.jump then
				table.insert(others, { "the jump button", L.jump })
			end
			if L.chooser then
				table.insert(others, { "the chooser", L.chooser })
			end
			local a = L.admin
			if a then
				table.insert(others, { "ADMIN", rect(a.x - originX, a.y - TOPBAR, a.w, a.h) })
			end
			-- The notice band with the widest biome name, and the boost row.
			local dx, top = HudLayout.notice(L, widest, 30, 50 - TOPBAR)
			table.insert(others, { "the biome name", rect(sw / 2 + dx - widest / 2, top, widest, 30) })
			local _, _, boosts = HudLayout.statusRows(L, TOPBAR)
			table.insert(others, { "the boost row", boosts })
			for _, other in ipairs(others) do
				if HudLayout.gap(o, other[2]) < 8 - 1e-6 then
					ok = false
					note ..= " meets " .. other[1]
				end
			end
			-- Never over the clock: on a phone it stands on the clock's own row, 8 px clear of it.
			local clock = L.clock
			if clock then
				local inset = o.h * (1 - L.teleportScale) / 2
				local drawn = rect(o.x + originX + o.w * (1 - L.teleportScale) / 2, o.y + TOPBAR + inset,
					o.w * L.teleportScale, o.h - inset * 2)
				if HudLayout.gap(drawn, clock) < 8 - 1e-6 then
					ok = false
					note ..= " meets the clock"
				end
			end
			check(ok, tag .. ": OBBY stands on TELEPORT's row, " .. apart .. " px beside it, clear of everything", note)
			-- The DRAWN room: a label's least size is a drawn size (2026-09-30).
			local room = (if L.obbyWide then L.obbyPlate.X - 50 else L.obbyPlate.X - 12) * L.teleportScale
			check(room >= word, tag .. ": its word fits at 10 px drawn" .. (if L.obbyWide then " beside its icon" else ""),
				string.format("%.0f of %.1f", word, room))
		end
	end
	check(#hidden == 0, "every listed screen has room for it beside TELEPORT", table.concat(hidden, ", "))
	say(string.format("  (right of TELEPORT on %d screens, left on %d; the word alone on: %s; under the topbar on: %s)",
		right, left, if #narrow > 0 then table.concat(narrow, ", ") else "none",
		if #lowered > 0 then table.concat(lowered, ", ") else "none"))
	-- A free span that ends early (something of Roblox's on the right): the row
	-- keeps its order inside it -- the clock at the span's end, the buttons from
	-- its start -- and the warning runs from the row's start over the buttons'
	-- empty slots, never past the row's free end (the mobile corrections).
	do
		local input = screen(956, 440, { touch = true })
		input.topbar = rect(40, 0, 956 / 2 + CFG.Phone.Clock / 2 + 8 - 40, TOPBAR)
		local L = HudLayout.solve(input)
		local c, o, p, b = L.clock, L.obby, L.teleport, L.biomes
		local RG = CFG.Phone.RowGap
		local originX = (956 - L.safe.X) / 2
		check(L.topRow == true and c ~= nil and c.x + c.w == input.topbar.x + input.topbar.w - 8
				and b.x == input.topbar.x + 8 and p.x == b.x + b.w + RG and o.x == p.x + p.w + RG
				and o.x + o.w + 8 <= c.x - originX,
			"where the free span ends early the row keeps its order inside it: BIOMES, PLOT, OBBY, the clock",
			r2s(b) .. " / " .. r2s(p) .. " / " .. r2s(o) .. " / " .. (if c then r2s(c) else "nil"))
		local line = HudLayout.statusLine(L, TOPBAR, 179)
		check(line.w == 179 and line.x == L.rowLo and L.rowEnd ~= nil and line.x + line.w <= L.rowEnd,
			"and there the warning runs from the row's start over the three slots, inside the row's free span",
			r2s(line))
	end
	-- A screen with no room either side gets an empty rect, and the button stays hidden.
	local tiny = HudLayout.solve(screen(330, 500, { touch = true }))
	check(tiny.obby.w == 0 or HudLayout.gap(tiny.obby, tiny.teleport) >= 8 - 1e-6,
		"a screen too small for it beside TELEPORT leaves it out rather than on top of anything", r2s(tiny.obby))

	-- The wiring: placed by HudLayout at TELEPORT's scale, one verb and nothing
	-- else, the Safe Zone and the course the server's own flags, D-pad Right,
	-- no loop -- and the chase warning never shares the row with it.
	local obbySrc = sourceOf("ObbyButtonUI") or ""
	check(obbySrc:find("layout.obby", 1, true) ~= nil and obbySrc:find("layout.obbyWide", 1, true) ~= nil
			and obbySrc:find("plateScale.Scale = layout.teleportScale", 1, true) ~= nil
			and obbySrc:find("remote:FireServer(WheelData.Actions.ObbyTeleport)", 1, true) ~= nil
			and select(2, obbySrc:gsub("FireServer%(", "")) == 1
			and obbySrc:find("GetAttribute(ATTR.InSafeZone) == true", 1, true) ~= nil
			and obbySrc:find("GetAttribute(ObbyData.Attributes.Course) ~= true", 1, true) ~= nil
			and obbySrc:find("Enum.KeyCode.DPadRight", 1, true) ~= nil
			and obbySrc:find("PadInput.panelOpen()", 1, true) ~= nil
			and obbySrc:find('GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)', 1, true) ~= nil
			and obbySrc:find("UIKit.tenFoot(gui)", 1, true) ~= nil
			and not obbySrc:find("while true", 1, true) and not obbySrc:find("RenderStepped", 1, true),
		"ObbyButtonUI: placed by HudLayout at TELEPORT's scale, sends one verb and nothing else, shows only in the "
			.. "Safe Zone off the course, answers D-pad Right, and runs no loop")
end

--==============================================================================
-- THE BIOMES BUTTON (2026-09-30): ON TELEPORT'S OTHER SIDE
--
-- The owner's one-destination button, on a phone and a desktop alike. On a
-- phone's top row it is the row's first button (held with the row, above).
-- Everywhere else it stands on TELEPORT's row and height, exactly 8 px off it,
-- on the side OBBY left free -- BIOMES | TELEPORT TO PLOT | OBBY on a desktop --
-- and on every listed screen it clears every group and badge, both thumbs, the
-- toast, the tutorial banner, an open chooser, ADMIN, the clock, OBBY, the
-- biome name and the boost row by 8 px, its word fitting at 10 px. A desktop
-- moves nothing else for it (section 1 still holds to the pixel).
--==============================================================================
say("\n-- the BIOMES button --")
do
	local B = CFG.Biomes
	local word = TextService:GetTextSize("BIOMES", 10, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	local word9 = TextService:GetTextSize("BIOMES", 9, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	local hidden, wordOnly, sides = {}, {}, { left = 0, right = 0 }
	for _, case in ipairs(everyScreen) do
		local L = HudLayout.solve(case.input)
		local tag = case.tag
		local b, p, o = L.biomes, L.teleport, L.obby
		local sw, sh = L.safe.X, L.safe.Y
		if b.w <= 0 then
			table.insert(hidden, tag)
		else
			local originX = (case.input.viewport.X - sw) / 2
			local bar = case.input.topbar
			local inFreeSpan = b.y >= 0 or (bar ~= nil and b.x + originX >= bar.x + 8
				and b.x + b.w + originX <= bar.x + bar.w - 8)
			-- A phone's row is one even row, RowGap apart (2026-10-05); 8 elsewhere.
			local apart = if L.topRow then CFG.Phone.RowGap else 8
			local onLeft = math.abs(b.x + b.w + apart - p.x) < 1e-6
			local onRight = math.abs(b.x - (p.x + p.w + apart)) < 1e-6
			sides[if onLeft then "left" else "right"] += 1
			local otherSide = o.w <= 0 or ((o.x > p.x) ~= (b.x > p.x))
			local e = CFG.Phone.RowStroke * 2
			local rowPlate = L.biomesPlate == Vector2.new(CFG.Phone.Row.Biomes - e, 44 - e)
				or L.biomesPlate == Vector2.new(CFG.Phone.RowTight.Biomes - e, 44 - e)
			local widthOk = if L.topRow
				then not L.biomesWide and rowPlate and b.w == (L.biomesPlate.X + e) * L.teleportScale
				else b.w == (if L.biomesWide then B.Size.X else B.Narrow)
			if not L.biomesWide then
				table.insert(wordOnly, tag)
			end
			local ok = b.y == p.y and (onLeft or onRight) and otherSide and widthOk and b.h == p.h and b.h >= 44
				and b.x >= 8 and b.x + b.w <= sw - 8 and b.y + b.h <= sh - 8 and inFreeSpan
			local note = r2s(b) .. " beside " .. r2s(p) .. " / OBBY " .. r2s(o)
			local others = { { "OBBY", o }, { "the toast", L.toast }, { "the tutorial banner", L.banner },
				{ "its skip line", L.skip } }
			for _, g in ipairs(HudLayout.groups(L, true)) do
				table.insert(others, { g.name, g.rect })
			end
			local indexBadge, gardenBadge = HudLayout.badges(L)
			table.insert(others, { "the Index badge", indexBadge })
			table.insert(others, { "the Garden badge", gardenBadge })
			for _, maybe in ipairs({ { "the thumbstick", L.thumb }, { "the jump button", L.jump } }) do
				if maybe[2] then
					table.insert(others, maybe)
				end
			end
			local a = L.admin
			if a then
				table.insert(others, { "ADMIN", rect(a.x - originX, a.y - TOPBAR, a.w, a.h) })
			end
			local clock = L.clock
			if clock then
				table.insert(others, { "the clock", rect(clock.x - originX, clock.y - TOPBAR, clock.w, clock.h) })
			end
			local dx, top = HudLayout.notice(L, widest, 30, 50 - TOPBAR)
			table.insert(others, { "the biome name", rect(sw / 2 + dx - widest / 2, top, widest, 30) })
			local _, _, boosts = HudLayout.statusRows(L, TOPBAR)
			table.insert(others, { "the boost row", boosts })
			for _, other in ipairs(others) do
				local r = other[2]
				-- OBBY is the row's own neighbour on a phone, RowGap off it.
				local least = if other[1] == "OBBY" and L.topRow then apart else 8
				if r.w > 0 and HudLayout.gap(b, r) < least - 1e-6 then
					ok = false
					note ..= " meets " .. other[1]
				end
			end
			check(ok, tag .. ": BIOMES stands on TELEPORT's row, " .. apart .. " px on OBBY's other side, clear of "
				.. "everything", note)
			-- The DRAWN room (a label's least size is a drawn size): at 10 px, or 9
			-- where an old row drew it tight -- on its plate, before the scale.
			local room = (if L.biomesWide then L.biomesPlate.X - 50 else L.biomesPlate.X - 8) * L.teleportScale
			local least = if L.biomesPlate.X == B.Tight then word9 else word
			check(room >= least, tag .. ": its word fits at " .. (if L.biomesPlate.X == B.Tight then "9" else "10")
					.. " px drawn" .. (if L.biomesWide then " beside its icon" else ""),
				string.format("%.0f of %.1f", least, room))
			-- A desktop's is the full button, icon and word, left of TELEPORT.
			if not L.compact then
				check(L.biomesWide and onLeft and b.w == B.Size.X,
					tag .. ": on a desktop it is the full button, icon and word, on TELEPORT's left", r2s(b))
			end
		end
	end
	-- Every listed desktop and phone has it. A small desktop WINDOW under about
	-- 840 px wide has no room beside TELEPORT and OBBY between the two top rows
	-- (700 x 400: 10 px on the left, 45 on the right), and there it stays hidden
	-- rather than cover anything, as OBBY would.
	local missing = {}
	for _, tag in ipairs(hidden) do
		if not (tag:find(" window", 1, true) and tonumber(tag:match("^(%d+)x")) < 840) then
			table.insert(missing, tag)
		end
	end
	check(#missing == 0, "every listed desktop and phone has room for it beside TELEPORT", table.concat(missing, ", "))
	say("  (hidden, no room beside TELEPORT, on: " .. (if #hidden > 0 then table.concat(hidden, ", ") else "none") .. ")")
	say(string.format("  (left of TELEPORT on %d screens, right on %d; the word alone on: %s)", sides.left,
		sides.right, if #wordOnly > 0 then table.concat(wordOnly, ", ") else "none"))
	-- A screen with no room either side gets an empty rect, and the button stays hidden.
	local tiny = HudLayout.solve(screen(330, 500, { touch = true }))
	check(tiny.biomes.w == 0 or (HudLayout.gap(tiny.biomes, tiny.teleport) >= 8 - 1e-6
			and (tiny.obby.w == 0 or HudLayout.gap(tiny.biomes, tiny.obby) >= 8 - 1e-6)),
		"a screen too small for it beside TELEPORT leaves it out rather than on top of anything", r2s(tiny.biomes))

	-- The wiring: placed by HudLayout at TELEPORT's scale, ONE verb and nothing
	-- after it -- never a biome or a position -- the Safe Zone and the course the
	-- server's own flags, D-pad Left, no loop.
	local biomesSrc = sourceOf("BiomesButtonUI") or ""
	check(biomesSrc:find("layout.biomes", 1, true) ~= nil and biomesSrc:find("layout.biomesWide", 1, true) ~= nil
			and biomesSrc:find("plateScale.Scale = layout.teleportScale", 1, true) ~= nil
			and biomesSrc:find("remote:FireServer(PLOT.BiomesAction)", 1, true) ~= nil
			and select(2, biomesSrc:gsub("FireServer%(", "")) == 1
			and biomesSrc:find("GetAttribute(ATTR.InSafeZone) == true", 1, true) ~= nil
			and biomesSrc:find("GetAttribute(ObbyData.Attributes.Course) ~= true", 1, true) ~= nil
			and biomesSrc:find("Enum.KeyCode.DPadLeft", 1, true) ~= nil
			and biomesSrc:find("button.Selectable = true", 1, true) ~= nil
			and biomesSrc:find("PadInput.panelOpen()", 1, true) ~= nil
			and biomesSrc:find('GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)', 1, true) ~= nil
			and biomesSrc:find("UIKit.tenFoot(gui)", 1, true) ~= nil
			and not biomesSrc:find("while true", 1, true) and not biomesSrc:find("RenderStepped", 1, true),
		"BiomesButtonUI: placed by HudLayout at TELEPORT's scale, sends one verb and nothing else, shows only in the "
			.. "Safe Zone off the course, answers D-pad Left and the UI's selection, and runs no loop")
end

--==============================================================================
-- THE STATUS COLUMN (2026-09-27)
--
-- The chase warning used to be asked for at window y 84 and the boost timer at
-- 114, and HudLayout.notice stood BOTH under TELEPORT TO PLOT -- into the same
-- spot, one pill on the other (the owner's report). Now each has a band of its
-- own (statusRows): the warning in the teleport slot under the clock, the
-- obby's run line in the notice band, the boosts in a row under both. Measured
-- here with StatusText's real lines at their longest words, desktop and phone
-- size, on every listed screen:
--
--   * each fits its band whole, and clears every group and badge by 8 px;
--   * none overlaps another, the biome name's row or TELEPORT TO PLOT's rows
--     beyond the one slot the warning shares with it (never at the same time);
--   * a warning standing in the topbar stays inside its free span;
--   * the boost row stays above the middle of the screen and inside the safe
--     area -- and it is one answer whatever else is up, because statusRows
--     reads nothing but the layout.
--
-- ON A PHONE (2026-09-29; the owner's report that these words stood over the
-- obby's platforms and the player's forward view) the same three, moved out of
-- the middle:
--
--   * the warning in TELEPORT's slot BESIDE the clock, running on over OBBY's
--     empty slot and never over the clock (statusLine);
--   * the run's CLOCK ALONE in OBBY's slot on the course, and each stage's name
--     said once as a notice -- no line of words held up for the whole run;
--   * the boosts in a slim row right under the topbar, drawn at 13 px, side by
--     side and a little smaller where two are too wide (boostRows);
--   * the passing lines' band under that row, 4 px clear of it, where the
--     notices, the biome name and the sale line each stand a moment.
--==============================================================================
say("\n-- the status column --")
local StatusText = require(Shared:WaitForChild("StatusText"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local S = StatusText.Size
local function lineSize(opts, head, detail)
	local line = StatusText.new(opts)
	local size = line.set(head, detail)
	line.destroy()
	return size
end
local holder = Instance.new("Folder")
local warnW = 0
for _, words in ipairs({ "WAKING—RUN!", "CHASED!" }) do
	warnW = math.max(warnW, lineSize({ name = "W", parent = holder, size = S.status,
		tint = StatusText.Danger, icon = "warning" }, words).X)
end
local warnH = lineSize({ name = "W", parent = holder, size = S.status, tint = StatusText.Danger,
	icon = "warning" }, "CHASED!").Y
local function boostW(title, clock)
	return lineSize({ name = "B", parent = holder, size = S.boost, tint = Color3.new(1, 1, 1), icon = "boost",
		detailSize = S.boostClock, detailFont = StatusText.ClockFont }, title, clock).X
end
-- Two at once with a long clock, and one with an hour on it. The pair is the
-- wider of both chest rewards and -- since the sacrifice pedestal (2026-09-28),
-- whose boost stands in the same row -- the chest's widest reward beside the
-- pedestal's line. Its title is read from GameConfig, so the words measured
-- are the words drawn.
local pedestalTitle = GameConfig.sacrificeBoostTitle(SeedData.Sacrifice.Multiplier)
local incomeW, trainingW = boostW("+25% PLANT INCOME", "59:59"), boostW("+25% TRAINING", "59:59")
local pedestalW = boostW(pedestalTitle, "59:59")
local chestPair = incomeW + 18 + trainingW
local pedestalPair = incomeW + 18 + pedestalW
local twoBoosts = math.max(chestPair, pedestalPair)
local longBoost = boostW("+25% PLANT INCOME", "1:02:03")
-- The pairs that can stand in the row: the chest's one reward beside the
-- pedestal's line, and both chest rewards as the widest case measured before.
local boostPairs = { { incomeW, pedestalW }, { trainingW, pedestalW }, { incomeW, trainingW } }
local runW = 0
for _, stage in ipairs(ObbyData.Stages) do
	runW = math.max(runW, lineSize({ name = "R", parent = holder, size = S.run, tint = Color3.new(1, 1, 1),
		detailSize = S.runClock, detailFont = StatusText.ClockFont }, string.upper(stage.name), "9:59.9").X)
end
-- The phone's run clock, alone: under ten minutes, and the longest a run can
-- show before its third digit (a hundred minutes).
local function runClockW(text)
	return lineSize({ name = "RC", parent = holder, size = S.runClock, tint = Color3.new(1, 1, 1),
		headFont = StatusText.ClockFont }, text)
end
local runClock, runClockLong = runClockW("9:59.9"), runClockW("99:59.9")
local nameW = 0
for _, biome in ipairs(BiomeData.Biomes) do
	nameW = math.max(nameW, TextService:GetTextSize(string.upper(biome.DisplayName), 24,
		Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X + 3)
end
holder:Destroy()
say(string.format("  (longest: warning %d, two boosts %d, one long boost %d, run line %d, biome name %d px at desktop size)",
	warnW, twoBoosts, longBoost, runW, nameW))
local PS = StatusText.PhoneScale
say(string.format("  (on a phone: warning %.1f, two boosts %.1f, one long boost %.1f, the run's clock %.1f -- %.1f past "
	.. "ten minutes)", warnW * StatusText.SmallScale.status, (incomeW + pedestalW + 18) * PS.boost,
	longBoost * PS.boost, runClock.X * PS.runClock, runClockLong.X * PS.runClock))
check(PS.boost < StatusText.SmallScale.boost and S.boost * PS.boost >= 13 - 1e-6
		and S.boostClock * PS.boost >= 11 and S.runClock * PS.runClock >= 15 - 1e-6
		and S.boost * PS.boost * HudLayout.BoostShrink >= 10,
	"a phone's boost line is drawn at 13 px (its clock 11.5) and the run's clock at 15 -- and a row of two, drawn "
		.. "smaller to fit, never under 10",
	string.format("%.1f / %.1f / %.1f / %.1f", S.boost * PS.boost, S.boostClock * PS.boost, S.runClock * PS.runClock,
		S.boost * PS.boost * HudLayout.BoostShrink))

local columnCases = {}
for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1366, 768), Vector2.new(1600, 900),
	Vector2.new(1920, 1080), Vector2.new(2560, 1440), Vector2.new(1000, 609), Vector2.new(933, 714),
	Vector2.new(800, 500) }) do
	table.insert(columnCases, { tag = string.format("%dx%d desktop", size.X, size.Y),
		input = screen(size.X, size.Y) })
end
for _, case in ipairs(cases) do
	table.insert(columnCases, case)
end
local columnBad = {}
local function bad(tag, what)
	table.insert(columnBad, tag .. ": " .. what)
end
-- How many of the screens have the phone's column, and which draw two boosts
-- smaller than the phone's size to keep them side by side.
local phoneColumns, shrunk = 0, {}
for _, case in ipairs(columnCases) do
	local L = HudLayout.solve(case.input)
	local tag = case.tag
	local small = L.compact or L.sidebar
	-- The phone's column: every touch screen whose top row holds the buttons.
	local phone = L.sidebar == true and L.columnTop ~= nil
	local ks = if small then StatusText.SmallScale.status else 1
	local kb = if phone then PS.boost elseif small then StatusText.SmallScale.boost else 1
	local kr = if small then StatusText.SmallScale.run else 1
	local status, notice, boosts = HudLayout.statusRows(L, TOPBAR)
	local tp = L.teleport

	local others = {}
	for _, g in ipairs(HudLayout.groups(L, true)) do
		table.insert(others, g)
	end
	local ib, gb = HudLayout.badges(L)
	table.insert(others, { name = "Index badge", rect = ib })
	table.insert(others, { name = "Garden badge", rect = gb })
	local function clearOfGroups(what, r)
		for _, g in ipairs(others) do
			if HudLayout.gap(r, g.rect) < 8 - 1e-6 then
				bad(tag, string.format("%s %s is %.1f px from %s", what, r2s(r), HudLayout.gap(r, g.rect), g.name))
			end
		end
	end
	local function fitsWhole(what, band, width)
		local r = HudLayout.centreIn(L, band, width)
		if r.w < width - 0.5 then
			bad(tag, string.format("%s needs %d px and has %d", what, math.ceil(width), math.floor(r.w)))
		end
		clearOfGroups(what, r)
		return r
	end

	-- The warning: in the teleport slot, whole, inside the topbar's free span.
	if status.y < tp.y - 1e-6 or status.y + status.h > tp.y + tp.h + 1e-6 then
		bad(tag, "the warning's band leaves the teleport slot " .. r2s(status) .. " / " .. r2s(tp))
	end
	if warnH * ks > status.h + 1e-6 then
		bad(tag, string.format("the warning is %d tall in a %d band", warnH * ks, status.h))
	end
	local originX = (case.input.viewport.X - L.safe.X) / 2
	local middle = case.input.viewport.Y / 2 - TOPBAR
	local w
	if phone then
		-- ON THE CLOCK'S ROW (the owner's order, 2026-09-30): since the even row
		-- of 2026-10-05, from the row's start, RIGHT, over all three buttons'
		-- slots -- every one empty while a chase is on, the buttons being for the
		-- Safe Zone only -- whole, inside the row's free span (rowEnd) and never
		-- within 8 px of the clock or ADMIN.
		w = HudLayout.statusLine(L, TOPBAR, warnW * ks)
		phoneColumns += 1
		if w.w < warnW * ks - 0.5 then
			bad(tag, string.format("the warning needs %d px and has %d", math.ceil(warnW * ks), math.floor(w.w)))
		end
		if math.abs(w.x - L.rowLo) > 1e-6 or L.rowEnd == nil or w.x + w.w > L.rowEnd + 1e-6 then
			bad(tag, "the warning does not start at the row's start or runs past its free span " .. r2s(w)
				.. " / " .. tostring(L.rowEnd))
		end
		if w.x < L.rowLo - 1e-6 or w.x + w.w > L.rowHi + 1e-6 then
			bad(tag, "the warning leaves the row")
		end
		local c = L.clock
		if not c or HudLayout.gap(w, rect(c.x - originX, c.y - TOPBAR, c.w, c.h)) < 8 - 1e-6 then
			bad(tag, "the warning comes within 8 px of the clock")
		end
		local a = L.admin
		if a and HudLayout.gap(w, rect(a.x - originX, a.y - TOPBAR, a.w, a.h)) < 8 - 1e-6 then
			bad(tag, "the warning comes within 8 px of ADMIN")
		end
		-- Nothing of it under the topbar, where the player's view begins.
		if w.y + w.h > 0 then
			bad(tag, "the warning reaches under the topbar")
		end
		clearOfGroups("the warning", w)
	else
		w = fitsWhole("the warning", status, warnW * ks)
	end
	if w.y < 0 then
		local bar = case.input.topbar
		if w.x + originX < bar.x + 8 or w.x + w.w + originX > bar.x + bar.w - 8 then
			bad(tag, "the warning, up in the topbar, leaves its free span")
		end
	end

	local row
	if phone then
		-- THE RUN'S CLOCK, ALONE, in OBBY's slot: whole at any time a run can show.
		local slot = L.run
		for _, size in ipairs({ runClock, runClockLong }) do
			if size.X * PS.runClock > slot.w + 1e-6 or size.Y * PS.runClock > slot.h + 1e-6 then
				bad(tag, string.format("the run's clock is %.1f x %.1f in a %g x %g slot", size.X * PS.runClock,
					size.Y * PS.runClock, slot.w, slot.h))
			end
		end
		if slot.y + slot.h > 0 then
			bad(tag, "the run's clock reaches under the topbar")
		end
		-- THE BOOSTS: every pair side by side on ONE row, drawn no smaller than
		-- BoostShrink, each whole and 8 px clear of every group; and one alone
		-- with an hour on its clock.
		local smallest = 1
		for _, pair in ipairs(boostPairs) do
			local widths = { pair[1] * kb, pair[2] * kb }
			local rows, shrink = HudLayout.boostRows(L, boosts, widths, 18 * kb)
			smallest = math.min(smallest, shrink)
			if #rows ~= 2 or shrink < HudLayout.BoostShrink or shrink > 1 then
				bad(tag, string.format("two boosts came back as %d rects at %.2f", #rows, shrink))
			end
			for i, r in ipairs(rows) do
				if r.y ~= boosts.y or r.h ~= boosts.h then
					bad(tag, "two boosts are stacked, not side by side " .. r2s(r))
				end
				if math.abs(r.w - widths[i] * shrink) > 1e-6 then
					bad(tag, string.format("a boost %.1f wide has %.1f", widths[i] * shrink, r.w))
				end
				if r.x < 8 - 1e-6 or r.x + r.w > L.safe.X - 8 + 1e-6 then
					bad(tag, "a boost leaves the safe area " .. r2s(r))
				end
				clearOfGroups("a boost", r)
			end
			if #rows == 2 and rows[2].x < rows[1].x + rows[1].w + 18 * kb * shrink - 1e-6 then
				bad(tag, "two boosts stand closer than their gap")
			end
			row = if row then HudLayout.union(row, HudLayout.union(rows[1], rows[#rows]))
				else HudLayout.union(rows[1], rows[#rows])
		end
		if smallest < 1 then
			table.insert(shrunk, string.format("%s (%.2f)", tag, smallest))
		end
		local lone, k1 = HudLayout.boostRows(L, boosts, { longBoost * kb }, 18 * kb)
		if #lone ~= 1 or k1 ~= 1 or math.abs(lone[1].w - longBoost * kb) > 1e-6 then
			bad(tag, "one boost alone is not drawn whole at the phone's size")
		else
			clearOfGroups("one long boost", lone[1])
		end
		-- THE COLUMN'S ORDER, from the topbar down: the boost row, then the
		-- passing lines' band -- the toast, the biome name -- NoticeGap under it.
		-- The top row's own buttons are all above the column.
		local top = L.columnTop
		if boosts.y ~= top + CFG.Phone.BoostTop or boosts.h ~= CFG.Phone.BoostHeight then
			bad(tag, "the boost row is not the first thing under the row " .. r2s(boosts))
		end
		if notice.y ~= top + CFG.Phone.NoticeTop
			or notice.y < boosts.y + boosts.h + CFG.Phone.NoticeGap - 1e-6 then
			bad(tag, "the passing lines' band is not NoticeGap under the boost row " .. r2s(notice))
		end
		-- The biome name still stands in that band; the toast is over the belt
		-- now (2026-10-04), not up here.
		local _, nameTop = HudLayout.notice(L, nameW, CFG.NoticeHeight, CFG.NoticeTop - TOPBAR)
		if nameTop ~= notice.y or L.toast.y <= notice.y + notice.h then
			bad(tag, string.format("the biome name (%g) is not in the band (%g), or the toast (%g) is up in it",
				nameTop, notice.y, L.toast.y))
		end
		if tp.y + tp.h > top + 1e-6 or L.obby.y + L.obby.h > top + 1e-6
			or L.biomes.y + L.biomes.h > top + 1e-6 then
			bad(tag, "a button of the top row reaches into the column")
		end
		-- 22 px down at most -- or right under ADMIN, on a phone whose row hangs it.
		local ad = L.admin
		local hungAt = if ad and L.clock and ad.y >= L.clock.y + L.clock.h then ad.y + ad.h - TOPBAR else nil
		if top > (hungAt or 22) + 1e-6 then
			bad(tag, "the column starts " .. top .. " px down")
		end
		-- The boosts, the band and the warning never share a row with each other.
		if HudLayout.gap(rect(0, w.y, L.safe.X, w.h), rect(0, boosts.y, L.safe.X, boosts.h)) < 8 - 1e-6 then
			bad(tag, "the warning's row comes within 8 px of the boost row")
		end
	else
		-- The obby's run line, in the notice band.
		local run = fitsWhole("the run line", notice, runW * kr)
		-- The boosts: two at once, and one with an hour on its clock.
		row = fitsWhole("two boosts", boosts, twoBoosts * kb)
		fitsWhole("one long boost", boosts, longBoost * kb)
		-- Stacked, not overlapping: the biome name's row, then the warning -- and
		-- the boosts under both, 8 px clear.
		local _, nameTop = HudLayout.notice(L, nameW, CFG.NoticeHeight, CFG.NoticeTop - TOPBAR)
		local name = rect(0, nameTop, L.safe.X, CFG.NoticeHeight)
		if HudLayout.gap(rect(0, w.y, L.safe.X, w.h), name) < 0 + 1e-6 then
			bad(tag, "the warning's row meets the biome name's")
		end
		if row.y < math.max(name.y + name.h, tp.y + tp.h, w.y + w.h) + 8 - 1e-6 then
			bad(tag, "the boost row is not 8 px under the name, the slot and the warning")
		end
		if run.y + run.h > row.y - 8 + 1e-6 then
			bad(tag, "the run line comes within 8 px of the boost row")
		end
		-- Two boosts through boostRows are exactly where centreIn put them.
		local rows, shrink = HudLayout.boostRows(L, boosts, { incomeW * kb, pedestalW * kb }, 18 * kb)
		local from = HudLayout.centreIn(L, boosts, (incomeW + pedestalW + 18) * kb)
		if shrink ~= 1 or #rows ~= 2 or rows[1].x ~= from.x or rows[1].y ~= from.y
			or math.abs(rows[2].x - (from.x + (incomeW + 18) * kb)) > 1e-6 then
			bad(tag, "boostRows moved a desktop's boosts")
		end
	end
	-- Above the middle of the screen, where the character and the reticle are,
	-- and inside the safe area.
	if row.y + row.h > middle - 8 + 1e-6 then
		bad(tag, string.format("the boost row reaches the middle (bottom %g, middle %g)", row.y + row.h, middle))
	end
	if row.y + row.h > L.safe.Y - 8 then
		bad(tag, "the boost row leaves the safe area")
	end
	-- One answer, asked twice: nothing in it depends on what is showing.
	local s2, n2, b2 = HudLayout.statusRows(L, TOPBAR)
	if r2s(s2) ~= r2s(status) or r2s(n2) ~= r2s(notice) or r2s(b2) ~= r2s(boosts) then
		bad(tag, "statusRows gave two answers for one screen")
	end
end
check(#columnBad == 0, string.format("on all %d screens the warning, the run line and the boost row fit whole, "
	.. "clear every group and badge by 8 px, stack without overlapping, and keep off the middle", #columnCases),
	table.concat(columnBad, "; "))
check(phoneColumns == #cases, "every listed phone has the column: the top row holds its buttons on all of them",
	phoneColumns .. " of " .. #cases)
say("  (two boosts are drawn smaller than the phone's size, to stay side by side, on: "
	.. (if #shrunk > 0 then table.concat(shrunk, ", ") else "none") .. ")")

-- The wiring: each owner places its line with statusRows and HudLayout's own
-- placing for it -- the warning by statusLine, the boosts by boostRows, the
-- run line by centreIn; nothing is a pill any more, and the chest's row no
-- longer looks the warning up.
local alertSrc = sourceOf("AlertUI") or ""
local chestSrc = sourceOf("BonusChestUI") or ""
local obbySrc = sourceOf("ObbyUI") or ""
local PLACED_BY = {
	AlertUI = "HudLayout.statusLine(layout, inset,",
	ObbyUI = "HudLayout.centreIn(layout,",
}
for name, src in pairs({ AlertUI = alertSrc, ObbyUI = obbySrc }) do
	check(src:find("HudLayout.statusRows(layout, inset)", 1, true) ~= nil
			and src:find(PLACED_BY[name], 1, true) ~= nil
			and src:find("StatusText.new({", 1, true) ~= nil
			and not src:find("UICorner", 1, true) and not src:find("UIPadding", 1, true)
			and not src:find("HudLayout.notice(", 1, true),
		name .. " draws its indicator as a StatusText line in its statusRows band: no corner, no padding, no plate")
end
--==============================================================================
-- THE BUFF ROW ON A PHONE, AND ITS POPOVER (2026-10-09, the owner: move the
-- row off the middle of the screen, and the popover CLEAR of the guide card and
-- the HUD's words, still transparent -- seen on a 705 x 338 phone: the row on
-- the character, the popover's words through the guide card's)
--==============================================================================
say("\n-- the buff row on a phone, and its popover --")
do
	local rowBad, popBad, moved = {}, {}, 0
	local asideOn = {}
	local POP = GameConfig.BoostIcons.Popover
	for _, case in ipairs(everyScreen) do
		for _, n in ipairs({ 1, 3 }) do
			local input = table.clone(case.input)
			input.icons = n
			local L = HudLayout.solve(input)
			local row = L.icons
			if not row then
				table.insert(rowBad, case.tag .. ": no row")
			else
				local tag = string.format("%s, %d buff(s)", case.tag, n)
				if L.sidebar then
					-- Over the strip's right end, and right of the character's band.
					if math.abs(row.x + row.w - (L.hotbar.x + L.hotbar.w)) > 1e-6
						or row.x < L.safe.X / 2 + CFG.Phone.Guide.Clear - 1e-6 then
						table.insert(rowBad, tag .. " " .. r2s(row) .. " strip " .. r2s(L.hotbar))
					end
				end
				local inset = case.input.insetTop or 0
				for _, guide in ipairs({ false, true }) do
					local size = Vector2.new(if L.sidebar then POP.PhoneWidth else POP.Width, 100)
					local cx = row.x + row.w - L.iconSize / 2
					local r, clear = HudLayout.popoverRect(L, cx, size, POP.Gap, inset, guide)
					-- Where nothing is clear of the guide card, the card's words step aside
					-- (BoostIconsUI, TutorialUI) and the popover stands where it would
					-- without them (2026-10-09).
					local cardAside = guide and not clear
					if cardAside then
						r = HudLayout.popoverRect(L, cx, size, POP.Gap, inset, false)
						asideOn[case.tag] = true
					end
					local why = nil
					if r.x < CFG.Margin - 1e-6 or r.y < CFG.Margin - 1e-6 or r.x + r.w > L.safe.X - CFG.Margin + 1e-6
						or r.y + r.h > L.safe.Y - CFG.Margin + 1e-6 then
						why = "outside the margin"
					end
					-- The notices' line is theirs only while one passes (HudLayout.popoverRect).
					local blocked = {}
					for _, b in ipairs(HudLayout.occupied(L)) do
						if b ~= L.toast then
							table.insert(blocked, b)
						end
					end
					local status, notice = HudLayout.statusRows(L, inset)
					table.insert(blocked, status)
					table.insert(blocked, notice)
					if guide and not cardAside then
						table.insert(blocked, L.banner)
						table.insert(blocked, L.skip)
					end
					for _, b in ipairs(blocked) do
						if not why and b.w > 0 and b.h > 0 and HudLayout.gap(r, b) < CFG.Gap - 1e-6 then
							why = "near " .. r2s(b)
						end
					end
					if r.y + r.h + POP.Gap ~= row.y then
						moved += 1
					end
					if why then
						table.insert(popBad, string.format("%s%s %s: %s", tag, if guide then " (guide)" else "", r2s(r), why))
					end
				end
			end
		end
	end
	check(#rowBad == 0, "every phone's buff row stands over the strip's right end, right of the character's band -- "
		.. "never centred over it", table.concat(rowBad, "; "))
	check(#popBad == 0, "the buff popover stands inside the margin, 8 px clear of every group and badge, the "
		.. "status rows and, while it shows, the guide card -- on every listed screen with one and with three "
		.. "buffs; where nothing is clear of the card, the card's words step aside",
		table.concat(popBad, "; "))
	do
		local list = {}
		for tag in pairs(asideOn) do
			table.insert(list, tag)
		end
		table.sort(list)
		say("  (the guide card's words step aside for the popover on: " .. table.concat(list, ", ") .. ")")
		local only = #list > 0
		for _, tag in ipairs(list) do
			only = only and (string.find(tag, "^705x338") ~= nil or tag == "700x400 window")
		end
		check(only, "only the 705 x 338 phone and the 700 x 400 window send the guide card's words aside for the "
			.. "popover", table.concat(list, ", "))
	end
	say(string.format("  (the popover stood elsewhere than over its icon in %d of the %d cases)", moved,
		#everyScreen * 4))
	-- The guide card and the status rows are what it keeps off: put the card,
	-- then a status band, where it would stand over its icon, and it moves;
	-- with the card down it stands there again.
	do
		-- A desktop: room all round its icon to move to.
		local L = HudLayout.solve((function()
			local input = screen(1366, 768)
			input.icons = 1
			return input
		end)())
		local row = L.icons
		local size = Vector2.new(POP.Width, 100)
		local cx = row.x + row.w - L.iconSize / 2
		local want = HudLayout.popoverRect(L, cx, size, POP.Gap, TOPBAR, false)
		local carded = table.clone(L)
		carded.banner = rect(want.x, want.y, want.w, want.h)
		local away = HudLayout.popoverRect(carded, cx, size, POP.Gap, TOPBAR, true)
		local still = HudLayout.popoverRect(carded, cx, size, POP.Gap, TOPBAR, false)
		check(HudLayout.gap(away, carded.banner) >= CFG.Gap - 1e-6 and r2s(still) == r2s(want)
				and want.y + want.h + POP.Gap == row.y,
			"the popover stands over its icon, keeps off the guide card only while the card shows, and moves for it",
			r2s(want) .. " " .. r2s(away) .. " " .. r2s(still))
	end
	local popSrc = sourceOf("BoostIconsUI") or ""
	-- The Pod Rush tracker's words too (seen in Play: the popover on it): kept
	-- off where a place lets it; where none does the popover stands where it
	-- would without them and the tracker steps aside until it closes.
	do
		local L = HudLayout.solve((function()
			local input = screen(1366, 768)
			input.icons = 1
			return input
		end)())
		local row = L.icons
		local size = Vector2.new(POP.Width, 100)
		local cx = row.x + row.w - L.iconSize / 2
		local want, clear0 = HudLayout.popoverRect(L, cx, size, POP.Gap, TOPBAR, false)
		local tracker = rect(want.x, want.y, want.w, want.h)
		local moved, clear1 = HudLayout.popoverRect(L, cx, size, POP.Gap, TOPBAR, false, { tracker })
		local wall = rect(CFG.Margin, CFG.Margin, L.safe.X - CFG.Margin * 2, L.safe.Y - CFG.Margin * 2)
		local _, clear2 = HudLayout.popoverRect(L, cx, size, POP.Gap, TOPBAR, false, { wall })
		check(clear0 and clear1 and HudLayout.gap(moved, tracker) >= CFG.Gap - 1e-6 and clear2 == false,
			"the popover keeps off the Pod Rush tracker's words where a place lets it, and says when none does",
			r2s(want) .. " " .. r2s(moved))
	end
	local rushSrc = sourceOf("PodRushUI") or ""
	check(rushSrc:find("player:GetAttribute(GameConfig.BoostIcons.CoversAttribute) ~= true", 1, true) ~= nil
			and popSrc:find("local covers = coversFor == id or (not clear and (#rush > 0 or guide))", 1, true) ~= nil
			and popSrc:find("setCovers(covers)", 1, true) ~= nil,
		"with no place clear of the tracker (or the guide card) the popover sends it aside until it closes "
			.. "(BoostIconsUI, PodRushUI)")
	-- AND THE GUIDE CARD (2026-10-09): where nothing is clear of the card either
	-- -- a 705 x 338 phone under the panel's row -- the popover stands where it
	-- would without the card, and the card's words step aside until it closes.
	check(popSrc:find("\tlocal at, clear = HudLayout.popoverRect(L, cx, size, CFG.Popover.Gap, lastInsetTop, guide, rush)\n",
				1, true) ~= nil
			and popSrc:find("if guide and not clearOfCard then\n\t\t\tat = HudLayout.popoverRect(L, cx, size, "
				.. "CFG.Popover.Gap, lastInsetTop, false)", 1, true) ~= nil
			and popSrc:find("local guide = UIKit.guideShowing(playerGui)", 1, true) ~= nil
			and popSrc:find("popover.Position = HudLayout.place(HudLayout.rect(at.x, at.y + at.h, width, 0)", 1, true) ~= nil,
		"BoostIconsUI places the popover through HudLayout.popoverRect, with the guide card's state, and without "
			.. "the card where nothing is clear of it")
	-- The panels that cover the rail where Garden and the Bag stand under them:
	-- every UIKit.modal but MenuKit's own, on a compact screen or a phone.
	local kitSrc = Shared:FindFirstChild("UIKit").Source
	check(kitSrc:find("covers = HudLayout.solve(HudLayout.measure(gui)).compact == true", 1, true) ~= nil
			and kitSrc:find("if options.fixedHeader or not playerGui then", 1, true) ~= nil
			and kitSrc:find("\t\topen = want\n\t\tcoverRail(want)\n", 1, true) ~= nil,
		"a UIKit.modal panel covers the rail while it is open on a compact screen or a phone (not MenuKit's: they "
			.. "do it themselves); a desktop's stand between the rails")
end

-- The boosts are icons over the hotbar now (2026-10-04): BoostIconsUI places
-- them in the layout's own `icons` rect, publishes how many stand, and the
-- chest's script draws no line of its own.
local iconsSrc = sourceOf("BoostIconsUI") or ""
check(iconsSrc:find("local r = L.icons", 1, true) ~= nil
		and iconsSrc:find("size = L.iconSize", 1, true) ~= nil
		and iconsSrc:find("player:SetAttribute(CFG.Attribute, want)", 1, true) ~= nil
		and iconsSrc:find("-- Published BEFORE placing: the layout reads it.\n\t\tpublishCount(#list)\n\t\tplace()", 1, true) ~= nil
		and not chestSrc:find("StatusText.new(", 1, true) and not chestSrc:find("HudLayout.", 1, true),
	"BoostIconsUI places the icon row in HudLayout's icons rect at its iconSize, and publishes its count before "
		.. "it places; BonusChestUI draws no status line any more")
check(obbySrc:find("local slot = layout.run", 1, true) ~= nil
		and obbySrc:find("local alone = layout.sidebar and slot.w > 0", 1, true) ~= nil
		and obbySrc:find("runTime.setScale(StatusText.PhoneScale.runClock)", 1, true) ~= nil
		and obbySrc:find("headFont = StatusText.ClockFont", 1, true) ~= nil
		and obbySrc:find("plate.Size = UDim2.fromOffset(layout.returnPlate.X, layout.returnPlate.Y)", 1, true) ~= nil
		and obbySrc:find("local r = layout.returnPlot", 1, true) ~= nil
		and obbySrc:find("key = \"obby:stage\", quiet = true", 1, true) ~= nil
		and obbySrc:find("return if clockAlone then seconds else nil", 1, true) ~= nil,
	"ObbyUI: on a phone the run's clock alone in HudLayout's `run` slot, each stage's name said once as a quiet "
		.. "notice, the course's notices brief -- and everywhere else the line and the times they had")
do
	local walkSrc = sourceOf("WalkModeUI") or ""
	local clockSrc = sourceOf("WorldClock") or ""
	check(walkSrc:find("slab.Visible = not (phone and ObbyData.onCourse(player)) and not away", 1, true) ~= nil
			and walkSrc:find("phone = layout.sidebar == true", 1, true) ~= nil
			and walkSrc:find("away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil", 1, true) ~= nil
			and walkSrc:find("GetAttributeChangedSignal(ObbyData.Attributes.Course)", 1, true) ~= nil
			and walkSrc:find("GetAttributeChangedSignal(ATTR.OpenPanel)", 1, true) ~= nil,
		"WalkModeUI puts its switch away on the course on a touch screen only -- a desktop keeps it, there too -- "
			.. "and off a desktop steps it aside while a panel is open, as EVENTS does")
	check(clockSrc:find("chip = layout.clockChip", 1, true) ~= nil,
		"WorldClock draws the chip's face where HudLayout says the clock is a chip")
	-- The chip's words, read from WorldClock's own source: each fits the chip's
	-- line (its width less 5 px a side, less the cycle icon and its gap since
	-- 2026-10-04) at the smallest size TextScaled may take it to, and the time
	-- under it at its own.
	local said = {}
	for words in string.gmatch(clockSrc, '\n\t\twords = "([^"]+)"') do
		table.insert(said, words)
	end
	local room = CFG.Phone.Clock - 10 - CFG.Phone.ClockIcon - CFG.Phone.ClockIconGap
	local tooWide = {}
	for _, words in ipairs(said) do
		local w = TextService:GetTextSize(words, 7, Enum.Font.GothamBlack, Vector2.new(4000, 100)).X
		if w > room then
			table.insert(tooWide, string.format("%s (%d)", words, w))
		end
	end
	local timeW = TextService:GetTextSize("00:00", 17, Enum.Font.GothamBlack, Vector2.new(4000, 100)).X
	check(#said == 3 and #tooWide == 0 and timeW <= room
			and clockSrc:find("chipWordsCap.MinTextSize = 7", 1, true) ~= nil
			and clockSrc:find("chipTime.TextSize = 17", 1, true) ~= nil
			and clockSrc:find("local CHIP_TEXT_X = 5 + LAYOUT.Phone.ClockIcon + LAYOUT.Phone.ClockIconGap", 1, true) ~= nil,
		"the chip's three sentences fit its line beside the cycle icon at 7 px or more, and the time under them at 17",
		string.format("%d read; too wide: %s; time %d of %d", #said, table.concat(tooWide, ", "), timeW, room))
end
check(not chestSrc:find("DangerPill", 1, true),
	"the boost row stands in its own band rather than stepping under the warning")
check(alertSrc:find("GetAttributeChangedSignal(ATTR.InSafeZone)", 1, true) ~= nil
		and alertSrc:find("if not inSafeZone() then\n\t\tstatus.show()", 1, true) ~= nil,
	"the warning stands down inside the Safe Zone, where TELEPORT TO PLOT shares its slot")

-- The wiring: one owner each, both placed by HudLayout, the button's verb
-- carries nothing, and the server's re-check is the one that decides.
local toastSrc = sourceOf("ActionToastUI") or ""
local teleSrc = sourceOf("PlotTeleportUI") or ""
check(toastSrc:find("layout.toast", 1, true) ~= nil and toastSrc:find("HudLayout.noticeStack(layout", 1, true) ~= nil
		and toastSrc:find("Notice.step(", 1, true) ~= nil
		and toastSrc:find("gui.DisplayOrder = 13", 1, true) ~= nil
		and not toastSrc:find("while true", 1, true),
	"the notices are placed by HudLayout (toast + noticeStack), coalesced by Notice.step, drawn under prompts "
		.. "and panels, and run no loop")
check(teleSrc:find("layout.teleport", 1, true) ~= nil
		and teleSrc:find("remote:FireServer(PLOT.TeleportAction)", 1, true) ~= nil
		and teleSrc:find("GetAttribute(ATTR.InSafeZone) == true", 1, true) ~= nil
		and teleSrc:find("GetAttribute(ATTR.OwnPlotId) ~= nil", 1, true) ~= nil
		and teleSrc:find("Enum.KeyCode.DPadUp", 1, true) ~= nil
		and not teleSrc:find("while true", 1, true),
	"the teleport button sends its verb and nothing else, shows off the server's two flags, answers a controller, and runs no loop")
-- The phone's smaller tutorial (owner, 2026-09-24): one number from HudLayout,
-- applied to the banner, the pointing hand and its words (the gold pointer's
-- successor, 2026-10-08) and the celebration.
local tutorialSrc = sourceOf("TutorialUI") or ""
check(tutorialSrc:find("tutorialScale = layout.tutorialScale", 1, true) ~= nil
		and tutorialSrc:find("bannerScale.Scale = tutorialScale", 1, true) ~= nil
		and tutorialSrc:find("layout.banner.w / tutorialScale", 1, true) ~= nil
		and tutorialSrc:find("local size = Spot.Hand.Size * tutorialScale * k", 1, true) ~= nil
		and tutorialSrc:find("math.floor(Spot.Words.Size * tutorialScale * k + 0.5)", 1, true) ~= nil
		and tutorialSrc:find("{ Scale = full }", 1, true) ~= nil,
	"TutorialUI draws the banner, the hand and its words, and the celebration at HudLayout's tutorialScale")
-- Both stand under the clock, which moves with the topbar's free span: placed
-- again when it changes, as WorldClock is -- the stale button the owner saw.
check(teleSrc:find('GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)', 1, true) ~= nil
		and tutorialSrc:find('GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeBanner)', 1, true) ~= nil,
	"TELEPORT TO PLOT and the tutorial banner are placed again when the topbar's free span changes")

-- THE PHONE'S ARRANGEMENT, WIRED (2026-09-29): every owner reads it from the
-- layout -- none asks what kind of screen this is for itself.
check(teleSrc:find("plate.Size = UDim2.fromOffset(layout.teleportPlate.X, layout.teleportPlate.Y)", 1, true) ~= nil,
	"PlotTeleportUI draws its plate at HudLayout's teleportPlate, whatever the touch area round it")
check(toastSrc:find("fromTop = layout.toastTop", 1, true) ~= nil
		and toastSrc:find("metrics = if fromTop or layout.sidebar then PHONE elseif small then SMALL else FULL", 1, true) ~= nil
		and toastSrc:find("Notice.setReach(if fromTop and y > 0 then", 1, true) ~= nil
		and toastSrc:find("local depth = math.max(stackDepth, middle - CONFIG_GAP - stackTop)", 1, true) ~= nil
		and toastSrc:find("GetAttributeChangedSignal(GameConfig.BoostIcons.Attribute):Connect(place)", 1, true) ~= nil
		and toastSrc:find('GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)', 1, true) ~= nil,
	"ActionToastUI draws a phone's notices at the phone's size wherever they stand (over the belt since "
		.. "2026-10-04), re-places when the icon row's count changes, and follows the topbar's free span")
check(tutorialSrc:find("guide = layout.guide", 1, true) ~= nil
		and tutorialSrc:find("words.Visible = not ((guide and Notice.reach() ~= nil) or player:GetAttribute(COVERS) == true)",
			1, true) ~= nil
		and tutorialSrc:find("local COVERS = Config.BoostIcons.CoversAttribute", 1, true) ~= nil
		and tutorialSrc:find("player:GetAttributeChangedSignal(COVERS):Connect(coverWords)", 1, true) ~= nil
		and tutorialSrc:find("Notice.onReach(coverWords)", 1, true) ~= nil
		and tutorialSrc:find("if banner.Visible and not guide then", 1, true) ~= nil,
	"TutorialUI stands the guide's words in the left column where HudLayout says guide, stands them down while a "
		.. "notice is up or a buff popover covers them (2026-10-09), and pushes nothing down from there")
for _, name in ipairs({ "BiomeGuideUI", "SellUI" }) do
	local src = sourceOf(name) or ""
	check(src:find("Notice.reach())", 1, true) ~= nil and src:find("Notice.onReach(function()", 1, true) ~= nil
			and src:find("HudLayout.notice(", 1, true) ~= nil,
		name .. " stands its line under a notice that is up, by the reach ActionToastUI publishes")
end

--==============================================================================
-- THE GUIDE'S WORDS, EVERY ONE (2026-09-29)
--
-- Read out of TutorialData and out of TutorialUI's own source, and laid out as
-- TutorialUI lays its left-column block out: wrapped, two lines at the most, a
-- size smaller only when two lines will not hold them -- at every width a
-- listed phone gives the block. None is cut short at its smallest size, and
-- the tallest instruction over the tallest advice stands inside the block.
--==============================================================================
say("\n-- the guide's words on a phone --")
do
	local TutorialData = require(Shared:WaitForChild("TutorialData"))
	local G = { Line = 24, LineMin = 17, Sub = 15, SubMin = 13, Counter = 14, Gap = 3, Lines = 2 }
	check(tutorialSrc:find("local GUIDE = { Line = 24, LineMin = 17, Sub = 15, SubMin = 13, Counter = 14, Gap = 3, "
			.. "Lines = 2 }", 1, true) ~= nil,
		"TutorialUI lays the block out at the sizes measured here")
	local FONT = Enum.Font.LuckiestGuy
	local function wrappedAt(text, size, least, width, lines)
		local at = size
		while true do
			local one = TextService:GetTextSize("Ag", at, FONT, Vector2.new(10000, 10000)).Y
			local all = TextService:GetTextSize(text, at, FONT, Vector2.new(width, 10000)).Y
			if all <= one * lines + 1 or at <= least then
				return at, math.min(all, one * lines) + 2, all > one * lines + 1
			end
			at -= 1
		end
	end
	local heads, subs = {}, {}
	for _, step in ipairs(TutorialData.Steps) do
		heads[step.Title] = true
	end
	for text in string.gmatch(tutorialSrc, 'instruction%.Text = "([^"]+)"') do
		heads[text] = true
	end
	for a, b in string.gmatch(tutorialSrc, 'instruction%.Text = if [^\n]- then "([^"]+)" else "([^"]+)"') do
		heads[a] = true
		heads[b] = true
	end
	for text in string.gmatch(tutorialSrc, 'waitAtTheMill%("([^"]+)"%)') do
		heads[text] = true
	end
	for text in string.gmatch(tutorialSrc, 'subline%.Text = "([^"]+)"') do
		subs[text] = true
	end
	for a, b in string.gmatch(tutorialSrc, 'subline%.Text = if [^\n]- then "([^"]+)" else "([^"]+)"') do
		subs[a] = true
		subs[b] = true
	end
	-- The lines built as the game runs, at their longest.
	subs["Pods return at dawn in 9999s -- train while you wait!"] = true
	subs["Pods return at dawn -- train while you wait!"] = true
	subs["Ready in 9999s"] = true
	local headCount, subCount = 0, 0
	for _ in pairs(heads) do
		headCount += 1
	end
	for _ in pairs(subs) do
		subCount += 1
	end
	check(headCount >= #TutorialData.Steps + 3 and subCount >= 15,
		"the guide's lines were found in its source", headCount .. " instructions, " .. subCount .. " lines of advice")

	local ts = CFG.TutorialPhoneScale
	local GUIDE = CFG.Phone.Guide
	local widths = {}
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		if L.guide then
			widths[L.banner.w] = true
		end
	end
	local measured = 0
	for drawn in pairs(widths) do
		measured += 1
		local width = drawn / ts
		local cut = {}
		local tallHead, tallSub, smallHead, smallSub = 0, 0, G.Line, G.Sub
		for text in pairs(heads) do
			local size, height, clipped = wrappedAt(text, G.Line, G.LineMin, width, G.Lines)
			tallHead, smallHead = math.max(tallHead, height), math.min(smallHead, size)
			if clipped then
				table.insert(cut, text)
			end
		end
		for text in pairs(subs) do
			local size, height, clipped = wrappedAt(text, G.Sub, G.SubMin, width, G.Lines)
			tallSub, smallSub = math.max(tallSub, height), math.min(smallSub, size)
			if clipped then
				table.insert(cut, text)
			end
		end
		local total = GUIDE.Row + (G.Gap + tallHead + G.Gap + tallSub) * ts
		check(#cut == 0 and total <= GUIDE.Height,
			string.format("a block %g px wide holds every line the guide can say, whole, in two lines at the most "
				.. "(instructions drawn at %.1f px or more, advice at %.1f)", drawn, smallHead * ts, smallSub * ts),
			string.format("%.1f of %g px; cut short: %s", total, GUIDE.Height, table.concat(cut, " | ")))
	end
	check(measured >= 1, "the listed phones' guide blocks were measured", measured)
	-- The row above the words: the step counter in its own width, and Skip's
	-- longest word in the button's (it is drawn at 1, outside the banner's scale).
	local counterW = TextService:GetTextSize("STEP " .. #TutorialData.Steps .. " / " .. #TutorialData.Steps,
		G.Counter, FONT, Vector2.new(4000, 100)).X * ts
	local skipW = 0
	for _, words in ipairs({ "Skip guide", "Tap again to skip" }) do
		skipW = math.max(skipW, TextService:GetTextSize(words, 12, Enum.Font.GothamBold, Vector2.new(4000, 100)).X)
	end
	check(counterW <= CFG.Phone.Counter and skipW <= CFG.Phone.Skip.X
			and tutorialSrc:find('"Tap again to skip" else "Skip guide"', 1, true) ~= nil,
		"the step counter and Skip's longest word fit their places on the row above the words",
		string.format("counter %.1f of %g, skip %.1f of %g", counterW, CFG.Phone.Counter, skipW, CFG.Phone.Skip.X))
end

--==============================================================================
-- 9. THE TEN-FOOT PROFILE: A TV GETS THE DESKTOP, BIGGER, INSIDE TITLE-SAFE
--
-- The owner's approval of 2026-09-24. What measure() hands the owner of a gui
-- UIKit.tenFoot has scaled is HudLayout.tenFootInput of the physical facts; the
-- answer must be the desktop arrangement, every group inside the TV's
-- title-safe canvas (5% in from every edge), the window-space row brought down
-- to it, and nothing about a desktop or a phone answer different.
--==============================================================================
say("\n-- the TV --")
local T = CFG.TenFoot
check(math.abs(HudLayout.tenFootScale(Vector2.new(1920, 1080)) - 1.35) < 1e-9
		and HudLayout.tenFootScale(Vector2.new(1280, 720)) == 1
		and math.abs(HudLayout.tenFootScale(Vector2.new(3840, 2160)) - 2.7) < 1e-9
		and HudLayout.tenFootScale(Vector2.new(800, 600)) == 1,
	"the scale shows a TV's title-safe area as a 1280 x 720 canvas: 1.35 at 1080p, 2.7 at 4K, never below 1",
	string.format("%.3f %.3f %.3f", HudLayout.tenFootScale(Vector2.new(1920, 1080)),
		HudLayout.tenFootScale(Vector2.new(1280, 720)), HudLayout.tenFootScale(Vector2.new(3840, 2160))))

local function tvCase(w, h, inset, keyboard)
	local physical = {
		safe = Vector2.new(w, h - inset),
		touch = false,
		keyboard = keyboard,
		viewport = Vector2.new(w, h),
		topbar = rect(0, 0, 0, inset),
		insetTop = inset,
	}
	return HudLayout.tenFootInput(physical), HudLayout.tenFootScale(Vector2.new(w, h))
end

local tvCases = {
	{ tag = "1920x1080 Xbox, no topbar", w = 1920, h = 1080, inset = 0, keyboard = false },
	{ tag = "1920x1080, 58 topbar", w = 1920, h = 1080, inset = 58, keyboard = false },
	{ tag = "1920x1080 with a keyboard", w = 1920, h = 1080, inset = 58, keyboard = true },
	{ tag = "3840x2160", w = 3840, h = 2160, inset = 0, keyboard = false },
	{ tag = "1280x720", w = 1280, h = 720, inset = 36, keyboard = false },
}

for _, case in ipairs(tvCases) do
	local input, k = tvCase(case.w, case.h, case.inset, case.keyboard)
	local L = HudLayout.solve(input)
	local frame = L.frame
	local tag = case.tag
	-- Five roles, keyboard or not (2026-10-01): a controller reaches them with LB and RB.
	check(frame ~= nil and not L.compact and not L.touch and L.fits and L.slots == CFG.DesktopSlots,
		tag .. ": the desktop arrangement, on a title-safe frame, with its five slots",
		frame and r2s(frame))
	if frame then
		-- Every permanent group, badges included, inside the frame.
		local outside = {}
		for _, group in ipairs(HudLayout.groups(L, true)) do
			local r = group.rect
			if r.x < frame.x or r.y < frame.y or r.x + r.w > frame.x + frame.w
				or r.y + r.h > frame.y + frame.h then
				table.insert(outside, group.name .. " " .. r2s(r))
			end
		end
		for _, extra in ipairs({ { "toast", L.toast }, { "teleport", L.teleport }, { "OBBY", L.obby },
			{ "banner", L.banner }, { "skip", L.skip } }) do
			local r = extra[2]
			if r.x < frame.x or r.y < frame.y or r.x + r.w > frame.x + frame.w
				or r.y + r.h > frame.y + frame.h then
				table.insert(outside, extra[1] .. " " .. r2s(r))
			end
		end
		check(#outside == 0 and L.obby.w > 0,
			tag .. ": every group, the toast, TELEPORT TO PLOT, OBBY and the tutorial banner inside title-safe",
			table.concat(outside, "; "))
		check(#HudLayout.problems(L) == 0, tag .. ": nothing overlaps, every gap at least 8",
			table.concat(HudLayout.problems(L), "; "))
		-- Title-safe in the WINDOW: 5% of each edge, in the gui's logical units.
		local view = input.viewport :: Vector2
		local edgeX, edgeY = view.X * T.SafeEdge, view.Y * T.SafeEdge
		local clock, admin = L.clock, L.admin
		local function within(r)
			return r ~= nil and r.x >= edgeX - 1e-6 and r.y >= edgeY - 1e-6
				and r.x + r.w <= view.X - edgeX + 1e-6 and r.y + r.h <= view.Y - edgeY + 1e-6
		end
		check(within(clock) and within(admin),
			tag .. ": the clock and the ADMIN button come down inside the title-safe top edge",
			clock and r2s(clock))
		-- The notice band, with the widest biome name: under the clock, clear of
		-- TELEPORT TO PLOT, inside the window's title-safe area.
		local inset = input.insetTop or 0
		local dx, top = HudLayout.notice(L, widest, 30, CFG.NoticeTop - inset)
		local band = rect(L.safe.X / 2 + dx - widest / 2, top, widest, 30)
		local bandWindowTop = top + inset
		check(clock ~= nil and bandWindowTop >= clock.y + clock.h
				and HudLayout.gap(band, L.teleport) >= 8 - 1e-6 and bandWindowTop >= edgeY - 1e-6,
			tag .. ": the biome name sits under the clock, clear of the teleport button",
			string.format("band %s window top %.1f clock bottom %.1f", r2s(band), bandWindowTop,
				if clock then clock.y + clock.h else -1))
		check(HudLayout.gap(L.banner, L.teleport) >= 8 - 1e-6,
			tag .. ": the tutorial banner keeps 8 px under TELEPORT TO PLOT", r2s(L.banner))
		-- The Bag panel inside the frame too.
		local bag = HudLayout.bag(L, {
			hotTop = L.hotbar.y, stripHidden = false,
		})
		local p = bag.panel
		check(p.x >= frame.x and p.y >= frame.y and p.x + p.w <= frame.x + frame.w
				and p.y + p.h <= L.hotbar.y,
			tag .. ": the Bag panel stands inside the frame, above the strip", r2s(p))
		check(k >= 1 and L.hotbar.h == HudLayout.hotbarHeight(),
			tag .. string.format(": the desktop strip, drawn %.2fx -- %d px on the TV",
				k, math.round(HudLayout.hotbarHeight() * k)))
	end
end

-- A desktop or a phone is not a TV: no frame, no lift -- and section 1 holds
-- the desktop to the pixel with the TV profile in the module.
do
	local desk = HudLayout.solve(screen(1920, 1080))
	local phone = HudLayout.solve(screen(801, 392, { touch = true }))
	check(desk.frame == nil and desk.lift == nil and phone.frame == nil and phone.lift == nil,
		"a desktop and a phone answer carries no TV frame and no lift")
end

-- The wiring: every owner opts its gui in, and every pixel read that becomes
-- an Offset is divided by the gui's scale.
do
	local needs = {
		{ "CashUI", "UIKit.tenFoot(gui)" }, { "CashUI", "TextBounds.X / UIKit.scaleOf(gui)" },
		{ "LoadoutUI", "UIKit.tenFoot(gui)" }, { "LoadoutUI", "gui.AbsoluteSize / UIKit.scaleOf(gui)" },
		{ "WorldClock", "UIKit.tenFoot(gui)" }, { "WorldClock", "viewport.X / 2), 0, r.y)" },
		{ "ActionToastUI", "UIKit.tenFoot(gui)" }, { "PlotTeleportUI", "UIKit.tenFoot(gui)" },
		{ "ObbyButtonUI", "UIKit.tenFoot(gui)" }, { "WheelUI", "UIKit.tenFoot(gui)" },
		{ "WheelUI", "gui.AbsoluteSize / UIKit.scaleOf(gui)" },
		{ "BiomeGuideUI", "UIKit.tenFoot(gui)" }, { "BiomeGuideUI", "label.AbsoluteSize.X / UIKit.scaleOf(gui)" },
		-- TutorialUI's hand and spotlight live in a gui with NO UIScale (it has to
		-- cover the notch, 2026-10-08): its pixel reads stay pixels, and what it
		-- draws is multiplied by the TV scale instead.
		{ "TutorialUI", "UIKit.tenFoot(gui)" }, { "TutorialUI", "local k = UIKit.scaleOf(gui)" },
		{ "TutorialUI", "Spot.Hand.Size * tutorialScale * k" },
		{ "PlantPlace", "UIKit.tenFoot(padGui)" },
		{ "SellUI", "notice.AbsoluteSize.X / UIKit.scaleOf(gui)" },
		{ "ShopUI", "gui.AbsoluteSize / UIKit.scaleOf(gui)" },
		{ "IndexUI", "gui.AbsoluteSize / UIKit.scaleOf(gui)" },
		{ "SettingsUI", "rowsFrame.AbsoluteSize.X / UIKit.scaleOf(gui)" },
		{ "GardenUI", "gui.AbsoluteSize / UIKit.scaleOf(gui)" },
		{ "MarigoldShopUI", "list.AbsoluteSize.X / UIKit.scaleOf(gui)" },
		{ "OfflineUI", "modal.body.AbsoluteSize.X / k" },
		{ "PromptUI", "label.TextBounds.X / tv" },
	}
	local missing = {}
	for _, need in ipairs(needs) do
		local src = sourceOf(need[1]) or ""
		if not src:find(need[2], 1, true) then
			table.insert(missing, need[1] .. ": " .. need[2])
		end
	end
	check(#missing == 0, "every owner opts in to the TV scale and divides its pixel reads by it",
		table.concat(missing, "; "))
	local kit = Shared:FindFirstChild("UIKit")
	local kitSrc = if kit then (kit :: any).Source else ""
	check(kitSrc:find("\tUIKit.tenFoot(gui)\n\tlocal outline = RAIL.OutlineThickness", 1, true) ~= nil
			and kitSrc:find("UIKit.tenFoot(layer)", 1, true) ~= nil
			and kitSrc:find("gui.AbsoluteSize.Y / HudLayout.scaleOf(gui)", 1, true) ~= nil
			and kitSrc:find("if not (camera and HudLayout.isTenFoot()) then", 1, true) ~= nil,
		"every panel and the rail are scaled, a panel fits in the gui's own units, and off a TV no UIScale is made")
end


--==============================================================================
-- THE REMOVE ROW (2026-10-04, the reusable-trap brief)
--
-- While a trap is out, a small REMOVE stands just over the trap's own slot --
-- any slot. HudLayout reserves a strip-wide row for it right over the strip
-- (removeRow), and the item name's band, the boost icons and the notices all
-- stand over that row. Checked on every listed screen and every slot: the
-- button over its own slot, inside the strip's columns, clear of the name
-- band, the icons, the toast and the thumbs, a 44 px target on a touch screen,
-- and nothing else moved when no trap is out.
--==============================================================================
say("\n-- the REMOVE row --")
do
	local GAP = HOT.RemoveGap
	local noRowSame, rowShape, bandOver, iconsOver, toastOver, fitsAll = true, true, true, true, true, true
	local slotsOk, touchBig, wordsFit, countFits = true, true, true, true
	local notes = {}
	local function note(tag, what)
		if #notes < 12 then
			table.insert(notes, tag .. ": " .. what)
		end
	end
	local screens = {}
	for _, case in ipairs(everyScreen) do
		table.insert(screens, case)
	end
	for _, tv in ipairs(tvCases) do
		table.insert(screens, { tag = tv.tag .. " TV", input = (tvCase(tv.w, tv.h, tv.inset, tv.keyboard)) })
	end
	for _, case in ipairs(screens) do
		local tag = case.tag
		local plain = HudLayout.solve(case.input)
		if plain.removeRow ~= nil then
			noRowSame = false
			note(tag, "a row with no trap out")
		end
		local withRow = table.clone(case.input)
		withRow.removeRow = true
		local L = HudLayout.solve(withRow)
		local row = L.removeRow
		local H = L.hot
		local rowH = HudLayout.removeRowHeight(L.touch)
		-- The strip itself never moves for the row.
		if L.hotbar.x ~= plain.hotbar.x or L.hotbar.y ~= plain.hotbar.y or L.hotbar.w ~= plain.hotbar.w
			or L.slots ~= plain.slots then
			noRowSame = false
			note(tag, "the strip moved for the row " .. r2s(L.hotbar) .. " vs " .. r2s(plain.hotbar))
		end
		if not row or math.abs(row.x - L.hotbar.x) > 0.01 or math.abs(row.w - L.hotbar.w) > 0.01
			or math.abs(row.y + row.h + GAP - L.hotbar.y) > 0.01 or math.abs(row.h - rowH) > 0.01 then
			rowShape = false
			note(tag, "row " .. (if row then r2s(row) else "nil"))
		end
		if row and math.abs(L.namePopup.y + L.namePopup.h + HOT.NamePopupGap - row.y) > 0.01 then
			bandOver = false
			note(tag, "name band " .. r2s(L.namePopup) .. " not over row " .. r2s(row))
		end
		if #HudLayout.problems(plain) == 0 and #HudLayout.problems(L) > 0 then
			fitsAll = false
			note(tag, table.concat(HudLayout.problems(L), "; "))
		end
		-- With four boost icons standing too: icons over the band, the toast over both.
		local busy = table.clone(withRow)
		busy.icons = 4
		local B = HudLayout.solve(busy)
		local icons = B.icons
		if not icons or icons.y + icons.h > B.namePopup.y - 8 + 0.01 or HudLayout.gap(icons, B.removeRow) < 8 then
			iconsOver = false
			note(tag, "icons " .. (if icons then r2s(icons) else "nil") .. " band " .. r2s(B.namePopup))
		end
		local t = B.toast
		local under = if icons then math.min(icons.y, B.namePopup.y) else B.namePopup.y
		if t.y + t.h > under - 8 + 0.01 or HudLayout.gap(t, B.removeRow) < 8 then
			toastOver = false
			note(tag, "toast " .. r2s(t) .. " over " .. tostring(under))
		end
		-- Every slot's button.
		for i = 1, L.slots do
			local press, plate = HudLayout.removeButton(L, i)
			local slot = HudLayout.slotRect(L, i)
			local okSlot = press ~= nil and plate ~= nil
				and math.abs(plate.x - slot.x) < 0.01 and math.abs(plate.w - slot.w) < 0.01
				and math.abs(plate.y + plate.h + GAP - slot.y) < 0.01 and plate.h == HOT.RemoveHeight
				and press.x <= plate.x + 0.01 and press.x + press.w >= plate.x + plate.w - 0.01
				and press.y <= plate.y + 0.01 and math.abs(press.y + press.h - L.hotbar.y) < 0.01
				and press.x >= L.hotbar.x - 0.01 and press.x + press.w <= L.hotbar.x + L.hotbar.w + 0.01
				and HudLayout.gap(press, L.namePopup) >= HOT.NamePopupGap - 0.01
			for _, zone in ipairs({ L.thumb, L.jump }) do
				okSlot = okSlot and (zone == nil or HudLayout.gap(press :: any, zone) >= 8)
			end
			if not okSlot then
				slotsOk = false
				note(tag, string.format("slot %d press %s plate %s", i, if press then r2s(press) else "nil",
					if plate then r2s(plate) else "nil"))
			end
			if L.touch and press and (press.h < 44 or press.w < 44) then
				touchBig = false
				note(tag, string.format("slot %d target %s", i, r2s(press)))
			end
		end
		-- The words on the plate, and the count under a trap's picture.
		local words = TextService:GetTextSize(HOT.RemoveWords, H.RemoveText, Enum.Font.FredokaOne, Vector2.new(400, 100))
		if words.X > H.SlotWidth - 6 or words.Y > HOT.RemoveHeight then
			wordsFit = false
			note(tag, string.format("REMOVE %dx%d on a %d-wide plate", words.X, words.Y, H.SlotWidth))
		end
		local count = TextService:GetTextSize("3\u{00D7}", H.TrapCountSize, Enum.Font.FredokaOne, Vector2.new(400, 100))
		if count.X > H.SlotWidth / 2 or H.TrapCountSize + 3 + H.TrapCountBottom > H.SlotHeight / 3 then
			countFits = false
			note(tag, string.format("3x %dx%d in a %d slot", count.X, count.Y, H.SlotWidth))
		end
	end
	check(noRowSame, "no trap out, no row: the strip and everything over it are exactly where they were",
		table.concat(notes, " | "))
	check(rowShape, "a trap out: a strip-wide row RemoveGap over the strip, the drawn button's height on a "
		.. "mouse screen and RemoveTouch on a touch screen", table.concat(notes, " | "))
	check(bandOver, "the item name's band stands just over the row", table.concat(notes, " | "))
	check(fitsAll, "every screen that fit without the row fits with it -- nothing within 8 px of anything",
		table.concat(notes, " | "))
	check(iconsOver, "four boost icons stand over the name band, 8 px clear of the row", table.concat(notes, " | "))
	check(toastOver, "and the notices over the icons, clear of the row", table.concat(notes, " | "))
	check(slotsOk, "over EVERY slot: the plate just over that slot, the press on the whole row over it, inside "
		.. "the strip's columns, clear of the name band and 8 px from both thumbs", table.concat(notes, " | "))
	check(touchBig, "on every touch screen the press is at least 44 x 44", table.concat(notes, " | "))
	check(wordsFit, "REMOVE fits its plate in every face", table.concat(notes, " | "))
	check(countFits, "and \"3x\" fits under a trap's picture, bottom centre, in every face", table.concat(notes, " | "))

	-- The owners re-place when the row starts or stops (it is a measured fact).
	local loadout = sourceOf("LoadoutUI") or ""
	local toastSrc = sourceOf("ActionToastUI") or ""
	local iconsSrc2 = sourceOf("BoostIconsUI") or ""
	local cashSrc = sourceOf("CashUI") or ""
	local tutorialSrc = sourceOf("TutorialUI") or ""
	check(loadout:find("GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(layoutHud)", 1, true)
			and toastSrc:find("GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(place)", 1, true)
			and iconsSrc2:find("GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(place)", 1, true)
			and cashSrc:find("GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute)", 1, true)
			and tutorialSrc:find("GetAttributeChangedSignal(Config.Hotbar.RemoveRowAttribute):Connect(placeBanner)", 1, true),
		"LoadoutUI, the notices, the icon row, the cash block and the guide each re-place when the row comes or goes")
	check(loadout:find("hotTop = layout.namePopup.y", 1, true) ~= nil,
		"and the Bag's foot stands over the name band the layout placed -- over the row while it stands")
end


--==============================================================================
-- THE EVENTS BUTTON (2026-10-04, EventsUI)
--
-- Placed where nothing that shipped moves. On a desktop (and a TV) it stands
-- beside Settings, inside the band the 130-wide slabs left, so the rail's
-- footprint -- and everything placed round it -- is what it was. In compact and
-- on a phone it stands under the Bag at the right edge, 8 px under the top
-- row, a group of its own: the compact row and the phone's top row keep their
-- ends, so TELEPORT, the boosts and the notices are centred where they were.
-- (Measured on the way: a fifth compact cell put TELEPORT 38 px off the
-- clock's centre in a 700 x 400 window; beside WALK MODE, the boosts stacked on
-- a 640-px phone; a fourth dock tile has no 44-px room on the 772 x 360,
-- 705 x 338 and 640 x 360 phones.)
--==============================================================================
-- Garden and the Bag never move when a trap comes out (their room is
-- measured with its REMOVE row up), on any listed screen or TV.
do
	local movedFor = {}
	local all = table.clone(everyScreen)
	-- 800 x 440 to 760 x 448: windows on the edge between the pair at the left
	-- and the top-right row, which a REMOVE row's lift would tip over.
	for _, size in ipairs({ { 1024, 600 }, { 640, 400 }, { 560, 320 }, { 1400, 400 }, { 800, 440 }, { 860, 445 },
		{ 760, 448 } }) do
		table.insert(all, { tag = string.format("%dx%d window", size[1], size[2]),
			input = screen(size[1], size[2], { touch = false }) })
	end
	for _, tv in ipairs(tvCases) do
		table.insert(all, { tag = "TV " .. tv.tag, input = (tvCase(tv.w, tv.h, tv.inset, tv.keyboard)) })
	end
	for _, case in ipairs(all) do
		local L = HudLayout.solve(case.input)
		local withRow = table.clone(case.input)
		withRow.removeRow = true
		local R = HudLayout.solve(withRow)
		if r2s(L.garden) ~= r2s(R.garden) or r2s(L.bag) ~= r2s(R.bag) or L.pairRow ~= R.pairRow
			or L.gardenRight ~= R.gardenRight then
			table.insert(movedFor, case.tag .. " " .. r2s(L.garden) .. " -> " .. r2s(R.garden))
		end
	end
	check(#movedFor == 0, "Garden and the Bag stand where they stand with or without a trap's REMOVE row, on "
		.. "every listed screen, small window and TV", table.concat(movedFor, "; "))
end

say("-- the walk mode switch --")
do
	-- 2026-10-04, the horizontal switch: label-wide (WalkCompact) off a desktop.
	-- In compact it stands LEFT OF EVENTS, 8 px off it and 8 px under the row --
	-- in the row it pushed TELEPORT off the clock's centre, under Index a short
	-- window's lifted cash block met it -- a group of its own, clear of all.
	-- SINCE 2026-10-09 (Garden and the Bag at the left edge, EVENTS in the
	-- corner): under EVENTS at the right edge, 8 px under it -- and still left
	-- of EVENTS under the Bag in a window too small for the pair at the left
	-- edge, which keeps the top-right row it had (gardenRight).
	local ok, notes = true, {}
	local kept, moved = 0, 0
	-- (1024 x 600 left the list: the desktop again since 2026-10-09's evening.)
	local windows = { { 860, 700 }, { 700, 400 }, { 1400, 400 }, { 899, 700 }, { 560, 320 }, { 640, 400 },
		{ 600, 348 } }
	for _, size in ipairs(windows) do
		local L = HudLayout.solve(screen(size[1], size[2], { touch = false }))
		local w, e = L.walk, L.events
		local named = false
		for _, g in ipairs(HudLayout.groups(L, true)) do
			if g.name == "walk" and g.rect == w then
				named = true
			end
		end
		local sized = L.compact and w.w == CFG.WalkCompact.X and w.h == CFG.WalkCompact.Y
		local placed
		if L.gardenRight then
			kept += 1
			placed = sized and w.x + w.w + CFG.Gap == e.x and w.y == e.y and w.y == L.railBottom + CFG.Gap
		else
			moved += 1
			placed = sized and w.x + w.w == L.safe.X - CFG.Margin and w.y == e.y + e.h + CFG.Gap
		end
		local clear = #HudLayout.problems(L) == 0
		if not (placed and named and clear) then
			ok = false
			table.insert(notes, string.format("%dx%d %s%s%s", size[1], size[2], r2s(w),
				if named then "" else " (no walk group)",
				if clear then "" else " " .. table.concat(HudLayout.problems(L), "; ")))
		end
	end
	check(ok and kept > 0 and moved > 0, "compact: WALK MODE's switch stands under EVENTS at the right edge (left of "
		.. "it where a small window keeps Garden and the Bag top right), label-wide, a group of its own, and "
		.. "nothing overlaps", table.concat(notes, "; ") .. string.format(" (%d moved, %d kept)", moved, kept))
end

say("-- the events button --")
do
	-- Fresh names: I, W and S are reused for other things further up.
	local I, W, S, G6 = RAIL.Inset, RAIL.WideSize, RAIL.SquareSize, RAIL.Gap
	local row = W.Y + G6
	local deskOk, deskNotes = true, {}
	for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1366, 768), Vector2.new(1600, 900),
		Vector2.new(1920, 1080), Vector2.new(2560, 1440) }) do
		local L = HudLayout.solve(screen(size.X, size.Y))
		local e = L.events
		local beside = e.x == I + S.X + G6 and e.y == I + row * 2 and e.w == S.X and e.h == S.Y
		local inBand = e.x + e.w <= L.railRight and e.y + e.h <= L.railBottom
			and L.railRight == I + W.X and L.railBottom == L.walk.y + L.walk.h
		local apart = true
		for _, other in ipairs({ L.index, L.shop, L.settings, L.walk }) do
			if HudLayout.gap(e, other) < G6 - 1e-6 then
				apart = false
			end
		end
		if not (beside and inBand and apart) then
			deskOk = false
			table.insert(deskNotes, string.format("%dx%d %s", size.X, size.Y, r2s(e)))
		end
	end
	check(deskOk, "desktop: EVENTS is a 50 x 50 square beside Settings, inside the rail's band, the rail's 6 px "
		.. "from Shop, Settings and WALK MODE -- the band (railRight, railBottom) exactly as it shipped",
		table.concat(deskNotes, "; "))

	local offOk, offNotes = true, {}
	local PP = CFG.Phone.Panel
	for _, case in ipairs(everyScreen) do
		local L = HudLayout.solve(case.input)
		if L.compact then
			local e = L.events
			local M8 = CFG.Margin
			-- On a phone the SECOND square of the panel's row (INVITE first since
			-- 2026-10-06; a row since 2026-10-09), which is its group; in a small
			-- window 50 x 50 in the top-right corner (2026-10-09), or under the Bag
			-- where a window keeps Garden and the Bag top right.
			local view = L.dockView
			local placed = if L.sidebar
				then view ~= nil and e.y == view.y + PP.Pad and e.x == view.x + PP.Pad + e.w + PP.Gap and e.w == e.h
					and e.w <= PP.Tile and e.w >= PP.MinTile
				elseif L.gardenRight
				then e.w == S.X and e.h == S.Y and e.x == L.bag.x and e.y == L.bag.y + L.bag.h + CFG.Gap
				else e.w == S.X and e.h == S.Y and e.x == L.safe.X - CFG.Margin - S.X and e.y == CFG.Margin
			-- A square scrolled out of the viewport is clipped by it: only the part that
			-- shows is measured (the viewport itself is the dock's group).
			if L.sidebar and view and e.y + e.h > view.y + view.h then
				e = { x = e.x, y = e.y, w = e.w, h = math.max(0, view.y + view.h - e.y) }
			end
			local own = if L.sidebar then "dock" else "events"
			local inside = e.x >= M8 and e.y >= M8 and e.x + e.w <= L.safe.X - M8 and e.y + e.h <= L.safe.Y - M8
			local clear = true
			for _, g in ipairs(HudLayout.groups(L, true)) do
				if g.name ~= own and HudLayout.gap(e, g.rect) < CFG.Gap - 1e-6 then
					clear = false
					table.insert(offNotes, case.tag .. " near " .. g.name)
				end
			end
			for _, zone in ipairs({ L.thumb, L.jump }) do
				if zone and HudLayout.gap(e, zone) < CFG.Gap - 1e-6 then
					clear = false
					table.insert(offNotes, case.tag .. " near a thumb")
				end
			end
			for _, b in ipairs({ L.teleport, L.obby, L.biomes }) do
				if b.w > 0 and HudLayout.gap(e, b) < CFG.Gap - 1e-6 then
					clear = false
					table.insert(offNotes, case.tag .. " near TELEPORT / OBBY / BIOMES")
				end
			end
			-- Since 2026-10-04 Walk Mode's switch is off the row (left of EVENTS in
			-- compact): the row ends at Settings. A phone's left column (2026-10-05)
			-- ends at the switch rows under Shop, its right one at Index.
			local ends = if L.sidebar
				then L.railRight == L.walk.x + L.walk.w and L.rightLeft == L.index.x
				else L.railRight == L.settings.x + L.settings.w
					and L.rightLeft == (if L.gardenRight then L.garden.x else e.x)
			if not (placed and inside and clear and ends) then
				offOk = false
				table.insert(offNotes, case.tag .. " " .. r2s(e))
			end
		end
	end
	check(offOk, "compact: EVENTS stands 50 x 50 in the top-right corner (under the Bag where a small window keeps "
		.. "Garden and the Bag top right); every phone: the second square of the panel's row -- inside the "
		.. "margin, 8 px clear of every other group, both thumbs, TELEPORT, OBBY and BIOMES, and the rows ending "
		.. "where the layout says", table.concat(offNotes, "; "))

	local tvOk, tvNotes = true, {}
	for _, case in ipairs(tvCases) do
		local input = tvCase(case.w, case.h, case.inset, case.keyboard)
		local L = HudLayout.solve(input)
		local e = L.events
		local ok = if L.compact
			then (if L.gardenRight then e.x == L.bag.x and e.y == L.bag.y + L.bag.h + CFG.Gap
				else e.x + e.w == (L.frame and L.frame.x + L.frame.w or L.safe.X) - CFG.Margin)
			else e.x == L.settings.x + S.X + G6 and e.y == L.settings.y
		if not (ok and e.w == S.X and e.h == S.Y) then
			tvOk = false
			table.insert(tvNotes, case.tag .. " " .. r2s(e) .. " settings " .. r2s(L.settings))
		end
	end
	check(tvOk, "a TV's title-safe canvas carries EVENTS with the rest of the rail", table.concat(tvNotes, "; "))

	local src = sourceOf("EventsUI") or ""
	check(count(src, "UIKit.railButton(") == 2 and src:find('name = "EventsButton"', 1, true) ~= nil
			and src:find("local r = layout.events", 1, true) ~= nil
			and src:find("UIKit.railShape(button, Vector2.new(r.w, r.h))", 1, true) ~= nil
			and src:find("UIKit.placeRail(button, layout, r, playerGui)", 1, true) ~= nil,
		"EventsUI owns its one rail button (art, or the violet slab until there is art), placed from "
			.. "layout.events -- in the rail layer, or on a phone in the canvas of the panel under the Bag")
	check(src:find("local away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil", 1, true) ~= nil
			and src:find("player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(placeButton)", 1, true) ~= nil,
		"off a desktop it steps aside while a centre panel is open, as the dock does")
end

--==============================================================================
-- THE OTHER PLANTS SWITCH (2026-10-05): WALK MODE'S TWIN, A DISPLAY PREFERENCE
--
-- A desktop's rail row under WALK MODE, the rail's 130 x 46 and its 6 px; in
-- compact OthersCompact, as wide as its 12-px label, at the right edge under
-- EVENTS (under WALK MODE in a window too short for that); on a phone a
-- see-through row under Shop, over WALK MODE's (2026-10-05). A trap's REMOVE
-- row never moves it.
--==============================================================================
say("-- the other plants switch --")
do
	local OC = CFG.OthersCompact
	local I, W, G6, M8, G8 = RAIL.Inset, RAIL.WideSize, RAIL.Gap, CFG.Margin, CFG.Gap
	local function labelW(text, size)
		return TextService:GetTextSize(text, size, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	end
	local widest = math.max(labelW("OTHER PLANTS: OFF", 13), labelW("OTHER PLANTS: ON", 13))
	local widestSmall = math.max(labelW("OTHER PLANTS: OFF", 12), labelW("OTHER PLANTS: ON", 12))
	check(widest + 4 <= W.X and widestSmall + 6 <= OC.X and OC.X >= 44 and OC.Y >= 44 and OC.Y == CFG.WalkHeight,
		string.format("its longer words fit one line: %d px at 13 in the rail's %d, %d px at 12 in OthersCompact's %d; "
			.. "46 tall, a full touch target", widest, W.X, widestSmall, OC.X))

	local function same(a, b)
		return math.abs(a.x - b.x) < 1e-6 and math.abs(a.y - b.y) < 1e-6 and a.w == b.w and a.h == b.h
	end
	local function named(L, name, r)
		for _, g in ipairs(HudLayout.groups(L, true)) do
			if g.name == name and same(g.rect, r) then
				return true
			end
		end
		return false
	end

	local deskOk, deskNotes = true, {}
	-- (1000 x 609 goes compact since 2026-10-09; 1024 x 768 keeps the desktop.)
	for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1366, 768), Vector2.new(1600, 900),
		Vector2.new(1920, 1080), Vector2.new(2560, 1440), Vector2.new(1024, 768) }) do
		local L = HudLayout.solve(screen(size.X, size.Y))
		local o, w = L.others, L.walk
		local placed = not L.compact and o.x == I and o.y == w.y + w.h + G6 and o.w == W.X and o.h == CFG.WalkHeight
			and L.railBottom == w.y + w.h
		local inRail = false
		for _, g in ipairs(HudLayout.groups(L, true)) do
			if g.name == "rail" and g.rect.x <= o.x and g.rect.y + g.rect.h >= o.y + o.h then
				inRail = true
			end
		end
		local problems = HudLayout.problems(L)
		if not (placed and inRail and #problems == 0) then
			deskOk = false
			table.insert(deskNotes, string.format("%dx%d %s %s", size.X, size.Y, r2s(o), table.concat(problems, "; ")))
		end
	end
	check(deskOk, "desktop: OTHER PLANTS is the rail's fifth row -- under WALK MODE, the rail's 6 px, 130 x 46 -- "
		.. "inside the rail's group; the band (railBottom) as it shipped", table.concat(deskNotes, "; "))

	-- Off a desktop: every listed phone and window, and the compact windows the
	-- walk check lists, each with and without a trap's REMOVE row.
	local offCases = {}
	for _, case in ipairs(everyScreen) do
		table.insert(offCases, case)
	end
	-- 600 x 348: the window where the band with a trap's REMOVE row up decides --
	-- under EVENTS clears the belt's band without the row, not with it.
	for _, size in ipairs({ { 899, 700 }, { 560, 320 }, { 640, 400 }, { 1400, 400 }, { 600, 348 } }) do
		table.insert(offCases, { tag = string.format("%dx%d window", size[1], size[2]),
			input = screen(size[1], size[2], { touch = false }) })
	end
	local offOk, offNotes, spots = true, {}, { underShop = 0, walkCompact = 0, eventsCompact = 0, underWalk = 0,
		besideWalk = 0 }
	local SW = CFG.Phone.Switch
	for _, case in ipairs(offCases) do
		local L = HudLayout.solve(case.input)
		if L.compact then
			local withRow = table.clone(case.input)
			withRow.removeRow = true
			local R = HudLayout.solve(withRow)
			local o, w, e, sw = L.others, L.walk, L.events, L.safe.X
			local bad = {}
			-- On a phone a see-through row since the owner's layout of 2026-10-05;
			-- in a small window OthersCompact as it was.
			local rowSize = o.h == SW.H and o.w == SW.W
			if not (if L.sidebar then rowSize and L.switchInline else o.w == OC.X and o.h == OC.Y) then
				table.insert(bad, "size")
			end
			if not same(o, R.others) then
				table.insert(bad, "moved for the REMOVE row " .. r2s(R.others))
			end
			if not named(L, "others", o) then
				table.insert(bad, "no group of its own")
			end
			if o.x < M8 or o.y < M8 or o.x + o.w > sw - M8 or o.y + o.h > L.safe.Y - M8 then
				table.insert(bad, "outside the margin")
			end
			for _, g in ipairs(HudLayout.groups(L, true)) do
				if g.name ~= "others" and HudLayout.gap(o, g.rect) < G8 - 1e-6 then
					table.insert(bad, "near " .. g.name)
				end
			end
			if HudLayout.gap(o, L.namePopup) < G8 - 1e-6 and case.tag ~= "560x320 window" then
				table.insert(bad, "near the name band")
			end
			-- And with a trap out: the lifted name band and the REMOVE row, on
			-- every screen but the one too short for any spot (560 x 320).
			if case.tag ~= "560x320 window" and (HudLayout.gap(R.others, R.namePopup) < G8 - 1e-6
				or (R.removeRow and HudLayout.gap(R.others, R.removeRow) < G8 - 1e-6)) then
				table.insert(bad, "near the lifted name band or the REMOVE row")
			end
			if L.sidebar then
				if HudLayout.gap(o, L.jump) < G8 or HudLayout.gap(o, L.thumb) < G8 then
					table.insert(bad, "within 8 px of a touch control")
				end
				if HudLayout.gap(R.others, R.namePopup) < G8 - 1e-6 or (R.removeRow and HudLayout.gap(R.others, R.removeRow) < G8 - 1e-6) then
					table.insert(bad, "near the lifted name band or the REMOVE row")
				end
				if not (o.x >= sw * 2 / 3 or o.x + o.w <= sw / 3) then
					table.insert(bad, "in the middle third")
				end
				-- Under Shop at the margin, WALK MODE under it in one column.
				local shop = L.shop
				if o.x == M8 and o.y == shop.y + shop.h + G8 and w.y == o.y + o.h + SW.Gap and w.x == o.x
					and w.w == o.w then
					spots.underShop += 1
				else
					table.insert(bad, "not under Shop, over WALK MODE")
				end
			elseif L.gardenRight then
				-- A small window that keeps Garden and the Bag top right: as before.
				if o.x + o.w == sw - M8 and o.y == e.y + e.h + G8 then
					spots.eventsCompact += 1
				elseif o.x + o.w == w.x + w.w and o.y == w.y + w.h + G8 then
					spots.walkCompact += 1
				else
					table.insert(bad, "neither under EVENTS nor under WALK MODE")
				end
			else
				-- Since 2026-10-09: at the right edge under WALK MODE (which stands
				-- under EVENTS), else beside WALK MODE in its row.
				if o.x + o.w == sw - M8 and o.y == w.y + w.h + G8 then
					spots.underWalk += 1
				elseif o.x + o.w + G8 == w.x and o.y == w.y then
					spots.besideWalk += 1
				else
					table.insert(bad, "neither under WALK MODE nor beside it")
				end
			end
			if #bad > 0 then
				offOk = false
				table.insert(offNotes, case.tag .. " " .. r2s(o) .. ": " .. table.concat(bad, ", "))
			end
		end
	end
	check(offOk, "off a desktop: a see-through row under Shop on a phone (OthersCompact in a window), a group of "
		.. "its own, 8 px clear of every group, the name band and both thumbs, out of a phone's middle third, never "
		.. "moved by the REMOVE row", table.concat(offNotes, "; "))
	say(string.format("        phones: %d under Shop; windows: %d under WALK MODE, %d beside it; small windows "
		.. "with the pair top right: %d under EVENTS, %d under WALK MODE", spots.underShop, spots.underWalk,
		spots.besideWalk, spots.eventsCompact, spots.walkCompact))
	check(spots.underShop > 0 and spots.underWalk > 0 and spots.eventsCompact > 0,
		"the phone's spot and the windows' are in use on the listed screens")

	local tvOk, tvNotes = true, {}
	for _, case in ipairs(tvCases) do
		local input = tvCase(case.w, case.h, case.inset, case.keyboard)
		local L = HudLayout.solve(input)
		local o, w, f = L.others, L.walk, L.frame
		if not (f and o.x == w.x and o.y == w.y + w.h + G6 and o.x >= f.x and o.y + o.h <= f.y + f.h) then
			tvOk = false
			table.insert(tvNotes, case.tag .. " " .. r2s(o))
		end
	end
	check(tvOk, "a TV's title-safe canvas carries OTHER PLANTS under WALK MODE with the rest of the rail",
		table.concat(tvNotes, "; "))

	local src = sourceOf("OtherPlantsUI") or ""
	local walkSrc = sourceOf("WalkModeUI") or ""
	local look = true
	for _, line in ipairs({ "local LABEL_H = 18", "local TRACK_H = 20", "local THUMB = Vector2.new(26, 24)",
		"local TRACK_WIDE = 64", "local TRACK_NARROW = 58", "local SLIDE_SECONDS = 0.14",
		"local OFF_FACE = { LOOK.DangerTop, LOOK.DangerBottom, LOOK.DangerEdge }",
		"local ON_FACE = { LOOK.ButtonTop, LOOK.ButtonBottom, LOOK.ButtonEdge }",
		"UIKit.pressPop(slab, 1.04, 0.95)", "label.TextSize = if wide then 13 else 12" }) do
		look = look and src:find(line, 1, true) ~= nil and walkSrc:find(line, 1, true) ~= nil
	end
	check(look and src:find("local r = layout.others", 1, true) ~= nil
			and src:find("slab.Visible = not (phone and ObbyData.onCourse(player)) and not away", 1, true) ~= nil
			and not src:find("FireServer", 1, true) and not src:find("GameEvent", 1, true),
		"OtherPlantsUI: Walk Mode's look number for number, placed from layout.others, put away where Walk Mode is, "
			.. "and no remote: the preference is this client's")
	-- (Until 2026-10-05 the x2 button's message hung under the top-right row and
	-- stepped left of this switch; the card rides the cash line now, its message
	-- over the cash block, as everywhere else.)
	local cashSrc = sourceOf("CashUI") or ""
	check(not cashSrc:find("hung = HudLayout.rect(", 1, true) and not cashSrc:find("tip.Parent = gui", 1, true),
		"the x2 card's message no longer hangs under a phone's top row: it stays with the card, over the cash block")
end

--==============================================================================
-- THE OWNER'S MOBILE CORRECTIONS (2026-10-05; art/mockups/mobile-hud-2026-10-05)
--
-- On every touch screen: the top row one even row -- BIOMES | PLOT | OBBY 4 to 6
-- px apart, PLOT the word alone (held above, THE TOP ROW and the button's own
-- checks); the x2 card off the top-right row and beside the cash line, the
-- artwork alone, its press never nearer the thumbstick's zone, the jump button
-- or the belt than 8 px -- whatever the balance -- and the belt moving for it
-- only for a player who has the card, on a screen with no other room. Since
-- the owner's layout of that evening: PLOT on the screen's centre line, Shop in
-- the top-left corner with OTHER PLANTS and WALK MODE as see-through rows under
-- it whose words fit them inline, Index in the x2 card's old place, and EVENTS,
-- WHAT'S NEW and Settings in a panel under the Bag (the phones' checks above,
-- and THE WHAT'S NEW BUTTON below). A desktop and a small window are exactly
-- what they were (section 1 and every desktop check above still hold).
--==============================================================================
say("-- the mobile corrections --")
do
	local P = CFG.Phone
	check(P.RowGap >= 4 and P.RowGap <= 6,
		string.format("the top row's three buttons stand %d px apart: the owner's 4 to 6", P.RowGap))
	-- What is SEEN is that far apart too: the plates' black edge draws outside
	-- them (measured in Play 2026-10-05: full-size plates left 1 px between the
	-- outlines), and each row plate is inset by exactly that edge (RowStroke).
	local kitSrc = Shared:FindFirstChild("UIKit").Source
	check(P.RowStroke == 2.5 and kitSrc:find("local edge = UIKit.stroke(plate, BLACK, 2.5)\n\tedge.ApplyStrokeMode = "
			.. "Enum.ApplyStrokeMode.Border", 1, true) ~= nil,
		"each row plate is inset by UIKit.hudPlate's 2.5-px edge, so the outlines, not just the touch areas, stand "
			.. P.RowGap .. " px apart")

	-- THE x2 CARD BESIDE THE CASH. Placed as CashUI places it: off the cash text
	-- at the face's BuffGap, never left of the layout's buffMinX, bottom-anchored
	-- BuffDrop under the cash block's root; its press BuffHit square round it.
	local face = CFG.CashStyle.Phone
	local function textW(text)
		return TextService:GetTextSize(text, face.CashSize, Enum.Font.LuckiestGuy, Vector2.new(4000, 200)).X
	end
	local short, long = textW("$0"), textW("$9.99Qa")
	local hang = (face.BuffHit - face.BuffSize) / 2
	local function press(L, width)
		local x = math.max(L.buffMinX or face.BuffMinX, math.floor(width) + face.BuffGap)
		local root = L.cashRoot
		local bottom = root.y + root.h + face.BuffDrop
		return rect(root.x + x - hang, bottom - face.BuffSize - hang, face.BuffHit, face.BuffHit)
	end
	local phones = {}
	for _, case in ipairs(cases) do
		table.insert(phones, case)
	end
	for _, c in ipairs({ { 772, 360, 400 }, { 600, 338, 260 }, { 640, 480, 250 }, { 430, 500, 250 } }) do
		table.insert(phones, { tag = string.format("%dx%d phone, Roblox buttons to %d", c[1], c[2], c[3]),
			input = screen(c[1], c[2], { touch = true, barLeft = c[3] }) })
	end
	table.insert(phones, { tag = "768x1024 portrait tablet", input = screen(768, 1024, { touch = true, keyboard = false }) })
	table.insert(phones, { tag = "1366x1024 landscape tablet",
		input = screen(1366, 1024, { touch = true, keyboard = false }) })
	local ok, notes, slid, dropped = true, {}, {}, {}
	for _, case in ipairs(phones) do
		local L = HudLayout.solve(case.input)
		local withCard = table.clone(case.input)
		withCard.buff = true
		local C = HudLayout.solve(withCard)
		local trapped = table.clone(withCard)
		trapped.removeRow = true
		local T = HudLayout.solve(trapped)
		local bad = {}
		-- No x2 row button any more, and the card's leftmost place known. (Without
		-- the card the belt is where it stood: centred, the phones' checks above.)
		if L.boost ~= nil or L.buffMinX == nil then
			table.insert(bad, "no buffMinX, or an x2 row button")
		end
		for _, width in ipairs({ short, long }) do
			for _, X in ipairs({ C, T }) do
				local p = press(X, width)
				local worst = HudLayout.hotbarBand(X.hotbar, HudLayout.removeRowHeight(true) + HOT.RemoveGap)
				if HudLayout.gap(p, X.thumb) < 8 - 1e-6 or HudLayout.gap(p, X.jump) < 8 - 1e-6 then
					table.insert(bad, string.format("its press %s within 8 px of a thumb", r2s(p)))
				end
				if HudLayout.gap(p, worst) < 8 - 1e-6 then
					table.insert(bad, string.format("its press %s within 8 px of the belt's band %s", r2s(p), r2s(worst)))
				end
				if p.x < 0 or p.y < 0 or p.x + p.w > X.safe.X or p.y + p.h > X.safe.Y then
					table.insert(bad, "its press leaves the safe area " .. r2s(p))
				end
				if X.cash.x + X.cash.w < p.x + p.w - 1e-6 then
					table.insert(bad, "the cash block's reservation stops short of the card")
				end
			end
		end
		-- The belt moves for the card only where it must: noted by screen.
		if r2s(C.hotbar) ~= r2s(L.hotbar) then
			if C.chip ~= L.chip then
				table.insert(dropped, case.tag)
			else
				table.insert(slid, string.format("%s (%+.0f px)", case.tag, (C.hotbar.x + C.hotbar.w / 2)
					- (L.hotbar.x + L.hotbar.w / 2)))
			end
		end
		local problems = HudLayout.problems(C)
		if not C.fits or #problems > 0 then
			table.insert(bad, "with the card: " .. table.concat(problems, "; "))
		end
		if #bad > 0 then
			ok = false
			table.insert(notes, case.tag .. ": " .. table.concat(bad, ", "))
		end
	end
	check(ok, "every phone and tablet: the x2 card rides the cash line -- from \"$0\" to \"$9.99Qa\" its 44-px press "
		.. "keeps 8 px off the thumbstick, the jump button and the belt's band (a trap's REMOVE row up too), inside "
		.. "the cash block's reservation -- and with the card nothing overlaps", table.concat(notes, "; "))
	say("        the belt slides over for the card on: " .. (if #slid > 0 then table.concat(slid, ", ") else "none")
		.. "; drops its Bag cell for it on: " .. (if #dropped > 0 then table.concat(dropped, ", ") else "none"))

	-- THE SWITCH ROWS (the owner's layout, 2026-10-05 evening): see-through
	-- rows under Shop. The words inline fit at Label px between PadLeft and the
	-- switch, 4 px before it, the switch PadRight from the row's end; the thumb
	-- a little taller than the track; ON or OFF in the track at Word px.
	local SW = P.Switch
	local function labelW(text, size)
		return TextService:GetTextSize(text, size, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	end
	local oth, walkW = GameConfig.OtherPlants.Label, GameConfig.WalkMode.Label
	local onW = math.max(labelW(GameConfig.WalkMode.OnText, SW.Word), labelW(GameConfig.WalkMode.OffText, SW.Word),
		labelW(GameConfig.OtherPlants.OnText, SW.Word), labelW(GameConfig.OtherPlants.OffText, SW.Word))
	check(SW.PadLeft + labelW(oth, SW.Label) + 4 + SW.Track.X + SW.PadRight <= SW.W
			and SW.PadLeft + labelW(walkW, SW.Label) + 4 + SW.Track.X + SW.PadRight <= SW.W
			and SW.Thumb >= SW.Track.Y and SW.Thumb <= SW.H and onW <= SW.Track.X - SW.Thumb - 2
			and SW.Label >= 10 and SW.Word >= 8 and SW.Gap >= CFG.Gap,
		string.format("the see-through rows hold their words inline: OTHER PLANTS %d px and WALK MODE %d at %d, "
			.. "beside a %d x %d switch whose ON / OFF (%d px at %d) fits beside its thumb, in %d x %d rows a group's "
			.. "8 px apart", labelW(oth, SW.Label), labelW(walkW, SW.Label), SW.Label, SW.Track.X, SW.Track.Y, onW,
			SW.Word, SW.W, SW.H))
	local walkSrc, othersSrc = sourceOf("WalkModeUI") or "", sourceOf("OtherPlantsUI") or ""
	local rowLines = true
	for _, line in ipairs({ "local ROW = HudLayout.Config.Phone.Switch", "local inline = layout.switchInline == true",
		"stateWord.Visible = inline", "label.TextSize = ROW.Label",
		"track.Size = UDim2.fromOffset(ROW.Track.X, ROW.Track.Y)", "thumb.Size = UDim2.fromOffset(ROW.Thumb, ROW.Thumb)",
		"local stateWord = UIKit.outlined(track, \"State\", ROW.Word, WHITE, 1)" }) do
		rowLines = rowLines and walkSrc:find(line, 1, true) ~= nil and othersSrc:find(line, 1, true) ~= nil
	end
	check(rowLines and walkSrc:find("label.Text = WALK.Label\n", 1, true) ~= nil
			and othersSrc:find("label.Text = OTHERS.Label\n", 1, true) ~= nil
			and not walkSrc:find("RowPlate", 1, true) and not othersSrc:find("RowPlate", 1, true),
		"both switches draw the see-through row alike on a phone: no plate behind it, the words inline, the small "
			.. "switch with ON or OFF in it")
	local teleSrc, returnSrc = sourceOf("PlotTeleportUI") or "", sourceOf("ObbyUI") or ""
	check(teleSrc:find('label.Text = if short then "PLOT" else "TELEPORT TO PLOT"', 1, true) ~= nil
			and teleSrc:find("icon.Visible = not short", 1, true) ~= nil
			and teleSrc:find("remote:FireServer(PLOT.TeleportAction)", 1, true) ~= nil
			and returnSrc:find("icon.Visible = layout.returnWide", 1, true) ~= nil,
		"on a touch screen the button says PLOT with no icon and sends the same teleport; RETURN TO PLOT keeps its "
			.. "words on the course, over BIOMES' and PLOT's span")
end

--==============================================================================
-- THE WHAT'S NEW BUTTON (2026-10-05, UpdateLogUI)
--
-- The update log's square, placed where nothing that shipped moves: every
-- check above holds to the pixel with it standing. On a desktop and a TV under
-- the Bag at the right edge, 8 px under it, where no desktop panel reaches; in
-- compact under OTHER PLANTS or under EVENTS at the right edge, else under
-- Index -- a group of its own in both, 50 x 50, or the touch floor's 44 where
-- only that fits; on a phone the middle square of the panel under the Bag (the
-- owner's layout of 2026-10-05 evening), part of that panel's group; 8 px
-- clear of every other group and badge, both thumbs, TELEPORT, OBBY and
-- BIOMES, ADMIN, the tutorial banner and its skip line, the toast and the icon
-- row; out of a phone's middle third; and never moved by a trap's REMOVE row,
-- nor passed over by the lifted name band. Where no spot clears all of that
-- the rect is empty and the button stays hidden, as OBBY does -- on the screens
-- HIDDEN names and no others: none since the top-right row took it.
--==============================================================================
say("-- the what's new button --")
do
	local U, M8, G8 = CFG.Updates, CFG.Margin, CFG.Gap
	local function same(a, b)
		return math.abs(a.x - b.x) < 1e-6 and math.abs(a.y - b.y) < 1e-6 and a.w == b.w and a.h == b.h
	end
	local function holds(outer, inner)
		return inner.x >= outer.x - 1e-6 and inner.y >= outer.y - 1e-6 and inner.x + inner.w <= outer.x + outer.w + 1e-6
			and inner.y + inner.h <= outer.y + outer.h + 1e-6
	end
	local HIDDEN: { [string]: boolean } = {}
	local all = {}
	for _, case in ipairs(everyScreen) do
		table.insert(all, case)
	end
	table.insert(all, { tag = "1024x600 desktop", input = screen(1024, 600) })
	table.insert(all, { tag = "1920x1080 console", input = screen(1920, 1080, { keyboard = false }) })
	for _, size in ipairs({ { 1400, 400 }, { 899, 700 }, { 560, 320 }, { 640, 400 }, { 600, 348 }, { 640, 480 },
		{ 430, 500 } }) do
		table.insert(all, { tag = string.format("%dx%d window", size[1], size[2]),
			input = screen(size[1], size[2], { touch = false }) })
	end
	table.insert(all, { tag = "640x480 window, Roblox buttons to 250",
		input = screen(640, 480, { touch = false, barLeft = 250 }) })
	for _, c in ipairs({ { 772, 360, 400 }, { 600, 338, 260 }, { 640, 480, 250 }, { 430, 500, 250 } }) do
		table.insert(all, { tag = string.format("%dx%d phone, Roblox buttons to %d", c[1], c[2], c[3]),
			input = screen(c[1], c[2], { touch = true, barLeft = c[3] }) })
	end
	table.insert(all, { tag = "768x1024 portrait tablet", input = screen(768, 1024, { touch = true, keyboard = false }) })
	table.insert(all, { tag = "1366x1024 landscape tablet",
		input = screen(1366, 1024, { touch = true, keyboard = false }) })
	for _, tv in ipairs(tvCases) do
		table.insert(all, { tag = tv.tag .. " TV", input = (tvCase(tv.w, tv.h, tv.inset, tv.keyboard)) })
	end

	local ok, notes = true, {}
	local spots = { corner = 0, others = 0, events = 0, walk = 0, index = 0, panel = 0 }
	local shown, small, hiddenOn = 0, 0, {}
	for _, case in ipairs(all) do
		local L = HudLayout.solve(case.input)
		local u = L.updates
		local bad = {}
		-- On a phone the square may stand below the panel's viewport, where its
		-- canvas scrolls (2026-10-06): the viewport clips it, so its clearances are
		-- measured on the part that shows.
		local seen = u
		local view = L.dockView
		if L.sidebar and view and u.w > 0 and u.y + u.h > view.y + view.h then
			seen = rect(u.x, math.min(u.y, view.y + view.h), u.w, math.max(0, view.y + view.h - u.y))
		end
		-- Its group: on a phone the panel's under the Bag; anywhere else its own.
		local inPanel = L.sidebar and u.w > 0
		local home = if inPanel then "dock" else "updates"
		local listed = false
		for _, g in ipairs(HudLayout.groups(L, true)) do
			if g.name == home then
				listed = if inPanel then holds(g.rect, seen) else same(g.rect, u)
			end
		end
		if u.w <= 0 or u.h <= 0 then
			table.insert(hiddenOn, case.tag)
			if not HIDDEN[case.tag] then
				table.insert(bad, "hidden where HIDDEN does not say it has no room")
			end
			if listed then
				table.insert(bad, "an empty rect listed as a group")
			end
		else
			shown += 1
			if HIDDEN[case.tag] then
				table.insert(bad, "stands where HIDDEN says it has no room")
			end
			local full = u.w == U.Size and u.h == U.Size
			local tight = u.w == U.Tight and u.h == U.Tight
			-- On a phone the panel's square, the size EVENTS and Settings are.
			local square = inPanel and u.w == u.h and u.w == L.events.w and u.w == L.settings.w
			if not (full or tight or square) or U.Tight < 44 or U.Size ~= RAIL.SquareSize.X then
				table.insert(bad, string.format("size %gx%g", u.w, u.h))
			end
			if tight then
				small += 1
			end
			if not listed then
				table.insert(bad, "not in its group (" .. home .. ")")
			end
			local box = L.frame or rect(0, 0, L.safe.X, L.safe.Y)
			if seen.x < box.x + M8 or seen.y < box.y + M8 or seen.x + seen.w > box.x + box.w - M8
				or seen.y + seen.h > box.y + box.h - M8 then
				table.insert(bad, "outside the margin")
			end
			for _, g in ipairs(HudLayout.groups(L, true)) do
				if g.name ~= home and HudLayout.gap(seen, g.rect) < G8 - 1e-6 then
					table.insert(bad, "near " .. g.name)
				end
			end
			local indexBadge, gardenBadge = HudLayout.badges(L)
			if HudLayout.gap(seen, indexBadge) < G8 - 1e-6 or HudLayout.gap(seen, gardenBadge) < G8 - 1e-6 then
				table.insert(bad, "near a badge")
			end
			for _, zone in ipairs({ L.thumb, L.jump }) do
				if zone and HudLayout.gap(seen, zone) < G8 - 1e-6 then
					table.insert(bad, "near a thumb")
				end
			end
			for _, b in ipairs({ L.teleport, L.obby, L.biomes, L.banner, L.skip, L.toast }) do
				if b.w > 0 and HudLayout.gap(seen, b) < G8 - 1e-6 then
					table.insert(bad, "near TELEPORT, OBBY, BIOMES, the banner, SKIP or the toast " .. r2s(b))
				end
			end
			-- ADMIN, in window space like the clock (a TV's is the canvas's own).
			local admin = L.admin
			if admin and not L.frame then
				local viewport = case.input.viewport
				local originX = if viewport then (viewport.X - L.safe.X) / 2 else 0
				local a = rect(admin.x - originX, admin.y - (case.input.insetTop or 0), admin.w, admin.h)
				if HudLayout.gap(u, a) < G8 - 1e-6 then
					table.insert(bad, "near ADMIN")
				end
			end
			if L.sidebar and HudLayout.gap(u, rect(L.safe.X / 3, 0, L.safe.X / 3, L.safe.Y)) < G8 - 1e-6 then
				table.insert(bad, "in or by the middle third")
			end
			-- A trap out: the same spot, clear of the lifted name band and the row.
			local withRow = table.clone(case.input)
			withRow.removeRow = true
			local R = HudLayout.solve(withRow)
			if not same(u, R.updates) then
				table.insert(bad, "moved for the REMOVE row " .. r2s(R.updates))
			end
			if HudLayout.gap(R.updates, R.namePopup) < G8 - 1e-6
				or (R.removeRow and HudLayout.gap(R.updates, R.removeRow) < G8 - 1e-6) then
				table.insert(bad, "near the lifted name band or the REMOVE row")
			end
			-- Four boosts running: the same spot, clear of the icon row and the toast over it.
			local busy = table.clone(case.input)
			busy.icons = 4
			local B = HudLayout.solve(busy)
			if not same(u, B.updates) or (B.icons and HudLayout.gap(B.updates, B.icons) < G8 - 1e-6)
				or HudLayout.gap(B.updates, B.toast) < G8 - 1e-6 then
				table.insert(bad, "moved for, or near, the icon row and the toast over it")
			end
			-- Its place, by name.
			local where: string? = nil
			if not L.compact then
				-- The top-right corner, where Garden stood (2026-10-09; under the Bag
				-- before that).
				local box = L.frame or rect(0, 0, L.safe.X, L.safe.Y)
				if full and u.x + u.w == box.x + box.w - RAIL.Inset and u.y == box.y + RAIL.Inset then
					where = "corner"
				end
			elseif L.sidebar then
				-- Between EVENTS and Settings in the panel's row (2026-10-09).
				if square and u.y == L.events.y and u.x == L.events.x + L.events.w + CFG.Phone.Panel.Gap
					and L.settings.x == u.x + u.w + CFG.Phone.Panel.Gap
					and u.x + u.w <= L.dockView.x + L.dockCanvas then
					where = "panel"
				end
			else
				if u.x + u.w == L.others.x + L.others.w and u.y == L.others.y + L.others.h + G8 then
					where = "others"
				elseif L.gardenRight and u.x + u.w == L.events.x + L.events.w and u.y == L.events.y + L.events.h + G8 then
					where = "events"
				elseif not L.gardenRight and u.x + u.w == L.walk.x + L.walk.w and u.y == L.walk.y + L.walk.h + G8 then
					-- Under WALK MODE, the right edge's second row since 2026-10-09.
					where = "walk"
				elseif u.x == L.index.x and u.y == L.index.y + L.index.h + G8 then
					where = "index"
				end
			end
			if where then
				spots[where] += 1
			else
				table.insert(bad, "not in one of its places")
			end
			-- The rows keep their ends: everything placed round them is where it was.
			-- (The right ends since 2026-10-09: EVENTS in compact, Garden where a small
			-- window keeps the pair top right, WHAT'S NEW's corner on a desktop.)
			local ends = if L.sidebar
				then L.railRight == L.walk.x + L.walk.w and L.rightLeft == L.index.x
				elseif L.compact then L.railRight == L.settings.x + L.settings.w
					and L.rightLeft == (if L.gardenRight then L.garden.x else L.events.x)
				else L.railRight == (L.frame and L.frame.x or 0) + RAIL.Inset + RAIL.WideSize.X
					and L.rightLeft == L.updates.x and L.railBottom == L.walk.y + L.walk.h
			if not ends then
				table.insert(bad, "the rows' ends moved")
			end
		end
		if #bad > 0 then
			ok = false
			table.insert(notes, case.tag .. " " .. r2s(u) .. ": " .. table.concat(bad, ", "))
		end
	end
	check(ok, "WHAT'S NEW: 50 x 50 or 44 x 44 in one of its places -- the desktop's top-right corner; under OTHER "
		.. "PLANTS, under WALK MODE (EVENTS where a small window keeps Garden and the Bag top right) or under Index "
		.. "(a group of its own); on a phone between EVENTS and Settings in the panel's row (that panel's "
		.. "group) -- inside the margin, 8 px clear of every other group and badge, both thumbs, "
		.. "TELEPORT, OBBY, "
		.. "BIOMES, ADMIN, the banner, SKIP, the toast and the icon row, out of a phone's middle third, never moved "
		.. "by the REMOVE row or the icons; the rows' ends as they were; hidden on HIDDEN's screens and nowhere else",
		table.concat(notes, "; "))
	say(string.format("        stands on %d of %d screens: %d in the corner, %d under OTHER PLANTS, %d under WALK MODE, "
		.. "%d under EVENTS, %d under Index, %d in a phone's panel under Index (%d at 44 x 44); hidden on: %s",
		shown, #all, spots.corner, spots.others, spots.walk, spots.events, spots.index, spots.panel, small,
		if #hiddenOn > 0 then table.concat(hiddenOn, ", ") else "none"))
	-- "Under Index" is compact's last refuge: the 1024 x 600 class reached it,
	-- and keeps the desktop since 2026-10-09's evening -- so no listed screen does.
	check(spots.corner > 0 and spots.others > 0 and spots.panel > 0,
		"every one of its places that the listed screens reach is in use (under Index: none since the 1024 x 600 "
			.. "class keeps the desktop)")

	local src = sourceOf("UpdateLogUI") or ""
	local hooks = count(src, "RenderStepped") + count(src, "Heartbeat") + count(src, "BindToRenderStep")
		+ count(src, "RunService.Stepped")
	check(count(src, "UIKit.railButton(") == 1 and src:find('name = "UpdatesButton"', 1, true) ~= nil
			and src:find("local layout = HudLayout.solve(HudLayout.measure(gui))", 1, true) ~= nil
			and src:find("local r = layout.updates", 1, true) ~= nil
			and src:find("UIKit.railShape(button, Vector2.new(r.w, r.h))", 1, true) ~= nil
			and src:find("UIKit.placeRail(button, layout, r, playerGui)", 1, true) ~= nil
			and src:find('gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)', 1, true) ~= nil,
		"UpdateLogUI owns its one rail button, placed from layout.updates -- in the rail layer, or on a phone in the "
			.. "canvas of the panel under the Bag -- and asks again when its ScreenGui's size changes")
	check(src:find("local away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil", 1, true) ~= nil
			and src:find("player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(placeButton)", 1, true) ~= nil
			and src:find("if r.w <= 0 or r.h <= 0 or away then", 1, true) ~= nil,
		"off a desktop it steps aside while a centre panel is open, and an empty rect hides it")
	check(hooks == 0 and count(src, 'Instance.new("ScreenGui")') == 1
			and not src:find('Instance.new("RemoteEvent")', 1, true) and not src:find("FireServer", 1, true)
			and not src:find("InvokeServer", 1, true),
		"one ScreenGui, no per-frame hook, no remote: the log is this client's", hooks)
	check(not (sourceOf("RailDrawerUI") or ""):find("Updates", 1, true),
		"RailDrawerUI is untouched: the dock is still Index, Shop and Settings")
end

end)

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, 0 failed"):format(pass)
