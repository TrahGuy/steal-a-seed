--!strict
-- Steal a Seed :: DebugService
--
--==============================================================================
-- THE DEVELOPER CONSOLE
--
-- Sets Speed, mints Cash, spawns pods, moves the player, restocks nests. In a
-- game whose whole progression is Speed and Cash, that is every exploit in the
-- book behind one RemoteEvent -- so THE GATE IS THE FEATURE, and it is the
-- first thing in this file for that reason.
--
-- Allowed: Studio (a private session by definition), the place owner on a live
-- server, and anybody explicitly listed in GameConfig.Debug.UserIds. The check
-- runs HERE, on the server, before the payload is read. The client hides the
-- panel from everybody else, but hiding a panel is a courtesy and a rule
-- enforced only on the client is not a rule.
--
--==============================================================================
-- IT IS EXEMPT FROM RULE 6, OUT LOUD
--
-- Cash mints in EconomyService and nowhere else. This file mints cash, and that
-- is a deliberate exception rather than an oversight: a debug console is not
-- part of the economy, it is a way to stand outside it. The exception is safe
-- only because it CANNOT RUN FOR A PLAYER -- which is the same sentence as the
-- gate above, and the reason that gate is not negotiable.
--
-- If the gate is ever loosened, this becomes a second faucet and Rule 6 is gone.
--
--==============================================================================
-- EVERY ARGUMENT IS A LIE UNTIL CHECKED
--
-- Rule 4. The sender is engine-stamped and can be trusted; nothing else can.
-- Each handler validates its own payload -- a number that is actually a number,
-- a species that actually exists, a weight inside the real range -- because
-- "only I can call it" is an argument that stops being true the moment somebody
-- adds a UserId.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local DebugService = {}

-- Last, so everything it drives is already up.
DebugService.Priority = 90

local connections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/DebugService] " .. message)
end

--==============================================================================
-- THE GATE
--==============================================================================
local function isAllowed(player: Player): boolean
	if not GameConfig.Debug.Enabled then
		return false
	end
	if RunService:IsStudio() then
		return true
	end
	-- A group-owned place has a CreatorId that is the GROUP, so this matches
	-- nobody there. That is what UserIds is for.
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	for _, id in ipairs(GameConfig.Debug.UserIds) do
		if player.UserId == id then
			return true
		end
	end
	return false
end

DebugService.IsAllowed = isAllowed

--==============================================================================
-- SMALL VALIDATORS, USED BY EVERY HANDLER
--==============================================================================
local function num(value: any, lo: number, hi: number): number?
	local n = tonumber(value)
	-- NaN fails every comparison, so it has to be tested rather than clamped.
	if not n or n ~= n then
		return nil
	end
	return math.clamp(n, lo, hi)
end

local function speciesFrom(value: any): SeedData.Species?
	if type(value) ~= "string" then
		return nil
	end
	return SeedData.Get(value)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--==============================================================================
-- THE ACTIONS
--
-- Each returns a short line to echo back at whoever pressed the button, because
-- a debug tool that does its work silently is one you cannot tell apart from a
-- debug tool that is broken.
--==============================================================================
local ACTIONS: { [string]: (Player, { [string]: any }) -> string } = {}

ACTIONS.SetSpeed = function(player, payload)
	local target = num(payload.value, 0, 1e15)
	if not target then
		return "SetSpeed: not a number"
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return "SetSpeed: no profile"
	end
	-- There is only AddSpeed, so a SET is a delta. Reading first also means the
	-- clamp inside PlayerDataService still owns the ceiling.
	PlayerDataService.AddSpeed(player, target - (tonumber(profile.Speed) or 0))
	local now = PlayerDataService.Get(player)
	return string.format("Speed = %s", GameConfig.compact(now and now.Speed or 0))
end

ACTIONS.AddSpeed = function(player, payload)
	local delta = num(payload.value, -1e15, 1e15)
	if not delta then
		return "AddSpeed: not a number"
	end
	PlayerDataService.AddSpeed(player, delta)
	local now = PlayerDataService.Get(player)
	return string.format("Speed = %s", GameConfig.compact(now and now.Speed or 0))
end

ACTIONS.SetCash = function(player, payload)
	local target = num(payload.value, 0, GameConfig.Save.MaxCash or 1e15)
	if not target then
		return "SetCash: not a number"
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return "SetCash: no profile"
	end
	PlayerDataService.AddCash(player, target - (tonumber(profile.Cash) or 0))
	local now = PlayerDataService.Get(player)
	return string.format("Cash = %s", GameConfig.compact(now and now.Cash or 0))
end

ACTIONS.AddCash = function(player, payload)
	local delta = num(payload.value, -1e15, 1e15)
	if not delta then
		return "AddCash: not a number"
	end
	PlayerDataService.AddCash(player, delta)
	local now = PlayerDataService.Get(player)
	return string.format("Cash = %s", GameConfig.compact(now and now.Cash or 0))
end

--==============================================================================
-- SPAWN A POD
--
-- Built by the real builder, tagged the real tag, and left for the real prompt
-- to find -- the same three steps CarryService takes when a pod is dropped. A
-- debug pod that was special in any way would be a debug pod that could not
-- reproduce a bug in the ordinary one.
--
-- It does NOT expire. A dropped pod has a lifetime because the road would fill
-- up with them; a pod you spawned to look at should still be there when you
-- finish looking.
--==============================================================================
ACTIONS.SpawnPod = function(player, payload)
	local root = rootOf(player)
	if not root then
		return "SpawnPod: no character"
	end
	local species: SeedData.Species?
	if payload.species == "random" or payload.species == nil then
		local biome = if type(payload.biome) == "string" then payload.biome else "greenhollow"
		species = SeedData.Roll(biome, Random.new(os.clock() * 1000 % 1e6))
	else
		species = speciesFrom(payload.species)
	end
	if not species then
		return "SpawnPod: unknown species"
	end
	local kg = num(payload.kg, 1, GameConfig.Carry.MaxKg)
	if not kg then
		kg = SeedData.RollKg(Random.new(os.clock() * 1000 % 1e6))
	end
	kg = math.floor(kg :: number)

	local at = root.CFrame * CFrame.new(0, -root.Size.Y * 0.5, -6)
	local pod = CreatureModel.BuildPod(species :: SeedData.Species, kg,
		CFrame.new(at.Position.X, at.Position.Y, at.Position.Z), Workspace)
	CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	return string.format("spawned %s at %d kg", (species :: SeedData.Species).Name, kg)
end

ACTIONS.SetMill = function(player, payload)
	local tier = num(payload.tier, 1, #GameConfig.Mill.Tiers)
	local over = num(payload.overclock, 0, GameConfig.Mill.Overclock.MaxLevel)
	if tier then
		PlayerDataService.SetMillTier(player, math.floor(tier))
	end
	if over then
		PlayerDataService.SetMillOverclock(player, math.floor(over))
	end
	return string.format("mill tier %s, overclock %s",
		tostring(tier and math.floor(tier)), tostring(over and math.floor(over)))
end

ACTIONS.SetPlotTier = function(player, payload)
	local tier = num(payload.value, 1, 99)
	if not tier then
		return "SetPlotTier: not a number"
	end
	PlayerDataService.SetPlotTier(player, math.floor(tier))
	return string.format("plot tier %d", math.floor(tier))
end

--==============================================================================
-- TELEPORT
--
-- The character is moved rather than the camera, and by CFrame rather than by
-- MoveTo, because the point is usually to BE somewhere -- at a nest, past the
-- red line -- rather than to walk there.
--==============================================================================
ACTIONS.Teleport = function(player, payload)
	local root = rootOf(player)
	if not root then
		return "Teleport: no character"
	end
	local where = payload.where
	if where == "plot" then
		local cf = PlotService.SpawnCFrameFor(player)
		if not cf then
			return "Teleport: no plot"
		end
		root.CFrame = cf + Vector3.new(0, 4, 0)
		return "at your plot"
	end
	if where == "field" then
		root.CFrame = CFrame.new(0, GameConfig.Map.GroundY + 5, 40)
		return "in the field"
	end
	if type(where) ~= "string" then
		return "Teleport: where?"
	end
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Id == where then
			local nests = BiomeData.NestCFrames(biome)
			local target = nests[1]
			if not target then
				local nearZ, farZ = BiomeData.SegmentBounds(biome)
				target = CFrame.new(0, GameConfig.Map.GroundY, (nearZ + farZ) * 0.5)
			end
			root.CFrame = target + Vector3.new(0, 6, 12)
			return "at " .. biome.DisplayName
		end
	end
	return "Teleport: unknown place " .. where
end

--==============================================================================
-- NESTS
--==============================================================================
ACTIONS.RestockNests = function(_player, _payload)
	-- StockAll returns (built, wanted) -- POD counts, not nest counts. Labelling
	-- them as nests read as "11 nests" against a road that has three.
	local built, wanted = NestService.StockAll()
	return string.format("%d of %d pod(s) standing", built, wanted)
end

ACTIONS.ResetParents = function(_player, _payload)
	local n = NestService.ResetParents()
	return string.format("sent %d parent(s) home", n)
end

ACTIONS.WakeNearest = function(player, _payload)
	local root = rootOf(player)
	if not root then
		return "WakeNearest: no character"
	end
	local best, bestDist = nil, math.huge
	for _, model in ipairs(CollectionService:GetTagged(GameConfig.Tags.NestParent)) do
		local pp = (model :: Model).PrimaryPart
		if pp then
			local d = (pp.Position - root.Position).Magnitude
			if d < bestDist then
				best, bestDist = model, d
			end
		end
	end
	if not best then
		return "WakeNearest: no parents"
	end
	local nestId = (best :: Model).Parent and (best :: Model).Parent.Name
	if type(nestId) == "string" and NestService.Provoke(nestId, player) then
		return string.format("provoked %s (%.0f studs away)", (best :: Model).Name, bestDist)
	end
	return "WakeNearest: could not provoke " .. (best :: Model).Name
end

--==============================================================================
-- THE BAG
--==============================================================================
ACTIONS.ClearBag = function(player, _payload)
	local n = 0
	local function strip(container: Instance?)
		if not container then
			return
		end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
				n += 1
			end
		end
	end
	strip(player:FindFirstChildOfClass("Backpack"))
	strip(player.Character)
	return string.format("cleared %d item(s)", n)
end

ACTIONS.SellBag = function(player, _payload)
	local sold, paid = EconomyService.SellHeld(player)
	return string.format("sold %d item(s) for %s", sold, GameConfig.compact(paid))
end

ACTIONS.DropCarry = function(player, _payload)
	if not CarryService.IsCarrying(player) then
		return "not carrying anything"
	end
	CarryService.ForfeitCarry(player)
	return "dropped the carried pod"
end

--==============================================================================
-- WHAT THE SERVER THINKS IS TRUE
--
-- Every service already has a Snapshot; this just collects them, so a bug report
-- can carry the server's own words rather than a description of them.
--==============================================================================
ACTIONS.Snapshot = function(player, _payload)
	local profile = PlayerDataService.Get(player)
	local lines = {
		string.format("cash %s  speed %s",
			GameConfig.compact(profile and profile.Cash or 0),
			GameConfig.compact(profile and profile.Speed or 0)),
		NestService.Snapshot(),
		CarryService.Snapshot(),
	}
	log(player.Name .. " snapshot:\n  " .. table.concat(lines, "\n  "))
	return "snapshot printed to the server log"
end

--==============================================================================
function DebugService.Init()
end

function DebugService.Start()
	local seedGame = ReplicatedStorage:WaitForChild("SeedGame")
	local remotes = seedGame:WaitForChild("Remotes")
	local channel = remotes:FindFirstChild(GameConfig.Remotes.DebugCommand)
	if not (channel and channel:IsA("RemoteEvent")) then
		warn("[Seed/DebugService] no DebugCommand remote; console is off")
		return
	end

	table.insert(connections, (channel :: RemoteEvent).OnServerEvent:Connect(
		function(player: Player, action: any, payload: any)
			--==================================================================
			-- THE GATE, BEFORE THE PAYLOAD IS EVEN LOOKED AT
			--==================================================================
			if not isAllowed(player) then
				-- Logged, because an unauthorised call is either a bug in the
				-- client gate or somebody probing the remote, and both are
				-- things to know about.
				warn(string.format(
					"[Seed/DebugService] REFUSED debug command from %s (%d)",
					player.Name, player.UserId))
				return
			end
			if type(action) ~= "string" then
				return
			end
			local handler = ACTIONS[action]
			if not handler then
				log(string.format("%s asked for unknown action %q", player.Name, action))
				return
			end
			local safePayload: { [string]: any } = if type(payload) == "table"
				then payload
				else {}
			local ok, result = pcall(handler, player, safePayload)
			if not ok then
				warn(string.format("[Seed/DebugService] %s failed: %s", action, tostring(result)))
				;(channel :: RemoteEvent):FireClient(player, action, "failed: " .. tostring(result))
				return
			end
			log(string.format("%s: %s -> %s", player.Name, action, tostring(result)))
			;(channel :: RemoteEvent):FireClient(player, action, tostring(result))
		end))

	log(string.format("Ready. %d action(s); Studio and the place owner only.",
		(function()
			local n = 0
			for _ in pairs(ACTIONS) do
				n += 1
			end
			return n
		end)()))
end

function DebugService.Stop()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
end

return DebugService
