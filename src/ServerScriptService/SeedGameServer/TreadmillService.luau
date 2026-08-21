--!strict
-- Steal a Seed :: TreadmillService
--
-- THE FAUCET FOR SPEED. The same shape as EconomyService is for cash: this is
-- the only thing in the game that calls PlayerDataService.AddSpeed.
--
--==============================================================================
-- AND IT NEVER WRITES WalkSpeed
--
-- CarryService owns that property outright. This raises the Speed SCORE and
-- then asks CarryService to recompute, because WalkSpeed is the product of two
-- things -- the score and what you are carrying -- and a service that knows
-- only one of them will write the wrong number every time it is holding a pod.
--
--     Speed score  ->  GameConfig.walkSpeedFor  ->  x carry multiplier  ->  WalkSpeed
--                                                   ^ CarryService owns this whole line
--
--==============================================================================
-- OCCUPANCY IS ENOUGH. YOU DO NOT HAVE TO HOLD W.
--
-- Standing on the belt pays. Making the player hold a key to earn the slow
-- floor rate turns a background activity into a chore, and a chore is what
-- people auto-click rather than play around.
--
-- Tested by TRANSFORMING the root into the belt's own frame rather than by
-- Touched: the belt is a static part a player can stand on for ten minutes
-- without ever firing Touched again after the first frame, and a region check
-- is also immune to standing on somebody's head above it.
--
--==============================================================================
-- YOUR MILL, NOT THE NEAREST ONE
--
-- Matched on the PlotId the map already stamps on both the plot and the
-- treadmill. Six mills sit in a ring and the walk between two of them is short;
-- without this, the person whose plot you are standing next to pays for your
-- training.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local MILL = GameConfig.Treadmill
local ATTR = GameConfig.Attributes

local TreadmillService = {}
-- After CarryService (45), whose RefreshWalkSpeed this calls.
TreadmillService.Priority = 60

local TICK = MILL.TickSeconds
-- How far above the belt's top face still counts as standing on it. A root sits
-- about three studs up; the ceiling is generous enough for a jump and mean
-- enough to exclude somebody on the handrail.
local STAND_HEIGHT = 6.5
-- Lets a player earn while their toes are over the edge.
local EDGE_MARGIN = 1.2

local lastPaid: { [Player]: number } = {}
local granted: { [Player]: number } = {}
local running = false
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/TreadmillService] " .. message)
end

--==============================================================================
-- FINDING THE BELTS
--==============================================================================
local function beltFor(plotId: number): BasePart?
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") and belt.Parent then
			local id = belt.Parent:GetAttribute(ATTR.PlotId)
			if id == plotId then
				return belt
			end
		end
	end
	return nil
end

local function standingOn(root: BasePart, belt: BasePart): boolean
	-- Into the belt's own frame, so a rotated mill is no different from an
	-- axis-aligned one. Six of these sit in a ring and every one is rotated.
	local local_ = belt.CFrame:PointToObjectSpace(root.Position)
	local half = belt.Size * 0.5
	if math.abs(local_.X) > half.X + EDGE_MARGIN then
		return false
	end
	if math.abs(local_.Z) > half.Z + EDGE_MARGIN then
		return false
	end
	local above = local_.Y - half.Y
	return above > -1 and above < STAND_HEIGHT
end

--==============================================================================
-- WHO IS EARNING, AND HOW FAST
--==============================================================================
function TreadmillService.RateFor(player: Player): number
	if not PlayerDataService.IsReady(player) then
		return 0
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	-- Alive. A ragdolled or dead player on the belt is not training.
	if not (humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		return 0
	end
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		return 0
	end
	local plotId = plot:GetAttribute(ATTR.PlotId)
	if type(plotId) ~= "number" then
		return 0
	end
	local belt = beltFor(plotId)
	if not belt or not standingOn(root :: BasePart, belt) then
		return 0
	end
	return MILL.SpeedPerSecond
end

--==============================================================================
-- THE TICK
--==============================================================================
local function payEveryone()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local rate = TreadmillService.RateFor(player)
		if rate > 0 then
			local since = lastPaid[player]
			lastPaid[player] = now
			if since then
				local dt = now - since
				-- Same hitch rule as the cash faucet: pay for time actually
				-- elapsed, but never a lump for a gap this long -- that gap
				-- means they stepped off and came back.
				if dt > 0 and dt < 30 then
					if PlayerDataService.AddSpeed(player, rate * dt) then
						granted[player] = (granted[player] or 0) + rate * dt
						-- CarryService owns WalkSpeed. Ask, do not write.
						CarryService.RefreshWalkSpeed(player)
					end
				end
			end
		else
			-- Off the belt. Clearing this is what stops a player who wandered
			-- away for a minute from being paid for the minute when they
			-- step back on.
			lastPaid[player] = nil
		end
	end
end

local function forget(player: Player)
	lastPaid[player] = nil
	granted[player] = nil
end

--==============================================================================
-- THE SIGN ON THE MILL
--
-- Server-built and static: it says the RATE, which is a property of the mill
-- rather than of whoever is standing on it. Nothing here updates per player, so
-- there is nothing to replicate.
--==============================================================================
local function signOn(belt: BasePart)
	local existing = belt:FindFirstChild("MillSign")
	if existing then
		existing:Destroy()
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MillSign"
	billboard.Adornee = belt
	billboard.AlwaysOnTop = false
	billboard.Size = UDim2.fromOffset(150, 46)
	billboard.StudsOffset = Vector3.new(0, belt.Size.Y * 0.5 + 4.2, 0)
	billboard.MaxDistance = 120
	billboard.Parent = belt

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(26, 24, 30)
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel = 0
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(142, 196, 62)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(142, 196, 62)
	label.Text = string.format("+%g/step", MILL.SpeedPerSecond)
	label.Parent = panel
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function TreadmillService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastPaid)
	table.clear(granted)
end

function TreadmillService.Start()
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	local mills = 0
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") then
			signOn(belt)
			mills += 1
		end
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Treadmill):Connect(function(belt)
			if belt:IsA("BasePart") then
				signOn(belt)
			end
		end))

	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			local ok, err = pcall(payEveryone)
			if not ok then
				warn("[Seed/TreadmillService] pay tick failed: " .. tostring(err))
			end
		end
	end)

	log(string.format(
		"Ready. The only faucet for Speed: +%g/sec while the owner stands on their own mill. %d mill(s).",
		MILL.SpeedPerSecond, mills))
end

function TreadmillService.Snapshot(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		table.insert(rows, string.format("%s: %s, Speed %.0f (+%.0f this session)",
			player.Name,
			if TreadmillService.RateFor(player) > 0 then "ON the belt" else "off",
			profile and profile.Speed or 0, granted[player] or 0))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody training"
end

return TreadmillService
