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
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local Notice = require(Shared:WaitForChild("Notice"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local StatusText = require(Shared:WaitForChild("StatusText"))

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

local metrics: Metrics = FULL
local maxShown = Notice.MaxShown
local width = 340

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
	frame.AnchorPoint = Vector2.new(0.5, 1)
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
	}

	-- The headline row: icon, a small gap, the words -- centred as one.
	local iconSize = metrics.icon
	local room = width - iconSize - 8
	local hs = headSize(post.title, room)
	local headW = math.min(room, textWidth(post.title, hs, HEAD_FONT))
	local rowW = iconSize + 8 + headW
	local rowH = math.max(iconSize, hs + 4)

	local row = Instance.new("Frame")
	row.Name = "Headline"
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 0)
	row.Size = UDim2.fromOffset(rowW, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = body

	local icon = StatusText.icon(row, post.kind, style.tint, iconSize)
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
	head.TextColor3 = style.tint
	head.TextXAlignment = Enum.TextXAlignment.Center
	head.Text = post.title
	head.Parent = row
	d.headLabel = head
	local headEdge = UIKit.stroke(head, Notice.Outline, 2, 0.1)
	track(d, head, "TextTransparency")
	track(d, headEdge, "Transparency")

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

	-- The icon's rings are strokes and its glyph is fills with strokes.
	for _, part in ipairs(icon:GetDescendants()) do
		if part:IsA("UIStroke") then
			track(d, part, "Transparency")
		elseif part:IsA("Frame") and part.BackgroundTransparency < 1 then
			track(d, part, "BackgroundTransparency")
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
	local goal = UDim2.new(0.5, 0, 1, -y)
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
	for i = #drawn, 1, -1 do
		local d = drawn[i]
		if not d.leaving then
			slotTween(d, y, d == newest)
			y += d.height + metrics.between
		end
	end
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
	metrics = if small then SMALL else FULL
	width = math.max(160, layout.toast.w)
	-- The window's middle, in this gui's safe space: the reticle's band.
	local camera = workspace.CurrentCamera
	local middle = if camera then camera.ViewportSize.Y / 2 - GuiService:GetGuiInset().Y else 0
	local one = metrics.head + 4 + metrics.gap + metrics.detail + 4 + metrics.between
	local area, count = HudLayout.noticeStack(layout, one,
		if small then Notice.MaxShownCompact else Notice.MaxShown, middle)
	maxShown = count
	column.Position = HudLayout.place(area, Vector2.new(0.5, 1), layout.safe)
	column.Size = UDim2.fromOffset(width, area.h)
	restack(nil)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
place()

--==============================================================================
-- THE TWO WAYS A NOTICE ARRIVES
--==============================================================================
Notice.setRenderer(show)

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
		end
	end)
end)
