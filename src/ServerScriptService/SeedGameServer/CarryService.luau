--!strict
-- Steal a Seed :: CarryService
--
-- Picking pods up, carrying them home, and dropping them when it goes wrong.
--
--==============================================================================
-- YOU CAN CARRY AS MANY AS YOU LIKE, AND THAT IS THE POINT
--
-- One pod at a time would have been simpler and it would have gutted the nest.
-- A nest asks "how many can I take before it wakes up?", and that question only
-- exists if the answer can be more than one.
--
-- So weight SUMS. Four pods is four pods of income and four pods of slow, and
-- the parent behind you does not care how rich you are. Greed is priced by the
-- same number that pays you, which is why the carry curve and the income curve
-- are the same stat:
--
--     2 kg   99.6% speed        one Nubkin, basically free
--     110 kg 95.3%              one Bellchime
--     440 kg 91.2%              four Bellchimes, and a decision
--
-- MaxPods exists only so a stack cannot become absurd on screen. WEIGHT is the
-- real limiter and always should be -- a cap teaches nothing, a slow walk home
-- past an angry parent teaches everything.
--
--==============================================================================
-- THIS SERVICE IS THE ONLY WRITER OF WalkSpeed
--
-- Base speed comes from the profile's Speed score through GameConfig's curve,
-- and carry weight is the LAST multiplier applied to it. Something has to have
-- the final say or two systems will fight over the property every frame, and
-- the one holding the last multiplier is the one that must own it.
--
-- When a TreadmillService exists it will raise the Speed SCORE and call
-- RefreshWalkSpeed. It will not touch WalkSpeed itself.
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

local CarryService = {}
-- After NestService (40), which owns the pods being taken.
CarryService.Priority = 45

export type Held = {
	species: SeedData.Species,
	model: Model,
}

local carried: { [Player]: { Held } } = {}
local serviceConnections: { RBXScriptConnection } = {}
local prompted: { [Model]: true } = {}

-- How far above the head the first pod floats, and the gap between stacked
-- pods. A stack reads instantly at distance -- everybody can see how loaded you
-- are, which is what makes a heavy carrier a target.
local STACK_BASE = 2.6
local STACK_GAP = 1.9
local MAX_PODS = 5
-- A pod dropped on the ground is fair game for anybody, and vanishes if nobody
-- comes for it.
local LOOSE_LIFETIME = 45

local function log(message: string)
	print("[Seed/CarryService] " .. message)
end

--==============================================================================
-- WEIGHT AND SPEED
--==============================================================================
function CarryService.TotalKg(player: Player): number
	local held = carried[player]
	if not held then
		return 0
	end
	local kg = 0
	for _, entry in ipairs(held) do
		kg += entry.species.Kg
	end
	return kg
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
-- THE STACK
--==============================================================================
local function anchorless(model: Model)
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
end

local function restack(player: Player)
	local held = carried[player]
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not (held and head and head:IsA("BasePart")) then
		return
	end
	for index, entry in ipairs(held) do
		local primary = entry.model.PrimaryPart
		if primary then
			for _, j in ipairs(primary:GetChildren()) do
				if j:IsA("Weld") and j.Name == "CarryWeld" then
					j:Destroy()
				end
			end
			primary.CFrame = head.CFrame
				* CFrame.new(0, STACK_BASE + (index - 1) * STACK_GAP, 0)
			local weld = Instance.new("Weld")
			weld.Name = "CarryWeld"
			weld.Part0 = head
			weld.Part1 = primary
			weld.C0 = CFrame.new(0, STACK_BASE + (index - 1) * STACK_GAP, 0)
			weld.Parent = primary
		end
	end
end

--==============================================================================
-- PICKING UP
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

	local species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"
	prompt.ObjectText = if species
		then string.format("%s  %d kg", species.Rarity, species.Kg)
		else "Pod"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	prompt.Triggered:Connect(function(player)
		CarryService.TryTake(player, pod)
	end)
end

function CarryService.TryTake(player: Player, pod: Model): boolean
	if player.Parent ~= Players or not pod.Parent then
		return false
	end
	local held = carried[player]
	if held and #held >= MAX_PODS then
		return false
	end

	local species: SeedData.Species?
	if pod:GetAttribute("NestId") then
		-- Nest-owned: NestService decides, because taking one is what wakes the
		-- parent, and it is also the only thing that can lose the race between
		-- two players reaching for the same pod.
		species = NestService.TakePod(pod, player)
	else
		-- Loose on the ground: whoever gets there.
		species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
		if species then
			pod:Destroy()
		end
	end
	if not species then
		return false
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return false
	end

	local model = CreatureModel.BuildPod(species, CFrame.new(head.Position), character)
	anchorless(model)
	CollectionService:AddTag(model, GameConfig.Tags.CarriedPod)

	held = carried[player] or {}
	table.insert(held, { species = species, model = model })
	carried[player] = held

	restack(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- DROPPING
--
-- Dropped pods become loose pods anybody can take. That is the whole PvP hook
-- waiting to be switched on: the moment a carrier can be made to drop, a heavy
-- stack stops being a prize and becomes a target.
--==============================================================================
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

function CarryService.DropAll(player: Player, at: Vector3?)
	local held = carried[player]
	carried[player] = nil
	if not held then
		return
	end
	local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
	local where = at
	if not where then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		where = if root and root:IsA("BasePart") then root.Position else nil
	end

	for index, entry in ipairs(held) do
		if entry.model.Parent then
			entry.model:Destroy()
		end
		if where and map then
			-- Scattered, not stacked: a pile of pods on one stud is one pod as
			-- far as anybody running past can tell.
			local a = (index / #held) * math.pi * 2
			spawnLoose(entry.species,
				CFrame.new(where + Vector3.new(math.sin(a) * 4, 0, math.cos(a) * 4)),
				map)
		end
	end
	CarryService.RefreshWalkSpeed(player)
end

--==============================================================================
-- READ API, for PlantService
--==============================================================================
function CarryService.GetCarried(player: Player): { Held }
	return carried[player] or {}
end

-- Removes one pod from the stack and hands back its species. Planting is the
-- only thing that should consume a carried pod without dropping it.
function CarryService.Consume(player: Player, index: number): SeedData.Species?
	local held = carried[player]
	if not held or not held[index] then
		return nil
	end
	local entry = table.remove(held, index)
	if not entry then
		return nil
	end
	if entry.model.Parent then
		entry.model:Destroy()
	end
	if #held == 0 then
		carried[player] = nil
	end
	restack(player)
	CarryService.RefreshWalkSpeed(player)
	return entry.species
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function onCharacterAdded(player: Player, _character: Model)
	-- A new body carries nothing. The pods were dropped where the old one died.
	carried[player] = nil
	task.defer(function()
		CarryService.RefreshWalkSpeed(player)
	end)
end

local function watch(player: Player)
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and humanoid:IsA("Humanoid") then
			table.insert(serviceConnections, humanoid.Died:Connect(function()
				local root = character:FindFirstChild("HumanoidRootPart")
				CarryService.DropAll(player,
					if root and root:IsA("BasePart") then root.Position else nil)
			end))
		end
	end))
end

function CarryService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
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
		carried[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end

	local C = GameConfig.Carry
	log(string.format("Ready. Up to %d pods, %d kg costs %.0f%% of your speed.",
		MAX_PODS, C.MaxKg, (1 - C.MinMultiplier) * 100))
end

function CarryService.Snapshot(): string
	local rows = {}
	for player, held in pairs(carried) do
		local names = {}
		for _, e in ipairs(held) do
			table.insert(names, e.species.Name)
		end
		table.insert(rows, string.format("%s: %d pod(s) %.0f kg -> %.1f%% speed [%s]",
			player.Name, #held, CarryService.TotalKg(player),
			GameConfig.carryMultiplierFor(CarryService.TotalKg(player)) * 100,
			table.concat(names, ", ")))
	end
	return if #rows > 0 then table.concat(rows, " | ") else "nobody carrying"
end

return CarryService
