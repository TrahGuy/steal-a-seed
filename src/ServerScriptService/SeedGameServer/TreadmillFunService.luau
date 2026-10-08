--!strict
--==============================================================================
-- Steal a Seed :: TreadmillFunService
-- TREADMILL FUN (the owner's brief, 2026-10-08): the Speed milestones' prizes and
-- the catch game on the belt. The pops and the bar are the client's
-- (TreadmillFunUI), drawn off the profile packet; this file pays and decides.
--
--==============================================================================
-- THE RULE THAT DOES NOT MOVE
--
-- The belt's Speed rate is untouched. Nothing here calls AddSpeed or multiplies
-- anything: milestones pay CASH (EconomyService.PayReward) or SPIN TICKETS
-- (WheelService), and so does the catch game.
--
--==============================================================================
-- A2. THE MILESTONES (SpeedMilestones)
--
-- PlayerDataService tells this file about every Speed gain, from any source. A
-- gain that passes milestones above the profile's mark moves the mark to the
-- highest one -- once, ever -- and, unless the Speed came from the admin or the
-- debug console, pays each of them: cash at twelve, one free spin at five, all
-- in ONE notice. A spin with no room on the earned balance is owed and paid the
-- next time there is room (MilestoneSpinsOwed).
--
--==============================================================================
-- B. THE CATCH GAME (BeltCatch)
--
-- Per player, on their OWN belt: an item every 8-12 s, coin or golden ticket,
-- floating from in front of them to behind them at jump height. The server
-- keeps the item and its record (a Configuration under Workspace.BeltItems,
-- MiniEventService's ticket pattern: the facts a client draws, stamped
-- CaughtBy on a catch, gone after); every tick it reads the owner's replicated
-- root against the item, with a latency allowance, and decides. Nothing a
-- client sends is read: there is no remote for it at all.
--
-- NEVER while carrying a pod, dead or respawning, off their own belt, on the
-- Disco Mill, or while a Ticket Disco / Ticket Shower mini event runs. An item
-- in flight when that becomes true is withdrawn, unpaid.
--
-- "ON THE BELT" IS TALLER HERE THAN THE MILL'S. The mill pays a root under 6.5
-- studs over its belt; a catch IS a jump, which peaks about ten. So an item in
-- flight asks its own question -- inside the belt's footprint and under
-- Ceiling -- and a jump never withdraws the item it is catching.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SpeedMilestones = require(Shared:WaitForChild("SpeedMilestones"))
local BeltCatch = require(Shared:WaitForChild("BeltCatch"))
local Notice = require(Shared:WaitForChild("Notice"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))

local TreadmillFunService = {}
-- After EconomyService (55), TreadmillService (60), WheelService (62) and
-- MiniEventService (66), all of which this calls.
TreadmillFunService.Priority = 68

local ATTR = GameConfig.Attributes
local EVENT = GameConfig.MiniEvent.Attributes
-- How often the catch game looks (s), and how high over its belt a root may be
-- for an item in flight to stay (a jump's peak is about 10).
local STEP = 0.05
local CEILING = 14
local EDGE_MARGIN = 1.5
-- The client draws the item at its start this long before it moves.
local LEAD = 0.5
-- The folder the records live in.
TreadmillFunService.FolderName = "BeltItems"

local running = false
local connections: { RBXScriptConnection } = {}
local unhookSpeed: (() -> ())? = nil
local channel: RemoteEvent? = nil
local rng = Random.new()

type Item = {
	id: number,
	player: Player,
	kind: string,
	from: Vector3,
	to: Vector3,
	startsAt: number,
	endsAt: number,
	belt: BasePart,
	standing: number,
	record: Configuration?,
}
local items: { [Player]: Item } = {}
local nextAt: { [Player]: number } = {}
local itemSeq = 0

--==============================================================================
-- SEAMS, FOR TreadmillFunSpec AND THE GUARDED PLAY (Studio only)
--==============================================================================
local clockFn: (() -> number)? = nil
local kindFn: ((Player) -> string?)? = nil
local tellFn: ((Player, { [string]: any }) -> ())? = nil

local function now(): number
	local fn = clockFn
	return if fn then fn() else Workspace:GetServerTimeNow()
end

function TreadmillFunService.SpecClock(fn: (() -> number)?)
	if RunService:IsStudio() then
		clockFn = fn
	end
end

-- The next item's kind, decided by the caller ("coin" / "ticket"), still subject
-- to the ticket cap. The guarded Play's way to show a golden ticket on demand.
function TreadmillFunService.SpecNextKind(fn: ((Player) -> string?)?)
	if RunService:IsStudio() then
		kindFn = fn
	end
end

-- What the player would be told, heard by a spec instead of the remote.
function TreadmillFunService.SpecTell(fn: ((Player, { [string]: any }) -> ())?)
	if RunService:IsStudio() then
		tellFn = fn
	end
end

local function log(message: string)
	print("[Seed/TreadmillFunService] " .. message)
end

local function tell(player: Player, payload: { [string]: any })
	local hook = tellFn
	if hook then
		hook(player, payload)
		return
	end
	local remote = channel
	if remote then
		pcall(function()
			remote:FireClient(player, Notice.ServerNotice, payload)
		end)
	end
end

--==============================================================================
-- A2. THE MILESTONES
--==============================================================================
local function payOwed(player: Player)
	local profile = PlayerDataService.Get(player) :: any
	local owed = if profile then tonumber(profile.MilestoneSpinsOwed) or 0 else 0
	if owed <= 0 then
		return
	end
	local landed = WheelService.GrantMilestoneSpins(player, owed, "Speed milestones owed")
	if landed > 0 then
		PlayerDataService.AddMilestoneSpinsOwed(player, -landed)
	end
end

local function onSpeedGained(player: Player, _before: number, after: number, source: string?)
	local profile = PlayerDataService.Get(player) :: any
	if not profile then
		return
	end
	payOwed(player)
	local crossed = SpeedMilestones.crossed(tonumber(profile.SpeedMilestone) or 0, after)
	if #crossed == 0 then
		return
	end
	local highest = crossed[#crossed]
	-- The mark first: whatever happens to the prizes, these are spent.
	PlayerDataService.SetSpeedMilestone(player, highest)
	if source == "admin" or source == "debug" then
		log(string.format("%s passed %d Speed milestone(s) up to %s by %s Speed: no prize.", player.Name, #crossed,
			SpeedMilestones.label(highest), source))
		return
	end
	local income = EconomyService.RateFor(player)
	local level = tonumber(profile.PlotTier) or 1
	local cash, tickets = 0, 0
	for _, m in ipairs(crossed) do
		if SpeedMilestones.isTicket(m) then
			tickets += SpeedMilestones.Tickets[m]
		else
			cash += SpeedMilestones.cashFor(m, income, level)
		end
	end
	if cash > 0 then
		EconomyService.PayReward(player, cash, "the " .. SpeedMilestones.label(highest) .. " Speed milestone")
	end
	if tickets > 0 then
		local landed = WheelService.GrantMilestoneSpins(player, tickets, "a Speed milestone")
		if landed < tickets then
			PlayerDataService.AddMilestoneSpinsOwed(player, tickets - landed)
		end
	end
	local title, detail = SpeedMilestones.noticeWords(highest, cash, tickets)
	tell(player, {
		title = title,
		detail = detail,
		key = "milestone:" .. tostring(highest),
		icon = if tickets > 0 then "tickets" else "milestone",
		-- The bar's celebration plays the milestone's own sound.
		quiet = true,
	})
	log(string.format("%s passed %s: %s.", player.Name, title, detail))
end

function TreadmillFunService.SpecSpeedGained(player: any, before: number, after: number, source: string?)
	if RunService:IsStudio() then
		onSpeedGained(player, before, after, source)
	end
end

--==============================================================================
-- B. THE CATCH GAME
--==============================================================================
local function itemFolder(): Instance
	local found = Workspace:FindFirstChild(TreadmillFunService.FolderName)
	if found and found:IsA("Folder") then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = TreadmillFunService.FolderName
	made.Archivable = false
	made.Parent = Workspace
	return made
end

local function ownBelt(player: Player): BasePart?
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		return nil
	end
	local plotId = plot:GetAttribute(ATTR.PlotId)
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") and belt.Parent and belt.Parent:GetAttribute(ATTR.PlotId) == plotId then
			return belt
		end
	end
	return nil
end

-- A Ticket Disco or a Ticket Shower is up: the belt's own tickets stand aside.
local function eventBlocks(): boolean
	local state = Workspace:GetAttribute(EVENT.State)
	if state ~= "running" and state ~= "ending" then
		return false
	end
	local mode = Workspace:GetAttribute(EVENT.Mode)
	return mode == "ticketdisco" or mode == "tickets"
end

-- Inside the belt's footprint and under `ceiling` over its top face.
local function over(belt: BasePart, root: BasePart, ceiling: number): boolean
	local p = belt.CFrame:PointToObjectSpace(root.Position)
	local half = belt.Size * 0.5
	if math.abs(p.X) > half.X + EDGE_MARGIN or math.abs(p.Z) > half.Z + EDGE_MARGIN then
		return false
	end
	local above = p.Y - half.Y
	return above > -1 and above < ceiling
end

-- Everything that must be true for the game to run for this player, or nil.
local function playing(player: Player, ceiling: number): (BasePart?, BasePart?, Humanoid?)
	if player.Parent ~= Players or not PlayerDataService.IsReady(player) then
		return nil, nil, nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		return nil, nil, nil
	end
	if CarryService.IsCarrying(player) or TreadmillService.OnDiscoMill(player) or eventBlocks() then
		return nil, nil, nil
	end
	local belt = ownBelt(player)
	if not (belt and over(belt, root :: BasePart, ceiling)) then
		return nil, nil, nil
	end
	return belt, root :: BasePart, humanoid
end

local function dropRecord(item: Item, caughtBy: number?, paid: number?)
	local record = item.record
	item.record = nil
	if not record then
		return
	end
	if caughtBy then
		record:SetAttribute("Paid", paid or 0)
		record:SetAttribute("CaughtBy", caughtBy)
		-- Long enough for the stamp to reach the client before the record goes.
		task.delay(0.6, function()
			record:Destroy()
		end)
	else
		record:Destroy()
	end
end

local function finish(player: Player, item: Item, t: number)
	if items[player] == item then
		items[player] = nil
	end
	nextAt[player] = t + BeltCatch.nextGap(rng)
end

local function withdraw(player: Player)
	local item = items[player]
	if item then
		items[player] = nil
		dropRecord(item)
	end
	nextAt[player] = nil
end

local function spawnItem(player: Player, belt: BasePart, root: BasePart, humanoid: Humanoid, t: number)
	local ticketOpen = WheelService.BeltTicketOpen(player)
	local asked = kindFn and kindFn(player)
	local kind = if asked == "ticket" or asked == "coin" then asked else BeltCatch.rollKind(rng, ticketOpen)
	if kind == "ticket" and not ticketOpen then
		kind = "coin"
	end
	local lateral = belt.CFrame:PointToObjectSpace(root.Position).X
	local from, to = BeltCatch.path(belt.CFrame, belt.Size, lateral)
	itemSeq += 1
	local startsAt = t + LEAD
	local item: Item = {
		id = itemSeq,
		player = player,
		kind = kind,
		from = from,
		to = to,
		startsAt = startsAt,
		endsAt = startsAt + BeltCatch.TravelSeconds,
		belt = belt,
		standing = BeltCatch.standingHeight(humanoid.HipHeight, root.Size.Y),
		record = nil,
	}
	local record = Instance.new("Configuration")
	record.Name = "B" .. tostring(itemSeq)
	record.Archivable = false
	record:SetAttribute("Owner", player.UserId)
	record:SetAttribute("Id", itemSeq)
	record:SetAttribute("Kind", kind)
	record:SetAttribute("From", from)
	record:SetAttribute("To", to)
	record:SetAttribute("StartsAt", item.startsAt)
	record:SetAttribute("EndsAt", item.endsAt)
	record.Parent = itemFolder()
	item.record = record
	items[player] = item
end

-- A catch: paid, stamped, and the next one scheduled.
local function catch(player: Player, item: Item, t: number)
	local paid = 0
	local kind = item.kind
	if kind == "ticket" then
		local ok, why = WheelService.GrantBeltTicket(player)
		if ok then
			tell(player, {
				title = "GOLDEN TICKET! +1 Spin Ticket",
				detail = BeltCatch.capWords(BeltCatch.TicketsPerWindow),
				key = "belt:ticket",
				icon = "tickets",
				quiet = true,
			})
			log(string.format("%s caught a golden ticket.", player.Name))
		else
			-- Raced past the cap or a full balance since it was sent: a coin.
			kind = "coin"
			log(string.format("%s's golden ticket became a coin (%s).", player.Name, tostring(why)))
		end
	end
	if kind == "coin" then
		paid = BeltCatch.coinCash(EconomyService.RateFor(player))
		if EconomyService.PayReward(player, paid, "a seed coin on the belt") then
			tell(player, {
				title = "SEED COIN! +$" .. GameConfig.compact(paid),
				key = "belt:coin",
				icon = "coin",
				quiet = true,
			})
		else
			paid = 0
		end
	end
	dropRecord(item, player.UserId, paid)
	finish(player, item, t)
end

local function step(t: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local item = items[player]
		if item then
			local belt, root = playing(player, CEILING)
			if not (belt and root) or belt ~= item.belt then
				withdraw(player)
			elseif BeltCatch.caught(item.belt.CFrame, item.belt.Size, item.standing, item.from, item.to,
				item.startsAt, item.endsAt, t, root.Position) then
				catch(player, item, t)
			elseif t > item.endsAt + BeltCatch.LatencySeconds then
				-- Missed: it drifts away.
				dropRecord(item)
				finish(player, item, t)
			end
		else
			-- Standing on it, as the mill means it, to be sent one.
			local belt, root, humanoid = playing(player, 6.5)
			if belt and root and humanoid then
				local due = nextAt[player]
				if not due then
					nextAt[player] = t + BeltCatch.nextGap(rng)
				elseif t >= due then
					spawnItem(player, belt, root, humanoid, t)
				end
			elseif not playing(player, CEILING) then
				nextAt[player] = nil
			end
		end
	end
end

function TreadmillFunService.SpecStep(t: number)
	if RunService:IsStudio() then
		step(t)
	end
end

function TreadmillFunService.SpecItem(player: any): Item?
	return if RunService:IsStudio() then items[player] else nil
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function TreadmillFunService.Init()
	running = false
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	if unhookSpeed then
		unhookSpeed()
		unhookSpeed = nil
	end
	for player in pairs(items) do
		withdraw(player)
	end
	table.clear(items)
	table.clear(nextAt)
	clockFn = nil
	kindFn = nil
	tellFn = nil
end

function TreadmillFunService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	unhookSpeed = PlayerDataService.OnSpeedGained(onSpeedGained)
	table.insert(connections, Players.PlayerRemoving:Connect(function(leaving: Player)
		withdraw(leaving)
	end))
	local acc = 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < STEP then
			return
		end
		acc = 0
		local ok, err = pcall(step, now())
		if not ok then
			warn("[Seed/TreadmillFunService] " .. tostring(err))
		end
	end))
	running = true
	log(string.format("Ready. %d Speed milestones (5 tickets); a belt item every %d-%d s, a golden ticket 1 in %d "
		.. "and at most %d a day.", #SpeedMilestones.List, BeltCatch.GapSeconds.Min, BeltCatch.GapSeconds.Max,
		math.floor(1 / BeltCatch.TicketChance + 0.5), BeltCatch.TicketsPerWindow))
end

function TreadmillFunService.Snapshot(): string
	local n = 0
	for _ in pairs(items) do
		n += 1
	end
	return string.format("%s; %d item(s) in flight", if running then "running" else "stopped", n)
end

return TreadmillFunService
