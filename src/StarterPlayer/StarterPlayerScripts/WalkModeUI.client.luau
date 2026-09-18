--!strict
-- Steal a Seed :: WalkModeUI
--
--==============================================================================
-- A SWITCH THAT SAYS WHETHER YOU ARE WALKING
--
-- One compact slab directly under the Settings gear, in the same rail layer, with
-- the word WALK MODE and a pill that reads ON or OFF. Pressing it asks the server;
-- the server answers by changing an attribute; this file draws the attribute.
--
-- IT IS NOT IN THE SETTINGS PANEL, and that is the whole design. This is used
-- mid-stride -- lining a plant up, reading a sign, walking beside somebody who is
-- slower than you -- and a control you have to open a modal to reach is a control
-- nobody uses while moving. The panel is for things you set once.
--
--==============================================================================
-- THE SERVER IS THE SWITCH. THIS IS THE LAMP.
--
-- The button sends a verb and a boolean on the GameEvent remote and then does
-- NOTHING to its own state: no optimistic flip, no local attribute write, no
-- guessing. CarryService validates the request, PlayerDataService writes the
-- profile and stamps the replicated attribute, and the label follows that.
--
-- So a client that fakes the attribute changes its own word for one frame and its
-- own speed never, because the speed is computed on the other side. And a refusal
-- -- mid-respawn, no profile yet -- leaves the label telling the truth rather than
-- showing ON over a player who is still sprinting.
--
--==============================================================================
-- WHERE IT SITS, AND WHAT IT MUST NOT COVER
--
-- Left rail, fourth row: Index, Shop, Settings, then this. The left column is the
-- only part of the HUD that stacks downward, and it ends here -- the cash and
-- Speed readouts are top-right, the hotbar is bottom-centre, the Bag's column is
-- right, and the joystick and jump button are bottom-left and bottom-right of the
-- touch layer, which this never reaches.
--
-- 130 x 46, so the touch target clears the 44-pixel floor in both axes on the
-- narrowest phone this game supports, and the same width as the rail buttons above
-- it so the column reads as one column.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local RAIL = GameConfig.Rail
local WALK = GameConfig.WalkMode
local ATTR = GameConfig.Attributes

local SIZE = Vector2.new(RAIL.WideSize.X, 46)
-- Under Settings, which is the third row: inset plus three rows of the rail's own
-- height and gap. Read off GameConfig rather than written down, so a change to the
-- rail moves this with it.
local ROW = 3
local FACE = Color3.fromRGB(46, 52, 62)
local SHADE = Color3.fromRGB(28, 32, 40)
local ON_FACE = Color3.fromRGB(96, 178, 96)
local OFF_FACE = Color3.fromRGB(78, 84, 96)
local CREAM = Color3.fromRGB(242, 238, 222)

--==============================================================================
-- RE-RUN SAFE
--
-- A LocalScript that is synced while the game is running gets a second copy, and
-- the first copy's Destroying handler is not guaranteed to run -- so the new copy
-- removes the old switch rather than trusting the old one to have tidied up.
--==============================================================================
local layer = UIKit.railLayer(playerGui)
local stale = layer:FindFirstChild("WalkModeSwitch")
if stale then
	stale:Destroy()
end

local slab = UIKit.slab(layer, {
	size = UDim2.fromOffset(SIZE.X, SIZE.Y),
	face = FACE,
	shade = SHADE,
	radius = RAIL.Radius,
})
slab.Name = "WalkModeSwitch"
slab.Position = UDim2.new(0, RAIL.Inset, 0,
	RAIL.Inset + (RAIL.WideSize.Y + RAIL.Gap) * ROW)

local label = UIKit.outlined(slab, "Label", 13, CREAM, 2)
label.Position = UDim2.fromOffset(10, 4)
label.Size = UDim2.new(1, -20, 0, 18)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = WALK.Label
label.ZIndex = 6

--==============================================================================
-- THE PILL IS THE STATE, AND IT IS THE PART THAT CANNOT BE DECORATIVE
--
-- Reduced Effects turns the hover and the press animation off, because those are
-- decoration. The pill is not: it is the only thing on screen that says which way
-- the switch is, so it changes colour and word under every setting.
--==============================================================================
local pill = Instance.new("Frame")
pill.Name = "State"
pill.Position = UDim2.new(0, 10, 0, 24)
pill.Size = UDim2.new(1, -20, 0, 16)
pill.BackgroundColor3 = OFF_FACE
pill.BorderSizePixel = 0
pill.ZIndex = 6
pill.Parent = slab
UIKit.corner(pill, 8)

local state = UIKit.outlined(pill, "Text", 12, CREAM, 1.6)
state.Size = UDim2.new(1, 0, 1, 0)
state.Text = WALK.OffText
state.ZIndex = 7


--==============================================================================
-- WHAT THE SERVER SAYS, DRAWN
--==============================================================================
local function paint()
	local on = player:GetAttribute(ATTR.WalkMode) == true
	pill.BackgroundColor3 = if on then ON_FACE else OFF_FACE
	state.Text = if on then WALK.OnText else WALK.OffText
	--==========================================================================
	-- AND THE CAP ITSELF, SPELLED OUT WHILE IT IS ON
	--
	-- "ON 16" rather than "ON", because the number is the entire content of the
	-- feature and a player who has never seen Roblox's default walk speed has no
	-- way to know what they just asked for.
	--==========================================================================
	if on then
		state.Text = string.format("%s  %d", WALK.OnText, WALK.CapStuds)
	end
end

paint()
player:GetAttributeChangedSignal(ATTR.WalkMode):Connect(paint)

--==============================================================================
-- THE PRESS
--
-- Sends the OPPOSITE of what the server currently says, which is the only state
-- worth toggling from: toggling from a local variable is how a refused request
-- leaves the client convinced it is in a state the server has never heard of.
--==============================================================================
local channel: RemoteEvent? = nil
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	end
end)

local lastSent = 0
slab.Activated:Connect(function()
	local rem = channel
	if not rem then
		return
	end
	--==========================================================================
	-- ONE REQUEST PER FIFTH OF A SECOND
	--
	-- A held finger on a touch screen fires Activated repeatedly, and every one of
	-- those is a profile write and an attribute replication. The server refuses a
	-- no-change write anyway; this is so it is not asked ten times.
	--==========================================================================
	local now = os.clock()
	if now - lastSent < 0.2 then
		return
	end
	lastSent = now
	rem:FireServer(WALK.Action, not (player:GetAttribute(ATTR.WalkMode) == true))
end)

--==============================================================================
-- THE POP, WHICH IS THE ONLY DECORATION HERE
--
-- Desktop hover lifts it a little; a touch press squashes it. Both are the
-- house cues -- UIKit.slab already carries the click sound and
-- UIKit.popOnHover is what every other rail button uses -- and both are skipped
-- entirely under Reduced Effects, which is the one setting allowed to remove
-- animation and never allowed to remove the pill above.
--==============================================================================
local scale = Instance.new("UIScale")
scale.Parent = slab

local function reduced(): boolean
	return player:GetAttribute("SeedAfterimageQuality") == "Off"
end

local function animateTo(target: number)
	if reduced() then
		scale.Scale = 1
		return
	end
	local start = scale.Scale
	local began = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - began) / 0.12, 0, 1)
		scale.Scale = start + (target - start) * t
		if t >= 1 and connection then
			connection:Disconnect()
		end
	end)
end

if UserInputService.TouchEnabled then
	slab.MouseButton1Down:Connect(function()
		animateTo(0.94)
	end)
	slab.MouseButton1Up:Connect(function()
		animateTo(1)
	end)
else
	slab.MouseEnter:Connect(function()
		animateTo(1.04)
	end)
	slab.MouseLeave:Connect(function()
		animateTo(1)
	end)
end
