--!strict
--==============================================================================
-- SPEED MILESTONES AND WALK-SPEED POPS (TREADMILL FUN, the owner's brief,
-- 2026-10-08) -- data and pure rules only.
--
-- THE RULE THAT DOES NOT MOVE: the belt's Speed rate is untouched. Nothing here
-- is a Speed source or a multiplier. The pops and the bar are feedback; the
-- milestones pay CASH or SPIN TICKETS, and TreadmillFunService pays them.
--
--==============================================================================
-- A1. "+1 WALK SPEED" -- every time the WalkSpeed the SCORE walks at
-- (GameConfig.walkSpeedFor, never the carry-slowed figure) passes a whole
-- number. Several at once are one pop. TreadmillFunUI draws it off the profile
-- packet, the way SpeedFX draws its "+N": no remote.
--
-- A2. SEVENTEEN MILESTONES, each paid ONCE PER PROFILE, EVER. The profile keeps
-- the highest one passed (SpeedMilestone, a Speed value -- a list that grows
-- later still reads right); every milestone at or below it is spent. Cash at
-- twelve, one free spin ticket at five. Admin and debug Speed mark them passed
-- with no prize, and a save from before this shipped starts with every
-- milestone under its score already passed: no back pay.
--==============================================================================
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local SpeedMilestones = {}

SpeedMilestones.List = {
	100, 500, 1e3, 5e3, 1e4, 5e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
} :: { number }

-- One free spin ticket at each of these: five, ever. Cash at the other twelve.
SpeedMilestones.Tickets = { [1e3] = 1, [1e6] = 1, [1e9] = 1, [1e12] = 1, [1e15] = 1 } :: { [number]: number }

--==============================================================================
-- THE CASH (proposed for the owner to approve)
--
-- 60 s of the player's garden income at that moment, never under the
-- milestone's FLOOR -- so a player with nothing growing still gets something --
-- and never over CapShare of their NEXT plot level's cost (the top level's at
-- Level 7). When the two disagree the CAP wins: no milestone may pay more than
-- a small share of the next plot level.
--
-- The floors grow with the milestone and each is at most a tenth of the plot
-- level a player usually faces when they reach it (25K .. 2.5B):
--
--     100      $100      500     $250      5K      $1K     10K     $2K
--     50K      $5K       100K    $10K      10M     $50K    100M    $250K
--     10B      $1M       100B    $2.5M     10T     $10M    100T    $25M
--==============================================================================
SpeedMilestones.CashSeconds = 60
SpeedMilestones.CapShare = 0.10
SpeedMilestones.Floors = {
	[100] = 100, [500] = 250, [5e3] = 1000, [1e4] = 2000, [5e4] = 5000, [1e5] = 10000,
	[1e7] = 50000, [1e8] = 250000, [1e10] = 1e6, [1e11] = 2.5e6, [1e13] = 1e7, [1e14] = 2.5e7,
} :: { [number]: number }

--==============================================================================
-- THE OWNER'S ART (2026-10-08, relayed with the brief; each proven IsLoaded in
-- Edit and transparent). The Speed shoe is the game's one Speed icon,
-- GameConfig.SourceIcons.speed -- the owner's transparent re-upload (the first
-- one was on a black square) -- in the pop over the burst, riding the bar's
-- fill, and in the badge's centre with the number; its small version wherever
-- it draws at 40 px or less (SizedIcon).
--==============================================================================
SpeedMilestones.Art = {
	-- GOLD BURST: rays with a transparent centre, behind the pop.
	Burst = "rbxassetid://138957621639655",
	-- MILESTONE BADGE: an empty gold medal; the number is drawn over its centre.
	Badge = "rbxassetid://101850589009212",
	Shoe = GameConfig.SourceIcons.speed,
}

-- The shoe's sizes before the screen's scale: in the pop beside the words, on
-- the bar's fill, and in the badge's centre.
SpeedMilestones.ShoePx = { Pop = 46, Bar = 26, Badge = 30 }

-- The sound each moment makes (existing cues only).
SpeedMilestones.Sounds = { Pop = "InviteBadgePop", Milestone = "MillUpgrade" }

--==============================================================================
-- THE MILESTONES
--==============================================================================
function SpeedMilestones.isTicket(milestone: number): boolean
	return SpeedMilestones.Tickets[milestone] ~= nil
end

-- How the bar and the notice write a milestone: the HUD's own compact form.
function SpeedMilestones.label(milestone: number): string
	return GameConfig.compact(milestone)
end

-- The highest milestone at or below `score`, or 0: what a save from before this
-- shipped starts with (no back pay).
function SpeedMilestones.highestAtOrBelow(score: number): number
	local s = tonumber(score) or 0
	local best = 0
	for _, m in SpeedMilestones.List do
		if m <= s then
			best = m
		end
	end
	return best
end

-- Every milestone above the profile's `mark` (the highest passed) and at or
-- below `score`, smallest first. A mark that is not a milestone still works:
-- everything at or below it is spent.
function SpeedMilestones.crossed(mark: number, score: number): { number }
	local out = {}
	local m0, s = tonumber(mark) or 0, tonumber(score) or 0
	for _, m in SpeedMilestones.List do
		if m > m0 and m <= s then
			table.insert(out, m)
		end
	end
	return out
end

-- The next milestone above the mark, or nil once all seventeen are passed.
function SpeedMilestones.nextAfter(mark: number): number?
	local m0 = tonumber(mark) or 0
	for _, m in SpeedMilestones.List do
		if m > m0 then
			return m
		end
	end
	return nil
end

-- The bar: from the last milestone passed to the next one, how full (0..1).
function SpeedMilestones.progress(mark: number, score: number): (number, number?, number)
	local last = tonumber(mark) or 0
	local nextOne = SpeedMilestones.nextAfter(last)
	if not nextOne then
		return last, nil, 1
	end
	local s = tonumber(score) or 0
	local span = nextOne - last
	local fill = if span > 0 then math.clamp((s - last) / span, 0, 1) else 1
	return last, nextOne, fill
end

-- "NEXT: 5K SPEED · CASH" / "NEXT: 1M SPEED · 1 SPIN TICKET" -- words, never a
-- glyph that might draw as a box.
function SpeedMilestones.barWords(nextOne: number?): string
	if not nextOne then
		return "EVERY SPEED MILESTONE PASSED"
	end
	return string.format("NEXT: %s SPEED \u{00B7} %s", SpeedMilestones.label(nextOne),
		if SpeedMilestones.isTicket(nextOne) then "1 SPIN TICKET" else "CASH")
end

-- The cap on one milestone's cash: CapShare of the next plot level's cost, or of
-- the top level's at the top.
function SpeedMilestones.capFor(plotLevel: number): number
	local tiers = GameConfig.PlotTiers
	local level = math.clamp(math.floor(tonumber(plotLevel) or 1), 1, #tiers)
	local nextTier = tiers[level + 1] or tiers[#tiers]
	return math.floor(nextTier.cost * SpeedMilestones.CapShare)
end

-- What a CASH milestone pays: 60 s of income, never under its floor, never over
-- the cap (the cap wins). Whole dollars, at least 1.
function SpeedMilestones.cashFor(milestone: number, incomePerSecond: number, plotLevel: number): number
	local income = tonumber(incomePerSecond) or 0
	if income ~= income or income < 0 then
		income = 0
	end
	local amount = math.max(SpeedMilestones.Floors[milestone] or 0,
		math.floor(income * SpeedMilestones.CashSeconds))
	amount = math.min(amount, SpeedMilestones.capFor(plotLevel))
	return math.max(1, math.floor(amount))
end

-- The one notice for one gain, however many milestones it crossed:
-- "MILESTONE! 10K Speed" / "+$2K · +1 Spin Ticket".
function SpeedMilestones.noticeWords(highest: number, cash: number, tickets: number): (string, string)
	local parts = {}
	if cash > 0 then
		table.insert(parts, "+$" .. GameConfig.compact(cash))
	end
	if tickets > 0 then
		table.insert(parts, string.format("+%d Spin Ticket%s", tickets, if tickets == 1 then "" else "s"))
	end
	return "MILESTONE! " .. SpeedMilestones.label(highest) .. " Speed",
		if #parts > 0 then table.concat(parts, " \u{00B7} ") else "Passed"
end

--==============================================================================
-- A1. THE WALK-SPEED POPS
--
-- How many whole WalkSpeed numbers a gain from `before` to `after` passed, and
-- the whole number it walks at now. A hair of slack under each integer, so an
-- anchor that lands at 21.9999999 still reads 22.
--==============================================================================
local function whole(score: number): number
	return math.floor(GameConfig.walkSpeedFor(score) + 1e-6)
end

function SpeedMilestones.walkGain(before: number, after: number): (number, number)
	local now = whole(after)
	return math.max(0, now - whole(before)), now
end

function SpeedMilestones.popWords(gained: number, now: number): string
	return string.format("+%d WALK SPEED \u{00B7} NOW %d", gained, now)
end

--==============================================================================
-- WHERE THE BAR AND THE POP STAND: CLEAR OF THE HUD (measured in Play, 2026-10-08)
--
-- Projected 11.5 studs over the belt, the bar came out at the very top of the
-- screen, behind the clock, whenever the camera was close. So the screen has
-- the last word: `r` (the bar with its badge, or the pop's words) goes to the
-- nearest place `gap` clear of every rect in `blocked` -- HudLayout's own
-- rects, and for the pop the bar too -- inside `bounds`. Going UP costs twice
-- going down or sideways, so what stands over the belt comes to rest UNDER the
-- top row, never in the topbar. nil only when `r` cannot fit in `bounds` or no
-- spot is clear; the caller then hides it. One space for every rect: the
-- caller's gui pixels.
--
-- THE NEAREST CLEAR SPOT, NOT THE FIRST WAY OUT: stepping out of one rect at a
-- time ran back and forth between two bands of the strip forever (800 of 1995
-- spots on that desktop hid the bar). The nearest clear spot always has each
-- edge where it was wanted, at a bound, or `gap` off some rect's edge, so
-- every such x and y is tried and the cheapest clear pair wins: at most a few
-- hundred cheap checks for the HUD's ~16 rects.
--==============================================================================
export type Rect = { x: number, y: number, w: number, h: number }

local function overlaps(a: Rect, b: Rect, gap: number): boolean
	return a.x < b.x + b.w + gap and b.x < a.x + a.w + gap and a.y < b.y + b.h + gap and b.y < a.y + a.h + gap
end

function SpeedMilestones.clearOf(r: Rect, blocked: { Rect }, bounds: Rect, gap: number): Rect?
	local w, h = r.w, r.h
	local loX, hiX = bounds.x, bounds.x + bounds.w - w
	local loY, hiY = bounds.y, bounds.y + bounds.h - h
	if hiX < loX or hiY < loY then
		return nil
	end
	local xs = { math.clamp(r.x, loX, hiX), loX, hiX }
	local ys = { math.clamp(r.y, loY, hiY), loY, hiY }
	for _, b in ipairs(blocked) do
		if b.w > 0 and b.h > 0 then
			table.insert(xs, b.x + b.w + gap)
			table.insert(xs, b.x - gap - w)
			table.insert(ys, b.y + b.h + gap)
			table.insert(ys, b.y - gap - h)
		end
	end
	local best: Rect? = nil
	local bestCost = math.huge
	for _, x in ipairs(xs) do
		local dx = math.abs(x - r.x)
		if x >= loX and x <= hiX and dx < bestCost then
			for _, y in ipairs(ys) do
				local dy = y - r.y
				local cost = dx + (if dy >= 0 then dy else -2 * dy)
				if y >= loY and y <= hiY and cost < bestCost then
					local here: Rect = { x = x, y = y, w = w, h = h }
					local clear = true
					for _, b in ipairs(blocked) do
						if b.w > 0 and b.h > 0 and overlaps(here, b, gap) then
							clear = false
							break
						end
					end
					if clear then
						best, bestCost = here, cost
					end
				end
			end
		end
	end
	return best
end

return SpeedMilestones
