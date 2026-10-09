--!strict
-- Steal a Seed :: InviteRewardUI (2026-10-06, the owner's Invite a Friend)
--
-- THE REWARD POPUP: a card for each form the server gives -- the moment the
-- invites paid off -- and never more than that.
--
--   NOT MODAL   no dimmer, never the whole screen, never the camera, never the
--               player's movement: the card stands in the upper middle, clear
--               of every HUD rect (HudLayout.occupied, MenuLayout.rewardPopup),
--               and the player can walk away from it. The plant is already in
--               the Bag; untouched, the card closes itself after AutoClose
--               seconds (the final form's FinalAutoClose).
--   THE CARD    the studded baseplate with a rim in the form's rarity colour
--               (the Secret's gold), NEW FORM UNLOCKED! (FINAL FORM!) on a
--               ribbon, the form turning and idling in a window over drawn rays
--               in its colour, its name, the rarity on a pill, its $/s in the
--               income gold, "Invite reward: N friends - Unsellable", PLACE IT
--               (equips it, as the Bag does) and LATER, whose ring empties over
--               the auto-close.
--   INTENSITY   by rarity, from GameConfig (Popup.Intensity): the rays'
--               brightness, sparkles round the form, a short glow at the
--               screen's edges, confetti, the burst's length. Values, no
--               branches.
--   SOUND       the owner's invite_unlock_<rarity> as it comes in
--               (InviteSounds: it wins over any other invite sound).
--   THE QUEUE   one card a form, lowest first, a Gap between; none while
--               another reward moment is up -- the hatch reveal, the offline
--               earnings, a centre panel (the wheel's prize is one) -- or the
--               INVITE panel: a card hidden under a panel would never reach the
--               player (RewardMoments.busy). A panel opening, or another moment
--               starting, takes a card down. At join: nothing for JoinSettle
--               seconds nor while offline earnings wait to be claimed (their
--               card comes first), then WHILE YOU WERE AWAY -- the friends
--               credited while the player was away, once -- then the cards,
--               none sooner than AwayLead seconds after it.
--   INPUT       mouse and touch on its two buttons; Enter = PLACE IT, Escape =
--               LATER; a controller's A = PLACE IT, B = LATER -- bound only while
--               a card is up. It never takes the GUI selection: with a selection
--               the stick would steer the menu instead of walking, and the
--               arrows would stop moving the player.
--
-- Every animation is decoration: a card is complete and right with none (an
-- Edit spec runs no tweens). It shows only what the server already did.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SecretIdle = require(Shared:WaitForChild("SecretIdle"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
local InviteRewards = require(Shared:WaitForChild("InviteRewards"))
local InviteSounds = require(Shared:WaitForChild("InviteSounds"))
local InviteNews = require(Shared:WaitForChild("InviteNews"))
local RewardMoments = require(Shared:WaitForChild("RewardMoments"))

local CONFIG = GameConfig.InviteRewards
if not CONFIG.Enabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local POP = CONFIG.Popup
local WORDS = CONFIG.Words
local PANEL = CONFIG.Panel
local ATTR = GameConfig.Attributes
local CARD = GameConfig.Card
-- The card's blocks for its shape (tall, or wide on a short screen): whichever
-- MenuLayout.rewardPopup answered when the card was last placed.
local B = MenuLayout.popupBlocks("tall")
local PLACE_ACTION = "SeedInviteRewardPlace"
local LATER_ACTION = "SeedInviteRewardLater"
-- Play captures only, in Studio: while the local player carries this attribute
-- a card's auto-close waits (its ring stops). Never in a live game.
local HOLD = if RunService:IsStudio() then "SeedTestHoldCard" else nil

local WHITE = Color3.fromRGB(255, 255, 255)
local Z = 4
-- The rays: this many bars through the middle (twice as many rays).
local RAY_BARS = 8
-- LATER's ring, in dots.
local RING_DOTS = 20
-- The edge glow's depth into the screen, and how long PLACE IT waits for the
-- given plant's Tool (GiveHatched's can land a moment late).
local EDGE_DEPTH = 44
local TOOL_PATIENCE = 4

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
for _, name in ipairs({ "SeedInviteReward", "SeedInviteRewardEdges" }) do
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end
ContextActionService:UnbindAction(PLACE_ACTION)
ContextActionService:UnbindAction(LATER_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedInviteReward"
gui.ResetOnSpawn = false
-- Over the belt and the menus' layers, under the rail layer's 40: it only ever
-- stands where the HUD does not.
gui.DisplayOrder = 35
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- The HUD's own units on a TV, so HudLayout's rects mean the same here.
UIKit.tenFoot(gui)

-- The whole screen, beside this gui's area: an empty gui with no insets at all
-- (WheelUI measures the same two). The edge glow reaches from this gui's area
-- out to it -- a notched phone's strips, the topbar's band -- where, sized to
-- this gui, it stopped in a hard line short of the screen's edges (a Play at
-- 705 x 338, 2026-10-06). A ScreenGui's own AbsolutePosition and AbsoluteSize
-- carry its insets (Edit, the same emulation: 705 x 338 at 0, 0 here; 799 x 359
-- at -47, 0 there); it holds nothing, so nothing on it is ever hit.
local wholeGui = Instance.new("ScreenGui")
wholeGui.Name = "SeedInviteRewardEdges"
wholeGui.ResetOnSpawn = false
wholeGui.IgnoreGuiInset = true
wholeGui.ScreenInsets = Enum.ScreenInsets.None
wholeGui.Parent = playerGui
gui.Destroying:Connect(function()
	wholeGui:Destroy()
end)

--==============================================================================
-- THE CARD (built once; each form repaints it)
--==============================================================================
local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Size = UDim2.fromOffset(B.size.X, B.size.Y)
card.BackgroundTransparency = 1
card.Active = false
card.Visible = false
card.ZIndex = 2
card.Parent = gui
local fit = Instance.new("UIScale")
fit.Parent = card

local function place(object: GuiObject, r: MenuLayout.Rect)
	object.Position = UDim2.fromOffset(r.x, r.y)
	object.Size = UDim2.fromOffset(r.w, r.h)
end

local function fitText(label: TextLabel, max: number, min: number)
	label.TextScaled = true
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = max
	c.MinTextSize = min
	c.Parent = label
end

local plate = MenuKit.baseplate(card, Z)
plate.Size = UDim2.fromScale(1, 1)
local rim = Instance.new("UIStroke")
rim.Name = "Rim"
rim.Thickness = 4
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.LineJoinMode = Enum.LineJoinMode.Round
rim.Parent = plate

-- Confetti falls behind the words, over the plate, inside the card.
local confettiLayer = MenuKit.frame(card, "Confetti", Z + 1)
confettiLayer.Size = UDim2.fromScale(1, 1)
confettiLayer.ClipsDescendants = true

local ribbon = MenuKit.frame(card, "Ribbon", Z + 2, WHITE, 0, 8)
place(ribbon, B.ribbon)
local ribbonEdge = MenuKit.keyline(ribbon, CONFIG.Ink, 2)
ribbonEdge.LineJoinMode = Enum.LineJoinMode.Round
local ribbonWords = UIKit.outlined(ribbon, "Words", 24, WHITE, 2.5)
ribbonWords.Size = UDim2.new(1, -12, 1, -4)
ribbonWords.Position = UDim2.fromOffset(6, 2)
ribbonWords.ZIndex = Z + 3
fitText(ribbonWords, 26, 10)

-- The stage: the rays turning behind the form's window.
local stage = MenuKit.frame(card, "Stage", Z + 2)
place(stage, B.stage)
local rays = MenuKit.frame(stage, "Rays", Z + 2)
rays.AnchorPoint = Vector2.new(0.5, 0.5)
rays.Position = UDim2.fromScale(0.5, 0.5)
local rayScale = Instance.new("UIScale")
rayScale.Parent = rays
local glow = MenuKit.frame(rays, "Glow", Z + 2, WHITE, 0.55)
local glowRound = UIKit.corner(glow, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.fromScale(0.6, 0.6)
local rayBars: { Frame } = {}
for i = 1, RAY_BARS do
	local bar = MenuKit.frame(rays, "Ray", Z + 2, WHITE, 0, 6)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.Size = UDim2.new(0, 14, 1, 0)
	bar.Rotation = (i - 1) * 180 / RAY_BARS
	-- Bright in the middle, gone at both ends: two rays from one bar.
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.55),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = bar
	table.insert(rayBars, bar)
end
-- The flash ring of the entrance's burst.
local flash = MenuKit.frame(stage, "Flash", Z + 3)
flash.AnchorPoint = Vector2.new(0.5, 0.5)
flash.Position = UDim2.fromScale(0.5, 0.5)
local flashRound = UIKit.corner(flash, 0)
local flashLine = UIKit.stroke(flash, WHITE, 4, 1)
local flashScale = Instance.new("UIScale")
flashScale.Parent = flash

local view = Instance.new("ViewportFrame")
view.Name = "Form"
view.BackgroundTransparency = 1
view.Ambient = CARD.Ambient
view.LightColor = CARD.LightColour
view.LightDirection = CARD.LightDirection
view.ZIndex = Z + 4
view.Parent = card
place(view, B.view)
local sparkleLayer = MenuKit.frame(card, "Sparkles", Z + 5)
place(sparkleLayer, B.stage)

local nameLabel = UIKit.outlined(card, "FormName", 28, WHITE, 2.5)
place(nameLabel, B.name)
nameLabel.ZIndex = Z + 3
fitText(nameLabel, 30, 12)

local pill = MenuKit.frame(card, "Rarity", Z + 3, WHITE, 0, math.floor(B.pill.h / 2))
place(pill, B.pill)
MenuKit.keyline(pill, CONFIG.Ink, 1.5)
local pillWord = MenuKit.text(pill, "Word", 14, WHITE, Z + 4)
pillWord.Size = UDim2.new(1, -10, 1, 0)
pillWord.Position = UDim2.fromOffset(5, 0)
MenuKit.keepInk(pillWord)
fitText(pillWord, 15, 9)

local income = MenuKit.text(card, "Income", 18, CONFIG.Income, Z + 3)
place(income, B.income)
income.TextXAlignment = Enum.TextXAlignment.Left
MenuKit.keepInk(income)
fitText(income, 20, 10)

local line = MenuKit.body(card, "Line", 13, CONFIG.Cream, Z + 3)
place(line, B.line)
MenuKit.keepInk(line)
fitText(line, 14, 9)

local placeIt = MenuKit.button(card, "PlaceIt", Z + 3, POP.Place, 20, { studs = true })
place(placeIt.hit, B.place)
placeIt.style("go")

-- LATER: grey, its words moved over for the ring that empties.
local later = MenuKit.button(card, "Later", Z + 3, POP.Later, 16)
place(later.hit, B.later)
do
	local face = POP.LaterFace
	local black = Color3.new(0, 0, 0)
	later.tint.Color = MenuKit.faceColours(face, face:Lerp(black, 0.18), face:Lerp(black, 0.55))
	later.edge.Color = face:Lerp(black, 0.55)
	later.label.TextColor3 = WHITE
	later.label.Position = UDim2.fromOffset(B.ring.w + 10, 1)
	later.label.Size = UDim2.new(1, -(B.ring.w + 14), 1 - GameConfig.BagLook.FootShare, 0)
end
local ring = MenuKit.frame(later.plate, "Ring", Z + 6)
ring.AnchorPoint = Vector2.new(0, 0.5)
ring.Position = UDim2.new(0, B.ring.x - B.later.x, 0.5, -2)
ring.Size = UDim2.fromOffset(B.ring.w, B.ring.h)
local ringDots: { Frame } = {}
for k = 1, RING_DOTS do
	local a = (k - 1) / RING_DOTS * 2 * math.pi - math.pi / 2
	local radius = B.ring.w / 2 - 2
	local dot = MenuKit.frame(ring, "Dot", Z + 6, WHITE, 0, 1)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromOffset(B.ring.w / 2 + math.cos(a) * radius, B.ring.h / 2 + math.sin(a) * radius)
	dot.Size = UDim2.fromOffset(4, 2)
	dot.Rotation = math.deg(a) + 90
	table.insert(ringDots, dot)
end

-- The short glow along the screen's edges (Mythic and the Secret): four
-- strips, nothing in the middle, never pressable; reachEdges stretches it past
-- this gui's insets to the screen's own edges.
local edges = Instance.new("Frame")
edges.Name = "EdgeGlow"
edges.Size = UDim2.fromScale(1, 1)
edges.BackgroundTransparency = 1
edges.Active = false
edges.Visible = false
edges.ZIndex = 1
edges.Parent = gui
local edgeStrips: { Frame } = {}
for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
	local strip = Instance.new("Frame")
	strip.Name = side
	strip.BorderSizePixel = 0
	strip.Active = false
	strip.BackgroundColor3 = WHITE
	strip.BackgroundTransparency = 1
	strip.ZIndex = 1
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new(0, 1)
	if side == "Top" then
		strip.Size = UDim2.new(1, 0, 0, EDGE_DEPTH)
		fade.Rotation = 90
	elseif side == "Bottom" then
		strip.AnchorPoint = Vector2.new(0, 1)
		strip.Position = UDim2.fromScale(0, 1)
		strip.Size = UDim2.new(1, 0, 0, EDGE_DEPTH)
		fade.Rotation = -90
	elseif side == "Left" then
		strip.Size = UDim2.new(0, EDGE_DEPTH, 1, 0)
		fade.Rotation = 0
	else
		strip.AnchorPoint = Vector2.new(1, 0)
		strip.Position = UDim2.fromScale(1, 0)
		strip.Size = UDim2.new(0, EDGE_DEPTH, 1, 0)
		fade.Rotation = 180
	end
	fade.Parent = strip
	strip.Parent = edges
	table.insert(edgeStrips, strip)
end

--==============================================================================
-- THE CARD'S SHAPE: its blocks for tall or wide (MenuLayout.popupBlocks)
--==============================================================================
local shapeNow: string? = nil
local function shapeCard(shape: MenuLayout.PopupShape)
	if shapeNow == shape then
		return
	end
	shapeNow = shape
	B = MenuLayout.popupBlocks(shape)
	card.Size = UDim2.fromOffset(B.size.X, B.size.Y)
	place(ribbon, B.ribbon)
	place(stage, B.stage)
	local side = math.max(B.stage.w, B.stage.h)
	rays.Size = UDim2.fromOffset(side, side)
	glowRound.CornerRadius = UDim.new(0, math.floor(side * 0.3))
	flash.Size = UDim2.fromOffset(side, side)
	flashRound.CornerRadius = UDim.new(0, math.floor(side / 2))
	place(view, B.view)
	place(sparkleLayer, B.stage)
	place(nameLabel, B.name)
	place(pill, B.pill)
	place(income, B.income)
	place(line, B.line)
	place(placeIt.hit, B.place)
	place(later.hit, B.later)
	local align = if B.centred then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
	nameLabel.TextXAlignment = align
	line.TextXAlignment = align
end

--==============================================================================
-- WHERE THE CARD STANDS: the upper middle, clear of the HUD
--==============================================================================
local function where(): (MenuLayout.Rect, number, MenuLayout.PopupShape)
	if gui.AbsoluteSize.X <= 0 then
		return MenuLayout.rect(0, 0, 0, 0), 0, "tall"
	end
	local L = HudLayout.solve(HudLayout.measure(gui))
	local r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupied(L), L.sidebar)
	if r.w <= 0 then
		-- No place clear of the notices' line too (a 640 x 360 phone under the
		-- panel's row, 2026-10-09): the line gives way, the notices' only while
		-- one passes (HudLayout.occupiedButToast).
		r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupiedButToast(L), L.sidebar)
	end
	return r, scale, shape
end

local fitScale = 1
local function placeCard(): boolean
	local r, scale, shape = where()
	if r.w <= 0 or scale <= 0 then
		return false
	end
	shapeCard(shape)
	fitScale = scale
	card.Position = UDim2.fromOffset(r.x + r.w / 2, r.y + r.h / 2)
	fit.Scale = scale
	return true
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if card.Visible then
		placeCard()
	end
end)

--==============================================================================
-- ONE CARD: painted, shown, closed
--==============================================================================
type Sparkle = { frame: Frame, scale: UIScale, phase: number }
type Up = {
	tier: number,
	form: string,
	closedBy: string?,
	started: number,
	autoClose: number,
	model: Model?,
	rig: SecretIdle.Rig?,
	camera: Camera?,
	distance: number,
	focus: Vector3,
	sparkles: { Sparkle },
}
local current: Up? = nil

local function clearSparkles()
	for _, child in ipairs(sparkleLayer:GetChildren()) do
		child:Destroy()
	end
end

-- Sparkles round the form: small four-point stars twinkling (Legendary and up).
local function sparkle(up: Up, count: number, size: number, colour: Color3)
	clearSparkles()
	for k = 1, count do
		local holder = MenuKit.frame(sparkleLayer, "Sparkle", Z + 5)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		local a = (k / count) * math.pi * 2 + (k % 2) * 0.4
		local rx, ry = B.stage.w * (0.32 + (k % 3) * 0.05), B.stage.h * (0.36 + (k % 2) * 0.06)
		holder.Position = UDim2.fromOffset(B.stage.w / 2 + math.cos(a) * rx, B.stage.h / 2 + math.sin(a) * ry)
		holder.Size = UDim2.fromOffset(size, size)
		for _, turnBy in ipairs({ 0, 90 }) do
			local arm = MenuKit.frame(holder, "Arm", Z + 5, if k % 3 == 0 then CONFIG.Gold else colour, 0, 2)
			arm.AnchorPoint = Vector2.new(0.5, 0.5)
			arm.Position = UDim2.fromScale(0.5, 0.5)
			arm.Size = UDim2.new(1, 0, 0, math.max(2, math.floor(size / 4)))
			arm.Rotation = 45 + turnBy
		end
		local scale = Instance.new("UIScale")
		scale.Parent = holder
		table.insert(up.sparkles, { frame = holder, scale = scale, phase = k * 1.7 })
	end
end

local CONFETTI = { CONFIG.Gold, Color3.fromRGB(255, 120, 150), Color3.fromRGB(120, 210, 255) }

local function confetti(count: number)
	for k = 1, count do
		local bit = MenuKit.frame(confettiLayer, "Bit", Z + 1, CONFETTI[k % #CONFETTI + 1], 0, 1)
		local x = math.random(10, math.floor(B.size.X) - 10)
		bit.Position = UDim2.fromOffset(x, math.random(-20, 10))
		bit.Size = UDim2.fromOffset(math.random(5, 8), math.random(8, 12))
		bit.Rotation = math.random(0, 180)
		local seconds = 1.2 + math.random() * 0.8
		TweenService:Create(bit, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(x + math.random(-40, 40), B.size.Y + 10),
			Rotation = bit.Rotation + math.random(-260, 260),
			BackgroundTransparency = 0.4,
		}):Play()
		task.delay(seconds, function()
			bit:Destroy()
		end)
	end
end

-- The glow's frame out to every edge of the screen, past this gui's insets, in
-- the gui's own units (pixels / its TV scale).
local function reachEdges()
	local k = UIKit.scaleOf(gui)
	local wp, ws = wholeGui.AbsolutePosition, wholeGui.AbsoluteSize
	local sp, ss = gui.AbsolutePosition, gui.AbsoluteSize
	if k <= 0 or ws.X <= 0 or ss.X <= 0 then
		return
	end
	local left = math.max(0, (sp.X - wp.X) / k)
	local top = math.max(0, (sp.Y - wp.Y) / k)
	local right = math.max(0, (wp.X + ws.X - sp.X - ss.X) / k)
	local bottom = math.max(0, (wp.Y + ws.Y - sp.Y - ss.Y) / k)
	edges.Position = UDim2.fromOffset(-left, -top)
	edges.Size = UDim2.new(1, left + right, 1, top + bottom)
end

local function edgeGlow(colour: Color3, seconds: number)
	reachEdges()
	edges.Visible = true
	for _, strip in ipairs(edgeStrips) do
		strip.BackgroundColor3 = colour
		strip.BackgroundTransparency = 1
		TweenService:Create(strip, TweenInfo.new(seconds * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.35 }):Play()
	end
	task.delay(seconds * 0.4, function()
		for _, strip in ipairs(edgeStrips) do
			TweenService:Create(strip, TweenInfo.new(seconds * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }):Play()
		end
		task.delay(seconds * 0.6, function()
			edges.Visible = false
		end)
	end)
end

-- Everything a card says, with no motion: the card is right from here.
local function paint(c: InviteRewards.PopupCard)
	rim.Color = c.rim
	ribbon.BackgroundColor3 = c.rim
	ribbonWords.Text = c.ribbon
	for _, bar in ipairs(rayBars) do
		bar.BackgroundColor3 = c.colour
		bar.BackgroundTransparency = 1 - c.intensity.rays
	end
	glow.BackgroundColor3 = c.colour
	flashLine.Color = c.rim
	flashLine.Transparency = 1
	nameLabel.Text = string.upper(c.name)
	pill.BackgroundColor3 = c.colour
	pillWord.Text = string.upper(c.rarity)
	income.Text = c.incomeText
	line.Text = c.line
	for _, dot in ipairs(ringDots) do
		dot.Visible = true
	end
	rays.Rotation = 0
	rayScale.Scale = 1
	flashScale.Scale = 1
end

local function buildForm(up: Up, form: string)
	for _, child in ipairs(view:GetChildren()) do
		child:Destroy()
	end
	view.CurrentCamera = nil
	local species = SeedData.Get(form) :: any
	if not species then
		return
	end
	local ok, model = pcall(CreatureModel.Build, species, SeedData.InviteTier, CreatureModel.STAGE_GROWN,
		CFrame.new(), view)
	if not ok or not model then
		return
	end
	up.model = model
	local okRig, rig = pcall(SecretIdle.Rig, model)
	up.rig = if okRig then rig else nil
	local camera, distance, focus = UIKit.framePlant(view, model, species.Form, PANEL.CardFill)
	up.camera, up.distance, up.focus = camera, distance, focus
end

-- PLACE IT: the given plant in the hands, the way the Bag holds one -- never
-- over a pod carried in both arms, never one whose roll is still sealed.
local function holdForm(form: string)
	local deadline = os.clock() + TOOL_PATIENCE
	local tool: Tool? = nil
	while os.clock() < deadline do
		for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") } :: { Instance? }) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") and child:GetAttribute("SpeciesId") == form then
						tool = child
					end
				end
			end
		end
		if tool then
			break
		end
		task.wait(0.2)
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not tool or not humanoid or tool.Parent == character then
		return
	end
	if player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		require(Shared:WaitForChild("ActionRefusal")).raise("CARRYING_POD")
		return
	end
	if HatchRoll.sealed(tool) then
		return
	end
	SoundKit.play("CardClick")
	humanoid:EquipTool(tool)
end

local function closeWith(why: string)
	local up = current
	if up and not up.closedBy then
		up.closedBy = why
	end
end

MenuKit.tap(placeIt.hit, nil, function()
	closeWith("place")
end)
MenuKit.tap(later.hit, nil, function()
	closeWith("later")
end)
-- LATER's own press for Play tests, as OfflineUI's ClaimPressed is.
local laterPressed = Instance.new("BindableEvent")
laterPressed.Name = "LaterPressed"
laterPressed.Parent = gui
laterPressed.Event:Connect(function()
	closeWith("later")
end)
-- A centre panel opening takes the card down (it would stand under it).
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if player:GetAttribute(ATTR.OpenPanel) ~= nil then
		closeWith("panel")
	end
end)

local function bindKeys()
	ContextActionService:BindActionAtPriority(PLACE_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			closeWith("place")
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonA)
	ContextActionService:BindActionAtPriority(LATER_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			closeWith("later")
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
end

local function unbindKeys()
	ContextActionService:UnbindAction(PLACE_ACTION)
	ContextActionService:UnbindAction(LATER_ACTION)
end

-- The entrance: 0.6 -> 1.08 -> 1.0 of its fitted size, the rays flaring in,
-- and the rarity's extras. Decoration only.
local function enter(up: Up, c: InviteRewards.PopupCard)
	local look = c.intensity
	fit.Scale = fitScale * 0.6
	local first = POP.InSeconds * 0.6
	TweenService:Create(fit, TweenInfo.new(first, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = fitScale * 1.08 }):Play()
	task.delay(first, function()
		if current == up and not up.closedBy then
			TweenService:Create(fit, TweenInfo.new(POP.InSeconds - first, Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut), { Scale = fitScale }):Play()
		end
	end)
	for _, bar in ipairs(rayBars) do
		bar.BackgroundTransparency = 1
		TweenService:Create(bar, TweenInfo.new(POP.InSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 - look.rays }):Play()
	end
	rayScale.Scale = 0.6
	TweenService:Create(rayScale, TweenInfo.new(look.burst * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1.25 }):Play()
	task.delay(look.burst * 0.4, function()
		TweenService:Create(rayScale, TweenInfo.new(look.burst * 0.6, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	flashScale.Scale = 0.4
	flashLine.Transparency = 0
	TweenService:Create(flashScale, TweenInfo.new(look.burst, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1.4 }):Play()
	TweenService:Create(flashLine, TweenInfo.new(look.burst, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1 }):Play()
	if look.sparkles > 0 then
		sparkle(up, look.sparkles, look.sparkleSize, c.colour)
	end
	if look.edge then
		edgeGlow(c.colour, look.burst)
	end
	if look.confetti > 0 then
		confetti(look.confetti)
	end
end

-- One card, start to finish. Yields until it is gone.
-- The plant the server says each tier gave (the "granted" payload's form): not
-- the tier's own when the wheel gave that one first (InviteRewards, THE TRACK
-- WITH THE WHEEL, 2026-10-08).
local givenForm: { [number]: string } = {}

local function show(tier: number)
	local c = InviteRewards.popup(tier, givenForm[tier])
	paint(c)
	if not placeCard() then
		-- No clear spot on this screen at all: the notice says it instead.
		Notice.post({ kind = "success", title = string.format(WORDS.Earned, string.upper(c.name)),
			detail = string.format(WORDS.EarnedDetail, c.name, c.rarity), quiet = true })
		InviteSounds.play("unlock", c.rarity)
		return
	end
	local up: Up = {
		tier = tier,
		form = c.form,
		closedBy = nil,
		started = os.clock(),
		autoClose = c.autoClose,
		model = nil,
		rig = nil,
		camera = nil,
		distance = 0,
		focus = Vector3.zero,
		sparkles = {},
	}
	current = up
	buildForm(up, c.form)
	local still = StatusText.reducedMotion()
	card.Visible = true
	InviteSounds.play("unlock", c.rarity)
	if not still then
		enter(up, c)
	end
	bindKeys()
	local spin = 0
	local moving = RunService.RenderStepped:Connect(function(dt: number)
		if HOLD and player:GetAttribute(HOLD) == true then
			up.started += dt
		end
		local left = math.clamp(1 - (os.clock() - up.started) / up.autoClose, 0, 1)
		-- LATER's ring empties with the time left (information: it runs under
		-- reduced motion too).
		local lit = math.ceil(left * RING_DOTS)
		for k, dot in ipairs(ringDots) do
			dot.Visible = k <= lit
		end
		if left <= 0 then
			closeWith("auto")
		elseif RewardMoments.busy(player, ATTR.OpenPanel) then
			closeWith("moment")
		end
		if still then
			return
		end
		spin += dt
		rays.Rotation = (spin * POP.RaySpin) % 360
		local camera = up.camera
		if camera and camera.Parent then
			local out = CFrame.Angles(0, math.rad(CONFIG.TurnDegrees) * spin, 0):VectorToWorldSpace(
				CARD.CameraOffset.Unit)
			camera.CFrame = CFrame.lookAt(up.focus + out * up.distance, up.focus)
		end
		local rig = up.rig
		if rig then
			SecretIdle.Step(rig, os.clock())
		end
		for _, s in ipairs(up.sparkles) do
			s.scale.Scale = math.max(0, math.sin(spin * 3 + s.phase))
		end
	end)
	while not up.closedBy do
		task.wait()
	end
	moving:Disconnect()
	unbindKeys()
	-- OUT: shrink away.
	if not StatusText.reducedMotion() then
		TweenService:Create(fit, TweenInfo.new(POP.OutSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = fitScale * 0.05 }):Play()
		task.wait(POP.OutSeconds)
	end
	card.Visible = false
	fit.Scale = fitScale
	clearSparkles()
	for _, child in ipairs(view:GetChildren()) do
		child:Destroy()
	end
	current = nil
	if up.closedBy == "place" then
		holdForm(up.form)
	end
end

--==============================================================================
-- THE QUEUE: one card a form, lowest first, never over another moment
--==============================================================================
local queue: { number } = {}
-- WHILE YOU WERE AWAY's friends, to be told before the cards.
local away = 0
-- No card before this clock: AwayLead after WHILE YOU WERE AWAY, so it is read
-- first even when the form comes a moment after it, not in the same batch (a
-- Play on a phone, 2026-10-06, had the two land together).
local cardsAfter = 0
local pumping = false
local startedAt = os.clock()
local OFFLINE_CASH = GameConfig.OfflineEarnings.Attributes.Cash

-- Not now: just after joining (the offline earnings card may be on its way),
-- while offline earnings wait to be claimed (that card comes first), or while
-- another reward moment or a centre panel is up.
local function busy(): boolean
	if os.clock() - startedAt < POP.JoinSettle then
		return true
	end
	local due = player:GetAttribute(OFFLINE_CASH)
	if type(due) == "number" and due > 0 then
		return true
	end
	return RewardMoments.busy(player, ATTR.OpenPanel)
end

-- WHILE YOU WERE AWAY, once: "<n> friends joined from your invites".
local function tellAway()
	local words = InviteRewards.notice({ kind = "away", count = away })
	away = 0
	if not words then
		return
	end
	local waited = 0
	while not Notice.ready() and waited < 15 do
		waited += task.wait(0.25)
	end
	Notice.post({ kind = words.kind :: any, title = words.title, detail = words.detail, key = words.key })
end

local function pump()
	if pumping then
		return
	end
	pumping = true
	task.spawn(function()
		while #queue > 0 or away > 0 do
			if busy() then
				task.wait(POP.Wait)
			elseif away > 0 then
				tellAway()
				cardsAfter = os.clock() + POP.AwayLead
			elseif os.clock() < cardsAfter then
				task.wait(POP.Wait)
			else
				local tier = InviteRewards.nextCard(queue, busy())
				if tier then
					show(tier)
					if #queue > 0 then
						task.wait(POP.Gap)
					end
				end
			end
		end
		pumping = false
	end)
end

InviteNews.subscribe(function(payload: InviteNews.Payload)
	if payload.kind == "granted" and type(payload.form) == "string" then
		givenForm[math.floor(tonumber(payload.tier) or 0)] = payload.form
	end
	if payload.kind == "granted" and InviteRewards.enqueue(queue, payload.tier) then
		pump()
	elseif payload.kind == "away" then
		away += math.max(0, math.floor(tonumber(payload.count) or 0))
		pump()
	end
end)

gui.Destroying:Connect(function()
	unbindKeys()
end)
