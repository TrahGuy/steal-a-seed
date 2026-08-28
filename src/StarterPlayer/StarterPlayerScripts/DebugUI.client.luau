--!strict
-- Steal a Seed :: DebugUI
--
--==============================================================================
-- THE DEVELOPER PANEL
--
-- F4 opens it. Everything it does goes to DebugService over one RemoteEvent,
-- and DebugService decides whether to listen -- this file hiding itself from a
-- player is a courtesy, not the rule. The rule is on the server.
--
-- It builds nothing at all unless the local player passes the same gate the
-- server uses, so an ordinary player does not have a hidden panel one keypress
-- away; they have no panel.
--
--==============================================================================
-- PLAIN CHROME, DELIBERATELY
--
-- The HUD has a shared look (UIKit, the gold rail) and this does not use it.
-- A debug panel that looked like the game would be a debug panel somebody
-- screenshots into a bug report and mistakes for the game. It is grey, it is
-- ugly, and it says DEBUG across the top.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
local SeedData = require(SeedGame.Shared:WaitForChild("SeedData"))
local BiomeData = require(SeedGame.Shared:WaitForChild("BiomeData"))

local player = Players.LocalPlayer

--==============================================================================
-- THE SAME GATE THE SERVER USES
--
-- Kept in step with DebugService by being the same three checks in the same
-- order. If they ever disagree the server wins, which is the correct way round.
--==============================================================================
local function isAllowed(): boolean
	if not GameConfig.Debug.Enabled then
		return false
	end
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	for _, id in ipairs(GameConfig.Debug.UserIds) do
		if player.UserId == id then
			return true
		end
	end
	return false
end

if not isAllowed() then
	return
end

local remotes = SeedGame:WaitForChild("Remotes")
local channel = remotes:WaitForChild(GameConfig.Remotes.DebugCommand) :: RemoteEvent

-- Right edge, vertically centred. Kept as a constant because the drag
-- below can put the panel anywhere, and something has to know the way back.
local DEFAULT_POSITION = UDim2.new(1, -16, 0.5, 0)

local INK = Color3.fromRGB(232, 232, 236)
local PANEL = Color3.fromRGB(24, 26, 30)
local ROW = Color3.fromRGB(38, 41, 47)
local ACCENT = Color3.fromRGB(232, 92, 132)

local function send(action: string, payload: { [string]: any }?)
	channel:FireServer(action, payload or {})
end

--==============================================================================
-- BUILDING BLOCKS
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedDebug"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5000
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Panel"
root.Size = UDim2.fromOffset(330, 560)
--==============================================================================
-- RIGHT SIDE, NOT LEFT
--
-- It used to open at (16, 16), which is exactly where the Index rail button
-- lives -- so the one panel you open to test things covered the first thing you
-- would want to click. Anchored to the right edge instead, and it stays put
-- relative to that edge when the window is resized.
--==============================================================================
root.AnchorPoint = Vector2.new(1, 0.5)
root.Position = DEFAULT_POSITION
root.BackgroundColor3 = PANEL
root.BorderSizePixel = 0
root.Parent = gui
Instance.new("UICorner").Parent = root

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = root

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.Parent = root

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local function label(text: string, height: number, colour: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0, height)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Code
	t.Text = text
	t.TextColor3 = colour
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.LayoutOrder = nextOrder()
	t.Parent = root
	return t
end

local function heading(text: string)
	local t = label(text, 20, ACCENT)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
end

local function row(): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 26)
	f.BackgroundTransparency = 1
	f.LayoutOrder = nextOrder()
	f.Parent = root
	local h = Instance.new("UIListLayout")
	h.FillDirection = Enum.FillDirection.Horizontal
	h.Padding = UDim.new(0, 4)
	h.SortOrder = Enum.SortOrder.LayoutOrder
	h.Parent = f
	return f
end

local function button(parent: Instance, text: string, width: number,
	onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, width, 1, 0)
	b.BackgroundColor3 = ROW
	b.BorderSizePixel = 0
	b.Font = Enum.Font.Code
	b.Text = text
	b.TextColor3 = INK
	b.TextSize = 13
	b.AutoButtonColor = true
	b.Parent = parent
	Instance.new("UICorner").Parent = b
	b.Activated:Connect(onClick)
	return b
end

local function field(parent: Instance, placeholder: string, width: number): TextBox
	local t = Instance.new("TextBox")
	t.Size = UDim2.new(0, width, 1, 0)
	t.BackgroundColor3 = Color3.fromRGB(16, 17, 20)
	t.BorderSizePixel = 0
	t.Font = Enum.Font.Code
	t.PlaceholderText = placeholder
	t.Text = ""
	t.TextColor3 = INK
	t.TextSize = 13
	t.ClearTextOnFocus = false
	t.Parent = parent
	Instance.new("UICorner").Parent = t
	return t
end

--==============================================================================
-- THE PANEL
--==============================================================================
local title = label("DEBUG  ·  F4  ·  drag me", 22, INK)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

--==============================================================================
-- DRAGGING, BY THE TITLE BAR ONLY
--
-- Not Frame.Draggable: that is deprecated, ignores touch, and would let a stray
-- press anywhere on the panel start a drag -- including on the buttons, which is
-- most of the panel.
--
-- Active = true is what makes a TextLabel receive input at all. The move is
-- tracked on UserInputService rather than on the label, because a fast drag
-- leaves the cursor behind and a label-only connection drops the panel the
-- moment the pointer outruns it.
--==============================================================================
title.Active = true

local dragging = false
local dragOrigin = Vector2.zero
local dragFrom = DEFAULT_POSITION

local function isDragInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

title.InputBegan:Connect(function(input)
	if isDragInput(input) then
		dragging = true
		dragOrigin = Vector2.new(input.Position.X, input.Position.Y)
		dragFrom = root.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragOrigin
		root.Position = UDim2.new(
			dragFrom.X.Scale, dragFrom.X.Offset + delta.X,
			dragFrom.Y.Scale, dragFrom.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if isDragInput(input) then
		dragging = false
	end
end)

local echo = label("", 34, Color3.fromRGB(150, 210, 150))
echo.TextWrapped = true

heading("SPEED")
local speedRow = row()
local speedBox = field(speedRow, "speed", 120)
button(speedRow, "set", 44, function()
	send("SetSpeed", { value = tonumber(speedBox.Text) })
end)
button(speedRow, "+1M", 46, function()
	send("AddSpeed", { value = 1e6 })
end)
button(speedRow, "+1B", 46, function()
	send("AddSpeed", { value = 1e9 })
end)

local speedJump = row()
-- The four recommendations, because those are the numbers the game is balanced
-- against and typing 167000000 by hand is how a test ends up at 16.7M instead.
for _, biome in ipairs(BiomeData.Biomes) do
	if biome.RecommendedSpeed > 0 then
		button(speedJump, string.sub(biome.DisplayName, 1, 4), 72, function()
			send("SetSpeed", { value = biome.RecommendedSpeed })
		end)
	end
end

heading("CASH")
local cashRow = row()
local cashBox = field(cashRow, "cash", 120)
button(cashRow, "set", 44, function()
	send("SetCash", { value = tonumber(cashBox.Text) })
end)
button(cashRow, "+1M", 46, function()
	send("AddCash", { value = 1e6 })
end)
button(cashRow, "+1B", 46, function()
	send("AddCash", { value = 1e9 })
end)

heading("SPAWN A POD")
local podRow = row()
local kgBox = field(podRow, "kg (blank = roll)", 150)
button(podRow, "random", 74, function()
	send("SpawnPod", { species = "random", kg = tonumber(kgBox.Text) })
end)

-- One button per species, so a specific shape can be summoned without typing
-- an id. Wrapped across rows because there are fifteen of them and counting.
local speciesRow = row()
local inRow = 0
for _, biome in ipairs(BiomeData.Biomes) do
	for _, sp in ipairs(SeedData.InBiome(biome.Id)) do
		if inRow >= 4 then
			speciesRow = row()
			inRow = 0
		end
		inRow += 1
		button(speciesRow, string.sub(sp.Name, 1, 7), 74, function()
			send("SpawnPod", { species = sp.Id, kg = tonumber(kgBox.Text) })
		end)
	end
end

heading("GO TO")
local goRow = row()
local goCount = 0
button(goRow, "plot", 74, function()
	send("Teleport", { where = "plot" })
end)
button(goRow, "field", 74, function()
	send("Teleport", { where = "field" })
end)
goCount = 2
for _, biome in ipairs(BiomeData.Biomes) do
	if goCount >= 4 then
		goRow = row()
		goCount = 0
	end
	goCount += 1
	button(goRow, string.sub(biome.DisplayName, 1, 7), 74, function()
		send("Teleport", { where = biome.Id })
	end)
end

heading("MILL & PLOT")
local millRow = row()
local tierBox = field(millRow, "tier", 60)
local overBox = field(millRow, "over", 60)
button(millRow, "set mill", 84, function()
	send("SetMill", { tier = tonumber(tierBox.Text), overclock = tonumber(overBox.Text) })
end)
local plotRow = row()
local plotBox = field(plotRow, "plot tier", 100)
button(plotRow, "set plot", 84, function()
	send("SetPlotTier", { value = tonumber(plotBox.Text) })
end)

heading("NESTS")
local nestRow = row()
button(nestRow, "restock", 84, function()
	send("RestockNests")
end)
button(nestRow, "parents home", 118, function()
	send("ResetParents")
end)
local nestRow2 = row()
button(nestRow2, "wake nearest", 118, function()
	send("WakeNearest")
end)

heading("BAG")
local bagRow = row()
button(bagRow, "sell all", 74, function()
	send("SellBag")
end)
button(bagRow, "clear", 66, function()
	send("ClearBag")
end)
button(bagRow, "drop carry", 96, function()
	send("DropCarry")
end)

heading("STATE")
button(row(), "snapshot to server log", 200, function()
	send("Snapshot")
end)

--==============================================================================
-- THE ECHO
--
-- The server answers every command with a line. Without it the panel is a wall
-- of buttons that may or may not have done anything, which is the exact failure
-- mode a debug tool exists to prevent.
--==============================================================================
channel.OnClientEvent:Connect(function(action: string, result: string)
	echo.Text = string.format("%s: %s", tostring(action), tostring(result))
end)

--==============================================================================
-- F4
--
-- ContextActionService rather than UserInputService, so it does not fire while
-- a text box in the panel has focus -- which would close the panel every time
-- somebody typed a weight.
--==============================================================================
--==============================================================================
-- A PANEL DRAGGED OFF THE SCREEN IS A PANEL YOU CANNOT GET BACK
--
-- Checked on the way OPEN rather than clamped during the drag: clamping fights
-- the pointer and feels broken, and this only has to catch the one case that
-- actually strands the tool. If less than a corner of it is on screen, it goes
-- home.
--==============================================================================
local function ensureReachable()
	local view = root.Parent :: GuiBase2d
	local screen = view.AbsoluteSize
	local pos, size = root.AbsolutePosition, root.AbsoluteSize
	local onX = math.min(pos.X + size.X, screen.X) - math.max(pos.X, 0)
	local onY = math.min(pos.Y + size.Y, screen.Y) - math.max(pos.Y, 0)
	if onX < 60 or onY < 40 then
		root.Position = DEFAULT_POSITION
	end
end

-- Bound to the PROPERTY, not to the keybind. F4 is only one way the panel can
-- open, and a rescue that only runs on one of them is a rescue you will
-- eventually be missing.
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if gui.Enabled then
		ensureReachable()
	end
end)

ContextActionService:BindAction("SeedDebugToggle", function(_, state)
	if state == Enum.UserInputState.Begin then
		gui.Enabled = not gui.Enabled
	end
	return Enum.ContextActionResult.Sink
end, false, (Enum.KeyCode :: any)[GameConfig.Debug.ToggleKey])

print(string.format("[Seed/DebugUI] ready -- press %s", GameConfig.Debug.ToggleKey))
