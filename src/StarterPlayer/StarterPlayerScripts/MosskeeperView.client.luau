--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperView (2026-10-11, Enchanted Mist stage 3)
--
-- WHAT EACH CLIENT DOES WITH THE MOSSKEEPER THE SERVER BUILT
--
-- 1. HIS LIFE (Shared/MosskeeperIdle, the owner's builder's brain): breathing,
--    blinking, the look at the nearest player, the wave on approach, the sway,
--    the Dewdrop's bob -- on this client only, never the server, every pose
--    absolute from the clock (nothing accumulates), stepped while he is
--    streamed in and the camera within ANIMATE_RANGE. He "serves" -- bows,
--    opens his satchel -- while this player is in his dialogue (MosskeeperUI's
--    local attribute). Reduced FX stills his glow; the motion stays.
-- 2. HIS BAR (§9): this player's OWN saved progress over his head --
--    "Dewberries 5/10 / Next Mysterious Pod", or "Waiting for Enchanted Mist"
--    while none runs. It moves only on the server's numbers (the player's
--    attributes, never a guess); a delivery that made a pod shows 10/10 for
--    FullHold, then the saved remainder. Eased, or cut under reduced motion.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MosskeeperIdle = require(Shared:WaitForChild("MosskeeperIdle"))
local DewberryModel = require(Shared:WaitForChild("DewberryModel"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local CFG = EnchantedMistConfig.Mosskeeper
local BAR = CFG.Bar
local PA = EnchantedMistConfig.PlayerAttributes
local PER_POD = EnchantedMistData.BerriesPerPod
local ANIMATE_RANGE = 160

local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local function npcModel(): Model?
	local folder = Workspace:FindFirstChild(CFG.FolderName)
	local model = folder and folder:FindFirstChild("Mosskeeper")
	return if model and model:IsA("Model") and model.PrimaryPart then model else nil
end

--==============================================================================
-- 1. HIS LIFE
--==============================================================================
local brain: MosskeeperIdle.Brain? = nil
local brainOf: Model? = nil

RunService.PreSimulation:Connect(function()
	local model = npcModel()
	if model ~= brainOf then
		brainOf = model
		brain = if model then MosskeeperIdle.new(model) else nil
	end
	local b = brain
	local camera = Workspace.CurrentCamera
	if not (b and model and camera) then
		return
	end
	local pivot = model:GetPivot().Position
	if (camera.CFrame.Position - pivot).Magnitude > ANIMATE_RANGE then
		return
	end
	local at: { Vector3 } = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(at, root.Position)
		end
	end
	b.step(os.clock(), {
		players = at,
		serving = player:GetAttribute(CFG.TalkingAttribute) == true,
		reducedFx = StatusText.reducedMotion(),
	})
end)

--==============================================================================
-- 2. HIS BAR (this player's own)
--==============================================================================
local existing = playerGui:FindFirstChild("SeedMosskeeperBar")
if existing then
	existing:Destroy()
end

local board = Instance.new("BillboardGui")
board.Name = "SeedMosskeeperBar"
board.ResetOnSpawn = false
board.Size = UDim2.fromScale(BAR.Width, BAR.Height)
board.StudsOffsetWorldSpace = Vector3.new(0, BAR.Above, 0)
board.MaxDistance = BAR.MaxDistance
board.LightInfluence = 0
board.AlwaysOnTop = false
board.Enabled = false
board.Parent = playerGui

local header = MenuKit.heading(board, "Header", 26, Color3.fromRGB(240, 255, 244), 3)
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.fromScale(0.5, 0)
header.Size = UDim2.fromScale(1, 0.36)
header.TextScaled = true

-- It reads berry -> pod: the owner's Dewberry at the start (a live render --
-- this billboard is in PlayerGui, where a ViewportFrame draws), the pod at the end.
local berryIcon = Instance.new("ViewportFrame")
berryIcon.Name = "BerryIcon"
berryIcon.AnchorPoint = Vector2.new(0, 0.5)
berryIcon.Position = UDim2.fromScale(0.01, 0.52)
berryIcon.Size = UDim2.fromScale(0.15, 0.56)
berryIcon.BackgroundTransparency = 1
berryIcon.Ambient = Color3.fromRGB(190, 200, 190)
berryIcon.LightColor = Color3.fromRGB(255, 255, 255)
berryIcon.LightDirection = Vector3.new(-1, -1.4, -1)
berryIcon.ZIndex = 3
berryIcon.Parent = board
local berryAspect = Instance.new("UIAspectRatioConstraint")
berryAspect.AspectRatio = 1
berryAspect.Parent = berryIcon
do
	DewberryModel.build(CFrame.new(), berryIcon)
	local eye = Instance.new("Camera")
	eye.FieldOfView = 40
	eye.CFrame = CFrame.lookAt(Vector3.new(0, 1.35, 4.2), Vector3.new(0, 1.15, 0))
	eye.Parent = berryIcon
	berryIcon.CurrentCamera = eye
end
-- The Mysterious Pod at the end, a live render like the berry: the shell
-- itself (EnchantedMistData.Shell, the owner's Luckhollow pod), never a
-- stand-in picture. Nothing when the shell is unbound.
local podIcon = Instance.new("ViewportFrame")
podIcon.Name = "PodIcon"
podIcon.AnchorPoint = Vector2.new(1, 0.5)
podIcon.Position = UDim2.fromScale(0.99, 0.52)
podIcon.Size = UDim2.fromScale(0.15, 0.56)
podIcon.BackgroundTransparency = 1
podIcon.Ambient = berryIcon.Ambient
podIcon.LightColor = berryIcon.LightColor
podIcon.LightDirection = berryIcon.LightDirection
podIcon.ZIndex = 3
podIcon.Parent = board
local podAspect = Instance.new("UIAspectRatioConstraint")
podAspect.AspectRatio = 1
podAspect.Parent = podIcon
do
	local shell = SeedData.Get(EnchantedMistData.Shell.Id or "")
	local ok, model = false, nil
	if shell then
		ok, model = pcall(CreatureModel.Build, shell, 1, CreatureModel.STAGE_POD, CFrame.new(), podIcon)
	end
	if ok and model then
		-- Framed whole from a little above its front, as the berry is.
		local box, size = model:GetBoundingBox()
		local radius = size.Magnitude / 2
		local eye = Instance.new("Camera")
		eye.FieldOfView = 40
		local distance = radius / math.tan(math.rad(eye.FieldOfView / 2)) * 0.8
		eye.CFrame = CFrame.lookAt(box.Position + Vector3.new(0, radius * 0.3, distance), box.Position)
		eye.Parent = podIcon
		podIcon.CurrentCamera = eye
	end
end

local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.fromScale(0.5, 0.4)
track.Size = UDim2.fromScale(0.62, 0.24)
-- A solid track (the owner, 2026-10-10: progress bars are never see-through):
-- a dark well with a moss edge, the mill's MilestoneBar look.
track.BackgroundColor3 = BAR.Track
track.BackgroundTransparency = 0
track.BorderSizePixel = 0
track.ZIndex = 2
track.Parent = board
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0.5, 0)
trackCorner.Parent = track
local trackStroke = Instance.new("UIStroke")
trackStroke.Thickness = 2
trackStroke.Color = BAR.TrackEdge
trackStroke.Parent = track

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = BAR.Fill
fill.BorderSizePixel = 0
fill.ZIndex = 3
fill.Parent = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.5, 0)
fillCorner.Parent = fill
local fillStroke = Instance.new("UIStroke")
fillStroke.Thickness = 1.5
fillStroke.Color = Color3.fromRGB(16, 22, 18)
fillStroke.Parent = fill

local sub = MenuKit.heading(board, "Sub", 18, Color3.fromRGB(200, 240, 214), 3)
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Position = UDim2.fromScale(0.5, 0.68)
sub.Size = UDim2.fromScale(1, 0.3)
sub.TextScaled = true

local shown = -1
local holdUntil = 0
local fillTween: Tween? = nil

local function mistActive(): boolean
	return Workspace:GetAttribute(EnchantedMistConfig.Attributes.State) == EnchantedMistConfig.States.Active
end

local function saved(): number
	return math.clamp(math.floor(tonumber(player:GetAttribute(PA.Progress)) or 0), 0, PER_POD - 1)
end

local function draw(value: number)
	header.Text = string.format(BAR.Header, value, PER_POD)
	sub.Text = if mistActive() then BAR.Sub else BAR.Waiting
	if value == shown then
		return
	end
	shown = value
	if fillTween then
		fillTween:Cancel()
	end
	local goal = UDim2.fromScale(value / PER_POD, 1)
	if StatusText.reducedMotion() then
		fill.Size = goal
	else
		local tween = TweenService:Create(fill, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = goal })
		fillTween = tween
		tween:Play()
	end
end

local function refresh()
	if os.clock() < holdUntil then
		return
	end
	draw(saved())
end

-- A delivery that made a pod: the full bar first, then what was saved.
channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= CFG.ServerAction or type(payload) ~= "table" or payload.phase ~= "given" then
		return
	end
	if (tonumber(payload.pods) or 0) > 0 then
		holdUntil = os.clock() + BAR.FullHold
		draw(PER_POD)
		task.delay(BAR.FullHold, function()
			holdUntil = 0
			refresh()
		end)
	else
		refresh()
	end
end)

player:GetAttributeChangedSignal(PA.Progress):Connect(refresh)
Workspace:GetAttributeChangedSignal(EnchantedMistConfig.Attributes.State):Connect(function()
	shown = -1
	refresh()
end)

--==============================================================================
-- 3. THE DECK'S GLOW (Shared/MistDeckModel): the fairy ring's mint spots glow,
-- or under Reduced FX are plain, on this screen only.
--==============================================================================
local stilledDeck: Instance? = nil
local stilled: boolean? = nil
local function stillTheDeck()
	local folder = Workspace:FindFirstChild(CFG.FolderName)
	local deck = folder and folder:FindFirstChild(EnchantedMistConfig.Deck.ModelName)
	local reduced = StatusText.reducedMotion()
	if deck == stilledDeck and reduced == stilled then
		return
	end
	stilledDeck, stilled = deck, reduced
	for _, p in ipairs(deck and deck:GetDescendants() or {}) do
		if p:IsA("BasePart") and p:GetAttribute("MistGlow") then
			p.Material = if reduced then Enum.Material.SmoothPlastic else Enum.Material.Neon
		end
	end
end

-- Follow him: on his Footing while he stands, hidden while he does not.
RunService.Heartbeat:Connect(function()
	stillTheDeck()
	local model = npcModel()
	local root = model and model.PrimaryPart
	if board.Adornee ~= root then
		board.Adornee = root
		shown = -1
		refresh()
	end
	board.Enabled = root ~= nil
end)
refresh()
