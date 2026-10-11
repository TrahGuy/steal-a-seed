--!strict
--==============================================================================
-- Steal a Seed :: ServerBoostService (2026-10-12, the owner's item 9B)
--
-- THE TWO PRODUCTS BOUGHT FOR THE WHOLE SERVER, AND THE STARTER PACK'S OFFER.
-- The rules are ServerBoost's (Shared, pure); this file keeps the clock, starts
-- the Rain, and publishes what the clients draw.
--
-- SERVER LUCK. Each purchase adds its seconds (15 min) of rarer pods x
-- ServerBoost.Luck.Factor in every nest -- NestService's roll, through useLuck
-- -- stacking. While the Enchanted Mist is on the clock stands still (the
-- event's brief bans paid luck in it) and it runs on after. The buyer's name is
-- said to everybody, and a chip (BoostIcons) shows the time. It lives in this
-- server: a server that closes takes what was left of it.
--
-- SUMMON RAIN. A purchase is OWED first, on the buyer's profile, in the
-- receipt's own step (StoreService saves it with its ledger entry before
-- Roblox is told); this file's step starts the Rain for it the moment nothing
-- clashes -- at once, normally, since the Shop's button sells only then. One
-- that raced a clash waits on the profile, in this server or the buyer's next,
-- and is never lost. Each summon starts ServerBoost.Rain.CooldownSeconds of
-- cooldown. The Rain itself is WeatherService's, its lottery untouched.
--
-- THE STARTER PACK'S OFFER: on each player, until when they are offered it
-- (ServerBoost.starterUntil), for the Shop to show or hide its card. The grant
-- itself is StoreService's.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local ServerBoost = require(Shared:WaitForChild("ServerBoost"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local WeatherService = require(script.Parent:WaitForChild("WeatherService"))
local EnchantedMistService = require(script.Parent:WaitForChild("EnchantedMistService"))
local PodRushService = require(script.Parent:WaitForChild("PodRushService"))

local ServerBoostService = {}
-- Before StoreService (66), which calls in from its first receipt.
ServerBoostService.Priority = 64

local CFG = GameConfig.ServerBoost
local LUCK = CFG.Luck
local RAIN = CFG.Rain
local STARTER = CFG.Starter

local function log(message: string)
	print("[Seed/ServerBoostService] " .. message)
end

--==============================================================================
-- WHAT THIS FILE ASKS OF THE WORLD (a spec replaces any of them)
--==============================================================================
ServerBoostService.Hooks = {
	now = function(): number
		return Workspace:GetServerTimeNow()
	end,
	players = function(): { Player }
		return Players:GetPlayers()
	end,
	-- One GameEvent message to one player.
	send = function(player: Player, action: string, payload: { [string]: any })
		local remotes = SeedGame:FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
		if remote and remote:IsA("RemoteEvent") and player.Parent == Players then
			(remote :: RemoteEvent):FireClient(player, action, payload)
		end
	end,
	-- What a summon would clash with: weather in any state, the Mist, a Pod Rush.
	weather = function(): boolean
		return WeatherService.State() ~= nil
	end,
	mist = function(): boolean
		return EnchantedMistService.IsActive()
	end,
	rush = function(): boolean
		return PodRushService.Current() ~= nil or NestService.RushOn()
	end,
	startRain = function(by: Player, seconds: number): (boolean, string)
		return WeatherService.StartRain(by, seconds)
	end,
	-- One Workspace attribute the clients read, written only when it changes.
	publish = function(name: string, value: any)
		if Workspace:GetAttribute(name) ~= value then
			Workspace:SetAttribute(name, value)
		end
	end,
}
local Hooks = ServerBoostService.Hooks

local luck = ServerBoost.newLuck()
-- Hooks.now() the last summon's cooldown ends at.
local rainReadyAt = 0
local running = false
local generation = 0
local noticeCount = 0
local connections: { RBXScriptConnection } = {}

local function nameOf(player: Player): string
	local name = (player :: any).DisplayName
	return if type(name) == "string" and name ~= "" then name else player.Name
end

-- One line for everybody here, the buyer included.
local function announce(title: string, kind: string, icon: string)
	noticeCount += 1
	local key = string.format("%s:%d", kind, noticeCount)
	for _, other in ipairs(Hooks.players()) do
		Hooks.send(other, Notice.ServerNotice, { title = title, key = key, icon = icon })
	end
end

local function clashNow(): string?
	return ServerBoost.rainClash(Hooks.weather(), Hooks.mist(), Hooks.rush())
end

-- The attributes: the luck's (ServerBoost.Luck.Attributes; nothing while it
-- is off) and the summon's (its cooldown's end and what it clashes with).
local function publish(now: number, clash: string?)
	local A = LUCK.Attributes
	local left = ServerBoost.luckLeft(luck, now)
	local endsAt = luck.endsAt
	Hooks.publish(A.EndsAt, if endsAt and left > 0 then endsAt else nil)
	Hooks.publish(A.Left, if endsAt == nil and left > 0 then left else nil)
	Hooks.publish(A.Total, if left > 0 then luck.total else nil)
	Hooks.publish(A.By, if left > 0 and luck.by ~= "" then luck.by else nil)
	local R = RAIN.Attributes
	Hooks.publish(R.ReadyAt, if rainReadyAt > now then rainReadyAt else nil)
	Hooks.publish(R.Clash, clash)
end

--==============================================================================
-- SERVER LUCK
--==============================================================================
-- What a nest's species roll is worth now (NestService.useLuck): Luck.Factor
-- while SERVER LUCK runs and the Mist is not on, else 1.
function ServerBoostService.Luck(): number
	return ServerBoost.luckFactor(luck, Hooks.now(), Hooks.mist())
end

-- A SERVER LUCK receipt (StoreService): `seconds` more for everybody here, and
-- said to everybody. True when it landed.
function ServerBoostService.GrantLuck(player: Player, seconds: number): boolean
	local s = math.floor(tonumber(seconds) or 0)
	if s <= 0 then
		return false
	end
	local now = Hooks.now()
	local paused = Hooks.mist()
	ServerBoost.addLuck(luck, s, now, paused, nameOf(player))
	publish(now, clashNow())
	local minutes = math.floor(s / 60 + 0.5)
	announce(string.format(if paused then LUCK.BoughtPaused else LUCK.Bought, nameOf(player), LUCK.Factor,
		minutes), "luck", "luck")
	log(string.format("%s bought %d s of SERVER LUCK: %s to run%s.", player.Name, s,
		ServerBoost.clock(ServerBoost.luckLeft(luck, now)),
		if paused then ", standing still until the Enchanted Mist ends" else ""))
	return true
end

-- The clock as it stands, for the console and the spec.
function ServerBoostService.LuckState(): ServerBoost.Luck
	return table.clone(luck)
end

--==============================================================================
-- SUMMON RAIN
--==============================================================================
-- A SUMMON RAIN receipt (StoreService): one more Rain owed on the buyer's
-- profile, in the receipt's own step. Started by the next step, never in here:
-- a Rain started inside a receipt whose save then failed would run again on
-- Roblox's retry. True when it is owed.
function ServerBoostService.GrantRain(player: Player): boolean
	local owed = PlayerDataService.AddRainOwed(player, 1)
	if owed == nil then
		return false
	end
	log(string.format("%s bought SUMMON RAIN (%d owed): it starts the moment nothing clashes.", player.Name, owed))
	task.defer(function()
		if running then
			ServerBoostService.Step()
		end
	end)
	return true
end

-- When the next summon may start (Hooks.now() time; 0 for now).
function ServerBoostService.RainReadyAt(): number
	return rainReadyAt
end

-- One owed Rain, started if nothing clashes and the cooldown is over: the
-- first player here who is owed one. Answers whether one started.
local function startOwed(now: number, clash: string?): boolean
	if not ServerBoost.mayStartRain(clash, rainReadyAt, now) then
		return false
	end
	for _, player in ipairs(Hooks.players()) do
		local profile = PlayerDataService.Get(player)
		if profile and (profile.RainOwed or 0) > 0 then
			local ok, started, why = pcall(Hooks.startRain, player, RAIN.Seconds)
			if not (ok and started) then
				warn(string.format("[Seed/ServerBoostService] %s's Rain did not start (%s); it stays owed.",
					player.Name, tostring(if ok then why else started)))
				return false
			end
			PlayerDataService.AddRainOwed(player, -1)
			rainReadyAt = now + RAIN.CooldownSeconds
			announce(string.format(RAIN.Summoned, nameOf(player)), "rain", "rain")
			log(string.format("%s's Rain started; the next summon from %s.", player.Name,
				ServerBoost.clock(RAIN.CooldownSeconds)))
			return true
		end
	end
	return false
end

--==============================================================================
-- ONE STEP (every second, and right after a Rain is bought): the luck's clock,
-- one owed Rain if one may start, then the attributes.
--==============================================================================
function ServerBoostService.Step()
	local now = Hooks.now()
	local mist = Hooks.mist()
	local moved = ServerBoost.stepLuck(luck, now, mist)
	if moved == "paused" then
		log("SERVER LUCK stands still: the Enchanted Mist is on.")
	elseif moved == "resumed" then
		log(string.format("SERVER LUCK runs on: %s left.", ServerBoost.clock(ServerBoost.luckLeft(luck, now))))
	elseif moved == "ended" then
		log("SERVER LUCK has run out.")
	end
	local clash = ServerBoost.rainClash(Hooks.weather(), mist, Hooks.rush())
	if startOwed(now, clash) then
		clash = clashNow()
	end
	publish(now, clash)
end

--==============================================================================
-- THE STARTER PACK'S OFFER, ON THE PLAYER: until when (os.time) they are
-- offered it -- their first Starter.Days from their first join (the profile's
-- CreatedAt) -- or 0 once they have one. The Shop hides the card past it.
--==============================================================================
function ServerBoostService.PublishStarter(player: Player)
	local profile = PlayerDataService.Get(player)
	if not profile or player.Parent ~= Players then
		return
	end
	local untilAt = ServerBoost.starterUntil(profile.CreatedAt or 0, profile.StarterPacks or 0)
	if player:GetAttribute(STARTER.Attribute) ~= untilAt then
		player:SetAttribute(STARTER.Attribute, untilAt)
	end
end

-- A profile first, then the offer (never in Start: the profile is a DataStore
-- round trip away).
local function watch(player: Player, gen: number)
	local t = os.clock()
	while running and gen == generation and player.Parent == Players
		and not PlayerDataService.IsReady(player) and os.clock() - t < 120 do
		task.wait(0.25)
	end
	if running and gen == generation and player.Parent == Players then
		ServerBoostService.PublishStarter(player)
	end
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function ServerBoostService.Init()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	running = false
	generation += 1
	luck = ServerBoost.newLuck()
	rainReadyAt = 0
end

function ServerBoostService.Start()
	running = true
	generation += 1
	local gen = generation
	NestService.useLuck(ServerBoostService.Luck)
	table.insert(connections, Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(watch, player, gen)
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(watch, player, gen)
	end
	task.spawn(function()
		while running and gen == generation do
			local ok, err = pcall(ServerBoostService.Step)
			if not ok then
				warn("[Seed/ServerBoostService] a step failed: " .. tostring(err))
			end
			task.wait(1)
		end
	end)
	log(string.format("Ready. SERVER LUCK rolls rarer pods x%d in every nest while bought (still during the "
		.. "Enchanted Mist); SUMMON RAIN starts the moment nothing clashes, %d min apart.", LUCK.Factor,
		RAIN.CooldownSeconds // 60))
end

return ServerBoostService
