--!strict
-- Steal a Seed :: HudLayout
--
-- Where every permanent HUD group sits, worked out from the screen the player
-- actually has rather than from the one it was drawn on.
--
--==============================================================================
-- WHY THIS IS ONE MODULE AND NOTHING BUT NUMBERS
--
-- The HUD has ten owners and none of them owns the others:
--
--   IndexUI, ShopUI, SettingsUI, WalkModeUI    the left rail
--   RailDrawerUI                               on a phone, the dock the first
--                                              three stand in, and its handle
--   GardenUI, LoadoutUI                        Garden and the Bag, the BAT/TRAP
--                                              column (and its chooser) and the
--                                              hotbar
--   CashUI                                     cash, speed and the x2 card
--   WorldClock                                 the clock
--   TutorialUI, BiomeGuideUI                   the two that come and go
--
-- They have to agree to the pixel without talking to each other, so each asks
-- this module the same question with the same facts -- how big the safe area
-- is, whether the screen is touch, whether there is a keyboard -- and applies
-- ITS OWN part of the answer to ITS OWN instances. Nothing here builds, finds,
-- moves or keeps an instance, and nothing here runs on a clock: an owner asks
-- again when its ScreenGui's AbsoluteSize changes, which is the viewport, the
-- inset and the notch all at once. Same pattern as ReachPoint, for the same
-- reason, and it is what lets HudLayoutSpec drive every branch without Play.
--
--==============================================================================
-- WHAT STARTED IT, 2026-09-18, THE OWNER'S EMULATED 801 x 392 PHONE
--
--   cash block and hotbar              overlapping by 68 px
--   WALK MODE and the cash block       overlapping by 10 px
--   the thumbstick's resting ring      drawn over the cash block
--   the jump button                    under the BAT/TRAP column
--   the left rail                      64% of the safe height
--
-- Every one of those is the desktop layout, unchanged, on a screen a third of
-- the size with two thumbs' worth of Roblox controls on it.
--
--==============================================================================
-- THREE LAYOUTS, AND THE DESKTOP ONE IS WHAT ALREADY SHIPPED
--
-- DESKTOP is the old geometry to the pixel -- the same numbers the owners used
-- to write inline, now read from here. It is used when the screen is not touch
-- AND the desktop arrangement actually fits: nothing overlapping and every gap
-- at least 8 px. The one thing that can move on a desktop is the cash block,
-- which rises above the hotbar when a narrow window leaves no room beside it --
-- on a window 1268 px or wider it never does.
--
-- COMPACT is a window the desktop arrangement does not fit and that has no
-- touch screen: a desktop window dragged small. Decided by the safe size, never
-- by a device name.
--
-- SIDEBARS is every TOUCH screen -- a phone, a tablet, the emulator -- and is
-- the approved mobile redesign of 2026-09-23 (THE PHONE'S SIDEBARS, below). A
-- narrow window is never a phone: only TouchEnabled makes one.
--
--   top left      Index, Shop, Settings, Walk Mode: one row of 50 x 50 buttons
--   top right     Garden and the Bag: one row, the Bag in the corner
--   right edge    BAT over TRAP, standing on the jump button's reservation
--   bottom        the hotbar, five slots, centred between the two thumbs
--   bottom left   cash and speed, above the thumbstick and the hotbar line
--
-- The hotbar and the cash block also change FACE in compact and in sidebars: a
-- smaller belt (GameConfig.Hotbar.Compact, read through hotMetrics) and a
-- smaller cash block (CASH_COMPACT). Every answer carries its mode's numbers as
-- `hot` and `cashStyle`, so the two owners draw from the same answer that
-- placed them.
--
-- Five slots in compact and sidebars, ten on a desktop with a keyboard. The
-- count changes only when the MODE does, so resizing or rotating a phone never
-- takes a slot away from anybody.
--
--==============================================================================
-- THE ROBLOX CONTROLS ARE MODELLED, NOT MEASURED LIVE
--
-- The PlayerModule's own formulas, for the safe area the TouchGui shares with
-- every HUD layer. Both stick modes are reserved at once -- the player picks
-- one in the Roblox menu, and a layout that moved when they did would be a
-- layout that could be wrong for a frame.
--
--   small screen (shorter side <= 500)
--     DynamicThumbstick ring     29, h - 93, 74 x 74
--     classic Thumbstick         25, h - 90, 70 x 70
--     jump                       w - 95, h - 90, 70 x 70
--   large screen
--     DynamicThumbstick ring     58, h - 186, 148 x 148
--     classic Thumbstick         60, h - 210, 120 x 120
--     jump                       w - 170, h - 210, 120 x 120
--
-- Reserved whenever the screen is touch, whether or not the controls are
-- showing this instant: they appear the moment a thumb lands, and a HUD that
-- waited for them would jump under the thumb.
--==============================================================================

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local RAIL = GameConfig.Rail
local HOT = GameConfig.Hotbar

local HudLayout = {}

export type Rect = { x: number, y: number, w: number, h: number }

export type Input = {
	-- AbsoluteSize of a HUD ScreenGui with IgnoreGuiInset = false: below the
	-- topbar and inside the notch. Every owner has one.
	safe: Vector2,
	touch: boolean,
	keyboard: boolean,
	-- CashUI's own measurement, when it is wider than the reservation.
	cashWidth: number?,
	-- The clock's three: the whole window, the topbar's free span in window
	-- coordinates (GuiService.TopbarInset), and how far the safe area starts
	-- below the top of the window.
	viewport: Vector2?,
	topbar: Rect?,
	insetTop: number?,
}

export type Layout = {
	compact: boolean,
	slots: number,
	safe: Vector2,
	touch: boolean,
	-- False when some permanent group could not be placed clear of the others.
	-- Every listed phone and desktop fits; HudLayoutSpec says so.
	fits: boolean,

	index: Rect,
	shop: Rect,
	settings: Rect,
	walk: Rect,
	garden: Rect,
	bag: Rect,
	-- The two top groups' band, for the things that have to step round them.
	railTop: number,
	railBottom: number,
	railRight: number,
	rightLeft: number,

	equipment: Rect,
	equipSlot: number,
	equipGap: number,

	-- The strip at its widest: every live slot and the Bag cell.
	hotbar: Rect,
	chip: boolean,

	-- The cash block as a group (its reserved width), and its root frame.
	cash: Rect,
	cashRoot: Rect,

	thumb: Rect?,
	jump: Rect?,

	-- The tutorial's instruction banner and the skip line under it.
	banner: Rect,
	skip: Rect,

	-- WINDOW space, unlike everything above.
	clock: Rect?,

	-- The hotbar card's numbers for this mode: GameConfig.Hotbar itself on a
	-- desktop, the same table with its Compact block laid over it in compact.
	-- LoadoutUI draws the strip from this and nothing else. See hotMetrics.
	hot: any,
	-- The cash block's face for this mode; see CONFIG.CashStyle.
	cashStyle: CashStyle,

	-- THE PHONE'S SIDEBARS (see below). False, and the five rects nil, on a
	-- desktop and in compact, whose answers are exactly what they were.
	sidebar: boolean,
	-- The dock Index, Shop and Settings stand in; `index`, `shop` and `settings`
	-- are its three tiles.
	dock: Rect?,
	-- The dock's handle as the square a press lands on: on the dock's edge while
	-- it is open, on the safe area's edge while it is shut.
	handle: Rect?,
	handleShut: Rect?,
	-- The x2 card, as a button on the top-right row.
	boost: Rect?,
	-- The BATS / TRAPS chooser at its widest. Its right edge is fixed; a player
	-- with fewer items gets a narrower one, still inside this.
	chooser: Rect?,
	-- The right sidebar's padding round its two tiles; 0 for the old column.
	equipPad: number,
}

--==============================================================================
-- THE CASH BLOCK'S TWO FACES
--
-- Desktop is CashUI's shipped numbers, moved here unchanged so the spec can
-- hold them to the pixel and so there is one copy: the 316 x 108 root, speed at
-- 39 and cash at 47 in LuckiestGuy, the 50 x 38 shoe, the 46-px x2 card 10 px
-- off the text.
--
-- COMPACT, asked for by the owner 2026-09-22 on a landscape phone: the block was
-- competing with the rail and covering a corner of the world. The same shoe,
-- numbers, colours and x2 card, smaller and closer together -- cash at 35 and
-- speed at 27, the shoe at 0.64, a 36-px card inside a 44-px touch area, thinner
-- outlines, and 2 px between the two lines instead of 13. Reserved by the
-- widest balance the formatter can print, "$9.99Qa": 129 px at 35, the card
-- 8 px after it and 36 wide, and its touch area 4 px past that -- 177, kept
-- as 180. The touch area reaches 4 px past the card on every side, which is
-- what `Drop` covers below the root.
--==============================================================================
export type CashStyle = {
	-- The root frame: the block's own size, anchored at its bottom-left.
	Root: Vector2,
	-- The width HudLayout places the block by, so a longer balance never moves it.
	Reserve: number,
	-- How far below the root the group reaches: the x2 card, or its touch area.
	Drop: number,
	SpeedSize: number,
	CashSize: number,
	-- The speed line's box: its left edge (after the shoe), width and bottom.
	SpeedX: number,
	SpeedW: number,
	SpeedBottom: number,
	CashW: number,
	SpeedStroke: number,
	CashStroke: number,
	-- The shoe is drawn at 50 x 38 and scaled; its bottom edge in the root.
	ShoeScale: number,
	ShoeBottom: number,
	-- The x2 card as drawn, the touch area around it, its gap off the cash text,
	-- its leftmost place while the text is still a dash, and its hang.
	BuffSize: number,
	BuffHit: number,
	BuffGap: number,
	BuffMinX: number,
	BuffDrop: number,
	-- The card's message line, and how far above the root's bottom edge it ends.
	TipSize: number,
	TipLift: number,
	BuffCorner: number,
}

local CASH_DESKTOP: CashStyle = {
	-- The widest the block can be: "$9.99Qa" is 174 px of 47-px LuckiestGuy, the
	-- x2 card starts 10 px after it and is 46 wide, which is 230. A realistic
	-- "$9.99M" is 205. Measured with TextService 2026-09-18.
	Root = Vector2.new(316, 108),
	Reserve = 232,
	-- The x2 card hangs 2 px under the root.
	Drop = 2,
	SpeedSize = 39,
	CashSize = 47,
	SpeedX = 56,
	SpeedW = 260,
	SpeedBottom = 44,
	CashW = 300,
	SpeedStroke = 2,
	CashStroke = 3,
	ShoeScale = 1,
	ShoeBottom = 44,
	BuffSize = GameConfig.Pass.BuffSize or 46,
	BuffHit = GameConfig.Pass.BuffSize or 46,
	BuffGap = 10,
	BuffMinX = 120,
	BuffDrop = 2,
	TipSize = 15,
	-- The card's height and 4 px, less its 2-px hang: the line sits just above it.
	TipLift = 48,
	BuffCorner = 10,
}

local CASH_COMPACT: CashStyle = {
	-- Speed's box (31) over cash's (39) with 2 px between them; 36 in from the
	-- shoe, like the desktop's 56 is from its larger one.
	Root = Vector2.new(190, 72),
	Reserve = 180,
	-- The touch area's 4 px past the card's 2-px hang.
	Drop = 6,
	SpeedSize = 27,
	CashSize = 35,
	SpeedX = 36,
	SpeedW = 154,
	SpeedBottom = 31,
	CashW = 190,
	SpeedStroke = 1.5,
	CashStroke = 2,
	-- 32 x 24: the 50 x 38 shoe at 0.64, its foot level with the speed line's.
	ShoeScale = 0.64,
	ShoeBottom = 29,
	BuffSize = 36,
	BuffHit = 44,
	BuffGap = 8,
	BuffMinX = 90,
	BuffDrop = 2,
	TipSize = 13,
	-- Above the whole block, 2 px over the speed line: between the two lines,
	-- where the desktop puts it, there is no room at this size.
	TipLift = 74,
	BuffCorner = 8,
}

local CONFIG = {
	-- Compact keeps every group this far inside the safe area, and this far
	-- from every other group.
	Margin = 8,
	Gap = 8,
	-- Ten 64-px slots need the width; below it a desktop window is compact.
	DesktopMinWidth = 900,
	DesktopSlots = 10,
	MobileSlots = 5,
	WalkHeight = 46,
	-- The cash block's two faces (see THE CASH BLOCK'S TWO FACES), and the
	-- desktop one's three placing numbers under the names they always had.
	CashStyle = { Desktop = CASH_DESKTOP, Compact = CASH_COMPACT },
	CashReserve = CASH_DESKTOP.Reserve,
	CashRoot = CASH_DESKTOP.Root,
	CashDrop = CASH_DESKTOP.Drop,
	-- The root's left edge in both modes. The cash line's 3 px outline draws
	-- outside it, so 12 is what keeps the "$" 9 px off the safe edge -- measured
	-- live at 5 px when compact used the plain 8 px margin.
	CashLeft = RAIL.Inset,
	EquipWidth = 64,
	EquipSlot = 68,
	EquipGap = 8,
	EquipTightGap = 6,
	EquipMinSlot = 52,
	BannerSize = Vector2.new(560, 84),
	BannerTop = 84,
	SkipSize = Vector2.new(150, 20),
	ClockTop = 8,
	ClockHeight = 34,
	ClockScale = 0.44,
	ClockMin = 190,
	ClockMax = 360,
	-- The narrowest the clock is allowed to get before it gives up being
	-- exactly centred rather than get any smaller.
	ClockFloor = 170,
	SmallScreen = 500,
	-- How far a compact badge hangs past its button's corner. The rail's 6 px
	-- gap minus the badge's 2.5 px stroke leaves this much before it would
	-- touch the next button.
	BadgeHang = 2,
	--==========================================================================
	-- THE PHONE'S SIDEBARS
	--
	-- The dock's tiles are 50 x 50 like every rail square, the icon over a
	-- 10-px word, and give up height to 44 -- the touch floor -- only on a
	-- screen too short for three. The handle is drawn 18 x 34 on the dock's
	-- edge and pressed on a 44 x 44 square that reaches right from it, never
	-- back over a tile. BATS and TRAPS are 56 x 60, because the equipped
	-- item's model needs the room a book icon does not, and give up height to
	-- 48 on a short phone, never width. The chooser shows three 76 x 96 cards
	-- at most and scrolls past that.
	--==========================================================================
	Dock = {
		Tile = Vector2.new(50, 50),
		MinTile = 44,
		Pad = 4,
		Gap = 5,
		Icon = 28,
		Label = 10,
		Handle = Vector2.new(18, 34),
		Hit = 44,
	},
	Side = {
		Tile = Vector2.new(56, 60),
		MinTile = 48,
		Pad = 4,
		Gap = 6,
	},
	Chooser = {
		Card = Vector2.new(76, 96),
		Cards = 3,
		Gap = 6,
		Pad = 8,
		Title = 20,
		-- The strip down its right edge, toward the sidebar, carrying the
		-- chevron that closes it.
		Spine = 22,
	},
	-- Between the x2 button and Garden: room for Garden's tucked badge.
	BoostGap = 8,
	--==========================================================================
	-- THE BAG PANEL
	--
	-- LoadoutUI's own numbers, moved here so the arithmetic that places the
	-- panel can be driven by a spec at every screen size. LoadoutUI reads them
	-- back from here; there is one copy.
	--==========================================================================
	Bag = {
		EdgeGap = 8,
		MaxW = 780,
		MaxH = 600,
		MinW = 240,
		MinH = 160,
		-- A shell shorter than this puts the tabs on the title's row.
		CompactBelow = 380,
		-- Where the body starts inside the shell, and what the header and the
		-- bottom margin take from its height, with the tabs on the title's row
		-- and on their own row.
		BodyTopCompact = 58,
		BodyTop = 100,
		BodyTrimCompact = 70,
		BodyTrim = 112,
		-- The desktop card and the compact one. Compact is 8 px wider and 12
		-- taller: a name box every shipped name fits in two lines of 14 pt, and
		-- an action button that is the whole 44 px strip rather than a 24 px
		-- pill inside it.
		Card = Vector2.new(104, 158),
		CardCompact = Vector2.new(112, 170),
		CardGap = 10,
		GridPad = 10,
		-- The grid's own UIPadding: left/right, top/bottom.
		PadX = 10,
		PadY = 8,
		ActionH = 44,
		InfoGap = 10,
		InfoSideMin = 184,
		InfoSideMax = 236,
		InfoSheetH = 118,
	},
}
HudLayout.Config = CONFIG

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = x, y = y, w = w, h = h }
end
HudLayout.rect = rect

function HudLayout.union(a: Rect, b: Rect): Rect
	local x0, y0 = math.min(a.x, b.x), math.min(a.y, b.y)
	local x1 = math.max(a.x + a.w, b.x + b.w)
	local y1 = math.max(a.y + a.h, b.y + b.h)
	return rect(x0, y0, x1 - x0, y1 - y0)
end

-- How far apart two rects are along whichever axis separates them. Negative
-- when they overlap -- by how much, on the axis that overlaps least.
function HudLayout.gap(a: Rect, b: Rect): number
	local dx = math.max(b.x - (a.x + a.w), a.x - (b.x + b.w))
	local dy = math.max(b.y - (a.y + a.h), a.y - (b.y + b.h))
	return math.max(dx, dy)
end

local function sharesRows(a: Rect, b: Rect, gap: number): boolean
	return a.y < b.y + b.h + gap and b.y < a.y + a.h + gap
end

--==============================================================================
-- A RECT AS A POSITION, MEASURED FROM THE EDGE ITS ANCHOR IS ON
--
-- A button anchored to the right edge stays measured from the right edge, so a
-- window that resizes between two relayouts never throws it off the screen.
-- The desktop answers come out as exactly the UDim2s the owners used to write:
-- the hotbar is (0.5, 0, 1, -10), the Garden button (1, -12, 0, 12).
--==============================================================================
function HudLayout.place(r: Rect, anchor: Vector2, safe: Vector2): UDim2
	local px = r.x + r.w * anchor.X
	local py = r.y + r.h * anchor.Y
	return UDim2.new(anchor.X, math.round(px - safe.X * anchor.X),
		anchor.Y, math.round(py - safe.Y * anchor.Y))
end

--==============================================================================
-- THE HOTBAR'S NUMBERS IN EACH MODE
--
-- GameConfig.Hotbar is the desktop card, and its Compact block names only what
-- the compact belt changes. Laid over a copy once, so a reader always gets ONE
-- table with every key -- the colours too -- and a desktop gets the original
-- itself, which is what keeps its strip the one that shipped.
--==============================================================================
local compactHot: any = nil

function HudLayout.hotMetrics(compact: boolean?): any
	if not compact then
		return HOT
	end
	if not compactHot then
		local merged: any = table.clone(HOT)
		for key, value in pairs(HOT.Compact :: any) do
			merged[key] = value
		end
		compactHot = merged
	end
	return compactHot
end

function HudLayout.hotbarWidth(slots: number, chip: boolean, compact: boolean?): number
	local H = HudLayout.hotMetrics(compact)
	local width = H.TrayPad * 2 + slots * H.SlotWidth + (slots - 1) * H.Gap
	if chip then
		-- The list's padding either side of the BagGap spacer, then the cell.
		width += H.Gap + H.BagGap + H.Gap + H.ChipWidth
	end
	return width
end

function HudLayout.hotbarHeight(compact: boolean?): number
	local H = HudLayout.hotMetrics(compact)
	return H.SlotHeight + H.TrayPad * 2
end

-- The thumbstick (both modes, as one zone) and the jump button.
function HudLayout.touchZones(safe: Vector2): (Rect, Rect)
	local w, h = safe.X, safe.Y
	if math.min(w, h) <= CONFIG.SmallScreen then
		return rect(25, h - 93, 78, 74), rect(w - 95, h - 90, 70, 70)
	end
	return rect(58, h - 210, 148, 172), rect(w - 170, h - 210, 120, 120)
end

--==============================================================================
-- THE CLOCK, IN WINDOW SPACE
--
-- Centred, 34 tall, 44% of the window between 190 and 360 -- as it always was
-- -- and then no wider than the topbar's free span allows while staying
-- centred, 8 px clear of the Roblox buttons on both sides. Only a very narrow
-- window ever makes that bite; below 170 px it stops shrinking and slides the
-- least it can instead.
--
-- The rows are a second limit only when the topbar is too short to hold the
-- clock, which no current Roblox topbar is -- but a clock that could land on
-- the Index button because a topbar changed height is not one to ship.
--==============================================================================
local function clockRect(input: Input, L: Layout): Rect?
	local viewport = input.viewport
	if not viewport then
		return nil
	end
	local vx = viewport.X
	local centre = vx / 2
	local width = math.clamp(vx * CONFIG.ClockScale, CONFIG.ClockMin, CONFIG.ClockMax)
	local lo, hi = -math.huge, math.huge
	local bar = input.topbar
	if bar and bar.w > 0 then
		lo, hi = bar.x + CONFIG.Margin, bar.x + bar.w - CONFIG.Margin
	end
	local insetTop = input.insetTop or 0
	if CONFIG.ClockTop + CONFIG.ClockHeight + CONFIG.Gap > insetTop + L.railTop then
		local originX = (vx - L.safe.X) / 2
		lo = math.max(lo, originX + L.railRight + CONFIG.Gap)
		hi = math.min(hi, originX + L.rightLeft - CONFIG.Gap)
	end
	if lo > -math.huge or hi < math.huge then
		local half = math.min(centre - lo, hi - centre)
		if half * 2 < width then
			width = math.max(0, half * 2)
			if width < CONFIG.ClockFloor then
				width = math.max(0, math.min(CONFIG.ClockFloor, hi - lo))
				centre = math.clamp(centre, lo + width / 2, math.max(lo + width / 2, hi - width / 2))
			end
		end
	end
	return rect(centre - width / 2, CONFIG.ClockTop, width, CONFIG.ClockHeight)
end

--==============================================================================
-- DESKTOP: THE GEOMETRY THAT SHIPPED
--==============================================================================
local function desktop(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local I, G = RAIL.Inset, CONFIG.Gap
	local wide, square = RAIL.WideSize, RAIL.SquareSize
	local row = wide.Y + RAIL.Gap

	local index = rect(I, I, wide.X, wide.Y)
	local shop = rect(I, I + row, wide.X, wide.Y)
	local settings = rect(I, I + row * 2, square.X, square.Y)
	local walk = rect(I, I + row * 3, wide.X, CONFIG.WalkHeight)
	local garden = rect(sw - I - square.X, I, square.X, square.Y)
	local bag = rect(sw - I - square.X, I + square.Y + RAIL.Gap, square.X, square.Y)
	local equipment = rect(sw - I - CONFIG.EquipWidth, I + (square.Y + RAIL.Gap) * 2 + 6,
		CONFIG.EquipWidth, CONFIG.EquipSlot * 2 + CONFIG.EquipGap)

	local slots = if input.keyboard then CONFIG.DesktopSlots else CONFIG.MobileSlots
	local chip = sw >= HOT.ChipMinViewport
	local width = HudLayout.hotbarWidth(slots, chip)
	local height = HudLayout.hotbarHeight()
	local hotbar = rect(sw / 2 - width / 2, sh - HOT.BottomGap - height, width, height)

	-- Beside the hotbar where the whole reservation fits; above it where not.
	local style = CASH_DESKTOP
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	local cx = CONFIG.CashLeft
	local rootBottom = sh - HOT.BottomGap
	if cx + cw + G > hotbar.x then
		rootBottom = hotbar.y - G - style.Drop
	end
	local cashRoot = rect(cx, rootBottom - style.Root.Y, style.Root.X, style.Root.Y)
	local cash = rect(cx, cashRoot.y, cw, style.Root.Y + style.Drop)

	local banner = rect(sw / 2 - CONFIG.BannerSize.X / 2, CONFIG.BannerTop,
		CONFIG.BannerSize.X, CONFIG.BannerSize.Y)
	local skip = rect(sw / 2 - CONFIG.SkipSize.X / 2, CONFIG.BannerTop + CONFIG.BannerSize.Y,
		CONFIG.SkipSize.X, CONFIG.SkipSize.Y)

	local L: Layout = {
		compact = false,
		slots = slots,
		safe = input.safe,
		touch = input.touch,
		fits = true,
		index = index,
		shop = shop,
		settings = settings,
		walk = walk,
		garden = garden,
		bag = bag,
		railTop = I,
		railBottom = walk.y + walk.h,
		railRight = I + wide.X,
		rightLeft = garden.x,
		equipment = equipment,
		equipSlot = CONFIG.EquipSlot,
		equipGap = CONFIG.EquipGap,
		hotbar = hotbar,
		chip = chip,
		cash = cash,
		cashRoot = cashRoot,
		thumb = nil,
		jump = nil,
		banner = banner,
		skip = skip,
		clock = nil,
		hot = HOT,
		cashStyle = style,
		sidebar = false,
		dock = nil,
		handle = nil,
		handleShut = nil,
		boost = nil,
		chooser = nil,
		equipPad = 0,
	}
	L.clock = clockRect(input, L)
	return L
end

--==============================================================================
-- THE HOTBAR: CENTRED BETWEEN THE THUMBS
--
-- At the bottom edge, centred on the screen unless that puts it within 8 px
-- of the stick or the jump button, in which case it slides the least it
-- has to. It is the compact belt (GameConfig.Hotbar.Compact): five slots
-- and the Bag cell are 355 x 84, where the desktop's cards made 419 x 104.
-- Where even that will not go between the two controls the cell is
-- dropped, and where five bare slots will not either the strip is lifted
-- clear of both. Compact and sidebars place it the same way.
--==============================================================================
local function beltBetween(input: Input, thumb: Rect?, jump: Rect?): (Rect, boolean, boolean)
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local slots = CONFIG.MobileSlots
	local height = HudLayout.hotbarHeight(true)
	local bottom = sh - HOT.BottomGap
	local lo, hi = M, sw - M
	if thumb and jump then
		lo, hi = thumb.x + thumb.w + G, jump.x - G
	end
	local chip = true
	local width = HudLayout.hotbarWidth(slots, true, true)
	if width > hi - lo then
		chip = false
		width = HudLayout.hotbarWidth(slots, false, true)
	end
	if width > hi - lo and thumb and jump then
		bottom = math.min(thumb.y, jump.y) - G
		lo, hi = M, sw - M
		chip = HudLayout.hotbarWidth(slots, true, true) <= hi - lo
		width = HudLayout.hotbarWidth(slots, chip, true)
	end
	local centre = sw / 2
	local fits = true
	if width <= hi - lo then
		centre = math.clamp(centre, lo + width / 2, hi - width / 2)
	else
		fits = false
	end
	return rect(centre - width / 2, bottom - height, width, height), chip, fits
end

--==============================================================================
-- THE TUTORIAL BANNER: UNDER THE ROWS, BETWEEN WHATEVER SHARES ITS BAND
--
-- 560 wide where it can be, narrower where the cash block or the BAT/TRAP
-- column stands in its band, and slid off centre rather than squeezed
-- symmetrically -- the words are what it is for, and TutorialUI scales
-- them down only when the banner is narrower than they are.
--==============================================================================
local function bannerIn(sw: number, railBottom: number, beside: { Rect }): (Rect, Rect)
	local M, G = CONFIG.Margin, CONFIG.Gap
	local bannerHeight = CONFIG.BannerSize.Y + CONFIG.SkipSize.Y
	local band = rect(0, railBottom + G, sw, bannerHeight)
	local blo, bhi = M, sw - M
	for _, other in ipairs(beside) do
		if sharesRows(band, other, G) then
			if other.x + other.w / 2 < sw / 2 then
				blo = math.max(blo, other.x + other.w + G)
			else
				bhi = math.min(bhi, other.x - G)
			end
		end
	end
	local bannerWidth = math.max(CONFIG.SkipSize.X, math.min(CONFIG.BannerSize.X, bhi - blo))
	local bannerCentre = sw / 2
	if bannerWidth <= bhi - blo then
		bannerCentre = math.clamp(bannerCentre, blo + bannerWidth / 2, bhi - bannerWidth / 2)
	end
	local banner = rect(bannerCentre - bannerWidth / 2, band.y, bannerWidth, CONFIG.BannerSize.Y)
	local skip = rect(bannerCentre - CONFIG.SkipSize.X / 2, band.y + CONFIG.BannerSize.Y,
		CONFIG.SkipSize.X, CONFIG.SkipSize.Y)
	return banner, skip
end

--==============================================================================
-- COMPACT
--==============================================================================
local function compact(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local B, g = RAIL.SquareSize.X, RAIL.Gap
	local fits = true

	--==========================================================================
	-- THE TWO TOP ROWS
	--
	-- Four 50 x 50 buttons across the top left, in the order they used to run
	-- down it, at the rail's own 6 px gap -- 226 px of width and 50 of height
	-- where the column took 214 of height. Garden and the Bag mirror them top
	-- right, the Bag in the corner so BAT and TRAP still stand under it.
	--==========================================================================
	local function cell(i: number): Rect
		return rect(M + (i - 1) * (B + g), M, B, B)
	end
	local index, shop, settings, walk = cell(1), cell(2), cell(3), cell(4)
	local bag = rect(sw - M - B, M, B, B)
	local garden = rect(bag.x - g - B, M, B, B)
	local railBottom = M + B

	local thumb: Rect?, jump: Rect? = nil, nil
	if input.touch then
		thumb, jump = HudLayout.touchZones(input.safe)
	end

	-- THE HOTBAR: see beltBetween.
	local slots = CONFIG.MobileSlots
	local hotbar, chip, stripFits = beltBetween(input, thumb, jump)
	if not stripFits then
		fits = false
	end

	--==========================================================================
	-- BAT AND TRAP: LOWER RIGHT, STANDING ON THE JUMP BUTTON
	--
	-- Against the right edge, 8 px above the jump reservation -- which keeps
	-- the band between the hotbar and the jump button empty for the right
	-- thumb's camera drag -- and 8 px under the top row. Where that band is
	-- short the two slots lose a few pixels of height, never below 52, and
	-- never their width.
	--==========================================================================
	local ex = sw - M - CONFIG.EquipWidth
	local top = railBottom + G
	local floor = if jump then jump.y - G else sh - HOT.BottomGap
	if hotbar.x + hotbar.w + G > ex then
		floor = math.min(floor, hotbar.y - G)
	end
	local room = floor - top
	local equipGap = if room >= CONFIG.EquipSlot * 2 + CONFIG.EquipGap
		then CONFIG.EquipGap
		else CONFIG.EquipTightGap
	local equipSlot = math.min(CONFIG.EquipSlot, math.floor((room - equipGap) / 2))
	if equipSlot < CONFIG.EquipMinSlot then
		fits = false
		equipSlot = CONFIG.EquipMinSlot
	end
	local stack = equipSlot * 2 + equipGap
	local equipment = rect(ex, floor - stack, CONFIG.EquipWidth, stack)

	--==========================================================================
	-- CASH AND SPEED: BOTTOM LEFT, ABOVE EVERYTHING THAT IS ALSO BOTTOM LEFT
	--
	-- In its compact face (CASH_COMPACT), 190 x 72 where the desktop's is
	-- 316 x 108 -- and then it moves, it never shrinks any further. On touch it
	-- stands above the thumbstick and, where it would meet the hotbar, above
	-- the hotbar's top line too; decided from the reservation rather than the
	-- number on it, so it does not hop when a balance gets a digit longer.
	-- Without a touch screen it keeps the desktop's bottom line whenever the
	-- reservation fits beside the strip. `limit` is the GROUP's bottom -- the
	-- x2 card's touch area -- which is 6 px under the root.
	--==========================================================================
	local style = CASH_COMPACT
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	local ch = style.Root.Y + style.Drop
	local cx = CONFIG.CashLeft
	local limit = sh - HOT.BottomGap + CONFIG.CashDrop
	if thumb then
		limit = math.min(limit, thumb.y - G)
	end
	if hotbar.x < cx + cw + G then
		limit = math.min(limit, hotbar.y - G)
	end
	local cash = rect(cx, limit - ch, cw, ch)
	if cash.y < railBottom + G then
		fits = false
	end
	local cashRoot = rect(cx, limit - style.Drop - style.Root.Y, style.Root.X, style.Root.Y)

	-- THE TUTORIAL BANNER: see bannerIn.
	local beside: { Rect } = { cash, equipment }
	if thumb then
		table.insert(beside, thumb)
	end
	if jump then
		table.insert(beside, jump)
	end
	local banner, skip = bannerIn(sw, railBottom, beside)

	local L: Layout = {
		compact = true,
		slots = slots,
		safe = input.safe,
		touch = input.touch,
		fits = fits,
		index = index,
		shop = shop,
		settings = settings,
		walk = walk,
		garden = garden,
		bag = bag,
		railTop = M,
		railBottom = railBottom,
		railRight = walk.x + walk.w,
		rightLeft = garden.x,
		equipment = equipment,
		equipSlot = equipSlot,
		equipGap = equipGap,
		hotbar = hotbar,
		chip = chip,
		cash = cash,
		cashRoot = cashRoot,
		thumb = thumb,
		jump = jump,
		banner = banner,
		skip = skip,
		clock = nil,
		hot = HudLayout.hotMetrics(true),
		cashStyle = style,
		sidebar = false,
		dock = nil,
		handle = nil,
		handleShut = nil,
		boost = nil,
		chooser = nil,
		equipPad = 0,
	}
	L.clock = clockRect(input, L)
	L.fits = L.fits and #HudLayout.problems(L) == 0
	return L
end

--==============================================================================
-- THE PHONE'S SIDEBARS
--
-- The owner's approved mockup, 2026-09-23 (Steal an Artifact/output/imagegen/
-- podnappers-mobile-sidebar-mockup-v2.png), on any TOUCH screen:
--
--   left edge     THE DOCK: Index, Shop and Settings as tiles, the icon over
--                 its word, in one slim panel with a handle on its edge that
--                 shuts it. Reserved open or shut, so shutting it moves nothing
--                 else; RailDrawerUI hides it while a centre panel is open.
--   beside it     Walk Mode, the compact 50 x 50 switch, on the top row.
--   top right     the x2 card as a button, then Garden, the Bag in the corner.
--   right edge    BATS over TRAPS in a panel that matches the dock, standing
--                 on the jump button's reservation as the old column did. Each
--                 opens THE CHOOSER leftward, toward the middle and no further.
--   bottom        the belt, five slots, pods and plants only: the weapons live
--                 on the right sidebar now.
--   bottom left   cash and speed in the compact face, under the dock where the
--                 screen is tall enough and beside it where it is not -- on a
--                 phone under ~350 px of safe height the dock, a 78-px block
--                 and the thumbstick's reservation cannot share one column.
--==============================================================================
local function sidebars(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local B, g = RAIL.SquareSize.X, RAIL.Gap
	local D, S, C = CONFIG.Dock, CONFIG.Side, CONFIG.Chooser
	local fits = true
	local thumb, jump = HudLayout.touchZones(input.safe)

	--==========================================================================
	-- THE DOCK, AND WHAT STANDS BESIDE IT
	--
	-- Three tiles, 8 px clear of the thumbstick's reservation; on a screen too
	-- short for 50-px tiles they give up height, never below the touch floor.
	-- The handle's press reaches right from the dock's edge, level with the
	-- Shop tile. Walk Mode and a cash block beside the dock stand clear of
	-- Index's badge, which hangs a few pixels past the dock's edge.
	--==========================================================================
	local tileW = D.Tile.X
	local tileH = math.min(D.Tile.Y,
		math.floor((thumb.y - G - M - D.Pad * 2 - D.Gap * 2) / 3))
	if tileH < D.MinTile then
		fits = false
		tileH = D.MinTile
	end
	local dock = rect(M, M, tileW + D.Pad * 2, tileH * 3 + D.Gap * 2 + D.Pad * 2)
	local function tile(i: number): Rect
		return rect(dock.x + D.Pad, dock.y + D.Pad + (i - 1) * (tileH + D.Gap), tileW, tileH)
	end
	local index, shop, settings = tile(1), tile(2), tile(3)
	local handleY = math.floor(shop.y + shop.h / 2 - D.Hit / 2)
	local handle = rect(dock.x + dock.w, handleY, D.Hit, D.Hit)
	local handleShut = rect(0, handleY, D.Hit, D.Hit)
	local badgeReach = index.x + index.w + CONFIG.BadgeHang + 2.5
	local dockRight = math.ceil(math.max(dock.x + dock.w, badgeReach))
	local walk = rect(dockRight + G, M, B, B)

	--==========================================================================
	-- THE TOP-RIGHT ROW: x2, GARDEN, THE BAG IN THE CORNER
	--==========================================================================
	local bag = rect(sw - M - B, M, B, B)
	local garden = rect(bag.x - g - B, M, B, B)
	local boost = rect(garden.x - CONFIG.BoostGap - B, M, B, B)
	local railBottom = M + B

	-- THE BELT: see beltBetween.
	local hotbar, chip, stripFits = beltBetween(input, thumb, jump)
	if not stripFits then
		fits = false
	end

	--==========================================================================
	-- BATS OVER TRAPS
	--
	-- The old column's rule -- against the right edge, 8 px above the jump
	-- reservation and 8 px under the top row -- with the panel's padding round
	-- two 56 x 60 tiles. Short of room, the tiles lose height, never below 48.
	--==========================================================================
	local panelW = S.Tile.X + S.Pad * 2
	local ex = sw - M - panelW
	local top = railBottom + G
	local floor = jump.y - G
	if hotbar.x + hotbar.w + G > ex then
		floor = math.min(floor, hotbar.y - G)
	end
	local equipSlot = math.min(S.Tile.Y, math.floor((floor - top - S.Pad * 2 - S.Gap) / 2))
	if equipSlot < S.MinTile then
		fits = false
		equipSlot = S.MinTile
	end
	local stack = equipSlot * 2 + S.Gap + S.Pad * 2
	local equipment = rect(ex, floor - stack, panelW, stack)

	--==========================================================================
	-- THE CHOOSER, AT ITS WIDEST
	--
	-- Out of the sidebar's left side, 8 px off it, and never past the middle of
	-- the screen, where the player's own character stands. As tall as a title
	-- and one row of cards; level with the sidebar where it can be, lifted clear
	-- of the belt and the jump button where it cannot, and never over the top
	-- row. Wider than its cards need only on paper: LoadoutUI draws it the width
	-- of what the player owns, from the same right edge.
	--==========================================================================
	local chooserH = C.Pad * 2 + C.Title + C.Card.Y
	local chooserRight = equipment.x - G
	local chooserW = C.Pad + C.Cards * C.Card.X + (C.Cards - 1) * C.Gap + C.Spine
	chooserW = math.min(chooserW, chooserRight - (sw / 2 + G))
	local oneCard = C.Pad + C.Card.X + C.Spine
	if chooserW < oneCard then
		fits = false
		chooserW = oneCard
	end
	local chooserX = chooserRight - chooserW
	local lowest = sh - M
	for _, other in ipairs({ hotbar, jump, thumb }) do
		if other.x < chooserRight + G and other.x + other.w + G > chooserX then
			lowest = math.min(lowest, other.y - G)
		end
	end
	local chooserY = math.floor(equipment.y + equipment.h / 2 - chooserH / 2)
	chooserY = math.clamp(chooserY, top, math.max(top, lowest - chooserH))
	if chooserY + chooserH > lowest then
		fits = false
	end
	local chooser = rect(chooserX, chooserY, chooserW, chooserH)

	--==========================================================================
	-- CASH AND SPEED: UNDER THE DOCK, OR BESIDE IT
	--
	-- The compact face, and compact's rule for its bottom line: above the
	-- thumbstick, and above the belt wherever the two would share columns. At
	-- the left edge when that leaves it 8 px under the dock; otherwise beside
	-- the dock, 8 px clear of its handle. It carries no x2 card here -- that is
	-- the button on the top row -- so it has nothing a thumb can press.
	--==========================================================================
	local style = CASH_COMPACT
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	local ch = style.Root.Y + style.Drop
	local function bottomLine(cx: number): number
		local limit = math.min(sh - HOT.BottomGap + CONFIG.CashDrop, thumb.y - G)
		if hotbar.x < cx + cw + G and hotbar.x + hotbar.w + G > cx then
			limit = math.min(limit, hotbar.y - G)
		end
		return limit
	end
	local cx = CONFIG.CashLeft
	local limit = bottomLine(cx)
	if limit - ch < dock.y + dock.h + G then
		cx = dockRight + G
		limit = bottomLine(cx)
		if limit - ch < math.max(walk.y + walk.h, handle.y + handle.h) + G then
			fits = false
		end
	end
	local cash = rect(cx, limit - ch, cw, ch)
	local cashRoot = rect(cx, limit - style.Drop - style.Root.Y, style.Root.X, style.Root.Y)

	-- THE TUTORIAL BANNER: see bannerIn. The dock and its handle stand in its
	-- band too, open or shut.
	local banner, skip = bannerIn(sw, railBottom, { cash, equipment, thumb, jump, dock, handle })

	local L: Layout = {
		compact = true,
		slots = CONFIG.MobileSlots,
		safe = input.safe,
		touch = input.touch,
		fits = fits,
		index = index,
		shop = shop,
		settings = settings,
		walk = walk,
		garden = garden,
		bag = bag,
		railTop = M,
		railBottom = railBottom,
		railRight = walk.x + walk.w,
		rightLeft = boost.x,
		equipment = equipment,
		equipSlot = equipSlot,
		equipGap = S.Gap,
		hotbar = hotbar,
		chip = chip,
		cash = cash,
		cashRoot = cashRoot,
		thumb = thumb,
		jump = jump,
		banner = banner,
		skip = skip,
		clock = nil,
		hot = HudLayout.hotMetrics(true),
		cashStyle = style,
		sidebar = true,
		dock = dock,
		handle = handle,
		handleShut = handleShut,
		boost = boost,
		chooser = chooser,
		equipPad = S.Pad,
	}
	L.clock = clockRect(input, L)
	L.fits = L.fits and #HudLayout.problems(L) == 0
	return L
end

--==============================================================================
-- THE PERMANENT GROUPS, AND WHAT IS WRONG WITH A LAYOUT
--
-- The two badges are part of their groups when gaps are measured, where they
-- are drawn in that mode: half off the corner on a desktop, tucked into it in
-- compact. The 8 px margin is measured to the buttons; a compact badge only has
-- to stay on the glass, and does, 3.5 px in.
--
-- A desktop badge still hangs 3.5 px up into the topbar band, as it always
-- has. It is drawn there, not clipped, and the desktop is left as it was.
--==============================================================================
export type Group = { name: string, rect: Rect }

function HudLayout.badges(L: Layout): (Rect, Rect)
	local stroke = 2.5
	local size = 26 + stroke * 2
	if L.compact then
		local hang = CONFIG.BadgeHang + stroke
		return rect(L.index.x + L.index.w + hang - size, L.index.y - hang, size, size),
			rect(L.garden.x - hang, L.garden.y - hang, size, size)
	end
	return rect(L.index.x + L.index.w - size / 2, L.index.y - size / 2, size, size),
		rect(L.garden.x - size / 2, L.garden.y - size / 2, size, size)
end

function HudLayout.groups(L: Layout, withBadges: boolean?): { Group }
	--==========================================================================
	-- ON A PHONE, "rail" IS THE TOP-LEFT ROW THAT STAYS: WALK MODE
	--
	-- The dock is its own group, and its handle another -- a bounding box round
	-- the two would swallow Walk Mode, which stands beside the dock and above
	-- the handle. The x2 button joins Garden and the Bag in their row.
	--==========================================================================
	local dock, handle, boost = L.dock, L.handle, L.boost
	if L.sidebar and dock and handle and boost then
		local right = HudLayout.union(HudLayout.union(boost, L.garden), L.bag)
		if withBadges then
			local indexBadge, gardenBadge = HudLayout.badges(L)
			dock = HudLayout.union(dock, indexBadge)
			right = HudLayout.union(right, gardenBadge)
		end
		return {
			{ name = "rail", rect = L.walk },
			{ name = "dock", rect = dock },
			{ name = "handle", rect = handle },
			{ name = "garden+bag", rect = right },
			{ name = "equipment", rect = L.equipment },
			{ name = "hotbar", rect = L.hotbar },
			{ name = "cash", rect = L.cash },
		}
	end
	local rail = HudLayout.union(HudLayout.union(L.index, L.shop),
		HudLayout.union(L.settings, L.walk))
	local right = HudLayout.union(L.garden, L.bag)
	if withBadges and L.compact then
		local indexBadge, gardenBadge = HudLayout.badges(L)
		rail = HudLayout.union(rail, indexBadge)
		right = HudLayout.union(right, gardenBadge)
	end
	local list: { Group } = {
		{ name = "rail", rect = rail },
		{ name = "garden+bag", rect = right },
		{ name = "equipment", rect = L.equipment },
		{ name = "hotbar", rect = L.hotbar },
		{ name = "cash", rect = L.cash },
	}
	return list
end

function HudLayout.problems(L: Layout): { string }
	local found: { string } = {}
	local sw, sh = L.safe.X, L.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	for _, group in ipairs(HudLayout.groups(L)) do
		local r = group.rect
		if r.x < M or r.y < M or r.x + r.w > sw - M or r.y + r.h > sh - M then
			table.insert(found, group.name .. " is not inside the safe area's margin")
		end
	end
	if L.compact then
		local indexBadge, gardenBadge = HudLayout.badges(L)
		for _, badge in ipairs({ indexBadge, gardenBadge }) do
			if badge.x < 0 or badge.y < 0 or badge.x + badge.w > sw or badge.y + badge.h > sh then
				table.insert(found, "a badge leaves the safe area")
			end
		end
	end
	local groups = HudLayout.groups(L, true)
	for i = 1, #groups do
		for j = i + 1, #groups do
			-- The handle is ON the dock's edge; those two are meant to touch.
			local pair = groups[i].name .. "/" .. groups[j].name
			local apart = HudLayout.gap(groups[i].rect, groups[j].rect)
			if apart < G and pair ~= "dock/handle" then
				table.insert(found, string.format("%s and %s are %.1f px apart",
					groups[i].name, groups[j].name, apart))
			end
		end
	end
	--==========================================================================
	-- THE TWO THINGS THAT ARE NOT ALWAYS THERE
	--
	-- The chooser, open, has to clear every group and both thumbs as if it
	-- were one, and stay inside the margin. The shut handle stands where the
	-- dock was, so it only has to clear the rest, and may sit on the safe
	-- area's own edge -- it is a tab pulled out of it.
	--==========================================================================
	local transient: { Group } = {}
	if L.chooser then
		table.insert(transient, { name = "chooser", rect = L.chooser })
	end
	if L.handleShut then
		table.insert(transient, { name = "shut handle", rect = L.handleShut })
	end
	for _, extra in ipairs(transient) do
		local r = extra.rect
		local edge = if extra.name == "chooser" then M else 0
		if r.x < edge or r.y < M or r.x + r.w > sw - M or r.y + r.h > sh - M then
			table.insert(found, extra.name .. " is not inside the safe area's margin")
		end
		for _, group in ipairs(groups) do
			local exempt = extra.name == "shut handle"
				and (group.name == "dock" or group.name == "handle")
			local apart = HudLayout.gap(r, group.rect)
			if apart < G and not exempt then
				table.insert(found, string.format("%s and %s are %.1f px apart",
					extra.name, group.name, apart))
			end
		end
		for _, zone in ipairs({ L.thumb, L.jump }) do
			if zone and HudLayout.gap(r, zone) < G then
				table.insert(found, extra.name .. " is within 8 px of a touch control")
			end
		end
	end
	local zones: { Rect } = {}
	if L.thumb then
		table.insert(zones, L.thumb)
	end
	if L.jump then
		table.insert(zones, L.jump)
	end
	for _, zone in ipairs(zones) do
		for _, group in ipairs(groups) do
			local apart = HudLayout.gap(zone, group.rect)
			if apart < G then
				table.insert(found, string.format("%s is %.1f px from a touch control",
					group.name, apart))
			end
		end
	end
	return found
end

--==============================================================================
-- THE ANSWER
--==============================================================================
function HudLayout.solve(input: Input): Layout
	if input.touch then
		return sidebars(input)
	end
	if input.safe.X >= CONFIG.DesktopMinWidth then
		local L = desktop(input)
		if #HudLayout.problems(L) == 0 then
			return L
		end
	end
	return compact(input)
end

--==============================================================================
-- THE BIOME NOTICE: OFFSET FROM THE MIDDLE, AND WHICH ROW TO SIT IN
--
-- A word 30 px tall at the very top of the window, which on a 58-px topbar is
-- 8 px above the safe area and 22 into it -- level with both top groups. It
-- stays centred wherever it clears them by 8 px, slides between them where it
-- only fits off centre, and drops under them where it fits neither.
--
-- `top` is in safe space. Returns the x offset from the middle and the top to
-- use, also in safe space.
--==============================================================================
function HudLayout.notice(L: Layout, width: number, height: number, top: number): (number, number)
	local G = CONFIG.Gap
	if top + height + G <= L.railTop or top >= L.railBottom + G then
		return 0, top
	end
	local centre = L.safe.X / 2
	-- Measured to the badges as well as the buttons: Garden's hangs 4.5 px
	-- off its left corner in compact, toward the middle.
	local indexBadge, gardenBadge = HudLayout.badges(L)
	local lo = math.max(L.railRight, indexBadge.x + indexBadge.w) + G
	local hi = math.min(L.rightLeft, gardenBadge.x) - G
	if width / 2 <= math.min(centre - lo, hi - centre) then
		return 0, top
	end
	if width <= hi - lo then
		return (lo + hi) / 2 - centre, top
	end
	return 0, L.railBottom + G
end

--==============================================================================
-- THE BAG PANEL
--
-- The desktop branch is LoadoutUI's layoutBag arithmetic, moved here unchanged:
-- the panel fits between the rails and above the hotbar, centred on the screen
-- when that still leaves a real panel.
--
-- COMPACT, measured 2026-09-18 on the owner's emulated 801 x 392 phone: the
-- panel stopped above the strip, so after its header the grid was 128 px tall
-- -- and a card row is 158 + 16. No card could ever be shown whole: at the top
-- of the scroll its action button was cut off by the tray's bottom edge, and
-- scrolled to reach it, its preview went up under the header. So on a phone:
--
--   * the strip is hidden while the Bag is open (touch only), and the panel
--     runs down to the safe area's bottom edge instead of stopping above it;
--   * the grid scrolls SIDEWAYS, in as many whole rows as fit -- never a part
--     row, so nothing is ever clipped at the top or the bottom;
--   * a card is the compact 112 x 170, with a full 44 px action button.
--
-- `stripHidden` is the first of those: LoadoutUI passes `layout.touch`, and
-- hides the strip on exactly the same condition.
--==============================================================================
export type BagInput = {
	-- The strip's top edge in safe space, from its own Position and Size.
	hotTop: number,
	stripHidden: boolean,
	-- The Plants tab, which has the information column beside or under the grid.
	plants: boolean,
	-- The BAT/TRAP frame's width, which the desktop panel stops short of.
	sideWidth: number,
}

export type Bag = {
	panel: Rect,
	-- The group is centre-anchored; this is the offset LoadoutUI writes.
	centre: Vector2,
	compactHeader: boolean,
	body: Rect,
	tray: Rect,
	-- "none", "side", "compact" (a short side column) or "sheet".
	info: string,
	infoRect: Rect?,
	horizontal: boolean,
	-- Whole rows of cards in a sideways grid; 0 for the desktop's vertical one.
	rows: number,
	card: Vector2,
}

function HudLayout.bag(L: Layout, input: BagInput): Bag
	local B = CONFIG.Bag
	local sw, sh = L.safe.X, L.safe.Y
	local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
	local leftEdge = RAIL.Inset + RAIL.WideSize.X + B.EdgeGap
	local rightEdge = sw - RAIL.Inset - input.sideWidth - B.EdgeGap
	local top = B.EdgeGap
	local bottom = input.hotTop - B.EdgeGap
	if L.compact then
		-- The compact rail is two short rows, not two columns: the panel takes
		-- the width up to BAT/TRAP, and the rows stand over its top corners,
		-- which UIKit.modal's header pads its title and close button clear of.
		leftEdge = B.EdgeGap
		rightEdge = L.equipment.x - B.EdgeGap
		if input.stripHidden then
			bottom = sh - B.EdgeGap
		end
	elseif rightEdge - leftEdge < 420 then
		leftEdge = B.EdgeGap
		top = railBottom + B.EdgeGap
	end

	local height = math.max(B.MinH, math.min(B.MaxH, bottom - top))
	local half = sw * 0.5
	local symmetric = 2 * math.min(half - leftEdge, rightEdge - half)
	local width, centreX
	if symmetric >= 600 or symmetric >= rightEdge - leftEdge - 40 then
		width = math.max(B.MinW, math.min(B.MaxW, symmetric))
		centreX = half
	else
		width = math.max(B.MinW, math.min(B.MaxW, rightEdge - leftEdge))
		centreX = (leftEdge + rightEdge) * 0.5
	end
	local centreY = top + (bottom - top) * 0.5
	local centre = Vector2.new(math.floor(centreX), math.floor(centreY))
	width, height = math.floor(width), math.floor(height)
	if L.compact then
		-- Centred on the exact half, so a panel of odd height still starts ON
		-- the 8 px margin rather than half a pixel inside it. The desktop keeps
		-- the floor it always had.
		centre = Vector2.new(centre.X, top + height / 2)
	end
	local panel = rect(centre.X - width / 2, centre.Y - height / 2, width, height)

	local outline = RAIL.OutlineThickness
	local shellW, shellH = width - outline * 2, height - outline * 2
	local compactHeader = shellH < B.CompactBelow
	local bodyTop = if compactHeader then B.BodyTopCompact else B.BodyTop
	local bodyW = shellW - 24
	local bodyH = shellH - (if compactHeader then B.BodyTrimCompact else B.BodyTrim)
	local body = rect(panel.x + outline + 12, panel.y + outline + bodyTop, bodyW, bodyH)

	local card = if L.compact then B.CardCompact else B.Card
	local twoColumns = card.X * 2 + B.CardGap + B.GridPad * 2
	local tray, info, infoRect = body, "none", nil
	if not input.plants then
		tray = body
	elseif bodyW >= twoColumns + B.InfoGap + B.InfoSideMin then
		local infoW = math.clamp(math.floor(bodyW * 0.34), B.InfoSideMin, B.InfoSideMax)
		tray = rect(body.x, body.y, bodyW - infoW - B.InfoGap, bodyH)
		infoRect = rect(body.x + bodyW - infoW, body.y, infoW, bodyH)
		info = if bodyH < 240 then "compact" else "side"
	else
		tray = rect(body.x, body.y, bodyW, bodyH - B.InfoSheetH - B.InfoGap)
		infoRect = rect(body.x, body.y + bodyH - B.InfoSheetH, bodyW, B.InfoSheetH)
		info = "sheet"
	end

	local rows = 0
	if L.compact then
		rows = math.max(1, math.floor((tray.h - B.PadY * 2 + B.CardGap) / (card.Y + B.CardGap)))
	end

	return {
		panel = panel,
		centre = centre,
		compactHeader = compactHeader,
		body = body,
		tray = tray,
		info = info,
		infoRect = infoRect,
		horizontal = L.compact,
		rows = rows,
		card = card,
	}
end

--==============================================================================
-- THE THREE FACTS, READ
--
-- Reading is not placing: this touches no instance but the one it is handed,
-- and only to read its size. `gui` is any HUD ScreenGui; one that ignores the
-- inset has the topbar taken off its height, which is the whole difference
-- between the two spaces on every screen Roblox draws today.
--==============================================================================
function HudLayout.measure(gui: ScreenGui, cashWidth: number?): Input
	local UserInputService = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")
	local camera = workspace.CurrentCamera
	local insetTop = GuiService:GetGuiInset().Y
	local size = gui.AbsoluteSize
	if gui.IgnoreGuiInset then
		size = Vector2.new(size.X, math.max(0, size.Y - insetTop))
	end
	local bar = GuiService.TopbarInset
	return {
		safe = size,
		touch = UserInputService.TouchEnabled,
		keyboard = UserInputService.KeyboardEnabled,
		cashWidth = cashWidth,
		viewport = if camera then camera.ViewportSize else nil,
		topbar = rect(bar.Min.X, bar.Min.Y, bar.Width, bar.Height),
		insetTop = insetTop,
	}
end

return HudLayout
