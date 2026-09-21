--!strict
--==============================================================================
-- Podnappers :: OfflineUI
--
-- The claim card for a garden that kept earning while its owner was away.
--
-- WHAT IT IS
--
-- A night scene, because that is what the player missed: their own best plant,
-- the real CreatureModel, asleep on its bed under a moon and a sky of stars,
-- "Zzz" drifting off it. Under it, how long it grew for and the money it made,
-- counting up. One button. Pressing it is the morning: the sky turns to dawn,
-- the moon sets, the sun comes up, the plant wakes into daylight, and the coins
-- fly from the number to the wallet in the corner.
--
-- WHAT IT IS NOT
--
-- The authority. The claim lives on the server (OfflineEarnings, then
-- EconomyService); this reads the server-set player attributes named in
-- GameConfig.OfflineEarnings, sends one verb that carries nothing, and shows the
-- amount the server answers with. There is no close button: claiming is the only
-- thing to do, it costs nothing, and a card that can be dismissed by accident is
-- a claim that waits until the next visit.
--
-- Reduced FX (Settings, "Off") gets the same card, still: no twinkle, no count,
-- no sunrise, no coins.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OFFLINE = GameConfig.OfflineEarnings
local ATTR = OFFLINE.Attributes
local OFF = SeedData.Offline
local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel
local CARD = GameConfig.Card
local QUALITY = GameConfig.Afterimage.QualityAttribute
local PASS_ATTR = GameConfig.Pass.MultiplierAttribute

--==============================================================================
-- THE PALETTE: NIGHT, AND THE MORNING IT TURNS INTO
--==============================================================================
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local CREAM = Color3.fromRGB(242, 238, 206)
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local TIME_GOLD = Color3.fromRGB(255, 226, 122)

local NIGHT_TOP = Color3.fromRGB(14, 18, 52)
local NIGHT_LOW = Color3.fromRGB(62, 40, 112)
local DAWN_TOP = Color3.fromRGB(120, 176, 238)
local DAWN_LOW = Color3.fromRGB(255, 186, 124)
local MOON = Color3.fromRGB(255, 247, 214)
local MOON_GLOW = Color3.fromRGB(255, 238, 180)
local CRATER = Color3.fromRGB(236, 224, 188)
local SUN = Color3.fromRGB(255, 212, 86)
local SUN_GLOW = Color3.fromRGB(255, 170, 54)
local GRASS_NIGHT = Color3.fromRGB(36, 88, 58)
local SOIL_NIGHT = Color3.fromRGB(56, 38, 34)
local GRASS_DAY = Color3.fromRGB(96, 190, 72)
local SOIL_DAY = Color3.fromRGB(118, 78, 52)
local MOONLIGHT_AMBIENT = Color3.fromRGB(96, 104, 150)
local MOONLIGHT = Color3.fromRGB(176, 190, 255)

local COIN_FACE = Color3.fromRGB(255, 208, 64)
local COIN_RIM = Color3.fromRGB(176, 118, 0)
local COIN_INK = Color3.fromRGB(150, 96, 0)

local NIGHT_THEME: UIKit.ModalTheme = {
	fill = Color3.fromRGB(34, 36, 80),
	shade = Color3.fromRGB(18, 18, 48),
	lattice = Color3.fromRGB(82, 88, 158),
	latticeTransparency = 0.74,
	headerTop = Color3.fromRGB(104, 82, 206),
	headerBottom = Color3.fromRGB(60, 44, 146),
	headerRule = BLACK,
}

--==============================================================================
-- THE GEOMETRY
--
-- One fixed-size column scaled to whatever the modal's body can give it. A phone
-- in landscape gets the short sky (SCENE_SHORT) so the scale stays near 0.75
-- and CLAIM stays a 44-pixel target; a desktop gets the tall one.
--==============================================================================
local PANEL_W = 400
local COLUMN_W = 360
local SCENE_TALL, SCENE_SHORT = 168, 104
local INFO_H, AMOUNT_H, CHIPS_H, BUTTON_H = 40, 54, 26, 60
local GAP = 8
local EDGE = 12
local COUNT_SECONDS = 1.1
local SHOW_DELAY = 1.2
local ANSWER_PATIENCE = 8

local function contentHeight(scene: number): number
	return scene + INFO_H + AMOUNT_H + CHIPS_H + BUTTON_H + GAP * 4 + EDGE
end

local function reduced(): boolean
	return player:GetAttribute(QUALITY) == "Off"
end

--==============================================================================
-- WORDS AND NUMBERS
--==============================================================================
local function duration(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local d = s // 86400
	local h = (s % 86400) // 3600
	local m = (s % 3600) // 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	end
	if h > 0 then
		return if m > 0 then string.format("%dh %dm", h, m) else string.format("%dh", h)
	end
	return string.format("%dm", math.max(m, 1))
end

local function withCommas(n: number): string
	local digits = tostring(math.floor(n))
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

local function money(n: number): string
	if n >= 1e6 then
		return "$" .. GameConfig.compact(n)
	end
	return "$" .. withCommas(n)
end

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

--==============================================================================
-- THE REMOTE
--==============================================================================
local remotes = SeedGame:WaitForChild("Remotes", 20)
local channelInstance = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
if not (channelInstance and channelInstance:IsA("RemoteEvent")) then
	warn("[Seed/OfflineUI] No GameEvent remote; offline earnings cannot be claimed.")
	return
end
local channel = channelInstance :: RemoteEvent

--==============================================================================
-- THE CARD
--==============================================================================
local existing = playerGui:FindFirstChild("SeedOffline")
if existing then
	existing:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedOffline"
gui.ResetOnSpawn = false
-- Above the rail (40) and the biome guide's row, below the alarm (50).
gui.DisplayOrder = 42
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local modal = UIKit.modal(gui, {
	name = "Offline",
	title = OFFLINE.Title,
	maxWidth = PANEL_W,
	maxHeight = 480,
	theme = NIGHT_THEME,
})
modal.close.Visible = false

local column = Instance.new("Frame")
column.Name = "Column"
column.AnchorPoint = Vector2.new(0.5, 0)
column.Position = UDim2.fromScale(0.5, 0)
column.Size = UDim2.fromOffset(COLUMN_W, contentHeight(SCENE_TALL))
column.BackgroundTransparency = 1
column.ZIndex = 3
column.Parent = modal.body
local columnScale = Instance.new("UIScale")
columnScale.Parent = column
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, GAP)
list.Parent = column

local function frame(parent: Instance, name: string, size: UDim2, colour: Color3,
	z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function round(f: GuiObject)
	UIKit.corner(f, 999)
end

--== THE SCENE ================================================================--
local scene = frame(column, "Scene", UDim2.new(1, 0, 0, SCENE_TALL), NIGHT_TOP, 4)
scene.LayoutOrder = 1
scene.ClipsDescendants = true
UIKit.corner(scene, 12)
UIKit.stroke(scene, BLACK, 3)

local sky = frame(scene, "Sky", UDim2.fromScale(1, 1), WHITE, 4)
UIKit.gradient(sky, NIGHT_TOP, NIGHT_LOW)
local dawn = frame(scene, "Dawn", UDim2.fromScale(1, 1), WHITE, 5)
UIKit.gradient(dawn, DAWN_TOP, DAWN_LOW)
dawn.BackgroundTransparency = 1

-- Stars, placed by a fixed scatter so the sky is the same every time.
local stars: { Frame } = {}
for i = 1, 18 do
	local size = 2 + (i * 7) % 3
	local star = frame(scene, "Star" .. i, UDim2.fromOffset(size, size), WHITE, 6)
	star.AnchorPoint = Vector2.new(0.5, 0.5)
	star.Position = UDim2.fromScale(((i * 53) % 97) / 97 * 0.94 + 0.03, ((i * 29) % 61) / 61 * 0.52 + 0.05)
	star.BackgroundTransparency = 0.15 + ((i * 13) % 5) * 0.1
	round(star)
	table.insert(stars, star)
end

local moon = frame(scene, "Moon", UDim2.fromOffset(32, 32), MOON, 7)
moon.AnchorPoint = Vector2.new(0.5, 0.5)
moon.Position = UDim2.new(1, -46, 0, 34)
round(moon)
local moonGlow = Instance.new("UIStroke")
moonGlow.Color = MOON_GLOW
moonGlow.Thickness = 5
moonGlow.Transparency = 0.55
moonGlow.Parent = moon
for i, spot in ipairs({ { 0.34, 0.38, 8 }, { 0.62, 0.62, 6 }, { 0.6, 0.3, 4 } }) do
	local crater = frame(moon, "Crater" .. i, UDim2.fromOffset(spot[3], spot[3]), CRATER, 8)
	crater.AnchorPoint = Vector2.new(0.5, 0.5)
	crater.Position = UDim2.fromScale(spot[1], spot[2])
	round(crater)
end

local sun = frame(scene, "Sun", UDim2.fromOffset(38, 38), SUN, 7)
sun.AnchorPoint = Vector2.new(0.5, 0.5)
sun.Position = UDim2.new(0, 48, 1, 40)
round(sun)
local sunGlow = Instance.new("UIStroke")
sunGlow.Color = SUN_GLOW
sunGlow.Thickness = 6
sunGlow.Transparency = 0.45
sunGlow.Parent = sun

local ground = frame(scene, "Ground", UDim2.new(1, 0, 0, 30), SOIL_NIGHT, 9)
ground.AnchorPoint = Vector2.new(0, 1)
ground.Position = UDim2.fromScale(0, 1)
local grass = frame(ground, "Grass", UDim2.new(1, 0, 0, 6), GRASS_NIGHT, 10)

-- The plant: the real model, framed the way the Index frames it.
local view = Instance.new("ViewportFrame")
view.Name = "Plant"
view.AnchorPoint = Vector2.new(0.5, 1)
view.Position = UDim2.new(0.5, 0, 1, -8)
view.Size = UDim2.fromScale(0.92, 0.92)
view.BackgroundTransparency = 1
view.Ambient = MOONLIGHT_AMBIENT
view.LightColor = MOONLIGHT
view.LightDirection = CARD.LightDirection
view.ZIndex = 11
view.Parent = scene
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.DominantAxis = Enum.DominantAxis.Height
aspect.Parent = view

-- "Zzz", off the plant's shoulder.
local zees: { TextLabel } = {}
for i, size in ipairs({ 14, 18, 24 }) do
	local z = UIKit.outlined(scene, "Z" .. i, size, WHITE, 1.5)
	z.Text = if i == 3 then "Z" else "z"
	z.AnchorPoint = Vector2.new(0.5, 0.5)
	z.Size = UDim2.fromOffset(size + 6, size + 6)
	z.ZIndex = 12
	table.insert(zees, z)
end

--== THE WORDS ================================================================--
local function textRow(name: string, size: number, colour: Color3, height: number,
	order: number, outline: number): TextLabel
	local label = UIKit.outlined(column, name, size, colour, outline)
	label.Size = UDim2.new(1, 0, 0, height)
	label.LayoutOrder = order
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextScaled = true
	label.ZIndex = 4
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = size
	limit.MinTextSize = 10
	limit.Parent = label
	return label
end

local info = textRow("Info", 17, CREAM, INFO_H, 2, 1.5)
info.RichText = true
info.TextWrapped = true
local amount = textRow("Amount", 46, CASH_GREEN, AMOUNT_H, 3, 3)

--== THE CHIPS ================================================================--
local chips = Instance.new("Frame")
chips.Name = "Chips"
chips.Size = UDim2.new(1, 0, 0, CHIPS_H)
chips.BackgroundTransparency = 1
chips.LayoutOrder = 4
chips.ZIndex = 4
chips.Parent = column
local chipList = Instance.new("UIListLayout")
chipList.FillDirection = Enum.FillDirection.Horizontal
chipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
chipList.VerticalAlignment = Enum.VerticalAlignment.Center
chipList.SortOrder = Enum.SortOrder.LayoutOrder
chipList.Padding = UDim.new(0, 6)
chipList.Parent = chips

local function chip(name: string, text: string, face: Color3, shade: Color3, ink: Color3,
	order: number): Frame
	local c = frame(chips, name, UDim2.fromOffset(0, CHIPS_H), face, 5)
	c.AutomaticSize = Enum.AutomaticSize.X
	c.LayoutOrder = order
	round(c)
	UIKit.gradient(c, face, shade)
	UIKit.stroke(c, BLACK, 2)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = c
	local label = UIKit.outlined(c, "Label", 13, ink, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, CHIPS_H)
	label.Position = UDim2.fromOffset(0, -1)
	label.Text = text
	label.ZIndex = 6
	return c
end

chip("Speed", string.format("%d%% SPEED", math.floor(OFF.Efficiency * 100 + 0.5)),
	Color3.fromRGB(156, 126, 238), Color3.fromRGB(104, 78, 186), WHITE, 1)
local passChip = chip("Pass", "x2 PASS", Color3.fromRGB(255, 216, 0), Color3.fromRGB(214, 158, 0),
	WHITE, 2)
local capChip = chip("Cap", string.format("%dH MAX", math.floor(OFF.MaxCreditSeconds / 3600)),
	Color3.fromRGB(104, 116, 150), Color3.fromRGB(66, 74, 104), WHITE, 3)

--== THE BUTTON ===============================================================--
local buttonHolder = Instance.new("Frame")
buttonHolder.Name = "ButtonRow"
buttonHolder.Size = UDim2.new(1, 0, 0, BUTTON_H)
buttonHolder.BackgroundTransparency = 1
buttonHolder.LayoutOrder = 5
buttonHolder.ZIndex = 4
buttonHolder.Parent = column

-- A gold halo behind the button that breathes, so the one thing to press says so.
local halo = frame(buttonHolder, "Halo", UDim2.new(1, 6, 1, 6), WHITE, 4)
halo.AnchorPoint = Vector2.new(0.5, 0.5)
halo.Position = UDim2.fromScale(0.5, 0.5)
halo.BackgroundTransparency = 1
UIKit.corner(halo, 14)
local haloStroke = Instance.new("UIStroke")
haloStroke.Color = COIN_FACE
haloStroke.Thickness = 4
haloStroke.Transparency = 0.5
haloStroke.Parent = halo

local claim = Instance.new("TextButton")
claim.Name = "Claim"
claim.AnchorPoint = Vector2.new(0.5, 0.5)
claim.Position = UDim2.fromScale(0.5, 0.5)
claim.Size = UDim2.fromScale(1, 1)
claim.BackgroundTransparency = 1
claim.BorderSizePixel = 0
claim.AutoButtonColor = false
claim.Text = ""
claim.ZIndex = 5
claim.Parent = buttonHolder
UIKit.clicks(claim)

local plate = frame(claim, "Plate", UDim2.new(1, -4, 1, -4), WHITE, 6)
plate.AnchorPoint = Vector2.new(0.5, 0.5)
plate.Position = UDim2.fromScale(0.5, 0.5)
plate.Active = false
UIKit.corner(plate, 12)
UIKit.stroke(plate, PANEL.Outline, RAIL.OutlineThickness)
UIKit.gradient(plate, RAIL.ShopFace, RAIL.ShopShade)
local foot = frame(plate, "Shade", UDim2.new(1, 0, 0, 6), Color3.fromRGB(30, 92, 30), 7)
foot.AnchorPoint = Vector2.new(0.5, 1)
foot.Position = UDim2.fromScale(0.5, 1)
foot.Active = false
UIKit.corner(foot, 12)

local face = Instance.new("Frame")
face.Name = "Face"
face.AnchorPoint = Vector2.new(0.5, 0.5)
face.Position = UDim2.new(0.5, 0, 0.5, -2)
face.Size = UDim2.fromScale(1, 1)
face.BackgroundTransparency = 1
face.ZIndex = 8
face.Parent = plate
local faceList = Instance.new("UIListLayout")
faceList.FillDirection = Enum.FillDirection.Horizontal
faceList.HorizontalAlignment = Enum.HorizontalAlignment.Center
faceList.VerticalAlignment = Enum.VerticalAlignment.Center
faceList.SortOrder = Enum.SortOrder.LayoutOrder
faceList.Padding = UDim.new(0, 10)
faceList.Parent = face

local function coin(parent: Instance, size: number, z: number): Frame
	local c = frame(parent, "Coin", UDim2.fromOffset(size, size), COIN_FACE, z)
	round(c)
	UIKit.stroke(c, COIN_RIM, math.max(2, size * 0.09))
	local mark = UIKit.outlined(c, "Mark", math.floor(size * 0.68), COIN_INK, 0)
	mark.Size = UDim2.fromScale(1, 1)
	mark.Position = UDim2.fromOffset(0, 1)
	mark.Text = "$"
	mark.ZIndex = z + 1
	return c
end

local buttonCoin = coin(face, 30, 9)
buttonCoin.LayoutOrder = 1
local claimLabel = UIKit.outlined(face, "Label", 28, WHITE, 2.5)
claimLabel.AutomaticSize = Enum.AutomaticSize.X
claimLabel.Size = UDim2.fromOffset(0, BUTTON_H)
claimLabel.Text = OFFLINE.ClaimText
claimLabel.LayoutOrder = 2
claimLabel.ZIndex = 9

local claimScale = Instance.new("UIScale")
claimScale.Parent = claim
UIKit.cardPop(claim, claimScale, { hoverScale = 1.04, pressScale = 0.95, sound = false })

--==============================================================================
-- FITTING THE CARD TO THE SCREEN
--==============================================================================
local function fit()
	local bodyW, bodyH = modal.body.AbsoluteSize.X, modal.body.AbsoluteSize.Y
	if bodyW <= 0 or bodyH <= 0 then
		return
	end
	-- The short sky when the tall one would shrink the card below 0.8.
	local tall = math.min(bodyW / COLUMN_W, bodyH / contentHeight(SCENE_TALL))
	local sceneHeight = if tall < 0.8 then SCENE_SHORT else SCENE_TALL
	scene.Size = UDim2.new(1, 0, 0, sceneHeight)
	local h = contentHeight(sceneHeight)
	column.Size = UDim2.fromOffset(COLUMN_W, h)
	columnScale.Scale = math.clamp(math.min(bodyW / COLUMN_W, bodyH / h), 0.5, 1.15)
end
modal.body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

--==============================================================================
-- THE LOOPS, WHILE THE CARD IS OPEN
--
-- Every repeating tween is kept here and cancelled on close; nothing runs while
-- the card is shut.
--==============================================================================
local loops: { Tween } = {}
local function loop(target: Instance, info: TweenInfo, goal: { [string]: any })
	local t = TweenService:Create(target, info, goal)
	t:Play()
	table.insert(loops, t)
end
local function stopLoops()
	for _, t in ipairs(loops) do
		t:Cancel()
	end
	table.clear(loops)
end

local function placeZees()
	for i, z in ipairs(zees) do
		z.Position = UDim2.new(0.5, 30 + i * 12, 0.34 - i * 0.09, 0)
		z.TextTransparency = 0
		local stroke = z:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
	end
end

local function startNightLoops()
	for i, star in ipairs(stars) do
		loop(star, TweenInfo.new(0.9 + (i % 5) * 0.35, Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut, -1, true, (i % 7) * 0.18), { BackgroundTransparency = 0.85 })
	end
	loop(moonGlow, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.85 })
	for i, z in ipairs(zees) do
		local base = z.Position
		loop(z, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, false, (i - 1) * 0.45),
			{ Position = base + UDim2.fromOffset(10, -22), TextTransparency = 1 })
		local stroke = z:FindFirstChildOfClass("UIStroke")
		if stroke then
			loop(stroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, false,
				(i - 1) * 0.45), { Transparency = 1 })
		end
	end
	loop(haloStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.05, Thickness = 6 })
end

--==============================================================================
-- STATE
--==============================================================================
local isOpen = false
local claiming = false
local plantModel: Model? = nil
local shownValue = 0
local countConn: RBXScriptConnection? = nil

local function pendingBase(): number
	local v = player:GetAttribute(ATTR.Cash)
	return if type(v) == "number" and v == v and v > 0 then v else 0
end

local function multiplier(): number
	local v = player:GetAttribute(PASS_ATTR)
	return if type(v) == "number" and v == v and v > 0 then v else 1
end

local function setAmount(n: number)
	shownValue = n
	amount.Text = "+" .. money(n)
end

local function countTo(target: number)
	if countConn then
		countConn:Disconnect()
		countConn = nil
	end
	if reduced() then
		setAmount(target)
		return
	end
	local from = shownValue
	local started = os.clock()
	countConn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - started) / COUNT_SECONDS, 0, 1)
		local eased = 1 - (1 - t) ^ 3
		setAmount(math.floor(from + (target - from) * eased))
		if t >= 1 then
			setAmount(target)
			if countConn then
				countConn:Disconnect()
				countConn = nil
			end
		end
	end)
end

local function fillWords()
	local grown = tonumber(player:GetAttribute(ATTR.Grown)) or 0
	local credited = tonumber(player:GetAttribute(ATTR.Seconds)) or 0
	local away = tonumber(player:GetAttribute(ATTR.Away)) or credited
	local capped = credited >= OFF.MaxCreditSeconds
	local plants = string.format('<font color="%s">%d plant%s</font>', hex(CASH_GREEN), grown,
		if grown == 1 then "" else "s")
	if capped and away > credited then
		info.Text = string.format('Your %s grew for the max <font color="%s">%s</font>\n(you were gone %s)',
			plants, hex(TIME_GOLD), duration(credited), duration(away))
	else
		info.Text = string.format('Your %s kept growing for <font color="%s">%s</font>',
			plants, hex(TIME_GOLD), duration(credited))
	end
	passChip.Visible = multiplier() >= 2
	capChip.Visible = capped
end

local function buildPlant()
	if plantModel then
		plantModel:Destroy()
		plantModel = nil
	end
	local id = player:GetAttribute(ATTR.Best)
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	if not species then
		return
	end
	local tier = tonumber(player:GetAttribute(ATTR.BestTier)) or SeedData.BaseTier
	local ok, model = pcall(function()
		return CreatureModel.Build(species, tier, CreatureModel.STAGE_GROWN, CFrame.new(), view)
	end)
	if ok and model then
		plantModel = model
		local camera = UIKit.framePlant(view, model, species.Form, 0.8)
		view.CurrentCamera = camera
	end
end

local function resetScene()
	stopLoops()
	dawn.BackgroundTransparency = 1
	for i, star in ipairs(stars) do
		star.BackgroundTransparency = 0.15 + ((i * 13) % 5) * 0.1
	end
	moon.Position = UDim2.new(1, -46, 0, 34)
	moonGlow.Transparency = 0.55
	sun.Position = UDim2.new(0, 48, 1, 40)
	ground.BackgroundColor3 = SOIL_NIGHT
	grass.BackgroundColor3 = GRASS_NIGHT
	view.Ambient = MOONLIGHT_AMBIENT
	view.LightColor = MOONLIGHT
	haloStroke.Transparency = 0.5
	haloStroke.Thickness = 4
	placeZees()
	claimLabel.Text = OFFLINE.ClaimText
	claim.Active = true
end

local function close()
	if not isOpen then
		return
	end
	isOpen = false
	claiming = false
	if countConn then
		countConn:Disconnect()
		countConn = nil
	end
	stopLoops()
	modal.setOpen(false)
	task.delay(0.4, function()
		if not isOpen and plantModel then
			plantModel:Destroy()
			plantModel = nil
		end
	end)
end

local function open()
	if isOpen or pendingBase() <= 0 then
		return
	end
	isOpen = true
	claiming = false
	resetScene()
	buildPlant()
	fillWords()
	setAmount(0)
	modal.setOpen(true)
	modal.fitContent(contentHeight(SCENE_TALL))
	task.defer(fit)
	if not reduced() then
		startNightLoops()
	end
	task.delay(0.25, function()
		if not isOpen then
			return
		end
		if not reduced() then
			SoundKit.play("HatchTimeSkip", { volume = 0.55 })
		end
		countTo(math.floor(pendingBase() * multiplier()))
	end)
end

--==============================================================================
-- THE MORNING, AND THE COINS
--==============================================================================
local function walletPoint(): Vector2
	local ok, point = pcall(function()
		local layout = HudLayout.solve(HudLayout.measure(gui))
		local r = layout.cashRoot
		return Vector2.new(r.x + r.w * 0.3, r.y + r.h * 0.5)
	end)
	if ok and typeof(point) == "Vector2" then
		return point
	end
	return Vector2.new(90, gui.AbsoluteSize.Y - 130)
end

local function coinsToWallet()
	local from = amount.AbsolutePosition + amount.AbsoluteSize * 0.5 - gui.AbsolutePosition
	local to = walletPoint()
	for i = 1, 12 do
		local c = coin(gui, 24, 60)
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.fromOffset(from.X + (i % 5 - 2) * 14, from.Y + (i % 3 - 1) * 8)
		local mid = UDim2.fromOffset((from.X + to.X) * 0.5 + (i % 4 - 1.5) * 30,
			math.min(from.Y, to.Y) - 60 - (i % 3) * 18)
		task.delay((i - 1) * 0.035, function()
			local up = TweenService:Create(c, TweenInfo.new(0.28, Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out), { Position = mid })
			up:Play()
			up.Completed:Wait()
			local down = TweenService:Create(c, TweenInfo.new(0.34, Enum.EasingStyle.Quad,
				Enum.EasingDirection.In), { Position = UDim2.fromOffset(to.X, to.Y),
				Size = UDim2.fromOffset(14, 14) })
			down:Play()
			down.Completed:Wait()
			c:Destroy()
		end)
	end
end

local function sunrise()
	stopLoops()
	local slow = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(dawn, slow, { BackgroundTransparency = 0 }):Play()
	for _, star in ipairs(stars) do
		TweenService:Create(star, slow, { BackgroundTransparency = 1 }):Play()
	end
	TweenService:Create(moon, slow, { Position = UDim2.new(1, -46, 1, 40) }):Play()
	TweenService:Create(sun, TweenInfo.new(1.0, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 48, 0, 34) }):Play()
	TweenService:Create(ground, slow, { BackgroundColor3 = SOIL_DAY }):Play()
	TweenService:Create(grass, slow, { BackgroundColor3 = GRASS_DAY }):Play()
	TweenService:Create(view, slow, { Ambient = CARD.Ambient, LightColor = CARD.LightColour }):Play()
	for _, z in ipairs(zees) do
		TweenService:Create(z, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		local stroke = z:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
	end
end

--==============================================================================
-- CLAIMING
--==============================================================================
local answerGeneration = 0

-- The press, as one function. The button calls it, and so does the
-- ClaimPressed event below, which is how a Play test presses CLAIM without
-- injecting input into somebody's desktop -- the same code path either way.
local function pressClaim()
	if not isOpen or claiming then
		return
	end
	claiming = true
	claim.Active = false
	claimLabel.Text = "..."
	answerGeneration += 1
	local mine = answerGeneration
	channel:FireServer(OFFLINE.ClaimAction)
	task.delay(ANSWER_PATIENCE, function()
		-- No answer: let them press again rather than leave a dead button --
		-- unless the claim is already gone, in which case it was paid and the
		-- answer is what went missing.
		if isOpen and claiming and answerGeneration == mine then
			claiming = false
			if pendingBase() <= 0 then
				close()
				return
			end
			claim.Active = true
			claimLabel.Text = OFFLINE.ClaimText
		end
	end)
end

claim.Activated:Connect(pressClaim)
local pressed = Instance.new("BindableEvent")
pressed.Name = "ClaimPressed"
pressed.Parent = gui
pressed.Event:Connect(pressClaim)

channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= OFFLINE.ReplyAction or type(payload) ~= "table" then
		return
	end
	local paid = tonumber(payload.paid) or 0
	if not isOpen then
		return
	end
	answerGeneration += 1
	if paid <= 0 then
		close()
		return
	end
	if countConn then
		countConn:Disconnect()
		countConn = nil
	end
	setAmount(paid)
	claimLabel.Text = "CLAIMED!"
	SoundKit.play("SellAll")
	if reduced() then
		task.delay(0.35, close)
		return
	end
	sunrise()
	task.delay(0.45, coinsToWallet)
	-- Long enough to see the morning after the sun is up, not so long it waits.
	task.delay(2.4, close)
end)

--==============================================================================
-- WHEN TO SHOW IT
--
-- Whenever a claim is waiting and the card is shut: on join, once the profile
-- has landed and the attributes with it, after a beat so the world and the HUD
-- are up first. If the claim disappears while the card is open -- paid by
-- another path -- the card goes with it.
--==============================================================================
local scheduled = false
local function consider()
	if pendingBase() <= 0 then
		if isOpen and not claiming then
			close()
		end
		return
	end
	if isOpen then
		fillWords()
		if not claiming then
			countTo(math.floor(pendingBase() * multiplier()))
		end
		return
	end
	if scheduled then
		return
	end
	scheduled = true
	task.delay(SHOW_DELAY, function()
		scheduled = false
		if pendingBase() > 0 then
			open()
		end
	end)
end

player:GetAttributeChangedSignal(ATTR.Cash):Connect(consider)
player:GetAttributeChangedSignal(PASS_ATTR):Connect(function()
	if isOpen then
		consider()
	end
end)
consider()
