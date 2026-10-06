--!strict
-- Steal a Seed :: WalkModeUI
--
--==============================================================================
-- A SWITCH THAT SAYS WHETHER YOU ARE WALKING
--
-- A compact horizontal switch in the rail layer (the owner's reference,
-- 2026-10-04): the words WALK MODE: OFF over a slim light track, the thumb red
-- at its LEFT end -- and WALK MODE: ON with the thumb green at its RIGHT end.
-- Pressing anywhere on it asks the server; the server answers by changing an
-- attribute; this file draws the attribute.
--
-- IT IS NOT IN THE SETTINGS PANEL, and that is the whole design. This is used
-- mid-stride -- lining a plant up, reading a sign, walking beside somebody who is
-- slower than you -- and a control you have to open a modal to reach is a control
-- nobody uses while moving. The panel is for things you set once.
--
--==============================================================================
-- THE SERVER IS THE SWITCH. THIS IS THE LAMP.
--
-- The button sends a verb and a boolean on the GameEvent remote and then does
-- NOTHING to its own state: no optimistic flip, no local attribute write, no
-- guessing. CarryService validates the request, PlayerDataService writes the
-- profile and stamps the replicated attribute, and the switch follows that.
--
-- So a client that fakes the attribute changes its own words for one frame and
-- its own speed never, because the speed is computed on the other side. And a
-- refusal -- mid-respawn, no profile yet -- leaves the switch telling the truth
-- rather than showing ON over a player who is still sprinting.
--
--==============================================================================
-- WHERE IT SITS, AND WHAT IT MUST NOT COVER
--
-- HudLayout's `walk`. On a desktop: the left rail's fourth row, under Settings,
-- 130 x 46 -- the rail's own width, so the column reads as one column. Off a
-- desktop the switch is as wide as its words (HudLayout's WalkCompact), in a
-- small window left of EVENTS under the top row, 46 tall, so the whole switch
-- -- not just the thumb -- is a 44-px-plus target for a finger. On a phone
-- (2026-10-05) a see-through 128 x 28 row under OTHER PLANTS, under Shop in
-- the top-left corner, the owner's smaller switch, well clear of the stick.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- Only for ObbyData.onCourse: the switch is put away on the Floating Garden.
local ObbyData = require(Shared:WaitForChild("ObbyData"))
-- Only for reducedMotion: the thumb's slide is motion, and nothing else here is.
local StatusText = require(Shared:WaitForChild("StatusText"))

local RAIL = GameConfig.Rail
local WALK = GameConfig.WalkMode
local ATTR = GameConfig.Attributes
local LOOK = GameConfig.BagLook

local WHITE = Color3.fromRGB(255, 255, 255)
-- The track: a light groove, a little deeper at the top, with the rail's ink
-- line round it -- light on any ground, as the label's outline is.
local TRACK_TOP = Color3.fromRGB(210, 220, 212)
local TRACK_BOTTOM = Color3.fromRGB(250, 252, 248)
-- The two thumbs: the family's red (remove, close) and its green (go), each
-- with its darker foot and its own dark keyline.
local OFF_FACE = { LOOK.DangerTop, LOOK.DangerBottom, LOOK.DangerEdge }
local ON_FACE = { LOOK.ButtonTop, LOOK.ButtonBottom, LOOK.ButtonEdge }

-- The parts, in gui px: the words' line, the track under it, and a thumb a
-- little taller than the track so it reads as the thing that moves.
local LABEL_H = 18
local TRACK_H = 20
local THUMB = Vector2.new(26, 24)
local TRACK_Y = LABEL_H + 3 + (THUMB.Y - TRACK_H) / 2
-- The track's length: the desktop's wide row, and the narrower switch.
local TRACK_WIDE = 64
local TRACK_NARROW = 58
local SLIDE_SECONDS = 0.14
-- A PHONE'S ROW (the owner, 2026-10-05; HudLayout's switchInline and
-- Phone.Switch): see-through, under Shop in the top-left corner -- no plate,
-- the words outlined as every HUD word is -- the words inline at the row's
-- left, a small switch at its right, the state's word inside the track beside
-- the thumb. The whole row is the press.
local ROW = HudLayout.Config.Phone.Switch

--==============================================================================
-- RE-RUN SAFE
--
-- A LocalScript that is synced while the game is running gets a second copy, and
-- the first copy's Destroying handler is not guaranteed to run -- so the new copy
-- removes the old switch rather than trusting the old one to have tidied up.
--==============================================================================
local layer = UIKit.railLayer(playerGui)
local stale = layer:FindFirstChild("WalkModeSwitch")
if stale then
	stale:Destroy()
end

-- The whole switch is the button: an ImageButton with no image (no text pass),
-- transparent, so the words and the track stand on the world as the
-- reference's do. The rail's click and the family's press (UIKit.pressPop: a
-- small grow under the mouse, a sink under a press, still under Reduced
-- Effects) are on it; the controller's gold ring (PadFocus) is drawn round it.
local slab = Instance.new("ImageButton")
slab.Name = "WalkModeSwitch"
slab.AnchorPoint = Vector2.new(0.5, 0.5)
slab.Size = UDim2.fromOffset(RAIL.WideSize.X, 46)
slab.BackgroundTransparency = 1
slab.BorderSizePixel = 0
slab.Image = ""
slab.AutoButtonColor = false
slab.ZIndex = 5
slab.Parent = layer
UIKit.clicks(slab)
UIKit.pressPop(slab, 1.04, 0.95)

local label = UIKit.outlined(slab, "Label", 13, WHITE, 2)
local labelLine = label:FindFirstChildOfClass("UIStroke")
label.Position = UDim2.fromOffset(2, 0)
label.Size = UDim2.new(1, -4, 0, LABEL_H)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = WALK.Label .. ": " .. WALK.OffText
label.ZIndex = 7

--==============================================================================
-- THE THUMB IS THE STATE, AND IT IS THE PART THAT CANNOT BE DECORATIVE
--
-- Reduced Effects (and the device's reduced motion) take the slide away,
-- because that is motion. The thumb and the words are not decoration: they
-- are what says which way the switch is, so they change -- side, colour and
-- word -- under every setting. Never colour alone: the words say ON or OFF.
--==============================================================================
local track = Instance.new("Frame")
track.Name = "Track"
track.Size = UDim2.fromOffset(TRACK_WIDE, TRACK_H)
track.Position = UDim2.fromOffset(3, TRACK_Y)
track.BackgroundColor3 = WHITE
track.BorderSizePixel = 0
track.ZIndex = 6
track.Parent = slab
UIKit.corner(track, 8)
do
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(TRACK_TOP, TRACK_BOTTOM)
	shade.Parent = track
	local line = Instance.new("UIStroke")
	line.Color = RAIL.Outline
	line.Thickness = 2
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = track
end

local thumb = Instance.new("Frame")
thumb.Name = "Thumb"
thumb.AnchorPoint = Vector2.new(0, 0.5)
thumb.Size = UDim2.fromOffset(THUMB.X, THUMB.Y)
thumb.Position = UDim2.new(0, 0, 0.5, 0)
thumb.BackgroundColor3 = WHITE
thumb.BorderSizePixel = 0
thumb.ZIndex = 8
thumb.Parent = track
UIKit.corner(thumb, 7)
local thumbFace = Instance.new("UIGradient")
thumbFace.Rotation = 90
thumbFace.Parent = thumb
local thumbLine = Instance.new("UIStroke")
thumbLine.Thickness = 2
thumbLine.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
thumbLine.Parent = thumb
do
	-- The shine across its top, as the reference's thumb has.
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Position = UDim2.new(0.18, 0, 0, 3)
	shine.Size = UDim2.new(0.5, 0, 0, 4)
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.45
	shine.BorderSizePixel = 0
	shine.ZIndex = 9
	shine.Parent = thumb
	UIKit.corner(shine, 2)
end

-- ON or OFF in the compact row's track, on the side the thumb is not.
local stateWord = UIKit.outlined(track, "State", ROW.Word, WHITE, 1)
stateWord.Size = UDim2.new(0, ROW.Track.X - ROW.Thumb - 2, 1, 0)
stateWord.TextXAlignment = Enum.TextXAlignment.Center
stateWord.ZIndex = 7
stateWord.Visible = false

--==============================================================================
-- ONE SWITCH, EVERY LAYOUT
--
-- A desktop keeps the 130 x 46 row under Settings; off a desktop HudLayout
-- hands the narrower WalkCompact. Either way the words stand over the track on
-- one line -- WALK MODE: OFF, never broken over two -- and both lean to the
-- side the switch stands on: the left rail's left, the right edge's right. The
-- same slab, label, track and thumb are re-laid rather than rebuilt, so what
-- paint() gave them carries straight across a relayout.
--
-- The rail layer is shared and outlives this script, so the connection to it
-- is dropped when this switch is: a re-run's new switch brings its own.
--==============================================================================
local inlineRow = false
local paint: () -> ()

local function placeSwitch()
	if layer.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(layer))
	local r = layout.walk
	slab.Size = UDim2.fromOffset(r.w, r.h)
	slab.Position = HudLayout.place(r, slab.AnchorPoint, layout.safe)
	-- On a phone a compact row (`switchInline`, 2026-10-05), OTHER PLANTS' twin.
	local inline = layout.switchInline == true
	stateWord.Visible = inline
	if labelLine then
		-- A thinner outline on the row's smaller words, so their counters stay open.
		labelLine.Thickness = if inline then 1.5 else 2
	end
	if inline then
		label.TextSize = ROW.Label
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(ROW.PadLeft, 0)
		label.Size = UDim2.new(1, -(ROW.PadLeft + ROW.PadRight + 4 + ROW.Track.X), 1, 0)
		track.Size = UDim2.fromOffset(ROW.Track.X, ROW.Track.Y)
		track.AnchorPoint = Vector2.new(1, 0.5)
		track.Position = UDim2.new(1, -ROW.PadRight, 0.5, 0)
		thumb.Size = UDim2.fromOffset(ROW.Thumb, ROW.Thumb)
	else
		local wide = r.w >= RAIL.WideSize.X
		local right = r.x + r.w / 2 > layout.safe.X / 2
		label.TextSize = if wide then 13 else 12
		label.TextXAlignment = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(2, 0)
		label.Size = UDim2.new(1, -4, 0, LABEL_H)
		track.Size = UDim2.fromOffset(if wide then TRACK_WIDE else TRACK_NARROW, TRACK_H)
		track.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
		track.Position = if right then UDim2.new(1, -3, 0, TRACK_Y) else UDim2.fromOffset(3, TRACK_Y)
		thumb.Size = UDim2.fromOffset(THUMB.X, THUMB.Y)
	end
	if inline ~= inlineRow then
		inlineRow = inline
		if paint then
			paint()
		end
	end
end
local relayout = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeSwitch)
slab.Destroying:Once(function()
	relayout:Disconnect()
end)
placeSwitch()

--==============================================================================
-- WHAT THE SERVER SAYS, DRAWN
--
-- The thumb's two places are the track's two ends (UDim2 scale, so a relayout
-- that changes the track's length keeps the thumb at its end). It slides
-- between them in a seventh of a second -- or jumps, under reduced motion and
-- on the first paint, where there is nothing to slide from.
--==============================================================================
local slide: Tween? = nil
local painted = false
local paintedRow = false

function paint()
	local on = player:GetAttribute(ATTR.WalkMode) == true
	label.Text = WALK.Label .. ": " .. (if on then WALK.OnText else WALK.OffText)
	-- The compact row says the state in its switch, on the thumb's other side.
	if inlineRow then
		label.Text = WALK.Label
	end
	stateWord.Text = if on then WALK.OnText else WALK.OffText
	stateWord.AnchorPoint = Vector2.new(if on then 0 else 1, 0)
	stateWord.Position = if on then UDim2.fromOffset(2, 0) else UDim2.new(1, -2, 0, 0)
	local face = if on then ON_FACE else OFF_FACE
	thumbFace.Color = UIKit.footColours(face[1], face[2], face[3])
	thumbLine.Color = face[3]
	local thumbW = thumb.Size.X.Offset
	local goal = if on then UDim2.new(1, -thumbW, 0.5, 0) else UDim2.new(0, 0, 0.5, 0)
	if slide then
		slide:Cancel()
		slide = nil
	end
	-- A new shape of switch jumps, as the first paint does: nothing to slide from.
	local reshaped = paintedRow ~= inlineRow
	paintedRow = inlineRow
	if not painted or reshaped or StatusText.reducedMotion() then
		thumb.Position = goal
	elseif thumb.Position ~= goal then
		local tween = TweenService:Create(thumb,
			TweenInfo.new(SLIDE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = goal })
		slide = tween
		tween:Play()
	end
	painted = true
end

paint()
player:GetAttributeChangedSignal(ATTR.WalkMode):Connect(paint)

--==============================================================================
-- PUT AWAY ON THE FLOATING GARDEN ON A PHONE (2026-09-29), AND OUT OF AN OPEN
-- PANEL'S WAY OFF A DESKTOP (2026-10-04)
--
-- The course runs everybody at its own fixed speed -- "Weight and Walk Mode do
-- not apply up there" (CarryService) -- so the switch does nothing on it, and on
-- a phone it stood beside the way ahead doing that nothing. On a touch screen
-- (HudLayout's sidebars) it is hidden while the server says this player is on
-- the course and shown again the moment they are not. A desktop, a console and
-- a TV keep the switch where it always was, on the course too.
--
-- Off a desktop an open panel can be under the switch -- the Bag's panel takes
-- the whole width -- so it steps aside while OpenPanel names a panel, as EVENTS
-- and the phone's panel do, and comes back when the panel closes.
--
-- Only hidden, both: what the switch is SET to is the server's and is not
-- touched, so a player who walks onto the course in Walk Mode walks off it in
-- Walk Mode.
--==============================================================================
local function showSwitch()
	local phone, away = false, false
	if layer.AbsoluteSize.X > 0 then
		local layout = HudLayout.solve(HudLayout.measure(layer))
		phone = layout.sidebar == true
		away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil
	end
	slab.Visible = not (phone and ObbyData.onCourse(player)) and not away
end
player:GetAttributeChangedSignal(ObbyData.Attributes.Course):Connect(showSwitch)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(showSwitch)
local reshow = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(showSwitch)
slab.Destroying:Once(function()
	reshow:Disconnect()
end)
showSwitch()

--==============================================================================
-- THE PRESS
--
-- Sends the OPPOSITE of what the server currently says, which is the only state
-- worth toggling from: toggling from a local variable is how a refused request
-- leaves the client convinced it is in a state the server has never heard of.
--==============================================================================
local channel: RemoteEvent? = nil
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	end
end)

local lastSent = 0
slab.Activated:Connect(function()
	local rem = channel
	if not rem then
		return
	end
	--==========================================================================
	-- ONE REQUEST PER FIFTH OF A SECOND
	--
	-- A held finger on a touch screen fires Activated repeatedly, and every one of
	-- those is a profile write and an attribute replication. The server refuses a
	-- no-change write anyway; this is so it is not asked ten times.
	--==========================================================================
	local now = os.clock()
	if now - lastSent < 0.2 then
		return
	end
	lastSent = now
	rem:FireServer(WALK.Action, not (player:GetAttribute(ATTR.WalkMode) == true))
end)
