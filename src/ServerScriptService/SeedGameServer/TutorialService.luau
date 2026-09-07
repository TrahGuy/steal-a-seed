--!strict
-- Only skip/resume/snapshot cross the wire. Gameplay services record successes.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("SeedGame"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Data = require(Shared:WaitForChild("TutorialData"))
local Profiles = require(script.Parent:WaitForChild("PlayerDataService"))
local Service = { Priority = 80 }
local connections: { RBXScriptConnection } = {}
local lastRequest: { [Player]: number } = {}
local channel: RemoteEvent? = nil

function Service.Request(player: Player, command: any): boolean
	if player.Parent ~= Players or type(command) ~= "string"
		or (command ~= "snapshot" and command ~= "skip" and command ~= "resume") then return false end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < .5 then return false end
	lastRequest[player] = now
	local profile = Profiles.Get(player)
	if not profile then return false end
	if command ~= "snapshot" then Profiles.SetTutorialSkipped(player, command == "skip") end
	local remote = channel
	if remote then remote:FireClient(player, Data.Action, profile.Tutorial, profile.Cash) end
	return true
end

function Service.Init()
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	table.clear(lastRequest)
	channel = nil
end

function Service.Start()
	if channel then return end
	local folder = Shared.Parent:FindFirstChild("Remotes")
	local remote = folder and folder:FindFirstChild(Config.Remotes.GameEvent)
	if not remote or not remote:IsA("RemoteEvent") then return end
	channel = remote
	table.insert(connections, remote.OnServerEvent:Connect(function(player, action: any, command: any)
		if action == Data.Action then Service.Request(player, command) end
	end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end))
end

return Service
