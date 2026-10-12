--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistData (2026-10-11)
--
-- The Enchanted Mist event's NUMBERS -- its schedule, the confirmed collection
-- rules, the spawn tuning, the Mysterious Pod's creature and size odds. Balance
-- lives here, not in GameConfig (AGENTS.md, rule 7); EnchantedMistConfig holds
-- the switch, the names and the words.
--
-- What the owner has CONFIRMED is marked so. Everything marked DRAFT is a
-- proposal awaiting the owner's approval (KB/ENCHANTED-MIST-RESET-ALIGNED-
-- CLAUDE-PROMPT.md); the event stays off while any of it is unapproved
-- (EnchantedMistService.MissingBindings).
--==============================================================================
local EnchantedMistData = {}

--==============================================================================
-- THE SCHEDULE -- CONFIRMED 2026-10-11 (the owner's answers)
--
--   * The look: an enchanted NIGHT LOOK after a reset, the road open -- not a
--     real Night (gameplay stays in Day; biomes stay reachable).
--   * Eligible CooldownSeconds after the previous Mist STARTED, then it begins
--     after the next COMPLETED natural reset (dusk, the fifteen-second night,
--     the restock, the road reopened). With the unchanged 435-second cycle that
--     is about 65:15 between starts; Pod Rush holds and resets can delay it.
--     Never called "hourly".
--   * A new server's first eligibility: a random FirstEligibleMin..Max seconds
--     after it starts.
--==============================================================================
EnchantedMistData.Schedule = {
	ActiveSeconds = 300,
	CooldownSeconds = 3600,
	FirstEligibleMin = 1200,
	FirstEligibleMax = 3600,
	-- An admin's START MIST NOW (2026-10-12, the owner's item 12): 2, 5 or 10
	-- minutes, the console's chips; the normal ActiveSeconds among them.
	AdminSeconds = { 120, 300, 600 },
}

--==============================================================================
-- THE COLLECTION RULES -- CONFIRMED (the owner, not to be asked again)
--
-- A player carries at most CarryCap Dewberries; Mosskeeper saves partial
-- deposits; BerriesPerPod deposited berries earn one Mysterious Pod, which is
-- ready HatchSeconds after it is granted, whatever is inside.
--==============================================================================
EnchantedMistData.CarryCap = 5
EnchantedMistData.BerriesPerPod = 10
EnchantedMistData.HatchSeconds = 30

--==============================================================================
-- THE MYSTERIOUS POD'S SHELL (stage 4; MysteryPodService) -- A BINDING
--
-- One generic shell for every outcome: the pod's row and Tool name this
-- species id and nothing else (the outcome is the server's alone,
-- Profile.MysteryPods). With no shell id, or one SeedData does not know, no pod can be granted and
-- the event stays off (EnchantedMistService.MissingBindings). The shell's own
-- species must grow in HatchSeconds (FixedGrowSeconds) and be unlisted.
-- ReelSeconds: how long the owner's card reels run before the world reveal;
-- LandHoldSeconds: how long a landed creature card stays before the size reel
-- starts (reelTimes, below).
--==============================================================================
EnchantedMistData.Shell = {
	-- Bound (2026-10-11): the owner's LuckhollowPod, SeedData.MysterySpecies.
	Id = "mysterypod" :: string?,
	Name = "Mysterious Pod",
	-- 4.2 since 2026-10-12 (3.6 before): room for the landed creature's hold.
	ReelSeconds = 4.2,
	-- 2026-10-12, the owner via the peer: the size reel replaced the landed
	-- creature after ~0.15 s, so a player never saw which creature came out.
	LandHoldSeconds = 1.1,
}

--==============================================================================
-- SPAWNING -- DRAFT tuning (proposed, not approved balance), except
-- IntervalSeconds: the owner's 3 s (2026-10-11; it was 5). At most 97 berries
-- a Mist (300 s, none in the last 10 s); six players' pods need 60.
--
-- At most MaxActive berries in the world; one spawn or replacement
-- opportunity every IntervalSeconds, never a catch-up burst after a stall; each
-- lives LifetimeSeconds (staggered by when it appeared). SafeShare of the
-- spawns go to the safe field near the plots, the rest to reachable biome
-- ground off the racing line. A berry is collected with a HoldSeconds hold of
-- E within Reach studs; the server re-checks Reach + ReachSlack, and that the
-- hold it saw begin lasted HoldSeconds - HoldTolerance (the two signals cross
-- the network with different delays).
--
-- WHERE (EnchantedMistBerryService): the safe share in MiniEventService's
-- ticket zones SafeZones names, by weight; the biome share on a biome's
-- floor between the racing line (|X| under 24, as GameConfig.PodGuide keeps)
-- and the walls (|X| in BiomeX), BiomeNearMargin inside its arch (past the
-- Pod Guide stand at In 13 and its board) and BiomeFarMargin short of the next
-- gate, an early biome likelier (weight 1 / Order) so a beginner meets berries
-- too. Every spot passes the tickets' checks (the hub
-- and its NPCs, the plots, the nests and their guardians, the props, a real
-- floor), stays Spacing studs from every other berry and PodClear studs from
-- every pod, so no two prompts share ground. Tries spots per opportunity; an
-- opportunity with no spot is skipped, never made up later. No berry appears
-- in the last QuietEndSeconds: nobody could reach it before the Mist ends.
--==============================================================================
EnchantedMistData.Spawn = {
	MaxActive = 6,
	IntervalSeconds = 3, -- the owner's (2026-10-11)
	LifetimeSeconds = 60,
	SafeShare = 0.6,
	HoldSeconds = 0.75,
	HoldTolerance = 0.25,
	Reach = 10,
	ReachSlack = 6,
	SafeZones = { Field = 3, Front = 2 },
	BiomeX = { 24, 50 },
	BiomeNearMargin = 36,
	BiomeFarMargin = 10,
	Spacing = 14,
	PodClear = 10,
	Tries = 12,
	QuietEndSeconds = 10,
	-- AN ADMIN'S BERRY BURST (2026-10-12, the owner's item 12): Count berries
	-- around the admin, MinRadius .. MaxRadius studs out -- wide enough for
	-- five at Spacing -- on a floor no more than MaxStep above or below the
	-- one the admin stands on (RootHeight under their body when none is found
	-- there), Tries spots each.
	Burst = { Count = 5, MinRadius = 8, MaxRadius = 24, MaxStep = 4, RootHeight = 3, Tries = 30 },
}

--==============================================================================
-- THE MYSTERIOUS POD'S CREATURES -- CONFIRMED (owner, 2026-10-11): these
-- weights as they stand. Version unchanged, so saved records stay valid.
--
-- Weights in percent; one creature per pod, chosen by the server at grant and
-- saved, never by a client. Grovemaw is the guardian and is never here.
-- Secrets keep their own authored size and fixed income: no size is rolled.
--==============================================================================
EnchantedMistData.Pool = {
	Version = 1,
	Approved = true,
	Entries = {
		{ Id = "mossbristle", Name = "Mossbristle", Rarity = "Legendary", Weight = 60 },
		{ Id = "briarstag", Name = "Briarstag", Rarity = "Mythic", Weight = 17 },
		{ Id = "hollowl", Name = "Hollowl", Rarity = "Mythic", Weight = 17 },
		{ Id = "elderbough", Name = "Elderbough", Rarity = "Divine", Weight = 5 },
		{ Id = "gnarlmaw", Name = "Gnarlmaw", Rarity = "Secret", Weight = 0.8 },
		{ Id = "snarlbloom", Name = "Snarlbloom", Rarity = "Secret", Weight = 0.2 },
	},
}

--==============================================================================
-- THE SIZE, FOR LEGENDARY TO DIVINE -- CONFIRMED (owner, 2026-10-11):
-- these conditional odds as they stand (Version unchanged), Tiny to
-- Colossal, in SeedData.Tiers' order. A creature of these
-- rarities rolls one size once it is chosen; the joint odds are the product.
--==============================================================================
EnchantedMistData.Sizes = {
	Version = 1,
	Approved = true,
	Weights = { 0.5325, 0.1593, 0.1007, 0.0789, 0.0592, 0.0642, 0.0052 },
}

--==============================================================================
-- PURE HELPERS (the server's rolls and the Odds panel read the same numbers)
--==============================================================================
local SIZED = { Legendary = true, Mythic = true, Divine = true }

-- Whether a pool entry rolls a size (Secrets never do).
function EnchantedMistData.isSized(rarity: string): boolean
	return SIZED[rarity] == true
end

-- THE REVEAL'S TIMES (MysteryRevealUI), in seconds from its start, for a
-- reveal `seconds` long (Shell.ReelSeconds; the world reveal follows it):
--   creature  the creature reel's spin: it lands then
--   next      a sized creature's card has held Shell.LandHoldSeconds -- long
--             enough to read which creature came out -- and the size reel
--             starts; a Secret's "A SECRET!" comes right after it lands
--   sizeSpin  the size reel's spin, landing before the world reveal (0 for a
--             Secret)
--   close     the strip closes
export type ReelTimes = { creature: number, next: number, sizeSpin: number, close: number }

function EnchantedMistData.reelTimes(sized: boolean, seconds: number): ReelTimes
	local hold = EnchantedMistData.Shell.LandHoldSeconds
	local spin = math.max(seconds - hold, 0.6)
	if sized then
		local creature = spin * 0.5
		return { creature = creature, next = creature + hold, sizeSpin = math.max(spin - creature - 0.4, 0.2),
			close = seconds + 0.6 }
	end
	return { creature = spin, next = spin + 0.15, sizeSpin = 0, close = seconds + 0.6 }
end

-- The pool entry a uniform `r` in [0, 1) lands on.
function EnchantedMistData.pickCreature(r: number): any
	local total = 0
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		total += e.Weight
	end
	local at = r * total
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		at -= e.Weight
		if at < 0 then
			return e
		end
	end
	return EnchantedMistData.Pool.Entries[#EnchantedMistData.Pool.Entries]
end

-- The size tier (1 = Tiny .. 7 = Colossal) a uniform `r` in [0, 1) lands on.
function EnchantedMistData.pickSize(r: number): number
	local weights = EnchantedMistData.Sizes.Weights
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local at = r * total
	for i, w in ipairs(weights) do
		at -= w
		if at < 0 then
			return i
		end
	end
	return #weights
end

-- A creature's share of all pods, in percent.
function EnchantedMistData.creatureChance(id: string): number
	local total, mine = 0, 0
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		total += e.Weight
		if e.Id == id then
			mine += e.Weight
		end
	end
	return if total > 0 then 100 * mine / total else 0
end

-- A size's share among sized creatures, in percent.
function EnchantedMistData.sizeChance(tier: number): number
	local weights = EnchantedMistData.Sizes.Weights
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	return if total > 0 then 100 * (weights[tier] or 0) / total else 0
end

-- Pod math for a delivery (the server's, CONFIRMED rule): everything carried is
-- added to the saved progress; ten makes a pod, the rest stays saved. A single
-- delivery earns at most one pod (carry 5 + progress 9 = 14).
function EnchantedMistData.deliver(progress: number, carried: number): (number, number)
	local total = progress + carried
	local pods = math.floor(total / EnchantedMistData.BerriesPerPod)
	return math.min(pods, 1), total - math.min(pods, 1) * EnchantedMistData.BerriesPerPod
end

return EnchantedMistData
