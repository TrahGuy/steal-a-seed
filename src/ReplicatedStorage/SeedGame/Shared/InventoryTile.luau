--!strict
--==============================================================================
-- Steal a Seed :: InventoryTile (2026-10-03, the owner's compact Bag + free
-- hotbar)
--
-- HOW ONE BAG TILE IS DRAWN. A small square in the hotbar's slate and ink
-- (GameConfig.Hotbar, `T` below), so the Bag and the strip read as one set:
--
--   preview     the item, large and centred in the top of the tile
--   name        its visible name, up to two lines, in cream
--   variant     its size, or what kind of thing it is, in that size's colour --
--               or, where it IS the rarity word, that word styled (RarityFX)
--   count       "x3" top right, for identical copies (the tickets' balance)
--   badge       top left, on a phone: the hidden slot (6-0) this copy is on
--   heart       bottom right of the preview: a favourite
--   accent      a thin bar on the bottom edge, a grown plant's rarity colour
--
-- IN YOUR HANDS it wears the strip's held look -- the warm amber-to-green edge,
-- the lit plate, an amber name -- and the strip's small amber diamond on the
-- top-right corner. RESTORING (after a respawn, until the server has put it
-- back) it is dimmed and says so. Two sizes: 96 x 100 on a desktop and 96 x 116
-- on a phone, where the words are a point or two larger.
--
-- MYTHIC, DIVINE, SECRET (2026-10-03, the owner's inventory pass): the edge
-- takes the rarity's colour and a small light travels round it (RarityFX), but
-- only while nothing outranks it -- in hand, the selection's keyline;
-- restoring, the colour alone. Every other rarity keeps the plain edge.
--
-- Like HotbarCard it listens to nothing: InventoryPanel builds, wires and
-- paints it. The heart is drawn from frames -- two discs and a turned square --
-- so no glyph can come out as a box.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))

local InventoryTile = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local HEART = Color3.fromRGB(255, 96, 128)
local LOOK = GameConfig.BagLook
InventoryTile.HeartColour = HEART

-- The "in hand" mark, shared with the strip (HotbarCard): a small amber
-- diamond with an ink keyline, centred just outside the top-right corner so it
-- never sits on the count. A turned square, so no glyph can come out a box.
function InventoryTile.marker(parent: Instance, size: number, colour: Color3, ink: Color3,
	zIndex: number): Frame
	local m = Instance.new("Frame")
	m.Name = "InHand"
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.Position = UDim2.new(1, 1, 0, -1)
	m.Size = UDim2.fromOffset(size, size)
	m.Rotation = 45
	m.BackgroundColor3 = colour
	m.BorderSizePixel = 0
	m.Active = false
	m.Visible = false
	m.ZIndex = zIndex
	m.Parent = parent
	UIKit.corner(m, 2)
	local edge = UIKit.stroke(m, ink, 1.25)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return m
end

export type Heart = { frame: Frame, paint: (Color3, number) -> () }

-- A heart `size` px across, from frames, in `parent`. paint(colour, transparency).
function InventoryTile.heart(parent: Instance, size: number, zIndex: number): Heart
	local frame = Instance.new("Frame")
	frame.Name = "Heart"
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex
	frame.Parent = parent
	local pieces: { Frame } = {}
	local function piece(name: string, x: number, y: number, w: number, h: number, round: boolean, turn: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.Rotation = turn
		f.BorderSizePixel = 0
		f.ZIndex = zIndex
		f.Parent = frame
		if round then
			UIKit.corner(f, size)
		end
		table.insert(pieces, f)
	end
	piece("Left", 0.3, 0.34, 0.52, 0.52, true, 0)
	piece("Right", 0.7, 0.34, 0.52, 0.52, true, 0)
	piece("Point", 0.5, 0.56, 0.52, 0.52, false, 45)
	local function paint(colour: Color3, transparency: number)
		for _, f in ipairs(pieces) do
			f.BackgroundColor3 = colour
			f.BackgroundTransparency = transparency
		end
	end
	paint(HEART, 0)
	return { frame = frame, paint = paint }
end

export type Tile = {
	holder: Frame,
	button: TextButton,
	back: Frame,
	backTint: UIGradient,
	studs: UIKit.StudCard,
	words: Frame,
	plate: UIStroke,
	ringTint: UIGradient,
	rim: UIStroke,
	preview: UIKit.ItemPreview,
	name: TextLabel,
	nameFit: UITextSizeConstraint,
	variant: TextLabel,
	count: TextLabel,
	badge: TextLabel,
	heart: Heart,
	accent: Frame,
	marker: Frame,
	fxEdge: RarityFX.Handle,
	fxText: RarityFX.Handle,
	pop: UIKit.CardPop,
	compact: boolean,
	shownKey: string,
}

export type Paint = {
	name: string,
	variant: string,
	variantColour: Color3,
	count: string?,
	badge: string?,
	favourite: boolean,
	held: boolean,
	restoring: boolean,
	accent: Color3?,
	-- 2026-10-03: the rarity the player may see, and whether `variant` is it.
	rarity: string?,
	variantIsRarity: boolean?,
	-- 2026-10-04: its studded background (InventoryModel.face's `studs`).
	studs: string?,
}

function InventoryTile.build(parent: Instance, T: any, zIndex: number): Tile
	-- The grid's cell, and the face the pop scales inside it: the grid writes
	-- the cell's Position on every reflow, so nothing animates the cell itself.
	local holder = Instance.new("Frame")
	holder.Name = "Tile"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = zIndex
	holder.Parent = parent

	local button = Instance.new("TextButton")
	button.Name = "Face"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.fromScale(1, 1)
	-- The face is the Back frame below: the button itself stays clear, so its
	-- rarity keyline is never tinted by a gradient on the same object.
	button.BackgroundColor3 = T.Plate
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = zIndex + 1
	button.Parent = holder
	UIKit.corner(button, 8)
	--==========================================================================
	-- AN OPAQUE, DEEPER EMERALD SLATE (2026-10-04, the readability brief)
	--
	-- The hotbar's see-through slate read as muddy grey-green on the light
	-- Bag. The tile keeps its dark identity -- silhouettes and rare plants need
	-- a dark ground -- as an OPAQUE emerald-to-slate face (BagLook.Tile*),
	-- under the preview (made first, so the preview stands over it).
	--==========================================================================
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BorderSizePixel = 0
	back.Active = false
	back.ZIndex = zIndex + 1
	back.Parent = button
	UIKit.corner(back, 8)
	local backTint = UIKit.gradient(back, LOOK.TileTop, LOOK.TileBottom)
	-- THE COLOURFUL STUDDED TILE (2026-10-04): over the slate, the upload for
	-- what the tile is (its rarity's nearest, or its kind's; UIKit.studCard --
	-- the solid colour until the picture has loaded), its words on a quiet ink
	-- backing. A Common and an ordinary pod keep the slate.
	local studs = UIKit.studCard(back, 8, zIndex + 1)
	local words = Instance.new("Frame")
	words.Name = "Words"
	words.BackgroundColor3 = LOOK.StudWords
	words.BackgroundTransparency = LOOK.StudWordsTransparency
	words.BorderSizePixel = 0
	words.Active = false
	words.Visible = false
	words.ZIndex = zIndex + 3
	words.Parent = button
	UIKit.corner(words, 6)
	local plate = UIKit.stroke(button, T.Edge, 1, T.EdgeTransparency)
	-- Border: a TextButton's default stroke outlines its (empty) text instead.
	plate.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local ringTint = Instance.new("UIGradient")
	ringTint.Color = ColorSequence.new(T.LitTop, T.LitBottom)
	ringTint.Rotation = 90
	ringTint.Enabled = false
	ringTint.Parent = plate

	local rimFrame = Instance.new("Frame")
	rimFrame.Name = "Rim"
	rimFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	rimFrame.Position = UDim2.fromScale(0.5, 0.5)
	rimFrame.Size = UDim2.new(1, -3, 1, -3)
	rimFrame.BackgroundTransparency = 1
	rimFrame.BorderSizePixel = 0
	rimFrame.ZIndex = zIndex + 1
	rimFrame.Parent = button
	UIKit.corner(rimFrame, 7)
	local rim = UIKit.stroke(rimFrame, T.Edge, 1, 1)

	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.fromOffset(88, 54),
		position = UDim2.fromOffset(4, 3),
		scrim = 1,
		fit = 0.92,
	})
	preview.hero.Ambient = T.PreviewAmbient

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextColor3 = LOOK.Cream
	name.TextWrapped = true
	name.TextScaled = true
	name.TextYAlignment = Enum.TextYAlignment.Center
	name.Text = ""
	name.ZIndex = zIndex + 4
	name.Parent = button
	UIKit.stroke(name, T.Ink, 1)
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.Parent = name

	local variant = Instance.new("TextLabel")
	variant.Name = "Variant"
	variant.BackgroundTransparency = 1
	variant.Font = Enum.Font.FredokaOne
	variant.TextTruncate = Enum.TextTruncate.AtEnd
	variant.Text = ""
	variant.ZIndex = zIndex + 4
	variant.Parent = button
	local variantLine = UIKit.stroke(variant, T.Ink, 1)

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, -4, 0, 3)
	count.Size = UDim2.fromOffset(44, 16)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.FredokaOne
	count.TextSize = 13
	count.TextColor3 = T.StackColour
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.Text = ""
	count.Visible = false
	count.ZIndex = zIndex + 5
	count.Parent = button
	UIKit.stroke(count, T.Ink, T.NumeralOutline)

	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Position = UDim2.fromOffset(3, 3)
	badge.Size = UDim2.fromOffset(18, 16)
	badge.BackgroundColor3 = T.Ink
	badge.BackgroundTransparency = 0.2
	badge.BorderSizePixel = 0
	badge.Font = Enum.Font.FredokaOne
	badge.TextSize = 12
	badge.TextColor3 = T.NumeralLit
	badge.Text = ""
	badge.Visible = false
	badge.ZIndex = zIndex + 5
	badge.Parent = button
	UIKit.corner(badge, 5)

	local heart = InventoryTile.heart(button, 13, zIndex + 5)
	heart.frame.AnchorPoint = Vector2.new(1, 1)
	heart.frame.Visible = false

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.AnchorPoint = Vector2.new(0.5, 1)
	accent.Position = UDim2.new(0.5, 0, 1, -3)
	accent.Size = UDim2.new(0.56, 0, 0, 2)
	accent.BorderSizePixel = 0
	accent.Visible = false
	accent.ZIndex = zIndex + 4
	accent.Parent = button
	UIKit.corner(accent, 1)

	-- The light round a Mythic, Divine or Secret, on the border under the
	-- words; the rarity word's own light; the in-hand diamond over everything.
	local fxEdge = RarityFX.edge(button, 8, zIndex + 3)
	local fxText = RarityFX.text(variant, variantLine)
	local marker = InventoryTile.marker(button, T.MarkerSize, T.Marker, T.Ink, zIndex + 6)

	local press = Instance.new("UIScale")
	press.Parent = button
	local pop = UIKit.cardPop(button, press, {
		hoverScale = 1.04,
		pressScale = 0.97,
		glow = rim,
		glowRest = 1,
		glowHover = T.HoverEdgeTransparency,
		sound = false,
	})

	local tile: Tile = {
		holder = holder,
		button = button,
		back = back,
		backTint = backTint,
		studs = studs,
		words = words,
		plate = plate,
		ringTint = ringTint,
		rim = rim,
		preview = preview,
		name = name,
		nameFit = nameFit,
		variant = variant,
		count = count,
		badge = badge,
		heart = heart,
		accent = accent,
		marker = marker,
		fxEdge = fxEdge,
		fxText = fxText,
		pop = pop,
		compact = false,
		shownKey = "",
	}
	InventoryTile.shape(tile, false)
	return tile
end

-- The two sizes. Desktop 96 x 100: a 54-px picture, the name 22 tall at 10-12
-- pt, the variant at 11. Phone 96 x 116: a 62-px picture, the name 26 tall at
-- 11-13, the variant 16 tall at 12. The picture is most of the tile (the
-- approved mockup), the words tucked under it and clear of the accent bar.
function InventoryTile.shape(tile: Tile, compact: boolean)
	tile.compact = compact
	local previewH = if compact then 62 else 54
	tile.preview.holder.Size = UDim2.fromOffset(88, previewH)
	local nameTop = 3 + previewH + 1
	local nameH = if compact then 26 else 22
	tile.name.Position = UDim2.fromOffset(4, nameTop)
	tile.name.Size = UDim2.fromOffset(88, nameH)
	tile.nameFit.MinTextSize = if compact then 11 else 10
	tile.nameFit.MaxTextSize = if compact then 13 else 12
	local variantH = if compact then 16 else 14
	tile.variant.Position = UDim2.fromOffset(4, nameTop + nameH + 1)
	tile.variant.Size = UDim2.fromOffset(88, variantH)
	tile.variant.TextSize = if compact then 12 else 11
	tile.heart.frame.Position = UDim2.fromOffset(92, 3 + previewH)
	tile.words.Position = UDim2.fromOffset(3, nameTop - 1)
	tile.words.Size = UDim2.fromOffset(90, nameH + variantH + 3)
end

-- On screen with the Bag open, or not: only then does a light move.
function InventoryTile.animate(tile: Tile, on: boolean)
	RarityFX.setActive(tile.fxEdge, on)
	RarityFX.setActive(tile.fxText, on)
end

function InventoryTile.paint(tile: Tile, T: any, p: Paint)
	tile.name.Text = p.name
	tile.name.TextColor3 = if p.held then T.NumeralLit else LOOK.Cream
	tile.variant.Text = if p.restoring then "Restoring…" else p.variant
	-- Styled only where the line IS the rarity word, never over a size.
	RarityFX.setText(tile.fxText, if not p.restoring and p.variantIsRarity then p.rarity else nil,
		if p.restoring then T.CountLoading else p.variantColour)
	local count = p.count
	tile.count.Visible = count ~= nil
	if count then
		tile.count.Text = count
	end
	local badge = p.badge
	tile.badge.Visible = badge ~= nil
	if badge then
		tile.badge.Text = badge
	end
	tile.heart.frame.Visible = p.favourite
	local accent = p.accent
	tile.accent.Visible = accent ~= nil
	if accent then
		tile.accent.BackgroundColor3 = accent
	end
	tile.preview.hero.ImageTransparency = if p.restoring then 0.6 else 0
	-- In your hands: the strip's held look and its corner mark. Otherwise a
	-- rarest rarity's coloured edge, its light only while nothing outranks it.
	local rare = RarityFX.edgeColour(p.rarity)
	-- Held: the lit emerald; otherwise the opaque emerald slate.
	tile.backTint.Color = ColorSequence.new(if p.held then LOOK.TileHeld else LOOK.TileTop, LOOK.TileBottom)
	local studded = tile.studs.set(p.studs) ~= nil
	tile.words.Visible = studded
	tile.ringTint.Enabled = p.held
	-- A studded tile's plain edge is the ink keyline; held and rare keep theirs.
	tile.plate.Color = if p.held then WHITE elseif rare then rare elseif studded then LOOK.Ink else T.Edge
	tile.plate.Thickness = if p.held then T.LitThickness elseif studded then 1.5 else 1
	tile.plate.Transparency = if p.held then 0 elseif rare then 0.05 elseif studded then 0 else T.EdgeTransparency
	tile.marker.Visible = p.held
	RarityFX.setEdge(tile.fxEdge, p.rarity, not p.held and not p.restoring)
end

return InventoryTile
