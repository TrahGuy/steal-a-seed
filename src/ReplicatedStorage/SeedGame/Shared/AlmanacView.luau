--!strict
--==============================================================================
-- Steal a Seed :: AlmanacView (2026-10-03, the compact Index)
--
-- WHICH CARDS THE ALMANAC SHOWS, AND WHAT EACH ONE MAY SAY. Pure: the profile's
-- Almanac set in, a list out -- so CompactMenusSpec can prove the discovery
-- rules without a Play session.
--
--   a biome   its shelf, AlmanacData's order (commonest first), filtered
--             All / Grown / Missing
--   a search  every biome, road order then shelf order, same filter
--
-- WHAT A LOCKED CARD MAY GIVE AWAY: its rarity (the approved rule of
-- 2026-09-11: an undiscovered card shows its rarity colour and word) and the
-- biome it is in. Never its name. So a search matches a species' NAME only when
-- it has been grown, and otherwise only what the card already shows -- its
-- rarity word and its biome's name. A query naming a plant nobody has grown
-- finds nothing, and the count of results says nothing a card would not.
--
-- "Grown" is the profile's Almanac bit: grown on the player's own plot
-- (PlantService), never carried or stolen. This file only reads it.
--==============================================================================
local Shared = script.Parent
local AlmanacData = require(Shared:WaitForChild("AlmanacData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local AlmanacView = {}

export type Filter = "all" | "grown" | "missing"

AlmanacView.Filters = { "all", "grown", "missing" } :: { Filter }
AlmanacView.FilterLabels = { all = "All", grown = "Grown", missing = "Missing" } :: { [string]: string }

export type Entry = {
	species: any,
	biomeId: string,
	known: boolean,
}

-- The road and each biome's shelf, read once.
local road = AlmanacData.Biomes()
local shelves: { [string]: { any } } = {}
for _, biome in ipairs(road) do
	shelves[biome.Id] = AlmanacData.SpeciesIn(biome.Id)
end

function AlmanacView.road(): { any }
	return road
end

function AlmanacView.shelf(biomeId: string): { any }
	return shelves[biomeId] or {}
end

-- The query as it is compared: trimmed, lower case; "" when there is none.
function AlmanacView.normalise(query: string?): string
	if type(query) ~= "string" then
		return ""
	end
	return string.lower((string.gsub(query, "^%s+", ""):gsub("%s+$", "")))
end

local function contains(text: string, q: string): boolean
	return string.find(string.lower(text), q, 1, true) ~= nil
end

-- Whether a search finds this card: its name only when grown; its rarity word
-- and its biome's name always, since every card already shows those.
function AlmanacView.matches(species: any, biomeId: string, known: boolean, q: string): boolean
	if q == "" then
		return true
	end
	if known and contains(species.Name, q) then
		return true
	end
	if contains(tostring(species.Rarity), q) then
		return true
	end
	local biome = BiomeData.ById[biomeId]
	return biome ~= nil and contains(biome.DisplayName, q)
end

local function passes(filter: Filter, known: boolean): boolean
	if filter == "grown" then
		return known
	elseif filter == "missing" then
		return not known
	end
	return true
end

-- The cards to show, and whether this is a search across every biome.
function AlmanacView.list(almanac: { [string]: boolean }, biomeId: string, filter: Filter,
	query: string?): ({ Entry }, boolean)
	local q = AlmanacView.normalise(query)
	local out: { Entry } = {}
	local function add(id: string)
		for _, species in ipairs(shelves[id] or {}) do
			local known = almanac[species.Id] == true
			if passes(filter, known) and AlmanacView.matches(species, id, known, q) then
				table.insert(out, { species = species, biomeId = id, known = known })
			end
		end
	end
	if q ~= "" then
		for _, biome in ipairs(road) do
			add(biome.Id)
		end
		return out, true
	end
	add(biomeId)
	return out, false
end

-- What a card may print: the name, or "???" until grown; the rarity always.
function AlmanacView.face(species: any, known: boolean): { name: string, rarity: string }
	return {
		name = if known then species.Name else "???",
		rarity = tostring(species.Rarity),
	}
end

return AlmanacView
