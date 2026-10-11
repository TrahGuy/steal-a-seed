--!strict
--==============================================================================
-- Steal a Seed :: MistOddsView (2026-10-11, Enchanted Mist stage 3)
--
-- MOSSKEEPER'S ODDS PAGE (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §10,
-- the owner's cards): one RARITY CARD per Mysterious Pod creature -- the card
-- the Bag, MY PLANTS, the Index and Marigold wear (MenuKit.cardFace, its
-- rarity's studs by BagLook.StudsByRarity, RarityFX's shine and word) -- with
-- its chance as a percentage at the card's top edge; and apart from them the
-- SIZE odds, Tiny to Colossal, for Legendary to Divine only (Secrets keep
-- their own size). Every number is EnchantedMistData's -- creatureChance and
-- sizeChance -- the same the server rolls with.
--
-- The rarest chance's % (RainbowAtMost and under) runs a rapid rainbow
-- (WheelDraw.rainbow on white words; their near-black outline stays dark under
-- the gradient); the others under ShimmerBelow shimmer in their own colour;
-- the rest stay still. Reduced FX: the rainbow and shimmer stand still, and
-- RarityFX stills its own.
--
-- A creature with no model yet stands in the Index's undiscovered DARK window
-- ("???"), never a stand-in creature; one that exists is drawn live.
--==============================================================================
local RunService = game:GetService("RunService")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

local MistOddsView = {}

local CFG = EnchantedMistConfig.Mosskeeper
local ODDS = CFG.Odds
local W = CFG.Words
local LOOK = MenuKit.Look
local STUD_LOOK = GameConfig.BagLook
local ALMANAC = GameConfig.Almanac
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(14, 10, 18)
local DRAFT = Color3.fromRGB(176, 52, 40)
local GAP = 6

-- A chance in percent, as the Wheel writes one (22%, 0.4%, 0.52%).
function MistOddsView.percent(chance: number): string
	return WheelData.percent(chance / 100)
end

-- How a chance's % moves: "rainbow", "shimmer" or nil (still).
function MistOddsView.animationFor(chance: number): string?
	if chance <= ODDS.RainbowAtMost + 1e-9 then
		return "rainbow"
	elseif chance < ODDS.ShimmerBelow then
		return "shimmer"
	end
	return nil
end

export type View = {
	frame: ScrollingFrame,
	height: number,
	setShown: (boolean) -> (),
}

type Moving = { kind: string, gradient: UIGradient, colour: Color3 }

-- The chance words: white under a gradient that carries the colour, so their
-- outline stays dark; a still one keeps its plain colour.
local function chanceWords(parent: GuiObject, name: string, size: number, chance: number, colour: Color3, z: number,
	moving: { Moving }): TextLabel
	local label = MenuKit.text(parent, name, size, WHITE, z)
	label.Text = MistOddsView.percent(chance)
	label.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = size
	fit.MinTextSize = 9
	fit.Parent = label
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = INK
		stroke.Transparency = 0
	end
	local kind = MistOddsView.animationFor(chance)
	if kind == nil then
		label.TextColor3 = colour
		return label
	end
	local gradient = Instance.new("UIGradient")
	gradient.Name = if kind == "rainbow" then "Rainbow" else "Shimmer"
	if kind == "rainbow" then
		gradient.Color = WheelDraw.rainbow(0)
	else
		local light = colour:Lerp(WHITE, 0.75)
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colour),
			ColorSequenceKeypoint.new(0.42, colour),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(0.58, colour),
			ColorSequenceKeypoint.new(1, colour),
		})
		gradient.Offset = Vector2.new(-1, 0)
	end
	gradient.Parent = label
	table.insert(moving, { kind = kind, gradient = gradient, colour = colour })
	return label
end

-- ONE CREATURE'S RARITY CARD (the Odds page and the Mysterious Pod's reels):
-- its % at the top, its window (live when the creature exists, else the dark
-- "???"), its name and rarity on the ink backing. `moving`, `fx` and `views`
-- collect what the caller starts and stops.
function MistOddsView.card(parent: GuiObject, entry: any, z: number, cardH: number, moving: { Moving },
	fx: { any }, views: { { view: ViewportFrame, species: any, built: boolean } }): Frame
	local chance = EnchantedMistData.creatureChance(entry.Id)
	local holderCard = MenuKit.frame(parent, "Card_" .. entry.Id, z + 1)
	local face = MenuKit.frame(holderCard, "Face", z + 1, WHITE, 0, 8)
	face.Size = UDim2.fromScale(1, 1)
	local tint = MenuKit.cardFace(face)
	MenuKit.cardTint(tint, (GameConfig.RarityColor :: any)[entry.Rarity])
	local studs = UIKit.studCard(face, 8, z + 1)
	local shine = RarityFX.shine(face, 8, z + 1)
	local spec = studs.set((STUD_LOOK.StudsByRarity :: any)[entry.Rarity])
	RarityFX.setShine(shine, if spec then entry.Rarity else nil)
	table.insert(fx, shine)
	local rare = RarityFX.edgeColour(entry.Rarity)
	MenuKit.keyline(face, rare or LOOK.CardEdge, 1, if rare then 0.05 else LOOK.CardEdgeTransparency)
	-- The % at the card's top edge.
	local colour = (GameConfig.RarityColor :: any)[entry.Rarity] or WHITE
	local pct = chanceWords(face, "Chance", 18, chance, colour, z + 6, moving)
	pct.AnchorPoint = Vector2.new(0.5, 0)
	pct.Position = UDim2.new(0.5, 0, 0, 3)
	pct.Size = UDim2.new(1, -8, 0, 20)
	-- The display window: dark, the creature in it when it exists.
	local well = MenuKit.frame(face, "Preview", z + 2, LOOK.Window, 0, 6)
	well.ClipsDescendants = true
	well.Position = UDim2.fromOffset(4, 25)
	well.Size = UDim2.new(1, -8, 0, cardH - 25 - 40)
	local species = SeedData.Get(entry.Id)
	if species then
		local view = Instance.new("ViewportFrame")
		view.Name = "Plant"
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		view.Position = UDim2.fromScale(0.5, 0.5)
		view.Size = UDim2.new(1, -4, 1, -4)
		view.BackgroundTransparency = 1
		view.Ambient = GameConfig.Card.Ambient
		view.LightColor = GameConfig.Card.LightColour
		view.LightDirection = GameConfig.Card.LightDirection
		view.ZIndex = z + 3
		view.Parent = well
		table.insert(views, { view = view, species = species, built = false })
	else
		local unknown = MenuKit.text(well, "Unknown", 22, Color3.fromRGB(110, 128, 116), z + 3)
		unknown.Size = UDim2.fromScale(1, 1)
		unknown.Text = "???"
	end
	-- The name and the rarity on the Bag's quiet ink backing.
	local words = MenuKit.frame(face, "Words", z + 4, STUD_LOOK.StudWords,
		if spec and spec.words then spec.words else STUD_LOOK.StudWordsTransparency, 6)
	words.Position = UDim2.new(0, 3, 1, -39)
	words.Size = UDim2.new(1, -6, 0, 36)
	words.Visible = spec ~= nil
	local name = MenuKit.text(face, "Name", 14, if spec then WHITE else LOOK.Text, z + 5)
	name.Position = UDim2.new(0, 5, 1, -38)
	name.Size = UDim2.new(1, -10, 0, 18)
	name.TextScaled = true
	name.Text = entry.Name
	local rarity = MenuKit.text(face, "Rarity", 12, WHITE, z + 5)
	rarity.Position = UDim2.new(0, 5, 1, -19)
	rarity.Size = UDim2.new(1, -10, 0, 15)
	rarity.Text = entry.Rarity
	local word = RarityFX.text(rarity, rarity:FindFirstChildOfClass("UIStroke"))
	local tone = (ALMANAC.Rarity :: any)[entry.Rarity] or (ALMANAC.Rarity :: any).Common
	RarityFX.setText(word, entry.Rarity, tone[1])
	table.insert(fx, word)
	return holderCard
end

-- A size's chance words (the Odds page's chips, the Mysterious Pod's size
-- reel), the ink outline carrying them on a chip of their tier's colour:
-- still ones in that colour lightened; a shimmering one (Colossal's) in the
-- colour itself, so its light band shows as it passes.
function MistOddsView.sizeWords(parent: GuiObject, name: string, size: number, tier: number, z: number,
	moving: { Moving }): TextLabel
	local t = SeedData.Tiers[tier]
	local chance = EnchantedMistData.sizeChance(tier)
	local base = if t then t.color else WHITE
	local colour = if MistOddsView.animationFor(chance) == nil then base:Lerp(WHITE, 0.3) else base
	return chanceWords(parent, name, size, chance, colour, z, moving)
end

-- Runs the rainbow and the shimmer of `moving` (Reduced FX holds them still);
-- returns the stop.
function MistOddsView.animate(moving: { Moving }): () -> ()
	local stepping = RunService.RenderStepped:Connect(function()
		local still = StatusText.reducedMotion()
		local now = os.clock()
		for _, m in ipairs(moving) do
			if m.kind == "rainbow" then
				m.gradient.Color = WheelDraw.rainbow(if still then 0 else (now / ODDS.RainbowSeconds) % 1)
			else
				m.gradient.Offset = Vector2.new(if still then -1 else ((now / ODDS.ShimmerSeconds) % 1) * 2 - 1, 0)
			end
		end
	end)
	return function()
		stepping:Disconnect()
	end
end

-- A Mysterious Pod reel's items: `answer` at `land`, the rest from `draw` (the
-- odds' own mix, so the filler never misstates them), never two alike side by
-- side, so the landing reads at a glance. `all` is every possible item.
function MistOddsView.reelItems(count: number, land: number, answer: any, draw: () -> any, all: { any }): { any }
	local items = {}
	for i = 1, count do
		if i == land then
			items[i] = answer
		else
			local function clash(v: any): boolean
				return v == items[i - 1] or (i == land - 1 and v == answer)
			end
			local pick = draw()
			for _ = 1, 6 do
				if not clash(pick) then
					break
				end
				pick = draw()
			end
			if clash(pick) then
				for _, v in ipairs(all) do
					if not clash(v) then
						pick = v
						break
					end
				end
			end
			items[i] = pick
		end
	end
	return items
end

-- Draws, once each, the creature in every window `card` listed in `views`.
function MistOddsView.drawViews(views: { { view: ViewportFrame, species: any, built: boolean } })
	for _, v in ipairs(views) do
		if not v.built then
			v.built = true
			local ok, model = pcall(CreatureModel.Build, v.species, SeedData.BaseTier,
				CreatureModel.STAGE_GROWN, CFrame.new(), v.view)
			if ok and model then
				v.view.CurrentCamera = UIKit.framePlant(v.view, model, v.species.Form, 0.84,
					(GameConfig.Card.Zoom :: any).Index)
			end
		end
	end
end

-- `holder` gets a scrolling page; its height is `View.height` (the caller
-- caps it). Built once; `setShown` starts and stops what moves.
function MistOddsView.build(holder: GuiObject, z: number): View
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "OddsScroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ScrollBarThickness = 6
	scroll.ElasticBehavior = Enum.ElasticBehavior.Always
	scroll.Selectable = false
	scroll.ZIndex = z
	scroll.Parent = holder
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = scroll

	local height = 0
	local order = 0
	local moving: { Moving } = {}
	local fx: { any } = {}
	local views: { { view: ViewportFrame, species: any, built: boolean } } = {}

	local function heading(name: string, text: string, size: number, colour: Color3, h: number)
		order += 1
		local label = MenuKit.text(scroll, name, size, colour, z + 1)
		label.Size = UDim2.new(1, -10, 0, h)
		label.LayoutOrder = order
		label.Text = text
		label.TextScaled = true
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = size
		fit.MinTextSize = 9
		fit.Parent = label
		height += h + GAP
	end

	if not (EnchantedMistData.Pool.Approved and EnchantedMistData.Sizes.Approved) then
		heading("Draft", W.OddsDraft, 13, DRAFT, 16)
	end
	heading("Species", W.OddsSpecies, 16, LOOK.Text, 20)

	-- THE CREATURE CARDS
	local entries = EnchantedMistData.Pool.Entries
	local columns = 3
	local rows = math.ceil(#entries / columns)
	local cardH = ODDS.CardHeight
	order += 1
	local grid = Instance.new("Frame")
	grid.Name = "Cards"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, -10, 0, rows * cardH + (rows - 1) * GAP)
	grid.LayoutOrder = order
	grid.ZIndex = z
	grid.Parent = scroll
	height += rows * cardH + (rows - 1) * GAP + GAP
	local cells = Instance.new("UIGridLayout")
	cells.CellSize = UDim2.new(1 / columns, -GAP, 0, cardH)
	cells.CellPadding = UDim2.fromOffset(GAP, GAP)
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cells.Parent = grid

	for i, entry in ipairs(entries) do
		local holderCard = MistOddsView.card(grid, entry, z, cardH, moving, fx, views)
		holderCard.LayoutOrder = i
	end

	-- THE SIZES, apart (Legendary to Divine).
	heading("Sizes", W.OddsSizes, 16, LOOK.Text, 20)
	local weights = EnchantedMistData.Sizes.Weights
	local chipColumns = 4
	local chipRows = math.ceil(#weights / chipColumns)
	local chipH = ODDS.ChipHeight
	order += 1
	local chips = Instance.new("Frame")
	chips.Name = "Sizes"
	chips.BackgroundTransparency = 1
	chips.Size = UDim2.new(1, -10, 0, chipRows * chipH + (chipRows - 1) * GAP)
	chips.LayoutOrder = order
	chips.ZIndex = z
	chips.Parent = scroll
	height += chipRows * chipH + (chipRows - 1) * GAP + GAP
	local chipCells = Instance.new("UIGridLayout")
	chipCells.CellSize = UDim2.new(1 / chipColumns, -GAP, 0, chipH)
	chipCells.CellPadding = UDim2.fromOffset(GAP, GAP)
	chipCells.SortOrder = Enum.SortOrder.LayoutOrder
	chipCells.HorizontalAlignment = Enum.HorizontalAlignment.Center
	chipCells.Parent = chips
	for tier = 1, #weights do
		local t = SeedData.Tiers[tier]
		local colour = if t then t.color else WHITE
		local chip = MenuKit.frame(chips, "Size_" .. tier, z + 1, colour, 0, 8)
		chip.LayoutOrder = tier
		MenuKit.keyline(chip, INK, 1.5)
		-- The studded kit on the chip too, in its own colour.
		UIKit.studs(chip, { pitch = 10, size = 5, inset = 2, face = colour:Lerp(WHITE, 0.25),
			shade = colour:Lerp(INK, 0.35), zIndex = z + 2 })
		local label = MistOddsView.sizeWords(chip, "Chance", 14, tier, z + 4, moving)
		label.Size = UDim2.new(1, -6, 1, -4)
		label.Position = UDim2.fromOffset(3, 2)
		label.Text = string.format("%s %s", if t then t.name else tostring(tier), label.Text)
	end
	heading("SecretNote", W.OddsSecretNote, 13, LOOK.Muted, 16)

	-- What moves, while the page is up.
	local stop: (() -> ())? = nil
	local view: View = {
		frame = scroll,
		height = height,
		setShown = function(on: boolean)
			for _, h in ipairs(fx) do
				RarityFX.setActive(h, on)
			end
			if stop then
				stop()
				stop = nil
			end
			if not on then
				return
			end
			MistOddsView.drawViews(views)
			stop = MistOddsView.animate(moving)
		end,
	}
	return view
end

return MistOddsView
