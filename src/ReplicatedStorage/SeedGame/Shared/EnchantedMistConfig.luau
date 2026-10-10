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
