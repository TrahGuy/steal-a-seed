--!strict
-- Steal a Seed :: AdminConsoleUI
--
-- The developer console's client, REDESIGNED 2026-10-07 (the owner's brief)
-- and MADE COMPACT 2026-10-12 (item 11: less scrolling, above all on a phone):
-- an ADMIN button in the topbar beside the clock, and behind it the ADMIN
-- CONSOLE -- MenuKit's studded rim, its title in the owner's badge (rainbow
-- letters, a dark edge: OwnerTitleService's recipe), a thin red keyline round
-- the frame, the close X, and no dimmer (UIKit's see-through one). Inside:
--
--   TABS        PLAYER, SPAWN, WORLD, MIST, EVENTS, ANNOUNCE in the header row
--               -- a row that scrolls where it is narrower than they are; the
--               title reads ADMIN on a short screen, so all six fit a phone
--   TARGET BAR  one, under the tabs, on the tabs that act on a player (PLAYER,
--               SPAWN and MIST): who the actions are for -- headshot, display
--               name, @username, and their cash, Speed and bag room, live (the
--               server's Roster). You by default.
--   PLAYER      ADD MONEY and ADD SPEED: a box that takes K, M, B, T and Qd
--               beside its button, quick chips (1M, 1B, 1T, 1Qd, MAX), and the
--               full number before anything is sent; REBIRTHS (2026-10-13, the
--               owner's item 9): the target's count beside +1 and SET TO 0
--               (behind its question), and a box for any number to add -- the
--               count only, never a rebirth; RESET PROGRESS behind one red
--               button, and then behind the typed username
--   SPAWN       group chips and a search over a grid of species cards (each
--               with its picture); POD or GROWN PLANT; the size, stepped
--               through the sizes it really comes in; how many, up to the
--               target's free bag room; the preview line; SPAWN
--   WORLD       Start Night, Start Day; the weather -- every admin account's
--               since 2026-10-07 (the owner's alone before) -- and its duration
--               chips
--   MIST        the Enchanted Mist (2026-10-11): START / END MIST NOW and, since
--               2026-10-12 (item 12), its length, MAKE ELIGIBLE NOW, its
--               berries' count, a BERRY BURST, MOSSKEEPER SAYS, and for the
--               target their Dewberries, their progress, a Mysterious Pod and
--               READY NOW
--   EVENTS      the mini events: the mode, its duration chips, START / END
--   ANNOUNCE    the words and their count, THIS SERVER or ALL SERVERS, SEND
--   ANSWER      the server's answer to the last press, one line over the
--               page's foot -- green done, red refused -- that fades by itself
--               after about three seconds and never takes a press. (The log
--               strip it replaced is gone.)
--
-- EVERY ROW IS A FIXED HEIGHT -- a finger's 40 on a phone -- so each tab's
-- height is ConsoleModel's (pageHeight), which AdminConsoleSpec measures on
-- every listed screen.
--
-- Every command the console had before, and SPAWN (AdminService, 2026-10-07)
-- in place of the two-Secret grant. Each button sends exactly what
-- ConsoleModel.args says -- the shapes it always sent -- through the one
-- RemoteFunction. What the server answered is the answer line.
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
-- answers with the line the answer shows. What the server puts on the gui
-- (Spawning, the waits, Roster) only changes how a control LOOKS.
--
--==============================================================================
-- DANGER IS CONFIRMED IN PLACE, NEVER IN A POPUP
--
-- RESET PROGRESS opens its red box, and waits there for the username typed
-- back. Giving to anybody but yourself, the weather, the Enchanted Mist and
-- the mini events each turn their row into the question and CANCEL / CONFIRM
-- -- the same words and the same steps as before the compact console, in the
-- row's own place. ALL SERVERS asks once more, as it did. A request on its way
-- locks every button; SPAWN's own wait and a request that never got an answer
-- count down on the button itself.
--
--==============================================================================
-- MOUSE, TOUCH AND CONTROLLER
--
-- Every control is a GuiButton or a text box, and every one is Selectable. LB
-- and RB step through the tabs and put the selection on the tab's main button
-- (ConsoleModel.MainButton); B steps back -- out of the player list, then out
-- of a question, then out of the red box or the rebirth card, then out of the
-- console -- and
-- Escape closes it, both bound only while it is open. The grid's cards take a
-- press only when the list was not being scrolled (MenuKit.tap). One centre
-- panel at a time: the console writes its name to OpenPanel and steps aside
-- when another panel takes it.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
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
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

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
-- The answer's grey: a question answered "no" here, where nothing was asked of anybody.
local NEUTRAL = Color3.fromRGB(88, 94, 108)
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
local MIST = EnchantedMistConfig
local MIST_SECONDS = EnchantedMistData.Schedule.ActiveSeconds
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
	podrush = string.format("POD RUSH: nests regrow every %ds and guardians build no rage; pods stolen and banked "
		.. "count -- %d BRONZE, %d SILVER, %d GOLD. Dusk waits. Its length is %d s.",
		GameConfig.PodRush.RegrowSeconds, GameConfig.PodRush.Levels[1].Pods, GameConfig.PodRush.Levels[2].Pods,
		GameConfig.PodRush.Levels[3].Pods, MINI.Modes.podrush.Seconds),
}
-- THE COMPACT ROWS (ConsoleModel.Metrics, 2026-10-12): inside every page and
-- card, the scroll bar, and the gaps between rows, side by side and between
-- cards.
local M = Model.Metrics
local PAGE_PAD, CARD_PAD, BAR = M.PagePad, M.CardPad, M.ScrollBar
local ROW_GAP, COL_GAP, SECTION_GAP = M.RowGap, M.ColGap, M.SectionGap
-- The smallest any word here is drawn: the menus' floor (GameConfig's MinText).
local TEXT_MIN = 10

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
	-- Which question is up: nil, "give", "weather", "mist", "mini", "all".
	asking = nil :: string?,
	askVerb = nil :: string?,
	-- The duration a question asked about: what its CONFIRM sends; MOSSKEEPER
	-- SAYS's words, likewise.
	askSeconds = nil :: number?,
	askText = nil :: string?,
	-- RESET PROGRESS's red box: shut until its button opens it.
	resetOpen = false,
	-- The rebirth card (2026-10-13, item 9): shut until REBIRTHS... opens it.
	rebirthOpen = false,
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
	-- The durations chosen on the chips (ConsoleModel.WeatherSeconds, EventSeconds).
	rainSeconds = WEATHER.DefaultSeconds,
	miniSeconds = MINI.DefaultSeconds,
	-- THE MIST TAB (2026-10-12): an admin Mist's length (ConsoleModel.MistSeconds),
	-- and the Mysterious Pod to give -- nil for RANDOM, each.
	mistSeconds = MIST_SECONDS,
	podSpecies = nil :: string?,
	podSize = nil :: number?,
	scope = "server",
}

local ui: any = {}
local grids: { { grid: UIGridLayout, max: number, min: number, scope: string } } = {}
local actionRows: { any } = {}
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

-- A button whose words are never drawn under the floor (MenuKit lets them go to 9).
local function floored(b: any): any
	local fit = b.label:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MinTextSize = TEXT_MIN
	end
	return b
end

-- Places a GuiObject at one of ConsoleModel's rects.
local function put(object: GuiObject, r: any)
	object.Position = UDim2.fromOffset(r.x, r.y)
	object.Size = UDim2.fromOffset(r.w, r.h)
end

--==============================================================================
-- THE PIECES EVERY PAGE IS BUILT FROM
--
-- A page is a list that scrolls, on the studded baseplate: light cards, each
-- holding rows -- a state beside the buttons that act on it, a row of chips, a
-- box, a line. Every row is the screen's row height (ConsoleModel), so a page
-- is exactly as tall as ConsoleModel.pageHeight says.
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
	list.Padding = UDim.new(0, gap or SECTION_GAP)
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
	list.Padding = UDim.new(0, gap or ROW_GAP)
	list.Parent = f
	return f
end

-- A white LuckiestGuy heading with its ink edge.
function build.heading(parent: Instance, text: string, colour: Color3?): TextLabel
	local h = MenuKit.heading(parent, "Heading", 18, colour or WHITE, Z + 1)
	h.LayoutOrder = nextIn(parent)
	h.Size = UDim2.new(1, 0, 0, 22)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = text
	return h
end

-- A light card: its own padding and list of rows.
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
	list.Padding = UDim.new(0, ROW_GAP)
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
	box.Size = UDim2.new(1, 0, 0, height or M.RowTouch - 4)
	box.BackgroundColor3 = LOOK.Well
	box.BackgroundTransparency = LOOK.WellTransparency
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = LOOK.BodyFont
	box.TextSize = 15
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
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = box
	return box
end

-- A row of buttons (or chips), `most` abreast where each can be `min` wide,
-- fewer where not, each the screen's row height. `scope` says whose width the
-- row has (relayout): "full" a page's card, "half" one of PLAYER's two cards,
-- "controls" SPAWN's column, "page" the page itself.
function build.buttons(holder: Instance, most: number, min: number, scope: string, specs: { { string } }): { any }
	local frame = Instance.new("Frame")
	frame.Name = "Buttons_" .. specs[1][1]
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = nextIn(holder)
	frame.Parent = holder
	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.fromOffset(COL_GAP, ROW_GAP)
	grid.CellSize = UDim2.fromOffset(min, M.RowTouch)
	grid.Parent = frame
	table.insert(grids, { grid = grid, max = most, min = min, scope = scope })
	local made: { any } = {}
	for i, spec in ipairs(specs) do
		local b = floored(MenuKit.button(frame, spec[1], Z + 1, spec[2], 15))
		b.hit.LayoutOrder = i
		b.hit.Selectable = true
		made[i] = b
	end
	return made
end

-- A ROW OF STATE AND ACTION (2026-10-12): what the row acts on -- a state, a
-- box, a count, a question's words; the caller sets it as `left` -- at the
-- left, its buttons at the right; the left over the buttons where the row is
-- too narrow for both (ConsoleModel.actionInline). `scope` as a row of
-- buttons'; `most` the buttons' widest.
function build.action(holder: Instance, name: string, scope: string, specs: { { string } }, most: number?): any
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, M.RowTouch)
	frame.LayoutOrder = nextIn(holder)
	frame.Parent = holder
	local made: { any } = {}
	for i, spec in ipairs(specs) do
		local b = floored(MenuKit.button(frame, spec[1], Z + 1, spec[2], 15))
		b.hit.Selectable = true
		made[i] = b
	end
	local row = { frame = frame, left = nil :: GuiObject?, buttons = made, scope = scope, inset = 2,
		most = most or (if #specs == 1 then M.ActionWideMaxW else M.ActionMaxW) }
	table.insert(actionRows, row)
	return row
end

-- A state: a small coloured dot, the section's caption -- whom it reaches --
-- and its live line under it, in a well. The left of an action row.
function build.state(holder: Instance, name: string, caption: string?): (TextLabel, Frame, Frame)
	local well = Instance.new("Frame")
	well.Name = name
	well.BackgroundColor3 = LOOK.Well
	well.BackgroundTransparency = LOOK.WellTransparency
	well.BorderSizePixel = 0
	well.Size = UDim2.new(1, 0, 0, M.RowTouch - 4)
	well.ZIndex = Z + 1
	well.Parent = holder
	UIKit.corner(well, 9)
	MenuKit.keyline(well, LOOK.WellEdge, 1)
	local dot = MenuKit.frame(well, "Dot", Z + 2, LOOK.Muted, 0, 6)
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 9, 0.5, 0)
	dot.Size = UDim2.fromOffset(10, 10)
	if caption then
		local cap = MenuKit.body(well, "Caption", 11, LOOK.Muted, Z + 2)
		cap.Font = LOOK.BodyBoldFont
		cap.Position = UDim2.fromOffset(26, 2)
		cap.Size = UDim2.new(1, -32, 0, 13)
		cap.TextXAlignment = Enum.TextXAlignment.Left
		cap.TextTruncate = Enum.TextTruncate.AtEnd
		cap.Text = caption
	end
	local words = MenuKit.body(well, "Words", 14, TEXT, Z + 2)
	words.Position = UDim2.fromOffset(26, if caption then 15 else 0)
	words.Size = UDim2.new(1, -32, 1, if caption then -17 else 0)
	words.TextXAlignment = Enum.TextXAlignment.Left
	words.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = TEXT_MIN
	fit.Parent = words
	return words, dot, well
end

-- The question that stands in for a row (DANGER IS CONFIRMED IN PLACE): its
-- words where the row's state was, CANCEL and CONFIRM where its buttons were --
-- the same height, so nothing under it moves.
function build.question(holder: Instance, name: string, scope: string, yes: string): any
	local row = build.action(holder, name, scope, { { "Cancel", "CANCEL" }, { "Confirm", yes } })
	row.frame.Visible = false
	row.inset = 0
	local words = MenuKit.body(row.frame, "Question", 14, TEXT, Z + 1)
	words.Font = LOOK.BodyBoldFont
	words.TextWrapped = true
	words.TextScaled = true
	words.TextXAlignment = Enum.TextXAlignment.Left
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = TEXT_MIN
	fit.Parent = words
	row.left = words
	row.buttons[1].style("idle")
	row.buttons[2].style("danger")
	return { block = row.frame, words = words, cancel = row.buttons[1], confirm = row.buttons[2] }
end

-- A face beyond MenuKit's own: a locked control dark, the weather its own two
-- colours, the night its blue. Each with the family's darker foot and keyline.
local FACES: { [string]: { Color3 } } = {
	rain = { Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170), Color3.fromRGB(14, 46, 96), WHITE },
	thunder = { Color3.fromRGB(128, 104, 214), Color3.fromRGB(70, 52, 146), Color3.fromRGB(34, 22, 86), WHITE },
	night = { Color3.fromRGB(70, 92, 170), Color3.fromRGB(34, 44, 104), Color3.fromRGB(14, 20, 64), WHITE },
	-- The Enchanted Mist's mint, deepened to carry white words.
	mist = { Color3.fromRGB(54, 170, 140), Color3.fromRGB(26, 110, 92), Color3.fromRGB(10, 56, 46), WHITE },
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

-- An action row, `w` wide at the screen's row height: inline, the left takes
-- what its buttons leave; else the left on its own row over them.
local function placeAction(row: any, w: number, rowH: number)
	local n = #row.buttons
	local left: GuiObject? = row.left
	local inset = row.inset
	local inline = Model.actionInline(w, n)
	local bw = if inline then Model.actionWidth(w, n, row.most) else math.floor((w - (n - 1) * COL_GAP) / n)
	local leftW = if inline then w - n * (bw + COL_GAP) else w
	if left then
		left.Position = UDim2.fromOffset(0, inset)
		left.Size = UDim2.fromOffset(leftW, rowH - inset * 2)
	end
	for i, b in ipairs(row.buttons) do
		b.hit.Position = if inline then UDim2.fromOffset(leftW + COL_GAP + (i - 1) * (bw + COL_GAP), 0)
			else UDim2.fromOffset((i - 1) * (bw + COL_GAP), rowH + ROW_GAP)
		b.hit.Size = UDim2.fromOffset(bw, rowH)
	end
	row.frame.Size = UDim2.new(1, 0, 0, Model.actionRowHeight(w, n, rowH))
end

--==============================================================================
-- THE FRAME OF IT: the tabs in the header row, the target bar, the plate and
-- its five pages, the player list over them, and the answer
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
	list.Padding = UDim.new(0, M.TabGap)
	list.Parent = strip
	ui.tabStrip = strip
	ui.tabs = {}
	for i, tab in ipairs(Model.Tabs) do
		local b = floored(MenuKit.button(strip, "Tab_" .. tab.id, Z + 2, tab.label, 15))
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
		player = build.list(pages, "Page_player", SECTION_GAP),
		world = build.list(pages, "Page_world", SECTION_GAP),
		mist = build.list(pages, "Page_mist", SECTION_GAP),
		events = build.list(pages, "Page_events", SECTION_GAP),
		announce = build.list(pages, "Page_announce", SECTION_GAP),
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
	local back = floored(MenuKit.button(sheet, "Back", Z + 7, "BACK", 15))
	back.hit.LayoutOrder = 0
	back.hit.Size = UDim2.new(0, 120, 0, MenuLayout.Config.Touch)
	back.style("sky")
	ui.sheetBack = back
	local caption = MenuKit.text(sheet, "Caption", 13, LOOK.Muted, Z + 7)
	caption.LayoutOrder = 1
	caption.Size = UDim2.new(1, 0, 0, 18)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Text = "CHOOSE A PLAYER IN THIS SERVER"

	-- THE ANSWER (2026-10-12, item 11, in place of the log strip): the server's
	-- words, one line over the page's foot, that fade by itself. A Frame and a
	-- TextLabel -- neither Active nor Selectable, no button anywhere in it -- so
	-- it never takes a press: the row under it works the whole time it shows.
	local answer = Instance.new("Frame")
	answer.Name = "Answer"
	answer.BackgroundColor3 = NEUTRAL
	answer.BorderSizePixel = 0
	answer.Active = false
	answer.Selectable = false
	answer.Visible = false
	answer.ZIndex = Z + 20
	answer.Parent = body
	UIKit.corner(answer, 9)
	local answerEdge = MenuKit.keyline(answer, INK, 2)
	local answerWords = Instance.new("TextLabel")
	answerWords.Name = "Words"
	answerWords.BackgroundTransparency = 1
	answerWords.Active = false
	answerWords.Selectable = false
	answerWords.Position = UDim2.fromOffset(12, 0)
	answerWords.Size = UDim2.new(1, -24, 1, 0)
	answerWords.Font = LOOK.BodyBoldFont
	answerWords.TextSize = 14
	answerWords.TextColor3 = WHITE
	answerWords.TextStrokeColor3 = INK
	answerWords.TextStrokeTransparency = 0.55
	answerWords.TextWrapped = true
	answerWords.ZIndex = Z + 21
	answerWords.Parent = answer
	ui.answer, ui.answerWords, ui.answerEdge = answer, answerWords, answerEdge
end

--==============================================================================
-- THE ANSWER: the server's words for the last press -- green done, red
-- refused, grey for a question answered "no" here, where nothing was asked of
-- anybody -- for M.AnswerSeconds, then faded out. A newer answer takes its
-- place at once, and its own time.
--==============================================================================
local answerSeq = 0
local function note(text: string, ok: boolean?)
	answerSeq += 1
	local mine = answerSeq
	local pill: Frame, words: TextLabel, edge: UIStroke = ui.answer, ui.answerWords, ui.answerEdge
	local r = ui.layout and ui.layout.answer
	local most = if r then r.w else 400
	local bounds = TextService:GetTextSize(text, 14, LOOK.BodyBoldFont, Vector2.new(math.max(40, most - 24), 1000))
	local w = math.min(most, math.ceil(bounds.X) + 28)
	local h = math.max(M.AnswerH, math.ceil(bounds.Y) + 10)
	if r then
		pill.Position = UDim2.fromOffset(r.x + math.floor((r.w - w) / 2), r.y + r.h - h)
	end
	pill.Size = UDim2.fromOffset(w, h)
	words.Text = text
	pill.BackgroundColor3 = if ok == true then GOOD elseif ok == false then BAD else NEUTRAL
	pill.BackgroundTransparency = 0
	edge.Transparency = 0
	words.TextTransparency = 0
	words.TextStrokeTransparency = 0.55
	pill.Visible = true
	task.delay(M.AnswerSeconds, function()
		if mine ~= answerSeq then
			return
		end
		local fade = TweenInfo.new(M.AnswerFade)
		TweenService:Create(pill, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(edge, fade, { Transparency = 1 }):Play()
		TweenService:Create(words, fade, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(M.AnswerFade, function()
			if mine == answerSeq then
				pill.Visible = false
			end
		end)
	end)
end

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
	return string.format("$%s  \u{00B7}  %s SPEED  \u{00B7}  PLANTS %d/%d  \u{00B7}  PODS %d/%d",
		GameConfig.money(tonumber(row.cash) or 0), GameConfig.compact(tonumber(row.speed) or 0),
		tonumber(row.held) or 0, MAX_HELD, tonumber(row.pods) or 0, GameConfig.Save.MaxPods)
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
-- One card: the box beside its button, the quick chips, the full number (the
-- limit while the box is empty).
local function grantCard(holder: Instance, key: string, money: boolean): any
	local col = build.column(holder, key, ROW_GAP)
	local card = build.card(col, "Card")
	local limit = attr(if money then "MaxMoney" else "MaxSpeed", 1e15)
	local row = build.action(card, "AmountRow", "half", { { if money then "AddMoney" else "AddSpeed",
		if money then "ADD MONEY" else "ADD SPEED" } }, 112)
	local box = build.box(row.frame, "Amount", if money then "Money: 1.5T, 250,000, 1Qd" else "Speed: 1.5T, 250,000, 1Qd")
	row.left = box
	local go = row.buttons[1]
	local chips: { any } = {}
	local specs: { { string } } = {}
	for _, chip in ipairs(Model.chips(limit)) do
		table.insert(specs, { "Chip" .. chip.label, chip.label })
	end
	local quick = build.buttons(card, 5, M.GrantChipMinW, "half", specs)
	for i, chip in ipairs(Model.chips(limit)) do
		quick[i].style("sky")
		chips[i] = { button = quick[i], value = chip.value }
	end
	local full = build.line(card, "Full", 14, LOOK.Muted)
	full.Font = LOOK.BodyBoldFont
	full.AutomaticSize = Enum.AutomaticSize.None
	full.TextScaled = true
	local fullFit = Instance.new("UITextSizeConstraint")
	fullFit.MaxTextSize = 14
	fullFit.MinTextSize = TEXT_MIN
	fullFit.Parent = full
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
	local limitText = string.format("LIMIT %s%s%s", if money then "$" else "", Model.commas(limit),
		if money then "" else " SPEED")
	return { column = col, box = box, full = full, go = go, money = money, limit = limit, limitText = limitText }
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
	pairList.Padding = UDim.new(0, SECTION_GAP)
	pairList.Parent = pair
	ui.grantPair, ui.grantPairList = pair, pairList
	ui.money = grantCard(pair, "Money", true)
	ui.speed = grantCard(pair, "Speed", false)

	-- REBIRTHS AND RESET PROGRESS, ONE ROW (2026-10-13, the owner's item 9):
	-- the target's rebirth count (their published one) beside REBIRTHS... and
	-- RESET PROGRESS... -- the row RESET PROGRESS had alone, so a phone's
	-- PLAYER still fits with no scroll (item 11). REBIRTHS... opens the rebirth
	-- card under it: a box for any number to add beside ADD and +1, then CLOSE
	-- and SET TO 0, which asks first, in its row's place. The count only: never
	-- a rebirth, never their cash or plants (AdminService). RESET PROGRESS...
	-- opens the red box, and in it the username typed back unlocks RESET
	-- PROGRESS, as before.
	local col = build.column(page, "Reset", ROW_GAP)
	local opener = build.action(col, "Opener", "page", { { "OpenRebirths", "REBIRTHS\u{2026}" },
		{ "OpenReset", "RESET PROGRESS\u{2026}" } }, 170)
	local rDot
	ui.rebirthLine, rDot, opener.left = build.state(opener.frame, "RebirthCount", "REBIRTHS")
	rDot.BackgroundColor3 = GOLD
	ui.openRebirths, ui.openReset = opener.buttons[1], opener.buttons[2]
	ui.openRebirths.style("sky")
	face(ui.openReset, "danger")
	ui.resetOpener = opener.frame
	local rCard = build.card(col, "Rebirths")
	rCard.Visible = false
	ui.rebirthCard = rCard
	local addRow = build.action(rCard, "RebirthAdd", "full", { { "AddRebirths", "ADD" }, { "AddRebirthOne", "+1" } })
	ui.rebirthBox = build.box(addRow.frame, "RebirthAmount",
		string.format("Rebirths to add: 1 to %s", Model.commas(attr("MaxRebirths", 1000))))
	addRow.left = ui.rebirthBox
	ui.rebirthAdd, ui.rebirthOne = addRow.buttons[1], addRow.buttons[2]
	local rRow = build.action(rCard, "RebirthRow", "full", { { "CloseRebirths", "CLOSE" },
		{ "AskRebirthReset", "SET TO 0\u{2026}" } })
	local only = MenuKit.body(rRow.frame, "Only", 12, LOOK.Muted, Z + 1)
	only.TextWrapped = true
	only.TextXAlignment = Enum.TextXAlignment.Left
	only.Text = "The count only: never a rebirth, never their cash or plants."
	rRow.left = only
	rRow.inset = 0
	ui.closeRebirths, ui.rebirthReset = rRow.buttons[1], rRow.buttons[2]
	ui.closeRebirths.style("idle")
	ui.rebirthRow = rRow.frame
	ui.rebirthAsk = build.question(rCard, "RebirthQuestion", "full", "SET TO 0")
	local card = build.card(col, "Danger", true)
	card.Visible = false
	ui.resetCard = card
	build.heading(card, "RESET PROGRESS", Color3.fromRGB(255, 196, 188))
	ui.resetWho = build.line(card, "Who", 14, TEXT)
	ui.resetWho.Font = LOOK.BodyBoldFont
	build.line(card, "Erases", 12, TEXT).Text = "ERASES AND SAVES: cash, Speed, every plant and pod, the bag, bought "
		.. "weapons, plot and mill upgrades, the Almanac and harvests, tutorial progress, offline earnings. KEPT: game "
		.. "passes, Robux purchase records, the Walk Mode setting. This cannot be undone."
	ui.typeCaption = build.line(card, "TypeCaption", 12, BAD)
	local typed = build.action(card, "Typed", "full", { { "CloseReset", "CANCEL" },
		{ "ResetPlayerProgress", "RESET PROGRESS" } }, 150)
	ui.typedBox = build.box(typed.frame, "TypedUsername", "Username")
	typed.left = ui.typedBox
	ui.closeReset, ui.resetButton = typed.buttons[1], typed.buttons[2]
	ui.closeReset.style("idle")
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
		local b = floored(MenuKit.button(chips, "Group_" .. g.id, Z + 2, g.label, 13))
		b.hit.LayoutOrder = i
		b.hit.Selectable = true
		b.hit.Size = UDim2.fromOffset(math.max(84, MenuKit.textWidth(g.label, 13) + 24), M.ToolbarShort)
		ui.groupChips[g.id] = b
		ui.groupOrder[i] = g.id
	end
	ui.chipArrows = {}
	for _, side in ipairs({ -1, 1 }) do
		local arrow = floored(MenuKit.button(toolbar, if side < 0 then "ChipsBack" else "ChipsOn", Z + 2,
			if side < 0 then "<" else ">", 14))
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
	layout.CellPadding = UDim2.fromOffset(M.CardGap, M.CardGap)
	layout.Parent = grid
	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop = UDim.new(0, M.GridInset)
	gridPad.PaddingBottom = UDim.new(0, M.GridInset)
	gridPad.PaddingLeft = UDim.new(0, M.GridInset)
	gridPad.PaddingRight = UDim.new(0, M.GridInset)
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
	local options = build.list(controls, "Options", ROW_GAP)
	options.ZIndex = Z + 1
	ui.options = options
	local forms = build.buttons(options, 2, M.FormMinW, "controls", { { "Pod", "POD" }, { "Grown", "GROWN PLANT" } })
	ui.pickPod, ui.pickGrown = forms[1], forms[2]
	-- THE SIZE (2026-10-12): stepped through the sizes the species comes in,
	-- beside how many (relayout: placeSizeQty).
	local sizeQty = Instance.new("Frame")
	sizeQty.Name = "SizeAndCount"
	sizeQty.BackgroundTransparency = 1
	sizeQty.Size = UDim2.new(1, 0, 0, M.RowTouch)
	sizeQty.LayoutOrder = nextIn(options)
	sizeQty.Parent = options
	ui.sizeQty = sizeQty
	ui.sizeBack = floored(MenuKit.button(sizeQty, "SizeDown", Z + 1, "<", 15))
	ui.sizeOn = floored(MenuKit.button(sizeQty, "SizeUp", Z + 1, ">", 15))
	ui.sizeBack.hit.Selectable = true
	ui.sizeOn.hit.Selectable = true
	local sizeWell = MenuKit.frame(sizeQty, "Size", Z + 1, LOOK.Well, LOOK.WellTransparency, 9)
	MenuKit.keyline(sizeWell, LOOK.WellEdge, 1)
	ui.sizeWell = sizeWell
	local sizeWord = MenuKit.text(sizeWell, "Word", 14, TEXT, Z + 2)
	sizeWord.Position = UDim2.fromOffset(4, 0)
	sizeWord.Size = UDim2.new(1, -8, 1, 0)
	sizeWord.TextScaled = true
	local sizeFit = Instance.new("UITextSizeConstraint")
	sizeFit.MaxTextSize = 14
	sizeFit.MinTextSize = TEXT_MIN
	sizeFit.Parent = sizeWord
	ui.sizeWord = sizeWord
	ui.less = floored(MenuKit.button(sizeQty, "Less", Z + 1, "\u{2212}", 15))
	ui.count = floored(MenuKit.button(sizeQty, "Count", Z + 1, "1", 15))
	ui.more = floored(MenuKit.button(sizeQty, "More", Z + 1, "+", 15))
	ui.less.hit.Selectable = true
	ui.more.hit.Selectable = true
	ui.less.style("sky")
	ui.more.style("sky")
	ui.count.style("idle")
	ui.count.hit.Selectable = false
	ui.preview = build.line(options, "Preview", 14, TEXT)
	ui.preview.Font = LOOK.BodyBoldFont

	-- SPAWN, or the question that stands in for it.
	local go = Instance.new("Frame")
	go.Name = "Go"
	go.BackgroundTransparency = 1
	go.ZIndex = Z + 1
	go.Parent = controls
	ui.go = go
	local spawnButton = floored(MenuKit.button(go, "Spawn", Z + 2, "SPAWN", 18, { studs = true }))
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
	local cancel = floored(MenuKit.button(giveRow, "Cancel", Z + 2, "CANCEL", 15))
	cancel.hit.Size = UDim2.new(0.4, -3, 1, 0)
	cancel.hit.Selectable = true
	cancel.style("idle")
	local give = floored(MenuKit.button(giveRow, "Give", Z + 2, "GIVE", 16, { studs = true }))
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

-- SPAWN's size stepper beside how many, `w` wide (one over the other where
-- narrower than ConsoleModel's SpawnRowMinW).
local function placeSizeQty(w: number, rowH: number)
	local arrow, countW = M.StepArrowW, M.CountW
	local one = w >= M.SpawnRowMinW
	local qtyW = arrow * 2 + countW + COL_GAP * 2
	local stepW = if one then w - qtyW - COL_GAP else w
	local qx = if one then stepW + COL_GAP else 0
	local qy = if one then 0 else rowH + ROW_GAP
	ui.sizeBack.hit.Position = UDim2.fromOffset(0, 0)
	ui.sizeBack.hit.Size = UDim2.fromOffset(arrow, rowH)
	ui.sizeWell.Position = UDim2.fromOffset(arrow + COL_GAP, 4)
	ui.sizeWell.Size = UDim2.fromOffset(math.max(0, stepW - (arrow + COL_GAP) * 2), rowH - 8)
	ui.sizeOn.hit.Position = UDim2.fromOffset(stepW - arrow, 0)
	ui.sizeOn.hit.Size = UDim2.fromOffset(arrow, rowH)
	ui.less.hit.Position = UDim2.fromOffset(qx, qy)
	ui.less.hit.Size = UDim2.fromOffset(arrow, rowH)
	ui.count.hit.Position = UDim2.fromOffset(qx + arrow + COL_GAP, qy)
	ui.count.hit.Size = UDim2.fromOffset(countW, rowH)
	ui.more.hit.Position = UDim2.fromOffset(qx + arrow + COL_GAP * 2 + countW, qy)
	ui.more.hit.Size = UDim2.fromOffset(arrow, rowH)
	ui.sizeQty.Size = UDim2.new(1, 0, 0, Model.spawnRowHeight(w, rowH))
end

--==============================================================================
-- WORLD: THE DAY AND THE NIGHT, THE WEATHER (EVERY ADMIN'S)
--
-- Each section one card: its state -- captioned with whom it reaches -- beside
-- the buttons that change it, and the weather's duration chips under its row.
--==============================================================================
do
	local page = ui.page.world
	local dayCard = build.card(page, "DayNight")
	local dayRow = build.action(dayCard, "Phase", "full", { { "StartNight", "START NIGHT" }, { "StartDay", "START DAY" } })
	ui.phaseLabel, ui.phaseDot, dayRow.left = build.state(dayRow.frame, "Phase", "DAY & NIGHT \u{00B7} WHOLE SERVER")
	ui.startNight, ui.startDay = dayRow.buttons[1], dayRow.buttons[2]
	face(ui.startNight, "night")
	ui.startDay.style("done")

	-- The weather: every admin account's since 2026-10-07 (the owner's alone
	-- before), so every console shows it (ConsoleModel.sections); the server
	-- checks the allowlist either way, and every change still asks in place.
	-- How long: a duration chip (2026-10-12) in place of the seconds box.
	local wCard = build.card(page, "Weather")
	local wRow = build.action(wCard, "Rain", "full", { { "StartRain", "START RAIN" },
		{ "StartThunder", "THUNDERSTORM" }, { "EndRain", "STOP" } })
	ui.rainLabel, ui.rainDot, wRow.left = build.state(wRow.frame, "Rain", "WEATHER \u{00B7} THIS SERVER")
	ui.startRain, ui.startThunder, ui.endRain = wRow.buttons[1], wRow.buttons[2], wRow.buttons[3]
	face(ui.startRain, "rain")
	face(ui.startThunder, "thunder")
	face(ui.endRain, "danger")
	ui.weatherRow = ui.startRain.hit.Parent
	ui.weatherAsk = build.question(wCard, "WeatherQuestion", "full", "CONFIRM")
	local rainSpecs: { { string } } = {}
	for _, seconds in ipairs(Model.WeatherSeconds) do
		table.insert(rainSpecs, { "Rain" .. seconds, Model.durationLabel(seconds) })
	end
	local rainChips = build.buttons(wCard, 4, M.ChipMinW, "full", rainSpecs)
	ui.rainChips = {}
	for i, seconds in ipairs(Model.WeatherSeconds) do
		ui.rainChips[i] = { seconds = seconds, button = rainChips[i] }
	end
	ui.weatherSection = wCard
end

--==============================================================================
-- MIST: THE ENCHANTED MIST AND ITS TOOLS (its own tab since 2026-10-12, the
-- owner's item 12)
--
-- THE MIST: its state beside START MIST NOW and END MIST NOW (2026-10-11: a
-- normal Mist even while its schedule is off), its length (2 / 5 / 10 MIN)
-- beside MAKE ELIGIBLE NOW (only while the schedule runs: greyed out while it
-- is off), and its berries -- on the map, appeared, picked (the server's
-- MistOnMap, MistSpawned, MistPicked). AROUND YOU: a BERRY BURST, and
-- MOSSKEEPER SAYS, which asks in place. FOR THE TARGET (the bar's player):
-- their Dewberries 0..5, their progress 0..9, a Mysterious Pod -- RANDOM or a
-- creature, RANDOM or a size -- and READY NOW. Every press is a request; the
-- server checks it all.
--==============================================================================
do
	local page = ui.page.mist
	local mistCard = build.card(page, "Mist")
	local mistRow = build.action(mistCard, "Mist", "full", { { "StartMist", "START MIST NOW" },
		{ "EndMist", "END MIST NOW" } })
	ui.mistLabel, ui.mistDot, mistRow.left = build.state(mistRow.frame, "MistStatus",
		"ENCHANTED MIST \u{00B7} THIS SERVER")
	ui.startMist, ui.endMist = mistRow.buttons[1], mistRow.buttons[2]
	face(ui.startMist, "mist")
	face(ui.endMist, "danger")
	ui.mistRow = ui.startMist.hit.Parent
	ui.mistAsk = build.question(mistCard, "MistQuestion", "full", "CONFIRM")
	local lengthSpecs: { { string } } = {}
	for _, seconds in ipairs(Model.MistSeconds) do
		table.insert(lengthSpecs, { "MistLength" .. seconds, Model.durationLabel(seconds) })
	end
	table.insert(lengthSpecs, { "MistEligible", "ELIGIBLE NOW" })
	local lengths = build.buttons(mistCard, 4, M.ChipMinW, "full", lengthSpecs)
	ui.mistLengths = {}
	for i, seconds in ipairs(Model.MistSeconds) do
		ui.mistLengths[i] = { seconds = seconds, button = lengths[i] }
	end
	ui.mistEligible = lengths[#lengths]
	ui.mistBerries = build.line(mistCard, "Berries", 12, LOOK.Muted)
	ui.mistBerries.AutomaticSize = Enum.AutomaticSize.None
	ui.mistBerries.TextWrapped = false
	ui.mistBerries.TextTruncate = Enum.TextTruncate.AtEnd
	ui.mistSection = mistCard

	-- AROUND YOU: the burst, and his words.
	local aroundCard = build.card(page, "Around")
	local burstRow = build.action(aroundCard, "Burst", "full", { { "MistBurst", "BERRY BURST" } }, 160)
	local burstDot
	ui.mistBurstNote, burstDot, burstRow.left = build.state(burstRow.frame, "BurstNote", "DEWBERRIES \u{00B7} AROUND YOU")
	burstDot.BackgroundColor3 = GOOD
	ui.mistBurst = burstRow.buttons[1]
	face(ui.mistBurst, "mist")
	local sayRow = build.action(aroundCard, "Say", "full", { { "MistSay", "SAY" } }, 112)
	ui.sayBox = build.box(sayRow.frame, "SayWords",
		string.format("The Mosskeeper says... (%d characters)", EnchantedMistConfig.Mosskeeper.Talk.SayMaxChars))
	sayRow.left = ui.sayBox
	ui.mistSay = sayRow.buttons[1]
	ui.mistSay.style("done")
	ui.sayRow = ui.mistSay.hit.Parent
	ui.sayAsk = build.question(aroundCard, "SayQuestion", "full", "SAY")

	-- FOR THE TARGET: their counts, a pod, ready now.
	local forCard = build.card(page, "ForPlayer")
	ui.berriesLine = build.line(forCard, "BerriesLine", 12, TEXT)
	ui.berriesLine.Font = LOOK.BodyBoldFont
	local berrySpecs: { { string } } = {}
	for n = 0, EnchantedMistData.CarryCap do
		table.insert(berrySpecs, { "Berries" .. n, tostring(n) })
	end
	local berries = build.buttons(forCard, 10, M.CountMinW, "full", berrySpecs)
	ui.berryChips = {}
	for i, b in ipairs(berries) do
		ui.berryChips[i] = { count = i - 1, button = b }
	end
	ui.progressLine = build.line(forCard, "ProgressLine", 12, TEXT)
	ui.progressLine.Font = LOOK.BodyBoldFont
	local progressSpecs: { { string } } = {}
	for n = 0, EnchantedMistData.BerriesPerPod - 1 do
		table.insert(progressSpecs, { "Progress" .. n, tostring(n) })
	end
	local progress = build.buttons(forCard, 10, M.CountMinW, "full", progressSpecs)
	ui.progressChips = {}
	for i, b in ipairs(progress) do
		ui.progressChips[i] = { count = i - 1, button = b }
	end
	ui.podLine = build.line(forCard, "PodLine", 12, TEXT)
	ui.podLine.Font = LOOK.BodyBoldFont
	local entries = EnchantedMistData.Pool.Entries
	local creatureSpecs: { { string } } = { { "PodRandom", "RANDOM" } }
	for _, entry in ipairs(entries) do
		table.insert(creatureSpecs, { "Pod_" .. entry.Id, string.upper(entry.Name) })
	end
	local creatures = build.buttons(forCard, #entries + 1, M.CreatureMinW, "full", creatureSpecs)
	ui.creatureChips = {}
	for i, b in ipairs(creatures) do
		local entry = entries[i - 1]
		ui.creatureChips[i] = { id = if entry then entry.Id else nil, sized = entry == nil
			or EnchantedMistData.isSized(entry.Rarity), button = b }
	end
	local sizeSpecs: { { string } } = { { "SizeRandom", "RANDOM" } }
	for tier = 1, SeedData.TierCount do
		table.insert(sizeSpecs, { "PodSize" .. tier, string.upper(SeedData.TierName(tier)) })
	end
	local sizes = build.buttons(forCard, SeedData.TierCount + 1, M.ChipMinW, "full", sizeSpecs)
	ui.podSizeChips = {}
	for i, b in ipairs(sizes) do
		ui.podSizeChips[i] = { tier = if i > 1 then i - 1 else nil, button = b }
	end
	local podRow = build.action(forCard, "Pod", "full", { { "MistGivePod", "GIVE POD" }, { "MistReady", "READY NOW" } })
	local _, podDot
	ui.podSummary, podDot, podRow.left = build.state(podRow.frame, "PodChoice", "MYSTERIOUS POD")
	podDot.BackgroundColor3 = GOLD
	ui.givePod, ui.readyNow = podRow.buttons[1], podRow.buttons[2]
	face(ui.givePod, "mist")
	ui.readyNow.style("sky")
	ui.podRow = ui.givePod.hit.Parent
	ui.podAsk = build.question(forCard, "PodQuestion", "full", "GIVE")
end

--==============================================================================
-- EVENTS: THE MINI EVENTS, ON EVERY SERVER (their own tab since 2026-10-12)
--==============================================================================
do
	local page = ui.page.events
	local mCard = build.card(page, "Events")
	local mRow = build.action(mCard, "Mini", "full", { { "StartGlobalEvent", "START EVENT" },
		{ "EndGlobalEvent", "END EVENT" } })
	ui.miniLabel, ui.miniDot, mRow.left = build.state(mRow.frame, "MiniStatus", "MINI EVENTS \u{00B7} EVERY SERVER")
	ui.startMini, ui.endMini = mRow.buttons[1], mRow.buttons[2]
	ui.startMini.style("go")
	face(ui.endMini, "danger")
	ui.miniRow = ui.startMini.hit.Parent
	ui.miniAsk = build.question(mCard, "MiniQuestion", "full", "CONFIRM")
	local modes = build.buttons(mCard, 5, M.ModeMinW, "full", {
		{ "DiscoOnly", "DISCO ONLY" }, { "DiscoMill", "DISCO + MILL" },
		{ "TicketDisco", "TICKET DISCO" }, { "TicketShowerOnly", "TICKET SHOWER ONLY" },
		{ "PodRush", "POD RUSH" },
	})
	ui.miniChoices = {
		{ verb = "party", button = modes[1] },
		{ verb = "disco", button = modes[2] },
		{ verb = "ticketdisco", button = modes[3] },
		{ verb = "tickets", button = modes[4] },
		{ verb = "podrush", button = modes[5] },
	}
	local miniSpecs: { { string } } = {}
	for _, seconds in ipairs(Model.EventSeconds) do
		table.insert(miniSpecs, { "Mini" .. seconds, Model.durationLabel(seconds) })
	end
	local miniChips = build.buttons(mCard, 4, M.ChipMinW, "full", miniSpecs)
	ui.miniChips = {}
	for i, seconds in ipairs(Model.EventSeconds) do
		ui.miniChips[i] = { seconds = seconds, button = miniChips[i] }
	end
	ui.miniHelp = build.line(mCard, "ModeWords", 12, TEXT)
	ui.miniSync = build.line(mCard, "MiniSync", 12, LOOK.Muted)
	ui.miniSync.AutomaticSize = Enum.AutomaticSize.None
	ui.miniSync.TextWrapped = false
	ui.miniSync.TextTruncate = Enum.TextTruncate.AtEnd
end

--==============================================================================
-- ANNOUNCE: THE WORDS, WHO HEARS THEM, SEND
--==============================================================================
do
	local page = ui.page.announce
	local card = build.card(page, "Announce")
	local scopeRow = build.buttons(card, 2, M.ScopeMinW, "full", { { "ThisServer", "THIS SERVER" },
		{ "AllServers", "ALL SERVERS" } })
	ui.thisServer, ui.allServers = scopeRow[1], scopeRow[2]
	ui.messageBox = build.box(card, "Message", string.format("Message, up to %d characters", ANNOUNCE.MaxChars),
		M.MessageH)
	ui.messageBox.TextWrapped = true
	ui.messageBox.TextYAlignment = Enum.TextYAlignment.Top
	ui.messageBox.MultiLine = true
	local boxPad = ui.messageBox:FindFirstChildOfClass("UIPadding")
	if boxPad then
		boxPad.PaddingTop = UDim.new(0, 6)
	end
	-- The count beside SEND.
	local sendRow = build.action(card, "SendRow", "full", { { "Send", "SEND TO THIS SERVER" } })
	ui.counter = MenuKit.body(sendRow.frame, "Counter", 13, LOOK.Muted, Z + 1)
	ui.counter.TextXAlignment = Enum.TextXAlignment.Left
	sendRow.left = ui.counter
	sendRow.inset = 0
	ui.send = sendRow.buttons[1]
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
	-- ADMIN on a short screen, so the five tabs fit beside it (ConsoleModel.title).
	modal.title.Text = Model.title(short)
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
	ui.layout = L
	menu.place(L.panel)
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
	-- The page: under the target bar on the tabs that act on a player, in the
	-- bar's room too elsewhere (paint.tabs keeps it so on every tab change).
	put(ui.pages, if Model.TargetTabs[state.tab] then L.page else L.pageFull)
	local rowH = L.rowH

	-- SPAWN, inside the page.
	put(ui.toolbar, L.toolbar)
	put(ui.groupStrip, L.chips)
	ui.search.frame.AnchorPoint = Vector2.new(0, 0)
	put(ui.search.frame, L.search)
	-- Every group shows: wrapped into rows, or scrolling between the arrows.
	local chipH = L.search.h
	local places, _ = Model.chipPlaces(chipWidths, L.chips.w, chipH, L.chipsWrap)
	local total = 0
	for i, id in ipairs(ui.groupOrder) do
		local chip = ui.groupChips[id].hit
		chip.Size = UDim2.fromOffset(chipWidths[i], chipH)
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
		arrow.hit.Size = UDim2.fromOffset(M.ChipArrowW, chipH)
		arrow.hit.Position = UDim2.fromOffset(
			if side < 0 then 0 else L.chips.x + L.chips.w + M.ChipGap, 0)
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
	ui.options.Position = UDim2.fromOffset(0, 0)
	ui.options.Size = UDim2.new(1, 0, 1, -(rowH + CARD_PAD + ROW_GAP))
	ui.go.Position = UDim2.new(0, CARD_PAD, 1, -(rowH + CARD_PAD))
	ui.go.Size = UDim2.new(1, -CARD_PAD * 2, 0, rowH)

	-- PLAYER: money and Speed side by side, or one over the other.
	local pageInner = L.page.w - PAGE_PAD * 2 - BAR
	ui.grantPairList.FillDirection = if L.playerSplit then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	ui.grantPairList.Padding = UDim.new(0, if L.playerSplit then COL_GAP else SECTION_GAP)
	local half = if L.playerSplit then math.floor((pageInner - COL_GAP) / 2) else pageInner
	ui.money.column.Size = UDim2.new(0, half, 0, 0)
	ui.speed.column.Size = UDim2.new(0, half, 0, 0)

	-- Every row at the screen's row height: rows of buttons as many abreast as
	-- their width allows, rows of state and action side by side or one over
	-- the other -- the same rules ConsoleModel.pageHeight counts by.
	local widths = {
		page = pageInner,
		full = pageInner - CARD_PAD * 2,
		half = half - CARD_PAD * 2,
		controls = L.controls.w - PAGE_PAD * 2 - BAR,
	}
	for _, g in ipairs(grids) do
		local w = widths[g.scope] or widths.full
		local cols = Model.perRow(w, g.min, g.max)
		g.grid.CellSize = UDim2.fromOffset(math.max(1, math.floor((w - (cols - 1) * COL_GAP) / cols)), rowH)
	end
	for _, row in ipairs(actionRows) do
		placeAction(row, widths[row.scope] or widths.full, rowH)
	end
	placeSizeQty(widths.controls, rowH)
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
-- RemoteFunction; what the server answered is the answer line.
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
	-- The target bar only on the tabs that act on a player (ConsoleModel.TargetTabs):
	-- elsewhere the page takes its room.
	local targeted = Model.TargetTabs[state.tab] == true
	ui.targetBar.Visible = targeted
	local L = ui.layout
	if L then
		put(ui.pages, if targeted then L.page else L.pageFull)
	end
	-- The weather for every admin account (2026-10-07); the Mist on its own tab
	-- (2026-10-12).
	local shown = Model.sections("world")
	ui.weatherSection.Visible = table.find(shown, "weather") ~= nil
	local mistShown = Model.sections("mist")
	ui.mistSection.Visible = table.find(mistShown, "mist") ~= nil
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
		g.full.Text = if g.box.Text == "" then g.limitText else line
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
	-- REBIRTHS: the target's count as the server published it; in the card, +1
	-- while under the limit, ADD for a good number, SET TO 0 while there is one
	-- to clear -- its question in its row's place while it asks.
	local p = currentTarget()
	local count = GameConfig.rebirthCount(p:GetAttribute(GameConfig.Rebirth.Attributes.Rebirths))
	local most = attr("MaxRebirths", 1000)
	ui.rebirthLine.Text = string.format("%s: %s REBIRTH%s", if p == player then "YOU" else string.upper(p.DisplayName),
		Model.commas(count), if count == 1 then "" else "S")
	ui.rebirthCard.Visible = state.rebirthOpen and not state.resetOpen
	lockable(ui.rebirthOne, count < most and not state.busy, "go", if state.busy then "…" else "+1")
	lockable(ui.rebirthReset, count > 0 and not state.busy, "danger", "SET TO 0\u{2026}")
	local adding = Model.parseAmount(ui.rebirthBox.Text, most)
	lockable(ui.rebirthAdd, adding ~= nil and count < most and not state.busy, "go", if state.busy then "…" else "ADD")
	local resetting = state.asking == "rebirthreset"
	ui.rebirthAsk.block.Visible = resetting
	ui.rebirthRow.Visible = not resetting
	local match = typedMatches()
	lockable(ui.resetButton, match and not state.busy, "danger", if state.busy then "…" else "RESET PROGRESS")
	ui.resetHint.Text = if match then "Press RESET PROGRESS to erase and save." else "Locked until the username matches."
	-- The red box shows only once its button has opened it.
	ui.resetCard.Visible = state.resetOpen
	ui.resetOpener.Visible = not state.resetOpen
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
	-- The room of the form chosen (2026-10-09): pods have their own.
	local room = if state.form == "pod" then row.podRoom else row.room
	local most = Model.quantityMax(room)
	state.quantity = Model.clampQuantity(state.quantity, room)
	ui.pickPod.style(if state.form == "pod" then "on" else "idle")
	ui.pickGrown.style(if state.form == "plant" then "on" else "idle")
	-- The size, stepped through the sizes the species comes in; a species of
	-- one size shows it with both arrows off.
	local down: number?, up: number? = nil, nil
	if not species then
		ui.sizeWord.Text = "SIZE"
		ui.preview.Text = "CHOOSE A SPECIES"
		ui.preview.TextColor3 = LOOK.Muted
	else
		local s = species :: SeedData.Species
		local sizes = SpawnCatalog.sizesOf(s)
		if not table.find(sizes, state.size) then
			state.size = Model.defaultSize(s, state.size)
		end
		if SpawnCatalog.fixedSize(s) then
			local word = SpawnCatalog.sizeWord(s, state.size)
			ui.sizeWord.Text = if word then string.upper(word) else "ONE SIZE"
		else
			ui.sizeWord.Text = string.upper(SeedData.TierName(state.size))
			down, up = Model.sizeStep(sizes, state.size, -1), Model.sizeStep(sizes, state.size, 1)
		end
		local name = if p == player then nil else p.Name
		ui.preview.Text = Model.preview(s, state.size, state.form, state.quantity, name)
		ui.preview.TextColor3 = TEXT
	end
	ui.sizeBack.style(if down then "sky" else "off")
	ui.sizeOn.style(if up then "sky" else "off")
	-- How many, out of the most the target's bag takes now.
	ui.count.set(if row.ready ~= true then "\u{2026}" else string.format("%d/%d", state.quantity, math.max(most, 0)))
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
	elseif species and row.ready ~= true then
		word = "BAG: LOADING"
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
	local MA = MIST.Attributes
	local mistState = Workspace:GetAttribute(MA.State)
	local mistEnds = Workspace:GetAttribute(MA.EndsAt)
	if mistState == MIST.States.Active and type(mistEnds) == "number" then
		ui.mistLabel.Text = string.format("MIST: ACTIVE  \u{2022}  %s LEFT", mmss(mistEnds - Workspace:GetServerTimeNow()))
		ui.mistDot.BackgroundColor3 = GOOD
	else
		-- The schedule's own state: off (COMING SOON on the sign) or on.
		ui.mistLabel.Text = if mistState == MIST.States.Disabled then "MIST: NOT RUNNING  \u{2022}  SCHEDULE OFF"
			elseif type(mistState) == "string" then "MIST: NOT RUNNING  \u{2022}  SCHEDULE ON"
			else "MIST: NOT RUNNING"
		ui.mistDot.BackgroundColor3 = LOOK.Muted
	end
	ui.miniHelp.Text = MODE_WORDS[state.miniMode] or ""
	local sync = screen:GetAttribute("MiniStatus")
	ui.miniSync.Text = if type(sync) == "string" then sync else "Waiting for the server's sync status…"
	for _, choice in ipairs(ui.miniChoices) do
		choice.button.style(if choice.verb == state.miniMode then "on" else "idle")
	end
	-- The duration chips: the one chosen lit.
	for _, chip in ipairs(ui.rainChips) do
		chip.button.style(if chip.seconds == state.rainSeconds then "on" else "idle")
	end
	for _, chip in ipairs(ui.miniChips) do
		chip.button.style(if chip.seconds == state.miniSeconds then "on" else "idle")
	end
	local weatherAsk = state.asking == "weather"
	ui.weatherAsk.block.Visible = weatherAsk
	ui.weatherRow.Visible = not weatherAsk
	local mistAsk = state.asking == "mist"
	ui.mistAsk.block.Visible = mistAsk
	ui.mistRow.Visible = not mistAsk
	local miniAsk = state.asking == "mini"
	ui.miniAsk.block.Visible = miniAsk
	ui.miniRow.Visible = not miniAsk
	for _, b in ipairs({ ui.startNight, ui.startDay, ui.startRain, ui.startThunder, ui.endRain, ui.startMist,
		ui.endMist, ui.startMini, ui.endMini }) do
		b.label.TextTransparency = if state.busy then 0.5 else 0
	end
end

-- A pool creature's entry by id (EnchantedMistData.Pool), or nil.
local function poolEntry(id: string?): any
	for _, entry in ipairs(EnchantedMistData.Pool.Entries) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

-- The pod chosen, in words: "RANDOM CREATURE · RANDOM SIZE", "ELDERBOUGH ·
-- COLOSSAL", "SNARLBLOOM · ITS OWN SIZE".
local function podWords(): string
	local entry = poolEntry(state.podSpecies)
	if not entry then
		return "RANDOM CREATURE  \u{00B7}  RANDOM SIZE"
	end
	local size = if not EnchantedMistData.isSized(entry.Rarity) then "ITS OWN SIZE"
		elseif state.podSize then string.upper(SeedData.TierName(state.podSize :: number))
		else "RANDOM SIZE"
	return string.upper(entry.Name) .. "  \u{00B7}  " .. size
end

function paint.mist()
	local MA = MIST.Attributes
	local mistState = Workspace:GetAttribute(MA.State)
	local active = mistState == MIST.States.Active
	-- The schedule runs only while its next eligibility is published -- an admin's
	-- Mist with the schedule off is "active" with none (EnchantedMistService).
	local scheduleOn = type(Workspace:GetAttribute(MA.EligibleAt)) == "number"
	-- The length chosen; MAKE ELIGIBLE NOW only while the schedule runs (greyed
	-- out while it is off), lit while it cools down.
	for _, chip in ipairs(ui.mistLengths) do
		chip.button.style(if chip.seconds == state.mistSeconds then "on" else "idle")
	end
	ui.mistEligible.style(if not scheduleOn then "off" elseif mistState == MIST.States.Cooldown then "go" else "idle")
	-- The running Mist's berries: the server's, once a second.
	local onMap = screen:GetAttribute("MistOnMap")
	ui.mistBerries.Text = if active and type(onMap) == "number"
		then string.format("BERRIES: %d ON THE MAP  \u{00B7}  %d APPEARED  \u{00B7}  %d PICKED THIS MIST", onMap,
			tonumber(screen:GetAttribute("MistSpawned")) or 0, tonumber(screen:GetAttribute("MistPicked")) or 0)
		elseif scheduleOn then "NO MIST RUNNING  \u{00B7}  THE SCHEDULE IS ON"
		else "NO MIST RUNNING  \u{00B7}  THE SCHEDULE IS OFF"
	ui.mistBurstNote.Text = if active
		then string.format("%d AROUND YOU, KEEPING APART", EnchantedMistData.Spawn.Burst.Count)
		else "NEEDS A RUNNING MIST"
	if active then
		face(ui.mistBurst, "mist")
	else
		ui.mistBurst.style("off")
	end
	-- The target's own counts (their attributes, the server's).
	local p = currentTarget()
	local PA = MIST.PlayerAttributes
	local carried = tonumber(p:GetAttribute(PA.Carried)) or 0
	local progress = tonumber(p:GetAttribute(PA.Progress)) or 0
	local whom = if p == player then "YOU" else string.upper(p.DisplayName)
	ui.berriesLine.Text = string.format("DEWBERRIES %s CARR%s: %d/%d", whom, if p == player then "Y" else "IES",
		carried, EnchantedMistData.CarryCap)
	ui.progressLine.Text = string.format("%s PROGRESS TOWARD A POD: %d/%d", if p == player then "YOUR" else whom .. "'S",
		progress, EnchantedMistData.BerriesPerPod)
	for _, chip in ipairs(ui.berryChips) do
		chip.button.style(if chip.count == carried then "on" else "idle")
	end
	for _, chip in ipairs(ui.progressChips) do
		chip.button.style(if chip.count == progress then "on" else "idle")
	end
	-- The pod: a size only for a sized creature the admin chose.
	local entry = poolEntry(state.podSpecies)
	local sized = entry ~= nil and EnchantedMistData.isSized(entry.Rarity)
	if not sized then
		state.podSize = nil
	end
	for _, chip in ipairs(ui.creatureChips) do
		chip.button.style(if chip.id == state.podSpecies then "on" else "idle")
	end
	for _, chip in ipairs(ui.podSizeChips) do
		chip.button.style(if chip.tier ~= nil and not sized then "off" elseif chip.tier == state.podSize then "on" else "idle")
	end
	ui.podLine.Text = "A MYSTERIOUS POD FOR " .. whom
	ui.podSummary.Text = podWords()
	local podAsking = state.asking == "pod"
	ui.podAsk.block.Visible = podAsking
	ui.podRow.Visible = not podAsking
	local saying = state.asking == "say"
	ui.sayAsk.block.Visible = saying
	ui.sayRow.Visible = not saying
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
	elseif which == "StartMist" then
		return if ui.mistAsk.block.Visible then ui.mistAsk.cancel.hit else ui.startMist.hit
	elseif which == "StartGlobalEvent" then
		return ui.startMini.hit
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
	paint.mist()
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

-- A list scrolled to its foot (in the gui's own units): what was just opened
-- at the bottom of it in view.
local function toFoot(list: ScrollingFrame)
	task.defer(function()
		local k = UIKit.scaleOf(deck)
		list.CanvasPosition = Vector2.new(0, math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y) / k)
	end)
end

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
-- RESET PROGRESS's red box: opened by its button, shut by CANCEL (its typing gone).
ui.openReset.hit.Activated:Connect(function()
	state.resetOpen = true
	-- One box open at a time: the rebirth card (and its question) shut.
	state.rebirthOpen = false
	if state.asking == "rebirthreset" then
		state.asking = nil
	end
	paint.all()
	toFoot(ui.page.player)
	selectIfPad(ui.typedBox)
end)
ui.closeReset.hit.Activated:Connect(function()
	state.resetOpen = false
	ui.typedBox.Text = ""
	paint.all()
	note("Nothing was reset.", nil)
	selectIfPad(ui.openReset.hit)
end)
ui.resetButton.hit.Activated:Connect(function()
	if state.busy or not typedMatches() then
		return
	end
	local typed = ui.typedBox.Text
	ui.typedBox.Text = ""
	task.spawn(send, Model.args.reset(currentTarget().UserId, typed))
end)
-- REBIRTHS (2026-10-13, item 9): REBIRTHS... opens and shuts the card, CLOSE
-- shuts it; +1 and ADD go at once, the count only; SET TO 0 asks first, in its
-- row's place, and its yes sends the target's username.
ui.openRebirths.hit.Activated:Connect(function()
	state.rebirthOpen = not state.rebirthOpen
	if state.asking == "rebirthreset" then
		state.asking = nil
	end
	paint.all()
	if state.rebirthOpen then
		toFoot(ui.page.player)
		selectIfPad(ui.rebirthBox)
	end
end)
ui.closeRebirths.hit.Activated:Connect(function()
	state.rebirthOpen = false
	ui.rebirthBox.Text = ""
	paint.all()
	selectIfPad(ui.openRebirths.hit)
end)
ui.rebirthBox:GetPropertyChangedSignal("Text"):Connect(paint.player)
ui.rebirthOne.hit.Activated:Connect(function()
	task.spawn(send, Model.args.addRebirths(currentTarget().UserId, 1))
end)
ui.rebirthAdd.hit.Activated:Connect(function()
	local amount, why = Model.parseAmount(ui.rebirthBox.Text, attr("MaxRebirths", 1000))
	if not amount then
		note("Not sent: " .. (why or "type how many rebirths to add."), false)
		return
	end
	task.spawn(send, Model.args.addRebirths(currentTarget().UserId, amount))
end)
ui.rebirthReset.hit.Activated:Connect(function()
	local p = currentTarget()
	local count = GameConfig.rebirthCount(p:GetAttribute(GameConfig.Rebirth.Attributes.Rebirths))
	ui.rebirthAsk.words.Text = if p == player
		then string.format("Set your rebirths (%s) to 0?", Model.commas(count))
		else string.format("Set %s's rebirths (%s) to 0?", p.DisplayName .. " (@" .. p.Name .. ")", Model.commas(count))
	setAsking("rebirthreset", nil)
	selectIfPad(ui.rebirthAsk.cancel.hit)
end)
ui.rebirthAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("No rebirths were changed.", nil)
	selectIfPad(ui.rebirthReset.hit)
end)
ui.rebirthAsk.confirm.hit.Activated:Connect(function()
	local p = currentTarget()
	setAsking(nil, nil)
	task.spawn(send, Model.args.resetRebirths(p.UserId, p.Name))
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
-- The size stepper: only ever to a size the species comes in.
for _, side in ipairs({ -1, 1 }) do
	local arrow = if side < 0 then ui.sizeBack else ui.sizeOn
	arrow.hit.Activated:Connect(function()
		local species = state.species
		if not species then
			return
		end
		local nextSize = Model.sizeStep(SpawnCatalog.sizesOf(species), state.size, side)
		if nextSize and SpawnCatalog.allows(species, nextSize) then
			state.size = nextSize
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
		-- Anybody but yourself: the question first, in place of the button --
		-- its words over it, in view.
		setAsking("give", nil)
		toFoot(ui.options)
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
--
-- Each question asks for the duration chosen on its chips, and its CONFIRM
-- sends that one (state.askSeconds); a chip pressed while it is up closes it.
--==============================================================================
ui.startNight.hit.Activated:Connect(function()
	task.spawn(send, Model.args.startNight(currentTarget().UserId))
end)
ui.startDay.hit.Activated:Connect(function()
	task.spawn(send, Model.args.startDay(currentTarget().UserId))
end)
local function askWeather(verb: string)
	local secs = state.rainSeconds
	ui.weatherAsk.words.Text = if verb == "end" then "Stop the weather on this server?"
		else string.format("Start %s on this server for %s?", if verb == "thunder" then "a THUNDERSTORM" else "RAIN",
			mmss(secs))
	state.askSeconds = secs
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
	local secs = state.askSeconds
	setAsking(nil, nil)
	task.spawn(send, Model.args.weather(verb, if verb == "end" then nil else secs))
end)
for _, chip in ipairs(ui.rainChips) do
	chip.button.hit.Activated:Connect(function()
		state.rainSeconds = chip.seconds
		if state.asking == "weather" then
			setAsking(nil, nil)
		else
			paint.world()
		end
	end)
end

--==============================================================================
-- MIST'S BUTTONS (2026-10-11; its own tab and tools since 2026-10-12)
--
-- START and END each ask in place, like the weather -- START for the length
-- chosen, which its CONFIRM sends; MOSSKEEPER SAYS asks in place too, and a
-- pod for anybody else asks with their name as SPAWN's give does.
--==============================================================================
local function askMist(verb: string)
	local secs = state.mistSeconds
	ui.mistAsk.words.Text = if verb == "end" then "End the Enchanted Mist on this server now?"
		else string.format("Start an Enchanted Mist on this server now, for %s?", mmss(secs))
	state.askSeconds = secs
	setAsking("mist", verb)
	selectIfPad(ui.mistAsk.cancel.hit)
end
ui.startMist.hit.Activated:Connect(function()
	askMist("start")
end)
ui.endMist.hit.Activated:Connect(function()
	askMist("end")
end)
ui.mistAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("Mist unchanged.", nil)
end)
ui.mistAsk.confirm.hit.Activated:Connect(function()
	local verb = state.askVerb or "end"
	local secs = state.askSeconds
	setAsking(nil, nil)
	task.spawn(send, Model.args.mist(verb, if verb == "start" then secs else nil))
end)
for _, chip in ipairs(ui.mistLengths) do
	chip.button.hit.Activated:Connect(function()
		state.mistSeconds = chip.seconds
		if state.asking == "mist" then
			setAsking(nil, nil)
		else
			paint.mist()
		end
	end)
end
ui.mistEligible.hit.Activated:Connect(function()
	task.spawn(send, Model.args.mist("eligible"))
end)
ui.mistBurst.hit.Activated:Connect(function()
	task.spawn(send, Model.args.mist("burst"))
end)
ui.mistSay.hit.Activated:Connect(function()
	local text = ui.sayBox.Text
	if not string.find(text, "%S") then
		note("Not said: type his line first.", false)
		return
	end
	ui.sayAsk.words.Text = "Say this as the Mosskeeper to everyone here?"
	state.askText = text
	setAsking("say", nil)
	selectIfPad(ui.sayAsk.cancel.hit)
end)
ui.sayAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("Nothing was said.", nil)
end)
ui.sayAsk.confirm.hit.Activated:Connect(function()
	local text = state.askText
	setAsking(nil, nil)
	task.spawn(function()
		local reply = send(Model.args.mist("say", text))
		if reply and reply.ok == true and ui.sayBox.Text == text then
			ui.sayBox.Text = ""
		end
	end)
end)
-- The target's Dewberries and progress: a chip is the number, sent at once.
for _, chip in ipairs(ui.berryChips) do
	chip.button.hit.Activated:Connect(function()
		task.spawn(send, Model.args.mistBerries(currentTarget().UserId, chip.count))
	end)
end
for _, chip in ipairs(ui.progressChips) do
	chip.button.hit.Activated:Connect(function()
		task.spawn(send, Model.args.mistProgress(currentTarget().UserId, chip.count))
	end)
end
-- The pod to give: RANDOM or a creature, RANDOM or a size (a sized one's only).
for _, chip in ipairs(ui.creatureChips) do
	chip.button.hit.Activated:Connect(function()
		state.podSpecies = chip.id
		if state.asking == "pod" then
			setAsking(nil, nil)
		else
			paint.mist()
		end
	end)
end
for _, chip in ipairs(ui.podSizeChips) do
	chip.button.hit.Activated:Connect(function()
		local entry = poolEntry(state.podSpecies)
		if chip.tier ~= nil and not (entry and EnchantedMistData.isSized(entry.Rarity)) then
			return
		end
		state.podSize = chip.tier
		if state.asking == "pod" then
			setAsking(nil, nil)
		else
			paint.mist()
		end
	end)
end
local function givePodNow(confirmName: string?)
	task.spawn(send, Model.args.mistPod(currentTarget().UserId, Model.podChoice(state.podSpecies, state.podSize),
		confirmName))
end
ui.givePod.hit.Activated:Connect(function()
	local p = currentTarget()
	if p ~= player then
		-- Anybody but yourself: the question first, in place of the row.
		ui.podAsk.words.Text = string.format("Give %s a Mysterious Pod (%s)?", p.DisplayName .. " (@" .. p.Name .. ")",
			podWords())
		setAsking("pod", nil)
		selectIfPad(ui.podAsk.cancel.hit)
		return
	end
	givePodNow(nil)
end)
ui.podAsk.cancel.hit.Activated:Connect(function()
	setAsking(nil, nil)
	note("No pod was given.", nil)
end)
ui.podAsk.confirm.hit.Activated:Connect(function()
	local name = currentTarget().Name
	setAsking(nil, nil)
	givePodNow(name)
end)
ui.readyNow.hit.Activated:Connect(function()
	task.spawn(send, Model.args.mistReady(currentTarget().UserId))
end)

--==============================================================================
-- EVENTS' BUTTONS
--==============================================================================
for _, choice in ipairs(ui.miniChoices) do
	choice.button.hit.Activated:Connect(function()
		state.miniMode = choice.verb
		-- A mode with its own length (POD RUSH's five minutes) picks it.
		local own = tonumber(((MINI.Modes :: any)[choice.verb] or {}).Seconds)
		if own then
			state.miniSeconds = own
		end
		if state.asking == "mini" then
			setAsking(nil, nil)
		else
			paint.all()
		end
	end)
end
for _, chip in ipairs(ui.miniChips) do
	chip.button.hit.Activated:Connect(function()
		state.miniSeconds = chip.seconds
		if state.asking == "mini" then
			setAsking(nil, nil)
		else
			paint.world()
		end
	end)
end
local function askMini(verb: string)
	local secs = state.miniSeconds
	local mode = (MINI.Modes :: any)[verb]
	ui.miniAsk.words.Text = if verb == "end" then "End the global event on EVERY server?"
		else string.format("Start %s on EVERY server for %s?", if mode then mode.Name else string.upper(verb),
			mmss(secs))
	state.askSeconds = secs
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
	local secs = state.askSeconds
	setAsking(nil, nil)
	task.spawn(send, Model.args.miniEvent(verb, if verb == "end" then nil else secs))
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
		paint.mist()
		-- The target's rebirth count, as the server publishes it (item 9).
		paint.player()
		task.delay(1, step)
	end
	step()
end
for _, name in ipairs({ ATTR.WorldPhase, ATTR.WorldPhaseEndsAt, WEATHER.Attributes.State, WEATHER.Attributes.EndsAt,
	WEATHER.Attributes.Mode, MIST.Attributes.State, MIST.Attributes.EndsAt, MINI.Attributes.State,
	MINI.Attributes.EndsAt, MINI.Attributes.Mode }) do
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
-- and the target it was left on, this session -- with RESET PROGRESS's red box
-- shut and its typing gone.
--==============================================================================
local setOpen: (boolean) -> ()

local function back()
	if state.listOpen then
		setList(false)
	elseif state.asking ~= nil then
		setAsking(nil, nil)
		note("Nothing was done.", nil)
		selectIfPad(mainButton())
	elseif state.resetOpen and state.tab == "player" then
		state.resetOpen = false
		ui.typedBox.Text = ""
		paint.all()
		selectIfPad(ui.openReset.hit)
	elseif state.rebirthOpen and state.tab == "player" then
		state.rebirthOpen = false
		ui.rebirthBox.Text = ""
		paint.all()
		selectIfPad(ui.openRebirths.hit)
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
		state.resetOpen = false
		state.rebirthOpen = false
		ui.typedBox.Text = ""
		ui.rebirthBox.Text = ""
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
