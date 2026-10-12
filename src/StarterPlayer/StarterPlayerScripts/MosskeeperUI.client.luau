--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperUI (2026-10-11, Enchanted Mist stage 3; his talk
-- rebuilt the same day)
--
-- MOSSKEEPER'S TALK (the owner's clip of a Grow-a-Garden-style shop NPC;
-- EnchantedMistConfig.Mosskeeper.Talk, Shared/MosskeeperTalk). E -- Talk (the
-- server's "open") eases the camera behind the player's shoulder, facing him,
-- and turns the player to him. His line types out over his head (the Mist
-- running or not); the player's four replies float beside the player as
-- outlined words with no panel, the player's own numbers under them:
--   #1 Give all Dewberries  the server decides; he answers ("5/10, five more
--                           for a pod!", "Here's your Mysterious Pod!", "Make
--                           room in your Bag.", ...) while his bar fills
--   #2 Odds                 the odds cards (MistOddsView), then the replies
--   #3 How to play          his short run of lines, then the replies
--   #4 Nevermind            closes; the camera eases back
-- A reply goes up over the player's own head first. Keys 1-4, a click, a tap
-- (a touch screen's rows tall enough), or the D-pad and A -- the D-pad read
-- through UserInputService, never a GUI selection (which would eat it). HELLO
-- as it opens, GIVE ALL on a delivery taken, the game's Action Blocked as he
-- refuses one; POD EARNED is his bar's (MosskeeperView). The numbers are the
-- server's (the player's attributes); a Give all sends no amount.
--
-- THE CAMERA, borrowed and given back: taken only if it is the default camera
-- on this player's own Humanoid (no other owner, no VR), marked with
-- CAMERA_MARK, held each frame after the engine's camera step; given back
-- (Custom, this body's Humanoid) only while the mark is still ours and it is
-- still Scriptable -- a newer owner's state is never overwritten. Nevermind,
-- Back/Escape/B ease it back first; walking past CloseDistance, death,
-- respawn, him going, another panel opening or the Roblox menu give it back at
-- once. Reduced Motion cuts the camera and types nothing: each line whole.
-- Nothing forced: only a Talk the player chose opens it.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local MosskeeperModel = require(Shared:WaitForChild("MosskeeperModel"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
local MosskeeperTalk = require(Shared:WaitForChild("MosskeeperTalk"))

local CFG = EnchantedMistConfig.Mosskeeper
local TALK = CFG.Talk
local W = CFG.Words
local BAR = CFG.Bar
local PA = EnchantedMistConfig.PlayerAttributes
local ATTR = GameConfig.Attributes
local PANEL = "Mosskeeper"
local BACK_ACTION = "SeedMosskeeperBack"
local REPLY_ACTION = "SeedMosskeeperReplies"
local CAMERA_STEP = "SeedMosskeeperCamera"
local CAMERA_MARK = "SeedMosskeeperCamera"
local OPTIONS = MosskeeperTalk.options()
local REPLY_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
}

local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
for _, name in ipairs({ "SeedMosskeeper", "SeedMosskeeperTalk", "SeedMosskeeperMeasure", "SeedMosskeeperLine",
	"SeedMosskeeperYou" }) do
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end
player:SetAttribute(CFG.TalkingAttribute, nil)

local function reduced(): boolean
	return StatusText.reducedMotion()
end

--==============================================================================
-- THE ODDS: the cards (MistOddsView) on a panel of their own, and the way back
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedMosskeeper"
gui.ResetOnSpawn = false
-- Beside Marigold's shop (34), under SELL ONE (36) and the RUN alarm (50).
gui.DisplayOrder = 35
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local modal = UIKit.modal(gui, {
	name = "Mosskeeper",
	title = string.upper(W.Odds),
	maxWidth = 400,
	maxHeight = 430,
	-- The studded kit over the whole panel (the owner: never a flat plate).
	theme = MenuKit.studdedTheme(CFG.Look),
	titleColour = GameConfig.StuddedLook.Title,
	stillWhenReduced = true,
})
modal.followMenuSize()

local GAP, MARGIN = 6, 16

local function row(parent: Instance, name: string, order: number, height: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.new(1, -8, 0, height)
	f.BackgroundTransparency = 1
	f.LayoutOrder = order
	f.ZIndex = 4
	f.Parent = parent
	return f
end

local oddsPage = Instance.new("Frame")
oddsPage.Name = "OddsPage"
oddsPage.Size = UDim2.fromScale(1, 1)
oddsPage.BackgroundTransparency = 1
oddsPage.ZIndex = 3
oddsPage.Parent = modal.body
do
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = oddsPage
end
local oddsHolder = row(oddsPage, "Cards", 1, 0)
local backRow = row(oddsPage, "BackRow", 2, 42)
local oddsBack = MenuKit.button(backRow, "OddsBack", 5, W.Back, 18)
oddsBack.style("sky")
oddsBack.hit.AnchorPoint = Vector2.new(0.5, 0.5)
oddsBack.hit.Position = UDim2.fromScale(0.5, 0.5)
oddsBack.hit.Size = UDim2.new(1, 0, 0, 42)
UIKit.clicks(oddsBack.hit)
local oddsView = MistOddsView.build(oddsHolder, 5)
oddsHolder.Size = UDim2.new(1, -8, 0, math.min(oddsView.height, CFG.Odds.ViewHeight))

-- Where a controller's selection starts (PadFocus reads it).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Value = oddsBack.hit
padFirst.Parent = modal.shell

--==============================================================================
-- THE REPLIES: outlined words beside the player, no panel
--
-- In a gui that ignores the inset and the safe area, so a point projected
-- from the world is its own pixel; the HUD is measured through an empty gui
-- set up as the HUD's own are, and the replies keep inside its free middle
-- (between the rails, over the strip's name band). Drawn bigger on a TV.
--==============================================================================
local talkGui = Instance.new("ScreenGui")
talkGui.Name = "SeedMosskeeperTalk"
talkGui.ResetOnSpawn = false
talkGui.IgnoreGuiInset = true
talkGui.ScreenInsets = Enum.ScreenInsets.None
-- Under the odds panel (35).
talkGui.DisplayOrder = 34
talkGui.Enabled = false
talkGui.Parent = playerGui

local measureGui = Instance.new("ScreenGui")
measureGui.Name = "SeedMosskeeperMeasure"
measureGui.ResetOnSpawn = false
measureGui.IgnoreGuiInset = false
measureGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
UIKit.tenFoot(measureGui)
measureGui.Parent = playerGui

type Reply = { hit: TextButton, words: TextLabel }
local replies: { Reply } = {}
for i, option in ipairs(OPTIONS) do
	local hit = Instance.new("TextButton")
	hit.Name = "Reply" .. i
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Text = ""
	-- The D-pad is read directly: nothing here ever takes the GUI selection.
	hit.Selectable = false
	hit.Parent = talkGui
	local words = UIKit.outlined(hit, "Words", TALK.Look.Desktop.Type, TALK.Look.Text, TALK.Look.Stroke)
	words.RichText = true
	words.Size = UDim2.fromScale(1, 1)
	words.TextXAlignment = Enum.TextXAlignment.Left
	words.TextYAlignment = Enum.TextYAlignment.Center
	words.Text = MosskeeperTalk.label(option)
	table.insert(replies, { hit = hit, words = words })
end
local countsLabel = UIKit.outlined(talkGui, "Counts", TALK.Look.Desktop.Counts, TALK.Look.Text, TALK.Look.Stroke)
countsLabel.TextXAlignment = Enum.TextXAlignment.Left
countsLabel.TextYAlignment = Enum.TextYAlignment.Center

--==============================================================================
-- THE BUBBLES: his line over his bar, the player's over their head
--
-- Outlined words standing in the world (BillboardGuis in PlayerGui), bottom
-- edge on the point, wrapped to the bubble's widest, always on top: the arch,
-- the grove, his staff or another player never hide them. (An always-on-top
-- billboard never shows in a Studio capture: a capture run turns it off on the
-- live bubbles by hand -- test only, never shipped.)
--==============================================================================
local function bubble(name: string): (BillboardGui, TextLabel)
	local board = Instance.new("BillboardGui")
	board.Name = name
	board.ResetOnSpawn = false
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	-- Its bottom edge on the point: it grows upward.
	board.SizeOffset = Vector2.new(0, 0.5)
	board.Enabled = false
	board.Parent = playerGui
	local label = UIKit.outlined(board, "Line", TALK.Look.Desktop.Bubble, TALK.Look.Text, TALK.Look.Stroke)
	label.Size = UDim2.fromScale(1, 1)
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Bottom
	return board, label
end
local hisBoard, hisLabel = bubble("SeedMosskeeperLine")
local youBoard, youLabel = bubble("SeedMosskeeperYou")

--==============================================================================
-- FINDING THINGS
--==============================================================================
local function npcModel(): Model?
	local folder = Workspace:FindFirstChild(CFG.FolderName)
	local model = folder and folder:FindFirstChild("Mosskeeper")
	return if model and model:IsA("Model") and model.PrimaryPart then model else nil
end

local function myHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function myRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function myHead(): BasePart?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

local function count(name: string): number
	return math.floor(tonumber(player:GetAttribute(name)) or 0)
end

--==============================================================================
-- THE HUD, in talkGui's pixels: the screen, everything of the HUD's on it
-- (its groups with their badges, the bands over the belt, the touch controls,
-- the clock and ADMIN -- TreadmillFunUI's recipe) and, apart, what comes and
-- goes there (the notices' line, the biome name, the chase warning, the running
-- boosts); whether it is a touch screen and how much bigger a TV draws it.
-- Measured when the replies show and when the screen changes.
--==============================================================================
local hud: { bounds: MosskeeperTalk.Rect, blocked: { MosskeeperTalk.Rect }, soft: { MosskeeperTalk.Rect },
	touch: boolean, k: number }? = nil

local function measureHud()
	local size = measureGui.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		hud = nil
		return
	end
	local input = HudLayout.measure(measureGui)
	local L = HudLayout.solve(input)
	local k = HudLayout.scaleOf(measureGui)
	local shift = measureGui.AbsolutePosition - talkGui.AbsolutePosition
	local insetTop = input.insetTop or 0
	local blocked: { MosskeeperTalk.Rect } = {}
	local soft: { MosskeeperTalk.Rect } = {}
	-- A phone's REBIRTH stands in the dock RailDrawerUI hides while this talk's
	-- panel is open (OpenPanel; 2026-10-12, item 18): no room taken then.
	if L.sidebar then
		L.rebirth = HudLayout.rect(0, 0, 0, 0)
	end
	local function add(list: { MosskeeperTalk.Rect }, r: HudLayout.Rect?, lift: number?)
		if r and r.w > 0 and r.h > 0 then
			table.insert(list, {
				x = r.x * k + shift.X,
				y = (r.y - (lift or 0)) * k + shift.Y,
				w = r.w * k,
				h = r.h * k,
			})
		end
	end
	for _, r in ipairs(HudLayout.occupiedButToast(L)) do
		add(blocked, r)
	end
	local status, notice, boosts = HudLayout.statusRows(L, insetTop)
	-- The clock and ADMIN stand in an inset-ignoring gui: HudLayout's own way
	-- from there into safe space is less the inset.
	add(blocked, L.clock, insetTop)
	add(blocked, L.admin, insetTop)
	add(soft, L.toast)
	add(soft, notice)
	add(soft, status)
	add(soft, boosts)
	hud = {
		bounds = { x = shift.X, y = shift.Y, w = size.X, h = size.Y },
		blocked = blocked,
		soft = soft,
		touch = input.touch,
		k = k,
	}
end
measureGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(measureHud)

--==============================================================================
-- THE STATE
--==============================================================================
local isOpen = false
-- What the player can do now: "replies" (choosing), "busy" (a line or a run
-- going), "odds" (the odds panel up).
local mode = "busy"
local generation = 0
local selected = 1
local hovered: number? = nil
local answer: { [string]: any }? = nil
local asked: number? = nil

type Line = { text: string, started: number }
local hisLine: Line? = nil
local youUntil = 0

-- Where even the tight look cannot stand clear of his line, his line is put
-- away while the replies show (MosskeeperTalk.place); his next line is shown.
local hisPutAway = false

local function setHis(text: string?)
	hisPutAway = false
	if text then
		hisLabel.Text = text
		hisLabel.MaxVisibleGraphemes = if reduced() then -1 else 0
		hisLine = { text = text, started = os.clock() }
		hisBoard.Enabled = true
	else
		hisLine = nil
		hisBoard.Enabled = false
	end
end

local function setYou(text: string?, hold: number?)
	if text then
		youLabel.Text = text
		youBoard.Enabled = true
		youUntil = os.clock() + (hold or TALK.PlayerHold)
	else
		youBoard.Enabled = false
		youUntil = 0
	end
end

local function sizeBubbles()
	local k = if hud then hud.k else 1
	local look = MosskeeperTalk.look(hud ~= nil and hud.touch)
	for _, pair in ipairs({ { hisBoard, hisLabel }, { youBoard, youLabel } }) do
		local board, label = pair[1] :: BillboardGui, pair[2] :: TextLabel
		board.Size = UDim2.fromOffset(look.BubbleWidth * k, (look.Bubble * 1.2 * 4 + 8) * k)
		label.TextSize = look.Bubble * k
	end
	local model = npcModel()
	hisBoard.Adornee = if model then model.PrimaryPart else nil
	hisBoard.StudsOffsetWorldSpace = Vector3.new(0, BAR.Above + BAR.Height / 2 + TALK.OverBar, 0)
	local head = myHead()
	youBoard.Adornee = head
	youBoard.StudsOffsetWorldSpace = Vector3.new(0, (if head then head.Size.Y / 2 else 1) + TALK.OverHead, 0)
end

local function refreshCounts()
	countsLabel.Text = MosskeeperTalk.counts(count(PA.Carried), count(PA.Progress))
end

local function paintReplies()
	local lit = if PadInput.active() then selected else hovered
	for i, reply in ipairs(replies) do
		reply.words.Text = MosskeeperTalk.label(OPTIONS[i], if i == lit then TALK.Look.Chosen else nil)
	end
end

-- WHERE THE CAMERA'S VIEWPORT STANDS IN talkGui (2026-10-12). A projected
-- point is the viewport's own pixel. Where the viewport fills the screen that
-- is talkGui's pixel too; where it is only the device's safe area (Studio's
-- phone emulator: a 705 x 338 viewport in a 799 x 359 screen, every projected
-- point 47 px left of its part) it starts at the safe area's left edge,
-- measureGui's, and its bottom is measureGui's bottom.
local function viewOrigin(camera: Camera): Vector2
	local view = camera.ViewportSize
	if view.X >= talkGui.AbsoluteSize.X - 1 and view.Y >= talkGui.AbsoluteSize.Y - 1 then
		return Vector2.zero
	end
	local at = measureGui.AbsolutePosition - talkGui.AbsolutePosition
	return Vector2.new(at.X, at.Y + measureGui.AbsoluteSize.Y - view.Y)
end

-- His line's rect on screen, in talkGui's pixels: its words wrapped to the
-- bubble's widest, standing on the point over his bar.
local function hisRect(camera: Camera, model: Model, k: number, look: MosskeeperTalk.Look,
	origin: Vector2): MosskeeperTalk.Rect?
	local line = hisLine
	local base = model.PrimaryPart
	if not (line and base and hisBoard.Enabled) then
		return nil
	end
	local point, inFront = camera:WorldToViewportPoint(base.Position + hisBoard.StudsOffsetWorldSpace)
	if not inFront then
		return nil
	end
	local size = TextService:GetTextSize(line.text, look.Bubble * k, Enum.Font.LuckiestGuy,
		Vector2.new(look.BubbleWidth * k, 4000))
	local w, h = size.X + TALK.Look.Stroke * 2 * k, size.Y + TALK.Look.Stroke * 2 * k
	return { x = point.X + origin.X - w / 2, y = point.Y + origin.Y - h, w = w, h = h }
end

-- Him on screen, in talkGui's pixels: his body and the bar over him
-- (MosskeeperTalk.himPoints), what the replies keep clear of. nil while no
-- part of him is in front of the camera.
local function himRect(camera: Camera, model: Model, origin: Vector2): MosskeeperTalk.Rect?
	local base = model.PrimaryPart
	if not base then
		return nil
	end
	local box, size = model:GetBoundingBox()
	local onScreen: { Vector2 } = {}
	for _, p in ipairs(MosskeeperTalk.himPoints(box, size, base.Position, camera.CFrame.RightVector,
		camera.CFrame.UpVector)) do
		local point, inFront = camera:WorldToViewportPoint(p)
		if inFront then
			table.insert(onScreen, Vector2.new(point.X, point.Y) + origin)
		end
	end
	return MosskeeperTalk.spanOf(onScreen)
end

-- The widest reply and the counts line at a look's type, the outline and room
-- for a font still loading (measured short then) added.
local function widths(look: MosskeeperTalk.Look): (number, number)
	local widest = 0
	for _, option in ipairs(OPTIONS) do
		local size = TextService:GetTextSize(MosskeeperTalk.plain(option), look.Type, Enum.Font.LuckiestGuy,
			Vector2.new(4000, 1000))
		widest = math.max(widest, size.X + TALK.Look.Stroke * 2 + 16)
	end
	local counts = TextService:GetTextSize(countsLabel.Text, look.Counts, Enum.Font.LuckiestGuy, Vector2.new(4000, 1000))
	return widest, counts.X + TALK.Look.Stroke * 2 + 16
end

-- The rows beside the player, from where the player stands on screen now --
-- laid out in the HUD's units, drawn k times larger (a TV).
local laidOutAt = -math.huge

-- WHAT OF THE HUD IS ON SCREEN NOW (2026-10-12). The talk is an open panel,
-- and an open panel puts some of the HUD away -- on a phone the left column,
-- the panel row and Index. The replies may stand where those stood: a HUD rect
-- still counts only while something of the HUD draws at its middle or a
-- quarter in from a corner (PlayerGui:GetGuiObjectsAtPosition, in the same
-- space as AbsolutePosition), read again every half second.
local SAMPLES = { Vector2.new(0.5, 0.5), Vector2.new(0.25, 0.25), Vector2.new(0.75, 0.25), Vector2.new(0.25, 0.75),
	Vector2.new(0.75, 0.75) }
local drawnFor: any = nil
local drawnAt = -math.huge
local drawn: { MosskeeperTalk.Rect } = {}

local function drawsHere(o: GuiObject): boolean
	if o:IsDescendantOf(gui) or o:IsDescendantOf(talkGui) or o:IsDescendantOf(measureGui)
		or o.AbsoluteSize.X >= talkGui.AbsoluteSize.X * 0.9 then
		return false
	end
	local any = o :: any
	if o.BackgroundTransparency < 0.95 or o:IsA("ViewportFrame") then
		return true
	elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
		return any.Image ~= "" and any.ImageTransparency < 0.95
	elseif o:IsA("TextLabel") or o:IsA("TextButton") then
		return any.Text ~= "" and any.TextTransparency < 0.95
	end
	return false
end

local function drawnIn(r: MosskeeperTalk.Rect): boolean
	local at = talkGui.AbsolutePosition
	for _, f in ipairs(SAMPLES) do
		for _, o in ipairs(playerGui:GetGuiObjectsAtPosition(at.X + r.x + r.w * f.X, at.Y + r.y + r.h * f.Y)) do
			if drawsHere(o) then
				return true
			end
		end
	end
	return false
end

local function drawnBlocked(h: any): { MosskeeperTalk.Rect }
	if drawnFor ~= h or os.clock() - drawnAt >= 0.5 then
		drawnFor, drawnAt = h, os.clock()
		drawn = {}
		for _, r in ipairs(h.blocked) do
			if drawnIn(r) then
				table.insert(drawn, r)
			end
		end
	end
	return drawn
end

local function layoutReplies()
	local camera = Workspace.CurrentCamera
	local model = npcModel()
	local root = myRoot()
	local h = hud
	if not (camera and model and root and h) then
		return
	end
	laidOutAt = os.clock()
	local k = h.k
	local function units(r: MosskeeperTalk.Rect): MosskeeperTalk.Rect
		return { x = r.x / k, y = r.y / k, w = r.w / k, h = r.h / k }
	end
	local blocked: { MosskeeperTalk.Rect } = {}
	for _, r in ipairs(drawnBlocked(h)) do
		table.insert(blocked, units(r))
	end
	local soft: { MosskeeperTalk.Rect } = {}
	for _, r in ipairs(h.soft) do
		table.insert(soft, units(r))
	end
	local origin = viewOrigin(camera)
	local his = if hisPutAway then nil else hisRect(camera, model, k, MosskeeperTalk.look(h.touch), origin)
	local him = himRect(camera, model, origin)
	local point = camera:WorldToViewportPoint(MosskeeperTalk.besidePoint(root.Position, model:GetPivot().Position))
	local block = MosskeeperTalk.place((Vector2.new(point.X, point.Y) + origin) / k, units(h.bounds), h.touch, widths,
		blocked, soft, if his then units(his) else nil, #OPTIONS, if him then units(him) else nil)
	if not block.keepsHis and hisLine then
		hisPutAway = true
		hisBoard.Enabled = false
	end
	local look = block.look
	for i, reply in ipairs(replies) do
		local r = block.rows[i]
		reply.hit.Position = UDim2.fromOffset(r.x * k, r.y * k)
		reply.hit.Size = UDim2.fromOffset(r.w * k, r.h * k)
		reply.words.TextSize = look.Type * k
	end
	local c = block.counts
	countsLabel.Position = UDim2.fromOffset(c.x * k, c.y * k)
	countsLabel.Size = UDim2.fromOffset(c.w * k, c.h * k)
	countsLabel.TextSize = look.Counts * k
end

local function showReplies(on: boolean)
	mode = if on then "replies" else (if mode == "odds" then "odds" else "busy")
	talkGui.Enabled = on
	if on then
		measureHud()
		refreshCounts()
		paintReplies()
		layoutReplies()
	end
end

--==============================================================================
-- THE CAMERA
--==============================================================================
type Framing = { from: CFrame, holdFrom: CFrame?, started: number, reduced: boolean, leaving: number?,
	leaveFrom: CFrame? }
local held: { subject: Instance? }? = nil
local framing: Framing? = nil

local function giveBack()
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	framing = nil
	local was = held
	held = nil
	local camera = Workspace.CurrentCamera
	if not (was and camera) or camera:GetAttribute(CAMERA_MARK) ~= true then
		-- Never ours, or a newer owner has it: theirs to keep.
		return
	end
	camera:SetAttribute(CAMERA_MARK, nil)
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = myHumanoid()
		local subject = was.subject
		if humanoid and humanoid.Health > 0 then
			camera.CameraSubject = humanoid
		elseif subject and subject:IsDescendantOf(Workspace) then
			camera.CameraSubject = subject
		end
	end
end

-- Eased back to where it stood before the talk, then given back -- or given
-- back at once (`now`: walking off, a death, a respawn; Reduced Motion).
local function releaseCamera(now: boolean)
	local f = framing
	local camera = Workspace.CurrentCamera
	if now or not (f and camera and held) or f.reduced or camera:GetAttribute(CAMERA_MARK) ~= true then
		giveBack()
		return
	end
	if f.leaving == nil then
		f.leaving = os.clock()
		f.leaveFrom = camera.CFrame
	end
end

-- Nothing solid between the player and the shot: pulled in to whatever stands
-- there (only what collides: leaves and dress never move it), looking the same way.
local function unblocked(goal: CFrame, root: Vector3, model: Model): CFrame
	local from = root + Vector3.new(0, 1.5, 0)
	local reach = goal.Position - from
	if reach.Magnitude < 1e-3 then
		return goal
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, model }
	params.RespectCanCollide = true
	local hit = Workspace:Raycast(from, reach, params)
	if not hit then
		return goal
	end
	local eye = hit.Position - reach.Unit * 0.6
	return CFrame.lookAt(eye, eye + goal.LookVector)
end

local function takeCamera()
	local camera = Workspace.CurrentCamera
	local humanoid = myHumanoid()
	local f = framing
	if f and f.leaving then
		-- Talked to again on the way back: eased to him again from where it is.
		f.leaving = nil
		f.leaveFrom = nil
		f.holdFrom = if camera then camera.CFrame else nil
		f.started = os.clock()
		return
	end
	if held or not (camera and humanoid) then
		return
	end
	-- Only the default camera on this player's own body; anything else has an owner.
	if camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= humanoid or VRService.VREnabled then
		return
	end
	held = { subject = camera.CameraSubject }
	camera:SetAttribute(CAMERA_MARK, true)
	camera.CameraType = Enum.CameraType.Scriptable
	framing = { from = camera.CFrame, started = os.clock(), reduced = reduced() }
	-- After the engine's own camera step, which would otherwise win the first frame.
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, function()
		local cam = Workspace.CurrentCamera
		local now = framing
		if not (cam and now) then
			return
		end
		if cam:GetAttribute(CAMERA_MARK) ~= true or cam.CameraType ~= Enum.CameraType.Scriptable then
			-- Somebody else took it: stop holding, give nothing back over theirs.
			RunService:UnbindFromRenderStep(CAMERA_STEP)
			framing = nil
			held = nil
			return
		end
		local leaving = now.leaving
		if leaving then
			local u = MosskeeperTalk.ease((os.clock() - leaving) / TALK.Camera.EaseSeconds)
			cam.CFrame = (now.leaveFrom or cam.CFrame):Lerp(now.from, u)
			if u >= 1 then
				giveBack()
			end
			return
		end
		local model = npcModel()
		local root = myRoot()
		if not (model and root) then
			return
		end
		local goal = unblocked(MosskeeperTalk.shoulder(root.Position, model:GetPivot().Position), root.Position, model)
		if now.reduced then
			cam.CFrame = goal
		else
			cam.CFrame = (now.holdFrom or now.from):Lerp(goal,
				MosskeeperTalk.ease((os.clock() - now.started) / TALK.Camera.EaseSeconds))
		end
	end)
end

-- The player turned to him (yaw only), so the shot over the shoulder faces him.
local function faceHim()
	local model = npcModel()
	local root = myRoot()
	local humanoid = myHumanoid()
	if not (model and root and humanoid) or humanoid.SeatPart or root.Anchored then
		return
	end
	local at = model:GetPivot().Position
	local from = root.Position
	if Vector3.new(at.X - from.X, 0, at.Z - from.Z).Magnitude < 0.5 then
		return
	end
	root.CFrame = CFrame.lookAt(from, Vector3.new(at.X, from.Y, at.Z))
end

--==============================================================================
-- THE RUNS: his lines and the player's, one after another; a newer run, the
-- odds or a close ends an older one
--==============================================================================
local function alive(mine: number): boolean
	return isOpen and generation == mine
end

local function wait(seconds: number, mine: number): boolean
	local stop = os.clock() + seconds
	repeat
		task.wait()
		if not alive(mine) then
			return false
		end
	until os.clock() >= stop
	return true
end

-- His line, typed; true once all of it shows (still this run's).
local function says(text: string, mine: number): boolean
	setHis(text)
	return wait(MosskeeperTalk.typeTime(text, reduced()), mine)
end

local function run(body: (number) -> ())
	generation += 1
	local mine = generation
	task.spawn(body, mine)
end

local function greet()
	showReplies(false)
	run(function(mine: number)
		local active = Workspace:GetAttribute(EnchantedMistConfig.Attributes.State) == EnchantedMistConfig.States.Active
		if says(MosskeeperTalk.greeting(active), mine) then
			showReplies(true)
		end
	end)
end

local setOpen: (boolean, boolean?) -> ()

local function openOdds()
	mode = "odds"
	talkGui.Enabled = false
	oddsView.setShown(true)
	modal.fitContent(42 + GAP + MARGIN + oddsHolder.Size.Y.Offset)
	modal.setOpen(true)
end

local function closeOdds()
	if mode ~= "odds" then
		return
	end
	oddsView.setShown(false)
	modal.setOpen(false)
	showReplies(true)
end

local function pick(i: number)
	local option = OPTIONS[i]
	if not (isOpen and option and mode == "replies") then
		return
	end
	selected = i
	showReplies(false)
	-- The player's line takes his place (the clip): his comes back with his answer.
	setHis(nil)
	setYou(option.text)
	if option.id == "bye" then
		setOpen(false)
		return
	end
	if option.id == "give" then
		answer = nil
		asked = os.clock()
		channel:FireServer(CFG.ClientAction)
	end
	run(function(mine: number)
		if not wait(TALK.PlayerHold, mine) then
			return
		end
		setYou(nil)
		if option.id == "odds" then
			openOdds()
			return
		elseif option.id == "howto" then
			local lines = MosskeeperTalk.howTo()
			for n, line in ipairs(lines) do
				if not says(line, mine) then
					return
				end
				if n < #lines and not wait(MosskeeperTalk.readTime(line), mine) then
					return
				end
			end
		else
			-- The server's answer, or as long as it is worth waiting for one.
			local since = asked or os.clock()
			while answer == nil and os.clock() - since < TALK.Patience do
				if not wait(0.05, mine) then
					return
				end
			end
			local text, ok = MosskeeperTalk.answer(answer or { phase = "refused", reason = "BUSY" })
			answer = nil
			asked = nil
			if not ok then
				SoundKit.play("NoticeBlocked")
			end
			if not says(text, mine) then
				return
			end
		end
		showReplies(true)
	end)
end

--==============================================================================
-- AN ADMIN'S LINE (2026-10-12, the owner's item 12: MOSSKEEPER SAYS)
--
-- The server's words -- already filtered for everyone -- whole in his bubble
-- over his head, as long as an admin announcement or its reading time if that
-- is longer (MosskeeperTalk.sayTime). They come on the Workspace
-- (Mosskeeper.SaidAttribute), so a late joiner reads the rest of a line already
-- up, and one not streamed in yet (him far off) shows once he is, while its
-- time lasts. Never over a talk: a player talking to him sees it once the talk
-- closes, if its time is not up yet. Each line counts (n), so the same words
-- said again keep their own full time.
--
-- SKIPPED (the owner, 2026-10-12) by a click or a tap anywhere -- a mouse
-- button, a touch, the pad's A or R2 -- once it has stood SaySkipAfter: on this
-- screen only, and for good (a talk's close does not bring it back). Heard on
-- UserInputService, never bound or sunk, so the press still does its own job.
-- A touch that starts on the move stick never skips it, so walking never does
-- (MosskeeperTalk.skipsSaid); his talk's own lines are never skipped here.
--==============================================================================
local said: { text: string?, untilAt: number, n: number, shownAt: number? } =
	{ text = nil, untilAt = 0, n = 0, shownAt = nil }

local function hideSaid()
	said.text = nil
	said.shownAt = nil
	setHis(nil)
end

local function showSaid()
	local text = said.text
	if not text or isOpen or os.clock() >= said.untilAt then
		return
	end
	local mine = said.n
	if not npcModel() then
		-- Not streamed in yet: again shortly, while its time lasts.
		task.delay(0.5, function()
			if said.n == mine and said.shownAt == nil then
				showSaid()
			end
		end)
		return
	end
	if not hud then
		measureHud()
	end
	sizeBubbles()
	setHis(text)
	hisLabel.MaxVisibleGraphemes = -1
	said.shownAt = os.clock()
	task.delay(said.untilAt - os.clock(), function()
		if said.n == mine and not isOpen then
			hideSaid()
		end
	end)
end

-- The line on the Workspace, read now and whenever it changes.
local function readSaid()
	local raw = Workspace:GetAttribute(CFG.SaidAttribute)
	if type(raw) ~= "string" then
		return
	end
	local ok, line = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	local n, text, left = MosskeeperTalk.saidLeft(if ok then line else nil, Workspace:GetServerTimeNow())
	if n == nil or text == nil or left == nil or n == said.n then
		return
	end
	said.n = n
	said.text = text
	said.untilAt = os.clock() + left
	said.shownAt = nil
	showSaid()
end

-- The move stick's area, whichever the player uses (the PlayerModule's
-- TouchGui: the dynamic stick's whole area or the classic stick's frame,
-- while showing), in the press's pixels.
local STICKS = { "DynamicThumbstickFrame", "ThumbstickFrame" }

local function stickRects(): { MosskeeperTalk.Rect }
	local rects: { MosskeeperTalk.Rect } = {}
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local controls = if touchGui and touchGui:IsA("ScreenGui") and touchGui.Enabled
		then touchGui:FindFirstChild("TouchControlFrame")
		else nil
	if controls then
		for _, name in ipairs(STICKS) do
			local frame = controls:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") and frame.Visible then
				table.insert(rects, { x = frame.AbsolutePosition.X, y = frame.AbsolutePosition.Y,
					w = frame.AbsoluteSize.X, h = frame.AbsoluteSize.Y })
			end
		end
	end
	return rects
end

-- One of the game's own buttons under a touch (never the Roblox controls').
local function onGameButton(x: number, y: number): boolean
	local touchGui = playerGui:FindFirstChild("TouchGui")
	for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(x, y)) do
		if object:IsA("GuiButton") and object.Active and not (touchGui and object:IsDescendantOf(touchGui)) then
			return true
		end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input: InputObject)
	local shownAt = said.shownAt
	if not said.text or not shownAt or isOpen or os.clock() >= said.untilAt then
		return
	end
	local touch = input.UserInputType == Enum.UserInputType.Touch
	local press: MosskeeperTalk.Press = {
		kind = input.UserInputType,
		key = input.KeyCode,
		x = input.Position.X,
		y = input.Position.Y,
		onButton = touch and onGameButton(input.Position.X, input.Position.Y),
	}
	if MosskeeperTalk.skipsSaid(press, os.clock() - shownAt, if touch then stickRects() else {}) then
		hideSaid()
	end
end)

--==============================================================================
-- OPEN AND CLOSE
--==============================================================================
local closers: { RBXScriptConnection } = {}

local function onFrame()
	-- His line typing.
	local line = hisLine
	if line then
		local n, done = MosskeeperTalk.typed(line.text, os.clock() - line.started, reduced())
		hisLabel.MaxVisibleGraphemes = if done then -1 else n
	end
	-- The player's own line stands its time.
	if youBoard.Enabled and os.clock() >= youUntil then
		setYou(nil)
	end
	if mode == "replies" and talkGui.Enabled and os.clock() - laidOutAt >= 0.25 then
		layoutReplies()
	end
end

-- OUT OF THE WAY WHILE TALKING (2026-10-12, the owner on a phone): his TAP TALK
-- prompt -- the talk is already open -- and this player's own VIP name, which
-- the talk's camera looks past at his bar; on this screen only, each given back
-- as it was when the talk closes. (The ADMIN and REBIRTH titles step aside by
-- themselves, OwnerTitleUI reading TalkingAttribute; so does the hub's sign.)
local VIP_TAG = GameConfig.Pass.VipName.Tag
local putAway: { [Instance]: boolean } = {}

local function putAwayForTalk(on: boolean)
	if not on then
		for thing in pairs(putAway) do
			if thing.Parent then
				(thing :: any).Enabled = true
			end
		end
		table.clear(putAway)
		return
	end
	local model = npcModel()
	local talk = model and model:FindFirstChild(CFG.PromptName, true)
	if talk and talk:IsA("ProximityPrompt") and talk.Enabled then
		talk.Enabled = false
		putAway[talk] = true
	end
	local character = player.Character
	if character then
		for _, gui in ipairs(CollectionService:GetTagged(VIP_TAG)) do
			if gui:IsA("BillboardGui") and gui.Enabled and (gui:IsDescendantOf(character)
				or (gui.Adornee ~= nil and gui.Adornee:IsDescendantOf(character))) then
				gui.Enabled = false
				putAway[gui] = true
			end
		end
	end
end

setOpen = function(want: boolean, now: boolean?)
	if want == isOpen then
		return
	end
	isOpen = want
	generation += 1
	for _, c in ipairs(closers) do
		c:Disconnect()
	end
	table.clear(closers)
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL)
		player:SetAttribute(CFG.TalkingAttribute, true)
		putAwayForTalk(true)
		answer = nil
		asked = nil
		selected = 1
		hovered = nil
		measureHud()
		sizeBubbles()
		faceHim()
		takeCamera()
		greet()
		table.insert(closers, RunService.RenderStepped:Connect(onFrame))
		ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state)
			if state == Enum.UserInputState.Begin then
				if mode == "odds" then
					closeOdds()
				else
					setOpen(false)
				end
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
		-- Keys 1-4 and A answer him while he talks -- never the strip's slots,
		-- never a jump. With the odds up, A is the panel's.
		ContextActionService:BindActionAtPriority(REPLY_ACTION, function(_, state, input)
			if mode == "odds" then
				return Enum.ContextActionResult.Pass
			end
			if state == Enum.UserInputState.Begin then
				local key = REPLY_KEYS[input.KeyCode]
				if key then
					pick(key)
				elseif input.KeyCode == Enum.KeyCode.ButtonA then
					pick(selected)
				end
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
			Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour,
			Enum.KeyCode.ButtonA)
		-- The D-pad walks the replies (UserInputService: a GUI selection would
		-- take it from ContextActionService first).
		table.insert(closers, UserInputService.InputBegan:Connect(function(input: InputObject)
			if mode ~= "replies" then
				return
			end
			local step = if input.KeyCode == Enum.KeyCode.DPadDown then 1
				elseif input.KeyCode == Enum.KeyCode.DPadUp then -1
				else 0
			if step ~= 0 then
				selected = (selected - 1 + step) % #OPTIONS + 1
				paintReplies()
			end
		end))
		table.insert(closers, PadInput.Changed:Connect(paintReplies))
		-- Walking away, him going, death and respawn all close it.
		table.insert(closers, RunService.Heartbeat:Connect(function()
			local still = npcModel()
			local root = myRoot()
			local plate = still and still:FindFirstChild(MosskeeperModel.PromptPart)
			if not (still and root and plate and plate:IsA("BasePart"))
				or (root.Position - plate.Position).Magnitude > CFG.CloseDistance then
				setOpen(false, true)
			end
		end))
		local humanoid = myHumanoid()
		if humanoid then
			table.insert(closers, humanoid.Died:Connect(function()
				setOpen(false, true)
			end))
		end
		table.insert(closers, player.CharacterRemoving:Connect(function()
			setOpen(false, true)
		end))
	else
		ContextActionService:UnbindAction(BACK_ACTION)
		ContextActionService:UnbindAction(REPLY_ACTION)
		mode = "busy"
		oddsView.setShown(false)
		modal.setOpen(false)
		talkGui.Enabled = false
		setHis(nil)
		-- A Nevermind still stands over the player's head its time.
		if not youBoard.Enabled or now then
			setYou(nil)
		else
			task.delay(math.max(0, youUntil - os.clock()), function()
				if not isOpen then
					setYou(nil)
				end
			end)
		end
		releaseCamera(now == true)
		player:SetAttribute(CFG.TalkingAttribute, nil)
		putAwayForTalk(false)
		if player:GetAttribute(ATTR.OpenPanel) == PANEL then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		-- An admin's line said while this talk ran, if its time is not up.
		showSaid()
	end
end

for i, reply in ipairs(replies) do
	reply.hit.Activated:Connect(function()
		pick(i)
	end)
	reply.hit.MouseEnter:Connect(function()
		hovered = i
		paintReplies()
	end)
	reply.hit.MouseLeave:Connect(function()
		if hovered == i then
			hovered = nil
			paintReplies()
		end
	end)
end
oddsBack.hit.Activated:Connect(closeOdds)
modal.close.Activated:Connect(closeOdds)
modal.dimmer.Activated:Connect(closeOdds)
GuiService.MenuOpened:Connect(function()
	setOpen(false, true)
end)

-- One panel at a time: another panel's name closes this one.
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if isOpen and player:GetAttribute(ATTR.OpenPanel) ~= PANEL then
		setOpen(false, true)
	end
end)
for _, name in ipairs({ PA.Carried, PA.Progress }) do
	player:GetAttributeChangedSignal(name):Connect(function()
		if isOpen then
			refreshCounts()
		end
	end)
end

--==============================================================================
-- THE SERVER'S ANSWERS
--==============================================================================
channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= CFG.ServerAction or type(payload) ~= "table" then
		return
	end
	if payload.phase == "open" then
		setOpen(true)
		SoundKit.play("MistHello")
	elseif payload.phase == "given" or payload.phase == "refused" then
		if payload.phase == "given" then
			-- Under the bar filling (POD EARNED, if it made one, is the bar's: MosskeeperView).
			SoundKit.play("MistGiveAll")
		end
		if isOpen and asked then
			answer = payload
		end
	end
end)

-- An admin's line (MosskeeperService.Say): everybody's, talking or not -- and
-- the rest of one already up when this player joined.
Workspace:GetAttributeChangedSignal(CFG.SaidAttribute):Connect(readSaid)
readSaid()

-- A reload mid-talk never leaves the camera borrowed.
script.Destroying:Connect(function()
	setOpen(false, true)
	measureGui:Destroy()
	talkGui:Destroy()
	hisBoard:Destroy()
	youBoard:Destroy()
end)
