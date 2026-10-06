--!strict
-- Steal a Seed :: WorldClock
--
-- The countdown at the top of the screen, and the night the world falls into.
--
--==============================================================================
-- THE COUNTDOWN IS A SUBTRACTION, NOT A BROADCAST
--
-- The server publishes three attributes on the Workspace and nothing else:
--
--     WorldPhase        "Day" or "Night"
--     WorldPhaseEndsAt  an absolute workspace:GetServerTimeNow()
--     WorldCycleIndex   bumped at every dawn
--
-- This subtracts one from the other every frame it draws. A seven-minute day
-- therefore costs the server three attribute writes instead of 420 remote calls
-- per player, and -- the part that actually matters -- somebody who joins at
-- 03:12 is CORRECT ON THEIR FIRST FRAME. There is no join handshake to miss, no
-- window where the HUD says the wrong thing, and no packet that can arrive late.
--
-- GetServerTimeNow is the same clock on every machine, so two players watching
-- the same countdown see the same number.
--
--==============================================================================
-- NIGHT IS BLUE, NOT BLACK
--
-- People plant, harvest and stand on their mills through the night. A night that
-- made a player's own garden unreadable would be a night they wait out looking
-- at a wall, so the plots stay usable and the drop is in colour temperature far
-- more than in brightness.
--
-- THE DAY VALUES ARE CAPTURED, NOT TYPED. MapService sets the daytime lighting
-- and this reads whatever it finds at boot, so "restore the exact daytime
-- visibility at dawn" is true by construction rather than by two files agreeing
-- about eight numbers. Retune MapService and this follows.
--
-- Entirely client-side. The server never touches Lighting -- which is why the
-- transition costs it nothing and cannot desync anybody -- and the one thing
-- concealment actually depends on is a real part across the road, not this.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- Only for its TV scale (UIKit.tenFoot).
local UIKit = require(Shared:WaitForChild("UIKit"))
-- A Thunderstorm's lightning schedule, and whether this player asked for less.
local RainClouds = require(Shared:WaitForChild("RainClouds"))
local StatusText = require(Shared:WaitForChild("StatusText"))
-- The disco's palette (2026-10-03): the same colours as every disco light.
local DiscoLights = require(Shared:WaitForChild("DiscoLights"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes
local NIGHT = CYCLE.Night
-- THE RAIN (2026-10-02): slightly darker while it falls, laid over the blend
-- below -- this script stays Lighting's one owner. See applyLight.
local RAIN_LIGHT = GameConfig.Weather.Light
-- A THUNDERSTORM'S (2026-10-02): the rain's look with Weather.Thunder.Light's
-- darker numbers laid over it. RAIN is whichever is falling.
local THUNDER_LIGHT = table.clone(RAIN_LIGHT) :: any
for key, value in pairs(GameConfig.Weather.Thunder.Light) do
	THUNDER_LIGHT[key] = value
end
local RAIN = RAIN_LIGHT
local RAIN_STATE = GameConfig.Weather.Attributes.State
local RAIN_MODE = GameConfig.Weather.Attributes.Mode
local RAIN_ID = GameConfig.Weather.Attributes.EventId
local RAIN_STARTED = GameConfig.Weather.Attributes.StartedAt
local LIGHTNING = GameConfig.Weather.Thunder.Lightning
-- THE DISCO (2026-10-03, TICKET DISCO / DISCO ONLY): a little dimmer and a
-- soft drifting tint while a disco mode runs, laid over everything else here
-- -- this script stays Lighting's one owner. See applyLight and THE DISCO.
local MINI = GameConfig.MiniEvent
local DISCO_LIGHT = MINI.Disco.Light
local MINI_MODES: { [string]: any } = MINI.Modes :: any
local SCREEN = CYCLE.Barrier.Screen

local INK = Color3.fromRGB(26, 24, 30)
-- THE COUNTDOWN'S TWO COLOURS (the owner, 2026-10-04): white, and red only by
-- day inside WarnSeconds -- never at night, whose fifteen seconds are all under
-- that window, and never on the icons.
local WHITE = Color3.fromRGB(255, 255, 255)
local WARN = Color3.fromRGB(255, 76, 64)
-- The cycle icon's sizes are HudLayout's (its spec measures the chip's words
-- against them); its uploaded pictures are GameConfig's, "" until uploaded.
local LAYOUT = HudLayout.Config
local ICON_IMAGES = CYCLE.ClockIcons
local FONT = Enum.Font.GothamBlack
-- The bar's words: as large as this, and never under the least, sized once per
-- layout off the longest thing the bar says, so they never change size when
-- the warning starts.
local BAR_TEXT = 20
local BAR_TEXT_LEAST = 12
local LONGEST = "BIOMES CLOSE IN 0:00"

--==============================================================================
-- RE-RUN SAFE
--
-- Rule 10. A Rojo sync re-runs this while the old readout is still on screen,
-- and two countdowns a frame apart is the kind of thing that gets blamed on the
-- clock rather than on the reload.
--==============================================================================
local existing = playerGui:FindFirstChild("SeedWorldClock")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedWorldClock"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- TOP CENTRE, AND SIZED IN SCALE
--
-- Scale rather than offset so it is the same fraction of a phone screen as of a
-- monitor, with a pixel cap so it does not become a banner on an ultrawide.
-- IgnoreGuiInset is on, so this sits clear of the Roblox topbar on every device
-- rather than under it on some.
--==============================================================================
local plate = Instance.new("Frame")
plate.Name = "Plate"
plate.AnchorPoint = Vector2.new(0.5, 0)
plate.Position = UDim2.new(0.5, 0, 0, 8)
plate.Size = UDim2.new(0.44, 0, 0, 34)
plate.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
plate.BackgroundTransparency = 0.25
plate.BorderSizePixel = 0
plate.Parent = gui

local cap = Instance.new("UISizeConstraint")
cap.MinSize = Vector2.new(190, 28)
cap.MaxSize = Vector2.new(360, 40)
cap.Parent = plate

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = plate

local edge = Instance.new("UIStroke")
edge.Color = INK
edge.Thickness = 2.5
edge.Parent = plate

-- The words stand beside the cycle icon, the two centred on the plate as one
-- group (arrangeBar), so their size is set rather than scaled: fitBar.
local text = Instance.new("TextLabel")
text.Name = "Text"
text.AnchorPoint = Vector2.new(0, 0.5)
text.Position = UDim2.new(0.5, 0, 0.5, 0)
text.Size = UDim2.new(0, 0, 1, -8)
text.BackgroundTransparency = 1
text.Font = FONT
text.TextSize = BAR_TEXT
text.TextColor3 = WHITE
text.Text = ""
text.Parent = plate

local textEdge = Instance.new("UIStroke")
textEdge.Color = INK
textEdge.Thickness = 2
textEdge.Parent = text

--==============================================================================
-- THE CYCLE ICON (the owner, 2026-10-04)
--
-- What comes next, beside the words that count down to it: a moon and cloud
-- while the day runs out, a sun and cloud through the night. Decorative -- the
-- words say the same thing -- and not a weather sign: the clouds are part of
-- the picture whatever the sky is doing.
--
-- The approved pictures have no upload id yet (GameConfig.WorldCycle
-- .ClockIcons), so each is drawn from frames (UIKit.cycleIcon); a picture,
-- once one is set, is laid over its drawing and replaces it only once it has
-- actually loaded here (UIKit.whenPictureLoads), never a blank square.
--==============================================================================
local icon = Instance.new("Frame")
icon.Name = "Icon"
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0)
icon.Size = UDim2.fromOffset(LAYOUT.ClockIcon, LAYOUT.ClockIcon)
icon.BackgroundTransparency = 1
icon.Parent = plate

local function cycleIcon(kind: "moon" | "sun", image: string): Frame
	local stack = Instance.new("Frame")
	stack.Name = if kind == "sun" then "Dawn" else "Night"
	stack.BackgroundTransparency = 1
	stack.Size = UDim2.fromScale(1, 1)
	stack.Visible = false
	stack.Parent = icon
	local drawn = UIKit.cycleIcon(stack, kind, 2)
	if image ~= "" then
		local picture = Instance.new("ImageLabel")
		picture.Name = "Picture"
		picture.BackgroundTransparency = 1
		picture.Size = UDim2.fromScale(1, 1)
		picture.Image = image
		picture.ScaleType = Enum.ScaleType.Fit
		picture.ZIndex = 8
		picture.Parent = stack
		UIKit.whenPictureLoads(picture, function(loaded: boolean)
			drawn.Visible = not loaded
		end)
	end
	return stack
end
-- Shown while the day counts down to night, and through the night to dawn.
local toNight = cycleIcon("moon", ICON_IMAGES.Moon)
local toDawn = cycleIcon("sun", ICON_IMAGES.Sun)

--==============================================================================
-- THE CHIP: A PHONE'S CLOCK (2026-09-29)
--
-- The owner's report, from a landscape phone: "the DAY timer is a very wide bar
-- across the top". The bar is 44% of the window because its longest sentence
-- needs the room on one line. On a phone the same plate is a CHIP (HudLayout's
-- `clockChip`, 124 px where the bar was 273 on the owner's screen) and says the
-- same three things on two short lines -- the words over the time:
--
--     NIGHT IN               BIOMES CLOSE IN        DAWN IN
--     6:59                   0:45                   0:14
--
-- (2026-10-04: with the cycle icon at its left end, and the bar's words.)
--
-- Still a different SENTENCE for each as well as a different colour, so nothing
-- is said by colour alone. The width never changes with the words, so nothing
-- beside it on the row moves when the day turns. A desktop, a console and a TV
-- keep the bar exactly as it was.
--==============================================================================
-- Both lines stand right of the chip's icon (HudLayout's Phone.ClockIcon).
local CHIP_TEXT_X = 5 + LAYOUT.Phone.ClockIcon + LAYOUT.Phone.ClockIconGap
local chipWords = Instance.new("TextLabel")
chipWords.Name = "Words"
chipWords.Position = UDim2.fromOffset(CHIP_TEXT_X, 3)
chipWords.Size = UDim2.new(1, -(CHIP_TEXT_X + 5), 0, 11)
chipWords.BackgroundTransparency = 1
chipWords.Font = Enum.Font.GothamBlack
chipWords.TextScaled = true
chipWords.TextColor3 = WHITE
chipWords.Text = ""
chipWords.Visible = false
chipWords.Parent = plate
local chipWordsCap = Instance.new("UITextSizeConstraint")
chipWordsCap.MaxTextSize = 10
chipWordsCap.MinTextSize = 7
chipWordsCap.Parent = chipWords
local chipWordsEdge = Instance.new("UIStroke")
chipWordsEdge.Color = INK
chipWordsEdge.Thickness = 1.5
chipWordsEdge.Parent = chipWords

local chipTime = Instance.new("TextLabel")
chipTime.Name = "Time"
chipTime.Position = UDim2.fromOffset(CHIP_TEXT_X, 14)
chipTime.Size = UDim2.new(1, -(CHIP_TEXT_X + 5), 0, 18)
chipTime.BackgroundTransparency = 1
chipTime.Font = Enum.Font.GothamBlack
chipTime.TextSize = 17
chipTime.TextColor3 = WHITE
chipTime.Text = ""
chipTime.Visible = false
chipTime.Parent = plate
local chipTimeEdge = Instance.new("UIStroke")
chipTimeEdge.Color = INK
chipTimeEdge.Thickness = 2
chipTimeEdge.Parent = chipTime

-- Which face is up: the chip's two lines, or the bar's one.
local chip = false

--==============================================================================
-- THE BAR'S GROUP: THE ICON, THEN THE WORDS, CENTRED AS ONE
--
-- fitBar picks the words' size once per layout -- the largest up to BAR_TEXT
-- at which the longest sentence and the icon fit the plate -- and arrangeBar
-- centres icon and words on the plate's middle each time the words change,
-- off their measured width (TextService), so the icon always stands right
-- beside them. The chip's are fixed: the icon at its left end, the two lines
-- right of it.
--==============================================================================
local barWords = ""

local function wordsWidth(words: string, size: number): number
	return TextService:GetTextSize(words, size, FONT, Vector2.new(4000, 100)).X
end

local function arrangeBar(words: string)
	barWords = words
	if chip then
		return
	end
	local w = math.ceil(wordsWidth(words, text.TextSize)) + 4
	local left = -math.floor((LAYOUT.ClockIcon + LAYOUT.ClockIconGap + w) / 2)
	icon.Position = UDim2.new(0.5, left, 0.5, 0)
	text.Position = UDim2.new(0.5, left + LAYOUT.ClockIcon + LAYOUT.ClockIconGap, 0.5, 0)
	text.Size = UDim2.new(0, w, 1, -8)
end

local function fitBar(plateWidth: number)
	local room = plateWidth - 16 - LAYOUT.ClockIcon - LAYOUT.ClockIconGap
	local size = BAR_TEXT
	while size > BAR_TEXT_LEAST and wordsWidth(LONGEST, size) > room do
		size -= 1
	end
	text.TextSize = size
end

--==============================================================================
-- CENTRED, AND NEVER UNDER A ROBLOX BUTTON
--
-- The plate above is the whole look and is not touched: same scale, same
-- 190-360 band, same 34 px, same text. What HudLayout adds is a ceiling -- no
-- wider than the topbar's free span allows while staying centred, 8 px clear
-- of the Roblox buttons on both sides -- so on a narrow phone the plate gets
-- a little narrower and TextScaled takes the words down with it. Below 170 px
-- it stops shrinking and slides the least it can instead.
--
-- On every desktop and every listed phone the ceiling is above the plate's own
-- width and this changes nothing. Asked again on a resize or when the topbar
-- changes shape; never per frame.
--==============================================================================
local function placePlate()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local r, viewport = layout.clock, input.viewport
	if not (r and viewport) then
		return
	end
	cap.MaxSize = Vector2.new(math.min(360, r.w), 40)
	cap.MinSize = Vector2.new(math.min(190, r.w), 28)
	-- The chip's two lines on a phone, the bar's one line everywhere else.
	chip = layout.clockChip
	text.Visible = not chip
	chipWords.Visible = chip
	chipTime.Visible = chip
	if chip then
		local size = LAYOUT.Phone.ClockIcon
		icon.Size = UDim2.fromOffset(size, size)
		icon.Position = UDim2.new(0, 5, 0.5, 0)
	else
		icon.Size = UDim2.fromOffset(LAYOUT.ClockIcon, LAYOUT.ClockIcon)
		-- The plate is as wide as HudLayout's rect wherever the cap allows it.
		fitBar(math.min(r.w, cap.MaxSize.X))
		arrangeBar(barWords)
	end
	-- r.y is GameConfig's 8 everywhere but a TV, whose clock row comes down to
	-- the title-safe edge.
	plate.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - viewport.X / 2), 0, r.y)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placePlate)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placePlate)
gui.Destroying:Once(function()
	topbarWatch:Disconnect()
end)
placePlate()

--==============================================================================
-- THE THREE THINGS IT CAN SAY (the owner's wording, 2026-10-04)
--
--     (moon) NIGHT IN 6:59          the ordinary day, in white
--     (moon) BIOMES CLOSE IN 0:45   the last WarnSeconds of the day, in RED
--     (sun)  DAWN IN 0:14           the whole (fifteen-second) night, in white
--
-- Each says what comes next. The warning is a different SENTENCE as well as
-- the one red, not a colour change alone -- a player who is colourblind or
-- looking at their plot rather than the top of the screen gets the same
-- information from the words. Red is the day's warning only: a night is all
-- inside WarnSeconds and stays white, and dawn starts white again.
--==============================================================================
-- The wall's countdown (mm:ss), which this does not restyle.
local function clock(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(whole / 60), whole % 60)
end

-- The HUD's (m:ss).
local function shortClock(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

--==============================================================================
-- THE BIG ONE, ON THE WALL
--
-- The barrier is a screen now -- MapService paints a night sky on the face that
-- meets the field -- and the countdown on it is driven from here rather than
-- from the server, for the same reason the HUD clock is: it is a subtraction
-- both machines can already do, and a server writing this string thirty times a
-- second would replicate it to every player to tell them something they know.
--
-- It is also why the two can never disagree. There is one `left` in this file
-- and both readouts are formatted from it; a second timer computing its own
-- would be a second thing to keep true.
--
-- RESOLVED FRESH, NEVER CACHED ACROSS A REBUILD. MapService.Init destroys the
-- SeedMap folder and builds a new barrier, so a reference held from boot points
-- at a part that is no longer in the world -- which is exactly what the tag on
-- it exists to avoid. Cached until it goes stale, then looked up again: the
-- lookup is one array read and it happens twice a session, not twice a frame.
--==============================================================================
local screenTimer: TextLabel? = nil

local function bigTimer(): TextLabel?
	local held = screenTimer
	if held and held.Parent and held:IsDescendantOf(Workspace) then
		return held
	end
	screenTimer = nil
	for _, part in ipairs(CollectionService:GetTagged(GameConfig.Tags.NightBarrier)) do
		local screen = part:FindFirstChild("NightScreen")
		local label = screen and screen:FindFirstChild("Timer")
		if label and label:IsA("TextLabel") then
			screenTimer = label
			return label
		end
	end
	return nil
end

local lastBig = ""
local lastBigInk: Color3? = nil

local function drawBigTimer(phase: string?, left: number)
	local label = bigTimer()
	if not label then
		return
	end
	--==========================================================================
	-- BLANK BY DAY, AND BLANK IS NOT A COSMETIC CHOICE
	--
	-- The whole SurfaceGui is disabled by day -- MapService does that with the
	-- wall -- so nothing here is visible either way. What this protects is the
	-- FIRST FRAME OF NIGHT: a label still holding the last number of the
	-- previous night would be shown for one frame before this runs, and a clock
	-- that flashes a stale time is worse than one that arrives a frame late.
	--==========================================================================
	local wording = if phase == CYCLE.PhaseNight then clock(left) else ""
	local ink = if left <= SCREEN.SoonSeconds then SCREEN.InkSoon else SCREEN.InkTimer

	if wording ~= lastBig then
		lastBig = wording
		label.Text = wording
	end
	if ink ~= lastBigInk then
		lastBigInk = ink
		label.TextColor3 = ink
	end
end

local lastText = ""
local lastColour = WHITE
-- The chip's own two lines, written only when they change, like the bar's.
local lastWords, lastTime = "", ""
local lastChipColour = WHITE
-- Which icon stands: what the countdown is counting down to.
local lastNext = ""

--==============================================================================
-- A PHASE AND ITS DEADLINE ARE TWO ATTRIBUTES, AND THEY MOVE TOGETHER
--
-- WorldCycleService writes both in one server frame, and they land together.
-- If one ever arrived a frame before the other, a boundary would be drawn as
-- the old phase with the new phase's time -- "BIOMES CLOSE IN 00:15" at the
-- start of a night, "NIGHT * PODS RETURN IN 07:00" at dawn -- which with a
-- fifteen-second night would happen eight times as often as it used to.
--
-- So a pair in which exactly ONE half has moved, at a boundary (the deadline
-- this readout last drew was already due), is held: the last words stay up
-- until the other half lands, for half a second at most. A player joining
-- mid-phase has nothing to compare against and is drawn at once.
--==============================================================================
local seenPhase: string? = nil
local seenEndsAt: number? = nil
local heldSince: number? = nil

local function settled(phase: string, endsAt: number, now: number): boolean
	local lastPhase, lastEndsAt = seenPhase, seenEndsAt
	if lastPhase ~= nil and lastEndsAt ~= nil
		and (phase ~= lastPhase) ~= (endsAt ~= lastEndsAt)
		and lastEndsAt - now <= 0.5 then
		local since = heldSince or os.clock()
		heldSince = since
		if os.clock() - since < 0.5 then
			return false
		end
	end
	heldSince = nil
	seenPhase, seenEndsAt = phase, endsAt
	return true
end

local function draw()
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(phase) ~= "string" or type(endsAt) ~= "number" then
		-- The cycle service has not published yet. Silent rather than wrong: a
		-- readout guessing at a phase is worse than no readout for one frame.
		-- The wall says nothing either, for the same reason.
		plate.Visible = false
		drawBigTimer(nil, 0)
		return
	end
	local now = Workspace:GetServerTimeNow()
	if not settled(phase, endsAt, now) then
		-- Half a pair: the last words, and the wall's, stay as they were.
		return
	end
	plate.Visible = true

	local left = math.max(0, endsAt - now)
	drawBigTimer(phase, left)
	local wording: string
	local colour: Color3
	-- The same three, as the chip says them: the words, and the time under them.
	local words: string
	-- What it counts down to, which is the icon beside it.
	local nextUp: string

	if phase == CYCLE.PhaseNight then
		wording = "DAWN IN " .. shortClock(left)
		words = "DAWN IN"
		colour = WHITE
		nextUp = "dawn"
	elseif phase == CYCLE.PhaseDay and left <= CYCLE.WarnSeconds then
		wording = "BIOMES CLOSE IN " .. shortClock(left)
		words = "BIOMES CLOSE IN"
		colour = WARN
		nextUp = "night"
	else
		wording = "NIGHT IN " .. shortClock(left)
		words = "NIGHT IN"
		colour = WHITE
		nextUp = "night"
	end

	if nextUp ~= lastNext then
		lastNext = nextUp
		toNight.Visible = nextUp == "night"
		toDawn.Visible = nextUp == "dawn"
	end

	if chip then
		local time = shortClock(left)
		if words ~= lastWords then
			lastWords = words
			chipWords.Text = words
		end
		if time ~= lastTime then
			lastTime = time
			chipTime.Text = time
		end
		if colour ~= lastChipColour then
			lastChipColour = colour
			chipWords.TextColor3 = colour
			chipTime.TextColor3 = colour
		end
	end

	-- Written only when it changes. TextScaled re-measures on every assignment,
	-- and this draws every frame.
	if wording ~= lastText then
		lastText = wording
		text.Text = wording
		arrangeBar(wording)
	end
	if colour ~= lastColour then
		lastColour = colour
		text.TextColor3 = colour
	end
end

--==============================================================================
-- THE LIGHT
--
-- Captured at boot from whatever MapService set, so dawn restores the real
-- daytime values rather than a second copy of them that could drift.
--==============================================================================
type Look = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	EnvironmentDiffuseScale: number,
	ExposureCompensation: number,
}

local day: Look = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	ExposureCompensation = Lighting.ExposureCompensation,
}

local night: Look = {
	ClockTime = NIGHT.ClockTime,
	Brightness = NIGHT.Brightness,
	Ambient = NIGHT.Ambient,
	OutdoorAmbient = NIGHT.OutdoorAmbient,
	EnvironmentDiffuseScale = NIGHT.EnvironmentDiffuseScale,
	ExposureCompensation = NIGHT.ExposureCompensation,
}

--==============================================================================
-- BLENDED, NOT TWEENED
--
-- One number carries the whole transition and every property is read off it, so
-- a phase that flips back mid-fade simply reverses -- where six TweenService
-- tweens would have to be found and cancelled, and any that were missed would
-- keep pulling towards a night that is already over.
--
-- ClockTime wraps at 24, so it is moved DOWN from 14 to 0 rather than up through
-- midnight, which would spin the sun the long way round.
--==============================================================================
local blend = 0

--==============================================================================
-- THE FOG RIDES THE SAME NUMBER
--
-- MapService builds the banks inside each lane at Transparency = 1 and never
-- touches them again; this is the only thing that makes them visible. Off the
-- same `blend` as the light, so fog and darkness arrive together and a phase
-- that flips back mid-fade reverses both -- which is the whole reason that
-- number exists rather than six tweens.
--
-- ENTIRELY CLIENT-SIDE, like the lighting above it and for the same reason: the
-- server owns nothing here, so the transition costs it nothing and cannot
-- desync anybody. It is also why this is allowed to be cosmetic. The wall
-- across the road mouth is what actually closes the world; a client drawing no
-- fog at all would be no more able to get in, and there is nothing left in
-- there to see.
--
--==============================================================================
-- AND THE LIST IS EVENT-DRIVEN, BECAUSE THIS PLACE STREAMS
--
-- The first version collected the tagged parts once and re-collected only when
-- the first one lost its parent. Measured in a real session, that is wrong:
-- `Workspace.StreamingEnabled` is TRUE here, so a client holds only the fog near
-- its camera. Standing in Greenhollow at night the client had 51 of the 80
-- masses -- Emberroot 3 of 16, Starbloom none at all.
--
-- A cached list therefore misses every mass that streams in afterwards, and a
-- missed mass is not a dim one, it is an INVISIBLE one: the server builds them
-- at Transparency = 1 and this is the only thing that ever changes that. Running
-- down the road would have opened clean holes in the fog exactly where the
-- player was heading.
--
-- So the tag's own signals drive it. A mass that arrives is faded to wherever
-- the transition currently is, immediately, rather than waiting for the next
-- phase change -- otherwise everything streamed in mid-night stays invisible
-- until dawn.
--==============================================================================
local FOG_NIGHT = CYCLE.Fog.NightTransparency
local fogParts: { [BasePart]: true } = {}

local function fogTransparency(t: number): number
	-- 1 is invisible, so this walks DOWN from 1 to the night value.
	return 1 + (FOG_NIGHT - 1) * t
end

local function applyFog(t: number)
	local want = fogTransparency(t)
	for part in pairs(fogParts) do
		part.Transparency = want
	end
end

for _, part in ipairs(CollectionService:GetTagged(GameConfig.Tags.BiomeFog)) do
	if part:IsA("BasePart") then
		fogParts[part] = true
	end
end

CollectionService:GetInstanceAddedSignal(GameConfig.Tags.BiomeFog):Connect(function(part)
	if part:IsA("BasePart") then
		fogParts[part] = true
		part.Transparency = fogTransparency(blend)
	end
end)

CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.BiomeFog):Connect(function(part)
	fogParts[part] = nil
end)

--==============================================================================
-- THE RAIN, OVER THE BLEND (2026-10-02)
--
-- A second number, `rain`, 0 to 1, eased toward WeatherService's state the way
-- `blend` is eased toward the phase, and laid over the day/night result of the
-- same call: OVERCAST, not dark -- a fraction of the brightness kept, some
-- exposure taken off, the ambients moved part way toward the rain's cool grey
-- (its day pair by day, its night pair by night, blended like everything
-- else), softer shadows, less glint, a restrained cool tone through the one
-- ColorCorrection this script owns, and the sky's own cloud layer (a Terrain
-- Clouds instance, this client's, created here if the place has none and
-- blended from the place's own values if it has). Day or night underneath,
-- the rain neither forces a phase nor pauses the cycle, and when it stops
-- there is no stale value to put back -- the blend is simply recomputed with
-- rain at 0, so the light that comes back is the CURRENT phase's. It comes in
-- over FadeSeconds and goes over FadeOutSeconds, as long as the white clouds
-- and the biome take to fade. A player who joins while it rains starts at 1.
--==============================================================================
local rain = 0
-- A Thunderstorm's flash of light: extra exposure for an instant, on the moments
-- RainClouds.lightning names (none under reduced motion or Reduced FX). The bolt
-- itself is Weather.client's.
local flash = 0

--==============================================================================
-- THE DISCO, OVER BOTH (2026-10-03)
--
-- A third number, `disco`, 0 to 1, eased toward "a disco mode is running"
-- (MiniEventService's attributes) over Disco.Light.FadeSeconds: a fraction of
-- the brightness kept and a little exposure off -- laid over the day/night
-- blend and the rain in the same call -- and a soft tint, through a
-- ColorCorrection of this script's own, drifting slowly round the colour
-- wheel from the event's shared start time (steady under reduced motion). No
-- flash, no strobe: it moves a full turn in Disco.HueSeconds. When the disco
-- ends the light is simply recomputed with disco at 0, so what comes back is
-- whatever weather, day or night is live NOW -- nothing is restored from a
-- snapshot taken when it began.
--
-- MAP-WIDE (2026-10-03): the colour is the disco PALETTE's (DiscoLights,
-- purple / pink / gold / green / cyan / blue, blended over CycleSeconds), and
-- the ambient light everywhere leans toward it too (Disco.Light.AmbientMix),
-- so the whole map -- hub, plots, every biome, the rain biome -- moves through
-- the disco's colours without a single extra light. That part is all Reduced
-- FX keeps. While the disco shows, the light is recomputed every frame (the
-- colour drifts); the local pools and spots are MiniEventFX's.
--==============================================================================
local disco = 0
-- The palette's colour this frame (white while no disco shows).
local discoColour = Color3.new(1, 1, 1)
-- Re-run safe: a Rojo re-sync leaves the last run's tone behind otherwise.
for _, staleTone in ipairs(Lighting:GetChildren()) do
	if staleTone.Name == "DiscoTone" and staleTone:IsA("ColorCorrectionEffect") then
		staleTone:Destroy()
	end
end
local discoTone = Instance.new("ColorCorrectionEffect")
discoTone.Name = "DiscoTone"
discoTone.Enabled = false
discoTone.Parent = Lighting

local function discoWanted(): number
	if Workspace:GetAttribute(MINI.Attributes.State) ~= "running" then
		return 0
	end
	local mode = MINI_MODES[Workspace:GetAttribute(MINI.Attributes.Mode) or ""]
	return if mode and mode.Disco then 1 else 0
end

local function applyDiscoTone()
	if disco <= 0.001 then
		discoTone.Enabled = false
		return
	end
	local startedAt = tonumber(Workspace:GetAttribute(MINI.Attributes.StartedAt)) or 0
	local t = if StatusText.reducedMotion() then 0 else Workspace:GetServerTimeNow() - startedAt
	discoColour = DiscoLights.colourAt(t, 0)
	discoTone.TintColor = Color3.new(1, 1, 1):Lerp(discoColour, DISCO_LIGHT.TintMix * disco)
	discoTone.Enabled = true
end

local baseShadow = Lighting.ShadowSoftness
local baseSpecular = Lighting.EnvironmentSpecularScale

local tone = Instance.new("ColorCorrectionEffect")
tone.Name = "RainTone"
tone.Enabled = false
tone.Parent = Lighting

local sky = Workspace.Terrain:FindFirstChildOfClass("Clouds")
local skyBase = { Cover = 0, Density = 0, Color = Color3.new(1, 1, 1), Enabled = false }
if sky then
	skyBase = { Cover = sky.Cover, Density = sky.Density, Color = sky.Color, Enabled = sky.Enabled }
else
	sky = Instance.new("Clouds")
	sky.Name = "RainSky"
	sky.Cover = 0
	sky.Density = 0
	sky.Enabled = false
	sky.Parent = Workspace.Terrain
end

local function applyLight(t: number)
	local r = rain
	Lighting.ClockTime = day.ClockTime + (night.ClockTime - day.ClockTime) * t
	local kept = RAIN.Brightness + (RAIN.NightBrightness - RAIN.Brightness) * t
	Lighting.Brightness = (day.Brightness + (night.Brightness - day.Brightness) * t)
		* (1 - (1 - kept) * r)
		* (1 - (1 - DISCO_LIGHT.Brightness) * disco)
	-- The disco's ambient: toward the palette's colour, scaled so it tints
	-- rather than brightens or blackens (Disco.Light.AmbientMix, AmbientValue).
	local discoAmbient = Color3.new(discoColour.R * DISCO_LIGHT.AmbientValue, discoColour.G * DISCO_LIGHT.AmbientValue,
		discoColour.B * DISCO_LIGHT.AmbientValue)
	local discoMix = DISCO_LIGHT.AmbientMix * disco
	Lighting.Ambient = day.Ambient:Lerp(night.Ambient, t)
		:Lerp(RAIN.Ambient:Lerp(RAIN.NightAmbient, t), RAIN.AmbientMix * r)
		:Lerp(discoAmbient, discoMix)
	Lighting.OutdoorAmbient = day.OutdoorAmbient:Lerp(night.OutdoorAmbient, t)
		:Lerp(RAIN.OutdoorAmbient:Lerp(RAIN.NightOutdoorAmbient, t), RAIN.AmbientMix * r)
		:Lerp(discoAmbient, discoMix)
	Lighting.EnvironmentDiffuseScale = day.EnvironmentDiffuseScale
		+ (night.EnvironmentDiffuseScale - day.EnvironmentDiffuseScale) * t
	Lighting.ExposureCompensation = day.ExposureCompensation
		+ (night.ExposureCompensation - day.ExposureCompensation) * t
		+ RAIN.Exposure * r
		+ DISCO_LIGHT.Exposure * disco
		+ flash
	Lighting.ShadowSoftness = baseShadow + (RAIN.ShadowSoftness - baseShadow) * r
	Lighting.EnvironmentSpecularScale = baseSpecular * (1 - (1 - RAIN.SpecularScale) * r)
	tone.TintColor = Color3.new(1, 1, 1):Lerp(RAIN.Tint, r)
	tone.Saturation = RAIN.Saturation * r
	tone.Contrast = RAIN.Contrast * r
	tone.Enabled = r > 0.001
	sky.Cover = skyBase.Cover + (RAIN.Sky.Cover - skyBase.Cover) * r
	sky.Density = skyBase.Density + (RAIN.Sky.Density - skyBase.Density) * r
	sky.Color = skyBase.Color:Lerp(RAIN.Sky.DayColor:Lerp(RAIN.Sky.NightColor, t), r)
	sky.Enabled = skyBase.Enabled or r > 0.001
	applyFog(t)
end

RunService.RenderStepped:Connect(function(dt)
	draw()

	local changed = false
	local state = Workspace:GetAttribute(RAIN_STATE)
	local wantRain = if state == "opening" or state == "active" then 1 else 0
	-- Which look is falling: the mode is kept until the next event names one,
	-- so the fade out after a Thunderstorm is a Thunderstorm's.
	local mode = Workspace:GetAttribute(RAIN_MODE)
	if mode ~= nil then
		local look = if mode == "thunder" then THUNDER_LIGHT else RAIN_LIGHT
		if RAIN ~= look then
			RAIN = look
			changed = true
		end
	end
	local nextFlash = 0
	if mode == "thunder" and wantRain == 1 and not StatusText.reducedMotion() then
		local id, started = Workspace:GetAttribute(RAIN_ID), Workspace:GetAttribute(RAIN_STARTED)
		if type(id) == "number" and type(started) == "number" then
			local bright = RainClouds.lightning(id, started, Workspace:GetServerTimeNow())
			nextFlash = bright * LIGHTNING.Exposure * rain
		end
	end
	if math.abs(nextFlash - flash) > 1e-4 then
		flash = nextFlash
		changed = true
	end
	if rain ~= wantRain then
		local seconds = if wantRain > rain then RAIN.FadeSeconds else RAIN.FadeOutSeconds
		local step = dt / math.max(0.05, seconds)
		rain = if wantRain > rain
			then math.min(wantRain, rain + step)
			else math.max(wantRain, rain - step)
		changed = true
	end
	local wantDisco = discoWanted()
	if disco ~= wantDisco then
		local step = dt / math.max(0.05, DISCO_LIGHT.FadeSeconds)
		disco = if wantDisco > disco then math.min(wantDisco, disco + step) else math.max(wantDisco, disco - step)
		changed = true
	end
	if disco > 0 or discoTone.Enabled then
		applyDiscoTone()
		-- The palette drifts every frame, and the ambient follows it.
		changed = true
	end
	local want = if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0
	if blend ~= want then
		local step = dt / math.max(0.05, NIGHT.FadeSeconds)
		blend = if want > blend
			then math.min(want, blend + step)
			else math.max(want, blend - step)
		changed = true
	end
	if changed then
		applyLight(blend)
	end
end)

draw()
-- A late joiner sees the rain's light at once, not faded in.
do
	local state = Workspace:GetAttribute(RAIN_STATE)
	rain = if state == "opening" or state == "active" then 1 else 0
	-- And the disco's, likewise (2026-10-03).
	disco = discoWanted()
	applyDiscoTone()
end
applyLight(if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0)
blend = if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0
