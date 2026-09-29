--!strict
-- Steal a Seed :: WheelUI
--
-- THE OBBY REWARD WHEEL'S PANEL, AND THE WHEEL'S FACE IN THE WORLD
-- (2026-09-27; rebuilt the same day to the owner's approved mockup,
-- "Podnappers Spin Wheel Mockup"). Opened by the prompt at the wheel behind
-- Marigold's stall. Everything it shows was decided by WheelService: it draws
-- the balances the server publishes, sends one word to spin, and animates the
-- answer.
--
--==============================================================================
-- THREE SCREENS, AS THE MOCKUP DRAWS THEM
--
--   the wheel     a dim scrim over the game and the wheel alone on it, as big as
--                 the screen allows; the hub is the SPIN button ("SPIN" over
--                 "×N"), a round blue "?" at the top left, a red X at the right
--   no spins      the same, the hub grey ("0" over "SPINS") and not pressable,
--                 and "Beat the obby to earn a spin" under the wheel
--   Reward info   ("?") a wooden-headed sheet over the wheel: every prize with its
--                 rarity and its exact odds in two columns, read from WheelData;
--                 a pod's row opens a grid of its species' cards, each with its
--                 own odds; the day's allowance, the reset countdown and Skip
--                 animation along the foot
--
-- What the mockup does not draw, kept small: the prize just won, in the line
-- under the wheel for a few seconds (and as a notice); a prize waiting for bag
-- space, with CLAIM; the question before a purchased spin; a refusal, in that
-- line and as a notice.
--
--==============================================================================
-- ABOVE THE HUD, LIKE A PANEL TO EVERYTHING ELSE
--
-- DisplayOrder 48: over the rail (40), the biome banner (45) and the boost row
-- (46), so no HUD button draws across the wheel; under the RUN alarm (50) and
-- the admin console (60). The scrim is a full-screen `RewardWheelDimmer` button
-- straight under the gui with everything inside a `Shell`, which is what
-- PadInput and PadFocus read as "a centre panel is open": nothing behind it
-- acts, the controller is kept inside it, and B closes it.
--
-- NOTHING RUNS PER FRAME WHILE IT IS SHUT. The rainbows (the trail's sector and
-- star, its row in Reward info) share one RenderStepped, made on open and
-- dropped on close, and none at all with SeedAfterimageQuality "Off"; a spin has
-- its own, for the length of the spin; the countdown is a once-a-second loop
-- that lives while the panel is open. The world sign's colour drift steps ten
-- times a second, and only while this camera is within the sign's draw distance.
--
--==============================================================================
-- A SPIN IS THE SERVER'S FROM START TO FINISH
--
-- SPIN sends "earned" -- or, only after the player says yes to a question
-- naming it, "bought" -- and nothing else. The wheel turns only once the answer
-- is here, and stops with the rolled prize's sector under the pointer at the
-- point in it the server chose. The sectors are drawn at readable sizes, not to
-- scale (WheelData.displaySectors); the exact odds are in Reward info. Closing
-- the panel, skipping the animation or leaving changes nothing: the prize was
-- recorded, saved and paid before the answer was sent.
--
-- PURCHASED SPINS (2026-09-29): never spent without being asked. Two products
-- can be bought, +1 Spin and +10 Spins (WheelData.Products), and only by a
-- player the server says may: GET SPINS and its card are shown while
-- WheelPaidAllowed is true and at no other time -- so not at all while
-- WheelData.Paid.Enabled is off, which is how this ships.
--
--   * THIS SCRIPT OPENS NO PURCHASE PROMPT AND GRANTS NOTHING. A choice sends
--     its product's KEY; the server decides whether to open Roblox's prompt, and
--     the spins arrive -- as a balance the server publishes -- only from the
--     receipt.
--   * THE PRICE IS ROBLOX'S, FOR THIS PLAYER (RobuxPrice), or no number at all:
--     never WheelData's list price, which a regional price would contradict in
--     the prompt.
--   * THE ODDS ARE ONE PRESS AWAY, BEHIND A BUTTON THAT SAYS SO. Roblox's rule
--     for a paid random item is every final outcome's odds before the purchase
--     and before the spend, and that a bare "?" is not enough: the card to buy
--     and the question to spend each carry REWARDS & ODDS, and the round "?"
--     gets the word ODDS under it.
--   * A CARD KEEPS THE CONTROLLER. While the card to buy or the question is up
--     nothing behind it can be selected, and B shuts the card before the panel.
--   * NOTHING IS ADDED TO THE HUD. The button and both cards live inside this
--     panel's scrim, so the game is never covered by them.
--
-- THE WORLD WHEEL: WheelModel's two face panels carry the same WheelDraw face,
-- built here, locally. The front one turns on THIS screen only while this
-- player spins, so nobody's spin shows on anybody else's wheel.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))
-- What Roblox would charge THIS player for a spin product (the buy card).
local RobuxPrice = require(Shared:WaitForChild("RobuxPrice"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if not WheelData.Enabled then
	return
end

local ATTR = GameConfig.Attributes
local A = WheelData.Attributes
local ACT = WheelData.Actions
local OA = ObbyData.Attributes
local ALMANAC = GameConfig.Almanac
local PANEL_NAME = "RewardWheel"
local BACK_ACTION = "SeedWheelBack"
-- Walk this far from the wheel's prompt and the panel shuts, like the shop's.
local CLOSE_DISTANCE = 26
-- Over the rail (40), the biome banner (45) and the boost row (46); under the
-- RUN alarm (50) and the admin console (60).
local DISPLAY_ORDER = 48
-- A desktop's wheel stops growing here, in gui units: a panel, not a poster.
local MAX_WHEEL = 520
-- The spin: whole turns, then an ease-out onto the rolled point.
local SPIN_TURNS = 5
local SPIN_SECONDS = 4.6
-- How long the line under the wheel holds a win, and a refusal.
local RESULT_SECONDS = 6
local NOTE_SECONDS = 4
-- One turn of the rainbow's hue, the mockup's pace.
local RAINBOW_SECONDS = 2.4
-- The plant cards: a card's width it aims at, and its shape (the Garden's).
local CARD_WIDTH = 104
local CARD_ASPECT = 1.3
local CARD_GAP = 8
local CARD_FILL = 0.8
-- Reward info's rows: all twelve, in six pairs, fit a landscape phone's sheet
-- (229 of its 231) without a scroll until a pod row is opened.
local ROW_HEIGHT = 34
local ROW_GAP = 5

local PAL = WheelDraw.Palette
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
-- The mockup's colours, by its own hex. One table: this script is long, and
-- Luau allows a chunk 200 locals.
local C = {
	White = rgb(255, 255, 255),
	Black = rgb(0, 0, 0),
	Scrim = rgb(10, 20, 12), -- rgba(10,20,12,.55)
	PointerGold = rgb(255, 210, 63), -- #ffd23f
	Blue = rgb(63, 143, 224), -- #3f8fe0
	BlueRim = rgb(29, 63, 115), -- #1d3f73
	Red = rgb(216, 69, 59), -- #d8453b
	RedRim = rgb(122, 26, 20), -- #7a1a14
	Sheet = rgb(47, 90, 52), -- #2f5a34
	SheetFoot = rgb(62, 37, 15), -- #3e250f
	Header = rgb(138, 90, 43), -- #8a5a2b
	-- rgba(0,0,0,.25) on the sheet, made opaque so its rounded foot can overlap.
	Footer = rgb(35, 68, 39),
	NameInk = rgb(20, 35, 15), -- #14230f
	Note = rgb(207, 227, 200), -- #cfe3c8
	FootText = rgb(228, 239, 220), -- #e4efdc
	Glow = rgb(255, 240, 150),
	-- Epic WORDS on the green sheet: the game's Epic purple (146, 62, 158) is too
	-- dark to read there even outlined, so names and rarity words take the
	-- approved mockup's light purple (#d49bff). Borders and pills keep the
	-- game's own (the owner's call, 2026-09-27).
	EpicText = rgb(212, 155, 255),
}
local SCRIM_SEEN = 0.45

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
for _, name in ipairs({ "SeedWheel", "SeedWheelEdges" }) do
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end
ContextActionService:UnbindAction(BACK_ACTION)
if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
	player:SetAttribute(ATTR.OpenPanel, nil)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedWheel"
gui.ResetOnSpawn = false
gui.DisplayOrder = DISPLAY_ORDER
-- Laid out in the device's SAFE AREA -- IgnoreGuiInset gives DeviceSafeInsets:
-- the topbar's band is inside it, a phone's notch strips and home bar are not
-- -- which is where the wheel and its buttons belong. The layout keeps clear
-- of Roblox's own topbar buttons itself (GuiService.TopbarInset), and the
-- scrim reaches past the safe area to every edge of the screen (see edge).
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- Drawn bigger on a TV, and at the player's menu size where the screen has room.
UIKit.tenFoot(gui)
UIKit.menuGui(gui, Vector2.new(640, 330))

-- The whole screen and the safe area, measured side by side: an empty gui with
-- no insets at all, and a frame filling this one. In Studio's iPhone 14
-- emulation the screen is 799 x 359 and the safe area 705 x 338 -- 47 on each
-- side and 21 under it that a scrim sized to this gui would leave undimmed.
local edge: { whole: Frame, safe: Frame }
do
	local edges = Instance.new("ScreenGui")
	edges.Name = "SeedWheelEdges"
	edges.ResetOnSpawn = false
	edges.IgnoreGuiInset = true
	edges.ScreenInsets = Enum.ScreenInsets.None
	edges.Parent = playerGui
	local function filler(name: string, parent: Instance): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundTransparency = 1
		f.Active = false
		f.Parent = parent
		return f
	end
	edge = { whole = filler("WholeScreen", edges), safe = filler("SafeArea", gui) }
end

--==============================================================================
-- SMALL BUILDERS. The gui is SIBLING ZIndexBehavior: a ZIndex orders siblings.
--==============================================================================
local function text(parent: Instance, name: string, px: number, colour: Color3, font: Enum.Font?,
	z: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.GothamBold
	l.TextSize = px
	l.TextColor3 = colour
	l.Text = ""
	l.Active = false
	l.ZIndex = z or 1
	l.Parent = parent
	return l
end

local function ink(target: Instance, colour: Color3, thickness: number, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = target
	return s
end

local function panel(parent: Instance, name: string, colour: Color3, radius: number, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = z
	f.Parent = parent
	if radius > 0 then
		UIKit.corner(f, radius)
	end
	return f
end

local function round(parent: Instance, name: string, colour: Color3, z: number): Frame
	local f = panel(parent, name, colour, 0, z)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	return f
end

local function place(g: GuiObject, x: number, y: number, w: number, h: number)
	g.Position = UDim2.fromOffset(x, y)
	g.Size = UDim2.fromOffset(w, h)
end

local function blank(parent: Instance, name: string, z: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.Text = ""
	b.Selectable = false
	b.ZIndex = z
	b.Parent = parent
	return b
end

--==============================================================================
-- A ROUND BUTTON, the mockup's "?" and X: a face in a darker rim, standing on
-- a foot of the rim's colour, the glyph outlined with a drop under it.
--==============================================================================
type RoundButton = {
	button: TextButton,
	face: Frame,
	resize: (diameter: number, border: number, foot: number, glyphPx: number) -> (),
}

local function roundButton(parent: Instance, name: string, fill: Color3, rim: Color3, glyphText: string?,
	z: number): RoundButton
	local b = blank(parent, name, z)
	b.Selectable = true
	UIKit.clicks(b)
	local foot = round(b, "Foot", rim, 1)
	local ring = round(b, "Rim", rim, 2)
	local face = round(b, "Face", fill, 3)
	local glyph, drop = nil, nil
	if glyphText then
		drop = WheelDraw.words(b, "GlyphDrop", 20, PAL.Ink, PAL.Ink, 2, 4)
		glyph = WheelDraw.words(b, "Glyph", 20, C.White, PAL.Ink, 2, 5)
		for _, l in ipairs({ drop, glyph }) do
			l.Text = glyphText
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.Size = UDim2.fromScale(1, 1)
		end
	end
	local function resize(d: number, border: number, footPx: number, glyphPx: number)
		b.Size = UDim2.fromOffset(d, d)
		place(foot, 0, footPx, d, d)
		place(ring, 0, 0, d, d)
		place(face, border, border, d - border * 2, d - border * 2)
		if glyph and drop then
			glyph.TextSize = glyphPx
			drop.TextSize = glyphPx
			glyph.Position = UDim2.new(0.5, 0, 0.5, -1)
			drop.Position = UDim2.new(0.5, 0, 0.5, math.max(1, math.floor(glyphPx * 0.1 + 0.5)))
		end
	end
	return { button = b, face = face, resize = resize }
end

-- The back chevron: two white strokes, the mockup's "M15 5 L8 12 L15 19".
local function chevron(parent: GuiObject)
	for i, rot in ipairs({ -45, 45 }) do
		local bar = Instance.new("Frame")
		bar.Name = "Chevron" .. i
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5 - 0.02, if i == 1 then 0.5 - 0.145 else 0.5 + 0.145)
		bar.Size = UDim2.fromScale(0.5, 0.16)
		bar.BackgroundColor3 = C.White
		bar.BorderSizePixel = 0
		bar.Active = false
		bar.Rotation = rot
		bar.ZIndex = 5
		bar.Parent = parent
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = bar
	end
end

--==============================================================================
-- THE SCRIM AND THE SHELL
--==============================================================================
-- A button, so the tap that closes it is consumed rather than reaching the
-- world; never selectable (a ring round the whole screen). B closes instead.
local scrim = blank(gui, PANEL_NAME .. "Dimmer", 1)
scrim.Size = UDim2.fromScale(1, 1)
scrim.BackgroundColor3 = C.Scrim
scrim.BackgroundTransparency = 1
scrim.Visible = false

local shell = Instance.new("Frame")
shell.Name = "Shell"
shell.AnchorPoint = Vector2.new(0.5, 0.5)
shell.Position = UDim2.fromScale(0.5, 0.5)
shell.Size = UDim2.fromScale(1, 1)
shell.BackgroundTransparency = 1
shell.Active = false
shell.ZIndex = 2
shell.Parent = scrim
local pop = Instance.new("UIScale")
pop.Scale = 1
pop.Parent = shell

-- PadFocus's first pick when a controller opens the panel: the hub, or "?".
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = shell

-- The scrim out to every edge of the screen, and the shell -- everything the
-- player touches -- back inside the safe area, centred where it always was.
-- In this gui's own units: pixels / `k`, its TV and menu scale. Returns the
-- safe area's inset from the screen's left and right edges.
local function reachEdges(k: number): (number, number)
	local whole, safe = edge.whole, edge.safe
	local wp, ws = whole.AbsolutePosition, whole.AbsoluteSize
	local sp, ss = safe.AbsolutePosition, safe.AbsoluteSize
	local left = math.max(0, (sp.X - wp.X) / k)
	local top = math.max(0, (sp.Y - wp.Y) / k)
	local right = math.max(0, (wp.X + ws.X - sp.X - ss.X) / k)
	local bottom = math.max(0, (wp.Y + ws.Y - sp.Y - ss.Y) / k)
	scrim.Position = UDim2.fromOffset(-left, -top)
	scrim.Size = UDim2.new(1, left + right, 1, top + bottom)
	shell.Position = UDim2.new(0.5, (left - right) / 2, 0.5, (top - bottom) / 2)
	shell.Size = UDim2.new(1, -(left + right), 1, -(top + bottom))
	return left, right
end

--==============================================================================
-- SCREEN 1 AND 2: THE WHEEL
--==============================================================================
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.Size = UDim2.fromScale(1, 1)
stage.BackgroundTransparency = 1
stage.Active = false
stage.ZIndex = 1
stage.Parent = shell

-- A press on the wheel itself is swallowed here rather than falling through
-- to the scrim, which would shut the panel.
local wheelBlock = blank(stage, "WheelBlock", 1)
local wheelHolder = panel(stage, "WheelHolder", C.Black, 0, 2)
wheelHolder.BackgroundTransparency = 1
local drawn: WheelDraw.Drawn? = nil
local drawnSize = 0

-- The mockup's gold pin: a round head on a point, a brown edge and a cream
-- dot. A circle and a diamond (a square turned 45 degrees) whose top corner is
-- the circle's centre: the diamond's sides then touch the circle exactly, so
-- the two make one teardrop. Each is drawn twice, the brown grown underneath,
-- so the edge runs round the outside only.
local pointer = panel(stage, "Pointer", C.Black, 0, 3)
pointer.BackgroundTransparency = 1
pointer.Size = UDim2.fromScale(1, 1)
local pin = {
	headEdge = round(pointer, "HeadEdge", PAL.Wood, 1),
	tipEdge = panel(pointer, "TipEdge", PAL.Wood, 0, 1),
	head = round(pointer, "Head", C.PointerGold, 2),
	tip = panel(pointer, "Tip", C.PointerGold, 0, 2),
	dot = round(pointer, "Dot", PAL.Cream, 3),
}
for _, tip in ipairs({ pin.tipEdge, pin.tip }) do
	tip.Rotation = 45
end
for _, piece in pairs(pin) do
	piece.AnchorPoint = Vector2.new(0.5, 0.5)
end

-- The hub: WheelDraw's SPIN face, and the button over it.
local hubFace: WheelDraw.Hub? = nil
local hubButton = blank(stage, "Spin", 5)
hubButton.AnchorPoint = Vector2.new(0.5, 0.5)
hubButton.Selectable = true
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = hubButton
end
UIKit.clicks(hubButton)

local infoButton = roundButton(stage, "Info", C.Blue, C.BlueRim, "?", 6)
local closeButton = roundButton(stage, "Close", C.Red, C.RedRim, "X", 6)
for _, r in ipairs({ infoButton, closeButton }) do
	r.button.AnchorPoint = Vector2.new(0.5, 0.5)
end

-- The line under the wheel: what was just won, a refusal, a prize waiting for
-- bag space (with CLAIM), or "Beat the obby to earn a spin".
local lineRow = panel(stage, "Line", C.Black, 0, 6)
lineRow.BackgroundTransparency = 1
do
	local lineLayout = Instance.new("UIListLayout")
	lineLayout.FillDirection = Enum.FillDirection.Horizontal
	lineLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lineLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	lineLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lineLayout.Padding = UDim.new(0, 10)
	lineLayout.Parent = lineRow
end
local lineText = WheelDraw.words(lineRow, "Words", 15, PAL.Cream, PAL.Ink, 2, 1)
lineText.AutomaticSize = Enum.AutomaticSize.X
lineText.LayoutOrder = 1
local lineGradient = Instance.new("UIGradient")
lineGradient.Enabled = false
lineGradient.Parent = lineText
local claimButton = blank(lineRow, "Claim", 2)
claimButton.LayoutOrder = 2
claimButton.Selectable = true
claimButton.Visible = false
claimButton.BackgroundTransparency = 0
claimButton.BackgroundColor3 = C.Header
UIKit.corner(claimButton, 8)
ink(claimButton, PAL.Gold, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local claimWords = WheelDraw.words(claimButton, "Words", 14, C.White, PAL.Ink, 1.5, 2)
claimWords.Size = UDim2.fromScale(1, 1)
claimWords.Text = "CLAIM"
UIKit.clicks(claimButton)

-- The purchased-spin question, over the hub. Dormant while the product is
-- disabled (nobody holds a bought spin), and never skipped when it is not.
local confirm = panel(stage, "UseBought", C.Sheet, 14, 8)
confirm.AnchorPoint = Vector2.new(0.5, 0.5)
confirm.Visible = false
ink(confirm, PAL.Gold, 2.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local confirmText = text(confirm, "Question", 14, PAL.Cream, Enum.Font.GothamBold, 2)
confirmText.TextWrapped = true
confirmText.Text = "No earned spins left. Use 1 PURCHASED spin?"
ink(confirmText, PAL.Ink, 1.5)
local function wordButton(parent: Instance, name: string, words: string, colour: Color3): TextButton
	local b = blank(parent, name, 2)
	b.Selectable = true
	b.BackgroundTransparency = 0
	b.BackgroundColor3 = colour
	UIKit.corner(b, 8)
	local edge = ink(b, PAL.Ink, 2)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local w = WheelDraw.words(b, "Words", 14, C.White, PAL.Ink, 1.5, 3)
	w.Size = UDim2.fromScale(1, 1)
	w.Text = words
	UIKit.clicks(b)
	return b
end
local confirmYes = wordButton(confirm, "Yes", "USE PURCHASED", rgb(214, 150, 46))
local confirmNo = wordButton(confirm, "No", "CANCEL", PAL.HubGrey)

--==============================================================================
-- BUYING SPINS (2026-09-29): GET SPINS, AND THE CARD IT OPENS
--
-- One worded button beside the wheel, shown only to a player the server says
-- may buy (WheelPaidAllowed). It opens a card over the hub, inside the panel's
-- own scrim -- nothing is added to the HUD, so nothing stands over the game:
--
--     GET SPINS
--     [ icon  +1 SPIN   (R$) 4 ]   [ icon  +10 SPINS   (R$) 35 ]
--     Every spin wins a random reward ...
--     [ REWARDS & ODDS ]                               [ CLOSE ]
--
-- The icons are the products' own (the owner's artwork, as Roblox lists it);
-- a choice reads perfectly well without one, should it not load. Each price is
-- what RobuxPrice hears from Roblox for THIS player: three dots until it
-- answers, BUY and no number if it never does, OFF SALE if Roblox says so.
--
-- One table, because this script is near Luau's 200 locals a chunk: its
-- pieces, and further down the functions that place, paint and open it.
--==============================================================================
type ShopChoice = {
	product: WheelData.Product,
	button: TextButton,
	icon: ImageLabel,
	name: TextLabel,
	capsule: Frame,
	token: ImageLabel,
	price: TextLabel,
	onSale: boolean,
}

local shop: { [string]: any } = {
	open = false,
	-- Where Reward info goes back to when it was opened from a card: "shop",
	-- "confirm" or "" (the wheel).
	returnTo = "",
	-- The last bought balance seen, so a purchase landing can be said out loud.
	bought = 0,
	button = wordButton(stage, "GetSpins", "GET SPINS", rgb(214, 150, 46)),
	card = panel(stage, "BuySpins", C.Sheet, 14, 8),
	choices = {} :: { ShopChoice },
	-- The word under the round "?", where a purchase can be made: Roblox asks
	-- that the way to the odds says what it is.
	infoWord = WheelDraw.words(stage, "InfoWord", 12, C.White, PAL.Ink, 2, 6),
	confirmOdds = wordButton(confirm, "Odds", "REWARDS & ODDS", C.Blue),
}
shop.button.Visible = false
shop.button.ZIndex = 6
-- ON A BIG SCREEN the wheel is big, and a button and cards made for a phone
-- would sit small beside it. They grow with the SCREEN -- not the wheel, which
-- is already big in a 640 x 480 window that has no room for more -- by up to a
-- quarter from 1024 x 600, and are never smaller than they are on a phone.
shop.grow = function(W: number, H: number): number
	return math.clamp(math.min(W / 1024, H / 600), 1, 1.25)
end
for _, name in ipairs({ "button", "card", "question" }) do
	local scale = Instance.new("UIScale")
	scale.Name = "Grow"
	scale.Parent = if name == "question" then confirm else shop[name]
	shop[name .. "Scale"] = scale
end
shop.infoWord.Text = "ODDS"
shop.infoWord.AnchorPoint = Vector2.new(0.5, 0)
shop.infoWord.Visible = false
shop.card.AnchorPoint = Vector2.new(0.5, 0.5)
shop.card.Visible = false
ink(shop.card, PAL.Gold, 2.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
do
	local title = WheelDraw.words(shop.card, "Title", 20, C.White, PAL.Ink, 2, 2)
	title.Text = "GET SPINS"
	shop.title = title
	local note = text(shop.card, "Note", 11, C.Note, Enum.Font.GothamBold, 2)
	note.TextWrapped = true
	note.TextYAlignment = Enum.TextYAlignment.Center
	note.Text = "Every spin wins one random reward. Bought spins never expire and are not part of "
		.. "your 5 daily obby spins."
	-- Two lines at 11 on a phone, in a box with room for three: its first line
	-- is 292 of the 308 it has, so another screen's scale can wrap it again.
	-- Past three it is drawn smaller rather than run into the buttons.
	note.TextScaled = true
	local noteSize = Instance.new("UITextSizeConstraint")
	noteSize.MaxTextSize = 11
	noteSize.MinTextSize = 8
	noteSize.Parent = note
	ink(note, C.NameInk, 1, 0.3)
	shop.note = note
	shop.odds = wordButton(shop.card, "Odds", "REWARDS & ODDS", C.Blue)
	shop.close = wordButton(shop.card, "Close", "CLOSE", PAL.HubGrey)

	for i, product in ipairs(WheelData.Products) do
		local b = blank(shop.card, "Buy_" .. product.key, 2)
		b.Selectable = true
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = rgb(67, 176, 79)
		UIKit.corner(b, 10)
		ink(b, PAL.Ink, 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIKit.clicks(b)
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = "rbxassetid://" .. product.icon
		icon.Active = false
		icon.ZIndex = 3
		icon.Parent = b
		local name = WheelDraw.words(b, "Name", 16, C.White, PAL.Ink, 2, 3)
		name.Text = string.upper(product.name)
		local capsule = panel(b, "Capsule", C.White, 10, 3)
		capsule.AnchorPoint = Vector2.new(0.5, 0)
		capsule.AutomaticSize = Enum.AutomaticSize.X
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = capsule
		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.HorizontalAlignment = Enum.HorizontalAlignment.Center
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.Padding = UDim.new(0, 4)
		row.Parent = capsule
		-- The Robux mark the client ships with (ShopUI's): no upload, no glyph.
		local token = Instance.new("ImageLabel")
		token.Name = "Token"
		token.LayoutOrder = 1
		token.Size = UDim2.fromOffset(14, 14)
		token.BackgroundTransparency = 1
		token.BorderSizePixel = 0
		token.Image = "rbxasset://textures/ui/common/robux@3x.png"
		token.ImageColor3 = PAL.Ink
		token.ScaleType = Enum.ScaleType.Fit
		token.Active = false
		token.ZIndex = 4
		token.Parent = capsule
		local price = text(capsule, "Price", 15, PAL.Ink, Enum.Font.LuckiestGuy, 4)
		price.LayoutOrder = 2
		price.AutomaticSize = Enum.AutomaticSize.X
		price.Size = UDim2.new(0, 0, 1, 0)
		price.Text = "..."
		local choice: ShopChoice = {
			product = product,
			button = b,
			icon = icon,
			name = name,
			capsule = capsule,
			token = token,
			price = price,
			onSale = true,
		}
		shop.choices[i] = choice
	end
end
-- THIS PLAYER'S PRICE, or no number: never WheelData's list price. Roblox is
-- asked the first time this player may buy with the panel open -- so not at
-- all while paid spins are switched off -- and once for the whole session.
shop.watch = function()
	if shop.watching then
		return
	end
	shop.watching = true
	for _, choice in ipairs(shop.choices :: { ShopChoice }) do
		RobuxPrice.watch("product", choice.product.productId, function(state: RobuxPrice.State, amount: number?)
			choice.onSale = state ~= "offsale"
			if state == "ready" and amount then
				choice.price.Text = RobuxPrice.format(amount)
				choice.token.Visible = true
			elseif state == "loading" then
				choice.price.Text = "..."
				choice.token.Visible = true
			elseif state == "offsale" then
				choice.price.Text = "OFF SALE"
				choice.token.Visible = false
			else
				choice.price.Text = "BUY"
				choice.token.Visible = false
			end
			choice.button.Active = choice.onSale
			choice.button.Selectable = choice.onSale
			choice.button.BackgroundColor3 = if choice.onSale then rgb(67, 176, 79) else PAL.HubGrey
		end)
	end
end
-- Where a controller starts in the card: the first choice on sale, else the odds.
shop.first = function(): GuiObject
	for _, choice in ipairs(shop.choices :: { ShopChoice }) do
		if choice.onSale then
			return choice.button
		end
	end
	return shop.odds
end

--==============================================================================
-- SCREEN 3: REWARD INFO
--==============================================================================
-- A button, so a press anywhere on it stays on it (never the wheel or the
-- scrim under it). Fully opaque, and a few pixels past everything it covers.
local sheet = blank(shell, "RewardInfo", 2)
sheet.Visible = false
-- The sheet's still frames, placed by layoutSheet: its foot, gold ring and wood
-- border (the mockup's box-shadows and border), the header's rounded top, its
-- square foot and gold rule, and the footer's rounded bottom, top and rule.
local trim = {
	foot = panel(sheet, "Foot", C.SheetFoot, 25, 1),
	ring = panel(sheet, "Ring", PAL.Gold, 25, 2),
	wood = panel(sheet, "Border", PAL.Wood, 22, 3),
}
local body = panel(sheet, "Body", C.Sheet, 17, 4)
trim.header = panel(body, "Header", C.Header, 17, 1)
trim.headerFoot = panel(body, "HeaderFoot", C.Header, 0, 2)
trim.headerRule = panel(body, "HeaderRule", PAL.Gold, 0, 3)
local backButton = roundButton(body, "Back", C.Blue, C.BlueRim, nil, 6)
chevron(backButton.face)
local sheetClose = roundButton(body, "Close", C.Red, C.RedRim, "X", 6)
local sheetTitle = WheelDraw.words(body, "Title", 28, C.White, PAL.Ink, 2, 5)
sheetTitle.Text = "Reward info"
local sheetTitleDrop = WheelDraw.words(body, "TitleDrop", 28, PAL.Ink, PAL.Ink, 2, 4)
sheetTitleDrop.Text = "Reward info"

local list = Instance.new("ScrollingFrame")
list.Name = "Rewards"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = PAL.Gold
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.Selectable = false
list.ZIndex = 5
list.Parent = body
do
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, ROW_GAP)
	listLayout.Parent = list
end

trim.footer = panel(body, "Footer", C.Footer, 17, 1)
trim.footerTop = panel(body, "FooterTop", C.Footer, 0, 2)
trim.footerRule = panel(body, "FooterRule", PAL.Wood, 0, 3)
local spinsToday = WheelDraw.words(body, "SpinsToday", 16, PAL.Cream, PAL.Ink, 1.5, 6)
spinsToday.TextXAlignment = Enum.TextXAlignment.Left
local nextLine = text(body, "NextSpin", 13, C.FootText, Enum.Font.GothamBold, 6)
nextLine.TextXAlignment = Enum.TextXAlignment.Left
nextLine.TextTruncate = Enum.TextTruncate.AtEnd
local skipButton = blank(body, "SkipAnimation", 6)
skipButton.Selectable = true
UIKit.clicks(skipButton)
local skipBox = panel(skipButton, "Box", C.Footer, 5, 1)
skipBox.AnchorPoint = Vector2.new(0, 0.5)
skipBox.Position = UDim2.new(0, 0, 0.5, 0)
skipBox.Size = UDim2.fromOffset(22, 22)
local skipEdge = ink(skipBox, PAL.Cream, 2)
skipEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local skipTick = text(skipBox, "Tick", 17, C.White, Enum.Font.GothamBlack, 2)
skipTick.Size = UDim2.fromScale(1, 1)
skipTick.Text = "✓"
ink(skipTick, PAL.Ink, 1.5)
local skipWords = text(skipButton, "Words", 15, C.White, Enum.Font.GothamBold, 1)
skipWords.Position = UDim2.fromOffset(30, 0)
skipWords.Size = UDim2.new(1, -30, 1, 0)
skipWords.TextXAlignment = Enum.TextXAlignment.Left
skipWords.Text = "Skip animation"
ink(skipWords, PAL.Ink, 1)

--==============================================================================
-- THE PRIZE ROWS: two columns, commonest first, each prize's rarity and exact
-- odds from WheelData. A pod's row is a button: it opens its species' cards.
--==============================================================================
type Card = {
	card: UIKit.PlantCard,
	id: string,
	-- Undiscovered-looking whatever the Almanac says (the Colossal pod's).
	hidden: boolean,
}

type Row = {
	reward: WheelData.Reward,
	frame: GuiObject,
	-- The row drawn smaller as a whole on a short screen (see layoutSheet).
	fit: UIScale,
	name: TextLabel,
	rarity: TextLabel,
	note: TextLabel,
	odds: TextLabel,
	chevron: TextLabel?,
	grid: Frame?,
	cards: { Card },
}

local rows: { Row } = {}
local pairs_: { Frame } = {}
-- The trail row's rainbow: its name and rarity words (a whole rainbow across
-- each), and its star's (the star's own four stops).
local textRainbows: { UIGradient } = {}
local starRainbows: { UIGradient } = {}

local ordered = table.clone(WheelData.Rewards)
table.sort(ordered, function(a: WheelData.Reward, b: WheelData.Reward): boolean
	if a.weight ~= b.weight then
		return a.weight > b.weight
	end
	return a.id < b.id
end)

local function rarityColour(rarity: string): Color3
	return GameConfig.RarityColor[rarity] or C.White
end

-- The colour a rarity's WORDS are set in: the game's own, but Epic's lighter.
local function rarityText(rarity: string): Color3
	return if rarity == "Epic" then C.EpicText else rarityColour(rarity)
end

local function rainbowText(l: TextLabel)
	l.TextColor3 = C.White
	local g = Instance.new("UIGradient")
	g.Color = WheelDraw.rainbow(0)
	g.Parent = l
	table.insert(textRainbows, g)
	-- A soft light round the letters: a pale copy behind, edged in light.
	local glow = l:Clone()
	for _, child in ipairs(glow:GetChildren()) do
		child:Destroy()
	end
	glow.Name = l.Name .. "Glow"
	glow.TextColor3 = C.Glow
	glow.TextTransparency = 0.55
	glow.ZIndex = l.ZIndex - 1
	ink(glow, C.Glow, 3, 0.6)
	glow.Parent = l.Parent
	l:GetPropertyChangedSignal("Text"):Connect(function()
		glow.Text = l.Text
	end)
	l:GetPropertyChangedSignal("Size"):Connect(function()
		glow.Size = l.Size
	end)
	l:GetPropertyChangedSignal("Position"):Connect(function()
		glow.Position = l.Position
	end)
	l:GetPropertyChangedSignal("Visible"):Connect(function()
		glow.Visible = l.Visible
	end)
end

local function buildRow(pair: Frame, reward: WheelData.Reward, column: number): Row
	local pod = reward.kind == "pod"
	local frame: GuiObject
	if pod then
		local b = blank(pair, "Row_" .. reward.id, 1)
		b.Selectable = true
		UIKit.clicks(b)
		frame = b
	else
		frame = panel(pair, "Row_" .. reward.id, C.Black, 0, 1)
	end
	frame.BackgroundColor3 = if reward.rainbow then C.White else C.Black
	frame.BackgroundTransparency = if reward.rainbow then 0.92 else 0.82
	frame.Position = UDim2.new(if column == 1 then 0 else 0.5, if column == 1 then 0 else 3, 0, 0)
	frame.Size = UDim2.new(0.5, -3, 1, 0)
	UIKit.corner(frame, 10)
	local fit = Instance.new("UIScale")
	fit.Name = "Fit"
	fit.Scale = 1
	fit.Parent = frame
	if reward.rainbow then
		-- The rarest: a gold border so it stands out.
		local gold = ink(frame, PAL.Gold, 2)
		gold.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end

	local iconHolder = panel(frame, "IconHolder", C.Black, 0, 1)
	iconHolder.BackgroundTransparency = 1
	place(iconHolder, 10, 4, 26, 26)
	local icon = WheelDraw.icon(iconHolder, reward, 19.5)
	icon.box.Position = UDim2.fromScale(0.5, 0.5)
	for _, g in ipairs(icon.rainbow) do
		table.insert(starRainbows, g)
	end

	local colour = rarityText(reward.rarity)
	local name = WheelDraw.words(frame, "Name", 17, colour, C.NameInk, 1.5, 3)
	name.Text = reward.short
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local line = panel(frame, "RarityLine", C.Black, 0, 3)
	line.BackgroundTransparency = 1
	local lineList = Instance.new("UIListLayout")
	lineList.FillDirection = Enum.FillDirection.Horizontal
	lineList.VerticalAlignment = Enum.VerticalAlignment.Center
	lineList.SortOrder = Enum.SortOrder.LayoutOrder
	lineList.Padding = UDim.new(0, 6)
	lineList.Parent = line
	-- The trail's rarity word gets a holder of its own, so its glow can stand
	-- behind it rather than being laid out beside it by the line's list.
	local rarityParent: Instance = line
	if reward.rainbow then
		local holder = panel(line, "RarityHolder", C.Black, 0, 3)
		holder.BackgroundTransparency = 1
		holder.AutomaticSize = Enum.AutomaticSize.X
		holder.Size = UDim2.new(0, 0, 1, 0)
		holder.LayoutOrder = 1
		rarityParent = holder
	end
	local rarity = text(rarityParent, "Rarity", 11, colour, Enum.Font.GothamBlack, 3)
	rarity.AutomaticSize = Enum.AutomaticSize.X
	rarity.Size = UDim2.new(0, 0, 1, 0)
	rarity.LayoutOrder = 1
	rarity.Text = reward.rarity
	ink(rarity, C.NameInk, 1)
	-- A size above the rarity word: on a phone the row is drawn at 0.85, and at
	-- 11 the space in "species hidden" all but vanished.
	local note = text(line, "Note", 12, C.Note, Enum.Font.GothamBold, 3)
	note.AutomaticSize = Enum.AutomaticSize.X
	note.Size = UDim2.new(0, 0, 1, 0)
	note.LayoutOrder = 2
	note.Text = reward.note or ""
	note.Visible = reward.note ~= nil
	ink(note, C.NameInk, 1, 0.3)
	-- A pod is one of several species, each a final outcome of its own: the
	-- row says how many and what each one's odds are before it is ever opened
	-- (its cards then name them one by one). Read from WheelData, like every
	-- other number here.
	if pod then
		local pool = WheelData.poolOdds(reward)
		if #pool > 0 then
			note.Text = string.format(if reward.note then "%d hidden species, %s each" else "%d species, %s each",
				#pool, WheelData.percent(pool[1].probability))
			note.Visible = true
		end
	end

	local odds = WheelDraw.words(frame, "Odds", 16, C.White, PAL.Ink, 1.5, 3)
	odds.AnchorPoint = Vector2.new(1, 0.5)
	odds.TextXAlignment = Enum.TextXAlignment.Right
	odds.Text = WheelData.percent(reward.weight / WheelData.TotalWeight)

	local arrow: TextLabel? = nil
	if pod then
		-- The row opens: a cream arrow that turns over while its cards show.
		local a = text(frame, "Chevron", 16, PAL.Cream, Enum.Font.GothamBlack, 3)
		a.AnchorPoint = Vector2.new(0.5, 0.5)
		a.Size = UDim2.fromOffset(20, 20)
		a.Text = "▼"
		ink(a, PAL.Ink, 1.5)
		arrow = a
	end

	if reward.rainbow then
		rainbowText(name)
		rainbowText(rarity)
		name.ZIndex, rarity.ZIndex = 4, 4
	end

	return {
		reward = reward,
		frame = frame,
		fit = fit,
		name = name,
		rarity = rarity,
		note = note,
		odds = odds,
		chevron = arrow,
		grid = nil,
		cards = {},
	}
end

do
	local order = 0
	for i = 1, #ordered, 2 do
		order += 1
		local pair = panel(list, "Pair" .. ((i + 1) // 2), C.Black, 0, 1)
		pair.BackgroundTransparency = 1
		pair.LayoutOrder = order * 2
		table.insert(pairs_, pair)
		local podRow: Row? = nil
		for column = 1, 2 do
			local reward = ordered[i + column - 1]
			if reward then
				local row = buildRow(pair, reward, column)
				table.insert(rows, row)
				if reward.kind == "pod" then
					podRow = row
				end
			end
		end
		-- The pair's card grid, under it, shut until its pod row is pressed.
		if podRow then
			local grid = panel(list, "Species_" .. podRow.reward.id, C.Black, 0, 1)
			grid.BackgroundTransparency = 1
			grid.LayoutOrder = order * 2 + 1
			grid.Visible = false
			local layout = Instance.new("UIGridLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
			layout.Parent = grid
			-- Room at the sides for the cards' rarity borders, which a Border
			-- stroke draws outside the card and the list would otherwise clip.
			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 4)
			pad.PaddingBottom = UDim.new(0, 6)
			pad.PaddingLeft = UDim.new(0, 4)
			pad.PaddingRight = UDim.new(0, 4)
			pad.Parent = grid
			podRow.grid = grid
		end
	end
end

local function rowFor(id: string): Row?
	for _, row in ipairs(rows) do
		if row.reward.id == id then
			return row
		end
	end
	return nil
end

--==============================================================================
-- WORDS FROM THE ATTRIBUTES
--==============================================================================
local function num(name: string): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

local function span(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h, m = s // 3600, (s // 60) % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%dm %02ds", m, s % 60)
end

local function ownsTrail(): boolean
	return player:GetAttribute(A.TrailOwned) == true
end

local function paidAllowed(): boolean
	return player:GetAttribute(A.PaidAllowed) == true
end

-- Spins this player can use now: earned ones, and bought ones only where paid
-- spins are allowed at all.
local function usable(): number
	return num(A.Earned) + (if paidAllowed() then num(A.Bought) else 0)
end

-- The day's allowance: spins earned in the open window, and seconds left in it
-- (nil when no window is open).
local function allowance(): (number, number?)
	local endsAt = player:GetAttribute(A.DayEndsAt)
	local left = if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else nil
	if left and left <= 0 then
		left = nil
	end
	return if left then num(A.DayCount) else 0, left
end

local open = false
local spinning = false
local waiting = false
local skip = false

-- A win or a refusal held in the line under the wheel for a while.
type LineNote = { words: string, colour: Color3, rainbow: boolean, untilAt: number }
local lineNote: LineNote? = nil

local function lineState(): (string, Color3, boolean, boolean)
	-- words, colour, CLAIM shown, rainbow
	if spinning or waiting then
		return "", PAL.Cream, false, false
	end
	local held = lineNote
	if held and os.clock() < held.untilAt then
		return held.words, held.colour, false, held.rainbow
	end
	local pending = num(A.Pending)
	if pending > 0 then
		return if pending == 1 then "1 prize waiting for bag space"
			else string.format("%d prizes waiting for bag space", pending), PAL.Cream, true, false
	end
	if usable() <= 0 then
		local count, left = allowance()
		if left and count >= WheelData.Daily.Limit then
			return string.format("Daily spins earned. Resets in %s", span(left)), PAL.Cream, false, false
		end
		return "Beat the obby to earn a spin", PAL.Cream, false, false
	end
	return "", PAL.Cream, false, false
end

--==============================================================================
-- PAINTING
--==============================================================================
local sheetOpen = false

local function paintFooter()
	local limit = WheelData.Daily.Limit
	local count, left = allowance()
	spinsToday.Text = string.format("Obby spins today: %d/%d", count, limit)
	if count >= limit and left then
		local main = tonumber(player:GetAttribute(OA.RewardMain))
		nextLine.Text = if main
			then string.format("Daily spins earned! Complete the obby for +%s Speed. Resets in %s.",
				GameConfig.compact(main), span(left))
			else string.format("Daily spins earned! Resets in %s.", span(left))
	elseif left then
		nextLine.Text = string.format("Next obby completion earns 1 spin. Resets in %s.", span(left))
	else
		nextLine.Text = "Next obby completion earns 1 spin."
	end
	skipTick.Visible = skip
	skipBox.BackgroundColor3 = if skip then PAL.Gold else C.Footer
	skipEdge.Color = if skip then PAL.Gold else PAL.Cream

	-- The trail's row says what it pays a player who owns it already.
	local trail = rowFor(WheelData.ById.trail.id)
	if trail then
		local swap = WheelData.ById[WheelData.ById.trail.swap or ""]
		trail.note.Visible = ownsTrail()
		trail.note.Text = string.format("owned: pays %s instead", if swap then swap.short else "cash")
	end
end

local function paint()
	-- BUYING, and spending what was bought, are for a player the server says
	-- may: nobody while paid spins are switched off. A card that is up when that
	-- stops being true goes at once. Closing it paints again, so this pass ends.
	local may = paidAllowed()
	if shop.open and not may then
		shop.show(false)
		return
	end
	if confirm.Visible and not may then
		shop.confirm(false)
		return
	end

	local count = usable()
	local busy = spinning or waiting
	local ready = count > 0
	local hub = hubFace
	if hub then
		hub.setState(if ready then "ready" else "empty", count)
	end
	-- A CARD OVER THE HUB -- the two to buy, or the question before a purchased
	-- spin -- keeps the controller until it is answered: nothing behind it takes
	-- the selection, so the D-pad cannot walk out to "?" and find no way back.
	-- A finger or a mouse still reaches "?" and X.
	local card = shop.open == true or confirm.Visible
	local behind = sheetOpen or card

	-- Not tappable at 0 (screen 2), nor while a spin is in the air.
	hubButton.Active = ready and not busy
	hubButton.AutoButtonColor = false
	hubButton.Selectable = ready and not busy and not behind

	local words, colour, claim, rainbow = lineState()
	lineText.Text = words
	lineText.TextColor3 = if rainbow then C.White else colour
	lineGradient.Enabled = rainbow
	lineText.Visible = words ~= ""
	claimButton.Visible = claim
	claimButton.Selectable = claim and not behind

	-- GET SPINS, and the word under "?" that says where the odds are: there
	-- whenever a purchase can be made, and only then.
	local getSpins = shop.button :: TextButton
	getSpins.Visible = may
	getSpins.Active = may and not busy
	getSpins.Selectable = may and not busy and not behind
	getSpins.BackgroundColor3 = if busy then PAL.HubGrey else rgb(214, 150, 46)
	shop.infoWord.Visible = may
	if may then
		shop.watch()
	end

	-- The controller: inside the card while one is up, else the hub when it can
	-- spin, "?" when it cannot.
	local info, close = infoButton.button, closeButton.button
	info.Selectable = not behind
	close.Selectable = not behind
	padFirst.Value = if shop.open then shop.first()
		elseif confirm.Visible then confirmYes
		elseif hubButton.Selectable then hubButton
		else info
	info.NextSelectionRight = close
	close.NextSelectionLeft = info
	info.NextSelectionDown = if hubButton.Selectable then hubButton elseif claim then claimButton else nil
	close.NextSelectionDown = if getSpins.Selectable then getSpins else info.NextSelectionDown
	hubButton.NextSelectionUp = info
	hubButton.NextSelectionLeft = info
	hubButton.NextSelectionRight = if getSpins.Selectable then getSpins else close
	hubButton.NextSelectionDown = if claim then claimButton else nil
	claimButton.NextSelectionUp = if hubButton.Selectable then hubButton else info
	getSpins.NextSelectionLeft = if hubButton.Selectable then hubButton else info
	getSpins.NextSelectionUp = close

	if sheetOpen then
		paintFooter()
	end
end

local noteToken = 0
local function holdLine(words: string, colour: Color3, seconds: number, rainbow: boolean?)
	noteToken += 1
	local mine = noteToken
	lineNote = { words = words, colour = colour, rainbow = rainbow == true, untilAt = os.clock() + seconds }
	paint()
	task.delay(seconds + 0.05, function()
		if noteToken == mine then
			lineNote = nil
			paint()
		end
	end)
end

--==============================================================================
-- THE ALMANAC: which species this player has grown (IndexUI's own source)
--==============================================================================
local almanac: { [string]: boolean } = {}
local expanded: Row? = nil

local function tintCards(row: Row)
	for _, entry in ipairs(row.cards) do
		local known = almanac[entry.id] == true and not entry.hidden
		local view = entry.card.hero
		view.ImageColor3 = if known then C.White else ALMANAC.Silhouette
		view.ImageTransparency = if known then 0 else 0.1
	end
end

--==============================================================================
-- THE CARDS
--
-- The Garden's own card (UIKit.plantCard): the species' grown model at its
-- base size on its biome's backdrop, the rarity on the border, the name and
-- its pill; this panel adds the odds badge. A species the player has not grown
-- yet is its silhouette, the Index's tint, with its name and odds still shown;
-- every Colossal card is a silhouette with a "?", the species being the
-- hatch's to reveal.
--
-- BUILT ON FIRST OPEN AND KEPT. One model per species for the whole session,
-- moved into whichever card shows it: only one grid is open at a time, so a
-- species is never wanted in two places at once, and reopening a grid builds
-- nothing. At most thirteen models (five common, eight rare), none moving.
--==============================================================================
type Portrait = { model: Model, camera: Camera }
local portraits: { [string]: Portrait } = {}

local function showPortrait(view: ViewportFrame, speciesId: string)
	local species = SeedData.Get(speciesId)
	if not species then
		return
	end
	local entry = portraits[speciesId]
	if entry then
		if entry.model.Parent ~= view then
			entry.model.Parent = view
			entry.camera.Parent = view
		end
		view.CurrentCamera = entry.camera
		return
	end
	local model = CreatureModel.Build(species, SeedData.BaseTier, CreatureModel.STAGE_GROWN, CFrame.new(), view)
	if model then
		local camera = UIKit.framePlant(view, model, species.Form, CARD_FILL)
		portraits[speciesId] = { model = model, camera = camera }
	end
end

local function buildCards(row: Row)
	local grid = row.grid
	if not grid or #row.cards > 0 then
		return
	end
	local hidden = row.reward.id == "pod_colossal"
	for i, entry in ipairs(WheelData.poolOdds(row.reward)) do
		local card = UIKit.plantCard(grid, {
			name = "Card_" .. entry.id,
			layoutOrder = i,
			nameSize = 13,
			subSize = 11,
		})
		local colour = rarityColour(entry.rarity)
		local words = rarityText(entry.rarity)
		card.setStageTheme("grown")
		card.setBackdrop(entry.id)
		card.name.Text = entry.name
		card.name.TextColor3 = words
		card.sub.Text = string.upper(entry.rarity)
		card.sub.TextColor3 = words
		card.setSubPill(true, colour)
		card.border.Color = colour
		-- The odds badge, top right, over everything on the card.
		local badge = panel(card.button, "Odds", rgb(14, 12, 18), 6, 30)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, -5, 0, 5)
		badge.Size = UDim2.fromOffset(0, 18)
		badge.AutomaticSize = Enum.AutomaticSize.X
		badge.BackgroundTransparency = 0.15
		local badgeEdge = ink(badge, PAL.Gold, 1.5)
		badgeEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 5)
		pad.PaddingRight = UDim.new(0, 5)
		pad.Parent = badge
		local odds = text(badge, "Words", 12, C.White, Enum.Font.GothamBlack, 31)
		odds.AutomaticSize = Enum.AutomaticSize.X
		odds.Size = UDim2.new(0, 0, 1, 0)
		odds.Text = WheelData.percent(entry.probability)
		if hidden then
			local mark = WheelDraw.words(card.button, "Hidden", 44, C.White, PAL.Ink, 3, 29)
			mark.AnchorPoint = Vector2.new(0.5, 0.5)
			mark.Position = UDim2.fromScale(0.5, 0.38)
			mark.Size = UDim2.fromScale(0.6, 0.45)
			mark.Text = "?"
		end
		table.insert(row.cards, { card = card, id = entry.id, hidden = hidden })
	end
end

-- The card grid's size for the list's width, and the list's canvas with it.
local cellW, cellH, columns = CARD_WIDTH, math.floor(CARD_WIDTH * CARD_ASPECT), 4

local function sizeGrids(listWidth: number)
	-- Inside the grid's side padding.
	local width = listWidth - 8
	columns = math.max(3, math.floor((width + CARD_GAP) / (CARD_WIDTH + CARD_GAP)))
	cellW = math.floor((width - CARD_GAP * (columns - 1)) / columns)
	cellH = math.floor(cellW * CARD_ASPECT)
	for _, row in ipairs(rows) do
		local grid = row.grid
		if grid then
			local layout = grid:FindFirstChildOfClass("UIGridLayout")
			if layout then
				layout.CellSize = UDim2.fromOffset(cellW, cellH)
			end
			local n = #WheelData.poolOdds(row.reward)
			local lines = math.max(1, math.ceil(n / columns))
			grid.Size = UDim2.new(1, -8, 0, lines * cellH + (lines - 1) * CARD_GAP + 10)
		end
	end
end

local function setExpanded(row: Row?)
	local was = expanded
	if was then
		local grid = was.grid
		if grid then
			grid.Visible = false
		end
		local arrow = was.chevron
		if arrow then
			arrow.Rotation = 0
		end
	end
	expanded = if row == was then nil else row
	local now = expanded
	if not now then
		return
	end
	local grid = now.grid
	if not grid then
		return
	end
	buildCards(now)
	grid.Visible = true
	local arrow = now.chevron
	if arrow then
		arrow.Rotation = 180
	end
	tintCards(now)
	-- The models, one per frame after the first so a big pool opens smoothly.
	task.spawn(function()
		for i, entry in ipairs(now.cards) do
			if expanded ~= now or not open then
				return
			end
			showPortrait(entry.card.hero, entry.id)
			if i < #now.cards then
				RunService.Heartbeat:Wait()
			end
		end
	end)
	-- Scroll so the opened grid shows under its row, once the list has laid it
	-- out (two frames: the grid was hidden a moment ago).
	task.spawn(function()
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()
		if expanded ~= now then
			return
		end
		local k = UIKit.scaleOf(list)
		local view = list.AbsoluteSize.Y / k
		local top = (now.frame.AbsolutePosition.Y - list.AbsolutePosition.Y) / k + list.CanvasPosition.Y
		local bottom = (grid.AbsolutePosition.Y - list.AbsolutePosition.Y + grid.AbsoluteSize.Y) / k
			+ list.CanvasPosition.Y
		local total = list.AbsoluteCanvasSize.Y / k
		-- Taller than the list (eight cards on a phone): from its row down, so the
		-- player sees what opened and the first cards, and scrolls for the rest.
		local want = if bottom - top > view then math.clamp(top, 0, math.max(0, total - view))
			else UIKit.scrollToShow(list.CanvasPosition.Y, view, top, bottom, total)
		list.CanvasPosition = Vector2.new(0, want)
	end)
end

for _, row in ipairs(rows) do
	local frame = row.frame
	if frame:IsA("GuiButton") then
		frame.Activated:Connect(function()
			setExpanded(row)
		end)
	end
end

--==============================================================================
-- LAYOUT: everything in the gui's own units (pixels / its TV and menu scale)
--==============================================================================
local function buildWheel(d: number)
	if drawn and drawnSize == d then
		return
	end
	local angle = if drawn then drawn.angle() else 0
	if drawn then
		drawn.root:Destroy()
	end
	if hubFace then
		hubFace.root:Destroy()
	end
	drawnSize = d
	local w = WheelDraw.build(wheelHolder, d, { labels = true })
	w.setAngle(angle)
	drawn = w
	local hub = WheelDraw.hub(stage, math.floor(d * 100 / 296 + 0.5))
	hub.root.ZIndex = 4
	hubFace = hub
end

-- Where Roblox's own topbar buttons are, in gui units: the band's height and
-- the free stretch between the left and right groups.
local function topbarBand(k: number, W: number): (number, number, number)
	local inset = GuiService.TopbarInset
	local bottom = inset.Max.Y / k
	local left = inset.Min.X / k
	local right = if inset.Max.X > 0 then inset.Max.X / k else W
	return bottom, left, right
end

--==============================================================================
-- WHERE GET SPINS AND ITS CARD STAND
--
-- The button beside the wheel, on its right, wherever the screen is wide
-- enough -- every landscape phone and desktop -- and under the line below the
-- wheel on a window too narrow for that (a phone held upright). A window with
-- room for neither, 640 x 480, has it in the corner the wheel's circle leaves
-- free, ABOVE the line: the line's words run the width of the screen.
-- Thumb-sized (46 tall), and never on the wheel, the pointer, the round buttons
-- or the line. The card is centred on the hub like the purchased-spin question,
-- and fits a 338-tall phone whole.
--
-- Both are drawn `f` times their phone size (shop.grow: 1 on a phone, up to
-- 1.25 on a desktop) by a UIScale of their own, so every number below is the
-- phone's, and only where they stand is worked out at the size they show.
--==============================================================================
shop.layout = function(W: number, H: number, cx: number, cy: number, d: number, lineTop: number,
	lineBottom: number)
	local R = d / 2
	local f = shop.grow(W, H)
	local bw, bh = 132 * f, 46 * f
	local x, y
	if W - (cx + R) >= bw + 22 then
		x, y = math.min(cx + R + 14 + bw / 2, W - 8 - bw / 2), cy
	elseif H - lineBottom >= bh + 8 then
		x, y = cx, lineBottom + 4 + bh / 2
	else
		x, y = W - 8 - bw / 2, lineTop - 4 - bh / 2
	end
	local button = shop.button :: TextButton
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromOffset(x, y)
	button.Size = UDim2.fromOffset(132, 46)
	shop.buttonScale.Scale = f

	local cw = math.min(336, math.floor((W - 24) / f))
	local choiceH = 86
	local noteH = 44
	local ch = 40 + choiceH + 6 + noteH + 6 + 38 + 10
	local half = ch * f / 2
	local card = shop.card :: Frame
	card.Position = UDim2.fromOffset(cx, math.clamp(cy, half + 4, math.max(half + 4, H - half - 4)))
	card.Size = UDim2.fromOffset(cw, ch)
	shop.cardScale.Scale = f
	place(shop.title, 12, 8, cw - 24, 26)
	local each = math.floor((cw - 24 - 10) / 2)
	for i, choice in ipairs(shop.choices :: { ShopChoice }) do
		place(choice.button, 12 + (i - 1) * (each + 10), 40, each, choiceH)
		place(choice.icon, 6, 6, 46, 46)
		place(choice.name, 54, 8, each - 58, 24)
		choice.name.TextSize = if each < 140 then 14 else 16
		choice.capsule.Position = UDim2.new(0.5, 0, 0, 56)
		choice.capsule.Size = UDim2.new(0, 0, 0, 24)
	end
	place(shop.note, 14, 40 + choiceH + 6, cw - 28, noteH)
	local oddsW = math.floor((cw - 24 - 10) * 0.64)
	place(shop.odds, 12, ch - 48, oddsW, 38)
	place(shop.close, 12 + oddsW + 10, ch - 48, cw - 24 - 10 - oddsW, 38)
end

local function layoutStage(W: number, H: number, k: number)
	-- The mockup's phone: a 296 wheel whose top is 58 down a 390 screen, the
	-- pointer standing 30 above it, the line in the 32 under it.
	local lineRoom = 32
	local d = math.floor(math.min((H - 28 - lineRoom) / (1 + 30 / 296), W - 48, MAX_WHEEL))
	d = math.max(d, 140)
	local s = d / 296
	local blockH = 28 + 30 * s + d + lineRoom
	local top = math.max(0, math.floor((H - blockH) / 2))
	local wheelTop = top + 28 + 30 * s
	local cx, cy = W / 2, wheelTop + d / 2

	buildWheel(d)
	place(wheelHolder, cx - d / 2, wheelTop, d, d)
	place(wheelBlock, cx - d / 2, wheelTop, d, d)

	-- The pin: head radius 13.5, edge 2.7 (the mockup's 15 and 3 at 0.9), its
	-- tip 9 into the rim.
	local r, e = 13.5 * s, 2.7 * s
	local headY = wheelTop + 9 * s - r * math.sqrt(2)
	pin.headEdge.Position = UDim2.fromOffset(cx, headY)
	pin.headEdge.Size = UDim2.fromOffset((r + e / 2) * 2, (r + e / 2) * 2)
	pin.head.Position = UDim2.fromOffset(cx, headY)
	pin.head.Size = UDim2.fromOffset((r - e / 2) * 2, (r - e / 2) * 2)
	local tipY = headY + r / math.sqrt(2)
	pin.tipEdge.Position = UDim2.fromOffset(cx, tipY)
	pin.tipEdge.Size = UDim2.fromOffset(r + e, r + e)
	pin.tip.Position = UDim2.fromOffset(cx, tipY)
	pin.tip.Size = UDim2.fromOffset(r - e, r - e)
	pin.dot.Position = UDim2.fromOffset(cx, headY + 1.3 * s)
	pin.dot.Size = UDim2.fromOffset(10.8 * s, 10.8 * s)

	-- The hub: the mockup's 92 button in its 100 ring.
	local hub = hubFace
	if hub then
		hub.root.Position = UDim2.fromOffset(cx, cy)
	end
	hubButton.Position = UDim2.fromOffset(cx, cy)
	hubButton.Size = UDim2.fromOffset(d * 92 / 296, d * 92 / 296)

	-- "?" and X: thumb-sized, flanking the wheel's top, clear of the circle.
	local bd = math.max(48, math.floor(48 * math.min(s, 1.25) + 0.5))
	local border = math.max(3, math.floor(bd / 16 + 0.5))
	local footPx = math.max(3, math.floor(bd / 12 + 0.5))
	local glyphPx = math.floor(bd * 26 / 48 + 0.5)
	infoButton.resize(bd, border, footPx, glyphPx)
	closeButton.resize(bd, border, footPx, glyphPx)
	local R = d / 2
	local reach, by = R - 6 * s, wheelTop - 18 * s
	-- Roblox's own buttons own the ends of the topbar's band. Where these would
	-- reach them (a phone's scaled screen: the left group runs to 208 of 705 in
	-- Studio's iPhone 14), both step in, still flanking the pointer; only if
	-- that would bring them onto the rim do they stand beside the wheel.
	local bandBottom, bandLeft, bandRight = topbarBand(k, W)
	if by - bd / 2 < bandBottom then
		reach = math.min(reach, cx - (bandLeft + 8 + bd / 2), (bandRight - 8 - bd / 2) - cx)
	end
	local clear = R + bd / 2 + 4
	if reach * reach + (cy - by) ^ 2 < clear * clear then
		reach = math.min(R + 10 + bd / 2, cx - 8 - bd / 2, W - 8 - bd / 2 - cx)
		by = math.max(bandBottom + 4 + bd / 2, wheelTop + bd / 2)
	end
	infoButton.button.Position = UDim2.fromOffset(cx - reach, by)
	closeButton.button.Position = UDim2.fromOffset(cx + reach, by)

	-- The line under the wheel.
	local linePx = math.floor(math.clamp(15 * s, 15, 22) + 0.5)
	lineText.TextSize = linePx
	lineText.Size = UDim2.fromOffset(0, linePx + 4)
	claimButton.Size = UDim2.fromOffset(math.floor(linePx * 4.8), linePx + 12)
	claimWords.TextSize = math.max(13, linePx - 1)
	place(lineRow, 8, wheelTop + d + 4, W - 16, math.max(linePx + 12, 26))

	-- The purchased-spin question over the hub, and under it the way to the
	-- odds, in words. Drawn at the card's size (shop.grow).
	local grow = shop.grow(W, H)
	local cw = math.min(280, math.floor((W - 32) / grow))
	confirm.Position = UDim2.fromOffset(cx, cy)
	confirm.Size = UDim2.fromOffset(cw, 164)
	shop.questionScale.Scale = grow
	place(confirmText, 12, 8, cw - 24, 50)
	place(confirmYes, 12, 66, math.floor(cw * 0.58) - 16, 40)
	place(confirmNo, math.floor(cw * 0.58) + 4, 66, cw - math.floor(cw * 0.58) - 16, 40)
	place(shop.confirmOdds, 12, 114, cw - 24, 38)

	-- The word under "?".
	shop.infoWord.Position = UDim2.fromOffset(cx - reach, by + bd / 2 + math.max(3, footPx))
	shop.infoWord.Size = UDim2.fromOffset(0, 14)
	shop.infoWord.AutomaticSize = Enum.AutomaticSize.X

	shop.layout(W, H, cx, cy, d, wheelTop + d + 4, wheelTop + d + 4 + math.max(linePx + 12, 26))
end

local function layoutSheet(W: number, H: number, k: number, insetL: number, insetR: number)
	-- The mockup's sheet: 760 x 362 on its 844 x 390 phone, centred -- 42 in
	-- from the SCREEN's sides, so where a notch strip already takes 47 of that
	-- the sheet keeps only 8 more inside the safe area (689 of 705 in Studio's
	-- iPhone 14, rather than 621). Capped at 820 wide on a big screen.
	local mL, mR = math.max(8, 42 - insetL), math.max(8, 42 - insetR)
	local sw = math.floor(math.clamp(W - mL - mR, 300, 820))
	local sh = math.floor(math.clamp(H - 28, 220, 540))
	local sx = math.floor(mL + (W - mL - mR - sw) / 2)
	local sy = math.floor((H - sh) / 2)
	place(sheet, sx - 6, sy - 6, sw + 12, sh + 18)
	-- In the sheet's own space, offset by the 6 it reaches past the ring.
	local ox, oy = 6, 6
	place(trim.foot, ox - 3, oy - 3 + 6, sw + 6, sh + 6)
	place(trim.ring, ox - 3, oy - 3, sw + 6, sh + 6)
	place(trim.wood, ox, oy, sw, sh)
	local bw, bh = sw - 10, sh - 10
	place(body, ox + 5, oy + 5, bw, bh)

	--==========================================================================
	-- ALL TWELVE PRIZES WITHOUT A SCROLL, ON A SHORT SCREEN TOO
	--
	-- The mockup's sizes need a 362-tall sheet; a landscape phone's safe area
	-- gives less (310 in Studio's iPhone 14, 341 on the phone itself), and the
	-- sixth pair -- the Colossal pod and the gold-edged trail -- fell below the
	-- fold. So on a short screen the header and footer tighten and the rows are
	-- drawn smaller as a whole (a UIScale per row: words, icon and odds alike),
	-- no further than 28 of their 34 -- the mockup's own scale on a 338-tall
	-- screen.
	--==========================================================================
	local count = #pairs_
	local full = count * ROW_HEIGHT + (count - 1) * ROW_GAP
	local compact = bh - (52 + 3 + 8) - (52 + 6) < full
	local headH = if compact then 46 else 52
	local footH = if compact then 44 else 52
	local topPad = if compact then 6 else 8
	local bottomPad = if compact then 4 else 6
	local gap = if compact then 4 else ROW_GAP
	local listTop = headH + 3 + topPad
	local listH = bh - footH - listTop - bottomPad
	local rowH = math.clamp(math.floor((listH - (count - 1) * gap) / count), 28, ROW_HEIGHT)
	local fit = rowH / ROW_HEIGHT

	place(trim.header, 0, 0, bw, headH)
	place(trim.headerFoot, 0, headH - 20, bw, 20)
	place(trim.headerRule, 0, headH, bw, 3)
	-- The header's buttons step clear of Roblox's own where the band reaches it.
	local bandBottom, bandLeft, bandRight = topbarBand(k, W)
	local bodyX = sx + 5
	local headerTop = sy + 5
	local padL, padR = 12, 12
	if headerTop < bandBottom then
		padL = math.max(12, math.ceil(bandLeft + 8 - bodyX))
		padR = math.max(12, math.ceil(bodyX + bw - (bandRight - 8)))
	end
	local button = if compact then 36 else 40
	backButton.resize(button, 3, 3, if compact then 19 else 21)
	sheetClose.resize(button, 3, 3, if compact then 19 else 21)
	local buttonY = math.floor((headH - button) / 2) - 1
	place(backButton.button, padL, buttonY, button, button)
	place(sheetClose.button, bw - padR - button, buttonY, button, button)
	sheetTitle.TextSize = if compact then 25 else 28
	sheetTitleDrop.TextSize = sheetTitle.TextSize
	place(sheetTitle, padL + button + 8, 0, bw - padL - padR - 2 * (button + 8), headH)
	place(sheetTitleDrop, padL + button + 8, 3, bw - padL - padR - 2 * (button + 8), headH)

	place(trim.footer, 0, bh - footH, bw, footH)
	place(trim.footerTop, 0, bh - footH, bw, 20)
	place(trim.footerRule, 0, bh - footH, bw, 2)
	local skipW = 176
	spinsToday.TextSize = if compact then 15 else 16
	nextLine.TextSize = if compact then 12 else 13
	place(spinsToday, 16, bh - footH + (if compact then 5 else 8), bw - skipW - 40, 19)
	place(nextLine, 16, bh - footH + (if compact then 25 else 29), bw - skipW - 40, 16)
	place(skipButton, bw - skipW - 12, bh - footH + math.floor((footH - 28) / 2), skipW, 28)

	place(list, 14, listTop, bw - 28, listH)
	local listLayout = list:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		listLayout.Padding = UDim.new(0, gap)
	end
	local listW = bw - 28 - 8
	for _, pair in ipairs(pairs_) do
		pair.Size = UDim2.new(1, -8, 0, rowH)
	end
	-- Each row is laid out at the mockup's 34 in its own units, `fit` of them to
	-- a drawn pixel: its size is divided by `fit` so it still spans its column.
	local rw = math.floor((listW - 6) / 2) / fit
	local oddsW = 64
	for _, row in ipairs(rows) do
		row.fit.Scale = fit
		row.frame.Size = UDim2.new(0.5 / fit, -3 / fit, 1 / fit, 0)
		place(row.name, 46, 1, rw - 46 - oddsW - 22, 19)
		local line = row.name.Parent and row.name.Parent:FindFirstChild("RarityLine")
		if line and line:IsA("GuiObject") then
			place(line, 46, 20, rw - 46 - oddsW - 8, 13)
		end
		row.odds.Position = UDim2.new(1, -10, 0.5, 0)
		row.odds.Size = UDim2.fromOffset(oddsW, 20)
		local arrow = row.chevron
		if arrow then
			arrow.Position = UDim2.new(1, -10 - oddsW - 6, 0.5, 0)
		end
	end
	sizeGrids(listW)
end

local function layout()
	local k = UIKit.scaleOf(gui)
	local area = gui.AbsoluteSize / UIKit.scaleOf(gui)
	local W, H = math.floor(area.X), math.floor(area.Y)
	if W <= 0 or H <= 0 then
		return
	end
	local insetL, insetR = reachEdges(k)
	layoutStage(W, H, k)
	layoutSheet(W, H, k, insetL, insetR)
	paint()
end

--==============================================================================
-- THE RAINBOWS: one RenderStepped while the panel is open, none while it is shut
--==============================================================================
local rainbowConn: RBXScriptConnection? = nil

local function motionOff(): boolean
	return player:GetAttribute("SeedAfterimageQuality") == "Off"
end

local function rainbowTick()
	local shift = (os.clock() / RAINBOW_SECONDS) % 1
	local d = drawn
	if d then
		d.setRainbow(shift)
	end
	local lit = sheetOpen
	if lit or lineGradient.Enabled then
		local surface = WheelDraw.rainbow(shift)
		lineGradient.Color = surface
		if lit then
			for _, g in ipairs(textRainbows) do
				g.Color = surface
			end
			local star = WheelDraw.rainbow(shift, 0.15, 0.85, true)
			for _, g in ipairs(starRainbows) do
				g.Color = star
			end
		end
	end
end

local function refreshRainbows()
	local want = open and not motionOff()
	if want and not rainbowConn then
		rainbowConn = RunService.RenderStepped:Connect(rainbowTick)
	elseif not want and rainbowConn then
		rainbowConn:Disconnect()
		rainbowConn = nil
	end
end
player:GetAttributeChangedSignal("SeedAfterimageQuality"):Connect(refreshRainbows)

--==============================================================================
-- THE WORLD WHEEL: its faces, and the sign's slow colour drift
--==============================================================================
local worldFace: WheelDraw.Drawn? = nil
local signGradient: UIGradient? = nil
local signAnchor: BasePart? = nil
local promptAnchor: BasePart? = nil

task.spawn(function()
	local folder = Workspace:WaitForChild(WheelData.FolderName, math.huge)
	local model = folder and folder:WaitForChild("RewardWheel", math.huge)
	if not model then
		return
	end
	for _, name in ipairs({ "FaceFront", "FaceBack" }) do
		local faceHolder = model:WaitForChild(name, 30)
		if faceHolder and faceHolder:IsA("BasePart") then
			local old = faceHolder:FindFirstChild("WheelFace")
			if old then
				old:Destroy()
			end
			local surface = Instance.new("SurfaceGui")
			surface.Name = "WheelFace"
			surface.Face = Enum.NormalId.Front
			surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			surface.CanvasSize = Vector2.new(600, 600)
			surface.LightInfluence = 0.3
			surface.MaxDistance = 250
			surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			surface.ResetOnSpawn = false
			surface.Parent = faceHolder
			-- The same face, its rainbow standing still, and the green hub round
			-- the model's gold cap.
			local face = WheelDraw.build(surface, 600, { labels = true, hub = true })
			if name == "FaceFront" then
				worldFace = face
			end
		end
	end
	local anchor = model:WaitForChild("SignAnchor", 30)
	local board = anchor and anchor:FindFirstChild("SpinSign")
	local words = board and board:FindFirstChild("Words")
	local gradient = words and words:FindFirstChild("Rainbow")
	if gradient and gradient:IsA("UIGradient") then
		signGradient = gradient
	end
	if anchor and anchor:IsA("BasePart") then
		signAnchor = anchor
	end
	local promptPart = model:WaitForChild("PromptAnchor", 30)
	if promptPart and promptPart:IsA("BasePart") then
		promptAnchor = promptPart
	end
end)

-- A gentle drift of the sign's colours, one slow pass every 14 seconds: ten
-- steps a second while this camera is near enough to draw the sign, and a
-- look once a second otherwise.
task.spawn(function()
	local drift = 0
	local last = os.clock()
	while gui.Parent do
		local g, anchor, camera = signGradient, signAnchor, Workspace.CurrentCamera
		local near = g ~= nil and g.Parent ~= nil and anchor ~= nil and camera ~= nil
			and (camera.CFrame.Position - anchor.Position).Magnitude <= WheelData.Place.SignDistance
		local now = os.clock()
		if near and g then
			drift = (drift + (now - last) / 14) % 1
			g.Offset = Vector2.new(drift * 2 - 1, 0)
		end
		last = now
		task.wait(if near then 0.1 else 1)
	end
end)

--==============================================================================
-- THE REWARD INFO SHEET
--==============================================================================
local function setSheet(on: boolean)
	if sheetOpen == on then
		return
	end
	sheetOpen = on
	sheet.Visible = on
	-- The wheel steps away under the sheet: on a tall screen its "?" and X
	-- would show above it, and none of its controls may take the selection.
	stage.Visible = not on
	infoButton.button.Selectable = not on
	closeButton.button.Selectable = not on
	if not on then
		setExpanded(nil)
	end
	paint()
	if on then
		paintFooter()
		list.CanvasPosition = Vector2.zero
	end
	if PadInput.active() then
		GuiService.SelectedObject = if on then backButton.button elseif open then infoButton.button else nil
	end
	-- Opened from the card to buy, or from the question to spend: Back goes
	-- back THERE, so the odds are read and the choice is still in front of them.
	if not on and open then
		local back = shop.returnTo
		shop.returnTo = ""
		if back == "shop" and paidAllowed() then
			shop.show(true)
		elseif back == "confirm" and paidAllowed() and num(A.Bought) > 0 then
			shop.confirm(true)
		end
	end
end

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local rangeConn: RBXScriptConnection? = nil
local deathConns: { RBXScriptConnection } = {}
local clockToken = 0
local setOpen: (boolean) -> ()

local function bindClosers()
	-- Back closes the Reward info first, then the panel. Bound only while open.
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			if sheetOpen then
				setSheet(false)
			elseif shop.open then
				shop.show(false)
			elseif confirm.Visible then
				shop.confirm(false)
			else
				setOpen(false)
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
	rangeConn = RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			setOpen(false)
			return
		end
		local anchor = promptAnchor
		if anchor and anchor.Parent and (root.Position - anchor.Position).Magnitude > CLOSE_DISTANCE then
			setOpen(false)
		end
	end)
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

local function showConfirm(on: boolean)
	if on and shop.open then
		shop.show(false)
	end
	confirm.Visible = on
	hubButton.Visible = not on
	paint()
	if PadInput.active() then
		GuiService.SelectedObject = if on then confirmYes
			elseif hubButton.Selectable then hubButton
			else infoButton.button
	end
end
shop.confirm = showConfirm

-- The card to buy, over the hub. One card at a time: it shuts the question.
shop.show = function(on: boolean)
	if on and confirm.Visible then
		showConfirm(false)
	end
	shop.open = on
	shop.card.Visible = on
	hubButton.Visible = not on
	if on then
		RobuxPrice.refresh()
	end
	paint()
	if PadInput.active() then
		GuiService.SelectedObject = if on then shop.first()
			elseif shop.button.Selectable then shop.button
			else infoButton.button
	end
end

setOpen = function(want: boolean)
	if open == want then
		return
	end
	open = want
	SoundKit.play(if want then "PanelOpen" else "PanelClose")
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		bindClosers()
		sheet.Visible = false
		sheetOpen = false
		stage.Visible = true
		infoButton.button.Selectable = true
		closeButton.button.Selectable = true
		shop.open = false
		shop.card.Visible = false
		shop.returnTo = ""
		showConfirm(false)
		layout()
		scrim.Visible = true
		scrim.BackgroundTransparency = 1
		TweenService:Create(scrim, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = SCRIM_SEEN }):Play()
		pop.Scale = 0.92
		TweenService:Create(pop, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }):Play()
		refreshRainbows()
		-- The countdown, once a second while the panel is up.
		clockToken += 1
		local mine = clockToken
		task.spawn(function()
			while open and clockToken == mine do
				task.wait(1)
				if open and clockToken == mine then
					paint()
				end
			end
		end)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		unbindClosers()
		clockToken += 1
		setExpanded(nil)
		sheetOpen = false
		sheet.Visible = false
		shop.open = false
		shop.card.Visible = false
		shop.returnTo = ""
		scrim.Visible = false
		refreshRainbows()
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
	end
end

scrim.Activated:Connect(function()
	setOpen(false)
end)
closeButton.button.Activated:Connect(function()
	setOpen(false)
end)
sheetClose.button.Activated:Connect(function()
	setOpen(false)
end)
infoButton.button.Activated:Connect(function()
	setSheet(true)
end)
backButton.button.Activated:Connect(function()
	setSheet(false)
end)
GuiService.MenuOpened:Connect(function()
	setOpen(false)
end)
-- One centre panel at a time: the same OpenPanel mutex as every other panel.
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
	if who ~= player or prompt.Name ~= "WheelPrompt" then
		return
	end
	local folder = Workspace:FindFirstChild(WheelData.FolderName)
	if folder and prompt:IsDescendantOf(folder) then
		setOpen(true)
	end
end)

--==============================================================================
-- SPINNING
--==============================================================================
local channel: RemoteEvent? = nil
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/WheelUI] No GameEvent remote; the wheel cannot spin.")
	end
end)

-- The server's reasons, in words. Every one of them leaves the balances as they were.
local REFUSED: { [string]: { title: string, detail: string? } } = {
	NO_SPINS = { title = "NO SPINS", detail = "Complete the obby to earn spins." },
	NOT_READY = { title = "NOT READY YET", detail = "Your progress is still loading." },
	NOT_SAVED = { title = "CAN'T SPIN RIGHT NOW", detail = "Your progress isn't saving, so nothing can be won." },
	SAVE_FAILED = { title = "SPIN NOT SAVED", detail = "Nothing was used or won. Try again." },
	FAILED = { title = "SPIN INTERRUPTED", detail = "If a spin was used, its prize is saved and on its way." },
	PAID_UNAVAILABLE = { title = "PURCHASED SPINS UNAVAILABLE", detail = "They can't be used on this account." },
	PENDING_FULL = { title = "PRIZES WAITING", detail = "Make room in your bag, then press CLAIM." },
	NO_ROOM = { title = "BAG FULL", detail = "Make room in your bag, then press CLAIM." },
	DISABLED = { title = "THE WHEEL IS CLOSED" },
	-- Buying: every one of these opened no prompt and took nothing.
	BALANCE_FULL = { title = "SPINS FULL", detail = "Use some of your spins first." },
	PROMPT_BUSY = { title = "ONE MOMENT", detail = "A purchase is already opening." },
	PROMPT_FAILED = { title = "PURCHASE UNAVAILABLE", detail = "It could not open. Nothing was charged." },
	UNKNOWN_PRODUCT = { title = "PURCHASE UNAVAILABLE", detail = "Nothing was charged." },
}

local function refused(reason: string)
	local words = REFUSED[reason] or { title = "CAN'T SPIN", detail = nil }
	Notice.post({ kind = "blocked", title = words.title, detail = words.detail, key = "wheel:" .. reason })
	holdLine(words.detail or words.title, PAL.Cream, NOTE_SECONDS)
end

local function send(source: string)
	local remote = channel
	if not remote or spinning or waiting then
		return
	end
	waiting = true
	lineNote = nil
	paint()
	remote:FireServer(ACT.Spin, source)
	-- An answer always comes; were it lost, SPIN frees itself.
	task.delay(12, function()
		if waiting then
			waiting = false
			paint()
		end
	end)
end

hubButton.Activated:Connect(function()
	-- Grey at 0 spins: not a button at all, so not even a refusal.
	if spinning or waiting or usable() <= 0 then
		return
	end
	local earned, bought = num(A.Earned), num(A.Bought)
	if earned > 0 then
		send("earned")
	elseif bought > 0 and paidAllowed() then
		-- Never a silent switch to a purchased spin: say so and wait for a yes.
		showConfirm(true)
	elseif bought > 0 then
		refused("PAID_UNAVAILABLE")
	else
		refused("NO_SPINS")
	end
end)
confirmYes.Activated:Connect(function()
	showConfirm(false)
	send("bought")
end)
confirmNo.Activated:Connect(function()
	showConfirm(false)
end)

--==============================================================================
-- BUYING: a key to the server, and the odds in words
--
-- A choice sends its product's KEY and nothing else -- no id, no amount, no
-- price. Whether a purchase prompt opens is the server's decision, and the
-- prompt is Roblox's: nothing here knows whether the player bought. Spins that
-- were bought arrive as the balance the server publishes (WheelSpinsBought),
-- which is all this script ever draws.
--==============================================================================
do
	local getSpins: TextButton = shop.button
	local closeCard: TextButton = shop.close
	local cardOdds: TextButton = shop.odds
	local questionOdds: TextButton = shop.confirmOdds
	getSpins.Activated:Connect(function()
		if spinning or waiting or not paidAllowed() then
			return
		end
		shop.show(not shop.open)
	end)
	closeCard.Activated:Connect(function()
		shop.show(false)
	end)
	-- REWARDS & ODDS: Reward info, and Back returns to where it was opened.
	cardOdds.Activated:Connect(function()
		shop.show(false)
		shop.returnTo = "shop"
		setSheet(true)
	end)
	questionOdds.Activated:Connect(function()
		showConfirm(false)
		shop.returnTo = "confirm"
		setSheet(true)
	end)
	for _, choice in ipairs(shop.choices :: { ShopChoice }) do
		choice.button.Activated:Connect(function()
			local remote = channel
			if not remote or not paidAllowed() or not choice.onSale then
				return
			end
			remote:FireServer(ACT.Buy, choice.product.key)
		end)
	end
end

-- A purchase that landed, said out loud: the balance went up while the panel
-- was open. The balance is the server's; this only reads it.
shop.bought = num(A.Bought)
player:GetAttributeChangedSignal(A.Bought):Connect(function()
	local now = num(A.Bought)
	local gained = now - shop.bought
	shop.bought = now
	if gained > 0 and open and paidAllowed() then
		if shop.open then
			shop.show(false)
		end
		Notice.post({ kind = "success", title = if gained == 1 then "+1 SPIN" else string.format("+%d SPINS", gained),
			detail = "Added to your spins.", key = "wheel:bought" })
	end
end)
skipButton.Activated:Connect(function()
	skip = not skip
	paintFooter()
end)
claimButton.Activated:Connect(function()
	local remote = channel
	if remote then
		remote:FireServer(ACT.Claim)
	end
end)

-- What a prize is, in words, for the notice. A pod's species is never said:
-- that is its hatch's.
local function describe(prize: WheelData.Reward): string
	if prize.kind == "pod" then
		local size = SeedData.Tier(prize.tier).name
		if prize.pool == "rare" then
			return string.format("A Rare-species pod, %s size. Its species shows when it hatches.", size)
		end
		return string.format("Guaranteed %s size. Its species shows when it hatches.", size)
	elseif prize.kind == "boost" then
		return "Running now. A new boost replaces one already running."
	elseif prize.kind == "trail" then
		return "Yours for good, and on now. Wear or remove it from your Bag."
	elseif prize.kind == "speed" then
		return "Added to your Speed."
	end
	return "Added to your cash."
end

local function showResult(payload: { [string]: any })
	local rolled = WheelData.ById[tostring(payload.rolled)]
	local prize = WheelData.ById[tostring(payload.prize)]
	if not (rolled and prize) then
		return
	end
	local note = describe(prize)
	local line = string.format("You won: %s!", prize.short)
	if payload.swapped == true then
		note = string.format("You own the %s already, so it paid %s instead.", rolled.title, prize.title)
		line = string.format("Trail slice! You own it, so: %s", prize.short)
	end
	if payload.owed == true then
		note = "Your bag is full, so it's waiting here. Make room, then press CLAIM."
		line = string.format("You won: %s! It waits for bag space", prize.short)
	end
	holdLine(line, rarityText(prize.rarity), RESULT_SECONDS, prize.rainbow == true)
	-- The rarest four get the hatch's own rare sting instead of the notice chime.
	local rare = rolled.weight <= 250
	if rare then
		SoundKit.play("RevealAccentRare")
	end
	Notice.post({ kind = "success", title = "WHEEL: " .. string.upper(prize.title), detail = note,
		key = "wheel:won", quiet = rare })
end

-- Turn the panel's wheel and this player's copy of the world wheel onto the
-- rolled point: whole turns, then an ease-out, ticking as each divider passes.
local sectors = WheelData.displaySectors()
local function underPointer(angle: number): number
	local at = (-angle) % 360
	for i, s in ipairs(sectors) do
		if at >= s.start and at < s.finish then
			return i
		end
	end
	return #sectors
end

local function setBoth(angle: number)
	local d, wf = drawn, worldFace
	if d then
		d.setAngle(angle)
	end
	if wf then
		wf.setAngle(angle)
	end
end

local function animate(payload: { [string]: any })
	local rolled = WheelData.ById[tostring(payload.rolled)]
	if not rolled then
		return
	end
	local within = tonumber(payload.within) or 0.5
	-- The drawn sector's point, at the server's own `within`.
	local finish = -WheelData.displayLanding(rolled, within)
	local d = drawn
	local startAngle = if d then d.angle() else 0
	if skip or not open then
		setBoth(finish)
		paint()
		showResult(payload)
		return
	end
	spinning = true
	paint()
	local total = SPIN_TURNS * 360 + (finish - startAngle) % 360
	local started = os.clock()
	local lastTickAt = 0
	local lastIndex = underPointer(startAngle)
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		-- Skipping mid-spin jumps to the same end: the prize never changes.
		local t = if skip then 1 else math.min(1, (os.clock() - started) / SPIN_SECONDS)
		local eased = 1 - (1 - t) ^ 4
		local angle = startAngle + total * eased
		setBoth(angle)
		local index = underPointer(angle)
		if index ~= lastIndex then
			lastIndex = index
			local now = os.clock()
			if now - lastTickAt > 0.07 and t < 1 then
				lastTickAt = now
				SoundKit.play("CardHover")
			end
		end
		if t >= 1 then
			if conn then
				conn:Disconnect()
			end
			setBoth(finish)
			spinning = false
			paint()
			showResult(payload)
		end
	end)
end

task.spawn(function()
	while not channel do
		task.wait(0.5)
	end
	local remote = channel :: RemoteEvent
	remote.OnClientEvent:Connect(function(action: any, payload: any)
		if action ~= ACT.Result or type(payload) ~= "table" then
			return
		end
		-- The answer to a request to buy: a refusal is said; a yes means
		-- Roblox's own prompt is opening, and says nothing about a purchase.
		if payload.buy == true then
			if payload.ok ~= true then
				refused(tostring(payload.reason))
			end
			return
		end
		if payload.claim == true then
			if payload.ok == true then
				local n = tonumber(payload.landed) or 1
				Notice.post({ kind = "success", title = if n == 1 then "PRIZE CLAIMED" else "PRIZES CLAIMED",
					detail = "It's in your bag.", key = "wheel:claim" })
			else
				refused("NO_ROOM")
			end
			paint()
			return
		end
		waiting = false
		if payload.ok ~= true then
			local reason = tostring(payload.reason)
			if reason == "CONFIRM_BOUGHT" then
				showConfirm(true)
			elseif reason ~= "BUSY" then
				refused(reason)
			end
			paint()
			return
		end
		animate(payload)
	end)
end)

--==============================================================================
-- THE PROFILE: the Almanac's grown species, for the cards' silhouettes. Both
-- remotes IndexUI reads; a species is never un-grown, so the set only grows.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Almanac) ~= "table" then
		return
	end
	local changed = false
	for id, value in pairs(profile.Almanac) do
		if value == true and type(id) == "string" and not almanac[id] then
			almanac[id] = true
			changed = true
		end
	end
	local row = expanded
	if changed and row then
		tintCards(row)
	end
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	if not remotes then
		return
	end
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
end)

--==============================================================================
-- REPAINTING
--==============================================================================
for _, name in ipairs({ A.Earned, A.Bought, A.DayCount, A.DayEndsAt, A.Pending, A.PaidAllowed, A.TrailOwned,
	OA.RewardMain, OA.RewardChallenge }) do
	player:GetAttributeChangedSignal(name):Connect(function()
		if open then
			paint()
		end
	end)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if open then
		layout()
	end
end)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	if open then
		layout()
	end
end)
