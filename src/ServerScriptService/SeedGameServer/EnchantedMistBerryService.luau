--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistBerryService (2026-10-11, Enchanted Mist stage 2)
--
-- THE SHARED DEWBERRIES. While EnchantedMistService says the Mist is active,
-- Dewberries appear across the map -- near the plots and on the biomes' floor
-- off the running line (EnchantedMistData.Spawn) -- one opportunity every
-- IntervalSeconds, MaxActive at most, each for LifetimeSeconds. Every player
-- is told where each one appeared (one notice, said again in place).
--
-- SHARED COMPETITION: one berry, one picker. Hold E (Collect Dewberry,
-- HoldSeconds) within reach; the server checks the event, the berry, its
-- expiry, a living body in range, the hold it saw begin, no pod in hand and
-- room under the carry cap -- never a client's count, position or claimed
-- hold. The berry is RESERVED, the picker CREDITED and the berry REMOVED in
-- one resumption, so two triggers can never both win and a credit can never
-- be handed back. The count is the saved profile's (PlayerDataService.
-- UpdateDewberries): it outlives death, the Mist's end, a rejoin, another
-- server and a rebirth.
--
-- A full player (CarryCap) is refused without the berry being used; their
-- client puts the prompt out of reach (EnchantedMistBerries.client) -- only
-- theirs.
--
-- At the Mist's end every berry left is removed and no pick is accepted.
-- Nothing here runs while EnchantedMistService is off.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Notice = require(Shared:WaitForChild("Notice"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local DewberryModel = require(Shared:WaitForChild("DewberryModel"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MiniEventService = require(script.Parent:WaitForChild("MiniEventService"))
local EnchantedMistService = require(script.Parent:WaitForChild("EnchantedMistService"))

local EnchantedMistBerryService = {}
-- After EnchantedMistService (75), whose OnStart and OnEnd this hooks.
EnchantedMistBerryService.Priority = 76

local SPAWN = EnchantedMistData.Spawn
local CAP = EnchantedMistData.CarryCap
local B = EnchantedMistConfig.Berries
local W = B.Words

local function log(message: string)
	print("[Seed/EnchantedMistBerryService] " .. message)
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

--==============================================================================
-- SPEC-REPLACEABLE HOOKS: every reach outside this file.
--==============================================================================
local rng = Random.new()

EnchantedMistBerryService.Hooks = {
	now = function(): number
		return Workspace:GetServerTimeNow()
	end,
	random = function(): number
		return rng:NextNumber()
	end,
	-- The running Mist's id, or nil.
	eventId = function(): string?
		return EnchantedMistService.EventId()
	end,
	players = function(): { any }
		return Players:GetPlayers()
	end,
	-- Start points it at the GameEvent remote.
	send = function(_player: any, _action: string, _payload: { [string]: any }) end,
	profile = function(player: any): any
		return PlayerDataService.Get(player)
	end,
	update = function(player: any, change: (any) -> boolean): boolean
		return PlayerDataService.UpdateDewberries(player, change)
	end,
	-- A living body's root position, or nil.
	root = function(player: any): Vector3?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return root.Position
		end
		return nil
	end,
	carryingPod = function(player: any): boolean
		return player:GetAttribute(GameConfig.Attributes.CarryingSpecies) ~= nil
	end,
	-- A spot and its words, or nil: a spec's own placement replaces the map's.
	spot = nil :: (() -> (Vector3?, string?))?,
	-- Where the models go (a spec gives its own folder).
	parent = function(): Instance
		local folder = Workspace:FindFirstChild(B.FolderName)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = B.FolderName
			folder.Parent = Workspace
		end
		return folder :: Instance
	end,
}
local Hooks = EnchantedMistBerryService.Hooks

--==============================================================================
-- THE BERRIES
--==============================================================================
type Berry = {
	id: string,
	eventId: string,
	at: Vector3,
	where: string,
	bornAt: number,
	expiresAt: number,
	model: Model?,
	holds: { [any]: number },
	claimed: boolean,
}

local berries: { [string]: Berry } = {}
local run = {
	eventId = nil :: string?,
	endsAt = 0,
	nextAt = 0,
	serial = 0,
	picked = 0,
	spawned = 0,
}

local function count(): number
	local n = 0
	for _ in pairs(berries) do
		n += 1
	end
	return n
end

local function remove(berry: Berry)
	berries[berry.id] = nil
	table.clear(berry.holds)
	local model = berry.model
	berry.model = nil
	if model then
		model:Destroy()
	end
end

--==============================================================================
-- WHERE A BERRY MAY APPEAR
--==============================================================================
-- Spacing from every berry, PodClear from every pod: no two prompts share
-- ground.
local function roomAt(at: Vector3): boolean
	for _, other in pairs(berries) do
		if flat(other.at - at).Magnitude < SPAWN.Spacing then
			return false
		end
	end
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("PVInstance") and pod:IsDescendantOf(Workspace) then
			if flat((pod :: PVInstance):GetPivot().Position - at).Magnitude < SPAWN.PodClear then
				return false
			end
		end
	end
	return true
end

-- Near the plots: a MiniEventService ticket zone SafeZones names, by weight,
-- with every ticket check (the hub and its NPCs, plots, props, a real floor).
local function safeSpot(): Vector3?
	local names: { string } = {}
	local total = 0
	for name, weight in pairs(SPAWN.SafeZones) do
		table.insert(names, name)
		total += weight
	end
	table.sort(names)
	local others: { { at: Vector3 } } = {}
	for _, other in pairs(berries) do
		table.insert(others, { at = other.at })
	end
	local fake = { tickets = others } :: any
	for _ = 1, math.max(1, math.floor(SPAWN.Tries / 3)) do
		local roll = Hooks.random() * total
		local chosen = names[#names]
		for _, name in ipairs(names) do
			roll -= SPAWN.SafeZones[name]
			if roll <= 0 then
				chosen = name
				break
			end
		end
		local at = MiniEventService.PickIn(chosen, fake)
		if at and roomAt(at) then
			return at
		end
	end
	return nil
end

-- On a biome's floor off the running line, an early biome likelier.
local function biomeSpot(): (Vector3?, string?)
	local zones: { any } = {}
	local total = 0
	for _, zone in ipairs(MiniEventService.Zones()) do
		if zone.kind == "biome" and zone.biome then
			table.insert(zones, zone)
			total += 1 / math.max(1, zone.biome.Order)
		end
	end
	if #zones == 0 then
		return nil, nil
	end
	for _ = 1, SPAWN.Tries do
		local roll = Hooks.random() * total
		local zone = zones[#zones]
		for _, z in ipairs(zones) do
			roll -= 1 / math.max(1, z.biome.Order)
			if roll <= 0 then
				zone = z
				break
			end
		end
		local nearZ, farZ = BiomeData.SegmentBounds(zone.biome)
		local z = (farZ + SPAWN.BiomeFarMargin)
			+ ((nearZ - SPAWN.BiomeNearMargin) - (farZ + SPAWN.BiomeFarMargin)) * Hooks.random()
		local side = if Hooks.random() < 0.5 then -1 else 1
		local x = side * (SPAWN.BiomeX[1] + (SPAWN.BiomeX[2] - SPAWN.BiomeX[1]) * Hooks.random())
		local guess = Vector3.new(x, GameConfig.Map.GroundY, z)
		if MiniEventService.SpotClear(guess, zone, nil) and roomAt(guess) then
			local floor = MiniEventService.FloorAt(x, z)
			if floor then
				return floor, string.format(W.InBiome, zone.biome.DisplayName or zone.biome.Id)
			end
		end
	end
	return nil, nil
end

-- A spot and the words for it, or nil (the opportunity is skipped).
local function pickSpot(): (Vector3?, string?)
	local override = Hooks.spot
	if override then
		return override()
	end
	if Hooks.random() >= SPAWN.SafeShare then
		local at, where = biomeSpot()
		if at then
			return at, where
		end
		return nil, nil
	end
	local at = safeSpot()
	if at then
		return at, W.NearPlots
	end
	return nil, nil
end

--==============================================================================
-- A BERRY APPEARS
--==============================================================================
local function build(berry: Berry)
	local yaw = Hooks.random() * math.pi * 2
	local model = DewberryModel.build(CFrame.new(berry.at) * CFrame.Angles(0, yaw, 0), nil)
	model.Name = "Dewberry_" .. berry.id
	model:SetAttribute(B.BerryAttribute, berry.id)
	-- Its prompt and parts arrive on a client together, or not at all.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local root = model.PrimaryPart :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = B.PromptName
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = B.ActionText
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = SPAWN.HoldSeconds
	prompt.MaxActivationDistance = SPAWN.Reach
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute(B.BerryAttribute, berry.id)
	prompt.Parent = root:FindFirstChild("PickupAnchor") or root
	-- The hold the server SAW begin is the one a pick is measured against.
	prompt.PromptButtonHoldBegan:Connect(function(player)
		if berries[berry.id] == berry then
			berry.holds[player] = Hooks.now()
		end
	end)
	prompt.Triggered:Connect(function(player)
		EnchantedMistBerryService._claim(player, berry.id, Hooks.now())
	end)
	model.Parent = Hooks.parent()
	berry.model = model
end

local function announce(berry: Berry)
	local payload = { title = W.Appeared, detail = berry.where, key = B.NoticeKeys.Appeared }
	for _, player in ipairs(Hooks.players()) do
		-- Nobody full or still loading is sent after a berry they cannot take.
		local profile = Hooks.profile(player)
		if profile and (tonumber(profile.DewberriesCarried) or 0) < CAP then
			Hooks.send(player, Notice.ServerNotice, payload)
		end
	end
end

-- One spawn opportunity: a berry, or nothing.
function EnchantedMistBerryService._spawn(now: number): Berry?
	local eventId = run.eventId
	if not eventId or count() >= SPAWN.MaxActive or run.endsAt - now < SPAWN.QuietEndSeconds then
		return nil
	end
	local at, where = pickSpot()
	if not at then
		return nil
	end
	run.serial += 1
	local berry: Berry = {
		id = string.format("%s-b%d", eventId, run.serial),
		eventId = eventId,
		at = at,
		where = where or W.NearPlots,
		bornAt = now,
		expiresAt = now + SPAWN.LifetimeSeconds,
		model = nil,
		holds = {},
		claimed = false,
	}
	berries[berry.id] = berry
	build(berry)
	run.spawned += 1
	announce(berry)
	return berry
end

--==============================================================================
-- A PICK
--==============================================================================
function EnchantedMistBerryService._claim(player: any, id: string, now: number): (boolean, string)
	local berry = berries[id]
	if not berry or berry.claimed then
		return false, "GONE"
	end
	if run.eventId == nil or berry.eventId ~= run.eventId or Hooks.eventId() ~= berry.eventId then
		return false, "EVENT_OVER"
	end
	if now >= berry.expiresAt then
		return false, "EXPIRED"
	end
	local began = berry.holds[player]
	if not began or now - began < SPAWN.HoldSeconds - SPAWN.HoldTolerance then
		return false, "NO_HOLD"
	end
	local root = Hooks.root(player)
	if not root then
		return false, "DEAD"
	end
	if (root - berry.at).Magnitude > SPAWN.Reach + SPAWN.ReachSlack then
		return false, "FAR"
	end
	-- Every prompt hides while a pod is in hand (PromptUI); so does this one.
	if Hooks.carryingPod(player) then
		return false, "CARRYING"
	end
	local profile = Hooks.profile(player)
	if not profile then
		return false, "NOT_LOADED"
	end
	if (tonumber(profile.DewberriesCarried) or 0) >= CAP then
		return false, "FULL"
	end
	-- Reserved, credited, removed: one resumption, nothing yields between.
	berry.claimed = true
	local carried = 0
	local credited = Hooks.update(player, function(p: any): boolean
		local have = tonumber(p.DewberriesCarried) or 0
		if have >= CAP then
			return false
		end
		p.DewberriesCarried = have + 1
		carried = have + 1
		return true
	end)
	if not credited then
		berry.claimed = false
		return false, "FULL"
	end
	remove(berry)
	run.picked += 1
	local full = carried >= CAP
	Hooks.send(player, Notice.ServerNotice, {
		title = string.format(if full then W.PickedFull else W.Picked, carried, CAP),
		detail = if full then W.FullDetail else nil,
		key = B.NoticeKeys.Picked,
	})
	log(string.format("%s picked %s (%d/%d).", tostring(player.Name), id, carried, CAP))
	return true, "OK"
end

--==============================================================================
-- THE MIST'S START, ITS SECONDS, ITS END
--==============================================================================
function EnchantedMistBerryService._stop(reason: string)
	local left = count()
	for _, berry in pairs(berries) do
		remove(berry)
	end
	if run.eventId then
		log(string.format("%s over (%s): %d spawned, %d picked, %d removed.", run.eventId, reason, run.spawned,
			run.picked, left))
	end
	run.eventId = nil
	run.endsAt = 0
end

function EnchantedMistBerryService._begin(info: any, now: number)
	if type(info) ~= "table" or type(info.eventId) ~= "string" or info.eventId == run.eventId then
		return
	end
	EnchantedMistBerryService._stop("replaced")
	run.eventId = info.eventId
	run.endsAt = tonumber(info.endsAt) or now
	run.nextAt = now
	run.serial = 0
	run.picked = 0
	run.spawned = 0
	EnchantedMistBerryService._step(now)
end

-- The second's step: expired berries go, and one opportunity every
-- IntervalSeconds -- measured from now, so a stall never bursts.
function EnchantedMistBerryService._step(now: number)
	local eventId = run.eventId
	if not eventId then
		return
	end
	if Hooks.eventId() ~= eventId then
		EnchantedMistBerryService._stop("not running")
		return
	end
	for _, berry in pairs(berries) do
		if now >= berry.expiresAt then
			remove(berry)
		end
	end
	if now >= run.nextAt then
		run.nextAt = now + SPAWN.IntervalSeconds
		EnchantedMistBerryService._spawn(now)
	end
end

-- For specs and the console: the berries up now, oldest first.
function EnchantedMistBerryService.List(): { { id: string, at: Vector3, where: string, expiresAt: number } }
	local out = {}
	for _, berry in pairs(berries) do
		table.insert(out, { id = berry.id, at = berry.at, where = berry.where, expiresAt = berry.expiresAt,
			bornAt = berry.bornAt })
	end
	table.sort(out, function(a, b)
		return a.bornAt < b.bornAt
	end)
	return out
end

function EnchantedMistBerryService.Model(id: string): Model?
	local berry = berries[id]
	return berry and berry.model
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local unhooks: { () -> () } = {}
local generation = 0

function EnchantedMistBerryService.Init()
	for _, unhook in ipairs(unhooks) do
		unhook()
	end
	table.clear(unhooks)
	generation += 1
	EnchantedMistBerryService._stop("restart")
end

function EnchantedMistBerryService.Start()
	local mine = generation
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		local channel = found :: RemoteEvent
		Hooks.send = function(player: any, action: string, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, action, payload)
			end
		end
	end
	table.insert(unhooks, EnchantedMistService.OnStart(function(info)
		if generation == mine then
			EnchantedMistBerryService._begin(info, Hooks.now())
		end
	end))
	table.insert(unhooks, EnchantedMistService.OnEnd(function(info)
		if generation == mine then
			EnchantedMistBerryService._stop(if type(info) == "table" then tostring(info.reason) else "end")
		end
	end))
	local leaving = Players.PlayerRemoving:Connect(function(player)
		for _, berry in pairs(berries) do
			berry.holds[player] = nil
		end
	end)
	table.insert(unhooks, function()
		leaving:Disconnect()
	end)
	task.spawn(function()
		while generation == mine do
			task.wait(1)
			if generation == mine and run.eventId then
				EnchantedMistBerryService._step(Hooks.now())
			end
		end
	end)
end

return EnchantedMistBerryService
