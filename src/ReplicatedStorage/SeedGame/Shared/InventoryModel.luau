--!strict
--==============================================================================
-- Steal a Seed :: InventoryModel (2026-10-03, the owner's compact Bag + free
-- hotbar)
--
-- WHAT THE BAG SHOWS, AS DATA. Pure: it reads stand-in-able Tools (anything
-- with GetAttribute) and the profile's rows, and builds nothing. LoadoutUI
-- calls it, InventoryPanel draws what it answers, InventoryModelSpec drives it.
--
--   collect   every owned thing as one Item: the Held rows (with their live
--             Tool, or "restoring" while it is being put back), the bats and
--             traps owned, the Spin Ticket stack, the Bloomrunner Trail
--   face      what may be SAID about an item -- its visible name, size or
--             variant, picture and search words. Nothing else.
--   groups    identical items as one tile with a count; items on the shown
--             hotbar slots are left out; a phone's hidden slots (6-0) show in
--             the grid with a slot badge
--   filter / counts / sort / pick / details / emptyText / storage
--
-- A POD NEVER SAYS WHAT IS INSIDE IT. Its name is PlantInfo's ("Unhatched
-- pod", "Secret pod", a Rain pod's name), its group key, picture, search words
-- and place in the order come from what the shell LOOKS like -- its biome (or
-- its Secret or Rain pod) and its size -- never from the species id it holds.
-- Since the owner's 25 pods (2026-10-09, one pod per plant, PodForms) the
-- shell IS the species' own, so an ordinary pod's picture and group key are
-- its species' pod; its name and words still say only "Unhatched pod".
-- A plant still in its hatch roll (HatchRoll) is the pod it came out of.
-- Plants are grouped by species ID, never by name: Puddlepod and Colossal
-- Puddlepod share one.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
local HotbarSlots = require(Shared:WaitForChild("HotbarSlots"))
local WheelData = require(Shared:WaitForChild("WheelData"))
-- The owner's pods, one per plant (2026-10-09): a pod's picture is its own.
local PodForms = require(Shared:WaitForChild("PodForms"))

local InventoryModel = {}

InventoryModel.Categories = {
	{ id = "all", label = "All Items" },
	{ id = "plants", label = "Plants" },
	{ id = "pods", label = "Pods" },
	{ id = "equipment", label = "Equipment" },
	{ id = "tickets", label = "Spin Tickets" },
}

export type Item = {
	ref: string?,
	kind: string, -- "plant" | "pod" | "weapon" | "ticket" | "trail"
	tool: any?,
	restoring: boolean,
	speciesId: string?,
	tier: number,
	hatched: boolean,
	sealed: boolean,
	weaponId: string?,
	count: number,
	worn: boolean,
	favourite: boolean,
	order: number,
	-- A pod in the Bag (2026-10-09, pods hatch in the Bag): the server's
	-- os.time() it may be hatched (its Tool's HatchAt, else its row's), and
	-- whether that time has come. nil and false for anything else.
	hatchAt: number?,
	ready: boolean?,
}

export type Art = { kind: string, speciesId: string?, tier: number, weaponId: string? }

export type Face = {
	name: string,
	variant: string,
	variantColour: Color3,
	-- The rarity the player may already see (2026-10-03): a grown plant's form,
	-- a Secret or Rain pod's shell; nil for an ordinary pod (its hatch is the
	-- reveal), a plant still in its roll, and equipment. `variantIsRarity`
	-- when the variant line IS that word (no size to show instead).
	rarity: string?,
	variantIsRarity: boolean,
	accent: Color3?,
	visual: string,
	art: Art,
	search: string,
	category: string,
	-- Its studded card background (2026-10-04, GameConfig.BagLook.Studs): the
	-- upload nearest the rarity it already shows, or its kind's; nil keeps the
	-- plain card (a Common, an ordinary pod).
	studs: string?,
}

export type Group = {
	key: string,
	face: Face,
	items: { Item },
	count: number,
	favourite: boolean,
	restoring: boolean,
	held: boolean,
	badge: number?,
	category: string,
}

export type Input = {
	held: { any }?,
	tools: { any },
	weapons: { [string]: boolean }?,
	tickets: number?,
	trailOwned: boolean?,
	trailWorn: boolean?,
	favourites: { [string]: boolean }?,
	-- Item id -> the RevealAt last seen on its Tool. The client's own cache, kept
	-- across a respawn, so a plant restoring mid-roll is still its pod.
	sealedUntil: { [string]: number },
	now: number,
}

local QUIET = Color3.fromRGB(198, 176, 152)
local CREAM = Color3.fromRGB(242, 238, 206)
local KG = GameConfig.Attributes.CarryingKg
local ITEM = GameConfig.Attributes.ItemId
-- A pod's deadline on its Tool (2026-10-09, pods hatch in the Bag), and the
-- green a READY pod is said in.
local HATCH_AT = GameConfig.HatchInBag.Attribute
local READY_GREEN = Color3.fromRGB(126, 214, 92)
local WEAPON_ORDER: { [string]: number } = {}
for index, item in ipairs(WeaponData.Items) do
	WEAPON_ORDER[item.Id] = index
end
local BIOME_ORDER: { [string]: number } = {}
for index, biome in ipairs(BiomeData.Biomes) do
	BIOME_ORDER[biome.Id] = index
end

local function attr(tool: any, name: string): any
	local ok, value = pcall(function()
		return tool:GetAttribute(name)
	end)
	return if ok then value else nil
end

local function tierOf(value: any): number
	local n = tonumber(value)
	if not n or n ~= n then
		return 1
	end
	return math.clamp(math.floor(n), 1, SeedData.TierCount)
end

--==============================================================================
-- COLLECT
--==============================================================================
-- `hatchAt` (2026-10-09): a pod's deadline, read as a claim -- not a number,
-- and the pod has none (it says nothing about when, and is never READY).
local function plantItem(speciesId: string, tier: number, hatched: boolean, revealAt: any, now: number,
	hatchAt: any): Item
	local sealed = hatched and HatchRoll.hidden(revealAt, now)
	local due = if hatched then nil else tonumber(hatchAt)
	if due and due ~= due then
		due = nil
	end
	return {
		ref = nil,
		kind = if hatched and not sealed then "plant" else "pod",
		tool = nil,
		restoring = false,
		speciesId = speciesId,
		tier = tier,
		hatched = hatched,
		sealed = sealed,
		weaponId = nil,
		count = 1,
		worn = false,
		favourite = false,
		order = math.huge,
		hatchAt = due,
		ready = due ~= nil and now >= due,
	}
end

local function kindKey(speciesId: any, tier: number, hatched: boolean): string
	return tostring(speciesId) .. ":" .. tostring(tier) .. ":" .. tostring(hatched)
end

function InventoryModel.collect(input: Input): { Item }
	local items: { Item } = {}
	local now = input.now
	local byItem: { [string]: any } = {}
	local unnamed: { [string]: { any } } = {}
	local weaponTools: { [string]: any } = {}
	local ticketTool: any = nil
	local plantTools: { any } = {}
	for _, tool in ipairs(input.tools) do
		local weapon = attr(tool, HotbarSlots.WeaponAttribute)
		local species = attr(tool, "SpeciesId")
		if type(weapon) == "string" and WeaponData.Get(weapon) then
			weaponTools[weapon] = weaponTools[weapon] or tool
		elseif attr(tool, HotbarSlots.TicketAttribute) == true then
			ticketTool = ticketTool or tool
		elseif type(species) == "string" and SeedData.Get(species) then
			table.insert(plantTools, tool)
			local item = attr(tool, ITEM)
			local revealAt = attr(tool, HatchRoll.Attribute)
			if type(item) == "string" and item ~= "" then
				byItem[item] = byItem[item] or tool
				if HatchRoll.hidden(revealAt, now) then
					input.sealedUntil[item] = tonumber(revealAt) :: number
				end
			else
				local key = kindKey(species, tierOf(attr(tool, KG)), attr(tool, "Hatched") == true)
				unnamed[key] = unnamed[key] or {}
				table.insert(unnamed[key], tool)
			end
		end
	end

	-- The saved rows, each with its live Tool by name. A Tool that has not been
	-- told its id yet stands in for a row of its kind that has no Tool, so a
	-- hatch is never counted twice in the moment between its row and its stamp.
	local used: { [any]: boolean } = {}
	if type(input.held) == "table" then
		for index, row in ipairs(input.held :: { any }) do
			local species = if type(row) == "table" then SeedData.Get(tostring(row.Id)) else nil
			if species then
				local id = if type(row.Item) == "string" and row.Item ~= "" then row.Item else nil
				local tier = tierOf(row.Tier)
				local hatched = row.Hatched == true
				local tool = if id then byItem[id] else nil
				local named = tool ~= nil
				if not tool then
					local spare = unnamed[kindKey(species.Id, tier, hatched)]
					if spare and #spare > 0 then
						tool = table.remove(spare, 1)
					end
				end
				local revealAt = if tool then attr(tool, HatchRoll.Attribute)
					elseif id then input.sealedUntil[id] else nil
				-- A pod's deadline: its Tool's, which the server keeps in step with
				-- the row; the row's while the Tool is being put back.
				local due = if hatched then nil
					else (if tool then attr(tool, HATCH_AT) else nil) or row.HatchAt
				local item = plantItem(species.Id, tier, hatched, revealAt, now, due)
				item.tool = tool
				item.restoring = tool == nil
				-- Only a Tool that knows its id may be assigned: holdRef finds it by it.
				item.ref = if id and (named or tool == nil) then HotbarSlots.item(id) else nil
				item.order = tonumber(id) or (1e9 + index)
				if tool then
					used[tool] = true
				end
				table.insert(items, item)
			end
		end
	end
	-- Tools no row accounts for yet (before the profile, or a hatch a frame ahead
	-- of its push): held, never assigned.
	for _, tool in ipairs(plantTools) do
		if not used[tool] then
			local species = attr(tool, "SpeciesId") :: string
			local item = plantItem(species, tierOf(attr(tool, KG)), attr(tool, "Hatched") == true,
				attr(tool, HatchRoll.Attribute), now, attr(tool, HATCH_AT))
			item.tool = tool
			local id = attr(tool, ITEM)
			item.order = 2e9 + #items
			if type(id) == "string" and id ~= "" and input.held == nil then
				item.ref = HotbarSlots.item(id)
				item.order = tonumber(id) or item.order
			end
			table.insert(items, item)
		end
	end

	for _, weapon in ipairs(WeaponData.Items) do
		if input.weapons and input.weapons[weapon.Id] == true then
			table.insert(items, {
				ref = HotbarSlots.weapon(weapon.Id),
				kind = "weapon",
				tool = weaponTools[weapon.Id],
				restoring = false,
				speciesId = nil,
				tier = 1,
				hatched = false,
				sealed = false,
				weaponId = weapon.Id,
				count = 1,
				worn = false,
				favourite = false,
				order = WEAPON_ORDER[weapon.Id] or 99,
			})
		end
	end
	local tickets = math.floor(tonumber(input.tickets) or 0)
	if tickets ~= tickets then
		tickets = 0
	end
	if tickets >= 1 then
		table.insert(items, {
			ref = HotbarSlots.Ticket,
			kind = "ticket",
			tool = ticketTool,
			restoring = false,
			speciesId = nil,
			tier = 1,
			hatched = false,
			sealed = false,
			weaponId = nil,
			count = tickets,
			worn = false,
			favourite = false,
			order = 0,
		})
	end
	if input.trailOwned then
		table.insert(items, {
			ref = nil,
			kind = "trail",
			tool = nil,
			restoring = false,
			speciesId = nil,
			tier = 1,
			hatched = false,
			sealed = false,
			weaponId = nil,
			count = 1,
			worn = input.trailWorn == true,
			favourite = false,
			order = 100,
		})
	end
	local favourites = input.favourites or {}
	for _, item in ipairs(items) do
		item.favourite = item.ref ~= nil and favourites[item.ref :: string] == true
	end
	return items
end

--==============================================================================
-- FACE: VISIBLE FACTS ONLY
--==============================================================================
-- What a shell LOOKS like, and a species that draws exactly that shell: the
-- picture is built from the representative, never from what is inside --
-- EXCEPT the owner's 25 pods (2026-10-09, PodForms): one pod per plant, so a
-- pod's picture is its own species' pod, and two species' pods are two tiles.
local function podVisual(species: SeedData.Species, tier: number): (string, string, number, number)
	local rain = SeedData.RainPodOf(species)
	if rain then
		return "pod|r:" .. rain.Id .. "|" .. tier, rain.Species[1], 3, 1000
	end
	local biome = (species :: any).Biome :: string
	local order = BIOME_ORDER[biome] or 50
	if species.Secret == true then
		return "pod|s:" .. biome .. "|" .. tier, species.Id, 2, order
	end
	if PodForms.Has(species.Id) then
		return "pod|p:" .. species.Id .. "|" .. tier, species.Id, 1, order
	end
	local shelf = SeedData.InBiome(biome)
	local first = shelf[1]
	return "pod|b:" .. biome .. "|" .. tier, if first then first.Id else species.Id, 1, order
end

local STUDS_BY_RARITY: { [string]: string } = (GameConfig.BagLook.StudsByRarity :: any)
local STUDS_BY_KIND: { [string]: string } = (GameConfig.BagLook.StudsByKind :: any)

function InventoryModel.face(item: Item): Face
	if item.kind == "weapon" then
		local weapon = WeaponData.Get(item.weaponId) :: WeaponData.Item
		local word = if weapon.Category == "trap" then "Trap" else "Bat"
		return {
			name = weapon.Name,
			variant = word,
			variantColour = QUIET,
			rarity = nil,
			variantIsRarity = false,
			accent = nil,
			visual = "w|" .. weapon.Id,
			art = { kind = "weapon", speciesId = nil, tier = 1, weaponId = weapon.Id },
			search = string.lower(weapon.Name .. " " .. word),
			category = "equipment",
			studs = STUDS_BY_KIND.equipment,
		}
	elseif item.kind == "ticket" then
		return {
			name = GameConfig.Community.TicketName .. "s",
			variant = "Wheel spin",
			variantColour = Color3.fromRGB(255, 206, 84),
			rarity = nil,
			variantIsRarity = false,
			accent = nil,
			visual = "ticket",
			art = { kind = "ticket", speciesId = nil, tier = 1, weaponId = nil },
			search = string.lower(GameConfig.Community.TicketName .. "s ticket spin wheel"),
			category = "tickets",
			studs = STUDS_BY_KIND.tickets,
		}
	elseif item.kind == "trail" then
		local name = WheelData.Trail.Name
		return {
			name = name,
			variant = if item.worn then "Wearing" else "Trail",
			variantColour = if item.worn then Color3.fromRGB(142, 214, 86) else QUIET,
			rarity = nil,
			variantIsRarity = false,
			accent = nil,
			visual = "trail",
			art = { kind = "trail", speciesId = nil, tier = 1, weaponId = nil },
			search = string.lower(name .. " trail"),
			category = "equipment",
			studs = STUDS_BY_KIND.trail,
		}
	end
	local species = SeedData.Get(item.speciesId or "") :: SeedData.Species
	if item.kind == "plant" then
		local size = PlantInfo.SizeWord(species.Id, item.tier)
		local variant = size or species.Rarity
		-- The three rarest keep their inventory colour on the accent too, so
		-- the bar, the edge and the word agree (GameConfig.RarityFX).
		local fx = (GameConfig.RarityFX :: any)[species.Rarity]
		return {
			name = species.Name,
			variant = variant,
			variantColour = PlantInfo.SizeColour(species.Id, item.tier),
			rarity = species.Rarity,
			variantIsRarity = size == nil,
			accent = if fx then fx.Edge else GameConfig.RarityColor[species.Rarity],
			visual = "plant|" .. species.Id .. "|" .. item.tier,
			art = { kind = "plant", speciesId = species.Id, tier = item.tier, weaponId = nil },
			search = string.lower(species.Name .. " " .. variant),
			category = "plants",
			studs = STUDS_BY_RARITY[species.Rarity],
		}
	end
	-- A pod, or a plant whose roll still runs: the shell, described as a shell.
	local info = PlantInfo.Describe(species.Id, item.tier, false)
	local visual, drawAs = podVisual(species, item.tier)
	local variant = if info.sized then info.size elseif info.rarity ~= PlantInfo.Unknown then info.rarity else ""
	-- Only what the shell says: a Secret or Rain pod's rarity; never the
	-- species inside an ordinary pod (PlantInfo keeps that ???).
	local known = if info.rarity ~= PlantInfo.Unknown then info.rarity else nil
	return {
		name = info.title,
		variant = variant,
		variantColour = if info.sized then info.sizeColour else info.rarityColour,
		rarity = known,
		variantIsRarity = known ~= nil and not info.sized,
		accent = nil,
		visual = visual,
		art = { kind = "pod", speciesId = drawAs, tier = item.tier, weaponId = nil },
		search = string.lower(info.title .. " " .. variant),
		category = "pods",
		-- Only a rarity the shell already says (a Secret or Rain pod's).
		studs = if known then STUDS_BY_RARITY[known] else nil,
	}
end

--==============================================================================
-- GROUPS
--==============================================================================
local CATEGORY_RANK = { plants = 1, pods = 2, equipment = 3, tickets = 4 }

function InventoryModel.groupKey(item: Item, face: Face, badge: number?): string
	local key = face.visual
	if item.sealed then
		key ..= "|sealed"
	end
	-- A pod in the Bag (2026-10-09): its READY ones apart from those still
	-- growing, so a tile is all one or the other.
	if item.kind == "pod" and not item.hatched then
		key ..= if item.ready then "|ready" else "|grow"
	end
	if item.favourite then
		key ..= "|fav"
	end
	if badge then
		-- One tile per copy that has a slot: the badge names THAT copy.
		key ..= "|slot" .. badge .. "|" .. tostring(item.ref)
	end
	return key
end

-- `bar` the shown bar (ten refs), `shown` how many slots are on screen, `heldRef`
-- / `heldTool` what is in the hands now.
function InventoryModel.groups(items: { Item }, bar: { string }, shown: number, heldRef: string?,
	heldTool: any?): { Group }
	local list: { Group } = {}
	local byKey: { [string]: Group } = {}
	for _, item in ipairs(items) do
		local slot = if item.ref then HotbarSlots.slotOf(bar, item.ref) else nil
		if not (slot and slot <= shown) then
			local face = InventoryModel.face(item)
			local key = InventoryModel.groupKey(item, face, slot)
			local group = byKey[key]
			if not group then
				group = {
					key = key,
					face = face,
					items = {},
					count = 0,
					favourite = item.favourite,
					restoring = true,
					held = false,
					badge = slot,
					category = face.category,
				}
				byKey[key] = group
				table.insert(list, group)
			end
			local g = group :: Group
			table.insert(g.items, item)
			g.count += if item.kind == "ticket" then item.count else 1
			g.restoring = g.restoring and item.restoring
			if (heldRef ~= nil and item.ref == heldRef) or (heldTool ~= nil and item.tool == heldTool) then
				g.held = true
			end
		end
	end
	InventoryModel.sort(list)
	return list
end

local function firstOrder(group: Group): number
	local best = math.huge
	for _, item in ipairs(group.items) do
		best = math.min(best, item.order)
	end
	return best
end

-- The fixed order (no SORT button, the owner's spec lists none): favourites
-- first; then plants by base income, pods by biome and then size, equipment in
-- shop order, tickets. A pod's place reads its shell, never its species.
function InventoryModel.sort(list: { Group })
	local rank: { [Group]: { number } } = {}
	for _, g in ipairs(list) do
		local item = g.items[1]
		local a, b, c = 0, 0, 0
		if g.category == "plants" then
			a = -(PlantInfo.BaseIncome(item.speciesId, item.tier, true) or 0)
			b = -item.tier
		elseif g.category == "pods" then
			local species = SeedData.Get(item.speciesId or "")
			local _, _, kind, order = podVisual(species :: SeedData.Species, item.tier)
			a = order * 10 + kind
			b = -item.tier
			c = if item.sealed then 1 else 0
		elseif g.category == "equipment" then
			a = item.order
		end
		rank[g] = { if g.favourite then 0 else 1, CATEGORY_RANK[g.category] or 9, a, b, c, firstOrder(g) }
	end
	table.sort(list, function(x: Group, y: Group): boolean
		local rx, ry = rank[x], rank[y]
		for i = 1, 6 do
			if rx[i] ~= ry[i] then
				return rx[i] < ry[i]
			end
		end
		return x.key < y.key
	end)
end

function InventoryModel.filter(list: { Group }, category: string, search: string?, favouritesOnly: boolean): { Group }
	local out: { Group } = {}
	local query = if type(search) == "string" then string.lower((string.gsub(search, "^%s+", ""))) else ""
	query = string.gsub(query, "%s+$", "")
	for _, g in ipairs(list) do
		if (category == "all" or g.category == category)
			and (not favouritesOnly or g.favourite)
			and (query == "" or string.find(g.face.search, query, 1, true) ~= nil) then
			table.insert(out, g)
		end
	end
	return out
end

-- How many of each, bar included; Spin Tickets is the balance.
function InventoryModel.counts(items: { Item }): { [string]: number }
	local c = { all = 0, plants = 0, pods = 0, equipment = 0, tickets = 0 }
	for _, item in ipairs(items) do
		c.all += 1
		if item.kind == "plant" then
			c.plants += 1
		elseif item.kind == "pod" then
			c.pods += 1
		elseif item.kind == "ticket" then
			c.tickets += item.count
		else
			c.equipment += 1
		end
	end
	return c
end

-- The copy a press means: the one in hand if it is in this group, else the
-- live copy with the lowest item id, else the first. A tile of pods still
-- growing (2026-10-09) means the one due first: its countdown is the tile's.
function InventoryModel.pick(group: Group, heldRef: string?, heldTool: any?): Item?
	local best: Item? = nil
	for _, item in ipairs(group.items) do
		if (heldRef ~= nil and item.ref == heldRef) or (heldTool ~= nil and item.tool ~= nil and item.tool == heldTool) then
			return item
		end
		if not item.restoring then
			local b = best
			if b == nil then
				best = item
			elseif item.hatchAt ~= nil and b.hatchAt ~= nil and not item.ready and item.hatchAt ~= b.hatchAt then
				if item.hatchAt < (b.hatchAt :: number) then
					best = item
				end
			elseif item.order < b.order then
				best = item
			end
		end
	end
	return best or group.items[1]
end

--==============================================================================
-- PODS HATCH IN THE BAG (2026-10-09; GameConfig.HatchInBag)
--
--   clock       whole seconds as the countdown says them: 0:45, 4:05, 1:12:30
--   podState    a pod tile's: READY, or the countdown of the pod due first
--   readyCount  how many pods in the Bag are READY (HATCH ALL's number)
--==============================================================================
function InventoryModel.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	local h, m = s // 3600, (s % 3600) // 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s % 60)
	end
	return string.format("%d:%02d", m, s % 60)
end

-- nil for a tile that is not pods in the Bag; else whether it is READY, and the
-- seconds left on the pod due first.
function InventoryModel.podState(group: Group, now: number): (boolean?, number?)
	local soonest: number? = nil
	local ready = false
	local any = false
	for _, item in ipairs(group.items) do
		if item.kind == "pod" and not item.hatched and item.hatchAt then
			any = true
			if now >= (item.hatchAt :: number) then
				ready = true
			elseif soonest == nil or (item.hatchAt :: number) < soonest then
				soonest = item.hatchAt
			end
		end
	end
	if not any then
		return nil, nil
	end
	return ready, if soonest then math.max(0, soonest - now) else nil
end

function InventoryModel.readyCount(items: { Item }, now: number): number
	local n = 0
	for _, item in ipairs(items) do
		if item.kind == "pod" and not item.hatched and not item.restoring and item.hatchAt
			and now >= (item.hatchAt :: number) then
			n += 1
		end
	end
	return n
end

-- Every ref in a group, for a heart that favourites every copy.
function InventoryModel.refsOf(group: Group): { string }
	local refs: { string } = {}
	for _, item in ipairs(group.items) do
		if item.ref then
			table.insert(refs, item.ref :: string)
		end
	end
	return refs
end

--==============================================================================
-- DETAILS: the tooltip's and the menu's lines, visible facts only
--==============================================================================
-- `rarity` on the Rarity line only: the id the panel styles that word by.
export type Line = { key: string, value: string, colour: Color3?, rarity: string? }

-- `now` (2026-10-09): the server's time, for a pod's countdown.
function InventoryModel.details(item: Item, face: Face, multiplier: number?, slot: number?, inHand: boolean,
	now: number?): { Line }
	local lines: { Line } = {}
	local function add(key: string, value: string, colour: Color3?, rarity: string?)
		table.insert(lines, { key = key, value = value, colour = colour, rarity = rarity })
	end
	if item.kind == "plant" then
		local info = PlantInfo.Describe(item.speciesId, item.tier, true, multiplier)
		add("Rarity", info.rarity, info.rarityColour, info.rarity)
		if info.sized then
			add("Size", info.size, info.sizeColour)
		end
		add("Income", info.income)
		if info.sell then
			add("Sell", info.sell :: string)
		end
	elseif item.kind == "pod" then
		local info = PlantInfo.Describe(item.speciesId, item.tier, false)
		add("Biome", info.biome)
		if info.sized then
			add("Size", info.size, info.sizeColour)
		elseif info.rarity ~= PlantInfo.Unknown then
			add("Rarity", info.rarity, info.rarityColour, info.rarity)
		end
		add("Income", if item.sealed then "Hatching..." else PlantInfo.PodIncome)
		-- When it may be hatched (2026-10-09, pods hatch in the Bag).
		if not item.hatched and item.hatchAt then
			local left = (item.hatchAt :: number) - (now or (item.hatchAt :: number))
			add("Hatches", if left <= 0 then "Ready now" else "In " .. InventoryModel.clock(left),
				if left <= 0 then READY_GREEN else nil)
		end
	elseif item.kind == "weapon" then
		local weapon = WeaponData.Get(item.weaponId) :: WeaponData.Item
		for _, stat in ipairs(WeaponData.StatLines(weapon)) do
			add(stat.label, stat.value)
		end
	elseif item.kind == "ticket" then
		add("Count", "x" .. tostring(item.count))
		add("Use", GameConfig.Community.TicketHint)
	elseif item.kind == "trail" then
		add("Status", if item.worn then "Wearing" else "Not worn")
	end
	if item.restoring then
		add("Status", "Restoring...")
	elseif item.kind ~= "trail" then
		add("Status", PlantInfo.Status(inHand, slot))
	end
	return lines
end

function InventoryModel.emptyText(category: string, owned: number, filtered: boolean): string
	if filtered then
		return "Nothing matches."
	end
	if owned > 0 then
		return "Everything here is on your hotbar."
	end
	if category == "plants" then
		return "Hatch a pod to grow a plant here."
	elseif category == "pods" then
		return "Steal a pod and bring it home."
	elseif category == "equipment" then
		return "Buy a bat or a trap from Marigold."
	elseif category == "tickets" then
		return "Win Spin Tickets on the obby."
	end
	return "Your Bag is empty."
end

--==============================================================================
-- THE STORAGE LINE (the footer): Plant storage: 4/24, with a carried pod
-- "23 stored + 1 carried / 24", and prizes the wheel owes for want of room.
-- Answers the text, full, known.
--==============================================================================
function InventoryModel.storage(rows: number?, carrying: boolean, limit: number, waiting: number?): (string, boolean, boolean)
	if rows == nil then
		return "Plant storage: …", false, false
	end
	local stored = math.max(0, math.floor(rows))
	local count = stored + (if carrying then 1 else 0)
	local text = if carrying
		then string.format("Plant storage: %d stored + 1 carried / %d", stored, limit)
		else string.format("Plant storage: %d/%d", count, limit)
	local owed = math.floor(tonumber(waiting) or 0)
	if owed >= 1 then
		text ..= string.format(" · %d wheel prize%s waiting for room", owed, if owed == 1 then "" else "s")
	end
	return text, count >= limit, true
end

--==============================================================================
-- THE POD ROOM (2026-10-09, pods hatch in the Bag): "Pods: 12/60", with a pod
-- being carried home "Pods: 59+1/60" -- it keeps its place in this room, not the
-- plants'. Answers the text, full, known.
--==============================================================================
function InventoryModel.podStorage(rows: number?, carrying: boolean, limit: number): (string, boolean, boolean)
	if rows == nil then
		return "Pods: …", false, false
	end
	local stored = math.max(0, math.floor(rows))
	local count = stored + (if carrying then 1 else 0)
	local text = if carrying
		then string.format("Pods: %d+1/%d", stored, limit)
		else string.format("Pods: %d/%d", count, limit)
	return text, count >= limit, true
end

return InventoryModel
