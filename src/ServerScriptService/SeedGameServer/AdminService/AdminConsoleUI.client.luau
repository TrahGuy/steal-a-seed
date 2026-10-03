--!strict
-- Steal a Seed :: AdminConsoleUI
--
-- The developer console's client: an ADMIN button in the topbar beside the
-- clock, and a small panel behind it -- a target, an amount, ADD MONEY, ADD
-- SPEED and RESET PLAYER PROGRESS; the current phase with START NIGHT and START
-- DAY for the whole server; an announcement; SECRET ITEMS (2026-10-02), a
-- Secret pod or grown plant into your own bag; and one line saying what the
-- server did.
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
local HttpService = game:GetService("HttpService")
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

-- The form runs to WEATHER's START THUNDERSTORM row (2026-10-02); it scrolls.
local CONTENT = 1056
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

--== THE FORM: AN ANNOUNCEMENT (2026-10-01) ==--
-- Who hears it -- THIS SERVER unless ALL SERVERS is picked, and ALL SERVERS
-- asks once more -- the words, how many are left, and SEND. The server checks
-- every part again: the allowlist, the length, the cooldown, the filter.
local ANNOUNCE = GameConfig.Announce
local announceRule = rule:Clone()
announceRule.Position = UDim2.fromOffset(0, 362)
announceRule.Parent = form
local announceCaption = caption(form, "ANNOUNCEMENT TO PLAYERS", 372)
announceCaption.TextColor3 = GOLD

local scopeRow = Instance.new("Frame")
scopeRow.Name = "Scope"
scopeRow.BackgroundTransparency = 1
scopeRow.Position = UDim2.fromOffset(0, 392)
scopeRow.Size = UDim2.new(1, -8, 0, 40)
scopeRow.ZIndex = 5
scopeRow.Parent = form
local SCOPE_ON_TOP, SCOPE_ON_BOTTOM = Color3.fromRGB(96, 186, 72), Color3.fromRGB(46, 120, 42)
local SCOPE_OFF_TOP, SCOPE_OFF_BOTTOM = Color3.fromRGB(70, 78, 96), Color3.fromRGB(44, 50, 64)
local thisServer = pill(scopeRow, "ThisServer", "THIS SERVER", SCOPE_ON_TOP, SCOPE_ON_BOTTOM)
thisServer.Size = UDim2.new(0.5, -4, 1, 0)
local allServers = pill(scopeRow, "AllServers", "ALL SERVERS", SCOPE_OFF_TOP, SCOPE_OFF_BOTTOM)
allServers.AnchorPoint = Vector2.new(1, 0)
allServers.Position = UDim2.fromScale(1, 0)
allServers.Size = UDim2.new(0.5, -4, 1, 0)

local messageBox = field(form, "Message", 440, string.format("Message, up to %d characters", ANNOUNCE.MaxChars))
messageBox.Size = UDim2.new(1, -8, 0, 72)
messageBox.TextSize = 16
messageBox.TextWrapped = true
messageBox.TextXAlignment = Enum.TextXAlignment.Left
messageBox.TextYAlignment = Enum.TextYAlignment.Top
local counter = caption(form, "", 516)

local sendRow = Instance.new("Frame")
sendRow.Name = "SendRow"
sendRow.BackgroundTransparency = 1
sendRow.Position = UDim2.fromOffset(0, 538)
sendRow.Size = UDim2.new(1, -8, 0, 44)
sendRow.ZIndex = 5
sendRow.Parent = form
local sendAnnouncement = pill(sendRow, "SendAnnouncement", "SEND", Color3.fromRGB(236, 176, 60),
	Color3.fromRGB(176, 112, 24))
sendAnnouncement.Size = UDim2.fromScale(1, 1)
local cancelAll = pill(sendRow, "CancelAll", "CANCEL", Color3.fromRGB(120, 128, 146), Color3.fromRGB(72, 78, 94))
cancelAll.Size = UDim2.new(0.4, -4, 1, 0)
cancelAll.Visible = false
local confirmAll = pill(sendRow, "ConfirmAll", "YES, ALL SERVERS", DANGER_TOP, DANGER_BOTTOM)
confirmAll.AnchorPoint = Vector2.new(1, 0)
confirmAll.Position = UDim2.fromScale(1, 0)
confirmAll.Size = UDim2.new(0.6, -4, 1, 0)
confirmAll.Visible = false

--== THE FORM: SECRET ITEMS (2026-10-02) ==--
-- A Snarlbloom or a Petalfawn, as a POD or a GROWN PLANT, into YOUR OWN bag --
-- this version names no other recipient, and the server refuses any other.
-- EQUIP NOW puts it in your hands only if they are free. GRANT TO BAG is locked
-- while a grant is on its way. Every press carries its own request id, so the
-- server never grants the same request twice.
local secretRule = rule:Clone()
secretRule.Position = UDim2.fromOffset(0, 594)
secretRule.Parent = form
local secretCaption = caption(form, "SECRET ITEMS: INTO YOUR OWN BAG", 604)
secretCaption.TextColor3 = GOLD

local function row(name: string, y: number, h: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Position = UDim2.fromOffset(0, y)
	f.Size = UDim2.new(1, -8, 0, h)
	f.ZIndex = 5
	f.Parent = form
	return f
end

local creatureRow = row("SecretCreature", 624, 40)
local pickSnarlbloom = pill(creatureRow, "Snarlbloom", "SNARLBLOOM", SCOPE_ON_TOP, SCOPE_ON_BOTTOM)
pickSnarlbloom.Size = UDim2.new(0.5, -4, 1, 0)
local pickPetalfawn = pill(creatureRow, "Petalfawn", "PETALFAWN", SCOPE_OFF_TOP, SCOPE_OFF_BOTTOM)
pickPetalfawn.AnchorPoint = Vector2.new(1, 0)
pickPetalfawn.Position = UDim2.fromScale(1, 0)
pickPetalfawn.Size = UDim2.new(0.5, -4, 1, 0)
local creatureNote = caption(form, "", 668)

local kindRow = row("SecretKind", 688, 40)
local pickPod = pill(kindRow, "Pod", "POD", SCOPE_ON_TOP, SCOPE_ON_BOTTOM)
pickPod.Size = UDim2.new(0.5, -4, 1, 0)
local pickPlant = pill(kindRow, "GrownPlant", "GROWN PLANT", SCOPE_OFF_TOP, SCOPE_OFF_BOTTOM)
pickPlant.AnchorPoint = Vector2.new(1, 0)
pickPlant.Position = UDim2.fromScale(1, 0)
pickPlant.Size = UDim2.new(0.5, -4, 1, 0)

local recipientLine = caption(form, "", 734)
recipientLine.TextWrapped = true
recipientLine.Size = UDim2.new(1, -8, 0, 32)

local grantRow = row("SecretGrant", 772, 44)
local equipToggle = pill(grantRow, "EquipNow", "EQUIP NOW: OFF", SCOPE_OFF_TOP, SCOPE_OFF_BOTTOM)
equipToggle.Size = UDim2.new(0.42, -4, 1, 0)
local GRANT_TOP, GRANT_BOTTOM = Color3.fromRGB(236, 176, 60), Color3.fromRGB(176, 112, 24)
local grantButton = pill(grantRow, "GrantToBag", "GRANT TO BAG", GRANT_TOP, GRANT_BOTTOM)
grantButton.AnchorPoint = Vector2.new(1, 0)
grantButton.Position = UDim2.fromScale(1, 0)
grantButton.Size = UDim2.new(0.58, -4, 1, 0)

--== THE FORM: WEATHER (2026-10-02) ==--
-- Rain for THIS server, by the OWNER's account alone: the server checks the
-- sender's UserId against its own owner identity on every request, and another
-- admin's press is refused there. START RAIN takes the duration box, in whole
-- seconds; END RAIN ends it early. The line between reads the server's own
-- attributes, the way the phase line reads the clock's.
local WEATHER = GameConfig.Weather
local weatherRule = rule:Clone()
weatherRule.Position = UDim2.fromOffset(0, 826)
weatherRule.Parent = form
local weatherCaption = caption(form, "WEATHER FOR THIS SERVER (OWNER ONLY)", 836)
weatherCaption.TextColor3 = GOLD

local rainLabel = phaseLabel:Clone()
rainLabel.Name = "Rain"
rainLabel.Position = UDim2.fromOffset(0, 854)
rainLabel.Text = ""
rainLabel.Parent = form

caption(form, "DURATION (SECONDS)", 882)
local durationBox = field(form, "RainSeconds", 900,
	string.format("Whole seconds, %d to %d", WEATHER.MinSeconds, WEATHER.MaxSeconds))
durationBox.Text = tostring(WEATHER.DefaultSeconds)

local weatherRow = row("Weather", 952, 44)
local startRain = pill(weatherRow, "StartRain", "START RAIN", Color3.fromRGB(74, 156, 232), Color3.fromRGB(36, 92, 170))
startRain.Size = UDim2.new(0.5, -4, 1, 0)
local endRain = pill(weatherRow, "EndRain", "END RAIN", Color3.fromRGB(120, 128, 146), Color3.fromRGB(72, 78, 94))
endRain.AnchorPoint = Vector2.new(1, 0)
endRain.Position = UDim2.fromScale(1, 0)
endRain.Size = UDim2.new(0.5, -4, 1, 0)
-- The Thunderstorm (2026-10-02): the same event in its heavier mode, the same
-- duration box; END RAIN ends whichever is running.
local thunderRow = row("Thunder", 1004, 44)
local startThunder = pill(thunderRow, "StartThunder", "START THUNDERSTORM", Color3.fromRGB(128, 104, 214),
	Color3.fromRGB(70, 52, 146))
startThunder.Size = UDim2.new(1, 0, 1, 0)

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
-- AN ANNOUNCEMENT (2026-10-01)
--
-- THIS SERVER unless ALL SERVERS is picked, and ALL SERVERS goes only after
-- YES, ALL SERVERS -- the server refuses an unconfirmed one anyway. The box
-- keeps to MaxChars and the counter says how many are used. What the server
-- answered is the status line: a best-effort cross-server send says so.
--==============================================================================
local scope = "server"
local confirmingAll = false

local function paintScope()
	local all = scope == "all"
	paint(thisServer, if all then SCOPE_OFF_TOP else SCOPE_ON_TOP, if all then SCOPE_OFF_BOTTOM else SCOPE_ON_BOTTOM)
	paint(allServers, if all then SCOPE_ON_TOP else SCOPE_OFF_TOP, if all then SCOPE_ON_BOTTOM else SCOPE_OFF_BOTTOM)
end

local function setAllConfirm(want: boolean)
	confirmingAll = want
	sendAnnouncement.Visible = not want
	cancelAll.Visible = want
	confirmAll.Visible = want
	if want then
		setStatus("Send this to EVERY server? Press YES, ALL SERVERS to confirm.", GOLD)
		selectIfPad(cancelAll)
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
	counter.Text = string.format("%d / %d", length, ANNOUNCE.MaxChars)
	counter.TextColor3 = if length == 0 then MUTED elseif length >= ANNOUNCE.MaxChars then GOLD else WHITE
end
messageBox:GetPropertyChangedSignal("Text"):Connect(paintCounter)
paintCounter()

local function announce(confirmed: boolean)
	if busy then
		return
	end
	busy = true
	setStatus(if scope == "all" then "Sending to every server…" else "Sending…", MUTED)
	local ok, reply = pcall(function()
		return remote:InvokeServer("Announce", scope, messageBox.Text, confirmed)
	end)
	busy = false
	if not ok or type(reply) ~= "table" then
		setStatus("Couldn't reach the server. Nothing was sent.", BAD)
		return
	end
	local message = if type(reply.message) == "string" then reply.message else "No answer."
	setStatus(message, if reply.ok == true then GOOD else BAD)
	if reply.ok == true then
		messageBox.Text = ""
	end
end

thisServer.Activated:Connect(function()
	scope = "server"
	setAllConfirm(false)
	paintScope()
end)
allServers.Activated:Connect(function()
	scope = "all"
	setAllConfirm(false)
	paintScope()
end)
sendAnnouncement.Activated:Connect(function()
	if scope == "all" then
		setAllConfirm(true)
	else
		announce(false)
	end
end)
cancelAll.Activated:Connect(function()
	setAllConfirm(false)
	setStatus("Not sent.", MUTED)
	selectIfPad(sendAnnouncement)
end)
confirmAll.Activated:Connect(function()
	setAllConfirm(false)
	selectIfPad(sendAnnouncement)
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
	{ id = "snarlbloom", button = pickSnarlbloom, note = "SNARLBLOOM: GREENHOLLOW'S SECRET" },
	{ id = "petalfawn", button = pickPetalfawn, note = "PETALFAWN: STARBLOOM'S SECRET" },
}
local LOCKED_GRANT_TOP, LOCKED_GRANT_BOTTOM = Color3.fromRGB(96, 92, 80), Color3.fromRGB(64, 60, 52)
local secretSpecies = "snarlbloom"
local secretKind = "pod"
local secretEquip = false
local granting = false
-- The last request whose answer never arrived, to send again unchanged.
local unanswered: { species: string, kind: string, equip: boolean, request: string }? = nil

local function relabel(b: GuiObject, text: string)
	local label = b:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function paintSecret()
	for _, choice in ipairs(SECRET_CHOICES) do
		local on = choice.id == secretSpecies
		paint(choice.button, if on then SCOPE_ON_TOP else SCOPE_OFF_TOP, if on then SCOPE_ON_BOTTOM else SCOPE_OFF_BOTTOM)
		if on then
			creatureNote.Text = choice.note
		end
	end
	local pod = secretKind == "pod"
	paint(pickPod, if pod then SCOPE_ON_TOP else SCOPE_OFF_TOP, if pod then SCOPE_ON_BOTTOM else SCOPE_OFF_BOTTOM)
	paint(pickPlant, if pod then SCOPE_OFF_TOP else SCOPE_ON_TOP, if pod then SCOPE_OFF_BOTTOM else SCOPE_ON_BOTTOM)
	paint(equipToggle, if secretEquip then SCOPE_ON_TOP else SCOPE_OFF_TOP,
		if secretEquip then SCOPE_ON_BOTTOM else SCOPE_OFF_BOTTOM)
	relabel(equipToggle, if secretEquip then "EQUIP NOW: ON" else "EQUIP NOW: OFF")
	paint(grantButton, if granting then LOCKED_GRANT_TOP else GRANT_TOP, if granting then LOCKED_GRANT_BOTTOM else GRANT_BOTTOM)
	relabel(grantButton, if granting then "GRANTING…" else "GRANT TO BAG")
	grantButton.AutoButtonColor = not granting
	recipientLine.Text = string.format("RECIPIENT: %s (YOU). Only you, in this version.", player.Name)
end

local function grantSecret()
	if busy or granting then
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
	setStatus("Granting…", MUTED)
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
	local colour = if reply.ok ~= true then BAD elseif reply.saved == false then GOLD else GOOD
	setStatus(message, colour)
end

pickSnarlbloom.Activated:Connect(function()
	secretSpecies = "snarlbloom"
	paintSecret()
end)
pickPetalfawn.Activated:Connect(function()
	secretSpecies = "petalfawn"
	paintSecret()
end)
pickPod.Activated:Connect(function()
	secretKind = "pod"
	paintSecret()
end)
pickPlant.Activated:Connect(function()
	secretKind = "plant"
	paintSecret()
end)
equipToggle.Activated:Connect(function()
	secretEquip = not secretEquip
	paintSecret()
end)
grantButton.Activated:Connect(grantSecret)
paintSecret()

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

--==============================================================================
-- WEATHER (2026-10-02)
--
-- The line reads WeatherService's attributes the way the phase line reads the
-- clock's, and is redrawn with it once a second while the panel is open. The
-- two buttons only ask; the server refuses anyone but the owner.
--==============================================================================
local RAIN_ATTR = WEATHER.Attributes

local function drawRain()
	local state = Workspace:GetAttribute(RAIN_ATTR.State)
	local endsAt = Workspace:GetAttribute(RAIN_ATTR.EndsAt)
	if type(state) ~= "string" or type(endsAt) ~= "number" then
		rainLabel.Text = "RAIN: OFF"
		rainLabel.TextColor3 = MUTED
		return
	end
	local name = if Workspace:GetAttribute(RAIN_ATTR.Mode) == "thunder" then "THUNDERSTORM" else "RAIN"
	if state == "closing" then
		rainLabel.Text = name .. ": ENDING  •  THE BIOME IS FADING"
	else
		rainLabel.Text = string.format("%s: %s  •  %s LEFT", name,
			if state == "active" then "ACTIVE, BIOME OPEN" else "STARTING", mmss(endsAt - Workspace:GetServerTimeNow()))
	end
	rainLabel.TextColor3 = NIGHT_INK
end
Workspace:GetAttributeChangedSignal(RAIN_ATTR.State):Connect(drawRain)
Workspace:GetAttributeChangedSignal(RAIN_ATTR.EndsAt):Connect(drawRain)
Workspace:GetAttributeChangedSignal(RAIN_ATTR.Mode):Connect(drawRain)

local function askWeather(verb: string, seconds: number?)
	if busy then
		return
	end
	busy = true
	setStatus(if verb == "start" then "Starting the rain…"
		elseif verb == "thunder" then "Starting the thunderstorm…"
		else "Ending the weather…", MUTED)
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
startRain.Activated:Connect(function()
	startWeather("start")
end)
startThunder.Activated:Connect(function()
	startWeather("thunder")
end)
endRain.Activated:Connect(function()
	askWeather("end", nil)
end)
drawRain()

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
		elseif confirmingAll then
			setAllConfirm(false)
			setStatus("Not sent.", MUTED)
			selectIfPad(sendAnnouncement)
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
