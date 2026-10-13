--!strict
-- Steal a Seed :: EquipBestPad.client
--
-- THE EQUIP BEST PAD (2026-10-13; Michael's console feedback, the owner's
-- backlog item 1): drawn on THIS player's own plot and nowhere else, so nobody
-- else ever sees it or can stand on it to any effect.
--
-- Stand on it HoldSeconds and its ring fills; then it sends the Garden menu's
-- own EQUIP BEST verb (Plant.MyPlants.Best) on GameEvent -- the same request
-- the menu's button sends, under the same server rules and cooldown, and
-- GardenUI says the answer in the same words as for the button. Then it cools
-- down (CooldownSeconds) and stays spent until the body steps off it.
--
--==============================================================================
-- THE CLIENT SHOWS IT. THE SERVER DECIDES IT.
--
-- Nothing here plants or returns anything. PlantService.EquipBest decides, and
-- refuses what it refuses for the button too.
--
-- WHERE: EquipBestPad.cframeFor the plot's PlotCF (the left grass strip,
-- halfway along the main bed), placed again whenever the plot's frame or
-- level changes (an upgrade), and gone while this player has no plot.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EquipBestPad = require(Shared:WaitForChild("EquipBestPad"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer

local PAD = GameConfig.EquipBestPad
local MY = GameConfig.Plant.MyPlants
local ATTR = GameConfig.Attributes
local FOLDER = "SeedEquipBestPad"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = Workspace:FindFirstChild(FOLDER)
if existing then
	existing:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = FOLDER
folder.Archivable = false
folder.Parent = Workspace

--==============================================================================
-- THE PAD AND ITS WORDS, ON THIS PLAYER'S PLOT
--==============================================================================
local built: EquipBestPad.Built? = nil
local sign: FloatingSign.Sign? = nil
local padAt: CFrame? = nil
local plot: Model? = nil
local plotWatch: { RBXScriptConnection } = {}
local painted = ""

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model") and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

local function clear()
	if built then
		built.model:Destroy()
		built = nil
	end
	if sign then
		sign.destroy()
		sign = nil
	end
	padAt = nil
	painted = ""
end

-- Built again rather than moved: it happens once an upgrade, and a rebuild has
-- no stale part to forget.
local function place()
	clear()
	local p = plot
	local frame = if p then p:GetAttribute("PlotCF") else nil
	if typeof(frame) ~= "CFrame" then
		return
	end
	local at = EquipBestPad.cframeFor(frame)
	padAt = at
	built = EquipBestPad.build(at, folder)
	local words = FloatingSign.new({
		name = "EquipBestWords",
		parent = folder,
		at = at * CFrame.new(0, PAD.WordsHeight, 0),
		text = PAD.Words,
		colour = PAD.Colour,
		width = PAD.WordsWidth,
		height = PAD.WordsSize,
		subText = PAD.SubWords,
		subHeight = PAD.SubSize,
	})
	words.setShown(true)
	sign = words
end

local function watchPlot(found: Model?)
	if found == plot then
		return
	end
	for _, c in ipairs(plotWatch) do
		c:Disconnect()
	end
	table.clear(plotWatch)
	plot = found
	if found then
		table.insert(plotWatch, found:GetAttributeChangedSignal("PlotCF"):Connect(place))
		table.insert(plotWatch, found:GetAttributeChangedSignal("Level"):Connect(place))
	end
	place()
end

-- Which plot is this player's: asked whenever any plot's owner changes.
local function lookAgain()
	watchPlot(myPlot())
end

local function watchOwner(instance: Instance)
	if instance:IsA("Model") then
		instance:GetAttributeChangedSignal(ATTR.OwnerUserId):Connect(lookAgain)
	end
end
for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
	watchOwner(instance)
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Plot):Connect(function(instance: Instance)
	watchOwner(instance)
	lookAgain()
end)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Plot):Connect(function(instance: Instance)
	if instance == plot then
		lookAgain()
	end
end)

--==============================================================================
-- THE RING: lit gold as the hold fills; while it cools down, green segments
-- count the cooldown out; otherwise plain white. Written only when it changes.
--==============================================================================
local function paint(fill: number, cooling: number)
	local b = built
	if not b then
		return
	end
	local n = #b.segments
	local key: string
	local count: number
	if cooling > 0 then
		count = math.clamp(math.ceil(cooling * n - 1e-6), 0, n)
		key = "cool" .. count
	else
		count = EquipBestPad.lit(fill, n)
		key = "fill" .. count
	end
	if key == painted then
		return
	end
	painted = key
	for i, seg in ipairs(b.segments) do
		if cooling > 0 then
			seg.Color = if i <= count then PAD.Colour else PAD.IdleColour
			seg.Transparency = if i <= count then 0.15 else 0.7
		else
			seg.Color = if i <= count then PAD.LitColour else PAD.IdleColour
			seg.Transparency = if i <= count then 0 else 0.55
		end
	end
end

--==============================================================================
-- THE HOLD, AND THE ONE REQUEST IT SENDS
--==============================================================================
local channel: RemoteEvent? = nil

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/EquipBestPad] No GameEvent remote; the pad cannot ask for anything.")
	end
end)

local function send()
	local remote = channel
	if not remote then
		return
	end
	SoundKit.play("CardClick")
	-- The Garden menu's own verb (GardenUI's EQUIP BEST button sends exactly
	-- this); GardenUI hears the answer and says it.
	remote:FireServer(MY.Best, nil)
end

local hold = EquipBestPad.new()

task.spawn(function()
	local last = os.clock()
	while folder.Parent do
		local now = os.clock()
		local dt = now - last
		last = now
		local at = padAt
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local on, near = false, false
		if at and root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and not humanoid.Sit then
			on = EquipBestPad.onPad(root.Position, at)
			near = (root.Position - at.Position).Magnitude <= PAD.NearStuds
		end
		if EquipBestPad.step(hold, on, dt, now) then
			send()
		end
		local fill, cooling = EquipBestPad.progress(hold, now)
		paint(fill, cooling)
		task.wait(if near or cooling > 0 then 1 / PAD.NearHz else 1)
	end
end)

lookAgain()
