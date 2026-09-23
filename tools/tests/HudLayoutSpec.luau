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
	check(L.hot == HOT and L.cashStyle == CFG.CashStyle.Desktop
			and L.hotbar.w == 764 and L.hotbar.h == 104
			and L.cashRoot.w == 316 and L.cashRoot.h == 108 and L.cash.h == 110,
		tag .. ": the shipped faces -- GameConfig.Hotbar itself, the 764 x 104 strip, the 316 x 108 cash block",
		r2s(L.hotbar) .. " " .. r2s(L.cashRoot))
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
check(not console.compact and console.slots == 5 and console.hot == HOT
		and console.cashStyle == CFG.CashStyle.Desktop,
	"no keyboard and no touch keeps the desktop arrangement, its faces and five slots, as before")

--==============================================================================
-- THE DESKTOP FACES ARE THE NUMBERS THAT SHIPPED
--
-- The card's and the cash block's sizes were literals inside LoadoutUI and
-- CashUI until 2026-09-22, when the compact faces needed them named. Every one
-- is pinned here to the value it had as a literal, so the desktop strip and
-- the desktop cash block are drawn exactly as they were.
--==============================================================================
local SHIPPED_HOT = {
	SlotWidth = 64, SlotHeight = 92, Gap = 5, TrayPad = 6, TrayBorder = 3, BottomGap = 10,
	ChipWidth = 52, BagGap = 5, BadgeSize = 16, PreviewTop = 18, PreviewHeight = 48,
	PreviewInset = 3, NameTop = 64, NameHeight = 21, NameMax = 12, NameMin = 7, ChipHeight = 13,
	ChipMaxWidth = 42, ChipTextMax = 9, ChipTextMin = 6, InHandHeight = 10, HeldLift = 4,
	LitThickness = 3.5, CardCorner = 12, CardStroke = 2.5, AuraPad = 8, AuraCorner = 16,
	BadgeInset = 3, BadgeText = 11, ChipTop = 4, NameLines = 2, HintWidth = 52, HintHeight = 13,
	GhostPlus = 22, BagIcon = 34, BagIconTop = 9, BagWord = true, BagPillTop = 66,
	TrayCorner = 18, TrayRim = 6,
}
local hotDiff = {}
for key, want in pairs(SHIPPED_HOT) do
	if HOT[key] ~= want then
		table.insert(hotDiff, key .. " = " .. tostring(HOT[key]))
	end
end
check(#hotDiff == 0 and HudLayout.hotMetrics(false) == HOT
		and HudLayout.hotbarWidth(10, true) == 764 and HudLayout.hotbarHeight() == 104,
	"the desktop card's numbers are the ones that shipped, read from GameConfig.Hotbar itself",
	table.concat(hotDiff, ", "))

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

	-- the rail: on a touch screen, the dock's column and Walk Mode beside it
	check(L.sidebar and L.dock ~= nil and L.handle ~= nil and L.handleShut ~= nil
			and L.boost ~= nil and L.chooser ~= nil,
		tag .. ": a touch screen gets the sidebars -- the dock, its handle, the x2 button and the chooser")
	local D = CFG.Dock
	local dock = L.dock
	local tiles = { L.index, L.shop, L.settings }
	local column = dock ~= nil
	for i, c in ipairs(tiles) do
		column = column and c.w == tiles[1].w and c.h == tiles[1].h and c.w >= 44 and c.h >= 44
			and c.x == dock.x + D.Pad and c.x + c.w == dock.x + dock.w - D.Pad
		if i > 1 then
			column = column and c.y - (tiles[i - 1].y + tiles[i - 1].h) == D.Gap
		end
	end
	column = column and L.index.y == dock.y + D.Pad
		and L.settings.y + L.settings.h == dock.y + dock.h - D.Pad
		and dock.x == CFG.Margin and dock.y == CFG.Margin
	check(column, tag .. ": Index, Shop and Settings stand in one column in the dock, same size, 44+",
		dock and r2s(dock))
	check(dock ~= nil and dock.y + dock.h + 8 <= L.thumb.y,
		tag .. ": the dock ends 8 px above the thumbstick", dock and (L.thumb.y - dock.y - dock.h))
	check(L.walk.w >= 44 and L.walk.h >= 44 and L.walk.y == CFG.Margin
			and L.walk.x >= dock.x + dock.w + 8,
		tag .. ": WALK MODE stands on the top row beside the dock, where the dock shutting never moves it",
		r2s(L.walk))
	check(L.garden.w >= 44 and L.bag.w >= 44 and L.garden.y == L.bag.y
			and L.bag.x + L.bag.w == sw - CFG.Margin,
		tag .. ": Garden and the Bag in one row, the Bag in the corner")
	local boost = L.boost
	check(boost ~= nil and boost.y == L.garden.y and boost.w == L.garden.w and boost.h == L.garden.h
			and boost.x + boost.w + CFG.BoostGap == L.garden.x,
		tag .. ": the x2 button stands immediately left of Garden, the same size, on the same row",
		boost and r2s(boost))
	local indexBadge, gardenBadge = HudLayout.badges(L)
	check(indexBadge.y >= 0 and gardenBadge.y >= 0 and indexBadge.y + indexBadge.h < L.shop.y
			and HudLayout.gap(indexBadge, L.walk) >= 8 and HudLayout.gap(gardenBadge, boost) > 0,
		tag .. ": both badges on the glass, Index's clear of Shop and WALK MODE, Garden's clear of x2",
		r2s(indexBadge) .. " " .. r2s(gardenBadge))

	-- the handle: a 44 x 44 press on the dock's edge, level with Shop; shut, on
	-- the safe area's edge at the same height
	local handle, shut = L.handle, L.handleShut
	local shopMid = L.shop.y + L.shop.h / 2
	check(handle.w >= 44 and handle.h >= 44 and handle.x == dock.x + dock.w
			and math.abs(handle.y + handle.h / 2 - shopMid) <= 1
			and shut.x == 0 and shut.y == handle.y and shut.w == handle.w,
		tag .. ": the dock's handle is a 44 x 44 press on its edge, level with Shop, and on the safe edge when shut",
		r2s(handle) .. " / " .. r2s(shut))

	-- the hotbar
	local thumb, jump = L.thumb, L.jump
	check(thumb ~= nil and jump ~= nil, tag .. ": the thumbstick and jump button are reserved")
	check(L.hot == COMPACT_HOT and L.hotbar.w == HudLayout.hotbarWidth(5, L.chip, true)
			and L.hotbar.h == HudLayout.hotbarHeight(true)
			and L.hot.SlotWidth >= 44 and L.hot.SlotHeight >= 44
			and L.hotbar.y + L.hotbar.h == sh - HOT.BottomGap,
		tag .. ": the strip is the compact belt, five 54 x 76 slots on the bottom edge", r2s(L.hotbar))
	check(math.abs((L.hotbar.x + L.hotbar.w / 2) - sw / 2) <= 8,
		tag .. ": and within 8 px of the middle",
		(L.hotbar.x + L.hotbar.w / 2) - sw / 2)
	check(HudLayout.gap(L.hotbar, thumb) >= 8 and HudLayout.gap(L.hotbar, jump) >= 8,
		tag .. ": clear of both thumbs",
		string.format("%.1f / %.1f", HudLayout.gap(L.hotbar, thumb), HudLayout.gap(L.hotbar, jump)))

	-- cash
	local face = L.cashStyle
	check(face == CFG.CashStyle.Compact and L.cash.w >= face.Reserve
			and L.cash.h == face.Root.Y + face.Drop
			and L.cashRoot.w == face.Root.X and L.cashRoot.h == face.Root.Y
			and L.cash.y + L.cash.h + 8 <= thumb.y,
		tag .. ": the cash block wears its compact face and stands above the thumbstick", r2s(L.cash))
	-- The cash line's outline draws left of the root: measured live, the "$"
	-- reached x = 5 when the root sat on the plain 8 px margin. 3 px is the
	-- desktop's outline, the thicker of the two.
	check(L.cash.x - 3 >= CFG.Margin,
		tag .. ": and the first character's outline is still 8 px inside the safe edge", L.cash.x - 3)
	-- Under the dock where the screen is tall enough, beside it where not.
	local under = L.cash.x == CFG.CashLeft and L.cash.y >= dock.y + dock.h + 8
	local beside = L.cash.x >= dock.x + dock.w + 8
	check(under or beside,
		tag .. ": cash and speed stand under the dock, or beside it where the column is too short",
		r2s(L.cash))
	-- The x2 card is the button on the top row now; its message hangs under it,
	-- right-aligned to it, on the glass and off the right sidebar.
	local tipW = TextService:GetTextSize(GameConfig.Pass.BuffMessage, face.TipSize,
		Enum.Font.GothamMedium, Vector2.new(1000, 100)).X + 4
	local tip = rect(boost.x + boost.w - tipW, boost.y + boost.h + 6, tipW, face.TipSize + 3)
	check(tip.x >= 0 and tip.y + tip.h <= sh and HudLayout.gap(tip, L.equipment) >= 0,
		tag .. ": the x2 card's message, under its button, stays inside the safe area and off BATS/TRAPS",
		r2s(tip))

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

	-- BATS/TRAPS: the right sidebar
	local S = CFG.Side
	local tileW = L.equipment.w - L.equipPad * 2
	check(L.equipment.x + L.equipment.w == sw - CFG.Margin
			and L.equipment.y + L.equipment.h + 8 <= jump.y
			and L.equipment.y >= L.railBottom + 8 and L.equipSlot >= S.MinTile
			and tileW >= 44 and L.equipPad == S.Pad
			and L.equipment.h == L.equipSlot * 2 + L.equipGap + L.equipPad * 2,
		tag .. ": BATS over TRAPS in the right sidebar, against the edge, above the jump button, 44+",
		r2s(L.equipment) .. " tile " .. tileW .. "x" .. L.equipSlot)

	-- the chooser, at its widest: out of the sidebar's left side toward the
	-- middle and no further, one card at the least, a title and a row tall
	local C = CFG.Chooser
	local chooser = L.chooser
	check(chooser.x + chooser.w + 8 == L.equipment.x and chooser.x >= sw / 2 + 8
			and chooser.w >= C.Pad + C.Card.X + C.Spine
			and chooser.h == C.Pad * 2 + C.Title + C.Card.Y,
		tag .. ": the chooser opens leftward from the sidebar, never past the middle, at least one card wide",
		r2s(chooser))
	local clearOfChooser = HudLayout.gap(chooser, L.hotbar) >= 8 and HudLayout.gap(chooser, jump) >= 8
		and HudLayout.gap(chooser, thumb) >= 8 and HudLayout.gap(chooser, L.cash) >= 8
		and chooser.y >= L.railBottom + 8
	for _, group in ipairs(HudLayout.groups(L, true)) do
		clearOfChooser = clearOfChooser and HudLayout.gap(chooser, group.rect) >= 8
	end
	check(clearOfChooser,
		tag .. ": open, it covers none of the belt, cash, the top rows, the thumbs or the sidebars", r2s(chooser))

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
			-- The thumbs are one control each side, and the handle is on the
			-- dock's edge by design; neither pair is a gap.
			local names = groups[i].name .. "/" .. groups[j].name
			if names ~= "thumb/jump" and names ~= "dock/handle" then
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
check(C.SlotWidth >= 52 and C.SlotWidth <= 56 and C.SlotHeight >= 72 and C.SlotHeight <= 78
		and tray >= 82 and tray <= 88 and C.Gap >= 3 and C.Gap <= 4
		and C.BadgeSize >= 13 and C.BadgeSize <= 15 and C.PreviewHeight >= 40 and C.PreviewHeight <= 44
		and C.ChipTextMax >= 9 and C.ChipTextMax <= 10 and C.ChipWidth >= 48 and C.ChipWidth <= 52,
	"the compact belt is in the brief's bands: 52-56 x 72-78 cards, an 82-88 tray, 3-4 gaps, a 13-15 badge, a 40-44 preview, 9-10 px chip words, a 48-52 Bag cell",
	string.format("%dx%d tray %d gap %d badge %d preview %d chip %d bag %d", C.SlotWidth, C.SlotHeight,
		tray, C.Gap, C.BadgeSize, C.PreviewHeight, C.ChipTextMax, C.ChipWidth))
check(C.NameLines == 1 and C.InHandHeight == 0 and C.BagWord == false,
	"one-line names, no IN HAND strip, and a Bag cell without its word")
check(C.SlotWidth >= 44 and C.SlotHeight >= 44 and C.ChipWidth >= 44 and C.SlotHeight >= 44
		and CFG.CashStyle.Compact.BuffHit >= 44,
	"every compact press is at least 44 x 44: a card, the Bag cell, and the x2 card's touch area")
check(C.PreviewTop + C.PreviewHeight <= C.NameTop and C.NameTop + C.NameHeight <= C.SlotHeight - 2
		and C.BadgeInset + C.BadgeSize <= C.SlotWidth - 3 - C.ChipMaxWidth
		and C.BagIconTop + C.BagIcon <= C.BagPillTop and C.BagPillTop + 18 <= C.SlotHeight - 3,
	"inside a compact card nothing meets: preview over name, badge beside chip, icon over count")

-- Every word the chip can carry, at the smallest size refreshHotbar will use.
local chipWords = { HOT.Tags.bat.text, HOT.Tags.trap.text, HOT.Tags.pod.text }
for i = 1, SeedData.TierCount do
	table.insert(chipWords, string.upper(SeedData.TierName(i)))
end
local chipRoom = C.ChipMaxWidth - 6
local chipCut = {}
for _, word in ipairs(chipWords) do
	local width = TextService:GetTextSize(word, C.ChipTextMin, Enum.Font.FredokaOne, Vector2.new(400, 40)).X
	if width > chipRoom then
		table.insert(chipCut, string.format("%s %.0f", word, width))
	end
end
check(#chipCut == 0, string.format("all %d chip words fit the compact chip without an ellipsis", #chipWords),
	table.concat(chipCut, ", "))

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
-- A top band too narrow for the widest name: a small desktop window's compact
-- rows, and a phone just too narrow for it -- sized off the measured name, so
-- centring it is impossible and sliding it between the rows is not. (A 560 x
-- 320 PHONE is no longer such a case: its top-left row is only Walk Mode now,
-- and the name stays centred.)
local squeezed = math.floor(widest + 336)
for _, input in ipairs({ screen(560, 320, { touch = false }), screen(squeezed, 400, { touch = true }) }) do
	local tiny = HudLayout.solve(input)
	local dx, top = HudLayout.notice(tiny, widest, 30, 50 - TOPBAR)
	local box = rect(tiny.safe.X / 2 + dx - widest / 2, top, widest, 30)
	local apart = true
	for _, group in ipairs(HudLayout.groups(tiny, true)) do
		apart = apart and HudLayout.gap(box, group.rect) >= 8
	end
	check((dx ~= 0 or top ~= 50 - TOPBAR) and apart,
		string.format("%dx%d%s: where it cannot stay centred between the rows it moves rather than overlap them",
			input.viewport.X, input.viewport.Y, if input.touch then " phone" else " window"),
		string.format("dx %.1f top %.1f", dx, top))
end

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
-- 5b. THE BAG PANEL
--
-- Found by the owner 2026-09-18 on an emulated iPhone 11: equipment cards cut
-- off under the Bag's header. Measured on the owner's 801 x 392 phone, the grid
-- was 128 px tall and a card row 158 + 16, so no card could ever show whole.
-- HudLayout.bag is the arithmetic LoadoutUI applies; this drives it at every
-- screen the owner listed and pins the desktop to what shipped.
--==============================================================================
say("-- the bag --")
local BAGC = CFG.Bag
local OUTLINE = RAIL.OutlineThickness

-- The shipped layoutBag's panel arithmetic, verbatim, as the desktop oracle.
local function shippedBag(safe, hotTop, sideWidth)
	local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
	local leftEdge = RAIL.Inset + RAIL.WideSize.X + 8
	local rightEdge = safe.X - RAIL.Inset - sideWidth - 8
	local top, bottom = 8, hotTop - 8
	if rightEdge - leftEdge < 420 then
		leftEdge = 8
		top = railBottom + 8
	end
	local height = math.max(160, math.min(600, bottom - top))
	local half = safe.X * 0.5
	local symmetric = 2 * math.min(half - leftEdge, rightEdge - half)
	local width, centreX
	if symmetric >= 600 or symmetric >= rightEdge - leftEdge - 40 then
		width = math.max(240, math.min(780, symmetric))
		centreX = half
	else
		width = math.max(240, math.min(780, rightEdge - leftEdge))
		centreX = (leftEdge + rightEdge) * 0.5
	end
	return math.floor(centreX), math.floor(top + (bottom - top) * 0.5),
		math.floor(width), math.floor(height)
end

for _, size in ipairs({ Vector2.new(1169, 609), Vector2.new(1280, 720), Vector2.new(1366, 768),
	Vector2.new(1920, 1080), Vector2.new(1000, 609) }) do
	local L = HudLayout.solve(screen(size.X, size.Y))
	local tag = string.format("%dx%d desktop", size.X, size.Y)
	local same = true
	for _, plants in ipairs({ false, true }) do
		local bag = HudLayout.bag(L, { hotTop = L.hotbar.y, stripHidden = L.touch,
			plants = plants, sideWidth = 64 })
		local cx, cy, w, h = shippedBag(L.safe, L.hotbar.y, 64)
		same = same and not L.compact and not bag.horizontal and bag.rows == 0
			and bag.centre.X == cx and bag.centre.Y == cy and bag.panel.w == w and bag.panel.h == h
			and bag.card == BAGC.Card
	end
	local bag = HudLayout.bag(L, { hotTop = L.hotbar.y, stripHidden = false, plants = false, sideWidth = 64 })
	check(same, tag .. ": the Bag is exactly the shipped panel, the 104x158 card and the vertical grid",
		string.format("centre %d,%d size %dx%d", bag.centre.X, bag.centre.Y, bag.panel.w, bag.panel.h))
	check(bag.panel.y + bag.panel.h + 8 <= L.hotbar.y,
		tag .. ": and it still stops 8 px above the ten-slot strip, which stays", r2s(bag.panel))
end

-- The header rule UIKit.modal applies: the title bar pads clear of the rail
-- band it shares rows with, and the close button moves in with it.
local titleWidth = TextService:GetTextSize("Bag", 26, Enum.Font.LuckiestGuy, Vector2.new(1000, 100)).X
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
	local tabs
	if bag.compactHeader then
		local reserve = math.max(72, math.ceil(titleWidth) + padLeft + 16)
		tabs = rect(shell.x + 12 + reserve, shell.y + 13, shell.w - (24 + reserve + 52 + padRight), 34)
	else
		tabs = rect(shell.x + 12, shell.y + 58, shell.w - 24, 34)
	end
	return shell, titleRect, tabs, close
end

-- The longest names the game ships, in the compact name box at 12 pt: two
-- lines at most, which is what fitName checks before it would truncate.
local LONG_NAMES = { "SUNFLOWER BONKER", "BRAMBLEJAW TRAP", "CINDERBURST MINE", "CINDERCRACK BAT",
	"STARLOCK ANCHOR", "MIREWOOD PADDLE", "THORNWHORL", "GLOOMLOTUS", "ASTRALHORN" }
local namesFit = true
for _, name in ipairs(LONG_NAMES) do
	local at14 = TextService:GetTextSize(name, 14, Enum.Font.LuckiestGuy,
		Vector2.new(BAGC.CardCompact.X - 14, 1000))
	namesFit = namesFit and at14.Y <= 32
end
check(namesFit, "every long shipped name is two lines at 14 pt in the compact card's 98 x 32 name box")
local pillWord = TextService:GetTextSize("TAP TO EQUIP", 15, Enum.Font.FredokaOne, Vector2.new(400, 40)).X
check(BAGC.ActionH >= 44 and pillWord <= BAGC.CardCompact.X - 12,
	"the compact action button is the whole 44 px strip and TAP TO EQUIP fits it at 15 pt", pillWord)
check(84 + 32 <= 120 and 120 + BAGC.ActionH <= BAGC.CardCompact.Y - 4,
	"inside a 112x170 card the name (84-116) and the button (120-164) never touch")

local BAG_CASES = {
	{ tag = "iPhone 11 896x414", input = screen(896, 414, { touch = true }) },
	{ tag = "iPhone 11 896x414 notched", input = screen(896, 414, { touch = true, left = 48, right = 48, bottom = 21 }) },
	{ tag = "iPhone 16 Pro Max 956x440", input = screen(956, 440, { touch = true }) },
	{ tag = "Galaxy S22 Ultra 772x360", input = screen(772, 360, { touch = true }) },
	{ tag = "VGA 640x480", input = screen(640, 480, { touch = true }) },
	{ tag = "the owner's 801x392", input = screen(801, 392, { touch = true }) },
}
for _, case in ipairs(BAG_CASES) do
	local L = HudLayout.solve(case.input)
	local sw, sh = L.safe.X, L.safe.Y
	for _, plants in ipairs({ false, true }) do
		local tab = if plants then "Plants" else "Equipment"
		local tag = case.tag .. " " .. tab
		local bag = HudLayout.bag(L, { hotTop = L.hotbar.y, stripHidden = L.touch,
			plants = plants, sideWidth = 64 })
		local p = bag.panel
		check(p.x >= 8 and p.y >= 8 and p.x + p.w <= sw - 8 and p.y + p.h <= sh - 8
				and p.x + p.w + 8 <= L.equipment.x,
			tag .. ": the panel is inside the safe area and clear of BAT/TRAP", r2s(p))
		check(p.y + p.h > L.hotbar.y,
			tag .. ": it runs over where the hidden strip was -- no strip-shaped hole", r2s(p))
		-- whole rows only, centred in the tray: nothing cut at the top or bottom
		local rowsTall = bag.rows * bag.card.Y + (bag.rows - 1) * BAGC.CardGap
		local slack = bag.tray.h - BAGC.PadY * 2 - rowsTall
		local cardTop = bag.tray.y + BAGC.PadY + slack / 2
		check(bag.horizontal and bag.rows >= 1 and slack >= 0 and bag.card == BAGC.CardCompact,
			tag .. ": sideways, in whole 112x170 rows that fit the tray", string.format(
				"tray %s rows %d slack %.1f", r2s(bag.tray), bag.rows, slack))
		local _, title, tabs, close = header(L, bag)
		local headerBottom = tabs.y + tabs.h
		check(cardTop >= headerBottom + 8 and bag.tray.y >= headerBottom + 8,
			tag .. ": the first card starts below the header and tabs with room to spare",
			string.format("header ends %.1f, tray %.1f, card %.1f", headerBottom, bag.tray.y, cardTop))
		check(cardTop + rowsTall <= bag.tray.y + bag.tray.h - BAGC.PadY,
			tag .. ": and the last row ends inside the tray", cardTop + rowsTall)
		-- title, tabs and close apart, and none under a rail button. 4 px, not
		-- 8: the two-row header's 44 px close target has always stood 6 px
		-- above its tab row, by design, and apart is the requirement.
		local clear = HudLayout.gap(title, tabs) >= 4 and HudLayout.gap(tabs, close) >= 4
			and HudLayout.gap(title, close) >= 4 and tabs.w / 2 >= 120
		for _, g in ipairs(HudLayout.groups(L, true)) do
			if g.name == "rail" or g.name == "garden+bag" then
				clear = clear and HudLayout.gap(title, g.rect) >= 0 and HudLayout.gap(tabs, g.rect) >= 0
					and HudLayout.gap(close, g.rect) >= 0
			end
		end
		check(clear, tag .. ": title, both tabs and the close button stand apart and clear of the rail rows",
			string.format("title %s tabs %s close %s", r2s(title), r2s(tabs), r2s(close)))
		local shown = (bag.tray.w - BAGC.PadX * 2 + BAGC.CardGap) / (bag.card.X + BAGC.CardGap)
		say(string.format("    %s: panel %s  %s header  tray %s  %d row(s), %.1f cards across, card top %.1f",
			tag, r2s(p), if bag.compactHeader then "one-row" else "two-row", r2s(bag.tray),
			bag.rows, shown, cardTop))
	end
end

-- A small desktop window is compact without touch: the strip stays, so the Bag
-- still stops above it.
do
	local L = HudLayout.solve(screen(860, 700, { touch = false }))
	local bag = HudLayout.bag(L, { hotTop = L.hotbar.y, stripHidden = L.touch, plants = false, sideWidth = 64 })
	check(L.compact and not L.touch and bag.panel.y + bag.panel.h + 8 <= L.hotbar.y and bag.rows >= 1,
		"a small desktop window keeps its strip, and the Bag stops above it", r2s(bag.panel))
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
	CashUI = 2, IndexUI = 0, ShopUI = 0, SettingsUI = 0, WalkModeUI = 1, GardenUI = 1,
	LoadoutUI = 2, WorldClock = 1, TutorialUI = 1, BiomeGuideUI = 0, RailDrawerUI = 0,
}
-- The two owners that draw into the shared rail layer and make no ScreenGui.
local LAYER_ONLY = { WalkModeUI = true, RailDrawerUI = true }
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
	check(src ~= nil and count(src, 'Instance.new("ScreenGui")') == (if LAYER_ONLY[name] then 0 else 1)
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

check(loadout:find("hotbar.Visible = not (bagOpen and not lifted and layout ~= nil and layout.touch)", 1, true) ~= nil
		and loadout:find("	bagOpen = want\n	showStrip()", 1, true) ~= nil,
	"on touch the strip hides while the Bag is open, shows while a card is in the air, and returns on close")
check(loadout:find("stripHidden = layout.touch", 1, true) ~= nil,
	"and the Bag grows into its space on exactly that condition")
check(loadout:find("HudLayout.bag(layout,", 1, true) ~= nil
		and select(2, loadout:gsub("grid.CanvasPosition = Vector2.zero", "")) >= 3,
	"LoadoutUI places the Bag from HudLayout.bag and resets the scroll on a tab switch, a side slot and a new direction")
check(loadout:find("padRight), 0, 34)", 1, true) ~= nil,
	"the one-row tabs stop short of the close button wherever the header has moved it")
check(select(2, loadout:gsub('Instance.new%("ScrollingFrame"%)', "")) == 2
		and select(2, loadout:gsub('Instance.new%("UIGridLayout"%)', "")) == 2,
	"still one Bag grid and one info grid, and the chooser's one row -- nothing rebuilt")

local kit = Shared:FindFirstChild("UIKit").Source
check(kit:find("function UIKit.railShape", 1, true) and kit:find("function UIKit.railBadge", 1, true)
		and kit:find("if layout.compact then", 1, true),
	"UIKit reshapes a rail button for its owner and steps modal headers clear of the compact rows")

--==============================================================================
-- 7. THE PHONE'S SIDEBARS, WIRED
--
-- The approved mobile redesign of 2026-09-23, read from the owners that draw
-- it: every control still has exactly the owner it had, the dock is a frame
-- they stand in rather than a controller, the belt drops the weapons on a phone
-- only, and the chooser equips through the verb that already existed.
--==============================================================================
say("-- the sidebars, wired --")

-- Only a touch screen is a phone. Every non-touch answer carries none of it.
local plain = true
for _, input in ipairs({ screen(1920, 1080), screen(1000, 609), screen(860, 700, { touch = false }),
	screen(700, 400, { touch = false }), screen(1920, 1080, { keyboard = false }) }) do
	local L = HudLayout.solve(input)
	plain = plain and not L.sidebar and L.dock == nil and L.handle == nil and L.handleShut == nil
		and L.boost == nil and L.chooser == nil and L.equipPad == 0
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

for _, name in ipairs({ "IndexUI", "ShopUI", "SettingsUI" }) do
	local src = sourceOf(name) or ""
	check(src:find("if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)", 1, true) ~= nil
			and src:find("UIKit.railShape(button,", 1, true) ~= nil
			and count(src, "UIKit.railButton(") == 1,
		name .. " still owns its one rail button, and on a phone stands it in the dock as a tile")
end
local drawer = sourceOf("RailDrawerUI") or ""
check(drawer:find("UIKit.railDock(playerGui)", 1, true) ~= nil
		and drawer:find("player:GetAttribute(ATTR.OpenPanel) ~= nil", 1, true) ~= nil
		and drawer:find("layout.handleShut", 1, true) ~= nil
		and not drawer:find("IndexButton", 1, true) and not drawer:find("ShopButton", 1, true)
		and not drawer:find("SettingsButton", 1, true),
	"RailDrawerUI owns the dock's panel, handle and open/shut, steps aside for a panel, and touches no tile")
check(kit:find("function UIKit.railDock", 1, true) ~= nil
		and kit:find("layer:FindFirstChild(options.name, true)", 1, true) ~= nil,
	"the dock is one shared frame, and a re-run rail button finds its old self inside it")

check(loadout:find("or (plantsOnly and liveSlots[nextFree].item ~= nil)", 1, true) ~= nil
		and loadout:find("local plantsOnly = hud ~= nil and hud.sidebar", 1, true) ~= nil,
	"on a phone the belt fills with pods and plants only -- the weapons are not drawn twice")
check(loadout:find("chooser.toggle(category)", 1, true) ~= nil
		and loadout:find("equipRequest(item)", 1, true) ~= nil
		and count(loadout, "FireServer(W.EquipAction") == 2
		and loadout:find("if item.Category == category and owned[item.Id] then", 1, true) ~= nil,
	"BATS and TRAPS open a chooser of what the profile says is owned, which equips through the one equip verb")
check(loadout:find("UserInputService.InputBegan:Connect(", 1, true) ~= nil
		and loadout:find("chooser.close()", 1, true) ~= nil
		and loadout:find("player.CharacterRemoving:Connect(function()\n\tchooser.close()", 1, true) ~= nil,
	"the chooser shuts on an outside tap (without swallowing it), a panel opening and the character going")
check(count(cash, 'buff.Name = "MoneyBuff"') == 1 and cash:find("local at = if layout.sidebar then layout.boost else nil", 1, true) ~= nil
		and cash:find("buff.Parent = root", 1, true) ~= nil,
	"one x2 card: on a phone it stands on the top-right row, elsewhere it goes back beside the cash")

end)

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nHudLayoutSpec: %d passed, 0 failed"):format(pass)
