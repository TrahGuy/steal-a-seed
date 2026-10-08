--!strict
-- Steal a Seed :: ActionToastUI
--
-- The game's short notifications, drawn: a refused action, a small success, a
-- warning, a passing piece of information. One renderer for all of them
-- (Notice.setRenderer), so there is one look, one stack and one set of sound
-- rules, whoever posts.
--
--==============================================================================
-- WHAT ARRIVES, AND FROM WHERE
--
--   the GameEvent remote   verb ActionRefusal.Action and a code, sent by the
--                          server guard that already refused -- a trap in the
--                          Safe Zone, a swing at a protected player, a plot too
--                          far away or full, a second pod, a teleport
--   Notice.post            any client script: ActionRefusal.raise for the one
--                          refusal the client knows first (a plant in your
--                          hands while a raided pod is in your arms), the Bonus
--                          Chest's answer, and whatever else posts a notice
--
-- A refusal code nobody named is ignored, so nothing internal reaches the
-- screen. Nothing here is read back by anything; what a notice reports has
-- already happened.
--
--==============================================================================
-- THE LOOK (2026-09-27): TEXT, NOT A PILL
--
-- No plate behind it. A headline in the kind's colour, in the HUD's display
-- face with a dark outline; under it, when there is one, a smaller warm-white
-- line with the next step; to the headline's left a small icon drawn from
-- frames -- a ring with a bar through it, a tick, a diamond with "!", an "i".
-- The outline is what carries it over bright grass, pale sky and the night.
--
--==============================================================================
-- THE MOTION
--
-- In: a short rise and a small scale settle, quint-out, no overshoot. Up for
-- long enough to read (Notice.holdFor). Out: a fade with a few pixels of drift.
-- A repeat of the same notice gives a small nudge instead of a new one. Reduced
-- motion -- Settings' REDUCED FX, or Roblox's own setting -- drops the rise, the
-- settle, the nudge and the sliding, and keeps the fades. Nothing shakes,
-- flashes or bounces.
--
-- NO LOOP. Tweens and a task.delay per notice, with a token so a refreshed
-- notice's newer timer owns its exit. The only repeating check is for a notice
-- that carries `stillTrue`, and only while one is up.
--
--==============================================================================
-- WHERE, AND UNDER WHAT
--
-- HudLayout's `toast`: the newest notice sits there, over the belt, and older
-- ones stand above it -- never more than the stack allows, and never up into
-- the middle of the screen, where the controller's reticle is. DisplayOrder 13,
-- so it draws UNDER the hatch timers (14), the prompts (15), the cash and speed
-- (20), the belt (30) and every panel. Nothing in it can take input: no button,
-- nothing Active, nothing Selectable, so a tap, a click or a controller's
-- selection goes straight past it.
--==============================================================================

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local Notice = require(Shared:WaitForChild("Notice"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HEAD_FONT = Enum.Font.LuckiestGuy
local DETAIL_FONT = Enum.Font.GothamBold

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedToast")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedToast"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 13
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

-- The column the notices stand in: its bottom edge is the toast rect's.
local column = Instance.new("Frame")
column.Name = "Stack"
column.AnchorPoint = Vector2.new(0.5, 1)
column.BackgroundTransparency = 1
column.BorderSizePixel = 0
column.Active = false
column.Parent = gui

--==============================================================================
-- SIZES, BY SCREEN
--==============================================================================
type Metrics = { head: number, headMin: number, detail: number, detailMin: number, icon: number, gap: number, between: number }

local FULL: Metrics = { head = 26, headMin = 18, detail = 15, detailMin = 12, icon = 24, gap = 2, between = 8 }
local SMALL: Metrics = { head = 21, headMin = 16, detail = 13, detailMin = 11, icon = 20, gap = 1, between = 6 }
--==============================================================================
-- A PHONE'S NOTICES STAND AT THE TOP, AND STACK DOWN (2026-09-29)
--
-- The owner's report, from a phone: "large success notifications fill much of
-- the middle of the screen", and a notice "should not linger over the character
-- or the next jump". Over the belt is exactly that on a phone: the character's
-- own feet, and on the obby the leaf they are about to land on.
--
-- So where HudLayout says `toastTop` -- every touch screen with room for it --
-- the stack hangs from the top of the centre column, under the clock's row: the
-- newest notice at the top, an older one under it, never past the middle of the
-- screen. A size smaller again than a small window's (18 and 12), and the same
-- words, colours, icons, sounds and rules. Everywhere else the stack stands on
-- the belt, as it did.
--
-- BACK OVER THE BELT, SMALL (2026-10-04, the owner's order for every screen:
-- the hotbar, the active icons right over it, the short notices just over
-- those). HudLayout no longer says `toastTop`; a phone's stack stands on the
-- toast rect over the icon row and keeps this size -- one notice at a time on
-- a short phone, so it never climbs over the character (noticeStack's middle
-- band).
--==============================================================================
local PHONE: Metrics = { head = 18, headMin = 14, detail = 12, detailMin = 11, icon = 17, gap = 1, between = 4 }
-- What the stack keeps between its foot and the middle of the screen.
local CONFIG_GAP = HudLayout.Config.Gap

local metrics: Metrics = FULL
local maxShown = Notice.MaxShown
local width = 340
-- Hanging from the top (a phone) rather than standing on the belt; where the
-- stack's top edge is, in this gui's space; and the least depth it is allowed.
local fromTop = false
local stackTop = 0
local stackDepth = 0

-- REDUCED FX in Settings ("HIDES TRAILS, SPARKS & UI MOTION") is the game's
-- own preference: the same attribute UIKit's pops, SpeedFX and OfflineUI read.
-- Roblox's accessibility setting counts too, where the engine has it -- read
-- through pcall, so an engine without the property simply says "motion on".
-- A duration, as the renderer runs it (Notice.TimeScale is 1 in the game).
local function secs(seconds: number): number
	return seconds * Notice.TimeScale
end

local function reducedMotion(): boolean
	if player:GetAttribute(GameConfig.Afterimage.QualityAttribute) == "Off" then
		return true
	end
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

--==============================================================================
-- THE ICONS, FROM FRAMES: StatusText.icon (moved there 2026-09-27, unchanged,
-- so the notices and the lasting indicators draw one family). A dark ring under
-- a coloured ring, and a coloured glyph with a thin dark edge.
--==============================================================================

--==============================================================================
-- ONE NOTICE ON SCREEN
--==============================================================================
type Drawn = {
	key: string,
	post: Notice.Post,
	frame: Frame,
	body: Frame,
	scale: UIScale,
	alpha: NumberValue,
	height: number,
	token: number,
	-- The two lines, so a refresh with new words (a cooldown's time) can say them.
	headLabel: TextLabel?,
	detailLabel: TextLabel?,
	leaving: boolean,
	-- Every instance whose transparency the fades move, with its resting value.
	fades: { { target: Instance, prop: string, base: number } },
	-- The close button of a notice the player may take down (Notice's
	-- `dismissible`); nil on every other notice.
	close: TextButton?,
}

local drawn: { Drawn } = {}
local stack: { Notice.Shown } = {}
local sounds = Notice.newSoundState()

local function applyAlpha(d: Drawn)
	local a = d.alpha.Value
	for _, f in ipairs(d.fades) do
		(f.target :: any)[f.prop] = f.base + (1 - f.base) * a
	end
end

local function track(d: Drawn, target: Instance, prop: string)
	table.insert(d.fades, { target = target, prop = prop, base = (target :: any)[prop] })
end

local function textWidth(text: string, size: number, font: Enum.Font): number
	return TextService:GetTextSize(text, size, font, Vector2.new(10000, 10000)).X
end

-- The headline's size: as large as the screen allows, stepped down to fit.
local function headSize(title: string, room: number): number
	local size = metrics.head
	while size > metrics.headMin and textWidth(title, size, HEAD_FONT) > room do
		size -= 1
	end
	return size
end

local function build(post: Notice.Post, key: string): Drawn
	local style = Notice.Styles[post.kind]
	local frame = Instance.new("Frame")
	frame.Name = "Notice"
	frame.AnchorPoint = if fromTop then Vector2.new(0.5, 0) else Vector2.new(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Parent = column

	-- Anchored at its middle, so the scale settle grows from the middle rather
	-- than from the top-left corner.
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

	local alpha = Instance.new("NumberValue")
	alpha.Value = 1
	local d: Drawn = {
		key = key,
		post = post,
		frame = frame,
		body = body,
		scale = scale,
		alpha = alpha,
		height = 0,
		token = 0,
		headLabel = nil,
		detailLabel = nil,
		leaving = false,
		fades = {},
		close = nil,
	}

	-- The headline row: icon, a small gap, the words -- centred as one. A notice
	-- the player may dismiss keeps its close button's width clear on BOTH sides,
	-- so the row stays centred and never runs under the button.
	local iconSize = metrics.icon
	local closeW = if post.dismissible == true then iconSize + 6 else 0
	local room = width - iconSize - 8 - closeW * 2
	local hs = headSize(post.title, room)
	local headW = math.min(room, textWidth(post.title, hs, HEAD_FONT))
	-- A headline still wider than the room at the smallest size wraps onto a
	-- second line (2026-10-02, the Rain toast's): the row grows to hold it, so
	-- the words never run out under the icon.
	local wrapped = textWidth(post.title, hs, HEAD_FONT) > room
	local headH = if wrapped
		then TextService:GetTextSize(post.title, hs, HEAD_FONT, Vector2.new(room, 10000)).Y
		else hs
	-- The Secret toast's word (2026-10-05) stands wherever the sentence puts it
	-- -- "A SECRET EGG SPAWNED ON ..." -- so its headline is broken into lines
	-- here rather than by the engine, and the word's place on its line is known.
	local span: Notice.WordSpan? = nil
	if post.kind == "secret" then
		local found = Notice.wordSpan(post.title, GameConfig.Secret.Toast.Word, room, function(text: string): number
			return textWidth(text, hs, HEAD_FONT)
		end)
		if found.line then
			span = found
			headW = found.width
			wrapped = #found.lines > 1
			headH = if wrapped
				then TextService:GetTextSize(table.concat(found.lines, "\n"), hs, HEAD_FONT, Vector2.new(10000, 10000)).Y
				else hs
		end
	end
	local rowW = iconSize + 8 + headW
	local rowH = math.max(iconSize, headH + 4)

	local row = Instance.new("Frame")
	row.Name = "Headline"
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 0)
	row.Size = UDim2.fromOffset(rowW, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = body

	-- The kind's glyph, or the picture of where it came from once uploaded.
	local icon = StatusText.icon(row, post.kind, style.tint, iconSize, post.icon)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 0, 0.5, 0)

	local head = Instance.new("TextLabel")
	head.Name = "Title"
	head.AnchorPoint = Vector2.new(1, 0.5)
	head.Position = UDim2.new(1, 0, 0.5, 1)
	head.Size = UDim2.fromOffset(headW + 2, rowH)
	head.BackgroundTransparency = 1
	head.Font = HEAD_FONT
	head.TextSize = hs
	head.TextWrapped = wrapped
	head.TextColor3 = style.tint
	head.TextXAlignment = Enum.TextXAlignment.Center
	head.Text = post.title
	head.Parent = row
	d.headLabel = head
	local headEdge = UIKit.stroke(head, Notice.Outline, 2, 0.1)
	track(d, head, "TextTransparency")
	track(d, headEdge, "Transparency")

	--==========================================================================
	-- THE WORD "SECRET" (2026-10-01): italic, silver, a strong dark outline and a
	-- smooth grey sweep -- on the Secret egg toast only, to the owner's
	-- reference. The headline keeps the word as INVISIBLE text so the row is
	-- measured and centred as one; this label draws the word over it. Under
	-- reduced motion the sweep is a still silver-to-white.
	--
	-- WHEREVER IT STANDS (2026-10-05). The sentence now starts "A SECRET ...",
	-- so the word's place is wordSpan's: its line, and its left edge with each
	-- line centred. The label is centred on the invisible word, so the italic
	-- face spreads evenly either side of where the headline's word would be.
	--==========================================================================
	if span then
		local word = GameConfig.Secret.Toast.Word
		local line = span.line :: number
		local lines = table.clone(span.lines)
		lines[line] = string.sub(lines[line], 1, span.at - 1)
			.. string.format('<font transparency="1">%s</font>', word)
			.. string.sub(lines[line], span.at + #word)
		head.TextWrapped = false
		head.RichText = true
		head.Text = table.concat(lines, "\n")
		-- Each line's band: the text stands centred in the row, one line height
		-- per line.
		local lineH = headH / #span.lines
		local centreY = (rowH - headH) / 2 + (line - 0.5) * lineH
		local secret = Instance.new("TextLabel")
		secret.Name = "SecretWord"
		secret.AnchorPoint = Vector2.new(0.5, 0.5)
		-- The headline label is 2 px wider than its widest line, the lines
		-- centred in it: 1 px in.
		secret.Position = UDim2.fromOffset(1 + span.x + span.w / 2, centreY)
		secret.Size = UDim2.fromOffset(span.w + 4, lineH)
		secret.BackgroundTransparency = 1
		secret.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
		secret.TextSize = hs
		secret.TextColor3 = Color3.fromRGB(255, 255, 255)
		secret.TextXAlignment = Enum.TextXAlignment.Center
		secret.Text = word
		secret.Parent = head
		local edge = UIKit.stroke(secret, Notice.Outline, 2.5, 0)
		track(d, secret, "TextTransparency")
		track(d, edge, "Transparency")
		local sweep = Instance.new("UIGradient")
		if reducedMotion() then
			sweep.Color = ColorSequence.new(Color3.fromRGB(196, 196, 208), Color3.fromRGB(255, 255, 255))
		else
			-- Silver at rest; a dark edge leading a white light crosses it.
			sweep.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(186, 186, 198)),
				ColorSequenceKeypoint.new(0.36, Color3.fromRGB(58, 58, 68)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.64, Color3.fromRGB(186, 186, 198)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(186, 186, 198)),
			})
			-- A looping tween, not a per-frame hook: a toast is an event, and
			-- the tween ends with the label it moves.
			sweep.Offset = Vector2.new(-1, 0)
			TweenService:Create(sweep, TweenInfo.new(GameConfig.Secret.Toast.SweepSeconds,
				Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Offset = Vector2.new(1, 0) }):Play()
		end
		sweep.Parent = secret
	end

	local total = rowH
	if post.detail and post.detail ~= "" then
		-- Up to two lines, stepped down a size before it would need a third.
		local ds = metrics.detail
		local bounds = TextService:GetTextSize(post.detail, ds, DETAIL_FONT, Vector2.new(width, 10000))
		while ds > metrics.detailMin and bounds.Y > ds * 2.6 do
			ds -= 1
			bounds = TextService:GetTextSize(post.detail, ds, DETAIL_FONT, Vector2.new(width, 10000))
		end
		local line = Instance.new("TextLabel")
		line.Name = "Detail"
		line.AnchorPoint = Vector2.new(0.5, 0)
		line.Position = UDim2.new(0.5, 0, 0, rowH + metrics.gap)
		line.Size = UDim2.fromOffset(width, bounds.Y + 2)
		line.BackgroundTransparency = 1
		line.Font = DETAIL_FONT
		line.TextSize = ds
		line.TextWrapped = true
		line.TextColor3 = Notice.DetailColour
		line.TextXAlignment = Enum.TextXAlignment.Center
		line.Text = post.detail
		line.Parent = body
		d.detailLabel = line
		local lineEdge = UIKit.stroke(line, Notice.Outline, 1.5, 0.15)
		track(d, line, "TextTransparency")
		track(d, lineEdge, "Transparency")
		total += metrics.gap + bounds.Y + 2
	end

	--==========================================================================
	-- THE CLOSE BUTTON, on a notice the player may take down (2026-10-01)
	--
	-- The panels' own close button, at a notice's size: a red plate with an
	-- outlined X at the headline row's right end, inside a 44 px press that is
	-- the button (UIKit.modal's rule: the target grows, the plate does not).
	-- Selectable, so the UI's own selection reaches it on a controller. It fades
	-- with the notice; show() connects the press.
	--==========================================================================
	if post.dismissible == true then
		local LOOK = GameConfig.BagLook
		local close = Instance.new("TextButton")
		close.Name = "Close"
		close.AnchorPoint = Vector2.new(0.5, 0.5)
		close.Position = UDim2.new(1, -closeW / 2, 0, rowH / 2)
		close.Size = UDim2.fromOffset(44, 44)
		close.BackgroundTransparency = 1
		close.BorderSizePixel = 0
		close.AutoButtonColor = false
		close.Selectable = true
		close.Text = ""
		close.ZIndex = 4
		close.Parent = body
		UIKit.clicks(close)
		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromScale(0.5, 0.5)
		plate.Size = UDim2.fromOffset(iconSize, iconSize)
		plate.BackgroundColor3 = Color3.new(1, 1, 1)
		plate.BorderSizePixel = 0
		plate.Active = false
		plate.ZIndex = 4
		plate.Parent = close
		UIKit.corner(plate, 6)
		local plateEdge = UIKit.stroke(plate, Notice.Outline, 1.5)
		-- The menus' own close red (the global UI pass, 2026-10-04): coral to red
		-- over its darker foot, the same on every close.
		local tint = UIKit.gradient(plate, LOOK.CloseTop, LOOK.CloseBottom)
		tint.Color = UIKit.footColours(LOOK.CloseTop, LOOK.CloseBottom, LOOK.CloseShade)
		local mark = UIKit.outlined(plate, "Mark", math.max(10, math.floor(iconSize * 0.7)), Color3.new(1, 1, 1), 1.5)
		mark.Size = UDim2.fromScale(1, 1)
		mark.ZIndex = 5
		mark.Text = "X"
		track(d, plate, "BackgroundTransparency")
		track(d, plateEdge, "Transparency")
		track(d, mark, "TextTransparency")
		local markEdge = mark:FindFirstChildOfClass("UIStroke")
		if markEdge then
			track(d, markEdge, "Transparency")
		end
		d.close = close
	end

	-- The icon's rings are strokes and its glyph is fills with strokes.
	for _, part in ipairs(icon:GetDescendants()) do
		if part:IsA("UIStroke") then
			track(d, part, "Transparency")
		elseif part:IsA("Frame") and part.BackgroundTransparency < 1 then
			track(d, part, "BackgroundTransparency")
		elseif part:IsA("ImageLabel") then
			track(d, part, "ImageTransparency")
		end
	end

	d.height = total
	frame.Size = UDim2.fromOffset(width, total)
	alpha.Changed:Connect(function()
		applyAlpha(d)
	end)
	applyAlpha(d)
	return d
end

--==============================================================================
-- THE STACK'S SLOTS: NEWEST AT THE BOTTOM
--==============================================================================
local function slotTween(d: Drawn, y: number, instant: boolean)
	-- Up from the belt, or down from the top of the column.
	local goal = if fromTop then UDim2.new(0.5, 0, 0, y) else UDim2.new(0.5, 0, 1, -y)
	if instant or reducedMotion() then
		d.frame.Position = goal
		return
	end
	-- Quint-out: the older notices are most of the way clear of the slot by the
	-- time a newcomer (which waits SlideLead for them) starts to show.
	TweenService:Create(d.frame, TweenInfo.new(secs(0.2), Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = goal }):Play()
end

local function restack(newest: Drawn?)
	local y = 0
	local standing = 0
	for i = #drawn, 1, -1 do
		local d = drawn[i]
		if not d.leaving then
			slotTween(d, y, d == newest)
			y += d.height + metrics.between
			standing += 1
		end
	end
	-- Where the stack's foot is, for what shares its band on a phone (Notice,
	-- WHERE THE STACK STANDS); nothing to say where it stands on the belt.
	Notice.setReach(if fromTop and y > 0 then stackTop + y - metrics.between else nil)
	-- And how many stand, on every screen: the guide's spotlight waits while any
	-- does (Notice, HOW MANY NOTICES ARE STANDING, 2026-10-08).
	Notice.setShowing(standing)
end

local function forget(d: Drawn)
	for i, other in ipairs(drawn) do
		if other == d then
			table.remove(drawn, i)
			break
		end
	end
	d.alpha:Destroy()
	d.frame:Destroy()
end

local function leave(d: Drawn, seconds: number)
	if d.leaving then
		return
	end
	d.leaving = true
	-- Out of the stack's count at once, so a notice arriving during this fade
	-- gets the room; the slots close up behind it.
	Notice.remove(stack, d.key)
	restack(nil)
	local info = TweenInfo.new(secs(seconds), Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fade = TweenService:Create(d.alpha, info, { Value = 1 })
	if not reducedMotion() then
		TweenService:Create(d.body, info, { Position = UDim2.new(0.5, 0, 0.5, -4) }):Play()
	end
	fade.Completed:Once(function()
		forget(d)
	end)
	fade:Play()
end

local function schedule(d: Drawn, hold: number)
	d.token += 1
	local mine = d.token
	task.delay(secs(Notice.EnterSeconds + hold), function()
		if mine == d.token and d.frame.Parent then
			leave(d, Notice.ExitSeconds)
		end
	end)
end

-- Notices that carry `stillTrue` are asked again while they are up; one that
-- has stopped being true leaves at once. A delay that re-arms itself only while
-- such a notice is up -- no loop, and nothing at all the rest of the time.
local watching = false
local function recheck()
	local any = false
	for _, d in ipairs(table.clone(drawn)) do
		local still = d.post.stillTrue
		if still and not d.leaving then
			local ok, answer = pcall(still)
			if ok and answer == true then
				any = true
			else
				leave(d, Notice.EvictSeconds)
			end
		end
	end
	if any then
		task.delay(secs(Notice.RecheckSeconds), recheck)
	else
		watching = false
	end
end

local function watch()
	if not watching then
		watching = true
		task.delay(secs(Notice.RecheckSeconds), recheck)
	end
end

local function nudge(d: Drawn)
	if reducedMotion() then
		return
	end
	local half = secs(Notice.NudgeSeconds / 2)
	local up = TweenService:Create(d.scale, TweenInfo.new(half, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), { Scale = Notice.NudgeScale })
	up.Completed:Once(function()
		TweenService:Create(d.scale, TweenInfo.new(half, Enum.EasingStyle.Quad,
			Enum.EasingDirection.In), { Scale = 1 }):Play()
	end)
	up:Play()
end

local function show(post: Notice.Post)
	if not Notice.valid(post) or gui.Parent == nil then
		return
	end
	local now = Notice.now()
	local key = Notice.keyOf(post)

	-- A notice that FOLLOWS another (2026-10-05: a storm's Secret egg after the
	-- storm's own opening) waits while going up would put that one out before
	-- it is read -- a stack with room for one, on a short phone -- and goes up
	-- as it starts to leave. Once: the copy that waited follows nothing.
	local after = post.after
	if after then
		local wait = Notice.waitAfter(stack, after, now, maxShown)
		if wait > 0 then
			local later = table.clone(post)
			later.after = nil
			task.delay(secs(wait), show, later)
			return
		end
	end

	-- ONE KEY, ONE NOTICE, and the screen is what decides it: the same notice
	-- still up is refreshed where it is -- its clock restarts, it nudges, it
	-- makes no sound -- whatever the rules' own record says about its time.
	local live: Drawn? = nil
	for _, d in ipairs(drawn) do
		if d.key == key and not d.leaving then
			live = d
			break
		end
	end
	if live then
		-- New words for the same notice (a cooldown's time left) are said in
		-- place when they fit the lines it has; otherwise it makes way for a
		-- fresh one below.
		local sameShape = post.title == live.post.title
			and (post.detail ~= nil) == (live.detailLabel ~= nil)
		if sameShape then
			local recorded = false
			for _, shown in ipairs(stack) do
				if shown.key == key then
					shown.hideAt = now + Notice.lifeOf(post)
					shown.count += 1
					recorded = true
				end
			end
			if not recorded then
				table.insert(stack, { key = key, kind = post.kind, bornAt = now,
					hideAt = now + Notice.lifeOf(post), count = 2 })
			end
			local detailLabel = live.detailLabel
			if detailLabel and post.detail then
				detailLabel.Text = post.detail
			end
			live.post = post
			schedule(live, Notice.holdFor(post))
			nudge(live)
			return
		end
		leave(live, Notice.EvictSeconds)
	end
	local madeRoom = live ~= nil

	-- A new notice: the stack rule decides who makes room.
	local verdict, _, evicted = Notice.step(stack, post, now, maxShown)
	if verdict == "refresh" then
		-- The rules still remember one whose drawing has already gone.
		Notice.remove(stack, key)
		verdict, _, evicted = Notice.step(stack, post, now, maxShown)
	end
	for _, gone in ipairs(evicted) do
		for _, d in ipairs(drawn) do
			if d.key == gone.key and not d.leaving then
				leave(d, Notice.EvictSeconds)
			end
		end
	end

	local others = 0
	for _, other in ipairs(drawn) do
		if not other.leaving then
			others += 1
		end
	end
	local d = build(post, key)
	table.insert(drawn, d)
	-- Taken down by the player (Notice's `dismissible`): it leaves as it would
	-- at the end of its time, and the poster hears so, once.
	local close = d.close
	if close then
		close.Activated:Connect(function()
			if d.leaving then
				return
			end
			leave(d, Notice.ExitSeconds)
			local told = d.post.onDismissed
			if told then
				task.spawn(told)
			end
		end)
	end
	-- Hanging from the top, the stack has a depth as well as a count: a notice
	-- with two lines under it is taller than the one the count was worked out
	-- for. The oldest make way until the newest fits whole. The depth is asked
	-- NOW rather than kept from the last layout: measured 2026-09-29, the
	-- camera's size had not settled when the gui was first placed, and a depth
	-- kept from then was 27 px too shallow for the rest of the session.
	if fromTop then
		local camera = workspace.CurrentCamera
		local middle = if camera then camera.ViewportSize.Y / 2 - GuiService:GetGuiInset().Y else 0
		local depth = math.max(stackDepth, middle - CONFIG_GAP - stackTop)
		local deep = d.height
		for i = #drawn - 1, 1, -1 do
			local older = drawn[i]
			if not older.leaving then
				deep += older.height + metrics.between
				if deep > depth then
					leave(older, Notice.EvictSeconds)
				end
			end
		end
	end
	restack(d)
	local still = reducedMotion()
	d.body.Position = UDim2.new(0.5, 0, 0.5, if still then 0 else Notice.RisePixels)
	d.scale.Scale = if still then 1 else Notice.StartScale
	-- With others up, it waits a beat while they slide up out of its slot; when
	-- one had to make room, it waits for that one's fade -- the evicted notice
	-- can be the one in the very slot it rises into. Never drawn over each other.
	local lead = if still then 0
		elseif madeRoom or #evicted > 0 then secs(Notice.EvictSeconds)
		elseif others > 0 then secs(Notice.SlideLead)
		else 0
	local info = TweenInfo.new(secs(Notice.EnterSeconds), Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
		0, false, lead)
	TweenService:Create(d.alpha, info, { Value = 0 }):Play()
	if not still then
		TweenService:Create(d.body, info, { Position = UDim2.fromScale(0.5, 0.5) }):Play()
		TweenService:Create(d.scale, info, { Scale = 1 }):Play()
	end
	schedule(d, Notice.holdFor(post))
	if post.stillTrue then
		watch()
	end

	-- A cue that is missing, or a player who muted SOUND FX, plays nothing:
	-- SoundKit routes it through the UI bus, whose level is the player's.
	-- It sounds when it shows: a newcomer that waited its lead waits to play too.
	local cue = Notice.soundFor(sounds, post, now)
	if cue and SoundKit.has(cue) then
		if lead > 0 then
			task.delay(lead, SoundKit.play, cue)
		else
			SoundKit.play(cue)
		end
	end
end

--==============================================================================
-- PLACED BY HudLAYOUT, ASKED AGAIN ONLY WHEN THE SCREEN CHANGES SHAPE
--
-- The stack stands on the toast rect and may grow up to maxShown notices --
-- fewer where that would reach the middle band, where the controller's reticle
-- and its reason line sit.
--==============================================================================
local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local small = layout.compact or layout.sidebar
	fromTop = layout.toastTop
	-- A phone's notices are the phone's size wherever they stand.
	metrics = if fromTop or layout.sidebar then PHONE elseif small then SMALL else FULL
	width = math.max(160, layout.toast.w)
	-- The window's middle, in this gui's safe space: the reticle's band.
	local camera = workspace.CurrentCamera
	local middle = if camera then camera.ViewportSize.Y / 2 - GuiService:GetGuiInset().Y else 0
	local one = metrics.head + 4 + metrics.gap + metrics.detail + 4 + metrics.between
	local most = if small then Notice.MaxShownCompact else Notice.MaxShown
	local area, count = HudLayout.noticeStack(layout, one, most, middle)
	-- On the belt the stack is counted: HudLayout says how many of the tallest
	-- notice fit. Hanging from the top it is MEASURED instead (stackDepth, in
	-- show): two short notices -- CHECKPOINT and the next stage's name -- fit
	-- where two of the tallest would not, and counting would have the second
	-- put the first out the moment it arrived.
	maxShown = if fromTop then most else count
	-- On the belt the column stands on its bottom edge; at the top it hangs from
	-- its top edge, and may grow down to the middle of the screen and no further.
	local anchor = if fromTop then Vector2.new(0.5, 0) else Vector2.new(0.5, 1)
	stackTop = area.y
	-- The least the stack may be: one notice's own band. How much deeper it may
	-- grow is asked when a notice arrives (show).
	stackDepth = area.h
	column.AnchorPoint = anchor
	column.Position = HudLayout.place(area, anchor, layout.safe)
	column.Size = UDim2.fromOffset(width, area.h)
	for _, d in ipairs(drawn) do
		d.frame.AnchorPoint = anchor
	end
	restack(nil)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
-- The active-boost icon row (BoostIconsUI, 2026-10-04) stands over the belt
-- and the toast line steps up over it: asked again whenever its count changes.
Players.LocalPlayer:GetAttributeChangedSignal(GameConfig.BoostIcons.Attribute):Connect(place)
-- And a trap's REMOVE row (LoadoutUI, 2026-10-04): the toast steps up over it too.
Players.LocalPlayer:GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(place)
-- And the x2 card coming or going (2026-10-05): on a narrow phone the belt keeps
-- 8 px off it beside the cash line, and the toast stands over the belt.
Players.LocalPlayer:GetAttributeChangedSignal(GameConfig.Pass.MultiplierAttribute):Connect(place)
-- On a phone the stack hangs under the clock's row, which moves with the
-- topbar's free span (Roblox's own buttons coming and going).
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
place()

--==============================================================================
-- THE TWO WAYS A NOTICE ARRIVES
--==============================================================================
Notice.setRenderer(show)

-- The Secret egg toast's biome names: the biomes' own, and the weather's
-- biome's label. Anything else has no name to show (Notice.secretPost).
local function biomeName(id: string): string?
	if id == GameConfig.Weather.Biome.Id then
		return GameConfig.Weather.Biome.Label
	end
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Id == id then
			return biome.DisplayName
		end
	end
	return nil
end
-- The spawns this client has shown, for the session (the script runs once).
local seenSecrets: { [string]: boolean } = {}

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/ActionToastUI] No GameEvent remote; server refusals will not be shown.")
		return
	end
	found.OnClientEvent:Connect(function(action: any, code: any)
		if action == ActionRefusal.Action and type(code) == "string" then
			local post = ActionRefusal.notice(code)
			if post then
				show(post)
			end
		--==================================================================
		-- A SECRET EGG SPAWNED (2026-10-05; NestService)
		--
		-- Once per actual spawn, to everyone in this server at that moment --
		-- never on a return, a rebuilt guardian, a respawn, from another
		-- server or to a late joiner. Each spawn has its own id: the same one
		-- delivered twice is shown once, a later one in the same biome is
		-- shown. A storm's egg follows the storm's own opening toast, and
		-- goes if the storm does.
		--==================================================================
		elseif action == "SecretSpawned" then
			local news = Notice.readSecret(code)
			local post = if news then Notice.secretPost(news, GameConfig.Secret.Toast, biomeName, seenSecrets) else nil
			if news and post then
				local event = news.event
				if event then
					post.after = "rain:" .. tostring(event)
					post.stillTrue = function(): boolean
						return game:GetService("Workspace"):GetAttribute(GameConfig.Weather.Attributes.EventId) == event
					end
				end
				show(post)
			end
		--==================================================================
		-- THE RAIN (2026-10-02; WeatherService)
		--
		-- Opened: once per event, to everyone here when the entrance opens --
		-- never a late joiner, and never twice (the key is the event's id).
		-- Warning: to those inside, before a timed end. Evacuated: to whoever
		-- was put back at the entrance. The words are GameConfig.Weather's; the
		-- percentage is SeedData.Rain's, the one number the faucet pays.
		--==================================================================
		elseif action == GameConfig.Weather.Events.Opened and type(code) == "number" then
			local W = GameConfig.Weather
			-- A Thunderstorm says so (2026-10-02): the same event, the same one
			-- percentage, its own words -- and its own picture (2026-10-03).
			local thunder = game:GetService("Workspace"):GetAttribute(W.Attributes.Mode) == "thunder"
			local words = if thunder then W.ThunderToast else W.Toast
			show({
				kind = "info",
				title = words.Title,
				detail = string.format(words.Detail, math.round((SeedData.Rain.IncomeFactor - 1) * 100)),
				key = "rain:" .. tostring(code),
				icon = if thunder then "thunder" else "rain",
			})
		elseif action == GameConfig.Weather.Events.Warning and type(code) == "number" then
			local W = GameConfig.Weather
			show({
				kind = "warning",
				title = W.Warning.Title,
				detail = string.format(W.Warning.Detail, math.max(1, math.floor(code))),
				key = "rain:warning",
				icon = if game:GetService("Workspace"):GetAttribute(W.Attributes.Mode) == "thunder"
					then "thunder" else "rain",
			})
		elseif action == GameConfig.Weather.Events.Evacuated then
			local W = GameConfig.Weather
			show({
				kind = "info",
				title = W.Evacuated.Title,
				detail = W.Evacuated.Detail,
				key = "rain:evacuated:" .. tostring(code),
				quiet = true,
				icon = if game:GetService("Workspace"):GetAttribute(W.Attributes.Mode) == "thunder"
					then "thunder" else "rain",
			})
		--==================================================================
		-- A LINE THE SERVER WORDED (2026-10-07; Notice.readServerNotice):
		-- always information, its words cut to length before they show.
		--==================================================================
		elseif action == Notice.ServerNotice then
			local post = Notice.readServerNotice(code)
			if post then
				show(post)
			end
		end
	end)
end)
