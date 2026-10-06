--!strict
-- Steal a Seed :: BoostIconsUI (2026-10-04, the owner's ask)
--
-- THE ACTIVE BOOST AND EVENT ICONS: one compact row of round icons directly
-- over the hotbar (HudLayout's `icons` rect, just above the item name's band),
-- one per boost or event running for this player -- the Rain or Thunderstorm,
-- the Disco, the Ticket Shower, the Bonus Chest's (or the wheel's) income or
-- training boost, the Sacrifice Pedestal's. They replace the text lines that
-- said the same thing (WeatherUI's rain chip, MiniEventUI's ticket and disco
-- line, BonusChestUI's boost row).
--
-- READ-ONLY. Every icon is drawn from the server's own attributes and its
-- authoritative deadline (Shared/BoostIcons). Nothing here grants, extends or
-- changes a modifier, and no tap reaches the server.
--
-- A TAP OPENS A POPOVER ABOVE THE ICON: where it comes from, exactly what it
-- does, the time left (ticking) and what to do -- or, on the tickets, how many
-- of the per-event limit are taken. One at a time. The same icon again, a tap
-- anywhere outside it and the row, a panel opening, or B closes it. On a
-- controller the PadKey (DPadDown) opens the first, then each next one, and
-- past the last closes it; left and right step along while one is open.
--
-- A faint ring round each icon empties as its time runs out, once a second.
-- Reduced motion drops only the popover's rise. Taps never reach the world:
-- the buttons sink them, and nothing else here is Active.
--
-- THE ROW'S SIZE IS PUBLISHED: the local player's BoostIcons.Attribute holds
-- how many icons stand (nil for none). HudLayout.measure reads it, so the toast
-- line steps up over the row, and ActionToastUI re-places when it changes.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local BoostIcons = require(Shared:WaitForChild("BoostIcons"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CFG = GameConfig.BoostIcons
-- HUD, not a menu: the slate palette, which the menus' bright recolor
-- (2026-10-04) does not touch.
local LOOK = MenuKit.Slate

local PAD_ACTION = "SeedBoostIconsPad"
local NAV_ACTION = "SeedBoostIconsNav"
-- Over PadFocus's B (2500) and the bumpers (2600), under a menu's own B (3000):
-- only bound while a popover is open, and a menu opening closes it first.
local NAV_PRIORITY = 2700

local stale = playerGui:FindFirstChild("SeedBoostIcons")
if stale then
	stale:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedBoostIcons"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- Under the hotbar (30) and every panel (31+), over the notices (13): the row
-- never covers a panel, and its popover stands over a notice it shares space
-- with.
gui.DisplayOrder = 29
gui.Parent = playerGui
UIKit.tenFoot(gui)

local row = Instance.new("Frame")
row.Name = "Row"
row.BackgroundTransparency = 1
row.BorderSizePixel = 0
row.Active = false
row.Visible = false
row.Parent = gui

-- The controller's button, beside the row while a controller is in use.
local padHint = Instance.new("ImageLabel")
padHint.Name = "PadHint"
padHint.BackgroundTransparency = 1
padHint.AnchorPoint = Vector2.new(1, 0.5)
padHint.ScaleType = Enum.ScaleType.Fit
padHint.Visible = false
padHint.Active = false
padHint.Parent = row

--==============================================================================
-- ONE ICON: A ROUND SLATE PLATE, THE PICTURE, THE RING, A BADGE
--==============================================================================
type Icon = {
	id: string,
	source: string,
	frame: Frame,
	box: Frame,
	pop: UIScale,
	right: UIGradient,
	left: UIGradient,
	badge: TextLabel,
	hit: TextButton,
}

local icons: { [string]: Icon } = {}
local current: { BoostIcons.Entry } = {}
local currentKey = ""
local openId: string? = nil
local size = CFG.Size.Desktop

-- Half of the ring, clipped: a whole circle's stroke with a hard-edged
-- gradient, so turning the gradient shows more or less of that half.
local function ringHalf(parent: Frame, name: string, x: number, tint: Color3): UIGradient
	local clip = Instance.new("Frame")
	clip.Name = name
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromScale(0.5, 1)
	clip.Position = UDim2.fromScale(x, 0)
	clip.Active = false
	clip.ZIndex = 3
	clip.Parent = parent
	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.BackgroundTransparency = 1
	circle.BorderSizePixel = 0
	-- Inset by the stroke, which a Border stroke draws OUTSIDE its frame.
	circle.Size = UDim2.new(2, -6, 1, -6)
	circle.Position = UDim2.new(if x > 0 then -1 else 0, 3, 0, 3)
	circle.Active = false
	circle.ZIndex = 3
	circle.Parent = clip
	UIKit.corner(circle, 999)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = tint
	stroke.Thickness = 2.5
	stroke.Transparency = 0.1
	stroke.Parent = circle
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.501, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = stroke
	return gradient
end

local toggle: (id: string) -> ()

local function buildIcon(e: BoostIcons.Entry): Icon
	local frame = Instance.new("Frame")
	frame.Name = e.id
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Parent = row
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = frame

	local plate = MenuKit.frame(frame, "Plate", 1, LOOK.Card, 0.2, 999)
	plate.Size = UDim2.new(1, -2, 1, -2)
	plate.Position = UDim2.fromOffset(1, 1)
	-- The faint full track the ring empties along.
	local track = MenuKit.frame(frame, "Track", 2, nil, nil, 999)
	track.Size = UDim2.new(1, -6, 1, -6)
	track.Position = UDim2.fromOffset(3, 3)
	MenuKit.keyline(track, e.tint, 2.5, 0.78)

	local right = ringHalf(frame, "RingRight", 0.5, e.tint)
	local left = ringHalf(frame, "RingLeft", 0, e.tint)

	-- The picture, or until it loads (or with no id yet) the glyph; the box is
	-- named "Icon", which is what RewardSplash flies a reward to.
	local box = StatusText.icon(frame, e.glyph, e.tint, 10, e.source)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(0.66, 0.66)
	box.ZIndex = 4

	local badge = MenuKit.text(frame, "Badge", 11, LOOK.Cream, 6)
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.new(0.5, 0, 1, -9)
	badge.Size = UDim2.fromOffset(30, 13)
	badge.BackgroundColor3 = LOOK.Well
	badge.BackgroundTransparency = 0.1
	badge.Font = Enum.Font.FredokaOne
	badge.Visible = false
	UIKit.corner(badge, 6)

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Selectable = false
	hit.AnchorPoint = Vector2.new(0.5, 0.5)
	hit.Position = UDim2.fromScale(0.5, 0.5)
	hit.ZIndex = 8
	hit.Parent = frame
	local id = e.id
	hit.Activated:Connect(function()
		toggle(id)
	end)

	return {
		id = id,
		source = e.source,
		frame = frame,
		box = box,
		pop = pop,
		right = right,
		left = left,
		badge = badge,
		hit = hit,
	}
end

-- A new picture for an icon whose source changed (the rain turning into a
-- thunderstorm): the box is rebuilt in place, nothing else.
local function reface(icon: Icon, e: BoostIcons.Entry)
	if icon.source == e.source then
		return
	end
	icon.box:Destroy()
	local box = StatusText.icon(icon.frame, e.glyph, e.tint, 10, e.source)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(0.66, 0.66)
	box.ZIndex = 4
	icon.box = box
	icon.source = e.source
end

--==============================================================================
-- THE POPOVER
--==============================================================================
local popover = MenuKit.frame(gui, "Popover", 20, LOOK.Sheet, 0.04, 10)
popover.AnchorPoint = Vector2.new(0, 1)
popover.AutomaticSize = Enum.AutomaticSize.Y
popover.Visible = false
MenuKit.keyline(popover, LOOK.SheetEdge, 1.5)
local popPad = Instance.new("UIPadding")
popPad.PaddingTop = UDim.new(0, 8)
popPad.PaddingBottom = UDim.new(0, 9)
popPad.PaddingLeft = UDim.new(0, 10)
popPad.PaddingRight = UDim.new(0, 10)
popPad.Parent = popover
local popList = Instance.new("UIListLayout")
popList.SortOrder = Enum.SortOrder.LayoutOrder
popList.Padding = UDim.new(0, 3)
popList.Parent = popover
local popScale = Instance.new("UIScale")
popScale.Parent = popover

local function popLine(name: string, order: number, textSize: number, colour: Color3, font: Enum.Font): TextLabel
	local l = MenuKit.text(popover, name, textSize, colour, 21)
	l.LayoutOrder = order
	l.Font = font
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Size = UDim2.new(1, 0, 0, textSize + 2)
	return l
end

local popTitle = popLine("Title", 1, 18, LOOK.Title, Enum.Font.FredokaOne)
local popEffect = popLine("Effect", 2, 14, LOOK.Cream, Enum.Font.FredokaOne)
local popTime = popLine("Time", 3, 13, LOOK.Gold, Enum.Font.FredokaOne)
local popHint = popLine("Hint", 4, 13, LOOK.Muted, Enum.Font.FredokaOne)

-- The small notch pointing down at the icon.
local caret = MenuKit.frame(gui, "Caret", 19, LOOK.Sheet, 0.04, nil)
caret.AnchorPoint = Vector2.new(0.5, 0.5)
caret.Rotation = 45
caret.Size = UDim2.fromOffset(12, 12)
caret.Visible = false
MenuKit.keyline(caret, LOOK.SheetEdge, 1.5)

local lastLayout: HudLayout.Layout? = nil

local function entryOf(id: string): BoostIcons.Entry?
	for _, e in ipairs(current) do
		if e.id == id then
			return e
		end
	end
	return nil
end

local function paintPopover()
	local id = openId
	local e = if id then entryOf(id) else nil
	if not e then
		return
	end
	local now = Workspace:GetServerTimeNow()
	popTitle.Text = e.title
	popEffect.Text = e.effect
	popTime.Text = BoostIcons.timeLine(e, now)
	popHint.Text = e.hint or ""
	popHint.Visible = e.hint ~= nil
end

local function placePopover()
	local id = openId
	local icon = if id then icons[id] else nil
	local L = lastLayout
	local r = L and L.icons
	if not (icon and L and r) then
		popover.Visible = false
		caret.Visible = false
		return
	end
	local phone = L.sidebar
	local width = if phone then CFG.Popover.PhoneWidth else CFG.Popover.Width
	local textScale = if phone then 0.88 elseif L.compact then 0.94 else 1
	popTitle.TextSize = math.round(18 * textScale)
	popEffect.TextSize = math.round(14 * textScale)
	popTime.TextSize = math.round(13 * textScale)
	popHint.TextSize = math.round(13 * textScale)
	local margin = HudLayout.Config.Margin
	local cx = r.x + icon.frame.Position.X.Offset
	local x = math.clamp(cx - width / 2, margin, math.max(margin, L.safe.X - margin - width))
	local bottom = r.y - CFG.Popover.Gap
	popover.Size = UDim2.fromOffset(width, 0)
	popover.Position = HudLayout.place(HudLayout.rect(x, bottom, width, 0), Vector2.new(0, 1), L.safe)
	caret.Position = HudLayout.place(HudLayout.rect(cx, bottom - 1, 0, 0), Vector2.new(0.5, 0.5), L.safe)
	popover.Visible = true
	caret.Visible = true
end

local function unbindNav()
	ContextActionService:UnbindAction(NAV_ACTION)
end

local open: (id: string?) -> ()

local function bindNav()
	ContextActionService:BindActionAtPriority(NAV_ACTION, function(_, state: Enum.UserInputState,
		input: InputObject)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		if input.KeyCode == Enum.KeyCode.ButtonB then
			open(nil)
		else
			local ids = {}
			for i, e in ipairs(current) do
				ids[i] = e.id
			end
			open(BoostIcons.nextOpen(ids, openId, if input.KeyCode == Enum.KeyCode.DPadLeft then -1 else 1, true))
		end
		return Enum.ContextActionResult.Sink
	end, false, NAV_PRIORITY, Enum.KeyCode.ButtonB, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)
end

open = function(id: string?)
	if id and not icons[id] then
		id = nil
	end
	local was = openId
	openId = id
	for key, icon in pairs(icons) do
		icon.pop.Scale = if key == id then 1.08 else 1
	end
	if not id then
		popover.Visible = false
		caret.Visible = false
		if was then
			unbindNav()
		end
		return
	end
	paintPopover()
	placePopover()
	if was == nil then
		if PadInput.active() then
			bindNav()
		end
		if not StatusText.reducedMotion() then
			popScale.Scale = 0.92
			TweenService:Create(popScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = 1 }):Play()
		end
	end
end

toggle = function(id: string)
	open(if openId == id then nil else id)
end

--==============================================================================
-- THE ROW: PLACED BY HudLAYOUT, REDRAWN ONCE A SECOND AND ON EVERY CHANGE
--==============================================================================
local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local L = HudLayout.solve(HudLayout.measure(gui))
	lastLayout = L
	local r = L.icons
	if not r or #current == 0 then
		row.Visible = false
		open(nil)
		return
	end
	size = L.iconSize
	local columns = math.max(1, L.iconColumns)
	row.Position = HudLayout.place(r, Vector2.zero, L.safe)
	row.Size = UDim2.fromOffset(r.w, r.h)
	local gap = CFG.Gap
	local n = #current
	for i, e in ipairs(current) do
		local icon = icons[e.id]
		if icon then
			local index = i - 1
			local line = index // columns
			local inLine = math.min(columns, n - line * columns)
			local lineWidth = inLine * size + (inLine - 1) * gap
			local x0 = (r.w - lineWidth) / 2
			local col = index % columns
			icon.frame.Size = UDim2.fromOffset(size, size)
			icon.frame.Position = UDim2.fromOffset(math.round(x0 + col * (size + gap) + size / 2),
				math.round(line * (size + gap) + size / 2))
			-- The touch area: as big as the gap allows, never under the icon.
			local reach = size + gap
			icon.hit.Size = UDim2.fromOffset(reach, reach)
			icon.badge.TextSize = math.max(9, math.round(size * 0.3))
			icon.badge.Size = UDim2.fromOffset(math.round(size * 0.8), math.round(size * 0.34))
		end
	end
	local glyph = if PadInput.active() then PadInput.glyph(CFG.PadKey) else ""
	padHint.Image = glyph
	padHint.Size = UDim2.fromOffset(math.round(size * 0.55), math.round(size * 0.55))
	padHint.Position = UDim2.new(0, -6, 0, math.round(size / 2))
	padHint.Visible = glyph ~= ""
	row.Visible = true
	if openId then
		placePopover()
	end
end

local function publishCount(n: number)
	local want = if n > 0 then n else nil
	if player:GetAttribute(CFG.Attribute) ~= want then
		player:SetAttribute(CFG.Attribute, want)
	end
end

local function redraw()
	local now = Workspace:GetServerTimeNow()
	local list = BoostIcons.entries(BoostIcons.read(player, Workspace, now))
	local key = BoostIcons.key(list)
	current = list
	if key ~= currentKey then
		currentKey = key
		local keep: { [string]: boolean } = {}
		for _, e in ipairs(list) do
			keep[e.id] = true
			if not icons[e.id] then
				icons[e.id] = buildIcon(e)
			end
		end
		for id, icon in pairs(icons) do
			if not keep[id] then
				icon.frame:Destroy()
				icons[id] = nil
			end
		end
		if openId and not keep[openId] then
			open(nil)
		end
		-- Published BEFORE placing: the layout reads it.
		publishCount(#list)
		place()
	end
	for _, e in ipairs(list) do
		local icon = icons[e.id]
		if icon then
			reface(icon, e)
			local r, l = BoostIcons.ringRotations(BoostIcons.fraction(e, now))
			icon.right.Rotation = r
			icon.left.Rotation = l
			icon.badge.Text = e.badge or ""
			icon.badge.Visible = e.badge ~= nil
		end
	end
	if openId then
		paintPopover()
	end
end

-- Many attributes change together (a claim writes four): one redraw for all
-- of them, on the next frame.
local queued = false
local function soon()
	if queued then
		return
	end
	queued = true
	task.defer(function()
		queued = false
		redraw()
	end)
end

for _, w in ipairs(BoostIcons.watched()) do
	local target: Instance = if w.on == "player" then player else Workspace
	target:GetAttributeChangedSignal(w.name):Connect(soon)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
-- A trap's REMOVE row over the strip (LoadoutUI, 2026-10-04) lifts the row.
player:GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(place)
-- The x2 card coming or going (2026-10-05): on a narrow phone the belt, which the
-- row stands over, keeps 8 px off it beside the cash line.
player:GetAttributeChangedSignal(GameConfig.Pass.MultiplierAttribute):Connect(place)
PadInput.Changed:Connect(function(on: boolean)
	place()
	if not on then
		unbindNav()
	elseif openId then
		bindNav()
	end
end)

--==============================================================================
-- CLOSING FROM OUTSIDE: a tap or click anywhere but the popover and the row
-- (the row's own buttons decide for themselves), and any panel opening. The
-- input is only looked at, never taken: the world still gets the tap.
--==============================================================================
local function inside(object: GuiObject, at: Vector2): boolean
	if not object.Visible then
		return false
	end
	local p, s = object.AbsolutePosition, object.AbsoluteSize
	return at.X >= p.X and at.X <= p.X + s.X and at.Y >= p.Y and at.Y <= p.Y + s.Y
end

UserInputService.InputBegan:Connect(function(input: InputObject)
	if not openId then
		return
	end
	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
		return
	end
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if inside(popover, at) or inside(row, at) then
		return
	end
	open(nil)
end)

PadInput.watch()
PadInput.PanelChanged:Connect(function(_, isOpen: boolean)
	if isOpen then
		open(nil)
	end
end)

--==============================================================================
-- THE CONTROLLER'S WAY IN
--==============================================================================
ContextActionService:BindAction(PAD_ACTION, function(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if #current == 0 or PadInput.panelOpen() then
		return Enum.ContextActionResult.Pass
	end
	local ids = {}
	for i, e in ipairs(current) do
		ids[i] = e.id
	end
	open(BoostIcons.nextOpen(ids, openId, 1, false))
	return Enum.ContextActionResult.Sink
end, false, CFG.PadKey)

-- Once a second: the clocks, the rings and anything whose deadline passed.
task.spawn(function()
	while gui.Parent do
		redraw()
		task.wait(1)
	end
end)
