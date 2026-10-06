--!strict
-- Steal a Seed :: StatusText
--
-- THE TEXT-LED LOOK, FOR WHAT STAYS UP (2026-09-27)
--
-- The notices (Notice, ActionToastUI) lost their plate on 2026-09-27 and the
-- owner approved the look. This is the same look for the indicators that are
-- not notices: a state that lasts (CHASED!), a timer that runs (+25% TRAINING
-- 1:56), a run in progress (the obby's stage and its clock). No plate, no
-- capsule, no border -- a line of type in its own colour with the notices' dark
-- outline, a small icon drawn from frames where one helps, and after it, when
-- there is one, a smaller warm-white part. That second part is where a clock
-- goes, in a monospaced face so a countdown never jiggles the line.
--
-- ONE LINE, ONE OBJECT. An owner builds it once, writes words into it with
-- `set` as often as it likes -- a countdown every half-second -- and calls
-- `show` and `hide` when the thing it reports starts and stops. `set` never
-- animates and never plays a sound, so a clock ticking is only a clock
-- ticking. `show` on a line that is up and `hide` on one that is down do
-- nothing, so an owner can call them from every repaint.
--
-- THE MOTION IS THE NOTICES' OWN (Notice.EnterSeconds and the rest): in, a
-- short rise and a small settle, quint-out, no overshoot; out, a fade with a
-- few pixels of drift. `nudge` is the notices' repeat nudge, for a state that
-- changed in place (WAKING to CHASED). Nothing loops, pulses or bounces.
-- REDUCED FX and Roblox's reduced motion keep only the fades.
--
-- NOTHING IN IT TAKES INPUT. No button, nothing Active or Selectable: a tap, a
-- click or a controller's selection goes straight through to what is under it.
--
-- WHERE IT GOES is the owner's to ask of HudLayout (statusRows, centreIn). This
-- builds, animates and says how big it is.
--==============================================================================

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local StatusText = {}

--==============================================================================
-- THE PALETTE AND THE FACES
--
-- The notices' outline and warm white, and one colour of our own: the chase's
-- warm red, a touch deeper than the blocked notice's so a danger that lasts is
-- not mistaken for a refusal that passes. The dark outline is what carries every
-- one of these over bright grass, pale sky and the night.
--==============================================================================
StatusText.Outline = Notice.Outline
StatusText.Detail = Notice.DetailColour
StatusText.Danger = Color3.fromRGB(255, 84, 64)
StatusText.HeadFont = Enum.Font.LuckiestGuy
StatusText.DetailFont = Enum.Font.GothamBold
StatusText.ClockFont = Enum.Font.RobotoMono

--==============================================================================
-- THE ICONS, FROM FRAMES
--
-- Moved here from ActionToastUI (2026-09-27) so the notices and the lasting
-- indicators draw one family. Each is a dark ring under a coloured ring, and a
-- coloured glyph with a thin dark edge: the same two-layer outline the words
-- have. Nothing thinner than about a tenth of the box, which is where UIKit's
-- own icons found mush begins.
--
--   blocked   a ring with a bar through it
--   success   a tick
--   warning   a diamond with "!"
--   info      an "i"
--   boost     an arrow pointing up: something running faster for a while
--==============================================================================
local function edge(target: Instance, thickness: number): UIStroke
	local s = UIKit.stroke(target, Notice.Outline, thickness, 0.2)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function ring(box: Frame, tint: Color3, diamond: boolean, size: number)
	local line = math.max(2, math.floor(size * 0.12 + 0.5))
	for layer = 1, 2 do
		local r = Instance.new("Frame")
		r.Name = if layer == 1 then "RingEdge" else "Ring"
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Position = UDim2.fromScale(0.5, 0.5)
		r.Size = if diamond then UDim2.fromScale(0.7, 0.7) else UDim2.fromScale(0.86, 0.86)
		r.Rotation = if diamond then 45 else 0
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.ZIndex = 2 + layer
		r.Parent = box
		local c = Instance.new("UICorner")
		c.CornerRadius = if diamond then UDim.new(0.18, 0) else UDim.new(0.5, 0)
		c.Parent = r
		local s = UIKit.stroke(r, if layer == 1 then Notice.Outline else tint,
			if layer == 1 then line + 2 else line, if layer == 1 then 0.2 else 0)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
end

local function bar(box: Frame, name: string, cx: number, cy: number, w: number, h: number,
	tint: Color3, rotation: number?): Frame
	local f = UIKit.piece(box, name, cx, cy, w, h, tint, 0.5, rotation, 5)
	edge(f, 1)
	return f
end

--==============================================================================
-- OR A PICTURE OF WHERE IT CAME FROM (2026-10-03)
--
-- `source` names one of GameConfig.SourceIcons (rain, thunder, chest, wheel,
-- sacrifice, income, training, community). Its uploaded picture is drawn in
-- the same box INSTEAD of the glyph -- and until its id is filled in, the glyph
-- `kind` is drawn exactly as before. The box keeps its name, "Icon", which is
-- what RewardSplash flies a reward to.
--==============================================================================
function StatusText.sourceImage(source: string?): string?
	local id = if source then (GameConfig.SourceIcons :: any)[source] else nil
	return if type(id) == "string" and id ~= "" then id else nil
end

function StatusText.icon(parent: GuiObject, kind: string, tint: Color3, size: number, source: string?): Frame
	local box = Instance.new("Frame")
	box.Name = "Icon"
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Active = false
	box.Parent = parent
	local picture = StatusText.sourceImage(source)
	if picture then
		-- The glyph stays underneath, in its own frame, until the picture has
		-- loaded here -- and for good if it never does (UIKit.whenPictureLoads).
		local fallback = Instance.new("Frame")
		fallback.Name = "Fallback"
		fallback.AnchorPoint = Vector2.new(0.5, 0.5)
		fallback.Position = UDim2.fromScale(0.5, 0.5)
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.BorderSizePixel = 0
		fallback.Active = false
		fallback.Parent = box
		StatusText.icon(fallback, kind, tint, size).Size = UDim2.fromScale(1, 1)
		local image = Instance.new("ImageLabel")
		image.Name = "Picture"
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Active = false
		image.Image = picture
		image.ScaleType = Enum.ScaleType.Fit
		image.ZIndex = 3
		image.Parent = box
		-- The glyph goes once the picture has loaded; the picture is never
		-- hidden (an unloaded one draws nothing, the glyph shows through).
		UIKit.whenPictureLoads(image, function(loaded: boolean)
			if loaded then
				fallback.Visible = false
			end
		end)
		return box
	end
	if kind == "blocked" then
		ring(box, tint, false, size)
		bar(box, "Bar", 0.5, 0.5, 0.64, 0.16, tint, -45)
	elseif kind == "success" then
		ring(box, tint, false, size)
		bar(box, "TickShort", 0.37, 0.57, 0.30, 0.16, tint, 45)
		bar(box, "TickLong", 0.57, 0.47, 0.50, 0.16, tint, -50)
	elseif kind == "warning" then
		ring(box, tint, true, size)
		bar(box, "Stem", 0.5, 0.42, 0.15, 0.30, tint)
		bar(box, "Dot", 0.5, 0.69, 0.15, 0.15, tint)
	elseif kind == "boost" then
		ring(box, tint, false, size)
		bar(box, "Shaft", 0.5, 0.60, 0.15, 0.38, tint)
		bar(box, "HeadLeft", 0.41, 0.40, 0.30, 0.15, tint, -45)
		bar(box, "HeadRight", 0.59, 0.40, 0.30, 0.15, tint, 45)
	else
		ring(box, tint, false, size)
		bar(box, "Dot", 0.5, 0.29, 0.15, 0.15, tint)
		bar(box, "Stem", 0.5, 0.61, 0.15, 0.32, tint)
	end
	return box
end

--==============================================================================
-- REDUCED MOTION
--
-- REDUCED FX in Settings ("HIDES TRAILS, SPARKS & UI MOTION") is the game's own
-- preference, the attribute UIKit's pops, SpeedFX, OfflineUI and the notices
-- read. Roblox's accessibility setting counts too, where the engine has it --
-- read through pcall, so an engine without the property simply says "motion on".
--==============================================================================
function StatusText.reducedMotion(): boolean
	local player = Players.LocalPlayer
	if player and player:GetAttribute(GameConfig.Afterimage.QualityAttribute) == "Off" then
		return true
	end
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

local function textWidth(text: string, size: number, font: Enum.Font): number
	if text == "" then
		return 0
	end
	return math.ceil(TextService:GetTextSize(text, size, font, Vector2.new(10000, 10000)).X)
end

--==============================================================================
-- THE SIZES, BY SCREEN
--
-- Built at the desktop size and drawn smaller where the notices are (compact
-- windows and every touch screen: ActionToastUI's SMALL), through `setScale`,
-- so a phone turned or a window dragged never rebuilds a line that is up.
-- `status` is the notices' own headline size, 26 and 21: a warning has to be
-- read at a glance. The boost row is a step down -- it is a reminder, not news.
--==============================================================================
StatusText.Size = { status = 26, boost = 17, boostClock = 15, run = 20, runClock = 17 }
StatusText.SmallScale = { status = 21 / 26, boost = 15 / 17, run = 17 / 20 }
-- A PHONE'S OWN (2026-09-29; HudLayout, THE PHONE'S TOP ROW): the boost row
-- stands in a slim band right under the top row, so its lines are drawn at 13
-- (their clocks at 11.5) where a small window draws them at 15; and the obby's
-- run clock, alone in the OBBY button's slot, is 15. The chase warning keeps
-- SmallScale's 21: a warning is read at a glance or not at all.
StatusText.PhoneScale = { boost = 13 / 17, runClock = 15 / 17 }

-- A remaining time as a clock: 0:07, 1:56, 12:04, and 1:02:03 past an hour.
function StatusText.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

--==============================================================================
-- ONE LINE
--==============================================================================
export type Options = {
	name: string,
	parent: Instance,
	-- The headline's text size, and its colour.
	size: number,
	tint: Color3,
	-- A glyph from the family above, drawn at about the headline's size.
	icon: string?,
	iconTint: Color3?,
	-- Where it came from (GameConfig.SourceIcons): its picture replaces the
	-- glyph once uploaded; until then the glyph is drawn. Needs `icon`.
	source: string?,
	-- A second, smaller part after the headline -- drawn only when this is set.
	detailSize: number?,
	detailFont: Enum.Font?,
	-- The headline's own face, when it is not the display face: a line that is
	-- only a clock (a phone's run clock, ObbyUI) is monospaced from its first
	-- digit, so it never jiggles.
	headFont: Enum.Font?,
	zIndex: number?,
}

export type Line = {
	frame: Frame,
	-- New words (and a new headline colour); returns the line's size. No motion.
	set: (head: string, detail: string?, tint: Color3?) -> Vector2,
	show: () -> (),
	-- Out on the notices' fade; `instant` for a line whose slot something else
	-- takes in the same frame (the warning, when TELEPORT TO PLOT comes up).
	hide: (instant: boolean?) -> (),
	nudge: () -> (),
	isShown: () -> boolean,
	-- The line's size as drawn: its words' size times its scale.
	size: () -> Vector2,
	-- Drawn this much smaller or larger, about its top middle (StatusText.SmallScale).
	setScale: (scale: number) -> (),
	-- A new glyph and source for a line built with an icon (the Rain line when
	-- its event turns out to be a Thunderstorm); the same size and place.
	setIcon: (kind: string, source: string?) -> (),
	destroy: () -> (),
}

function StatusText.new(opts: Options): Line
	local size = opts.size
	local glyphSize = if opts.icon then math.floor(size * 0.92 + 0.5) else 0
	local gap = math.max(4, math.floor(size * 0.3 + 0.5))
	local detailSize = opts.detailSize
	local detailFont = opts.detailFont or StatusText.DetailFont
	local headFont = opts.headFont or StatusText.HeadFont
	local rowH = math.max(glyphSize, size + 6)
	-- A source PICTURE is drawn a little larger than a glyph (2026-10-03): a
	-- detailed picture at a phone's 13/17 scale was ~12 px and mush. It grows
	-- only into the row's own height, so no band, rect or line moves for it.
	local pictureSize = math.min(rowH, math.floor(size * 1.18 + 0.5))
	local iconSize = glyphSize

	-- Anchored at its top middle: owners centre it on a HudLayout rect.
	local frame = Instance.new("Frame")
	frame.Name = opts.name
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Size = UDim2.fromOffset(0, rowH)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Visible = false
	if opts.zIndex then
		frame.ZIndex = opts.zIndex
	end
	frame.Parent = opts.parent
	-- The screen's scale, on the frame; the settle's own scale is on the body.
	local frameScale = Instance.new("UIScale")
	frameScale.Parent = frame

	-- Anchored at its middle, so the settle grows from the middle rather than
	-- from a corner, and the rise moves it without moving the frame an owner placed.
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.Position = UDim2.fromScale(0.5, 0.5)
	body.Size = UDim2.fromScale(1, 1)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Active = false
	body.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Parent = body

	-- Every instance whose transparency the fades move, with its resting value.
	local fades: { { target: Instance, prop: string, base: number } } = {}
	local function track(target: Instance, prop: string)
		table.insert(fades, { target = target, prop = prop, base = (target :: any)[prop] })
	end

	local icon: Frame? = nil
	local iconKey = ""
	local function drawIcon(kind: string, source: string?)
		iconSize = if StatusText.sourceImage(source) then pictureSize else glyphSize
		local drawn = StatusText.icon(body, kind, opts.iconTint or opts.tint, iconSize, source)
		drawn.AnchorPoint = Vector2.new(0, 0.5)
		drawn.Position = UDim2.new(0, 0, 0.5, 0)
		for _, part in ipairs(drawn:GetDescendants()) do
			if part:IsA("UIStroke") then
				track(part, "Transparency")
			elseif part:IsA("Frame") and part.BackgroundTransparency < 1 then
				track(part, "BackgroundTransparency")
			elseif part:IsA("ImageLabel") then
				track(part, "ImageTransparency")
			end
		end
		icon = drawn
		iconKey = kind .. "|" .. tostring(StatusText.sourceImage(source))
	end
	if opts.icon then
		drawIcon(opts.icon, opts.source)
	end

	local head = Instance.new("TextLabel")
	head.Name = "Head"
	head.AnchorPoint = Vector2.new(0, 0.5)
	head.BackgroundTransparency = 1
	head.Font = headFont
	head.TextSize = size
	head.TextColor3 = opts.tint
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.Text = ""
	head.Parent = body
	local headEdge = UIKit.stroke(head, Notice.Outline, 2, 0.1)
	track(head, "TextTransparency")
	track(headEdge, "Transparency")

	local detail: TextLabel? = nil
	if detailSize then
		local d = Instance.new("TextLabel")
		d.Name = "Detail"
		d.AnchorPoint = Vector2.new(0, 0.5)
		d.BackgroundTransparency = 1
		d.Font = detailFont
		d.TextSize = detailSize
		d.TextColor3 = Notice.DetailColour
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.Text = ""
		d.Visible = false
		d.Parent = body
		local detailEdge = UIKit.stroke(d, Notice.Outline, 1.5, 0.15)
		track(d, "TextTransparency")
		track(detailEdge, "Transparency")
		detail = d
	end

	local alpha = Instance.new("NumberValue")
	alpha.Value = 1
	local function apply()
		local a = alpha.Value
		for _, f in ipairs(fades) do
			(f.target :: any)[f.prop] = f.base + (1 - f.base) * a
		end
	end
	alpha.Changed:Connect(apply)
	apply()

	local measured = Vector2.new(0, rowH)

	local function set(headText: string, detailText: string?, tint: Color3?): Vector2
		if tint then
			head.TextColor3 = tint
		end
		local x = if icon then iconSize + gap else 0
		if head.Text ~= headText then
			head.Text = headText
		end
		local hw = textWidth(headText, size, headFont) + 4
		head.Position = UDim2.new(0, x, 0.5, 1)
		head.Size = UDim2.fromOffset(hw, size + 6)
		x += hw
		local d = detail
		if d and detailSize then
			local text = detailText or ""
			if d.Text ~= text then
				d.Text = text
			end
			if text ~= "" then
				local dw = textWidth(text, detailSize, detailFont) + 4
				x += gap
				d.Position = UDim2.new(0, x, 0.5, 1)
				d.Size = UDim2.fromOffset(dw, detailSize + 6)
				d.Visible = true
				x += dw
			else
				d.Visible = false
			end
		end
		measured = Vector2.new(x, rowH)
		frame.Size = UDim2.fromOffset(x, rowH)
		return measured
	end

	local shown = false
	local token = 0
	local running: { Tween } = {}
	local function stop()
		for _, tween in ipairs(running) do
			tween:Cancel()
		end
		table.clear(running)
	end
	local function play(target: Instance, info: TweenInfo, goal: { [string]: any }): Tween
		local tween = TweenService:Create(target, info, goal)
		table.insert(running, tween)
		tween:Play()
		return tween
	end

	local function show()
		if shown then
			return
		end
		shown = true
		token += 1
		stop()
		frame.Visible = true
		local enter = Notice.EnterSeconds * Notice.TimeScale
		if StatusText.reducedMotion() then
			body.Position = UDim2.fromScale(0.5, 0.5)
			scale.Scale = 1
			play(alpha, TweenInfo.new(enter, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 0 })
			return
		end
		-- From below and a touch small only when it was fully gone; a line
		-- brought back mid-fade just comes back from where it is.
		if alpha.Value >= 0.999 then
			body.Position = UDim2.new(0.5, 0, 0.5, Notice.RisePixels)
			scale.Scale = Notice.StartScale
		end
		local info = TweenInfo.new(enter, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		play(alpha, info, { Value = 0 })
		play(body, info, { Position = UDim2.fromScale(0.5, 0.5) })
		play(scale, info, { Scale = 1 })
	end

	local function hide(instant: boolean?)
		if not shown then
			-- Already on its way out: an instant hide still ends the fade now.
			if instant and frame.Visible then
				token += 1
				stop()
				alpha.Value = 1
				frame.Visible = false
				body.Position = UDim2.fromScale(0.5, 0.5)
				scale.Scale = 1
			end
			return
		end
		shown = false
		token += 1
		local mine = token
		stop()
		if instant then
			alpha.Value = 1
			frame.Visible = false
			body.Position = UDim2.fromScale(0.5, 0.5)
			scale.Scale = 1
			return
		end
		local info = TweenInfo.new(Notice.ExitSeconds * Notice.TimeScale, Enum.EasingStyle.Quad,
			Enum.EasingDirection.In)
		local fade = play(alpha, info, { Value = 1 })
		if not StatusText.reducedMotion() then
			play(body, info, { Position = UDim2.new(0.5, 0, 0.5, -4) })
		end
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and mine == token then
				frame.Visible = false
				body.Position = UDim2.fromScale(0.5, 0.5)
				scale.Scale = 1
			end
		end)
	end

	local function nudge()
		if not shown or StatusText.reducedMotion() then
			return
		end
		scale.Scale = Notice.NudgeScale
		play(scale, TweenInfo.new(Notice.NudgeSeconds * Notice.TimeScale, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Scale = 1 })
	end

	local function destroy()
		stop()
		alpha:Destroy()
		frame:Destroy()
	end

	return {
		frame = frame,
		set = set,
		show = show,
		hide = hide,
		nudge = nudge,
		isShown = function(): boolean
			return shown
		end,
		size = function(): Vector2
			return measured * frameScale.Scale
		end,
		setScale = function(k: number)
			frameScale.Scale = k
		end,
		setIcon = function(kind: string, source: string?)
			local old = icon
			if not old or iconKey == kind .. "|" .. tostring(StatusText.sourceImage(source)) then
				return
			end
			-- Its fades go with it; the new one starts at the line's own alpha.
			for i = #fades, 1, -1 do
				local target = fades[i].target
				if target == old or target:IsDescendantOf(old) then
					table.remove(fades, i)
				end
			end
			old:Destroy()
			drawIcon(kind, source)
			apply()
		end,
		destroy = destroy,
	}
end

return StatusText
