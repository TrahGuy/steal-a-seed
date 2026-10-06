--!strict
-- Steal a Seed :: SacrificeUI
--
--==============================================================================
-- WHAT THE LOCAL PLAYER SEES OF THE SACRIFICE PEDESTAL (2026-09-28)
--
-- The server decides everything -- whether the pod may be offered, what it
-- buys, when the pedestal is ready again -- and this only draws it:
--
--   THE SIGN     the pedestal is lettered front and back, and the third line of
--                each sign is each player's own: READY, or the time left.
--                Written on this client's copy from the SacrificeNextAt
--                attribute.
--   THE PROMPT   the pedestal's own ProximityPrompt, which works the same for a
--                click, a tap and a controller button. Hidden while the
--                pedestal is recharging and while the question is up -- a
--                courtesy; the server refuses anything early regardless.
--   THE QUESTION a panel that shows the pod about to be given up -- the same
--                picture the hotbar draws, and its size -- what it buys, and
--                that it cannot be undone. Nothing is taken on a no, on the
--                close button, on a tap outside or on B.
--   THE ANSWER   a notice through the game's shared renderer (Notice): the
--                boost as a success, or why nothing happened as a blocked one.
--
-- The boost itself is drawn by BonusChestUI, which owns the boost row.
--
-- NOTHING HERE SAYS WHAT IS IN THE POD. The panel names its size, which the
-- shell already shows, and draws the shell. The species stays unread.
--
-- THE EXACT POD. The quote was made for the Tool in the hands when the prompt
-- fired. If that Tool leaves the hands while the question is up -- unequipped,
-- planted, sold, or the character dies -- the panel answers no and closes
-- rather than let a yes land on whatever is held next. The server refuses
-- that case too; this is only the panel keeping up.
--
-- ONE YES. The button disarms on its first press and the panel waits for the
-- answer; a second press sends nothing. An answer that never comes closes the
-- panel after a moment rather than leaving a disarmed button on screen.
--
-- ON A CONTROLLER, KEEP POD IS WHERE THE SELECTION STARTS (PadFirst), and B is
-- a no: the first button under a thumb is the safe one.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
-- A pod's size word and colour (a Secret has neither a size nor a word here).
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local Notice = require(Shared:WaitForChild("Notice"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))

local CONFIG = GameConfig.Sacrifice
local ATTR = CONFIG.Attributes
local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel

if not CONFIG.Enabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = SeedGame:WaitForChild("Remotes", 20)
local channelInstance = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
if not (channelInstance and channelInstance:IsA("RemoteEvent")) then
	warn("[Seed/SacrificeUI] No GameEvent remote; the pedestal has no confirmation.")
	return
end
local channel = channelInstance :: RemoteEvent

local WHITE = Color3.fromRGB(255, 255, 255)
local CREAM = Color3.fromRGB(242, 238, 206)
local MUTED = Color3.fromRGB(206, 188, 160)
local READY = Color3.fromRGB(142, 220, 86)
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local WARN = Color3.fromRGB(255, 196, 150)
-- The panel is the menus' light studded one (the global UI pass, 2026-10-04):
-- SACRIFICE destroys the pod, so it wears MenuKit's red `danger`; KEEP POD the
-- blue secondary. Its words are dark and plain; the world's signs keep CREAM.
local LOOK = GameConfig.BagLook
local WARN_TEXT = Color3.fromRGB(176, 52, 40)

--==============================================================================
-- TWO SIZES, BECAUSE A PHONE HELD SIDEWAYS IS 300 PIXELS TALL
--
-- The four rows at their full size need 206 pixels. UIKit.modal gives a panel's
-- content 86% of the screen less its own title bar, which on the shortest
-- listed phone -- 772 x 360, a safe height of 302 -- is 177, and 158 with the
-- largest menu size chosen. A confirmation whose buttons are cut off by the
-- bottom of its own panel is not a confirmation, and it cannot scroll them out
-- of sight either, so the rows have a second, closer size that fits in 154.
--
-- The panel asks how much room this screen gives (modal.contentRoom) and takes
-- the full size wherever it fits. The buttons stay 44 tall at the smaller one:
-- Roblox's touch guidance, and the Bag's compact button.
--==============================================================================
type Metrics = {
	pod: number,
	picture: number,
	offer: number,
	warn: number,
	button: number,
	gap: number,
	margin: number,
}
-- SELL ONE's buttons are 46 too.
local REGULAR: Metrics = { pod = 64, picture = 78, offer = 22, warn = 34, button = 46, gap = 8, margin = 16 }
local COMPACT: Metrics = { pod = 48, picture = 60, offer = 18, warn = 26, button = 44, gap = 4, margin = 6 }

-- The four rows, their three gaps and the body's own margin.
local function contentOf(m: Metrics): number
	return m.pod + m.offer + m.warn + m.button + m.gap * 3 + m.margin
end
-- How long a sent yes waits for its answer before the panel gives up on it.
local ANSWER_PATIENCE = 8

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSacrifice")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSacrifice"
gui.ResetOnSpawn = false
-- Above the Bag (30), Marigold's shop (34) and SELL ONE (36), below the RUN
-- alarm (50): a question about giving something up outranks a menu.
gui.DisplayOrder = 37
gui.IgnoreGuiInset = false
gui.Parent = playerGui

--==============================================================================
-- THE PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = "Sacrifice",
	title = "SACRIFICE POD",
	maxWidth = 380,
	maxHeight = 340,
	theme = MenuKit.rimTheme(),
})
-- The pedestal's own approved picture beside the title, on the rim.
do
	local titleBar = modal.title.Parent :: Frame
	local icon = MenuKit.picture(titleBar, GameConfig.SourceIcons.sacrifice, nil, modal.title.ZIndex + 1)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 0, 0.5, 0)
	icon.Size = UDim2.fromOffset(34, 34)
	modal.title.Position = UDim2.new(0, 38, 0.5, 0)
	modal.title.Size = UDim2.new(1, -90, 1, 0)
end
modal.followMenuSize()

local rows = Instance.new("Frame")
rows.Name = "Rows"
rows.Size = UDim2.fromScale(1, 1)
rows.BackgroundTransparency = 1
rows.ZIndex = 3
rows.Parent = modal.body

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, REGULAR.gap)
layout.Parent = rows

-- Scaled down, never up, so a narrow phone shrinks a word instead of clipping it.
local function fitText(label: TextLabel, maxSize: number)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = 9
	limit.Parent = label
end

-- THE POD: its picture on the left, and what can be said about it on the right.
-- Everything inside the row is placed by fraction, so the row can be either
-- height.
local podRow = Instance.new("Frame")
podRow.Name = "Pod"
podRow.Size = UDim2.new(1, -8, 0, REGULAR.pod)
podRow.BackgroundTransparency = 1
podRow.LayoutOrder = 1
podRow.ZIndex = 4
podRow.Parent = rows

local PICTURE_W = REGULAR.picture
local picture = UIKit.itemPreview(podRow, {
	name = "Picture",
	size = UDim2.fromOffset(PICTURE_W, REGULAR.pod),
	position = UDim2.fromOffset(0, 0),
	scrim = 1,
	fit = 0.92,
})

-- Plain words on the light panel (FredokaOne; `body` the clean body face).
local function word(parent: Instance, name: string, size: number, colour: Color3, body: boolean,
	position: UDim2, extent: UDim2): TextLabel
	local label = if body then MenuKit.body(parent, name, size, colour, 4) else MenuKit.text(parent, name, size, colour, 4)
	label.Position = position
	label.Size = extent
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 4
	fitText(label, size)
	return label
end

local nameLabel = word(podRow, "Name", 24, LOOK.Text, false, UDim2.new(0, PICTURE_W + 8, 0.09, 0),
	UDim2.new(1, -(PICTURE_W + 8), 0.47, 0))
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "UNHATCHED POD"
local sizeLabel = word(podRow, "Size", 16, LOOK.Muted, true, UDim2.new(0, PICTURE_W + 8, 0.56, 0),
	UDim2.new(1, -(PICTURE_W + 8), 0.35, 0))
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.RichText = true

local offerLabel = word(rows, "Offer", 17, LOOK.Money, false, UDim2.new(), UDim2.new(1, -8, 0, REGULAR.offer))
offerLabel.LayoutOrder = 2
offerLabel.TextXAlignment = Enum.TextXAlignment.Center
local warnLabel = word(rows, "Warning", 14, WARN_TEXT, true, UDim2.new(), UDim2.new(1, -8, 0, REGULAR.warn))
warnLabel.LayoutOrder = 3
warnLabel.TextXAlignment = Enum.TextXAlignment.Center
warnLabel.TextWrapped = true

local buttonsRow = Instance.new("Frame")
buttonsRow.Name = "Buttons"
buttonsRow.Size = UDim2.new(1, -8, 0, REGULAR.button)
buttonsRow.BackgroundTransparency = 1
buttonsRow.LayoutOrder = 4
buttonsRow.ZIndex = 4
buttonsRow.Parent = rows

--==============================================================================
-- THE TWO BUTTONS, SELL ONE'S RECIPE
--
-- A transparent TextButton for the hit, a rounded plate with the outline and
-- the gradient, a darker foot, an outlined label, and the same pop the Bag's
-- cards have.
--==============================================================================
type Button = {
	button: TextButton,
	plate: Frame,
	label: TextLabel,
}

local function makeButton(name: string, text: string, face: string, anchorX: number): Button
	-- MenuKit's button (the global UI pass, 2026-10-04): the family's faces,
	-- foot, keyline and press, in the one language every menu speaks.
	local made = MenuKit.button(buttonsRow, name, 5, text, 18)
	made.style(face)
	local b = made.hit
	b.AnchorPoint = Vector2.new(anchorX, 0.5)
	b.Position = UDim2.new(anchorX, 0, 0.5, 0)
	b.Size = UDim2.new(0.5, -6, 0, REGULAR.button)
	UIKit.clicks(b)
	return { button = b, plate = made.plate, label = made.label }
end

local keepButton = makeButton("Keep", "KEEP POD", "sky", 0)
local yesButton = makeButton("Sacrifice", "SACRIFICE", "danger", 1)

-- Where a controller's selection starts when this opens (PadFocus reads it).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Value = keepButton.button
padFirst.Parent = modal.shell

local BACK_ACTION = "SeedSacrificeBack"

--==============================================================================
-- THE SIZE THAT FITS THIS SCREEN
--
-- Asked when the panel opens and again whenever the screen or the menu size
-- changes under it -- after UIKit.modal's own follow, which is registered
-- first, has settled what size the panel is drawn at.
--==============================================================================
local function fit()
	local m = if modal.contentRoom() >= contentOf(REGULAR) then REGULAR else COMPACT
	layout.Padding = UDim.new(0, m.gap)
	podRow.Size = UDim2.new(1, -8, 0, m.pod)
	picture.holder.Size = UDim2.fromOffset(m.picture, m.pod)
	nameLabel.Position = UDim2.new(0, m.picture + 8, 0.09, 0)
	nameLabel.Size = UDim2.new(1, -(m.picture + 8), 0.47, 0)
	sizeLabel.Position = UDim2.new(0, m.picture + 8, 0.56, 0)
	sizeLabel.Size = UDim2.new(1, -(m.picture + 8), 0.35, 0)
	offerLabel.Size = UDim2.new(1, -8, 0, m.offer)
	warnLabel.Size = UDim2.new(1, -8, 0, m.warn)
	buttonsRow.Size = UDim2.new(1, -8, 0, m.button)
	modal.fitContent(contentOf(m))
end
UIKit.onMenuSize(fit)

--==============================================================================
-- WORDS
--==============================================================================
local function hex(c: Color3): string
	return string.format("#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- Why nothing happened, as a headline and the next step that works for it.
-- The words are GameConfig's, where HudLayoutSpec measures them; a reason with
-- no line there is not something a player did, and gets none here.
local REFUSED: { [string]: { title: string, detail: string? } } = CONFIG.Notices

--==============================================================================
-- THE STATE OF THE ONE OPEN QUESTION
--==============================================================================
local openToken: number? = nil
local watches: { RBXScriptConnection } = {}
local awaiting = false
local answerGeneration = 0
local paintPedestal: () -> ()

local function armYes(armed: boolean)
	yesButton.button.Active = armed
	yesButton.plate.BackgroundTransparency = if armed then 0 else 0.35
	yesButton.label.TextTransparency = if armed then 0 else 0.35
end

local function close()
	for _, c in ipairs(watches) do
		c:Disconnect()
	end
	table.clear(watches)
	openToken = nil
	awaiting = false
	answerGeneration += 1
	armYes(true)
	ContextActionService:UnbindAction(BACK_ACTION)
	modal.setOpen(false)
	paintPedestal()
end

local function answer(accept: boolean)
	local token = openToken
	if not token then
		return
	end
	channel:FireServer(CONFIG.ClientAction, { token = token, accept = accept })
end

local function decline()
	if not openToken then
		return
	end
	answer(false)
	close()
end

-- B is a no, bound only while the question is up. Above PadFocus's generic
-- panel close, because this panel is not on the OpenPanel mutex.
local function bindBack()
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		decline()
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
end

-- The hotbar's own picture of this pod: the same builder, asked the same way.
local function picturePod(tool: Tool?, tier: number)
	local id = if tool then tool:GetAttribute("SpeciesId") else nil
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	if not species then
		picture.holder.Visible = false
		return
	end
	picture.holder.Visible = true
	picture.setModel(string.format("pod:%s:%d", species.Id, tier), function(parent: Instance): Model?
		return CreatureModel.BuildPod(species, tier, CFrame.new(), parent)
	end, "plant")
end

local function show(payload: { [string]: any })
	local token = tonumber(payload.token)
	local tier = tonumber(payload.tier)
	local multiplier = tonumber(payload.multiplier)
	local seconds = tonumber(payload.seconds)
	local cooldown = tonumber(payload.cooldown)
	if not (token and tier and multiplier and seconds and cooldown)
		or tier < 1 or tier > SeedData.TierCount or tier ~= math.floor(tier) then
		return
	end
	-- A fresh quote replaces whatever was open, the same way the server's did.
	close()

	local character = player.Character
	local held = if character then character:FindFirstChildOfClass("Tool") else nil
	picturePod(held, tier)
	-- A Secret pod has no size tier (2026-10-02), and this panel never names a
	-- rarity: for it, the question alone. Every other pod reads as it did.
	local heldId = if held then held:GetAttribute("SpeciesId") else nil
	local sizeWord = PlantInfo.SizeWord(heldId, tier)
	sizeLabel.Text = if sizeWord
		then string.format('<font color="%s">%s</font>  •  ???',
			hex(PlantInfo.SizeColour(heldId, tier)), string.upper(sizeWord))
		else string.format('<font color="%s">???</font>', hex(PlantInfo.SizeColour(heldId, tier)))
	offerLabel.Text = GameConfig.sacrificeOffer(multiplier, seconds)
	warnLabel.Text = string.format("The pod is destroyed for good. The pedestal recharges for %s.",
		GameConfig.sacrificeSpan(cooldown))

	openToken = token

	--======================================================================
	-- THE HANDS ARE WATCHED WHILE THE QUESTION IS UP
	--======================================================================
	if held then
		table.insert(watches, held.AncestryChanged:Connect(function()
			if held.Parent ~= character then
				decline()
			end
		end))
	end
	table.insert(watches, player.CharacterRemoving:Connect(function()
		close()
	end))

	modal.setOpen(true)
	fit()
	bindBack()
	paintPedestal()
end

yesButton.button.Activated:Connect(function()
	if not openToken or awaiting then
		return
	end
	awaiting = true
	armYes(false)
	answer(true)
	answerGeneration += 1
	local mine = answerGeneration
	task.delay(ANSWER_PATIENCE, function()
		if awaiting and answerGeneration == mine then
			close()
		end
	end)
end)
keepButton.button.Activated:Connect(decline)
modal.close.Activated:Connect(decline)
modal.dimmer.Activated:Connect(decline)
-- The panel is sized against the screen it opened on; keep it on a screen that
-- turns or resizes under it.
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if openToken then
		fit()
	end
end)

--==============================================================================
-- THE PEDESTAL'S OWN LINE, AND ITS PROMPT
--
-- Persistent under streaming, but it still arrives after this script starts.
--==============================================================================
-- One line per sign: the pedestal is lettered front and back.
local statusLabels: { TextLabel } = {}
local prompt: ProximityPrompt? = nil
-- "SACRIFICE A POD!" floating over the bowl (2026-09-30): this player's own.
local floatingWords: FloatingSign.Sign? = nil
-- The glowing base round the foot (2026-10-01): this player's own, steady, and
-- dimmed while their pedestal recharges. No flashing, no particles.
local baseGlow: Part? = nil
local baseLight: PointLight? = nil
local EXPLAIN = GameConfig.sacrificeExplain(SeedData.Sacrifice.Multiplier, SeedData.Sacrifice.DurationSeconds)
local LIME = CONFIG.FloatingWords.Colour

paintPedestal = function()
	local now = Workspace:GetServerTimeNow()
	local nextAt = tonumber(player:GetAttribute(ATTR.NextAt)) or 0
	local ready = now >= nextAt
	for _, label in ipairs(statusLabels) do
		label.Text = if ready then "READY" else "READY IN " .. StatusText.clock(nextAt - now)
		label.TextColor3 = if ready then READY else MUTED
	end
	local p = prompt
	if p then
		p.Enabled = ready and openToken == nil
	end
	--==========================================================================
	-- THE WORDS STAY UP (2026-10-01): the offer reads the same ready or not;
	-- the third line says which. Ready: the one sentence of what it does, in
	-- the boards' plain bold face. Recharging: how long, in the sign's own.
	-- Nothing here decides anything -- the server still refuses an early press.
	--==========================================================================
	local w = floatingWords
	if w then
		local note = w.note
		if note then
			if ready then
				note.Text, note.Font, note.TextColor3 = EXPLAIN, FloatingSign.NoteFont, CREAM
			else
				note.Text, note.Font, note.TextColor3 =
					"RECHARGING · READY IN " .. StatusText.clock(nextAt - now), FloatingSign.Font, CREAM
			end
		end
		w.setShown(true)
	end
	local glow = baseGlow
	if glow then
		glow.Transparency = if ready then 0.45 else 0.85
	end
	local light = baseLight
	if light then
		light.Enabled = ready
	end
end

task.spawn(function()
	local folder = Workspace:WaitForChild(CONFIG.FolderName, math.huge)
	local model = folder:WaitForChild("SacrificePedestal", math.huge)
	for _, name in ipairs({ "Sign", "SignBack" }) do
		local sign = model:WaitForChild(name, 10)
		local face = if sign then sign:WaitForChild("Face", 10) else nil
		local status = if face then face:WaitForChild("Status", 10) else nil
		if status and status:IsA("TextLabel") then
			table.insert(statusLabels, status)
		end
	end
	local bowl = model:WaitForChild("OfferingBowl", 10)
	local found = if bowl then bowl:WaitForChild("SacrificePrompt", 10) else nil
	prompt = if found and found:IsA("ProximityPrompt") then found else nil
	--==========================================================================
	-- THE WORDS OVER IT (2026-09-30): floating above the bowl like the wheel's
	-- sign, with what it buys under them in the pedestal's own numbers -- and,
	-- since 2026-10-01, a third line (paintPedestal fills it).
	--==========================================================================
	if bowl and bowl:IsA("BasePart") then
		local W = CONFIG.FloatingWords
		floatingWords = FloatingSign.new({
			name = "SacrificeWords",
			parent = model,
			at = CFrame.new(bowl.Position + Vector3.new(0, W.Above, 0)),
			text = W.Text,
			colour = W.Colour,
			width = W.Width,
			height = W.Height,
			subText = GameConfig.sacrificeBoostTitle(SeedData.Sacrifice.Multiplier),
			subHeight = W.SubHeight,
			noteText = EXPLAIN,
			noteHeight = W.NoteHeight,
			noteColour = CREAM,
		})
	end
	--==========================================================================
	-- THE GLOWING BASE (2026-10-01): a thin lime plate under the foot, so a rim
	-- of light shows round it on the deck, and a soft light on the stone. Local
	-- and inert: nothing can stand on it, touch it or hit it, and it never
	-- moves or pulses -- paintPedestal only dims it while recharging.
	--==========================================================================
	local foot = model:WaitForChild("Foot", 10)
	if foot and foot:IsA("BasePart") then
		local plate = Instance.new("Part")
		plate.Name = "SacrificeBaseGlow"
		plate.Size = Vector3.new(foot.Size.X + 0.8, 0.12, foot.Size.Z + 0.8)
		plate.CFrame = foot.CFrame * CFrame.new(0, -foot.Size.Y / 2 + 0.06, 0)
		plate.Color = LIME
		plate.Material = Enum.Material.Neon
		plate.Transparency = 0.45
		plate.Anchored = true
		plate.CanCollide = false
		plate.CanTouch = false
		plate.CanQuery = false
		plate.CastShadow = false
		plate.Parent = model
		baseGlow = plate
		local light = Instance.new("PointLight")
		light.Color = LIME
		light.Brightness = 0.7
		light.Range = 8
		light.Shadows = false
		light.Parent = plate
		baseLight = light
	end
	paintPedestal()
end)

for _, name in pairs(ATTR) do
	player:GetAttributeChangedSignal(name):Connect(paintPedestal)
end
task.spawn(function()
	while gui.Parent do
		paintPedestal()
		task.wait(0.5)
	end
end)

--==============================================================================
-- WHAT THE SERVER SAYS
--==============================================================================
channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= CONFIG.ServerAction or type(payload) ~= "table" then
		return
	end
	local phase = payload.phase
	if phase == "quote" then
		show(payload)
	elseif phase == "sacrificed" then
		close()
		local multiplier = tonumber(payload.multiplier) or SeedData.Sacrifice.Multiplier
		local seconds = tonumber(payload.seconds) or SeedData.Sacrifice.DurationSeconds
		Notice.post({
			kind = "success",
			title = CONFIG.SuccessTitle,
			detail = GameConfig.sacrificeOffer(multiplier, seconds) .. ".",
			key = "sacrifice:done",
			icon = "sacrifice",
		})
	elseif phase == "refused" then
		if openToken then
			close()
		end
		local words = if type(payload.reason) == "string" then REFUSED[payload.reason] else nil
		if words then
			local detail = words.detail
			local nextAt = tonumber(payload.nextAt)
			if payload.reason == "COOLDOWN" and nextAt then
				detail = GameConfig.sacrificeReadyIn(nextAt - Workspace:GetServerTimeNow())
			end
			Notice.post({
				kind = "blocked",
				title = words.title,
				detail = detail,
				key = "sacrifice:refused",
			})
		end
	end
end)
