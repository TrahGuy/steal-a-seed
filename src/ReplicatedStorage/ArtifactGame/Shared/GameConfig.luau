--!strict
-- Steal an Artifact :: GameConfig
--
-- Canonical shared configuration. Names live here so no later phase ever
-- duplicates one. Every gameplay DECISION still happens on the server -- this
-- file is replicated to clients, so treat everything in it as public.
--
--==============================================================================
-- WHAT DOES **NOT** BELONG IN THIS FILE
--
-- Artifact values, rarity weights and economy balance live in ArtifactData;
-- zone geometry lives in ZoneData. The predecessor project put placeholder
-- `Ore` and `Economy` tables in its GameConfig and by Phase 2 they held zeros
-- that contradicted the real numbers, so the tables had to be deleted and every
-- reader repointed. Do not start that again: if a number describes an artifact
-- or a zone, it goes in that data file, not here.
--==============================================================================

local GameConfig = {}

GameConfig.ProjectName = "Steal an Artifact"
GameConfig.Version = "0.1.0"
GameConfig.Phase = 1

--==============================================================================
-- CAPACITY
--
-- Bases and players are ONE number. The predecessor shipped with a 6-plot map
-- on a 60-player place, and the seventh joiner onwards got a body, a toast and
-- no base for the rest of the session. Keeping the two equal here does not
-- enforce it -- Players.MaxPlayers is a PLACE setting that can only be changed
-- in Game Settings -> Places -- so this is the number to set it to, and
-- ServerMain warns at boot if it does not match.
--==============================================================================
GameConfig.MaxBases = 8
GameConfig.MaxPlayers = 8

--==============================================================================
-- THE MAP IS BUILT FROM CODE, NOT PLACED BY HAND
--
-- This is the single most important structural decision in the project, and it
-- is a direct lesson from both predecessors. Cloud Cafe's map and NPC rigs live
-- only inside a .rbxl and are called out in its audit as the thing a lost file
-- would destroy. Steal the Ore and Forge's 3,204-part foundry is still listed
-- in its handoff as "the only remaining unreproducible artifact".
--
-- So MapService builds this map from these numbers on every boot. Losing the
-- place file costs nothing, the map is diffable in git, and moving the whole
-- island is one edit to BaseY.
--==============================================================================
GameConfig.Map = {
	FolderName = "ArtifactMap",
	BasesFolderName = "Bases",
	ZonesFolderName = "Zones",
	EnvironmentFolderName = "Environment",

	-- World Y of the ground surface. Everything else is derived from it.
	BaseY = 500,

	-- The neutral spawn island in the middle.
	SpawnRadius = 34,
	SpawnName = "SafeSpawn",

	-- How far out the ring of bases sits from the centre.
	BaseRingRadius = 150,

	-- The two artifact zones sit on the +Z / -Z axis. The base ring is rotated
	-- half a step (see MapService) so no base ever sits directly in front of a
	-- zone -- otherwise one or two players would spawn with a materially
	-- shorter run home than everybody else.
	--
	-- 280 IS A CLEARANCE, NOT A TASTE. At 250 the two nearest bases physically
	-- intersected the zone floor and it is visible in a screenshot: a base reaches
	-- BaseRingRadius + Base.Size/2 = 178, and a zone 160 deep centred at 250
	-- starts at 170. Any change to BaseRingRadius, Base.Size or a zone's Size.Z
	-- has to keep (ZoneDistance - Size.Z/2) above that number -- MapService
	-- checks it at boot and warns rather than trusting this comment.
	ZoneDistance = 280,
	OverflowSpawnName = "OverflowSpawn",
}

GameConfig.Base = {
	NamePrefix = "Base_",
	Size = 56,
	FloorThickness = 3,
	SpawnPadName = "SpawnPad",
	DisplayName = "ArtifactDisplay",
	CollectorName = "CoinCollector",
	UpgradeAreaName = "UpgradeArea",
	SignName = "OwnerSign",
	SignOwnerLabelName = "OwnerLabel",
	ProtectionZoneName = "ProtectionZone",
	RuntimeFolderName = "Runtime",
	SpawnHeightOffset = 4,
	UnclaimedText = "UNCLAIMED",

	-- Phase 4 grows this. Phase 1 only needs to know how many pedestals to
	-- build, and building the full level-1 set now means the display is a real
	-- object later services can attach to rather than something to retrofit.
	StartingDisplaySlots = 5,
}

--==============================================================================
-- ATTRIBUTES
--
-- The names of every attribute the server stamps onto instances. Read through
-- this table, never typed as a literal -- a typo in a literal is a silent nil,
-- not an error.
--==============================================================================
GameConfig.Attributes = {
	BaseId = "BaseId",
	OwnerUserId = "OwnerUserId",
	Claimed = "Claimed",
	-- Phase 2+. Named now so the carry guard and the HUD cannot disagree about
	-- the spelling later.
	CarryingArtifact = "CarryingArtifact",
	ArtifactInstanceId = "ArtifactInstanceId",
	CombatDisabled = "CombatDisabled",
}

GameConfig.Tags = {
	ArtifactDisplay = "ArtifactDisplay",
	CoinCollector = "CoinCollector",
	UpgradeArea = "UpgradeArea",
	ProtectionZone = "ProtectionZone",
	BaseSpawn = "BaseSpawn",
	ArtifactZone = "ArtifactZone",
	ArtifactPedestal = "ArtifactPedestal",
}

--==============================================================================
-- REMOTES
--
-- Every remote the game will ever create, named in one place. ServerMain
-- creates the folder; each service creates only the ones it owns.
--==============================================================================
GameConfig.Remotes = {
	BaseAssigned = "BaseAssigned",     -- server -> client: which base is yours
	ProfileUpdated = "ProfileUpdated", -- server -> client: coins / level / counts
	-- Phase 2
	CarryStateChanged = "CarryStateChanged",
	DropArtifactRequest = "DropArtifactRequest",
	GameEvent = "GameEvent",           -- server -> client: transient toasts
}

--==============================================================================
-- RARITY
--
-- Canonical order, index = tier. Straight from the blueprint. Everything that
-- sorts, colours or compares rarity reads this, so there is exactly one place
-- where "is Epic above Rare" is answered.
--==============================================================================
GameConfig.Rarities = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret",
}

local rarityTier: { [string]: number } = {}
for index, name in ipairs(GameConfig.Rarities) do
	rarityTier[name] = index
end
GameConfig.RarityTier = rarityTier

--==============================================================================
-- SAVE
--
-- CURRENT_VERSION IS FORWARD-ONLY. Never lower it without also changing
-- StoreName: an old server reading a newer profile is the one way to lose
-- somebody's account, and a version number that has gone backwards is how that
-- happens.
--==============================================================================
GameConfig.Save = {
	-- RENAMED WHILE IT WAS STILL FREE. This key was "StealTheArtifact_v1" for
	-- about an hour, before the game had ever run and therefore before a single
	-- profile existed under it. That is the ONLY moment a store name can be
	-- changed: renaming it after launch orphans every save under the old key,
	-- silently, and every player starts again from zero.
	StoreName = "StealAnArtifact_v1",
	CurrentVersion = 1,
	AutosaveSeconds = 90,
	-- Roblox throttles DataStore writes per key. Below this gap a save request
	-- is coalesced rather than sent.
	MinWriteGap = 7,
	RetryAttempts = 4,
}

--==============================================================================
-- COMBAT
--
-- Off until Phase 3. Present now so no service has to invent the flag.
--==============================================================================
GameConfig.Combat = {
	Enabled = false,
	SafeZonesBlockDamage = true,
}

--==============================================================================
-- deepFreeze
--
-- Config is read by everybody and written by nobody. Freezing turns "a service
-- quietly mutated a shared table and something across the game changed" into an
-- immediate error at the line that did it.
--==============================================================================
local function deepFreeze(target: { [any]: any }): { [any]: any }
	for _, value in pairs(target) do
		if type(value) == "table" then
			deepFreeze(value)
		end
	end
	return table.freeze(target)
end

return deepFreeze(GameConfig)
