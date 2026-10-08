--!strict
--==============================================================================
-- THE CATCH GAME ON THE BELT (TREADMILL FUN, the owner's brief, 2026-10-08) --
-- data and pure rules only.
--
-- While a player stands on their OWN belt, every 8-12 s one item floats toward
-- them along it at jump height -- from the console end, past them, off the back.
-- Jumping as it passes catches it. A miss drifts away: no penalty, nothing
-- required, and an AFK player simply catches nothing.
--
--   SEED COIN       most items: cash worth 15 s of their garden income, never
--                   under a small floor so a brand-new player still gets some
--   GOLDEN TICKET   about 1 in 8: one free spin, at most ONE PER ROLLING 24 h
--                   (WheelData.Daily's pattern, its own window). Once used, or
--                   with no room on the earned balance, only coins come.
--
-- THE SERVER DECIDES EVERYTHING (TreadmillFunService): when an item comes, what
-- it is, and whether it was caught -- from the character's replicated position
-- against the belt's top face in the item's pass, with a latency allowance. The
-- client only draws it and never claims anything. The belt's Speed rate is not
-- touched by any of it.
--==============================================================================

local BeltCatch = {}

BeltCatch.GapSeconds = { Min = 8, Max = 12 }
BeltCatch.TicketChance = 1 / 8
BeltCatch.TicketWindowSeconds = 24 * 60 * 60
BeltCatch.TicketsPerWindow = 1
-- A coin: this many seconds of the garden's income, never under the floor
-- (proposed for the owner: $10, so the first coin of a new player is not $0).
BeltCatch.CoinSeconds = 15
BeltCatch.CoinFloor = 10

--==============================================================================
-- THE PATH, IN THE BELT'S OWN FRAME
--
-- A player on the mill faces the belt's LookVector (-Z: the console end), so an
-- item that comes TOWARD them starts in front of them and leaves behind them.
-- It rides Height studs over the belt's top face -- over a standing head,
-- inside a jump.
--
-- WHERE IT MAY RUN WAS MEASURED, NOT ASSUMED (2026-10-08): swept through all
-- fourteen tiers on all six plots, a path from the console end hit Inferno
-- Forge's skull, Astral Singularity's hologram, Abyssal Trench's lure and Event
-- Horizon's disks -- all hung over the FRONT of the belt between 4.7 and 9
-- studs out -- and one along the belt's sides hit Heartroot's banners at 2.2
-- across. So it starts StartShare of the half-length in front of the middle
-- (3.4 studs on a 16-stud belt), ends Inset inside the back, and keeps within
-- Lateral studs of the centre line. TreadmillFunSpec sweeps it the same way.
--==============================================================================
BeltCatch.Height = 6.2
BeltCatch.StartShare = 0.42
BeltCatch.Inset = 1.6
BeltCatch.Lateral = 0.8
BeltCatch.TravelSeconds = 3.2
-- How big an item is drawn (studs across), and the radius the sweep keeps clear.
BeltCatch.DrawStuds = 2.2
BeltCatch.ClearRadius = 1.1

--==============================================================================
-- WHAT COUNTS AS A CATCH
--
-- The root, at the moment the item is there, within Along studs of it along the
-- belt and Across studs across it, and RISEN at least Rise studs above where it
-- stands on this belt (its HipHeight and half its own height over the top
-- face). A real jump peaks about seven studs up; walking, standing and a small
-- bump never reach Rise. The server reads a replicated position, so the item's
-- position is tested at now AND LatencySeconds ago: a jump the client made on
-- time is still a catch when its position arrives late.
--==============================================================================
BeltCatch.Rise = 1.6
BeltCatch.Along = 2.6
BeltCatch.Across = 2.6
BeltCatch.LatencySeconds = 0.35

-- The art and the sounds (the owner's SEED COIN; the game's own ticket picture,
-- GameConfig.SourceIcons.tickets; existing cues only).
BeltCatch.Art = { Coin = "rbxassetid://97002362837712" }
BeltCatch.Sounds = { Coin = "CashTick", Ticket = "InviteBadgePop" }

--==============================================================================
-- TIMING, KIND, CAP, PRICE
--==============================================================================
function BeltCatch.nextGap(rng: Random): number
	local g = BeltCatch.GapSeconds
	return g.Min + rng:NextNumber() * (g.Max - g.Min)
end

-- Whether a golden ticket may come: the window (opened by the first ticket,
-- running whether or not they play) has room, or has closed.
function BeltCatch.ticketAvailable(windowAt: number, count: number, now: number): boolean
	local at = tonumber(windowAt) or 0
	if at <= 0 or now >= at + BeltCatch.TicketWindowSeconds then
		return true
	end
	return (tonumber(count) or 0) < BeltCatch.TicketsPerWindow
end

-- How many belt tickets the CURRENT window has given (0 once it has closed).
function BeltCatch.ticketsToday(windowAt: number, count: number, now: number): number
	local at = tonumber(windowAt) or 0
	if at <= 0 or now >= at + BeltCatch.TicketWindowSeconds then
		return 0
	end
	return math.max(0, math.floor(tonumber(count) or 0))
end

-- "BELT TICKET 0/1 TODAY"
function BeltCatch.capWords(today: number): string
	return string.format("BELT TICKET %d/%d TODAY", math.min(today, BeltCatch.TicketsPerWindow),
		BeltCatch.TicketsPerWindow)
end

function BeltCatch.rollKind(rng: Random, ticketAllowed: boolean): string
	if ticketAllowed and rng:NextNumber() < BeltCatch.TicketChance then
		return "ticket"
	end
	return "coin"
end

function BeltCatch.coinCash(incomePerSecond: number): number
	local income = tonumber(incomePerSecond) or 0
	if income ~= income or income < 0 then
		income = 0
	end
	return math.max(BeltCatch.CoinFloor, math.floor(income * BeltCatch.CoinSeconds))
end

--==============================================================================
-- THE PATH AND THE CATCH
--==============================================================================
-- The item's start and end, in world space, on the line across from `lateral`
-- (the player's own X on this belt, kept within Lateral of the centre line).
function BeltCatch.path(beltCF: CFrame, beltSize: Vector3, lateral: number?): (Vector3, Vector3)
	local half = beltSize * 0.5
	local x = math.clamp(tonumber(lateral) or 0, -BeltCatch.Lateral, BeltCatch.Lateral)
	local y = half.Y + BeltCatch.Height
	local from = beltCF:PointToWorldSpace(Vector3.new(x, y, -half.Z * BeltCatch.StartShare))
	local to = beltCF:PointToWorldSpace(Vector3.new(x, y, half.Z - BeltCatch.Inset))
	return from, to
end

-- Where an item is at server time `t` (clamped to its flight).
function BeltCatch.positionAt(from: Vector3, to: Vector3, startsAt: number, endsAt: number, t: number): Vector3
	local span = endsAt - startsAt
	local u = if span > 0 then math.clamp((t - startsAt) / span, 0, 1) else 1
	return from:Lerp(to, u)
end

-- The height a root stands at over the belt's top face: the humanoid's own.
function BeltCatch.standingHeight(hipHeight: number, rootHeight: number): number
	return (tonumber(hipHeight) or 2) + (tonumber(rootHeight) or 2) * 0.5
end

-- Is a root at `root` (world) catching an item at `item` (world), on a belt at
-- `beltCF` of `beltSize`, for a body that stands `standing` studs over the top?
function BeltCatch.reaches(beltCF: CFrame, beltSize: Vector3, standing: number, item: Vector3, root: Vector3): boolean
	local half = beltSize * 0.5
	local i = beltCF:PointToObjectSpace(item)
	local r = beltCF:PointToObjectSpace(root)
	if math.abs(i.Z - r.Z) > BeltCatch.Along or math.abs(i.X - r.X) > BeltCatch.Across then
		return false
	end
	return (r.Y - half.Y) - standing >= BeltCatch.Rise
end

-- The server's question at time `t`: the item now, or where it was a moment
-- ago (the latency allowance), against the root it has now.
function BeltCatch.caught(beltCF: CFrame, beltSize: Vector3, standing: number, from: Vector3, to: Vector3,
	startsAt: number, endsAt: number, t: number, root: Vector3): boolean
	for _, back in { 0, BeltCatch.LatencySeconds * 0.5, BeltCatch.LatencySeconds } do
		local at = t - back
		if at >= startsAt and at <= endsAt then
			if BeltCatch.reaches(beltCF, beltSize, standing, BeltCatch.positionAt(from, to, startsAt, endsAt, at), root) then
				return true
			end
		end
	end
	return false
end

return BeltCatch
