--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistBerries (2026-10-11, Enchanted Mist stage 2)
--
-- A FULL PLAYER IS NOT OFFERED A BERRY. At CarryCap Dewberries carried (the
-- DewberriesCarried player attribute PlayerDataService publishes) every berry's
-- Collect Dewberry prompt is put out of reach ON THIS CLIENT -- its reach set
-- to 0, as PromptUI does for another player's plot -- so the key and the tap
-- reach nothing, while every other player still sees and takes the berry. The
-- reach comes back when a delivery drops the count under the cap. A reach
-- somebody else writes while this player is full (PromptHoldLock giving one
-- back at the end of a hold) is put out again.
--
-- Carrying a pod needs nothing here: PromptUI hides every prompt then.
--
-- Courtesy, not enforcement: EnchantedMistBerryService refuses a full player's
-- pick whether or not this ran, and the berry stays for somebody else.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

local B = EnchantedMistConfig.Berries
local CARRIED = EnchantedMistConfig.PlayerAttributes.Carried
local CAP = EnchantedMistData.CarryCap
-- The reach the server builds every berry prompt with.
local REACH = EnchantedMistData.Spawn.Reach

local player = Players.LocalPlayer

-- Every berry prompt on this client, and the watch on its reach.
local berries: { [ProximityPrompt]: RBXScriptConnection } = {}

local function full(): boolean
	return (tonumber(player:GetAttribute(CARRIED)) or 0) >= CAP
end

local function isBerryPrompt(x: Instance): boolean
	return x:IsA("ProximityPrompt") and x.Name == B.PromptName and x:GetAttribute(B.BerryAttribute) ~= nil
end

local function track(prompt: ProximityPrompt)
	if berries[prompt] then
		return
	end
	berries[prompt] = prompt:GetPropertyChangedSignal("MaxActivationDistance"):Connect(function()
		if full() and prompt.MaxActivationDistance ~= 0 then
			prompt.MaxActivationDistance = 0
		end
	end)
	if full() then
		prompt.MaxActivationDistance = 0
	end
end

local function forget(x: Instance)
	local watch = berries[x :: any]
	if watch then
		watch:Disconnect()
		berries[x :: any] = nil
	end
end

-- The server's berry folder: only its descendants are looked at, never the
-- whole Workspace's.
local function watchFolder(folder: Instance)
	folder.DescendantAdded:Connect(function(x)
		if isBerryPrompt(x) then
			track(x :: ProximityPrompt)
		end
	end)
	folder.DescendantRemoving:Connect(forget)
	for _, x in ipairs(folder:GetDescendants()) do
		if isBerryPrompt(x) then
			track(x :: ProximityPrompt)
		end
	end
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name == B.FolderName and child:IsA("Folder") then
		watchFolder(child)
	end
end)
local folder = Workspace:FindFirstChild(B.FolderName)
if folder and folder:IsA("Folder") then
	watchFolder(folder)
end

-- A pick to the cap puts every berry out of reach; a delivery gives them back.
player:GetAttributeChangedSignal(CARRIED):Connect(function()
	local nowFull = full()
	for prompt in pairs(berries) do
		if prompt.Parent then
			if nowFull then
				prompt.MaxActivationDistance = 0
			elseif prompt.MaxActivationDistance == 0 then
				prompt.MaxActivationDistance = REACH
			end
		end
	end
end)
