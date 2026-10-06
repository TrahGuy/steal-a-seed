--!strict
-- Steal a Seed :: AdminConsoleUI
--
-- The developer console's client: an ADMIN button in the topbar beside the
-- clock, and behind it the ADMIN CONSOLE -- compact, in the inventory's look
-- (MenuKit, MenuLayout), one section at a time (2026-10-04, the owner's ask):
--
--   BROADCAST     an announcement: THIS SERVER or ALL SERVERS (asked once
--                 more), the words and their count, SEND, the outbox
--   EVENTS        the GLOBAL mini event: TICKET DISCO, DISCO ONLY or TICKET
--                 SHOWER ONLY, the duration, START / END GLOBAL EVENT, its
--                 state and its sync -- every server of this place, either admin
--   WEATHER       Rain or a Thunderstorm for THIS server: the duration, START
--                 RAIN, START THUNDERSTORM, END RAIN, its state -- the owner's
--                 account only (the server refuses anyone else)
--   ITEM GRANTS   SECRET ITEMS: a Snarlbloom or a Petalfawn, a pod or a grown
--                 plant, into YOUR OWN bag, EQUIP NOW or not
--   PLAYER TOOLS  a target in this server, an amount, ADD MONEY, ADD SPEED
--   ADVANCED      the whole server's day and night; RESET PLAYER PROGRESS,
--                 behind its typed confirmation
--
-- Every command it had before, and nothing new: only how they are laid out
-- changed. A narrow sidebar picks the section on a desktop, a dropdown in the
-- header on a phone; each section scrolls under it, and what the server
-- answered stands in a line under every section. Switching sections starts,
-- stops and resets nothing, and keeps whatever was typed; reopening shows the
-- section it was left on, as the server has it now.
--
--==============================================================================
-- IT DOES NOT SHIP TO ANYBODY ELSE
--
-- This script is a child of AdminService, on the server, where nothing
-- replicates. AdminService clones it -- with the RemoteFunction it talks
-- through -- into a ScreenGui in the PlayerGui of an allowlisted account, and
-- does nothing for anybody else. Whatever runs here, EVERY PRESS IS A REQUEST:
-- the server checks the sender, the target, the action, the amount and the
-- typed confirmation, rate-limits them, and answers with the line the status
-- row shows. A reset is reported done only when the server says it saved.
-- The two flags the server puts on that gui (IsOwner, SecretGrants) only change
-- how a control LOOKS; the server decides every press as before.
--
--==============================================================================
-- MOUSE, TOUCH AND CONTROLLER
--
-- Every control is a GuiButton or a text box, and every one is Selectable, so a
-- controller reaches the ADMIN button through Roblox's own UI selection and
-- moves between the panel's controls with the D-pad; LB and RB step through the
-- sections. B steps back -- out of the player list, the ALL SERVERS question or
-- the reset confirmation, then out of the panel -- and is bound only while the
-- panel is open. The text boxes open the platform's keyboard, and the panel
-- stands above it while it shows.
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

local LOOK = MenuKit.Look
local INK = Color3.fromRGB(26, 24, 30)
local PLATE = Color3.fromRGB(24, 26, 32)
local GOLD = Color3.fromRGB(255, 200, 64)
local WHITE = Color3.fromRGB(255, 255, 255)
-- THE CONSOLE'S WORDS ON ITS LIGHT PANEL (the menus' bright recolor,
-- 2026-10-04): dark type, a dark gold, and the good / bad / night colours
-- taken down until they read on white. GOLD and WHITE stay for the HUD's ADMIN
-- button and the coloured faces' words.
local TEXT = LOOK.Text
local GOLD_TEXT = LOOK.Premium
local GOOD = LOOK.Money
local BAD = Color3.fromRGB(196, 52, 40)
local NIGHT_INK = Color3.fromRGB(44, 74, 170)
local BACK_ACTION = "SeedAdminBack"
local PAD_ACTION = "SeedAdminPad"
local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes
local ANNOUNCE = GameConfig.Announce
local WEATHER = GameConfig.Weather
local MINI = GameConfig.MiniEvent
local Z = 6

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
	deck:Destroy()
end)

-- The header's picture: the Settings gear (no admin art has been uploaded).
local menu = MenuKit.modal(deck, "Admin", "ADMIN CONSOLE", GameConfig.Rail.SettingsIcon, nil)
local modal = menu.modal
local body = menu.body
modal.dimmer.Selectable = false
do
	local blocker = modal.shell:FindFirstChild("ClickBlocker")
	if blocker and blocker:IsA("GuiButton") then
		blocker.Selectable = false
	end
end
modal.close.Selectable = true

--==============================================================================
-- THE PIECES EVERY SECTION IS BUILT FROM
--
-- A section is a page that scrolls: a heading with its HELP (folded away until
-- asked for), lines, text boxes, and rows of buttons that stand two or three
-- abreast where the width allows and one per row where it does not.
--==============================================================================
-- The faces a button wears beyond MenuKit's own: a locked control dark, the
-- weather its own two colours, the night its blue. END and anything
-- destructive wear MenuKit's red `danger`. Each with the family's darker foot
-- and a dark keyline (the global UI pass); a locked one never presses.
local FACES: { [string]: { Color3 } } = {
	locked = { Color3.fromRGB(96, 70, 70), Color3.fromRGB(64, 46, 46), Color3.fromRGB(34, 22, 22),
		Color3.fromRGB(214, 196, 196) },
	rain = { Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170), Color3.fromRGB(14, 46, 96), WHITE },
	thunder = { Color3.fromRGB(128, 104, 214), Color3.fromRGB(70, 52, 146), Color3.fromRGB(34, 22, 86), WHITE },
	night = { Color3.fromRGB(70, 92, 170), Color3.fromRGB(34, 44, 104), Color3.fromRGB(14, 20, 64), WHITE },
	speed = { Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170), Color3.fromRGB(14, 46, 96), WHITE },
}
local function face(b: MenuKit.Button, id: string)
	local f = FACES[id]
	if f then
		-- MenuKit's own state first (pressable or not), then these colours.
		b.style(if id == "locked" then "off" else "go")
		b.tint.Color = MenuKit.faceColours(f[1], f[2], f[3])
		b.edge.Color = f[3]
		b.label.TextColor3 = f[4]
	else
		b.style(id)
	end
end

type Grid = { grid: UIGridLayout, max: number, min: number }
local grids: { Grid } = {}
local pages: { [string]: ScrollingFrame } = {}
local order: { [Instance]: number } = {}

local function nextIn(holder: Instance): number
	local n = (order[holder] or 0) + 1
	order[holder] = n
	return n
end

local build = {}

function build.page(id: string): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = "Page_" .. id
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 5
	s.ScrollBarImageColor3 = LOOK.WellEdge
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.Selectable = false
	s.Visible = false
	s.ZIndex = Z
	s.Parent = body
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 7)
	list.Parent = s
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 9)
	pad.Parent = s
	pages[id] = s
	return s
end

-- A block inside a page that comes and goes as one (the reset's question).
function build.block(page: Instance, name: string): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = nextIn(page)
	f.Parent = page
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 7)
	list.Parent = f
	return f
end

-- Words that wrap and take the height they need.
function build.line(holder: Instance, name: string, size: number, colour: Color3?): TextLabel
	-- Sentences: the clean body face (the readability brief).
	local l = MenuKit.body(holder, name, size, colour, Z + 1)
	l.LayoutOrder = nextIn(holder)
	l.Size = UDim2.new(1, 0, 0, size + 4)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

-- The section's own heading, and its help folded under a "?".
function build.heading(page: Instance, text: string, help: string)
	local row = Instance.new("Frame")
	row.Name = "Heading"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 32)
	row.LayoutOrder = nextIn(page)
	row.Parent = page
	local title = MenuKit.text(row, "Title", 17, TEXT, Z + 1)
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -44, 1, 0)
	title.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 17
	fit.MinTextSize = 11
	fit.Parent = title
	title.Text = text
	local toggle = MenuKit.button(row, "Help", Z + 1, "?", 15)
	toggle.hit.AnchorPoint = Vector2.new(1, 0.5)
	toggle.hit.Position = UDim2.new(1, 0, 0.5, 0)
	toggle.hit.Size = UDim2.fromOffset(40, 40)
	toggle.style("dark")
	local words = build.line(page, "HelpText", 13, LOOK.Muted)
	words.Text = help
	words.Visible = false
	toggle.hit.Activated:Connect(function()
		words.Visible = not words.Visible
		toggle.set(if words.Visible then "\u{00D7}" else "?")
	end)
end

-- A text box in the panel's wells.
function build.box(holder: Instance, name: string, placeholder: string, height: number?): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.LayoutOrder = nextIn(holder)
	box.Size = UDim2.new(1, 0, 0, height or 44)
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
-- not -- one per row on the narrowest screens. Every one a 44-px target.
function build.buttons(holder: Instance, most: number, min: number, specs: { { string } }): { MenuKit.Button }
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
	grid.CellSize = UDim2.fromOffset(min, MenuLayout.Config.Touch)
	grid.Parent = frame
	table.insert(grids, { grid = grid, max = most, min = min })
	local made: { MenuKit.Button } = {}
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
	row.Size = UDim2.new(1, 0, 0, 34)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = nextIn(holder)
	row.Parent = holder
	UIKit.corner(row, 9)
	MenuKit.keyline(row, LOOK.WellEdge, 1)
	local dot = MenuKit.frame(row, "Dot", Z + 1, LOOK.Muted, 0, 6)
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 11, 0, 17)
	dot.Size = UDim2.fromOffset(12, 12)
	local words = MenuKit.body(row, "Words", 15, TEXT, Z + 1)
	words.Position = UDim2.fromOffset(30, 0)
	words.Size = UDim2.new(1, -38, 0, 34)
	words.AutomaticSize = Enum.AutomaticSize.Y
	words.TextWrapped = true
	words.TextXAlignment = Enum.TextXAlignment.Left
	return words, dot
end

--==============================================================================
-- THE SECTIONS AND THEIR PICTURES
--
-- Uploaded pictures only (no emoji): the Spin Ticket for EVENTS, the rain
-- cloud for WEATHER, the Bag's pods for ITEM GRANTS, the shop's cash for
-- PLAYER TOOLS, the Settings gear for ADVANCED. BROADCAST has no art uploaded
-- for it; it shows its name alone.
--==============================================================================
local SECTIONS = {
	{ id = "broadcast", label = "BROADCAST", icon = nil },
	{ id = "events", label = "EVENTS", icon = GameConfig.SourceIcons.tickets },
	{ id = "weather", label = "WEATHER", icon = GameConfig.SourceIcons.rain },
	{ id = "grants", label = "ITEM GRANTS", icon = GameConfig.BagLook.IconImages.pods },
	{ id = "players", label = "PLAYER TOOLS", icon = GameConfig.Store.Icons.cash1 },
	{ id = "advanced", label = "ADVANCED", icon = GameConfig.Rail.SettingsIcon },
}
for _, s in ipairs(SECTIONS) do
	build.page(s.id)
end

--==============================================================================
-- WHAT HAPPENED: under every section, whichever is showing
--==============================================================================
local status = MenuKit.text(body, "Status", 14, LOOK.Muted, Z + 1)
status.Font = Enum.Font.FredokaOne
status.BackgroundColor3 = LOOK.Well
status.BackgroundTransparency = LOOK.WellTransparency
status.TextWrapped = true
status.TextScaled = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Choose a section, then an action."
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = 10
	fit.Parent = status
	UIKit.corner(status, 9)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = status
end
local STATUS_H = 46

local function setStatus(text: string, colour: Color3)
	status.Text = text
	status.TextColor3 = colour
end

--==============================================================================
-- BROADCAST
--
-- Who hears it -- THIS SERVER unless ALL SERVERS is picked, and ALL SERVERS
-- asks once more -- the words, how many are used, and SEND. The server checks
-- every part again: the allowlist, the length, its safeguards, the filter.
--==============================================================================
local ui: any = {}
do
	local page = pages.broadcast
	build.heading(page, "BROADCAST", string.format("Up to %d characters, filtered by Roblox before anybody sees "
		.. "them. THIS SERVER shows it here at once; ALL SERVERS asks once more, then sends it to every server of "
		.. "this place (best effort). Nothing waits between announcements: each one queues and shows after the last.",
		ANNOUNCE.MaxChars))
	local scopeRow = build.buttons(page, 2, 140, { { "ThisServer", "THIS SERVER" }, { "AllServers", "ALL SERVERS" } })
	ui.thisServer, ui.allServers = scopeRow[1], scopeRow[2]
	ui.messageBox = build.box(page, "Message", string.format("Message, up to %d characters", ANNOUNCE.MaxChars), 84)
	ui.messageBox.TextSize = 16
	ui.messageBox.TextWrapped = true
	ui.messageBox.TextYAlignment = Enum.TextYAlignment.Top
	ui.messageBox.MultiLine = true
	ui.counter = build.line(page, "Counter", 13, LOOK.Muted)
	ui.counter.TextXAlignment = Enum.TextXAlignment.Right
	local send = build.buttons(page, 1, 140, { { "SendAnnouncement", "SEND TO THIS SERVER" } })
	ui.sendAnnouncement = send[1]
	ui.sendAnnouncement.style("done")
	local confirm = build.buttons(page, 2, 140, { { "CancelAll", "CANCEL" }, { "ConfirmAll", "YES, ALL SERVERS" } })
	ui.cancelAll, ui.confirmAll = confirm[1], confirm[2]
	ui.cancelAll.style("idle")
	face(ui.confirmAll, "danger")
	ui.confirmRow = ui.cancelAll.hit.Parent
	ui.confirmRow.Visible = false
end

--==============================================================================
-- EVENTS: THE GLOBAL MINI EVENT (2026-10-03)
--
-- For EVERY server of this place, by either admin -- the server checks the
-- allowlist (by the UserId the engine stamps) on every press. One global event
-- at a time: a second START is refused and changes nothing, and END is
-- harmless when nothing runs. The first line reads this server's attributes
-- (the mode and the time left); the second is the server's own account of the
-- shared record and its sync.
--
-- Four modes (2026-10-04): the pure DISCO ONLY ("party": the disco and x1.5
-- movement, no mill, no tickets) is new; DISCO + MILL is the mode this button
-- row called DISCO ONLY before, under the same verb ("disco").
--==============================================================================
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

do
	local page = pages.events
	build.heading(page, "EVENTS", string.format("One global mini event at a time, for every server of this place. "
		.. "DISCO ONLY: the disco and up to +%d%% movement speed for everyone -- speed is capped at %d, so a player "
		.. "already above %d gains less (no mill, no tickets). DISCO + MILL: the "
		.. "disco and the giant Disco Mill (\u{00D7}%d training while mounted). TICKET DISCO: the disco, the mill "
		.. "and free Spin Tickets all over the map. TICKET SHOWER ONLY: the tickets alone. Each ticket is one free "
		.. "spin, up to %d per player per event (across servers); collected spins stay after it ends. A second START "
		.. "is refused; END ends it everywhere.", partyPercent(), GameConfig.Speed.MaxWalkSpeed, partyFullBelow(),
		MINI.DiscoMill.Multiplier, MINI.Tickets.PerPlayerCap))
	ui.miniLabel, ui.miniDot = build.state(page, "MiniStatus")
	ui.miniSync = build.line(page, "MiniSync", 12, LOOK.Muted)
	build.line(page, "ModeCaption", 13, LOOK.Muted).Text = "MODE"
	local modes = build.buttons(page, 2, 150, {
		{ "DiscoOnly", "DISCO ONLY" }, { "DiscoMill", "DISCO + MILL" },
		{ "TicketDisco", "TICKET DISCO" }, { "TicketShowerOnly", "TICKET SHOWER ONLY" },
	})
	ui.miniChoices = {
		{ verb = "party", button = modes[1] },
		{ verb = "disco", button = modes[2] },
		{ verb = "ticketdisco", button = modes[3] },
		{ verb = "tickets", button = modes[4] },
	}
	build.line(page, "DurationCaption", 13, LOOK.Muted).Text =
		string.format("DURATION (SECONDS, %d TO %d)", MINI.MinSeconds, MINI.MaxSeconds)
	ui.miniDurationBox = build.box(page, "MiniSeconds", string.format("Whole seconds, %d to %d", MINI.MinSeconds,
		MINI.MaxSeconds))
	local scope = build.line(page, "Scope", 13, GOLD_TEXT)
	scope.Text = "SCOPE: EVERY SERVER OF THIS PLACE \u{00B7} EITHER ADMIN"
	local go = build.buttons(page, 2, 160, { { "StartGlobalEvent", "START GLOBAL EVENT" }, { "EndGlobalEvent", "END GLOBAL EVENT" } })
	ui.startGlobal, ui.endGlobal = go[1], go[2]
	ui.startGlobal.style("go")
	face(ui.endGlobal, "danger")
end
local miniDurationBox: TextBox = ui.miniDurationBox
miniDurationBox.Text = tostring(MINI.DefaultSeconds)

--==============================================================================
-- WEATHER (2026-10-02)
--
-- Rain for THIS server, by the OWNER's account alone: the server checks the
-- sender's UserId against its own owner identity on every request. START RAIN
-- and START THUNDERSTORM take the duration box, in whole seconds; END RAIN
-- ends whichever is running. The state line reads the server's attributes.
--==============================================================================
do
	local page = pages.weather
	build.heading(page, "WEATHER", string.format("Rain or a Thunderstorm on THIS server: +%d%% plant income while "
		.. "it falls, and a temporary biome that opens a few seconds in. The owner's account only -- the server "
		.. "checks every press. END RAIN ends whichever is running.",
		math.round((SeedData.Rain.IncomeFactor - 1) * 100)))
	ui.rainLabel, ui.rainDot = build.state(page, "Rain")
	build.line(page, "DurationCaption", 13, LOOK.Muted).Text =
		string.format("DURATION (SECONDS, %d TO %d)", WEATHER.MinSeconds, WEATHER.MaxSeconds)
	ui.durationBox = build.box(page, "RainSeconds", string.format("Whole seconds, %d to %d", WEATHER.MinSeconds,
		WEATHER.MaxSeconds))
	ui.weatherScope = build.line(page, "Scope", 13, GOLD_TEXT)
	local go = build.buttons(page, 3, 150, {
		{ "StartRain", "START RAIN" }, { "StartThunder", "START THUNDERSTORM" }, { "EndRain", "END RAIN" },
	})
	ui.startRain, ui.startThunder, ui.endRain = go[1], go[2], go[3]
end
local durationBox: TextBox = ui.durationBox
durationBox.Text = tostring(WEATHER.DefaultSeconds)

--==============================================================================
-- ITEM GRANTS: SECRET ITEMS (2026-10-02)
--
-- A Snarlbloom or a Petalfawn, as a POD or a GROWN PLANT, into YOUR OWN bag --
-- this version names no other recipient, and the server refuses any other.
-- EQUIP NOW puts it in your hands only if they are free. GRANT TO BAG is locked
-- while a grant is on its way. Every press carries its own request id, so the
-- server never grants the same request twice. These are the only items the
-- console grants.
--==============================================================================
do
	local page = pages.grants
	build.heading(page, "ITEM GRANTS", "A Secret pod or grown plant into YOUR OWN bag -- the only items this "
		.. "console grants. EQUIP NOW puts it in your hands only if they are free. Every press carries its own "
		.. "request id, so pressing again after no answer never grants twice.")
	build.line(page, "CreatureCaption", 13, LOOK.Muted).Text = "SECRET"
	local creature = build.buttons(page, 2, 140, { { "Snarlbloom", "SNARLBLOOM" }, { "Petalfawn", "PETALFAWN" } })
	ui.pickSnarlbloom, ui.pickPetalfawn = creature[1], creature[2]
	ui.creatureNote = build.line(page, "CreatureNote", 13, LOOK.Muted)
	build.line(page, "KindCaption", 13, LOOK.Muted).Text = "FORM"
	local kind = build.buttons(page, 2, 140, { { "Pod", "POD" }, { "GrownPlant", "GROWN PLANT" } })
	ui.pickPod, ui.pickPlant = kind[1], kind[2]
	ui.recipientLine = build.line(page, "Recipient", 13, GOLD_TEXT)
	local grant = build.buttons(page, 2, 150, { { "EquipNow", "EQUIP NOW: OFF" }, { "GrantToBag", "GRANT TO BAG" } })
	ui.equipToggle, ui.grantButton = grant[1], grant[2]
	ui.grantsOff = build.line(page, "GrantsOff", 13, BAD)
	ui.grantsOff.Text = "SECRET GRANTS ARE SWITCHED OFF ON THIS SERVER."
	ui.grantsOff.Visible = false
end

--==============================================================================
-- PLAYER TOOLS: A TARGET IN THIS SERVER, AN AMOUNT, CASH OR SPEED
--==============================================================================
do
	local page = pages.players
	build.heading(page, "PLAYER TOOLS", string.format("Cash and Speed go to the target through the game's own "
		.. "faucets -- up to %s cash and %s Speed a request, read back off their profile, so a grant the save cap "
		.. "cut short says so. The target is always somebody in this server; yourself by default.",
		GameConfig.compact(tonumber(screen:GetAttribute("MaxMoney")) or 1e12),
		GameConfig.compact(tonumber(screen:GetAttribute("MaxSpeed")) or 1e12)))
	local target = build.buttons(page, 1, 140, { { "Target", "TARGET" } })
	ui.targetButton = target[1]
	ui.targetButton.style("dark")
	build.line(page, "AmountCaption", 13, LOOK.Muted).Text = "AMOUNT (FOR MONEY OR SPEED)"
	ui.amountBox = build.box(page, "Amount", "Whole number, e.g. 1000000")
	local adds = build.buttons(page, 2, 140, { { "AddMoney", "ADD MONEY" }, { "AddSpeed", "ADD SPEED" } })
	ui.addMoney, ui.addSpeed = adds[1], adds[2]
	ui.addMoney.style("go")
	face(ui.addSpeed, "speed")
end

--==============================================================================
-- ADVANCED: THE WHOLE SERVER'S DAY AND NIGHT, AND THE RESET
--
-- Set apart and said in so many words: START NIGHT and START DAY change the
-- world for everybody in this server, not for a target. RESET PLAYER PROGRESS
-- shows the exact username and UserId it will erase, what goes and what stays,
-- and a box the admin must type that username into; the button stays locked
-- until the box matches, and the server checks the typed name again anyway.
--==============================================================================
do
	local page = pages.advanced
	build.heading(page, "ADVANCED", "START NIGHT and START DAY change the world for everybody in this server. "
		.. "RESET PLAYER PROGRESS erases the target's progress and saves it; it asks for their username first and "
		.. "cannot be undone. It acts on the target chosen here or in PLAYER TOOLS (the same one).")
	local world = build.line(page, "WorldCaption", 13, GOLD_TEXT)
	world.Text = "WHOLE SERVER: DAY AND NIGHT FOR EVERYONE HERE"
	ui.phaseLabel, ui.phaseDot = build.state(page, "Phase")
	local day = build.buttons(page, 2, 140, { { "StartNight", "START NIGHT" }, { "StartDay", "START DAY" } })
	ui.startNight, ui.startDay = day[1], day[2]
	face(ui.startNight, "night")
	ui.startDay.style("done")
	local danger = build.line(page, "DangerCaption", 13, BAD)
	danger.Text = "DANGER: ERASES A PLAYER'S PROGRESS"
	local target = build.buttons(page, 1, 140, { { "ResetTarget", "TARGET" } })
	ui.resetTarget = target[1]
	ui.resetTarget.style("dark")
	local reset = build.buttons(page, 1, 140, { { "ResetPlayerProgress", "RESET PLAYER PROGRESS" } })
	ui.resetButton = reset[1]
	face(ui.resetButton, "danger")

	local ask = build.block(page, "ConfirmReset")
	ask.Visible = false
	ui.confirmBlock = ask
	ui.confirmName = build.line(ask, "Username", 20, TEXT)
	ui.confirmId = build.line(ask, "UserId", 13, LOOK.Muted)
	local erases = build.line(ask, "Erases", 13, TEXT)
	erases.Text = "ERASES, AND SAVES: cash, Speed, every plant and pod, the bag, bought weapons, "
		.. "plot and mill upgrades, the Almanac and biome harvests, tutorial progress and offline "
		.. "earnings. KEPT: game passes, Robux purchase records and the Walk Mode setting. "
		.. "This cannot be undone."
	ui.typeCaption = build.line(ask, "TypeCaption", 13, GOLD_TEXT)
	ui.typedBox = build.box(ask, "TypedUsername", "Username")
	local actions = build.buttons(ask, 2, 140, { { "Cancel", "CANCEL" }, { "ConfirmReset", "RESET PROGRESS" } })
	ui.cancelReset, ui.confirmReset = actions[1], actions[2]
	ui.cancelReset.style("idle")
	ui.confirmHint = build.line(ask, "Hint", 13, LOOK.Muted)
end

--==============================================================================
-- THE PLAYER LIST: OVER THE SECTION, UNTIL A PLAYER IS PICKED OR BACK
--==============================================================================
local sheet = Instance.new("ScrollingFrame")
sheet.Name = "Players"
sheet.BackgroundColor3 = LOOK.Sheet
sheet.BackgroundTransparency = 0.02
sheet.BorderSizePixel = 0
sheet.ScrollBarThickness = 5
sheet.ScrollBarImageColor3 = LOOK.WellEdge
sheet.CanvasSize = UDim2.new()
sheet.AutomaticCanvasSize = Enum.AutomaticSize.Y
sheet.Selectable = false
sheet.Visible = false
sheet.ZIndex = Z + 3
sheet.Parent = body
UIKit.corner(sheet, 9)
do
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = sheet
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = sheet
end
local sheetBack = MenuKit.button(sheet, "Back", Z + 4, "BACK", 15)
sheetBack.hit.LayoutOrder = 0
sheetBack.hit.Size = UDim2.new(0, 120, 0, MenuLayout.Config.Touch)
sheetBack.style("dark")
local sheetCaption = MenuKit.text(sheet, "Caption", 13, LOOK.Muted, Z + 4)
sheetCaption.Font = Enum.Font.FredokaOne
sheetCaption.LayoutOrder = 1
sheetCaption.Size = UDim2.new(1, 0, 0, 18)
sheetCaption.TextXAlignment = Enum.TextXAlignment.Left
sheetCaption.Text = "CHOOSE A PLAYER IN THIS SERVER"

--==============================================================================
-- THE CHOOSER: THE SIDEBAR ON A DESKTOP, A DROPDOWN IN THE HEADER ON A PHONE
--==============================================================================
local section = "broadcast"
local setSection: (string) -> ()
local chooser = MenuKit.chooser(deck, body, Z, function(id: string)
	setSection(id)
end)
do
	local items: { MenuKit.ChooserItem } = {}
	for _, s in ipairs(SECTIONS) do
		table.insert(items, { id = s.id, label = s.label, icon = s.icon })
	end
	chooser.setItems(items)
	chooser.setSelected(section)
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied -- the safe width AND height, no shrink
--==============================================================================
local open = false

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
	return at.Y - GuiService:GetGuiInset().Y
end

local function relayout()
	local safe = deck.AbsoluteSize
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(deck))
	local p = MenuLayout.panel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight,
		rightLeft = hud.rightLeft,
		keyboardTop = keyboardTop(),
	}, 860, 600, GameConfig.Rail.OutlineThickness)
	menu.place(p)
	local b = MenuLayout.blocks(p)
	local gap = MenuLayout.Config.Gap
	local touch = MenuLayout.Config.Touch
	chooser.setMode(p.sidebar)
	if p.sidebar then
		chooser.layoutColumn(b.sidebar, touch)
	else
		local x = p.pad + MenuKit.titleWidth(menu, p.short) + 12
		local w = math.clamp(p.shell.X - x - p.pad - touch - 10, 110, 240)
		chooser.layoutDropdown({ x = x, y = math.floor((p.header - touch) / 2), w = w, h = touch })
	end
	local main = b.main
	local pageH = math.max(60, main.h - STATUS_H - gap)
	for _, page in pairs(pages) do
		page.Position = UDim2.fromOffset(main.x, main.y)
		page.Size = UDim2.fromOffset(main.w, pageH)
	end
	sheet.Position = UDim2.fromOffset(main.x, main.y)
	sheet.Size = UDim2.fromOffset(main.w, pageH)
	status.Position = UDim2.fromOffset(main.x, main.y + pageH + gap)
	status.Size = UDim2.fromOffset(main.w - 9, STATUS_H)
	-- Two or three abreast only where each still has its room.
	local w = main.w - 9
	for _, g in ipairs(grids) do
		local cols = math.clamp(math.floor((w + 6) / (g.min + 6)), 1, g.max)
		g.grid.CellSize = UDim2.fromOffset(math.floor((w - (cols - 1) * 6) / cols), touch)
	end
end
deck:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
	task.defer(relayout)
end)
relayout()

--==============================================================================
-- THE TARGET: A USERID, ALWAYS SOMEBODY IN THIS SERVER
--
-- Yourself by default. What goes to the server is the UserId; the name on the
-- buttons is only what is shown. If the chosen player leaves, the target is you
-- again -- and a request already on its way for them is refused by the server.
--==============================================================================
local targetId = player.UserId
local listOpen = false
local confirming = false
local busy = false
local confirmFor: Player? = nil

local function labelFor(p: Player): string
	return if p == player then p.Name .. "  (you)" else p.Name
end

local function currentTarget(): Player?
	return Players:GetPlayerByUserId(targetId)
end

local function showTarget()
	local p = currentTarget()
	if not p then
		targetId = player.UserId
		p = player
	end
	local name = labelFor(p :: Player)
	ui.targetButton.set("TARGET: " .. name .. "   \u{00B7}   CHANGE")
	ui.resetTarget.set("RESET TARGET: " .. name .. "   \u{00B7}   CHANGE")
end

local function usingGamepad(): boolean
	return string.find(UserInputService:GetLastInputType().Name, "Gamepad", 1, true) ~= nil
end

local function selectIfPad(target: GuiObject?)
	if target and usingGamepad() then
		GuiService.SelectedObject = target
	end
end

-- Which page shows: the section's, or the player list over it.
local function showPages()
	for id, page in pairs(pages) do
		page.Visible = open and id == section and not listOpen
	end
	sheet.Visible = open and listOpen
end

local function typedMatches(): boolean
	local who = confirmFor
	if not who then
		return false
	end
	local trimmed = string.match(ui.typedBox.Text, "^%s*(.-)%s*$") or ""
	return trimmed ~= "" and string.lower(trimmed) == string.lower(who.Name)
end

local function paintConfirm()
	if typedMatches() then
		face(ui.confirmReset, "danger")
		ui.confirmHint.Text = "Press RESET PROGRESS to erase and save."
		ui.confirmHint.TextColor3 = GOLD_TEXT
	else
		face(ui.confirmReset, "locked")
		ui.confirmHint.Text = "Locked until the username matches."
		ui.confirmHint.TextColor3 = LOOK.Muted
	end
end
ui.typedBox:GetPropertyChangedSignal("Text"):Connect(paintConfirm)

local function setConfirm(want: boolean)
	confirming = want
	ui.confirmBlock.Visible = want
	ui.resetButton.hit.Visible = not want
	if want then
		local who = currentTarget() or player
		confirmFor = who
		ui.confirmName.Text = who.Name
		ui.confirmId.Text = string.format("UserId %d%s", who.UserId, if who == player then "  (you)" else "")
		ui.typeCaption.Text = string.format("TYPE %s TO CONFIRM", string.upper(who.Name))
		ui.typedBox.Text = ""
		paintConfirm()
		selectIfPad(ui.typedBox)
	else
		confirmFor = nil
		ui.typedBox.Text = ""
	end
end

local rows: { GuiObject } = {}

local function buildList(): GuiObject?
	for _, row in ipairs(rows) do
		row:Destroy()
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
		local chosen = p.UserId == targetId
		local row = MenuKit.button(sheet, "Player_" .. tostring(p.UserId), Z + 4, labelFor(p), 15)
		row.hit.LayoutOrder = 1 + i
		row.hit.Size = UDim2.new(1, 0, 0, MenuLayout.Config.Touch)
		row.style(if chosen then "on" else "idle")
		local id = p.UserId
		row.hit.Activated:Connect(function()
			if id ~= targetId and confirming then
				-- The question names one player; a new target closes it.
				setConfirm(false)
				setStatus("The target changed, so the reset question was closed. Nothing was reset.", LOOK.Muted)
			end
			targetId = id
			showTarget()
			listOpen = false
			showPages()
			setStatus("Target: " .. labelFor(Players:GetPlayerByUserId(id) or player), LOOK.Muted)
			selectIfPad(if section == "advanced" then ui.resetTarget.hit else ui.targetButton.hit)
		end)
		table.insert(rows, row.hit)
		if not first then
			first = row.hit
		end
	end
	return first
end

local function setList(want: boolean)
	listOpen = want
	if want then
		local first = buildList()
		sheet.CanvasPosition = Vector2.zero
		showPages()
		selectIfPad(first)
	else
		showPages()
		selectIfPad(if section == "advanced" then ui.resetTarget.hit else ui.targetButton.hit)
	end
end
sheetBack.hit.Activated:Connect(function()
	setList(false)
end)

-- The first control a controller lands on in each section.
local FIRST: { [string]: () -> GuiObject } = {
	broadcast = function()
		return ui.messageBox
	end,
	events = function()
		return ui.startGlobal.hit
	end,
	weather = function()
		return ui.durationBox
	end,
	grants = function()
		return ui.grantButton.hit
	end,
	players = function()
		return ui.targetButton.hit
	end,
	advanced = function()
		return ui.startNight.hit
	end,
}

-- A section chosen: that page, from its top. Nothing starts, stops or resets,
-- and whatever was typed anywhere stays; only the player list closes.
setSection = function(want: string)
	if not pages[want] then
		return
	end
	listOpen = false
	section = want
	chooser.setSelected(want)
	pages[want].CanvasPosition = Vector2.zero
	showPages()
	selectIfPad(FIRST[want]())
end

--==============================================================================
-- ASKING
--
-- One request at a time from here; the server allows one a second whatever
-- this does (an announcement excepted, 2026-10-03). What the server said is
-- what the status row says.
--==============================================================================
local function amountFromBox(): number?
	local cleaned = (string.gsub(ui.amountBox.Text, "[,%s_]", ""))
	return tonumber(cleaned)
end

local function send(action: string, amount: number?, typed: string?)
	if busy then
		return
	end
	busy = true
	setStatus(if action == "ResetPlayerProgress" then "Resetting and saving…" else "Working…", LOOK.Muted)
	local ok, reply = pcall(function()
		return remote:InvokeServer(action, targetId, amount, typed)
	end)
	busy = false
	if not ok or type(reply) ~= "table" then
		setStatus("Couldn't reach the server.", BAD)
		return
	end
	local message = if type(reply.message) == "string" then reply.message else "No answer."
	setStatus(message, if reply.ok == true then GOOD else BAD)
end

ui.addMoney.hit.Activated:Connect(function()
	send("AddMoney", amountFromBox(), nil)
end)
ui.addSpeed.hit.Activated:Connect(function()
	send("AddSpeed", amountFromBox(), nil)
end)
ui.resetButton.hit.Activated:Connect(function()
	setConfirm(true)
end)
ui.cancelReset.hit.Activated:Connect(function()
	setConfirm(false)
	setStatus("Reset cancelled. Nothing changed.", LOOK.Muted)
	selectIfPad(ui.resetButton.hit)
end)
ui.confirmReset.hit.Activated:Connect(function()
	if busy or not typedMatches() then
		return
	end
	local typed = ui.typedBox.Text
	setConfirm(false)
	selectIfPad(ui.resetButton.hit)
	send("ResetPlayerProgress", nil, typed)
end)
ui.targetButton.hit.Activated:Connect(function()
	setList(true)
end)
ui.resetTarget.hit.Activated:Connect(function()
	setList(true)
end)
ui.startNight.hit.Activated:Connect(function()
	send("StartNight", nil, nil)
end)
ui.startDay.hit.Activated:Connect(function()
	send("StartDay", nil, nil)
end)

--==============================================================================
-- AN ANNOUNCEMENT (2026-10-01)
--
-- THIS SERVER unless ALL SERVERS is picked, and ALL SERVERS goes only after
-- YES, ALL SERVERS -- the server refuses an unconfirmed one anyway. The box
-- keeps to MaxChars and the counter says how many are used. What the server
-- answered is the status line: a best-effort cross-server send says so.
--
-- NO WAITING BETWEEN THEM (2026-10-03): SEND takes the words into a small
-- OUTBOX and empties the box at once, so the next can be typed and sent while
-- the last is still on its way. The outbox goes to the server one at a time,
-- in order, and the server queues them for the screen in that same order.
-- Each answer is the status line; one the server did not take at all (the
-- filter, a safeguard, no connection) says so and gives its words back to
-- the box if the box is empty, and the line never ends on a success while an
-- earlier one in the same run was not sent.
--==============================================================================
local scope = "server"
local confirmingAll = false
local messageBox: TextBox = ui.messageBox

local function paintScope()
	local all = scope == "all"
	ui.thisServer.style(if all then "idle" else "on")
	ui.allServers.style(if all then "on" else "idle")
	ui.sendAnnouncement.set(if all then "SEND TO ALL SERVERS" else "SEND TO THIS SERVER")
end

local function setAllConfirm(want: boolean)
	confirmingAll = want
	ui.sendAnnouncement.hit.Visible = not want
	ui.confirmRow.Visible = want
	if want then
		setStatus("Send this to EVERY server? Press YES, ALL SERVERS to confirm.", GOLD_TEXT)
		selectIfPad(ui.cancelAll.hit)
	end
end

local function paintCounter()
	local length = utf8.len(messageBox.Text) or 0
	if length > ANNOUNCE.MaxChars then
		-- Kept to the limit as it is typed or pasted, cut on a character.
		local stop = utf8.offset(messageBox.Text, ANNOUNCE.MaxChars + 1)
		if stop then
			messageBox.Text = string.sub(messageBox.Text, 1, stop - 1)
			return
		end
	end
	ui.counter.Text = string.format("%d / %d", length, ANNOUNCE.MaxChars)
	ui.counter.TextColor3 = if length == 0 then LOOK.Muted elseif length >= ANNOUNCE.MaxChars then GOLD_TEXT else TEXT
end
messageBox:GetPropertyChangedSignal("Text"):Connect(paintCounter)
paintCounter()

-- With a phone's keyboard up, the words and SEND stay in view over it: the
-- panel stands above the keyboard (relayout) and the page brings the box up.
messageBox.Focused:Connect(function()
	task.delay(0.25, function()
		local page = pages.broadcast
		local top = messageBox.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
		page.CanvasPosition = Vector2.new(0, math.max(0, top - 6))
	end)
end)

type Outgoing = { scope: string, text: string, confirmed: boolean }
-- In a block of its own: the console keeps well under Luau's 200 locals.
local announce: (confirmed: boolean) -> ()
do
	local outbox: { Outgoing } = {}
	local draining = false
	-- At most this many waiting here: more is a stuck connection, not typing.
	local OUTBOX_MAX = 8

	-- The first words of a message, to say which one an answer is about.
	local function excerpt(text: string): string
		local flat = string.match((string.gsub(text, "%s+", " ")), "^%s*(.-)%s*$") or ""
		if (utf8.len(flat) or 0) <= 24 then
			return "\"" .. flat .. "\""
		end
		local stop = utf8.offset(flat, 25) or (#flat + 1)
		return "\"" .. string.sub(flat, 1, stop - 1) .. "…\""
	end

	local function drain()
		if draining then
			return
		end
		draining = true
		local sent, missed, lastMiss = 0, 0, ""
		while #outbox > 0 do
			-- Another action's request first, if one is on its way.
			while busy do
				task.wait(0.05)
			end
			local item = table.remove(outbox, 1) :: Outgoing
			busy = true
			local more = #outbox
			setStatus((if item.scope == "all" then "Sending to every server…" else "Sending…")
				.. (if more > 0 then string.format(" (%d more queued)", more) else ""), LOOK.Muted)
			local ok, reply = pcall(function()
				return remote:InvokeServer("Announce", item.scope, item.text, item.confirmed)
			end)
			busy = false
			local message: string, good: boolean, shown: boolean
			if not ok or type(reply) ~= "table" then
				message, good, shown = "Couldn't reach the server. Nothing was sent.", false, false
			else
				message = if type(reply.message) == "string" then reply.message else "No answer."
				good = reply.ok == true
				shown = good or reply.shown == true
			end
			if good then
				sent += 1
			else
				missed += 1
				lastMiss = excerpt(item.text) .. ": " .. message
				-- Nothing went anywhere: the words come back to be fixed or resent.
				if not shown and messageBox.Text == "" then
					messageBox.Text = item.text
					lastMiss ..= " It's back in the box."
				end
			end
			if #outbox > 0 then
				setStatus((if good then message else lastMiss) .. string.format(" (%d more queued)", #outbox),
					if good then GOOD else BAD)
			elseif good and missed > 0 then
				setStatus(string.format("%d sent; %d not: %s", sent, missed, lastMiss), BAD)
			else
				setStatus(if good then message else lastMiss, if good then GOOD else BAD)
			end
		end
		draining = false
	end

	function announce(confirmed: boolean)
		local text = messageBox.Text
		if not string.find(text, "%S") then
			setStatus("Type a message first.", BAD)
			return
		end
		if #outbox >= OUTBOX_MAX then
			setStatus(string.format("%d announcements are still on their way. This one is still in the box.", #outbox), BAD)
			return
		end
		table.insert(outbox, { scope = scope, text = text, confirmed = confirmed })
		messageBox.Text = ""
		if draining then
			setStatus(string.format("Queued to send (%d waiting).", #outbox), LOOK.Muted)
		end
		task.spawn(drain)
	end
end

ui.thisServer.hit.Activated:Connect(function()
	scope = "server"
	setAllConfirm(false)
	paintScope()
end)
ui.allServers.hit.Activated:Connect(function()
	scope = "all"
	setAllConfirm(false)
	paintScope()
end)
ui.sendAnnouncement.hit.Activated:Connect(function()
	if scope == "all" then
		setAllConfirm(true)
	else
		announce(false)
	end
end)
ui.cancelAll.hit.Activated:Connect(function()
	setAllConfirm(false)
	setStatus("Not sent.", LOOK.Muted)
	selectIfPad(ui.sendAnnouncement.hit)
end)
ui.confirmAll.hit.Activated:Connect(function()
	setAllConfirm(false)
	selectIfPad(ui.sendAnnouncement.hit)
	announce(true)
end)
paintScope()

--==============================================================================
-- SECRET ITEMS (2026-10-02)
--
-- What is chosen here is only a request; the server checks the allowlist, the
-- recipient (you), the species, the form, its cooldown and the bag's room, and
-- grants exactly one item or none. GRANT TO BAG is locked from the press to the
-- answer. A request that never got an answer keeps its id: pressed again for
-- the same item, the server answers it instead of granting a second one.
--==============================================================================
local SECRET_CHOICES = {
	{ id = "snarlbloom", button = ui.pickSnarlbloom, note = "SNARLBLOOM: GREENHOLLOW'S SECRET" },
	{ id = "petalfawn", button = ui.pickPetalfawn, note = "PETALFAWN: STARBLOOM'S SECRET" },
}
local secretSpecies = "snarlbloom"
local secretKind = "pod"
local secretEquip = false
local granting = false
-- The last request whose answer never arrived, to send again unchanged.
local unanswered: { species: string, kind: string, equip: boolean, request: string }? = nil

-- The server's own switch, said here; the server refuses either way.
local function grantsOn(): boolean
	return screen:GetAttribute("SecretGrants") ~= false
end

local function paintSecret()
	for _, choice in ipairs(SECRET_CHOICES) do
		local on = choice.id == secretSpecies
		choice.button.style(if on then "on" else "idle")
		if on then
			ui.creatureNote.Text = choice.note
		end
	end
	local pod = secretKind == "pod"
	ui.pickPod.style(if pod then "on" else "idle")
	ui.pickPlant.style(if pod then "idle" else "on")
	ui.equipToggle.style(if secretEquip then "on" else "idle")
	ui.equipToggle.set(if secretEquip then "EQUIP NOW: ON" else "EQUIP NOW: OFF")
	local locked = granting or not grantsOn()
	if locked then
		face(ui.grantButton, "locked")
	else
		ui.grantButton.style("done")
	end
	ui.grantButton.set(if granting then "GRANTING…" else "GRANT TO BAG")
	ui.grantsOff.Visible = not grantsOn()
	ui.recipientLine.Text = string.format("RECIPIENT: %s (YOU). Only you, in this version.", player.Name)
end

local function grantSecret()
	if busy or granting then
		return
	end
	if not grantsOn() then
		setStatus("Secret grants are switched off on this server. Nothing was asked.", BAD)
		return
	end
	local request = unanswered
	if not (request and request.species == secretSpecies and request.kind == secretKind
		and request.equip == secretEquip) then
		request = {
			species = secretSpecies,
			kind = secretKind,
			equip = secretEquip,
			request = HttpService:GenerateGUID(false),
		}
	end
	busy = true
	granting = true
	paintSecret()
	setStatus("Granting…", LOOK.Muted)
	local ok, reply = pcall(function()
		return remote:InvokeServer("GrantSecret", player.UserId, request, nil)
	end)
	busy = false
	granting = false
	paintSecret()
	if not ok or type(reply) ~= "table" then
		-- No answer: maybe nothing happened, maybe it did. The same press sends
		-- the same id, which the server answers rather than granting again.
		unanswered = request
		setStatus("No answer from the server. Check your Bag; pressing again resends the same request.", BAD)
		return
	end
	unanswered = nil
	local message = if type(reply.message) == "string" then reply.message else "No answer."
	local colour = if reply.ok ~= true then BAD elseif reply.saved == false then GOLD_TEXT else GOOD
	setStatus(message, colour)
end

ui.pickSnarlbloom.hit.Activated:Connect(function()
	secretSpecies = "snarlbloom"
	paintSecret()
end)
ui.pickPetalfawn.hit.Activated:Connect(function()
	secretSpecies = "petalfawn"
	paintSecret()
end)
ui.pickPod.hit.Activated:Connect(function()
	secretKind = "pod"
	paintSecret()
end)
ui.pickPlant.hit.Activated:Connect(function()
	secretKind = "plant"
	paintSecret()
end)
ui.equipToggle.hit.Activated:Connect(function()
	secretEquip = not secretEquip
	paintSecret()
end)
ui.grantButton.hit.Activated:Connect(grantSecret)
screen:GetAttributeChangedSignal("SecretGrants"):Connect(paintSecret)
paintSecret()

--==============================================================================
-- THE PHASE, AS THE CLOCK READS IT
--
-- The two attributes WorldCycleService publishes, read the way WorldClock
-- reads them. Redrawn when either changes -- a forced dusk shows at once -- and
-- once a second while the console is open for the time left, by a task.delay
-- chain that stops as soon as it shuts.
--==============================================================================
local function mmss(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

local function drawPhase()
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(phase) ~= "string" or type(endsAt) ~= "number" then
		ui.phaseLabel.Text = "NOW: THE CYCLE HAS NOT STARTED"
		ui.phaseLabel.TextColor3 = LOOK.Muted
		ui.phaseDot.BackgroundColor3 = LOOK.Muted
		return
	end
	local night = phase == CYCLE.PhaseNight
	local left = endsAt - Workspace:GetServerTimeNow()
	ui.phaseLabel.Text = string.format("NOW: %s  \u{2022}  %s LEFT", if night then "NIGHT" else "DAY", mmss(left))
	ui.phaseLabel.TextColor3 = if night then NIGHT_INK else TEXT
	ui.phaseDot.BackgroundColor3 = if night then NIGHT_INK else GOLD
end
Workspace:GetAttributeChangedSignal(ATTR.WorldPhase):Connect(drawPhase)
Workspace:GetAttributeChangedSignal(ATTR.WorldPhaseEndsAt):Connect(drawPhase)

--==============================================================================
-- WEATHER (2026-10-02)
--
-- The line reads WeatherService's attributes the way the phase line reads the
-- clock's. The buttons only ask; the server refuses anyone but the owner -- and
-- an account the server says is not the owner's sees them locked, with why.
--==============================================================================
local RAIN_ATTR = WEATHER.Attributes

-- nil: not said (the server decides at the press); false: not the owner.
local function ownerAccount(): boolean?
	local v = screen:GetAttribute("IsOwner")
	return if type(v) == "boolean" then v else nil
end

local function paintWeather()
	local restricted = ownerAccount() == false
	ui.weatherScope.Text = if restricted
		then "RESTRICTED: THE OWNER'S ACCOUNT ONLY. The server refuses weather from this account."
		else "SCOPE: THIS SERVER ONLY \u{00B7} THE OWNER'S ACCOUNT ONLY"
	ui.weatherScope.TextColor3 = if restricted then BAD else GOLD_TEXT
	face(ui.startRain, if restricted then "locked" else "rain")
	face(ui.startThunder, if restricted then "locked" else "thunder")
	face(ui.endRain, if restricted then "locked" else "danger")
end

local function drawRain()
	local state = Workspace:GetAttribute(RAIN_ATTR.State)
	local endsAt = Workspace:GetAttribute(RAIN_ATTR.EndsAt)
	if type(state) ~= "string" or type(endsAt) ~= "number" then
		ui.rainLabel.Text = "RAIN: OFF"
		ui.rainLabel.TextColor3 = LOOK.Muted
		ui.rainDot.BackgroundColor3 = LOOK.Muted
		return
	end
	local name = if Workspace:GetAttribute(RAIN_ATTR.Mode) == "thunder" then "THUNDERSTORM" else "RAIN"
	if state == "closing" then
		ui.rainLabel.Text = name .. ": ENDING  \u{2022}  THE BIOME IS FADING"
	else
		ui.rainLabel.Text = string.format("%s: %s  \u{2022}  %s LEFT", name,
			if state == "active" then "ACTIVE, BIOME OPEN" else "STARTING", mmss(endsAt - Workspace:GetServerTimeNow()))
	end
	ui.rainLabel.TextColor3 = NIGHT_INK
	ui.rainDot.BackgroundColor3 = if state == "closing" then LOOK.Muted else GOOD
end
Workspace:GetAttributeChangedSignal(RAIN_ATTR.State):Connect(drawRain)
Workspace:GetAttributeChangedSignal(RAIN_ATTR.EndsAt):Connect(drawRain)
Workspace:GetAttributeChangedSignal(RAIN_ATTR.Mode):Connect(drawRain)
screen:GetAttributeChangedSignal("IsOwner"):Connect(paintWeather)

local function askWeather(verb: string, seconds: number?)
	if busy then
		return
	end
	if ownerAccount() == false then
		setStatus("Weather is the owner's account's alone. Nothing was asked.", BAD)
		return
	end
	busy = true
	setStatus(if verb == "start" then "Starting the rain…"
		elseif verb == "thunder" then "Starting the thunderstorm…"
		else "Ending the weather…", LOOK.Muted)
	local ok, reply = pcall(function()
		return remote:InvokeServer("Weather", verb, seconds, nil)
	end)
	busy = false
	if not ok or type(reply) ~= "table" then
		setStatus("Couldn't reach the server.", BAD)
		return
	end
	local message = if type(reply.message) == "string" then reply.message else "No answer."
	setStatus(message, if reply.ok == true then GOOD else BAD)
end

local function startWeather(verb: string)
	local cleaned = (string.gsub(durationBox.Text, "[,%s_]", ""))
	local seconds = tonumber(cleaned)
	if not seconds then
		setStatus("Type the duration in whole seconds first.", BAD)
		return
	end
	askWeather(verb, seconds)
end
ui.startRain.hit.Activated:Connect(function()
	startWeather("start")
end)
ui.startThunder.hit.Activated:Connect(function()
	startWeather("thunder")
end)
ui.endRain.hit.Activated:Connect(function()
	askWeather("end", nil)
end)
paintWeather()
drawRain()

--==============================================================================
-- GLOBAL MINI EVENTS (2026-10-03)
--
-- The first line reads MiniEventService's attributes on this server: which
-- mode is running here and its time left (from the shared absolute end, so
-- every server shows the same clock). The second is the server's own account
-- of the shared record and its sync, written onto this admin's gui alone.
-- The buttons only ask; what the server could confirm is the status row.
--==============================================================================
local MINI_ATTR = MINI.Attributes
local miniMode = "ticketdisco"

local function paintMiniModes()
	for _, choice in ipairs(ui.miniChoices) do
		choice.button.style(if choice.verb == miniMode then "on" else "idle")
	end
end

local function drawMini()
	local state = Workspace:GetAttribute(MINI_ATTR.State)
	local endsAt = Workspace:GetAttribute(MINI_ATTR.EndsAt)
	local mode = (MINI.Modes :: any)[Workspace:GetAttribute(MINI_ATTR.Mode) or ""]
	local where = if Workspace:GetAttribute(MINI_ATTR.Scope) == "local" then "THIS SERVER" else "GLOBAL"
	if type(state) ~= "string" or type(endsAt) ~= "number" or not mode then
		ui.miniLabel.Text = "NO GLOBAL EVENT RUNNING HERE"
		ui.miniLabel.TextColor3 = LOOK.Muted
		ui.miniDot.BackgroundColor3 = LOOK.Muted
	elseif state == "ending" then
		ui.miniLabel.Text = string.format("%s %s: ENDING", where, mode.Name)
		ui.miniLabel.TextColor3 = LOOK.Muted
		ui.miniDot.BackgroundColor3 = LOOK.Muted
	else
		-- The pure DISCO ONLY says what it gives everybody (2026-10-04).
		local factor = tonumber(mode.SpeedFactor)
		local boost = if factor and factor > 1 then string.format(" (UP TO +%d%% SPEED)", partyPercent(factor)) else ""
		ui.miniLabel.Text = string.format("%s %s%s  \u{2022}  %s LEFT", where, mode.Name, boost,
			mmss(endsAt - Workspace:GetServerTimeNow()))
		ui.miniLabel.TextColor3 = GOLD_TEXT
		ui.miniDot.BackgroundColor3 = GOOD
	end
	local line = screen:GetAttribute("MiniStatus")
	ui.miniSync.Text = if type(line) == "string" then line else "Waiting for the server's sync status…"
end
for _, name in ipairs({ MINI_ATTR.State, MINI_ATTR.EndsAt, MINI_ATTR.Mode, MINI_ATTR.Scope }) do
	Workspace:GetAttributeChangedSignal(name):Connect(drawMini)
end
screen:GetAttributeChangedSignal("MiniStatus"):Connect(drawMini)

local function askMini(verb: string, seconds: number?)
	if busy then
		return
	end
	busy = true
	setStatus(if verb == "end" then "Ending the global event (shared storage, then a notice to the other servers)…"
		else "Starting the global event (shared storage, then a notice to the other servers)…", LOOK.Muted)
	local ok, reply = pcall(function()
		return remote:InvokeServer("MiniEvent", verb, seconds, nil)
	end)
	busy = false
	if not ok or type(reply) ~= "table" then
		setStatus("Couldn't reach this server. Nothing is confirmed.", BAD)
		return
	end
	local message = if type(reply.message) == "string" then reply.message else "No answer."
	setStatus(message, if reply.ok == true then GOOD else BAD)
	drawMini()
end

for _, choice in ipairs(ui.miniChoices) do
	choice.button.hit.Activated:Connect(function()
		miniMode = choice.verb
		paintMiniModes()
	end)
end
ui.startGlobal.hit.Activated:Connect(function()
	local cleaned = (string.gsub(miniDurationBox.Text, "[,%s_]", ""))
	local seconds = tonumber(cleaned)
	if not seconds then
		setStatus("Type the duration in whole seconds first.", BAD)
		return
	end
	askMini(miniMode, seconds)
end)
ui.endGlobal.hit.Activated:Connect(function()
	askMini("end", nil)
end)
paintMiniModes()
drawMini()

local phaseTicker = 0
local function tickPhase(want: boolean)
	phaseTicker += 1
	if not want then
		return
	end
	local mine = phaseTicker
	local function step()
		if mine ~= phaseTicker then
			return
		end
		drawPhase()
		drawRain()
		drawMini()
		task.delay(1, step)
	end
	step()
end

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local setOpen: (boolean) -> ()

local function bindBack(want: boolean)
	if not want then
		ContextActionService:UnbindAction(BACK_ACTION)
		ContextActionService:UnbindAction(PAD_ACTION)
		return
	end
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if listOpen then
			setList(false)
		elseif confirmingAll then
			setAllConfirm(false)
			setStatus("Not sent.", LOOK.Muted)
			selectIfPad(ui.sendAnnouncement.hit)
		elseif confirming then
			setConfirm(false)
			setStatus("Reset cancelled. Nothing changed.", LOOK.Muted)
			selectIfPad(ui.resetButton.hit)
		else
			setOpen(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
	-- LB and RB step through the sections, as they do through the Shop's.
	ContextActionService:BindActionAtPriority(PAD_ACTION, function(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if chooser.isOpen() then
			return Enum.ContextActionResult.Sink
		end
		local at = 1
		for i, s in ipairs(SECTIONS) do
			if s.id == section then
				at = i
			end
		end
		local step = if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1
		setSection(SECTIONS[(at - 1 + step) % #SECTIONS + 1].id)
		return Enum.ContextActionResult.Sink
	end, false, 2600, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

setOpen = function(want: boolean)
	if want == open then
		return
	end
	open = want
	modal.setOpen(want)
	tickPhase(want)
	if want then
		relayout()
		showTarget()
		paintSecret()
		paintWeather()
		-- The section it was left on, from the top, with what was typed in it.
		setSection(section)
		bindBack(true)
	else
		listOpen = false
		chooser.close()
		showPages()
		bindBack(false)
		local selected = GuiService.SelectedObject
		if selected and (selected:IsDescendantOf(screen) or selected:IsDescendantOf(deck)) then
			GuiService.SelectedObject = nil
		end
	end
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

--==============================================================================
-- THE ROOM CHANGING
--==============================================================================
Players.PlayerRemoving:Connect(function(leaving: Player)
	if confirming and confirmFor == leaving then
		setConfirm(false)
		setStatus(leaving.Name .. " left the server. Nothing was reset.", LOOK.Muted)
	end
	if leaving.UserId == targetId and leaving ~= player then
		targetId = player.UserId
		showTarget()
		setStatus(leaving.Name .. " left the server. The target is you again.", LOOK.Muted)
	end
	if listOpen then
		-- After the leaver is actually gone from GetPlayers.
		task.defer(function()
			if listOpen then
				setList(true)
			end
		end)
	end
end)
Players.PlayerAdded:Connect(function()
	if listOpen then
		setList(true)
	end
end)

showTarget()
showPages()
