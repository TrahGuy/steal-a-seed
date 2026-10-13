--!strict
-- Steal a Seed :: PadStick
--
-- THE RIGHT STICK IN A MENU (2026-10-13; Michael's console feedback, the
-- owner's backlog item 3: "In menus the right stick should lock for
-- scrolling. I can see character is still looking around.")
--
-- While any panel is open (PadInput.panelOpen: OpenPanel names one, or a
-- modal's dimmer is showing -- the Shop, the Bag, Garden, the Index, Rebirth,
-- Mosskeeper's talk, the admin console...), the right stick is the menu's:
-- bound on ContextActionService at High, above the camera's own Thumbstick2
-- bind (the PlayerModule's, at Medium), and SUNK, so the camera stays still.
-- Every frame it scrolls the list PadScroll.pick chooses: the one around the
-- selected control that can move that way, else the panel's biggest -- up and
-- down, and across where a list scrolls across.
--
--==============================================================================
-- RELEASED ON EVERY CLOSE PATH
--
-- The bind follows PadInput's panel state, which every way a panel shuts goes
-- through: B (OpenPanel cleared), its X, another panel taking its place, a
-- respawn that destroys its gui. And a frame watch unbinds the moment no panel
-- is open, whatever missed a signal. The left stick and the D-pad are never
-- touched: they keep moving the selection.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local PadScroll = require(Shared:WaitForChild("PadScroll"))

local player = Players.LocalPlayer

local ACTION = "SeedMenuStick"
-- Above the camera's Thumbstick2 (Medium), so its turn never sees the stick.
local PRIORITY = Enum.ContextActionPriority.High.Value

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
ContextActionService:UnbindAction(ACTION)

local bound = false
local stick = Vector2.zero

local function onStick(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	else
		stick = Vector2.zero
	end
	-- Sunk in every state: the camera hears nothing of it while a menu is up.
	return Enum.ContextActionResult.Sink
end

local function setBound(want: boolean)
	if want == bound then
		return
	end
	bound = want
	stick = Vector2.zero
	if want then
		ContextActionService:BindActionAtPriority(ACTION, onStick, false, PRIORITY, Enum.KeyCode.Thumbstick2)
	else
		ContextActionService:UnbindAction(ACTION)
	end
end

local function refresh()
	setBound(PadInput.panelOpen())
end

PadInput.PanelChanged:Connect(refresh)
PadInput.watch()
player:GetAttributeChangedSignal(GameConfig.Attributes.OpenPanel):Connect(refresh)

RunService.RenderStepped:Connect(function(dt: number)
	if not bound then
		return
	end
	-- The watch: whatever shut the panel, the stick is the camera's again now.
	if not PadInput.panelOpen() then
		setBound(false)
		return
	end
	if math.abs(stick.X) <= PadScroll.Deadzone and math.abs(stick.Y) <= PadScroll.Deadzone then
		return
	end
	local _, gui = PadInput.openPanel()
	local selected = GuiService.SelectedObject
	local panel: Instance? = gui
	if not panel and selected then
		-- A panel on the OpenPanel mutex with no dimmer: the gui the selection is in.
		panel = selected:FindFirstAncestorWhichIsA("LayerCollector")
	end
	local list = PadScroll.pick(selected, panel, stick)
	if list then
		list.CanvasPosition = PadScroll.step(list.CanvasPosition, PadScroll.limit(list), stick, dt)
	end
end)

refresh()
