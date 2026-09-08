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
-- THE PLOT CARDS TRANSACT. THE OTHER SHELVES STILL DO NOT.
--
-- These read SOON for a long time, because there was no server that owned the
-- decision and a button that took money without one would have been the lie.
-- PlotUpgradeService owns it now, so the plot shelf is live.
--
-- THE CLIENT SENDS A VERB AND NOTHING ELSE -- not the level, not the price.
-- Everything below is presentation: which card looks buyable, what the price
-- line says, whether the button is lit. The server re-derives all of it from
-- the sender before it moves a single coin, so the worst a tampered copy of
-- this file can do is ask for the upgrade it was already entitled to buy.
--
-- Which is also why nothing here writes `plotTier` on click. The card turns
-- OWNED when the profile packet says so and not one frame earlier: the client
-- does not get to decide it succeeded.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

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
-- plotArt was here: the bed-and-sprouts illustration for the plot shelf. The
-- plot ladder is a board by the gate now, so the drawing went with the shelf.

--==============================================================================
-- THE SHELVES
--
-- Built from GameConfig.Store, which is also what the server grants from, so a
-- tile cannot advertise something StoreService does not know how to give.
--
-- There is NO REMOTE in this file any more. A Robux purchase is a prompt to
-- Roblox and a receipt to the server; the client's whole part is asking for the
-- prompt. The plot ladder -- the one thing here that ever sent a verb -- moved
-- to the board by the gate.
--==============================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local STORE = GameConfig.Store

--==============================================================================
-- THE ICONS ARE DRAWN, NOT UPLOADED
--
-- Rule 5: nothing is placed by hand, and that includes art. Four shapes from
-- plain frames, in the shelf's own colour, so a new shelf needs no asset and no
-- upload -- the same reason plotArt was drawn rather than imported.
--==============================================================================
local function chip(parent: Instance, x: number, y: number, w: number, h: number,
	colour: Color3, rot: number?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Rotation = rot or 0
	f.ZIndex = 6
	f.Parent = parent
	UIKit.corner(f, 4)
	return f
end

local function storeArt(parent: Frame, kind: string)
	if kind == "speed" then
		-- Three chevrons leaning forward: the one shape that reads as speed at
		-- forty pixels without a running shoe to draw it on.
		for i = 0, 2 do
			local light = Color3.fromRGB(198, 236, 255):Lerp(Color3.fromRGB(96, 170, 240), i / 2)
			chip(parent, 0.30 + i * 0.20, 0.5, 0.10, 0.62, light, 18)
		end
	elseif kind == "cash" then
		-- A stack of notes, offset so the stack reads as depth.
		for i = 0, 2 do
			chip(parent, 0.5 - i * 0.045, 0.62 - i * 0.13, 0.62, 0.26,
				Color3.fromRGB(122, 200, 96):Lerp(Color3.fromRGB(196, 240, 150), i / 2))
		end
	elseif kind == "pod" then
		-- A shell: a wide base under a narrower crown, which is the pod
		-- silhouette every card in the Index already uses.
		chip(parent, 0.5, 0.62, 0.52, 0.44, Color3.fromRGB(238, 226, 198))
		chip(parent, 0.5, 0.34, 0.38, 0.34, Color3.fromRGB(250, 244, 224))
	else
		-- A sprout: stem and two blades.
		chip(parent, 0.5, 0.66, 0.09, 0.46, Color3.fromRGB(124, 182, 92))
		chip(parent, 0.36, 0.40, 0.30, 0.13, Color3.fromRGB(142, 206, 104), -22)
		chip(parent, 0.64, 0.40, 0.30, 0.13, Color3.fromRGB(142, 206, 104), 22)
	end
end

--==============================================================================
-- ONE SHELF PER SECTION, ONE TILE PER ITEM
--
-- A product with an id of 0 has not been created in the Creator Dashboard yet.
-- Its tile is still DRAWN -- the shelf has to look like a shelf -- but it reads
-- SOON, goes dark, and its button refuses. Filling the id in is the only change
-- needed to make it live.
--==============================================================================
local order = 1
local liveCount, soonCount = 0, 0

for _, spec in ipairs(STORE.Sections) do
	local shelf = section(order, spec.heading, spec.colour)
	order += 2

	local items = STORE.Items[spec.id] or {}
	if #items == 0 then
		--==================================================================
		-- AN EMPTY SHELF STILL SAYS SOMETHING
		--
		-- The owner asked for PLANTS now and the content later. A plate that
		-- says so is a promise; a missing heading is nothing at all.
		--==================================================================
		local card = buildCard(shelf, 1)
		storeArt(card.art, "plant")
		card.title.Text = "COMING SOON"
		card.price.Text = "SOON"
		card.tint.Color = ColorSequence.new(SHOP.SoldTop, SHOP.SoldBottom)
		card.frame.BackgroundColor3 = SHOP.SoldBottom
		card.buy.BackgroundColor3 = SHOP.BuyShade
		card.fill.BackgroundTransparency = 0.25
		card.buy.Activated:Connect(function()
			SoundKit.play("Denied")
		end)
		soonCount += 1
	end

	for index, item in ipairs(items) do
		local card = buildCard(shelf, index)
		storeArt(card.art, tostring(item.kind))
		card.title.Text = item.label

		local productId = tonumber(item.product) or 0
		local live = productId > 0
		if live then
			liveCount += 1
			-- The Robux glyph, then the price. No currency word: the icon is
			-- the currency, the same as the reference shelves.
			card.price.Text = string.format("\u{E002}%d", item.robux)
			card.buy.BackgroundColor3 = SHOP.Buy
			card.fill.BackgroundTransparency = 0
		else
			soonCount += 1
			card.price.Text = "SOON"
			card.tint.Color = ColorSequence.new(SHOP.SoldTop, SHOP.SoldBottom)
			card.frame.BackgroundColor3 = SHOP.SoldBottom
			card.buy.BackgroundColor3 = SHOP.BuyShade
			card.fill.BackgroundTransparency = 0.25
		end

		card.buy.Activated:Connect(function()
			if not live then
				--==========================================================
				-- A BUTTON THAT CANNOT CHARGE SAYS SO
				--
				-- Prompting with a product id of 0 throws, and a thrown error
				-- on a click reads to a player as a broken shop. The refusal
				-- noise is the honest answer until the id exists.
				--==========================================================
				SoundKit.play("Denied")
				return
			end
			--==============================================================
			-- THE CLIENT ASKS FOR THE PROMPT AND NOTHING ELSE
			--
			-- No optimistic paint, no BUYING state, no local grant. What the
			-- player gets is decided by StoreService when Roblox delivers the
			-- receipt, and the profile packet that follows is what updates the
			-- HUD. There is nothing for this side to be optimistic about.
			--==============================================================
			local ok, err = pcall(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)
			if not ok then
				warn("[Seed/ShopUI] could not prompt for " .. item.key .. ": " .. tostring(err))
				SoundKit.play("Denied")
			end
		end)
	end
end

-- Every shelf exists now, so the cells can be measured. Bound to the body rather
-- than fired once: a phone that turns sideways is a resize, not a rebuild.
body:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
bodyList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
relayout()
fit()

if liveCount == 0 then
	warn(string.format(
		"[Seed/ShopUI] Nothing is for sale: %d tile(s) and every product id is 0. "
		.. "Create the Developer Products and fill their ids into GameConfig.Store.",
		soonCount))
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
