--!strict
-- Steal a Seed :: PlotTeleportUI
--
-- TELEPORT TO PLOT: one button, top centre under the clock, while the player
-- is alive, has a plot and is standing in the Safe Zone.
--
--==============================================================================
-- THE CLIENT SHOWS IT. THE SERVER DECIDES IT.
--
-- Pressing sends one verb on GameEvent and nothing else -- no plot id, no
-- position. PlotService.TeleportHome takes the player from the sender, the plot
-- from its own lease and the destination from SpawnCFrameFor, and checks every
-- press again: alive, has a plot, in the Safe Zone, no raided pod, not trapped
-- or knocked down, outside its cooldown, ground under the spawn. A refusal a
-- player can act on comes back as a toast (ActionToastUI).
--
-- The three facts this shows off are the server's, replicated, and each
-- arrives as an event -- there is no loop here:
--
--   alive          the Humanoid's own Died / HealthChanged, re-hooked per body
--   has a plot     the player's OwnPlotId attribute (PlotService)
--   in the zone    the player's InSafeZone attribute, from BiomeGateService's
--                  road poll -- off within a tenth of a second of the road
--
--==============================================================================
-- MOUSE, TOUCH AND CONTROLLER
--
-- A GuiButton: a click and a tap are the same Activated, and a controller can
-- select it through Roblox's own UI navigation. While it is showing, D-pad Up
-- presses it as well -- bound only then, so it takes nothing from anybody the
-- rest of the time. And never while a panel is open or the selection is out on
-- the HUD: that D-pad Up is the UI's, walking the selection up, and a teleport
-- home on top of it would be one press doing two things (PlantPlace's rule).
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

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
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local PAD_ACTION = "SeedTeleportToPlot"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedPlotTeleport")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(PAD_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedPlotTeleport"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- Over the world and the prompts, under the belt's ScreenGui and every panel,
-- so an open panel covers it rather than it poking through one.
gui.DisplayOrder = 26
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON
--
-- The Shop tile's emerald with a lime rim, the Garden's own sprout artwork --
-- "home" in this game's words -- and the label in the HUD's outlined face.
--
-- THE TOUCH AREA AND THE PLATE ARE TWO THINGS. The button is the touch area --
-- exactly HudLayout's `teleport` rect, the thing a click, a tap and the
-- controller's selection land on -- and draws nothing itself. Everything seen
-- is the PLATE inside it, drawn at HudLayout's `teleportScale`: 1 everywhere,
-- so a desktop's button is the pixels it always was; smaller on a phone, where
-- since the owner's mobile corrections (2026-10-05) the target is only as
-- wide as the plate drawn -- PLOT, 51 x 44 (HudLayout, TELEPORT TO PLOT ON A
-- PHONE). The plate is the old button's own set-up
-- moved one level down -- a text object with no text, the same corner,
-- gradient and stroke -- so it renders exactly as the button did.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "TeleportToPlot"
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
-- outline on the BORDER (it never drew on the old text-less label), the
-- family's darker foot, the inner rim, the icon and the outlined word.
local hud = UIKit.hudPlate(button, {
	top = RAIL.ShopTileTop,
	bottom = RAIL.ShopTileBottom,
	rim = RAIL.ShopEdge,
	image = RAIL.GardenIcon,
	text = "TELEPORT TO PLOT",
})
local plate = hud.plate
local plateScale = hud.scale
local rim = hud.rim
local icon = hud.icon
local label = hud.label


local scale = Instance.new("UIScale")
scale.Parent = button
UIKit.cardPop(button, scale, { hoverScale = 1.04, pressScale = 0.96, sound = false })

--==============================================================================
-- WHERE IT SITS: HudLayout's `teleport`, asked when the screen changes shape
--
-- And when the topbar's free span does, as WorldClock asks: the button stands
-- under the clock and 8 px off the ADMIN button, and both move with the span.
-- Measured on the owner's emulated phone, the span settles a moment after the
-- first layout -- asked only then, the ADMIN button still hung under a clock
-- with no room beside it, and the button stayed 22 px low for the session.
--==============================================================================
local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.teleport
	button.Position = HudLayout.place(r, button.AnchorPoint, layout.safe)
	button.Size = UDim2.fromOffset(r.w, r.h)
	-- The plate's own size, before its scale: the touch area's everywhere but a
	-- phone, where each of the top row's plates, drawn at its scale, is exactly
	-- its touch area (HudLayout, THE PHONE'S TOP ROW).
	plate.Size = UDim2.fromOffset(layout.teleportPlate.X, layout.teleportPlate.Y)
	plateScale.Scale = layout.teleportScale
	-- THE OWNER'S MOBILE CORRECTIONS (2026-10-05): on a touch screen the button
	-- says exactly PLOT, with no icon -- the same button and the same press.
	local short = layout.teleportShort
	label.Text = if short then "PLOT" else "TELEPORT TO PLOT"
	icon.Visible = not short
	if short then
		label.Position = UDim2.new(0, 6, 0.5, 1)
		label.Size = UDim2.new(1, -12, 0, 22)
	else
		label.Position = UDim2.new(0, 42, 0.5, 1)
		label.Size = UDim2.new(1, -50, 0, 22)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
gui.Destroying:Once(function()
	topbarWatch:Disconnect()
end)
place()

--==============================================================================
-- THE PRESS
--
-- Guarded here only against a double tap sending two requests in one gesture;
-- the cooldown that matters is the server's.
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
	remote:FireServer(PLOT.TeleportAction)
end

button.Activated:Connect(request)

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/PlotTeleportUI] No GameEvent remote; the button cannot ask for anything.")
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
			-- Passed on, not eaten, while the UI has the buttons: the engine's
			-- navigation then moves the selection up as it would unbound.
			if state == Enum.UserInputState.Begin
				and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
				request()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.DPadUp)
	else
		ContextActionService:UnbindAction(PAD_ACTION)
	end
end

local function alive(): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and humanoid.Health > 0
end

local function refresh()
	-- Never on the Floating Garden: ObbyUI's RETURN TO PLOT has this slot
	-- there, and for the moment between Start and landing on the course the
	-- runner is still standing in the Safe Zone.
	local want = alive()
		and player:GetAttribute(ATTR.OwnPlotId) ~= nil
		and player:GetAttribute(ATTR.InSafeZone) == true
		and player:GetAttribute(ObbyData.Attributes.Course) ~= true
	button.Visible = want
	bindPad(want)
end

player:GetAttributeChangedSignal(ATTR.OwnPlotId):Connect(refresh)
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
refresh()
