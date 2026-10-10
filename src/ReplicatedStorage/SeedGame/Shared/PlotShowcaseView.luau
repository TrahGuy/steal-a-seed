--!strict
--==============================================================================
-- Steal a Seed :: PlotShowcaseView (2026-10-05, the owner's TOP CREATURES board)
--
-- HOW ONE PLOT'S BOARD IS DRAWN: a SurfaceGui on its plank's front face. Every
-- client draws the boards it holds (PlotShowcaseUI decides when); this decides
-- how, and builds nothing it is not asked to.
--
-- THE FACE LIVES IN THE PLAYERGUI, ADORNED TO THE PLANK -- never under it. A
-- SurfaceGui that descends from the Workspace draws NO ViewportFrame at all:
-- Roblox disabled that on purpose (DevForum 437055, staff: "for now we disabled
-- rendering of viewportframe if it's in workspace"). The first build parented
-- the face to the plank, and the owner's published board showed its cards
-- with no creature in them (2026-10-05). ResetOnSpawn is off, or a respawn
-- would take every board's face with it.
--
--   THE HEADER    the global UI pass's white studded rim -- UIKit.modal's own
--                 band (RimTop to RimBottom, native studs, a dark keyline),
--                 rebuilt here because UIKit.modal is a ScreenGui's -- and a
--                 white LuckiestGuy TOP CREATURES with a heavy ink line.
--   TWO CARDS     MY PLANTS' card as GardenUI builds it: the plain cream face
--                 under a dark keyline; the rarity's studded colour
--                 (UIKit.studCard, BagLook.StudsByRarity -- a Common keeps the
--                 plain card) with its words on the quiet ink backing; the
--                 creature itself (ItemArt.builder + UIKit.itemPreview, MY
--                 PLANTS' own picture key); its rarity word in its own colour
--                 (RarityFX's light for Mythic, Divine and Secret, on the word
--                 and round the card); its name; its size in the tier colour
--                 (TITAN / COLOSSAL in the wheel's lettering, WheelDraw.prestige;
--                 none for a Secret or an unsized form); what it earns a second.
--                 The size and the rate are a line each: the label's one
--                 "COLOSSAL . $1.46M/s" line is wider than a card.
--                 EVERY WORD IS PlantLabel.content's, at the owner's rate, so
--                 the board and the overhead labels can never disagree.
--   ONE STANDING  the second card is a quiet EMPTY slot: a dark socket in the
--                 plank, the word in cream.
--   NONE          one friendly card across both: NO CREATURES YET.
--
-- THE PICTURES ARE SEPARATE (setPreviews): built while the board is near the
-- camera and FREED when it is not -- two ViewportFrames a plot across every
-- plot is not free -- and the rarity light runs only while that is so
-- (setActive). The words are cheap and stay. Never lit by the world
-- (LightInfluence 0: night does not black it out), never interactive.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))
local PlantLabel = require(Shared:WaitForChild("PlantLabel"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))

local PlotShowcaseView = {}

local SC = GameConfig.Plot.Showcase
local BAG = GameConfig.BagLook
local LOOK = MenuKit.Look
local LABEL = GameConfig.Labels.Plant
local WHITE = Color3.fromRGB(255, 255, 255)

-- What the client's gui is called on a plank, so a re-run can find its own.
PlotShowcaseView.GuiName = "SeedShowcaseFace"

--==============================================================================
-- THE CANVAS, IN PX: the plank's face at PixelsPerStud (432 x 336 at 60).
--==============================================================================
local W = math.floor(SC.BoardSize.X * SC.PixelsPerStud + 0.5)
local H = math.floor(SC.BoardSize.Y * SC.PixelsPerStud + 0.5)
local Z = 2
local MARGIN = 8
local HEADER = 54
local TITLE_SIZE = 38
local CARD_TOP = MARGIN + HEADER + 8
local CARD_W = math.floor((W - MARGIN * 3) / 2)
local CARD_H = H - CARD_TOP - MARGIN
local PICTURE_H = 116
local WORDS_TOP = PICTURE_H + 8
-- READABLE FROM A FEW STUDS: no line smaller than the upgrade board's own
-- smallest (20 px on its 224-px canvas over 4.26 studs = 0.38 studs); 24 px
-- here is 0.40 studs, the name 0.50.
local RARITY_SIZE = 24
local NAME_SIZE = 30
local SIZE_SIZE = 24
local INCOME_SIZE = 26
-- Each line's top inside the card, and its height.
local RARITY_Y, RARITY_H = WORDS_TOP + 3, RARITY_SIZE + 4
local NAME_Y, NAME_H = RARITY_Y + RARITY_H, NAME_SIZE + 6
local SIZE_Y, SIZE_H = NAME_Y + NAME_H, SIZE_SIZE + 4
local INCOME_Y, INCOME_H = SIZE_Y + SIZE_H, INCOME_SIZE + 6
-- With no size to show the rate takes the size's line and the one under it.
local INCOME_ALONE_Y = SIZE_Y + math.floor((SIZE_H + INCOME_H - INCOME_H) / 2)
-- A quiet slot: a dark socket in the plank, its one word in cream.
local QUIET_FILL = 0.45
local QUIET_EDGE = 0.55
local QUIET_WORD = 0.3

PlotShowcaseView.Canvas = Vector2.new(W, H)
-- The text sizes, for PlotShowcaseSpec's readability check.
PlotShowcaseView.TextSizes = {
	title = TITLE_SIZE, rarity = RARITY_SIZE, name = NAME_SIZE, size = SIZE_SIZE, income = INCOME_SIZE,
}
-- The smallest a long name may shrink to, and the width it has to fit in.
PlotShowcaseView.NameMinSize = 23
PlotShowcaseView.NameWidth = CARD_W - 16

export type Card = {
	holder: Frame,
	face: Frame,
	tint: UIGradient,
	edge: UIStroke,
	studs: UIKit.StudCard,
	words: Frame,
	previewHost: Frame,
	preview: UIKit.ItemPreview?,
	rarity: TextLabel,
	rarityFX: RarityFX.Handle,
	edgeFX: RarityFX.Handle,
	-- A Mythic, Divine or Secret card's shine over its studs (2026-10-10).
	shineFX: RarityFX.Handle,
	name: TextLabel,
	size: TextLabel,
	income: TextLabel,
	empty: TextLabel,
	sizeStyle: string?,
	-- The TITAN / COLOSSAL word's light, kept in a list of one so stepping it
	-- builds nothing a frame.
	glints: { WheelDraw.Glint },
	art: ItemArt.Art?,
	artKey: string,
	shownArt: string,
	filled: boolean,
	studded: boolean,
}

export type View = {
	gui: SurfaceGui,
	header: Frame,
	title: TextLabel,
	cards: { Card },
	none: Frame,
	noneTitle: TextLabel,
	noneLine: TextLabel,
	previews: boolean,
	active: boolean,
	key: string,
	-- What the board says right now, for PlotShowcaseSpec and PlotShowcaseUI.
	contents: { PlantLabel.Content },
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

--==============================================================================
-- THE HEADER: the white studded rim, the title on it
--==============================================================================
local function buildHeader(gui: SurfaceGui): (Frame, TextLabel)
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
	title.Text = SC.Title
	return header, title
end

--==============================================================================
-- ONE CARD: GardenUI's cardFor, without the press
--==============================================================================
local function line(parent: Instance, name: string, size: number, colour: Color3, y: number,
	height: number): TextLabel
	local it = MenuKit.text(parent, name, size, colour, Z + 5)
	it.Position = UDim2.fromOffset(6, y)
	it.Size = UDim2.new(1, -12, 0, height)
	return it
end

local function buildCard(gui: SurfaceGui, index: number): Card
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
	local tint = MenuKit.cardFace(face)
	local edge = MenuKit.keyline(face, LOOK.CardEdge, 2)
	local studs = UIKit.studCard(face, 10, Z + 1)
	-- The three rarest's shine (2026-10-10): right after the studs, so over
	-- them and under the picture and words made after it.
	local shineFX = RarityFX.shine(face, 10, Z + 1)
	local words = MenuKit.frame(face, "Words", Z + 4, BAG.StudWords, BAG.StudWordsTransparency, 8)
	words.Position = UDim2.fromOffset(6, WORDS_TOP)
	words.Size = UDim2.new(1, -12, 0, CARD_H - WORDS_TOP - 6)
	words.Visible = false

	local previewHost = plainFrame(face, "Picture", Z + 2)
	previewHost.Position = UDim2.fromOffset(6, 6)
	previewHost.Size = UDim2.new(1, -12, 0, PICTURE_H)

	local rarity = line(face, "Rarity", RARITY_SIZE, LABEL.Separator, RARITY_Y, RARITY_H)
	local rarityInk = MenuKit.keepInk(rarity)
	local name = line(face, "Name", NAME_SIZE, LOOK.Text, NAME_Y, NAME_H)
	-- A long name shrinks rather than runs off the card -- never below the
	-- other lines (PlotShowcaseSpec measures every species' name against it).
	name.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = NAME_SIZE
	fit.MinTextSize = PlotShowcaseView.NameMinSize
	fit.Parent = name
	-- The size word keeps its ink line whatever its tier colour.
	local size = line(face, "Size", SIZE_SIZE, LABEL.Separator, SIZE_Y, SIZE_H)
	MenuKit.keepInk(size)
	local income = line(face, "Income", INCOME_SIZE, LOOK.Money, INCOME_Y, INCOME_H)

	local empty = MenuKit.text(face, "Empty", SIZE_SIZE, BAG.Cream, Z + 5)
	empty.Size = UDim2.fromScale(1, 1)
	empty.Text = SC.EmptySlot
	empty.TextTransparency = QUIET_WORD
	-- Its ink line as quiet as the word (MenuKit gives a light word one).
	local emptyInk = empty:FindFirstChild("Ink")
	if emptyInk and emptyInk:IsA("UIStroke") then
		emptyInk.Transparency = QUIET_WORD
	end
	empty.Visible = false

	return {
		holder = holder,
		face = face,
		tint = tint,
		edge = edge,
		studs = studs,
		words = words,
		previewHost = previewHost,
		preview = nil,
		rarity = rarity,
		rarityFX = RarityFX.text(rarity, rarityInk),
		edgeFX = RarityFX.edge(face, 10, Z + 4),
		shineFX = shineFX,
		name = name,
		size = size,
		income = income,
		empty = empty,
		sizeStyle = nil,
		glints = {},
		art = nil,
		artKey = "",
		shownArt = "",
		filled = false,
		studded = false,
	}
end

--==============================================================================
-- NONE: one friendly card across both slots
--==============================================================================
local function buildNone(gui: SurfaceGui): (Frame, TextLabel, TextLabel)
	local none = Instance.new("Frame")
	none.Name = "None"
	none.Position = UDim2.fromOffset(MARGIN, CARD_TOP)
	none.Size = UDim2.fromOffset(W - MARGIN * 2, CARD_H)
	none.BorderSizePixel = 0
	none.Active = false
	none.ZIndex = Z + 1
	none.Visible = false
	none.Parent = gui
	UIKit.corner(none, 10)
	MenuKit.cardFace(none)
	MenuKit.keyline(none, LOOK.CardEdge, 2)
	local title = MenuKit.text(none, "NoneTitle", 30, LOOK.Text, Z + 5)
	title.AnchorPoint = Vector2.new(0.5, 1)
	title.Position = UDim2.fromScale(0.5, 0.5)
	title.Size = UDim2.new(1, -24, 0, 40)
	title.Text = SC.EmptyTitle
	local line = MenuKit.body(none, "NoneLine", 20, LOOK.Muted, Z + 5)
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.Position = UDim2.new(0.5, 0, 0.5, 6)
	line.Size = UDim2.new(1, -24, 0, 28)
	line.Text = SC.EmptyLine
	return none, title, line
end

--==============================================================================
-- NEW
--
-- On `board` (the plank; its Front face is the one that is read), held in
-- `parent` -- the PlayerGui on a client, NEVER the Workspace (see THE FACE
-- LIVES IN THE PLAYERGUI). Built shown but quiet: no pictures and no rarity
-- light until PlotShowcaseUI says the camera is near.
--==============================================================================
function PlotShowcaseView.new(board: BasePart, parent: Instance): View
	local gui = Instance.new("SurfaceGui")
	gui.Name = PlotShowcaseView.GuiName
	gui.Adornee = board
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(W, H)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = SC.MaxDistance
	gui.Active = false
	gui.ResetOnSpawn = false
	-- GLOBAL layering, for RarityFX: a Secret's light keyline is a twin of the
	-- word one layer BELOW it, as its child, and only Global layering puts a
	-- child behind its parent (PlantLabel's own note).
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = parent

	local header, title = buildHeader(gui)
	local cards: { Card } = {}
	for i = 1, PlotShowcase.Slots do
		table.insert(cards, buildCard(gui, i))
	end
	local none, noneTitle, noneLine = buildNone(gui)
	return {
		gui = gui,
		header = header,
		title = title,
		cards = cards,
		none = none,
		noneTitle = noneTitle,
		noneLine = noneLine,
		previews = false,
		active = false,
		key = "",
		contents = {},
	}
end

--==============================================================================
-- PAINTING
--==============================================================================
local function setSizeStyle(card: Card, style: string?)
	if card.sizeStyle == style then
		return
	end
	local old = card.size:FindFirstChild("Prestige")
	if old then
		old:Destroy()
	end
	table.clear(card.glints)
	card.sizeStyle = style
	if style then
		local glint = WheelDraw.prestige(card.size, style)
		if glint then
			table.insert(card.glints, glint)
		end
	end
end

local function setWords(card: Card, on: boolean)
	card.rarity.Visible = on
	card.name.Visible = on
	card.size.Visible = on
	card.income.Visible = on
end

local function paintQuiet(card: Card)
	card.filled = false
	card.studded = false
	card.art = nil
	card.artKey = ""
	-- A dark socket: the card's face in the words' own ink, let into the plank.
	card.face.BackgroundColor3 = BAG.StudWords
	card.face.BackgroundTransparency = QUIET_FILL
	card.edge.Transparency = QUIET_EDGE
	card.edge.Color = LOOK.CardEdge
	MenuKit.cardTint(card.tint, nil)
	card.studs.set(nil)
	RarityFX.setShine(card.shineFX, nil)
	card.words.Visible = false
	setWords(card, false)
	card.empty.Visible = true
	RarityFX.setText(card.rarityFX, nil, LABEL.Separator)
	RarityFX.setEdge(card.edgeFX, nil, false)
	setSizeStyle(card, nil)
end

local function paintCreature(card: Card, content: PlantLabel.Content, slot: PlotShowcase.Slot)
	card.filled = true
	card.face.BackgroundColor3 = WHITE
	card.face.BackgroundTransparency = 0
	card.edge.Transparency = 0
	card.empty.Visible = false
	setWords(card, true)

	-- The rarity's studded colour; a Common keeps the plain card.
	local studKey = (BAG.StudsByRarity :: any)[content.rarity]
	local spec = card.studs.set(studKey)
	local studded = spec ~= nil
	card.studded = studded
	card.words.Visible = studded
	-- The white card's words stand on a denser band (its `words`, 2026-10-10).
	card.words.BackgroundTransparency = if spec and spec.words then spec.words else BAG.StudWordsTransparency
	RarityFX.setShine(card.shineFX, if studded then content.rarity else nil)
	MenuKit.cardTint(card.tint, GameConfig.RarityColor[content.rarity])
	local rare = RarityFX.edgeColour(content.rarity)
	card.edge.Color = rare or (if studded then BAG.Ink else LOOK.CardEdge)
	RarityFX.setEdge(card.edgeFX, content.rarity, true)

	card.rarity.Text = content.rarityText
	RarityFX.setText(card.rarityFX, content.rarity, content.rarityColour)
	card.name.Text = content.name
	MenuKit.ink(card.name, if studded then WHITE else LOOK.Text)

	-- No size for a Secret or an unsized form: the rate takes the middle of
	-- the two lines rather than leaving a gap above it.
	local sized = content.size ~= nil
	card.size.Visible = sized
	card.size.Text = content.size or ""
	setSizeStyle(card, if sized then content.sizeStyle else nil)
	if not card.sizeStyle then
		card.size.TextColor3 = content.sizeColour
	end
	card.income.Position = UDim2.fromOffset(6, if sized then INCOME_Y else INCOME_ALONE_Y)
	card.income.Text = content.income
	MenuKit.ink(card.income, if studded then BAG.StudMoney else LOOK.Money)

	-- MY PLANTS' own picture key, so a creature already drawn there is a clone.
	card.art = { kind = "plant", speciesId = slot.species, tier = slot.tier }
	card.artKey = "plant|" .. slot.species .. "|" .. tostring(slot.tier)
end

local function refreshPreviews(view: View)
	for _, card in ipairs(view.cards) do
		local want = view.previews and card.filled and card.art ~= nil
		if want then
			local preview = card.preview
			if not preview then
				local made = UIKit.itemPreview(card.previewHost, { name = "Preview", scrim = 1, fit = 0.9 })
				made.hero.Ambient = LOOK.PreviewAmbient
				for _, d in ipairs(made.holder:GetDescendants()) do
					if d:IsA("GuiObject") then
						d.ZIndex = math.max(d.ZIndex, Z + 2)
					end
				end
				card.preview = made
				card.shownArt = ""
				preview = made
			end
			if preview and card.shownArt ~= card.artKey then
				local builder, kind = ItemArt.builder(card.artKey, card.art :: ItemArt.Art)
				preview.setModel(card.artKey, builder, kind)
				card.shownArt = card.artKey
			end
		else
			local preview = card.preview
			if preview then
				-- FREED, not hidden: the ViewportFrame and the model in it go.
				preview.holder:Destroy()
				card.preview = nil
				card.shownArt = ""
			end
		end
	end
end

-- The board for these slots (PlotShowcase.read) at the owner's rate. Writes
-- only when what it says has changed.
function PlotShowcaseView.paint(view: View, slots: { PlotShowcase.Slot }, multiplier: number)
	local contents: { PlantLabel.Content } = {}
	local shown: { PlotShowcase.Slot } = {}
	for _, slot in ipairs(slots) do
		local content = PlantLabel.content(slot.species, slot.tier, multiplier)
		if content and #contents < PlotShowcase.Slots then
			table.insert(contents, content)
			table.insert(shown, slot)
		end
	end
	local parts = { if RarityFX.still() then "still" else "live" }
	for i, c in ipairs(contents) do
		table.insert(parts, table.concat({ shown[i].species, tostring(shown[i].tier), c.rarity, c.name,
			c.size or "", c.sizeStyle or "", c.income }, "|"))
	end
	local key = table.concat(parts, "/")
	if key == view.key then
		return
	end
	view.key = key
	view.contents = contents
	local any = #contents > 0
	view.none.Visible = not any
	for i, card in ipairs(view.cards) do
		card.holder.Visible = any
		local content = contents[i]
		if content then
			paintCreature(card, content, shown[i])
		else
			paintQuiet(card)
		end
	end
	refreshPreviews(view)
	PlotShowcaseView.setActive(view, view.active)
end

--==============================================================================
-- NEAR AND FAR
--==============================================================================
-- The pictures: built while `on`, freed while not.
function PlotShowcaseView.setPreviews(view: View, on: boolean)
	if view.previews == on then
		return
	end
	view.previews = on
	refreshPreviews(view)
end

-- The rarity light: running only on a board somebody can see up close.
function PlotShowcaseView.setActive(view: View, on: boolean)
	view.active = on
	for _, card in ipairs(view.cards) do
		local live = on and card.filled
		RarityFX.setActive(card.rarityFX, live)
		RarityFX.setActive(card.edgeFX, live)
		RarityFX.setActive(card.shineFX, live)
	end
end

-- Shown or hidden whole (an unowned plot, a garden not yet known).
function PlotShowcaseView.setShown(view: View, on: boolean)
	view.gui.Enabled = on
	if not on then
		PlotShowcaseView.setActive(view, false)
		PlotShowcaseView.setPreviews(view, false)
	end
end

-- Whether a TITAN or COLOSSAL word on this board needs stepping.
function PlotShowcaseView.hasGlint(view: View): boolean
	for _, card in ipairs(view.cards) do
		if card.filled and #card.glints > 0 then
			return true
		end
	end
	return false
end

-- Steps a TITAN or COLOSSAL word's light (the caller's one update, as PlantUI
-- steps the labels'); still under reduced motion. A gradient is written only
-- when its frame changes (WheelDraw.glint).
function PlotShowcaseView.step(view: View, t: number)
	local still = RarityFX.still()
	for _, card in ipairs(view.cards) do
		if card.filled and #card.glints > 0 then
			WheelDraw.glint(card.glints, t, still)
		end
	end
end

function PlotShowcaseView.destroy(view: View)
	for _, card in ipairs(view.cards) do
		RarityFX.forget(card.rarityFX)
		RarityFX.forget(card.edgeFX)
		RarityFX.forget(card.shineFX)
		table.clear(card.glints)
		card.preview = nil
	end
	view.gui:Destroy()
end

return PlotShowcaseView
