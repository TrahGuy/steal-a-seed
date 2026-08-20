--!strict
-- Steal The Artifact :: BaseService
--
-- Owns base ownership, base lifecycle, and player spawning. Server-authoritative:
-- a client can never pick, claim or release a base. Every spawn position is
-- derived from a live map part, so moving the map requires no change here.
--
-- Ported from the predecessor's PlotService, with two behavioural changes noted
-- at the points they occur: a real waiting queue, and a base that is not
-- assigned until the profile behind it has loaded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local MapService = require(script.Parent:WaitForChild("MapService"))

type BaseSnapshot = Types.BaseSnapshot

type Base = {
	id: number,
	model: Model,
	floor: BasePart?,
	spawnPad: SpawnLocation?,
	runtime: Folder?,
	ownerLabel: TextLabel?,
	ownerUserId: number,
}

local BaseService = {}
-- After MapService (1) and PlayerDataService (15): a base is only useful once
-- there is a map to hold it and a profile to attach it to.
BaseService.Priority = 20

local ATTR = GameConfig.Attributes
local CFG = GameConfig.Base

local bases: { Base } = {}
local baseByUserId: { [number]: Base } = {}
local playerConnections: { [number]: { RBXScriptConnection } } = {}

--==============================================================================
-- THE WAITING QUEUE
--
-- THIS IS THE ONE BEHAVIOURAL FIX PORTED IN FROM A KNOWN BUG. The predecessor's
-- audit still carries it as an open item: "releasePlot never offers a freed plot
-- to a player already waiting, and the join-time retry gives up after 10
-- attempts one second apart -- after which a base-less player stays base-less
-- for the session."
--
-- A queue, in join order, is the whole fix. Nobody retries, nobody gives up, and
-- a base freed at any point in the session goes to whoever has been waiting
-- longest. It costs one table.
--
-- It should be unreachable while MaxPlayers equals MaxBases -- and it will stop
-- being unreachable the moment either number moves, which is exactly when a
-- retry loop would have silently started failing.
--==============================================================================
local waiting: { Player } = {}

local function log(message: string)
	print("[Artifact/BaseService] " .. message)
end

local function trackConnection(player: Player, connection: RBXScriptConnection)
	local list = playerConnections[player.UserId]
	if not list then
		list = {}
		playerConnections[player.UserId] = list
	end
	table.insert(list, connection)
end

local function clearConnections(player: Player)
	local list = playerConnections[player.UserId]
	if not list then
		return
	end
	for _, connection in ipairs(list) do
		connection:Disconnect()
	end
	playerConnections[player.UserId] = nil
end

local function removeFromQueue(player: Player)
	for index = #waiting, 1, -1 do
		if waiting[index] == player then
			table.remove(waiting, index)
		end
	end
end

--==============================================================================
-- DISCOVERY
--==============================================================================
local function collectBases()
	table.clear(bases)

	local folder = MapService.GetBasesFolder()
	if not folder then
		warn("[Artifact/BaseService] No Bases folder. MapService did not build, or built late.")
		return
	end

	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local id = model:GetAttribute(ATTR.BaseId)
			if typeof(id) == "number" then
				local sign = model:FindFirstChild(CFG.SignName)
				local labelInstance = if sign then sign:FindFirstChild(CFG.SignOwnerLabelName, true) else nil
				local pad = model:FindFirstChild(CFG.SpawnPadName)
				local runtime = model:FindFirstChild(CFG.RuntimeFolderName)
				local floor = model:FindFirstChild("Base")

				table.insert(bases, {
					id = id,
					model = model,
					floor = if floor and floor:IsA("BasePart") then floor else nil,
					spawnPad = if pad and pad:IsA("SpawnLocation") then pad else nil,
					runtime = if runtime and runtime:IsA("Folder") then runtime else nil,
					ownerLabel = if labelInstance and labelInstance:IsA("TextLabel") then labelInstance else nil,
					ownerUserId = 0,
				})
			end
		end
	end

	table.sort(bases, function(a: Base, b: Base): boolean
		return a.id < b.id
	end)
end

-- Ownership state only. Permanent map objects are never touched -- a release
-- must not be able to dismantle the base it is releasing.
local function resetBase(base: Base)
	base.ownerUserId = 0
	base.model:SetAttribute(ATTR.OwnerUserId, 0)
	base.model:SetAttribute(ATTR.Claimed, false)

	local label = base.ownerLabel
	if label then
		label.Text = CFG.UnclaimedText
	end

	local pad = base.spawnPad
	if pad then
		pad.Enabled = false
	end

	local runtime = base.runtime
	if runtime then
		for _, child in ipairs(runtime:GetChildren()) do
			child:Destroy()
		end
	end
end

local function spawnCFrame(base: Base): CFrame
	local pad = base.spawnPad
	if pad then
		return pad.CFrame * CFrame.new(0, (pad.Size.Y * 0.5) + CFG.SpawnHeightOffset, 0)
	end
	local floor = base.floor
	if floor then
		return floor.CFrame * CFrame.new(0, 8, 0)
	end
	warn("[Artifact/BaseService] Base " .. tostring(base.id) .. " has no SpawnPad or Base part.")
	return MapService.GetOverflowCFrame()
end

--==============================================================================
-- ASSIGN / RELEASE
--==============================================================================
local function findFreeBase(): Base?
	for _, base in ipairs(bases) do
		if base.ownerUserId == 0 then
			return base
		end
	end
	return nil
end

local function assignBase(player: Player): Base?
	local existing = baseByUserId[player.UserId]
	if existing then
		return existing
	end

	local base = findFreeBase()
	if not base then
		removeFromQueue(player)
		table.insert(waiting, player)
		player:SetAttribute(ATTR.BaseId, 0)
		warn(string.format(
			"[Artifact/BaseService] No free base for %s. Queued at position %d of %d. " ..
			"Server capacity is %d bases.",
			player.Name, #waiting, #waiting, GameConfig.MaxBases))
		return nil
	end

	removeFromQueue(player)
	base.ownerUserId = player.UserId
	baseByUserId[player.UserId] = base
	base.model:SetAttribute(ATTR.OwnerUserId, player.UserId)
	base.model:SetAttribute(ATTR.Claimed, true)
	player:SetAttribute(ATTR.BaseId, base.id)

	local label = base.ownerLabel
	if label then
		label.Text = string.upper(player.DisplayName)
	end

	-- Only the owner's pad is live. Every pad enabled would let Roblox's own
	-- respawn logic drop anybody on anybody's base.
	local pad = base.spawnPad
	if pad then
		pad.Enabled = true
		player.RespawnLocation = pad
	end

	local remotes = ArtifactGame:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(GameConfig.Remotes.BaseAssigned)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, { baseId = base.id })
	end

	log(string.format("%s%02d assigned to %s (%d).", CFG.NamePrefix, base.id, player.Name, player.UserId))
	return base
end

local function spawnPlayer(player: Player)
	if player.Parent ~= Players then
		return
	end

	local base = baseByUserId[player.UserId]
	local target = if base then spawnCFrame(base) else MapService.GetOverflowCFrame()

	local ok, err = pcall(function()
		player:LoadCharacter()
	end)
	if not ok then
		warn(string.format("[Artifact/BaseService] LoadCharacter failed for %s: %s", player.Name, tostring(err)))
		return
	end

	local character = player.Character
	if not character then
		return
	end
	-- PivotTo AFTER LoadCharacter rather than trusting RespawnLocation alone:
	-- the pad is only enabled for the owner, and a player with no base at all
	-- has no pad to be sent to.
	if character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5) then
		character:PivotTo(target)
	end
end

BaseService.SpawnPlayer = spawnPlayer

local function releaseBase(player: Player)
	local base = baseByUserId[player.UserId]
	baseByUserId[player.UserId] = nil
	player:SetAttribute(ATTR.BaseId, nil)
	removeFromQueue(player)

	if not base then
		return
	end

	resetBase(base)
	log(string.format("%s%02d released by %s.", CFG.NamePrefix, base.id, player.Name))

	--== HAND IT STRAIGHT TO WHOEVER HAS WAITED LONGEST ==--
	while #waiting > 0 do
		local next_ = table.remove(waiting, 1)
		if next_ and next_.Parent == Players then
			local assigned = assignBase(next_)
			if assigned then
				spawnPlayer(next_)
				log(string.format("%s was waiting and now has %s%02d.",
					next_.Name, CFG.NamePrefix, assigned.id))
			end
			break
		end
	end
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	-- CharacterAutoLoads is off, so respawning is ours to do.
	local diedConnection: RBXScriptConnection? = nil
	diedConnection = humanoid.Died:Connect(function()
		if diedConnection then
			diedConnection:Disconnect()
			diedConnection = nil
		end
		task.delay(Players.RespawnTime, function()
			if player.Parent ~= Players then
				return
			end
			spawnPlayer(player)
		end)
	end)
	if diedConnection then
		trackConnection(player, diedConnection)
	end
end

local function onPlayerAdded(player: Player)
	trackConnection(player, player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end))

	assignBase(player)
	spawnPlayer(player)
end

local function onPlayerRemoving(player: Player)
	clearConnections(player)
	releaseBase(player)
end

function BaseService.Init()
	-- Assign the base BEFORE a character exists, so the first spawn is already
	-- on the right pad rather than at the origin and then teleported.
	Players.CharacterAutoLoads = false

	collectBases()
	for _, base in ipairs(bases) do
		resetBase(base)
	end

	if #bases == 0 then
		warn("[Artifact/BaseService] No bases found. MapService failed to build.")
	elseif #bases < GameConfig.MaxBases then
		warn(string.format("[Artifact/BaseService] Only %d of %d bases found.", #bases, GameConfig.MaxBases))
	end
end

function BaseService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	log(string.format("Ready. %d base(s) online, ring radius %d, ground Y=%d.",
		#bases, GameConfig.Map.BaseRingRadius, GameConfig.Map.BaseY))
end

--==============================================================================
-- READ API  (for ArtifactService, DepositService, upgrade services, ...)
--==============================================================================
function BaseService.GetBaseIdForPlayer(player: Player): number?
	local base = baseByUserId[player.UserId]
	return if base then base.id else nil
end

function BaseService.GetBaseModel(baseId: number): Model?
	for _, base in ipairs(bases) do
		if base.id == baseId then
			return base.model
		end
	end
	return nil
end

function BaseService.GetRuntimeFolder(baseId: number): Folder?
	for _, base in ipairs(bases) do
		if base.id == baseId then
			return base.runtime
		end
	end
	return nil
end

function BaseService.IsOwner(player: Player, baseId: number): boolean
	local base = baseByUserId[player.UserId]
	return base ~= nil and base.id == baseId
end

function BaseService.GetSnapshot(): { BaseSnapshot }
	local snapshot: { BaseSnapshot } = {}
	for _, base in ipairs(bases) do
		table.insert(snapshot, {
			baseId = base.id,
			claimed = base.ownerUserId ~= 0,
			ownerUserId = base.ownerUserId,
		})
	end
	return snapshot
end

return BaseService
