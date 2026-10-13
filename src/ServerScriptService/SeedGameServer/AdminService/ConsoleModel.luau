--!strict
--==============================================================================
-- Steal a Seed :: ConsoleModel (AdminService, 2026-10-07, the console redesign)
--
-- THE ADMIN CONSOLE'S ARITHMETIC AND WORDS, with no Instance in it, so
-- AdminConsoleSpec can check them without a Play session:
--
--   amounts   the ADD MONEY / ADD SPEED box: digits with thousands commas, a
--             decimal with a suffix (K, M, B, T, Qd -- Qa too, the HUD's own
--             word for it), worked out EXACTLY in whole numbers ("1.1T" is
--             1,100,000,000,000, never a float a hair off), junk refused with
--             a line that says why; the quick chips 1M .. 1Qd and MAX
--   tabs      PLAYER, SPAWN, WORLD, MIST, EVENTS, ANNOUNCE (EVENTS its own tab
--             since 2026-10-12, item 11; MIST, the Enchanted Mist and its
--             tools, since item 12); the sections each shows -- the weather
--             for every admin account since 2026-10-07 (the owner's alone
--             before); which tabs show the target bar; LB / RB's step; the
--             button a controller's selection starts on in each; the duration
--             chips; SPAWN's size stepper; the Mist's lengths and pod choices
--   requests  exactly what each button sends through the one RemoteFunction:
--             the action and its three words, the same shapes the console sent
--             before the redesign, and SPAWN's request table (AdminService)
--   layout    the panel (MenuLayout.panel), the title, the tabs in the header
--             row, the target bar, the page (and the page without the bar),
--             the fading answer's line over the page's foot, and SPAWN's grid
--             beside its controls -- rects in the panel's shell, every screen
--   rows      THE COMPACT PAGES (2026-10-12, the owner's item 11): every row a
--             fixed height (a finger's 40 on a phone or a short screen), so a
--             tab's height is known before it is drawn -- AdminConsoleSpec
--             measures every listed screen with pageHeight
--
-- ADMIN-ONLY, LIKE THE CONSOLE. A child of AdminService, in ServerScriptService,
-- which never replicates; AdminService clones it, with the console, into an
-- allowlisted admin's own SeedAdmin gui and gives nobody else anything.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local SpawnCatalog = require(script.Parent:WaitForChild("SpawnCatalog"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

local ConsoleModel = {}

export type Rect = MenuLayout.Rect
local rect = MenuLayout.rect

--==============================================================================
-- AMOUNTS
--==============================================================================
-- Each suffix's power of ten. "Qd" is the owner's word for 1e15; "Qa" is the
-- HUD's (GameConfig.compact), so a number read off the HUD types straight in.
local POWER: { [string]: number } = { k = 3, m = 6, b = 9, t = 12, qd = 15, qa = 15 }

-- 1234567 -> "1,234,567". Exact for every whole number up to 2^53.
function ConsoleModel.commas(n: number): string
	local digits = string.format("%.0f", math.floor(n))
	local grouped = string.reverse(digits)
	grouped = string.gsub(grouped, "(%d%d%d)", "%1,")
	grouped = string.reverse(grouped)
	return (string.gsub(grouped, "^,", ""))
end

-- The words typed, as a whole number from 1 to `limit` -- or nil and a line
-- that says why. Spaces and underscores are ignored; commas must group the
-- whole part in threes ("999,999", never "1,5"); a decimal needs a suffix that
-- makes it whole ("1.5T" yes, "1.5" no). Worked in DIGITS, not floats: the
-- answer is exact or refused, so the full number shown is the number sent.
function ConsoleModel.parseAmount(text: any, limit: number?): (number?, string?)
	if type(text) ~= "string" then
		return nil, "Type an amount."
	end
	local s = string.gsub(text, "[%s_]", "")
	if s == "" then
		return nil, "Type an amount."
	end
	local body, suffix = string.match(s, "^([%d,%.]+)(%a*)$")
	if not body then
		return nil, "Use digits, then K, M, B, T or Qd."
	end
	local power = 0
	if suffix ~= "" then
		local p = POWER[string.lower(suffix)]
		if not p then
			return nil, "Use K, M, B, T or Qd after the number."
		end
		power = p
	end
	local whole, frac = string.match(body, "^([%d,]+)%.(%d+)$")
	if not whole then
		whole = string.match(body, "^([%d,]+)$")
		frac = ""
	end
	if not whole or whole == "" then
		return nil, "That is not a number."
	end
	if string.find(whole, ",", 1, true) then
		if not string.match(whole, "^%d%d?%d?,%d%d%d[,%d]*$") or string.find(whole, ",%d?%d?$")
			or string.find(whole, ",%d%d%d%d") then
			return nil, "Commas go between groups of three digits."
		end
		whole = string.gsub(whole, ",", "")
	end
	local f = string.gsub(frac :: string, "0+$", "")
	if #f > power then
		return nil, "That is not a whole number."
	end
	local digits = string.gsub(whole .. f, "^0+", "")
	if digits == "" then
		return nil, "Type at least 1."
	end
	local length = #digits + (power - #f)
	if length > 16 then
		return nil, "That is more than the limit."
	end
	local n = tonumber(digits .. string.rep("0", power - #f))
	if not n or n < 1 then
		return nil, "Type at least 1."
	end
	if limit and n > limit then
		return nil, "That is more than the limit of " .. ConsoleModel.commas(limit) .. "."
	end
	return n, nil
end

export type Chip = { label: string, value: number }

-- The quick chips under each amount box: 1M, 1B, 1T, 1Qd, and MAX -- the
-- limit itself, whatever the server says it is.
function ConsoleModel.chips(limit: number): { Chip }
	local out: { Chip } = {}
	for _, c in ipairs({ { "1M", 1e6 }, { "1B", 1e9 }, { "1T", 1e12 }, { "1Qd", 1e15 } }) do
		local value = c[2] :: number
		if value <= limit then
			table.insert(out, { label = c[1] :: string, value = value })
		end
	end
	table.insert(out, { label = "MAX", value = limit })
	return out
end

-- The full number a box will send, as a line under it.
function ConsoleModel.fullLine(text: string, limit: number, money: boolean): (string, boolean)
	local n, why = ConsoleModel.parseAmount(text, limit)
	if not n then
		return why or "Type an amount.", false
	end
	return "= " .. (if money then "$" else "") .. ConsoleModel.commas(n) .. (if money then "" else " Speed"), true
end

--==============================================================================
-- THE TABS AND WHAT EACH SHOWS
--==============================================================================
export type Tab = { id: string, label: string }

ConsoleModel.Tabs = {
	{ id = "player", label = "PLAYER" },
	{ id = "spawn", label = "SPAWN" },
	{ id = "world", label = "WORLD" },
	{ id = "mist", label = "MIST" },
	{ id = "events", label = "EVENTS" },
	{ id = "announce", label = "ANNOUNCE" },
} :: { Tab }

-- The tabs that act on a player, and so show the target bar (2026-10-12): the
-- rest take its room for their own rows. MIST's tools for a player act on it.
ConsoleModel.TargetTabs = { player = true, spawn = true, mist = true } :: { [string]: boolean }

-- The title in the header row: ADMIN on a short screen, where the five tabs
-- need the room beside it (2026-10-12); ADMIN CONSOLE elsewhere.
function ConsoleModel.title(short: boolean): string
	return if short then "ADMIN" else "ADMIN CONSOLE"
end

-- The sections of a tab, top to bottom. The weather is every admin account's
-- since 2026-10-07 (the owner's alone before), so every console shows it; the
-- Enchanted Mist (2026-10-11) likewise -- on its own MIST tab since
-- 2026-10-12 (item 12), with its tools. The mini events have their own tab
-- since 2026-10-12 too, so WORLD fits a phone.
function ConsoleModel.sections(tabId: string): { string }
	if tabId == "player" then
		return { "money", "speed", "rebirth", "reset" }
		-- (REBIRTHS shares RESET PROGRESS's row; its card opens under it.)
	elseif tabId == "spawn" then
		return { "groups", "search", "grid", "form", "size", "quantity", "preview", "spawn" }
	elseif tabId == "world" then
		return { "daynight", "weather" }
	elseif tabId == "mist" then
		return { "mist", "around", "forplayer" }
	elseif tabId == "events" then
		return { "events" }
	elseif tabId == "announce" then
		return { "message", "scope", "send" }
	end
	return {}
end

-- LB (-1) and RB (+1): the tab before or after, wrapping.
function ConsoleModel.stepTab(current: string, step: number): string
	local at = 1
	for i, tab in ipairs(ConsoleModel.Tabs) do
		if tab.id == current then
			at = i
		end
	end
	local n = #ConsoleModel.Tabs
	return ConsoleModel.Tabs[(at - 1 + step) % n + 1].id
end

-- Where a controller's selection starts in each tab: its main button.
ConsoleModel.MainButton = {
	player = "AddMoney",
	spawn = "Spawn",
	world = "StartNight",
	mist = "StartMist",
	events = "StartGlobalEvent",
	announce = "Send",
} :: { [string]: string }

--==============================================================================
-- THE DURATION CHIPS (2026-10-12, item 11): segmented pickers in place of the
-- seconds boxes, each inside its event's own limits (GameConfig.Weather,
-- GameConfig.MiniEvent) with the default among them. A question asks for the
-- one chosen, and its CONFIRM sends that one.
--==============================================================================
ConsoleModel.WeatherSeconds = { 60, 180, 300, 600 } :: { number }
ConsoleModel.EventSeconds = { 60, 90, 180, 300 } :: { number }
-- An admin's Mist (2026-10-12, item 12): 2, 5 or 10 minutes -- the server's own
-- list (EnchantedMistData.Schedule.AdminSeconds), 5 the default.
ConsoleModel.MistSeconds = EnchantedMistData.Schedule.AdminSeconds :: { number }

-- A Mysterious Pod's choices (2026-10-12): RANDOM or a pool creature, and for a
-- sized one (Legendary, Mythic, Divine) RANDOM or a size. nil is "random".
function ConsoleModel.podChoice(speciesId: string?, size: number?): any
	if speciesId == nil then
		return "random"
	end
	local sized = false
	for _, entry in ipairs(EnchantedMistData.Pool.Entries) do
		if entry.Id == speciesId then
			sized = EnchantedMistData.isSized(entry.Rarity)
		end
	end
	return { species = speciesId, size = if sized then size else nil }
end

-- "1 MIN", "1:30", "10 MIN".
function ConsoleModel.durationLabel(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	if whole % 60 == 0 then
		return string.format("%d MIN", whole // 60)
	end
	return string.format("%d:%02d", whole // 60, whole % 60)
end

--==============================================================================
-- WHAT EACH BUTTON SENDS
--
-- The one RemoteFunction's four words: the action, then three. Each the shape
-- the console sent before the redesign; SPAWN's is AdminService's request.
--==============================================================================
export type Args = { n: number, [number]: any }

local function args(action: string, a: any, b: any, c: any): Args
	return { n = 4, action, a, b, c }
end

ConsoleModel.args = {
	addMoney = function(targetId: number, amount: number): Args
		return args("AddMoney", targetId, amount, nil)
	end,
	addSpeed = function(targetId: number, amount: number): Args
		return args("AddSpeed", targetId, amount, nil)
	end,
	reset = function(targetId: number, typed: string): Args
		return args("ResetPlayerProgress", targetId, nil, typed)
	end,
	-- REBIRTHS (2026-10-13, the owner's item 9): how many to add to the count;
	-- the count back to 0, the target's username its confirm.
	addRebirths = function(targetId: number, n: number): Args
		return args("AddRebirths", targetId, n, nil)
	end,
	resetRebirths = function(targetId: number, confirmName: string): Args
		return args("ResetRebirths", targetId, nil, confirmName)
	end,
	-- The whole server's: the target rides along as it always did, and the
	-- server never reads it.
	startNight = function(targetId: number): Args
		return args("StartNight", targetId, nil, nil)
	end,
	startDay = function(targetId: number): Args
		return args("StartDay", targetId, nil, nil)
	end,
	-- "start" (rain), "thunder" or "end"; the seconds for the first two.
	weather = function(verb: string, seconds: number?): Args
		return args("Weather", verb, seconds, nil)
	end,
	-- A mode ("ticketdisco", "disco", "party", "tickets") with its seconds, or "end".
	miniEvent = function(verb: string, seconds: number?): Args
		return args("MiniEvent", verb, seconds, nil)
	end,
	-- "start" (START MIST NOW, the third word its length since 2026-10-12: one of
	-- MistSeconds) or "end" (END MIST NOW); since 2026-10-12 "eligible" (MAKE
	-- ELIGIBLE NOW), "burst" (a BERRY BURST around you) and "say" (MOSSKEEPER
	-- SAYS, the third word his line).
	mist = function(verb: string, extra: any?): Args
		return args("Mist", verb, extra, nil)
	end,
	-- The Mist's tools for the target bar's player (2026-10-12): their carried
	-- Dewberries, their progress toward a pod, a Mysterious Pod ("random" or
	-- { species, size? }, with their username for anybody but you), and their
	-- Mysterious Pods ready now.
	mistBerries = function(targetId: number, count: number): Args
		return args("MistBerries", targetId, count, nil)
	end,
	mistProgress = function(targetId: number, progress: number): Args
		return args("MistProgress", targetId, progress, nil)
	end,
	mistPod = function(targetId: number, choice: any, confirmName: string?): Args
		return args("MistPod", targetId, choice, confirmName)
	end,
	mistReady = function(targetId: number): Args
		return args("MistReady", targetId, nil, nil)
	end,
	-- "server" or "all"; `confirmed` only after YES, ALL SERVERS.
	announce = function(scope: string, text: string, confirmed: boolean): Args
		return args("Announce", scope, text, confirmed)
	end,
	-- The target's UserId, the request, and -- for anybody but yourself -- the
	-- target's username, which is the confirm.
	spawn = function(targetId: number, request: SpawnRequest, confirmName: string?): Args
		return args("Spawn", targetId, request, confirmName)
	end,
}

export type SpawnRequest = { species: string, form: string, size: number, quantity: number, request: string }

function ConsoleModel.spawnRequest(speciesId: string, form: string, size: number, quantity: number,
	requestId: string): SpawnRequest
	return { species = speciesId, form = form, size = size, quantity = quantity, request = requestId }
end

-- 1 .. the target's free room, never more than the bag holds; 0 when full.
function ConsoleModel.quantityMax(room: number?): number
	local r = math.floor(tonumber(room) or 0)
	return math.clamp(r, 0, GameConfig.Save.MaxHeld)
end

function ConsoleModel.clampQuantity(quantity: number, room: number?): number
	local most = ConsoleModel.quantityMax(room)
	if most < 1 then
		return 1
	end
	return math.clamp(math.floor(quantity), 1, most)
end

-- SPAWN's size stepper (2026-10-12): the next size the species comes in, down
-- (-1) or up (+1) from `current`, or nil at the end -- never one it lacks.
function ConsoleModel.sizeStep(sizes: { number }, current: number, step: number): number?
	local best: number? = nil
	for _, size in ipairs(sizes) do
		if (step > 0 and size > current and (best == nil or size < (best :: number)))
			or (step < 0 and size < current and (best == nil or size > (best :: number))) then
			best = size
		end
	end
	return best
end

-- The size a species starts on in the console: the one it has, or the smallest.
function ConsoleModel.defaultSize(species: SeedData.Species, wanted: number?): number
	local sizes = SpawnCatalog.sizesOf(species)
	if wanted and table.find(sizes, wanted) then
		return wanted
	end
	return sizes[1] or SeedData.BaseTier
end

-- "3x Colossal Lanterncap pod -> you" / "... -> Name".
function ConsoleModel.preview(species: SeedData.Species, size: number, form: string, quantity: number,
	targetName: string?): string
	return SpawnCatalog.preview(species, size, form, quantity) .. " -> " .. (targetName or "you")
end

-- The inline confirm for anybody but yourself: "Give 3 Colossal Lanterncap pods to Name?"
function ConsoleModel.giveQuestion(species: SeedData.Species, size: number, form: string, quantity: number,
	name: string): string
	return string.format("Give %s to %s?", SpawnCatalog.phrase(species, size, form, quantity), name)
end

--==============================================================================
-- THE LAYOUT
--
-- In the shell's coordinates, as MenuLayout.blocks are. The tabs stand in the
-- header row between the title and the close (a row that scrolls where it is
-- narrower than they are); under the header, the shared target bar on the
-- tabs that act on a player; then the page, to the foot. THE LOG STRIP IS
-- GONE (2026-10-12): the server's answer is one line over the page's foot that
-- fades by itself. SPAWN's grid stands beside its controls wherever the page is
-- SplitMinW wide (every landscape phone and every desktop), its controls under
-- it elsewhere.
--==============================================================================
ConsoleModel.Metrics = {
	MaxW = 900,
	MaxH = 600,
	-- A tab's least width on a short screen: 72 since the sixth tab (2026-10-12,
	-- MIST) so all six fit a 640 x 360 phone beside ADMIN; still 44 tall.
	TabMinShort = 72,
	-- Elsewhere too since the sixth tab, so six fit a small window's header
	-- beside ADMIN CONSOLE; a desktop's tabs are wider than this (up to 150).
	TabMinTall = 72,
	TabGap = 4,
	TargetShort = 40,
	TargetTall = 48,
	Gap = 4,
	-- THE COMPACT ROWS (2026-10-12, item 11). A control's height: a finger's
	-- on a phone or a short screen, a little less on a desktop. Every button's
	-- plate is 8 shorter than its target (MenuKit.button), so rows stand only
	-- RowGap apart and still read as apart; side by side, ColGap.
	RowTouch = 40,
	RowDesk = 36,
	PagePad = 4,
	CardPad = 4,
	RowGap = 2,
	ColGap = 6,
	SectionGap = 4,
	-- A line of 14-px words, one of 12-px words, the mini events' two-line
	-- help, the announcement's box.
	LineH = 18,
	SmallLineH = 16,
	HelpH = 32,
	MessageH = 60,
	-- The fading answer: its line's height, how long it stays, then its fade.
	AnswerH = 28,
	AnswerSeconds = 3,
	AnswerFade = 0.4,
	-- A row of state and action: the state block's least width beside its
	-- buttons (else it has its own row over them), a button's least and most.
	StateMinW = 150,
	ActionMinW = 92,
	ActionMaxW = 128,
	ActionWideMaxW = 220,
	-- A chip's least width: a duration, a quick amount, a mini event, POD /
	-- GROWN PLANT, THIS SERVER / ALL SERVERS.
	ChipMinW = 64,
	GrantChipMinW = 44,
	ModeMinW = 100,
	-- THE MIST TAB (2026-10-12): a count chip (0 .. 9), a pool creature's chip.
	CountMinW = 40,
	CreatureMinW = 96,
	FormMinW = 60,
	ScopeMinW = 120,
	ScrollBar = 6,
	-- SPAWN's size stepper beside how many: from this wide on one row.
	SpawnRowMinW = 270,
	StepArrowW = 36,
	CountW = 40,
	-- SPAWN: the controls' column, the grid's cards and the row over the grid.
	SplitMinW = 520,
	ControlsShort = 300,
	ControlsTall = 340,
	ToolbarShort = 40,
	ToolbarTall = 36,
	-- The group chips: their gap, and the arrows either end of the strip when
	-- the chips only fit as one scrolling row.
	ChipGap = 4,
	ChipArrowW = 36,
	CardMinShort = 120,
	CardMinTall = 132,
	CardMax = 180,
	CardGap = 6,
	GridInset = 6,
	CardWordsShort = 32,
	CardWordsTall = 40,
	PreviewShort = 54,
	-- PLAYER: money and Speed side by side from this wide.
	PlayerSplitMinW = 560,
}
local M = ConsoleModel.Metrics

export type Screen = MenuLayout.Screen

export type Layout = {
	panel: MenuLayout.Panel,
	header: Rect,
	tabs: Rect,
	tabW: number,
	tabsScroll: boolean,
	target: Rect,
	-- The page under the target bar, and the page that takes the bar's room
	-- (the tabs that act on nobody).
	page: Rect,
	pageFull: Rect,
	-- The fading answer's line, over the page's foot.
	answer: Rect,
	-- A control's height on this screen.
	rowH: number,
	-- SPAWN, inside `page`
	spawnSplit: boolean,
	toolbar: Rect,
	-- Inside `toolbar`: the search box and the group chips' strip. Wrapped, the
	-- search has its own row and every chip shows; otherwise one scrolling row
	-- beside the search, with arrows (chipArrows) so the hidden chips read as
	-- there (2026-10-07: the owner could not find the groups past EMBERROOT).
	search: Rect,
	chips: Rect,
	chipsWrap: boolean,
	chipRows: number,
	chipArrows: boolean,
	grid: Rect,
	controls: Rect,
	columns: number,
	cardW: number,
	cardH: number,
	previewH: number,
	-- PLAYER, inside `page`
	playerSplit: boolean,
}

-- Where each group chip goes, in order, filling rows `rowW` wide (one row
-- when `wrap` is false): { x, y } per chip, and the rows used.
function ConsoleModel.chipPlaces(widths: { number }, rowW: number, rowH: number, wrap: boolean): ({ { number } }, number)
	local places: { { number } } = {}
	local x, row = 0, 0
	for i, w in ipairs(widths) do
		if wrap and x > 0 and x + w > rowW then
			row += 1
			x = 0
		end
		places[i] = { x, row * (rowH + M.ChipGap) }
		x += w + M.ChipGap
	end
	return places, row + 1
end

function ConsoleModel.layout(s: Screen, outline: number, titleW: number, chipWidths: { number }?): Layout
	local p = MenuLayout.panel(s, M.MaxW, M.MaxH, outline)
	p.sidebar = false
	local C = MenuLayout.Config
	local w, h = p.shell.X, p.shell.Y
	local short = p.short
	local header = rect(p.pad, 0, math.max(0, w - p.pad * 2), p.header)

	-- THE TABS, in the header row: after the title, before the close.
	local x0 = p.pad + titleW + 10
	local x1 = w - p.pad - C.Touch - C.Gap
	local room = math.max(0, x1 - x0)
	local n = #ConsoleModel.Tabs
	local minTab = if short then M.TabMinShort else M.TabMinTall
	local fit = math.floor((room - (n - 1) * M.TabGap) / n)
	local tabW = math.max(minTab, math.min(fit, 150))
	local tabs = rect(x0, math.floor((p.header - C.Touch) / 2), room, C.Touch)

	-- THE BAR AND THE PAGE, down the shell: the page to the foot.
	local top = p.header + C.Gap
	local innerW = math.max(0, w - p.pad * 2)
	local bottom = h - p.pad
	local targetH = if short then M.TargetShort else M.TargetTall
	local target = rect(p.pad, top, innerW, targetH)
	local pageTop = top + targetH + M.Gap
	local page = rect(p.pad, pageTop, innerW, math.max(0, bottom - pageTop))
	local pageFull = rect(p.pad, top, innerW, math.max(0, bottom - top))
	local answer = rect(p.pad + M.PagePad, bottom - M.AnswerH - M.PagePad, math.max(0, innerW - M.PagePad * 2),
		M.AnswerH)
	local rowH = if short or s.compact then M.RowTouch else M.RowDesk

	-- SPAWN: the grid beside its controls, or over them.
	local split = page.w >= M.SplitMinW
	local controlsW = if short then M.ControlsShort else M.ControlsTall
	local toolbarH = if short then M.ToolbarShort else M.ToolbarTall
	local gridCol: Rect
	local controls: Rect
	if split then
		local cw = math.min(controlsW, math.floor(page.w * 0.5))
		gridCol = rect(0, 0, page.w - cw - M.Gap, page.h)
		controls = rect(page.w - cw, 0, cw, page.h)
	else
		local ch = math.min(page.h, if short then 122 else 220)
		gridCol = rect(0, 0, page.w, math.max(0, page.h - ch - M.Gap))
		controls = rect(0, page.h - ch, page.w, ch)
	end
	local g = MenuLayout.grid(gridCol.w - 5, if short then M.CardMinShort else M.CardMinTall, M.CardMax, M.CardGap,
		M.GridInset)
	local previewH = if short then M.PreviewShort else math.min(96, math.floor(g.cardW * 0.55))
	local cardH = previewH + (if short then M.CardWordsShort else M.CardWordsTall)

	-- THE ROW OVER THE GRID. Wrapped when that still leaves a whole row of
	-- cards in view: the search on its own row, every chip under it. Else one
	-- row: the chips' strip, between its arrows, beside the search.
	local _, rows = ConsoleModel.chipPlaces(chipWidths or {}, gridCol.w, toolbarH, true)
	local wrapH = toolbarH * (rows + 1) + M.ChipGap * (rows - 1) + M.Gap
	local wrap = chipWidths ~= nil and #chipWidths > 0 and gridCol.h - wrapH - M.Gap >= cardH
	local toolbarTotal = if wrap then wrapH else toolbarH
	local toolbar = rect(gridCol.x, gridCol.y, gridCol.w, toolbarTotal)
	local search: Rect
	local chips: Rect
	local arrows = false
	if wrap then
		search = rect(0, 0, gridCol.w, toolbarH)
		chips = rect(0, toolbarH + M.Gap, gridCol.w, toolbarTotal - toolbarH - M.Gap)
	else
		local searchW = math.clamp(math.floor(gridCol.w * 0.36), 110, 220)
		local stripW = gridCol.w - searchW - 6
		local needed = -M.ChipGap
		for _, w in ipairs(chipWidths or {}) do
			needed += w + M.ChipGap
		end
		arrows = needed > stripW
		local inset = if arrows then M.ChipArrowW + M.ChipGap else 0
		search = rect(gridCol.w - searchW, 0, searchW, toolbarH)
		chips = rect(inset, 0, math.max(0, stripW - inset * 2), toolbarH)
	end
	local grid = rect(gridCol.x, gridCol.y + toolbarTotal + M.Gap, gridCol.w,
		math.max(0, gridCol.h - toolbarTotal - M.Gap))

	return {
		panel = p,
		header = header,
		tabs = tabs,
		tabW = tabW,
		tabsScroll = n * tabW + (n - 1) * M.TabGap > room,
		target = target,
		page = page,
		pageFull = pageFull,
		answer = answer,
		rowH = rowH,
		spawnSplit = split,
		toolbar = toolbar,
		search = search,
		chips = chips,
		chipsWrap = wrap,
		chipRows = if wrap then rows else 1,
		chipArrows = arrows,
		grid = grid,
		controls = controls,
		columns = g.columns,
		cardW = g.cardW,
		cardH = cardH,
		previewH = previewH,
		playerSplit = page.w >= M.PlayerSplitMinW,
	}
end

--==============================================================================
-- THE COMPACT PAGES' ROWS (2026-10-12, the owner's item 11)
--
-- Every row a fixed height, so a tab's height is worked out here exactly as
-- the console builds it: a page is a list (PagePad above and below, its cards
-- SectionGap apart), a card its rows (CardPad round them, RowGap apart).
-- AdminConsoleSpec measures every listed screen with it. `w` is the page's
-- inner width (inside its padding and scroll bar), `rowH` Layout.rowH.
--==============================================================================
-- How many `min` wide fit side by side in `w`, never more than `most`.
function ConsoleModel.perRow(w: number, min: number, most: number): number
	return math.clamp(math.floor((w + M.ColGap) / (min + M.ColGap)), 1, math.max(1, most))
end

-- A run of `n` chips (or buttons), `min` wide, at most `most` to a row.
function ConsoleModel.chipsHeight(n: number, w: number, min: number, most: number, rowH: number): number
	local rows = math.ceil(n / ConsoleModel.perRow(w, min, most))
	return rows * rowH + (rows - 1) * M.RowGap
end

-- Whether a state block and `buttons` buttons share one row `w` wide.
function ConsoleModel.actionInline(w: number, buttons: number): boolean
	return w >= M.StateMinW + buttons * (M.ActionMinW + M.ColGap)
end

-- A row of state and action: one row, or the block over the buttons.
function ConsoleModel.actionRowHeight(w: number, buttons: number, rowH: number): number
	return if ConsoleModel.actionInline(w, buttons) then rowH else rowH * 2 + M.RowGap
end

-- An action row's buttons' width when inline: three fifths of the row shared
-- between them, from ActionMinW to `most`.
function ConsoleModel.actionWidth(w: number, buttons: number, most: number): number
	return math.clamp(math.floor(w * 0.6 / buttons) - M.ColGap, M.ActionMinW, most)
end

-- A card holding these rows.
function ConsoleModel.cardHeight(rows: { number }): number
	local h = M.CardPad * 2
	for i, r in ipairs(rows) do
		h += r + (if i > 1 then M.RowGap else 0)
	end
	return h
end

-- SPAWN's size stepper and how many: one row, or one over the other.
function ConsoleModel.spawnRowHeight(w: number, rowH: number): number
	return if w >= M.SpawnRowMinW then rowH else rowH * 2 + M.RowGap
end

export type PageOpts = { split: boolean?, resetOpen: boolean?, rebirthOpen: boolean? }

-- A tab's height at page inner width `w` -- for SPAWN, the height its controls
-- column needs at that column's inner width. Every question stands in for the
-- row it asks about, the same height, so none of them changes it.
function ConsoleModel.pageHeight(tabId: string, w: number, rowH: number, opts: PageOpts?): number
	local o: PageOpts = opts or {}
	local cardW = w - M.CardPad * 2
	if tabId == "spawn" then
		-- POD / GROWN PLANT; the size beside how many; the preview; SPAWN.
		return M.PagePad * 2 + ConsoleModel.chipsHeight(2, w, M.FormMinW, 2, rowH) + M.RowGap
			+ ConsoleModel.spawnRowHeight(w, rowH) + M.RowGap + M.LineH + M.RowGap + rowH + M.CardPad
	end
	local sections: { number } = {}
	if tabId == "player" then
		-- ADD MONEY and ADD SPEED (side by side when split): the box beside its
		-- button, the quick chips, the full number. Then REBIRTHS, then RESET
		-- PROGRESS's row.
		local split = o.split == true
		local half = if split then math.floor((w - M.ColGap) / 2) else w
		local inner = half - M.CardPad * 2
		local grant = ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(inner, 1, rowH),
			ConsoleModel.chipsHeight(5, inner, M.GrantChipMinW, 5, rowH), M.LineH })
		table.insert(sections, if split then grant else grant * 2 + M.SectionGap)
		-- RESET PROGRESS's red box; or the row it shares (2026-10-13, item 9) with
		-- REBIRTHS -- the count beside REBIRTHS... and RESET PROGRESS... -- and,
		-- while it is open, the rebirth card under it: the box beside ADD and +1,
		-- then CLOSE and SET TO 0 (its question in the same row's place).
		local shared = ConsoleModel.actionRowHeight(w, 2, rowH)
		if o.rebirthOpen and not o.resetOpen then
			shared += M.RowGap + ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 2, rowH),
				ConsoleModel.actionRowHeight(cardW, 2, rowH) })
		end
		table.insert(sections, if o.resetOpen
			then ConsoleModel.cardHeight({ M.LineH, M.SmallLineH * 3, M.SmallLineH, rowH, M.SmallLineH })
			else shared)
	elseif tabId == "world" then
		-- Night and day; the weather with its durations; the Enchanted Mist.
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 2, rowH) }))
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 3, rowH),
			ConsoleModel.chipsHeight(#ConsoleModel.WeatherSeconds, cardW, M.ChipMinW, 4, rowH) }))
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 2, rowH) }))
	elseif tabId == "events" then
		-- START / END EVENT, the five modes, the durations, the mode's help, the sync.
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 2, rowH),
			ConsoleModel.chipsHeight(5, cardW, M.ModeMinW, 5, rowH),
			ConsoleModel.chipsHeight(#ConsoleModel.EventSeconds, cardW, M.ChipMinW, 4, rowH), M.HelpH, M.SmallLineH }))
	elseif tabId == "announce" then
		-- THIS SERVER / ALL SERVERS, the words, the count beside SEND.
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.chipsHeight(2, cardW, M.ScopeMinW, 2, rowH),
			M.MessageH, ConsoleModel.actionRowHeight(cardW, 1, rowH) }))
	elseif tabId == "mist" then
		-- THE MIST (2026-10-12, item 12): its state beside START / END, the
		-- lengths beside MAKE ELIGIBLE NOW, the berries' line. AROUND YOU: the
		-- burst, MOSSKEEPER SAYS. FOR THE TARGET: their counts, DEWBERRIES 0..5,
		-- PROGRESS 0..9, the creature, the size, GIVE POD and READY NOW.
		local pool = #EnchantedMistData.Pool.Entries
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 2, rowH),
			ConsoleModel.chipsHeight(#ConsoleModel.MistSeconds + 1, cardW, M.ChipMinW, 4, rowH), M.SmallLineH }))
		table.insert(sections, ConsoleModel.cardHeight({ ConsoleModel.actionRowHeight(cardW, 1, rowH),
			ConsoleModel.actionRowHeight(cardW, 1, rowH) }))
		table.insert(sections, ConsoleModel.cardHeight({ M.SmallLineH,
			ConsoleModel.chipsHeight(EnchantedMistData.CarryCap + 1, cardW, M.CountMinW, 10, rowH), M.SmallLineH,
			ConsoleModel.chipsHeight(EnchantedMistData.BerriesPerPod, cardW, M.CountMinW, 10, rowH), M.SmallLineH,
			ConsoleModel.chipsHeight(pool + 1, cardW, M.CreatureMinW, pool + 1, rowH),
			ConsoleModel.chipsHeight(SeedData.TierCount + 1, cardW, M.ChipMinW, SeedData.TierCount + 1, rowH),
			ConsoleModel.actionRowHeight(cardW, 2, rowH) }))
	end
	local h = M.PagePad * 2
	for i, s in ipairs(sections) do
		h += s + (if i > 1 then M.SectionGap else 0)
	end
	return h
end

return ConsoleModel
