--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperUI (2026-10-11, Enchanted Mist stage 3)
--
-- MOSSKEEPER'S DIALOGUE (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §8):
-- after the player taps E -- Talk (the server's "open"), the camera frames his
-- face and upper body and a compact studded panel opens: his line (active or
-- waiting), what the player carries, their saved progress, the Mist's state,
-- and GIVE ALL DEWBERRIES / ODDS / HOW TO PLAY / CLOSE. Give all is disabled
-- while no Mist runs (the server refuses it then too); Odds and How to play
-- always work. The numbers shown are the server's (the player's attributes);
-- a Give all sends no amount -- the server decides everything.
--
-- THE CAMERA, borrowed and given back: taken only if it is the default camera
-- on this player's own Humanoid (no other owner, no VR), marked with
-- CAMERA_MARK, held each frame after the engine's camera step; given back
-- (Custom, this body's Humanoid) only while the mark is still ours and it is
-- still Scriptable -- a newer owner's state is never overwritten. Closed by
-- Close, Back/Escape/B, walking past CloseDistance, death, respawn, him going,
-- another panel opening or the Roblox menu. Reduced motion cuts instead of
-- easing. Nothing forced: only a Talk the player chose opens it.
--==============================================================================
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MosskeeperModel = require(Shared:WaitForChild("MosskeeperModel"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))

local CFG = EnchantedMistConfig.Mosskeeper
local W = CFG.Words
local PA = EnchantedMistConfig.PlayerAttributes
local LOOK = GameConfig.BagLook
local ATTR = GameConfig.Attributes
local CAP = EnchantedMistData.CarryCap
local PER_POD = EnchantedMistData.BerriesPerPod
local PANEL = "Mosskeeper"
local BACK_ACTION = "SeedMosskeeperBack"
local CAMERA_STEP = "SeedMosskeeperCamera"
local CAMERA_MARK = "SeedMosskeeperCamera"
local WARN_TEXT = Color3.fromRGB(176, 52, 40)
-- How long a sent Give all waits for its answer.
local PATIENCE = 6

local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedMosskeeper")
if existing then
	existing:Destroy()
end
player:SetAttribute(CFG.TalkingAttribute, nil)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedMosskeeper"
gui.ResetOnSpawn = false
-- Beside Marigold's shop (34), under SELL ONE (36) and the RUN alarm (50).
gui.DisplayOrder = 35
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local modal = UIKit.modal(gui, {
	name = "Mosskeeper",
	title = W.Title,
	maxWidth = 400,
	maxHeight = 430,
	-- The studded kit over the whole panel (the owner: never a flat plate).
	theme = MenuKit.studdedTheme(CFG.Look),
	titleColour = GameConfig.StuddedLook.Title,
	stillWhenReduced = true,
})
modal.followMenuSize()

--==============================================================================
-- THE PAGES: his words, the odds (MistOddsView fills its page), how to play
--==============================================================================
local GAP, MARGIN = 6, 16

local function fitText(label: TextLabel, maxSize: number)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = 9
	limit.Parent = label
end

local function page(name: string): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.ZIndex = 3
	f.Visible = false
	f.Parent = modal.body
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = f
	return f
end

local function line(parent: Instance, name: string, order: number, height: number, size: number, colour: Color3,
	body: boolean?): TextLabel
	local label = if body then MenuKit.body(parent, name, size, colour, 4) else MenuKit.text(parent, name, size, colour, 4)
	label.Size = UDim2.new(1, -8, 0, height)
	label.LayoutOrder = order
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 4
	fitText(label, size)
	return label
end

local function row(parent: Instance, name: string, order: number, height: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.new(1, -8, 0, height)
	f.BackgroundTransparency = 1
	f.LayoutOrder = order
	f.ZIndex = 4
	f.Parent = parent
	return f
end

type Button = { hit: TextButton, style: (string) -> () }

local function button(parent: Instance, name: string, text: string, face: string, anchorX: number,
	width: UDim2): Button
	local made = MenuKit.button(parent, name, 5, text, 18)
	made.style(face)
	local b = made.hit
	b.AnchorPoint = Vector2.new(anchorX, 0.5)
	b.Position = UDim2.new(anchorX, 0, 0.5, 0)
	b.Size = width
	UIKit.clicks(b)
	return { hit = b, style = made.style }
end

-- His words and the player's numbers.
local main = page("MainPage")
local saying = line(main, "Line", 1, 54, 17, LOOK.Text, true)
local carryingLabel = line(main, "Carrying", 2, 20, 16, LOOK.Text)
local progressLabel = line(main, "Progress", 3, 20, 16, LOOK.Text)
local mistLabel = line(main, "Mist", 4, 18, 14, LOOK.Muted, true)
local answerLabel = line(main, "Answer", 5, 20, 15, LOOK.Money)
local giveRow = row(main, "GiveRow", 6, 46)
local give = button(giveRow, "GiveAll", W.GiveAll, "go", 0.5, UDim2.new(1, 0, 0, 46))
local moreRow = row(main, "MoreRow", 7, 42)
local oddsButton = button(moreRow, "Odds", W.Odds, "sky", 0, UDim2.new(0.5, -4, 0, 42))
local howButton = button(moreRow, "HowTo", W.HowTo, "sky", 1, UDim2.new(0.5, -4, 0, 42))
local closeRow = row(main, "CloseRow", 8, 40)
local closeButton = button(closeRow, "Close", W.Close, "idle", 0.5, UDim2.new(1, 0, 0, 40))
local MAIN_HEIGHT = 54 + 20 + 20 + 18 + 20 + 46 + 42 + 40 + GAP * 7 + MARGIN

-- The odds: a holder MistOddsView fills with its cards, and the way back.
local oddsPage = page("OddsPage")
local oddsHolder = row(oddsPage, "Cards", 1, 0)
local oddsBack = button(row(oddsPage, "BackRow", 2, 42), "OddsBack", W.Back, "sky", 0.5, UDim2.new(1, 0, 0, 42))
local oddsView = MistOddsView.build(oddsHolder, 5)
oddsHolder.Size = UDim2.new(1, -8, 0, math.min(oddsView.height, CFG.Odds.ViewHeight))
local oddsHeight = 42 + GAP + MARGIN

-- How to play.
local howPage = page("HowToPage")
local howHeight = 0
for i, text in ipairs(W.HowToLines) do
	local l = line(howPage, "Line" .. i, i, 40, 15, LOOK.Text, true)
	l.Text = text
	howHeight += 40 + GAP
end
local howBack = button(row(howPage, "BackRow", #W.HowToLines + 1, 42), "HowToBack", W.Back, "sky", 0.5,
	UDim2.new(1, 0, 0, 42))
howHeight += 42 + MARGIN

-- Where a controller's selection starts (PadFocus reads it).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Value = give.hit
padFirst.Parent = modal.shell

local shown = "Main"
local function showPage(name: string)
	shown = name
	main.Visible = name == "Main"
	oddsPage.Visible = name == "Odds"
	howPage.Visible = name == "HowTo"
	oddsView.setShown(name == "Odds")
	padFirst.Value = if name == "Odds" then oddsBack.hit elseif name == "HowTo" then howBack.hit else give.hit
	modal.fitContent(if name == "Odds" then oddsHeight + oddsHolder.Size.Y.Offset
		elseif name == "HowTo" then howHeight else MAIN_HEIGHT)
end

--==============================================================================
-- THE NUMBERS (the server's, on this player)
--==============================================================================
local pending: number? = nil

local function mistActive(): boolean
	return Workspace:GetAttribute(EnchantedMistConfig.Attributes.State) == EnchantedMistConfig.States.Active
end

local function count(name: string, most: number): number
	return math.clamp(math.floor(tonumber(player:GetAttribute(name)) or 0), 0, most)
end

local function refresh()
	local active = mistActive()
	local carried = count(PA.Carried, CAP)
	saying.Text = if active then CFG.Lines.Active else CFG.Lines.Inactive
	carryingLabel.Text = string.format(W.Carrying, carried, CAP)
	progressLabel.Text = string.format(W.Progress, count(PA.Progress, PER_POD - 1), PER_POD)
	mistLabel.Text = if active then W.MistActive else W.MistWaiting
	local can = active and carried > 0 and pending == nil
	give.style(if can then "go" else "off")
	give.hit.Active = can
end

--==============================================================================
-- THE CAMERA
--==============================================================================
local held: { subject: Instance? }? = nil
local framing: { from: CFrame, started: number, reduced: boolean }? = nil

local function npcModel(): Model?
	local folder = Workspace:FindFirstChild(CFG.FolderName)
	local model = folder and folder:FindFirstChild("Mosskeeper")
	return if model and model:IsA("Model") then model else nil
end

local function myHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- His face and upper body, from a little in front of him and to one side, so
-- the panel in the middle of the screen leaves him in view.
local function frameFor(model: Model): CFrame
	local pivot = model:GetPivot()
	local eye = pivot * Vector3.new(-1.2, 4.6, -7.4)
	local target = pivot * Vector3.new(1.6, 3.9, 0)
	return CFrame.lookAt(eye, target)
end

local function releaseCamera()
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	framing = nil
	local was = held
	held = nil
	local camera = Workspace.CurrentCamera
	if not (was and camera) or camera:GetAttribute(CAMERA_MARK) ~= true then
		-- Never ours, or a newer owner has it: theirs to keep.
		return
	end
	camera:SetAttribute(CAMERA_MARK, nil)
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = myHumanoid()
		local subject = was.subject
		if humanoid and humanoid.Health > 0 then
			camera.CameraSubject = humanoid
		elseif subject and subject:IsDescendantOf(Workspace) then
			camera.CameraSubject = subject
		end
	end
end

local function takeCamera(model: Model)
	local camera = Workspace.CurrentCamera
	local humanoid = myHumanoid()
	if held or not (camera and humanoid) then
		return
	end
	-- Only the default camera on this player's own body; anything else has an owner.
	if camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= humanoid or VRService.VREnabled then
		return
	end
	held = { subject = camera.CameraSubject }
	camera:SetAttribute(CAMERA_MARK, true)
	camera.CameraType = Enum.CameraType.Scriptable
	framing = { from = camera.CFrame, started = os.clock(), reduced = StatusText.reducedMotion() }
	-- After the engine's own camera step, which would otherwise win the first frame.
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, function()
		local cam = Workspace.CurrentCamera
		local f = framing
		if not (cam and f) then
			return
		end
		if cam:GetAttribute(CAMERA_MARK) ~= true or cam.CameraType ~= Enum.CameraType.Scriptable then
			-- Somebody else took it: stop holding, give nothing back over theirs.
			RunService:UnbindFromRenderStep(CAMERA_STEP)
			framing = nil
			held = nil
			return
		end
		local still = npcModel()
		if not still then
			return
		end
		local goal = frameFor(still)
		if f.reduced then
			cam.CFrame = goal
		else
			local u = math.clamp((os.clock() - f.started) / 0.6, 0, 1)
			u = u * u * (3 - 2 * u)
			cam.CFrame = f.from:Lerp(goal, u)
		end
	end)
end

--==============================================================================
-- OPEN AND CLOSE
--==============================================================================
local isOpen = false
local closers: { RBXScriptConnection } = {}

local function setOpen(want: boolean)
	if want == isOpen then
		return
	end
	isOpen = want
	for _, c in ipairs(closers) do
		c:Disconnect()
	end
	table.clear(closers)
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL)
		player:SetAttribute(CFG.TalkingAttribute, true)
		pending = nil
		answerLabel.Text = ""
		showPage("Main")
		refresh()
		modal.setOpen(true)
		local model = npcModel()
		if model then
			takeCamera(model)
		end
		ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state)
			if state == Enum.UserInputState.Begin then
				if shown ~= "Main" then
					showPage("Main")
				else
					setOpen(false)
				end
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
		-- Walking away, him going, death and respawn all close it.
		table.insert(closers, RunService.Heartbeat:Connect(function()
			local still = npcModel()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local plate = still and still:FindFirstChild(MosskeeperModel.PromptPart)
			if not (still and root and root:IsA("BasePart") and plate and plate:IsA("BasePart"))
				or (root.Position - plate.Position).Magnitude > CFG.CloseDistance then
				setOpen(false)
				return
			end
			if pending and os.clock() - pending > PATIENCE then
				pending = nil
				refresh()
			end
		end))
		local humanoid = myHumanoid()
		if humanoid then
			table.insert(closers, humanoid.Died:Connect(function()
				setOpen(false)
			end))
		end
		table.insert(closers, player.CharacterRemoving:Connect(function()
			setOpen(false)
		end))
	else
		ContextActionService:UnbindAction(BACK_ACTION)
		oddsView.setShown(false)
		modal.setOpen(false)
		releaseCamera()
		player:SetAttribute(CFG.TalkingAttribute, nil)
		if player:GetAttribute(ATTR.OpenPanel) == PANEL then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
	end
end

closeButton.hit.Activated:Connect(function()
	setOpen(false)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)
GuiService.MenuOpened:Connect(function()
	setOpen(false)
end)
oddsButton.hit.Activated:Connect(function()
	showPage("Odds")
end)
howButton.hit.Activated:Connect(function()
	showPage("HowTo")
end)
oddsBack.hit.Activated:Connect(function()
	showPage("Main")
end)
howBack.hit.Activated:Connect(function()
	showPage("Main")
end)
give.hit.Activated:Connect(function()
	if not give.hit.Active or pending then
		return
	end
	pending = os.clock()
	answerLabel.TextColor3 = LOOK.Muted
	answerLabel.Text = "..."
	refresh()
	channel:FireServer(CFG.ClientAction)
end)

-- One panel at a time: another panel's name closes this one.
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if isOpen and player:GetAttribute(ATTR.OpenPanel) ~= PANEL then
		setOpen(false)
	end
end)
for _, name in ipairs({ PA.Carried, PA.Progress }) do
	player:GetAttributeChangedSignal(name):Connect(function()
		if isOpen then
			refresh()
		end
	end)
end
Workspace:GetAttributeChangedSignal(EnchantedMistConfig.Attributes.State):Connect(function()
	if isOpen then
		refresh()
	end
end)

--==============================================================================
-- THE SERVER'S ANSWERS
--==============================================================================
channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= CFG.ServerAction or type(payload) ~= "table" then
		return
	end
	if payload.phase == "open" then
		setOpen(true)
	elseif payload.phase == "given" then
		pending = nil
		answerLabel.TextColor3 = LOOK.Money
		local n = tonumber(payload.delivered) or 0
		answerLabel.Text = if (tonumber(payload.pods) or 0) > 0 then string.format(W.GivenPod, n)
			else string.format(W.Given, n, if n == 1 then "y" else "ies", tonumber(payload.progress) or 0, PER_POD)
		refresh()
	elseif payload.phase == "refused" then
		pending = nil
		answerLabel.TextColor3 = WARN_TEXT
		answerLabel.Text = W.Refused[tostring(payload.reason)] or W.Refused.BUSY
		refresh()
	end
end)

-- A reload mid-talk never leaves the camera borrowed.
script.Destroying:Connect(function()
	setOpen(false)
end)
