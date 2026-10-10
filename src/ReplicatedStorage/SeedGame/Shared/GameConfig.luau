--!strict
-- Steal a Seed :: GameConfig
--
-- Names, capacity and map geometry. Replicated to clients, so treat everything
-- in it as public. Balance numbers do NOT live here -- seeds and plants go in
-- SeedData, biome content in BiomeData.

local GameConfig = {}

GameConfig.ProjectName = "Steal a Sprout"
GameConfig.Version = "0.1.0"
GameConfig.Phase = 1

--==============================================================================
-- CAPACITY
--
-- Plots and players are ONE number. ServerMain warns at boot if
-- Players.MaxPlayers disagrees -- it is a place setting a script cannot change,
-- so the only honest thing code can do is refuse to be quiet about it.
--==============================================================================
GameConfig.MaxPlots = 6
GameConfig.MaxPlayers = 6

--==============================================================================
-- THE SHAPE OF THE MAP, AND WHY IT IS THIS SHAPE
--
-- Read off footage of the reference game rather than assumed. The first plan
-- had a hub with bases ringed around it and biomes as distant islands. That was
-- wrong, and wrong in a way that mattered.
--
-- ONE ROAD. THE FURTHER OUT, THE RARER THE SEED.
--
--     FIELD ══ FOREST ─── DESERT ─── JUNGLE ─── VOLCANO ─── COSMIC
--     (safe)    easy                                        endgame
--       ▲
--     the red line
--
-- The biomes are SEGMENTS OF ONE CORRIDOR, laid end to end, not five separate
-- lanes side by side. That single change is the whole risk curve of the game
-- expressed as geometry:
--
--   * Distance IS difficulty. Nothing has to be explained -- the rarer seed is
--     visibly further away, and you can see how far.
--   * THE RUN HOME GETS LONGER AS THE PRIZE GETS BETTER. A Cosmic seed is
--     1,500 studs from safety through every other biome. That is the entire
--     risk/reward of the game and it costs nothing to implement, because it is
--     just where the walls are.
--   * Everyone shares one road, so PvP happens on the way past rather than
--     having to be arranged. Five parallel lanes let players miss each other
--     completely.
--   * A speed gate at each boundary is a door on the road you are already
--     running down, not a menu of five destinations.
--
-- Pods sit ALONG THE WALLS, never in the middle. Grabbing one costs you the
-- racing line, which is a real decision when somebody is behind you.
--
-- Everything is derived from FieldWidth, FieldDepth, CorridorWidth and
-- SegmentLength. Moving the whole map is editing GroundY.
--==============================================================================
GameConfig.Map = {
	FolderName = "SeedMap",
	FieldName = "TheField",
	PlotsFolderName = "Plots",
	LanesFolderName = "Lanes",
	PropsFolderName = "Props",

	-- World Y of the field's walking surface. Everything is derived from it.
	GroundY = 0,

	-- The shared safe field.
	--
	-- ASYMMETRIC, AND THAT IS THE WHOLE EXPANSION STORY. The field is measured
	-- separately in each direction from the origin:
	--
	--   FieldFront  toward the road. TIGHT ON PURPOSE -- an early build put the
	--               plots 246 studs from the road and every run began and ended
	--               with a long walk across empty grass. Dead time, and the
	--               first thing a new player experiences. This number is the one
	--               that must never grow.
	--   FieldBack   away from the road. DELIBERATELY OVERSIZED. It is empty
	--               grass today and it is reserved room for plots to grow into.
	--
	-- Plots ring the hub (see THE RING below) and grow OUTWARD from it. Their
	-- gates all sit on one radius, so expanding a plot never moves the point its
	-- owner walks in through -- the same property an earlier row layout got from
	-- a fixed front edge, kept through the change of shape.
	FieldWidth = 540,   -- X
	FieldFront = 170,   -- Z toward the road
	FieldBack = 265,    -- Z away from it
	FieldThickness = 6,

	--==========================================================================
	-- THE RING
	--
	-- Plots are arranged around a central hub rather than in a row, from the
	-- owner's second sketch. It is a better shape and the reason is expansion:
	--
	--   A RING GIVES MORE ROOM THE FURTHER OUT YOU GROW. Plots expand OUTWARD,
	--   so their inner edges never move and the gaps between them there never
	--   change -- while the arc at their outer edge gets longer as the radius
	--   does. A row can only expand into space reserved up front; a ring makes
	--   room as it goes.
	--
	-- It also puts the hub the same distance from every plot, which a row never
	-- did: in a row the end plots were 145 studs from the centre and the middle
	-- ones were 29.
	--
	-- HubRadius is the deck in the middle (its centre the event plaza, the shops
	-- in their row by the road's mouth since 2026-10-10: EventHub, Stall
	-- below). PlotRingInner is where every plot's GATE sits -- identical for
	-- all of them, at every tier.
	--==========================================================================
	HubRadius = 46,
	PlotRingInner = 100,
	-- The arc left empty for the road, centred on the road's own axis. Nothing
	-- is built inside it.
	RoadGapDegrees = 62,

	--==========================================================================
	-- THE EVENT HUB (2026-10-10, the owner: the central hub becomes a permanent
	-- Event Hub; KB/EVENT-HUB-CLAUDE-PROMPT.md)
	--
	-- The deck's middle is an open event plaza. Nothing permanent stands within
	-- EventHub.Radius of its Centre: Marigold's stall and its two boards moved
	-- out to Stall below, the overflow spawn to OverflowSpawn. A restrained
	-- studded floor marks it (MapService) and nothing else, so between events it
	-- is open ground. An event's NPC stands on NpcAnchor, feet on the deck's
	-- top, looking down the road (-Z) over the open front half, ApproachWidth
	-- wide; whatever an event builds stays inside Radius and under MaxHeight,
	-- and each event clears only its own objects. Enchanted Mist's Mosskeeper
	-- is the first to stand here, and the owner lets him stay between events:
	-- the one resident (KB/ENCHANTED-MIST-HOURLY-CLAUDE-PROMPT.md). Polar
	-- about Centre, like the mini events' Area.
	--==========================================================================
	EventHub = {
		Centre = Vector3.new(0, 0, 0),
		Radius = 20,
		MaxHeight = 14,
		-- The deck's top over GroundY (MapService's Deck: 0.9 thick).
		FloorY = 0.9,
		NpcAnchor = CFrame.new(0, 0.9, 0),
		ApproachWidth = 12,
		-- The floor: a studded disc a hair over the deck, and a darker edge
		-- ring at Radius. Decoration only: the deck still carries everybody.
		Floor = {
			Colour = Color3.fromRGB(224, 200, 156),
			EdgeColour = Color3.fromRGB(168, 136, 96),
			EdgeWidth = 1.2,
			Rise = 0.05,
		},
	},

	--==========================================================================
	-- THE SHOP ROW, WEST OF THE ROAD'S MOUTH (2026-10-10, the owner: "transfer
	-- them here, shop, rebirth, everything")
	--
	-- Every fixture of the old square -- Marigold's stall with its two sell
	-- boards, the wheel, both chests, both pedestals, the shrine -- stands on
	-- the grass inside the red line, west of the road's mouth, all facing
	-- north into the field. The owner pointed at the strip EAST of the mouth;
	-- plot 6 grows over most of it from Level 3 (its wing reaches the red
	-- line), so the owner chose this mirror strip, which plot 1's wing grows
	-- away from. Two rows:
	--   * along the red line, east to west: the stall (nearest the mouth and
	--     the plots), the wheel, the invite pedestal, the shrine, the
	--     sacrifice pedestal -- as tight as the prompts allow, each further
	--     from the next than their two reaches added;
	--   * behind them, 30 studs into the field, the two chests, low, each in a
	--     gap of the first row, so no sign stands in front of another from the
	--     field.
	-- Each fixture's own config holds its spot (Stall here, WheelData.Place,
	-- BonusChest, Community, Sacrifice, InviteRewards, Rebirth); ShopRow is the
	-- ground they and their customers stand on, kept clear of field decor
	-- (MapDecor) and 6 studs or more off every plot at every level
	-- (EventHubSpec measures it all).
	--
	-- Position is the stall's origin, its counter's centre, on GroundY (its
	-- floor's centre is 2 studs back); FacingDegrees the way its counter's
	-- front -- the side customers walk up to -- faces, about +Y from +Z: 0
	-- looks north, into the field. BoardSide and BoardFront are SellService's:
	-- each board stands that far off the stall floor's ends and that far toward
	-- its front (in the floor's own frame), turned toward the point BoardFocus
	-- studs in front of the stall's middle.
	--==========================================================================
	Stall = {
		Position = Vector3.new(-140, 0, -157),
		FacingDegrees = 0,
		BoardSide = 15.5,
		BoardFront = -3.0,
		BoardFocus = 15,
	},
	-- The shop row's ground (X, Z), every fixture and its customers inside.
	ShopRow = { From = Vector2.new(-258, -167), To = Vector2.new(-118, -113) },

	-- The plotless player's spawn (every plot taken), out of the plaza to the
	-- deck's south side, on the walk in from the road; it was the deck's centre.
	OverflowSpawn = Vector3.new(0, 0.5, -26),

	-- THE RED LINE. A stripe painted flat on the grass at the field's far edge
	-- with SAFE ZONE written on it. Not a dome, not a forcefield, not a
	-- billboard -- the reference game uses a floor decal and it is readable at
	-- thirty studs while sprinting, which is the entire requirement. Anything
	-- fancier is worse at the only job it has.
	SafeLineThickness = 2.5,
	SafeLineColor = Color3.fromRGB(226, 58, 58),

	-- The road. One corridor, five segments long.
	CorridorWidth = 140,
	-- Per biome. Five of these end to end is the whole journey, so this number
	-- is the pacing of the entire game: how long a Forest round trip takes at
	-- WalkSpeed 16, and how long a Cosmic one takes at 150.
	SegmentLength = 300,
	WallHeight = 46,
	WallThickness = 10,
	-- How far a pod sits in from the wall. Far enough to walk behind, close
	-- enough that stepping out to it visibly costs you the middle.
	PodInset = 26,

	OverflowSpawnName = "OverflowSpawn",
	SellStandName = "SellStand",
}

-- Marigold's stall's own frame (Map.Stall): its counter's centre on GroundY,
-- local +Z its counter's front. MapService builds the stall by it; SellService's
-- boards, the mini events' keep-clear lists and EventHubSpec read it too.
function GameConfig.hubStallCFrame(): CFrame
	local S = GameConfig.Map.Stall
	return CFrame.new(S.Position) * CFrame.Angles(0, math.rad(S.FacingDegrees), 0)
end

-- A point in the stall's frame, on GroundY: `side` across it, `front` toward
-- its customers (negative behind the counter).
function GameConfig.hubStallPoint(side: number, front: number): Vector3
	local p = GameConfig.hubStallCFrame():PointToWorldSpace(Vector3.new(side, 0, front))
	return Vector3.new(p.X, GameConfig.Map.GroundY, p.Z)
end

--==============================================================================
-- A PLOT
--
-- Sits ON the field behind a low fence, exactly as the reference does. The
-- fence is decoration and a property line -- it is deliberately NOT collidable,
-- because a player sprinting home at WalkSpeed 120 who clips a fence post and
-- stops dead has been robbed by the scenery.
--==============================================================================
GameConfig.Plot = {
	NamePrefix = "Plot_",
	-- Width never changes. Only depth does -- see Tiers.
	Width = 48,
	-- There is no FrontZ any more. It was the row layout's anchor -- one world Z
	-- every plot's front edge sat on -- and on a ring the anchor is a RADIUS
	-- (Map.PlotRingInner) which every gate sits at instead. Keeping a dead
	-- coordinate around is keeping a number that looks authoritative and is not.
	-- Kept for the fit check. Plots are on a ring now, so this is no longer what
	-- spaces them -- the angle is -- but two plots closer together than this
	-- would still be too close, and MapService checks the arc against it.
	Pitch = 58,

	FloorName = "Ground",
	-- The soil part. It says "Soil" because that is what MapService actually
	-- names it -- this said "Planter" while the part was called Soil, and only a
	-- fallback in PlantService hid the mismatch.
	PlanterName = "Soil",
	TreadmillName = "Treadmill",
	SpawnPadName = "SpawnPad",
	RuntimeFolderName = "Runtime",
	-- Under Runtime: one invisible part per grown plant, named by placement id,
	-- at the server's authoritative wander position. Its existence is what tells
	-- PlantPickUI a plant is grown and yours. No prompt hangs on it -- see THERE
	-- IS NO PICKUP PROMPT in PlantService.
	PickupAnchorsFolderName = "PickupAnchors",
	PlantsFolderName = "Plants",

	--==========================================================================
	-- HOW LONG A NEWLY ASSIGNED PLOT WAITS FOR ITS OWNER'S SAVE
	--
	-- A plot is handed out on join; the garden and the mill it should show come
	-- off a profile that is a DataStore round trip behind -- measured at 38 s in
	-- Studio, and a throttled server is slower. PlantService waited 30 s and
	-- TreadmillService 20, then gave up silently: the garden was never put back
	-- and the first planting SAVED THAT EMPTY BED over the real one.
	--
	-- Now both wait for as long as the player stays, and this is only the
	-- backstop against a thread that would otherwise spin all session -- the
	-- same 600 s CarryService gives the held plants. If it ever runs out the bed
	-- stays shut: nothing is planted or saved over a garden that never arrived.
	--==========================================================================
	RestorePatienceSeconds = 600,

	--==========================================================================
	-- WHO HOLDS A PLOT: THE OWNER'S BADGE, HIGH OVER THE GATE
	--
	-- Replaced the low YOUR BASE / name plate on 2026-09-26 at the owner's
	-- request: the owner's Roblox headshot in a round frame with their username
	-- under it, floating well above the entrance where it names the plot from
	-- the approach without covering the gate, the bed or anybody walking in. The
	-- viewer's own plot wears an accent ring instead of a sentence.
	--
	-- SIZED IN STUDS, CLAMPED BY PlotOwnerLabels. Between NearStuds and FarStuds
	-- it shrinks with distance like any sign; nearer, it stops growing, and
	-- farther, it stops shrinking -- readable from the hub, never a wall of face
	-- at the gate. MaxDistance hides it past that, so the far side of the hub is
	-- not a row of heads. (BillboardGui's own DistanceLowerLimit/UpperLimit were
	-- tried first and MEASURED to do nothing to the drawn size, 2026-09-26: a
	-- stud badge ran 408 px at 8 studs to 22 px at 150 with both set.)
	--
	-- Its foot is HeightStuds - TallStuds/2 = 13.4 studs up: over the gateposts
	-- (5.8), a jump (7.2) and the camera's usual height walking in.
	--==========================================================================
	OwnerBadge = {
		HeightStuds = 17,
		WidthStuds = 6.4,
		TallStuds = 7.2,
		NearStuds = 28,
		FarStuds = 110,
		MaxDistance = 160,
		-- The round frame's share of the badge's height; the name takes the rest.
		FaceShare = 0.78,
		-- The ring, as a share of the face's diameter, so it scales with it.
		RingShare = 0.07,
		RingMine = Color3.fromRGB(142, 214, 86),
		RingTheirs = Color3.fromRGB(255, 255, 255),
		-- Behind the headshot while it loads, and the whole face if it never does.
		Fill = Color3.fromRGB(58, 44, 34),
		Name = Color3.fromRGB(255, 255, 255),
	},
	-- What a free plot keeps: one small word at the gate, no badge.
	UnclaimedTag = {
		HeightStuds = 8.5,
		WidthStuds = 5,
		TallStuds = 1.1,
		MaxDistance = 90,
		Colour = Color3.fromRGB(200, 200, 206),
	},
	--==========================================================================
	-- THE GARDEN'S NUMBERS, ON A PLAQUE OUTSIDE THE ENTRANCE
	--
	-- Plants and income, split off the badge (owner, 2026-09-26): a compact
	-- board on a short post just outside the fence, mirroring the upgrade board
	-- across the gate -- it stands at +OffsetX where that one stands at -OffsetX,
	-- the same Standoff out, so the gate is framed by the two and the opening
	-- between them (GateWidth) stays clear. Local, non-colliding and not
	-- queryable: signage cannot catch a runner or a planting click.
	--==========================================================================
	StatsSign = {
		OffsetX = 11.12,
		Standoff = 1.6,
		GroundY = 0,
		PostHeight = 3.4,
		BoardSize = Vector3.new(5.6, 2.5, 0.35),
		MaxDistance = 90,
		Plants = Color3.fromRGB(242, 238, 206),
		Income = Color3.fromRGB(255, 214, 92),
		Muted = Color3.fromRGB(206, 188, 160),
	},

	-- THE GAP IN THE FRONT FENCE.
	--
	-- The fence encloses all four sides, and without this there was no way IN --
	-- not physically, since the fence is non-collidable and you walk through it,
	-- but visually, which is the part that matters. A fully sealed rectangle
	-- reads as a pen. A gap with two taller posts either side reads as a garden
	-- gate, and it tells a player where their plot begins without a word.
	--
	-- It faces the road, so the opening is on the side every run comes home
	-- through -- you arrive at your gate rather than at the back of a fence.
	GateWidth = 13,

	--==========================================================================
	-- THE UPGRADE BOARD
	--
	-- Built by MillModel.BuildSign, the same one the mill uses, because two
	-- upgrade boards drawn by two builders is two things to keep in step and the
	-- one that gets forgotten is the one nobody is looking at.
	--==========================================================================
	Sign = {
		-- Clear of the gate on the left as you walk in. See plotSignBase for the
		-- arithmetic; this is not a number to nudge by eye.
		OffsetX = -11.12,
		-- BuildSign treats the frame it is handed as the post's GROUND BASE, so
		-- this is where the post's foot lands relative to the plot's own frame.
		--
		-- ZERO, not the mill's -0.6. The mill sits 0.6 studs proud of the field and
		-- its sign has to reach back down; a plot's frame is already on the ground.
		-- Measured before and after: at -0.6 the post's foot was at y -0.60 against
		-- a field at 0.00 -- buried by exactly that much.
		GroundY = 0,
		-- Just outside the fence line, so the board is read from the approach
		-- rather than from inside somebody's garden.
		Standoff = 1.6,
		-- The board faces the way the gate does, which is the way the plot's own
		-- local -Z points: at the hub, where players arrive from.
		YawDegrees = 0,
	},

	--==========================================================================
	-- THE TOP CREATURES BOARD (2026-10-05, the owner's brief)
	--
	-- Beside the upgrade board, on its OUTER side -- away from the gate, so the
	-- way in and the walk up to it stay as they were: the plot OWNER's two best
	-- grown creatures (the creature itself, its rarity, name, size and what it
	-- earns a second). Everybody sees every plot's board.
	--
	-- BUILT ONCE BY MapService (PlotShowcase.build), parented to the plots
	-- folder like the upgrade board -- ResizePlot clears a plot's children --
	-- and placed off the gate, which never moves: right at every level.
	--
	-- THE X IS ARITHMETIC (GameConfig.plotShowcaseBase): the upgrade board is
	-- MillModel.BuildSign's, 9 x Mill.Sign.Scale = 6.84 wide, centred at
	-- Sign.OffsetX -11.12, so its outer edge is at -14.54. Gap past that is
	-- this board's rim, and its centre is the rim and half the plank further
	-- out: -19.06, the rim's outer edge at -22.78 -- inside the fence run,
	-- short of its corner at -Width/2 = -24. The same Standoff off
	-- the fence and the same facing as the upgrade board, and its top at that
	-- board's top (7.75), so the two read as a pair. PlotShowcaseSpec measures
	-- the built board against the gate, the walk, the mill and its belt at
	-- every tier, every fence at every level and the neighbours on the ring.
	--
	-- WHAT IT SHOWS is published by PlotShowcaseService (plain attributes, only
	-- when the plot's planted creatures change) and drawn on every client by
	-- PlotShowcaseUI / PlotShowcaseView: the words are PlantLabel.content at
	-- the owner's rate. Its pictures exist only while the camera is near.
	--==========================================================================
	Showcase = {
		Slots = 2,
		-- Studs between the upgrade board's outer edge and this board's rim.
		Gap = 0.8,
		GroundY = 0,
		Standoff = 1.6,
		YawDegrees = 0,
		BoardSize = Vector3.new(7.2, 5.6, 0.46),
		-- The plank's top edge over the post's foot: the upgrade board's top
		-- (7.4 + 2.8) x Mill.Sign.Scale = 7.75.
		BoardTopY = 7.75,
		RimStuds = 0.12,
		PostWidth = 0.61,
		-- How far the post reaches up into the plank's lower edge, and how far
		-- its front face stands behind the lettered one (it is the thicker).
		PostOverlap = 0.45,
		PostInset = 0.02,
		-- The face's resolution: a 432 x 336 canvas on the 7.2 x 5.6 plank.
		PixelsPerStud = 60,
		-- Not drawn past this (the upgrade board's own 90).
		MaxDistance = 90,
		-- THE PICTURES: built when the camera comes within PreviewNearStuds of
		-- the board, freed past PreviewFarStuds (the gap is the hysteresis, so a
		-- camera on the edge never builds and frees every check), checked every
		-- CheckSeconds -- never a frame's work.
		PreviewNearStuds = 60,
		PreviewFarStuds = 75,
		CheckSeconds = 0.25,
		-- The server folds a burst (EQUIP BEST, an upgrade's re-render, a
		-- garden restored) into one publish this long after its first change.
		PublishDelaySeconds = 0.25,
		Title = "TOP CREATURES",
		-- A claimed plot with nothing grown in it (once its garden is known).
		EmptyTitle = "NO CREATURES YET",
		EmptyLine = "Grown creatures show up here",
		-- The second card while only one creature stands.
		EmptySlot = "EMPTY",
		-- The plain attributes PlotShowcaseService writes on the board, per slot.
		Attributes = {
			Species = { "Top1Species", "Top2Species" },
			Tier = { "Top1Tier", "Top2Tier" },
			Placement = { "Top1Placement", "Top2Placement" },
		},
	},

	SpawnHeightOffset = 4,

	--==========================================================================
	-- TELEPORT TO PLOT (PlotService.TeleportHome), 2026-09-23
	--
	-- The verb the HUD button sends on GameEvent, with NOTHING after it: no plot
	-- id and no destination, because the server takes both from who asked. The
	-- cooldown is the server's and starts at a teleport that happened, so a
	-- mashed button moves you once. The ground check reaches this far below the
	-- spawn point, so a plot caught mid-rebuild refuses rather than drops you.
	--==========================================================================
	TeleportAction = "TeleportToPlot",
	TeleportCooldownSeconds = 3,
	TeleportGroundProbe = 24,

	--==========================================================================
	-- BIOMES (PlotService.TeleportToBiomes), 2026-09-30, the owner's brief
	--
	-- One button, ONE destination: the GREENHOLLOW ENTRANCE, where the road
	-- begins. The verb carries nothing, like TELEPORT TO PLOT's; the landing is
	-- the server's (PlotService.BiomesLanding): on the road's centre line, this
	-- many studs inside the red line -- so still the Safe Zone, which every
	-- TeleportTo landing must be -- at the spawn height, facing down the road
	-- through Greenhollow's gate. No other biome has a destination: the rest
	-- of the road is walked.
	--
	-- Surveyed from the map 2026-09-30: nothing collidable near that spot but
	-- the field under it and the corridor's walls 70 studs to either side; the
	-- gate's bar is 36 up and the red line a flat decal; the nearest decor
	-- stands 25 studs off the centre line, past the line; Greenhollow's one nest
	-- and its pods are in the far corner, over 250 studs on.
	--==========================================================================
	BiomesAction = "TeleportToBiomes",
	BiomesLandingInset = 10,

	--==========================================================================
	-- THE BED
	--
	-- ONE continuous bed of soil inside a raised wooden border, from the owner's
	-- photo reference. An earlier version split it into two framed blocks with
	-- visible row divisions; the reference is a single plain rectangle and it is
	-- the better read -- soil is soil, and drawing rows on it before anything
	-- grows there is labelling an empty field.
	--
	-- The grid still exists, it is just invisible: plant slots are laid out
	-- Columns x rows across the surface. A ROW IS STILL A SLOT ROW, so the plant
	-- count and the bed's depth cannot drift apart.
	--
	-- ELEVATION IS 0.5. It was 2.2, which made every plot a platform you climbed
	-- rather than a bed set into the lawn.
	--==========================================================================
	BedColumns = 3,
	RowDepth = 11,
	RowGap = 1.2,
	-- Grass between the bed's FRAME and the fence.
	BedMargin = 6,
	BedInsetX = 5,
	-- How far the soil surface stands above the grass, and how far the wooden
	-- border stands above the soil. Both deliberately small: the border only has
	-- to read as an edge, not as a wall.
	BedHeight = 0.5,
	BedFrameLip = 0.25,
	BedFrameWidth = 2,

	--==========================================================================
	-- THE SIDE BED: ROOM, NOT CAPACITY
	--
	-- From Level 3 a plot grows a wing on ONE side. It holds a second bed and
	-- adds no slots whatsoever -- capacity stays 10 / 15 / 20 (25 / 30 at
	-- Levels 6-7) and lives in PlotTiers. This is floor space for twenty
	-- walking creatures, which a single 34-stud strip does not have.
	--
	-- ALWAYS THE SAME LOCAL SIDE, on every plot. Two neighbours flaring toward
	-- each other would meet in the gap between them; flaring the same way makes
	-- every wing point into the gap its neighbour just vacated, and the whole
	-- ring stays evenly spaced.
	--
	-- REAR-ANCHORED, which is what makes it fit at all. Plots sit on a ring, so
	-- the arc between two of them GROWS with distance from the hub: the chord
	-- between neighbouring centre lines is 0.84 * r, which is 84 studs at the
	-- gate and 165 at the back of a Level 5 plot. The wing starts where that
	-- extra room actually exists and the front edge never widens -- the gate
	-- stays exactly as narrow as it was, so nothing changes at the ring radius
	-- where the plots are tightest.
	--
	-- Rows here are PHYSICAL rows of soil. They are deliberately fewer than the
	-- main bed's at the same level, because the wing is shorter than the plot
	-- is deep -- it starts behind the gate, not at it.
	--==========================================================================
	SideBed = {
		-- How much wider the plot gets, on the +X local side.
		--
		-- WIDE RATHER THAN LONG, and that was the treadmill's doing. The mill
		-- stood on this same side, in the plot's front: from 2026-09-30 0.9 to
		-- 23.6 studs behind the gate (Mill.Place). A wing reaching forward past
		-- that fenced the mill in: the first build of this came out with 0.93
		-- studs between plot and treadmill, and until 2026-09-30 the wing's
		-- fence on Levels 3 and 4 ran through the mill's back. Since
		-- 2026-10-06 plots 1-5's mills stand IN FRONT of their plots and only
		-- plot 6's still stands here (Mill.Place.BesidePlots).
		-- MillPlacementSpec holds every tier clear of every level's fences.
		--
		-- So the wing starts BEHIND the mill and takes its area back across
		-- instead. Sideways is the direction with room -- the ring's arc grows
		-- with radius and the neighbour clearance measured 26.7 studs at 28
		-- wide, which is slack this can spend.
		WingWidth = 40,
		-- Grass inside the wing's fence before the bed's frame starts.
		WingMargin = 3,
		--==================================================================
		-- THE WING'S FENCE MAY NOT REACH FORWARD OF THIS -- LEVELS 1-5
		--
		-- In the LEVEL'S OWN frame, so on its own it only kept the mill clear at
		-- Level 5, where it was measured (the plot grows back from a fixed gate
		-- and the mill does not move). The mill's forward placement (Mill.Place)
		-- is what keeps Levels 3 and 4 clear of plot 6's mill, the one that
		-- still stands beside its plot; MillPlacementSpec checks both.
		--==================================================================
		WingFrontZ = -15,
		--==================================================================
		-- FROM LEVEL 6 THE WING GROWS FORWARD (owner, 2026-10-07)
		--
		-- Into the strip plots 1-5's mills stood in (0.9 to 23.6 studs behind
		-- the gate) until they moved in front of their plots. WingFrontZ stops
		-- applying from ForwardFromLevel; the wing's front fence then only has
		-- to stay MinBehindGate studs behind the gate line, and the gate itself
		-- stays exactly as narrow as it is. Six side rows at Level 6 and seven
		-- at Level 7 put that fence 13.2 behind the line on both, the rows still
		-- lined up with the main bed's. Plot 6 is not one of these plots: its
		-- mill still stands in that strip (Plot.Beside).
		--==================================================================
		ForwardFromLevel = 6,
		MinBehindGate = 10,
		-- Physical soil rows per level. Nothing below Level 3 has a wing.
		--
		-- Rear-anchored and capped by WingFrontZ, which is why Levels 3-5 are
		-- 2/3/4 rather than the 2/4/7 a plot with no mill beside it could carry:
		-- at Level 5 the bed may span 52.1 studs and five rows need 59.8.
		-- Levels 6-7 are capped by MinBehindGate instead (above).
		RowsByLevel = { 0, 0, 2, 3, 4, 6, 7 },
		-- Named so PlantService can find it, and so a save can say where a
		-- plant stands without the name being a position.
		Name = "SoilSide",
	},
	--==========================================================================
	-- PLOT 6 AT LEVELS 6-7: DEEPER, NEVER THROUGH OR AROUND ITS MILL
	--
	-- The owner's decision (2026-10-06): plot 6 keeps its mill beside its
	-- right-hand fence, so the strip the other plots' wings grow forward into
	-- (SideBed.ForwardFromLevel) is its mill's. A plot whose mill stands
	-- beside it (Mill.Place.BesidePlots) therefore keeps its Level 5 wing as it
	-- is -- the same fences, the same bed, at the same distance from the gate --
	-- and grows its MAIN bed deeper instead: Rows replaces PlotTiers' rows at
	-- the levels it names. The wing could not go further either way: forward is
	-- the mill and the road's empty arc, which Level 5's front corner already
	-- touches (1.4 studs); back is the field's front edge, 5.7 studs from that
	-- wing's back corner at Level 5.
	--
	-- THE SAME CAPACITY AND NO LESS ROOM (owner: "no plot is worse to own"):
	-- capacity is PlotTiers' at every level on every plot; the rows are chosen
	-- so plot 6's fenced ground and its soil are never smaller than plots
	-- 1-5's at the same level (Level 6: 8,133 against 7,938 square studs fenced,
	-- 5,120 against 5,023 of soil; Level 7: 9,304 against 9,011 and 5,950
	-- against 5,804). Its extra depth is exactly the other plots' forward wing
	-- (and, at Level 7, the wing's last row), which is what lets a garden move
	-- between the two shapes without a plant going anywhere it was not --
	-- GardenFrame.
	--==========================================================================
	Beside = {
		Rows = { [6] = 9, [7] = 11 },
		WingLevel = 5,
	},
	--==========================================================================
	-- THE FENCE IS A REAL BOUNDARY NOW
	--
	-- It was non-collidable throughout, on the reasoning that "the gap is not
	-- what lets you in -- you could always walk through the rails. It is what
	-- SHOWS you the way in, and a sealed rectangle read as a pen rather than as
	-- a garden." Asked to make it solid, so it is: the gate is now the way in
	-- because it is the ONLY way in.
	--
	--======================================================================
	-- THE FENCE IS THE FENCE, AND THERE IS NO INVISIBLE SLAB
	--
	-- FenceColliderThickness and FenceColliderHeight lived here, sizing a pane
	-- down the middle of each run: the rails were decoration and that pane did
	-- the stopping, eleven studs tall so it was ABOVE A JUMP.
	--
	-- The worry behind it was sound -- a 0.6 stud rail is thinner than one
	-- frame of travel at high WalkSpeed, so a sprinting player would pass
	-- through a merely-collidable one. But the answer to that is a thicker
	-- fence, not an invisible wall, and the wall cost something real: you could
	-- not hop your own fence.
	--
	-- MapService now builds two 1.6-stud boards topping out at 5.0. Wider than
	-- a frame of travel up to about 96 WalkSpeed, and low enough to jump. If a
	-- corner ever gets clipped, thicken the board there -- do not bring the
	-- pane back.
	--======================================================================

	--==========================================================================
	-- THE BED IS TILLED, NOT PAINTED
	--
	-- The soil was ONE PART in ONE COLOUR: a 34 x 121 stud slab of flat brown at
	-- the biggest tier, which is the largest single surface a player looks at in
	-- this game and had less going on than the grass beside it.
	--
	-- The rows already exist in the data -- RowDepth and RowGap have decided
	-- where plants stand since the first build -- and nothing drew them. So the
	-- gaps become FURROWS: a darker strip, set slightly below the surface, one
	-- per gap. That is the bed's own structure made visible rather than a
	-- texture invented on top of it, which is why it lines up with the planting
	-- for free and keeps lining up if the rows are ever retuned.
	--
	-- CLODS in the furrows on top of that, for small-scale break-up. In the
	-- furrows specifically because plants stand in row CENTRES -- a clod there
	-- would end up inside somebody's Bellchime.
	--
	-- COUNTED, because this game is mobile-first and the bed is not the budget:
	-- a four-row plot gains 3 furrows and 4 clods, a ten-row plot 9 and 10. At
	-- six plots of the largest tier that is 114 parts against a 1,563-part map.
	--==========================================================================
	--======================================================================
	-- THE ROWS ARE RAISED, THE GAPS ARE WHAT IS LEFT
	--
	-- The first attempt SANK a darker strip into the gaps and it was invisible:
	-- the soil is one opaque slab and a part below its surface is simply inside
	-- it. Nothing showed but the clods.
	--
	-- So it is the other way up, which is also how a real bed is built. The slab
	-- itself is darkened to the furrow tone and never moves -- PlantService
	-- derives every plant's height from `soil.Size.Y * 0.5`, so touching its size
	-- or its CFrame would lift or sink every garden in the game. The ROWS are
	-- added on top in the lighter earth, and the dark base showing between them
	-- IS the furrow. Real relief, no z-fighting, and nothing planted moves.
	--
	-- A plant therefore stands 0.18 below the crown of its own row. On a
	-- creature between 1.2 and 33 studs tall that is not a thing anybody can
	-- see, and it is the price of not moving the surface the save is measured
	-- against.
	--======================================================================
	SoilRowRise = 0.18,
	SoilClodsPerFurrow = 2,
	-- Every other furrow gets clods. All of them read as gravel rather than as
	-- broken earth.
	SoilClodStride = 2,
	SoilClodSize = 1.1,
}

--==============================================================================
-- PLOT TIERS
--
-- THE SYSTEM THAT SPENDS THESE IS PHASE D. THE SPACE THEY NEED IS RESERVED NOW,
-- and that ordering is not laziness in one direction or over-engineering in the
-- other -- it is the only order that works.
--
-- An upgrade button is a day's work whenever it is wanted. Plot GEOMETRY is
-- not: pitch, field size and the fixed front edge are baked into the map, and
-- a plot that has to grow with no room reserved forces every other plot to
-- move. Everybody's saved plot id then points at a different patch of ground.
--
-- So the tiers are decided today and only tier 1 is built. `MapService` reads
-- `depth` from here, so shipping tier 2 is changing a player's stored tier
-- number and rebuilding their plot -- no map surgery, no repacking the row.
--
-- Depth grows, width never does. Six long strips side by side is what an
-- allotment actually looks like, which is a happy accident of the constraint
-- that keeps the run home constant.
--
-- Slot counts are a first pass and will move once a plant model exists and
-- there is something real to space.
--==============================================================================
-- ROWS, not depth. Depth is derived from them, so a tier cannot be defined with
-- a size that does not fit a whole number of beds.
--==============================================================================
-- AND WHAT EACH ONE COSTS
--
-- `cost` is what the SHOP charges to move UP to that tier, in cash. Tier 1 is
-- where everybody starts, so its cost is 0 and is never shown.
--
-- FIRST-PASS NUMBERS, NOT TUNED. They are here because a shop cannot be drawn
-- without prices, and a placeholder in the data file is honest where a
-- placeholder buried in UI code would not be. Rough shape: each tier is about
-- ten times the last, so the first one is reachable in a session and the last
-- one is a goal.
--
-- For scale: one grown Nubkin pays 2/sec and one Bellchime pays 110/sec, so a
-- starting plot of twelve mixed plants is somewhere around 100-400/sec.
--==============================================================================
--==============================================================================
-- CAPACITY IS WRITTEN DOWN, NOT DERIVED
--
-- It used to be `rows * BedColumns` -- the invisible planting grid doubling as
-- the gameplay limit. That tied two things that have no business moving
-- together: how DEEP the plot looks and how MANY plants it holds. Widening the
-- bed by a column would silently have handed every player in the game three
-- more slots per row, and a ladder nobody can read off the table is a ladder
-- nobody can balance.
--
-- So `capacity` is the number, `rows` is the geometry, and the two are allowed
-- to disagree. Level 5 is seven rows for twenty plants precisely because the
-- plot has to LOOK like the biggest one without the count following the grid.
--
-- A planted pod and a grown creature each take one space. A creature being
-- carried takes none -- it is not in the ground.
--==============================================================================
--==============================================================================
-- LEVELS 6 AND 7 (owner, 2026-10-07)
--
-- On the ground the moved mills freed: plots 1-5's wings grow forward into the
-- strip their mills stood in (Plot.SideBed), and Level 7 is a row deeper as
-- well. `rows` is THOSE plots' main bed; plot 6, whose mill still stands in
-- that strip, is deeper instead (Plot.Beside). Capacity and cost are the same
-- on every plot. Levels 1-5 are exactly what they were.
--==============================================================================
GameConfig.PlotTiers = {
	{ capacity = 5,  rows = 2, cost = 0 },
	{ capacity = 7,  rows = 3, cost = 25000 },
	{ capacity = 10, rows = 4, cost = 250000 },
	{ capacity = 15, rows = 5, cost = 2500000 },
	{ capacity = 20, rows = 7, cost = 25000000 },
	{ capacity = 25, rows = 7, cost = 250000000 },
	{ capacity = 30, rows = 8, cost = 2500000000 },
}

--==============================================================================
-- WHAT VERSION 1 PLOTS WERE, KEPT FOR THE MIGRATION AND NOTHING ELSE
--
-- The old ladder was four levels of 4, 6, 8 and 10 rows, and capacity came out
-- of `rows * 3`. A saved garden's Z coordinates were measured against THAT
-- plot's depth, so migrating a profile needs the old depth to convert them --
-- see ProfileSchema. Nothing else may read this.
--==============================================================================
GameConfig.LegacyPlotRowsV1 = { 4, 6, 8, 10 }

-- What a plot is built at before anything is bought.
GameConfig.StartingPlotTier = 1

--==============================================================================
-- ONE ACTION NAME, AND THE CLIENT SENDS NOTHING ELSE
--
-- The Shop fires GameEvent with this and no payload worth forging: not a level,
-- not a price, not a plot id. The server reads the sender -- which is
-- engine-stamped -- looks up what they own, and decides everything. A client
-- that could name its own target level could buy Level 5 for the price of two.
--==============================================================================
GameConfig.PlotUpgradeAction = "PlotUpgrade"

--==============================================================================
-- MARIGOLD'S COUNTER: THREE VERBS ON THE SAME REMOTE
--
-- Same discipline as the plot upgrade above and for the same reason. The client
-- sends a VERB and, for two of these, one string that names a shelf item -- and
-- nothing else. Not a price, not a stat, not a target.
--
-- An item id has to cross the wire because the shop sells seven different
-- things and the server cannot read the player's mind about which card was
-- pressed. What it cannot do is decide anything: WeaponShopService looks the id
-- up in WeaponData, prices it from there, and charges the sender the server's
-- own number. A forged id names a weapon that does not exist and is dropped; a
-- real one buys exactly what its card says at exactly its card's price.
--
-- The shop OPEN verb travels the other way -- server to client, on the prompt
-- being held -- so that the panel cannot be opened by a client deciding it is
-- standing next to Marigold.
--==============================================================================
GameConfig.Weapon = {
	BuyAction = "WeaponBuy",
	EquipAction = "WeaponEquip",
	ShopAction = "WeaponShop",
	-- Server -> client only, carrying false. A refused PLACEMENT is the one
	-- weapon action that changes nothing on screen: a swing on cooldown is
	-- obviously a swing on cooldown, and a trap that will not go down looks
	-- exactly like a trap tool that is broken. Same shape as the mill's refusal
	-- and for the same reason -- the verb and `false`, no reason attached.
	DeniedAction = "WeaponDenied",
	-- Client -> server: REMOVE, carrying the id of the newest trap the owner's
	-- own records show (2026-10-04, the reusable-trap brief). CombatService
	-- removes it only if it is still the sender's newest remaining trap; a repeat
	-- finds it gone, and an id of somebody else's trap is dropped.
	TrapRemoveAction = "TrapRemove",
	--==========================================================================
	-- WHAT THE PROMPT SAYS, AND HOW LONG IT IS HELD
	--
	-- Longer than a pod's 0.7s and shorter than the sell board's 1.1s. Opening
	-- a shop is not destructive, so it does not need the sell board's pause --
	-- but Marigold stands two steps from that board and a shop that opened on a
	-- tap would open every time somebody walked past to sell their bag.
	--==========================================================================
	PromptText = "Open Shop",
	--==========================================================================
	-- NO HOLD. Owner's call, over the reasoning above.
	--
	-- That reasoning is left standing because it is still true: Marigold does
	-- stand near the sell board, and opening her shop is now a single tap. What
	-- keeps the two apart is that THE SELL BOARD KEPT ITS HOLD -- 1.1s, and
	-- deliberately not changed here -- so the destructive one of the pair is
	-- still the one you have to mean.
	--==========================================================================
	PromptHold = 0,
	PromptDistance = 11,
	-- The panel shuts itself when the player walks away. Deliberately WIDER
	-- than the prompt: a shop that slammed shut the instant you took a step
	-- back would be unusable on a phone, where the thumb is on the screen.
	CloseDistance = 26,
	--==========================================================================
	-- THE WORDS OVER HER STALL (2026-10-08, the owner: "new players dont know
	-- about where to buy bats, we will add a shop text above marigold like
	-- spinwheel")
	--
	-- Drawn like the wheel's "SPIN THE WHEEL!" (FloatingSign), in one plain
	-- colour no other hub sign wears -- a red orange, well clear of FREE
	-- CHEST's gold (a marigold orange sat too close to it), and the blue sky's
	-- opposite by day -- with a smaller second line of what she sells. Shown
	-- to every player in range all the time: anyone can buy. Each client's own
	-- (MarigoldSign).
	--
	-- On the STALL, not on Marigold: she wanders 6.5 studs either side of her
	-- spot, and the words never move. OVER THE ROOF since 2026-10-10 (the
	-- owner: "lift BAT SHOP! over the roof"), like SPIN THE WHEEL! over its
	-- arch: their foot 2 studs over the awning's high front edge (15.4 up),
	-- over the roof's middle. From 2026-10-08 they hung under the awning's
	-- front lip, because the wheel stood straight behind the stall and words
	-- over the roof sat on top of SPIN THE WHEEL! from the square and the road;
	-- the stall has left that line (Map.Stall, the shop row). Above is the
	-- middle of both lines over the counter's middle; Front is how far toward
	-- the customers (back over the roof's middle: -1.5). Width, Height and
	-- SubHeight are the lines' boxes in studs: the headline's letters come out
	-- 2.17 studs tall (TextService), a touch over the wheel's 2.01, and the
	-- second line's 1.3.
	--==========================================================================
	FloatingWords = {
		Text = "BAT SHOP!",
		SubText = "BATS & TRAPS",
		Colour = Color3.fromRGB(255, 105, 40), -- red orange #FF6928
		-- 11 since 2026-10-10 (Michael on v1047: bigger signs): the headline is
		-- width-bound, so it grew a tenth.
		Width = 11,
		Height = 2.4,
		SubHeight = 1.3,
		Above = 16.9,
		Front = -1.5,
	},
}

--==============================================================================
-- SELL ONE: THE OTHER BOARD, AND WHAT CROSSES THE WIRE FOR IT
--
-- Two verbs on GameEvent, the same discipline as the counter above. Server ->
-- client carries a `phase`: "quote" with a token, the species, the tier and the
-- SERVER'S price; "refused" with the one line to show; "sold" with the name and
-- what was paid. Client -> server answers a quote with its token and a yes or
-- a no, and nothing else -- not a price, not a species, not which Tool. The
-- server captured the exact Tool when it made the quote, prices that same Tool
-- again when the answer comes, and a token can only name the quote it was
-- minted for.
--==============================================================================
GameConfig.SellOne = {
	PromptText = "Sell One",
	-- Zero, like Marigold's shop prompt above and for the same reason: this
	-- only OPENS a confirmation, and the confirmation is the deliberate step.
	-- SELL ALL keeps its 1.1s hold because one press there is the whole sale.
	PromptHold = 0,
	PromptDistance = 12,
	-- How far from the board the player may stand when they answer. A little
	-- more than the prompt reaches, so a step back while reading the panel is
	-- not a refusal; nowhere near a walk to the road.
	ReachStuds = 18,
	-- A quote nobody answers is forgotten after this long.
	QuoteSeconds = 45,
	ServerAction = "SellOne",
	ClientAction = "SellOneReply",
	-- Empty hands, a bat, a trap, an unhatched pod, a raid pod on the back:
	-- everything that is not a grown plant in the hands gets the one line that
	-- says what would work.
	EmptyHandsText = "Hold a grown plant to sell it.",
	-- An Invite a Friend reward in the hands (2026-10-06): never sold.
	UnsellableText = "Invite rewards can't be sold.",
	-- The plant left the hands, or was sold another way, between the quote and
	-- the answer. Nothing else is ever put in its place.
	ChangedText = "That plant is no longer in your hands.",
	TooFarText = "Stand at the SELL ONE sign to sell.",
	ExpiredText = "That offer expired. Press the sign again.",
}

--==============================================================================
-- SELL ALL: THE SAME QUOTE-THEN-ANSWER, FOR THE WHOLE BAG
--
-- It used to sell on the prompt: a 1.1s hold and the bag was gone, with the
-- count and the payout only in the server log. Now the hold asks for a quote --
-- how many plants, how many pods, and what they pay -- and nothing is sold
-- until the player says yes to exactly that. It rides SELL ONE's channel and
-- its reach, expiry and token rules (SellService); these are its own words.
--==============================================================================
GameConfig.SellAll = {
	-- Nothing in the bag or the hands that the stall buys.
	EmptyText = "Nothing in your bag to sell.",
	-- The bag gained, lost or changed something between the quote and the yes.
	-- Nothing is sold; the player presses the sign again for a fresh count.
	ChangedText = "Your bag changed. Press SELL ALL again.",
	TooFarText = "Stand at the SELL ALL sign to sell.",
	-- FAVOURITES ARE KEPT (2026-10-03): SELL ALL never sells an item with a
	-- heart (SELL ONE still does). Said when nothing but favourites is left,
	-- and counted on the quote ("%d favourite(s) kept").
	FavouritesText = "Only favourites left. SELL ALL keeps them.",
	-- Nothing left but Invite a Friend rewards, which no stall buys (2026-10-06).
	InviteOnlyText = "Only invite rewards left. They can't be sold.",
	KeptText = "%d favourite%s kept",
}

--==============================================================================
-- THE SACRIFICE PEDESTAL: PLACE, NAMES AND VERBS (2026-09-28)
--
-- The numbers -- how much, how long, how often -- are SeedData.Sacrifice. The
-- rules are SacrificeService's. These are where it stands, what its replicated
-- fields are called and the two verbs it uses on the GameEvent remote.
--==============================================================================
GameConfig.Sacrifice = {
	Enabled = true,
	FolderName = "SeedSacrificePedestal",
	--==========================================================================
	-- WHERE IT STANDS (the shop row, 2026-10-10: Map.Stall's comment)
	--
	-- At the west end of the row along the red line, facing north into the
	-- field: 180 turns its front from -Z to +Z; its back, which carries the
	-- same sign, faces the red line. Its prompt is further from every other
	-- than their two reaches added (EventHubSpec). It stood on the hub deck's
	-- south rim from 2026-09-28. Y is the grass.
	--==========================================================================
	Position = Vector3.new(-252, 0, -157),
	FacingDegrees = 180,
	PromptDistance = 10,
	-- Held a moment, like the chest's.
	PromptHoldSeconds = 0.35,
	-- How far from the pedestal a quote may be asked for or answered. Wider than
	-- the prompt, so a player who stepped back to read the panel is still there.
	ReachStuds = 16,
	-- A quote nobody answers is forgotten after this long: SELL ONE's 45, so
	-- the game's two "are you sure" panels give the same time to read them.
	QuoteSeconds = 45,
	ServerAction = "SacrificeResult",
	ClientAction = "SacrificeReply",
	Attributes = {
		-- os.time() the pedestal is ready again for this player; 0 if never used.
		NextAt = "SacrificeNextAt",
		-- The os.time() the running boost ends, and what it multiplies garden
		-- income by; both nil when none is running.
		EndsAt = "SacrificeEndsAt",
		Multiplier = "SacrificeMultiplier",
	},
	--==========================================================================
	-- WHAT THE PLAYER IS TOLD, BY REASON
	--
	-- SacrificeService names why it refused; these are the words SacrificeUI
	-- puts up: a headline, and under it the next step that works for that
	-- reason. Here, not in the client script, so HudLayoutSpec can measure every
	-- one against the notice's width on every listed phone.
	--
	-- COOLDOWN has no next step written down: the client fills in the time left
	-- (sacrificeReadyIn). A reason that is not here -- a body mid-respawn, the
	-- pedestal switched off -- is not something a player did, and says nothing.
	-- NOT_A_POD and NOT_OWNED share a line: either way, what works is a pod out
	-- of the Bag.
	--==========================================================================
	Notices = {
		COOLDOWN = { title = "PEDESTAL RECHARGING" },
		NOTHING_HELD = { title = "NO POD IN HAND", detail = "Hold an unhatched pod from your Bag." },
		NOT_A_POD = { title = "NOT A POD", detail = "Hold an unhatched pod from your Bag." },
		NOT_OWNED = { title = "NOT A POD", detail = "Hold an unhatched pod from your Bag." },
		HATCHED = { title = "PODS ONLY", detail = "A grown plant can't be sacrificed." },
		CARRYING = { title = "BANK IT FIRST", detail = "Carry that pod past the red line." },
		NO_GARDEN = { title = "NOTHING TO BOOST", detail = "Grow a plant on your plot first." },
		TOO_FAR = { title = "TOO FAR AWAY", detail = "Stand beside the pedestal." },
		EXPIRED = { title = "OFFER EXPIRED", detail = "Press the pedestal again." },
		CHANGED = { title = "POD NOT IN HAND", detail = "Nothing was taken. Press the pedestal again." },
		NOT_SAVED = { title = "PEDESTAL CLOSED", detail = "Saving is off here, so nothing was taken." },
		NOT_READY = { title = "STILL LOADING", detail = "Try again in a moment." },
		BAG_NOT_READY = { title = "STILL LOADING", detail = "Try again in a moment." },
		FAILED = { title = "NOTHING TAKEN", detail = "The pedestal couldn't start. Try again." },
	},
	SuccessTitle = "POD SACRIFICED",
	--==========================================================================
	-- THE WORDS THAT FLOAT OVER IT (2026-09-30, the owner's ask; reworked
	-- 2026-10-01)
	--
	-- Shown to every player all the time now, ready or not. Drawn like the
	-- wheel's sign (FloatingSign), in one plain colour, with a smaller second
	-- line of what it buys -- written from the pedestal's own numbers by
	-- sacrificeBoostTitle, so the two cannot disagree -- and a third, the note:
	-- sacrificeExplain's one sentence while that player's pedestal is ready, or
	-- how long until it is while it recharges.
	--
	-- Width, Height, SubHeight and NoteHeight are the lines' boxes in studs
	-- (letters 1.9 studs, just under the wheel's 2.0; the second line 1.3; the
	-- sentence two lines of about 0.7): a quarter bigger than they were, so they
	-- still read zoomed out. Above is the middle of all three over the offering
	-- bowl, high enough that the box starts well above the prompt drawn over
	-- the bowl even on a phone -- and the note, not the "+50%", is the line
	-- nearest to it.
	--==========================================================================
	FloatingWords = {
		Text = "SACRIFICE A POD!",
		Colour = Color3.fromRGB(140, 255, 106), -- #8CFF6A
		Width = 14.5,
		Height = 2.6,
		SubHeight = 1.3,
		NoteHeight = 1.5,
		Above = 7.8,
	},
}

--==============================================================================
-- INVITE A FRIEND (2026-10-06, the owner's track)
--
-- A friend who joins the game through a player's invite counts once for that
-- player, forever; at 1, 5, 10 and 20 such friends the player is GIVEN a grown,
-- placeable, unsellable plant (SeedData.InviteSpecies: Dustthorn, Thornbrute,
-- Pharaothorn, Heliothorn). InviteService counts and grants -- server only --
-- and publishes the confirmed count; everything a client draws (the hub
-- pedestal and its sign, the INVITE button and its "!", the INVITE panel) is
-- InviteRewards' pure answer for that count. The balance -- rarities and
-- incomes -- is SeedData's; this is the structure, the words and the place.
--==============================================================================
GameConfig.InviteRewards = {
	Enabled = true,
	-- Friends needed for each form, in order; Forms[i] is given at Thresholds[i].
	Thresholds = { 1, 5, 10, 20 },
	Forms = { "dustthorn", "thornbrute", "pharaothorn", "heliothorn" },
	--==========================================================================
	-- WHO COUNTS
	--
	-- A join counts when the joining player's GetJoinData().ReferredByPlayerId
	-- names the inviter, the two are different players, and the joiner's save
	-- was NEW this session (a first-time player of the game). The owner was
	-- asked whether a returning player may count; until answered, they may not.
	--==========================================================================
	CountReturningPlayers = false,
	-- The most invited ids one save remembers (each counted once, forever).
	MaxRemembered = 200,
	-- Credit for an inviter who is not in the joiner's server waits in the
	-- inviter's inbox (SaveService) and is taken on their next join, and every
	-- InboxPollSeconds while they play. At most InboxMax ids wait.
	InboxPollSeconds = 60,
	InboxMax = 200,
	-- A tier owed while the Bag is full is tried again this often.
	RetrySeconds = 5,
	-- The rules line (Words.Rules) turns this often in the INVITE panel, and the
	-- hub sign shows the rules for RulesSignSeconds in every RulesSignCycle.
	RulesSeconds = 4,
	RulesSignSeconds = 6,
	RulesSignCycle = 18,
	-- Player attributes the server writes and every client screen reads.
	Attributes = {
		-- Friends counted (confirmed, saved).
		Count = "InviteCount",
		-- Forms given: 0 .. #Forms. A tier is shown only once it is given.
		Granted = "InviteGranted",
		-- The INVITE panel has been opened since the last form was given.
		Seen = "InviteSeen",
		-- The invite plants ever given, by the track or the wheel (2026-10-08):
		-- their ids, comma-separated. A card shows EARNED for a plant owned.
		Owned = "InviteOwned",
	},
	-- client -> server on GameEvent, carrying nothing: "the INVITE panel opened".
	OpenedAction = "InviteOpened",
	-- server -> client on GameEvent: what InviteService tells one player (a
	-- friend joined, a form given, the Bag full, WELCOME!), read by InviteNews.
	NoticeAction = "InviteNotice",
	-- client -> server, carrying nothing: this client is listening now. What the
	-- server had to say before then -- a join's WELCOME!, a form given while the
	-- profile loaded -- is held for it and sent then (InviteService).
	ReadyAction = "InviteReady",
	-- The most a server holds for one player before READY.
	HeldMax = 20,
	--==========================================================================
	-- WHERE THE PEDESTAL STANDS (the shop row, 2026-10-10: Map.Stall's comment)
	--
	-- In the row along the red line, between the wheel and the shrine, facing
	-- north into the field: 180 turns its front (-Z) to +Z, the plate's face
	-- with it. From 2026-10-06 it stood on the deck's south-south-west rim by
	-- the road mouth, scored against every spawn pad's walk; the plate was
	-- made big to read from the nearest spawn pad, which the row is too far
	-- from now: it reads from the stall's counter instead (InviteRewardsSpec).
	-- Y is the grass.
	--==========================================================================
	Position = Vector3.new(-207, 0, -157),
	FacingDegrees = 180,
	FolderName = "SeedInvitePedestal",
	PromptDistance = 10,
	PromptAction = "INVITE A FRIEND",
	PromptObject = "Invite Friends",
	-- The pedestal, stone like the Sacrifice pedestal's, its top studded.
	Pedestal = {
		Foot = Vector3.new(8.4, 0.5, 8.4),
		Column = Vector3.new(6.6, 1.1, 6.6),
		Top = Vector3.new(7.6, 0.4, 7.6),
		Stone = Color3.fromRGB(83, 83, 76),
		TopColour = Color3.fromRGB(58, 112, 66),
	},
	-- The sign: a studded plate (the Shop's baseplate look) over the pedestal,
	-- resting on two pillars. `Bottom` is its lower edge above the pedestal's
	-- base, clear of the tallest form's aura.
	--
	-- READ FROM THE NEAREST SPAWN PAD (the owner, 2026-10-06). Plot 1's pad sees
	-- the plate's back 55 degrees from the side, its follow camera ~91 studs off:
	-- on a 705 x 338 phone the old 14 x 7.4 plate's title was 2.9 px tall and
	-- 0.8 px a letter. The owner chose a bigger plate with a far view: 20 x 11,
	-- on the same two pillars -- their feet where they stood beside the old
	-- plate, so the deck and every prompt clearance are as measured; they end
	-- under it now -- and past FarFrom studs (camera to plate) it shows only
	-- SignFar, two lines as large as the plate allows: ~13 px tall and ~4 px a
	-- letter from that pad. Nearer, the whole sign, every line Height / 7.4
	-- (~1.5x) what it was.
	Sign = {
		Width = 20,
		Height = 11,
		Depth = 0.5,
		Bottom = 14.2,
		PillarWidth = 0.9,
		-- The pillars' centres either side of the pedestal's: where they stood
		-- beside the old 14-stud plate (7 + half their width).
		PillarHalf = 7.45,
		-- The dark keyline round the plate, studs.
		Keyline = 0.35,
		-- Its face, in pixels a stud (SurfaceGui CanvasSize: Width x Height x
		-- this). Coarse on purpose: TextScaled stops at 100 px, so the far
		-- view's 5-stud letters need 20 or fewer.
		PixelsPerStud = 20,
		-- The far view from this many studs, camera to plate, and the whole sign
		-- again under FarFrom - FarBand (no flicker on the line); the far words'
		-- margin, canvas pixels.
		FarFrom = 45,
		FarBand = 4,
		FarPad = 10,
		-- The whole sign's rows, { top, height }, in the old 700 x 370 canvas's
		-- units (InviteHub multiplies them by the canvas's height over 370): the
		-- header band and the title in it, the name, the rarity and $/s, NEXT,
		-- and the bar with its count in it. NEXT stands well clear of the bar
		-- -- more than any other two rows are apart -- and the count sits inset
		-- in the bar: in p18b (2026-10-06) the count's numerals rose past the
		-- bar's top edge into NEXT.
		Rows = {
			Header = { 12, 66 },
			Title = { 6, 54 },
			Name = { 86, 82 },
			Info = { 170, 46 },
			Next = { 220, 38 },
			Bar = { 284, 66 },
			Count = { 12, 42 },
		},
		-- Readable from across the deck, and gone beyond it (the farthest pad is
		-- 140 studs off).
		MaxDistance = 160,
	},
	-- How big each form stands ON THE PEDESTAL (the owner, 2026-10-06: "the
	-- plant must not look small" under the 20 x 11 plate). The pedestal's
	-- DISPLAY copy only -- never the source model or a granted plant -- scaled
	-- whole (InviteRewards.displayScale) so its highest point at rest stands
	-- DisplayFill of the way from the pedestal's top to the plate's keyline;
	-- and never, even at the top of an aura's flare (the sphere swells to
	-- AuraSwell -- PlantIdles: 1 + 0.03 breath + 0.10 flare), closer than
	-- DisplayClear studs to the keyline or the pillars. Its lights scale with
	-- it, never past DisplayLightMax. The copy collides with nothing and the
	-- prompt is drawn on top, so neither the prompt nor the deck is crowded:
	-- the plate stays where it is.
	DisplayFill = 0.94,
	DisplayClear = 0.25,
	AuraSwell = 1.13,
	DisplayLightMax = 60,
	-- The evolve moment, under 2 s: the old form shrinks away, a burst, the new
	-- one grows in. No animation on join.
	Evolve = {
		Shrink = 0.45,
		Hold = 0.15,
		Grow = 0.75,
		-- The burst's sound: the owner's invite_evolve, on the pedestal (a SoundKit cue).
		Sound = "InviteEvolve",
		Sparks = 40,
	},
	--==========================================================================
	-- THE OWNER'S TEN INVITE SOUNDS (uploaded 2026-10-06; economy details: Audio,
	-- CrazyCozy Games, names as below). The ONLY ids these moments use. Each is
	-- also a SoundKit cue (GameConfig.Sfx.Cues, Invite*), so it plays through the
	-- player's own UI or World bus and the Settings volume and mute apply. Volume
	-- is the one number to tune by ear; the clips are never trimmed or pitched.
	--
	--   Send      INVITE FRIENDS opened Roblox's invite dialog (never on refusal)
	--   Joined    with the "+1 INVITE" notice (a refreshed one stays silent)
	--   Tick      the bar filling one step (the panel open, or the sign in view);
	--             at most TickRun in a row, then silent until TickQuiet passes
	--   BadgePop  the "!" coming up for a form earned live (never on join, never
	--             for the never-opened call to action)
	--   Welcome   the invited friend's "WELCOME!" notice, once
	--   Evolve    the pedestal's evolve moment, 3D on the pedestal (EvolveRange)
	--   Unlock*   the reward popup's entrance, by the form's rarity -- in place of
	--             a generic fanfare, for invite rewards only
	--==========================================================================
	Sounds = {
		Send = { Id = "rbxassetid://77331637660005", Volume = 0.6 },
		Joined = { Id = "rbxassetid://89247518748364", Volume = 0.65 },
		Tick = { Id = "rbxassetid://83632422237204", Volume = 0.45 },
		BadgePop = { Id = "rbxassetid://91054387401588", Volume = 0.55 },
		Welcome = { Id = "rbxassetid://111245625596729", Volume = 0.6 },
		Evolve = { Id = "rbxassetid://118129555423964", Volume = 0.7 },
		UnlockEpic = { Id = "rbxassetid://70816923180534", Volume = 0.7 },
		UnlockLegendary = { Id = "rbxassetid://79976838694273", Volume = 0.7 },
		UnlockMythic = { Id = "rbxassetid://88512685687885", Volume = 0.7 },
		UnlockSecret = { Id = "rbxassetid://116733502135083", Volume = 0.75 },
	},
	-- Which unlock sound a form's rarity plays (the four the track uses).
	UnlockCue = {
		Epic = "InviteUnlockEpic",
		Legendary = "InviteUnlockLegendary",
		Mythic = "InviteUnlockMythic",
		Secret = "InviteUnlockSecret",
	},
	-- How far the evolve sound carries from the pedestal: the deck, not the map.
	EvolveRange = 70,
	-- The progress tick: at most this many in a row, then silent for this long.
	TickRun = 3,
	TickQuiet = 4,
	-- Two "+1 INVITE"s this close together are one notice, and the second is silent.
	JoinedQuiet = 4,
	--==========================================================================
	-- THE REWARD POPUP (InviteRewardUI): a card per form given, upper middle,
	-- never modal, no dimmer -- the player can walk away; the plant is already in
	-- the Bag. Rect: MenuLayout.rewardPopup. Every animation is decoration.
	--==========================================================================
	Popup = {
		Ribbon = "NEW FORM UNLOCKED!",
		FinalRibbon = "FINAL FORM!",
		-- "Invite reward: 20 friends \u{2022} Unsellable"
		Line = "Invite reward: %d %s \u{2022} %s",
		Friend = "friend",
		Friends = "friends",
		Place = "PLACE IT",
		Later = "LATER",
		-- Untouched, it closes itself after this long (the final form's longer).
		AutoClose = 8,
		FinalAutoClose = 12,
		-- In: 0.6 -> 1.08 -> 1.0; out: shrink and fade.
		InSeconds = 0.35,
		OutSeconds = 0.2,
		-- Between two cards of one grant.
		Gap = 0.6,
		-- At join, nothing for this long: the offline earnings card may still be
		-- on its way, and WHILE YOU WERE AWAY and the cards come after it.
		JoinSettle = 3,
		-- WHILE YOU WERE AWAY stands this long before the first card.
		AwayLead = 2.5,
		-- How often the queue looks again while another moment is up.
		Wait = 0.5,
		-- The rays' turn, degrees a second.
		RaySpin = 12,
		-- The whole card's grey for LATER and its ring.
		LaterFace = Color3.fromRGB(150, 156, 160),
		-- INTENSITY BY RARITY (values, not branches): rays' brightness (0..1, the
		-- rays' transparency is 1 minus it), sparkles round the model (count and
		-- size), an edge glow on the screen, confetti, the burst's length, the rim
		-- (nil: the rarity's own colour).
		Intensity = {
			Epic = { rays = 0.45, sparkles = 0, sparkleSize = 0, edge = false, confetti = 0, burst = 0.6 },
			Legendary = { rays = 0.55, sparkles = 8, sparkleSize = 10, edge = false, confetti = 0, burst = 0.8 },
			Mythic = { rays = 0.75, sparkles = 12, sparkleSize = 14, edge = true, confetti = 0, burst = 1.0 },
			Secret = { rays = 0.85, sparkles = 14, sparkleSize = 14, edge = true, confetti = 36, burst = 1.6,
				rim = Color3.fromRGB(255, 205, 64) },
		},
	},
	--==========================================================================
	-- THE WORDS (the sign, the panel and the notices)
	--==========================================================================
	Words = {
		Title = "INVITE FRIENDS",
		-- The hub sign's far view (Sign.FarFrom): the title on two lines.
		SignFar = { "INVITE", "FRIENDS" },
		-- NEXT: Thornbrute (Legendary) at 5 invites
		Next = "NEXT: %s (%s) at %d %s",
		One = "invite",
		Many = "invites",
		Final = "FINAL FORM REACHED",
		Bar = "%d / %d",
		Income = "$%s/s",
		Unsellable = "Unsellable",
		Claimed = "CLAIMED",
		-- A card's own line under its name: "5 invites".
		Needs = "%d %s",
		-- ... and an owned card's, when the wheel gave some of the plants and
		-- which milestone gave which is not known (InviteRewards.cards, 2026-10-08).
		Owned = "owned",
		Button = "INVITE FRIENDS",
		How = "Friends count when they join the game from your invite.",
		-- THE RULES, IN SHORT WORDS (2026-10-08, the owner's brief): the INVITE
		-- panel shows them one at a time under its button, and the hub sign
		-- between its progress views. Each fits one line on a phone
		-- (InvitePanelSpec measures them).
		RulesTitle = "HOW INVITES WORK",
		Rules = {
			"A friend counts once: their first time playing",
			"1 - 5 - 10 - 20 friends: 4 invite plants",
			"Played before? You still get 1 free spin",
		},
		-- A friend who had played before came back through your invite: 1 free
		-- spin, once per friend, ever (InviteService.CreditReturning).
		Returning = "+1 FREE SPIN",
		ReturningDetail = "%s came back from your invite",
		-- THE NOTICES (Notice.post; InviteRewards.notice words each server
		-- payload; the owner's notices brief, 2026-10-06). A name is a player's
		-- DisplayName, or SomeFriend -- never a UserId.
		-- Invites cannot be sent (CanSendGameInviteAsync false or failed): blocked.
		CantSend = "CAN'T SEND INVITES",
		CantSendDetail = "Invites aren't available on this account",
		-- A friend joined through your invite and counts: success.
		-- "<DisplayName> joined! <count>/<next threshold>"
		Joined = "+1 INVITE",
		JoinedDetail = "%s joined! %d/%d",
		-- A friend joined through your invite and does not count: info, the
		-- headline "<DisplayName> joined", the line why.
		NotCounted = "%s joined",
		NotCountedWhy = {
			returning = "Already played, so it doesn't count",
			known = "Already counted from an earlier invite",
		},
		-- The invited friend's own notice, once, only for a referral the server
		-- confirmed: info. "You joined from <inviter DisplayName>'s invite".
		Welcome = "WELCOME!",
		WelcomeDetail = "You joined from %s's invite",
		-- Friends credited while the inviter was away, told on their next join:
		-- info, once, after the offline earnings card and before the reward cards.
		Away = "WHILE YOU WERE AWAY",
		AwayDetail = "%d %s joined from your invites",
		Friend = "friend",
		Friends = "friends",
		-- Whoever's name is not known.
		SomeFriend = "a friend",
		Earned = "INVITE REWARD: %s",
		EarnedDetail = "%s, %s -- in your Bag, ready to place.",
		Full = "PLANT STORAGE FULL",
		FullDetail = "Make room in your Bag for your invite reward.",
	},
	--==========================================================================
	-- THE INVITE PANEL (InviteUI): what is not MenuKit's look or a rarity's
	-- own colour. Its rects are MenuLayout.Invite's.
	--==========================================================================
	Panel = {
		-- The road the four cards stand on, and its dashed middle line.
		Road = Color3.fromRGB(62, 56, 50),
		RoadLine = Color3.fromRGB(246, 232, 178),
		RoadDash = 10,
		RoadDashGap = 8,
		-- The bar's raised studs (the hub sign's), every StudPitch px.
		StudPitch = 16,
		StudSize = 8,
		StudTransparency = 0.72,
		-- How much of its window a form fills: the hero's, a card's.
		HeroFill = 0.78,
		CardFill = 0.8,
		-- A card given while the panel is open: it pops, sparks fly, CLAIMED
		-- comes up. Decoration: the card is right without it.
		BurstSparks = 10,
		BurstSeconds = 0.6,
		PopScale = 1.12,
		-- The bar filling one friend at a time while the panel is open.
		StepSeconds = 0.15,
		-- The words' smallest drawn size (after the menu's scale).
		MinText = 10,
		TinyText = 9,
	},
	-- Heliothorn's card rim, at every state, and the final sign's trim.
	Gold = Color3.fromRGB(255, 205, 64),
	-- An earned card's tick.
	Tick = Color3.fromRGB(110, 220, 96),
	-- A locked card's silhouette (ViewportFrame.ImageColor3).
	Silhouette = Color3.fromRGB(18, 22, 20),
	-- The next card's slow pulse: its rim breathes this often.
	PulseSeconds = 1.6,
	-- The hero picture's slow turn, degrees a second.
	TurnDegrees = 18,
	-- The income gold (the garden plaque's), the words' cream and the ink line.
	Income = Color3.fromRGB(255, 214, 92),
	Cream = Color3.fromRGB(248, 240, 214),
	Ink = Color3.fromRGB(16, 30, 22),
}

-- The boost row's words, in one place: BonusChestUI draws them and
-- HudLayoutSpec measures them against every listed phone.
function GameConfig.sacrificeBoostTitle(multiplier: number): string
	return string.format("+%d%% GARDEN INCOME", math.floor((multiplier - 1) * 100 + 0.5))
end

-- A length of time in the pedestal's panel and notices: "45 seconds",
-- "3 minutes", "2 min 30 s" -- whatever SeedData says, said plainly.
function GameConfig.sacrificeSpan(seconds: number): string
	local s = math.max(0, math.floor(seconds + 0.5))
	if s < 60 then
		return string.format("%d second%s", s, if s == 1 then "" else "s")
	end
	if s % 60 == 0 then
		return string.format("%d minute%s", s // 60, if s == 60 then "" else "s")
	end
	return string.format("%d min %d s", s // 60, s % 60)
end

-- What one pod buys, as the panel offers it and the success notice confirms it.
function GameConfig.sacrificeOffer(multiplier: number, seconds: number): string
	return string.format("+%d%% garden income for %s", math.floor((multiplier - 1) * 100 + 0.5),
		GameConfig.sacrificeSpan(seconds))
end

-- The one sentence the pedestal's floating words carry while it is ready:
-- "Sacrifice one owned, banked pod for +50% garden income for 45 seconds."
function GameConfig.sacrificeExplain(multiplier: number, seconds: number): string
	return "Sacrifice one owned, banked pod for " .. GameConfig.sacrificeOffer(multiplier, seconds) .. "."
end

-- The COOLDOWN notice's next step: the time left, as the sign counts it.
function GameConfig.sacrificeReadyIn(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("Ready in %d:%02d.", s // 60, s % 60)
end

--==============================================================================
-- OFFLINE EARNINGS: THE CLAIM, BY NAME
--
-- Names and words only; the numbers are SeedData.Offline. The pending claim is
-- published as player attributes -- server-set, so a client can read them and
-- cannot change them -- and the client asks to be paid with one verb on
-- GameEvent that carries nothing. The server answers with the amount it paid.
--==============================================================================
GameConfig.OfflineEarnings = {
	ClaimAction = "OfflineClaim",
	ReplyAction = "OfflineClaimed",
	Attributes = {
		-- The pending claim before the x2 pass; the pass is applied on payment.
		Cash = "OfflineCash",
		-- Seconds actually credited (capped) and seconds actually away.
		Seconds = "OfflineSeconds",
		Away = "OfflineAway",
		-- The garden that earned it: how many grown plants, and the best one.
		Grown = "OfflineGrown",
		Best = "OfflineBest",
		BestTier = "OfflineBestTier",
	},
	Title = "WHILE YOU WERE AWAY",
	ClaimText = "CLAIM",
}

GameConfig.Attributes = {
	PlotId = "PlotId",
	OwnerUserId = "OwnerUserId",
	-- The owner's NAME as well as their id, so a client can label a plot without
	-- a GetNameFromUserIdAsync round trip per plot. Attributes replicate on
	-- their own, so this is also why "who owns this" needs no remote.
	OwnerName = "OwnerName",
	Claimed = "Claimed",
	BiomeId = "BiomeId",
	-- Phase A+
	-- What the player is holding. Set on the PLAYER, not the character, so it
	-- survives a respawn boundary and replicates to every client for free --
	-- the prompt UI reads it to decide whether to draw itself at all.
	--
	-- These were "CarryingSeed" here while CarryService wrote CarryingSpecies
	-- and CarryingKg. Two names for one fact is a bug waiting for whoever trusts
	-- the wrong one.
	CarryingSpecies = "CarryingSpecies",
	CarryingKg = "CarryingKg",
	-- On a plant or pod TOOL (2026-10-03): which saved row it is -- profile.Held's
	-- `Item`. Two identical Nubkins are two items, and a hotbar shortcut names one.
	ItemId = "ItemId",
	-- On the PLAYER (2026-10-03): true once the server has put back everything the
	-- save holds and is recording the bag again (CarryService's rebuild); false
	-- while a body or Backpack is being replaced. The hotbar waits on it.
	HeldRestored = "HeldRestored",
	-- On a POD (the carried model and the loose pod): a confiscating guardian
	-- chose to leave it behind, so no confiscating guardian will ever take it.
	-- The pod's, never a player's. See GuardianCatch.
	GuardianAbandoned = "GuardianAbandoned",
	--==========================================================================
	-- WHICH LEFT-RAIL PANEL IS OPEN, IF ANY
	--
	-- The Index and the Shop both dock on the LEFT and both are full height, so
	-- they occupy the same rectangle and cannot both be open. Rather than have
	-- one script reach into the other's ScreenGui, each writes its own name here
	-- when it opens and clears it when it closes, and each closes itself when it
	-- sees a name that is not its own.
	--
	-- The Garden is deliberately NOT part of this. It docks on the RIGHT, it
	-- never overlaps either of them, and being able to read your own dirt while
	-- looking at a shop price is the point of having two rails.
	--==========================================================================
	OpenPanel = "OpenPanel",
	-- On the local player, set by TutorialUI (on the client, like OpenPanel):
	-- how far down the screen the guide's own words reach right now -- its
	-- banner's skip line, or the first-hatch celebration's foot -- in the HUD's
	-- units (HudLayout's safe space); nil when neither is up. BonusChestUI
	-- stands its boost row under it: the chest opens only after the guide, but
	-- the reward wheel (2026-09-27) can hand a new player a boost in the middle.
	TutorialReach = "TutorialReach",
	-- On a HUD button, client-local, set by TutorialUI's spotlight (2026-10-08)
	-- while it lights that button and holds a controller's selection on it:
	-- the button's own D-pad key presses it then (PlotTeleportUI, BiomesButtonUI,
	-- ObbyButtonUI). The engine's GUI navigation takes the D-pad before any
	-- ContextActionService binding while something is selected, so only an
	-- InputBegan listener can hear it. Absent (nil) every other moment.
	GuideLit = "GuideLit",
	-- On a player, set by PlantService (2026-10-08, FirstMinute) while the
	-- starter pod the game planted for them is still a pod: its deadline,
	-- os.time(). TutorialUI's training steps say "Your first pod is growing!"
	-- while it is set. nil before it is planted and once it has hatched.
	StarterHatchAt = "StarterHatchAt",
	-- Bumped every time a pod is banked at the red line. A COUNTER rather than a
	-- flag, because two banks in a row have to be two events -- setting a flag
	-- true twice changes nothing and the second one would go unnoticed. The
	-- client watches it to tell "I made it" apart from "I lost it", which from
	-- the client's side otherwise look identical: CarryingSpecies goes nil.
	BankedCount = "BankedCount",
	SeedInstanceId = "SeedInstanceId",
	-- On the PLAYER, written by BiomeGateService's road poll with
	-- MapService.IsInSafeZone (true in the field). Read-only presentation: the
	-- TELEPORT TO PLOT button shows off it, and the server tests the position
	-- itself on every request.
	InSafeZone = "InSafeZone",
	-- On the PLAYER: the id of the plot PlotService leased them, nil while they
	-- have none (queued, or leaving). Presentation only, like the above.
	OwnPlotId = "OwnPlotId",
	-- Set while the owner is standing on their own mill and earning. On the
	-- PLAYER, so it replicates to everybody for free -- which is what lets each
	-- client play the run cycle on somebody else's character without a remote.
	OnTreadmill = "OnTreadmill",
	--==========================================================================
	-- PARKED ON YOUR OWN MILL
	--
	-- Set by TreadmillService when it catches a player crossing their belt, read
	-- by CarryService to hold them at a standstill. On the PLAYER rather than the
	-- character so it survives nothing in particular -- a respawn clears the mount
	-- anyway -- but so that every client can see who is training without a remote.
	--==========================================================================
	MillMounted = "MillMounted",
	-- On the PLAYER, set once by PlayerDataService at load when an old Overclock
	-- became a mill (ProfileSchema.convertOverclock, 2026-10-06): the tier it
	-- became. MillNotice.client says so, once.
	MillOverclockBecame = "MillOverclockBecame",
	--==========================================================================
	-- HOW MANY GUARDIANS ARE RUNNING AT THIS PLAYER RIGHT NOW
	--
	-- On the PLAYER, written by NestService's tick only when it changes: nil
	-- while nobody is, else the number of guardians in the chasing state with
	-- this player as their target. Waking, throwing, hauling and walking home do
	-- not count -- none of those is a pursuit.
	--
	-- One number per player rather than a target on every guardian, so the
	-- client never needs to SEE a guardian to know it is being chased: the one
	-- behind you can be streamed out, and the chase bed must not stop because
	-- of it. Read by AlertUI. Presentation only.
	--==========================================================================
	PursuedBy = "PursuedBy",
	--==========================================================================
	-- HOW MANY GUARDIANS ARE WAKING UP TO COME AFTER THIS PLAYER
	--
	-- The same shape as PursuedBy, for the state before it: nil while nobody
	-- is, else the number of guardians in their wake delay with this player as
	-- their target. Written by NestService on the theft itself and every tick
	-- after, only when it changes. It drops back to nil the tick the delay ends,
	-- which is also the tick PursuedBy counts them -- so AlertUI goes from
	-- "WAKING -- RUN!" to "CHASED!" on the guardian's own state change, never
	-- on the carry. Presentation only.
	--==========================================================================
	WakingBy = "WakingBy",
	--==========================================================================
	-- WHAT A GARDEN HOLDS AND EARNS, ON ITS PLOT, FOR THE GATE SIGN
	--
	-- On the plot Model. Written by EconomyService's pay tick, only when a value
	-- changes, and cleared by PlotService the moment the lease ends. nil means
	-- "not known" -- nobody owns it, or the owner's garden is not back in the
	-- ground yet -- and never stands in for zero.
	--
	--   GardenGrown   grown plants standing in the bed
	--   GardenPods    pods still hatching; with GardenGrown, what Capacity counts
	--   GardenIncome  what the owner is paid per second right now: the RateFor the
	--                 same tick pays, so every active boost is already inside it
	--   GardenBoost   the boost multiplier inside that number; nil at x1
	--
	-- Presentation only. The capacity check and the payout never read them.
	--==========================================================================
	GardenGrown = "GardenGrown",
	GardenPods = "GardenPods",
	GardenIncome = "GardenIncome",
	GardenBoost = "GardenBoost",
	--==========================================================================
	-- HOW FAST THIS PLAYER LOOKS, TO EVERY OTHER CLIENT
	--
	-- 0 for a trail only, 1..3 for the afterimage tiers. An ATTRIBUTE and not a
	-- number in the profile packet, because the client that has to draw your
	-- ghosts is everybody ELSE'S -- and their clients must never be handed your
	-- profile to find out you are fast.
	--
	-- One small integer, replicated by the engine, meaningless on its own.
	--==========================================================================
	SpeedVisualTier = "SpeedVisualTier",
	--==========================================================================
	-- HOW MUCH THE LOAD IS COSTING THEM, 0.30 TO 1
	--
	-- Exactly the multiplier CarryService applies to WalkSpeed, published so the
	-- afterimage can dim and thin itself on somebody ELSE'S screen. Server-owned
	-- and never re-derived on the client: a client that computed this from a
	-- replicated weight is a client that could lie about it, and the entire
	-- purpose is that running home rich cannot be made to look fast.
	--==========================================================================
	CarrySpeedMultiplier = "CarrySpeedMultiplier",
	--==========================================================================
	-- THE DEEPEST BIOME THIS PLAYER HAS EVER EARNED
	--
	-- Published so the client can grey a gate it cannot pass and say what it
	-- wants, without a remote and without being trusted: the SERVER decides who
	-- crosses, and this is only what the HUD reads.
	--==========================================================================
	HighestBiomeOrder = "HighestBiomeOrder",
	--==========================================================================
	-- THE WORLD CLOCK, ON THE WORKSPACE
	--
	-- Three read-only facts every client and every service reads the same way.
	-- On the WORKSPACE rather than on a player, because they are true of the
	-- world and not of anybody in it -- and because that makes a late joiner
	-- correct on their first frame without being sent anything.
	--
	-- A client writing these changes only its own view; nothing on the server
	-- ever reads them back off a client.
	--==========================================================================
	WorldPhase = "WorldPhase",
	WorldPhaseEndsAt = "WorldPhaseEndsAt",
	WorldCycleIndex = "WorldCycleIndex",
	--==========================================================================
	-- HELD BY A TRAP
	--
	-- On the PLAYER, and it is a movement MODIFIER, not a movement WRITE.
	-- CarryService owns WalkSpeed -- it is the only file that assigns it,
	-- because the speed is a product of things no single caller knows -- so a
	-- trap sets this and asks CarryService to recompute, exactly as
	-- TreadmillService does with MillMounted.
	--
	-- That is the whole reason it is an attribute rather than a captured number
	-- somewhere in CombatService. Capturing WalkSpeed and putting it back is how
	-- a trap that fires while a player is stepping onto a mill hands them the
	-- wrong speed forever; recomputing cannot, because it reads the truth.
	--
	-- It replicates, so every client can see who is stuck without a remote.
	--==========================================================================
	Trapped = "Trapped",
	--==========================================================================
	-- WHEN THAT TRAP LETS GO, IN SERVER TIME
	--
	-- One number, written once when the jaws close and cleared once when they
	-- open. Every client subtracts it from `Workspace:GetServerTimeNow()` and
	-- draws its own countdown, so a two-second timer costs two attribute writes
	-- rather than sixty replicated updates a second per trapped player.
	--
	-- Server time, not os.clock: the two ends have to be reading one clock, and
	-- GetServerTimeNow is the same value on both.
	--==========================================================================
	TrappedUntil = "TrappedUntil",
	--==========================================================================
	-- WHICH KIND OF TRAP HAS THEM, SO THE COUNTDOWN CAN SAY SO
	--
	-- "root" or "slow". A rooted player is standing still and the label over them
	-- is red; a slowed one is still walking, still steering and still able to
	-- swing, and a red TRAPPED over their head would be a lie that reads as a bug.
	--
	-- Written beside TrappedUntil and cleared with it, so there is no state where
	-- a countdown exists without a word to put in front of it.
	--==========================================================================
	TrappedKind = "TrappedKind",
	--==========================================================================
	-- HOW MUCH OF THEIR OWN SPEED A TRAP IS LEAVING THEM
	--
	-- A FRACTION, not a speed: 0.35 means "whatever you would be doing, do 35% of
	-- it". CarryService multiplies its computed speed by this, so a slow applies
	-- to a billionaire sprinting at 90 and to a beginner at 20 in the same
	-- proportion, and nothing anywhere captures a WalkSpeed to put back.
	--
	-- Absent means no slow. The root uses `Trapped` instead, which is zero rather
	-- than a fraction, because a root is not a slow of 0% -- it also takes their
	-- jump, and those two facts should not share one number.
	--==========================================================================
	TrapSlow = "TrapSlow",
	--==========================================================================
	-- WALK MODE, AS THE SERVER SEES IT
	--
	-- The player asked to walk. It is stamped here by the server -- from the
	-- profile, on join, and on every toggle -- and the HUD renders THIS rather
	-- than what it last clicked, because a client-set attribute is a client
	-- claiming a movement state and this game does not let it.
	--
	-- Read-only to every client. TreadmillService, the guardians, the bats and the
	-- traps never look at it: it is a CAP applied at the end of CarryService's
	-- calculation, so it cannot change what anybody earns or how hard anything
	-- hits.
	--==========================================================================
	WalkMode = "WalkMode",
	-- The saved GameConfig.MenuSize option id, stamped from the profile the way
	-- WalkMode is. Read by every menu (UIKit.menuScale).
	MenuSize = "MenuSize",
	-- The like reminder's saved state, stamped from the profile the same way:
	-- "pending" (earned with the hatch bonus, not yet shown), "shown", or nil
	-- (GameConfig.HatchBonus). Read by HatchBonusUI.
	LikeReminder = "LikeReminder",
	-- Disco dancing on or off (2026-10-03), stamped from the profile the same
	-- way: true unless the player switched it off. Read by DiscoDance.client.
	DiscoDance = "DiscoDance",
}

--==============================================================================
-- WALK MODE
--
-- A switch under the Settings gear that caps ordinary movement at Roblox's own
-- walking speed. It exists because this game's Speed score reaches the hundreds:
-- a player who wants to line a plant up, read a sign, or walk beside somebody
-- cannot do any of it at 90 studs a second, and the answer to that should not be
-- "spend your Speed".
--
-- min(computed, 16), AND NEVER max. A player slower than 16 -- carrying a
-- Colossal pod, wading through a Mirecoil, new to the game -- is not sped up by
-- asking to walk. That is the whole of the rule, and CarryService applies it as
-- the last line of the one function that owns WalkSpeed.
--
-- IT IS NOT A SETTING IN THE SETTINGS PANEL. It is a movement control, it is
-- toggled mid-stride, and burying it two clicks deep would make it useless for
-- the thing it is for.
--==============================================================================
GameConfig.WalkMode = {
	-- Roblox's default. Not a number this game invented, which is the point: it is
	-- the speed every other experience walks at.
	CapStuds = 16,
	-- The verb the HUD sends on the GameEvent remote it already owns, and the
	-- words it prints.
	Action = "WalkMode",
	Label = "WALK MODE",
	OnText = "ON",
	OffText = "OFF",
}

--==============================================================================
-- OTHER PLANTS: A DISPLAY PREFERENCE, THIS SCREEN ONLY (2026-10-05)
--
-- OTHER PLANTS: ON shows every garden, as it always did; OFF hides OTHER
-- players' GROWN plants in their plots -- the models, their labels, income pops
-- and effects -- on this player's screen and nobody else's (PlantVisibility,
-- OtherPlantsUI). Their own plants, every pod still in the ground, a carried or
-- loose pod, players, guardians, plots and the map stay. Nothing on the server
-- changes: income, ownership, collisions, pickups, spawns and saves are exactly
-- what they were.
--
-- Kept for the session and through every respawn as a LOCAL attribute on the
-- player -- written by the client, never replicated, never saved. Default ON.
--==============================================================================
GameConfig.OtherPlants = {
	Attribute = "ShowOtherPlants",
	Label = "OTHER PLANTS",
	OnText = "ON",
	OffText = "OFF",
}

--==============================================================================
-- MENU SIZE: A READING PREFERENCE, SAVED LIKE WALK MODE (2026-09-26)
--
-- How big the menus are drawn -- panels, their text and their controls -- for a
-- player who finds them small. Chosen, never guessed: a screen's resolution says
-- nothing about how big the glass is or how far away the player sits, so the
-- default is today's size and the player picks a larger one in Settings.
--
-- Saved the way Walk Mode is: a profile field, this verb on the GameEvent remote
-- the HUD already owns, and an attribute the server stamps from the profile. No
-- second remote and no second store.
--
-- MODEST, AND ALWAYS INSIDE THE SCREEN. Each menu takes the smaller of the
-- chosen size and what fits the usable screen (UIKit.menuScale), so LARGER on a
-- short phone is as large as that phone allows and never a panel off its edges.
-- The HUD itself -- the rail, the hotbar, cash and speed -- is never scaled:
-- its owner-approved positions stay exactly where they are.
--==============================================================================
GameConfig.MenuSize = {
	Action = "MenuSize",
	Label = "MENU SIZE",
	Default = "normal",
	Options = {
		{ Id = "normal", Label = "NORMAL", Scale = 1 },
		{ Id = "large", Label = "LARGE", Scale = 1.15 },
		{ Id = "larger", Label = "LARGER", Scale = 1.3 },
	},
	-- ON A PHONE (2026-10-08, the owner: "make the ui smaller on phones"; every
	-- menu panel, 85%): every menu panel is drawn PhoneScale times its size and
	-- takes that share of the screen, so it keeps exactly the room it had -- the
	-- same layout, smaller -- and stops short of the screen's edges, the HUD
	-- showing round it. Times the player's own choice: LARGE on a phone is still
	-- larger. A phone is the prompts' rule (Labels.Prompt): touch, and the
	-- viewport's shorter side under PhoneShortSide. The HUD is never scaled.
	PhoneScale = 0.85,
	PhoneShortSide = 500,
}

--==============================================================================
-- SORT: THE BAG'S AND MY PLANTS' ORDER, SAVED (2026-10-10, the owner: "dont
-- forget to add sort", then a SORT button stepping Rarity, Income and Newest,
-- in the Bag and in MY PLANTS)
--
-- A third saved setting, the MenuSize way: the profile keeps one option id per
-- panel (BagSort, PlantsSort), PlayerDataService stamps the attribute of the
-- same name, and each panel's SORT button sends its own verb on the GameEvent
-- remote. Anything that is not an option is refused, and an old save with no
-- key reads as the Default. In the Bag, favourites stay first whatever the
-- order.
--
--   rarity  rarest first (GameConfig.RarityTier, high to low), bats and traps
--           by their own; what shows no rarity (an ordinary pod, tickets, the
--           trail) after every rarity; within one rarity, as income
--   income  the order the Bag always had -- plants by income, pods by biome
--           and size, equipment in shop order -- and MY PLANTS' earners best
--           first
--   newest  the latest item first (its item id, which only grows); equipment,
--           which keeps no date, the dearest first
--==============================================================================
GameConfig.Sort = {
	Default = "rarity",
	Options = {
		{ Id = "rarity", Label = "RARITY" },
		{ Id = "income", Label = "INCOME" },
		{ Id = "newest", Label = "NEWEST" },
	},
	-- The small word over the option on each SORT button.
	Word = "SORT",
	Bag = { Action = "BagSort", Attribute = "BagSort" },
	Plants = { Action = "PlantsSort", Attribute = "PlantsSort" },
}

--==============================================================================
-- THE FREELY ASSIGNABLE HOTBAR AND THE BAG'S HEARTS (2026-10-03, the owner's
-- compact Bag + free hotbar; HotbarSlots is the grammar)
--
-- The profile keeps both: `Hotbar`, ten shortcuts saved by item id, and
-- `Favourites`, a set of the same ids. Two verbs on the GameEvent remote the HUD
-- already owns, the way MenuSize is saved: SetAction sends the whole bar (ten
-- strings), FavouriteAction a list of refs and on/off. InventoryService checks
-- each against what the player owns, and a token bucket per player -- Burst
-- requests at once, RefillPerSecond after -- is charged before the payload is
-- even read, so a flood of junk costs the sender and nothing else.
--==============================================================================
GameConfig.Inventory = {
	SetAction = "HotbarSet",
	FavouriteAction = "Favourite",
	Slots = 10,
	-- Longest ref accepted: "i:" plus an Item id of at most 24 characters fits.
	MaxRefLength = 32,
	-- Most refs one Favourite request may name; a bigger group is split.
	MaxPerRequest = 32,
	Burst = 12,
	RefillPerSecond = 8,
}

--==============================================================================
-- THE HATCH BONUS AND THE LIKE REMINDER (2026-10-01, the owner's brief)
--
-- ONE free wheel spin per player, once, for a SUCCESSFUL hatch -- the first
-- after this update. It is the hatch's reward and never depends on liking the
-- game.
--
--   * Two names for the one bonus, and nobody gets both. A player who had
--     never hatched gets it on that first hatch: FIRST HATCH BONUS! One whose
--     saved progress says they had -- Tutorial.Done.hatch, read before this
--     hatch is recorded and re-derived on every load from the Almanac, the bag
--     and the garden -- gets it on their next: WELCOME BACK BONUS! Joining
--     grants nothing; a refused or failed hatch grants nothing.
--   * The spin goes on the wheel's EARNED balance (WheelService.
--     GrantHatchBonus) and never touches the obby's daily allowance. The spin,
--     the claimed marker and the reminder's "pending" are written in one step,
--     so every save has all three or none. A progress reset keeps the marker
--     and the reminder's state.
--   * Its notice waits for the roll, the plant's reveal and the guide's
--     congratulations (HatchBonusUI). Once it and any guide message have gone,
--     a small notice the player can dismiss asks "Enjoying Podnappers? Leave
--     us a like!" -- once per player, saved as shown, still pending on the
--     next visit if they left first. Nothing detects a like, nothing is
--     promised for one, and a pending reminder never grants another spin.
--==============================================================================
GameConfig.HatchBonus = {
	FirstTitle = "FIRST HATCH BONUS!",
	WelcomeTitle = "WELCOME BACK BONUS!",
	Detail = "You earned 1 free wheel spin.",
	-- After the plant's reveal and any congratulations, this much more before
	-- the notice: they read as two moments, not one crowd.
	BeatSeconds = 0.6,
	Reminder = {
		Title = "ENJOYING STEAL A SPROUT?",
		Detail = "Leave us a like!",
		-- Up this long unless dismissed sooner (Notice's `dismissible`).
		Seconds = 10,
		-- The client reports it shown once it has been up this long, or when it
		-- is dismissed sooner.
		ShownAfter = 2,
		-- A reminder pending from an earlier visit waits at least this long after
		-- the body arrives, and then for a calm moment: in the Safe Zone, no
		-- panel, no guide message, no notice, no pod in the arms.
		CalmSeconds = 20,
		-- client -> server on GameEvent, carrying nothing: "it was shown".
		Action = "LikeReminderShown",
	},
}

--==============================================================================
-- THE COMMUNITY CHEST AND SPIN TICKETS (2026-10-01, the owner's brief)
--
-- A second chest on the hub deck, a stride from the Bonus Chest. Standing on
-- the glowing circle in front of it asks the server first, once per visit to
-- the circle: the server checks membership itself (CommunityService) and, for
-- a member who has never claimed, gives `Spins` free spins ONCE per saved
-- profile, on the wheel's EARNED balance (WheelService.GrantCommunity), saved
-- in the same step as the permanent claimed flag -- no dialog. Only a
-- non-member is shown Roblox's own community-join prompt
-- (GroupService:PromptJoinAsync, on the client); when it closes the server
-- checks again. A cancelled prompt grants nothing; a join Roblox has not
-- confirmed yet is asked again a few times and then left for the player to
-- retry, as is a check Roblox would not answer.
--
-- SPIN TICKETS are that earned balance shown in the hotbar: one stacked Tool,
-- "Spin Ticket" with its count, built from WheelEarned and never a balance of
-- its own (WheelService, SPIN TICKETS). Each funds one normal spin at the wheel.
--
-- PLACED in the shop row (2026-10-10, Map.Stall's comment): the back row, in
-- the gap between the shrine and the sacrifice pedestal, facing north with the
-- circle in front, clear of every prompt's reach (EventHubSpec). It stood on
-- the deck's west side from 2026-10-01, placed off every spawn pad's walk.
--==============================================================================
GameConfig.Community = {
	-- CrazyCozy Games, the community that owns Podnappers (the owner, 2026-10-01).
	GroupId = 744756221,
	Spins = 5,
	FolderName = "SeedCommunityChest",
	-- Y is the grass the plinth stands on; the circle lies on it too.
	Position = Vector3.new(-240, 0, -127),
	-- The chest's front is its -Z (as the Bonus Chest's): 180 faces it north.
	FacingDegrees = 180,
	-- The circle: this far in front of the chest, this wide, lit.
	PadAhead = 6.5,
	PadRadius = 3,
	PadColour = Color3.fromRGB(120, 255, 170),
	-- How high above the circle a body still counts as standing on it.
	PadReach = 6,
	-- The words over the chest (CommunityChestUI, FloatingSign).
	Title = "FREE",
	Sub = "JOIN COMMUNITY · 5 FREE SPINS",
	ClaimedTitle = "CLAIMED",
	ClaimedSub = "THANKS FOR JOINING!",
	SignAbove = 6.4,
	SignWidth = 9,
	SignHeight = 2.4,
	SignSubHeight = 0.9,
	-- A Roblox community join can take a moment to show: asked this many times,
	-- this far apart, before the player is told to try again.
	VerifyTries = 3,
	VerifyGapSeconds = 2,
	-- One check at a time per player, and not more often than this.
	CheckCooldownSeconds = 3,
	-- client -> server: "check me" (nothing else). server -> client: the outcome.
	CheckAction = "CommunityCheck",
	ResultAction = "CommunityResult",
	-- The player attribute the chest reads for its claimed state.
	ClaimedAttribute = "CommunityClaimed",
	-- The hotbar's Tool for the earned balance.
	TicketName = "Spin Ticket",
	TicketHint = "Use at the Spin Wheel.",
	ClaimedNotice = { Title = "COMMUNITY REWARD CLAIMED!", Detail = "+5 Spin Tickets" },
}

--==============================================================================
-- ANNOUNCEMENTS AND RESTART NOTICES (2026-10-01, the owner's brief)
--
-- What every client may know: the words' limits, the Workspace attributes the
-- server publishes the two notices on (AnnouncementService writes them,
-- AnnouncementUI reads them -- so a player who joins or respawns late reads
-- the same state), and the restart notice's wording. Who may announce, the
-- safeguards, the messaging topic and the filter live on the server
-- (AnnouncementService, AdminService), where no client reads them.
--
-- ONE AFTER ANOTHER (2026-10-03): there is no wait between an admin's
-- announcements any more. Consecutive ones queue on the server and show in
-- the order they were accepted: the one up gives way after MinShowSeconds,
-- the last stays ShowSeconds. The queue is published as Attributes.Queue.
--
-- Everything a notice carries is TEXT: drawn in a TextLabel with RichText off,
-- never run, required or parsed for anything.
--==============================================================================
GameConfig.Announce = {
	MaxChars = 180,
	-- How long an admin announcement stays up -- the last one queued.
	ShowSeconds = 12,
	-- How long one stays up, at least, before the next in the queue replaces it.
	MinShowSeconds = 5,
	Attributes = {
		-- The queue (2026-10-03): JSON, a list of { i = id, t = words, f = sender,
		-- s = start, e = end } in server time, in the order shown. What the
		-- banner draws.
		Queue = "AnnounceQueue",
		-- The newest announcement, one attribute each (kept for older readers).
		Id = "AnnounceId",
		Text = "AnnounceText",
		-- The sending admin's DisplayName, read off their Player by the server.
		From = "AnnounceFrom",
		-- Server time (Workspace:GetServerTimeNow) the announcement comes down.
		Until = "AnnounceUntil",
		RestartTitle = "RestartTitle",
		-- Server time the restart is scheduled for.
		RestartAt = "RestartAt",
	},
	-- Shown only if a broadcast somehow arrives without its sender's name.
	Title = "ANNOUNCEMENT",
	-- A DisplayName longer than this is not one (Roblox's are 20 at most).
	MaxNameChars = 32,
	-- The one short sound a new broadcast plays: the owner's own chime
	-- (Sfx.Cues.AdminBroadcast), on the UI bus, so the player's SOUND FX
	-- setting decides its level and mute.
	Chime = "AdminBroadcast",
	-- A restart's custom message is shown after this; without one, the default.
	RestartLead = "SERVER UPDATE — ",
	RestartDefault = "Server restarting for an update.",
	RestartMaxChars = 80,
}

--==============================================================================
-- THE OWNER'S "ADMIN" TITLE (2026-10-01, the owner's ask)
--
-- Over ONE account's head, seen by everyone: the owner's, by UserId, decided on
-- the server (AdminService.IsOwner, OwnerTitleService) -- never by a name. This
-- block is only how it looks. OwnerTitleService builds it on the Head of each
-- new character; OwnerTitleUI turns its rainbow on each viewer's screen
-- (still, for a viewer with reduced motion). Cosmetic: nothing reads it.
--
-- Sized in pixels like a name tag, so it reads the same near and far, and gone
-- past MaxDistance. It stands Rise studs over the head's middle and Lift of its
-- own heights higher still: just over Roblox's own name tag and the speed pops.
-- TrapUI's countdown (3.4 studs up) would land on it, so a viewer's copy steps
-- aside while that player's TrappedUntil runs (OwnerTitleUI). The first try
-- stood it over the countdown's slot instead -- 3.4 and 1.4 -- and that was
-- nearly 200 px over the head of a player a camera's length away.
--==============================================================================
GameConfig.OwnerTitle = {
	Name = "SeedOwnerTitle",
	Tag = "SeedOwnerTitle",
	Text = "ADMIN",
	Rise = 2.4,
	Lift = 0.9,
	Size = Vector2.new(140, 34),
	TextSize = 30,
	-- The glow's edge under the letters, and the letters' dark outline.
	GlowThickness = 7,
	EdgeThickness = 3,
	-- ON A PHONE (2026-10-09, the owner: "shrink admin on phones too ...
	-- shrink it that it matches the name size of a player"): the same phone as
	-- the rebirth title's (GameConfig.titlePhone) draws ADMIN with its letters
	-- at PhoneTextSize, its box and outlines with them (ownerTitleLook). 15
	-- MATCHES A PLAYER'S NAME, measured on the owner's phone screenshot of the
	-- engine's default name tag (2000 x 900): its capitals 28 px tall where the
	-- top bar's 44-point logo button is 108 px, so 11.4 points; ADMIN at 15
	-- draws 12 points tall with its outline. The engine's name label cannot be
	-- measured in Studio (no instance; the capture leaves it out).
	PhoneTextSize = 15,
	MaxDistance = 100,
	-- One turn of the rainbow's hues, as the broadcast name and FREE drift.
	DriftSeconds = 7,
}

-- Whether a broadcast showing now sounds its chime: once per id on this client
-- (`heard` remembers), and never for one already up when the client started --
-- a late joiner reads it in silence. Anything that is not an id never sounds.
-- A phone, for the titles over heads (2026-10-09, the prompts' rule): a touch
-- screen whose shorter side is under Rebirth.Title.PhoneShortSide.
function GameConfig.titlePhone(viewport: Vector2?, touch: boolean): boolean
	local R = GameConfig.Rebirth.Title
	return touch and viewport ~= nil and viewport.X > 0 and viewport.Y > 0
		and math.min(viewport.X, viewport.Y) < R.PhoneShortSide
end

-- What a screen draws the rebirth title at: Rebirth.Title.PhoneScale on a
-- phone, 1 anywhere else.
function GameConfig.rebirthTitleScale(viewport: Vector2?, touch: boolean): number
	if GameConfig.titlePhone(viewport, touch) then
		return GameConfig.Rebirth.Title.PhoneScale
	end
	return 1
end

-- What a screen draws ADMIN at: its letters at OwnerTitle.PhoneTextSize on a
-- phone, 1 anywhere else.
function GameConfig.ownerTitleScale(viewport: Vector2?, touch: boolean): number
	local T = GameConfig.OwnerTitle
	if GameConfig.titlePhone(viewport, touch) then
		return T.PhoneTextSize / T.TextSize
	end
	return 1
end

-- ADMIN at a scale: its box in whole pixels, its letters' size, and its glow's
-- and outline's thickness (never under 1). OwnerTitleService builds it at 1;
-- OwnerTitleUI redraws it for a phone, on that phone only.
function GameConfig.ownerTitleLook(scale: number): { box: Vector2, text: number, glow: number, edge: number }
	local T = GameConfig.OwnerTitle
	return {
		box = Vector2.new(math.round(T.Size.X * scale), math.round(T.Size.Y * scale)),
		text = T.TextSize * scale,
		glow = math.max(T.GlowThickness * scale, 1),
		edge = math.max(T.EdgeThickness * scale, 1),
	}
end

-- The rebirth title at a scale: its box in whole pixels, its words' size and
-- REBIRTH N's, never under SubMinTextSize. The server builds it at 1;
-- OwnerTitleUI redraws it for a phone, on that phone only.
function GameConfig.rebirthTitleLook(scale: number): (Vector2, number, number)
	local R = GameConfig.Rebirth.Title
	local box = Vector2.new(math.round(R.Size.X * scale), math.round(R.Size.Y * scale))
	return box, R.TextSize * scale, math.max(R.SubTextSize * scale, R.SubMinTextSize)
end

-- How far over its own height ADMIN is raised (its SizeOffset): its own Lift,
-- or -- over a rebirth title (GameConfig.Rebirth.Title, 2026-10-08) -- clear of
-- that title's top by two pixels, so a player with both shows both, ADMIN on top.
-- `titleScale` is the title's on this screen (rebirthTitleScale) and
-- `adminScale` ADMIN's (ownerTitleScale); 1 if left out.
function GameConfig.ownerTitleLift(stacked: boolean, titleScale: number?, adminScale: number?): number
	local T = GameConfig.OwnerTitle
	if not stacked then
		return T.Lift
	end
	local R = GameConfig.Rebirth.Title
	local box = GameConfig.rebirthTitleLook(titleScale or 1)
	local admin = GameConfig.ownerTitleLook(adminScale or 1).box
	return ((R.Lift + 0.5) * box.Y + 2) / admin.Y + 0.5
end

function GameConfig.announceChime(heard: { [string]: boolean }, id: any, starting: boolean): boolean
	if type(id) ~= "string" or id == "" or heard[id] then
		return false
	end
	heard[id] = true
	return not starting
end

-- "Restarting in 05:00", and "Restarting shortly…" from zero on: the notice
-- never says the restart has happened, because only Roblox does that.
function GameConfig.restartCountdown(secondsLeft: number): string
	if secondsLeft ~= secondsLeft or secondsLeft <= 0 then
		return "Restarting shortly…"
	end
	local s = math.ceil(secondsLeft)
	return string.format("Restarting in %02d:%02d", s // 60, s % 60)
end

-- What a phone draws every menu at (MenuSize.PhoneScale), 1 on anything else:
-- touch, and the viewport's shorter side under MenuSize.PhoneShortSide.
function GameConfig.menuPhoneScale(viewport: Vector2?, touch: boolean): number
	local M = GameConfig.MenuSize
	if touch and viewport and viewport.X > 0 and viewport.Y > 0
		and math.min(viewport.X, viewport.Y) < M.PhoneShortSide then
		return M.PhoneScale
	end
	return 1
end

-- The scale an option id stands for, or nil for anything that is not one.
function GameConfig.menuSizeScale(id: any): number?
	for _, option in ipairs(GameConfig.MenuSize.Options) do
		if option.Id == id then
			return option.Scale
		end
	end
	return nil
end

-- The option after `id`, round again after the last; unknown ids start over.
function GameConfig.nextMenuSize(id: any): string
	local options = GameConfig.MenuSize.Options
	for i, option in ipairs(options) do
		if option.Id == id then
			return options[i % #options + 1].Id
		end
	end
	return options[1].Id
end

-- A GameConfig.Sort option id as given, or nil for anything else (2026-10-10).
function GameConfig.sortOption(id: any): string?
	for _, option in ipairs(GameConfig.Sort.Options) do
		if option.Id == id then
			return option.Id
		end
	end
	return nil
end

-- The sort after `id`, round again after the last; unknown ids start over.
function GameConfig.nextSort(id: any): string
	local options = GameConfig.Sort.Options
	for i, option in ipairs(options) do
		if option.Id == id then
			return options[i % #options + 1].Id
		end
	end
	return options[1].Id
end

-- What a SORT button says for `id` ("RARITY"); the Default's for anything else.
function GameConfig.sortLabel(id: any): string
	local want = GameConfig.sortOption(id) or GameConfig.Sort.Default
	for _, option in ipairs(GameConfig.Sort.Options) do
		if option.Id == want then
			return option.Label
		end
	end
	return GameConfig.Sort.Options[1].Label
end

GameConfig.Tags = {
	Plot = "Plot",
	PlotSpawn = "PlotSpawn",
	Planter = "Planter",
	Treadmill = "Treadmill",
	PlantSlot = "PlantSlot",
	SafeZone = "SafeZone",
	Lane = "Lane",
	WildPatch = "WildPatch",
	SeedPod = "SeedPod",
	BiomeGate = "BiomeGate",
	-- A pod in somebody's hands. Tagged separately from SeedPod because a pod on
	-- the road is scenery you may take and a pod being carried is a target.
	CarriedPod = "CarriedPod",
	-- Planted and growing, or grown. Built and tagged by the server, SWAYED by
	-- each client -- same split as the fairy, and the reason a creature costs
	-- roughly what a plant costs.
	Creature = "Creature",
	-- Built and tagged by the server, MOVED by each client. See HubFairy.
	Fairy = "Fairy",
	-- The nest guardian. Unlike everything else that moves for decoration, this
	-- one is server-simulated: it chases, and a chase every player sees in a
	-- different place is not a chase.
	NestParent = "NestParent",
	-- GROWING IN SOMEBODY'S PLOT. The opposite of SeedPod, and the reason both
	-- exist: a pod in a nest is loot, and the identical model standing in a plot
	-- is somebody's property mid-hatch. Nothing tagged Planted is ever takeable,
	-- and CarryService refuses it even if a stale prompt survives on it.
	Planted = "Planted",
	-- One arrow painted on a treadmill belt. Server builds them where they
	-- belong; each client scrolls its own copies, same split as the fairy.
	MillChevron = "MillChevron",
	--==========================================================================
	-- THE REST OF THE MILL'S MOVING PARTS
	--
	-- Same split as the chevrons and the fairy: the SERVER builds them, each
	-- CLIENT moves them. A roller turning is paint, and paint replicated sixty
	-- times a second from six plots is the single most expensive thing this game
	-- could decide to do.
	--==========================================================================
	--==========================================================================
	-- THE TREADS
	--
	-- The thing that actually makes a treadmill read as one. Arrows painted on a
	-- surface say "this is meant to move"; slats sliding under your feet say it
	-- is moving. Scrolled by the same client clock the chevrons use.
	--==========================================================================
	MillSlat = "MillSlat",
	MillRoller = "MillRoller",
	-- Turns the other way from whatever it is geared to, at its own ratio.
	MillGear = "MillGear",
	-- An arm driven off the belt: goes round, so the mill has something with a
	-- stroke to it rather than only things that spin.
	MillCrank = "MillCrank",
	-- Cloth. Sways on its own slow cycle whether or not anybody is training,
	-- because a flag in a garden does.
	MillBanner = "MillBanner",
	-- Neon that breathes. Slow and shallow when idle, quick and bright under
	-- load -- which is most of how a premium mill says somebody is on it.
	MillPulse = "MillPulse",
	MillWheel = "MillWheel",
	MillLeaf = "MillLeaf",
	MillSign = "MillSign",
	--==========================================================================
	-- THE PLOT'S OWN UPGRADE BOARD
	--
	-- The same idea as MillSign and deliberately the same builder: a board by the
	-- gate that says what the next level costs and carries the prompt that buys
	-- it. The plot ladder used to live in the shop panel, which put the two
	-- upgrades in a menu and at a sign respectively for no reason a player could
	-- see.
	--==========================================================================
	PlotSign = "PlotSign",
	-- The TOP CREATURES board beside it (2026-10-05): built by MapService,
	-- published by PlotShowcaseService, drawn by PlotShowcaseUI.
	PlotShowcase = "PlotShowcase",
	MillJaw = "MillJaw",
	MillHolo = "MillHolo",
	MillWing = "MillWing",
	-- An empty marker MapService leaves behind saying "a nest belongs here".
	-- NestService builds the actual nest on top of it, because a nest has state
	-- and the map deliberately has none.
	NestSite = "NestSite",
	-- The shutter across the mouth of the road. Tagged rather than found by
	-- name because MapService rebuilds the whole map and the cycle service must
	-- find whichever barrier exists now, not the one that existed at boot.
	NightBarrier = "NightBarrier",
	-- The fog masses inside the biome lanes. Tagged for the same reason the
	-- barrier is: MapService rebuilds the map, and WorldClock must fade whichever
	-- fog exists now rather than a set it collected at boot.
	BiomeFog = "BiomeFog",
	-- A Bramblejaw lying on the road. Tagged so a client can find one to
	-- animate and so a placement check can find the others without a spatial
	-- query on parts that are deliberately CanQuery = false.
	Trap = "Trap",
	-- A one-shot SoundKit.emit played by the SERVER. A server-made Sound cannot
	-- name a client-local SoundGroup, so it is tagged instead and each client
	-- routes it through its own bus, where the settings panel's levels are.
	ServerCue = "SeedServerCue",
}

GameConfig.Remotes = {
	PlotAssigned = "PlotAssigned",
	ProfileUpdated = "ProfileUpdated",
	-- Sent once when a profile is ready, or when it could not be loaded. A
	-- client that never hears this must not pretend the player has 0 cash --
	-- that is indistinguishable from a real new account.
	ProfileReady = "ProfileReady",
	CarryStateChanged = "CarryStateChanged",
	-- The parent's hit. Server -> victim: a direction and a speed. Victim ->
	-- server: "I have stopped."
	--
	-- It has to be a message rather than the server just applying the impulse,
	-- because a player's character is simulated by THAT PLAYER. A velocity
	-- written on the server is overwritten by the owner's next update, which is
	-- exactly what made the first ragdoll invisible.
	ThrowVictim = "ThrowVictim",
	DropSeedRequest = "DropSeedRequest",
	-- Server -> client. Fired when the player enters a non-starter biome so the
	-- HUD can show that biome's advisory Speed target.
	BiomeRecommendation = "BiomeRecommendation",
	GameEvent = "GameEvent",
}

--==============================================================================
-- RARITY
--
-- Canonical order, index = tier. Everything that sorts, colours or compares
-- rarity reads this, so there is one place where "is Epic above Rare" is
-- answered.
--==============================================================================
GameConfig.Rarities = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine",
}

local rarityTier: { [string]: number } = {}
for index, name in ipairs(GameConfig.Rarities) do
	rarityTier[name] = index
end
GameConfig.RarityTier = rarityTier

-- Sampled off the pod artwork rather than picked, so the pods in the world are
-- the pods that were designed. The first five are the ones the reference sheet
-- actually shows; the last three follow its logic outward.
GameConfig.RarityColor = {
	Common    = Color3.fromRGB(238, 235, 226),
	Uncommon  = Color3.fromRGB(142, 196, 62),
	Rare      = Color3.fromRGB(108, 168, 214),
	Epic      = Color3.fromRGB(146, 62, 158),
	Legendary = Color3.fromRGB(250, 198, 48),
	Mythic    = Color3.fromRGB(232, 92, 132),
	Secret    = Color3.fromRGB(120, 240, 236),
	Divine    = Color3.fromRGB(255, 246, 194),
}

--==============================================================================
-- THE THREE RAREST, IN MOTION (2026-10-03, the owner's inventory pass)
--
-- How Mythic, Divine and Secret read in the Bag and on the strip, wherever
-- their rarity is already shown: the rarity WORD carries a slow light, and the
-- card's thin edge takes the rarity's colour with a small light travelling
-- round it. Not new rarities and not new world colours -- RarityColor above
-- still colours pods, the Index and the Garden; this is the inventory's own
-- reading of three of its words, keyed by the same ids.
--
--   Text / Glow     the word at rest, and the light that crosses it
--   StillTop/Bottom the word under reduced motion: a still two-tone, top down
--   Outline         the word's keyline (Secret's is LIGHT: its sheen runs dark)
--   Edge            the card's edge at rest
--   Glint / Tail    the light going round the edge, and what trails it
--
-- One cycle every CycleSeconds, on every card at once, never faster: slow
-- motion, no flashing. Drawn by RarityFX; stepped by the strip's cooldown tick
-- in LoadoutUI, at most every StepSeconds.
--==============================================================================
GameConfig.RarityFX = {
	CycleSeconds = 3.6,
	StepSeconds = 1 / 30,
	-- How thick the travelling light is, and how much of the card it lights.
	GlintThickness = 1.5,
	GlintSpan = 0.22,
	-- THE CARD'S SHINE (2026-10-10, the owner: "add shine effect"): a band of
	-- light crossing a Mythic, Divine or Secret STUDDED card once a cycle, over
	-- its studs and under its picture and words; Sweep seconds to cross, then
	-- rest. Wave: a card further right starts later, up to this many seconds,
	-- so a row of them shines left to right. Width: half the band, as a share of
	-- the card; Rotation its slant. Each rarity's colours below (`Shine`, three
	-- across the band) and how strong at its middle (`ShinePeak`, a
	-- transparency) -- a white shine would vanish on the pearl card, so
	-- Mythic's is a pastel prism and Divine's gold. Reduced motion: no shine.
	Shine = { Sweep = 0.8, Wave = 0.6, Width = 0.13, Rotation = 22 },
	Mythic = {
		Text = Color3.fromRGB(238, 54, 70), -- crimson, lit enough for dark slate
		Glow = Color3.fromRGB(255, 150, 132),
		StillTop = Color3.fromRGB(250, 86, 96),
		StillBottom = Color3.fromRGB(208, 34, 54),
		Outline = Color3.fromRGB(40, 6, 12),
		Edge = Color3.fromRGB(204, 34, 54),
		Glint = Color3.fromRGB(255, 150, 104), -- an ember
		Tail = Color3.fromRGB(255, 70, 64),
		-- on the pearl card: a pastel prism, rose to cream to ice
		Shine = { Color3.fromRGB(255, 160, 196), Color3.fromRGB(255, 236, 176), Color3.fromRGB(160, 226, 255) },
		ShinePeak = 0.3,
	},
	Divine = {
		Text = Color3.fromRGB(255, 247, 224), -- ivory
		Glow = Color3.fromRGB(255, 200, 70), -- gold
		StillTop = Color3.fromRGB(255, 249, 232),
		StillBottom = Color3.fromRGB(240, 196, 92),
		Outline = Color3.fromRGB(92, 62, 8),
		Edge = Color3.fromRGB(230, 182, 70), -- gold
		Glint = Color3.fromRGB(255, 252, 236), -- an ivory glint
		Tail = Color3.fromRGB(255, 224, 140),
		-- on the pearl card: gold, its middle near white
		Shine = { Color3.fromRGB(255, 196, 84), Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 196, 84) },
		ShinePeak = 0.25,
	},
	-- The SECRET POD SPAWNED toast's italic heavy word and its palette, turned
	-- for the dark Bag: BLACK letters inside a crisp light-silver keyline, a
	-- silver band leading a white sheen across them. (Silver letters in a light
	-- keyline blurred into one grey shape at tile size -- measured 2026-10-03.)
	-- `Halo`: the keyline is drawn by a twin label BEHIND the word, because a
	-- label's UIGradient tints its own UIStroke too (measured: a light keyline
	-- under a black gradient came out black).
	Secret = {
		Text = Color3.fromRGB(22, 22, 28), -- black
		Glow = Color3.fromRGB(255, 255, 255),
		Dark = Color3.fromRGB(196, 198, 212), -- the silver band before the light
		StillTop = Color3.fromRGB(236, 236, 244),
		StillBottom = Color3.fromRGB(40, 40, 50),
		Outline = Color3.fromRGB(214, 216, 228),
		OutlineTransparency = 0,
		Halo = true,
		Italic = true,
		Edge = Color3.fromRGB(196, 198, 212), -- silver
		Glint = Color3.fromRGB(255, 255, 255),
		Tail = Color3.fromRGB(26, 26, 34),
		-- on the dark holo card: ice, white, lilac
		Shine = { Color3.fromRGB(150, 236, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(222, 178, 255) },
		ShinePeak = 0.45,
	},
}

--==============================================================================
-- THE OTHER FIVE, STILL (2026-10-10, the owner: "yes, add rarity edges")
--
-- Every grown plant's card wears its FORM rarity's colour as an edge, Common
-- grey up to Legendary gold -- not only the three rarest, which keep RarityFX
-- above (their own colour and its travelling light). Still: no light, no
-- motion. Vivid versions of RarityColor, so the edge reads on the Bag's
-- studded tiles of the same hue, the strip's dark plate and the Almanac's
-- light cards alike.
--
--   Ring    a Bag tile's and an Almanac card's band just inside its edge,
--           whose own keyline stays; px (1.7 drawn in a phone's 85% menus)
--   Strip   a hotbar slot's edge, px (the HUD is never drawn smaller)
--
-- A pod never wears one -- what is inside is the hatch's to show -- nor a
-- plant still in its roll, nor an Almanac card not yet grown.
--==============================================================================
GameConfig.RarityEdge = {
	Ring = 2,
	Strip = 1.5,
	Colours = {
		Common = Color3.fromRGB(176, 182, 188),
		Uncommon = Color3.fromRGB(168, 236, 92),
		Rare = Color3.fromRGB(122, 196, 255),
		Epic = Color3.fromRGB(204, 124, 255),
		Legendary = Color3.fromRGB(255, 212, 60),
	},
}

--==============================================================================
-- SPEED
--
-- SPEED IS A SCORE. WalkSpeed IS A CURVE. This is an engine constraint, not a
-- balance preference: Roblox character physics degrades badly past roughly 200
-- studs/second -- characters tunnel through thin geometry, network ownership
-- thrashes as the humanoid outruns its own replication, and the camera cannot
-- keep up.
--
-- The reference game's live leaderboard showed a player at 3.2 BILLION Speed.
-- That number can never reach WalkSpeed. So it does not: the score feeds a
-- curve, the player watches an unbounded number climb, and the simulation never
-- sees past MaxWalkSpeed.
--
--==============================================================================
-- MILESTONES, NOT AN ASYMPTOTE
--
-- It was `Base + (Max - Base) * (1 - e^(-Speed / Scale))` with Scale = 20,000.
-- That is a fine shape and completely the wrong RANGE for this game. Measured
-- against the ladder it was supposed to serve:
--
--     Speed        150,000   ->  WalkSpeed 149.99
--     Speed    167,000,000   ->  WalkSpeed 150.00   <- Dustbowl target
--     Speed 10,000,000,000   ->  WalkSpeed 150.00   <- Starbloom target
--
-- The curve finished before the FIRST biome recommendation. Every biome, every
-- mill tier above the third, and the entire billions ladder the game is built
-- around all landed on the same 150 -- so the one stat the whole game grinds
-- stopped changing anything a player could feel, four orders of magnitude
-- before the content did.
--
-- ANCHORS FIX THAT BY BEING A DESIGN STATEMENT RATHER THAN A SHAPE. Each pair
-- below is "at this score, you move this fast", and the biome recommendations
-- are ON the list -- 167M is 42, 800M is 54, 3B is 68, 10B is 82. Reaching a
-- recommendation is worth a visible step because its number also moves the
-- legs faster.
--
-- INTERPOLATED IN LOG SPACE, because the score is logarithmic and linear
-- interpolation between 1M and 167M would leave 99% of that span in the last
-- few walk-speed points. log(x + 1) rather than log(x), so the zero anchor
-- needs no special case.
--
-- MONOTONIC BY CONSTRUCTION: both columns strictly increase and log
-- interpolation between two increasing points cannot dip. More speed is never
-- slower, which is the one property that must survive any retune.
--
-- To retune, move a row. Do not add a formula.
--==============================================================================
GameConfig.Speed = {
	BaseWalkSpeed = 16,
	MaxWalkSpeed = 150,

	--==========================================================================
	-- { Speed score, WalkSpeed }
	--
	-- Must stay sorted and strictly increasing in BOTH columns. The last row is
	-- the cap and must equal MaxWalkSpeed; the first must equal BaseWalkSpeed.
	-- Verified on load below, because a typo here is a game that silently walks
	-- backwards at one particular score.
	--==========================================================================
	Anchors = {
		{ 0, 16 },
		{ 1e3, 22 },
		{ 1e4, 27 },
		{ 1e6, 32 },
		-- The long climb from 1M to Dustbowl is the emptiest stretch on the
		-- ladder, so it gets a waypoint of its own: 100M is a round number a
		-- player passes on the way and a visible +8 for having done it.
		{ 100e6, 40 },
		--== the biome recommendations ==--
		{ 167e6, 42 },
		{ 800e6, 54 },
		{ 3e9, 68 },
		{ 10e9, 82 },
		--== past the last recommendation, where the idle game actually lives ==--
		{ 100e9, 96 },
		{ 1e12, 110 },
		{ 10e12, 124 },
		{ 100e12, 138 },
		{ 1e15, 150 },
	},
}

--==============================================================================
-- THE DAY, AND THE NIGHT THAT RESTOCKS IT
--
-- Greenhollow holds ONE nest of five pods. Under the old rule a taken slot grew
-- a new pod 22 seconds later, which meant the nest was never really empty and
-- clearing it meant nothing -- you could stand beside it and farm the same ring
-- forever. The scarcity the whole road is built around existed on the map and
-- not in the game.
--
-- So the supply is a BATCH, not a trickle. Every live nest is stocked once at
-- dawn, a taken slot stays empty for the rest of the day, and an emptied nest
-- stays emptied. What is left at dusk is destroyed rather than carried over, so
-- a hoarded nest is not a way to start tomorrow ahead.
--
--     420s day     five pods for up to six players, then nothing until dawn
--      15s night   the road is shut and the world is reset
--      45s warning enough to decide whether to go in or turn round
--
-- SEVEN MINUTES IS THE NUMBER TO TUNE. It is the whole supply curve: the batch
-- per seven-and-a-quarter-minute cycle across the whole server. Shorten the day
-- and the road gets busier; lengthen it and the nest sits empty longer.
--
-- THE NIGHT WAS 60 SECONDS UNTIL 2026-09-23, when the owner cut it to 15: a
-- minute of shut road was a minute of waiting. Everything a night does still
-- happens at its two edges and none of it waits on the night's length -- the
-- dusk teardown runs before the night's wait begins, and the dawn batch is
-- built and counted before Day is published (WorldCycleService) -- so a
-- shorter night is a shorter wait and nothing else. The lighting and music
-- crossfades are 3 s, a fifth of it; CycleSpec holds them under a quarter.
--
--==============================================================================
-- THE PHASE IS AN ATTRIBUTE ON THE WORKSPACE, NOT A REMOTE
--
-- Three read-only facts, replicated by the engine, that every client and every
-- service reads the same way:
--
--     WorldPhase        "Day" or "Night"
--     WorldPhaseEndsAt  workspace:GetServerTimeNow() of the next change
--     WorldCycleIndex   bumped at every dawn
--
-- A countdown is a SUBTRACTION, not a broadcast. The client works out the number
-- on its own clock from the deadline, so a seven-minute day costs three
-- attribute writes rather than 420 remote calls per player, and a player who
-- joins at 03:12 is correct on their first frame with nothing sent to them.
--
-- Nothing reads this off a client. The client is told; it never asks and it is
-- never believed.
--==============================================================================
GameConfig.WorldCycle = {
	DaySeconds = 420,
	NightSeconds = 15,
	-- How long before dusk the HUD starts saying so -- and the one window its
	-- countdown is red in (WorldClock, 2026-10-04): by day only, never at night.
	WarnSeconds = 45,

	PhaseDay = "Day",
	PhaseNight = "Night",

	-- THE HUD CLOCK'S CYCLE ICONS (2026-10-04): the moon and cloud beside the
	-- countdown to night, the sun and cloud beside the countdown to dawn. The
	-- approved art is art/icons/hud-cycle-2026-10-04 (cycle-moon-cloud-v1.png,
	-- cycle-sun-cloud-v1.png), uploaded by the owner the same day. Until a
	-- picture has actually loaded here -- or for good, if it never does --
	-- WorldClock keeps UIKit.cycleIcon's native pair under it.
	ClockIcons = { Moon = "rbxassetid://123862305697349", Sun = "rbxassetid://138878981553342" },

	--==========================================================================
	-- THE ROAD IS SHUT BY A WALL, NOT BY THE DARK
	--
	-- Darkness and fog are a LOOK, and a look is not a rule: a player can turn
	-- their graphics down, and anybody who does would be able to see straight
	-- down a corridor that is supposed to be closed. The barrier is a real part
	-- across the mouth -- opaque and collidable at night, invisible and
	-- non-collidable by day -- so concealment does not depend on how somebody
	-- has their settings.
	--
	-- It is also why the nests are EMPTIED at dusk rather than merely hidden.
	-- Nothing waits behind it to be revealed.
	--==========================================================================
	Barrier = {
		Name = "Nightfall",
		-- Thin, but thick enough that a fast player cannot end a frame inside it.
		Thickness = 4,
		-- Above the corridor walls, so there is no gap to see over from the
		-- field or to hop across.
		HeightPad = 14,
		-- Wider than the corridor by a wall thickness on each side, so there is
		-- no seam at the wall line.
		WidthPad = 24,
		Colour = Color3.fromRGB(18, 22, 46),
		--======================================================================
		-- FULLY OPAQUE, AND 0.08 WAS NOT
		--
		-- It was 0.08 on the theory that a hint of the road beyond reads as
		-- "shut" rather than as the world ending. Measured in a playtest, and it
		-- leaked: the biome arch's name plate is a SurfaceGui with
		-- LightInfluence = 0, so it is drawn at FULL brightness regardless of
		-- the night lighting, and eight percent of full brightness against a
		-- black corridor is perfectly legible. "Greenhollow" was floating in the
		-- middle of a wall that is supposed to be opaque.
		--
		-- Anything unlit behind this would do the same, which is the general
		-- form of the bug: a barrier that is nearly opaque conceals things in
		-- proportion to how dark they happen to be, and unlit UI is never dark.
		-- Concealment cannot be a matter of degree.
		--======================================================================
		NightTransparency = 0,

		--======================================================================
		-- AND IT IS A SCREEN, NOT A SLAB
		--
		-- It was a flat dark-blue wall, and a flat dark-blue wall at 164 by 60
		-- studs is not read as "the road is shut for a moment", it is read as
		-- the world having run out. Nothing on it said what had happened or how
		-- long it would last, so the only way to know either was the one-line
		-- HUD clock at the top of the screen -- which a player walking INTO the
		-- thing is not looking at.
		--
		-- So the face that meets the field is a night sky with the countdown on
		-- it, big enough to read at the far end of the field.
		--
		-- IT IS DRAWN ON THE OPAQUE PART, WHICH IS WHY THIS IS SAFE. The banner
		-- above is emphatic that concealment cannot be a matter of degree, and
		-- none of this changes that: the part stays Transparency = 0 at night,
		-- the SurfaceGui paints its near face, and nothing behind it becomes any
		-- more visible than it was.
		--
		-- BACK, NOT FRONT. NormalId.Front is -Z and the corridor runs toward -Z
		-- -- measured, Starbloom's end wall is at Z = -1675 while the plots are
		-- at -57.8 -- so the face the field can see is +Z. Getting this backwards
		-- costs nothing at build time and shows a blank wall to every player.
		--======================================================================
		Screen = {
			Face = "Back",
			-- 8 gives a 1312 x 480 canvas on a 164 x 60 stud wall, which is
			-- enough for the timer to have clean edges without paying for a
			-- texture nobody can see the detail of from thirty studs.
			PixelsPerStud = 8,

			--== the sky ==--
			-- Darkest at the zenith, lifting toward a horizon glow, which is
			-- the way round a real sky goes and the way round that makes the
			-- bottom of a 60-stud wall look like distance rather than paint.
			SkyTop = Color3.fromRGB(6, 8, 22),
			SkyHorizon = Color3.fromRGB(24, 30, 68),
			-- Stars only in the upper part: a star below the horizon line is a
			-- speck of dirt.
			StarCount = 74,
			StarBand = 0.66,
			StarColour = Color3.fromRGB(226, 234, 255),
			-- A fixed seed, so every client and every rebuild gets the SAME sky.
			-- It replicates from the server either way; this is so a screenshot
			-- taken today can be compared with one taken next month.
			StarSeed = 20260909,

			--== the moon ==--
			MoonColour = Color3.fromRGB(238, 240, 226),
			MoonGlow = Color3.fromRGB(120, 140, 210),

			--== the words ==--
			Caption = "THE ROAD IS CLOSED",
			Footer = "PODS RETURN AT DAWN",
			InkCaption = Color3.fromRGB(150, 170, 225),
			InkTimer = Color3.fromRGB(236, 242, 255),
			-- The last ten seconds. Same idea as the HUD's warning colour, and
			-- deliberately the same INFORMATION as the HUD rather than extra:
			-- a player should never have to compare two clocks.
			InkSoon = Color3.fromRGB(255, 206, 120),
			SoonSeconds = 10,
		},
	},

	--==========================================================================
	-- FOG INSIDE THE BIOMES, AND IT IS A LOOK RATHER THAN A RULE
	--
	-- At night the corridor is shut and emptied, and from the field the barrier
	-- covers it completely -- but from INSIDE, looking down the road, every gate,
	-- sign and tree is still perfectly legible. Measured at night from
	-- Greenhollow: the Dustbowl arch, its Speed plate and the decor beyond it all
	-- read clearly at three hundred studs. The world is closed and it does not
	-- look closed.
	--
	-- SO THIS IS ATMOSPHERE, AND THE BARRIER IS STILL THE RULE. The banner above
	-- `NightTransparency` is emphatic that concealment cannot depend on a look,
	-- because a player can turn their graphics down. Nothing here changes that
	-- and nothing here is load-bearing: the wall is opaque and collidable, the
	-- gate check puts anybody past the road mouth back in the field ten times a
	-- second, and the nests are emptied. A client that drew none of this would be
	-- no more able to enter or to see anything worth seeing.
	--
	-- WHY IT IS PARTS AND NOT `FogEnd`. The one thing this map may never do is
	-- haze the road -- being able to stand at the safe line and see five biomes
	-- receding IS the progression display, and `applyLighting` shuts off both
	-- FogEnd and Atmosphere to protect it. Global fog cannot be aimed: it would
	-- grey the FIELD too, where people plant and harvest all through the night.
	-- Banks of geometry sit only where they are put.
	--
	-- AND THE DEPTH DOES THE WORK. One bank is a haze; the far end of the road is
	-- behind twenty of them, so it disappears while the ground at your feet does
	-- not. That is the shape real fog has, and it falls out of stacking rather
	-- than being tuned.
	--==========================================================================
	Fog = {
		Name = "NightFog",
		-- Four banks down each 300-stud lane, four masses in each bank. 80 parts
		-- across the whole road, none of which collides, casts a shadow or can be
		-- queried -- and all of which are behind an opaque wall from the only
		-- place a player can legally stand at night, so they cost nothing to
		-- draw from there.
		BanksPerLane = 4,
		BlobsPerBank = 4,
		--======================================================================
		-- BLOCKS, NOT BALLS
		--
		-- A Roblox Ball renders at the diameter of its SMALLEST axis, so a
		-- 90 x 40 x 30 "cloud" comes out a 30-stud marble. Blocks also happen to
		-- be right for this game: it is blocky studded plastic everywhere else,
		-- and a blocky fog bank looks deliberate rather than like a sphere that
		-- did not work.
		--======================================================================
		Colour = Color3.fromRGB(150, 168, 205),
		-- Per mass. The number that matters is not this one but this one stacked:
		-- two deep it is a haze, eight deep it is a wall.
		-- 0.72 left the first gate down the road still readable. 0.68 is a small
		-- move per mass and a large one stacked -- eight deep it is 0.036 of the
		-- light through against 0.072 -- which is the whole reason the depth does
		-- the work rather than the number.
		NightTransparency = 0.68,
		-- Fixed, so every client and every rebuild gets the same fog, and so a
		-- screenshot stays comparable.
		Seed = 20260910,
	},

	--==========================================================================
	-- NIGHT IS BLUE, NOT BLACK
	--
	-- The plots stay usable: people plant, harvest and stand on their mills
	-- through the night, and a night that made their own garden unreadable would
	-- be a night they wait out staring at a wall. Every one of these is a target
	-- for the CLIENT to tween towards -- the server never touches Lighting, so
	-- the transition costs nothing and cannot desync anybody.
	--
	-- Dawn restores MapService's exact daytime values, which are captured once
	-- rather than typed here, so the two can never drift apart.
	--==========================================================================
	Night = {
		ClockTime = 0,
		Brightness = 1.1,
		Ambient = Color3.fromRGB(58, 66, 96),
		OutdoorAmbient = Color3.fromRGB(66, 78, 116),
		EnvironmentDiffuseScale = 0.7,
		ExposureCompensation = 0.25,
		FadeSeconds = 3.0,
	},
}

--==============================================================================
-- BIOME ENTRANCES ARE ADVISORY; NIGHT STILL CLOSES THE ROAD
--
-- MapService builds an arch at every biome boundary. The Speed number on it is
-- a recommendation for the chase ahead, not a lock: every player may enter
-- every biome during the day. The same geometric check remains valuable at
-- night, when the entire road closes for the restock cycle.
--
--==============================================================================
-- A PLANE, NOT A PART
--
-- The visible night barrier can be clipped at high WalkSpeed, so the server
-- also checks which side of the road entrance a player occupies.
--
-- The road mouth is one plane. During the day it is open; at night a player on
-- the biome side is put back in the field. That rule cannot be missed at any
-- speed or frame rate because it checks where the player is, not a touch event.
--
--==============================================================================
-- NIGHT EJECTION
--
-- At night the smallest correction that works is a short push across the road
-- mouth. CarryService separately forfeits the active pod, preserving the cost
-- of failing to return before the shutdown.
--==============================================================================
GameConfig.Gate = {
	-- How far into the field a player caught on the road at night is placed.
	PushBackStuds = 8,
	-- Server poll for entry recommendations and the nighttime closure.
	PollSeconds = 0.1,
	-- Throttles repeated night-ejection diagnostics.
	NoticeCooldown = 3,
}

--==============================================================================
-- THE AFTERIMAGE
--
-- Seven tiers, from a single faint echo at a thousand Speed to a flowing rainbow
-- at the save cap. It is the only thing in the game that says how far up the
-- ladder somebody is without a number, and it is the reward for the one stat
-- this game is entirely about.
--
--==============================================================================
-- THE SCORE QUALIFIES. THE MOVEMENT EMITS. THEY ARE NOT THE SAME QUESTION.
--
-- A player standing still, ragdolled, mid-throw, dead, or crawling home under a
-- 9,000 kg pod must produce NOTHING at any tier. An afterimage is a statement
-- about motion; one that appears while you are pinned to the floor reads as a
-- bug and cheapens it everywhere else.
--
--==============================================================================
-- HIGHER TIERS BUY COLOUR, NEVER INSTANCES
--
-- The ghost count stops at four and stays there from tier 4 up. Everything above
-- it is spent on the SAME four ghosts looking better: a gradient down the body,
-- a wave travelling through it, a hue wheel turning, a pulse, an expansion. That
-- is the whole performance strategy -- an eighth ghost costs fifteen more parts
-- per player per frame forever, and a hue that moves costs one Color3 write at
-- twelve hertz.
--
-- Which is also why a phone can have every tier. It gets fewer ghosts, not a
-- worse rainbow.
--
--==============================================================================
-- EMITTED BY DISTANCE, NOT BY FRAMES
--
-- A frame counter spaces ghosts by frame rate, so the same run leaves twice as
-- many on a 120 Hz machine as on a 60 Hz one. Studs travelled is the same
-- picture everywhere, and it is what makes the spacing numbers below mean
-- something a person can see.
--==============================================================================
GameConfig.Afterimage = {
	--==========================================================================
	-- A RIBBON, NOT A CROWD OF COPIES
	--
	-- This used to emit cloned character limbs -- up to four echoes at a time,
	-- fifteen parts each, respawned every few studs for as long as you ran. It
	-- read well and it capped hard: a fifth ghost cost fifteen more parts, so
	-- the count stopped at four and every tier above the fourth was spent on
	-- making the SAME four echoes look better. That is why the top half of the
	-- ladder had nothing structural left to give.
	--
	-- One Trail per character has no such cap. Length, width, brightness and
	-- animation are all free to keep climbing, so every step up the ladder is
	-- visibly more than the one below it in the SHAPE of the thing and not only
	-- in its colour.
	--
	-- THE RIBBON NO LONGER STEPS BACK. There was a TrailTransparencyFloor here
	-- that held the streak deliberately faint so the echoes had room to read
	-- inside it. With the echoes gone the ribbon carries the whole reading, so
	-- it gets STRONGER with tier -- the exact inverse of what it used to do.
	--==========================================================================
	QualityAttribute = "SeedAfterimageQuality",

	--== movement gates ==--
	-- Standing still at a high WalkSpeed must not smear a ribbon across a plot,
	-- and a respawn must not draw one across the map.
	MinGroundSpeed = 2,
	TeleportStuds = 24,
	-- Past this, somebody else's ribbon is not worth driving. Checked before the
	-- work rather than by MaxDistance, because the point is to skip COMPUTING
	-- it, not merely to skip drawing it.
	RemoteMaxStuds = 120,

	-- How often the animated tiers are repainted. A wave that moved at the frame
	-- rate would run at a different speed on every machine.
	ColourInterval = 1 / 30,

	--==========================================================================
	-- WHAT A LOAD DOES TO IT
	--
	-- Read off the SERVER'S carry multiplier, never re-derived from a size --
	-- a client that worked it out for itself is a client that could decide not
	-- to. Above CarryFullAbove nothing changes; below CarryReducedAbove the
	-- ribbon goes out entirely, which is what guarantees a Colossal haul is
	-- silent at every tier, the void at the top included.
	--==========================================================================
	CarryFullAbove = 0.92,
	CarryReducedAbove = 0.55,
	CarryLifetimeScale = 0.45,
	CarryWidthScale = 0.60,
	CarryFadeAdd = 0.18,

	-- Phones get a shorter, narrower ribbon rather than a different effect. The
	-- whole point of moving off ghosts is that every machine can have every
	-- tier.
	ReducedLifetimeScale = 0.55,
	ReducedWidthScale = 0.85,

	--==========================================================================
	-- THE TEN
	--
	--   From              the Speed score that unlocks it
	--   Lifetime          how long the ribbon persists behind you, in seconds
	--   WidthStuds        the separation of the two attachments, which IS the
	--                     ribbon's width -- a Trail draws between a pair
	--   HeadTransparency  how solid it is where it leaves the body
	--   LightEmission     how much it ignores world lighting
	--   Palette           the colours it cycles through
	--   Wave              palette travel per second (0 is static)
	--   Shimmer           fast, shallow brightness flicker
	--   Particle          the emitter that rides with it: Texture, Color, Rate,
	--                     Speed, Size, and an optional LightEmission
	--   CoreColor         optional. The inner blade is white at full emission
	--                     unless a tier names its own colour
	--
	-- THE SHAPE OF IT CLIMBS AT EVERY STEP: Lifetime, WidthStuds and
	-- HeadTransparency are strictly monotonic from 1 to 10, so no tier is ever
	-- shorter, narrower or fainter than the one below it. That is the guarantee
	-- the ghost ladder could not make once its count capped at four.
	--
	-- THE ANIMATION DIALS DELIBERATELY DO NOT. Wave and Shimmer are set by
	-- THEME, not by rank -- Thunder Strike flickers harder than the Violet
	-- Phantom above it because that is what those two things are. Do not
	-- "correct" them into a ramp; the monotonic guarantee lives in the three
	-- columns above and nowhere else.
	--
	-- AND TIER 10 BREAKS LightEmission ON PURPOSE. Every tier climbs toward
	-- light; Void Singularity is the one that takes it away, which only reads
	-- as an ending because the nine below it went the other way.
	--
	-- THAT IS ALSO WHY THERE IS NO LONGER A Rainbow COLUMN. The old top tier
	-- ended the ladder by abandoning its palette for the whole hue wheel. The
	-- void ends it by going the other way instead, so nothing set the flag, and
	-- a branch no row can reach is a branch nobody tests. It went with it. If a
	-- future tier wants the hue wheel back, it is in the history -- do not leave
	-- a dead column here waiting for it.
	--==========================================================================
	Tiers = {
		{
			From = 1e3,
			Name = "Breeze Whisper",
			Lifetime = 0.25,
			WidthStuds = 1.20,
			HeadTransparency = 0.55,
			LightEmission = 0.40,
			Palette = {
				Color3.fromRGB(190, 250, 210),
				Color3.fromRGB(130, 230, 160),
			},
			Wave = 0.15,
			Shimmer = 0,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(150, 240, 170),
				Rate = 16,
				Speed = 2.4,
				Size = 0.65,
			},
		},
		{
			From = 10e3,
			Name = "Aqua Surge",
			Lifetime = 0.35,
			WidthStuds = 1.50,
			HeadTransparency = 0.48,
			LightEmission = 0.50,
			Palette = {
				Color3.fromRGB(130, 245, 255),
				Color3.fromRGB(60, 170, 255),
			},
			Wave = 0.20,
			Shimmer = 0.05,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(110, 225, 255),
				Rate = 20,
				Speed = 3.0,
				Size = 0.80,
			},
		},
		{
			From = 1e6,
			Name = "Thunder Strike",
			Lifetime = 0.45,
			WidthStuds = 1.80,
			HeadTransparency = 0.42,
			LightEmission = 0.68,
			Palette = {
				Color3.fromRGB(255, 245, 110),
				Color3.fromRGB(90, 230, 255),
			},
			Wave = 0.38,
			Shimmer = 0.16,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 235, 90),
				Rate = 24,
				Speed = 3.8,
				Size = 0.95,
			},
		},
		{
			From = 100e6,
			Name = "Violet Phantom",
			Lifetime = 0.55,
			WidthStuds = 2.10,
			HeadTransparency = 0.36,
			LightEmission = 0.78,
			Palette = {
				Color3.fromRGB(245, 170, 255),
				Color3.fromRGB(150, 70, 250),
			},
			Wave = 0.25,
			Shimmer = 0.08,
			Particle = {
				Texture = "rbxasset://textures/particles/smoke_main.dds",
				Color = Color3.fromRGB(210, 110, 255),
				Rate = 22,
				Speed = 3.2,
				Size = 1.15,
			},
		},
		{
			From = 1e9,
			Name = "Solar Flare",
			Lifetime = 0.65,
			WidthStuds = 2.45,
			HeadTransparency = 0.30,
			LightEmission = 0.86,
			Palette = {
				Color3.fromRGB(255, 255, 220),
				Color3.fromRGB(255, 180, 40),
				Color3.fromRGB(255, 100, 15),
			},
			Wave = 0.32,
			Shimmer = 0.12,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 210, 60),
				Rate = 28,
				Speed = 4.2,
				Size = 1.25,
			},
		},
		{
			From = 10e9,
			Name = "Glacial Frostbite",
			Lifetime = 0.75,
			WidthStuds = 2.80,
			HeadTransparency = 0.26,
			LightEmission = 0.92,
			Palette = {
				Color3.fromRGB(230, 255, 255),
				Color3.fromRGB(110, 230, 255),
				Color3.fromRGB(70, 160, 255),
			},
			Wave = 0.38,
			Shimmer = 0.10,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(190, 250, 255),
				Rate = 32,
				Speed = 4.6,
				Size = 1.40,
			},
		},
		{
			From = 100e9,
			Name = "Heartwood Bloom",
			Lifetime = 0.85,
			WidthStuds = 3.15,
			HeadTransparency = 0.22,
			LightEmission = 0.94,
			Palette = {
				Color3.fromRGB(110, 255, 170),
				Color3.fromRGB(255, 130, 230),
				Color3.fromRGB(255, 240, 110),
			},
			Wave = 0.45,
			Shimmer = 0.08,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 170, 240),
				Rate = 35,
				Speed = 4.8,
				Size = 1.50,
			},
		},
		{
			From = 1e12,
			Name = "Hellfire Inferno",
			Lifetime = 0.95,
			WidthStuds = 3.50,
			HeadTransparency = 0.18,
			LightEmission = 0.97,
			Palette = {
				Color3.fromRGB(255, 240, 90),
				Color3.fromRGB(255, 90, 20),
				Color3.fromRGB(180, 20, 8),
				Color3.fromRGB(40, 24, 28),
			},
			Wave = 0.55,
			Shimmer = 0.15,
			Particle = {
				Texture = "rbxasset://textures/particles/fire_main.dds",
				Color = Color3.fromRGB(255, 120, 25),
				Rate = 40,
				Speed = 5.4,
				Size = 1.75,
			},
		},
		{
			From = 10e12,
			Name = "Seraphic Divinity",
			Lifetime = 1.05,
			WidthStuds = 3.85,
			HeadTransparency = 0.15,
			LightEmission = 0.99,
			Palette = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(255, 240, 150),
				Color3.fromRGB(210, 245, 255),
				Color3.fromRGB(255, 220, 100),
			},
			Wave = 0.62,
			Shimmer = 0.10,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 250, 190),
				Rate = 45,
				Speed = 5.6,
				Size = 1.90,
			},
		},
		{
			From = 100e12,
			Name = "Void Singularity",
			Lifetime = 1.25,
			WidthStuds = 4.40,
			HeadTransparency = 0.05,
			LightEmission = 0.00,
			Palette = {
				Color3.fromRGB(0, 0, 0),
				Color3.fromRGB(18, 12, 26),
				Color3.fromRGB(42, 16, 58),
				Color3.fromRGB(0, 0, 0),
			},
			CoreColor = Color3.fromRGB(10, 6, 16),
			Wave = 0.65,
			Shimmer = 0.25,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(15, 10, 24),
				Rate = 60,
				Speed = 7.0,
				Size = 2.50,
				LightEmission = 0.00,
			},
		},
	},
}

--==============================================================================
-- WEIGHT IS THE WHOLE RISK/REWARD, AND IT IS ONE NUMBER
--
-- A creature's KILOGRAMS decide both what it earns and what it costs to get
-- home with. Rarity decides only how OFTEN you find one. That split is the
-- entire design of a theft game expressed as a single stat:
--
--   the fat pod is the one worth taking, and the one that gets you caught.
--
-- ONE KILOGRAM IS ONE CASH PER SECOND. No conversion, no table, no tooltip
-- maths -- a player reads an object's worth straight off its weight, and can
-- compare any two things in the game at a glance without opening anything.
-- Scale comes later from multipliers and Rebirth, never from bending this.
--
-- The slow curve is deliberately flat at the bottom and brutal at the top:
--
--       2 kg  ->  99.6% speed   (a starter pod is free to carry)
--     110 kg  ->  95.4%         (noticeable, not punishing)
--   1,000 kg  ->  82.4%
--  10,000 kg  ->  30.0%         (a crawl, and a very long walk home)
--
-- Flat at the bottom matters: a new player must never feel taxed for picking up
-- the only thing they can find. Brutal at the top is what makes an endgame
-- carry a decision rather than a formality.
--==============================================================================
--==============================================================================
-- THE PARENT
--
-- Every wild patch is a NEST: pods spawn in a ring around a big hostile parent
-- creature that guards them. It ignores you until a pod is taken, then chases
-- whoever took it, and on catching them it GRABS and THROWS.
--
-- Throwing rather than damaging is the right punishment for this game. Damage
-- would mean health bars, respawns and a death loop; a throw costs you the one
-- thing the whole design is already about -- the length of the walk home -- and
-- it is funny to watch, which matters more than it sounds for a game people
-- clip.
--
-- THROW DISTANCE SCALES WITH THE BIOME, so the parent guarding a 1,500-stud
-- Starbloom nest hurls you far further than the one in the starter field. That
-- keeps the punishment proportional to the prize without needing a second
-- mechanic: the deep biomes are not more dangerous because the parent hits
-- harder, they are more dangerous because being thrown there costs more walking.
--
-- Numbers are a first pass and cannot be anything else until a parent exists to
-- be run away from.
--==============================================================================
GameConfig.Parent = {
	--==========================================================================
	-- IT SLEEPS, AND THE DELAY IS THE GAME
	--
	-- The parent is asleep beside its pods until one is taken. It then wakes on
	-- a SHORT DELAY -- not instantly -- and that delay is the entire skill of a
	-- raid. It is your head start, it is what makes grabbing the near pod
	-- different from grabbing the far one, and it is why a player creeps in and
	-- then sprints out rather than just running in a straight line.
	--
	-- Instant aggro would delete all of that and make the mechanic a tax.
	--==========================================================================
	WakeDelaySeconds = 1.2,

	--==========================================================================
	-- ITS SPEED IS THE GATE, AND THE TREADMILL IS THE ANSWER
	--
	-- This is what the treadmill was always for. The player trains on it to earn
	-- Speed per second; Speed feeds the WalkSpeed curve; WalkSpeed is measured
	-- against THIS number. So "can I loot Emberroot yet" is not a menu check, it
	-- is a footrace you either win or feel yourself losing.
	--
	-- Biome 1 sits just above a fresh player's 16 -- you WILL be caught on your
	-- first raid, and that is the lesson. Each biome further out is faster.
	--==========================================================================
	-- FAST. At 19 against a fresh player's 16 the parent was technically faster
	-- and felt like a slow-moving hazard you could stroll away from. A guard
	-- that never quite catches you is scenery.
	-- How much faster than the biome's own recommendation the guardian runs
	-- against a player who MEETS that recommendation. See parentWalkSpeedFor:
	-- 10 is what Greenhollow already had, so the shipped value falls out of the
	-- formula instead of being special-cased.
	SpeedMargin = 10,

	--==========================================================================
	-- AND HOW MUCH FASTER AGAIN AGAINST SOMEBODY WHO TURNED UP UNDERGEARED
	--
	-- Added on a sliding scale: in full at Speed 0, and not at all once you meet
	-- the recommendation. It exists because THE SPEED CURVE IS LOGARITHMIC and
	-- SpeedMargin alone could not express "you should not be here yet".
	--
	-- Measured at Dustbowl, whose bar is 167M:
	--
	--     score     your walk    old parent   closing    time to catch
	--         0        16.0          52.0       36.0          2.5s
	--        10M       36.5          52.0       15.5          4.9s
	--        80.5M     40.6          52.0       11.4          6.2s
	--       167M       42.0          52.0       10.0          7.1s
	--
	-- Half the recommended score buys you three per cent of a walk speed. A
	-- player at 80.5M -- less than half the bar -- ran only 1.4 slower than one
	-- who had earned their way in, so the guardian treated them identically and
	-- the recommendation meant nothing. The gate was removed from the road on
	-- purpose; this is what replaced it, and it was not carrying the weight.
	--
	-- Sliding rather than a threshold, because a cliff at 166,999,999 would be a
	-- check wearing a footrace's clothes -- and the first claim this file makes
	-- is that the matter is settled by running.
	--
	-- 30 is set so a player at half the bar is caught in about three seconds
	-- instead of six, and one who walked in with nothing is caught almost at
	-- once. It is deliberately NOT enough to touch anybody at or above the
	-- recommendation: that race is unchanged, and overshooting the bar still
	-- buys a clean escape.
	--==========================================================================
	UnderSpeedMargin = 30,

	--==========================================================================
	-- IT GETS ANGRIER
	--
	-- Every theft from the same nest before it gets back to sleep adds speed.
	-- Being caught and coming back for the same pod is the obvious way to farm a
	-- nest safely -- lose it, wait, collect -- so the second attempt has to be
	-- harder than the first, and the fourth harder again.
	--
	-- It resets on sleep, so a nest left alone forgives. The escalation punishes
	-- pestering, not the player.
	--==========================================================================
	RageSpeedPerTake = 5,
	MaxRageStacks = 4,
	-- Rage FADES, it does not vanish the moment the parent lies down. Resetting
	-- on sleep sounded right and made the mechanic almost unreachable: a caught
	-- player is thrown clear, the parent walks home and sleeps in a couple of
	-- seconds, and the pod is still on the ground -- so by the time anyone picks
	-- it back up the anger is already gone. Measured: two thefts in a row, both
	-- at 31, when the second should have been 36.
	--
	-- Held for this long after it settles, so coming back for a dropped pod is
	-- the case that stacks. Leave the nest alone and it forgives.
	RageForgetSeconds = 45,

	-- How far a biome-1 parent throws you, in studs.
	BaseThrowStuds = 60,
	-- Added per biome further down the road. Starbloom throws 240.
	ThrowPerBiome = 45,
	-- Upward component, as a fraction of the horizontal throw. Enough to arc.
	ThrowLift = 0.45,
	-- It only wakes when a pod leaves its nest.
	AggroOnTheftOnly = true,
	--==========================================================================
	-- THE BACKSTOP, NOT THE RULE
	--
	-- This was 220, and it was doing the job the safe-zone check should have
	-- been doing. Every nest sits 240 studs from its own biome's near edge, so
	-- a 220 radius meant a parent gave up TWENTY STUDS SHORT of the boundary --
	-- in every biome, identically, because the nests are placed to a pattern.
	-- Step across the line and the chase ended, which made a road that is
	-- deliberately one continuous corridor behave like five separate rooms.
	--
	-- "So a parent can never be kited into the safe field" is now enforced
	-- where it belongs: NestService tests the PARENT's own position against the
	-- safe zone every tick. That is the actual rule, and a radius only ever
	-- approximated it.
	--
	-- What is left here is a backstop -- sized for the full 5-biome corridor
	-- (1500+ studs) -- so a normal cross-biome chase from Emberroot or Starbloom
	-- can reach the red line / safe zone, while a broken chase off-map cannot
	-- run forever.
	--==========================================================================
	LeashStuds = 2000,
	-- Close enough to grab.
	GrabStuds = 7,

	--==========================================================================
	-- HOW FAR PAST YOU THE PARENT AIMS WHILE IT IS CHASING
	--
	-- Not decoration, and not pathfinding. A Humanoid told to MoveTo a point
	-- DECELERATES as it arrives, and a chase asks it to arrive at a point that
	-- keeps moving away -- so it spends the whole run braking for a destination
	-- it never reaches. Measured against a target running 40.6:
	--
	--     chase speed   closest it EVER gets
	--         45.0            13.99
	--         52.0            13.64
	--         67.5            12.50
	--         82.0            13.60
	--
	-- Thirteen studs, at every speed, against a GrabStuds of 7. A player running
	-- in a straight line was UNCATCHABLE, and no amount of parent speed could
	-- have fixed it -- the standoff does not shrink when the chaser gets faster,
	-- which is why two rounds of making the parent quicker changed nothing. Stop
	-- running and the point stops receding, the arrival completes, and it hits
	-- you: exactly the "it only catches me when I stand still" that found this.
	--
	-- Aiming past the target means the goal is never within braking distance, so
	-- the Humanoid runs flat out until it makes contact. 60 is comfortably clear
	-- of the ~14 stud braking envelope with room for a faster biome.
	--
	-- CHASING ONLY. The walk home still uses a plain MoveTo, because arriving
	-- and stopping is precisely what it wants.
	--==========================================================================
	ChaseOvershootStuds = 60,
	--==========================================================================
	-- AND CLOSE IN, IT AIMS WHERE YOU WILL BE (2026-10-01)
	--
	-- The overshoot runs along the line to the target's position at the last
	-- tick. Within this many studs that line is bent toward where the target
	-- will be one tick later (NestService, GuardianPursuit.heading), so a player
	-- strafing round a guardian at arm's length is not chased round in circles
	-- by orders that are always a tick behind. The lead is one tick of the
	-- target's own measured motion and never longer than the gap; at range, and
	-- for anybody running straight away, the line is the same one it always was.
	--==========================================================================
	ChaseLeadStuds = 30,
	-- Seconds it holds you before the throw. Long enough to read what happened.

	--==========================================================================
	-- ONE GUARDIAN CAN BE MORE THAN THE FORMULA
	--
	-- Everything above derives every parent from its biome's recommendation, and
	-- that is right for four of the five: the road's difficulty curve and its
	-- guardians should not be two numbers that can drift apart.
	--
	-- Astralmaw is the end of the road, and measurement says the formula alone
	-- does not get it there. `parentWalkSpeedFor` gives it 92 against a player
	-- who has trained to the Starbloom recommendation and runs 82 -- ten studs a
	-- second of margin, which is the same margin Greenhollow's brute has over a
	-- beginner. The last biome reading exactly like the first one is the thing
	-- being fixed here.
	--
	-- A PROFILE IS AN OVERRIDE, NOT A SECOND SYSTEM. Rage still stacks on top,
	-- the under-speed shortfall still applies on top, the safe zone still ends
	-- the chase, and a species with no entry here is untouched -- which is what
	-- keeps Greenhollow, Brambleback, Miremaw and Forgemaw exactly as they were.
	--==========================================================================
	Guardians = {
		astralmaw = {
			--==================================================================
			-- IT OPENS FAST AND THEN KEEPS GETTING WORSE
			--
			-- A flat top speed is a single fact a player learns once. A ramp is
			-- a chase that changes while it is happening: the first two seconds
			-- are survivable and every second after that is less so, which is
			-- what makes running the whole way home a decision rather than a
			-- formality.
			--
			-- Squared rather than linear, so the frightening part is the end of
			-- the ramp and not the beginning.
			--
			-- THE CEILING IS 96 AND NOT 118, AND THAT IS THE ROAD'S OWN CURVE.
			-- Simulated at 50 Hz -- 1.2 second head start, contact at GrabStuds,
			-- the red line as the finish, and the +5 rage that EVERY theft
			-- carries because provoke does `rage += 1` -- for a player who has
			-- exactly met each biome's bar and grabbed the lightest pod there is,
			-- the fraction of the run home they cover before being caught goes:
			--
			--     greenhollow 11%   dustbowl 28%   tanglemire 29%   emberroot 34%
			--
			-- Eleven is the tutorial teaching you that you get caught. The rest
			-- is a deliberate, gentle rise: the road gets a little more forgiving
			-- per raid as the run home gets longer, which is what stops distance
			-- from double-counting as difficulty. On the flat 92 it derived,
			-- Starbloom sat at 38% and continued that line exactly.
			--
			-- A ceiling of 118 put it at 28% -- LEVEL WITH DUSTBOWL, making the
			-- last biome the least survivable attempt on the road as well as the
			-- longest walk back. 96 with a 3.4-second ramp puts it at 43%, back
			-- on the line, and it is still the fastest guardian in the game and
			-- still opens by accelerating into you, which is the part that was
			-- actually wrong before any of this.
			--
			-- (These read low against an earlier draft of this comment, which
			-- was simulated WITHOUT the rage every theft carries. The ordering
			-- and the conclusion are the same in both runs; the figures here are
			-- the ones in the commit and in KB/HANDOFF.md.)
			--==================================================================
			OpeningSpeed = 78,
			TopSpeed = 96,
			RampSeconds = 3.4,
			-- Walking home is not a chase. Slower, and the animator reads the
			-- same state to take the aggression out of the gait.
			ReturnSpeed = 64,

			--==================================================================
			-- NO ANTICIPATION. CONTACT IS THE HIT.
			--
			-- This was 0.32 seconds of coil before the launch, and played it
			-- read as LAG: the monster reaches you, nothing happens, and a third
			-- of a second later you go. Anticipation is a real technique and it
			-- is the wrong one here -- the whole chase has already been the
			-- anticipation, and a pause at the end of it is a pause, not a
			-- flourish.
			--
			-- It is also what made charging the monster a dodge: at 150 walk
			-- speed a player covered 48 studs during the coil, past the range
			-- re-check, and the swing missed. Zero puts the impulse on the frame
			-- contact happens, so running at it is running at it.
			--
			-- The arm still swings. ParentAnim starts Astralmaw's strike at the
			-- impact and follows through, which is what every other guardian
			-- already does -- see astralStrike, which reads this number and
			-- drops its coil phase when it is zero.
			--==================================================================
			WindupSeconds = 0,

			--==================================================================
			-- THE THROW, AND THE WALL IT HAS TO CLEAR
			--
			-- Horizontal is in the same band the formula produced (228.7); this
			-- is a deliberate hair over it.
			--
			-- LIFT IS NOT. The Starbloom corridor is walled at x = +/-75 and
			-- those walls are FORTY-SIX STUDS TALL. A ballistic launch clears
			-- them only if v^2/2g beats 43, which needs 130 studs/second of
			-- vertical: the 0.45 lift every other biome uses gives 103 and an
			-- apex of 27, half the wall. 0.60 gives 141 and an apex of 53.7,
			-- which is over the top with seven studs to spare -- and past the
			-- wall there is no floor, so the victim goes to the void.
			--
			-- That is the whole reason this number is not shared: it is not a
			-- taste for a bigger number, it is the height of a specific wall.
			--==================================================================
			--
			-- 300 rather than 235 because "very far" was the ask after seeing
			-- it, and 235 was landing people in the middle of the biome they
			-- were trying to leave. Ballistic range at this lift is 504 studs
			-- before the tumble, against 338 at the old number.
			ThrowSpeed = 300,
			-- 0.55 puts the apex at 69 studs, still well over the 46-stud
			-- corridor wall, and gives 1.7 seconds of air -- which is the
			-- control-loss window as well, since the body is limp until it
			-- settles.
			ThrowLift = 0.55,

			--==================================================================
			-- IT THROWS YOU HOME, AND THAT IS THE POINT
			--
			-- Away used to dominate at 1.00 against 0.30 of road, and played it
			-- was backwards: the guardian aims SIXTY STUDS PAST you while it
			-- chases -- see ChaseOvershootStuds, which exists so it does not
			-- brake -- so by the time it makes contact it is very often level
			-- with you or in front. "Away from the monster" is then "further
			-- down the corridor", and the hit fired people deeper into the
			-- biome they were running out of.
			--
			-- The road wins now. At 1.00 against 0.45, `away` can never take the
			-- sum past ninety degrees off the road, so every hit sends the
			-- victim up the corridor toward the plots however the two bodies
			-- happen to be standing -- while `away` still decides which side of
			-- the road they go, so the launch and the visible strike agree.
			--
			-- The road direction itself is derived from this nest's own position
			-- toward the hub pad rather than a hardcoded world axis, so it is
			-- still right for a nest placed anywhere.
			--==================================================================
			AwayWeight = 0.45,
			RoadWeight = 1.00,
		},
	},

	--======================================================================
	-- THE THREE THAT TAKE IT BACK
	--
	-- Past Dustbowl, being caught does not scatter the pod on the road for
	-- you to run back to -- the guardian CONFISCATES it and carries it home.
	-- The pod stops being recoverable by the player who took it, which is
	-- the whole point: the deep biomes are where a failed raid costs you the
	-- raid rather than costing you the walk.
	--
	-- KEYED BY BIOME, and absent for Greenhollow and Dustbowl. Absence is
	-- the switch, exactly as it is for Guardians above: those two nests
	-- never look this up, never confiscate, and drop the pod on the floor as
	-- they always have. That is the tutorial contract -- you can always go
	-- back for what you lost in the first two biomes.
	--
	-- SEPARATE FROM `Guardians` ON PURPOSE. That table is the speed and
	-- throw profile and only Astralmaw has one; adding Miremaw and Forgemaw
	-- there to get a carry point would have handed them a chase ramp, a
	-- return speed and a new throw as a side effect. Two different questions
	-- deserve two different tables.
	--
	-- SEAM is a PART NAME on that guardian, verified against the live rigs
	-- rather than read off a builder -- the rigs are composed from several
	-- files and no one file lists them all:
	--
	--     miremaw   RightHand  1.83 cubed, at root-space  4.67 -4.39 -2.11
	--     forgemaw  FistR      2.28 x 1.75 x 2.62,        3.70 -7.46 -3.83
	--     astralmaw LowerJaw   4.89 x 1.31 x 3.56,        0.00  2.81 -2.16
	--
	-- The two brutes carry it in a fist; the maw carries it in its mouth,
	-- which is what it is for. That is ALL the seam decides: which limb the
	-- pod is welded to, and therefore how it moves. WHERE it sits is derived
	-- from the rig at attach time rather than written here.
	--
	-- IT HAS TO BE DERIVED, because a pod is 1.66 studs across at Tiny and
	-- 9.04 at the top of the curve, on guardians 15 to 19 studs tall. Three
	-- hand-tuned offsets were tried first and measured against the live rigs:
	-- at Tiny they were fine, and at 9.04 the same numbers buried Astralmaw's
	-- pod 2.62 studs inside its own ChestNebula and hung Forgemaw's 8.55
	-- studs BELOW its feet. There is no constant that is right at both ends.
	--
	-- SIDE is the only offset left, in pod radii, and it is cosmetic: which
	-- side of the centre line a fist-carried pod rides on. See
	-- NestService.attachHaul for the two derivations that matter -- pushed out
	-- of the body, and clamped above the ground.
	--======================================================================
	--======================================================================
	-- AND WHICH WAY IT THROWS YOU
	--
	-- The legacy weighting is away 0.70 against road 0.50, and away WINS.
	-- That is fine while the guardian is behind you, which is most of a
	-- chase -- and wrong the moment it is not, because `ChaseOvershootStuds`
	-- aims sixty studs PAST you so it regularly ends up level with you or in
	-- front. Then away-from-the-guardian is deeper into the biome, the sum
	-- comes out at -0.20 of the road, and you are fired backwards.
	--
	-- Measured on Forgemaw during the playtest: dir (0.25, 0, -0.97), landing
	-- at z -1623 and y -410 -- past Starbloom, in the void, dead. Reported as
	-- *"theres a rare chance when i ragdoll on opposite direction"*. Rare
	-- because it needs that geometry; not rare enough, because it kills you.
	--
	-- 0.45 against 1.00 is what Astralmaw was given when the same complaint
	-- was made about Starbloom, and the road wins from every angle at those
	-- numbers. `away` still decides which SIDE of the road you go, so the
	-- launch and the visible strike still agree.
	--
	-- GREENHOLLOW AND DUSTBOWL KEEP 0.70 / 0.50 by having no entry here at
	-- all. Their throws are short enough that the geometry never sends
	-- anybody anywhere dangerous, and they are the two biomes that are not
	-- allowed to change.
	--======================================================================
	Confiscate = {
		--==================================================================
		-- HOW OFTEN A CATCH LEAVES THE POD BEHIND INSTEAD
		--
		-- Rolled ONCE per pod, server-side, on its first confirmed catch by
		-- one of these three. On a leave the pod is marked GuardianAbandoned
		-- for good: every later catch still throws the carrier, and none
		-- takes the pod or rolls again. Strict boundary: leave iff
		-- roll < this, with roll in [0, 1). See GuardianCatch.
		--==================================================================
		LeaveBehindChance = 0.40,
		tanglemire = { Seam = "RightHand", Side = 0.35, Steady = "right",
			AwayWeight = 0.45, RoadWeight = 1.00 },
		emberroot = { Seam = "FistR", Side = 0.30, Steady = "right",
			AwayWeight = 0.45, RoadWeight = 1.00 },
		starbloom = { Seam = "LowerJaw", Side = 0.00, Steady = "jaw",
			AwayWeight = 0.45, RoadWeight = 1.00 },
	},

	--======================================================================
	-- HOW MUCH DAYLIGHT A CARRIED POD KEEPS
	--
	-- Between the pod and the front of the guardian, and between the pod and
	-- the ground. Small on purpose: it is carried, not held at arm's length.
	--======================================================================
	HaulClearance = 0.4,

	--======================================================================
	-- HOW LONG A WALK HOME IS ALLOWED TO TAKE
	--
	-- A guardian hauling a pod is holding the only copy of it, so the one
	-- thing that must not happen is the walk never ending. Past this the
	-- haul is deposited wherever the guardian has got to -- see
	-- NestService.depositHaul, which prefers the nest slot and falls back to
	-- a loose pod on the ground. Generous: the longest real leash is two
	-- biome segments at the slowest return speed, which is about forty
	-- seconds.
	--======================================================================
	HaulSeconds = 90,

	--======================================================================
	-- A LOST GUARDIAN IS REBUILT (2026-10-04, the owner's report: a live
	-- server that had been up for hours had no guardian at any nest, and a
	-- restart brought them all back)
	--
	-- A guardian is built once, when its nest is raised, and before this
	-- nothing rebuilt one whose rig went away mid-session -- dusk's
	-- ResetParents only moves a guardian whose root still exists. NestService
	-- now checks the SERVER's rig every tick and rebuilds it through the same
	-- builder when it is genuinely gone, dead or out of the world:
	--
	--   FallStuds          below its nest's floor by this much, it has left
	--                      the world (FallenPartsDestroyHeight is -500; the
	--                      road and the rain biome are flat)
	--   RetrySeconds       the waits after a failed rebuild, the last repeated
	--   WarnEverySeconds   a failing rebuild is warned about at most this often
	--   BusyCapSeconds     a throw holds its nest (`busy`) for at most a few
	--                      seconds and is waited for; past this a lost rig is
	--                      rebuilt anyway
	--======================================================================
	Recovery = {
		FallStuds = 150,
		RetrySeconds = { 2, 4, 8, 16, 30, 60 },
		WarnEverySeconds = 60,
		BusyCapSeconds = 20,
	},
}

--==============================================================================
-- STORMSTRIDER, THE RAIN EVENT'S GUARDIAN (2026-10-02)
--
-- The owner's rule: its chase-speed targets are SpeedScale x the Starbloom
-- guardian's under equivalent player conditions, the ramp logic preserved --
-- 1.15 at first, then 1.80, and 2.5 since the owner found even that too slow
-- (2026-10-02). So it carries Astralmaw's profile number for number, plus
-- SpeedScale (ITS OWN knob; no other profile has one), which NestService
-- applies to the WHOLE chase speed it works out -- the ramp, the rage and the
-- shortfall, the shortfall measured against Starbloom's own recommendation (the
-- event nest's) -- so against any one player, at any moment of the ramp, it
-- runs exactly 2.5 x what Astralmaw would: 195 at the opening, 240 at the top,
-- the same 3.4 s ramp, before rage and shortfall. At that speed it covers 30
-- to 45 studs a tick, so NestService widens ITS OWN sweep allowance by the same
-- factor (every other guardian keeps 40).
-- The walk home, the throw and its aim are Astralmaw's, unscaled: the owner
-- named the chase. Its catch radius, its hitbox and the player's movement are
-- every guardian's. CatchLightning: each confirmed catch stamps one VISUAL
-- strike for the clients (ParentAnim); nothing about the catch changes.
--==============================================================================
do
	local storm = table.clone(GameConfig.Parent.Guardians.astralmaw)
	storm.SpeedScale = 2.5
	storm.CatchLightning = true
	GameConfig.Parent.Guardians.stormstrider = storm
end

--==============================================================================
-- WHERE THIS BIOME'S GUARDIAN PUTS A CONFISCATED POD, OR NOTHING
--
-- Nothing for Greenhollow and Dustbowl, and that absence is load-bearing in
-- exactly the way guardianProfile's is.
--==============================================================================
function GameConfig.confiscateProfile(biomeId: any): any
	if type(biomeId) ~= "string" then
		return nil
	end
	-- Profiles only. The table also holds LeaveBehindChance, a number, and no
	-- id may resolve to it.
	local profile = GameConfig.Parent.Confiscate[biomeId]
	return if type(profile) == "table" then profile else nil
end

do
	local chance = GameConfig.Parent.Confiscate.LeaveBehindChance
	assert(type(chance) == "number" and chance == chance and chance >= 0 and chance <= 1,
		"GameConfig.Parent.Confiscate.LeaveBehindChance must be a number in 0..1")
end

--==============================================================================
-- THE PROFILE FOR A SPECIES, OR NOTHING
--
-- Nothing is the answer for four of the five guardians and that is the point:
-- an absent profile is what makes this whole block unable to touch them.
--==============================================================================
function GameConfig.guardianProfile(species: any): any
	if type(species) ~= "string" then
		return nil
	end
	return GameConfig.Parent.Guardians[species]
end

--==============================================================================
-- THE PARENT IS AS FAST AS THE BIOME ASKS YOU TO BE, PLUS A MARGIN
--
-- It used to be Base + PerBiome * (order - 1): 26, 38, 50, 62, 74. Measured
-- against what a player who MEETS each biome's own RecommendedSpeed actually
-- runs at -- 16, 42, 54, 68, 82 -- only Greenhollow's parent could catch
-- anyone. Every deeper biome had a guardian SLOWER than the player it exists to
-- threaten, and the shortfall grew with depth: -4, -4, -6, -8. That is exactly
-- backwards. The further you are from safety, the more the run home should
-- cost, and a monster you can stroll away from is scenery.
--
-- Deriving the speed FROM the recommendation ties the two together, so a biome
-- whose difficulty is retuned can never leave its guardian behind -- there is
-- no second number to remember.
--
--     biome         player at rec   parent   was
--     Greenhollow            16.0     26.0    26   unchanged
--     Dustbowl               42.0     52.0    38   could not catch
--     Tanglemire             54.0     64.0    50   could not catch
--     Emberroot              68.0     78.0    62   could not catch
--     Starbloom              82.0     92.0    74   could not catch
--
-- Rage still stacks on top of all of these (+5 each, four deep), and a player
-- carrying a heavy pod is far slower than any of it -- 12.6 at Dustbowl with
-- 10,000 kg in their arms. Being caught is meant to be what happens when you
-- get greedy, not what happens because you turned up.
--
-- IT TAKES THE RECOMMENDATION, NOT THE BIOME: BiomeData requires GameConfig, so
-- GameConfig cannot require BiomeData back. `walkSpeedFor` is declared further
-- down this file and that is safe -- it is a table field resolved when this is
-- CALLED, not an upvalue captured where it is defined.
--==============================================================================
--
-- THE SECOND ARGUMENT IS WHO IT IS CHASING, AND IT IS OPTIONAL
--
-- Omitted -- or from a player whose profile has not loaded -- this is exactly
-- the flat margin it has always been. Unknown means UNCHANGED rather than
-- unqualified: a mid-load player is not evidence of anything, and guessing
-- against them would put the harshest speed in the game behind a race
-- condition.
--==============================================================================
function GameConfig.parentWalkSpeedFor(
	recommendedSpeed: number,
	targetSpeedScore: number?
): number
	local rec = tonumber(recommendedSpeed) or 0
	-- NaN fails every comparison, so test it directly rather than clamping.
	if rec ~= rec or rec < 0 then
		rec = 0
	end
	local base = GameConfig.walkSpeedFor(rec) + GameConfig.Parent.SpeedMargin

	local score = tonumber(targetSpeedScore)
	-- rec == 0 is Greenhollow, which recommends nothing and therefore cannot
	-- have anybody fall short of it. Dividing by it would be a NaN, and the
	-- tutorial biome keeping its shipped 26 is the point.
	if score == nil or score ~= score or rec <= 0 then
		return base
	end
	local shortfall = math.clamp(1 - math.max(score, 0) / rec, 0, 1)
	return base + GameConfig.Parent.UnderSpeedMargin * shortfall
end

--==============================================================================
-- THE TREADMILL
--
-- Speed per second while you stand on it. The only faucet for Speed, the same
-- way EconomyService is the only faucet for cash -- one source is what keeps a
-- number auditable when a dozen systems want to grant it.
--==============================================================================
--==============================================================================
-- PLANTING
--
-- Structure, not balance: WHEN a plant changes shape as a fraction of its own
-- grow time, not how long any particular species takes -- that is SeedData's.
--
-- Here rather than inside PlantService because THE CLIENT NEEDS IT. The hatch
-- timer counts down to the next stage, so it has to compute the same thresholds
-- the server does, from the same numbers. A private constant in the service
-- would have meant the countdown and the transition disagreeing.
--==============================================================================
GameConfig.Plant = {
	-- How far through its growth a pod becomes a sprout.
	--
	-- DEAD NOW, and kept only so an old save's stage maths still reads. Nothing
	-- in the ground sprouts any more: a planted pod stays a pod until its owner
	-- hatches it by hand, and what comes out is already the creature. The stage
	-- between them had no decision in it -- it was a thing you watched.
	SproutAt = 0.35,
	TickSeconds = 1,
	-- How close you must stand to plant, and to reach the point you clicked.
	-- Generous -- a convenience, not a skill check.
	RangeStuds = 26,

	--==========================================================================
	-- YOU PUT IT WHERE YOU CLICK
	--
	-- The bed used to be an invisible 3-by-N grid and planting snapped to the
	-- nearest free cell. That made a plot a form to fill in. Free placement
	-- makes it a garden you arrange -- which is the only reason to look at
	-- somebody else's.
	--
	-- The grid attachments still exist in MapService, but only as the table
	-- that says where a PRE-FREE-PLACEMENT save lands. Nothing places into
	-- them any more.
	--==========================================================================
	-- How far inside the soil's edge a click is pulled, so nothing is planted
	-- half-way through the bed frame. A click outside the bed is CLAMPED rather
	-- than refused: "exactly where I clicked" should stop being exact only at
	-- the rim, and a refusal there reads as the game being broken.
	EdgeMarginStuds = 1.6,
	--==========================================================================
	-- ONE SMALL CIRCLE FOR EVERYTHING (the owner's rule, 2026-10-02)
	--
	-- The preview disc's width, the same for every pod, plant and Secret
	-- whatever its species, rarity, size or model. It marks where the BASE goes,
	-- not how far the model reaches: a big model may overhang its neighbours,
	-- its own fence, gate, signs and mill, and nothing is refused for that. The
	-- base itself stays on the owner's own soil -- the clamp above keeps the
	-- whole circle on it, because EdgeMarginStuds is more than its radius.
	--==========================================================================
	BaseCircleStuds = 2,
	--==========================================================================
	-- WANDERING, WHICH THE SERVER DECIDES AND THE CLIENT ONLY DRAWS
	--
	-- A grown creature walks its owner's whole plot. A POD DOES NOT MOVE: it
	-- sits where it was planted until it is hatched, because a seed that
	-- strolled off would be a seed you could not find again.
	--
	-- The server picks each destination and stamps four facts on the model --
	-- where from, where to, when it starts, when it arrives. Every client
	-- interpolates the same four numbers against Workspace:GetServerTimeNow(),
	-- so a plant is in the same place on every screen. The alternative, which
	-- this replaced, was each client rolling its own dice: cheap, and wrong the
	-- moment two people look at the same garden.
	--
	-- Four attribute writes per creature per LEG -- roughly one every five to
	-- twelve seconds -- and no CFrame ever crosses the wire.
	--==========================================================================
	Wander = {
		-- How far inside the fence a creature may walk. The fence boards are
		-- 1.6 thick and stand at the plot edge, so this keeps a body off them.
		FenceMargin = 4.5,
		-- Extra room kept clear in front of the gate, so nothing loiters in the
		-- doorway looking like it is about to leave.
		GateMargin = 7,
		-- Candidate destinations scored per leg. Enough that the least
		-- crowded of them is meaningfully better than the first; small enough
		-- that twenty plants scoring them is nothing. Ten rather than the six
		-- it was: with legs long enough to cross a plot, six measurably spread
		-- a crowded Level 3 garden worse (twenty plants simulated: a plant
		-- resting or headed within 8 studs of two others 10.5% of the time at
		-- 6 candidates, 8.3% at 10).
		Candidates = 10,
		-- The most directions tried to find those candidates. A direction
		-- without straight-line room for the tier's minimum leg is thrown away
		-- rather than shortened, so this is what keeps the search bounded
		-- against a fence. How long a leg is lives in SeedData.WanderLadder.
		Attempts = 36,
		-- How far apart the scorer TRIES to keep them. Bounded on purpose: a
		-- Colossal is currently hundreds of studs tall, and scoring against its
		-- real size would make every destination illegal at once. This is a
		-- logical spacing, not a physical one.
		SeparationStuds = 14,
		-- Recomputed only when a leg ends. Between legs the server does nothing
		-- at all for that plant.
		TickSeconds = 0.5,
		-- How often the authoritative offset is written back to the profile.
		-- Committed at the END of a leg rather than continuously -- a creature
		-- mid-stride has no saved position worth having, and a profile write
		-- per frame is the thing this exists to avoid.
		CommitOnArrival = true,
	},

	-- Hold to hatch. Long enough that the pod visibly shakes and the hatch is a
	-- thing you did, short enough that a full bed is not a chore.
	HatchHoldSeconds = 1.1,

	--==========================================================================
	-- INSTANT HATCH: THE SAME HATCH, WITHOUT THE WAIT, FOR ROBUX
	--
	-- A second prompt on a pod that is still counting down. Pressing it asks
	-- Roblox for the purchase; the receipt is what hatches the pod. The price
	-- and the product id live in GameConfig.Store.InWorld with every other
	-- Robux product.
	--
	-- F, NOT E. E is the free Hatch prompt on a READY pod, and prompts share a
	-- key one at a time: on E, a growing pod beside a ready one could take the
	-- key from it, and the player who pressed E to hatch for free would get a
	-- purchase dialog. On F the two show side by side, each over its own pod.
	--
	-- No hold. The purchase dialog is already the confirmation, and a hold in
	-- front of a dialog is two confirmations.
	--==========================================================================
	InstantHatch = {
		ActionText = "Instant Hatch",
		-- What the same prompt says, with no price, to a player holding a saved
		-- Instant Hatch (2026-09-30; PlantService.InstantHatch): the press
		-- spends the credit instead of opening a purchase.
		SavedActionText = "Free Instant Hatch",
		Key = Enum.KeyCode.F,
		-- E's gamepad twin is the default ButtonX, so the same reasoning moves
		-- this one to ButtonY.
		GamepadKey = Enum.KeyCode.ButtonY,
		-- One purchase dialog per press. A key held down, or a finger that
		-- bounces, would otherwise ask the server to open it over and over.
		OfferGapSeconds = 1,
	},
	-- How long the shell burst lasts before its pieces are gone. 0.35 since the
	-- reveal was built: the shell has to be out of the way before the creature
	-- comes up, or the two read as one pile of parts. See Hatch below.
	BurstSeconds = 0.35,

	--==========================================================================
	-- THE REVEAL: WHAT A HATCH LOOKS LIKE, AND WHAT IT IS NOT ALLOWED TO DO
	--
	-- Every number the hatch animation uses is here, because the animation runs
	-- in two places -- the server bursts the shell it owns, each nearby client
	-- draws the reveal -- and two files guessing at the same timing is how a
	-- creature comes up through a shell that has not gone yet.
	--
	-- THE ANIMATION NEVER DECIDES ANYTHING. The plant is in the player's
	-- Backpack and the garden is saved before any of this starts; if a client
	-- never draws a frame of it, the only thing lost is the frame. See
	-- PlantService.hatch for the order, which is not negotiable.
	--
	-- ONE EVENT, NOT A STREAM. The server sends one message with a server
	-- timestamp and every nearby client animates locally off it. Nothing here is
	-- per-frame replication.
	--==========================================================================
	Hatch = {
		-- Server -> every client, on the GameEvent remote this file already owns.
		Action = "HatchReveal",
		-- Past this, a client ignores the message outright. A hatch on the far
		-- side of a 1,500 stud road is not worth a model.
		HearingStuds = 240,

		-- THE HOLD, which is feedback and nothing else. The prompt's own
		-- HatchHoldSeconds above is the authority; these only shape the rattle.
		Hold = {
			-- The shake starts at a tenth of its full violence and arrives there
			-- as the hold fills, so the pod reads as being worked loose rather
			-- than as already broken.
			StartFactor = 0.10,
			-- Tier-coloured light inside the shell, off the seams, over the hold.
			GlowBrightness = 2.4,
			GlowRange = 10,
			-- Dust off the shell. Small: this is a promise, not the burst.
			DustRate = 14,
			DustCap = 26,
		},

		-- THE BURST. Compress, flash, then outward -- inside BurstSeconds.
		Burst = {
			-- How far in the shell is squeezed before it lets go.
			Compress = 0.92,
			-- The fraction of the burst spent compressing.
			CompressShare = 0.30,
			-- Outward travel, as a multiple of the pod's own diameter, so a Tiny
			-- does not spray parts across somebody's bed and a Colossal does not
			-- look like it deflated.
			SpreadPerDiameter = 0.55,
			Lift = 2.6,
			FlashBrightness = 6,
			FlashRange = 26,
		},

		-- THE CREATURE. Built by the real builder, at the real tier, then thrown
		-- away: it cannot be touched, queried, tagged or paid.
		Reveal = {
			Seconds = 0.8,
			ScaleStart = 0.65,
			-- How far it rises out of the glow, as a multiple of its own height.
			RiseShare = 0.22,
			-- The forward lean it settles out of, in degrees. A turn is not
			-- allowed: a plant that spins reads as a shop viewport, not a reveal.
			LeanDegrees = 9,
		},

		-- THE LABEL. Species, rarity and size, and what it pays.
		Label = {
			Seconds = 1.5,
			FadeSeconds = 0.45,
			NameSize = 34,
			LineSize = 20,
			IncomeSize = 26,
			Width = 300,
			Height = 108,
			-- How far above the creature's own head it floats, in studs.
			Lift = 1.4,
			NewText = "NEW DISCOVERY",
		},

		-- THE PAID PULSE. The only difference a purchase makes to the animation:
		-- a gold ring and no hold.
		Paid = {
			PulseSeconds = 0.15,
			Color = Color3.fromRGB(255, 205, 80),
		},

		--======================================================================
		-- THE ROLL: WHAT WILL IT BE? (2026-09-29; in the world since the same day)
		--
		-- The owner's rule: when a pod hatches, the place where it stood cycles
		-- plant silhouettes under a floating question mark for ABOUT THREE
		-- SECONDS -- quickly at first, slowing -- and then shows the plant that
		-- came out, with the hatch's own effects. IN THE WORLD, where the pod was,
		-- for everybody nearby: no card, no panel, nothing over the camera, and
		-- nothing that stops anybody moving.
		--
		-- IT IS A PICTURE OF A DECISION ALREADY MADE. The species was fixed when
		-- the pod was made, and the plant is in the Backpack and on the profile
		-- before the first silhouette is drawn (PlantService.hatch). Nothing
		-- here rolls, picks or decides: the silhouettes are the plants of the
		-- pod's own biome, in an order drawn from the hatch's token, and the
		-- last of them is the plant that hatched.
		--
		-- EVERY HATCH HAS ITS OWN. Two pods hatched together are two rolls side
		-- by side, each where its pod stood, each three seconds long. Nothing
		-- waits for anything else.
		--
		-- THE ROLL IS TIME PUT BETWEEN THE BURST AND THE CREATURE, and nothing
		-- else. With it off, that time is nought and a hatch is second for
		-- second the hatch it was on 2026-09-17. TIER INTENSITY below still
		-- holds: a Colossal is a bigger event than a Tiny, never a longer one.
		--======================================================================
		Roll = {
			-- ON FOR PLAYERS: the owner switched it on on 2026-09-30 ("enable the
			-- silhouette roll now so i can publish it live"). Until then it shipped
			-- off, and StudioPreview turned it on in Studio alone, for the server
			-- and the client alike. False turns it off on a published server again.
			Enabled = true,
			StudioPreview = true,
			-- From the hatch to the plant, shown. ABOUT THREE SECONDS: HatchRoll
			-- refuses to load with this outside MinSeconds and MaxSeconds.
			Seconds = 3,
			MinSeconds = 2.5,
			MaxSeconds = 3.5,
			-- How many silhouettes are shown. The last is the plant's own.
			Steps = 9,
			-- How long the first and the last are held: quick, then slow. The
			-- holds between them grow evenly and the whole is stretched to fill the
			-- time from the burst to the reveal, so these two are a shape.
			FirstHold = 0.12,
			LastHold = 0.6,
			-- The promise: no silhouette is held for less than this. They turn
			-- over; they never flicker. HatchRoll refuses numbers that break it.
			FloorHold = 0.1,
			-- A plant is never kept a secret for longer than this, whatever a
			-- clock or a lost message does.
			MaxHideSeconds = 10,
			-- On the plant's Tool: the server time its plant may be shown.
			Attribute = "RevealAt",
			--==================================================================
			-- WHAT IS DRAWN WHERE THE POD STOOD (HatchFX)
			--
			-- MODEST, for a phone: one dark shape at a time, a question mark on
			-- one sign and a disc on the soil. No particles, no lights.
			--==================================================================
			World = {
				-- A silhouette's longest side, in pod diameters and in studs: the
				-- shapes are the size of the shell, whatever plant they are the
				-- shape of. The size of the PLANT is the reveal's to show.
				SizeInPods = 1.3,
				MinStuds = 2.6,
				MaxStuds = 9,
				-- The question mark: how tall, and how far over the shapes.
				MarkInPods = 0.85,
				MarkMinStuds = 1.8,
				MarkMaxStuds = 5,
				MarkGapStuds = 0.4,
				-- It rides up and down by this much, this often. Still under
				-- Reduced Effects.
				BobStuds = 0.22,
				BobSeconds = 1.5,
				-- The disc on the soil, in pod diameters.
				DiscInPods = 1.15,
				-- More rolls than this at once, on one screen, are a question
				-- mark with no shapes turning under it.
				MaxShapes = 3,
			},
		},

		--======================================================================
		-- TIER INTENSITY: SCALE THE EFFECT, NOT THE RUNTIME
		--
		-- A Colossal is a bigger event than a Tiny, and it is NOT a longer one:
		-- the timings above are shared, and only the counts and sizes below
		-- change. Anything else turns the seventh hatch of the evening into a
		-- wait, and the top tiers are the ones a player hatches deliberately.
		--
		-- CameraBump is the owner's own camera, Titan and Colossal only, in
		-- studs, and it is off entirely under Reduced Effects.
		--======================================================================
		Tiers = {
			{ rings = 1, ringScale = 1.6, particles = 18, flash = 0.6, bump = 0, lightning = false },
			{ rings = 1, ringScale = 1.8, particles = 22, flash = 0.7, bump = 0, lightning = false },
			{ rings = 1, ringScale = 2.1, particles = 30, flash = 0.9, bump = 0, lightning = false },
			{ rings = 1, ringScale = 2.4, particles = 38, flash = 1.0, bump = 0, lightning = false },
			{ rings = 1, ringScale = 2.7, particles = 48, flash = 1.2, bump = 0, lightning = false },
			{ rings = 2, ringScale = 3.0, particles = 60, flash = 1.4, bump = 0.5, lightning = false },
			{ rings = 2, ringScale = 3.4, particles = 74, flash = 1.7, bump = 0.9, lightning = true },
		},

		--======================================================================
		-- THE SOUNDS THIS ANIMATION ASKED FOR, AND HAS HAD SINCE 2026-09-17
		--
		-- They were named, empty and silent from the day the reveal was built --
		-- an empty string plays nothing at all, deliberately, because a pod
		-- rattle played from the mill's belt is not a placeholder, it is a wrong
		-- sound, and it would have shipped.
		--
		--   Rattle    a shell working loose, under the 1.1 s hold
		--   Crack     the shell letting go, on the burst
		--   TimeSkip  the paid pulse: a wait being skipped
		--
		-- Blanking any of these three is still how you turn one off, and the
		-- three call sites in HatchFX still check both the string and the row.
		--======================================================================
		Sounds = {
			Rattle = "HatchRattle",
			Crack = "HatchCrack",
			TimeSkip = "HatchTimeSkip",
		},
	},

	--==========================================================================
	-- ONE VERB ON ONE EXISTING REMOTE
	--
	-- Tool.Activated fires on the server with no idea WHERE the player clicked,
	-- and neither does ClickDetector. A click position can only come across the
	-- wire. Rather than add a remote, this rides GameEvent -- which ServerMain
	-- has always created and nothing has ever used.
	--
	-- The position is a claim by the client and is treated as one: the server
	-- re-checks the plot is theirs, the point is on their own soil, and they
	-- are standing within RangeStuds of it.
	--==========================================================================
	PlaceAction = "PlantAt",
	--==========================================================================
	-- TAKING ONE BACK, FROM THE PANEL
	--
	-- The world already has a way: walk over and hold E on the Pick Up prompt.
	-- This is the same act reached from the Garden panel, which is the only
	-- place a player can see the whole bed at once.
	--
	-- A SECOND ACTION ON THE SAME REMOTE, not a second remote. GameEvent already
	-- carries PlantAt and the argument after the action string is already
	-- treated as a claim rather than as an instruction; one more verb costs
	-- nothing and keeps the validation in one place.
	--==========================================================================
	PickUpAction = "PickUp",

	--==========================================================================
	-- MY PLANTS (2026-10-04, the owner's menu): four more verbs on the same
	-- remote, each a request the server settles (PlantService) and answers on
	-- it with `Reply` and a table { op, ok, code, planted, returned }.
	--
	--   Plant    an item id: a stored, fully hatched creature into the ground,
	--            on a spot of the player's own soil the server picks
	--   Return   a placement id: a planted grown creature back to the Bag
	--   Best     nothing: EQUIP BEST -- the best earners in, weaker ones out
	--   Clear    nothing: UNEQUIP ALL -- every grown creature back to the Bag,
	--            refused whole if the Bag cannot hold them all
	--
	-- `Cooldown` is how soon one player's next request is heard: repeated
	-- presses are answered once. `SpotStep` is the grid newcomers' spots are
	-- picked from (GardenPlan.spots), in studs.
	--==========================================================================
	MyPlants = {
		Plant = "MyPlantsPlant",
		Return = "MyPlantsReturn",
		Best = "MyPlantsBest",
		Clear = "MyPlantsClear",
		Reply = "MyPlantsResult",
		Cooldown = 0.6,
		SpotStep = 2.5,
	},

	--==========================================================================
	-- WHERE THE PICK UP BUTTON STANDS
	--
	-- It used to float `height + 0.8` above the plant's base. Measured off the
	-- production builder on 2026-09-18 that is 4.2 studs for a Tiny Nubkin and
	-- 68.2 for a Colossal Supernovus, whose footprint reaches 41.8 studs from its
	-- centre -- a button nobody standing beside the plant can see without
	-- zooming the camera right out.
	--
	-- Now a plant short enough to have its head within reach keeps the button
	-- just above it, exactly as before. Anything taller gets it at the edge of
	-- its footprint that faces the player, at a person's height:
	--
	--   InteractHeight   studs above the soil for a tall plant's button, and
	--                    the test for "short": height + 0.8 at or under it
	--   EdgeMargin       studs outside the footprint edge, so it is in front of
	--                    the body rather than on it
	--   StandOff         never closer to the plant than this in front of the
	--                    player -- a player standing INSIDE a huge footprint gets
	--                    it just ahead of them, never behind them
	--   DeadbandDegrees  how far the player's bearing must move before the
	--                    button follows, so crossing the centreline does not
	--                    flick it from one side to the other
	--   SoilInset        studs it keeps inside the bed's edge; it never leaves
	--                    the soil for a fence, the road or the next plot
	--   TweenSeconds     how long it glides when it moves, which is the
	--                    selection's own poll -- no per-frame work
	--
	-- Client presentation only. The server never sees this point: PickUpById
	-- re-tests ownership, growth and the bag against the placement id, and the
	-- click range is PlantPickUI's SELECT_RANGE from the plant, unchanged.
	--==========================================================================
	Reach = {
		InteractHeight = 4.5,
		EdgeMargin = 1.0,
		StandOff = 1.5,
		DeadbandDegrees = 20,
		SoilInset = 1.0,
		TweenSeconds = 0.25,
	},
}

GameConfig.Treadmill = {
	--==========================================================================
	-- THIS IS A BASE RATE AND IT IS MEANT TO LOOK SLOW
	--
	-- The whole speed ladder measured against the parents:
	--
	--     out-run biome 1 (19)     453 Speed    ~4 min
	--     out-run biome 2 (30)   2,208 Speed   ~18 min
	--     out-run biome 3 (41)   4,133 Speed   ~34 min
	--     out-run biome 4 (52)   6,260 Speed   ~52 min
	--     out-run biome 5 (63)   8,636 Speed   ~72 min
	--
	-- At the 12/sec this started as, that entire ladder was TWELVE MINUTES, and
	-- a progression game whose progression is over before the first session is
	-- not a progression game. It was dropped to 2 then; the ten-step mill below
	-- (THE MILL, IN TEN STEPS) later re-priced tier 1 at 20, which is what it is.
	--
	-- The number is low because it is a BASE. Upgrades and Rebirth multiply it,
	-- which is where the actual pacing will come from -- and it is much easier
	-- to add multipliers on top of a slow floor than to claw back a fast one
	-- from players who already have the speed.
	--
	-- Also worth knowing: speed is not a hard gate on biome 1. The parent's
	-- wake delay means a quick raid on a near pod succeeds at WalkSpeed 16. You
	-- buy speed to stop being nervous, not to be allowed in.
	--==========================================================================
	-- The tier-1 rate, kept here because TreadmillService still reads it as the
	-- floor when a tier index falls off the end of the table. It must MATCH
	-- Tiers[1].speed -- a fallback that disagrees with the row it stands in for
	-- is a silent wrong answer at exactly the moment something else is already
	-- wrong. Asserted below the table.
	SpeedPerSecond = 20,
	-- Only pays while you are actually standing on it, alive.
	TickSeconds = 1,
}

--==============================================================================
-- THE MILL, IN FOURTEEN STEPS
--
-- One per plot, and yours only.
--
-- THE RATES ARE PRICED OFF THE BIOME RECOMMENDATIONS, NOT OFF EACH OTHER.
-- Each tier is sized so that the milestone it is meant to serve takes tens of
-- minutes rather than tens of hours:
--
--     T1     20/s    1K in 50s          the first trail, inside a minute
--     T2    100/s    10K in 100s        an immediate reward for the first buy
--     T3      1K/s   1M in 17 min       the early-session goal
--     T4      8K/s                      the bridge to Dustbowl
--     T5     50K/s   167M in 56 min     Dustbowl
--     T6    300K/s   800M in 44 min     Tanglemire
--     T7      2M/s   3B in 25 min       Emberroot
--     T8     12M/s   10B in 14 min      Starbloom
--     T9     70M/s                      post-Starbloom
--     T10   400M/s                      post-Starbloom
--     T11   2.5B/s   costs 400B         the endgame, which Overclock used to
--     T12    15B/s   costs 600B         be: four more machines covering the
--     T13    80B/s   costs 1T           range its ten levels covered
--     T14   450B/s   costs 1.5T         the cap (1e15) in 37 minutes
--
-- THE TOP FOUR ARE THE OWNER'S OWN MILLS (2026-10-06): supplied models, Abyssal
-- Trench, Volcanic Forge, Frozen Aurora and Event Horizon, replayed part for
-- part by MillForms. Overclock ran 800M to 410B a second for 125B to 850B a
-- level; these run 2.5B to 450B for 400B to 1.5T. A tier-10 mill's next step is
-- an upgrade like every other step (OVERCLOCK, below, is history now).
--
-- THE OLD LADDER RAN 2 TO 160 AND WAS NOT A LADDER. It spanned 80x while the
-- score ladder it feeds spans a QUADRILLION, so every tier past the third was
-- indistinguishable in practice and the whole of the pacing had been pushed
-- onto Overclock. This one spans 20 million times, which is the same shape as
-- the thing it is climbing.
--
-- COSTS ARE UNCHANGED. They already climbed faster than the old rates and they
-- climb slower than these, which is deliberate: a tier now buys a visible jump
-- rather than a rounding error, so no step is an obvious skip.
--
-- BeltStuds is how fast the surface travels, and it is not decoration: the run
-- animation is driven from the same number (see SpeedFX), so a faster mill has
-- visibly faster feet. Roblox authors its run cycle for 16 studs a second, so
-- that is the number a track speed of 1.0 corresponds to.
--
-- NOT BALANCE IN THE Rule 7 SENSE -- this is the speed curve, which GameConfig
-- has always owned, sitting next to the curve it multiplies.
--==============================================================================
GameConfig.Mill = {
	--==========================================================================
	-- THE ONE AUTHORITATIVE RATE TABLE
	--
	-- `speed` is Speed SCORE per second, not studs. Everything that prints a
	-- rate -- the mill sign, the upgrade board, the showroom placards, the
	-- startup log -- reads this row through TreadmillService, so a number
	-- changed here is a number changed everywhere.
	--
	-- BeltStuds is the only studs-per-second column and drives the belt
	-- animation and the run cycle. It is untouched by this pass.
	--==========================================================================
	Tiers = {
		{ name = "Compost Walk", speed = 20, cost = 0, beltStuds = 13 },
		{ name = "Garden Path", speed = 100, cost = 10000, beltStuds = 15 },
		{ name = "Trellis Trot", speed = 1000, cost = 75000, beltStuds = 17 },
		{ name = "Millstone", speed = 8000, cost = 500000, beltStuds = 19 },
		{ name = "Glasshouse", speed = 50000, cost = 3500000, beltStuds = 21 },
		{ name = "Sunwheel", speed = 300000, cost = 25000000, beltStuds = 24 },
		{ name = "Heartroot", speed = 2000000, cost = 150000000, beltStuds = 27 },
		{ name = "Inferno Forge", speed = 12000000, cost = 1000000000, beltStuds = 31 },
		{ name = "Celestial Ascent", speed = 70000000, cost = 10000000000, beltStuds = 35 },
		{ name = "Astral Singularity", speed = 400000000, cost = 100000000000, beltStuds = 40 },
		-- The owner's supplied mills (2026-10-06; MillForms). Prices from the
		-- owner's Overclock-removal addendum, which replaced the first proposal.
		{ name = "Abyssal Trench", speed = 2500000000, cost = 400000000000, beltStuds = 45 },
		{ name = "Volcanic Forge", speed = 15000000000, cost = 600000000000, beltStuds = 50 },
		{ name = "Frozen Aurora", speed = 80000000000, cost = 1000000000000, beltStuds = 56 },
		{ name = "Event Horizon", speed = 450000000000, cost = 1500000000000, beltStuds = 63 },
	},
	StartingTier = 1,

	--==========================================================================
	-- WHERE EACH PLOT'S MILL STANDS (moved to the FRONT 2026-10-06, the owner's
	-- choice; GameConfig.millCFrameFor is the one formula)
	--
	-- Measured from the plot's GATE, which never moves (MapService.ResizePlot):
	-- in its frame x runs to the plot's right and -z toward the hub.
	--
	-- PLOTS 1-5: IN FRONT, off the plot's right-hand side -- `Front.Out` studs
	-- right of the plot's centre line, `Front.Ahead` in front of the gate line,
	-- `Lift` up, turned `Front.Yaw` degrees so the console looks along the front
	-- of the plot, toward its own walk line. Chosen by the owner from the front
	-- placement study (KB/HANDOFF.md, 2026-10-06): every mill sits in the gap
	-- between two plots' walk lines (the hub-to-gate corridors, MiniEvent.Disco's
	-- Corridors), wholly in front of the gate line, and every tier 1-14 clears
	-- the walk lines, the deck and its rim, the Disco Mill, the road's empty arc,
	-- every board and prompt, both neighbours and their mills (MillPlacementSpec).
	--
	-- PLOT 6: BESIDE ITS RIGHT-HAND FENCE, where every mill stood before -- its
	-- right side meets the road mouth, so the gap a front mill would need is the
	-- road's empty arc. `Beside.Side` studs out past the plot's half width,
	-- `Beside.Behind` back from the gate line, the plot's own facing. Its strip
	-- is therefore NOT free for a plot upgrade, as plots 1-5's now are. Tiers
	-- 12-14 overhang there by the owner's leave (2026-10-06); MillPlacementSpec
	-- pins exactly how far, and MillModel.Soften makes every overhanging part
	-- non-colliding.
	--
	-- The beside numbers' history: it stood 11 out and 17.6 back until
	-- 2026-09-30, when a Level 3-4 wing fence (25.4 back from the gate) ran
	-- through the back of every tier and tier 1's compost bin cut 0.18 into the
	-- right fence. At 12.1 back a tier 1-11 mill spans 0.9 to 23.6 behind the
	-- gate; 12 out puts tier 1's bin 0.8 off the fence.
	--==========================================================================
	Place = {
		Lift = 0.6,
		Front = { Out = 37.5, Ahead = 24.5, Yaw = 90 },
		Beside = { Side = 12, Behind = 12.1, Yaw = 0 },
		BesidePlots = { [6] = true } :: { [number]: boolean },
		--======================================================================
		-- WHAT TOUCHES PLOT 6'S OWN FENCE (tier 13 only)
		--
		-- The owner asked for the smallest nudge of plot 6's mill that clears
		-- tier 13's left front spire from the right-hand fence by 0.5 without a
		-- bigger road overhang. There is none (searched 2026-10-06, 252,601
		-- poses): the spire needs 1.02 out, which pushes tiers 12-13 into the
		-- road's empty arc unless the mill also goes at least 2.3 back -- and
		-- every tier's step has 1.00 before the Level 3-4 wing's front fence.
		-- So these parts stay where the owner put them and are softened with the
		-- overhang (MillModel.Soften): the spire at every level, and at Levels
		-- 3-4 a snow bank and an ice boulder behind the step, in the wing's front
		-- fence. Named by part AND by where each stands in the mill's frame,
		-- because the names repeat.
		--======================================================================
		BesideTouch = {
			[13] = {
				{ Name = "Spire", At = Vector3.new(-10.262, 2.897, -7.982) },
				{ Name = "SnowBank", At = Vector3.new(5.649, -0.695, 13.271) },
				{ Name = "IceBoulder", At = Vector3.new(-5.808, -0.507, 13.408) },
			},
		} :: { [number]: { { Name: string, At: Vector3 } } },
	},

	-- What the belt creeps at with nobody on it. Not zero: a dead mill reads as
	-- broken, and a slow drift says "this is a machine and it is waiting".
	IdleStuds = 1.6,

	--==========================================================================
	-- THE ANIMATION IS NOT AUTHORED AT ONE SPEED
	--
	-- Roblox's own Animate script scales the run cycle by speed/16, which is
	-- what keeps feet on the ground when a character actually moves. A mill
	-- character does not move, so the same division has to be done by hand --
	-- and doing it from the SAME BeltStuds the chevrons use is what stops the
	-- belt crawling under sprinting legs.
	--==========================================================================
	RunCycleStuds = 16,

	--==========================================================================
	-- WHAT THE BELT DOES, TIER BY TIER
	--
	-- One row per mill, and the ladder is meant to be read DOWN a column: every
	-- tier is the tier below it plus exactly one new behaviour. That constraint
	-- is the whole design. Seven belts that each do a different clever thing
	-- would be seven belts a player cannot rank; seven belts that visibly ACCRUE
	-- are a progression somebody can feel themselves climbing.
	--
	--   1  scroll .............. it moves, and nothing else
	--   2  + breathe ........... the set brightens and dims: it is powered
	--   3  + chase ............. arrows light in sequence along the run
	--   4  + rake .............. they lean into the travel, harder when faster
	--   5  + bloom ............. a band of light sweeps the belt through them
	--                           -- painted as brightness, not built as a part
	--   6  + bob and shimmer ... they ride a wave, the plate catches the light
	--   7  + rainbow ........... a spectrum runs the surface itself
	--
	-- Rung 7 needs one thing none of the others do. A belt is a single part, so
	-- its colour is one colour -- there is no varying anything ALONG it, at any
	-- price -- and a plate that merely cycles hues is a plate that is lilac, and
	-- then is blue. That is not a rainbow. A rainbow is all the hues at once, in
	-- order, and the only way to have one on a single belt is to lay flat bands
	-- on it and let them scroll through a spectrum that stays where it is. Which
	-- is what Bands is for, and why it exists on exactly one tier.
	--
	-- Every amplitude here is multiplied by how hard the belt is WORKING, which
	-- is what "animate as the player uses it" actually means: an unoccupied
	-- tier-7 mill idles as a slow green drift, and lights up as a rainbow the
	-- moment somebody steps on. A mill that put on its whole show to an empty
	-- garden would spend most of its life spoiling its own best moment.
	--
	-- Arrows is the only column the SERVER reads -- it builds that many chevron
	-- pairs and stamps the count on each. Everything else is paint and is
	-- applied per client in Ambience, because sixty parts changing colour on the
	-- server is sixty parts of replication a second for something nobody can
	-- interact with.
	--==========================================================================
	Belt = {
		-- Arrows is PAIRS: a chevron is two arms and lights as one. Bands are
		-- flat strips lying on the plate, and only rung 7 has any.
		{ Arrows = 2, Bands = 0, Neon = false, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 3, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 4, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0.85, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 5, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0.85, Rake = 0.30, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 5, Bands = 0, Neon = true, Breathe = 0.35, Chase = 0.70, Rake = 0.26, Bloom = 0.90, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 6, Bands = 0, Neon = true, Breathe = 0.35, Chase = 0.70, Rake = 0.22, Bloom = 0.90, Bob = 0.45, Shimmer = 0.35, Rainbow = 0 },
		{ Arrows = 7, Bands = 9, Neon = true, Breathe = 0.40, Chase = 0.60, Rake = 0.18, Bloom = 1.00, Bob = 0.60, Shimmer = 0.50, Rainbow = 1 },
		{ Arrows = 7, Bands = 0, Neon = true, Breathe = 0.65, Chase = 0.95, Rake = 0.35, Bloom = 1.20, Bob = 0.80, Shimmer = 0.90, Rainbow = 0 },
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0.60, Chase = 0.80, Rake = 0.20, Bloom = 1.00, Bob = 0.50, Shimmer = 0.80, Rainbow = 0 },
		{ Arrows = 8, Bands = 12, Neon = true, Breathe = 0.70, Chase = 0.95, Rake = 0.25, Bloom = 1.00, Bob = 0.80, Shimmer = 1.00, Rainbow = 1 },
		-- 11-14, the owner's supplied mills (MillForms): their own eight
		-- chevron pairs, scrolled and coloured by MillFormMotion as their
		-- scripts did, at this belt's real speed -- not by the rungs above.
		-- These rows keep one row per tier for anything that reads the ladder,
		-- and are INERT: no rung paints those belts or their arrows (Ambience
		-- glints a plate with Shimmer, which would repaint the owner's belt).
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0, Supplied = true },
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0, Supplied = true },
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0, Supplied = true },
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0, Supplied = true },
	},

	--==========================================================================
	-- ARROWS DO NOT POP IN AND OUT AT THE WRAP
	--
	-- Every arrow teleports from the front of the belt to the back once a lap.
	-- Unfaded that is a visible blink, and a blink reads as a bug rather than as
	-- tier 1 being humble. This is the fraction of the run over which one fades,
	-- and it applies to every tier for that reason -- it is correctness, not a
	-- rung on the ladder.
	--==========================================================================
	BeltEdgeFade = 0.12,

	Action = "MillUpgrade",

	--==========================================================================
	-- WHERE THE SIGN STANDS, AND WHICH WAY IT LOOKS
	--
	-- It used to sit at (8.6, -6) in the mill's own frame -- the OUTER side,
	-- away from the plot -- facing the same way the walker does. Two problems,
	-- and they are the same problem: a player coming out of their own gate saw
	-- the BACK of it, and a player standing on the belt saw it edge-on. The one
	-- board in the game that has to be read was the one nobody was ever pointed
	-- at.
	--
	-- AT THE FRONT OF THE MILL. It spent a while out on the fence line, angled
	-- at the plot gate, which put it where somebody walking out of their garden
	-- met it first -- and left it looking sideways at the machine it belongs to.
	-- The front is where the mill already points: the console is there, the
	-- mount turns a player to face it, and it is the end everybody approaches
	-- from because the road and the hub are both that way.
	--
	-- The mill's body ends at z = -8.6, so this stands four studs clear of it,
	-- square on, with no yaw at all. YAW ZERO IS THE POINT rather than an
	-- omission: the board's front already faces -Z, which is the mill's own
	-- facing, so it needs no angle of its own and swings round with the plot for
	-- free.
	--
	-- BOTH FACES EARN THEIR KEEP HERE. Front to whoever is walking up; back to
	-- the player standing on the belt, who is turned to face exactly this way by
	-- the mount.
	--==========================================================================
	Sign = {
		--======================================================================
		-- OFF THE FRONT-LEFT CORNER, ON THE WAY IN
		--
		-- Measured, not chosen by eye. In the mill's own frame:
		--
		--   Y -0.6    is the ground. The field's surface sits exactly there --
		--             raycast from the mill down to TheField returns local
		--             -0.60 -- and BuildSign puts the post's bottom on this
		--             frame, so the post meets the grass. The deck's own
		--             underside is at -1.13, i.e. deliberately buried.
		--
		--   Z -11.6   is clear of EVERY tier (MillSignSpec measures it across the
		--             board's own span) and, with the mill at Place.Behind 12.1,
		--             keeps the board's front face 0.3 behind the gate line.
		--             It was -12.6 until the mill moved forward (2026-09-30);
		--             measured then, nothing any tier builds reaches past
		--             Z -11.2.
		--
		--   X -5.5    is the new part. Centred, the board stood square across
		--             the front of your own machine. The plot is on the mill's
		--             -X side and the walk in comes from the spawn pad, so this
		--             puts the board beside that approach instead of across it,
		--             like a station you pass rather than a hoarding you look
		--             through.
		--
		-- The board is 9 * Scale = 6.84 wide, so at -5.5 it spans -8.92 to
		-- -2.08. The plot fence's outer face is at -11.2 (Place.Side 12): 2.28
		-- studs of daylight.
		--======================================================================
		Offset = Vector3.new(-5.5, -0.6, -11.6),
		--======================================================================
		-- THE OTHER TWO SPOTS (2026-10-06)
		--
		-- Offset is where the sign stands BESIDE a plot (plot 6, Place.Beside)
		-- for tiers 1-11. Tiers 12-14's decor -- an anvil and hammer, aurora
		-- rays, lens arcs -- fills that corner, and plots 1-5's mills now stand
		-- in front of their plots, turned. Measured over every tier with each
		-- part grown 0.25, and kept within reach of a player standing on the
		-- belt (MillSignSpec):
		--
		--   FrontOffset       in front of a plot (plots 1-5), every tier: on the
		--                     mill's left, between it and its plot, facing the
		--                     walk line. 1.4 studs of room toward the mill; the
		--                     prompt 15.2 from a mounted player and 39.1 from
		--                     the nearest plot board's (each reaches 18).
		--
		--   BesideTallOffset  beside a plot, tiers BesideTallFrom and up: in
		--                     front of the mill, its face 4.0 past the gate line
		--                     -- the one spot in reach. Behind the step is the
		--                     Level 3-4 wing's fence, the left is the plot and
		--                     the right is the road's empty arc. It does not
		--                     collide (no mill sign does), so it stands with the
		--                     overhang the owner allowed there; the prompt is
		--                     15.9 from a mounted player.
		--======================================================================
		FrontOffset = Vector3.new(-14.5, -0.6, -4.5),
		BesideTallOffset = Vector3.new(1, -0.6, -15.8),
		BesideTallFrom = 12,
		YawDegrees = 0,
		--======================================================================
		-- SLIGHTLY SMALLER
		--
		-- At full size the board is nine studs wide and stands where the mill
		-- used to be visible, so walking up to your own machine meant looking at
		-- a fence-height hoarding with the machine behind it. Three quarters is
		-- enough to still read the price across the plot and small enough that
		-- the mill is the thing you see.
		--
		-- Everything the builder places scales together -- post, board, bolts,
		-- and their offsets -- because a board that shrank while its post did
		-- not would be a lollipop.
		--======================================================================
		Scale = 0.76,
		--======================================================================
		-- FAR ENOUGH TO REACH FROM THE BELT
		--
		-- The sign is 15.3 studs from the belt centre now, and it was 10.5. At
		-- the old 14 a mounted player -- who is held at WalkSpeed zero by the
		-- mount -- could no longer buy the upgrade they are standing on the
		-- thing to afford. Eighteen covers the belt and still will not open from
		-- inside somebody's bed.
		--======================================================================
		PromptRange = 18,
	},

	--==========================================================================
	-- OVERCLOCK, WHICH IS HISTORY (removed 2026-10-06, the owner's addendum)
	--
	-- From 2026-09-17 a tier-10 mill bought OVERCLOCK levels instead of a next
	-- tier: the same Astral Singularity running x2 per level, ten levels, 800M
	-- to 410B a second, for 125B to 850B a level. Tiers 11-14 -- the owner's own
	-- mills -- replaced it and cover the same range as machines. Nothing sells
	-- an overclock any more and the training rate has no overclock factor
	-- (trainingRateFor). A save's MillOverclock is kept so old saves still load,
	-- and a tier-10 save with levels converts ONCE to the lowest of tiers 11-14
	-- paying at least what it did (ProfileSchema.convertOverclock).
	--==========================================================================

}

--==============================================================================
-- THE FLOOR MUST MATCH THE ROW IT STANDS IN FOR
--
-- GameConfig.Treadmill.SpeedPerSecond -- a DIFFERENT table from the one above,
-- which is half the reason this check exists -- is what TreadmillService pays
-- when a tier index falls off the end of Tiers. Left disagreeing with Tiers[1]
-- it would answer a different wrong number at exactly the moment something else
-- had already gone wrong, which is the hardest kind of bug to see.
--==============================================================================
assert(GameConfig.Treadmill.SpeedPerSecond == GameConfig.Mill.Tiers[1].speed,
	"GameConfig.Treadmill.SpeedPerSecond must equal GameConfig.Mill.Tiers[1].speed")

--==============================================================================
-- AND EVERY STEP UP IS A STEP UP
--
-- Two rules, both balance decisions rather than typo guards: every tier pays
-- more than the one below it and costs more than it, so no step is a skip and
-- none is a downgrade; and the belt ladder has one row per tier. (The same rule
-- guarded Overclock's prices against the tier-10 mill until it was removed,
-- 2026-10-06.)
--==============================================================================
do
	local M = GameConfig.Mill
	assert(#M.Belt == #M.Tiers, "GameConfig.Mill.Belt needs exactly one row per tier")
	for i, tier in ipairs(M.Tiers) do
		assert(type(tier.speed) == "number" and tier.speed > 0 and type(tier.cost) == "number" and tier.cost >= 0
				and math.floor(tier.cost) == tier.cost,
			string.format("Mill tier %d needs a positive speed and a whole cost", i))
		if i > 1 then
			local prev = M.Tiers[i - 1]
			assert(tier.speed > prev.speed and tier.cost > prev.cost,
				string.format("Mill tier %d (%s) must pay and cost more than tier %d (%s)",
					i, tier.name, i - 1, prev.name))
		end
	end
end


function GameConfig.parentThrowStudsFor(biomeOrder: number): number
	local P = GameConfig.Parent
	local order = math.max(1, math.floor(tonumber(biomeOrder) or 1))
	return P.BaseThrowStuds + P.ThrowPerBiome * (order - 1)
end

GameConfig.Carry = {
	-- The heaviest thing in the game. Biome 1 tops out at ~110.
	TopTierValue = 9500,
	-- Speed multiplier when carrying a TopTierValue pod. (Read "MaxKg" here
	-- until size tiers replaced kilograms.)
	MinMultiplier = 0.30,
	-- Below 1 flattens the low end. 0.6 keeps small pods nearly free.
	Exponent = 0.6,
	CashPerValue = 1,

	--==========================================================================
	-- TAKING A POD IS HELD, NOT TAPPED
	--
	-- An instant take made a raid a drive-by: run through a nest, tap, gone. A
	-- hold is what puts the player STILL and EXPOSED next to a sleeping monster
	-- for a moment, which is the only part of the raid that has any tension in
	-- it -- and it is what makes the wake delay mean something, since the timer
	-- and the head start now overlap.
	--==========================================================================
	TakeHoldSeconds = 0.7,
	--==========================================================================
	-- WHERE A POD RIDES, AND WHY IT LIVES HERE
	--
	-- CarryService owns the weld, but the CLIENT needs the same numbers to point
	-- the arms at the thing. Two copies of "how far in front" is the two-names-
	-- for-one-fact bug in another coat.
	--
	-- Unchanged values, new home: a Nubkin lands 1.58 studs out and a Bellchime
	-- 3.09, which is settled and not to be retuned.
	--==========================================================================
	GripForwardBase = 0.85,
	GripDrop = -0.35,
	--==========================================================================
	-- THE OVERHEAD CARRY -- 2026-10-01, the owner's approved pose for the secret
	-- pods and plants (SeedData species with Carry = "overhead"): both arms
	-- straight up, the model's BASE this far above the HumanoidRootPart, which is
	-- a quarter-stud over the raised hands' top (measured 2.77 on the R15 rig)
	-- and clear of the head (2.08). Nothing in front of the chest, no forward
	-- offset. CarryService welds by it; CarryPose and SecretCarryCamera read it.
	-- Since 2026-10-03 also every HATCHED plant built from the owner's supplied
	-- rigs (PlantForms.CarriedOverhead) -- their pods keep the chest carry.
	--==========================================================================
	OverheadLift = 3.0,

}

--==============================================================================
-- THE SECRET POD AND PLANT -- 2026-10-01
--
-- The switch and the structure; the numbers are BiomeData's (per biome) and
-- SeedData's (the species). On 2026-10-09 (the owner: "turn secret pods back
-- on"), OFF AGAIN SINCE 2026-10-10 (the owner: "turn off secrets for now").
-- On, each nest stocking rolls its biome's SpawnChance. Off, NestService's
-- roll never runs and the Pod Guide shows no secret row; the only secret pod in
-- a server is one the Studio-only DebugService `SpawnSecret` action asked for
-- or an admin's console grant. Secrets players already own are untouched.
--==============================================================================
GameConfig.Secret = {
	Enabled = false,
	-- The spawn toast: everyone in the server, once per actual spawn, never on a
	-- return, a respawn or across servers.
	Toast = {
		-- The owner's words (2026-10-05), with the biome's display name.
		Title = "A SECRET EGG SPAWNED ON %s!",
		-- A biome with no display name is told without one, never by its id.
		TitleNoName = "A SECRET EGG SPAWNED!",
		-- The word the renderer styles wherever it stands in the title: italic,
		-- silver, dark outline, a grey sweep (static under reduced motion).
		Word = "SECRET",
		SweepSeconds = 1.6,
		-- The weather's special eggs that get the same toast when their event's
		-- biome opens: the Thunderstorm's Pod 3 only -- its real rarity (Divine),
		-- hatch pool and rewards are untouched; this is the notice alone.
		WeatherEggs = { rainpod3 = true },
	},
	-- The guardian's "POD LEFT BEHIND!" after a catch that did not take a secret.
	LeftBehind = {
		Text = "POD LEFT BEHIND!",
		Seconds = 2.2,
	},
	-- The dedicated spot's platform: a cradle in the biome's colours.
	Platform = {
		Radius = 26,
		Thickness = 0.16,
		Stones = 10,
	},
	--==========================================================================
	-- WHICH WAY A PLANTED SECRET POD STANDS (the owner's option 2, 2026-10-02)
	--
	-- PlantService's `facing` for a secret pod, on top of the plot's own
	-- rotation: pi turns the pod's face -- its narrow side -- to the gate. It
	-- says only which way the pod stands, never where it may: the footprint
	-- rules it was chosen for are gone (2026-10-02, the owner's placement rule --
	-- one small base circle for everything, GameConfig.Plant.BaseCircleStuds,
	-- and overlap is allowed), and the facing was kept as it was.
	--==========================================================================
	PodFacing = math.pi,
}

--==============================================================================
-- RAIN (2026-10-02): THE ADMINS' WEATHER EVENT, AND THE BIOME IT UNCOVERS
--
-- Names, structure, geometry and the look. The one balance number -- what the
-- rain pays -- is SeedData.Rain's. WeatherService (server) owns the ONE event:
-- its id, state and deadline, published here as workspace attributes; it
-- builds the temporary terrain (RainBiome) and takes it down. Weather.client
-- draws the rain and the fog, BoostIconsUI the event's icon (2026-10-04; it was
-- WeatherUI's income chip), WorldClock the darker
-- light, ActionToastUI the toasts. It starts from the admin console -- any of the
-- three admin accounts since 2026-10-07, the owner's alone before -- for this
-- server only -- and, since 2026-10-05, on its own (Weather.Auto, below). The guardian, the Secret Egg and the
-- plant are supplied later; the clearing at the far end is kept for them
-- (RainBiome's EncounterSite) and nothing stands in it yet.
--==============================================================================
GameConfig.Weather = {
	-- Workspace attributes, the server's to write and every client's to read.
	-- `State` is "opening" (rain falling, the entrance not yet open), "active"
	-- (the entrance open) or "closing" (the bonus over, the biome fading), and
	-- absent while no rain falls. Times are workspace:GetServerTimeNow(). A
	-- player who joins mid-event reads these and is right on their first frame.
	Attributes = {
		State = "RainState",
		EventId = "RainEventId",
		StartedAt = "RainStartedAt",
		EndsAt = "RainEndsAt",
		OpenedAt = "RainOpenedAt",
		ClosingAt = "RainClosingAt",
		-- The income factor in force: SeedData.Rain.IncomeFactor while the rain
		-- pays, 1 otherwise. Displays read this; the faucet asks the service.
		Factor = "RainFactor",
		-- Which weather it is (2026-10-02): "rain" or "thunder" -- the same
		-- event, the same biome and the same ONE income factor; a Thunderstorm
		-- only looks and stocks differently. Absent while no event runs.
		Mode = "RainMode",
	},
	-- GameEvent actions, server to client. `Opened` goes to everyone in the
	-- server at the moment the entrance opens -- never to a late joiner;
	-- `Warning` and `Evacuated` go to those inside the biome.
	Events = {
		Opened = "RainBiomeOpened",
		Warning = "RainClosingSoon",
		Evacuated = "RainEvacuated",
	},
	-- The console's duration box starts at this. A knob, not a rule.
	DefaultSeconds = 180,
	MinSeconds = 20,
	MaxSeconds = 1800,
	--==========================================================================
	-- AUTOMATIC WEATHER (2026-10-05, the owner's approved settings; briefs:
	-- art/references/automatic-weather-2026-10-05/CLAUDE_PROMPT.md, and
	-- LOWER_RATE_FOLLOWUP.md, which made it rarer the same day: 5% a check, not
	-- 15%; 90/10, not 80/20; sure at 60 minutes, not 30)
	--
	-- WeatherService's own scheduler, per server, inside its one loop. While
	-- the weather is FULLY clear (no event in any state) and at least one player
	-- is here, it checks every CheckSeconds: each check starts weather with
	-- probability Chance, and the mode is then drawn from ModeWeights (weights
	-- after a start, not separate rolls). At GuaranteeSeconds of continuously
	-- populated clear weather a start is made whatever the draws said. Started
	-- weather runs DurationSeconds, opening included.
	--
	-- The quiet window starts when the first player arrives, or when the last
	-- weather -- automatic OR the console's -- has finished all its cleanup; an
	-- empty server resets it. No roll at startup, none during an event, and at
	-- most one attempt per check however late the loop runs.
	--
	-- TWO DRAWS, NOT ONE PER MODE: an ordinary check is weather 5 times in 100,
	-- and that weather is Rain 9 times in 10 -- so 4.5% Rain, 0.5% Thunderstorm,
	-- 95% nothing. The 60-minute check skips the first draw, not the second: a
	-- sure start is Rain or a Thunderstorm 90/10 as well. With these numbers
	-- the eleven draws at 5 .. 55 minutes all miss in about 57% of windows, and
	-- the expected clear wait is about 46.0 minutes (starts about 49 minutes
	-- apart with the three-minute weather) -- an average, not a timer.
	--==========================================================================
	Auto = {
		Enabled = true,
		CheckSeconds = 300,
		Chance = 0.05,
		ModeWeights = { rain = 0.9, thunder = 0.1 },
		DurationSeconds = 180,
		GuaranteeSeconds = 3600,
	},
	-- The opening toast comes this long after the rain begins, and never before
	-- the entrance is open.
	ToastDelaySeconds = 3,
	-- Those inside are warned this long before a timed end.
	WarnSeconds = 5,
	-- The closing, in order: the fog thickens over the biome (ThickenSeconds),
	-- then the biome and its fog fade away together (FadeSeconds). The terrain
	-- is removed only after both, and only once nobody is standing on it.
	ThickenSeconds = 2,
	FadeSeconds = 4,
	-- And it waits, this long past the fade at most, while anybody is still
	-- knocked down (2026-10-10): a body that is down is moved by its own player's
	-- computer, so it is evacuated once it stands (WeatherService, WHO IS DOWN).
	-- A guardian's throw lasts about 12 s at the most.
	LimpHoldSeconds = 15,
	-- How long the rain and the fog take to fade in, and out, on a client.
	RainFadeSeconds = 2.5,
	--==========================================================================
	-- THE WHITE CLOUDS (2026-10-02, second pass): billowing banks of
	-- overlapping balls, built by EVERY CLIENT for itself from one seeded
	-- recipe (Shared/RainClouds) the moment it sees the rain's state -- so a
	-- late joiner has them on its first frame and the server holds no part of
	-- them -- and faded from one number per zone. Round the island, down the
	-- road outside its walls, and thickest along the temporary biome. Nothing
	-- here shortens the world's visibility: FogEnd and Atmosphere are
	-- MapService's and untouched.
	--==========================================================================
	Clouds = {
		Seed = 20261004,
		-- Round the island: a bank every Spacing studs along each edge, Inset
		-- studs outside it; the road's mouth left open; the bank the bridge
		-- passes through is the entrance's.
		Inset = 16,
		Spacing = 52,
		-- Down the road, outside its walls and above them, every RoadSpacing
		-- studs from the island to the last biome's end.
		RoadSpacing = 150,
		RoadOffset = 34,
		-- Along the temporary biome's route, either side beyond the walls, and
		-- over its wide rooms: closer together and bigger.
		RouteSpacing = 60,
		RouteOffset = 20,
		RouteScale = 1.2,
		-- A bank: Puffs balls of Diameter studs, overlapping along the bank's
		-- Length and rising to its middle, with one or two riding on top.
		Puffs = { Min = 5, Max = 7 },
		Diameter = { Min = 14, Max = 30 },
		Length = { Min = 44, Max = 64 },
		-- The height of a bank's centre line above the ground, by zone.
		Height = { Perimeter = 14, Road = 52, Biome = 54, Room = 70, Entrance = 20 },
		-- Transparency per zone while it rains; the biome's while it opens
		-- (concealing what emerges) and until it has emerged; the entrance's
		-- at the start of the opening; and how solid the biome's banks get as
		-- it closes.
		Perimeter = 0.42,
		Road = 0.55,
		Biome = 0.6,
		BiomeConceal = 0.12,
		EmergeSeconds = 5,
		Entrance = 0.8,
		EntranceConceal = 0.3,
		Thick = 0.1,
		-- Gentle movement: each bank bobs this far over this long (none under
		-- reduced motion).
		Bob = { Studs = 1.4, Seconds = 9 },
		-- Day: lit white plastic. Night: a dim self-lit grey-blue, readable
		-- without glare.
		Day = { Color = Color3.fromRGB(246, 249, 253), Material = Enum.Material.SmoothPlastic },
		Night = { Color = Color3.fromRGB(132, 142, 166), Material = Enum.Material.Neon },
		-- At most this many balls on a client. RainEventSpec holds it.
		PartBudget = 800,
	},
	--==========================================================================
	-- THE LOOK OF THE RAIN (WorldClock, the one owner of Lighting): overcast,
	-- not dark, laid over whatever the day/night blend already is and read off
	-- one number, so when the rain ends the live phase simply comes back and
	-- nothing is restored from a snapshot. The fraction of the brightness
	-- kept, the exposure taken off, how far the two ambients move toward the
	-- rain's cool grey (its day pair, or its night pair, blended like the
	-- rest), softer shadows, less glint, a restrained cool tone through one
	-- ColorCorrection WorldClock owns, and the sky's cloud layer (a Terrain
	-- Clouds instance, WorldClock's own, client-local).
	--==========================================================================
	Light = {
		-- By day the brightness drops to this fraction; by night it hardly
		-- does (NightBrightness), because the night is already the floor of
		-- what stays readable, and its ambient pair sits a touch ABOVE the
		-- plain night's so a rainy night is never darker than a clear one.
		Brightness = 0.78,
		NightBrightness = 0.97,
		Exposure = -0.12,
		Ambient = Color3.fromRGB(112, 122, 142),
		OutdoorAmbient = Color3.fromRGB(138, 150, 172),
		NightAmbient = Color3.fromRGB(74, 84, 114),
		NightOutdoorAmbient = Color3.fromRGB(88, 102, 138),
		AmbientMix = 0.5,
		ShadowSoftness = 0.7,
		SpecularScale = 0.6,
		Tint = Color3.fromRGB(226, 234, 246),
		Saturation = -0.1,
		Contrast = 0.03,
		Sky = {
			Cover = 0.86,
			Density = 0.6,
			DayColor = Color3.fromRGB(216, 222, 232),
			NightColor = Color3.fromRGB(92, 100, 124),
		},
		-- How long the look takes to come in; and to go when the rain ends,
		-- which is as long as the white clouds and the biome take to fade
		-- (ThickenSeconds + FadeSeconds).
		FadeSeconds = 2.5,
		FadeOutSeconds = 6,
	},
	-- The rain itself (Weather.client): streaks over the camera, following it
	-- everywhere -- a near sheet over Area studs and a sparser far sheet of
	-- bigger drops over FarArea. A phone gets the near sheet at ReducedRate
	-- and no far sheet; Reduced FX gets none.
	Rain = { Rate = 720, ReducedRate = 240, FarRate = 180, Area = 100, FarArea = 220 },
	Toast = {
		Title = "A mysterious biome has emerged through the rain!",
		-- %d is the percentage, from SeedData.Rain.IncomeFactor.
		Detail = "+%d%% plant income while it rains",
	},
	Warning = { Title = "THE RAIN IS PASSING", Detail = "The biome closes in %d s. Make for the bridge." },
	Evacuated = { Title = "BACK AT THE ENTRANCE", Detail = "The rain has stopped and the biome is fading away." },
	Tags = { Terrain = "RainTerrain", Fog = "RainFog", Gate = "RainGate", Site = "RainEncounterSite" },
	--==========================================================================
	-- THE TWO MODES (2026-10-02). The console starts either by its verb; only
	-- one event runs at a time, whichever it is.
	--==========================================================================
	Modes = {
		rain = { Name = "Rain" },
		thunder = { Name = "Thunderstorm" },
	},
	ThunderToast = {
		Title = "A thunderstorm has rolled in! A mysterious biome has emerged!",
		Detail = "+%d%% plant income while it storms",
	},
	--==========================================================================
	-- THE THUNDERSTORM'S LOOK (2026-10-02): heavier rain, thicker white clouds,
	-- a darker overcast and the odd flash of lightning, laid over the Rain's own
	-- (every number not named here is the Rain's). Readable: the darkest it
	-- gets still keeps most of the day's light, and the night barely moves.
	-- Phones keep their reduced sheet; Reduced FX draws no streaks and no flash
	-- (a dim bolt only).
	--==========================================================================
	Thunder = {
		Rain = { Rate = 1100, ReducedRate = 320, FarRate = 320 },
		-- Every cloud bank's transparency times this: thicker banks.
		CloudTransparency = 0.55,
		Light = {
			Brightness = 0.62,
			NightBrightness = 0.93,
			Exposure = -0.3,
			Ambient = Color3.fromRGB(96, 104, 124),
			OutdoorAmbient = Color3.fromRGB(116, 126, 148),
			NightAmbient = Color3.fromRGB(66, 74, 102),
			NightOutdoorAmbient = Color3.fromRGB(80, 92, 124),
			AmbientMix = 0.6,
			Tint = Color3.fromRGB(208, 216, 234),
			Saturation = -0.2,
			Sky = { Cover = 0.96, Density = 0.85, DayColor = Color3.fromRGB(186, 192, 206),
				NightColor = Color3.fromRGB(76, 84, 108) },
		},
		-- The lightning: a flash every Min..Max seconds, the same moments on
		-- every client (drawn from the event's id), Seconds long, at most
		-- Exposure brighter for an instant, with a jagged bolt of BoltParts
		-- segments striking somewhere within Radius studs of the viewer.
		Lightning = { Min = 7, Max = 15, Seconds = 0.32, Exposure = 0.7, Radius = 320, BoltParts = 7,
			Color = Color3.fromRGB(236, 240, 255) },
	},
	--==========================================================================
	-- THE EVENT NEST (2026-10-02): where the supplied pods stand and where the
	-- guardian sleeps. The nest platform was grown to hold them (Biome.Nest.
	-- Radius); nothing is resized. Three Pod 2s, 27 studs across, stand on a
	-- ring of PodRing studs about its centre with room between them; a lone
	-- pod stands at the centre. Stormstrider sleeps in the open ring beside it,
	-- Guard.Distance from the centre at Guard.Bearing degrees (0 = +X, 90 =
	-- +Z, as the biome's own dressing is placed), lying across the way in.
	-- Strike: the one visual bolt a catch makes (ParentAnim): how long it shows,
	-- how far above the catch it starts, how many jagged segments, its colour.
	--==========================================================================
	EventNest = {
		PodRing = 19,
		Guard = { Distance = 70, Bearing = 195 },
		Strike = { Seconds = 0.28, Height = 90, Parts = 6, Color = Color3.fromRGB(236, 240, 255) },
	},
	--==========================================================================
	-- THE SAFE LINE AT THE BRIDGE (2026-10-02): the road's own red line, painted
	-- across the deck where the safe zone ends (MapService.IsInSafeZone: the
	-- field's edge, x = Map.FieldWidth / 2), its outer edge on the boundary
	-- itself. The island side is safe: crossing it banks a carried pod by the
	-- ordinary flow, and a guardian stops at it as at the road's.
	--==========================================================================
	SafeLine = { Text = "SAFE ZONE", TextSize = 60 },
	--==========================================================================
	-- AUDIO (2026-10-02): the cue rows the weather plays (Sfx.Cues has the ids,
	-- levels and ranges). The rain's music is Music.RainTracks.
	--   StormAmbience       RainAmbience's level times this in a Thunderstorm
	--                       (the same loop, a little louder; never a second one)
	--   OpeningSeconds      a Thunderstorm's opening sound plays only for an
	--                       event this client SAW start, at most this long after
	--                       its StartedAt -- never for a late joiner
	--   MaxStrikeSounds     weather strikes sounding at once, at most; the
	--                       oldest is cut if another lands
	--==========================================================================
	Audio = {
		ThunderClap = "ThunderClap",
		StormstriderStrike = "StormstriderStrike",
		RainAmbience = "RainAmbience",
		ThunderstormOpening = "ThunderstormOpening",
		StormAmbience = 1.3,
		OpeningSeconds = 5,
		MaxStrikeSounds = 2,
	},
	--==========================================================================
	-- THE TEMPORARY BIOME: OFF THE ISLAND'S EAST EDGE, SQUARE TO THE ROAD
	--
	-- +X, perpendicular to the -Z road: no part of Starbloom and no sixth
	-- segment. World studs, the ground at Map.GroundY. A bridge rises from the
	-- grass inside the hedge line, crosses the hedges and the gap, and comes down
	-- into a walled corridor that ends in a wider clearing kept empty for the
	-- assets that come later.
	--
	-- CLEARANCE, checked by RainEventSpec against the built map and the plots'
	-- top-level footprints: the nearest plot's wing (Plot 5 at Level 5) reaches
	-- x 206; the obby's entrance stands at z -24 and its course floats at
	-- z <= 10, thirty studs up; the field's hedges run along x 262..268, which
	-- the deck clears at 9 studs. Nothing of the island is moved or rebuilt.
	--==========================================================================
	Biome = {
		FolderName = "SeedRainBiome",
		-- A working label. Not an approved name.
		Label = "Rain Biome",
		-- The event nest's biome id (NestService), which a client turns back into
		-- Label for the Secret egg toast -- never shown itself.
		Id = "rain",
		-- Where evacuees land: a grid on the grass before the ramp, facing the
		-- biome, Spread studs apart -- permanent island ground, never the ramp.
		Landing = { X = 232, Z = 70, Spread = 5, Columns = 7, Rows = 3 },
		-- The bridge: 60 wide, so the road's full width opens off it without a
		-- bottleneck; the landing grid stays west of its foot.
		Ramp = { X0 = 240, X1 = 258, Rise = 9 },
		Deck = { X0 = 258, X1 = 304, Y = 9, Z = 70, Width = 60, Thickness = 1.2 },
		Descent = { X0 = 304, X1 = 330 },
		-- The entrance: a curtain across the top of the ramp, solid while the
		-- biome is opening and closing, gone while it is open.
		Gate = { X = 257, Width = 76, Height = 28 },
		--======================================================================
		-- THE ROUTE (third pass, 2026-10-02): round rooms joined by straight
		-- corridors, from the foot of the descent to the nest. Each entry is a
		-- room (x, z, radius r) and the width w of the corridor leaving it for
		-- the next; the last is the nest clearing. Every corridor is the ROAD'S
		-- OWN USABLE WIDTH -- Map.CorridorWidth, the clear floor between a
		-- biome's walls, 140 studs -- and the route runs north of the obby's
		-- course (its walls stay past z 20). It bends gently, widens at the
		-- pond and the clearing, and is about as long as Greenhollow and
		-- Dustbowl together (Map.SegmentLength twice): RainBiome.RouteLength()
		-- measures it and RainEventSpec holds it. Four sections, named for the
		-- scenery each carries. A room's radius exceeds every corridor's
		-- half-width plus half a wall, so the ring geometry always closes.
		--======================================================================
		-- Four rooms, because a room must be wider than the road and two of
		-- them must not overlap: the mouth, the pond, the passage's hollow and
		-- the clearing, with three long corridors between.
		Route = {
			{ x = 362, z = 104, r = 76, w = GameConfig.Map.CorridorWidth, section = "Entrance" },
			{ x = 540, z = 168, r = 96, w = GameConfig.Map.CorridorWidth, section = "Garden" },
			{ x = 720, z = 146, r = 80, w = GameConfig.Map.CorridorWidth, section = "Passage" },
			{ x = 872, z = 186, r = 110, w = 0, section = "Nest" },
		},
		-- The nest: an empty, visible platform at the clearing's CENTRE with
		-- the EncounterSite marker at its own centre; an open ring of floor
		-- round it for the guardian (ClearRing: distances from the centre,
		-- from beyond the nest's own foliage to the rim's dressing). Nothing
		-- is placed on it here.
		--
		-- GROWN FOR THE SUPPLIED PODS (2026-10-02): the radius was 18, and the
		-- Rain event's Pod 2 is 27 studs across -- three of them stand on a ring
		-- of EventNest.PodRing about the centre, so the platform is twice the
		-- width and its own foliage and the open ring moved out with it. The
		-- pods are never resized to fit; the nest was.
		Nest = { X = 872, Z = 186, Radius = 36, Stones = 30, ClearRing = { Inner = 56, Outer = 94 } },
		-- The road's own wall height.
		WallHeight = 46,
		WallThickness = 6,
		-- A room's ring is panels of at most this length, a pillar at each joint.
		PanelLength = 28,
		RailHeight = 3.2,
		-- How far above or below the ground still counts as on the terrain (the
		-- bridge is 9 up; a fall off it is not on it), and how far outside a
		-- corridor's or a room's wall does.
		Height = { Below = 8, Above = 80 },
		Reach = 2,
		EncounterSiteName = "EncounterSite",
		-- Parts in the event folder, at most. RainEventSpec holds it.
		PartBudget = 1500,
		-- Rain-soaked: deep greens, muted teal foliage, slate, moss, pale blue
		-- flowers and one restrained cyan accent.
		Colours = {
			Floor = Color3.fromRGB(54, 96, 84),
			Room = Color3.fromRGB(48, 88, 78),
			Wall = Color3.fromRGB(78, 92, 108),
			Pillar = Color3.fromRGB(64, 76, 92),
			Deck = Color3.fromRGB(82, 56, 38),
			Rail = Color3.fromRGB(60, 40, 28),
			Gate = Color3.fromRGB(170, 184, 204),
			Fog = Color3.fromRGB(174, 184, 198),
			Leaf = Color3.fromRGB(46, 104, 72),
			LeafDeep = Color3.fromRGB(34, 80, 60),
			Teal = Color3.fromRGB(70, 134, 122),
			TealPale = Color3.fromRGB(112, 166, 154),
			Moss = Color3.fromRGB(96, 142, 84),
			MossPale = Color3.fromRGB(134, 172, 110),
			Root = Color3.fromRGB(62, 46, 38),
			Bark = Color3.fromRGB(78, 58, 44),
			Stone = Color3.fromRGB(92, 104, 118),
			StoneDark = Color3.fromRGB(64, 74, 88),
			Water = Color3.fromRGB(118, 150, 172),
			Wet = Color3.fromRGB(58, 70, 86),
			Flower = Color3.fromRGB(182, 208, 236),
			FlowerDeep = Color3.fromRGB(140, 176, 220),
			Accent = Color3.fromRGB(92, 196, 206),
			Reed = Color3.fromRGB(90, 128, 92),
			NestBed = Color3.fromRGB(74, 118, 82),
			NestBowl = Color3.fromRGB(56, 90, 66),
		},
		-- The scenery's jitter is seeded: every server builds the same biome.
		Scenery = { Seed = 20261003 },
	},
}

-- Display only: the Rain factor in force, as WeatherService publishes it. 1
-- while no rain pays. Never a number of its own: the server's attribute.
function GameConfig.rainIncomeFactor(): number
	local factor = tonumber(workspace:GetAttribute(GameConfig.Weather.Attributes.Factor))
	return if factor and factor > 1 then factor else 1
end

--==============================================================================
-- MINI EVENTS: TICKET DISCO (2026-10-03, the owner's brief; GLOBAL the same day)
--
-- A small admin event for EVERY server of this place, started from the
-- console's MINI EVENTS section (START GLOBAL EVENT / END GLOBAL EVENT) by
-- either allowlisted account (AdminService.IsAdmin, checked on the server).
-- Three modes of ONE event -- only one runs at a time, everywhere, and it is
-- independent of the weather: it never touches a weather timer, the income
-- factor, the biome, pods, guardians or the evacuation, and it does not make
-- Rain or Thunderstorm global.
--
-- ONE SHARED RECORD (Global, below): a DataStore key holds the authoritative
-- event -- a unique id, the mode, a revision, absolute start and end times
-- (workspace:GetServerTimeNow(), the same epoch clock on every server) and
-- the admin who started it -- written by UpdateAsync, so two presses on two
-- servers make one event. MessagingService tells the other servers at once,
-- best-effort; every server also re-reads the record on a timer, so a missed
-- message is caught up and a server that starts mid-event joins it for what
-- is LEFT of it. Each server drops its OWN tickets; nothing per-ticket or
-- per-frame crosses servers. The per-player cap is per GLOBAL event, saved on
-- the player's profile with the spins (EventClaims), so switching servers
-- never resets it.
--
--   ticketdisco   Golden Spinwheel Tickets fall round the hub AND the disco
--   disco         the disco alone: a temporary ball over the hub, soft colour
--   tickets       the ticket shower alone
--
-- MiniEventService owns the event, every ticket, the proximity check and the
-- limits; a client sends nothing (there is no remote for picking up -- the
-- server sees who stands on a landed ticket). Each collected ticket is ONE free
-- EARNED wheel spin through WheelService.GrantEventSpin -- the same saved
-- balance the obby and the community chest fill, shown as the Spin Ticket in
-- the hotbar -- never the obby's daily allowance, never a once-per-profile
-- reward, and never spun automatically. Spins collected stay after the event.
--
-- What every client may read: the attributes, the modes' names and words, the
-- look. Times are workspace:GetServerTimeNow().
--==============================================================================
GameConfig.MiniEvent = {
	-- Workspace attributes (each server writes its own, every client reads).
	-- `State` is "running", or "ending" for the FadeSeconds the effects take to
	-- fade out, and absent while no mini event exists here. EventId is the
	-- GLOBAL event's id (a string); StartedAt and EndsAt are the shared record's
	-- absolute times, the same on every server.
	Attributes = {
		State = "MiniEventState",
		Mode = "MiniEventMode",
		EventId = "MiniEventId",
		StartedAt = "MiniEventStartedAt",
		EndsAt = "MiniEventEndsAt",
		EndingAt = "MiniEventEndingAt",
		-- The per-player limit in force for this event (ticket modes only).
		Cap = "MiniEventCap",
		-- "global" (shared by every server of this place), or "local" (Studio
		-- without the throwaway test store: this server only).
		Scope = "MiniEventScope",
		-- On each PLAYER: how many tickets they collected in the current GLOBAL
		-- event (ticket modes only), read off their own profile (EventClaims),
		-- so a death, a rejoin or another server never resets it.
		PlayerTickets = "MiniEventTickets",
	},
	-- GameEvent actions, server to client.
	Events = {
		-- Once per event per server, AnnounceDelaySeconds in, to everyone here
		-- then -- never to a late joiner or a server that caught up late.
		-- Payload { id, mode }.
		Opened = "MiniEventOpened",
		-- To the collector: { id, count, cap, at } -- `at` is where the ticket lay.
		Collected = "MiniEventTicket",
		-- To a player standing on a ticket who cannot take it: { id, reason,
		-- count, cap } with reason "CAP", "FULL" (spin balance full) or
		-- "UNAVAILABLE" (their profile is not saving). At most once per
		-- NoticeGapSeconds.
		Refused = "MiniEventRefused",
	},
	--==========================================================================
	-- THE MODES, BY THE ID THE SHARED RECORD CARRIES (never renamed: a record
	-- names its mode by this id, and a server reading one must understand it).
	-- What each mode switches on:
	--   Disco        the disco: music, the map's lights, the ball, the
	--                dancers, avatars dancing (the clients read this)
	--   Tickets      ticket rain (MiniEventService drops them)
	--   Mill         the giant Disco Mill, x10 training (TreadmillService)
	--   SpeedFactor  movement speed for EVERYBODY while it runs (CarryService,
	--                the one writer of WalkSpeed; 2026-10-04)
	--
	--   ticketdisco  TICKET DISCO        disco + tickets + mill
	--   disco        DISCO + MILL        disco + mill (shown as "DISCO ONLY" until
	--                                    2026-10-04: the same id and behaviour,
	--                                    a clearer name)
	--   party        DISCO ONLY          disco + x1.5 movement for everyone; no
	--                                    mill, no tickets (new 2026-10-04)
	--   tickets      TICKET SHOWER ONLY  tickets only
	--   podrush      POD RUSH            five minutes to steal and bank as many
	--                                    pods as you can (2026-10-09; PodRush
	--                                    below names it, GameConfig.PodRush
	--                                    runs it)
	--
	-- `Seconds`, where a mode has it, is its own length: the console puts it in
	-- the duration box when the mode is picked.
	--==========================================================================
	Modes = {
		ticketdisco = {
			Name = "TICKET DISCO",
			Tickets = true,
			Disco = true,
			Mill = true,
			-- The notice's picture is its source icon (SourceIcons.tickets or
			-- .disco), not an emoji (2026-10-04).
			Announce = { Title = "TICKET DISCO!", Detail = "Free Spin Tickets are falling all over the map!",
				Icon = "tickets" },
		},
		disco = {
			Name = "DISCO + MILL",
			Tickets = false,
			Disco = true,
			Mill = true,
			Announce = { Title = "DISCO TIME!", Detail = "Hop on the giant Disco Mill for \u{00D7}10 training!",
				Icon = "disco" },
		},
		party = {
			Name = "DISCO ONLY",
			Tickets = false,
			Disco = true,
			Mill = false,
			-- Movement speed only: never treadmill training, never the saved Speed
			-- score (GameConfig.miniEventSpeedFactor, CarryService).
			SpeedFactor = 1.5,
			-- "Up to" (the owner's words, 2026-10-04): MaxWalkSpeed caps the
			-- boosted speed, so a player already above 100 gains less than +50%.
			Announce = { Title = "DISCO PARTY!", Detail = "Up to +50% movement speed for everyone!", Icon = "disco" },
		},
		tickets = {
			Name = "TICKET SHOWER",
			Tickets = true,
			Disco = false,
			Mill = false,
			Announce = { Title = "TICKET SHOWER!", Detail = "Free Spin Tickets are falling all over the map!",
				Icon = "tickets" },
		},
		-- KB/POD-RUSH-PLAN.md, approved 2026-10-09. No disco, tickets or mill:
		-- the rush is PodRushService's (GameConfig.PodRush).
		podrush = {
			Name = "POD RUSH",
			Tickets = false,
			Disco = false,
			Mill = false,
			PodRush = true,
			Seconds = 300,
			Announce = { Title = "POD RUSH!", Detail = "Steal and bank as many pods as you can in 5 minutes!",
				Icon = "podrush" },
		},
	},
	-- The console's duration box starts at this; whole seconds in Min..Max.
	DefaultSeconds = 90,
	MinSeconds = 30,
	MaxSeconds = 300,
	-- The announcement comes this long after the start (one per event).
	AnnounceDelaySeconds = 2,
	-- Manual END and the timer share ONE close: drops stop, unclaimed tickets
	-- go, and the effects fade out over this long before the event is gone.
	FadeSeconds = 3,
	-- The server's tick for drops, expiry and the timer (pickups are checked
	-- every Heartbeat, swept along each body's path since the last one).
	TickSeconds = 0.1,
	Tickets = {
		-- About one every DropSeconds (± DropJitter), while fewer than
		-- MaxUnclaimed lie unclaimed. The owner's budget for tickets all over the
		-- map (2026-10-04; was 12 and 15 s, sized for the hub): 20 at most, 30 s
		-- each. At this drop rate about 15 lie at once per server, so 20 is the
		-- ceiling, not the usual count; DropSeconds is the knob for more.
		DropSeconds = 2,
		DropJitter = 0.3,
		MaxUnclaimed = 20,
		-- From the drop: FallSeconds in the air (not yet collectable), gone
		-- ExpireSeconds after the drop if nobody takes it.
		FallSeconds = 1.3,
		ExpireSeconds = 30,
		-- Collected tickets per player per GLOBAL event (across every server),
		-- each one free earned spin.
		PerPlayerCap = 3,
		-- A body whose root passes within PickupRadius studs (flat distance) of a
		-- landed ticket, no higher than PickupHeight above it, takes it. A move
		-- longer than TeleportStuds in one frame is a teleport, not a sweep.
		PickupRadius = 4,
		PickupHeight = 8,
		TeleportStuds = 40,
		-- Unclaimed tickets keep this far apart, for readability.
		MinSpacing = 5,
		-- A profile remembers its claims for this many global events (newest
		-- kept, oldest dropped): enough for any event still running.
		ClaimsKept = 8,
		-- A refusal (cap, full balance) is said at most this often per player.
		NoticeGapSeconds = 6,
	},
	--==========================================================================
	-- WHERE THEY FALL: the hub's open east side, on the deck (radius 46), clear
	-- of everything people go there for. Polar about the hub's centre: a
	-- radius band, and sectors in degrees measured from +X toward +Z (0 = east,
	-- 90 = the wheel's side, -90 = the road's). A drop is refused within
	-- KeepClear of anything below or of the Bonus Chest, the community chest,
	-- the sacrifice pedestal, the wheel and the obby's entrance (positions read
	-- from their own configs), and on any spot whose ground is not the floor
	-- or where something solid stands.
	--==========================================================================
	Area = {
		Centre = Vector3.new(0, 0, 0),
		-- Outside the event plaza (Map.EventHub, 2026-10-10): 16 until then.
		MinRadius = GameConfig.Map.EventHub.Radius + 4,
		MaxRadius = 41,
		Sectors = { { From = -50, To = 32 } },
		-- Studs past each keep-clear thing's own radius.
		Clearance = 3,
		-- The floor's walking surface lies within this of GroundY.
		FloorTolerance = 2,
	},
	-- Things that are not in another config: Marigold's stall and its two sell
	-- boards, the overflow spawn and the event plaza, from Map's own numbers
	-- since 2026-10-10 (the Event Hub moved the first three); and the invite
	-- pedestal, which no list kept a drop off until then.
	KeepClear = {
		{ Name = "Stall", At = GameConfig.hubStallPoint(0, -2), Radius = 16 },
		{ Name = "SellAll", At = GameConfig.hubStallPoint(-GameConfig.Map.Stall.BoardSide,
			GameConfig.Map.Stall.BoardFront - 2), Radius = 4 },
		{ Name = "SellOne", At = GameConfig.hubStallPoint(GameConfig.Map.Stall.BoardSide,
			GameConfig.Map.Stall.BoardFront - 2), Radius = 4 },
		{ Name = "Spawn", At = Vector3.new(GameConfig.Map.OverflowSpawn.X, 0, GameConfig.Map.OverflowSpawn.Z),
			Radius = 9 },
		{ Name = "EventHub", At = GameConfig.Map.EventHub.Centre, Radius = GameConfig.Map.EventHub.Radius },
		{ Name = "InvitePedestal", At = Vector3.new(GameConfig.InviteRewards.Position.X, 0,
			GameConfig.InviteRewards.Position.Z), Radius = 8 },
	},
	--==========================================================================
	-- ALL OVER THE MAP (2026-10-04, the owner's ask). Each drop first picks a
	-- ZONE, by Weight among the zones open right now, then a spot in it --
	-- Area above stays the hub's own zone, exactly as it was:
	--
	--   Hub     the deck's open east side (Area, KeepClear)
	--   Field   the grass ring between the deck's rim and the plot gates,
	--           every direction, never inside a plot (PlotMargin)
	--   Front   the open ground in front of the hub, from the deck to the
	--           SAFE line (the Disco Mill and anything standing kept clear)
	--   Biomes  each of the five permanent biomes' racing line (HalfWidth of
	--           its centre, where MapDecor puts no tall prop), never within
	--           NestClear of a nest or the Secret pod's spot -- BY DAY only,
	--           while the road is open (GameConfig.isDay)
	--   Rain    the rain biome's own floors, while it is OPEN ("active") and
	--           only then; its tickets go when it starts to close
	--
	-- A zone a player is standing in weighs (1 + PresenceBoost) times as much,
	-- so tickets fall where people are without leaving any zone out. Every spot
	-- is checked against the real map: on the walking floor (FloorAt), nothing
	-- solid there, no prop (anything over a stud tall, collidable or not,
	-- PropMargin away -- MapDecor's props cannot be hit by a query, so the
	-- service measures them once and keeps a grid), clear of every KeepClear,
	-- the Disco Mill, a disco's dancers and every other unclaimed ticket.
	-- The amounts, the cap, the drop rate and the expiry are unchanged.
	--==========================================================================
	Zones = {
		{ Name = "Hub", Kind = "area", Weight = 2 },
		{ Name = "Field", Kind = "ring", Weight = 3, MinRadius = 56, MaxRadius = 98 },
		{ Name = "Front", Kind = "box", Weight = 2, X0 = -62, X1 = 62, Z0 = -160, Z1 = -54 },
		{ Name = "Biomes", Kind = "biomes", Weight = 1, HalfWidth = 20, NearMargin = 14, FarMargin = 10,
			NestClear = 44 },
		{ Name = "Rain", Kind = "rain", Weight = 2, Inset = 0.75 },
	},
	PresenceBoost = 2,
	PlotMargin = 4,
	PropMargin = 1.5,
	--==========================================================================
	-- THE DISCO MILL (2026-10-04, the owner's ask): while a mode with a Mill runs
	-- (Ticket Disco, DISCO + MILL -- never the pure DISCO ONLY or Ticket Shower
	-- Only), one giant shared treadmill stands in front of the hub, west of the
	-- road to the biomes, on open grass clear of the plots, their mills, the
	-- SAFE line and the weather screen. Built by TreadmillService on every server the event reaches
	-- (keyed by the event's id, so a repeated notice never makes a second),
	-- taken down when the event ends.
	--
	-- Several players run on it at once, each on a spot of their own (Spots, in
	-- the belt's frame as fractions of its half size). Each earns their OWN
	-- normal training -- tier, overclock, rebirth and any training boost,
	-- exactly what their own mill pays this second -- times Multiplier,
	-- composed once on the one line that mints Speed. The same 1-second tick,
	-- one AddSpeed. Mounted only: standing on it unmounted earns nothing.
	--
	-- Off by a jump, a death, a reset or leaving, as on any mill. When the
	-- event ends everybody on it is set down on the grass beside it (ExitOut
	-- studs off its road-side edge), walking again; nobody else is moved.
	--==========================================================================
	DiscoMill = {
		Enabled = true,
		Multiplier = 10,
		-- The look: the top tier's (Astral Singularity, rainbow bands), this
		-- much bigger, its deck sunk Sink studs so the belt is a short step up.
		Tier = 10,
		Scale = 2.5,
		Sink = 2.05,
		-- The deck's centre on the ground, and the console facing +Z (the hub):
		-- runners face the hub.
		At = Vector3.new(-40, 0, -95),
		Spots = {
			{ -0.6, -0.5 }, { 0, -0.5 }, { 0.6, -0.5 },
			{ -0.6, 0 }, { 0, 0 }, { 0.6, 0 },
			{ -0.6, 0.5 }, { 0, 0.5 }, { 0.6, 0.5 },
		},
		-- The belt's surface speed (studs/s) while anybody runs on it; idle is
		-- Mill.IdleStuds.
		BeltStuds = 24,
		ExitOut = 5,
		-- Kept clear of tickets and dancers (a circle round its centre).
		KeepClearRadius = 35,
		ModelName = "SeedDiscoMill",
		-- To a player who stepped on it with every spot taken.
		FullAction = "DiscoMillFull",
	},
	-- The non-archivable folder of ticket records (ReplicatedStorage), and the
	-- client's own folder for what it draws (Workspace, never replicated).
	FolderName = "SeedMiniEventTickets",
	FxFolderName = "SeedMiniEventFX",
	--==========================================================================
	-- GLOBAL: WHERE THE SHARED RECORD LIVES AND HOW SERVERS KEEP UP
	--
	-- Live servers: the DataStore `Store`, key `KeyPrefix` .. PlaceId, and the
	-- MessagingService topic `TopicPrefix` .. PlaceId -- this place only, so
	-- no other place or game hears it. STUDIO NEVER USES THESE: with the
	-- throwaway test store switched on (ServerStorage.SeedTestStore) it uses
	-- that throwaway DataStore and a topic named after it; without it, a mini
	-- event in Studio is this server's alone. Nothing a Studio test does can
	-- start a live event or reach a live player's rewards.
	--
	-- Re-read every PollSeconds while an event runs, IdlePollSeconds when none
	-- does (± PollJitter, so servers spread out), with failures backing off to
	-- MaxBackoffSeconds. EndedKept ids of ended events are remembered (in the
	-- record and on each server) so a late START can never bring one back.
	--==========================================================================
	Global = {
		Store = "SeedMiniEvent_v1",
		KeyPrefix = "place_",
		TopicPrefix = "SeedMiniEvent_v1_",
		TestKeyPrefix = "MiniEvent_place_",
		TestTopicSuffix = "_MiniEvent",
		PollSeconds = 15,
		IdlePollSeconds = 45,
		PollJitter = 0.2,
		MaxBackoffSeconds = 300,
		EndedKept = 6,
		-- A server that learns of an event this long after its announcement was
		-- due (a new server, a late read) joins silently: no announcement.
		AnnounceGraceSeconds = 8,
	},
	--==========================================================================
	-- THE LOOK (MiniEventFX.client builds it locally on every client; the
	-- light is WorldClock's, the music Music.client's)
	--==========================================================================
	Ticket = {
		-- The golden ticket (ItemArt's Spin Ticket, at this scale), hovering
		-- over a soft gold ring once it lands.
		Scale = 0.75,
		Hover = 2.4,
		FallHeight = 34,
		SpinDegreesPerSecond = 70,
		Ring = { Diameter = 4.4, Colour = Color3.fromRGB(255, 214, 92), Transparency = 0.35 },
		-- Faded for a player who already has their PerPlayerCap.
		CappedTransparency = 0.6,
		-- The last seconds before it expires, it fades.
		FadeOutSeconds = 2,
	},
	Disco = {
		-- The ball, over the hub's centre.
		BallAt = Vector3.new(0, 30, 0),
		BallDiameter = 6,
		BallSpinDegreesPerSecond = 18,
		-- Soft beams from the ball to the deck, sweeping slowly round it.
		-- Desktop count, and a phone's.
		Beams = 6,
		PhoneBeams = 3,
		BeamTransparency = 0.78,
		BeamReach = 30,
		BeamSweepDegreesPerSecond = 10,
		-- Restrained sparkles round the ball (none on reduced motion; a
		-- phone's rate is PhoneSparkleRate).
		SparkleRate = 6,
		PhoneSparkleRate = 2,
		-- One full turn of the colour wheel takes this long: gentle, never a
		-- flash.
		HueSeconds = 16,
		Saturation = 0.55,
		-- Laid over the light by WorldClock (Lighting's one owner): a fraction
		-- of the brightness kept, a little exposure off, and a soft tint drifting
		-- through the colour wheel -- the map stays readable. Comes in and goes
		-- over FadeSeconds.
		Light = {
			Brightness = 0.82,
			Exposure = -0.12,
			TintMix = 0.14,
			-- MAP-WIDE (2026-10-03): the ambient light everywhere is moved this
			-- far toward the palette's colour (scaled by AmbientValue, so it
			-- tints without darkening or washing out) -- the cheap, light-free
			-- part of the disco every player gets, Reduced FX included.
			AmbientMix = 0.3,
			AmbientValue = 0.78,
			FadeSeconds = 3,
		},
		--======================================================================
		-- THE PALETTE (2026-10-03): the disco's colours, in the order the light
		-- moves through them, blended smoothly -- a whole turn in CycleSeconds,
		-- so a colour holds for seconds and never flashes. Every disco light
		-- uses it: WorldClock's tint and ambient, the ball, the beams and the
		-- map's pools and spots (DiscoLights.colourAt).
		--======================================================================
		Palette = {
			Color3.fromRGB(150, 84, 255), -- purple
			Color3.fromRGB(255, 92, 196), -- pink
			Color3.fromRGB(255, 192, 74), -- warm gold
			Color3.fromRGB(86, 232, 140), -- green
			Color3.fromRGB(70, 222, 255), -- cyan
			Color3.fromRGB(76, 122, 255), -- blue
		},
		CycleSeconds = 30,
		--======================================================================
		-- THE MAP'S LIGHTS (2026-10-03, DiscoLights): pools of coloured light and
		-- slow spotlights at STATIONS laid out from the map itself -- a ring
		-- round the hub, the field, the road, every player plot, every
		-- permanent biome's segment (BiomeData.SegmentBounds) and the rain
		-- biome's floors while it stands. Only the nearest stations within
		-- ActivationRadius of the player are lit, at most Budget[quality] of
		-- each kind (Full / Reduced; Reduced FX lights none), every light with
		-- shadows off. Reassigned every ReassignSeconds, faded in and out over
		-- SwapSeconds so nothing pops.
		--======================================================================
		Map = {
			ActivationRadius = 230,
			ReassignSeconds = 0.5,
			SwapSeconds = 0.8,
			Budget = {
				Full = { Pools = 10, Spots = 3 },
				Reduced = { Pools = 5, Spots = 1 },
			},
			-- The hub keeps its ball; these pools ring the deck round it.
			HubPools = 4,
			HubRadiusFraction = 0.72,
			-- A ring between the deck and the plots, clear of the road's gap.
			FieldPools = 6,
			FieldRadius = 74,
			-- Down the road to the corridor's mouth, alternating sides.
			RoadSpacing = 55,
			RoadOffset = 18,
			-- Per biome segment: pools at these fractions of its length,
			-- alternating sides at SideFraction of the corridor's half width;
			-- spots on the centreline at SpotAt.
			PoolsAt = { 1 / 6, 1 / 2, 5 / 6 },
			SpotsAt = { 1 / 3, 2 / 3 },
			SideFraction = 0.5,
			-- The rain biome: a pool on every room floor and every RainSpacing
			-- studs along each corridor floor, a spot on every room.
			RainSpacing = 70,
			Pool = { Height = 7, Range = 30, Brightness = 2.2 },
			Spot = {
				Height = 26,
				Range = 48,
				Angle = 46,
				Brightness = 3,
				-- The cone leans this far off vertical and turns round at a
				-- walking pace: a lit patch circling slowly on the floor.
				TiltDegrees = 18,
				SweepDegreesPerSecond = 14,
				-- A faint shaft of light down the cone (none on reduced motion).
				BeamTransparency = 0.86,
			},
		},
	},
	--==========================================================================
	-- DISCO DANCING (DiscoDance.client): while a disco mode runs, each player's
	-- own avatar dances in the hub area -- Roblox's own R15/R6 dance animations,
	-- the variant and the beat taken from the event's shared start time, so the
	-- hub dances together on every server. It stops at once for anything more
	-- important: carrying a pod or a plant, holding any Tool (a bat, the trap, the
	-- Spin Ticket), walking, jumping, falling, sitting or being thrown. Saved
	-- opt-out in Settings (DISCO DANCING), the GameEvent verb `Action`; reduced
	-- motion (Reduced FX or Roblox's own) never dances.
	--==========================================================================
	Dance = {
		Action = "DiscoDance",
		-- Only within this many studs of the hub's centre (flat).
		Radius = 70,
		-- Standing still this long before it starts again after a move.
		SettleSeconds = 0.6,
		-- Each variant plays this long before the next, all in step.
		VariantSeconds = 16,
		FadeSeconds = 0.3,
		R15 = { "rbxassetid://507771019", "rbxassetid://507776043", "rbxassetid://507777268" },
		R6 = { "rbxassetid://182435998", "rbxassetid://182491037", "rbxassetid://182491065" },
	},
	--==========================================================================
	-- THE DANCERS (DiscoDancers.client, 2026-10-03): while Ticket Disco or Disco
	-- Only runs, about Count of the owner's eight dancers (DancerForms) stand
	-- round the hub dancing (DancerMoves), all on the event's beat. COSMETIC and
	-- LOCAL: each client builds its own anchored, non-colliding, untouchable,
	-- unqueryable copies; nothing is sent anywhere and nothing is collected.
	--
	-- THE SAME ON EVERY SCREEN. The picks -- which dancer, where, facing which
	-- way, at what size -- come from a Random seeded by the event's id and from
	-- this table alone, never from what a client happens to have streamed in,
	-- so a server's players all see the same troupe (a phone draws the first
	-- PhoneCount of the same list). Only the height of the ground under each
	-- spot is read locally (a ray, GroundY if it misses).
	--
	-- WHERE: polar about the hub's centre, degrees from +X toward +Z (0 = east,
	-- 90 = the wheel's side, -90 = the road's), as Area above. The DECK zone is
	-- the deck's quiet west and south-west arcs and a sliver past the ticket
	-- band (never the ticket band itself); the FIELD zone is the grass ring
	-- between the deck's rim (48.5) and the plot gates (Map.PlotRingInner 100),
	-- leaving the road's arc empty. A dancer's whole footprint must clear every
	-- KeepClear circle and every Corridor (the road, each plot's walk from the
	-- hub to its gate, and the way east to the obby), and stand Gap studs from
	-- every other dancer. Sizes are uniform: the whole model and rig at one
	-- factor, ScaleMin to ScaleMax of its authored size.
	--==========================================================================
	Dancers = {
		Count = 18,
		PhoneCount = 10,
		ScaleMin = 0.7,
		ScaleMax = 1.3,
		Gap = 2.5,
		Attempts = 900,
		-- Each faces the hub's centre, turned by up to this many degrees.
		FacingJitterDegrees = 75,
		Zones = {
			{
				Name = "Deck", Weight = 0.25, MinRadius = 27, MaxRadius = 43, GroundY = 0.85,
				Sectors = { { From = 128, To = 176 }, { From = 220, To = 242 }, { From = 36, To = 50 } },
			},
			{
				Name = "Field", Weight = 0.75, MinRadius = 56, MaxRadius = 86, GroundY = 0,
				Sectors = { { From = -52, To = 232 } },
			},
		},
		KeepClear = {
			-- The overflow spawn, the event plaza and Marigold's stall with its
			-- boards, from Map's own numbers (the Event Hub, 2026-10-10); the
			-- invite pedestal, kept clear since the same day.
			{ Name = "Spawn", At = Vector3.new(GameConfig.Map.OverflowSpawn.X, 0, GameConfig.Map.OverflowSpawn.Z),
				Radius = 14 },
			{ Name = "EventHub", At = GameConfig.Map.EventHub.Centre, Radius = GameConfig.Map.EventHub.Radius },
			{ Name = "Stall", At = GameConfig.hubStallPoint(0, -2), Radius = 22 },
			{ Name = "InvitePedestal", At = Vector3.new(GameConfig.InviteRewards.Position.X, 0,
				GameConfig.InviteRewards.Position.Z), Radius = 8 },
			-- The shop row's fixtures (2026-10-10, Map.Stall's comment), out of
			-- every dancer's zone now but kept here all the same: the wheel's,
			-- the bonus chest's and the shrine's spots are written out (their
			-- configs come later in this file; EventHubSpec and RebirthSpec hold
			-- them equal).
			{ Name = "Wheel", At = Vector3.new(-178.5, 0, -157), Radius = 9 },
			{ Name = "BonusChest", At = Vector3.new(-193, 0, -127), Radius = 8 },
			{ Name = "CommunityChest", At = Vector3.new(GameConfig.Community.Position.X, 0, GameConfig.Community.Position.Z),
				Radius = 8 },
			{ Name = "Pedestal", At = Vector3.new(GameConfig.Sacrifice.Position.X, 0, GameConfig.Sacrifice.Position.Z),
				Radius = 8 },
			{ Name = "RebirthShrine", At = Vector3.new(-230, 0, -157), Radius = 8 },
			-- The Disco Mill (DiscoMill above), while it stands and while not.
			{ Name = "DiscoMill", At = Vector3.new(-40, 0, -95), Radius = 35 },
			-- The deck's rim step: nobody stands half on it.
			{ Name = "RimInside", At = Vector3.new(0, 0, 0), Radius = 0, Ring = { 44.5, 53 } },
		},
		Corridors = {
			{ Name = "Road", From = Vector3.new(0, 0, -40), To = Vector3.new(0, 0, -200), HalfWidth = 40 },
			{ Name = "Plot_05", From = Vector3.new(0, 0, 0), To = Vector3.new(96.5, 0, 26.4), HalfWidth = 12 },
			{ Name = "Plot_04", From = Vector3.new(0, 0, 0), To = Vector3.new(41.6, 0, 90.9), HalfWidth = 12 },
			{ Name = "Plot_03", From = Vector3.new(0, 0, 0), To = Vector3.new(-41.6, 0, 90.9), HalfWidth = 12 },
			{ Name = "Plot_02", From = Vector3.new(0, 0, 0), To = Vector3.new(-96.5, 0, 26.4), HalfWidth = 12 },
			{ Name = "Plot_01", From = Vector3.new(0, 0, 0), To = Vector3.new(-82.7, 0, -56.2), HalfWidth = 12 },
			{ Name = "Plot_06", From = Vector3.new(0, 0, 0), To = Vector3.new(82.7, 0, -56.2), HalfWidth = 12 },
			{ Name = "Obby", From = Vector3.new(0, 0, 0), To = Vector3.new(246, 0, -24), HalfWidth = 14 },
		},
		-- Faded in from the event's start (a late joiner sees them at once) and
		-- out over the event's own FadeSeconds as it ends.
		FadeInSeconds = 1.5,
		-- Danced every frame within NearStuds of the camera, every other frame
		-- out to FarStuds, every fourth beyond.
		NearStuds = 120,
		FarStuds = 260,
		FolderName = "SeedDiscoDancers",
	},
	-- The short notices (Notice.post). The status line that said "Tickets: 2/3
	-- · 0:42" / "Disco · 0:42" is gone (2026-10-04): the event's icons over the
	-- hotbar say it (GameConfig.BoostIcons), and each ticket taken shows the
	-- "+1" pop over the collector instead of a notice. The limit is said ONCE
	-- per event (Capped on the last one taken, or AtCap if that was missed).
	Notices = {
		Capped = { Title = "ALL %d TICKETS COLLECTED!", Detail = "Your free spins are in the hotbar · spin them at the Wheel" },
		AtCap = { Title = "TICKET LIMIT REACHED", Detail = "%d/%d this event · leave the rest for others" },
		Full = { Title = "SPIN TICKETS FULL", Detail = "Spin some at the Wheel to collect more" },
		Unavailable = { Title = "TICKET NOT SAVED", Detail = "Your progress isn't saving right now · try again soon" },
		MillFull = { Title = "DISCO MILL FULL", Detail = "Every spot is taken · try again in a moment" },
	},
	--==========================================================================
	-- "+1 [ticket]" OVER THE COLLECTOR (2026-10-04, the owner's ask): drawn by
	-- MiniEventUI on the collector's own screen when the server CONFIRMS a
	-- ticket (the Collected event, sent only after the grant saved) -- never on
	-- a prediction, a refusal, a rejoin or the count arriving -- and once per
	-- ticket (event id + count). It rises Rise studs and fades over Seconds;
	-- with reduced motion it only fades. Cosmetic: it grants nothing.
	--==========================================================================
	Pop = { Text = "+1", Seconds = 1.4, Rise = 3, Above = 3.2, Width = 120, Height = 50 },
}

--==============================================================================
-- POD RUSH (2026-10-09; KB/POD-RUSH-PLAN.md. The owner: "approve, let terminal
-- work", every recommendation taken)
--
-- The fifth global mini event (MiniEvent.Modes.podrush): started from the
-- admin console like the other four, on every server at once. While it runs:
--   * every nest grows a taken pod back RegrowSeconds later -- normal pods,
--     normal odds and sizes -- and a golden ring of light lies under each nest;
--   * guardians chase as usual but build no rage past the theft itself
--     (NestService);
--   * dusk waits until the rush and its grace are over, and DuskMarginSeconds
--     more (WorldCycleService reads Attributes.Until);
--   * a pod TAKEN FROM A NEST during the rush and banked by the same player
--     counts one. A pod still in the arms when it ends has GraceSeconds to be
--     banked; one picked back up after a drop never counts.
-- Three levels by the count, each paid once per player per rush the moment it
-- is reached. The count, the levels paid and the highest biome banked from
-- are saved on the profile under the event's id (PodRush), so a rejoin -- on
-- any server -- keeps them. Every pod banked is the player's as always: the
-- levels are on top. PodRushService runs it, PodRushUI draws it, and
-- Shared/PodRush is the pure part both share.
--==============================================================================
GameConfig.PodRush = {
	-- The mini event mode that is a rush.
	Mode = "podrush",
	RegrowSeconds = 15,
	GraceSeconds = 20,
	DuskMarginSeconds = 10,
	--==========================================================================
	-- THE THREE LEVELS (the owner's defaults: 3 / 7 / 12)
	--
	-- Spins land on the earned balance (WheelService.GrantMilestoneSpins); any
	-- that do not fit are owed and paid when there is room (MilestoneSpinsOwed).
	-- Boost is the Bonus Chest's own (BonusChestService.GrantBoost: its one
	-- slot, BonusChest.BoostSeconds at its multiplier). PodTier is the Titan pod
	-- (SeedData tier 6) of the highest biome the player banked from during the
	-- rush (CarryService.GivePod), kept owed (PodRush.PodOwed) while the Bag is
	-- full and given as soon as there is room.
	--==========================================================================
	Levels = {
		{ Id = "bronze", Name = "BRONZE", Pods = 3, Spins = 1 },
		{ Id = "silver", Name = "SILVER", Pods = 7, Spins = 3, Boost = "training" },
		{ Id = "gold", Name = "GOLD", Pods = 12, Spins = 5, PodTier = 6 },
	},
	-- GOLD pods still owed are kept as a list, oldest first, at most this many
	-- (PodRush.owedList): a second won while the first waits is never lost.
	MaxOwed = 8,
	-- The owner's art (uploaded and checked 2026-10-09: Image, CrazyCozy Games
	-- 744756221, IsLoaded, 512 x 512, corner alpha 0), one shared crop.
	Art = {
		Icon = "rbxassetid://108173602941410",
		Bronze = "rbxassetid://106320803448209",
		Silver = "rbxassetid://108448116105933",
		Gold = "rbxassetid://100048210150003",
		CropOffset = Vector2.new(41, 41),
		CropSize = Vector2.new(430, 430),
	},
	Attributes = {
		-- On the Workspace (each server's own): the server time until which the
		-- rush, its grace included, holds dusk. Absent while no rush is on.
		Until = "PodRushUntil",
		-- On each player: the rush their numbers are for, the count, the level
		-- reached (0 none, 1 bronze, 2 silver, 3 gold), and whether the pod in
		-- their arms would count if banked now.
		Id = "PodRushId",
		Count = "PodRushCount",
		Level = "PodRushLevel",
		Carrying = "PodRushCarrying",
	},
	-- GameEvent actions, server to client.
	Events = {
		-- A pod counted: { id, count, level, levelUp? }. levelUp is the level
		-- just reached and what it paid: { level, spins, boost, pod }.
		Counted = "PodRushCounted",
		-- This player's rush is over: { id, count, level, spins, boost, pod,
		-- podOwed }.
		Over = "PodRushOver",
	},
	Words = {
		Title = "POD RUSH",
		Banked = "%d banked",
		ToNext = "%d more for %s",
		Top = "GOLD! Keep banking",
		BankIt = "BANK IT!",
		Plus = "+1",
		LevelUp = "%s!",
		Spins = "+%d Spin Ticket%s",
		Boost = "+%d%% training for %d min",
		Pod = "a Titan %s pod",
		PodOwed = "Make room in your Bag for your Titan pod",
		PodGiven = "Your Titan %s pod is in your Bag",
		Over = "POD RUSH OVER",
		OverCount = "%d pod%s",
		NoLevel = "no level",
		ServerLine = "%s hit GOLD in the Pod Rush!",
		Close = "TAP TO CLOSE",
	},
	-- The tracker (PodRushUI): its logical size, the scale a phone draws it at
	-- (touch, short side under 500), and its gap to the HUD. Where no spot is
	-- clear for it -- a short phone with boost icons up has a band 20 px tall
	-- over the toast -- it is a one-line STRIP of StripWidth x StripHeight
	-- (drawn 1:1, so its words stay readable), the bar left out; and where not
	-- even that fits (the beginner's guide card up as well), the MINI strip,
	-- MiniWidth: the time and the pods banked.
	Tracker = { Width = 300, Height = 86, PhoneScale = 0.78, Gap = 8, StripWidth = 240, MiniWidth = 150,
		StripHeight = 24,
		-- BANK IT! is said in this red; the time otherwise in the ring's gold.
		BankItColour = Color3.fromRGB(255, 104, 86) },
	-- The end card, centred: its logical size (scaled down to fit inside the
	-- safe area less Margin a side), and how long it stays.
	EndCard = { Width = 340, Height = 214, Seconds = 8, Margin = 16 },
	-- The "+1" and the level's pop by the tracker (none with REDUCED FX).
	Pop = { Seconds = 1.2, Rise = 26, LevelSeconds = 1.8 },
	-- The ring under each nest: on the pods' own ring (NestService's 16),
	-- Segments flat Neon bars, breathing between Transparency and PulseTo
	-- (still with REDUCED FX).
	Ring = { Radius = 16, Width = 3, Segments = 36, Thickness = 0.2, Colour = Color3.fromRGB(255, 204, 64),
		Transparency = 0.2, PulseSeconds = 1.6, PulseTo = 0.55 },
}

-- What a carried weight does to your WalkSpeed, as a multiplier.
function GameConfig.carryMultiplierFor(tier: number): number
	local C = GameConfig.Carry
	if type(tier) ~= "number" or tier ~= tier or tier <= 0 then
		return 1
	end
	local t = math.clamp(tier / C.TopTierValue, 0, 1) ^ C.Exponent
	return 1 - (1 - C.MinMultiplier) * t
end

--==============================================================================
-- THE SCORE BECOMES A SPEED
--
-- Reads GameConfig.Speed.Anchors and interpolates between the two rows that
-- bracket the score. Nothing here decides what anything is worth -- the table
-- does, and this only walks it.
--
-- EVERY BAD INPUT LANDS ON BASE OR ON CAP, and neither is an error. A profile
-- that failed to load reads nil, a corrupted save can read a string, and NaN
-- propagates silently out of any arithmetic upstream. A game where a bad number
-- freezes the player in place is worse than one where they walk at 16.
--
--     nil / string / NaN / negative / 0   ->  BaseWalkSpeed
--     anything at or past the last anchor ->  MaxWalkSpeed  (math.huge included)
--==============================================================================
function GameConfig.walkSpeedFor(speedScore: number): number
	local S = GameConfig.Speed
	local anchors = S.Anchors
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return S.BaseWalkSpeed
	end
	local last = anchors[#anchors]
	if speedScore >= last[1] then
		-- math.huge included, deliberately: the comparison is true for it and
		-- the cap is the honest answer.
		return S.MaxWalkSpeed
	end
	for i = 1, #anchors - 1 do
		local lo = anchors[i]
		local hi = anchors[i + 1]
		if speedScore < hi[1] then
			--==================================================================
			-- log(x + 1), NOT log(x)
			--
			-- The first anchor is zero and log(0) is -inf, which would make the
			-- entire first span NaN -- the one span every new player is in. The
			-- +1 costs nothing at the scales that matter (it is a 0.04%
			-- distortion at the 1,000 anchor and vanishes above it) and removes
			-- the special case entirely.
			--==================================================================
			local a = math.log(lo[1] + 1)
			local b = math.log(hi[1] + 1)
			local t = if b > a then (math.log(speedScore + 1) - a) / (b - a) else 0
			return lo[2] + (hi[2] - lo[2]) * math.clamp(t, 0, 1)
		end
	end
	return S.MaxWalkSpeed
end

--==============================================================================
-- THE TABLE IS CHECKED ON LOAD, NOT TRUSTED
--
-- A row typed out of order, a duplicated score, or a walk speed that dips is a
-- game where being faster makes you slower at exactly one point on the ladder --
-- which nobody would ever reproduce on purpose and which the curve above would
-- happily serve. Cheap to assert once at require time; impossible to notice
-- otherwise.
--==============================================================================
do
	local anchors = GameConfig.Speed.Anchors
	assert(#anchors >= 2, "GameConfig.Speed.Anchors needs at least two rows")
	assert(anchors[1][1] == 0, "the first Speed anchor must be score 0")
	assert(anchors[1][2] == GameConfig.Speed.BaseWalkSpeed,
		"the first Speed anchor must equal BaseWalkSpeed")
	assert(anchors[#anchors][2] == GameConfig.Speed.MaxWalkSpeed,
		"the last Speed anchor must equal MaxWalkSpeed")
	for i = 2, #anchors do
		assert(anchors[i][1] > anchors[i - 1][1],
			string.format("Speed anchor %d is not above the one before it", i))
		assert(anchors[i][2] > anchors[i - 1][2],
			string.format("Speed anchor %d walks slower than the one before it", i))
	end
end

--==============================================================================
-- IS IT DAY
--
-- Here rather than in the cycle service, and read straight off the attribute,
-- because CarryService and BiomeGateService both need the answer and both run
-- BEFORE the service that sets it. Requiring it from them would be a cycle:
-- WorldCycleService already requires both of them.
--
-- UNSET MEANS DAY. A server whose cycle service failed to start, or one in the
-- moments before Init, is a server where the game works -- not one where every
-- pod is unreachable and nobody can find out why.
--==============================================================================
function GameConfig.isDay(): boolean
	local phase = workspace:GetAttribute(GameConfig.Attributes.WorldPhase)
	return phase ~= GameConfig.WorldCycle.PhaseNight
end

--==============================================================================
-- THE MINI EVENT'S MOVEMENT FACTOR, FOR EVERYBODY HERE, RIGHT NOW (2026-10-04)
--
-- A mode's SpeedFactor (DISCO ONLY's 1.5) while the global mini event RUNS on
-- this server -- the state MiniEventService publishes from the shared record,
-- so every server the event reaches answers the same, a late joiner included --
-- and exactly 1 otherwise: no event, another mode, or the event ENDING (its
-- fade) or gone. Read fresh on every recompute and never stored, so a repeated
-- START, a respawn or a re-read can never stack it, and an ending takes it
-- away by the next recompute. CarryService.RefreshWalkSpeed is the one place
-- it is applied; it is movement only, never training or the saved Speed score.
--==============================================================================
function GameConfig.miniEventSpeedFactor(): number
	local M = GameConfig.MiniEvent
	if workspace:GetAttribute(M.Attributes.State) ~= "running" then
		return 1
	end
	local modes: { [string]: any } = M.Modes :: any
	local id = workspace:GetAttribute(M.Attributes.Mode)
	local mode = if type(id) == "string" then modes[id] else nil
	local factor = if mode then tonumber(mode.SpeedFactor) else nil
	if not factor or factor ~= factor or factor <= 0 then
		return 1
	end
	return factor
end

--==============================================================================
-- REBIRTH (2026-10-08, the owner: "rebirth first, cash and mill tier reset,
-- plan it" / "we should also do a fence upgrade every rebirth and a title
-- above the name" / "use your defaults")
--
-- A rebirth SPENDS all the player's cash -- the price is what it must reach --
-- and puts their mill back to Compost Walk, for a PERMANENT bonus that adds up
-- with every rebirth: +50% training and +25% garden income (offline earnings
-- included, like the x2 pass). Everything else in the save is kept: Speed, the
-- plot's level, every plant (garden and Bag), pods, weapons, spin tickets, the
-- Speed milestones, the Index, passes and running boosts. Shared/Rebirth is
-- the pure rulebook (prices, the requirement, titles, fence tiers, what blocks
-- one); RebirthService is the only thing that does one.
--
-- THE PRICE: rebirth 1 needs $1B, then x4 each time ($4B, $16B, $64B...) --
-- until that would pass PriceCap. The save holds at most $1Qa (Save.MaxCash),
-- so x4 alone would make rebirth 11 ($1.05Qa) unpayable and every title past
-- 10 unreachable; past the cap every rebirth costs the cap. And the mill must
-- be at least MinMillTier first (Inferno Forge, itself $1B).
--==============================================================================
GameConfig.Rebirth = {
	Enabled = true,
	-- The GameEvent action; the verbs are "confirm" (client) and "quote",
	-- "done", "refused" (server).
	Action = "Rebirth",
	BasePrice = 1e9,
	PriceFactor = 4,
	PriceCap = 5e14,
	MinMillTier = 8,
	TrainingPer = 0.5,
	IncomePer = 0.25,
	-- After a rebirth, this long before another is considered at all: a double
	-- press, a lagging client and a replayed packet all land inside it.
	CooldownSeconds = 10,
	-- How long the shrine's quote (the panel's numbers) stays good to confirm.
	QuoteSeconds = 120,
	-- Published on the player for every client: the panel, the displays' income.
	Attributes = { Rebirths = "Rebirths" },
	--==========================================================================
	-- THE SHRINE, in the shop row along the red line between the invite and
	-- sacrifice pedestals (2026-10-10, Map.Stall's comment), facing north into
	-- the field: FacingDegrees turns its front (the CFrame's -Z, its look)
	-- about +Y as every fixture's, 180 to +Z. Its prompt shares ground with no
	-- other (EventHubSpec). It stood just off the deck's north-east rim from
	-- 2026-10-08, facing the square.
	--==========================================================================
	FolderName = "SeedRebirthShrine",
	Position = Vector3.new(-230, 0, -157),
	FacingDegrees = 180,
	PromptDistance = 10,
	PromptHoldSeconds = 0.5,
	-- The panel shuts when the player walks further than this from the shrine.
	CloseDistance = 24,
	-- The kit's Rebirth band (MenuKit.studdedTheme).
	Look = { Band = Color3.fromRGB(255, 53, 93), Edge = Color3.fromRGB(120, 19, 41) },
	-- The words over it (FloatingSign), in a colour no other sign in the square
	-- wears; Above is their middle over the shrine's ground.
	FloatingWords = {
		Text = "REBIRTH",
		SubText = "+50% TRAINING · +25% INCOME",
		Colour = Color3.fromRGB(255, 80, 200), -- magenta #FF50C8
		-- HALF AGAIN AS BIG since 2026-10-10 (Michael on v1047; the owner
		-- approved): 11 x (2.4 + 1.1) at 10.5 until then. Nothing stands over the
		-- shrine; its foot (9.7) stays over the seed's glow and the prompt.
		Width = 16.5,
		Height = 3.6,
		SubHeight = 1.65,
		Above = 12.3,
	},
	--==========================================================================
	-- THE TITLE OVER A REBORN PLAYER'S NAME: built on the Head by RebirthService
	-- like OwnerTitleService's ADMIN, back on every respawn, one per character.
	-- With ADMIN both show, ADMIN on top. The highest step reached; the last
	-- one turns like ADMIN's rainbow (still for reduced motion: OwnerTitleUI).
	--==========================================================================
	Title = {
		Name = "SeedRebirthTitle",
		Tag = "SeedRebirthTitle",
		-- SMALLER (2026-10-09, the owner: "make the title smaller, it looks huge
		-- specially on phones"; it was 320 x 46, the words at 28 and REBIRTH N
		-- at 14). 228 wide: at 20 the widest of the 100 titles, ELDERWOOD
		-- WARDEN III, is 206 px and its outline 6 more; 156 + 6 of a phone's 171
		-- at 15 (RebirthSpec measures every one). The box is invisible; only the
		-- words show.
		Size = Vector2.new(228, 34),
		Rise = 2.4,
		Lift = 0.9,
		TextSize = 20,
		SubTextSize = 12,
		-- ON A PHONE, THREE QUARTERS AGAIN (the prompts' rule): a touch screen
		-- whose shorter side is under PhoneShortSide draws the title at
		-- PhoneScale -- 171 x 26, the words at 15 -- each viewer for their own
		-- screen (OwnerTitleUI, GameConfig.rebirthTitleLook). REBIRTH N never
		-- under SubMinTextSize.
		PhoneScale = 0.75,
		PhoneShortSide = 500,
		SubMinTextSize = 10,
		MaxDistance = 100,
		Sub = "REBIRTH %d",
		-- ROMAN NUMERALS (2026-10-08, the owner: "Add roman numerals so that
		-- players wont think it's repepitive"): a step that lasts more than one
		-- rebirth counts through it from I -- BOTANIST I at 5 to III at 7. A step
		-- of one rebirth (SPROUT to GREEN THUMB) has none: a lone I would promise
		-- a II that never comes. The TITLES list names each step's range (Span). A
		-- plain hyphen: these fonts' dashes are unchecked (memory: the tofu list).
		Numbered = "%s %s",
		Span = "%s %s-%s",
		--======================================================================
		-- THE 100 TITLES (2026-10-10, the owner: "approve the rebirth titles, let
		-- terminal do it"). The design: output/design/rebirth-titles-fx-v1 (the
		-- owner's Cursor session) -- its names, ranges and colours as drawn, the
		-- fifteen founder colours kept. Each step lasts until the next one's At:
		-- SPROUT to GREEN THUMB one rebirth each, the five landmarks five (I-V:
		-- GROVE KEEPER at 20, ELDER ROOT at 67, WORLD TREE at 144, EVERBLOOM at
		-- 221, GAIA at 298), every other step three (I-III). The top step's Ranks
		-- ends its numerals: GAIA V from 302 on, REBIRTH N under it still
		-- counting. Family: its family in Families. The rainbow is GAIA's alone.
		-- No migration: rebirth was never published (v1038 predates it).
		--======================================================================
		Ladder = {
			{ At = 1, Text = "SPROUT", Colour = Color3.fromRGB(150, 235, 100), Family = "seedlight" },
			{ At = 2, Text = "SEEDLING", Colour = Color3.fromRGB(60, 205, 115), Family = "seedlight" },
			{ At = 3, Text = "GARDENER", Colour = Color3.fromRGB(255, 190, 70), Family = "seedlight" },
			{ At = 4, Text = "GREEN THUMB", Colour = Color3.fromRGB(170, 255, 60), Family = "seedlight" },
			{ At = 5, Text = "BOTANIST", Colour = Color3.fromRGB(90, 200, 255), Family = "seedlight" },
			{ At = 8, Text = "LEAF TENDER", Colour = Color3.fromRGB(60, 205, 115), Family = "seedlight" },
			{ At = 11, Text = "HERBALIST", Colour = Color3.fromRGB(40, 215, 190), Family = "seedlight" },
			{ At = 14, Text = "SEED WARDEN", Colour = Color3.fromRGB(60, 205, 115), Family = "seedlight" },
			{ At = 17, Text = "GARDEN KEEPER", Colour = Color3.fromRGB(60, 205, 115), Family = "seedlight" },
			{ At = 20, Text = "GROVE KEEPER", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 25, Text = "GROVE SCOUT", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 28, Text = "GROVE GUARD", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 31, Text = "PETAL GUARDIAN", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 34, Text = "BLOOM SENTINEL", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 37, Text = "BLOOM WARDEN", Colour = Color3.fromRGB(255, 120, 200), Family = "petal" },
			{ At = 40, Text = "BLOOM KNIGHT", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 43, Text = "BLOOM CHAMPION", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 46, Text = "GROVE COMMANDER", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 49, Text = "GROVE MASTER", Colour = Color3.fromRGB(190, 125, 255), Family = "petal" },
			{ At = 52, Text = "THORN KNIGHT", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 55, Text = "THORN SENTINEL", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 58, Text = "THORN CAPTAIN", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 61, Text = "THORN CHAMPION", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 64, Text = "ROOT KEEPER", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 67, Text = "ELDER ROOT", Colour = Color3.fromRGB(255, 125, 80), Family = "thorn" },
			{ At = 72, Text = "ROOT GUARDIAN", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 75, Text = "ROOT COMMANDER", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 78, Text = "ROOT MASTER", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 81, Text = "ROOT SOVEREIGN", Colour = Color3.fromRGB(235, 60, 80), Family = "thorn" },
			{ At = 84, Text = "CANOPY LORD", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 87, Text = "EMERALD REGENT", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 90, Text = "WILDWOOD REGENT", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 93, Text = "VERDANT REGENT", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 96, Text = "CANOPY KING", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 99, Text = "FOREST KING", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 102, Text = "WILD SOVEREIGN", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 105, Text = "GROVE EMPEROR", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 108, Text = "CANOPY MONARCH", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 111, Text = "FOREST ASCENDANT", Colour = Color3.fromRGB(30, 190, 110), Family = "canopy" },
			{ At = 114, Text = "ANCIENT OAK", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 117, Text = "TIMELESS OAK", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 120, Text = "IRONBARK", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 123, Text = "DEEPWOOD", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 126, Text = "PRIMEVAL ROOT", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 129, Text = "PRIMAL GROVE", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 132, Text = "ELDERWOOD WARDEN", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 135, Text = "ELDERWOOD TITAN", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 138, Text = "FOREST COLOSSUS", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 141, Text = "ANCIENT WORLD", Colour = Color3.fromRGB(205, 150, 90), Family = "elder" },
			{ At = 144, Text = "WORLD TREE", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 149, Text = "SKYROOT", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 152, Text = "SKY CANOPY", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 155, Text = "SUNROOT", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 158, Text = "SUN CANOPY", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 161, Text = "SUNWARD TREE", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 164, Text = "WORLDHEART", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 167, Text = "WORLDROOT", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 170, Text = "WORLD CROWN", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 173, Text = "WORLD SOUL", Colour = Color3.fromRGB(255, 215, 80), Family = "world" },
			{ At = 176, Text = "ETERNAL ROOT", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 179, Text = "ETERNAL GROVE", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 182, Text = "ETERNAL CANOPY", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 185, Text = "ETERNAL BLOOM", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 188, Text = "DAWNROOT", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 191, Text = "DAWNWEAVER", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 194, Text = "SUNWEAVER", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 197, Text = "RADIANT GROVE", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 200, Text = "RADIANT CROWN", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 203, Text = "EVERGREEN SOUL", Colour = Color3.fromRGB(90, 200, 255), Family = "dawn" },
			{ At = 206, Text = "PRIMEVAL BLOOM", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 209, Text = "VERDANT ETERNAL", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 212, Text = "UNDYING ROOT", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 215, Text = "UNDYING CANOPY", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 218, Text = "BOUNDLESS BLOOM", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 221, Text = "EVERBLOOM", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 226, Text = "EVERBLOOM HEART", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 229, Text = "EVERBLOOM CROWN", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 232, Text = "EVERBLOOM SOUL", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 235, Text = "BLOOM ASCENDANT", Colour = Color3.fromRGB(255, 90, 230), Family = "everbloom" },
			{ At = 238, Text = "STARROOT", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 241, Text = "STAR CANOPY", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 244, Text = "STARBLOOM", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 247, Text = "ASTRAL ROOT", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 250, Text = "ASTRAL CANOPY", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 253, Text = "CELESTIAL BLOOM", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 256, Text = "COSMIC GROVE", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 259, Text = "GALAXY WEAVER", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 262, Text = "STELLAR SOVEREIGN", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 265, Text = "COSMIC ASCENDANT", Colour = Color3.fromRGB(181, 156, 255), Family = "astral" },
			{ At = 268, Text = "PRIMAL SPIRIT", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 271, Text = "VITAL SPIRIT", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 274, Text = "NATURE AVATAR", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 277, Text = "EARTHHEART", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 280, Text = "EARTHSOUL", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 283, Text = "LIFEWEAVER", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 286, Text = "LIFE ARCHITECT", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 289, Text = "LIFE SOVEREIGN", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 292, Text = "GENESIS BLOOM", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 295, Text = "GENESIS SOUL", Colour = Color3.fromRGB(241, 190, 164), Family = "genesis" },
			{ At = 298, Text = "GAIA", Colour = Color3.fromRGB(255, 255, 255), Family = "gaia", Rainbow = true, Ranks = 5 },
		},
		-- THE ELEVEN FAMILIES, in the ladder's order: the TITLES list's headers,
		-- each one's palette -- the celebration's leaves and sparkles, the aura's
		-- two wisps (Primary, Secondary; GAIA's the rainbow) -- and its unlock
		-- accent. Signature: a family's own accent on a NEW name (RebirthFX), two
		-- prototypes for the owner: Seedlight and World Tree Halo; the other nine
		-- throw the common leaves and sparkles in their palette until the owner
		-- says yes. AuraAccents: small leaves round its aura (Aura.Accent), at
		-- most two.
		Families = {
			{ Id = "seedlight", Name = "GARDEN APPRENTICES", Fx = "SEEDLIGHT", Primary = Color3.fromRGB(60, 205, 115),
				Secondary = Color3.fromRGB(170, 255, 60), Signature = "Seedlight" },
			{ Id = "petal", Name = "GROVE WARDENS", Fx = "PETAL RING", Primary = Color3.fromRGB(190, 125, 255),
				Secondary = Color3.fromRGB(255, 120, 200) },
			{ Id = "thorn", Name = "THORN AND ROOT GUARD", Fx = "THORN CIRCLE", Primary = Color3.fromRGB(235, 60, 80),
				Secondary = Color3.fromRGB(255, 125, 80) },
			{ Id = "canopy", Name = "CANOPY NOBILITY", Fx = "CANOPY CROWN", Primary = Color3.fromRGB(30, 190, 110),
				Secondary = Color3.fromRGB(182, 243, 204) },
			{ Id = "elder", Name = "ANCIENT FOREST", Fx = "ELDER POLLEN", Primary = Color3.fromRGB(205, 150, 90),
				Secondary = Color3.fromRGB(255, 240, 210) },
			{ Id = "world", Name = "WORLD TREE", Fx = "WORLD TREE HALO", Primary = Color3.fromRGB(255, 215, 80),
				Secondary = Color3.fromRGB(138, 228, 119), Signature = "Halo", AuraAccents = 2 },
			{ Id = "dawn", Name = "DAWN AND RADIANCE", Fx = "DAWN RAYS", Primary = Color3.fromRGB(90, 200, 255),
				Secondary = Color3.fromRGB(240, 247, 255) },
			{ Id = "everbloom", Name = "IMMORTAL BLOOM", Fx = "EVERBLOOM PETALS", Primary = Color3.fromRGB(255, 90, 230),
				Secondary = Color3.fromRGB(255, 240, 250) },
			{ Id = "astral", Name = "ASTRAL GROVE", Fx = "ASTRAL POLLEN", Primary = Color3.fromRGB(181, 156, 255),
				Secondary = Color3.fromRGB(124, 232, 255) },
			{ Id = "genesis", Name = "GENESIS", Fx = "GENESIS ORBIT", Primary = Color3.fromRGB(241, 190, 164),
				Secondary = Color3.fromRGB(255, 246, 226) },
			{ Id = "gaia", Name = "GAIA", Fx = "GAIA RAINBOW", Primary = Color3.fromRGB(255, 255, 255),
				Secondary = Color3.fromRGB(255, 255, 255), Rainbow = true },
		},
	},
	--==========================================================================
	-- THE OWNER'S FENCE, BY THEIR REBIRTHS. Colours, materials and caps that
	-- nothing can touch, stand on or hit ONLY: the boards, the gap filler and
	-- the posts keep exactly their size, place and collision -- tuned against
	-- snagging and climbing (MapService, THE GAP IS SHUT TO THE BODY). The tier
	-- is the rebirths, up to the last; past it the gold fence's gems step
	-- through Trims every TrimEvery rebirths. Built from parts and materials,
	-- no uploads.
	--==========================================================================
	Fence = {
		-- `Says` is how the panel's NEXT UNLOCKS names each one.
		Tiers = {
			[0] = { Name = "Wood", Says = "Plain wood", Colour = Color3.fromRGB(96, 66, 44), Material = Enum.Material.Wood },
			{ Name = "White picket", Says = "White picket", Colour = Color3.fromRGB(240, 238, 228),
				Material = Enum.Material.SmoothPlastic,
				Cap = "point", CapColour = Color3.fromRGB(240, 238, 228), CapMaterial = Enum.Material.SmoothPlastic },
			{ Name = "Stone", Says = "Stone with moss caps", Colour = Color3.fromRGB(130, 128, 120),
				Material = Enum.Material.Slate,
				Cap = "moss", CapColour = Color3.fromRGB(91, 151, 76), CapMaterial = Enum.Material.Grass },
			{ Name = "Iron", Says = "Iron with gold tips", Colour = Color3.fromRGB(56, 58, 66),
				Material = Enum.Material.DiamondPlate,
				Cap = "tip", CapColour = Color3.fromRGB(255, 196, 64), CapMaterial = Enum.Material.Metal },
			{ Name = "Marble", Says = "Marble with flower planters", Colour = Color3.fromRGB(236, 232, 224),
				Material = Enum.Material.Marble,
				Cap = "planter", CapColour = Color3.fromRGB(186, 98, 58), CapMaterial = Enum.Material.Wood,
				FlowerColour = Color3.fromRGB(255, 120, 175) },
			{ Name = "Crystal", Says = "Crystal with glowing caps", Colour = Color3.fromRGB(170, 225, 255),
				Material = Enum.Material.Glass,
				Cap = "glow", CapColour = Color3.fromRGB(190, 245, 255), CapMaterial = Enum.Material.Neon },
			{ Name = "Gold", Says = "Gold with gem caps", Colour = Color3.fromRGB(255, 198, 64),
				Material = Enum.Material.Foil,
				Cap = "gem", CapMaterial = Enum.Material.Neon },
		},
		TrimEvery = 4,
		Trims = {
			Color3.fromRGB(230, 40, 70), -- ruby
			Color3.fromRGB(60, 110, 255), -- sapphire
			Color3.fromRGB(40, 205, 110), -- emerald
			Color3.fromRGB(170, 80, 255), -- amethyst
			Color3.fromRGB(255, 150, 30), -- topaz
			Color3.fromRGB(235, 248, 255), -- diamond
		},
		-- The decorations' folder in the plot, beside the fence it dresses.
		FolderName = "FenceDecor",
	},
	--==========================================================================
	-- THE PANEL'S ICONS (2026-10-08, the owner: "add more detail on the rebirth
	-- info, we will add how the required mill look"). The owner's uploads, one
	-- Image each (output/imagegen/rebirth/rebirth-icons-v1; CrazyCozy Games,
	-- 512 x 512, real alpha; checked: economy details, Edit IsLoaded). ""
	-- draws the stand-in, never anybody else's upload: no MILL icon was
	-- uploaded, and the mill picture is the real model, live (Preview).
	--==========================================================================
	Art = {
		Emblem = "rbxassetid://133554119533442",
		Mill = "",
		CashReset = "rbxassetid://112687292855232",
		TitleBadge = "rbxassetid://133032357694764",
		-- The part of each 512 px picture that is drawn: one square round all
		-- three drawings (measured alpha bounds 76..435), so the transparent
		-- margin does not shrink them under ScaleType Fit and all three draw at
		-- the same size.
		CropOffset = Vector2.new(72, 72),
		CropSize = Vector2.new(368, 368),
	},
	-- The live 3D pictures (RebirthUI): the required mill and the next fence,
	-- each in a ViewportFrame, built while the panel is open and destroyed on
	-- close. One turn every TurnSeconds; still for reduced motion.
	Preview = {
		TurnSeconds = 18,
		Pitch = 20,
		-- How long a sample of fence the next tier is shown on, in studs.
		FenceLength = 12,
	},
	--==========================================================================
	-- THE CELEBRATION (2026-10-09, the owner: "can we also make a pop up when
	-- rebirthed? like a animation rotating the character, or a light that
	-- rotates around when you rebirth then a text and sfx" -- the plan the other
	-- session wrote for it, approved as written: "approve, let terminal work").
	--
	-- About Seconds long from the server's "done" (Shared/RebirthCelebration is
	-- the timeline, Shared/RebirthFX draws it):
	--   0.0       the panel shuts; a soft white-gold flash; a column of light
	--             rises from the feet; the fanfare;
	--   0.0-1.6   the body spins SpinTurns, eased, and ends facing the camera;
	--             eight orbs orbit the other way, rising from the feet to over
	--             the head; the camera is held still and the controls with it;
	--   0.6       the REBORN! card pops in at the upper middle, the owner's gold
	--             rays turning behind it;
	--   1.6       the burst at the feet; leaves and sparkles in the new title's
	--             colour drift up; the controls come back;
	--   3.5       the card has faded (a tap on it closes it sooner); every piece
	--             is gone.
	-- Players within Range see the column, the orbs and the burst round that
	-- body and hear the fanfare from there; everybody else in the server reads
	-- one line (Notice.ServerNotice). From Aura.From rebirths a faint aura loops
	-- round the body. REDUCED FX (StatusText.reducedMotion): no spin, orbs, rays,
	-- flash, column or particles -- the card simply appears and the fanfare
	-- still plays.
	--==========================================================================
	Celebration = {
		-- The fanfare (the owner's "Triumphant Chime"): SoundKit cue rows, flat
		-- on the reborn player's own screen, and from the body for everybody
		-- within Range. Their window puts its hit on the burst (SpinSeconds).
		Cue = "Rebirth",
		NearbyCue = "RebirthNearby",
		-- Who else sees it: everybody whose body is this close to the reborn one.
		Range = 120,
		Seconds = 3.5,
		SpinSeconds = 1.6,
		SpinTurns = 2,
		PopupAt = 0.6,
		-- The card's entrance: 0.6 -> 1.08 -> 1 of its fitted size.
		PopSeconds = 0.35,
		FadeSeconds = 0.4,
		FlashSeconds = 0.5,
		-- At its brightest the flash is this see-through.
		FlashTransparency = 0.45,
		FlashColour = Color3.fromRGB(255, 244, 214),
		Column = {
			RiseSeconds = 0.35,
			FadeFrom = 1.2,
			FadeTo = 1.9,
			Height = 16,
			-- The bright core and the soft glow round it: diameters in studs.
			Core = 1.6,
			Glow = 4.4,
			CoreColour = Color3.fromRGB(255, 250, 225),
			Colour = Color3.fromRGB(255, 222, 130),
		},
		Orbs = {
			Count = 8,
			Radius = 3.4,
			-- Round the body the other way while it spins.
			Turns = 1.5,
			-- Each orb, in studs.
			Size = 1.6,
			-- From the feet to over the head, against the body's root.
			FromY = -2.6,
			ToY = 4.2,
			FadeSeconds = 0.3,
			Colour = Color3.fromRGB(255, 214, 90),
		},
		-- The coloured burst, once: facing the camera behind the body, and flat
		-- on the ground round the feet. Studs across.
		Burst = { Size = 14, Ground = 11, Lifetime = 0.9 },
		Leaves = { Count = 18 },
		Sparkles = { Count = 28 },
		--==========================================================================
		-- THE ACCENT AT THE BURST, BY WHAT CHANGED (2026-10-10, the 100 titles;
		-- the design's FX rules). The rest of the celebration is every rebirth's.
		--   a NEW NAME (BOTANIST III to LEAF TENDER I): its family's accent -- the
		--     two prototypes' own (Families' Signature: Seedlight, Halo), or the
		--     leaves and sparkles above in its family's palette;
		--   a RANK ONLY (BOTANIST I to II): Motes leaves and sparkles in the
		--     palette, and the title over the head pulses once (Pulse) -- never the
		--     full accent, never a longer hold of the controls.
		-- All of it world pieces made at the start and gone at the end; none for
		-- REDUCED FX.
		--==========================================================================
		Motes = { Leaves = 4, Sparkles = 8 },
		-- The pulse: the reborn title's words grow to Scale and back in Seconds
		-- (OwnerTitleUI, told by the title's Attribute on that screen only).
		Pulse = { Seconds = 0.5, Scale = 1.18, Attribute = "SeedRebirthPulse" },
		-- SEEDLIGHT (slots 1-9): a small upward pollen puff and a few bright leaf
		-- twinkles; one leaf arc over the head, no crown. Leaves leaf pictures
		-- ride the arc (Radius studs round the head, ArcSeconds from the left
		-- shoulder over to the right), staggered by Stagger.
		Seedlight = { Leaves = 5, Radius = 2.6, ArcSeconds = 0.9, Stagger = 0.08, LeafSize = 1.1, Pollen = 16,
			Twinkles = 6 },
		-- WORLD TREE HALO (slots 50-59): a fuller leaf halo opens once over the
		-- head with golden pollen, a short gold ring of rays behind it. Leaves
		-- leaf pictures in a ring Above studs over the head, from From to To
		-- studs round in Seconds while it turns Turn of a circle, then fading; the
		-- owner's sunburst (Rays) behind, RaysSize studs, for RaysSeconds.
		Halo = { Leaves = 10, Above = 1.4, From = 0.6, To = 2.8, Seconds = 1.2, Turn = 0.35, LeafSize = 1.0,
			Pollen = 24, RaysSize = 7, RaysSeconds = 1.0, Gold = Color3.fromRGB(255, 214, 90) },
		-- THE AURA, from rebirth 50 up: the owner's looping wisp sheet played as a
		-- 16-frame picture (Framerate a second) on two billboards Size studs
		-- square, Side studs to the left and the right of the body in camera
		-- space, Back studs behind it and Lift up -- so from any side they stand
		-- beside the body and never over it. In the family's palette (since the
		-- 100 titles; the title's colour before). Billboards, not
		-- particles: the same sheet as a flipbook ParticleEmitter drew only now
		-- and then in Play (2026-10-09, on the body and off it), the billboards
		-- every time.
		Aura = {
			From = 50,
			Size = 6.5,
			Side = 1.8,
			Back = 0.8,
			Lift = 0.25,
			Framerate = 10,
			Transparency = 0,
			MaxDistance = 160,
			-- THE 100 TITLES (2026-10-10): the wisps wear the family's palette (the
			-- first Primary, the second Secondary; GAIA's the rainbow, turning once
			-- every RainbowSeconds). Only the Nearest bodies within MaxDistance of
			-- this camera show theirs. A family's AuraAccents (World Tree Halo's
			-- two) are small leaves going round the body once every Accent.Seconds,
			-- Radius studs out, bobbing Bob studs about Lift.
			-- Fast since 2026-10-10 (the owner: "make those fast too"): the same
			-- pace as GAIA's title, TitleFX.RainbowSeconds (12 before).
			RainbowSeconds = 1.2,
			Nearest = 4,
			Accent = { Size = 0.9, Radius = 2.4, Seconds = 7, Lift = 1.2, Bob = 0.3 },
		},
		-- The owner's four effect sheets (uploaded 2026-10-09; checked by the
		-- other session: Image, CrazyCozy Games, Edit IsLoaded, real alpha).
		-- Every frame 256 px, left to right, top row first.
		Textures = {
			-- 1024, 4 x 4, coloured: played ONCE (frame 16 is nearly empty).
			Burst = "rbxassetid://104561904060787",
			-- 512, 2 x 2, white (tinted): played back and forth, because its last
			-- frame jumps back to its first.
			Leaf = "rbxassetid://139088327003961",
			-- 512, 2 x 2, white (tinted): once per particle; frame 3 is the orb.
			Sparkle = "rbxassetid://113832021583342",
			-- 1024, 4 x 4, white (tinted), at most 69% opaque: loops.
			Aura = "rbxassetid://136617357503029",
		},
		-- THE OWNER'S EXTRA ART (output/imagegen/extras/
		-- hatch-rebirth-extras-v1.prompt.md), uploaded 2026-10-09. "" puts the
		-- drawn stand-in back -- never another upload standing in.
		--   Rays  a 1024 WHITE sunburst (sunburst-rays-v1, 16 rays, peak alpha
		--         204), tinted RayColour and turned behind the card's emblem;
		--         drawn as RayBars bars (twice as many rays) when "";
		--   Logo  a 1024 x 384 "REBORN!" word picture (reborn-logo-v1; the art
		--         fills about 89% x 77% of it) over the card's first line; the
		--         LuckiestGuy words when "".
		Rays = "rbxassetid://134900206184752",
		Logo = "rbxassetid://107076109311776",
		RayColour = Color3.fromRGB(255, 206, 70),
		-- How see-through the sunburst is at its fullest (2026-10-09): it sits
		-- on the card, round the emblem and under the words.
		RayFade = 0.4,
		RayBars = 8,
		-- Degrees a second.
		RaySpin = 40,
		-- THE CARD: its base size, placed by RebirthCelebration.popup at the
		-- upper middle clear of the HUD, at most a phone's menu size there
		-- (MenuSize.PhoneScale), never under MinScale.
		Popup = {
			Size = Vector2.new(460, 156),
			Gap = 8,
			MinScale = 0.5,
			Step = 0.02,
			-- The most it may stand off the middle, as a share of the width (a
			-- small phone's free gap between its corner buttons is off it).
			Shift = 0.15,
			-- The least it is drawn at before the notices' line gives way to it
			-- (RebirthCelebration.popup's `soft`, 2026-10-09): its longest lines fit
			-- at about 19 px (the Bonus line), so 0.66 keeps every word 12 px or
			-- more drawn. Under the phone's panel row 640 x 360 had it at 0.63.
			Readable = 0.66,
			Emblem = 112,
			Rays = 250,
		},
		-- Over the menus' layers (Shop, EVENTS, the panel: 32) and the invite
		-- card (35), under the rail layer (40) and the alarm (50).
		DisplayOrder = 36,
		Words = {
			Reborn = "REBORN!",
			Line = "REBIRTH %d · %s",
			Bonus = "x%s training · x%s income",
			-- To everybody else in the server.
			Server = "%s reached REBIRTH %d · %s!",
		},
	},
	-- THE PANEL'S PLACES (Rebirth.layout): at most MaxW x MaxH, placed by
	-- MenuLayout like the Shop's (between the rails, or over them on a phone).
	-- The FOOT -- the reason line and the button -- is pinned to the bottom of
	-- the body, outside the scroll, on every screen (a phone of the owner's
	-- once showed the old panel's body run off its bottom and the button gone).
	-- Two columns where the body is WideAt or wider.
	Layout = {
		MaxW = 860,
		MaxH = 640,
		Foot = 86,
		ButtonTop = 26,
		ButtonH = 56,
		ButtonW = 0.5,
		WideAt = 640,
		-- The least of the body the scroll ever gets.
		MinScroll = 40,
		-- THE TITLES VIEW (the owner: "i want players to see the titles inside a
		-- question mark button inside the rebirth ui"): its BACK control over a
		-- list that fills the rest of the body, one TitleRow per step; the "?"
		-- that opens it stands left of the X in the band, the X's own size.
		BackW = 140,
		BackH = 36,
		TitleRow = 56,
		-- THE 100 TITLES (2026-10-10): a header row over each family's steps, and
		-- each row's words (the step and its numerals' range, its rebirths) on
		-- RowWords of its width -- the narrowest list's widest, ELDERWOOD WARDEN
		-- I-III, at 22 px (RebirthSpec); the bonus beside them, the chip right.
		FamilyRow = 30,
		RowWords = 0.56,
		RowBonus = 0.24,
		HelpGap = 8,
	},
	-- YOU KEEP / YOU LOSE as chips: a word and an existing icon where there is
	-- one (`Icon` names a GameConfig path read by RebirthUI; nil draws a mark).
	Keep = {
		{ Text = "Speed", Icon = "SourceIcons.speed" },
		{ Text = "Plot level", Icon = nil },
		{ Text = "Plants", Icon = "Rail.GardenIcon" },
		{ Text = "Pods", Icon = "Store.Icons.pod1" },
		{ Text = "Weapons", Icon = nil },
		{ Text = "Spin tickets", Icon = "SourceIcons.tickets" },
		{ Text = "The Index", Icon = "Rail.IndexIcon" },
		{ Text = "Passes", Icon = "Pass.BuffIcon" },
		{ Text = "Boosts", Icon = "SourceIcons.chest" },
	},
	Lose = {
		{ Text = "All cash", Art = "CashReset" },
		{ Text = "Mill → Compost Walk", Art = "Mill" },
	},
	Words = {
		Prompt = "Rebirth",
		Title = "REBIRTH",
		Current = "REBIRTH %d",
		NotYet = "NOT REBORN YET",
		Bonus = "Training x%s · Income x%s",
		Next = "Rebirth %d: training x%s, income x%s",
		Price = "Costs %s",
		Needs = "Mill: %s or better",
		-- The reworked body (2026-10-08).
		Strip = "REBIRTH %d · %s",
		NextStrip = "NEXT: REBIRTH %d · %s",
		BonusTitle = "BONUS",
		Training = "Training",
		Income = "Income",
		Step = "x%s → x%s",
		NeedsTitle = "REQUIREMENTS",
		CashLabel = "Cash",
		CashBar = "%s / %s",
		MillLabel = "Mill",
		MillLine = "Your mill: %s (tier %d) → needs %s (tier %d)",
		UnlocksTitle = "NEXT UNLOCKS",
		FenceLine = "Fence: %s",
		TitleLine = "Title: %s",
		-- The TITLES view.
		Help = "?",
		TitlesTitle = "TITLES",
		Back = "← BACK",
		RowRebirth = "REBIRTH %d",
		RowRebirths = "REBIRTH %d-%d",
		RowRebirthFrom = "REBIRTH %d+",
		-- A family's header in the TITLES list: "GARDEN APPRENTICES · REBIRTH 1-19".
		FamilyRow = "%s · REBIRTH %d-%d",
		FamilyRowFrom = "%s · REBIRTH %d+",
		RowBonus = "x%s training · x%s income",
		Reached = "✓ REACHED",
		NextChip = "NEXT",
		Locked = "LOCKED",
		KeepTitle = "YOU KEEP",
		Keep = "Speed, your plot level, every plant (garden and Bag), pods, weapons, spin tickets, "
			.. "the Index, passes and running boosts.",
		LoseTitle = "YOU LOSE",
		Lose = "All your cash. Your mill goes back to Compost Walk.",
		Button = "REBIRTH",
		Confirm = "ARE YOU SURE?",
		Done = "REBORN! REBIRTH %d",
		DoneDetail = "Training x%s · Income x%s",
		Refused = {
			DISABLED = "Rebirth is closed right now.",
			NOT_READY = "Your save is still loading.",
			COOLDOWN = "You were just reborn. One moment.",
			BUSY = "Finish your purchase first.",
			DEAD = "Respawn first.",
			CARRYING = "Put the pod down first.",
			CHASED = "Get away from your chaser first!",
			OFFLINE = "Claim your offline earnings first.",
			MILL = "Your mill must reach %s first.",
			CASH = "You need %s.",
			QUOTE = "Open the shrine again.",
			FAR = "Walk back to the shrine.",
		},
	},
}

-- A rebirth count from anywhere -- a save, an attribute, a packet: whole and
-- never below 0.
function GameConfig.rebirthCount(raw: any): number
	local n = tonumber(raw)
	if not n or n ~= n or n < 0 or n == math.huge then
		return 0
	end
	return math.floor(n)
end

--==============================================================================
-- THE TRAINING SEAM. Everything that computes a training rate multiplies by
-- this (trainingRateFor below): the payout, the mill sign, the shop and the
-- client's displays, each with the same profile. +50% per rebirth, added up:
-- x1.5 after one, x2 after two.
--==============================================================================
function GameConfig.rebirthMultiplierFor(profile: any): number
	if type(profile) ~= "table" then
		return 1
	end
	return 1 + GameConfig.Rebirth.TrainingPer * GameConfig.rebirthCount(profile.Rebirths)
end

-- The garden income bonus for a rebirth count: +25% each, added up. Permanent,
-- so it rides with the x2 pass (EconomyService's withPass): the live garden
-- and the offline claim, never a sale or a reward.
function GameConfig.rebirthIncomeFor(rebirths: any): number
	return 1 + GameConfig.Rebirth.IncomePer * GameConfig.rebirthCount(rebirths)
end

-- The same for a display, read off the player's published count.
function GameConfig.rebirthIncomeOf(player: Player?): number
	if not player then
		return 1
	end
	return GameConfig.rebirthIncomeFor(player:GetAttribute(GameConfig.Rebirth.Attributes.Rebirths))
end

--==============================================================================
-- THE ONE PLACE A TRAINING RATE IS DECIDED
--
--     rate = tier.speed * rebirth
--
-- Here rather than in TreadmillService because the mill SIGN, the shop and any
-- future UI all want to show the same number the payout uses, and a rate that
-- is computed twice is a rate that reads differently in two places the first
-- time either is touched. It carried an overclock factor (Multiplier^level)
-- until Overclock was removed (2026-10-06): tiers 11-14 are that range now.
--==============================================================================
function GameConfig.trainingRateFor(tierIndex: number, profile: any): number
	local tiers = GameConfig.Mill.Tiers
	local i = math.clamp(math.floor(if type(tierIndex) == "number" and tierIndex == tierIndex
		then tierIndex else 1), 1, #tiers)
	return tiers[i].speed * GameConfig.rebirthMultiplierFor(profile)
end

--==============================================================================
-- WHICH AFTERIMAGE TIER A SCORE EARNS
--
-- 0 is "trail only". Returned as a plain integer because it is published as a
-- player attribute so that every client can render every OTHER player without
-- being handed their profile.
--==============================================================================
--==============================================================================
-- IS THIS CHANGE IN THE BALANCE A LUMP, OR MORE OF THE SAME
--
-- For CashUI's tick (GameConfig.Sfx.CashTicks). `routine` is the running size
-- of recent changes -- plant income, mostly -- and nil until there is one. A
-- change more than LumpFactor times it is a lump: a sale, a reward, a purchase.
-- The routine size moves a quarter of the way toward EVERY change, lumps
-- included, so a garden whose income jumps is only a lump once, and the next
-- second of the new income is routine again.
--==============================================================================
function GameConfig.cashStepIsLump(step: number, routine: number?): boolean
	local r = routine
	return r ~= nil and r > 0 and math.abs(step) > r * GameConfig.Sfx.CashTicks.LumpFactor
end

function GameConfig.cashRoutineStep(routine: number?, step: number): number
	local s = math.abs(step)
	return if routine then routine + (s - routine) * 0.25 else s
end

--==============================================================================
-- WHAT A PLOT'S BADGE SHOWS, TO WHOM
--
-- `ownerUserId` is the plot's OwnerUserId attribute -- PlotService's word, the
-- only source of truth for who holds a plot -- and 0 or nil is nobody.
-- Returns which of three badges it is ("free", "mine", "theirs") and the name
-- printed under the face: the owner's USERNAME (their Player's, else the plot's
-- stamped OwnerName), never their display name, and nothing for a free plot.
--==============================================================================
function GameConfig.plotBadgeFor(ownerUserId: number?, viewerUserId: number,
	username: string?): (string, string)
	if type(ownerUserId) ~= "number" or ownerUserId <= 0 then
		return "free", ""
	end
	local name = if type(username) == "string" then username else ""
	return (if ownerUserId == viewerUserId then "mine" else "theirs"), name
end

-- The owner's headshot, by id. An rbxthumb:// content id the engine fetches and
-- caches itself: nothing yields, and nothing about it comes over a remote.
function GameConfig.avatarHeadshot(userId: number): string
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", math.floor(userId))
end

--==============================================================================
-- THE PLAQUE'S TWO LINES
--
-- Out of what EconomyService published (GameConfig.Attributes.GardenGrown and
-- friends) and the plot's Capacity. nil when there is nothing true to say yet --
-- a plot nobody holds, or an owner whose garden is still being restored -- so
-- the plaque stands blank rather than printing a 0/10 that was never so.
-- Counts only: a pod is "hatching", never what is inside it.
--==============================================================================
function GameConfig.plotStatsText(grown: any, pods: any, capacity: any, income: any,
	boost: any): (string?, string?, string?, string?)
	if type(grown) ~= "number" or type(pods) ~= "number" or type(income) ~= "number" then
		return nil, nil, nil, nil
	end
	local cap = tonumber(capacity) or 0
	local plants = string.format("PLANTS %d/%d", grown + pods, math.max(0, math.floor(cap)))
	local hatching = if pods > 0 then string.format("%d hatching", pods) else ""
	local earning = "$" .. GameConfig.compact(income) .. "/s"
	local boosted = if type(boost) == "number" and boost > 1
		then string.format("with x%s boost", tostring(boost))
		else ""
	return plants, hatching, earning, boosted
end

function GameConfig.speedVisualTierFor(speedScore: number): number
	local tiers = GameConfig.Afterimage.Tiers
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return 0
	end
	local tier = 0
	for i, row in ipairs(tiers) do
		if speedScore >= row.From then
			tier = i
		end
	end
	return tier
end

--==============================================================================
-- THE HUD RAIL IS DRAWN AGAIN, IN CODE
--
-- It was three crops of `shop index.png` -- another game's UI, uploaded to the
-- asset server -- for about a day. They looked cropped because they were: the
-- black outline and the diamond lattice were clipped on both sides, the Index
-- badge had to be mirrored out of the artwork, and all three were pinned to the
-- source's native 123 x 48 because a 170 x 152 screenshot has no resolution to
-- spare.
--
-- HANDOFF wrote down where that ends before it was a problem: "redrawing the
-- same look in code carries none of that risk and scales to any size." The
-- lattice, the slab, the icons and the labels are instances again. The image ids
-- are gone and `art/rail-*.png` stays on disk as reference for what the buttons
-- once looked like, not as anything the game loads.
--
-- STRUCTURE AND NAMES, NOT BALANCE. Rule 7 is intact: nothing here decides what
-- a thing is worth, only where it sits and what colour it is.
--==============================================================================
GameConfig.Rail = {
	-- Left rail: Index at the top, Shop under it. Garden sits opposite.
	Inset = 12,
	Gap = 6,

	-- Wide enough for an icon and a word; the square one is icon only. Chosen
	-- rather than inherited now -- 130 x 50 puts Shop's top at 68, exactly where
	-- the 123 x 48 crop left it, so nothing below the rail moved.
	WideSize = Vector2.new(130, 50),
	SquareSize = Vector2.new(50, 50),
	Radius = 12,
	LabelSize = 22,

	--==========================================================================
	-- TWO ICON SIZES, BECAUSE THE RAIL IS TWO KINDS OF BUTTON
	--
	-- Index and Shop are SLABS: a coloured plate with a word on it, and the icon
	-- is a passenger at 28. Garden and the Bag are BARE -- the artwork is the
	-- button, with nothing behind it -- so their icon has to fill the whole 50
	-- the plate used to, or those two lose half their presence next to the pair
	-- that still have plates.
	--==========================================================================
	IconSize = 28,
	IconBare = 50,

	-- Thick, and black. The outline is what made the reference read as a button
	-- rather than as a coloured rectangle, and it is the one part the crops kept
	-- losing at the edges. Read by the two slab buttons and by the plant card's
	-- action; the bare pair have no rectangle to outline.
	Outline = Color3.fromRGB(0, 0, 0),
	OutlineThickness = 3,

	--==========================================================================
	-- THE SLAB FACES, WHICH TWO BUTTONS STILL PAINT
	--
	-- Blue, green and amber: far enough apart to be told apart at a glance in the
	-- corner of the eye, and none of them a Greenhollow plant colour -- chrome
	-- should not be mistakable for something growing.
	--
	-- Index and Shop read these. Garden and the Bag are bare buttons and do not,
	-- but Garden's pair stays: it is what the garden icon was DRAWN in, and it is
	-- the record of that identity now that no plate carries it.
	--==========================================================================
	IndexFace = Color3.fromRGB(64, 148, 220),
	IndexShade = Color3.fromRGB(36, 102, 168),
	ShopFace = Color3.fromRGB(86, 182, 72),
	ShopShade = Color3.fromRGB(46, 126, 44),
	GardenFace = Color3.fromRGB(236, 160, 52),
	GardenShade = Color3.fromRGB(186, 110, 28),

	-- Red, and one of the few things allowed outside ink / paper / accent: the
	-- job of a badge is to be what the eye finds before it has decided to look.
	Badge = Color3.fromRGB(226, 76, 76),
	--==========================================================================
	-- INVITE'S BADGE IS AN EXCLAMATION POINT (the owner, 2026-10-06)
	--
	-- Not the red circle every other button keeps: a bold "!" (plain ASCII) in
	-- bright yellow-gold with a thick dark ink line, the display font, no plate
	-- behind it -- in the same corner and the same box as the other badges
	-- (HudLayout.badges). A small wiggle every PulseEvery seconds while it shows,
	-- drawn over a glyph that is already in its place: nothing positions it.
	--==========================================================================
	InviteBadge = {
		Glyph = "!",
		Fill = Color3.fromRGB(255, 214, 64),
		Ink = Color3.fromRGB(26, 20, 6),
		Stroke = 3,
		Font = Enum.Font.LuckiestGuy,
		-- The glyph's height, of the badge box's.
		Scale = 1.15,
		PulseEvery = 3.2,
		PulseSeconds = 0.5,
		PulseDegrees = 14,
		-- Its pop (invite_badge_pop) is for a form given while playing: none
		-- in this many seconds after the player's numbers first arrive.
		QuietAfterJoin = 10,
	},

	--==========================================================================
	-- THE FOUR RAIL ICONS, WHICH ARE UPLOADED NOW
	--
	-- These four buttons drew their own icons out of frames -- a cart, a book, a
	-- sprout and a satchel -- and the reason is still written beside each of
	-- them: a font glyph renders as tofu on some devices and an uploaded id can
	-- be moderated away. Both are true. What changed is that the owner supplied
	-- vector masters, so the trade is now a drawn approximation against real
	-- artwork rather than against a glyph.
	--
	-- Uploaded from art/ui/rail-icons/<name>-128.png, which are 128px reductions
	-- of the 512px exports. They draw at 28 and pop to 30; 128 covers a 3x phone
	-- with headroom at a sixteenth of the memory, which is rule 8.
	--
	-- THE DRAWN HELPERS ARE STILL LIVE. UIKit.bookIcon and sproutIcon each appear
	-- twice -- once on the rail button and once in that panel's modal TITLE BAR --
	-- and only the rail half is replaced here. Deleting them would take the title
	-- bars with them. UIKit.cartIcon lost its title bar in the 2026-09-11 shop
	-- restyle, whose green header carries no icon; it is unused but kept.
	--==========================================================================
	-- Superseded on the rail by ShopArt and IndexArt below (2026-09-24); kept so
	-- going back is a one-line change.
	ShopIcon = "rbxassetid://90931969678136",
	IndexIcon = "rbxassetid://126806966970007",
	--==========================================================================
	-- INDEX AND SHOP: THE OWNER'S APPROVED BUTTON ARTWORK (2026-09-24)
	--
	-- Each is a whole button in one square picture -- the thick black outline,
	-- the rim, the face, the cart or the book, and the word -- so these two are
	-- ART buttons now (UIKit.railButton `art`): no slab, icon or label of ours
	-- around it, square at every size, never stretched.
	--
	-- Uploaded from art/ui/rail-buttons/<name>-256.png, 256-px reductions of
	-- the 512 exports: the buttons draw at 50 px, which is 150 on a 3x phone and
	-- 135 on a 4K TV, so 128 would soften and 512 would be four times the memory.
	--
	-- The Shop's is shop-base.svg: the approved shop.svg with its static rim
	-- stroke taken out and that band CUT to transparent, so the rainbow
	-- UIKit.rainbowRim turns behind the picture shows through the band and
	-- nowhere else. The Index keeps the approved static rim.
	--==========================================================================
	ShopArt = "rbxassetid://100314547854118",
	IndexArt = "rbxassetid://107928181966123",
	--==========================================================================
	-- THE OWNER'S STUDDED PICTURES (2026-10-05)
	--
	-- Shop (wide: the picture is 2094 x 751), Index and Settings (square), each
	-- a whole button -- outline, studded face, icon and word -- drawn as it is,
	-- never stretched (UIKit.railPicture). Uploaded to the group by the owner;
	-- economy details read Image, CrazyCozy Games, named shop-lime-studded-v1,
	-- index-sky-blue-studded-v1 and settings-silver-studded-v1. Sources in
	-- art/ui-buttons/shop-index-2026-10-05. Index draws its picture on every
	-- screen and Shop wherever its slot is wide -- a desktop's and a TV's rail
	-- (since 2026-10-06), a phone's corner; a small window's square keeps
	-- ShopArt. Settings draws its picture on a phone only.
	--==========================================================================
	StuddedShopArt = "rbxassetid://82894505272456",
	StuddedShopAspect = 2094 / 751,
	StuddedIndexArt = "rbxassetid://91015160762668",
	StuddedSettingsArt = "rbxassetid://131108200114897",
	--==========================================================================
	-- THE INVITE BUTTON'S PICTURE (2026-10-06, owner-designated; economy
	-- details: Image, CrazyCozy Games). Measured in Studio Edit: 1024 x 1024,
	-- its opaque body 939 x 915 -- SQUARE, so like Index it is the button on
	-- every screen (UIKit.railPicture). Source drawn by Codex:
	-- art/ui-buttons/invite-friend-2026-10-06.
	--==========================================================================
	StuddedInviteArt = "rbxassetid://87744294855846",
	StuddedInviteAspect = 1024 / 1024,
	--==========================================================================
	-- GARDEN AND THE BAG'S PICTURES (2026-10-09, the owner: "new garden
	-- button, and inventory button"; owner-designated uploads "Plant-creatures"
	-- and "inventory"). Each a whole studded button -- dark outline, teal
	-- studded face, a purple paw / a brown satchel, no word -- so like Index and
	-- Invite the picture IS the button (UIKit.railPicture), with GARDEN / BAG on
	-- a plate until it has loaded. Measured in Studio Edit: both 1024 x 1024,
	-- PreloadAsync Success, the opaque body 948 x 928 and 948 x 925, centred
	-- within 2 px. ON THE TWO RAIL BUTTONS ONLY (the owner's call): GardenIcon
	-- and BagIcon below stay everywhere else they are drawn (panel titles, the
	-- teleport buttons, notices, the Bag's Plants box, the rebirth card).
	--==========================================================================
	StuddedGardenArt = "rbxassetid://80369422946168",
	StuddedBagArt = "rbxassetid://100113253044275",
	--==========================================================================
	-- THE SHOP'S RAINBOW RIM
	--
	-- Geometry in the artwork's own 256 units (shop-base.svg). The band is the
	-- 7-unit stroke round the panel rect (20, 43, 216 x 192, rx 14); the frame
	-- behind the picture is that band's outer edge grown by 2.5 on every side,
	-- still inside the opaque black outline, so the frame's own edge and corners
	-- never show. Same corner centres as the band, radius 17.5 + 2.5.
	--
	-- Speed and colours are the owner's reference clip, measured: every point on
	-- the band swings red -> purple -> red, the two sides in opposite phase, one
	-- whole turn in 120 frames at 30 fps -- a rainbow gradient rotating at 90
	-- degrees a second. Red, yellow, green, cyan, blue and purple, evenly spaced.
	--==========================================================================
	Rim = {
		Art = 256,
		X = 14,
		Y = 37,
		W = 228,
		H = 204,
		Radius = 20,
		Speed = 90,
		Colours = {
			Color3.fromRGB(255, 56, 56),
			Color3.fromRGB(255, 222, 48),
			Color3.fromRGB(86, 232, 72),
			Color3.fromRGB(48, 224, 255),
			Color3.fromRGB(56, 112, 255),
			Color3.fromRGB(184, 72, 255),
		},
	},
	--==========================================================================
	-- GARDEN AND THE BAG ARE FILLED AGAIN, BECAUSE THEY LOST THEIR PLATE
	--
	-- These two were knocked out to hollow outlines for one good reason: each
	-- icon is drawn in its own button's colour family, and for these two that
	-- collided with the plate behind it -- the planter's amber against a #ECA034
	-- slab, the satchel's leather against a #C4945C one. Near enough the same
	-- colour to read as a lump.
	--
	-- That reason is gone. There is no slab behind either of them now, so there
	-- is nothing left to clash with -- and a hollow outline on a bare button is
	-- just the world showing through, which is how they ended up looking like
	-- they had no colour at all. Filled artwork on nothing is the version that
	-- reads.
	--
	-- These are the ORIGINAL filled uploads, not new ones. The knocked-out pair
	-- (131355079577116 and 124800563254633) are superseded and unused.
	--==========================================================================
	GardenIcon = "rbxassetid://106268245303506",
	BagIcon = "rbxassetid://135554729755251",
	--==========================================================================
	-- SETTINGS, THE FIFTH, BARE LIKE GARDEN AND THE BAG
	--
	-- Uploaded from art/ui/rail-icons/settings-128.png, the same 128px reduction
	-- as the other four. It sits on the LEFT rail under Shop, because the right
	-- rail's third row is where the Bag's equipment column starts. SettingsUI
	-- draws a gear out of frames if this id ever fails to load, so a moderated
	-- upload costs the artwork and never the button.
	--==========================================================================
	SettingsIcon = "rbxassetid://104265736892158",

	--==========================================================================
	-- THE PHONE'S TWO SIDEBARS (touch only; HudLayout, THE PHONE'S SIDEBARS)
	--
	-- The owner's approved mockup, 2026-09-23: a slim dark translucent panel
	-- with a teal edge down each side, dark slate tiles in it, and a thin
	-- coloured edge on each tile rather than a painted face. The Shop's tile is
	-- the one in colour -- emerald, lime-edged, under the stall artwork --
	-- because it is the one the owner wants found. BATS and TRAPS take the
	-- hotbar chip's amber and orange as their edges.
	--==========================================================================
	DockFill = Color3.fromRGB(18, 26, 36),
	DockEdge = Color3.fromRGB(74, 178, 172),
	DockHandle = Color3.fromRGB(242, 238, 206),
	TileTop = Color3.fromRGB(46, 56, 72),
	TileBottom = Color3.fromRGB(26, 32, 44),
	IndexEdge = Color3.fromRGB(120, 190, 245),
	SettingsEdge = Color3.fromRGB(176, 188, 204),
	ShopTileTop = Color3.fromRGB(52, 140, 76),
	ShopTileBottom = Color3.fromRGB(20, 82, 46),
	ShopEdge = Color3.fromRGB(162, 236, 96),
	--==========================================================================
	-- EVENTS (2026-10-04): NO ARTWORK YET, SO ITS WORD ON A SLAB
	--
	-- Index and Shop are the owner's square pictures; there is no EVENTS one.
	-- Until there is, EventsUI draws a slab (UIKit.railButton) in this violet
	-- -- apart from the blue, green and amber faces -- with "EVENTS" on it in
	-- outlined white. MISSING ASSET: an approved EVENTS button picture in the
	-- rail-buttons style (art/ui/rail-buttons, 256 px). Its id goes in
	-- EventsArt, and the button becomes an ART button like Index and Shop.
	--==========================================================================
	EventsFace = Color3.fromRGB(150, 96, 224),
	EventsShade = Color3.fromRGB(96, 56, 170),
	EventsArt = "",
	--==========================================================================
	-- WHAT'S NEW (2026-10-05, UpdateLogUI): NO ARTWORK, SO A SLAB AND ITS WORD
	--
	-- The EVENTS button's family: a square slab, a scroll drawn from frames
	-- (UIKit.scrollIcon, a native stand-in) and its word in outlined white. The
	-- face is the menus' sky -- secondary, navigation (BagLook.SkyBottom /
	-- SkyEdge, written out here because the Rail is read before the BagLook) --
	-- apart from EVENTS' violet beside it. MISSING ASSET: an approved WHAT'S NEW
	-- button picture in the rail-buttons style. The NEW dot is the rail badge's
	-- red (Badge, above), UpdatesDot px across.
	--==========================================================================
	UpdatesFace = Color3.fromRGB(76, 166, 222),
	UpdatesShade = Color3.fromRGB(22, 66, 100),
	UpdatesWord = "UPDATES",
	UpdatesDot = 14,
	--==========================================================================
	-- A WORD UNDER EVERY RAIL PICTURE UNTIL IT LOADS (2026-10-09, the owner:
	-- "some buttons are invisible like the garden and inventory")
	--
	-- Garden, the Bag, Index, Shop and INVITE are pictures on a transparent
	-- button, so one that does not load here -- a fetch that fails, a CDN
	-- hiccup, an upload held in moderation -- drew nothing: the button was gone.
	-- Each now stands its plain word on a slate plate (the dock tile's TileTop
	-- and TileBottom, the rail's black Outline) UNDER its pictures
	-- (UIKit.railFallback): shown until one of them has loaded HERE, and for
	-- good if none ever does. Settings keeps its gear drawn from frames
	-- instead; EVENTS (until its picture comes) and WHAT'S NEW are slabs with
	-- their words on already. The hotbar's Bag cell says BAG the same way.
	--==========================================================================
	Words = {
		Garden = "GARDEN",
		Bag = "BAG",
		Index = "INDEX",
		Shop = "SHOP",
		Invite = "INVITE",
		Events = "EVENTS",
	},
	FallbackOutline = 2,
	FallbackTextMax = 14,
	FallbackTextMin = 7,
}

--==============================================================================
-- THE EVENTS PANEL (2026-10-04, EventsUI and EventsModel)
--
-- The experience events the owner has POSTED on Roblox, read on the client
-- with SocialService -- nothing here names an event, a date or a picture --
-- and the native reminder prompt. It only advertises: no event's schedule
-- starts, ends or announces anything in the game.
--
--   CacheSeconds   the list is asked for again on opening once it is older
--   Retries        how many more tries a failed list request gets, after
--   RetryDelays    these pauses -- then the panel says it failed, with RETRY
--   RsvpSeconds    a reminder status read is trusted this long
--   TickSeconds    how often an open panel re-reads the clock (countdowns, an
--                  event starting or ending while it is open)
--   TrustSlack     how far the times may disagree with Roblox's own started /
--                  ended flags at fetch before the times are not shown
--==============================================================================
GameConfig.ExperienceEvents = {
	CacheSeconds = 120,
	Retries = 2,
	RetryDelays = { 2, 5 },
	RsvpSeconds = 60,
	TickSeconds = 1,
	TrustSlack = 120,
}

--==============================================================================
-- WHAT'S NEW (2026-10-05, UpdateLog / UpdateLogUI)
--
-- The words are Shared/UpdateLog's, the owner's to edit; these are the panel's
-- and the button's rules:
--
--   Shown       how many of the newest entries the panel lists
--   NewDays     the button wears its NEW dot while the newest entry's date is
--               fewer than this many days old -- and only until the player
--               opens the panel this session. A "seen" that survived a rejoin
--               would need a saved profile field: deliberately NOT added.
--   TitleMax / BulletMax / MinBullets / MaxBullets
--               the shape every entry keeps (UpdateLogSpec): a short title and
--               2 to 5 one-line bullets
--==============================================================================
GameConfig.UpdateLog = {
	Shown = 6,
	NewDays = 3,
	TitleMax = 32,
	BulletMax = 64,
	MinBullets = 2,
	MaxBullets = 5,
}

--==============================================================================
-- THE PANEL, WHICH IS NOT A SHOP THING
--
-- Index, Shop and Garden are one modal in three costumes, so the chrome they
-- share lives in its own table rather than inside GameConfig.Shop. It sat there
-- while the shop was the only panel and it stopped being true the moment the
-- other two stopped sliding in from the edges.
--
--==============================================================================
-- IT WAS BLACK, AND A BLACK RECTANGLE IS NOT A SURFACE
--
-- The fill was rgb(26,28,41) -- a very dark navy sampled off the reference
-- shots. Faithful, and on a screen it read as a hole cut out of the game: the
-- diamond lattice was there at 0.55 transparency and simply could not be seen,
-- so three panels of a garden game looked like three empty boxes.
--
-- Warm dark soil instead, shaded. Not invented: SeedData.SOIL is 124,76,50 and
-- MapService lays its beds at 158,82,52, so this is those two taken down into
-- shadow -- the same dirt the plants grow out of, seen from underneath a lid.
--
--     fill    rgb( 58, 38, 29)     shaded soil, the top of the gradient
--     shade   rgb( 38, 25, 19)     and the bottom of it
--     lattice rgb(132, 88, 62)     a soil HIGHLIGHT, lighter than the fill
--
-- DARKER THAN THE CARDS, ALWAYS. A card has to sit ON the panel, so the panel
-- has to be the darkest thing in the modal. Measured as relative luminance:
--
--     panel fill        42          panel shade       27
--     Index locked      50          Index seen        68
--
-- The lattice is a LIGHTER line on a DARKER fill now, which is what makes it
-- legible at all -- the old arrangement was a barely-lighter navy on navy. Pitch
-- comes down from 34 to 22, nearer the rail's 18, so a panel reads as a field of
-- diamonds rather than as four stray scratches. Still quieter than any card or
-- buy button sitting on it: the texture is behind the content, never with it.
--==============================================================================
GameConfig.Panel = {
	Fill = Color3.fromRGB(58, 38, 29),
	Shade = Color3.fromRGB(38, 25, 19),
	Outline = Color3.fromRGB(0, 0, 0),
	Lattice = Color3.fromRGB(132, 88, 62),
	LatticeSpacing = 22,
	LatticeTransparency = 0.55,
	-- The scrollbar and the thin inner lip: light enough to find on the fill.
	Edge = Color3.fromRGB(126, 96, 76),
	Title = Color3.fromRGB(255, 255, 255),

	--==========================================================================
	-- THE CLOSE BUTTON IS THREE REDS, NOT ONE
	--
	-- It was a single flat rgb(255,0,0) -- the sampled value off the reference
	-- shot, and the one colour in this palette that is not a colour so much as a
	-- channel turned all the way up. Flat maximum red against warm brown reads
	-- as a warning rather than as a control, and it was the only chrome on a
	-- panel with no light on it at all.
	--
	-- Three now, which is what every other button in this game already is: a lit
	-- face, a darker foot, and a shade under it. The sampled 255,0,0 is kept in
	-- this note as the record of where the button came from.
	--==========================================================================
	CloseTop = Color3.fromRGB(216, 68, 60),
	CloseBottom = Color3.fromRGB(152, 30, 26),
	CloseShade = Color3.fromRGB(112, 20, 18),
}

--==============================================================================
-- THE SHOP'S PALETTE
--
-- The panel, the outline and the close button were sampled off the owner's
-- three reference shots -- `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` --
-- with a pixel sampler rather than off a first impression. Those stay.
--
--     panel        rgb( 26, 28, 41)   very dark navy, black outline
--     panel edge   rgb( 48, 50, 61)   the lighter inner lip
--     close        rgb(255,  0,  0)   white X, black outline
--
--==============================================================================
-- THE CARDS ARE NOT CYAN ANY MORE
--
-- They were rgb(0,247,237) -> rgb(0,116,229), sampled straight off the same
-- shots. Faithful, and wrong for this game: a cyan-to-blue tile with a
-- lime-green button is another simulator's shelf, and it sat two panels away
-- from an Index full of Greenhollow greens and creams. One HUD cannot be two
-- games.
--
-- A plot card sells DIRT AND ROWS, so it is green now -- the same leaf-and-stem
-- family the plants are drawn in -- with an amber button, which is the Garden
-- rail's colour and the one warm thing on the panel. Amber against green reads
-- at a glance; lime against green does not.
--
-- OWNED goes SLATE rather than green. When the available card was cyan, green
-- could mean sold; now that available IS green, an owned card has to stop
-- competing some other way, and going grey is what "you already have this"
-- looks like everywhere.
--
-- These are NOT ink / paper / accent, exactly like the corner HUD is not. A shop
-- panel is a large surface with its own internal contrast to manage.
--==============================================================================
--==============================================================================
-- THE ROBUX STOREFRONT
--
-- Four shelves: SPEED, CASH, PREMIUM PODS and PLANTS. The plot ladder used to
-- live in this panel and does not any more -- it is a board by the gate now, the
-- same as the mill's, because two upgrades reached two different ways was a
-- difference with no reason behind it.
--
--==============================================================================
-- A `product` OF 0 MEANS "NOT CREATED YET"
--
-- A Developer Product id can only be created in the Creator Dashboard, and an id
-- typed in from memory is an id that silently sells the wrong thing. Zero means
-- "not created yet": the shelf still draws the tile, the tile reads SOON, and
-- the button refuses. Fill an id in and that tile becomes live with no other
-- change anywhere.
--
-- WIRED 2026-09-11 from the owner's Creator Dashboard: all five cash packs, all
-- six speed packs and the x2 Money pass are live. Only the three pods are still
-- 0 and read SOON. The tile prices are the owner's list.
-- GetProductInfo, asked from the owner's own account in Studio, returned about
-- 0.4x of them for every product (cash1 8 against 19, speed6 319 against 799);
-- that was taken to be regional pricing, and the owner chose the list.
--
-- StoreService asserts at boot that no two entries share a non-zero id, because
-- a copy-pasted id is the one mistake here that charges for one thing and grants
-- another.
--
--==============================================================================
-- THE POD PRODUCTS ARE FIXED, NOT ROLLED
--
-- Each one names exactly what it gives -- a species and a tier -- and the server
-- grants that and nothing else. This is deliberate and it is a COMPLIANCE
-- position, not a design preference: a pod whose species or tier were rolled
-- would be a paid random item, which Roblox requires you to disclose and to
-- publish odds for. Every other pod in this game is rolled, and every one of
-- them is obtained by stealing rather than by paying.
--
-- If these ever become random, the experience questionnaire has to change with
-- them. Do not make that change here alone.
--
--==============================================================================
-- THE NUMBERS ARE A STARTING POINT
--
-- The speed and cash ladders are the reference shots' shape. They have NOT been
-- fitted to this economy -- a tier-1 mill trains at 20/sec, so +150K is about
-- two hours of it, and the owner's own save is past 2B on both counters. Expect
-- to move these once there is a beta to watch. The Robux prices on the live rows
-- are the owner's own; the SOON rows still carry the reference's.
--
-- `robux` IS ONLY WHAT THE TILE PRINTS. Roblox charges whatever the Dashboard
-- says, so a price changed there has to be changed here too, or the tile and
-- the purchase prompt will disagree.
--==============================================================================
export type StoreItem = {
	key: string,
	label: string,
	robux: number,
	product: number,
	kind: "speed" | "cash" | "pod" | "hatch",
	amount: number?,
	species: string?,
	tier: number?,
}

GameConfig.Store = {
	--== the shelves, in the order they are drawn ==--
	--==========================================================================
	-- A SHELF OWNS ITS COLOUR
	--
	-- `colour` is the heading. `top`/`bottom` are the tile's gradient and `rim`
	-- the bright edge around it -- which is the thing that makes the reference
	-- shelves read as shelves rather than as one wall of tiles. `accent` is the
	-- colour the AMOUNT is printed in, with the noun left white beside it.
	--==========================================================================
	Sections = {
		--======================================================================
		-- A SHELF OWNS ITS COLOURS
		--
		-- `colour` is the heading over the shelf; `top` and `bottom` are its
		-- tiles' gradient. From the owner's approved mockup of 2026-09-11: sky
		-- blue for speed, grass green for cash, warm gold for passes. Every tile
		-- wears the same ink keyline and the same lime button whatever its shelf.
		--
		-- The bright `rim` and the per-shelf `accent` went with the old tile: the
		-- keyline replaced the rim, and an amount's colour now comes from the
		-- size of the pack (GameConfig.Shop.AmountLow / AmountHigh), not from the
		-- shelf it is on.
		--======================================================================
		--======================================================================
		-- PASSES SITS AT THE TOP
		--
		-- `layout = "pass"` tells ShopUI these rows are Game Passes: each tile
		-- shows the pass's card art from `Cards`, and its button prompts a pass
		-- purchase rather than a Developer Product. A permanent entitlement goes
		-- first; that is the point of it.
		--======================================================================
		-- `studs` (2026-10-04): the shelf's colour as one of the owner's studded
		-- card uploads (BagLook.Studs), worn by every card on it.
		{ id = "Passes", heading = "PASSES", layout = "pass", studs = "gold",
			colour = Color3.fromRGB(255, 214, 64),
			top = Color3.fromRGB(255, 232, 117), bottom = Color3.fromRGB(202, 110, 8) },
		{ id = "Speed", heading = "SPEED", studs = "sky",
			colour = Color3.fromRGB(64, 226, 250),
			top = Color3.fromRGB(94, 231, 252), bottom = Color3.fromRGB(8, 126, 196) },
		{ id = "Cash", heading = "CASH", studs = "lime",
			colour = Color3.fromRGB(86, 232, 46),
			top = Color3.fromRGB(118, 245, 86), bottom = Color3.fromRGB(24, 138, 16) },
		--======================================================================
		-- "???" IS THE HEADING THE OWNER ASKED FOR
		--
		-- It was PREMIUM PODS. The shelf, its three items and their prices are
		-- unchanged -- only what the header prints. The approved mockup gives it
		-- no colour of its own, so its tiles keep their gold.
		--======================================================================
		{ id = "Pods", heading = "???", studs = "gold",
			colour = Color3.fromRGB(252, 220, 96),
			top = Color3.fromRGB(255, 238, 130), bottom = Color3.fromRGB(238, 170, 20) },
		--======================================================================
		-- PLANTS IS GONE, NOT HIDDEN
		--
		-- It was an empty shelf carrying a COMING SOON plate. The owner asked
		-- for it removed from the shop, so the section, its item list and its
		-- ComingSoon entry all went with it rather than being left behind as a
		-- disabled row somebody has to remember is deliberate.
		--
		-- Nothing else lost anything: plants are still grown, sold and indexed.
		-- The SHOP simply no longer advertises a shelf it cannot stock.
		--======================================================================
	},

	--==========================================================================
	-- NOTHING IS FLAGGED COMING SOON ANY MORE
	--
	-- PLANTS was the only entry, and the shelf has been removed rather than
	-- left standing empty. The table stays so a future shelf can be announced
	-- before it is stocked, and so ShopUI's empty-shelf branch keeps a reason
	-- to exist.
	--==========================================================================
	ComingSoon = {},

	--==========================================================================
	-- THE SHELF ART IS UPLOADED, NOT DRAWN
	--
	-- Every tile used to draw its own icon out of plain frames, because no image
	-- tool was available and inventing an asset id is worse than a rectangle.
	-- These are real ids returned by the upload pipeline for the fifteen PNGs in
	-- art/icons/tight -- keyed by the item's `key`, so a tile with no entry here
	-- falls back to no icon rather than to a wrong one.
	--
	-- TIGHT-CROPPED, not square. ScaleType.Fit scales a square image to the band's
	-- HEIGHT, so a square canvas made every icon as small as the shortest edge and
	-- threw away the width -- which is why the tiles read as empty next to the
	-- reference. Cropped to the object's own bounds, a wide shoe fills the band's
	-- width and a tall pod fills its height, which is what the reference does.
	--
	-- `comingSoon` is the plate on the empty PLANTS shelf, which has no item and
	-- therefore no key of its own.
	--==========================================================================
	Icons = {
		speed1 = "rbxassetid://135726423224390",
		speed2 = "rbxassetid://114410993760817",
		speed3 = "rbxassetid://119870542364353",
		speed4 = "rbxassetid://135967331922530",
		speed5 = "rbxassetid://113277929496901",
		speed6 = "rbxassetid://113755567466973",

		cash1 = "rbxassetid://87550812316788",
		cash2 = "rbxassetid://71606957709509",
		cash3 = "rbxassetid://113035737316029",
		cash4 = "rbxassetid://115379046300186",
		cash5 = "rbxassetid://125540317398172",

		pod1 = "rbxassetid://136330649728985",
		pod2 = "rbxassetid://135956805691493",
		pod3 = "rbxassetid://81480489766629",

		comingSoon = "rbxassetid://84399068852963",
	},

	--==========================================================================
	-- CARDS ARE NOT ICONS
	--
	-- `Icons` above are small objects drawn INTO a tile the UI builds. A card is
	-- the whole tile -- background, title and benefit line are painted into the
	-- artwork -- so it is a separate table rather than a fifteenth icon, and the
	-- UI draws only a purchase button on top of it.
	--
	-- 3:2, and the artwork deliberately leaves its lower right quarter calm so
	-- that button has somewhere to sit. Anything laid over the LEFT of this card
	-- covers the money bundles; anything above the midline covers the title.
	--==========================================================================
	Cards = {
		x2money = "rbxassetid://114365661955846",
	},

	Items = {
		--======================================================================
		-- A GAME PASS, NOT A DEVELOPER PRODUCT
		--
		-- Every other row in this table is a Developer Product: bought over and
		-- over, granted once per receipt, and reconciled by StoreService against
		-- a saved ledger. This one is not. The benefit is PERMANENT, so it is an
		-- account entitlement Roblox already stores and answers for, and the
		-- right question is "does this player own it" rather than "have we
		-- honoured this receipt yet".
		--
		-- That is why the field is `pass` and not `product`. StoreService skips
		-- anything without a `product`, so this row can never reach the receipt
		-- path by accident, and PassService is the only thing that reads it.
		--
		-- `multiplier` is the number EconomyService multiplies the plant faucet
		-- by. It lives here so the shelf and the payout cannot disagree about
		-- what was sold -- and it is applied to the FAUCET ONLY: not to bag
		-- sales, not to Robux cash packs, not to refunds, not to admin grants.
		--
		-- pass = 0 is "not created yet": the card reads SOON and the button
		-- refuses. The card goes live on a real pass id ALONE and then prints
		-- `robux`, so the two are filled in together -- a live card with robux
		-- still at 0 would advertise the pass as free. Wired 2026-09-11 with the
		-- owner's pass, printed at 79: the price Roblox returned for it on the
		-- owner's account.
		--
		-- 79 WAS THE OWNER'S REGIONAL PRICE, NOT THE PASS'S. That account reads
		-- about 0.4x of list on every product (Instant Hatch 39 against 99, the
		-- speed packs the same), and every other tile prints list. An Xbox tester
		-- saw 79 on the card and 199 in Roblox's prompt, which charges list.
		-- Corrected 2026-09-24 to 199, read from the public product-info API
		-- (PriceInRobux 199, "Permanent 2x Earn", for sale) -- the Dashboard price
		-- itself was not changed and nothing was bought.
		--======================================================================
		Passes = {
			{ key = "x2money", label = "\u{00D7}2 MONEY", robux = 199, pass = 1975418369,
				kind = "pass", multiplier = 2 },
		},
		Speed = {
			{ key = "speed1", label = "+150K SPEED", robux = 29, product = 3712094350, kind = "speed", amount = 150e3 },
			{ key = "speed2", label = "+1M SPEED", robux = 79, product = 3712094432, kind = "speed", amount = 1e6 },
			{ key = "speed3", label = "+10M SPEED", robux = 149, product = 3712091968, kind = "speed", amount = 10e6 },
			{ key = "speed4", label = "+50M SPEED", robux = 299, product = 3712092016, kind = "speed", amount = 50e6 },
			{ key = "speed5", label = "+500M SPEED", robux = 599, product = 3712092058, kind = "speed", amount = 500e6 },
			{ key = "speed6", label = "+1B SPEED", robux = 799, product = 3712092103, kind = "speed", amount = 1e9 },
		},
		Cash = {
			-- Amount and noun, like the speed rows, so the tile prints the amount in
			-- colour and CASH in white. They were bare figures ("$24,000").
			{ key = "cash1", label = "$24K CASH", robux = 19, product = 3712092213, kind = "cash", amount = 24e3 },
			{ key = "cash2", label = "$200K CASH", robux = 39, product = 3712092272, kind = "cash", amount = 200e3 },
			{ key = "cash3", label = "$800K CASH", robux = 89, product = 3712092458, kind = "cash", amount = 800e3 },
			{ key = "cash4", label = "$4M CASH", robux = 179, product = 3712092533, kind = "cash", amount = 4e6 },
			{ key = "cash5", label = "$8M CASH", robux = 279, product = 3712092621, kind = "cash", amount = 8e6 },
		},
		--======================================================================
		-- Species and tier are BOTH named, so nothing about the outcome is a
		-- roll. Greenhollow commons at the low end and the biome's Epic at the
		-- top, which is the shape of a reward ladder rather than a lottery.
		--======================================================================
		Pods = {
			{ key = "pod1", label = "GIANT NUBKIN", robux = 79, product = 0,
				kind = "pod", species = "nubkin", tier = 5 },
			{ key = "pod2", label = "TITAN PETALPIP", robux = 189, product = 0,
				kind = "pod", species = "petalpip", tier = 6 },
			{ key = "pod3", label = "COLOSSAL BELLCHIME", robux = 449, product = 0,
				kind = "pod", species = "bellchime", tier = 7 },
		},
	},

	--==========================================================================
	-- SOLD IN THE WORLD, NOT ON A SHELF
	--
	-- Developer Products that ShopUI never draws. Each one is offered by a
	-- ProximityPrompt on the thing it acts on, because that is the only place
	-- the offer means anything: "hatch this pod now" is not a shop tile.
	--
	-- StoreService indexes this list exactly like the shelves -- the same ledger,
	-- the same duplicate-id check, the same product = 0 rule -- so a product here
	-- is granted by the same receipt path as a Speed pack.
	--
	-- INSTANT HATCH. The owner asked for it on 2026-09-15 at 99 Robux. It opens
	-- the pod the player pressed it on, clock or no clock; PlantService decides
	-- which pod that was (see PlantService.InstantHatch). The owner created the
	-- Developer Product on 2026-09-17 and gave its id, 3713212811, so the prompt
	-- now charges. A product id of 0 would still be legal: the prompt draws with
	-- its price and a press only says why in the server log.
	--==========================================================================
	InWorld = {
		{ key = "instanthatch", label = "INSTANT HATCH", robux = 99, product = 3713212811,
			kind = "hatch" },
	},
}

--==============================================================================
-- WHAT A GAME PASS IS WORTH, AND HOW THE CLIENT FINDS OUT
--
-- PassService writes the player's total cash multiplier onto the Player as an
-- attribute. Attributes replicate, so the three places that print an income
-- figure can multiply by it without a remote, a request or a wait.
--
-- THE SERVER DOES NOT READ THIS BACK. EconomyService asks PassService directly.
-- A client that overwrites its own copy changes what its own HUD says and
-- nothing else -- which is worth stating plainly, because an attribute that
-- looked authoritative would be an obvious place to try.
--==============================================================================
GameConfig.Pass = {
	MultiplierAttribute = "CashMultiplier",

	--==========================================================================
	-- THE HUD INDICATOR
	--
	-- A small card beside the cash line that says the multiplier is running. It
	-- is COSMETIC AND NOTHING ELSE: it reads the attribute above, which the
	-- server publishes, and it never decides or reports a payout. EconomyService
	-- multiplies the faucet from PassService's own table and does not look here.
	--
	-- The icon is a transparent cutout uploaded from art/icons/x2_money_buff.png
	-- via art/icons/x2_money_buff-256.png -- 256 square, because it draws at 46
	-- and a 1254px texture for a 46px icon is memory nobody sees (rule 8).
	--
	-- The message is stated here rather than in the client script so the words a
	-- player is shown are data, not a string literal buried in layout code.
	--==========================================================================
	BuffIcon = "rbxassetid://111194752241888",
	BuffSize = 46,
	BuffMessage = "Earn x2 money permanently.",
	BuffSeconds = 2.5,
	BuffFade = 0.25,
}

--==============================================================================
-- Display only. `SeedData.IncomePerSecond` stays pass-agnostic on purpose: it
-- is the plant's intrinsic worth and the Index prints it for species the player
-- may not own, where a personal multiplier would be nonsense. Anything showing
-- what THIS player earns multiplies by this; anything showing what a PLANT is
-- worth does not.
--==============================================================================
function GameConfig.cashMultiplier(player: Player?): number
	if not player then
		return 1
	end
	local n = tonumber(player:GetAttribute(GameConfig.Pass.MultiplierAttribute))
	-- Absent while PassService is still asking Roblox, and a hostile or stale
	-- value is not worth trusting either: anything below 1 would let a display
	-- under-report, which is the direction that looks like a bug.
	if not n or n < 1 then
		return 1
	end
	return n
end

--==============================================================================
-- LAUNCH ANALYTICS (2026-09-27): WHAT Metrics MAY SEND, AND FOR WHOM
--
-- Measurement only. Nothing here changes a rule, a reward or a price; the
-- server module SeedGameServer/Metrics reads it, and KB/ANALYTICS.md says what
-- every event means and where to read it.
--==============================================================================
GameConfig.Metrics = {
	-- The switch for every custom event and funnel step. Off: nothing is sent,
	-- nothing is counted, and gameplay is exactly the same.
	Enabled = true,
	-- THE NEW-PLAYER COHORT: a save first written on or after this moment
	-- (os.time, 2026-09-27 00:00 UTC). A returning player -- any save older
	-- than this, even one whose guide is unfinished -- never enters the
	-- onboarding funnel, so it cannot be restarted or falsely completed.
	CohortSince = 1790467200,
	-- The two admin accounts' own play stays out of every report.
	ExcludeStaff = true,
	-- ...unless this is on, and then their actions send ONE event instead,
	-- MetricsValidation, naming what would have been sent -- so the pipeline can
	-- be watched arriving in Creator Hub's View Events without adding a single
	-- count to a real report. Off for launch.
	StaffValidation = false,
	-- Per server: at most this many analytics calls a minute. Roblox allows
	-- 120 + 20 x players; the game sends a handful per raid, so this is a ceiling
	-- for a bug, not a budget anybody should meet.
	PerMinute = 60,
	-- SPEED BANDS against the biome's BiomeData.RecommendedSpeed: under 80% is
	-- "below", 80% to under 125% "near", 125% and up "above". A biome that
	-- recommends nothing (Greenhollow) is "none".
	BelowShare = 0.80,
	AboveShare = 1.25,
	-- The Floating Garden's run events (ObbyRun funnel, ObbyCheckpoint,
	-- ObbyRunEnded). On since the course was built and verified, 2026-09-27;
	-- with GameConfig.Obby.Enabled off there is no run to report anyway.
	Obby = true,
}

--==============================================================================
-- THE FLOATING GARDEN OBBY (2026-09-27): ITS ONE SWITCH
--
-- Everything else about the course -- where it floats, what it pays, how fast
-- you move on it -- is in Shared/ObbyData. `Enabled = false` switches the whole
-- thing off on the server: no course is built, no entrance, nobody can start,
-- and ObbyUI finds nothing to draw. Nothing else has to be touched.
--==============================================================================
GameConfig.Obby = {
	Enabled = true,
}

--==============================================================================
-- THE BONUS CHEST (2026-09-27 launch pass)
--
-- A free chest in the safe hub. The owner's launch configuration, kept in one
-- block so the feature has one switch and one place to read:
--
--   * the first claim opens when the guide's first loop is done, at the first
--     hatch (TutorialData.FirstLoopDone; the guide's step 7, the travel lesson,
--     comes after it, 2026-10-08);
--   * after a claim the next one opens CooldownSeconds later;
--   * each claim grants ONE reward below, weighted equally -- a 50/50 that the
--     chest shows before anybody claims;
--   * a reward runs for BoostSeconds and never stacks: a claim REPLACES, it
--     does not add time (and the cooldown outlasts the boost anyway);
--   * the cooldown and the expiry are absolute server times, os.time(), saved
--     on the profile -- so they keep elapsing while the player is away, and a
--     rejoin can neither reset one nor extend the other.
--
-- No movement-speed reward, no Robux, no rerolls, no streaks, no paid skips.
--
-- `Enabled = false` SWITCHES THE WHOLE THING OFF on the server: no chest is
-- built, every claim is refused, and a boost already saved on a profile stops
-- paying (see bonusChestMultiplier). Nothing else has to be touched.
--
-- WHERE EACH REWARD LANDS, AND NOWHERE ELSE
--
--   income    EconomyService.RateFor -- passive plant income, the same number
--             the x2 pass multiplies, so the two MULTIPLY: x2 becomes x2.5.
--             Not sales, not Robux cash packs, not the offline claim, not a
--             Biome Harvest: none of those come through RateFor.
--   training  TreadmillService's payout -- Speed earned on the belt, on the
--             mill's own rate. Not purchases, not admin grants, not WalkSpeed
--             directly.
--==============================================================================
GameConfig.BonusChest = {
	Enabled = true,
	CooldownSeconds = 600,
	BoostSeconds = 120,
	Rewards = {
		{ Id = "income", Multiplier = 1.25, Weight = 1,
			Title = "+25% PLANT INCOME", Detail = "passive plant income" },
		{ Id = "training", Multiplier = 1.25, Weight = 1,
			Title = "+25% TRAINING", Detail = "Speed earned on your treadmill" },
	},
	-- The answer to a claim, on the existing GameEvent remote. The claim itself
	-- is the chest's ProximityPrompt, settled on the server: no client verb.
	ReplyAction = "BonusChestResult",
	Attributes = {
		-- True once the guide is finished (and the chest is on at all).
		Unlocked = "ChestUnlocked",
		-- os.time() at which the next claim opens.
		NextAt = "ChestNextAt",
		-- The running reward's Id, and the os.time() it ends; nil when none.
		Boost = "ChestBoost",
		EndsAt = "ChestBoostEndsAt",
	},
	FolderName = "SeedBonusChest",
	-- In the shop row (2026-10-10, Map.Stall's comment): the back row, in the
	-- gap between the wheel and the invite pedestal, facing north (180 turns
	-- the chest's front from -Z to +Z), its prompt sharing ground with no
	-- other (EventHubSpec). It stood on the hub deck's west side from
	-- 2026-09-27. Y is the grass the plinth stands on.
	Position = Vector3.new(-193, 0, -127),
	FacingDegrees = 180,
	PromptDistance = 10,
	PromptHoldSeconds = 0.35,
	--==========================================================================
	-- THE WORDS THAT FLOAT OVER IT (2026-09-30, the owner's ask; reworked
	-- 2026-10-01)
	--
	-- "FREE CHEST" in gold, up through the cooldown as well as when it is ready,
	-- with that player's own state under it: ReadyText when they can claim, the
	-- time left (WaitText and the clock) while it recharges, OpeningText while
	-- their claim is on its way. Hidden altogether while it is LOCKED (the guide
	-- unfinished): nothing advertises a chest that player cannot open. Drawn like
	-- the wheel's "SPIN THE WHEEL!" (FloatingSign), one plain colour. The chest
	-- can give different rewards, so the words never call it a boost.
	--
	-- Width, Height and SubHeight are the lines' boxes in studs; the words come
	-- out 1.9 studs tall, just under the wheel's 2.0, and the second line 1.
	-- Above is the middle of both over the chest's pivot, over the board behind
	-- it (whose rim tops out at 7.45), so the board and the prompt stay clear.
	--==========================================================================
	FloatingWords = {
		Text = "FREE CHEST",
		Colour = Color3.fromRGB(255, 211, 77), -- #FFD34D
		Width = 11,
		Height = 1.9,
		SubHeight = 1,
		Above = 9.8,
		Behind = 2.6,
		ReadyText = "READY TO CLAIM!",
		WaitText = "NEXT IN ",
		OpeningText = "OPENING...",
	},
}

function GameConfig.bonusChestReward(id: any): any
	if type(id) ~= "string" then
		return nil
	end
	for _, reward in ipairs(GameConfig.BonusChest.Rewards) do
		if reward.Id == id then
			return reward
		end
	end
	return nil
end

--==============================================================================
-- THE STARBLOOM TEASER (2026-10-01, the owner's ask)
--
-- Words over the road's last wall, for everybody, all the time: a visual teaser
-- only -- no date, no new biome, no door, nothing a player can do with it.
-- Shared/StarbloomTeaser draws it in the floating words' look (FloatingSign),
-- each client's own. Sizes in studs:
--
--   Width, Height, SubHeight   the two lines' boxes: letters about 6.5 and 3.6
--                              tall, wide enough that the height decides
--   Above, OffWall             its middle over the road, and off the wall's face
--   Distance                   drawn from this far: the whole Starbloom segment
--   Glow*                      a copy of the headline behind it with a wide,
--                              half-clear lavender edge -- steady, no motion
--   Light*                     a soft lavender light on the wall behind it
--==============================================================================
GameConfig.StarbloomTeaser = {
	Text = "BEYOND THE STARS…",
	SubText = "NEW BIOME · COMING SOON",
	Colour = Color3.fromRGB(201, 167, 255), -- lavender #C9A7FF
	SubColour = Color3.fromRGB(255, 211, 77), -- the FREE CHEST gold #FFD34D
	GlowThickness = 6,
	GlowTransparency = 0.55,
	LightBrightness = 1.4,
	LightRange = 26,
	Width = 64,
	Height = 6.5,
	SubHeight = 3.6,
	Above = 17,
	OffWall = 10,
	Distance = 320,
}

--==============================================================================
-- THE WEATHER TEASER'S PICTURES (2026-10-06, the owner's brief)
--
-- The screen at the road mouth (Shared/WeatherTeaser) teases the next event
-- with the owner's two pictures in turn -- A, green, three silhouettes; B,
-- blue, five -- and the creatures in them slowly breathing. Each picture was
-- cut into layers (output/event-teaser-2026-10-06/layers.json, from the
-- 1672 x 941 copies): a background with the creatures painted out (the ground
-- shadows kept) and one cut-out per creature, left to right, each made against
-- what lies beneath it, so the layers drawn at rest ARE the picture. Every id
-- is the owner's upload to the CrazyCozy Games group.
--
--   Source            the pictures' size in pixels; every Rect, Feet and Badge
--                     is in these pixels, and the screen shows all of it
--   Rect              x, y, w, h of the cut-out in its picture
--   Feet              the point that stays put: the middle of the cut-out's
--                     lowest band (the bird's standing foot, not its tail; the
--                     spiky one floats, so its tentacle tips)
--   Badge             the "?": centre x, y, and its radius plus 8 pixels
--   Period, Phase     the breath's cycle in seconds (3.5 to 6, no two alike)
--                     and where in it the creature is at time 0, as a fraction
--   Bob               the hover, a fraction of the height, upward only; only
--                     the one that floats -- every other one stands on the floor
--   Hold, Fade        seconds each picture holds, and the crossfade between
--   EaseIn            the clock's first seconds ease in from rest, so time 0
--                     is each picture exactly as drawn (the server's frame)
--   Breath, BreathX   the breath: height x (1 + Breath); width x (1 + Breath x
--                     BreathX), slightly less
--   Sway              the lean, in degrees either way, about the feet
--   SwayPeriod        the lean's cycle, as a multiple of the breath's
--   BobPeriod         the hover's cycle, likewise
--   GlowMax           how white the soft haze over the "?" gets at the top of
--                     a breath; GlowReach its radius, x the "?"'s own
--   Glow              each picture's colour, behind SOON
--
-- Measured on the cut-outs at every extreme of breath, lean and hover: the
-- silhouettes stay inside the screen and never touch a neighbour (closest
-- 3 pixels, B's serpent and robot, 11 apart at rest; only rim glows meet).
--==============================================================================
GameConfig.WeatherTeaser = {
	Source = Vector2.new(1672, 941),
	Hold = 8,
	Fade = 1.5,
	EaseIn = 2,
	Breath = 0.025,
	BreathX = 0.6,
	Sway = 1.5,
	SwayPeriod = 1.6,
	BobPeriod = 1.3,
	GlowMax = 0.25,
	GlowReach = 1.45,
	Words = { Soon = "SOON" },
	Ink = Color3.fromRGB(16, 21, 28),
	Scenes = {
		{
			Name = "A",
			Background = "rbxassetid://108987983355390",
			Glow = Color3.fromRGB(64, 232, 150),
			Creatures = {
				{ Image = "rbxassetid://89476211121024", Rect = { 52, 21, 699, 807 }, Feet = { 368.5, 818 },
					Badge = { 481, 540.5, 66.5 }, Period = 5.6, Phase = 0.1 },
				{ Image = "rbxassetid://139403382929852", Rect = { 772, 175, 377, 660 }, Feet = { 957, 826 },
					Badge = { 961.5, 495.5, 62.5 }, Period = 4.4, Phase = 0.55 },
				{ Image = "rbxassetid://94766727026749", Rect = { 1185, 246, 428, 604 }, Feet = { 1391, 841 },
					Badge = { 1398, 579, 90 }, Period = 4.9, Phase = 0.8 },
			},
		},
		{
			Name = "B",
			Background = "rbxassetid://112662331303116",
			Glow = Color3.fromRGB(64, 156, 255),
			Creatures = {
				{ Image = "rbxassetid://124789383294317", Rect = { 16, 165, 409, 624 }, Feet = { 211, 779 },
					Badge = { 230.5, 455.5, 44.5 }, Period = 5.2, Phase = 0.3 },
				{ Image = "rbxassetid://105049401486153", Rect = { 355, 317, 401, 460 }, Feet = { 567, 768 },
					Badge = { 563, 526.5, 62.5 }, Period = 4.1, Phase = 0.05 },
				{ Image = "rbxassetid://85864328194602", Rect = { 672, 208, 355, 404 }, Feet = { 834, 599 },
					Badge = { 846.5, 373.5, 41.5 }, Period = 5.9, Phase = 0.65, Bob = 0.03 },
				{ Image = "rbxassetid://99819334779640", Rect = { 885, 268, 492, 525 }, Feet = { 1139, 784 },
					Badge = { 1148.5, 549.5, 57.5 }, Period = 3.7, Phase = 0.45 },
				{ Image = "rbxassetid://126484898711252", Rect = { 1289, 204, 370, 550 }, Feet = { 1431.5, 745 },
					Badge = { 1425.5, 487.5, 44.5 }, Period = 4.7, Phase = 0.9 },
			},
		},
	},
}

--==============================================================================
-- WHAT A SAVED BOOST IS WORTH TO ONE KIND OF EARNING, AT ONE MOMENT
--
-- The reward's Multiplier while `now` is before `endsAt` and the boost is of
-- this `kind`; exactly 1 otherwise -- and always 1 with the chest switched off.
-- Pure, so the server's faucets and the client's displays ask the same question
-- and a spec can ask it without a world.
--==============================================================================
function GameConfig.bonusChestMultiplier(boostId: any, endsAt: any, now: number, kind: string): number
	if not GameConfig.BonusChest.Enabled or boostId ~= kind then
		return 1
	end
	local reward = GameConfig.bonusChestReward(boostId)
	local ends = tonumber(endsAt)
	if not reward or not ends or ends ~= ends or now >= ends then
		return 1
	end
	return reward.Multiplier
end

-- Display only, like cashMultiplier: the chest's INCOME boost this player is
-- running, off the attributes the server publishes and the server's clock.
function GameConfig.chestIncomeBoost(player: Player?): number
	if not player then
		return 1
	end
	local A = GameConfig.BonusChest.Attributes
	return GameConfig.bonusChestMultiplier(player:GetAttribute(A.Boost), player:GetAttribute(A.EndsAt),
		workspace:GetServerTimeNow(), "income")
end

-- Display-only mirror of the server's saved sacrifice boost. The server
-- publishes the multiplier and absolute expiry, so no balance number is
-- duplicated in GameConfig and the client never grants itself income.
function GameConfig.sacrificeIncomeBoost(player: Player?): number
	if not player or not GameConfig.Sacrifice.Enabled then
		return 1
	end
	local A = GameConfig.Sacrifice.Attributes
	local endsAt = tonumber(player:GetAttribute(A.EndsAt))
	local multiplier = tonumber(player:GetAttribute(A.Multiplier))
	if not endsAt or not multiplier or multiplier <= 1
		or workspace:GetServerTimeNow() >= endsAt then
		return 1
	end
	return multiplier
end

--==============================================================================
-- WHAT THIS PLAYER'S PASSIVE INCOME IS MULTIPLIED BY, FOR A DISPLAY
--
-- The pass and the rebirths' bonus (the two permanent ones, as withPass pays
-- them) times the sum of active temporary income bonuses -- exactly what
-- EconomyService.RateFor pays. The offline card multiplies the same two
-- permanent ones and nothing temporary.
--==============================================================================
function GameConfig.incomeMultiplier(player: Player?): number
	-- Temporary income bonuses add their percentages before the pass. A chest
	-- +25% and a sacrifice +50% therefore mean +75%, never a hidden compound.
	-- THE RAIN (2026-10-02) is the weather's own factor, not a player's boost:
	-- one x1.25 on the whole, exactly as EconomyService.RateFor applies it.
	return GameConfig.cashMultiplier(player) * GameConfig.rebirthIncomeOf(player)
		* (GameConfig.chestIncomeBoost(player) + GameConfig.sacrificeIncomeBoost(player) - 1)
		* GameConfig.rainIncomeFactor()
end

--==============================================================================
-- THE MULTIPLIER A PLOT'S OWN PLANTS ARE PAID AT, FOR WHOEVER IS LOOKING
-- (2026-10-04, the overhead labels)
--
-- incomeMultiplier above is the LOOKER's: their pass, their chest, their
-- sacrifice. A plant in somebody else's bed is paid at its OWNER's, so a
-- label or a pop over it reads the plot's GardenBoost -- withPass x the
-- temporary boosts, which EconomyService publishes from the very tick that
-- pays -- times the rain's factor, which is the whole server's. Each once,
-- exactly as RateFor multiplies them. No profile is exposed: one number on the
-- plot, already there for the garden sign. Missing (x1, or the owner's garden
-- not back yet) reads as 1.
--==============================================================================
function GameConfig.gardenIncomeMultiplier(plot: Instance?): number
	local boost = if plot then tonumber(plot:GetAttribute(GameConfig.Attributes.GardenBoost)) else nil
	if not boost or boost ~= boost or boost < 1 then
		boost = 1
	end
	return (boost :: number) * GameConfig.rainIncomeFactor()
end

-- Checked on load, like the Speed anchors: a boost that outlived the cooldown
-- would let two stack, and a reward with a bad weight would skew the 50/50 the
-- chest promises.
do
	local C = GameConfig.BonusChest
	assert(C.CooldownSeconds > 0 and C.BoostSeconds > 0, "BonusChest times must be positive")
	assert(C.CooldownSeconds >= C.BoostSeconds,
		"a Bonus Chest boost must end before the next claim opens -- boosts never stack")
	assert(#C.Rewards >= 1, "the Bonus Chest needs at least one reward")
	local seen: { [string]: boolean } = {}
	for _, reward in ipairs(C.Rewards) do
		assert(type(reward.Id) == "string" and not seen[reward.Id], "Bonus Chest reward ids must be unique")
		seen[reward.Id] = true
		assert(type(reward.Weight) == "number" and reward.Weight > 0, "Bonus Chest weights must be positive")
		assert(type(reward.Multiplier) == "number" and reward.Multiplier >= 1,
			"a Bonus Chest reward must not reduce anything")
	end
end

--==============================================================================
-- THE PLANT ALMANAC (THE INDEX)
--
-- The one verb the Index sends -- a claim for a biome's harvest bonus, which
-- AlmanacService settles -- and the redesigned panel's palette, from the owner's
-- approved botanical mockup (index_mockup_preview.png, 2026-09-11).
--==============================================================================
GameConfig.Almanac = {
	ClaimAction = "AlmanacClaim",

	Ink = Color3.fromRGB(16, 21, 28),
	HeaderTop = Color3.fromRGB(86, 237, 52), -- #56ED34
	HeaderBottom = Color3.fromRGB(30, 164, 12), -- #1EA40C
	CloseTop = Color3.fromRGB(255, 77, 77),
	CloseBottom = Color3.fromRGB(204, 20, 20),
	CloseShade = Color3.fromRGB(128, 12, 12),
	-- Deep moss, lighter at the top.
	BodyTop = Color3.fromRGB(23, 44, 28), -- #172C1C
	BodyBottom = Color3.fromRGB(18, 36, 22), -- #122416
	BodyLattice = Color3.fromRGB(46, 84, 54),
	BodyLatticeTransparency = 0.72,

	-- The inner panels: the biome card's frame, the grid well, the showcase.
	Well = Color3.fromRGB(12, 26, 16),
	WellEdge = Color3.fromRGB(58, 104, 66),
	Lime = Color3.fromRGB(86, 237, 52),
	LimeDeep = Color3.fromRGB(41, 191, 24),
	Gold = Color3.fromRGB(255, 214, 38),
	Cream = Color3.fromRGB(242, 238, 206),
	Muted = Color3.fromRGB(150, 176, 154),
	Slate = Color3.fromRGB(74, 86, 80),
	SlateDeep = Color3.fromRGB(46, 56, 50),

	--==========================================================================
	-- A CARD IS COLOURED BY ITS RARITY, GROWN OR NOT
	--
	-- Sunlit gradients, light at the top. The mockup names five; Mythic is the
	-- sixth this game's shelves actually use (Gloomlotus, Pyrelotus,
	-- Supernovus), in a rose that sits beside the Epic orchid without being it.
	--==========================================================================
	Rarity = {
		Common = { Color3.fromRGB(163, 230, 53), Color3.fromRGB(63, 98, 18) }, -- #A3E635 -> #3F6212
		Uncommon = { Color3.fromRGB(52, 211, 153), Color3.fromRGB(6, 78, 59) }, -- #34D399 -> #064E3B
		Rare = { Color3.fromRGB(56, 189, 248), Color3.fromRGB(7, 89, 133) }, -- #38BDF8 -> #075985
		Epic = { Color3.fromRGB(232, 121, 249), Color3.fromRGB(112, 26, 117) }, -- #E879F9 -> #701A75
		Legendary = { Color3.fromRGB(253, 224, 71), Color3.fromRGB(146, 64, 14) }, -- #FDE047 -> #92400E
		Mythic = { Color3.fromRGB(251, 113, 133), Color3.fromRGB(136, 19, 55) }, -- #FB7185 -> #881337
	},
	-- An undiscovered plant: the form, in one dark flat colour.
	Silhouette = Color3.fromRGB(26, 34, 30),
	-- The Speed half of a harvest, in the shop's Speed shelf blue.
	Sky = Color3.fromRGB(94, 231, 252),

	--==========================================================================
	-- THE STUDS ON THE MOSS
	--
	-- One soft white dot on a transparent tile, drawn by
	-- tools/art/almanac_dots.py into art/index/almanac-dots-64.png and uploaded.
	-- White in the file, so its colour and strength are the two numbers below.
	-- An empty id means the upload is missing, and the panel keeps the modal's
	-- lattice rather than showing a wrong id.
	--==========================================================================
	DotTexture = "rbxassetid://125265576644859",
	DotTile = 22,
	DotColour = Color3.fromRGB(96, 150, 104),
	DotTransparency = 0.6,

	-- The header's book tile, a lighter leaf than the banner behind it.
	MarkTop = Color3.fromRGB(150, 246, 118),
	MarkBottom = Color3.fromRGB(62, 196, 40),
	-- A biome tab that is not the one on show.
	TabIdleTop = Color3.fromRGB(38, 66, 44),
	TabIdleBottom = Color3.fromRGB(26, 48, 32),
	-- The showcase pedestal: moss on a stone foot, a lime glow ring between.
	PedestalMoss = Color3.fromRGB(74, 132, 60),
	PedestalStone = Color3.fromRGB(70, 62, 54),
	-- The CLAIM button's faces: lime to take, gold once taken, slate to wait.
	LimeShade = Color3.fromRGB(24, 122, 14),
	GoldDeep = Color3.fromRGB(214, 146, 12),
	GoldShade = Color3.fromRGB(140, 90, 8),
	SlateShade = Color3.fromRGB(30, 38, 34),

	--==========================================================================
	-- EACH BIOME'S PICTURE, BY ITS STABLE ID (2026-10-04, uploaded by the owner)
	--
	-- Replaces the generic emoji the biome selector used to wear (TabIcons).
	-- Drawn beside the biome's NAME -- the sidebar, the dropdown and its list,
	-- the progress row's heading, a detail page's biome line, a search card's
	-- corner -- square, Fit, on no plate. A picture that never loads leaves the
	-- name on its own (never the emoji back) and is reported once in the log
	-- (MenuKit.picture).
	--==========================================================================
	BiomeIcons = {
		greenhollow = "rbxassetid://93127507617364",
		dustbowl = "rbxassetid://116633509157008",
		tanglemire = "rbxassetid://122688457196300",
		-- Corrected 2026-10-04 (the owner's transcription: ...990 was a typo and 404s).
		emberroot = "rbxassetid://107859867107909",
		starbloom = "rbxassetid://118655354256131",
	},
}

--==============================================================================
-- THE HOTBAR: BOTANICAL SLATE & INK
--
-- Option A of the owner's hotbar exploration, approved 2026-09-11
-- (art/hotbar/reference/approved-hotbar-mockup.png). The strip was the last
-- surface on the HUD still in translucent soil browns under the Shop's and the
-- Almanac's charcoal slate, so it takes their plate, ink keyline and lattice.
--
--==============================================================================
-- V2, 2026-09-14: art/hotbar/reference/target-hotbar-v2.png
--
-- The same slate and ink, re-proportioned around the item. The tray carries
-- the texture and the cards go calm and darker than it; the preview is framed
-- to the silhouette instead of the bounding box; a round number badge and ONE
-- information chip sit in the top corners; the name gets real type; the Tool in
-- the hands is warm amber-green, lifted, with an IN HAND strip; the Bag is its
-- own cell after a small gap. Only LoadoutUI reads this block.
--==============================================================================
GameConfig.Hotbar = {
	--==========================================================================
	-- THE HOTBAR'S LOOK (2026-10-01, the owner's reference image)
	--
	-- A compact row of nearly square slots: a translucent charcoal plate with
	-- small rounded corners and a thin light-grey edge, the item large in the
	-- middle, a small white number in the top-left corner as plain text, narrow
	-- even spacing, and no tray, no shadow and no name on the slot. Since
	-- 2026-10-03 the slots are FREELY ASSIGNED shortcuts (HotbarSlots): ten on
	-- a desktop, five on a phone, saved by item id; the BAG cell is one more
	-- square at the end. Drawn by HotbarCard; placed by HudLayout; owned by
	-- LoadoutUI.
	--
	-- Colours keep the slate-and-ink family: the in-hand edge the warm
	-- amber-to-green keyline, the stack count the tickets' gold, the Bag's
	-- count the chest's green and amber. Since 2026-10-03 (the owner's approved
	-- inventory mockup) the plate is the Bag's dark FOREST slate rather than the
	-- Shop's blue charcoal, the edge a light sage slate, the number cream -- one
	-- set with the Bag (GameConfig.BagLook).
	--==========================================================================
	Ink = Color3.fromRGB(16, 21, 28), -- #10151C
	Plate = Color3.fromRGB(28, 40, 35), -- forest slate #1C2823
	PlateTransparency = 0.38,
	Edge = Color3.fromRGB(170, 192, 178), -- light sage slate #AAC0B2
	EdgeTransparency = 0.45,
	CardCorner = 6,
	CardStroke = 1,
	-- An empty slot is barely there: the key is still in its place.
	EmptyPlateTransparency = 0.84,
	EmptyEdgeTransparency = 0.86,
	EmptyNumeralTransparency = 0.55,
	-- Under a mouse: a brighter edge, a little bigger, a little higher.
	HoverEdgeTransparency = 0.1,
	HoverScale = 1.04,
	HoverLift = 2,
	-- Under a thumb: a brief sink.
	PressScale = 0.97,

	-- In your hands: the warm keyline, a lighter plate, an amber number, a lift.
	LitTop = Color3.fromRGB(255, 200, 64), -- #FFC840 warm amber
	LitBottom = Color3.fromRGB(126, 214, 72), -- #7ED648 botanical green
	LitThickness = 2,
	LitPlate = Color3.fromRGB(54, 68, 52),
	LitPlateTransparency = 0.22,
	HeldLift = 3,
	-- And a small amber diamond on the top-right corner (2026-10-03): the same
	-- "in hand" mark on a slot and on a Bag tile, so a rarity's coloured edge
	-- is never mistaken for the selection.
	Marker = Color3.fromRGB(255, 200, 64),
	MarkerSize = 8,
	-- The cooldown shade's transparency: deep, because the plate is dark.
	CooldownShade = 0.25,
	-- The preview's ambient light, a step brighter than the Bag's card light.
	PreviewAmbient = Color3.fromRGB(160, 164, 180),

	-- The number: plain cream text top left, amber while held, with a hairline
	-- of ink so it reads over a light item.
	Numeral = Color3.fromRGB(246, 242, 222),
	NumeralLit = Color3.fromRGB(255, 208, 92),
	NumeralSize = 12,
	NumeralInset = 4,
	NumeralOutline = 1.2,
	-- The stack count (the tickets' xN), bottom right, in the tickets' gold.
	StackColour = Color3.fromRGB(255, 206, 84),
	StackSize = 10,
	StackInset = 3,
	-- The rarity accent: a thin bar on the bottom edge, this share of the width,
	-- in the form's RarityColor. A hatched plant only; a pod's rarity is the
	-- hatch's reveal, and a weapon has none.
	AccentHeight = 2,
	AccentShare = 0.56,
	AccentBottom = 3,

	-- Feedback: a pop on equip and on an arrival, and a flash of the edge.
	BumpScale = 1.12,
	BumpSeconds = 0.18,
	FlashSeconds = 0.3,
	FlashArrived = Color3.fromRGB(150, 220, 96),
	FlashCleared = Color3.fromRGB(226, 118, 92),

	-- The words a FAINT slot shows (2026-10-03: a placeholder waiting for the
	-- first bat, trap or Spin Tickets), and the Bag's count colours: green while
	-- there is room, a calm amber when storage is full, slate while the profile
	-- is still loading.
	Tags = {
		bat = { text = "BAT", colour = Color3.fromRGB(255, 191, 36) }, -- amber #FFBF24
		trap = { text = "TRAP", colour = Color3.fromRGB(251, 146, 60) }, -- orange #FB923C
		ticket = { text = "TICKETS", colour = Color3.fromRGB(255, 206, 84) }, -- the tickets' gold
		pod = { text = "POD", colour = Color3.fromRGB(170, 182, 198) }, -- quiet slate
	},
	CountOpen = Color3.fromRGB(126, 214, 72),
	CountFull = Color3.fromRGB(255, 196, 76),
	CountLoading = Color3.fromRGB(170, 182, 198),

	-- Gui pixels. Square 64-px slots 4 px apart, the touch floor this strip has
	-- always kept; no tray (TrayPad 0). Five slots and the Bag: 410 wide.
	SlotWidth = 64,
	SlotHeight = 64,
	Gap = 4,
	TrayPad = 0,
	BottomGap = 10,
	-- The Bag cell, and the extra space before it (the list's gap either side
	-- of a spacer this wide).
	ChipWidth = 64,
	BagGap = 2,
	-- The preview's glass: nearly the whole slot, the number over its corner.
	PreviewInset = 3,
	PreviewTop = 4,
	PreviewHeight = 56,
	-- The silhouette's limiting axis spans this much of the glass.
	PreviewFit = 0.96,
	-- The Bag cell's icon and its count. BagIconImage (2026-10-09, the owner:
	-- "yes, hotbar bag cell too"): the owner's studded "inventory" button, the
	-- rail Bag's own picture (Rail.StuddedBagArt), drawn as the WHOLE cell; once
	-- it has loaded the cell's own plate and edge go (the owner: drop it, "so
	-- only the owner's tile shows"). The rail's satchel (Rail.BagIcon) on the
	-- plate stands in until it loads, and stays if it never does or this is "".
	-- Before: the satchel 129734693384327 (art/icons/inventory/bag-256.png).
	BagIconImage = "rbxassetid://100113253044275",
	BagIcon = 34,
	BagIconTop = 5,
	BagCountTop = 43,
	BagCountSize = 12,
	-- The Bag cell is dropped below this viewport width.
	ChipMinViewport = 420,

	-- The item's name, briefly above the strip on an equip and under a mouse:
	-- its band's height, its gap over the strip, its text, and how long an
	-- equip's stays. HudLayout keeps the band clear of notices and the cash.
	NamePopupHeight = 22,
	NamePopupGap = 4,
	NamePopupText = 13,
	NamePopupSeconds = 1.2,

	--==========================================================================
	-- A TRAP'S PLACEMENTS, AND ITS REMOVE BUTTON (2026-10-04, reusable traps)
	--
	-- The count of placements still available ("3x" .. "0x") stands under a
	-- trap's picture on every trap slot, bottom centre, in cream -- a warm red
	-- at 0x. It is the server's count (WeaponData.Trap.PlacedAttribute), shared
	-- by every trap type.
	--
	-- REMOVE is a small button just over the trap's own slot while at least one
	-- trap is out. HudLayout reserves a row for it between the strip and the
	-- item name's band (the band, the boost icons and the notices step up over
	-- it) only while it stands: RemoveHeight drawn, RemoveTouch tall as a
	-- touch screen's target, RemoveGap over the slot. LoadoutUI publishes that
	-- it stands on the local player's RemoveRowAttribute, which every HUD owner
	-- placed over the strip re-reads (HudLayout.measure).
	--==========================================================================
	TrapCountSize = 13,
	TrapCountBottom = 2,
	TrapCountColour = Color3.fromRGB(246, 242, 222),
	TrapCountEmpty = Color3.fromRGB(255, 132, 108),
	--==========================================================================
	-- THE TRIGGER COOLDOWN ON A TRAP SLOT (2026-10-05)
	--
	-- While one of the owner's traps has caught somebody in the last
	-- WeaponData.Trap.TriggerCooldownSeconds, EVERY trap slot is dimmed -- its
	-- picture at TrapCoolDim, the shade over it shrinking as the wait runs --
	-- and the seconds left stand over the picture, white with a dark keyline,
	-- above the "3x" (which keeps saying how many may go down once it ends).
	--==========================================================================
	TrapCoolSize = 18,
	TrapCoolColour = Color3.fromRGB(255, 255, 255),
	TrapCoolDim = 0.55,
	RemoveHeight = 18,
	RemoveTouch = 40,
	-- 8, not 4: a slot in the hands rises HeldLift and wears its in-hand
	-- diamond on its top corner, which met the plate at 4 (seen in Play).
	RemoveGap = 8,
	RemoveText = 11,
	RemoveWords = "REMOVE",
	RemoveEdge = Color3.fromRGB(226, 118, 92),
	RemoveRowAttribute = "SeedTrapRemoveRow",

	--==========================================================================
	-- THE COMPACT BELT: A PHONE
	--
	-- Four slots and the Bag, 52-px squares between the thumbstick and the
	-- jump button: 284 wide. Everything else is the desktop's. HudLayout lays
	-- this over the table above (hotMetrics), so a key missing here is the
	-- desktop's.
	--==========================================================================
	Compact = {
		SlotWidth = 52,
		SlotHeight = 52,
		ChipWidth = 52,
		NumeralSize = 10,
		NumeralInset = 3,
		PreviewInset = 2,
		PreviewTop = 3,
		PreviewHeight = 46,
		StackSize = 9,
		BagIcon = 28,
		BagIconTop = 4,
		BagCountTop = 35,
		BagCountSize = 11,
		HeldLift = 2,
		HoverLift = 1,
		NamePopupText = 12,
		MarkerSize = 7,
		TrapCountSize = 12,
		TrapCountBottom = 1,
		TrapCoolSize = 15,
		RemoveText = 10,
	},
}

--==============================================================================
-- THE CONTEXT SLOT (2026-10-10, the owner: "we can remove the hotbar while the
-- drop button appears, so the button will replace hotbar position, we could
-- also apply it while riding the mill for the minigame button too")
--
-- While a raid pod is carried the hands are full, so the hotbar steps aside and
-- DROP stands in its place; while the player rides their own mill, PLAY
-- MINIGAME does. The hotbar's rect stays reserved -- nothing else on the HUD
-- moves -- and the button stands centred in it (HudLayout.contextButton). Each
-- button's owner raises its own client-local attribute, YieldPrefix .. its
-- name, while it stands; LoadoutUI hides the strip, its number keys and LB / RB
-- while any is raised.
--==============================================================================
GameConfig.ContextSlot = {
	YieldPrefix = "SeedHotbarYield_",
	--==========================================================================
	-- DROP (Michael, on v1047, passed on by the owner: "Once you steal an egg
	-- from a nest, a red 'Drop' button appears at the bottom of the screen.
	-- Pressing it leaves the egg on the ground, allowing any other player in the
	-- server to pick it up."). The owner's picture (CrazyCozy Games, 1024 x 384,
	-- opaque 985 x 312, transparent corners), as tall as the strip at its own
	-- Aspect; Keys too (B on a controller is free: the hands are full). The
	-- GameEvent verb is Action; a press is the knock-down's own drop
	-- (CarryService.Drop) -- anyone may take the pod, until dusk. Presses closer
	-- than PressGap count once, on both sides.
	--==========================================================================
	Drop = {
		Image = "rbxassetid://77040710214310",
		Aspect = 1024 / 384,
		Action = "DropPod",
		Keys = { Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB },
		PressGap = 0.5,
	},
}

--==============================================================================
-- THE SLATE LOOK: the Bag's palette of 2026-10-03, kept whole
--
-- Botanical Slate & Ink, from the owner's approved mockup
-- (output/imagegen/podnappers-inventory-hotbar-style-v1.png): a cool, very dark
-- forest slate, warm cream type, a restrained green for what is chosen, amber
-- only where something is chosen. The compact menus and the Bag wore it until
-- the bright recolor below. It stays for what is NOT a menu -- the boost icons
-- and their popover on the HUD (BoostIconsUI) -- so the recolor never reaches
-- the HUD.
--==============================================================================
GameConfig.SlateLook = {
	Ink = Color3.fromRGB(9, 14, 12),
	Title = Color3.fromRGB(246, 242, 222),
	Well = Color3.fromRGB(13, 20, 17),
	WellTransparency = 0.12,
	WellEdge = Color3.fromRGB(72, 96, 84),
	Cream = Color3.fromRGB(246, 242, 222),
	Muted = Color3.fromRGB(176, 186, 166),
	Sheet = Color3.fromRGB(15, 23, 20),
	SheetEdge = Color3.fromRGB(100, 128, 112),
}

--==============================================================================
-- THE BAG'S LOOK -- AND EVERY COMPACT MENU'S (MenuKit) -- BRIGHT SINCE
-- 2026-10-04 (the owner's recolor brief, art/references/ui-recolor-2026-10-04)
--
-- Light and playful in place of the dark forest slate: a mint-to-cream shell
-- with a gentle vertical gradient; a fresh leaf-green header and green for
-- what is chosen; lively green main actions; calm sky-blue secondary controls;
-- warm gold for owned and done; a coral close; clean dark keylines; dark
-- forest type on the light plates. One copy, so the menus and the Bag cannot
-- drift apart. The Bag's TILES keep the hotbar's slate (GameConfig.Hotbar), as
-- they always have, so the Bag and the strip still read as one set.
--
-- WHICH TYPE IS WHICH. `Text` and `Muted` are for words ON these light plates.
-- `Cream` is still cream: the words on a DARK plate -- a Bag tile, the count
-- pill, a dark display window. A word that sits on something light never reads
-- Cream.
--==============================================================================
GameConfig.BagLook = {
	Ink = Color3.fromRGB(16, 30, 22),
	-- The shell (#F1FFF6 to #DCEEDF), its header band (#91E849 to #47B63B),
	-- the title (white, ink-outlined) and its sprout.
	ShellTop = Color3.fromRGB(241, 255, 246),
	ShellBottom = Color3.fromRGB(220, 238, 223),
	HeaderTop = Color3.fromRGB(145, 232, 73),
	HeaderBottom = Color3.fromRGB(71, 182, 59),
	Title = Color3.fromRGB(255, 255, 255),
	Leaf = Color3.fromRGB(126, 200, 92),
	Stem = Color3.fromRGB(86, 150, 66),
	-- The shell's texture: the house lattice, faint (UIKit.modal draws it).
	Lattice = Color3.fromRGB(150, 196, 162),
	LatticeTransparency = 0.72,
	-- The wells: the search box, the heart and the grid, a shade deeper than
	-- the shell, with a clear green keyline.
	Well = Color3.fromRGB(226, 241, 230),
	WellTransparency = 0,
	WellEdge = Color3.fromRGB(86, 132, 98),
	Placeholder = Color3.fromRGB(104, 126, 110),
	-- A category, a tab, a quiet button: pale and calm, a dark keyline; chosen,
	-- leaf green with white type, and the narrow amber mark.
	CatTop = Color3.fromRGB(252, 255, 253),
	CatBottom = Color3.fromRGB(220, 235, 226),
	CatEdge = Color3.fromRGB(56, 92, 68),
	CatOnTop = Color3.fromRGB(145, 232, 73),
	CatOnBottom = Color3.fromRGB(71, 182, 59),
	CatOnEdge = Color3.fromRGB(22, 70, 28),
	CatMark = Color3.fromRGB(255, 196, 64),
	CatText = Color3.fromRGB(30, 56, 40),
	CatTextOn = Color3.fromRGB(255, 255, 255),
	-- The count pill: a dark plate, so cream type.
	Count = Color3.fromRGB(38, 72, 48),
	CountTransparency = 0,
	-- The type (see WHICH TYPE IS WHICH): dark forest on the light plates, a
	-- softer forest for what is secondary, cream on the dark ones.
	Text = Color3.fromRGB(26, 50, 34),
	Muted = Color3.fromRGB(84, 108, 92),
	Cream = Color3.fromRGB(246, 242, 222),
	-- An amount on a light plate: income green, and the premium gold, both
	-- dark enough to read without an outline.
	Money = Color3.fromRGB(28, 140, 40),
	Premium = Color3.fromRGB(196, 124, 8),
	-- A Speed amount (the almanac's harvest), the shoe's blue taken down.
	Speed = Color3.fromRGB(28, 116, 196),
	-- The storage bar beside the footer's words.
	BarTrack = Color3.fromRGB(196, 218, 202),
	BarWidth = 120,
	BarHeight = 6,
	-- The tooltip, the menu, a sheet over a list.
	Sheet = Color3.fromRGB(250, 255, 251),
	SheetEdge = Color3.fromRGB(64, 104, 76),
	-- The main action (PLANT, EQUIP BEST, an eligible CLAIM): bright green on
	-- top, deeper below.
	ButtonTop = Color3.fromRGB(132, 230, 78),
	ButtonBottom = Color3.fromRGB(52, 162, 48),
	ButtonEdge = Color3.fromRGB(20, 72, 26),
	-- A secondary or navigating control: sky blue, kept apart from the green.
	SkyTop = Color3.fromRGB(172, 226, 250),
	SkyBottom = Color3.fromRGB(76, 166, 222),
	SkyEdge = Color3.fromRGB(22, 66, 100),
	-- Owned, done, claimed: warm gold (#FFD96B to #E5A82E), dark type.
	GoldTop = Color3.fromRGB(255, 217, 107),
	GoldBottom = Color3.fromRGB(229, 168, 46),
	GoldEdge = Color3.fromRGB(112, 70, 0),
	GoldText = Color3.fromRGB(58, 38, 4),
	-- Not pressable: flat and grey, never a colour any state uses. Its words
	-- dark enough to read (about 4.7:1 on the grey), still plainly muted.
	OffTop = Color3.fromRGB(226, 231, 228),
	OffBottom = Color3.fromRGB(200, 208, 204),
	OffEdge = Color3.fromRGB(140, 152, 146),
	OffText = Color3.fromRGB(78, 88, 84),
	-- A reward to take (CLAIM): a deeper, warmer gold than the owned state,
	-- so white words with an ink line stand on it.
	ClaimTop = Color3.fromRGB(255, 200, 64),
	ClaimBottom = Color3.fromRGB(232, 136, 16),
	ClaimEdge = Color3.fromRGB(104, 52, 0),
	-- The close: coral to red, a white X, a dark keyline.
	CloseTop = Color3.fromRGB(255, 122, 104),
	CloseBottom = Color3.fromRGB(222, 50, 50),
	CloseShade = Color3.fromRGB(150, 22, 30),
	-- A menu card: white to a breath of mint, a dark keyline; a grown plant's
	-- card takes a little of its rarity's colour at the top (MenuKit.cardTint),
	-- never so much that the creature or the rarity's own word fades into it.
	CardTop = Color3.fromRGB(255, 255, 255),
	CardBottom = Color3.fromRGB(232, 245, 236),
	CardEdge = Color3.fromRGB(44, 78, 56),
	CardEdgeTransparency = 0.25,
	CardTint = 0.24,
	-- The dark display window an almanac plant stands in: dark enough that an
	-- undiscovered plant's silhouette shows no more than it did.
	Window = Color3.fromRGB(20, 32, 25),
	--==========================================================================
	-- THE GLOBAL UI ART PASS (2026-10-04, art/references/global-ui-pass-
	-- 2026-10-04): one studded family for every menu.
	--
	-- THE RIM: a white to pale-cream header with faint raised studs and an ink
	-- rule, the title in white LuckiestGuy ON its top edge (`RimLift` px of the
	-- panel stand above the shell for it), the menu's own icon beside it, and a
	-- red studded close. The body below is clean: studs are an accent, never
	-- behind words.
	--==========================================================================
	RimTop = Color3.fromRGB(255, 255, 255),
	RimBottom = Color3.fromRGB(241, 246, 236),
	-- One stud scale everywhere (UIKit.studs): pitch and face in gui px.
	StudPitch = 18,
	StudSize = 9,
	-- On the white rim: a white face over a soft grey-green bevel.
	RimStud = Color3.fromRGB(255, 255, 255),
	RimStudShade = Color3.fromRGB(214, 224, 210),
	-- On the red close: a lighter red face over a deep red bevel.
	CloseStud = Color3.fromRGB(255, 112, 100),
	CloseStudShade = Color3.fromRGB(170, 28, 34),
	CloseStudPitch = 10,
	CloseStudSize = 5,
	-- On a primary (green) button, faint.
	GoStud = Color3.fromRGB(150, 236, 96),
	GoStudShade = Color3.fromRGB(40, 140, 40),
	-- An uploaded, SEAMLESS stud tile for the rim, when there is one (see
	-- UIKit.studs): "" draws the studs in frames. NOT the atlas crops as they
	-- are -- their rows were measured not to wrap.
	RimStudImage = "",
	--==========================================================================
	-- THE COLOURFUL STUDDED CARDS (2026-10-04, the owner's six uploads,
	-- art/textures/colorful-studs-2026-10-04; MenuKit.studCard)
	--
	-- Group-owned Images, stored by Roblox at StudSource x StudSource (the
	-- 1254-px originals come back 1024). NOT seamless: a card shows a CROPPED
	-- window of one, with the card's own aspect, so a stud is StudCardPitch gui
	-- px across whatever the upload's spacing (`pitch`, measured, in stored px)
	-- -- the reference's fine studs, about seven across a Bag tile; never
	-- stretched, never tiled. A card wider than the picture allows that for (a
	-- Shop card, a phone's Shop row) gets larger studs rather than a seam.
	-- `top` / `bottom` (or `stops`, across) is the solid fallback drawn under
	-- the picture until it has loaded -- or for good, if it never does.
	--
	-- sky's id as sent (9169659369702) is no asset; 91696569369702 is the
	-- group's own studs-sky-blue-v1 from the same upload (found by name).
	--==========================================================================
	StudSource = 1024,
	StudCardPitch = 14,
	Studs = {
		sky = { image = "rbxassetid://91696569369702", pitch = 78.2,
			top = Color3.fromRGB(12, 209, 249), bottom = Color3.fromRGB(23, 155, 253) },
		gold = { image = "rbxassetid://106730544656733", pitch = 86.1,
			top = Color3.fromRGB(240, 210, 17), bottom = Color3.fromRGB(249, 155, 7) },
		purple = { image = "rbxassetid://103172630669031", pitch = 86.1,
			top = Color3.fromRGB(203, 45, 239), bottom = Color3.fromRGB(151, 27, 247) },
		coral = { image = "rbxassetid://133079221497449", pitch = 86.1,
			top = Color3.fromRGB(234, 73, 64), bottom = Color3.fromRGB(223, 31, 42) },
		lime = { image = "rbxassetid://134570572143730", pitch = 86.1,
			top = Color3.fromRGB(118, 236, 17), bottom = Color3.fromRGB(33, 203, 55) },
		-- The spectrum runs ACROSS: a card shows all of it (`wide`), and is used
		-- sparingly -- the one featured Shop pack and the Bloomrunner Trail.
		rainbow = { image = "rbxassetid://118707369966787", pitch = 71.7, wide = true,
			stops = { Color3.fromRGB(247, 61, 66), Color3.fromRGB(248, 180, 29), Color3.fromRGB(62, 238, 76),
				Color3.fromRGB(81, 128, 248), Color3.fromRGB(225, 39, 244) } },
		-- THE TOP THREE'S OWN (2026-10-10, Codex's art/textures/rarity-studs-
		-- 2026-10-10, the owner's uploads): pearl WHITE (the owner: Mythic's
		-- "background must be white"; Divine's too, "best pick for divine is
		-- white") and the colourful midnight holo for Secret. Same stud spacing
		-- as coral (measured 85.6 stored px, both). `words`: the words' ink
		-- backing on this card, denser than StudWordsTransparency -- cream
		-- words on a white card need a darker band than on a coloured one.
		-- `light`: a selection line ON the card is drawn dark, not white.
		pearl = { image = "rbxassetid://72726318027556", pitch = 86.1, words = 0.25, light = true,
			top = Color3.fromRGB(241, 240, 241), bottom = Color3.fromRGB(216, 219, 224) },
		holo = { image = "rbxassetid://78921871175240", pitch = 86.1,
			top = Color3.fromRGB(52, 40, 150), bottom = Color3.fromRGB(44, 20, 120) },
		-- Uploaded with them, worn by nothing yet: Secret's option A.
		obsidian = { image = "rbxassetid://94572104024955", pitch = 86.1,
			top = Color3.fromRGB(58, 64, 68), bottom = Color3.fromRGB(23, 26, 28) },
	},
	-- A card wears its RARITY's upload: Uncommon to Legendary the one nearest
	-- the rarity's own colour (GameConfig.RarityColor); since 2026-10-10 the
	-- three rarest their own (the owner: Mythic white, Secret "the colorful
	-- one", Divine white). Common's own colour is the plain card itself, so a
	-- Common keeps it. Bats and traps too (WeaponData's `Rarity`).
	StudsByRarity = { Uncommon = "lime", Rare = "sky", Epic = "purple", Legendary = "gold", Mythic = "pearl",
		Secret = "holo", Divine = "pearl" },
	-- The Bag's things that have no rarity: tickets the Shop's ticket violet,
	-- the jackpot trail the rainbow. (Bats and traps were coral until
	-- 2026-10-10; they wear their rarity's card now.)
	StudsByKind = { tickets = "purple", trail = "rainbow" },
	-- The Shop's featured pack: the only rainbow card in it.
	StudsFeatured = { spin10 = true },
	-- On a studded card the words stand on a quiet ink backing (StudWords,
	-- StudWordsTransparency); an income there is this brighter green.
	StudWords = Color3.fromRGB(10, 20, 16),
	StudWordsTransparency = 0.42,
	StudMoney = Color3.fromRGB(132, 240, 96),
	--==========================================================================
	-- THE BASEPLATE (2026-10-06, the owner: "a better studded texture
	-- background behind the products so it will not look plain white"): the
	-- Shop's and the Index's cards stand on a green studded plate, its studs
	-- raised the way the menus' rims are (UIKit.studs: a lighter face over a
	-- darker shade), PlatePitch apart, under a dark keyline. Drawn, not an
	-- upload: the six studded uploads are gradients that do not tile. A deep
	-- forest green: the light green tried first (122, 196, 108) left the lime
	-- cash cards green on green in Play; on this every card colour stands out.
	--==========================================================================
	PlateFill = Color3.fromRGB(58, 112, 66),
	PlateEdge = Color3.fromRGB(24, 52, 30),
	PlateStud = Color3.fromRGB(76, 140, 84),
	PlateStudShade = Color3.fromRGB(38, 80, 44),
	PlatePitch = 22,
	PlateStudSize = 12,
	--==========================================================================
	-- TYPE (the readability brief, art/references/ui-readability-2026-10-04)
	--
	-- Small words on a light plate are PLAIN: dark, no outline, in a clean
	-- medium face. FredokaOne is for names, labels and buttons; LuckiestGuy
	-- with a heavy ink outline is for a menu's title only. White on a coloured
	-- face keeps a thin ink line.
	--==========================================================================
	BodyFont = Enum.Font.GothamMedium,
	BodyBoldFont = Enum.Font.GothamBold,
	-- Card titles and labels.
	LabelFont = Enum.Font.FredokaOne,
	-- A menu title, by screen.
	TitleSize = 28,
	TitleSizeShort = 23,
	TitleStroke = 3,
	--==========================================================================
	-- THE BAG'S TILES (the readability brief): opaque, deeper emerald slate in
	-- place of the hotbar's see-through plate, so the light names read and the
	-- silhouettes keep their dark ground. The hotbar keeps its own plate.
	--==========================================================================
	TileTop = Color3.fromRGB(40, 74, 58),
	TileBottom = Color3.fromRGB(22, 44, 34),
	TileEdge = Color3.fromRGB(12, 26, 18),
	TileHeld = Color3.fromRGB(58, 98, 64),
	--==========================================================================
	-- MORE FACES: remove / destroy (red), premium (violet), and the controller's
	-- focus ring (gold, thick, on every light or dark plate).
	--==========================================================================
	DangerTop = Color3.fromRGB(255, 112, 100),
	DangerBottom = Color3.fromRGB(214, 44, 48),
	DangerEdge = Color3.fromRGB(96, 12, 18),
	PremiumTop = Color3.fromRGB(196, 150, 255),
	PremiumBottom = Color3.fromRGB(126, 74, 206),
	PremiumEdge = Color3.fromRGB(58, 24, 110),
	Focus = Color3.fromRGB(255, 204, 40),
	-- A button's darker foot under its lit face (the close's three reds).
	FootShare = 0.16,
	-- THE APPROVED CATEGORY ART (2026-10-03): art/icons/inventory/<name>-256.png,
	-- cropped from output/imagegen/podnappers-inventory-category-icons-v1.png.
	-- Uploaded by the owner 2026-10-03. A picture shows once it has actually
	-- LOADED here (UIKit.whenPictureLoads); until then, or if it never does, the
	-- frame-drawn icon below stays, and "" keeps it for good -- never a blank.
	--   all = all_items-256.png   plants = plants-256.png   pods = pods-256.png
	--   equipment = equipment-256.png   tickets = spin_tickets-256.png
	IconImages = {
		all = "rbxassetid://97250543670622",
		plants = "rbxassetid://113964771900247",
		pods = "rbxassetid://88009836282641",
		equipment = "rbxassetid://136563245084953",
		tickets = "rbxassetid://112516668911937",
	},
	-- An uploaded picture's size in a category button (a drawn icon is 18): 20
	-- keeps all five labels on one line at the shared size (fitLabels).
	IconImageSize = 20,
	-- The drawn fallbacks: the pod and leaf greens, the bat's woods, the
	-- tickets' gold.
	IconLeaf = Color3.fromRGB(132, 204, 96),
	IconVein = Color3.fromRGB(58, 112, 46),
	IconWood = Color3.fromRGB(176, 124, 76),
	IconGrip = Color3.fromRGB(92, 60, 38),
	IconTicket = Color3.fromRGB(255, 206, 84),
	IconTicketInk = Color3.fromRGB(107, 74, 0),
}

--==============================================================================
-- EVERY MENU'S TITLE PICTURE (2026-10-04, the global UI art pass)
--
-- The approved uploads that stand beside each menu's title on the studded rim
-- -- chosen from art the owner already approved, never a new upload -- and,
-- written down, the two menus that have none of their own:
--
--   shop       the rail's former cart picture (Rail.ShopIcon), superseded ON THE
--              RAIL by the whole-button art and approved artwork all the same
--   almanac    the Bag's plants category picture, as before
--   plants     MY PLANTS: the rail's Garden pot
--   bag        the rail's satchel
--   settings   the rail's gear
--   admin      NO ADMIN ART: the Settings gear stands in (unchanged)
--   events     NO EVENTS ART (Rail.EventsArt is ""): a calendar drawn from
--              frames (UIKit.calendarIcon) stands in -- an asset gap
--   marigold   NO MARIGOLD ART: the Bag's equipment picture (a bat) stands in
--   sell       the cash pack's picture
--   sacrifice  the pedestal's own source icon
--==============================================================================
--==============================================================================
-- THE STUDDED UI KIT'S LOOK (2026-10-08, the owner: "restyle the shop and
-- settings first")
--
-- Read off the owner's StuddedUI-Free.rbxm (RBLX Essentials; use in this game
-- is allowed, the kit itself is never redistributed -- it is not in the repo):
-- a menu is a coloured studded header band, a white studded body, an outline
-- and a solid base in the band's dark tone, a red studded close, and a white
-- title with a black line. Only the look is taken -- every control, layout and
-- font stays the game's own. MenuKit.studdedTheme builds UIKit.modal's theme
-- from these; each menu names its own band and edge.
--
--   Texture       the kit's stud tile (its rbxassetid), tiled at Tile px
--   BandStuds     its transparency over a header band and the close
--   BodyStuds     its transparency over the white body
--   Base          the solid base under the panel, in px below the shell
--==============================================================================
GameConfig.StuddedLook = {
	Texture = "rbxassetid://118347284107187",
	Tile = 90,
	BandStuds = 0.5,
	BodyStuds = 0.85,
	Body = Color3.fromRGB(255, 255, 255),
	Base = 5,
	Close = Color3.fromRGB(255, 32, 70),
	CloseEdge = Color3.fromRGB(120, 10, 28),
	Title = Color3.fromRGB(255, 255, 255),
	TitleLine = Color3.fromRGB(0, 0, 0),
	Shop = { Band = Color3.fromRGB(255, 53, 67), Edge = Color3.fromRGB(133, 13, 27) },
	Settings = {
		Band = Color3.fromRGB(24, 143, 255),
		Edge = Color3.fromRGB(0, 57, 132),
		-- Settings' rows: the kit's dark blue strips, white words.
		Row = Color3.fromRGB(23, 89, 165),
		RowEdge = Color3.fromRGB(0, 57, 132),
		RowText = Color3.fromRGB(255, 255, 255),
		RowDetail = Color3.fromRGB(196, 222, 255),
		-- A muted row's state word ("MUTED", "OFF"), quieter but still light.
		RowMuted = Color3.fromRGB(150, 178, 216),
	},
	-- The kit has no Index and no Bag (2026-10-08, the owner: "do the index and
	-- bag next"): the Index wears the kit's Pets / collection green, the Bag its
	-- Trade Inventory cyan.
	Index = { Band = Color3.fromRGB(52, 217, 135), Edge = Color3.fromRGB(9, 106, 67) },
	Bag = { Band = Color3.fromRGB(33, 187, 235), Edge = Color3.fromRGB(7, 87, 118) },
	-- The Reward Wheel's chrome (2026-10-08, the owner: "let claude terminal do
	-- the wheel too"), from the kit's Spin screen: its purple (SKIP, +10 SPINS)
	-- for Reward info's band and the cards, its green SPIN for the buying and
	-- spending buttons, and a dark purple strip under each prize row and the
	-- footer so their light words read on the white studded body. The blue is
	-- Settings', the red the kit's close. The wheel's own art is untouched.
	Wheel = {
		Band = Color3.fromRGB(169, 91, 255),
		Edge = Color3.fromRGB(78, 28, 134),
		Go = Color3.fromRGB(85, 255, 0),
		Row = Color3.fromRGB(52, 32, 82),
	},
}

--==============================================================================
-- SPROUT DASH (2026-10-08, the owner: "when player rides the mill, a play
-- minigame button appears, then when opened, a screen of the game will open,
-- so it will not affect the jump" -- "let claude terminal build it")
--
-- A 2D runner played on the player's OWN mill (not the Disco Mill): the sprout
-- runs a treadmill strip, a tap / click / Space / pad A hops it over rocks,
-- weeds and logs, seed coins are picked up, the speed ramps, three hits end
-- the run, and the next run is free. The DISTANCE earns a short +25% training
-- boost of its own (Boost), added to the Bonus Chest's / the wheel's.
--
-- THE SERVER DECIDES (Shared/SproutDash, SproutDashService): it hands each run
-- a seed; the client sends only the ticks it hopped on; the server replays the
-- fixed-step simulation from the seed and those hops and pays what IT counts.
-- A run counts only ridden on the player's own mill from start to end.
--
-- Values marked DEFAULT are the other session's proposals: owner calls.
--==============================================================================
GameConfig.SproutDash = {
	Enabled = true,
	-- The GameEvent action, and its two verbs (start, finish).
	Action = "SproutDash",
	Attributes = {
		-- os.time() the minigame's own training boost runs out (server-written).
		BoostEndsAt = "SproutBoostEndsAt",
		-- True while this client has the game's screen open (client-local).
		Open = "SproutDashOpen",
	},
	-- THE SIMULATION, in metres and seconds, stepped Hz times a second by the
	-- client to draw it and by the server to count it -- identical steps.
	Hz = 60,
	Start = 8, -- m/s
	Ramp = 0.15, -- m/s every second
	Top = 18, -- m/s
	Gravity = 40, -- m/s/s
	Hop = 13.5, -- m/s up: 0.675 s in the air, 2.28 m high
	Runner = { W = 0.8, H = 1.3 },
	Obstacles = {
		rock = { W = 1.0, H = 0.8 },
		weed = { W = 0.6, H = 1.2 },
		log = { W = 1.6, H = 0.6 },
	},
	-- THE COURSE, made from the seed a chunk at a time: one obstacle somewhere
	-- in [Edge, Chunk - Edge] of each chunk past Lead, so two are never closer
	-- than 2 * Edge (16 m: a hop at Top covers 12.2), and three seed coins.
	Course = { Lead = 40, Chunk = 32, Edge = 8, CoinR = 0.4 },
	Lives = 3, -- "until 3 hits, free replay"
	HitGrace = 1.0, -- s the sprout passes through after a hit
	-- CHEAP TO ASK, IMPOSSIBLE TO RUSH: a run is at most MaxSeconds of sim time
	-- and never more than the wall clock allowed (FinishSlack s of network);
	-- a new run at most every StartEvery s.
	MaxSeconds = 300,
	FinishSlack = 3,
	StartEvery = 2,
	-- THE REWARD (DEFAULT): +25% training for minutes by distance, at most
	-- BankMax s banked and HourMax s earned in any hour.
	Boost = {
		Multiplier = 1.25,
		Tiers = {
			{ Distance = 250, Minutes = 1 },
			{ Distance = 500, Minutes = 2 },
			{ Distance = 1000, Minutes = 3 },
			{ Distance = 2000, Minutes = 5 },
		},
		BankMax = 600,
		HourMax = 900,
	},
	-- THE ART: the owner's uploads (2026-10-08, CrazyCozy Games group Images);
	-- "" would bring back the frame stand-ins. Rects are in each STORED image's
	-- pixels, measured on the upload itself (EditableImage, alpha), so a new
	-- drop-in is config-only. The ground strip is the one layer that scrolls
	-- and repeats (made to tile). The backdrop does NOT tile: it is drawn once,
	-- still, behind the runner -- never scrolled, never repeated. Obstacles and
	-- coins scroll as sprites.
	Art = {
		-- sprout-dash-runner-v1: 1024 x 512, 4 x 2 cells of 256 (run 1-4 on top;
		-- hop, hit, ready, cheer below), facing right. The standing frames' feet
		-- are 32 px over each cell's foot, the tucked hop's 72 -- each frame is
		-- set down by its own feet. The standing drawing, feet to leaf tip, is
		-- about 157 px: that height is CFG.Runner.H on screen.
		Runner = {
			Image = "rbxassetid://134371957887780",
			Cell = 256,
			Baseline = 32,
			HopBaseline = 72,
			Tall = 157,
			Run = { Vector2.new(0, 0), Vector2.new(256, 0), Vector2.new(512, 0), Vector2.new(768, 0) },
			Hop = Vector2.new(0, 256),
			Hit = Vector2.new(256, 256),
			Ready = Vector2.new(512, 256),
			Cheer = Vector2.new(768, 256),
		},
		-- sprout-dash-props-v1-ORIGINAL (1774 x 887, stored 1024 x 512): the
		-- generation, not the 256-cell atlas, so its drawings fill their cells
		-- at their own sizes. Each is a tight rect (alpha > 10, a pixel spare);
		-- a ground prop's rect ends at its lowest row, which stands on the belt.
		-- An obstacle is drawn just big enough to cover its hitbox, so nothing
		-- that hits is ever unseen. `pot` has no obstacle yet.
		Props = {
			Image = "rbxassetid://87208780933422",
			rock = Rect.new(19, 66, 238, 240),
			weed = Rect.new(264, 44, 498, 242),
			log = Rect.new(517, 105, 766, 241),
			pot = Rect.new(780, 74, 1007, 239),
			heart = Rect.new(36, 301, 224, 464),
			heartEmpty = Rect.new(289, 300, 478, 463),
			dust = Rect.new(531, 339, 758, 466),
			spark = Rect.new(794, 264, 1000, 475),
		},
		-- sprout-dash-ground-v1: 1024 x 256, opaque; the belt's top (where the
		-- feet go) 48 px down.
		Ground = { Image = "rbxassetid://107251527164014", Size = Vector2.new(1024, 256), Top = 48 },
		-- sprout-dash-backdrop-v1: 1024 x 512, opaque, static.
		Backdrop = { Image = "rbxassetid://122111644752248", Size = Vector2.new(1024, 512) },
		-- The approved uploads already in the game.
		Coin = "rbxassetid://97002362837712",
		Burst = "rbxassetid://138957621639655",
	},
	-- The screen's band (DEFAULT: the kit's Upgrades orange).
	Look = { Band = Color3.fromRGB(255, 154, 34), Edge = Color3.fromRGB(153, 81, 20) },
	-- THE GAME'S OWN MUSIC: an empty slot. While THIS player has the screen
	-- open (Attributes.Open, client-local) Music.client crossfades the bed to
	-- Id over FadeSeconds, looping, and back to whatever the world asks for on
	-- close. On the one music Sound and bus, so the player's music level and
	-- mute and the chase bed's duck apply as to any bed. Volume is on the same
	-- scale as Music.Volume (0.32: the beds' own level). "" keeps the bed that
	-- was playing -- as now: the owner's 111742643280141, wired here first on
	-- 2026-10-09 (a misread of "sprout rush"), is Pod Rush's bed (the owner:
	-- "just pod rush"; Music.PodRushTrack).
	Music = { Id = "", Volume = 0.32, FadeSeconds = 1.5 },
	Words = {
		Button = "PLAY MINIGAME",
		Title = "Sprout Dash",
		Hint = "TAP or SPACE to hop",
		Over = "RUN OVER",
		Distance = "%s m",
		Coins = "%d",
		CoinTotal = "%d coins",
		Best = "Best today: %s m",
		Again = "PLAY AGAIN",
		Close = "CLOSE",
		Reward = "+%d min training boost!",
		NoReward = "Run %d m for a training boost",
		Capped = "Training boost full (10 min)",
		HourCapped = "15 boost minutes an hour: try later",
		Counting = "Counting...",
		OffMill = "Off the mill: the run ended",
	},
}

GameConfig.MenuIcons = {
	shop = GameConfig.Rail.ShopIcon,
	almanac = GameConfig.BagLook.IconImages.plants,
	plants = GameConfig.Rail.GardenIcon,
	bag = GameConfig.Rail.BagIcon,
	settings = GameConfig.Rail.SettingsIcon,
	admin = GameConfig.Rail.SettingsIcon,
	events = "",
	marigold = GameConfig.BagLook.IconImages.equipment,
}

--==============================================================================
-- WHERE A BOOST OR A REWARD CAME FROM, AS A PICTURE (2026-10-03)
--
-- The approved source icons, art/icons/boosts/<file>-256.png, cropped from
-- output/imagegen/podnappers-boost-weather-icons-v1.png, uploaded by the owner
-- 2026-10-03. StatusText draws one before a line's words (`source`) and
-- ActionToastUI before a notice's (`Notice.Post.icon`) once it has LOADED
-- here (UIKit.whenPictureLoads): until then, if it never does, or for an id of
-- "", the frame-drawn glyph the line or notice always had -- never a blank. Pictures only -- every amount, duration and stacking rule is
-- the server's, exactly as before, and the Rain and the Thunderstorm are one
-- +25% event showing one icon, whichever picture it wears (BoostIcons reads the
-- authoritative Workspace RainMode).
--
--   rain      rain-256.png             the Rain event's line and notices
--   thunder   thunderstorm-256.png     the same, while its mode is "thunder"
--   chest     free_chest-256.png       a Bonus Chest claim's notice
--   wheel     reward_wheel-256.png     the Reward Wheel's prize and claim notices
--   sacrifice sacrifice-256.png        the pedestal's boost line and its notice
--   income    plant_income-256.png     a +plant-income boost line (chest or wheel)
--   training  the BOOSTED SHOE (2026-10-08; was speed_training-256.png, which
--             stays the Speed icon as `speed` -- see below): a +training boost
--             line (chest or wheel)
--   community community_reward-256.png the community chest's claimed notice only
--   tickets   spin_tickets-256.png     the Ticket Shower's icon, its notices and
--                                      the "+1" over a player who took one: the
--                                      Bag's own Spin Ticket picture (BagLook)
--   disco     disco-256.png            the Disco's icon and its notices: the
--                                      owner's upload of art/icons/boosts/disco-
--                                      256.png (cropped from output/imagegen/
--                                      podnappers-disco-event-icon-v1.png), id given
--                                      2026-10-04 -- an Image, "disco-256", by the
--                                      CrazyCozy Games group. Never the disco AUDIO id.
--==============================================================================
--==============================================================================
-- SPEED AND TRAINING ARE TWO ICONS NOW (2026-10-08, the owner's TREADMILL FUN
-- addenda, relayed by the peer session)
--
--   speed      every place that SHOWS Speed: the HUD's Speed number, the Shop's
--              Speed shelf and items, the Index's Speed reward, the wheel's Speed
--              prizes and their notice, SpeedFX's "+N", and TREADMILL FUN's pop,
--              bar and badge. The owner's PLAIN SPEED SHOE, re-uploaded on
--              transparent (99714577637458, 512 x 512), with its SMALL version
--              (SmallIcons below) wherever it draws at 40 px or less. The first
--              two uploads (87020355715502, 137016623960738) were on opaque
--              black and are drawn nowhere; the old winged shoe 96656510808947
--              is no longer used.
--   training   the +25% TRAINING BOOST only (BoostIcons' training slot, the
--              wheel's boost_training sector and its line): the owner's BOOSTED
--              SHOE, green with flames, transparent.
--   coin       the belt's SEED COIN (BeltCatch), on its catch notices.
--   milestone  the MILESTONE BADGE (SpeedMilestones), on milestone notices.
--==============================================================================
GameConfig.SourceIcons = {
	rain = "rbxassetid://130178353004540",
	thunder = "rbxassetid://97835526705727",
	chest = "rbxassetid://134062175986179",
	wheel = "rbxassetid://120181822443205",
	sacrifice = "rbxassetid://120984862343497",
	income = "rbxassetid://131924246776637",
	speed = "rbxassetid://99714577637458",
	training = "rbxassetid://113941145748388",
	community = "rbxassetid://139312630119333",
	tickets = "rbxassetid://112516668911937",
	disco = "rbxassetid://129016824458756",
	coin = "rbxassetid://97002362837712",
	milestone = "rbxassetid://101850589009212",
	-- The owner's rebirth emblem (2026-10-09): the icon of the line everybody
	-- else in the server reads when somebody is reborn.
	rebirth = GameConfig.Rebirth.Art.Emblem,
	-- The owner's POD RUSH icon (2026-10-09): its announcement, its boost icon
	-- and its lines. Drawn by its crop (SourceIconCrops).
	podrush = GameConfig.PodRush.Art.Icon,
}

-- A source picture uploaded with a clear margin round it is drawn by its crop
-- wherever StatusText draws it (the notices, the boost icons): ImageRectOffset
-- and ImageRectSize in the upload's stored pixels.
GameConfig.SourceIconCrops = {
	podrush = { Offset = GameConfig.PodRush.Art.CropOffset, Size = GameConfig.PodRush.Art.CropSize },
}

--==============================================================================
-- THE OWNER'S SMALL VERSIONS (2026-10-08)
--
-- A picture with an entry here is drawn as its small upload wherever it draws
-- at SmallIconMax px or less -- the owner's rule for the plain Speed shoe. Keyed
-- by the big upload's id; SizedIcon picks between the two by the drawn size.
--==============================================================================
GameConfig.SmallIconMax = 40
GameConfig.SmallIcons = {
	-- The plain Speed shoe's small version, stored at 32 x 32.
	[GameConfig.SourceIcons.speed] = "rbxassetid://114664524232030",
} :: { [string]: string }

--==============================================================================
-- THE WHEEL'S POD SILHOUETTES, AS UPLOADED (2026-10-04)
--
-- WheelDraw draws every pod prize as black silhouettes of the real pods its
-- species pool can give. A biome with an id here is drawn as the owner's
-- upload of its crop in art/icons/wheel/ (cut from the approved
-- podnappers-spinwheel-actual-pod-silhouettes-v2.png; each picture carries its
-- own ivory rim and "?"); a biome without one keeps its frame-drawn silhouette
-- -- POD BY POD, so a prize mixes the two. Never an id that is not the owner's
-- upload of that crop, and never another biome's picture standing in.
--
--   greenhollow  wheel_pod_greenhollow-512.png, uploaded by the owner 2026-10-04
--   tanglemire   wheel_pod_tanglemire-512.png, uploaded by the owner 2026-10-04
--   starbloom    wheel_pod_starbloom-512.png, uploaded by the owner 2026-10-04
--   dustbowl     no picture yet: drawn in frames
--   emberroot    no picture yet (no wheel prize shows it today): frames
--==============================================================================
GameConfig.WheelPodArt = {
	greenhollow = "rbxassetid://121294253348295",
	dustbowl = "",
	tanglemire = "rbxassetid://122381169752786",
	emberroot = "",
	starbloom = "rbxassetid://106800317033952",
}

--==============================================================================
-- THE ACTIVE BOOST AND EVENT ICONS (2026-10-04, the owner's ask)
--
-- One compact row of round icons directly over the hotbar (HudLayout's `icons`
-- rect, above the item name's band), one per thing running for this player:
--
--   weather    the Rain or the Thunderstorm -- ONE icon for the event and its
--              +25% (its picture follows the server's RainMode)
--   disco      a Disco mode: the Disco Mill's x10 (Ticket Disco, DISCO + MILL)
--              or, for the pure DISCO ONLY, its movement boost
--   tickets    a Ticket mode (Ticket Disco, Ticket Shower Only), with this
--              player's count of the per-event limit on a small badge
--   podrush    a POD RUSH (2026-10-09), with this player's count banked on
--              its badge
--   income     a +plant-income boost (the Bonus Chest's or the Reward Wheel's --
--   training   a +training boost        one slot, the two cannot be told apart)
--   sacrifice  the Sacrifice Pedestal's garden-income boost
--
-- Read-only: every one is drawn from the server's own attributes and its
-- authoritative deadline, and no icon, tap or popover changes any modifier.
-- A tap (a click, or the controller's PadKey) opens a small popover ABOVE the
-- icon -- where it comes from, exactly what it does, the time left and what to
-- do -- one at a time; the same icon again, a tap anywhere else, B or the
-- PadKey past the last icon closes it. A faint ring round each icon empties as
-- its time runs out, a step a second (reduced motion drops only the popover's
-- rise). BoostIconsUI draws it; Shared/BoostIcons is the pure part.
--==============================================================================
GameConfig.BoostIcons = {
	-- Left to right.
	Order = { "weather", "disco", "tickets", "podrush", "income", "training", "sprout", "sacrifice" },
	-- The drawn icon (px, safe space) by HUD mode; never smaller than Min,
	-- however many there are. Gap between two.
	Size = { Desktop = 40, Compact = 34, Phone = 30, Min = 24 },
	Gap = 6,
	-- The player attribute BoostIconsUI keeps at how many icons stand in the
	-- row (nil for none), LOCAL to this client: HudLayout.measure reads it so
	-- the toast line steps up over the row, and ActionToastUI re-places on it.
	Attribute = "HudIcons",
	-- Opens the first icon's popover, then the next; past the last it closes.
	-- Free on every controller path (DPadUp TELEPORT, DPadLeft BIOMES, DPadRight
	-- OBBY).
	PadKey = Enum.KeyCode.DPadDown,
	-- The popover over the icon.
	Popover = { Width = 250, PhoneWidth = 214, Gap = 8 },
	-- True on the LocalPlayer (client-local) while the open popover has no place
	-- clear of the Pod Rush tracker too, and stands where it would without it:
	-- the tracker steps aside until it closes (2026-10-09, seen on a 705 x 338
	-- phone with the guide's card up).
	CoversAttribute = "SeedBuffPopoverCovers",
	Tints = {
		weather = Color3.fromRGB(150, 196, 255),
		disco = Color3.fromRGB(255, 160, 232),
		tickets = Color3.fromRGB(255, 214, 92),
		-- POD RUSH (2026-10-09): its gold.
		podrush = Color3.fromRGB(255, 204, 64),
		income = Color3.fromRGB(38, 255, 0),
		training = Color3.fromRGB(25, 144, 255),
		-- Sprout Dash's own training boost (2026-10-08): its screen's orange.
		sprout = Color3.fromRGB(255, 154, 34),
		sacrifice = Color3.fromRGB(38, 255, 0),
	},
	-- What each popover says. %d / %s are filled in from the configs the
	-- servers pay by, never typed here.
	Words = {
		Rain = "Rain",
		Thunder = "Thunderstorm",
		WeatherEffect = "+%d%% plant income while it lasts",
		WeatherOpening = "A temporary biome is about to open east of the hub.",
		WeatherOpen = "A temporary biome is open east of the hub, over the bridge.",
		Disco = "Disco",
		-- The owner's own words (2026-10-04).
		DiscoEffect = "Disco Mill: \u{00D7}10 your normal treadmill training while mounted.",
		DiscoHint = "The giant Disco Mill stands in front of the hub, beside the road.",
		-- DISCO ONLY, the pure disco (2026-10-04, the owner's words): no mill, so
		-- never the x10 above; %d is the mode's own SpeedFactor as a percentage.
		-- "Up to" because MaxWalkSpeed (150) caps the boosted speed: a player
		-- already above 100 gains less (the owner's label, the same day).
		Party = "Disco Party",
		PartyEffect = "Up to +%d%% movement speed",
		Tickets = "Ticket Shower",
		TicketsEffect = "Free Spin Tickets are falling all over the map.",
		TicketsProgress = "Collected %d/%d this event. Walk over one to take it.",
		TicketsCapped = "All %d collected this event. Leave the rest for others.",
		-- POD RUSH (2026-10-09): the levels' pods, then this player's count.
		PodRush = "Pod Rush",
		PodRushEffect = "Bank pods taken from nests: %d bronze, %d silver, %d gold.",
		PodRushProgress = "%d banked this rush.",
		Boost = "Bonus Chest or Reward Wheel",
		IncomeEffect = "+%d%% plant income",
		TrainingEffect = "+%d%% treadmill training",
		BoostHint = "Claim the Bonus Chest again when it is ready.",
		Sacrifice = "Sacrifice Pedestal",
		SacrificeEffect = "+%d%% garden income",
		SacrificeHint = "Sacrifice at the pedestal again when it is ready.",
		Sprout = "Sprout Dash",
		SproutEffect = "+%d%% treadmill training",
		SproutHint = "Play Sprout Dash on your own mill for more.",
		EndsIn = "Ends in %s",
	},
}

GameConfig.Shop = {
	--==========================================================================
	-- THE APPROVED RESTYLE, 2026-09-11
	--
	-- From the owner's approved mockup (shop_mockup_preview.png), with
	-- art/shop/reference/target-shop-reference.png as the look it is after: a
	-- green header over a charcoal slate panel, so the coloured tiles are the
	-- brightest thing in the shop. The tiles' own gradients are per shelf, in
	-- Store.Sections.
	--
	-- INK is the one dark: every keyline, every text outline, and the price on
	-- its white capsule. A black with a little blue in it rather than 0,0,0,
	-- which is what the mockup draws and what keeps an outline on charcoal from
	-- reading as a hole.
	--==========================================================================
	Ink = Color3.fromRGB(16, 21, 28),

	HeaderTop = Color3.fromRGB(78, 227, 44), -- #4EE32C
	HeaderBottom = Color3.fromRGB(37, 166, 17), -- #25A611
	CloseTop = Color3.fromRGB(255, 77, 77), -- #FF4D4D
	CloseBottom = Color3.fromRGB(204, 20, 20), -- #CC1414
	CloseShade = Color3.fromRGB(128, 12, 12),

	BodyTop = Color3.fromRGB(38, 44, 56), -- #262C38
	BodyBottom = Color3.fromRGB(24, 29, 38), -- #181D26
	-- A lighter slate held well back: texture sits behind the tiles and never
	-- competes with them.
	BodyLattice = Color3.fromRGB(74, 84, 102),
	BodyLatticeTransparency = 0.7,
	ScrollBar = Color3.fromRGB(96, 106, 124),

	--==========================================================================
	-- THE BUY BUTTON IS LIME ON EVERY SHELF
	--
	-- A lime plate with a white capsule holding the Robux mark and the price.
	-- It is the BUY colour, not the shelf's -- the same on sky blue and on grass
	-- green -- which is what makes it read as the button rather than as
	-- decoration. SOON is the same shape in slate, with a dark capsule.
	--==========================================================================
	PillTop = Color3.fromRGB(86, 237, 52), -- #56ED34
	PillBottom = Color3.fromRGB(41, 191, 24), -- #29BF18
	Capsule = Color3.fromRGB(255, 255, 255),
	SoonTop = Color3.fromRGB(126, 135, 150), -- #7E8796
	SoonBottom = Color3.fromRGB(89, 97, 110), -- #59616E
	SoonCapsule = Color3.fromRGB(47, 53, 66), -- #2F3542
	SoonText = Color3.fromRGB(170, 178, 192),

	--==========================================================================
	-- AN AMOUNT'S COLOUR SAYS HOW BIG THE PACK IS
	--
	-- Neon green under 50M, neon gold from 50M up, with the noun beside it white.
	-- Keyed on the row's own `amount`, so a new pack lands on the right side of
	-- the line with no second list to keep in step.
	--==========================================================================
	AmountLow = Color3.fromRGB(54, 244, 42), -- #36F42A
	AmountHigh = Color3.fromRGB(255, 214, 38), -- #FFD626
	AmountHighFrom = 50e6,

	-- Marigold's weapon stall reads these two; the Robux shop no longer does.
	Buy = Color3.fromRGB(250, 190, 46),
	BuyShade = Color3.fromRGB(186, 130, 20),
}

--==============================================================================
-- THE PLANT CARD
--
-- A card is a little diorama: a painted backdrop, a STILL 3D plant standing in
-- front of it, and two lines of type. The plant is the subject and everything
-- else is scenery.
--
--==============================================================================
-- THE CARD HAS NO TEXTURE OF ITS OWN, AND WILL NOT GET ONE
--
-- It carried a diamond lattice for one pass. The lattice is drawn from ROTATED
-- frames, and a rotated child escapes ClipsDescendants -- which is written up at
-- length in UIKit. Inside a ScrollingFrame that is not cosmetic: a half-scrolled
-- card threw its diamonds 342 pixels past the list and straight over the
-- Garden's footer.
--
-- A CanvasGroup contained it, but containing a bug is not fixing one. The card
-- surface is now a picture and nothing else. NO lattice, no studs, no diagonal
-- anything -- do not put rotated frames inside a scrolling card again.
--
-- The rail buttons and the modal panel keep theirs. Neither of them scrolls.
--
--==============================================================================
-- ONE PAINTED PLACE PER BIOME, BEHIND EVERY SPECIES THAT LIVES THERE
--
-- Five illustrated background plates -- woodland, dunes, swamp, basalt, nebula
-- -- supplied 2026-09-08 and mapped onto all twenty-five species by the road
-- they come off. Background scenery ONLY: no creature, no name, no rarity, no
-- border, nothing animated. The real static ViewportFrame plant stands in front.
--
-- Masters art/cards/backgrounds/biome1..5.png; the runtime copies are the
-- 512px <biome>-bg.png beside them, which is all a 116-151 pixel card can show.
--
-- BEFORE THIS, five Greenhollow species had bespoke procedural backdrops drawn
-- by tools/art/card_backdrops.py -- Nubkin's sunlit rows, Petalpip's meadow,
-- Spiretip's misty pines, Toadcap's rotting log, Bellchime's lanterns at dusk.
-- They are superseded rather than deleted: the script and the ids are still in
-- the repository, and the reason for dropping them is COHESION. Two art styles
-- in one collection -- soft procedural gradients on five cards and painted
-- scenes on twenty -- reads as a bug rather than as variety.
--
--   nubkin    rbxassetid://100196841981461     spiretip  rbxassetid://90680843858849
--   petalpip  rbxassetid://109778696165493     toadcap   rbxassetid://110972481430448
--   bellchime rbxassetid://106856602665628
--
-- A backdrop is IDENTITY, so it is withheld wherever identity is withheld: an
-- undiscovered Index card, a Garden pod and an empty hole all get the plain
-- dusk gradient below instead. Painting Emberroot's magma behind a ??? would
-- narrow the species to five as surely as printing the word.
--==============================================================================
GameConfig.Card = {
	Art = {
		--== GREENHOLLOW ==--
		nubkin = "rbxassetid://101119022870924",
		petalpip = "rbxassetid://101119022870924",
		spiretip = "rbxassetid://101119022870924",
		toadcap = "rbxassetid://101119022870924",
		bellchime = "rbxassetid://101119022870924",

		--== DUSTBOWL ==--
		dunebud = "rbxassetid://133554639098352",
		paddlehop = "rbxassetid://133554639098352",
		thornwhorl = "rbxassetid://133554639098352",
		raincup = "rbxassetid://133554639098352",
		suncrown = "rbxassetid://133554639098352",

		--== TANGLEMIRE ==--
		bogbonnet = "rbxassetid://127784202754052",
		crookreed = "rbxassetid://127784202754052",
		snapmoss = "rbxassetid://127784202754052",
		lanterncap = "rbxassetid://127784202754052",
		gloomlotus = "rbxassetid://127784202754052",

		--== EMBERROOT ==--
		cinderpaw = "rbxassetid://107428058230890",
		emberquill = "rbxassetid://107428058230890",
		slagbloom = "rbxassetid://107428058230890",
		kilnhusk = "rbxassetid://107428058230890",
		pyrelotus = "rbxassetid://107428058230890",

		--== STARBLOOM ==--
		novaorb = "rbxassetid://80623858180990",
		cosmospire = "rbxassetid://80623858180990",
		voidpetal = "rbxassetid://80623858180990",
		astralhorn = "rbxassetid://80623858180990",
		supernovus = "rbxassetid://80623858180990",
	},

	-- What a card shows when it may not show a place. Grey on purpose: it
	-- carries no information except "not yet".
	DuskTop = Color3.fromRGB(134, 136, 132),
	DuskBottom = Color3.fromRGB(92, 98, 92),

	--==========================================================================
	-- THE VIEWPORT
	--
	-- A still 3D copy of the real CreatureModel, lit from one side and shot from
	-- three-quarters so the form reads as volume rather than as a sticker. The
	-- creature faces -Z, so the camera sits in front of it, to the right and
	-- above.
	--
	-- FRAMED PER MODEL, not at a fixed distance. A Bellchime is more than twice
	-- a Nubkin's height and a fixed camera would leave one filling the card and
	-- the other a speck. Relative height is already told by the sheet and by the
	-- world; a card's job is to show the SHAPE.
	--==========================================================================
	--
	-- Pitch matters more than it sounds. At 0.52 the camera looked down hard
	-- enough to show the top of every head and turn the soil heap into a flat
	-- disc jutting out of the bottom of the frame; 0.28 is a three-quarter view
	-- of a creature rather than an aerial photograph of one.
	CameraOffset = Vector3.new(0.66, 0.28, -1),
	-- 0.94 cropped the soil heap off the bottom of several forms. Just over 1
	-- fits the whole model with a hair of air, which is what a portrait wants:
	-- the box already includes the heap, so there is no need to cut into it.
	CameraFill = 1.02,
	-- The visual mass sits above the geometric centre -- the heap is wide and
	-- low -- so the camera looks a little higher than the middle of the box.
	CameraRise = 0.08,
	Ambient = Color3.fromRGB(132, 134, 146),
	LightColour = Color3.fromRGB(255, 250, 236),
	LightDirection = Vector3.new(-0.45, -1, -0.62),
	--==========================================================================
	-- THE FACE AND UPPER BODY (2026-10-10, the owner: "can we zoom their
	-- appearance than using a whole body?" -- the Bag's tiles, the hotbar, MY
	-- PLANTS, the Index and the plot's board): a grown creature's picture
	-- frames everything from BelowEyes of its height under its eyes up --
	-- where its builder names its eyes (a part with "eye" in its name) -- or
	-- else its top TopShare; the rest is cut by the picture's edge. Each
	-- surface its own switch. A pod, a bat, a trap and the Index's big stage
	-- are never zoomed.
	--==========================================================================
	Zoom = {
		BelowEyes = 0.3,
		TopShare = 0.55,
		Bag = true,
		Hotbar = true,
		Plants = true,
		Board = true,
		Index = true,
		-- Per creature (2026-10-10, the owner: "fix the weak zooms on drizzlet
		-- and lotusling"): a window from Below to Above of its height round its
		-- eyes, for a creature whose crown stands far above its face --
		-- Drizzlet's cloud and canopy, Lotusling's petals -- so the face still
		-- fills the picture; what is above it is cut by the edge. `Wide`, if
		-- given: also no further than that share of its height to either side
		-- of its eyes (Lotusling's petals spread sideways too). A colossal form
		-- is the same shape bigger (measured: its eyes at the same share of its
		-- height), so it takes the same window.
		Species = {
			drizzlet = { Below = 0.19, Above = 0.28 },
			drizzlet_colossal = { Below = 0.19, Above = 0.28 },
			lotusling = { Below = 0.23, Above = 0.3, Wide = 0.3 },
			lotusling_colossal = { Below = 0.23, Above = 0.3, Wide = 0.3 },
		},
	},

	--==========================================================================
	-- THE BACKDROP IS TURNED DOWN
	--
	-- Rendered at full strength the pictures competed with the thing standing in
	-- front of them -- worst on Spiretip, whose pale spikes sat against pale
	-- mist and stopped reading. A flat multiply keeps all five recognisable as
	-- places while putting every one of them behind the plant, which is the rule
	-- the art bible states and the reason they were drawn soft to begin with.
	--==========================================================================
	ArtTint = Color3.fromRGB(202, 202, 202),

	Radius = 12,
	--==========================================================================
	-- THE POP
	--
	-- A card lifts under the pointer. 1.07 is enough to read as a lift without
	-- the card colliding with its neighbours at rest, and 0.12s is short enough
	-- that a fast pass across a grid does not leave a wave behind it.
	--==========================================================================
	HoverScale = 1.07,
	HoverSeconds = 0.12,

	--==========================================================================
	-- THE CLICK SHAKE
	--
	-- A short horizontal wobble that settles, so a press has a physical answer
	-- rather than only a sound. Deliberately small: this fires on every card
	-- click in the game, and an effect that fires that often is one a player
	-- stops seeing and starts feeling -- which it can only do if it never gets
	-- in the way of the thing they just pressed.
	--
	-- IT MOVES, IT DOES NOT ROTATE. A rotated GuiObject escapes ClipsDescendants
	-- and the shop shelves SCROLL, so a rotating card caught half way past the
	-- top of the list would draw its clipped-off half over the panel header.
	-- Translation clips correctly, which is why ShakePixels is a distance.
	--
	-- 5px over 0.20s at four reversals: fast enough to read as an impact rather
	-- than a wobble, small enough that the text stays readable throughout.
	--==========================================================================
	ShakePixels = 5,
	ShakeSeconds = 0.20,

	--==========================================================================
	-- SELECTED IS NOT HOVERED
	--
	-- A hovered card grows; a SELECTED card gets out of its own way. It shrinks
	-- toward the top of its cell and the strip that frees up at the bottom is
	-- where the action button goes -- so the button belongs to that card, sits
	-- under its plant, and never covers a neighbour.
	--
	-- 0.84 rather than the 0.90 that first suggested itself: a 184-pixel cell
	-- only frees 18 pixels at 0.90, and a button that short cannot hold
	-- LuckiestGuy at a readable size. 0.84 frees 29, which fits a 28-pixel slab
	-- with a pixel to spare.
	--
	-- Hover is switched OFF while a card is selected. Two scales fighting over
	-- one card is how a card ends up stuck at 1.07 with a button under it.
	--==========================================================================
	SelectScale = 0.84,
	ActionHeight = 28,
	ActionFace = Color3.fromRGB(226, 96, 84),
	ActionShade = Color3.fromRGB(168, 56, 48),
	ActionTextSize = 14,
	-- Added to every layer of a hovered card so it draws over the ones beside
	-- it. Bigger than any ZIndex a card uses, so a lifted card clears a resting
	-- one whole rather than interleaving with it.
	HoverLift = 40,
}

--==============================================================================
-- THE MUSIC
--
-- ROBLOX CANNOT PLAY A FILE OFF THE DISK. The pieces live in `sfx/` and none of
-- them is what the game plays: audio has to be uploaded to the asset server
-- first, and what ships is the id that comes back. These are those ids, off the
-- owner's own account.
--
--     BGM1   133940553394248     sfx/Garden at First Light.m4a
--     BGM2    70722559996799     sfx/Garden at First Light_1.m4a
--     NIGHT  115368148164882     sfx/Night Background Music.mp3
--
-- TWO TAKES OF ONE PIECE, BY DAY. Played in order and wrapped at the end, so the
-- bed runs about three and a quarter minutes before it repeats itself. One id in
-- a list would loop that one track forever instead; the list decides, not the
-- code.
--
-- AND ONE PIECE AT NIGHT. NightTracks is the same kind of list and works the same
-- way -- Music.client reads Workspace.WorldPhase and crossfades between the two
-- -- but it is nearly three minutes long against a night that lasts fifteen
-- seconds, so in practice it plays its own opening and is faded out at dawn.
-- That is the right shape for it: a night is a scene, not a loop.
--
-- AN EMPTY NightTracks IS NOT SILENCE. The day bed simply keeps playing, which is
-- exactly what the game did before this list existed.
--
-- Nothing about the PLAYER picks a track. The world does, and only at dusk and
-- dawn. It is still a bed, not a cue.
--
-- NOT BALANCE, so Rule 7 is intact: names and structure, the same way
-- GameConfig.Rail carried the rail's image ids for as long as it had any.
--==============================================================================
GameConfig.Music = {
	Tracks = {
		"rbxassetid://133940553394248",  -- BGM1
		"rbxassetid://70722559996799",   -- BGM2
	},

	-- 2:58 of it, against a fifteen-second night. Uploaded 2026-09-17.
	NightTracks = {
		"rbxassetid://115368148164882",  -- Night Background Music
	},

	--==========================================================================
	-- UNDER THE GAME, NEVER OVER IT
	--
	-- A bed sits below every cue that means something -- the RUN alarm, the
	-- hatch, the pod landing -- because a player who cannot hear the alarm over
	-- the music turns the music off, and then they cannot hear the music
	-- either. AlertUI's stinger plays at 0.55 and its pings at 0.42, so this
	-- stays well under both.
	--==========================================================================
	Volume = 0.32,

	-- Faded up at join rather than slammed on. A track that starts at full
	-- level on the loading screen is the first thing a player mutes.
	FadeSeconds = 2.5,

	--==========================================================================
	-- AND THE SAME THREE SECONDS THE SKY TAKES
	--
	-- Deliberately WorldCycle.Night.FadeSeconds, by value: the lighting crossfade
	-- and the bed crossfade are one event to a player standing in the road at
	-- dusk, and two durations that drift apart would make the world change twice.
	--
	-- Half of it fades the old bed out and half brings the new one in, so the
	-- swap itself happens at the darkest moment rather than over the top of the
	-- track that is leaving.
	--==========================================================================
	PhaseFadeSeconds = 3.0,

	--==========================================================================
	-- THE RAIN EVENT'S BED (2026-10-02)
	--
	-- While a Rain or a Thunderstorm falls (Weather.Attributes.State "opening"
	-- or "active") this ONE track takes the place of the day or night bed: the
	-- same Sound on the same Music bus, so the MUSIC slider and mute move it and
	-- it never plays over another bed. It comes in over RainFadeSeconds (half
	-- the old bed out, half the rain bed in) and leaves the same way the moment
	-- the weather starts closing; a player who joins mid-event starts on it.
	-- If the id does not load for this client the day/night bed carries on --
	-- an asset that cannot play is never silence where the music was.
	--==========================================================================
	RainTracks = {
		"rbxassetid://70930849303265",  -- Rain Event BGM (CrazyCozy Games upload)
	},
	RainFadeSeconds = 4.0,

	--==========================================================================
	-- THE DISCO'S BED (2026-10-03; every mode with Disco: TICKET DISCO, DISCO +
	-- MILL and, from 2026-10-04, the pure DISCO ONLY)
	--
	-- The owner's disco track (supplied 2026-10-03; an Audio asset uploaded by
	-- CrazyCozy Games, the group that owns this place, 172.95 s). While a disco
	-- mode runs (GameConfig.MiniEvent State "running" and a mode with Disco --
	-- never TICKET SHOWER ONLY) it takes the bed's place the way the rain's
	-- does -- ahead of the rain, night and day beds -- on the same one Sound and
	-- Music bus (the player's music level), looping, faded in and out over
	-- DiscoFadeSeconds, and started at the global event's own position so a
	-- late joiner hears the same bar as everyone else. An id that does not load
	-- is reported and skipped: the bed that was playing carries on. Never the
	-- rain BGM.
	--==========================================================================
	DiscoTracks = {
		"rbxassetid://118716691317783", -- disco event sfx (CrazyCozy Games upload)
	},
	DiscoFadeSeconds = 3.0,

	--==========================================================================
	-- THE POD RUSH'S BED (2026-10-09; the owner: the rush needs music)
	--
	-- While a POD RUSH runs (GameConfig.MiniEvent State "running" and a mode
	-- with PodRush) this ONE track takes the bed's place the way the disco's
	-- does -- the two are both mini events and never run at once -- on the same
	-- one Sound and Music bus, so the chase bed ducks it as it ducks any bed;
	-- looping, faded in and out over PodRushFadeSeconds, and started at the
	-- rush's own position, at the beds' own level (Volume). The owner's
	-- (2026-10-09: "111742643280141 bgm for pod rush"; an Audio asset, CrazyCozy
	-- Games; Studio Edit: loaded, 182.814 s; mean -16.6 dB, as BGM1). "" keeps
	-- the normal bed. An id that does not load is reported and skipped.
	--==========================================================================
	PodRushTrack = "rbxassetid://111742643280141",
	PodRushFadeSeconds = 3.0,
}

--==============================================================================
-- EVERY SOUND THAT IS NOT THE MUSIC BED
--
-- ONE CUE PER LINE, AND AN EMPTY ID IS A SILENT CUE RATHER THAN A BROKEN ONE.
-- SoundKit skips any row with no id: no error, no warning at the call site, and
-- the game behaves exactly as it does with the row absent. That is what makes
-- this table fillable ONE ROW AT A TIME, in any order, by somebody who is not
-- reading the code that plays it. Paste an id, hear the cue.
--
-- What was here before was six ids in a flat map that nothing read, kept "so
-- the ids are not lost". Ids that nothing reads rot: five of those six were
-- deleted off the account and this table went on claiming they existed. Every
-- row below has a trigger in a specific script, which is the only thing that
-- makes a wrong id noticeable.
--
--==============================================================================
-- WHAT A ROW MEANS
--
--   id        rbxassetid://N, or "" for not recorded yet.
--   volume    0-1, before the bus level below.
--   pitch     PlaybackSpeed. 1 is the file as recorded.
--   jitter    +/- this much pitch, per play. A hover that plays at exactly the
--             same pitch every time turns into a woodpecker the moment somebody
--             sweeps the pointer down a grid of cards.
--   group     which bus it rides. Decides what a future volume slider moves.
--   looped    for the two that are beds rather than hits.
--   range     studs. Positional cues only; ignored by the 2D ones.
--
-- LEVELS ARE SET AGAINST THE FOUR SOUNDS ALREADY PLAYING. AlertUI's stinger is
-- 0.55 and its alarm pings are 0.42, and the music bed sits under both at 0.32.
--
-- THE RULE IS ABOUT WHAT CAN PLAY WHILE THE ALARM IS UP, not about the loudest
-- number in the table. Anything that can sound DURING a carry -- the hover, the
-- click, the tick, the panels -- stays well under 0.42, because a player who
-- cannot hear the alarm over a card hover is a player who turns the sound off,
-- and then they cannot hear the alarm either.
--
-- Three cues sit above it on purpose. Banked (0.50) plays at the instant the
-- alarm STOPS and is the thing replacing it. RevealEpic and RevealLegendary
-- (0.45, 0.55) happen in your own garden, at the one moment this game reveals
-- anything, and a payoff that has to be quieter than a warning is not a payoff.
--
-- NOT BALANCE, so Rule 7 is intact. How loud a thing is and how far it carries
-- is structure; none of it decides what anything is worth.
--==============================================================================
GameConfig.Sfx = {
	--==========================================================================
	-- FOUR BUSES
	--
	-- Because they are four different arguments about volume: music is a
	-- preference, the chase is drama, the UI is feedback and the world is
	-- distance. One master would make "quieter menus" and "quieter monster" the
	-- same setting, and they are not the same setting.
	--==========================================================================
	Mixer = {
		Music = 1.0,
		Chase = 1.0,
		UI = 1.0,
		World = 1.0,
	},

	--==========================================================================
	-- THE GARDEN BED GETS OUT OF THE CHASE BED'S WAY
	--
	-- Down to a third rather than off. Off is a hole -- the moment the chase
	-- ends the bed slams back in and the player hears the SYSTEM rather than the
	-- game. A third is still there, still keying the garden, and no longer
	-- arguing with the drums.
	--==========================================================================
	MusicDuck = 0.34,
	DuckSeconds = 0.6,

	--==========================================================================
	-- THE CHASE BED FOLLOWS THE PURSUIT, AND LEAVES GENTLY
	--
	-- Hold: how long nobody may be chasing before the bed lets go. Long enough
	-- to ride a retarget, a guardian's throw ending while another is still
	-- running, or a chase that picks straight back up; short enough that
	-- reaching the red line still sounds like the moment it is.
	--
	-- FadeIn is short, because a pursuit starting should land -- but not zero,
	-- so the roar that started it is not stepped on by a hard downbeat. FadeOut
	-- is the escape: the bed goes under while the garden bed comes back up over
	-- the same length, so the two cross rather than one leaving a hole.
	--==========================================================================
	ChaseHoldSeconds = 1.0,
	ChaseFadeInSeconds = 0.4,
	ChaseFadeOutSeconds = 1.8,

	--==========================================================================
	-- THE MONEY TICK IS A COUNT, NOT A METRONOME
	--
	-- CashUI ticks while its readout eases to a new balance. Plant income moves
	-- the balance every second for a whole session, and the tick used to sound
	-- on every third printed change -- about once a second at $4/s, ten times
	-- a second at $100/s, for ever. Reported as irritating on 2026-09-26.
	--
	-- A ROUTINE step -- no bigger than LumpFactor times the recent ones, which
	-- is what plant income looks like -- ticks at most once every
	-- RoutineSeconds, at RoutineVolume of the cue's level. A LUMP -- a sale, a
	-- reward, a purchase -- is counted in with the tick it always had, never
	-- faster than one per CountSeconds. The balance is never touched: this
	-- only decides when the tick sounds. The player's SOUND FX level applies to
	-- both, through the UI bus.
	--==========================================================================
	CashTicks = {
		RoutineSeconds = 2.5,
		RoutineVolume = 0.5,
		CountSeconds = 0.12,
		LumpFactor = 4,
	},

	--==========================================================================
	-- WHICH FILE IN sfx/ BECOMES WHICH ROW
	--
	-- ROBLOX CANNOT PLAY A FILE OFF THE DISK. Everything in sfx/ is a source;
	-- what the game plays is the id that comes back from uploading it. So this
	-- table is the seam between the two, and this is the map across it -- because
	-- "which WAV was CardHover again" is a question that has to be answerable a
	-- month from now, by somebody looking at either end.
	--
	--   CardHover         CARD HOVER POP.wav
	--   CardClick         CARD CLICK.wav
	--   Denied            NOT ENOUGH CASH.wav
	--   PanelOpen         PANEL OPEN.wav
	--   PanelClose        PANEL CLOSE.wav -- its own recording since 2026-09-17.
	--                     It used to be PANEL OPEN pitched up 6% and cut short,
	--                     which was always a stand-in rather than an answer.
	--   CashTick          CASH TICK.wav
	--   Banked            BANKED -- A POD MADE IT HOME.wav
	--   ChaseBed          Chase bed (Loop) -- the ORIGINAL upload, recovered.
	--                     CHASE BED, SECOND TIER.wav is uploaded and unused: it
	--                     is the escalation, and there is no state to escalate
	--                     on yet.
	--   RevealCommon      Common rarity.wav
	--   RevealRare        rare rarity.wav
	--   RevealEpic        epic rarity.wav
	--   RevealLegendary   legendary rarity.wav
	--   MillMount         MOUNTING belt.wav
	--   MillUpgrade       MILL UPGRADE BOUGHT.wav
	--   ParentSleep       parent sleep sound.wav -- uploaded, and the only row
	--                     below that already has its id.
	--
	-- AND THE EIGHT THE OWNER ADDED ON 2026-09-17, which are the first cues in this
	-- game that belong to ONE CREATURE rather than to the game:
	--
	--   ParentHit              Attack Claw Swipe & Jaw Snap.wav
	--   ParentHitGreenhollow   attack hit biome 1.wav
	--   ParentHitTanglemire    attack hit miremaw.wav
	--   ParentWakeGreenhollow  biome 1 aggro trigger.wav
	--   ParentWakeDustbowl     brambleback aggro wake up.wav
	--   ParentWakeTanglemire   miremaw aggro trigger.wav
	--   ParentStepDustbowl     brambleback heavy stomp chasegait.wav
	--   ParentSleepDustbowl    brambleback sleeping.wav
	--
	-- "biome 1" is GREENHOLLOW -- the mossy brute in ParentModel, which is the only
	-- parent without a name of its own. Brambleback is Dustbowl's and Miremaw is
	-- Tanglemire's. Which creature hears which is ParentVoices, under the cues.
	--
	-- AND THE EIGHTEEN FROM LATER THE SAME DAY, which finish the job: every moment
	-- this file had written down as "silent, waiting for a recording" now has one.
	--
	--   TrapPlace              TRAP PLACEMENT.wav
	--   TrapArmed              TRAP ARMED.wav
	--   TrapSpringBramblejaw   BRAMBLEJAW ACTIVATION.wav
	--   TrapSpringDunesnap     DUNESNAP ACTIVATION.wav
	--   TrapSpringMirecoil     MIRECOIL ACTIVATION.wav
	--   TrapSpringCinderburst  CINDERBURST ACTIVATION.wav
	--   TrapSpringStarlock     STARLOCK ACTIVATION.wav
	--   BatSwing               BAT SWING.wav
	--   BatImpact              BAT IMPACT.wav
	--   PodDrop                POD DROP.wav
	--   ColossalPickup         COLOSSAL POD PICKUP.wav
	--   HatchRattle            HATCH RATTLE.mp3 -- the only MP3 in the folder
	--   HatchCrack             HATCH CRACK.wav
	--   HatchTimeSkip          INSTANT HATCH TIME SKIP.wav
	--   ParentWakeEmberroot    EMBERROOT GUARDIAN WAK.wav
	--   ParentWakeStarbloom    STARBLOOM GUARDIAN WAKE.wav
	--   SellAll                SELL ALL CASH.wav
	--   PanelClose             PANEL CLOSE.wav -- AT LAST. See the row.
	--
	-- TakePod, Grab, Throw and ChaseStep have no local WAV -- those five files
	-- were deleted. THE UPLOADED ASSETS WERE NOT, and all five still load, so
	-- they are wired from the account's own audio inventory rather than left
	-- silent. Prompts 15 to 19 in sfx/suno prompts.txt replace any of them.
	--
	-- TITLE  LOADING.wav has no row because it has no trigger: there is no
	-- loading screen to play it under. It is a bed, not a cue -- when there is
	-- somewhere to put it, it goes in GameConfig.Music, not here.
	--==========================================================================
	--==========================================================================
	-- THE NUMBERS ARE MEASURED, NOT GUESSED
	--
	-- Every `volume`, `start` and `clip` below came off the WAV in sfx/ rather
	-- than off a slider, because the uploads are RAW SUNO RENDERS and a raw
	-- render is not a game sound. Two things were wrong with all fourteen and
	-- neither is audible until it is in the game:
	--
	-- THEY ARE NOT TRIMMED. `CARD HOVER POP` is five seconds containing THIRTEEN
	-- separate pops; playing it on hover plays all thirteen. `CARD CLICK` opens
	-- with 140ms of silence, so the click lands a sixth of a second after the
	-- press. `PANEL OPEN` has a 290ms lead-in and a second thump at 1.04s.
	--
	-- THEIR LEVELS ARE ALL OVER THE PLACE. Peak amplitude runs from 7% of full
	-- scale (Common rarity) to 100% (Mill upgrade) -- a 23 dB spread across
	-- sounds that are supposed to sit in one mix. Volume below is therefore the
	-- DESIGNED level divided by the file's measured peak, which is why some of
	-- them are above 1: Banked peaks at 11%, so 0.50 of designed level is 4.37
	-- of gain.
	--
	-- Checked before doing it: the quietest 20ms window in each file is its
	-- noise floor, and after the gain above the worst case (Banked, 8.7x) still
	-- sits at -50 dB. Nothing here surfaces hiss. If a file is ever normalised
	-- and re-uploaded, drop its volume back to the designed number in the
	-- comment beside it.
	--
	-- start/clip are a WINDOW INTO THE ASSET, not a substitute for trimming. It
	-- is exact and it costs nothing, but a trimmed re-upload is smaller, starts
	-- instantly, and lets both fields go away.
	--==========================================================================
	Cues = {
		--======================================================================
		-- THE SCREEN
		--======================================================================
		-- Pop 1 of 13, at 0.088. Fires more often than anything else in the
		-- game, so it is also the quietest thing in the game. Designed 0.20.
		CardHover = {
			id = "rbxassetid://93538481108310",
			volume = 0.24, start = 0.08, clip = 0.14, jitter = 0.06, group = "UI",
		},
		-- 140ms of dead air before the click. Designed 0.30.
		CardClick = {
			id = "rbxassetid://113610810828248",
			volume = 0.30, start = 0.12, clip = 0.20, jitter = 0.04, group = "UI",
		},
		--==================================================================
		-- THE SAME CLICK, UNDER THE NAME FOUR CALL SITES ALREADY USE
		--
		-- LoadoutUI asks for "UIClick" when a slot is returned, assigned or
		-- swapped, and PlantPickUI asks for it when you choose a plant to pick
		-- up. THERE HAS NEVER BEEN A ROW CALLED THAT, so all four have been
		-- silent since they were written -- and silently silent, because
		-- SoundKit.report only lists rows whose id is blank and a row that does
		-- not exist has no id to be blank. Each of those four presses already
		-- flashes the slot it acted on, so the sound was the half that was
		-- missing rather than the half that was wanted.
		--
		-- A POINTER AT CardClick, not a second recording: it is the same event
		-- -- a press that did something -- and no click of the hotbar's own has
		-- been recorded. When one is, this row takes the new id and nothing
		-- else has to change. Its window is CardClick's because it is the same
		-- asset, dead air and all.
		--==================================================================
		UIClick = {
			id = "rbxassetid://113610810828248",
			volume = 0.30, start = 0.12, clip = 0.20, jitter = 0.04, group = "UI",
		},
		-- Peaks at 18%. Designed 0.30.
		Denied = { id = "rbxassetid://102715407432501", volume = 1.68, group = "UI" },
		-- The swoosh starts at 0.29 and the thump lands at 0.43; the second
		-- thump at 1.04 is a different take and is cut off. Designed 0.28.
		PanelOpen = {
			id = "rbxassetid://131340288435165",
			volume = 0.28, start = 0.27, clip = 0.50, group = "UI",
		},
		--==================================================================
		-- CLOSING IS THE SAME ASSET, PITCHED UP AND CUT SHORT
		--
		-- The reverse was never recorded, so this is the honest version of
		-- what is available: the same gesture, 6% faster and a third
		-- shorter, which reads as quicker without pretending to be a
		-- different sound. It is a stand-in. A reversed upload of its own is
		-- still the right answer.
		--==================================================================
		--==================================================================
		-- THE CLOSE IS NOT THE OPEN PLAYED BACKWARDS, OR SHARPER
		--
		-- This row used to be PANEL OPEN's id with pitch = 1.06 and a third cut
		-- off, because there was no close to play. It has its own recording now:
		-- 0.88s, 40ms of lead-in, the latch at 0.54, done by 0.66. The pitch
		-- shift is gone with it -- a cue that is its own sound does not need to
		-- be disguised as a different one.
		--
		-- Peaks at 34%, which is the quietest file in the folder. Designed 0.28,
		-- the level the stand-in was mixed to, so nothing about how loud the UI
		-- feels changes today.
		--==================================================================
		PanelClose = {
			id = "rbxassetid://98956134010999",
			volume = 0.82, start = 0.02, clip = 0.72, group = "UI",
		},
		-- 130ms late, then a 540ms decay that would ring under a counter
		-- ticking three times a second. Designed 0.15.
		CashTick = {
			id = "rbxassetid://107680742328909",
			volume = 0.23, start = 0.13, clip = 0.16, jitter = 0.03, group = "UI",
		},

		--==================================================================
		-- THE NOTICES (2026-09-27): Notice.Styles names these, and nothing
		-- else does. The owner's dedicated recordings. Blocked, warning and
		-- info are uploads of the CrazyCozy Games group (744756221), which
		-- also owns Podnappers, so they load here with no step (Studio load
		-- test, 2026-09-27). SUCCESS is the owner's "success new", and it is a
		-- group upload too since 2026-09-28 (104123841960377): the first copy
		-- (123803156310043) was on the owner's own account, which Podnappers
		-- may not use without a grant. Studio load test 2026-09-28: 1.28 s.
		--
		-- THEIR OWN ROWS, NOT Denied's. A blocked notice used to sound Denied;
		-- that cue stays exactly as it is for the shop, the Bag, the Index and
		-- the mill, which refuse things with no notice at all.
		--
		-- 48 kHz. Levels by 100 ms loudness against what already ships
		-- (Banked, a pod home, is -16.5 dB; Denied -18.0; a panel opening
		-- -18.7): blocked, success and warning at about -21, info a quiet
		-- accent at -25 -- under every gameplay moment.
		--   Action Blocked   0.48 s, file -17.2 dB, peak -3.8      -> 0.65
		--   success new      1.28 s, file -13.6 dB, peak -3.1: a chime that
		--                    decays to silence by 1.0 s, so there is no
		--                    window -- the whole of it plays        -> 0.43
		--   Warning          0.48 s, file -21.2; still sounding at -24 dB
		--                    when the render stops, so it fades over its
		--                    last 80 ms rather than being cut        -> 1.08
		--   Information      0.48 s, file -18.4, a sharp ping (peak -2.7) -> 0.47
		--==================================================================
		NoticeBlocked = { id = "rbxassetid://129733199607968", volume = 0.65, group = "UI" },
		NoticeSuccess = { id = "rbxassetid://104123841960377", volume = 0.43, group = "UI" },
		NoticeWarning = {
			id = "rbxassetid://122434285599993",
			volume = 1.08, clip = 0.48, fadeOut = 0.08, group = "UI",
		},
		NoticeInfo = { id = "rbxassetid://80357294905654", volume = 0.47, group = "UI" },

		--==================================================================
		-- THE ADMIN BROADCAST'S CHIME (2026-10-01): the owner's
		-- "adminmessagenotif", uploaded under CrazyCozy Games, so it loads with
		-- no grant (Studio load test: Success, 0.88 s). Played once per new
		-- broadcast by AnnouncementUI (GameConfig.Announce.Chime).
		--
		-- Levelled by PlaybackLoudness in Studio Play, each at Volume 1 with no
		-- bus: this one peaks at 395 with a mean of 194 over its loud 0.4 s,
		-- against NoticeInfo's 204 / ~80 and NoticeSuccess's 266 / 139. At 0.30
		-- it sits where the success chime is played (0.43): peak ~118, mean
		-- ~58 -- a little more present than the info ping, as a message from
		-- a person should be, and no louder than a notice. No window: it
		-- starts at once, and its last half second is its own quiet tail.
		--==================================================================
		AdminBroadcast = { id = "rbxassetid://119120354459025", volume = 0.30, group = "UI" },

		-- THE RARE REVEAL'S ACCENT: the owner's RARE PLANT REVEAL ACCENT, uploaded
		-- to the same group. Played with the creature, not the timer (HatchFX),
		-- for the rarities RevealAccentFor names and no others. 1.00 s, a bright
		-- sparkle (10 kHz); -26 dB here, two under the Rare fanfare it sits on.
		RevealAccentRare = { id = "rbxassetid://75401177703541", volume = 0.55, group = "UI" },

		--======================================================================
		-- THE RUN
		--======================================================================
		-- Peaks at 11%, the quietest upload of the fourteen. Designed 0.50.
		Banked = { id = "rbxassetid://90673825356478", volume = 4.37, group = "UI" },
		--==================================================================
		-- THE CHASE BED, RE-RECORDED 2026-09-17
		--
		-- This was 86935894428393, a 5.56 second loop recovered out of the
		-- account's inventory after its local file was deleted -- the oldest
		-- asset in this table and the only one nobody had ever measured. It is
		-- now `Chase Background Music`: 74.4 seconds of written chase rather
		-- than six seconds going round.
		--
		-- STILL LOOPED, AND THAT STILL MATTERS MORE THAN THE LENGTH. A chase
		-- is over in seconds; what a player hears is the first ten of this,
		-- from the top, every time -- SoundKit restarts a 2D cue rather than
		-- stacking it. The loop only ever matters to somebody who has been
		-- chased for a minute and a quarter, and they have earned a seam.
		--
		-- Peaks at 65%, so the designed 0.40 is 0.62 of gain. THIS IS THE
		-- NUMBER MOST LIKELY TO WANT AN EAR: the old bed's level was never
		-- measured against anything, so 0.40 was a judgement about a file
		-- nobody has the source of any more.
		--
		-- `CHASE BED, SECOND TIER` (110892791280400, 4.00s) is still the
		-- escalation and still has nowhere to go: that needs a state saying a
		-- chase is WORSE than usual, and this game does not have one.
		--==================================================================
		ChaseBed = {
			id = "rbxassetid://97007444825023",
			volume = 0.62, looped = true, group = "Chase",
		},

		--======================================================================
		-- THE REVEAL
		--
		-- The hatch is the only moment this game reveals anything, so the rarer
		-- it is the longer the sound is allowed to take: 0.77s, 0.17s, 0.49s and
		-- 1.06s of content. Not clipped -- every one of them starts at zero and
		-- a musical tail is the part you would be cutting.
		--======================================================================
		-- Peaks at 7%. Designed 0.30.
		RevealCommon = { id = "rbxassetid://74338267139417", volume = 4.45, group = "UI" },
		-- Peaks at 83%. Designed 0.35.
		RevealRare = { id = "rbxassetid://99776609601370", volume = 0.42, group = "UI" },
		-- Peaks at 30%. Designed 0.45.
		RevealEpic = { id = "rbxassetid://83653226797020", volume = 1.52, group = "UI" },
		-- Peaks at 87%. Designed 0.55.
		RevealLegendary = { id = "rbxassetid://73136314922937", volume = 0.64, group = "UI" },
		--==================================================================
		-- THE REBIRTH FANFARE (2026-10-09, Rebirth.Celebration.Cue and
		-- NearbyCue)
		--
		-- The owner's "Triumphant Chime" (sfx/Triumphant Chime.mp3), 13.09 s:
		-- a build to 2.4 s (rising hits at 0.48-1.87 s), the ARRIVAL HIT at
		-- 2.41 s -- its brightest moment -- a sustained fanfare to 9.5 s and a
		-- fade to 12.5 s. Peak 0.635 (-3.9 dBFS) in either channel at 48 kHz
		-- (measured here 2026-10-09; the other session's own measure read
		-- 0.501). Designed 0.60: 0.6 / 0.635.
		--
		-- THE WINDOW the owner was told: from 0.85 s for 3.4 s, so the hit
		-- lands at 1.56 s -- on the celebration's burst at 1.6 s -- and the
		-- last 1.2 s fades instead of being cut, ending with the card.
		-- Rebirth is flat on the reborn player's own screen; RebirthNearby is
		-- the same window from the body, heard within the celebration's
		-- Range by everybody close.
		--==================================================================
		Rebirth = {
			id = "rbxassetid://115254226875194",
			volume = 0.94, start = 0.85, clip = 3.4, fadeOut = 1.2, group = "UI",
		},
		RebirthNearby = {
			id = "rbxassetid://115254226875194",
			volume = 0.94, start = 0.85, clip = 3.4, fadeOut = 1.2, range = 120, group = "World",
		},

		--==================================================================
		-- THE POD RUSH'S STINGS (2026-10-09; PodRushUI): a short START with
		-- its announcement and a FINISH with the end card, flat on the
		-- player's own screen. The owner's (Audio, CrazyCozy Games; Studio
		-- Edit: loaded, 2.000 s each): START sounds 0.00-1.43 s, FINISH
		-- 0.00-1.20 s, no lead-in, peak 1.0, clean tails -- the whole asset,
		-- no window. 0.6 as designed.
		--==================================================================
		PodRushStart = { id = "rbxassetid://101349325894268", volume = 0.6, group = "UI" },
		PodRushFinish = { id = "rbxassetid://117588221543351", volume = 0.6, group = "UI" },

		--======================================================================
		-- THE MILL
		--
		-- Both positional and both audible from off the plot, on purpose: a
		-- neighbour buying tier 6 is the most persuasive advertisement this game
		-- has, and it is free.
		--======================================================================
		-- 160ms of thud followed by three and a half seconds of nothing.
		-- Designed 0.45.
		MillMount = {
			id = "rbxassetid://137166099826620",
			volume = 0.82, clip = 0.60, range = 90, group = "World",
		},
		-- Designed 0.60, and the file already peaks at full scale.
		MillUpgrade = {
			id = "rbxassetid://102053237936114",
			volume = 0.60, clip = 1.20, range = 140, group = "World",
		},

		--======================================================================
		-- THE NEST
		--
		-- ALL FOUR OF THESE ARE THE ORIGINAL UPLOADS. The local WAVs were
		-- deleted; the ASSETS were not, and all four still load. Recovered out
		-- of the account's own audio inventory rather than left silent, because
		-- the alternative was a monster that chases you without a sound.
		--
		-- Their numbers are the DESIGNED levels and nothing else -- unlike the
		-- fourteen above, there is no local file left to measure, so no trim and
		-- no gain compensation. If any of them turns out to be quiet or to open
		-- with dead air, prompts 15 to 19 in sfx/suno prompts.txt will replace
		-- it and the measurement can be done properly.
		--
		-- Grab is the parent's hand closing on you, a fifth of a second before
		-- Throw. Two beats of one event, so they have to sit together.
		--======================================================================
		TakePod = { id = "rbxassetid://130694487616211", volume = 0.55, range = 90, group = "World" },
		Grab = { id = "rbxassetid://113282797733918", volume = 0.75, range = 140, group = "World" },
		Throw = { id = "rbxassetid://131635221141553", volume = 0.85, range = 160, group = "World" },
		-- 7.72s of running steps. Set looped = false if it turns out to be a
		-- SINGLE step; SoundCues retriggers it per stride in that case.
		ChaseStep = {
			id = "rbxassetid://84880778606132",
			volume = 0.50, range = 110, looped = true, group = "World",
		},
		-- Peaks at 74%. Designed 0.35.
		ParentSleep = {
			id = "rbxassetid://81143161269823",
			volume = 0.47, range = 70, looped = true, group = "World",
		},

		--======================================================================
		-- ONE CREATURE'S VOICE IS NOT ANOTHER'S
		--
		-- Everything above this line is a sound the GAME makes. These are sounds a
		-- PARTICULAR MONSTER makes, which is a different kind of row: the
		-- Brambleback's stomp is two tons landing on sand and Greenhollow's brute
		-- does not have one. So they are named for the biome that owns them, and
		-- ParentVoices below says who gets what -- a biome with no row of its own
		-- keeps the generic sound it has today, which is why Emberroot and
		-- Starbloom are absent here rather than silent in the game.
		--
		-- MEASURED OFF THE WAVs IN sfx/, the same way the fourteen above were, and
		-- these eight came back in better shape: only two need gain and only the
		-- claw swipe opens with dead air. What they DO need is CLIPPING. Four are
		-- two- and three-second renders holding one usable hit, and two of them
		-- hold a SECOND TAKE of that hit a beat later, which would otherwise play
		-- as an echo nobody recorded.
		--======================================================================
		-- The generic attack, for any parent with no hit of its own. 3.00s holding
		-- one swipe: 140ms of air, the claw at 0.18, over by 1.04. Peaks at 100%.
		ParentHit = {
			id = "rbxassetid://135685020427303",
			volume = 0.75, start = 0.12, clip = 1.00, range = 140, group = "World",
		},
		-- Greenhollow's brute. Hits at 0.04, and AGAIN at 0.92 -- second take, cut.
		ParentHitGreenhollow = {
			id = "rbxassetid://76475963669343",
			volume = 0.75, clip = 0.80, range = 140, group = "World",
		},
		-- Miremaw. Hits at 0.02, second take at 1.34, cut the same way.
		ParentHitTanglemire = {
			id = "rbxassetid://89258109602305",
			volume = 0.75, clip = 1.20, range = 140, group = "World",
		},

		-- THE WAKE, which is the loudest thing any of them do and the furthest
		-- carrying: it is the one sound in this game that means RUN, and it has to
		-- reach whoever is still standing at the nest. Content ends at 1.32, 1.52
		-- and 1.46; everything after that in each render is air.
		ParentWakeGreenhollow = {
			id = "rbxassetid://124160507544069",
			volume = 0.70, clip = 1.40, range = 170, group = "World",
		},
		ParentWakeDustbowl = {
			id = "rbxassetid://132556773572810",
			volume = 0.70, clip = 1.60, range = 170, group = "World",
		},
		ParentWakeTanglemire = {
			id = "rbxassetid://102762735296089",
			volume = 0.70, clip = 1.55, range = 170, group = "World",
		},
		-- The last two, recorded the same day this table was written and wired
		-- the same evening. Every guardian in the game now answers being robbed.
		-- Emberroot peaks at 86%, so 0.70 designed is 0.82; content ends at 1.20.
		ParentWakeEmberroot = {
			id = "rbxassetid://80131277872397",
			volume = 0.82, clip = 1.25, range = 170, group = "World",
		},
		-- Starbloom's is one second long and all of it is in the first 0.64.
		ParentWakeStarbloom = {
			id = "rbxassetid://138701632491162",
			volume = 0.70, clip = 0.70, range = 170, group = "World",
		},

		-- ONE STEP, NOT A GAIT. The file is called chasegait and it is 1.00s with a
		-- single stomp inside the first 0.44 -- so looped = false, and SoundCues
		-- fires it once per stride COVERED, which is the branch that was written
		-- for exactly this case and has never run. Peaks at 66%: 0.50 designed,
		-- ChaseStep's level, is 0.76 of gain.
		ParentStepDustbowl = {
			id = "rbxassetid://126905642164896",
			volume = 0.76, clip = 0.55, range = 110, looped = false, group = "World",
		},
		-- A breath a second, looped. NO WINDOW: the silence after the breath is the
		-- gap between breaths, and clipping it would make the Brambleback pant.
		-- Peaks at 78%, so 0.35 designed -- ParentSleep's level -- is 0.45.
		ParentSleepDustbowl = {
			id = "rbxassetid://89288684316602",
			volume = 0.45, range = 70, looped = true, group = "World",
		},

		--======================================================================
		-- THE 2026-09-24 GUARDIAN RECORDINGS (wired 2026-09-27)
		--
		-- Seven renders in sfx/: two sleeps, four walks home and Astralmaw's
		-- rage. Each id is checked to be the upload of the file its row
		-- describes (asset name, type Audio, creator). Never an id that is not.
		--
		-- UPLOADS OF THE CrazyCozy Games GROUP (744756221), WHICH OWNS
		-- PODNAPPERS, since 2026-09-28. The first uploads (2026-09-27) were on
		-- the owner's own account, and Podnappers may not use those: Roblox
		-- refused them ("The experience doesn't have access permission"), even
		-- after a grant. The group copies load with no step: Studio load test
		-- 2026-09-28, each at its file's length.
		--
		-- A row with an id is chosen by its id, not by whether it loads:
		-- parentCue stops falling through to the generic sleep and to
		-- Starbloom's old wake the moment an id is pasted, so an upload this
		-- game cannot use is SILENCE where there used to be a sound. Load-test
		-- an id in Podnappers before it goes here (KB/HANDOFF.md).
		--
		-- MEASURED OFF THE WAVs, levels set against the sounds already shipping
		-- (400 ms loudness): the sleeps at the generic sleep's -25 dB, the walks
		-- home at -16 (under every wake roar), the rage at -9 -- between
		-- Starbloom's old wake (-10.8) and the Brambleback's (-7.6), peaking at
		-- -2.7 dB, so it lands hard without clipping or burying the chase.
		--======================================================================
		-- 4.80 s: a breath that the render starts in the MIDDLE of (the first
		-- sample is at -0.18 -- a click on every loop), a clean breath from 1.6
		-- s, and silence from 3.4. So the loop is the region 1.4 -> 4.8: one
		-- whole breath out of silence and the pause after it, round and round.
		ParentSleepEmberroot = {
			id = "rbxassetid://140647760739270",
			volume = 0.26, range = 70, looped = true, loopStart = 1.4, loopEnd = 4.8, group = "World",
		},
		-- 4.80 s of one slow low hum, silence to silence (first and last samples
		-- 0.000 and 0.001): it loops as it is.
		ParentSleepStarbloom = {
			id = "rbxassetid://120712332842926",
			volume = 0.28, range = 70, looped = true, group = "World",
		},
		-- THE WALK HOME: a one-shot when a guardian gives up and turns for its
		-- nest (GameConfig.Sfx.ReturnCueAt). All four are short vocal renders
		-- with an onset and a decay -- none is a loop, and none has the long
		-- settle a lie-down would -- so they belong to the moment it turns.
		-- Dustbowl: a grunt, 0.8 s of digital silence, then a stomp at 1.5 s.
		ParentReturnDustbowl = { id = "rbxassetid://107688968177239", volume = 0.81, range = 120, group = "World" },
		-- Tanglemire: one second of sound and silence after it.
		ParentReturnTanglemire = { id = "rbxassetid://95499040809968", volume = 1.97, clip = 1.1, range = 120, group = "World" },
		-- Emberroot: a loud start decaying over a second and a half.
		ParentReturnEmberroot = { id = "rbxassetid://76853063080329", volume = 0.46, range = 120, group = "World" },
		-- Starbloom: a quiet 2.76 s shimmer (the quietest file of the four,
		-- hence the gain) that is still at -35 dB when the render stops.
		ParentReturnStarbloom = { id = "rbxassetid://139199037963607", volume = 2.79, range = 120, group = "World" },
		-- ASTRALMAW'S RAGE, which REPLACES Starbloom's one-second wake as its
		-- roar (ParentVoices.starbloom.Wake lists it first) -- never both. The
		-- render holds ONE whole roar, 0 to 3.2 s, near-silence by 3.9 (-46 dB),
		-- then a SECOND TAKE that the render cuts off mid-roar at 6.0. So the
		-- window is 3.9 s: the whole roar, not the two seconds the old wake had,
		-- and not the half of a second one. Nothing in the chase waits for it.
		ParentRageStarbloom = { id = "rbxassetid://108747837024365", volume = 0.73, clip = 3.9, range = 190, group = "World" },

		--======================================================================
		-- THE TRAPS
		--
		-- Three moments, and they are three different questions a player asks:
		-- WHERE (it went down), WHEN (it is live), and WHO (just stepped in it).
		-- The first two are shared by all five traps because they are the same
		-- action; the spring is per trap, named in the trap's own spec beside its
		-- radius and its cooldown -- see WeaponData.TrapSpecs.SpringCue.
		--
		-- Deliberately short ranges on the first two. A trap being placed is
		-- information a nearby player is entitled to, and a trap being placed on
		-- the far side of the road is not.
		--======================================================================
		-- Two thuds, 0.02 and 0.64: set down, then latched. Both kept.
		TrapPlace = {
			id = "rbxassetid://73333240019513",
			volume = 0.45, clip = 0.85, range = 60, group = "World",
		},
		-- The tick that says it is live. Content ends at 0.74.
		TrapArmed = {
			id = "rbxassetid://85062135388466",
			volume = 0.40, clip = 0.80, range = 50, group = "World",
		},
		-- The jaw: 140ms of creak, the snap at 0.80, ring-out to 1.28.
		TrapSpringBramblejaw = {
			id = "rbxassetid://113454656665508",
			volume = 0.70, start = 0.10, clip = 1.25, range = 90, group = "World",
		},
		-- The plate. One second, and the whole event is over by 0.44. It is also
		-- the quietest of the five -- peaks at 45% -- so it carries the most gain.
		TrapSpringDunesnap = {
			id = "rbxassetid://135633126454821",
			volume = 1.56, start = 0.02, clip = 0.50, range = 90, group = "World",
		},
		-- The snare: a coil at 0.18 and the catch at 0.84.
		TrapSpringMirecoil = {
			id = "rbxassetid://94258758905177",
			volume = 0.70, clip = 1.50, range = 90, group = "World",
		},
		-- The mine, and the only one that is an explosion: louder, and heard from
		-- further, because it is also the only trap that knocks a pod loose.
		TrapSpringCinderburst = {
			id = "rbxassetid://74420052751382",
			volume = 0.80, clip = 1.55, range = 120, group = "World",
		},
		-- The anchor. NO WINDOW: this one never goes quiet -- its noise floor is
		-- -20 dB where every other file in the folder is below -63 -- because it
		-- is a sustained hum with the lock at 1.12 and 1.32 inside it. Clipping
		-- it would cut a held note off mid-ring. It runs its own two seconds,
		-- which is under the three the pull-and-slow lasts.
		TrapSpringStarlock = {
			id = "rbxassetid://94296728955633",
			volume = 0.70, range = 100, group = "World",
		},

		--======================================================================
		-- THE BAT
		--
		-- The swing plays on the WIND-UP and the impact only if something is
		-- struck, which is the pair the animation already draws: the coil is
		-- published to every client before the hit is resolved, so a victim who
		-- hears the whoosh has the same warning the tell gives them.
		--======================================================================
		-- 320ms of silence, then the whoosh. Peaks at 65%.
		BatSwing = {
			id = "rbxassetid://127465264913354",
			volume = 0.62, start = 0.28, clip = 0.50, range = 60, group = "World",
		},
		-- 280ms, all of it impact, at full scale. Carries further than the swing
		-- because the person who got hit is not always the person who swung.
		BatImpact = {
			id = "rbxassetid://120499284760036",
			volume = 0.75, clip = 0.40, range = 110, group = "World",
		},

		--======================================================================
		-- THE POD ITSELF
		--
		-- TakePod is the shell coming free in your hands. These two are the other
		-- half of the same object's life: hitting the ground, and being a
		-- COLOSSAL coming free, which is a 0.5% roll and deserves its own noise.
		--======================================================================
		-- Two impacts, 0.06 and 0.46 -- landing and settling. Peaks at 43%.
		PodDrop = {
			id = "rbxassetid://119713147046244",
			volume = 1.16, start = 0.02, clip = 0.90, range = 90, group = "World",
		},
		-- FOUR SECONDS of file with 0.60 of sound in it. Named by the pod itself:
		-- CreatureModel stamps PickupSound = "ColossalPickup" on tier 7 and the
		-- take reads it, which is the attribute that has been sitting there unread
		-- since the tier shipped.
		ColossalPickup = {
			id = "rbxassetid://130996586864709",
			volume = 0.92, clip = 0.70, range = 140, group = "World",
		},

		--======================================================================
		-- THE HATCH
		--
		-- The three GameConfig.Plant.Hatch.Sounds has been naming as empty
		-- strings since the reveal was built. They are filled in down there; the
		-- rows are here.
		--======================================================================
		-- Under the 1.1s hold. The quietest thing in the batch at 40%, which is
		-- right for a shell working against itself, and the reason it carries
		-- 1.01 of gain. Content is 0.02 to 0.58; the rest of the hold is quiet on
		-- purpose, so the crack lands on silence.
		HatchRattle = {
			id = "rbxassetid://113736151394399",
			volume = 1.01, clip = 0.62, range = 70, group = "World",
		},
		-- The shell letting go: four cracks between 0.02 and 0.94, all of them
		-- part of one sound rather than four takes of it, so none is cut.
		HatchCrack = {
			id = "rbxassetid://125982914448542",
			volume = 0.60, clip = 1.10, range = 90, group = "World",
		},
		--======================================================================
		-- INVITE A FRIEND (2026-10-06): the owner's ten, ids and volumes from
		-- GameConfig.InviteRewards.Sounds (above), never retyped here.
		--======================================================================
		InviteSend = { id = GameConfig.InviteRewards.Sounds.Send.Id,
			volume = GameConfig.InviteRewards.Sounds.Send.Volume, group = "UI" },
		InviteJoined = { id = GameConfig.InviteRewards.Sounds.Joined.Id,
			volume = GameConfig.InviteRewards.Sounds.Joined.Volume, group = "UI" },
		InviteTick = { id = GameConfig.InviteRewards.Sounds.Tick.Id,
			volume = GameConfig.InviteRewards.Sounds.Tick.Volume, group = "UI" },
		InviteBadgePop = { id = GameConfig.InviteRewards.Sounds.BadgePop.Id,
			volume = GameConfig.InviteRewards.Sounds.BadgePop.Volume, group = "UI" },
		InviteWelcome = { id = GameConfig.InviteRewards.Sounds.Welcome.Id,
			volume = GameConfig.InviteRewards.Sounds.Welcome.Volume, group = "UI" },
		InviteEvolve = { id = GameConfig.InviteRewards.Sounds.Evolve.Id,
			volume = GameConfig.InviteRewards.Sounds.Evolve.Volume, group = "World",
			range = GameConfig.InviteRewards.EvolveRange },
		InviteUnlockEpic = { id = GameConfig.InviteRewards.Sounds.UnlockEpic.Id,
			volume = GameConfig.InviteRewards.Sounds.UnlockEpic.Volume, group = "UI" },
		InviteUnlockLegendary = { id = GameConfig.InviteRewards.Sounds.UnlockLegendary.Id,
			volume = GameConfig.InviteRewards.Sounds.UnlockLegendary.Volume, group = "UI" },
		InviteUnlockMythic = { id = GameConfig.InviteRewards.Sounds.UnlockMythic.Id,
			volume = GameConfig.InviteRewards.Sounds.UnlockMythic.Volume, group = "UI" },
		InviteUnlockSecret = { id = GameConfig.InviteRewards.Sounds.UnlockSecret.Id,
			volume = GameConfig.InviteRewards.Sounds.UnlockSecret.Volume, group = "UI" },
		-- The paid pulse, and the only cue in this group that is NOT positional:
		-- it is a receipt for something you bought, it plays on your screen, and
		-- nobody else in the world has any business hearing it.
		HatchTimeSkip = {
			id = "rbxassetid://77501647710630",
			volume = 0.45, clip = 1.45, group = "UI",
		},

		--======================================================================
		-- THE TILL
		--
		-- SellService has been emitting MillUpgrade for this with a comment
		-- inviting the swap. This is the swap. Peaks at 45%, and it is the
		-- shortest render in the folder at 0.88s.
		--======================================================================
		SellAll = {
			id = "rbxassetid://70521588661081",
			volume = 1.24, clip = 0.78, range = 80, group = "World",
		},

		--======================================================================
		-- THE RAIN EVENT (2026-10-02). The ids are the owner's CrazyCozy Games
		-- uploads, each load-tested in Podnappers before it was wired; the two
		-- Stormstrider voice rows still wait for their recordings (silent).
		-- All ride the World bus: the SOUND FX slider and mute move them, the
		-- MUSIC mute does not.
		--
		--   StormstriderWake    the guardian robbed and rising (ParentVoices.rain)
		--   StormstriderHit     its catch landing (ParentVoices.rain)
		--   StormstriderStrike  the bolt a catch calls down: the server's ONE
		--                       emit per confirmed catch, at the guardian
		--                       (NestService), heard with distance
		--   ThunderClap         a Thunderstorm's weather strike: one per bolt,
		--                       at the bolt's foot (Weather.client), heard with
		--                       distance
		--   ThunderstormOpening a Thunderstorm starting: once, 2D (Weather.client)
		--   RainAmbience        the rain itself: ONE 2D loop under a Rain or a
		--                       Thunderstorm, faded with the rain, a little
		--                       louder in a storm (Weather.Audio.StormAmbience)
		-- The two strikes are one recording. A catch is not a weather strike and
		-- a weather strike is not a catch, so no moment plays it twice. The old
		-- ThunderstormBed hook (a second, storm-only rain loop) is RainAmbience
		-- now: one loop, never two.
		--======================================================================
		-- The guardian's own two (2026-10-02, group uploads, load-tested). Measured
		-- off sfx/: AWAKE ANGRY is 2.88 s, mean -11.8 dB, peak 0 dB (a hot render)
		-- -> 0.35, about -21 dB at the guardian, the warning a thief hears, once
		-- per real wake (NestService's roar). SLEEPING is 11.88 s, mean -35.5 dB,
		-- peak -19.4 dB (a quiet one) -> 0.45, about -42 dB at arm's length: a
		-- touch under the rain's bed and well under the music, heard only near
		-- it (range 70, the other sleeps' reach), looped by SoundCues while
		-- ParentState is "asleep". Neither is pitched: speed 1.
		StormstriderWake = { id = "rbxassetid://113193227101300", volume = 0.35, range = 220, group = "World" },
		StormstriderSleep = { id = "rbxassetid://82607848172654", volume = 0.45, range = 70, looped = true, group = "World" },
		StormstriderHit = { id = "", volume = 1, range = 160, group = "World" },
		StormstriderStrike = { id = "rbxassetid://79835427265580", volume = 0.45, range = 320, group = "World" },
		ThunderClap = { id = "rbxassetid://79835427265580", volume = 0.35, range = 640, group = "World" },
		ThunderstormOpening = { id = "rbxassetid://110362720818059", volume = 0.4, group = "World" },
		RainAmbience = { id = "rbxassetid://138018201261517", volume = 0.16, looped = true, group = "World" },
	},

	--==========================================================================
	-- WHICH CREATURE MAKES WHICH NOISE
	--
	-- Keyed by the parent model's BiomeId attribute, which every builder sets
	-- BEFORE it parents the model -- so it replicates with the model and a client
	-- never sees a parent whose biome it does not know yet.
	--
	-- FOUR ROLES, AND A ROW MAY FILL ANY OF THEM:
	--
	--   Sleep   the loop it breathes while it is asleep beside its nest
	--   Step    one footfall, or a running loop if that is what was recorded
	--   Wake    the roar the moment somebody robs it. THIS IS A NEW MOMENT --
	--           nothing made a sound when a parent woke up before 2026-09-17
	--   Hit     the swing that lands, at the instant it takes your pod
	--
	-- A MISSING ROLE FALLS THROUGH TO Default, and a missing Default is silence.
	-- That is how three recordings for two creatures light up four biomes without
	-- a branch anywhere: Emberroot's Forgemaw and Starbloom's Astralmaw keep the
	-- generic sleep, the generic step and the generic swipe, and neither of them
	-- roars, because nobody has recorded them roaring. The day somebody does, it
	-- is one line here.
	--
	-- NOT Species. Every parent carries BiomeId; only the named four carry Species,
	-- so keying on it would leave Greenhollow's brute -- the one creature that has
	-- both a hit AND a roar -- unable to find either.
	--==========================================================================
	ParentVoices = {
		Default = { Sleep = "ParentSleep", Step = "ChaseStep", Hit = "ParentHit" },
		greenhollow = { Wake = "ParentWakeGreenhollow", Hit = "ParentHitGreenhollow" },
		dustbowl = {
			Sleep = "ParentSleepDustbowl",
			Step = "ParentStepDustbowl",
			Wake = "ParentWakeDustbowl",
			Return = "ParentReturnDustbowl",
		},
		tanglemire = {
			Wake = "ParentWakeTanglemire",
			Hit = "ParentHitTanglemire",
			Return = "ParentReturnTanglemire",
		},
		-- Recorded hours after the first six, so these two are no longer the
		-- silent ones. They still swing the generic claw; since 2026-09-27 each
		-- has its own sleep and walk home as well (blank either id again and it
		-- falls through to the generic sleep, or to no walk-home sound).
		emberroot = {
			Wake = "ParentWakeEmberroot",
			Sleep = "ParentSleepEmberroot",
			Return = "ParentReturnEmberroot",
		},
		-- A LIST IS AN ORDER OF PREFERENCE (SoundKit.parentCue): Astralmaw's
		-- rage is its roar while it has an id (since 2026-09-27), and the old
		-- one-second wake whenever it has not -- never both.
		starbloom = {
			Wake = { "ParentRageStarbloom", "ParentWakeStarbloom" },
			Sleep = "ParentSleepStarbloom",
			Return = "ParentReturnStarbloom",
		},
		-- The Rain event's Stormstrider (2026-10-02): its own growl when it wakes
		-- and its own breathing while it sleeps (in place of the generic one);
		-- Hit is still a hook waiting for a recording, so a catch keeps the
		-- generic claw it has today (and the lightning strike, which is not a
		-- voice).
		rain = {
			Wake = "StormstriderWake",
			Sleep = "StormstriderSleep",
			Hit = "StormstriderHit",
		},
	},

	-- When a guardian's walk-home cue plays: "leave", the moment it gives up and
	-- turns for the nest, or "arrive", the moment it lies back down. "leave" by
	-- the recordings (2026-09-27): short vocal one-shots, none shaped like a
	-- settle. One word to move them.
	ReturnCueAt = "leave",

	--==========================================================================
	-- A ONE-SHOT IS FOR WHOEVER WAS THERE (2026-10-02)
	--
	-- A server one-shot (SoundKit.emit) stands in the world for twelve seconds
	-- after it played. A client that receives it LATER than this -- a guardian
	-- streamed in mid-chase, a player who joined a moment after a roar -- does
	-- not replay a moment it never witnessed: its own copy is stopped. Ordinary
	-- replication lands well inside this.
	--==========================================================================
	LateCueSeconds = 1.0,

	-- THE ACCENT ON A REVEAL, by the same FORM rarity as RevealFor below: only
	-- the rarities named here, so recording another is a line in this table and
	-- nothing plays for a rarity nobody named.
	RevealAccentFor = {
		Rare = "RevealAccentRare",
	},

	--==========================================================================
	-- WHICH REVEAL A SPECIES GETS
	--
	-- EIGHT RARITIES, FOUR RECORDED CUES. Mapped here rather than in the script
	-- that plays them, so recording a fifth is a line in this table and not a
	-- branch somewhere in a client.
	--
	-- This is the FORM rarity off the species sheet -- how often that shape turns
	-- up -- and not SeedData.RarityForKg, which is the weight band the pod wears
	-- as its colour. Two vocabularies share four words in this game and the
	-- hatch is the one that reveals the SHAPE.
	--==========================================================================
	RevealFor = {
		Common = "RevealCommon",
		Uncommon = "RevealCommon",
		Rare = "RevealRare",
		Epic = "RevealEpic",
		Legendary = "RevealLegendary",
		Mythic = "RevealLegendary",
		Secret = "RevealLegendary",
		Divine = "RevealLegendary",
	},
}

--==============================================================================
-- THE TWO NUMBERS THAT POP OFF THINGS
--
-- A `+$N` rises off every grown plant once a second, and a `+N` rises off the
-- player while they are on a mill. They are the only two floating numbers in the
-- game and they were THE SAME OBJECT: GothamBlack, lime, three-pixel ink
-- outline, rise two and a half studs, fade over 1.1 seconds. The only thing
-- telling them apart was a 22-pixel blue shoe, and at any distance where these
-- are actually read -- across a plot, from the road -- that shoe is four pixels
-- wide.
--
-- So a player watching their own screen could not tell what had just paid them.
-- Which is the entire job of a floating number.
--
--==============================================================================
-- THEY ARE DIFFERENT AT SILHOUETTE, NOT AT COLOUR
--
-- Colour alone does not survive distance, colourblindness, a green plot, or a
-- bright sky. The two differ in the shape of the letters first:
--
--     CASH    LuckiestGuy -- fat, round, upright. Gold into lime, top to
--             bottom, like a coin catching the light. It POPS IN with an
--             overshoot and a slight tilt, because money should land with
--             weight, and it holds full opacity for half its life so the
--             number is readable rather than glimpsed.
--
--     SPEED   Bangers -- narrow, sharp, and slanted by the typeface itself
--             rather than by a rotation. White into blue. No pop-in, a shorter
--             life, and it slides SIDEWAYS as it rises so it reads as being
--             left behind rather than lifting off.
--
-- Round-fat-upright-gold against narrow-sharp-leaning-blue is a difference you
-- can still make at the edge of the 90-stud draw distance, with the text too
-- small to read.
--
-- BOTH FONTS WERE CHECKED FOR TOFU. Most of this engine's symbol range renders
-- as blank boxes -- the shoe beside the speed pop is built from two rounded
-- frames for exactly that reason -- so every glyph these need was rendered and
-- looked at before either was chosen.
--
-- NOT BALANCE. How a number is dressed, never what it is worth.
--==============================================================================
GameConfig.Pops = {
	Cash = {
		Font = Enum.Font.LuckiestGuy,
		-- Gold at the head, the game's lime at the foot. Gold is the one
		-- saturated colour Greenhollow spends, and it is spent here because this
		-- is a HUD readout rather than a plant -- the art bible's warning is
		-- about the world, and a coin that looks like a leaf is not a coin.
		Top = Color3.fromRGB(255, 216, 102),
		Bottom = Color3.fromRGB(142, 196, 62),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 3,
		Width = 108,
		Height = 34,
		RiseStuds = 2.5,
		-- Straight up. Money is not going anywhere.
		DriftStuds = 0,
		Seconds = 1.15,
		--======================================================================
		-- IT LANDS, THEN IT LIFTS
		--
		-- Scales up from small through an overshoot. A number that simply
		-- appears at full size has no impact; one that arrives has weight, and
		-- weight is the whole reading of a payout.
		--======================================================================
		PopFrom = 0.55,
		PopOvershoot = 1.14,
		PopSeconds = 0.22,
		-- Degrees, plus or minus, chosen per pop. LuckiestGuy is dead upright,
		-- and forty of them rising off one bed in a ruler-straight column looks
		-- printed rather than alive.
		TiltJitter = 6,
		-- Fraction of its life at full opacity before the fade starts. Half,
		-- because the number is the point.
		Hold = 0.5,
	},

	Speed = {
		Font = Enum.Font.Bangers,
		-- Slanted by the typeface. Nothing here rotates the label -- a rotated
		-- upright font reads as a mistake, a genuinely italic one reads as fast.
		Top = Color3.fromRGB(240, 250, 255),
		Bottom = Color3.fromRGB(96, 164, 232),
		-- A cooler ink than the cash pop's, so even the outline is a different
		-- temperature.
		Outline = Color3.fromRGB(16, 26, 46),
		OutlineThickness = 3,
		Width = 104,
		Height = 32,
		RiseStuds = 2.0,
		--======================================================================
		-- IT SLIDES AS IT RISES
		--
		-- Sideways as well as up, alternating by pool slot. Two effects at once:
		-- consecutive pops stop stacking into an illegible column, and the
		-- number reads as being LEFT BEHIND, which is the only thing a speed
		-- readout should ever look like.
		--======================================================================
		DriftStuds = 1.1,
		-- Shorter than the cash pop on purpose. Fast things do not linger.
		Seconds = 0.85,
		-- No pop-in. It is already moving.
		PopFrom = 1,
		PopOvershoot = 1,
		PopSeconds = 0,
		TiltJitter = 0,
		Hold = 0.22,
	},
}

--==============================================================================
-- THE TWO PIECES OF TEXT THE WORLD ITSELF CARRIES
--
-- Everything else in this game that says something is on the HUD -- the cash
-- readout, the world clock, the alarm. These two are in the WORLD, attached to a
-- thing, and until now they were the same GothamBold paper-and-lime as the rest
-- of it: a pod's countdown and a prompt's verb were typographically identical to
-- the corner of the screen, so nothing about them said "this belongs to the
-- object you are looking at".
--
--     POD     what a buried pod is doing, and how long is left of it
--     PROMPT  the key, and the verb it performs
--
-- One is a LABEL on a growing thing and the other is a BUTTON. They should not
-- look like each other either, and neither should look like the HUD.
--==============================================================================
GameConfig.Labels = {
	--==========================================================================
	-- THE POD: A COUNTDOWN, NOT A PROGRESS BAR
	--
	-- ARCADE, since the owner asked for a new face on 2026-09-15. It was
	-- FredokaOne, which the hotbar, the shop and the map signs all wear as well.
	-- Candidates were drawn at the real sizes and colours over sky, fence, soil
	-- and pods in Play:
	--   * the thin faces (Sarpanch, Oswald, Nunito, Kalam, TitilliumWeb, Ubuntu)
	--     washed out once the plate was gone;
	--   * Michroma thinned out over soil;
	--   * BuilderSansExtraBold read well but looked like the HUD.
	-- Arcade stayed crisp on every background, is used nowhere else in the game,
	-- and its blocky digits read as a clock in a blocky world.
	--
	-- One step larger than the plate's 13/18, because a label with nothing
	-- behind it has to carry its own contrast.
	--
	-- The word is warm cream rather than paper white: the Crown colour every
	-- Greenhollow creature already wears, so the label looks like it grew there.
	--
	--======================================================================
	-- THE CLOCK RIPENS FROM AMBER TO GREEN
	--
	-- This is the part that is worth more than the typeface. The number already
	-- says how long is left; the COLOUR says it without being read. A pod
	-- crossing a bed at a glance is amber when it has just gone in and green
	-- when it is nearly out, so a player walking their plot knows which square
	-- to stand near without stopping at any of them.
	--
	-- Green at the end and not at the start, because green is what this whole
	-- palette means by "ready" -- it is the colour of the prompt that replaces
	-- this label the moment the clock runs out.
	--======================================================================
	Pod = {
		Font = Enum.Font.Arcade,
		WordSize = 14,
		ClockSize = 20,
		-- The Crown cream off the species sheet.
		Word = Color3.fromRGB(242, 238, 206),
		ClockYoung = Color3.fromRGB(255, 190, 90),
		ClockReady = Color3.fromRGB(142, 214, 86),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 2,
		--======================================================================
		-- NO PLATE BEHIND IT
		--
		-- The owner had the dark rounded box removed on 2026-09-15, so the words
		-- float over the pod on their own. The outline is what keeps them
		-- readable over sky, grass and soil, so it is the one thing here that
		-- must not be thinned.
		--
		-- The box is still LAID OUT, Width by Height and centred LiftStuds above
		-- the top of the model, because PromptUI stacks the Instant Hatch prompt
		-- on top of it and has to know where the label ends. Height is the two
		-- lines (WordSize + 2, ClockSize + 1) plus PlantUI's 5-pixel padding
		-- above and below.
		--======================================================================
		Width = 124,
		Height = 48,
		LiftStuds = 1.2,
		--======================================================================
		-- NEVER HIGHER THAN A PERSON CAN SEE FROM BESIDE IT
		--
		-- LiftStuds above the model's top was right for a pod you look DOWN at
		-- and wrong for one you look UP at. Measured off the production builder
		-- on 2026-09-18, a nubkin pod's label centre sat 3.6 studs above the soil
		-- at Tiny and 15.6 at Colossal -- off the top of a phone's screen for a
		-- player standing next to it, with the Instant Hatch button stacked
		-- another ~76 pixels above that and culled first.
		--
		-- So the centre is capped this many studs above the SOIL. Measured on a
		-- Nubkin and a Dunebud pod at every tier, Tiny, Big and Huge land under
		-- it (the highest, a Huge Nubkin, at 6.55) and keep exactly the height
		-- they had; Mega and up are held at 6.6, which is just above a
		-- character's eye line and within a third of a stud of where the free
		-- Hatch prompt appears when the clock runs out (6.9 on a Colossal), so the
		-- timer and the prompt that replaces it live in the same place. See
		-- ReachPoint.podLabelLift and ReachPointSpec.
		--======================================================================
		MaxAboveSoil = 6.6,
		-- Pixels a touch-drawn timer and its stacked prompt keep from the edge of
		-- the screen when they are clamped back onto it. See ReachPoint.stack.
		ScreenMargin = 6,
		--======================================================================
		-- THE STRINGS
		--
		-- Growing is unreachable today: PlantService rebuilds a plant at every
		-- stage change and nothing in a bed is ever a sprout, so a pod is a pod
		-- until it is grown. It is here because the stage still exists in
		-- CreatureModel and the day it comes back this is where its word lives
		-- -- not buried in a client as a literal nobody can find.
		--======================================================================
		Hatching = "HATCHING",
		Growing = "GROWING",
	},

	--==========================================================================
	-- A GROWN CREATURE'S OVERHEAD LABEL (2026-10-04, the owner's brief)
	--
	-- SUPERSEDES "a grown plant carries no plate" (PlantUI's banner said why it
	-- was cut: twelve three-line cards over one bed). The owner asked for them
	-- back, after the reference: three outlined lines, no plate --
	--
	--     RARE                     the rarity word, in its own colour or RarityFX
	--     FROSTROOT                the name, the largest line
	--     HUGE • $1.46K/s          the size word in its tier colour (TITAN and
	--                              COLOSSAL in the wheel's own lettering), the
	--                              owner's income per second in the reveal's green
	--
	-- -- no kg anywhere, and no size for a Secret or an unsized event form. Held
	-- in check the way the old cards were not: a fixed pixel size whatever the
	-- creature's size, faded out between NearStuds and FarStuds from the camera
	-- and gone past that, out of the way while the plant is selected for PICK UP,
	-- and the cash pop starts above it instead of through it.
	--
	-- The faces are the game's own: LuckiestGuy is money (the name and the
	-- income, as the hatch reveal draws them) and FredokaOne the Bag's words
	-- (the rarity and the size).
	--==========================================================================
	Plant = {
		RarityFont = Enum.Font.FredokaOne,
		RaritySize = 14,
		NameFont = Enum.Font.LuckiestGuy,
		NameSize = 22,
		InfoFont = Enum.Font.FredokaOne,
		InfoSize = 14,
		IncomeFont = Enum.Font.LuckiestGuy,
		IncomeSize = 15,
		Width = 240,
		Name = Color3.fromRGB(255, 255, 255),
		Separator = Color3.fromRGB(242, 238, 206),
		-- The hatch reveal's income green.
		Income = Color3.fromRGB(142, 214, 86),
		Outline = Color3.fromRGB(16, 21, 28),
		NameOutline = 2,
		LineOutline = 1.5,
		-- Studs over the creature's measured top, where the label's bottom edge sits.
		GapStuds = 0.5,
		-- Camera distance, measured FLAT (across the ground, height ignored):
		-- whole within NearStuds, gone at FarStuds. Flat because a Colossal's
		-- label rides 40+ studs up -- measured to its base in 3D it had started
		-- fading by the time a player stood back far enough to see it (Play,
		-- 2026-10-04: 38 / 58 in 3D became 45 / 70 flat).
		NearStuds = 45,
		FarStuds = 70,
		-- Drawn this much smaller on a touch screen (its pixels are dearer).
		PhoneScale = 0.85,
		-- CLIENT-ONLY attributes on the planted model (never replicated):
		-- PlantPickUI marks the plant it has selected, and PlantUI hides that
		-- plant's label while PICK UP stands where the label would be; PlantUI
		-- publishes the label's drawn height in pixels (0 while it is not shown)
		-- so CashPop starts a pop above it.
		SelectedAttribute = "SeedPickSelected",
		HeightAttribute = "SeedLabelPx",
	},

	--==========================================================================
	-- THE PROMPT: A BUTTON
	--
	-- DenkOne is condensed, geometric and upright -- it reads as a control
	-- rather than as a caption, which is exactly what a prompt is. Distinct from
	-- the faces already in use: LuckiestGuy is money, Bangers is speed, Arcade is
	-- the pod's countdown, GothamBlack is the HUD.
	--
	-- THE VERB IS UPPERCASED HERE rather than in the four places that set an
	-- ActionText. `prompt.ActionText` stays "Pick Up" because that is what it
	-- is; how loudly it is said is this file's business, and a service should
	-- not have to shout to be drawn correctly.
	--==========================================================================
	Prompt = {
		Font = Enum.Font.DenkOne,
		KeySize = 20,
		VerbSize = 21,
		Verb = Color3.fromRGB(248, 246, 240),
		Key = Color3.fromRGB(26, 24, 30),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 2,
		Uppercase = true,
		--======================================================================
		-- A PRICE, WHEN THE PROMPT SELLS SOMETHING
		--
		-- A prompt with a Robux attribute gets the shop's capsule after its verb:
		-- white, the client's own Robux mark in ink, the number in ink. It is the
		-- capsule the shelves print, so a price looks the same everywhere.
		--======================================================================
		PriceFont = Enum.Font.LuckiestGuy,
		PriceSize = 17,
		Capsule = Color3.fromRGB(255, 255, 255),
		-- Pixels between a pod's label and a prompt stacked above it.
		StackGap = 4,
		-- A prompt panel's height in pixels. Its width grows with its verb and
		-- price; its height never does. Here rather than as a literal in
		-- PromptUI because PlantUI has to reserve exactly this much room above a
		-- pod's timer on touch, where the two are clamped onto the screen as one
		-- group -- see ReachPoint.stack.
		PanelHeight = 52,
		-- ON A PHONE, THREE QUARTERS (the owner's call, 2026-10-08: "proximity
		-- prompt on mobile looks too large"). A touch screen whose shorter side
		-- is under PhoneShortSide pixels draws every prompt panel at PhoneScale
		-- -- 170 x 52 becomes about 128 x 39. Tablets and every desktop keep 1.
		-- ReachPoint.promptScale is the one answer PromptUI and PlantUI share.
		PhoneScale = 0.75,
		PhoneShortSide = 500,
	},
}

--==============================================================================
-- ONE COMPACTOR, NOT THREE
--
-- Four places want to shorten a number -- the rate on a grown plant, the `+$N`
-- that pops off it, the Index row, and now every Speed readout in the game --
-- and four hand-rolled versions is how the same plant ends up reading $1.5K in
-- one place and $2K in another. It sits here because here is the module they
-- all already require.
--
-- Not balance, so Rule 7 is intact: this decides how a number is SPELLED, never
-- what it is.
--
--==============================================================================
-- THREE SIGNIFICANT DIGITS, AND THE LADDER RUNS TO Qa
--
-- It was one decimal below ten and none above, which reads fine for cash and
-- destroys the Speed HUD: the whole billions ladder this game is built on
-- collapsed into "12B" for everything from 12.0B to 12.9B, so a player watching
-- their score climb saw it sit still for the better part of an hour.
--
--     under 10     two decimals    1.25K   3.5K    1T
--     10 to 99     one decimal     12.4B   39K
--     100 and up   none            999B    553M    100K
--
-- Trailing zeros are dropped at every width, so 2,000 is "2K" rather than
-- "2.00K" and 1e15 is "1Qa" rather than "1.00Qa" -- which is what keeps the old
-- cash readouts spelled exactly as they were.
--
--     110    ->  110        1500  ->  1.5K       39000  ->  39K
--     2000   ->  2K       100000  ->  100K   553000000  ->  553M
--     12.4e9 -> 12.4B      999e9  ->  999B        1e12  ->  1T
--     1e15   ->  1Qa
--
-- Qa AND NOT Q. "Q" is ambiguous the moment quintillion exists, and this ladder
-- is one save-cap raise away from needing it. Qa/Qi/Sx is the convention the
-- genre already uses.
--
-- THE SAVE CAP IS STILL 1e15 and this does not change that -- the formatter
-- reaching Qa is what lets the CAP be displayed, not a licence to pass it.
--==============================================================================
local COMPACT_UNITS = {
	{ 1e15, "Qa" },
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local function trimZeros(text: string): string
	-- A PLAIN find, so the needle is a full stop and not the PATTERN for one.
	-- It was `"%."` with plain = true, which searches for the two literal
	-- characters percent-full-stop -- never present -- so every value returned
	-- early and the HUD read 1.00K, 3.00B, 1.00Qa. The pattern escape is exactly
	-- what plain mode turns off.
	if not string.find(text, ".", 1, true) then
		return text
	end
	-- Parenthesised: gsub returns the count as a second value, and returning it
	-- would make the caller two-valued.
	text = (string.gsub(text, "0+$", ""))
	return (string.gsub(text, "%.$", ""))
end

function GameConfig.compact(n: number): string
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local v = math.abs(n)
	if v == math.huge then
		-- Not "inf". Nothing in this game is legitimately infinite, so a readout
		-- saying so is a bug report nobody can act on; the cap is the number a
		-- player would actually be at.
		return sign .. GameConfig.compact(GameConfig.Save.MaxSpeedScore)
	end
	for i, unit in ipairs(COMPACT_UNITS) do
		local divisor = unit[1] :: number
		local suffix = unit[2] :: string
		if v >= divisor then
			local scaled = v / divisor
			--==============================================================
			-- 999.6M IS 1B, NOT 1000M
			--
			-- Rounding happens after the unit is chosen, so a value just under
			-- a boundary can round up THROUGH it and print a four-digit
			-- mantissa. Caught here rather than by widening the comparison,
			-- because the comparison is what decides the suffix and it is
			-- correct.
			--==============================================================
			if scaled >= 999.5 and i > 1 then
				local bigger = COMPACT_UNITS[i - 1]
				scaled = v / (bigger[1] :: number)
				suffix = bigger[2] :: string
			end
			local text
			if scaled < 10 then
				text = string.format("%.2f", scaled)
			elseif scaled < 100 then
				text = string.format("%.1f", scaled)
			else
				text = string.format("%.0f", scaled)
			end
			return sign .. trimZeros(text) .. suffix
		end
	end
	return sign .. string.format("%d", math.floor(v))
end

--==============================================================================
-- A BALANCE IS SPELLED DIFFERENTLY FROM A PRICE: GameConfig.money
--
-- compact() is right for prices, rates and Speed, and wrong for the one number
-- a player watches climb. Between 1K and 100K it trimmed its zeros, so the
-- corner read $2K, then $2.01K, then $2.1K -- whole, two decimals, one decimal
-- -- as the same cash came in (reported by an Xbox tester). And it rounds to
-- the NEAREST, so $9,999 read "$10K", the same text as a 10K price the player
-- could not yet pay.
--
-- So a balance has its own rule, one precision at every size, never rounded up:
--
--     under 100,000    whole dollars, commas      0   7   999   1,000   99,999
--     100,000 and up   three significant digits,  100K   123K   1.50M   12.3M
--                      zeros KEPT, rounded down   999K (not 1.00M)   1.00Qa
--
-- Rounded DOWN, so the corner never shows a dollar the player does not have --
-- the same rule every "can I afford this" check applies to the raw number.
-- Zeros KEPT, so the text only changes width when a digit or a unit is gained.
-- Only how the number is SPELLED: balances are stored unrounded, as before.
--==============================================================================
local function groupThousands(whole: number): string
	local digits = string.format("%d", whole)
	local head = #digits % 3
	local parts: { string } = {}
	if head > 0 then
		table.insert(parts, string.sub(digits, 1, head))
	end
	for i = head + 1, #digits, 3 do
		table.insert(parts, string.sub(digits, i, i + 2))
	end
	return table.concat(parts, ",")
end

-- floor(x * 10^places) / 10^places, with the float fuzz that makes 1.23 * 100
-- come out as 122.9999... taken off first.
local function floorTo(x: number, places: number): number
	local f = 10 ^ places
	return math.floor(x * f + 1e-7) / f
end

function GameConfig.money(n: number): string
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local v = math.abs(n)
	if v == math.huge then
		return sign .. GameConfig.money(GameConfig.Save.MaxCash)
	end
	if v < 100e3 then
		return sign .. groupThousands(math.floor(v))
	end
	for _, unit in ipairs(COMPACT_UNITS) do
		local divisor = unit[1] :: number
		if v >= divisor then
			local scaled = v / divisor
			local places = if scaled < 10 then 2 elseif scaled < 100 then 1 else 0
			return sign .. string.format("%." .. places .. "f", floorTo(scaled, places)) .. (unit[2] :: string)
		end
	end
	return sign .. groupThousands(math.floor(v))
end

--==============================================================================
-- HOW HIGH A PLANT ACTUALLY REACHES
--
-- Model:GetBoundingBox() REPORTS IN THE PIVOT'S FRAME, and a creature pivots on
-- a cylinder rolled ninety degrees -- so its X and Y come back swapped and the
-- "height" it hands you is the WIDTH. Measured on real grown models:
--
--     Nubkin     bbox (1.74, 1.11, 1.11)      true height 1.74, width 1.11
--     Spiretip   bbox (4.20, 2.11, 2.11)      true height 4.20, width 2.11
--     Bellchime  bbox (6.41, 4.33, 4.33)      true height 6.41, width 4.33
--
-- Those X values are exactly the finished heights SeedData documents. PlantUI
-- placed its billboard at `bbox.Y * 0.5 + 1.4` and so put a Bellchime's label
-- 3.56 studs up on a plant 6.19 studs tall -- a label INSIDE the head of the
-- most valuable thing in the biome, which nobody spotted because on a Nubkin the
-- same wrong sum lands close enough to look right.
--
-- This measures in WORLD SPACE instead, where there is no frame to be wrong
-- about: the vertical reach of a rotated box is the sum of the absolute vertical
-- components of its three half-axes.
--
-- It lives here because two clients want it -- the name plate and the cash pop
-- -- and two hand-rolled copies of a measurement is how they end up disagreeing
-- about where the top of a plant is.
--==============================================================================
function GameConfig.topOfModel(model: Model, anchor: BasePart): number
	local highest = -math.huge
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf, size = d.CFrame, d.Size
			local reach = math.abs(cf.UpVector.Y) * size.Y * 0.5
				+ math.abs(cf.RightVector.Y) * size.X * 0.5
				+ math.abs(cf.LookVector.Y) * size.Z * 0.5
			highest = math.max(highest, cf.Position.Y + reach)
		end
	end
	if highest == -math.huge then
		return 2
	end
	return highest - anchor.Position.Y
end

--==============================================================================
-- SAVE
--
-- Forward-only. Never lower CurrentVersion without also changing StoreName: an
-- old server reading a newer profile is the one way to lose an account.
--==============================================================================
GameConfig.Save = {
	StoreName = "StealASeed_v1",
	CurrentVersion = 2,
	AutosaveSeconds = 45,
	MinWriteGap = 7,
	RetryAttempts = 4,
	RetryBackoff = 1,

	--==========================================================================
	-- THE STUDIO TEST STORE, AND WHY IT IS NOT A SECOND StoreName
	--
	-- Automated Play tests never load a real save (AGENTS.md). Pointing
	-- Studio's copy of THIS file at a throwaway name was undone by any save of
	-- the file or any Rojo reconnect, and on 2026-09-26 that sent a Play test
	-- into the owner's real save. So SaveService takes a test store from a
	-- StringValue in ServerStorage instead -- a service default.project.json
	-- does not map, so no sync can touch it -- and only in Studio; a live
	-- server never looks. A marker whose value does not match the pattern
	-- refuses EVERY store rather than falling back to the real one.
	-- tools/studio/store_guard.luau checks these same two values.
	--==========================================================================
	TestStoreMarker = "SeedTestStore",
	TestStorePattern = "^Seed%a*Test_[%w_]+$",

	--==========================================================================
	-- THE CEILINGS, AND WHY THEY ARE HERE RATHER THAN IN A BALANCE FILE
	--
	-- Luau numbers are IEEE doubles: exact for integers to 2^53 (~9.007e15) and
	-- silently approximate above it. Silently is the whole problem -- no error,
	-- just cash that stops adding up and a profile that round-trips to a
	-- different value than it left as. That makes these a SAVE INTEGRITY
	-- constraint, not a tuning knob, which is why they live next to the schema.
	--
	-- 1e15 leaves an order of magnitude of headroom under the exact range, so
	-- intermediate arithmetic cannot drift either.
	--
	-- The reference game runs at 2.7 BILLION/sec, which would reach this in
	-- about four days. That is not an argument for a bigger number, because
	-- there isn't one -- 9e15 is only 9x further and no cap survives an
	-- unbounded rate. It is an argument about the RATE, which is ours to set:
	-- plant yields get tuned so Rebirth arrives long before the ceiling does.
	--==========================================================================
	--==========================================================================
	-- HOW MANY HONOURED RECEIPTS ARE REMEMBERED
	--
	-- Only enough to outlive a retry. Roblox re-delivers an unacknowledged
	-- receipt for days, but it re-delivers the SAME one -- so the list only has
	-- to be longer than the number of purchases a player could make between two
	-- saves, and the autosave is every 45 seconds.
	--==========================================================================
	MaxReceipts = 32,
	--==========================================================================
	-- HOW MANY SAVED INSTANT HATCHES A PLAYER CAN HOLD (2026-09-30)
	--
	-- A purchase of an instant hatch that finds nothing it can do -- the saved
	-- record full, and its pod's wait already over -- is kept as one credit
	-- and spent by the next instant hatch that succeeds (PlantService). Nobody
	-- reaches this; it is here so the number a save hands back is bounded like
	-- every other one. A credit past it is not granted, and its receipt stays
	-- open.
	--==========================================================================
	MaxInstantCredits = 1000,
	MaxCash = 1e15,
	MaxSpeedScore = 1e15,
	--==========================================================================
	-- HOW MANY HELD PLANTS COME BACK
	--
	-- The hotbar is saved now, and a saved list is rebuilt into real Tools with
	-- real geometry on join. Roblox gives a Backpack far more slots than a
	-- player can reach, so the cap is about the WORK: twenty-four creatures at
	-- up to forty parts each is already a thousand parts built at the least
	-- convenient moment there is.
	--
	-- The limit is asked when something is ADDED (CarryService.HeldRoom): a
	-- hatch, a pickup or a pod past it is refused. Nothing is cut to it: since
	-- 2026-09-29 ProfileSchema keeps every saved row, however many there are.
	--
	-- PLANTS ONLY SINCE 2026-10-09 (the owner's Phase 1, "More stealing, less
	-- waiting"): hatched plants count here, pods against MaxPods below.
	--==========================================================================
	MaxHeld = 24,
	--==========================================================================
	-- HOW MANY PODS THE BAG HOLDS (2026-10-09, the owner's Phase 1)
	--
	-- Pods hatch in the Bag now (GameConfig.HatchInBag), so they have a room of
	-- their own: a steal at the nest is refused only at this many pods, saved
	-- and carried together. Every pod is still a saved row and a Tool, so the
	-- cap keeps saves small and the Bag responsive; with the average pod ready
	-- in about five minutes nobody should reach it. Asked when a pod is ADDED,
	-- like MaxHeld; nothing is ever cut to it.
	--==========================================================================
	MaxPods = 60,

	--==========================================================================
	-- SESSION LOCK
	--
	-- How long another server's claim on a profile is respected before it is
	-- assumed dead and taken. Too short and a live server gets its profile
	-- stolen mid-session; too long and a player who hops servers waits.
	--
	-- The failure this prevents is the classic one: leave server A, join server
	-- B before A has written, B loads stale data, B saves over A. Progress is
	-- gone and nothing errored.
	--==========================================================================
	SessionLockSeconds = 120,
	LoadAttempts = 5,
	LoadRetryGap = 3,
}

--==============================================================================
-- PODS HATCH IN THE BAG (2026-10-09, the owner's Phase 1, "More stealing, less
-- waiting"; KB/STEAL-MORE-PLAN.md)
--
-- A pod's wait starts the moment it is BANKED: its deadline (os.time(),
-- absolute) is stamped on its saved Bag row and on its Tool as `Attribute`, so
-- it keeps running while the player is away, as planting did. Pods never take a
-- garden bed: placing one is refused (ActionRefusal POD_IN_BAG). A ready pod
-- says READY in the Bag and on the hotbar; HATCH there is the bed prompt's own
-- 1.1 s hold (Plant.HatchHoldSeconds), and HATCH ALL hatches every ready pod.
-- The plant goes straight into a free bed of the player's garden, or into the
-- Bag when no bed is free. Pods planted before this keep growing and hatch
-- where they stand, exactly as before (PlantService.hatch).
--
-- THE VERBS, client -> server on GameEvent; every argument is a claim
-- (PlantService):
--   Hatch      one ready pod, by its item id
--   HatchAll   every ready pod
--   Instant    Instant Hatch on one growing pod, by its item id: a saved credit
--              is spent, else the purchase dialog opens -- the bed prompt's
--              product, price and credits (Plant.InstantHatch)
--   Reply      server -> the asking client: { op, ok, code, planted, bagged,
--              left }
--==============================================================================
GameConfig.HatchInBag = {
	Attribute = "HatchAt",
	-- On the player: how many saved Instant Hatches they hold (PlantService),
	-- so the Bag's Instant Hatch says FREE instead of a price.
	CreditsAttribute = "InstantCredits",
	Hatch = "BagHatch",
	HatchAll = "BagHatchAll",
	Instant = "BagInstantHatch",
	Reply = "BagHatchResult",
	-- One request per player this often; a second inside it is not heard.
	Cooldown = 0.3,
	-- HATCH ALL's reveals one after another, this far apart. Every plant is the
	-- player's the moment the request lands; only the shows are spaced, so a
	-- dozen shells do not burst on one frame.
	AllGapSeconds = 0.4,
	--==========================================================================
	-- WHERE THE HATCH MOMENT PLAYS
	--
	-- At the bed the plant goes into, while the player stands within
	-- RevealAtBedStuds of it. Otherwise -- away from home, or no free bed -- in
	-- front of them, so the moment never plays where nobody sees it: past
	-- Plant.Hatch.HearingStuds (240) a client draws nothing. In front means
	-- FrontStuds ahead of the body plus the shell's own size, and a HATCH ALL
	-- fans its plants across FanSlots places FanDegrees either side.
	--==========================================================================
	RevealAtBedStuds = 120,
	FrontStuds = 9,
	FanDegrees = 50,
	FanSlots = 5,
	--==========================================================================
	-- HATCH FROM THE HANDS (2026-10-10, Michael on v1047: "no way to hatch the
	-- egg in your hotbar without navigating to bag and hatch all")
	--
	-- PodHatch's HATCH over a READY pod's own hotbar slot, in the REMOVE row,
	-- held like the Bag's (Plant.HatchHoldSeconds) and sent as Hatch. A
	-- controller holds HandKey: RT plants the pod (PlantPlace), so LT hatches
	-- it. HandAttribute is client-local on the player while HATCH is offered,
	-- so PlantPlace's reticle names LT beside RT and B.
	--==========================================================================
	HandKey = Enum.KeyCode.ButtonL2,
	HandAttribute = "SeedHandHatch",
	Words = {
		Ready = "READY",
		Hatch = "HATCH",
		HatchAll = "HATCH ALL",
		HoldHatch = "HOLD TO HATCH",
		Instant = "INSTANT HATCH",
		SavedInstant = "FREE INSTANT HATCH",
		-- A pod still growing, with its time left: "READY IN 2:05".
		ReadyIn = "READY IN %s",
		-- Said once a Bag hatch's plant has come up, by where the plants went:
		-- one planted while its moment played away from its bed, one in the Bag
		-- (the garden full), and a HATCH ALL of several.
		PlantedTitle = "PLANTED!",
		PlantedDetail = "It's growing in your garden now.",
		BaggedTitle = "IN YOUR BAG",
		BaggedDetail = "Your garden is full. Place it from your Bag.",
		AllTitle = "%d HATCHED!",
		AllPlanted = "All planted in your garden.",
		AllBagged = "All in your Bag: your garden is full.",
		AllSplit = "%d planted in your garden, %d in your Bag.",
	},
	--==========================================================================
	-- THE OWNER'S ICONS (2026-10-09; each 512 x 512, ids checked by the peer
	-- session). "" puts the drawn stand-in back -- never another upload
	-- standing in. One crop fits all four: their drawn bounds are inside
	-- (41, 41)-(471, 471), so under ScaleType Fit they fill their spots and
	-- draw the same size.
	--   Hatch         a pod cracking with a sprout: HATCH and HATCH ALL
	--   InstantHatch  the pod with a lightning bolt: the Instant Hatch action
	--   Timer         the hourglass, beside a growing pod's countdown
	--   Ready         a green check badge, on a ready pod's tile
	--==========================================================================
	Icons = {
		Hatch = "rbxassetid://70562570593192",
		InstantHatch = "rbxassetid://111764150121238",
		Timer = "rbxassetid://111370496768773",
		Ready = "rbxassetid://131185686807584",
	},
	IconCropOffset = Vector2.new(41, 41),
	IconCropSize = Vector2.new(430, 430),
}

--==============================================================================
-- THE OWNER'S 25 PODS (2026-10-09; KB/POD-MODELS-PLAN.md, approved: "approve
-- but let claude terminal build")
--
-- PodForms holds them as data, PodModel builds one at a tier's size for
-- CreatureModel.BuildPod, and PodMotion (client) plays their idles.
--==============================================================================
GameConfig.PodModels = {
	-- THE BOX, in D (SeedData.PodDiameter). A pod without the owner's designed
	-- size is scaled until its wider footprint side reaches MaxWidth x D or its
	-- height MaxHeight x D, whichever comes first; a lid pod keeps the owner's
	-- designed ClosedWidth x D. The carry grip, the guardian haul and the nest
	-- ring are built for this box (the old pods ran 1.21 to 1.46 D tall).
	MaxWidth = 1.25,
	MaxHeight = 1.45,
	-- NO BASE AND NO RING (the owner, 2026-10-09: "remove the base if there is a
	-- base below the pods"). The base each pod stood on is left out of its form
	-- (PodForms), and a pod without a SizeSeam of its own (the 12 studded pods
	-- and Bogbonnet) shows its size by its scale: a ring round its foot would
	-- read as the base again. A lid pod's own SizeSeam takes the tier's colour.
	--
	-- THE COLOSSAL'S CORE, in D: a Neon ball at the Shell's centre, inside the
	-- pod, so the owner's outline is unchanged. Its light and the stronger aura
	-- hang on it and reach out through the shell; it shows through a lid's peek.
	CoreDiameter = 0.34,
	-- PALE PODS GLOW SOFTER (2026-10-09, the owner's approval: "approve your
	-- suggestions"). A Colossal's two lights -- its core's and its aura's --
	-- follow the pod's own brightness (PodModel.Brightness: its visible parts'
	-- mean luminance, by area): full at From and under, Floor of their strength
	-- and RangeFloor of their reach at To and over, straight between. Seen in
	-- Play: those lights, not the aura's halo, washed the pale Greenhollow and
	-- Dustbowl pods out white, and a neighbour's light added to it. The halo is
	-- unchanged.
	PaleGlow = { From = 0.42, To = 0.6, Floor = 0.15, RangeFloor = 0.5 },
	-- On every pod PodModel builds, put on last: PodMotion animates by it.
	Tag = "PodRig",
	-- On the model: which of the owner's pods it is (CarryService drops the
	-- owner's joints from a carried or held one by it).
	FormAttribute = "PodForm",
	-- POD MOTION (client). Only pods in the Workspace that are anchored (not
	-- carried or hauled) and within Range studs of the camera move: a nest's or a
	-- loose pod (SeedPod), a planted one (Planted), or one on a stand that sets
	-- ShowcaseAttribute. Viewport copies stay still; REDUCED FX stills every one.
	-- NOTHING BREATHES (the owner, 2026-10-09: "disable breathing animation on
	-- pods"): no pod's body bobs; a studded pod's joints wave as its script
	-- waved them, a lid pod's lid peeks, and both pulse their lights.
	Motion = {
		Range = 120,
		-- HOW OFTEN A POD IS STEPPED. Moving anchored parts costs about 5 us a
		-- part a frame (measured 2026-10-09, Studio Play), so only the parts a
		-- joint moves are written, and a pod within NearStuds of the camera
		-- steps every NearEvery frames, one further off every FarEvery, each on
		-- its own frame so the cost is spread, never bunched.
		NearStuds = 60,
		NearEvery = 2,
		FarEvery = 4,
		ShowcaseAttribute = "PodShowcase",
		-- A READY pod (an old save's planted pod with its Ready attribute): a
		-- studded pod's idle runs ReadySpeed times faster; a lid pod's lid stands
		-- ReadyOpen open (the owner's OpenAmount, 0..1), eased in over ReadyEase
		-- seconds.
		ReadySpeed = 2,
		ReadyOpen = 0.45,
		ReadyEase = 0.6,
		-- A LID POD'S IDLE (new: the owner's lid pods had none): the lid peeking
		-- open to PeekOpen and shut again over PeekSeconds, every PeekEvery
		-- seconds, and its lights pulsing GlowPulse either side of their
		-- brightness.
		PeekOpen = 0.08,
		PeekEvery = 5.5,
		PeekSeconds = 1.4,
		GlowPulse = 0.25,
	},
}

--==============================================================================
-- THE POD GUIDE (2026-10-09; KB/POD-GUIDE-PLAN.md, the owner's approval)
--
-- What a pod hatches, taught OUTSIDE the pod -- a pod carries no words at all
-- (2026-09-17). One stand just inside each biome's arch, beside the road: the
-- biome's five pods turning slowly on a carousel, and a board that pairs each
-- pod with its plant (a "???" silhouette until grown), its rarity and how
-- often a nest stocks it, over the seven sizes' odds and what each is worth.
-- Every client builds the stands for itself (PodGuideUI; nothing replicates);
-- every number is PodGuide's, from the rolls' own data.
--==============================================================================
GameConfig.PodGuide = {
	-- WHERE, in each biome's own frame: X across the road (+ is the right going
	-- in), In studs inside its arch. Clear of the racing line (|X| under 24)
	-- and of the props near each arch (MapDecor, measured 2026-10-09):
	-- Starbloom's right side is its fan trees', so its stand is on the left.
	-- In was 9.5 until the board grew half again (2026-10-10, below): 13 keeps
	-- the wider board inside the arch.
	Spots = {
		greenhollow = { X = 40, In = 13 },
		dustbowl = { X = 40, In = 13 },
		tanglemire = { X = 40, In = 13 },
		emberroot = { X = 40, In = 13 },
		starbloom = { X = -40, In = 13 },
	},
	-- THE CAROUSEL: the five pods at PodTier (Big), Radius from the centre of a
	-- turntable TurntableRadius wide and TurntableHeight tall, each facing out;
	-- one turn every TurnSeconds (held still for reduced motion). Built while
	-- the camera is within BuildStuds of a stand, freed past FreeStuds; turned
	-- only within TurnStuds.
	PodTier = 2,
	Radius = 3.7,
	TurntableRadius = 5.6,
	TurntableHeight = 1,
	TurnSeconds = 40,
	BuildStuds = 150,
	FreeStuds = 180,
	TurnStuds = 90,
	-- THE BOARD: BoardBack studs behind the carousel's centre (away from the
	-- road), facing the road, BoardSize at PixelsPerStud, its top BoardTopY over
	-- the ground. Not drawn past MaxDistance; its pictures built within
	-- PreviewNearStuds and freed past PreviewFarStuds, checked every
	-- CheckSeconds (TOP CREATURES' own rule).
	-- HALF AGAIN AS BIG since 2026-10-10 (Michael on v1047: "scale up the size
	-- on them 50% maybe"; the owner approved): 15 x 8.4 at 60 px a stud until
	-- then. The canvas is the same 900 x 504 px, so every line grows with it;
	-- its foot stays 3.0 over the ground.
	BoardBack = 8,
	BoardSize = Vector3.new(22.5, 12.6, 0.46),
	BoardTopY = 15.6,
	PostWidth = 0.7,
	RimStuds = 0.14,
	PixelsPerStud = 40,
	MaxDistance = 120,
	PreviewNearStuds = 60,
	PreviewFarStuds = 75,
	CheckSeconds = 0.25,
	Words = {
		Title = "%s PODS",
		Sub = "EACH POD HATCHES ITS OWN PLANT. HOW OFTEN A NEST HAS IT:",
		Sizes = "SIZE",
		SizeChance = "CHANCE",
		SizeWorth = "INCOME",
		Secret = "SECRET POD: %s CHANCE A NEST RAISES ONE",
		-- The Bag: a pod's tile and its menu's way to the Almanac.
		BagTitle = "%s pod",
		WhatsInside = "WHAT'S INSIDE?",
		-- A chance, "1 in N" (2026-10-10, the owner: "can we make it 1 in 1000";
		-- PodGuide.odds). The boards write it in capitals like their other lines.
		Odds = "1 in %s",
		-- The Almanac: a card's chance, its detail page's lines.
		CardChance = "%s pods",
		HatchesFrom = "Hatches from its own pod: %s %s nest pods",
		IncomeTitle = "Income by size",
		SizesTitle = "POD SIZES",
	},
}

-- How deep a plot with this many bed rows has to be. One expression, read by
-- the tier table, the map builder and the field-size check alike.
function GameConfig.plotDepthFor(rows: number): number
	local P = GameConfig.Plot
	return P.BedMargin * 2 + rows * P.RowDepth + (rows - 1) * P.RowGap
end

-- Where a plot's mill stands, from the plot's GATE frame (the gate line's
-- middle, the plot's own facing): GameConfig.Mill.Place -- in front of plots
-- 1-5, beside plot 6's right-hand fence. The gate never moves, so neither does
-- the mill, at any level.
function GameConfig.millStandsBeside(plotId: number?): boolean
	return plotId ~= nil and GameConfig.Mill.Place.BesidePlots[plotId] == true
end

-- The mill's frame in its plot's gate frame.
function GameConfig.millPlacementFor(plotId: number?): CFrame
	local P = GameConfig.Mill.Place
	if GameConfig.millStandsBeside(plotId) then
		local B = P.Beside
		return CFrame.new(GameConfig.Plot.Width * 0.5 + B.Side, P.Lift, B.Behind)
			* CFrame.Angles(0, math.rad(B.Yaw), 0)
	end
	local F = P.Front
	return CFrame.new(F.Out, P.Lift, -F.Ahead) * CFrame.Angles(0, math.rad(F.Yaw), 0)
end

function GameConfig.millCFrameFor(gateCF: CFrame, plotId: number?): CFrame
	return gateCF * GameConfig.millPlacementFor(plotId)
end

-- And back: the gate frame a mill stands off, from the mill's own frame (its
-- pivot) -- what TreadmillService has when it rebuilds one.
function GameConfig.millGateFor(millCF: CFrame, plotId: number?): CFrame
	return millCF * GameConfig.millPlacementFor(plotId):Inverse()
end

--==============================================================================
-- A LEVEL, CLAMPED TO THE LADDER
--
-- What every lookup below does with what it is handed: a number from a future
-- build, a corrupted one or none at all must still name a real level.
--==============================================================================
local function clampLevel(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	return math.clamp(math.floor(n :: number), 1, #GameConfig.PlotTiers)
end

--==============================================================================
-- WHICH SHAPE A PLOT GROWS INTO (2026-10-07)
--
-- "Front" for a plot whose mill stands in front of it (plots 1-5), "Beside"
-- for one whose mill stands beside its right-hand fence (plot 6). The two are
-- the same plot at Levels 1-5; from Level 6 the Front plots' wing grows forward
-- (Plot.SideBed) and the Beside plot grows deeper (Plot.Beside). Asked by plot
-- ID -- the PlotId every plot model carries -- and nil, or an id no plot has,
-- is a Front plot.
--==============================================================================
function GameConfig.plotLayoutFor(plotId: number?): string
	return if GameConfig.millStandsBeside(plotId) then "Beside" else "Front"
end

-- Whether this plot, at this level, has the Beside shape's own rows.
local function besideAt(level: number, plotId: number?): boolean
	return GameConfig.millStandsBeside(plotId) and GameConfig.Plot.Beside.Rows[level] ~= nil
end

-- The main bed's rows on THIS plot: PlotTiers' (plotRowsForTier) everywhere
-- but where Plot.Beside names its own.
function GameConfig.plotRowsFor(tier: number?, plotId: number?): number
	local level = clampLevel(tier)
	if besideAt(level, plotId) then
		return GameConfig.Plot.Beside.Rows[level]
	end
	return GameConfig.PlotTiers[level].rows
end

-- How deep THIS plot is at this level, gate to back fence.
function GameConfig.plotDepthForPlot(tier: number?, plotId: number?): number
	return GameConfig.plotDepthFor(GameConfig.plotRowsFor(tier, plotId))
end

--==============================================================================
-- HOW WIDE A PLOT IS AT A GIVEN LEVEL, WING INCLUDED
--
-- Levels 1 and 2 are the plain rectangle they have always been. From Level 3
-- the footprint is an L: full width at the front, wider across the back half.
-- From Level 6 a Front plot's L reaches nearly to the gate, and the Beside plot
-- keeps Level 5's wing (Plot.Beside). `plotId` is optional: without it the
-- answer is a Front plot's.
--==============================================================================
function GameConfig.plotSideRowsForTier(tier: number?, plotId: number?): number
	local level = clampLevel(tier)
	if besideAt(level, plotId) then
		level = GameConfig.Plot.Beside.WingLevel
	end
	return GameConfig.Plot.SideBed.RowsByLevel[level] or 0
end

function GameConfig.plotHasSideBed(tier: number?, plotId: number?): boolean
	return GameConfig.plotSideRowsForTier(tier, plotId) > 0
end

--==============================================================================
-- WHERE THE WING SITS, IN PLOT-LOCAL Z
--
-- Rear-anchored: its BACK edge lines up with the main bed's back edge, and it
-- reaches forward only as far as its own rows need. Returns front and back Z,
-- or nil when the level has no wing.
--
-- The main bed spans `rows * RowDepth + (rows - 1) * RowGap` centred on the
-- plot, so its back edge is at half that. The wing shares it.
--
-- THE BESIDE PLOT AT LEVELS 6-7 is the one exception: its wing is Level 5's
-- bed, the same distance behind the gate, written in this level's own frame --
-- so it stops short of the plot's back fence (plotWingZ).
--==============================================================================
function GameConfig.plotSideBedZ(tier: number?, plotId: number?): (number?, number?)
	local level = clampLevel(tier)
	local P = GameConfig.Plot
	if besideAt(level, plotId) then
		local wingLevel = P.Beside.WingLevel
		local front, back = GameConfig.plotSideBedZ(wingLevel)
		if not (front and back) then
			return nil, nil
		end
		-- The frame's centre sits half the depth behind the gate, so a bed that
		-- stays put moves by half the difference in this level's numbers.
		local shift = (GameConfig.plotDepthForPlot(wingLevel) - GameConfig.plotDepthForPlot(level, plotId)) * 0.5
		return front + shift, back + shift
	end
	local sideRows = GameConfig.plotSideRowsForTier(level)
	if sideRows <= 0 then
		return nil, nil
	end
	local mainRows = GameConfig.plotRowsForTier(level)
	local backZ = (mainRows * P.RowDepth + (mainRows - 1) * P.RowGap) * 0.5
	local span = sideRows * P.RowDepth + (sideRows - 1) * P.RowGap
	-- Capped so the wing's FENCE -- which stands WingMargin + a frame width
	-- forward of the bed -- can never reach past the treadmill. RowsByLevel is
	-- already chosen to satisfy this; the clamp is here so that changing a row
	-- count can shorten a bed but can never fence in the mill. From
	-- ForwardFromLevel the mill is in front of the plot and the cap is the gate
	-- line instead: MinBehindGate studs behind it, in this level's own frame.
	local minBedFront = if level < P.SideBed.ForwardFromLevel
		then P.SideBed.WingFrontZ + P.SideBed.WingMargin + P.BedFrameWidth
		else -GameConfig.plotDepthFor(mainRows) * 0.5 + P.SideBed.MinBehindGate + P.SideBed.WingMargin
			+ P.BedFrameWidth
	return math.max(backZ - span, minBedFront), backZ
end

--==============================================================================
-- THE WING'S OWN FENCE LINES, IN PLOT-LOCAL Z
--
-- Front: WingMargin and a frame width ahead of its bed. Back: BedMargin behind
-- it, which is the plot's back fence on every plot but the Beside one at Levels
-- 6-7, whose wing ends where Level 5's did. Nil when the level has no wing.
-- MapService builds the fences on these and stamps them as WingFrontZ and
-- WingBackZ; PlantWander and MiniEventService read them back off the plot.
--==============================================================================
function GameConfig.plotWingZ(tier: number?, plotId: number?): (number?, number?)
	local front, back = GameConfig.plotSideBedZ(tier, plotId)
	if not (front and back) then
		return nil, nil
	end
	local P = GameConfig.Plot
	return front - P.SideBed.WingMargin - P.BedFrameWidth, back + P.BedMargin
end

--==============================================================================
-- EVERYTHING A PLOT FENCES IN, FROM ITS GATE
--
-- Rectangles on the fence lines, in the GATE's frame: x across (+x the wing's
-- side), d behind the gate line. The main rectangle, and the wing when the
-- level has one. Read by MapDecor (nothing is dressed where a plot will ever
-- stand), MapService's fit check and the plot specs -- the shape at every
-- level of every plot, without building one.
--==============================================================================
function GameConfig.plotFootprint(tier: number?, plotId: number?): { { x0: number, x1: number, d0: number, d1: number } }
	local P = GameConfig.Plot
	local depth = GameConfig.plotDepthForPlot(tier, plotId)
	local halfW = P.Width * 0.5
	local out = { { x0 = -halfW, x1 = halfW, d0 = 0, d1 = depth } }
	local front, back = GameConfig.plotWingZ(tier, plotId)
	if front and back then
		table.insert(out, {
			x0 = halfW,
			x1 = halfW + P.SideBed.WingWidth,
			d0 = front + depth * 0.5,
			d1 = math.min(back + depth * 0.5, depth),
		})
	end
	return out
end

--==============================================================================
-- HOW FAR FROM THE GATE A PLANT CAN ACTUALLY STAND
--
-- The gate is the one fixed landmark in a plot: local -Z faces it, so a plant's
-- distance from it is `z + depth/2` -- a number that survives the plot being
-- rebuilt at a different depth, which is exactly what an upgrade does and what
-- the v1 -> v2 migration has to reason about.
--
-- The reachable range is set by the SOIL, not the plot. Soil is centred on the
-- plot and spans `depth - BedMargin * 2`, and PlantService keeps plants
-- EdgeMargin inside that, so both ends come out as a constant inset from the
-- fence. Near edge is `BedMargin + EdgeMargin` at every level -- the bed always
-- starts the same distance behind the gate -- and only the far edge grows.
--
-- Two callers need the same answer and must not each derive it: the migration,
-- deciding whether an old garden reaches, and anything later that has to place
-- a plant against a plot it is not standing in.
--==============================================================================
function GameConfig.plotGateReach(rows: number): (number, number)
	local P = GameConfig.Plot
	local inset = P.BedMargin + GameConfig.Plant.EdgeMarginStuds
	local depth = GameConfig.plotDepthFor(rows)
	return inset, math.max(depth - inset, inset)
end

--==============================================================================
-- THE INVISIBLE GRID, WHICH IS NOT THE CAPACITY
--
-- Still how many attachment points a bed of `rows` rows has, and MapService and
-- PlantService both lay plants out against it. It is NOT how many plants a plot
-- may hold -- that is plotCapacityForTier below, and confusing the two is the
-- bug this pass exists to remove.
--==============================================================================
--==============================================================================
-- WHERE THE PLOT'S UPGRADE BOARD STANDS
--
-- Beside the gate, on the front fence line, turned to face whoever is walking
-- up to it -- the same relationship the mill's board has to the mill.
--
-- THE FRONT EDGE NEVER MOVES. A plot grows BACKWARDS: PlotSpec asserts the gate
-- does not move at any level pair and that the back edge takes the whole depth
-- change. So a board placed off the front is placed once and is still right at
-- Level 5, which is what keeps this out of the drift the mill sign once had.
--
-- The X is arithmetic, not taste. The board is 9 * Mill.Sign.Scale = 6.84 wide
-- and the gate gap is GateWidth 13, so the gate's edge is at 6.5. Clearing it by
-- 1.2 puts the board's inner edge at 7.7 and its centre at 11.12; the fence
-- corner is at Width/2 = 24, so it sits in the middle of the fence run with
-- room on both sides.
--==============================================================================
-- `plotId` (2026-10-07): plot 6 is deeper than the rest at Levels 6-7, so a
-- centre at one of those levels needs the plot's own depth to find its gate.
function GameConfig.plotSignBase(plotCF: CFrame, level: number?, plotId: number?): CFrame
	local P = GameConfig.Plot
	local S = P.Sign
	local halfD = GameConfig.plotDepthForPlot(level, plotId) * 0.5
	return plotCF
		* CFrame.new(S.OffsetX, S.GroundY, -halfD - S.Standoff)
		* CFrame.Angles(0, math.rad(S.YawDegrees), 0)
end

--==============================================================================
-- WHERE THE TOP CREATURES BOARD STANDS (2026-10-05)
--
-- Beside the upgrade board, on its outer side (Plot.Showcase): the upgrade
-- board's outer edge, then Gap, then this board's rim, then half its plank.
-- Off the same front edge as plotSignBase, so it is placed once and is still
-- right at Level 5. The 9 is MillModel.BuildSign's board width before
-- Mill.Sign.Scale -- PlotShowcaseSpec measures the built upgrade board and
-- holds the gap to what this says.
--==============================================================================
function GameConfig.plotShowcaseX(): number
	local P = GameConfig.Plot
	local SC = P.Showcase
	local signHalf = 9 * GameConfig.Mill.Sign.Scale * 0.5
	return P.Sign.OffsetX - signHalf - SC.Gap - SC.RimStuds - SC.BoardSize.X * 0.5
end

function GameConfig.plotShowcaseBase(plotCF: CFrame, level: number?, plotId: number?): CFrame
	local SC = GameConfig.Plot.Showcase
	local halfD = GameConfig.plotDepthForPlot(level, plotId) * 0.5
	return plotCF
		* CFrame.new(GameConfig.plotShowcaseX(), SC.GroundY, -halfD - SC.Standoff)
		* CFrame.Angles(0, math.rad(SC.YawDegrees), 0)
end

function GameConfig.plotSlotsFor(rows: number): number
	return rows * GameConfig.Plot.BedColumns
end

--==============================================================================
-- HOW MANY PLANTS A LEVEL HOLDS
--
-- The single answer, for the server that enforces it and the two panels that
-- display it. Clamped rather than nil-returning: a profile carrying a level
-- from a future build, or a corrupted one, must still be able to garden.
--==============================================================================
function GameConfig.plotCapacityForTier(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	local level = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
	return GameConfig.PlotTiers[level].capacity
end

function GameConfig.plotRowsForTier(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	local level = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
	return GameConfig.PlotTiers[level].rows
end

--==============================================================================
-- THE LOWEST LEVEL THAT WOULD HOLD THIS MANY PLANTS
--
-- Used by the migration, which must never decide a saved garden does not fit.
-- Answers the TOP level when nothing fits, because the alternative -- refusing,
-- or silently choosing a level too small -- is how saved plants get discarded.
--==============================================================================
function GameConfig.plotLevelForPlants(count: number?): number
	local n = math.max(math.floor(tonumber(count) or 0), 0)
	for level, tier in ipairs(GameConfig.PlotTiers) do
		if n <= tier.capacity then
			return level
		end
	end
	return #GameConfig.PlotTiers
end

--==============================================================================
-- DERIVED
--
-- Computed rather than typed, so the two halves of the field can never disagree
-- with the whole. Set before the freeze, because after it they cannot be.
--==============================================================================
GameConfig.Map.FieldDepth = GameConfig.Map.FieldFront + GameConfig.Map.FieldBack
-- The field is not centred on the origin any more, so anything placing the slab
-- itself needs this. The ROAD side stays at -FieldFront regardless.
GameConfig.Map.FieldCenterZ = (GameConfig.Map.FieldBack - GameConfig.Map.FieldFront) * 0.5

-- The deepest tier's back edge, on any plot -- the Beside plot's rows count
-- (Plot.Beside). Whether every plot's every level stands on the field is
-- MapService's fit check, plot by plot (plotFootprint), since 2026-10-07: the
-- deepest plot points at the field's FRONT, not at FieldBack.
do
	local deepest = 0
	for level, tier in ipairs(GameConfig.PlotTiers) do
		deepest = math.max(deepest, GameConfig.plotDepthFor(tier.rows),
			GameConfig.plotDepthFor(GameConfig.Plot.Beside.Rows[level] or tier.rows))
	end
	GameConfig.Plot.MaxDepth = deepest
	-- How far from the hub the deepest tier reaches. The ring equivalent of the
	-- old MaxBackZ.
	GameConfig.Plot.MaxReach = GameConfig.Map.PlotRingInner + deepest
	--==========================================================================
	-- THE FIELD'S SCATTER STAYS WHERE IT WAS ROLLED (2026-10-07)
	--
	-- MapDecor dresses the field outside this radius (+18), and it was rolled
	-- around Level 5 plots: MaxReach then. Levels 6-7 reach further, and letting
	-- the radius follow would re-roll every daisy, fern and oak on the field. So
	-- it is pinned at Level 5's reach, and the few props a Level 6-7 plot would
	-- stand on are taken out instead (MapDecor's clearOfPlots).
	--==========================================================================
	GameConfig.Plot.DecorReach = GameConfig.Map.PlotRingInner + GameConfig.plotDepthFor(GameConfig.PlotTiers[5].rows)
end

--==============================================================================
-- THE REBIRTH TITLES' LEAVES, FLOWERS AND MIST (2026-10-10, the owner's brief)
--
-- Cosmetic only, on each viewer's own screen (OwnerTitleUI, TitleFX): a few
-- small Kenney silhouettes (CC0; art/title-fx-2026-10-10, its MANIFEST.md)
-- round the words of a rebirth title, behind them and inside the title's own
-- band, so ADMIN over it and the name under it stay clear. No panel, no light,
-- no fog. The celebration and the body aura are not touched.
--
-- WHICH: a title's ladder step -- its player's Rebirths attribute through
-- Rebirth.title, never the words on the board -- names a profile in Steps. A
-- step not listed draws none: GAIA keeps its rainbow alone.
--
-- THE ART: the owner's uploads, by name. "" keeps every profile that needs it
-- off: never another upload standing in. A sprite shows only once its picture
-- has loaded (SettleSeconds after it was made, the IsLoaded rule), so one that
-- fails leaves the words as they were.
--
-- BUDGET: at most MaxSprites a title, moving on the MaxAnimated titles nearest
-- this camera (the others show their words alone), all from OwnerTitleUI's one
-- loop; none at all under Reduced FX (StatusText.reducedMotion).
--
-- Every size and distance is in the title's own pixels at desktop size
-- (Rebirth.Title.Size); a phone's smaller title shrinks them with it.
--==============================================================================
GameConfig.TitleFX = {
	-- The owner's uploads (2026-10-10, CrazyCozy Games, each an Image; Edit
	-- fetched every one), art/title-fx-2026-10-10/upload/<name>.png.
	Art = {
		-- Kenney Foliage Sprites, PNG/Flat (white silhouettes, tinted here).
		LeafRound = "rbxassetid://105951895064835", -- sprite_0030: a teardrop leaf; pink, a petal
		LeafPoint = "rbxassetid://96967429910080", -- sprite_0031: a pointed leaf
		LeafSerrate = "rbxassetid://133671352096183", -- sprite_0038: a toothed leaf on its stalk
		Blossom = "rbxassetid://118683858092487", -- sprite_0040: a round blossom
		SprigLeft = "rbxassetid://87735916751330", -- sprite_0041 mirrored: a leafy sprig for the left side
		SprigRight = "rbxassetid://96083382301295", -- sprite_0041: the same sprig for the right side
		-- Kenney Smoke Particles, PNG/White puff (white, tinted lilac here).
		MistA = "rbxassetid://72752875696615", -- whitePuff00
		MistB = "rbxassetid://131352141653475", -- whitePuff04
	},
	MaxSprites = 6,
	MaxAnimated = 4,
	SettleSeconds = 0.3,
	--==========================================================================
	-- LIVELIER (2026-10-10, the owner: "title effects look lame, how can we
	-- improve it, like rapid animations, specially on gaia, a rapid rainbow
	-- color"): every motion about twice as quick; a white glint sweeping across
	-- every title's words; the owner's rebirth sparkle sheet twinkling on them;
	-- GAIA's rainbow flowing a whole turn every RainbowSeconds, with rainbow
	-- petals and blossoms shooting from its ends. A smooth hue flow, never a
	-- brightness jump; all of it still under Reduced FX.
	--==========================================================================
	RainbowSeconds = 1.2,
	-- A band Width of the words wide, Strength opaque at its middle, crossing
	-- in Sweep every Every seconds, leaning Rotation degrees.
	Glint = { Every = 2, Sweep = 0.5, Width = 0.16, Strength = 0.15, Rotation = 18 },
	-- Each twinkle pops through the sheet's Frames (2 x 2, 256 px each: dot,
	-- short rays, the largest, short rays) in Pop seconds, rests Rest[1] to
	-- Rest[2], then pops again somewhere else on the words. On top of the words.
	Twinkle = {
		Art = GameConfig.Rebirth.Celebration.Textures.Sparkle,
		Count = 3,
		Size = 22,
		Pop = 0.4,
		Rest = { 0.3, 1.1 },
		Frames = { 1, 2, 3, 2 },
		Cell = 256,
	},
	-- THE "?" TITLES LIST (2026-10-10, the owner: "add them to the ? list too"):
	-- each row's words stand Room further in for the left sprites (no more: the
	-- narrowest list's longest row must still draw at 20 of its 22, RebirthSpec);
	-- a LOCKED row's sprites keep only (1 - LockedFade) of themselves, like its
	-- words.
	List = { Room = 14, LockedFade = 0.5 },
	-- Seen with the owner's art in Play (2026-10-10, desktop, day): the leaves at
	-- 11 px and the sprigs at 22 read as specks and the mist at 0.8 was all but
	-- gone, so the leaves are 13, the sprigs 24, the mist 0.72 -- still faint.
	Profiles = {
		-- NATURE: small leaves drifting out from beside the words and a little
		-- down, turning as they go, fading in and out.
		nature = {
			Motion = "drift",
			Art = { "LeafRound", "LeafPoint", "LeafSerrate" },
			Tints = { Color3.fromRGB(165, 235, 120), Color3.fromRGB(110, 215, 125), Color3.fromRGB(215, 245, 140) },
			Size = 13,
			Seconds = 2.4,
			Travel = 20,
			Fall = 6,
			Turn = 140,
			Transparency = 0.1,
		},
		-- BLOOM: pink petals and blossoms easing outward from the words' ends.
		bloom = {
			Motion = "outward",
			Art = { "LeafRound", "Blossom" },
			Tints = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(255, 205, 232) },
			Size = 13,
			Seconds = 2.8,
			Travel = 24,
			Fall = 5,
			Turn = 100,
			Transparency = 0.1,
		},
		-- GOLD: a sprig at each end of the words, swaying a few degrees, and the
		-- odd gold leaf drifting beyond them. Never over the name.
		gold = {
			Motion = "laurel",
			Art = { "SprigLeft", "SprigRight", "LeafSerrate" },
			Tints = { Color3.fromRGB(255, 214, 95), Color3.fromRGB(240, 185, 70) },
			Size = 24,
			-- The loose leaves beyond the sprigs.
			LeafArt = "LeafSerrate",
			LeafSize = 11,
			Seconds = 3,
			Sway = 9,
			Travel = 12,
			Fall = 5,
			Turn = 30,
			Transparency = 0.15,
		},
		-- MYSTIC: faint lilac mist behind the left and right of the lettering,
		-- breathing slowly; the middle stays clear.
		mystic = {
			Motion = "mist",
			Art = { "MistA", "MistB" },
			Tints = { Color3.fromRGB(205, 175, 255), Color3.fromRGB(175, 145, 245) },
			Size = 32,
			Seconds = 4.5,
			Drift = 9,
			Turn = 12,
			Transparency = 0.72,
			Breathe = 0.02,
		},
		-- THE 100 TITLES' OWN (2026-10-10), for the families no profile above
		-- wore: DAWN, MYSTIC's mist in sky blue and soft white (Dawn and
		-- radiance); ASTRAL, the mist in lavender and cyan (Astral grove);
		-- GENESIS, GOLD's sprigs and leaves in rose gold and ivory (Genesis).
		dawn = {
			Motion = "mist",
			Art = { "MistA", "MistB" },
			Tints = { Color3.fromRGB(150, 215, 255), Color3.fromRGB(225, 240, 255) },
			Size = 32,
			Seconds = 4.5,
			Drift = 9,
			Turn = 12,
			Transparency = 0.72,
			Breathe = 0.02,
		},
		astral = {
			Motion = "mist",
			Art = { "MistA", "MistB" },
			Tints = { Color3.fromRGB(190, 170, 255), Color3.fromRGB(150, 235, 255) },
			Size = 32,
			Seconds = 4.5,
			Drift = 9,
			Turn = 12,
			Transparency = 0.72,
			Breathe = 0.02,
		},
		genesis = {
			Motion = "laurel",
			Art = { "SprigLeft", "SprigRight", "LeafSerrate" },
			Tints = { Color3.fromRGB(241, 190, 164), Color3.fromRGB(255, 236, 214) },
			Size = 24,
			LeafArt = "LeafSerrate",
			LeafSize = 11,
			Seconds = 3,
			Sway = 9,
			Travel = 12,
			Fall = 5,
			Turn = 30,
			Transparency = 0.15,
		},
		-- GAIA (the rainbow step): rainbow petals and blossoms shooting from the
		-- words' ends, each its own hue flowing with the words' (RainbowSeconds),
		-- and a fourth twinkle.
		gaia = {
			Motion = "outward",
			Rainbow = true,
			Art = { "Blossom", "LeafRound" },
			Tints = { Color3.fromRGB(255, 255, 255) },
			Size = 12,
			Seconds = 1.4,
			Travel = 26,
			Fall = 6,
			Turn = 160,
			Transparency = 0.05,
			Twinkles = 4,
		},
	},
	-- The ladder's steps by their words (GameConfig.Rebirth.Title.Ladder), each
	-- to a profile and how many sprites. GAIA wears its own rainbow profile.
	-- The 100 titles (2026-10-10) by family: Garden apprentices NATURE; Grove
	-- wardens MYSTIC (the GROVE names) and BLOOM; Thorn and root, Canopy NATURE;
	-- Ancient forest and World tree GOLD; Dawn DAWN; Immortal bloom BLOOM; Astral
	-- ASTRAL; Genesis GENESIS. The fifteen founders' as they were.
	Steps = {
		["GAIA"] = { Profile = "gaia", Count = 6 },
		["SPROUT"] = { Profile = "nature", Count = 2 },
		["SEEDLING"] = { Profile = "nature", Count = 3 },
		["GARDENER"] = { Profile = "nature", Count = 3 },
		["GREEN THUMB"] = { Profile = "nature", Count = 4 },
		["BOTANIST"] = { Profile = "nature", Count = 4 },
		["LEAF TENDER"] = { Profile = "nature", Count = 4 },
		["HERBALIST"] = { Profile = "nature", Count = 4 },
		["SEED WARDEN"] = { Profile = "nature", Count = 4 },
		["GARDEN KEEPER"] = { Profile = "nature", Count = 4 },
		["GROVE KEEPER"] = { Profile = "mystic", Count = 4 },
		["GROVE SCOUT"] = { Profile = "mystic", Count = 4 },
		["GROVE GUARD"] = { Profile = "mystic", Count = 4 },
		["PETAL GUARDIAN"] = { Profile = "bloom", Count = 4 },
		["BLOOM SENTINEL"] = { Profile = "bloom", Count = 4 },
		["BLOOM WARDEN"] = { Profile = "bloom", Count = 4 },
		["BLOOM KNIGHT"] = { Profile = "bloom", Count = 4 },
		["BLOOM CHAMPION"] = { Profile = "bloom", Count = 5 },
		["GROVE COMMANDER"] = { Profile = "mystic", Count = 5 },
		["GROVE MASTER"] = { Profile = "mystic", Count = 5 },
		["THORN KNIGHT"] = { Profile = "nature", Count = 5 },
		["THORN SENTINEL"] = { Profile = "nature", Count = 5 },
		["THORN CAPTAIN"] = { Profile = "nature", Count = 5 },
		["THORN CHAMPION"] = { Profile = "nature", Count = 5 },
		["ROOT KEEPER"] = { Profile = "nature", Count = 5 },
		["ELDER ROOT"] = { Profile = "nature", Count = 5 },
		["ROOT GUARDIAN"] = { Profile = "nature", Count = 5 },
		["ROOT COMMANDER"] = { Profile = "nature", Count = 5 },
		["ROOT MASTER"] = { Profile = "nature", Count = 5 },
		["ROOT SOVEREIGN"] = { Profile = "nature", Count = 5 },
		["CANOPY LORD"] = { Profile = "nature", Count = 6 },
		["EMERALD REGENT"] = { Profile = "nature", Count = 6 },
		["WILDWOOD REGENT"] = { Profile = "nature", Count = 6 },
		["VERDANT REGENT"] = { Profile = "nature", Count = 6 },
		["CANOPY KING"] = { Profile = "nature", Count = 6 },
		["FOREST KING"] = { Profile = "nature", Count = 6 },
		["WILD SOVEREIGN"] = { Profile = "nature", Count = 6 },
		["GROVE EMPEROR"] = { Profile = "nature", Count = 6 },
		["CANOPY MONARCH"] = { Profile = "nature", Count = 6 },
		["FOREST ASCENDANT"] = { Profile = "nature", Count = 6 },
		["ANCIENT OAK"] = { Profile = "gold", Count = 4 },
		["TIMELESS OAK"] = { Profile = "gold", Count = 4 },
		["IRONBARK"] = { Profile = "gold", Count = 4 },
		["DEEPWOOD"] = { Profile = "gold", Count = 4 },
		["PRIMEVAL ROOT"] = { Profile = "gold", Count = 4 },
		["PRIMAL GROVE"] = { Profile = "gold", Count = 4 },
		["ELDERWOOD WARDEN"] = { Profile = "gold", Count = 4 },
		["ELDERWOOD TITAN"] = { Profile = "gold", Count = 4 },
		["FOREST COLOSSUS"] = { Profile = "gold", Count = 5 },
		["ANCIENT WORLD"] = { Profile = "gold", Count = 5 },
		["WORLD TREE"] = { Profile = "gold", Count = 6 },
		["SKYROOT"] = { Profile = "gold", Count = 6 },
		["SKY CANOPY"] = { Profile = "gold", Count = 6 },
		["SUNROOT"] = { Profile = "gold", Count = 6 },
		["SUN CANOPY"] = { Profile = "gold", Count = 6 },
		["SUNWARD TREE"] = { Profile = "gold", Count = 6 },
		["WORLDHEART"] = { Profile = "gold", Count = 6 },
		["WORLDROOT"] = { Profile = "gold", Count = 6 },
		["WORLD CROWN"] = { Profile = "gold", Count = 6 },
		["WORLD SOUL"] = { Profile = "gold", Count = 6 },
		["ETERNAL ROOT"] = { Profile = "dawn", Count = 4 },
		["ETERNAL GROVE"] = { Profile = "dawn", Count = 4 },
		["ETERNAL CANOPY"] = { Profile = "dawn", Count = 4 },
		["ETERNAL BLOOM"] = { Profile = "dawn", Count = 4 },
		["DAWNROOT"] = { Profile = "dawn", Count = 4 },
		["DAWNWEAVER"] = { Profile = "dawn", Count = 4 },
		["SUNWEAVER"] = { Profile = "dawn", Count = 5 },
		["RADIANT GROVE"] = { Profile = "dawn", Count = 5 },
		["RADIANT CROWN"] = { Profile = "dawn", Count = 5 },
		["EVERGREEN SOUL"] = { Profile = "dawn", Count = 5 },
		["PRIMEVAL BLOOM"] = { Profile = "bloom", Count = 6 },
		["VERDANT ETERNAL"] = { Profile = "bloom", Count = 6 },
		["UNDYING ROOT"] = { Profile = "bloom", Count = 6 },
		["UNDYING CANOPY"] = { Profile = "bloom", Count = 6 },
		["BOUNDLESS BLOOM"] = { Profile = "bloom", Count = 6 },
		["EVERBLOOM"] = { Profile = "bloom", Count = 6 },
		["EVERBLOOM HEART"] = { Profile = "bloom", Count = 6 },
		["EVERBLOOM CROWN"] = { Profile = "bloom", Count = 6 },
		["EVERBLOOM SOUL"] = { Profile = "bloom", Count = 6 },
		["BLOOM ASCENDANT"] = { Profile = "bloom", Count = 6 },
		["STARROOT"] = { Profile = "astral", Count = 5 },
		["STAR CANOPY"] = { Profile = "astral", Count = 5 },
		["STARBLOOM"] = { Profile = "astral", Count = 5 },
		["ASTRAL ROOT"] = { Profile = "astral", Count = 5 },
		["ASTRAL CANOPY"] = { Profile = "astral", Count = 5 },
		["CELESTIAL BLOOM"] = { Profile = "astral", Count = 5 },
		["COSMIC GROVE"] = { Profile = "astral", Count = 5 },
		["GALAXY WEAVER"] = { Profile = "astral", Count = 5 },
		["STELLAR SOVEREIGN"] = { Profile = "astral", Count = 5 },
		["COSMIC ASCENDANT"] = { Profile = "astral", Count = 5 },
		["PRIMAL SPIRIT"] = { Profile = "genesis", Count = 6 },
		["VITAL SPIRIT"] = { Profile = "genesis", Count = 6 },
		["NATURE AVATAR"] = { Profile = "genesis", Count = 6 },
		["EARTHHEART"] = { Profile = "genesis", Count = 6 },
		["EARTHSOUL"] = { Profile = "genesis", Count = 6 },
		["LIFEWEAVER"] = { Profile = "genesis", Count = 6 },
		["LIFE ARCHITECT"] = { Profile = "genesis", Count = 6 },
		["LIFE SOVEREIGN"] = { Profile = "genesis", Count = 6 },
		["GENESIS BLOOM"] = { Profile = "genesis", Count = 6 },
		["GENESIS SOUL"] = { Profile = "genesis", Count = 6 },
	},
}

local function deepFreeze(target: { [any]: any }): { [any]: any }
	for _, value in pairs(target) do
		if type(value) == "table" then
			deepFreeze(value)
		end
	end
	return table.freeze(target)
end

return deepFreeze(GameConfig)
