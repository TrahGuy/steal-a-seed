--!strict
-- Steal a Seed :: OtherPlantsUI
--
--==============================================================================
-- OTHER PLANTS: ON / OFF (2026-10-05, the owner's brief)
--
-- A display preference, on this screen only: ON shows every garden; OFF hides
-- the other players' GROWN plants in their plots, with their labels, income
-- pops and effects (PlantVisibility does the hiding). This player's own plants,
-- every pod still in the ground, carried and loose pods, players, guardians,
-- plots and the map stay as they are. Nothing is asked of the server and
-- nothing there changes: income, ownership, collisions, pickups and saves are
-- exactly what they were for everybody, this player included.
--
--==============================================================================
-- WALK MODE'S SWITCH, NOT WALK MODE'S AUTHORITY
--
-- The same compact horizontal switch, number for number (WalkModeUI): the words
-- OTHER PLANTS: ON over a slim light track, the thumb green at its RIGHT end --
-- and OTHER PLANTS: OFF with the thumb red at its LEFT end. The whole switch is
-- the button, 46 tall, so a finger has the full target; the rail's click and
-- the family's press; the slide under a seventh of a second, a jump under
-- reduced motion. What it does NOT share is Walk Mode's remote and its server:
-- a display preference is this client's to keep. The press flips one LOCAL
-- attribute on the player (GameConfig.OtherPlants.Attribute) -- the one value
-- every reader of the preference reads -- and the switch draws that attribute.
-- On the player, so it outlives every respawn; local, so it is never sent,
-- never saved and never seen by anybody else. Default ON.
--
--==============================================================================
-- WHERE IT SITS: HudLayout's `others`. A desktop's rail row under WALK MODE,
-- 130 x 46; in compact as wide as its longer label (OthersCompact), at the
-- right edge under EVENTS; on a phone (2026-10-05) a see-through 128 x 28 row
-- under Shop, over WALK MODE's. HudLayout says why for each, and keeps it 8 px
-- clear of everything, the thumbstick and the jump button included.
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
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local PlantVisibility = require(Shared:WaitForChild("PlantVisibility"))

local RAIL = GameConfig.Rail
local OTHERS = GameConfig.OtherPlants
local ATTR = GameConfig.Attributes
local LOOK = GameConfig.BagLook

-- WalkModeUI's, unchanged.
local WHITE = Color3.fromRGB(255, 255, 255)
local TRACK_TOP = Color3.fromRGB(210, 220, 212)
local TRACK_BOTTOM = Color3.fromRGB(250, 252, 248)
local OFF_FACE = { LOOK.DangerTop, LOOK.DangerBottom, LOOK.DangerEdge }
local ON_FACE = { LOOK.ButtonTop, LOOK.ButtonBottom, LOOK.ButtonEdge }
local LABEL_H = 18
local TRACK_H = 20
local THUMB = Vector2.new(26, 24)
local TRACK_Y = LABEL_H + 3 + (THUMB.Y - TRACK_H) / 2
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
-- RE-RUN SAFE: the new copy removes the old switch (WalkModeUI says why).
--==============================================================================
local layer = UIKit.railLayer(playerGui)
local stale = layer:FindFirstChild("OtherPlantsSwitch")
if stale then
	stale:Destroy()
end

local slab = Instance.new("ImageButton")
slab.Name = "OtherPlantsSwitch"
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
label.Text = OTHERS.Label .. ": " .. OTHERS.OnText
label.ZIndex = 7

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
-- ONE SWITCH, EVERY LAYOUT (WalkModeUI's rules): the words over the track on
-- one line, both leaning to the side the switch stands on -- and on a phone the
-- compact row (`switchInline`).
--==============================================================================
local inlineRow = false
local paint: () -> ()

local function placeSwitch()
	if layer.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(layer))
	local r = layout.others
	slab.Size = UDim2.fromOffset(r.w, r.h)
	slab.Position = HudLayout.place(r, slab.AnchorPoint, layout.safe)
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
-- A trap's REMOVE row re-solves the layout; the spot is chosen so it never
-- moves for it, but it is asked again all the same.
local relayoutRow = player:GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(placeSwitch)
slab.Destroying:Once(function()
	relayout:Disconnect()
	relayoutRow:Disconnect()
end)
placeSwitch()

--==============================================================================
-- THE PREFERENCE, DRAWN: green at the right for ON, red at the left for OFF,
-- and the words say which -- never colour alone. The slide is the only motion.
--==============================================================================
local slide: Tween? = nil
local painted = false
local paintedRow = false

function paint()
	local on = PlantVisibility.showOthers(player)
	label.Text = OTHERS.Label .. ": " .. (if on then OTHERS.OnText else OTHERS.OffText)
	-- The compact row says the state in its switch, on the thumb's other side.
	if inlineRow then
		label.Text = OTHERS.Label
	end
	stateWord.Text = if on then OTHERS.OnText else OTHERS.OffText
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
local repaint = player:GetAttributeChangedSignal(OTHERS.Attribute):Connect(paint)
slab.Destroying:Once(function()
	repaint:Disconnect()
end)

--==============================================================================
-- PUT AWAY WHERE WALK MODE IS (WalkModeUI): on a phone while on the Floating
-- Garden, where there is no garden to show or hide, and off a desktop while a
-- panel is open -- so it never floats over a menu. Only hidden: the preference
-- is not touched.
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
local onCourse = player:GetAttributeChangedSignal(ObbyData.Attributes.Course):Connect(showSwitch)
local onPanel = player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(showSwitch)
local reshow = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(showSwitch)
slab.Destroying:Once(function()
	onCourse:Disconnect()
	onPanel:Disconnect()
	reshow:Disconnect()
end)
showSwitch()

--==============================================================================
-- THE PRESS: the opposite of what the attribute says now. A click, a tap, or
-- the controller's selection (the slab is an ordinary selectable button, so
-- the UI's own navigation and PadFocus's ring reach it). A held finger fires
-- Activated over and over; one flip per fifth of a second.
--==============================================================================
local lastFlip = 0
slab.Activated:Connect(function()
	local now = os.clock()
	if now - lastFlip < 0.2 then
		return
	end
	lastFlip = now
	PlantVisibility.setShowOthers(player, not PlantVisibility.showOthers(player))
end)

--==============================================================================
-- THE HIDING ITSELF: started here, once per session (PlantVisibility.start is
-- re-run safe and keeps one watcher however often this script runs).
--==============================================================================
PlantVisibility.start(player)
