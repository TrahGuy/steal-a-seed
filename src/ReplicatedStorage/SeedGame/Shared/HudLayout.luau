--!strict
-- Steal a Seed :: HudLayout
--
-- Where every permanent HUD group sits, worked out from the screen the player
-- actually has rather than from the one it was drawn on.
--
--==============================================================================
-- WHY THIS IS ONE MODULE AND NOTHING BUT NUMBERS
--
-- The HUD has nine owners and none of them owns the others:
--
--   IndexUI, ShopUI, SettingsUI, WalkModeUI    the left rail
--   GardenUI, LoadoutUI                        Garden and the Bag, the BAT/TRAP
--                                              column and the hotbar
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
-- TWO LAYOUTS, AND THE DESKTOP ONE IS WHAT ALREADY SHIPPED
--
-- DESKTOP is the old geometry to the pixel -- the same numbers the owners used
-- to write inline, now read from here. It is used when the screen is not touch
-- AND the desktop arrangement actually fits: nothing overlapping and every gap
-- at least 8 px. The one thing that can move on a desktop is the cash block,
-- which rises above the hotbar when a narrow window leaves no room beside it --
-- on a window 1268 px or wider it never does.
--
-- COMPACT is everything else: any touch screen, and any window the desktop
-- arrangement does not fit. Decided by the safe size and by touch, never by a
-- device name, so a phone, a tablet, the emulator and a desktop window dragged
-- small all get the same rules.
--
--   top left      Index, Shop, Settings, Walk Mode: one row of 50 x 50 buttons
--   top right     Garden and the Bag: one row, the Bag in the corner
--   right edge    BAT over TRAP, standing on the jump button's reservation
--   bottom        the hotbar, five slots, centred between the two thumbs
--   bottom left   cash and speed, above the thumbstick and the hotbar line
--
-- Five slots in compact, ten on a desktop with a keyboard. The count changes
-- only when the MODE does, so resizing or rotating a phone never takes a slot
-- away from anybody.
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
	-- The widest the cash block can be: "$9.99Qa" is 174 px of 47-px
	-- LuckiestGuy, the x2 card starts 10 px after it and is 46 wide, which is
	-- 230. A realistic "$9.99M" is 205. Measured with TextService 2026-09-18.
	CashReserve = 232,
	CashRoot = Vector2.new(316, 108),
	-- The x2 card hangs 2 px under the root.
	CashDrop = 2,
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

function HudLayout.hotbarWidth(slots: number, chip: boolean): number
	local width = HOT.TrayPad * 2 + slots * HOT.SlotWidth + (slots - 1) * HOT.Gap
	if chip then
		-- The list's padding either side of the BagGap spacer, then the cell.
		width += HOT.Gap + HOT.BagGap + HOT.Gap + HOT.ChipWidth
	end
	return width
end

function HudLayout.hotbarHeight(): number
	return HOT.SlotHeight + HOT.TrayPad * 2
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
	local cw = math.max(CONFIG.CashReserve, input.cashWidth or 0)
	local cx = CONFIG.CashLeft
	local rootBottom = sh - HOT.BottomGap
	if cx + cw + G > hotbar.x then
		rootBottom = hotbar.y - G - CONFIG.CashDrop
	end
	local cashRoot = rect(cx, rootBottom - CONFIG.CashRoot.Y, CONFIG.CashRoot.X, CONFIG.CashRoot.Y)
	local cash = rect(cx, cashRoot.y, cw, CONFIG.CashRoot.Y + CONFIG.CashDrop)

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
	}
	L.clock = clockRect(input, L)
	return L
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

	--==========================================================================
	-- THE HOTBAR: CENTRED BETWEEN THE THUMBS
	--
	-- At the bottom edge, centred on the screen unless that puts it within 8 px
	-- of the stick or the jump button, in which case it slides the least it
	-- has to. Five slots and the Bag cell are 419 px; where even that will not
	-- go between the two controls the cell is dropped, and where five bare
	-- slots will not either the strip is lifted clear of both.
	--==========================================================================
	local slots = CONFIG.MobileSlots
	local height = HudLayout.hotbarHeight()
	local bottom = sh - HOT.BottomGap
	local lo, hi = M, sw - M
	if thumb and jump then
		lo, hi = thumb.x + thumb.w + G, jump.x - G
	end
	local chip = true
	local width = HudLayout.hotbarWidth(slots, true)
	if width > hi - lo then
		chip = false
		width = HudLayout.hotbarWidth(slots, false)
	end
	if width > hi - lo and thumb and jump then
		bottom = math.min(thumb.y, jump.y) - G
		lo, hi = M, sw - M
		chip = HudLayout.hotbarWidth(slots, true) <= hi - lo
		width = HudLayout.hotbarWidth(slots, chip)
	end
	local centre = sw / 2
	if width <= hi - lo then
		centre = math.clamp(centre, lo + width / 2, hi - width / 2)
	else
		fits = false
	end
	local hotbar = rect(centre - width / 2, bottom - height, width, height)

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
	-- At full size, always -- the block moves, it never shrinks. On touch it
	-- stands above the thumbstick and, where it would meet the hotbar, above
	-- the hotbar's top line too; decided from the reservation rather than the
	-- number on it, so it does not hop when a balance gets a digit longer.
	-- Without a touch screen it keeps its desktop corner whenever the
	-- reservation fits beside the strip.
	--==========================================================================
	local cw = math.max(CONFIG.CashReserve, input.cashWidth or 0)
	local ch = CONFIG.CashRoot.Y + CONFIG.CashDrop
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
	local cashRoot = rect(cx, limit - CONFIG.CashDrop - CONFIG.CashRoot.Y,
		CONFIG.CashRoot.X, CONFIG.CashRoot.Y)

	--==========================================================================
	-- THE TUTORIAL BANNER: UNDER THE ROWS, BETWEEN WHATEVER SHARES ITS BAND
	--
	-- 560 wide where it can be, narrower where the cash block or the BAT/TRAP
	-- column stands in its band, and slid off centre rather than squeezed
	-- symmetrically -- the words are what it is for, and TutorialUI scales
	-- them down only when the banner is narrower than they are.
	--==========================================================================
	local bannerHeight = CONFIG.BannerSize.Y + CONFIG.SkipSize.Y
	local band = rect(0, railBottom + G, sw, bannerHeight)
	local blo, bhi = M, sw - M
	local beside: { Rect } = { cash, equipment }
	if thumb then
		table.insert(beside, thumb)
	end
	if jump then
		table.insert(beside, jump)
	end
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
			local apart = HudLayout.gap(groups[i].rect, groups[j].rect)
			if apart < G then
				table.insert(found, string.format("%s and %s are %.1f px apart",
					groups[i].name, groups[j].name, apart))
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
	if not input.touch and input.safe.X >= CONFIG.DesktopMinWidth then
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
