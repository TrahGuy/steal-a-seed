--!strict
-- Steal a Seed :: PodRush (2026-10-09; KB/POD-RUSH-PLAN.md)
--
-- The pure half of the POD RUSH (GameConfig.PodRush): what counts, the three
-- levels and what each pays, the words, and where the tracker, the end card
-- and the rings under the nests stand. No clock and no instance: the server's
-- PodRushService and the client's PodRushUI both read it, and PodRushSpec
-- holds it.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SpeedMilestones = require(Shared:WaitForChild("SpeedMilestones"))

local CFG = GameConfig.PodRush
local LEVELS = CFG.Levels
local WORDS = CFG.Words

local PodRush = {}

-- One rush on one server, as far as counting goes: its start and its timer's
-- end (the shared record's), and when it stopped running here (the timer or an
-- END), nil while it runs.
export type Window = {
	startedAt: number,
	endsAt: number,
	closedAt: number?,
}

-- What one level pays, or all of them up to one.
export type Reward = {
	spins: number,
	boost: string?,
	podTier: number?,
}

local function whole(n: any): number
	return if type(n) == "number" and n == n and n >= 0 and n < 2 ^ 31 then math.floor(n) else 0
end

--==============================================================================
-- THE LEVELS
--==============================================================================
-- The level a count has reached: 0 for none, else its index in Levels.
function PodRush.levelFor(count: number): number
	local n = whole(count)
	local level = 0
	for i, row in ipairs(LEVELS) do
		if n >= row.Pods then
			level = i
		end
	end
	return level
end

-- The next level and how many more pods it needs; nil and 0 past the last.
function PodRush.nextLevel(count: number): (number?, number)
	local n = whole(count)
	for i, row in ipairs(LEVELS) do
		if n < row.Pods then
			return i, row.Pods - n
		end
	end
	return nil, 0
end

-- The levels a player who has been paid up to `paid` is owed at `level`, in
-- order: each pays once per rush, however many one bank reaches at once.
function PodRush.toPay(paid: number, level: number): { number }
	local out = {}
	for i = whole(paid) + 1, math.min(whole(level), #LEVELS) do
		table.insert(out, i)
	end
	return out
end

-- What one level pays.
function PodRush.reward(level: number): Reward
	local row: any = LEVELS[level]
	if not row then
		return { spins = 0 }
	end
	return { spins = whole(row.Spins), boost = row.Boost, podTier = row.PodTier }
end

-- What every level up to `level` paid altogether: the spins added up, the
-- boost and the pod if any of them gave one.
function PodRush.rewardsUpTo(level: number): Reward
	local total: Reward = { spins = 0 }
	for i = 1, math.min(whole(level), #LEVELS) do
		local r = PodRush.reward(i)
		total.spins += r.spins
		total.boost = r.boost or total.boost
		total.podTier = r.podTier or total.podTier
	end
	return total
end

-- The level's id and name ("silver", "SILVER"); "none" and the no-level words
-- for 0.
function PodRush.levelId(level: number): string
	local row: any = LEVELS[level]
	return if row then row.Id else "none"
end

function PodRush.levelName(level: number): string
	local row: any = LEVELS[level]
	return if row then row.Name else WORDS.NoLevel
end

-- The medal picture of a level (GameConfig.PodRush.Art: Bronze, Silver,
-- Gold), "" for none.
function PodRush.medal(level: number): string
	local row: any = LEVELS[level]
	if not row then
		return ""
	end
	local art: any = CFG.Art
	return art[string.upper(string.sub(row.Id, 1, 1)) .. string.sub(row.Id, 2)] or ""
end

--==============================================================================
-- GOLD PODS STILL OWED (ProfileSchema PodRush.PodOwed)
--
-- Biome ids, oldest first, joined by commas -- a string, so the saved row
-- stays flat -- at most MaxOwed of them. Given one at a time, the oldest
-- first, so a second pod won while the first waits for room is never lost.
--==============================================================================
function PodRush.owedList(s: any): { string }
	local out = {}
	if type(s) ~= "string" then
		return out
	end
	for id in string.gmatch(s, "[^,]+") do
		if #out < CFG.MaxOwed then
			table.insert(out, id)
		end
	end
	return out
end

function PodRush.owedString(list: { string }): string
	return table.concat(list, ",", 1, math.min(#list, CFG.MaxOwed))
end

--==============================================================================
-- WHAT COUNTS
--
-- A pod TAKEN FROM A NEST while the rush ran -- CarryService stamps the server
-- time of a nest theft on the pod in the arms, and never on a pod picked back
-- up after a drop -- banked no later than GraceSeconds after the rush stopped
-- running. A pod in the arms from before the rush never counts, and neither
-- does one taken after it stopped.
--==============================================================================
function PodRush.counts(window: Window, stolenAt: number?, now: number): boolean
	if type(stolenAt) ~= "number" or stolenAt ~= stolenAt then
		return false
	end
	local stopped = window.closedAt or window.endsAt
	if stolenAt < window.startedAt or stolenAt > stopped then
		return false
	end
	return now <= stopped + CFG.GraceSeconds
end

--==============================================================================
-- THE WORDS
--==============================================================================
local function plural(n: number): string
	return if n == 1 then "" else "s"
end

-- m:ss, never below 0:00.
function PodRush.clock(seconds: number): string
	local s = math.max(0, math.ceil(if seconds == seconds then seconds else 0))
	return string.format("%d:%02d", s // 60, s % 60)
end

function PodRush.bankedLine(count: number): string
	return string.format(WORDS.Banked, whole(count))
end

-- "2 more for SILVER", or the words past GOLD.
function PodRush.nextLine(count: number): string
	local level, need = PodRush.nextLevel(count)
	if not level then
		return WORDS.Top
	end
	return string.format(WORDS.ToNext, need, PodRush.levelName(level))
end

-- What a reward says, a line each: the spins, the boost, the pod (`biome` is
-- the pod's biome's display name, when it is known).
function PodRush.rewardLines(r: Reward, biome: string?): { string }
	local lines = {}
	if r.spins > 0 then
		table.insert(lines, string.format(WORDS.Spins, r.spins, plural(r.spins)))
	end
	if r.boost then
		local reward = GameConfig.bonusChestReward(r.boost)
		local percent = if reward then math.floor((reward.Multiplier - 1) * 100 + 0.5) else 0
		table.insert(lines, string.format(WORDS.Boost, percent,
			math.floor(GameConfig.BonusChest.BoostSeconds / 60 + 0.5)))
	end
	if r.podTier then
		local words = string.format(WORDS.Pod, biome or "")
		table.insert(lines, (string.gsub(words, "  ", " ")))
	end
	return lines
end

-- The end card's line: "9 pods · SILVER!", or "2 pods · no level".
function PodRush.overLine(count: number, level: number): string
	local n = whole(count)
	local tail = if level > 0 then string.format(WORDS.LevelUp, PodRush.levelName(level)) else WORDS.NoLevel
	return string.format(WORDS.OverCount, n, plural(n)) .. " \u{00B7} " .. tail
end

-- The line everybody else in the server reads when somebody reaches GOLD.
function PodRush.serverLine(name: string): string
	return string.format(WORDS.ServerLine, name)
end

--==============================================================================
-- WHERE THE TRACKER STANDS
--
-- Under the top row's status, notice and boost bands, on the screen's middle,
-- or the nearest spot clear of everything the HUD has -- HudLayout.occupied,
-- the three bands, the clock, ADMIN and the run's slot -- by Tracker.Gap,
-- inside the safe area less the same gap. Safe space, like HudLayout's rects;
-- the clock and ADMIN are inset-ignoring, so they are lifted by `insetTop`
-- first. `scale` is what the screen draws the tracker at (PhoneScale on a
-- phone). Where the whole tracker finds no clear spot it is the one-line
-- STRIP (Tracker.StripWidth x StripHeight, drawn 1:1), and where that finds
-- none the MINI strip (MiniWidth: the time and the pods banked), placed by the
-- same rule. Answers the rect and which it is ("full", "strip" or "mini"); nil
-- when none fits -- PodRushSpec holds that a listed screen always has one.
--==============================================================================
PodRush.Layouts = { "full", "strip", "mini" }

function PodRush.trackerSize(scale: number, layout: string?): Vector2
	local T = CFG.Tracker
	if layout == "strip" then
		return Vector2.new(T.StripWidth, T.StripHeight)
	elseif layout == "mini" then
		return Vector2.new(T.MiniWidth, T.StripHeight)
	end
	return Vector2.new(T.Width * scale, T.Height * scale)
end

-- `guide` while the beginner's guide card stands under the top row
-- (TutorialUI: HudLayout's banner and its SKIP), seen in Play 2026-10-09 with
-- the tracker over it.
function PodRush.blocked(L: any, insetTop: number, guide: boolean?): { SpeedMilestones.Rect }
	local out: { SpeedMilestones.Rect } = {}
	local function add(r: any, lift: number?)
		if r and r.w > 0 and r.h > 0 then
			table.insert(out, { x = r.x, y = r.y - (lift or 0), w = r.w, h = r.h })
		end
	end
	for _, r in ipairs(HudLayout.occupied(L)) do
		add(r)
	end
	local status, notice, boosts = HudLayout.statusRows(L, insetTop)
	add(status)
	add(notice)
	add(boosts)
	add(L.clock, insetTop)
	add(L.admin, insetTop)
	add(L.run)
	if guide then
		add(L.banner)
		add(L.skip)
	end
	return out
end

function PodRush.trackerRect(L: any, insetTop: number, scale: number, guide: boolean?): (SpeedMilestones.Rect?, string?)
	local gap = CFG.Tracker.Gap
	local _, _, boosts = HudLayout.statusRows(L, insetTop)
	local blocked = PodRush.blocked(L, insetTop, guide)
	local bounds = { x = gap, y = gap, w = L.safe.X - gap * 2, h = L.safe.Y - gap * 2 }
	for _, layout in ipairs(PodRush.Layouts) do
		local size = PodRush.trackerSize(scale, layout)
		local wanted = {
			x = L.safe.X / 2 - size.X / 2,
			y = boosts.y + boosts.h + gap,
			w = size.X,
			h = size.Y,
		}
		local spot = SpeedMilestones.clearOf(wanted, blocked, bounds, gap)
		if spot then
			return spot, layout
		end
	end
	return nil, nil
end

-- The strip's one line: the time (or BANK IT! and the grace left) in gold or
-- red, then the pods banked and -- unless `short` (the mini strip) -- the next
-- goal. RichText.
function PodRush.stripLine(count: number, timeLeft: number, bankIt: boolean, short: boolean?): string
	local head = if bankIt
		then string.format('<font color="#%s">%s %s</font>', CFG.Tracker.BankItColour:ToHex(), WORDS.BankIt,
			PodRush.clock(timeLeft))
		else string.format('<font color="#%s">%s</font>', CFG.Ring.Colour:ToHex(), PodRush.clock(timeLeft))
	if short then
		return string.format("%s  %s", head, PodRush.bankedLine(count))
	end
	return string.format("%s  %s \u{00B7} %s", head, PodRush.bankedLine(count), PodRush.nextLine(count))
end

-- Where the end card stands and its scale (2026-10-09, the owner: lift it so
-- its last line clears the hotbar on every phone -- on the 705 x 338 one TAP TO
-- CLOSE stood over slots 3-4). Centred across the safe width, in the room from
-- Margin under the safe area's top to Margin over the hotbar's top, and as large
-- as fits there, never over 1: 0.87 on 705 x 338, whole on desktops. Answers
-- its centre in safe space and the scale. `L` is a HudLayout answer.
--
-- And 8 px clear of the beginner's guide card while it shows (`guide`; seen in
-- Play on that phone: the card's title on the guide's words): the nearest place
-- in that room that is (SpeedMilestones.clearOf) -- at the same scale, else as
-- large as fits beside the guide's card while TAP TO CLOSE (12 px) still draws
-- at 10 or more (the 640-px phones: 0.85) -- else centred after all.
local END_HINT, END_HINT_FLOOR = 12, 10
function PodRush.endCard(L: any, guide: boolean?): (Vector2, number)
	local E = CFG.EndCard
	local safe: Vector2 = L.safe
	local top, bottom = E.Margin, L.hotbar.y - E.Margin
	local k = math.max(0, math.min(1, (safe.X - E.Margin * 2) / E.Width, (bottom - top) / E.Height))
	local centre = Vector2.new(safe.X / 2, (top + bottom) / 2)
	if guide and L.banner and L.banner.w > 0 then
		local G = HudLayout.Config.Gap
		local room = { x = E.Margin, y = top, w = safe.X - E.Margin * 2, h = bottom - top }
		local guideRight = math.max(L.banner.x + L.banner.w, L.skip.x + L.skip.w) + G
		for _, s in ipairs({ k, math.min(k, (safe.X - E.Margin - guideRight) / E.Width) }) do
			if s * END_HINT >= END_HINT_FLOOR then
				local w, h = E.Width * s, E.Height * s
				local want = { x = centre.X - w / 2, y = centre.Y - h / 2, w = w, h = h }
				local found = SpeedMilestones.clearOf(want, { L.banner, L.skip }, room, G)
				if found then
					return Vector2.new(found.x + w / 2, found.y + h / 2), s
				end
			end
		end
	end
	return centre, k
end

--==============================================================================
-- THE RING UNDER A NEST
--
-- Segments flat bars round the pods' own ring, each a chord of it laid just
-- above the ground (the client builds them; nothing collides or is queried).
-- Answers each bar's CFrame and size, its length along its own X.
--==============================================================================
function PodRush.ring(centre: Vector3): { { cframe: CFrame, size: Vector3 } }
	local R = CFG.Ring
	local out = {}
	local n = math.max(3, math.floor(R.Segments))
	local chord = 2 * R.Radius * math.sin(math.pi / n)
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local at = centre + Vector3.new(math.sin(a) * R.Radius, R.Thickness / 2 + 0.05, math.cos(a) * R.Radius)
		table.insert(out, {
			cframe = CFrame.new(at) * CFrame.Angles(0, a, 0),
			size = Vector3.new(chord + 0.2, R.Thickness, R.Width),
		})
	end
	return out
end

return PodRush
