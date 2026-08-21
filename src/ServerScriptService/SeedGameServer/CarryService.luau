--!strict
-- Steal a Seed :: CarryService
--
-- Picking a pod up, carrying it home, and losing it when it goes wrong.
--
--==============================================================================
-- ONE POD. THAT IS THE WHOLE RULE.
--
-- An earlier build let you stack them and summed the weight. One is better, and
-- for a reason worth keeping: with a stack, a raid is an optimisation problem --
-- how many can I grab before it wakes. With one, it is a COMMITMENT. You picked
-- that pod, you are carrying that pod, and the walk home is about that pod.
--
-- It also makes the weight legible. A single number on your back, a single
-- number off your speed, and a player learns the whole economy by carrying two
-- different things.
--
--==============================================================================
-- GETTING CAUGHT COSTS YOU THE POD, NOT JUST THE WALK
--
-- Being ragdolled drops it. Any ragdoll, not just the parent's throw -- the
-- trigger is Humanoid.PlatformStand going true, so anything that ever knocks a
-- player down takes their cargo with it and no future system has to remember to
-- call anything.
--
-- That is what makes the parent frightening. The throw alone costs distance,
-- which is recoverable; losing the pod at the same time is what makes you creep
-- rather than sprint.
--
--==============================================================================
-- THIS SERVICE IS THE ONLY WRITER OF WalkSpeed
--
-- Base comes from the profile's Speed through GameConfig's curve, and carry
-- weight is the LAST multiplier applied to it. Something has to have the final
-- say or two systems fight over the property every frame, and the one holding
-- the last multiplier is the one that must own it. A future TreadmillService
-- raises the Speed SCORE and calls RefreshWalkSpeed; it never touches WalkSpeed.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(script.Parent:WaitForChild("CreatureModel"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local ATTR = GameConfig.Attributes

local CarryService = {}
-- After NestService (40), which owns the pods being taken.
CarryService.Priority = 45

export type Held = {
	species: SeedData.Species,
	model: Model,
}

local carried: { [Player]: Held } = {}
local serviceConnections: { RBXScriptConnection } = {}
local perPlayer: { [Player]: { RBXScriptConnection } } = {}
local prompted: { [Model]: true } = {}

-- How far above the head it floats. High enough to read across the road --
-- everybody can see what you are carrying, which is what makes a carrier a
-- target the moment PvP is switched on.
local CARRY_HEIGHT = 3.0
-- A pod on the ground is fair game for anybody, and vanishes if nobody comes.
local LOOSE_LIFETIME = 45
-- How close you must be. The PROMPT is not a security boundary -- it is a
-- courtesy drawn on a client, and a client can call InputHoldBegin on a prompt
-- from anywhere -- so the server measures the distance itself.
local TAKE_RANGE = 11
-- Slack for latency: the client saw them in range a moment ago and the take
-- lands a moment later. Tight enough to stop a reach across the road.
local RANGE_SLACK = 5

local function log(message: string)
	print("[Seed/CarryService] " .. message)
end

--==============================================================================
-- STATE THE CLIENT CAN SEE
--
-- An ATTRIBUTE ON THE PLAYER, because attributes replicate on their own and the
-- prompt UI has to know instantly whether to draw itself. A remote would be a
-- round trip to answer a question the client asks every frame it renders a
-- prompt.
--==============================================================================
local function publish(player: Player)
	local held = carried[player]
	player:SetAttribute(ATTR.CarryingSpecies, if held then held.species.Id else nil)
	player:SetAttribute(ATTR.CarryingKg, if held then held.species.Kg else nil)
end

function CarryService.IsCarrying(player: Player): boolean
	return carried[player] ~= nil
end

function CarryService.TotalKg(player: Player): number
	local held = carried[player]
	return if held then held.species.Kg else 0
end

function CarryService.RefreshWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local profile = PlayerDataService.Get(player)
	local base = GameConfig.walkSpeedFor(if profile then profile.Speed else 0)
	humanoid.WalkSpeed = base * GameConfig.carryMultiplierFor(CarryService.TotalKg(player))
end

--==============================================================================
-- CARRYING
--==============================================================================
local function attachToHead(model: Model, head: BasePart)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = primary
			end
		end
	end
	primary.CFrame = head.CFrame * CFrame.new(0, CARRY_HEIGHT, 0)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = primary
	weld.C0 = CFrame.new(0, CARRY_HEIGHT, 0)
	weld.Parent = primary
end

--==============================================================================
-- PROMPTS
--
-- Style = Custom, so the look is drawn by PromptUI.client.luau rather than by
-- Roblox's default chrome. ActionText is still set because the client reads it
-- for the label, and ObjectText is deliberately EMPTY: the prompt shows "Take"
-- and a key, nothing else.
--==============================================================================
local function attachPrompt(pod: Model)
	if prompted[pod] or not pod:IsA("Model") then
		return
	end
	local primary = pod.PrimaryPart
	if not primary then
		return
	end
	prompted[pod] = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakePrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Take"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = GameConfig.Carry.TakeHoldSeconds
	prompt.MaxActivationDistance = TAKE_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	prompt.Triggered:Connect(function(player)
		CarryService.TryTake(player, pod)
	end)
end

-- A dropped pod becomes a loose pod anybody can take. Declared before TryTake
-- because taking one that then cannot be attached has to put it back.
local function spawnLoose(species: SeedData.Species, at: CFrame, parent: Instance)
	local pod = CreatureModel.BuildPod(species, at, parent)
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	attachPrompt(pod)
	task.delay(LOOSE_LIFETIME, function()
		if pod.Parent then
			pod:Destroy()
		end
	end)
end

--==============================================================================
-- VALIDATE EVERYTHING, THEN MUTATE. NOT THE OTHER WAY ROUND.
--
-- This used to call TakePod first and check for a Head afterwards, and TakePod
-- is not a query: it clears the nest slot, starts the wake timer and DESTROYS
-- the pod. So a player with no Head -- mid-respawn, or dying in the same frame
-- -- left the parent waking up over an empty slot with the pod gone and nobody
-- holding it. The prize evaporated.
--
-- Everything that can refuse is checked before anything is touched, and the one
-- step that still cannot be pre-checked -- attaching to the character -- puts
-- the species back on the ground rather than dropping it out of the world.
--==============================================================================
function CarryService.TryTake(player: Player, pod: Model): boolean
	if player.Parent ~= Players then
		return false
	end
	-- THE SERVER IS THE AUTHORITY. The client hides the prompt while you are
	-- carrying, and this refuses anyway: hiding a prompt is a courtesy, not a
	-- rule, and a rule enforced only on the client is not a rule.
	if carried[player] then
		return false
	end
	if not pod.Parent then
		return false
	end
	local anchor = pod.PrimaryPart
	if not anchor then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not (humanoid and humanoid.Health > 0) then
		return false
	end
	if not (head and head:IsA("BasePart")) then
		return false
	end
	if (head.Position - anchor.Position).Magnitude > TAKE_RANGE + RANGE_SLACK then
		return false
	end

	--== EVERYTHING BELOW THIS LINE CHANGES THE WORLD ==--
	local species: SeedData.Species?
	if pod:GetAttribute("NestId") then
		-- Nest-owned: NestService decides, because taking one is what wakes the
		-- parent, and it is the only thing that can lose the race between two
		-- players reaching for the same pod -- it checks pods[slot] ~= pod, so
		-- only one of them can win.
		species = NestService.TakePod(pod, player)
	else
		species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
		if species then
			pod:Destroy()
		end
	end
	if not species then
		return false
	end

	local taken = species :: SeedData.Species
	local ok, err = pcall(function()
		local model = CreatureModel.BuildPod(taken, CFrame.new(head.Position), character)
		attachToHead(model, head)
		CollectionService:AddTag(model, GameConfig.Tags.CarriedPod)
		carried[player] = { species = taken, model = model }
	end)

	if not ok or not carried[player] then
		-- The pod is already out of the world and the parent may already be
		-- waking. Losing the species here would make a raid randomly worthless,
		-- so it goes back on the ground where anybody can pick it up.
		warn("[Seed/CarryService] could not attach " .. taken.Id .. ": " .. tostring(err))
		carried[player] = nil
		local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
		if map then
			spawnLoose(taken, CFrame.new(anchor.Position + Vector3.new(0, 1, 0)), map)
		end
		return false
	end

	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- DROPPING
--
-- A dropped pod becomes a loose pod anybody can take. That is the PvP hook
-- waiting to be switched on: the moment a carrier can be made to drop, what
-- they are carrying stops being a prize and becomes a target.
--==============================================================================
function CarryService.Drop(player: Player, at: Vector3?): boolean
	local held = carried[player]
	if not held then
		return false
	end
	carried[player] = nil

	local where = at
	if not where then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		where = if root and root:IsA("BasePart") then root.Position else nil
	end
	if held.model.Parent then
		held.model:Destroy()
	end
	local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
	if where and map then
		spawnLoose(held.species, CFrame.new(where + Vector3.new(0, 1, -3)), map)
	end

	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- READ API, for PlantService
--==============================================================================
function CarryService.GetCarried(player: Player): Held?
	return carried[player]
end

-- Consumes the pod without dropping it. Planting is the only thing that should
-- take a carried pod off a player and leave nothing on the ground.
function CarryService.Consume(player: Player): SeedData.Species?
	local held = carried[player]
	if not held then
		return nil
	end
	carried[player] = nil
	if held.model.Parent then
		held.model:Destroy()
	end
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return held.species
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function forget(player: Player)
	local conns = perPlayer[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		perPlayer[player] = nil
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- A new body carries nothing: whatever the old one had is on the ground
	-- where it fell.
	carried[player] = nil
	publish(player)

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	local conns = perPlayer[player] or {}
	perPlayer[player] = conns

	CarryService.RefreshWalkSpeed(player)

	-- RAGDOLLED MEANS DROPPED, and watching the PROPERTY rather than the event
	-- that caused it means every future knockdown gets this for free -- nothing
	-- has to remember to call Drop.
	table.insert(conns, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		if humanoid.PlatformStand then
			local root = character:FindFirstChild("HumanoidRootPart")
			CarryService.Drop(player,
				if root and root:IsA("BasePart") then root.Position else nil)
		end
	end))

	table.insert(conns, humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		CarryService.Drop(player,
			if root and root:IsA("BasePart") then root.Position else nil)
	end))
end

local function watch(player: Player)
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		forget(player)
		onCharacterAdded(player, character)
	end))
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

function CarryService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for player in pairs(perPlayer) do
		forget(player)
	end
	table.clear(carried)
	table.clear(prompted)
end

function CarryService.Start()
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("Model") then
			attachPrompt(pod)
		end
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			if pod:IsA("Model") then
				attachPrompt(pod)
			end
		end))
	table.insert(serviceConnections,
		CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			prompted[pod :: Model] = nil
		end))

	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player)
		forget(player)
		carried[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end

	log("Ready. One pod at a time; being ragdolled drops it.")
end

function CarryService.Snapshot(): string
	local rows = {}
	for player, held in pairs(carried) do
		table.insert(rows, string.format("%s: %s %d kg -> %.1f%% speed",
			player.Name, held.species.Name, held.species.Kg,
			GameConfig.carryMultiplierFor(held.species.Kg) * 100))
	end
	return if #rows > 0 then table.concat(rows, " | ") else "nobody carrying"
end

return CarryService
