--!strict
-- Steal The Artifact :: ArtifactData
--
-- Every artifact in the game, the odds of finding one, and the economy numbers
-- that depend on them. THE SINGLE SOURCE OF TRUTH for all three -- GameConfig
-- deliberately holds none of it.
--
--==============================================================================
-- THE SEVEN NAMED ARTIFACTS ARE THE BLUEPRINT'S, VALUES UNCHANGED
--
-- Ancient Coin 100 -> Time Artifact 5,000,000. That is a 50,000x spread across
-- seven bands, and it is the spine of the game: it is what makes a Legendary
-- carrier worth chasing across the map and a Common carrier worth ignoring.
-- Do not compress it to make early play feel better -- fix the odds instead.
--
-- The extra entries in the lower bands exist so that the first ten minutes are
-- not the same four words over and over. Every band still has its blueprint
-- artifact as the top value in that band.
--==============================================================================

local Shared = script.Parent
local Types = require(Shared:WaitForChild("Types"))
-- Hoisted. GameConfig does not require this file, so there is no cycle, and a
-- require inside the roll function would re-resolve the module on every single
-- artifact spawn.
local GameConfig = require(Shared:WaitForChild("GameConfig"))

type ArtifactType = Types.ArtifactType

local ArtifactData = {}

--==============================================================================
-- CROSS-RARITY ODDS
--
-- Relative weights, not percentages, so adding a band never requires
-- re-balancing every other number to keep a total at 100.
--
-- As shipped this is roughly: Common 62%, Uncommon 25%, Rare 9.9%, Epic 2.5%,
-- Legendary 0.5%, Mythic 0.06%, Secret 0.002%. A Secret is about one roll in
-- fifty thousand, which at a few rolls a minute per player is a thing a busy
-- server sees once every day or so -- rare enough to be an event, common enough
-- that it is not a myth.
--==============================================================================
ArtifactData.RarityWeights = {
	Common    = 62000,
	Uncommon  = 25000,
	Rare      = 9900,
	Epic      = 2500,
	Legendary = 500,
	Mythic    = 60,
	Secret    = 2,
}

--==============================================================================
-- THE ARTIFACTS
--
-- Weight here is RELATIVE WITHIN THE BAND. Cross-band odds come from
-- RarityWeights above and never from these -- mixing the two scales is how a
-- rarity table ends up meaning nothing.
--
-- CarryPenalty is studs per second taken off the carrier's walk speed. It rises
-- with value on purpose: the better the prize, the longer you are exposed
-- carrying it, which is the entire risk/reward curve of the game expressed as
-- one column.
--==============================================================================
local ARTIFACTS: { ArtifactType } = {
	-- Common ------------------------------------------------------------
	{
		Id = "ancient_coin", DisplayName = "Ancient Coin",
		Rarity = "Common", Value = 100, Weight = 60,
		Color = Color3.fromRGB(214, 176, 92), Material = Enum.Material.Metal,
		Scale = 0.7, CarryPenalty = 1,
	},
	{
		Id = "clay_shard", DisplayName = "Clay Shard",
		Rarity = "Common", Value = 60, Weight = 40,
		Color = Color3.fromRGB(186, 122, 88), Material = Enum.Material.Slate,
		Scale = 0.7, CarryPenalty = 1,
	},

	-- Uncommon ----------------------------------------------------------
	{
		Id = "bronze_statue", DisplayName = "Bronze Statue",
		Rarity = "Uncommon", Value = 500, Weight = 60,
		Color = Color3.fromRGB(176, 118, 62), Material = Enum.Material.Metal,
		Scale = 0.9, CarryPenalty = 3,
	},
	{
		Id = "silver_chalice", DisplayName = "Silver Chalice",
		Rarity = "Uncommon", Value = 350, Weight = 40,
		Color = Color3.fromRGB(200, 206, 214), Material = Enum.Material.Metal,
		Scale = 0.85, CarryPenalty = 3,
	},

	-- Rare --------------------------------------------------------------
	{
		Id = "golden_mask", DisplayName = "Golden Mask",
		Rarity = "Rare", Value = 5000, Weight = 60,
		Color = Color3.fromRGB(255, 205, 74), Material = Enum.Material.Metal,
		Scale = 1.0, CarryPenalty = 5,
	},
	{
		Id = "jade_idol", DisplayName = "Jade Idol",
		Rarity = "Rare", Value = 3200, Weight = 40,
		Color = Color3.fromRGB(88, 196, 140), Material = Enum.Material.Marble,
		Scale = 1.0, CarryPenalty = 5,
	},

	-- Epic --------------------------------------------------------------
	{
		Id = "pharaoh_relic", DisplayName = "Pharaoh Relic",
		Rarity = "Epic", Value = 25000, Weight = 60,
		Color = Color3.fromRGB(240, 190, 100), Material = Enum.Material.Neon,
		Scale = 1.15, CarryPenalty = 8,
	},
	{
		Id = "obsidian_tablet", DisplayName = "Obsidian Tablet",
		Rarity = "Epic", Value = 18000, Weight = 40,
		Color = Color3.fromRGB(64, 56, 84), Material = Enum.Material.Glass,
		Scale = 1.15, CarryPenalty = 8,
	},

	-- Legendary ---------------------------------------------------------
	{
		Id = "dragon_crown", DisplayName = "Dragon Crown",
		Rarity = "Legendary", Value = 100000, Weight = 100,
		Color = Color3.fromRGB(255, 138, 62), Material = Enum.Material.Neon,
		Scale = 1.3, CarryPenalty = 11,
	},

	-- Mythic ------------------------------------------------------------
	{
		Id = "void_crystal", DisplayName = "Void Crystal",
		Rarity = "Mythic", Value = 500000, Weight = 100,
		Color = Color3.fromRGB(148, 92, 255), Material = Enum.Material.Neon,
		Scale = 1.45, CarryPenalty = 14,
	},

	-- Secret ------------------------------------------------------------
	{
		Id = "time_artifact", DisplayName = "Time Artifact",
		Rarity = "Secret", Value = 5000000, Weight = 100,
		Color = Color3.fromRGB(120, 240, 236), Material = Enum.Material.Neon,
		Scale = 1.6, CarryPenalty = 17,
	},
}

ArtifactData.Artifacts = ARTIFACTS

-- Indexed both ways at load, so nothing at runtime ever walks the list.
local byId: { [string]: ArtifactType } = {}
local byRarity: { [string]: { ArtifactType } } = {}
for _, artifact in ipairs(ARTIFACTS) do
	byId[artifact.Id] = artifact
	local bucket = byRarity[artifact.Rarity]
	if not bucket then
		bucket = {}
		byRarity[artifact.Rarity] = bucket
	end
	table.insert(bucket, artifact)
end
ArtifactData.ById = byId
ArtifactData.ByRarity = byRarity

--==============================================================================
-- CARRY
--
-- BaseWalkSpeed is what a player runs at with empty hands. MinWalkSpeed is the
-- floor a carry penalty can never take them below -- without it a Secret
-- artifact would pin the carrier at a standstill and the run home would stop
-- being a risk and start being a death sentence.
--==============================================================================
ArtifactData.Carry = {
	BaseWalkSpeed = 20,
	MinWalkSpeed = 6,
	-- How long a dropped artifact lies on the ground before it despawns.
	DroppedLifetime = 60,
	-- A grace period after a drop during which the person who dropped it
	-- cannot pick it straight back up. Without it, dying next to your own
	-- artifact and instantly regrabbing it removes the entire point of PvP.
	StealGrace = 1.5,
}

--==============================================================================
-- ECONOMY
--
-- Deposit is the only way coins are minted in Phase 2. Keep it that way as long
-- as possible: an economy with exactly one faucet is one you can still reason
-- about at Phase 5.
--==============================================================================
ArtifactData.Economy = {
	StartingCoins = 0,
	-- Multiplier applied to an artifact's Value when it is deposited. 1.0 means
	-- the number on the tin is the number you are paid, which is worth keeping
	-- until there is a reason not to -- a player who is told 5,000 and paid
	-- 3,750 stops trusting every other number in the game.
	DepositMultiplier = 1.0,
	-- Experience is the artifact's value, damped. A flat rate per artifact would
	-- make farming Commons the fastest way to level.
	ExperiencePerValue = 0.01,
	ExperiencePerLevel = 1000,
	MaxLevel = 100,
}

--==============================================================================
-- ROLLING
--
-- Server-only in practice, but it lives here rather than in a service because
-- it is a pure function of this file's own tables, and a roll that lives next
-- to its odds is a roll you can audit by reading one screen.
--
-- Takes an optional Random so a caller can make the sequence reproducible in a
-- test. Never seeded here: a module-level seed shared by every call is how two
-- servers end up rolling the same artifact at the same moment.
--==============================================================================
function ArtifactData.RollRarity(rng: Random?): string
	local total = 0
	for _, weight in pairs(ArtifactData.RarityWeights) do
		total += weight
	end

	local roll = if rng then rng:NextNumber(0, total) else math.random() * total
	-- Walked in canonical order, NOT in pairs() order. A hash table has no
	-- order, so rolling over pairs() would give a different distribution
	-- boundary on every server -- correct on average, unreproducible in a test.
	local cursor = 0
	for _, rarity in ipairs(GameConfig.Rarities) do
		cursor += ArtifactData.RarityWeights[rarity] or 0
		if roll <= cursor then
			return rarity
		end
	end
	return "Common"
end

function ArtifactData.RollArtifact(rng: Random?): ArtifactType
	local rarity = ArtifactData.RollRarity(rng)
	local bucket = byRarity[rarity]
	if not bucket or #bucket == 0 then
		return byId.ancient_coin
	end

	local total = 0
	for _, artifact in ipairs(bucket) do
		total += artifact.Weight
	end
	local roll = if rng then rng:NextNumber(0, total) else math.random() * total
	local cursor = 0
	for _, artifact in ipairs(bucket) do
		cursor += artifact.Weight
		if roll <= cursor then
			return artifact
		end
	end
	return bucket[1]
end

return ArtifactData
