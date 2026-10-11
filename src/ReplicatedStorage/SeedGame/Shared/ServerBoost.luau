--!strict
--==============================================================================
-- Steal a Seed :: ServerBoost (2026-10-12, the owner's item 9B)
--
-- THE RULES OF THE PRODUCTS BOUGHT FOR THE WHOLE SERVER, AND OF THE STARTER
-- PACK'S OFFER -- pure, one source for the server (ServerBoostService) and the
-- client (ShopUI). Nothing here reads a clock or an instance: callers pass
-- `now` (workspace:GetServerTimeNow(), or the server's os.time() for the
-- Starter Pack, the same clock to the second).
--
--   SERVER LUCK   a clock that stands still while the Enchanted Mist is on --
--                 the event's brief bans paid luck in it -- and what it is
--                 worth to a nest's roll (SeedData.Roll's `luck`)
--   SUMMON RAIN   what it would clash with, whether one may start, and what
--                 the Shop's button says while it may not
--   STARTER PACK  until when a profile is offered it
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local CFG = GameConfig.ServerBoost

local ServerBoost = {}

-- m:ss, or h:mm:ss past an hour.
function ServerBoost.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

--==============================================================================
-- SERVER LUCK
--
-- `left` is the seconds banked while it is NOT running (waiting out the Mist);
-- `endsAt` the time it ends while it runs. Exactly one of the two is live: a
-- running clock has left = 0, a paused one endsAt = nil. `total` is the whole
-- run so far (every purchase's seconds), for the chip's ring; `by` who bought
-- the latest of it.
--==============================================================================
export type Luck = {
	left: number,
	endsAt: number?,
	total: number,
	by: string,
}

function ServerBoost.newLuck(): Luck
	return { left = 0, endsAt = nil, total = 0, by = "" }
end

-- Seconds still to run at `now`, running or paused.
function ServerBoost.luckLeft(luck: Luck, now: number): number
	local endsAt = luck.endsAt
	if endsAt then
		return math.max(endsAt - now, 0)
	end
	return math.max(luck.left, 0)
end

-- A purchase: `seconds` more, on top of whatever is left. It runs at once,
-- unless the Mist is on (`paused`): then it is banked until the Mist ends. A
-- clock that had run out starts its ring afresh.
function ServerBoost.addLuck(luck: Luck, seconds: number, now: number, paused: boolean, by: string)
	local left = ServerBoost.luckLeft(luck, now)
	if left <= 0 then
		luck.total = 0
	end
	left += seconds
	luck.total += seconds
	luck.by = by
	if paused then
		luck.left, luck.endsAt = left, nil
	else
		luck.left, luck.endsAt = 0, now + left
	end
end

-- One step of the clock at `now`: it pauses as the Mist starts, runs on as it
-- ends, and is over when it runs out. Answers what it did -- "paused",
-- "resumed" or "ended" -- or nil.
function ServerBoost.stepLuck(luck: Luck, now: number, paused: boolean): string?
	local endsAt = luck.endsAt
	if endsAt then
		if now >= endsAt then
			luck.left, luck.endsAt, luck.total, luck.by = 0, nil, 0, ""
			return "ended"
		end
		if paused then
			luck.left, luck.endsAt = endsAt - now, nil
			return "paused"
		end
		return nil
	end
	if luck.left > 0 and not paused then
		luck.left, luck.endsAt = 0, now + luck.left
		return "resumed"
	end
	return nil
end

-- What it is worth to a nest's roll at `now`: Luck.Factor while it runs and
-- the Mist is not on, else 1.
function ServerBoost.luckFactor(luck: Luck, now: number, paused: boolean): number
	local endsAt = luck.endsAt
	return if endsAt and now < endsAt and not paused then CFG.Luck.Factor else 1
end

--==============================================================================
-- SUMMON RAIN
--==============================================================================
-- What a summon would clash with now: "rain" (weather in any state, the
-- Thunderstorm too), "mist" (the Enchanted Mist), "rush" (a Pod Rush), or nil.
function ServerBoost.rainClash(weather: boolean, mist: boolean, rush: boolean): string?
	if weather then
		return "rain"
	end
	if mist then
		return "mist"
	end
	if rush then
		return "rush"
	end
	return nil
end

-- Whether a summon may start at `now`: nothing clashes, and the last summon's
-- cooldown is over.
function ServerBoost.mayStartRain(clash: string?, readyAt: number, now: number): boolean
	return clash == nil and now >= readyAt
end

-- What the Shop's SUMMON RAIN button says while it may not be bought -- the
-- clash's word, else the cooldown's WAIT m:ss -- or nil while it may.
function ServerBoost.summonWord(clash: string?, readyAt: number, now: number): string?
	local words = CFG.Rain.Words
	if clash then
		return (words :: any)[clash] or words.rain
	end
	if now < readyAt then
		return string.format(words.cooldown, ServerBoost.clock(readyAt - now))
	end
	return nil
end

--==============================================================================
-- THE STARTER PACK'S OFFER
--==============================================================================
-- Until when (os.time) a profile is offered it: its first Starter.Days from
-- its first join (CreatedAt); 0 once it has one (`bought`), or with no date.
function ServerBoost.starterUntil(createdAt: number, bought: number): number
	if bought > 0 or createdAt <= 0 then
		return 0
	end
	return createdAt + CFG.Starter.Days * 86400
end

-- Whether the Shop shows it at `now`: still in the window, and the player may
-- hold a paid random item (its Spin Tickets: WheelData's PaidAllowed).
function ServerBoost.starterOffered(untilAt: number, now: number, paidAllowed: boolean): boolean
	return paidAllowed and untilAt > now
end

return ServerBoost
