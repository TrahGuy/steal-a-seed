--!strict
-- Steal a Seed :: ShopUI
--
-- The shop. Its button is on the left rail under the Index (a dock tile on a
-- phone); the panel opens in the middle of the screen.
--
--==============================================================================
-- COMPACT, IN THE INVENTORY'S LOOK (2026-10-03, the owner's redesign), AND ONE
-- PAGE (2026-10-06, the owner: "make the shop just one scrollable page")
--
--   header      one short row: the title, REWARDS & ODDS while this player may
--               buy Spin Tickets, the close
--   the page    every shelf on one scrolling list, derived, never invented
--               (ShopCatalog): one per configured shelf in GameConfig.Store, in
--               its order and under its heading, then Spin Tickets while this
--               player may buy them -- over a studded baseplate that stands still
--               behind it (MenuKit.baseplate). From 2026-10-03 to 2026-10-06 it
--               showed one shelf at a time, chosen in a dropdown or a sidebar.
--   cards       the product's own uploaded icon, its label, the exact amount
--               or benefit in words, and ONE buy button -- a row on a phone's
--               two columns, a small tile on a desktop's three
--   details     tapping a card (not its button) opens its longer words, and a
--               pass's card art, IN the panel with Back
--
-- The buy button keeps the approved face: lime, a white capsule, the Robux mark
-- and this player's price. Its other faces: SOON (a product not created yet:
-- refuses), OFF SALE, OWNED (a pass this account has), and OPENING (a purchase
-- prompt is up -- every other button waits until it closes, so two prompts are
-- never asked for at once).
--
-- WHERE IT STANDS is MenuLayout's: between the rails on a desktop (they stay
-- pressable), the whole safe area on a phone -- and then the rail layer steps
-- under the panel while it is open (UIKit.coverRail), so nothing of the HUD's
-- stands over a buy button or takes its tap.
--
--==============================================================================
-- ONE CENTRE PANEL AT A TIME
--
-- The Index, the Garden and this all open in the same rectangle, so they take
-- turns: each writes its own name to the OpenPanel attribute and closes on
-- seeing a name that is not its own.
--
--==============================================================================
-- THE CLIENT ONLY EVER ASKS
--
-- A Robux purchase is a prompt to Roblox and a receipt to the server. Nothing in
-- this file grants, charges or remembers anything: StoreService decides what a
-- product gives (its one ProcessReceipt), PassService what a player owns, and
-- WheelService whether a Spin Ticket prompt opens at all. Everything here is
-- presentation -- which card looks buyable, what its price says, whether its
-- button answers.
--==============================================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local RobuxPrice = require(Shared:WaitForChild("RobuxPrice"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local WheelData = require(Shared:WaitForChild("WheelData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOP = GameConfig.Shop
local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local LOOK = MenuKit.Look
local PANEL_NAME = "Shop"

-- The one dark in the shop: every keyline, every outline, the price on its capsule.
local INK = SHOP.Ink

local SH = MenuLayout.Shop
local CARD_GAP = SH.CardGap
local GRID_INSET = SH.GridInset
local ROW_H = SH.RowH
local BUY_W = SH.BuyW
-- How long OPENING may stand with no word from Roblox before the buttons free.
local PROMPT_PATIENCE = 30

local Z = 6

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
-- THE RAIL BUTTON
--
-- The owner's approved artwork (2026-09-24): the blue cart and the word in one
-- square picture, with the rainbow turning in its rim (UIKit.rainbowRim) --
-- the one rail button that moves, because it is the one the owner wants found.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "ShopButton",
	art = RAIL.ShopArt,
	rim = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset + RAIL.WideSize.Y + RAIL.Gap)

-- Second on the rail, from HudLayout: under Index on a desktop, beside it in
-- the compact top row; on a touch screen the top-left corner (2026-10-05).
-- Wherever its slot is wide -- a desktop's and a TV's rail, a phone's corner --
-- it is the owner's wide studded picture, its own outline in place of the rim;
-- a small window's compact row has only a square for it, which keeps ShopArt.
local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	UIKit.railShape(button, Vector2.new(layout.shop.w, layout.shop.h))
	UIKit.railPicture(button, if layout.shop.w > layout.shop.h then RAIL.StuddedShopArt else nil,
		RAIL.StuddedShopAspect)
	button.Parent = if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)
	button.Position = HudLayout.place(layout.shop, Vector2.zero, layout.safe)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
placeButton()

--==============================================================================
-- THE PANEL
--==============================================================================
-- The approved Shop picture beside the title on the rim (GameConfig.MenuIcons).
local menu = MenuKit.modal(gui, PANEL_NAME, "Shop", GameConfig.MenuIcons.shop, nil)
-- This gui holds only the panel, so it takes the player's menu size whole.
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body
local close = modal.close

local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

--==============================================================================
-- STATE
--==============================================================================
local PAID = WheelData.Attributes.PaidAllowed
local function mayBuy(): boolean
	return player:GetAttribute(PAID) == true
end

local categories = ShopCatalog.categories(mayBuy())
local detailKey: string? = nil
local open = false

-- The purchase prompt that is up, if any: one at a time.
type Busy = { key: string, id: number, kind: string, token: number }
local busy: Busy? = nil
local busyToken = 0
-- Passes this account owns (UserOwnsGamePassAsync; true is never taken back).
local owned: { [number]: boolean } = {}

--==============================================================================
-- THE HEADER'S CONTROLS
--==============================================================================
local paint: () -> ()
local relayout: () -> ()

-- REWARDS & ODDS: the wheel's own sheet of every outcome's odds, one press away
-- before any Spin Ticket purchase.
local odds = MenuKit.button(body, "RewardsAndOdds", Z, "REWARDS & ODDS", 14)
odds.style("sky")
local function openOdds()
	SoundKit.play("CardClick")
	-- The wheel's own sheet: the Shop closes as the wheel's panel opens
	-- (the OpenPanel mutex), and Back returns to the wheel.
	player:SetAttribute(WheelData.OpenOddsAttribute, os.clock())
end
odds.hit.Activated:Connect(openOdds)

--==============================================================================
-- THE PAGE (2026-10-06): every shelf, one list
--
-- A shelf is its heading -- its picture and its name in white on the plate --
-- and under it a grid of its cards; the shelves follow one another down one
-- scrolling list. Behind the list, still while it scrolls, the studded
-- baseplate (MenuKit.baseplate) where a plain light well stood.
--==============================================================================
local plate = MenuKit.baseplate(body, Z - 1)
local grid = Instance.new("ScrollingFrame")
grid.Name = "Products"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 5
grid.ScrollBarImageColor3 = LOOK.PlateEdge
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ElasticBehavior = Enum.ElasticBehavior.Always
grid.Selectable = false
grid.ZIndex = Z
grid.Parent = body
local gridPad = Instance.new("UIPadding")
gridPad.Parent = grid
local pageList = Instance.new("UIListLayout")
pageList.SortOrder = Enum.SortOrder.LayoutOrder
pageList.Padding = UDim.new(0, SH.SectionGap)
pageList.Parent = grid

type Section = { frame: Frame, label: TextLabel, shelf: Frame, cells: UIGridLayout }
local sections: { [string]: Section } = {}
-- One card's size, from MenuLayout.shopCards (relayout); every shelf's grid takes it.
local cardW, cardH = 240, ROW_H

local function shapeSection(section: Section)
	section.cells.CellSize = UDim2.fromOffset(cardW, cardH)
	section.cells.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
end

local function sectionFor(category: ShopCatalog.Category): Section
	local made = sections[category.id]
	if made then
		return made
	end
	local frame = MenuKit.frame(grid, "Section_" .. category.id, Z + 1)
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, SH.HeadingGap)
	list.Parent = frame
	local head = MenuKit.frame(frame, "Heading", Z + 1)
	head.LayoutOrder = 1
	head.Size = UDim2.new(1, 0, 0, SH.HeadingH)
	local icon = MenuKit.picture(head, category.icon, category.fallback, Z + 2)
	icon.Position = UDim2.fromOffset(2, 1)
	icon.Size = UDim2.fromOffset(SH.HeadingH - 2, SH.HeadingH - 2)
	local label = MenuKit.text(head, "Label", 20, LOOK.Text, Z + 2)
	label.Position = UDim2.fromOffset(SH.HeadingH + 6, 0)
	label.Size = UDim2.new(1, -(SH.HeadingH + 10), 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = category.label
	MenuKit.ink(label, Color3.new(1, 1, 1))
	local shelf = MenuKit.frame(frame, "Shelf", Z + 1)
	shelf.LayoutOrder = 2
	shelf.Size = UDim2.new(1, 0, 0, 0)
	shelf.AutomaticSize = Enum.AutomaticSize.Y
	local cells = Instance.new("UIGridLayout")
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Left
	cells.Parent = shelf
	local section: Section = { frame = frame, label = label, shelf = shelf, cells = cells }
	sections[category.id] = section
	shapeSection(section)
	return section
end

--==============================================================================
-- THE BUY BUTTON (the global UI pass, 2026-10-04): MenuKit's green action face
-- -- its foot, its studs, its keyline -- round the white capsule that carries
-- this player's own Robux price. OWNED is the gold state, SOON / OPENING / OFF
-- SALE the grey one: the face says which as well as the word.
--==============================================================================
type Price = {
	button: MenuKit.Button,
	hit: TextButton,
	plate: Frame,
	capsule: Frame,
	token: ImageLabel,
	price: TextLabel,
	word: TextLabel,
}

local function priceButton(parent: Instance, z: number): Price
	local b = MenuKit.button(parent, "Buy", z, "", 15, { studs = true })
	b.style("go")
	local plate = b.plate
	--==========================================================================
	-- THE CAPSULE SIZES ITSELF TO WHAT IS IN IT, and the Robux mark is the
	-- client's own texture (rbxasset://textures/ui/common/robux@3x.png -- no
	-- upload, no glyph), tinted ink; never rotated, because this list scrolls.
	-- It stands in the lit face, above the foot.
	--==========================================================================
	local lit = 1 - GameConfig.BagLook.FootShare
	local capsule = MenuKit.frame(plate, "Capsule", z + 3, SHOP.Capsule, 0, 11)
	capsule.AnchorPoint = Vector2.new(0.5, 0.5)
	capsule.Position = UDim2.new(0.5, 0, lit / 2, 1)
	capsule.Size = UDim2.new(0, 0, lit, -8)
	capsule.AutomaticSize = Enum.AutomaticSize.X
	MenuKit.keyline(capsule, INK, 1, 0.55)
	local capsulePad = Instance.new("UIPadding")
	capsulePad.PaddingLeft = UDim.new(0, 9)
	capsulePad.PaddingRight = UDim.new(0, 9)
	capsulePad.Parent = capsule
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Padding = UDim.new(0, 4)
	row.Parent = capsule
	local token = Instance.new("ImageLabel")
	token.Name = "Token"
	token.LayoutOrder = 1
	token.Size = UDim2.fromOffset(15, 15)
	token.BackgroundTransparency = 1
	token.Image = "rbxasset://textures/ui/common/robux@3x.png"
	token.ImageColor3 = INK
	token.ScaleType = Enum.ScaleType.Fit
	token.ZIndex = z + 4
	token.Parent = capsule
	-- Dark on white needs no outline: an ink stroke round ink type only blurs it.
	local price = Instance.new("TextLabel")
	price.Name = "Price"
	price.LayoutOrder = 2
	price.AutomaticSize = Enum.AutomaticSize.X
	price.Size = UDim2.new(0, 0, 1, 0)
	price.BackgroundTransparency = 1
	price.Font = Enum.Font.LuckiestGuy
	price.TextSize = 16
	price.TextColor3 = INK
	price.Text = ""
	price.ZIndex = z + 4
	price.Parent = capsule
	-- The face's own word (OWNED, OPENING...): MenuKit's label, which inks itself
	-- to the face -- plain dark on gold and grey, white with a thin line on green.
	local word = b.label
	word.Visible = false
	return { button = b, hit = b.hit, plate = plate, capsule = capsule, token = token, price = price, word = word }
end

--==============================================================================
-- THE PRICE IS THIS PLAYER'S, OR IT IS NOT SHOWN
--
-- Roblox prices by region, so a live card asks Roblox, through RobuxPrice, what
-- THIS player would pay, and until it knows it shows three dots beside the
-- Robux mark rather than any number. If Roblox never answers, the capsule says
-- BUY and shows no price at all; OFF SALE if Roblox says so. The button works
-- in every state but OFF SALE's: the purchase prompt is the authority, and it
-- quotes the real price itself.
--==============================================================================
local PRICE_LOADING = "..."
local PRICE_UNKNOWN = "BUY"
local PRICE_OFF_SALE = "OFF SALE"

type Card = {
	entry: ShopCatalog.Entry,
	holder: Frame,
	face: TextButton,
	icon: Frame,
	title: TextLabel,
	titleFit: UITextSizeConstraint,
	benefit: TextLabel,
	buy: Price,
	priceState: string,
	priceValue: number?,
	priced: boolean,
}
local cards: { [string]: Card } = {}

local function busyFor(entry: ShopCatalog.Entry): boolean
	local b = busy
	return b ~= nil and b.key == entry.key
end

local function paintPrice(p: Price, card: Card)
	local entry = card.entry
	local plate, capsule, token, price, word = p.plate, p.capsule, p.token, p.price, p.word
	local function face(id: string)
		p.button.style(id)
	end
	capsule.Visible = true
	word.Visible = false
	capsule.BackgroundColor3 = SHOP.Capsule
	token.ImageColor3 = INK
	price.TextColor3 = INK
	if entry.kind == "soon" then
		--======================================================================
		-- "NOT YET" IS A GREY BUTTON: a price is coming, and the button still
		-- reads as a Robux purchase rather than a free one.
		--======================================================================
		face("off")
		capsule.BackgroundColor3 = SHOP.SoonCapsule
		token.ImageColor3 = SHOP.SoonText
		token.Visible = true
		price.Text = "SOON"
		price.TextColor3 = SHOP.SoonText
	elseif entry.kind == "pass" and owned[entry.id] then
		face("done")
		capsule.Visible = false
		word.Visible = true
		word.Text = "\u{2713} OWNED"
	elseif busyFor(entry) then
		face("off")
		capsule.Visible = false
		word.Visible = true
		word.Text = "OPENING..."
	elseif card.priceState == "offsale" then
		face("off")
		capsule.BackgroundColor3 = SHOP.SoonCapsule
		token.Visible = false
		price.Text = PRICE_OFF_SALE
		price.TextColor3 = SHOP.SoonText
	else
		face("go")
		local value = card.priceValue
		if card.priceState == "ready" and value then
			price.Text = RobuxPrice.format(value)
			token.Visible = true
		elseif card.priceState == "failed" then
			price.Text = PRICE_UNKNOWN
			token.Visible = false
		else
			price.Text = PRICE_LOADING
			token.Visible = true
		end
	end
	plate.BackgroundTransparency = 0
end

local detailBuy: Price
local paintDetail: () -> ()

local function repaintPrices()
	for _, card in pairs(cards) do
		paintPrice(card.buy, card)
	end
	if detailKey then
		paintDetail()
	end
end

local function showPrice(card: Card, kind: RobuxPrice.Kind, id: number)
	RobuxPrice.watch(kind, id, function(state: RobuxPrice.State, value: number?)
		card.priceState = state
		card.priceValue = value
		paintPrice(card.buy, card)
		if detailKey == card.entry.key then
			paintDetail()
		end
	end)
end

--==============================================================================
-- THE LABEL IS TWO COLOURS ON ONE LINE
--
-- The amount green, and gold from GameConfig.Shop.AmountHighFrom up; a row with
-- no amount at all (a pass, a pod) is a premium item and reads gold. The noun
-- is the light plates' dark type. Split at the first space. (On the bright
-- cards of 2026-10-04 the neon amounts and the white noun had no plate dark
-- enough to stand on: these are the same two colours, dark enough to read on
-- white without an outline.)
--==============================================================================
local function twoTone(label: string, amount: number?): string
	local tint = if amount == nil or amount >= SHOP.AmountHighFrom then LOOK.Premium else LOOK.Money
	local head, tail = string.match(label, "^(%S+)%s+(.+)$")
	if not head then
		return string.format('<font color="#%s">%s</font>', tint:ToHex(), label)
	end
	return string.format('<font color="#%s">%s</font> <font color="#%s">%s</font>', tint:ToHex(), head,
		LOOK.Text:ToHex(), tail)
end

-- The same title on a STUDDED card (2026-10-04): the amount warm yellow, the
-- rest the label's own white, the label's ink line round both.
local function studTone(label: string): string
	local head, tail = string.match(label, "^(%S+)%s+(.+)$")
	if not head then
		return label
	end
	return string.format('<font color="#FFE45C">%s</font> %s', head, tail)
end

--==============================================================================
-- PRESSING BUY
--
-- A pass: PromptGamePassPurchase. A product: PromptProductPurchase. A Spin
-- Ticket pack: its KEY to the server (WheelData.Actions.Buy), which asks every
-- question again and opens the prompt itself; the spins come only from the
-- receipt (StoreService). A product not created yet refuses. No optimistic
-- paint, no local grant: what the player gets is decided by the server when
-- Roblox delivers the receipt, and the profile packet that follows updates the
-- HUD. While one prompt is up the buttons wait (OPENING), so two are never
-- asked for at once.
--==============================================================================
local wheelRemote: RemoteEvent? = nil

local function clearBusy(token: number?)
	local b = busy
	if b and (token == nil or b.token == token) then
		busy = nil
		repaintPrices()
	end
end

local function setBusy(entry: ShopCatalog.Entry)
	busyToken += 1
	local token = busyToken
	busy = { key = entry.key, id = entry.id, kind = entry.kind, token = token }
	repaintPrices()
	task.delay(PROMPT_PATIENCE, function()
		clearBusy(token)
	end)
end

local function buy(card: Card)
	local entry = card.entry
	if entry.kind == "soon" or card.priceState == "offsale" then
		-- Prompting with an id of 0 throws, and a thrown error on a click reads
		-- as a broken shop. The refusal noise is the honest answer.
		SoundKit.play("Denied")
		return
	end
	if entry.kind == "pass" and owned[entry.id] then
		SoundKit.play("Denied")
		return
	end
	if busy then
		SoundKit.play("Denied")
		return
	end
	if entry.kind == "spin" then
		local channel = wheelRemote
		if not channel or not mayBuy() then
			SoundKit.play("Denied")
			return
		end
		-- The press cue, and the request: nothing is granted or prompted here.
		SoundKit.play("CardClick")
		setBusy(entry)
		channel:FireServer(WheelData.Actions.Buy, entry.spinKey)
		return
	end
	-- The press cue only on the path that DOES something.
	SoundKit.play("CardClick")
	setBusy(entry)
	local ok, err = pcall(function()
		if entry.kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, entry.id)
		else
			MarketplaceService:PromptProductPurchase(player, entry.id)
		end
	end)
	if not ok then
		warn("[Seed/ShopUI] could not prompt for " .. entry.key .. ": " .. tostring(err))
		SoundKit.play("Denied")
		clearBusy(nil)
	end
end

-- The prompt closing frees the buttons -- bought or not. Whether anything was
-- bought is the receipt's to say, never this.
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, productId: number, _bought: boolean)
	local b = busy
	if userId == player.UserId and b and b.id == productId then
		clearBusy(b.token)
	end
end)

--==============================================================================
-- A PASS THIS ACCOUNT OWNS SAYS SO
--
-- Asked of Roblox for this account (a web call: pcall, and a failure changes
-- nothing), at the start, whenever PassService publishes a new multiplier, and
-- when a pass prompt closes with a purchase. Presentation only: PassService's
-- own answer is what pays.
--==============================================================================
local function askOwned(passId: number)
	if passId <= 0 or owned[passId] then
		return
	end
	task.spawn(function()
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok and result == true and not owned[passId] then
			owned[passId] = true
			repaintPrices()
		end
	end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who: Player, passId: number, bought: boolean)
	if who ~= player then
		return
	end
	local b = busy
	if b and b.id == passId then
		clearBusy(b.token)
	end
	if bought then
		askOwned(passId)
	end
end)

--==============================================================================
-- ONE CARD
--
-- The face is the card (a tap opens its details); the buy button stands on it
-- and is the only thing that buys. Both are press-guarded: a finger scrolling
-- the list presses neither.
--==============================================================================
local openDetail: (string) -> ()
local rows = true

local function shapeCard(card: Card)
	if rows then
		card.icon.Position = UDim2.fromOffset(8, (cardH - 42) / 2)
		card.icon.Size = UDim2.fromOffset(42, 42)
		local textW = cardW - 58 - BUY_W - 14
		card.title.Position = UDim2.fromOffset(58, 5)
		card.title.Size = UDim2.fromOffset(textW, 21)
		card.benefit.Position = UDim2.fromOffset(58, 27)
		card.benefit.Size = UDim2.fromOffset(textW, cardH - 30)
		card.buy.hit.Position = UDim2.fromOffset(cardW - BUY_W - 8, (cardH - 44) / 2)
		card.buy.hit.Size = UDim2.fromOffset(BUY_W, 44)
	else
		card.icon.Position = UDim2.fromOffset(8, 8)
		card.icon.Size = UDim2.fromOffset(56, 56)
		local textW = cardW - 80
		card.title.Position = UDim2.fromOffset(72, 10)
		card.title.Size = UDim2.fromOffset(textW, 24)
		card.benefit.Position = UDim2.fromOffset(72, 34)
		card.benefit.Size = UDim2.fromOffset(textW, 32)
		card.buy.hit.Position = UDim2.fromOffset(8, cardH - 50)
		card.buy.hit.Size = UDim2.fromOffset(cardW - 16, 44)
	end
end

local liveCount, soonCount = 0, 0

local function cardFor(entry: ShopCatalog.Entry, shelf: Frame): Card
	local made = cards[entry.key]
	if made then
		return made
	end
	local holder = MenuKit.frame(shelf, "Card_" .. entry.key, Z + 1)
	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.ZIndex = Z + 1
	face.Parent = holder
	UIKit.corner(face, 9)
	MenuKit.cardFace(face)
	local edge = MenuKit.keyline(face, LOOK.CardEdge, 1, LOOK.CardEdgeTransparency)
	-- THE COLOURFUL STUDDED CARD (2026-10-04, the owner's reference): its
	-- shelf's upload under everything on it (UIKit.studCard; the solid colour
	-- until the picture has loaded), a dark keyline round it, and the words
	-- white with an ink line. The details view keeps its light sheet.
	local studded = UIKit.studCard(face, 9, Z + 1).set(entry.studs) ~= nil
	if studded then
		edge.Color = LOOK.Ink
		edge.Thickness = 2
		edge.Transparency = 0
	end
	local icon = MenuKit.picture(face, entry.icon, entry.fallback, Z + 2)
	-- A bold card title in plain dark type: no outline on a light card.
	local title = MenuKit.text(face, "Title", 18, LOOK.Text, Z + 3)
	title.RichText = true
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = Z + 3
	local titleFit = Instance.new("UITextSizeConstraint")
	titleFit.MaxTextSize = 18
	titleFit.MinTextSize = 11
	titleFit.Parent = title
	title.Text = if studded then studTone(entry.title) else twoTone(entry.title, entry.amount)
	if studded then
		MenuKit.ink(title, Color3.new(1, 1, 1))
	end
	-- The benefit in the clean body face, wrapped onto two lines where it needs
	-- them (shapeCard gives a row card two); only past that a point smaller.
	local benefit = MenuKit.body(face, "Benefit", 13, LOOK.Muted, Z + 3)
	benefit.TextXAlignment = Enum.TextXAlignment.Left
	benefit.TextYAlignment = Enum.TextYAlignment.Top
	benefit.TextWrapped = true
	benefit.TextScaled = true
	do
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 13
		fit.MinTextSize = 11
		fit.Parent = benefit
	end
	benefit.Text = entry.benefit
	if studded then
		MenuKit.ink(benefit, Color3.new(1, 1, 1))
	end
	local p = priceButton(face, Z + 4)
	local card: Card = {
		entry = entry,
		holder = holder,
		face = face,
		icon = icon,
		title = title,
		titleFit = titleFit,
		benefit = benefit,
		buy = p,
		priceState = "loading",
		priceValue = nil,
		priced = false,
	}
	cards[entry.key] = card
	shapeCard(card)
	local scale = Instance.new("UIScale")
	scale.Parent = face
	UIKit.cardPop(face, scale, { hoverScale = 1.02, pressScale = 0.98, sound = false })
	MenuKit.tap(face, grid, function()
		SoundKit.play("CardClick")
		openDetail(entry.key)
	end, p.hit)
	MenuKit.tap(p.hit, grid, function()
		buy(card)
	end)
	-- Priced the moment it exists, as the old shelves were -- except a Spin
	-- Ticket pack, which Roblox is not asked about until this player may buy.
	if entry.kind == "pass" then
		local passId = entry.id
		showPrice(card, "pass", passId)
		card.priced = true
		askOwned(passId)
		liveCount += 1
	elseif entry.kind == "product" then
		local productId = entry.id
		showPrice(card, "product", productId)
		card.priced = true
		liveCount += 1
	elseif entry.kind == "soon" then
		soonCount += 1
	end
	paintPrice(p, card)
	return card
end

-- Every shelf's cards exist from the start (they are a few frames each), so
-- every live price is asked for at once, as it always was.
for _, category in ipairs(ShopCatalog.categories(false)) do
	local shelf = sectionFor(category).shelf
	for _, entry in ipairs(ShopCatalog.entries(category.id)) do
		cardFor(entry, shelf)
	end
end
if liveCount == 0 then
	warn(string.format(
		"[Seed/ShopUI] Nothing is for sale: %d tile(s) and every product id is 0. "
			.. "Create the Developer Products and fill their ids into GameConfig.Store.",
		soonCount))
end

--==============================================================================
-- THE DETAILS: in the panel, over the grid
--==============================================================================
local detail = MenuKit.frame(body, "Detail", Z + 8, LOOK.Sheet, 0.02, 10)
detail.Active = true
detail.Visible = false
MenuKit.keyline(detail, LOOK.WellEdge, 1, 0.3)
local back = MenuKit.button(detail, "Back", Z + 9, "< BACK", 15)
back.style("sky")
local artBox = MenuKit.frame(detail, "Art", Z + 9, LOOK.Well, LOOK.WellTransparency, 10)
MenuKit.keyline(artBox, LOOK.WellEdge, 1, 0.3)
local artPicture: Frame? = nil
local info = MenuKit.frame(detail, "Info", Z + 9)
local infoList = Instance.new("UIListLayout")
infoList.SortOrder = Enum.SortOrder.LayoutOrder
infoList.Padding = UDim.new(0, 6)
infoList.Parent = info
local detailTitle = MenuKit.text(info, "Title", 24, LOOK.Text, Z + 10)
detailTitle.LayoutOrder = 1
detailTitle.RichText = true
detailTitle.Size = UDim2.new(1, 0, 0, 30)
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.TextScaled = true
detailTitle.ZIndex = Z + 10
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 26
	fit.MinTextSize = 14
	fit.Parent = detailTitle
end
local detailBenefit = MenuKit.body(info, "Benefit", 16, LOOK.Text, Z + 10)
detailBenefit.LayoutOrder = 2
detailBenefit.Size = UDim2.new(1, 0, 0, 20)
detailBenefit.TextXAlignment = Enum.TextXAlignment.Left
local detailWords = MenuKit.body(info, "Words", 14, LOOK.Muted, Z + 10)
detailWords.LayoutOrder = 3
detailWords.Size = UDim2.new(1, 0, 0, 20)
detailWords.AutomaticSize = Enum.AutomaticSize.Y
detailWords.TextWrapped = true
detailWords.TextXAlignment = Enum.TextXAlignment.Left
detailWords.TextYAlignment = Enum.TextYAlignment.Top
local detailRow = MenuKit.frame(info, "Buttons", Z + 10)
detailRow.LayoutOrder = 4
detailRow.Size = UDim2.new(1, 0, 0, 44)
detailBuy = priceButton(detailRow, Z + 11)
detailBuy.hit.Size = UDim2.fromOffset(150, 44)
local detailOdds = MenuKit.button(detailRow, "DetailOdds", Z + 11, "REWARDS & ODDS", 14)
detailOdds.style("sky")
detailOdds.hit.Position = UDim2.fromOffset(158, 0)
detailOdds.hit.Size = UDim2.fromOffset(160, 44)
detailOdds.hit.Activated:Connect(openOdds)

paintDetail = function()
	local key = detailKey
	local card = if key then cards[key] else nil
	if not card then
		return
	end
	local entry = card.entry
	detailTitle.Text = twoTone(entry.title, entry.amount)
	detailBenefit.Text = entry.benefit
	detailWords.Text = entry.detail
	detailOdds.hit.Visible = entry.kind == "spin"
	paintPrice(detailBuy, card)
end

local function showArt(entry: ShopCatalog.Entry)
	local old = artPicture
	if old then
		old:Destroy()
	end
	-- A pass shows its commissioned 3:2 card (name and benefit painted in); every
	-- other product its own icon.
	local image = entry.art or entry.icon
	local pic = MenuKit.picture(artBox, image, if entry.art then nil else entry.fallback, Z + 10)
	pic.AnchorPoint = Vector2.new(0.5, 0.5)
	pic.Position = UDim2.fromScale(0.5, 0.5)
	pic.Size = UDim2.new(1, -16, 1, -16)
	artPicture = pic
end

local backName = "SeedShopBack"

local function closeDetail()
	local key = detailKey
	if not key then
		return
	end
	detailKey = nil
	detail.Visible = false
	grid.Visible = true
	plate.Visible = true
	MenuKit.unbind(backName)
	local card = cards[key]
	if card and MenuKit.onPad() and card.holder.Visible then
		GuiService.SelectedObject = card.face
	end
end

openDetail = function(key: string)
	local card = cards[key]
	if not card then
		return
	end
	detailKey = key
	grid.Visible = false
	plate.Visible = false
	detail.Visible = true
	showArt(card.entry)
	paintDetail()
	MenuKit.bindBack(backName, closeDetail)
	if MenuKit.onPad() then
		GuiService.SelectedObject = back.hit
	end
end

MenuKit.tap(back.hit, nil, function()
	SoundKit.play("CardClick")
	closeDetail()
end)
MenuKit.tap(detailBuy.hit, nil, function()
	local key = detailKey
	local card = if key then cards[key] else nil
	if card then
		buy(card)
	end
end)

--==============================================================================
-- PAINTING: every shelf this player can see, in order, on the one page
--==============================================================================
local function paintGrid()
	categories = ShopCatalog.categories(mayBuy())
	local shown: { [string]: boolean } = {}
	local first: Card? = nil
	for order, category in ipairs(categories) do
		local section = sectionFor(category)
		section.frame.LayoutOrder = order
		section.frame.Visible = true
		shown[category.id] = true
		for i, entry in ipairs(ShopCatalog.entries(category.id)) do
			local card = cardFor(entry, section.shelf)
			card.holder.LayoutOrder = i
			card.holder.Visible = true
			if not first then
				first = card
			end
			if entry.kind == "spin" and not card.priced and mayBuy() then
				card.priced = true
				showPrice(card, "product", entry.id)
			end
		end
	end
	for id, section in pairs(sections) do
		if not shown[id] then
			section.frame.Visible = false
		end
	end
	local top = first
	padFirst.Value = if top then top.face else nil
	-- REWARDS & ODDS whenever Spin Tickets are on the page.
	odds.hit.Visible = shown[ShopCatalog.TicketsId] == true and odds.hit.Size.X.Offset > 0
end

paint = function()
	paintGrid()
	if detailKey then
		paintDetail()
	end
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied (the gui's own units)
--==============================================================================
local function keyboardTop(): number?
	if not UserInputService.OnScreenKeyboardVisible then
		return nil
	end
	local ok, at = pcall(function()
		return UserInputService.OnScreenKeyboardPosition
	end)
	if not ok or typeof(at) ~= "Vector2" or at.Y <= 0 then
		return nil
	end
	return (at.Y - GuiService:GetGuiInset().Y) / UIKit.scaleOf(gui)
end

relayout = function()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / UIKit.scaleOf(gui)
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local camera = workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	local counts: { number } = {}
	for _, category in ipairs(categories) do
		table.insert(counts, #ShopCatalog.entries(category.id))
	end
	local p = MenuLayout.shopPanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		keyboardTop = keyboardTop(),
	}, RAIL.OutlineThickness, counts)
	menu.place(p)
	local b = MenuLayout.blocks(p)
	local gap = MenuLayout.Config.Gap
	local touch = MenuLayout.Config.Touch
	local rowY = math.floor((p.header - touch) / 2)

	-- THE HEADER: REWARDS & ODDS before the close button.
	local row = MenuLayout.shopHeader(p, MenuKit.titleWidth(menu, p.short))
	local oddsRect = row.odds
	odds.hit.Size = UDim2.fromOffset(if oddsRect then oddsRect.w else 0, touch)
	if oddsRect then
		odds.hit.Position = UDim2.fromOffset(oddsRect.x, rowY)
	end

	-- THE PAGE, over the baseplate: every card a row on a phone, a small tile on
	-- a desktop, each shelf's grid the same.
	local main = b.main
	plate.Position = UDim2.fromOffset(main.x, main.y)
	plate.Size = UDim2.fromOffset(main.w, main.h)
	grid.Position = UDim2.fromOffset(main.x, main.y)
	grid.Size = UDim2.fromOffset(main.w, main.h)
	local cg = MenuLayout.shopCards(p, main.w - grid.ScrollBarThickness)
	cardW, cardH, rows = cg.cardW, cg.cardH, cg.rows
	gridPad.PaddingLeft = UDim.new(0, GRID_INSET)
	gridPad.PaddingRight = UDim.new(0, GRID_INSET)
	gridPad.PaddingTop = UDim.new(0, GRID_INSET)
	gridPad.PaddingBottom = UDim.new(0, GRID_INSET)
	for _, section in pairs(sections) do
		shapeSection(section)
	end
	for _, card in pairs(cards) do
		shapeCard(card)
	end

	-- THE DETAILS: over the grid.
	detail.Position = UDim2.fromOffset(main.x, main.y)
	detail.Size = UDim2.fromOffset(main.w, main.h)
	back.hit.Position = UDim2.fromOffset(6, 2)
	back.hit.Size = UDim2.fromOffset(104, 44)
	local top = 50
	if main.w >= 460 then
		local side = math.max(80, math.min(main.h - top - 8, math.floor(main.w * 0.4)))
		artBox.Position = UDim2.fromOffset(8, top)
		artBox.Size = UDim2.fromOffset(side, math.min(side, main.h - top - 8))
		info.Position = UDim2.fromOffset(8 + side + 14, top)
		info.Size = UDim2.fromOffset(main.w - side - 30, main.h - top - 8)
	else
		local side = math.max(60, math.floor((main.h - top) * 0.36))
		artBox.Position = UDim2.fromOffset(8, top)
		artBox.Size = UDim2.fromOffset(main.w - 16, side)
		info.Position = UDim2.fromOffset(10, top + side + 6)
		info.Size = UDim2.fromOffset(main.w - 20, main.h - top - side - 12)
	end
	UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)
	paintGrid()
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
	task.defer(relayout)
end)
UIKit.onMenuSize(relayout)

--==============================================================================
-- SPIN TICKETS: shown only while the server says this player may buy
--
-- WheelData.Attributes.PaidAllowed: PolicyService answered, and paid spins are
-- on -- the rule GET SPINS keeps. Hidden otherwise, and Roblox is not asked for
-- a price until the category first shows. A refusal from the server frees the
-- buttons (WheelUI says why, for both places a spin is sold).
--==============================================================================
player:GetAttributeChangedSignal(PAID):Connect(function()
	paint()
end)
player:GetAttributeChangedSignal(GameConfig.Pass.MultiplierAttribute):Connect(function()
	for _, card in pairs(cards) do
		if card.entry.kind == "pass" then
			askOwned(card.entry.id)
		end
	end
end)
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		wheelRemote = found
		found.OnClientEvent:Connect(function(action: any, payload: any)
			if action ~= WheelData.Actions.Result or type(payload) ~= "table" or payload.buy ~= true then
				return
			end
			local b = busy
			if payload.ok ~= true and b and b.kind == "spin" then
				clearBusy(b.token)
			end
		end)
	end
end)

paint()
relayout()

--==============================================================================
-- OPEN AND SHUT
--
-- A controller's LB / RB jump the page to the previous or next shelf's heading
-- (one page since 2026-10-06; they stepped the chosen category before), with
-- that shelf's first card selected.
--==============================================================================
local function stepCategory(step: number)
	if detailKey ~= nil then
		return
	end
	local shown: { Section } = {}
	for _, category in ipairs(categories) do
		local section = sections[category.id]
		if section and section.frame.Visible then
			table.insert(shown, section)
		end
	end
	if #shown == 0 then
		return
	end
	-- The shelf the view is in: the last whose heading is at or above its top.
	local k = math.max(HudLayout.scaleOf(grid), 1e-3)
	local at = 1
	for i, section in ipairs(shown) do
		if section.frame.AbsolutePosition.Y <= grid.AbsolutePosition.Y + 2 then
			at = i
		end
	end
	local target = shown[(at - 1 + step) % #shown + 1]
	local y = (target.frame.AbsolutePosition.Y - grid.AbsolutePosition.Y) / k + grid.CanvasPosition.Y - GRID_INSET
	grid.CanvasPosition = Vector2.new(0, math.max(0, y))
	SoundKit.play("CardClick")
	if MenuKit.onPad() then
		local pick: Card? = nil
		for _, card in pairs(cards) do
			if card.holder.Parent == target.shelf and card.holder.Visible
				and (pick == nil or card.holder.LayoutOrder < (pick :: Card).holder.LayoutOrder) then
				pick = card
			end
		end
		if pick then
			GuiService.SelectedObject = pick.face
		end
	end
end

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		-- A price that failed at join, or has gone stale, is asked for again.
		RobuxPrice.refresh()
		MenuKit.bindBumpers("SeedShopPad", stepCategory)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		closeDetail()
		MenuKit.unbind("SeedShopPad")
	end
	relayout()
	paint()
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
gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	MenuKit.unbind("SeedShopPad")
	MenuKit.unbind(backName)
end)
