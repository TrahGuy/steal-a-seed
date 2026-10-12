--!strict
--==============================================================================
-- Steal a Seed :: MysteryRevealUI (2026-10-11, Enchanted Mist stage 4)
--
-- THE MYSTERIOUS POD'S CARD DRAWS (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-
-- PROMPT.md §11), for this family only -- never the retired hatch cards.
--
-- After the server has hatched a Mysterious Pod exactly once and saved what
-- came out (MysteryPodService.TellHatch, to its owner alone), the creature
-- cards run across the screen and land on the SAVED creature; for Legendary to
-- Divine a second reel lands on the SAVED size once the landed creature has
-- held a moment to be read; a Secret skips it ("A SECRET!"). Then the world
-- reveal (HatchFX) plays as for any hatch, at the draw's end. The client
-- decides nothing: the reel's filler order comes from the hatch's own token,
-- and it always lands where the server said. No camera is touched.
--
-- 2026-10-12, the owner:
--   THE LOOK      no panel: the cards run over a slight dimmer covering the
--                 whole screen, notches too; the titles outlined over it.
--   THE PLACE     the cards up to 1.3x, centred between the HUD's top row
--                 and the belt (MistOddsView.drawPlace), SKIP beside the
--                 title; a draw is a moment the guide's words stand down for
--                 (RewardMoments.MysteryDraw).
--   THE PACE      each reel spins EnchantedMistData.Shell.SpinSeconds (at
--                 least 5 s), slowing onto its card the whole way, over about
--                 twice the cards it had.
--   EVERY DRAW    "sometimes the draw doesn't run, it auto chooses": a second
--                 hatch cut the running draw short, and Performance Mode (which
--                 forces Reduced FX) landed every draw at once. Now each draw
--                 waits its turn -- the server reserves them one after another
--                 (MysteryPodService.Reserve) and says when each starts -- and
--                 only the player's OWN Reduced FX, or Roblox's Reduced Motion,
--                 lands the cards at once.
--   SKIP          a small SKIP (or the pad's B) jumps this draw to its landed
--                 cards, each held a moment; the server's result and timing
--                 are untouched, and the next draw starts at its own time.
--==============================================================================
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
local PerformanceMode = require(Shared:WaitForChild("PerformanceMode"))
local Notice = require(Shared:WaitForChild("Notice"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local RewardMoments = require(Shared:WaitForChild("RewardMoments"))

local CFG = EnchantedMistConfig.Mystery
local W = CFG.Words
local INK = Color3.fromRGB(14, 10, 18)
local WHITE = Color3.fromRGB(255, 255, 255)
local CARD_W, CARD_H, GAP = 104, 140, 8
local CHIP_W, CHIP_H = 96, 84
-- The title's row (SKIP at its right end); the window under it.
local TITLE_ROW = 44
local Z = 4
-- Each reel's cards and the one it lands on, filler after it filling the
-- window's right side: about twice the cards since the reels spin 5.5 s.
local CREATURE_COUNT, CREATURE_LAND = 34, 30
local SIZE_COUNT, SIZE_LAND = 30, 26
-- How long each landed card holds after a SKIP, and when SKIP may be pressed
-- (never by the hatch press itself).
local SKIP_HOLD = 0.8
local SKIP_AFTER = 0.5

local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

for _, name in ipairs({ "SeedMysteryReveal", "SeedMysteryRevealMeasure" }) do
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end
-- A re-run mid-draw leaves no moment standing.
RewardMoments.finish(RewardMoments.MysteryDraw)
local gui = Instance.new("ScreenGui")
gui.Name = "SeedMysteryReveal"
gui.ResetOnSpawn = false
-- Over the panels (Sacrifice 37), the rail's buttons (40) and the HUD cards
-- (42), so the dimmer covers the whole screen as the owner asked; under the
-- guides (45), the announcements (47), the notices (49) and the RUN alarm (50).
-- The rail stays pressable: the dimmer takes no input. The whole screen,
-- notches too (IgnoreGuiInset alone stops at the safe insets).
gui.DisplayOrder = 44
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None
gui.Enabled = false
gui.Parent = playerGui

-- THE DIMMER: a dark sheet over everything, a little see-through; no
-- CanvasGroup (its transparency ghosts). It takes no input.
local scrim = Instance.new("Frame")
scrim.Name = "Scrim"
scrim.Size = UDim2.fromScale(1, 1)
scrim.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
scrim.BackgroundTransparency = 0.55
scrim.BorderSizePixel = 0
scrim.Active = false
scrim.ZIndex = Z - 2
scrim.Parent = gui
-- The draw wins the notices' band: a notice gives way until it has gone (the
-- owner, 2026-10-12; Notice.band).
Notice.band("mystery-draw", "over", scrim)

-- THE STAGE (2026-10-12, the owner: the cards bigger, the strip lower, not
-- hugging the top row): MistOddsView.DrawStage at 1 -- the title's row, then
-- the window -- scaled and centred between the HUD's top row and the belt
-- (MistOddsView.drawPlace; placeStage, below).
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, 0.5)
stage.Size = UDim2.fromOffset(MistOddsView.DrawStage.X, MistOddsView.DrawStage.Y)
stage.BackgroundTransparency = 1
stage.ZIndex = Z
stage.Parent = gui
local stageScale = Instance.new("UIScale")
stageScale.Parent = stage

-- The title, outlined over the dimmer, in its row's middle: SKIP's room on
-- either side.
local title = MenuKit.heading(stage, "Title", 26, WHITE, Z + 2)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.new(0.5, 0, 0, TITLE_ROW / 2)
title.Size = UDim2.new(1, -2 * 112, 0, 32)
local titleEdge = title:FindFirstChildOfClass("UIStroke") or UIKit.stroke(title, INK, 3)
titleEdge.Color = INK
titleEdge.Thickness = 3

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0)
window.Position = UDim2.new(0.5, 0, 0, TITLE_ROW + 6)
window.Size = UDim2.new(1, -20, 0, CARD_H + 12)
window.BackgroundTransparency = 1
window.ClipsDescendants = true
window.ZIndex = Z + 1
window.Parent = stage
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

-- OPEN ALL's grid (2026-10-12, the owner's item 17): in the window's place, one
-- tile per creature that came out; hidden otherwise (playGrid).
local grid = Instance.new("Frame")
grid.Name = "Grid"
grid.AnchorPoint = Vector2.new(0.5, 0)
grid.Position = UDim2.new(0.5, 0, 0, TITLE_ROW + 6)
grid.Size = UDim2.new(1, -20, 0, CARD_H + 12)
grid.BackgroundTransparency = 1
grid.Visible = false
grid.ZIndex = Z + 1
grid.Parent = stage

-- SKIP (2026-10-12, the owner): a small pill at the right end of the title's
-- row -- clear of the cards, the title, the belt and a phone's thumbs -- at its
-- own size whatever the stage's scale (sizeSkip). Shown SKIP_AFTER into a draw
-- that moves.
local skipButton = Instance.new("TextButton")
skipButton.Name = "Skip"
skipButton.AnchorPoint = Vector2.new(1, 0.5)
skipButton.Position = UDim2.new(1, -8, 0, TITLE_ROW / 2)
skipButton.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
skipButton.BackgroundTransparency = 0.15
skipButton.AutoButtonColor = true
skipButton.Font = Enum.Font.LuckiestGuy
skipButton.Text = "SKIP"
skipButton.TextColor3 = WHITE
skipButton.TextSize = 16
skipButton.Visible = false
skipButton.ZIndex = Z + 6
skipButton.Parent = stage
UIKit.corner(skipButton, 14)
UIKit.stroke(skipButton, Color3.fromRGB(150, 255, 196), 1.5)

-- SKIP at its own size whatever the stage's scale: a touch screen's 96 x 44.
local function sizeSkip()
	local s = math.max(stageScale.Scale, 0.01)
	local nominal = if UserInputService.TouchEnabled then Vector2.new(96, 44) else Vector2.new(84, 34)
	skipButton.Size = UDim2.fromOffset(nominal.X / s, nominal.Y / s)
	skipButton.TextSize = 16 / s
end

-- Where the stage stands: read off the HUD's own layout through an empty gui
-- with the HUD's insets (MosskeeperUI's way), on every change of screen and at
-- each draw's start.
local measureGui = Instance.new("ScreenGui")
measureGui.Name = "SeedMysteryRevealMeasure"
measureGui.ResetOnSpawn = false
measureGui.IgnoreGuiInset = false
measureGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
UIKit.tenFoot(measureGui)
measureGui.Parent = playerGui

local function placeStage()
	local size = gui.AbsoluteSize
	if size.X <= 0 or measureGui.AbsoluteSize.X <= 0 then
		return
	end
	local L = HudLayout.solve(HudLayout.measure(measureGui))
	local scale, centre = MistOddsView.drawPlace(L, size, measureGui.AbsolutePosition - gui.AbsolutePosition,
		HudLayout.scaleOf(measureGui))
	stageScale.Scale = scale
	stage.Position = UDim2.fromOffset(centre.X, centre.Y)
	sizeSkip()
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeStage)
measureGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeStage)
placeStage()

local fx: { any } = {}
local moving: { any } = {}
local stopMoving: (() -> ())? = nil
local tween: Tween? = nil
-- The moving reel's stop, for a SKIP: it lands where it was going at once.
local landNow: (() -> ())? = nil
local playing = 0

local function clear()
	landNow = nil
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
	for _, c in ipairs(grid:GetChildren()) do
		c:Destroy()
	end
	grid.Visible = false
	window.Visible = true
end

-- ONLY AN EXPLICIT REDUCED MOTION lands the cards at once: the player's own
-- Reduced FX (PerformanceMode.ownReduced -- never the one Performance Mode
-- forces) or Roblox's own setting.
local function snapping(): boolean
	if PerformanceMode.ownReduced(player) then
		return true
	end
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
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
-- it), and slide it under the notches over `seconds` -- or set it there at once
-- (`seconds` 0: a snap). It brakes evenly (Quad), a wheel's way, so it moves
-- the whole spin and stops as CARD LANDS plays (a Quint stood still for its
-- last second and a half). `near`, if given, hears each frame which item is
-- under the notches (and the landed one when it stops). While it moves,
-- `landNow` stops it on its answer at once (a SKIP): the same cards, nothing
-- built again.
local function reel(count: number, land: number, width: number, build: (index: number, slot: Frame) -> (),
	seconds: number, near: ((centred: number, all: boolean) -> ())?)
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
	-- Stopped on the answer: the cards about it built, and CARD LANDS.
	local function stop()
		landNow = nil
		strip.Position = at(land)
		if near then
			near(land, true)
		end
		SoundKit.play("MistCardLands")
	end
	if seconds <= 0 then
		stop()
		return
	end
	strip.Position = at(1)
	if near then
		near(1, true)
	end
	local t = TweenService:Create(strip, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = at(land) })
	tween = t
	-- The Enchanted Mist's REEL TICK for every card that passes the notches (the
	-- one centred changes), and CARD LANDS when it stops there -- a reel cut
	-- short (cleared, or landed by a SKIP) says nothing more of its own.
	local pitch = width + GAP
	local centred = 1
	local ticking = RunService.RenderStepped:Connect(function()
		local i = math.floor((-strip.Position.X.Offset - width / 2) / pitch + 0.5) + 1
		if i ~= centred then
			centred = i
			SoundKit.play("MistReelTick")
		end
		if near then
			near(i, false)
		end
	end)
	t.Completed:Once(function(state: Enum.PlaybackState)
		ticking:Disconnect()
		if state == Enum.PlaybackState.Completed then
			landNow = nil
			SoundKit.play("MistCardLands")
		end
	end)
	landNow = function()
		ticking:Disconnect()
		t:Cancel()
		stop()
	end
	t:Play()
end

-- THE CREATURE REEL: filler drawn by the pool's own odds from the hatch's token
-- (mostly the commonest, the Secrets rarest), so the reel never misstates
-- them; the answer is always card CREATURE_LAND.
local function creatureReel(payload: any, seconds: number)
	local species = tostring(payload.species)
	local token = math.floor(tonumber(payload.token) or 0)
	local ids = {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		table.insert(ids, e.Id)
	end
	local rng = Random.new(token)
	local items = MistOddsView.reelItems(CREATURE_COUNT, CREATURE_LAND, species, function()
		return EnchantedMistData.pickCreature(rng:NextNumber()).Id
	end, ids)
	-- Each card's creature is built as the card comes up to the notches -- the
	-- window's own at once, then at most two a frame -- so every card the spin
	-- shows stands its creature (a 5.5 s spin is no blur), with no hitch for the
	-- whole strip at once (each is a model). They stand on their cards' studs,
	-- as on the Odds page.
	local views: { { any } } = {}
	local function near(centred: number, all: boolean)
		local made = 0
		for k = math.max(1, centred - 2), math.min(CREATURE_COUNT, centred + 3) do
			local list = views[k]
			if list and list[1] and not list[1].built then
				MistOddsView.drawViews(list)
				made += 1
				if made >= 2 and not all then
					return
				end
			end
		end
	end
	reel(CREATURE_COUNT, CREATURE_LAND, CARD_W, function(i, slot)
		local e = if i == CREATURE_LAND then entryFor(species, payload.rarity) else entryFor(items[i])
		views[i] = {}
		local card = MistOddsView.card(slot, e, Z + 2, CARD_H, moving, fx, views[i])
		card.Size = UDim2.fromScale(1, 1)
	end, seconds, near)
	for _, h in ipairs(fx) do
		RarityFX.setActive(h, true)
	end
	stopMoving = MistOddsView.animate(moving)
end

-- THE SIZE REEL, its filler by the size odds as the creatures' by theirs.
local function sizeReel(payload: any, seconds: number)
	local size = tonumber(payload.size) or 1
	local token = math.floor(tonumber(payload.token) or 0)
	local tiers = SeedData.Tiers
	local all = {}
	for tier = 1, #EnchantedMistData.Sizes.Weights do
		table.insert(all, tier)
	end
	local sizeRng = Random.new(token + 1)
	local items = MistOddsView.reelItems(SIZE_COUNT, SIZE_LAND, size, function()
		return EnchantedMistData.pickSize(sizeRng:NextNumber())
	end, all)
	reel(SIZE_COUNT, SIZE_LAND, CHIP_W, function(i, slot)
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
	end, seconds)
	stopMoving = MistOddsView.animate(moving)
end

--==============================================================================
-- EACH DRAW IN ITS TURN (2026-10-12)
--
-- Draws arrive as their pods hatch; each plays whole, from its own start: at
-- the server's `startAt` (MysteryPodService.Reserve), or at once if that has
-- passed. Item 17's OPEN ALL is its own reveal -- one grid, not a draw each --
-- booked and queued the same way (playGrid).
--==============================================================================
local queue: { any } = {}
local busy = false
local skipTo: (() -> ())? = nil
local runNext: () -> ()

local function finish(mine: number)
	if mine ~= playing then
		return
	end
	playing += 1
	skipTo = nil
	skipButton.Visible = false
	ContextActionService:UnbindAction("SeedMysterySkip")
	clear()
	gui.Enabled = false
	RewardMoments.finish(RewardMoments.MysteryDraw)
	runNext()
end

local function play(payload: any)
	playing += 1
	local mine = playing
	clear()
	placeStage()
	gui.Enabled = true
	-- A moment: the guide's words stand down until it closes (TutorialUI).
	RewardMoments.begin(RewardMoments.MysteryDraw)
	local sized = tonumber(payload.size) ~= nil and EnchantedMistData.isSized(tostring(payload.rarity))
	local secret = payload.rarity == "Secret"
	local snap = snapping()
	-- The landed creature holds before the size reel: reelTimes.
	local times = EnchantedMistData.reelTimes(sized)
	local sizing = false
	title.Text = W.Creature
	creatureReel(payload, if snap then 0 else times.creature)
	task.delay(times.next, function()
		if mine ~= playing then
			return
		end
		if not sized then
			if secret then
				title.Text = W.Secret
				SoundKit.play("MistSecret")
			end
			return
		end
		clear()
		sizing = true
		title.Text = W.Size
		sizeReel(payload, if snap then 0 else times.sizeSpin)
	end)
	task.delay(times.close, finish, mine)
	-- SKIP: the reel on screen lands at once where it was going -- the same
	-- cards, nothing built again (a rebuild of every card hitched) -- and each
	-- landed card holds SKIP_HOLD: the creature's, then a sized one's size;
	-- pressed on the size reel, only the size. Then the draw closes. Not where
	-- the cards already land at once.
	skipTo = function()
		if mine ~= playing then
			return
		end
		playing += 1
		local skipped = playing
		skipButton.Visible = false
		ContextActionService:UnbindAction("SeedMysterySkip")
		local land = landNow
		if land then
			land()
		end
		if secret and title.Text ~= W.Secret then
			title.Text = W.Secret
			SoundKit.play("MistSecret")
		end
		task.delay(SKIP_HOLD, function()
			if skipped ~= playing then
				return
			end
			if sizing or not sized then
				finish(skipped)
				return
			end
			clear()
			title.Text = W.Size
			sizeReel(payload, 0)
			task.delay(SKIP_HOLD, finish, skipped)
		end)
	end
	skipButton.Visible = false
	if not snap then
		task.delay(SKIP_AFTER, function()
			if mine ~= playing then
				return
			end
			sizeSkip()
			skipButton.Visible = true
			ContextActionService:BindActionAtPriority("SeedMysterySkip", function(_, state)
				if state == Enum.UserInputState.Begin and skipTo then
					skipTo()
				end
				return Enum.ContextActionResult.Sink
			end, false, 3000, Enum.KeyCode.ButtonB)
		end)
	end
end

skipButton.Activated:Connect(function()
	if skipTo then
		skipTo()
	end
end)

--==============================================================================
-- OPEN ALL (2026-10-12, the owner's item 17): every ready Mysterious Pod opened
-- at once (PlantService.OpenAllMystery) -- no draw each, ONE grid of what came
-- out, held for the server's `seconds`: a tile per creature, rarest first, its
-- count and its best size on it, the rarest edged in gold. It waits its turn
-- like a draw (the server booked it after any still running); SKIP closes it.
--==============================================================================
local OPEN = CFG.OpenAll
local GOLD = Color3.fromRGB(255, 214, 92)

local function playGrid(payload: any)
	playing += 1
	local mine = playing
	clear()
	placeStage()
	gui.Enabled = true
	RewardMoments.begin(RewardMoments.MysteryDraw)
	window.Visible = false
	grid.Visible = true
	-- Each creature once: how many, and the sizes they came at.
	type Kind = { entry: any, count: number, best: number? }
	local kinds: { [string]: Kind } = {}
	local order: { Kind } = {}
	local total, secret = 0, false
	for _, o in ipairs(if type(payload.outcomes) == "table" then payload.outcomes else {}) do
		local id = tostring(o.species)
		local kind = kinds[id]
		if not kind then
			kind = { entry = entryFor(id, o.rarity), count = 0, best = nil }
			kinds[id] = kind
			table.insert(order, kind)
		end
		kind.count += 1
		total += 1
		local size = tonumber(o.size)
		if size and (kind.best == nil or size > (kind.best :: number)) then
			kind.best = size
		end
		secret = secret or o.rarity == "Secret"
	end
	-- Rarest first: the pool's own weights, the lightest the rarest.
	local weight: { [string]: number } = {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		weight[e.Id] = e.Weight
	end
	table.sort(order, function(a, b)
		return (weight[a.entry.Id] or math.huge) < (weight[b.entry.Id] or math.huge)
	end)
	title.Text = string.format(W.Opened, total)
	-- The tiles side by side, as wide as the window lets them be.
	local n = math.max(#order, 1)
	local room = (stage.Size.X.Offset - 20 - (n - 1) * GAP) / n
	local scale = math.min(1, room / CARD_W)
	local tileW = CARD_W * scale
	local x0 = ((stage.Size.X.Offset - 20) - (n * tileW + (n - 1) * GAP)) / 2
	local views = {}
	for i, kind in ipairs(order) do
		local slot = Instance.new("Frame")
		slot.Name = "Tile" .. i
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromOffset(CARD_W, CARD_H)
		slot.Position = UDim2.fromOffset(x0 + (i - 1) * (tileW + GAP), (CARD_H + 12 - CARD_H * scale) / 2)
		slot.ZIndex = Z + 2
		slot.Parent = grid
		local fit = Instance.new("UIScale")
		fit.Scale = scale
		fit.Parent = slot
		local card = MistOddsView.card(slot, kind.entry, Z + 2, CARD_H, moving, fx, views)
		card.Size = UDim2.fromScale(1, 1)
		if kind.count > 1 then
			local many = MenuKit.heading(slot, "Count", 22, WHITE, Z + 9)
			many.AnchorPoint = Vector2.new(0, 0)
			many.Position = UDim2.fromOffset(4, 22)
			many.Size = UDim2.fromOffset(60, 24)
			many.TextXAlignment = Enum.TextXAlignment.Left
			many.Text = string.format("x%d", kind.count)
		end
		local best = kind.best
		local tier = if best then SeedData.Tiers[best] else nil
		if tier then
			local chip = MenuKit.frame(slot, "Best", Z + 8, tier.color, 0, 6)
			chip.AnchorPoint = Vector2.new(1, 0)
			chip.Position = UDim2.new(1, -4, 0, 24)
			chip.Size = UDim2.fromOffset(58, 20)
			MenuKit.keyline(chip, INK, 1.5)
			local word = MenuKit.text(chip, "Size", 13, WHITE, Z + 9)
			word.Size = UDim2.fromScale(1, 1)
			word.Text = tier.name
		end
		if i == 1 and #order > 1 then
			local edge = Instance.new("UIStroke")
			edge.Color = GOLD
			edge.Thickness = 3
			edge.Parent = card
			local ribbon = MenuKit.heading(slot, "Rarest", 15, GOLD, Z + 9)
			ribbon.AnchorPoint = Vector2.new(0.5, 1)
			ribbon.Position = UDim2.new(0.5, 0, 0, -2)
			ribbon.Size = UDim2.new(1, 0, 0, 18)
			ribbon.Text = W.Rarest
		end
	end
	MistOddsView.drawViews(views)
	for _, h in ipairs(fx) do
		RarityFX.setActive(h, true)
	end
	stopMoving = MistOddsView.animate(moving)
	SoundKit.play("MistCardLands")
	if secret then
		SoundKit.play("MistSecret")
	end
	local hold = math.clamp(tonumber(payload.seconds) or OPEN.GridSeconds, 1, 10)
	task.delay(hold, finish, mine)
	-- SKIP closes the grid; everything in it is already the player's.
	skipTo = function()
		finish(mine)
	end
	skipButton.Visible = false
	if not snapping() then
		task.delay(SKIP_AFTER, function()
			if mine ~= playing then
				return
			end
			sizeSkip()
			skipButton.Visible = true
			ContextActionService:BindActionAtPriority("SeedMysterySkip", function(_, state)
				if state == Enum.UserInputState.Begin and skipTo then
					skipTo()
				end
				return Enum.ContextActionResult.Sink
			end, false, 3000, Enum.KeyCode.ButtonB)
		end)
	end
end

runNext = function()
	local payload = table.remove(queue, 1)
	if not payload then
		busy = false
		return
	end
	busy = true
	local run = if payload.phase == OPEN.Phase then playGrid else play
	local wait = (tonumber(payload.startAt) or 0) - Workspace:GetServerTimeNow()
	if wait > 0 then
		task.delay(wait, run, payload)
	else
		run(payload)
	end
end

channel.OnClientEvent:Connect(function(action: any, payload: any)
	if action == CFG.Action and type(payload) == "table" and (payload.phase == "hatch" or payload.phase == OPEN.Phase) then
		table.insert(queue, payload)
		if not busy then
			runNext()
		end
	end
end)
