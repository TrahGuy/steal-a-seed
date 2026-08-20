--!strict
-- Steal an Artifact :: Types
--
-- Shared type vocabulary for every phase. No runtime behaviour.
--
-- Every type here has to describe something that actually exists. The
-- predecessor's Types file carried an `OreDescriptor` in a shape nothing ever
-- produced, which meant the annotation was worse than none -- it read as
-- documentation and it was wrong. If a shape changes, this file changes in the
-- same commit.

export type Rarity =
	"Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

-- Matches GameConfig.Tags exactly. No shorter aliases.
export type ZoneKind = "ArtifactZone" | "ProtectionZone"

--==============================================================================
-- BASES
--==============================================================================
export type BaseSnapshot = {
	baseId: number,
	claimed: boolean,
	ownerUserId: number,
}

--==============================================================================
-- PLAYER PROFILE
--
-- The authoritative per-player record. `artifactsOwned` is keyed by artifact id
-- with a count, not a list, because a list of five thousand duplicate ids is a
-- save that eventually stops fitting in a DataStore key.
--==============================================================================
export type Profile = {
	version: number,
	coins: number,
	level: number,
	experience: number,
	artifactsCollected: number,
	artifactsOwned: { [string]: number },
	baseLevel: number,
	equipment: { [string]: boolean },
	createdAt: number,
	updatedAt: number,
}

-- What the client is told. Deliberately a SUMMARY, not the profile: a client
-- never needs createdAt, and anything replicated is something an exploiter can
-- read, so the smallest honest shape is the right one.
export type ProfileView = {
	coins: number,
	level: number,
	experience: number,
	artifactsCollected: number,
	baseLevel: number,
}

--==============================================================================
-- ARTIFACTS  (Phase 2 uses these; defined now so the data file can be typed)
--==============================================================================
export type ArtifactType = {
	Id: string,
	DisplayName: string,
	Rarity: Rarity,
	Value: number,
	-- Relative roll weight WITHIN its rarity band. Cross-rarity odds come from
	-- ArtifactData.RarityWeights, never from these.
	Weight: number,
	Color: Color3,
	Material: Enum.Material,
	Scale: number,
	-- Studs per second removed from the carrier's walk speed. Bigger prize,
	-- slower run home -- the whole risk curve of the game is this one number.
	CarryPenalty: number,
}

export type ArtifactDescriptor = {
	InstanceId: string,
	TypeId: string,
	DisplayName: string,
	Rarity: Rarity,
	Value: number,
	SpawnedAt: number,
}

--==============================================================================
-- SERVICES
--
-- The contract every "*Service" ModuleScript under ArtifactGameServer may
-- implement. ServerMain requires each one, runs Init() on all of them, then
-- Start() on all of them, ordered by Priority.
--==============================================================================
export type Service = {
	Priority: number?,
	Init: (() -> ())?,
	Start: (() -> ())?,
}

return {}
