--!strict
-- Steal a Seed :: UIKit
--
-- The screen furniture more than one client builds.
--
--==============================================================================
-- WHY THIS EXISTS
--
-- Four surfaces wanted a texture and three wanted the same rail button. Four
-- hand-rolled grids is how the shop panel and the Index button end up textured
-- at different pitches, and three hand-rolled buttons is how one of them quietly
-- keeps a green stroke after the other two go gold.
--
-- Same reasoning as GameConfig.compact: the second copy of a thing is where the
-- drift starts, so there is one copy.
--
-- NOT a *Service, and not in GameConfig. GameConfig holds names, structure and
-- the curves; it does not build Instances. This does nothing but build them.
--
--==============================================================================
-- THE RAIL IS DRAWN AGAIN, NOT CROPPED
--
-- It was three cropped screenshots of another game's UI for a while. They looked
-- cropped because they were: the black outline and the diamond lattice were both
-- clipped at the sides, the Index badge had to be mirrored out of the artwork,
-- and every button was pinned to the source's native 123 x 48 because there was
-- no resolution to spare.
--
-- HANDOFF already wrote down where that ends -- "redrawing the same look in code
-- carries none of that risk and scales to any size" -- so this is that. The
-- slab, the lattice, the icons and the labels are all instances now. Nothing on
-- the HUD is an asset id.
--==============================================================================

local TweenService = game:GetService("TweenService")

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local UIKit = {}

local RAIL = GameConfig.Rail
local BLACK = Color3.fromRGB(0, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)

--==============================================================================
-- THE SMALL ONES
--==============================================================================
function UIKit.corner(parent: Instance, radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function UIKit.stroke(parent: Instance, colour: Color3, thickness: number,
	transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

function UIKit.gradient(parent: Instance, top: Color3, bottom: Color3): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = 90
	g.Parent = parent
	return g
end

--==============================================================================
-- OUTLINED TYPE
--
-- LuckiestGuy with a black UIStroke, which is the face and the recipe CashUI
-- established: of the six heavy display fonts this engine ships it is the only
-- one that is heavy AND slanted AND rounded. Every panel title, card name, price
-- and rarity word on the HUD goes through here, so none of them can drift into
-- Gotham on their own.
--
-- The outline is not decoration. A white word on a lattice has no plate behind
-- it and the stroke is the whole of its readability.
--==============================================================================
function UIKit.outlined(parent: Instance, name: string, size: number,
	colour: Color3, thickness: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.TextSize = size
	label.TextColor3 = colour
	label.Text = ""
	label.Parent = parent
	UIKit.stroke(label, BLACK, thickness or 2)
	return label
end

--==============================================================================
-- THE DIAMOND LATTICE
--
-- Two families of parallel diagonal lines crossing at right angles. The diamonds
-- are the cells between them, which is the cheap way round: a grid of rotated
-- cells costs one instance per DIAMOND, and lines cost one per ROW. A rail
-- button is eighteen frames this way and a full panel about forty-six.
--
-- Built once and never touched again unless the surface resizes. There is no
-- per-frame work here at all, which is the half of Rule 8 that actually matters
-- on a phone -- the instance count is paid at login, once.
--
--==============================================================================
-- ClipsDescendants DOES NOT CLIP A ROTATED CHILD. MEASURED, NOT ASSUMED.
--
-- The first version drew one long line per row -- the box's diagonal plus a
-- margin -- rotated it 45 degrees, and put the lot in a ClipsDescendants holder
-- to trim the overhang. The holder reported `clips = true` and clipped nothing:
--
--     Index button   position 12, 12   size 130 x 50
--     its lattice    lines 176 long, spanning x -87..241, y -40..114
--
-- So every surface sprayed a diamond pattern a hundred pixels past its own
-- border, across the sky, the grass and everything else on screen. It looked
-- like the texture belonged to the world rather than to the button.
--
-- THE FIX IS NOT A BETTER CLIP, IT IS A SHORTER LINE. Each row is drawn as the
-- exact CHORD where its infinite line crosses the box, so no part of any line is
-- ever outside in the first place and no clipping is required.
--
-- With the box centred, half-width a and half-height b, a line of the +45 family
-- is the set of points d*n + t*u where u = (c, c) runs along it, n = (c, -c)
-- runs across it, c = sin 45, and d is the row's offset. Then
--
--     |P.x| <= a   ->   |d + t| <= a / c
--     |P.y| <= b   ->   |t - d| <= b / c
--
-- and intersecting those two ranges gives the visible span directly. The -45
-- family works out to the identical pair, so one piece of arithmetic does both.
-- A row whose span comes out empty is a row that misses the box, and is skipped
-- rather than drawn as a zero-length frame.
--
-- INSET, because a rounded corner is not a corner. The chords are exact to the
-- RECTANGLE, and the surface they sit on has a corner radius -- so a line
-- through a corner would show outside the rounded border by about 0.3 of the
-- radius. A few pixels of inset puts the whole lattice inside the stroke, which
-- is where it was always meant to be.
--==============================================================================
export type LatticeOptions = {
	spacing: number?,
	thickness: number?,
	colour: Color3?,
	transparency: number?,
	inset: number?,
}

local SIN45 = 0.70710678
local ROOT2 = 1.41421356

function UIKit.lattice(parent: GuiObject, options: LatticeOptions?): Frame
	local opts: LatticeOptions = options or {}
	local spacing = opts.spacing or 24
	local thickness = opts.thickness or 2
	local inset = opts.inset or 3
	local colour = opts.colour or WHITE
	local transparency = opts.transparency or 0.88

	local holder = Instance.new("Frame")
	holder.Name = "Lattice"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	-- Behind the content and never in the way of a click: a Frame is not Active,
	-- so it does not swallow input.
	holder.ZIndex = 0
	holder.Parent = parent

	local builtFor = Vector2.zero

	local function build(size: Vector2)
		builtFor = size
		holder:ClearAllChildren()

		local a = size.X * 0.5 - inset
		local b = size.Y * 0.5 - inset
		if a < 2 or b < 2 then
			return
		end

		local A = a * ROOT2
		local B = b * ROOT2
		-- No row past (A + B) / 2 can touch the box, so that is where to stop.
		local count = math.ceil((A + B) * 0.5 / spacing)

		for _, dir in ipairs({ 1, -1 }) do
			local ux, uy = SIN45, SIN45 * dir
			local nx, ny = SIN45, -SIN45 * dir
			for row = -count, count do
				local d = row * spacing
				local low = math.max(-A - d, d - B)
				local high = math.min(A - d, d + B)
				local span = high - low
				if span > 1 then
					local middle = (low + high) * 0.5
					local line = Instance.new("Frame")
					line.Name = "Line"
					line.AnchorPoint = Vector2.new(0.5, 0.5)
					line.Position = UDim2.new(0.5, d * nx + middle * ux,
						0.5, d * ny + middle * uy)
					line.Size = UDim2.fromOffset(math.floor(span), thickness)
					line.Rotation = 45 * dir
					line.BackgroundColor3 = colour
					line.BackgroundTransparency = transparency
					line.BorderSizePixel = 0
					line.ZIndex = 0
					line.Parent = holder
				end
			end
		end
	end

	--==========================================================================
	-- REBUILT ON A RESIZE, AND ONLY ON THE TRAILING EDGE
	--
	-- The lattice is cut to the surface's real pixels, so a surface that changes
	-- size needs new chords -- a modal capped at 480 and opened on a 300-pixel
	-- phone is not the same rectangle.
	--
	-- Deferred, because AbsoluteSize also moves while the open tween runs its
	-- UIScale from 0.92 to 1. Rebuilding forty-six frames every frame of that
	-- would be the per-frame allocation Rule 8 exists to prevent; waiting for
	-- the tween to settle costs one rebuild instead of ten, and the panel is
	-- still faded out for most of it.
	--==========================================================================
	local pending = false
	local function request()
		if pending then
			return
		end
		pending = true
		task.delay(0.12, function()
			pending = false
			local size = parent.AbsoluteSize
			if math.abs(size.X - builtFor.X) < 2 and math.abs(size.Y - builtFor.Y) < 2 then
				return
			end
			build(size)
		end)
	end

	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(request)
	-- A fixed-size button already knows its pixels; a panel inside a layout does
	-- not, and waits for the signal.
	if parent.AbsoluteSize.X > 0 and parent.AbsoluteSize.Y > 0 then
		build(parent.AbsoluteSize)
	end

	return holder
end

--==============================================================================
-- THE SLAB
--
-- A rounded rectangle, a thick black outline, a vertical gradient and a lattice
-- inside it. The rail buttons are slabs, the panels are slabs, and the shop's
-- buy buttons are slabs -- one builder, so the lattice on a button is the same
-- lattice as the one on the panel behind it, at the same angle.
--
-- NO ClipsDescendants ON THE SLAB ITSELF. Both live badges hang half outside a
-- corner on purpose, and a slab that clipped would cut them in half. The lattice
-- does its own clipping (above) so nothing here has to.
--==============================================================================
export type SlabOptions = {
	size: UDim2?,
	face: Color3,
	shade: Color3?,
	radius: number?,
	outline: Color3?,
	outlineThickness: number?,
	latticeSpacing: number?,
	latticeTransparency: number?,
}

function UIKit.slab(parent: Instance, options: SlabOptions): ImageButton
	local radius = options.radius or 10
	local thickness = options.outlineThickness or RAIL.OutlineThickness

	-- An ImageButton with no Image: a TextButton would render a text pass this
	-- never needs, and the label is a child so it can carry its own stroke.
	local slab = Instance.new("ImageButton")
	slab.Name = "Slab"
	slab.Size = options.size or UDim2.fromOffset(RAIL.WideSize.X, RAIL.WideSize.Y)
	slab.BackgroundColor3 = options.face
	slab.BorderSizePixel = 0
	slab.AutoButtonColor = false
	slab.Parent = parent
	UIKit.corner(slab, radius)
	UIKit.stroke(slab, options.outline or RAIL.Outline, thickness)
	if options.shade then
		UIKit.gradient(slab, options.face, options.shade)
	end

	UIKit.lattice(slab, {
		spacing = options.latticeSpacing or 20,
		thickness = 2,
		transparency = options.latticeTransparency or 0.86,
		-- Clear of the rounded corner, which is where a chord cut to the plain
		-- rectangle would otherwise poke out past the stroke.
		inset = math.max(3, math.floor(radius * 0.35)),
	})

	return slab
end

--==============================================================================
-- THE ICONS
--
-- Frames, like everything else. Each is drawn inside a square box and scales
-- with it, so the same book works at 26 px on a rail button and at 34 in a title
-- bar without a second asset.
--==============================================================================
local function piece(parent: GuiObject, name: string, cx: number, cy: number,
	w: number, h: number, colour: Color3, radius: number?, rotation: number?,
	z: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(cx, cy)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.ZIndex = z or 2
	if rotation then
		f.Rotation = rotation
	end
	f.Parent = parent
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radius, 0)
		c.Parent = f
	end
	return f
end

UIKit.piece = piece

local function iconBox(parent: GuiObject, name: string, size: number): Frame
	local box = Instance.new("Frame")
	box.Name = name
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Position = UDim2.new(0, 10, 0.5, 0)
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundTransparency = 1
	box.ZIndex = 3
	box.Parent = parent
	return box
end

--==============================================================================
-- AN OPEN BOOK, AND NOTHING THINNER THAN TWO PIXELS
--
-- The first pass ruled each page with two lines. At a 28-pixel icon a rule is a
-- pixel and a half tall, and four of them around a spine turned the whole thing
-- into a white grid -- it read as a window, not a book. Anything under about
-- 0.09 of the box is mush at this size, so the rules are gone and the shape does
-- the work: two pages tilted apart over a dark spine.
--==============================================================================
function UIKit.bookIcon(parent: GuiObject, size: number, ink: Color3): Frame
	local box = iconBox(parent, "Book", size)
	piece(box, "Spine", 0.5, 0.54, 0.16, 0.74, ink, 0.06, nil, 3)
	piece(box, "PageL", 0.28, 0.50, 0.46, 0.62, WHITE, 0.10, -7, 4)
	piece(box, "PageR", 0.72, 0.50, 0.46, 0.62, WHITE, 0.10, 7, 4)
	-- A shaded edge under each page: the difference between a sheet of paper and
	-- a stack of them.
	piece(box, "EdgeL", 0.28, 0.76, 0.46, 0.11, ink, 0.10, -7, 5)
	piece(box, "EdgeR", 0.72, 0.76, 0.46, 0.11, ink, 0.10, 7, 5)
	return box
end

-- A shopping cart: handle, rim, basket, two wheels. Nothing thinner than a
-- tenth of the box, for the same reason the book lost its rules.
function UIKit.cartIcon(parent: GuiObject, size: number, ink: Color3): Frame
	local box = iconBox(parent, "Cart", size)
	piece(box, "Handle", 0.17, 0.28, 0.30, 0.12, WHITE, 0.30, -48, 3)
	piece(box, "Rim", 0.56, 0.30, 0.74, 0.14, WHITE, 0.30, nil, 4)
	piece(box, "Basket", 0.56, 0.50, 0.64, 0.34, WHITE, 0.16, nil, 3)
	piece(box, "Wheel", 0.40, 0.80, 0.19, 0.19, WHITE, 0.5, nil, 3)
	piece(box, "Wheel", 0.72, 0.80, 0.19, 0.19, WHITE, 0.5, nil, 3)
	return box
end

--==============================================================================
-- A SPROUT, WHICH IS THE ONE ICON THAT WAS ALREADY DRAWN
--
-- GardenUI built this out of frames back when the rail was gold plate, and it
-- kept drawing it after the other two were painted into artwork -- there was no
-- Garden button in the reference to crop. It moves here unchanged in spirit so
-- all three icons come from one file.
--==============================================================================
function UIKit.sproutIcon(parent: GuiObject, size: number, stem: Color3,
	leaf: Color3): Frame
	local box = Instance.new("Frame")
	box.Name = "Sprout"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundTransparency = 1
	box.ZIndex = 3
	box.Parent = parent

	piece(box, "Stem", 0.5, 0.62, 0.10, 0.56, stem, 0.3, nil, 3)
	piece(box, "Leaf", 0.29, 0.42, 0.36, 0.17, leaf, 0.5, -26, 4)
	piece(box, "Leaf", 0.71, 0.42, 0.36, 0.17, leaf, 0.5, 26, 4)
	piece(box, "Leaflet", 0.66, 0.24, 0.24, 0.12, leaf, 0.5, -18, 4)
	return box
end

--==============================================================================
-- THE RAIL BUTTON
--
-- A slab, an icon and -- for the two wide ones -- a word. Callers still parent
-- their badges into it, and it still does not clip, because both badges hang
-- half outside a corner on purpose.
--==============================================================================
export type RailOptions = {
	name: string,
	face: Color3,
	shade: Color3,
	label: string?,
	wide: boolean?,
}

--==============================================================================
-- ALL THREE BUTTONS LIVE IN ONE LAYER, ABOVE EVERY DIMMER
--
-- Each panel used to keep its button in its own ScreenGui, which was fine while
-- panels were docked strips. It stopped being fine the moment they became
-- modals: a dimmer fills the screen, ScreenGuis stack by DisplayOrder, and the
-- Shop's dimmer at 32 sat on top of the Garden button at 30. Clicking Garden
-- while the Shop was open hit the DIMMER -- the shop closed, the garden never
-- opened, and nothing errored anywhere.
--
-- So the rail is its own layer above all of them. The requirement for these
-- panels is that the buttons stay in the corners and stay CLICKABLE, and one
-- shared ScreenGui is what makes the second half true.
--
-- Shared, so it is found rather than destroyed and rebuilt: a script that
-- re-runs takes out its OWN button by name and leaves the other two standing.
--==============================================================================
local RAIL_LAYER = "SeedRail"

function UIKit.railLayer(playerGui: Instance): ScreenGui
	local existing = playerGui:FindFirstChild(RAIL_LAYER)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	local layer = Instance.new("ScreenGui")
	layer.Name = RAIL_LAYER
	layer.ResetOnSpawn = false
	-- Above every panel dimmer, below SeedAlert's RUN vignette at 50 -- an alarm
	-- outranks a menu.
	layer.DisplayOrder = 40
	layer.Parent = playerGui
	return layer
end

function UIKit.railButton(playerGui: Instance, options: RailOptions): ImageButton
	local wide = options.wide ~= false
	local size = if wide then RAIL.WideSize else RAIL.SquareSize

	local layer = UIKit.railLayer(playerGui)
	local previous = layer:FindFirstChild(options.name)
	if previous then
		previous:Destroy()
	end

	local slab = UIKit.slab(layer, {
		size = UDim2.fromOffset(size.X, size.Y),
		face = options.face,
		shade = options.shade,
		radius = RAIL.Radius,
		latticeSpacing = 18,
		latticeSize = size,
	})
	slab.Name = options.name

	if options.label then
		local label = UIKit.outlined(slab, "Label", RAIL.LabelSize, WHITE, 2.5)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 1)
		label.Size = UDim2.new(1, -(RAIL.IconSize + 24), 0, RAIL.LabelSize + 6)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = options.label
		label.ZIndex = 3
	end

	return slab
end

--==============================================================================
-- A PLANT, DRAWN FLAT
--
-- The Index used to be a list of coloured squares, which said nothing: a swatch
-- of Bellchime purple is the FORM RARITY colour, so five species read as five
-- tiers rather than as five plants. What a player recognises across a bed is the
-- SILHOUETTE -- cube, orb, teardrop, mushroom, bell -- so that is what a card
-- has to show.
--
-- Frames, not a ViewportFrame. Five live creatures at 29 to 40 parts each is 170
-- parts of camera work behind a panel, on a phone, for a picture that never
-- moves. These are the same shapes CreatureModel builds, drawn once and flat.
--
-- The engine's shape rules come along with them: a mushroom cap is a rounded
-- pill with a gill bar cutting its underside, a teardrop is a circle with a
-- rotated square behind it, and a bell is stacked tiers widening downward. Same
-- approximations, same reasons.
--
-- ONE SQUARE BOX, SCALE COORDINATES. Every number below is a fraction of the
-- box, so a card can size the portrait however it likes.
--==============================================================================
export type PlantSpec = {
	form: string,
	body: Color3,
	crown: Color3,
	accent: Color3,
	leaf: Color3,
	stem: Color3,
	soil: Color3,
	blush: Color3,
}

local FACE_DARK = Color3.fromRGB(38, 34, 40)
local FACE_WHITE = Color3.fromRGB(252, 252, 250)

--==============================================================================
-- THE FACE, AT PORTRAIT SIZE
--
-- The model's face is nine parts and so is this one: two eyes, two glints, two
-- cheeks, three smile blocks. The rules that make it read come with it -- the
-- glint sits upper-LEFT on BOTH eyes rather than being mirrored, because one
-- shared light is what makes two circles look like a face instead of two googly
-- eyes, and the smile is three blocks with the ends lifted because one bar reads
-- as a grimace.
--==============================================================================
local function drawFace(parent: GuiObject, cx: number, cy: number, w: number,
	blush: Color3)
	local eyeD = w * 0.22
	local gap = w * 0.21

	for _, side in ipairs({ -1, 1 }) do
		local ex = cx + side * gap
		piece(parent, "Eye", ex, cy, eyeD, eyeD, FACE_DARK, 0.5, nil, 8)
		piece(parent, "Glint", ex - eyeD * 0.24, cy - eyeD * 0.27,
			eyeD * 0.38, eyeD * 0.38, FACE_WHITE, 0.5, nil, 9)
	end

	for _, side in ipairs({ -1, 1 }) do
		piece(parent, "Cheek", cx + side * w * 0.35, cy + w * 0.15,
			w * 0.14, w * 0.11, blush, 0.5, nil, 8)
	end

	local mw = w * 0.11
	for _, spec in ipairs({ { -1, 0.030 }, { 0, 0 }, { 1, 0.030 } }) do
		local sx: number, lift: number = spec[1], spec[2]
		piece(parent, "Smile", cx + sx * mw * 0.95, cy + w * 0.27 - lift * w,
			mw, w * 0.06, FACE_DARK, 0.02, nil, 8)
	end
end

--==============================================================================
-- THE FIVE HEADS
--
-- Each returns the y where the head meets the stem, plus where a face goes and
-- how wide it is. `front` is per-form for the same reason it is in CreatureModel:
-- the widest part of a head is not always the part the face sits on, which the
-- bell proved once already with a smile inside its own skirt.
--==============================================================================
local function drawHead(box: GuiObject, spec: PlantSpec, flat: Color3?)
	local body = flat or spec.body
	local crown = flat or spec.crown
	local accent = flat or spec.accent

	if spec.form == "cube" then
		piece(box, "Head", 0.5, 0.44, 0.44, 0.44, body, 0.07, nil, 5)
		-- The brow, standing a little proud, so the front is not a flat panel.
		piece(box, "Brow", 0.5, 0.305, 0.40, 0.055, body:Lerp(BLACK, 0.14), 0.02, nil, 6)
		-- Two nubs on the upper corners: from the side, the difference between a
		-- box and a head.
		piece(box, "Nub", 0.32, 0.235, 0.10, 0.085, body, 0.03, nil, 5)
		piece(box, "Nub", 0.68, 0.235, 0.10, 0.085, body, 0.03, nil, 5)
		-- The sprout, because the cube had nothing on its head at all.
		piece(box, "Sprout", 0.40, 0.175, 0.17, 0.075, crown, 0.5, -32, 5)
		piece(box, "Sprout", 0.60, 0.175, 0.17, 0.075, crown, 0.5, 32, 5)
		if not flat then
			piece(box, "Tip", 0.33, 0.135, 0.06, 0.06, accent, 0.5, nil, 6)
			piece(box, "Tip", 0.67, 0.135, 0.06, 0.06, accent, 0.5, nil, 6)
		end
		return 0.66, 0.5, 0.475, 0.44
	elseif spec.form == "orb" then
		-- Petals behind the head so they tuck under it rather than sit on it,
		-- and sepals under THEM in the leaf colour, which is what makes the
		-- flower grow out of the head instead of resting on it.
		if not flat then
			for _, sx in ipairs({ 0.40, 0.50, 0.60 }) do
				piece(box, "Sepal", sx, 0.315, 0.13, 0.09, spec.leaf, 0.5, nil, 3)
			end
		end
		for _, p in ipairs({ { 0.32, 0.305 }, { 0.385, 0.205 }, { 0.5, 0.165 },
			{ 0.615, 0.205 }, { 0.68, 0.305 } }) do
			piece(box, "Petal", p[1], p[2], 0.155, 0.135, crown, 0.5, nil, 4)
		end
		piece(box, "Head", 0.5, 0.42, 0.48, 0.48, body, 0.5, nil, 5)
		if not flat then
			piece(box, "Centre", 0.5, 0.235, 0.095, 0.095, accent, 0.5, nil, 6)
		end
		return 0.66, 0.5, 0.44, 0.48
	elseif spec.form == "teardrop" then
		-- A rotated square behind the circle: the top corner stands clear as a
		-- point and the bottom half never shows. Same trick as the model's ball
		-- and two mirrored wedges, in two dimensions.
		piece(box, "Point", 0.5, 0.305, 0.30, 0.30, body, 0.04, 45, 4)
		piece(box, "Head", 0.5, 0.46, 0.44, 0.44, body, 0.5, nil, 5)
		-- The banded collar. Without it a teardrop is a balloon with sticks in
		-- the top and nothing explaining where it joins the plant.
		-- Narrow. At 0.34 wide in a near-white crown this read as a plank laid
		-- across the plant rather than as a band round its neck.
		piece(box, "Collar", 0.5, 0.680, 0.24, 0.055, crown, 0.3, nil, 6)
		if not flat then
			for _, s in ipairs({ { 0.36, 0.245, -32 }, { 0.5, 0.205, 0 },
				{ 0.64, 0.245, 32 } }) do
				piece(box, "Spike", s[1], s[2], 0.045, 0.12, accent, 0.3, s[3], 3)
			end
		end
		return 0.70, 0.5, 0.48, 0.44
	elseif spec.form == "mushroom" then
		piece(box, "Stalk", 0.5, 0.565, 0.34, 0.30, body, 0.14, nil, 5)
		-- A fully rounded pill with a gill bar across its underside. The bar is
		-- what turns an ellipse into a cap: it hides the bottom of the curve, so
		-- what is left reads as a dome sitting on a stalk.
		piece(box, "Cap", 0.5, 0.325, 0.68, 0.28, crown, 0.5, nil, 6)
		piece(box, "Gills", 0.5, 0.45, 0.62, 0.05, crown:Lerp(BLACK, 0.38), 0.02, nil, 7)
		if not flat then
			piece(box, "Spot", 0.355, 0.28, 0.105, 0.105, accent, 0.5, nil, 7)
			piece(box, "Spot", 0.545, 0.245, 0.12, 0.12, accent, 0.5, nil, 7)
			piece(box, "Spot", 0.665, 0.335, 0.09, 0.09, accent, 0.5, nil, 7)
		end
		return 0.70, 0.5, 0.575, 0.34
	end

	-- bell: tiers widening downward, finishing on a ridge at the hem rather than
	-- just stopping, which is what the sheet's flared lip does.
	-- Each step a shade darker than the one above it. In three dimensions the
	-- tiers separate because they catch the light differently; drawn flat in one
	-- porcelain they merged into a single white lump, and a bell whose steps are
	-- invisible is an egg.
	for index, t in ipairs({ { 0.280, 0.24, 0.10 }, { 0.375, 0.34, 0.11 },
		{ 0.480, 0.44, 0.12 }, { 0.590, 0.52, 0.12 }, { 0.663, 0.58, 0.07 } }) do
		local step = if flat then body else body:Lerp(BLACK, (index - 1) * 0.055)
		piece(box, "Tier", 0.5, t[1], t[2], t[3], step, 0.12, nil, 5)
	end
	-- The scalloped collar, not a napkin ring: overlapping rounds where the
	-- skirt meets the stem, in the same pink as the bud tips.
	for _, sx in ipairs({ 0.28, 0.39, 0.50, 0.61, 0.72 }) do
		piece(box, "Collar", sx, 0.705, 0.13, 0.105, crown, 0.5, nil, 6)
	end
	if not flat then
		piece(box, "BudStalk", 0.345, 0.205, 0.032, 0.15, accent, 0.3, -18, 3)
		piece(box, "BudStalk", 0.655, 0.205, 0.032, 0.15, accent, 0.3, 18, 3)
		piece(box, "Bud", 0.315, 0.125, 0.105, 0.105, crown, 0.5, nil, 4)
		piece(box, "Bud", 0.685, 0.125, 0.105, 0.105, crown, 0.5, nil, 4)
	end
	-- The face rides the WIDE lower skirt, which is where the sheet puts it.
	return 0.72, 0.5, 0.575, 0.50
end

--==============================================================================
-- GHOST MEANS UNDISCOVERED, AND IT STILL HAS TO BE THE RIGHT SHAPE
--
-- A locked card is not blank. The whole point of showing one is that you can
-- see there IS a fifth thing and roughly what it looks like -- so the silhouette
-- is drawn in full, in one flat grey, and only the face and the small accents
-- are withheld.
--
-- NO RARITY WORD AND NO RARITY COLOUR ON A GHOST, which is the caller's job but
-- worth writing where the ghost is built: Epic means Bellchime in Greenhollow,
-- so a tier -- spelled OR tinted -- names the species through the back door.
--==============================================================================
function UIKit.plantPortrait(parent: GuiObject, spec: PlantSpec,
	ghost: Color3?): Frame
	local box = Instance.new("Frame")
	box.Name = "Portrait"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(1, 1)
	box.BackgroundTransparency = 1
	box.Parent = parent

	-- Square, whatever the cell does. Every coordinate below is a fraction of
	-- the box, and a stretched box would stretch the plant with it.
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = box

	local stem = ghost or spec.stem
	local leaf = ghost or spec.leaf
	local soil = ghost or spec.soil

	local headBottom, faceX, faceY, faceW = drawHead(box, spec, ghost)

	-- Stem from the head down into the heap, then the heap on top of it, so the
	-- plant grows out of the dirt rather than standing in front of it.
	local stemTop = headBottom - 0.01
	piece(box, "Stem", 0.5, (stemTop + 0.875) * 0.5, 0.075, 0.875 - stemTop,
		stem, 0.3, nil, 2)

	-- Two blades at the same height and angle read as a rotor from above, so
	-- there is a smaller leaflet higher up and turned the other way.
	local leafY = stemTop + 0.085
	piece(box, "Leaf", 0.325, leafY, 0.27, 0.115, leaf, 0.5, -26, 3)
	piece(box, "Leaf", 0.675, leafY, 0.27, 0.115, leaf, 0.5, 26, 3)
	piece(box, "Leaflet", 0.645, leafY - 0.10, 0.18, 0.085, leaf, 0.5, -16, 3)

	-- The heap, not a puck: a peak at the stem thinning outward, overlapping
	-- into one mound rather than sitting as separate clods.
	piece(box, "Soil", 0.5, 0.885, 0.60, 0.145, soil, 0.35, nil, 4)
	piece(box, "Clod", 0.275, 0.895, 0.26, 0.115, soil, 0.5, nil, 4)
	piece(box, "Clod", 0.725, 0.900, 0.24, 0.105, soil, 0.5, nil, 4)

	if not ghost then
		drawFace(box, faceX, faceY, faceW, spec.blush)
	end

	return box
end

--==============================================================================
-- THE CENTRE MODAL
--
-- Index, Shop and Garden all used to slide in from an edge and dock under the
-- rail. Three problems with that, and the third is the one that settled it:
-- a docked panel covers the button that closes it, a left panel and a right
-- panel are two different mental models of the same interaction, and on a phone
-- an edge-docked panel is either unreadably narrow or the whole screen anyway.
--
-- So all three open in the middle over a dimmer, and the rail buttons stay in
-- their corners where they can still be pressed.
--
--==============================================================================
-- A CanvasGroup, SO THE FADE IS ONE PROPERTY
--
-- Fading a panel means fading a title, a close button, a lattice and forty cards
-- with it. GroupTransparency does the whole subtree in one tween; the
-- alternative is walking the descendants and remembering what every one of them
-- was transparent to begin with.
--
-- The shell is inset by the outline thickness because a CanvasGroup renders to a
-- texture its own size, and a stroke on its edge would be clipped by it.
--==============================================================================
export type ModalOptions = {
	name: string,
	title: string,
	maxWidth: number?,
	maxHeight: number?,
	titleColour: Color3?,
}

export type Modal = {
	dimmer: TextButton,
	group: CanvasGroup,
	shell: Frame,
	body: Frame,
	title: TextLabel,
	close: TextButton,
	setOpen: (boolean) -> (),
	-- Height the panel to what is actually in it. A five-card Index in a panel
	-- sized for twelve garden rows is two thirds empty, and empty is what a
	-- broken panel looks like.
	fitContent: (number) -> (),
}

local DIM = 0.45
local FADE = 0.16
local SHOP = GameConfig.Shop

function UIKit.modal(gui: ScreenGui, options: ModalOptions): Modal
	local outline = RAIL.OutlineThickness

	-- A TextButton rather than a Frame: the dimmer has to CONSUME the click that
	-- closes it, or the tap goes through to the world behind and plants a seed.
	local dimmer = Instance.new("TextButton")
	dimmer.Name = options.name .. "Dimmer"
	dimmer.Size = UDim2.fromScale(1, 1)
	dimmer.BackgroundColor3 = BLACK
	dimmer.BackgroundTransparency = 1
	dimmer.BorderSizePixel = 0
	dimmer.AutoButtonColor = false
	dimmer.Text = ""
	dimmer.Visible = false
	dimmer.ZIndex = 1
	dimmer.Parent = gui

	local group = Instance.new("CanvasGroup")
	group.Name = "Panel"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
	-- Most of a phone, capped so it never swallows a desktop screen.
	group.Size = UDim2.fromScale(0.9, 0.82)
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.ZIndex = 2
	group.Parent = dimmer

	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(248, 240)
	limit.MaxSize = Vector2.new(options.maxWidth or 460, options.maxHeight or 540)
	limit.Parent = group

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = group

	local shell = Instance.new("Frame")
	shell.Name = "Shell"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.new(1, -outline * 2, 1, -outline * 2)
	shell.BackgroundColor3 = SHOP.Panel
	shell.BorderSizePixel = 0
	-- Consumes the click, so tapping the panel does not reach the dimmer under
	-- it and close the thing you are reading.
	shell.Active = true
	shell.Parent = group
	UIKit.corner(shell, 16)
	UIKit.stroke(shell, SHOP.Outline, outline)

	-- Quiet: there are cards sitting on this and texture must never compete with
	-- them. Same lattice, same angle, much further back than the rail's.
	--
	-- Sized off the shell itself rather than off the cap: this panel is 0.9 of
	-- the screen up to a limit, so its real width is 300 on a phone and 480 on a
	-- desktop, and a lattice built for the larger one overhangs the smaller by
	-- ninety pixels in every direction.
	UIKit.lattice(shell, {
		spacing = 34,
		thickness = 2,
		colour = SHOP.PanelEdge,
		transparency = 0.55,
		inset = 6,
	})

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, -24, 0, 40)
	titleBar.Position = UDim2.fromOffset(12, 10)
	titleBar.BackgroundTransparency = 1
	titleBar.ZIndex = 3
	titleBar.Parent = shell

	local title = UIKit.outlined(titleBar, "Title", 26,
		options.titleColour or SHOP.Title, 3)
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Position = UDim2.new(0, 0, 0.5, 0)
	title.Size = UDim2.new(1, -52, 1, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = options.title
	title.ZIndex = 3

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, 0, 0.5, 0)
	close.Size = UDim2.fromOffset(38, 38)
	close.BackgroundColor3 = SHOP.Close
	close.BorderSizePixel = 0
	close.AutoButtonColor = false
	close.Font = Enum.Font.LuckiestGuy
	close.TextSize = 22
	close.TextColor3 = WHITE
	close.Text = "X"
	close.ZIndex = 4
	close.Parent = titleBar
	UIKit.corner(close, 10)
	UIKit.stroke(close, SHOP.Outline, outline)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(12, 58)
	body.Size = UDim2.new(1, -24, 1, -70)
	body.BackgroundTransparency = 1
	body.ZIndex = 3
	body.Parent = shell

	local open = false

	local function setOpen(want: boolean)
		if open == want then
			return
		end
		open = want
		if want then
			dimmer.Visible = true
			dimmer.BackgroundTransparency = 1
			group.GroupTransparency = 1
			scale.Scale = 0.92
			TweenService:Create(dimmer, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out), { BackgroundTransparency = DIM }):Play()
			TweenService:Create(group, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
			TweenService:Create(scale, TweenInfo.new(FADE, Enum.EasingStyle.Back,
				Enum.EasingDirection.Out), { Scale = 1 }):Play()
		else
			TweenService:Create(dimmer, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(scale, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.In), { Scale = 0.92 }):Play()
			local fade = TweenService:Create(group, TweenInfo.new(FADE,
				Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ GroupTransparency = 1 })
			fade:Play()
			fade.Completed:Connect(function()
				-- Only if nothing re-opened it during the fade.
				if not open then
					dimmer.Visible = false
				end
			end)
		end
	end

	local function fitContent(contentHeight: number)
		local screen = gui.AbsoluteSize.Y
		if screen <= 0 then
			return
		end
		-- Never taller than the screen allows, never taller than the cap, never
		-- shorter than a title bar and a row.
		local ceiling = math.min(limit.MaxSize.Y, math.floor(screen * 0.86))
		local want = math.clamp(contentHeight + 82, 240, ceiling)
		group.Size = UDim2.new(0.9, 0, 0, want)
	end

	return {
		dimmer = dimmer,
		group = group,
		shell = shell,
		body = body,
		title = title,
		close = close,
		setOpen = setOpen,
		fitContent = fitContent,
	}
end

--==============================================================================
-- THE BADGE
--
-- Red, and that is deliberate: it is one of the few things allowed outside ink /
-- paper / accent, because the whole job of it is to be what your eye goes to
-- before you have decided to look at anything.
--
-- Hangs half off the corner, which is why no slab clips.
--==============================================================================
function UIKit.badge(parent: GuiObject, colour: Color3): (Frame, TextLabel)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, 0, 0, 0)
	badge.Size = UDim2.fromOffset(26, 26)
	badge.BackgroundColor3 = colour
	badge.BorderSizePixel = 0
	badge.Visible = false
	badge.ZIndex = 6
	badge.Parent = parent
	UIKit.corner(badge, 13)
	UIKit.stroke(badge, BLACK, 2.5)

	local count = UIKit.outlined(badge, "Count", 15, WHITE, 2)
	count.Size = UDim2.fromScale(1, 1)
	count.Position = UDim2.fromOffset(0, 1)
	count.TextXAlignment = Enum.TextXAlignment.Center
	count.ZIndex = 7

	return badge, count
end

return UIKit
