--!strict
--==============================================================================
-- Steal a Seed :: PodGuideView (2026-10-09; GameConfig.PodGuide)
--
-- HOW ONE STAND'S BOARD IS LETTERED: a SurfaceGui on its plank's front face,
-- held in the PlayerGui and adorned to the plank (a ViewportFrame never draws
-- in a SurfaceGui under the Workspace -- PlotShowcaseView's note). PodGuideUI
-- decides when; this decides how.
--
--   THE HEADER    TOP CREATURES' white studded rim and lettering: "<BIOME>
--                 PODS", and the line under it.
--   FIVE CARDS    one a plant, in its nest's draw order: its pod, an arrow,
--                 its plant -- a dark silhouette until this player has grown
--                 it, as in the Almanac (AlmanacView.face: "???") -- its
--                 rarity in its colour, its name, and how often a nest stocks
--                 its pod (PodGuide).
--   THE SIZES     the seven sizes in the tier colours, each with this biome's
--                 chance and its income against Tiny; under them the secret
--                 line, only while secrets are on.
--
-- THE PICTURES ARE SEPARATE (setPreviews): ten ViewportFrames a board, built
-- while the camera is near and FREED when it is not. The words are cheap and
-- stay. Never lit by the world, never interactive.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local PodGuide = require(Shared:WaitForChild("PodGuide"))
local AlmanacView = require(Shared:WaitForChild("AlmanacView"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))

local PodGuideView = {}

local CFG = GameConfig.PodGuide
local WORDS = CFG.Words
local BAG = GameConfig.BagLook
local LOOK = MenuKit.Look
local ALMANAC = GameConfig.Almanac
local WHITE = Color3.fromRGB(255, 255, 255)

-- What the client's gui is called on a plank, so a re-run can find its own.
PodGuideView.GuiName = "SeedPodGuideFace"

--==============================================================================
-- THE CANVAS, IN PX: the plank's face at PixelsPerStud (900 x 504 at 60).
--==============================================================================
local W = math.floor(CFG.BoardSize.X * CFG.PixelsPerStud + 0.5)
local H = math.floor(CFG.BoardSize.Y * CFG.PixelsPerStud + 0.5)
local Z = 2
local MARGIN = 10
local HEADER = 60
local TITLE_SIZE = 42
local SUB_Y = MARGIN + HEADER + 4
local SUB_SIZE = 22
local CARD_TOP = SUB_Y + SUB_SIZE + 10
local CARD_W = math.floor((W - MARGIN * 6) / 5)
local CARD_H = 196
local PICTURE = 74
local RARITY_SIZE = 22
local NAME_SIZE = 26
local CHANCE_SIZE = 32
local SIZES_TOP = CARD_TOP + CARD_H + 10
local SIZES_H = H - SIZES_TOP - MARGIN
local LABEL_W = 132
local CELL_W = math.floor((W - MARGIN * 2 - LABEL_W) / 7)
local SIZE_WORD = 26
local SIZE_NUMBER = 30
local SECRET_SIZE = 20

PodGuideView.Canvas = Vector2.new(W, H)
-- Every text size on the board, for PodGuideSpec's readability check.
PodGuideView.TextSizes = {
	title = TITLE_SIZE, sub = SUB_SIZE, rarity = RARITY_SIZE, name = NAME_SIZE, chance = CHANCE_SIZE,
	size = SIZE_WORD, number = SIZE_NUMBER, secret = SECRET_SIZE,
}

export type Card = {
	species: SeedData.Species,
	podHost: Frame,
	plantHost: Frame,
	podPreview: UIKit.ItemPreview?,
	plantPreview: UIKit.ItemPreview?,
	rarity: TextLabel,
	name: TextLabel,
	chance: TextLabel,
	known: boolean,
}

export type View = {
	gui: SurfaceGui,
	biomeId: string,
	title: TextLabel,
	cards: { Card },
	secret: TextLabel,
	previews: boolean,
	key: string,
}

local function plainFrame(parent: Instance, name: string, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function buildHeader(gui: SurfaceGui, text: string): TextLabel
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.fromOffset(MARGIN, MARGIN)
	header.Size = UDim2.fromOffset(W - MARGIN * 2, HEADER)
	header.BackgroundColor3 = WHITE
	header.BorderSizePixel = 0
	header.Active = false
	header.ZIndex = Z
	header.Parent = gui
	UIKit.corner(header, 12)
	local tint = Instance.new("UIGradient")
	tint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BAG.RimTop),
		ColorSequenceKeypoint.new(0.7, BAG.RimBottom),
		ColorSequenceKeypoint.new(1, BAG.RimBottom),
	})
	tint.Rotation = 90
	tint.Parent = header
	MenuKit.keyline(header, BAG.Ink, 2.5)
	UIKit.studs(header, {
		pitch = BAG.StudPitch,
		size = BAG.StudSize,
		face = BAG.RimStud,
		shade = BAG.RimStudShade,
		image = BAG.RimStudImage,
		inset = 10,
		insetTop = 5,
		insetBottom = 6,
		zIndex = Z,
	})
	local title = UIKit.outlined(header, "Title", TITLE_SIZE, BAG.Title, BAG.TitleStroke + 0.5)
	local line = title:FindFirstChildOfClass("UIStroke")
	if line then
		line.Color = BAG.Ink
		line.LineJoinMode = Enum.LineJoinMode.Round
	end
	title.Position = UDim2.fromOffset(8, 2)
	title.Size = UDim2.new(1, -16, 1, -4)
	title.ZIndex = Z + 3
	title.Text = text
	return title
end

local function line(parent: Instance, name: string, size: number, colour: Color3, x: number, y: number, w: number,
	h: number, body: boolean?): TextLabel
	local it = if body then MenuKit.body(parent, name, size, colour, Z + 5) else MenuKit.text(parent, name, size, colour,
		Z + 5)
	it.Position = UDim2.fromOffset(x, y)
	it.Size = UDim2.fromOffset(w, h)
	return it
end

local function buildCard(gui: SurfaceGui, index: number, row: PodGuide.PlantOdds): Card
	local holder = plainFrame(gui, "Card" .. index, Z)
	holder.Position = UDim2.fromOffset(MARGIN + (index - 1) * (CARD_W + MARGIN), CARD_TOP)
	holder.Size = UDim2.fromOffset(CARD_W, CARD_H)
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.Active = false
	face.ZIndex = Z + 1
	face.Parent = holder
	UIKit.corner(face, 10)
	MenuKit.cardFace(face)
	MenuKit.keyline(face, LOOK.CardEdge, 2)
	-- The pod, an arrow, the plant: one picture each side of the card's middle.
	local half = math.floor((CARD_W - 28) / 2)
	local podHost = plainFrame(face, "Pod", Z + 2)
	podHost.Position = UDim2.fromOffset(6, 6)
	podHost.Size = UDim2.fromOffset(half, PICTURE)
	local arrow = line(face, "Arrow", 24, LOOK.Muted, 6 + half, 6, 16, PICTURE)
	arrow.Text = "\u{2192}"
	local plantHost = plainFrame(face, "Plant", Z + 2)
	plantHost.Position = UDim2.fromOffset(CARD_W - 6 - half, 6)
	plantHost.Size = UDim2.fromOffset(half, PICTURE)
	local sp = row.species
	local rarity = line(face, "Rarity", RARITY_SIZE, GameConfig.RarityColor[sp.Rarity] or LOOK.Text, 4,
		PICTURE + 12, CARD_W - 8, RARITY_SIZE + 4)
	rarity.Text = string.upper(tostring(sp.Rarity))
	MenuKit.keepInk(rarity)
	local name = line(face, "Name", NAME_SIZE, LOOK.Text, 4, PICTURE + 12 + RARITY_SIZE + 6, CARD_W - 8, NAME_SIZE + 6)
	local chance = line(face, "Chance", CHANCE_SIZE, LOOK.Money, 4, CARD_H - CHANCE_SIZE - 12, CARD_W - 8,
		CHANCE_SIZE + 6)
	chance.Text = string.upper(PodGuide.odds(row.chance))
	return {
		species = sp,
		podHost = podHost,
		plantHost = plantHost,
		podPreview = nil,
		plantPreview = nil,
		rarity = rarity,
		name = name,
		chance = chance,
		known = false,
	}
end

local function buildSizes(gui: SurfaceGui, biomeId: string): TextLabel
	local well = MenuKit.frame(gui, "Sizes", Z, BAG.StudWords, 0.25, 10)
	well.Position = UDim2.fromOffset(MARGIN, SIZES_TOP)
	well.Size = UDim2.fromOffset(W - MARGIN * 2, SIZES_H)
	-- The three rows share the well, less the secret line's room while there is one.
	local odds = PodGuide.secret(biomeId)
	local rowH = math.floor((SIZES_H - 16 - (if odds then SECRET_SIZE + 12 else 0)) / 3)
	local rows = { WORDS.Sizes, WORDS.SizeChance, WORDS.SizeWorth }
	for r, word in ipairs(rows) do
		local label = line(well, "Label" .. r, SIZE_WORD, BAG.Cream, 8, 8 + (r - 1) * rowH, LABEL_W - 12, rowH)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = word
	end
	for i, s in ipairs(PodGuide.sizes(biomeId)) do
		local x = LABEL_W + (i - 1) * CELL_W
		local name = line(well, "Size" .. i, SIZE_WORD, s.colour, x, 8, CELL_W, rowH)
		name.Text = string.upper(s.name)
		MenuKit.keepInk(name)
		local chance = line(well, "SizeChance" .. i, SIZE_NUMBER, WHITE, x, 8 + rowH, CELL_W, rowH)
		chance.Text = string.upper(PodGuide.odds(s.chance))
		local worth = line(well, "SizeWorth" .. i, SIZE_NUMBER, LOOK.Gold, x, 8 + rowH * 2, CELL_W, rowH)
		worth.Text = PodGuide.times(s.worth)
	end
	local secret = line(well, "Secret", SECRET_SIZE, BAG.Cream, 8, SIZES_H - SECRET_SIZE - 10, W - MARGIN * 2 - 16,
		SECRET_SIZE + 4, true)
	secret.Text = if odds then string.format(WORDS.Secret, string.upper(PodGuide.odds(odds.chance))) else ""
	secret.Visible = odds ~= nil
	return secret
end

--==============================================================================
-- NEW: a stand's board for `biomeId`, on `board` (the plank; its Front face is
-- the one read), held in `parent` -- the PlayerGui, never the Workspace. Built
-- with every name hidden and no pictures; paint() and setPreviews() do the rest.
--==============================================================================
function PodGuideView.new(board: BasePart, parent: Instance, biomeId: string): View
	local gui = Instance.new("SurfaceGui")
	gui.Name = PodGuideView.GuiName
	gui.Adornee = board
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(W, H)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = CFG.MaxDistance
	gui.Active = false
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui:SetAttribute("BiomeId", biomeId)
	gui.Parent = parent

	local biome = BiomeData.ById[biomeId]
	local title = buildHeader(gui, string.format(WORDS.Title, string.upper(if biome then biome.DisplayName else biomeId)))
	local sub = line(gui, "Sub", SUB_SIZE, BAG.Cream, MARGIN, SUB_Y, W - MARGIN * 2, SUB_SIZE + 6, true)
	sub.Text = WORDS.Sub
	local cards: { Card } = {}
	for i, row in ipairs(PodGuide.plants(biomeId)) do
		table.insert(cards, buildCard(gui, i, row))
	end
	local secret = buildSizes(gui, biomeId)
	local view: View = {
		gui = gui,
		biomeId = biomeId,
		title = title,
		cards = cards,
		secret = secret,
		previews = false,
		key = "",
	}
	PodGuideView.paint(view, {})
	return view
end

--==============================================================================
-- PAINTING: names and silhouettes from what this player has grown.
--==============================================================================
local function tintPlant(card: Card)
	local preview = card.plantPreview
	if preview then
		preview.hero.ImageColor3 = if card.known then WHITE else ALMANAC.Silhouette
		preview.hero.ImageTransparency = if card.known then 0 else 0.1
	end
end

local function preview(host: Frame): UIKit.ItemPreview
	local made = UIKit.itemPreview(host, { name = "Preview", scrim = 1, fit = 0.9 })
	made.hero.Ambient = LOOK.PreviewAmbient
	for _, d in ipairs(made.holder:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = math.max(d.ZIndex, Z + 2)
		end
	end
	return made
end

local function refreshPreviews(view: View)
	for _, card in ipairs(view.cards) do
		local id = card.species.Id
		if view.previews then
			if not card.podPreview then
				local made = preview(card.podHost)
				local art: ItemArt.Art = { kind = "pod", speciesId = id, tier = CFG.PodTier }
				local key = "pod|p:" .. id .. "|" .. tostring(CFG.PodTier)
				local builder, kind = ItemArt.builder(key, art)
				made.setModel(key, builder, kind)
				card.podPreview = made
			end
			if not card.plantPreview then
				local made = preview(card.plantHost)
				local art: ItemArt.Art = { kind = "plant", speciesId = id, tier = SeedData.BaseTier }
				local key = "plant|" .. id .. "|" .. tostring(SeedData.BaseTier)
				local builder, kind = ItemArt.builder(key, art)
				made.setModel(key, builder, kind)
				card.plantPreview = made
			end
			tintPlant(card)
		else
			-- FREED, not hidden: the ViewportFrames and the models in them go.
			if card.podPreview then
				card.podPreview.holder:Destroy()
				card.podPreview = nil
			end
			if card.plantPreview then
				card.plantPreview.holder:Destroy()
				card.plantPreview = nil
			end
		end
	end
end

-- The board for what this player has grown (`known[speciesId]`). Writes only
-- when that has changed for one of its plants.
function PodGuideView.paint(view: View, known: { [string]: boolean })
	local parts = {}
	for _, card in ipairs(view.cards) do
		table.insert(parts, if known[card.species.Id] then "1" else "0")
	end
	local key = table.concat(parts)
	if key == view.key then
		return
	end
	view.key = key
	for _, card in ipairs(view.cards) do
		card.known = known[card.species.Id] == true
		card.name.Text = AlmanacView.face(card.species, card.known).name
		tintPlant(card)
	end
end

-- The pictures: built while `on`, freed while not.
function PodGuideView.setPreviews(view: View, on: boolean)
	if view.previews == on then
		return
	end
	view.previews = on
	refreshPreviews(view)
end

function PodGuideView.destroy(view: View)
	for _, card in ipairs(view.cards) do
		card.podPreview = nil
		card.plantPreview = nil
	end
	view.gui:Destroy()
end

return PodGuideView
