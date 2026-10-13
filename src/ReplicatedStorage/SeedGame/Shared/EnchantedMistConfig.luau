--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistConfig (2026-10-11)
--
-- The Enchanted Mist event's SWITCH, NAMES AND WORDS: its attributes, its
-- states, the shared timer sign above the Event Hub. Its numbers are
-- EnchantedMistData's. Kept out of GameConfig while the hub's layout there is
-- another session's work in progress; it reads GameConfig.Map.EventHub only.
--
-- ON since 2026-10-12 (the owner's item 14): `Enabled` runs the schedule -- a
-- new server's first eligibility 20-60 minutes in, then 60 minutes after each
-- start, each Mist after the next completed natural reset -- and even so only
-- once every binding EnchantedMistService.MissingBindings lists is in place.
-- An admin's START MIST NOW counts as a start while it runs. The shared sign
-- shows with `ShowSign` (ON since 2026-10-11): its real states, and COMING
-- SOON only while the schedule is off.
--==============================================================================
local EnchantedMistConfig = {}

EnchantedMistConfig.Enabled = true
EnchantedMistConfig.ShowSign = true

-- Workspace attributes the server publishes, the deadline before the state
-- (WorldCycleService's order), so a client never reads a new state with an old
-- deadline. Times are Workspace:GetServerTimeNow() values.
EnchantedMistConfig.Attributes = {
	State = "MistState",
	EventId = "MistEventId",
	EligibleAt = "MistEligibleAt",
	StartedAt = "MistStartedAt",
	EndsAt = "MistEndsAt",
}

-- Player attributes (PlayerDataService.PublishDewberries): the saved counts,
-- nil at 0. The client hides the berry prompt for a full player by them, and
-- Mosskeeper's bar reads the progress.
EnchantedMistConfig.PlayerAttributes = {
	Carried = "DewberriesCarried",
	Progress = "DewberryProgress",
}

--==============================================================================
-- THE DEWBERRIES (EnchantedMistBerryService, EnchantedMistBerries.client)
--
-- The server's folder in Workspace, the prompt's verb, and the notices: one
-- per spawned berry, all under one key, so a new berry says its place in the
-- notice already up instead of stacking another (ActionToastUI folds a key);
-- and the picker's own count, under a key of its own.
--==============================================================================
EnchantedMistConfig.Berries = {
	FolderName = "SeedDewberries",
	PromptName = "CollectDewberry",
	-- One word (the owner, 2026-10-12: "Collect Dewberry" ran off a phone's panel).
	ActionText = "Collect",
	-- The client reads these to tell a berry prompt from any other.
	BerryAttribute = "DewberryId",
	Words = {
		Appeared = "A Dewberry appeared!",
		NearPlots = "Near the plots",
		InBiome = "In %s",
		-- An admin's burst (2026-10-12): around them, by display name.
		AroundAdmin = "Around %s",
		Picked = "Dewberry picked! %d/%d",
		PickedFull = "Dewberries full! %d/%d",
		FullDetail = "Bring them to the Mosskeeper",
	},
	NoticeKeys = {
		Appeared = "mist:berry",
		Picked = "mist:picked",
	},
}

--==============================================================================
-- MOSSKEEPER (MosskeeperService, MosskeeperUI.client, MosskeeperView.client;
-- KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §8-9)
--
-- The resident NPC on GameConfig.Map.EventHub.NpcAnchor. He stands there
-- between Mists too -- talk works then, deposits do not -- once
-- `ShowMosskeeper` is on: ON since 2026-10-11 (the owner: he stands live in the
-- hub; the next Publish puts him there). His surround (Shared/MistSurroundModel)
-- and the deck's dress stand round him ALWAYS (the owner, 2026-10-11), and he
-- stands on the surround's pad.
--
-- Tap E -- Talk (a TAP: HoldDuration 0, unlike the berry and hatch holds)
-- within TalkReach; the server re-checks TalkReach + ReachSlack from the prompt.
-- The dialogue closes past CloseDistance. One GameEvent verb each way:
-- ClientAction from the client ("give"), ServerAction to it (open / given /
-- refused).
--==============================================================================
EnchantedMistConfig.ShowMosskeeper = true
EnchantedMistConfig.Mosskeeper = {
	FolderName = "SeedMosskeeper",
	PromptName = "MosskeeperTalk",
	ActionText = "Talk",
	TalkReach = 10,
	ReachSlack = 4,
	CloseDistance = 18,
	-- Seconds between two Give all requests from one player.
	GiveGap = 0.5,
	ClientAction = "MosskeeperGive",
	ServerAction = "Mosskeeper",
	-- The player is in his dialogue (a local attribute: he serves them).
	TalkingAttribute = "SeedMosskeeperTalking",
	-- AN ADMIN'S LINE (MOSSKEEPER SAYS), on the Workspace for everybody, late
	-- joiners too: JSON { n = its count, t = its words, e = the server time it
	-- ends } (MosskeeperService.Say, MosskeeperTalk.said / saidLeft).
	SaidAttribute = "SeedMosskeeperSaid",
	Lines = {
		Active = "Bring me 10 Dewberries for a Mysterious Pod. You can deliver them a few at a time.",
		Inactive = "I'm waiting for Enchanted Mist. Keep your berries safe: I can take them when it returns.",
	},
	Words = {
		Title = "MOSSKEEPER",
		GiveAll = "Give all Dewberries",
		Odds = "Odds",
		HowTo = "How to play",
		Close = "Close",
		Back = "Back",
		Carrying = "Carrying: %d/%d Dewberries",
		Progress = "Next Mysterious Pod: %d/%d",
		MistActive = "Enchanted Mist: active",
		MistWaiting = "Enchanted Mist: waiting",
		OddsDraft = "Draft odds, not final",
		OddsSpecies = "Creatures",
		OddsSizes = "Sizes (Legendary, Mythic, Divine)",
		OddsSecretNote = "Secrets keep their own size.",
		HowToLines = {
			"While Enchanted Mist is active, Dewberries appear near the plots and in the biomes.",
			"Hold E to pick one. You can carry 5 at a time.",
			"Bring them here and Give all: every 10 delivered makes a Mysterious Pod.",
			"Deliveries add up across Mists. Your berries and progress are saved.",
		},
		-- The answers to a Give all, by the server's reason.
		Given = "Delivered %d Dewberr%s! %d/%d to the next pod.",
		GivenPod = "Delivered %d! A Mysterious Pod is yours.",
		Refused = {
			INACTIVE = "He can accept berries only while Enchanted Mist is active.",
			EMPTY = "You have no Dewberries to give.",
			FAR = "Step closer to the Mosskeeper.",
			BAG_FULL = "Make room in your Bag.",
			BAG_NOT_READY = "Your Bag is still loading. Try again in a moment.",
			POD_NOT_READY = "The Mysterious Pod isn't ready yet.",
			CARRYING = "Put the pod down first.",
			NOT_LOADED = "Your save is still loading.",
			BUSY = "One moment...",
			GONE = "The Mosskeeper isn't here.",
		},
	},
	-- His personal bar (each viewer sees their own saved progress).
	Bar = {
		Header = "Dewberries %d/%d",
		Sub = "Next Mysterious Pod",
		Waiting = "Waiting for Enchanted Mist",
		-- Over his pivot, in studs: above the Dewdrop (7.1), far under the
		-- shared sign (EventHub floor + Sign.Above).
		Above = 8.6,
		Width = 8,
		Height = 2.2,
		MaxDistance = 70,
		-- How long a completed bar shows 10/10 before the saved remainder.
		FullHold = 1.4,
		Fill = Color3.fromRGB(150, 255, 196),
		-- A solid dark well with a moss edge (the mill's MilestoneBar look).
		Track = Color3.fromRGB(38, 62, 44),
		TrackEdge = Color3.fromRGB(86, 168, 92),
	},
	NoticeKey = "mist:mosskeeper",
	-- His panels wear the studded kit (MenuKit.studdedTheme): a moss band.
	Look = { Band = Color3.fromRGB(86, 168, 92), Edge = Color3.fromRGB(28, 82, 40) },
	-- The Odds page (MistOddsView): one rarity card per creature, the sizes
	-- apart. The rarest chance's % runs a rapid rainbow; the others under
	-- ShimmerBelow percent shimmer in their own colour; the rest stay still.
	Odds = {
		RainbowAtMost = 0.2,
		ShimmerBelow = 1,
		RainbowSeconds = 0.8,
		ShimmerSeconds = 1.8,
		CardHeight = 140,
		ChipHeight = 30,
		-- The page's tallest; past it, it scrolls.
		ViewHeight = 300,
		-- A creature on its card (2026-10-12, the owner: no black window behind
		-- it): standing on the studs, lit brighter than the Index's dark window
		-- needs, so it reads on the white pearl and the gold as on the holo.
		Ambient = Color3.fromRGB(176, 178, 188),
		LightColour = Color3.fromRGB(255, 252, 240),
		-- A card's chance (2026-10-13): light words under a thick ink line on
		-- every card (MistOddsView.card); the pearl's deep inks went with it.
	},
	--==========================================================================
	-- HIS TALK (the owner, 2026-10-11, from a clip of a Grow-a-Garden-style shop
	-- NPC). Talk eases the camera behind the player's shoulder, facing him; his
	-- line types out over his head; the player's four replies float beside the
	-- player as outlined words, no panel; a reply goes up over the player's own
	-- head, then he answers. Shared/MosskeeperTalk decides, MosskeeperUI draws.
	-- Plain ASCII words only: LuckiestGuy draws every one of them.
	--==========================================================================
	Talk = {
		-- AN ADMIN'S LINE in his bubble (2026-10-12, the owner's item 12): at most
		-- this many characters -- his own longest line is 87, and that fits a
		-- phone's bubble in its four lines.
		SayMaxChars = 90,
		-- It stays over his head this long -- as long as an admin announcement
		-- (GameConfig.Announce.ShowSeconds), since it is one -- or its reading
		-- time, if that is longer (MosskeeperTalk.sayTime).
		SaySeconds = 12,
		-- A player may skip it on their own screen with a click or a tap anywhere
		-- (the owner, 2026-10-12) once it has stood this long, so a press already
		-- on its way never skips it at once (MosskeeperTalk.skipsSaid).
		SaySkipAfter = 0.5,
		-- The replies, keys 1-4 in this order (a click, a tap, the D-pad and A too).
		Options = {
			{ id = "give", text = "Give all Dewberries" },
			{ id = "odds", text = "Odds" },
			{ id = "howto", text = "How to play" },
			{ id = "bye", text = "Nevermind" },
		},
		-- His answers to a Give all, by the server's own answer.
		Given = "%d/%d, %s more for a pod!",
		GivenPod = "Here's your Mysterious Pod!",
		Refused = {
			INACTIVE = "I'm waiting for Enchanted Mist...",
			EMPTY = "You have no Dewberries to give.",
			FAR = "Come a little closer.",
			BAG_FULL = "Make room in your Bag.",
			BAG_NOT_READY = "Your Bag is still loading. Try again in a moment.",
			POD_NOT_READY = "The Mysterious Pod isn't ready yet.",
			CARRYING = "Put the pod down first.",
			NOT_LOADED = "Your save is still loading.",
			BUSY = "One moment...",
		},
		-- An answer this late is not waited for: he says Refused.BUSY.
		Patience = 6,
		Numbers = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" },
		-- How to play: his short run of lines ({cap}: the carry cap; {pod}: berries a pod).
		HowTo = {
			"When Enchanted Mist rolls in, Dewberries grow near the plots and in the biomes.",
			"Hold to pick one up. You can carry {cap} at a time.",
			"Bring them to me. Every {pod} makes a Mysterious Pod!",
			"Your berries and your progress are saved between Mists.",
		},
		-- Under the replies: the player's own numbers.
		Counts = "Carrying %d/%d    Next pod %d/%d",
		-- Typing, in characters a second; a line in a run stays ReadHold plus
		-- ReadPerChar a character once typed.
		CharsPerSecond = 40,
		ReadHold = 1.2,
		ReadPerChar = 0.04,
		-- The player's own line stands this long before he answers.
		PlayerHold = 0.9,
		-- The camera: Back, Up and Side studs behind the player's right shoulder,
		-- looking at his pivot plus LookUp (between his head and his bar), eased
		-- over EaseSeconds -- the player bottom left, him in the middle, clear of
		-- each other (the first Play, 2026-10-11: closer in, the player's head hid him).
		Camera = { Back = 10, Up = 3.5, Side = 5.5, LookUp = 6.8, EaseSeconds = 0.6 },
		-- His line's bottom this far over the top of his bar (studs); the
		-- player's this far over the top of their head.
		OverBar = 0.5,
		OverHead = 1.2,
		-- The replies start Beside studs right of him, BesideUp over his pivot (his
		-- chest) -- beside the player and him, over neither -- and keep Margin px
		-- off the screen's edge and every part of the HUD.
		Beside = 3.2,
		BesideUp = 3.5,
		Margin = 8,
		-- The look: px type, a reply's row and the gap between rows, the bubbles'
		-- type and widest. The tight looks are for where the first will not stand
		-- clear (a 640 x 360 phone).
		--
		-- A TOUCH SCREEN'S, EXACTLY THE OWNER'S REFERENCE (2026-10-12: a Grow a
		-- Garden phone, 2000 x 900): the replies' words about 4% of the screen's
		-- height and a row every 5.8%, his line about 2.5-3% -- on a 338-360 px
		-- phone 14 px words, 20 px rows and an 11 px line. Each reply's row is its
		-- whole tap target, never overlapping the next; the owner accepts taps
		-- that small, and the number keys and the pad's D-pad still choose.
		Look = {
			Desktop = { Type = 26, Row = 34, Gap = 2, Bubble = 24, BubbleWidth = 380, Counts = 18 },
			DesktopTight = { Type = 22, Row = 30, Gap = 0, Bubble = 22, BubbleWidth = 340, Counts = 16 },
			Touch = { Type = 14, Row = 20, Gap = 0, Bubble = 11, BubbleWidth = 230, Counts = 11 },
			TouchTight = { Type = 13, Row = 19, Gap = 0, Bubble = 10, BubbleWidth = 200, Counts = 10 },
			Number = Color3.fromRGB(255, 214, 64),
			Text = Color3.fromRGB(255, 255, 255),
			Chosen = Color3.fromRGB(150, 255, 196),
			Stroke = 2.5,
		},
	},
}

--==============================================================================
-- THE HUB DECK'S DRESS (Shared/MistDeckModel; the owner, 2026-10-11:
-- "A's moss carpet together with C's mushroom fairy ring")
--
-- Standing ALWAYS with the surround since 2026-10-11 (the owner; before, it
-- came with each Mist and went at its end). A moss carpet over the whole
-- round deck (under the plaza's floor, so the plaza still shows), and a
-- fairy ring of mint-spotted mushrooms near its edge with the road's side
-- left open. Overlays only: nothing collides, is found by a
-- ray or touches, so the Deck ticket ring (MiniEvent, r 27-43, read by a ray
-- that respects collision) and the overflow spawn keep working. The ring
-- stands outside the ticket ring and inside the deck's edge. Reduced FX
-- stills the spots' glow (MosskeeperView).
--==============================================================================
EnchantedMistConfig.Deck = {
	ModelName = "MistDeck",
	-- The carpet: this far in from the deck's edge, its top this far over the
	-- deck's top (under the plaza floor's Rise).
	CarpetInset = 0.3,
	CarpetLift = 0.03,
	CarpetThickness = 0.05,
	CarpetColour = Color3.fromRGB(92, 140, 66),
	-- The ring: Count mushrooms round RingRadius, none within RoadGapDegrees of
	-- the road (-Z), the tall and short alternating.
	RingRadius = 44.8,
	Count = 20,
	RoadGapDegrees = 26,
	StemWidth = 0.5,
	StemTall = 1.5,
	StemShort = 1.1,
	CapWidth = 1.9,
	CapThickness = 0.45,
	SpotSize = 0.28,
	StemColour = Color3.fromRGB(214, 244, 226),
	CapColours = { Color3.fromRGB(96, 158, 76), Color3.fromRGB(92, 140, 66) },
	SpotColour = Color3.fromRGB(150, 255, 200),
	--==========================================================================
	-- THE GROVE (the owner, 2026-10-11: "more trees around Mosskeeper, more
	-- enchanted decoration, a pathway leading to him ... just improvise"):
	-- woodland trees in the band between the plaza (Map.EventHub.Radius) and
	-- the Deck ticket ring, none on the road's side; glowing flower clusters
	-- between them; a stepping-stone path from short of the overflow spawn to
	-- the surround's open front, inside its approach, mint lanterns either side
	-- just outside it. Overlays only, like the rest; under TreeMaxHeight, so
	-- the shared Mist sign above the hub stays in sight.
	--==========================================================================
	Grove = {
		TreeRadius = 23.5,
		TreeAngles = { 62, 98, 132, 166, 194, 228, 262, 298 },
		TreeMaxHeight = 12.5,
		RoadGapDegrees = 45,
		FlowerRadius = 24.5,
		FlowerAngles = { 80, 115, 149, 180, 211, 245, 280 },
		PathFrom = 21,
		PathTo = 7,
		PathWidth = 4.2,
		PathStones = 8,
		LanternSide = 7.6,
		LanternCount = 3,
		Trunk = Color3.fromRGB(110, 74, 48),
		TrunkDark = Color3.fromRGB(82, 54, 38),
		Leaves = { Color3.fromRGB(44, 94, 52), Color3.fromRGB(66, 126, 62), Color3.fromRGB(96, 158, 76) },
		Stone = Color3.fromRGB(124, 128, 114),
		Moss = Color3.fromRGB(92, 140, 66),
		Mint = Color3.fromRGB(150, 255, 200),
		Petal = Color3.fromRGB(214, 244, 226),
	},
	--==========================================================================
	-- THE DETAIL (the owner, 2026-10-11: "MORE DETAIL ON THE EVENT HUB. Grass
	-- tufts, more flowers, a small POND, decorative plants, etc.; improvise in
	-- the same family as the grove, carpet and mushroom ring"): grass tufts,
	-- wildflowers, ferns, bushes, little mushrooms, mossy rocks and a fallen
	-- log over the deck's open band, and a small pond on its west side with a
	-- stone rim, lily pads, reeds and a few fireflies. Overlays only, like the
	-- rest, and low (under TallMax), so the deck stays walkable everywhere and
	-- the pond is a flush painted surface: no Terrain water, nothing to swim in
	-- or wade through. Kept off the plaza (MinRadius), the deck's rim step
	-- (MaxRadius) and the road's side (RoadGapDegrees: the approach, its path
	-- and the overflow spawn), and nothing over LowMax stands where a mini
	-- event's ticket may fall or a disco's dancer stand (MosskeeperSpec). Its
	-- glowing bits are MistGlow, so Reduced FX stills them; nothing moves.
	-- Spots are { degrees from the road, radius }, as the grove's angles.
	--==========================================================================
	Detail = {
		MinRadius = 20.5,
		MaxRadius = 42.5,
		RoadGapDegrees = 45,
		TallMax = 2.8,
		LowMax = 1.4,
		Tufts = { { 50, 31 }, { 58, 39.5 }, { 66, 30.5 }, { 76, 34 }, { 88, 40 }, { 96, 28.5 }, { 113, 37 }, { 121, 31 },
			{ 150, 29.5 }, { 160, 40.5 }, { 198, 41 }, { 230, 37 }, { 262, 40 }, { 298, 31.5 }, { 301, 40 }, { 312, 37 } },
		Flowers = { { 64, 37 }, { 104, 32 }, { 186, 28.5 }, { 240, 29 }, { 300, 35.5 } },
		Ferns = { { 72, 22.5 }, { 146, 36 }, { 202, 25.5 }, { 236, 25.5 } },
		Bushes = { { 156, 25.5 }, { 166, 31.5 }, { 192, 33 }, { 308, 24.5 } },
		Shrooms = { { 185, 39.5 }, { 229.5, 26.5 } },
		Rocks = { { 171, 40.5 }, { 293, 37.5 } },
		Logs = { { 178, 37 } },
		-- Clover patches: { degrees, radius, the patch's own radius }.
		Clover = { { 55, 36, 2.2 }, { 82, 31, 2 }, { 108, 39.5, 1.8 }, { 216, 31, 2 }, { 250, 37, 2.2 }, { 309, 32, 2 } },
		-- The pond: lobes { out, along, radius } in its own frame (out from the
		-- hub's centre, along the turn toward +X), the water's top Rise over the
		-- deck's (over the carpet, under a stud), a rim stone every RimStep studs
		-- of its edge, and pads, reeds and fireflies in the same frame.
		Pond = {
			Angle = 284,
			Radius = 33,
			Lobes = { { 0, 0, 3.8 }, { -0.4, -3.6, 2.6 }, { 0.6, 3.3, 2 } },
			Rise = 0.07,
			Deep = 0.55,
			RimStep = 2.6,
			Pads = { { -1.2, 0.8, 1.4 }, { 1.3, -1.2, 1.2 }, { -0.6, -4, 1.1 } },
			Reeds = { { 4.2, -1.8, 2.2 }, { 4.6, -0.7, 2.6 }, { 4.3, 0.5, 2.1 }, { 4.7, 1.5, 2.5 }, { 4.1, 2.4, 1.9 } },
			Fireflies = { { 0.6, 1.8, 1.7 }, { -1.6, -2.2, 2.2 }, { 2, -0.4, 2.6 } },
		},
		Grass = { Color3.fromRGB(124, 186, 88), Color3.fromRGB(98, 160, 72), Color3.fromRGB(150, 206, 110) },
		CloverColour = Color3.fromRGB(122, 178, 86),
		Water = Color3.fromRGB(92, 168, 196),
		WaterDeep = Color3.fromRGB(64, 132, 170),
		StoneLight = Color3.fromRGB(152, 156, 140),
		Lilac = Color3.fromRGB(196, 170, 232),
		Butter = Color3.fromRGB(250, 232, 150),
		LogEnd = Color3.fromRGB(196, 150, 104),
	},
}

--==============================================================================
-- THE MYSTERIOUS POD'S HATCH (MysteryPodService -> MysteryRevealUI.client): the
-- pod's owner is told the saved creature (and size) as its shell breaks, for
-- their card draw; the world reveal follows at the draw's end
-- (EnchantedMistData.drawSeconds, MysteryPodService.Reserve).
--==============================================================================
EnchantedMistConfig.Mystery = {
	Action = "MysteryHatch",
	Words = {
		Creature = "WHAT'S INSIDE?",
		Size = "WHAT SIZE?",
		Secret = "A SECRET!",
		-- OPEN ALL's grid: "10 PODS OPENED!" (short: SKIP shares its row), the
		-- rarest's ribbon.
		Opened = "%d PODS OPENED!",
		Rarest = "RAREST!",
	},
	-- OPEN ALL (2026-10-12, the owner's item 17): every ready Mysterious Pod at
	-- once, with no draw each -- one grid of what came out (MysteryRevealUI,
	-- this Phase), held GridSeconds; the plants' world reveals follow it, Gap
	-- apart (PlantService.OpenAllMystery).
	OpenAll = { Phase = "openall", GridSeconds = 4.5, Gap = 0.3 },
	-- THE SHOP (2026-10-12, item 17; GameConfig.Store.MysteryPods). The client
	-- flag WheelService publishes PolicyService's own answer on (true only when
	-- paid random items are allowed; missing reads "no"), the gift's request
	-- and reply on GameEvent, the banner's studs and its words.
	Shop = {
		PolicyAttribute = "PaidRandomAllowed",
		GiftAction = "MysteryGift",
		GiftReply = "MysteryGiftResult",
		Studs = "rbxassetid://88002993641737",
		Words = {
			Badge = "NEW!",
			Title = "MYSTERIOUS POD",
			Tagline = "A creature from the Enchanted Mist inside -- even a Secret!",
			Odds = "ODDS",
			Gift = "GIFT",
			GiftPick = "Who is it for?",
			GiftNone = "Nobody else is in this server to gift to.",
			Restricted = "Not available here.",
			Was = "WAS %s",
			-- The server's announcement to everyone, and its notices ("%s" pods:
			-- "a Mysterious Pod" or "3 Mysterious Pods").
			Gifted = "%s gifted %s %s!",
			GiftLeft = "%s left before the gift arrived, so %s went to you.",
			GiftUnsent = "The gift couldn't be delivered, so %s went to you.",
			Delivered = "Your Bag now holds %s from your order.",
			Owed = "Your Bag is full: %s will wait for room.",
			-- A gift refused before any prompt, by the server's code.
			Refused = {
				NO_PLAYER = "That player isn't in this server any more.",
				RESTRICTED = "Mysterious Pods can't be gifted to that player.",
				NOT_SAVING = "That player's progress isn't saving right now.",
				OFF = "Mysterious Pods aren't available right now.",
			},
		},
	},
}

--==============================================================================
-- THE MIST'S LOOK (Shared/MistLook; brief §3, the owner's go 2026-10-11): a
-- readable, magical night over the day while the gameplay phase stays Day.
--
-- LIGHT (WorldClock): toward the night sky -- ClockTime 0, its moon and stars
-- -- but lighter and more violet than the plain night the plots are tuned for
-- (WorldCycle.Night: Brightness 1.1, ambients 58,66,96 / 66,78,116), so the
-- road, the berries and the far biomes keep reading. No fog setting of any
-- kind: no Atmosphere, no fog distance.
-- WISPS, FIREFLIES, and since 2026-10-12 (item 16E) the ROLLING GROUND MIST
-- and the HUB'S SWIRL -- all particles (Weather.client) -- and GLINTS
-- (EnchantedMistBerries.client): decoration, off under Reduced FX, a touch
-- screen's lower rates. Every
-- texture is the engine's own particle (rbxasset://), never an upload. Its
-- sound (the owner's uploads, 2026-10-11) is GameConfig.Sfx's Mist cues.
--==============================================================================
EnchantedMistConfig.Look = {
	-- Tuned 2026-10-11 after the first Play captures: a notch lighter, so the
	-- field, the plots and the far biome read on a phone too.
	Light = {
		ClockTime = 0,
		Brightness = 1.9,
		Ambient = Color3.fromRGB(104, 94, 166),
		OutdoorAmbient = Color3.fromRGB(126, 114, 188),
		EnvironmentDiffuseScale = 0.8,
		Exposure = 0.5,
		-- A soft blue-violet tone, a touch more colour.
		Tint = Color3.fromRGB(226, 218, 255),
		Saturation = 0.08,
		Contrast = 0.04,
		FadeSeconds = 4,
		FadeOutSeconds = 6,
	},
	-- Soft mint wisps round the camera: SELF-LIT (Glow, no light influence) --
	-- lit by the night they read as dark smudges (the first Play's captures).
	-- MORE MIST (2026-10-12, the owner's item 16E: "like a real mist moving
	-- around"): grown into big, very see-through PUFFS floating past on the
	-- Wind -- Drift is its push, the drag holds it to a slow float -- each
	-- fading in and out over 8-12 s.
	Wisps = {
		Rate = 6,
		ReducedRate = 2.5,
		Area = 120,
		Above = 1.5,
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Colour = Color3.fromRGB(150, 255, 210),
		Far = Color3.fromRGB(186, 168, 255),
		Size = { 12, 20 },
		Transparency = 0.6,
		Glow = 0.4,
		Lifetime = { 8, 12 },
		Speed = { 0.2, 0.5 },
		Drift = 0.35,
	},
	-- The wind the ground mist and the puffs drift on: a heading in degrees,
	-- round from +X toward +Z, and studs a second.
	Wind = { Degrees = 30, Speed = 1.1 },
	-- ROLLING GROUND MIST (item 16E): wide, faint layers at knee height round
	-- the camera, rolling slowly downwind -- the engine's smoke drawn wide and
	-- flat (Squash) and kept level (little Rotation), faintly self-lit so the
	-- night does not draw it dark. Low and see-through, so the berries, the
	-- prompts and the road read through it; only round the camera, so the far
	-- biomes stay clear. A touch screen's at ReducedRate; none under Reduced FX
	-- (MistLook.mistRates). Tuned in the Play's captures (2026-10-12): fainter
	-- (0.9 over a 150-stud square) read as nothing, 0.5 at 9 a second washed the
	-- field out; this keeps the near grass's colour, so a berry reads, and
	-- hazes the fences, the trees and the horizon. The smoke's own alpha peaks
	-- near 0.45, so Transparency 0.6 is about a fifth opaque at its middle.
	Ground = {
		Rate = 7,
		ReducedRate = 2.5,
		Area = 90,
		Above = 1.1,
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Colour = Color3.fromRGB(222, 216, 255),
		Size = { 20, 32 },
		Squash = -0.6,
		Transparency = 0.6,
		Glow = 0.35,
		Lifetime = { 12, 16 },
	},
	-- THICKER AT THE HUB (item 16E): a slow swirl round the Mosskeeper's grove
	-- and a band along the deck's edge (Map.HubRadius 46), each a ring of the
	-- same smoke (Radius, Inner: the ring's inside as a share of it) that turns
	-- Turn degrees a second, carrying its mist round -- drawn only while the
	-- camera is within Range of the hub's centre.
	Hub = {
		Range = 240,
		Above = 1.4,
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Colour = Color3.fromRGB(176, 255, 222),
		Far = Color3.fromRGB(196, 182, 255),
		Glow = 0.45,
		Grove = { Radius = 30, Inner = 0.5, Rate = 7, ReducedRate = 2.5, Size = { 10, 18 }, Transparency = 0.58,
			Lifetime = { 8, 12 }, Turn = 6 },
		Edge = { Radius = 48, Inner = 0.88, Rate = 9, ReducedRate = 3, Size = { 12, 20 }, Transparency = 0.6,
			Lifetime = { 9, 13 }, Turn = -3 },
	},
	-- Sparkles drifting a few studs up: fireflies and glinting leaves.
	Fireflies = {
		Rate = 14,
		ReducedRate = 5,
		Area = 70,
		Above = 1.5,
		Height = 5,
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Colours = { Color3.fromRGB(150, 255, 200), Color3.fromRGB(255, 236, 150) },
		Size = 0.5,
		Lifetime = { 2.5, 4.5 },
		Speed = { 0.3, 0.8 },
	},
	-- Each berry's glint: a twinkle now and then at its middle.
	Glints = {
		Rate = 0.7,
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Colour = Color3.fromRGB(244, 255, 239),
		Size = 0.9,
		Lifetime = 0.7,
	},
}

-- What MistState says.
EnchantedMistConfig.States = {
	Disabled = "disabled", -- switched off, or a binding missing: COMING SOON
	Cooldown = "cooldown", -- not yet eligible: EligibleAt says when
	Eligible = "eligible", -- eligible, waiting for the next completed reset
	Active = "active", -- running: StartedAt .. EndsAt
}

--==============================================================================
-- THE SHARED TIMER SIGN above the Event Hub (EnchantedMistSign.client)
--
-- Over GameConfig.Map.EventHub's centre, Above studs over its floor -- clear of
-- the surround (MaxHeight) and of Mosskeeper's own deposit bar. FloatingSign's
-- family: LuckiestGuy, the dark outline, sized in studs, one plain colour each
-- line, no backing. Header, status line, note line.
--
-- READ FROM THE PLOTS (2026-10-11, measured: EventHubSpec): its bottom edge
-- (16.7 up) is 2.8 studs over the surround's highest leaf, 3.4 over its arch
-- and 4.5 over the grove's trees, and nothing of the set or the map stands
-- between it and any plot. At its 22 studs a plot's camera (100-150 away) drew
-- its words 5-7 points tall on a phone -- unreadable -- so past the distance
-- where its header's box would draw under MinHeaderUnits (screen units: pixels
-- on a computer, points on a phone; the camera's own view), it grows to hold
-- that size, upward from its bottom edge, which stays where it is. Nearer, it
-- is the studs it is built at. It draws out to MaxDistance: past the deepest
-- plot's back (GameConfig.Plot.MaxReach 245, a camera 12 behind it).
--==============================================================================
EnchantedMistConfig.Sign = {
	Above = 19,
	MaxDistance = 300,
	MinHeaderUnits = 19,
	-- And never above this share of the screen's height up close (2026-10-12, the
	-- owner on a phone: at the hub it drew HUGE behind the top buttons), nor under
	-- MinHeaderUnits: a near sign shrinks to it (EnchantedMistStatus.signScale).
	MaxHeaderShare = 0.06,
	Width = 22,
	Height = 3.4,
	SubHeight = 1.7,
	NoteHeight = 1.3,
	Header = "ENCHANTED MIST",
	Colour = Color3.fromRGB(150, 255, 196),
	SubColour = Color3.fromRGB(236, 255, 242),
	NoteColour = Color3.fromRGB(196, 236, 214),
	-- The truthful states (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §4).
	Words = {
		ComingSoon = "COMING SOON",
		-- The owner, 2026-10-12, for kids: "Next Mist in" (was "Eligible in"); the
		-- note still says it waits for the reset.
		Cooldown = "Next Mist in %s",
		CooldownNote = "Begins after biome reset",
		Eligible = "Waiting for biome reset",
		-- An estimate (dusk + the night), moved by a Pod Rush hold; never a promise.
		EstimateNote = "Estimated start in ~%s",
		Resetting = "Biomes resetting · %s",
		Active = "ACTIVE · Ends in %s",
		Syncing = "Syncing…",
	},
}

return EnchantedMistConfig
