--!strict
-- Steal a Seed :: BiomeGateService
--
-- Daytime biome entrances are open to everybody. The numbers on the arches are
-- recommendations for the chase ahead, not locks. This service does three
-- related jobs from one authoritative road-position poll:
--
--   1. tell a client when it enters a non-starter biome;
--   2. preserve the player's permanent Speed milestone for mill progression;
--   3. enforce the separate rule that the entire road closes at night.
--
-- The night rule remains geometric rather than Touched-based. At high
-- WalkSpeed a character can skip through a thin part between physics frames,
-- but it cannot hide which side of the road mouth it occupies.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local BiomeGateService = {}
BiomeGateService.Priority = 25

local MAP = GameConfig.Map
local GATE = GameConfig.Gate
local ATTR = GameConfig.Attributes

local running = false
local generation = 0
local serviceConnections: { RBXScriptConnection } = {}
local lastOrder: { [Player]: number } = {}
local lastNightNotice: { [Player]: number } = {}
local recommendationRemote: RemoteEvent? = nil

local function log(message: string)
	print("[Seed/BiomeGateService] " .. message)
end

-- The road runs into negative Z from the field's front edge. Order zero is the
-- field; orders one through five are the biome segments.
function BiomeGateService.OrderAt(position: Vector3): number
	local depth = -position.Z - MAP.FieldFront
	if depth < 0 then
		return 0
	end
	local order = math.floor(depth / MAP.SegmentLength) + 1
	return math.min(order, #BiomeData.Biomes)
end

local function roadMouthZ(): number
	return -MAP.FieldFront
end

-- This is a progression milestone, not permission to enter. It remains
-- permanent so rebirth cannot revoke mill overclocks a player already earned.
function BiomeGateService.EarnedBy(speedScore: number): number
	if type(speedScore) ~= "number" or speedScore ~= speedScore then
		return 1
	end
	local earned = 1
	for _, biome in ipairs(BiomeData.Biomes) do
		if speedScore >= biome.RecommendedSpeed then
			earned = math.max(earned, biome.Order)
		end
	end
	return earned
end

local function publishMilestone(player: Player, profile: PlayerDataService.Profile)
	local earned = BiomeGateService.EarnedBy(profile.Speed)
	if PlayerDataService.RaiseHighestBiome(player, earned) then
		local biome = BiomeData.Biomes[earned]
		log(string.format("%s reached the %s Speed milestone (%s >= %s).",
			player.Name,
			if biome then biome.DisplayName else tostring(earned),
			GameConfig.compact(profile.Speed),
			GameConfig.compact(if biome then biome.RecommendedSpeed else 0)))
	end

	local recorded = math.floor(profile.HighestBiomeOrder or 1)
	if player:GetAttribute(ATTR.HighestBiomeOrder) ~= recorded then
		player:SetAttribute(ATTR.HighestBiomeOrder, recorded)
	end
end

local function tellClient(player: Player, order: number)
	local biome = BiomeData.Biomes[order]
	if not biome or biome.RecommendedSpeed <= 0 or not recommendationRemote then
		return
	end

	local ok, err = pcall(function()
		(recommendationRemote :: RemoteEvent):FireClient(player, biome.Id)
	end)
	if not ok then
		warn("[Seed/BiomeGateService] recommendation for " .. player.Name
			.. " failed: " .. tostring(err))
	end
end

local function ejectForNight(player: Player, root: BasePart, now: number)
	local stopZ = roadMouthZ() + GATE.PushBackStuds
	local at = root.Position
	root.CFrame = CFrame.lookAt(
		Vector3.new(at.X, at.Y, stopZ),
		Vector3.new(at.X, at.Y, stopZ + 1))
	root.AssemblyLinearVelocity = Vector3.zero
	CarryService.ForfeitCarry(player)

	local last = lastNightNotice[player] or 0
	if now - last >= GATE.NoticeCooldown then
		lastNightNotice[player] = now
		log(player.Name .. " returned to the field because the road is closed at night.")
	end
end

local function step(player: Player, now: number)
	local profile = PlayerDataService.Get(player)
	if not profile then
		return
	end
	publishMilestone(player, profile)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootInstance = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and humanoid.Health > 0 and rootInstance and rootInstance:IsA("BasePart")) then
		return
	end
	local root = rootInstance :: BasePart
	local order = BiomeGateService.OrderAt(root.Position)
	local previous = lastOrder[player]
	lastOrder[player] = order

	local night = not GameConfig.isDay()
	if not night then
		-- The first observation also counts. This makes a test teleport or a
		-- respawn inside Dustbowl receive the same guidance as walking across it.
		if order > 1 and order ~= previous then
			tellClient(player, order)
		end
		return
	end

	if order > 0 then
		ejectForNight(player, root, now)
		lastOrder[player] = 0
	end
end

-- WorldCycleService calls this on the exact night transition; the regular poll
-- handles ordinary movement and clipping attempts between transitions.
function BiomeGateService.SweepNow(): number
	local now = os.clock()
	local touched = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local ok = pcall(step, player, now)
		if ok then
			touched += 1
		end
	end
	return touched
end

-- Public access answers now describe the actual rule: open to every biome by
-- day, closed at the road mouth by night. Player progression is irrelevant.
function BiomeGateService.AllowedFor(_player: Player): number
	return if GameConfig.isDay() then #BiomeData.Biomes else 0
end

function BiomeGateService.CanEnter(player: Player, order: number): boolean
	return order <= BiomeGateService.AllowedFor(player)
end

function BiomeGateService.Init()
	running = false
	generation += 1
	for _, connection in ipairs(serviceConnections) do
		connection:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastOrder)
	table.clear(lastNightNotice)
	recommendationRemote = nil

	-- Republish from the profile after a rerun instead of leaving stale state.
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute(ATTR.HighestBiomeOrder, nil)
	end
end

function BiomeGateService.Start()
	local remotes = SeedGame:WaitForChild("Remotes")
	local candidate = remotes:WaitForChild(GameConfig.Remotes.BiomeRecommendation)
	if candidate:IsA("RemoteEvent") then
		recommendationRemote = candidate
	else
		warn("[Seed/BiomeGateService] BiomeRecommendation is not a RemoteEvent.")
	end

	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		lastOrder[player] = nil
		lastNightNotice[player] = nil
	end))

	running = true
	local startedGeneration = generation
	task.spawn(function()
		while running and generation == startedGeneration do
			task.wait(GATE.PollSeconds)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(step, player, now)
				if not ok then
					warn("[Seed/BiomeGateService] " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)

	local recommendations = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.RecommendedSpeed > 0 then
			table.insert(recommendations, string.format("%s %s",
				biome.DisplayName, GameConfig.compact(biome.RecommendedSpeed)))
		end
	end
	log(string.format("Ready. Day access is open to all; recommendations: %s. "
		.. "Night closure is checked every %.2fs.",
		table.concat(recommendations, ", "), GATE.PollSeconds))
end

function BiomeGateService.Snapshot(): string
	local rows = {}
	local access = if GameConfig.isDay() then "open" else "closed"
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local order = if root and root:IsA("BasePart")
			then BiomeGateService.OrderAt(root.Position) else 0
		local biome = BiomeData.Biomes[order]
		table.insert(rows, string.format("%s: road %s, standing in %d, recommended %s, Speed %s",
			player.Name, access, order,
			if biome then GameConfig.compact(biome.RecommendedSpeed) else "none",
			GameConfig.compact(if profile then profile.Speed else 0)))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody on the road"
end

return BiomeGateService
