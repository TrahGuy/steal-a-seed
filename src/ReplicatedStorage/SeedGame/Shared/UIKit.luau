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

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--==============================================================================
-- ONE FRAME LOOP FOR EVERY CARD, NOT ONE PER CARD
--
-- A Garden with twelve rows and an Index with five is seventeen cards, and each
-- one used to open its own RenderStepped. Seventeen connections, each running a
-- chain of string.find and then a whole-model PivotTo, sixty times a second.
--
-- Worse, they never stopped. The guard was `if not holder.Visible` and
-- VISIBLE IS NOT INHERITED IN ROBLOX: closing a panel sets the panel's own
-- Visible to false and every descendant stays true, so the guard was true
-- forever and the cards animated behind a closed menu for the whole session.
--
-- One connection now, over a registry, and it disconnects itself when the last
-- card goes. Each card is asked whether it is actually on screen first -- see
-- onScreen, which walks what Visible does not.
--==============================================================================
local cardUpdaters: { [Instance]: (number) -> () } = {}
local cardCount = 0
local cardLoop: RBXScriptConnection? = nil

local function pumpCards(dt: number)
	for _, update in pairs(cardUpdaters) do
		update(dt)
	end
end

local function registerCard(key: Instance, update: (number) -> ())
	if cardUpdaters[key] == nil then
		cardCount += 1
	end
	cardUpdaters[key] = update
	if not cardLoop then
		cardLoop = RunService.RenderStepped:Connect(pumpCards)
	end
end

local function unregisterCard(key: Instance)
	if cardUpdaters[key] == nil then
		return
	end
	cardUpdaters[key] = nil
	cardCount -= 1
	if cardCount <= 0 and cardLoop then
		cardLoop:Disconnect()
		cardLoop = nil
		cardCount = 0
	end
end

--==============================================================================
-- IS THIS THING ACTUALLY ON SCREEN?
--
-- GuiObject.Visible describes ONE object. A frame inside a hidden parent is
-- still Visible = true and simply is not drawn, which is why the old guard
-- never fired. This walks to the ScreenGui and asks the whole chain.
--
-- Four or five property reads, against a PivotTo over a forty-part model. It is
-- not the expensive half.
--==============================================================================
local function onScreen(obj: GuiObject): boolean
	local node: Instance? = obj
	while node do
		if node:IsA("ScreenGui") then
			return (node :: ScreenGui).Enabled
		end
		if node:IsA("GuiObject") and not (node :: GuiObject).Visible then
			return false
		end
		node = node.Parent
	end
	return false
end

--==============================================================================
-- THE IDLE, PICKED ONCE
--
-- The form used to be matched with up to a dozen string.find calls PER CARD PER
-- FRAME. It only changes when the card changes what it is showing, so it is
-- resolved there instead and stored as a function.
--==============================================================================
local function idleFor(form: string): (number) -> CFrame
	local f = string.lower(form)
	if f == "cube" or string.find(f, "nubkin") then
		return function(t)
			local bounce = math.abs(math.sin(t * 3.4))
			return CFrame.new(0, bounce * 0.16, 0)
				* CFrame.Angles(0, math.sin(t * 2.6) * math.rad(6), math.sin(t * 3.4) * math.rad(4))
		end
	elseif f == "orb" or string.find(f, "petalpip") then
		return function(t)
			return CFrame.new(0, math.sin(t * 2.2) * 0.08, 0)
				* CFrame.Angles(math.sin(t * 1.8) * math.rad(7), math.cos(t * 1.1) * math.rad(8),
					math.sin(t * 2.2) * math.rad(5))
		end
	elseif f == "teardrop" or string.find(f, "spiretip") or string.find(f, "sprout") then
		return function(t)
			return CFrame.Angles(math.sin(t * 2.4) * math.rad(8), math.sin(t * 1.6) * math.rad(14),
				math.cos(t * 2.4) * math.rad(6))
		end
	elseif f == "mushroom" or string.find(f, "toadcap") or string.find(f, "shroom") then
		return function(t)
			return CFrame.new(0, math.sin(t * 4.8) * 0.06, 0)
				* CFrame.Angles(math.sin(t * 2.5) * math.rad(9), 0, math.cos(t * 2.5) * math.rad(8))
		end
	elseif f == "bell" or string.find(f, "bellchime") then
		return function(t)
			return CFrame.Angles(0, 0, math.sin(t * 2.2) * math.rad(14))
				* CFrame.Angles(math.cos(t * 1.1) * math.rad(5), 0, 0)
		end
	elseif f == "ready" then
		return function(t)
			local hop = math.abs(math.sin(t * 6.0)) * 0.20
			return CFrame.new(0, hop, 0)
				* CFrame.Angles(math.sin(t * 16.0) * math.rad(5), 0, math.cos(t * 14.0) * math.rad(5))
		end
	elseif f == "pod" then
		return function(t)
			return CFrame.new(0, math.sin(t * 2.0) * 0.05, 0)
				* CFrame.Angles(math.sin(t * 1.8) * math.rad(5), 0, math.cos(t * 2.4) * math.rad(4))
		end
	end
	return function(t)
		return CFrame.new(0, math.sin(t * 2.0) * 0.05, 0)
			* CFrame.Angles(0, math.sin(t * 1.5) * math.rad(4), 0)
	end
end

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local SoundKit = require(script.Parent:WaitForChild("SoundKit"))

local UIKit = {}

local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel
local CARD = GameConfig.Card
local BLACK = Color3.fromRGB(0, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)

--==============================================================================
-- THE SMALL ONES
--==============================================================================
--==============================================================================
-- A BUTTON THAT MAKES A NOISE
--
-- `Activated` and not MouseButton1Click: it is the one that also fires for a
-- touch and for a gamepad, and every button in this game has to work on a phone.
--
-- Here rather than at each call site for the same reason the slab is here -- the
-- second copy of a thing is where the drift starts, and a click that is 0.3 on
-- the rail and 0.35 in the shop is a drift nobody will ever be able to hear well
-- enough to report.
--==============================================================================
function UIKit.clicks(button: GuiButton): GuiButton
	button.Activated:Connect(function()
		SoundKit.play("CardClick")
	end)
	return button
end

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

--==============================================================================
-- A UIGradient MULTIPLIES. IT DOES NOT REPLACE.
--
-- The rendered colour is BackgroundColor3 TIMES the gradient, so a frame set to
-- its own fill and then gradiented from that fill squares it. On a bright face
-- that only looks a bit deeper and passes unnoticed; on the panel's shaded soil
-- it turned rgb(58,38,29) into rgb(13,6,3), which is why a fill picked to stop
-- the panel reading as black rendered blacker than the one it replaced.
--
-- So the surface goes WHITE and the gradient carries the colour. Callers pass
-- the two real colours and get exactly those two colours. ShopUI's cards had
-- this right already -- `fill.BackgroundColor3 = WHITE` then gradient -- and
-- this is that, moved somewhere all three panels share.
--==============================================================================
function UIKit.gradient(parent: GuiObject, top: Color3, bottom: Color3): UIGradient
	parent.BackgroundColor3 = WHITE
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
	-- These ScreenGuis run ZIndexBehavior.Global, where a lower number is behind
	-- a higher one no matter who owns it. Zero is right on a panel, whose only
	-- job is to be behind everything; on a plant card the sky sits above other
	-- layers and its lattice has to come with it.
	zIndex: number?,
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

	local layer = opts.zIndex or 0

	local holder = Instance.new("Frame")
	holder.Name = "Lattice"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	-- Behind the content and never in the way of a click: a Frame is not Active,
	-- so it does not swallow input.
	holder.ZIndex = layer
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
					line.ZIndex = layer
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
		-- Sets the background white itself; see the note on UIKit.gradient. The
		-- three rail faces were being squared before that was fixed, which is
		-- why they all read a shade deeper than the palette says.
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

	-- Both slabs in the game are buttons -- the rail button and the card's
	-- action -- so the click belongs to the builder rather than to its two
	-- callers. If a slab is ever used as a surface rather than a control, this
	-- is the line that has to move out.
	UIKit.clicks(slab)

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
	f.Active = false
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
--==============================================================================
-- ONE BOX AND ONE HEAP, SHARED BY EVERY PORTRAIT
--
-- A plant, a pod and an empty hole are three things that live in the same dirt,
-- and drawing that dirt three ways is how a bed of twelve ends up with three
-- different soil colours in it.
--==============================================================================
local function portraitBox(parent: GuiObject): Frame
	local box = Instance.new("Frame")
	box.Name = "Portrait"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(1, 1)
	box.BackgroundTransparency = 1
	box.Parent = parent

	-- Square, whatever the cell does. Every coordinate in here is a fraction of
	-- the box, and a stretched box would stretch the plant with it.
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = box
	return box
end

-- A heap with a peak, thinning outward, overlapping into one mound rather than
-- sitting as separate clods.
local function drawSoil(box: GuiObject, soil: Color3)
	piece(box, "Soil", 0.5, 0.885, 0.60, 0.145, soil, 0.35, nil, 4)
	piece(box, "Clod", 0.275, 0.895, 0.26, 0.115, soil, 0.5, nil, 4)
	piece(box, "Clod", 0.725, 0.900, 0.24, 0.105, soil, 0.5, nil, 4)
end

function UIKit.plantPortrait(parent: GuiObject, spec: PlantSpec,
	ghost: Color3?): Frame
	local box = portraitBox(parent)

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

	drawSoil(box, soil)

	if not ghost then
		drawFace(box, faceX, faceY, faceW, spec.blush)
	end

	return box
end

--==============================================================================
-- A POD, DRAWN FLAT
--
-- What sits in a hole before the shell breaks. Same vocabulary as
-- CreatureModel.BuildPod -- an egg of two overlapping rounds with the upper one
-- smaller, a seam a hair proud of it, and the curled tendril -- because a Ball
-- is sized by its smallest axis and a single elongated one is not available in
-- three dimensions either.
--
--==============================================================================
-- COLOURED BY WEIGHT, AND IT IS NOT THE CREATURE
--
-- The shell takes ColorForKg and NOTHING here says which species is inside. Two
-- Commons arrive in identical shells and which one you got is not knowable until
-- it opens -- so drawing the form on a Garden card would spend the hatch exactly
-- the way printing the name would. A pod card shows a pod.
--==============================================================================
function UIKit.podPortrait(parent: GuiObject, shell: Color3, soil: Color3): Frame
	local box = portraitBox(parent)

	drawSoil(box, soil)

	-- The egg: the lower round is the body, the upper and smaller one closes it.
	piece(box, "Shell", 0.5, 0.585, 0.52, 0.52, shell, 0.5, nil, 5)
	piece(box, "Crown", 0.5, 0.395, 0.44, 0.44, shell, 0.5, nil, 5)
	-- The seam. The sheet's zigzag is not worth twenty parts to reproduce and at
	-- any size that matters what reads is that there IS one.
	piece(box, "Seam", 0.5, 0.505, 0.545, 0.055,
		shell:Lerp(BLACK, 0.18), 0.02, nil, 6)
	-- The tendril, four blocks around a quarter turn.
	for index, t in ipairs({ { 0.560, 0.175, 12 }, { 0.585, 0.115, 30 },
		{ 0.635, 0.070, 52 }, { 0.700, 0.048, 74 } }) do
		piece(box, "Tendril" .. index, t[1], t[2], 0.055, 0.085,
			Color3.fromRGB(104, 158, 62), 0.2, t[3], 6)
	end

	return box
end

--==============================================================================
-- AN EMPTY HOLE
--
-- Not a blank card. An empty slot is a real hole in real dirt that you can walk
-- over and fill, so it is drawn as one -- the same heap every other portrait
-- stands in, with the ground opened up in the middle of it.
--==============================================================================
function UIKit.emptyPortrait(parent: GuiObject, soil: Color3): Frame
	local box = portraitBox(parent)
	drawSoil(box, soil)
	-- The hollow, sunk into the heap: darker than the dirt around it, because a
	-- hole is the absence of the thing rather than a lighter patch of it.
	piece(box, "Hollow", 0.5, 0.845, 0.30, 0.135,
		soil:Lerp(BLACK, 0.45), 0.5, nil, 5)
	return box
end

--==============================================================================
-- A CLIP THAT SURVIVES ROTATION
--
-- ClipsDescendants does not clip a rotated child. That is written up at length
-- on the lattice, where it was first measured, and the chord maths there stops
-- a lattice escaping the surface it decorates.
--
-- It does not stop the surface itself being scrolled out of view. A card
-- half-way off the bottom of a ScrollingFrame has its sky and its bed cut at
-- the boundary, correctly, and its lattice lines carry on rendering below it --
-- measured at 342 pixels past the edge, which is how a green diamond ended up
-- sitting on the Garden's footer.
--
-- A CanvasGroup renders its descendants into a buffer of its own size, so what
-- falls outside is simply not drawn -- rotation included. Proof it works was
-- already on screen: the escaped lattice stopped at the panel's edge, and the
-- panel is a CanvasGroup.
--
-- ONE PER LIST, not one per card. A render target per card would be thirty of
-- them on a tier-4 plot, and Rule 8 is mobile first.
--==============================================================================
function UIKit.rotationSafeClip(parent: Instance, name: string,
	size: UDim2): CanvasGroup
	local clip = Instance.new("CanvasGroup")
	clip.Name = name
	clip.Size = size
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ZIndex = 3
	clip.Parent = parent
	return clip
end

--==============================================================================
-- LIFTING A WHOLE CARD, UNDER ZIndexBehavior.Global
--
-- Every ScreenGui in this game runs Global, which was measured rather than
-- assumed: a GuiObject is ordered against every other one in the ScreenGui by
-- its own ZIndex, and being somebody's child buys it nothing. Raising a card's
-- own ZIndex therefore raises the CARD and leaves its sky, its plant and its
-- labels behind, sitting under the neighbour it was supposed to rise above.
--
-- So the lift walks the subtree and moves every layer by the same offset, and
-- puts them all back on the way down. Walked at hover time rather than cached,
-- because the portrait inside a card is rebuilt whenever what it depicts
-- changes and a cached list would be holding destroyed frames.
--
-- Guarded with `up`, because lifting twice would record the already-lifted
-- values as the resting ones and the card would never come back down.
--==============================================================================
local function liftLayers(root: GuiObject, offset: number)
	local resting: { [GuiObject]: number } = {}
	local up = false

	return function(want: boolean)
		if up == want then
			return
		end
		up = want
		if want then
			table.clear(resting)
			resting[root] = root.ZIndex
			root.ZIndex += offset
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("GuiObject") then
					resting[d] = d.ZIndex
					d.ZIndex += offset
				end
			end
		else
			for object, z in pairs(resting) do
				-- Anything rebuilt while the card was up is not in here and does
				-- not need to be: it was built at its resting number.
				if object.Parent then
					object.ZIndex = z
				end
			end
			table.clear(resting)
		end
	end
end

--==============================================================================
-- THE POP
--
-- Scale, stroke and stacking order, on a tween. No Heartbeat: a hover is two
-- events and two tweens, not a per-frame job.
--
-- TOUCH IS NOT HOVER. A phone has no pointer to enter with, so the same pop runs
-- on press and releases on lift -- without it every card on mobile is a dead
-- rectangle that never acknowledges being touched.
--
-- Returned as a function as well as wired to the events, because a hover cannot
-- be fired from a script and a state that cannot be driven cannot be tested.
--==============================================================================
export type PopOptions = {
	scale: number?,
	seconds: number?,
	lift: number?,
	stroke: UIStroke?,
	strokeThickness: number?,
}

function UIKit.popOnHover(target: GuiObject, scale: UIScale,
	options: PopOptions?): ((boolean) -> (), (boolean) -> ())
	local opts: PopOptions = options or {}
	local up = opts.scale or CARD.HoverScale
	local seconds = opts.seconds or CARD.HoverSeconds
	local raise = liftLayers(target, opts.lift or CARD.HoverLift)

	local stroke = opts.stroke
	local restingThickness = if stroke then stroke.Thickness else 0
	local thickThickness = opts.strokeThickness or (restingThickness + 1.25)

	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	--==========================================================================
	-- A CARD THAT IS DOING SOMETHING ELSE DOES NOT POP
	--
	-- Selection shrinks a card and hover grows it, and a card that can be in
	-- both states at once is a card that gets stuck in one of them. Turning the
	-- pop off also puts it DOWN, so a card selected while the pointer is on it
	-- does not stay at 1.07 underneath the new state.
	--==========================================================================
	local enabled = true
	local hovered = false

	local function setHovered(on: boolean)
		if on and not enabled then
			return
		end
		--======================================================================
		-- THE SOUND IS ON THE EDGE, NOT ON THE EVENT
		--
		-- MouseEnter fires once per entry, but touch fires setHovered(true) on
		-- every InputBegan the card sees, and setEnabled(false) fires it the
		-- other way -- so a card being selected under a stationary pointer would
		-- pop without the pointer having moved. Only a real change makes a
		-- noise.
		--======================================================================
		if hovered ~= on then
			hovered = on
			if on then
				SoundKit.play("CardHover")
			end
		end
		raise(on)
		TweenService:Create(scale, info, { Scale = if on then up else 1 }):Play()
		if stroke then
			TweenService:Create(stroke, info,
				{ Thickness = if on then thickThickness else restingThickness }):Play()
		end
	end

	target.MouseEnter:Connect(function()
		setHovered(true)
	end)
	target.MouseLeave:Connect(function()
		setHovered(false)
	end)
	target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			setHovered(true)
		end
	end)
	target.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			setHovered(false)
		end
	end)

	local function setEnabled(on: boolean)
		enabled = on
		if not on then
			setHovered(false)
		end
	end

	return setHovered, setEnabled
end

--==============================================================================
-- THE PLANT CARD
--
-- One builder for the Index almanac and the Garden bed. They ask different
-- questions -- what shapes exist, and what is in your dirt right now -- but they
-- are the same object on screen, and two copies of it is how one of them keeps a
-- backdrop the other has already changed.
--
-- Back to front: a shadow, the card, a clipped BACKDROP, a ViewportFrame with a
-- still 3D plant in it, then two labels.
--
--==============================================================================
-- THE PLANT IS A REAL MODEL NOW, AND IT DOES NOT MOVE
--
-- It was a flat drawing built from rotated frames -- which is why the card used
-- to need a horizon, a soil bed and a solved art box to stand a 2D heap on. All
-- of that is gone. The card shows a copy of the SAME CreatureModel the world
-- builds, so a Bellchime in the Index is the Bellchime in the ground rather than
-- an illustration of one that can drift away from it.
--
-- STILL. No sway, no lean, no walk, no spin, no camera orbit, no Heartbeat and
-- nothing on RenderStepped. The camera is set once when the model is built and
-- never touched again. A menu that animates thirty plants is a menu that costs
-- frames for nothing.
--
-- A COPY, and never the plant in the plot. Nothing here is tagged, prompted or
-- welded, and no ViewportFrame is ever pointed at a live model -- reparenting
-- one would take it out of the world.
--==============================================================================
export type PlantCardOptions = {
	name: string?,
	layoutOrder: number?,
	nameSize: number?,
	subSize: number?,
}

export type PlantCard = {
	holder: Frame,
	button: ImageButton,
	stage: Frame,
	hero: ViewportFrame,
	name: TextLabel,
	sub: TextLabel,
	border: UIStroke,
	action: ImageButton,
	setBackdrop: (string?) -> (),
	setModel: (string, (((Instance) -> Model?)?), string?) -> (),
	setHovered: (boolean) -> (),
	setSelected: (boolean, string?) -> (),
	setWeightTag: (string?, Color3?) -> (),
	setStatusTag: (string?, Color3?, Color3?) -> (),
	setProgress: (number?, Color3?) -> (),
	setReadyPulse: (boolean) -> (),
	setStageTheme: (string) -> (),
	setEmpty: (boolean) -> (),
}

local Z_SHADOW = 3
local Z_CARD = 4
local Z_STAGE = 5
local Z_HERO = 8
local Z_LABEL = 22

--==============================================================================
-- FRAMING, ONCE
--
-- The model is built at the origin, so its bounding box is where the camera has
-- to look. Distance comes off the box's diagonal and the camera's own field of
-- view, which is what makes a Nubkin and a Bellchime both fill their card
-- without a per-species number to keep in step.
--==============================================================================
local function addPedestal(model: Model, pivot: CFrame, size: Vector3)
	if model:FindFirstChild("Pedestal") then
		return
	end
	local groundY = pivot.Position.Y - size.Y * 0.5
	local rad = math.max(size.X, size.Z) * 0.58 + 0.35

	local ped = Instance.new("Model")
	ped.Name = "Pedestal"

	local disc = Instance.new("Part")
	disc.Name = "Soil"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.20, rad * 2, rad * 2)
	disc.CFrame = CFrame.new(pivot.Position.X, groundY - 0.10, pivot.Position.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	disc.Color = Color3.fromRGB(64, 46, 32)
	disc.Material = Enum.Material.Grass
	disc.Anchored = true
	disc.CanCollide = false
	disc.Parent = ped

	local rim = Instance.new("Part")
	rim.Name = "Grass"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.12, rad * 2.25, rad * 2.25)
	rim.CFrame = CFrame.new(pivot.Position.X, groundY - 0.18, pivot.Position.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	rim.Color = Color3.fromRGB(98, 168, 68)
	rim.Material = Enum.Material.Grass
	rim.Anchored = true
	rim.CanCollide = false
	rim.Parent = ped

	ped.Parent = model
end

local function frameModel(hero: ViewportFrame, model: Model)
	local pivot, size = model:GetBoundingBox()
	addPedestal(model, pivot, size)

	pivot, size = model:GetBoundingBox()
	local extent = math.max(size.Magnitude, 0.1)

	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	local distance = (extent * CARD.CameraFill * 0.54)
		/ math.tan(math.rad(camera.FieldOfView * 0.5))
	local focus = pivot.Position + Vector3.new(0, size.Y * (CARD.CameraRise * 0.88), 0)
	camera.CFrame = CFrame.lookAt(focus + CARD.CameraOffset.Unit * distance, focus)
	camera.Parent = hero
	hero.CurrentCamera = camera
end

function UIKit.plantCard(parent: Instance, options: PlantCardOptions): PlantCard
	local radius = CARD.Radius

	local holder = Instance.new("Frame")
	holder.Name = options.name or "PlantCard"
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = options.layoutOrder or 0
	holder.ZIndex = Z_SHADOW
	holder.Parent = parent

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = holder

	local card = Instance.new("Frame")
	card.Name = "CardWrap"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.fromScale(0.5, 0)
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundTransparency = 1
	card.ZIndex = Z_SHADOW
	card.Parent = holder

	local selectScale = Instance.new("UIScale")
	selectScale.Scale = 1
	selectScale.Parent = card

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, 4)
	shadow.BackgroundColor3 = BLACK
	shadow.BackgroundTransparency = 0.55
	shadow.BorderSizePixel = 0
	shadow.ZIndex = Z_SHADOW
	shadow.Parent = card
	UIKit.corner(shadow, radius)

	local button = Instance.new("ImageButton")
	button.Name = "Card"
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Active = true
	button.Selectable = true
	button.ZIndex = Z_CARD
	button.Parent = card
	local border = UIKit.stroke(button, BLACK, 2.5)

	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.Size = UDim2.fromScale(1, 1)
	stage.BorderSizePixel = 0
	stage.ClipsDescendants = true
	stage.Active = false
	stage.ZIndex = Z_STAGE
	stage.Parent = button
	UIKit.corner(stage, radius)
	local dusk = UIKit.gradient(stage, CARD.DuskTop, CARD.DuskBottom)

	-- Top gloss line for a sleek toy plastic sheen
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.new(1, 0, 0, 3)
	gloss.Position = UDim2.fromOffset(0, 0)
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0.72
	gloss.BorderSizePixel = 0
	gloss.Active = false
	gloss.ZIndex = Z_STAGE + 1
	gloss.Parent = stage

	--==========================================================================
	-- PROCEDURAL DECORATIVE BACKGROUND LAYERS
	--==========================================================================
	local bgDeco = Instance.new("Frame")
	bgDeco.Name = "BgDeco"
	bgDeco.Size = UDim2.fromScale(1, 1)
	bgDeco.BackgroundTransparency = 1
	bgDeco.BorderSizePixel = 0
	bgDeco.Active = false
	bgDeco.ZIndex = Z_STAGE
	bgDeco.Parent = stage

	-- 1. Soft Spotlight Halo
	local halo = Instance.new("Frame")
	halo.Name = "Halo"
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.40)
	halo.Size = UDim2.fromScale(0.85, 0.65)
	halo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	halo.BackgroundTransparency = 0.88
	halo.BorderSizePixel = 0
	halo.Active = false
	halo.ZIndex = Z_STAGE
	halo.Parent = bgDeco
	UIKit.corner(halo, 36)

	-- 2. Distant Hill Silhouette
	local hillFar = Instance.new("Frame")
	hillFar.Name = "HillFar"
	hillFar.AnchorPoint = Vector2.new(0.5, 1)
	hillFar.Position = UDim2.fromScale(0.5, 0.74)
	hillFar.Size = UDim2.fromScale(1.3, 0.35)
	hillFar.BackgroundColor3 = Color3.fromRGB(28, 48, 40)
	hillFar.BackgroundTransparency = 0.5
	hillFar.BorderSizePixel = 0
	hillFar.Active = false
	hillFar.ZIndex = Z_STAGE
	hillFar.Parent = bgDeco
	UIKit.corner(hillFar, 42)

	-- 3. Near Hill / Lawn Silhouette
	local hillNear = Instance.new("Frame")
	hillNear.Name = "HillNear"
	hillNear.AnchorPoint = Vector2.new(0.5, 1)
	hillNear.Position = UDim2.fromScale(0.5, 0.80)
	hillNear.Size = UDim2.fromScale(1.2, 0.28)
	hillNear.BackgroundColor3 = Color3.fromRGB(38, 68, 52)
	hillNear.BackgroundTransparency = 0.35
	hillNear.BorderSizePixel = 0
	hillNear.Active = false
	hillNear.ZIndex = Z_STAGE
	hillNear.Parent = bgDeco
	UIKit.corner(hillNear, 36)

	-- 4. Floating Glowing Spores / Sparkles
	local spores = {}
	local sporeCoords = {
		{ x = 0.18, y = 0.20, s = 4, c = Color3.fromRGB(180, 245, 140), t = 0.4 },
		{ x = 0.82, y = 0.25, s = 5, c = Color3.fromRGB(255, 235, 150), t = 0.35 },
		{ x = 0.26, y = 0.44, s = 3, c = Color3.fromRGB(160, 230, 255), t = 0.45 },
		{ x = 0.76, y = 0.48, s = 4, c = Color3.fromRGB(220, 255, 160), t = 0.4 },
	}
	for i, sp in ipairs(sporeCoords) do
		local dot = Instance.new("Frame")
		dot.Name = "Spore" .. i
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(sp.x, sp.y)
		dot.Size = UDim2.fromOffset(sp.s, sp.s)
		dot.BackgroundColor3 = sp.c
		dot.BackgroundTransparency = sp.t
		dot.BorderSizePixel = 0
		dot.Active = false
		dot.ZIndex = Z_STAGE
		dot.Parent = bgDeco
		UIKit.corner(dot, 3)
		table.insert(spores, dot)
	end

	-- The species backdrop picture, when there is one to show.
	local backdrop = Instance.new("ImageLabel")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Active = false
	backdrop.ScaleType = Enum.ScaleType.Crop
	backdrop.ImageColor3 = CARD.ArtTint
	backdrop.Visible = false
	backdrop.ZIndex = Z_STAGE
	backdrop.Parent = stage

	-- Bottom text vignette for crystal-clear readability
	local textShade = Instance.new("Frame")
	textShade.Name = "TextShade"
	textShade.AnchorPoint = Vector2.new(0, 1)
	textShade.Position = UDim2.fromScale(0, 1)
	textShade.Size = UDim2.new(1, 0, 0.44, 0)
	textShade.BorderSizePixel = 0
	textShade.Active = false
	textShade.ZIndex = Z_STAGE + 1
	textShade.Parent = stage
	local shadeGrad = Instance.new("UIGradient")
	shadeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 10, 16)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 16)),
	})
	shadeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.5),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	shadeGrad.Rotation = 90
	shadeGrad.Parent = textShade

	--==========================================================================
	-- TOP TAG BADGES: Weight & Status
	--==========================================================================
	local tagLeft = Instance.new("Frame")
	tagLeft.Name = "TagLeft"
	tagLeft.Position = UDim2.fromOffset(6, 6)
	tagLeft.Size = UDim2.fromOffset(46, 16)
	tagLeft.AutomaticSize = Enum.AutomaticSize.X
	tagLeft.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
	tagLeft.BackgroundTransparency = 0.32
	tagLeft.BorderSizePixel = 0
	tagLeft.Active = false
	tagLeft.Visible = false
	tagLeft.ZIndex = Z_LABEL
	tagLeft.Parent = button
	UIKit.corner(tagLeft, 5)
	local tagLeftStroke = UIKit.stroke(tagLeft, Color3.fromRGB(255, 255, 255), 1, 0.82)

	local tagLeftPad = Instance.new("UIPadding")
	tagLeftPad.PaddingLeft = UDim.new(0, 5)
	tagLeftPad.PaddingRight = UDim.new(0, 6)
	tagLeftPad.Parent = tagLeft

	local tagLeftList = Instance.new("UIListLayout")
	tagLeftList.FillDirection = Enum.FillDirection.Horizontal
	tagLeftList.VerticalAlignment = Enum.VerticalAlignment.Center
	tagLeftList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tagLeftList.Padding = UDim.new(0, 4)
	tagLeftList.Parent = tagLeft

	local tagLeftDot = Instance.new("Frame")
	tagLeftDot.Name = "Dot"
	tagLeftDot.Size = UDim2.fromOffset(5, 5)
	tagLeftDot.BackgroundColor3 = WHITE
	tagLeftDot.BorderSizePixel = 0
	tagLeftDot.Active = false
	tagLeftDot.ZIndex = Z_LABEL
	tagLeftDot.Parent = tagLeft
	UIKit.corner(tagLeftDot, 3)

	local tagLeftText = Instance.new("TextLabel")
	tagLeftText.Name = "Text"
	tagLeftText.AutomaticSize = Enum.AutomaticSize.X
	tagLeftText.Size = UDim2.fromScale(0, 1)
	tagLeftText.BackgroundTransparency = 1
	tagLeftText.Font = Enum.Font.FredokaOne
	tagLeftText.TextSize = 10
	tagLeftText.TextColor3 = WHITE
	tagLeftText.Active = false
	tagLeftText.TextYAlignment = Enum.TextYAlignment.Center
	tagLeftText.ZIndex = Z_LABEL
	tagLeftText.Parent = tagLeft

	local tagRight = Instance.new("Frame")
	tagRight.Name = "TagRight"
	tagRight.AnchorPoint = Vector2.new(1, 0)
	tagRight.Position = UDim2.new(1, -6, 0, 6)
	tagRight.Size = UDim2.fromOffset(50, 16)
	tagRight.AutomaticSize = Enum.AutomaticSize.X
	tagRight.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
	tagRight.BackgroundTransparency = 0.30
	tagRight.BorderSizePixel = 0
	tagRight.Active = false
	tagRight.Visible = false
	tagRight.ZIndex = Z_LABEL
	tagRight.Parent = button
	UIKit.corner(tagRight, 5)
	local tagRightStroke = UIKit.stroke(tagRight, Color3.fromRGB(255, 255, 255), 1, 0.82)

	local tagRightPad = Instance.new("UIPadding")
	tagRightPad.PaddingLeft = UDim.new(0, 5)
	tagRightPad.PaddingRight = UDim.new(0, 6)
	tagRightPad.Parent = tagRight

	local tagRightText = Instance.new("TextLabel")
	tagRightText.Name = "Text"
	tagRightText.AutomaticSize = Enum.AutomaticSize.X
	tagRightText.Size = UDim2.fromScale(0, 1)
	tagRightText.BackgroundTransparency = 1
	tagRightText.Font = Enum.Font.FredokaOne
	tagRightText.TextSize = 10
	tagRightText.TextColor3 = Color3.fromRGB(142, 220, 68)
	tagRightText.Active = false
	tagRightText.TextYAlignment = Enum.TextYAlignment.Center
	tagRightText.ZIndex = Z_LABEL
	tagRightText.Parent = tagRight

	--==========================================================================
	-- GROWTH PROGRESS BAR (For Hatching Pods)
	--==========================================================================
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.AnchorPoint = Vector2.new(0.5, 1)
	progressBar.Position = UDim2.new(0.5, 0, 1, -40)
	progressBar.Size = UDim2.new(1, -16, 0, 4)
	progressBar.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
	progressBar.BackgroundTransparency = 0.45
	progressBar.BorderSizePixel = 0
	progressBar.Active = false
	progressBar.Visible = false
	progressBar.ZIndex = Z_LABEL
	progressBar.Parent = button
	UIKit.corner(progressBar, 2)

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(142, 220, 68)
	progressFill.BorderSizePixel = 0
	progressFill.Active = false
	progressFill.ZIndex = Z_LABEL
	progressFill.Parent = progressBar
	UIKit.corner(progressFill, 2)

	--==========================================================================
	-- THE VIEWPORT
	--==========================================================================
	local hero = Instance.new("ViewportFrame")
	hero.Name = "Hero"
	hero.AnchorPoint = Vector2.new(0.5, 0)
	hero.Position = UDim2.fromScale(0.5, 0.02)
	hero.Size = UDim2.fromScale(0.98, 0.74)
	hero.BackgroundTransparency = 1
	hero.BorderSizePixel = 0
	hero.Active = false
	hero.Ambient = CARD.Ambient
	hero.LightColor = CARD.LightColour
	hero.LightDirection = CARD.LightDirection
	hero.ZIndex = Z_HERO
	hero.Parent = button

	local name = UIKit.outlined(button, "Name", options.nameSize or 15, WHITE, 2)
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -20)
	name.Size = UDim2.new(1, -8, 0, 19)
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.Active = false
	name.ZIndex = Z_LABEL

	local sub = UIKit.outlined(button, "Sub", options.subSize or 12, WHITE, 2)
	sub.AnchorPoint = Vector2.new(0.5, 1)
	sub.Position = UDim2.new(0.5, 0, 1, -4)
	sub.Size = UDim2.new(1, -8, 0, 16)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.Active = false
	sub.ZIndex = Z_LABEL

	local shownArt: string? = nil
	local function setBackdrop(speciesId: string?)
		if shownArt == speciesId then
			return
		end
		shownArt = speciesId
		local image = if speciesId then CARD.Art[speciesId] else nil
		backdrop.Visible = image ~= nil
		backdrop.Image = image or ""
	end

	--==========================================================================
	-- 3D MODEL & CAMERA MANAGEMENT
	--==========================================================================
	local currentModel: Model? = nil
	local modelBasePivot: CFrame = CFrame.identity
	local activeCamera: Camera? = nil
	local cameraDistance: number = 10
	local cameraFocus: Vector3 = Vector3.zero
	local cameraBasePitch: number = math.rad(-14)
	local currentYaw: number = 0
	local spinVelocity: number = 0
	local isSelected: boolean = false
	local currentFormType: string = ""
	-- Resolved on change rather than matched per frame. See idleFor.
	local currentIdle: (number) -> CFrame = idleFor("")
	local animPhase: number = math.random() * math.pi * 2

	--==========================================================================
	-- A CARD ONLY ANIMATES WHILE SOMEBODY IS LOOKING AT IT
	--
	-- `hovered` is tracked here rather than read off popOnHover, because that
	-- one is deliberately switched OFF while a card is selected -- a selected
	-- card must not keep popping under the pointer -- and this gate needs the
	-- raw pointer state, not the decorated one.
	--
	-- `animT` is accumulated instead of reading os.clock() directly. That is
	-- the difference between pausing and stopping: wall-clock time keeps
	-- running while a card sleeps, so resuming against it would snap the idle
	-- curve forward by however long the pointer was away. Accumulated time just
	-- picks up where it left off.
	--
	-- `parked` records that the resting pose has already been written, so the
	-- sleeping branch costs one boolean test per card per frame and no
	-- viewport work at all.
	--==========================================================================
	local hovered: boolean = false
	local animT: number = 0
	local parked: boolean = false

	local function setupCamera(model: Model)
		local pivot, size = model:GetBoundingBox()
		addPedestal(model, pivot, size)

		pivot, size = model:GetBoundingBox()
		modelBasePivot = pivot
		local extent = math.max(size.Magnitude, 0.1)

		local camera = Instance.new("Camera")
		camera.FieldOfView = 38
		cameraDistance = (extent * CARD.CameraFill * 0.54)
			/ math.tan(math.rad(camera.FieldOfView * 0.5))
		cameraFocus = pivot.Position + Vector3.new(0, size.Y * (CARD.CameraRise * 0.88), 0)
		camera.CFrame = CFrame.lookAt(cameraFocus + CARD.CameraOffset.Unit * cameraDistance, cameraFocus)
		camera.Parent = hero
		hero.CurrentCamera = camera
		activeCamera = camera
	end

	local modelKey: string? = nil
	local function setModel(key: string, build: ((Instance) -> Model?)?, formName: string?)
		if modelKey == key then
			if formName then
				currentFormType = string.lower(formName)
				currentIdle = idleFor(currentFormType)
			end
			return
		end
		modelKey = key
		currentModel = nil
		activeCamera = nil
		hero:ClearAllChildren()
		hero.CurrentCamera = nil
		if not build then
			return
		end
		if formName then
			currentFormType = string.lower(formName)
		else
			currentFormType = ""
		end
		currentIdle = idleFor(currentFormType)
		local model = build(hero)
		if model then
			currentModel = model
			setupCamera(model)
			-- A new model has never been placed, so the resting pose owes it one
			-- write no matter what the pointer is doing.
			parked = false
		end
	end

	--==========================================================================
	-- ANIMATION LOOP: Interactive Orbit & Unique Plant Idles
	--==========================================================================
	--==========================================================================
	-- ONE UPDATER, DRIVEN BY THE SHARED LOOP
	--
	-- Registered rather than connected: see the loop at the top of the file for
	-- why seventeen RenderSteppeds was the thing making the game lag.
	--
	-- onScreen(holder) is the guard that `holder.Visible` was supposed to be and
	-- never was -- Visible is not inherited, so the old check was true even with
	-- every panel shut and the cards animated all session.
	--==========================================================================
	--==========================================================================
	-- IS THERE ANY REASON TO TOUCH THE VIEWPORT THIS FRAME?
	--
	-- Hovered or selected means somebody is looking. The other two terms are
	-- the wind-down: a clicked card carries spinVelocity, and a card returning
	-- from a spin eases currentYaw back to zero. Cutting either off mid-flight
	-- would stop the card dead the instant the pointer left it.
	--==========================================================================
	local function awake(): boolean
		return hovered or isSelected
			or spinVelocity > 0.05 or math.abs(currentYaw) > 0.0005
	end

	local function updateCard(dt: number)
		if not currentModel or not activeCamera then
			return
		end
		if not onScreen(holder) then
			return
		end

		if not awake() then
			--==================================================================
			-- ONE LAST WRITE, THEN NOTHING
			--
			-- Squared up to the authored three-quarter view and set to the idle
			-- pose at this card's own phase, so twelve sleeping cards are
			-- twelve different plants rather than twelve identical ones -- and
			-- none of them is frozen mid-lean at whatever angle the pointer
			-- happened to leave it.
			--==================================================================
			if not parked then
				parked = true
				currentYaw = 0
				activeCamera.CFrame = CFrame.lookAt(
					cameraFocus + CARD.CameraOffset.Unit * cameraDistance, cameraFocus)
				currentModel:PivotTo(modelBasePivot * currentIdle(animPhase))
			end
			return
		end
		parked = false

		-- Accumulated, not wall-clock. See the note where animT is declared.
		animT += dt
		local t = animT + animPhase

		--== SPIN ==--
		if isSelected then
			currentYaw += (1.5 + spinVelocity) * dt
			spinVelocity = math.max(0, spinVelocity - dt * 4.8)
		elseif spinVelocity > 0.05 then
			currentYaw += spinVelocity * dt
			spinVelocity = math.max(0, spinVelocity - dt * 4.8)
		else
			currentYaw = currentYaw + (-currentYaw) * math.min(1, dt * 7.5)
		end

		--======================================================================
		-- THE CAMERA ORBITS THE AUTHORED VIEW, IT DOES NOT REPLACE IT
		--
		-- This used to rebuild the position from a hardcoded +Z, which threw
		-- away CARD.CameraOffset entirely. That offset is (0.66, 0.28, -1), and
		-- the Z is NEGATIVE for a reason: addFace puts the eyes at -front, so
		-- -Z is the side with a face on it. Starting from +Z put the camera
		-- behind every plant on the first frame, which is why they all appeared
		-- to be facing away.
		--
		-- Now yaw rotates the authored direction, so yaw = 0 is exactly the
		-- three-quarter view setupCamera framed, and a spin orbits around it.
		--======================================================================
		local dir = CFrame.Angles(0, currentYaw, 0) * CARD.CameraOffset.Unit
		activeCamera.CFrame = CFrame.lookAt(cameraFocus + dir * cameraDistance, cameraFocus)

		--== THE IDLE, ALREADY CHOSEN ==--
		currentModel:PivotTo(modelBasePivot * currentIdle(t))
	end

	registerCard(button, updateCard)

	button.Destroying:Connect(function()
		-- The shared loop drops its own connection when the last card goes.
		unregisterCard(button)
	end)

	--==========================================================================
	-- THE ACTION BUTTON
	--==========================================================================
	local action = UIKit.slab(holder, {
		size = UDim2.new(1, -6, 0, CARD.ActionHeight),
		face = CARD.ActionFace,
		shade = CARD.ActionShade,
		radius = 8,
		latticeSpacing = 14,
		latticeTransparency = 0.84,
	})
	action.Name = "Action"
	action.AnchorPoint = Vector2.new(0.5, 1)
	action.Position = UDim2.new(0.5, 0, 1, 0)
	action.Visible = false
	action.ZIndex = Z_CARD

	local actionLabel = UIKit.outlined(action, "Label", CARD.ActionTextSize, WHITE, 2)
	actionLabel.Size = UDim2.fromScale(1, 1)
	actionLabel.Position = UDim2.fromOffset(0, 1)
	actionLabel.TextXAlignment = Enum.TextXAlignment.Center
	actionLabel.ZIndex = Z_LABEL

	UIKit.clicks(button)

	-- Trigger instant celebratory spin on click!
	button.MouseButton1Click:Connect(function()
		spinVelocity = 8.5
	end)

	--==========================================================================
	-- THE POINTER IS WHAT WAKES A CARD
	--
	-- Hooked on `button` because that is the card's hit area and the
	-- ViewportFrame is its child. Separate from popOnHover on purpose: see the
	-- note on `hovered` where it is declared.
	--
	-- Touch needs no case of its own. A tap fires MouseButton1Click, which sets
	-- spinVelocity, and the gate treats a spinning card as awake until it has
	-- coasted to a stop -- so a tap plays the whole flourish and then sleeps.
	--==========================================================================
	button.MouseEnter:Connect(function()
		hovered = true
	end)
	button.MouseLeave:Connect(function()
		hovered = false
	end)

	local setHovered, setPopEnabled = UIKit.popOnHover(holder, scale, { stroke = border })

	local lift = liftLayers(holder, CARD.HoverLift)
	local selected = false
	local function setSelected(on: boolean, label: string?)
		if selected == on then
			if on and label then
				actionLabel.Text = label
			end
			return
		end
		selected = on
		isSelected = on
		if on then
			spinVelocity = 8.5
		end
		setPopEnabled(not on)
		if on and label then
			actionLabel.Text = label
		end
		action.Visible = on
		lift(on)
		TweenService:Create(selectScale, TweenInfo.new(CARD.HoverSeconds,
			Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = if on then CARD.SelectScale else 1 }):Play()
	end

	local function setWeightTag(text: string?, color: Color3?)
		if text and text ~= "" then
			tagLeftText.Text = text
			tagLeftDot.BackgroundColor3 = color or WHITE
			tagLeft.Visible = true
		else
			tagLeft.Visible = false
		end
	end

	local function setStatusTag(text: string?, textColor: Color3?, bgColor: Color3?)
		if text and text ~= "" then
			tagRightText.Text = text
			tagRightText.TextColor3 = textColor or WHITE
			if bgColor then
				tagRight.BackgroundColor3 = bgColor
				tagRight.BackgroundTransparency = 0.2
			else
				tagRight.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
				tagRight.BackgroundTransparency = 0.30
			end
			tagRight.Visible = true
		else
			tagRight.Visible = false
		end
	end

	local function setProgress(fraction: number?, color: Color3?)
		if fraction ~= nil and fraction >= 0 then
			progressBar.Visible = true
			progressFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			if color then
				progressFill.BackgroundColor3 = color
			end
		else
			progressBar.Visible = false
		end
	end

	local pulsing = false
	local pulseConn: RBXScriptConnection? = nil
	local function setReadyPulse(on: boolean)
		if pulsing == on then
			return
		end
		pulsing = on
		if pulseConn then
			pulseConn:Disconnect()
			pulseConn = nil
		end
		if on then
			pulseConn = RunService.RenderStepped:Connect(function()
				-- Same guard the card updater uses. A ready plant behind a shut
				-- Garden was still lerping a colour sixty times a second.
				if not onScreen(holder) then
					return
				end
				local t = os.clock() * 4
				local alpha = (math.sin(t) * 0.5 + 0.5)
				local glowColor = Color3.fromRGB(245, 200, 45):Lerp(Color3.fromRGB(120, 245, 80), alpha)
				border.Color = glowColor
			end)
		end
	end

	local function setStageTheme(theme: string)
		if theme == "grown" then
			dusk.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 52, 44)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 25, 20)),
			})
			halo.BackgroundColor3 = Color3.fromRGB(180, 255, 200)
			halo.BackgroundTransparency = 0.86
			hillFar.BackgroundColor3 = Color3.fromRGB(24, 45, 36)
			hillNear.BackgroundColor3 = Color3.fromRGB(34, 64, 48)
			bgDeco.Visible = true
		elseif theme == "pod" then
			dusk.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 32, 54)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 14, 24)),
			})
			halo.BackgroundColor3 = Color3.fromRGB(220, 180, 255)
			halo.BackgroundTransparency = 0.88
			hillFar.BackgroundColor3 = Color3.fromRGB(32, 24, 44)
			hillNear.BackgroundColor3 = Color3.fromRGB(48, 36, 62)
			bgDeco.Visible = true
		elseif theme == "ready" then
			dusk.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 52, 22)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 18, 10)),
			})
			halo.BackgroundColor3 = Color3.fromRGB(255, 230, 120)
			halo.BackgroundTransparency = 0.78
			hillFar.BackgroundColor3 = Color3.fromRGB(56, 42, 18)
			hillNear.BackgroundColor3 = Color3.fromRGB(78, 60, 24)
			bgDeco.Visible = true
		elseif theme == "empty" then
			dusk.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 24, 28)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 16)),
			})
			halo.BackgroundColor3 = Color3.fromRGB(140, 150, 160)
			halo.BackgroundTransparency = 0.95
			hillFar.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
			hillNear.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
			bgDeco.Visible = true
		end
	end

	local function setEmpty(isEmpty: boolean)
		if isEmpty then
			tagLeft.Visible = false
			tagRight.Visible = false
			progressBar.Visible = false
			setReadyPulse(false)
			setStageTheme("empty")
			border.Color = Color3.fromRGB(110, 108, 116)
			border.Transparency = 0.45
			textShade.Visible = false
		else
			border.Transparency = 0
			textShade.Visible = true
		end
	end

	return {
		holder = holder,
		button = button,
		stage = stage,
		hero = hero,
		name = name,
		sub = sub,
		border = border,
		action = action,
		setBackdrop = setBackdrop,
		setModel = setModel,
		setHovered = setHovered,
		setSelected = setSelected,
		setWeightTag = setWeightTag,
		setStatusTag = setStatusTag,
		setProgress = setProgress,
		setReadyPulse = setReadyPulse,
		setStageTheme = setStageTheme,
		setEmpty = setEmpty,
	}
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
	-- Overwritten by UIKit.gradient below, which needs the surface white to
	-- multiply against. Set anyway so the shell is never momentarily the
	-- default grey if the gradient is ever dropped.
	shell.BackgroundColor3 = PANEL.Fill
	shell.BorderSizePixel = 0
	-- Consumes the click, so tapping the panel does not reach the dimmer under
	-- it and close the thing you are reading.
	shell.Active = true
	shell.Parent = group
	UIKit.corner(shell, 16)
	UIKit.stroke(shell, PANEL.Outline, outline)
	UIKit.gradient(shell, PANEL.Fill, PANEL.Shade)

	--==========================================================================
	-- THE SAME LATTICE AS THE RAIL, AND YOU CAN ACTUALLY SEE IT
	--
	-- A LIGHTER line on a DARKER fill, at a pitch near the rail's. The old one
	-- was a barely-lighter navy on navy at a pitch of 34, which is a texture
	-- that exists in the file and not on the screen.
	--
	-- Still quieter than anything sitting on it. Texture goes behind content,
	-- never with it -- the moment a diamond competes with a card the panel stops
	-- being a background.
	--
	-- Sized off the shell itself rather than off the cap: this panel is 0.9 of
	-- the screen up to a limit, so its real width is 300 on a phone and 480 on a
	-- desktop, and a lattice built for the larger one overhangs the smaller by
	-- ninety pixels in every direction.
	--==========================================================================
	UIKit.lattice(shell, {
		spacing = PANEL.LatticeSpacing,
		thickness = 2,
		colour = PANEL.Lattice,
		transparency = PANEL.LatticeTransparency,
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
		options.titleColour or PANEL.Title, 3)
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
	close.BackgroundColor3 = PANEL.Close
	close.BorderSizePixel = 0
	close.AutoButtonColor = false
	close.Font = Enum.Font.LuckiestGuy
	close.TextSize = 22
	close.TextColor3 = WHITE
	close.Text = "X"
	close.ZIndex = 4
	UIKit.clicks(close)
	close.Parent = titleBar
	UIKit.corner(close, 10)
	UIKit.stroke(close, PANEL.Outline, outline)

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
		-- Guarded by the equality check above, so a panel asked to open twice
		-- makes one sound. Two scripts both closing the same panel -- which is
		-- exactly what OpenPanel does when the Index and the Shop trade places
		-- -- is the case this protects.
		SoundKit.play(if want then "PanelOpen" else "PanelClose")
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
		--======================================================================
		-- THE FLOOR GIVES WAY, IT DOES NOT WIN
		--
		-- `math.clamp(x, 240, ceiling)` THROWS when the ceiling is under 240 --
		-- max must be >= min -- and that is reachable: a viewport reports a few
		-- dozen pixels for a frame or two while a Play session starts up, which
		-- is early enough that GardenUI's first relayout lands inside it. The
		-- guard above only catches a screen of exactly zero:
		--
		--     invalid argument #3 to 'clamp' (max must be greater than or equal
		--     to min)  --  UIKit fitContent <- GardenUI relayout
		--
		-- A 200-pixel screen and a 240-pixel minimum is not a contradiction to
		-- resolve, it is the screen winning. So the minimum bends down to the
		-- ceiling rather than the call blowing up and abandoning the layout.
		--======================================================================
		local want = math.clamp(contentHeight + 82, math.min(240, ceiling), ceiling)
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
