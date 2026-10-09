--!strict
--==============================================================================
-- Steal a Seed :: BatHintService
--
-- THE BAT HINT (2026-10-08, the owner: "change sell to shop and add the hint")
--
-- New players did not know where bats are sold. The first time a player who
-- owns NO bat is chased by a guardian, they are told -- once per profile, ever:
--
--     NO BAT YET?
--     Buy a bat at Marigold's stall to fight back!
--
-- Only once the guide's first loop is done (or the guide was skipped), so it
-- never talks over the guide's own first raid. A hit happens only during a
-- chase, so the chase is the one moment watched.
--
-- One server notice (Notice.ServerNotice on GameEvent), sent in the same step
-- that saves the flag (PlayerDataService.MarkBatHintShown); a progress reset
-- keeps the flag. Reads only: PursuedBy (NestService publishes it), the
-- profile's Weapons and Tutorial. Changes nothing about chases, weapons or
-- Marigold's shop.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local BatHintService = {}
-- After PlayerDataService and NestService; nothing waits on it.
BatHintService.Priority = 120

BatHintService.Title = "NO BAT YET?"
BatHintService.Detail = "Buy a bat at Marigold's stall to fight back!"
BatHintService.Key = "bathint"

local ATTR = GameConfig.Attributes
local channel: RemoteEvent? = nil
local connections: { RBXScriptConnection } = {}
local watching: { [Player]: RBXScriptConnection } = {}
-- Studio seam: the spec reads the notice instead of a client.
local tellFn: ((Player, { [string]: any }) -> ())? = nil

local function log(message: string)
	print("[Seed/BatHintService] " .. message)
end

--==============================================================================
-- THE RULES (pure; BatHintSpec drives them)
--==============================================================================
-- Whether the profile owns any bat (a WeaponData item of Category "bat").
function BatHintService.ownsBat(profile: any): boolean
	if type(profile) ~= "table" or type(profile.Weapons) ~= "table" then
		return false
	end
	for id, on in pairs(profile.Weapons) do
		if on == true then
			local item = WeaponData.Get(id)
			if item and item.Category == "bat" then
				return true
			end
		end
	end
	return false
end

-- Whether this profile is told now: chased, no bat, not told before, and past
-- the guide's first loop (or the guide skipped).
function BatHintService.due(profile: any, pursued: number): boolean
	if type(profile) ~= "table" or profile.BatHintShown == true then
		return false
	end
	if not (type(pursued) == "number" and pursued > 0) then
		return false
	end
	if BatHintService.ownsBat(profile) then
		return false
	end
	local progress = profile.Tutorial
	if type(progress) ~= "table" or type(progress.Done) ~= "table" then
		return false
	end
	return progress.Skipped == true or TutorialData.FirstLoopDone(progress)
end

--==============================================================================
-- THE WATCH
--==============================================================================
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

function BatHintService.Check(player: Player): boolean
	if player.Parent ~= Players or not PlayerDataService.IsReady(player) then
		return false
	end
	local pursued = tonumber(player:GetAttribute(ATTR.PursuedBy)) or 0
	if not BatHintService.due(PlayerDataService.Get(player), pursued) then
		return false
	end
	-- Saved first: a hint the flag does not hold could come back on a rejoin.
	if not PlayerDataService.MarkBatHintShown(player) then
		return false
	end
	tell(player, { title = BatHintService.Title, detail = BatHintService.Detail, key = BatHintService.Key })
	log(player.Name .. " was told where bats are sold.")
	return true
end

local function watch(player: Player)
	if watching[player] then
		return
	end
	watching[player] = player:GetAttributeChangedSignal(ATTR.PursuedBy):Connect(function()
		BatHintService.Check(player)
	end)
end

local function forget(player: Player)
	local c = watching[player]
	if c then
		c:Disconnect()
		watching[player] = nil
	end
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function BatHintService.Init()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for player in pairs(watching) do
		forget(player)
	end
	tellFn = nil
end

function BatHintService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	table.insert(connections, Players.PlayerAdded:Connect(watch))
	table.insert(connections, Players.PlayerRemoving:Connect(forget))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	log("Ready. The first chase of a player with no bat, past the guide's first loop, says where bats are sold.")
end

-- Studio seam for the spec: capture notices instead of firing the remote.
function BatHintService.SpecTell(fn: ((Player, { [string]: any }) -> ())?)
	tellFn = fn
end

return BatHintService
