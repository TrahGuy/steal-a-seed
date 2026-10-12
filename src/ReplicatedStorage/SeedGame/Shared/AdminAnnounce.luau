--!strict
--==============================================================================
-- Steal a Seed :: AdminAnnounce (2026-10-12, the owner's item 10)
--
-- WHAT AN ADMIN'S CONSOLE ACTION SAYS TO EVERYBODY, in the owner's style --
-- "nicnicniccoal summoned a Thunderstorm!", "nicnicniccoal gave PlayerX a
-- Colossal Snarlbloom pod!". Pure: AdminService (and, for a GLOBAL mini event,
-- MiniEventService in every server the event reaches) hands in the names and
-- what was done, once it really happened, and gets the line and its fold key.
--
-- NEVER FOR ANYTHING NATURAL. The weather lottery, a Pod Rush's own news, the
-- Mist's schedule, nightfall, nest stock and Robux purchases keep their own
-- notices and never come here. A progress reset says nothing (it would shame a
-- player), and an announcement is already one.
--
-- NAMES ARE DISPLAY NAMES, as in every other line the game says to everybody
-- (a rebirth's, SERVER LUCK's). ONE FOLD KEY per admin, action and player, so
-- a burst of gives folds into one line that counts up (FoldSeconds).
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

local CFG = GameConfig.AdminAnnounce

local AdminAnnounce = {}

-- A Player's (or a stand-in's) display name; its username where it has none.
function AdminAnnounce.nameOf(player: any): string
	local ok, shown = pcall(function()
		return player.DisplayName
	end)
	if ok and type(shown) == "string" and shown ~= "" then
		return shown
	end
	local okName, name = pcall(function()
		return player.Name
	end)
	return if okName and type(name) == "string" and name ~= "" then name else CFG.Words.Somebody
end

-- "$1M"; "500K Speed".
function AdminAnnounce.money(n: number): string
	return "$" .. GameConfig.compact(n)
end

function AdminAnnounce.speed(n: number): string
	return GameConfig.compact(n) .. " Speed"
end

-- What was done:
--   rain, thunder               the weather started (WeatherService)
--   weatherend (+ thunder)      the weather ended, the Thunderstorm or the Rain
--   miststart, mistend          an Enchanted Mist started or ended
--   night, day                  the cycle turned
--   mini, miniend (+ mode)      a GLOBAL mini event started or ended
--   spawn (+ words)             a give: SpawnCatalog's words, "5 Giant Petalpip pods"
--   money, speed (+ amount)     a give of cash or Speed
-- THE MIST'S TOOLS (2026-10-12, the owner's item 12):
--   dewberries (+ amount)       Dewberries given: a raise, never a lowering
--                               (AdminService says nothing for one), never 0
--   progress (+ amount)         a player's Dewberry progress set; never 0 (the
--                               owner: a reset to 0 says nothing)
--   mistpod                     a Mysterious Pod given -- never what is inside
--   mistready                   a player's Mysterious Pods made ready
--   burst                       a burst of Dewberries dropped
--   misteligible                the Enchanted Mist made eligible
-- `own` when the admin gave to themselves; `target` the player's name otherwise.
export type What = {
	kind: string,
	mode: string?,
	thunder: boolean?,
	words: string?,
	amount: number?,
	own: boolean?,
	target: string?,
}

-- The line for one action by `admin` (a display name), or nil when it says
-- nothing (an unknown action, a give of nothing).
function AdminAnnounce.line(admin: string, what: What): string?
	local W = CFG.Words
	local kind = what.kind
	if kind == "rain" then
		return string.format(W.Rain, admin)
	elseif kind == "thunder" then
		return string.format(W.Thunder, admin)
	elseif kind == "weatherend" then
		return string.format(if what.thunder then W.ThunderEnd else W.RainEnd, admin)
	elseif kind == "miststart" then
		return string.format(W.MistStart, admin)
	elseif kind == "mistend" then
		return string.format(W.MistEnd, admin)
	elseif kind == "night" then
		return string.format(W.Night, admin)
	elseif kind == "day" then
		return string.format(W.Day, admin)
	elseif kind == "mini" or kind == "miniend" then
		local modes: any = GameConfig.MiniEvent.Modes
		local mode = if what.mode then modes[what.mode] else nil
		if not mode then
			return nil
		end
		return string.format(if kind == "mini" then W.MiniStart else W.MiniEnd, admin, mode.Name)
	elseif kind == "spawn" then
		local words = what.words
		if not words or words == "" then
			return nil
		end
		if what.own then
			return string.format(W.SpawnOwn, admin, words)
		end
		return string.format(W.Spawn, admin, what.target or W.Somebody, words)
	elseif kind == "money" or kind == "speed" then
		local n = what.amount
		if not n or n <= 0 then
			return nil
		end
		local amount = if kind == "money" then AdminAnnounce.money(n) else AdminAnnounce.speed(n)
		if what.own then
			return string.format(W.GiveOwn, admin, amount)
		end
		return string.format(W.Give, admin, what.target or W.Somebody, amount)
	elseif kind == "dewberries" then
		local n = what.amount
		if not n or n <= 0 then
			return nil
		end
		local berries = string.format(if n == 1 then W.OneDewberry else W.Dewberries, n)
		if what.own then
			return string.format(W.DewberriesOwn, admin, berries)
		end
		return string.format(W.DewberriesGiven, admin, what.target or W.Somebody, berries)
	elseif kind == "progress" then
		local n = what.amount
		if not n or n <= 0 then
			return nil
		end
		local per = EnchantedMistData.BerriesPerPod
		if what.own then
			return string.format(W.ProgressOwn, admin, n, per)
		end
		return string.format(W.Progress, admin, what.target or W.Somebody, n, per)
	elseif kind == "mistpod" then
		if what.own then
			return string.format(W.MistPodOwn, admin)
		end
		return string.format(W.MistPod, admin, what.target or W.Somebody)
	elseif kind == "mistready" then
		if what.own then
			return string.format(W.MistReadyOwn, admin)
		end
		return string.format(W.MistReady, admin, what.target or W.Somebody)
	elseif kind == "burst" then
		return string.format(W.Burst, admin)
	elseif kind == "misteligible" then
		return string.format(W.MistEligible, admin)
	end
	return nil
end

-- One fold key per admin and action, and player where there is one.
function AdminAnnounce.key(adminId: number, kind: string, targetId: number?): string
	return string.format("admin:%d:%s%s", adminId, kind, if targetId then ":" .. tostring(targetId) else "")
end

-- SILENT LINES (2026-10-12, the owner: "when I trigger the enchanted mist, sfx is
-- overlapping"): the Mist's start and end make their own sound -- BEGINS and
-- ENDS, alone -- so their lines come without the notice's ping. Every other
-- admin line keeps it.
local QUIET: { [string]: boolean } = { miststart = true, mistend = true }

function AdminAnnounce.quiet(kind: string): boolean
	return QUIET[kind] == true
end

--==============================================================================
-- A BURST FOLDS. The same admin giving the same player the same kind of thing
-- again within FoldSeconds of the last adds to the one line: its count and
-- amount add up, and what was given is named while it is all the same thing --
-- else by its form ("6 pods"), or as items when the forms differ.
--==============================================================================
export type Fold = {
	at: number,
	kind: string,
	quantity: number,
	amount: number,
	species: string?,
	size: number?,
	form: string?,
	-- More than one species, size or form; more than one form.
	mixed: boolean,
	mixedForm: boolean,
}

export type Give = {
	kind: string,
	quantity: number?,
	amount: number?,
	species: string?,
	size: number?,
	form: string?,
}

function AdminAnnounce.fold(prev: Fold?, now: number, give: Give): Fold
	if prev and prev.kind == give.kind and now - prev.at <= CFG.FoldSeconds then
		local f = table.clone(prev)
		f.at = now
		f.quantity += give.quantity or 0
		f.amount += give.amount or 0
		if give.species ~= f.species or give.size ~= f.size or give.form ~= f.form then
			f.mixed = true
		end
		if give.form ~= f.form then
			f.mixedForm = true
		end
		return f
	end
	return {
		at = now,
		kind = give.kind,
		quantity = give.quantity or 0,
		amount = give.amount or 0,
		species = give.species,
		size = give.size,
		form = give.form,
		mixed = false,
		mixedForm = false,
	}
end

-- A folded spawn's words when it is not all one thing: "6 pods", "6 grown
-- plants", "6 items". `named` is SpawnCatalog's own phrase for the single case.
function AdminAnnounce.spawnWords(f: Fold, named: string): string
	if not f.mixed then
		return named
	end
	local W = CFG.Words
	if f.mixedForm then
		return string.format(W.Items, f.quantity)
	end
	return string.format(if f.form == "pod" then W.Pods else W.Plants, f.quantity)
end

return AdminAnnounce
