--!strict
--==============================================================================
-- Steal a Seed :: HatchRollUI
--
-- THE OWNER'S CARD: WHAT WILL IT BE? (2026-09-29)
--
-- The owner's request: "When a pod finishes hatching, show a polished animation
-- that cycles through plant silhouettes with a prominent question mark, then
-- reveals the plant actually hatched. The roll must last at least 5 seconds
-- before the final reveal. Start briskly, slow toward the end, and make the
-- final plant reveal feel rewarding."
--
--==============================================================================
-- IT SHOWS A DECISION. IT DOES NOT MAKE ONE.
--
-- By the time the message that starts this arrives, the plant is in the
-- player's Backpack, on their record and out of their garden
-- (PlantService.hatch). The message names the plant; HatchRoll turns the
-- hatch's token into the order the silhouettes come up in, ending on that
-- plant. This script sends nothing, asks for nothing and is answered by
-- nothing: closing the card, dying, leaving, or an error anywhere in this file
-- costs the player a few seconds of animation and not one leaf.
--
--==============================================================================
-- WHAT IS ON THE CARD
--
--   the roll     the game's own plant card (UIKit.plantCard) with the plant's
--                biome turning over on it as silhouettes -- the Index's tint --
--                under a question mark; ???, the size the shell already showed,
--                and a line filling toward the reveal
--   the reveal   the last silhouette is the plant's own: its colour comes up,
--                the question mark goes, and the card says its name, its
--                rarity and size, what it pays, and NEW DISCOVERY when it is
--                one. The rarity's own fanfare plays, once.
--
-- NO FLASH, FEW SPARKS, QUIET TICKS. Nothing on the card blinks: a silhouette
-- slides in over a tenth of a second and none is held for less than
-- Roll.FloorHold. The reveal is a tint lifting, not a flash. Sparks are for
-- Epic and better, a dozen at most, drawn once. The tick is CardHover, the
-- quietest cue the game has. Reduced Effects keeps the card and drops the
-- motion.
--
--==============================================================================
-- ONE CARD AT A TIME, AND IT NEVER HOLDS THE PLAYER
--
-- The server gives each hatch its own window, one after another
-- (HatchRoll.schedule), and this draws them in that order. It is not a panel:
-- no scrim, nothing behind it is blocked, the stick and the camera stay the
-- player's. X -- or B on a controller -- puts it away, and everything still
-- waiting is then told in a line when its own time comes, until the run of
-- hatches is over. A centre panel opening puts it away as well.
--
-- A hatch the server marked `compact` -- one too far behind the card to wait
-- for -- is never drawn here at all: it is a line, at its time.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local HATCH = GameConfig.Plant.Hatch
local ROLL = HATCH.Roll
local HOT = GameConfig.Hotbar
local ATTR = GameConfig.Attributes
local SILHOUETTE: Color3 = GameConfig.Almanac.Silhouette
local REVEAL_FOR: { [string]: string } = (GameConfig.Sfx.RevealFor :: any)
local REVEAL_ACCENT: { [string]: string } = (GameConfig.Sfx.RevealAccentFor :: any) or {}

local GUI_NAME = "SeedHatchRoll"
local BACK_ACTION = "SeedHatchRollBack"
-- Over the HUD (rail 40, banner 45, boost row 46); under the wheel's panel (48)
-- and the RUN alarm (50).
local DISPLAY_ORDER = 47
local QUALITY_ATTRIBUTE = "SeedAfterimageQuality"

local WHITE = Color3.new(1, 1, 1)
local CREAM: Color3 = HOT.Caption
-- The world label's own two (HatchFX): what it pays, and a first discovery.
local INCOME = Color3.fromRGB(142, 214, 86)
local GOLD = Color3.fromRGB(255, 226, 120)
local CLOSE_FACE = Color3.fromRGB(216, 69, 59)
local TRACK = Color3.fromRGB(12, 16, 22)

-- The plate at a phone's size, in the gui's own units, and the plant card on it.
local PLATE = Vector2.new(340, 160)
local CARD = Vector2.new(110, 144)
-- How far the X stands out past the plate's top right corner.
local OVERHANG = 8
-- Rarities from here up get sparks at the reveal, and how many.
local SPARKS_FROM = GameConfig.RarityTier.Epic :: number
local SPARKS = { few = 8, many = 12 }

local function reduced(): boolean
	return player:GetAttribute(QUALITY_ATTRIBUTE) == "Off"
end

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

--==============================================================================
-- THE CARD, BUILT ONCE
--==============================================================================
do
	local stale = playerGui:FindFirstChild(GUI_NAME)
	if stale then
		stale:Destroy()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = DISPLAY_ORDER
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
UIKit.tenFoot(gui)

-- The hotbar's tray, which this stands over: slate, an ink border, a faint rim.
local plate = Instance.new("Frame")
plate.Name = "RollCard"
plate.AnchorPoint = Vector2.new(0.5, 0.5)
plate.Size = UDim2.fromOffset(PLATE.X, PLATE.Y)
plate.BackgroundColor3 = WHITE
-- Solid, where the tray is faintly clear: the card stands over the world's own
-- prompts and labels, and its words must not have theirs showing through.
plate.BackgroundTransparency = 0
plate.BorderSizePixel = 0
-- A press on the card stays on the card.
plate.Active = true
plate.Visible = false
plate.Parent = gui
UIKit.corner(plate, 14)
UIKit.gradient(plate, HOT.TrayTop, HOT.TrayBottom)
UIKit.stroke(plate, HOT.Ink, HOT.TrayBorder)

local plateScale = Instance.new("UIScale")
plateScale.Parent = plate

-- The rim inside the border: faint slate while the roll runs, the rarity's
-- colour once the plant is known.
local rim = Instance.new("Frame")
rim.Name = "Rim"
rim.Position = UDim2.fromOffset(4, 4)
rim.Size = UDim2.new(1, -8, 1, -8)
rim.BackgroundTransparency = 1
rim.BorderSizePixel = 0
rim.Active = false
rim.Parent = plate
UIKit.corner(rim, 11)
local rimEdge = UIKit.stroke(rim, HOT.Rim, 1.5, HOT.RimTransparency)

local card = UIKit.plantCard(plate, { name = "Plant", nameSize = 13, subSize = 10 })
card.holder.Position = UDim2.fromOffset(8, 8)
card.holder.Size = UDim2.fromOffset(CARD.X, CARD.Y)
-- A picture here, not a button: nothing to press, hover or select.
card.button.Active = false
card.button.Selectable = false
card.action.Active = false
card.action.Selectable = false
card.setStageTheme("pod")

local cardPop = Instance.new("UIScale")
cardPop.Name = "Pop"
cardPop.Parent = card.button

local question = UIKit.outlined(card.button, "Question", 64, WHITE, 3)
question.AnchorPoint = Vector2.new(0.5, 0.5)
question.Position = UDim2.fromScale(0.5, 0.4)
question.Size = UDim2.fromOffset(80, 84)
question.Text = "?"
question.Active = false
question.ZIndex = 30
local questionEdge = question:FindFirstChildOfClass("UIStroke")
local questionPop = Instance.new("UIScale")
questionPop.Parent = question

-- The words, right of the card.
local WORDS_X = CARD.X + 20
local WORDS_W = PLATE.X - WORDS_X - 12

local function words(name: string, size: number, colour: Color3, y: number, tall: number): TextLabel
	local label = UIKit.outlined(plate, name, size, colour, 2)
	label.Position = UDim2.fromOffset(WORDS_X, y)
	label.Size = UDim2.fromOffset(WORDS_W, tall)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Active = false
	label.ZIndex = 4
	return label
end

local header = words("Header", 14, CREAM, 12, 18)
header.Size = UDim2.fromOffset(WORDS_W - 34, 18)
local title = words("Name", 26, WHITE, 32, 32)
title.TextScaled = true
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 26
	fit.MinTextSize = 14
	fit.Parent = title
end
local line = words("Line", 15, CREAM, 68, 20)
local pays = words("Pays", 19, INCOME, 91, 24)
local found = words("New", 14, GOLD, 117, 18)

-- How far through the roll: a quiet line, filling.
local track = Instance.new("Frame")
track.Name = "Track"
track.Position = UDim2.fromOffset(WORDS_X, PLATE.Y - 22)
track.Size = UDim2.fromOffset(WORDS_W, 6)
track.BackgroundColor3 = TRACK
track.BackgroundTransparency = 0.25
track.BorderSizePixel = 0
track.Active = false
track.ZIndex = 4
track.Parent = plate
UIKit.corner(track, 3)
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = CREAM
fill.BorderSizePixel = 0
fill.Active = false
fill.ZIndex = 5
fill.Parent = track
UIKit.corner(fill, 3)

-- How many more are waiting their turn on this card.
local more = words("More", 12, CREAM, PLATE.Y - 40, 16)
more.TextXAlignment = Enum.TextXAlignment.Right
more.Visible = false

-- X: a thumb's worth of press (44) round a small red face, on the plate's corner.
local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, OVERHANG, 0, -OVERHANG)
close.Size = UDim2.fromOffset(44, 44)
close.BackgroundTransparency = 1
close.AutoButtonColor = false
close.Text = ""
-- B closes it on a controller; nothing on this card takes the selection.
close.Selectable = false
close.ZIndex = 40
close.Parent = plate
do
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromOffset(28, 28)
	face.BackgroundColor3 = CLOSE_FACE
	face.BorderSizePixel = 0
	face.Active = false
	face.ZIndex = 40
	face.Parent = close
	UIKit.corner(face, 14)
	UIKit.stroke(face, HOT.Ink, 2.5)
	local glyph = UIKit.outlined(face, "Glyph", 15, WHITE, 2)
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.Text = "X"
	glyph.Active = false
	glyph.ZIndex = 41
end
UIKit.clicks(close)

--==============================================================================
-- WHERE IT STANDS
--
-- In the middle, between the topbar and the hotbar, and no lower than that: on
-- a landscape phone that band is about as tall as the card. Drawn a little
-- bigger on a big screen -- by up to a quarter from 1024 x 600, the wheel's own
-- rule -- and smaller on a screen too short for it, never under four fifths.
--==============================================================================
local function place(): number
	local k = UIKit.scaleOf(gui)
	local area = gui.AbsoluteSize / k
	local W, H = area.X, area.Y
	if W <= 0 or H <= 0 then
		return plateScale.Scale
	end
	local grow = math.clamp(math.min(W / 1024, H / 600), 1, 1.25)
	-- The room the HUD leaves: over the hotbar, and between whatever stands in
	-- a column at either side of those rows -- the rail and its drawer on the
	-- left; Garden, the Bag and the bats on the right.
	local top, bottom = 6, H - 8
	local left, right = 8, W - 8
	local ok, groups = pcall(function()
		return HudLayout.groups(HudLayout.solve(HudLayout.measure(gui)), true)
	end)
	if ok and type(groups) == "table" then
		for _, group in ipairs(groups) do
			if group.name == "hotbar" then
				bottom = math.min(bottom, group.rect.y - 8)
			end
		end
		for _, group in ipairs(groups) do
			local r = group.rect
			if group.name ~= "hotbar" and r.y < bottom and r.y + r.h > top then
				if r.x + r.w / 2 < W / 2 then
					left = math.max(left, r.x + r.w + 8)
				else
					right = math.min(right, r.x - 8)
				end
			end
		end
	end
	-- The X hangs over the plate's corner by OVERHANG, up and to the right.
	local band = math.max(bottom - top, 40)
	local span = math.max(right - left, 40)
	local scale = math.clamp(math.min(grow, band / (PLATE.Y + OVERHANG), span / (PLATE.X + OVERHANG)),
		0.8, 1.25)
	plateScale.Scale = scale
	local halfW, halfH = PLATE.X * scale / 2, PLATE.Y * scale / 2
	local hang = OVERHANG * scale
	local x = W / 2
	if span >= PLATE.X * scale + hang then
		x = math.clamp(x, left + halfW, right - halfW - hang)
	else
		-- Narrower than the card at its smallest: in the middle of what there is.
		x = (left + right - hang) / 2
	end
	local middle = math.min(top + band / 2, H * 0.42)
	plate.Position = UDim2.fromOffset(x, math.max(middle, top + halfH + hang))
	return scale
end

--==============================================================================
-- THE SILHOUETTES
--
-- The real plants, by the real builder, at the pod's own tier: a silhouette is
-- the viewport's tint taken down to near black (the Index's), so the reveal is
-- that tint lifting and nothing is rebuilt for it. One model for each plant of
-- the biome, built the first time it comes up and thrown away with the card.
--==============================================================================
type Portrait = { model: Model, camera: Camera }
local portraits: { [string]: Portrait } = {}
local shown: string? = nil

local function clearPortraits()
	shown = nil
	for id, portrait in pairs(portraits) do
		portrait.model:Destroy()
		portrait.camera:Destroy()
		portraits[id] = nil
	end
	card.hero.CurrentCamera = nil
end

local function portraitOf(speciesId: string, tier: number): Portrait?
	local known = portraits[speciesId]
	if known then
		return known
	end
	local species = SeedData.Get(speciesId)
	if not species then
		return nil
	end
	local ok, model = pcall(function()
		return CreatureModel.Build(species, tier, CreatureModel.STAGE_GROWN, CFrame.new(), card.hero)
	end)
	if not ok or typeof(model) ~= "Instance" then
		return nil
	end
	local built = model :: Model
	-- Nothing in a viewport is a plant in anybody's garden.
	for _, tag in ipairs(CollectionService:GetTags(built)) do
		CollectionService:RemoveTag(built, tag)
	end
	for _, d in ipairs(built:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(d)) do
			CollectionService:RemoveTag(d, tag)
		end
	end
	local camera = UIKit.framePlant(card.hero, built, species.Form)
	local portrait = { model = built, camera = camera }
	portraits[speciesId] = portrait
	return portrait
end

local function show(speciesId: string, tier: number)
	if shown == speciesId then
		return
	end
	local before = if shown then portraits[shown :: string] else nil
	local portrait = portraitOf(speciesId, tier)
	if not portrait then
		return
	end
	if before and before ~= portrait then
		before.model.Parent = nil
		before.camera.Parent = nil
	end
	portrait.model.Parent = card.hero
	portrait.camera.Parent = card.hero
	card.hero.CurrentCamera = portrait.camera
	shown = speciesId
end

--==============================================================================
-- THE HATCHES WAITING TO BE SHOWN
--==============================================================================
type Hatch = {
	token: number,
	speciesId: string,
	tier: number,
	income: number,
	discovery: boolean,
	rollAt: number,
	revealAt: number,
	-- Told in a line rather than on the card.
	compact: boolean,
	frames: { HatchRoll.Frame },
	frame: number,
	revealed: boolean,
}

local waiting: { Hatch } = {}
local current: Hatch? = nil
-- The player put the card away: the rest of this run of hatches is lines.
local putAway = false
local driver: RBXScriptConnection? = nil
local heard: { [number]: boolean } = {}
local heardCount = 0

local function panelOpen(): boolean
	return player:GetAttribute(ATTR.OpenPanel) ~= nil
end

-- The line a hatch is told in when there is no card to tell it on.
local function tell(hatch: Hatch)
	local species = SeedData.Get(hatch.speciesId)
	if not species then
		return
	end
	local detail = string.format("%s • %s • +$%s/s", species.Rarity, SeedData.TierName(hatch.tier),
		GameConfig.compact(hatch.income))
	if hatch.discovery then
		detail = "New discovery! " .. detail
	end
	Notice.post({
		kind = "success",
		title = "HATCHED: " .. string.upper(species.Name),
		detail = detail,
		key = "hatch:" .. tostring(hatch.token),
		seconds = 3.2,
	})
end

local function bindBack(on: boolean)
	pcall(function()
		ContextActionService:UnbindAction(BACK_ACTION)
	end)
	if not on then
		return
	end
	-- Over PadFocus's own B (2500): with the card up, B is the card's.
	ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or not plate.Visible then
			return Enum.ContextActionResult.Pass
		end
		putAway = true
		return Enum.ContextActionResult.Sink
	end, false, 2600, Enum.KeyCode.ButtonB)
end

local function hideCard()
	if not plate.Visible then
		return
	end
	plate.Visible = false
	bindBack(false)
	clearPortraits()
end

local function paintMore()
	local count = 0
	for _, hatch in ipairs(waiting) do
		if not hatch.compact then
			count += 1
		end
	end
	more.Visible = count > 0
	more.Text = string.format("+%d MORE", count)
end

-- The card as the roll has it: a secret, the size the shell showed, no name.
-- On the Garden's own stage for a pod that is ready to hatch: its warm light is
-- what the near-black shapes are read against.
local function dressForRoll(hatch: Hatch)
	card.setStageTheme("ready")
	card.setBackdrop(nil)
	card.name.Text = ""
	card.sub.Text = ""
	card.setSubPill(false)
	card.border.Color = HOT.Ink
	card.hero.Position = UDim2.fromScale(0.5, 0.02)
	card.hero.ImageColor3 = SILHOUETTE
	card.hero.ImageTransparency = 0.1
	cardPop.Scale = 1
	question.Visible = true
	question.TextTransparency = 0
	if questionEdge then
		questionEdge.Transparency = 0
	end
	questionPop.Scale = 1
	rimEdge.Color = HOT.Rim
	rimEdge.Transparency = HOT.RimTransparency
	rimEdge.Thickness = 1.5
	header.Text = "HATCHING..."
	title.Text = HatchRoll.Unknown
	title.TextColor3 = WHITE
	line.Text = string.upper(SeedData.TierName(hatch.tier))
	line.TextColor3 = SeedData.ColorForTier(hatch.tier)
	pays.Visible = false
	found.Visible = false
	track.Visible = true
	fill.Size = UDim2.fromScale(0, 1)
end

local function sparks(colour: Color3, count: number)
	local centre = Vector2.new(8 + CARD.X / 2, 8 + CARD.Y * 0.42)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + 0.3
		local reach = 46 + (i % 3) * 14
		local dot = Instance.new("Frame")
		dot.Name = "Spark"
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromOffset(centre.X, centre.Y)
		dot.Size = UDim2.fromOffset(6, 6)
		dot.BackgroundColor3 = colour:Lerp(WHITE, 0.45)
		dot.BackgroundTransparency = 0.1
		dot.BorderSizePixel = 0
		dot.Active = false
		dot.ZIndex = 35
		dot.Parent = plate
		UIKit.corner(dot, 3)
		TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(centre.X + math.cos(angle) * reach, centre.Y + math.sin(angle) * reach),
			Size = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(1, function()
			dot:Destroy()
		end)
	end
end

-- The plant, shown. Every word here is read off the message the server sent
-- when the hatch happened; nothing is looked up that could differ from it.
local function reveal(hatch: Hatch)
	hatch.revealed = true
	local species = SeedData.Get(hatch.speciesId)
	if not species then
		return
	end
	show(hatch.speciesId, hatch.tier)
	local still = reduced()
	local rarityColour: Color3 = GameConfig.RarityColor[species.Rarity] or WHITE
	local seconds = if still then 0.2 else 0.5
	local ease = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	card.setStageTheme("grown")
	card.setBackdrop(hatch.speciesId)
	card.hero.Position = UDim2.fromScale(0.5, 0.02)
	-- The tint lifts: the silhouette becomes the plant it always was.
	TweenService:Create(card.hero, ease, { ImageColor3 = WHITE, ImageTransparency = 0 }):Play()
	TweenService:Create(question, ease, { TextTransparency = 1 }):Play()
	if questionEdge then
		TweenService:Create(questionEdge, ease, { Transparency = 1 }):Play()
	end
	if not still then
		TweenService:Create(questionPop, ease, { Scale = 1.5 }):Play()
		cardPop.Scale = 0.94
		TweenService:Create(cardPop, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }):Play()
	end
	task.delay(seconds, function()
		if current == hatch then
			question.Visible = false
		end
	end)

	card.border.Color = rarityColour
	card.name.Text = ""
	card.sub.Text = string.upper(species.Rarity)
	card.sub.TextColor3 = rarityColour
	card.setSubPill(true, rarityColour)
	rimEdge.Color = rarityColour
	rimEdge.Transparency = 0.15
	rimEdge.Thickness = 2

	header.Text = "YOU HATCHED"
	title.Text = string.upper(species.Name)
	title.TextColor3 = SeedData.FormColor(species)
	line.Text = string.format("%s • %s", string.upper(species.Rarity), string.upper(SeedData.TierName(hatch.tier)))
	line.TextColor3 = rarityColour
	pays.Text = string.format("+$%s/s", GameConfig.compact(hatch.income))
	pays.Visible = true
	found.Text = HATCH.Label.NewText
	found.Visible = hatch.discovery
	track.Visible = false

	local rank = GameConfig.RarityTier[species.Rarity] or 1
	if not still and rank >= SPARKS_FROM then
		sparks(rarityColour, if rank > SPARKS_FROM then SPARKS.many else SPARKS.few)
	end

	-- Once (HatchRoll.claim): the world's side plays neither for a hatch this
	-- card has sounded, and both for one it has not -- a card that was put
	-- away, or never drawn.
	if HatchRoll.claim(hatch.token) then
		SoundKit.play(REVEAL_FOR[species.Rarity] or "RevealCommon")
		local accent = REVEAL_ACCENT[species.Rarity]
		if accent and SoundKit.has(accent) then
			SoundKit.play(accent)
		end
	end
end

local function showCard(hatch: Hatch)
	current = hatch
	local settle = place()
	dressForRoll(hatch)
	paintMore()
	plate.Visible = true
	bindBack(true)
	if not reduced() then
		plateScale.Scale = settle * 0.92
		TweenService:Create(plateScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = settle }):Play()
	end
	SoundKit.play("PanelOpen")
end

-- One silhouette gives way to the next: a short slide up into place, and a tick.
local function turn(hatch: Hatch, index: number)
	local first = hatch.frame == 0
	hatch.frame = index
	local frame = hatch.frames[index]
	if not frame then
		return
	end
	show(frame.speciesId, hatch.tier)
	if first then
		return
	end
	SoundKit.play("CardHover")
	if reduced() then
		return
	end
	card.hero.Position = UDim2.new(0.5, 0, 0.02, 9)
	card.hero.ImageTransparency = 0.55
	local slide = TweenInfo.new(math.min(0.12, frame.hold * 0.6), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(card.hero, slide, { Position = UDim2.fromScale(0.5, 0.02), ImageTransparency = 0.1 }):Play()
	questionPop.Scale = 1.1
	TweenService:Create(questionPop, slide, { Scale = 1 }):Play()
end

--==============================================================================
-- THE CLOCK
--
-- One Heartbeat while anything is waiting, none while nothing is. Every moment
-- is read off the server's clock against the times the server sent, so a
-- frame that comes late draws where the roll IS, not where it was left.
--==============================================================================
local function step()
	local now = serverNow()

	-- Lines, for whatever is not going on the card.
	for i = #waiting, 1, -1 do
		local hatch = waiting[i]
		if (hatch.compact or putAway) and now >= hatch.revealAt then
			table.remove(waiting, i)
			tell(hatch)
		end
	end

	local hatch = current
	if hatch then
		if (putAway or panelOpen()) and plate.Visible then
			hideCard()
		end
		if not hatch.revealed and now >= hatch.revealAt then
			if plate.Visible then
				reveal(hatch)
			else
				hatch.revealed = true
				tell(hatch)
			end
		elseif not hatch.revealed and plate.Visible then
			local elapsed = now - hatch.rollAt
			local index = HatchRoll.frameAt(hatch.frames, elapsed)
			if index ~= hatch.frame then
				turn(hatch, index)
			end
			fill.Size = UDim2.fromScale(math.clamp(elapsed / math.max(hatch.revealAt - hatch.rollAt, 0.1), 0, 1), 1)
		end
		if now >= hatch.revealAt + ROLL.ShowSeconds or (hatch.revealed and not plate.Visible) then
			current = nil
			hideCard()
		end
	end

	if current == nil and not putAway then
		local nextAt: number? = nil
		for i, candidate in ipairs(waiting) do
			if not candidate.compact and now >= candidate.rollAt - 0.05 then
				nextAt = i
				break
			end
		end
		if nextAt then
			local nextHatch = table.remove(waiting, nextAt) :: Hatch
			if panelOpen() or now >= nextHatch.revealAt then
				-- A panel is up, or its roll went by while it waited (a stalled
				-- client): this one is a line, at its time, not a card drawn late.
				nextHatch.compact = true
				table.insert(waiting, nextHatch)
			else
				showCard(nextHatch)
				turn(nextHatch, HatchRoll.frameAt(nextHatch.frames, now - nextHatch.rollAt))
			end
		end
	end

	if current == nil and #waiting == 0 then
		-- The run of hatches is over: the next one gets its card again.
		putAway = false
		if driver then
			driver:Disconnect()
			driver = nil
		end
	end
end

local function wake()
	if driver then
		return
	end
	driver = RunService.Heartbeat:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			-- The card is decoration. Whatever went wrong, it goes away and the
			-- plants are told in lines -- the one that was on it too, at its own
			-- time; the hotbar shows them either way.
			warn("[Seed/HatchRollUI] the card failed: " .. tostring(err))
			putAway = true
			local failed = current
			current = nil
			if failed and not failed.revealed then
				failed.compact = true
				table.insert(waiting, failed)
			end
			pcall(hideCard)
		end
	end)
end

--==============================================================================
-- ONE MESSAGE, ONE HATCH
--
-- The server's own message, read as a claim: a plant that exists, a tier, two
-- times that make a roll, and an owner who is this player. Anything else is
-- not drawn. A message heard twice is one hatch.
--==============================================================================
local function onHatch(payload: any)
	if type(payload) ~= "table" or payload.owner ~= player then
		return
	end
	local speciesId = payload.species
	local tier = tonumber(payload.tier)
	local revealAt = tonumber(payload.revealAt)
	local rollAt = tonumber(payload.rollAt)
	local token = tonumber(payload.token) or 0
	if type(speciesId) ~= "string" or not SeedData.Get(speciesId) or not tier then
		return
	end
	if not (revealAt and rollAt) or revealAt ~= revealAt or rollAt ~= rollAt then
		return
	end
	local now = serverNow()
	-- No roll (it is switched off), one already over, or a time no roll could
	-- have: nothing to draw. The world's side shows the plant as it always did.
	if revealAt <= rollAt or not HatchRoll.hidden(revealAt, now) then
		return
	end
	if token ~= 0 then
		if heard[token] then
			return
		end
		heard[token] = true
		heardCount += 1
		-- Only a recent hatch can be heard twice: the old ones are forgotten.
		if heardCount > 256 then
			for old in pairs(heard) do
				if old < token - 128 then
					heard[old] = nil
					heardCount -= 1
				end
			end
		end
	end
	local hatch: Hatch = {
		token = token,
		speciesId = speciesId,
		tier = math.clamp(math.floor(tier), 1, SeedData.TierCount),
		income = tonumber(payload.income) or 0,
		discovery = payload.discovery == true,
		rollAt = rollAt,
		revealAt = revealAt,
		compact = payload.compact == true,
		frames = HatchRoll.frames(speciesId, token),
		frame = 0,
		revealed = false,
	}
	table.insert(waiting, hatch)
	table.sort(waiting, function(a: Hatch, b: Hatch): boolean
		return a.rollAt < b.rollAt
	end)
	paintMore()
	wake()
end

close.Activated:Connect(function()
	putAway = true
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if plate.Visible then
		place()
	end
end)

-- Dying puts the card away. The plants are on the record and come back with
-- the body; what was still waiting to be shown is told in lines.
player.CharacterRemoving:Connect(function()
	if current or #waiting > 0 then
		putAway = true
	end
end)

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local channel = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (channel and channel:IsA("RemoteEvent")) then
		return
	end
	channel.OnClientEvent:Connect(function(action: any, payload: any)
		if action ~= HATCH.Action then
			return
		end
		local ok, err = pcall(onHatch, payload)
		if not ok then
			warn("[Seed/HatchRollUI] a hatch could not be drawn: " .. tostring(err))
		end
	end)
end)
