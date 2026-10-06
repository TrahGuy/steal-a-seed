--!strict
-- Steal a Seed :: BonusChestUI
--
-- What the local player sees of the Bonus Chest (2026-09-27 launch pass). The
-- server decides everything -- whether it is ready, what it gave, when it runs
-- out -- and publishes it on this player as four attributes
-- (GameConfig.BonusChest.Attributes). This only draws them:
--
--   THE SIGN     a board behind the chest, lettered front and back like the
--                plot plaque: READY or the time left, and BOTH outcomes with
--                their chances, so the odds are on the chest before anybody
--                presses anything.
--   THE PROMPT   the chest's own ProximityPrompt, which works the same for a
--                click, a tap and a controller button. Shown only while this
--                player can actually claim -- hiding it is a courtesy; the
--                server refuses anything early regardless.
--   THE RESULT   a claim the server confirmed: the reward splash (RewardSplash,
--                2026-10-01) -- the reward's icon, name and amount near the
--                middle, then the icon flies to the boost's own ICON over the
--                hotbar -- once per claim. A refusal: a blocked notice saying
--                why (Notice, ActionToastUI). One sound either way, the notice's.
--
-- THE RUNNING BOOST IS AN ICON NOW (2026-10-04). The text row this script drew
-- under the clock's column -- the chest's boost and the Sacrifice Pedestal's,
-- each with its time left -- became two of BoostIconsUI's icons over the hotbar,
-- drawn from the same attributes. This script keeps the sign, the prompt and
-- the splash.
--
-- DRAWN FROM THE ATTRIBUTES, NOT THE REPLY. If the server's answer is lost the
-- attributes still arrive, and the sign and the icon show the reward anyway.
--==============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local Notice = require(Shared:WaitForChild("Notice"))
local RewardSplash = require(Shared:WaitForChild("RewardSplash"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local CHEST = GameConfig.BonusChest
local ATTR = CHEST.Attributes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(255, 214, 92)
local CREAM = Color3.fromRGB(242, 238, 206)
local MUTED = Color3.fromRGB(206, 188, 160)
local READY = Color3.fromRGB(142, 220, 86)
local PLANK = Color3.fromRGB(176, 128, 82)
local OAK = Color3.fromRGB(122, 84, 52)

--==============================================================================
-- WORDS
--==============================================================================
local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

local totalWeight = 0
for _, reward in ipairs(CHEST.Rewards) do
	totalWeight += reward.Weight
end

local function chanceOf(reward: any): string
	return string.format("%d%%", math.floor(reward.Weight / totalWeight * 100 + 0.5))
end

-- Why nothing happened, as a headline and the next step that works for it.
-- COOLDOWN's time is filled in from the server's answer.
local REFUSED: { [string]: { title: string, detail: string? } } = {
	LOCKED = { title = "CHEST LOCKED", detail = "Finish the guide to open it." },
	COOLDOWN = { title = "CHEST NOT READY" },
	BUSY = { title = "CHEST OPENING", detail = "One moment." },
	NOT_READY = { title = "CHEST NOT READY", detail = "Still loading. Try again in a moment." },
	NOT_SAVED = { title = "CHEST CLOSED", detail = "Saving is off here, so nothing was granted." },
	SAVE_FAILED = { title = "CHEST DIDN'T OPEN", detail = "Saving failed, so nothing was used. Try again." },
	DISABLED = { title = "CHEST CLOSED" },
}

--==============================================================================
-- THE SIGN AND THE GLOW, BUILT ON THE CHEST WHEN IT STREAMS IN
--==============================================================================
local function outlined(parent: Instance, name: string, font: Enum.Font, colour: Color3,
	stroke: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextScaled = true
	label.TextColor3 = colour
	label.Text = ""
	label.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.new(0, 0, 0)
	edge.Thickness = stroke
	edge.Parent = label
	return label
end

local function signPart(name: string, size: Vector3, colour: Color3, material: Enum.Material,
	parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

type Face = { status: TextLabel }
type Built = { model: Model, faces: { Face }, prompt: ProximityPrompt?, glow: PointLight?, words: FloatingSign.Sign }
local built: Built? = nil

local function build(chest: Model): Built
	local sign = Instance.new("Model")
	sign.Name = "ChestSign"
	local origin = chest:GetPivot()
	-- Behind the chest (its front is -Z), a post and a board facing the front.
	local post = signPart("Post", Vector3.new(0.5, 4.2, 0.5), OAK, Enum.Material.Wood, sign)
	post.CFrame = origin * CFrame.new(0, 2.1, 2.6)
	local board = signPart("Board", Vector3.new(6.4, 3.4, 0.35), PLANK, Enum.Material.WoodPlanks, sign)
	board.CFrame = origin * CFrame.new(0, 5.6, 2.6)
	local rim = signPart("Rim", Vector3.new(6.7, 3.7, 0.25), OAK, Enum.Material.Wood, sign)
	rim.CFrame = board.CFrame

	local faces: { Face } = {}
	for _, which in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local surface = Instance.new("SurfaceGui")
		surface.Name = if which == Enum.NormalId.Front then "Face" else "FaceBack"
		surface.Face = which
		surface.CanvasSize = Vector2.new(320, 170)
		surface.LightInfluence = 0
		surface.MaxDistance = 90
		surface.Active = false
		surface.Parent = board

		local title = outlined(surface, "Title", Enum.Font.LuckiestGuy, GOLD, 2.5)
		title.Position = UDim2.fromOffset(8, 6)
		title.Size = UDim2.new(1, -16, 0, 40)
		title.Text = "BONUS CHEST"
		local status = outlined(surface, "Status", Enum.Font.LuckiestGuy, READY, 2)
		status.Position = UDim2.fromOffset(8, 48)
		status.Size = UDim2.new(1, -16, 0, 32)
		for i, reward in ipairs(CHEST.Rewards) do
			local line = outlined(surface, "Odds" .. i, Enum.Font.GothamBold, CREAM, 1.5)
			line.Position = UDim2.fromOffset(8, 86 + (i - 1) * 38)
			line.Size = UDim2.new(1, -16, 0, 32)
			line.Text = string.format("%s  %s  %s", chanceOf(reward), reward.Title,
				clock(CHEST.BoostSeconds))
		end
		table.insert(faces, { status = status })
	end
	--==========================================================================
	-- THE WORDS OVER IT (2026-09-30; 2026-10-01): "FREE CHEST", floating above
	-- the board like the wheel's sign, this player's own, with their state on
	-- the line under it. paint() shows it unless the chest is locked to them.
	--==========================================================================
	local W = CHEST.FloatingWords
	local words = FloatingSign.new({
		name = "OpenChestWords",
		parent = sign,
		at = origin * CFrame.new(0, W.Above, W.Behind),
		text = W.Text,
		colour = W.Colour,
		width = W.Width,
		height = W.Height,
		subText = W.ReadyText,
		subHeight = W.SubHeight,
	})
	sign.Parent = chest

	-- The chest's own prompt, found rather than made: the server owns it.
	local body = chest:FindFirstChild("Body")
	local prompt = if body then body:FindFirstChildOfClass("ProximityPrompt") else nil
	-- A warm glow off the lock while THIS player can claim. Local, so it is
	-- nobody else's cue.
	local lock = chest:FindFirstChild("Lock")
	local glow: PointLight? = nil
	if lock and lock:IsA("BasePart") then
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 9
		light.Brightness = 1.4
		light.Enabled = false
		light.Parent = lock
		glow = light
	end
	return { model = sign, faces = faces, prompt = prompt, glow = glow, words = words }
end

--==============================================================================
-- THE SCREEN: THE SPLASH'S LAYER
--
-- Over every HUD group (46), so a reward's splash and its flight stand over
-- the hotbar and the icon row it flies to.
--==============================================================================
local existing = playerGui:FindFirstChild("SeedBonusChest")
if existing then
	existing:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedBonusChest"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 46
gui.Parent = playerGui

-- The colour of the number each reward raises: cash green for plant income,
-- speed blue for training (the Cash and Speed readout's own two).
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
local BOOST_TINT: { [string]: Color3 } = { income = CASH_GREEN, training = SPEED_BLUE }

-- The running boost's icon over the hotbar (BoostIconsUI names each icon by
-- its id), while it is on screen; nil otherwise.
local function boostIcon(id: string): Frame?
	local icons = playerGui:FindFirstChild("SeedBoostIcons")
	local row = icons and icons:FindFirstChild("Row")
	local icon = row and row:FindFirstChild(id)
	if not (row and row:IsA("GuiObject") and row.Visible and icon and icon:IsA("Frame")) then
		return nil
	end
	return icon
end

--==============================================================================
-- ONE PAINT, TWICE A SECOND
--==============================================================================
local pending = false
local pendingSince = 0

local function paint()
	local now = Workspace:GetServerTimeNow()
	local unlocked = player:GetAttribute(ATTR.Unlocked) == true
	local nextAt = tonumber(player:GetAttribute(ATTR.NextAt)) or 0
	if pending and now - pendingSince > 8 then
		-- The answer never came. The attributes are the truth either way.
		pending = false
	end
	local ready = unlocked and now >= nextAt and not pending

	local b = built
	if b then
		local text, colour
		if pending then
			text, colour = "OPENING...", GOLD
		elseif not unlocked then
			text, colour = "FINISH THE GUIDE FIRST", MUTED
		elseif now >= nextAt then
			text, colour = "READY", READY
		else
			text, colour = "NEXT IN " .. clock(nextAt - now), MUTED
		end
		for _, face in ipairs(b.faces) do
			face.status.Text = text
			face.status.TextColor3 = colour
		end
		local prompt = b.prompt
		if prompt then
			prompt.Enabled = ready
		end
		local glow = b.glow
		if glow then
			glow.Enabled = ready
		end
		-- Up through the cooldown too (2026-10-01), with this player's state
		-- under it -- but never for a player the chest is locked to: READY TO
		-- CLAIM! is the prompt's own answer, `ready`, and nothing else.
		local W = CHEST.FloatingWords
		local sub = b.words.sub
		if sub then
			if ready then
				sub.Text, sub.TextColor3 = W.ReadyText, READY
			elseif pending then
				sub.Text, sub.TextColor3 = W.OpeningText, GOLD
			else
				sub.Text, sub.TextColor3 = W.WaitText .. clock(nextAt - now), CREAM
			end
		end
		b.words.setShown(unlocked)
	end
	-- The boost itself is BoostIconsUI's icon, drawn from the same attributes.
end

--==============================================================================
-- THE CHEST, WHICH IS PERSISTENT UNDER STREAMING BUT STILL ARRIVES LATE
--==============================================================================
if CHEST.Enabled then
	task.spawn(function()
		local folder = Workspace:WaitForChild(CHEST.FolderName, math.huge)
		local chest = folder:WaitForChild("BonusChest", math.huge)
		if chest and chest:IsA("Model") then
			chest:WaitForChild("Body", 10)
			built = build(chest)
			paint()
		end
	end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
	local b = built
	if who == player and b and prompt == b.prompt then
		pending = true
		pendingSince = Workspace:GetServerTimeNow()
		paint()
	end
end)

--==============================================================================
-- THE REWARD, MADE OBVIOUS (2026-10-01, the owner's ask)
--
-- On a claim the server confirmed, and only then: RewardSplash shows the
-- reward it NAMED -- the wheel's own icon for that boost, its title, and how
-- long it runs -- then flies the icon to that reward's line in THE ROW (which
-- the attributes have put up by then) and nudges it. No line on screen, and
-- the icon fades where it is. Reduced motion: no flight (RewardSplash).
--
-- ONCE PER CLAIM. A claim's answer carries its own next-claim time, which no
-- other claim shares (they are CooldownSeconds apart), so the same answer
-- delivered again shows nothing. The splash plays the success notice's sound;
-- the notice itself is only what is shown if the splash cannot draw.
--==============================================================================
local lastClaimShown: string? = nil

local function splash(reward: any): boolean
	local id = reward.Id
	local icon = nil
	for _, r in ipairs(WheelData.Rewards) do
		if r.kind == "boost" and r.boost == id then
			icon = r
		end
	end
	local minutes = CHEST.BoostSeconds / 60
	local ok, played = pcall(RewardSplash.play, {
		layer = gui,
		heading = "BONUS CHEST",
		reduced = StatusText.reducedMotion(),
		items = {
			{
				draw = function(parent: Frame, px: number)
					if icon then
						local drawn = WheelDraw.icon(parent, icon, px)
						drawn.box.Position = UDim2.fromScale(0.5, 0.5)
					else
						local glyph = StatusText.icon(parent, "boost", BOOST_TINT[id] or GOLD, px)
						glyph.AnchorPoint = Vector2.new(0.5, 0.5)
						glyph.Position = UDim2.fromScale(0.5, 0.5)
					end
				end,
				title = reward.Title,
				detail = if minutes == math.floor(minutes)
					then string.format("BOOST FOR %d MIN", minutes)
					else "BOOST FOR " .. clock(CHEST.BoostSeconds),
				tint = BOOST_TINT[id] or GOLD,
				destination = function(): GuiObject?
					local icon = boostIcon(id)
					if not icon then
						return nil
					end
					local mark = icon:FindFirstChild("Icon", true)
					return if mark and mark:IsA("GuiObject") then mark else icon
				end,
				landed = function()
					-- A short bump of the icon it landed on.
					local icon = boostIcon(id)
					local pop = icon and icon:FindFirstChild("Pop")
					if pop and pop:IsA("UIScale") and not StatusText.reducedMotion() then
						local rest = pop.Scale
						pop.Scale = rest * 1.25
						TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
							{ Scale = rest }):Play()
					end
				end,
			},
		},
	})
	if not (ok and played == true) then
		return false
	end
	if SoundKit.has("NoticeSuccess") then
		SoundKit.play("NoticeSuccess")
	end
	return true
end

local remotes = SeedGame:WaitForChild("Remotes")
local channel = remotes:WaitForChild(GameConfig.Remotes.GameEvent)
if channel:IsA("RemoteEvent") then
	channel.OnClientEvent:Connect(function(action: any, payload: any)
		if action ~= CHEST.ReplyAction or type(payload) ~= "table" then
			return
		end
		pending = false
		if payload.ok == true then
			local reward = GameConfig.bonusChestReward(payload.reward)
			local key = string.format("%s:%s", tostring(payload.nextAt), tostring(payload.reward))
			if key ~= lastClaimShown then
				lastClaimShown = key
				if not (reward and splash(reward)) then
					Notice.post({
						kind = "success",
						icon = "chest",
						title = if reward then reward.Title else "BONUS CHEST",
						detail = string.format("Bonus Chest reward for %s.", clock(CHEST.BoostSeconds)),
						key = "chest:ok",
					})
				end
			end
		else
			local reason = tostring(payload.reason)
			local words = REFUSED[reason]
			if words then
				local detail = words.detail
				if reason == "COOLDOWN" then
					local nextAt = tonumber(payload.nextAt)
					if nextAt then
						detail = "Next one in " .. clock(nextAt - Workspace:GetServerTimeNow()) .. "."
					end
				end
				Notice.post({ kind = "blocked", title = words.title, detail = detail, key = "chest:" .. reason })
			end
		end
		paint()
	end)
end

for _, name in pairs(ATTR) do
	player:GetAttributeChangedSignal(name):Connect(paint)
end
task.spawn(function()
	while gui.Parent do
		paint()
		task.wait(0.5)
	end
end)
