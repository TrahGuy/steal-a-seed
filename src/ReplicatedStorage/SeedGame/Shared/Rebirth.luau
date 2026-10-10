--!strict
--==============================================================================
-- Steal a Seed :: Rebirth (2026-10-08)
--
-- The rebirth rulebook, pure: what the next one costs, what it needs, what it
-- gives, which title and which fence a count earns, and what stops one right
-- now. No instance, no remote, no clock of its own -- RebirthService asks with
-- the state it read, RebirthUI asks with the state it was told, and both get
-- the same answer. The numbers are GameConfig.Rebirth.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))

local CFG = GameConfig.Rebirth
local WORDS = CFG.Words

local Rebirth = {}

Rebirth.count = GameConfig.rebirthCount

-- What the n-th rebirth costs (n from 1): BasePrice, x PriceFactor each time,
-- never over PriceCap.
function Rebirth.priceFor(n: number): number
	local k = math.max(1, math.floor(n))
	return math.min(CFG.BasePrice * CFG.PriceFactor ^ (k - 1), CFG.PriceCap)
end

-- What the NEXT one costs for somebody reborn `rebirths` times.
function Rebirth.nextPrice(rebirths: any): number
	return Rebirth.priceFor(Rebirth.count(rebirths) + 1)
end

-- The two bonuses a count carries, added up: +50% training and +25% income
-- each (GameConfig's own seams, so the payout and this cannot disagree).
function Rebirth.training(rebirths: any): number
	return GameConfig.rebirthMultiplierFor({ Rebirths = rebirths })
end

function Rebirth.income(rebirths: any): number
	return GameConfig.rebirthIncomeFor(rebirths)
end

-- A multiplier as the panel prints it: 1.5, 2, 2.25 -- never 1.5000001.
function Rebirth.times(x: number): string
	local rounded = math.floor(x * 100 + 0.5) / 100
	if rounded == math.floor(rounded) then
		return string.format("%d", rounded)
	end
	return (string.gsub(string.format("%.2f", rounded), "0$", ""))
end

-- The mill tier a rebirth needs, and its name.
function Rebirth.millNeeded(): (number, string)
	local tier = GameConfig.Mill.Tiers[CFG.MinMillTier]
	return CFG.MinMillTier, if tier then tier.name else tostring(CFG.MinMillTier)
end

export type Step = { At: number, Text: string, Colour: Color3, Family: string?, Rainbow: boolean?, Ranks: number? }

-- The index of the highest title step a count has reached, 0 before the first.
-- The ladder rises (RebirthSpec), so the first step not reached ends the look.
function Rebirth.stepIndex(rebirths: any): number
	local n = Rebirth.count(rebirths)
	local index = 0
	for i, step in ipairs(CFG.Title.Ladder) do
		if n < step.At then
			break
		end
		index = i
	end
	return index
end

-- The highest title step a count has reached, or nil before the first.
function Rebirth.title(rebirths: any): Step?
	local index = Rebirth.stepIndex(rebirths)
	return if index > 0 then CFG.Title.Ladder[index] :: any else nil
end

--==============================================================================
-- ROMAN NUMERALS (2026-10-08, the owner: "Add roman numerals so that players
-- wont think it's repepitive"). Inside a step longer than one rebirth the
-- title counts on from I, so no two rebirths in a row wear the same words;
-- a step of one rebirth has no numeral. GameConfig.Rebirth.Title says how.
--==============================================================================
local NUMERALS = {
	{ 1000, "M" }, { 900, "CM" }, { 500, "D" }, { 400, "CD" }, { 100, "C" }, { 90, "XC" },
	{ 50, "L" }, { 40, "XL" }, { 10, "X" }, { 9, "IX" }, { 5, "V" }, { 4, "IV" }, { 1, "I" },
}

-- n in roman numerals, I to MMMCMXCIX (3999); past that the plain number,
-- since roman has no 4000 without a bar over it; "" below 1.
function Rebirth.roman(n: number): string
	local k = math.floor(n)
	if k ~= k or k < 1 then
		return ""
	elseif k > 3999 then
		return string.format("%.0f", k)
	end
	local parts = {}
	for _, pair in ipairs(NUMERALS) do
		while k >= pair[1] do
			table.insert(parts, pair[2])
			k -= pair[1]
		end
	end
	return table.concat(parts)
end

-- The rebirths the ladder's i-th step spans: its first, and its last. The top
-- step's last is where its Ranks end (GAIA V at 302); it is worn on after it.
function Rebirth.span(index: number): (number, number)
	local ladder = CFG.Title.Ladder
	local step = ladder[index] :: any
	local after = ladder[index + 1]
	if after then
		return step.At, after.At - 1
	end
	return step.At, step.At + math.max(1, math.floor(tonumber(step.Ranks) or 1)) - 1
end

-- The words a count wears over its name and in the panel -- "BOTANIST II" --
-- with its step (colour, family, rainbow); nil before the first rebirth. Past
-- the top step's last rank the numeral stays there: GAIA V at 302 and on.
function Rebirth.titleFor(rebirths: any): (string?, Step?)
	local n = Rebirth.count(rebirths)
	local index = Rebirth.stepIndex(n)
	if index == 0 then
		return nil, nil
	end
	local step = CFG.Title.Ladder[index] :: any
	local first, last = Rebirth.span(index)
	if last == first then
		return step.Text, step
	end
	return string.format(CFG.Title.Numbered, step.Text, Rebirth.roman(math.min(n, last) - first + 1)), step
end

-- A step as the TITLES list names it: the words with their numerals' range
-- ("BOTANIST I-III", "GAIA I-V", "SPROUT") and its rebirths ("REBIRTH 5-7",
-- "REBIRTH 1"; the top step's run on: "REBIRTH 298+").
function Rebirth.stepWords(index: number): (string, string)
	local step = CFG.Title.Ladder[index]
	local first, last = Rebirth.span(index)
	local rebirths = if CFG.Title.Ladder[index + 1] == nil then string.format(WORDS.RowRebirthFrom, first)
		elseif last == first then string.format(WORDS.RowRebirth, first)
		else string.format(WORDS.RowRebirths, first, last)
	if last == first then
		return step.Text, rebirths
	end
	return string.format(CFG.Title.Span, step.Text, Rebirth.roman(1), Rebirth.roman(last - first + 1)), rebirths
end

--==============================================================================
-- THE FAMILIES (2026-10-10, the 100 titles): GameConfig.Rebirth.Title.Families,
-- each step's by its Family. What the TITLES list heads each run with, and what
-- the celebration and the aura are tinted by.
--==============================================================================
export type Family = {
	Id: string,
	Name: string,
	Fx: string,
	Primary: Color3,
	Secondary: Color3,
	Signature: string?,
	AuraAccents: number?,
	Rainbow: boolean?,
}

local familyById: { [string]: Family } = {}
for _, f in ipairs(CFG.Title.Families) do
	familyById[f.Id] = f :: any
end

-- A step's family, or nil (no step, or one with none).
function Rebirth.family(step: any): Family?
	local id = if type(step) == "table" then step.Family else nil
	return if type(id) == "string" then familyById[id] else nil
end

-- A family's run of the ladder: its first step's index and its last (0, 0 for
-- an id no step wears), and the rebirths from the first one's first to the last
-- one's last.
function Rebirth.familySpan(id: string): (number, number, number, number)
	local firstIndex, lastIndex = 0, 0
	for i, step in ipairs(CFG.Title.Ladder) do
		if (step :: any).Family == id then
			if firstIndex == 0 then
				firstIndex = i
			end
			lastIndex = i
		end
	end
	if firstIndex == 0 then
		return 0, 0, 0, 0
	end
	local from = Rebirth.span(firstIndex)
	local _, to = Rebirth.span(lastIndex)
	return firstIndex, lastIndex, from, to
end

-- What a rebirth from `before` to `after` does to the title: "name" (a step it
-- had not reached: SPROUT, or BOTANIST III to LEAF TENDER I), "rank" (the same
-- step's next numeral, or GAIA V kept) or "none" (no title yet).
function Rebirth.change(before: any, after: any): string
	local now = Rebirth.stepIndex(after)
	if now == 0 then
		return "none"
	end
	return if Rebirth.stepIndex(before) ~= now then "name" else "rank"
end

-- The size one line of words is drawn at: `base`, unless the words need more
-- room than the box has, then just small enough to fit (never under 1).
function Rebirth.fitSize(base: number, need: number, room: number): number
	if room <= 0 or need <= room then
		return base
	end
	return math.max(1, math.floor(base * room / need))
end

export type Fence = {
	tier: number,
	style: { [string]: any },
	-- The gems' colour on the gold fence (nil below it).
	trim: Color3?,
}

-- The fence a plot owner's count earns: tier = rebirths up to the last tier;
-- past that the gold fence's gems step through Trims every TrimEvery rebirths.
function Rebirth.fence(rebirths: any): Fence
	local n = Rebirth.count(rebirths)
	local F = CFG.Fence
	local last = #F.Tiers
	local tier = math.min(n, last)
	local style = F.Tiers[tier] :: any
	local trim: Color3? = nil
	if tier == last then
		local step = (n - last) // F.TrimEvery
		trim = F.Trims[(step % #F.Trims) + 1]
	end
	return { tier = tier, style = style, trim = trim }
end

export type State = {
	enabled: boolean?,
	-- The save is loaded.
	ready: boolean,
	now: number,
	-- os.time() of the last rebirth (0 never).
	lastAt: number?,
	rebirths: number,
	cash: number,
	millTier: number,
	dead: boolean?,
	carrying: boolean?,
	chased: boolean?,
	-- An offline claim is waiting.
	offline: boolean?,
	-- A purchase, or another rebirth, is in flight.
	busy: boolean?,
}

-- Nil when a rebirth may go ahead; otherwise the first thing stopping it, in
-- the order a player can do something about it.
function Rebirth.check(s: State): string?
	if s.enabled == false or not CFG.Enabled then
		return "DISABLED"
	end
	if not s.ready then
		return "NOT_READY"
	end
	if (s.lastAt or 0) > 0 and s.now - (s.lastAt or 0) < CFG.CooldownSeconds then
		return "COOLDOWN"
	end
	if s.busy then
		return "BUSY"
	end
	if s.dead then
		return "DEAD"
	end
	if s.carrying then
		return "CARRYING"
	end
	if s.chased then
		return "CHASED"
	end
	if s.offline then
		return "OFFLINE"
	end
	if (s.millTier or 0) < CFG.MinMillTier then
		return "MILL"
	end
	if (s.cash or 0) < Rebirth.nextPrice(s.rebirths) then
		return "CASH"
	end
	return nil
end

-- Every step of the title ladder for a count: "reached", "next" (the first
-- not reached) or "locked"; with the index of the highest reached (0 before
-- the first) and of the next (0 past the last).
export type LadderRow = { step: Step, state: string }
function Rebirth.ladder(rebirths: any): ({ LadderRow }, number, number)
	local n = Rebirth.count(rebirths)
	local rows: { LadderRow } = {}
	local highest, nextIndex = 0, 0
	for i, step in ipairs(CFG.Title.Ladder) do
		local state = "locked"
		if n >= step.At then
			state = "reached"
			highest = i
		elseif nextIndex == 0 then
			state = "next"
			nextIndex = i
		end
		table.insert(rows, { step = step :: any, state = state })
	end
	return rows, highest, nextIndex
end

export type Layout = {
	panel: MenuLayout.Panel,
	-- In the panel's shell (MenuLayout.blocks' space): the scrolling body, the
	-- foot under it and the button in the foot.
	scroll: MenuLayout.Rect,
	foot: MenuLayout.Rect,
	button: MenuLayout.Rect,
	-- The band's X (UIKit.modal's own 44 px target at the title row's right)
	-- and the "?" left of it; the TITLES view's BACK and its list, which fill
	-- the body from the scroll's top to the foot's bottom.
	close: MenuLayout.Rect,
	help: MenuLayout.Rect,
	back: MenuLayout.Rect,
	list: MenuLayout.Rect,
	wide: boolean,
}

-- Where the panel and its parts go on one screen (MenuLayout's Screen, in the
-- menu gui's own units). RebirthUI places by it; RebirthSpec checks it on
-- every listed phone and desktop.
function Rebirth.layout(screen: MenuLayout.Screen, outline: number): Layout
	local L = CFG.Layout
	local p = MenuLayout.panel(screen, L.MaxW, L.MaxH, outline)
	local b = MenuLayout.blocks(p)
	local x, y, w, h = b.header.x, b.main.y, b.header.w, b.main.h
	local foot = MenuLayout.rect(x, y + h - L.Foot, w, L.Foot)
	local touch = MenuLayout.Config.Touch
	local rowY = p.header * 0.5 - touch * 0.5
	local barRight = b.header.x + b.header.w
	local listY = y + L.BackH + 6
	return {
		panel = p,
		scroll = MenuLayout.rect(x, y, w, math.max(L.MinScroll, h - L.Foot - 4)),
		foot = foot,
		button = MenuLayout.rect(x + w * (1 - L.ButtonW) * 0.5, foot.y + L.ButtonTop, w * L.ButtonW, L.ButtonH),
		close = MenuLayout.rect(barRight - touch, rowY, touch, touch),
		help = MenuLayout.rect(barRight - touch * 2 - L.HelpGap, rowY, touch, touch),
		back = MenuLayout.rect(x, y, math.min(w, L.BackW), L.BackH),
		list = MenuLayout.rect(x, listY, w, foot.y + foot.h - listY),
		wide = w >= L.WideAt,
	}
end

-- The words for a refusal, with its number filled in where it has one.
function Rebirth.refusal(why: string, rebirths: any): string
	local line = WORDS.Refused[why] or WORDS.Refused.DISABLED
	if why == "MILL" then
		local _, name = Rebirth.millNeeded()
		return string.format(line, name)
	elseif why == "CASH" then
		return string.format(line, "$" .. GameConfig.money(Rebirth.nextPrice(rebirths)))
	end
	return line
end

return Rebirth
