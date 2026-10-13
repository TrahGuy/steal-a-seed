--!strict
-- Steal a Seed :: SellButtonUI
--
-- SELL: one button right beside TELEPORT TO PLOT (2026-10-13, the owner's
-- backlog item 7: "change the obby navigation pill to SELL, and teleport to
-- marigold"; it was the OBBY button, 2026-09-27, in the same place), while the
-- player is alive, standing in the Safe Zone and not on the course. A press
-- asks for Marigold's stall -- in front of the SELL ALL board, inside its
-- prompt, facing between the board and her -- and it sells nothing: the board
-- still sells, like any other time.
--
--==============================================================================
-- THE CLIENT SHOWS IT. THE SERVER DECIDES IT.
--
-- One verb on GameEvent and nothing else. PlotService.TeleportToSell checks
-- every press with TELEPORT TO PLOT's own rules and its shared cooldown
-- (PlotService.TeleportTo) -- alive, in the Safe Zone, no raided pod, not
-- trapped or knocked down, ground under the landing -- and on top of those,
-- never during a chase. A refusal a player can act on comes back as a notice
-- (ActionToastUI).
--
--==============================================================================
-- WHERE, AND HOW IT LOOKS
--
-- HudLayout's `obby` rect (the name it kept): TELEPORT's own row and height,
-- 8 px off it, drawn at TELEPORT's scale -- so on a phone it stands up under
-- the clock with it. The plate is TELEPORT's, built the same way one level down
-- from the touch area, in the Index tile's slate with a sky-blue rim so the two
-- never read as one button; the icon is a gold coin with a dollar sign, drawn
-- from frames, and the word is SELL. Where there is only room for the word,
-- only the word; where a screen has no room beside TELEPORT at all, the rect is
-- empty and the button stays hidden rather than cover anything.
--
-- A CONTROLLER presses it with D-pad Right while it shows (TELEPORT has Up),
-- bound only then, and never while a panel is open or the selection is out on
-- the HUD -- that D-pad Right is the UI's (PlotTeleportUI's rule).
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local PLOT = GameConfig.Plot
local BLACK = Color3.fromRGB(0, 0, 0)
local GOLD = Color3.fromRGB(255, 206, 84)
local GOLD_DEEP = Color3.fromRGB(232, 158, 30)
local GOLD_LIGHT = Color3.fromRGB(255, 244, 196)
local PAD_ACTION = "SeedTeleportToSell"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSellButton")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(PAD_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSellButton"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- TELEPORT TO PLOT's own order: over the world and the prompts, under every panel.
gui.DisplayOrder = 26
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON: the touch area is HudLayout's `obby` rect and draws nothing; the
-- PLATE inside it is drawn at the layout's `teleportScale`, like TELEPORT's.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "TeleportToSell"
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Selectable = true
button.Text = ""
button.Visible = false
button.Parent = gui
UIKit.clicks(button)

-- The HUD's plate button (UIKit.hudPlate, the global UI pass 2026-10-04): the
-- outline on the BORDER, the family's darker foot, the inner rim, the icon and
-- the outlined word.
local hud = UIKit.hudPlate(button, {
	top = RAIL.TileTop,
	bottom = RAIL.TileBottom,
	rim = RAIL.IndexEdge,
	text = "SELL",
})
local plate = hud.plate
local plateScale = hud.scale
local icon = hud.icon
local label = hud.label
-- A gold coin with a dollar sign, in 28 px: the rim, a deeper face, the sign,
-- and a glint.
local coin = UIKit.piece(icon, "Coin", 0.5, 0.52, 0.86, 0.86, GOLD, 0.5)
UIKit.stroke(coin, BLACK, 1.5)
UIKit.piece(icon, "Face", 0.5, 0.52, 0.6, 0.6, GOLD_DEEP, 0.5, nil, 3)
local sign = Instance.new("TextLabel")
sign.Name = "Dollar"
sign.AnchorPoint = Vector2.new(0.5, 0.5)
sign.Position = UDim2.fromScale(0.5, 0.53)
sign.Size = UDim2.fromScale(0.5, 0.56)
sign.BackgroundTransparency = 1
sign.Font = Enum.Font.FredokaOne
sign.Text = "$"
sign.TextScaled = true
sign.TextColor3 = GOLD_LIGHT
sign.ZIndex = 4
sign.Parent = icon
UIKit.piece(icon, "Glint", 0.32, 0.3, 0.16, 0.1, GOLD_LIGHT, 0.5, -35, 4)

local scale = Instance.new("UIScale")
scale.Parent = button
UIKit.cardPop(button, scale, { hoverScale = 1.04, pressScale = 0.96, sound = false })

--==============================================================================
-- WHERE IT SITS: HudLayout's `obby`, asked when the screen or the topbar's free
-- span changes -- exactly when TELEPORT TO PLOT asks for its own.
--==============================================================================
local roomy = false
local refresh: () -> ()

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.obby
	roomy = r.w > 0
	if roomy then
		button.Position = HudLayout.place(r, button.AnchorPoint, layout.safe)
		button.Size = UDim2.fromOffset(r.w, r.h)
	end
	plateScale.Scale = layout.teleportScale
	-- The plate before its scale (2026-10-05): its touch area's own size, but on a
	-- phone's even row exactly its touch area once drawn (HudLayout's obbyPlate).
	if roomy then
		plate.Size = UDim2.fromOffset(layout.obbyPlate.X, layout.obbyPlate.Y)
	end
	icon.Visible = layout.obbyWide
	if layout.obbyWide then
		label.Position = UDim2.new(0, 42, 0.5, 1)
		label.Size = UDim2.new(1, -50, 0, 22)
	else
		label.Position = UDim2.new(0, 6, 0.5, 1)
		label.Size = UDim2.new(1, -12, 0, 22)
	end
	refresh()
end

--==============================================================================
-- THE PRESS: guarded only against a double tap sending two requests; the
-- cooldown that matters is the server's, shared with TELEPORT TO PLOT.
--==============================================================================
local channel: RemoteEvent? = nil
local lastPress = 0

local function request()
	local remote = channel
	if not (remote and button.Visible) then
		return
	end
	local now = os.clock()
	if now - lastPress < 0.35 then
		return
	end
	lastPress = now
	remote:FireServer(PLOT.SellAction)
	-- A note for this client's own ObbyCamera, which turns the camera to the
	-- stall once if the body does land there, and for the guide's travel step.
	-- It never leaves this machine.
	player:SetAttribute(PLOT.SellAskedAttribute, now)
end

button.Activated:Connect(request)

-- LIT BY THE GUIDE, ITS D-PAD KEY STILL PRESSES IT (2026-10-08): D-pad Right,
-- only while TutorialUI's spotlight has it lit (GuideLit) and selected --
-- PlotTeleportUI's listener, and its reasons, word for word.
UserInputService.InputBegan:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.DPadRight and button.Visible and button:GetAttribute(ATTR.GuideLit) == true
		and GuiService.SelectedObject == button and not PadInput.panelOpen() then
		request()
	end
end)

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/SellButtonUI] No GameEvent remote; the button cannot ask for anything.")
	end
end)

--==============================================================================
-- SHOWN OR NOT
--==============================================================================
local padBound = false

local function bindPad(want: boolean)
	if want == padBound then
		return
	end
	padBound = want
	if want then
		ContextActionService:BindAction(PAD_ACTION, function(_, state: Enum.UserInputState)
			-- Passed on while the UI has the buttons: the engine's navigation then
			-- moves the selection right as it would unbound.
			if state == Enum.UserInputState.Begin
				and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
				request()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.DPadRight)
	else
		ContextActionService:UnbindAction(PAD_ACTION)
	end
end

local function alive(): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and humanoid.Health > 0
end

refresh = function()
	-- Today's rules (the owner's default for item 7): never on the course
	-- (RETURN TO PLOT is the way off it), and never where the screen had no
	-- room for it.
	local want = roomy and alive()
		and player:GetAttribute(ATTR.InSafeZone) == true
		and player:GetAttribute(ObbyData.Attributes.Course) ~= true
	button.Visible = want
	bindPad(want)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
gui.Destroying:Once(function()
	topbarWatch:Disconnect()
	ContextActionService:UnbindAction(PAD_ACTION)
end)

player:GetAttributeChangedSignal(ATTR.InSafeZone):Connect(refresh)
player:GetAttributeChangedSignal(ObbyData.Attributes.Course):Connect(refresh)

local bodyConnections: { RBXScriptConnection } = {}

local function watchBody(character: Model)
	for _, c in ipairs(bodyConnections) do
		c:Disconnect()
	end
	table.clear(bodyConnections)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") and character.Parent then
		table.insert(bodyConnections, humanoid.Died:Connect(refresh))
		table.insert(bodyConnections, humanoid.HealthChanged:Connect(refresh))
	end
	refresh()
end

player.CharacterAdded:Connect(watchBody)
player.CharacterRemoving:Connect(function()
	button.Visible = false
	bindPad(false)
end)
if player.Character then
	task.spawn(watchBody, player.Character)
end
place()
