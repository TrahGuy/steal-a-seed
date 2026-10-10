--!strict
--==============================================================================
-- Steal a Seed :: SproutDashUI (2026-10-08)
--
-- The mill's minigame on screen (GameConfig.SproutDash, Shared/SproutDash,
-- SproutDashService). The owner: "when player rides the mill, a play minigame
-- button appears, then when opened, a screen of the game will open, so it
-- will not affect the jump".
--
--   THE BUTTON   PLAY MINIGAME, while this player rides their OWN mill (not the
--                Disco Mill), in the hotbar's place while the strip steps aside
--                (2026-10-10, GameConfig.ContextSlot; HudLayout.contextButton).
--   THE JUMP     while the screen is open this client's humanoid cannot jump
--                (its Jumping state off, the touch controls hidden; both back
--                as they were on close) and Space and pad A are taken first,
--                so nothing lifts the rider -- the mill unmounts only on a
--                Jumping humanoid. Space, A, a tap or a click on the game hop
--                the sprout instead; on the end screen they play again.
--   THE RUN      the server hands the seed; this script steps SproutDash Hz
--                times a second to draw it and keeps the ticks it hopped on.
--                At the third hit, at MaxSeconds or at the X it sends those
--                ticks, and the end screen shows what the SERVER counted --
--                never this script's own number.
--   OFF THE MILL a jump, a death or a teleport closes the screen and the run.
--
-- Art: GameConfig.SproutDash.Art -- the owner's sheets (ids set 2026-10-08),
-- each drawing placed by rects measured on the upload. A layer whose id is ""
-- falls back to frame-drawn stand-ins (never anyone else's upload).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SproutDash = require(Shared:WaitForChild("SproutDash"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local CFG = GameConfig.SproutDash
local WORDS = CFG.Words
local ART = CFG.Art
local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local PANEL_NAME = "SproutDash"
local HOP_ACTION = "SeedSproutDashHop"
local CLOSE_ACTION = "SeedSproutDashClose"
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(16, 21, 28)

-- A drawing on the props sheet, or nil while there is no sheet (stand-ins).
local function propRect(name: string): Rect?
	local r = (ART.Props :: any)[name]
	return if ART.Props.Image ~= "" and typeof(r) == "Rect" then r else nil
end

for _, name in ipairs({ "SeedSproutDash", "SeedSproutDashButton", "SeedSproutDashMeasure" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local function place(g: GuiObject, r: { x: number, y: number, w: number, h: number })
	g.Position = UDim2.fromOffset(r.x, r.y)
	g.Size = UDim2.fromOffset(r.w, r.h)
end

local function frame(parent: Instance, name: string, colour: Color3, z: number, radius: UDim?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = radius
		c.Parent = f
	end
	return f
end

local function words(parent: Instance, name: string, size: number, colour: Color3, z: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.LuckiestGuy
	l.TextSize = size
	l.TextColor3 = colour
	l.ZIndex = z
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = 2
	s.Parent = l
	return l
end

--==============================================================================
-- THE BUTTON: PLAY MINIGAME, clear of the HUD (as TreadmillFunUI's bar)
--==============================================================================
local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "SeedSproutDashButton"
buttonGui.ResetOnSpawn = false
buttonGui.IgnoreGuiInset = true
buttonGui.ScreenInsets = Enum.ScreenInsets.None
buttonGui.DisplayOrder = 11
buttonGui.Parent = playerGui

local measureGui = Instance.new("ScreenGui")
measureGui.Name = "SeedSproutDashMeasure"
measureGui.ResetOnSpawn = false
measureGui.IgnoreGuiInset = false
measureGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
UIKit.tenFoot(measureGui)
measureGui.Parent = playerGui

local BUTTON_W, BUTTON_H = 230, 56
local playButton = Instance.new("TextButton")
playButton.Name = "PlayMinigame"
playButton.AnchorPoint = Vector2.new(0, 0)
playButton.AutoButtonColor = false
playButton.BackgroundColor3 = CFG.Look.Band
playButton.BorderSizePixel = 0
playButton.Text = ""
playButton.Visible = false
playButton.ZIndex = 2
playButton.Parent = buttonGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = playButton
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = CFG.Look.Edge
	edge.Thickness = 3
	edge.Parent = playButton
	-- The kit's studs over the face.
	local studs = Instance.new("ImageLabel")
	studs.Name = "StudTexture"
	studs.BackgroundTransparency = 1
	studs.Size = UDim2.fromScale(1, 1)
	studs.Image = GameConfig.StuddedLook.Texture
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(GameConfig.StuddedLook.Tile, GameConfig.StuddedLook.Tile)
	studs.ImageTransparency = GameConfig.StuddedLook.BandStuds
	studs.ZIndex = 2
	studs.Parent = playButton
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 12)
	sc.Parent = studs
	local label = words(playButton, "Words", 24, WHITE, 3)
	label.Size = UDim2.fromScale(1, 1)
	label.Text = WORDS.Button
end
local buttonScale = Instance.new("UIScale")
buttonScale.Parent = playButton
UIKit.clicks(playButton)

-- Riding their OWN mill: mounted, and standing on the belt of their own plot.
local function ownBeltUnder(): boolean
	if player:GetAttribute(ATTR.MillMounted) ~= true then
		return false
	end
	local id = player:GetAttribute(ATTR.OwnPlotId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if id == nil or not (root and root:IsA("BasePart")) then
		return false
	end
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") and belt.Parent and belt.Parent:GetAttribute(ATTR.PlotId) == id then
			return (root.Position - belt.Position).Magnitude < math.max(belt.Size.X, belt.Size.Z) + 6
		end
	end
	return false
end

--==============================================================================
-- THE SCREEN: the studded kit's orange band, the game inside
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedSproutDash"
gui.ResetOnSpawn = false
-- The menus' order (Shop, EVENTS): over the rails when it covers them.
gui.DisplayOrder = 32
gui.Parent = playerGui
local menu = MenuKit.modal(gui, PANEL_NAME, WORDS.Title, GameConfig.SourceIcons.training, nil, nil, nil,
	MenuKit.studdedTheme(CFG.Look))
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body

local stage = frame(body, "Stage", Color3.fromRGB(150, 214, 255), 3, UDim.new(0, 12))
stage.ClipsDescendants = true
do
	local sky = Instance.new("UIGradient")
	sky.Rotation = 90
	sky.Color = ColorSequence.new(Color3.fromRGB(120, 196, 255), Color3.fromRGB(214, 240, 255))
	sky.Parent = stage
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = CFG.Look.Edge
	edge.Thickness = 3
	edge.Parent = stage
end
local backdrop = Instance.new("ImageLabel")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ScaleType = Enum.ScaleType.Crop
backdrop.Image = ART.Backdrop.Image
backdrop.Visible = ART.Backdrop.Image ~= ""
backdrop.ZIndex = 3
backdrop.Parent = stage
-- A tap or a click anywhere on the game hops. Never a pad selection: a
-- selected control takes A away from the hop (PadFocus leaves this gui alone).
local hitArea = Instance.new("TextButton")
hitArea.Name = "Hop"
hitArea.BackgroundTransparency = 1
hitArea.Selectable = false
hitArea.Text = ""
hitArea.Size = UDim2.fromScale(1, 1)
hitArea.ZIndex = 20
hitArea.Parent = stage

-- The ground: the treadmill's belt, its stripes running under the sprout.
local belt = frame(stage, "Belt", Color3.fromRGB(58, 62, 72), 4)
local beltTop = frame(belt, "Top", Color3.fromRGB(126, 196, 92), 5)
local stripes: { Frame } = {}
for i = 1, 24 do
	stripes[i] = frame(belt, "Stripe" .. i, Color3.fromRGB(88, 94, 108), 5)
end
local groundImage = Instance.new("ImageLabel")
groundImage.Name = "Ground"
groundImage.BackgroundTransparency = 1
groundImage.Image = ART.Ground.Image
groundImage.ScaleType = Enum.ScaleType.Tile
groundImage.Visible = ART.Ground.Image ~= ""
groundImage.ZIndex = 6
groundImage.Parent = stage

-- The sprout: the owner's runner sheet, or a pot, a stem and two leaves.
local runner = Instance.new("Frame")
runner.Name = "Runner"
runner.BackgroundTransparency = 1
runner.AnchorPoint = Vector2.new(0.5, 1)
runner.ZIndex = 10
runner.Parent = stage
-- A whole cell, square, set down by the frame's own feet (draw).
local runnerImage = Instance.new("ImageLabel")
runnerImage.Name = "Sheet"
runnerImage.BackgroundTransparency = 1
runnerImage.AnchorPoint = Vector2.new(0.5, 1)
runnerImage.Position = UDim2.fromScale(0.5, 1)
runnerImage.Image = ART.Runner.Image
runnerImage.ImageRectSize = Vector2.new(ART.Runner.Cell, ART.Runner.Cell)
runnerImage.Visible = ART.Runner.Image ~= ""
runnerImage.ZIndex = 11
runnerImage.Parent = runner
local drawnRunner = Instance.new("Frame")
drawnRunner.Name = "Drawn"
drawnRunner.BackgroundTransparency = 1
drawnRunner.Size = UDim2.fromScale(1, 1)
drawnRunner.Visible = ART.Runner.Image == ""
drawnRunner.ZIndex = 10
drawnRunner.Parent = runner
do
	local pot = frame(drawnRunner, "Pot", Color3.fromRGB(196, 104, 52), 11, UDim.new(0.2, 0))
	pot.AnchorPoint = Vector2.new(0.5, 1)
	pot.Position = UDim2.fromScale(0.5, 1)
	pot.Size = UDim2.fromScale(0.9, 0.42)
	local rim = frame(drawnRunner, "Rim", Color3.fromRGB(150, 74, 36), 12, UDim.new(0.3, 0))
	rim.AnchorPoint = Vector2.new(0.5, 1)
	rim.Position = UDim2.fromScale(0.5, 0.62)
	rim.Size = UDim2.fromScale(1, 0.12)
	local stem = frame(drawnRunner, "Stem", Color3.fromRGB(70, 168, 64), 11, UDim.new(0.5, 0))
	stem.AnchorPoint = Vector2.new(0.5, 1)
	stem.Position = UDim2.fromScale(0.5, 0.56)
	stem.Size = UDim2.fromScale(0.14, 0.42)
	for i, rot in ipairs({ -32, 32 }) do
		local leaf = frame(drawnRunner, "Leaf" .. i, Color3.fromRGB(96, 206, 80), 12, UDim.new(0.5, 0))
		leaf.AnchorPoint = Vector2.new(0.5, 0.5)
		leaf.Position = UDim2.fromScale(if i == 1 then 0.3 else 0.7, 0.2)
		leaf.Size = UDim2.fromScale(0.55, 0.26)
		leaf.Rotation = rot
		local e = Instance.new("UIStroke")
		e.Color = Color3.fromRGB(36, 104, 40)
		e.Thickness = 2
		e.Parent = leaf
	end
	for i = 1, 2 do
		local eye = frame(drawnRunner, "Eye" .. i, INK, 13, UDim.new(0.5, 0))
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(if i == 1 then 0.36 else 0.64, 0.8)
		eye.Size = UDim2.fromScale(0.12, 0.1)
	end
end

-- The HUD over the game: distance, coins, hearts.
local distanceWords = words(stage, "Distance", 26, WHITE, 15)
distanceWords.AnchorPoint = Vector2.new(0, 0)
distanceWords.TextXAlignment = Enum.TextXAlignment.Left
local coinIcon = Instance.new("ImageLabel")
coinIcon.Name = "CoinIcon"
coinIcon.BackgroundTransparency = 1
coinIcon.Image = ART.Coin
coinIcon.ScaleType = Enum.ScaleType.Fit
coinIcon.ZIndex = 15
coinIcon.Parent = stage
local coinWords = words(stage, "Coins", 26, Color3.fromRGB(255, 226, 92), 15)
coinWords.TextXAlignment = Enum.TextXAlignment.Left
-- The lives: the sheet's full and empty hearts, or plain tiles without it.
local hearts: { Frame } = {}
local heartImages: { [number]: ImageLabel } = {}
local heartArt = propRect("heart") ~= nil and propRect("heartEmpty") ~= nil
for i = 1, CFG.Lives do
	local h = frame(stage, "Heart" .. i, Color3.fromRGB(255, 72, 96), 15, UDim.new(0.3, 0))
	local e = Instance.new("UIStroke")
	e.Color = INK
	e.Thickness = 2
	e.Parent = h
	hearts[i] = h
	if heartArt then
		h.BackgroundTransparency = 1
		e.Enabled = false
		local img = Instance.new("ImageLabel")
		img.Name = "Art"
		img.BackgroundTransparency = 1
		img.Image = ART.Props.Image
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.fromScale(1, 1)
		img.ZIndex = 16
		img.Parent = h
		heartImages[i] = img
	end
end
local hint = words(stage, "Hint", 22, WHITE, 15)
hint.Text = WORDS.Hint

-- The end of a run: what the server counted, PLAY AGAIN and CLOSE.
local sheet = frame(stage, "RunOver", Color3.fromRGB(255, 255, 255), 30, UDim.new(0, 14))
sheet.AnchorPoint = Vector2.new(0.5, 0.5)
sheet.Position = UDim2.fromScale(0.5, 0.5)
sheet.Size = UDim2.fromScale(0.62, 0.78)
sheet.Visible = false
do
	local e = Instance.new("UIStroke")
	e.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	e.Color = CFG.Look.Edge
	e.Thickness = 3
	e.Parent = sheet
end
local overTitle = words(sheet, "Title", 30, CFG.Look.Band, 31)
overTitle.Position = UDim2.fromScale(0, 0.04)
overTitle.Size = UDim2.fromScale(1, 0.16)
overTitle.Text = WORDS.Over
local overLines: { TextLabel } = {}
for i = 1, 4 do
	local l = words(sheet, "Line" .. i, if i == 1 then 30 else 20, if i == 4 then Color3.fromRGB(85, 220, 40) else WHITE, 31)
	l.Position = UDim2.fromScale(0.04, 0.2 + (i - 1) * 0.12)
	l.Size = UDim2.fromScale(0.92, 0.11)
	l.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = if i == 1 then 32 else 22
	limit.Parent = l
	overLines[i] = l
end
local again = MenuKit.button(sheet, "PlayAgain", 31, WORDS.Again, 18, { studs = true } :: any)
again.style("go")
again.hit.AnchorPoint = Vector2.new(1, 1)
again.hit.Position = UDim2.new(0.5, -6, 0.95, 0)
again.hit.Size = UDim2.new(0.42, 0, 0.17, 0)
local closeRun = MenuKit.button(sheet, "CloseRun", 31, WORDS.Close, 18, { studs = true } :: any)
closeRun.style("danger")
closeRun.hit.AnchorPoint = Vector2.new(0, 1)
closeRun.hit.Position = UDim2.new(0.5, 6, 0.95, 0)
closeRun.hit.Size = UDim2.new(0.42, 0, 0.17, 0)

-- Pools: one drawing per obstacle / coin id, made when first seen.
local obstacleArt: { [number]: GuiObject } = {}
local coinArt: { [number]: ImageLabel } = {}

local function newObstacle(kind: string): GuiObject
	local r = propRect(kind)
	if r then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = ART.Props.Image
		img.ImageRectOffset = r.Min
		img.ImageRectSize = Vector2.new(r.Width, r.Height)
		img.AnchorPoint = Vector2.new(0.5, 1)
		img.ZIndex = 8
		img.Parent = stage
		return img
	end
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.ZIndex = 8
	holder.Parent = stage
	if kind == "rock" then
		local r = frame(holder, "Rock", Color3.fromRGB(150, 150, 160), 8, UDim.new(0.45, 0))
		r.Size = UDim2.fromScale(1, 1)
		local e = Instance.new("UIStroke")
		e.Color = Color3.fromRGB(84, 84, 96)
		e.Thickness = 2
		e.Parent = r
	elseif kind == "log" then
		local l = frame(holder, "Log", Color3.fromRGB(150, 98, 52), 8, UDim.new(0.45, 0))
		l.Size = UDim2.fromScale(1, 1)
		local ring = frame(holder, "Ring", Color3.fromRGB(222, 178, 116), 9, UDim.new(0.5, 0))
		ring.AnchorPoint = Vector2.new(1, 0.5)
		ring.Position = UDim2.fromScale(1, 0.5)
		ring.Size = UDim2.fromScale(0.3, 0.9)
	else
		for i, rot in ipairs({ -18, 0, 18 }) do
			local blade = frame(holder, "Blade" .. i, Color3.fromRGB(64, 150, 52), 8, UDim.new(0.5, 0))
			blade.AnchorPoint = Vector2.new(0.5, 1)
			blade.Position = UDim2.fromScale(0.2 + (i - 1) * 0.3, 1)
			blade.Size = UDim2.fromScale(0.34, 1)
			blade.Rotation = rot
		end
	end
	return holder
end

--==============================================================================
-- THE RUN
--==============================================================================
type Phase = "closed" | "waiting" | "running" | "counting" | "over"
local run = {
	phase = "closed" :: Phase,
	id = 0,
	state = nil :: SproutDash.State?,
	hops = {} :: { number },
	wantHop = false,
	acc = 0,
	-- Where each happened on the belt (metres), so it scrolls away with it.
	bursts = {} :: { { image: ImageLabel, born: number, x: number, y: number, size: number } },
	-- When the end screen came up; a hop key mashed through the third hit
	-- must not skip it.
	overAt = -math.huge,
}
local remote: RemoteEvent? = nil

--==============================================================================
-- THE JUMP, HELD WHILE THE GAME IS OPEN
--
-- Not through the PlayerModule: this place's PlayerScripts have none -- the
-- engine keeps it under StarterPlayer now, and waiting for it in PlayerScripts
-- waited forever, so the screen never opened (Play, 2026-10-08). The jump is
-- held where the mill reads it instead. TreadmillService unmounts only on a
-- Jumping humanoid, and this client simulates its own character, so with that
-- state off HERE no key, button or pad lifts the rider; the mill's zero
-- WalkSpeed already parks the legs. The touch controls hide as well, so a tap
-- lands on the game and not on a jump button. Both go back to exactly what
-- they were on close.
--==============================================================================
local held: { humanoid: Humanoid, jump: boolean, touch: boolean }? = nil

local function holdControls(hold: boolean)
	if hold then
		if held then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		held = {
			humanoid = humanoid,
			jump = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping),
			touch = (GuiService :: any).TouchControlsEnabled,
		}
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		;(GuiService :: any).TouchControlsEnabled = false
	else
		local was = held
		held = nil
		if not was then
			return
		end
		if was.humanoid.Parent then
			was.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, was.jump)
		end
		;(GuiService :: any).TouchControlsEnabled = was.touch
	end
end

local function send(verb: string, payload: { [string]: any }?)
	local r = remote
	if r then
		r:FireServer(CFG.Action, verb, payload)
	end
end

local function clearRun()
	for _, art in pairs(obstacleArt) do
		art:Destroy()
	end
	table.clear(obstacleArt)
	for _, art in pairs(coinArt) do
		art:Destroy()
	end
	table.clear(coinArt)
	for _, b in ipairs(run.bursts) do
		b.image:Destroy()
	end
	table.clear(run.bursts)
end

local function startRun()
	clearRun()
	run.state = nil
	run.hops = {}
	run.wantHop = false
	run.acc = 0
	run.phase = "waiting"
	sheet.Visible = false
	hint.Visible = true
	hint.Text = WORDS.Counting
	send("start")
end

-- The run stops here: the third hit, MaxSeconds or the X. Its hops go to the
-- server, which counts it; the end screen waits for that count.
local function finishRun()
	local state = run.state
	if run.phase ~= "running" or not state then
		return
	end
	run.phase = "counting"
	send("finish", { id = run.id, hops = run.hops, ticks = state.tick })
	sheet.Visible = true
	overTitle.Text = WORDS.Over
	overLines[1].Text = string.format(WORDS.Distance, SproutDash.distance(state))
	overLines[2].Text = WORDS.Counting
	overLines[3].Text = ""
	overLines[4].Text = ""
end

local open = false
-- Below, with the drawing. Opening lays the panel out afresh (UpdateLogUI's
-- order): the layout made at the script's start has no rails measured yet.
local relayout: () -> ()

-- PLAY AGAIN: its button at once, a hop key only once the end screen has had
-- a moment -- Space mashed through the third hit would skip the count.
local AGAIN_AFTER = 0.75
local function playAgain(byKey: boolean)
	if not open or run.phase ~= "over" then
		return
	end
	if byKey and os.clock() - run.overAt < AGAIN_AFTER then
		return
	end
	startRun()
end

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		player:SetAttribute(CFG.Attributes.Open, true)
		holdControls(true)
		-- A pad's selection would take A from the hop, and the button that may
		-- hold it hides now (the engine re-homes a hidden selection), so none.
		playButton.Visible = false
		GuiService.SelectedObject = nil
		ContextActionService:BindActionAtPriority(HOP_ACTION, function(_, inputState: Enum.UserInputState)
			if inputState == Enum.UserInputState.Begin then
				if run.phase == "over" then
					playAgain(true)
				else
					run.wantHop = true
				end
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.Up, Enum.KeyCode.W)
		ContextActionService:BindActionAtPriority(CLOSE_ACTION, function(_, inputState: Enum.UserInputState)
			if inputState == Enum.UserInputState.Begin then
				setOpen(false)
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
		startRun()
	else
		-- A run still going is counted as far as it got.
		finishRun()
		run.phase = "closed"
		ContextActionService:UnbindAction(HOP_ACTION)
		ContextActionService:UnbindAction(CLOSE_ACTION)
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		player:SetAttribute(CFG.Attributes.Open, nil)
		holdControls(false)
		UIKit.coverRail(playerGui, PANEL_NAME, false)
		clearRun()
	end
	relayout()
	modal.setOpen(want)
end

playButton.Activated:Connect(function()
	setOpen(true)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
again.hit.Activated:Connect(function()
	playAgain(false)
end)
closeRun.hit.Activated:Connect(function()
	setOpen(false)
end)
hitArea.InputBegan:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		run.wantHop = true
	end
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)
-- Off the mill: the screen and the run close.
player:GetAttributeChangedSignal(ATTR.MillMounted):Connect(function()
	if open and player:GetAttribute(ATTR.MillMounted) ~= true then
		setOpen(false)
		Notice.post({ kind = "info", title = WORDS.OffMill, detail = "" })
	end
end)

--==============================================================================
-- THE SERVER'S ANSWERS
--==============================================================================
local function onAnswer(payload: { [string]: any })
	local verb = payload.verb
	if verb == "started" then
		if not open or run.phase ~= "waiting" then
			return
		end
		if payload.ok ~= true then
			if payload.why == "TOO_SOON" then
				task.delay(CFG.StartEvery, function()
					if open and run.phase == "waiting" then
						send("start")
					end
				end)
			else
				setOpen(false)
			end
			return
		end
		run.id = payload.id
		run.state = SproutDash.new(payload.seed)
		run.phase = "running"
		hint.Text = WORDS.Hint
	elseif verb == "counted" then
		if not open or run.phase ~= "counting" then
			return
		end
		run.phase = "over"
		run.overAt = os.clock()
		if payload.ok ~= true then
			overLines[2].Text = ""
			overLines[4].Text = ""
			return
		end
		overLines[1].Text = string.format(WORDS.Distance, tostring(payload.distance))
		overLines[2].Text = string.format(WORDS.CoinTotal, tonumber(payload.coins) or 0)
		overLines[3].Text = string.format(WORDS.Best, tostring(payload.best))
		local granted = tonumber(payload.granted) or 0
		if granted > 0 then
			overLines[4].Text = string.format(WORDS.Reward, math.max(1, math.floor(granted / 60 + 0.5)))
			SoundKit.play("NoticeSuccess")
		elseif payload.cut == "bank" then
			overLines[4].Text = WORDS.Capped
		elseif payload.cut == "hour" then
			overLines[4].Text = WORDS.HourCapped
		else
			overLines[4].Text = string.format(WORDS.NoReward, SproutDash.firstTier())
		end
	elseif verb == "ended" then
		if open then
			setOpen(false)
		end
	end
end

task.spawn(function()
	local folder = Shared.Parent:WaitForChild("Remotes", 30)
	local r = folder and folder:WaitForChild(GameConfig.Remotes.GameEvent, 30)
	if r and r:IsA("RemoteEvent") then
		remote = r
		r.OnClientEvent:Connect(function(action: any, payload: any)
			if action == CFG.Action and type(payload) == "table" then
				onAnswer(payload)
			end
		end)
	end
end)

--==============================================================================
-- DRAWING
--==============================================================================
local stageW, stageH = 600, 300
relayout = function()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / k
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local cam = Workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and cam then HudLayout.tenFootScale(cam.ViewportSize) else 1
	local f = k / hudScale
	local p = MenuLayout.panel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.
		fill = math.min(1, k),
	} :: any, 820, 520, RAIL.OutlineThickness)
	menu.place(p)
	-- The game takes the shell's whole width: it has no sidebar to make room for.
	local blocks = MenuLayout.blocks(p)
	local main = MenuLayout.rect(blocks.header.x, blocks.main.y, blocks.header.w, blocks.main.h)
	place(stage, main)
	stageW, stageH = main.w, main.h
	UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if open then
		relayout()
	end
end)

-- Studio only: a test may set this attribute to let the sprout hop for itself
-- (the same hops a player would send, counted by the server the same way).
local function autoHop(state: SproutDash.State): boolean
	if not (RunService:IsStudio() and player:GetAttribute("SproutDashAutoplay") == true) then
		return false
	end
	if not SproutDash.grounded(state) then
		return false
	end
	local v = SproutDash.speedAt(state.tick)
	local here = math.floor(state.x / CFG.Course.Chunk)
	for index = here, here + 2 do
		for _, o in ipairs(SproutDash.chunkOf(state, index).obstacles) do
			local d = (o.x - o.w / 2) - (state.x + CFG.Runner.W / 2)
			if d > 0 and not state.struck[o.id] then
				local a, b = CFG.Gravity / 2, -CFG.Hop
				local disc = b * b - 4 * a * o.h
				local t1 = (-b - math.sqrt(disc)) / (2 * a)
				local t2 = (-b + math.sqrt(disc)) / (2 * a)
				local mid = (v * t1 + v * t2 - (o.w + CFG.Runner.W)) / 2
				if d <= mid + v / CFG.Hz and d >= mid - 2 * v / CFG.Hz then
					return true
				end
			end
		end
	end
	return false
end

local function draw(state: SproutDash.State, now: number)
	-- 16 m across (about 0.7 s of warning at top speed) and 9 m up, whichever
	-- is tighter; the belt's top 84% of the way down.
	local ppm = math.min(stageH / 9, stageW / 16)
	local groundY = stageH * 0.84
	local runnerX = stageW * 0.2
	-- The belt.
	belt.Position = UDim2.fromOffset(0, groundY)
	belt.Size = UDim2.fromOffset(stageW, stageH - groundY)
	beltTop.Size = UDim2.new(1, 0, 0, math.max(4, ppm * 0.18))
	local spacing = 2 * ppm
	local shift = (state.x * ppm) % spacing
	for i, s in ipairs(stripes) do
		local x = (i - 1) * spacing - shift
		s.Position = UDim2.fromOffset(x, math.max(4, ppm * 0.18) + 4)
		s.Size = UDim2.fromOffset(math.max(3, ppm * 0.25), stageH - groundY)
		s.Visible = x < stageW
	end
	if groundImage.Visible then
		local top = ART.Ground.Top / ART.Ground.Size.Y
		local h = (stageH - groundY) / (1 - top)
		local tileW = h * ART.Ground.Size.X / ART.Ground.Size.Y
		groundImage.Size = UDim2.fromOffset(stageW + tileW, h)
		groundImage.Position = UDim2.fromOffset(-((state.x * ppm) % tileW), groundY - h * top)
		groundImage.TileSize = UDim2.fromOffset(tileW, h)
	end
	-- The sprout: a little bob while it runs, a blink through its grace.
	local rw, rh = CFG.Runner.W * ppm * 1.25, CFG.Runner.H * ppm
	local bob = if SproutDash.grounded(state) then math.abs(math.sin(state.x * 2.2)) * ppm * 0.06 else 0
	runner.Position = UDim2.fromOffset(runnerX, groundY - state.y * ppm - bob)
	runner.Size = UDim2.fromOffset(rw, rh)
	local blinking = state.tick < state.graceUntil and (state.tick // 6) % 2 == 0
	runner.Visible = not blinking
	if runnerImage.Visible then
		local R = ART.Runner
		local hit = state.tick < state.graceUntil
		local hopping = not hit and not SproutDash.grounded(state)
		runnerImage.ImageRectOffset = if hit then R.Hit
			elseif hopping then R.Hop
			else R.Run[(math.floor(state.x / 0.7) % #R.Run) + 1]
		-- The standing drawing is R.Tall sheet px for CFG.Runner.H; each frame
		-- stands on its own feet, so the cell drops below the runner's foot by
		-- that frame's baseline (the tucked hop's sits higher in its cell).
		local k = rh / R.Tall
		runnerImage.Size = UDim2.fromOffset(R.Cell * k, R.Cell * k)
		runnerImage.Position = UDim2.new(0.5, 0, 1, (if hopping then R.HopBaseline else R.Baseline) * k)
	end
	-- What is ahead and just behind.
	local seen: { [number]: boolean } = {}
	local seenCoins: { [number]: boolean } = {}
	local here = math.floor(state.x / CFG.Course.Chunk)
	local ahead = (stageW - runnerX) / ppm
	for index = here - 1, here + math.ceil(ahead / CFG.Course.Chunk) + 1 do
		local chunk = SproutDash.chunkOf(state, index)
		for _, o in ipairs(chunk.obstacles) do
			local sx = runnerX + (o.x - state.x) * ppm
			if sx > -ppm * 3 and sx < stageW + ppm * 3 then
				seen[o.id] = true
				local art = obstacleArt[o.id]
				if not art then
					art = newObstacle(o.kind)
					obstacleArt[o.id] = art
				end
				art.Position = UDim2.fromOffset(sx, groundY)
				local r = propRect(o.kind)
				if r then
					-- In the drawing's own shape, just big enough to cover the
					-- hitbox: what hits is always seen.
					local s = math.max(o.w * ppm / r.Width, o.h * ppm / r.Height)
					art.Size = UDim2.fromOffset(r.Width * s, r.Height * s)
				else
					art.Size = UDim2.fromOffset(o.w * ppm, o.h * ppm)
				end
			end
		end
		for _, c in ipairs(chunk.coins) do
			local sx = runnerX + (c.x - state.x) * ppm
			if not state.taken[c.id] and sx > -ppm and sx < stageW + ppm then
				seenCoins[c.id] = true
				local art = coinArt[c.id]
				if not art then
					art = Instance.new("ImageLabel")
					art.BackgroundTransparency = 1
					art.Image = ART.Coin
					art.ScaleType = Enum.ScaleType.Fit
					art.AnchorPoint = Vector2.new(0.5, 0.5)
					art.ZIndex = 9
					art.Parent = stage
					coinArt[c.id] = art
				end
				local d = CFG.Course.CoinR * 2 * ppm * 1.4
				art.Size = UDim2.fromOffset(d, d)
				art.Position = UDim2.fromOffset(sx, groundY - c.y * ppm)
			end
		end
	end
	for id, art in pairs(obstacleArt) do
		if not seen[id] then
			art:Destroy()
			obstacleArt[id] = nil
		end
	end
	for id, art in pairs(coinArt) do
		if not seenCoins[id] then
			art:Destroy()
			coinArt[id] = nil
		end
	end
	-- Bursts fade over 0.4 s.
	for i = #run.bursts, 1, -1 do
		local b = run.bursts[i]
		local age = now - b.born
		if age > 0.4 then
			b.image:Destroy()
			table.remove(run.bursts, i)
		else
			b.image.ImageTransparency = age / 0.4
			b.image.Position = UDim2.fromOffset(runnerX + (b.x - state.x) * ppm, groundY - b.y * ppm)
			b.image.Size = UDim2.fromOffset(b.size * ppm, b.size * ppm)
		end
	end
	-- The HUD.
	local hudH = math.max(22, stageH * 0.09)
	distanceWords.Position = UDim2.fromOffset(12, 8)
	distanceWords.Size = UDim2.fromOffset(stageW * 0.4, hudH)
	distanceWords.TextSize = hudH
	distanceWords.Text = string.format(WORDS.Distance, SproutDash.distance(state))
	coinIcon.Position = UDim2.fromOffset(stageW * 0.45, 8)
	coinIcon.Size = UDim2.fromOffset(hudH, hudH)
	coinWords.Position = UDim2.fromOffset(stageW * 0.45 + hudH + 6, 8)
	coinWords.Size = UDim2.fromOffset(stageW * 0.2, hudH)
	coinWords.TextSize = hudH
	coinWords.Text = string.format(WORDS.Coins, state.coins)
	for i, h in ipairs(hearts) do
		h.Position = UDim2.fromOffset(stageW - 12 - i * (hudH + 6), 8)
		h.Size = UDim2.fromOffset(hudH, hudH)
		local img = heartImages[i]
		local r = propRect(if i <= state.lives then "heart" else "heartEmpty")
		if img and r then
			img.ImageRectOffset = r.Min
			img.ImageRectSize = Vector2.new(r.Width, r.Height)
		else
			h.BackgroundColor3 = if i <= state.lives then Color3.fromRGB(255, 72, 96) else Color3.fromRGB(90, 90, 100)
		end
	end
	hint.Position = UDim2.fromOffset(0, stageH * 0.3)
	hint.Size = UDim2.fromOffset(stageW, hudH)
	hint.Visible = state.tick < CFG.Hz * 3
end

-- A puff that fades over 0.4 s where it happened on the belt (x along it, y
-- above it, size across, all in metres): the gold burst for a coin, or a
-- drawing off the props sheet -- none without the sheet.
local function burstAt(x: number, y: number, size: number, prop: string?)
	local r = if prop then propRect(prop) else nil
	if prop and not r then
		return
	end
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	if r then
		img.Image = ART.Props.Image
		img.ImageRectOffset = r.Min
		img.ImageRectSize = Vector2.new(r.Width, r.Height)
	else
		img.Image = ART.Burst
	end
	img.ScaleType = Enum.ScaleType.Fit
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.ImageTransparency = 1
	img.ZIndex = 12
	img.Parent = stage
	table.insert(run.bursts, { image = img, born = os.clock(), x = x, y = y, size = size })
end

RunService.RenderStepped:Connect(function(dt: number)
	if not open then
		return
	end
	local state = run.state
	if run.phase ~= "running" or not state then
		if state then
			draw(state, os.clock())
		end
		return
	end
	run.acc = math.min(run.acc + dt, 8 * SproutDash.DT)
	while run.acc >= SproutDash.DT and run.phase == "running" do
		run.acc -= SproutDash.DT
		local hop = run.wantHop or autoHop(state)
		run.wantHop = false
		if hop and SproutDash.grounded(state) then
			table.insert(run.hops, state.tick)
		end
		local events = SproutDash.step(state, hop)
		if events.hopped then
			SoundKit.play("UIClick")
			-- Kicked up behind the feet, standing on the belt.
			burstAt(state.x - CFG.Runner.W * 0.4, 0.3, 1.1, "dust")
		end
		if #events.coins > 0 then
			SoundKit.play("CashTick")
			burstAt(state.x, state.y + CFG.Runner.H / 2, 2)
		end
		if events.hit then
			SoundKit.play("Denied")
			burstAt(state.x + CFG.Runner.W / 2, state.y + CFG.Runner.H / 2, 1.5, "spark")
		end
		if events.over or state.tick >= SproutDash.MaxTicks then
			finishRun()
		end
	end
	draw(state, os.clock())
end)

--==============================================================================
-- THE BUTTON'S PLACE: THE CONTEXT SLOT, A FEW TIMES A SECOND (2026-10-10, the
-- owner: "we could also apply it while riding the mill for the minigame button
-- too")
--
-- While this player rides their own mill the strip steps aside (the client-local
-- YieldPrefix .. "Minigame" attribute, which LoadoutUI reads) and the button
-- stands centred in the strip's rect (HudLayout.contextButton) at its own 230 x
-- 56 aspect, as tall as the strip or 56. Until then it stood at the nearest spot
-- clear of the HUD above the strip: a third of a phone's width, by the Treadmill
-- Fun bar and the guide's words.
--==============================================================================
local YIELD = GameConfig.ContextSlot.YieldPrefix .. "Minigame"
task.spawn(function()
	local placedAt = -math.huge
	while gui.Parent do
		local want = CFG.Enabled and not open and ownBeltUnder()
		if want and os.clock() - placedAt > 1 then
			placedAt = os.clock()
			local size = measureGui.AbsoluteSize
			if size.X > 0 and size.Y > 0 then
				-- In this gui's pixels: the measure gui's units, times its TV scale,
				-- from its corner (TreadmillFunUI's measure).
				local L = HudLayout.solve(HudLayout.measure(measureGui))
				local k = HudLayout.scaleOf(measureGui)
				local shift = measureGui.AbsolutePosition - buttonGui.AbsolutePosition
				local r = HudLayout.contextButton(L, BUTTON_W / BUTTON_H, BUTTON_H)
				playButton.Position = UDim2.fromOffset(r.x * k + shift.X, r.y * k + shift.Y)
				playButton.Size = UDim2.fromOffset(r.w, r.h)
				buttonScale.Scale = k
			end
		end
		playButton.Visible = want
		if (player:GetAttribute(YIELD) == true) ~= want then
			player:SetAttribute(YIELD, if want then true else nil)
		end
		task.wait(0.2)
	end
end)

modal.group:GetPropertyChangedSignal("Visible"):Connect(function()
	if modal.group.Visible then
		relayout()
	end
end)
relayout()
