--!strict
-- Steal a Seed :: OtherPlantsUI
--
--==============================================================================
-- PERFORMANCE MODE: OFF / ON / ULTRA (2026-10-13, the owner: "insert a level 3
-- switch on performance mode, when turned level 3, owned plants will be hidden
-- too"; "tap cycles 3 steps"; "instead of word ultra in the switch, just make
-- an extra spark effect")
--
-- One press steps OFF, ON, ULTRA, then OFF again (PerformanceMode.nextLevel):
--   - OFF: the thumb red at the left, OFF beside it.
--   - ON: green in the middle, ON beside it.
--   - ULTRA: gold at the right with no word; little sparks twinkle in the thumb
--     and a gold aura rings it (THE SPARKS). Under reduced motion the sparks
--     stand still.
-- On a phone's row the thumb's place and colour say it alone: its 40-px track
-- has no room for a word beside a thumb in the middle. The words above say
-- PERFORMANCE MODE as before. Reaching ULTRA says once that the player's own
-- plants are hidden too, and still grow and earn.
--
--==============================================================================
-- PERFORMANCE MODE: ON / OFF (2026-10-11, the owner: this switch was OTHER
-- PLANTS, and became PERFORMANCE MODE with a lightning bolt)
--
-- ON is what OTHER PLANTS: OFF was -- other players' grown plants not drawn
-- here -- and Reduced FX on as well; OFF shows everything and gives Reduced FX
-- back to the player's own choice (Shared/PerformanceMode owns both). The one
-- local preference is read the other way round, so nobody's view changes on
-- the update: OFF, everything shown, is where every session starts. Below,
-- the switch as it was built for OTHER PLANTS; what changed for PERFORMANCE
-- MODE is at THE WORDS AND THE BOLT.
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
local PerformanceMode = require(Shared:WaitForChild("PerformanceMode"))
local Notice = require(Shared:WaitForChild("Notice"))

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
-- ULTRA (2026-10-13): a deep amber gold, so the bolt still reads on it.
local ULTRA_FACE = OTHERS.UltraFace
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
-- THE WORDS AND THE BOLT (2026-10-11): PERFORMANCE MODE is longer than OTHER
-- PLANTS, and the switch keeps its size and its place (HudLayout's `others`;
-- the phone's top row has no spare width). So the words are the name alone,
-- at the largest size that fits on one line -- 119 px at 12 in the rail's
-- 126, 110 at 11 in OthersCompact's 114 (LuckiestGuy, measured) -- and on a
-- phone's row two lines at its 10 px (73 x 20 in 73 x 28, as OTHER PLANTS
-- filled its 73). ON or OFF stands in the track beside the thumb, as the
-- phone's row always had it, and the lightning bolt (GameConfig.OtherPlants
-- .Icon, a colour emoji) rides on the thumb.
--==============================================================================
local NAME_WIDE = 12
local NAME_NARROW = 11
local WORD_SIZE = 10

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
label.Text = OTHERS.Label
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
-- The lightning bolt on the thumb: it slides with it.
local bolt = Instance.new("TextLabel")
bolt.Name = "Bolt"
bolt.BackgroundTransparency = 1
bolt.AnchorPoint = Vector2.new(0.5, 0.5)
bolt.Position = UDim2.fromScale(0.5, 0.5)
bolt.Size = UDim2.fromScale(1, 1)
bolt.Font = Enum.Font.LuckiestGuy
bolt.Text = OTHERS.Icon
bolt.TextSize = THUMB.Y - 8
bolt.ZIndex = 10
bolt.Parent = thumb

--==============================================================================
-- THE SPARKS (2026-10-13, ULTRA): little four-point stars inside the thumb,
-- twinkling one after another (looping tweens, nothing per frame), and a gold
-- aura 1 px round it -- all within the thumb's box and that 1 px plus its
-- line, so the switch's rect holds them (the track stands 3 px inside it).
-- Built once; shown only in ULTRA. Under reduced motion they stand still.
--==============================================================================
local aura = Instance.new("Frame")
aura.Name = "Aura"
aura.BackgroundTransparency = 1
aura.AnchorPoint = Vector2.new(0.5, 0.5)
aura.Position = UDim2.fromScale(0.5, 0.5)
aura.Size = UDim2.new(1, 2, 1, 2)
aura.ZIndex = 7
aura.Visible = false
aura.Parent = thumb
UIKit.corner(aura, 8)
local auraLine = Instance.new("UIStroke")
auraLine.Color = OTHERS.AuraColour
auraLine.Thickness = 1.5
auraLine.Transparency = 0.25
auraLine.Parent = aura

-- Where the stars stand in the thumb (shares of its box) -- round the bolt,
-- clear of the edges.
local SPARK_AT = { Vector2.new(0.22, 0.24), Vector2.new(0.8, 0.26), Vector2.new(0.24, 0.78), Vector2.new(0.78, 0.76) }
type Spark = { holder: Frame, scale: UIScale }
local sparks: { Spark } = {}
for i = 1, math.min(OTHERS.Sparks, #SPARK_AT) do
	local holder = Instance.new("Frame")
	holder.Name = "Spark"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(SPARK_AT[i].X, SPARK_AT[i].Y)
	holder.Size = UDim2.fromScale(0.3, 0.3)
	holder.ZIndex = 11
	holder.Visible = false
	holder.Parent = thumb
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = holder
	for _, size in ipairs({ UDim2.fromScale(0.26, 1), UDim2.fromScale(1, 0.26) }) do
		local arm = Instance.new("Frame")
		arm.Name = "Arm"
		arm.AnchorPoint = Vector2.new(0.5, 0.5)
		arm.Position = UDim2.fromScale(0.5, 0.5)
		arm.Size = size
		arm.BackgroundColor3 = OTHERS.SparkColour
		arm.BorderSizePixel = 0
		arm.ZIndex = 11
		arm.Parent = holder
		UIKit.corner(arm, 2)
	end
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	table.insert(sparks, { holder = holder, scale = scale })
end
local twinkles: { Tween } = {}

-- The sparks on or off; twinkling unless the player asked for reduced motion
-- THEMSELVES -- their own Reduced FX (PerformanceMode.ownReduced), never the one
-- Performance Mode itself turns on, or ULTRA's sparks would never move.
local function sparkle(on: boolean, still: boolean)
	for _, t in ipairs(twinkles) do
		t:Cancel()
	end
	table.clear(twinkles)
	aura.Visible = on
	for i, s in ipairs(sparks) do
		s.holder.Visible = on
		if on and not still then
			s.scale.Scale = 0
			local t = TweenService:Create(s.scale, TweenInfo.new(OTHERS.Twinkle, Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut, -1, true, (i - 1) * OTHERS.Stagger), { Scale = 1 })
			table.insert(twinkles, t)
			t:Play()
		else
			s.scale.Scale = OTHERS.StillScale
		end
	end
end

-- ON or OFF in the track, on the side the thumb is not -- in every layout
-- since PERFORMANCE MODE (the phone's row had it before).
local stateWord = UIKit.outlined(track, "State", ROW.Word, WHITE, 1)
stateWord.Size = UDim2.new(0, ROW.Track.X - ROW.Thumb - 2, 1, 0)
stateWord.TextXAlignment = Enum.TextXAlignment.Center
stateWord.ZIndex = 7

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
	if labelLine then
		-- A thinner outline on the row's smaller words, so their counters stay open.
		labelLine.Thickness = if inline then 1.5 else 2
	end
	if inline then
		label.TextSize = ROW.Label
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextWrapped = true
		label.Position = UDim2.fromOffset(ROW.PadLeft, 0)
		label.Size = UDim2.new(1, -(ROW.PadLeft + ROW.PadRight + 4 + ROW.Track.X), 1, 0)
		track.Size = UDim2.fromOffset(ROW.Track.X, ROW.Track.Y)
		track.AnchorPoint = Vector2.new(1, 0.5)
		track.Position = UDim2.new(1, -ROW.PadRight, 0.5, 0)
		thumb.Size = UDim2.fromOffset(ROW.Thumb, ROW.Thumb)
		stateWord.TextSize = ROW.Word
		stateWord.Size = UDim2.new(0, ROW.Track.X - ROW.Thumb - 2, 1, 0)
		bolt.TextSize = ROW.Thumb - 6
	else
		local wide = r.w >= RAIL.WideSize.X
		local right = r.x + r.w / 2 > layout.safe.X / 2
		label.TextSize = if wide then NAME_WIDE else NAME_NARROW
		label.TextXAlignment = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		label.TextWrapped = false
		label.Position = UDim2.fromOffset(2, 0)
		label.Size = UDim2.new(1, -4, 0, LABEL_H)
		local trackW = if wide then TRACK_WIDE else TRACK_NARROW
		track.Size = UDim2.fromOffset(trackW, TRACK_H)
		track.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
		track.Position = if right then UDim2.new(1, -3, 0, TRACK_Y) else UDim2.fromOffset(3, TRACK_Y)
		thumb.Size = UDim2.fromOffset(THUMB.X, THUMB.Y)
		stateWord.TextSize = WORD_SIZE
		stateWord.Size = UDim2.new(0, trackW - THUMB.X - 2, 1, 0)
		bolt.TextSize = THUMB.Y - 8
	end
	inlineRow = inline
	-- Every layout: the thumb's three places and the word's room follow the
	-- track (2026-10-13). A new shape of switch jumps (paint's `reshaped`).
	if paint then
		paint()
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

local sparkOn, sparkStill = false, false

function paint()
	-- THREE LEVELS (2026-10-13): OFF red at the left, ON green in the middle,
	-- ULTRA gold at the right with its sparks and no word.
	local level = PerformanceMode.level(player)
	label.Text = OTHERS.Label
	local trackW = track.Size.X.Offset
	local thumbW = thumb.Size.X.Offset
	-- The middle place leans a pixel left when it must, so ON fits beside it.
	local x = if level == "ultra" then trackW - thumbW elseif level == "on" then math.floor((trackW - thumbW - 1) / 2) else 0
	-- The word beside the thumb: OFF or ON where it fits (never a phone's row),
	-- never ULTRA.
	stateWord.Visible = not inlineRow and level ~= "ultra"
	if level == "on" then
		stateWord.Text = OTHERS.OnText
		stateWord.AnchorPoint = Vector2.new(0, 0)
		stateWord.Position = UDim2.fromOffset(x + thumbW + 1, 0)
		stateWord.Size = UDim2.new(0, math.max(0, trackW - x - thumbW - 2), 1, 0)
	else
		stateWord.Text = OTHERS.OffText
		stateWord.AnchorPoint = Vector2.new(1, 0)
		stateWord.Position = UDim2.new(1, -2, 0, 0)
		stateWord.Size = UDim2.new(0, math.max(0, trackW - thumbW - 2), 1, 0)
	end
	local face = if level == "ultra" then ULTRA_FACE elseif level == "on" then ON_FACE else OFF_FACE
	thumbFace.Color = UIKit.footColours(face[1], face[2], face[3])
	thumbLine.Color = face[3]
	-- The sparks follow the level, and Reduced Motion while it is ULTRA.
	local wantSpark, still = level == "ultra", PerformanceMode.ownReduced(player)
	if wantSpark ~= sparkOn or (wantSpark and still ~= sparkStill) then
		sparkle(wantSpark, still)
		sparkOn, sparkStill = wantSpark, still
	end
	local goal = UDim2.new(0, x, 0.5, 0)
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
-- ULTRA's own-plants preference (2026-10-13).
local repaintOwn = player:GetAttributeChangedSignal(OTHERS.HideOwnAttribute):Connect(paint)
slab.Destroying:Once(function()
	repaint:Disconnect()
	repaintOwn:Disconnect()
	sparkle(false, true)
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
-- THE PRESS: the next level -- OFF, ON, ULTRA, then OFF (2026-10-13). A click,
-- a tap, or the controller's selection (the slab is an ordinary selectable
-- button, so the UI's own navigation and PadFocus's ring reach it). A held
-- finger fires Activated over and over; one step per fifth of a second.
-- Reaching ULTRA says so once.
--==============================================================================
local lastFlip = 0
slab.Activated:Connect(function()
	local now = os.clock()
	if now - lastFlip < 0.2 then
		return
	end
	lastFlip = now
	local nextLevel = PerformanceMode.nextLevel(PerformanceMode.level(player))
	PerformanceMode.setLevel(player, nextLevel)
	if nextLevel == "ultra" then
		Notice.post({ kind = "info", title = OTHERS.UltraNotice.Title, detail = OTHERS.UltraNotice.Detail,
			key = "performance-ultra" })
	end
end)

--==============================================================================
-- THE HIDING ITSELF: started here, once per session (PlantVisibility.start is
-- re-run safe and keeps one watcher however often this script runs).
--==============================================================================
PlantVisibility.start(player)
