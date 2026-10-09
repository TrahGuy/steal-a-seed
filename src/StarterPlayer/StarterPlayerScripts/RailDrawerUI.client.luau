--!strict
-- Steal a Seed :: RailDrawerUI
--
-- On a touch screen: the slim panel -- INVITE, EVENTS, WHAT'S NEW and Settings
-- (the owner, 2026-10-05 and 2026-10-06) -- as one row under the clock's chip
-- since 2026-10-09 ("it should show sideways"), its viewport and the "<"
-- handle at its left end that folds it away to the right edge. Nothing else.
--
--==============================================================================
-- ONE OWNER PER CONTROL, AS EVERYWHERE ON THIS HUD
--
-- The squares are still InviteUI's, EventsUI's, UpdateLogUI's and SettingsUI's.
-- Each builds, shapes, places and answers its own, and on a phone puts it in
-- the panel's scrolling canvas (UIKit.placeRail). This script owns the panel
-- round them: the tray, the viewport's place and size, the fade at a cut edge,
-- the handle, the shut state and its slide -- and the one thing the whole dock
-- frame does: it steps aside while a centre panel is open.
--
-- Where everything stands is HudLayout's (THE PHONE'S SIDEBARS: `handle`,
-- `dockView`, `dockCanvas`). On a desktop and in compact there is no panel and
-- this draws nothing.
--
--==============================================================================
-- IT SHUTS SIDEWAYS (the owner, 2026-10-06; a row since 2026-10-09)
--
-- From 2026-10-06 the panel ran down the right edge and scrolled where four
-- squares did not fit a short phone's height. As a row every listed phone holds
-- it whole, so it never scrolls now; the scrolling frame, its fades and the
-- pinned "!" below stay for a screen that ever needs them.
--
-- The handle at the row's left end -- a drawn chevron, no glyph (Gotham draws
-- most arrows as boxes): ">" while open, "<" while tucked, the way the row will
-- move (the owner) -- folds the row away to the right edge, where the handle
-- alone then stands, and brings it back out. Open by
-- default; the choice lasts the session (a client-local attribute HudLayout
-- reads), never the save. The slide is decoration: the answer is the shut or
-- open layout at once, and the tween only draws the way there. Shut, a square
-- that wears a badge shows it on the handle -- INVITE's "!" before any red dot.
-- A controller's selection on a square that is shutting away moves to the handle.
--
-- INVITE'S "!" NEVER SCROLLS AWAY (the owner, 2026-10-06). Scrolled so far that
-- INVITE's own "!" would be cut, the panel pins it to its top edge, over the top
-- fade, in the very box it stands in with the canvas at the top
-- (HudLayout.invitePin); InviteUI hides its own while PinAttribute says so. A
-- tap on the pinned "!" scrolls the panel back to the top. The panel opens at
-- the top: on joining, and every time it opens after being shut.
--
-- IT STEPS ASIDE WHILE A CENTRE PANEL IS OPEN, as it always has: the dock frame
-- is hidden while OpenPanel names a panel.
--==============================================================================

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local PP = HudLayout.Config.Phone.Panel
local BADGE = RAIL.InviteBadge

local layer = UIKit.railLayer(playerGui)
local dock = UIKit.railDock(playerGui)
local scroll = UIKit.railDockScroll(playerGui)
local clip = scroll.Parent :: Frame

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
for _, name in ipairs({ "DockPanel", "DockHandle", "DockFade", "DockFadeTop", "DockInvitePin", "DockHandleBadge" }) do
	local stale = layer:FindFirstChild(name, true)
	if stale then
		stale:Destroy()
	end
end

--==============================================================================
-- THE TRAY, THE FADE, THE HANDLE AND ITS BADGE
--==============================================================================
local panel = Instance.new("Frame")
panel.Name = "DockPanel"
panel.BackgroundColor3 = RAIL.DockFill
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = false
panel.ZIndex = 0
panel.Visible = false
panel.Parent = dock
UIKit.corner(panel, 12)
UIKit.stroke(panel, RAIL.DockEdge, 1.5, 0.15)

-- Over the viewport's foot while more of the canvas lies below it.
local fade = Instance.new("Frame")
fade.Name = "DockFade"
fade.AnchorPoint = Vector2.new(0, 1)
fade.Position = UDim2.fromScale(0, 1)
fade.Size = UDim2.new(1, 0, 0, 14)
fade.BackgroundColor3 = RAIL.DockFill
fade.BorderSizePixel = 0
fade.Active = false
fade.ZIndex = 20
fade.Visible = false
fade.Parent = clip
do
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new(1, 0.05)
	gradient.Parent = fade
end

-- Its mirror over the viewport's head while some of the canvas lies above it.
local topFade = Instance.new("Frame")
topFade.Name = "DockFadeTop"
topFade.Size = UDim2.new(1, 0, 0, 14)
topFade.BackgroundColor3 = RAIL.DockFill
topFade.BorderSizePixel = 0
topFade.Active = false
topFade.ZIndex = 20
topFade.Visible = false
topFade.Parent = clip
do
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new(0.05, 1)
	gradient.Parent = topFade
end

-- INVITE's "!" pinned to the top edge (HudLayout.invitePin), over the fade: a
-- press PinPad bigger than the "!", the glyph in INVITE's own look and box.
local pin = Instance.new("TextButton")
pin.Name = "DockInvitePin"
pin.Text = ""
pin.AutoButtonColor = false
pin.BackgroundTransparency = 1
pin.BorderSizePixel = 0
pin.Selectable = false
pin.ZIndex = 22
pin.Visible = false
pin.Parent = clip
local pinBang = Instance.new("TextLabel")
pinBang.Name = "Bang"
pinBang.AnchorPoint = Vector2.new(0.5, 0.5)
pinBang.BackgroundTransparency = 1
pinBang.Font = BADGE.Font
pinBang.Text = BADGE.Glyph
pinBang.TextColor3 = BADGE.Fill
pinBang.TextScaled = true
pinBang.Active = false
pinBang.ZIndex = 23
pinBang.Parent = pin
do
	local ink = Instance.new("UIStroke")
	ink.Name = "Ink"
	ink.Color = BADGE.Ink
	ink.Thickness = BADGE.Stroke
	ink.LineJoinMode = Enum.LineJoinMode.Round
	ink.Parent = pinBang
end
-- The scroll past which it pins (HudLayout), and the square badge it stands for.
local pinFrom = math.huge
local INVITE_BADGE = UIKit.DockBadgePrefix .. "Invite"

local handle = Instance.new("TextButton")
handle.Name = "DockHandle"
handle.Text = ""
handle.AutoButtonColor = false
handle.BackgroundColor3 = RAIL.DockFill
handle.BackgroundTransparency = 0.15
handle.BorderSizePixel = 0
handle.Visible = false
handle.Selectable = true
handle.ZIndex = 4
handle.Parent = dock
UIKit.corner(handle, 8)
UIKit.stroke(handle, RAIL.DockEdge, 1.5, 0.15)

-- The chevron: two short bars meeting at a point, drawn -- the way the row will
-- move (the owner, 2026-10-09): a ">" while it is open (a tap tucks it into the
-- right edge), a "<" while it is tucked (a tap brings it back out). It was an
-- up (^) or down (v) one on the panel's top edge before.
local chevron = Instance.new("Frame")
chevron.Name = "Chevron"
chevron.AnchorPoint = Vector2.new(0.5, 0.5)
chevron.Position = UDim2.fromScale(0.5, 0.5)
chevron.Size = UDim2.fromOffset(10, 18)
chevron.BackgroundTransparency = 1
chevron.Active = false
chevron.ZIndex = 5
chevron.Parent = handle
local bars: { Frame } = {}
for i, side in ipairs({ -1, 1 }) do
	local bar = Instance.new("Frame")
	bar.Name = "Bar" .. i
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.new(0.5, 0, 0.5, side * 4)
	bar.Size = UDim2.fromOffset(11, 3)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = chevron
	UIKit.corner(bar, 2)
	bars[i] = bar
end
local function drawChevron(shut: boolean)
	-- Tucked: a "<" (the upper bar rising to the right); open: a ">".
	local tilt = if shut then 52 else -52
	bars[1].Rotation = -tilt
	bars[2].Rotation = tilt
end

-- The handle's badge: INVITE's "!" (its own look, GameConfig.Rail.InviteBadge),
-- else the rail badge's red dot.
local handleBadge = Instance.new("Frame")
handleBadge.Name = "DockHandleBadge"
handleBadge.BackgroundTransparency = 1
handleBadge.Active = false
handleBadge.ZIndex = 8
handleBadge.Visible = false
handleBadge.Parent = dock
local bang = Instance.new("TextLabel")
bang.Name = "Bang"
bang.BackgroundTransparency = 1
bang.Size = UDim2.fromScale(1, 1.2)
bang.AnchorPoint = Vector2.new(0.5, 0.5)
bang.Position = UDim2.fromScale(0.5, 0.45)
bang.Font = BADGE.Font
bang.Text = BADGE.Glyph
bang.TextScaled = true
bang.TextColor3 = BADGE.Fill
bang.ZIndex = 9
bang.Parent = handleBadge
do
	local ink = Instance.new("UIStroke")
	ink.Color = BADGE.Ink
	ink.Thickness = math.max(2, BADGE.Stroke - 1)
	ink.Parent = bang
end
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromScale(0.6, 0.6)
dot.BackgroundColor3 = RAIL.Badge
dot.BorderSizePixel = 0
dot.ZIndex = 9
dot.Parent = handleBadge
UIKit.corner(dot, 64)
UIKit.stroke(dot, Color3.fromRGB(255, 255, 255), 1.5)

-- The badges the squares wear (UIKit.dockBadge): "bang" before "dot".
local function squareBadge(): string?
	local found: string? = nil
	for name, value in pairs(player:GetAttributes()) do
		if string.sub(name, 1, #UIKit.DockBadgePrefix) == UIKit.DockBadgePrefix then
			if value == "bang" then
				return "bang"
			elseif value == "dot" then
				found = "dot"
			end
		end
	end
	return found
end

--==============================================================================
-- THE ANSWER, APPLIED
--==============================================================================
local slide: Tween? = nil
local lastShut: boolean? = nil

local function isShut(): boolean
	return player:GetAttribute(PP.ShutAttribute) == true
end

-- The pinned "!": while INVITE wears its "!", the panel is open and showing, and
-- the canvas has scrolled past where INVITE's own would be cut.
local function refreshPin()
	local up = clip.Visible and dock.Visible and not isShut() and player:GetAttribute(INVITE_BADGE) == "bang"
		and scroll.CanvasPosition.Y > pinFrom
	pin.Visible = up
	player:SetAttribute(PP.PinAttribute, if up then true else nil)
end

local function place()
	if layer.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(layer))
	dock.Position = UDim2.new()
	local view, hr = layout.dockView, layout.handle
	if not (layout.sidebar and view and hr) then
		-- No panel on this screen: the rail buttons are back in the layer, and the
		-- frame waits, in place and empty, for a touch screen.
		panel.Visible = false
		handle.Visible = false
		handleBadge.Visible = false
		clip.Visible = false
		dock.Visible = true
		pinFrom = math.huge
		refreshPin()
		return
	end
	local shut = layout.dockShut == true
	drawChevron(shut)
	local handleAt = HudLayout.place(hr, Vector2.zero, layout.safe)
	handle.Size = UDim2.fromOffset(hr.w, hr.h)
	handle.Visible = true
	-- The viewport and the tray behind it, hung from the row's RIGHT end at the
	-- open size; shut, the clip slides to nothing into the right edge (or is
	-- simply nothing, with no tween), and the handle goes with its left end.
	clip.AnchorPoint = Vector2.new(1, 0)
	panel.AnchorPoint = clip.AnchorPoint
	clip.Position = HudLayout.place(view, Vector2.new(1, 0), layout.safe)
	panel.Position = clip.Position
	-- The pinned "!": its press and its glyph in the clip's own coordinates.
	local box, from, press = HudLayout.invitePin(layout)
	pinFrom = from
	pin.Position = UDim2.fromOffset(press.x - view.x, press.y - view.y)
	pin.Size = UDim2.fromOffset(press.w, press.h)
	pinBang.Position = UDim2.fromOffset(box.x - press.x + box.w / 2, box.y - press.y + box.h / 2)
	pinBang.Size = UDim2.fromOffset(box.w, math.floor(box.h * BADGE.Scale))
	local openSize = UDim2.fromOffset(view.w, view.h)
	local target = if shut then UDim2.fromOffset(0, view.h) else openSize
	local changed = lastShut ~= nil and lastShut ~= shut
	-- Opening fresh -- on joining, or after being shut -- it opens at the top.
	if not shut and lastShut ~= false then
		scroll.CanvasPosition = Vector2.zero
	end
	lastShut = shut
	local running = slide
	if running then
		running:Cancel()
		slide = nil
	end
	if changed and PP.Slide > 0 then
		clip.Visible = true
		panel.Visible = true
		local info = TweenInfo.new(PP.Slide, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(clip, info, { Size = target })
		TweenService:Create(panel, info, { Size = target }):Play()
		TweenService:Create(handle, info, { Position = handleAt }):Play()
		slide = tween
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and slide == tween then
				slide = nil
				clip.Visible = not shut
				panel.Visible = not shut
			end
		end)
		tween:Play()
	else
		clip.Size = target
		panel.Size = target
		handle.Position = handleAt
		clip.Visible = not shut
		panel.Visible = not shut
	end
	-- Shut: a controller's selection on a square going away moves to the handle.
	if shut then
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(scroll) then
			GuiService.SelectedObject = handle
		end
	end
	-- The handle's badge, while shut and a square wears one.
	local kind = if shut then squareBadge() else nil
	if kind then
		local b = HudLayout.handleBadge(layout)
		handleBadge.Position = HudLayout.place(b, Vector2.zero, layout.safe)
		handleBadge.Size = UDim2.fromOffset(b.w, b.h)
		bang.Visible = kind == "bang"
		dot.Visible = kind == "dot"
		handleBadge.Visible = true
	else
		handleBadge.Visible = false
	end
	dock.Visible = player:GetAttribute(ATTR.OpenPanel) == nil
	refreshPin()
end

-- The fades: below while the canvas runs on under the viewport, above while some
-- of it lies over it; and the pinned "!", which goes with the scroll.
local function refreshFade()
	local below = scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y - scroll.CanvasPosition.Y
	fade.Visible = clip.Visible and below > 1
	topFade.Visible = clip.Visible and scroll.CanvasPosition.Y > 1
	refreshPin()
end

handle.Activated:Connect(function()
	player:SetAttribute(PP.ShutAttribute, not isShut())
end)

-- A tap on the pinned "!": back to the top (the glide is decoration).
local toTop: Tween? = nil
pin.Activated:Connect(function()
	local running = toTop
	if running then
		running:Cancel()
	end
	if PP.Slide > 0 then
		local tween = TweenService:Create(scroll, TweenInfo.new(PP.Slide, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { CanvasPosition = Vector2.zero })
		toTop = tween
		tween:Play()
	else
		scroll.CanvasPosition = Vector2.zero
	end
end)

--==============================================================================
-- ASKED AGAIN WHEN THE SCREEN CHANGES SHAPE, A PANEL OPENS OR SHUTS, THE HANDLE
-- IS PRESSED, OR A SQUARE'S BADGE CHANGES
--==============================================================================
local connections: { RBXScriptConnection } = {
	layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(place),
	player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(place),
	player:GetAttributeChangedSignal(PP.ShutAttribute):Connect(place),
	player.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, #UIKit.DockBadgePrefix) == UIKit.DockBadgePrefix then
			place()
		end
	end),
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(refreshFade),
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(refreshFade),
	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refreshFade),
	clip:GetPropertyChangedSignal("Visible"):Connect(refreshFade),
}
panel.Destroying:Once(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
end)
place()
refreshFade()
