--!strict
--==============================================================================
-- Steal a Seed :: UpdateLog (2026-10-05, the owner's WHAT'S NEW)
--
-- THE GAME'S RECENT CHANGES, IN THE WORDS PLAYERS READ IN THE WHAT'S NEW PANEL.
--
--   OWNER: EDIT THE LIST BELOW. Add a new entry at the TOP for a publish; the
--   oldest fall off the panel by themselves (it shows GameConfig.UpdateLog.Shown).
--   Each entry is:
--     id       unique and never reused -- e.g. the date and a word
--     date     as a player reads it: "5 Oct 2026" (day, short month, year)
--     title    short (GameConfig.UpdateLog.TitleMax characters at most)
--     bullets  2 to 5 lines in plain player language, one line each
--              (GameConfig.UpdateLog.BulletMax characters at most)
--   Write only what is in the game: no number that cannot be checked, no
--   promise of something to come. UpdateLogSpec checks every rule here.
--
-- No remote and no server: the words ship with a publish, like any config.
--
-- THE LIST BELOW IS A DRAFT (2026-10-05) written from KB/HANDOFF.md's record of
-- what the last publishes carried -- the owner rewrites or approves it before
-- it is published.
--
-- Pure helpers, for UpdateLogUI and UpdateLogSpec:
--   dayOf(date)     a date's UTC midnight in seconds, or nil if unreadable
--   shown()         the newest entries the panel shows, newest first
--   isNew(now)      whether the newest entry is under NewDays old: the dot
--   problems()      every rule the list breaks (an empty list when it is fine)
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local UpdateLog = {}

local C = GameConfig.UpdateLog

export type Entry = {
	id: string,
	date: string,
	title: string,
	bullets: { string },
}

--==============================================================================
-- THE ENTRIES, NEWEST FIRST (DRAFT -- the owner approves the wording)
--==============================================================================
UpdateLog.Entries = {
	{
		id = "2026-10-05-top-creatures",
		date = "5 Oct 2026",
		title = "Top creatures on every plot",
		bullets = {
			"Every plot has a TOP CREATURES board beside its upgrade sign.",
			"It shows the owner's two best creatures and what they earn.",
			"Everyone can see every plot's board.",
		},
	},
	{
		id = "2026-10-04-new-look",
		date = "4 Oct 2026",
		title = "A fresh new look",
		bullets = {
			"Menus have a fresh look with white studded headers.",
			"Walk Mode is now a simple ON/OFF switch.",
			"The day and night clock shows a moon or a sun.",
			"Shop, MY PLANTS and Bag cards are colourful and studded.",
		},
	},
} :: { Entry }

--==============================================================================
-- DATES
--==============================================================================
local MONTHS: { [string]: number } = {
	jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6,
	jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12,
}

local function isLeap(y: number): boolean
	return (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0
end

local DAYS_IN = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- Days from 1970-01-01 to the given day (proleptic Gregorian, no time zone).
local function daysFromEpoch(y: number, m: number, d: number): number
	local days = 0
	if y >= 1970 then
		for year = 1970, y - 1 do
			days += if isLeap(year) then 366 else 365
		end
	else
		for year = y, 1969 do
			days -= if isLeap(year) then 366 else 365
		end
	end
	for month = 1, m - 1 do
		days += DAYS_IN[month] + (if month == 2 and isLeap(y) then 1 else 0)
	end
	return days + d - 1
end

-- "5 Oct 2026" as that day's UTC midnight, in seconds; nil for anything else.
function UpdateLog.dayOf(date: any): number?
	if type(date) ~= "string" then
		return nil
	end
	local d, mon, y = string.match(date, "^(%d%d?) (%a%a%a) (%d%d%d%d)$")
	if not (d and mon and y) then
		return nil
	end
	local m = MONTHS[string.lower(mon)]
	local day, year = tonumber(d) :: number, tonumber(y) :: number
	if not m or day < 1 then
		return nil
	end
	local most = DAYS_IN[m] + (if m == 2 and isLeap(year) then 1 else 0)
	if day > most then
		return nil
	end
	return daysFromEpoch(year, m, day) * 86400
end

--==============================================================================
-- WHAT THE PANEL SHOWS, AND THE DOT
--==============================================================================
-- The newest `GameConfig.UpdateLog.Shown` entries, newest first, of `list`
-- (UpdateLog.Entries unless a spec hands its own).
function UpdateLog.shown(list: { Entry }?): { Entry }
	local all = list or UpdateLog.Entries
	local out: { Entry } = {}
	for i = 1, math.min(C.Shown, #all) do
		table.insert(out, all[i])
	end
	return out
end

-- Whether the newest entry is under NewDays old at `now` (server time, s):
-- the button's NEW dot. A date that cannot be read is never new.
function UpdateLog.isNew(now: number, list: { Entry }?): boolean
	local all = list or UpdateLog.Entries
	local newest = all[1]
	local at = if newest then UpdateLog.dayOf(newest.date) else nil
	if not at or now ~= now then
		return false
	end
	return now - (at :: number) < C.NewDays * 86400
end

--==============================================================================
-- THE RULES, CHECKED (UpdateLogSpec; and at load, loudly, in Studio)
--==============================================================================
function UpdateLog.problems(list: { Entry }?): { string }
	local all = list or UpdateLog.Entries
	local out: { string } = {}
	local seen: { [string]: boolean } = {}
	local previous: number? = nil
	for i, e in ipairs(all) do
		local where = string.format("entry %d (%s)", i, tostring(e.id))
		if type(e.id) ~= "string" or e.id == "" then
			table.insert(out, where .. ": no id")
		elseif seen[e.id] then
			table.insert(out, where .. ": the id is used twice")
		else
			seen[e.id] = true
		end
		local at = UpdateLog.dayOf(e.date)
		if not at then
			table.insert(out, where .. ": the date is not like \"5 Oct 2026\"")
		elseif previous and (at :: number) > previous then
			table.insert(out, where .. ": newer than the entry above it (newest first)")
		end
		previous = at or previous
		if type(e.title) ~= "string" or e.title == "" then
			table.insert(out, where .. ": no title")
		elseif utf8.len(e.title) and (utf8.len(e.title) :: number) > C.TitleMax then
			table.insert(out, string.format("%s: the title is over %d characters", where, C.TitleMax))
		end
		local bullets = e.bullets
		if type(bullets) ~= "table" or #bullets < C.MinBullets or #bullets > C.MaxBullets then
			table.insert(out, string.format("%s: needs %d to %d bullets", where, C.MinBullets, C.MaxBullets))
		else
			for b, line in ipairs(bullets) do
				if type(line) ~= "string" or line == "" then
					table.insert(out, string.format("%s: bullet %d is empty", where, b))
				elseif string.find(line, "\n", 1, true) then
					table.insert(out, string.format("%s: bullet %d is more than one line", where, b))
				elseif (utf8.len(line) or #line) > C.BulletMax then
					table.insert(out, string.format("%s: bullet %d is over %d characters", where, b, C.BulletMax))
				end
			end
		end
	end
	if #all == 0 then
		table.insert(out, "the list is empty")
	end
	return out
end

return UpdateLog
