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
--==============================================================================
-- THE SHOP PANEL IS WIDER THAN THE OTHER TWO
--
-- 460 is UIKit's default and it is right for the Index and the Garden, whose
-- cards are portraits read one at a time. A shop shelf is scanned three across,
-- and at 460 that left 144-pixel tiles -- against roughly 200 in the reference,
-- which is why the tiles read as cramped no matter how the bands were divided.
--
-- maxWidth is already a per-caller option, so this widens the SHOP and nothing
-- else: Index, Garden, Loadout and the Marigold stall keep their own numbers.
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
	icon = RAIL.ShopIcon,
	label = "Shop",
	wide = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset + RAIL.WideSize.Y + RAIL.Gap)

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
--==============================================================================
-- THE SHOP TILE IS LANDSCAPE, AND THE OTHER TWO PANELS ARE NOT
--
-- Index and Garden cards are 1.30 -- portrait, because a plant is taller than it
-- is wide and the card is a photograph of one. A shop tile is not a portrait of
-- anything: it is an icon, a price and a button, and the reference lays those
-- out wider than tall. 0.86 is as flat as this panel can go and still fit a
-- 52% illustration over a line of type over a 30-pixel pill at 248 pixels wide.
--==============================================================================
local CARD_ASPECT = 0.86

local shelves: { UIGridLayout } = {}

--==============================================================================
-- THE PASS CARD IS ONE CELL, NOT A BANNER
--
-- It used to span the whole shelf: a 3:2 card 584 wide and 389 tall, which was
-- most of the panel before a player had scrolled to anything they could buy.
-- The owner asked for it at tile size, with the rest of the row left for the
-- passes still to come -- so it is now an ordinary grid cell, the same width and
-- height as a SPEED tile, and the second and third pass will land beside it with
-- no layout work at all.
--
-- That also retires the sizing problem the banner had. There is no measuring
-- pass and no aspect constraint to go circular against an AutomaticSize parent;
-- UIGridLayout gives the cell a definite size and the artwork fits inside it.
--==============================================================================
local BANNER_ASPECT = 1.5

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

--==============================================================================
-- EVERY SHELF IS A GRID
--
-- The PASSES shelf used to be an exception that got no UIGridLayout, because it
-- held one card as wide as the panel. It holds a tile now, so the exception is
-- gone and its cells come from the same relayout() as every other shelf -- which
-- is what makes "the same size as SPEED" true by construction rather than by two
-- numbers that have to be kept equal.
--==============================================================================
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
	--==========================================================================
	-- LEFT, NOT CENTRE
	--
	-- Centre aligns the whole grid BLOCK, and a partial last row then sits left
	-- inside it -- which looks left-aligned on every shelf that fills a row, and
	-- puts the lone COMING SOON plate on the empty PLANTS shelf in the middle
	-- column. One card behaving differently from the other fifteen reads as a
	-- bug; left aligns all of them the same way and moves the rest by 3 pixels.
	--==========================================================================
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
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
	-- Greyed with the rest of the tile when a product has no id yet.
	token: Frame,
}

--==============================================================================
-- ONE TILE
--
-- Built to the reference: a bright rim in the shelf's own colour around a
-- gradient face, an illustration filling the top half, one line of type where
-- the AMOUNT is coloured and the noun beside it is white, and a green pill with
-- a Robux token and a number.
--
-- The palette is passed in rather than read from a global, because the whole
-- point of the redesign is that a speed tile and a cash tile are not the same
-- colour.
--==============================================================================
local function buildCard(parent: Instance, order: number, palette: any): Card
	local frame = Instance.new("Frame")
	frame.Name = "Card" .. order
	frame.LayoutOrder = order
	-- The RIM. It is the card's background and the fill sits inset inside it,
	-- so the bright edge is geometry rather than a stroke that would round
	-- differently at every corner radius.
	frame.BackgroundColor3 = palette.rim
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, 12)
	-- Captured, because the hover pop thickens it. It used to be built and
	-- forgotten, which is fine right up until something wants to animate it.
	local edge = stroke(frame, SHOP.Outline, 3)

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
	fill.Position = UDim2.fromOffset(4, 4)
	fill.Size = UDim2.new(1, -8, 1, -8)
	fill.BackgroundColor3 = WHITE
	fill.BorderSizePixel = 0
	fill.Parent = frame
	corner(fill, 9)
	local tint = gradient(fill, palette.top, palette.bottom)

	-- Scale, not offset: the cell is measured off the panel, so a card laid out
	-- at 248 pixels and one at 460 have to fill themselves the same way.
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	--==========================================================================
	-- EVERY BAND IS A FRACTION, NOT A PIXEL COUNT
	--
	-- The title used to be 24 pixels tall on a card that is 124 pixels tall at
	-- three columns and 93 at two -- a quarter of the tile at one width and a
	-- third at the other, which is how the label ended up sitting on the pill.
	-- Art 0.05-0.47, type 0.49-0.69, pill 0.73-0.95, all in scale.
	--==========================================================================
	art.Position = UDim2.new(0.5, 0, 0.02, 0)
	--==========================================================================
	-- THE ART BAND IS SIZED BY ITS HEIGHT, NOT ITS WIDTH
	--
	-- The icons are square and ScaleType.Fit honours that, so a 115x59 band
	-- renders a 59-pixel icon and wastes the other 56 pixels of width. Height is
	-- the only dimension that makes the illustration bigger, so art takes half
	-- the tile: 0.02-0.58 art, 0.59-0.76 type, 0.76-0.97 pill.
	--==========================================================================
	art.Size = UDim2.new(0.94, 0, 0.56, 0)
	art.BackgroundTransparency = 1
	art.Parent = fill

	--==========================================================================
	-- ONE LINE, TWO COLOURS
	--
	-- RichText, so "+150K" can be green and "SPEED" white on the same baseline
	-- the way the reference prints it. Two labels side by side would need to be
	-- measured and centred as a pair, which is arithmetic RichText already does.
	--==========================================================================
	local titleLabel = outlined(fill, 18, WHITE, 3)
	titleLabel.Name = "Title"
	titleLabel.RichText = true
	titleLabel.Position = UDim2.new(0, 0, 0.59, 0)
	titleLabel.Size = UDim2.new(1, -8, 0.17, 0)
	--==========================================================================
	-- LONG NAMES SHRINK RATHER THAN SPILL
	--
	-- "+150K SPEED" fits at eighteen and "COLOSSAL BELLCHIME" does not -- it came
	-- out as "COLOSSAL BELLCHI(" with the tail cut off the card. Scaled with a
	-- floor, so a long product name gets smaller type instead of losing its last
	-- word, and nothing here has to know in advance how long a label is.
	--==========================================================================
	titleLabel.TextScaled = true
	local titleFit = Instance.new("UITextSizeConstraint")
	titleFit.MaxTextSize = 18
	titleFit.MinTextSize = 9
	titleFit.Parent = titleLabel

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 0.97, 0)
	buy.Size = UDim2.new(0.88, 0, 0.21, 0)
	buy.BackgroundColor3 = SHOP.Pill
	buy.BorderSizePixel = 0
	buy.AutoButtonColor = false
	buy.Text = ""
	buy.Parent = fill
	corner(buy, 7)
	stroke(buy, SHOP.Outline, 2.5)

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.AnchorPoint = Vector2.new(0.5, 1)
	shade.Position = UDim2.new(0.5, 0, 1, 0)
	shade.Size = UDim2.new(1, 0, 0, 6)
	shade.BackgroundColor3 = SHOP.PillShade
	shade.BorderSizePixel = 0
	shade.Parent = buy
	corner(shade, 7)

	--==========================================================================
	-- THE ROBUX MARK IS A DRAWN TOKEN, NOT A GLYPH
	--
	-- The real icon is a font character that renders as a blank box wherever the
	-- font does not carry it, and this HUD has already been bitten once by
	-- missing glyphs. A ring with a lighter centre reads as a coin at sixteen
	-- pixels, needs no upload, and cannot come out as tofu.
	--
	-- NOT ROTATED. A rotated child escapes ClipsDescendants, and this panel
	-- SCROLLS -- the card comment at the top of this file records the half-
	-- scrolled tile that threw its decoration 342 pixels past the list.
	--==========================================================================
	local token = Instance.new("Frame")
	token.Name = "Token"
	token.AnchorPoint = Vector2.new(0, 0.5)
	token.Position = UDim2.new(0.10, 0, 0.5, 0)
	token.Size = UDim2.fromScale(0.42, 0.56)
	token.SizeConstraint = Enum.SizeConstraint.RelativeYY
	token.BackgroundColor3 = Color3.fromRGB(236, 252, 214)
	token.BorderSizePixel = 0
	token.ZIndex = 3
	token.Parent = buy
	corner(token, 20)
	stroke(token, SHOP.Outline, 2)

	local pip = Instance.new("Frame")
	pip.AnchorPoint = Vector2.new(0.5, 0.5)
	pip.Position = UDim2.fromScale(0.5, 0.5)
	pip.Size = UDim2.fromScale(0.42, 0.42)
	pip.BackgroundColor3 = SHOP.PillShade
	pip.BorderSizePixel = 0
	pip.ZIndex = 4
	pip.Parent = token
	corner(pip, 20)

	local price = outlined(buy, 16, WHITE, 2)
	price.Name = "Price"
	price.Position = UDim2.new(0.16, 0, 0, 0)
	price.Size = UDim2.new(0.84, -6, 1, 0)
	price.ZIndex = 3

	--==========================================================================
	-- Hover is on the WHOLE TILE, because that is what the pointer is over; the
	-- shake is fired by the pill, because that is the only part of a shop tile
	-- a player can actually press.
	--==========================================================================
	UIKit.popOnHover(frame, pop, { stroke = edge })
	UIKit.shakeOnClick(buy, fill)

	return {
		frame = frame,
		fill = fill,
		tint = tint,
		art = art,
		title = titleLabel,
		price = price,
		buy = buy,
		token = token,
	}
end

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
-- THE ICONS ARE UPLOADED NOW, AND THAT REPLACED FOUR DRAWN SHAPES
--
-- Every tile used to draw its own icon out of plain frames -- three bars for
-- speed, a stack of notes for cash, a two-part shell for a pod, a stem and two
-- leaves for a plant. That was the honest answer while no image tool existed
-- and inventing an asset id was the only alternative, but it never matched the
-- reference, which uses rendered objects with a white sticker outline.
--
-- These are fifteen real ids in GameConfig.Store.Icons, keyed by the item's own
-- `key`. A tile whose key is missing from that table gets NO icon rather than
-- the wrong one -- a blank band reads as unfinished, a mismatched picture reads
-- as a bug, and only one of those is true.
--
-- ScaleType.Fit, not Stretch. The art is square and the band is not, so Stretch
-- would squash every shoe flat. Fit letterboxes inside the band instead, which
-- is why the band above is sized off its HEIGHT.
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
	icon.ZIndex = 6
	icon.Parent = parent
	return icon
end

--==============================================================================
-- A PASS CARD IS ARTWORK WITH A BUTTON ON IT
--
-- Every other tile in this shop is BUILT -- gradient, rim, icon, type, pill --
-- because there are fourteen of them and they have to stay in step. A pass is
-- one card. Its background, its title and its benefit line are painted into a
-- single 3:2 image, so the only thing left for the UI to draw is the control
-- the player actually presses.
--
-- WHERE THE BUTTON GOES IS NOT A FREE CHOICE. The artwork was commissioned with
-- its lower right quarter left calm for exactly this. Moving it left covers the
-- money bundles and moving it up covers "PERMANENT - EARN x2 MONEY", so the
-- numbers below are anchored to the bottom right corner and kept inside that
-- reserved area.
--
-- ScaleType.Fit, not Stretch: the shelf is as wide as the panel and the card is
-- 3:2, and a stretched card would distort the type that is baked into it.
--==============================================================================
local function buildBanner(parent: Instance, order: number, palette: any,
	image: string): (Frame, TextButton, TextLabel)
	local frame = Instance.new("Frame")
	frame.Name = "PassCard" .. order
	frame.LayoutOrder = order
	-- No Size. UIGridLayout writes it, which is the whole point: the cell is
	-- whatever a SPEED tile is, measured once in relayout for every shelf.
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	--==========================================================================
	-- THE ARTWORK KEEPS ITS OWN SHAPE INSIDE THE CELL
	--
	-- The card is 3:2 and a tile is not, so the image is given the card's aspect
	-- and centred -- it fills the cell's width and leaves a little air above and
	-- below rather than being cropped or squashed. Cropping would cut either the
	-- money or the title; stretching would fatten the lettering.
	--
	-- The constraint is safe here in a way it was not on the old banner: a grid
	-- cell has a definite size, so height-from-width resolves. It only went
	-- circular before because the parent shelf was sizing itself FROM the child.
	--==========================================================================
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	art.Size = UDim2.new(1, 0, 1, 0)
	art.BackgroundTransparency = 1
	art.Image = image
	art.ScaleType = Enum.ScaleType.Fit
	art.Parent = frame

	local shape = Instance.new("UIAspectRatioConstraint")
	shape.AspectRatio = BANNER_ASPECT
	shape.DominantAxis = Enum.DominantAxis.Width
	shape.Parent = art

	--==========================================================================
	-- THE KEYLINE GOES ON THE ARTWORK, NOT ON THE CELL
	--
	-- The cell is 188 x 161 and the 3:2 card inside it is 188 x 125, so a stroke
	-- on the cell drew a box with 18 empty pixels of shelf above and below the
	-- picture -- a frame around nothing, which is worse than no frame at all.
	--
	-- On the art it traces the card, matches the black keyline every tile
	-- carries, and still gives the hover pop something to thicken. Thickness is
	-- what the tween moves, NOT transparency: a stroke left transparent would
	-- thicken invisibly and this would be the one card in the shop that does not
	-- answer the pointer.
	--==========================================================================
	corner(art, 8)
	local edge = stroke(art, SHOP.Outline, 2.5)

	--==========================================================================
	-- THE BUTTON, IN THE QUARTER THE ARTWORK LEFT EMPTY
	--
	-- Anchored to the bottom right rather than positioned from the top left, so
	-- it stays in the reserved area whatever the card's rendered size is.
	--==========================================================================
	--==========================================================================
	-- Still the artwork's reserved lower-right quarter, and still in SCALE, so
	-- shrinking the card from 584 wide to a tile moves the button with it rather
	-- than leaving a pill sized for a banner sitting off the corner.
	--==========================================================================
	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.AnchorPoint = Vector2.new(1, 1)
	buy.Position = UDim2.fromScale(0.945, 0.90)
	buy.Size = UDim2.fromScale(0.40, 0.20)
	buy.BackgroundColor3 = SHOP.Pill
	buy.BorderSizePixel = 0
	buy.AutoButtonColor = false
	buy.Text = ""
	buy.ZIndex = 4
	buy.Parent = art
	corner(buy, 6)
	stroke(buy, SHOP.Outline, 2)

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.AnchorPoint = Vector2.new(0.5, 1)
	shade.Position = UDim2.new(0.5, 0, 1, 0)
	shade.Size = UDim2.new(1, 0, 0, 5)
	shade.BackgroundColor3 = SHOP.PillShade
	shade.BorderSizePixel = 0
	shade.ZIndex = 4
	shade.Parent = buy
	corner(shade, 6)

	local price = outlined(buy, 16, WHITE, 2)
	price.Name = "Price"
	price.Size = UDim2.fromScale(1, 1)
	price.ZIndex = 5
	price.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	-- The tile is a third of the banner's width, so the ceiling comes down with
	-- it; SOON at 22 on a 190px card would have crowded the pill edge to edge.
	cap.MaxTextSize = 15
	cap.MinTextSize = 8
	cap.Parent = price

	--==========================================================================
	-- The same two behaviours as a tile. The banner is not in a grid, so its own
	-- Position would have been safe to move -- but shaking the ARTWORK keeps
	-- every card in the game shaking the same layer, and one rule is easier to
	-- keep true than two.
	--==========================================================================
	local pop = Instance.new("UIScale")
	pop.Scale = 1
	pop.Parent = frame
	UIKit.popOnHover(frame, pop, { stroke = edge })
	UIKit.shakeOnClick(buy, art)

	local _ = palette
	return frame, buy, price
end

--==============================================================================
-- THE LABEL IS TWO COLOURS ON ONE LINE
--
-- "+150K SPEED" prints the amount in the shelf's accent and the noun in white,
-- which is how the reference separates the number you are buying from the thing
-- it is. Split at the first space: an entry with no space -- "$24,000" -- is all
-- amount, which is also how the reference prints the cash shelf.
--==============================================================================
local function twoTone(label: string, accent: Color3): string
	local hex = string.format("#%02X%02X%02X",
		math.round(accent.R * 255), math.round(accent.G * 255), math.round(accent.B * 255))
	local head, tail = string.match(label, "^(%S+)%s+(.+)$")
	if not head then
		return string.format('<font color="%s">%s</font>', hex, label)
	end
	return string.format('<font color="%s">%s</font> %s', hex, head, tail)
end

--==============================================================================
-- ONE SHELF PER SECTION, ONE TILE PER ITEM
--
-- A product with an id of 0 has not been created in the Creator Dashboard yet.
-- Its tile is still DRAWN -- the shelf has to look like a shelf -- but it reads
-- SOON, goes grey, and its button refuses. Filling the id in is the only change
-- needed to make it live.
--==============================================================================
local order = 1
local liveCount, soonCount = 0, 0

--==============================================================================
-- "NOT YET" IS A GREY BUTTON, NOT A GREY SHELF
--
-- The first pass drained the whole tile to grey when a product had no id, which
-- is honest and made the entire shop look broken: every id is 0 today, so every
-- shelf was slate and the cyan-and-green the reference is built on was nowhere
-- on screen.
--
-- The tile keeps its colour. Only the PILL goes dark and reads SOON, which is
-- also the smallest possible difference between this state and the live one --
-- fill in an id and the same tile simply shows a price.
--==============================================================================
local function markSoon(card: Card)
	card.buy.BackgroundColor3 = Color3.fromRGB(122, 128, 140)
	card.token.BackgroundColor3 = Color3.fromRGB(206, 210, 218)
	card.price.Text = "SOON"
	-- The shade under the pill has to go with it or the button reads as lit.
	local shade = card.buy:FindFirstChild("Shade")
	if shade and shade:IsA("Frame") then
		shade.BackgroundColor3 = Color3.fromRGB(74, 78, 88)
	end
end

for _, spec in ipairs(STORE.Sections) do
	local isBanner = spec.layout == "banner"
	local shelf = section(order, spec.heading, spec.colour)
	order += 2

	local items = STORE.Items[spec.id] or {}

	if isBanner then
		--======================================================================
		-- A PASS SHELF, WHICH IS SOLD A DIFFERENT WAY
		--
		-- PromptGamePassPurchase, not PromptProductPurchase. The two take
		-- different ids from different pages of the Creator Dashboard, and
		-- calling one with the other's id fails at the till rather than here --
		-- which is why the field is named `pass` and is read as `pass`.
		--
		-- The client still only ASKS. PassService decides what the player owns
		-- by asking Roblox, and nothing on this side grants anything.
		--======================================================================
		for index, item in ipairs(items) do
			local artwork = (STORE.Cards or {})[tostring(item.key)]
			if not artwork then
				warn("[Seed/ShopUI] no card art for pass " .. tostring(item.key))
				continue
			end
			local _, buy, price = buildBanner(shelf, index, spec, artwork)

			local passId = tonumber(item.pass) or 0
			local live = passId > 0
			if live then
				liveCount += 1
				price.Text = tostring(item.robux)
			else
				soonCount += 1
				price.Text = "SOON"
				--==============================================================
				-- Greyed the same way a SOON tile is, and for the same reason:
				-- the ARTWORK keeps its colour so the shelf still sells the
				-- idea, and only the control the player would press goes dead.
				--==============================================================
				buy.BackgroundColor3 = Color3.fromRGB(122, 128, 140)
				local shade = buy:FindFirstChild("Shade")
				if shade and shade:IsA("Frame") then
					shade.BackgroundColor3 = Color3.fromRGB(74, 78, 88)
				end
			end

			buy.Activated:Connect(function()
				if not live then
					SoundKit.play("Denied")
					return
				end
				--==========================================================
				-- The press cue only on the path that DOES something. A
				-- refusal already has its own sound, and stacking the two
				-- would say "yes" and "no" in the same tenth of a second.
				--==========================================================
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
		end
		continue
	end

	if #items == 0 then
		--==================================================================
		-- AN EMPTY SHELF STILL SAYS SOMETHING
		--
		-- The owner asked for PLANTS now and the content later. A plate that
		-- says so is a promise; a missing heading is nothing at all.
		--==================================================================
		local card = buildCard(shelf, 1, spec)
		storeArt(card.art, "comingSoon")
		card.title.Text = twoTone("COMING SOON", spec.accent)
		markSoon(card)
		card.buy.Activated:Connect(function()
			SoundKit.play("Denied")
		end)
		soonCount += 1
	end

	for index, item in ipairs(items) do
		local card = buildCard(shelf, index, spec)
		storeArt(card.art, tostring(item.key))
		card.title.Text = twoTone(item.label, spec.accent)

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
			-- receipt, and the profile packet that follows updates the HUD.
			--==============================================================
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
