--!strict
--==============================================================================
-- Steal a Seed :: MysteryShopBanner (client; 2026-10-12, the owner's item 17)
--
-- THE SHOP'S FEATURED BANNER: THE MYSTERIOUS POD, SOLD. At the top of the
-- Shop's page, always there:
--   * "NEW!", the pod's own shell drawn live, its name and a line;
--   * the six creatures inside on their Odds cards -- each with its chance,
--     the size odds one press away on ODDS (MistOddsView's page) -- so the odds
--     stand before any buy (a PAID RANDOM ITEM);
--   * the bundles, 1 / 3 / 10 / 50 (GameConfig.Store.MysteryPods): each its
--     art, this player's own live price on the green Robux tag, an honest
--     "WAS" crossed out above it -- the live x1 price times the count, shown
--     only when the bundle costs less (the owner, 2026-10-12) -- and GIFT,
--     which asks who it is for among the players here and has the server note
--     them before it opens the gift's prompt (MysteryShopService);
--   * all on the Mist's own studs, shining softly.
-- Offered only while PolicyService allows paid random items for this player
-- (Mystery.Shop.PolicyAttribute, published by the server, missing = no):
-- otherwise the bundles and GIFT are hidden and it says so.
--
-- Laid out once at BASE wide and scaled to the page (a probe reads any
-- UIScale above it), so every phone and desktop gets the same banner.
--==============================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local RobuxPrice = require(Shared:WaitForChild("RobuxPrice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local MysteryShopBanner = {}

local SHOP = EnchantedMistConfig.Mystery.Shop
local W = SHOP.Words
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(14, 10, 18)
local GOLD = Color3.fromRGB(255, 214, 92)
local MINT = Color3.fromRGB(150, 255, 196)

-- The banner at 1: its width and height, the header's height, the cards' row
-- and the bundles' row.
MysteryShopBanner.BASE = Vector2.new(640, 446)
local BASE = MysteryShopBanner.BASE
local CARD_SCALE = 0.92
local CARD_W, CARD_H = 104, 140
local CARDS_Y = 118
local TILE_W, TILE_H, TILE_GAP = 148, 172, 8
local TILES_Y = 262

-- The bundles by count: the buyer's and the gifts'.
local COUNTS = { 1, 3, 10, 50 }
local mineBy: { [number]: any } = {}
local giftBy: { [number]: any } = {}
for _, item in ipairs((GameConfig.Store :: any).MysteryPods or {}) do
	if item.gift == true then
		giftBy[item.count] = item
	else
		mineBy[item.count] = item
	end
end

-- "WAS" for `count` at this x1 price: the honest whole, or nil where the
-- bundle is not cheaper (or a price is not known).
function MysteryShopBanner.wasPrice(count: number, single: number?, bundle: number?): number?
	if count <= 1 or not single or not bundle then
		return nil
	end
	local whole = single * count
	return if whole > bundle then whole else nil
end

export type Banner = { frame: Frame, setOpen: (boolean) -> () }

function MysteryShopBanner.build(page: GuiObject, sheetParent: GuiObject, z: number, order: number): Banner
	local player = Players.LocalPlayer
	local outer = Instance.new("Frame")
	outer.Name = "MysteryPodBanner"
	outer.BackgroundTransparency = 1
	outer.BorderSizePixel = 0
	outer.LayoutOrder = order
	outer.Size = UDim2.new(1, 0, 0, BASE.Y)
	outer.ZIndex = z
	outer.Parent = page
	-- What one offset pixel here draws as (the Shop may be scaled).
	local probe = Instance.new("Frame")
	probe.Name = "Probe"
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromOffset(100, 1)
	probe.Parent = outer
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromOffset(BASE.X, BASE.Y)
	inner.ZIndex = z
	inner.Parent = outer
	local fit = Instance.new("UIScale")
	fit.Parent = inner
	local function fitWidth()
		local unit = probe.AbsoluteSize.X / 100
		if unit <= 0 or outer.AbsoluteSize.X <= 0 then
			return
		end
		local s = math.min(1, outer.AbsoluteSize.X / (BASE.X * unit))
		fit.Scale = s
		inner.Position = UDim2.fromOffset(math.max(0, (outer.AbsoluteSize.X / unit - BASE.X * s) / 2), 0)
		local tall = UDim2.new(1, 0, 0, math.ceil(BASE.Y * s))
		if outer.Size ~= tall then
			outer.Size = tall
		end
	end
	outer:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWidth)

	-- THE FACE: the Mist's own studs, shining softly.
	local face = MenuKit.frame(inner, "Face", z, WHITE, 0, 14)
	face.Size = UDim2.fromScale(1, 1)
	local studs = UIKit.studCard(face, 14, z)
	studs.set("mist")
	local shine = RarityFX.shine(face, 14, z + 1)
	RarityFX.setShine(shine, "Mist")
	MenuKit.keyline(face, MINT, 2)
	local fx = { shine }

	-- THE HEADER: NEW!, the shell, its name, ODDS.
	local view = Instance.new("ViewportFrame")
	view.Name = "Shell"
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(14, 10)
	view.Size = UDim2.fromOffset(104, 104)
	view.Ambient = Color3.fromRGB(176, 178, 188)
	view.LightColor = Color3.fromRGB(255, 252, 240)
	view.LightDirection = GameConfig.Card.LightDirection
	view.ZIndex = z + 3
	view.Parent = inner
	local shell = SeedData.Get(tostring(EnchantedMistData.Shell.Id))
	if shell then
		local ok, model = pcall(CreatureModel.Build, shell, 1, CreatureModel.STAGE_POD, CFrame.new(), view)
		if ok and model then
			view.CurrentCamera = UIKit.framePlant(view, model, shell.Form, 0.9, false)
		end
	end
	local badge = MenuKit.frame(inner, "New", z + 6, GOLD, 0, 8)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromOffset(32, 18)
	badge.Size = UDim2.fromOffset(58, 24)
	badge.Rotation = -10
	MenuKit.keyline(badge, INK, 2)
	local badgeWord = MenuKit.heading(badge, "Word", 18, WHITE, z + 7)
	badgeWord.Size = UDim2.fromScale(1, 1)
	badgeWord.Text = W.Badge
	local heading = MenuKit.heading(inner, "Title", 32, WHITE, z + 4)
	heading.Position = UDim2.fromOffset(128, 16)
	heading.Size = UDim2.fromOffset(380, 38)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Text = W.Title
	local tagline = MenuKit.text(inner, "Tagline", 16, WHITE, z + 4)
	tagline.Position = UDim2.fromOffset(128, 56)
	tagline.Size = UDim2.fromOffset(390, 40)
	tagline.TextXAlignment = Enum.TextXAlignment.Left
	tagline.TextWrapped = true
	tagline.Text = W.Tagline
	MenuKit.ink(tagline, INK)
	local oddsButton = MenuKit.button(inner, "Odds", z + 5, W.Odds, 16)
	oddsButton.style("sky")
	oddsButton.hit.AnchorPoint = Vector2.new(1, 0)
	oddsButton.hit.Position = UDim2.fromOffset(BASE.X - 14, 18)
	oddsButton.hit.Size = UDim2.fromOffset(96, 38)
	UIKit.clicks(oddsButton.hit)

	-- THE SIX INSIDE, each on its Odds card with its chance.
	local moving: { any } = {}
	local cardViews = {}
	local cardsRow = Instance.new("Frame")
	cardsRow.Name = "Creatures"
	cardsRow.BackgroundTransparency = 1
	local entries = EnchantedMistData.Pool.Entries
	local n = #entries
	local rowW = n * CARD_W * CARD_SCALE + (n - 1) * 6
	cardsRow.Position = UDim2.fromOffset((BASE.X - rowW) / 2, CARDS_Y)
	cardsRow.Size = UDim2.fromOffset(rowW, CARD_H * CARD_SCALE)
	cardsRow.ZIndex = z + 2
	cardsRow.Parent = inner
	for i, entry in ipairs(entries) do
		local slot = Instance.new("Frame")
		slot.Name = "Card" .. i
		slot.BackgroundTransparency = 1
		slot.Position = UDim2.fromOffset((i - 1) * (CARD_W * CARD_SCALE + 6), 0)
		slot.Size = UDim2.fromOffset(CARD_W, CARD_H)
		slot.ZIndex = z + 2
		slot.Parent = cardsRow
		local shrink = Instance.new("UIScale")
		shrink.Scale = CARD_SCALE
		shrink.Parent = slot
		local card = MistOddsView.card(slot, entry, z + 2, CARD_H, moving, fx, cardViews)
		card.Size = UDim2.fromScale(1, 1)
	end
	MistOddsView.drawViews(cardViews)

	-- THE BUNDLES: art, "WAS", the live price, GIFT.
	local tilesRow = Instance.new("Frame")
	tilesRow.Name = "Bundles"
	tilesRow.BackgroundTransparency = 1
	local tilesW = #COUNTS * TILE_W + (#COUNTS - 1) * TILE_GAP
	tilesRow.Position = UDim2.fromOffset((BASE.X - tilesW) / 2, TILES_Y)
	tilesRow.Size = UDim2.fromOffset(tilesW, TILE_H)
	tilesRow.ZIndex = z + 2
	tilesRow.Parent = inner
	local restricted = MenuKit.heading(inner, "Restricted", 20, WHITE, z + 4)
	restricted.Position = UDim2.fromOffset(20, TILES_Y + 60)
	restricted.Size = UDim2.fromOffset(BASE.X - 40, 40)
	restricted.Text = W.Restricted
	restricted.Visible = false

	type Tile = { count: number, item: any, gift: any?, was: TextLabel, tag: UIKit.PriceTag, buy: TextButton,
		giftButton: MenuKit.Button, price: number? }
	local tiles: { Tile } = {}
	local singlePrice: number? = nil
	local stops: { () -> () } = {}
	local function paintWas()
		for _, t in ipairs(tiles) do
			local was = MysteryShopBanner.wasPrice(t.count, singlePrice, t.price)
			t.was.Visible = was ~= nil
			if was then
				t.was.Text = string.format(W.Was, "<s>" .. RobuxPrice.format(was) .. "</s>")
			end
		end
	end
	local lastPress = 0
	local function pressOnce(): boolean
		local now = os.clock()
		if now - lastPress < 1 then
			return false
		end
		lastPress = now
		return true
	end
	local openGift: (any) -> ()

	for i, count in ipairs(COUNTS) do
		local item = mineBy[count]
		if not item then
			continue
		end
		local tileFrame = MenuKit.frame(tilesRow, "Bundle" .. count, z + 2, Color3.fromRGB(26, 22, 40), 0.25, 12)
		tileFrame.Position = UDim2.fromOffset((i - 1) * (TILE_W + TILE_GAP), 0)
		tileFrame.Size = UDim2.fromOffset(TILE_W, TILE_H)
		MenuKit.keyline(tileFrame, MINT, 1.5, 0.3)
		local art = Instance.new("ImageLabel")
		art.Name = "Art"
		art.BackgroundTransparency = 1
		art.AnchorPoint = Vector2.new(0.5, 0)
		art.Position = UDim2.new(0.5, 0, 0, 4)
		art.Size = UDim2.fromOffset(78, 78)
		art.Image = tostring(item.icon or "")
		art.ScaleType = Enum.ScaleType.Fit
		art.ZIndex = z + 3
		art.Parent = tileFrame
		local many = MenuKit.heading(tileFrame, "Count", 22, WHITE, z + 4)
		many.Position = UDim2.fromOffset(6, 4)
		many.Size = UDim2.fromOffset(60, 26)
		many.TextXAlignment = Enum.TextXAlignment.Left
		many.Text = string.format("x%d", count)
		local was = MenuKit.text(tileFrame, "Was", 16, Color3.fromRGB(255, 220, 220), z + 4)
		was.Position = UDim2.fromOffset(0, 80)
		was.Size = UDim2.new(1, 0, 0, 20)
		was.RichText = true
		was.Visible = false
		MenuKit.ink(was, INK)
		local buy = Instance.new("TextButton")
		buy.Name = "Buy"
		buy.Text = ""
		buy.BackgroundTransparency = 1
		buy.AnchorPoint = Vector2.new(0.5, 0)
		buy.Position = UDim2.new(0.5, 0, 0, 100)
		buy.Size = UDim2.fromOffset(TILE_W - 16, 40)
		buy.ZIndex = z + 4
		buy.Parent = tileFrame
		UIKit.clicks(buy)
		local tag = UIKit.priceTag(buy, "Tag", z + 5)
		tag.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		tag.frame.Position = UDim2.fromScale(0.5, 0.5)
		tag.frame.Size = UDim2.fromScale(1, 1)
		tag.price.Text = "..."
		local giftItem = giftBy[count]
		local giftButton = MenuKit.button(tileFrame, "Gift", z + 4, W.Gift, 14)
		giftButton.style("sky")
		giftButton.hit.AnchorPoint = Vector2.new(0.5, 1)
		giftButton.hit.Position = UDim2.new(0.5, 0, 1, -4)
		giftButton.hit.Size = UDim2.fromOffset(TILE_W - 40, 26)
		giftButton.hit.Visible = giftItem ~= nil
		UIKit.clicks(giftButton.hit)
		local tile: Tile = { count = count, item = item, gift = giftItem, was = was, tag = tag, buy = buy,
			giftButton = giftButton, price = nil }
		table.insert(tiles, tile)
		table.insert(stops, RobuxPrice.watch("product", item.product, function(state: RobuxPrice.State, price: number?)
			tile.price = if state == "ready" then price else nil
			tag.price.Text = if state == "ready" and price then RobuxPrice.format(price) else "..."
			if count == 1 then
				singlePrice = tile.price
			end
			paintWas()
		end))
		buy.Activated:Connect(function()
			if not pressOnce() then
				return
			end
			SoundKit.play("CardClick")
			MarketplaceService:PromptProductPurchase(player, item.product)
		end)
		giftButton.hit.Activated:Connect(function()
			if giftItem and pressOnce() then
				SoundKit.play("CardClick")
				openGift(giftItem)
			end
		end)
	end

	-- PolicyService's answer, from the server: missing reads "no".
	local function allowed(): boolean
		return player:GetAttribute(SHOP.PolicyAttribute) == true
	end
	local function paintPolicy()
		local yes = allowed()
		tilesRow.Visible = yes
		restricted.Visible = not yes
	end
	player:GetAttributeChangedSignal(SHOP.PolicyAttribute):Connect(paintPolicy)
	paintPolicy()

	--==========================================================================
	-- A SHEET OVER THE SHOP: the odds page, or who a gift is for
	--==========================================================================
	local function sheet(name: string, tall: number): (Frame, Frame, () -> ())
		local back = Instance.new("TextButton")
		back.Name = name
		back.Text = ""
		back.AutoButtonColor = false
		back.BackgroundColor3 = INK
		back.BackgroundTransparency = 0.35
		back.Size = UDim2.fromScale(1, 1)
		back.ZIndex = z + 40
		back.Visible = false
		back.Parent = sheetParent
		local panel = MenuKit.frame(back, "Panel", z + 41, Color3.fromRGB(34, 28, 52), 0, 14)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.Size = UDim2.new(0.92, 0, 0, tall)
		MenuKit.keyline(panel, MINT, 2)
		local cap = Instance.new("UISizeConstraint")
		cap.MaxSize = Vector2.new(560, tall)
		cap.Parent = panel
		local close = MenuKit.button(panel, "Close", z + 44, "X", 16)
		close.style("danger")
		close.hit.AnchorPoint = Vector2.new(1, 0)
		close.hit.Position = UDim2.new(1, -8, 0, 8)
		close.hit.Size = UDim2.fromOffset(36, 36)
		UIKit.clicks(close.hit)
		local function shut()
			back.Visible = false
		end
		close.hit.Activated:Connect(shut)
		back.Activated:Connect(shut)
		return back, panel, shut
	end

	-- ODDS: MistOddsView's own page, the creatures and the sizes.
	local oddsBack, oddsPanel = sheet("MysteryOdds", 380)
	local oddsTitle = MenuKit.heading(oddsPanel, "Title", 24, WHITE, z + 43)
	oddsTitle.Position = UDim2.fromOffset(14, 10)
	oddsTitle.Size = UDim2.new(1, -60, 0, 32)
	oddsTitle.TextXAlignment = Enum.TextXAlignment.Left
	oddsTitle.Text = W.Title .. " " .. W.Odds
	local oddsHolder = Instance.new("Frame")
	oddsHolder.Name = "Holder"
	oddsHolder.BackgroundTransparency = 1
	oddsHolder.Position = UDim2.fromOffset(10, 48)
	oddsHolder.Size = UDim2.new(1, -20, 1, -58)
	oddsHolder.ZIndex = z + 42
	oddsHolder.Parent = oddsPanel
	local oddsView: MistOddsView.View? = nil
	oddsButton.hit.Activated:Connect(function()
		SoundKit.play("CardClick")
		if not oddsView then
			oddsView = MistOddsView.build(oddsHolder, z + 42)
		end
		oddsBack.Visible = true
		local built = oddsView :: MistOddsView.View
		built.frame.Size = UDim2.fromScale(1, 1)
		built.setShown(true)
	end)
	oddsBack:GetPropertyChangedSignal("Visible"):Connect(function()
		if oddsView and not oddsBack.Visible then
			(oddsView :: MistOddsView.View).setShown(false)
		end
	end)

	-- GIFT: who it is for, among the players here PolicyService allows.
	local giftBack, giftPanel, giftShut = sheet("MysteryGift", 330)
	local giftTitle = MenuKit.heading(giftPanel, "Title", 22, WHITE, z + 43)
	giftTitle.Position = UDim2.fromOffset(14, 10)
	giftTitle.Size = UDim2.new(1, -60, 0, 30)
	giftTitle.TextXAlignment = Enum.TextXAlignment.Left
	local giftAsk = MenuKit.text(giftPanel, "Ask", 16, WHITE, z + 43)
	giftAsk.Position = UDim2.fromOffset(14, 42)
	giftAsk.Size = UDim2.new(1, -28, 0, 20)
	giftAsk.TextXAlignment = Enum.TextXAlignment.Left
	giftAsk.Text = W.GiftPick
	local list = Instance.new("ScrollingFrame")
	list.Name = "Players"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(12, 68)
	list.Size = UDim2.new(1, -24, 1, -110)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 5
	list.ZIndex = z + 43
	list.Parent = giftPanel
	local rows = Instance.new("UIListLayout")
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Padding = UDim.new(0, 6)
	rows.Parent = list
	local status = MenuKit.text(giftPanel, "Status", 15, Color3.fromRGB(255, 214, 214), z + 43)
	status.AnchorPoint = Vector2.new(0, 1)
	status.Position = UDim2.new(0, 14, 1, -10)
	status.Size = UDim2.new(1, -28, 0, 24)
	status.TextWrapped = true
	MenuKit.ink(status, INK)
	-- Nobody to give to: said where the names would stand.
	local nobody = MenuKit.heading(giftPanel, "Nobody", 18, WHITE, z + 43)
	nobody.AnchorPoint = Vector2.new(0.5, 0.5)
	nobody.Position = UDim2.fromScale(0.5, 0.5)
	nobody.Size = UDim2.new(1, -40, 0, 48)
	nobody.TextWrapped = true
	nobody.Text = W.GiftNone
	nobody.Visible = false
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("SeedGame"):WaitForChild("Remotes")
	local channel = remotes:WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent
	local giftFor: any = nil
	openGift = function(item: any)
		giftFor = item
		giftTitle.Text = string.upper(string.format("%s %s", W.Gift, (string.gsub(item.label, "^Gift: ", ""))))
		status.Text = ""
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		local any = false
		for i, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other:GetAttribute(SHOP.PolicyAttribute) == true then
				any = true
				local row = MenuKit.button(list, "Player" .. i, z + 44,
					string.format("%s (@%s)", other.DisplayName, other.Name), 15)
				row.style("go")
				row.hit.Size = UDim2.new(1, -8, 0, 40)
				row.hit.LayoutOrder = i
				UIKit.clicks(row.hit)
				row.hit.Activated:Connect(function()
					if not giftFor or not pressOnce() then
						return
					end
					SoundKit.play("CardClick")
					status.Text = ""
					channel:FireServer(SHOP.GiftAction, { bundle = giftFor.key, recipient = other.UserId })
				end)
			end
		end
		nobody.Visible = not any
		giftBack.Visible = true
	end
	channel.OnClientEvent:Connect(function(action: any, reply: any)
		if action ~= SHOP.GiftReply or type(reply) ~= "table" or not giftBack.Visible then
			return
		end
		if reply.ok == true then
			giftShut()
		else
			status.Text = (W.Refused :: any)[tostring(reply.code)] or ""
		end
	end)

	-- Open, its glow and its rainbows run; shut, they rest.
	local stopMoving: (() -> ())? = nil
	local function setOpen(open: boolean)
		for _, h in ipairs(fx) do
			RarityFX.setActive(h, open)
		end
		if open and not stopMoving then
			stopMoving = MistOddsView.animate(moving)
		elseif not open and stopMoving then
			stopMoving()
			stopMoving = nil
		end
		if not open then
			oddsBack.Visible = false
			giftBack.Visible = false
		else
			fitWidth()
		end
	end
	fitWidth()
	return { frame = outer, setOpen = setOpen }
end

return MysteryShopBanner
