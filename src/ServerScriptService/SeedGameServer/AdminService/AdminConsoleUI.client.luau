--!strict
-- Steal a Seed :: AdminConsoleUI
--
-- The developer console's client: an ADMIN button in the topbar beside the
-- clock, and a small panel behind it -- a target, an amount, ADD MONEY, ADD
-- SPEED and RESET PLAYER PROGRESS; the current phase with START NIGHT and START
-- DAY for the whole server; and one line saying what the server did.
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
--
--==============================================================================
-- MOUSE, TOUCH AND CONTROLLER
--
-- Every control is a GuiButton or a text box, and every one is Selectable, so a
-- controller reaches the ADMIN button through Roblox's own UI selection and
-- moves between the panel's controls with the D-pad. Opening a page with a
-- controller selects its first control; B steps back -- out of the player list
-- or the reset confirmation, then out of the panel -- and is bound only while
-- the panel is open. The text boxes open the platform's keyboard.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
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

local INK = Color3.fromRGB(26, 24, 30)
local PLATE = Color3.fromRGB(24, 26, 32)
local FIELD = Color3.fromRGB(34, 38, 48)
local GOLD = Color3.fromRGB(255, 200, 64)
local WHITE = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(190, 196, 210)
local GOOD = Color3.fromRGB(126, 214, 72)
local BAD = Color3.fromRGB(255, 118, 100)
local DANGER_TOP = Color3.fromRGB(232, 96, 72)
local DANGER_BOTTOM = Color3.fromRGB(160, 40, 30)
local LOCKED_TOP = Color3.fromRGB(96, 70, 70)
local LOCKED_BOTTOM = Color3.fromRGB(64, 46, 46)
local NIGHT_INK = Color3.fromRGB(150, 196, 255)
local BACK_ACTION = "SeedAdminBack"
local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes

--==============================================================================
-- THE BUTTON, BESIDE THE CLOCK
--
-- The clock's own plate with a gold word on it. Placed from HudLayout's
-- `admin`, in window space (this gui ignores the inset), and asked again only
-- when the screen or the topbar changes shape. Above the panel's dimmer, so it
-- also shuts the panel.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "AdminButton"
button.BackgroundColor3 = PLATE
button.BackgroundTransparency = 0.25
button.BorderSizePixel = 0
button.AutoButtonColor = true
button.Text = ""
button.Selectable = true
button.Visible = false
button.ZIndex = 10
button.Parent = screen
UIKit.corner(button, 10)
local buttonEdge = UIKit.stroke(button, INK, 2.5)
buttonEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIKit.clicks(button)

local buttonWord = UIKit.outlined(button, "Word", 16, GOLD, 2)
buttonWord.AnchorPoint = Vector2.new(0.5, 0.5)
buttonWord.Position = UDim2.fromScale(0.5, 0.5)
buttonWord.Size = UDim2.new(1, -10, 1, -8)
buttonWord.TextScaled = true
buttonWord.Text = "ADMIN"
buttonWord.ZIndex = 11
local wordFit = Instance.new("UITextSizeConstraint")
wordFit.MaxTextSize = 16
wordFit.MinTextSize = 10
wordFit.Parent = buttonWord

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
	button.Visible = true
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
screen.Destroying:Once(function()
	topbarWatch:Disconnect()
	ContextActionService:UnbindAction(BACK_ACTION)
end)
place()

--==============================================================================
-- THE PANEL: THE GAME'S OWN MODAL
--
-- Three pages in its body, one showing at a time: the form, the list the
-- target is picked from, and the reset confirmation. Each scrolls, so a short
-- phone keeps every control reachable -- and a controller's selection scrolls
-- with it.
--==============================================================================
local modal = UIKit.modal(screen, { name = "Admin", title = "ADMIN", maxWidth = 380, maxHeight = 500 })
modal.dimmer.Selectable = false
local blocker = modal.shell:FindFirstChild("ClickBlocker")
if blocker and blocker:IsA("GuiButton") then
	blocker.Selectable = false
end
modal.close.Selectable = true

local CONTENT = 350
local CONFIRM_CONTENT = 332
-- The status line lives under the pages, not in them, so what the server said
-- is on screen whichever page is showing and however far the form is scrolled.
local STATUS_H = 40

local function page(name: string, height: number): ScrollingFrame
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = name
	scroller.Size = UDim2.new(1, 0, 1, -(STATUS_H + 6))
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 6
	scroller.ScrollBarImageColor3 = MUTED
	scroller.CanvasSize = UDim2.fromOffset(0, height)
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.Selectable = false
	scroller.ZIndex = 4
	scroller.Parent = modal.body
	return scroller
end

local form = page("Form", CONTENT)
local list = page("Players", CONTENT)
list.Visible = false
local confirmPage = page("ConfirmReset", CONFIRM_CONTENT)
confirmPage.Visible = false

local function caption(parent: Instance, text: string, y: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = MUTED
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, -8, 0, 16)
	label.Position = UDim2.fromOffset(0, y)
	label.Text = text
	label.ZIndex = 5
	label.Parent = parent
	return label
end

local function paint(b: GuiObject, top: Color3, bottom: Color3)
	local gradient = b:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(top, bottom)
	end
end

local function pill(parent: Instance, name: string, text: string, top: Color3, bottom: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Text = ""
	b.Selectable = true
	b.ZIndex = 5
	UIKit.corner(b, 10)
	local edge = UIKit.stroke(b, INK, 2.5)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIKit.gradient(b, top, bottom)
	local word = UIKit.outlined(b, "Label", 18, WHITE, 2)
	word.AnchorPoint = Vector2.new(0.5, 0.5)
	word.Position = UDim2.fromScale(0.5, 0.5)
	word.Size = UDim2.new(1, -12, 1, -10)
	word.TextScaled = true
	word.Text = text
	word.ZIndex = 6
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 18
	fit.MinTextSize = 10
	fit.Parent = word
	UIKit.clicks(b)
	b.Parent = parent
	return b
end

local function field(parent: Instance, name: string, y: number, placeholder: string): TextBox
	local box = Instance.new("TextBox")
	box.Name = name
	box.Position = UDim2.fromOffset(0, y)
	box.Size = UDim2.new(1, -8, 0, 44)
	box.BackgroundColor3 = FIELD
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamBold
	box.TextSize = 18
	box.TextColor3 = WHITE
	box.PlaceholderColor3 = MUTED
	box.PlaceholderText = placeholder
	box.Text = ""
	box.Selectable = true
	box.ZIndex = 5
	box.Parent = parent
	UIKit.corner(box, 10)
	local edge = UIKit.stroke(box, INK, 2)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = box
	return box
end

--== THE FORM: TARGET ==--
caption(form, "TARGET", 0)
local targetButton = Instance.new("TextButton")
targetButton.Name = "Target"
targetButton.Position = UDim2.fromOffset(0, 18)
targetButton.Size = UDim2.new(1, -8, 0, 44)
targetButton.BackgroundColor3 = FIELD
targetButton.BorderSizePixel = 0
targetButton.AutoButtonColor = true
targetButton.Text = ""
targetButton.Selectable = true
targetButton.ZIndex = 5
targetButton.Parent = form
UIKit.corner(targetButton, 10)
local targetEdge = UIKit.stroke(targetButton, INK, 2)
targetEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIKit.clicks(targetButton)

local targetName = Instance.new("TextLabel")
targetName.Name = "Username"
targetName.BackgroundTransparency = 1
targetName.Font = Enum.Font.GothamBlack
targetName.TextColor3 = WHITE
targetName.TextScaled = true
targetName.TextXAlignment = Enum.TextXAlignment.Left
targetName.Position = UDim2.fromOffset(12, 7)
targetName.Size = UDim2.new(1, -96, 1, -14)
targetName.ZIndex = 6
targetName.Parent = targetButton
local nameFit = Instance.new("UITextSizeConstraint")
nameFit.MaxTextSize = 20
nameFit.MinTextSize = 11
nameFit.Parent = targetName

local change = Instance.new("TextLabel")
change.Name = "Change"
change.BackgroundTransparency = 1
change.Font = Enum.Font.GothamBold
change.TextSize = 13
change.TextColor3 = GOLD
change.TextXAlignment = Enum.TextXAlignment.Right
change.AnchorPoint = Vector2.new(1, 0.5)
change.Position = UDim2.new(1, -12, 0.5, 0)
change.Size = UDim2.fromOffset(76, 20)
change.Text = "CHANGE"
change.ZIndex = 6
change.Parent = targetButton

--== THE FORM: AMOUNT, AND THE THREE ACTIONS ==--
caption(form, "AMOUNT (FOR MONEY OR SPEED)", 70)
local amountBox = field(form, "Amount", 88, "Whole number, e.g. 1000000")

local actions = Instance.new("Frame")
actions.Name = "Actions"
actions.BackgroundTransparency = 1
actions.Position = UDim2.fromOffset(0, 142)
actions.Size = UDim2.new(1, -8, 0, 44)
actions.ZIndex = 5
actions.Parent = form

local addMoney = pill(actions, "AddMoney", "ADD MONEY", Color3.fromRGB(96, 186, 72), Color3.fromRGB(46, 120, 42))
addMoney.Size = UDim2.new(0.5, -4, 1, 0)
local addSpeed = pill(actions, "AddSpeed", "ADD SPEED", Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170))
addSpeed.AnchorPoint = Vector2.new(1, 0)
addSpeed.Position = UDim2.fromScale(1, 0)
addSpeed.Size = UDim2.new(0.5, -4, 1, 0)

local resetButton = pill(form, "ResetPlayerProgress", "RESET PLAYER PROGRESS", DANGER_TOP, DANGER_BOTTOM)
resetButton.Position = UDim2.fromOffset(0, 194)
resetButton.Size = UDim2.new(1, -8, 0, 44)

--== THE FORM: DAY AND NIGHT, FOR THE WHOLE SERVER ==--
-- Set apart by a rule and said in so many words: these two change the world for
-- everybody in this server, not for the target above.
local rule = Instance.new("Frame")
rule.Name = "Rule"
rule.BorderSizePixel = 0
rule.BackgroundColor3 = MUTED
rule.BackgroundTransparency = 0.6
rule.Position = UDim2.fromOffset(0, 250)
rule.Size = UDim2.new(1, -8, 0, 2)
rule.ZIndex = 5
rule.Parent = form
local worldCaption = caption(form, "WHOLE SERVER: DAY AND NIGHT FOR EVERYONE HERE", 260)
worldCaption.TextColor3 = GOLD

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Name = "Phase"
phaseLabel.BackgroundTransparency = 1
phaseLabel.Font = Enum.Font.GothamBlack
phaseLabel.TextSize = 17
phaseLabel.TextColor3 = WHITE
phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
phaseLabel.Position = UDim2.fromOffset(0, 278)
phaseLabel.Size = UDim2.new(1, -8, 0, 24)
phaseLabel.Text = ""
phaseLabel.ZIndex = 5
phaseLabel.Parent = form

local world = Instance.new("Frame")
world.Name = "World"
world.BackgroundTransparency = 1
world.Position = UDim2.fromOffset(0, 306)
world.Size = UDim2.new(1, -8, 0, 44)
world.ZIndex = 5
world.Parent = form
local startNight = pill(world, "StartNight", "START NIGHT", Color3.fromRGB(70, 92, 170), Color3.fromRGB(34, 44, 104))
startNight.Size = UDim2.new(0.5, -4, 1, 0)
local startDay = pill(world, "StartDay", "START DAY", Color3.fromRGB(236, 176, 60), Color3.fromRGB(176, 112, 24))
startDay.AnchorPoint = Vector2.new(1, 0)
startDay.Position = UDim2.fromScale(1, 0)
startDay.Size = UDim2.new(0.5, -4, 1, 0)

--== WHAT HAPPENED: under the pages, on every one of them ==--
local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 15
status.TextWrapped = true
status.TextColor3 = MUTED
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.fromScale(0, 1)
status.Size = UDim2.new(1, -8, 0, STATUS_H)
status.Text = "Choose a target, then an action."
status.ZIndex = 5
status.Parent = modal.body

local function setStatus(text: string, colour: Color3)
	status.Text = text
	status.TextColor3 = colour
end

--==============================================================================
-- THE RESET CONFIRMATION
--
-- The exact username and UserId it will erase, what goes and what stays, and a
-- box the admin must type that username into. The button stays locked until
-- the box matches, and the server checks the typed name again anyway.
--==============================================================================
caption(confirmPage, "RESET PLAYER PROGRESS", 0)
local confirmName = Instance.new("TextLabel")
confirmName.Name = "Username"
confirmName.BackgroundTransparency = 1
confirmName.Font = Enum.Font.GothamBlack
confirmName.TextColor3 = WHITE
confirmName.TextScaled = true
confirmName.TextXAlignment = Enum.TextXAlignment.Left
confirmName.Position = UDim2.fromOffset(0, 18)
confirmName.Size = UDim2.new(1, -8, 0, 28)
confirmName.ZIndex = 5
confirmName.Parent = confirmPage
local confirmNameFit = Instance.new("UITextSizeConstraint")
confirmNameFit.MaxTextSize = 24
confirmNameFit.MinTextSize = 12
confirmNameFit.Parent = confirmName

local confirmId = caption(confirmPage, "", 46)

local warning = Instance.new("TextLabel")
warning.Name = "Erases"
warning.BackgroundTransparency = 1
warning.Font = Enum.Font.GothamMedium
warning.TextSize = 13
warning.TextWrapped = true
warning.TextColor3 = WHITE
warning.TextXAlignment = Enum.TextXAlignment.Left
warning.TextYAlignment = Enum.TextYAlignment.Top
warning.Position = UDim2.fromOffset(0, 66)
warning.Size = UDim2.new(1, -8, 0, 96)
warning.Text = "ERASES, AND SAVES: cash, Speed, every plant and pod, the bag, bought weapons, "
	.. "plot and mill upgrades, the Almanac and biome harvests, tutorial progress and offline "
	.. "earnings. KEPT: game passes, Robux purchase records and the Walk Mode setting. "
	.. "This cannot be undone."
warning.ZIndex = 5
warning.Parent = confirmPage

local typeCaption = caption(confirmPage, "", 170)
local typedBox = field(confirmPage, "TypedUsername", 188, "Username")

local confirmActions = Instance.new("Frame")
confirmActions.Name = "Actions"
confirmActions.BackgroundTransparency = 1
confirmActions.Position = UDim2.fromOffset(0, 242)
confirmActions.Size = UDim2.new(1, -8, 0, 44)
confirmActions.ZIndex = 5
confirmActions.Parent = confirmPage
local cancelReset = pill(confirmActions, "Cancel", "CANCEL", Color3.fromRGB(120, 128, 146), Color3.fromRGB(72, 78, 94))
cancelReset.Size = UDim2.new(0.4, -4, 1, 0)
local confirmReset = pill(confirmActions, "ConfirmReset", "RESET PROGRESS", LOCKED_TOP, LOCKED_BOTTOM)
confirmReset.AnchorPoint = Vector2.new(1, 0)
confirmReset.Position = UDim2.fromScale(1, 0)
confirmReset.Size = UDim2.new(0.6, -4, 1, 0)

local confirmHint = caption(confirmPage, "", 294)
confirmHint.TextWrapped = true
confirmHint.Size = UDim2.new(1, -8, 0, 34)

-- Asked again whenever the screen changes shape and every time the panel opens:
-- fitContent sizes the panel against the screen it measures AT THAT MOMENT, and
-- the screen this script starts on is not always the one it is used on -- a
-- phone reported a desktop-sized screen at startup, and the panel stood 472 px
-- tall in a 413-px window with its title and X off the top. Short screens get a
-- shorter panel; the pages scroll.
local PANEL_CONTENT = math.max(CONTENT, CONFIRM_CONTENT) + STATUS_H + 6
local function fitPanel()
	modal.fitContent(PANEL_CONTENT)
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanel)
fitPanel()

--==============================================================================
-- THE TARGET: A USERID, ALWAYS SOMEBODY IN THIS SERVER
--
-- Yourself by default. What goes to the server is the UserId; the name on the
-- button is only what is shown. If the chosen player leaves, the target is you
-- again -- and a request already on its way for them is refused by the server.
--==============================================================================
local targetId = player.UserId

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
	targetName.Text = labelFor(p :: Player)
end

local listOpen = false
local confirming = false
local open = false
local busy = false
local confirmFor: Player? = nil

local function usingGamepad(): boolean
	return string.find(UserInputService:GetLastInputType().Name, "Gamepad", 1, true) ~= nil
end

local function selectIfPad(target: GuiObject?)
	if target and usingGamepad() then
		GuiService.SelectedObject = target
	end
end

local function typedMatches(): boolean
	local who = confirmFor
	if not who then
		return false
	end
	local trimmed = string.match(typedBox.Text, "^%s*(.-)%s*$") or ""
	return trimmed ~= "" and string.lower(trimmed) == string.lower(who.Name)
end

local function paintConfirm()
	local ready = typedMatches()
	if ready then
		paint(confirmReset, DANGER_TOP, DANGER_BOTTOM)
		confirmHint.Text = "Press RESET PROGRESS to erase and save."
		confirmHint.TextColor3 = GOLD
	else
		paint(confirmReset, LOCKED_TOP, LOCKED_BOTTOM)
		confirmHint.Text = "Locked until the username matches."
		confirmHint.TextColor3 = MUTED
	end
end
typedBox:GetPropertyChangedSignal("Text"):Connect(paintConfirm)

local function setConfirm(want: boolean)
	confirming = want
	if want then
		local who = currentTarget() or player
		confirmFor = who
		confirmName.Text = who.Name
		confirmId.Text = string.format("UserId %d%s", who.UserId, if who == player then "  (you)" else "")
		typeCaption.Text = string.format("TYPE %s TO CONFIRM", string.upper(who.Name))
		typedBox.Text = ""
		paintConfirm()
		form.Visible = false
		list.Visible = false
		confirmPage.Visible = true
		confirmPage.CanvasPosition = Vector2.zero
		selectIfPad(typedBox)
	else
		confirmFor = nil
		typedBox.Text = ""
		confirmPage.Visible = false
		form.Visible = not listOpen
		list.Visible = listOpen
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
	table.insert(rows, caption(list, "CHOOSE A PLAYER IN THIS SERVER", 0))
	local y = 20
	local first: GuiObject? = nil
	for _, p in ipairs(everyone) do
		local chosen = p.UserId == targetId
		local row = pill(list, "Player_" .. tostring(p.UserId), labelFor(p),
			if chosen then Color3.fromRGB(96, 186, 72) else Color3.fromRGB(70, 78, 96),
			if chosen then Color3.fromRGB(46, 120, 42) else Color3.fromRGB(44, 50, 64))
		row.Position = UDim2.fromOffset(0, y)
		row.Size = UDim2.new(1, -8, 0, 40)
		local id = p.UserId
		row.Activated:Connect(function()
			targetId = id
			showTarget()
			listOpen = false
			list.Visible = false
			form.Visible = true
			setStatus("Target: " .. labelFor(Players:GetPlayerByUserId(id) or player), MUTED)
			selectIfPad(targetButton)
		end)
		table.insert(rows, row)
		if not first then
			first = row
		end
		y += 46
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
	return first
end

local function setList(want: boolean)
	listOpen = want
	if want then
		setConfirm(false)
		local first = buildList()
		form.Visible = false
		list.Visible = true
		list.CanvasPosition = Vector2.zero
		selectIfPad(first)
	else
		list.Visible = false
		form.Visible = not confirming
		selectIfPad(targetButton)
	end
end

--==============================================================================
-- ASKING
--
-- One request at a time from here; the server allows one a second whatever
-- this does. What the server said is what the status row says.
--==============================================================================
local function amountFromBox(): number?
	local cleaned = (string.gsub(amountBox.Text, "[,%s_]", ""))
	return tonumber(cleaned)
end

local function send(action: string, amount: number?, typed: string?)
	if busy then
		return
	end
	busy = true
	setStatus(if action == "ResetPlayerProgress" then "Resetting and saving…" else "Working…", MUTED)
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

addMoney.Activated:Connect(function()
	send("AddMoney", amountFromBox(), nil)
end)
addSpeed.Activated:Connect(function()
	send("AddSpeed", amountFromBox(), nil)
end)
resetButton.Activated:Connect(function()
	setConfirm(true)
end)
cancelReset.Activated:Connect(function()
	setConfirm(false)
	setStatus("Reset cancelled. Nothing changed.", MUTED)
	selectIfPad(resetButton)
end)
confirmReset.Activated:Connect(function()
	if busy or not typedMatches() then
		return
	end
	local typed = typedBox.Text
	setConfirm(false)
	selectIfPad(resetButton)
	send("ResetPlayerProgress", nil, typed)
end)
targetButton.Activated:Connect(function()
	setList(true)
end)
startNight.Activated:Connect(function()
	send("StartNight", nil, nil)
end)
startDay.Activated:Connect(function()
	send("StartDay", nil, nil)
end)

--==============================================================================
-- THE PHASE, AS THE CLOCK READS IT
--
-- The two attributes WorldCycleService publishes, read the way WorldClock
-- reads them. Redrawn when either changes -- a forced dusk shows at once -- and
-- once a second while the panel is open for the time left, by a task.delay
-- chain that stops as soon as the panel shuts.
--==============================================================================
local function mmss(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

local function drawPhase()
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(phase) ~= "string" or type(endsAt) ~= "number" then
		phaseLabel.Text = "NOW: THE CYCLE HAS NOT STARTED"
		phaseLabel.TextColor3 = MUTED
		return
	end
	local night = phase == CYCLE.PhaseNight
	local left = endsAt - Workspace:GetServerTimeNow()
	phaseLabel.Text = string.format("NOW: %s  •  %s LEFT", if night then "NIGHT" else "DAY", mmss(left))
	phaseLabel.TextColor3 = if night then NIGHT_INK else WHITE
end
Workspace:GetAttributeChangedSignal(ATTR.WorldPhase):Connect(drawPhase)
Workspace:GetAttributeChangedSignal(ATTR.WorldPhaseEndsAt):Connect(drawPhase)

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
		return
	end
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if listOpen then
			setList(false)
		elseif confirming then
			setConfirm(false)
			setStatus("Reset cancelled. Nothing changed.", MUTED)
			selectIfPad(resetButton)
		else
			setOpen(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
end

setOpen = function(want: boolean)
	if want == open then
		return
	end
	open = want
	if want then
		fitPanel()
	end
	modal.setOpen(want)
	tickPhase(want)
	if want then
		showTarget()
		setList(false)
		setConfirm(false)
		bindBack(true)
		selectIfPad(targetButton)
	else
		listOpen = false
		setConfirm(false)
		list.Visible = false
		form.Visible = true
		bindBack(false)
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(screen) then
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
		setStatus(leaving.Name .. " left the server. Nothing was reset.", MUTED)
	end
	if leaving.UserId == targetId and leaving ~= player then
		targetId = player.UserId
		showTarget()
		setStatus(leaving.Name .. " left the server. The target is you again.", MUTED)
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
