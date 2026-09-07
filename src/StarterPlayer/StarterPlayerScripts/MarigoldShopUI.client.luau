--!strict
-- Steal a Seed :: MarigoldShopUI
--
-- Marigold's Garden Goods. Opened by holding E on her, not by a rail button:
-- this is a shop you walk to, which is what makes the hub somewhere to go.
--
--==============================================================================
-- THIS IS NOT A SECOND SHOP IMPLEMENTATION
--
-- ShopUI sells plot levels off the left rail and this sells weapons off an NPC,
-- and they share everything a shop is made of: UIKit.modal builds the dimmer,
-- the panel, the fade and the close button; the OpenPanel attribute is the same
-- mutex; the GameEvent remote is the same wire; the ProfileUpdated packet is the
-- same source of truth. What is here and nowhere else is the SHELF -- a
-- scrolling column of horizontal product cards with a live 3D weapon in each --
-- because a grid of square tiles cannot show a name, a sentence, three stats, a
-- price and a button, and this shop has to show all six.
--
-- The preview stage is not duplicated either. UIKit.frameViewport is the one
-- camera solve in the project and WeaponModel.BuildPreview is the one builder;
-- the model in this card is the model in your hands, built by the same function
-- from the same record.
--
--==============================================================================
-- THE CLIENT DECIDES NOTHING
--
-- Every card's state is read off the profile packet: Weapons says owned,
-- Equipped says which one is out, Cash says what is affordable. A press sends a
-- verb and an id and nothing else -- no price, no stats, no claim about what the
-- player can afford. The card turns OWNED when the SERVER says so and not one
-- frame earlier, which is why nothing in here writes to `owned` on click.
--
--==============================================================================
-- WHAT WAS BUILT FROM A DESCRIPTION RATHER THAN A PICTURE
--
-- The brief describes a reference screenshot -- warm wooden frame, green
-- patterned header with leaves, stacked horizontal cards, cream names, green
-- prices with a coin, a category badge. THAT IMAGE DID NOT ARRIVE with the
-- brief and is not in the repo, so every number below is a reading of the words
-- rather than a sample of the pixels. The palette is taken from
-- GameConfig.Panel, which is already this game's warm dark soil, and the header
-- green from GameConfig.Rail.ShopFace, which is already this game's shop
-- colour -- so it is at least wrong in the same direction as everything else.
--
-- The corner HUD and the old shop panel were both SAMPLED off their references
-- with a pixel reader, and both were wrong at first impression and right after
-- measuring. Assume this one is wrong until it is measured too.
--
-- ALSO: the reference has stock counts, restocking and a Restock button, and
-- the brief explicitly says not to copy them. There is no quantity anywhere in
-- this file. These are permanent unlocks.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PANEL = GameConfig.Panel
local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local W = GameConfig.Weapon
local PANEL_NAME = "Marigold"

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
-- Cream, which is the Crown colour every Greenhollow creature wears and the
-- colour GameConfig.Labels already uses for a name on a dark ground.
local CREAM = Color3.fromRGB(242, 238, 206)
local MONEY = Color3.fromRGB(112, 240, 96)
local COIN = Color3.fromRGB(250, 198, 48)
local COIN_RIM = Color3.fromRGB(186, 130, 20)
local MUTED = Color3.fromRGB(198, 176, 152)
local EQUIPPED_FACE = Color3.fromRGB(86, 182, 72)
local EQUIPPED_SHADE = Color3.fromRGB(46, 126, 44)
local LOCKED = Color3.fromRGB(104, 90, 78)

local HEADER_H = 54
local FILTER_H = 38
local BODY_TOP = HEADER_H + 10 + FILTER_H + 8
-- Below this the card stacks its price and button under the stats instead of
-- putting them in a right-hand column. Chosen off the narrowest the modal can
-- ever be (248) plus the widest a two-column card needs to stay readable.
local NARROW_AT = 372

--==============================================================================
-- RE-RUN SAFE, AND SINGLETON BY CONSTRUCTION
--
-- One ScreenGui with one name. A second run of this script destroys the first
-- one's, so there can never be two shop windows -- which is also the answer to
-- "prevent duplicate windows": there is only ever one panel instance and
-- `setOpen` is idempotent, so being told to open twice opens it once.
--==============================================================================
local existing = playerGui:FindFirstChild("SeedMarigoldShop")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedMarigoldShop"
gui.ResetOnSpawn = false
-- Above the other three panels (32) and below the RUN alarm (50), because an
-- alarm outranks a menu.
gui.DisplayOrder = 34
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "Marigold's Garden Goods",
	maxWidth = 520,
	maxHeight = 640,
})

--==============================================================================
-- THE HEADER
--
-- A green plate across the top of the panel with the title on it and the red X
-- at its right. The modal's own title bar is re-used rather than rebuilt -- its
-- close button already carries the click sound and the outline -- and simply
-- moved onto the plate.
--
-- ROUNDED AT THE TOP ONLY. A UICorner rounds all four, so a second rectangle
-- covers the bottom half of the plate and squares it off against the filter row.
--==============================================================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = RAIL.ShopFace
header.BorderSizePixel = 0
header.ZIndex = 4
header.Parent = modal.shell
UIKit.corner(header, 14)
UIKit.gradient(header, RAIL.ShopFace, RAIL.ShopShade)

local headerFoot = Instance.new("Frame")
headerFoot.Name = "Foot"
headerFoot.AnchorPoint = Vector2.new(0, 1)
headerFoot.Position = UDim2.fromScale(0, 1)
headerFoot.Size = UDim2.new(1, 0, 0, 16)
headerFoot.BackgroundColor3 = RAIL.ShopShade
headerFoot.BorderSizePixel = 0
headerFoot.ZIndex = 4
headerFoot.Parent = header

-- The line that separates the plate from the wood under it. Black, like every
-- other edge in this HUD.
local headerEdge = Instance.new("Frame")
headerEdge.Name = "Edge"
headerEdge.AnchorPoint = Vector2.new(0, 1)
headerEdge.Position = UDim2.fromScale(0, 1)
headerEdge.Size = UDim2.new(1, 0, 0, 3)
headerEdge.BackgroundColor3 = BLACK
headerEdge.BorderSizePixel = 0
headerEdge.ZIndex = 6
headerEdge.Parent = header

--==============================================================================
-- LEAVES, AND WHY THEY ARE NOT A LATTICE
--
-- The header wants a pattern and the obvious one is the diamond lattice every
-- other surface in this HUD carries. It is not used here for one reason: a
-- lattice is drawn from ROTATED frames, and this plate sits directly above a
-- ScrollingFrame -- the exact arrangement written up in UIKit that threw
-- diamonds three hundred pixels past their own box and over the panel below.
--
-- So the pattern is a handful of leaves, each small enough that its rotated
-- footprint stays inside the plate at every panel width, and each one placed
-- rather than tiled. Six of them, on the two ends, out from behind the title.
--==============================================================================
--
-- ALL OF THEM TO THE RIGHT OF THE TITLE, which is where the empty half of the
-- plate is. The first pass put three on the LEFT and they landed underneath
-- "Marigold's" -- behind it, at a lower ZIndex, so what actually rendered was
-- pale slivers showing through the gaps between letters. Measured off the
-- screenshot rather than reasoned about: the title is left-aligned and about
-- half the plate wide, so everything from 0.58 out is clear space.
--
-- They hide entirely on a narrow panel, where the title takes the whole plate.
local LEAVES = {
	{ x = 0.600, y = 0.68, w = 22, h = 11, r = 20, t = 0.74 },
	{ x = 0.660, y = 0.28, w = 16, h = 8, r = -14, t = 0.82 },
	{ x = 0.722, y = 0.66, w = 26, h = 13, r = 26, t = 0.72 },
	{ x = 0.790, y = 0.30, w = 19, h = 10, r = -20, t = 0.78 },
	{ x = 0.845, y = 0.70, w = 15, h = 8, r = 12, t = 0.86 },
	{ x = 0.895, y = 0.32, w = 21, h = 11, r = -8, t = 0.80 },
}
local leafFrames: { Frame } = {}
for i, leaf in ipairs(LEAVES) do
	local f = Instance.new("Frame")
	f.Name = "Leaf" .. i
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(leaf.x, leaf.y)
	f.Size = UDim2.fromOffset(leaf.w, leaf.h)
	f.Rotation = leaf.r
	f.BackgroundColor3 = CREAM
	f.BackgroundTransparency = leaf.t
	f.BorderSizePixel = 0
	f.ZIndex = 5
	f.Parent = header
	local c = Instance.new("UICorner")
	-- A leaf is a lens: fully rounded on the short axis, so the corner radius is
	-- half the height rather than a fixed pixel count.
	c.CornerRadius = UDim.new(0, math.floor(leaf.h * 0.5))
	c.Parent = f
	-- The vein. One line, off-centre, which is what stops it reading as a pill.
	local vein = Instance.new("Frame")
	vein.Name = "Vein"
	vein.AnchorPoint = Vector2.new(0.5, 0.5)
	vein.Position = UDim2.fromScale(0.5, 0.42)
	vein.Size = UDim2.new(0.74, 0, 0, 1)
	vein.BackgroundColor3 = RAIL.ShopShade
	vein.BackgroundTransparency = math.min(0.9, leaf.t + 0.05)
	vein.BorderSizePixel = 0
	vein.ZIndex = 6
	vein.Parent = f
	table.insert(leafFrames, f)
end

local titleBar = modal.title.Parent :: Frame
titleBar.Parent = header
titleBar.Position = UDim2.fromOffset(14, 0)
titleBar.Size = UDim2.new(1, -28, 0, HEADER_H)
titleBar.ZIndex = 7
modal.title.Text = "Marigold's Garden Goods"
modal.title.TextColor3 = CREAM
modal.title.TextSize = 22
modal.title.TextScaled = false
--==============================================================================
-- TRUNCATE, DO NOT SCALE
--
-- TextScaled on a title makes the shop's own name a different size on every
-- screen, which is the one label that should not move. It shrinks one step on a
-- narrow panel and truncates below that -- an ellipsis is a legible failure and
-- text spilling past a green plate is not.
--==============================================================================
modal.title.TextTruncate = Enum.TextTruncate.AtEnd
modal.title.TextXAlignment = Enum.TextXAlignment.Left
modal.title.Size = UDim2.new(1, -50, 1, 0)
modal.title.ZIndex = 7
modal.close.ZIndex = 8
modal.close.Size = UDim2.fromOffset(34, 34)

--==============================================================================
-- THE FILTER ROW
--
-- Three tabs and the balance, on one fixed line under the header. It is outside
-- the ScrollingFrame on purpose: a filter you have to scroll back up to reach
-- is a filter nobody uses twice.
--==============================================================================
local filterRow = Instance.new("Frame")
filterRow.Name = "Filters"
filterRow.Position = UDim2.fromOffset(12, HEADER_H + 8)
filterRow.Size = UDim2.new(1, -24, 0, FILTER_H)
filterRow.BackgroundTransparency = 1
filterRow.ZIndex = 4
filterRow.Parent = modal.shell

local TABS = {
	{ id = "all", label = "All" },
	{ id = "bat", label = "Bats" },
	{ id = "trap", label = "Traps" },
}
local activeFilter = "all"
local tabButtons: { [string]: TextButton } = {}

--
-- SIZED IN `sizeFilters` BELOW, NOT HERE. Three tabs at a fixed 62-pixel pitch
-- plus a fixed 112-pixel balance is 298 pixels of content in a 270-pixel row,
-- and on a narrow panel the cash pill sat on top of the TRAPS tab -- measured
-- off the first mobile screenshot, not reasoned about. The row divides itself
-- now, so it cannot overflow at any width the modal allows.
local tabFrames: { TextButton } = {}
for i, tab in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.Name = "Tab" .. tab.id
	b.Position = UDim2.fromOffset((i - 1) * 62, 2)
	b.Size = UDim2.fromOffset(58, 34)
	b.BackgroundColor3 = PANEL.Shade
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = 5
	UIKit.clicks(b)
	b.Parent = filterRow
	UIKit.corner(b, 9)
	UIKit.stroke(b, BLACK, 2)

	local label = UIKit.outlined(b, "Label", 15, CREAM, 2)
	label.Size = UDim2.fromScale(1, 1)
	label.Text = tab.label
	label.ZIndex = 6
	tabButtons[tab.id] = b
	tabFrames[i] = b
end

--== THE BALANCE ==--
local cashPill = Instance.new("Frame")
cashPill.Name = "Cash"
cashPill.AnchorPoint = Vector2.new(1, 0)
cashPill.Position = UDim2.new(1, 0, 0, 2)
cashPill.Size = UDim2.fromOffset(112, 34)
cashPill.BackgroundColor3 = PANEL.Shade
cashPill.BorderSizePixel = 0
cashPill.ZIndex = 5
cashPill.Parent = filterRow
UIKit.corner(cashPill, 9)
UIKit.stroke(cashPill, BLACK, 2)

--==============================================================================
-- THE COIN
--
-- Three frames: a rim, a face and a highlight. Drawn rather than an emoji or an
-- asset for the reason every icon in this HUD is drawn -- the Gotham dingbat
-- range is tofu on this device, and an uploaded id can be moderated away.
--==============================================================================
local function coin(parent: GuiObject, size: number): Frame
	local box = Instance.new("Frame")
	box.Name = "Coin"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundColor3 = COIN_RIM
	box.BorderSizePixel = 0
	box.ZIndex = 6
	box.Parent = parent
	UIKit.corner(box, math.floor(size * 0.5))
	local face = UIKit.piece(box, "Face", 0.5, 0.5, 0.70, 0.70, COIN, 0.5, nil, 7)
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	local shine = UIKit.piece(box, "Shine", 0.40, 0.36, 0.22, 0.22,
		Color3.fromRGB(255, 244, 190), 0.5, nil, 8)
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	return box
end

local cashCoin = coin(cashPill, 18)
cashCoin.Position = UDim2.new(0, 8, 0.5, 0)

local cashLabel = UIKit.outlined(cashPill, "Amount", 16, MONEY, 2)
cashLabel.Position = UDim2.fromOffset(30, 0)
cashLabel.Size = UDim2.new(1, -38, 1, 0)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.TextTruncate = Enum.TextTruncate.AtEnd
cashLabel.Text = "$0"
cashLabel.ZIndex = 6

--==============================================================================
-- THE ROW DIVIDES ITSELF
--
-- Three tabs and a balance across whatever width there is: the pill takes its
-- share, the tabs split the rest, and the gap between them is what is left. At
-- 490 that is the comfortable 58-pixel tabs the desktop panel had; at 270 it is
-- 46, which is still a thumb-sized target at 34 tall and, more to the point, is
-- a tab that is actually on the screen.
--==============================================================================
local function sizeFilters()
	local rowW = filterRow.AbsoluteSize.X
	if rowW <= 0 then
		return
	end
	local pillW = math.clamp(math.floor(rowW * 0.40), 84, 118)
	local tabW = math.clamp(math.floor((rowW - pillW - 16) / 3) - 4, 40, 58)
	local pitch = tabW + 4
	cashPill.Size = UDim2.fromOffset(pillW, 34)
	for i, b in ipairs(tabFrames) do
		b.Position = UDim2.fromOffset((i - 1) * pitch, 2)
		b.Size = UDim2.fromOffset(tabW, 34)
	end
end

filterRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeFilters)

--==============================================================================
-- THE SHELF
--
-- The only thing on the panel that scrolls.
--==============================================================================
modal.body.Position = UDim2.fromOffset(12, BODY_TOP)
modal.body.Size = UDim2.new(1, -24, 1, -(BODY_TOP + 12))

local list = Instance.new("ScrollingFrame")
list.Name = "Shelf"
list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollingDirection = Enum.ScrollingDirection.Y
-- VISIBLE, and thick enough to grab with a thumb. The default 12 is a desktop
-- number and 4 -- what the plot shop uses -- is a hairline on a phone.
list.ScrollBarThickness = 7
list.ScrollBarImageColor3 = PANEL.Edge
list.ScrollBarImageTransparency = 0.1
list.ElasticBehavior = Enum.ElasticBehavior.Always
list.ZIndex = 4
list.Parent = modal.body

local listPad = Instance.new("UIPadding")
listPad.PaddingRight = UDim.new(0, 10)
listPad.PaddingBottom = UDim.new(0, 10)
listPad.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 12)
listLayout.Parent = list

--==============================================================================
-- ONE CARD
--
-- Horizontal: a square preview on the left, the name and a sentence beside it,
-- three stats under that, and the price and the button on the right -- or under
-- the stats when the panel is too narrow to hold a second column.
--
-- NOTHING IN A CARD IS ROTATED. UIKit's own note: a rotated child escapes
-- ClipsDescendants, and a half-scrolled card once threw its texture three
-- hundred pixels across the panel below it. So no lattice, no diamonds, and the
-- leaves stay up in the header where nothing scrolls.
--==============================================================================
type Card = {
	item: WeaponData.Item,
	holder: Frame,
	stage: Frame,
	name: TextLabel,
	badge: Frame,
	badgeText: TextLabel,
	blurb: TextLabel,
	stats: Frame,
	priceRow: Frame,
	priceText: TextLabel,
	action: TextButton,
	actionLabel: TextLabel,
	actionShade: Frame,
	textLeft: number,
}

local cards: { Card } = {}

local function statChip(parent: GuiObject, index: number, line: WeaponData.StatLine): Frame
	local chip = Instance.new("Frame")
	chip.Name = "Stat" .. index
	-- FRACTIONAL, so three of them can never add up to more than the row they
	-- are in. A fixed pixel width is how a stat row overflows on a phone.
	chip.Position = UDim2.fromScale((index - 1) / 3, 0)
	chip.Size = UDim2.new(1 / 3, -5, 1, 0)
	chip.BackgroundColor3 = PANEL.Shade
	chip.BackgroundTransparency = 0.15
	chip.BorderSizePixel = 0
	chip.ZIndex = 6
	chip.Parent = parent
	UIKit.corner(chip, 6)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.fromOffset(6, 2)
	label.Size = UDim2.new(1, -10, 0, 11)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 10
	label.TextColor3 = MUTED
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = line.label
	label.ZIndex = 7
	label.Parent = chip

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Position = UDim2.fromOffset(6, 13)
	value.Size = UDim2.new(1, -10, 0, 14)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.FredokaOne
	value.TextSize = 13
	value.TextColor3 = CREAM
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.Text = line.value
	value.ZIndex = 7
	value.Parent = chip
	return chip
end

local function buildCard(item: WeaponData.Item): Card
	local pal = item.Palette

	local holder = Instance.new("Frame")
	holder.Name = item.Id
	holder.LayoutOrder = item.Order
	holder.Size = UDim2.new(1, 0, 0, 120)
	holder.BackgroundColor3 = pal.CardEdge
	holder.BorderSizePixel = 0
	holder.ZIndex = 4
	holder.Parent = list
	UIKit.corner(holder, 12)
	UIKit.stroke(holder, BLACK, 3)

	-- THE BEVEL. An inset fill two pixels in from the edge colour, a light line
	-- along its top and a dark one along its bottom. Three frames, and it is the
	-- whole difference between a card and a coloured rectangle.
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Position = UDim2.fromOffset(3, 3)
	fill.Size = UDim2.new(1, -6, 1, -6)
	fill.BackgroundColor3 = WHITE
	fill.BorderSizePixel = 0
	fill.ZIndex = 5
	fill.Parent = holder
	UIKit.corner(fill, 10)
	UIKit.gradient(fill, pal.Card:Lerp(WHITE, 0.10), pal.Card:Lerp(BLACK, 0.22))

	local topLight = Instance.new("Frame")
	topLight.Name = "Bevel"
	topLight.Position = UDim2.fromOffset(10, 1)
	topLight.Size = UDim2.new(1, -20, 0, 2)
	topLight.BackgroundColor3 = pal.CardEdge:Lerp(WHITE, 0.45)
	topLight.BackgroundTransparency = 0.35
	topLight.BorderSizePixel = 0
	topLight.ZIndex = 6
	topLight.Parent = fill

	--== THE PREVIEW, IN ITS OWN LITTLE ROOM ==--
	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.Position = UDim2.fromOffset(10, 10)
	stage.Size = UDim2.fromOffset(78, 78)
	stage.BackgroundColor3 = WHITE
	stage.BorderSizePixel = 0
	stage.ClipsDescendants = true
	stage.ZIndex = 6
	stage.Parent = fill
	UIKit.corner(stage, 9)
	UIKit.stroke(stage, BLACK, 2)
	-- ITS OWN PALETTE. Seven cards down a column is seven places rather than one
	-- wall, and the backdrop is the cheapest way to say so -- it is the item's
	-- own accent, taken right down into shadow.
	UIKit.gradient(stage, pal.Card:Lerp(pal.Accent, 0.30), pal.Card:Lerp(BLACK, 0.42))

	local glowSpot = Instance.new("Frame")
	glowSpot.Name = "Spot"
	glowSpot.AnchorPoint = Vector2.new(0.5, 0.5)
	glowSpot.Position = UDim2.fromScale(0.5, 0.38)
	glowSpot.Size = UDim2.fromScale(0.86, 0.62)
	glowSpot.BackgroundColor3 = pal.Accent
	glowSpot.BackgroundTransparency = 0.86
	glowSpot.BorderSizePixel = 0
	glowSpot.ZIndex = 6
	glowSpot.Parent = stage
	UIKit.corner(glowSpot, 40)

	local hero = Instance.new("ViewportFrame")
	hero.Name = "Hero"
	hero.Size = UDim2.fromScale(1, 1)
	hero.BackgroundTransparency = 1
	hero.BorderSizePixel = 0
	hero.Active = false
	hero.Ambient = GameConfig.Card.Ambient
	hero.LightColor = GameConfig.Card.LightColour
	hero.LightDirection = GameConfig.Card.LightDirection
	hero.ZIndex = 7
	hero.Parent = stage

	--==========================================================================
	-- THE ACTUAL WEAPON, BUILT ONCE AND LEFT STANDING
	--
	-- The same WeaponModel.BuildPreview a Tool comes out of, so the picture
	-- cannot drift from the product. STATIC: no orbit, no idle, no per-frame
	-- work at all -- one camera write at build and never again.
	--
	-- That is deliberate rather than lazy. IndexUI refused ViewportFrames on the
	-- grounds that five live creatures behind a panel is a hundred and seventy
	-- parts of CAMERA WORK on a phone; the cost it was refusing was the
	-- animation, not the frame. Seven still weapons at a dozen parts each is
	-- roughly half the instance count and none of the per-frame cost.
	--
	-- The weapon lies along +Y from its grip, so it is looked at from the side
	-- and slightly above rather than from the three-quarter angle a plant with a
	-- face wants.
	--==========================================================================
	local built = WeaponModel.BuildPreview(item, hero)
	--==========================================================================
	-- A BAT LIES DIAGONALLY. THE TRAP LIES FLAT.
	--
	-- A weapon is six studs tall and under two wide, and a square card framed
	-- around its bounding diagonal therefore spends most of itself on empty air
	-- either side -- which is exactly what the first render looked like: a thin
	-- dark stick in the middle of a big box.
	--
	-- Tipped 34 degrees the same object's box is nearly square, so the framer
	-- can come in close and the weapon fills the card. It is also how a weapon
	-- is drawn in every shop that has ever sold one, for the same reason.
	--
	-- Rotated about the GRIP, which is the model pivot and sits at the origin,
	-- so the whole thing swings as one and the framer re-measures whatever box
	-- results. The trap is already wider than it is tall and is left alone.
	--==========================================================================
	-- ONE FRAMING RULE, IN UIKit. This was the shop's own branch; the inventory
	-- and the hotbar need the identical pose and camera, and three copies is how
	-- three surfaces end up drawing the same bat three ways. The numbers moved
	-- unchanged, so the approved card looks exactly as it did.
	UIKit.frameItem(hero, built, item.Category)

	--== NAME, BADGE, SENTENCE ==--
	local nameLabel = UIKit.outlined(fill, "Name", 18, CREAM, 3)
	nameLabel.Position = UDim2.fromOffset(98, 8)
	nameLabel.Size = UDim2.new(1, -180, 0, 24)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = item.Name
	nameLabel.ZIndex = 7

	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -10, 0, 10)
	badge.Size = UDim2.fromOffset(70, 18)
	badge.BackgroundColor3 = pal.Accent
	badge.BorderSizePixel = 0
	badge.ZIndex = 7
	badge.Parent = fill
	UIKit.corner(badge, 6)
	UIKit.stroke(badge, BLACK, 2)

	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "Text"
	badgeText.Size = UDim2.fromScale(1, 1)
	badgeText.BackgroundTransparency = 1
	badgeText.Font = Enum.Font.FredokaOne
	badgeText.TextSize = 11
	badgeText.TextColor3 = BLACK
	badgeText.TextTruncate = Enum.TextTruncate.AtEnd
	badgeText.Text = item.Badge
	badgeText.ZIndex = 8
	badgeText.Parent = badge

	local blurb = Instance.new("TextLabel")
	blurb.Name = "Blurb"
	blurb.Position = UDim2.fromOffset(98, 32)
	blurb.Size = UDim2.new(1, -180, 0, 32)
	blurb.BackgroundTransparency = 1
	blurb.Font = Enum.Font.FredokaOne
	blurb.TextSize = 12
	blurb.TextColor3 = MUTED
	blurb.TextWrapped = true
	blurb.TextXAlignment = Enum.TextXAlignment.Left
	blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.Text = item.Blurb
	blurb.ZIndex = 7
	blurb.Parent = fill

	--== THE THREE STATS ==--
	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.Position = UDim2.fromOffset(98, 68)
	stats.Size = UDim2.new(1, -180, 0, 30)
	stats.BackgroundTransparency = 1
	stats.ClipsDescendants = true
	stats.ZIndex = 6
	stats.Parent = fill
	for i, line in ipairs(WeaponData.StatLines(item)) do
		statChip(stats, i, line)
	end

	--== PRICE AND BUTTON ==--
	local priceRow = Instance.new("Frame")
	priceRow.Name = "Price"
	priceRow.AnchorPoint = Vector2.new(1, 0)
	priceRow.Position = UDim2.new(1, -10, 0, 34)
	priceRow.Size = UDim2.fromOffset(112, 22)
	priceRow.BackgroundTransparency = 1
	priceRow.ZIndex = 7
	priceRow.Parent = fill

	local priceCoin = coin(priceRow, 16)
	priceCoin.Position = UDim2.new(0, 0, 0.5, 0)

	local priceText = UIKit.outlined(priceRow, "Amount", 16, MONEY, 2)
	priceText.Position = UDim2.fromOffset(21, 0)
	priceText.Size = UDim2.new(1, -21, 1, 0)
	priceText.TextXAlignment = Enum.TextXAlignment.Left
	priceText.TextTruncate = Enum.TextTruncate.AtEnd
	priceText.Text = WeaponData.PriceText(item)
	priceText.ZIndex = 8

	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.AnchorPoint = Vector2.new(1, 0)
	action.Position = UDim2.new(1, -10, 0, 62)
	-- 112 x 36. Comfortably over the 44-pixel touch minimum on its short axis
	-- once the card padding round it is counted, and wide enough for EQUIPPED.
	action.Size = UDim2.fromOffset(112, 36)
	action.BackgroundColor3 = GameConfig.Shop.Buy
	action.BorderSizePixel = 0
	action.AutoButtonColor = false
	action.Text = ""
	action.ZIndex = 7
	UIKit.clicks(action)
	action.Parent = fill
	UIKit.corner(action, 9)
	UIKit.stroke(action, BLACK, 3)

	local actionShade = Instance.new("Frame")
	actionShade.Name = "Shade"
	actionShade.AnchorPoint = Vector2.new(0.5, 1)
	actionShade.Position = UDim2.new(0.5, 0, 1, 0)
	actionShade.Size = UDim2.new(1, 0, 0, 7)
	actionShade.BackgroundColor3 = GameConfig.Shop.BuyShade
	actionShade.BorderSizePixel = 0
	actionShade.ZIndex = 7
	actionShade.Parent = action
	UIKit.corner(actionShade, 9)

	local actionLabel = UIKit.outlined(action, "Label", 16, WHITE, 2)
	actionLabel.Size = UDim2.fromScale(1, 1)
	actionLabel.Text = "BUY"
	actionLabel.ZIndex = 9

	return {
		item = item,
		holder = holder,
		stage = stage,
		name = nameLabel,
		badge = badge,
		badgeText = badgeText,
		blurb = blurb,
		stats = stats,
		priceRow = priceRow,
		priceText = priceText,
		action = action,
		actionLabel = actionLabel,
		actionShade = actionShade,
		textLeft = 98,
	}
end

for _, item in ipairs(WeaponData.Items) do
	table.insert(cards, buildCard(item))
end

--==============================================================================
-- RESPONSIVE, IN TWO SHAPES
--
-- Wide: preview, text, and a right-hand column with the price over the button.
-- Narrow: the same preview and text, with the price and the button on their own
-- row across the bottom -- because a 112-pixel column beside a 78-pixel preview
-- inside a 224-pixel card leaves 34 pixels for a name, and 34 pixels of name is
-- a name that is not there.
--
-- Driven off the LIST's own AbsoluteSize rather than the screen's, so it is
-- right for a phone turning sideways, a desktop window being dragged, and the
-- modal's own open tween -- all of which are resizes and none of which is a
-- rebuild.
--==============================================================================
local function relayout()
	local width = list.AbsoluteSize.X - 10
	if width <= 0 then
		return
	end
	local narrow = width < NARROW_AT

	modal.title.TextSize = if narrow then 17 else 22
	for _, leaf in ipairs(leafFrames) do
		leaf.Visible = not narrow
	end

	for _, card in ipairs(cards) do
		--======================================================================
		-- EVERY PIXEL THE PHONE CAN SPARE GOES TO THE NAME
		--
		-- The first mobile pass left 96 pixels for it and "ROOTWOOD BAT" needs
		-- about 130 at TextSize 18 -- so every card on the shelf read
		-- "ROOTWO...", which is the one thing on a product card that must never
		-- be an ellipsis. Three things give it back: a smaller preview (56
		-- against 78), a tighter gutter, and a 16-point face. That is 130
		-- pixels against the 115 the longest name in the shop needs.
		--======================================================================
		local art = if narrow then 56 else 78
		local left = art + (if narrow then 12 else 20)
		local rightW = 112
		local textW = if narrow then (width - left - 16) else (width - left - rightW - 26)

		card.stage.Size = UDim2.fromOffset(art, art)
		card.name.TextSize = if narrow then 16 else 18
		card.name.Position = UDim2.fromOffset(left, 8)
		card.blurb.Position = UDim2.fromOffset(left, if narrow then 30 else 32)
		card.stats.Position = if narrow
			then UDim2.fromOffset(10, 84)
			else UDim2.fromOffset(left, 68)
		card.stats.Size = if narrow
			then UDim2.new(1, -20, 0, 30)
			else UDim2.new(0, textW, 0, 30)

		--======================================================================
		-- THE BADGE ONLY EATS INTO THE NAME WHEN THEY SHARE A LINE
		--
		-- Wide, the badge sits above the PRICE COLUMN -- both are anchored to the
		-- card's right edge and the text column already stops short of it, so
		-- there is nothing to subtract and subtracting anyway is what truncated
		-- "SUNFLOWER BONKER" to "SUNFLOWER..." in the first screenshot.
		--
		-- Narrow, the text column runs all the way to that edge and the two
		-- genuinely do share the line, so there the subtraction is real. Both
		-- are TextTruncate.AtEnd either way, so the worst case is an ellipsis
		-- rather than two words on top of each other.
		--======================================================================
		local badgeW = if narrow then 50 else 70
		card.badge.Size = UDim2.fromOffset(badgeW, 18)
		card.name.Size = UDim2.new(0,
			math.max(40, if narrow then (textW - badgeW - 6) else textW), 0, 24)
		-- Three lines on a phone, two on a desktop. The sentence is the same
		-- length either way and a narrower column needs another line for it.
		card.blurb.Size = UDim2.new(0, math.max(40, textW), 0, if narrow then 46 else 32)

		if narrow then
			card.priceRow.AnchorPoint = Vector2.new(0, 0)
			card.priceRow.Position = UDim2.fromOffset(10, 122)
			card.action.AnchorPoint = Vector2.new(1, 0)
			card.action.Position = UDim2.new(1, -10, 0, 120)
			local btnW = math.floor(math.clamp(width * 0.42, 96, 124))
			card.action.Size = UDim2.fromOffset(btnW, 36)
			-- Whatever the button does not take, minus a gap it cannot close.
			card.priceRow.Size = UDim2.fromOffset(math.max(60, width - btnW - 30), 30)
			card.holder.Size = UDim2.new(1, 0, 0, 168)
		else
			card.priceRow.AnchorPoint = Vector2.new(1, 0)
			card.priceRow.Position = UDim2.new(1, -10, 0, 32)
			card.priceRow.Size = UDim2.fromOffset(rightW, 24)
			card.action.AnchorPoint = Vector2.new(1, 0)
			card.action.Position = UDim2.new(1, -10, 0, 62)
			card.action.Size = UDim2.fromOffset(rightW, 36)
			card.holder.Size = UDim2.new(1, 0, 0, 120)
		end
	end
end

list:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
relayout()
sizeFilters()

--==============================================================================
-- WHAT THE SERVER SAYS
--==============================================================================
local owned: { [string]: boolean } = {}
--==============================================================================
-- ONE SLOT PER CATEGORY, READ THE SAME WAY THE SERVER STORES THEM
--
-- This was a single `equipped` string. A player may now have a bat AND a trap
-- ready at once, so a card is EQUIPPED when it matches the slot ITS OWN
-- category names -- which is why pressing EQUIP on a trap leaves the bat card
-- alone, with no bookkeeping here to get wrong.
--==============================================================================
local loadout: { [string]: string } = { bat = "", trap = "" }
local function equippedIn(category: string): string
	return loadout[category] or ""
end
local cash = 0
local heard = false
local pending: string? = nil

local function affordable(item: WeaponData.Item): boolean
	return cash >= item.Price
end

--==============================================================================
-- PAINT
--
-- STATE ONLY. Nothing is created, destroyed, moved or resized in here, which is
-- what makes "the scroll position survives a purchase" true rather than
-- something restored afterwards: the canvas does not change, so there is nothing
-- for the scroll to be clamped against.
--
-- The position is captured and put back anyway, because the filter tabs DO
-- change the canvas and a purchase that happened to land in the same frame as a
-- filter change would otherwise jump.
--==============================================================================
local function paint()
	local keep = list.CanvasPosition

	cashLabel.Text = "$" .. GameConfig.compact(cash)

	for _, tab in ipairs(TABS) do
		local b = tabButtons[tab.id]
		local on = activeFilter == tab.id
		b.BackgroundColor3 = if on then RAIL.ShopFace else PANEL.Shade
		local label = b:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.TextColor3 = if on then WHITE else MUTED
		end
	end

	for _, card in ipairs(cards) do
		local item = card.item
		card.holder.Visible = activeFilter == "all" or activeFilter == item.Category

		local isOwned = owned[item.Id] == true
		local isEquipped = equippedIn(item.Category) == item.Id

		if pending == item.Id then
			card.actionLabel.Text = "..."
			card.action.BackgroundColor3 = GameConfig.Shop.BuyShade
			card.actionShade.BackgroundColor3 = GameConfig.Shop.BuyShade
			card.priceText.Text = WeaponData.PriceText(item)
			card.priceText.TextColor3 = MUTED
		elseif isEquipped then
			card.actionLabel.Text = "EQUIPPED"
			card.action.BackgroundColor3 = EQUIPPED_FACE
			card.actionShade.BackgroundColor3 = EQUIPPED_SHADE
			card.priceText.Text = "OWNED"
			card.priceText.TextColor3 = CREAM
		elseif isOwned then
			card.actionLabel.Text = "EQUIP"
			card.action.BackgroundColor3 = GameConfig.Shop.Buy
			card.actionShade.BackgroundColor3 = GameConfig.Shop.BuyShade
			card.priceText.Text = "OWNED"
			card.priceText.TextColor3 = CREAM
		else
			card.actionLabel.Text = "BUY"
			--==============================================================
			-- A PRICE YOU CANNOT MEET IS STILL A PRICE
			--
			-- It stays green and readable and the BUTTON goes dark, rather
			-- than greying the number out. What a player wants off an
			-- unaffordable card is the figure they are saving toward; what
			-- they want off the button is "not yet".
			--==============================================================
			local can = affordable(item) and heard
			card.action.BackgroundColor3 = if can then GameConfig.Shop.Buy else LOCKED
			card.actionShade.BackgroundColor3 = if can
				then GameConfig.Shop.BuyShade
				else LOCKED:Lerp(BLACK, 0.35)
			card.priceText.Text = WeaponData.PriceText(item)
			card.priceText.TextColor3 = MONEY
		end

		-- Owned cards keep their own colour. An owned weapon is still the
		-- weapon it was, and greying the whole card out would hide the picture
		-- the player paid for.
		card.stage.BackgroundTransparency = 0
	end

	list.CanvasPosition = keep
end

--==============================================================================
-- THE WIRE
--==============================================================================
local remotes = SeedGame:WaitForChild("Remotes", 20)
local channel: RemoteEvent? = nil
if remotes then
	local ev = remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
	if ev and ev:IsA("RemoteEvent") then
		channel = ev
	end
end
if not channel then
	warn("[Seed/MarigoldShopUI] No GameEvent remote; nothing can be bought.")
end

local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local changed = false

	if type(profile.Weapons) == "table" then
		for _, item in ipairs(WeaponData.Items) do
			local now = profile.Weapons[item.Id] == true
			if now ~= (owned[item.Id] == true) then
				owned[item.Id] = now
				changed = true
			end
		end
	end
	for _, category in ipairs({ "bat", "trap" }) do
		local field = if category == "bat" then "EquippedBat" else "EquippedTrap"
		local value = (profile :: any)[field]
		if type(value) == "string" and value ~= loadout[category] then
			loadout[category] = value
			changed = true
		end
	end
	if type(profile.Cash) == "number" then
		-- Only repaint when the balance crosses a price. Cash moves several
		-- times a second and a repaint per packet is a repaint per packet for
		-- nothing.
		for _, item in ipairs(WeaponData.Items) do
			if (cash >= item.Price) ~= (profile.Cash >= item.Price) then
				changed = true
			end
		end
		cash = profile.Cash
		-- The header number itself does have to move every time.
		cashLabel.Text = "$" .. GameConfig.compact(cash)
	end
	if not heard then
		heard = true
		changed = true
	end
	--==========================================================================
	-- THE ANSWER, WHICHEVER WAY IT WENT
	--
	-- A success arrives as a changed profile; a refusal arrives as nothing at
	-- all and this is simply the next routine packet. Both clear the press,
	-- because a button stuck on "..." is worse than one that flickers.
	--==========================================================================
	if pending ~= nil then
		pending = nil
		changed = true
	end
	if changed then
		paint()
	end
end

if remotes then
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
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
local BACK_ACTION = "SeedMarigoldBack"
local rangeConn: RBXScriptConnection? = nil
local deathConns: { RBXScriptConnection } = {}

local function marigoldRoot(): BasePart?
	for _, model in ipairs(CollectionService:GetTagged(GameConfig.Tags.Fairy)) do
		if model:IsA("Model") and model.Parent then
			local part = model.PrimaryPart or model:FindFirstChild("Torso")
			if part and part:IsA("BasePart") then
				return part
			end
		end
	end
	return nil
end

local setOpen: (boolean) -> ()

local function bindClosers()
	--==========================================================================
	-- ESCAPE, BACK, AND THE ROBLOX MENU
	--
	-- Escape is CoreGui's, and whether an experience gets to see it first has
	-- changed more than once across engine versions -- so it is bound here AND
	-- the menu opening is treated as a back gesture. Whichever of the two the
	-- engine actually delivers, the panel closes.
	--
	-- Backspace and the gamepad B button are bound because they are what "back"
	-- means on a keyboard and on a controller. On a phone the back gesture is a
	-- tap outside the panel, which the dimmer already is.
	--
	-- BOUND ONLY WHILE OPEN, and unbound on close. A permanent binding on
	-- Escape would eat the pause menu for the whole session.
	--==========================================================================
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			setOpen(false)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)

	--== WALKING AWAY SHUTS IT ==--
	rangeConn = RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local her = marigoldRoot()
		if not (root and root:IsA("BasePart")) then
			setOpen(false)
			return
		end
		if her and (root.Position - her.Position).Magnitude > W.CloseDistance then
			setOpen(false)
		end
	end)

	--== DYING SHUTS IT ==--
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		table.insert(deathConns, humanoid.Died:Connect(function()
			setOpen(false)
		end))
	end
	table.insert(deathConns, player.CharacterRemoving:Connect(function()
		setOpen(false)
	end))
end

local function unbindClosers()
	pcall(function()
		ContextActionService:UnbindAction(BACK_ACTION)
	end)
	if rangeConn then
		rangeConn:Disconnect()
		rangeConn = nil
	end
	for _, c in ipairs(deathConns) do
		c:Disconnect()
	end
	table.clear(deathConns)
end

setOpen = function(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		--======================================================================
		-- NOTHING ABOUT MOVEMENT OR THE CAMERA IS TOUCHED
		--
		-- No mouse lock, no ModalEnabled, no ControlModule call, no walk speed.
		-- A player can walk away from Marigold with the shop open and it closes
		-- itself -- which is also why nothing can be left stuck when it does.
		-- The only thing this panel owns is a ScreenGui and one key binding, and
		-- both are released on the way out.
		--======================================================================
		bindClosers()
		paint()
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		unbindClosers()
	end
	modal.setOpen(want)
end

modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)
GuiService.MenuOpened:Connect(function()
	setOpen(false)
end)

--==============================================================================
-- ONE CENTRE PANEL AT A TIME
--
-- The same mutex the Index, the Shop and the Garden use: each writes its own
-- name to OpenPanel and closes on seeing a name that is not its own. Neither
-- script has to know the other exists.
--==============================================================================
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)

--==============================================================================
-- THE TABS
--==============================================================================
for _, tab in ipairs(TABS) do
	tabButtons[tab.id].Activated:Connect(function()
		if activeFilter == tab.id then
			return
		end
		activeFilter = tab.id
		-- A filter change is the one place the canvas legitimately changes
		-- height, so the list goes back to the top rather than to wherever the
		-- previous filter had been scrolled.
		list.CanvasPosition = Vector2.zero
		paint()
	end)
end

--==============================================================================
-- BUY AND EQUIP, WHICH ARE THE SAME BUTTON
--
-- One press, three meanings, and the SERVER decides which one happened. The
-- panel sends BUY for something it believes is unowned and EQUIP for something
-- it believes is owned -- and if it has that backwards, the server refuses the
-- verb it was sent rather than doing the other one.
--==============================================================================
for _, card in ipairs(cards) do
	card.action.Activated:Connect(function()
		local item = card.item
		if not channel or not heard or pending ~= nil then
			SoundKit.play("Denied")
			return
		end
		if equippedIn(item.Category) == item.Id then
			--==================================================================
			-- PRESSING EQUIPPED PUTS THAT ONE AWAY, AND ONLY THAT ONE
			--
			-- The category travels because "" names no item and therefore names
			-- no slot. Sending it without one would be asking the server to
			-- guess which drawer to empty.
			--==================================================================
			pending = item.Id
			paint()
			channel:FireServer(W.EquipAction, "", item.Category)
			return
		end
		if owned[item.Id] then
			pending = item.Id
			paint()
			channel:FireServer(W.EquipAction, item.Id)
			return
		end
		if not affordable(item) then
			SoundKit.play("Denied")
			return
		end
		pending = item.Id
		paint()
		channel:FireServer(W.BuyAction, item.Id)
	end)
end

--==============================================================================
-- THE PROMPT SAYS WHEN
--
-- The server fires this when somebody finishes the hold on Marigold. It is the
-- only thing that opens the panel: a client that decided for itself when it was
-- close enough would make "the shop is open" a claim rather than a fact.
--
-- A REFUSAL from anywhere in the weapon system arrives on the same wire as the
-- verb plus false, and makes a noise. That is the only feedback a refused trap
-- placement has -- a trap that will not go down looks exactly like a trap tool
-- that is broken.
--==============================================================================
if channel then
	channel.OnClientEvent:Connect(function(action: any, ok: any)
		if action == W.ShopAction and ok == true then
			setOpen(true)
		elseif ok == false and (action == W.BuyAction or action == W.EquipAction
			or action == W.DeniedAction) then
			SoundKit.play("Denied")
			if pending ~= nil then
				pending = nil
				paint()
			end
		end
	end)
end

paint()
