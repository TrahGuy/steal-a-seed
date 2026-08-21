--!strict
-- Steal a Seed :: PromptUI
--
-- Draws every ProximityPrompt in the game. The server sets Style = Custom,
-- which makes Roblox render nothing at all and hand the client the event
-- instead -- so the look is entirely ours and there is no default chrome to
-- fight with.
--
--==============================================================================
-- IT SHOWS A KEY AND A VERB. NOTHING ELSE.
--
-- No rarity, no weight, no object name. A prompt appears when you are close
-- enough to do a thing and it says what the thing is; everything else about the
-- pod is already visible in the pod -- its colour IS its rarity, and its size is
-- its weight. Repeating that in text would be a caption on a photograph.
--
--==============================================================================
-- IT HIDES WHILE YOU ARE CARRYING
--
-- Read off the CarryingSpecies attribute the server sets on the Player, because
-- attributes replicate on their own: no remote, no round trip, and the answer is
-- already local by the time a prompt wants to draw itself.
--
-- The server refuses the take as well. Hiding the prompt is a courtesy so the
-- player is not offered something that cannot happen; the refusal is the rule.
--==============================================================================

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)

local shown: { [ProximityPrompt]: BillboardGui } = {}

local function carrying(): boolean
	return player:GetAttribute("CarryingSpecies") ~= nil
end

--==============================================================================
-- THE PANEL
--==============================================================================
local function build(prompt: ProximityPrompt): BillboardGui?
	local adornee = prompt.Parent
	if not (adornee and adornee:IsA("BasePart")) then
		return nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SeedPrompt"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(170, 52)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	-- MaxDistance IS MEASURED FROM THE CAMERA, not from the character, while
	-- MaxActivationDistance is measured from the character. Setting this to
	-- activation + 4 seemed obviously right and hid the prompt at exactly the
	-- moment it became usable: the player stands 7 studs from the pod, the
	-- default third-person camera sits ~20 studs behind them, and 20 > 11 + 4.
	--
	-- Range is already decided by PromptShown and PromptHidden, so this only has
	-- to be large enough never to be the thing that hides it.
	billboard.MaxDistance = 250
	billboard.Parent = playerGui

	-- A button, not a frame, because touch has no E key and the repo rule is
	-- mobile first. On desktop it is simply never clicked.
	local panel = Instance.new("TextButton")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.12
	panel.AutoButtonColor = false
	panel.Text = ""
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = panel

	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.Padding = UDim.new(0, 10)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = panel

	--== THE KEY CAP ==--
	local cap = Instance.new("Frame")
	cap.Name = "KeyCap"
	cap.LayoutOrder = 1
	cap.Size = UDim2.fromOffset(34, 34)
	cap.BackgroundColor3 = PAPER
	cap.Parent = panel
	local capCorner = Instance.new("UICorner")
	capCorner.CornerRadius = UDim.new(0, 8)
	capCorner.Parent = cap

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromScale(1, 1)
	key.BackgroundTransparency = 1
	key.Font = Enum.Font.GothamBold
	key.TextSize = 19
	key.TextColor3 = INK
	-- The bound key, not a hardcoded letter: rebinding the prompt should not
	-- leave the UI lying about which key does it.
	key.Text = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		then "TAP"
		else prompt.KeyboardKeyCode.Name
	key.Parent = cap

	--== THE VERB ==--
	local action = Instance.new("TextLabel")
	action.Name = "Action"
	action.LayoutOrder = 2
	action.Size = UDim2.fromOffset(80, 34)
	action.BackgroundTransparency = 1
	action.Font = Enum.Font.GothamBold
	action.TextSize = 20
	action.TextColor3 = PAPER
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Text = if prompt.ActionText ~= "" then prompt.ActionText else "Use"
	action.Parent = panel

	panel.Activated:Connect(function()
		prompt:InputHoldBegin()
		task.wait()
		prompt:InputHoldEnd()
	end)

	-- Pop in. Scaled from slightly small rather than faded from nothing: a
	-- prompt that grows reads as something arriving, and at this size a fade is
	-- almost invisible anyway.
	panel.Size = UDim2.fromScale(0.82, 0.82)
	TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()

	return billboard
end

local function hide(prompt: ProximityPrompt)
	local billboard = shown[prompt]
	shown[prompt] = nil
	if not billboard then
		return
	end
	local panel = billboard:FindFirstChild("Panel")
	if panel and panel:IsA("GuiObject") then
		TweenService:Create(panel, TweenInfo.new(0.10), {
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundTransparency = 1,
		}):Play()
	end
	task.delay(0.12, function()
		billboard:Destroy()
	end)
end

local function show(prompt: ProximityPrompt)
	if shown[prompt] or carrying() then
		return
	end
	local billboard = build(prompt)
	if billboard then
		shown[prompt] = billboard
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Style == Enum.ProximityPromptStyle.Custom then
		show(prompt)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	hide(prompt)
end)

-- Picking something up must take the prompt away in the same frame, or the
-- player is left looking at an offer the server has already refused.
player:GetAttributeChangedSignal("CarryingSpecies"):Connect(function()
	if carrying() then
		for prompt in pairs(shown) do
			hide(prompt)
		end
	end
end)
