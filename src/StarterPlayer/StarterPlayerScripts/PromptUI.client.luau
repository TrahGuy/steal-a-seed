--!strict
-- Steal a Seed :: PromptUI
--
-- Draws every ProximityPrompt in the game. The server sets Style = Custom,
-- which makes Roblox render nothing at all and hand the client the events
-- instead -- so the look is entirely ours and there is no default chrome to
-- fight with.
--
--==============================================================================
-- IT SHOWS A KEY, A VERB, AND HOW FAR THROUGH THE HOLD YOU ARE
--
-- No rarity, no weight, no object name. The pod's colour IS its rarity and its
-- size is its weight, so repeating either in text would be a caption on a
-- photograph.
--
-- The FILL is not decoration. Taking a pod is a hold, and a hold with no
-- feedback is indistinguishable from a broken button -- the player presses,
-- nothing happens, they let go. The bar is the only thing that says "keep
-- holding", and it is the reason the hold can be long enough to matter.
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- The attribute name comes from GameConfig so the client and the server cannot
-- drift onto two spellings of the same fact.
local GameConfig = require(ReplicatedStorage:WaitForChild("SeedGame")
	:WaitForChild("Shared"):WaitForChild("GameConfig"))
local CARRYING = GameConfig.Attributes.CarryingSpecies
-- Set by CarryService on a beginner's reserved pod, and on nothing else.
local RESERVED_FOR = "ReservedFor"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
--==============================================================================
-- THE VERB IS A BUTTON, AND IT LOOKS LIKE ONE NOW
--
-- The key cap and the verb were GothamBold in paper -- the same type as the HUD
-- and, until this pass, the same as the pod label floating a stud above them.
-- Three different things in one typeface is three things that read as one.
-- See GameConfig.Labels.Prompt.
--==============================================================================
local PROMPT = GameConfig.Labels.Prompt

type Panel = {
	billboard: BillboardGui,
	fill: Frame,
	cap: Frame,
	tween: Tween?,
}

local shown: { [ProximityPrompt]: Panel } = {}

-- The prompt a finger is currently holding down, if any. Declared here rather
-- than beside THE TAP because `hide` below has to be able to let go of it, and a
-- local referenced before its declaration is silently a GLOBAL -- which would
-- read nil in hide and quietly never release.
local holding: ProximityPrompt? = nil

--==============================================================================
-- SOMEBODY ELSE'S POD DOES NOT OFFER ITSELF
--
-- A reserved beginner pod carries a ReservedFor attribute naming its owner, and
-- attributes replicate, so this is answerable locally with no remote. Everyone
-- can still SEE the pod -- it is a server-built model and hiding it per player
-- is not something this architecture does cleanly -- but only its owner is
-- offered the verb.
--
-- COURTESY, NOT ENFORCEMENT, exactly as the note at the top of this file says
-- about the carrying check. CarryService.TryTake refuses a stranger's take
-- whether or not this ran, and a forged trigger arrives there like any other.
--==============================================================================
local function reservedForSomebodyElse(prompt: ProximityPrompt): boolean
	local pod = prompt.Parent and prompt.Parent.Parent
	if not (pod and pod:IsA("Model")) then
		return false
	end
	local owner = tonumber(pod:GetAttribute(RESERVED_FOR))
	return owner ~= nil and owner ~= player.UserId
end

local function carrying(): boolean
	return player:GetAttribute(CARRYING) ~= nil
end

--==============================================================================
-- THE PANEL
--==============================================================================
local function build(prompt: ProximityPrompt): Panel?
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
	-- MaxDistance IS MEASURED FROM THE CAMERA, while MaxActivationDistance is
	-- measured from the CHARACTER. Setting this to activation + 4 seemed
	-- obviously right and hid the prompt at exactly the moment it became usable:
	-- the character stands 7 studs from the pod and the default third-person
	-- camera sits ~32 behind them. Range is already decided by PromptShown and
	-- PromptHidden, so this only has to be big enough never to be the thing that
	-- hides it.
	billboard.MaxDistance = 250
	billboard.Parent = playerGui

	-- A button, not a frame, because touch has no E key and the repo rule is
	-- mobile first.
	local panel = Instance.new("TextButton")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.12
	panel.AutoButtonColor = false
	panel.Text = ""
	-- So the fill is cut off by the rounded corners rather than squaring them.
	panel.ClipsDescendants = true
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = panel

	--== THE HOLD FILL ==--
	-- Its own layer under the content, sized in scale, so it sweeps the whole
	-- panel rather than sitting in the layout with the labels.
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = ACCENT
	fill.BackgroundTransparency = 0.55
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.ZIndex = 1
	fill.Parent = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.ZIndex = 2
	content.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = content

	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.Padding = UDim.new(0, 10)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = content

	--== THE KEY CAP ==--
	local cap = Instance.new("Frame")
	cap.Name = "KeyCap"
	cap.LayoutOrder = 1
	cap.Size = UDim2.fromOffset(34, 34)
	cap.BackgroundColor3 = PAPER
	cap.ZIndex = 3
	cap.Parent = content
	local capCorner = Instance.new("UICorner")
	capCorner.CornerRadius = UDim.new(0, 8)
	capCorner.Parent = cap

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromScale(1, 1)
	key.BackgroundTransparency = 1
	key.Font = PROMPT.Font
	key.TextSize = PROMPT.KeySize
	key.TextColor3 = PROMPT.Key
	key.ZIndex = 4
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
	action.Font = PROMPT.Font
	action.TextSize = PROMPT.VerbSize
	action.TextColor3 = PROMPT.Verb
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.ZIndex = 3
	--==========================================================================
	-- UPPERCASED HERE, NOT AT THE FOUR PLACES THAT SET IT
	--
	-- ActionText stays "Pick Up" on the prompt, because that is what the action
	-- is called. How loudly it is said is this file's business -- a service
	-- should not have to shout in its own data to be drawn correctly, and the
	-- day somebody adds a fifth prompt they should not have to know.
	--==========================================================================
	local verb = if prompt.ActionText ~= "" then prompt.ActionText else "Use"
	action.Text = if PROMPT.Uppercase then string.upper(verb) else verb
	action.Parent = content

	local verbEdge = Instance.new("UIStroke")
	verbEdge.Color = PROMPT.Outline
	verbEdge.Thickness = PROMPT.OutlineThickness
	verbEdge.Parent = action

	--==========================================================================
	-- THE TOUCH IS NOT HANDLED HERE, AND THAT IS THE FIX
	--
	-- This used to hang MouseButton1Down/Up and MouseLeave on this panel, and
	-- ON A PHONE NONE OF THEM EVER FIRED. The panel lives in a BillboardGui, and
	-- a BillboardGui's buttons do not take part in touch hit-testing the way a
	-- ScreenGui's do -- setting `Active = true` on the billboard does not change
	-- it either, which was tried.
	--
	-- Measured, two taps a few pixels apart on the same frozen camera:
	--
	--     on the prompt panel        GLOBAL:Touch(processed=false), panel silent
	--     on a plain ScreenGui button GLOBAL:Touch(processed=true), button fired
	--
	-- `processed = false` is the whole story: no GUI consumed the tap. Nobody
	-- noticed because a desktop presses E, and E is the only reason this prompt
	-- has ever worked.
	--
	-- So the tap is caught globally and hit-tested against where this panel is
	-- actually drawn -- see THE TAP below. It is deliberately NOT solved by
	-- offering a keyboard affordance on mobile.
	--==========================================================================

	panel.Size = UDim2.fromScale(0.82, 0.82)
	TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()

	return { billboard = billboard, fill = fill, cap = cap, tween = nil }
end

local function hide(prompt: ProximityPrompt)
	local entry = shown[prompt]
	shown[prompt] = nil
	-- Walking out of range mid-hold: the prompt is going away and the hold it
	-- was carrying has to go with it, or the next tap finds `holding` occupied
	-- by something that is no longer on screen.
	if holding == prompt then
		holding = nil
		pcall(function()
			prompt:InputHoldEnd()
		end)
	end
	if not entry then
		return
	end
	if entry.tween then
		entry.tween:Cancel()
	end
	local panel = entry.billboard:FindFirstChild("Panel")
	if panel and panel:IsA("GuiObject") then
		TweenService:Create(panel, TweenInfo.new(0.10), {
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundTransparency = 1,
		}):Play()
	end
	task.delay(0.12, function()
		entry.billboard:Destroy()
	end)
end

local function show(prompt: ProximityPrompt)
	if shown[prompt] or carrying() or reservedForSomebodyElse(prompt) then
		return
	end
	local entry = build(prompt)
	if entry then
		shown[prompt] = entry
	end
end

--==============================================================================
-- THE HOLD
--==============================================================================
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	local entry = shown[prompt]
	if not entry then
		return
	end
	if entry.tween then
		entry.tween:Cancel()
	end
	-- Linear, and exactly the prompt's own HoldDuration. A bar that eases would
	-- be lying about how much longer to hold, which is the one thing it is for.
	entry.tween = TweenService:Create(entry.fill,
		TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromScale(1, 1) })
	entry.tween:Play()
	TweenService:Create(entry.cap, TweenInfo.new(0.10),
		{ BackgroundColor3 = ACCENT }):Play()
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
	local entry = shown[prompt]
	if not entry then
		return
	end
	if entry.tween then
		entry.tween:Cancel()
		entry.tween = nil
	end
	-- Snap back rather than drain. Letting go should read as cancelled, and a
	-- bar that empties slowly reads as still doing something.
	TweenService:Create(entry.fill, TweenInfo.new(0.12),
		{ Size = UDim2.fromScale(0, 1) }):Play()
	TweenService:Create(entry.cap, TweenInfo.new(0.12),
		{ BackgroundColor3 = PAPER }):Play()
end)

--==============================================================================
-- THE TAP
--
-- One pair of connections for the whole game rather than a pair per prompt.
--
-- IT DOES NOT HIT-TEST THE PANEL, AND THAT IS DELIBERATE. The first attempt did:
-- project the adornee, build a rect from the panel's AbsoluteSize, require the
-- touch inside it. It did not work, and the reason is that a BillboardGui is not
-- laid out in screen space at all -- its children report AbsolutePosition 0,0,
-- and StudsOffset is applied relative to the CAMERA rather than the world, so a
-- projected rect is an approximation that was measurably in the wrong place.
--
-- Trying to be precise about where a billboard is drawn is the wrong problem.
-- A prompt only appears when the player is within MaxActivationDistance of the
-- thing -- eleven studs for a pod, and PromptShown/PromptHidden already own that
-- decision. If a prompt is on screen at all, the player is standing at it.
--
-- SO: A TAP WHILE A PROMPT IS SHOWN IS THAT PROMPT. Position is used only to
-- choose between two prompts that are somehow both up, and even then it is a
-- nearest-to-the-finger guess rather than a containment test.
--
-- A DRAG IS NOT A TAP. The camera is panned by dragging, so a touch that travels
-- is the player looking around and must not hold a prompt down. That is the one
-- thing this has to get right, and it is a distance check rather than a rect.
--==============================================================================
local TAP_SLOP = 34

local touchStart: Vector2? = nil

local function anyShown(point: Vector2?): ProximityPrompt?
	local camera = Workspace.CurrentCamera
	local best, bestDist = nil, math.huge
	for prompt, entry in pairs(shown) do
		local adornee = entry.billboard.Adornee
		if adornee and adornee:IsA("BasePart") then
			if not point or not camera then
				return prompt
			end
			local at, inFront = camera:WorldToViewportPoint(adornee.Position)
			-- Behind the lens is not a candidate: WorldToViewportPoint still
			-- hands back an X and a Y for it, on the wrong side of the screen.
			local d = if inFront
				then (Vector2.new(at.X, at.Y) - point).Magnitude
				else math.huge
			if d < bestDist then
				best, bestDist = prompt, d
			end
		end
	end
	return best
end

local function release()
	if holding then
		holding:InputHoldEnd()
		holding = nil
	end
	touchStart = nil
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- `processed` means a real GUI took it -- a rail button, a card, the jump
	-- button. Those sit above the world and they win.
	if processed or input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if holding then
		return
	end
	local prompt = anyShown(Vector2.new(input.Position.X, input.Position.Y))
	if prompt then
		touchStart = Vector2.new(input.Position.X, input.Position.Y)
		holding = prompt
		-- With HoldDuration 0 this triggers on the press, which is what "no
		-- hold" means; with a hold it starts the bar and the lift below ends it.
		prompt:InputHoldBegin()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		release()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not (holding and touchStart) or input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if (at - touchStart).Magnitude > TAP_SLOP then
		-- The finger is panning the camera, not pressing a prompt.
		release()
	end
end)

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
player:GetAttributeChangedSignal(CARRYING):Connect(function()
	if carrying() then
		for prompt in pairs(shown) do
			hide(prompt)
		end
	end
end)
