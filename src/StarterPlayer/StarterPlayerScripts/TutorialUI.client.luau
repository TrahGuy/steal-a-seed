--!strict
--==============================================================================
-- MARIGOLD'S FIRST GARDEN -- shown, not read.
--
-- Version 1 was an objective card: a title, a paragraph, a bearing and a
-- distance. It was accurate and nobody looked at it, because a paragraph is a
-- thing you stop to read and this is a game you play while running.
--
-- So the card is gone. What replaced it is a trail of arrows on the ground, a
-- highlight on the thing to touch, and four words over it. The player should
-- know the next action from the SHAPE of the screen, and the words should only
-- confirm what the arrows already said.
--
--==============================================================================
-- EVERYTHING HERE IS LOCAL AND ADVISORY
--
-- The server is the only thing that decides a step is done. This file draws
-- where to go; it never claims arrival, never grants anything, and never sends
-- a milestone. The only three things it may say are snapshot / skip / resume.
--
-- Every world object it makes is created on the CLIENT, so it exists on this
-- screen and nobody else's -- that is what makes "visible only to the relevant
-- player" a property of where the code runs rather than a filter to maintain.
-- All of it is anchored, non-colliding, non-query, non-touch and non-archivable.
--
--==============================================================================
-- THE HAND AND THE SPOTLIGHT (the owner's brief, 2026-10-08)
--
-- The owner's pointing glove replaced the HUD's gold pointer and the world's
-- green finger. Once per step a HUD target is SPOTLIT -- the screen dimmed round
-- one real button, which alone takes a press, movement untouched -- and a
-- seventh step, `travel`, teaches OBBY and TELEPORT TO PLOT after the hatch.
-- TutorialSpotlight holds the rules and the arithmetic (TutorialSpotlightSpec).
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Data = require(Shared:WaitForChild("TutorialData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- Where the notices stand on a phone, beside the guide's words; and whether one
-- is up at all, which the spotlight waits out.
local Notice = require(Shared:WaitForChild("Notice"))
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
-- THE SPOTLIGHT AND THE POINTING HAND (the owner's brief, 2026-10-08): the rules
-- and the arithmetic are TutorialSpotlight's; this file draws them.
local Spot = require(Shared:WaitForChild("TutorialSpotlight"))
-- A controller in hand (the selection goes on a lit button only then), and a
-- panel or a reward moment up (no spotlight over either).
local PadInput = require(Shared:WaitForChild("PadInput"))
local RewardMoments = require(Shared:WaitForChild("RewardMoments"))
-- Only for the note the OBBY button leaves when it is pressed (EntranceAsked).
local ObbyData = require(Shared:WaitForChild("ObbyData"))
-- The starter pod's words on the training steps (2026-10-08).
local FirstMinute = require(Shared:WaitForChild("FirstMinute"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = SeedGame:WaitForChild("Remotes")
local channel = remotes:WaitForChild(Config.Remotes.GameEvent) :: RemoteEvent

local ATTR = Config.Attributes
local PLOT = Config.Plot

--== the HUD's own palette, so the guide is the same voice ====================
local GOLD = Color3.fromRGB(255, 211, 105)
local CREAM = Color3.fromRGB(255, 246, 220)
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

--== bounded costs, all of them ===============================================
--==============================================================================
-- THE TRAIL IS A CHAIN OF FLOWING ARROW BEAMS
--
-- One Beam per leg of the route, each carrying the standard flowing-arrow
-- texture. The texture scrolls ITSELF from TextureSpeed, so the animation costs
-- no Lua at all -- there is no per-frame trail work in this file any more.
--
-- CHAINED RATHER THAN ONE LONG BEAM, because a single beam from the player to
-- the objective is a straight line and would run through fences, the mill and
-- the plot wall. The legs are the pathfinding waypoints, so the arrows bend
-- around the things a straight beam would cut through.
--==============================================================================
local TRAIL_NODES = 24       -- the whole pool; spacing stretches to fit a route
local MIN_SPACING = 7
local ARROW_TEXTURE = "rbxassetid://18518488457"
local ARROW_HEIGHT = 1.6     -- studs above the walked surface
-- Tuned by eye down a real 245-stud route home, not guessed: at 3.2 studs the
-- arrows read as a dotted line from any distance worth guiding over.
local ARROW_WIDTH = 5.0
local ROUTE_EVERY = 0.7      -- seconds between pathfinding attempts
local ROUTE_MOVED = 9        -- ...or sooner if the player has moved this far
local TICK = 0.2             -- state refresh, 5Hz

local existing = playerGui:FindFirstChild("SeedBeginnerGuide")
if existing then
	existing:Destroy()
end
-- The spotlight's and the world hand's own guis (below), from an earlier run.
for _, name in ipairs({ "SeedGuideSpotlight", "SeedGuideMarker" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedBeginnerGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 30 -- menus and the raid alarm still take priority
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

local connections: { RBXScriptConnection } = {}
local alive = true
local progress: Data.Progress? = nil
local hidden = false
local confirmSkip = false
local celebrated = false
local hintUntil = 0
--==============================================================================
-- THE SPEED SCORE COMES FROM THE PROFILE PACKET, NOT AN ATTRIBUTE
--
-- There deliberately is no SpeedScore attribute: GameConfig publishes only
-- SpeedVisualTier, "one small integer... every OTHER client needs to know which
-- ghost to draw, not how rich you are". The real score is owner-only and rides
-- the profile, which replicates every 0.25s while it is dirty -- so training
-- updates this four times a second, which is live enough to count with.
--==============================================================================
local speedScore = 0

--==============================================================================
-- THE INSTRUCTION. NO PLATE, EVER.
--
-- CashUI's note applies word for word: "The outline IS the readability. There is
-- no plate behind these, so it is the only thing keeping a lime number legible
-- on lime grass." Same font, same black stroke, same reasoning -- a big opaque
-- panel would be the objective card coming back wearing different colours.
--==============================================================================
local function outlined(parent: Instance, name: string, size: number,
	colour: Color3, thickness: number): TextLabel
	local label = UIKit.outlined(parent, name, size, colour, thickness)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	return label
end

--==============================================================================
-- THE WORDS STAND TOGETHER, SO THEY CAN STAND DOWN TOGETHER (2026-09-29)
--
-- The banner, Skip and GUIDE live in one full-size holder that draws nothing
-- and takes no input. On a phone the words stand in the left column, beside
-- the band the notices pass through at the top of the screen; while a notice is
-- up the holder is hidden, so a notice is never written over the guide's words
-- or they over it, and comes back the moment the notice has gone (Notice.reach).
-- Only the words: the arrows, the highlight and the markers in the world carry
-- on. Everywhere else the holder is always shown and changes nothing.
--==============================================================================
local words = Instance.new("Frame")
words.Name = "Words"
words.Size = UDim2.fromScale(1, 1)
words.BackgroundTransparency = 1
words.BorderSizePixel = 0
words.Active = false
words.Parent = gui
-- How far the words have stepped down for the pointing hand (THE BANNER MAKES
-- ROOM, below), in this gui's units; 0 almost always.
local wordsShift = 0

local banner = Instance.new("Frame")
banner.Name = "Instruction"
banner.BackgroundTransparency = 1
banner.AnchorPoint = Vector2.new(.5, 0)
banner.Position = UDim2.new(.5, 0, 0, 84)
banner.Size = UDim2.fromOffset(560, 84)
banner.Visible = false
banner.Parent = words
-- HudLayout's `tutorialScale` (placeBanner): 1, except on a phone, where the
-- whole banner -- lines, outlines and spacing together -- is drawn smaller.
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner
-- The same scale for the pointer and the celebration, kept from the last layout.
local tutorialScale = 1

local instruction = outlined(banner, "Line", 34, CREAM, 3)
instruction.Size = UDim2.new(1, 0, 0, 42)
local subline = outlined(banner, "Sub", 19, GOLD, 2.5)
subline.Position = UDim2.fromOffset(0, 42)
subline.Size = UDim2.new(1, 0, 0, 24)
local counter = outlined(banner, "Counter", 15, Color3.fromRGB(196, 219, 173), 2)
counter.Position = UDim2.fromOffset(0, 64)
counter.Size = UDim2.new(1, 0, 0, 18)

-- Small, off to the side, and never over a gameplay button.
local skip = Instance.new("TextButton")
skip.Name = "Skip"
skip.Text = "Skip guide"
skip.Font = Enum.Font.GothamBold
skip.TextSize = 12
skip.TextColor3 = Color3.fromRGB(214, 205, 184)
skip.BackgroundTransparency = 1
skip.AutoButtonColor = false
skip.AnchorPoint = Vector2.new(.5, 0)
skip.Position = UDim2.new(.5, 0, 0, 168)
skip.Size = UDim2.fromOffset(150, 20)
skip.Visible = false
skip.Parent = words
UIKit.stroke(skip, BLACK, 2)

local resume = Instance.new("TextButton")
resume.Name = "Resume"
resume.Text = "GUIDE"
resume.Font = Enum.Font.LuckiestGuy
resume.TextSize = 16
resume.TextColor3 = GOLD
resume.BackgroundTransparency = 1
resume.AutoButtonColor = false
resume.AnchorPoint = Vector2.new(.5, 0)
resume.Position = UDim2.new(.5, 0, 0, 84)
resume.Size = UDim2.fromOffset(150, 26)
resume.Visible = false
resume.Parent = words
UIKit.stroke(resume, BLACK, 2.5)

--==============================================================================
-- WHERE THE BANNER SITS, AND HOW IT KEEPS ITS WORDS
--
-- On a desktop: 560 wide, 84 px down, centred, exactly as before. On a phone
-- that is the middle of a 300-px-tall safe area, where the cash block and the
-- BAT/TRAP column both stand -- so HudLayout puts it under the top rows and
-- between whichever of those share its band, off centre rather than squeezed.
-- Skip stays under it and GUIDE on top of it, wherever that is.
--
-- The three lines scale down only in that mode, and only when the banner is
-- narrower than their words: each is capped at the size it was drawn at, so
-- a line that fits is drawn exactly as before.
--
-- ON A PHONE THE WORDS ARE SMALLER (owner, 2026-09-24): HudLayout hands a
-- banner already at `tutorialScale` and this frame is laid out at 1 inside it
-- and scaled down by that much, so the lines keep their proportions and caps
-- and are simply drawn smaller. The pointer and the celebration follow the same
-- number. The skip line and GUIDE are buttons and keep their size.
--
-- Placed again when the topbar's free span changes, as WorldClock is: the
-- banner stands under the teleport button, which stands under the clock.
--==============================================================================
local BANNER_LINES = { { instruction, 34 }, { subline, 19 }, { counter, 15 } }
for _, line in ipairs(BANNER_LINES) do
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = line[2]
	cap.Parent = line[1]
end

--==============================================================================
-- ON A PHONE: THE LEFT COLUMN, THE WAY A QUEST LINE STANDS (2026-09-29)
--
-- The owner's report, from a landscape phone: the guide's words ("TAKE A POD!")
-- were among the things filling the middle of the screen, with the player's own
-- forward view behind them. Measured the same day in Studio's phone emulation:
-- the banner, its step and its skip line ran from the clock's column to the
-- character's waist, and pushed the boost row onto the belt.
--
-- Where HudLayout says `guide` -- a touch screen with room for it -- the same
-- three lines stand in the left column, under WALK MODE and clear of the dock's
-- handle, left-aligned:
--
--     STEP 3 / 6   Skip guide        one row: the counter, and the button
--     TAKE A POD!                    the instruction, two lines at the most
--     Pods return at dawn ...        the advice, two lines at the most
--
-- The words are WRAPPED rather than squeezed onto one line, and drawn a size
-- smaller only when two lines will not hold them -- so a long instruction is a
-- second line, not smaller type. Skip stands on the row ABOVE the words, so the
-- button never moves when the words change length. Laid out at 1 inside the
-- banner's own scale like every other size here: the sizes below are drawn at
-- HudLayout's `tutorialScale`, 18 and 11 on a phone.
--
-- A desktop, a console, a TV and a small window keep the banner exactly as it
-- was: every property this sets is put back to what it had there.
--==============================================================================
local GUIDE = { Line = 24, LineMin = 17, Sub = 15, SubMin = 13, Counter = 14, Gap = 3, Lines = 2 }
local guide = false
-- The row the counter and Skip stand on, and the block's width; at scale 1.
local guideRow, guideWidth = 0, 0

-- The size, from `size` down to `least`, at which `text` stands in `lines` lines
-- of `width`, and how tall that is.
local function wrappedAt(text: string, size: number, least: number, width: number, lines: number): (number, number)
	local at = size
	while true do
		local one = TextService:GetTextSize("Ag", at, Enum.Font.LuckiestGuy, Vector2.new(10000, 10000)).Y
		local all = TextService:GetTextSize(text, at, Enum.Font.LuckiestGuy, Vector2.new(width, 10000)).Y
		if all <= one * lines + 1 or at <= least then
			return at, math.min(all, one * lines) + 2
		end
		at -= 1
	end
end

local function layoutGuide()
	if not guide or guideWidth <= 0 then
		return
	end
	local y = guideRow + GUIDE.Gap
	for _, line in ipairs({ { instruction, GUIDE.Line, GUIDE.LineMin }, { subline, GUIDE.Sub, GUIDE.SubMin } }) do
		local label = line[1] :: TextLabel
		if label.Text == "" then
			label.Size = UDim2.fromOffset(guideWidth, 0)
			label.Position = UDim2.fromOffset(0, y)
		else
			local size, height = wrappedAt(label.Text, line[2] :: number, line[3] :: number, guideWidth, GUIDE.Lines)
			label.TextSize = size
			label.Position = UDim2.fromOffset(0, y)
			label.Size = UDim2.fromOffset(guideWidth, height)
			y += height + GUIDE.Gap
		end
	end
end
table.insert(connections, instruction:GetPropertyChangedSignal("Text"):Connect(layoutGuide))
table.insert(connections, subline:GetPropertyChangedSignal("Text"):Connect(layoutGuide))

-- The words stand down while a notice is up beside them (a phone only), and
-- while a buff popover with no clear place but over them is open (2026-10-09:
-- a 705 x 338 phone, under the panel's row) -- BoostIconsUI's client-local
-- BoostIcons.CoversAttribute, which the Pod Rush tracker steps aside for too.
local COVERS = Config.BoostIcons.CoversAttribute
local function coverWords()
	words.Visible = not ((guide and Notice.reach() ~= nil) or player:GetAttribute(COVERS) == true)
end
table.insert(connections, Notice.onReach(coverWords))
table.insert(connections, player:GetAttributeChangedSignal(COVERS):Connect(coverWords))

local function placeBanner()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local top = Vector2.new(0.5, 0)
	tutorialScale = layout.tutorialScale
	bannerScale.Scale = tutorialScale
	banner.Size = UDim2.fromOffset(layout.banner.w / tutorialScale, layout.banner.h / tutorialScale)
	banner.Position = HudLayout.place(layout.banner, top, layout.safe)
	skip.Position = HudLayout.place(layout.skip, top, layout.safe)
	skip.Size = UDim2.fromOffset(layout.skip.w, layout.skip.h)
	guide = layout.guide
	if guide then
		local row = HudLayout.Config.Phone.Guide.Row
		guideRow = row / tutorialScale
		guideWidth = layout.banner.w / tutorialScale
		for _, label in ipairs({ instruction, subline }) do
			label.TextScaled = false
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
		end
		counter.TextScaled = false
		counter.TextSize = GUIDE.Counter
		counter.TextXAlignment = Enum.TextXAlignment.Left
		counter.Position = UDim2.fromOffset(0, 0)
		counter.Size = UDim2.fromOffset(HudLayout.Config.Phone.Counter / tutorialScale, guideRow)
		skip.TextXAlignment = Enum.TextXAlignment.Left
		resume.AnchorPoint = Vector2.new(0, 0)
		resume.TextXAlignment = Enum.TextXAlignment.Left
		resume.Position = UDim2.fromOffset(layout.banner.x, layout.banner.y)
		layoutGuide()
	else
		-- The banner as it always was, whatever a phone's layout last set.
		instruction.Position = UDim2.fromOffset(0, 0)
		instruction.Size = UDim2.new(1, 0, 0, 42)
		subline.Position = UDim2.fromOffset(0, 42)
		subline.Size = UDim2.new(1, 0, 0, 24)
		counter.Position = UDim2.fromOffset(0, 64)
		counter.Size = UDim2.new(1, 0, 0, 18)
		for _, line in ipairs(BANNER_LINES) do
			local label = line[1] :: TextLabel
			label.TextSize = line[2] :: number
			label.TextWrapped = false
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.TextScaled = layout.compact
		end
		skip.TextXAlignment = Enum.TextXAlignment.Center
		resume.AnchorPoint = Vector2.new(0.5, 0)
		resume.TextXAlignment = Enum.TextXAlignment.Center
		resume.Position = UDim2.new(0.5, banner.Position.X.Offset, 0, layout.banner.y)
	end
	coverWords()
end
table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeBanner))
table.insert(connections, GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeBanner))
-- A trap's REMOVE row over the strip (LoadoutUI, 2026-10-04): a phone's guide
-- keeps clear of the band, which it raises.
table.insert(connections, player:GetAttributeChangedSignal(Config.Hotbar.RemoveRowAttribute):Connect(placeBanner))
-- And the x2 card beside a phone's cash line (2026-10-05), which the belt keeps off.
table.insert(connections, player:GetAttributeChangedSignal(Config.Pass.MultiplierAttribute):Connect(placeBanner))
placeBanner()

--==============================================================================
-- THE POINTING HAND AND THE SPOTLIGHT (the owner's brief, 2026-10-08)
--
-- The owner's glove (TutorialSpotlight.Hand.Image) replaced the gold pointer
-- that stood here. On the HUD it points at a real, rendered element, read off
-- its AbsolutePosition and AbsoluteSize every frame -- nothing here knows a
-- desktop coordinate, so the inset, the notch, a phone's widths and a TV's
-- UIScale are all somebody else's problem and it still lands on the thing.
--
-- ONCE PER STEP a HUD target is SPOTLIT: the screen goes 65% black round a
-- rounded window on it, a gold ring pulses on the window's edge, and only that
-- button takes a press.
--
-- ITS OWN GUI, WITH NO SCREEN INSETS. The dim has to cover the notch and the
-- topbar, which the guide's own gui (IgnoreGuiInset false, a TV's UIScale)
-- cannot reach. Every rect is measured in this gui's own pixels -- a target's
-- AbsolutePosition less this gui's -- which is what lands the window exactly on
-- a button that lives under a different inset. DisplayOrder 61, over every HUD
-- button (ADMIN is 60), so its blockers are what a tap meets; while the dim
-- shows, the guide's gui is raised over it, so the words and "Skip guide" stay
-- readable and pressable.
--
-- MOVEMENT IS NEVER BLOCKED. Nothing here lays anything that takes input over
-- the screen: the dim is a stroke, the hand and its words are labels. What
-- stops every OTHER button is a transparent blocker laid over each one, so a
-- thumb on the empty screen still reaches the touch thumbstick, the jump button
-- and the camera, and the keyboard and the stick are never touched at all.
--==============================================================================
local SPOT_ORDER = 61
local GUIDE_ORDER = gui.DisplayOrder
local spotGui = Instance.new("ScreenGui")
spotGui.Name = "SeedGuideSpotlight"
spotGui.ResetOnSpawn = false
spotGui.IgnoreGuiInset = true
spotGui.ScreenInsets = Enum.ScreenInsets.None
spotGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
spotGui.DisplayOrder = SPOT_ORDER
spotGui.Parent = playerGui

-- Transparent sinks over every other button while the dim shows (placeBlockers).
local blockerFolder = Instance.new("Folder")
blockerFolder.Name = "Blockers"
blockerFolder.Parent = spotGui

-- The window. It draws nothing itself: its enormous stroke IS the dim, which is
-- how the hole gets its rounded corners.
local hole = Instance.new("Frame")
hole.Name = "Window"
hole.BackgroundTransparency = 1
hole.BorderSizePixel = 0
hole.Active = false
hole.Visible = false
hole.ZIndex = 2
hole.Parent = spotGui
UIKit.corner(hole, Spot.Corner)
local shade = Instance.new("UIStroke")
shade.Name = "Dim"
shade.Color = BLACK
shade.Thickness = 4000
shade.Transparency = 1 - Spot.Dim
shade.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
shade.LineJoinMode = Enum.LineJoinMode.Round
shade.Parent = hole

local ring = Instance.new("Frame")
ring.Name = "Ring"
ring.BackgroundTransparency = 1
ring.BorderSizePixel = 0
ring.Active = false
ring.Visible = false
ring.ZIndex = 3
ring.Parent = spotGui
UIKit.corner(ring, Spot.Corner)
local ringStroke = UIKit.stroke(ring, GOLD, Spot.Ring.Thickness)

local hand = Instance.new("ImageLabel")
hand.Name = "Hand"
hand.BackgroundTransparency = 1
hand.Image = Spot.Hand.Image
hand.ScaleType = Enum.ScaleType.Fit
hand.AnchorPoint = Vector2.new(0.5, 0.5)
hand.Active = false
hand.Visible = false
hand.ZIndex = 5
hand.Parent = spotGui

-- Its words, and under them a controller's key while a button is lit.
local handWords = outlined(spotGui, "Words", Spot.Words.Size, CREAM, 3)
handWords.Visible = false
handWords.ZIndex = 6
local handKey = outlined(spotGui, "Key", Spot.Words.KeySize, GOLD, 2)
handKey.Visible = false
handKey.ZIndex = 6

--==============================================================================
-- THE CELEBRATION
--
-- Transparent text, a pop that overshoots and settles, a short burst of colour
-- and one existing cue. It never locks movement and never covers a button: it
-- is drawn high on the screen and it goes away by itself.
--==============================================================================
local party = Instance.new("Frame")
party.Name = "Celebration"
party.BackgroundTransparency = 1
party.AnchorPoint = Vector2.new(.5, .5)
party.Position = UDim2.new(.5, 0, .34, 0)
party.Size = UDim2.fromOffset(620, 150)
party.Visible = false
party.ZIndex = 8
party.Parent = gui
local partyScale = Instance.new("UIScale")
partyScale.Scale = 0.2
partyScale.Parent = party
local bigLine = outlined(party, "Big", 52, GOLD, 4)
bigLine.Size = UDim2.new(1, 0, 0, 66)
bigLine.Text = "CONGRATULATIONS!"
bigLine.ZIndex = 9
local smallLine = outlined(party, "Small", 26, CREAM, 3)
smallLine.Position = UDim2.fromOffset(0, 68)
smallLine.Size = UDim2.new(1, 0, 0, 34)
smallLine.Text = "You hatched your first plant!"
smallLine.ZIndex = 9

--==============================================================================
-- HOW FAR DOWN THE GUIDE'S WORDS REACH (2026-09-27)
--
-- In the HUD's own units (HudLayout's safe space): the skip line while the
-- banner is up, the celebration's foot while it plays, nil when neither.
-- BonusChestUI stands its boost row under it -- the chest only opens after the
-- guide, but the reward wheel can hand a new player a boost in the middle of it.
--==============================================================================
local function publishReach()
	local reach: number? = nil
	-- Not on a phone, whose words stand in the left column: nothing under the
	-- clock has to step round them there.
	if banner.Visible and not guide then
		local layout = HudLayout.solve(HudLayout.measure(gui))
		reach = layout.skip.y + layout.skip.h + wordsShift
	end
	if party.Visible then
		-- Centred at 34% of the gui, 150 tall at its full scale (celebrate).
		local foot = (gui.AbsoluteSize.Y / UIKit.scaleOf(gui)) * 0.34 + 75 * tutorialScale
		reach = math.max(reach or 0, foot)
	end
	player:SetAttribute(ATTR.TutorialReach, reach)
end
table.insert(connections, banner:GetPropertyChangedSignal("Visible"):Connect(publishReach))
table.insert(connections, party:GetPropertyChangedSignal("Visible"):Connect(publishReach))
table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(publishReach))
publishReach()

--==============================================================================
-- WORLD OBJECTS
--
-- One folder, a fixed pool, and nothing that can ever be saved into the place.
--==============================================================================
local world = Instance.new("Folder")
world.Name = "SeedGuideVisuals"
world.Archivable = false
world.Parent = workspace

--==============================================================================
-- A FIXED POOL OF NODES, AND ONE BEAM BETWEEN EACH NEIGHBOURING PAIR
--
-- Built once at login and reused for every route for the rest of the session.
-- Nothing is created or destroyed while the guide is running.
--==============================================================================
local nodes: { Attachment } = {}
local legs: { Beam } = {}
for i = 1, TRAIL_NODES do
	local part = Instance.new("Part")
	part.Name = "TrailNode" .. i
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Archivable = false
	part.Parent = world
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	nodes[i] = attachment
	if i > 1 then
		local beam = Instance.new("Beam")
		--==================================================================
		-- ATTACHMENT0 IS THE NODE FURTHER ALONG, AND THAT IS NOT A TYPO
		--
		-- The arrow glyph in this texture points from Attachment1 TOWARD
		-- Attachment0 -- the opposite of what reading the property names
		-- suggests. Built the obvious way round, the trail was a neat line of
		-- chevrons all pointing back the way the player had come, which is
		-- worse than no trail. Checked by photographing it from the side
		-- against known geometry rather than by reasoning about it.
		--
		-- TextureSpeed is then NEGATIVE so the flow also travels toward the
		-- objective instead of away from it. Speed sets the motion; the
		-- attachment order sets which way the arrowheads face.
		--==================================================================
		beam.Attachment0 = attachment
		beam.Attachment1 = nodes[i - 1]
		beam.Texture = ARROW_TEXTURE
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 9
		beam.TextureSpeed = -1.4
		beam.Width0 = ARROW_WIDTH
		beam.Width1 = ARROW_WIDTH
		beam.FaceCamera = true      -- readable from any angle, like a HUD arrow
		beam.LightInfluence = 0
		beam.Brightness = 3
		beam.Color = ColorSequence.new(GOLD)
		beam.Segments = 1           -- each leg is already a straight line
		beam.Enabled = false
		beam.Parent = attachment
		legs[i - 1] = beam
	end
end
local legCount = 0

local highlight = Instance.new("Highlight")
highlight.Name = "GuideTarget"
highlight.FillColor = GOLD
highlight.FillTransparency = 0.72
highlight.OutlineColor = CREAM
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = gui

--==============================================================================
-- THE HAND IN THE WORLD (2026-10-08; it replaced the gold beacon and the green
-- finger, which were AlwaysOnTop billboards)
--
-- Over a world target -- the mill's belt, a pod, a free spot of soil, the plot's
-- spawn -- the same glove points DOWN at it and taps. No dim: the ground arrows
-- carry the route. Drawn as a marker in a ScreenGui at the target's projected
-- point, the way PromptUI stands its prompts: in front of the world like the
-- billboards were, under every HUD layer (DisplayOrder 12), sized as a sign
-- WorldHand.Studs tall at that distance within readable bounds -- and, unlike an
-- AlwaysOnTop billboard, it shows up in a Studio capture.
--
-- `worldPoint` is where the FINGERTIP goes; nil hides it. Set by refresh
-- through handOver, drawn every frame by drawFrame.
--==============================================================================
local WorldHand = { Studs = 3.2, Least = 40, Most = 96, Bob = 0.7 }
-- How far above what refresh hands it the fingertip stops, in studs: where the
-- old beacon's and finger's tips stood.
local BELT_TIP = 3.2
local POD_TIP = 2.8
local SOIL_TIP = 2.2
local SPAWN_TIP = 3
-- A little past the teleport cooldown OBBY and TELEPORT share before TELEPORT is
-- lit: the server counts it from the moment it moved the player, one trip after
-- this client pressed.
local COOL_MARGIN = 0.4
local markGui = Instance.new("ScreenGui")
markGui.Name = "SeedGuideMarker"
markGui.ResetOnSpawn = false
-- Its pixels are the camera's viewport's, which WorldToViewportPoint answers in.
markGui.IgnoreGuiInset = true
markGui.DisplayOrder = 12
markGui.Parent = playerGui
local worldHand = Instance.new("ImageLabel")
worldHand.Name = "WorldHand"
worldHand.BackgroundTransparency = 1
worldHand.Image = Spot.Hand.Image
worldHand.ScaleType = Enum.ScaleType.Fit
worldHand.AnchorPoint = Vector2.new(0.5, 0.5)
-- Drawn pointing up; turned to point down at the target.
worldHand.Rotation = 180
worldHand.Visible = false
worldHand.Parent = markGui
local worldWords = outlined(markGui, "Words", 20, CREAM, 3)
worldWords.TextXAlignment = Enum.TextXAlignment.Left
worldWords.Visible = false

local worldPoint: Vector3? = nil
local worldText = ""
-- The world hand's fingertip at `point` (nil: none), with `text` beside it.
local function handOver(point: Vector3?, text: string?)
	worldPoint = point
	worldText = text or ""
end

--==============================================================================
-- THE HUD, AS THE MARKER GUI SEES IT (2026-10-10)
--
-- Every HUD layer draws over the world hand, so it stands clear of them
-- (TutorialSpotlight.worldHand): HudLayout's rects for this screen -- every
-- permanent group with its badges, the top row's buttons, the clock and ADMIN
-- -- and Roblox's own topbar buttons either side of its free span, in the
-- marker gui's pixels. Not the notices' line: it is theirs only while one
-- passes. Measured again when the screen changes shape or the HUD's own
-- attributes move it (the phone's panel row folding, the boost icons, a trap's
-- REMOVE row), and once a second besides -- never per frame. The guide's own
-- words are added live in drawWorld: they step down and back.
--==============================================================================
local worldHud: { Spot.Rect } = {}
local worldHudAt = -math.huge

local function measureWorldHud()
	worldHudAt = os.clock()
	local size = gui.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		worldHud = {}
		return
	end
	local input = HudLayout.measure(gui)
	local L = HudLayout.solve(input)
	local k = HudLayout.scaleOf(gui)
	local shift = gui.AbsolutePosition - markGui.AbsolutePosition
	local insetTop = input.insetTop or 0
	local view = input.viewport
	local originX = if view then (view.X - input.safe.X) / 2 else 0
	local rects: { Spot.Rect } = {}
	-- `dx`, `dy`: how far a window-space rect is from safe space.
	local function add(r: HudLayout.Rect?, dx: number?, dy: number?)
		if r and r.w > 0 and r.h > 0 then
			table.insert(rects, {
				x = (r.x - (dx or 0)) * k + shift.X,
				y = (r.y - (dy or 0)) * k + shift.Y,
				w = r.w * k,
				h = r.h * k,
			})
		end
	end
	for _, r in ipairs(HudLayout.occupied(L)) do
		if r ~= L.toast then
			add(r)
		end
	end
	add(L.clock, originX, insetTop)
	add(L.admin, originX, insetTop)
	local bar = input.topbar
	if bar and bar.h > 0 then
		add(HudLayout.rect(0, bar.y, bar.x, bar.h), originX, insetTop)
		local right = bar.x + bar.w
		local width = if view then view.X else input.safe.X
		add(HudLayout.rect(right, bar.y, width - right, bar.h), originX, insetTop)
	end
	worldHud = rects
end

do
	local moves: { [string]: boolean } = {
		[Config.BoostIcons.Attribute] = true,
		[Config.Hotbar.RemoveRowAttribute] = true,
		[HudLayout.Config.Phone.Panel.ShutAttribute] = true,
	}
	local function stale()
		worldHudAt = -math.huge
	end
	table.insert(connections, player.AttributeChanged:Connect(function(name: string)
		if moves[name] then
			stale()
		end
	end))
	table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(stale))
	table.insert(connections, markGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(stale))
end

--==============================================================================
-- WHAT THE GUIDE IS LOOKING AT
--==============================================================================
local function myPlot(): Model?
	for _, model in CollectionService:GetTagged(Config.Tags.Plot) do
		if model:IsA("Model") and model:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return model
		end
	end
	return nil
end

-- The belt is the tagged part; its PARENT model carries the plot id. Matching on
-- that is what makes this YOUR mill and not the one next door.
local function myBelt(plot: Model?): BasePart?
	if not plot then
		return nil
	end
	local id = plot:GetAttribute(ATTR.PlotId)
	if type(id) ~= "number" then
		return nil
	end
	for _, belt in CollectionService:GetTagged(Config.Tags.Treadmill) do
		if belt:IsA("BasePart") and belt.Parent and belt.Parent:GetAttribute(ATTR.PlotId) == id then
			return belt
		end
	end
	return nil
end

-- Where a player actually stands to train: the top face of the belt, not the
-- model's pivot, which on a mill sits inside the housing.
local function beltStand(belt: BasePart): Vector3
	return (belt.CFrame * CFrame.new(0, belt.Size.Y * 0.5 + 0.5, 0)).Position
end

local function toolOf(hatched: boolean): Tool?
	local function find(container: Instance?): Tool?
		if not container then
			return nil
		end
		for _, tool in container:GetChildren() do
			if tool:IsA("Tool") and SeedData.Get(tool:GetAttribute("SpeciesId"))
				and (tool:GetAttribute("Hatched") == true) == hatched then
				return tool
			end
		end
		return nil
	end
	return find(player.Character) or find(player:FindFirstChildOfClass("Backpack"))
end

local function plantsFolder(plot: Model): Instance?
	return plot:FindFirstChild(PLOT.PlantsFolderName)
end

local function podIn(plot: Model): Model?
	local folder = plantsFolder(plot)
	local earliest: Model? = nil
	local best = math.huge
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Stage") == 1 then
				-- The server's stamped deadline; the ladder only as a fallback for
				-- a model from before pods carried one.
				local ready = tonumber(m:GetAttribute("HatchAt"))
					or ((tonumber(m:GetAttribute("PlantedAt")) or os.time())
						+ SeedData.GrowSeconds(m:GetAttribute("Tier")))
				if ready < best then
					best = ready
					earliest = m
				end
			end
		end
	end
	return earliest
end

--==============================================================================
-- PODS HATCH IN THE BAG (2026-10-09)
--
-- The soonest deadline of the pods in the Bag (their Tools' HatchAt, the
-- server's os.time()), or nil with none; and the two doors the guide points at
-- for a hatch: the Bag itself (the strip's Bag cell, else the rail's Bag button)
-- and, with the Bag open, its HATCH ALL -- each only while it is on screen.
--==============================================================================
local function bagPodDue(): number?
	local soonest: number? = nil
	for _, container in { player.Character, player:FindFirstChildOfClass("Backpack") } do
		if container then
			for _, tool in container:GetChildren() do
				local due = if tool:IsA("Tool") and tool:GetAttribute("Hatched") ~= true
					then tonumber(tool:GetAttribute(Config.HatchInBag.Attribute)) else nil
				if due and (soonest == nil or due < soonest) then
					soonest = due
				end
			end
		end
	end
	return soonest
end

local function bagGuiButton(name: string): GuiButton?
	local found = playerGui:FindFirstChild(name, true)
	if found and found:IsA("GuiButton") and found.Visible then
		return found
	end
	return nil
end

--==============================================================================
-- A FREE SPOT ON YOUR OWN SOIL
--
-- Sampled on the soil's own top face and rejected against whatever is already
-- planted, so a full or rearranged bed produces NO spot rather than a finger
-- hovering over an occupied hole. The server still clamps and validates the real
-- placement; this only has to be honest about where there is room.
--==============================================================================
local function freeSpot(plot: Model, soil: BasePart, from: Vector3): Vector3?
	local folder = plantsFolder(plot)
	local taken: { Vector3 } = {}
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") then
				taken[#taken + 1] = m:GetPivot().Position
			end
		end
	end
	local half = soil.Size * 0.5
	local top = half.Y + 0.05
	local best: Vector3? = nil
	local bestScore = math.huge
	for gx = -2, 2 do
		for gz = -2, 2 do
			local point = (soil.CFrame * CFrame.new(
				half.X * (gx / 3) * 1.5, top, half.Z * (gz / 3) * 1.5)).Position
			local clear = true
			for _, other in taken do
				if (Vector3.new(other.X, 0, other.Z) - Vector3.new(point.X, 0, point.Z)).Magnitude < 4.5 then
					clear = false
					break
				end
			end
			if clear then
				local score = (point - from).Magnitude
				if score < bestScore then
					bestScore = score
					best = point
				end
			end
		end
	end
	return best
end

--==============================================================================
-- THE TRAIL
--
-- A real route, not a straight line: AgentCanJump is false, so the path goes
-- through the plot's gateway rather than over its fence, and around the mill
-- rather than across it. If pathfinding cannot answer, NOTHING is drawn -- a
-- straight line of arrows through a wall is worse than no arrows, because the
-- player trusts it and walks into the wall.
--==============================================================================
local routePoints: { Vector3 } = {}
local routeAt = 0
local routeFrom = Vector3.zero
local routeTo = Vector3.zero
local routeBusy = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function hideTrail()
	for i = 1, #legs do
		legs[i].Enabled = false
	end
	legCount = 0
end

local function layTrail(points: { Vector3 })
	local character = player.Character
	rayParams.FilterDescendantsInstances = { world, character or world }

	-- Total length first, so the fixed pool can be stretched to cover the whole
	-- route instead of running out partway down a long one.
	local total = 0
	for i = 1, #points - 1 do
		total += (points[i + 1] - points[i]).Magnitude
	end
	if total < 4 then
		hideTrail()
		return
	end
	--==========================================================================
	-- The pool STRETCHES to cover whatever it is given: a 245-stud run home gets
	-- the same 24 nodes a 30-stud walk to the mill does, just further apart. A
	-- fixed spacing would have run out partway down the long one.
	--==========================================================================
	local spacing = math.max(MIN_SPACING, total / (TRAIL_NODES - 1))

	local used = 0
	local travelled = 0
	local nextMark = 0
	local function placeNode(point: Vector3)
		-- Sat on whatever the player will actually walk over, then lifted --
		-- following the ground rather than the straight line between waypoints.
		local hit = workspace:Raycast(point + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), rayParams)
		local y = (if hit then hit.Position.Y else point.Y) + ARROW_HEIGHT
		used += 1
		nodes[used].Parent.Position = Vector3.new(point.X, y, point.Z)
	end

	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local segment = b - a
		local length = segment.Magnitude
		if length > 0.001 then
			local direction = segment / length
			while nextMark <= travelled + length and used < TRAIL_NODES do
				placeNode(a + direction * (nextMark - travelled))
				nextMark += spacing
			end
		end
		travelled += length
	end
	-- Always finish ON the objective, so the last arrow points at the thing
	-- rather than stopping a spacing short of it.
	if used < TRAIL_NODES and used > 0 then
		placeNode(points[#points])
	end

	for i = 1, #legs do
		legs[i].Enabled = i < used
	end
	legCount = math.max(0, used - 1)
end

local function requestRoute(from: Vector3, to: Vector3)
	if routeBusy then
		return
	end
	local now = os.clock()
	local moved = (from - routeFrom).Magnitude > ROUTE_MOVED or (to - routeTo).Magnitude > 3
	if now - routeAt < ROUTE_EVERY and not moved then
		return
	end
	routeAt = now
	routeFrom, routeTo = from, to
	routeBusy = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2.6,
			AgentHeight = 5.5,
			AgentCanJump = false,
			WaypointSpacing = 6,
		})
		local ok = pcall(function()
			path:ComputeAsync(from, to)
		end)
		if alive and ok and path.Status == Enum.PathStatus.Success then
			local points: { Vector3 } = { from }
			for _, wp in path:GetWaypoints() do
				points[#points + 1] = wp.Position
			end
			routePoints = points
			layTrail(points)
		elseif alive then
			-- Honest failure: no trail rather than a wrong one.
			routePoints = {}
			hideTrail()
		end
		routeBusy = false
	end)
end

--==============================================================================
-- FINDING A REAL RENDERED HUD ELEMENT
--
-- By name, and nil if it is not on screen -- during streaming, or before the HUD
-- has built itself, the pointer simply does not appear.
--==============================================================================
local function hudSpeedLabel(): GuiObject?
	local cash = playerGui:FindFirstChild("SeedCash")
	local corner = cash and cash:FindFirstChild("Corner")
	local label = corner and corner:FindFirstChild("Speed")
	return if label and label:IsA("GuiObject") then label else nil
end

local function hotbarSlotFor(tool: Tool?): GuiObject?
	local loadout = playerGui:FindFirstChild("SeedLoadout")
	local hotbar = loadout and loadout:FindFirstChild("Hotbar")
	if not (hotbar and hotbar:IsA("GuiObject")) then
		return nil
	end
	-- On a phone the strip steps aside while the Bag is open; a pointer aimed
	-- at where it would be would point into the Bag.
	if not hotbar.Visible then
		return nil
	end
	if tool then
		local want = string.upper(tool.Name)
		for _, slot in hotbar:GetChildren() do
			if slot:IsA("GuiObject") and slot.Visible then
				for _, kid in slot:GetDescendants() do
					if kid:IsA("TextLabel") and string.upper(kid.Text) == want then
						return slot
					end
				end
			end
		end
	end
	return hotbar
end

--==============================================================================
-- ON SCREEN: every ancestor visible up to the PlayerGui, its gui enabled, and
-- a real size -- what "the target hidden, or with no rect on this screen"
-- means, and what a blocker has to cover.
--==============================================================================
local function shown(object: GuiObject?): boolean
	if object == nil then
		return false
	end
	local size = object.AbsoluteSize
	if size.X < 2 or size.Y < 2 then
		return false
	end
	local node: Instance? = object
	while node and node ~= playerGui do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return node == playerGui
end

-- A HUD button by its gui and its name, while it is on screen; else nil.
local function hudButton(guiName: string, name: string): GuiButton?
	local holder = playerGui:FindFirstChild(guiName)
	local found = if holder then holder:FindFirstChild(name) else nil
	if found and found:IsA("GuiButton") and shown(found) then
		return found
	end
	return nil
end

-- The pressable face of the hotbar slot holding `tool` (HotbarCard's
-- Slot<n>.Wrap.Face), or nil when the strip has no slot for it.
local function slotFaceFor(tool: Tool?): GuiButton?
	local slot = hotbarSlotFor(tool)
	if slot and slot.Name ~= "Hotbar" then
		local face = slot:FindFirstChild("Face", true)
		if face and face:IsA("GuiButton") then
			return face
		end
	end
	return nil
end

--==============================================================================
-- WHAT THE HAND POINTS AT, THIS PASS
--
-- `target` is the real element; `button` the one that takes the press (nil for
-- a label: SPEED); `key` names the target's spotlight (TutorialSpotlight.
-- Targets), nil where it is never dimmed for; `text` is written beside the hand
-- while no spotlight is up -- a lit target says its own words. refresh says it
-- again five times a second; the hand follows the target every frame.
--==============================================================================
type Aim = { target: GuiObject?, button: GuiButton?, key: string?, text: string }
local aim: Aim = { target = nil, button = nil, key = nil, text = "" }

local function pointAt(target: GuiObject?, text: string, key: string?, button: GuiButton?)
	aim.target = target
	aim.text = text
	aim.key = key
	aim.button = button
end

-- An element's rect in the spotlight gui's own pixels (THE POINTING HAND).
local function rectOf(object: GuiObject): Spot.Rect
	local origin = spotGui.AbsolutePosition
	local p, s = object.AbsolutePosition, object.AbsoluteSize
	return { x = p.X - origin.X, y = p.Y - origin.Y, w = s.X, h = s.Y }
end

--==============================================================================
-- MEASURE THE GLYPHS, NOT THE BOX
--
-- The HUD's Speed label is a 260px box holding about 110px of text, because it
-- has to fit "139.88T" as well as "620". Anchoring to the box put the pointer a
-- finger-width of empty space away from the number it was pointing at.
-- TextBounds is what is actually on screen.
--==============================================================================
local function targetRect(object: GuiObject): Spot.Rect
	local r = rectOf(object)
	if object:IsA("TextLabel") and object.TextBounds.X > 4 then
		local glyphs = math.min(r.w, object.TextBounds.X + 6 * UIKit.scaleOf(object))
		if object.TextXAlignment == Enum.TextXAlignment.Right then
			return { x = r.x + r.w - glyphs, y = r.y, w = glyphs, h = r.h }
		elseif object.TextXAlignment == Enum.TextXAlignment.Center then
			return { x = r.x + (r.w - glyphs) * 0.5, y = r.y, w = glyphs, h = r.h }
		end
		return { x = r.x, y = r.y, w = glyphs, h = r.h }
	end
	return r
end

--==============================================================================
-- THE SPOTLIGHT, LIVE
--
-- `lights` holds this step's Light per target (TutorialSpotlight.advance), made
-- new only when the STEP changes -- a respawn is not a new life. `lit*` is the
-- one on screen now, if any.
--==============================================================================
local lights: { [string]: Spot.Light } = {}
local lightsStep = ""
local litKey: string? = nil
local litTarget: GuiObject? = nil
local litButton: GuiButton? = nil
local litConnections: { RBXScriptConnection } = {}
local fading = false
-- When each of this step's targets was pressed, lit or not. A pressed button
-- has done its job and is not pointed at again in the step (the hand stays on
-- one only while it is still waiting to be pressed); and after OBBY, TELEPORT
-- waits out the teleport cooldown the two share before it is lit.
local pressedAt: { [string]: number } = {}

-- A controller's selection held on the lit button, and what had it before.
local selectedButton: GuiButton? = nil
local selectionBefore: GuiObject? = nil
local selectionSaved: { GuiObject? } = {}

local blockers: { TextButton } = {}
local candidates: { GuiObject } = {}
local lastScan = 0
local SCAN_EVERY = 0.5

-- Each lit button's own D-pad key (its words name it); and what closes the
-- SPEED spotlight, which lights a label and takes a tap anywhere.
local PAD_KEYS: { [string]: Enum.KeyCode } = {
	biomes = Enum.KeyCode.DPadLeft,
	obby = Enum.KeyCode.DPadRight,
	teleport = Enum.KeyCode.DPadUp,
}
local TAP_INPUTS: { [Enum.UserInputType]: boolean } = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}
local TAP_KEYS: { [Enum.KeyCode]: boolean } = {
	[Enum.KeyCode.ButtonA] = true,
	[Enum.KeyCode.ButtonB] = true,
	[Enum.KeyCode.ButtonX] = true,
	[Enum.KeyCode.ButtonY] = true,
}
-- Guis whose buttons are never blocked: this guide's own (Skip guide), its two
-- drawing layers, and Roblox's touch controls.
local NEVER_BLOCKED: { [string]: boolean } = {
	SeedBeginnerGuide = true,
	SeedGuideSpotlight = true,
	SeedGuideMarker = true,
	TouchGui = true,
}

local function anyAButtonDown(): boolean
	for _, pad in ipairs(UserInputService:GetConnectedGamepads()) do
		if UserInputService:IsGamepadButtonDown(pad, Enum.KeyCode.ButtonA) then
			return true
		end
	end
	return false
end

--==============================================================================
-- A CONTROLLER'S SELECTION, BY PADFOCUS'S RULES
--
-- Only with a controller in hand, and only once an A that may still be down is
-- let go. Trapped on the button -- each NextSelection points back at it -- so
-- the D-pad cannot walk it off, and marked GuideLit, so the button's own D-pad
-- key presses it as well (the engine's navigation takes the D-pad first while
-- something is selected). Handed back the moment the light ends: to what had
-- it, if that is still there to select, else to nobody. A push of the left
-- stick hands it back at once -- the stick is the character's, and movement is
-- never blocked.
--==============================================================================
local function takeSelection(button: GuiButton)
	if selectedButton == button then
		return
	end
	selectedButton = button
	local before = GuiService.SelectedObject
	selectionBefore = if before ~= button then before else nil
	selectionSaved = { button.NextSelectionUp, button.NextSelectionDown, button.NextSelectionLeft,
		button.NextSelectionRight }
	button.NextSelectionUp = button
	button.NextSelectionDown = button
	button.NextSelectionLeft = button
	button.NextSelectionRight = button
	button:SetAttribute(ATTR.GuideLit, true)
	GuiService.SelectedObject = button
end

local function releaseSelection()
	local button = selectedButton
	if not button then
		return
	end
	selectedButton = nil
	button.NextSelectionUp = selectionSaved[1]
	button.NextSelectionDown = selectionSaved[2]
	button.NextSelectionLeft = selectionSaved[3]
	button.NextSelectionRight = selectionSaved[4]
	table.clear(selectionSaved)
	button:SetAttribute(ATTR.GuideLit, nil)
	if GuiService.SelectedObject == button then
		local back = selectionBefore
		GuiService.SelectedObject = if back and PadInput.active() and back.Selectable and shown(back)
			then back
			else nil
	end
	selectionBefore = nil
end

--==============================================================================
-- THE BLOCKERS: ONE TRANSPARENT SINK OVER EVERY OTHER BUTTON
--
-- Gathered every SCAN_EVERY seconds while a dim shows (a prompt comes and goes
-- as the player walks) and laid over their buttons every frame. Never over the
-- lit button, its parts or what holds it; never over the guide's own guis or
-- Roblox's touch controls; nothing in a SurfaceGui, which is in the world.
--==============================================================================
local function blockerAt(i: number): TextButton
	local made = blockers[i]
	if made then
		return made
	end
	local b = Instance.new("TextButton")
	b.Name = "Blocker"
	b.Text = ""
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Selectable = false
	b.Active = true
	b.ZIndex = 1
	b.Visible = false
	b.Parent = blockerFolder
	blockers[i] = b
	return b
end

local function hideBlockers()
	for _, b in ipairs(blockers) do
		b.Visible = false
	end
end

local function rescan(litObject: GuiObject?)
	table.clear(candidates)
	for _, holder in ipairs(playerGui:GetChildren()) do
		if holder:IsA("ScreenGui") and holder.Enabled and not NEVER_BLOCKED[holder.Name] then
			for _, d in ipairs(holder:GetDescendants()) do
				if (d:IsA("GuiButton") or d:IsA("TextBox")) and d ~= litObject
					and not (litObject and (d:IsDescendantOf(litObject) or litObject:IsDescendantOf(d)))
					and d:FindFirstAncestorWhichIsA("SurfaceGui") == nil and shown(d) then
					table.insert(candidates, d)
				end
			end
		end
	end
	lastScan = os.clock()
end

local function placeBlockers(litRect: Spot.Rect?)
	local used = 0
	for _, object in ipairs(candidates) do
		if object.Parent and shown(object) then
			local r = rectOf(object)
			if not (litRect and Spot.overlaps(r, litRect)) then
				used += 1
				local b = blockerAt(used)
				b.Position = UDim2.fromOffset(r.x, r.y)
				b.Size = UDim2.fromOffset(r.w, r.h)
				b.Visible = true
			end
		end
	end
	for i = used + 1, #blockers do
		blockers[i].Visible = false
	end
end

--==============================================================================
-- THE FACTS THE NEVER LIST READS (TutorialSpotlight.blocked), into one table
-- filled in place: it is asked every frame while a dim shows.
--==============================================================================
local facts: Spot.Facts = {
	guide = false,
	alive = false,
	safe = false,
	carrying = false,
	chased = false,
	panel = false,
	notice = false,
	moment = false,
	target = false,
}

local function spotFacts(): Spot.Facts
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	facts.guide = banner.Visible and words.Visible and not hidden and not confirmSkip
	facts.alive = humanoid ~= nil and humanoid.Health > 0 and root ~= nil
	facts.safe = player:GetAttribute(ATTR.InSafeZone) == true
	facts.carrying = type(player:GetAttribute(ATTR.CarryingSpecies)) == "string"
	facts.chased = (tonumber(player:GetAttribute(ATTR.PursuedBy)) or 0) > 0
		or (tonumber(player:GetAttribute(ATTR.WakingBy)) or 0) > 0
	facts.panel = PadInput.panelOpen() or RewardMoments.busy(player, ATTR.OpenPanel)
	facts.notice = Notice.showing() > 0
	facts.moment = party.Visible
	facts.target = shown(aim.target)
	return facts
end

--==============================================================================
-- ONE LIGHT'S LIFE: on, pressed, dropped, faded
--==============================================================================
-- The light is over: the dim, the ring and the blockers gone, the selection
-- handed back, the guide's gui back at its own order. The hand stays.
local function endLight()
	for _, c in ipairs(litConnections) do
		c:Disconnect()
	end
	table.clear(litConnections)
	releaseSelection()
	hole.Visible = false
	ring.Visible = false
	shade.Transparency = 1 - Spot.Dim
	ringStroke.Transparency = 0
	ringStroke.Thickness = Spot.Ring.Thickness
	hideBlockers()
	table.clear(candidates)
	litKey, litTarget, litButton = nil, nil, nil
	fading = false
	gui.DisplayOrder = GUIDE_ORDER
end

-- The step's target `key` was pressed -- lit or not -- so its spotlight is
-- spent, and one that is up lifts the instant it is.
local function press(key: string)
	pressedAt[key] = os.clock()
	local light = lights[key]
	if not light then
		light = Spot.newLight()
		lights[key] = light
	end
	light.phase = "spent"
	if litKey == key then
		endLight()
	end
end

local function startLight(key: string)
	local target, button = aim.target, aim.button
	litKey, litTarget, litButton = key, target, button
	fading = false
	gui.DisplayOrder = SPOT_ORDER + 1
	shade.Transparency = 1 - Spot.Dim
	ringStroke.Transparency = 0
	hole.Visible = true
	ring.Visible = true
	rescan(button or target)
	if button then
		table.insert(litConnections, button.Activated:Connect(function()
			press(key)
		end))
	end
	local padKey = PAD_KEYS[key]
	table.insert(litConnections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if litKey ~= key then
			return
		end
		if key == "speed" then
			if TAP_INPUTS[input.UserInputType] or TAP_KEYS[input.KeyCode] then
				press(key)
			end
		elseif padKey and input.KeyCode == padKey then
			press(key)
		end
	end))
	table.insert(litConnections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 and input.Position.Magnitude > 0.5 then
			local held = selectedButton
			if held and GuiService.SelectedObject == held then
				GuiService.SelectedObject = nil
			end
		end
	end))
	if button and PadInput.active() then
		task.spawn(function()
			local waited = 0
			while anyAButtonDown() and waited < 1 do
				waited += task.wait()
			end
			if litKey == key and litButton == button and not fading then
				takeSelection(button)
			end
		end)
	end
end

-- Unpressed for FadeAfter: the blockers and the selection go at once, the dim
-- fades, and the hand stays until the step moves on.
local function fadeLight()
	fading = true
	hideBlockers()
	table.clear(candidates)
	releaseSelection()
	local info = TweenInfo.new(Spot.FadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(shade, info, { Transparency = 1 }):Play()
	local out = TweenService:Create(ringStroke, info, { Transparency = 1 })
	local key = litKey
	out.Completed:Once(function()
		if litKey == key and fading then
			endLight()
		end
	end)
	out:Play()
end

-- Every button the hand has aimed at, heard from then on: a press counts whether
-- or not its spotlight was up at the time (only while it is still the target).
local hooked: { [GuiButton]: string } = setmetatable({}, { __mode = "k" }) :: any

-- Five times a second, after refresh has said what the hand points at.
local function spotTick()
	local key = aim.key
	local aimed = aim.button
	if aimed and key and hooked[aimed] == nil then
		hooked[aimed] = key
		table.insert(connections, aimed.Activated:Connect(function()
			if aim.button == aimed then
				press(hooked[aimed])
			end
		end))
	end
	-- What the step points at has moved on -- the pod equipped, OBBY done, the
	-- step finished, the guide hidden: a light that was up ends where it stands.
	if litKey and (litKey ~= key or aim.button ~= litButton) then
		local light = lights[litKey :: string]
		if light then
			light.phase = "spent"
		end
		endLight()
	end
	if not key then
		return
	end
	local light = lights[key]
	if not light then
		light = Spot.newLight()
		lights[key] = light
	end
	local event = Spot.advance(light, Spot.blocked(spotFacts()), false, os.clock())
	if event == "show" then
		startLight(key)
	elseif event == "drop" or event == "lift" then
		endLight()
	elseif event == "fade" then
		fadeLight()
	end
end

--==============================================================================
-- DRAWING THE HANDS
--
-- The hand's place is worked out when what it points at could have moved --
-- every frame while a spotlight shows (the window follows its button frame by
-- frame), five times a second otherwise -- and only TAPPED every frame.
--==============================================================================
local function measurer(): (string, number) -> Vector2
	local lastText, lastSize, last = "", -1, Vector2.zero
	return function(text: string, size: number): Vector2
		if text ~= lastText or size ~= lastSize then
			lastText, lastSize = text, size
			last = TextService:GetTextSize(text, size, Enum.Font.LuckiestGuy, Vector2.new(4000, 400))
		end
		return last
	end
end
local measureWords, measureKey, measureWorld = measurer(), measurer(), measurer()

local placed: Spot.Hand? = nil

--==============================================================================
-- THE BANNER MAKES ROOM (2026-10-08)
--
-- Under a button in the top row the hand points up, as drawn -- and on a
-- desktop the guide's own banner stands right there, under that row. So while
-- the hand or its words would stand on the banner, the guide's words step down
-- below them, Skip guide with them, and come back when the hand moves on. On a
-- phone the words stand in the left column and never meet it. `wordsShift`
-- (declared with the words, above) is in the guide gui's own units.
--==============================================================================
local function makeRoom(h: Spot.Hand?, at: Spot.Rect?)
	local shift = 0
	if h and not guide and banner.Visible then
		local k = UIKit.scaleOf(gui)
		local b = rectOf(banner)
		local top = b.y - wordsShift * k
		local unshifted: Spot.Rect = { x = b.x, y = top, w = b.w, h = b.h }
		local foot = -math.huge
		for _, r in ipairs({ h.rect, h.tapped, at }) do
			if r and Spot.overlaps(r, unshifted) then
				foot = math.max(foot, r.y + r.h)
			end
		end
		if foot > top then
			shift = math.ceil((foot + 4 - top) / k)
		end
	end
	if shift ~= wordsShift then
		wordsShift = shift
		words.Position = UDim2.fromOffset(0, shift)
		publishReach()
	end
end

local function hideHand()
	placed = nil
	hand.Visible = false
	handWords.Visible = false
	handKey.Visible = false
	makeRoom(nil, nil)
end

local function placeHand()
	local target = aim.target
	if not (target and shown(target)) then
		hideHand()
		return
	end
	local k = UIKit.scaleOf(gui)
	local lit = litKey ~= nil and not fading and litTarget == target
	-- Lit: the window stops short of a neighbouring button rather than light it.
	local others: { Spot.Rect }? = nil
	if lit and #candidates > 0 then
		local list: { Spot.Rect } = {}
		for _, o in ipairs(candidates) do
			if shown(o) then
				table.insert(list, rectOf(o))
			end
		end
		others = list
	end
	local window = Spot.window(targetRect(target), others)
	local view = spotGui.AbsoluteSize
	local screen: Spot.Rect = { x = 0, y = 0, w = view.X, h = view.Y }
	-- The window first: it lands on its button whatever the hand can do.
	if lit then
		hole.Position = UDim2.fromOffset(window.x, window.y)
		hole.Size = UDim2.fromOffset(window.w, window.h)
		ring.Position = hole.Position
		ring.Size = hole.Size
		shade.Thickness = math.max(view.X, view.Y) * 1.5
	end
	local size = Spot.Hand.Size * tutorialScale * k
	-- Garden and the Bag (2026-10-09: at a phone's left edge, over the cash block
	-- the hand points at for SPEED): the hand and its words keep off them where
	-- they can (TutorialSpotlight.handFor). Never the target itself.
	local avoid: { Spot.Rect } = {}
	local layer = playerGui:FindFirstChild("SeedRail")
	for _, name in ipairs({ "GardenButton", "BagButton" }) do
		local b = layer and layer:FindFirstChild(name, true)
		if b and b:IsA("GuiObject") and b ~= target and shown(b) then
			table.insert(avoid, rectOf(b))
		end
	end
	local h = Spot.handFor(window, screen, size, avoid)
	if not h then
		hideHand()
		return
	end
	placed = h
	hand.Size = UDim2.fromOffset(size, size)
	hand.Rotation = h.rotation

	local spec = if lit then Spot.Targets[litKey :: string] else nil
	local text = if spec then spec.words else aim.text
	local keyText = if spec and spec.key and PadInput.active() then spec.key :: string else ""
	local wordsAt: Spot.Rect? = nil
	if text == "" then
		handWords.Visible = false
		handKey.Visible = false
	else
		local wordSize = math.floor(Spot.Words.Size * tutorialScale * k + 0.5)
		local keySize = math.floor(Spot.Words.KeySize * tutorialScale * k + 0.5)
		local a = measureWords(text, wordSize)
		local b = if keyText ~= "" then measureKey(keyText, keySize) else Vector2.zero
		local edge = math.ceil(6 * k)
		local w = math.max(a.X, b.X) + edge
		local tall = a.Y + edge + (if keyText ~= "" then b.Y + 2 else 0)
		local at = Spot.wordsFor(h, window, screen, w, tall, avoid)
		wordsAt = at
		-- Read from the hand outward: left-aligned to its right, right-aligned to
		-- its left, centred over or under it.
		local align = if at.x >= h.rect.x + h.rect.w then Enum.TextXAlignment.Left
			elseif at.x + at.w <= h.rect.x then Enum.TextXAlignment.Right
			else Enum.TextXAlignment.Center
		handWords.TextSize = wordSize
		handWords.Text = text
		handWords.TextXAlignment = align
		handWords.Position = UDim2.fromOffset(at.x, at.y)
		handWords.Size = UDim2.fromOffset(w, a.Y + edge)
		handWords.Visible = true
		if keyText ~= "" then
			handKey.TextSize = keySize
			handKey.Text = keyText
			handKey.TextXAlignment = align
			handKey.Position = UDim2.fromOffset(at.x, at.y + a.Y + edge - 2)
			handKey.Size = UDim2.fromOffset(w, b.Y + 4)
			handKey.Visible = true
		else
			handKey.Visible = false
		end
	end
	makeRoom(h, wordsAt)
end

-- 0 at rest, 1 at the top of a tap, once every Hand.Period seconds.
local function tapAt(clock: number): number
	local t = (clock % Spot.Hand.Period) / Spot.Hand.Period
	return (1 - math.cos(t * math.pi * 2)) * 0.5
end

local function drawWorld(clock: number)
	local point = worldPoint
	local camera = workspace.CurrentCamera
	if not (point and camera) then
		worldHand.Visible = false
		worldWords.Visible = false
		return
	end
	local v = camera:WorldToViewportPoint(point)
	local view = camera.ViewportSize
	if v.Z <= 0.1 then
		worldHand.Visible = false
		worldWords.Visible = false
		return
	end
	local k = UIKit.scaleOf(gui)
	local px = WorldHand.Studs * view.Y / (2 * v.Z * math.tan(math.rad(camera.FieldOfView) * 0.5))
	local size = math.clamp(px, WorldHand.Least * k, WorldHand.Most * k)
	-- A tap carries it as far as WorldHand.Bob studs is on a hand WorldHand.Studs
	-- tall, in the gui's pixels: toward the target, whichever way it points.
	local bob = size * WorldHand.Bob / WorldHand.Studs
	if os.clock() - worldHudAt > 1 then
		measureWorldHud()
	end
	-- The guide's own words over it too, where they stand this frame.
	local hud = worldHud
	local origin = markGui.AbsolutePosition
	for _, object in ipairs({ banner, skip, resume }) do
		if shown(object) then
			if hud == worldHud then
				hud = table.clone(worldHud)
			end
			local p, s = object.AbsolutePosition, object.AbsoluteSize
			table.insert(hud, { x = p.X - origin.X, y = p.Y - origin.Y, w = s.X, h = s.Y })
		end
	end
	local mark = markGui.AbsoluteSize
	local screen: Spot.Rect = { x = 0, y = 0, w = mark.X, h = mark.Y }
	-- Its fingertip ON the projected point, pointing down -- or, where the HUD
	-- would cover it, at the point from the nearest clear place.
	local h = Spot.worldHand(Vector2.new(v.X, v.Y), screen, size, bob, hud)
	local tap = tapAt(clock)
	local cx = h.rect.x + h.rect.w * 0.5 + h.push.X * bob * tap
	local cy = h.rect.y + h.rect.h * 0.5 + h.push.Y * bob * tap
	worldHand.Size = UDim2.fromOffset(size, size)
	worldHand.Rotation = h.rotation
	worldHand.Position = UDim2.fromOffset(cx, cy)
	local onScreen = cx > -size and cx < view.X + size and cy > -size and cy < view.Y + size
	worldHand.Visible = onScreen
	if onScreen and worldText ~= "" then
		local ws = math.floor(20 * tutorialScale * k + 0.5)
		local m = measureWorld(worldText, ws)
		local w, tall = m.X + 8, m.Y + 6
		-- Beside the hand, never over the point, the hand or the HUD where a side
		-- allows (TutorialSpotlight.wordsFor), read from the hand outward.
		local at = Spot.wordsFor(h, { x = v.X - 2, y = v.Y - 2, w = 4, h = 4 }, screen, w, tall, hud)
		worldWords.TextSize = ws
		worldWords.Text = worldText
		worldWords.TextXAlignment = if at.x >= h.rect.x + h.rect.w then Enum.TextXAlignment.Left
			elseif at.x + at.w <= h.rect.x then Enum.TextXAlignment.Right
			else Enum.TextXAlignment.Center
		worldWords.Size = UDim2.fromOffset(w, tall)
		worldWords.Position = UDim2.fromOffset(at.x, at.y)
		worldWords.Visible = true
	else
		worldWords.Visible = false
	end
end

local warnedDraw = false
local function drawFrame(clock: number)
	if litKey and not fading then
		-- DROPPED AT ONCE when a NEVER comes true, not at the next tick.
		if Spot.blocked(spotFacts()) ~= nil then
			local light = lights[litKey :: string]
			if light then
				light.phase = "spent"
			end
			endLight()
		else
			if clock - lastScan >= SCAN_EVERY then
				rescan(litButton or litTarget)
			end
			placeHand()
			local own = litButton or litTarget
			placeBlockers(if own then rectOf(own) else nil)
			local p = tapAt(clock * Spot.Hand.Period / Spot.Ring.Period)
			ringStroke.Thickness = Spot.Ring.Thickness * (1 + 0.6 * p)
			ringStroke.Transparency = 0.35 * (1 - p)
		end
	end
	local h = placed
	if h then
		local bob = Spot.Hand.Bob * (h.size / Spot.Hand.Size) * tapAt(clock)
		hand.Position = UDim2.fromOffset(h.rect.x + h.rect.w * 0.5 + h.push.X * bob,
			h.rect.y + h.rect.h * 0.5 + h.push.Y * bob)
		hand.Visible = true
	end
	drawWorld(clock)
end

--==============================================================================
-- CLEARING UP
--
-- Called on every step change and every reason the guide stops pointing at
-- something: death, respawn, skip, completion and teardown all land here.
--==============================================================================
local function clearWorld()
	hideTrail()
	routePoints = {}
	routeAt = 0
	routeFrom = Vector3.new(1e6, 1e6, 1e6)
	highlight.Enabled = false
	highlight.Adornee = nil
	handOver(nil)
	pointAt(nil, "")
end

--==============================================================================
-- THE CELEBRATION, ONCE
--==============================================================================
local function confetti()
	local colours = { GOLD, CREAM, Color3.fromRGB(120, 255, 140), SPEED_BLUE }
	for i = 1, 14 do
		local bit = Instance.new("Frame")
		bit.BackgroundColor3 = colours[(i % #colours) + 1]
		bit.BorderSizePixel = 0
		bit.AnchorPoint = Vector2.new(.5, .5)
		bit.Position = UDim2.new(.5, 0, .5, 0)
		bit.Size = UDim2.fromOffset(10, 10)
		bit.Rotation = i * 26
		bit.ZIndex = 7
		bit.Parent = party
		UIKit.corner(bit, 2)
		local angle = math.rad(i * (360 / 14))
		local dx, dy = math.cos(angle) * 260, math.sin(angle) * 150 - 40
		TweenService:Create(bit, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(.5, dx, .5, dy),
			Rotation = bit.Rotation + 180,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(4, 4),
		}):Play()
		task.delay(1.3, function()
			bit:Destroy()
		end)
	end
end

local function celebrate()
	if celebrated then
		return
	end
	celebrated = true
	party.Visible = true
	-- Every step of the pop is a fraction of `tutorialScale`: 1, or a phone's
	-- smaller size (placeBanner).
	local full = tutorialScale
	partyScale.Scale = 0.2 * full
	-- Overshoot then settle: Back/Out is the pop, and it is a tween rather than
	-- a per-frame loop so it costs nothing after it finishes.
	TweenService:Create(partyScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = full }):Play()
	confetti()
	if SoundKit.has("RevealLegendary") then
		SoundKit.play("RevealLegendary")
	end
	task.delay(3.4, function()
		if not alive then
			return
		end
		local out = TweenService:Create(partyScale,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.1 * full })
		out:Play()
		out.Completed:Wait()
		party.Visible = false
	end)
end

--==============================================================================
-- SERVER STATE
--==============================================================================
local function receive(state: any)
	if type(state) ~= "table" or type(state.Done) ~= "table" then
		return
	end
	local had = progress
	local before = if had then (select(1, Data.Current(had))) else nil
	-- The first loop, train through hatch, before this packet (nil: the first).
	local loopBefore: boolean? = if had then Data.FirstLoopDone(had) else nil
	progress = state :: Data.Progress
	local now = select(1, Data.Current(progress :: Data.Progress))
	local finished = now > #Data.Steps
	local loopDone = Data.FirstLoopDone(progress :: Data.Progress)
	if loopBefore == false and loopDone and not state.Skipped then
		-- THE FIRST HATCH, crossed THIS SESSION: the congratulations, as they
		-- always were -- the guide's step 7, the travel lesson, comes after them
		-- (2026-10-08). A player who joins past the hatch takes the branch below
		-- and gets no fanfare for old news.
		--======================================================================
		-- AFTER THE HATCH'S OWN REVEAL, NOT BEFORE IT (2026-09-29)
		--
		-- A hatch shows its plant three seconds after it happens, where the pod
		-- stood (HatchRoll): the plant's Tool says until when. Congratulations
		-- for a plant nobody has seen yet would be early, so they wait for the
		-- plant to have come up. With no roll running there is nothing to wait
		-- for.
		--======================================================================
		local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
		local shownAt = HatchRoll.pendingUntil(player)
		if shownAt then
			local wait = math.max(shownAt - workspace:GetServerTimeNow(), 0)
				+ Config.Plant.Hatch.Reveal.Seconds
			task.delay(wait, function()
				if alive then
					celebrate()
				end
			end)
		else
			celebrate()
		end
	elseif loopBefore == nil and loopDone then
		celebrated = true
	end
	if before and before <= #Data.Steps and finished then
		-- The whole guide finished THIS SESSION -- the travel lesson was its last
		-- step. The hint that follows is optional, brief, and never places
		-- anything: the plant from the first hatch, if it is still in the Bag.
		clearWorld()
		if not state.Skipped then
			hintUntil = os.clock() + 45
		end
	elseif not before and finished then
		hidden = true
	end
end

local function receiveProfile(profile: any)
	if type(profile) == "table" then
		if type(profile.Speed) == "number" then
			speedScore = profile.Speed
		end
		receive(profile.Tutorial)
	end
end

table.insert(connections, (remotes:WaitForChild(Config.Remotes.ProfileUpdated) :: RemoteEvent)
	.OnClientEvent:Connect(receiveProfile))
table.insert(connections, (remotes:WaitForChild(Config.Remotes.ProfileReady) :: RemoteEvent)
	.OnClientEvent:Connect(function(ok: any, profile: any)
		if ok == true then
			receiveProfile(profile)
		end
	end))
table.insert(connections, channel.OnClientEvent:Connect(function(action: any, state: any)
	if action == Data.Action then
		receive(state)
	end
end))
table.insert(connections, skip.Activated:Connect(function()
	if confirmSkip then
		channel:FireServer(Data.Action, "skip")
		confirmSkip = false
		clearWorld()
	else
		confirmSkip = true
	end
end))
table.insert(connections, resume.Activated:Connect(function()
	if progress and progress.Skipped then
		channel:FireServer(Data.Action, "resume")
	end
	hidden = false
	confirmSkip = false
end))

--==============================================================================
-- ONE PASS OF THE STATE MACHINE
--==============================================================================
local lastStep = ""

local function refresh()
	local state = progress
	if not state then
		return
	end
	-- Every pass says again what the two hands point at; nothing carries over.
	pointAt(nil, "")
	handOver(nil)
	local index = select(1, Data.Current(state))
	local complete = index > #Data.Steps

	local menu = player:GetAttribute(ATTR.OpenPanel)
	local obstructed = type(menu) == "string" and menu ~= ""
	local biomeGui = playerGui:FindFirstChild("SeedBiomeGuide")
	local biomeBanner = biomeGui and biomeGui:FindFirstChildWhichIsA("Frame")
	if biomeBanner and biomeBanner.Visible then
		obstructed = true
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local live = root and root:IsA("BasePart") and humanoid and humanoid.Health > 0

	local showing = not hidden and not state.Skipped and not obstructed and not complete
	banner.Visible = showing
	skip.Visible = showing and not complete
	skip.Text = if confirmSkip then "Tap again to skip" else "Skip guide"
	resume.Visible = (state.Skipped or hidden) and not obstructed and not complete

	--== the optional post-tutorial nudge ====================================
	if complete then
		clearWorld()
		local hatchling = toolOf(true)
		if hatchling and os.clock() < hintUntil and not obstructed then
			banner.Visible = true
			instruction.Text = "Plant it to earn cash!"
			subline.Text = "Equip it, then tap your soil."
			counter.Text = ""
			local plot = myPlot()
			local soil = plot and plot:FindFirstChild(PLOT.PlanterName)
			if plot and soil and soil:IsA("BasePart") and live then
				local spot = freeSpot(plot, soil, (root :: BasePart).Position)
				if spot then
					handOver(spot + Vector3.new(0, SOIL_TIP, 0))
				end
			end
			pointAt(hotbarSlotFor(hatchling), "This one")
		end
		return
	end

	if not showing then
		clearWorld()
		return
	end

	local step = Data.Steps[index]
	if step.Id ~= lastStep then
		-- Every step change starts from nothing on screen.
		clearWorld()
		lastStep = step.Id
	end
	if step.Id ~= lightsStep then
		-- A new step: each of its spotlights gets its one life (a respawn, which
		-- clears lastStep above, is not a new step).
		lightsStep = step.Id
		table.clear(lights)
		table.clear(pressedAt)
	end

	instruction.Text = step.Title
	subline.Text = ""
	counter.Text = "STEP " .. index .. " / " .. #Data.Steps
	if confirmSkip then
		instruction.Text = "Skip the guide?"
		subline.Text = "Your finished steps stay saved."
		clearWorld()
		return
	end
	if not live then
		instruction.Text = step.Title
		subline.Text = "Your progress is safe -- back in a moment."
		clearWorld()
		return
	end
	local here = (root :: BasePart).Position

	local plot = myPlot()
	if not plot then
		subline.Text = "Waiting for your plot..."
		clearWorld()
		return
	end
	local soil = plot:FindFirstChild(PLOT.PlanterName)
	local id = step.Id

	--== 1 and 2: the mill, then the number =================================
	if id == "train" or id == "speed" then
		local belt = myBelt(plot)
		if not belt then
			subline.Text = "Looking for your treadmill..."
			clearWorld()
			return
		end
		local stand = beltStand(belt)
		highlight.Adornee = belt
		highlight.Enabled = true
		-- The hand over the belt -- in front of the gate on plots 1-5, beside it
		-- on plot 6: myBelt finds whichever this plot has.
		handOver(stand + Vector3.new(0, BELT_TIP, 0))
		if id == "speed" then
			-- Point at the REAL speed readout and count toward the target --
			-- after its one spotlight, "YOUR SPEED · GET 400", which a tap
			-- anywhere closes (it never stops the run).
			--==============================================================
			-- The CURRENT value uses the HUD's own compactor, so it reads the
			-- same way the number it is pointing at does. The TARGET is written
			-- out in full (Data.SpeedTargetText): compact() would turn a target
			-- of 1000 into "1K", and "620 / 1K" is a worse goal to read than
			-- "620 / 1,000" -- the same words the step title just said.
			--==============================================================
			pointAt(hudSpeedLabel(), Config.compact(speedScore) .. " / " .. Data.SpeedTargetText .. " SPEED", "speed")
			subline.Text = "Keep running on your mill."
		end
		-- THE STARTER POD (FirstMinute, 2026-10-08): while the pod the game
		-- planted for a new player is still growing, the training steps say so.
		-- The server sets StarterHatchAt for exactly that long.
		if player:GetAttribute(Config.Attributes.StarterHatchAt) ~= nil then
			subline.Text = FirstMinute.GrowingWords
		end
		if (here - stand).Magnitude > 12 then
			requestRoute(here, stand)
		else
			hideTrail()
		end
		return
	end

	--== 3: a real, available Greenhollow pod ================================
	if id == "steal" then
		--======================================================================
		-- WHEN THERE IS NOTHING TO TAKE, SAY SO AND SAY WHEN
		--
		-- Greenhollow is ONE nest of FIVE pods and a taken slot does NOT regrow
		-- during the day -- the 22-second regrow was removed on purpose, because
		-- a nest that refills itself is a nest with no scarcity in it. Only dawn
		-- restocks. On a busy server a new player can therefore reach this step
		-- and find the biome genuinely stripped, with up to a full day to wait.
		--
		-- That is a normal state of the game, not an error, so the guide has to
		-- have an answer for it: what happened, when it clears, and something
		-- worth doing until then. Standing in an empty biome reading "Heading to
		-- Greenhollow..." while walking to a place with no pods in it is the
		-- worst version of every one of those.
		--
		-- Training is the right thing to suggest. It is the only faucet for
		-- Speed, and Speed is exactly what decides whether the theft this step is
		-- waiting for actually gets home.
		--======================================================================
		local function dawnIn(): number?
			local endsAt = tonumber(workspace:GetAttribute(ATTR.WorldPhaseEndsAt))
			if not endsAt then
				return nil
			end
			local left = endsAt - workspace:GetServerTimeNow()
			-- At night the next phase change IS dawn. In the day it is dusk, and
			-- the restock lands a whole night after that.
			if workspace:GetAttribute(ATTR.WorldPhase) ~= "Night" then
				left += Config.WorldCycle.NightSeconds
			end
			return math.max(0, left)
		end

		local function waitAtTheMill(headline: string)
			instruction.Text = headline
			local left = dawnIn()
			subline.Text = if left
				then string.format("Pods return at dawn in %ds -- train while you wait!", math.ceil(left))
				else "Pods return at dawn -- train while you wait!"
			local belt = myBelt(plot)
			if belt then
				local stand = beltStand(belt)
				highlight.Adornee = belt
				highlight.Enabled = true
				handOver(stand + Vector3.new(0, BELT_TIP, 0))
				if (here - stand).Magnitude > 12 then
					requestRoute(here, stand)
				else
					hideTrail()
				end
			else
				clearWorld()
			end
		end

		if workspace:GetAttribute(ATTR.WorldPhase) == "Night" then
			waitAtTheMill("The nests are closed for the night!")
			return
		end
		--==================================================================
		-- BIOMES, LIT ONCE (2026-10-08): its teleport lands at the Greenhollow
		-- entrance, where the arrows to the nest take over -- and walking there
		-- is just as good. Only while the guide is sending them to Greenhollow:
		-- never at night or to a stripped nest, which send them to the mill.
		-- From the Safe Zone only, where the button stands at all.
		--==================================================================
		local function biomesHand()
			-- Pressed once, it has done its job: from the entrance (still the Safe
			-- Zone) the arrows take over, and the hand does not ask again.
			if pressedAt.biomes then
				return
			end
			local biomes = hudButton("SeedBiomesButton", "TeleportToBiomes")
			if biomes then
				pointAt(biomes, "TAP BIOMES", "biomes", biomes)
			end
		end
		--==================================================================
		-- THE ONE WITH THEIR NAME ON IT COMES FIRST
		--
		-- A beginner who reaches this step gets a pod reserved for them standing
		-- just outside the public ring (TutorialPodService), and it is the only
		-- one on the road that CANNOT have been taken out from under them while
		-- they ran. So it wins outright, no matter what is nearer.
		--
		-- The same attribute rules OTHER people's reservations out entirely.
		-- Walking somebody to a pod the server will refuse them is worse than
		-- walking them to nothing: nothing at least says "picked clean" and
		-- offers the mill.
		--==================================================================
		local best: Model? = nil
		local bestPos: Vector3? = nil
		local bestDist = math.huge
		local mineFound = false
		for _, m in CollectionService:GetTagged(Config.Tags.SeedPod) do
			local species = SeedData.Get(m:GetAttribute("SpeciesId"))
			local owner = tonumber(m:GetAttribute("ReservedFor"))
			if species and species.Biome == "greenhollow" and m:IsDescendantOf(workspace)
				and not CollectionService:HasTag(m, Config.Tags.Planted)
				and (owner == nil or owner == player.UserId)
				and m:FindFirstChildWhichIsA("ProximityPrompt", true) then
				local point = if m:IsA("Model") then m:GetPivot().Position else nil
				if point then
					local d = (point - here).Magnitude
					local mine = owner == player.UserId
					-- A second reservation cannot exist, so the first one found is
					-- final and nothing after it may displace it.
					if mine and not mineFound then
						best, bestPos, bestDist, mineFound = m :: Model, point, d, true
					elseif not mineFound and d < bestDist then
						best, bestPos, bestDist = m :: Model, point, d
					end
				end
			end
		end
		if not (best and bestPos) then
			--==================================================================
			-- EMPTY, OR JUST NOT LOADED YET? THE ANSWER IS WHERE THEY STANDING
			--
			-- Streaming can take the pods out of a distant player's world, and
			-- telling somebody stood in the safe field that the nest is stripped
			-- would often be a lie. So distance decides: from far away, walk
			-- them to the biome and retarget the moment a pod appears -- from
			-- inside it, with nothing found, the nest really is empty.
			--==================================================================
			local nestFar = math.abs(here.Z + Config.Map.FieldFront) < 90
			if nestFar then
				subline.Text = "Heading to Greenhollow..."
				highlight.Enabled = false
				biomesHand()
				requestRoute(here, Vector3.new(0, Config.Map.GroundY, -Config.Map.FieldFront - 60))
			else
				waitAtTheMill("Greenhollow is picked clean!")
			end
			return
		end
		highlight.Adornee = best
		highlight.Enabled = true
		handOver(bestPos + Vector3.new(0, POD_TIP, 0))
		biomesHand()
		requestRoute(here, bestPos)
		return
	end

	--== 4: home, through the real banking boundary ==========================
	if id == "bank" then
		local carrying = type(player:GetAttribute(ATTR.CarryingSpecies)) == "string"
		if carrying then
			-- No dim here: true to the letter, TeleportHome refuses a raided pod
			-- (CARRYING_POD), and the button stands only in the Safe Zone anyway.
			subline.Text = "Run back! Teleport won't work while you carry a pod."
		else
			subline.Text = if toolOf(false) then "Head to your soil." else "Go and take another pod."
		end
		-- Aim at the player's own plot spawn: it is inside the field, past the
		-- red line, so the route crosses the boundary that does the banking.
		local goal: Vector3? = nil
		for _, m in plot:GetDescendants() do
			if m:IsA("BasePart") and CollectionService:HasTag(m, Config.Tags.PlotSpawn) then
				goal = m.Position + Vector3.new(0, 2, 0)
				break
			end
		end
		goal = goal or (plot:GetPivot().Position + Vector3.new(0, 2, 0))
		handOver(goal + Vector3.new(0, SPAWN_TIP, 0))
		requestRoute(here, goal)
		return
	end

	--== 6: the plant on your own soil (2026-10-09: by hand only when the hatch
	-- found no free bed -- the hatch plants it otherwise) =====================
	if id == "place" then
		if not (soil and soil:IsA("BasePart")) then
			subline.Text = "Looking for your soil..."
			clearWorld()
			return
		end
		local plantTool = toolOf(true)
		if not plantTool then
			-- Never point at soil with nothing to put in it.
			if bagPodDue() then
				instruction.Text = "Hatch your first plant!"
				subline.Text = "Open your Bag when your pod is ready."
			elseif type(player:GetAttribute(ATTR.CarryingSpecies)) == "string" then
				instruction.Text = "Bring it to your plot!"
				subline.Text = "Cross the red line to bank it."
			else
				instruction.Text = "Take a pod!"
				subline.Text = "Grab a pod from Greenhollow."
			end
			clearWorld()
			return
		end
		local spot = freeSpot(plot, soil :: BasePart, here)
		if not spot then
			subline.Text = "Your plot is full -- lift a plant or upgrade to make room."
			clearWorld()
			return
		end
		highlight.Adornee = soil
		highlight.Enabled = true
		if not plantTool.Parent or plantTool.Parent ~= player.Character then
			-- Not in the hand yet: its hotbar slot, lit once -- "EQUIP YOUR PLANT".
			local face = slotFaceFor(plantTool)
			if face then
				pointAt(face, "EQUIP YOUR PLANT", "slot", face)
			else
				pointAt(hotbarSlotFor(plantTool), "EQUIP YOUR PLANT")
			end
		else
			-- In the hand: the hand over a free spot of soil.
			handOver(spot + Vector3.new(0, SOIL_TIP, 0))
		end
		if (here - spot).Magnitude > 14 then
			requestRoute(here, spot)
		else
			hideTrail()
		end
		return
	end

	--== 5: hatch it -- in the Bag since 2026-10-09; an old save's pod in the
	-- ground still hatches where it stands ===================================
	if id == "hatch" then
		local pod = podIn(plot)
		if pod then
			local point = pod:GetPivot().Position
			highlight.Adornee = pod
			highlight.Enabled = true
			local ready = tonumber(pod:GetAttribute("HatchAt"))
				or ((tonumber(pod:GetAttribute("PlantedAt")) or os.time())
					+ SeedData.GrowSeconds(pod:GetAttribute("Tier")))
			local left = math.max(0, math.ceil(ready - os.time()))
			if left > 0 then
				subline.Text = "Ready in " .. left .. "s"
			else
				subline.Text = "Hold the Hatch prompt."
			end
			-- The hand over the pod: "HOLD HATCH" once it can be.
			handOver(point + Vector3.new(0, POD_TIP, 0), if left > 0 then "READY IN " .. left .. "s" else "HOLD HATCH")
			if (here - point).Magnitude > 14 then
				requestRoute(here, point)
			else
				hideTrail()
			end
			return
		end
		local due = bagPodDue()
		if not due then
			instruction.Text = if type(player:GetAttribute(ATTR.CarryingSpecies)) == "string"
				then "Bring it to your plot!" else "Take a pod!"
			subline.Text = "Nothing is growing yet."
			clearWorld()
			return
		end
		clearWorld()
		local left = math.max(0, math.ceil(due - workspace:GetServerTimeNow()))
		subline.Text = if left > 0 then "Your pod is growing in your Bag: ready in " .. left .. "s"
			else "Open your Bag and hold HATCH."
		-- The Bag open: its HATCH ALL once a pod is ready. Shut: its door.
		local hatchAll = if left <= 0 then bagGuiButton("HatchAll") else nil
		if hatchAll then
			pointAt(hatchAll, "HOLD HATCH ALL", nil, hatchAll)
			return
		end
		local loadout = playerGui:FindFirstChild("SeedLoadout")
		local chip = if loadout then loadout:FindFirstChild("BagChip", true) else nil
		local chipFace = if chip then chip:FindFirstChild("Face") else nil
		local door = if chipFace and chipFace:IsA("GuiButton") and shown(chipFace) then chipFace
			else bagGuiButton("BagButton")
		pointAt(door, if left > 0 then "READY IN " .. left .. "s" else "OPEN YOUR BAG", nil, door)
		return
	end

	--== 7: the travel buttons (owner, 2026-10-08) ============================
	if id == "travel" then
		--======================================================================
		-- TWO SPOTLIGHTS IN A ROW: OBBY, then TELEPORT TO PLOT
		--
		-- a. OBBY, "TAP OBBY": to the Floating Garden's entrance -- unless OBBY is
		--    off, hidden or has no rect on this screen, when it is straight to b.
		-- b. TELEPORT TO PLOT, "TAP TO GO HOME" -- lit only once the teleport
		--    cooldown the two buttons share has run out since OBBY was pressed, so
		--    the press it asks for is never refused. The server records the step
		--    on that teleport's success (PlotService.TeleportHome), and nothing
		--    here claims it.
		-- Both stand only in the Safe Zone; outside it the words say so.
		--======================================================================
		local obby = hudButton("SeedObbyButton", "TeleportToObby")
		local home = hudButton("SeedPlotTeleport", "TeleportToPlot")
		local obbyLight = lights.obby
		local obbyDone = pressedAt.obby ~= nil or (obbyLight ~= nil and obbyLight.phase == "spent")
		if obby and not obbyDone then
			subline.Text = "OBBY takes you to the Floating Garden."
			pointAt(obby, "TAP OBBY", "obby", obby)
		elseif home then
			subline.Text = "TELEPORT TO PLOT takes you home."
			local pressed = pressedAt.obby
			local cooling = pressed ~= nil and os.clock() - pressed < PLOT.TeleportCooldownSeconds + COOL_MARGIN
			if not cooling then
				pointAt(home, "TAP TO GO HOME", "teleport", home)
			end
		else
			subline.Text = "OBBY and TELEPORT TO PLOT work from the Safe Zone."
		end
		return
	end
end

--==============================================================================
-- TWO LOOPS: STATE AT 5Hz, MOTION EVERY FRAME
--
-- The per-frame half reads a clock, taps the two hands and projects the world
-- one's point; while a spotlight shows it also follows the lit button and lays
-- the blockers, for at most FadeAfter seconds. It never searches the world or
-- rebuilds a path -- that is the 5Hz half's job, and even there the route is
-- throttled again on top.
--==============================================================================
local since = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since >= TICK then
		since = 0
		local ok, err = pcall(refresh)
		if not ok then
			warn("[Seed/TutorialUI] " .. tostring(err))
		end
		local lightOk, lightErr = pcall(spotTick)
		if not lightOk then
			warn("[Seed/TutorialUI] spotlight: " .. tostring(lightErr))
		end
		if not (litKey and not fading) then
			pcall(placeHand)
		end
	end
	-- The trail animates itself: the arrow texture scrolls from TextureSpeed, so
	-- there is deliberately nothing here for it.
	local drawn, drawErr = pcall(drawFrame, os.clock())
	if not drawn and not warnedDraw then
		warnedDraw = true
		warn("[Seed/TutorialUI] draw: " .. tostring(drawErr))
	end
end))

-- OBBY pressed, lit or not (the note ObbyButtonUI leaves for ObbyCamera): in the
-- travel step that is part a done, and TELEPORT waits out the shared cooldown.
table.insert(connections, player:GetAttributeChangedSignal(ObbyData.LocalAttributes.EntranceAsked):Connect(function()
	if lightsStep == "travel" then
		press("obby")
	end
end))

local function onCharacter()
	clearWorld()
	lastStep = ""
end
table.insert(connections, player.CharacterAdded:Connect(onCharacter))
table.insert(connections, player.CharacterRemoving:Connect(onCharacter))

gui.Destroying:Connect(function()
	alive = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	-- A light that was up hands the selection back and takes its blockers.
	endLight()
	-- The trail node pool lives under `world`, and the hands and the dim in
	-- their own guis: all of it has to be taken down by hand.
	world:Destroy()
	spotGui:Destroy()
	markGui:Destroy()
end)

task.spawn(function()
	while alive and not progress do
		channel:FireServer(Data.Action, "snapshot")
		task.wait(2)
	end
end)
