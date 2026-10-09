--!strict
--==============================================================================
-- Steal a Seed :: RebirthUI (2026-10-08)
--
-- The REBIRTH panel the shrine opens, and the words floating over the shrine.
-- It decides nothing: the panel shows the SERVER's quote (RebirthService), the
-- REBIRTH button asks twice -- "ARE YOU SURE?" -- and its second press sends
-- the quote's token back, and what happened is the server's answer. In the
-- studded kit's Rebirth band (GameConfig.Rebirth.Look). No HUD button: the
-- phone's HUD is full; the shrine is the way in.
--
-- THE BODY (reworked 2026-10-08, the owner: "add more detail on the rebirth
-- info, we will add how the required mill look"):
--   the strip      this rebirth and its title, in the title's colour, and the
--                  next one previewed;
--   BONUS          training and income, now -> after the next rebirth;
--   REQUIREMENTS   the cash on a bar, the mill in words, each with a tick or a
--                  cross -- and the REAL required mill, live in 3D, turning
--                  slowly (still for reduced motion), so the player sees exactly
--                  what to build;
--   NEXT UNLOCKS   the next fence, live on a short run of the real fence
--                  (Shared/FenceStyle), and the next title;
--   KEEP / LOSE    as chips, with the game's own icons where it has them.
-- Two columns where they fit, one scrolling column on a phone. The 3D pictures
-- are built when the panel opens and destroyed when it closes.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local RebirthFX = require(Shared:WaitForChild("RebirthFX"))
local FenceStyle = require(Shared:WaitForChild("FenceStyle"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local CFG = GameConfig.Rebirth
local WORDS = CFG.Words
local ART = CFG.Art
local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local PANEL_NAME = "Rebirth"
local CLOSE_ACTION = "SeedRebirthClose"
local WHITE = Color3.new(1, 1, 1)
local GOOD = Color3.fromRGB(110, 230, 90)
local BAD = Color3.fromRGB(255, 96, 96)
local DIM = Color3.fromRGB(46, 30, 52)
-- How long the second press has to come.
local ARMED_SECONDS = 4
-- Between the two columns.
local GAP = 10

--==============================================================================
-- THE WORDS OVER THE SHRINE (FloatingSign), everybody's, always
--==============================================================================
task.spawn(function()
	Workspace:WaitForChild(CFG.FolderName, math.huge)
	local W = CFG.FloatingWords
	local holder = Instance.new("Folder")
	holder.Name = "SeedRebirthWords"
	holder.Parent = Workspace
	local sign = FloatingSign.new({
		name = "RebirthWords",
		parent = holder,
		at = CFrame.new(CFG.Position + Vector3.new(0, W.Above, 0)),
		text = W.Text,
		colour = W.Colour,
		width = W.Width,
		height = W.Height,
		subText = W.SubText,
		subHeight = W.SubHeight,
	})
	sign.setShown(true)
end)

--==============================================================================
-- ICONS: the game's own where they exist, the owner's uploads where their
-- ids are set, a drawn stand-in otherwise -- never anybody else's upload
--==============================================================================
-- A GameConfig path such as "SourceIcons.speed".
local function configIcon(path: string?): string?
	if not path then
		return nil
	end
	local node: any = GameConfig
	for key in string.gmatch(path, "[^%.]+") do
		if type(node) ~= "table" then
			return nil
		end
		node = node[key]
	end
	return if type(node) == "string" and node ~= "" then node else nil
end

local function image(parent: Instance, name: string, size: number, z: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(size, size)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = z
	icon.Parent = parent
	return icon
end

-- The drawn stand-in: a round mark in `colour` with a letter or glyph on it.
local function mark(parent: Instance, name: string, size: number, z: number, colour: Color3, glyph: string): Frame
	local dot = MenuKit.frame(parent, name, z, colour, 0, 999)
	dot.Size = UDim2.fromOffset(size, size)
	local edge = Instance.new("UIStroke")
	edge.Color = DIM
	edge.Thickness = 2
	edge.Parent = dot
	local letter = MenuKit.text(dot, "Glyph", math.floor(size * 0.62), WHITE, z + 1)
	letter.Size = UDim2.fromScale(1, 1)
	letter.Text = glyph
	letter.TextXAlignment = Enum.TextXAlignment.Center
	return dot
end

-- One of the owner's icons (Art.Emblem / Mill / CashReset / TitleBadge), or its
-- stand-in where its id is "".
local function sheetIcon(parent: Instance, name: string, cell: string, size: number, z: number, colour: Color3,
	glyph: string): GuiObject
	local id = (ART :: any)[cell]
	if type(id) == "string" and id ~= "" then
		local icon = image(parent, name, size, z)
		icon.Image = id
		icon.ImageRectOffset = ART.CropOffset
		icon.ImageRectSize = ART.CropSize
		return icon
	end
	return mark(parent, name, size, z, colour, glyph)
end

--==============================================================================
-- THE PANEL
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedRebirth"
gui.ResetOnSpawn = false
-- The menus' order (Shop, EVENTS): over the rails when it covers them.
gui.DisplayOrder = 32
gui.Parent = playerGui

-- The band's emblem: the owner's, or the shrine's glowing seed drawn.
local function drawSeed(holder: Frame, z: number)
	if ART.Emblem ~= "" then
		local icon = image(holder, "Emblem", 1, z)
		icon.Size = UDim2.fromScale(1, 1)
		icon.Image = ART.Emblem
		icon.ImageRectOffset = ART.CropOffset
		icon.ImageRectSize = ART.CropSize
		return
	end
	local seed = MenuKit.frame(holder, "Seed", z, CFG.Look.Band, 0, 999)
	seed.AnchorPoint = Vector2.new(0.5, 0.5)
	seed.Position = UDim2.fromScale(0.5, 0.5)
	seed.Size = UDim2.fromScale(0.78, 0.78)
	local edge = Instance.new("UIStroke")
	edge.Color = CFG.Look.Edge
	edge.Thickness = 2
	edge.Parent = seed
	local shine = MenuKit.frame(seed, "Shine", z + 1, WHITE, 0.35, 999)
	shine.Position = UDim2.fromScale(0.2, 0.16)
	shine.Size = UDim2.fromScale(0.3, 0.3)
end

local menu = MenuKit.modal(gui, PANEL_NAME, WORDS.Title, nil, nil, drawSeed, nil, MenuKit.studdedTheme(CFG.Look))
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = CFG.Look.Edge
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.CanvasSize = UDim2.new()
scroll.ZIndex = 4
scroll.Parent = body

local function column(name: string): (Frame, UIListLayout)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Parent = scroll
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = f
	return f, list
end
local left, leftList = column("Left")
local right, rightList = column("Right")

local order = 0
local function block(parent: Instance, name: string, height: number): Frame
	order += 1
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.LayoutOrder = order
	f.Size = UDim2.new(1, 0, 0, height)
	f.Parent = parent
	return f
end
local function words(parent: Instance, name: string, size: number, colour: Color3, z: number?): TextLabel
	local label = MenuKit.text(parent, name, size, colour, z or 6)
	label.Size = UDim2.fromScale(1, 1)
	return label
end

-- One line that always fits its box (2026-10-08: the roman numerals make the
-- titles longer). Drawn at `base` unless the words are wider than the box, then
-- just small enough (Rebirth.fitSize). The room is the box's own width with
-- every UIScale above it taken out -- a phone's, and the panel's pop while it
-- opens -- so the size never pulses with them.
local FIT_MARGIN = 6
local function fitOne(label: TextLabel, base: number)
	local function fit()
		local k = 1
		local node: Instance? = label.Parent
		while node and node ~= playerGui do
			local s = node:FindFirstChildOfClass("UIScale")
			if s then
				k *= s.Scale
			end
			node = node.Parent
		end
		if k < 0.05 then
			return
		end
		local room = label.AbsoluteSize.X / k - FIT_MARGIN
		local need = if label.Text == "" then 0 else MenuKit.textWidth(label.Text, base, label.Font)
		label.TextSize = Rebirth.fitSize(base, need, room)
	end
	label:GetPropertyChangedSignal("Text"):Connect(fit)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
end
local function heading(parent: Instance, text: string, colour: Color3)
	local label = words(block(parent, "Heading", 22), "Words", 17, colour)
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
end

-- THE STRIP: this rebirth and its title, the next one under it.
local strip = block(left, "Strip", 60)
local stripNow = words(strip, "Now", 26, WHITE)
stripNow.Size = UDim2.new(1, 0, 0, 34)
local stripRainbow = Instance.new("UIGradient")
stripRainbow.Name = "Rainbow"
stripRainbow.Color = WheelDraw.rainbow(0)
stripRainbow.Enabled = false
stripRainbow.Parent = stripNow
local stripNext = words(strip, "Next", 16, Color3.fromRGB(255, 220, 236))
stripNext.Position = UDim2.fromOffset(0, 36)
stripNext.Size = UDim2.new(1, 0, 0, 22)
fitOne(stripNow, 26)
fitOne(stripNext, 16)

-- BONUS: now -> after the next rebirth.
heading(left, WORDS.BonusTitle, CFG.Look.Band)
local function bonusRow(name: string, iconPath: string, label: string): TextLabel
	local row = block(left, name, 34)
	local icon = image(row, "Icon", 30, 6)
	icon.Image = configIcon(iconPath) or ""
	local what = words(row, "What", 17, WHITE)
	what.Position = UDim2.fromOffset(38, 0)
	what.Size = UDim2.new(0.45, -38, 1, 0)
	what.TextXAlignment = Enum.TextXAlignment.Left
	what.Text = label
	local step = words(row, "Step", 19, GOOD)
	step.Position = UDim2.fromScale(0.45, 0)
	step.Size = UDim2.fromScale(0.55, 1)
	step.TextXAlignment = Enum.TextXAlignment.Right
	return step
end
local trainingStep = bonusRow("Training", "SourceIcons.training", WORDS.Training)
local incomeStep = bonusRow("Income", "SourceIcons.income", WORDS.Income)

-- REQUIREMENTS, each with a tick or a cross.
heading(left, WORDS.NeedsTitle, CFG.Look.Band)
local function tick(parent: Instance): TextLabel
	local t = words(parent, "Tick", 22, GOOD)
	t.Size = UDim2.fromOffset(26, 26)
	t.TextXAlignment = Enum.TextXAlignment.Center
	return t
end
local cashRow = block(left, "Cash", 30)
local cashTick = tick(cashRow)
local cashWord = words(cashRow, "What", 17, WHITE)
cashWord.Position = UDim2.fromOffset(30, 0)
cashWord.Size = UDim2.fromOffset(60, 26)
cashWord.TextXAlignment = Enum.TextXAlignment.Left
cashWord.Text = WORDS.CashLabel
local track = MenuKit.frame(cashRow, "Track", 6, DIM, 0, 8)
track.Position = UDim2.fromOffset(94, 2)
track.Size = UDim2.new(1, -94, 0, 24)
local cashFill = MenuKit.frame(track, "Fill", 7, GOOD, 0, 8)
cashFill.Size = UDim2.fromScale(0, 1)
local cashText = words(track, "Amount", 15, WHITE, 8)
cashText.TextXAlignment = Enum.TextXAlignment.Center

local millRow = block(left, "Mill", 44)
local millTick = tick(millRow)
local millIcon = sheetIcon(millRow, "MillIcon", "Mill", 26, 6, Color3.fromRGB(150, 98, 52), "M")
millIcon.Position = UDim2.fromOffset(30, 0)
local millWords = words(millRow, "Line", 15, WHITE)
millWords.Position = UDim2.fromOffset(62, 0)
millWords.Size = UDim2.new(1, -62, 1, 0)
millWords.TextXAlignment = Enum.TextXAlignment.Left
millWords.TextYAlignment = Enum.TextYAlignment.Top
millWords.TextWrapped = true

-- A live 3D picture: a ViewportFrame with a WorldModel and its own camera.
local function viewport(parent: Instance, name: string, height: number): (ViewportFrame, WorldModel, Camera)
	local holder = block(parent, name, height)
	local view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.BackgroundColor3 = Color3.fromRGB(58, 40, 66)
	view.BackgroundTransparency = 0
	view.Size = UDim2.fromScale(1, 1)
	view.Ambient = Color3.fromRGB(170, 160, 175)
	view.LightColor = Color3.fromRGB(255, 248, 236)
	view.LightDirection = Vector3.new(-1, -2, -1)
	view.ZIndex = 6
	view.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = view
	local world = Instance.new("WorldModel")
	world.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = view
	view.CurrentCamera = camera
	return view, world, camera
end
local _, millWorld, millCamera = viewport(left, "MillPreview", 180)

-- NEXT UNLOCKS: the next fence on a short run of the real fence, and the next
-- title.
heading(right, WORDS.UnlocksTitle, CFG.Look.Band)
local _, fenceWorld, fenceCamera = viewport(right, "FencePreview", 120)
local fenceLine = words(block(right, "Fence", 20), "Words", 15, WHITE)
fenceLine.TextXAlignment = Enum.TextXAlignment.Left
local titleRow = block(right, "Title", 30)
local badge = sheetIcon(titleRow, "Badge", "TitleBadge", 26, 6, Color3.fromRGB(226, 176, 66), "★")
badge.Position = UDim2.fromOffset(0, 2)
local titleLine = words(titleRow, "Words", 17, WHITE)
titleLine.Position = UDim2.fromOffset(34, 0)
titleLine.Size = UDim2.new(1, -34, 1, 0)
titleLine.TextXAlignment = Enum.TextXAlignment.Left
fitOne(titleLine, 17)

-- YOU KEEP / YOU LOSE, as chips.
local function chips(parent: Instance, name: string, list: { any }, tint: Color3, sheet: boolean)
	local holder = block(parent, name, 10)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -3, 0, 30)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = holder
	for i, item in ipairs(list) do
		local chip = MenuKit.frame(holder, "Chip" .. i, 6, DIM, 0.15, 8)
		chip.LayoutOrder = i
		local edge = Instance.new("UIStroke")
		edge.Color = tint
		edge.Thickness = 1.5
		edge.Parent = chip
		local icon: GuiObject
		if sheet then
			icon = sheetIcon(chip, "Icon", item.Art, 22, 7, tint,
				if item.Art == "CashReset" then "$" else "M")
		else
			local id = configIcon(item.Icon)
			if id then
				local img = image(chip, "Icon", 22, 7)
				img.Image = id
				icon = img
			else
				icon = mark(chip, "Icon", 22, 7, tint, string.sub(item.Text, 1, 1))
			end
		end
		icon.Position = UDim2.fromOffset(5, 4)
		local label = words(chip, "Words", 14, WHITE, 7)
		label.Position = UDim2.fromOffset(32, 0)
		label.Size = UDim2.new(1, -36, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextScaled = true
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 14
		fit.MinTextSize = 9
		fit.Parent = label
		label.Text = item.Text
	end
end
heading(right, WORDS.KeepTitle, GOOD)
chips(right, "Keep", CFG.Keep, GOOD, false)
heading(right, WORDS.LoseTitle, BAD)
chips(right, "Lose", CFG.Lose, BAD, true)

-- THE FOOT: the reason line and the button, always in view.
local foot = Instance.new("Frame")
foot.Name = "Foot"
foot.BackgroundTransparency = 1
foot.Parent = body
local status = words(foot, "Status", 15, BAD)
status.Size = UDim2.new(1, 0, 0, 22)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center
local button = MenuKit.button(foot, "RebirthButton", 6, WORDS.Button, 24, { studs = true } :: any)
button.hit.AnchorPoint = Vector2.new(0.5, 0)
button.hit.Position = UDim2.new(0.5, 0, 0, 26)
button.hit.Size = UDim2.new(0.5, 0, 0, 56)

--==============================================================================
-- THE "?" AND THE TITLES VIEW (2026-10-08, the owner: "i want players to see
-- the titles inside a question mark button inside the rebirth ui")
--
-- The "?" stands left of the X in the band, round, blue and studded like the
-- wheel's REWARDS & ODDS "?". It swaps the body for TITLES: a BACK control
-- over a scrolling list of every step -- the word in its own colour, its
-- rebirth, the training and income it comes with, and a chip: REACHED (the
-- highest one lit), NEXT, or LOCKED (greyed, still readable). Opening it puts
-- the NEXT row in view.
--==============================================================================
local BLUE = GameConfig.StuddedLook.Settings.Band
local BLUE_RIM = GameConfig.StuddedLook.Settings.Edge
local touch = 44

local help = Instance.new("TextButton")
help.Name = "Help"
help.AnchorPoint = Vector2.new(1, 0.5)
help.Position = UDim2.new(1, -(touch + CFG.Layout.HelpGap), 0.5, 0)
help.Size = UDim2.fromOffset(touch, touch)
help.BackgroundTransparency = 1
help.Text = ""
help.AutoButtonColor = false
help.ZIndex = 8
help.Parent = menu.titleBar
local helpRim = MenuKit.frame(help, "Rim", 8, BLUE_RIM, 0, 999)
helpRim.AnchorPoint = Vector2.new(0.5, 0.5)
helpRim.Position = UDim2.fromScale(0.5, 0.5)
helpRim.Size = UDim2.fromOffset(38, 38)
local helpFace = MenuKit.frame(helpRim, "Face", 9, BLUE, 0, 999)
helpFace.AnchorPoint = Vector2.new(0.5, 0.5)
helpFace.Position = UDim2.new(0.5, 0, 0.5, -1)
helpFace.Size = UDim2.new(1, -6, 1, -6)
do
	local t = Instance.new("ImageLabel")
	t.Name = "StudTexture"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Image = GameConfig.StuddedLook.Texture
	t.ScaleType = Enum.ScaleType.Tile
	t.TileSize = UDim2.fromOffset(GameConfig.StuddedLook.Tile, GameConfig.StuddedLook.Tile)
	t.ImageTransparency = GameConfig.StuddedLook.BandStuds
	t.ZIndex = 9
	t.Parent = helpFace
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = t
end
local helpGlyph = words(helpFace, "Glyph", 22, WHITE, 10)
helpGlyph.Text = WORDS.Help
helpGlyph.TextXAlignment = Enum.TextXAlignment.Center

local titlesView = Instance.new("Frame")
titlesView.Name = "TitlesView"
titlesView.BackgroundTransparency = 1
titlesView.Visible = false
titlesView.Parent = body
local back = MenuKit.button(titlesView, "Back", 6, WORDS.Back, 16, { studs = true } :: any)
back.style("sky")
local titlesHeading = words(titlesView, "Heading", 20, CFG.Look.Band)
titlesHeading.Text = WORDS.TitlesTitle
titlesHeading.TextXAlignment = Enum.TextXAlignment.Left
local list = Instance.new("ScrollingFrame")
list.Name = "TitleList"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = CFG.Look.Edge
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 5
list.Parent = titlesView
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = list

-- Room round the rows for the ring (below) to show whole.
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingBottom = UDim.new(0, 4)
listPad.Parent = list

type TitleRow = { frame: Frame, ring: UIStroke, word: TextLabel, rebirth: TextLabel, bonus: TextLabel,
	chip: TextLabel, rainbow: UIGradient?, step: any }
local titleRows: { TitleRow } = {}
local GREY = Color3.fromRGB(150, 146, 156)
local LIT = Color3.fromRGB(255, 220, 90)
for i, step in ipairs(CFG.Title.Ladder) do
	local row = MenuKit.frame(list, "Row" .. i, 6, DIM, 0.2, 10)
	row.LayoutOrder = i
	row.Size = UDim2.new(1, -10, 0, CFG.Layout.TitleRow)
	-- The highest step reached and the next one are RINGED, never filled, so
	-- every title colour stays on the same dark plate (2026-10-08: on a
	-- filled pink row BLOOM WARDEN's pink words all but vanished).
	local ring = Instance.new("UIStroke")
	ring.Name = "Ring"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Enabled = false
	ring.Parent = row
	-- The step's words with its numerals' range, and its rebirths.
	local stepText, stepRebirths = Rebirth.stepWords(i)
	local word = words(row, "Word", 22, step.Colour, 7)
	word.Position = UDim2.fromOffset(12, 4)
	word.Size = UDim2.new(0.42, -12, 0, 30)
	word.TextXAlignment = Enum.TextXAlignment.Left
	word.Text = stepText
	fitOne(word, 22)
	local rainbow: UIGradient? = nil
	if step.Rainbow then
		local g = Instance.new("UIGradient")
		g.Name = "Rainbow"
		g.Color = WheelDraw.rainbow(0)
		g.Parent = word
		rainbow = g
	end
	local rebirthWords = words(row, "Rebirth", 13, Color3.fromRGB(255, 236, 244), 7)
	rebirthWords.Position = UDim2.fromOffset(12, 33)
	rebirthWords.Size = UDim2.new(0.42, -12, 0, 18)
	rebirthWords.TextXAlignment = Enum.TextXAlignment.Left
	rebirthWords.Text = stepRebirths
	local bonusWords = words(row, "Bonus", 14, WHITE, 7)
	bonusWords.Position = UDim2.fromScale(0.42, 0)
	bonusWords.Size = UDim2.new(0.36, 0, 1, 0)
	bonusWords.TextWrapped = true
	bonusWords.Text = string.format(WORDS.RowBonus, Rebirth.times(Rebirth.training(step.At)),
		Rebirth.times(Rebirth.income(step.At)))
	local chip = words(row, "State", 14, WHITE, 8)
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(1, -10, 0.5, 0)
	chip.Size = UDim2.new(0.2, 0, 0, 26)
	chip.TextXAlignment = Enum.TextXAlignment.Right
	table.insert(titleRows, { frame = row, ring = ring, word = word, rebirth = rebirthWords, bonus = bonusWords,
		chip = chip, rainbow = rainbow, step = step })
end

-- Marks every row for a count: the highest REACHED ringed in gold, the NEXT
-- one in the band's colour, the rest LOCKED and greyed.
local function paintTitles(rebirths: number): number
	local rows, highest, nextIndex = Rebirth.ladder(rebirths)
	for i, r in ipairs(titleRows) do
		local state = rows[i].state
		local locked = state == "locked"
		r.word.TextColor3 = if locked and not r.step.Rainbow then r.step.Colour:Lerp(GREY, 0.55) else r.step.Colour
		r.word.TextTransparency = if locked then 0.15 else 0
		r.bonus.TextColor3 = if locked then GREY else WHITE
		r.frame.BackgroundColor3 = DIM
		r.frame.BackgroundTransparency = if i == highest then 0.05 else 0.2
		r.ring.Enabled = i == highest or state == "next"
		r.ring.Color = if i == highest then LIT else CFG.Look.Band
		r.ring.Thickness = if i == highest then 3 else 2
		r.chip.Text = if state == "reached" then WORDS.Reached elseif state == "next" then WORDS.NextChip else WORDS.Locked
		r.chip.TextColor3 = if state == "reached" then GOOD elseif state == "next" then Color3.fromRGB(255, 220, 236)
			else GREY
	end
	return nextIndex
end

local showingTitles = false
local function showTitles(on: boolean, rebirths: number?)
	showingTitles = on
	titlesView.Visible = on
	scroll.Visible = not on
	foot.Visible = not on
	if on then
		local nextIndex = paintTitles(rebirths or 0)
		-- The NEXT row in view (the last one once every step is reached).
		task.defer(function()
			local k = UIKit.scaleOf(gui)
			local index = if nextIndex > 0 then nextIndex else #titleRows
			local rowY = (index - 1) * (CFG.Layout.TitleRow + 6)
			local view = list.AbsoluteSize.Y / k
			list.CanvasPosition = Vector2.new(0, math.max(0, rowY - (view - CFG.Layout.TitleRow) * 0.5) * k)
		end)
	end
end

--==============================================================================
-- THE 3D PICTURES: built on open, destroyed on close, turning while open
--==============================================================================
local shown: { Model } = {}

-- A model built detached, its CollectionService tags taken off before it ever
-- enters the game (the mill's gears, wheels and banners are tagged for the
-- world's animators, which must never find a picture), then put in its world.
local function place(model: Model, world: WorldModel)
	for _, d in ipairs(model:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(d)) do
			CollectionService:RemoveTag(d, tag)
		end
	end
	model.Parent = world
	table.insert(shown, model)
end

local function clearPictures()
	for _, model in ipairs(shown) do
		model:Destroy()
	end
	table.clear(shown)
end

type Framing = { focus: Vector3, distance: number }
local millFraming: Framing? = nil
local fenceFraming: Framing? = nil

local function frame(model: Model, camera: Camera, tight: number): Framing
	local cf, size = model:GetBoundingBox()
	local radius = size.Magnitude * 0.5
	local distance = radius / math.tan(math.rad(camera.FieldOfView * 0.5)) * tight
	return { focus = cf.Position, distance = distance }
end

local function aim(camera: Camera, framing: Framing?, angle: number)
	if not framing then
		return
	end
	local pitch = math.rad(CFG.Preview.Pitch)
	local offset = Vector3.new(math.cos(angle) * math.cos(pitch), math.sin(pitch), math.sin(angle) * math.cos(pitch))
	camera.CFrame = CFrame.lookAt(framing.focus + offset * framing.distance, framing.focus)
end

local function buildPictures(rebirths: number)
	clearPictures()
	-- The REQUIRED mill, the real model at its real tier.
	local holder = Instance.new("Folder")
	local mill = MillModel.Build(CFG.MinMillTier, CFrame.new(), holder)
	place(mill, millWorld)
	holder:Destroy()
	millFraming = frame(mill, millCamera, 1.05)
	-- The NEXT fence, on a short run of the real fence.
	local sample = FenceStyle.segment(rebirths + 1, CFG.Preview.FenceLength)
	place(sample, fenceWorld)
	fenceFraming = frame(sample, fenceCamera, 0.82)
end

local turning: RBXScriptConnection? = nil
local function setTurning(on: boolean)
	if turning then
		turning:Disconnect()
		turning = nil
	end
	if not on then
		return
	end
	local started = os.clock()
	turning = RunService.RenderStepped:Connect(function()
		-- A fixed three-quarter view for reduced motion; otherwise one slow turn.
		local still = StatusText.reducedMotion()
		local angle = math.rad(-55)
		if not still then
			angle += (os.clock() - started) / CFG.Preview.TurnSeconds * math.pi * 2
		end
		aim(millCamera, millFraming, angle)
		aim(fenceCamera, fenceFraming, math.rad(-70))
		-- The rainbow title's colours turn like ADMIN's (OwnerTitleUI), still
		-- for reduced motion.
		local colours = WheelDraw.rainbow(if still then 0 else ((os.clock() - started) / GameConfig.OwnerTitle.DriftSeconds) % 1)
		if stripRainbow.Enabled then
			stripRainbow.Color = colours
		end
		if showingTitles then
			for _, r in ipairs(titleRows) do
				if r.rainbow then
					r.rainbow.Color = colours
				end
			end
		end
	end)
end

--==============================================================================
-- THE SERVER'S QUOTE, AND THE TWO PRESSES
--==============================================================================
local quote: { [string]: any }? = nil
local armedUntil = 0
local waiting = false
local remote: RemoteEvent? = nil

local function paintButton()
	local q = quote
	if waiting then
		button.set("...")
		button.style("off")
	elseif q and q.ok and os.clock() < armedUntil then
		button.set(WORDS.Confirm)
		button.style("danger")
	else
		button.set(WORDS.Button)
		button.style(if q and q.ok then "go" else "off")
	end
end

local function fill(q: { [string]: any })
	local n = Rebirth.count(q.rebirths)
	-- The strip.
	-- Each title with its numeral: every rebirth reads new.
	local nowText, now = Rebirth.titleFor(n)
	local nextText, nextTitle = Rebirth.titleFor(n + 1)
	stripNow.Text = if nowText then string.format(WORDS.Strip, n, nowText) else WORDS.NotYet
	stripNow.TextColor3 = if now and not now.Rainbow then now.Colour else WHITE
	stripRainbow.Enabled = now ~= nil and now.Rainbow == true
	stripNext.Text = string.format(WORDS.NextStrip, n + 1, nextText or "")
	-- The bonus, now -> next.
	trainingStep.Text = string.format(WORDS.Step, Rebirth.times(tonumber(q.training) or 1),
		Rebirth.times(tonumber(q.nextTraining) or 1))
	incomeStep.Text = string.format(WORDS.Step, Rebirth.times(tonumber(q.income) or 1),
		Rebirth.times(tonumber(q.nextIncome) or 1))
	-- The requirements.
	local cost = tonumber(q.price) or 0
	local cash = tonumber(q.cash) or 0
	local rich = cash >= cost
	cashTick.Text = if rich then "✓" else "✖"
	cashTick.TextColor3 = if rich then GOOD else BAD
	cashFill.Size = UDim2.fromScale(if cost > 0 then math.clamp(cash / cost, 0, 1) else 1, 1)
	cashFill.BackgroundColor3 = if rich then GOOD else Color3.fromRGB(255, 176, 60)
	cashText.Text = string.format(WORDS.CashBar, "$" .. GameConfig.money(cash), "$" .. GameConfig.money(cost))
	local milled = (tonumber(q.millTier) or 0) >= (tonumber(q.minTier) or 0)
	millTick.Text = if milled then "✓" else "✖"
	millTick.TextColor3 = if milled then GOOD else BAD
	millWords.Text = string.format(WORDS.MillLine, tostring(q.millName), tonumber(q.millTier) or 1,
		tostring(q.minName), tonumber(q.minTier) or CFG.MinMillTier)
	-- What the next rebirth unlocks.
	fenceLine.Text = string.format(WORDS.FenceLine, Rebirth.fence(n + 1).style.Says)
	titleLine.Text = string.format(WORDS.TitleLine, nextText or "")
	titleLine.TextColor3 = if nextTitle and not nextTitle.Rainbow then nextTitle.Colour else WHITE
	status.Text = if type(q.words) == "string" then q.words else ""
	paintButton()
end

local open = false
local relayout: () -> ()

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		-- Escape and Backspace only while open (a lasting binding on Escape
		-- would eat the Roblox menu). B is PadFocus's: it clears OpenPanel.
		ContextActionService:BindActionAtPriority(CLOSE_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin then
				setOpen(false)
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace)
		local q = quote
		buildPictures(if q then Rebirth.count(q.rebirths) else 0)
		setTurning(true)
		-- Every open starts at the top of the body: the title strip first.
		scroll.CanvasPosition = Vector2.new()
	else
		armedUntil = 0
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		ContextActionService:UnbindAction(CLOSE_ACTION)
		setTurning(false)
		clearPictures()
		-- The next open starts on the body, not where this one left off.
		showTitles(false)
	end
	relayout()
	modal.setOpen(want)
end

modal.close.Activated:Connect(function()
	setOpen(false)
end)
help.Activated:Connect(function()
	if not open then
		return
	end
	local q = quote
	SoundKit.play("UIClick")
	showTitles(not showingTitles, if q then Rebirth.count(q.rebirths) else 0)
end)
back.hit.Activated:Connect(function()
	SoundKit.play("UIClick")
	showTitles(false)
end)

button.hit.Activated:Connect(function()
	local q = quote
	if not (open and q and q.ok) or waiting then
		return
	end
	if os.clock() < armedUntil then
		-- The second press: the token goes back, and the server decides.
		local r = remote
		if r then
			waiting = true
			armedUntil = 0
			r:FireServer(CFG.Action, "confirm", { token = q.token })
		end
	else
		armedUntil = os.clock() + ARMED_SECONDS
		SoundKit.play("UIClick")
		task.delay(ARMED_SECONDS + 0.05, paintButton)
	end
	paintButton()
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)

local function onAnswer(payload: { [string]: any })
	local verb = payload.verb
	if verb == "quote" then
		-- Never over this player's own celebration (the shrine's prompt stands
		-- right there): it is over in seconds, and a quote then is a cooldown.
		if RebirthFX.celebrating(player.Character) then
			return
		end
		quote = payload
		waiting = false
		armedUntil = 0
		fill(payload)
		if open then
			-- A fresh quote while open: the pictures follow the count.
			buildPictures(Rebirth.count(payload.rebirths))
		end
		setOpen(true)
	elseif verb == "refused" then
		waiting = false
		armedUntil = 0
		status.Text = if type(payload.words) == "string" then payload.words else ""
		local q = quote
		if q then
			-- What the server said no to is not a quote to press again.
			q.ok = false
		end
		paintButton()
		SoundKit.play("Denied")
	elseif verb == "done" then
		waiting = false
		quote = nil
		setOpen(false)
		local n = Rebirth.count(payload.rebirths)
		-- THE CELEBRATION (2026-10-09, Shared/RebirthFX): the spin, the light,
		-- the REBORN! card and the fanfare, in place of a notice. With no body
		-- to celebrate round, the notice says it.
		local character = player.Character
		local shown = if character
			then RebirthFX.play({
				character = character,
				own = true,
				rebirths = n,
				training = tonumber(payload.training),
				income = tonumber(payload.income),
			})
			else nil
		if not shown then
			SoundKit.play("NoticeSuccess")
			Notice.post({
				kind = "success",
				title = string.format(WORDS.Done, n),
				detail = string.format(WORDS.DoneDetail, Rebirth.times(tonumber(payload.training) or 1),
					Rebirth.times(tonumber(payload.income) or 1)),
			})
		end
	elseif verb == "celebrate" then
		-- Somebody near was reborn (RebirthService.Celebrate): the column, the
		-- orbs and the burst round THEIR body, the fanfare from it.
		local who = if type(payload.userId) == "number" then Players:GetPlayerByUserId(payload.userId) else nil
		local character = who and who.Character
		if character then
			RebirthFX.play({ character = character, own = false, rebirths = Rebirth.count(payload.rebirths) })
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

-- The faint aura round every body with Celebration.Aura.From rebirths or more,
-- on this screen (RebirthFX; off for REDUCED FX).
RebirthFX.watchAuras()

-- Walked away: the panel shuts (the server would refuse from there anyway).
task.spawn(function()
	while gui.Parent do
		if open then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not (root and root:IsA("BasePart"))
				or (root.Position - (CFG.Position + Vector3.new(0, 5.3, 0))).Magnitude > CFG.CloseDistance then
				setOpen(false)
			end
		end
		task.wait(0.5)
	end
end)

--==============================================================================
-- THE LAYOUT, laid out afresh on every open (UpdateLogUI's order): two columns
-- where both fit side by side, otherwise one column that scrolls
--==============================================================================
local wide = false
local function placeColumns()
	local k = UIKit.scaleOf(gui)
	local w = scroll.AbsoluteSize.X / k
	local leftH = leftList.AbsoluteContentSize.Y / k
	local rightH = rightList.AbsoluteContentSize.Y / k
	local inner = w - scroll.ScrollBarThickness - 4
	if wide then
		local half = (inner - GAP) * 0.5
		left.Position = UDim2.fromOffset(0, 0)
		left.Size = UDim2.fromOffset(half, leftH)
		right.Position = UDim2.fromOffset(half + GAP, 0)
		right.Size = UDim2.fromOffset(half, rightH)
		scroll.CanvasSize = UDim2.fromOffset(0, math.max(leftH, rightH) + 4)
	else
		left.Position = UDim2.fromOffset(0, 0)
		left.Size = UDim2.fromOffset(inner, leftH)
		right.Position = UDim2.fromOffset(0, leftH + GAP)
		right.Size = UDim2.fromOffset(inner, rightH)
		scroll.CanvasSize = UDim2.fromOffset(0, leftH + GAP + rightH + 4)
	end
end
leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(placeColumns)
rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(placeColumns)
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeColumns)

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
	-- Rebirth.layout is the one answer, checked on every listed phone by
	-- RebirthSpec: the foot (reason and button) pinned under the scroll.
	local L = Rebirth.layout({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.
		fill = math.min(1, k),
	} :: any, RAIL.OutlineThickness)
	menu.place(L.panel)
	wide = L.wide
	scroll.Position = UDim2.fromOffset(L.scroll.x, L.scroll.y)
	scroll.Size = UDim2.fromOffset(L.scroll.w, L.scroll.h)
	foot.Position = UDim2.fromOffset(L.foot.x, L.foot.y)
	foot.Size = UDim2.fromOffset(L.foot.w, L.foot.h)
	button.hit.Position = UDim2.fromOffset(L.button.x - L.foot.x + L.button.w * 0.5, L.button.y - L.foot.y)
	button.hit.Size = UDim2.fromOffset(L.button.w, L.button.h)
	-- The TITLES view over the same body: BACK, its heading beside it, the list.
	titlesView.Position = UDim2.new()
	titlesView.Size = UDim2.fromScale(1, 1)
	back.hit.Position = UDim2.fromOffset(L.back.x, L.back.y)
	back.hit.Size = UDim2.fromOffset(L.back.w, L.back.h)
	titlesHeading.Position = UDim2.fromOffset(L.back.x + L.back.w + 12, L.back.y)
	titlesHeading.Size = UDim2.fromOffset(math.max(0, L.list.w - L.back.w - 12), L.back.h)
	list.Position = UDim2.fromOffset(L.list.x, L.list.y)
	list.Size = UDim2.fromOffset(L.list.w, L.list.h)
	placeColumns()
	UIKit.coverRail(playerGui, PANEL_NAME, open and L.panel.covers)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if open then
		relayout()
	end
end)
gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	ContextActionService:UnbindAction(CLOSE_ACTION)
	setTurning(false)
	clearPictures()
end)
relayout()
