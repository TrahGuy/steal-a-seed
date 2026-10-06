--!strict
-- Steal a Seed :: BoostIcons (2026-10-04)
--
-- Which boosts and events are running for this player right now, and what each
-- one's icon and popover say -- the pure half of BoostIconsUI. Everything comes
-- in as a Snapshot of the server's own attributes (BoostIcons.read builds one
-- off the live instances); nothing here reads a clock, touches an instance it
-- was not handed or changes a modifier. Times are workspace:GetServerTimeNow()
-- seconds; the Bonus Chest's and the pedestal's deadlines are the server's
-- os.time(), which is the same clock to the second.
--
-- See GameConfig.BoostIcons for the row, the order and the words.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local CFG = GameConfig.BoostIcons
local WORDS = CFG.Words

local BoostIcons = {}

export type Snapshot = {
	now: number,
	rainState: string?,
	rainMode: string?,
	rainStartedAt: number?,
	rainEndsAt: number?,
	miniState: string?,
	miniMode: string?,
	miniStartedAt: number?,
	miniEndsAt: number?,
	miniCap: number?,
	tickets: number?,
	chestBoost: string?,
	chestEndsAt: number?,
	sacrificeMultiplier: number?,
	sacrificeEndsAt: number?,
}

export type Entry = {
	id: string,
	-- The SourceIcons key whose picture it wears; "" or a missing id draws the
	-- glyph instead.
	source: string,
	glyph: string,
	tint: Color3,
	-- The popover's lines: where it comes from, what it does, what to do (or,
	-- on the tickets, how many of the limit are taken).
	title: string,
	effect: string,
	hint: string?,
	-- A few characters on the icon itself (the ticket count), or nil.
	badge: string?,
	endsAt: number,
	-- The whole run, for the ring; 0 when it cannot be known.
	total: number,
}

local function num(value: any): number?
	return if type(value) == "number" and value == value then value else nil
end

local function str(value: any): string?
	return if type(value) == "string" and value ~= "" then value else nil
end

-- The live attributes, as a Snapshot. Client only (the one impure function).
function BoostIcons.read(player: Player, workspace: Workspace, now: number): Snapshot
	local W = GameConfig.Weather.Attributes
	local M = GameConfig.MiniEvent.Attributes
	local C = GameConfig.BonusChest.Attributes
	local S = GameConfig.Sacrifice.Attributes
	return {
		now = now,
		rainState = str(workspace:GetAttribute(W.State)),
		rainMode = str(workspace:GetAttribute(W.Mode)),
		rainStartedAt = num(workspace:GetAttribute(W.StartedAt)),
		rainEndsAt = num(workspace:GetAttribute(W.EndsAt)),
		miniState = str(workspace:GetAttribute(M.State)),
		miniMode = str(workspace:GetAttribute(M.Mode)),
		miniStartedAt = num(workspace:GetAttribute(M.StartedAt)),
		miniEndsAt = num(workspace:GetAttribute(M.EndsAt)),
		miniCap = num(workspace:GetAttribute(M.Cap)),
		tickets = num(player:GetAttribute(M.PlayerTickets)),
		chestBoost = str(player:GetAttribute(C.Boost)),
		chestEndsAt = num(player:GetAttribute(C.EndsAt)),
		sacrificeMultiplier = num(player:GetAttribute(S.Multiplier)),
		sacrificeEndsAt = num(player:GetAttribute(S.EndsAt)),
	}
end

-- Every attribute BoostIcons.read looks at, so the UI can redraw on a change
-- rather than wait for its next second: (instance kind, name).
function BoostIcons.watched(): { { on: string, name: string } }
	local list = {}
	for _, name in pairs(GameConfig.Weather.Attributes) do
		table.insert(list, { on = "workspace", name = name })
	end
	for key, name in pairs(GameConfig.MiniEvent.Attributes) do
		table.insert(list, { on = if key == "PlayerTickets" then "player" else "workspace", name = name })
	end
	for _, name in pairs(GameConfig.BonusChest.Attributes) do
		table.insert(list, { on = "player", name = name })
	end
	for _, name in pairs(GameConfig.Sacrifice.Attributes) do
		table.insert(list, { on = "player", name = name })
	end
	return list
end

local function percent(multiplier: number): number
	return math.floor((multiplier - 1) * 100 + 0.5)
end

local function span(startedAt: number?, endsAt: number): number
	return if startedAt and endsAt > startedAt then endsAt - startedAt else 0
end

-- What is running, in GameConfig.BoostIcons.Order.
function BoostIcons.entries(s: Snapshot): { Entry }
	local now = s.now
	local found: { [string]: Entry } = {}

	-- THE WEATHER: one icon for the Rain or the Thunderstorm while it pays
	-- (WeatherUI's old rule: "opening" or "active"; "closing" pays nothing).
	local rainEnds = s.rainEndsAt
	if (s.rainState == "opening" or s.rainState == "active") and rainEnds and rainEnds > now then
		local thunder = s.rainMode == "thunder"
		found.weather = {
			id = "weather",
			source = if thunder then "thunder" else "rain",
			glyph = "boost",
			tint = CFG.Tints.weather,
			title = if thunder then WORDS.Thunder else WORDS.Rain,
			effect = string.format(WORDS.WeatherEffect, percent(SeedData.Rain.IncomeFactor)),
			hint = if s.rainState == "active" then WORDS.WeatherOpen else WORDS.WeatherOpening,
			endsAt = rainEnds,
			total = span(s.rainStartedAt, rainEnds),
		}
	end

	-- THE MINI EVENT: its disco and its tickets, each its own icon, while it
	-- runs ("ending" is the fade, and nothing runs then).
	local modes: { [string]: any } = GameConfig.MiniEvent.Modes :: any
	local mode = if s.miniMode then modes[s.miniMode] else nil
	local miniEnds = s.miniEndsAt
	if s.miniState == "running" and mode and miniEnds and miniEnds > now then
		local total = span(s.miniStartedAt, miniEnds)
		-- The disco's icon says what THIS mode gives: the Disco Mill's x10 where a
		-- mill stands (Ticket Disco, DISCO + MILL), the movement boost for the
		-- pure DISCO ONLY (2026-10-04) -- never the x10 without a mill.
		local speed = tonumber(mode.SpeedFactor)
		if mode.Disco and mode.Mill then
			found.disco = {
				id = "disco",
				source = "disco",
				glyph = "boost",
				tint = CFG.Tints.disco,
				title = WORDS.Disco,
				effect = WORDS.DiscoEffect,
				hint = WORDS.DiscoHint,
				endsAt = miniEnds,
				total = total,
			}
		elseif mode.Disco then
			found.disco = {
				id = "disco",
				source = "disco",
				glyph = "boost",
				tint = CFG.Tints.disco,
				title = WORDS.Party,
				effect = if speed and speed > 1 then string.format(WORDS.PartyEffect, percent(speed)) else WORDS.Party,
				hint = nil,
				endsAt = miniEnds,
				total = total,
			}
		end
		if mode.Tickets then
			local cap = math.max(1, math.floor(s.miniCap or GameConfig.MiniEvent.Tickets.PerPlayerCap))
			local count = math.clamp(math.floor(s.tickets or 0), 0, cap)
			found.tickets = {
				id = "tickets",
				source = "tickets",
				glyph = "boost",
				tint = CFG.Tints.tickets,
				title = WORDS.Tickets,
				effect = WORDS.TicketsEffect,
				hint = if count >= cap then string.format(WORDS.TicketsCapped, cap)
					else string.format(WORDS.TicketsProgress, count, cap),
				badge = string.format("%d/%d", count, cap),
				endsAt = miniEnds,
				total = total,
			}
		end
	end

	-- THE CHEST'S (OR THE WHEEL'S) BOOST: one slot, income or training.
	local reward = GameConfig.bonusChestReward(s.chestBoost)
	local chestEnds = s.chestEndsAt
	if reward and chestEnds and chestEnds > now then
		local id = reward.Id
		if id == "income" or id == "training" then
			found[id] = {
				id = id,
				source = id,
				glyph = "boost",
				tint = CFG.Tints[id],
				title = WORDS.Boost,
				effect = string.format(if id == "income" then WORDS.IncomeEffect else WORDS.TrainingEffect,
					percent(reward.Multiplier)),
				hint = WORDS.BoostHint,
				endsAt = chestEnds,
				total = GameConfig.BonusChest.BoostSeconds,
			}
		end
	end

	-- THE PEDESTAL'S.
	local mult = s.sacrificeMultiplier
	local sacrificeEnds = s.sacrificeEndsAt
	if GameConfig.Sacrifice.Enabled and mult and mult > 1 and sacrificeEnds and sacrificeEnds > now then
		found.sacrifice = {
			id = "sacrifice",
			source = "sacrifice",
			glyph = "boost",
			tint = CFG.Tints.sacrifice,
			title = WORDS.Sacrifice,
			effect = string.format(WORDS.SacrificeEffect, percent(mult)),
			hint = WORDS.SacrificeHint,
			endsAt = sacrificeEnds,
			total = SeedData.Sacrifice.DurationSeconds,
		}
	end

	local out: { Entry } = {}
	for _, id in ipairs(CFG.Order) do
		local e = found[id]
		if e then
			table.insert(out, e)
		end
	end
	return out
end

-- The time left on a clock: m:ss, or h:mm:ss past an hour.
function BoostIcons.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

function BoostIcons.timeLine(e: Entry, now: number): string
	return string.format(WORDS.EndsIn, BoostIcons.clock(e.endsAt - now))
end

-- How much of the ring is left, 0..1 (1 when the whole run is unknown).
function BoostIcons.fraction(e: Entry, now: number): number
	if e.total <= 0 then
		return 1
	end
	return math.clamp((e.endsAt - now) / e.total, 0, 1)
end

-- The ids in order, joined: what the row is, as one comparable string.
function BoostIcons.key(list: { Entry }): string
	local ids = {}
	for i, e in ipairs(list) do
		ids[i] = e.id
	end
	return table.concat(ids, ",")
end

--==============================================================================
-- THE TWO HALVES OF THE RING
--
-- A ring empties clockwise from twelve o'clock as two clipped halves of one
-- circle, each with a hard-edged gradient turned to the angle left: the right
-- half covers 0..180 degrees, the left 180..360. Returns the two gradients'
-- rotations for `fraction` of the ring still showing.
--==============================================================================
function BoostIcons.ringRotations(fraction: number): (number, number)
	local degrees = math.clamp(fraction, 0, 1) * 360
	return math.clamp(degrees, 0, 180), math.clamp(degrees, 180, 360)
end

--==============================================================================
-- STEPPING THROUGH THE ROW WITH A CONTROLLER
--
-- The PadKey opens the first icon's popover, then each next one; past the
-- last it closes (nil). Left and right step either way and wrap.
--==============================================================================
function BoostIcons.nextOpen(ids: { string }, current: string?, step: number, wrap: boolean): string?
	local n = #ids
	if n == 0 then
		return nil
	end
	local at: number? = nil
	if current then
		for i, id in ipairs(ids) do
			if id == current then
				at = i
				break
			end
		end
	end
	if not at then
		return if step >= 0 then ids[1] else ids[n]
	end
	local nextAt = at + (if step >= 0 then 1 else -1)
	if nextAt < 1 or nextAt > n then
		if not wrap then
			return nil
		end
		nextAt = ((nextAt - 1) % n) + 1
	end
	return ids[nextAt]
end

return BoostIcons
