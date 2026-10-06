--!strict
-- Steal a Seed :: AnnouncementUI
--
-- THE TWO NOTICES AT THE TOP OF THE SCREEN (2026-10-01, the owner's brief;
-- GameConfig.Announce)
--
--   THE RESTART NOTICE  "SERVER UPDATE — <reason>" (or the default line) over
--                       "Restarting in 05:00", counting down once a second, and
--                       "Restarting shortly…" from zero -- never "restarted".
--                       Up until the server closes. On its own plate.
--   AN ANNOUNCEMENT     ONE LINE, "Name: message", centred as a unit, no panel
--                       (the owner's reference, 2026-10-01). The name is the
--                       sending admin's DisplayName -- read off their Player by
--                       the server, never sent by a client -- in the wheel
--                       sign's rainbow, drifting, with a soft rainbow glow
--                       behind its letters (a still rainbow under reduced
--                       motion); the colon and the words white. All of it the
--                       same rounded cartoon face and size, outlined dark. A
--                       long message flows on under the line, left-aligned in
--                       the centred block, its first words always beside the
--                       name. One chime (GameConfig.announceChime) when a new
--                       one appears, on the UI bus -- the player's SOUND FX
--                       level and mute decide it -- and never twice for one id.
--   ONE AFTER ANOTHER   (2026-10-03) consecutive announcements no longer
--                       replace each other: the server queues them and
--                       publishes the queue (GameConfig.Announce.Attributes
--                       .Queue) with each one's start and end in server time.
--                       This draws the one whose time it is -- each in turn,
--                       in order, at least MinShowSeconds, the last for
--                       ShowSeconds -- and chimes as each comes up.
--
-- Both are read from Workspace attributes AnnouncementService publishes, so a
-- player who joins late reads the same notice and the same time left as
-- everybody else, and a respawn changes nothing (the gui does not reset).
--
-- PLACED, NOT IN THE WAY: under the HUD's top centre column -- below the boost
-- row (HudLayout.statusRows) and, while it is up, the beginner guide's lines --
-- and as wide as the room between the side groups there (HudLayout.centreIn).
-- Nothing in it is Active or a button, so it never takes a click, a tap or a
-- drag from the world, the camera or the thumbstick. Under the chase warning.
--
-- TEXT ONLY: every run of words is a TextLabel with RichText off. Nothing a
-- notice carries is run, required or parsed.
--==============================================================================

local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local ANNOUNCE = GameConfig.Announce
local ATTR = ANNOUNCE.Attributes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PLATE = Color3.fromRGB(18, 20, 26)
local INK = Color3.fromRGB(20, 16, 12)
local AMBER = Color3.fromRGB(255, 170, 72)
local WHITE = Color3.fromRGB(255, 255, 255)

-- The broadcast's face: bold, rounded, cartoon -- and one size for all of it.
local FACE = Enum.Font.FredokaOne
-- The wheel sign's rainbow (WheelModel, THE SIGN), stop for stop, and its drift
-- at twice the wheel's pace, like the community chest's FREE.
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 92, 92)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 176, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 232, 80)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(110, 220, 110)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(90, 176, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 255)),
})
local DRIFT_SECONDS = 7
-- The glow behind the name: a wide, half-clear edge carrying the same rainbow.
local GLOW_TRANSPARENCY = 0.55

local old = playerGui:FindFirstChild("SeedAnnouncements")
if old then
	old:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedAnnouncements"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- Over the HUD (40-46), under the chase warning (50) and the admin console (60).
gui.DisplayOrder = 47
gui.Parent = playerGui

local stack = Instance.new("Frame")
stack.Name = "Stack"
stack.BackgroundTransparency = 1
stack.AnchorPoint = Vector2.new(0.5, 0)
stack.AutomaticSize = Enum.AutomaticSize.Y
stack.Active = false
stack.Parent = gui
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 6)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Parent = stack

local function outlined(label: TextLabel, thickness: number): UIStroke
	local edge = Instance.new("UIStroke")
	edge.Color = INK
	edge.Thickness = thickness
	edge.Parent = label
	return edge
end

--==============================================================================
-- THE RESTART NOTICE'S CARD: a plate, a title and a countdown -- unchanged
--==============================================================================
local function line(parent: Instance, name: string, font: Enum.Font, colour: Color3, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextColor3 = colour
	label.RichText = false
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.fromScale(1, 0)
	label.LayoutOrder = order
	label.Active = false
	label.Text = ""
	label.Parent = parent
	outlined(label, 1.5)
	return label
end

local restartFrame = Instance.new("Frame")
restartFrame.Name = "Restart"
restartFrame.BackgroundColor3 = PLATE
restartFrame.BackgroundTransparency = 0.25
restartFrame.BorderSizePixel = 0
restartFrame.AutomaticSize = Enum.AutomaticSize.Y
restartFrame.Size = UDim2.fromScale(1, 0)
restartFrame.LayoutOrder = 1
restartFrame.Active = false
restartFrame.Visible = false
restartFrame.Parent = stack
UIKit.corner(restartFrame, 10)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 7)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = restartFrame
	local inner = Instance.new("UIListLayout")
	inner.SortOrder = Enum.SortOrder.LayoutOrder
	inner.Padding = UDim.new(0, 2)
	inner.Parent = restartFrame
end
local restartTitle = line(restartFrame, "Title", Enum.Font.GothamBlack, AMBER, 1)
local restartBody = line(restartFrame, "Body", Enum.Font.GothamBold, WHITE, 2)

--==============================================================================
-- THE BROADCAST: "Name: message" as one centred block, no panel
--==============================================================================
local broadcast = Instance.new("Frame")
broadcast.Name = "Broadcast"
broadcast.BackgroundTransparency = 1
broadcast.AutomaticSize = Enum.AutomaticSize.Y
broadcast.Size = UDim2.fromScale(1, 0)
broadcast.LayoutOrder = 2
broadcast.Active = false
broadcast.Visible = false
broadcast.Parent = stack

-- The lines, as wide as the widest of them and centred: one line is centred
-- whole; a wrapped message reads left to right under the name's line.
local block = Instance.new("Frame")
block.Name = "Block"
block.BackgroundTransparency = 1
block.AnchorPoint = Vector2.new(0.5, 0)
block.Position = UDim2.fromScale(0.5, 0)
block.AutomaticSize = Enum.AutomaticSize.XY
block.Size = UDim2.fromOffset(0, 0)
block.Active = false
block.Parent = broadcast
local rows = Instance.new("UIListLayout")
rows.SortOrder = Enum.SortOrder.LayoutOrder
rows.HorizontalAlignment = Enum.HorizontalAlignment.Left
rows.Padding = UDim.new(0, 0)
rows.Parent = block

type Style = { size: number, outline: number, glow: number, gap: number }
local DESKTOP: Style = { size = 22, outline = 2.5, glow = 7, gap = 7 }
local SMALL: Style = { size = 17, outline = 2, glow = 5, gap = 5 }
local style: Style = DESKTOP
local maxWidth = 520

-- The two rainbows the drift moves: the name's letters and their glow.
local nameRainbows: { UIGradient } = {}

local function run(parent: Instance, name: string, text: string, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = FACE
	label.TextSize = style.size
	label.TextColor3 = WHITE
	label.RichText = false
	label.TextWrapped = false
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.LayoutOrder = order
	label.Active = false
	label.Text = text
	label.Parent = parent
	outlined(label, style.outline)
	return label
end

local function widthOf(text: string): number
	if text == "" then
		return 0
	end
	return TextService:GetTextSize(text, style.size, FACE, Vector2.new(100000, 100000)).X + style.outline * 2
end

-- The longest start of `word` that fits in `room` (at least one character),
-- and the rest: for a word wider than a whole line.
local function splitWord(word: string, room: number): (string, string)
	local fit = ""
	for _, code in utf8.codes(word) do
		local grown = fit .. utf8.char(code)
		if fit ~= "" and widthOf(grown) > room then
			break
		end
		fit = grown
	end
	return fit, string.sub(word, #fit + 1)
end

-- The message cut into lines: the first `firstRoom` wide (beside the name),
-- the rest `fullRoom`. Spaces are where it breaks; a word too wide for a line
-- breaks inside itself. The first line always holds something, so the name is
-- never left alone on its line.
local function flow(message: string, firstRoom: number, fullRoom: number): { string }
	local lines: { string } = {}
	local current = ""
	local room = math.max(firstRoom, 1)
	local function push()
		table.insert(lines, current)
		current = ""
		room = fullRoom
	end
	for word in string.gmatch(message, "%S+") do
		local candidate = if current == "" then word else current .. " " .. word
		if widthOf(candidate) <= room then
			current = candidate
		else
			if current ~= "" then
				push()
			end
			while widthOf(word) > room do
				local head, rest = splitWord(word, room)
				current = head
				push()
				word = rest
			end
			current = word
		end
	end
	if current ~= "" or #lines == 0 then
		table.insert(lines, current)
	end
	return lines
end

local drawn = ""

local function draw(name: string, message: string)
	local key = table.concat({ name, message, tostring(maxWidth), tostring(style.size) }, "\0")
	if key == drawn then
		return
	end
	drawn = key
	for _, child in ipairs(block:GetChildren()) do
		if child ~= rows then
			child:Destroy()
		end
	end
	table.clear(nameRainbows)

	local head = widthOf(name) + widthOf(":") + style.gap
	local lines = flow(message, maxWidth - head, maxWidth)
	for i, text in ipairs(lines) do
		local row = Instance.new("Frame")
		row.Name = "Line" .. i
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.XY
		row.Size = UDim2.fromOffset(0, 0)
		row.LayoutOrder = i
		row.Active = false
		row.Parent = block
		local across = Instance.new("UIListLayout")
		across.FillDirection = Enum.FillDirection.Horizontal
		across.SortOrder = Enum.SortOrder.LayoutOrder
		across.VerticalAlignment = Enum.VerticalAlignment.Bottom
		across.Padding = UDim.new(0, 0)
		across.Parent = row
		if i == 1 then
			--==================================================================
			-- THE NAME: a box measured for it, holding two runs of it in exactly
			-- that box. Underneath, the GLOW: its edge wide and half clear, in
			-- the rainbow. On top (a higher ZIndex among the two), the letters,
			-- filled with the same rainbow and outlined dark -- so the colour
			-- only shows round them as light. Measured rather than sized from
			-- its own text, so nothing in it sizes itself from its parent.
			--==================================================================
			local measured = TextService:GetTextSize(name, style.size, FACE, Vector2.new(100000, 100000))
			local box = Instance.new("Frame")
			box.Name = "Name"
			box.BackgroundTransparency = 1
			box.Size = UDim2.fromOffset(math.ceil(measured.X), math.ceil(measured.Y))
			box.LayoutOrder = 1
			box.Active = false
			box.Parent = row
			local glow = run(box, "Glow", name, 0)
			glow.AutomaticSize = Enum.AutomaticSize.None
			glow.Size = UDim2.fromScale(1, 1)
			glow.ZIndex = 1
			local edge = glow:FindFirstChildOfClass("UIStroke") :: UIStroke
			edge.Color = WHITE
			edge.Thickness = style.glow
			edge.Transparency = GLOW_TRANSPARENCY
			local glowRainbow = Instance.new("UIGradient")
			glowRainbow.Color = RAINBOW
			glowRainbow.Parent = edge
			local letters = run(box, "Letters", name, 0)
			letters.AutomaticSize = Enum.AutomaticSize.None
			letters.Size = UDim2.fromScale(1, 1)
			letters.ZIndex = 2
			local fill = Instance.new("UIGradient")
			fill.Color = RAINBOW
			fill.Parent = letters
			table.insert(nameRainbows, fill)
			table.insert(nameRainbows, glowRainbow)
			run(row, "Colon", ":", 2)
			local gap = Instance.new("Frame")
			gap.Name = "Gap"
			gap.BackgroundTransparency = 1
			gap.Size = UDim2.fromOffset(style.gap, 1)
			gap.LayoutOrder = 3
			gap.Parent = row
		end
		run(row, "Words", text, 4)
	end
end

--==============================================================================
-- WHERE: under the top centre column, as wide as the room there
--==============================================================================
-- The beginner guide's instruction and Skip line stand in this column too, on
-- every screen, while a new player is on the guide: up, the notices start
-- under them; gone, the notices come up under the boost row.
local function guideUp(): boolean
	local guide = playerGui:FindFirstChild("SeedBeginnerGuide")
	if not (guide and guide:IsA("ScreenGui") and guide.Enabled) then
		return false
	end
	for _, name in ipairs({ "Instruction", "Skip" }) do
		local o = guide:FindFirstChild(name, true)
		if o and o:IsA("GuiObject") and o.Visible then
			local up = true
			local above = o.Parent
			while above and above ~= guide do
				if above:IsA("GuiObject") and not above.Visible then
					up = false
				end
				above = above.Parent
			end
			if up then
				return true
			end
		end
	end
	return false
end

local guided = false

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local inset = input.insetTop or 0
	local _, _, boosts = HudLayout.statusRows(layout, inset)
	local top = boosts.y + boosts.h + 8
	guided = guideUp()
	if guided then
		top = math.max(top, layout.banner.y + layout.banner.h + 8, layout.skip.y + layout.skip.h + 8)
	end
	local small = layout.compact or layout.sidebar
	local want = if small then 340 else 520
	local band = { x = 0, y = top, w = layout.safe.X, h = 60 }
	local r = HudLayout.centreIn(layout, band, want)
	local width = math.max(r.w, 200)
	stack.Size = UDim2.fromOffset(width, 0)
	stack.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - layout.safe.X / 2), 0, math.round(top + inset))
	restartTitle.TextSize = if small then 14 else 18
	restartBody.TextSize = if small then 13 else 16
	style = if small then SMALL else DESKTOP
	maxWidth = width
	drawn = ""
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
place()

--==============================================================================
-- THE RAINBOW MOVES: smooth steps while a broadcast is up; still under reduced
-- motion; nothing at all while none is
--==============================================================================
local drifting = false
local function drift()
	if drifting then
		return
	end
	drifting = true
	task.spawn(function()
		local offset = 0
		local last = os.clock()
		while gui.Parent and broadcast.Visible do
			local now = os.clock()
			if not StatusText.reducedMotion() then
				-- Capped, so a hitch or a frame behind never jumps the colours.
				offset = (offset + math.min(now - last, 0.1) / DRIFT_SECONDS) % 1
			end
			last = now
			local at = Vector2.new(offset * 2 - 1, 0)
			for _, g in ipairs(nameRainbows) do
				g.Offset = at
			end
			task.wait(1 / 30)
		end
		drifting = false
	end)
end

--==============================================================================
-- WHAT: read off Workspace, once a second while anything is up
--==============================================================================
-- Broadcast ids this client has chimed for (or found already up), and whether
-- it is still reading what was up when it started.
local heard: { [string]: boolean } = {}
local starting = true

-- THE QUEUE, as the server published it: decoded once per change, every field
-- checked, at most 16 kept. Text in, text out -- nothing in it is run.
type Entry = { id: string, text: string, from: string, s: number, e: number }
local queueRaw: string? = nil
local entries: { Entry } = {}

local function readQueue(): { Entry }
	local raw = Workspace:GetAttribute(ATTR.Queue)
	local key = if type(raw) == "string" then raw else nil
	if key == queueRaw then
		return entries
	end
	queueRaw = key
	entries = {}
	if key == nil or #key > 20000 then
		return entries
	end
	local ok, list = pcall(function()
		return HttpService:JSONDecode(key :: string)
	end)
	if not ok or type(list) ~= "table" then
		return entries
	end
	for _, v in ipairs(list) do
		if type(v) == "table" and type(v.i) == "string" and type(v.t) == "string" and v.t ~= ""
			and type(v.s) == "number" and type(v.e) == "number" and v.e > v.s then
			table.insert(entries, {
				id = v.i,
				text = v.t,
				from = if type(v.f) == "string" and v.f ~= "" then v.f else ANNOUNCE.Title,
				s = v.s,
				e = v.e,
			})
		end
		if #entries >= 16 then
			break
		end
	end
	return entries
end

-- How long the ticker may sleep: to the next start or end in the queue, a
-- second at most (the restart countdown's tick).
local wakeIn = 1

local function paint(): boolean
	if guideUp() ~= guided then
		place()
	end
	local now = Workspace:GetServerTimeNow()
	local restartAt = Workspace:GetAttribute(ATTR.RestartAt)
	local restartLine = Workspace:GetAttribute(ATTR.RestartTitle)
	local restarting = type(restartAt) == "number" and type(restartLine) == "string" and restartLine ~= ""
	if restarting then
		restartTitle.Text = restartLine :: string
		restartBody.Text = GameConfig.restartCountdown((restartAt :: number) - now)
	end
	restartFrame.Visible = restarting

	-- The one whose time it is, and when the queue next changes on screen.
	local current: Entry? = nil
	local nextAt = math.huge
	for _, entry in ipairs(readQueue()) do
		if entry.s <= now and now < entry.e then
			if current == nil then
				current = entry
			end
			nextAt = math.min(nextAt, entry.e)
		elseif entry.s > now then
			nextAt = math.min(nextAt, entry.s)
		end
	end
	local announcing = current ~= nil
	if current then
		draw(current.from, current.text)
		-- One chime per broadcast: a new id, never one this client has already
		-- heard, never the one already up when it started.
		if GameConfig.announceChime(heard, current.id, starting) then
			SoundKit.play(ANNOUNCE.Chime)
		end
	end
	broadcast.Visible = announcing
	if announcing then
		drift()
	end
	wakeIn = math.clamp(nextAt - now, 0.05, 1)
	return restarting or announcing or nextAt < math.huge
end

local ticking = false
local function refresh()
	if not paint() or ticking then
		return
	end
	ticking = true
	task.spawn(function()
		while gui.Parent and paint() do
			task.wait(wakeIn)
		end
		ticking = false
	end)
end
for _, name in pairs(ATTR) do
	Workspace:GetAttributeChangedSignal(name):Connect(refresh)
end
-- A late joiner: whatever is already up, with the time it has left -- in
-- silence: the chime is for a broadcast arriving, not for joining.
refresh()
starting = false
