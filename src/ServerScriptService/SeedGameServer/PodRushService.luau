--!strict
--==============================================================================
-- Steal a Seed :: PodRushService (2026-10-09; KB/POD-RUSH-PLAN.md)
--
-- THE POD RUSH, ON THIS SERVER. The event itself -- its id, and its start and
-- end on every server at once -- is MiniEventService's (mode "podrush"); this
-- watches the Workspace attributes that publishes and runs the rush here:
--
--   BEGIN    the nests regrow and build no rage (NestService.SetRush), dusk is
--            held (PodRush.Attributes.Until, read by WorldCycleService), and
--            each player's saved row meets this rush's id (a rejoin -- on any
--            server -- keeps its count).
--   A BANK   (CarryService.OnBanked) of a pod stolen from a nest during the
--            rush counts one: the row saved, the attributes published, the
--            "+1" sent, and a level reached paid once -- the spins, the boost,
--            the GOLD pod -- with GOLD said to everyone else here.
--   CLOSE    the nests as they were. A player carrying a pod that still counts
--            has GraceSeconds to bank it (PodRush.Attributes.Carrying: BANK
--            IT!); everybody else's end card goes now.
--   FINISH   the grace over: the rest get their end cards, PodRushEnded goes
--            once per player, dusk is let go.
--
-- Everything that reaches another service or the engine goes through Hooks,
-- so PodRushSpec drives all of it with stand-ins in Edit. GameConfig.PodRush
-- holds the numbers and the words; Shared/PodRush the rules.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local PodRush = require(Shared:WaitForChild("PodRush"))
local Notice = require(Shared:WaitForChild("Notice"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))
local BonusChestService = require(script.Parent:WaitForChild("BonusChestService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))

local CFG = GameConfig.PodRush
local MINI = GameConfig.MiniEvent.Attributes
local ATTR = CFG.Attributes
local EVENTS = CFG.Events
local WORDS = CFG.Words
-- The GOLD level's pod size (SeedData's Titan).
local TITAN_TIER: number = (CFG.Levels[#CFG.Levels] :: any).PodTier

local PodRushService = {}
-- After the mini events (66) and the world cycle (70) it rides on.
PodRushService.Priority = 71

-- The loop's step, and how often a GOLD pod still owed is tried again.
local TICK = 0.25
local OWED_RETRY_SECONDS = 5

local function log(message: string)
	print("[Seed/PodRushService] " .. message)
end

--==============================================================================
-- THE RUSH ON THIS SERVER
--==============================================================================
type Rush = {
	id: string,
	startedAt: number,
	endsAt: number,
	closedAt: number?,
	graceUntil: number?,
	-- Whose end card has gone (and PodRushEnded with it).
	over: { [any]: boolean },
}

local rush: Rush? = nil
-- The rush each player's numbers were last published for.
local synced: { [any]: string } = {}
-- When each player's owed GOLD pod was last tried.
local owedTried: { [any]: number } = {}

local connections: { RBXScriptConnection } = {}
local unhooks: { () -> () } = {}
local generation = 0

--==============================================================================
-- HOOKS: every reach outside this file. Start points `send` at the GameEvent
-- remote; a spec replaces any of them.
--==============================================================================
PodRushService.Hooks = {
	now = function(): number
		return Workspace:GetServerTimeNow()
	end,
	players = function(): { any }
		return Players:GetPlayers()
	end,
	-- The mini event as this server publishes it (MiniEventService).
	state = function(): { [string]: any }
		return {
			state = Workspace:GetAttribute(MINI.State),
			mode = Workspace:GetAttribute(MINI.Mode),
			id = Workspace:GetAttribute(MINI.EventId),
			startedAt = Workspace:GetAttribute(MINI.StartedAt),
			endsAt = Workspace:GetAttribute(MINI.EndsAt),
			endingAt = Workspace:GetAttribute(MINI.EndingAt),
		}
	end,
	send = function(_player: any, _action: string, _payload: { [string]: any }) end,
	setUntil = function(at: number?)
		Workspace:SetAttribute(ATTR.Until, at)
	end,
	setRush = function(on: boolean)
		NestService.SetRush(on)
	end,
	profile = function(player: any): any
		return PlayerDataService.Get(player)
	end,
	update = function(player: any, change: (any) -> boolean): boolean
		return PlayerDataService.UpdatePodRush(player, change)
	end,
	spins = function(player: any, n: number, why: string): number
		return WheelService.GrantMilestoneSpins(player, n, why)
	end,
	owe = function(player: any, n: number)
		PlayerDataService.AddMilestoneSpinsOwed(player, n)
	end,
	boost = function(player: any, boostId: string): boolean
		return BonusChestService.GrantBoost(player, boostId)
	end,
	givePod = function(player: any, speciesId: string, tier: number): boolean
		return CarryService.GivePod(player, speciesId, tier)
	end,
	carrying = function(player: any): number?
		return CarryService.CarriedTheft(player)
	end,
	metric = function(player: any, count: number, level: string)
		Metrics.podRushEnded(player, count, level)
	end,
	random = function(): Random
		return Random.new()
	end,
}
local Hooks = PodRushService.Hooks

--==============================================================================
-- THE SAVED ROW (ProfileSchema PodRush)
--==============================================================================
-- The row, made this rush's if it was another's: the count, the levels paid
-- and the top biome start again; a GOLD pod still owed stays owed.
local function claimRow(p: any, id: string): any
	local row = p.PodRush
	if type(row) ~= "table" then
		row = { Id = "", Count = 0, Paid = 0, Top = 0, PodOwed = "" }
		p.PodRush = row
	end
	if row.Id ~= id then
		row.Id = id
		row.Count = 0
		row.Paid = 0
		row.Top = 0
	end
	return row
end

local function rowOf(player: any): any
	local profile = Hooks.profile(player)
	local row = if profile then profile.PodRush else nil
	return if type(row) == "table" then row else nil
end

local function publish(player: any, id: string?, count: number, level: number)
	player:SetAttribute(ATTR.Id, id)
	player:SetAttribute(ATTR.Count, if id then count else nil)
	player:SetAttribute(ATTR.Level, if id then level else nil)
end

-- The biome a GOLD pod comes from: the highest Order banked from this rush,
-- Greenhollow's (Order 1) if somehow none is known.
local function biomeOfOrder(order: number): BiomeData.Biome?
	local first: BiomeData.Biome? = nil
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Order == order then
			return biome
		end
		if biome.Order == 1 then
			first = biome
		end
	end
	return first
end

local function nameOf(player: any): string
	local name = player.DisplayName
	if type(name) ~= "string" or name == "" then
		name = player.Name
	end
	return tostring(name)
end

--==============================================================================
-- A TITAN POD, NOW OR OWED
--==============================================================================
local function giveTitan(player: any, biomeId: string): boolean
	local species = SeedData.Roll(biomeId, Hooks.random())
	if not species then
		return false
	end
	return Hooks.givePod(player, species.Id, TITAN_TIER)
end

-- Pays one level: its spins (any that do not fit are owed), its boost, its pod
-- (owed while the Bag is full). Answers what it paid.
local function payLevel(player: any, level: number, top: number): (number, boolean, string?, boolean)
	local reward = PodRush.reward(level)
	local why = "the Pod Rush's " .. PodRush.levelName(level)
	local spins = 0
	if reward.spins > 0 then
		spins = reward.spins
		local landed = Hooks.spins(player, reward.spins, why)
		if landed < reward.spins then
			Hooks.owe(player, reward.spins - landed)
		end
	end
	local boosted = false
	if reward.boost then
		boosted = Hooks.boost(player, reward.boost)
		if not boosted then
			log(string.format("%s's %s boost was refused (a chest claim saving?).", nameOf(player), reward.boost))
		end
	end
	local podName: string? = nil
	local owed = false
	if reward.podTier then
		local biome = biomeOfOrder(top)
		if biome then
			podName = biome.DisplayName
			if not giveTitan(player, biome.Id) then
				owed = true
				local biomeId = biome.Id
				Hooks.update(player, function(p: any): boolean
					local row = p.PodRush
					if type(row) ~= "table" then
						return false
					end
					-- After any still owed: given oldest first (PodRush.owedList).
					local list = PodRush.owedList(row.PodOwed)
					table.insert(list, biomeId)
					row.PodOwed = PodRush.owedString(list)
					return true
				end)
				log(string.format("%s's GOLD pod (%s) is owed: no room in the Bag yet.", nameOf(player), biome.Id))
			end
		end
	end
	return spins, boosted, podName, owed
end

--==============================================================================
-- THE END CARD, ONCE (and PodRushEnded with it)
--==============================================================================
local function over(player: any, r: Rush)
	if r.over[player] then
		return
	end
	r.over[player] = true
	local row = rowOf(player)
	local count = if row and row.Id == r.id then row.Count else 0
	local level = PodRush.levelFor(count)
	local total = PodRush.rewardsUpTo(level)
	local biome = if total.podTier and row then biomeOfOrder(row.Top) else nil
	Hooks.send(player, EVENTS.Over, {
		id = r.id,
		count = count,
		level = level,
		spins = total.spins,
		boost = total.boost ~= nil,
		pod = if biome then biome.DisplayName else nil,
		podOwed = row ~= nil and row.PodOwed ~= "",
	})
	Hooks.metric(player, count, PodRush.levelId(level))
	player:SetAttribute(ATTR.Carrying, nil)
end

--==============================================================================
-- BEGIN, CLOSE, FINISH
--==============================================================================
local function begin(id: string, startedAt: number, endsAt: number): Rush
	local r: Rush = { id = id, startedAt = startedAt, endsAt = endsAt, over = {} }
	rush = r
	Hooks.setRush(true)
	Hooks.setUntil(endsAt + CFG.GraceSeconds)
	log(string.format("POD RUSH %s runs here until %.0f, then %ds of grace.", id, endsAt, CFG.GraceSeconds))
	return r
end

local function close(r: Rush, at: number)
	r.closedAt = at
	r.graceUntil = at + CFG.GraceSeconds
	Hooks.setRush(false)
	Hooks.setUntil(r.graceUntil)
	log(string.format("POD RUSH %s stopped; %ds of grace for a pod still in the arms.", r.id, CFG.GraceSeconds))
end

local function finish(r: Rush)
	for _, player in ipairs(Hooks.players()) do
		if synced[player] == r.id then
			over(player, r)
		end
		player:SetAttribute(ATTR.Carrying, nil)
		publish(player, nil, 0, 0)
		synced[player] = nil
	end
	Hooks.setRush(false)
	Hooks.setUntil(nil)
	if rush == r then
		rush = nil
	end
	log(string.format("POD RUSH %s is over here.", r.id))
end

-- A player's numbers, published for this rush once their profile is here.
local function sync(player: any, r: Rush)
	if synced[player] == r.id then
		return
	end
	if not Hooks.profile(player) then
		return
	end
	local count = 0
	Hooks.update(player, function(p: any): boolean
		local before = p.PodRush
		local fresh = type(before) ~= "table" or before.Id ~= r.id
		count = claimRow(p, r.id).Count
		return fresh
	end)
	synced[player] = r.id
	publish(player, r.id, count, PodRush.levelFor(count))
end

-- Whether the pod in this player's arms would count if banked now; written on
-- the player (Attributes.Carrying) when that changes.
local function setCarrying(player: any, r: Rush, now: number): boolean
	local waits = PodRush.counts(r, Hooks.carrying(player), now)
	local want: boolean? = if waits then true else nil
	if player:GetAttribute(ATTR.Carrying) ~= want then
		player:SetAttribute(ATTR.Carrying, want)
	end
	return waits
end

--==============================================================================
-- A BANK
--==============================================================================
function PodRushService.Banked(player: any, info: any)
	local r = rush
	if not r or type(info) ~= "table" then
		return
	end
	local now = Hooks.now()
	if not PodRush.counts(r, info.stolenAt, now) then
		return
	end
	local species = info.species
	local biome = if type(species) == "table" then BiomeData.ById[species.Biome] else nil
	local order = if biome then biome.Order else 0
	local count, level, paidBefore, top = 0, 0, 0, 0
	local counted = Hooks.update(player, function(p: any): boolean
		local row = claimRow(p, r.id)
		row.Count += 1
		if order > row.Top then
			row.Top = order
		end
		count = row.Count
		level = PodRush.levelFor(count)
		paidBefore = row.Paid
		if level > row.Paid then
			row.Paid = level
		end
		top = row.Top
		return true
	end)
	if not counted then
		return
	end
	synced[player] = r.id
	publish(player, r.id, count, level)

	-- Each level reached and not yet paid this rush, once.
	local due = PodRush.toPay(paidBefore, level)
	local levelUp: { [string]: any }? = nil
	for _, lv in ipairs(due) do
		local spins, boosted, podName, owed = payLevel(player, lv, top)
		local up: { [string]: any } = levelUp or { spins = 0, boost = false, podOwed = false }
		up.level = lv
		up.spins += spins
		up.boost = up.boost or boosted
		up.pod = podName or up.pod
		up.podOwed = up.podOwed or owed
		levelUp = up
	end
	Hooks.send(player, EVENTS.Counted, { id = r.id, count = count, level = level, levelUp = levelUp })
	log(string.format("%s banked a rush pod: %d (%s).", nameOf(player), count, PodRush.levelName(level)))

	-- GOLD, said to everybody else here.
	if table.find(due, #CFG.Levels) then
		local line = PodRush.serverLine(nameOf(player))
		for _, other in ipairs(Hooks.players()) do
			if other ~= player then
				Hooks.send(other, Notice.ServerNotice, {
					title = line,
					key = string.format("podrush:gold:%s:%s", r.id, tostring(player.UserId)),
					icon = "podrush",
					quiet = true,
				})
			end
		end
	end

	-- In the grace with nothing more that counts in the arms: over now.
	if r.closedAt and not setCarrying(player, r, now) then
		over(player, r)
	end
end

--==============================================================================
-- THE STEP: every TICK, from the Workspace's mini event
--==============================================================================
local function retryOwed(now: number)
	for _, player in ipairs(Hooks.players()) do
		local row = rowOf(player)
		if row and row.PodOwed ~= "" and now - (owedTried[player] or -math.huge) >= OWED_RETRY_SECONDS then
			owedTried[player] = now
			-- The oldest first.
			local biomeId = PodRush.owedList(row.PodOwed)[1]
			if biomeId and giveTitan(player, biomeId) then
				Hooks.update(player, function(p: any): boolean
					local owedRow = p.PodRush
					if type(owedRow) ~= "table" then
						return false
					end
					local list = PodRush.owedList(owedRow.PodOwed)
					local at = table.find(list, biomeId)
					if not at then
						return false
					end
					table.remove(list, at)
					owedRow.PodOwed = PodRush.owedString(list)
					return true
				end)
				local biome = BiomeData.ById[biomeId]
				Hooks.send(player, Notice.ServerNotice, {
					title = string.format(WORDS.PodGiven, if biome then biome.DisplayName else biomeId),
					key = "podrush:pod:" .. biomeId,
					icon = "podrush",
				})
				log(string.format("%s's owed GOLD pod (%s) given.", nameOf(player), biomeId))
			end
		end
	end
end

function PodRushService.Step(now: number)
	local s = Hooks.state()
	local live = s.mode == CFG.Mode and s.state == "running" and type(s.id) == "string"
		and type(s.startedAt) == "number" and type(s.endsAt) == "number"
	local r = rush
	if live then
		if not r or r.id ~= s.id then
			if r then
				finish(r)
			end
			r = begin(s.id, s.startedAt, s.endsAt)
		end
		local running = r :: Rush
		running.endsAt = s.endsAt
		for _, player in ipairs(Hooks.players()) do
			sync(player, running)
			setCarrying(player, running, now)
		end
	elseif r and not r.closedAt then
		-- Stopped: the timer or an END (State "ending", EndingAt), or gone.
		local at = if s.id == r.id and type(s.endingAt) == "number" then math.min(s.endingAt, now) else now
		close(r, at)
	end
	r = rush
	if r and r.closedAt then
		if now >= (r.graceUntil or now) then
			finish(r)
		else
			for _, player in ipairs(Hooks.players()) do
				if synced[player] == r.id and not r.over[player] and not setCarrying(player, r, now) then
					over(player, r)
				end
			end
		end
	end
	retryOwed(now)
end

-- What is running here, for the specs and the log: nil, or a copy.
function PodRushService.Current(): { [string]: any }?
	local r = rush
	if not r then
		return nil
	end
	return { id = r.id, startedAt = r.startedAt, endsAt = r.endsAt, closedAt = r.closedAt, graceUntil = r.graceUntil }
end

-- Studio specs: forget everything.
function PodRushService.Reset()
	rush = nil
	table.clear(synced)
	table.clear(owedTried)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PodRushService.Init()
	generation += 1
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, unhook in ipairs(unhooks) do
		unhook()
	end
	table.clear(unhooks)
	PodRushService.Reset()
end

function PodRushService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		local channel = found :: RemoteEvent
		Hooks.send = function(player: any, action: string, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, action, payload)
			end
		end
	else
		warn("[Seed/PodRushService] no GameEvent remote: the rush shows nothing to anybody.")
	end
	table.insert(unhooks, CarryService.OnBanked(function(player: Player, info: any)
		PodRushService.Banked(player, info)
	end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		synced[player] = nil
		owedTried[player] = nil
	end))
	local mine = generation
	task.spawn(function()
		while generation == mine do
			local ok, err = pcall(PodRushService.Step, Hooks.now())
			if not ok then
				warn("[Seed/PodRushService] step failed: " .. tostring(err))
			end
			task.wait(TICK)
		end
	end)
	log(string.format("Ready. A rush: nests regrow in %ds, no rage, dusk held; levels %d / %d / %d; %ds of grace.",
		CFG.RegrowSeconds, CFG.Levels[1].Pods, CFG.Levels[2].Pods, CFG.Levels[3].Pods, CFG.GraceSeconds))
end

return PodRushService
