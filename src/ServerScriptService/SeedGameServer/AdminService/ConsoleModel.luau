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
--   tabs      PLAYER, SPAWN, WORLD, ANNOUNCE; the sections each shows -- the
--             weather for every admin account since 2026-10-07 (the owner's
--             alone before); LB / RB's step; the button a controller's
--             selection starts on in each
--   requests  exactly what each button sends through the one RemoteFunction:
--             the action and its three words, the same shapes the console sent
--             before the redesign, and SPAWN's request table (AdminService)
--   layout    the panel (MenuLayout.panel), the tabs in the header row, the
--             target bar, the page, the log strip and SPAWN's grid beside its
--             controls -- rects in the panel's shell, for every screen
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
	{ id = "announce", label = "ANNOUNCE" },
} :: { Tab }

-- The sections of a tab, top to bottom. The weather is every admin account's
-- since 2026-10-07 (the owner's alone before), so every console shows it.
function ConsoleModel.sections(tabId: string): { string }
	if tabId == "player" then
		return { "money", "speed", "reset" }
	elseif tabId == "spawn" then
		return { "groups", "search", "grid", "form", "size", "quantity", "preview", "spawn" }
	elseif tabId == "world" then
		return { "daynight", "weather", "events" }
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
	announce = "Send",
} :: { [string]: string }

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
-- narrower than they are); under the header, the shared target bar; then the
-- page; then the log strip -- one line on a short screen, three elsewhere,
-- scrolling through the last five. SPAWN's grid stands beside its controls
-- wherever the page is SplitMinW wide (every landscape phone and every
-- desktop), its controls under it elsewhere.
--==============================================================================
ConsoleModel.Metrics = {
	MaxW = 900,
	MaxH = 600,
	TabMinShort = 84,
	TabMinTall = 112,
	TabGap = 4,
	TargetShort = 40,
	TargetTall = 48,
	LogLine = 18,
	LogPad = 3,
	LogLinesShort = 1,
	LogLinesTall = 3,
	Gap = 4,
	-- SPAWN: the controls' column, the grid's cards and the row over the grid.
	SplitMinW = 520,
	ControlsShort = 300,
	ControlsTall = 340,
	ToolbarShort = 30,
	ToolbarTall = 36,
	-- The group chips: their gap, and the arrows either end of the strip when
	-- the chips only fit as one scrolling row.
	ChipGap = 4,
	ChipArrowW = 30,
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
	page: Rect,
	log: Rect,
	logLines: number,
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

	-- THE BAR, THE PAGE AND THE LOG, down the shell.
	local top = p.header + C.Gap
	local innerW = math.max(0, w - p.pad * 2)
	local bottom = h - p.pad
	local targetH = if short then M.TargetShort else M.TargetTall
	local lines = if short then M.LogLinesShort else M.LogLinesTall
	local logH = lines * M.LogLine + M.LogPad * 2
	local target = rect(p.pad, top, innerW, targetH)
	local log = rect(p.pad, bottom - logH, innerW, logH)
	local pageTop = top + targetH + M.Gap
	local page = rect(p.pad, pageTop, innerW, math.max(0, bottom - logH - M.Gap - pageTop))

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
		log = log,
		logLines = lines,
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

return ConsoleModel
