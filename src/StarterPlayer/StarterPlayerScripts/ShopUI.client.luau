--!strict
-- Steal a Seed :: ShopUI
--
-- The shop. Its button is on the left rail under the Index; the panel opens in
-- the middle of the screen.
--
--==============================================================================
-- THE SHAPE CAME FROM THREE REFERENCE SHOTS. THE SKIN DID NOT.
--
-- `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` in the repo root. What was
-- taken from them is the LAYOUT -- a very dark panel with a thick black outline,
-- a title bar with an icon and a red X, coloured section headings so a long shop
-- reads as shelves rather than one wall, and cards that are an illustration over
-- a line of outlined text over a price button.
--
-- What was NOT taken is the palette. The cards were sampled cyan-to-blue with a
-- lime button, faithfully, and a cyan tile is another simulator's shelf: it sat
-- two panels away from an Index full of Greenhollow greens and creams and made
-- one HUD look like two games. Cards are green with an amber button now, the
-- plot art is drawn in the biome's own stem, leaf and soil, and the type is
-- LuckiestGuy like the rest of the screen. See GameConfig.Shop.
--
--==============================================================================
-- THE LATTICE, NOT STUDS
--
-- The panel was studded for a while -- Rule 8 is blocky studded plastic, and a
-- studded panel said that in our own accent. It is a diamond lattice now for one
-- reason: the rail buttons carry a lattice, and a panel textured one way opening
-- off a button textured another is two surfaces pretending not to be related.
--
-- One builder in UIKit draws all of it -- rail slab, panel, buy button -- so the
-- diamonds are the same size and the same angle wherever they turn up. Held far
-- back on the panel: there are cards sitting on this and texture must never
-- compete with them.
--
--==============================================================================
-- ONE CENTRE PANEL AT A TIME
--
-- The Index, the Garden and this all open in the same rectangle now, so all
-- three are in the mutex. Rather than have any script reach into another's
-- ScreenGui, each writes its own name to the OpenPanel attribute and closes on
-- seeing a name that is not its own.
--
-- The Garden used to be excluded, on the grounds that it docked on the RIGHT
-- rail and could never overlap these two. That was true of a docked panel and is
-- not true of a modal.
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

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP = GameConfig.Shop
local ATTR = GameConfig.Attributes
local PANEL_NAME = "Shop"

local RAIL = GameConfig.Rail
local WHITE = Color3.fromRGB(255, 255, 255)
--==============================================================================
-- THE PANEL OPENS IN THE MIDDLE NOW
--
-- It used to slide in from x = -width and dock under the rail at a fixed
-- PANEL_TOP. Three panels doing that on two opposite edges is three mental
-- models of one interaction, and a docked panel is either unreadably narrow on a
-- phone or the whole screen anyway. UIKit.modal owns the geometry; this is only
-- the cap it may grow to.
--==============================================================================
local MAX_WIDTH = 460
local MAX_HEIGHT = 560

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

--==============================================================================
-- LUCKIESTGUY, NOT GOTHAM
--
-- This used to build GothamBlack, with a comment saying the reference's shop
-- text has no slant to it. True of the reference and wrong for this HUD: the
-- corner cash readout is LuckiestGuy, so a shop in Gotham made two thirds of the
-- screen look like two different applications. Matching another game's font
-- choice is not the goal -- looking like ONE game is.
--
-- One helper, in UIKit, so the Index cards, these prices and the Garden rows
-- cannot drift apart again.
--==============================================================================
local function outlined(parent: Instance, size: number, colour: Color3,
	thickness: number): TextLabel
	return UIKit.outlined(parent, "Label", size, colour, thickness)
end

--==============================================================================
-- THE RAIL BUTTON
--
-- Green slab, a cart, and the word. It was a crop of `shop index.png` for a day
-- -- black outline clipped on both sides, "Shop" baked into the PNG -- and it is
-- instances again. The red toolbox that used to sit in the panel's title bar
-- went with it: the rail says CART, so the panel says cart too, because two
-- icons for one shop is how a player learns there are two shops.
--
-- Positioned off the Index slab's real height rather than a typed 68, so the two
-- cannot drift apart when either is resized.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "ShopButton",
	face = RAIL.ShopFace,
	shade = RAIL.ShopShade,
	label = "Shop",
	wide = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset + RAIL.WideSize.Y + RAIL.Gap)
UIKit.cartIcon(button, RAIL.IconSize, RAIL.ShopShade)

--==============================================================================
-- THE PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "SHOP",
	maxWidth = MAX_WIDTH,
	maxHeight = MAX_HEIGHT,
})

local titleBar = modal.title.Parent :: Frame
UIKit.cartIcon(titleBar, 30, SHOP.CardBorder)
modal.title.Position = UDim2.new(0, 46, 0.5, 0)
modal.title.Size = UDim2.new(1, -98, 1, 0)

local close = modal.close

--==============================================================================
-- THE BODY
--==============================================================================
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Size = UDim2.fromScale(1, 1)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = GameConfig.Panel.Edge
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ZIndex = 3
body.Parent = modal.body

local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingBottom = UDim.new(0, 12)
bodyPad.Parent = body

local bodyList = Instance.new("UIListLayout")
bodyList.FillDirection = Enum.FillDirection.Vertical
bodyList.SortOrder = Enum.SortOrder.LayoutOrder
bodyList.Padding = UDim.new(0, 10)
bodyList.Parent = body

--==============================================================================
-- SECTIONS AND CARDS
--==============================================================================
--==============================================================================
-- THE CARDS ARE MEASURED, NOT TYPED
--
-- The panel used to be exactly 430 wide, so a card could be a constant. A modal
-- is a fraction of the screen with a cap, and the same script now has to lay out
-- at 248 pixels and at 460 -- so every shelf sizes its cells off the body it is
-- in and re-sizes them when the screen turns.
--==============================================================================
local GUTTER = 10
local CARD_ASPECT = 1.30

local shelves: { UIGridLayout } = {}

local function relayout()
	local width = body.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local columns = if width >= 400 then 3 else 2
	local cell = math.floor((width - GUTTER * (columns - 1) - 6) / columns)
	for _, grid in ipairs(shelves) do
		grid.CellSize = UDim2.fromOffset(cell, math.floor(cell * CARD_ASPECT))
		grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)
	end
end

-- Height the panel to whatever the shelves add up to. Read off the layout
-- rather than counted here, because one shelf today is three shelves later and
-- a sum written twice is a sum that disagrees with itself.
local function fit()
	modal.fitContent(bodyList.AbsoluteContentSize.Y + 12)
end

local function section(order: number, heading: string, colour: Color3): Frame
	local header = outlined(body, 22, colour, 3)
	header.Name = heading .. "Header"
	header.LayoutOrder = order
	header.Size = UDim2.new(1, 0, 0, 32)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = heading

	local shelf = Instance.new("Frame")
	shelf.Name = heading
	shelf.LayoutOrder = order + 1
	shelf.Size = UDim2.new(1, 0, 0, 0)
	shelf.AutomaticSize = Enum.AutomaticSize.Y
	shelf.BackgroundTransparency = 1
	shelf.ZIndex = 3
	shelf.Parent = body

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(140, 182)
	grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = shelf
	table.insert(shelves, grid)

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

	-- Scale, not offset: the cell is measured off the panel now, so a card laid
	-- out at 248 pixels and one at 460 have to fill themselves the same way.
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0.04, 0)
	art.Size = UDim2.new(0.84, 0, 0.44, 0)
	art.BackgroundTransparency = 1
	art.Parent = fill

	local titleLabel = outlined(fill, 19, WHITE, 3)
	titleLabel.Name = "Title"
	titleLabel.Position = UDim2.new(0, 0, 0.52, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 26)

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 1, -9)
	buy.Size = UDim2.new(1, -18, 0, 34)
	buy.BackgroundColor3 = SHOP.Buy
	buy.BorderSizePixel = 0
	buy.AutoButtonColor = false
	buy.Text = ""
	buy.Parent = fill
	corner(buy, 8)
	stroke(buy, SHOP.Outline, 3)
	-- The same lattice as the rail slab and the panel behind it, at the button's
	-- own tighter pitch. Three surfaces, one texture, one angle.
	UIKit.lattice(buy, {
		spacing = 16,
		thickness = 2,
		transparency = 0.84,
		inset = 3,
	})

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
-- Soil with sprouts standing in it, and the row count is what the card sells so
-- the art says it too.
--
-- IN THE BIOME'S OWN COLOURS. This used to be rgb(96,66,48) dirt with
-- rgb(124,182,92) stems picked to sit on a cyan tile -- one of them happened to
-- be the real stem colour and the other two did not. They come off SeedData now,
-- which is the same stem, leaf and soil every Greenhollow plant shares and the
-- same three the Index portraits are drawn in. A shop selling dirt should be
-- selling THIS game's dirt.
--==============================================================================
local function plotArt(parent: Frame, sprouts: number)
	for _, existingChild in ipairs(parent:GetChildren()) do
		existingChild:Destroy()
	end

	-- A heap with a peak, not a plank. The first pass drew one thin bar and the
	-- sprouts read as lollipops standing on a shelf.
	local bed = UIKit.piece(parent, "Bed", 0.5, 0.80, 0.88, 0.32,
		SeedData.Soil, 0.30, nil, 3)
	stroke(bed, SHOP.Outline, 2)
	for _, clod in ipairs({ { 0.20, 0.84, 0.28, 0.24 }, { 0.80, 0.85, 0.26, 0.22 } }) do
		local lump = UIKit.piece(parent, "Clod", clod[1], clod[2], clod[3], clod[4],
			SeedData.Soil, 0.5, nil, 3)
		stroke(lump, SHOP.Outline, 2)
	end

	--==========================================================================
	-- OUTLINED, BECAUSE THE CARD IS GREEN NOW
	--
	-- These sprouts were legible on a cyan tile without any help. On the green
	-- card that replaced it they are green on green, and the black edge is the
	-- only thing separating them -- which is what every illustration in the
	-- reference does anyway.
	--==========================================================================
	for i = 1, sprouts do
		local x = 0.16 + (0.68 * (i - 0.5) / sprouts)
		local stem = UIKit.piece(parent, "Stem" .. i, x, 0.55, 0.055, 0.44,
			SeedData.Stem, 0.3, nil, 4)
		stroke(stem, SHOP.Outline, 2)
		for _, side in ipairs({ -1, 1 }) do
			local leaf = UIKit.piece(parent, "Leaf" .. i, x + side * 0.062, 0.50,
				0.12, 0.16, SeedData.Leaf, 0.5, side * 30, 5)
			stroke(leaf, SHOP.Outline, 2)
		end
		local bud = UIKit.piece(parent, "Bud" .. i, x, 0.27, 0.14, 0.24,
			SeedData.Species[1].Body, 0.5, nil, 5)
		stroke(bud, SHOP.Outline, 2)
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

-- Every shelf exists now, so the cells can be measured. Bound to the body rather
-- than fired once: a phone that turns sideways is a resize, not a rebuild.
body:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
bodyList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
relayout()
fit()

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
--
-- ONE CENTRE PANEL AT A TIME, and the Garden is in the mutex now. It used to be
-- excluded because it docked on the RIGHT rail and could not overlap these two;
-- all three open in the same rectangle now, so all three have to take turns.
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	modal.setOpen(want)
end

button.Activated:Connect(function()
	setOpen(not open)
end)
close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)
