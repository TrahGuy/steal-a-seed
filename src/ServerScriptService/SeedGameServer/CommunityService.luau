--!strict
-- Steal a Seed :: CommunityService
--
-- THE COMMUNITY CHEST (2026-10-01, the owner's brief; GameConfig.Community)
--
-- Builds the chest and the glowing circle in front of it, and answers one verb,
-- CheckAction, sent by CommunityChestUI in two steps:
--   * FIRST, when the player steps on the circle (carrying nothing): one look.
--     A member who has not claimed is granted there and then -- no dialog. A
--     non-member is answered "join", and the client opens Roblox's own prompt.
--   * "verify", once the prompt has closed: honoured once per "join" sent,
--     without the cooldown; asked VerifyTries times, VerifyGapSeconds apart,
--     because a join can take a moment to show. Any other "verify" is a first
--     look again, under the cooldown.
-- The client's word about the prompt is never read. Membership is Roblox's
-- answer -- GroupService:GetGroupsAsync, a fresh one; Player:IsInGroup is
-- cached for the server's life and would say "no" to a join made this session.
-- A member is handed to WheelService.GrantCommunity, which gives the spins once
-- per saved profile and saves them with the flag. A cancelled prompt is a
-- non-member and gets nothing; a join not yet visible is told to try again,
-- and can.
--
-- Answers sent back (ResultAction): "granted", "claimed", "join" (not a member:
-- show the prompt), "notmember" (still not, after the prompt), "retry" (Roblox
-- would not answer), "save" (the save failed and was taken back), "full" (no
-- room on the earned balance), "busy"/"wait" (a check already in flight, or too
-- soon after the last), "unavailable".
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))

local COMMUNITY = GameConfig.Community

local CommunityService = {}
-- After the wheel (62), whose grant this calls.
CommunityService.Priority = 64

local running = false
local channel: RemoteEvent? = nil
local serviceConnections: { RBXScriptConnection } = {}
local checking: { [Player]: boolean } = {}
-- Players answered "join" whose verify is still owed.
local prompted: { [Player]: boolean } = {}
local lastCheck: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function log(message: string)
	print("[Seed/CommunityService] " .. message)
end

--==============================================================================
-- MEMBERSHIP, AND THE SPEC'S SEAMS (Studio only)
--==============================================================================
local membershipFn: ((Player) -> boolean?)? = nil
local waitFn: (number) -> () = function(seconds: number)
	task.wait(seconds)
end
local replyFn: ((Player, { [string]: any }) -> ())? = nil

function CommunityService.useMembership(fn: ((Player) -> boolean?)?): boolean
	if not RunService:IsStudio() then
		return false
	end
	membershipFn = fn
	return true
end

function CommunityService.useWait(fn: ((number) -> ())?): boolean
	if not RunService:IsStudio() then
		return false
	end
	waitFn = fn or function(seconds: number)
		task.wait(seconds)
	end
	return true
end

function CommunityService.useReply(fn: ((Player, { [string]: any }) -> ())?): boolean
	if not RunService:IsStudio() then
		return false
	end
	replyFn = fn
	return true
end

-- True a member, false not, nil when Roblox would not say.
local function isMember(player: Player): boolean?
	local hook = membershipFn
	if hook then
		return hook(player)
	end
	local ok, groups = pcall(function()
		return GroupService:GetGroupsAsync(player.UserId)
	end)
	if not ok or type(groups) ~= "table" then
		return nil
	end
	for _, group in ipairs(groups) do
		if type(group) == "table" and group.Id == COMMUNITY.GroupId then
			return true
		end
	end
	return false
end

--==============================================================================
-- THE CLAIMED STATE, FOR THIS PLAYER'S OWN CHEST
--==============================================================================
local function publishClaimed(player: Player)
	local profile = PlayerDataService.Get(player)
	local value = if profile and (profile :: any).CommunityClaimed == true then true else nil
	if player:GetAttribute(COMMUNITY.ClaimedAttribute) ~= value then
		player:SetAttribute(COMMUNITY.ClaimedAttribute, value)
	end
end
CommunityService.PublishClaimed = publishClaimed

--==============================================================================
-- THE CHECK
--==============================================================================
function CommunityService.Check(player: Player, stage: string?): string
	if checking[player] then
		return "busy"
	end
	local verify = stage == "verify" and prompted[player] == true
	prompted[player] = nil
	local now = os.clock()
	if not verify and now - (lastCheck[player] or -math.huge) < COMMUNITY.CheckCooldownSeconds then
		return "wait"
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return "unavailable"
	end
	if (profile :: any).CommunityClaimed == true then
		publishClaimed(player)
		return "claimed"
	end
	checking[player] = true
	lastCheck[player] = now
	local outcome = "notmember"
	-- The first look asks once, so a non-member's prompt opens without a wait.
	local tries = if verify then COMMUNITY.VerifyTries else 1
	local ok, err = pcall(function()
		local member: boolean? = nil
		for attempt = 1, tries do
			member = isMember(player)
			if member == true or player.Parent ~= Players then
				break
			end
			if attempt < tries then
				waitFn(COMMUNITY.VerifyGapSeconds)
			end
		end
		if player.Parent ~= Players then
			outcome = "unavailable"
		elseif member == nil then
			outcome = "retry"
		elseif member == false then
			outcome = if verify then "notmember" else "join"
		else
			outcome = WheelService.GrantCommunity(player)
		end
	end)
	checking[player] = nil
	if not ok then
		warn(string.format("[Seed/CommunityService] %s's check stopped: %s", player.Name, tostring(err)))
		outcome = "unavailable"
	end
	if outcome == "join" then
		prompted[player] = true
	end
	publishClaimed(player)
	return outcome
end

local function reply(player: Player, outcome: string)
	local payload = { outcome = outcome }
	local hook = replyFn
	if hook then
		hook(player, payload)
		return
	end
	local remote = channel
	if remote and player.Parent == Players then
		remote:FireClient(player, COMMUNITY.ResultAction, payload)
	end
end

--==============================================================================
-- THE CHEST AND THE CIRCLE: the Bonus Chest's blocks, in the community's blue,
-- and a lit disc on the deck in front of it. Nothing here takes a touch: the
-- client watches the circle for its own body (CommunityChestUI).
--==============================================================================
local WOOD = Color3.fromRGB(150, 98, 58)
local LID = Color3.fromRGB(72, 104, 214)
local GOLD = Color3.fromRGB(240, 196, 72)
local PLINTH = Color3.fromRGB(128, 132, 124)

local function part(model: Model, name: string, size: Vector3, cf: CFrame, colour: Color3,
	material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = model
	return p
end

local function build(): Model
	local old = Workspace:FindFirstChild(COMMUNITY.FolderName)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = COMMUNITY.FolderName
	folder.Archivable = false

	local model = Instance.new("Model")
	model.Name = "CommunityChest"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local origin = CFrame.new(COMMUNITY.Position) * CFrame.Angles(0, math.rad(COMMUNITY.FacingDegrees), 0)
	local plinth = part(model, "Plinth", Vector3.new(5.6, 0.5, 4.4), origin * CFrame.new(0, 0.25, 0),
		PLINTH, Enum.Material.Slate)
	part(model, "Body", Vector3.new(4, 2.2, 2.8), origin * CFrame.new(0, 1.6, 0), WOOD, Enum.Material.WoodPlanks)
	part(model, "Lid", Vector3.new(4.2, 1.0, 3.0), origin * CFrame.new(0, 3.2, 0), LID, Enum.Material.SmoothPlastic)
	for _, x in ipairs({ -1.35, 1.35 }) do
		part(model, "Band", Vector3.new(0.35, 3.35, 3.1), origin * CFrame.new(x, 2.18, 0), GOLD, Enum.Material.Metal)
	end
	local lock = part(model, "Lock", Vector3.new(0.8, 0.9, 0.3), origin * CFrame.new(0, 2.7, -1.55), GOLD,
		Enum.Material.Metal)
	lock.CanCollide = false
	model.PrimaryPart = plinth

	-- The circle, on the deck's surface (y 0.9) in front of the chest.
	local deckTop = 0.9
	local at = origin * CFrame.new(0, 0, -COMMUNITY.PadAhead)
	local flat = CFrame.Angles(0, 0, math.rad(90))
	local pad = part(model, "StepPad", Vector3.new(0.14, COMMUNITY.PadRadius * 2, COMMUNITY.PadRadius * 2),
		CFrame.new(at.Position.X, deckTop + 0.07, at.Position.Z) * flat, COMMUNITY.PadColour, Enum.Material.Neon)
	pad.Shape = Enum.PartType.Cylinder
	pad.CanCollide = false
	pad.CanQuery = false
	local rim = part(model, "StepRim", Vector3.new(0.1, COMMUNITY.PadRadius * 2 + 0.8, COMMUNITY.PadRadius * 2 + 0.8),
		CFrame.new(at.Position.X, deckTop + 0.04, at.Position.Z) * flat, Color3.fromRGB(255, 255, 255),
		Enum.Material.Neon)
	rim.Shape = Enum.PartType.Cylinder
	rim.Transparency = 0.45
	rim.CanCollide = false
	rim.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = COMMUNITY.PadColour
	light.Brightness = 2.5
	light.Range = 10
	light.Parent = pad

	model.Parent = folder
	folder.Parent = Workspace
	return model
end
CommunityService.Build = build

--==============================================================================
-- LIFECYCLE
--==============================================================================
function CommunityService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(checking)
	table.clear(prompted)
	channel = nil
end

function CommunityService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	local remote = channel
	if remote then
		table.insert(serviceConnections, remote.OnServerEvent:Connect(function(player: Player, action: any, stage: any)
			if action ~= COMMUNITY.CheckAction then
				return
			end
			local step: string? = if stage == "verify" then "verify" else nil
			task.spawn(function()
				reply(player, CommunityService.Check(player, step))
			end)
		end))
	else
		warn("[Seed/CommunityService] No GameEvent remote; the community chest cannot be claimed.")
	end
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		checking[player] = nil
		prompted[player] = nil
	end))
	running = true
	-- The claimed state once each profile is in, never waited for in Start.
	local function watch(player: Player)
		task.spawn(function()
			local t = os.clock()
			while running and player.Parent == Players and not PlayerDataService.IsReady(player)
				and os.clock() - t < 120 do
				task.wait(0.5)
			end
			if running and player.Parent == Players then
				publishClaimed(player)
			end
		end)
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	local model = build()
	local at = model:GetPivot().Position
	log(string.format("Ready. The community chest stands at (%.0f, %.0f, %.0f); %d spins for community %d.",
		at.X, at.Y, at.Z, COMMUNITY.Spins, COMMUNITY.GroupId))
end

return CommunityService
