--!strict
-- Steal a Seed :: SellUI
--
--==============================================================================
-- THE SELL ONE CONFIRMATION
--
-- The server quoted a price for the plant in the player's hands; this shows it
-- and asks. Nothing here decides anything: the panel opens on the server's
-- "quote", the Sell button sends the quote's token back with a yes, Cancel
-- sends a no, and the panel closes on whatever the server answers. The name,
-- rarity and size come off the species the quote names; the income line is
-- PlantInfo's, with the pass multiplier, exactly as the Bag shows it; the price
-- is the server's number and nothing else.
--
-- THE EXACT COPY. The quote was made for the Tool that was in the hands when
-- the sign was pressed. If that Tool leaves the hands while the panel is up --
-- unequipped, planted, sold by SELL ALL, or the character dies -- the panel
-- cancels itself rather than let a yes land on whatever is held next. The
-- server refuses that case too; this is only the panel keeping up.
--
-- ONE YES. The Sell button disarms on its first press and the panel waits for
-- the answer; a second press sends nothing. An answer that never comes closes
-- the panel after a moment rather than leaving a disarmed button on screen.
--
-- INPUT IS SCOPED BY THE MODAL. UIKit.modal's dimmer is a TextButton that
-- covers the screen, so a tap anywhere but the two buttons is consumed and
-- never reaches the world, the held Tool or the plot behind the panel -- the
-- same reason the Bag's dimmer is a button.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SELL = GameConfig.SellOne
local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel

local WHITE = Color3.fromRGB(255, 255, 255)
local CREAM = Color3.fromRGB(242, 238, 206)
-- The same two pairs SettingsUI's toggle uses: the shop's green for the yes,
-- the panel's soil for the no, each with the darker foot every button here has.
local YES_FACE = RAIL.ShopFace
local YES_SHADE = RAIL.ShopShade
local YES_FOOT = Color3.fromRGB(30, 92, 30)
local NO_FACE = Color3.fromRGB(112, 90, 74)
local NO_SHADE = Color3.fromRGB(72, 54, 44)
local NO_FOOT = Color3.fromRGB(44, 32, 26)

-- Roblox's touch guidance is 44; the Bag's compact action button is 44 too.
local BUTTON_H = 46
local ROW_GAP = 8
local PANEL_W = 380
-- How long a sent yes waits for its answer before the panel gives up on it.
local ANSWER_PATIENCE = 8

-- The brief line near the top of the screen: the same slot, size and recipe as
-- the biome name, placed by HudLayout so it clears the rail on every screen.
local NOTICE_SIZE = 22
local NOTICE_OUTLINE = 1.5
local NOTICE_TOP = 50
local NOTICE_H = 30
local NOTICE_IN, NOTICE_HOLD, NOTICE_OUT = 0.2, 2.2, 0.6

local remotes = SeedGame:WaitForChild("Remotes", 20)
local channelInstance = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
if not (channelInstance and channelInstance:IsA("RemoteEvent")) then
	warn("[Seed/SellUI] No GameEvent remote; SELL ONE has no confirmation.")
	return
end
local channel = channelInstance :: RemoteEvent

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSellOne")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSellOne"
gui.ResetOnSpawn = false
-- Above the Bag (30) and Marigold's shop (34), below the RUN alarm (50): a
-- question about money outranks a menu, and an alarm outranks the question.
gui.DisplayOrder = 36
gui.IgnoreGuiInset = false
gui.Parent = playerGui

--==============================================================================
-- THE PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = "SellOne",
	title = "SELL ONE",
	maxWidth = PANEL_W,
	maxHeight = 340,
})

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
layout.Padding = UDim.new(0, ROW_GAP)
layout.Parent = rows

-- Scaled down, never up, so a narrow phone shrinks a word instead of clipping it.
local function fitText(label: TextLabel, maxSize: number)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = 9
	limit.Parent = label
end

local function row(name: string, size: number, colour: Color3, height: number,
	order: number, outline: number): TextLabel
	local label = UIKit.outlined(rows, name, size, colour, outline)
	label.Size = UDim2.new(1, -8, 0, height)
	label.LayoutOrder = order
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 4
	fitText(label, size)
	return label
end

local nameLabel = row("Name", 26, WHITE, 32, 1, 2.5)
local metaLabel = row("Meta", 15, CREAM, 20, 2, 1.5)
metaLabel.RichText = true
local incomeLabel = row("Income", 15, CREAM, 20, 3, 1.5)
local question = row("Question", 18, WHITE, 48, 4, 2)
question.TextWrapped = true

local buttonsRow = Instance.new("Frame")
buttonsRow.Name = "Buttons"
buttonsRow.Size = UDim2.new(1, -8, 0, BUTTON_H)
buttonsRow.BackgroundTransparency = 1
buttonsRow.LayoutOrder = 5
buttonsRow.ZIndex = 4
buttonsRow.Parent = rows

-- The five rows and their gaps. UIKit.modal sizes the panel to this once the
-- screen is known, and shrinks it on a screen that cannot fit it.
local CONTENT_H = 32 + 20 + 20 + 48 + BUTTON_H + ROW_GAP * 4 + 16

--==============================================================================
-- THE TWO BUTTONS, THE SETTINGS TOGGLE'S RECIPE
--
-- A transparent TextButton for the hit, a rounded plate with the outline and
-- the gradient, a darker foot, an outlined label, and the same pop the Bag's
-- cards have. A press sinks it under a thumb and lifts it under a mouse.
--==============================================================================
type Button = {
	button: TextButton,
	plate: Frame,
	label: TextLabel,
}

local function makeButton(name: string, text: string, face: Color3, shade: Color3,
	foot: Color3, anchorX: number): Button
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(anchorX, 0.5)
	b.Position = UDim2.new(anchorX, 0, 0.5, 0)
	b.Size = UDim2.new(0.5, -6, 0, BUTTON_H)
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = 5
	b.Parent = buttonsRow
	UIKit.clicks(b)

	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.new(1, -4, 1, -4)
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.ZIndex = 6
	plate.Parent = b
	UIKit.corner(plate, 10)
	UIKit.stroke(plate, PANEL.Outline, RAIL.OutlineThickness)
	UIKit.gradient(plate, face, shade)

	local footFrame = Instance.new("Frame")
	footFrame.Name = "Shade"
	footFrame.AnchorPoint = Vector2.new(0.5, 1)
	footFrame.Position = UDim2.new(0.5, 0, 1, 0)
	footFrame.Size = UDim2.new(1, 0, 0, 5)
	footFrame.BackgroundColor3 = foot
	footFrame.BorderSizePixel = 0
	footFrame.Active = false
	footFrame.ZIndex = 7
	footFrame.Parent = plate
	UIKit.corner(footFrame, 10)

	local label = UIKit.outlined(plate, "Label", 18, WHITE, 2.5)
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromOffset(0, -2)
	label.Text = text
	label.ZIndex = 8

	local scale = Instance.new("UIScale")
	scale.Parent = b
	UIKit.cardPop(b, scale, { hoverScale = 1.06, pressScale = 0.94, sound = false })

	return { button = b, plate = plate, label = label }
end

local cancelButton = makeButton("Cancel", "CANCEL", NO_FACE, NO_SHADE, NO_FOOT, 0)
local sellButton = makeButton("Sell", "SELL", YES_FACE, YES_SHADE, YES_FOOT, 1)

--==============================================================================
-- THE BRIEF LINE
--==============================================================================
local notice = UIKit.outlined(gui, "Notice", NOTICE_SIZE, WHITE, NOTICE_OUTLINE)
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Position = UDim2.new(0.5, 0, 0, NOTICE_TOP)
notice.Size = UDim2.fromOffset(0, NOTICE_H)
notice.AutomaticSize = Enum.AutomaticSize.X
notice.TextXAlignment = Enum.TextXAlignment.Center
notice.TextYAlignment = Enum.TextYAlignment.Center
notice.TextTransparency = 1
notice.Visible = false
notice.ZIndex = 10
local noticeStroke = notice:FindFirstChildOfClass("UIStroke") :: UIStroke
noticeStroke.Transparency = 1

local function placeNotice()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local solved = HudLayout.solve(input)
	local inset = input.insetTop or 0
	local width = notice.AbsoluteSize.X + NOTICE_OUTLINE * 2
	local dx, top = HudLayout.notice(solved, width, NOTICE_H, NOTICE_TOP - inset)
	notice.Position = UDim2.new(0.5, math.round(dx), 0, top + inset)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeNotice)
notice:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeNotice)
placeNotice()

local noticeToken = 0
local noticeTweens: { Tween } = {}

local function say(text: string)
	noticeToken += 1
	local mine = noticeToken
	for _, t in ipairs(noticeTweens) do
		t:Cancel()
	end
	table.clear(noticeTweens)

	notice.Text = text
	notice.Visible = true
	notice.TextTransparency = 1
	noticeStroke.Transparency = 1
	placeNotice()

	local fadeIn = TweenInfo.new(NOTICE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local a = TweenService:Create(notice, fadeIn, { TextTransparency = 0 })
	local b = TweenService:Create(noticeStroke, fadeIn, { Transparency = 0 })
	table.insert(noticeTweens, a)
	table.insert(noticeTweens, b)
	a:Play()
	b:Play()

	task.delay(NOTICE_IN + NOTICE_HOLD, function()
		if noticeToken ~= mine then
			return
		end
		local fadeOut = TweenInfo.new(NOTICE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local c = TweenService:Create(notice, fadeOut, { TextTransparency = 1 })
		local d = TweenService:Create(noticeStroke, fadeOut, { Transparency = 1 })
		table.insert(noticeTweens, c)
		table.insert(noticeTweens, d)
		c:Play()
		d:Play()
		task.delay(NOTICE_OUT, function()
			if noticeToken == mine then
				notice.Visible = false
			end
		end)
	end)
end

--==============================================================================
-- NUMBERS THE PLAYER CAN CHECK
--
-- The exact payout, with thousands separators -- "$12,000", not "$12K". A sale
-- is the one place a rounded figure would be the wrong figure.
--==============================================================================
local function withCommas(n: number): string
	local digits = string.format("%d", math.floor(n + 0.5))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return grouped
end

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

--==============================================================================
-- THE STATE OF THE ONE OPEN QUESTION
--==============================================================================
local openToken: number? = nil
local watches: { RBXScriptConnection } = {}
local awaiting = false
local answerGeneration = 0

local function armSell(armed: boolean)
	sellButton.button.Active = armed
	sellButton.plate.BackgroundTransparency = if armed then 0 else 0.35
	sellButton.label.TextTransparency = if armed then 0 else 0.35
end

local function close()
	for _, c in ipairs(watches) do
		c:Disconnect()
	end
	table.clear(watches)
	openToken = nil
	awaiting = false
	answerGeneration += 1
	armSell(true)
	modal.setOpen(false)
end

local function answer(accept: boolean)
	local token = openToken
	if not token then
		return
	end
	channel:FireServer(SELL.ClientAction, { token = token, accept = accept })
end

local function cancel()
	if not openToken then
		return
	end
	answer(false)
	close()
end

local function show(payload: { [string]: any })
	local token = tonumber(payload.token)
	local speciesId = payload.speciesId
	local tier = tonumber(payload.tier)
	local price = tonumber(payload.price)
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if not (token and species and tier and price) then
		return
	end
	-- A fresh quote replaces whatever was open, the same way the server's did.
	close()

	local info = PlantInfo.Describe(speciesId, tier, true, GameConfig.cashMultiplier(player))
	nameLabel.Text = string.upper(info.title)
	metaLabel.Text = string.format('<font color="%s">%s</font>  •  <font color="%s">%s</font>',
		hex(info.rarityColour), string.upper(info.rarity),
		hex(info.sizeColour), string.upper(info.size))
	incomeLabel.Text = string.format("Earning %s right now", info.income)
	question.Text = string.format("Sell this %s for $%s?", species.Name, withCommas(price))

	openToken = token

	--======================================================================
	-- THE HANDS ARE WATCHED WHILE THE QUESTION IS UP
	--
	-- The Tool in the hands NOW is the one the server quoted a moment ago.
	-- If it goes anywhere -- the Backpack, the ground, nowhere -- the question
	-- no longer has a subject, and it closes with a no rather than wait for a
	-- yes to land on the next thing picked up.
	--======================================================================
	local character = player.Character
	local held = if character then character:FindFirstChildOfClass("Tool") else nil
	if held then
		table.insert(watches, held.AncestryChanged:Connect(function()
			if held.Parent ~= character then
				cancel()
			end
		end))
	end
	table.insert(watches, player.CharacterRemoving:Connect(function()
		close()
	end))

	modal.setOpen(true)
	modal.fitContent(CONTENT_H)
end

sellButton.button.Activated:Connect(function()
	if not openToken or awaiting then
		return
	end
	awaiting = true
	armSell(false)
	answer(true)
	answerGeneration += 1
	local mine = answerGeneration
	task.delay(ANSWER_PATIENCE, function()
		if awaiting and answerGeneration == mine then
			close()
		end
	end)
end)
cancelButton.button.Activated:Connect(cancel)
modal.close.Activated:Connect(cancel)
modal.dimmer.Activated:Connect(cancel)

--==============================================================================
-- WHAT THE SERVER SAYS
--==============================================================================
channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action ~= SELL.ServerAction or type(payload) ~= "table" then
		return
	end
	local phase = payload.phase
	if phase == "quote" then
		show(payload)
	elseif phase == "refused" then
		if openToken then
			close()
		end
		if type(payload.text) == "string" and payload.text ~= "" then
			say(payload.text)
		end
	elseif phase == "sold" then
		close()
		local name = if type(payload.name) == "string" then payload.name else "plant"
		local paid = tonumber(payload.paid) or 0
		say(string.format("Sold %s for $%s", name, withCommas(paid)))
	end
end)
