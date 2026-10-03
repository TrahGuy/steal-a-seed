--!strict
-- Steal a Seed :: HudLayout
--
-- Where every permanent HUD group sits, worked out from the screen the player
-- actually has rather than from the one it was drawn on.
--
--==============================================================================
-- WHY THIS IS ONE MODULE AND NOTHING BUT NUMBERS
--
-- The HUD has fourteen owners and none of them owns the others:
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
--   ActionToastUI, PlotTeleportUI              the refusal toast and TELEPORT
--                                              TO PLOT
--   AdminConsoleUI                             the ADMIN button, for the two
--                                              accounts AdminService allows
--
-- They have to agree to the pixel without talking to each other, so each asks
-- this module the same question with the same facts -- how big the safe area
-- is, whether the screen is touch, whether there is a keyboard -- and applies
-- ITS OWN part of the answer to ITS OWN instances. Nothing here builds, finds,
-- moves or keeps an instance, and nothing here runs on a clock: an owner asks
-- again when its ScreenGui's AbsoluteSize changes, which is the viewport, the
-- inset and the notch all at once -- and one placed round the clock also when
-- GuiService.TopbarInset does, which that size does not show. Same pattern as
-- ReachPoint, for the same reason, and it is what lets HudLayoutSpec drive
-- every branch without Play.
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
--   bottom left   cash and speed, above the thumbstick and the hotbar line (in
--                 sidebars: in the corner itself, on the thumbstick's ring)
--
-- The hotbar and the cash block also change FACE in compact and in sidebars: a
-- smaller belt (GameConfig.Hotbar.Compact, read through hotMetrics) and a
-- smaller cash block (CASH_COMPACT, and CASH_PHONE in sidebars). Every answer carries its mode's numbers as
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

-- The title-safe margins of a TV, in the logical units of a scaled gui: how far
-- in from each edge of the safe area a group may start, and how far the
-- window-space things at the top (the clock, the notice band) come down.
export type TenFootInput = {
	left: number,
	top: number,
	right: number,
	bottom: number,
	lift: number,
}

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
	-- ON A TV ONLY (see THE TEN-FOOT PROFILE): the title-safe margins. nil
	-- everywhere else, which is every desktop and every phone.
	tv: TenFootInput?,
	-- How far the clock, the notice band and the tutorial banner come down --
	-- set for the inner solve of a TV answer, nil otherwise.
	lift: number?,
	-- THE RAIN EVENT IS PAYING (2026-10-02): measure reads it off the server's
	-- attribute. True puts the rain chip over the strip and the toast line over
	-- that; nil or false and the answer is exactly what it always was.
	rain: boolean?,
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
	-- The item name's band just above the strip (LoadoutUI's popup, shown on
	-- an equip and under a mouse). Notices, the cash block and the equipment
	-- column keep clear of it as they do of the strip.
	namePopup: Rect,
	-- THE RAIN CHIP (WeatherUI, 2026-10-02): "+25% INCOME · time", just over the
	-- name band, only while the Rain event pays (Input.rain). Notices keep clear
	-- of it: the toast line steps up over it. Nil while no rain falls.
	rain: Rect?,

	-- The cash block as a group (its reserved width), and its root frame.
	cash: Rect,
	cashRoot: Rect,

	thumb: Rect?,
	jump: Rect?,

	-- The tutorial's instruction banner and the skip line under it.
	banner: Rect,
	skip: Rect,
	-- How large TutorialUI draws its words -- the banner's lines, the pointer and
	-- the celebration: 1, except on a phone (THE TUTORIAL BANNER). `banner` is
	-- already the drawn size; the skip line is never scaled.
	tutorialScale: number,

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

	-- TWO SMALL THINGS THAT COME AND GO, in every mode (see TOAST AND TELEPORT).
	-- A refused action's one-line toast, just above the belt: ActionToastUI.
	toast: Rect,
	-- TELEPORT TO PLOT, top centre under the notice band: PlotTeleportUI. The
	-- rect is the button's touch area; `teleportScale` is how large its plate is
	-- DRAWN inside it -- 1, except on a phone (TELEPORT TO PLOT ON A PHONE).
	teleport: Rect,
	teleportScale: number,
	-- The OBBY button right beside it (ObbyButtonUI), its plate drawn at
	-- `teleportScale` too; `obbyWide` where there is room for its icon as well as
	-- its word. An empty rect where neither side has room: it then stays hidden.
	obby: Rect,
	obbyWide: boolean,
	-- The BIOMES button (BiomesButtonUI, 2026-09-30) on TELEPORT's other side,
	-- drawn the same way: `biomesWide` where its icon fits too, an empty rect
	-- where no side has room (it then stays hidden). On a phone's row it is the
	-- row's first button, right after Roblox's own.
	biomes: Rect,
	biomesWide: boolean,
	-- The plate TELEPORT TO PLOT (and the obby's RETURN TO PLOT) draws inside
	-- its touch area, before `teleportScale`: the touch area's own size
	-- everywhere but a phone, whose touch area is narrower than the plate's
	-- 196 x 44 drawn at 0.75 would suggest (THE PHONE'S TOP ROW).
	teleportPlate: Vector2,

	-- ON A PHONE ONLY (THE PHONE'S TOP ROW, THE PHONE'S CENTRE COLUMN). False,
	-- empty or nil on a desktop, a console, a TV and a small window.
	-- The clock is drawn as a chip: two short lines, the words over the time.
	clockChip: boolean,
	-- TELEPORT TO PLOT stands on the clock's row, beside it, rather than under it.
	topRow: boolean,
	-- The obby's run clock, in the OBBY button's slot -- that button is hidden on
	-- the course. Empty where the slot is not on the top row.
	run: Rect,
	-- The top row's two ends, and the middle and the top of the column under it;
	-- safe space.
	rowLo: number?,
	rowHi: number?,
	columnCentre: number?,
	columnTop: number?,
	-- The notices stand at the top of the centre column and stack DOWN from it.
	toastTop: boolean,
	-- The guide's words stand in the left column: left-aligned and wrapped, the
	-- step counter and Skip on a row above them.
	guide: boolean,

	-- The two-account ADMIN button, in WINDOW space like `clock`: in the topbar
	-- beside the clock (see THE ADMIN BUTTON). nil without a clock to stand by.
	admin: Rect?,

	-- A TV's title-safe canvas in safe space, which every group above sits
	-- inside, and how far the window-space row came down. Both nil off a TV.
	frame: Rect?,
	lift: number?,
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

--==============================================================================
-- THE PHONE'S FACE: COMPACT, 15% SMALLER (owner, 2026-09-24)
--
-- Asked for on the 735 x 413 emulated phone, with the block moved down into the
-- bottom-left corner (sidebars, CASH AND SPEED). Every size of the compact face
-- that draws the two lines and the shoe, at 0.85 and rounded: speed at 23 and
-- cash at 30, the shoe at 0.544, 2 px between the lines as before -- 27 + 2 +
-- 34 = 63 tall. Speed stays over cash; colours, icons and formatting are
-- CashUI's, untouched.
--
-- The x2 card never rides the cash line on a phone -- it is the top-right row's
-- button there -- so the card's and its message's numbers are compact's own,
-- and the button looks exactly as it did. For the same reason the reservation
-- is the widest balance alone: "$9.99Qa" is compact's 129 px at 30/35, 111,
-- and its outline -- kept as 120. The block reaches 2 px under its root for the
-- cash line's outline, and nothing else hangs below it.
--==============================================================================
local CASH_PHONE: CashStyle = {
	Root = Vector2.new(162, 63),
	Reserve = 120,
	Drop = 2,
	SpeedSize = 23,
	CashSize = 30,
	SpeedX = 31,
	SpeedW = 131,
	SpeedBottom = 27,
	CashW = 162,
	SpeedStroke = 1.3,
	CashStroke = 1.7,
	ShoeScale = 0.544,
	ShoeBottom = 25,
	BuffSize = CASH_COMPACT.BuffSize,
	BuffHit = CASH_COMPACT.BuffHit,
	BuffGap = CASH_COMPACT.BuffGap,
	BuffMinX = CASH_COMPACT.BuffMinX,
	BuffDrop = CASH_COMPACT.BuffDrop,
	TipSize = CASH_COMPACT.TipSize,
	TipLift = CASH_COMPACT.TipLift,
	BuffCorner = CASH_COMPACT.BuffCorner,
}

local CONFIG = {
	-- Compact keeps every group this far inside the safe area, and this far
	-- from every other group.
	Margin = 8,
	Gap = 8,
	-- Below this a desktop window is compact: the rail and the cash block need
	-- the width (the five-slot strip itself is 410).
	DesktopMinWidth = 900,
	-- The slots are ROLES (HotbarRoles, 2026-10-01): bat, trap, the Spin
	-- Tickets, the active plant or pod, the previous one. A touch screen has
	-- the first four; the previous-plant slot is the desktop's fifth.
	DesktopSlots = 5,
	MobileSlots = 4,
	WalkHeight = 46,
	-- The cash block's two faces (see THE CASH BLOCK'S TWO FACES), and the
	-- desktop one's three placing numbers under the names they always had.
	CashStyle = { Desktop = CASH_DESKTOP, Compact = CASH_COMPACT, Phone = CASH_PHONE },
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
	-- On a phone the tutorial's words -- the banner, the pointer and the
	-- celebration -- are drawn at this (owner, 2026-09-24; THE TUTORIAL BANNER).
	TutorialPhoneScale = 0.75,
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
	-- TOAST AND TELEPORT
	--
	-- THE TOAST is one line just above the belt, up to 340 wide, narrowed
	-- round anything that shares its rows and never under 200 -- below that it
	-- is lifted clear instead. It is drawn UNDER prompts, hatch timers, the belt
	-- and every panel (ActionToastUI's DisplayOrder), so where a world prompt
	-- happens to pass behind it, the prompt wins.
	--
	-- THE TELEPORT BUTTON sits under the NOTICE BAND -- the biome name and the
	-- sale line, drawn by BiomeGuideUI and SellUI at window y 50 to 80 -- centred
	-- under the clock, 44 tall for a thumb. On a 58-px topbar that is safe
	-- y 30. Where it shares rows with the top buttons it stays between them, and
	-- the tutorial banner, a dropped notice and the chooser all keep 8 px off it.
	--==========================================================================
	-- 52 tall since 2026-09-27: one notice -- a headline and a one-line next
	-- step (ActionToastUI) -- rather than the old one-line pill. Older notices
	-- stand above it; see THE NOTICE STACK.
	Toast = { Width = 340, Height = 52, MinWidth = 200 },
	-- The rain chip's line, per mode (THE RAIN CHIP).
	Rain = { Desktop = Vector2.new(240, 24), Compact = Vector2.new(200, 22), Phone = Vector2.new(170, 20) },
	-- On a phone it stands right under the clock instead, the plate drawn at
	-- PhoneScale inside the same 196 x 44 touch area (TELEPORT TO PLOT ON A PHONE).
	Teleport = { Size = Vector2.new(196, 44), PhoneScale = 0.75 },
	-- THE OBBY BUTTON beside it (2026-09-27; see obbyBeside): TELEPORT's height,
	-- as wide as its icon and word -- or the word alone where only that fits.
	-- `Tight` only on a phone's top row that has no room for `Narrow` (2026-09-30):
	-- the word alone, a little smaller (the label scales it to fit, 10 at least),
	-- and still wide enough for the run's clock that takes OBBY's slot.
	Obby = { Size = Vector2.new(124, 44), Narrow = 64, Tight = 56 },
	-- THE BIOMES BUTTON on TELEPORT's other side (2026-09-30; see biomesBeside):
	-- the same widths, sized for its longer word (56 px of LuckiestGuy 16).
	Biomes = { Size = Vector2.new(120, 44), Narrow = 80, Tight = 56 },
	NoticeTop = 50,
	NoticeHeight = 30,
	-- THE STATUS COLUMN (2026-09-27; see statusRows): the chase warning's line
	-- and the boost row, tall enough for StatusText's desktop sizes -- 26 with
	-- its icon is 32, 17 with its clock is 23 -- which a phone draws smaller.
	Status = { Height = 32, BoostHeight = 26 },
	-- The ADMIN button: the clock's height, one short word wide.
	Admin = { Size = Vector2.new(64, 34) },
	--==========================================================================
	-- THE PHONE'S TOP ROW AND WHAT STANDS UNDER IT (2026-09-29; see below)
	--
	-- The clock as a chip, this wide. TELEPORT TO PLOT's touch area beside it:
	-- its plate is still Teleport.Size drawn at Teleport.PhoneScale -- 147 x 33
	-- -- inside a touch area that is the plate and a few pixels, so the row has
	-- room for the OBBY button too. Under the row, in the safe area: the boost
	-- row, then the band every passing line shares (the notices, the biome name,
	-- the sale line). The guide's words stand in the left column.
	--==========================================================================
	Phone = {
		Clock = 124,
		Touch = 156,
		-- Below the top row's foot, in safe space: the boost row, and where the
		-- passing lines start.
		BoostTop = 2,
		BoostHeight = 18,
		NoticeTop = 24,
		-- A passing line stands this far under whatever already stands in the band.
		NoticeGap = 4,
		-- The guide's words: a block this wide at most, never past this share of
		-- the width (the character stands in the middle), and as tall as a row
		-- for STEP and Skip, two lines of instruction and two of advice. `Clear`
		-- is what it keeps between its right edge and the middle of the screen
		-- wherever that still leaves the row its width: measured 2026-09-29 on a
		-- 705-px phone, the character at the camera's resting zoom is 85 px wide
		-- and a 200-px block's longest line ended on its shoulder.
		Guide = { Width = 200, Reach = 0.47, Height = 90, Row = 20, Clear = 48 },
		-- Skip, beside the step counter: a button, as tall as it always was.
		Skip = Vector2.new(112, 20),
		Counter = 62,
	},
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
		-- The Plants tab's one-line note over its cards ("$/s is base income"),
		-- and the Sort button that stands at the right end of the tab row. The
		-- note is counted out of the tray before whole rows are, so a phone's
		-- one row of cards still fits whole under it; the button is counted out
		-- of the tab row, which is why each tab is still 120 wide at 341.
		NoteH = 18,
		SortW = 92,
		SortGap = 6,
	},
	--==========================================================================
	-- THE TEN-FOOT PROFILE (see below): the logical canvas a TV's title-safe
	-- area is shown as, and the share of each edge a TV may crop.
	--==========================================================================
	TenFoot = {
		Canvas = Vector2.new(1280, 720),
		SafeEdge = 0.05,
		MinScale = 1,
		MaxScale = 3,
	},
}
HudLayout.Config = CONFIG

--==============================================================================
-- THE TEN-FOOT PROFILE: THE DESKTOP LAYOUT, BIGGER, INSIDE THE TITLE-SAFE AREA
--
-- Approved by the owner 2026-09-24 after an Xbox tester (Michael) found the HUD
-- and the panels too small to read from a sofa. Only where Roblox says the
-- screen is a TV (GuiService:IsTenFootInterface) -- every desktop and every
-- phone answers exactly as it did.
--
-- NOT A REDESIGN. A TV gets the same arrangement a desktop gets, magnified:
--
--   * Each of the game's ScreenGuis carries a UIScale named TenFoot (UIKit
--     puts it there), which makes the gui lay its children out on a LOGICAL
--     canvas of window / scale and draw them that much bigger. The scale is
--     the one that shows the TV's title-safe area as a 1280 x 720 canvas --
--     1.35 at 1080p -- and never below 1.
--   * measure() hands a scaled gui's owner that logical size, so every rect
--     below is in logical pixels and every owner's UDim2 means what it says.
--   * solve() lays the ordinary answer out on the title-safe canvas -- 5% in
--     from each edge of the window, the share a TV may crop -- and moves it
--     there. The clock, the notice band under it and the tutorial banner come
--     down with the title-safe top edge (`lift`).
--
-- WHAT A SCALED GUI MUST NOT DO is turn an AbsoluteSize, AbsolutePosition or
-- TextBounds -- which are real pixels -- into an Offset without dividing by
-- scaleOf(). Every place that does was found and does (2026-09-24 audit).
--==============================================================================
local TEN_FOOT = "TenFoot"
HudLayout.TenFootName = TEN_FOOT

-- For a harness: nil asks the engine, true or false decides.
HudLayout.tenFootOverride = nil :: boolean?

function HudLayout.isTenFoot(): boolean
	local forced = HudLayout.tenFootOverride
	if forced ~= nil then
		return forced
	end
	local ok, tv = pcall(function()
		return game:GetService("GuiService"):IsTenFootInterface()
	end)
	return ok and tv == true
end

-- The magnification that shows a window's title-safe area as the canvas.
function HudLayout.tenFootScale(viewport: Vector2): number
	local T = CONFIG.TenFoot
	local usable = viewport * (1 - 2 * T.SafeEdge)
	local scale = math.min(usable.X / T.Canvas.X, usable.Y / T.Canvas.Y)
	if scale ~= scale then
		return T.MinScale
	end
	return math.clamp(scale, T.MinScale, T.MaxScale)
end

-- The TenFoot scale of the ScreenGui (or BillboardGui) `object` is drawn in,
-- or 1 -- what an AbsoluteSize read there has to be divided by to become an
-- Offset. Reads; never creates.
function HudLayout.scaleOf(object: Instance?): number
	local node = object
	while node and not node:IsA("LayerCollector") do
		node = node.Parent
	end
	if node then
		local scale = node:FindFirstChild(TEN_FOOT)
		if scale and scale:IsA("UIScale") and scale.Scale > 0 then
			return scale.Scale
		end
	end
	return 1
end

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

-- The item name's band over the strip (2026-10-01): as wide as the strip,
-- NamePopupGap above it. And the strip with that band, which is what
-- everything placed above the hotbar keeps clear of.
function HudLayout.namePopupOver(hotbar: Rect): Rect
	return rect(hotbar.x, hotbar.y - HOT.NamePopupGap - HOT.NamePopupHeight, hotbar.w, HOT.NamePopupHeight)
end

function HudLayout.hotbarBand(hotbar: Rect): Rect
	local reach = HOT.NamePopupGap + HOT.NamePopupHeight
	return rect(hotbar.x, hotbar.y - reach, hotbar.w, hotbar.h + reach)
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
	-- On a TV the row comes down to the title-safe top edge; 0 everywhere else.
	local top = CONFIG.ClockTop + (input.lift or 0)
	if top + CONFIG.ClockHeight + CONFIG.Gap > insetTop + L.railTop then
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
	return rect(centre - width / 2, top, width, CONFIG.ClockHeight)
end

--==============================================================================
-- THE RAIN CHIP (2026-10-02)
--
-- "+25% INCOME · time" while the Rain event pays (WeatherUI): one small
-- transparent line centred over the strip, just above its name band, and the
-- toast line steps up over it so a notice never lands on it. Nil -- and nothing
-- else moves -- while no rain falls, which is what `input.rain` says. Where
-- something that shares its columns stands in its row (a lifted cash block in a
-- narrow window), it steps up over that too.
--==============================================================================
local function rainOver(input: Input, hotbar: Rect, band: Rect, size: Vector2, beside: { Rect }?): Rect?
	if not input.rain then
		return nil
	end
	local G = CONFIG.Gap
	local x = hotbar.x + hotbar.w / 2 - size.X / 2
	local chip = rect(x, band.y - G - size.Y, size.X, size.Y)
	if beside then
		for _ = 1, 3 do
			local lifted = false
			for _, other in ipairs(beside) do
				if other.w > 0 and HudLayout.gap(chip, other) < G then
					chip = rect(x, other.y - G - size.Y, size.X, size.Y)
					lifted = true
				end
			end
			if not lifted then
				break
			end
		end
	end
	return chip
end

local function withRain(band: Rect, rain: Rect?): Rect
	return if rain then HudLayout.union(band, rain) else band
end

--==============================================================================
-- THE TOAST: ONE LINE ABOVE THE BELT
--
-- Centred on the belt, 8 px over it, and as wide as 340 allows between
-- whatever shares its rows -- the cash block, the BAT/TRAP column, the thumbs.
-- Where that leaves less than 200 it is lifted above the lowest thing it met
-- and tried again, so a short phone gets a line higher up rather than a sliver.
--==============================================================================
local function toastAbove(sw: number, hotbar: Rect, beside: { Rect }): Rect
	local T, M, G = CONFIG.Toast, CONFIG.Margin, CONFIG.Gap
	local centre = hotbar.x + hotbar.w / 2
	local bottom = hotbar.y - G
	local lo, hi = M, sw - M
	for _ = 1, 3 do
		local band = rect(0, bottom - T.Height, sw, T.Height)
		local ceiling = bottom
		lo, hi = M, sw - M
		for _, other in ipairs(beside) do
			if sharesRows(band, other, G) then
				if other.x + other.w / 2 < centre then
					lo = math.max(lo, other.x + other.w + G)
				else
					hi = math.min(hi, other.x - G)
				end
				ceiling = math.min(ceiling, other.y - G)
			end
		end
		if hi - lo >= T.MinWidth then
			break
		end
		bottom = ceiling
	end
	local width = math.max(0, math.min(T.Width, hi - lo))
	local x = math.clamp(centre - width / 2, lo, math.max(lo, hi - width))
	return rect(x, bottom - T.Height, width, T.Height)
end

--==============================================================================
-- THE TELEPORT BUTTON: UNDER THE NOTICE BAND, CENTRED UNDER THE CLOCK
--
-- `rows` are the top buttons that may share its band; it stays 8 px inside
-- them. `clock` is the clock's rect in window space, when there is a window to
-- measure, so a clock slid off centre by the topbar takes the button with it.
--==============================================================================
--==============================================================================
-- TELEPORT TO PLOT ON A PHONE (owner, 2026-09-24, twice)
--
-- Drawn at PhoneScale -- 0.75: plate, icon, word and padding, by UIScale --
-- inside the same 196 x 44 touch area, so a thumb has exactly the target it
-- had. And it comes right up to the clock: the DRAWN plate 8 px under it. That
-- puts the top of the button up in the topbar, under the clock, which is only
-- allowed inside the topbar's free span (GuiService.TopbarInset, the part Roblox
-- leaves to the game) -- nowhere near Roblox's own buttons. Where the free span
-- is too narrow to hold it, it waits under the topbar instead, at the safe
-- area's own 8 px margin, as the first pass had it.
--
-- The ADMIN button, beside the clock or hung under it on a window too narrow
-- for either side, keeps 8 px off the whole touch area; the button drops under
-- it where it would not. The notice band it used to wait under goes beneath it
-- (HudLayout.notice). Still centred on the clock and still between the top
-- rows; which screens show it, and what a press does, are not touched.
--==============================================================================
local function teleportUnder(input: Input, clock: Rect?, rows: { Rect }, phone: boolean?, admin: Rect?): Rect
	local T, M, G = CONFIG.Teleport, CONFIG.Margin, CONFIG.Gap
	local sw = input.safe.X
	local insetTop = input.insetTop or 0
	local w, h = T.Size.X, T.Size.Y
	local viewport = input.viewport
	-- Where the safe area starts across the window: the notched phones' side
	-- insets are equal, so it is centred.
	local originX = if viewport then (viewport.X - sw) / 2 else 0
	local centre = sw / 2
	if clock and viewport then
		centre = clock.x + clock.w / 2 - originX
	end
	-- Centred under the clock, and 8 px inside the top rows that share its band.
	local function at(y: number): Rect
		local band = rect(0, y, sw, h)
		local lo, hi = M, sw - M
		for _, other in ipairs(rows) do
			if sharesRows(band, other, G) then
				if other.x + other.w / 2 < centre then
					lo = math.max(lo, other.x + other.w + G)
				else
					hi = math.min(hi, other.x - G)
				end
			end
		end
		local c = math.clamp(centre, lo + w / 2, math.max(lo + w / 2, hi - w / 2))
		return rect(c - w / 2, y, w, h)
	end
	if not phone then
		local noticeTop = CONFIG.NoticeTop + (input.lift or 0)
		return at(math.max(M, noticeTop + CONFIG.NoticeHeight - insetTop + G))
	end

	-- The clock's height never depends on the window, so it is known even
	-- before the camera is: an owner laid out that early still gets this.
	local clockBottom = if clock then clock.y + clock.h
		else CONFIG.ClockTop + (input.lift or 0) + CONFIG.ClockHeight
	-- The plate is drawn this far inside the touch area, top and bottom.
	local inset = h * (1 - T.PhoneScale) / 2
	-- ADMIN in safe space; it is in window space like the clock.
	local a = if admin then rect(admin.x - originX, admin.y - insetTop, admin.w, admin.h) else nil
	local function underAdmin(r: Rect): Rect
		if a and HudLayout.gap(a, r) < G then
			return at(math.max(r.y, a.y + a.h + G))
		end
		return r
	end
	local r = underAdmin(at(math.ceil(clockBottom + G - inset) - insetTop))
	if r.y < 0 then
		local bar = input.topbar
		local free = bar ~= nil and bar.w > 0
			and r.x + originX >= bar.x + M and r.x + r.w + originX <= bar.x + bar.w - M
		if not free then
			r = underAdmin(at(M))
		end
	end
	return r
end

--==============================================================================
-- THE ADMIN BUTTON: IN THE TOPBAR, BESIDE THE CLOCK
--
-- Two accounts ever see it (AdminService), so it takes room nobody else's HUD
-- uses and moves nothing: no group is placed around it, and every other answer
-- is the same with or without it. WINDOW space, like the clock, level with it
-- and as tall: right of the clock inside the topbar's free span, left of it
-- where the right is too narrow. Every listed desktop and phone has room on the
-- right. On a window too narrow for either side it hangs just under the clock,
-- in the notice band, which only ever carries passing text.
--==============================================================================
local function adminBeside(input: Input, clock: Rect?): Rect?
	if not clock then
		return nil
	end
	local A, M, G = CONFIG.Admin, CONFIG.Margin, CONFIG.Gap
	local w, h = A.Size.X, A.Size.Y
	local y = clock.y + (clock.h - h) / 2
	local lo, hi = M, math.huge
	local bar, viewport = input.topbar, input.viewport
	if bar and bar.w > 0 then
		lo, hi = bar.x + M, bar.x + bar.w - M
	elseif viewport then
		hi = viewport.X - M
	end
	local right = clock.x + clock.w + G
	if right + w <= hi then
		return rect(right, y, w, h)
	end
	local left = clock.x - G - w
	if left >= lo then
		return rect(left, y, w, h)
	end
	return rect(clock.x + clock.w / 2 - w / 2, clock.y + clock.h + 4, w, h)
end
HudLayout.adminBeside = adminBeside

--==============================================================================
-- THE OBBY BUTTON: RIGHT BESIDE TELEPORT TO PLOT (2026-09-27)
--
-- ObbyButtonUI's touch area. TELEPORT's own row and height, 8 px off it, its
-- plate drawn at TELEPORT's scale -- so on a phone it is up under the clock
-- with it -- on TELEPORT's right where that clears everything, else on its
-- left; with its icon where the room allows, the word alone where only that
-- fits. Up in the topbar only inside the free span, TELEPORT's own rule, and
-- 8 px off the ADMIN button's reservation. Where neither side has room for even
-- the word the answer is an empty rect and the button stays hidden: a shortcut
-- is not worth covering anything for. HudLayoutSpec finds it beside TELEPORT on
-- every listed screen.
--
-- Nothing is placed around it. The chase warning shares TELEPORT's slot
-- (statusRows) and can run wider than it, but never while this shows: the
-- button is for the Safe Zone only, and AlertUI stands the warning down there.
--==============================================================================
-- Whether a rect beside TELEPORT clears everything it must: the safe area's
-- margin, the topbar's free span where it is up in the topbar, every group and
-- badge, the belt's toast and the guide's words, the touch controls, the chooser,
-- ADMIN and the clock -- and `extra`, which BIOMES passes OBBY in.
local function besideClear(input: Input, L: Layout, extra: { Rect }): (Rect) -> boolean
	local M, G = CONFIG.Margin, CONFIG.Gap
	local sw = input.safe.X
	local insetTop = input.insetTop or 0
	local viewport = input.viewport
	local originX = if viewport then (viewport.X - sw) / 2 else 0
	local others: { Rect } = { L.toast, L.banner, L.skip }
	for _, r in ipairs(extra) do
		table.insert(others, r)
	end
	for _, g in ipairs(HudLayout.groups(L, true)) do
		table.insert(others, g.rect)
	end
	local indexBadge, gardenBadge = HudLayout.badges(L)
	table.insert(others, indexBadge)
	table.insert(others, gardenBadge)
	for _, maybe in ipairs({ { L.thumb }, { L.jump }, { L.chooser } }) do
		local r = maybe[1]
		if r then
			table.insert(others, r)
		end
	end
	local admin = L.admin
	if admin then
		table.insert(others, rect(admin.x - originX, admin.y - insetTop, admin.w, admin.h))
	end
	-- The clock itself (window space, like ADMIN): on a phone TELEPORT stands
	-- BESIDE it on its row, so "left of TELEPORT" can be the clock's own place.
	-- Everywhere else the button's row is far under the clock and this rules
	-- nothing out.
	local clock = L.clock
	if clock then
		table.insert(others, rect(clock.x - originX, clock.y - insetTop, clock.w, clock.h))
	end
	local function clear(r: Rect): boolean
		if r.x < M or r.x + r.w > sw - M then
			return false
		end
		if r.y < 0 then
			local bar = input.topbar
			if not (bar and bar.w > 0 and r.x + originX >= bar.x + M and r.x + r.w + originX <= bar.x + bar.w - M) then
				return false
			end
		end
		for _, other in ipairs(others) do
			if HudLayout.gap(r, other) < G then
				return false
			end
		end
		return true
	end
	return clear
end

local function obbyBeside(input: Input, L: Layout): (Rect, boolean)
	local O, M, G = CONFIG.Obby, CONFIG.Margin, CONFIG.Gap
	local t = L.teleport
	local clear = besideClear(input, L, {})
	if t.w > 0 then
		-- TELEPORT's own row first; then, where TELEPORT stands up in the topbar
		-- and the topbar has no room beside it (a small phone: the free span
		-- ends on one side, the x2 button and ADMIN take the other), just under
		-- the topbar at the margin -- the row TELEPORT itself drops to when its
		-- own span is too narrow. HudLayout.notice steps round it there.
		local rows = if t.y < M then { t.y, M } else { t.y }
		for _, y in ipairs(rows) do
			for _, width in ipairs({ O.Size.X, O.Narrow }) do
				for _, x in ipairs({ t.x + t.w + G, t.x - G - width }) do
					local r = rect(x, y, width, t.h)
					if clear(r) then
						return r, width == O.Size.X
					end
				end
			end
		end
	end
	return rect(0, 0, 0, 0), false
end

--==============================================================================
-- THE BIOMES BUTTON: ON TELEPORT'S OTHER SIDE (2026-09-30)
--
-- BiomesButtonUI's touch area, by OBBY's own rules -- TELEPORT's row and
-- height, 8 px off it, its plate drawn at TELEPORT's scale, the icon where the
-- room allows and the word alone where only that fits -- on the side of
-- TELEPORT that OBBY left free, so a desktop reads BIOMES | TELEPORT TO PLOT |
-- OBBY; beyond OBBY where that side has no room. Asked after OBBY and 8 px off
-- it; nothing is placed around it. Where no side has room the rect is empty and
-- the button stays hidden. A phone whose top row holds the buttons places it on
-- the row instead (phoneRow).
--==============================================================================
local function biomesBeside(input: Input, L: Layout): (Rect, boolean)
	local B, M, G = CONFIG.Biomes, CONFIG.Margin, CONFIG.Gap
	local t, o = L.teleport, L.obby
	local clear = besideClear(input, L, if o.w > 0 then { o } else {})
	if t.w > 0 then
		local rows = if t.y < M then { t.y, M } else { t.y }
		for _, y in ipairs(rows) do
			for _, width in ipairs({ B.Size.X, B.Narrow }) do
				local left, right = t.x - G - width, t.x + t.w + G
				local xs = if o.w <= 0 then { left, right }
					elseif o.x > t.x then { left, o.x + o.w + G }
					else { right, o.x - G - width }
				for _, x in ipairs(xs) do
					local r = rect(x, y, width, t.h)
					if clear(r) then
						return r, width == B.Size.X
					end
				end
			end
		end
	end
	return rect(0, 0, 0, 0), false
end

--==============================================================================
-- DESKTOP: THE GEOMETRY THAT SHIPPED
--==============================================================================
local function desktop(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local I, G = RAIL.Inset, CONFIG.Gap
	local wide, square = RAIL.WideSize, RAIL.SquareSize
	local row = wide.Y + RAIL.Gap

	-- Index and Shop are the owner's square artwork (2026-09-24): 50 x 50 where
	-- the 130 x 50 slabs stood, the same height, so nothing under them moves.
	local index = rect(I, I, square.X, square.Y)
	local shop = rect(I, I + row, square.X, square.Y)
	local settings = rect(I, I + row * 2, square.X, square.Y)
	local walk = rect(I, I + row * 3, wide.X, CONFIG.WalkHeight)
	local garden = rect(sw - I - square.X, I, square.X, square.Y)
	local bag = rect(sw - I - square.X, I + square.Y + RAIL.Gap, square.X, square.Y)
	local equipment = rect(sw - I - CONFIG.EquipWidth, I + (square.Y + RAIL.Gap) * 2 + 6,
		CONFIG.EquipWidth, CONFIG.EquipSlot * 2 + CONFIG.EquipGap)

	-- Five roles, keyboard or not: a console reaches them with LB and RB.
	local slots = CONFIG.DesktopSlots
	local chip = sw >= HOT.ChipMinViewport
	local width = HudLayout.hotbarWidth(slots, chip)
	local height = HudLayout.hotbarHeight()
	local hotbar = rect(sw / 2 - width / 2, sh - HOT.BottomGap - height, width, height)
	local band = HudLayout.hotbarBand(hotbar)
	local rain = rainOver(input, hotbar, band, CONFIG.Rain.Desktop, nil)

	-- Beside the hotbar where the whole reservation fits; above it (and its
	-- name band) where not.
	local style = CASH_DESKTOP
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	local cx = CONFIG.CashLeft
	local rootBottom = sh - HOT.BottomGap
	if cx + cw + G > hotbar.x then
		rootBottom = band.y - G - style.Drop
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
		namePopup = HudLayout.namePopupOver(hotbar),
		cash = cash,
		cashRoot = cashRoot,
		thumb = nil,
		jump = nil,
		banner = banner,
		skip = skip,
		tutorialScale = 1,
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
		toast = rect(0, 0, 0, 0),
		teleport = rect(0, 0, 0, 0),
		teleportScale = 1,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = CONFIG.Teleport.Size,
		clockChip = false,
		topRow = false,
		run = rect(0, 0, 0, 0),
		toastTop = false,
		guide = false,
		admin = nil,
	}
	L.clock = clockRect(input, L)
	L.admin = adminBeside(input, L.clock)
	-- Placed round the shipped geometry; nothing above moves for them.
	L.teleport = teleportUnder(input, L.clock, {
		HudLayout.union(HudLayout.union(index, shop), HudLayout.union(settings, walk)),
		HudLayout.union(garden, bag), equipment,
	})
	L.rain = rain
	L.toast = toastAbove(sw, withRain(band, rain), { cash, equipment })
	-- ON A TV ONLY: the notice band and TELEPORT TO PLOT under it came down
	-- (`lift`), so the tutorial banner keeps 8 px under the button, as compact's
	-- always has. The desktop's 84 is not touched.
	if input.lift then
		local top = math.max(banner.y, L.teleport.y + L.teleport.h + G)
		L.banner = rect(banner.x, top, banner.w, banner.h)
		L.skip = rect(skip.x, top + CONFIG.BannerSize.Y, skip.w, skip.h)
	end
	L.obby, L.obbyWide = obbyBeside(input, L)
	L.biomes, L.biomesWide = biomesBeside(input, L)
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
local function beltBetween(input: Input, thumb: Rect?, jump: Rect?, slots: number): (Rect, boolean, boolean)
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
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
--
-- ON A PHONE the words were too big for the screen (owner, 2026-09-24): the
-- banner is `scale` (TutorialPhoneScale) of its size -- 420 x 63 at most --
-- and TutorialUI draws its lines, the pointer and the celebration at the same
-- scale (`tutorialScale`). The skip line under it keeps its size: it is a
-- button, and 20 px is already the least a finger gets.
--==============================================================================
local function bannerIn(sw: number, railBottom: number, beside: { Rect }, scale: number?): (Rect, Rect)
	local M, G = CONFIG.Margin, CONFIG.Gap
	local size = CONFIG.BannerSize * (scale or 1)
	local bannerHeight = size.Y + CONFIG.SkipSize.Y
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
	local bannerWidth = math.max(CONFIG.SkipSize.X, math.min(size.X, bhi - blo))
	local bannerCentre = sw / 2
	if bannerWidth <= bhi - blo then
		bannerCentre = math.clamp(bannerCentre, blo + bannerWidth / 2, bhi - bannerWidth / 2)
	end
	local banner = rect(bannerCentre - bannerWidth / 2, band.y, bannerWidth, size.Y)
	local skip = rect(bannerCentre - CONFIG.SkipSize.X / 2, band.y + size.Y,
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

	-- THE HOTBAR: see beltBetween. A touch screen has four roles; a desktop
	-- window that is merely small keeps the keyboard's five.
	local slots = if input.touch then CONFIG.MobileSlots else CONFIG.DesktopSlots
	local hotbar, chip, stripFits = beltBetween(input, thumb, jump, slots)
	local band = HudLayout.hotbarBand(hotbar)
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
		floor = math.min(floor, band.y - G)
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
		limit = math.min(limit, band.y - G)
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
		namePopup = HudLayout.namePopupOver(hotbar),
		cash = cash,
		cashRoot = cashRoot,
		thumb = thumb,
		jump = jump,
		banner = banner,
		skip = skip,
		tutorialScale = 1,
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
		toast = rect(0, 0, 0, 0),
		teleport = rect(0, 0, 0, 0),
		teleportScale = 1,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = CONFIG.Teleport.Size,
		clockChip = false,
		topRow = false,
		run = rect(0, 0, 0, 0),
		toastTop = false,
		guide = false,
		admin = nil,
	}
	L.clock = clockRect(input, L)
	L.admin = adminBeside(input, L.clock)
	L.teleport = teleportUnder(input, L.clock, {
		HudLayout.union(HudLayout.union(index, shop), HudLayout.union(settings, walk)),
		HudLayout.union(garden, bag),
	})
	-- The tutorial banner keeps 8 px under the teleport button as well as the rows.
	L.banner, L.skip = bannerIn(sw, math.max(railBottom, L.teleport.y + L.teleport.h), beside)
	local rain = rainOver(input, hotbar, band, CONFIG.Rain.Compact, beside)
	L.rain = rain
	L.toast = toastAbove(sw, withRain(band, rain), beside)
	L.fits = L.fits and #HudLayout.problems(L) == 0
	L.obby, L.obbyWide = obbyBeside(input, L)
	L.biomes, L.biomesWide = biomesBeside(input, L)
	return L
end

--==============================================================================
-- THE PHONE'S TOP ROW (2026-09-29)
--
-- The owner's report, from landscape phone screenshots: the DAY timer a very
-- wide bar across the top, and under it a column of words -- the teleport and
-- obby buttons, the stage, the boosts, the guide, the notices -- down the
-- middle of the screen, over the player's own forward view. Measured the same
-- day in Studio's phone emulation (705 x 338): with the guide and two boosts up
-- on the course that column ran from the clock to the belt, and the boost row
-- stood ON the belt.
--
-- So on a phone everything that used to stand under the clock stands on one
-- row, up in the topbar's band -- since 2026-09-30 in the order of the owner's
-- edited screenshot, read on from Roblox's own buttons:
--
--   BIOMES | TELEPORT TO PLOT | OBBY | ... | ADMIN | the clock, as a chip
--
--   * THE BUTTONS start at the row's left end, 8 px after Roblox's buttons and
--     8 px apart. TELEPORT TO PLOT's plate is the same 147 x 33 as before, in a
--     touch area Phone.Touch wide and 44 tall; BIOMES (the owner's one-place
--     teleport, BiomesButtonUI) and OBBY are drawn at the same scale, both with
--     their icons where the row has the room and both the word alone where it
--     has not. RETURN TO PLOT is TELEPORT's button on the course, and the run's
--     clock has OBBY's slot there (`run`): the button is hidden on the course.
--   * THE CLOCK is a chip Phone.Clock wide -- two short lines, the words over
--     the time (WorldClock) -- at the row's RIGHT end, where the bar once took
--     44% of the window.
--   * ADMIN, which two accounts see, stands just left of the clock, and hangs
--     under the row's middle, 8 px below the buttons, only where the row has
--     no room for it.
--   * THE CENTRE COLUMN under the row keeps the window's centre line (`centre`)
--     -- where the clock stood before 2026-09-30 -- so the boosts and the
--     passing lines still stand in the middle.
--
-- INSIDE THE TOPBAR'S FREE SPAN, EVERY ONE OF THEM: 8 px clear of Roblox's own
-- buttons (GuiService.TopbarInset), and inside the safe area across, which a
-- notch narrows. Where the row cannot hold ALL THREE buttons and the clock, the
-- answer for the three is nil, the clock stands on the centre line, and the
-- caller stands the buttons under it, as they stood before the row.
--
-- WINDOW space for the clock and ADMIN, safe space for the buttons, as each
-- always was.
--==============================================================================
type PhoneRow = {
	clock: Rect?,
	admin: Rect?,
	teleport: Rect?,
	obby: Rect?,
	obbyWide: boolean,
	biomes: Rect?,
	biomesWide: boolean,
	-- The row's two ends and the centre column's middle, in safe space.
	lo: number,
	hi: number,
	centre: number,
}

local function phoneRow(input: Input, band: { railTop: number, railRight: number, rightLeft: number }): PhoneRow
	local M, G = CONFIG.Margin, CONFIG.Gap
	local P, T, O, B, A = CONFIG.Phone, CONFIG.Teleport, CONFIG.Obby, CONFIG.Biomes, CONFIG.Admin
	local sw = input.safe.X
	local answer: PhoneRow = {
		clock = nil, admin = nil, teleport = nil, obby = nil, obbyWide = false,
		biomes = nil, biomesWide = false,
		lo = M, hi = sw - M, centre = sw / 2,
	}
	local viewport = input.viewport
	if not viewport then
		return answer
	end
	local insetTop = input.insetTop or 0
	local originX = (viewport.X - sw) / 2
	local top = CONFIG.ClockTop + (input.lift or 0)
	-- The buttons' touch areas are taller than the clock and centred on it.
	local touchTop = top + (CONFIG.ClockHeight - T.Size.Y) / 2

	local lo, hi = originX + M, originX + sw - M
	local bar = input.topbar
	if bar and bar.w > 0 then
		lo, hi = math.max(lo, bar.x + M), math.min(hi, bar.x + bar.w - M)
	end
	-- A topbar too short to hold the row: it then shares the top buttons' rows
	-- and stays between them, as the clock always has (clockRect).
	if touchTop + T.Size.Y + G > insetTop + band.railTop then
		lo = math.max(lo, originX + band.railRight + G)
		hi = math.min(hi, originX + band.rightLeft - G)
	end

	local width = math.min(P.Clock, math.max(0, hi - lo))
	local centre = viewport.X / 2
	if hi - lo >= width then
		centre = math.clamp(centre, lo + width / 2, hi - width / 2)
	end
	-- A row that cannot hold the buttons keeps the clock on the centre line, as
	-- it stood: the caller stands the buttons under it.
	answer.clock = rect(centre - width / 2, top, width, CONFIG.ClockHeight)
	answer.lo, answer.hi, answer.centre = lo - originX, hi - originX, centre - originX

	-- The clock at the row's right end, and the buttons from its left end.
	local clock = rect(hi - width, top, width, CONFIG.ClockHeight)
	local aw, ah = A.Size.X, A.Size.Y
	local ay = clock.y + (clock.h - ah) / 2
	--==========================================================================
	-- ALL THREE BUTTONS OR NONE. A row with room for two would leave the third
	-- nowhere to stand -- under the row is where ADMIN hangs once the row is
	-- full -- and a shortcut every player had must not vanish because Roblox's
	-- own buttons grew. Such a screen keeps the arrangement it had: the buttons
	-- under the clock (the caller; teleportUnder, obbyBeside, biomesBeside).
	--
	-- THE WIDTHS, widest first, and ADMIN on the row before the icons: a row
	-- with room for the words alone and ADMIN gets exactly that, as in the
	-- owner's screenshot. Without room for ADMIN as well it hangs under the
	-- row's middle, 8 px under the buttons' touch areas; and a row too narrow
	-- even for the words at their size (a 640- or 667-px phone) draws them a
	-- little smaller (`Tight`) rather than lose the row.
	--
	-- The three touch areas are always side by side, so the chase warning has
	-- TELEPORT's slot and BIOMES' beside it as its room (statusLine): both are
	-- empty then, the buttons being for the Safe Zone only.
	--==========================================================================
	local tiers = {
		{ B.Size.X, O.Size.X, true }, { B.Narrow, O.Narrow, true },
		{ B.Size.X, O.Size.X, false }, { B.Narrow, O.Narrow, false },
		{ B.Tight, O.Tight, false },
	}
	for _, tier in ipairs(tiers) do
		local bw, ow, withAdmin = tier[1], tier[2], tier[3]
		local stop = if withAdmin then clock.x - G - aw - G else clock.x - G
		local tx = lo + bw + G
		local ox = tx + P.Touch + G
		if ox + ow <= stop + 1e-6 then
			local wide = bw == B.Size.X
			answer.clock = clock
			answer.biomes = rect(lo - originX, touchTop - insetTop, bw, T.Size.Y)
			answer.teleport = rect(tx - originX, touchTop - insetTop, P.Touch, T.Size.Y)
			answer.obby = rect(ox - originX, touchTop - insetTop, ow, T.Size.Y)
			answer.biomesWide, answer.obbyWide = wide, wide
			answer.admin = if withAdmin then rect(clock.x - G - aw, ay, aw, ah)
				else rect(centre - aw / 2, touchTop + T.Size.Y + G, aw, ah)
			return answer
		end
	end
	return answer
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
--   bottom left   cash and speed in the phone's face (compact at 0.85), in the
--                 very corner, 12 in and 10 up, on the thumbstick's resting
--                 ring by the owner's approval (2026-09-24); over the belt only
--                 where the corner would meet it.
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

	-- THE BELT: see beltBetween. Four roles on a phone: the previous-plant
	-- slot is the desktop's.
	local hotbar, chip, stripFits = beltBetween(input, thumb, jump, CONFIG.MobileSlots)
	local band = HudLayout.hotbarBand(hotbar)
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
		floor = math.min(floor, band.y - G)
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
	--==========================================================================
	-- THE CLOCK, AND THE TELEPORT BUTTON ON ITS ROW (2026-09-29)
	--
	-- THE PHONE'S TOP ROW, above. Worked out here rather than at the end,
	-- because the chooser keeps clear of the button. Where the row has no room
	-- for the three buttons and the clock -- a topbar whose free span is very
	-- narrow -- TELEPORT stands under the clock with OBBY and BIOMES beside it
	-- there (obbyBeside, biomesBeside, below), as every phone's did before the
	-- row.
	--==========================================================================
	local row = phoneRow(input, { railTop = M, railRight = walk.x + walk.w, rightLeft = boost.x })
	local clock, admin = row.clock, row.admin
	local inRow = row.teleport ~= nil
	local teleport: Rect
	if row.teleport then
		teleport = row.teleport
	else
		admin = adminBeside(input, clock)
		teleport = teleportUnder(input, clock, {
			rect(dock.x, dock.y, dockRight - dock.x, dock.h), handle, walk,
			HudLayout.union(HudLayout.union(boost, garden), bag),
		}, true, admin)
	end

	local chooserH = C.Pad * 2 + C.Title + C.Card.Y
	local chooserRight = equipment.x - G
	local widest = C.Pad + C.Cards * C.Card.X + (C.Cards - 1) * C.Gap + C.Spine
	local oneCard = C.Pad + C.Card.X + C.Spine
	local leftmost = chooserRight - math.min(widest, chooserRight - (sw / 2 + G))
	local lowest = sh - M
	-- The strip, not its name band: the chooser is up only while a weapon is
	-- being picked, and on the smallest phones clearing the band as well would
	-- push it into the jump button.
	for _, other in ipairs({ hotbar, jump, thumb }) do
		if other.x < chooserRight + G and other.x + other.w + G > leftmost then
			lowest = math.min(lowest, other.y - G)
		end
	end
	local chooserY = math.floor(equipment.y + equipment.h / 2 - chooserH / 2)
	chooserY = math.clamp(chooserY, top, math.max(top, lowest - chooserH))
	if chooserY + chooserH > lowest then
		fits = false
	end
	-- Sharing rows with the teleport button, it keeps 8 px to the button's right.
	if chooserY < teleport.y + teleport.h + G then
		leftmost = math.max(leftmost, teleport.x + teleport.w + G)
	end
	local chooserW = chooserRight - leftmost
	if chooserW < oneCard then
		fits = false
		chooserW = oneCard
	end
	local chooser = rect(chooserRight - chooserW, chooserY, chooserW, chooserH)

	--==========================================================================
	-- CASH AND SPEED: THE BOTTOM-LEFT CORNER (owner, 2026-09-24)
	--
	-- The phone's face (CASH_PHONE, compact at 0.85) in the very corner of the
	-- safe area: 12 in and 10 up, as the desktop's block stands and level with
	-- the belt's own bottom edge. That is ON TOP OF the thumbstick's resting
	-- ring, which the owner approved in so many words: the joystick keeps its
	-- place and its behaviour, and the block takes no input (CashUI), so a thumb
	-- landing on it lands on the stick. It used to stand 8 px over the ring, or
	-- beside the dock where the dock left no room -- floating mid-screen on a
	-- 735 x 413 phone.
	--
	-- The belt is still kept clear: where the corner would come within 8 px of
	-- it, the block stands 8 px over the belt's top line instead. The dock is
	-- reserved above the thumbstick's zone, so the corner never reaches it. It
	-- carries no x2 card here -- that is the button on the top row -- so it has
	-- nothing a thumb can press.
	--==========================================================================
	local style = CASH_PHONE
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	local ch = style.Root.Y + style.Drop
	local cx = CONFIG.CashLeft
	local rootBottom = sh - HOT.BottomGap
	if HudLayout.gap(rect(cx, rootBottom - style.Root.Y, cw, ch), band) < G then
		rootBottom = band.y - G - style.Drop
	end
	local cash = rect(cx, rootBottom - style.Root.Y, cw, ch)
	local cashRoot = rect(cx, rootBottom - style.Root.Y, style.Root.X, style.Root.Y)
	if cash.y < dock.y + dock.h + G then
		fits = false
	end

	--==========================================================================
	-- THE PHONE'S CENTRE COLUMN, AND THE GUIDE'S WORDS BESIDE IT (2026-09-29)
	--
	-- With the buttons up on the clock's row, the column under it is the safe
	-- area's own top: `columnTop` is 0, or the foot of whatever still stands
	-- under the clock on a phone the row could not hold (the button, an ADMIN
	-- hung there). Two things stand in the column, and nothing else:
	--
	--   the boost row      Phone.BoostTop under columnTop, Phone.BoostHeight tall
	--   the passing lines  from Phone.NoticeTop: the notices (ActionToastUI), the
	--                      biome name and the sale line -- each there for a
	--                      second or two and gone
	--
	-- THE GUIDE'S WORDS LEAVE THE MIDDLE. They were a 420-px banner under all
	-- of that, over the player's own head for the whole of a beginner's first
	-- minutes. They stand in the LEFT column now, the way a quest line does:
	-- from the dock handle's right edge, under WALK MODE, left-aligned and
	-- wrapped (TutorialUI), never past Guide.Reach of the width -- and 8 px
	-- clear of the belt and the cash block where it shares their columns. The
	-- step counter and Skip stand on one row above the words, so the button
	-- never moves when the words change length.
	--
	-- A screen too narrow for that block keeps the banner it had, under the
	-- passing lines' band.
	--
	-- A PHONE WHOSE ROW COULD NOT HOLD THE BUTTONS HAS NO COLUMN: `columnTop` is
	-- nil and every answer that reads it (notice, statusRows, statusLine, the
	-- toast, the guide, the run's clock) is the one that shipped before the row
	-- -- the buttons under the clock, the lines under them, the notices over the
	-- belt. Nothing on such a screen is new but the clock's chip.
	--==========================================================================
	local P = CONFIG.Phone
	local columnTop: number? = nil
	if inRow then
		local top = math.max(0, teleport.y + teleport.h)
		if admin and clock and admin.y >= clock.y + clock.h then
			top = math.max(top, admin.y + admin.h - (input.insetTop or 0))
		end
		columnTop = top
	end

	local guide = false
	local banner: Rect, skip: Rect
	do
		local gx = handle.x + handle.w + G
		-- Under WALK MODE's row -- and under the passing lines' band too, where a
		-- column that starts lower (ADMIN hung under the clock) brings that band
		-- down to the block: a biome name going by never lands on the words.
		local gy = math.max(railBottom, (columnTop or 0) + P.NoticeTop + CONFIG.NoticeHeight) + G
		-- As wide as the row above the words needs at the least; Guide.Clear short
		-- of the middle where the screen allows more than that; never past Reach.
		local least = P.Counter + G + P.Skip.X
		local gw = math.min(P.Guide.Width, math.floor(sw * P.Guide.Reach) - gx,
			math.max(least, math.floor(sw / 2 - P.Guide.Clear) - gx))
		local floorY = sh - M
		for _, other in ipairs({ band, cash, thumb, jump, equipment }) do
			if other.x < gx + gw + G and other.x + other.w + G > gx then
				floorY = math.min(floorY, other.y - G)
			end
		end
		if columnTop and gw >= least and floorY - gy >= P.Guide.Height then
			guide = true
			banner = rect(gx, gy, gw, P.Guide.Height)
			skip = rect(gx + P.Counter + G, gy, P.Skip.X, P.Skip.Y)
		else
			local noticeBottom = if columnTop
				then columnTop + P.NoticeTop + CONFIG.NoticeHeight
				else teleport.y + teleport.h + G + CONFIG.NoticeHeight
			banner, skip = bannerIn(sw, math.max(railBottom, noticeBottom),
				{ cash, equipment, thumb, jump, dock, handle }, CONFIG.TutorialPhoneScale)
		end
	end

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
		namePopup = HudLayout.namePopupOver(hotbar),
		cash = cash,
		cashRoot = cashRoot,
		thumb = thumb,
		jump = jump,
		banner = banner,
		skip = skip,
		tutorialScale = CONFIG.TutorialPhoneScale,
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
		toast = toastAbove(sw, band, { cash, equipment, thumb, jump }),
		teleport = teleport,
		teleportScale = CONFIG.Teleport.PhoneScale,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = CONFIG.Teleport.Size,
		clockChip = true,
		topRow = inRow,
		run = rect(0, 0, 0, 0),
		rowLo = if inRow then row.lo else nil,
		rowHi = if inRow then row.hi else nil,
		columnCentre = if inRow then row.centre else nil,
		columnTop = columnTop,
		toastTop = false,
		guide = guide,
		admin = admin,
	}
	L.clock = clock
	L.fits = L.fits and #HudLayout.problems(L) == 0
	local beside, first = row.obby, row.biomes
	if not (beside and first and columnTop) then
		-- No row: beside TELEPORT under the clock, as OBBY stood (obbyBeside),
		-- BIOMES on its other side (biomesBeside), and everything else as it
		-- stood with them.
		L.obby, L.obbyWide = obbyBeside(input, L)
		L.biomes, L.biomesWide = biomesBeside(input, L)
		return L
	end
	-- On the row: the run's clock has OBBY's slot on the course.
	L.obby, L.obbyWide = beside, row.obbyWide
	L.biomes, L.biomesWide = first, row.biomesWide
	L.run = beside

	--==========================================================================
	-- THE NOTICES, AT THE TOP OF THE COLUMN (2026-09-29)
	--
	-- They stood on the belt, which on a phone is over the character's own feet
	-- and the ground in front of them -- the owner's "large success
	-- notifications fill much of the middle of the screen", and on the course
	-- the very leaf a runner is about to land on. On a phone they stand at the
	-- top of the centre column instead and stack DOWN from it (noticeStack),
	-- between the top rows, as wide as the belt's toast ever was.
	--
	-- Where that band is too narrow for the narrowest notice they stay over the
	-- belt, where they were.
	--==========================================================================
	local T = CONFIG.Toast
	local band = rect(row.centre - T.Width / 2, columnTop + P.NoticeTop, T.Width, T.Height)
	local r = HudLayout.centreIn(L, band, T.Width)
	if r.w >= T.MinWidth then
		L.toast = rect(r.x, band.y, r.w, T.Height)
		L.toastTop = true
	end
	-- The rain chip over the belt's name band, clear of the thumbs, the cash
	-- block and the equipment panel. The notices are in the column, not here.
	do
		local around: { Rect } = { L.cash, L.equipment }
		if L.thumb then
			table.insert(around, L.thumb)
		end
		if L.jump then
			table.insert(around, L.jump)
		end
		L.rain = rainOver(input, L.hotbar, HudLayout.hotbarBand(L.hotbar), CONFIG.Rain.Phone, around)
	end
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
		local phoneList: { Group } = {
			{ name = "rail", rect = L.walk },
			{ name = "dock", rect = dock },
			{ name = "handle", rect = handle },
			{ name = "garden+bag", rect = right },
			{ name = "equipment", rect = L.equipment },
			{ name = "hotbar", rect = L.hotbar },
			{ name = "cash", rect = L.cash },
		}
		if L.rain then
			table.insert(phoneList, { name = "rain", rect = L.rain })
		end
		return phoneList
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
	-- The rain chip, while it rains: a group of its own, so the notice stack
	-- (noticeStack) and every clearance check keep off it.
	if L.rain then
		table.insert(list, { name = "rain", rect = L.rain })
	end
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
	-- The item name's band over the strip (2026-10-01): up for a second on an
	-- equip, so not a permanent group, but nothing permanent may stand in it.
	-- It touches the strip it belongs to, which is the one pair exempted.
	table.insert(transient, { name = "name band", rect = L.namePopup })
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
			local exempt = (extra.name == "shut handle"
				and (group.name == "dock" or group.name == "handle"))
				or (extra.name == "name band" and group.name == "hotbar")
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
			-- The one approved overlap (owner, 2026-09-24): a phone's cash block in
			-- the bottom-left corner, on the thumbstick's ring. It takes no input,
			-- so the stick still gets every touch. The jump button, and every
			-- other group, still keep 8 px clear.
			local approved = L.sidebar and group.name == "cash" and zone == L.thumb
			local apart = HudLayout.gap(zone, group.rect)
			if apart < G and not approved then
				table.insert(found, string.format("%s is %.1f px from a touch control",
					group.name, apart))
			end
		end
	end
	return found
end

--==============================================================================
-- THE TEN-FOOT ANSWER
--
-- The ordinary answer for the title-safe canvas, moved onto it. The canvas
-- starts `tv.top` below the safe area, so the inner solve is told the topbar is
-- that much deeper -- which keeps every window-space conversion inside it (the
-- clock's, the teleport button's) exact -- and `lift` brings the clock row down
-- to the title-safe top edge. The margins are equal left and right, so the
-- clock stays on the window's centre line. Window-space rects (the clock, the
-- ADMIN button) are not moved; everything in safe space is.
--==============================================================================
local function shifted(r: Rect, dx: number, dy: number): Rect
	return rect(r.x + dx, r.y + dy, r.w, r.h)
end

local function shiftedMaybe(r: Rect?, dx: number, dy: number): Rect?
	return if r then shifted(r, dx, dy) else nil
end

local function tenFoot(input: Input, tv: TenFootInput): Layout
	local inner: Input = table.clone(input)
	inner.tv = nil
	inner.safe = Vector2.new(math.max(0, input.safe.X - tv.left - tv.right),
		math.max(0, input.safe.Y - tv.top - tv.bottom))
	inner.insetTop = (input.insetTop or 0) + tv.top
	inner.lift = tv.lift
	local L = HudLayout.solve(inner)
	local dx, dy = tv.left, tv.top
	L.index = shifted(L.index, dx, dy)
	L.shop = shifted(L.shop, dx, dy)
	L.settings = shifted(L.settings, dx, dy)
	L.walk = shifted(L.walk, dx, dy)
	L.garden = shifted(L.garden, dx, dy)
	L.bag = shifted(L.bag, dx, dy)
	L.equipment = shifted(L.equipment, dx, dy)
	L.hotbar = shifted(L.hotbar, dx, dy)
	L.namePopup = shifted(L.namePopup, dx, dy)
	L.rain = shiftedMaybe(L.rain, dx, dy)
	L.cash = shifted(L.cash, dx, dy)
	L.cashRoot = shifted(L.cashRoot, dx, dy)
	L.thumb = shiftedMaybe(L.thumb, dx, dy)
	L.jump = shiftedMaybe(L.jump, dx, dy)
	L.banner = shifted(L.banner, dx, dy)
	L.skip = shifted(L.skip, dx, dy)
	L.dock = shiftedMaybe(L.dock, dx, dy)
	L.handle = shiftedMaybe(L.handle, dx, dy)
	L.handleShut = shiftedMaybe(L.handleShut, dx, dy)
	L.boost = shiftedMaybe(L.boost, dx, dy)
	L.chooser = shiftedMaybe(L.chooser, dx, dy)
	L.toast = shifted(L.toast, dx, dy)
	L.teleport = shifted(L.teleport, dx, dy)
	-- An empty rect (no room for the button) stays empty.
	if L.obby.w > 0 then
		L.obby = shifted(L.obby, dx, dy)
	end
	if L.biomes.w > 0 then
		L.biomes = shifted(L.biomes, dx, dy)
	end
	L.railTop += dy
	L.railBottom += dy
	L.railRight += dx
	L.rightLeft += dx
	L.safe = input.safe
	L.frame = rect(dx, dy, inner.safe.X, inner.safe.Y)
	L.lift = tv.lift
	return L
end

--==============================================================================
-- THE ANSWER
--==============================================================================
function HudLayout.solve(input: Input): Layout
	local tv = input.tv
	if tv then
		return tenFoot(input, tv)
	end
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
-- THE NOTICE STACK (2026-09-27)
--
-- ActionToastUI's notices stand on the toast rect, newest at the bottom and
-- older ones above it. `one` is one notice's height with the gap under it and
-- `most` how many the screen may show at once. The stack grows up only while
-- it stays 8 px clear of every group and both thumbs, and never into the middle
-- band -- `middle` (the window's centre, in safe space) plus MiddleBand, where
-- the controller's reticle and its reason line sit. Always at least one.
--
-- Returns the whole area the stack may take and how many notices fit in it.
-- HudLayoutSpec holds that area clear on every listed screen.
--==============================================================================
HudLayout.MiddleBand = 48

function HudLayout.noticeStack(L: Layout, one: number, most: number, middle: number): (Rect, number)
	local t = L.toast
	local bottom = t.y + t.h
	local others: { Rect } = {}
	for _, g in ipairs(HudLayout.groups(L, true)) do
		table.insert(others, g.rect)
	end
	if L.thumb then
		table.insert(others, L.thumb)
	end
	if L.jump then
		table.insert(others, L.jump)
	end
	--==========================================================================
	-- ON A PHONE THE STACK HANGS FROM THE TOP (2026-09-29; `toastTop`)
	--
	-- The newest notice at the top of the centre column and older ones under
	-- it, growing DOWN only while the whole stack ends 8 px above the middle of
	-- the screen -- the character's own head -- and keeps 8 px off every group.
	-- Always at least one.
	--==========================================================================
	if L.toastTop then
		local held = 1
		for n = 2, math.max(1, most) do
			local area = rect(t.x, t.y, t.w, n * one)
			if area.y + area.h > middle - CONFIG.Gap then
				break
			end
			local clear = true
			for _, other in ipairs(others) do
				if HudLayout.gap(area, other) < CONFIG.Gap then
					clear = false
					break
				end
			end
			if not clear then
				break
			end
			held = n
		end
		return rect(t.x, t.y, t.w, math.max(t.h, held * one)), held
	end
	local count = 1
	for n = 2, math.max(1, most) do
		local top = bottom - t.h - (n - 1) * one
		if top < middle + HudLayout.MiddleBand then
			break
		end
		local area = rect(t.x, top, t.w, bottom - top)
		local clear = true
		for _, other in ipairs(others) do
			if HudLayout.gap(area, other) < CONFIG.Gap then
				clear = false
				break
			end
		end
		if not clear then
			break
		end
		count = n
	end
	local top = bottom - t.h - (count - 1) * one
	return rect(t.x, top, t.w, bottom - top), count
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
function HudLayout.notice(L: Layout, width: number, height: number, top: number, reach: number?): (number, number)
	local G = CONFIG.Gap
	--==========================================================================
	-- ON A PHONE: THE TOP OF THE CENTRE COLUMN (2026-09-29)
	--
	-- The passing lines' band, Phone.NoticeTop under the column's top, on the
	-- clock's centre and between the top rows. `reach` is how far down the
	-- notices stand at this moment (the player's NoticeReach attribute, which
	-- ActionToastUI publishes while one is up): a name arriving while a notice
	-- is up stands under it rather than on it. `top` is not asked -- the band
	-- is wherever the column starts.
	--==========================================================================
	local columnTop, columnCentre = L.columnTop, L.columnCentre
	if L.sidebar and columnTop and columnCentre then
		local P = CONFIG.Phone
		local y = columnTop + P.NoticeTop
		if type(reach) == "number" and reach == reach then
			y = math.max(y, reach + P.NoticeGap)
		end
		local r = HudLayout.centreIn(L, rect(columnCentre - width / 2, y, width, height), width)
		if r.w >= width - 0.5 then
			return r.x + r.w / 2 - L.safe.X / 2, y
		end
		-- Too wide to stand between the rows: under them, as everywhere else.
		return 0, math.max(y, L.railBottom + G)
	end
	-- A TV brings the band down with the clock above it; 0 everywhere else.
	top += L.lift or 0
	-- On a phone the teleport button stands right under the clock, in this
	-- band (TELEPORT TO PLOT ON A PHONE): a notice that would share its rows
	-- stands 8 px under it instead, and is placed round the top rows from there
	-- like any other. The tutorial banner keeps 8 px under that spot (sidebars),
	-- so a beginner keeps their instructions up while a name goes by.
	--
	-- ON EVERY SCREEN SINCE 2026-09-27. The biome name and the sale line end 8 px
	-- above the button on a desktop, so this never touches them there. (The
	-- chase warning and the boost timer used to be asked for here too, at
	-- window y 84 and 114, and this rule stood both under the button -- into
	-- the same spot. They have rows of their own now: see statusRows.)
	local teleport = L.teleport
	if top < teleport.y + teleport.h + G and top + height + G > teleport.y then
		top = teleport.y + teleport.h + G
	end
	-- The OBBY and BIOMES buttons, where a small phone stands them under the
	-- topbar beside TELEPORT (obbyBeside, biomesBeside): inside the rows' band,
	-- and stepped round like them.
	local inRows: { Rect } = {}
	for _, b in ipairs({ L.obby, L.biomes }) do
		if b.w > 0 and top < b.y + b.h + G and top + height + G > b.y then
			table.insert(inRows, b)
		end
	end
	if (top + height + G <= L.railTop or top >= L.railBottom + G) and #inRows == 0 then
		return 0, top
	end
	local centre = L.safe.X / 2
	-- Measured to the badges as well as the buttons: Garden's hangs 4.5 px
	-- off its left corner in compact, toward the middle.
	local indexBadge, gardenBadge = HudLayout.badges(L)
	local lo = math.max(L.railRight, indexBadge.x + indexBadge.w) + G
	local hi = math.min(L.rightLeft, gardenBadge.x) - G
	for _, b in ipairs(inRows) do
		if b.x + b.w / 2 < centre then
			lo = math.max(lo, b.x + b.w + G)
		else
			hi = math.min(hi, b.x - G)
		end
	end
	if width / 2 <= math.min(centre - lo, hi - centre) then
		return 0, top
	end
	if width <= hi - lo then
		return (lo + hi) / 2 - centre, top
	end
	-- Dropped under the rows, and under the teleport, OBBY and BIOMES buttons
	-- where lower.
	local lowest = math.max(L.railBottom, L.teleport.y + L.teleport.h)
	for _, b in ipairs({ L.obby, L.biomes }) do
		if b.w > 0 then
			lowest = math.max(lowest, b.y + b.h)
		end
	end
	return 0, lowest + G
end

--==============================================================================
-- THE STATUS COLUMN (2026-09-27)
--
-- Where the lasting indicators stand -- the chase warning, the running boosts,
-- the obby's run line -- as the owner asked in one brief: the warning centred
-- under the clock, the boosts in their own row under it, the biome name allowed
-- for, and nothing moving when a chase starts or ends. Three bands, worked out
-- from rects this module already places, so they follow the clock and the
-- topbar exactly as those do:
--
--   status   the chase warning (AlertUI), IN the TELEPORT TO PLOT slot and on
--            its centre. The button shows only in the Safe Zone and a guardian
--            only chases outside it, so the slot is empty whenever the warning
--            is up; AlertUI also stands the line down inside the Safe Zone,
--            which covers the second a chase takes to let go at the red line.
--            Right under the clock on a phone, under the notice band on a
--            desktop.
--   notice   the notice band (HudLayout.notice at NoticeTop): the biome name
--            and the sale line, unchanged -- and on the Floating Garden, where
--            RETURN TO PLOT has the teleport slot and no biome is announced (the
--            whole course is in the field's order), the obby's run line.
--   boosts   the running boosts (BonusChestUI): one compact row under whichever
--            of the teleport slot and the notice band is lower -- the same place
--            with or without a chase, a biome name or the button, so a timer
--            never jumps. The tutorial banner starts in this band on some
--            screens, never at the same time: the chest opens when the guide
--            is done.
--
-- Safe space, like every rect here; `insetTop` is the owner's measure of the
-- topbar (HudLayout.measure). Each rect is a band on the clock's centre -- x and
-- w are the teleport slot's -- and an owner centres its own content in it with
-- centreIn. HudLayoutSpec holds all three clear of every group and of each
-- other on every listed screen.
--==============================================================================
function HudLayout.statusRows(L: Layout, insetTop: number): (Rect, Rect, Rect)
	local S, G = CONFIG.Status, CONFIG.Gap
	local t = L.teleport
	local status = rect(t.x, t.y + (t.h - S.Height) / 2, t.w, S.Height)
	--==========================================================================
	-- ON A PHONE (2026-09-29): THE SLOT IS ON THE CLOCK'S ROW, AND THE COLUMN
	-- UNDER IT HOLDS THE BOOSTS AND THE PASSING LINES
	--
	-- The warning still has TELEPORT TO PLOT's slot -- which is beside the
	-- clock now, so that is where the warning stands (statusLine). The boost
	-- row is the first thing under the row and the passing lines' band the
	-- second: the boosts are what lasts, so they take the place nearest the
	-- edge of the screen. Both on the clock's centre.
	--==========================================================================
	local columnTop, columnCentre = L.columnTop, L.columnCentre
	if L.sidebar and columnTop and columnCentre then
		local P = CONFIG.Phone
		local x = columnCentre - t.w / 2
		return status,
			rect(x, columnTop + P.NoticeTop, t.w, CONFIG.NoticeHeight),
			rect(x, columnTop + P.BoostTop, t.w, P.BoostHeight)
	end
	local _, noticeTop = HudLayout.notice(L, 0, CONFIG.NoticeHeight, CONFIG.NoticeTop - insetTop)
	local notice = rect(t.x, noticeTop, t.w, CONFIG.NoticeHeight)
	local top = math.max(t.y + t.h, noticeTop + CONFIG.NoticeHeight) + G
	local boosts = rect(t.x, top, t.w, S.BoostHeight)
	return status, notice, boosts
end

--==============================================================================
-- A LINE `width` WIDE, CENTRED IN A BAND, BETWEEN WHATEVER SHARES ITS ROWS
--
-- On the band's middle -- the clock's -- wherever that clears every group and
-- both badges by 8 px; slid between them where it only fits off centre; and
-- never wider than the room there is. HudLayoutSpec keeps the room from running
-- out on every listed screen for the longest words these lines carry.
--==============================================================================
function HudLayout.centreIn(L: Layout, band: Rect, width: number): Rect
	local G, M = CONFIG.Gap, CONFIG.Margin
	local centre = band.x + band.w / 2
	local lo, hi = M, L.safe.X - M
	local row = rect(0, band.y, L.safe.X, band.h)
	local others: { Rect } = {}
	for _, g in ipairs(HudLayout.groups(L, true)) do
		table.insert(others, g.rect)
	end
	local indexBadge, gardenBadge = HudLayout.badges(L)
	table.insert(others, indexBadge)
	table.insert(others, gardenBadge)
	for _, other in ipairs(others) do
		if sharesRows(row, other, G) then
			if other.x + other.w / 2 < centre then
				lo = math.max(lo, other.x + other.w + G)
			else
				hi = math.min(hi, other.x - G)
			end
		end
	end
	local w = math.min(width, math.max(0, hi - lo))
	local x = math.clamp(centre - w / 2, lo, math.max(lo, hi - w))
	return rect(x, band.y, w, band.h)
end

--==============================================================================
-- THE CHASE WARNING'S LINE (2026-09-29)
--
-- A line `width` wide in the status band. Everywhere but a phone that is
-- centreIn: on the slot's middle, under the clock. On a phone the slot stands
-- on the clock's row, and a warning wider than the slot must not grow over
-- OBBY's slot, ADMIN or the clock on its right: it starts at the slot's right
-- edge and runs LEFT, as far as the row's start (2026-09-30: the clock is at
-- the row's right end). The BIOMES button's slot is on that side and is always
-- empty then -- the button shows only in the Safe Zone, where the warning
-- stands down.
--==============================================================================
function HudLayout.statusLine(L: Layout, insetTop: number, width: number): Rect
	local band = HudLayout.statusRows(L, insetTop)
	local lo = L.rowLo
	if not (L.topRow and lo) then
		return HudLayout.centreIn(L, band, width)
	end
	local right = band.x + band.w
	local w = math.min(width, math.max(0, right - lo))
	return rect(right - w, band.y, w, band.h)
end

--==============================================================================
-- THE BOOST ROW, ONE RECT A BOOST (2026-09-29)
--
-- `widths` are the lines standing in the row, in order, and `gap` what is kept
-- between two of them. Side by side on the band's middle wherever they fit
-- whole between whatever shares the band's rows -- on every desktop, which is
-- exactly where BonusChestUI always put them. On a phone too narrow for that
-- they stand one under another instead, each on the band's middle, the band's
-- height apart: a second boost never runs under a top button or off the glass.
--==============================================================================
--
-- Returns the rects and how much smaller the lines are to be drawn: 1, except
-- on a phone where the row is a little too wide for the room -- two boosts on
-- a narrow screen -- and the lines are drawn down to BoostShrink of their size
-- to stand side by side still. Only a row too wide even for that is stacked.
--==============================================================================
HudLayout.BoostShrink = 0.8

function HudLayout.boostRows(L: Layout, band: Rect, widths: { number }, gap: number): ({ Rect }, number)
	local total = 0
	for i, w in ipairs(widths) do
		total += w + (if i > 1 then gap else 0)
	end
	local row = HudLayout.centreIn(L, band, total)
	local rows: { Rect } = {}
	local function sideBySide(from: number, k: number)
		local x = from
		for _, w in ipairs(widths) do
			table.insert(rows, rect(x, row.y, w * k, row.h))
			x += (w + gap) * k
		end
	end
	if row.w >= total - 0.5 or not L.sidebar or #widths < 2 then
		sideBySide(row.x, 1)
		return rows, 1
	end
	-- The room there is, asked with a row too wide for any screen.
	local room = HudLayout.centreIn(L, band, 1e6)
	local k = math.floor(room.w / total * 100) / 100
	if k >= HudLayout.BoostShrink then
		sideBySide(room.x + (room.w - total * k) / 2, k)
		return rows, k
	end
	for i, w in ipairs(widths) do
		local line = rect(band.x, band.y + (i - 1) * (band.h + 2), band.w, band.h)
		local r = HudLayout.centreIn(L, line, w)
		table.insert(rows, rect(r.x, line.y, w, line.h))
	end
	return rows, 1
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
	-- The player's chosen menu size (UIKit.menuScale); nil or 1 is today's.
	scale: number?,
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
	-- Height of the Plants tab's note strip at the top of the tray; 0 elsewhere.
	note: number,
	-- The menu size the panel is actually drawn at: the chosen one, or less if
	-- that would not fit. The group is sized panel / scale and drawn `scale`
	-- times larger, so `panel` stays its footprint on screen; `body`, `tray`,
	-- `infoRect` and `rows` describe the panel at that smaller logical size.
	scale: number,
}

function HudLayout.bag(L: Layout, input: BagInput): Bag
	local B = CONFIG.Bag
	local sw, sh = L.safe.X, L.safe.Y
	-- On a TV the panel is placed on the title-safe canvas and moved onto it,
	-- like every group; off a TV the offset is 0 and nothing changes.
	local ox, oy = 0, 0
	local frame = L.frame
	if frame then
		ox, oy, sw, sh = frame.x, frame.y, frame.w, frame.h
	end
	local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
	local leftEdge = RAIL.Inset + RAIL.WideSize.X + B.EdgeGap
	local rightEdge = sw - RAIL.Inset - input.sideWidth - B.EdgeGap
	local top = B.EdgeGap
	local bottom = input.hotTop - oy - B.EdgeGap
	if L.compact then
		-- The compact rail is two short rows, not two columns: the panel takes
		-- the width up to BAT/TRAP, and the rows stand over its top corners,
		-- which UIKit.modal's header pads its title and close button clear of.
		leftEdge = B.EdgeGap
		rightEdge = L.equipment.x - ox - B.EdgeGap
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
	local card = if L.compact then B.CardCompact else B.Card
	-- The note over the plant cards comes out of the tray's height first.
	local note = if input.plants then B.NoteH else 0

	--==========================================================================
	-- EVERYTHING INSIDE, AT A MENU SIZE
	--
	-- `s` is the player's menu size: the panel keeps its footprint and is drawn
	-- `s` times larger, so its insides are laid out for a panel `s` times
	-- smaller, centred where the real one is. At 1 this is exactly the layout
	-- it always was.
	--==========================================================================
	type Inner = {
		compactHeader: boolean, body: Rect, tray: Rect, info: string, infoRect: Rect?,
		rows: number, fits: boolean,
	}
	local function inner(s: number): Inner
		local w, h = width / s, height / s
		local px, py = centre.X - w / 2, centre.Y - h / 2
		if s == 1 then
			px, py = panel.x, panel.y
		end
		local outline = RAIL.OutlineThickness
		local shellW, shellH = w - outline * 2, h - outline * 2
		local compactHeader = shellH < B.CompactBelow
		local bodyTop = if compactHeader then B.BodyTopCompact else B.BodyTop
		local bodyW = shellW - 24
		local bodyH = shellH - (if compactHeader then B.BodyTrimCompact else B.BodyTrim)
		local body = rect(px + outline + 12, py + outline + bodyTop, bodyW, bodyH)

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
			rows = math.max(1, math.floor((tray.h - note - B.PadY * 2 + B.CardGap) / (card.Y + B.CardGap)))
		end
		-- A whole card, under the note, inside the tray's padding.
		local fits = tray.h - note - B.PadY * 2 >= card.Y
		return {
			compactHeader = compactHeader, body = body, tray = tray, info = info,
			infoRect = infoRect, rows = rows, fits = fits,
		}
	end

	--==========================================================================
	-- AS LARGE AS CHOSEN, NO LARGER THAN FITS
	--
	-- Never smaller than the panel's minimum at its logical size, and never so
	-- large that a whole row of cards stops fitting under the note: stepped
	-- down until it does, and never below today's size.
	--==========================================================================
	local scale = 1
	local chosen = input.scale
	if type(chosen) == "number" and chosen == chosen and chosen > 1 then
		scale = math.min(chosen, width / B.MinW, height / B.MinH)
		while scale > 1 and not inner(scale).fits do
			scale = math.max(1, scale - 0.05)
		end
		scale = math.max(1, scale)
	end
	local it = inner(scale)
	local compactHeader, body, tray, info, infoRect, rows =
		it.compactHeader, it.body, it.tray, it.info, it.infoRect, it.rows

	if frame then
		panel = shifted(panel, ox, oy)
		centre = Vector2.new(centre.X + ox, centre.Y + oy)
		body = shifted(body, ox, oy)
		tray = shifted(tray, ox, oy)
		infoRect = shiftedMaybe(infoRect, ox, oy)
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
		note = note,
		scale = scale,
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
	local input: Input = {
		safe = size,
		touch = UserInputService.TouchEnabled,
		keyboard = UserInputService.KeyboardEnabled,
		cashWidth = cashWidth,
		viewport = if camera then camera.ViewportSize else nil,
		topbar = rect(bar.Min.X, bar.Min.Y, bar.Width, bar.Height),
		insetTop = insetTop,
		-- The Rain event's own attribute (WeatherService): the chip is placed
		-- and the toast lifted only while it rains.
		rain = workspace:GetAttribute(GameConfig.Weather.Attributes.State) ~= nil,
	}
	-- A gui UIKit has scaled for a TV answers in its own logical units; every
	-- other gui -- every desktop, every phone -- gets `input` untouched. ON A TV
	-- ONLY: a menu's own gui also carries that UIScale when the player chose a
	-- larger menu size (UIKit.menuGui), and the rail and the HUD placed from it
	-- must not take that for a television.
	local marker = gui:FindFirstChild(TEN_FOOT)
	if marker and marker:IsA("UIScale") and HudLayout.isTenFoot() then
		return HudLayout.tenFootInput(input)
	end
	return input
end

--==============================================================================
-- THE FACTS, AS A GUI SCALED FOR A TV SEES THEM
--
-- Its children live on a canvas `scale` times smaller than the window, so every
-- fact is handed over in those units, with the title-safe margins: 5% of the
-- window in from each side and the bottom, and from the top less whatever the
-- topbar already takes. The scale is worked out from the window rather than
-- read off the UIScale, so an owner that relays out before UIKit has updated it
-- for a new window still gets the right answer. Pure, so HudLayoutSpec can
-- drive a TV it does not have.
--==============================================================================
function HudLayout.tenFootInput(input: Input): Input
	local view = input.viewport
	if not (view and view.X > 0 and view.Y > 0) then
		return input
	end
	local k = HudLayout.tenFootScale(view)
	local edge = CONFIG.TenFoot.SafeEdge
	local marginX, marginY = view.X * edge, view.Y * edge
	local insetTop = input.insetTop or 0
	local bar = input.topbar
	local out: Input = table.clone(input)
	out.safe = input.safe / k
	out.viewport = view / k
	out.topbar = if bar then rect(bar.x / k, bar.y / k, bar.w / k, bar.h / k) else nil
	out.insetTop = insetTop / k
	out.tv = {
		left = marginX / k,
		right = marginX / k,
		-- The safe area already starts insetTop down the window.
		top = math.max(0, marginY - insetTop) / k,
		bottom = marginY / k,
		lift = math.max(0, marginY / k - CONFIG.ClockTop),
	}
	return out
end

return HudLayout
