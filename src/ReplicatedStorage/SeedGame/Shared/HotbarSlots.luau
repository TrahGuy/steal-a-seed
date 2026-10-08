--!strict
--==============================================================================
-- Steal a Seed :: HotbarSlots (2026-10-03, the owner's compact Bag + free hotbar)
--
-- WHAT A HOTBAR SLOT HOLDS, AS ONE GRAMMAR FOR THE SERVER AND THE CLIENT. Pure:
-- no Instances made, no services, no clock. ProfileSchema seeds and cleans the
-- saved bar with it, PlayerDataService prunes and validates with it, LoadoutUI
-- edits with it; HotbarSlotsSpec drives every function.
--
-- A SLOT IS A SHORTCUT TO SOMETHING OWNED, never a second copy. Ten slots
-- (1-9 and 0), each one string -- a REF -- or "" for empty:
--
--   i:<Item>    one plant or pod: profile.Held[n].Item, the Tool's ItemId
--   w:<id>      one owned bat or trap (a WeaponData id; one of each at most)
--   ticket      the Spin Ticket stack (owned while WheelEarned >= 1)
--   +bat        a FAINT slot waiting for the first bat -- and +trap, +ticket
--
-- Assigning moves nothing and copies nothing: an item on the bar is still in
-- the Bag, it is only drawn on the strip instead of in the grid.
--
-- THE RULE THAT KEEPS IT RACE-FREE. At runtime the server only REMOVES from the
-- bar and the favourites (prune) or accepts a validated edit from the client;
-- it never adds. Adding happens only at load (Default, seed, clean, fill) and on
-- the client, which places arrivals. Every arrival's row is written before its
-- Tool learns its ItemId, so an edit naming a new item is never refused.
--
-- FAVOURITES are a set of the same refs (never a placeholder). A favourite is
-- kept out of SELL ALL (EconomyService); SELL ONE, planting and sacrificing may
-- still use one up.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))

local HotbarSlots = {}

local INV = GameConfig.Inventory
HotbarSlots.Slots = INV.Slots
HotbarSlots.MaxRefLength = INV.MaxRefLength
HotbarSlots.Ticket = "ticket"
-- The three faint slots, by the category each waits for.
HotbarSlots.Placeholder = { bat = "+bat", trap = "+trap", ticket = "+ticket" }
-- What a Tool says about itself. Kept equal to GameConfig.Attributes.ItemId,
-- WeaponModel.ItemAttribute and WheelService's ticket marker (the spec checks).
HotbarSlots.ItemAttribute = GameConfig.Attributes.ItemId
HotbarSlots.WeaponAttribute = "WeaponId"
HotbarSlots.TicketAttribute = "SpinTicket"

export type Bar = { string }

local CATEGORY_OF_PLACEHOLDER: { [string]: string } = {}
for category, ref in pairs(HotbarSlots.Placeholder) do
	CATEGORY_OF_PLACEHOLDER[ref] = category
end
-- Shop order, for seeding and for a stable order of arrivals.
local WEAPON_ORDER: { [string]: number } = {}
for index, item in ipairs(WeaponData.Items) do
	WEAPON_ORDER[item.Id] = index
end

--==============================================================================
-- THE GRAMMAR
--==============================================================================
function HotbarSlots.item(id: string): string
	return "i:" .. id
end

function HotbarSlots.weapon(id: string): string
	return "w:" .. id
end

-- "item" | "weapon" | "ticket" | "placeholder", and the id after the prefix
-- (the category for a placeholder); nil for anything else.
function HotbarSlots.parse(ref: any): (string?, string?)
	if type(ref) ~= "string" or ref == "" or #ref > HotbarSlots.MaxRefLength then
		return nil, nil
	end
	if ref == HotbarSlots.Ticket then
		return "ticket", nil
	end
	local placeholder = CATEGORY_OF_PLACEHOLDER[ref]
	if placeholder then
		return "placeholder", placeholder
	end
	local prefix, rest = string.sub(ref, 1, 2), string.sub(ref, 3)
	if rest == "" then
		return nil, nil
	end
	if prefix == "i:" then
		return "item", rest
	elseif prefix == "w:" then
		return "weapon", rest
	end
	return nil, nil
end

function HotbarSlots.isPlaceholder(ref: any): boolean
	return type(ref) == "string" and CATEGORY_OF_PLACEHOLDER[ref] ~= nil
end

-- "bat" | "trap" | "ticket" | "item", for a ref or a placeholder; nil for junk
-- or a weapon id the shelf no longer knows.
function HotbarSlots.categoryOf(ref: any): string?
	local kind, id = HotbarSlots.parse(ref)
	if kind == "item" then
		return "item"
	elseif kind == "ticket" then
		return "ticket"
	elseif kind == "placeholder" then
		return id
	elseif kind == "weapon" then
		local item = WeaponData.Get(id)
		return if item then item.Category else nil
	end
	return nil
end

--==============================================================================
-- WHAT THE PROFILE OWNS
--
-- Every Held row's Item and every planted row's, every owned weapon the shelf still knows, and the
-- ticket stack while the earned balance is at least one (NaN-safe; not tied to
-- WheelData.Enabled, so switching the wheel off does not wipe a shortcut).
--==============================================================================
function HotbarSlots.owned(profile: any): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(profile) ~= "table" then
		return set
	end
	if type(profile.Held) == "table" then
		for _, row in ipairs(profile.Held) do
			if type(row) == "table" and type(row.Item) == "string" and row.Item ~= "" then
				set["i:" .. row.Item] = true
			end
		end
	end
	-- A grown creature IN THE GROUND is still owned (2026-10-04, MY PLANTS): its
	-- planted row carries its item id, so its shortcut and its heart wait for it
	-- while it earns, and are its own again when it comes back to the Bag.
	if type(profile.Plants) == "table" then
		for _, row in ipairs(profile.Plants) do
			if type(row) == "table" and type(row.Item) == "string" and row.Item ~= "" then
				set["i:" .. row.Item] = true
			end
		end
	end
	if type(profile.Weapons) == "table" then
		for id, on in pairs(profile.Weapons) do
			if on == true and type(id) == "string" and WeaponData.Get(id) then
				set["w:" .. id] = true
			end
		end
	end
	local earned = profile.WheelEarned
	if type(earned) == "number" and earned == earned and earned >= 1 then
		set[HotbarSlots.Ticket] = true
	end
	return set
end

function HotbarSlots.owns(profile: any, ref: any): boolean
	if type(ref) ~= "string" then
		return false
	end
	local kind, id = HotbarSlots.parse(ref)
	if kind == "item" then
		if type(profile) == "table" then
			for _, list in ipairs({ profile.Held, profile.Plants }) do
				if type(list) == "table" then
					for _, row in ipairs(list) do
						if type(row) == "table" and row.Item == id then
							return true
						end
					end
				end
			end
		end
		return false
	elseif kind == "weapon" or kind == "ticket" then
		return HotbarSlots.owned(profile)[ref] == true
	end
	return false
end

function HotbarSlots.empty(): Bar
	local bar = table.create(HotbarSlots.Slots, "")
	return bar
end

-- Any list, as exactly ten strings ("" where it held nothing usable). For the
-- client's drawing; it decides nothing about ownership.
function HotbarSlots.normalise(list: any): Bar
	local bar = HotbarSlots.empty()
	if type(list) == "table" then
		for i = 1, HotbarSlots.Slots do
			local ref = list[i]
			if type(ref) == "string" and #ref <= HotbarSlots.MaxRefLength and HotbarSlots.parse(ref) then
				bar[i] = ref
			end
		end
	end
	return bar
end

function HotbarSlots.same(a: { string }, b: { string }): boolean
	for i = 1, HotbarSlots.Slots do
		if (a[i] or "") ~= (b[i] or "") then
			return false
		end
	end
	return true
end

function HotbarSlots.placeholdersIn(bar: any): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(bar) == "table" then
		for i = 1, HotbarSlots.Slots do
			if HotbarSlots.isPlaceholder(bar[i]) then
				set[bar[i]] = true
			end
		end
	end
	return set
end

--==============================================================================
-- THE BAR AT LOAD
--
-- seed: the bar a profile without one starts with -- 1 bat, 2 trap, 3 Spin
-- Tickets, the rest empty. The equipped bat; else, for somebody who owns bats
-- but has none out, the LAST owned in shop order; else a faint +bat. The same
-- for traps; tickets while the balance holds one, else +ticket. seed(nil) is a
-- new player's: the three faint slots.
--==============================================================================
local function choose(profile: any, category: string, equipped: any): string
	if type(profile) ~= "table" or type(profile.Weapons) ~= "table" then
		return HotbarSlots.Placeholder[category]
	end
	if type(equipped) == "string" and profile.Weapons[equipped] == true then
		local item = WeaponData.Get(equipped)
		if item and item.Category == category then
			return "w:" .. equipped
		end
	end
	local best: string? = nil
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == category and profile.Weapons[item.Id] == true then
			best = item.Id
		end
	end
	return if best then "w:" .. best else HotbarSlots.Placeholder[category]
end

function HotbarSlots.seed(profile: any?): Bar
	local bar = HotbarSlots.empty()
	bar[1] = choose(profile, "bat", if profile then (profile :: any).EquippedBat else nil)
	bar[2] = choose(profile, "trap", if profile then (profile :: any).EquippedTrap else nil)
	bar[3] = if HotbarSlots.owned(profile)[HotbarSlots.Ticket] then HotbarSlots.Ticket else HotbarSlots.Placeholder.ticket
	return bar
end

--==============================================================================
-- clean: any saved or sent list, as ten strings the profile can stand behind.
-- Positions are kept, never compacted. A slot is emptied for: not a string,
-- longer than MaxRefLength, a grammar nothing knows, something not owned, or a
-- second copy of a ref already placed. A placeholder is kept once, and only if
-- `allowed` names it (nil allows all three -- a load; SetHotbar passes the ones
-- already on the bar, so a client may move or clear a faint slot but never
-- create one).
--==============================================================================
function HotbarSlots.clean(profile: any, list: any, allowed: { [string]: boolean }?): Bar
	local bar = HotbarSlots.empty()
	if type(list) ~= "table" then
		return bar
	end
	local owned = HotbarSlots.owned(profile)
	local used: { [string]: boolean } = {}
	for i = 1, HotbarSlots.Slots do
		local ref = list[i]
		if type(ref) == "string" and not used[ref] then
			local kind = HotbarSlots.parse(ref)
			if kind == "placeholder" then
				if allowed == nil or allowed[ref] then
					bar[i] = ref
					used[ref] = true
				end
			elseif kind and owned[ref] then
				bar[i] = ref
				used[ref] = true
			end
		end
	end
	return bar
end

--==============================================================================
-- fill (load only): a faint slot whose category the player owns but has nowhere
-- on the bar is given the item seed would have chosen. A bat bought on a client
-- that left before it could place it would otherwise wait behind a faint +bat
-- forever, since the next session's arrivals start from what is already owned.
--==============================================================================
function HotbarSlots.fill(profile: any, bar: Bar): Bar
	local out = table.clone(bar)
	local onBar: { [string]: boolean } = {}
	for i = 1, HotbarSlots.Slots do
		if out[i] ~= "" then
			onBar[out[i]] = true
		end
	end
	for i = 1, HotbarSlots.Slots do
		local kind, category = HotbarSlots.parse(out[i])
		if kind == "placeholder" and category then
			local want: string
			if category == "ticket" then
				want = if HotbarSlots.owned(profile)[HotbarSlots.Ticket] then HotbarSlots.Ticket else out[i]
			else
				local field = if category == "bat" then "EquippedBat" else "EquippedTrap"
				want = choose(profile, category, if type(profile) == "table" then profile[field] else nil)
			end
			-- Only when nothing of that category is placed already.
			local taken = false
			for ref in pairs(onBar) do
				if not HotbarSlots.isPlaceholder(ref) and HotbarSlots.categoryOf(ref) == category then
					taken = true
				end
			end
			if want ~= out[i] and not taken and not onBar[want] then
				onBar[out[i]] = nil
				out[i] = want
				onBar[want] = true
			end
		end
	end
	return out
end

--==============================================================================
-- FAVOURITES
--==============================================================================
function HotbarSlots.cleanFavourites(profile: any, raw: any): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(raw) ~= "table" then
		return set
	end
	local owned = HotbarSlots.owned(profile)
	for ref, on in pairs(raw) do
		if on == true and type(ref) == "string" and #ref <= HotbarSlots.MaxRefLength
			and not HotbarSlots.isPlaceholder(ref) and owned[ref] then
			set[ref] = true
		end
	end
	return set
end

-- Nil-safe: a stand-in profile without the field favourites nothing.
function HotbarSlots.isFavourite(profile: any, ref: string?): boolean
	if type(profile) ~= "table" or type(profile.Favourites) ~= "table" or type(ref) ~= "string" then
		return false
	end
	return profile.Favourites[ref] == true
end

--==============================================================================
-- prune: in place, after anything was taken away. A gone item's slot empties;
-- a spent ticket stack's slot turns faint again (+ticket, so the next ticket
-- comes back to the same place) unless a +ticket is already placed; a gone
-- favourite is forgotten. Placeholders are never touched. Answers whether
-- anything changed.
--==============================================================================
function HotbarSlots.prune(profile: any): boolean
	if type(profile) ~= "table" then
		return false
	end
	local owned = HotbarSlots.owned(profile)
	local changed = false
	if type(profile.Hotbar) == "table" then
		local bar = profile.Hotbar
		local faintTicket = HotbarSlots.placeholdersIn(bar)[HotbarSlots.Placeholder.ticket] == true
		for i = 1, HotbarSlots.Slots do
			local ref = bar[i]
			if type(ref) ~= "string" then
				bar[i] = ""
				changed = true
			elseif ref ~= "" and not HotbarSlots.isPlaceholder(ref) and not owned[ref] then
				if ref == HotbarSlots.Ticket and not faintTicket then
					bar[i] = HotbarSlots.Placeholder.ticket
					faintTicket = true
				else
					bar[i] = ""
				end
				changed = true
			end
		end
	end
	if type(profile.Favourites) == "table" then
		for ref in pairs(profile.Favourites) do
			if not owned[ref] then
				profile.Favourites[ref] = nil
				changed = true
			end
		end
	end
	return changed
end

--==============================================================================
-- THE CLIENT'S OPERATIONS. Each answers a NEW bar; none touches its argument.
-- `shown` is how many slots are on screen (10 on a desktop, 5 on a phone).
--==============================================================================
function HotbarSlots.slotOf(bar: { string }, ref: string?): number?
	if type(ref) ~= "string" or ref == "" then
		return nil
	end
	for i = 1, HotbarSlots.Slots do
		if bar[i] == ref then
			return i
		end
	end
	return nil
end

function HotbarSlots.firstEmpty(bar: { string }, shown: number): number?
	for i = 1, math.min(shown, HotbarSlots.Slots) do
		if (bar[i] or "") == "" then
			return i
		end
	end
	return nil
end

-- `ref` into `slot`. Already on the bar: the two slots swap. A placeholder in
-- the way is dropped; a real item in the way is DISPLACED -- answered, back to
-- the grid.
function HotbarSlots.assign(bar: { string }, ref: string, slot: number): (Bar, string?)
	local out = HotbarSlots.normalise(bar)
	if slot < 1 or slot > HotbarSlots.Slots then
		return out, nil
	end
	local from = HotbarSlots.slotOf(out, ref)
	if from == slot then
		return out, nil
	end
	local there = out[slot]
	if from then
		out[from] = there
		out[slot] = ref
		return out, nil
	end
	out[slot] = ref
	if there ~= "" and not HotbarSlots.isPlaceholder(there) then
		return out, there
	end
	return out, nil
end

function HotbarSlots.swap(bar: { string }, a: number, b: number): Bar
	local out = HotbarSlots.normalise(bar)
	if a >= 1 and a <= HotbarSlots.Slots and b >= 1 and b <= HotbarSlots.Slots then
		out[a], out[b] = out[b], out[a]
	end
	return out
end

function HotbarSlots.remove(bar: { string }, slot: number): Bar
	local out = HotbarSlots.normalise(bar)
	if slot >= 1 and slot <= HotbarSlots.Slots then
		out[slot] = ""
	end
	return out
end

--==============================================================================
-- planted: the refs of grown creatures IN THE GROUND and not in the Bag. Each
-- keeps its slot while it earns (MY PLANTS, 2026-10-04) -- but nothing of it is
-- drawn there, so the slot LOOKS empty. An arrival may take it (below).
--==============================================================================
function HotbarSlots.planted(profile: any): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(profile) ~= "table" or type(profile.Plants) ~= "table" then
		return set
	end
	local inBag: { [string]: boolean } = {}
	if type(profile.Held) == "table" then
		for _, row in ipairs(profile.Held) do
			if type(row) == "table" and type(row.Item) == "string" and row.Item ~= "" then
				inBag["i:" .. row.Item] = true
			end
		end
	end
	for _, row in ipairs(profile.Plants) do
		if type(row) == "table" and type(row.Item) == "string" and row.Item ~= "" then
			local ref = "i:" .. row.Item
			if not inBag[ref] then
				set[ref] = true
			end
		end
	end
	return set
end

-- Where an ARRIVAL goes: nowhere new if it is already placed; else its own
-- category's faint slot, wherever that is (a bat replaces +bat, even in a
-- slot a phone does not show); else the first empty shown slot; else the first
-- shown slot a PLANTED creature keeps (`planted`, HotbarSlots.planted); else,
-- for a plant or a pod, the plant slots SLIDE; else the grid (nil, and the bar
-- unchanged). The third answer is the ref pushed off the bar, if one was.
--
-- THE PLANTED SLOT GIVES WAY (the owner's call, 2026-10-08, option A): on a
-- phone only slots 4 and 5 hold plants, and two creatures planted from there
-- sent every pod stolen after them to the Bag past two slots that looked
-- empty. The planted creature loses only its shortcut.
--
-- A PLANT ALWAYS LANDS ON THE BAR (the owner, 2026-10-08): a banked pod, and a
-- creature picked up out of the garden (HotbarSlots.pickedUp), go to the bar
-- and the old ones go to the Bag. With every shown slot taken, the shown slots
-- holding plants or pods slide: the LEFT-MOST (the oldest -- the bar fills
-- left to right) leaves for the Bag, every other one moves one plant slot to
-- the left, and the newcomer takes the right-most. Hearts are not spared (the
-- owner's call). A bat, a trap or the tickets never move and are never pushed
-- off, and a weapon that finds no room still goes to the grid. Only with
-- `slide`: an arrival from the profile slides the bar, a Bag tile pressed to
-- hold does not (browsing the Bag never reshuffles the bar).
function HotbarSlots.arrive(bar: { string }, ref: string, shown: number,
	planted: { [string]: boolean }?, slide: boolean?): (Bar, number?, string?)
	local out = HotbarSlots.normalise(bar)
	if HotbarSlots.slotOf(out, ref) then
		return out, nil, nil
	end
	local category = HotbarSlots.categoryOf(ref)
	local faint = if category then HotbarSlots.Placeholder[category] else nil
	local at = if faint then HotbarSlots.slotOf(out, faint) else nil
	if not at then
		at = HotbarSlots.firstEmpty(out, shown)
	end
	if not at and planted then
		for i = 1, math.min(shown, HotbarSlots.Slots) do
			if planted[out[i]] then
				local pushed = out[i]
				out[i] = ref
				return out, i, pushed
			end
		end
	end
	if not at and slide and category == "item" then
		local slots: { number } = {}
		for i = 1, math.min(shown, HotbarSlots.Slots) do
			if HotbarSlots.categoryOf(out[i]) == "item" then
				table.insert(slots, i)
			end
		end
		if #slots > 0 then
			local pushed = out[slots[1]]
			for n = 1, #slots - 1 do
				out[slots[n]] = out[slots[n + 1]]
			end
			at = slots[#slots]
			out[at] = ref
			return out, at, pushed
		end
	end
	if not at then
		return out, nil, nil
	end
	out[at] = ref
	return out, at, nil
end

--==============================================================================
-- pickedUp: the creatures that were in the ground in the last packet and are
-- back in the Bag now -- owned still, planted no longer -- in a stable order.
-- Each is an arrival like a banked pod (HotbarSlots.arrive): one that kept its
-- slot while it earned stays where it is.
--==============================================================================
function HotbarSlots.pickedUp(wasPlanted: { [string]: boolean }?, nowPlanted: { [string]: boolean },
	owned: { [string]: boolean }): { string }
	local list: { string } = {}
	if not wasPlanted then
		return list
	end
	for ref in pairs(wasPlanted) do
		if owned[ref] and not nowPlanted[ref] then
			table.insert(list, ref)
		end
	end
	table.sort(list, HotbarSlots.before)
	return list
end

--==============================================================================
-- ARRIVALS: what is owned now and was not before, in a stable order --
-- weapons in shop order, the ticket, then items by their id's number.
--==============================================================================
local function rank(ref: string): (number, number, string)
	local kind, id = HotbarSlots.parse(ref)
	if kind == "weapon" then
		return 1, WEAPON_ORDER[id or ""] or 999, ref
	elseif kind == "ticket" then
		return 2, 0, ref
	end
	return 3, tonumber(id) or math.huge, ref
end

function HotbarSlots.before(a: string, b: string): boolean
	local ka, na, sa = rank(a)
	local kb, nb, sb = rank(b)
	if ka ~= kb then
		return ka < kb
	elseif na ~= nb then
		return na < nb
	end
	return sa < sb
end

function HotbarSlots.arrivals(before: { [string]: boolean }, now: { [string]: boolean }): { string }
	local list: { string } = {}
	for ref in pairs(now) do
		if not before[ref] then
			table.insert(list, ref)
		end
	end
	table.sort(list, HotbarSlots.before)
	return list
end

-- The ref a Tool stands for, from what the server stamped on it; nil for a
-- Tool that has not learned its id yet (it can be held, not assigned).
function HotbarSlots.refOfTool(tool: any): string?
	if tool == nil then
		return nil
	end
	local ok, item, weapon, ticket = pcall(function()
		return tool:GetAttribute(HotbarSlots.ItemAttribute), tool:GetAttribute(HotbarSlots.WeaponAttribute),
			tool:GetAttribute(HotbarSlots.TicketAttribute)
	end)
	if not ok then
		return nil
	end
	if type(item) == "string" and item ~= "" and #item <= HotbarSlots.MaxRefLength - 2 then
		return "i:" .. item
	elseif type(weapon) == "string" and weapon ~= "" and WeaponData.Get(weapon) then
		return "w:" .. weapon
	elseif ticket == true then
		return HotbarSlots.Ticket
	end
	return nil
end

--==============================================================================
-- THE BAG CELL'S STORAGE COUNT (moved from HotbarRoles)
--
-- profile.Held's rows, plus one while a pod is carried home -- it takes a place
-- too (CarryService.HeldRoom). Tickets, bats and traps have no row and never
-- count. Before the profile has arrived there is no number to show, and a "0"
-- would be a lie. A carried pod is said ("23+1/24"), so a Bag that lists 23 is
-- not a mystery when the count is full. Answers the text, full, known.
--==============================================================================
function HotbarSlots.storage(rows: number?, carrying: boolean, limit: number): (string, boolean, boolean)
	if rows == nil then
		return "…", false, false
	end
	local stored = math.max(0, math.floor(rows))
	local count = stored + (if carrying then 1 else 0)
	local text = if carrying then string.format("%d+1/%d", stored, limit) else string.format("%d/%d", count, limit)
	return text, count >= limit, true
end

return HotbarSlots
