--!strict
--==============================================================================
-- Steal a Seed :: InventoryService (2026-10-03, the owner's compact Bag + free
-- hotbar)
--
-- The two verbs a client may send about its Bag, on the GameEvent remote the HUD
-- already owns: HotbarSet (the whole bar, ten refs) and Favourite (refs and
-- on/off). The RULES -- what may be named, what is owned -- are HotbarSlots'
-- and the WRITES are PlayerDataService's (SetHotbar, SetFavourite); this owns
-- only the door: which verb, from whom, how often.
--
-- A TOKEN BUCKET PER PLAYER, CHARGED FIRST. Burst requests at once, refilled at
-- RefillPerSecond (GameConfig.Inventory). The token is taken as soon as the verb
-- matches -- before the payload is even looked at -- so a flood of junk costs its
-- sender and nothing else. A refused request is answered by silence: the client
-- shows the server's bar again when no push follows its edit.
--
-- Nothing here grants, sells or moves an item. A shortcut and a heart are
-- labels on things the server already says are owned.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local INV = GameConfig.Inventory

local InventoryService = {}
-- After PlayerDataService (20), whose setters this calls.
InventoryService.Priority = 25
-- The bucket's clock; a spec replaces it to step time.
InventoryService.Clock = os.clock

type Bucket = { tokens: number, at: number }
local buckets: { [Player]: Bucket } = {}
local connections: { RBXScriptConnection } = {}

local function charge(player: Player): boolean
	local now = InventoryService.Clock()
	local bucket = buckets[player]
	if not bucket then
		bucket = { tokens = INV.Burst, at = now }
		buckets[player] = bucket
	end
	local b = bucket :: Bucket
	b.tokens = math.min(INV.Burst, b.tokens + math.max(0, now - b.at) * INV.RefillPerSecond)
	b.at = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

-- One request, as the remote hands it over. Answers whether anything changed.
-- Exported so a spec can drive it without a remote.
function InventoryService.Handle(player: Player, action: any, payload: any, extra: any): boolean
	if action ~= INV.SetAction and action ~= INV.FavouriteAction then
		return false
	end
	if player.Parent ~= Players or not charge(player) then
		return false
	end
	if action == INV.SetAction then
		return PlayerDataService.SetHotbar(player, payload)
	end
	return PlayerDataService.SetFavourite(player, payload, extra) > 0
end

-- For a spec: forget a player's bucket, as leaving does.
function InventoryService.Forget(player: Player)
	buckets[player] = nil
end

function InventoryService.Init()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(buckets)
end

function InventoryService.Start()
	local remotes = Shared.Parent:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[Seed/InventoryService] No GameEvent remote. The hotbar and the hearts will not be saved.")
		return
	end
	table.insert(connections, remote.OnServerEvent:Connect(function(player: Player, action: any, payload: any,
		extra: any)
		if action == INV.SetAction or action == INV.FavouriteAction then
			InventoryService.Handle(player, action, payload, extra)
		end
	end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		buckets[player] = nil
	end))
end

return InventoryService
