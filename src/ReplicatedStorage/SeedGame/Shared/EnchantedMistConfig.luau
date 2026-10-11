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
-- is in place. The shared sign shows only with `ShowSign` (its COMING SOON would
-- otherwise go live on the next Publish).
--==============================================================================
local EnchantedMistConfig = {}

EnchantedMistConfig.Enabled = false
EnchantedMistConfig.ShowSign = false

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
-- between Mists too -- talk works then, deposits do not -- but only once
-- `ShowMosskeeper` is on: off until the owner approves, like ShowSign, so the
-- next Publish cannot put him live. His surround (Shared/MistSurroundModel)
-- stands round him only while a Mist runs, and lifts him onto its pad.
--
-- Tap E -- Talk (a TAP: HoldDuration 0, unlike the berry and hatch holds)
-- within TalkReach; the server re-checks TalkReach + ReachSlack from the prompt.
-- The dialogue closes past CloseDistance. One GameEvent verb each way:
-- ClientAction from the client ("give"), ServerAction to it (open / given /
-- refused).
--==============================================================================
EnchantedMistConfig.ShowMosskeeper = false
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
		Inactive = "I'm waiting for Enchanted Mist. Keep your berries safe—I can accept them when it returns.",
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
		Track = Color3.fromRGB(38, 62, 44),
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
--==============================================================================
EnchantedMistConfig.Sign = {
	Above = 19,
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
