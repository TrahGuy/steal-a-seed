--!strict
--==============================================================================
-- Steal a Seed :: HotbarRoles (2026-10-01, the owner's hotbar rework)
--
-- WHAT EACH HOTBAR SLOT MEANS, and the two plant shortcuts' memory. Pure: no
-- Instances, no services, no clock of its own. LoadoutUI owns the strip and
-- calls these; HotbarSpec drives them with stand-in Tools.
--
-- THE SLOTS ARE ROLES, NOT A LIST. A key always means the same thing:
--
--   1  the equipped bat         3  the Spin Tickets, one stacked slot
--   2  the equipped trap        4  the ACTIVE plant or pod
--                               5  the PREVIOUS plant or pod (desktop only)
--
-- so nothing ever renumbers or slides under a thumb: an empty role is an
-- empty slot, drawn faint, in its place.
--
-- THE TWO SHORTCUTS ARE POINTERS INTO THE BAG, never a second inventory. Every
-- stored plant and pod stays in the Bag; `active` and `previous` only say which
-- two the keys reach. Choosing a plant in the Bag makes it the active one and
-- moves the old active to previous. Nothing is moved, sold, cloned or dropped.
--
-- A SHORTCUT IS A TOOL *AND* A KEY (the hotbar's older lesson, kept): the Tool
-- is the exact copy -- two identical Nubkins are two items, and a shortcut
-- names one -- and the key (`p:<species>:<tier>:<hatched>`) is what to look
-- for when the copy dies, because a respawn destroys and rebuilds every Tool.
-- A lost copy is re-leased by key within Grace seconds; after that it is gone.
--
-- ARRIVALS NEVER TAKE A CHOSEN SHORTCUT. A new plant fills the active slot
-- only while that slot is empty (and not waiting out a grace). The previous
-- slot is only ever filled by a choice.
--==============================================================================
local HotbarRoles = {}

HotbarRoles.Roles = { "bat", "trap", "ticket", "active", "previous" }
-- Seconds a lost copy's key is kept before the shortcut is let go: a respawn
-- rebuilds the Tools in about a second; a sold plant never comes back.
HotbarRoles.Grace = 5.0

export type Shortcut = {
	key: string,
	tool: any?,
	-- When the copy went missing, if it has.
	lostAt: number?,
}
export type State = {
	active: Shortcut?,
	previous: Shortcut?,
}
-- What the strip knows about one owned Tool: LoadoutUI's Slot, reduced.
export type Live = {
	tool: any,
	key: string,
	kind: string,
	-- The order the Tool was first seen in: the newest has the largest.
	order: number,
}

local NAMES = { "active", "previous" }

function HotbarRoles.roleOf(index: number): string?
	return HotbarRoles.Roles[index]
end

--==============================================================================
-- RECONCILE, ONCE PER REDRAW
--
-- Against the Tools that exist right now. Returns whether a shortcut is still
-- waiting out its grace, so the caller can look again when it is over.
--==============================================================================
function HotbarRoles.reconcile(state: State, live: { Live }, now: number): boolean
	local byTool: { [any]: Live } = {}
	for _, entry in ipairs(live) do
		byTool[entry.tool] = entry
	end
	local used: { [any]: boolean } = {}
	local waiting = false

	-- Pass 1: the exact copy, if it is still owned and still a plant.
	for _, name in ipairs(NAMES) do
		local shortcut = (state :: any)[name] :: Shortcut?
		if shortcut then
			local tool = shortcut.tool
			local entry = if tool then byTool[tool] else nil
			if entry and entry.kind == "plant" and not used[tool] then
				used[tool] = true
				shortcut.lostAt = nil
			else
				shortcut.tool = nil
				shortcut.lostAt = shortcut.lostAt or now
			end
		end
	end

	-- Pass 2: re-lease by key, or run the grace down.
	for _, name in ipairs(NAMES) do
		local shortcut = (state :: any)[name] :: Shortcut?
		if shortcut and not shortcut.tool then
			for _, entry in ipairs(live) do
				if entry.kind == "plant" and entry.key == shortcut.key and not used[entry.tool] then
					used[entry.tool] = true
					shortcut.tool = entry.tool
					shortcut.lostAt = nil
					break
				end
			end
			if not shortcut.tool then
				if now - (shortcut.lostAt or now) >= HotbarRoles.Grace then
					(state :: any)[name] = nil
				else
					waiting = true
				end
			end
		end
	end

	-- The same copy can never stand in both: `used` already stops that, but a
	-- caller that set both by hand gets the same answer.
	local active, previous = state.active, state.previous
	if active and previous and active.tool ~= nil and active.tool == previous.tool then
		state.previous = nil
	end

	--==========================================================================
	-- AN EMPTY ACTIVE SLOT TAKES THE NEWEST PLANT
	--
	-- Only when nothing is chosen and nothing is waiting: a chosen shortcut is
	-- never replaced by an arrival. With no other plant left, the previous one
	-- steps up rather than leave key 4 empty beside a full key 5.
	--==========================================================================
	if state.active == nil then
		local newest: Live? = nil
		for _, entry in ipairs(live) do
			if entry.kind == "plant" and not used[entry.tool]
				and (newest == nil or entry.order > newest.order) then
				newest = entry
			end
		end
		if newest then
			state.active = { key = newest.key, tool = newest.tool }
		elseif state.previous and state.previous.tool then
			state.active = state.previous
			state.previous = nil
		end
	end
	return waiting
end

--==============================================================================
-- CHOOSING
--==============================================================================
-- A plant picked in the Bag: it becomes the active one; the old active becomes
-- the previous. Picking the previous one swaps the two.
function HotbarRoles.choose(state: State, key: string, tool: any)
	local active, previous = state.active, state.previous
	if active and active.tool == tool then
		return
	end
	if previous and previous.tool == tool then
		state.active, state.previous = previous, active
		return
	end
	if active and active.tool then
		state.previous = { key = active.key, tool = active.tool }
	end
	state.active = { key = key, tool = tool }
end

-- A plant dropped on the previous slot.
function HotbarRoles.setPrevious(state: State, key: string, tool: any)
	local active = state.active
	if active and active.tool == tool then
		state.active, state.previous = state.previous, active
		if state.active == nil then
			state.active = active
			state.previous = nil
		end
		return
	end
	state.previous = { key = key, tool = tool }
end

function HotbarRoles.swap(state: State)
	if state.active and state.previous then
		state.active, state.previous = state.previous, state.active
	end
end

function HotbarRoles.clear(state: State, name: string)
	if name == "active" then
		state.active = nil
	elseif name == "previous" then
		state.previous = nil
	end
end

-- What slot `index` shows: the live entry of its role, or nil for an empty slot.
function HotbarRoles.entryFor(state: State, live: { Live }, index: number): Live?
	local role = HotbarRoles.Roles[index]
	if role == nil then
		return nil
	end
	if role == "active" or role == "previous" then
		local shortcut = (state :: any)[role] :: Shortcut?
		local tool = if shortcut then shortcut.tool else nil
		if tool == nil then
			return nil
		end
		for _, entry in ipairs(live) do
			if entry.tool == tool then
				return entry
			end
		end
		return nil
	end
	for _, entry in ipairs(live) do
		if entry.kind == role then
			return entry
		end
	end
	return nil
end

-- The shortcut, if any, holding this exact Tool: "active", "previous" or nil.
function HotbarRoles.holding(state: State, tool: any): string?
	for _, name in ipairs(NAMES) do
		local shortcut = (state :: any)[name] :: Shortcut?
		if shortcut and shortcut.tool == tool then
			return name
		end
	end
	return nil
end

--==============================================================================
-- THE BAG'S COUNTER: PLANT STORAGE, AS THE SERVER COUNTS IT
--
-- `profile.Held` has one row per stored plant or pod, and a carried raid pod
-- takes a place too (CarryService.HeldRoom). Tickets, bats and traps have no
-- row and never count. Before the profile has arrived there is no number to
-- show, and a "0" would be a lie.
--==============================================================================
function HotbarRoles.storage(rows: number?, carrying: boolean, limit: number): (string, boolean, boolean)
	if rows == nil then
		return "…", false, false
	end
	local count = math.max(0, math.floor(rows)) + (if carrying then 1 else 0)
	return string.format("%d/%d", count, limit), count >= limit, true
end

return HotbarRoles
