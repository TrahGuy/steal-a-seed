--!strict
-- Steal a Seed :: AdminConsoleUI
--
-- The developer console's client, REDESIGNED 2026-10-07 (the owner's brief):
-- an ADMIN button in the topbar beside the clock, and behind it the ADMIN
-- CONSOLE -- MenuKit's studded rim, its title in the owner's badge (rainbow
-- letters, a dark edge: OwnerTitleService's recipe), a thin red keyline round
-- the frame, the close X, and no dimmer (UIKit's see-through one). Inside:
--
--   TABS        PLAYER, SPAWN, WORLD, ANNOUNCE in the header row -- a row that
--               scrolls where it is narrower than they are (a phone)
--   TARGET BAR  one, under the tabs, for every tab: who the actions are for --
--               headshot, display name, @username, and their cash, Speed and
--               bag room, live (the server's Roster). You by default.
--   PLAYER      ADD MONEY and ADD SPEED: a box that takes K, M, B, T and Qd and
--               shows the full number before anything is sent, quick chips (1M,
--               1B, 1T, 1Qd, MAX) and the limit; RESET PROGRESS in its own red
--               box at the bottom, behind the typed username
--   SPAWN       group chips and a search over a grid of species cards (each
--               with its picture); POD or GROWN; the sizes it really comes in
--               (the rest dimmed, no picker for a fixed size); how many, up to
--               the target's free bag room; the preview line; SPAWN
--   WORLD       Start Night, Start Day; the weather -- every admin account's
--               since 2026-10-07 (the owner's alone before); the mini events
--   ANNOUNCE    the words and their count, THIS SERVER or ALL SERVERS, SEND
--   LOG         under every tab: the last five answers, green done or red
--               refused, with the time
--
-- Every command the console had before, and SPAWN (AdminService, 2026-10-07)
-- in place of the two-Secret grant. Each button sends exactly what
-- ConsoleModel.args says -- the shapes it always sent -- through the one
-- RemoteFunction. What the server answered is the log.
--
--==============================================================================
-- IT DOES NOT SHIP TO ANYBODY ELSE
--
-- This script is a child of AdminService, on the server, where nothing
-- replicates. AdminService clones it -- with the RemoteFunction it talks
-- through and its two modules (SpawnCatalog, ConsoleModel) -- into a ScreenGui
-- in the PlayerGui of an allowlisted account, and does nothing for anybody else.
-- Whatever runs here, EVERY PRESS IS A REQUEST: the server checks the sender,
-- the target, the action, the amount, the confirm and its own waits, and
-- answers with the line the log shows. What the server puts on the gui
-- (Spawning, the waits, Roster) only changes how a control LOOKS.
--
--==============================================================================
-- DANGER IS CONFIRMED IN PLACE, NEVER IN A POPUP
--
-- RESET PROGRESS waits for the username typed back. Giving to anybody but
-- yourself, the weather and the mini events each turn their button row into
-- the question and CANCEL / CONFIRM. ALL SERVERS asks once more, as it did.
-- A request on its way locks every button; SPAWN's own wait and a request that
-- never got an answer count down on the button itself.
--
--==============================================================================
-- MOUSE, TOUCH AND CONTROLLER
--
-- Every control is a GuiButton or a text box, and every one is Selectable. LB
-- and RB step through the tabs and put the selection on the tab's main button
-- (ConsoleModel.MainButton); B steps back -- out of the player list, then out
-- of a question, then out of the console -- and Escape closes it, both bound
-- only while it is open. The grid's cards take a press only when the list was
-- not being scrolled (MenuKit.tap). One centre panel at a time: the console
-- writes its name to OpenPanel and steps aside when another panel takes it.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local parentGui = script.Parent
if not (parentGui and parentGui:IsA("ScreenGui")) then
	return
end
local screen = parentGui :: ScreenGui
local found = screen:WaitForChild("AdminRequest", 30)
if not (found and found:IsA("RemoteFunction")) then
	warn("[Seed/AdminConsoleUI] No AdminRequest remote; the console cannot ask for anything.")
	return
end
local remote = found :: RemoteFunction
local catalogModule = screen:WaitForChild("SpawnCatalog", 30)
local modelModule = screen:WaitForChild("ConsoleModel", 30)
if not (catalogModule and catalogModule:IsA("ModuleScript") and modelModule and modelModule:IsA("ModuleScript")) then
	warn("[Seed/AdminConsoleUI] The console's modules are missing; no console.")
	return
end
local SpawnCatalog = require(catalogModule) :: any
local Model = require(modelModule) :: any

local LOOK = MenuKit.Look
local INK = Color3.fromRGB(26, 24, 30)
local PLATE = Color3.fromRGB(24, 26, 32)
local GOLD = Color3.fromRGB(255, 200, 64)
local WHITE = Color3.fromRGB(255, 255, 255)
local RED = Color3.fromRGB(214, 44, 44)
local TEXT = LOOK.Text
local GOLD_TEXT = LOOK.Premium
local GOOD = LOOK.Money
local BAD = Color3.fromRGB(196, 52, 40)
local NIGHT_INK = Color3.fromRGB(44, 74, 170)
local DANGER_FILL = Color3.fromRGB(255, 236, 232)
local BACK_ACTION = "SeedAdminBack"
local PAD_ACTION = "SeedAdminPad"
local ESC_ACTION = "SeedAdminEscape"
local PANEL_NAME = "Admin"
local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes
local ANNOUNCE = GameConfig.Announce
local WEATHER = GameConfig.Weather
local MINI = GameConfig.MiniEvent
local MAX_HELD = GameConfig.Save.MaxHeld
local Z = 6

-- A mode's movement factor as a percentage (1.5 -> 50); DISCO ONLY's by default.
local function partyPercent(factor: number?): number
	local f = factor or tonumber((MINI.Modes :: any).party.SpeedFactor) or 1
	return math.floor((f - 1) * 100 + 0.5)
end

-- "Up to" (the owner's label, 2026-10-04): the boosted speed never passes
-- MaxWalkSpeed, so whoever already runs faster than this gains less.
local function partyFullBelow(): number
	local f = tonumber((MINI.Modes :: any).party.SpeedFactor) or 1
	return math.floor(GameConfig.Speed.MaxWalkSpeed / math.max(f, 1) + 0.5)
end

-- What each mini event mode gives, said under its chips.
local MODE_WORDS: { [string]: string } = {
	party = string.format("DISCO ONLY: the disco and up to +%d%% movement speed for everyone -- speed is capped at %d, so a player "
		.. "already above %d gains less (no mill, no tickets).", partyPercent(),
		GameConfig.Speed.MaxWalkSpeed, partyFullBelow()),
	disco = string.format("DISCO + MILL: the disco and the giant Disco Mill (\u{00D7}%d training while mounted).",
		MINI.DiscoMill.Multiplier),
	ticketdisco = string.format("TICKET DISCO: the disco, the mill and free Spin Tickets all over the map -- each "
		.. "one free spin, up to %d per player per event (across servers).", MINI.Tickets.PerPlayerCap),
	tickets = string.format("TICKET SHOWER ONLY: the tickets alone, up to %d per player per event.",
		MINI.Tickets.PerPlayerCap),
}
-- Inside every page and card: the list's padding, the card's, the scroll bar.
local PAGE_PAD, CARD_PAD, BAR = 8, 10, 6

--==============================================================================
-- THE BUTTON, BESIDE THE CLOCK
--
-- The clock's own plate with a gold word on it. Placed from HudLayout's
-- `admin`, in window space (this gui ignores the inset), and asked again only
-- when the screen or the topbar changes shape. In a gui above the console's,
-- so it also shuts the console.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "AdminButton"
button.BackgroundColor3 = PLATE
button.BackgroundTransparency = 0.25
button.BorderSizePixel = 0
-- The family's press (the global UI pass): a small grow under the mouse and a
-- sink under a press, never the engine's colour flash.
button.AutoButtonColor = false
button.Text = ""
button.Selectable = true
button.Visible = false
button.ZIndex = 10
button.Parent = screen
UIKit.corner(button, 10)
local buttonEdge = UIKit.stroke(button, INK, 2.5)
buttonEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIKit.clicks(button)
UIKit.pressPop(button)

local buttonWord = UIKit.outlined(button, "Word", 16, GOLD, 2)
buttonWord.AnchorPoint = Vector2.new(0.5, 0.5)
buttonWord.Position = UDim2.fromScale(0.5, 0.5)
buttonWord.Size = UDim2.new(1, -10, 1, -8)
buttonWord.TextScaled = true
buttonWord.Text = "ADMIN"
buttonWord.ZIndex = 11
do
	local wordFit = Instance.new("UITextSizeConstraint")
	wordFit.MaxTextSize = 16
	wordFit.MinTextSize = 10
	wordFit.Parent = buttonWord
end

-- STEPS ASIDE WHILE A MENU COVERS THE RAIL (2026-10-03): the compact Index and
-- Shop take a phone's whole safe area and put the rail layer under their dimmer
-- (UIKit.coverRail); this button is in its own gui above both, so it hides for
-- as long as the layer says Covered, and comes back where it was.
local railLayer = UIKit.railLayer(playerGui)
local function place()
	if screen.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(screen))
	local r = layout.admin
	if not r then
		button.Visible = false
		return
	end
	button.Position = UDim2.fromOffset(math.round(r.x), math.round(r.y))
	button.Size = UDim2.fromOffset(r.w, r.h)
	button.Visible = railLayer:GetAttribute("Covered") ~= true
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
local coverWatch = railLayer:GetAttributeChangedSignal("Covered"):Connect(place)
place()

--==============================================================================
-- THE CONSOLE: ITS OWN GUI, IN THE SAFE AREA, UNDER THE BUTTON'S
--
-- MenuLayout works in the safe area, so the console stands in a gui that keeps
-- the inset (the button's ignores it, to stand in the topbar). One below the
-- button's DisplayOrder, so the button still shuts it; over the HUD and every
-- other panel. Gone with the button's gui.
--==============================================================================
local stale = playerGui:FindFirstChild("SeedAdminPanel")
if stale then
	stale:Destroy()
end
local deck = Instance.new("ScreenGui")
deck.Name = "SeedAdminPanel"
deck.ResetOnSpawn = false
deck.IgnoreGuiInset = false
deck.DisplayOrder = 59
deck.Parent = playerGui
screen.Destroying:Once(function()
	topbarWatch:Disconnect()
	coverWatch:Disconnect()
	ContextActionService:UnbindAction(BACK_ACTION)
	ContextActionService:UnbindAction(PAD_ACTION)
	ContextActionService:UnbindAction(ESC_ACTION)
	if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	deck:Destroy()
end)

local menu = MenuKit.modal(deck, PANEL_NAME, "ADMIN CONSOLE", nil, nil)
local modal = menu.modal
local body = menu.body
modal.dimmer.Selectable = false
do
	local blocker = modal.shell:FindFirstChild("ClickBlocker")
	if blocker and blocker:IsA("GuiButton") then
		blocker.Selectable = false
	end
	-- THE OWNER'S BADGE: the title's letters filled with the wheel's rainbow over
	-- their dark edge, as the ADMIN title over the owner's head is drawn.
	local fill = Instance.new("UIGradient")
	fill.Name = "Rainbow"
	fill.Color = WheelDraw.rainbow(0)
	fill.Parent = modal.title
	modal.title.TextColor3 = WHITE
	-- A THIN RED KEYLINE just inside the frame's ink outline.
	local line = Instance.new("Frame")
	line.Name = "RedKeyline"
	line.BackgroundTransparency = 1
	line.BorderSizePixel = 0
	line.Position = UDim2.fromOffset(3, 3)
	line.Size = UDim2.new(1, -6, 1, -6)
	line.Active = false
	line.ZIndex = Z + 40
	line.Parent = modal.shell
	UIKit.corner(line, 13)
	MenuKit.keyline(line, RED, 1.5)
end
modal.close.Selectable = true
-- Where a controller's selection starts when the console opens (PadFocus reads it).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

--==============================================================================
-- WHAT IS GOING ON: one table, so the chunk keeps well under Luau's 200 locals
--==============================================================================
type Entry = { at: string, text: string, ok: boolean? }
local state = {
	open = false,
	tab = "player",
	targetId = player.UserId,
	-- The server's Roster, by UserId (AdminService: cash, Speed, the bag, ready).
	roster = {} :: { [number]: any },
	busy = false,
	-- When the server's one-a-second wait is over, and SPAWN's own.
	freeAt = 0,
	spawnFreeAt = 0,
	listOpen = false,
	-- Which question is up: nil, "give", "weather", "mini", "all".
	asking = nil :: string?,
	askVerb = nil :: string?,
	-- SPAWN's choices.
	group = "",
	search = "",
	species = nil :: SeedData.Species?,
	form = "pod",
	size = SeedData.BaseTier,
	quantity = 1,
	-- A spawn whose answer never came: sent again unchanged, and for how long.
	unanswered = nil :: { key: string, request: any, at: number }?,
	miniMode = "ticketdisco",
	scope = "server",
	log = {} :: { Entry },
}

local ui: any = {}
local grids: { { grid: UIGridLayout, max: number, min: number, scope: string } } = {}
local order: { [Instance]: number } = {}
local build: any = {}
local paint: any = {}

local function nextIn(holder: Instance): number
	local n = (order[holder] or 0) + 1
	order[holder] = n
	return n
end

local function attr(name: string, default: number): number
	local v = screen:GetAttribute(name)
	return if type(v) == "number" then v else default
end

local function usingGamepad(): boolean
	return string.find(UserInputService:GetLastInputType().Name, "Gamepad", 1, true) ~= nil
end

local function selectIfPad(target: GuiObject?)
	if target and usingGamepad() then
		GuiService.SelectedObject = target
	end
end

--==============================================================================
-- THE PIECES EVERY PAGE IS BUILT FROM
--
-- A page is a list that scrolls, on the studded baseplate: white headings with
-- an ink edge, and under each a light card holding lines, boxes and rows of
-- buttons -- two or three abreast where the width allows, one per row where it
-- does not.
--==============================================================================
function build.list(parent: Instance, name: string, gap: number?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = name
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = BAR
	s.ScrollBarImageColor3 = LOOK.WellEdge
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.Selectable = false
	s.ZIndex = Z
	s.Parent = parent
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, gap or 8)
	list.Parent = s
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, PAGE_PAD)
	pad.PaddingBottom = UDim.new(0, PAGE_PAD)
	pad.PaddingLeft = UDim.new(0, PAGE_PAD)
	pad.PaddingRight = UDim.new(0, PAGE_PAD + BAR)
	pad.Parent = s
	return s
end

-- A plain column that grows with what is in it.
function build.column(parent: Instance, name: string, gap: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = nextIn(parent)
	f.Parent = parent
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, gap or 6)
	list.Parent = f
	return f
end

-- A white LuckiestGuy heading with its ink edge, on the plate.
function build.heading(parent: Instance, text: string, colour: Color3?): TextLabel
	local h = MenuKit.heading(parent, "Heading", 18, colour or WHITE, Z + 1)
	h.LayoutOrder = nextIn(parent)
	h.Size = UDim2.new(1, 0, 0, 22)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = text
	return h
end

-- A light card under a heading: its own padding and list.
function build.card(parent: Instance, name: string, danger: boolean?): Frame
	local c = Instance.new("Frame")
	c.Name = name
	c.BackgroundColor3 = if danger then DANGER_FILL else LOOK.Card
	c.BorderSizePixel = 0
	c.Size = UDim2.new(1, 0, 0, 0)
	c.AutomaticSize = Enum.AutomaticSize.Y
	c.LayoutOrder = nextIn(parent)
	c.ZIndex = Z
	c.Parent = parent
	UIKit.corner(c, 10)
	if danger then
		MenuKit.keyline(c, BAD, 2)
	else
		MenuKit.cardFace(c)
		MenuKit.keyline(c, LOOK.CardEdge, 1.5, LOOK.CardEdgeTransparency)
	end
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = c
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, CARD_PAD)
	pad.PaddingBottom = UDim.new(0, CARD_PAD)
	pad.PaddingLeft = UDim.new(0, CARD_PAD)
	pad.PaddingRight = UDim.new(0, CARD_PAD)
	pad.Parent = c
	return c
end

-- Words that wrap and take the height they need.
function build.line(holder: Instance, name: string, size: number, colour: Color3?): TextLabel
	local l = MenuKit.body(holder, name, size, colour, Z + 1)
	l.LayoutOrder = nextIn(holder)
	l.Size = UDim2.new(1, 0, 0, size + 4)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

-- A text box in the panel's wells.
function build.box(holder: Instance, name: string, placeholder: string, height: number?): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.LayoutOrder = nextIn(holder)
	box.Size = UDim2.new(1, 0, 0, height or 40)
	box.BackgroundColor3 = LOOK.Well
	box.BackgroundTransparency = LOOK.WellTransparency
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = LOOK.BodyFont
	box.TextSize = 16
	box.TextColor3 = TEXT
	box.PlaceholderColor3 = LOOK.Placeholder
	box.PlaceholderText = placeholder
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Text = ""
	box.Selectable = true
	box.ZIndex = Z + 1
	box.Parent = holder
	UIKit.corner(box, 9)
	MenuKit.keyline(box, LOOK.WellEdge, 1)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = box
	return box
end

-- A row of buttons, `most` abreast where each can be `min` wide, fewer where
-- not. `scope` says whose width the row has (relayout): "full" a page's card,
-- "half" one of PLAYER's two cards, "controls" SPAWN's column.
function build.buttons(holder: Instance, most: number, min: number, scope: string, specs: { { string } },
	height: number?): { any }
	local frame = Instance.new("Frame")
	frame.Name = "Buttons_" .. specs[1][1]
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = nextIn(holder)
	frame.Parent = holder
	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.fromOffset(6, 4)
	grid.CellSize = UDim2.fromOffset(min, height or MenuLayout.Config.Touch)
	grid.Parent = frame
	table.insert(grids, { grid = grid, max = most, min = min, scope = scope })
	local made: { any } = {}
	for i, spec in ipairs(specs) do
		local b = MenuKit.button(frame, spec[1], Z + 1, spec[2], 15)
		b.hit.LayoutOrder = i
		b.hit.Selectable = true
		made[i] = b
	end
	return made
end

-- A small coloured dot and a line of state beside it.
function build.state(holder: Instance, name: string): (TextLabel, Frame)
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundColor3 = LOOK.Well
	row.BackgroundTransparency = LOOK.WellTransparency
	row.Size = UDim2.new(1, 0, 0, 32)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = nextIn(holder)
	row.Parent = holder
	UIKit.corner(row, 9)
	MenuKit.keyline(row, LOOK.WellEdge, 1)
	local dot = MenuKit.frame(row, "Dot", Z + 1, LOOK.Muted, 0, 6)
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 11, 0, 16)
	dot.Size = UDim2.fromOffset(12, 12)
	local words = MenuKit.body(row, "Words", 15, TEXT, Z + 1)
	words.Position = UDim2.fromOffset(30, 0)
	words.Size = UDim2.new(1, -38, 0, 32)
	words.AutomaticSize = Enum.AutomaticSize.Y
	words.TextWrapped = true
	words.TextXAlignment = Enum.TextXAlignment.Left
	return words, dot
end

-- The question that stands in for a row of buttons (DANGER IS CONFIRMED IN
-- PLACE): its words, CANCEL and CONFIRM.
function build.question(holder: Instance, name: string, scope: string, yes: string): any
	local block = build.column(holder, name, 4)
	block.Visible = false
	local words = build.line(block, "Question", 15, TEXT)
	words.Font = LOOK.BodyBoldFont
	local row = build.buttons(block, 2, 120, scope, { { "Cancel", "CANCEL" }, { "Confirm", yes } })
	row[1].style("idle")
	row[2].style("danger")
	return { block = block, words = words, cancel = row[1], confirm = row[2] }
end

-- A face beyond MenuKit's own: a locked control dark, the weather its own two
-- colours, the night its blue. Each with the family's darker foot and keyline.
local FACES: { [string]: { Color3 } } = {
	rain = { Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170), Color3.fromRGB(14, 46, 96), WHITE },
	thunder = { Color3.fromRGB(128, 104, 214), Color3.fromRGB(70, 52, 146), Color3.fromRGB(34, 22, 86), WHITE },
	night = { Color3.fromRGB(70, 92, 170), Color3.fromRGB(34, 44, 104), Color3.fromRGB(14, 20, 64), WHITE },
	speed = { Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170), Color3.fromRGB(14, 46, 96), WHITE },
}
local function face(b: any, id: string)
	local f = FACES[id]
	if f then
		b.style("go")
		b.tint.Color = MenuKit.faceColours(f[1], f[2], f[3])
		b.edge.Color = f[3]
		b.label.TextColor3 = f[4]
	else
		b.style(id)
	end
end

--==============================================================================
-- THE FRAME OF IT: the tabs in the header row, the target bar, the plate and
-- its four pages, the player list over them, the log strip
--==============================================================================
do
	local strip = Instance.new("ScrollingFrame")
	strip.Name = "Tabs"
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.ScrollBarThickness = 0
	strip.ScrollingDirection = Enum.ScrollingDirection.X
	strip.AutomaticCanvasSize = Enum.AutomaticSize.X
	strip.CanvasSize = UDim2.new()
	strip.Selectable = false
	strip.ZIndex = Z + 2
	strip.Parent = body
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, Model.Metrics.TabGap)
	list.Parent = strip
	ui.tabStrip = strip
	ui.tabs = {}
	for i, tab in ipairs(Model.Tabs) do
		local b = MenuKit.button(strip, "Tab_" .. tab.id, Z + 2, tab.label, 15)
		b.hit.LayoutOrder = i
		b.hit.Selectable = true
		ui.tabs[tab.id] = b
	end

	-- THE TARGET BAR: one button, which opens the player list.
	local bar = Instance.new("TextButton")
	bar.Name = "TargetBar"
	bar.AutoButtonColor = false
	bar.Text = ""
	bar.BackgroundColor3 = LOOK.Well
	bar.BackgroundTransparency = 0
	bar.BorderSizePixel = 0
	bar.Selectable = true
	bar.ZIndex = Z + 1
	bar.Parent = body
	UIKit.corner(bar, 10)
	ui.targetEdge = MenuKit.keyline(bar, LOOK.WellEdge, 2)
	UIKit.clicks(bar)
	local head = Instance.new("ImageLabel")
	head.Name = "Headshot"
	head.BackgroundColor3 = LOOK.Sheet
	head.BorderSizePixel = 0
	head.AnchorPoint = Vector2.new(0, 0.5)
	head.Position = UDim2.new(0, 6, 0.5, 0)
	head.ScaleType = Enum.ScaleType.Crop
	head.ZIndex = Z + 2
	head.Parent = bar
	UIKit.corner(head, 8)
	ui.targetHead = head
	local name = MenuKit.text(bar, "Name", 16, TEXT, Z + 2)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	ui.targetName = name
	local user = MenuKit.body(bar, "Username", 12, LOOK.Muted, Z + 2)
	user.TextXAlignment = Enum.TextXAlignment.Left
	user.TextTruncate = Enum.TextTruncate.AtEnd
	ui.targetUser = user
	local stats = MenuKit.text(bar, "Stats", 14, TEXT, Z + 2)
	stats.TextXAlignment = Enum.TextXAlignment.Right
	stats.TextTruncate = Enum.TextTruncate.AtEnd
	ui.targetStats = stats
	local change = MenuKit.text(bar, "Change", 13, LOOK.Muted, Z + 2)
	change.TextXAlignment = Enum.TextXAlignment.Right
	change.Text = "CHANGE"
	ui.targetChange = change
	ui.targetBar = bar

	-- THE PLATE AND ITS PAGES.
	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.ZIndex = Z
	pages.Parent = body
	ui.pages = pages
	local plate = MenuKit.baseplate(pages, Z - 1)
	plate.Size = UDim2.fromScale(1, 1)
	ui.plate = plate
	ui.page = {
		player = build.list(pages, "Page_player", 8),
		world = build.list(pages, "Page_world", 8),
		announce = build.list(pages, "Page_announce", 8),
	}
	local spawnPage = Instance.new("Frame")
	spawnPage.Name = "Page_spawn"
	spawnPage.BackgroundTransparency = 1
	spawnPage.BorderSizePixel = 0
	spawnPage.Size = UDim2.fromScale(1, 1)
	spawnPage.ZIndex = Z
	spawnPage.Parent = pages
	ui.page.spawn = spawnPage
	for _, page in pairs(ui.page) do
		page.Size = UDim2.fromScale(1, 1)
		page.Visible = false
	end

	-- THE PLAYER LIST, over the page while it is open.
	local sheet = build.list(pages, "Players", 6)
	sheet.BackgroundColor3 = LOOK.Sheet
	sheet.BackgroundTransparency = 0.02
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.Visible = false
	sheet.ZIndex = Z + 6
	UIKit.corner(sheet, 9)
	ui.sheet = sheet
	local back = MenuKit.button(sheet, "Back", Z + 7, "BACK", 15)
	back.hit.LayoutOrder = 0
	back.hit.Size = UDim2.new(0, 120, 0, MenuLayout.Config.Touch)
	back.style("sky")
	ui.sheetBack = back
	local caption = MenuKit.text(sheet, "Caption", 13, LOOK.Muted, Z + 7)
	caption.LayoutOrder = 1
	caption.Size = UDim2.new(1, 0, 0, 18)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Text = "CHOOSE A PLAYER IN THIS SERVER"

	-- THE LOG STRIP.
	local log = Instance.new("ScrollingFrame")
	log.Name = "Log"
	log.BackgroundColor3 = LOOK.Well
	log.BackgroundTransparency = 0
	log.BorderSizePixel = 0
	log.ScrollBarThickness = 4
	log.ScrollBarImageColor3 = LOOK.WellEdge
	log.CanvasSize = UDim2.new()
	log.AutomaticCanvasSize = Enum.AutomaticSize.Y
	log.ScrollingDirection = Enum.ScrollingDirection.Y
	log.Selectable = false
	log.ZIndex = Z + 1
	log.Parent = body
	UIKit.corner(log, 8)
	MenuKit.keyline(log, LOOK.WellEdge, 1)
	local logList = Instance.new("UIListLayout")
	logList.SortOrder = Enum.SortOrder.LayoutOrder
	logList.Parent = log
	local logPad = Instance.new("UIPadding")
	logPad.PaddingLeft = UDim.new(0, 8)
	logPad.PaddingRight = UDim.new(0, 8)
	logPad.PaddingTop = UDim.new(0, Model.Metrics.LogPad)
	logPad.PaddingBottom = UDim.new(0, Model.Metrics.LogPad)
	logPad.Parent = log
	ui.log = log
	ui.logLines = {}
	for i = 1, 5 do
		local l = MenuKit.body(log, "Entry" .. i, 13, LOOK.Muted, Z + 2)
		l.LayoutOrder = i
		l.Size = UDim2.new(1, 0, 0, Model.Metrics.LogLine)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = ""
		ui.logLines[i] = l
	end
end

--==============================================================================
-- THE LOG: the last five answers, newest first -- green done, red refused, and
-- grey for a question answered "no" here, where nothing was asked of anybody
--==============================================================================
local function paintLog()
	for i = 1, 5 do
		local entry = state.log[i]
		local l = ui.logLines[i]
		if entry then
			l.Text = string.format("%s   %s", entry.at, entry.text)
			l.TextColor3 = if entry.ok == true then GOOD elseif entry.ok == false then BAD else LOOK.Muted
			l.Visible = true
		else
			-- Before the first answer, the strip says what it is for.
			l.Text = if i == 1 then "The server's answers show here, newest first." else ""
			l.TextColor3 = LOOK.Muted
			l.Visible = i == 1
		end
	end
	ui.log.CanvasPosition = Vector2.zero
end

local function note(text: string, ok: boolean?)
	table.insert(state.log, 1, { at = os.date("%H:%M:%S") :: string, text = text, ok = ok })
	while #state.log > 5 do
		table.remove(state.log)
	end
	paintLog()
end
paintLog()

--==============================================================================
-- THE TARGET: a UserId, always somebody in this server, you by default
--==============================================================================
local function currentTarget(): Player
	local p = Players:GetPlayerByUserId(state.targetId)
	if not p then
		state.targetId = player.UserId
		return player
	end
	return p
end

local function headshot(userId: number): string
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", userId)
end

-- The roster's row for a player, or a blank one until the server has said.
local function rowOf(userId: number): any
	return state.roster[userId] or {}
end

local function statsLine(row: any): string
	if row.ready ~= true then
		return "PROFILE LOADING"
	end
	return string.format("$%s  \u{00B7}  %s SPEED  \u{00B7}  BAG %d/%d", GameConfig.money(tonumber(row.cash) or 0),
		GameConfig.compact(tonumber(row.speed) or 0), tonumber(row.held) or 0, MAX_HELD)
end

local function readRoster()
	local text = screen:GetAttribute("Roster")
	local rows: { [number]: any } = {}
	if type(text) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(text)
		end)
		if ok and type(decoded) == "table" then
			for _, row in ipairs(decoded) do
				if type(row) == "table" and type(row.id) == "number" then
					rows[row.id] = row
				end
			end
		end
	end
	state.roster = rows
end

--==============================================================================
-- PLAYER: ADD MONEY, ADD SPEED, RESET PROGRESS
--==============================================================================
local function grantCard(holder: Instance, key: string, title: string, money: boolean): any
	local col = build.column(holder, key, 6)
	build.heading(col, title)
	local card = build.card(col, "Card")
	local limit = attr(if money then "MaxMoney" else "MaxSpeed", 1e15)
	local box = build.box(card, "Amount", "e.g. 1.5T, 250,000 or 1Qd", 40)
	local chips: { any } = {}
	local specs: { { string } } = {}
	for _, chip in ipairs(Model.chips(limit)) do
		table.insert(specs, { "Chip" .. chip.label, chip.label })
	end
	local row = build.buttons(card, 5, 48, "half", specs, 32)
	for i, chip in ipairs(Model.chips(limit)) do
		row[i].style("sky")
		chips[i] = { button = row[i], value = chip.value }
	end
	local full = build.line(card, "Full", 15, LOOK.Muted)
	full.Font = LOOK.BodyBoldFont
	local limitLine = build.line(card, "Limit", 12, LOOK.Muted)
	limitLine.Text = string.format("LIMIT %s%s%s A REQUEST", if money then "$" else "", Model.commas(limit),
		if money then "" else " SPEED")
	local go = build.buttons(card, 1, 120, "half", { { if money then "AddMoney" else "AddSpeed",
		if money then "ADD MONEY" else "ADD SPEED" } })[1]
	if money then
		go.style("go")
	else
		face(go, "speed")
	end
	for _, chip in ipairs(chips) do
		chip.button.hit.Activated:Connect(function()
			box.Text = Model.commas(chip.value)
		end)
	end
	return { column = col, box = box, full = full, go = go, money = money, limit = limit }
end

do
	local page = ui.page.player
	-- Money and Speed: side by side where the page is wide enough (relayout).
	local pair = Instance.new("Frame")
	pair.Name = "Grants"
	pair.BackgroundTransparency = 1
	pair.Size = UDim2.new(1, 0, 0, 0)
	pair.AutomaticSize = Enum.AutomaticSize.Y
	pair.LayoutOrder = nextIn(page)
	pair.Parent = page
	local pairList = Instance.new("UIListLayout")
	pairList.SortOrder = Enum.SortOrder.LayoutOrder
	pairList.Padding = UDim.new(0, 8)
	pairList.Parent = pair
	ui.grantPair, ui.grantPairList = pair, pairList
	ui.money = grantCard(pair, "Money", "ADD MONEY", true)
	ui.speed = grantCard(pair, "Speed", "ADD SPEED", false)

	-- RESET PROGRESS: its own red box at the bottom, behind the typed username.
	local col = build.column(page, "Reset", 6)
	build.heading(col, "RESET PROGRESS", Color3.fromRGB(255, 196, 188))
	local card = build.card(col, "Danger", true)
	ui.resetWho = build.line(card, "Who", 15, TEXT)
	ui.resetWho.Font = LOOK.BodyBoldFont
	build.line(card, "Erases", 13, TEXT).Text = "ERASES AND SAVES: cash, Speed, every plant and pod, the bag, bought "
		.. "weapons, plot and mill upgrades, the Almanac and harvests, tutorial progress, offline earnings. KEPT: game "
		.. "passes, Robux purchase records, the Walk Mode setting. This cannot be undone."
	ui.typeCaption = build.line(card, "TypeCaption", 13, BAD)
	ui.typedBox = build.box(card, "TypedUsername", "Username", 40)
	ui.resetButton = build.buttons(card, 1, 120, "full", { { "ResetPlayerProgress", "RESET PROGRESS" } })[1]
	ui.resetHint = build.line(card, "Hint", 12, LOOK.Muted)
end

--==============================================================================
-- SPAWN: THE GROUPS, THE SEARCH, THE GRID AND THE CONTROLS
--==============================================================================
type Card = { species: SeedData.Species, hit: TextButton, frame: Frame, preview: any, built: boolean,
	edge: UIStroke, name: TextLabel }
local cards: { [string]: Card } = {}
local groups = SpawnCatalog.groups()
state.group = if groups[1] then groups[1].id else ""

do
	local page = ui.page.spawn
	-- The row over the grid: the group chips (a row that scrolls) and the search.
	local toolbar = Instance.new("Frame")
	toolbar.Name = "Toolbar"
	toolbar.BackgroundTransparency = 1
	toolbar.ZIndex = Z + 1
	toolbar.Parent = page
	ui.toolbar = toolbar
	local chips = Instance.new("ScrollingFrame")
	chips.Name = "Groups"
	chips.BackgroundTransparency = 1
	chips.BorderSizePixel = 0
	chips.ScrollBarThickness = 0
	chips.ScrollingDirection = Enum.ScrollingDirection.X
	chips.CanvasSize = UDim2.new()
	chips.Selectable = false
	chips.ZIndex = Z + 1
	chips.Parent = toolbar
	ui.groupStrip = chips
	-- Placed by relayout (ConsoleModel.chipPlaces): wrapped into rows where
	-- there is room, else one row that scrolls between the two arrows.
	ui.groupChips = {}
	ui.groupOrder = {}
	for i, g in ipairs(groups) do
		local b = MenuKit.button(chips, "Group_" .. g.id, Z + 2, g.label, 13)
		b.hit.LayoutOrder = i
		b.hit.Selectable = true
		b.hit.Size = UDim2.fromOffset(math.max(84, MenuKit.textWidth(g.label, 13) + 24), 30)
		ui.groupChips[g.id] = b
		ui.groupOrder[i] = g.id
	end
	ui.chipArrows = {}
	for _, side in ipairs({ -1, 1 }) do
		local arrow = MenuKit.button(toolbar, if side < 0 then "ChipsBack" else "ChipsOn", Z + 2,
			if side < 0 then "<" else ">", 14)
		arrow.hit.Selectable = true
		arrow.hit.Visible = false
		arrow.hit.Activated:Connect(function()
			-- In the strip's own units (relayout keeps both), so a UIScale
			-- cannot make a press overshoot.
			local window = ui.chipsWindow or 0
			local most = math.max(0, (ui.chipsTotal or 0) - window)
			local x = math.clamp(chips.CanvasPosition.X + side * window * 0.7, 0, most)
			chips.CanvasPosition = Vector2.new(x, 0)
		end)
		ui.chipArrows[side] = arrow
	end
	local search = MenuKit.search(toolbar, Z + 1, "Search all")
	search.box.Selectable = true
	ui.search = search

	-- THE GRID, on the plate.
	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 5
	grid.ScrollBarImageColor3 = LOOK.WellEdge
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.Selectable = false
	grid.ZIndex = Z + 1
	grid.Parent = page
	local layout = Instance.new("UIGridLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.CellPadding = UDim2.fromOffset(Model.Metrics.CardGap, Model.Metrics.CardGap)
	layout.Parent = grid
	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop = UDim.new(0, Model.Metrics.GridInset)
	gridPad.PaddingBottom = UDim.new(0, Model.Metrics.GridInset)
	gridPad.PaddingLeft = UDim.new(0, Model.Metrics.GridInset)
	gridPad.PaddingRight = UDim.new(0, Model.Metrics.GridInset)
	gridPad.Parent = grid
	ui.grid, ui.gridLayout = grid, layout

	-- THE CONTROLS: what to make, how many, for whom -- and SPAWN under them.
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.BackgroundColor3 = LOOK.Card
	controls.BorderSizePixel = 0
	controls.ZIndex = Z
	controls.Parent = page
	UIKit.corner(controls, 10)
	MenuKit.cardFace(controls)
	MenuKit.keyline(controls, LOOK.CardEdge, 1.5, LOOK.CardEdgeTransparency)
	ui.controls = controls
	local options = build.list(controls, "Options", 5)
	options.ZIndex = Z + 1
	ui.options = options
	ui.picked = build.line(options, "Picked", 15, TEXT)
	ui.picked.Font = LOOK.LabelFont
	local forms = build.buttons(options, 2, 90, "controls", { { "Pod", "POD" }, { "Grown", "GROWN PLANT" } }, 34)
	ui.pickPod, ui.pickGrown = forms[1], forms[2]
	ui.sizeCaption = build.line(options, "SizeCaption", 12, LOOK.Muted)
	local sizeSpecs: { { string } } = {}
	for tier = 1, SeedData.TierCount do
		table.insert(sizeSpecs, { "Size" .. tier, string.upper(SeedData.TierName(tier)) })
	end
	ui.sizeChips = build.buttons(options, 4, 64, "controls", sizeSpecs, 32)
	ui.sizeRow = ui.sizeChips[1].hit.Parent
	local qty = build.buttons(options, 3, 44, "controls", { { "Less", "\u{2212}" }, { "Count", "1" }, { "More", "+" } }, 36)
	ui.less, ui.count, ui.more = qty[1], qty[2], qty[3]
	ui.less.style("sky")
	ui.more.style("sky")
	ui.count.style("idle")
	ui.count.hit.Selectable = false
	ui.room = build.line(options, "Room", 12, LOOK.Muted)
	ui.preview = build.line(options, "Preview", 15, TEXT)
	ui.preview.Font = LOOK.BodyBoldFont

	-- SPAWN, or the question that stands in for it.
	local go = Instance.new("Frame")
	go.Name = "Go"
	go.BackgroundTransparency = 1
	go.ZIndex = Z + 1
	go.Parent = controls
	ui.go = go
	local spawnButton = MenuKit.button(go, "Spawn", Z + 2, "SPAWN", 18, { studs = true })
	spawnButton.hit.Size = UDim2.fromScale(1, 1)
	spawnButton.hit.Selectable = true
	spawnButton.style("go")
	ui.spawnButton = spawnButton
	local giveRow = Instance.new("Frame")
	giveRow.Name = "Give"
	giveRow.BackgroundTransparency = 1
	giveRow.Size = UDim2.fromScale(1, 1)
	giveRow.Visible = false
	giveRow.Parent = go
	ui.giveRow = giveRow
	local cancel = MenuKit.button(giveRow, "Cancel", Z + 2, "CANCEL", 15)
	cancel.hit.Size = UDim2.new(0.4, -3, 1, 0)
	cancel.hit.Selectable = true
	cancel.style("idle")
	local give = MenuKit.button(giveRow, "Give", Z + 2, "GIVE", 16, { studs = true })
	give.hit.AnchorPoint = Vector2.new(1, 0)
	give.hit.Position = UDim2.fromScale(1, 0)
	give.hit.Size = UDim2.new(0.6, -3, 1, 0)
	give.hit.Selectable = true
	give.style("danger")
	ui.giveCancel, ui.giveConfirm = cancel, give

	-- One card per species, built once; its picture only when first shown.
	for i, species in ipairs(SpawnCatalog.all()) do
		local hit = Instance.new("TextButton")
		hit.Name = "Card_" .. species.Id
		hit.AutoButtonColor = false
		hit.Text = ""
		hit.BackgroundColor3 = LOOK.Card
		hit.BorderSizePixel = 0
		hit.LayoutOrder = i
		hit.Selectable = true
		hit.Visible = false
		hit.ZIndex = Z + 2
		hit.Parent = grid
		UIKit.corner(hit, 10)
		local tint = MenuKit.cardFace(hit)
		MenuKit.cardTint(tint, GameConfig.RarityColor[species.Rarity])
		local edge = MenuKit.keyline(hit, LOOK.CardEdge, 2, LOOK.CardEdgeTransparency)
		local holder = Instance.new("Frame")
		holder.Name = "Art"
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(4, 4)
		holder.ZIndex = Z + 3
		holder.Parent = hit
		local preview = UIKit.itemPreview(holder, { name = "Picture", scrim = 1 })
		preview.holder.ZIndex = Z + 3
		preview.hero.ZIndex = Z + 3
		local nameLabel = MenuKit.text(hit, "Name", 14, TEXT, Z + 3)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Text = species.Name
		local tag = MenuKit.body(hit, "Tag", 11, GameConfig.RarityColor[species.Rarity], Z + 3)
		MenuKit.keepInk(tag)
		tag.TextXAlignment = Enum.TextXAlignment.Left
		tag.TextTruncate = Enum.TextTruncate.AtEnd
		local extra = SpawnCatalog.tagOf(species)
		tag.Text = string.upper(species.Rarity) .. (if extra then "  \u{00B7}  " .. extra else "")
		cards[species.Id] = { species = species, hit = hit, frame = holder, preview = preview, built = false,
			edge = edge, name = nameLabel }
	end
end

--==============================================================================
-- WORLD: THE DAY AND THE NIGHT, THE WEATHER (EVERY ADMIN'S), THE MINI EVENTS
--==============================================================================
do
	local page = ui.page.world
	local day = build.column(page, "DayNight", 6)
	build.heading(day, "DAY & NIGHT \u{00B7} WHOLE SERVER")
	local dayCard = build.card(day, "Card")
	ui.phaseLabel, ui.phaseDot = build.state(dayCard, "Phase")
	local dayRow = build.buttons(dayCard, 2, 140, "full", { { "StartNight", "START NIGHT" }, { "StartDay", "START DAY" } })
	ui.startNight, ui.startDay = dayRow[1], dayRow[2]
	face(ui.startNight, "night")
	ui.startDay.style("done")

	-- The weather: every admin account's since 2026-10-07 (the owner's alone
	-- before), so every console shows it (ConsoleModel.sections); the server
	-- checks the allowlist either way, and every change still asks in place.
	local weather = build.column(page, "Weather", 6)
	build.heading(weather, "WEATHER \u{00B7} THIS SERVER")
	local wCard = build.card(weather, "Card")
	ui.rainLabel, ui.rainDot = build.state(wCard, "Rain")
	build.line(wCard, "DurationCaption", 12, LOOK.Muted).Text =
		string.format("DURATION (SECONDS, %d TO %d)", WEATHER.MinSeconds, WEATHER.MaxSeconds)
	ui.rainBox = build.box(wCard, "RainSeconds", string.format("Whole seconds, %d to %d", WEATHER.MinSeconds,
		WEATHER.MaxSeconds), 40)
	ui.rainBox.Text = tostring(WEATHER.DefaultSeconds)
	local wRow = build.buttons(wCard, 3, 120, "full", { { "StartRain", "START RAIN" },
		{ "StartThunder", "THUNDERSTORM" }, { "EndRain", "STOP" } })
	ui.startRain, ui.startThunder, ui.endRain = wRow[1], wRow[2], wRow[3]
	face(ui.startRain, "rain")
	face(ui.startThunder, "thunder")
	face(ui.endRain, "danger")
	ui.weatherRow = ui.startRain.hit.Parent
	ui.weatherAsk = build.question(wCard, "WeatherQuestion", "full", "CONFIRM")
	ui.weatherSection = weather

	local mini = build.column(page, "Events", 6)
	build.heading(mini, "MINI EVENTS \u{00B7} EVERY SERVER")
	local mCard = build.card(mini, "Card")
	ui.miniLabel, ui.miniDot = build.state(mCard, "MiniStatus")
	ui.miniSync = build.line(mCard, "MiniSync", 12, LOOK.Muted)
	local modes = build.buttons(mCard, 2, 140, "full", {
		{ "DiscoOnly", "DISCO ONLY" }, { "DiscoMill", "DISCO + MILL" },
		{ "TicketDisco", "TICKET DISCO" }, { "TicketShowerOnly", "TICKET SHOWER ONLY" },
	}, 38)
	ui.miniChoices = {
		{ verb = "party", button = modes[1] },
		{ verb = "disco", button = modes[2] },
		{ verb = "ticketdisco", button = modes[3] },
		{ verb = "tickets", button = modes[4] },
	}
	ui.miniHelp = build.line(mCard, "ModeWords", 12, TEXT)
	build.line(mCard, "DurationCaption", 12, LOOK.Muted).Text =
		string.format("DURATION (SECONDS, %d TO %d)", MINI.MinSeconds, MINI.MaxSeconds)
	ui.miniBox = build.box(mCard, "MiniSeconds", string.format("Whole seconds, %d to %d", MINI.MinSeconds,
		MINI.MaxSeconds), 40)
	ui.miniBox.Text = tostring(MINI.DefaultSeconds)
	local mRow = build.buttons(mCard, 2, 140, "full", { { "StartGlobalEvent", "START EVENT" },
		{ "EndGlobalEvent", "END EVENT" } })
	ui.startMini, ui.endMini = mRow[1], mRow[2]
	ui.startMini.style("go")
	face(ui.endMini, "danger")
	ui.miniRow = ui.startMini.hit.Parent
	ui.miniAsk = build.question(mCard, "MiniQuestion", "full", "CONFIRM")
end

--==============================================================================
-- ANNOUNCE: THE WORDS, WHO HEARS THEM, SEND
--==============================================================================
do
	local page = ui.page.announce
	local col = build.column(page, "Announce", 6)
	build.heading(col, "ANNOUNCE")
	local card = build.card(col, "Card")
	local scopeRow = build.buttons(card, 2, 140, "full", { { "ThisServer", "THIS SERVER" }, { "AllServers", "ALL SERVERS" } })
	ui.thisServer, ui.allServers = scopeRow[1], scopeRow[2]
	ui.messageBox = build.box(card, "Message", string.format("Message, up to %d characters", ANNOUNCE.MaxChars), 84)
	ui.messageBox.TextWrapped = true
	ui.messageBox.TextYAlignment = Enum.TextYAlignment.Top
	ui.messageBox.MultiLine = true
	ui.counter = build.line(card, "Counter", 12, LOOK.Muted)
	ui.counter.TextXAlignment = Enum.TextXAlignment.Right
	ui.send = build.buttons(card, 1, 140, "full", { { "Send", "SEND TO THIS SERVER" } })[1]
	ui.send.style("done")
	ui.sendRow = ui.send.hit.Parent
	ui.allAsk = build.question(card, "AllQuestion", "full", "YES, ALL SERVERS")
end

--==============================================================================
-- LAYOUT: ConsoleModel's answer, applied -- the safe width AND height
--==============================================================================
local function keyboardTop(): number?
	if not UserInputService.OnScreenKeyboardVisible then
		return nil
	end
	local ok, at = pcall(function()
		return UserInputService.OnScreenKeyboardPosition
	end)
	if not ok or typeof(at) ~= "Vector2" or at.Y <= 0 then
		return nil
	end
	return (at.Y - GuiService:GetGuiInset().Y) / UIKit.scaleOf(deck)
end

local function relayout()
	local k = UIKit.scaleOf(deck)
	local safe = deck.AbsoluteSize / k
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(deck))
	local camera = Workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	local short = safe.Y - 16 < MenuLayout.Config.ShortBelow
	-- Each group chip's width, in order: its label plus padding, never under 84.
	local chipWidths: { number } = {}
	for i, g in ipairs(groups) do
		chipWidths[i] = math.max(84, MenuKit.textWidth(g.label, 13) + 24)
	end
	local L = Model.layout({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		keyboardTop = keyboardTop(),
	}, GameConfig.Rail.OutlineThickness, MenuKit.titleWidth(menu, short), chipWidths)
	menu.place(L.panel)
	local function put(object: GuiObject, r: any)
		object.Position = UDim2.fromOffset(r.x, r.y)
		object.Size = UDim2.fromOffset(r.w, r.h)
	end
	put(ui.tabStrip, L.tabs)
	for _, tab in ipairs(Model.Tabs) do
		ui.tabs[tab.id].hit.Size = UDim2.fromOffset(L.tabW, L.tabs.h)
	end
	put(ui.targetBar, L.target)
	local th = L.target.h
	ui.targetHead.Size = UDim2.fromOffset(th - 10, th - 10)
	local nameX = th + 2
	local statsW = math.clamp(math.floor(L.target.w * 0.46), 140, 380)
	ui.targetName.Position = UDim2.fromOffset(nameX, 3)
	ui.targetName.Size = UDim2.new(1, -(nameX + statsW + 70), 0, math.floor(th * 0.55))
	ui.targetUser.Position = UDim2.fromOffset(nameX, math.floor(th * 0.55))
	ui.targetUser.Size = UDim2.new(1, -(nameX + statsW + 70), 0, math.floor(th * 0.4))
	ui.targetStats.AnchorPoint = Vector2.new(1, 0.5)
	ui.targetStats.Position = UDim2.new(1, -66, 0.5, 0)
	ui.targetStats.Size = UDim2.fromOffset(statsW, th - 8)
	ui.targetChange.AnchorPoint = Vector2.new(1, 0.5)
	ui.targetChange.Position = UDim2.new(1, -8, 0.5, 0)
	ui.targetChange.Size = UDim2.fromOffset(56, th - 8)
	put(ui.pages, L.page)
	put(ui.log, L.log)

	-- SPAWN, inside the page.
	put(ui.toolbar, L.toolbar)
	put(ui.groupStrip, L.chips)
	ui.search.frame.AnchorPoint = Vector2.new(0, 0)
	put(ui.search.frame, L.search)
	-- Every group shows: wrapped into rows, or scrolling between the arrows.
	local rowH = L.search.h
	local places, _ = Model.chipPlaces(chipWidths, L.chips.w, rowH, L.chipsWrap)
	local total = 0
	for i, id in ipairs(ui.groupOrder) do
		local chip = ui.groupChips[id].hit
		chip.Size = UDim2.fromOffset(chipWidths[i], rowH)
		chip.Position = UDim2.fromOffset(places[i][1], places[i][2])
		total = math.max(total, places[i][1] + chipWidths[i])
	end
	ui.chipsTotal = total
	ui.chipsWindow = L.chips.w
	ui.groupStrip.ScrollingEnabled = not L.chipsWrap
	ui.groupStrip.CanvasSize = UDim2.fromOffset(if L.chipsWrap then 0 else total, 0)
	ui.groupStrip.CanvasPosition = Vector2.new(0, 0)
	for side, arrow in pairs(ui.chipArrows) do
		arrow.hit.Visible = L.chipArrows
		arrow.hit.Size = UDim2.fromOffset(Model.Metrics.ChipArrowW, rowH)
		arrow.hit.Position = UDim2.fromOffset(
			if side < 0 then 0 else L.chips.x + L.chips.w + Model.Metrics.ChipGap, 0)
	end
	put(ui.grid, L.grid)
	ui.gridLayout.CellSize = UDim2.fromOffset(L.cardW, L.cardH)
	ui.gridLayout.FillDirectionMaxCells = L.columns
	for _, card in pairs(cards) do
		card.frame.Size = UDim2.fromOffset(L.cardW - 8, L.previewH - 4)
		card.name.Position = UDim2.fromOffset(8, L.previewH + 1)
		card.name.Size = UDim2.fromOffset(L.cardW - 14, 16)
		local tag = card.hit:FindFirstChild("Tag") :: TextLabel?
		if tag then
			tag.Position = UDim2.fromOffset(8, L.previewH + 17)
			tag.Size = UDim2.fromOffset(L.cardW - 14, 13)
		end
	end
	put(ui.controls, L.controls)
	local goH = if L.panel.short then 40 else 48
	ui.options.Position = UDim2.fromOffset(0, 0)
	ui.options.Size = UDim2.new(1, 0, 1, -(goH + 8))
	ui.go.Position = UDim2.new(0, CARD_PAD, 1, -(goH + 6))
	ui.go.Size = UDim2.new(1, -CARD_PAD * 2, 0, goH)

	-- PLAYER: money and Speed side by side, or one over the other.
	local pageInner = L.page.w - PAGE_PAD * 2 - BAR
	ui.grantPairList.FillDirection = if L.playerSplit then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	local half = if L.playerSplit then math.floor((pageInner - 8) / 2) else pageInner
	ui.money.column.Size = UDim2.new(0, half, 0, 0)
	ui.speed.column.Size = UDim2.new(0, half, 0, 0)

	-- Every row of buttons: as many abreast as its width allows.
	local widths = {
		full = pageInner - CARD_PAD * 2,
		half = half - CARD_PAD * 2,
		controls = L.controls.w - PAGE_PAD * 2 - BAR,
	}
	for _, g in ipairs(grids) do
		local w = widths[g.scope] or widths.full
		local cols = math.clamp(math.floor((w + 6) / (g.min + 6)), 1, g.max)
		g.grid.CellSize = UDim2.fromOffset(math.max(1, math.floor((w - (cols - 1) * 6) / cols)),
			g.grid.CellSize.Y.Offset)
	end
	paint.all()
end
deck:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
	task.defer(relayout)
end)

--==============================================================================
-- ASKING
--
-- One request at a time; the server allows one a second (an announcement
-- excepted), so a press inside that second waits it out rather than being
-- refused. Every button sends what ConsoleModel.args builds, through the one
-- RemoteFunction; what the server answered is the log.
--==============================================================================
local function invoke(a: any): (boolean, any)
	return pcall(function()
		return remote:InvokeServer(a[1], a[2], a[3], a[4])
	end)
end

local function send(a: any, onReply: ((any) -> ())?): any
	if state.busy then
		return nil
	end
	state.busy = true
	paint.all()
	local wait = state.freeAt - os.clock()
	if wait > 0 and a[1] ~= "Announce" then
		task.wait(wait)
	end
	local ok, reply = invoke(a)
	if a[1] ~= "Announce" then
		state.freeAt = os.clock() + attr("MinInterval", 1)
	end
	state.busy = false
	if not ok or type(reply) ~= "table" then
		note("Couldn't reach the server. Nothing is confirmed.", false)
		paint.all()
		return nil
	end
	note(if type(reply.message) == "string" then reply.message else "No answer.", reply.ok == true)
	if onReply then
		onReply(reply)
	end
	paint.all()
	return reply
end

--==============================================================================
-- PAINTING: everything shown, from `state`
--==============================================================================
local function countdown(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return if whole >= 60 then string.format("%d:%02d", whole // 60, whole % 60) else tostring(whole)
end

local function mmss(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

function paint.tabs()
	for _, tab in ipairs(Model.Tabs) do
		ui.tabs[tab.id].style(if tab.id == state.tab then "on" else "idle")
	end
	for id, page in pairs(ui.page) do
		page.Visible = state.open and id == state.tab and not state.listOpen
	end
	ui.sheet.Visible = state.open and state.listOpen
	-- The weather for every admin account (2026-10-07).
	local shown = Model.sections("world")
	ui.weatherSection.Visible = table.find(shown, "weather") ~= nil
end

function paint.target()
	local p = currentTarget()
	local mine = p == player
	ui.targetHead.Image = headshot(p.UserId)
	ui.targetName.Text = if mine then "You  (" .. p.DisplayName .. ")" else p.DisplayName
	ui.targetUser.Text = "@" .. p.Name
	ui.targetStats.Text = statsLine(rowOf(p.UserId))
	ui.targetEdge.Color = if mine then LOOK.WellEdge else GOLD_TEXT
	ui.targetEdge.Thickness = if mine then 2 else 3
	ui.resetWho.Text = string.format("TARGET: %s (@%s, UserId %d)%s", p.DisplayName, p.Name, p.UserId,
		if mine then "  -- YOU" else "")
	ui.typeCaption.Text = string.format("TYPE %s TO CONFIRM", string.upper(p.Name))
end

-- Whether the typed username matches the target's (the server checks again).
local function typedMatches(): boolean
	local trimmed = string.match(ui.typedBox.Text, "^%s*(.-)%s*$") or ""
	return trimmed ~= "" and string.lower(trimmed) == string.lower(currentTarget().Name)
end

local function lockable(b: any, on: boolean, style: string, word: string?)
	if on then
		b.style(style)
	else
		b.style("off")
	end
	if word then
		b.set(word)
	end
end

function paint.player()
	for _, g in ipairs({ ui.money, ui.speed }) do
		local line, good = Model.fullLine(g.box.Text, g.limit, g.money)
		g.full.Text = if g.box.Text == "" then "Type an amount: 1.5T, 250,000, 1Qd" else line
		g.full.TextColor3 = if g.box.Text == "" then LOOK.Muted elseif good then GOOD else BAD
		local can = good and not state.busy
		if g.money then
			lockable(g.go, can, "go", if state.busy then "…" else "ADD MONEY")
		else
			if can then
				face(g.go, "speed")
			else
				g.go.style("off")
			end
			g.go.set(if state.busy then "…" else "ADD SPEED")
		end
	end
	local match = typedMatches()
	lockable(ui.resetButton, match and not state.busy, "danger", if state.busy then "…" else "RESET PROGRESS")
	ui.resetHint.Text = if match then "Press RESET PROGRESS to erase and save." else "Locked until the username matches."
end

-- The cards shown: the search over every group, or the chosen group.
local function shownSpecies(): { SeedData.Species }
	local out: { SeedData.Species } = {}
	if string.find(state.search, "%S") then
		for _, species in ipairs(SpawnCatalog.all()) do
			if SpawnCatalog.matches(species, state.search) then
				table.insert(out, species)
			end
		end
		return out
	end
	for _, g in ipairs(groups) do
		if g.id == state.group then
			return g.species
		end
	end
	return out
end

function paint.grid()
	local shown: { [string]: boolean } = {}
	for _, species in ipairs(shownSpecies()) do
		shown[species.Id] = true
	end
	local searching = string.find(state.search, "%S") ~= nil
	for id, chip in pairs(ui.groupChips) do
		chip.style(if not searching and id == state.group then "on" else "idle")
	end
	for id, card in pairs(cards) do
		local visible = state.open and state.tab == "spawn" and shown[id] == true
		card.hit.Visible = visible
		local picked = state.species ~= nil and (state.species :: SeedData.Species).Id == id
		card.edge.Color = if picked then LOOK.Leaf else LOOK.CardEdge
		card.edge.Thickness = if picked then 3.5 else 2
		card.edge.Transparency = if picked then 0 else LOOK.CardEdgeTransparency
		if visible and not card.built then
			card.built = true
			local size = Model.defaultSize(card.species, nil)
			local key = "admin:plant:" .. id .. ":" .. tostring(size)
			local make, kind = ItemArt.builder(key, { kind = "plant", speciesId = id, tier = size })
			card.preview.setModel(key, make, kind)
		end
	end
end

-- Spawn's request for what is chosen now, with its id kept while unanswered.
local function spawnKey(): string
	local species = state.species
	return string.format("%d|%s|%s|%d|%d", state.targetId, if species then species.Id else "", state.form,
		state.size, state.quantity)
end

function paint.spawn()
	local species = state.species
	local p = currentTarget()
	local row = rowOf(p.UserId)
	local most = Model.quantityMax(row.room)
	state.quantity = Model.clampQuantity(state.quantity, row.room)
	ui.pickPod.style(if state.form == "pod" then "on" else "idle")
	ui.pickGrown.style(if state.form == "plant" then "on" else "idle")
	if not species then
		ui.picked.Text = "CHOOSE A SPECIES"
		ui.picked.TextColor3 = LOOK.Muted
		ui.sizeCaption.Text = "SIZE"
		ui.sizeRow.Visible = false
		ui.preview.Text = ""
	else
		local s = species :: SeedData.Species
		ui.picked.Text = string.upper(s.Name) .. "  \u{00B7}  " .. string.upper(s.Rarity)
		ui.picked.TextColor3 = TEXT
		local sizes = SpawnCatalog.sizesOf(s)
		if not table.find(sizes, state.size) then
			state.size = Model.defaultSize(s, state.size)
		end
		local fixed = SpawnCatalog.fixedSize(s)
		ui.sizeRow.Visible = not fixed
		if fixed then
			local word = SpawnCatalog.sizeWord(s, state.size)
			ui.sizeCaption.Text = if word then "SIZE: " .. string.upper(word) .. " (ITS ONE SIZE)" else "ONE SIZE"
		else
			local pod = SpawnCatalog.podOf(s, state.size)
			ui.sizeCaption.Text = "SIZE" .. (if pod and state.form == "pod" then "  \u{00B7}  " .. string.upper(pod.Id) else "")
		end
		for tier, chip in ipairs(ui.sizeChips) do
			local ok = table.find(sizes, tier) ~= nil
			chip.style(if not ok then "off" elseif tier == state.size then "on" else "idle")
		end
		local name = if p == player then nil else p.Name
		ui.preview.Text = Model.preview(s, state.size, state.form, state.quantity, name)
	end
	ui.count.set(tostring(state.quantity))
	ui.room.Text = if row.ready ~= true then "BAG: LOADING"
		else string.format("MAX %d  \u{00B7}  %d FREE IN %s BAG", math.max(most, 0), tonumber(row.room) or 0,
			if p == player then "YOUR" else string.upper(p.Name) .. "'S")
	-- The button: the question for anybody else; else SPAWN, its wait or its resend.
	local asking = state.asking == "give"
	ui.giveRow.Visible = asking
	ui.spawnButton.hit.Visible = not asking
	if asking and species then
		ui.preview.Text = Model.giveQuestion(species :: SeedData.Species, state.size, state.form, state.quantity,
			p.DisplayName .. " (@" .. p.Name .. ")")
	end
	local now = os.clock()
	local pending = state.unanswered
	local answerSeconds = attr("SpawnAnswerSeconds", 300)
	if pending and now - pending.at > answerSeconds then
		state.unanswered = nil
		pending = nil
		note("No answer came for a spawn. Check the Bag before spawning it again.", false)
	end
	local word = "SPAWN"
	local can = species ~= nil and most >= 1 and screen:GetAttribute("Spawning") ~= false and not state.busy
	if state.busy then
		word = "…"
	elseif pending and pending.key == spawnKey() then
		word = "RESEND  " .. countdown(answerSeconds - (now - pending.at))
	elseif now < state.spawnFreeAt then
		word = "WAIT " .. countdown(state.spawnFreeAt - now)
		can = false
	elseif screen:GetAttribute("Spawning") == false then
		word = "SPAWNING IS OFF"
	elseif species and most < 1 then
		word = "BAG FULL"
	end
	ui.spawnButton.set(word)
	if can then
		ui.spawnButton.style("go")
	else
		ui.spawnButton.style("off")
	end
end

function paint.world()
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(phase) ~= "string" or type(endsAt) ~= "number" then
		ui.phaseLabel.Text = "NOW: THE CYCLE HAS NOT STARTED"
		ui.phaseDot.BackgroundColor3 = LOOK.Muted
	else
		local night = phase == CYCLE.PhaseNight
		ui.phaseLabel.Text = string.format("NOW: %s  \u{2022}  %s LEFT", if night then "NIGHT" else "DAY",
			mmss(endsAt - Workspace:GetServerTimeNow()))
		ui.phaseLabel.TextColor3 = if night then NIGHT_INK else TEXT
		ui.phaseDot.BackgroundColor3 = if night then NIGHT_INK else GOLD
	end
	local R = WEATHER.Attributes
	local rain = Workspace:GetAttribute(R.State)
	local rainEnds = Workspace:GetAttribute(R.EndsAt)
	if type(rain) ~= "string" or type(rainEnds) ~= "number" then
		ui.rainLabel.Text = "WEATHER: CLEAR"
		ui.rainDot.BackgroundColor3 = LOOK.Muted
	else
		local name = if Workspace:GetAttribute(R.Mode) == "thunder" then "THUNDERSTORM" else "RAIN"
		ui.rainLabel.Text = if rain == "closing" then name .. ": ENDING"
			else string.format("%s: %s  \u{2022}  %s LEFT", name, if rain == "active" then "ACTIVE" else "STARTING",
				mmss(rainEnds - Workspace:GetServerTimeNow()))
		ui.rainDot.BackgroundColor3 = if rain == "closing" then LOOK.Muted else GOOD
	end
	local A = MINI.Attributes
	local miniState = Workspace:GetAttribute(A.State)
	local miniEnds = Workspace:GetAttribute(A.EndsAt)
	local mode = (MINI.Modes :: any)[Workspace:GetAttribute(A.Mode) or ""]
	if type(miniState) ~= "string" or type(miniEnds) ~= "number" or not mode then
		ui.miniLabel.Text = "NO GLOBAL EVENT RUNNING HERE"
		ui.miniDot.BackgroundColor3 = LOOK.Muted
	else
		-- The pure DISCO ONLY says what it gives everybody (2026-10-04).
		local factor = tonumber(mode.SpeedFactor)
		local boost = if factor and factor > 1 then string.format(" (UP TO +%d%% SPEED)", partyPercent(factor)) else ""
		ui.miniLabel.Text = if miniState == "ending" then mode.Name .. ": ENDING"
			else string.format("%s%s  \u{2022}  %s LEFT", mode.Name, boost, mmss(miniEnds - Workspace:GetServerTimeNow()))
		ui.miniDot.BackgroundColor3 = if miniState == "ending" then LOOK.Muted else GOOD
	end
	ui.miniHelp.Text = MODE_WORDS[state.miniMode] or ""
	local sync = screen:GetAttribute("MiniStatus")
	ui.miniSync.Text = if type(sync) == "string" then sync else "Waiting for the server's sync status…"
	for _, choice in ipairs(ui.miniChoices) do
		choice.button.style(if choice.verb == state.miniMode then "on" else "idle")
	end
	local weatherAsk = state.asking == "weather"
	ui.weatherAsk.block.Visible = weatherAsk
	ui.weatherRow.Visible = not weatherAsk
	local miniAsk = state.asking == "mini"
	ui.miniAsk.block.Visible = miniAsk
	ui.miniRow.Visible = not miniAsk
	for _, b in ipairs({ ui.startNight, ui.startDay, ui.startRain, ui.startThunder, ui.endRain, ui.startMini,
		ui.endMini }) do
		b.label.TextTransparency = if state.busy then 0.5 else 0
	end
end

function paint.announce()
	local all = state.scope == "all"
	ui.thisServer.style(if all then "idle" else "on")
	ui.allServers.style(if all then "on" else "idle")
	ui.send.set(if state.busy then "…" elseif all then "SEND TO ALL SERVERS" else "SEND TO THIS SERVER")
	local asking = state.asking == "all"
	ui.allAsk.block.Visible = asking
	ui.sendRow.Visible = not asking
	local length = utf8.len(ui.messageBox.Text) or 0
	ui.counter.Text = string.format("%d / %d", length, ANNOUNCE.MaxChars)
	ui.counter.TextColor3 = if length == 0 then LOOK.Muted elseif length >= ANNOUNCE.MaxChars then GOLD_TEXT else TEXT
end

-- The control a controller starts on in this tab: its main button.
local function mainButton(): GuiObject?
	local which = Model.MainButton[state.tab]
	if which == "AddMoney" then
		return ui.money.go.hit
	elseif which == "Spawn" then
		return if ui.giveRow.Visible then ui.giveCancel.hit else ui.spawnButton.hit
	elseif which == "StartNight" then
		return ui.startNight.hit
	elseif which == "Send" then
		return ui.send.hit
	end
	return nil
end

function paint.all()
	paint.tabs()
	paint.target()
	paint.player()
	paint.grid()
	paint.spawn()
	paint.world()
	paint.announce()
	padFirst.Value = mainButton()
end

--==============================================================================
-- THE TABS, THE QUESTIONS, THE PLAYER LIST
--==============================================================================
local function setAsking(what: string?, verb: string?)
	state.asking = what
	state.askVerb = verb
	paint.all()
end

local function setTab(id: string)
	if not ui.page[id] then
		return
	end
	state.tab = id
	state.listOpen = false
	if state.asking ~= nil then
		setAsking(nil, nil)
	end
	local page = ui.page[id]
	if page:IsA("ScrollingFrame") then
		page.CanvasPosition = Vector2.zero
	end
	paint.all()
	selectIfPad(mainButton())
end

for _, tab in ipairs(Model.Tabs) do
	ui.tabs[tab.id].hit.Activated:Connect(function()
		setTab(tab.id)
	end)
end

local rows: { GuiObject } = {}

-- One row of the player list, as the target bar shows a player: the headshot,
-- the display name with the @username small under it, and their cash, Speed
-- and bag at the right. The current target's row wears the leaf-green edge.
local function playerRow(p: Player, chosen: boolean, order: number): TextButton
	local row = Instance.new("TextButton")
	row.Name = "Player_" .. tostring(p.UserId)
	row.AutoButtonColor = false
	row.Text = ""
	row.BackgroundColor3 = LOOK.Card
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 48)
	row.LayoutOrder = order
	row.Selectable = true
	row.ZIndex = Z + 7
	row.Parent = ui.sheet
	UIKit.corner(row, 10)
	MenuKit.cardFace(row)
	MenuKit.keyline(row, if chosen then LOOK.Leaf else LOOK.CardEdge, if chosen then 3 else 1.5)
	UIKit.clicks(row)
	local head = Instance.new("ImageLabel")
	head.Name = "Headshot"
	head.BackgroundColor3 = LOOK.Sheet
	head.BorderSizePixel = 0
	head.Position = UDim2.fromOffset(6, 6)
	head.Size = UDim2.fromOffset(36, 36)
	head.ScaleType = Enum.ScaleType.Crop
	head.Image = headshot(p.UserId)
	head.ZIndex = Z + 8
	head.Parent = row
	UIKit.corner(head, 8)
	local name = MenuKit.text(row, "Name", 15, TEXT, Z + 8)
	name.Position = UDim2.fromOffset(50, 5)
	name.Size = UDim2.new(0.5, -50, 0, 20)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = if p == player then "You  (" .. p.DisplayName .. ")" else p.DisplayName
	local user = MenuKit.body(row, "Username", 12, LOOK.Muted, Z + 8)
	user.Position = UDim2.fromOffset(50, 25)
	user.Size = UDim2.new(0.5, -50, 0, 16)
	user.TextXAlignment = Enum.TextXAlignment.Left
	user.TextTruncate = Enum.TextTruncate.AtEnd
	user.Text = "@" .. p.Name
	local stats = MenuKit.text(row, "Stats", 13, TEXT, Z + 8)
	stats.AnchorPoint = Vector2.new(1, 0.5)
	stats.Position = UDim2.new(1, -10, 0.5, 0)
	stats.Size = UDim2.new(0.5, -10, 0, 20)
	stats.TextXAlignment = Enum.TextXAlignment.Right
	stats.TextTruncate = Enum.TextTruncate.AtEnd
	stats.Text = statsLine(rowOf(p.UserId))
	return row
end

local function buildList(): GuiObject?
	for _, r in ipairs(rows) do
		r:Destroy()
	end
	table.clear(rows)
	local everyone = Players:GetPlayers()
	table.sort(everyone, function(a, b)
		if a == player then
			return true
		elseif b == player then
			return false
		end
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	local first: GuiObject? = nil
	for i, p in ipairs(everyone) do
		local r = playerRow(p, p.UserId == state.targetId, 1 + i)
		local id = p.UserId
		r.Activated:Connect(function()
			if id ~= state.targetId and state.asking == "give" then
				note("The target changed, so the question was closed. Nothing was given.", nil)
			end
			state.targetId = id
			state.asking = nil
			state.listOpen = false
			ui.typedBox.Text = ""
			paint.all()
			selectIfPad(ui.targetBar)
		end)
		table.insert(rows, r)
		first = first or r
	end
	return first
end

local function setList(want: boolean)
	state.listOpen = want
	if want then
		local first = buildList()
		ui.sheet.CanvasPosition = Vector2.zero
		paint.all()
		selectIfPad(first)
	else
		paint.all()
		selectIfPad(ui.targetBar)
	end
end
ui.targetBar.Activated:Connect(function()
	setList(not state.listOpen)
end)
ui.sheetBack.hit.Activated:Connect(function()
	setList(false)
end)

--==============================================================================
-- PLAYER'S BUTTONS
--==============================================================================
for _, g in ipairs({ ui.money, ui.speed }) do
	g.box:GetPropertyChangedSignal("Text"):Connect(paint.player)
	g.go.hit.Activated:Connect(function()
		local amount, why = Model.parseAmount(g.box.Text, g.limit)
		if not amount then
			note("Not sent: " .. (why or "type an amount."), false)
			return
		end
		local target = currentTarget().UserId
		task.spawn(send, if g.money then Model.args.addMoney(target, amount) else Model.args.addSpeed(target, amount))
	end)
end
ui.typedBox:GetPropertyChangedSignal("Text"):Connect(paint.player)
ui.resetButton.hit.Activated:Connect(function()
	if state.busy or not typedMatches() then
		return
	end
	local typed = ui.typedBox.Text
	ui.typedBox.Text = ""
	task.spawn(send, Model.args.reset(currentTarget().UserId, typed))
end)

--==============================================================================
-- SPAWN'S BUTTONS
--
-- A press is only ever a request: the server checks the allowlist, the species
-- and its size, the target and its confirm, its own wait and the bag's room,
-- and gives all of it or none. A request with no answer keeps its id, so the
-- same press again is answered rather than given twice -- for as long as the
-- server remembers it (SpawnAnswerSeconds), counted down on the button.
--==============================================================================
for _, g in ipairs(groups) do
	ui.groupChips[g.id].hit.Activated:Connect(function()
		state.group = g.id
		ui.search.set("")
		state.search = ""
		ui.grid.CanvasPosition = Vector2.zero
		paint.all()
	end)
end
ui.search.changed(function(text: string)
	state.search = text
	ui.grid.CanvasPosition = Vector2.zero
	paint.all()
end)
for _, card in pairs(cards) do
	MenuKit.tap(card.hit, ui.grid, function()
		state.species = card.species
		state.size = Model.defaultSize(card.species, state.size)
		if state.asking == "give" then
			state.asking = nil
		end
		paint.all()
	end)
end
ui.pickPod.hit.Activated:Connect(function()
	state.form = "pod"
	paint.all()
end)
ui.pickGrown.hit.Activated:Connect(function()
	state.form = "plant"
	paint.all()
end)
for tier, chip in ipairs(ui.sizeChips) do
	chip.hit.Activated:Connect(function()
		local species = state.species
		if species and SpawnCatalog.allows(species, tier) then
			state.size = tier
			paint.all()
		end
	end)
end
ui.less.hit.Activated:Connect(function()
	state.quantity = math.max(1, state.quantity - 1)
	paint.all()
end)
ui.more.hit.Activated:Connect(function()
	state.quantity += 1
	paint.all()
end)

local function spawnNow(confirmName: string?)
	local species = state.species
	if not species or state.busy then
		return
	end
	local key = spawnKey()
	local pending = state.unanswered
	local request = if pending and pending.key == key then pending.request
		else Model.spawnRequest(species.Id, state.form, state.size, state.quantity, HttpService:GenerateGUID(false))
	local a = Model.args.spawn(state.targetId, request, confirmName)
	state.asking = nil
	local reply = send(a, function(r: any)
		if r.ok == true then
			state.spawnFreeAt = os.clock() + attr("SpawnCooldown", 6)
		end
	end)
	if reply == nil then
		-- No answer: maybe nothing happened, maybe it did. The same press sends
		-- the same id, which the server answers instead of giving again.
		state.unanswered = { key = key, request = request, at = if pending and pending.key == key then pending.at
			else os.clock() }
	else
		state.unanswered = nil
	end
	paint.all()
end

ui.spawnButton.hit.Activated:Connect(function()
	if ui.spawnButton.face() == "off" or state.busy then
		return
	end
	local p = currentTarget()
	if p ~= player then
		-- Anybody but yourself: the question first, in place of the button.
		setAsking("give", nil)
		selectIfPad(ui.giveCancel.hit)
		return
	end
	task.spawn(spawnNow, nil)
end)
ui.giveCancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("Not given.", nil)
	selectIfPad(ui.spawnButton.hit)
end)
ui.giveConfirm.hit.Activated:Connect(function()
	task.spawn(spawnNow, currentTarget().Name)
end)

--==============================================================================
-- WORLD'S BUTTONS
--==============================================================================
local function seconds(box: TextBox): number?
	local cleaned = (string.gsub(box.Text, "[,%s_]", ""))
	return tonumber(cleaned)
end

ui.startNight.hit.Activated:Connect(function()
	task.spawn(send, Model.args.startNight(currentTarget().UserId))
end)
ui.startDay.hit.Activated:Connect(function()
	task.spawn(send, Model.args.startDay(currentTarget().UserId))
end)
local function askWeather(verb: string)
	local secs = seconds(ui.rainBox)
	if verb ~= "end" and not secs then
		note("Not sent: type the duration in whole seconds.", false)
		return
	end
	ui.weatherAsk.words.Text = if verb == "end" then "Stop the weather on this server?"
		else string.format("Start %s on this server for %s?", if verb == "thunder" then "a THUNDERSTORM" else "RAIN",
			mmss(secs or 0))
	setAsking("weather", verb)
	selectIfPad(ui.weatherAsk.cancel.hit)
end
ui.startRain.hit.Activated:Connect(function()
	askWeather("start")
end)
ui.startThunder.hit.Activated:Connect(function()
	askWeather("thunder")
end)
ui.endRain.hit.Activated:Connect(function()
	askWeather("end")
end)
ui.weatherAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("Weather unchanged.", nil)
end)
ui.weatherAsk.confirm.hit.Activated:Connect(function()
	local verb = state.askVerb or "end"
	setAsking(nil, nil)
	task.spawn(send, Model.args.weather(verb, if verb == "end" then nil else seconds(ui.rainBox)))
end)

for _, choice in ipairs(ui.miniChoices) do
	choice.button.hit.Activated:Connect(function()
		state.miniMode = choice.verb
		paint.all()
	end)
end
local function askMini(verb: string)
	local secs = seconds(ui.miniBox)
	if verb ~= "end" and not secs then
		note("Not sent: type the duration in whole seconds.", false)
		return
	end
	local mode = (MINI.Modes :: any)[verb]
	ui.miniAsk.words.Text = if verb == "end" then "End the global event on EVERY server?"
		else string.format("Start %s on EVERY server for %s?", if mode then mode.Name else string.upper(verb),
			mmss(secs or 0))
	setAsking("mini", verb)
	selectIfPad(ui.miniAsk.cancel.hit)
end
ui.startMini.hit.Activated:Connect(function()
	askMini(state.miniMode)
end)
ui.endMini.hit.Activated:Connect(function()
	askMini("end")
end)
ui.miniAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("No event started or ended.", nil)
end)
ui.miniAsk.confirm.hit.Activated:Connect(function()
	local verb = state.askVerb or "end"
	setAsking(nil, nil)
	task.spawn(send, Model.args.miniEvent(verb, if verb == "end" then nil else seconds(ui.miniBox)))
end)

--==============================================================================
-- AN ANNOUNCEMENT (2026-10-01)
--
-- THIS SERVER unless ALL SERVERS is picked, and ALL SERVERS goes only after
-- YES, ALL SERVERS -- the server refuses an unconfirmed one anyway. NO WAITING
-- BETWEEN THEM (2026-10-03): SEND takes the words into a small OUTBOX and
-- empties the box at once; the outbox goes to the server one at a time, in
-- order. One the server did not take at all gives its words back to the box.
--==============================================================================
local messageBox: TextBox = ui.messageBox
messageBox:GetPropertyChangedSignal("Text"):Connect(function()
	local length = utf8.len(messageBox.Text) or 0
	if length > ANNOUNCE.MaxChars then
		local stop = utf8.offset(messageBox.Text, ANNOUNCE.MaxChars + 1)
		if stop then
			messageBox.Text = string.sub(messageBox.Text, 1, stop - 1)
			return
		end
	end
	paint.announce()
end)

local announce: (confirmed: boolean) -> ()
do
	type Outgoing = { scope: string, text: string, confirmed: boolean }
	local outbox: { Outgoing } = {}
	local draining = false
	local OUTBOX_MAX = 8

	local function drain()
		if draining then
			return
		end
		draining = true
		while #outbox > 0 do
			while state.busy do
				task.wait(0.05)
			end
			local item = table.remove(outbox, 1) :: Outgoing
			local reply = send(Model.args.announce(item.scope, item.text, item.confirmed))
			if reply == nil or (reply.ok ~= true and reply.shown ~= true) then
				-- Nothing went anywhere: the words come back to be fixed or resent.
				if messageBox.Text == "" then
					messageBox.Text = item.text
				end
			end
		end
		draining = false
	end

	function announce(confirmed: boolean)
		local text = messageBox.Text
		if not string.find(text, "%S") then
			note("Not sent: type a message first.", false)
			return
		end
		if #outbox >= OUTBOX_MAX then
			note(string.format("%d announcements are still on their way. This one is still in the box.", #outbox), false)
			return
		end
		table.insert(outbox, { scope = state.scope, text = text, confirmed = confirmed })
		messageBox.Text = ""
		task.spawn(drain)
	end
end

ui.thisServer.hit.Activated:Connect(function()
	state.scope = "server"
	setAsking(nil, nil)
end)
ui.allServers.hit.Activated:Connect(function()
	state.scope = "all"
	setAsking(nil, nil)
end)
ui.send.hit.Activated:Connect(function()
	if state.scope == "all" then
		ui.allAsk.words.Text = "Send this to EVERY server of this place?"
		setAsking("all", nil)
		selectIfPad(ui.allAsk.cancel.hit)
	else
		announce(false)
	end
end)
ui.allAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("Not sent.", nil)
end)
ui.allAsk.confirm.hit.Activated:Connect(function()
	setAsking(nil, nil)
	announce(true)
end)

--==============================================================================
-- THE LIVE LINES: once a second while the console is open, by a task.delay
-- chain that stops as soon as it shuts -- the clocks and the countdowns
--==============================================================================
local ticker = 0
local function tick(want: boolean)
	ticker += 1
	if not want then
		return
	end
	local mine = ticker
	local function step()
		if mine ~= ticker then
			return
		end
		paint.world()
		paint.spawn()
		task.delay(1, step)
	end
	step()
end
for _, name in ipairs({ ATTR.WorldPhase, ATTR.WorldPhaseEndsAt, WEATHER.Attributes.State, WEATHER.Attributes.EndsAt,
	WEATHER.Attributes.Mode, MINI.Attributes.State, MINI.Attributes.EndsAt, MINI.Attributes.Mode }) do
	Workspace:GetAttributeChangedSignal(name):Connect(function()
		if state.open then
			paint.world()
		end
	end)
end
screen:GetAttributeChangedSignal("MiniStatus"):Connect(function()
	if state.open then
		paint.world()
	end
end)
screen:GetAttributeChangedSignal("Roster"):Connect(function()
	readRoster()
	if state.open then
		paint.target()
		paint.spawn()
	end
end)
screen:GetAttributeChangedSignal("Spawning"):Connect(paint.all)

--==============================================================================
-- OPEN AND SHUT
--
-- ONE CENTRE PANEL AT A TIME: the console writes its name to OpenPanel when it
-- opens and shuts itself on seeing another name there. It reopens on the tab
-- and the target it was left on, this session.
--==============================================================================
local setOpen: (boolean) -> ()

local function back()
	if state.listOpen then
		setList(false)
	elseif state.asking ~= nil then
		setAsking(nil, nil)
		note("Nothing was done.", nil)
		selectIfPad(mainButton())
	else
		setOpen(false)
	end
end

local function bindKeys(want: boolean)
	if not want then
		ContextActionService:UnbindAction(BACK_ACTION)
		ContextActionService:UnbindAction(PAD_ACTION)
		ContextActionService:UnbindAction(ESC_ACTION)
		return
	end
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		back()
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
	ContextActionService:BindActionAtPriority(ESC_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		setOpen(false)
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Escape)
	-- LB and RB step through the tabs, the selection on each one's main button.
	ContextActionService:BindActionAtPriority(PAD_ACTION, function(_, inputState: Enum.UserInputState,
		input: InputObject)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		setTab(Model.stepTab(state.tab, if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1))
		return Enum.ContextActionResult.Sink
	end, false, 2600, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

setOpen = function(want: boolean)
	if want == state.open then
		return
	end
	state.open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		readRoster()
		relayout()
		currentTarget()
		state.listOpen = false
		paint.all()
		modal.setOpen(true)
		bindKeys(true)
		tick(true)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		state.listOpen = false
		state.asking = nil
		tick(false)
		bindKeys(false)
		modal.setOpen(false)
		paint.all()
		local selected = GuiService.SelectedObject
		if selected and (selected:IsDescendantOf(screen) or selected:IsDescendantOf(deck)) then
			GuiService.SelectedObject = nil
		end
	end
end

button.Activated:Connect(function()
	setOpen(not state.open)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if state.open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)

--==============================================================================
-- THE ROOM CHANGING
--==============================================================================
Players.PlayerRemoving:Connect(function(leaving: Player)
	if leaving.UserId == state.targetId and leaving ~= player then
		state.targetId = player.UserId
		state.asking = nil
		ui.typedBox.Text = ""
		note(leaving.Name .. " left the server. The target is you again.", nil)
	end
	if state.listOpen then
		task.defer(function()
			if state.listOpen then
				setList(true)
			end
		end)
	end
	paint.all()
end)
Players.PlayerAdded:Connect(function()
	if state.listOpen then
		setList(true)
	end
end)

readRoster()
relayout()
paint.all()
