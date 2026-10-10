--!strict
--==============================================================================
-- Steal a Seed :: MenuLayout (2026-10-03, the compact Index and Shop)
--
-- WHERE A COMPACT MENU STANDS AND HOW ITS INSIDES SHARE THE ROOM. Numbers only:
-- rects in, rects out, no Instance -- so CompactMenusSpec can lay a menu out for
-- every listed desktop and phone without a Play session, the way HudLayoutSpec
-- does for the HUD. IndexUI and ShopUI apply the answers.
--
--   the panel   on a desktop, BETWEEN THE RAILS (nothing of the HUD's can stand
--               over it, and the rail stays pressable -- the Index and Shop
--               buttons still trade places); on a phone or a window too narrow
--               for that, the whole safe area less a small margin, and the
--               panel COVERS the rail layer while open (UIKit.coverRail).
--               Never past the on-screen keyboard's top while it shows.
--   the header  ONE row: icon, title, the panel's controls, the close button.
--               A short screen's row is 44, a desktop's 50.
--   the nav     a narrow sidebar where the panel is wide and tall enough for a
--               column of biomes or categories, else a dropdown in the header.
--   the grid    columns from the width and a readable minimum card -- never a
--               forced count -- and cards no wider than a maximum.
--
-- Every number is in the menu gui's own logical units: its pixels divided by
-- its scale (UIKit.scaleOf), which is also what HudLayout's rails are divided
-- by before they come here.
--==============================================================================
local MenuLayout = {}

export type Rect = { x: number, y: number, w: number, h: number }

MenuLayout.Config = {
	-- Off the safe area's edges and off the rails' buttons.
	EdgeGap = 8,
	-- A desktop panel stands between the rails only with at least this between
	-- them; less, and it takes the safe area and covers the rail.
	MinBetween = 600,
	-- The shell's outline (GameConfig.Rail.OutlineThickness is passed in).
	-- The header row: short screens, and the rest.
	HeaderShort = 44,
	HeaderTall = 50,
	-- The studded rim's overhang (2026-10-04, the global UI art pass): the
	-- title, its icon and the close stand ON the rim's top edge, in this much
	-- of the panel above the shell -- inside the panel's rect, never over the
	-- topbar. The shell is this much shorter; its blocks do not move. A short
	-- screen keeps only enough for the close to ride the rim: every pixel there
	-- is a card's (CompactMenusSpec: MY PLANTS' whole row on a 705 x 338 needs
	-- 147 px and has 150 without a lift).
	LiftShort = 3,
	LiftTall = 14,
	ShortBelow = 380,
	-- The inside margin of the shell, and the gap between blocks.
	PadShort = 8,
	PadTall = 10,
	Gap = 6,
	-- The sidebar, and when there is room for one.
	Sidebar = 170,
	SidebarMinW = 700,
	SidebarMinH = 380,
	-- Every control a finger presses.
	Touch = 44,
}

local C = MenuLayout.Config

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = x, y = y, w = w, h = h }
end
MenuLayout.rect = rect

--==============================================================================
-- THE PANEL
--==============================================================================
export type Screen = {
	-- The safe area, logical units (a ScreenGui that keeps the inset: below the
	-- topbar and inside the notch -- never padded for them a second time).
	safe: Vector2,
	-- HudLayout's answer for this screen: compact (a phone, or a small window)
	-- and the two rails' inner edges and the band they stand in, logical units.
	compact: boolean,
	railRight: number,
	rightLeft: number,
	-- The top of the on-screen keyboard in safe space, while it shows.
	keyboardTop: number?,
	-- The share of the safe area a covering panel takes, nil for all of it. A
	-- menu drawn smaller than 1:1 -- a phone's (2026-10-08, UIKit.menuScaleFor)
	-- -- sees a safe area that much larger, so taking only that share keeps the
	-- room it had at 1:1, centred, and on screen it stops short of the edges:
	-- pass math.min(1, the gui's scale).
	fill: number?,
}

export type Panel = {
	rect: Rect,
	-- True when the panel takes the safe area: the rail layer must step under it.
	covers: boolean,
	-- The shell inside the outline (and under the rim's lift), the header row,
	-- and the nav's kind.
	shell: Vector2,
	header: number,
	lift: number,
	pad: number,
	sidebar: boolean,
	short: boolean,
}

function MenuLayout.panel(s: Screen, maxW: number, maxH: number, outline: number): Panel
	local gap = C.EdgeGap
	local sw, sh = s.safe.X, s.safe.Y
	local bottom = sh - gap
	local keyboard = s.keyboardTop
	if keyboard and keyboard > 0 then
		bottom = math.min(bottom, keyboard - gap)
	end
	local top = gap
	local left, right = s.railRight + gap, s.rightLeft - gap
	local covers = s.compact or right - left < C.MinBetween
	if covers then
		left, right = gap, sw - gap
		local fill = s.fill
		if fill and fill > 0 and fill < 1 then
			-- Only the middle `fill` of the safe area, each way.
			local mx, my = sw * (1 - fill) / 2, sh * (1 - fill) / 2
			left, right = mx + gap, sw - mx - gap
			top = my + gap
			bottom = math.min(bottom, sh - my - gap)
		end
	end
	local width = math.max(0, math.min(maxW, right - left))
	-- Centred on the screen when that still clears both rails; else centred
	-- between them.
	local half = sw / 2
	local centreX = if 2 * math.min(half - left, right - half) >= width then half else (left + right) / 2
	local height = math.max(0, math.min(maxH, bottom - top))
	local x = math.floor(centreX - width / 2)
	local y = math.floor(top + (bottom - top - height) / 2)
	width, height = math.floor(width), math.floor(height)
	local short = height < C.ShortBelow
	local lift = if short then C.LiftShort else C.LiftTall
	local shell = Vector2.new(width - outline * 2, math.max(0, height - outline * 2 - lift))
	return {
		rect = rect(x, y, width, height),
		covers = covers,
		shell = shell,
		header = if short then C.HeaderShort else C.HeaderTall,
		lift = lift,
		pad = if short then C.PadShort else C.PadTall,
		sidebar = shell.X >= C.SidebarMinW and shell.Y >= C.SidebarMinH,
		short = short,
	}
end

--==============================================================================
-- THE BLOCKS INSIDE THE SHELL, in the shell's own coordinates: the header row,
-- the sidebar (zero wide without one) and the main column beside it.
--==============================================================================
export type Blocks = { header: Rect, sidebar: Rect, main: Rect }

function MenuLayout.blocks(p: Panel): Blocks
	local w, h = p.shell.X, p.shell.Y
	local top = p.header + C.Gap
	local side = if p.sidebar then C.Sidebar else 0
	local mainX = p.pad + (if p.sidebar then side + C.Gap + 4 else 0)
	return {
		header = rect(p.pad, 0, w - p.pad * 2, p.header),
		sidebar = rect(p.pad, top, side, math.max(0, h - p.pad - top)),
		main = rect(mainX, top, math.max(0, w - p.pad - mainX), math.max(0, h - p.pad - top)),
	}
end

--==============================================================================
-- ONE ROW OF CONTROLS
--
-- Items left to right with `gap` between them. An item is `w` wide, or grows
-- (`grow`) from `minW` up to `maxW` into whatever the row has left. When even
-- the minimums do not fit, items with a `drop` rank leave the row, lowest rank
-- first, until they do; an item without one never leaves. Answers each shown
-- item's x and width, and nil for one that was dropped.
--==============================================================================
export type Item = { id: string, w: number?, minW: number?, maxW: number?, grow: boolean?, drop: number? }

function MenuLayout.pack(x0: number, x1: number, gap: number, items: { Item }): { [string]: Rect }
	local shown: { Item } = table.clone(items)
	local function need(list: { Item }): number
		local total = 0
		for i, item in ipairs(list) do
			total += if item.grow then (item.minW or 0) else (item.w or 0)
			if i > 1 then
				total += gap
			end
		end
		return total
	end
	local room = x1 - x0
	while need(shown) > room do
		local worst: number? = nil
		for i, item in ipairs(shown) do
			local d = item.drop
			if d and (worst == nil or d < (shown[worst :: number].drop :: number)) then
				worst = i
			end
		end
		if not worst then
			break
		end
		table.remove(shown, worst)
	end
	-- The growing items share what is left, each up to its own maximum.
	local spare = math.max(0, room - need(shown))
	local widths: { [Item]: number } = {}
	local growers: { Item } = {}
	for _, item in ipairs(shown) do
		if item.grow then
			widths[item] = item.minW or 0
			table.insert(growers, item)
		else
			widths[item] = item.w or 0
		end
	end
	while spare > 0.5 and #growers > 0 do
		local share = spare / #growers
		local still: { Item } = {}
		for _, item in ipairs(growers) do
			local cap = item.maxW or math.huge
			local add = math.min(share, cap - widths[item])
			widths[item] += add
			spare -= add
			if widths[item] < cap - 0.5 then
				table.insert(still, item)
			end
		end
		if #still == #growers then
			break
		end
		growers = still
	end
	local out: { [string]: Rect } = {}
	local x = x0
	for i, item in ipairs(shown) do
		if i > 1 then
			x += gap
		end
		local w = math.floor(widths[item])
		out[item.id] = rect(math.floor(x), 0, w, 0)
		x += widths[item]
	end
	return out
end

--==============================================================================
-- A GRID OF CARDS
--
-- As many columns as cards of at least `minW` fit, never fewer than one; each
-- card the width that fills the row, but no wider than `maxW` (then the row
-- stays left-aligned and ends short). `inset` is the grid's own padding.
--==============================================================================
export type Grid = { columns: number, cardW: number, inset: number, gap: number }

function MenuLayout.grid(width: number, minW: number, maxW: number, gap: number, inset: number): Grid
	local room = width - inset * 2
	local columns = math.max(1, math.floor((room + gap) / (minW + gap)))
	local cardW = math.floor(math.min(maxW, (room - gap * (columns - 1)) / columns))
	return { columns = columns, cardW = math.max(1, cardW), inset = inset, gap = gap }
end

-- How tall a grid of `count` cards is, for a canvas.
function MenuLayout.gridHeight(g: Grid, count: number, cardH: number): number
	local rows = math.ceil(count / g.columns)
	if rows <= 0 then
		return g.inset * 2
	end
	return g.inset * 2 + rows * cardH + (rows - 1) * g.gap
end

--==============================================================================
-- THE TWO MENUS' OWN NUMBERS AND HEADER ROWS
--
-- Here rather than in IndexUI and ShopUI, so CompactMenusSpec lays out exactly
-- what the scripts lay out. `titleW` is the title's footprint (icon and words)
-- in the header; the row runs from after it to before the close button.
--==============================================================================
MenuLayout.Index = {
	MaxW = 960,
	MaxH = 600,
	-- A card no narrower than this (a phone's type is a point larger), no wider
	-- than that; its preview this share of its width, its words under it.
	CardMinShort = 116,
	CardMinTall = 128,
	CardMax = 170,
	CardGap = 8,
	GridInset = 8,
	PreviewShare = 0.6,
	CardWords = 52,
	ProgressShort = 34,
	ProgressTall = 38,
	FilterShort = 150,
	FilterTall = 186,
	-- ONE PAGE (2026-10-06): each biome's heading -- its progress row, Progress
	-- tall -- over its cards, HeadingGap between them, SectionGap between one
	-- biome's last row and the next heading.
	HeadingGap = 4,
	SectionGap = 10,
}

MenuLayout.Shop = {
	MaxW = 880,
	MaxH = 600,
	-- A phone's cards are rows two across; a desktop's small tiles, more across.
	CardMinShort = 260,
	CardMinTall = 196,
	CardMax = 420,
	CardGap = 8,
	GridInset = 8,
	-- A card at least RowFrom wide is a row (its button on the right), else a tile.
	RowH = 56,
	TileH = 122,
	RowFrom = 300,
	BuyW = 112,
	OddsW = 156,
	-- ONE PAGE (2026-10-06): each shelf's heading over its cards, HeadingGap
	-- between them, SectionGap between one shelf's last row and the next heading.
	HeadingH = 28,
	HeadingGap = 4,
	SectionGap = 10,
}

local function headerSpan(p: Panel, titleW: number): (number, number)
	return p.pad + titleW + 10, p.shell.X - p.pad - C.Touch - C.Gap
end

-- The Index's header: the search and the filter at its right end. One page
-- since 2026-10-06, so no biome to choose (it had a dropdown, or a sidebar).
function MenuLayout.indexHeader(p: Panel, titleW: number): { [string]: Rect }
	local x0, x1 = headerSpan(p, titleW)
	return MenuLayout.pack(x0, x1, C.Gap, {
		{ id = "spacer", grow = true, minW = 0, maxW = 10000 },
		{ id = "search", grow = true, minW = 100, maxW = 240, drop = 1 },
		{ id = "filter", w = if p.short then MenuLayout.Index.FilterShort else MenuLayout.Index.FilterTall },
	})
end

-- The Shop's header: REWARDS & ODDS at its right end. One page since
-- 2026-10-06, so no category to choose (it had a dropdown, or a sidebar).
function MenuLayout.shopHeader(p: Panel, titleW: number): { [string]: Rect }
	local x0, x1 = headerSpan(p, titleW)
	return MenuLayout.pack(x0, x1, C.Gap, {
		{ id = "spacer", grow = true, minW = 0, maxW = 10000 },
		{ id = "odds", w = MenuLayout.Shop.OddsW, drop = 1 },
	})
end

export type CardGrid = { grid: Grid, cardW: number, cardH: number, previewH: number, rows: boolean }

--==============================================================================
-- A DESKTOP PANEL ENDS WHERE ITS CONTENT DOES
--
-- A phone's panel takes the whole height: its content needs every row it can
-- get. A desktop's is as tall as its content -- the Index's and the Shop's
-- whole one page (2026-10-06), MY PLANTS' three rows -- never past its MaxH,
-- and never a 600-px slab over one row of five cards.
--==============================================================================

function MenuLayout.indexCards(p: Panel, gridW: number): CardGrid
	local I = MenuLayout.Index
	local g = MenuLayout.grid(gridW, if p.short then I.CardMinShort else I.CardMinTall, I.CardMax, I.CardGap,
		I.GridInset)
	local previewH = math.floor(g.cardW * I.PreviewShare)
	return { grid = g, cardW = g.cardW, cardH = previewH + I.CardWords, previewH = previewH, rows = false }
end

function MenuLayout.shopCards(p: Panel, gridW: number): CardGrid
	local S = MenuLayout.Shop
	local g = MenuLayout.grid(gridW, if p.short then S.CardMinShort else S.CardMinTall, S.CardMax, S.CardGap,
		S.GridInset)
	local rows = g.cardW >= S.RowFrom
	return { grid = g, cardW = g.cardW, cardH = if rows then S.RowH else S.TileH, previewH = 0, rows = rows }
end

--==============================================================================
-- MY PLANTS (2026-10-04): a header with the PLANTED / STORED tabs and the plot
-- count, a grid of creature cards, and a footer OUTSIDE the scroll with the
-- garden's income, the selected card's one action, EQUIP BEST and UNEQUIP ALL.
-- A phone's cards are a little wider than a desktop's (fewer, readable
-- columns rather than everything smaller).
--==============================================================================
MenuLayout.Plants = {
	MaxW = 900,
	MaxH = 600,
	CardMinShort = 124,
	CardMinTall = 130,
	CardMax = 168,
	CardGap = 8,
	GridInset = 8,
	PreviewShare = 0.5,
	CardWords = 54,
	TabsShort = 196,
	TabsTall = 220,
	CountW = 92,
	-- The SORT button (2026-10-10, GameConfig.Sort): before the count, and it
	-- outlasts it on a narrow header.
	SortW = 84,
	FooterH = 44,
	-- The footer's pieces: the income line, then three buttons.
	IncomeMinW = 104,
	ActionW = 150,
	BestW = 124,
	ClearW = 124,
}

function MenuLayout.plantsHeader(p: Panel, titleW: number): { [string]: Rect }
	local x0, x1 = headerSpan(p, titleW)
	local P = MenuLayout.Plants
	return MenuLayout.pack(x0, x1, C.Gap, {
		{ id = "tabs", w = if p.short then P.TabsShort else P.TabsTall },
		{ id = "spacer", grow = true, minW = 0, maxW = 10000 },
		{ id = "sort", w = P.SortW, drop = 2 },
		{ id = "count", w = P.CountW, drop = 1 },
	})
end

-- The footer row inside the main block: income, action, EQUIP BEST, UNEQUIP ALL.
function MenuLayout.plantsFooter(mainW: number): { [string]: Rect }
	local P = MenuLayout.Plants
	return MenuLayout.pack(0, mainW, C.Gap, {
		{ id = "income", grow = true, minW = P.IncomeMinW, maxW = 10000 },
		{ id = "action", w = P.ActionW },
		{ id = "best", w = P.BestW },
		{ id = "clear", w = P.ClearW },
	})
end

function MenuLayout.plantsCards(p: Panel, gridW: number): CardGrid
	local P = MenuLayout.Plants
	local g = MenuLayout.grid(gridW, if p.short then P.CardMinShort else P.CardMinTall, P.CardMax, P.CardGap,
		P.GridInset)
	local previewH = math.floor(g.cardW * P.PreviewShare)
	return { grid = g, cardW = g.cardW, cardH = previewH + P.CardWords, previewH = previewH, rows = false }
end

-- The Index's one page (2026-10-06): every biome's heading and its rows of
-- cards, top to bottom, inside the list's inset. `counts` is each biome's
-- number of cards, in road order.
function MenuLayout.indexPageHeight(p: Panel, cg: CardGrid, counts: { number }): number
	local I = MenuLayout.Index
	local g = cg.grid
	local head = if p.short then I.ProgressShort else I.ProgressTall
	local h = g.inset * 2
	for i, n in ipairs(counts) do
		local rows = math.ceil(n / g.columns)
		h += head + I.HeadingGap + rows * cg.cardH + math.max(0, rows - 1) * g.gap
		if i > 1 then
			h += I.SectionGap
		end
	end
	return h
end

-- The panels themselves: the scripts and the spec both ask these. The Index
-- has no sidebar (one page, 2026-10-06): on a desktop as tall as the whole
-- page, never past MaxH (the rest scrolls); on a phone the whole height.
function MenuLayout.indexPanel(s: Screen, outline: number, counts: { number }): Panel
	local I = MenuLayout.Index
	local p = MenuLayout.panel(s, I.MaxW, I.MaxH, outline)
	p.sidebar = false
	if p.short then
		return p
	end
	local cg = MenuLayout.indexCards(p, MenuLayout.blocks(p).main.w - 5)
	local need = MenuLayout.indexPageHeight(p, cg, counts)
	local h = math.ceil(p.lift + p.header + C.Gap + need + p.pad + outline * 2)
	local q = MenuLayout.panel(s, I.MaxW, math.min(I.MaxH, math.max(C.ShortBelow, h)), outline)
	q.sidebar = false
	return q
end

-- MY PLANTS has no sidebar: on a desktop it is as tall as its footer and three
-- rows of cards (a 20-slot plot scrolls the rest).
function MenuLayout.plantsPanel(s: Screen, outline: number): Panel
	local P = MenuLayout.Plants
	local p = MenuLayout.panel(s, P.MaxW, P.MaxH, outline)
	p.sidebar = false
	if p.short then
		return p
	end
	local cg = MenuLayout.plantsCards(p, MenuLayout.blocks(p).main.w - 5)
	local need = MenuLayout.gridHeight(cg.grid, cg.grid.columns * 3, cg.cardH) + C.Gap + P.FooterH
	local h = math.ceil(p.lift + p.header + C.Gap + need + p.pad + outline * 2)
	local q = MenuLayout.panel(s, P.MaxW, math.min(P.MaxH, math.max(C.ShortBelow, h)), outline)
	q.sidebar = false
	return q
end

-- The Shop's one page (2026-10-06): every shelf's heading and its rows of
-- cards, top to bottom, inside the list's inset. `counts` is each shelf's
-- number of cards, in order.
function MenuLayout.shopPageHeight(cg: CardGrid, counts: { number }): number
	local S = MenuLayout.Shop
	local g = cg.grid
	local h = g.inset * 2
	for i, n in ipairs(counts) do
		local rows = math.ceil(n / g.columns)
		h += S.HeadingH + S.HeadingGap + rows * cg.cardH + math.max(0, rows - 1) * g.gap
		if i > 1 then
			h += S.SectionGap
		end
	end
	return h
end

-- No sidebar (one page, 2026-10-06): on a desktop as tall as the whole page,
-- never past MaxH (the rest scrolls); on a phone the whole height.
function MenuLayout.shopPanel(s: Screen, outline: number, counts: { number }): Panel
	local S = MenuLayout.Shop
	local p = MenuLayout.panel(s, S.MaxW, S.MaxH, outline)
	p.sidebar = false
	if p.short then
		return p
	end
	local cg = MenuLayout.shopCards(p, MenuLayout.blocks(p).main.w - 5)
	local need = MenuLayout.shopPageHeight(cg, counts)
	local h = math.ceil(p.lift + p.header + C.Gap + need + p.pad + outline * 2)
	local q = MenuLayout.panel(s, S.MaxW, math.min(S.MaxH, math.max(C.ShortBelow, h)), outline)
	q.sidebar = false
	return q
end

--==============================================================================
-- EVENTS (2026-10-04): the header -- the title, BACK while one of several
-- events is open, the close -- and under it either the list (one compact row
-- per event, its picture at the left, soonest first) or one event's details.
-- No sidebar. One size for both views, so the panel never jumps between them.
--
-- THE DETAILS, two ways:
--
--   side by side  wherever the block is SideMinW wide -- every desktop and
--                 every landscape phone: the picture, the schedule badge and
--                 the local time in a left column; the title, the subtitle,
--                 the words (scrolling) and the button in the right one. The
--                 picture gives way first, so on a 338-px phone it is smaller
--                 and the words and the button keep their room.
--   stacked       on a narrow (portrait) block: the picture across the top, at
--                 most BannerShare of the height and never so tall that the
--                 words drop under WordsMin; then the badge, the time, the
--                 title and the words.
--
-- Either way the button is pinned to the foot of its column, outside the
-- words' scroll, so it never scrolls away. The picture's box is 16:9 and the
-- picture is FIT inside it: nothing is cropped or stretched.
--==============================================================================
MenuLayout.Events = {
	MaxW = 680,
	MaxH = 440,
	-- A narrow (portrait) screen stacks the details, and may be taller.
	MaxHStacked = 640,
	-- The list: one row per event; its picture box is 16:9 inside the row.
	RowShort = 70,
	RowTall = 80,
	RowGap = 6,
	ListInset = 6,
	-- The details.
	SideMinW = 460,
	SideShare = 0.42,
	BannerShare = 0.38,
	BadgeH = 26,
	WhenH = 34,
	TitleH = 30,
	SubtitleH = 20,
	ActionH = 44,
	ActionMaxW = 300,
	WordsMin = 48,
	Gap = 6,
	BackW = 104,
}

function MenuLayout.eventsPanel(s: Screen, outline: number): Panel
	local E = MenuLayout.Events
	local p = MenuLayout.panel(s, E.MaxW, E.MaxH, outline)
	p.sidebar = false
	if MenuLayout.blocks(p).main.w < E.SideMinW then
		p = MenuLayout.panel(s, E.MaxW, E.MaxHStacked, outline)
		p.sidebar = false
	end
	return p
end

-- The header row: BACK (while it shows) after the title, then nothing.
function MenuLayout.eventsHeader(p: Panel, titleW: number, back: boolean): { [string]: Rect }
	local x0, x1 = headerSpan(p, titleW)
	local items: { Item } = {}
	if back then
		table.insert(items, { id = "back", w = MenuLayout.Events.BackW })
	end
	table.insert(items, { id = "spacer", grow = true, minW = 0, maxW = 10000 })
	return MenuLayout.pack(x0, x1, C.Gap, items)
end

export type EventRows = { rowH: number, thumbW: number, thumbH: number }

function MenuLayout.eventRows(p: Panel): EventRows
	local E = MenuLayout.Events
	local rowH = if p.short then E.RowShort else E.RowTall
	local thumbH = rowH - 16
	return { rowH = rowH, thumbH = thumbH, thumbW = math.floor(thumbH * 16 / 9) }
end

export type EventDetail = {
	side: boolean,
	banner: Rect,
	badge: Rect,
	when: Rect,
	title: Rect,
	subtitle: Rect?,
	words: Rect,
	action: Rect,
}

--==============================================================================
-- WHAT'S NEW (2026-10-05, UpdateLogUI)
--
-- One column of light cards, newest first, in a scrolling well: the EVENTS
-- panel's frame (between the rails on a desktop, the whole safe area -- and
-- covering the rail -- in compact and on a phone), narrower because its words
-- are short bullets. A card is its date (with the newest card's tag at the
-- line's right end), its title on a line of its own, then a bullet a line --
-- two where a narrow screen wraps it -- so a short entry is a short card, and
-- a short log a short panel: the well no taller than its cards (`content`).
--
-- Nothing here measures text. UpdateLogUI lets the engine size each card
-- (AutomaticSize) and hands the cards' height back; laid out from a width
-- measured while FredokaOne was still loading, a date came out 15 px short and
-- ran into its title (seen in Play 2026-10-05). UpdateLogSpec measures every
-- shipped line against the narrowest screen the button stands on.
--==============================================================================
MenuLayout.Updates = {
	MaxW = 560,
	MaxH = 460,
	-- The well, and the cards in it.
	ListInset = 6,
	ScrollBar = 5,
	CardGap = 8,
	CardInset = 12,
	-- The date's line, the title's line and the gap under them.
	DateH = 18,
	DateSize = 14,
	TitleH = 24,
	TitleSize = 18,
	HeadGap = 4,
	-- The newest card's tag, on the date's line at its right end.
	TagW = 52,
	TagH = 18,
	TagGap = 8,
	-- One bullet line, and the mark's indent.
	BulletSize = 15,
	BulletLine = 22,
	BulletIndent = 16,
}

function MenuLayout.updatesPanel(s: Screen, outline: number, content: number?): Panel
	local U = MenuLayout.Updates
	local p = MenuLayout.panel(s, U.MaxW, U.MaxH, outline)
	p.sidebar = false
	-- Shorter where the cards (`content` tall) leave the well room to spare;
	-- asked again once, as a shorter panel can have the short header.
	if content then
		for _ = 1, 2 do
			local spare = MenuLayout.blocks(p).main.h - (content + U.ListInset * 2)
			if spare < 1 then
				break
			end
			p = MenuLayout.panel(s, U.MaxW, p.rect.h - math.floor(spare), outline)
			p.sidebar = false
		end
	end
	return p
end

-- How far a card's own lines may run: the well's insets and its scroll bar and
-- the card's insets taken off the column. A title has all of it, a bullet all
-- but its mark's indent, the date all but the newest card's tag.
function MenuLayout.updateWidth(p: Panel): number
	local U = MenuLayout.Updates
	local main = MenuLayout.blocks(p).main
	return main.w - U.ListInset * 2 - U.ScrollBar - U.CardInset * 2
end

function MenuLayout.updateText(p: Panel): number
	return MenuLayout.updateWidth(p) - MenuLayout.Updates.BulletIndent
end

-- One card's height, for this many bullet LINES (one a bullet unless wrapped).
function MenuLayout.updateCardHeight(lines: number): number
	local U = MenuLayout.Updates
	return U.CardInset + U.DateH + U.TitleH + U.HeadGap + lines * U.BulletLine + U.CardInset
end

-- The cards' height in the well, for these line counts, newest first.
function MenuLayout.updatesContent(lines: { number }): number
	local U = MenuLayout.Updates
	local total = 0
	for i, n in ipairs(lines) do
		total += MenuLayout.updateCardHeight(n) + (if i > 1 then U.CardGap else 0)
	end
	return total
end

-- The details inside a block `w` x `h`, in the block's own coordinates.
function MenuLayout.eventDetail(w: number, h: number, subtitle: boolean): EventDetail
	local E = MenuLayout.Events
	local g = E.Gap
	local subH = if subtitle then E.SubtitleH else 0
	if w >= E.SideMinW then
		local lw = math.floor(w * E.SideShare)
		local room = h - g - E.BadgeH - g - E.WhenH
		local bh = math.max(0, math.min(math.floor(lw * 9 / 16), room))
		local bw = math.floor(bh * 16 / 9)
		local below = bh + (if bh > 0 then g else 0)
		local rx = lw + g * 2
		local rw = w - rx
		local aw = math.min(rw, E.ActionMaxW)
		local top = E.TitleH + subH + g
		return {
			side = true,
			banner = rect(math.floor((lw - bw) / 2), 0, bw, bh),
			badge = rect(0, below, lw, E.BadgeH),
			when = rect(0, below + E.BadgeH + g, lw, E.WhenH),
			title = rect(rx, 0, rw, E.TitleH),
			subtitle = if subtitle then rect(rx, E.TitleH, rw, E.SubtitleH) else nil,
			words = rect(rx, top, rw, math.max(0, h - E.ActionH - g - top)),
			action = rect(rx + math.floor((rw - aw) / 2), h - E.ActionH, aw, E.ActionH),
		}
	end
	-- Everything but the picture, and the least the words may have.
	local fixed = E.BadgeH + g + E.WhenH + g + E.TitleH + subH + g + g + E.ActionH
	local bh = math.min(math.floor(w * 9 / 16), math.floor(h * E.BannerShare))
	bh = math.max(0, math.min(bh, h - fixed - g - E.WordsMin))
	local bw = math.floor(bh * 16 / 9)
	local y = bh + (if bh > 0 then g else 0)
	local badge = rect(0, y, w, E.BadgeH)
	y += E.BadgeH + g
	local when = rect(0, y, w, E.WhenH)
	y += E.WhenH + g
	local title = rect(0, y, w, E.TitleH)
	y += E.TitleH
	local sub: Rect? = nil
	if subtitle then
		sub = rect(0, y, w, E.SubtitleH)
		y += E.SubtitleH
	end
	y += g
	local aw = math.min(w, E.ActionMaxW)
	return {
		side = false,
		banner = rect(math.floor((w - bw) / 2), 0, bw, bh),
		badge = badge,
		when = when,
		title = title,
		subtitle = sub,
		words = rect(0, y, w, math.max(0, h - E.ActionH - g - y)),
		action = rect(math.floor((w - aw) / 2), h - E.ActionH, aw, E.ActionH),
	}
end

--==============================================================================
-- THE INVITE PANEL (InviteUI, 2026-10-06): the Shop's and the Index's sibling
--
-- One page in the main column, over the studded baseplate: the HERO (the
-- form's picture on the left; its name, rarity, rate and the Unsellable tag
-- on the right), the PROGRESS bar and the NEXT line under it, the TRACK of
-- four cards joined by a road, the INVITE FRIENDS button and its one small
-- line. The first of these that fits the column:
--
--   STACKED      top to bottom, at full size: every desktop and TV, the panel
--                as tall as the page, up to MaxH.
--   DENSE        the same, at a short screen's sizes (a smaller hero, bar and
--                cards; the rarity and the rate on one line): a desktop window
--                too short for the full page (1000 x 609).
--   SIDE BY SIDE dense, where the column is at least SplitMinW wide -- a
--                landscape phone (705 x 338 leaves a 667 x 197 column): the
--                hero, the bar, the NEXT line and the button down the left of
--                it, the track in the rest, scrolling sideways where four
--                cards do not fit, and the button's line under both. The hero
--                and the button stay put; nothing scrolls up and down. The
--                left column is as wide as still lets the four cards stand
--                beside it whole.
--
-- Otherwise dense and stacked, and the page scrolls. The track's cards are as
-- wide as fit up to CardW, never under CardMinW (it scrolls sideways at
-- CardMinW rather than shrink them further); the gaps between them, where the
-- road shows, grow up to CardGapMax.
--
-- Every rect is in the page's own coordinates (0, 0 at the main column's top
-- left), the page's inset already inside them; the cards are in the track's
-- own canvas.
--==============================================================================
MenuLayout.Invite = {
	MaxW = 760,
	MaxH = 620,
	-- The page's margin inside the column (a vertical scroll bar, where one is
	-- needed, rides in the right one), and the gap between its blocks.
	InsetTall = 8,
	InsetShort = 6,
	GapTall = 8,
	GapShort = 6,
	HeroTall = 132,
	HeroShort = 64,
	NameTall = 38,
	NameShort = 24,
	LineTall = 24,
	LineShort = 18,
	-- Dense, the rarity word's room before the rate on the same line.
	DenseRarityW = 110,
	TagW = 104,
	TagTall = 22,
	TagShort = 16,
	BarTall = 32,
	BarShort = 22,
	BarGapTall = 4,
	BarGapShort = 3,
	NextTall = 22,
	NextShort = 16,
	CardW = 140,
	CardMinW = 108,
	CardTall = 176,
	CardShort = 144,
	CardGap = 10,
	CardGapMax = 36,
	RoadH = 8,
	ScrollBar = 6,
	ButtonTall = 52,
	-- The touch floor (Config.Touch): a finger's whole target.
	ButtonShort = 44,
	ButtonMaxW = 340,
	HowGapTall = 4,
	HowGapShort = 2,
	HowTall = 18,
	HowShort = 14,
	SplitMinW = 460,
	SplitShare = 0.42,
	SplitMin = 240,
	SplitMax = 330,
}

export type InviteBlocks = {
	-- Side by side (see above), or stacked; the dense sizes (a short
	-- screen's: the smaller hero, bar and cards) or the full ones.
	split: boolean,
	dense: boolean,
	picture: Rect,
	name: Rect,
	-- The rarity word; dense, the rate shares its line (`income` then starts
	-- a gap after the rarity's room ends).
	rarity: Rect,
	income: Rect,
	tag: Rect,
	bar: Rect,
	nextLine: Rect,
	-- The track's window in the page, the cards in its own canvas, the canvas's
	-- width, and whether it scrolls sideways (four cards wider than the window).
	track: Rect,
	cards: { Rect },
	trackCanvas: number,
	trackScrolls: boolean,
	road: Rect,
	button: Rect,
	how: Rect,
	-- The whole page's height (its canvas), insets included.
	height: number,
}

export type InviteCard = {
	preview: Rect,
	name: Rect,
	rarity: Rect,
	income: Rect,
	needs: Rect,
	-- The earned card's green tick (the preview's top right) and its CLAIMED
	-- pill (across the preview's foot).
	tick: Rect,
	claimed: Rect,
}

-- One card's insides, in the card's own coordinates, dense or full.
function MenuLayout.inviteCard(w: number, h: number, dense: boolean): InviteCard
	local pad = 5
	local nameH = if dense then 16 else 18
	local lineH = if dense then 13 else 15
	local needsH = if dense then 12 else 14
	local words = nameH + lineH * 2 + needsH
	local previewH = math.max(24, h - pad * 2 - words - 3)
	local inner = math.max(0, w - pad * 2)
	local y = pad + previewH + 3
	local tickS = if dense then 18 else 22
	local claimH = if dense then 16 else 18
	return {
		preview = rect(pad, pad, inner, previewH),
		name = rect(pad, y, inner, nameH),
		rarity = rect(pad, y + nameH, inner, lineH),
		income = rect(pad, y + nameH + lineH, inner, lineH),
		needs = rect(pad, y + nameH + lineH * 2, inner, needsH),
		tick = rect(w - pad - tickS - 3, pad + 3, tickS, tickS),
		claimed = rect(pad + 6, pad + previewH - claimH - 4, math.max(0, inner - 12), claimH),
	}
end

type Track = { cards: { Rect }, canvas: number, scrolls: boolean, road: Rect, h: number }

-- Four cards in a window `w` wide, `cardH` tall.
local function inviteTrack(w: number, cardH: number, dense: boolean): Track
	local I = MenuLayout.Invite
	local cardW = math.clamp(math.floor((w - I.CardGap * 3) / 4), I.CardMinW, I.CardW)
	local gap = math.clamp(math.floor((w - cardW * 4) / 3), I.CardGap, I.CardGapMax)
	local canvas = cardW * 4 + gap * 3
	local scrolls = canvas > w
	local offset = if scrolls then 0 else math.floor((w - canvas) / 2)
	local cards: { Rect } = {}
	for i = 1, 4 do
		cards[i] = rect(offset + (i - 1) * (cardW + gap), 0, cardW, cardH)
	end
	-- The road joins the cards' pictures, behind them: from the first card's
	-- middle to the last's, at the pictures' middle height.
	local picture = MenuLayout.inviteCard(cardW, cardH, dense).preview
	local mid = picture.y + math.floor(picture.h / 2)
	local road = rect(offset + math.floor(cardW / 2), mid - math.floor(I.RoadH / 2), canvas - cardW, I.RoadH)
	return {
		cards = cards,
		canvas = math.max(canvas, w),
		scrolls = scrolls,
		road = road,
		h = cardH + (if scrolls then I.ScrollBar + 2 else 0),
	}
end

type Hero = { picture: Rect, name: Rect, rarity: Rect, income: Rect, tag: Rect, h: number }

-- The hero at (x, y), `w` wide: the picture square, the words beside it,
-- centred on its height.
local function inviteHero(x: number, y: number, w: number, dense: boolean, g: number): Hero
	local I = MenuLayout.Invite
	local side = if dense then I.HeroShort else I.HeroTall
	local nameH = if dense then I.NameShort else I.NameTall
	local lineH = if dense then I.LineShort else I.LineTall
	local tagH = if dense then I.TagShort else I.TagTall
	local tx = x + side + g * 2
	local tw = math.max(0, x + w - tx)
	-- A dense hero: the rarity and the rate on one line.
	local lines = if dense then 1 else 2
	local words = nameH + lineH * lines + 4 + tagH
	local h = math.max(side, words)
	local ty = y + math.max(0, math.floor((h - words) / 2))
	local name = rect(tx, ty, tw, nameH)
	local rarity, income
	if dense then
		-- The rate a gap after the rarity's room: a word that fills its room
		-- ran straight into the rate ("LEGENDARY$25K/s", a phone, 2026-10-06).
		local rw = math.min(math.floor(tw * 0.45), I.DenseRarityW)
		rarity = rect(tx, ty + nameH, rw, lineH)
		income = rect(tx + rw + g, ty + nameH, math.max(0, tw - rw - g), lineH)
	else
		rarity = rect(tx, ty + nameH, tw, lineH)
		income = rect(tx, ty + nameH + lineH, tw, lineH)
	end
	local tag = rect(tx, ty + nameH + lineH * lines + 4, math.min(I.TagW, tw), tagH)
	return { picture = rect(x, y + math.floor((h - side) / 2), side, side), name = name, rarity = rarity,
		income = income, tag = tag, h = h }
end

-- One arrangement of the page in a column `columnW` x `columnH`: dense or
-- full, stacked or side by side.
local function arrange(columnW: number, columnH: number, dense: boolean, split: boolean): InviteBlocks
	local I = MenuLayout.Invite
	local inset = if dense then I.InsetShort else I.InsetTall
	local g = if dense then I.GapShort else I.GapTall
	local barH = if dense then I.BarShort else I.BarTall
	local barGap = if dense then I.BarGapShort else I.BarGapTall
	local nextH = if dense then I.NextShort else I.NextTall
	local cardH = if dense then I.CardShort else I.CardTall
	local buttonH = if dense then I.ButtonShort else I.ButtonTall
	local howGap = if dense then I.HowGapShort else I.HowGapTall
	local howH = if dense then I.HowShort else I.HowTall
	local w = math.max(0, columnW - inset * 2)

	-- One column of blocks `width` wide at `x`: hero, bar, NEXT, the track
	-- (stacked only), the button, its line. Answers them and the column's height.
	local function stack(x: number, width: number, withTrack: boolean)
		local y = inset
		local hero = inviteHero(x, y, width, dense, g)
		y += hero.h + g
		local bar = rect(x, y, width, barH)
		y += barH + barGap
		local nextLine = rect(x, y, width, nextH)
		y += nextH + g
		local track: Track? = nil
		local trackAt = y
		if withTrack then
			local t = inviteTrack(width, cardH, dense)
			track = t
			y += t.h + g
		end
		local bw = math.min(I.ButtonMaxW, width)
		local button = rect(x + math.floor((width - bw) / 2), y, bw, buttonH)
		y += buttonH + howGap
		local how = rect(x, y, width, howH)
		y += howH + inset
		return hero, bar, nextLine, track, trackAt, button, how, y
	end

	local hero, bar, nextLine, track, trackAt, button, how, height = stack(inset, w, not split)
	local trackRect: Rect
	local t: Track
	if split then
		-- The left column as wide as still lets the four cards stand beside it
		-- whole; where they cannot fit even beside the narrowest, its share.
		local need = I.CardMinW * 4 + I.CardGap * 3
		local leftW = if w - I.SplitMin - g * 2 >= need
			then math.clamp(w - g * 2 - need, I.SplitMin, I.SplitMax)
			else math.clamp(math.floor(w * I.SplitShare), I.SplitMin, I.SplitMax)
		local rightX = inset + leftW + g * 2
		local rightW = math.max(0, w - leftW - g * 2)
		local leftHero, leftBar, leftNext, _, _, leftButton, leftHow, leftH = stack(inset, leftW, false)
		hero, bar, nextLine, button = leftHero, leftBar, leftNext, leftButton
		-- The button's line runs the page's whole width under it: in the left
		-- column alone it would shrink past readable on a phone.
		how = rect(inset, leftHow.y, w, leftHow.h)
		-- The cards take the right column down to the line, up to their own
		-- height, the track centred there.
		local room = math.max(0, how.y - g - inset)
		local probe = inviteTrack(rightW, cardH, dense)
		local below = if probe.scrolls then I.ScrollBar + 2 else 0
		t = inviteTrack(rightW, math.clamp(room - below, 0, cardH), dense)
		local top = inset + math.max(0, math.floor((room - t.h) / 2))
		trackRect = rect(rightX, top, rightW, t.h)
		height = leftH
	else
		t = track :: Track
		trackRect = rect(inset, trackAt, w, t.h)
	end
	return {
		split = split,
		dense = dense,
		picture = hero.picture,
		name = hero.name,
		rarity = hero.rarity,
		income = hero.income,
		tag = hero.tag,
		bar = bar,
		nextLine = nextLine,
		track = trackRect,
		cards = t.cards,
		trackCanvas = t.canvas,
		trackScrolls = t.scrolls,
		road = t.road,
		button = button,
		how = how,
		height = height,
	}
end

-- The page inside a main column `columnW` x `columnH` on a short screen or a
-- tall one: stacked at its own sizes where that fits; else stacked dense;
-- else side by side, dense, where the column is wide enough; else stacked
-- dense, the page scrolling.
function MenuLayout.inviteBlocks(columnW: number, columnH: number, short: boolean): InviteBlocks
	local own = arrange(columnW, columnH, short, false)
	if own.height <= columnH then
		return own
	end
	local dense = if short then own else arrange(columnW, columnH, true, false)
	if dense.height <= columnH then
		return dense
	end
	if columnW >= MenuLayout.Invite.SplitMinW then
		return arrange(columnW, columnH, true, true)
	end
	return dense
end

-- The page in a panel `p`.
function MenuLayout.invitePage(p: Panel): InviteBlocks
	local main = MenuLayout.blocks(p).main
	return MenuLayout.inviteBlocks(main.w, main.h, p.short)
end

-- The panel: no sidebar; on a desktop as tall as its page, up to MaxH; on a
-- short screen the safe area's height, the page side by side inside it.
function MenuLayout.invitePanel(s: Screen, outline: number): Panel
	local I = MenuLayout.Invite
	local p = MenuLayout.panel(s, I.MaxW, I.MaxH, outline)
	p.sidebar = false
	-- A phone's panel takes the whole height, as the Shop's and the Index's do.
	if p.short then
		return p
	end
	for _ = 1, 3 do
		local main = MenuLayout.blocks(p).main
		local spare = main.h - MenuLayout.inviteBlocks(main.w, main.h, p.short).height
		if spare < 1 then
			break
		end
		local q = MenuLayout.panel(s, I.MaxW, p.rect.h - math.floor(spare), outline)
		q.sidebar = false
		-- Never into the short sizes by shrinking: a tall panel keeps its tall page.
		if q.short ~= p.short then
			break
		end
		p = q
	end
	return p
end

--==============================================================================
-- THE INVITE REWARD POPUP (InviteRewardUI, 2026-10-06)
--
-- One card, drawn at its base size and scaled whole (UIScale) to the largest
-- size that fits clear of everything in `avoid` -- the HUD's groups and badges,
-- the thumbs, the belt's bands, the toast line, the top row -- by Gap: centred
-- on the screen's middle, as high as it can stand, never wider than WidthShare
-- of the screen (a phone's -- `phone` -- may take what the HUD leaves) nor
-- larger than MaxScale. Two shapes, the same blocks: TALL, the picture over the words
-- (a desktop's), and WIDE, the picture beside them -- a landscape phone's room
-- is a short band over the toast line, where the tall card would be too small
-- to read. Whichever draws larger is the answer. Never modal and never the
-- whole screen. Answers its rect, its scale and its shape, or an empty rect
-- where even MinScale finds no room.
--==============================================================================
MenuLayout.Popup = {
	Tall = Vector2.new(360, 330),
	Wide = Vector2.new(500, 176),
	WidthShare = 0.4,
	MaxScale = 1.6,
	MinScale = 0.5,
	Gap = 8,
	Step = 0.02,
}

export type PopupShape = "tall" | "wide"

export type PopupBlocks = {
	size: Vector2,
	-- The words' alignment: centred under the tall card's picture, from the
	-- left beside the wide card's.
	centred: boolean,
	-- NEW FORM UNLOCKED! (FINAL FORM!) across the top.
	ribbon: Rect,
	-- The rays' plate and, on it, the form's window.
	stage: Rect,
	view: Rect,
	name: Rect,
	-- The rarity word's pill and the rate beside it.
	pill: Rect,
	income: Rect,
	-- "Invite reward: 5 friends - Unsellable".
	line: Rect,
	-- PLACE IT and LATER (its emptying ring inside, at the left).
	place: Rect,
	later: Rect,
	ring: Rect,
}

-- A card's insides at its base size, every one inside the card.
function MenuLayout.popupBlocks(shape: PopupShape?): PopupBlocks
	local P = MenuLayout.Popup
	if shape == "wide" then
		local later = rect(366, 114, 126, 56)
		return {
			size = P.Wide,
			centred = false,
			ribbon = rect(20, 4, 460, 28),
			stage = rect(8, 34, 152, 136),
			view = rect(16, 36, 136, 132),
			name = rect(170, 38, 322, 28),
			pill = rect(170, 70, 120, 20),
			income = rect(298, 70, 194, 20),
			line = rect(170, 94, 322, 16),
			place = rect(170, 114, 190, 56),
			later = later,
			ring = rect(later.x + 10, later.y + 17, 22, 22),
		}
	end
	local later = rect(220, 266, 116, 56)
	return {
		size = P.Tall,
		centred = true,
		ribbon = rect(30, 8, 300, 36),
		stage = rect(90, 48, 180, 132),
		view = rect(114, 48, 132, 132),
		name = rect(16, 184, 328, 30),
		pill = rect(40, 218, 130, 22),
		income = rect(180, 218, 140, 22),
		line = rect(16, 244, 328, 16),
		place = rect(24, 266, 186, 56),
		later = later,
		ring = rect(later.x + 10, later.y + 17, 22, 22),
	}
end

-- The largest card of one size that fits: its rect and scale, or an empty rect.
local function fitPopup(safe: Vector2, avoid: { Rect }, base: Vector2, phone: boolean): (Rect, number)
	local P = MenuLayout.Popup
	local sw, sh = safe.X, safe.Y
	-- A phone is narrow: the share would make it tiny, so it may take what the
	-- HUD leaves (the search below keeps it clear), up to the screen's width.
	local largest = math.min(P.MaxScale, (if phone then sw - P.Gap * 2 else sw * P.WidthShare) / base.X)
	local function clear(r: Rect): boolean
		if r.x < P.Gap or r.y < P.Gap or r.x + r.w > sw - P.Gap or r.y + r.h > sh - P.Gap then
			return false
		end
		for _, a in ipairs(avoid) do
			if a.w > 0 and a.h > 0 and r.x < a.x + a.w + P.Gap and a.x < r.x + r.w + P.Gap
				and r.y < a.y + a.h + P.Gap and a.y < r.y + r.h + P.Gap then
				return false
			end
		end
		return true
	end
	local scale = largest
	while scale >= P.MinScale do
		local w, h = math.floor(base.X * scale), math.floor(base.Y * scale)
		local x = math.floor(sw / 2 - w / 2)
		-- As high as it can stand.
		local y = P.Gap
		while y + h <= sh - P.Gap do
			local r = rect(x, y, w, h)
			if clear(r) then
				return r, w / base.X
			end
			y += 4
		end
		scale -= P.Step
	end
	return rect(0, 0, 0, 0), 0
end

function MenuLayout.rewardPopup(safe: Vector2, avoid: { Rect }, phone: boolean?): (Rect, number, PopupShape)
	local P = MenuLayout.Popup
	local tall, tallScale = fitPopup(safe, avoid, P.Tall, phone == true)
	local wide, wideScale = fitPopup(safe, avoid, P.Wide, phone == true)
	if wideScale > tallScale + 1e-6 then
		return wide, wideScale, "wide"
	end
	return tall, tallScale, "tall"
end

return MenuLayout
