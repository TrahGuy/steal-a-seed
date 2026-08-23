--!strict
-- Steal a Seed :: ShopUI
--
-- The shop panel, on the left rail under the Index.
--
--==============================================================================
-- BUILT FROM THREE REFERENCE SHOTS, SAMPLED NOT EYEBALLED
--
-- `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` in the repo root. Every
-- colour is in GameConfig.Shop and every one of them came out of those files
-- with a pixel sampler. The shape borrowed from them:
--
--   * a very dark panel with a thick black outline and a faint texture
--   * a title bar: an icon, SHOP in heavy white with a black outline, and a red
--     X in the far corner
--   * coloured section headings, each a different colour, so a long shop reads
--     as a list of shelves rather than one wall
--   * cards: a vertical gradient inside a coloured border, an illustration, a
--     line of white outlined text, and a bright green price button
--
--==============================================================================
-- STUDDED, WHICH THE REFERENCE IS NOT
--
-- The reference panel carries a faint diagonal lattice -- measured at about five
-- units of luminance spread, barely there at all. The owner asked for STUDDED
-- instead, and it is the better call for this game: Rule 8 is blocky studded
-- plastic, and a studded panel says the same thing in our own accent.
--
-- Held at the reference's contrast on purpose. Studs are `rgb(52,56,76)` on a
-- `rgb(26,28,41)` panel at 0.82 transparency -- any louder and the texture
-- competes with the cards sitting on it, which is the one thing a shop panel
-- must never do.
--
-- Drawn as a grid of frames rather than a tiled image, because nothing in this
-- repo is placed by hand and there is no asset id to rot. Two hundred-odd static
-- frames, built once at login, never touched again and not rendered at all while
-- the panel is shut.
--
--==============================================================================
-- TWO LEFT PANELS CANNOT BOTH BE OPEN
--
-- The Index and this dock on the same edge at the same size, so they share one
-- rectangle. Rather than have either script reach into the other's ScreenGui,
-- both write their own name to the OpenPanel attribute and both close on seeing
-- a name that is not theirs.
--
-- The GARDEN is deliberately outside that arrangement: it is on the right rail,
-- it never overlaps either of these, and reading your own dirt while looking at
-- a price is exactly what two rails are for.
--
--==============================================================================
-- NOTHING IS BUYABLE YET, AND THE BUTTONS SAY SO
--
-- This is the UI. There is no ShopService, no purchase remote and no cash
-- deduction, so a price button renders its state and does not transact. That is
-- deliberate rather than unfinished: taking money needs a server that owns the
-- decision (Rule 3), and a plot tier in particular is not buyable until
-- PlotService can rebuild a bed at a new row count -- today every plot is tier 1
-- and nothing changes that.
--
-- A button that silently did nothing would be the lie. These read SOON.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP = GameConfig.Shop
local ATTR = GameConfig.Attributes
local PANEL_NAME = "Shop"

local WHITE = Color3.fromRGB(255, 255, 255)
local PANEL_WIDTH = 430
-- Below BOTH left-rail buttons: the Index sits at y = 12 and this one at y = 68,
-- each 46 tall, so 124 clears the pair and neither button is ever covered by the
-- panel it opened.
local PANEL_TOP = 124
local SLIDE = 0.22
local CARD_COLUMNS = 2

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedShop")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedShop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 32
gui.Parent = playerGui

--==============================================================================
-- SMALL BUILDERS
--==============================================================================
local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, colour: Color3, thickness: number,
	transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function gradient(parent: Instance, top: Color3, bottom: Color3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = 90
	g.Parent = parent
	return g
end

-- Heavy white text with a thick black outline, which is every readable string in
-- the reference. Upright, not the HUD's LuckiestGuy: the reference's shop text
-- has no slant to it.
local function outlined(parent: Instance, size: number, colour: Color3,
	thickness: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = size
	label.TextColor3 = colour
	label.Text = ""
	label.Parent = parent
	stroke(label, SHOP.Outline, thickness)
	return label
end

--==============================================================================
-- THE TOOLBOX
--
-- Frames, not a glyph -- the same reason the Index book, the Garden sprout and
-- the HUD sneaker are frames. A red box with a grey handle over it; the handle
-- is an outlined frame with no fill, which is a loop without needing a hole.
--==============================================================================
local function toolbox(parent: Instance, scale: number): Frame
	local box = Instance.new("Frame")
	box.Name = "Toolbox"
	box.BackgroundTransparency = 1
	box.Size = UDim2.fromOffset(math.floor(30 * scale), math.floor(30 * scale))
	box.Parent = parent

	local handle = Instance.new("Frame")
	handle.Name = "Handle"
	handle.AnchorPoint = Vector2.new(0.5, 0)
	handle.Position = UDim2.new(0.5, 0, 0, 0)
	handle.Size = UDim2.fromOffset(math.floor(16 * scale), math.floor(13 * scale))
	handle.BackgroundTransparency = 1
	handle.Parent = box
	corner(handle, math.max(2, math.floor(4 * scale)))
	stroke(handle, Color3.fromRGB(150, 152, 160), math.max(2, 3 * scale))

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.AnchorPoint = Vector2.new(0.5, 1)
	body.Position = UDim2.new(0.5, 0, 1, 0)
	body.Size = UDim2.fromOffset(math.floor(28 * scale), math.floor(18 * scale))
	body.BackgroundColor3 = Color3.fromRGB(226, 32, 32)
	body.BorderSizePixel = 0
	body.Parent = box
	corner(body, math.max(2, math.floor(4 * scale)))
	stroke(body, SHOP.Outline, math.max(2, 2 * scale))

	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.AnchorPoint = Vector2.new(0.5, 0)
	lip.Position = UDim2.new(0.5, 0, 0, 0)
	lip.Size = UDim2.new(1, math.floor(4 * scale), 0, math.floor(6 * scale))
	lip.BackgroundColor3 = Color3.fromRGB(248, 66, 66)
	lip.BorderSizePixel = 0
	lip.ZIndex = 2
	lip.Parent = body
	corner(lip, math.max(2, math.floor(3 * scale)))

	return box
end

--==============================================================================
-- THE RAIL BUTTON
--==============================================================================
local button = UIKit.railButton(gui, 152, 46)
button.Name = "ShopButton"
button.Position = UDim2.new(0, 12, 0, 68)

local railIcon = toolbox(button, 1)
railIcon.AnchorPoint = Vector2.new(0, 0.5)
railIcon.Position = UDim2.new(0, 11, 0.5, 0)

local railLabel = outlined(button, 18, WHITE, 2)
railLabel.Name = "Label"
railLabel.Position = UDim2.fromOffset(48, 0)
railLabel.Size = UDim2.new(1, -58, 1, 0)
railLabel.TextXAlignment = Enum.TextXAlignment.Left
railLabel.Text = "Shop"

--==============================================================================
-- THE PANEL
--==============================================================================
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.new(0, -PANEL_WIDTH - 30, 0, PANEL_TOP)
panel.Size = UDim2.new(0, PANEL_WIDTH, 1, -(PANEL_TOP + 14))
panel.BackgroundColor3 = SHOP.Panel
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = gui
corner(panel, 16)
stroke(panel, SHOP.Outline, 3)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(PANEL_WIDTH, 260)
panelSize.MaxSize = Vector2.new(PANEL_WIDTH, 620)
panelSize.Parent = panel

--==============================================================================
-- THE STUDS
--
-- Sized for the panel's MAXIMUM height and clipped by the panel, so a short
-- screen simply shows fewer of them and nothing has to be rebuilt on a resize.
--==============================================================================
-- Same builder the rail buttons use, at the panel's own coarser pitch. The
-- panel already clips, and the grid is sized for its MAXIMUM height so a short
-- screen just shows fewer studs.
UIKit.studs(panel, PANEL_WIDTH, panelSize.MaxSize.Y,
	SHOP.StudPitch, SHOP.StudSize, SHOP.Stud, 0.82)

--==============================================================================
-- THE TITLE BAR
--==============================================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundTransparency = 1
titleBar.Parent = panel

local titleIcon = toolbox(titleBar, 1.25)
titleIcon.AnchorPoint = Vector2.new(0, 0.5)
titleIcon.Position = UDim2.new(0, 14, 0.5, 0)

local title = outlined(titleBar, 30, SHOP.Title, 3)
title.Name = "Title"
title.Position = UDim2.fromOffset(60, 0)
title.Size = UDim2.new(1, -130, 1, 0)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "SHOP"

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -14, 0.5, 0)
close.Size = UDim2.fromOffset(38, 38)
close.BackgroundColor3 = SHOP.Close
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Font = Enum.Font.GothamBlack
close.TextSize = 22
close.TextColor3 = WHITE
close.Text = "X"
close.Parent = titleBar
corner(close, 9)
-- One stroke. It outlines the red square AND the X inside it, because a UIStroke
-- on a TextButton does both.
stroke(close, SHOP.Outline, 3)

--==============================================================================
-- THE BODY
--==============================================================================
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Position = UDim2.fromOffset(0, 52)
body.Size = UDim2.new(1, 0, 1, -52)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = SHOP.PanelEdge
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel

local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft = UDim.new(0, 14)
bodyPad.PaddingRight = UDim.new(0, 14)
bodyPad.PaddingBottom = UDim.new(0, 14)
bodyPad.Parent = body

local bodyList = Instance.new("UIListLayout")
bodyList.FillDirection = Enum.FillDirection.Vertical
bodyList.SortOrder = Enum.SortOrder.LayoutOrder
bodyList.Padding = UDim.new(0, 10)
bodyList.Parent = body

--==============================================================================
-- SECTIONS AND CARDS
--==============================================================================
local CARD_WIDTH = math.floor((PANEL_WIDTH - 28 - 10 - 6) / CARD_COLUMNS)
local CARD_HEIGHT = 186

local function section(order: number, heading: string, colour: Color3): Frame
	local header = outlined(body, 22, colour, 3)
	header.Name = heading .. "Header"
	header.LayoutOrder = order
	header.Size = UDim2.new(1, 0, 0, 32)
	header.Text = heading

	local shelf = Instance.new("Frame")
	shelf.Name = heading
	shelf.LayoutOrder = order + 1
	shelf.Size = UDim2.new(1, 0, 0, 0)
	shelf.AutomaticSize = Enum.AutomaticSize.Y
	shelf.BackgroundTransparency = 1
	shelf.Parent = body

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = shelf

	return shelf
end

type Card = {
	frame: Frame,
	fill: Frame,
	-- Held so paint() can RECOLOUR it. Calling gradient() again per repaint
	-- would parent a fresh UIGradient every time the profile packet lands --
	-- four a second, forever, on a panel that is usually shut.
	tint: UIGradient,
	art: Frame,
	title: TextLabel,
	price: TextLabel,
	buy: TextButton,
}

local function buildCard(parent: Instance, order: number): Card
	local frame = Instance.new("Frame")
	frame.Name = "Card" .. order
	frame.LayoutOrder = order
	frame.BackgroundColor3 = SHOP.CardBorder
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, 14)
	stroke(frame, SHOP.Outline, 3)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Position = UDim2.fromOffset(5, 5)
	fill.Size = UDim2.new(1, -10, 1, -10)
	fill.BackgroundColor3 = WHITE
	fill.BorderSizePixel = 0
	fill.Parent = frame
	corner(fill, 10)
	local tint = gradient(fill, SHOP.CardTop, SHOP.CardBottom)

	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0, 10)
	art.Size = UDim2.fromOffset(96, 68)
	art.BackgroundTransparency = 1
	art.Parent = fill

	local titleLabel = outlined(fill, 19, WHITE, 3)
	titleLabel.Name = "Title"
	titleLabel.Position = UDim2.fromOffset(0, 84)
	titleLabel.Size = UDim2.new(1, 0, 0, 26)

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 1, -10)
	buy.Size = UDim2.new(1, -20, 0, 34)
	buy.BackgroundColor3 = SHOP.Buy
	buy.BorderSizePixel = 0
	buy.AutoButtonColor = false
	buy.Text = ""
	buy.Parent = fill
	corner(buy, 8)
	stroke(buy, SHOP.Outline, 3)

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.AnchorPoint = Vector2.new(0.5, 1)
	shade.Position = UDim2.new(0.5, 0, 1, 0)
	shade.Size = UDim2.new(1, 0, 0, 7)
	shade.BackgroundColor3 = SHOP.BuyShade
	shade.BorderSizePixel = 0
	shade.Parent = buy
	corner(shade, 8)

	local price = outlined(buy, 17, WHITE, 2)
	price.Name = "Price"
	price.Size = UDim2.fromScale(1, 1)
	price.ZIndex = 2

	return {
		frame = frame,
		fill = fill,
		tint = tint,
		art = art,
		title = titleLabel,
		price = price,
		buy = buy,
	}
end

--==============================================================================
-- A PLOT, DRAWN SMALL
--
-- Soil with sprouts standing in it. Frames again, and the row count is what the
-- card is selling, so the art says it too.
--==============================================================================
local function plotArt(parent: Frame, sprouts: number)
	for _, existingChild in ipairs(parent:GetChildren()) do
		existingChild:Destroy()
	end

	local soil = Instance.new("Frame")
	soil.Name = "Soil"
	soil.AnchorPoint = Vector2.new(0.5, 1)
	soil.Position = UDim2.new(0.5, 0, 1, -4)
	soil.Size = UDim2.fromOffset(88, 22)
	soil.BackgroundColor3 = Color3.fromRGB(96, 66, 48)
	soil.BorderSizePixel = 0
	soil.Parent = parent
	corner(soil, 6)
	stroke(soil, SHOP.Outline, 2)

	local spacing = 84 / (sprouts + 1)
	for i = 1, sprouts do
		local stem = Instance.new("Frame")
		stem.Name = "Stem" .. i
		stem.AnchorPoint = Vector2.new(0.5, 1)
		stem.Position = UDim2.new(0, math.floor(6 + spacing * i), 1, -22)
		stem.Size = UDim2.fromOffset(5, 20)
		stem.BackgroundColor3 = Color3.fromRGB(124, 182, 92)
		stem.BorderSizePixel = 0
		stem.Parent = parent
		corner(stem, 2)
		stroke(stem, SHOP.Outline, 2)

		local head = Instance.new("Frame")
		head.Name = "Head" .. i
		head.AnchorPoint = Vector2.new(0.5, 1)
		head.Position = UDim2.new(0, math.floor(6 + spacing * i), 1, -38)
		head.Size = UDim2.fromOffset(16, 16)
		head.BackgroundColor3 = Color3.fromRGB(146, 196, 106)
		head.BorderSizePixel = 0
		head.Parent = parent
		corner(head, 8)
		stroke(head, SHOP.Outline, 2)
	end
end

--==============================================================================
-- THE PLOT SHELF
--
-- One card per tier above the one you start on. Tier 1 is where everybody
-- begins, so it is not for sale and is not shown.
--==============================================================================
local plotShelf = section(1, "PLOT", SHOP.Heading)
local plotCards: { Card } = {}

for tier = 2, #GameConfig.PlotTiers do
	local card = buildCard(plotShelf, tier)
	plotCards[tier] = card
	local rows = GameConfig.PlotTiers[tier].rows
	plotArt(card.art, math.min(4, tier))
	card.title.Text = string.format("%d SLOTS", GameConfig.plotSlotsFor(rows))
end

--==============================================================================
-- WHAT THE CARDS SAY, GIVEN WHERE THE PLAYER IS
--==============================================================================
local plotTier = GameConfig.StartingPlotTier
local cash = 0
local heardFromServer = false

local function paint()
	for tier = 2, #GameConfig.PlotTiers do
		local card = plotCards[tier]
		if card then
			local cost = GameConfig.PlotTiers[tier].cost or 0
			local owned = plotTier >= tier
			local next_ = plotTier == tier - 1

			if owned then
				-- Already yours: the card stays legible but stops competing for
				-- attention with the one you could actually buy.
				card.tint.Color = ColorSequence.new(SHOP.SoldTop, SHOP.SoldBottom)
				card.frame.BackgroundColor3 = SHOP.SoldBottom
				card.buy.BackgroundColor3 = SHOP.BuyShade
				card.price.Text = "OWNED"
			else
				card.tint.Color = ColorSequence.new(SHOP.CardTop, SHOP.CardBottom)
				card.frame.BackgroundColor3 = SHOP.CardBorder
				card.buy.BackgroundColor3 = if next_ then SHOP.Buy else SHOP.Locked
				--==========================================================
				-- SOON, NOT A DEAD BUTTON
				--
				-- There is no ShopService yet, so nothing here can take the
				-- money. Saying SOON is the honest version of that; a button
				-- reading a price and doing nothing when pressed is not.
				--==========================================================
				card.price.Text = if heardFromServer and cash >= cost
					then "SOON  ·  $" .. GameConfig.compact(cost)
					else "$" .. GameConfig.compact(cost)
			end
			card.fill.BackgroundTransparency = if owned or next_ then 0 else 0.25
		end
	end
end

paint()

--==============================================================================
-- THE PROFILE
--
-- PlotTier says which cards are owned, Cash says which one is within reach. No
-- new remote: both ride the ProfileUpdated packet that already arrives four
-- times a second.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local changed = false
	if type(profile.PlotTier) == "number" then
		local tier = math.floor(profile.PlotTier)
		if tier ~= plotTier then
			plotTier = tier
			changed = true
		end
	end
	if type(profile.Cash) == "number" then
		-- Only repaint when it crosses a price, not on every packet.
		for tier = 2, #GameConfig.PlotTiers do
			local cost = GameConfig.PlotTiers[tier].cost or 0
			if (cash >= cost) ~= (profile.Cash >= cost) then
				changed = true
			end
		end
		cash = profile.Cash
	end
	if not heardFromServer then
		heardFromServer = true
		changed = true
	end
	if changed then
		paint()
	end
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	-- WaitForChild, not FindFirstChild: the folder replicates before the events
	-- inside it, which is how CashUI once sat blank for a whole session.
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	else
		warn("[Seed/ShopUI] No ProfileUpdated; the shop will assume a starting plot.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		-- Claim the left rail. Whoever else is holding it closes on this.
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		panel.Visible = true
		panel.Position = UDim2.new(0, -PANEL_WIDTH - 30, 0, PANEL_TOP)
		TweenService:Create(panel, TweenInfo.new(SLIDE, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Position = UDim2.new(0, 12, 0, PANEL_TOP) }):Play()
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		local slideOut = TweenService:Create(panel, TweenInfo.new(SLIDE,
			Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0, -PANEL_WIDTH - 30, 0, PANEL_TOP) })
		slideOut:Play()
		slideOut.Completed:Connect(function()
			if not open then
				panel.Visible = false
			end
		end)
	end
end

button.Activated:Connect(function()
	setOpen(not open)
end)
close.Activated:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)
