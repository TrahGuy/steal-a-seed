--!strict
--==============================================================================
-- Steal a Seed :: SproutDash (2026-10-08)
--
-- The mill's minigame, its rules alone (GameConfig.SproutDash): the course a
-- seed makes, one fixed step of the sprout, a whole run replayed from the ticks
-- it hopped on, what a distance pays and the caps on it, and the checks the
-- server runs on what a client sends.
--
-- PURE. Numbers in, tables out: no Instances, no clock, no player. The client
-- steps it to draw a run; the server replays it to count one -- the same
-- steps in the same order, so the same answer: + - * / and bit32 only, no
-- trigonometry, no engine random (a 32-bit xorshift), so a phone, a PC and
-- the server agree to the bit.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local CFG = GameConfig.SproutDash
local COURSE = CFG.Course
local BOOST = CFG.Boost

local SproutDash = {}

SproutDash.Hz = CFG.Hz
local DT = 1 / CFG.Hz
SproutDash.DT = DT
SproutDash.MaxTicks = CFG.MaxSeconds * CFG.Hz
local KINDS = { "rock", "weed", "log" }

--==============================================================================
-- THE COURSE, FROM A SEED, A CHUNK AT A TIME
--
-- Chunk `i` covers [i * Chunk, (i + 1) * Chunk) metres and is made from the
-- run's seed mixed with `i` alone, so the client can draw ahead and the server
-- can look anywhere without making the course in between. Past Lead every
-- chunk holds one obstacle in [Edge, Chunk - Edge] -- two are never closer
-- than 2 * Edge -- and three seed coins: an arc over it, or a line on the
-- ground before it. The first chunk is a line of coins to learn on.
--==============================================================================
export type Obstacle = { id: number, kind: string, x: number, w: number, h: number }
export type Coin = { id: number, x: number, y: number }
export type Chunk = { obstacles: { Obstacle }, coins: { Coin } }

-- One step of a 32-bit xorshift: the next state, and it as a fraction [0, 1).
local function nextRandom(s: number): (number, number)
	local x = s
	x = bit32.bxor(x, bit32.lshift(x, 13))
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.bxor(x, bit32.lshift(x, 5))
	if x == 0 then
		x = 0x6D2B79F5
	end
	return x, x / 4294967296
end
SproutDash.nextRandom = nextRandom

local function chunkSeed(seed: number, index: number): number
	local s = bit32.bxor(bit32.band(seed, 0xFFFFFFFF), bit32.band(index * 0x9E3779B1 + 0x7F4A7C15, 0xFFFFFFFF))
	if s == 0 then
		s = 0x2545F491
	end
	-- Stir, so neighbouring chunks share nothing.
	for _ = 1, 3 do
		s = (nextRandom(s))
	end
	return s
end

function SproutDash.chunk(seed: number, index: number): Chunk
	local out: Chunk = { obstacles = {}, coins = {} }
	if index < 0 then
		return out
	end
	local start = index * COURSE.Chunk
	local s, r = chunkSeed(seed, index), 0
	local function coin(n: number, x: number, y: number)
		table.insert(out.coins, { id = index * 10 + n, x = x, y = y })
	end
	s, r = nextRandom(s)
	local x = start + COURSE.Edge + r * (COURSE.Chunk - 2 * COURSE.Edge)
	if x >= COURSE.Lead then
		s, r = nextRandom(s)
		local kind = KINDS[math.min(3, math.floor(r * 3) + 1)]
		local spec = CFG.Obstacles[kind]
		table.insert(out.obstacles, { id = index, kind = kind, x = x, w = spec.W, h = spec.H })
		s, r = nextRandom(s)
		if r < 0.5 then
			-- An arc over it, on a hop's path.
			coin(1, x - 1.6, 1.7)
			coin(2, x, 2.3)
			coin(3, x + 1.6, 1.7)
		else
			-- A line on the ground before it.
			coin(1, x - 7.5, 0.5)
			coin(2, x - 6, 0.5)
			coin(3, x - 4.5, 0.5)
		end
	elseif index == 0 then
		coin(1, 16, 0.5)
		coin(2, 18, 0.5)
		coin(3, 20, 0.5)
	end
	return out
end

--==============================================================================
-- ONE FIXED STEP
--==============================================================================
export type State = {
	seed: number,
	tick: number,
	x: number,
	y: number,
	vy: number,
	lives: number,
	coins: number,
	hits: number,
	graceUntil: number,
	over: boolean,
	taken: { [number]: boolean },
	struck: { [number]: boolean },
	chunks: { [number]: Chunk },
}

function SproutDash.new(seed: number): State
	return {
		seed = seed,
		tick = 0,
		x = 0,
		y = 0,
		vy = 0,
		lives = CFG.Lives,
		coins = 0,
		hits = 0,
		graceUntil = 0,
		over = false,
		taken = {},
		struck = {},
		chunks = {},
	}
end

-- The belt's speed at a tick: Start, ramping by Ramp a second, never past Top.
function SproutDash.speedAt(tick: number): number
	return math.min(CFG.Top, CFG.Start + CFG.Ramp * tick * DT)
end

function SproutDash.grounded(state: State): boolean
	return state.y <= 0 and state.vy <= 0
end

-- The chunk, made once a run.
function SproutDash.chunkOf(state: State, index: number): Chunk
	local made = state.chunks[index]
	if not made then
		made = SproutDash.chunk(state.seed, index)
		state.chunks[index] = made
		-- Behind the sprout: dropped, so a long run keeps a handful.
		state.chunks[index - 3] = nil
	end
	return made
end

local function overlaps(ax0: number, ax1: number, bx0: number, bx1: number): boolean
	return ax0 < bx1 and bx0 < ax1
end

export type Events = { hopped: boolean, coins: { Coin }, hit: Obstacle?, over: boolean }

-- One step of 1 / Hz. `hop`: the player asked this tick -- honoured only on the
-- ground. Moves, lands, then meets what is there: a coin once, an obstacle once
-- and only outside the grace after a hit. Answers what happened.
function SproutDash.step(state: State, hop: boolean): Events
	local events: Events = { hopped = false, coins = {}, hit = nil, over = false }
	if state.over then
		return events
	end
	if hop and SproutDash.grounded(state) then
		state.vy = CFG.Hop
		events.hopped = true
	end
	state.x += SproutDash.speedAt(state.tick) * DT
	state.y += state.vy * DT
	state.vy -= CFG.Gravity * DT
	if state.y <= 0 then
		state.y = 0
		state.vy = 0
	end
	state.tick += 1

	local half = CFG.Runner.W / 2
	local x0, x1 = state.x - half, state.x + half
	local y0, y1 = state.y, state.y + CFG.Runner.H
	local here = math.floor(state.x / COURSE.Chunk)
	for index = here - 1, here + 1 do
		local chunk = SproutDash.chunkOf(state, index)
		for _, c in ipairs(chunk.coins) do
			local r = COURSE.CoinR
			if not state.taken[c.id] and overlaps(x0, x1, c.x - r, c.x + r) and overlaps(y0, y1, c.y - r, c.y + r) then
				state.taken[c.id] = true
				state.coins += 1
				table.insert(events.coins, c)
			end
		end
		for _, o in ipairs(chunk.obstacles) do
			if not state.struck[o.id] and state.tick >= state.graceUntil and y0 < o.h
				and overlaps(x0, x1, o.x - o.w / 2, o.x + o.w / 2) then
				state.struck[o.id] = true
				state.hits += 1
				state.lives -= 1
				state.graceUntil = state.tick + math.floor(CFG.HitGrace * CFG.Hz + 0.5)
				events.hit = o
				if state.lives <= 0 then
					state.over = true
					events.over = true
				end
			end
		end
	end
	return events
end

-- The distance a state has run, as it is shown and paid: whole metres.
function SproutDash.distance(state: State): number
	return math.floor(state.x)
end

--==============================================================================
-- A RUN, REPLAYED (the server's count)
--
-- `hops`: the ticks the client hopped on, strictly increasing, each a tick the
-- sprout stood on the ground; `endTick`: where the client's run stopped -- its
-- third hit, or the player closing it. The server steps the whole run itself
-- and counts what IT sees. Refused (and nothing paid) for a list that is not
-- whole ticks, not in order, longer than MaxSeconds, a hop in the air (a tick
-- the sprout could not have hopped on), or a hop after the run ended.
--==============================================================================
export type Result = {
	ok: boolean,
	why: string?,
	distance: number,
	coins: number,
	hits: number,
	ticks: number,
	over: boolean,
}

local function refused(why: string): Result
	return { ok = false, why = why, distance = 0, coins = 0, hits = 0, ticks = 0, over = false }
end

local function whole(v: any): boolean
	return type(v) == "number" and v == v and v >= 0 and v < math.huge and math.floor(v) == v
end

function SproutDash.replay(seed: any, hops: any, endTick: any): Result
	if not whole(seed) or not whole(endTick) or type(hops) ~= "table" then
		return refused("MALFORMED")
	end
	if endTick > SproutDash.MaxTicks then
		return refused("TOO_LONG")
	end
	-- A hop needs the ground under it: at most one a hop's airtime.
	if #hops > endTick / math.floor(2 * CFG.Hop / CFG.Gravity * CFG.Hz) + 1 then
		return refused("TOO_MANY_HOPS")
	end
	local last = -1
	for i, t in ipairs(hops) do
		if not whole(t) or t <= last or t >= endTick then
			return refused("MALFORMED")
		end
		last = t
		if i > 4000 then
			return refused("TOO_MANY_HOPS")
		end
	end
	local state = SproutDash.new(seed)
	local h = 1
	while state.tick < endTick and not state.over do
		local want = hops[h] == state.tick
		if want then
			if not SproutDash.grounded(state) then
				return refused("AIR_HOP")
			end
			h += 1
		end
		SproutDash.step(state, want)
	end
	if hops[h] ~= nil then
		return refused("AFTER_END")
	end
	return {
		ok = true,
		why = nil,
		distance = SproutDash.distance(state),
		coins = state.coins,
		hits = state.hits,
		ticks = state.tick,
		over = state.over,
	}
end

-- The wall clock's check: a run's sim time can never be more than the time
-- between the server's start and its finish, and FinishSlack of network.
function SproutDash.timely(endTick: number, elapsed: number): boolean
	return endTick * DT <= elapsed + CFG.FinishSlack
end

--==============================================================================
-- THE REWARD: +25% TRAINING, BY DISTANCE, CAPPED
--==============================================================================
-- The minutes a distance earns: the highest tier reached, 0 below the first.
function SproutDash.minutesFor(distance: number): number
	local best = 0
	for _, tier in ipairs(BOOST.Tiers) do
		if distance >= tier.Distance then
			best = tier.Minutes
		end
	end
	return best
end

-- The first tier's distance, for "run N m for a boost".
function SproutDash.firstTier(): number
	return BOOST.Tiers[1].Distance
end

export type Earned = { At: number, Seconds: number }

-- What a run's minutes become under the caps: at most HourMax s earned in the
-- last hour and BankMax s banked. Answers the seconds granted, the boost's new
-- end, the earned log as it now stands (an hour of it), and which cap cut it
-- ("hour", "bank" or nil).
function SproutDash.grant(minutes: number, endsAt: number, earned: { Earned }, now: number):
	(number, number, { Earned }, string?)
	local kept: { Earned } = {}
	local inHour = 0
	for _, e in ipairs(earned) do
		if type(e) == "table" and whole(e.At) and whole(e.Seconds) and now - e.At < 3600 then
			table.insert(kept, { At = e.At, Seconds = e.Seconds })
			inHour += e.Seconds
		end
	end
	local want = math.max(0, math.floor(minutes) * 60)
	local cut: string? = nil
	local seconds = want
	local hourLeft = math.max(0, BOOST.HourMax - inHour)
	if seconds > hourLeft then
		seconds = hourLeft
		cut = "hour"
	end
	local banked = math.max(0, endsAt - now)
	local bankLeft = math.max(0, BOOST.BankMax - banked)
	if seconds > bankLeft then
		seconds = bankLeft
		cut = "bank"
	end
	if seconds <= 0 then
		return 0, endsAt, kept, if want > 0 then cut else nil
	end
	table.insert(kept, { At = now, Seconds = seconds })
	return seconds, math.max(now, endsAt) + seconds, kept, cut
end

-- The boost's share of the mill's training while it runs: 0.25, else 0.
function SproutDash.bonusAt(endsAt: any, now: number): number
	if type(endsAt) == "number" and endsAt > now then
		return BOOST.Multiplier - 1
	end
	return 0
end

-- The day a time falls on, for "best today" (UTC days).
function SproutDash.day(now: number): number
	return math.floor(now / 86400)
end

return SproutDash
