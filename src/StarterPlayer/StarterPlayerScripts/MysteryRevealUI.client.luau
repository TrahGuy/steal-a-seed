--!strict
--==============================================================================
-- Steal a Seed :: MysteryRevealUI (2026-10-11, Enchanted Mist stage 4)
--
-- THE MYSTERIOUS POD'S CARD DRAWS (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-
-- PROMPT.md §11), for this family only -- never the retired hatch cards.
--
-- After the server has hatched a Mysterious Pod exactly once and saved what
-- came out (MysteryPodService.TellHatch, to its owner alone), a compact
-- studded strip at the top of the screen reels the pool's creature cards and
-- lands on the SAVED creature; for Legendary to Divine a second reel lands on
-- the SAVED size; a Secret skips it ("A SECRET!"). Then the world reveal
-- (HatchFX) plays as for any hatch, Shell.ReelSeconds after it began. The
-- client decides nothing: the reel's filler order comes from the hatch's own
-- token, and it always lands where the server said. No camera is touched.
-- Reduced Motion: the cards appear already landed.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))

local CFG = EnchantedMistConfig.Mystery
local W = CFG.Words
local LOOK = GameConfig.StuddedLook
local INK = Color3.fromRGB(14, 10, 18)
local WHITE = Color3.fromRGB(255, 255, 255)
local CARD_W, CARD_H, GAP = 104, 140, 8
local CHIP_W, CHIP_H = 96, 84
local Z = 4
-- The slot each reel lands on; filler after it fills the window's right side.
local LAND = 12

local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local existing = playerGui:FindFirstChild("SeedMysteryReveal")
if existing then
	existing:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedMysteryReveal"
gui.ResetOnSpawn = false
-- Over the panels (Sacrifice 37), under the RUN alarm (50).
gui.DisplayOrder = 38
gui.Enabled = false
gui.Parent = playerGui

-- The studded panel (the kit's texture over white, edged in the moss band).
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.08, 0)
panel.Size = UDim2.new(0.92, 0, 0, 216)
panel.BackgroundColor3 = WHITE
panel.ZIndex = Z
panel.Parent = gui
local panelMax = Instance.new("UISizeConstraint")
panelMax.MaxSize = Vector2.new(460, 216)
panelMax.Parent = panel
UIKit.corner(panel, 16)
local edge = Instance.new("UIStroke")
edge.Thickness = 4
edge.Color = EnchantedMistConfig.Mosskeeper.Look.Edge
edge.Parent = panel
local texture = Instance.new("ImageLabel")
texture.Name = "StudTexture"
texture.Size = UDim2.fromScale(1, 1)
texture.BackgroundTransparency = 1
texture.Image = LOOK.Texture
texture.ScaleType = Enum.ScaleType.Tile
texture.TileSize = UDim2.fromOffset(LOOK.Tile, LOOK.Tile)
texture.ImageTransparency = LOOK.BodyStuds
texture.ZIndex = Z
texture.Parent = panel
UIKit.corner(texture, 16)

local title = MenuKit.heading(panel, "Title", 24, EnchantedMistConfig.Mosskeeper.Look.Band, Z + 2)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0, 6)
title.Size = UDim2.new(1, -20, 0, 30)

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0)
window.Position = UDim2.new(0.5, 0, 0, 42)
window.Size = UDim2.new(1, -20, 0, CARD_H + 12)
window.BackgroundTransparency = 1
window.ClipsDescendants = true
window.ZIndex = Z + 1
window.Parent = panel
-- Where the reel lands: a notch at the window's top and bottom (clear of the
-- card's words).
for _, edgeY in ipairs({ 0, 1 }) do
	local marker = Instance.new("Frame")
	marker.Name = if edgeY == 0 then "MarkerTop" else "MarkerBottom"
	marker.AnchorPoint = Vector2.new(0.5, edgeY)
	marker.Position = UDim2.fromScale(0.5, edgeY)
	marker.Size = UDim2.fromOffset(12, 8)
	marker.BackgroundColor3 = Color3.fromRGB(150, 255, 196)
	marker.BorderSizePixel = 0
	marker.ZIndex = Z + 20
	marker.Parent = window
	local markerLine = Instance.new("UIStroke")
	markerLine.Thickness = 1.5
	markerLine.Color = INK
	markerLine.Parent = marker
end

local strip = Instance.new("Frame")
strip.Name = "Strip"
strip.BackgroundTransparency = 1
strip.Size = UDim2.new(0, 0, 1, 0)
strip.ZIndex = Z + 1
strip.Parent = window

local fx: { any } = {}
local moving: { any } = {}
local stopMoving: (() -> ())? = nil
local tween: Tween? = nil
local playing = 0

local function clear()
	if tween then
		tween:Cancel()
		tween = nil
	end
	if stopMoving then
		stopMoving()
		stopMoving = nil
	end
	table.clear(moving)
	for _, h in ipairs(fx) do
		RarityFX.setActive(h, false)
		RarityFX.forget(h)
	end
	table.clear(fx)
	for _, c in ipairs(strip:GetChildren()) do
		c:Destroy()
	end
	strip.Position = UDim2.new()
end

-- The pool entry a species id names (its card's words), or one from SeedData.
local function entryFor(id: string, rarity: string?): any
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		if e.Id == id then
			return e
		end
	end
	local s = SeedData.Get(id)
	return { Id = id, Name = if s then s.Name else id, Rarity = rarity or (if s then s.Rarity else "Common") }
end

-- Lay `count` items in the strip, item `land` the answer (filler both sides of
-- it), and slide it under the notches.
local function reel(count: number, land: number, width: number, build: (index: number, slot: Frame) -> (),
	seconds: number)
	strip.Size = UDim2.new(0, count * (width + GAP), 1, 0)
	for i = 1, count do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.BackgroundTransparency = 1
		slot.Position = UDim2.new(0, (i - 1) * (width + GAP), 0, 6)
		slot.Size = UDim2.new(0, width, 1, -12)
		slot.ZIndex = Z + 2
		slot.Parent = strip
		build(i, slot)
	end
	-- Item i's centre at the window's centre.
	local function at(i: number): UDim2
		return UDim2.new(0.5, -width / 2 - (i - 1) * (width + GAP), 0, 0)
	end
	if StatusText.reducedMotion() or seconds <= 0 then
		strip.Position = at(land)
		return
	end
	strip.Position = at(1)
	local t = TweenService:Create(strip, TweenInfo.new(seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = at(land) })
	tween = t
	t:Play()
end

local function play(payload: any)
	local species = tostring(payload.species)
	local size = tonumber(payload.size)
	local seconds = math.clamp(tonumber(payload.seconds) or EnchantedMistData.Shell.ReelSeconds, 1, 10)
	local token = math.floor(tonumber(payload.token) or 0)
	playing += 1
	local mine = playing
	clear()
	gui.Enabled = true
	local sized = size ~= nil and EnchantedMistData.isSized(tostring(payload.rarity))
	local creatureSeconds = if sized then seconds * 0.5 else seconds * 0.75
	title.Text = W.Creature
	-- The filler: drawn by the pool's own odds from the hatch's token (mostly
	-- the commonest, the Secrets rarest), so the reel never misstates them.
	-- The answer is always card LAND.
	local ids = {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		table.insert(ids, e.Id)
	end
	local rng = Random.new(token)
	local count = 17
	local items = MistOddsView.reelItems(count, LAND, species, function()
		return EnchantedMistData.pickCreature(rng:NextNumber()).Id
	end, ids)
	local views = {}
	reel(count, LAND, CARD_W, function(i, slot)
		local e = if i == LAND then entryFor(species, payload.rarity) else entryFor(items[i])
		-- Only the cards seen as the reel slows get their creature drawn (the
		-- rest pass in a blur): a handful of models, never the whole strip.
		local near = i >= LAND - 4 and i <= LAND + 2
		local card = MistOddsView.card(slot, e, Z + 2, CARD_H, moving, fx, if near then views else {})
		card.Size = UDim2.fromScale(1, 1)
	end, creatureSeconds)
	-- The creatures that exist stand in their windows, as on the Odds page.
	MistOddsView.drawViews(views)
	for _, h in ipairs(fx) do
		RarityFX.setActive(h, true)
	end
	stopMoving = MistOddsView.animate(moving)
	task.delay(creatureSeconds + 0.15, function()
		if mine ~= playing then
			return
		end
		if not sized then
			if payload.rarity == "Secret" then
				title.Text = W.Secret
			end
			return
		end
		clear()
		title.Text = W.Size
		local tiers = SeedData.Tiers
		-- The filler by the size odds, as the creatures' by theirs.
		local all = {}
		for tier = 1, #EnchantedMistData.Sizes.Weights do
			table.insert(all, tier)
		end
		local sizeRng = Random.new(token + 1)
		local chips = 15
		local items = MistOddsView.reelItems(chips, LAND, size, function()
			return EnchantedMistData.pickSize(sizeRng:NextNumber())
		end, all)
		reel(chips, LAND, CHIP_W, function(i, slot)
			local tier = items[i] :: number
			local t = tiers[tier]
			local colour = if t then t.color else WHITE
			local chip = MenuKit.frame(slot, "Chip", Z + 3, colour, 0, 10)
			chip.AnchorPoint = Vector2.new(0.5, 0.5)
			chip.Position = UDim2.fromScale(0.5, 0.5)
			chip.Size = UDim2.new(1, 0, 0, CHIP_H)
			MenuKit.keyline(chip, INK, 2)
			UIKit.studs(chip, { pitch = 12, size = 6, inset = 3, face = colour:Lerp(WHITE, 0.25),
				shade = colour:Lerp(INK, 0.35), zIndex = Z + 4 })
			-- Its odds at the card's top edge, as on every card here.
			local pct = MistOddsView.sizeWords(chip, "Chance", 18, tier, Z + 6, moving)
			pct.AnchorPoint = Vector2.new(0.5, 0)
			pct.Position = UDim2.new(0.5, 0, 0, 4)
			pct.Size = UDim2.new(1, -8, 0, 20)
			local word = MenuKit.text(chip, "Size", 20, WHITE, Z + 6)
			word.AnchorPoint = Vector2.new(0.5, 1)
			word.Position = UDim2.new(0.5, 0, 1, -10)
			word.Size = UDim2.new(1, -8, 0, 28)
			word.Text = if t then t.name else tostring(tier)
			local stroke = word:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = INK
			end
		end, seconds - creatureSeconds - 0.4)
		stopMoving = MistOddsView.animate(moving)
	end)
	task.delay(seconds + 0.6, function()
		if mine == playing then
			clear()
			gui.Enabled = false
		end
	end)
end

channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action == CFG.Action and type(payload) == "table" and payload.phase == "hatch" then
		play(payload)
	end
end)
