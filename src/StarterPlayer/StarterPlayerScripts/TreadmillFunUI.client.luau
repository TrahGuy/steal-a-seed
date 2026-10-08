--!strict
--==============================================================================
-- Steal a Seed :: TreadmillFunUI
-- TREADMILL FUN (the owner's brief, 2026-10-08), the player's own screen:
--
--   A1  "+1 WALK SPEED · NOW 19" over the character each time the WalkSpeed
--       the SCORE walks at passes a whole number -- several at once are one
--       pop -- over the owner's gold burst.
--   A2  the slim bar over the front of their OWN belt, "NEXT: 5K SPEED · CASH",
--       filling from the last milestone to the next, "BELT TICKET 0/1 TODAY"
--       beside it, and the badge with the number when a milestone is passed.
--   B   the belt's items, where the server says they are, and their catch.
--
-- DRAWS ONLY. Every number is the server's: the profile packet (Speed, the
-- milestone mark, the belt ticket window) and the item records under
-- Workspace.BeltItems. Nothing here is sent anywhere; a catch is decided by
-- TreadmillFunService from the character's replicated position.
--
-- NEVER OVER A BUTTON OR A NOTICE: the pop and the bar are projected into a
-- gui at DisplayOrder 11, under the notices (13) and the HUD (20) -- the same
-- trick as the guide's world hand, which also keeps them in a capture -- and
-- never UNDER one either: each stands clear of HudLayout's own rects
-- (SpeedMilestones.clearOf), the pop clear of the bar too.
--
-- THE SPEED SHOE: the game's one Speed icon (GameConfig.SourceIcons.speed, the
-- owner's transparent re-upload) beside the pop's words, riding the bar's fill
-- and in the badge's centre with the number -- its small version wherever it
-- draws at 40 px or less (SizedIcon).
--==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SpeedMilestones = require(Shared:WaitForChild("SpeedMilestones"))
local BeltCatch = require(Shared:WaitForChild("BeltCatch"))
local SizedIcon = require(Shared:WaitForChild("SizedIcon"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ATTR = GameConfig.Attributes

local GOLD = Color3.fromRGB(255, 216, 96)
local GOLD_DEEP = Color3.fromRGB(240, 156, 40)
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(24, 20, 14)

-- A re-run (a hot reload in Studio) starts clean.
for _, name in ipairs({ "SeedTreadmillFun", "SeedTreadmillFunMeasure" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
local localFolderName = "SeedBeltItemsLocal"

local gui = Instance.new("ScreenGui")
gui.Name = "SeedTreadmillFun"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- The whole screen, no insets: a projected point is this gui's own pixel.
gui.ScreenInsets = Enum.ScreenInsets.None
gui.DisplayOrder = 11
gui.Parent = playerGui

-- An empty gui set up as the HUD's own are (the inset kept, CoreUI-safe,
-- drawn bigger on a TV): HudLayout measures the screen through it, and its
-- AbsolutePosition is where the HUD's rects start.
local measureGui = Instance.new("ScreenGui")
measureGui.Name = "SeedTreadmillFunMeasure"
measureGui.ResetOnSpawn = false
measureGui.IgnoreGuiInset = false
measureGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
UIKit.tenFoot(measureGui)
measureGui.Parent = playerGui
gui.Destroying:Connect(function()
	measureGui:Destroy()
end)

local function camera(): Camera?
	return Workspace.CurrentCamera
end

-- How big the screen is, as one factor for every pixel size below.
local function scale(): number
	local cam = camera()
	local vp = if cam then cam.ViewportSize else Vector2.new(1100, 720)
	return math.clamp(math.min(vp.X / 1100, vp.Y / 720), 0.6, 1.25)
end

-- A world point to this gui's pixels (it ignores the inset, as the viewport
-- does), or nil behind the camera.
local function project(world: Vector3): (Vector2?, boolean)
	local cam = camera()
	if not cam then
		return nil, false
	end
	local v, onScreen = cam:WorldToViewportPoint(world)
	if v.Z <= 0 then
		return nil, false
	end
	return Vector2.new(v.X, v.Y), onScreen
end

--==============================================================================
-- A1. THE POP
--==============================================================================
local pop = Instance.new("Frame")
pop.Name = "WalkPop"
pop.AnchorPoint = Vector2.new(0.5, 1)
pop.BackgroundTransparency = 1
pop.Size = UDim2.fromOffset(420, 150)
pop.Visible = false
pop.ZIndex = 1
pop.Parent = gui
local popScale = Instance.new("UIScale")
popScale.Parent = pop

local burst = Instance.new("ImageLabel")
burst.Name = "Burst"
burst.AnchorPoint = Vector2.new(0.5, 0.5)
burst.Position = UDim2.fromScale(0.5, 0.55)
burst.Size = UDim2.fromOffset(170, 170)
burst.BackgroundTransparency = 1
burst.ScaleType = Enum.ScaleType.Fit
burst.Image = SpeedMilestones.Art.Burst
burst.ZIndex = 1
burst.Parent = pop

-- The shoe and the words: one row, centred over the burst, as wide as its words.
local SHOE_PX = SpeedMilestones.ShoePx
local popRow = Instance.new("Frame")
popRow.Name = "Row"
popRow.AnchorPoint = Vector2.new(0.5, 0.5)
popRow.Position = UDim2.fromScale(0.5, 0.55)
popRow.Size = UDim2.fromOffset(0, SHOE_PX.Pop)
popRow.AutomaticSize = Enum.AutomaticSize.X
popRow.BackgroundTransparency = 1
popRow.ZIndex = 2
popRow.Parent = pop
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = popRow
end

local popShoe = Instance.new("ImageLabel")
popShoe.Name = "Shoe"
popShoe.LayoutOrder = 1
popShoe.Size = UDim2.fromOffset(SHOE_PX.Pop, SHOE_PX.Pop)
popShoe.BackgroundTransparency = 1
popShoe.ScaleType = Enum.ScaleType.Fit
popShoe.Image = SpeedMilestones.Art.Shoe
popShoe.ZIndex = 3
popShoe.Parent = popRow

local popWords = UIKit.outlined(popRow, "Words", 30, WHITE, 3)
popWords.LayoutOrder = 2
popWords.Size = UDim2.fromOffset(0, 40)
popWords.AutomaticSize = Enum.AutomaticSize.X
popWords.TextXAlignment = Enum.TextXAlignment.Center
popWords.ZIndex = 3
do
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(GOLD, GOLD_DEEP)
	gradient.Rotation = 90
	gradient.Parent = popWords
end

local POP_SECONDS = 1.9
local popUntil = 0
local popBorn = 0
local popGained = 0

local function showPop(gained: number, nowWalk: number)
	local t = os.clock()
	if pop.Visible and t < popUntil then
		-- Several in a row are one pop: the count adds up, the hold restarts.
		popGained += gained
	else
		popGained = gained
		popBorn = t
	end
	popUntil = t + POP_SECONDS
	popWords.Text = SpeedMilestones.popWords(popGained, nowWalk)
	-- At the size it settles to on this screen (not the pop-in's swell).
	popShoe.Image = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Pop * scale())
	pop.Visible = true
	SoundKit.play(SpeedMilestones.Sounds.Pop)
end

--==============================================================================
-- A2. THE BAR
--==============================================================================
local bar = Instance.new("Frame")
bar.Name = "MilestoneBar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.BackgroundTransparency = 1
bar.Size = UDim2.fromOffset(330, 74)
bar.Visible = false
-- Over the pop's burst where the two meet.
bar.ZIndex = 2
bar.Parent = gui
local barScale = Instance.new("UIScale")
barScale.Parent = bar

local nextWords = UIKit.outlined(bar, "Next", 18, WHITE, 2)
nextWords.Size = UDim2.new(1, 0, 0, 22)
nextWords.Position = UDim2.fromOffset(0, 0)
nextWords.TextXAlignment = Enum.TextXAlignment.Center

local track = Instance.new("Frame")
track.Name = "Track"
track.Size = UDim2.new(1, 0, 0, 16)
track.Position = UDim2.fromOffset(0, 26)
track.BackgroundColor3 = INK
track.BackgroundTransparency = 0.35
track.BorderSizePixel = 0
track.Parent = bar
UIKit.corner(track, 8)
do
	local edge = Instance.new("UIStroke")
	edge.Color = GOLD
	edge.Thickness = 2
	edge.Transparency = 0.2
	edge.Parent = track
end
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = GOLD
fill.BorderSizePixel = 0
fill.Parent = track
UIKit.corner(fill, 8)
do
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(GOLD, GOLD_DEEP)
	gradient.Rotation = 90
	gradient.Parent = fill
end

-- The Speed shoe rides the fill's leading edge toward the next milestone.
local barShoe = Instance.new("ImageLabel")
barShoe.Name = "Shoe"
barShoe.AnchorPoint = Vector2.new(0.5, 0.5)
barShoe.Position = UDim2.fromScale(0, 0.5)
barShoe.Size = UDim2.fromOffset(SHOE_PX.Bar, SHOE_PX.Bar)
barShoe.BackgroundTransparency = 1
barShoe.ScaleType = Enum.ScaleType.Fit
barShoe.Image = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Bar)
barShoe.ZIndex = 3
barShoe.Parent = track

-- The belt ticket's cap, beside the bar: the game's own ticket picture.
local capRow = Instance.new("Frame")
capRow.Name = "CapRow"
capRow.BackgroundTransparency = 1
capRow.Size = UDim2.new(1, 0, 0, 22)
capRow.Position = UDim2.fromOffset(0, 48)
capRow.Parent = bar
local capIcon = Instance.new("ImageLabel")
capIcon.Name = "Ticket"
capIcon.BackgroundTransparency = 1
capIcon.ScaleType = Enum.ScaleType.Fit
capIcon.Image = GameConfig.SourceIcons.tickets
capIcon.Size = UDim2.fromOffset(22, 22)
capIcon.AnchorPoint = Vector2.new(1, 0)
capIcon.Position = UDim2.new(0.5, -76, 0, 0)
capIcon.Parent = capRow
local capWords = UIKit.outlined(capRow, "Cap", 14, Color3.fromRGB(235, 230, 210), 2)
capWords.AnchorPoint = Vector2.new(0, 0)
capWords.Position = UDim2.new(0.5, -72, 0, 1)
capWords.Size = UDim2.fromOffset(200, 20)
capWords.TextXAlignment = Enum.TextXAlignment.Left

-- The celebration: the owner's badge, the Speed shoe in its centre and the
-- milestone written under it.
local badge = Instance.new("ImageLabel")
badge.Name = "Badge"
badge.AnchorPoint = Vector2.new(1, 0.5)
badge.Position = UDim2.new(0, -6, 0, 34)
badge.Size = UDim2.fromOffset(84, 84)
badge.BackgroundTransparency = 1
badge.ScaleType = Enum.ScaleType.Fit
badge.Image = SpeedMilestones.Art.Badge
badge.Visible = false
badge.Parent = bar
local badgeScale = Instance.new("UIScale")
badgeScale.Parent = badge
local badgeShoe = Instance.new("ImageLabel")
badgeShoe.Name = "Shoe"
badgeShoe.AnchorPoint = Vector2.new(0.5, 0.5)
badgeShoe.Position = UDim2.fromScale(0.5, 0.29)
badgeShoe.Size = UDim2.fromOffset(SHOE_PX.Badge, SHOE_PX.Badge)
badgeShoe.BackgroundTransparency = 1
badgeShoe.ScaleType = Enum.ScaleType.Fit
badgeShoe.Image = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Badge)
badgeShoe.ZIndex = 3
badgeShoe.Parent = badge
local badgeNumber = UIKit.outlined(badge, "Number", 22, WHITE, 2)
badgeNumber.AnchorPoint = Vector2.new(0.5, 0.5)
badgeNumber.Position = UDim2.fromScale(0.5, 0.55)
badgeNumber.Size = UDim2.fromScale(0.7, 0.22)
badgeNumber.TextScaled = true
badgeNumber.ZIndex = 3

local celebrateUntil = 0

-- The owner's pictures, fetched at the start: the first pop of a new player
-- came up without its burst in the guarded Play (run 3, capture 01).
task.spawn(function()
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync({ burst, badge, popShoe, barShoe, badgeShoe })
	end)
end)

local function celebrate(milestone: number)
	celebrateUntil = os.clock() + 2.6
	badgeNumber.Text = SpeedMilestones.label(milestone)
	badge.Visible = true
	badgeScale.Scale = 0.3
	TweenService:Create(badgeScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	SoundKit.play(SpeedMilestones.Sounds.Milestone)
end

--==============================================================================
-- THE PACKET
--==============================================================================
local lastSpeed: number? = nil
local speed = 0
local mark: number? = nil
local ticketAt, ticketCount = 0, 0

local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local s = tonumber(profile.Speed)
	if not s then
		return
	end
	-- The first packet is finding out where you already were, not a gain.
	if lastSpeed and s > lastSpeed then
		local gained, nowWalk = SpeedMilestones.walkGain(lastSpeed, s)
		if gained > 0 then
			showPop(gained, nowWalk)
		end
	end
	lastSpeed = s
	speed = s
	local m = tonumber(profile.SpeedMilestone) or 0
	if mark and m > mark then
		celebrate(m)
	end
	mark = m
	ticketAt = tonumber(profile.BeltTicketAt) or 0
	ticketCount = tonumber(profile.BeltTicketCount) or 0
end

--==============================================================================
-- B. THE ITEMS
--==============================================================================
type Drawn = { anchor: Part, board: BillboardGui, image: ImageLabel, record: Instance, gone: number? }
local drawn: { [Instance]: Drawn } = {}

local function localFolder(): Instance
	local cam = camera()
	local host: Instance = cam or Workspace
	local found = host:FindFirstChild(localFolderName)
	if found then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = localFolderName
	made.Parent = host
	return made
end

local function draw(record: Instance)
	if drawn[record] or record:GetAttribute("Owner") ~= player.UserId then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "BeltItem"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	local from = record:GetAttribute("From")
	anchor.Position = if typeof(from) == "Vector3" then from else Vector3.zero
	anchor.Parent = localFolder()
	local board = Instance.new("BillboardGui")
	board.Name = "Item"
	board.Adornee = anchor
	board.AlwaysOnTop = false
	board.LightInfluence = 0
	board.Size = UDim2.fromScale(BeltCatch.DrawStuds, BeltCatch.DrawStuds)
	board.Parent = anchor
	local image = Instance.new("ImageLabel")
	image.Name = "Picture"
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = if record:GetAttribute("Kind") == "ticket" then GameConfig.SourceIcons.tickets else BeltCatch.Art.Coin
	image.ImageTransparency = 1
	image.Parent = board
	drawn[record] = { anchor = anchor, board = board, image = image, record = record, gone = nil }
end

local function vanish(entry: Drawn, caught: boolean)
	if entry.gone then
		return
	end
	entry.gone = os.clock()
	if caught then
		SoundKit.play(if entry.record:GetAttribute("Kind") == "ticket" then BeltCatch.Sounds.Ticket else BeltCatch.Sounds.Coin)
		TweenService:Create(entry.board, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(BeltCatch.DrawStuds * 1.8, BeltCatch.DrawStuds * 1.8) }):Play()
	end
	TweenService:Create(entry.image, TweenInfo.new(if caught then 0.3 else 0.25), { ImageTransparency = 1 }):Play()
	task.delay(0.35, function()
		entry.anchor:Destroy()
	end)
end

local function watchFolder(folder: Instance)
	for _, child in ipairs(folder:GetChildren()) do
		draw(child)
	end
	folder.ChildAdded:Connect(draw)
	folder.ChildRemoved:Connect(function(child: Instance)
		local entry = drawn[child]
		if entry then
			drawn[child] = nil
			vanish(entry, child:GetAttribute("CaughtBy") == player.UserId)
		end
	end)
end

task.spawn(function()
	local folder = Workspace:FindFirstChild("BeltItems")
	if folder then
		watchFolder(folder)
		return
	end
	local conn: RBXScriptConnection? = nil
	conn = Workspace.ChildAdded:Connect(function(child: Instance)
		if child.Name == "BeltItems" then
			if conn then
				conn:Disconnect()
			end
			watchFolder(child)
		end
	end)
end)

--==============================================================================
-- THE OWN BELT, AND EVERY FRAME
--==============================================================================
local function ownBelt(): BasePart?
	local id = player:GetAttribute(ATTR.OwnPlotId)
	if id == nil then
		return nil
	end
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") and belt.Parent and belt.Parent:GetAttribute(ATTR.PlotId) == id then
			return belt
		end
	end
	return nil
end

local beltCache: BasePart? = nil
local beltCheckedAt = 0

--==============================================================================
-- THE HUD, AS THIS GUI SEES IT
--
-- HudLayout's rects for this screen -- every permanent group with its badges,
-- the top row's buttons, the status, notice and boost bands, the clock and
-- ADMIN -- in this gui's pixels, and the safe area they all stand in. Measured
-- again every second: a boost, the x2 card or a REMOVE row changes the answer.
--==============================================================================
local GAP = 8
local hudRects: { SpeedMilestones.Rect } = {}
local hudBounds: SpeedMilestones.Rect? = nil
local hudMeasuredAt = -math.huge

local function measureHud()
	local size = measureGui.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		hudBounds = nil
		return
	end
	local input = HudLayout.measure(measureGui)
	local L = HudLayout.solve(input)
	local k = HudLayout.scaleOf(measureGui)
	local shift = measureGui.AbsolutePosition - gui.AbsolutePosition
	local insetTop = input.insetTop or 0
	local rects: { SpeedMilestones.Rect } = {}
	local function add(r: HudLayout.Rect?, lift: number?)
		if r and r.w > 0 and r.h > 0 then
			table.insert(rects, {
				x = r.x * k + shift.X,
				y = (r.y - (lift or 0)) * k + shift.Y,
				w = r.w * k,
				h = r.h * k,
			})
		end
	end
	for _, r in ipairs(HudLayout.occupied(L)) do
		add(r)
	end
	local status, notice, boosts = HudLayout.statusRows(L, insetTop)
	add(status)
	add(notice)
	add(boosts)
	-- The clock and ADMIN stand in an inset-ignoring gui: HudLayout's own way
	-- from there into safe space is less the inset.
	add(L.clock, insetTop)
	add(L.admin, insetTop)
	hudRects = rects
	hudBounds = { x = shift.X, y = shift.Y, w = size.X, h = size.Y }
end

-- The bar's own size, and the room its badge takes out to its left and over
-- its top. The pop's row (the shoe and the words): as wide as the pop, as tall
-- as the shoe, its middle 67.5 px over the pop's foot (0.55 down a frame 150
-- tall, anchored at its bottom). All before the screen's scale.
local BAR_W, BAR_H = 330, 74
local BADGE_ROOM, BADGE_RISE = 90, 8
local POP_W, POP_WORDS_H, POP_WORDS_UP = 420, SHOE_PX.Pop, 67.5

RunService.RenderStepped:Connect(function(dt: number)
	local t = os.clock()
	local k = scale()
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if t - hudMeasuredAt > 1 then
		hudMeasuredAt = t
		measureHud()
	end
	local bounds = hudBounds

	--==========================================================================
	-- A2: OVER THE BELT, WHERE THE RUNNER IS, UNDER THE HUD (measured in Play
	-- 2026-10-08)
	--
	-- Over the console end it was off the screen: a desktop camera does not turn
	-- when the mill parks a player to face the console, so that end is often out
	-- of view. Over the belt's middle, a little toward the front, it is over the
	-- runner. A close camera puts that point at the top edge or past it, where
	-- the bar sat behind the clock; so it stands at the nearest place clear of
	-- the HUD -- on a desktop, just under the top row's boost band -- and hides
	-- only when the belt is behind the camera or off to a side.
	--==========================================================================
	if t - beltCheckedAt > 1 then
		beltCheckedAt = t
		beltCache = ownBelt()
	end
	local belt = beltCache
	local barRect: SpeedMilestones.Rect? = nil
	if bounds and belt and belt.Parent and root and root:IsA("BasePart") and (root.Position - belt.Position).Magnitude < 45 then
		local half = belt.Size * 0.5
		local at = project(belt.CFrame:PointToWorldSpace(Vector3.new(0, half.Y + 11.5, -half.Z * 0.15)))
		local w, h = BAR_W * k, BAR_H * k
		local room, rise = BADGE_ROOM * k, BADGE_RISE * k
		if at and at.X >= bounds.x and at.X <= bounds.x + bounds.w then
			barRect = SpeedMilestones.clearOf(
				{ x = at.X - w / 2 - room, y = at.Y - h - rise, w = w + room, h = h + rise * 2 },
				hudRects,
				bounds,
				GAP
			)
		end
		if barRect then
			bar.Position = UDim2.fromOffset(barRect.x + room + w / 2, barRect.y + rise + h)
			barScale.Scale = k
			local _, nextOne, amount = SpeedMilestones.progress(mark or 0, speed)
			nextWords.Text = SpeedMilestones.barWords(nextOne)
			fill.Size = UDim2.fromScale(math.clamp(amount, 0, 1), 1)
			barShoe.Position = UDim2.fromScale(math.clamp(amount, 0, 1), 0.5)
			local shoeImage = SizedIcon.at(SpeedMilestones.Art.Shoe, SHOE_PX.Bar * k)
			if barShoe.Image ~= shoeImage then
				barShoe.Image = shoeImage
			end
			capWords.Text = BeltCatch.capWords(BeltCatch.ticketsToday(ticketAt, ticketCount, Workspace:GetServerTimeNow()))
		end
	end
	bar.Visible = barRect ~= nil

	-- A1: over the head while it lasts, clear of the HUD and under the bar.
	if pop.Visible then
		local at = if head and head:IsA("BasePart") then project(head.Position + Vector3.new(0, 2.6, 0)) else nil
		if t >= popUntil or not at then
			pop.Visible = false
		else
			local foot: Vector2 = at
			if bounds then
				local blocked = hudRects
				if barRect then
					blocked = table.clone(hudRects)
					table.insert(blocked, barRect)
				end
				local w, h, up = POP_W * k, POP_WORDS_H * k, POP_WORDS_UP * k
				local words = SpeedMilestones.clearOf({ x = foot.X - w / 2, y = foot.Y - up - h / 2, w = w, h = h }, blocked, bounds, GAP)
				if words then
					foot = Vector2.new(words.x + w / 2, words.y + h / 2 + up)
				end
			end
			pop.Position = UDim2.fromOffset(foot.X, foot.Y)
			local age = t - popBorn
			popScale.Scale = k * (if age < 0.18 then 0.6 + age / 0.18 * 0.5 elseif age < 0.32 then 1.1 - (age - 0.18) / 0.14 * 0.1 else 1)
			burst.Rotation = (burst.Rotation + dt * 45) % 360
			local left = popUntil - t
			local fade = if left < 0.45 then 1 - left / 0.45 else 0
			popWords.TextTransparency = fade
			burst.ImageTransparency = 0.15 + fade * 0.85
			popShoe.ImageTransparency = fade
			local stroke = popWords:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = fade
			end
		end
	end
	if badge.Visible and t >= celebrateUntil then
		badge.Visible = false
	end
	fill.BackgroundColor3 = if t < celebrateUntil and math.floor(t * 6) % 2 == 0 then WHITE else GOLD

	-- B: every item where the server says it is now.
	local serverNow = Workspace:GetServerTimeNow()
	for record, entry in pairs(drawn) do
		if not entry.gone then
			local from, to = record:GetAttribute("From"), record:GetAttribute("To")
			local startsAt = tonumber(record:GetAttribute("StartsAt")) or serverNow
			local endsAt = tonumber(record:GetAttribute("EndsAt")) or serverNow
			if typeof(from) == "Vector3" and typeof(to) == "Vector3" then
				local at = BeltCatch.positionAt(from, to, startsAt, endsAt, serverNow)
				entry.anchor.Position = at + Vector3.new(0, math.sin(serverNow * 5) * 0.18, 0)
			end
			-- In over the lead, out past the far end.
			local appear = math.clamp((serverNow - (startsAt - 0.5)) / 0.4, 0, 1)
			entry.image.ImageTransparency = 1 - appear
			entry.image.Rotation = math.sin(serverNow * 3) * 12
			if record:GetAttribute("CaughtBy") == player.UserId then
				drawn[record] = nil
				vanish(entry, true)
			end
		end
	end
end)

--==============================================================================
-- THE PACKET'S TWO REMOTES (the same SpeedFX listens on)
--==============================================================================
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
