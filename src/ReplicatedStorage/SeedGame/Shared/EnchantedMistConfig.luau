--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistConfig (2026-10-11)
--
-- The Enchanted Mist event's SWITCH, NAMES AND WORDS: its attributes, its
-- states, the shared timer sign above the Event Hub. Its numbers are
-- EnchantedMistData's. Kept out of GameConfig while the hub's layout there is
-- another session's work in progress; it reads GameConfig.Map.EventHub only.
--
-- OFF until the owner approves: `Enabled` is false, and even when it is on the
-- event runs only once every binding EnchantedMistService.MissingBindings lists
-- is in place. The shared sign shows with `ShowSign`: ON since 2026-10-11 (the
-- owner), so while the event is off it reads COMING SOON, and the next Publish
-- puts it live.
--==============================================================================
local EnchantedMistConfig = {}

EnchantedMistConfig.Enabled = false
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
	ActionText = "Collect Dewberry",
	-- The client reads these to tell a berry prompt from any other.
	BerryAttribute = "DewberryId",
	Words = {
		Appeared = "A Dewberry appeared!",
		NearPlots = "Near the plots",
		InBiome = "In %s",
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
		-- The look: px type, a reply's row and the gap between rows (a touch
		-- screen's rows tall enough to tap), the bubbles' type and widest. The
		-- tight looks are for where the first will not stand clear (a 640 x 360
		-- phone): a touch screen's rows stay 44 px.
		Look = {
			Desktop = { Type = 26, Row = 34, Gap = 2, Bubble = 24, BubbleWidth = 380, Counts = 18 },
			DesktopTight = { Type = 22, Row = 30, Gap = 0, Bubble = 22, BubbleWidth = 340, Counts = 16 },
			Touch = { Type = 22, Row = 44, Gap = 2, Bubble = 20, BubbleWidth = 300, Counts = 16 },
			TouchTight = { Type = 20, Row = 44, Gap = 0, Bubble = 18, BubbleWidth = 260, Counts = 14 },
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
}

--==============================================================================
-- THE MYSTERIOUS POD'S HATCH (MysteryPodService -> MysteryRevealUI.client): the
-- pod's owner is told the saved creature (and size) as its shell breaks, for
-- their card reels; the world reveal follows Shell.ReelSeconds later.
--==============================================================================
EnchantedMistConfig.Mystery = {
	Action = "MysteryHatch",
	Words = {
		Creature = "WHAT'S INSIDE?",
		Size = "WHAT SIZE?",
		Secret = "A SECRET!",
	},
}

--==============================================================================
-- THE MIST'S LOOK (Shared/MistLook; brief §3, the owner's go 2026-10-11): a
-- readable, magical night over the day while the gameplay phase stays Day.
--
-- LIGHT (WorldClock): toward the night sky -- ClockTime 0, its moon and stars
-- -- but lighter and more violet than the plain night the plots are tuned for
-- (WorldCycle.Night: Brightness 1.1, ambients 58,66,96 / 66,78,116), so the
-- road, the berries and the far biomes keep reading. No fog of any kind.
-- WISPS and FIREFLIES (Weather.client), GLINTS (EnchantedMistBerries.client):
-- decoration, off under Reduced FX, a touch screen's lower rates. Every
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
	-- Soft mint wisps low over the ground round the camera: big, faint, slow,
	-- and SELF-LIT (Glow, no light influence) -- lit by the night they read as
	-- dark smudges (the first Play's captures).
	Wisps = {
		Rate = 8,
		ReducedRate = 3,
		Area = 110,
		Above = 0.4,
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Colour = Color3.fromRGB(150, 255, 210),
		Far = Color3.fromRGB(186, 168, 255),
		Size = { 6, 11 },
		Transparency = 0.7,
		Glow = 0.6,
		Lifetime = { 7, 10 },
		Speed = { 0.3, 0.9 },
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
		Cooldown = "Eligible in %s",
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
