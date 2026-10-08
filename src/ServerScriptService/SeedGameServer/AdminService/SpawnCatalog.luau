--!strict
--==============================================================================
-- Steal a Seed :: SpawnCatalog (AdminService, 2026-10-07)
--
-- WHAT THE ADMIN CONSOLE'S SPAWN CAN MAKE, read off SeedData and nothing else:
-- every species the game has, in the console's groups, the sizes each one
-- really comes in, and which Rain pod a Rain creature comes in at a size. ONE
-- ANSWER FOR BOTH ENDS: AdminService refuses whatever this does not allow, and
-- the console offers only what it allows, so the two cannot disagree.
--
--   groups   each biome's listed species, in BiomeData's road order; then the
--            Secrets, the Rain event's creatures (Rain and Thunderstorm, both
--            families) and the Invite a Friend rewards
--   sizes    a listed species: all seven, Tiny .. Colossal. A Secret: its one
--            SeedData.SecretTier. An Invite reward: its one InviteTier. A Rain
--            creature: exactly the sizes its pods lay (SeedData.RainPods) --
--            Pod 1's and Pod 3's one hidden tier, Pod 2's Colossal, and the
--            second family's Tiny .. Titan from rainpod4 with Colossal from
--            rainpod5 (the owner's "a rainpod4 spawn picks Tiny..Titan, and
--            Colossal means rainpod5")
--   words    "3x Colossal Lanterncap pod" (the preview), "3 Colossal Lanterncap
--            pods" (a sentence), and no size word at all for anything Unsized
--            (SeedData.Unsized): a Secret, an Invite reward, Pod 1 and Pod 3
--
-- A spawned item is only ever a species id and a tier, the two things a saved
-- row holds: its shell, growth, income, reveal and flags all follow from them
-- as they do for an earned one, so nothing here describes them.
--
-- ADMIN-ONLY, LIKE THE CONSOLE. A child of AdminService, in ServerScriptService,
-- which never replicates; AdminService clones it, with the console, into an
-- allowlisted admin's own SeedAdmin gui and gives nobody else anything. Pure:
-- no Instance is made, read or changed here.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local SpawnCatalog = {}

--==============================================================================
-- THE TWO FORMS
--==============================================================================
SpawnCatalog.Forms = { "pod", "plant" }
local NOUN: { [string]: string } = { pod = "pod", plant = "grown plant" }
local NOUNS: { [string]: string } = { pod = "pods", plant = "grown plants" }

function SpawnCatalog.isForm(form: any): boolean
	return type(form) == "string" and NOUN[form] ~= nil
end

--==============================================================================
-- THE GROUPS
--==============================================================================
export type Group = { id: string, label: string, species: { SeedData.Species } }

local groups: { Group } = {}
local groupOf: { [string]: string } = {}

local function addGroup(id: string, label: string, list: { SeedData.Species })
	local kept: { SeedData.Species } = {}
	for _, species in ipairs(list) do
		if groupOf[species.Id] == nil then
			groupOf[species.Id] = id
			table.insert(kept, species)
		end
	end
	if #kept > 0 then
		table.insert(groups, { id = id, label = label, species = kept })
	end
end

for _, biome in ipairs(BiomeData.Biomes) do
	addGroup(biome.Id, string.upper(biome.DisplayName), SeedData.InBiome(biome.Id))
end
addGroup("secret", "SECRETS", SeedData.SecretSpecies)
addGroup("rain", "RAIN EVENT", SeedData.RainSpecies)
addGroup("invite", "INVITE REWARDS", SeedData.InviteSpecies)

-- Every group, in the console's order. Copies: nothing a caller does to the
-- answer reaches the next caller.
function SpawnCatalog.groups(): { Group }
	local out: { Group } = {}
	for _, g in ipairs(groups) do
		table.insert(out, { id = g.id, label = g.label, species = table.clone(g.species) })
	end
	return out
end

-- The group a species is shown in, by its id; nil for an id SeedData does not know.
function SpawnCatalog.groupOf(speciesId: string): string?
	return groupOf[speciesId]
end

-- Every species the game has, in the console's order.
function SpawnCatalog.all(): { SeedData.Species }
	local out: { SeedData.Species } = {}
	for _, g in ipairs(groups) do
		for _, species in ipairs(g.species) do
			table.insert(out, species)
		end
	end
	return out
end

--==============================================================================
-- THE SIZES A SPECIES REALLY COMES IN
--==============================================================================
-- Every Rain pod that holds this creature, by pod id (a stable order).
local function rainPodsOf(species: SeedData.Species): { SeedData.RainPod }
	local ids: { string } = {}
	for podId in pairs(SeedData.RainPods) do
		table.insert(ids, podId)
	end
	table.sort(ids)
	local out: { SeedData.RainPod } = {}
	for _, podId in ipairs(ids) do
		local pod = SeedData.RainPods[podId]
		if table.find(pod.Species, species.Id) then
			table.insert(out, pod)
		end
	end
	return out
end

-- The sizes a pod lays: its one Tier, or every size its Tiers can draw.
local function laysAt(pod: SeedData.RainPod, tier: number): boolean
	if pod.Tier ~= nil then
		return pod.Tier == tier
	end
	local weights = pod.Tiers
	return weights ~= nil and (weights[tier] or 0) > 0
end

local sizeCache: { [string]: { number } } = {}

local function sizesFor(species: SeedData.Species): { number }
	local cached = sizeCache[species.Id]
	if cached then
		return cached
	end
	local s = species :: any
	local out: { number } = {}
	if s.Secret == true then
		out = { SeedData.SecretTier }
	elseif s.Invite == true then
		out = { SeedData.InviteTier }
	elseif s.Event == "rain" then
		local pods = rainPodsOf(species)
		for tier = 1, SeedData.TierCount do
			for _, pod in ipairs(pods) do
				if laysAt(pod, tier) then
					table.insert(out, tier)
					break
				end
			end
		end
	elseif SeedData.Unsized(species) then
		out = { SeedData.BaseTier }
	else
		for tier = 1, SeedData.TierCount do
			table.insert(out, tier)
		end
	end
	sizeCache[species.Id] = out
	return out
end

-- The sizes `species` can be spawned at, smallest first. A copy.
function SpawnCatalog.sizesOf(species: SeedData.Species): { number }
	return table.clone(sizesFor(species))
end

-- One size and no picker: a Secret, an Invite reward, Pod 1, Pod 2 and Pod 3.
function SpawnCatalog.fixedSize(species: SeedData.Species): boolean
	return #sizesFor(species) == 1
end

-- Whether `tier` is a whole number this species really comes in.
function SpawnCatalog.allows(species: SeedData.Species?, tier: any): boolean
	if type(species) ~= "table" or type(tier) ~= "number" or tier ~= tier or tier ~= math.floor(tier) then
		return false
	end
	return table.find(sizesFor(species :: SeedData.Species), tier) ~= nil
end

-- The Rain pod a Rain creature comes in at `tier` (rainpod4 for the second
-- family's Tiny .. Titan, rainpod5 for its Colossal); nil for anything else.
function SpawnCatalog.podOf(species: SeedData.Species, tier: number): SeedData.RainPod?
	if (species :: any).Event ~= "rain" then
		return nil
	end
	for _, pod in ipairs(rainPodsOf(species)) do
		if laysAt(pod, tier) then
			return pod
		end
	end
	return nil
end

--==============================================================================
-- THE WORDS
--==============================================================================
-- The size word a species shows at `tier`, or nil for anything Unsized.
function SpawnCatalog.sizeWord(species: SeedData.Species, tier: number): string?
	if SeedData.Unsized(species) then
		return nil
	end
	return SeedData.TierName(tier)
end

local function head(species: SeedData.Species, tier: number): string
	local word = SpawnCatalog.sizeWord(species, tier)
	return (if word then word .. " " else "") .. species.Name
end

-- One item, no count: "Colossal Lanterncap pod", "Snarlbloom grown plant".
function SpawnCatalog.itemName(species: SeedData.Species, tier: number, form: string): string
	return head(species, tier) .. " " .. (NOUN[form] or form)
end

-- The console's preview: "3x Colossal Lanterncap pod".
function SpawnCatalog.preview(species: SeedData.Species, tier: number, form: string, quantity: number): string
	return string.format("%dx %s", quantity, SpawnCatalog.itemName(species, tier, form))
end

-- In a sentence: "3 Colossal Lanterncap pods", "a Snarlbloom pod", "an
-- Emberquill grown plant".
function SpawnCatalog.phrase(species: SeedData.Species, tier: number, form: string, quantity: number): string
	local words = head(species, tier)
	if quantity == 1 then
		local article = if string.match(string.lower(words), "^[aeiou]") then "an" else "a"
		return article .. " " .. words .. " " .. (NOUN[form] or form)
	end
	return string.format("%d %s %s", quantity, words, NOUNS[form] or form)
end

-- The small line under a card's name that tells two of a name apart: the Rain
-- pod or pods a creature comes in ("RAIN POD 1", "RAIN POD 2", "THUNDERSTORM
-- POD 3", "RAIN POD 4/5"), "SECRET", "INVITE"; nil for a listed species.
function SpawnCatalog.tagOf(species: SeedData.Species): string?
	local s = species :: any
	if s.Secret == true then
		return "SECRET"
	elseif s.Invite == true then
		return "INVITE"
	elseif s.Event == "rain" then
		local pods = rainPodsOf(species)
		if #pods == 0 then
			return "RAIN"
		end
		local numbers: { string } = {}
		for _, pod in ipairs(pods) do
			table.insert(numbers, string.match(pod.Id, "(%d+)$") or pod.Id)
		end
		return string.upper(pods[1].Name) .. " " .. table.concat(numbers, "/")
	end
	return nil
end

-- A search: the name, the id or the rarity contains the words typed (any
-- case). Empty words match everything.
function SpawnCatalog.matches(species: SeedData.Species, query: string): boolean
	local q = string.lower(string.match(query, "^%s*(.-)%s*$") or "")
	if q == "" then
		return true
	end
	return string.find(string.lower(species.Name), q, 1, true) ~= nil
		or string.find(species.Id, q, 1, true) ~= nil
		or string.find(string.lower(species.Rarity), q, 1, true) ~= nil
end

return SpawnCatalog
