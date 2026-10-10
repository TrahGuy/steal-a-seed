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
--   GardenUI, LoadoutUI                        Garden and the Bag, and the
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
--   top left      Index, Shop, Settings: one row of 50 x 50 buttons
--   top right     EVENTS in the corner, Walk Mode's horizontal switch under it
--   centre left   Garden above the Bag at the left edge (2026-10-09, the
--                 owner: "put them on center left"; one row top right before)
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
-- Ten slots on a desktop and a TV, five on a touch screen, and in a small
-- desktop window ten while the compact strip fits, else five (2026-10-03, the
-- freely assignable hotbar). The count changes only when the MODE does, so
-- resizing or rotating a phone never takes a slot away from anybody.
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
-- Its nearest-clear-place search, for the buff popover (HudLayout.popoverRect).
local SpeedMilestones = require(script.Parent:WaitForChild("SpeedMilestones"))

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
	-- HOW MANY ACTIVE-BOOST ICONS STAND OVER THE STRIP (2026-10-04): measure
	-- reads it off the local player's GameConfig.BoostIcons.Attribute, which
	-- BoostIconsUI keeps. More than 0 puts the icon row just over the item
	-- name's band and the toast line over that; nil or 0 and the answer is
	-- exactly what it was with no icons. (It replaced the rain chip and the
	-- mini-event line, `rain` and `mini`, which the row now says as icons.)
	icons: number?,
	-- WHETHER A TRAP'S REMOVE BUTTON STANDS OVER THE STRIP (2026-10-04): measure
	-- reads it off the local player's GameConfig.Hotbar.RemoveRowAttribute,
	-- which LoadoutUI keeps. True reserves a row just over the strip (see THE
	-- REMOVE ROW) and stands the name band, the icon row and the toast over it;
	-- nil or false and the answer is exactly what it was without it.
	removeRow: boolean?,
	-- WHETHER THE PHONE'S PANEL UNDER THE BAG IS SHUT (2026-10-06): measure reads
	-- the local player's Phone.Panel.ShutAttribute (RailDrawerUI keeps it, for the
	-- session only). True leaves only the panel's handle standing; nil or false
	-- and the panel is open, as it opens by default.
	dockShut: boolean?,
	-- WHETHER THE x2 CARD SHOWS (2026-10-05): measure reads it the way CashUI
	-- decides it (GameConfig.cashMultiplier above 1). On a touch screen the card
	-- stands beside the cash line, and the belt keeps 8 px off it -- sliding over,
	-- or dropping its Bag cell, only where a narrow phone has no other room. nil
	-- or false and the answer is exactly what it was without the card.
	buff: boolean?,
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
	-- THE OTHER PLANTS SWITCH (OtherPlantsUI, 2026-10-05): Walk Mode's twin, a
	-- display preference -- OTHER PLANTS: ON over its track. On a desktop the
	-- rail's fifth row, under WALK MODE, the rail's 130 x 46; in compact as
	-- wide as its longer label (OthersCompact), at the right edge under WALK
	-- MODE (under EVENTS until 2026-10-09, and again where a window keeps
	-- Garden and the Bag top right); on a phone a see-through row under Shop,
	-- over WALK MODE's (2026-10-05).
	-- A group of its own everywhere but the desktop's rail (groups).
	others: Rect,
	-- THE EVENTS BUTTON (EventsUI, 2026-10-04), placed where nothing that shipped
	-- moves: on a desktop (and a TV) beside Settings, inside the rail's own
	-- band; in compact in the top-right corner since Garden and the Bag went to
	-- the left edge (2026-10-09) -- under the Bag at the right edge, 8 px under
	-- the top row, before that and still where a window keeps them top right.
	-- Not beside WALK MODE: that narrows the band the clock's row, TELEPORT,
	-- the boosts and the notices are centred in (HudLayoutSpec measured
	-- TELEPORT 38 px off centre in a 700 x 400 window). On a phone the second
	-- square of the panel under Index. Off a desktop it hides while a centre
	-- panel is open (EventsUI), as the phone's panel does.
	events: Rect,
	-- THE WHAT'S NEW BUTTON (UpdateLogUI, 2026-10-05): the update log's square,
	-- placed where nothing that shipped moves. On a desktop (and a TV) in the
	-- top-right corner (under the Bag until 2026-10-09); in compact under OTHER
	-- PLANTS, or under WALK MODE (EVENTS where Garden and the Bag stay top
	-- right) at the right edge, else under Index -- 50 x 50, or the touch
	-- floor's 44 x 44 where only that fits; an EMPTY rect where no spot clears
	-- everything, and the button then stays hidden, as OBBY does. A group of its
	-- own there. On a phone the second square of the panel under the Bag
	-- (2026-10-05). Off a desktop it hides while a centre panel is open
	-- (UpdateLogUI), as EVENTS does.
	updates: Rect,
	-- THE INVITE BUTTON (InviteUI, 2026-10-06): the owner's square picture. On a
	-- desktop (and a TV) in the rail's top row at its right end, beside Index --
	-- inside the band the 130-wide slabs left, clear of Index's badge -- so
	-- nothing that shipped moves; in compact the first spot under the row that
	-- clears everything (EMPTY, and hidden, where none does); on a phone the
	-- FIRST square of the panel under the Bag (the owner, 2026-10-06), at its
	-- place in the panel's canvas with the canvas scrolled to the top.
	invite: Rect,
	-- THE PANEL UNDER THE BAG SCROLLS AND SHUTS (the owner, 2026-10-06; a phone
	-- only, nil elsewhere). `dockView` is its scroll viewport and `dockCanvas`
	-- the squares' whole height -- more than the viewport where the squares
	-- would otherwise shrink under MinTile, so the panel scrolls instead.
	-- `dockShut`: only the handle stands, and `dock` is the handle alone.
	dockView: Rect?,
	dockCanvas: number?,
	dockShut: boolean?,
	-- GARDEN AND THE BAG (2026-10-09, the owner: "put them on center left"):
	-- at the left edge's middle, Garden over the Bag -- or side by side
	-- (`pairRow`: a phone, or a desktop short of the room for one over the
	-- other), Garden's badge then tucked level with its top. `gardenRight`: a
	-- window too small for either keeps the top-right row they had before
	-- (the Bag in the corner, Garden's badge on its top-LEFT corner).
	garden: Rect,
	bag: Rect,
	pairRow: boolean?,
	gardenRight: boolean?,
	-- Compact only: whether the pair has its room at the left edge (solve).
	pairFits: boolean?,
	-- INDEX, GARDEN AND THE BAG IN ONE COLUMN AT THE RIGHT EDGE (2026-10-09, the
	-- owner): one over another in that order -- on a phone under the panel's
	-- row, on a desktop and a TV on the safe area's middle. Their badges are
	-- tucked into their top-LEFT corners there (HudLayout.badges). nil or false
	-- in compact, which keeps the arrangement above.
	column: boolean?,
	-- The two top groups' band, for the things that have to step round them.
	railTop: number,
	railBottom: number,
	railRight: number,
	rightLeft: number,

	-- The strip at its widest: every live slot and the Bag cell.
	hotbar: Rect,
	chip: boolean,
	-- The item name's band just above the strip (LoadoutUI's popup, shown on
	-- an equip and under a mouse). Notices and the cash block keep clear of
	-- it as they do of the strip. Over the REMOVE row while that stands.
	namePopup: Rect,
	-- THE REMOVE ROW (2026-10-04): the strip-wide band just over the strip that
	-- a trap's REMOVE button stands in (HudLayout.removeButton), reserved only
	-- while Input.removeRow says it stands; nil otherwise.
	removeRow: Rect?,
	-- THE ACTIVE-BOOST ICON ROW (BoostIconsUI, 2026-10-04): centred over the
	-- strip, just above the name band, only while an icon stands (Input.icons).
	-- Notices keep clear of it: the toast line steps up over it. Nil with no
	-- icons. `iconSize` is one icon's drawn size and `iconColumns` how many
	-- stand in a row (a second row only where one cannot hold them all).
	icons: Rect?,
	iconSize: number,
	iconColumns: number,

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

	-- THE PHONE'S SIDEBARS (see below). False, and these rects nil, on a
	-- desktop and in compact, whose answers are exactly what they were.
	sidebar: boolean,
	-- On a phone the slim panel under the Bag that EVENTS, WHAT'S NEW and
	-- Settings stand down (the owner, 2026-10-05); until then the left edge's
	-- dock of Index, Shop and Settings.
	dock: Rect?,
	-- That old dock's handle, a press on its edge and, shut, on the safe area's
	-- edge: nil since the panel moved under the Bag, which does not shut.
	handle: Rect?,
	handleShut: Rect?,
	-- The x2 card as a button on a phone's top-right row: nil since the owner's
	-- mobile corrections (2026-10-05) stood it beside the cash line on every
	-- screen (`buffMinX`).
	boost: Rect?,

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
	-- The plate TELEPORT TO PLOT draws inside its touch area, before
	-- `teleportScale`: the touch area's own size everywhere but a phone, where
	-- each of the top row's plates, drawn at that scale, is exactly its touch
	-- area (THE PHONE'S TOP ROW, the mobile corrections of 2026-10-05).
	teleportPlate: Vector2,
	-- THE MOBILE CORRECTIONS (2026-10-05): on a touch screen the button says just
	-- PLOT, with no icon, and BIOMES and OBBY draw their plates at these sizes (the
	-- touch area's own size everywhere else). RETURN TO PLOT, the obby's button in
	-- TELEPORT's place, has a rect and a plate of its own: on a phone's row the
	-- span BIOMES and PLOT take (both hidden on the course), its words alone
	-- (`returnWide` false); everywhere else TELEPORT's own.
	teleportShort: boolean,
	biomesPlate: Vector2,
	obbyPlate: Vector2,
	returnPlot: Rect,
	returnPlate: Vector2,
	returnWide: boolean,
	-- THE x2 CARD ON A PHONE (2026-10-05): beside the cash line like everywhere
	-- else, never nearer the stick's zone than 8 px -- its leftmost place in the
	-- cash block's own units (CashUI); nil off a touch screen, where the face's
	-- BuffMinX decides.
	buffMinX: number?,
	-- THE SWITCHES ON A PHONE (2026-10-05): true on every touch screen, where
	-- WALK MODE and OTHER PLANTS are see-through rows under Shop, the words
	-- inline and a small switch at the row's end (Phone.Switch); false on every
	-- other screen, which keeps its label-over-track switches.
	switchInline: boolean,

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
	-- safe space. `rowEnd` is where the row's free span stops: 8 px short of ADMIN
	-- where it stands on the row, else of the clock (the chase warning's room).
	rowLo: number?,
	rowHi: number?,
	rowEnd: number?,
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
	-- the width (the ten-slot strip itself is 750).
	DesktopMinWidth = 900,
	-- THE FREELY ASSIGNABLE HOTBAR (2026-10-03): ten shortcuts, keys 1-9 and 0,
	-- on a desktop and a TV; the first five on a touch screen. A small desktop
	-- window gets ten while the compact strip fits and five where it does not.
	-- Slots 6-0 a phone does not show stay reachable from the Bag.
	DesktopSlots = 10,
	MobileSlots = 5,
	WalkHeight = 46,
	-- THE WALK MODE SWITCH OFF A DESKTOP (2026-10-04, the global UI pass): the
	-- horizontal switch, WALK MODE: OFF over its track, as wide as that label
	-- at the compact size and 46 tall like the desktop's. Off a desktop it
	-- stands by EVENTS: in compact left of it, on a phone under it (compact()
	-- and sidebars() say why).
	WalkCompact = Vector2.new(100, 46),
	-- THE OTHER PLANTS SWITCH OFF A DESKTOP (2026-10-05): OTHER PLANTS: OFF is
	-- 111 px at the compact label's 12 (LuckiestGuy, measured), so 118 wide --
	-- the same 3-4 px either side WALK MODE: OFF has in its 100 -- and 46 tall.
	OthersCompact = Vector2.new(118, 46),
	-- THE WHAT'S NEW BUTTON (2026-10-05): the rail's square, and the touch floor
	-- (the dock's MinTile) where only that fits. See Layout for where it stands.
	Updates = { Size = RAIL.SquareSize.X, Tight = 44 },
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
	BannerSize = Vector2.new(560, 84),
	BannerTop = 84,
	SkipSize = Vector2.new(150, 20),
	-- On a phone the tutorial's words -- the banner, the pointer and the
	-- celebration -- are drawn at this (owner, 2026-09-24; THE TUTORIAL BANNER).
	TutorialPhoneScale = 0.75,
	ClockTop = 8,
	ClockHeight = 34,
	-- The cycle icon beside the clock's words (2026-10-04, WorldClock): this
	-- square on the bar and this far from the words; the chip's are Phone's.
	ClockIcon = 26,
	ClockIconGap = 6,
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
	-- back over a tile. (The BATS / TRAPS sidebar and its chooser went with the
	-- freely assignable hotbar, 2026-10-03: a bat or a trap is any slot's.)
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
	-- Between the x2 button and Garden: room for Garden's tucked badge. (Neither
	-- stands in the phone's top row since 2026-10-09; kept for the readers.)
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
	-- the tutorial banner and a dropped notice keep 8 px off it.
	--==========================================================================
	-- 52 tall since 2026-09-27: one notice -- a headline and a one-line next
	-- step (ActionToastUI) -- rather than the old one-line pill. Older notices
	-- stand above it; see THE NOTICE STACK.
	Toast = { Width = 340, Height = 52, MinWidth = 200 },
	-- On a phone its plate is drawn at PhoneScale (TELEPORT TO PLOT ON A PHONE)
	-- and says just PLOT, in a touch area only as wide as that drawn plate
	-- (Phone.Row, the owner's mobile corrections of 2026-10-05).
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
	-- The clock as a chip, this wide. The row's three buttons beside it, each
	-- touch area as wide as its plate drawn at Teleport.PhoneScale (Row, below;
	-- until 2026-10-05 TELEPORT TO PLOT drew Teleport.Size there, 147 x 33).
	-- Under the row, in the safe area: the boost row, then the band every
	-- passing line shares (the notices, the biome name, the sale line). The
	-- guide's words stand in the left column.
	--==========================================================================
	Phone = {
		Clock = 124,
		-- The chip's cycle icon, at its left end, and its gap to the words.
		ClockIcon = 22,
		ClockIconGap = 4,
		--======================================================================
		-- THE ROW'S THREE BUTTONS (the owner's mobile corrections, 2026-10-05):
		-- BIOMES | PLOT | OBBY, the words alone, RowGap apart. Each plate before
		-- Teleport.PhoneScale -- 84 x 44 is 63 x 33 drawn -- and each touch area
		-- exactly as wide as its drawn plate and 44 tall, so the row reads as one
		-- even row and nothing pressable is wider than what is seen. RowTight
		-- where a topbar leaves the row less room; every touch area 44 or wider
		-- either way.
		--======================================================================
		RowGap = 5,
		Row = { Biomes = 84, Plot = 68, Obby = 72 },
		RowTight = { Biomes = 72, Plot = 60, Obby = 64 },
		-- UIKit.hudPlate's black edge (2.5, on the plate's border) draws OUTSIDE
		-- the plate: each plate is this much smaller on either side than its
		-- size above, so the outline's outer edge is the touch area's -- measured
		-- in Play 2026-10-05, plates of the full size left 1 px between outlines.
		RowStroke = 2.5,
		--======================================================================
		-- THE OWNER'S PHONE LAYOUT OF 2026-10-05 (the evening's mockup and its
		-- corrections; see THE PHONE'S SIDEBARS). The dock left the left edge:
		--
		--   Shop       the owner's wide studded picture (2094 x 751) in the
		--              top-left corner, 40 tall -- the picture's own aspect
		--   Index      the square picture, 44 x 44, at the top-right row's left
		--              end, where WHAT'S NEW stood
		--   Panel      a slim panel under the Bag with EVENTS, WHAT'S NEW and
		--              Settings (the third picture) down it: Tile-px squares, Pad
		--              inside and Gap between, never under MinTile where the jump
		--              button leaves a short phone less height
		--======================================================================
		Shop = Vector2.new(112, 40),
		Index = 44,
		--======================================================================
		-- INDEX, GARDEN AND THE BAG, ONE OVER ANOTHER UNDER THE PANEL'S ROW (the
		-- owner, 2026-10-09: "(Night Day) / <sidebar / Index / Garden /
		-- Inventory"): Size-px squares Gap apart, shrinking to fit the height
		-- down to the jump button's clearance, never under MinSize -- the
		-- panel's own rule (the owner: "~40 px"; 36 on 705 x 338).
		--======================================================================
		Column = { Size = 40, MinSize = 34, Gap = 6 },
		--======================================================================
		-- THEIR COUNT BADGES ON A PHONE (the owner, 2026-10-09: shrink them so
		-- the picture shows): a red pill Size px tall with its Stroke, as wide as
		-- its count needs at Text px (never under its height; Pad either side),
		-- on each square's top-RIGHT corner, Over px past it -- Index's level
		-- with its top, 8 px under the row. HudLayout reserves Reserve px of
		-- width (two digits); the pill grows leftward over its square.
		--======================================================================
		Badge = { Size = 22, Stroke = 2, Text = 12, Pad = 4, Over = 5, Reserve = 28 },
		--======================================================================
		-- THE PANEL UNDER THE BAG, SCROLLING AND SHUTTING (the owner,
		-- 2026-10-06): INVITE, EVENTS, WHAT'S NEW and Settings down it (Count),
		-- Tile-px squares that shrink no further than MinTile and SCROLL where
		-- even that leaves too little height; a HandleH-px handle on its top
		-- edge, HandleGap over the squares, that shuts it up under the Bag and
		-- opens it again -- shut, the handle alone stands. The choice lasts the
		-- session (ShutAttribute, client-local); the slide takes Slide seconds
		-- and the answer never waits for it.
		--======================================================================
		Panel = {
			Tile = 40,
			MinTile = 34,
			Pad = 3,
			Gap = 3,
			Count = 4,
			HandleH = 22,
			HandleGap = 3,
			ShutAttribute = "SeedDockShut",
			Slide = 0.2,
			-- AS A ROW (2026-10-09): how far right of the middle its left end
			-- stays at the least, so the boost row under the clock's row keeps the
			-- room for two boosts side by side (the widest pair is 378 px on a
			-- phone, 302 at BoostShrink; measured 2026-10-09). The squares shrink
			-- toward MinTile to keep it: 36 on the 640-px phones, Tile elsewhere.
			RowClear = 128,
			-- INVITE's "!" pinned to the top edge while the panel is scrolled
			-- (2026-10-06, HudLayout.invitePin): the client-local attribute
			-- RailDrawerUI raises while it shows (InviteUI hides its own then),
			-- and how much bigger than the "!" its press is, all round.
			PinAttribute = "SeedDockInvitePin",
			PinPad = 4,
		},
		--======================================================================
		-- THE TWO SWITCHES UNDER SHOP: OTHER PLANTS over WALK MODE, see-through
		-- rows -- no plate, the words outlined as every HUD word is -- W x H,
		-- the words inline at Label px (LuckiestGuy: OTHER PLANTS measures 71)
		-- PadLeft in, a Track-sized switch PadRight from the end with a Thumb-px
		-- thumb and its ON or OFF at Word px in the track. The whole row is the
		-- press, and the two are a group's 8 px apart (Gap).
		--======================================================================
		Switch = {
			W = 128,
			H = 28,
			Gap = 8,
			Label = 10,
			Word = 8,
			Track = Vector2.new(40, 18),
			Thumb = 19,
			PadLeft = 6,
			PadRight = 5,
		},
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
		MaxW = 860,
		MaxH = 600,
		MinW = 240,
		MinH = 160,
		-- A shell shorter than this puts the search box on the title's row.
		CompactBelow = 380,
		-- Where the body starts inside the shell, and what the header and the
		-- bottom margin take from its height, with the search row on the title's
		-- row and on its own row.
		BodyTopCompact = 58,
		BodyTop = 100,
		BodyTrimCompact = 70,
		BodyTrim = 112,
		--======================================================================
		-- THE COMPACT BAG (2026-10-03, the owner's compact grid)
		--
		-- Small square tiles: 96 x 100 on a desktop, 96 x 116 on a phone (a
		-- name two lines tall at a phone's larger type), 8 apart inside an
		-- 8-px pad. The five category buttons stand down a column on the left,
		-- 44 tall, never below 34 on the shortest phones; the storage line is a
		-- footer under the grid. The search box and the favourites heart run
		-- across the top: their own row under the title, or the title's row on a
		-- short screen, between the title and the close button.
		--======================================================================
		Tile = Vector2.new(96, 100),
		TileCompact = Vector2.new(96, 116),
		TileGap = 8,
		GridPad = 8,
		Column = 140,
		ColumnCompact = 112,
		ColumnGap = 8,
		CatH = 44,
		CatMinH = 34,
		CatGap = 4,
		CatGapCompact = 3,
		FooterH = 18,
		FooterGap = 4,
		SearchTop = 58,
		SearchTopCompact = 13,
		SearchH = 34,
		SearchMinW = 140,
		HeartW = 40,
		SearchGap = 6,
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
-- the hotbar is (0.5, 0, 1, -10), WHAT'S NEW's button (1, -12, 0, 12).
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
-- everything placed above the hotbar keeps clear of. `lift` is the REMOVE
-- row's reservation while it stands (removeLift), 0 or nil otherwise.
function HudLayout.namePopupOver(hotbar: Rect, lift: number?): Rect
	return rect(hotbar.x, hotbar.y - (lift or 0) - HOT.NamePopupGap - HOT.NamePopupHeight, hotbar.w,
		HOT.NamePopupHeight)
end

function HudLayout.hotbarBand(hotbar: Rect, lift: number?): Rect
	local reach = (lift or 0) + HOT.NamePopupGap + HOT.NamePopupHeight
	return rect(hotbar.x, hotbar.y - reach, hotbar.w, hotbar.h + reach)
end

--==============================================================================
-- THE REMOVE ROW (2026-10-04, the reusable-trap brief)
--
-- While a player has a trap out, a small REMOVE button stands just over the
-- trap's own hotbar slot -- whichever slot that is. It gets a row of its own
-- rather than a corner of somebody else's: the strip-wide band right over the
-- strip, RemoveGap above it, as tall as the drawn button on a mouse screen and
-- RemoveTouch tall on a touch screen (the button's target fills it, the plate
-- drawn at its bottom, hugging the slot). The item name's band, the boost icon
-- row and the notices all stand over the row while it is there, so none of
-- them ever lands on the button -- and the row is inside the strip's columns,
-- so it is as clear of the thumbstick and the jump button as the strip is.
-- With no trap out there is no row, and nothing else moves.
--==============================================================================
function HudLayout.removeRowHeight(touch: boolean): number
	return if touch then HOT.RemoveTouch else HOT.RemoveHeight
end

-- How far the name band and everything over it go up for the row: 0 without it.
local function removeLift(input: Input): number
	if input.removeRow ~= true then
		return 0
	end
	return HudLayout.removeRowHeight(input.touch) + HOT.RemoveGap
end

local function removeRowOver(input: Input, hotbar: Rect): Rect?
	if input.removeRow ~= true then
		return nil
	end
	local h = HudLayout.removeRowHeight(input.touch)
	return rect(hotbar.x, hotbar.y - HOT.RemoveGap - h, hotbar.w, h)
end

--==============================================================================
-- THE CONTEXT SLOT'S BUTTON (2026-10-10; GameConfig.ContextSlot)
--
-- DROP while a raid pod is carried, PLAY MINIGAME while the player rides their
-- own mill: in the strip's place while the strip steps aside, centred in its
-- rect -- as tall as the strip (or `maxHeight`, if lower) at the button's own
-- `aspect`, never wider than the strip. Inside the strip's rect, so it clears
-- everything the strip clears and nothing else moves.
--==============================================================================
function HudLayout.contextButton(L: Layout, aspect: number, maxHeight: number?): Rect
	local strip = L.hotbar
	local h = math.min(strip.h, maxHeight or math.huge)
	local w = math.min(h * aspect, strip.w)
	h = math.min(h, w / aspect)
	return rect(strip.x + (strip.w - w) / 2, strip.y + (strip.h - h) / 2, w, h)
end

-- Slot `index`'s square on the strip (1 is the left end), in the same space as
-- `L.hotbar`: the strip's cells run left to right from its own left edge.
function HudLayout.slotRect(L: Layout, index: number): Rect
	local H = L.hot
	return rect(L.hotbar.x + H.TrayPad + (index - 1) * (H.SlotWidth + H.Gap), L.hotbar.y + H.TrayPad,
		H.SlotWidth, H.SlotHeight)
end

--==============================================================================
-- THE REMOVE BUTTON OVER SLOT `index`: where a press lands, and the plate drawn
--
-- The plate is the slot's own width, RemoveHeight tall, RemoveGap over the slot.
-- The press lands on the whole row's height over that slot and half a gap
-- either side of it -- on a touch screen RemoveTouch + RemoveGap tall -- held
-- inside the strip's own columns. Nil while the layout has no REMOVE row.
--==============================================================================
function HudLayout.removeButton(L: Layout, index: number): (Rect?, Rect?)
	local row = L.removeRow
	if not row or index < 1 or index > L.slots then
		return nil, nil
	end
	local H = L.hot
	local slot = HudLayout.slotRect(L, index)
	local plate = rect(slot.x, slot.y - H.TrayPad - HOT.RemoveGap - HOT.RemoveHeight, slot.w, HOT.RemoveHeight)
	local x0 = math.max(L.hotbar.x, slot.x - H.Gap / 2)
	local x1 = math.min(L.hotbar.x + L.hotbar.w, slot.x + slot.w + H.Gap / 2)
	local press = rect(x0, row.y, x1 - x0, L.hotbar.y - row.y)
	return press, plate
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
-- THE ACTIVE-BOOST ICON ROW (2026-10-04)
--
-- Round icons, one per boost or event running for this player (BoostIconsUI),
-- side by side and centred over the strip, just above its name band -- the
-- rain chip's place, which the row replaced along with the mini-event line --
-- and the toast line steps up over the row so a notice never lands on it.
--
-- BOUNDED: the icons are the mode's size while they fit in `room` (the strip's
-- width, never under 200); past that they shrink, never under BoostIcons'
-- Min; and only past that do they take a second row, then a third -- at most
-- one per source in GameConfig.BoostIcons.Order, so the row can never grow
-- without end. Where something that shares its columns stands in its rows (a
-- lifted cash block in a narrow window, a thumb), it steps up over that.
-- Nil -- and nothing else moves -- with no icons.
--==============================================================================
local ICONS = GameConfig.BoostIcons

-- One icon's size, how many stand in a row, and how many rows, for `count`
-- icons in `room` px.
function HudLayout.iconGrid(count: number, room: number, size: number): (number, number, number)
	local gap, least = ICONS.Gap, ICONS.Size.Min
	if count <= 0 then
		return size, 0, 0
	end
	local fit = math.floor((room + gap) / (size + gap))
	if fit >= count then
		return size, count, 1
	end
	local shrunk = math.floor((room + gap) / count - gap)
	if shrunk >= least then
		return math.min(size, shrunk), count, 1
	end
	local columns = math.max(1, math.floor((room + gap) / (least + gap)))
	return least, columns, math.ceil(count / columns)
end

local function iconSizeFor(L: Layout): number
	return if L.sidebar then ICONS.Size.Phone elseif L.compact then ICONS.Size.Compact else ICONS.Size.Desktop
end

local function iconsOver(input: Input, L: Layout, band: Rect, beside: { Rect }?): (Rect?, number, number)
	local count = math.floor(input.icons or 0)
	local base = iconSizeFor(L)
	if count <= 0 then
		return nil, base, 0
	end
	local G = CONFIG.Gap
	local hotbar = L.hotbar
	local size, columns, rows = HudLayout.iconGrid(count, math.max(hotbar.w, CONFIG.Toast.MinWidth), base)
	local w = columns * size + (columns - 1) * ICONS.Gap
	local h = rows * size + (rows - 1) * ICONS.Gap
	-- ON A PHONE, OVER THE STRIP'S RIGHT END (2026-10-09, the owner: move it off
	-- the middle of the screen). Centred over the strip it stood on the
	-- character -- a short phone's strip is a hand under the middle -- and,
	-- with no disc behind its pictures any more, read like a crosshair there.
	-- Right-aligned with the strip's right end it stands beside the character,
	-- at the same height and on the same rules; its popover opens away from
	-- the beginner's guide card, which stands left (HudLayout.popoverRect).
	local x = if L.sidebar then hotbar.x + hotbar.w - w else hotbar.x + hotbar.w / 2 - w / 2
	local row = rect(x, band.y - G - h, w, h)
	if beside then
		for _ = 1, 3 do
			local lifted = false
			for _, other in ipairs(beside) do
				if other.w > 0 and HudLayout.gap(row, other) < G then
					row = rect(x, other.y - G - h, w, h)
					lifted = true
				end
			end
			if not lifted then
				break
			end
		end
	end
	return row, size, columns
end

local function withIcons(band: Rect, icons: Rect?): Rect
	return if icons then HudLayout.union(band, icons) else band
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
-- had. (Since the owner's mobile corrections of 2026-10-05 a phone's button
-- says just PLOT, and its touch area is only as wide as that drawn plate --
-- `width`, Phone.Row.Plot drawn: 51 x 44.) And it comes right up to the
-- clock: the DRAWN plate 8 px under it. That
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
local function teleportUnder(input: Input, clock: Rect?, rows: { Rect }, phone: boolean?, admin: Rect?,
	width: number?, lowered: boolean?): Rect
	local T, M, G = CONFIG.Teleport, CONFIG.Margin, CONFIG.Gap
	local sw = input.safe.X
	local insetTop = input.insetTop or 0
	-- `width`: a phone's PLOT, whose touch area is its plate drawn (2026-10-05).
	local w, h = width or T.Size.X, T.Size.Y
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
	-- `lowered`: a phone with no row keeps the three buttons on ONE row under the
	-- topbar (2026-10-05) -- PLOT's narrow plate would fit up under the clock
	-- where OBBY and BIOMES do not, and split them.
	if lowered then
		return underAdmin(at(M))
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
-- badge, the belt's toast and the guide's words, the touch controls, ADMIN and
-- the clock -- and `extra`, which BIOMES passes OBBY in.
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
	for _, maybe in ipairs({ { L.thumb }, { L.jump } }) do
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

-- Every rail badge's box: 26 px and the 2.5-px stroke round it (UIKit.badge,
-- HudLayout.badges).
local BADGE_BOX = 26 + 2.5 * 2

--==============================================================================
-- DESKTOP: THE GEOMETRY THAT SHIPPED
--==============================================================================
local function desktop(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local I, G = RAIL.Inset, CONFIG.Gap
	local wide, square = RAIL.WideSize, RAIL.SquareSize
	local row = wide.Y + RAIL.Gap

	-- Shop is the owner's wide studded picture since 2026-10-06, so it has the
	-- rail's whole 130 x 50 slot again -- the rail's own width: nothing beside or
	-- under it moves. Index stood in the rail's top-left corner, 50 x 50 (the
	-- owner's square artwork, 2026-09-24), until it joined Garden and the Bag at
	-- the right edge (2026-10-09, below); its corner stays empty, so nothing in
	-- the rail moves.
	local shop = rect(I, I + row, wide.X, wide.Y)
	local settings = rect(I, I + row * 2, square.X, square.Y)
	local walk = rect(I, I + row * 3, wide.X, CONFIG.WalkHeight)
	-- OTHER PLANTS (2026-10-05): the rail's fifth row, under WALK MODE, the
	-- rail's own 6 px under it and its own width -- one column of two switches.
	-- The rail's band (railBottom) is what it shipped as: nothing shares this
	-- row's height beside it.
	local others = rect(I, walk.y + walk.h + RAIL.Gap, wide.X, CONFIG.WalkHeight)
	-- Beside Settings, inside the band the 130-wide slabs left: the rail's
	-- footprint, and so everything placed round it, is what it was.
	local events = rect(I + square.X + RAIL.Gap, settings.y, square.X, square.Y)
	-- INVITE (2026-10-06): the top row's right end, the band's own width over
	-- Shop -- 30 px off Index, clear of its badge, until Index went to the right
	-- edge (2026-10-09); it stays where it was.
	local invite = rect(I + wide.X - square.X, I, square.X, square.Y)
	-- WHAT'S NEW: the top-right corner, where Garden stood until 2026-10-09 (it
	-- stood under the Bag before that) -- a group of its own. A desktop panel
	-- stops 8 px short of that column (rightLeft), so none ever covers it, and
	-- the left rail, its band and everything placed round them are what they were.
	local US = CONFIG.Updates.Size
	local updates = rect(sw - I - US, I, US, US)

	-- Ten shortcuts, keyboard or not: a console reaches them with LB and RB.
	local slots = CONFIG.DesktopSlots
	local chip = sw >= HOT.ChipMinViewport
	local width = HudLayout.hotbarWidth(slots, chip)
	local height = HudLayout.hotbarHeight()
	local hotbar = rect(sw / 2 - width / 2, sh - HOT.BottomGap - height, width, height)
	local band = HudLayout.hotbarBand(hotbar, removeLift(input))

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

	--==========================================================================
	-- INDEX, GARDEN AND THE BAG, ONE OVER ANOTHER AT THE RIGHT EDGE (the owner,
	-- 2026-10-09: "do not put sidebar on desktop, just on phone" -- only these
	-- three move here)
	--
	-- In WHAT'S NEW's column, on the safe area's middle, the rail's squares the
	-- rail's 6 px apart -- stepped down to 8 px under WHAT'S NEW and Index's
	-- badge (tucked into its top-LEFT corner, HudLayout.badges) where the middle
	-- would meet them, and up to 8 px over the strip's band, a trap's REMOVE row
	-- up, where that reaches the column. Index left the rail's top-left corner,
	-- and Garden and the Bag the left edge's middle (that afternoon's place,
	-- "put them on center left"); the rail, INVITE, EVENTS, WHAT'S NEW and
	-- Settings stand where they were. A desktop with no room for the column
	-- falls back to compact (HudLayout.problems), as any desktop that cannot
	-- hold its groups does.
	--==========================================================================
	local stackH = square.Y * 3 + RAIL.Gap * 2
	local stackX = sw - I - square.X
	local highest = updates.y + updates.h + G + CONFIG.BadgeHang + 2.5
	local lowest = sh - CONFIG.Margin
	local worst = HudLayout.hotbarBand(hotbar, HudLayout.removeRowHeight(input.touch) + HOT.RemoveGap)
	if worst.x + worst.w + G > stackX then
		lowest = math.min(lowest, worst.y - G)
	end
	local sy = math.max(highest, math.min(lowest - stackH, math.floor(sh / 2 - stackH / 2)))
	local index = rect(stackX, sy, square.X, square.Y)
	local garden = rect(stackX, sy + square.Y + RAIL.Gap, square.X, square.Y)
	local bag = rect(stackX, sy + (square.Y + RAIL.Gap) * 2, square.X, square.Y)

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
		others = others,
		events = events,
		updates = updates,
		invite = invite,
		garden = garden,
		bag = bag,
		pairRow = false,
		gardenRight = false,
		column = true,
		railTop = I,
		railBottom = walk.y + walk.h,
		railRight = I + wide.X,
		-- The right edge's column: WHAT'S NEW in the corner and Index, Garden and
		-- the Bag on the middle (2026-10-09), all at the x Garden's always was.
		rightLeft = updates.x,
		hotbar = hotbar,
		chip = chip,
		namePopup = HudLayout.namePopupOver(hotbar, removeLift(input)),
		removeRow = removeRowOver(input, hotbar),
		icons = nil,
		iconSize = ICONS.Size.Desktop,
		iconColumns = 0,
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
		toast = rect(0, 0, 0, 0),
		teleport = rect(0, 0, 0, 0),
		teleportScale = 1,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = CONFIG.Teleport.Size,
		-- As they always were off a touch screen (the mobile corrections are a
		-- phone's): TELEPORT TO PLOT with its icon, each plate its touch area,
		-- RETURN TO PLOT in TELEPORT's own place (set after it).
		teleportShort = false,
		biomesPlate = Vector2.new(0, 0),
		obbyPlate = Vector2.new(0, 0),
		returnPlot = rect(0, 0, 0, 0),
		returnPlate = CONFIG.Teleport.Size,
		returnWide = true,
		buffMinX = nil,
		switchInline = false,
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
		HudLayout.union(HudLayout.union(shop, HudLayout.union(settings, walk)),
			HudLayout.union(HudLayout.union(events, others), invite)),
		HudLayout.union(index, bag),
		updates,
	})
	L.icons, L.iconSize, L.iconColumns = iconsOver(input, L, band, nil)
	L.toast = toastAbove(sw, withIcons(band, L.icons), { cash })
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
	L.obbyPlate = Vector2.new(L.obby.w, L.obby.h)
	L.biomesPlate = Vector2.new(L.biomes.w, L.biomes.h)
	L.returnPlot = L.teleport
	L.returnPlate = L.teleportPlate
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
local function beltBetween(input: Input, thumb: Rect?, jump: Rect?, slots: number, left: number?,
	right: number?): (Rect, boolean, boolean)
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local height = HudLayout.hotbarHeight(true)
	local bottom = sh - HOT.BottomGap
	local lo, hi = M, sw - M
	if thumb and jump then
		lo, hi = thumb.x + thumb.w + G, jump.x - G
	end
	-- A phone's x2 card beside the cash line, and a switch row sharing the
	-- band, as far as the belt may reach either way (sidebars, 2026-10-05).
	if left then
		lo = math.max(lo, left)
	end
	if right then
		hi = math.min(hi, right)
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
-- THE OTHER PLANTS SWITCH OFF A DESKTOP: THE FIRST SPOT THAT IS CLEAR
-- (2026-10-05)
--
-- `spots` in order of preference; the first that keeps 8 px clear of every rect
-- in `keep` -- measured against the belt's band as it stands with a trap's
-- REMOVE row up (worstBand), so the switch never moves when a trap is taken
-- out. Where none is clear of that (a 560 x 320 window), the first clear of the
-- band without the row: still the same spot whether a trap is out or not, the
-- row's lifted name band passing over it for a moment; where none is clear even
-- of that, the first spot, and the spec says so.
--==============================================================================
local function firstClear(spots: { Rect }, keep: { Rect }, worst: Rect, plain: Rect): Rect
	local G = CONFIG.Gap
	for _, band in ipairs({ worst, plain }) do
		for _, spot in ipairs(spots) do
			local clear = HudLayout.gap(spot, band) >= G
			for _, other in ipairs(keep) do
				if clear and HudLayout.gap(spot, other) < G then
					clear = false
				end
			end
			if clear then
				return spot
			end
		end
	end
	return spots[1]
end

-- The belt's band with a trap's REMOVE row up, whatever the input says now.
local function worstBand(input: Input, hotbar: Rect): Rect
	return HudLayout.hotbarBand(hotbar, HudLayout.removeRowHeight(input.touch) + HOT.RemoveGap)
end

--==============================================================================
-- THE WHAT'S NEW BUTTON OFF A DESKTOP: THE FIRST SPOT THAT IS CLEAR, OR NONE
-- (2026-10-05)
--
-- `spots` in order of preference: each place at the rail's square, then each
-- again at the touch floor (sizedSpots). The first inside the margin that keeps
-- 8 px clear of every rect in `keep` -- which carries the belt's band as it
-- stands with a trap's REMOVE row up, so the button never moves when a trap is
-- taken out and the lifted name band never passes over it. Unlike firstClear
-- there is no second band and no fallback: where no spot is clear the answer is
-- an empty rect and the button stays hidden. A shortcut to the update log is
-- not worth covering anything for (OBBY's rule).
--==============================================================================
local function sizedSpots(makers: { (number) -> Rect }): { Rect }
	local spots: { Rect } = {}
	for _, side in ipairs({ CONFIG.Updates.Size, CONFIG.Updates.Tight }) do
		for _, make in ipairs(makers) do
			table.insert(spots, make(side))
		end
	end
	return spots
end

local function firstFree(spots: { Rect }, keep: { Rect }, safe: Vector2): Rect
	local M, G = CONFIG.Margin, CONFIG.Gap
	for _, spot in ipairs(spots) do
		local clear = spot.x >= M and spot.y >= M and spot.x + spot.w <= safe.X - M
			and spot.y + spot.h <= safe.Y - M
		for _, other in ipairs(keep) do
			if clear and other.w > 0 and HudLayout.gap(spot, other) < G then
				clear = false
			end
		end
		if clear then
			return spot
		end
	end
	return rect(0, 0, 0, 0)
end

--==============================================================================
-- COMPACT
--==============================================================================
local function compact(input: Input, keepRight: boolean?): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local B, g = RAIL.SquareSize.X, RAIL.Gap
	local fits = true

	--==========================================================================
	-- THE TOP ROWS
	--
	-- Three 50 x 50 buttons across the top left, in the order they used to run
	-- down it, at the rail's own 6 px gap. Top right, since Garden and the Bag
	-- went to the left edge (2026-10-09, below): EVENTS in the corner, where the
	-- Bag stood -- it stood under the Bag, 8 px under the row, before that.
	--
	-- `keepRight` (HudLayout.solve): a window too small for Garden and the Bag
	-- at the left edge keeps the top-right row they had until 2026-10-09 --
	-- Garden and the Bag in it, the Bag in the corner, EVENTS under the Bag.
	--==========================================================================
	local function cell(i: number): Rect
		return rect(M + (i - 1) * (B + g), M, B, B)
	end
	local index, shop, settings = cell(1), cell(2), cell(3)
	local garden, bag = rect(0, 0, 0, 0), rect(0, 0, 0, 0)
	local events: Rect
	if keepRight then
		bag = rect(sw - M - B, M, B, B)
		garden = rect(bag.x - g - B, M, B, B)
		events = rect(bag.x, M + B + G, B, B)
	else
		events = rect(sw - M - B, M, B, B)
	end
	--==========================================================================
	-- WALK MODE, THE HORIZONTAL SWITCH (2026-10-04, the global UI pass)
	--
	-- WALK MODE: OFF over its track is as wide as its label (WalkCompact), two
	-- squares where the switch was one. In the row it pushed TELEPORT 32 px
	-- off the clock's centre in a 700 x 400 window and left OBBY no room, as a
	-- fifth cell once did; under Index it stood where a short window lifts the
	-- cash block over the strip. So it stands UNDER EVENTS at the right edge,
	-- 8 px under the row -- left of EVENTS in that row until EVENTS went up to
	-- the corner (2026-10-09), and still where Garden and the Bag stay top
	-- right -- a group of its own like EVENTS, and like EVENTS it steps aside
	-- while a panel is open (WalkModeUI), the Bag's panel taking the whole
	-- width here. The row keeps its ends: railRight is Settings' edge.
	--==========================================================================
	local walk = if keepRight
		then rect(events.x - G - CONFIG.WalkCompact.X, M + B + G, CONFIG.WalkCompact.X, CONFIG.WalkCompact.Y)
		else rect(sw - M - CONFIG.WalkCompact.X, events.y + events.h + G, CONFIG.WalkCompact.X, CONFIG.WalkCompact.Y)
	-- The right edge's second row: WALK MODE under EVENTS, or EVENTS under the
	-- Bag where Garden and the Bag stay top right. OTHER PLANTS and WHAT'S NEW
	-- stand under it.
	local second = if keepRight then events else walk
	local railBottom = M + B

	local thumb: Rect?, jump: Rect? = nil, nil
	if input.touch then
		thumb, jump = HudLayout.touchZones(input.safe)
	end

	-- THE HOTBAR: see beltBetween. A touch screen has five; a desktop window
	-- that is merely small keeps the keyboard's ten while the compact strip
	-- fits across it (556 px), and five where it does not.
	local slots = if input.touch then CONFIG.MobileSlots
		elseif HudLayout.hotbarWidth(CONFIG.DesktopSlots, false, true) <= sw - M * 2 then CONFIG.DesktopSlots
		else CONFIG.MobileSlots
	local hotbar, chip, stripFits = beltBetween(input, thumb, jump, slots)
	local band = HudLayout.hotbarBand(hotbar, removeLift(input))
	if not stripFits then
		fits = false
	end

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

	--==========================================================================
	-- GARDEN ABOVE THE BAG, CENTRE LEFT (2026-10-09, the owner: "also lower the
	-- garden and inventory, put them on center left")
	--
	-- At the left edge, on the safe area's middle -- stepped down where the
	-- middle would meet the top row (8 px under it and Garden's tucked badge),
	-- and up off the cash block where it would meet that -- the block as a
	-- trap's REMOVE row lifts it, so the pair never moves when a trap comes
	-- out. INVITE and WHAT'S NEW, placed below, keep clear of the pair. A
	-- window that leaves no room is not a fit, and HudLayout.solve keeps that
	-- window's pair top right instead (keepRight).
	--==========================================================================
	local pairFits = true
	if not keepRight then
		local worstCashTop = cash.y
		if hotbar.x < cx + cw + G then
			worstCashTop = math.min(cash.y, worstBand(input, hotbar).y - G - ch)
		end
		local pairH = B * 2 + g
		local lowest = railBottom + G + CONFIG.BadgeHang + 2.5
		local highest = worstCashTop - G - pairH
		if highest < lowest then
			fits = false
			pairFits = false
		end
		local gy = math.max(lowest, math.min(highest, math.floor(sh / 2 - pairH / 2)))
		garden = rect(M, gy, B, B)
		bag = rect(M, gy + B + g, B, B)
	end

	--==========================================================================
	-- OTHER PLANTS (2026-10-05): AT THE RIGHT EDGE UNDER THE SECOND ROW
	--
	-- Its longer label (OthersCompact) in the top row would meet TELEPORT and
	-- OBBY's band. So: at the right edge under the second row's button (WALK
	-- MODE; EVENTS where Garden and the Bag stay top right), 8 px under it on
	-- the safe edge -- clear of both and of the tutorial banner -- and, in a
	-- window too short for that over the belt's name band (560 x 320), beside
	-- WALK MODE in its row, or under it where Garden and the Bag stay top
	-- right. A group of its own; it steps aside with WALK MODE while a panel is
	-- open.
	--==========================================================================
	local OC = CONFIG.OthersCompact
	local others = firstClear({
		rect(sw - M - OC.X, second.y + second.h + G, OC.X, OC.Y),
		if keepRight
			then rect(walk.x + walk.w - OC.X, walk.y + walk.h + G, OC.X, OC.Y)
			else rect(walk.x - G - OC.X, walk.y, OC.X, OC.Y),
	}, { walk, events, HudLayout.union(garden, bag), cash }, worstBand(input, hotbar),
		HudLayout.hotbarBand(hotbar, 0))

	--==========================================================================
	-- WHAT'S NEW (2026-10-05): THE RIGHT EDGE, ELSE UNDER INDEX
	--
	-- Under OTHER PLANTS at the right edge, 8 px under it; under WALK MODE where
	-- OTHER PLANTS stands beside it instead (560 x 320) -- under EVENTS, the
	-- squares' column, until the corner took EVENTS (2026-10-09). In a window
	-- where the belt's band, a trap's REMOVE row up, comes within 8 px of that
	-- spot, under Index, below the row's first cell, wherever Garden and the Bag
	-- leave it room. Not in the row (TELEPORT off the clock's centre, as EVENTS
	-- measured), and not beside WALK MODE or OTHER PLANTS (TELEPORT and OBBY's
	-- band, the tutorial banner).
	--==========================================================================
	local updatesKeep: { Rect } = { HudLayout.union(HudLayout.union(index, shop), settings),
		HudLayout.union(garden, bag), events, walk, others, cash, worstBand(input, hotbar) }
	if thumb then
		table.insert(updatesKeep, thumb)
	end
	if jump then
		table.insert(updatesKeep, jump)
	end
	local updates = firstFree(sizedSpots({
		function(s: number): Rect
			return rect(others.x + others.w - s, others.y + others.h + G, s, s)
		end,
		function(s: number): Rect
			return rect(second.x + second.w - s, second.y + second.h + G, s, s)
		end,
		function(s: number): Rect
			return rect(index.x, index.y + index.h + G, s, s)
		end,
	}), updatesKeep, input.safe)

	--==========================================================================
	-- INVITE (2026-10-06): UNDER THE ROW, THE FIRST CELL THAT CLEARS
	--
	-- Not in the row: a fourth cell is what pushed TELEPORT off the clock's
	-- centre (WALK MODE's note). Under Index, under Shop or under Settings --
	-- WHAT'S NEW's last refuge is under Index, so it is kept clear of that too --
	-- 50 x 50, or the touch floor's 44 x 44; EMPTY, and hidden, where none clears.
	--==========================================================================
	local inviteKeep: { Rect } = table.clone(updatesKeep)
	if updates.w > 0 then
		table.insert(inviteKeep, updates)
	end
	-- Its "!" hangs this far over its top edge (HudLayout.inviteBadge), so the
	-- square stands that much lower to keep the badge, too, 8 px off the row.
	local hangBelow = G + CONFIG.BadgeHang + 2.5
	local invite = firstFree(sizedSpots({
		function(s: number): Rect
			return rect(index.x, index.y + index.h + hangBelow, s, s)
		end,
		function(s: number): Rect
			return rect(shop.x, shop.y + shop.h + hangBelow, s, s)
		end,
		function(s: number): Rect
			return rect(settings.x, settings.y + settings.h + hangBelow, s, s)
		end,
	}), inviteKeep, input.safe)

	-- THE TUTORIAL BANNER: see bannerIn. Round Walk Mode's switch too, which
	-- stands under the row, and OTHER PLANTS by it -- and WHAT'S NEW and INVITE.
	local beside: { Rect } = { cash, walk, others }
	if updates.w > 0 then
		table.insert(beside, updates)
	end
	if invite.w > 0 then
		table.insert(beside, invite)
	end
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
		others = others,
		events = events,
		updates = updates,
		invite = invite,
		garden = garden,
		bag = bag,
		pairRow = false,
		gardenRight = keepRight == true,
		pairFits = pairFits,
		railTop = M,
		railBottom = railBottom,
		railRight = settings.x + settings.w,
		-- The row's right end: EVENTS alone since 2026-10-09; Garden where a
		-- window keeps Garden and the Bag top right.
		rightLeft = if keepRight then garden.x else events.x,
		hotbar = hotbar,
		chip = chip,
		namePopup = HudLayout.namePopupOver(hotbar, removeLift(input)),
		removeRow = removeRowOver(input, hotbar),
		icons = nil,
		iconSize = ICONS.Size.Compact,
		iconColumns = 0,
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
		toast = rect(0, 0, 0, 0),
		teleport = rect(0, 0, 0, 0),
		teleportScale = 1,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = CONFIG.Teleport.Size,
		-- As they always were off a touch screen (the mobile corrections are a
		-- phone's): TELEPORT TO PLOT with its icon, each plate its touch area,
		-- RETURN TO PLOT in TELEPORT's own place (set after it).
		teleportShort = false,
		biomesPlate = Vector2.new(0, 0),
		obbyPlate = Vector2.new(0, 0),
		returnPlot = rect(0, 0, 0, 0),
		returnPlate = CONFIG.Teleport.Size,
		returnWide = true,
		buffMinX = nil,
		switchInline = false,
		clockChip = false,
		topRow = false,
		run = rect(0, 0, 0, 0),
		toastTop = false,
		guide = false,
		admin = nil,
	}
	L.clock = clockRect(input, L)
	L.admin = adminBeside(input, L.clock)
	local rows: { Rect } = {
		HudLayout.union(HudLayout.union(index, shop), settings),
		HudLayout.union(garden, bag),
		events,
		walk,
		others,
	}
	if updates.w > 0 then
		table.insert(rows, updates)
	end
	L.teleport = teleportUnder(input, L.clock, rows)
	-- The tutorial banner keeps 8 px under the teleport button as well as the rows.
	L.banner, L.skip = bannerIn(sw, math.max(railBottom, L.teleport.y + L.teleport.h), beside)
	L.icons, L.iconSize, L.iconColumns = iconsOver(input, L, band, beside)
	L.toast = toastAbove(sw, withIcons(band, L.icons), beside)
	L.fits = L.fits and #HudLayout.problems(L) == 0
	L.obby, L.obbyWide = obbyBeside(input, L)
	L.biomes, L.biomesWide = biomesBeside(input, L)
	L.obbyPlate = Vector2.new(L.obby.w, L.obby.h)
	L.biomesPlate = Vector2.new(L.biomes.w, L.biomes.h)
	L.returnPlot = L.teleport
	L.returnPlate = L.teleportPlate
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
--   BIOMES | PLOT | OBBY | ... | ADMIN | the clock, as a chip
--
--   * THE BUTTONS stand with PLOT on the screen's centre line (the owner,
--     2026-10-05 evening), and start at the row's left end, 8 px after
--     Roblox's buttons, only where that has no room (phoneRow).
--     Since the owner's mobile corrections (2026-10-05) they are one even row:
--     the words alone -- TELEPORT TO PLOT says just PLOT, no icon -- each plate
--     drawn at Teleport.PhoneScale and each touch area exactly that plate,
--     Phone.RowGap (5 px) apart (Phone.Row; Phone.RowTight on a tighter row).
--     They were 8 px apart in touch areas up to a quarter wider than what was
--     drawn, which read as gaps of 20 px and more. RETURN TO PLOT is TELEPORT's
--     button on the course, over the span BIOMES and PLOT take there (both are
--     hidden on the course: `returnPlot`), and the run's clock has OBBY's slot
--     (`run`): the button is hidden on the course.
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
	-- Each button's plate before Teleport.PhoneScale, and RETURN TO PLOT's span
	-- over BIOMES and PLOT with its plate (the mobile corrections, 2026-10-05).
	biomesPlate: Vector2?,
	teleportPlate: Vector2?,
	obbyPlate: Vector2?,
	back: Rect?,
	backPlate: Vector2?,
	-- True where PLOT stands on the screen's centre line (2026-10-05).
	centred: boolean?,
	-- The row's two ends and the centre column's middle, in safe space, and where
	-- its free span stops (8 px short of ADMIN on the row, else of the clock).
	lo: number,
	hi: number,
	centre: number,
	stop: number?,
}

local function phoneRow(input: Input, band: { railTop: number, railRight: number, rightLeft: number }): PhoneRow
	local M, G = CONFIG.Margin, CONFIG.Gap
	local P, T, A = CONFIG.Phone, CONFIG.Teleport, CONFIG.Admin
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
	-- THE SIZES, Row before RowTight and ADMIN on the row before either: every
	-- listed phone holds the even row with ADMIN on it. Without room for ADMIN as
	-- well it hangs under the row's middle, 8 px under the buttons' touch areas.
	--
	-- While a chase is on the three are hidden (they are for the Safe Zone
	-- only), so the warning has the row's whole free span (`stop`; statusLine).
	--==========================================================================
	--==========================================================================
	-- PLOT ON THE SCREEN'S CENTRE LINE (the owner, 2026-10-05: "the centered
	-- one is the PLOT"), BIOMES left of it and OBBY right of it -- in every tier
	-- where that keeps BIOMES after the row's left end and OBBY short of its
	-- stop. Only where no tier allows it does the row start at its left end, as
	-- it did before.
	--==========================================================================
	local k = T.PhoneScale
	local gap = P.RowGap
	local tiers = { { P.Row, true }, { P.RowTight, true }, { P.Row, false }, { P.RowTight, false } }
	for _, centred in ipairs({ true, false }) do
		for _, tier in ipairs(tiers) do
			local sizes, withAdmin = tier[1], tier[2]
			local bw, pw, ow = sizes.Biomes * k, sizes.Plot * k, sizes.Obby * k
			local stop = if withAdmin then clock.x - G - aw - G else clock.x - G
			local bx = lo
			if centred then
				bx = viewport.X / 2 - pw / 2 - gap - bw
			end
			local tx = bx + bw + gap
			local ox = tx + pw + gap
			if bx >= lo - 1e-6 and ox + ow <= stop + 1e-6 then
				local y = touchTop - insetTop
				answer.clock = clock
				answer.biomes = rect(bx - originX, y, bw, T.Size.Y)
				answer.teleport = rect(tx - originX, y, pw, T.Size.Y)
				answer.obby = rect(ox - originX, y, ow, T.Size.Y)
				answer.biomesWide, answer.obbyWide = false, false
				answer.centred = centred
				-- Each plate inset by its outline (RowStroke), so what is drawn ends
				-- exactly at the touch area's edge.
				local edge = P.RowStroke * 2
				answer.biomesPlate = Vector2.new(sizes.Biomes - edge, T.Size.Y - edge)
				answer.teleportPlate = Vector2.new(sizes.Plot - edge, T.Size.Y - edge)
				answer.obbyPlate = Vector2.new(sizes.Obby - edge, T.Size.Y - edge)
				answer.back = rect(bx - originX, y, tx + pw - bx, T.Size.Y)
				answer.backPlate = Vector2.new((tx + pw - bx) / k - edge, T.Size.Y - edge)
				answer.stop = stop - originX
				answer.admin = if withAdmin then rect(clock.x - G - aw, ay, aw, ah)
					else rect(centre - aw / 2, touchTop + T.Size.Y + G, aw, ah)
				return answer
			end
		end
	end
	return answer
end

--==============================================================================
-- THE PHONE'S SIDEBARS
--
-- On any TOUCH screen: the owner's approved mockup of 2026-09-23 (Steal an
-- Artifact/output/imagegen/podnappers-mobile-sidebar-mockup-v2.png) as the
-- owner rearranged it on 2026-10-05 (output/mobile-hud-2026-10-05/
-- mockup_v2_proposal.png and the corrections to it):
--
--   top left      SHOP, the owner's wide studded picture, in the corner, and
--                 under it OTHER PLANTS and WALK MODE as two see-through rows:
--                 high on the edge, well clear of the movement stick.
--   top right     the slim panel -- INVITE, EVENTS, WHAT'S NEW and Settings
--                 (the third picture) -- as ONE ROW under the clock's chip, its
--                 "<" handle at the row's left end folding it away to the right
--                 edge (the owner, 2026-10-09). RailDrawerUI draws it and hides
--                 it, with what stands in it, while a centre panel is open.
--   under it      Index, Garden and the Bag, one over another in that order,
--                 at the right edge (2026-10-09). Until that evening Index stood
--                 alone in the corner with the panel down the edge under it, and
--                 Garden and the Bag side by side at the left edge.
--   bottom        the belt, five freely assigned slots (2026-10-03; the BATS
--                 / TRAPS panel and its chooser went: a bat is any slot's).
--   bottom left   cash and speed in the phone's face (compact at 0.85), in the
--                 very corner, 12 in and 10 up, on the thumbstick's resting
--                 ring by the owner's approval (2026-09-24); over the belt only
--                 where the corner would meet it.
--
-- Until then the left edge held a dock of Index, Shop and Settings with a
-- handle that shut it, and the switches stood under EVENTS at the right edge.
--==============================================================================
local function sidebars(input: Input): Layout
	local sw, sh = input.safe.X, input.safe.Y
	local M, G = CONFIG.Margin, CONFIG.Gap
	local P = CONFIG.Phone
	local fits = true
	local thumb, jump = HudLayout.touchZones(input.safe)

	--==========================================================================
	-- THE TOP-RIGHT CORNER: THE PANEL'S ROW, AND INDEX, GARDEN AND THE BAG UNDER
	-- IT (the owner, 2026-10-09: "now in mobile, i want to transfer the sidebar
	-- below the night/day ui, and it should show sideways", drawn as "(Night
	-- Day) / <sidebar / Index / Garden / Inventory")
	--
	-- Under the clock's chip, which stands at the top row's right end: the panel
	-- -- INVITE, EVENTS, WHAT'S NEW and Settings -- as ONE ROW in the safe area's
	-- top-right corner, Panel.Tile squares with Pad inside and Gap apart, and its
	-- handle, a "<", at the row's LEFT end, HandleGap off it. Shut, the row folds
	-- away to the right edge and the handle alone stands there. The row never
	-- scrolls: every listed phone holds it whole.
	--
	-- 8 px under the row, Index, Garden and the Bag one over another in that
	-- order (Phone.Column; INDEX, GARDEN AND THE BAG, below, once the belt is
	-- known), centred under the row's last square.
	--
	-- From 2026-10-05 the panel ran DOWN the right edge under Index in the
	-- corner, scrolling, with an up/down handle on its top edge; Garden and the
	-- Bag stood at the left edge from the morning of 2026-10-09.
	--==========================================================================
	local PP = P.Panel
	-- Tile-px squares where the row's left end stays RowClear right of the
	-- middle, else smaller to keep it there, never under MinTile. Across now;
	-- down once ADMIN's place is known (THE ROW'S TOP, below).
	local fixed = M + PP.HandleH + PP.HandleGap + PP.Gap * (PP.Count - 1) + PP.Pad * 2
	local tileSize = math.clamp(math.floor((sw / 2 - PP.RowClear - fixed) / PP.Count), PP.MinTile, PP.Tile)
	local rowH = tileSize + PP.Pad * 2
	local canvas = tileSize * PP.Count + PP.Gap * (PP.Count - 1) + PP.Pad * 2
	local viewX = sw - M - canvas
	local handleX = viewX - PP.HandleGap - PP.HandleH

	--==========================================================================
	-- THE TOP-LEFT CORNER: SHOP, AND THE TWO SWITCHES UNDER IT
	--
	-- Shop in the corner at its picture's own aspect; OTHER PLANTS 8 px under
	-- it and WALK MODE 8 px under that, see-through rows (Phone.Switch) on the
	-- margin -- up where a thumb on the movement stick never reaches, 8 px over
	-- the thumbstick's zone at the least.
	--==========================================================================
	local shop = rect(M, M, P.Shop.X, P.Shop.Y)
	local SW = P.Switch
	local others = rect(M, shop.y + shop.h + G, SW.W, SW.H)
	local walk = rect(M, others.y + others.h + SW.Gap, SW.W, SW.H)
	if walk.y + walk.h + G > thumb.y then
		fits = false
	end
	local railRight = math.max(shop.x + shop.w, others.x + others.w, walk.x + walk.w)

	-- THE BELT: see beltBetween. Five slots on a phone; the x2 card may move it
	-- (CASH AND SPEED, below).
	local plainBelt, plainChip, plainFits = beltBetween(input, thumb, jump, CONFIG.MobileSlots)

	--==========================================================================
	-- THE CLOCK, AND THE TELEPORT BUTTON ON ITS ROW (2026-09-29)
	--
	-- THE PHONE'S TOP ROW, above. Where the row has no room
	-- for the three buttons and the clock -- a topbar whose free span is very
	-- narrow -- TELEPORT stands under the clock with OBBY and BIOMES beside it
	-- there (obbyBeside, biomesBeside, below), as every phone's did before the
	-- row.
	--==========================================================================
	local row = phoneRow(input, { railTop = M, railRight = railRight, rightLeft = handleX })
	local clock, admin = row.clock, row.admin
	local inRow = row.teleport ~= nil
	if not inRow then
		admin = adminBeside(input, clock)
	end

	--==========================================================================
	-- THE ROW'S TOP: the margin -- or 8 px under ADMIN where ADMIN hangs under
	-- the clock into the corner (a phone whose top row cannot hold the buttons:
	-- 430 x 500 with Roblox's buttons out to 250). On the row ADMIN never
	-- reaches it: the row's left end keeps RowClear right of the middle.
	--==========================================================================
	local rowTop = M
	local viewport = input.viewport
	if admin and viewport then
		local a = rect(admin.x - (viewport.X - sw) / 2, admin.y - (input.insetTop or 0), admin.w, admin.h)
		if HudLayout.gap(a, rect(handleX, M, sw - M - handleX, rowH)) < G then
			rowTop = a.y + a.h + G
		end
	end
	local dockView = rect(viewX, rowTop, canvas, rowH)
	local railBottom = rowTop + rowH
	local handleOpen = rect(handleX, rowTop, PP.HandleH, rowH)
	local shut = input.dockShut == true
	local handle = if shut then rect(sw - M - PP.HandleH, rowTop, PP.HandleH, rowH) else handleOpen
	local dock = if shut then handle else HudLayout.union(handleOpen, dockView)
	local function tile(i: number): Rect
		return rect(viewX + PP.Pad + (i - 1) * (tileSize + PP.Gap), rowTop + PP.Pad, tileSize, tileSize)
	end
	local invite, events, updates, settings = tile(1), tile(2), tile(3), tile(4)

	local teleport: Rect
	-- PLOT's plate wherever it stands on a phone (the mobile corrections): the
	-- row's, or Row's own under the clock -- its outline the touch area's edge.
	local rowEdge = CONFIG.Phone.RowStroke * 2
	local plotPlate = row.teleportPlate
		or Vector2.new(CONFIG.Phone.Row.Plot - rowEdge, CONFIG.Teleport.Size.Y - rowEdge)
	if row.teleport then
		teleport = row.teleport
	else
		teleport = teleportUnder(input, clock, { shop, others, walk, dock },
			true, admin, CONFIG.Phone.Row.Plot * CONFIG.Teleport.PhoneScale, true)
	end

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
	-- it, the block stands 8 px over the belt's top line instead. Shop and the
	-- switches stand above the thumbstick's zone, so the corner never reaches
	-- them.
	--
	-- THE x2 CARD BESIDE THE CASH LINE (the owner's mobile corrections,
	-- 2026-10-05). It was the top-right row's first button; now it rides the
	-- cash text as it does everywhere else (CashUI), drawn with no plate. It is
	-- the one thing in the block a thumb can press, so it never stands nearer
	-- the stick's zone than 8 px: `buffMinX` is its leftmost place, in the
	-- block's own units. While it shows (`input.buff`) the block is reserved
	-- with it beside the widest balance, and the belt keeps 8 px off that --
	-- sliding over the least it has to, and only where that still leaves room
	-- short of the jump button dropping its Bag cell (beltBetween): on the
	-- 640-px phones, for an x2 owner.
	--==========================================================================
	local style = CASH_PHONE
	local cx = CONFIG.CashLeft
	local hang = (style.BuffHit - style.BuffSize) / 2
	local buffMinX = math.max(style.BuffMinX, thumb.x + thumb.w + G + hang - cx)
	local cw = math.max(style.Reserve, input.cashWidth or 0)
	if input.buff then
		cw = math.max(cw, math.max(buffMinX, style.Reserve + style.BuffGap) + style.BuffSize + hang)
	end
	local hotbar, chip, stripFits = plainBelt, plainChip, plainFits
	if input.buff then
		hotbar, chip, stripFits = beltBetween(input, thumb, jump, CONFIG.MobileSlots, cx + cw + G)
	end
	local band = HudLayout.hotbarBand(hotbar, removeLift(input))
	if not stripFits then
		fits = false
	end
	local ch = style.Root.Y + style.Drop
	local rootBottom = sh - HOT.BottomGap
	if HudLayout.gap(rect(cx, rootBottom - style.Root.Y, cw, ch), band) < G then
		rootBottom = band.y - G - style.Drop
	end
	local cash = rect(cx, rootBottom - style.Root.Y, cw, ch)
	local cashRoot = rect(cx, rootBottom - style.Root.Y, style.Root.X, style.Root.Y)
	if cash.y < walk.y + walk.h + G then
		fits = false
	end

	--==========================================================================
	-- INDEX, GARDEN AND THE BAG, ONE OVER ANOTHER (see THE TOP-RIGHT CORNER)
	--
	-- 8 px under the panel's row, centred under its last square, Column.Gap
	-- apart. Column.Size where the height allows, shrinking to fit down to the
	-- jump button's clearance -- the button stands under this column on every
	-- phone with the small controls -- and the belt's band, a trap's REMOVE row
	-- up, where that shares the column; never under Column.MinSize (705 x 338:
	-- 36). Index's badge is tucked level with its top, so the column stays 8 px
	-- off the row with it (HudLayout.badges). A phone with no room even at
	-- MinSize is not a fit.
	--==========================================================================
	local C = P.Column
	local stackTop = railBottom + G
	local mid = settings.x + settings.w / 2
	local stackFloor = sh - M
	for _, other in ipairs({ jump or rect(0, 0, 0, 0), worstBand(input, hotbar) }) do
		if other.w > 0 and other.x < mid + C.Size / 2 + G and other.x + other.w + G > mid - C.Size / 2 then
			stackFloor = math.min(stackFloor, other.y - G)
		end
	end
	local size = math.clamp(math.floor((stackFloor - stackTop - C.Gap * 2) / 3), C.MinSize, C.Size)
	if stackTop + size * 3 + C.Gap * 2 > stackFloor then
		fits = false
	end
	local index = rect(mid - size / 2, stackTop, size, size)
	local garden = rect(index.x, stackTop + size + C.Gap, size, size)
	local bag = rect(index.x, stackTop + (size + C.Gap) * 2, size, size)
	local stack = HudLayout.union(index, bag)

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
	-- right of Shop and the switches under it (until 2026-10-05, of the dock's
	-- handle), left-aligned and wrapped (TutorialUI), never past Guide.Reach of
	-- the width -- and 8 px clear of the belt and the cash block where it shares
	-- their columns. The step counter and Skip stand on one row above the
	-- words, so the button never moves when the words change length. On the
	-- 640-px phones the row above the words is wider than that leaves: the
	-- block keeps its least width there, and reaches a few px past the middle.
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
		local gx = railRight + G
		-- Under the top-right row's band -- and under the passing lines' band too,
		-- where a column that starts lower (ADMIN hung under the clock) brings that
		-- band down to the block: a biome name going by never lands on the words.
		local gy = math.max(railBottom, (columnTop or 0) + P.NoticeTop + CONFIG.NoticeHeight) + G
		-- As wide as the row above the words needs at the least; Guide.Clear short
		-- of the middle where the screen allows more than that; never past Reach
		-- where the least allows it.
		local least = P.Counter + G + P.Skip.X
		local gw = math.max(least, math.min(P.Guide.Width, math.floor(sw * P.Guide.Reach) - gx,
			math.max(least, math.floor(sw / 2 - P.Guide.Clear) - gx)))
		-- The panel's row and the column under it (2026-10-09; the panel ran down
		-- the right edge from 2026-10-06): on a narrow phone the words stop 8 px
		-- short of them, or take the banner instead (which steps round them, below).
		for _, right in ipairs({ dock, stack }) do
			if right.x > gx and HudLayout.gap(rect(gx, math.max(railBottom, (columnTop or 0) + P.NoticeTop
					+ CONFIG.NoticeHeight) + G, gw, P.Guide.Height), right) < G then
				gw = math.min(gw, math.floor(right.x - G - gx))
			end
		end
		local floorY = sh - M
		for _, other in ipairs({ band, cash, thumb, jump }) do
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
				{ cash, thumb, jump, dock, stack, shop, walk, others }, CONFIG.TutorialPhoneScale)
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
		others = others,
		events = events,
		updates = updates,
		garden = garden,
		bag = bag,
		pairRow = false,
		gardenRight = false,
		column = true,
		railTop = M,
		railBottom = railBottom,
		railRight = railRight,
		-- The right edge's column (Index's x), as on a desktop: what a panel's
		-- header steps round (UIKit.modal). The row left of it stands down while
		-- a centre panel is open (RailDrawerUI), as Index alone in the corner did.
		rightLeft = index.x,
		hotbar = hotbar,
		chip = chip,
		namePopup = HudLayout.namePopupOver(hotbar, removeLift(input)),
		removeRow = removeRowOver(input, hotbar),
		icons = nil,
		iconSize = ICONS.Size.Phone,
		iconColumns = 0,
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
		-- The panel's row (2026-10-09; down the right edge from 2026-10-06): the
		-- handle at its left end and the row, or the handle alone at the right
		-- edge while shut. `dockCanvas` is the row's whole width.
		dock = dock,
		handle = handle,
		handleShut = nil,
		dockView = dockView,
		dockCanvas = canvas,
		dockShut = shut,
		invite = invite,
		-- The x2 card is no longer a row button on a phone (2026-10-05).
		boost = nil,
		toast = toastAbove(sw, band, { cash, thumb, jump }),
		teleport = teleport,
		teleportScale = CONFIG.Teleport.PhoneScale,
		obby = rect(0, 0, 0, 0),
		obbyWide = false,
		biomes = rect(0, 0, 0, 0),
		biomesWide = false,
		teleportPlate = plotPlate,
		teleportShort = true,
		biomesPlate = row.biomesPlate or Vector2.new(0, 0),
		obbyPlate = row.obbyPlate or Vector2.new(0, 0),
		returnPlot = row.back or teleport,
		returnPlate = row.backPlate or plotPlate,
		returnWide = false,
		buffMinX = buffMinX,
		switchInline = true,
		clockChip = true,
		topRow = inRow,
		run = rect(0, 0, 0, 0),
		rowLo = if inRow then row.lo else nil,
		rowHi = if inRow then row.hi else nil,
		rowEnd = if inRow then row.stop else nil,
		columnCentre = if inRow then row.centre else nil,
		columnTop = columnTop,
		toastTop = false,
		guide = guide,
		admin = admin,
	}
	L.clock = clock
	--==========================================================================
	-- THE ICON ROW AND THE NOTICES, OVER THE BELT (2026-10-04)
	--
	-- The owner's order for every screen: the hotbar at the bottom, the active
	-- icons directly above it, the short notices just above the icons. On a
	-- phone that is the column between the thumbstick and the jump button,
	-- clear of the cash block -- and on EVERY phone, with or without the top
	-- row (the rain chip and the mini line were never placed on a phone with
	-- no row). The notices stood at the top of the column from 2026-09-29 to
	-- here; they are drawn at the phone's smaller size and stack up no further
	-- than the middle band allows -- one at a time on a short phone
	-- (noticeStack), so they never climb over the character.
	--==========================================================================
	do
		local around: { Rect } = { L.cash }
		if L.thumb then
			table.insert(around, L.thumb)
		end
		if L.jump then
			table.insert(around, L.jump)
		end
		-- And the panel's row and the column under it, at the right edge
		-- (2026-10-09).
		if L.dock then
			table.insert(around, L.dock)
		end
		table.insert(around, stack)
		L.icons, L.iconSize, L.iconColumns = iconsOver(input, L, band, around)
		L.toast = toastAbove(sw, withIcons(band, L.icons), around)
	end
	L.fits = L.fits and #HudLayout.problems(L) == 0
	local beside, first = row.obby, row.biomes
	if not (beside and first and columnTop) then
		-- No row: beside TELEPORT under the clock, as OBBY stood (obbyBeside),
		-- BIOMES on its other side (biomesBeside), and everything else as it
		-- stood with them -- each plate its touch area, as it always was.
		L.obby, L.obbyWide = obbyBeside(input, L)
		L.biomes, L.biomesWide = biomesBeside(input, L)
		L.obbyPlate = Vector2.new(L.obby.w, L.obby.h)
		L.biomesPlate = Vector2.new(L.biomes.w, L.biomes.h)
		return L
	end
	-- On the row: the run's clock has OBBY's slot on the course.
	L.obby, L.obbyWide = beside, row.obbyWide
	L.biomes, L.biomesWide = first, row.biomesWide
	L.run = beside
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
	local size = BADGE_BOX
	--==========================================================================
	-- IN THE COLUMN AT THE RIGHT EDGE (2026-10-09) ON A DESKTOP AND A TV: both
	-- tucked into their top-LEFT corners, toward the middle, BadgeHang past them
	-- -- Garden's into the 6 px over it, never half over Index. ON A PHONE the
	-- owner's small pills on the top-RIGHT corners instead (Phone.Badge), so the
	-- pictures show: Index's level with its top -- the column stands 8 px under
	-- the panel's row, so nothing may hang above it there.
	--
	-- In compact (which keeps that afternoon's arrangement): Garden at the left
	-- edge, its badge on its top-RIGHT corner, tucked; Index's on its top-right
	-- corner in the row. Where a small window keeps Garden top right, Garden's
	-- on its top-LEFT corner, toward the middle, as it always was there.
	--==========================================================================
	local hang = CONFIG.BadgeHang + stroke
	local g = L.garden
	if L.column then
		local ix = L.index
		if L.sidebar then
			-- A phone (the owner, 2026-10-09): the small pills on the top-RIGHT
			-- corners, Over past them (Phone.Badge) -- Garden's into the gap over
			-- it, Index's level with its top -- two digits' width reserved.
			local PB = CONFIG.Phone.Badge
			return rect(ix.x + ix.w + PB.Over - PB.Reserve, ix.y, PB.Reserve, PB.Size),
				rect(g.x + g.w + PB.Over - PB.Reserve, g.y - PB.Over, PB.Reserve, PB.Size)
		end
		return rect(ix.x - hang, ix.y - hang, size, size), rect(g.x - hang, g.y - hang, size, size)
	end
	local index: Rect
	if L.compact then
		index = rect(L.index.x + L.index.w + hang - size, L.index.y - hang, size, size)
	else
		index = rect(L.index.x + L.index.w - size / 2, L.index.y - size / 2, size, size)
	end
	local garden: Rect
	if L.gardenRight then
		garden = rect(g.x - hang, g.y - hang, size, size)
	elseif L.compact then
		garden = rect(g.x + g.w + hang - size, g.y - hang, size, size)
	else
		garden = rect(g.x + g.w - size / 2, g.y - size / 2, size, size)
	end
	return index, garden
end

--==============================================================================
-- INVITE'S "!" (2026-10-06): THE SAME BOX AS THE OTHER BADGES, THE SAME CORNERS
--
-- The size every badge has (26 and its stroke), on INVITE's corner by the rule
-- Index's follows in that mode: half off the top-right corner on a desktop and a
-- TV, tucked into it in compact. Empty with no INVITE. The glyph is drawn in
-- this box, Rail.InviteBadge.Scale times its height, with its ink line round it.
--
-- ON A PHONE (2026-10-06, seen in Play at 705 x 338) INVITE is the first square
-- of the panel under the Bag, 34-40 px: every badge's 31 px box drew a 35-px
-- "!" over most of the picture, and the panel's top edge cut the glyph's top.
-- There it is the handle's badge size (Phone.Panel.HandleH, the "!" the same
-- panel wears shut), on the square's top-right corner, its right edge in the
-- panel's padding, and as far down as the glyph and its ink reach above the
-- box -- so the viewport never cuts it.
--==============================================================================
function HudLayout.inviteBadge(L: Layout): Rect
	local r = L.invite
	if r.w <= 0 then
		return rect(0, 0, 0, 0)
	end
	local stroke = 2.5
	local size = 26 + stroke * 2
	if L.sidebar then
		local PP = CONFIG.Phone.Panel
		local BANG = RAIL.InviteBadge
		local small = PP.HandleH
		local reach = math.ceil(small * (BANG.Scale - 1) / 2 + BANG.Stroke)
		return rect(r.x + r.w + PP.Pad - small, r.y - PP.Pad + reach, small, small)
	end
	if L.compact then
		local hang = CONFIG.BadgeHang + stroke
		return rect(r.x + r.w + hang - size, r.y - hang, size, size)
	end
	return rect(r.x + r.w - size / 2, r.y - size / 2, size, size)
end

-- The phone panel's handle wears a smaller badge while the panel is shut and a
-- square inside has one (2026-10-06): on its top-right corner, tucked in, as
-- wide as the handle -- which stands upright at the row's end since the panel
-- became a row (2026-10-09). Empty with no handle.
function HudLayout.handleBadge(L: Layout): Rect
	local h = L.handle
	if not h then
		return rect(0, 0, 0, 0)
	end
	local size = math.min(h.w, h.h)
	return rect(h.x + h.w - size * 0.75, h.y - size * 0.25, size, size)
end

-- INVITE'S "!" PINNED TO THE PANEL'S TOP EDGE (2026-10-06, the owner). Scrolled
-- so far that INVITE's own "!" would be cut, the panel shows the "!" itself, over
-- its top fade, in the very box INVITE's stands in with the canvas at its top --
-- so the "!" never moves and never shows cut -- and a tap there scrolls the panel
-- back to the top. Answers that box (safe space), the scroll past which it pins
-- (where the glyph's top, ink included, stands under the viewport's top edge),
-- and its press: the box PinPad bigger all round, inside the viewport. Nothing
-- without the panel.
function HudLayout.invitePin(L: Layout): (Rect, number, Rect)
	local view = L.dockView
	local b = HudLayout.inviteBadge(L)
	if not (L.sidebar and view) or b.w <= 0 then
		return rect(0, 0, 0, 0), math.huge, rect(0, 0, 0, 0)
	end
	local PP = CONFIG.Phone.Panel
	local BANG = RAIL.InviteBadge
	local glyphTop = b.y + b.h / 2 - math.floor(b.h * BANG.Scale) / 2 - BANG.Stroke
	local x0, y0 = math.max(view.x, b.x - PP.PinPad), math.max(view.y, b.y - PP.PinPad)
	local x1 = math.min(view.x + view.w, b.x + b.w + PP.PinPad)
	local y1 = math.min(view.y + view.h, b.y + b.h + PP.PinPad)
	return b, math.max(0, glyphTop - view.y), rect(x0, y0, x1 - x0, y1 - y0)
end

function HudLayout.groups(L: Layout, withBadges: boolean?): { Group }
	--==========================================================================
	-- ON A PHONE (2026-10-05)
	--
	-- Shop in the top-left corner is a group, and each switch row under it
	-- another ("others", and "rail" for WALK MODE, as it always was). The
	-- panel's row at the top right -- INVITE, EVENTS, WHAT'S NEW and Settings
	-- in it, and its handle -- is "dock"; Index, Garden and the Bag one over
	-- another under it are "column", with their badges (2026-10-09 -- Index
	-- in the corner and Garden and the Bag at the left edge before).
	--==========================================================================
	local dock = L.dock
	if L.sidebar and dock then
		local stack = HudLayout.union(L.index, L.bag)
		if withBadges then
			local indexBadge, gardenBadge = HudLayout.badges(L)
			stack = HudLayout.union(HudLayout.union(stack, indexBadge), gardenBadge)
		end
		local phoneList: { Group } = {
			{ name = "shop", rect = L.shop },
			{ name = "others", rect = L.others },
			{ name = "rail", rect = L.walk },
			{ name = "dock", rect = dock },
			{ name = "column", rect = stack },
			{ name = "hotbar", rect = L.hotbar },
			{ name = "cash", rect = L.cash },
		}
		if L.icons then
			table.insert(phoneList, { name = "icons", rect = L.icons })
		end
		return phoneList
	end
	-- Index in the rail on a desktop until 2026-10-09, and still in compact's
	-- top row; in the right edge's column with Garden and the Bag since.
	local rail = if L.column then HudLayout.union(L.shop, L.settings)
		else HudLayout.union(HudLayout.union(L.index, L.shop), L.settings)
	-- INVITE (2026-10-06): in the rail's band on a desktop; a group of its own
	-- under the row in compact (below).
	if not L.compact and L.invite.w > 0 then
		rail = HudLayout.union(rail, L.invite)
	end
	-- WALK MODE: down the rail's column on a desktop; in compact under EVENTS at
	-- the right edge (left of it until 2026-10-09), a group of its own there.
	local walkAlone = L.compact
	if not walkAlone then
		rail = HudLayout.union(rail, L.walk)
		-- OTHER PLANTS: the rail's fifth row on a desktop (2026-10-05).
		rail = HudLayout.union(rail, L.others)
	end
	-- EVENTS: inside that band on a desktop; in the top-right corner in compact
	-- (under the Bag until 2026-10-09), a group of its own there.
	local events = L.events.w > 0 and L.compact
	if L.events.w > 0 and not L.compact then
		rail = HudLayout.union(rail, L.events)
	end
	-- Garden and the Bag: with Index in the right edge's column on a desktop and
	-- a TV (2026-10-09), its badges as they are drawn there -- tucked, which the
	-- half-off desktop badges were never counted as; at the left edge in compact.
	local right = if L.column then HudLayout.union(L.index, L.bag) else HudLayout.union(L.garden, L.bag)
	if withBadges and (L.compact or L.column) then
		local indexBadge, gardenBadge = HudLayout.badges(L)
		if L.column then
			right = HudLayout.union(HudLayout.union(right, indexBadge), gardenBadge)
		else
			rail = HudLayout.union(rail, indexBadge)
			right = HudLayout.union(right, gardenBadge)
		end
	end
	local list: { Group } = {
		{ name = "rail", rect = rail },
		{ name = if L.column then "column" else "garden+bag", rect = right },
		{ name = "hotbar", rect = L.hotbar },
		{ name = "cash", rect = L.cash },
	}
	if events then
		table.insert(list, { name = "events", rect = L.events })
	end
	if walkAlone then
		table.insert(list, { name = "walk", rect = L.walk })
		-- OTHER PLANTS under WALK MODE in compact: a group of its own too.
		table.insert(list, { name = "others", rect = L.others })
	end
	-- WHAT'S NEW (2026-10-05): in the top-right corner on a desktop (under the
	-- Bag until 2026-10-09), by WALK MODE or under Index in compact -- a group
	-- of its own in both.
	if L.updates.w > 0 then
		table.insert(list, { name = "updates", rect = L.updates })
	end
	-- INVITE in compact (2026-10-06), with its "!" where it is drawn.
	if L.compact and L.invite.w > 0 then
		local r = L.invite
		if withBadges then
			r = HudLayout.union(r, HudLayout.inviteBadge(L))
		end
		table.insert(list, { name = "invite", rect = r })
	end
	-- The icon row, while one stands: a group of its own, so the notice stack
	-- (noticeStack) and every clearance check keep off it.
	if L.icons then
		table.insert(list, { name = "icons", rect = L.icons })
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
	-- The shut handle stands where the dock was, so it only has to clear the
	-- rest, and may sit on the safe area's own edge -- it is a tab pulled out
	-- of it. And the item name's band, below.
	--==========================================================================
	local transient: { Group } = {}
	-- The item name's band over the strip (2026-10-01): up for a second on an
	-- equip, so not a permanent group, but nothing permanent may stand in it.
	-- It touches the strip it belongs to, which is the one pair exempted.
	table.insert(transient, { name = "name band", rect = L.namePopup })
	-- The REMOVE row (2026-10-04): up while a trap is out. It hugs the strip it
	-- belongs to, like the name band, and must keep clear of everything else.
	if L.removeRow then
		table.insert(transient, { name = "remove row", rect = L.removeRow })
	end
	if L.handleShut then
		table.insert(transient, { name = "shut handle", rect = L.handleShut })
	end
	for _, extra in ipairs(transient) do
		local r = extra.rect
		local edge = 0
		if r.x < edge or r.y < M or r.x + r.w > sw - M or r.y + r.h > sh - M then
			table.insert(found, extra.name .. " is not inside the safe area's margin")
		end
		for _, group in ipairs(groups) do
			local exempt = (extra.name == "shut handle"
				and (group.name == "dock" or group.name == "handle"))
				or ((extra.name == "name band" or extra.name == "remove row") and group.name == "hotbar")
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
	L.others = shifted(L.others, dx, dy)
	if L.events.w > 0 then
		L.events = shifted(L.events, dx, dy)
	end
	if L.updates.w > 0 then
		L.updates = shifted(L.updates, dx, dy)
	end
	if L.invite.w > 0 then
		L.invite = shifted(L.invite, dx, dy)
	end
	L.dockView = shiftedMaybe(L.dockView, dx, dy)
	L.garden = shifted(L.garden, dx, dy)
	L.bag = shifted(L.bag, dx, dy)
	L.hotbar = shifted(L.hotbar, dx, dy)
	L.namePopup = shifted(L.namePopup, dx, dy)
	L.removeRow = shiftedMaybe(L.removeRow, dx, dy)
	L.icons = shiftedMaybe(L.icons, dx, dy)
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
	L.toast = shifted(L.toast, dx, dy)
	L.teleport = shifted(L.teleport, dx, dy)
	if L.returnPlot.w > 0 then
		L.returnPlot = shifted(L.returnPlot, dx, dy)
	end
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
	-- A window too small for Garden and the Bag at the left edge (640 x 400 and
	-- smaller: the cash block stands within two buttons' height of the top row)
	-- keeps them in the top-right row they had until 2026-10-09. Decided by the
	-- pair alone, measured with a trap's REMOVE row up, so the arrangement never
	-- changes when a trap comes out.
	local L = compact(input)
	if L.pairFits == false then
		return compact(input, true)
	end
	return L
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
	-- and stepped round like them. EVENTS and Walk Mode's switch too, by the
	-- Bag in compact, and OTHER PLANTS under EVENTS (2026-10-05) -- and WHAT'S
	-- NEW, by them or under Index (2026-10-05).
	local inRows: { Rect } = {}
	for _, b in ipairs({ L.obby, L.biomes, L.events, L.walk, L.others, L.updates }) do
		if b.w > 0 and top < b.y + b.h + G and top + height + G > b.y then
			table.insert(inRows, b)
		end
	end
	if (top + height + G <= L.railTop or top >= L.railBottom + G) and #inRows == 0 then
		return 0, top
	end
	local centre = L.safe.X / 2
	-- Measured to the badges as well as the buttons -- each on the side its
	-- button stands, and only a button in the rows' band: Garden left the top
	-- right for the left edge's middle (2026-10-09), where its badge is nothing
	-- to a band at the top.
	local indexBadge, gardenBadge = HudLayout.badges(L)
	local lo, hi = L.railRight, L.rightLeft
	for _, pair in ipairs({ { L.index, indexBadge }, { L.garden, gardenBadge } }) do
		local button, badge = pair[1], pair[2]
		if button.w > 0 and button.y < L.railBottom then
			if button.x + button.w / 2 < centre then
				lo = math.max(lo, badge.x + badge.w)
			else
				hi = math.min(hi, badge.x)
			end
		end
	end
	lo += G
	hi -= G
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
	for _, b in ipairs({ L.obby, L.biomes, L.events, L.walk, L.others, L.updates }) do
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
	-- SINCE THE MOBILE CORRECTIONS (2026-10-05) the row's three buttons are one
	-- narrow even row, so the warning starts where the row does and runs RIGHT,
	-- over all three slots -- every one empty while a chase is on -- as far as
	-- the row's free span goes (`rowEnd`: 8 px short of ADMIN or the clock).
	local stop = L.rowEnd or (band.x + band.w)
	local w = math.min(width, math.max(0, stop - lo))
	return rect(lo, band.y, w, band.h)
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
-- The desktop branch is LoadoutUI's layoutBag arithmetic, moved here: the panel
-- fits between the rails and above the hotbar, centred on the screen when that
-- still leaves a real panel.
--
-- ON A PHONE (measured 2026-09-18 on the owner's emulated 801 x 392 phone, and
-- kept for the compact grid of 2026-10-03):
--
--   * the strip is hidden while the Bag is open (touch only), and the panel
--     runs down to the safe area's bottom edge instead of stopping above it;
--   * the grid scrolls SIDEWAYS, in as many whole rows of tiles as fit --
--     never a part row, so nothing is ever clipped at the top or the bottom.
--
-- `stripHidden` is the first of those: LoadoutUI passes `layout.touch`, and
-- hides the strip on exactly the same condition.
--
-- INSIDE THE BODY (2026-10-03, the owner's compact grid): the category column
-- down the left, the whole body tall; the grid beside it; the storage line as
-- a footer under the grid. Those three come back in the BODY's own coordinates.
--==============================================================================
export type BagInput = {
	-- The strip's top edge in safe space, from its own Position and Size.
	hotTop: number,
	stripHidden: boolean,
	-- The player's chosen menu size (UIKit.menuScale); nil or 1 is today's.
	scale: number?,
	-- A phone's menu scale (UIKit.phoneMenuScale, 2026-10-08); nil or 1 off one.
	phone: number?,
}

export type Bag = {
	panel: Rect,
	-- The group is centre-anchored; this is the offset LoadoutUI writes.
	centre: Vector2,
	compactHeader: boolean,
	body: Rect,
	-- In the body's own coordinates.
	column: Rect,
	grid: Rect,
	footer: Rect,
	-- The five category buttons' height and the gap between them.
	catH: number,
	catGap: number,
	tile: Vector2,
	gap: number,
	pad: number,
	horizontal: boolean,
	-- Whole rows of tiles that fit the grid's height (the phone's sideways grid
	-- has exactly these), and how many tiles fit across it, fractional.
	rows: number,
	columns: number,
	-- The menu size the panel is actually drawn at: the chosen one, or less if
	-- that would not fit. The group is sized panel / scale and drawn `scale`
	-- times larger, so `panel` stays its footprint on screen; `body` and what is
	-- in it describe the panel at that smaller logical size. On a phone both
	-- carry the phone's scale too: the panel is that share of the free space,
	-- centred, drawn that much smaller, with the same insides.
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
	-- The band the right column's buttons took (Garden over the Bag until
	-- 2026-10-09; WHAT'S NEW alone in the corner since, inside it).
	local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
	local leftEdge = RAIL.Inset + RAIL.WideSize.X + B.EdgeGap
	-- Short of the right edge's column (rightLeft), 8 px off it. Garden and the
	-- Bag stand at the left edge, left of leftEdge.
	local rightEdge = L.rightLeft - ox - B.EdgeGap
	local top = B.EdgeGap
	local bottom = input.hotTop - oy - B.EdgeGap
	if L.compact then
		-- The compact rail is two short rows, not two columns: the panel takes
		-- the whole width, and the rows stand over its top corners, which
		-- UIKit.modal's header pads its title and close button clear of.
		leftEdge = B.EdgeGap
		rightEdge = sw - B.EdgeGap
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
	local tile = if L.compact then B.TileCompact else B.Tile
	local columnW = if L.compact then B.ColumnCompact else B.Column
	local catGap = if L.compact then B.CatGapCompact else B.CatGap

	--==========================================================================
	-- EVERYTHING INSIDE, AT A MENU SIZE
	--
	-- `s` is the player's menu size: the panel keeps its footprint and is drawn
	-- `s` times larger, so its insides are laid out for a panel `s` times
	-- smaller, centred where the real one is. At 1 this is the plain layout.
	--==========================================================================
	type Inner = {
		compactHeader: boolean, body: Rect, column: Rect, grid: Rect, footer: Rect,
		catH: number, rows: number, columns: number, fits: boolean,
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

		local catH = math.min(B.CatH, math.floor((bodyH - catGap * 4) / 5))
		local gridX = columnW + B.ColumnGap
		local gridW = bodyW - gridX
		local gridH = bodyH - B.FooterH - B.FooterGap
		local wholeRows = math.floor((gridH - B.GridPad * 2 + B.TileGap) / (tile.Y + B.TileGap))
		local across = (gridW - B.GridPad * 2 + B.TileGap) / (tile.X + B.TileGap)
		return {
			compactHeader = compactHeader,
			body = body,
			column = rect(0, 0, columnW, bodyH),
			grid = rect(gridX, 0, gridW, gridH),
			footer = rect(gridX, gridH + B.FooterGap, gridW, B.FooterH),
			catH = catH,
			rows = if L.compact then math.max(1, wholeRows) else math.max(0, wholeRows),
			columns = across,
			-- Five category buttons at their floor, and one whole tile each way.
			fits = catH >= B.CatMinH and wholeRows >= 1 and across >= 1,
		}
	end

	--==========================================================================
	-- AS LARGE AS CHOSEN, NO LARGER THAN FITS
	--
	-- Never smaller than the panel's minimum at its logical size, and never so
	-- large that a whole row of tiles or the five buttons stop fitting: stepped
	-- down until they do, and never below today's size.
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
	local body = it.body

	--==========================================================================
	-- ON A PHONE (2026-10-08, the owner: "make the ui smaller on phones")
	--
	-- The panel is drawn `phone` times smaller and takes that share of its
	-- footprint, centred where it was: the same logical panel -- the insides
	-- above, unchanged -- short of the screen's edges, the HUD showing round it.
	--==========================================================================
	local phone = input.phone
	if type(phone) == "number" and phone == phone and phone > 0 and phone < 1 then
		local w, h = width * phone, height * phone
		panel = rect(centre.X - w / 2, centre.Y - h / 2, w, h)
		scale *= phone
	end

	if frame then
		panel = shifted(panel, ox, oy)
		centre = Vector2.new(centre.X + ox, centre.Y + oy)
		body = shifted(body, ox, oy)
	end

	return {
		panel = panel,
		centre = centre,
		compactHeader = it.compactHeader,
		body = body,
		column = it.column,
		grid = it.grid,
		footer = it.footer,
		catH = it.catH,
		catGap = catGap,
		tile = tile,
		gap = B.TileGap,
		pad = B.GridPad,
		horizontal = L.compact,
		rows = it.rows,
		columns = it.columns,
		scale = scale,
	}
end

--==============================================================================
-- THE SEARCH BOX AND THE HEART, IN THE SHELL'S OWN COORDINATES
--
-- On their own row under the title; in a compact header, on the title's row
-- between the title and the close button -- stopping short of both wherever
-- the header has stepped them in from a rail button (UIKit.modal's padding),
-- the way the old tab row did. `titleWidth` is the title's drawn width in the
-- panel's logical units. Answers the search box and the heart.
--==============================================================================
function HudLayout.bagSearch(bag: Bag, shellW: number, titleWidth: number, padLeft: number,
	padRight: number): (Rect, Rect)
	local B = CONFIG.Bag
	local x, y, right
	if bag.compactHeader then
		local reserve = math.max(72, math.ceil(titleWidth) + padLeft + 16)
		x = 12 + reserve
		y = B.SearchTopCompact
		right = shellW - 12 - 52 - padRight
	else
		x = 12
		y = B.SearchTop
		right = shellW - 12
	end
	local heart = rect(right - B.HeartW, y, B.HeartW, B.SearchH)
	local search = rect(x, y, math.max(0, heart.x - B.SearchGap - x), B.SearchH)
	return search, heart
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
	local me = game:GetService("Players").LocalPlayer
	local icons = if me then me:GetAttribute(ICONS.Attribute) else nil
	local removeRow = if me then me:GetAttribute(HOT.RemoveRowAttribute) == true else false
	local dockShut = if me then me:GetAttribute(CONFIG.Phone.Panel.ShutAttribute) == true else false
	local buff = if me then GameConfig.cashMultiplier(me) > 1 else false
	local input: Input = {
		safe = size,
		touch = UserInputService.TouchEnabled,
		keyboard = UserInputService.KeyboardEnabled,
		cashWidth = cashWidth,
		viewport = if camera then camera.ViewportSize else nil,
		topbar = rect(bar.Min.X, bar.Min.Y, bar.Width, bar.Height),
		insetTop = insetTop,
		-- How many icons BoostIconsUI has standing over the strip (2026-10-04):
		-- the row is placed and the toast lifted only while one stands.
		icons = if type(icons) == "number" then icons else nil,
		-- Whether LoadoutUI has a trap's REMOVE standing over the strip
		-- (2026-10-04): the band and everything over it step up for it.
		removeRow = if removeRow then true else nil,
		-- Whether RailDrawerUI has the phone's panel under the Bag shut (2026-10-06).
		dockShut = if dockShut then true else nil,
		-- Whether CashUI shows the x2 card (2026-10-05): on a phone the belt keeps
		-- 8 px off it beside the cash line.
		buff = if buff then true else nil,
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


--==============================================================================
-- EVERYTHING THE HUD STANDS IN ON THIS SCREEN (2026-10-06)
--
-- The permanent groups with their badges, INVITE's "!", the thumbstick and the
-- jump button, the bands over the belt (the item name, the REMOVE row, the
-- boost icons, the toast line) and the top row's buttons: what a passing card
-- -- the Invite a Friend reward popup (MenuLayout.rewardPopup) -- stands clear
-- of. Empty rects are left out.
--==============================================================================
function HudLayout.occupied(L: Layout): { Rect }
	local out: { Rect } = {}
	local function add(r: Rect?)
		if r and r.w > 0 and r.h > 0 then
			table.insert(out, r)
		end
	end
	for _, g in ipairs(HudLayout.groups(L, true)) do
		add(g.rect)
	end
	-- INVITE's "!" where it stands: on its square, or -- the phone's row tucked
	-- into the right edge, INVITE with it -- on the handle (2026-10-10: the "!"
	-- of a tucked row stood here as a phantom, and the guide's world hand kept
	-- 16 px off nothing).
	if L.sidebar and L.dockShut then
		add(HudLayout.handleBadge(L))
	else
		add(HudLayout.inviteBadge(L))
	end
	add(L.thumb)
	add(L.jump)
	add(L.namePopup)
	add(L.removeRow)
	add(L.icons)
	add(L.toast)
	add(L.teleport)
	add(L.obby)
	add(L.biomes)
	add(L.returnPlot)
	return out
end

-- occupied() without the notices' line (L.toast) -- the line is the notices'
-- only while one passes. What a big passing card may stand over where keeping
-- off it as well leaves it no room or too small to read (2026-10-09, under the
-- phone's panel row: the REBORN! card, the invite reward card), as the buff
-- popover always may (HudLayout.popoverRect).
function HudLayout.occupiedButToast(L: Layout): { Rect }
	local out: { Rect } = {}
	for _, r in ipairs(HudLayout.occupied(L)) do
		if r ~= L.toast then
			table.insert(out, r)
		end
	end
	return out
end

--==============================================================================
-- THE BUFF POPOVER'S PLACE (2026-10-09, the owner: "place it CLEAR of the guide
-- card and other HUD words, still transparent")
--
-- Over its icon, on the icon's middle and `popGap` above the row, as it always
-- stood -- wherever that keeps 8 px off every group and badge, the status rows
-- (the chase warning, the biome name, the sale line) and, while it shows, the
-- beginner's guide card. With no sheet behind it any
-- more a word under it shows through its own: seen on a 705 x 338 phone, the
-- guide card's. Else the nearest place inside the margin that does
-- (SpeedMilestones.clearOf); with none, over the icon after all. Safe space;
-- `size` is the popover's, `insetTop` HudLayout.measure's. `extra`: other
-- words standing now that are not HudLayout's (the Pod Rush tracker, seen in
-- Play under the popover on a 705 x 338 phone). Answers the place and whether
-- it is clear of everything.
--==============================================================================
function HudLayout.popoverRect(L: Layout, cx: number, size: Vector2, popGap: number, insetTop: number,
	guide: boolean, extra: { Rect }?): (Rect, boolean)
	local M, G = CONFIG.Margin, CONFIG.Gap
	local row = L.icons or rect(cx, L.safe.Y / 2, 0, 0)
	local want = rect(math.clamp(cx - size.X / 2, M, math.max(M, L.safe.X - M - size.X)), row.y - popGap - size.Y,
		size.X, size.Y)
	local blocked: { Rect } = {}
	for _, r in ipairs(HudLayout.occupied(L)) do
		-- Not the notices' line: it is theirs only while one passes (a short
		-- phone has no 100 px clear of it beside the row: 705 x 338).
		if r ~= L.toast then
			table.insert(blocked, r)
		end
	end
	local status, notice = HudLayout.statusRows(L, insetTop)
	table.insert(blocked, status)
	table.insert(blocked, notice)
	if guide then
		table.insert(blocked, L.banner)
		table.insert(blocked, L.skip)
	end
	for _, r in ipairs(extra or {}) do
		table.insert(blocked, r)
	end
	local bounds = rect(M, M, L.safe.X - M * 2, L.safe.Y - M * 2)
	local found = SpeedMilestones.clearOf(want, blocked, bounds, G)
	if found then
		return rect(found.x, found.y, found.w, found.h), true
	end
	return want, false
end

return HudLayout
