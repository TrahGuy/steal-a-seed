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
--   THE RESULT   a notice through the game's shared renderer (Notice,
--                ActionToastUI, 2026-09-27): the reward as a success, or why
--                nothing happened as a blocked one. One sound, the notice's.
--   THE ROW      a compact line per running reward -- its title and the time
--                left, as text with no plate (StatusText) -- in HudLayout's
--                boost band under the clock's column, so it keeps clear of every
--                HUD control and of the chase warning above it.
--
-- THE ROW IS ALSO THE SACRIFICE PEDESTAL'S (2026-09-28). Its boost stands in the
-- same band beside the chest's, so the two are laid out by one owner and can
-- never be placed on top of each other. That is why this script keeps running
-- with the chest switched off: the row still has the pedestal to serve.
--
-- DRAWN FROM THE ATTRIBUTES, NOT THE REPLY. If the server's answer is lost the
-- attributes still arrive, and the row and sign show the reward anyway.
--==============================================================================

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Notice = require(Shared:WaitForChild("Notice"))
local StatusText = require(Shared:WaitForChild("StatusText"))

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
type Built = { model: Model, faces: { Face }, prompt: ProximityPrompt?, glow: PointLight? }
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
	return { model = sign, faces = faces, prompt = prompt, glow = glow }
end

--==============================================================================
-- THE SCREEN: THE BOOST ROW
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

--==============================================================================
-- TEXT, NOT A PILL (2026-09-27)
--
-- Each running boost is one line: the up-arrow glyph and its title in the
-- colour of the number it raises -- cash green for plant income, speed blue for
-- training, the Cash and Speed readout's own two colours -- and the time left
-- after it, smaller, in warm white and a monospaced face so the line never
-- jiggles as it counts. No plate, no capsule, no border (StatusText). It comes
-- in on the notices' short rise; after that the clock only changes its digits --
-- no motion, no sound -- and the line fades when the boost ends.
--
-- IN HudLayout's BOOST BAND: one row under the teleport slot and the biome
-- name's band (statusRows), the same place with or without a chase, a biome
-- name or TELEPORT TO PLOT, so nothing here moves when any of those comes or
-- goes. More than one boost stands side by side in it, centred; the chest
-- grants one at a time today, and the row does not mind either way.
--==============================================================================
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
-- The pedestal's boost raises the same number the chest's income reward does.
local BOOST_TINT: { [string]: Color3 } = { income = CASH_GREEN, training = SPEED_BLUE,
	sacrifice = CASH_GREEN }
-- Between two boosts in the row, at the desktop size.
local BOOST_GAP = 18

type Entry = { line: StatusText.Line, order: number }
local entries: { [string]: Entry } = {}

local function placeBoosts()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local inset = input.insetTop or 0
	--==========================================================================
	-- ON A PHONE: THE SLIM ROW RIGHT UNDER THE TOP ROW (2026-09-29)
	--
	-- The owner's report, from a phone: the boosts' names and timers stood in
	-- the middle of the screen -- and, measured the same day with the guide up,
	-- the row had been pushed down onto the belt. On a phone the row is the
	-- first thing under the clock's row (HudLayout's centre column), its lines
	-- drawn at 13 where a small window draws them at 15, and the guide's words
	-- stand in the left column, so nothing pushes it anywhere. Everywhere else
	-- it is where it was.
	--==========================================================================
	local phone = layout.sidebar and layout.columnTop ~= nil
	local k = if phone then StatusText.PhoneScale.boost
		elseif layout.compact or layout.sidebar then StatusText.SmallScale.boost
		else 1
	local _, _, band = HudLayout.statusRows(layout, inset)
	-- 8 under the guide's own words while they are up (TutorialUI publishes how
	-- far down they reach): the chest opens only after the guide, but the reward
	-- wheel can hand a new player a boost in the middle of it (2026-09-27). Not on
	-- a phone, whose guide stands beside the column rather than in it.
	local reach = player:GetAttribute(GameConfig.Attributes.TutorialReach)
	if not phone and type(reach) == "number" and band.y < reach + 8 then
		band = HudLayout.rect(band.x, reach + 8, band.w, band.h)
	end
	-- Every line still on screen, a fading one included, so a boost that ends
	-- keeps its place while it goes and the rest close up after it.
	local standing: { Entry } = {}
	for _, e in pairs(entries) do
		e.line.setScale(k)
		if e.line.frame.Visible then
			table.insert(standing, e)
		end
	end
	table.sort(standing, function(a: Entry, b: Entry): boolean
		return a.order < b.order
	end)
	local widths: { number } = {}
	for i, e in ipairs(standing) do
		widths[i] = e.line.size().X
	end
	-- Side by side on the band's middle; on a phone too narrow for that, drawn a
	-- little smaller, and stacked only where even that will not fit.
	local rows, shrink = HudLayout.boostRows(layout, band, widths, BOOST_GAP * k)
	for i, e in ipairs(standing) do
		local r = rows[i]
		if shrink ~= 1 then
			e.line.setScale(k * shrink)
		end
		local s = e.line.size()
		e.line.frame.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - layout.safe.X / 2),
			0, math.round(r.y + (r.h - s.Y) / 2 + inset))
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeBoosts)
-- The row stands under the clock's slot, which moves with the topbar's free span.
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeBoosts)
player:GetAttributeChangedSignal(GameConfig.Attributes.TutorialReach):Connect(placeBoosts)

local nextOrder = 0
local function entryFor(id: string): Entry
	local e = entries[id]
	if not e then
		nextOrder += 1
		local line = StatusText.new({
			name = "Boost_" .. id,
			parent = gui,
			size = StatusText.Size.boost,
			tint = BOOST_TINT[id] or GOLD,
			icon = "boost",
			detailSize = StatusText.Size.boostClock,
			detailFont = StatusText.ClockFont,
		})
		local made: Entry = { line = line, order = nextOrder }
		line.frame:GetPropertyChangedSignal("Visible"):Connect(placeBoosts)
		entries[id] = made
		e = made
	end
	return e :: Entry
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
	local boost = GameConfig.bonusChestReward(player:GetAttribute(ATTR.Boost))
	local endsAt = tonumber(player:GetAttribute(ATTR.EndsAt)) or 0
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
	end

	-- The boosts running now, by id: the chest's one today.
	local running: { [string]: boolean } = {}
	if boost ~= nil and now < endsAt then
		running[boost.Id] = true
		local e = entryFor(boost.Id)
		local before = e.line.size()
		-- Words only: a tick of the clock moves nothing and sounds nothing.
		e.line.set(boost.Title, StatusText.clock(endsAt - now))
		if not e.line.isShown() then
			e.line.show()
			placeBoosts()
		elseif e.line.size() ~= before then
			placeBoosts()
		end
	end
	-- The sacrifice pedestal's boost (2026-09-28), in the same row: its own
	-- line and its own clock beside the chest's, because the two end at
	-- different times. Drawn from the attributes SacrificeService publishes,
	-- like the chest's, so it is right after a rejoin with no reply to wait for.
	local sacrifice = GameConfig.sacrificeIncomeBoost(player)
	local sacrificeEnds = tonumber(player:GetAttribute(GameConfig.Sacrifice.Attributes.EndsAt)) or 0
	if sacrifice > 1 and now < sacrificeEnds then
		running.sacrifice = true
		local e = entryFor("sacrifice")
		local before = e.line.size()
		e.line.set(GameConfig.sacrificeBoostTitle(sacrifice), StatusText.clock(sacrificeEnds - now))
		if not e.line.isShown() then
			e.line.show()
			placeBoosts()
		elseif e.line.size() ~= before then
			placeBoosts()
		end
	end
	for id, e in pairs(entries) do
		if not running[id] then
			e.line.hide()
		end
	end
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
			Notice.post({
				kind = "success",
				title = if reward then reward.Title else "BONUS CHEST",
				detail = string.format("Bonus Chest reward for %s.", clock(CHEST.BoostSeconds)),
				key = "chest:ok",
			})
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
for _, name in pairs(GameConfig.Sacrifice.Attributes) do
	player:GetAttributeChangedSignal(name):Connect(paint)
end
task.spawn(function()
	while gui.Parent do
		paint()
		task.wait(0.5)
	end
end)
