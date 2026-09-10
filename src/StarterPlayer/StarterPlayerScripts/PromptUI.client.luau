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
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
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

--==============================================================================
-- ON TOUCH, THE PANEL IS A ScreenGui BUTTON. NOT A BILLBOARD.
--
-- Three attempts failed before this one, and all three failed the same way: a
-- BillboardGui cannot be made to work as a touch target.
--
--   1. MouseButton1Down/Up on the billboard's button. Never fires from touch.
--   2. BillboardGui.Active = true. Changes nothing.
--   3. Catch the touch globally and hit-test a rectangle projected from the
--      adornee. This is the one that reached the owner, and it was wrong on a
--      real device: the player had to tap BELOW the visible prompt.
--
-- THE MEASURED CAUSE OF THAT VERTICAL OFFSET, because it is worth never
-- repeating. Camera:WorldToViewportPoint returns WINDOW space -- the 3D view
-- fills the whole window, topbar included. InputObject.Position and
-- GuiObject.AbsolutePosition are both reported in BELOW-INSET space. Measured
-- on this place at a 58-pixel inset, against the local character's head:
--
--     WorldToViewportPoint   367, 207     (window space)
--     WorldToScreenPoint     367, 149     (below-inset space, = viewport - 58)
--     a marker drawn at 207 in an IgnoreGuiInset=true ScreenGui
--       reports AbsolutePosition   ... 149 + its own half-height
--
-- The hit test compared a window-space projection against a below-inset touch,
-- so the rectangle sat exactly one inset -- 58 pixels -- below the panel the
-- player could see. Any further offset guess would have been a fourth attempt
-- at the same mistake.
--
-- SO THE ESTIMATE IS GONE. The panel is now a real TextButton in a real
-- ScreenGui, and the thing that is drawn and the thing that is pressed are THE
-- SAME INSTANCE. There is no rectangle to get wrong: if the projection is off,
-- the panel and its hit area are off together, and the player still presses
-- what they can see. That property is the entire point of this change.
--
-- THE COORDINATE CONTRACT, in one line: the layer is IgnoreGuiInset = true and
-- positions come from WorldToViewportPoint, so both are window space and no
-- inset arithmetic appears anywhere. Reads of AbsolutePosition, which is
-- below-inset, are only ever compared against InputObject.Position, which is
-- the same space.
--
-- A DESKTOP WITH NO TOUCHSCREEN KEEPS THE BILLBOARD, unchanged, because it was
-- never broken there -- E has always driven it and a billboard scales with
-- distance, which is the approved look. A touch-capable machine gets the
-- ScreenGui panel, because on one of those the billboard is not usable at all.
--==============================================================================
local TOUCH = UserInputService.TouchEnabled

-- How far above the adornee the panel sits, in studs, projected. The billboard
-- used StudsOffset, which is applied along the CAMERA's axes; this is world up,
-- so it is derivable from the adornee alone and behaves under a tilted camera
-- the way a thing standing on the object would.
local LIFT = Vector3.new(0, 2.4, 0)
local PANEL_SIZE = Vector2.new(170, 52)
-- A finger that travels this far has started panning the camera rather than
-- pressing a prompt.
local TAP_SLOP = 34

-- Used by the landing check below and by the slide-off check further down, so
-- that both ask the question of the SAME rect: the one the panel is really laid
-- out at. AbsolutePosition and InputObject.Position are both below-inset, so
-- there is no conversion here and no place for one to creep back in.
local function within(panel: GuiObject, at: Vector2): boolean
	local a, size = panel.AbsolutePosition, panel.AbsoluteSize
	return at.X >= a.X and at.X <= a.X + size.X
		and at.Y >= a.Y and at.Y <= a.Y + size.Y
end

type Panel = {
	-- The instance to destroy when this prompt goes away: the billboard on a
	-- desktop, the button itself on a touch device.
	root: Instance,
	panel: TextButton,
	adornee: BasePart,
	scale: UIScale?,
	fill: Frame,
	cap: Frame,
	tween: Tween?,
}

local shown: { [ProximityPrompt]: Panel } = {}

-- The prompt a finger is currently holding down, if any. Declared here rather
-- than beside the input handling because `hide` below has to be able to let go
-- of it, and a local referenced before its declaration is silently a GLOBAL --
-- which would read nil in hide and quietly never release.
local holding: ProximityPrompt? = nil
--==============================================================================
-- THE EXACT TOUCH THAT STARTED IT, NOT "A" TOUCH
--
-- Held in full rather than as a boolean so a SECOND finger landing and lifting
-- cannot end the first finger's hold: every touch is its own InputObject and
-- only the one that began the hold is allowed to end it.
--==============================================================================
local activeTouch: InputObject? = nil
local touchStart: Vector2? = nil

--==============================================================================
-- WHERE EACH FINGER LANDED, WHICH IS NOT WHERE THE PANEL FIRST HEARS ABOUT IT
--
-- MEASURED, and it is the whole reason this table exists: GuiObject.InputBegan
-- fires for a touch that ENTERS the button, not only for one that starts on it.
-- A finger that lands on open ground and is dragged across the panel gets a full
-- InputBegan, and before this was recorded that finger started -- and completed
-- -- a hold. On the sell board it sold the bed; on a PICK UP panel, whose hold
-- is zero, one camera pan that happened to sweep the prompt would have lifted
-- the plant instantly. That is the owner's original complaint by another route.
--
-- The transcript that proved it, on a panel occupying y 4..56:
--
--     touch 253,140            <- UserInputService, the real landing point
--     >PANEL saw Touch         <- the panel, ~400ms later, on entry
--     >HOLD SellPrompt
--     >***TRIG SellPrompt
--
-- Note the order. For a finger that genuinely lands ON the panel the two arrive
-- the other way round -- the panel first, UserInputService second -- and that
-- difference is exactly what tells the two apart:
--
--   * no entry in `origin` yet  -> UserInputService has not seen this touch at
--     all, so it is landing right now, on the panel. Allowed.
--   * an entry that is outside  -> it landed somewhere else and was dragged
--     here. Refused.
--
-- Written so it does not CARE which signal arrives first: if the order ever
-- changes, a genuine landing simply takes the second branch and its recorded
-- origin is inside the panel, which is allowed too.
--==============================================================================
local origin: { [InputObject]: Vector2 } = {}

-- A finger gets ONE hold. Once it has had one -- completed, lifted or cancelled
-- by a pan -- re-entering the panel must not hand it another, or a slop cancel
-- becomes a way to start again without ever letting go.
local spent: { [InputObject]: boolean } = {}

--==============================================================================
-- ONE LAYER FOR EVERY PROMPT
--
-- DisplayOrder 15 puts it under the HUD (20), the rail (40) and every panel
-- (30-34), which is deliberate: a prompt is world furniture and anything the
-- player deliberately opened must win the touch. A prompt that ends up behind
-- the hotbar is unreachable, and that is the correct outcome -- the hotbar is
-- what the finger was aimed at.
--==============================================================================
local layer: ScreenGui? = nil
if TOUCH then
	local existing = playerGui:FindFirstChild("SeedPromptLayer")
	if existing then
		existing:Destroy()
	end
	local made = Instance.new("ScreenGui")
	made.Name = "SeedPromptLayer"
	made.ResetOnSpawn = false
	made.IgnoreGuiInset = true
	made.DisplayOrder = 15
	made.Parent = playerGui
	layer = made
end

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
-- ONE PROMPT THAT TOUCH DOES NOT DRAW, AND WHY IT IS THIS ONE
--
-- Every prompt in the game is Style = Custom and drawn here, and on touch the
-- panel IS the button -- which is exactly right for the five prompts a player
-- walks up to and means to press: a nest Take, a hatch, Marigold, a mill, the
-- sell board. Each of those is a deliberate approach to a fixed object.
--
-- A GROWN PLANT IS NOT LIKE THAT, and the owner found the reason on a phone.
-- Its hold is ZERO -- picking your own plant back up should not need a hold, and
-- that was the right call -- but a zero-hold prompt fires on the touch that
-- STARTS the gesture. So a thumb coming down near a plant to swing the camera
-- lifted the plant instead, and no amount of movement cancellation can undo an
-- action that has already happened. Widening the movement threshold only makes
-- the panel harder to press on purpose; moving it only moves the collision.
--
-- The verb was wrong, not the geometry. On touch a plant is now SELECTED by a
-- tap and picked up by a separate button, so the destructive step is never the
-- first half of an ambiguous gesture -- see PlantPickUI, which owns that and
-- drives THIS prompt to do the actual work.
--
-- SO NOTHING IS DRAWN FOR IT HERE, on touch only. The prompt itself stays,
-- enabled and server-backed, because desktop still presses E on it and the
-- server still validates every trigger through it.
--
-- Named rather than inferred: PlantService creates exactly one prompt with this
-- name, the same way `reservedForSomebodyElse` above reads one attribute by
-- name. A structural test would have to reach into the plot tree from here to
-- learn something one string already says.
--==============================================================================
local DRAWN_BY_SOMEBODY_ELSE: { [string]: boolean } = {
	PickupPrompt = true,
}

local function ownedByAnotherUI(prompt: ProximityPrompt): boolean
	return TOUCH and DRAWN_BY_SOMEBODY_ELSE[prompt.Name] == true
end

--==============================================================================
-- THE PANEL
--==============================================================================
local function build(prompt: ProximityPrompt): Panel?
	local adornee = prompt.Parent
	if not (adornee and adornee:IsA("BasePart")) then
		return nil
	end

	--==========================================================================
	-- WHERE THE PANEL LIVES
	--
	-- On touch it is a button in the shared layer, positioned each frame by the
	-- tracker below. On a desktop with no touchscreen it is the billboard it has
	-- always been, untouched -- see the banner on TOUCH for why the two differ.
	--==========================================================================
	local root: Instance
	local scale: UIScale? = nil
	local billboard: BillboardGui? = nil
	if not TOUCH then
		local made = Instance.new("BillboardGui")
		made.Name = "SeedPrompt"
		made.Adornee = adornee
		made.AlwaysOnTop = true
		made.Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y)
		made.StudsOffset = LIFT
	-- MaxDistance IS MEASURED FROM THE CAMERA, while MaxActivationDistance is
	-- measured from the CHARACTER. Setting this to activation + 4 seemed
	-- obviously right and hid the prompt at exactly the moment it became usable:
	-- the character stands 7 studs from the pod and the default third-person
	-- camera sits ~32 behind them. Range is already decided by PromptShown and
	-- PromptHidden, so this only has to be big enough never to be the thing that
	-- hides it.
		made.MaxDistance = 250
		made.Parent = playerGui
		billboard = made
		root = made
	end

	-- A button, not a frame: on touch it IS the hit target, and on a desktop it
	-- is what the click path would need if one is ever added.
	local panel = Instance.new("TextButton")
	panel.Name = "Panel"
	if TOUCH then
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y)
		-- Off screen and invisible until the tracker has placed it, so it can
		-- never appear at 0,0 for the frame before its first update.
		panel.Position = UDim2.fromOffset(-1000, -1000)
		panel.Visible = false
		panel.Parent = layer
		root = panel
		local made = Instance.new("UIScale")
		made.Scale = 1
		made.Parent = panel
		scale = made
	else
		panel.Size = UDim2.fromScale(1, 1)
		panel.Parent = billboard
	end
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.12
	panel.AutoButtonColor = false
	panel.Text = ""
	-- So the fill is cut off by the rounded corners rather than squaring them.
	panel.ClipsDescendants = true

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
	-- THE PANEL TAKES ITS OWN TOUCH
	--
	-- InputBegan on the button itself, which is the native path a ScreenGui
	-- button has always had -- no global listener, no projected rectangle, and
	-- nothing for PickupPrompt to be routed from except a press that landed on
	-- the words PICK UP.
	--
	-- It also gives two behaviours for free that a global handler had to fake:
	-- a touch that BEGINS outside and slides on does not start a hold, because
	-- InputBegan only fires for a touch that starts inside; and the top and
	-- bottom edges are live to exactly the pixel the panel is drawn to.
	--
	-- TOUCH ONLY. A desktop mouse has never operated this panel -- E does -- and
	-- silently adding a click here would be a behaviour change nobody asked for.
	--==========================================================================
	if TOUCH then
		panel.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			-- One hold at a time, and the first finger owns it.
			if holding or activeTouch then
				return
			end
			-- This finger has already had its hold; entering again is not a new
			-- press.
			if spent[input] then
				return
			end
			-- AND IT MUST HAVE LANDED HERE. See the banner on `origin`: an entry
			-- that is outside this panel means the engine is telling us about a
			-- finger that came from somewhere else, which is a drag across the
			-- prompt and not a press of it.
			local from = origin[input]
			if from and not within(panel, from) then
				return
			end
			holding = prompt
			activeTouch = input
			spent[input] = true
			touchStart = Vector2.new(input.Position.X, input.Position.Y)
			prompt:InputHoldBegin()
		end)
	end

	if scale then
		scale.Scale = 0.82
		TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back,
			Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		panel.Size = UDim2.fromScale(0.82, 0.82)
		TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Back,
			Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()
	end

	return {
		root = root,
		panel = panel,
		adornee = adornee,
		scale = scale,
		fill = fill,
		cap = cap,
		tween = nil,
	}
end

--==============================================================================
-- LETTING GO
--
-- Every route out of a hold funnels here: the finger lifting, the finger
-- wandering off the button, the camera being panned, the prompt going away,
-- the character dying. A hold that only the happy path released would be a
-- prompt stuck lit with a fill bar frozen part way across it.
--==============================================================================
local function release()
	local prompt = holding
	holding = nil
	activeTouch = nil
	touchStart = nil
	if prompt then
		-- pcall because the prompt may have been destroyed under us.
		pcall(function()
			prompt:InputHoldEnd()
		end)
	end
end

local function hide(prompt: ProximityPrompt)
	local entry = shown[prompt]
	shown[prompt] = nil
	-- Walking out of range mid-hold: the prompt is going away and the hold it
	-- was carrying has to go with it, or the next tap finds `holding` occupied
	-- by something that is no longer on screen.
	if holding == prompt then
		release()
	end
	if not entry then
		return
	end
	if entry.tween then
		entry.tween:Cancel()
	end
	-- Out of the tracker's reach the moment it starts leaving, so a panel in its
	-- shrink cannot be re-placed on top of the object it is fading off.
	entry.panel.Active = false
	if entry.scale then
		TweenService:Create(entry.scale, TweenInfo.new(0.10), { Scale = 0.8 }):Play()
		TweenService:Create(entry.panel, TweenInfo.new(0.10),
			{ BackgroundTransparency = 1 }):Play()
	else
		TweenService:Create(entry.panel, TweenInfo.new(0.10), {
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundTransparency = 1,
		}):Play()
	end
	task.delay(0.12, function()
		entry.root:Destroy()
	end)
end

local function show(prompt: ProximityPrompt)
	if shown[prompt] or carrying() or reservedForSomebodyElse(prompt)
		or ownedByAnotherUI(prompt) then
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
-- FOLLOWING THE WORLD, ONCE PER FRAME FOR EVERY PROMPT
--
-- One BindToRenderStep for the whole set rather than a connection per prompt:
-- there are rarely more than two shown, but a per-prompt binding is a leak
-- waiting for the first time one is destroyed without being unbound.
--
-- Bound just after the camera so the panel is placed against the camera's
-- FINAL position for the frame. Placing it before the camera moves is how a
-- prompt ends up trailing the object it belongs to while you turn.
--
-- COORDINATES: the layer is IgnoreGuiInset = true and this is
-- WorldToViewportPoint, both window space. See the banner at the top of the
-- file for why mixing that with below-inset space is what broke the last
-- attempt.
--==============================================================================
if TOUCH then
	RunService:BindToRenderStep("SeedPromptTrack",
		Enum.RenderPriority.Camera.Value + 1, function()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		local inset = GuiService:GetGuiInset()
		for _, entry in pairs(shown) do
			local adornee = entry.adornee
			if not (adornee and adornee.Parent) then
				entry.panel.Visible = false
				continue
			end
			local at, inFront = camera:WorldToViewportPoint(adornee.Position + LIFT)
			local half = PANEL_SIZE * 0.5
			-- Behind the lens still returns an X and a Y, on the wrong side of
			-- the screen, so `inFront` has to be the first question.
			local onScreen = inFront
				and at.X > -half.X and at.X < viewport.X + half.X
				and at.Y > -half.Y and at.Y < viewport.Y + half.Y
			entry.panel.Visible = onScreen
			if onScreen then
				-- Kept clear of the topbar and the notch it stands in. A panel
				-- drawn under either is one the finger cannot reach, and the
				-- layer ignores the inset precisely so this is our decision
				-- rather than a clip.
				local y = math.max(at.Y, inset.Y + half.Y + 4)
				entry.panel.Position = UDim2.fromOffset(math.round(at.X), math.round(y))
			end
		end
	end)

	--==========================================================================
	-- AND THE HOLD IS RELEASED BY EVERYTHING THAT SHOULD END IT
	--
	-- Both listen for the ONE InputObject that began the hold. A second finger
	-- landing and lifting anywhere on the glass is a different InputObject and
	-- is ignored, which is the difference between a hold that survives a stray
	-- thumb and one that does not.
	--==========================================================================
	-- Fires exactly once per gesture, at the point the finger actually touched
	-- the glass. Recorded for EVERY touch, not only ones near a prompt, because
	-- at this moment we do not yet know which panel it may later be dragged over.
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			origin[input] = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == activeTouch then
			release()
		end
		-- The finger is off the glass and its InputObject will never be seen
		-- again, so neither table should keep holding it.
		if input.UserInputType == Enum.UserInputType.Touch then
			origin[input] = nil
			spent[input] = nil
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input ~= activeTouch or not touchStart then
			return
		end
		local at = Vector2.new(input.Position.X, input.Position.Y)
		-- Panning the camera.
		if (at - touchStart).Magnitude > TAP_SLOP then
			release()
			return
		end
		-- Or simply sliding off the button. AbsolutePosition and
		-- InputObject.Position are both below-inset, so this comparison needs no
		-- conversion -- unlike a projection, which is why this reads the real
		-- laid-out rect instead of computing one.
		local entry = if holding then shown[holding] else nil
		if entry and not within(entry.panel, at) then
			release()
		end
	end)
end

--==============================================================================
-- A BODY THAT GOES AWAY TAKES THE HOLD WITH IT
--==============================================================================
player.CharacterRemoving:Connect(release)
player.CharacterAdded:Connect(release)

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
