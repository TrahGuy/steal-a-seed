--!strict
-- Steal a Seed :: SettingsUI
--
-- The gear on the left rail and the panel behind it: music, sound effects and
-- reduced effects. The button sits under Shop; the panel opens in the middle of
-- the screen like every other panel.
--
--==============================================================================
-- EVERY CONTROL MOVES SOMETHING THAT ALREADY EXISTED
--
--   MUSIC        SoundKit's Music bus, through SoundKit.setLevel -- never the
--                group's Volume directly. The join fade and the chase duck move
--                that bus as well, and a level written past them would last
--                exactly until the next chase ended and faded the bed back up.
--   SOUND FX     the other three buses together: Chase, UI and World. That is
--                everything but the bed, the server's one-shots and the RUN
--                alarm included, since both ride those buses now.
--   REDUCED FX   `SeedAfterimageQuality` on the local Player -- the attribute
--                SpeedFX, PlantAura and UIKit's hover pops already read. ON
--                writes "Off": no speed ribbon, no plant sparks, no UI motion.
--                OFF puts back whatever was there before, or the device default.
--                Never "High": no reader knows that word, so writing it would
--                leave every effect switched off until a rejoin.
--
-- NO REMOTE AND NO SAVE. All three are this client's own business, and none is
-- kept -- a rejoin starts from the defaults. Keeping them would need a profile
-- field and a remote, and this panel adds neither.
--
--==============================================================================
-- 44 PIXELS, EVERY TARGET
--
-- Roblox's minimum and the close button's rule. A slider's hit area is the whole
-- 44-pixel band although its track is twelve, and each ON/OFF is a 64 x 44
-- button with a smaller plate inside it -- the way UIKit.modal builds its close.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel
local ATTR = GameConfig.Attributes
local QUALITY = GameConfig.Afterimage.QualityAttribute
local PANEL_NAME = "Settings"

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local CREAM = Color3.fromRGB(242, 238, 206)
local MUTED = Color3.fromRGB(198, 176, 152)

--==============================================================================
-- ON IS THE SHOP'S GREEN; OFF IS THE PANEL'S OWN SOIL
--
-- Green already means "this one is on" on this HUD -- an equipped bat, the tab
-- you are on -- so ON borrows the shop slab's pair rather than inventing another
-- green. OFF is the panel's soil lifted a step: unlit, and not a second colour
-- arguing with the first. Each gets a darker foot, like every other button here.
--==============================================================================
local ON_FACE = RAIL.ShopFace
local ON_SHADE = RAIL.ShopShade
local ON_FOOT = Color3.fromRGB(30, 92, 30)
local OFF_FACE = Color3.fromRGB(112, 90, 74)
local OFF_SHADE = Color3.fromRGB(72, 54, 44)
local OFF_FOOT = Color3.fromRGB(44, 32, 26)
local TRACK = Color3.fromRGB(24, 16, 12)

local TARGET = 44
local TOGGLE_W = 64
local PLATE_H = 38
local ROW_H = 52
local ROW_GAP = 8
local ROW_PAD = 10
local TRACK_H = 12
local KNOB = 24
local NUDGE = 0.1

local MAX_WIDTH = 440
local MAX_HEIGHT = 320

-- One slider, three buses: everything that is not the music bed.
local FX_BUSES = { "Chase", "UI", "World" }

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSettings")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSettings"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON
--
-- Bare, like Garden and the Bag: the gear is the button. LEFT rail, third row,
-- straight under Shop. The right rail's third row is where the Bag's equipment
-- column starts, and nothing else on the HUD lives under the left pair. The same
-- 50 x 50 footprint as the other bare two, so the target is the size a plate
-- would have been.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "SettingsButton",
	icon = RAIL.SettingsIcon,
	wide = false,
	bare = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset + (RAIL.WideSize.Y + RAIL.Gap) * 2)

--==============================================================================
-- A GEAR OUT OF FRAMES, FOR THE DAY THE UPLOAD DOES NOT LOAD
--
-- A bare button whose image failed is a transparent square: still pressable, and
-- invisible. So the id is asked for once, and if it does not come back both
-- gears -- the rail's and the title bar's -- are drawn instead: four bars
-- crossed at 45 degrees for eight teeth, a steel body and a brass hub. Six
-- frames, no glyph, nothing that can be moderated away.
--==============================================================================
local STEEL = Color3.fromRGB(150, 172, 190)
local STEEL_DARK = Color3.fromRGB(88, 106, 124)
local BRASS = Color3.fromRGB(214, 170, 72)

local function disc(parent: Instance, name: string, scale: number, colour: Color3,
	zIndex: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(scale, scale)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.ZIndex = zIndex
	f.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = f
	UIKit.stroke(f, BLACK, 2)
	return f
end

local function drawGear(parent: GuiObject, size: number, zIndex: number): Frame
	local box = Instance.new("Frame")
	box.Name = "GearDrawn"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundTransparency = 1
	box.ZIndex = zIndex
	box.Parent = parent
	for i = 0, 3 do
		local teeth = Instance.new("Frame")
		teeth.Name = "Teeth"
		teeth.AnchorPoint = Vector2.new(0.5, 0.5)
		teeth.Position = UDim2.fromScale(0.5, 0.5)
		teeth.Size = UDim2.fromScale(0.26, 0.96)
		teeth.Rotation = i * 45
		teeth.BackgroundColor3 = STEEL_DARK
		teeth.BorderSizePixel = 0
		teeth.ZIndex = zIndex
		teeth.Parent = box
		UIKit.corner(teeth, math.max(2, math.floor(size * 0.06)))
		UIKit.stroke(teeth, BLACK, 2)
	end
	disc(box, "Body", 0.7, STEEL, zIndex + 1)
	disc(box, "Hub", 0.32, BRASS, zIndex + 2)
	return box
end

--==============================================================================
-- THE PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "SETTINGS",
	maxWidth = MAX_WIDTH,
	maxHeight = MAX_HEIGHT,
})

local titleBar = modal.title.Parent :: Frame
local titleGear = Instance.new("ImageLabel")
titleGear.Name = "Gear"
titleGear.AnchorPoint = Vector2.new(0.5, 0.5)
titleGear.Position = UDim2.new(0, 24, 0.5, 0)
titleGear.Size = UDim2.fromOffset(32, 32)
titleGear.BackgroundTransparency = 1
titleGear.Image = RAIL.SettingsIcon
titleGear.ScaleType = Enum.ScaleType.Fit
titleGear.ZIndex = 3
titleGear.Parent = titleBar
modal.title.Position = UDim2.new(0, 46, 0.5, 0)
modal.title.Size = UDim2.new(1, -98, 1, 0)

task.spawn(function()
	local fetched = Enum.AssetFetchStatus.Success
	local ok = pcall(function()
		ContentProvider:PreloadAsync({ RAIL.SettingsIcon },
			function(_: string, status: Enum.AssetFetchStatus)
				fetched = status
			end)
	end)
	if ok and fetched == Enum.AssetFetchStatus.Success then
		return
	end
	warn(string.format("[Seed/SettingsUI] The settings icon did not load (%s); "
		.. "drawing the gear instead.", tostring(fetched)))
	local railIcon = button:FindFirstChild("Icon")
	if railIcon and railIcon:IsA("GuiObject") then
		railIcon.Visible = false
	end
	drawGear(button, RAIL.IconBare - 8, 3)
	titleGear.Image = ""
	drawGear(titleGear, 30, 3)
end)

--==============================================================================
-- THREE ROWS, NO SCROLL
--
-- Not a ScrollingFrame, on purpose: a ScrollingFrame takes a touch drag for
-- itself once it has moved a few pixels, and two of these rows are things a
-- thumb drags sideways. Three 52-pixel rows fit a landscape phone with room to
-- spare, so there is nothing to scroll to anyway.
--==============================================================================
local rowsFrame = Instance.new("Frame")
rowsFrame.Name = "Rows"
rowsFrame.Size = UDim2.fromScale(1, 1)
rowsFrame.BackgroundTransparency = 1
rowsFrame.ZIndex = 3
rowsFrame.Parent = modal.body

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, ROW_GAP)
layout.Parent = rowsFrame

type Row = {
	frame: Frame,
	title: TextLabel,
	detail: TextLabel,
}

-- Scaled down, never up, so a narrow phone shrinks a word instead of clipping it.
local function fitText(label: TextLabel, maxSize: number)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = 9
	limit.Parent = label
end

local function makeRow(order: number, name: string, titleText: string): Row
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, ROW_H)
	frame.BackgroundColor3 = PANEL.Shade
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.ZIndex = 3
	frame.Parent = rowsFrame
	UIKit.corner(frame, 12)
	UIKit.stroke(frame, BLACK, 2, 0.35)

	local title = UIKit.outlined(frame, "Title", 19, WHITE, 2)
	title.AnchorPoint = Vector2.new(0, 1)
	title.Position = UDim2.new(0, ROW_PAD, 0.5, 3)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = titleText
	title.ZIndex = 4
	fitText(title, 19)

	local detail = UIKit.outlined(frame, "Detail", 14, CREAM, 1.5)
	detail.Position = UDim2.new(0, ROW_PAD, 0.5, 4)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.ZIndex = 4
	fitText(detail, 14)

	return { frame = frame, title = title, detail = detail }
end

--==============================================================================
-- ON / OFF
--
-- Lit face, darker foot, shade bar, black keyline: the close button's four parts,
-- so this panel speaks the one button language the rest of the HUD does. The
-- press sinks it under a thumb and lifts it under a mouse, like a Bag card.
--==============================================================================
type Toggle = {
	button: TextButton,
	fill: UIGradient,
	foot: Frame,
	label: TextLabel,
}

local function makeToggle(row: Row): Toggle
	local b = Instance.new("TextButton")
	b.Name = "Toggle"
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -4, 0.5, 0)
	b.Size = UDim2.fromOffset(TOGGLE_W, TARGET)
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = 5
	b.Parent = row.frame
	UIKit.clicks(b)

	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.new(1, -8, 0, PLATE_H)
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.ZIndex = 6
	plate.Parent = b
	UIKit.corner(plate, 10)
	UIKit.stroke(plate, PANEL.Outline, RAIL.OutlineThickness)
	local fill = UIKit.gradient(plate, ON_FACE, ON_SHADE)

	local foot = Instance.new("Frame")
	foot.Name = "Shade"
	foot.AnchorPoint = Vector2.new(0.5, 1)
	foot.Position = UDim2.new(0.5, 0, 1, 0)
	foot.Size = UDim2.new(1, 0, 0, 5)
	foot.BackgroundColor3 = ON_FOOT
	foot.BorderSizePixel = 0
	foot.Active = false
	foot.ZIndex = 7
	foot.Parent = plate
	UIKit.corner(foot, 10)

	local label = UIKit.outlined(plate, "Label", 18, WHITE, 2.5)
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromOffset(0, -2)
	label.ZIndex = 8

	local scale = Instance.new("UIScale")
	scale.Parent = b
	UIKit.cardPop(b, scale, { hoverScale = 1.06, pressScale = 0.94, sound = false })

	return { button = b, fill = fill, foot = foot, label = label }
end

local function paintToggle(t: Toggle, on: boolean)
	t.fill.Color = if on then ColorSequence.new(ON_FACE, ON_SHADE)
		else ColorSequence.new(OFF_FACE, OFF_SHADE)
	t.foot.BackgroundColor3 = if on then ON_FOOT else OFF_FOOT
	t.label.Text = if on then "ON" else "OFF"
	t.label.TextColor3 = if on then WHITE else MUTED
end

--==============================================================================
-- THE SLIDER
--
-- The hit area is a transparent button the full 44 pixels tall; the twelve-pixel
-- track, its fill and the knob sit inside it and take no input of their own. A
-- press anywhere on the band jumps the level there and a drag follows the pointer
-- or the thumb until it lets go, wherever it goes -- the release is heard on
-- UserInputService, not on the band, so a drag that leaves the row still ends.
--
-- A GAMEPAD NUDGES. While the band is the selected object, left and right move it
-- a tenth at a time, and its left and right neighbours are itself, so the press
-- does not also walk the selection off sideways. Heard on UserInputService, not
-- bound through ContextActionService: measured in Play, with a GUI object
-- selected the engine's own navigation takes the arrow first and a bound action
-- never saw it.
--==============================================================================
type Slider = {
	hit: TextButton,
	track: Frame,
	fill: Frame,
	tint: UIGradient,
	knob: Frame,
	value: number,
	set: (number) -> (),
}

type Drag = {
	slider: Slider,
	input: InputObject,
}

local sliders: { Slider } = {}
local dragging: Drag? = nil

local function valueAt(s: Slider, x: number): number
	local left = s.track.AbsolutePosition.X
	local width = math.max(1, s.track.AbsoluteSize.X)
	return math.clamp(math.round((x - left) / width * 100) / 100, 0, 1)
end

local function makeSlider(row: Row, set: (number) -> ()): Slider
	local hit = Instance.new("TextButton")
	hit.Name = "Slider"
	hit.AnchorPoint = Vector2.new(0, 0.5)
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.ZIndex = 5
	hit.Parent = row.frame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.new(0, KNOB / 2, 0.5, 0)
	track.Size = UDim2.new(1, -KNOB, 0, TRACK_H)
	track.BackgroundColor3 = TRACK
	track.BorderSizePixel = 0
	track.Active = false
	track.ZIndex = 6
	track.Parent = hit
	UIKit.corner(track, TRACK_H / 2)
	UIKit.stroke(track, BLACK, 2)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Active = false
	fill.ZIndex = 7
	fill.Parent = track
	UIKit.corner(fill, TRACK_H / 2)
	local tint = UIKit.gradient(fill, ON_FACE, ON_SHADE)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(KNOB, KNOB)
	knob.BackgroundColor3 = CREAM
	knob.BorderSizePixel = 0
	knob.Active = false
	knob.ZIndex = 8
	knob.Parent = hit
	UIKit.corner(knob, KNOB / 2)
	UIKit.stroke(knob, BLACK, 2.5)

	local s: Slider = {
		hit = hit,
		track = track,
		fill = fill,
		tint = tint,
		knob = knob,
		value = 1,
		set = set,
	}
	table.insert(sliders, s)

	hit.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			dragging = { slider = s, input = input }
			s.set(valueAt(s, input.Position.X))
		end
	end)

	hit.NextSelectionLeft = hit
	hit.NextSelectionRight = hit

	return s
end

UserInputService.InputChanged:Connect(function(input: InputObject)
	local drag = dragging
	if not drag then
		return
	end
	-- A touch reports its movement on the same InputObject that began it; a
	-- mouse reports it on MouseMovement objects of its own.
	if input == drag.input or (input.UserInputType == Enum.UserInputType.MouseMovement
		and drag.input.UserInputType == Enum.UserInputType.MouseButton1) then
		drag.slider.set(valueAt(drag.slider, input.Position.X))
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	local drag = dragging
	if drag and (input == drag.input or (input.UserInputType == drag.input.UserInputType
		and input.UserInputType ~= Enum.UserInputType.Touch)) then
		dragging = nil
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject)
	local selected = GuiService.SelectedObject
	if not selected then
		return
	end
	local key = input.KeyCode
	local step = if key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.Left then -NUDGE
		elseif key == Enum.KeyCode.DPadRight or key == Enum.KeyCode.Right then NUDGE
		else 0
	if step == 0 then
		return
	end
	for _, s in ipairs(sliders) do
		if s.hit == selected then
			s.set(math.clamp(math.round((s.value + step) * 100) / 100, 0, 1))
			return
		end
	end
end)

local function placeSlider(s: Slider, level: number, muted: boolean)
	s.value = level
	s.knob.Position = UDim2.new(level, KNOB / 2 - level * KNOB, 0.5, 0)
	s.fill.Size = UDim2.fromScale(level, 1)
	s.fill.Visible = level > 0.005
	s.tint.Color = if muted then ColorSequence.new(OFF_FACE, OFF_SHADE)
		else ColorSequence.new(ON_FACE, ON_SHADE)
	s.knob.BackgroundColor3 = if muted then MUTED else CREAM
end

--==============================================================================
-- THE ROWS
--==============================================================================
local musicRow = makeRow(1, "Music", "MUSIC")
local fxRow = makeRow(2, "SoundFx", "SOUND FX")
local reducedRow = makeRow(3, "ReducedFx", "REDUCED FX")

local musicToggle = makeToggle(musicRow)
local fxToggle = makeToggle(fxRow)
local reducedToggle = makeToggle(reducedRow)

local function paintAudio(row: Row, s: Slider, t: Toggle, kind: string)
	local level, muted = SoundKit.level(kind)
	placeSlider(s, level, muted)
	paintToggle(t, not muted)
	row.detail.Text = if muted then "MUTED" else string.format("%d%%", math.round(level * 100))
	row.detail.TextColor3 = if muted then MUTED else CREAM
end

-- The three effect buses always move together, so any one of them speaks for
-- the row. UI is the one a player hears first.
local function setFx(level: number?, muted: boolean?)
	for _, bus in ipairs(FX_BUSES) do
		SoundKit.setLevel(bus, level, muted)
	end
end

local musicSlider: Slider
local fxSlider: Slider

local function paintMusic()
	paintAudio(musicRow, musicSlider, musicToggle, "Music")
end

local function paintFx()
	paintAudio(fxRow, fxSlider, fxToggle, "UI")
end

-- Moving a muted slider unmutes it: somebody dragging a level wants to hear it.
musicSlider = makeSlider(musicRow, function(level: number)
	SoundKit.setLevel("Music", level, false)
	paintMusic()
end)
fxSlider = makeSlider(fxRow, function(level: number)
	setFx(level, false)
	paintFx()
end)

musicToggle.button.Activated:Connect(function()
	local _, muted = SoundKit.level("Music")
	SoundKit.setLevel("Music", nil, not muted)
	paintMusic()
end)

fxToggle.button.Activated:Connect(function()
	local _, muted = SoundKit.level("UI")
	setFx(nil, not muted)
	paintFx()
end)

--==============================================================================
-- REDUCED EFFECTS
--
-- The same touch test SpeedFX and PlantAura use to pick their own default, so
-- switching this off on a phone puts the phone back to Reduced rather than
-- quietly promoting it to Full.
--==============================================================================
local function deviceQuality(): string
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		then "Reduced" else "Full"
end

local restoreQuality: string? = nil

local function paintReduced()
	local on = player:GetAttribute(QUALITY) == "Off"
	paintToggle(reducedToggle, on)
	reducedRow.detail.Text = "HIDES TRAILS, SPARKS & UI MOTION"
	reducedRow.detail.TextColor3 = if on then CREAM else MUTED
end

reducedToggle.button.Activated:Connect(function()
	local now = player:GetAttribute(QUALITY)
	if now == "Off" then
		local back = restoreQuality
		restoreQuality = nil
		player:SetAttribute(QUALITY,
			if back == "Full" or back == "Reduced" then back else deviceQuality())
	else
		restoreQuality = if type(now) == "string" then now else nil
		player:SetAttribute(QUALITY, "Off")
	end
end)

player:GetAttributeChangedSignal(QUALITY):Connect(paintReduced)

--==============================================================================
-- LAYOUT
--
-- Off the panel's real width, which is 90% of the screen up to the cap: the name
-- column takes about a third, the ON/OFF keeps its 64 and the slider gets the
-- rest. The reduced row has no slider, so its words take the width one would
-- have had.
--==============================================================================
local function relayout()
	local width = rowsFrame.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local nameW = math.clamp(math.floor(width * 0.3), 84, 124)
	local sliderLeft = ROW_PAD + nameW + 6
	local sliderRight = TOGGLE_W + 12
	for _, row in ipairs({ musicRow, fxRow }) do
		row.title.Size = UDim2.fromOffset(nameW, 22)
		row.detail.Size = UDim2.fromOffset(nameW, 16)
	end
	for _, s in ipairs(sliders) do
		s.hit.Position = UDim2.new(0, sliderLeft, 0.5, 0)
		s.hit.Size = UDim2.new(1, -(sliderLeft + sliderRight), 0, TARGET)
	end
	reducedRow.title.Size = UDim2.new(1, -(ROW_PAD + sliderRight), 0, 22)
	reducedRow.detail.Size = UDim2.new(1, -(ROW_PAD + sliderRight), 0, 16)
	modal.fitContent(ROW_H * 3 + ROW_GAP * 2)
end

rowsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)

--==============================================================================
-- OPEN AND SHUT
--
-- The OpenPanel handshake every centred panel uses: write our name on the way
-- in, clear it on the way out, close on seeing somebody else's.
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		-- Painted before it shows, off SoundKit and the attribute themselves, so
		-- the panel can never disagree with what the speakers are doing.
		paintMusic()
		paintFx()
		paintReduced()
	else
		dragging = nil
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
	end
	modal.setOpen(want)
end

button.Activated:Connect(function()
	setOpen(not open)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)

paintMusic()
paintFx()
paintReduced()
relayout()
