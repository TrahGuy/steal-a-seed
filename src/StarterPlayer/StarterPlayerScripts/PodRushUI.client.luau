--!strict
-- Steal a Seed :: PodRushUI (2026-10-09; KB/POD-RUSH-PLAN.md)
--
-- THE POD RUSH ON THIS SCREEN, all of it drawn from what the server publishes
-- (GameConfig.PodRush; PodRushService) and Shared/PodRush's rules:
--
--   THE TRACKER   while a rush runs: its icon, POD RUSH and the time left, the
--                 pods banked, "2 more for SILVER", and a bar with the three
--                 medals. After the end, only while a pod in the arms still
--                 counts: BANK IT! and the grace left. Placed clear of the
--                 whole HUD on every screen (PodRush.trackerRect), at
--                 Tracker.PhoneScale on a phone -- or, where it has no room
--                 (a short phone with boost icons up), as the one-line STRIP:
--                 the time, the pods banked, the next goal.
--   THE POPS      "+1" when a pod counts; the medal and its name when a level
--                 is reached, with a notice saying what it paid. No pops with
--                 REDUCED FX -- the notice still says it.
--   THE END CARD  POD RUSH OVER, the pods and the level, what it paid; gone
--                 after EndCard.Seconds or a tap.
--   THE RINGS     a golden ring of light under each nest while a rush runs,
--                 breathing (still, with REDUCED FX).
--   THE STINGS    START with the announcement, FINISH with the end card
--                 (SoundKit cues PodRushStart / PodRushFinish; silent while
--                 their ids are "").
--
-- Reads only; it sends nothing to the server.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local PodRush = require(Shared:WaitForChild("PodRush"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CFG = GameConfig.PodRush
local ATTR = CFG.Attributes
local EVENTS = CFG.Events
local WORDS = CFG.Words
local ART = CFG.Art
local T = CFG.Tracker
local E = CFG.EndCard
local POP = CFG.Pop
local RING = CFG.Ring
local MINI = GameConfig.MiniEvent
local MODES: { [string]: any } = MINI.Modes :: any

local GOLD = RING.Colour
local WHITE = Color3.new(1, 1, 1)
local MUTED = Color3.fromRGB(226, 232, 240)
local BANK_RED = T.BankItColour
local DIM = Color3.fromRGB(96, 96, 104)
local WELL = Color3.fromRGB(26, 30, 36)

-- The boost a level gives (SILVER's), for the words.
local BOOST_ID: string? = nil
for _, row in ipairs(CFG.Levels) do
	if (row :: any).Boost then
		BOOST_ID = (row :: any).Boost
	end
end

-- A re-run takes its old self down first.
for _, name in ipairs({ "SeedPodRush", "SeedPodRushCard" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
local oldRings = Workspace:FindFirstChild("SeedPodRushRings")
if oldRings then
	oldRings:Destroy()
end

local function newGui(name: string, order: number): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	-- Safe space, HudLayout's own.
	g.IgnoreGuiInset = false
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.DisplayOrder = order
	UIKit.tenFoot(g)
	g.Parent = playerGui
	return g
end

-- The tracker with the HUD, under the panels; the end card over them.
local gui = newGui("SeedPodRush", 12)
local cardGui = newGui("SeedPodRushCard", 42)

-- The owner's pictures, by their one shared crop.
local function picture(parent: Instance, name: string, id: string, size: number, z: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = name
	image.Size = UDim2.fromOffset(size, size)
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = id
	image.ImageRectOffset = ART.CropOffset
	image.ImageRectSize = ART.CropSize
	image.ScaleType = Enum.ScaleType.Fit
	image.Active = false
	image.ZIndex = z
	image.Parent = parent
	return image
end

local function words(parent: Instance, name: string, size: number, colour: Color3, stroke: number,
	font: Enum.Font?): TextLabel
	local label = UIKit.outlined(parent, name, size, colour, stroke)
	if font then
		label.Font = font
	end
	label.TextScaled = true
	label.Active = false
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = size
	fit.MinTextSize = math.max(9, math.floor(size * 0.6))
	fit.Parent = label
	return label
end

--==============================================================================
-- THE RUSH, AS THE WORKSPACE AND THIS PLAYER SAY IT
--==============================================================================
local function rushNow(): (boolean, string?, number?)
	local A = MINI.Attributes
	if Workspace:GetAttribute(A.State) ~= "running" then
		return false, nil, nil
	end
	local mode = MODES[Workspace:GetAttribute(A.Mode) or ""]
	if not (mode and mode.PodRush == true) then
		return false, nil, nil
	end
	local id = Workspace:GetAttribute(A.EventId)
	local endsAt = Workspace:GetAttribute(A.EndsAt)
	return true, if type(id) == "string" then id else nil, if type(endsAt) == "number" then endsAt else nil
end

-- This player's count, when their numbers are for the rush `id`.
local function myCount(id: any): number
	if type(id) ~= "string" or player:GetAttribute(ATTR.Id) ~= id then
		return 0
	end
	local n = player:GetAttribute(ATTR.Count)
	return if type(n) == "number" then math.max(0, math.floor(n)) else 0
end

--==============================================================================
-- THE TRACKER
--==============================================================================
local tracker = Instance.new("Frame")
tracker.Name = "Tracker"
tracker.Size = UDim2.fromOffset(T.Width, T.Height)
-- TRANSPARENT (2026-10-09, the owner: "pod rush gui must be transparent, everything
-- must be transparent, applies to buffs, and effects"): no plate and no edge
-- behind the tracker, the strip or the end card -- the words carry the game's
-- dark outline over any scene, as the floating signs do.
tracker.BackgroundTransparency = 1
tracker.BorderSizePixel = 0
tracker.Active = false
tracker.Visible = false
tracker.Parent = gui
local trackerScale = Instance.new("UIScale")
trackerScale.Parent = tracker

local trackerIcon = picture(tracker, "Icon", ART.Icon, 58, 2)
trackerIcon.Position = UDim2.fromOffset(8, math.floor((T.Height - 58) / 2))

local LEFT = 74
local title = words(tracker, "Title", 22, GOLD, 3)
title.Position = UDim2.fromOffset(LEFT, 6)
title.Size = UDim2.fromOffset(150, 26)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Text = WORDS.Title

local clock = words(tracker, "Clock", 22, WHITE, 3)
clock.AnchorPoint = Vector2.new(1, 0)
clock.Position = UDim2.new(1, -10, 0, 6)
clock.Size = UDim2.fromOffset(72, 26)
clock.TextXAlignment = Enum.TextXAlignment.Right
clock.ZIndex = 2

local banked = words(tracker, "Banked", 18, WHITE, 2.5, Enum.Font.FredokaOne)
banked.Position = UDim2.fromOffset(LEFT, 33)
banked.Size = UDim2.fromOffset(100, 22)
banked.TextXAlignment = Enum.TextXAlignment.Left
banked.ZIndex = 2

local nextWords = words(tracker, "Next", 14, MUTED, 2, Enum.Font.FredokaOne)
nextWords.AnchorPoint = Vector2.new(1, 0)
nextWords.Position = UDim2.new(1, -10, 0, 35)
nextWords.Size = UDim2.fromOffset(T.Width - LEFT - 110, 20)
nextWords.TextXAlignment = Enum.TextXAlignment.Right
nextWords.ZIndex = 2

-- The bar, its fill, and a medal where each level stands on it.
local BAR_W = T.Width - LEFT - 24
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.Position = UDim2.fromOffset(LEFT, 64)
bar.Size = UDim2.fromOffset(BAR_W, 10)
-- A solid track again (2026-10-10, the owner: "progress bars must not be
-- transparent"): a dark well with a gold edge under the fill. The tracker
-- round it stays transparent.
bar.BackgroundColor3 = WELL
bar.BackgroundTransparency = 0
bar.BorderSizePixel = 0
bar.ZIndex = 2
bar.Parent = tracker
UIKit.corner(bar, 5)
UIKit.stroke(bar, GOLD, 1.5)
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = GOLD
fill.BorderSizePixel = 0
fill.ZIndex = 3
fill.Parent = bar
UIKit.corner(fill, 5)
local fillEdge = UIKit.stroke(fill, Color3.new(0, 0, 0), 1.5)
fillEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local TOP_PODS = CFG.Levels[#CFG.Levels].Pods
local medals: { ImageLabel } = {}
for i, row in ipairs(CFG.Levels) do
	local medal = picture(bar, "Medal" .. i, PodRush.medal(i), 26, 4)
	medal.AnchorPoint = Vector2.new(0.5, 0.5)
	medal.Position = UDim2.new(row.Pods / TOP_PODS, 0, 0.5, 0)
	medals[i] = medal
end

local plus = words(tracker, "Plus", 20, GOLD, 2.5)
plus.Size = UDim2.fromOffset(40, 24)
plus.Text = WORDS.Plus
plus.Visible = false
plus.ZIndex = 5

-- The level's pop, over the tracker.
local levelPop = Instance.new("Frame")
levelPop.Name = "LevelPop"
levelPop.AnchorPoint = Vector2.new(0.5, 1)
levelPop.Position = UDim2.new(0.5, 0, 0, -6)
levelPop.Size = UDim2.fromOffset(200, 78)
levelPop.BackgroundTransparency = 1
levelPop.Visible = false
levelPop.Parent = tracker
local levelScale = Instance.new("UIScale")
levelScale.Parent = levelPop
local levelMedal = picture(levelPop, "Medal", "", 56, 6)
levelMedal.AnchorPoint = Vector2.new(0.5, 0)
levelMedal.Position = UDim2.new(0.5, 0, 0, 0)
local levelName = words(levelPop, "Name", 24, GOLD, 3)
levelName.AnchorPoint = Vector2.new(0.5, 1)
levelName.Position = UDim2.new(0.5, 0, 1, 0)
levelName.Size = UDim2.fromOffset(200, 26)
levelName.ZIndex = 6

-- THE STRIP: the tracker in one line, where the whole of it has no room.
local strip = Instance.new("Frame")
strip.Name = "Strip"
strip.Size = UDim2.fromOffset(T.StripWidth, T.StripHeight)
strip.BackgroundTransparency = 1
strip.BorderSizePixel = 0
strip.Active = false
strip.Visible = false
strip.Parent = gui
local stripIcon = picture(strip, "Icon", ART.Icon, T.StripHeight - 4, 2)
stripIcon.Position = UDim2.fromOffset(4, 2)
local stripLine = words(strip, "Line", 14, WHITE, 2, Enum.Font.FredokaOne)
stripLine.RichText = true
stripLine.Position = UDim2.fromOffset(T.StripHeight + 4, 2)
stripLine.Size = UDim2.new(1, -(T.StripHeight + 10), 1, -4)
stripLine.TextXAlignment = Enum.TextXAlignment.Left
stripLine.ZIndex = 2

-- Whether the beginner's guide card stands under the top row now: the tracker
-- keeps clear of it (UIKit.guideShowing, shared with the buff popover).
local function guideShowing(): boolean
	return UIKit.guideShowing(playerGui)
end

local placedAs: string? = nil
local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local L = HudLayout.solve(input)
	local camera = Workspace.CurrentCamera
	local phone = GameConfig.titlePhone(if camera then camera.ViewportSize else nil, UserInputService.TouchEnabled)
	local k = if phone then T.PhoneScale else 1
	-- And the card where it stands now, in this gui's units: lower than
	-- HudLayout's place while the guide's hand points at the top row (in a
	-- Play on 2026-10-10 the tracker stood over its STEP and SKIP lines).
	local unit = UIKit.scaleOf(gui)
	local guideCard = UIKit.guideRects(playerGui, gui.AbsolutePosition)
	for _, c in ipairs(guideCard) do
		c.x, c.y, c.w, c.h = c.x / unit, c.y / unit, c.w / unit, c.h / unit
	end
	local r, layout = PodRush.trackerRect(L, input.insetTop or 0, k, guideShowing(), guideCard)
	placedAs = if r then layout else nil
	if r and layout == "full" then
		trackerScale.Scale = k
		tracker.Position = UDim2.fromOffset(r.x, r.y)
	elseif r then
		-- The strip, or the mini strip: the same frame at its own width.
		strip.Size = UDim2.fromOffset(r.w, r.h)
		strip.Position = UDim2.fromOffset(r.x, r.y)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

local function paintTracker(now: number)
	local running, id, endsAt = rushNow()
	local holdUntil = Workspace:GetAttribute(ATTR.Until)
	local bankIt = not running and player:GetAttribute(ATTR.Carrying) == true and type(holdUntil) == "number"
	-- Aside while the buff popover stands on it, having no place clear of it
	-- (BoostIconsUI; 2026-10-09).
	local showing = (running or bankIt) and player:GetAttribute(GameConfig.BoostIcons.CoversAttribute) ~= true
	tracker.Visible = showing and placedAs == "full"
	strip.Visible = showing and (placedAs == "strip" or placedAs == "mini")
	if not showing then
		return
	end
	local count = myCount(if running then id else player:GetAttribute(ATTR.Id))
	if strip.Visible then
		stripLine.Text = PodRush.stripLine(count, if running then (endsAt or now) - now else (holdUntil :: number) - now,
			not running, placedAs == "mini")
		return
	end
	if not tracker.Visible then
		return
	end
	if running then
		title.Text = WORDS.Title
		title.TextColor3 = GOLD
		clock.Text = PodRush.clock((endsAt or now) - now)
	else
		title.Text = WORDS.BankIt
		title.TextColor3 = BANK_RED
		clock.Text = PodRush.clock((holdUntil :: number) - now)
	end
	banked.Text = PodRush.bankedLine(count)
	nextWords.Text = PodRush.nextLine(count)
	fill.Size = UDim2.fromScale(math.clamp(count / TOP_PODS, 0, 1), 1)
	local level = PodRush.levelFor(count)
	for i, medal in ipairs(medals) do
		medal.ImageColor3 = if i <= level then WHITE else DIM
		medal.ImageTransparency = if i <= level then 0 else 0.2
	end
end

--==============================================================================
-- THE POPS
--==============================================================================
local function plusOne()
	if StatusText.reducedMotion() or not tracker.Visible then
		return
	end
	local from = UDim2.fromOffset(LEFT + banked.TextBounds.X / math.max(trackerScale.Scale, 0.1) + 6, 31)
	plus.Position = from
	plus.TextTransparency = 0
	plus.Visible = true
	local tween = TweenService:Create(plus, TweenInfo.new(POP.Seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = from - UDim2.fromOffset(0, POP.Rise),
		TextTransparency = 1,
	})
	tween.Completed:Connect(function()
		plus.Visible = false
	end)
	tween:Play()
end

local popToken = 0
local function showLevel(level: number)
	if StatusText.reducedMotion() or not tracker.Visible then
		return
	end
	popToken += 1
	local token = popToken
	levelMedal.Image = PodRush.medal(level)
	levelMedal.ImageTransparency = 0
	levelName.Text = string.format(WORDS.LevelUp, PodRush.levelName(level))
	levelName.TextTransparency = 0
	levelScale.Scale = 0.6
	levelPop.Visible = true
	TweenService:Create(levelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
	task.delay(POP.LevelSeconds, function()
		if token ~= popToken then
			return
		end
		local fade = TweenInfo.new(0.4)
		TweenService:Create(levelMedal, fade, { ImageTransparency = 1 }):Play()
		local out = TweenService:Create(levelName, fade, { TextTransparency = 1 })
		out.Completed:Connect(function()
			if token == popToken then
				levelPop.Visible = false
			end
		end)
		out:Play()
	end)
end

-- What a reward paid, a line each (Shared/PodRush.rewardLines).
local function rewardWords(spins: number, boost: boolean, pod: string?, podOwed: boolean): { string }
	local lines = PodRush.rewardLines({
		spins = spins,
		boost = if boost then BOOST_ID else nil,
		podTier = if pod then 1 else nil,
	}, pod)
	if podOwed then
		table.insert(lines, WORDS.PodOwed)
	end
	return lines
end

local function counted(payload: { [string]: any })
	plusOne()
	local up = payload.levelUp
	if type(up) == "table" and type(up.level) == "number" then
		showLevel(up.level)
		local id = if type(payload.id) == "string" then payload.id else "?"
		Notice.post({
			kind = "success",
			title = string.format(WORDS.LevelUp, PodRush.levelName(up.level)),
			detail = table.concat(rewardWords(tonumber(up.spins) or 0, up.boost == true,
				if type(up.pod) == "string" then up.pod else nil, up.podOwed == true), " \u{00B7} "),
			key = string.format("podrush:level:%s:%d", id, up.level),
			icon = "podrush",
		})
	end
end

--==============================================================================
-- THE END CARD
--==============================================================================
local card = Instance.new("Frame")
card.Name = "EndCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromOffset(E.Width, E.Height)
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = cardGui
local cardScale = Instance.new("UIScale")
cardScale.Parent = card

local cardMedal = picture(card, "Medal", ART.Icon, 76, 2)
cardMedal.AnchorPoint = Vector2.new(0.5, 0)
cardMedal.Position = UDim2.new(0.5, 0, 0, 10)
local cardTitle = words(card, "Title", 26, GOLD, 3)
cardTitle.AnchorPoint = Vector2.new(0.5, 0)
cardTitle.Position = UDim2.new(0.5, 0, 0, 88)
cardTitle.Size = UDim2.new(1, -24, 0, 30)
cardTitle.Text = WORDS.Over
cardTitle.ZIndex = 2
local cardLine = words(card, "Line", 22, WHITE, 2.5)
cardLine.AnchorPoint = Vector2.new(0.5, 0)
cardLine.Position = UDim2.new(0.5, 0, 0, 120)
cardLine.Size = UDim2.new(1, -24, 0, 26)
cardLine.ZIndex = 2
-- Up to four lines (the spins, the boost, the pod, a pod still owed), shrunk
-- together to fit: three at full size clipped the pod's line (seen in Play).
local cardRewards = UIKit.outlined(card, "Rewards", 15, MUTED, 2)
cardRewards.Font = Enum.Font.FredokaOne
cardRewards.AnchorPoint = Vector2.new(0.5, 0)
cardRewards.Position = UDim2.new(0.5, 0, 0, 148)
cardRewards.Size = UDim2.new(1, -24, 0, 44)
cardRewards.TextWrapped = true
cardRewards.TextScaled = true
cardRewards.ZIndex = 2
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 15
	fit.MinTextSize = 9
	fit.Parent = cardRewards
end
local cardHint = UIKit.outlined(card, "Hint", 12, MUTED, 1.5)
cardHint.Font = Enum.Font.FredokaOne
cardHint.AnchorPoint = Vector2.new(0.5, 1)
cardHint.Position = UDim2.new(0.5, 0, 1, -6)
cardHint.Size = UDim2.new(1, -24, 0, 14)
cardHint.Text = WORDS.Close
cardHint.ZIndex = 2
local cardHit = Instance.new("TextButton")
cardHit.Name = "Close"
cardHit.Size = UDim2.fromScale(1, 1)
cardHit.BackgroundTransparency = 1
cardHit.Text = ""
cardHit.AutoButtonColor = false
cardHit.ZIndex = 5
cardHit.Parent = card

local cardToken = 0
local function hideCard()
	cardToken += 1
	card.Visible = false
end
cardHit.Activated:Connect(hideCard)

local function showCard(payload: { [string]: any })
	local count = tonumber(payload.count) or 0
	local level = math.clamp(math.floor(tonumber(payload.level) or 0), 0, #CFG.Levels)
	local medal = PodRush.medal(level)
	cardMedal.Image = if medal ~= "" then medal else ART.Icon
	cardLine.Text = PodRush.overLine(count, level)
	local lines = rewardWords(tonumber(payload.spins) or 0, payload.boost == true,
		if type(payload.pod) == "string" then payload.pod else nil, payload.podOwed == true)
	cardRewards.Text = table.concat(lines, "\n")
	-- Over the hotbar's top, never on it, and clear of the guide's card while it
	-- shows (PodRush.endCard).
	local centre, k = PodRush.endCard(HudLayout.solve(HudLayout.measure(cardGui)), guideShowing())
	card.Position = UDim2.fromOffset(centre.X, centre.Y)
	card.Visible = true
	cardToken += 1
	local token = cardToken
	if StatusText.reducedMotion() then
		cardScale.Scale = k
	else
		cardScale.Scale = k * 0.7
		TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = k,
		}):Play()
	end
	SoundKit.play("PodRushFinish")
	task.delay(E.Seconds, function()
		if token == cardToken then
			card.Visible = false
		end
	end)
end

--==============================================================================
-- THE RINGS UNDER THE NESTS (client-built; nothing collides or is queried)
--==============================================================================
local ringFolder = Instance.new("Folder")
ringFolder.Name = "SeedPodRushRings"
ringFolder.Parent = Workspace
local rings: { [Instance]: Model } = {}
local ringsOn = false

local function buildRing(site: Instance)
	if rings[site] or not site:IsA("BasePart") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "Ring_" .. site.Name
	local breathe = not StatusText.reducedMotion()
	for _, seg in ipairs(PodRush.ring(site.Position)) do
		local part = Instance.new("Part")
		part.Name = "Glow"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = GOLD
		part.Transparency = RING.Transparency
		part.Size = seg.size
		part.CFrame = seg.cframe
		part.Parent = model
		if breathe then
			TweenService:Create(part, TweenInfo.new(RING.PulseSeconds, Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut, -1, true), { Transparency = RING.PulseTo }):Play()
		end
	end
	model.Parent = ringFolder
	rings[site] = model
end

local function dropRing(site: Instance)
	local model = rings[site]
	if model then
		rings[site] = nil
		model:Destroy()
	end
end

local function setRings(on: boolean)
	if on == ringsOn then
		return
	end
	ringsOn = on
	if on then
		for _, site in ipairs(CollectionService:GetTagged(GameConfig.Tags.NestSite)) do
			buildRing(site)
		end
	else
		for site in pairs(rings) do
			dropRing(site)
		end
	end
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.NestSite):Connect(function(site: Instance)
	if ringsOn then
		buildRing(site)
	end
end)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.NestSite):Connect(dropRing)

--==============================================================================
-- THE SERVER'S WORD, AND THE CLOCK
--==============================================================================
local function onEvent(action: any, payload: any)
	if action == MINI.Events.Opened then
		if type(payload) == "table" and payload.mode == CFG.Mode then
			SoundKit.play("PodRushStart")
		end
		return
	end
	if type(payload) ~= "table" then
		return
	end
	if action == EVENTS.Counted then
		counted(payload)
		paintTracker(Workspace:GetServerTimeNow())
	elseif action == EVENTS.Over then
		showCard(payload)
	end
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/PodRushUI] No GameEvent remote; the Pod Rush draws nothing.")
		return
	end
	found.OnClientEvent:Connect(onEvent)
end)

place()
local placedAt = os.clock()
task.spawn(function()
	while gui.Parent do
		local now = Workspace:GetServerTimeNow()
		if os.clock() - placedAt >= 1 then
			placedAt = os.clock()
			place()
		end
		paintTracker(now)
		setRings((rushNow()))
		task.wait(0.25)
	end
end)
