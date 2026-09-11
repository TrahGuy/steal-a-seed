--!strict
-- Steal a Seed :: ShopUI
--
-- The shop. Its button is on the left rail under the Index; the panel opens in
-- the middle of the screen.
--
--==============================================================================
-- THE APPROVED RESTYLE, 2026-09-11
--
-- Drawn to the owner's approved mockup (shop_mockup_preview.png), with
-- art/shop/reference/target-shop-reference.png as the look it is after and
-- art/shop/reference/current-shop.png as the soil-brown panel it replaced:
--
--   header   a green banner: "Shop" in white with an ink outline, and a red X
--   body     charcoal slate under a faint lattice, so the tiles are the
--            brightest thing on the panel
--   tiles    one gradient per shelf -- sky blue for speed, grass green for cash,
--            warm gold for passes -- inside a chunky ink keyline
--   type     the amount neon green, or neon gold from 50M up; the noun white;
--            an ink outline on all of it
--   buy      a lime button holding a white capsule with the Robux mark and the
--            price; a SOON button is slate with a dark capsule
--
-- Every colour lives in GameConfig.Shop or GameConfig.Store.Sections. The panel
-- chrome is a UIKit.modal THEME, so the Index, the Garden, the Bag, Settings and
-- Marigold's stall keep the house style.
--
--==============================================================================
-- ONE CENTRE PANEL AT A TIME
--
-- The Index, the Garden and this all open in the same rectangle, so they take
-- turns. Rather than have any script reach into another's ScreenGui, each writes
-- its own name to the OpenPanel attribute and closes on seeing a name that is
-- not its own.
--
--==============================================================================
-- THE CLIENT ONLY EVER ASKS
--
-- A Robux purchase is a prompt to Roblox and a receipt to the server. Nothing in
-- this file grants, charges or remembers anything: StoreService decides what a
-- product gives and PassService what a player owns. Everything here is
-- presentation -- which tile looks buyable, what its price says, whether its
-- button answers.
--==============================================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP = GameConfig.Shop
local STORE = GameConfig.Store
local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local PANEL_NAME = "Shop"

local WHITE = Color3.fromRGB(255, 255, 255)
-- The one dark in the shop: every keyline, every outline, the price on its capsule.
local INK = SHOP.Ink

--==============================================================================
-- THE SHOP PANEL IS WIDER THAN THE OTHERS
--
-- 460 is UIKit's default and right for the Index and the Garden, whose cards are
-- portraits read one at a time. A shop shelf is scanned three across, and at 460
-- the tiles came out cramped. maxWidth is a per-caller option, so this widens the
-- shop and nothing else.
--==============================================================================
local MAX_WIDTH = 620
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

local function stroke(parent: Instance, colour: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.Parent = parent
	return s
end

--==============================================================================
-- LUCKIESTGUY, WITH AN INK OUTLINE
--
-- The house face through UIKit.outlined, so these prices and the Index cards
-- cannot drift into different fonts -- and then the outline is recoloured from
-- pure black to the shop's ink, which is what the mockup draws: a black with a
-- little blue in it, so an outline on charcoal reads as a line, not a hole.
--==============================================================================
local function outlined(parent: Instance, size: number, colour: Color3,
	thickness: number): TextLabel
	local label = UIKit.outlined(parent, "Label", size, colour, thickness)
	local line = label:FindFirstChildOfClass("UIStroke")
	if line then
		line.Color = INK
	end
	return label
end

--==============================================================================
-- THE RAIL BUTTON
--
-- Green slab, a cart, and the word, positioned off the Index slab's real height
-- rather than a typed 68, so the two cannot drift apart when either is resized.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "ShopButton",
	icon = RAIL.ShopIcon,
	face = RAIL.ShopFace,
	shade = RAIL.ShopShade,
	label = "Shop",
	wide = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset + RAIL.WideSize.Y + RAIL.Gap)

--==============================================================================
-- THE PANEL
--
-- The green header, the charcoal shell and the red close are a THEME on the one
-- shared modal rather than a second modal: the fade, the click blocker, the 44px
-- close target and the header's step clear of the rail all come with it, and
-- none of the other panels change.
--
-- No icon in the title bar any more. The mockup has none, and the cart is on the
-- rail button that opened this.
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "Shop",
	maxWidth = MAX_WIDTH,
	maxHeight = MAX_HEIGHT,
	theme = {
		fill = SHOP.BodyTop,
		shade = SHOP.BodyBottom,
		outline = INK,
		lattice = SHOP.BodyLattice,
		latticeTransparency = SHOP.BodyLatticeTransparency,
		-- Level with the shell, so it draws over the shell (it is the shell's
		-- child) and under everything above it: the banner and the tiles are
		-- at 2 and up. At the default 0 it was buried under the shell.
		latticeZIndex = 1,
		headerTop = SHOP.HeaderTop,
		headerBottom = SHOP.HeaderBottom,
		headerRule = INK,
		titleStroke = INK,
		titleStrokeThickness = 2.5,
		closeTop = SHOP.CloseTop,
		closeBottom = SHOP.CloseBottom,
		closeShade = SHOP.CloseShade,
		closeRadius = 8,
	},
})
modal.title.TextSize = 30

local close = modal.close

--==============================================================================
-- THE BODY
--==============================================================================
-- Room at the sides for a tile's keyline. A UIStroke draws OUTSIDE its frame and
-- a ScrollingFrame clips at its own edge, so a tile flush against that edge would
-- lose the outer half of its outline, and more of it while it pops.
local EDGE = 6

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Size = UDim2.fromScale(1, 1)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = SHOP.ScrollBar
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ZIndex = 3
body.Parent = modal.body

local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingLeft = UDim.new(0, EDGE)
bodyPad.PaddingRight = UDim.new(0, EDGE)
bodyPad.PaddingTop = UDim.new(0, 2)
bodyPad.PaddingBottom = UDim.new(0, 12)
bodyPad.Parent = body

local bodyList = Instance.new("UIListLayout")
bodyList.FillDirection = Enum.FillDirection.Vertical
bodyList.SortOrder = Enum.SortOrder.LayoutOrder
bodyList.Padding = UDim.new(0, 10)
bodyList.Parent = body

--==============================================================================
-- THE TILES ARE MEASURED, NOT TYPED
--
-- A modal is a fraction of the screen with a cap, so one script lays out at 248
-- pixels and at 620: every shelf sizes its cells off the body and re-sizes them
-- when the screen turns. Three across from 400 pixels, two below that.
--==============================================================================
local GUTTER = 10
-- Landscape: a shop tile is a picture, a line of type and a button, laid out
-- wider than tall.
local CARD_ASPECT = 0.86

--==============================================================================
-- THE BANDS INSIDE A TILE ARE PIXELS FROM THE BOTTOM
--
-- The button is a touch target, and a touch target has a floor: 44 pixels,
-- Roblox's minimum and this HUD's rule. A band sized as a fraction of the tile
-- shrinks under that on a small screen, so the button and the line of type above
-- it are fixed heights measured up from the bottom edge, and the picture takes
-- whatever is left.
--
-- THE HIT AREA IS 44 AND THE PLATE IS 36. The lime plate is drawn inside a
-- transparent button, the way UIKit.modal's close is a 44-pixel target around a
-- smaller plate, so the tile keeps the mockup's proportions and the target does
-- not shrink with them.
--==============================================================================
local PAD = 6
local TITLE = 22
local TARGET = 44
local PLATE = 36
local BOTTOM = 2

local shelves: { UIGridLayout } = {}

local function relayout()
	-- The padded width, less the scrollbar that draws over the right edge.
	local width = body.AbsoluteSize.X - EDGE * 2 - body.ScrollBarThickness
	if width <= 0 then
		return
	end
	local columns = if width >= 400 then 3 else 2
	local cell = math.floor((width - GUTTER * (columns - 1)) / columns)
	for _, grid in ipairs(shelves) do
		grid.CellSize = UDim2.fromOffset(cell, math.floor(cell * CARD_ASPECT))
		grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)
	end
end

-- Height the panel to whatever the shelves add up to. Read off the layout rather
-- than counted here, because a sum written twice is a sum that disagrees.
local function fit()
	modal.fitContent(bodyList.AbsoluteContentSize.Y + 14)
end

--==============================================================================
-- ONE SHELF PER SECTION: A HEADING AND A GRID
--
-- LEFT, NOT CENTRE. Centre aligns the whole grid block, and a partial last row
-- then sits left inside it; left puts every tile in the column it would have on
-- a full row.
--==============================================================================
local function section(order: number, heading: string, colour: Color3): Frame
	local header = outlined(body, 22, colour, 2.5)
	header.Name = heading .. "Header"
	header.LayoutOrder = order
	header.Size = UDim2.new(1, 0, 0, 30)
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
	grid.CellSize = UDim2.fromOffset(140, 120)
	grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.Parent = shelf
	table.insert(shelves, grid)

	return shelf
end

type Card = {
	frame: Frame,
	fill: Frame,
	art: Frame,
	title: TextLabel,
	buy: TextButton,
	-- Held so a SOON tile can recolour its plate without a second gradient.
	plateTint: UIGradient,
	capsule: Frame,
	token: Frame,
	price: TextLabel,
}

--==============================================================================
-- ONE TILE
--
-- The cell is a transparent frame the grid places and the pop scales. Inside it,
-- `fill` is the tile: the shelf's gradient, rounded, inside an ink keyline. The
-- picture takes the top, one line of two-tone type sits over the button, and the
-- button is a lime plate with a white capsule for the price.
--
-- `withTitle` is false for a pass, whose card art already carries its own name
-- and gets the title's height for the picture instead.
--==============================================================================
local function buildCard(parent: Instance, order: number, palette: any, withTitle: boolean): Card
	local frame = Instance.new("Frame")
	frame.Name = "Card" .. order
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent

	--==========================================================================
	-- THE POP LIVES ON THE CELL, THE SHAKE LIVES INSIDE IT
	--
	-- UIScale is visual only, so growing the cell on hover does not disturb the
	-- UIGridLayout that placed it -- but the cell's POSITION belongs to that
	-- layout, so the shake moves `fill` instead. See UIKit.shake.
	--==========================================================================
	local pop = Instance.new("UIScale")
	pop.Scale = 1
	pop.Parent = frame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = frame
	corner(fill, 12)
	UIKit.gradient(fill, palette.top, palette.bottom)
	-- On the tile, not the cell, so the keyline shakes with the tile it outlines.
	-- Kept, because the hover pop thickens it.
	local edge = stroke(fill, INK, 3)

	local below = BOTTOM + TARGET + (if withTitle then TITLE else 0)
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0, PAD)
	art.Size = UDim2.new(1, -PAD * 2, 1, -(PAD + below))
	art.BackgroundTransparency = 1
	art.ZIndex = 3
	art.Parent = fill

	--==========================================================================
	-- ONE LINE, TWO COLOURS
	--
	-- RichText, so "+150K" can be green and "SPEED" white on the same baseline.
	-- Two labels side by side would have to be measured and centred as a pair,
	-- which is arithmetic RichText already does. Scaled with a floor, so a long
	-- name gets smaller type instead of losing its last word off the tile.
	--==========================================================================
	local titleLabel = outlined(fill, 19, WHITE, 2)
	titleLabel.Name = "Title"
	titleLabel.RichText = true
	titleLabel.AnchorPoint = Vector2.new(0.5, 1)
	titleLabel.Position = UDim2.new(0.5, 0, 1, -(BOTTOM + TARGET))
	titleLabel.Size = UDim2.new(1, -10, 0, TITLE)
	titleLabel.TextScaled = true
	titleLabel.Visible = withTitle
	titleLabel.ZIndex = 4
	local titleFit = Instance.new("UITextSizeConstraint")
	titleFit.MaxTextSize = 19
	titleFit.MinTextSize = 9
	titleFit.Parent = titleLabel

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 1, -BOTTOM)
	buy.Size = UDim2.new(1, -12, 0, TARGET)
	buy.BackgroundTransparency = 1
	buy.BorderSizePixel = 0
	buy.AutoButtonColor = false
	buy.Text = ""
	buy.ZIndex = 5
	buy.Parent = fill

	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.new(1, 0, 0, PLATE)
	plate.BorderSizePixel = 0
	-- Not Active: the press belongs to the button around it.
	plate.Active = false
	plate.ZIndex = 6
	plate.Parent = buy
	corner(plate, 9)
	local plateTint = UIKit.gradient(plate, SHOP.PillTop, SHOP.PillBottom)
	stroke(plate, INK, 2.5)

	--==========================================================================
	-- THE CAPSULE SIZES ITSELF TO WHAT IS IN IT
	--
	-- A price of 29 and a price of 1199 are different widths, and a capsule cut
	-- to the widest would leave a short price rattling around in white. The mark
	-- and the number are a centred row, and the capsule grows to fit them.
	--==========================================================================
	local capsule = Instance.new("Frame")
	capsule.Name = "Capsule"
	capsule.AnchorPoint = Vector2.new(0.5, 0.5)
	capsule.Position = UDim2.fromScale(0.5, 0.5)
	capsule.Size = UDim2.new(0, 0, 0, PLATE - 12)
	capsule.AutomaticSize = Enum.AutomaticSize.X
	capsule.BackgroundColor3 = SHOP.Capsule
	capsule.BorderSizePixel = 0
	capsule.Active = false
	capsule.ZIndex = 7
	capsule.Parent = plate
	corner(capsule, 12)

	local capsulePad = Instance.new("UIPadding")
	capsulePad.PaddingLeft = UDim.new(0, 10)
	capsulePad.PaddingRight = UDim.new(0, 10)
	capsulePad.Parent = capsule

	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Padding = UDim.new(0, 5)
	row.Parent = capsule

	--==========================================================================
	-- THE ROBUX MARK IS A DRAWN TOKEN, NOT A GLYPH
	--
	-- The real icon is a font character that renders as a blank box wherever the
	-- font does not carry it, and this HUD has been bitten by missing glyphs. An
	-- ink square with a white centre reads as the mark at fourteen pixels, needs
	-- no upload, and cannot come out as tofu.
	--
	-- NOT ROTATED. A rotated child escapes ClipsDescendants, and this panel
	-- scrolls.
	--==========================================================================
	local token = Instance.new("Frame")
	token.Name = "Token"
	token.LayoutOrder = 1
	token.Size = UDim2.fromOffset(14, 14)
	token.BackgroundColor3 = INK
	token.BorderSizePixel = 0
	token.Active = false
	token.ZIndex = 8
	token.Parent = capsule
	corner(token, 4)

	local pip = Instance.new("Frame")
	pip.Name = "Pip"
	pip.AnchorPoint = Vector2.new(0.5, 0.5)
	pip.Position = UDim2.fromScale(0.5, 0.5)
	pip.Size = UDim2.fromOffset(6, 6)
	pip.BackgroundColor3 = SHOP.Capsule
	pip.BorderSizePixel = 0
	pip.Active = false
	pip.ZIndex = 9
	pip.Parent = token
	corner(pip, 2)

	-- Dark on white needs no outline: an ink stroke round ink type only blurs it.
	local price = Instance.new("TextLabel")
	price.Name = "Price"
	price.LayoutOrder = 2
	price.AutomaticSize = Enum.AutomaticSize.X
	price.Size = UDim2.new(0, 0, 1, 0)
	price.BackgroundTransparency = 1
	price.Font = Enum.Font.LuckiestGuy
	price.TextSize = 17
	price.TextColor3 = INK
	price.Text = ""
	price.ZIndex = 8
	price.Parent = capsule

	--==========================================================================
	-- Hover is on the WHOLE TILE, because that is what the pointer is over, and
	-- on a phone the same pop runs on press and releases on lift. The shake is
	-- fired by the button, the only part of a tile a player can actually press.
	--==========================================================================
	UIKit.popOnHover(frame, pop, { stroke = edge })
	UIKit.shakeOnClick(buy, fill)

	return {
		frame = frame,
		fill = fill,
		art = art,
		title = titleLabel,
		buy = buy,
		plateTint = plateTint,
		capsule = capsule,
		token = token,
		price = price,
	}
end

--==============================================================================
-- "NOT YET" IS A GREY BUTTON, NOT A GREY TILE
--
-- The tile keeps its colour so the shelf still sells the idea; only the button
-- goes slate, its capsule goes dark and the price reads SOON. Filling the id in
-- is the whole difference between this and a live tile.
--==============================================================================
local function markSoon(card: Card)
	card.plateTint.Color = ColorSequence.new(SHOP.SoonTop, SHOP.SoonBottom)
	card.capsule.BackgroundColor3 = SHOP.SoonCapsule
	card.token.Visible = false
	card.price.Text = "SOON"
	card.price.TextColor3 = SHOP.SoonText
end

--==============================================================================
-- THE ICONS ARE UPLOADED
--
-- Real ids in GameConfig.Store.Icons, keyed by the item's own `key`. A tile whose
-- key is missing gets NO icon rather than the wrong one: a blank band reads as
-- unfinished, a mismatched picture reads as a bug, and only one of those is true.
--
-- ScaleType.Fit, not Stretch: the art is square and the band is not.
--==============================================================================
local ICONS = STORE.Icons or {}

local function storeArt(parent: Frame, key: string): ImageLabel?
	local asset = ICONS[key]
	if not asset then
		warn("[Seed/ShopUI] no icon for " .. key .. "; leaving the band empty")
		return nil
	end
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Image = asset
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 4
	icon.Parent = parent
	return icon
end

--==============================================================================
-- A PASS TILE SHOWS ITS CARD ART
--
-- A pass is one commissioned 3:2 card with its own name and benefit painted in,
-- so its tile carries that picture where a product carries an icon, on the
-- shelf's gold, with the same button every other tile has.
--
-- The picture keeps its 3:2 inside the band and is centred: cropping would cut
-- the money or the title, and stretching would fatten the lettering. The ink
-- keyline traces the picture, not the band around it.
--==============================================================================
local PASS_ASPECT = 1.5

local function passArt(card: Card, image: string)
	local picture = Instance.new("ImageLabel")
	picture.Name = "PassArt"
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.5)
	picture.Size = UDim2.fromScale(1, 1)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.ScaleType = Enum.ScaleType.Fit
	picture.ZIndex = 4
	picture.Parent = card.art
	local shape = Instance.new("UIAspectRatioConstraint")
	shape.AspectRatio = PASS_ASPECT
	shape.Parent = picture
	corner(picture, 8)
	stroke(picture, INK, 2)
end

--==============================================================================
-- THE LABEL IS TWO COLOURS ON ONE LINE
--
-- The amount is neon green, and neon gold from GameConfig.Shop.AmountHighFrom up
-- -- the gold is how the reference marks the big packs. A row with no amount at
-- all (a pod) is a premium item and reads gold. The noun is always white.
--
-- Split at the first space: "+150K SPEED" is amount and noun. A label with no
-- space is all amount.
--==============================================================================
local function hexOf(colour: Color3): string
	return string.format("#%02X%02X%02X", math.round(colour.R * 255),
		math.round(colour.G * 255), math.round(colour.B * 255))
end

local function twoTone(label: string, amount: number?): string
	local tint = if amount == nil or amount >= SHOP.AmountHighFrom
		then SHOP.AmountHigh else SHOP.AmountLow
	local hex = hexOf(tint)
	local head, tail = string.match(label, "^(%S+)%s+(.+)$")
	if not head then
		return string.format('<font color="%s">%s</font>', hex, label)
	end
	return string.format('<font color="%s">%s</font> <font color="%s">%s</font>',
		hex, head, hexOf(WHITE), tail)
end

--==============================================================================
-- THE SHELVES
--
-- Built from GameConfig.Store, which is also what the server grants from, so a
-- tile cannot advertise something StoreService does not know how to give. A
-- product with an id of 0 has not been created yet: its tile is still drawn, but
-- reads SOON and refuses.
--==============================================================================
local order = 1
local liveCount, soonCount = 0, 0

for _, spec in ipairs(STORE.Sections) do
	local isPass = spec.layout == "pass"
	local shelf = section(order, spec.heading, spec.colour)
	order += 2

	local items = STORE.Items[spec.id] or {}

	if #items == 0 then
		--==================================================================
		-- AN EMPTY SHELF STILL SAYS SOMETHING
		--
		-- A plate that says so is a promise; a missing heading is nothing.
		--==================================================================
		local card = buildCard(shelf, 1, spec, true)
		storeArt(card.art, "comingSoon")
		card.title.Text = twoTone("COMING SOON", nil)
		markSoon(card)
		card.buy.Activated:Connect(function()
			SoundKit.play("Denied")
		end)
		soonCount += 1
	end

	for index, item in ipairs(items) do
		if isPass then
			--==============================================================
			-- A PASS, WHICH IS SOLD A DIFFERENT WAY
			--
			-- PromptGamePassPurchase, not PromptProductPurchase. The two take
			-- different ids from different pages of the Creator Dashboard,
			-- and calling one with the other's id fails at the till rather
			-- than here -- which is why the field is `pass` and is read as
			-- `pass`. PassService decides what the player owns by asking
			-- Roblox; nothing on this side grants anything.
			--==============================================================
			local artwork = (STORE.Cards or {})[tostring(item.key)]
			if not artwork then
				warn("[Seed/ShopUI] no card art for pass " .. tostring(item.key))
				continue
			end
			local card = buildCard(shelf, index, spec, false)
			passArt(card, artwork)

			local passId = tonumber(item.pass) or 0
			local live = passId > 0
			if live then
				liveCount += 1
				card.price.Text = tostring(item.robux)
			else
				soonCount += 1
				markSoon(card)
			end

			card.buy.Activated:Connect(function()
				if not live then
					SoundKit.play("Denied")
					return
				end
				-- The press cue only on the path that DOES something: a refusal
				-- has its own sound, and the two together say yes and no at once.
				SoundKit.play("CardClick")
				local ok, err = pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, passId)
				end)
				if not ok then
					warn("[Seed/ShopUI] could not prompt for pass " .. item.key
						.. ": " .. tostring(err))
					SoundKit.play("Denied")
				end
			end)
		else
			local card = buildCard(shelf, index, spec, true)
			storeArt(card.art, tostring(item.key))
			card.title.Text = twoTone(item.label, item.amount)

			local productId = tonumber(item.product) or 0
			local live = productId > 0
			if live then
				liveCount += 1
				card.price.Text = tostring(item.robux)
			else
				soonCount += 1
				markSoon(card)
			end

			card.buy.Activated:Connect(function()
				if not live then
					-- Prompting with a product id of 0 throws, and a thrown error
					-- on a click reads as a broken shop. The refusal noise is the
					-- honest answer until the id exists.
					SoundKit.play("Denied")
					return
				end
				--==========================================================
				-- THE CLIENT ASKS FOR THE PROMPT AND NOTHING ELSE
				--
				-- No optimistic paint, no BUYING state, no local grant. What
				-- the player gets is decided by StoreService when Roblox
				-- delivers the receipt, and the profile packet that follows
				-- updates the HUD.
				--==========================================================
				SoundKit.play("CardClick")
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
