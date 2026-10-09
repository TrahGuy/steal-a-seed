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
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--==============================================================================
-- THERE IS NO CARD LOOP ANY MORE
--
-- This file used to run one shared RenderStepped over a registry of cards, and
-- each card used it to bob, lean, spin and orbit its camera. All of that is
-- gone: a card is a still three-quarter photograph of the real model and the
-- camera is written once, when the model is built.
--
-- The loop is REMOVED rather than left idling. A registry that nothing registers
-- with is a connection waiting to be re-armed by the next person who wants "just
-- a little" motion, and the whole point of this pass is that there is none.
--
-- `onScreen` below survives because the selection and pop helpers still use it.
--==============================================================================

--==============================================================================
-- IS THIS THING ACTUALLY ON SCREEN?--==============================================================================
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
-- The per-form idle poses -- the bell's swing, the orb's breath, the cube's
-- settle -- were removed with the loop that drove them. A card's pose is now
-- whatever the builder authored, written once.

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local SoundKit = require(script.Parent:WaitForChild("SoundKit"))
-- Where the rail is on this screen, for the modal header that steps clear of it
-- and for the compact badge. Numbers only; it requires nothing but GameConfig.
local HudLayout = require(script.Parent:WaitForChild("HudLayout"))

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

--==============================================================================
-- THE CLICK SHAKE
--
-- Applied to an INNER element, never to the one a layout owns. A UIGridLayout
-- and a UIListLayout both write Position on their children every time they
-- reflow, so a tween on a grid cell is a tween arguing with the layout -- it
-- lands wherever the last writer won. Every caller here passes the wrapper
-- inside the cell instead, whose position nothing else touches.
--
-- The resting position is read ONCE, when the shake is wired, and every step
-- offsets from that. Reading it per click would capture a mid-shake position as
-- "rest" the moment two clicks overlapped, and the card would walk off sideways
-- a few pixels at a time.
--
-- Overlapping clicks are handled by a token rather than by a busy flag: a
-- second click abandons the first sequence wherever it is and starts a new one
-- from rest. Ignoring the second click instead would make a fast double-press
-- feel like the second one did not register.
--==============================================================================
export type ShakeOptions = {
	pixels: number?,
	seconds: number?,
}

function UIKit.shake(target: GuiObject, options: ShakeOptions?): () -> ()
	local opts: ShakeOptions = options or {}
	local amp = opts.pixels or CARD.ShakePixels
	local total = opts.seconds or CARD.ShakeSeconds
	local rest = target.Position

	-- Decaying reversals, ending exactly on rest so no rounding can leave the
	-- card a pixel off centre after a hundred clicks.
	local steps = { 1.0, -0.7, 0.45, -0.22, 0 }
	local each = total / #steps
	local info = TweenInfo.new(each, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local token = 0
	return function()
		token += 1
		local mine = token
		task.spawn(function()
			for _, k in ipairs(steps) do
				-- A newer click owns the card now; leave it to finish.
				if token ~= mine or not target.Parent then
					return
				end
				local goal = UDim2.new(
					rest.X.Scale, rest.X.Offset + math.round(amp * k),
					rest.Y.Scale, rest.Y.Offset)
				TweenService:Create(target, info, { Position = goal }):Play()
				task.wait(each)
			end
			-- Snapped, not tweened: the last tween has already arrived and this
			-- only guarantees the exact resting value.
			if token == mine and target.Parent then
				target.Position = rest
			end
		end)
	end
end

--==============================================================================
-- A CARD THAT SHAKES WHEN IT IS PRESSED
--
-- `button` is what the player actually hits and `target` is what moves, because
-- in the shop those are not the same object: the pressable thing is the price
-- pill and the thing worth moving is the whole tile.
--==============================================================================
function UIKit.shakeOnClick(button: GuiButton, target: GuiObject,
	options: ShakeOptions?): () -> ()
	local shake = UIKit.shake(target, options)
	button.Activated:Connect(shake)
	return shake
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
	-- The chords are Offsets, so the surface is measured in its gui's own units:
	-- on a TV (UIKit.tenFoot) AbsoluteSize is that many times bigger. 1 elsewhere.
	local function surface(): Vector2
		return parent.AbsoluteSize / HudLayout.scaleOf(parent)
	end

	local pending = false
	local function request()
		if pending then
			return
		end
		pending = true
		task.delay(0.12, function()
			pending = false
			local size = surface()
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
		build(surface())
	end

	return holder
end

--==============================================================================
-- RAISED SQUARE STUDS, DRAWN (2026-10-04, the global UI art pass)
--
-- The owner's studded look -- the white header rim, the red close, a primary
-- button -- as a quiet accent: small raised squares at ONE fixed pitch, each a
-- face over a shade nudged down and left, so it reads as the reference's soft
-- "L" bevel. Never stretched: the grid keeps its pitch on any surface and only
-- whole studs are drawn, centred, inside `inset`.
--
-- FRAMES, NOT A PICTURE, because the twelve-colour atlas (art/textures/ui-studs-
-- 2026-10-04) is not uploaded and its cells were measured NOT seamless (rows one
-- and two jump 60-112 levels across their wrap). `image` takes a verified,
-- seamless upload when there is one: then it is ONE tiled ImageLabel at the
-- same pitch (the tile holds `tileStuds` studs a side) and no frames at all.
--
-- Built once and again only when the surface's size settles, like the lattice:
-- no per-frame work. Two frames a stud; a 900 x 36 rim at pitch 20 is ~88.
--==============================================================================
export type StudOptions = {
	pitch: number?,
	size: number?,
	face: Color3,
	shade: Color3,
	faceTransparency: number?,
	shadeTransparency: number?,
	-- Kept clear of the surface's edges (a rounded corner, a keyline).
	inset: number?,
	-- Separate insets for the top and the bottom (a rim's rule, a button's foot).
	insetTop: number?,
	insetBottom: number?,
	zIndex: number?,
	image: string?,
	tileStuds: number?,
}

function UIKit.studs(parent: GuiObject, options: StudOptions): Frame
	local pitch = math.max(4, options.pitch or 20)
	local size = math.clamp(options.size or math.floor(pitch * 0.5), 2, pitch - 1)
	local inset = options.inset or 4
	local top = options.insetTop or inset
	local bottom = options.insetBottom or inset
	local layer = options.zIndex or parent.ZIndex
	local bevel = math.max(1, math.floor(size * 0.14 + 0.5))

	local holder = Instance.new("Frame")
	holder.Name = "Studs"
	-- The colours live on the holder, so a rebuild and UIKit.paintStuds agree.
	holder:SetAttribute("Face", options.face)
	holder:SetAttribute("Shade", options.shade)
	holder.Position = UDim2.fromOffset(inset, top)
	holder.Size = UDim2.new(1, -inset * 2, 1, -(top + bottom))
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.Active = false
	holder.ZIndex = layer
	holder.Parent = parent

	local image = options.image
	if image and image ~= "" then
		local tile = Instance.new("ImageLabel")
		tile.Name = "Tile"
		tile.Size = UDim2.fromScale(1, 1)
		tile.BackgroundTransparency = 1
		tile.BorderSizePixel = 0
		tile.Image = image
		tile.ScaleType = Enum.ScaleType.Tile
		local span = pitch * (options.tileStuds or 8)
		tile.TileSize = UDim2.fromOffset(span, span)
		tile.ImageTransparency = options.faceTransparency or 0
		tile.Active = false
		tile.ZIndex = layer
		tile.Parent = holder
		return holder
	end

	-- The studs follow their holder's ZIndex (a close button re-stacked later).
	holder:GetPropertyChangedSignal("ZIndex"):Connect(function()
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("GuiObject") then
				child.ZIndex = holder.ZIndex
			end
		end
	end)

	local builtFor = Vector2.new(-1, -1)
	local function build(area: Vector2)
		builtFor = area
		holder:ClearAllChildren()
		layer = holder.ZIndex
		local faceColour = (holder:GetAttribute("Face") :: Color3?) or options.face
		local shadeColour = (holder:GetAttribute("Shade") :: Color3?) or options.shade
		local cols = math.floor((area.X - size) / pitch) + 1
		local rows = math.floor((area.Y - size) / pitch) + 1
		if area.X < size or area.Y < size or cols < 1 or rows < 1 then
			return
		end
		-- Centred, so a surface's left and right margins match.
		local x0 = math.floor((area.X - ((cols - 1) * pitch + size)) / 2)
		local y0 = math.floor((area.Y - ((rows - 1) * pitch + size)) / 2)
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				local x, y = x0 + c * pitch, y0 + r * pitch
				local shade = Instance.new("Frame")
				shade.Name = "Shade"
				shade.Position = UDim2.fromOffset(x - bevel, y + bevel)
				shade.Size = UDim2.fromOffset(size, size)
				shade.BackgroundColor3 = shadeColour
				shade.BackgroundTransparency = options.shadeTransparency or 0
				shade.BorderSizePixel = 0
				shade.Active = false
				shade.ZIndex = layer
				shade.Parent = holder
				local face = Instance.new("Frame")
				face.Name = "Stud"
				face.Position = UDim2.fromOffset(x, y)
				face.Size = UDim2.fromOffset(size, size)
				face.BackgroundColor3 = faceColour
				face.BackgroundTransparency = options.faceTransparency or 0
				face.BorderSizePixel = 0
				face.Active = false
				face.ZIndex = layer
				face.Parent = holder
			end
		end
	end

	-- In the gui's own units (a TV's AbsoluteSize is that many times bigger),
	-- and rebuilt on the trailing edge of a resize, never through an open pop.
	local function area(): Vector2
		return holder.AbsoluteSize / HudLayout.scaleOf(holder)
	end
	local pending = false
	local function request()
		if pending then
			return
		end
		pending = true
		task.delay(0.12, function()
			pending = false
			if holder.Parent == nil then
				return
			end
			local now = area()
			if math.abs(now.X - builtFor.X) < 1 and math.abs(now.Y - builtFor.Y) < 1 then
				return
			end
			build(now)
		end)
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(request)
	if holder.AbsoluteSize.X > 0 and holder.AbsoluteSize.Y > 0 then
		build(area())
	end
	return holder
end

-- New colours for a stud field already drawn (a button changing its face).
function UIKit.paintStuds(holder: Frame, face: Color3, shade: Color3)
	holder:SetAttribute("Face", face)
	holder:SetAttribute("Shade", shade)
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") then
			child.BackgroundColor3 = if child.Name == "Shade" then shade else face
		end
	end
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
-- A CALENDAR PAGE (2026-10-04, the global UI pass) -- A TEMPORARY ICON
--
-- No approved EVENTS picture exists (GameConfig.Rail.EventsArt is ""), so the
-- Events button and the panel's title draw this from frames: a white page with
-- an ink keyline, a red binding band with two rings, and six days, one gold.
-- Fills `parent` (scale coordinates), so it works at any size. It is a native
-- stand-in, listed as an asset gap -- never the final icon.
--==============================================================================
function UIKit.calendarIcon(parent: GuiObject, z: number): Frame
	local box = Instance.new("Frame")
	box.Name = "Calendar"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Size = UDim2.fromScale(1, 1)
	box.Active = false
	box.ZIndex = z
	box.Parent = parent
	local red = Color3.fromRGB(232, 72, 70)
	local page = piece(box, "Page", 0.5, 0.58, 0.84, 0.70, WHITE, 0.16, nil, z)
	local edge = UIKit.stroke(page, BLACK, 1.5)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local band = piece(box, "Band", 0.5, 0.31, 0.84, 0.20, red, 0.3, nil, z + 1)
	local bandEdge = UIKit.stroke(band, BLACK, 1.5)
	bandEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	piece(box, "RingL", 0.33, 0.19, 0.10, 0.20, BLACK, 0.5, nil, z + 2)
	piece(box, "RingR", 0.67, 0.19, 0.10, 0.20, BLACK, 0.5, nil, z + 2)
	for r = 0, 1 do
		for c = 0, 2 do
			local today = r == 1 and c == 2
			piece(box, "Day", 0.30 + c * 0.20, 0.57 + r * 0.19, 0.14, 0.12,
				if today then Color3.fromRGB(255, 196, 48) else Color3.fromRGB(176, 186, 182), 0.3, nil, z + 1)
		end
	end
	return box
end

--==============================================================================
-- A SCROLL OF NOTES (2026-10-05, WHAT'S NEW) -- A TEMPORARY ICON
--
-- No approved WHAT'S NEW picture exists, so its button and its panel's title
-- draw this from frames: a cream page between two rolled ends, an ink keyline
-- round each, and three written lines -- the last one short. Nothing is thinner
-- than 0.09 of the box (the open book's lesson above). Fills `parent` (scale
-- coordinates), so it works at any size. A native stand-in, listed as an asset
-- gap -- never the final icon.
--==============================================================================
function UIKit.scrollIcon(parent: GuiObject, z: number): Frame
	local box = Instance.new("Frame")
	box.Name = "Scroll"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Size = UDim2.fromScale(1, 1)
	box.Active = false
	box.ZIndex = z
	box.Parent = parent
	local cream = Color3.fromRGB(255, 246, 222)
	local roll = Color3.fromRGB(226, 190, 128)
	local ink = Color3.fromRGB(140, 104, 64)
	local page = piece(box, "Page", 0.5, 0.53, 0.70, 0.66, cream, 0.08, nil, z)
	UIKit.stroke(page, BLACK, 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	for _, at in ipairs({ { "RollTop", 0.17 }, { "RollBottom", 0.88 } }) do
		local end_ = piece(box, at[1] :: string, 0.5, at[2] :: number, 0.86, 0.17, roll, 0.5, nil, z + 1)
		UIKit.stroke(end_, BLACK, 1.5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	piece(box, "Line", 0.5, 0.40, 0.46, 0.09, ink, 0.5, nil, z + 1)
	piece(box, "Line", 0.5, 0.53, 0.46, 0.09, ink, 0.5, nil, z + 1)
	piece(box, "Line", 0.42, 0.66, 0.30, 0.09, ink, 0.5, nil, z + 1)
	return box
end

--==============================================================================
-- THE CYCLE'S TWO ICONS (2026-10-04) -- NATIVE STAND-INS
--
-- The HUD clock's moon and cloud (counting down to night) and sun and cloud
-- (counting down to dawn). The approved art (art/icons/hud-cycle-2026-10-04)
-- has no upload id yet (GameConfig.WorldCycle.ClockIcons), so until it has,
-- these draw from frames: a round badge with an ink keyline -- night blue
-- under the moon, sky blue under the sun -- the body, and a cloud in front.
-- The crescent is the moon with a bite of the badge's own blue taken out of
-- it. Fills `parent` (scale coordinates), every piece inside the badge's
-- circle. No red in either: the clock's warning is its words' colour, never
-- the icon's.
--==============================================================================
function UIKit.cycleIcon(parent: GuiObject, kind: "moon" | "sun", z: number): Frame
	local sun = kind == "sun"
	local box = Instance.new("Frame")
	box.Name = if sun then "SunCloud" else "MoonCloud"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Size = UDim2.fromScale(1, 1)
	box.Active = false
	box.ZIndex = z
	box.Parent = parent
	local sky = if sun then Color3.fromRGB(96, 176, 238) else Color3.fromRGB(38, 52, 104)
	local badge = piece(box, "Badge", 0.5, 0.5, 1, 1, sky, 0.5, nil, z)
	local edge = UIKit.stroke(badge, BLACK, 1.5)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if sun then
		local disc = piece(box, "Sun", 0.40, 0.40, 0.50, 0.50, Color3.fromRGB(255, 204, 52), 0.5, nil, z + 1)
		local rim = UIKit.stroke(disc, Color3.fromRGB(226, 128, 18), 1)
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		piece(box, "Glint", 0.33, 0.32, 0.14, 0.14, Color3.fromRGB(255, 244, 190), 0.5, nil, z + 2)
	else
		piece(box, "Moon", 0.40, 0.42, 0.54, 0.54, Color3.fromRGB(246, 246, 236), 0.5, nil, z + 1)
		piece(box, "Bite", 0.55, 0.31, 0.46, 0.46, sky, 0.5, nil, z + 2)
	end
	local cloud = if sun then WHITE else Color3.fromRGB(182, 194, 226)
	piece(box, "Cloud", 0.64, 0.73, 0.52, 0.20, cloud, 0.5, nil, z + 3)
	piece(box, "Puff", 0.52, 0.66, 0.24, 0.24, cloud, 0.5, nil, z + 3)
	piece(box, "Puff", 0.68, 0.60, 0.30, 0.30, cloud, 0.5, nil, z + 3)
	piece(box, "Puff", 0.82, 0.69, 0.18, 0.18, cloud, 0.5, nil, z + 3)
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
-- AN UPLOADED PICTURE THAT MAY NOT LOAD HERE (2026-10-03)
--
-- An upload alone proves nothing: an id can be mistyped, held in moderation or
-- not usable by this experience. So the picture is preloaded through its OWN
-- ImageLabel -- PreloadAsync's string form answered Failure for art that drew
-- fine (measured 2026-09-11) -- and `onResult(true)` is said once it has
-- loaded, `onResult(false)` if it has not within PICTURE_WAIT seconds; a load
-- that comes later still says true.
--
-- THE CALLER NEVER HIDES THE PICTURE. It lays the old icon UNDER it and hides
-- the old icon on true -- nothing else. Measured 2026-10-03 in Play: a label at
-- ImageTransparency 1 (a status line built hidden, before its fade-in) never
-- reports IsLoaded while a visible twin of the same id loads in 3 s, so a
-- picture hidden on a timeout would never get the chance to load. Unloaded, a
-- picture draws nothing, and the old icon under it is what shows.
--
-- IsLoaded IS POLLED, NOT WATCHED: its changed signal never fired in Play
-- (2026-10-03) -- a closed Bag's pictures loaded on opening and the drawn icons
-- under them stayed. One shared check every half second, running only while
-- some picture is still waiting, stopped when none is; a picture taken away
-- stops being asked about.
--==============================================================================
local PICTURE_WAIT = 8
local PICTURE_POLL = 0.5
type PictureWait = { picture: ImageLabel, onResult: (boolean) -> (), since: number, told: boolean }
local waitingPictures: { PictureWait } = {}
local pictureLoopRunning = false

local function checkPictures()
	pictureLoopRunning = true
	while #waitingPictures > 0 do
		task.wait(PICTURE_POLL)
		local now = os.clock()
		for i = #waitingPictures, 1, -1 do
			local w = waitingPictures[i]
			if w.picture.Parent == nil then
				table.remove(waitingPictures, i)
			elseif w.picture.IsLoaded then
				table.remove(waitingPictures, i)
				w.onResult(true)
			elseif not w.told and now - w.since >= PICTURE_WAIT then
				w.told = true
				w.onResult(false)
			end
		end
	end
	pictureLoopRunning = false
end

function UIKit.whenPictureLoads(picture: ImageLabel, onResult: (boolean) -> ())
	if picture.IsLoaded then
		onResult(true)
		return
	end
	table.insert(waitingPictures, { picture = picture, onResult = onResult, since = os.clock(), told = false })
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ picture })
		end)
	end)
	if not pictureLoopRunning then
		task.spawn(checkPictures)
	end
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
	-- Slab and bare buttons. An art button's picture carries its own.
	icon: string?,
	-- Slab buttons only. A bare button has no plate to paint.
	face: Color3?,
	shade: Color3?,
	label: string?,
	wide: boolean?,
	-- `bare` drops the slab entirely: the artwork IS the button, no background
	-- and no rounded square. Garden and the Bag are bare.
	bare: boolean?,
	-- `art` is a whole button in one square picture -- outline, face, icon and
	-- word -- drawn square at any size with nothing of ours round it. Index and
	-- Shop are art buttons (2026-09-24). `rim` turns the rainbow behind a
	-- picture whose rim band was cut out for it: the Shop's.
	art: string?,
	rim: boolean?,
	-- Bare and art buttons: the plain word drawn under the picture until a
	-- picture of the button's has loaded here (UIKit.railFallback).
	fallback: string?,
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

--==============================================================================
-- ON A TV, OUR SCREENS ARE DRAWN BIGGER
--
-- HudLayout's TEN-FOOT PROFILE, applied: a gui that opts in with UIKit.tenFoot
-- gets a UIScale named TenFoot when Roblox says the screen is a TV, at the
-- magnification HudLayout.tenFootScale gives the window -- and nothing at all
-- anywhere else, so a desktop's or a phone's instance tree is exactly what it
-- was. HudLayout.measure sees the UIScale and answers that gui's owner in the
-- gui's logical units.
--
-- Opted in: the rail layer (below), every UIKit.modal, and each HUD owner's
-- own ScreenGui. Not: the RUN alarm (drawn in fractions of the screen already)
-- and the world-anchored pops, which are not laid out on the screen.
--==============================================================================
local tenFootGuis: { [LayerCollector]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local tenFootWatch: RBXScriptConnection? = nil

--==============================================================================
-- THE PLAYER'S MENU SIZE (2026-09-26)
--
-- GameConfig.MenuSize, saved on the profile and stamped on the player as the
-- MenuSize attribute; `pendingMenuSize` is Settings' own choice, shown at once
-- while the server writes it down. Two ways it reaches a menu:
--
--   A MENU'S OWN GUI   (UIKit.menuGui) -- a ScreenGui that holds only a panel.
--                      The size is folded into that gui's one UIScale with the
--                      TV scale, so every existing "divide by the gui's scale"
--                      read in the menu stays right with no change. HudLayout
--                      only calls a gui a TV when the engine says it is one, so
--                      the rail and the HUD are placed exactly as before.
--   A PANEL IN A HUD GUI  (the Bag) -- scaled on its own panel, through
--                      modal.setUserScale, sized by HudLayout.bag.
--
-- EITHER WAY IT FITS. menuScaleFor takes the smaller of the chosen size and
-- what the usable screen allows the menu's minimum panel, so a larger choice on
-- a short phone is as large as that phone allows and no panel leaves the glass.
-- At the default size nothing is made at all -- except on a phone, where every
-- menu is drawn at GameConfig.MenuSize.PhoneScale times the chosen size
-- (2026-10-08): smaller, and short of the screen's edges.
--==============================================================================
local menuGuis: { [LayerCollector]: Vector2 } = setmetatable({}, { __mode = "k" }) :: any
local pendingMenuSize: string? = nil
local menuSizeListeners: { () -> () } = {}
local menuSizeWatched = false

-- The chosen option id: Settings' pending choice, else the saved attribute.
function UIKit.menuSizeId(): string
	local id: any = pendingMenuSize
	if id == nil then
		local player = Players.LocalPlayer
		id = if player then player:GetAttribute(GameConfig.Attributes.MenuSize) else nil
	end
	return if GameConfig.menuSizeScale(id) ~= nil then id else GameConfig.MenuSize.Default
end

-- The chosen scale, before any screen has had its say.
function UIKit.menuScale(): number
	return GameConfig.menuSizeScale(UIKit.menuSizeId()) or 1
end

-- What a phone draws every menu at (GameConfig.MenuSize.PhoneScale), 1 on
-- anything else -- a TV is never a phone.
function UIKit.phoneMenuScale(): number
	if HudLayout.isTenFoot() then
		return 1
	end
	local camera = Workspace.CurrentCamera
	return GameConfig.menuPhoneScale(if camera then camera.ViewportSize else nil, UserInputService.TouchEnabled)
end

-- What `gui` may actually be drawn at: the chosen scale (times the phone's,
-- UIKit.phoneMenuScale), no more than keeps its minimum panel inside 90% x 86%
-- of the screen -- the same fractions UIKit.modal sizes panels by -- in the
-- gui's own TV units (`k`). Never below the phone's scale: 1 off a phone.
--
-- BELOW 1 ON A PHONE the gui's canvas is that much larger than the screen, and
-- each menu's panel takes only that share of it (MenuLayout's `fill`, the
-- modal's `share`), so the panel keeps the room it had and is drawn smaller,
-- short of the screen's edges.
function UIKit.menuScaleFor(gui: LayerCollector, k: number): number
	local need = menuGuis[gui]
	if not need then
		return 1
	end
	local phone = UIKit.phoneMenuScale()
	local want = UIKit.menuScale() * phone
	if want <= phone then
		return phone
	end
	local size = gui.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return phone
	end
	local fitW = (size.X / k) * 0.9 / need.X
	local fitH = (size.Y / k) * 0.86 / need.Y
	return math.max(phone, math.min(want, fitW, fitH))
end

local function applyTenFoot(gui: LayerCollector)
	local camera = Workspace.CurrentCamera
	local existing = gui:FindFirstChild(HudLayout.TenFootName)
	local k = 1
	if not (camera and HudLayout.isTenFoot()) then
		-- Off a TV: no UIScale at all, unless this is a menu's own gui and the
		-- player has chosen bigger menus, or the screen is a phone's.
		k = 1
	else
		k = HudLayout.tenFootScale((camera :: Camera).ViewportSize)
	end
	local want = k * UIKit.menuScaleFor(gui, k)
	if want == 1 then
		if existing then
			existing:Destroy()
		end
		return
	end
	local scale: UIScale
	if existing and existing:IsA("UIScale") then
		scale = existing
	else
		scale = Instance.new("UIScale")
		scale.Name = HudLayout.TenFootName
		scale.Parent = gui
	end
	scale.Scale = want
end

local function menuSizeChanged()
	for gui in pairs(menuGuis) do
		if gui.Parent then
			applyTenFoot(gui)
		end
	end
	for _, fn in ipairs(menuSizeListeners) do
		task.spawn(fn)
	end
end

local function watchMenuSize()
	if menuSizeWatched then
		return
	end
	local player = Players.LocalPlayer
	if not player then
		return
	end
	menuSizeWatched = true
	player:GetAttributeChangedSignal(GameConfig.Attributes.MenuSize):Connect(function()
		-- The server has written it down; its word replaces the pending one.
		pendingMenuSize = nil
		menuSizeChanged()
	end)
end

-- Settings' choice, applied now; the caller sends it to the server to be saved.
function UIKit.setMenuSize(id: string)
	if GameConfig.menuSizeScale(id) == nil or UIKit.menuSizeId() == id then
		return
	end
	pendingMenuSize = id
	watchMenuSize()
	menuSizeChanged()
end

-- For a panel that scales itself (the Bag): called whenever the size changes.
function UIKit.onMenuSize(fn: () -> ())
	watchMenuSize()
	table.insert(menuSizeListeners, fn)
end

-- Marks `gui` as holding only a menu, whose minimum panel is `need` (the modal's
-- own minimum unless a menu cannot scroll and needs more). Call after tenFoot.
function UIKit.menuGui(gui: LayerCollector, need: Vector2?)
	menuGuis[gui] = need or Vector2.new(248, 240)
	watchMenuSize()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyTenFoot(gui)
	end)
	applyTenFoot(gui)
end

-- Every opted-in gui again: on a new window size, and for a harness that has
-- just set HudLayout.tenFootOverride.
function UIKit.refreshTenFoot()
	for gui in pairs(tenFootGuis) do
		if gui.Parent then
			applyTenFoot(gui)
		end
	end
end

function UIKit.tenFoot(gui: LayerCollector)
	tenFootGuis[gui] = true
	applyTenFoot(gui)
	if not tenFootWatch and HudLayout.isTenFoot() then
		local camera = Workspace.CurrentCamera
		if camera then
			tenFootWatch = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UIKit.refreshTenFoot)
		end
	end
end

-- What an AbsoluteSize / AbsolutePosition / TextBounds read inside `object`'s
-- gui is divided by to become an Offset: its TenFoot scale, or 1.
function UIKit.scaleOf(object: Instance?): number
	return HudLayout.scaleOf(object)
end

--==============================================================================
-- THE LEAST SCROLL THAT SHOWS A SPAN
--
-- One axis of a list that scrolls: a window `view` long whose near edge is at
-- `canvas`, on a canvas `total` long, and a span [lo, hi] of it that has to be
-- seen. Returns where the near edge goes -- where it already is when the span
-- shows, else moved the least distance that shows it. Every number in one
-- space: the gui's own units, which is what CanvasPosition is in.
--
-- A SPAN LONGER THAN THE WINDOW SHOWS ITS FAR END. The Garden asks this for a
-- whole card, whose one control -- PICK UP -- is the card's bottom strip, and
-- on a landscape phone a card can be taller than the list. Showing the top
-- would scroll the button the reveal was for back out of reach.
--==============================================================================
function UIKit.scrollToShow(canvas: number, view: number, lo: number, hi: number,
	total: number): number
	local want = canvas
	if lo < want then
		want = lo
	end
	if hi > want + view then
		want = hi - view
	end
	return math.clamp(want, 0, math.max(0, total - view))
end

-- Whether [lo, hi] lies wholly inside the window, to within `slack` (1 unit
-- unless given: a canvas lands on fractions).
function UIKit.spanShown(canvas: number, view: number, lo: number, hi: number,
	slack: number?): boolean
	local s = slack or 1
	return lo >= canvas - s and hi <= canvas + view + s
end

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
	UIKit.tenFoot(layer)
	layer.Parent = playerGui
	return layer
end

--==============================================================================
-- THE PHONE'S DOCK: ONE SHARED FRAME IN THE RAIL LAYER
--
-- On a touch screen Index, Shop and Settings stand in a dock down the left edge
-- that shuts (HudLayout, THE PHONE'S SIDEBARS). Each of the three still builds,
-- shapes, places and answers its own button; on a phone it parents that button
-- into this frame, and RailDrawerUI slides the frame -- so the three move as one
-- without anybody moving anybody else's button.
--
-- The layer's full size and transparent, so a position in it is a position in
-- the layer. Not Active: it takes no input of its own. Found rather than
-- rebuilt, like the layer, so a script that re-runs never takes its neighbours'
-- buttons down with it. Visible until RailDrawerUI says otherwise, so a phone
-- whose drawer script never ran still has all three buttons.
--==============================================================================
local RAIL_DOCK = "Dock"

function UIKit.railDock(playerGui: Instance): Frame
	local layer = UIKit.railLayer(playerGui)
	local existing = layer:FindFirstChild(RAIL_DOCK)
	if existing and existing:IsA("Frame") then
		return existing
	end
	local dock = Instance.new("Frame")
	dock.Name = RAIL_DOCK
	dock.Size = UDim2.fromScale(1, 1)
	dock.BackgroundTransparency = 1
	dock.BorderSizePixel = 0
	dock.Active = false
	dock.Parent = layer
	return dock
end

--==============================================================================
-- THE PANEL UNDER THE BAG SCROLLS AND SHUTS (the owner, 2026-10-06)
--
-- On a phone the panel's four squares -- INVITE, EVENTS, WHAT'S NEW, Settings --
-- stand in one shared ScrollingFrame inside a clipping frame that slides shut,
-- both in the dock frame. RailDrawerUI owns their place, size, slide and fade
-- (HudLayout's `dockView` and `handle`); each square's own script places it in
-- the canvas at its HudLayout rect less the viewport's corner (placeRail).
--==============================================================================
local DOCK_CLIP, DOCK_SCROLL = "DockClip", "DockScroll"

function UIKit.railDockScroll(playerGui: Instance): ScrollingFrame
	local dock = UIKit.railDock(playerGui)
	local clip = dock:FindFirstChild(DOCK_CLIP)
	if not (clip and clip:IsA("Frame")) then
		local made = Instance.new("Frame")
		made.Name = DOCK_CLIP
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.ClipsDescendants = true
		made.Active = false
		made.Parent = dock
		clip = made
	end
	local existing = (clip :: Frame):FindFirstChild(DOCK_SCROLL)
	if existing and existing:IsA("ScrollingFrame") then
		return existing
	end
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = DOCK_SCROLL
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	-- A row since 2026-10-09 (HudLayout, THE TOP-RIGHT CORNER): it runs, and
	-- would scroll, sideways; down the edge before.
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageTransparency = 0.3
	scroll.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	scroll.Selectable = false
	scroll.Parent = clip
	-- The squares are placed with the left padding in their rects; the right's
	-- is the canvas's own, so AutomaticCanvasSize ends a pad after the last square.
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, HudLayout.Config.Phone.Panel.Pad)
	pad.Parent = scroll
	return scroll
end

-- Where a rail button stands on this screen: on a phone whose panel scrolls, in
-- its canvas at its place there; elsewhere in the rail layer (the dock frame on
-- a phone) at HudLayout's place, as every rail button always stood.
function UIKit.placeRail(button: GuiObject, layout: any, r: any, playerGui: Instance)
	local view = layout.dockView
	if layout.sidebar and view then
		button.Parent = UIKit.railDockScroll(playerGui)
		button.Position = UDim2.fromOffset(r.x - view.x, r.y - view.y)
	else
		button.Parent = if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)
		button.Position = HudLayout.place(r, Vector2.zero, layout.safe)
	end
end

-- A square in that panel tells its handle it wears a badge (2026-10-06): "bang"
-- for INVITE's "!", "dot" for a red dot, nil for none. Client-local attributes on
-- the local player; RailDrawerUI shows one on the handle while the panel is shut.
UIKit.DockBadgePrefix = "SeedDockBadge_"
function UIKit.dockBadge(name: string, kind: string?)
	local me = game:GetService("Players").LocalPlayer
	if me then
		me:SetAttribute(UIKit.DockBadgePrefix .. name, kind)
	end
end

--==============================================================================
-- THE BEGINNER'S GUIDE CARD, SHOWING (2026-10-09)
--
-- Whether TutorialUI's card stands under the top row now -- its banner, its
-- SKIP, or its RESUME in the banner's place, all inside its Words frame --
-- shown only while every frame up to the gui is. What the Pod Rush tracker and
-- the buff popover keep clear of (HudLayout's banner and skip rects).
--==============================================================================
function UIKit.guideShowing(playerGui: Instance): boolean
	local guide = playerGui:FindFirstChild("SeedBeginnerGuide")
	if not (guide and guide:IsA("ScreenGui") and guide.Enabled) then
		return false
	end
	for _, name in ipairs({ "Instruction", "Resume", "Skip" }) do
		local node: Instance? = guide:FindFirstChild(name, true)
		local shown = node ~= nil and node:IsA("GuiObject")
		while shown and node and node ~= guide do
			if node:IsA("GuiObject") and not node.Visible then
				shown = false
			end
			node = node.Parent
		end
		if shown then
			return true
		end
	end
	return false
end

--==============================================================================
-- A PANEL THAT COVERS THE RAIL (2026-10-03, the compact Index and Shop)
--
-- The rail layer draws above every panel so its buttons stay pressable -- right
-- on a desktop, where those panels stand between the rails. On a phone (or any
-- window too narrow for that) they take the whole safe area instead, and then
-- Walk Mode, Garden, the Bag and the x2 card would stand over the panel's header
-- and take its taps. So while such a panel is open the layer steps BELOW the
-- panels' dimmers (RAIL_COVERED_ORDER: under the hotbar's 30 too): its buttons
-- are behind the dimmer, unpressable, and the dimmer's tap still closes the
-- panel. A set of owners, so the Index closing as the Shop opens (OpenPanel)
-- leaves it covered; the last owner out puts it back at 40. The layer's
-- `Covered` attribute says so for a button that is not in the layer (the admin
-- console's, DisplayOrder 60, hides itself while it is true).
--==============================================================================
local RAIL_COVERED_ORDER = 29
local railCover: { [string]: boolean } = {}

function UIKit.coverRail(playerGui: Instance, owner: string, on: boolean)
	railCover[owner] = if on then true else nil
	local layer = UIKit.railLayer(playerGui)
	local covered = next(railCover) ~= nil
	layer.DisplayOrder = if covered then RAIL_COVERED_ORDER else 40
	if layer:GetAttribute("Covered") ~= covered then
		layer:SetAttribute("Covered", covered)
	end
end

--==============================================================================
-- THE UPLOADED ICON
--
-- An ImageLabel, and deliberately NOT a button. The slab underneath is still the
-- only thing a player clicks; an ImageLabel does not consume input, and Active
-- is set false as well so that stays true if it ever becomes something that
-- could.
--
-- ScaleType.Fit, because the art is square and the band it sits in is not always
-- -- Fit letterboxes and keeps the aspect, Stretch would fatten the satchel on a
-- wide button.
--
-- WHERE IT SITS IS READ OFF THE BUTTON, not passed in. A wide button carries a
-- word, so its icon is inset at the left exactly where iconBox put the drawn one;
-- a square button has nothing else in it, so its icon is centred exactly where
-- sproutIcon put that one. Deciding it here is what stops four call sites each
-- remembering a different pair of numbers.
--==============================================================================
function UIKit.railIcon(button: GuiObject, asset: string, size: number): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Image = asset
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Active = false
	icon.ZIndex = 3
	icon.Size = UDim2.fromOffset(size, size)

	-- Off the authored Size rather than AbsoluteSize, which is still 0 here: the
	-- button has not been laid out at the moment this runs.
	if button.Size.X.Offset > button.Size.Y.Offset then
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 10, 0.5, 0)
	else
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
	end

	icon.Parent = button
	return icon
end

--==============================================================================
-- THE HOVER POP
--
-- Up to 1.08, settle back to 1.04, hold there while the pointer is on it, and
-- ease to 1.00 when it leaves. One shot -- it never loops and never pulses,
-- because a button that keeps moving in the corner of the eye is a button you
-- learn to ignore.
--
-- UIScale, so nothing around it moves. Scaling Size would push the button out of
-- its corner and shove the one below it down the rail.
--
-- NOT ON TOUCH. A phone has no pointer, and Roblox still fires MouseEnter off a
-- tap on some devices -- which would make every press grow the button and leave
-- it grown, because no MouseLeave follows. Gated on the mouse being real AND on
-- the last input actually having come from it.
--
-- ONE UIScale, ONE PAIR OF CONNECTIONS. Wired inside railButton below, which
-- destroys any previous button of the same name first, so a script that re-runs
-- cannot end up with two of either.
--==============================================================================
local HOVER_UP, HOVER_HOLD = 1.08, 1.04
local HOVER_RISE, HOVER_SETTLE, HOVER_FALL = 0.09, 0.09, 0.12

local function pointerIsMouse(): boolean
	if not UserInputService.MouseEnabled then
		return false
	end
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.MouseMovement
		or last == Enum.UserInputType.MouseButton1
		or last == Enum.UserInputType.MouseButton2
		or last == Enum.UserInputType.MouseButton3
		or last == Enum.UserInputType.MouseWheel
end

--==============================================================================
-- The same attribute SpeedFX and PlantAura already read, rather than a second
-- control a player would have to find. Off means no motion; Reduced is left
-- alone, because it is the TOUCH default and touch never pops anyway.
--==============================================================================
local function motionOff(): boolean
	local player = Players.LocalPlayer
	return player ~= nil and player:GetAttribute("SeedAfterimageQuality") == "Off"
end

local function hoverPop(button: GuiObject)
	local scale = button:FindFirstChildWhichIsA("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = button
	end

	-- `token` is what makes rapid enter/leave safe. Every gesture takes a new
	-- one; a tween that finishes after a newer gesture started sees a token that
	-- is not its own and does not queue the settle.
	local token = 0
	local running: Tween? = nil

	local function play(goal: number, seconds: number, dir: Enum.EasingDirection): Tween
		if running then
			-- Cancelled rather than left to finish, so two tweens can never be
			-- writing Scale on the same frame.
			running:Cancel()
		end
		local tween = TweenService:Create(scale,
			TweenInfo.new(seconds, Enum.EasingStyle.Quad, dir), { Scale = goal })
		running = tween
		tween:Play()
		return tween
	end

	button.MouseEnter:Connect(function()
		if not pointerIsMouse() or motionOff() then
			return
		end
		token += 1
		local mine = token
		local rise = play(HOVER_UP, HOVER_RISE, Enum.EasingDirection.Out)
		rise.Completed:Once(function(state: Enum.PlaybackState)
			-- Cancel fires this too. Only a run that finished on its own, and is
			-- still the current gesture, earns the settle.
			if state == Enum.PlaybackState.Completed and token == mine then
				play(HOVER_HOLD, HOVER_SETTLE, Enum.EasingDirection.InOut)
			end
		end)
	end)

	button.MouseLeave:Connect(function()
		token += 1
		-- No guard: leaving must return to rest even if the pop never ran, or a
		-- button entered by touch and left by mouse could stay large.
		play(1, HOVER_FALL, Enum.EasingDirection.Out)
	end)
end

--==============================================================================
-- THE CARD POP: A LIFT UNDER A MOUSE, A PRESS UNDER A THUMB
--
-- `popOnHover` grows a card on touch as well, which is right for the Index and
-- wrong for a grid a thumb is pressing: a press that grows reads as the card
-- jumping at the finger. This one lifts under a real mouse and sinks under a
-- touch, and the two never run at once -- the press wins while it is held.
--
-- UIScale on an element the caller owns, never on a layout-controlled cell, so a
-- grid never sees a size change and nothing beside the card moves.
--
-- ONE TWEEN PER PROPERTY. Every change cancels the tween it replaces before
-- starting the next, so a fast pass across a grid cannot leave two tweens
-- writing Scale on the same frame. Nothing loops and nothing runs per frame.
--
-- `SeedAfterimageQuality = "Off"` keeps the scale at rest; the glow still
-- answers, because a brighter edge is not motion.
--
-- A touch that turns into a scroll releases the press as soon as it moves, so
-- a card a thumb dragged past does not stay sunk. `reset` puts everything back
-- at once, for a pooled card that is hidden while the pointer is still on it.
--==============================================================================
export type CardPopOptions = {
	hoverScale: number?,
	pressScale: number?,
	seconds: number?,
	glow: UIStroke?,
	glowRest: number?,
	glowHover: number?,
	sound: boolean?,
	-- Pixels the target rises under a hovering mouse, on top of the scale. The
	-- target's Position is tweened from where it stood when the pop was made,
	-- so it must be an element whose parent is NOT a layout -- the hotbar lifts
	-- the plate inside its cell, and the cell never moves. nil lifts nothing.
	lift: number?,
	-- Asked on every change (2026-10-04): false holds the target at rest -- a
	-- disabled button neither grows under the mouse nor sinks under a press.
	active: (() -> boolean)?,
}

export type CardPop = {
	reset: () -> (),
	destroy: () -> (),
}

local PRESS_SLOP = 10

function UIKit.cardPop(target: GuiObject, scale: UIScale, options: CardPopOptions?): CardPop
	local opts: CardPopOptions = options or {}
	local hoverScale = opts.hoverScale or 1.05
	local pressScale = opts.pressScale or 0.98
	local seconds = opts.seconds or 0.12
	local glow = opts.glow
	local glowRest = opts.glowRest or (if glow then glow.Transparency else 1)
	local glowHover = opts.glowHover or 0.35
	local sound = opts.sound ~= false

	local hovered, pressed = false, false
	local pressedAt: Vector3? = nil
	local scaleTween: Tween? = nil
	local glowTween: Tween? = nil
	local liftTween: Tween? = nil
	local lift = opts.lift
	local restPosition = target.Position
	local conns: { RBXScriptConnection } = {}

	local isActive = opts.active
	local function apply(instant: boolean?)
		local live = isActive == nil or isActive()
		local goal = if motionOff() or not live then 1
			elseif pressed then pressScale
			elseif hovered then hoverScale
			else 1
		if scaleTween then
			scaleTween:Cancel()
			scaleTween = nil
		end
		if instant then
			scale.Scale = goal
		elseif scale.Scale ~= goal then
			local tween = TweenService:Create(scale, TweenInfo.new(
				if pressed then seconds * 0.6 else seconds,
				Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = goal })
			scaleTween = tween
			tween:Play()
		end
		-- The lift is motion too, so reduced effects keep it at rest, and a
		-- press sinks rather than rises.
		if lift then
			local rise = if hovered and not pressed and not motionOff() and live then lift else 0
			local want = restPosition + UDim2.fromOffset(0, -rise)
			if liftTween then
				liftTween:Cancel()
				liftTween = nil
			end
			if instant then
				target.Position = want
			elseif target.Position ~= want then
				local tween = TweenService:Create(target, TweenInfo.new(seconds,
					Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = want })
				liftTween = tween
				tween:Play()
			end
		end
		if glow then
			local want = if (hovered or pressed) and live then glowHover else glowRest
			if glowTween then
				glowTween:Cancel()
				glowTween = nil
			end
			if instant then
				glow.Transparency = want
			elseif glow.Transparency ~= want then
				local tween = TweenService:Create(glow, TweenInfo.new(seconds,
					Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = want })
				glowTween = tween
				tween:Play()
			end
		end
	end

	table.insert(conns, target.MouseEnter:Connect(function()
		if hovered or not pointerIsMouse() then
			return
		end
		hovered = true
		if sound then
			SoundKit.play("CardHover")
		end
		apply()
	end))
	table.insert(conns, target.MouseLeave:Connect(function()
		-- A mouse press (no pressedAt) released off the target never ends on it.
		local mousePress = pressed and pressedAt == nil
		if hovered or mousePress then
			hovered = false
			if mousePress then
				pressed = false
			end
			apply()
		end
	end))
	table.insert(conns, target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch and not pressed then
			pressed = true
			pressedAt = input.Position
			apply()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not pressed then
			-- A mouse press sinks too (2026-10-04): a brief, separate pressed state.
			pressed = true
			pressedAt = nil
			apply()
		end
	end))
	table.insert(conns, target.InputChanged:Connect(function(input: InputObject)
		if pressed and input.UserInputType == Enum.UserInputType.Touch and pressedAt
			and (input.Position - (pressedAt :: Vector3)).Magnitude > PRESS_SLOP then
			pressed = false
			pressedAt = nil
			apply()
		end
	end))
	table.insert(conns, target.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if (kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1) and pressed then
			pressed = false
			pressedAt = nil
			apply()
		end
	end))

	local function reset()
		hovered, pressed, pressedAt = false, false, nil
		apply(true)
	end

	local function destroy()
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		table.clear(conns)
		if scaleTween then
			scaleTween:Cancel()
			scaleTween = nil
		end
		if glowTween then
			glowTween:Cancel()
			glowTween = nil
		end
		if liftTween then
			liftTween:Cancel()
			liftTween = nil
		end
	end
	table.insert(conns, target.Destroying:Connect(destroy))

	return { reset = reset, destroy = destroy }
end

--==============================================================================
-- THE SHOP'S RAINBOW RIM
--
-- The owner's reference clip: a narrow band of rainbow inside the thick black
-- outline, red, yellow, green, cyan, blue and purple ACROSS the button at once,
-- and the whole spread turning -- measured at one turn every 4 s. Each point on
-- the band swings red -> purple -> red and the two sides move in opposite
-- phase, which is exactly a rainbow UIGradient being rotated.
--
-- NOT A SECOND FRAME ON TOP. The Shop's picture was re-exported with its static
-- rim band CUT OUT (art/ui/rail-buttons/shop-base.svg), so this is a plain
-- rounded frame BEHIND the picture: the black outline and the face cover it
-- everywhere but the band, and the cart and the word, which cross the band, sit
-- on top of it exactly as they sat on the old rim. Nothing flashes and nothing
-- else moves; no glow, no halo -- the colours are bright enough on the black.
--
-- ONE NUMBER A FRAME, AND ONLY WHILE IT CAN BE SEEN. The spin writes Rotation
-- off the clock on one RenderStepped connection -- nothing allocated -- made
-- while the button is on screen (its gui enabled, every frame up the chain
-- visible, not slid off the edge, which is how the phone's dock shuts) and
-- dropped the moment it is not. `SeedAfterimageQuality = "Off"` holds it still,
-- colours and all, as it does the hover pop. Destroying the box (a re-run's
-- railButton destroys the old button) drops every connection, so a re-run never
-- leaves a second loop behind.
--==============================================================================
function UIKit.rainbowRim(box: GuiObject): Frame
	local RIM = RAIL.Rim
	local rim = Instance.new("Frame")
	rim.Name = "Rim"
	rim.Position = UDim2.fromScale(RIM.X / RIM.Art, RIM.Y / RIM.Art)
	rim.Size = UDim2.fromScale(RIM.W / RIM.Art, RIM.H / RIM.Art)
	rim.BackgroundColor3 = WHITE
	rim.BorderSizePixel = 0
	rim.Active = false
	rim.ZIndex = 3
	rim.Parent = box
	-- A corner's scale is of the frame's shorter side.
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(RIM.Radius / math.min(RIM.W, RIM.H), 0)
	corner.Parent = rim

	local keys = {}
	local count = #RIM.Colours
	for i, colour in ipairs(RIM.Colours) do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (count - 1), colour))
	end
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(keys)
	gradient.Parent = rim

	local spin: RBXScriptConnection? = nil
	local watch: { RBXScriptConnection } = {}
	local player = Players.LocalPlayer

	local function step()
		gradient.Rotation = (os.clock() * RIM.Speed) % 360
	end

	local function onScreen(): boolean
		local gui = box:FindFirstAncestorWhichIsA("LayerCollector")
		if not (gui and gui.Enabled) then
			return false
		end
		local node: Instance? = box
		while node and node ~= gui do
			if node:IsA("GuiObject") and not node.Visible then
				return false
			end
			node = node.Parent
		end
		local at, size, screen = box.AbsolutePosition, box.AbsoluteSize, gui.AbsoluteSize
		return size.X > 0 and at.X + size.X > 0 and at.Y + size.Y > 0
			and at.X < screen.X and at.Y < screen.Y
	end

	local function refresh()
		local run = onScreen() and not motionOff()
		if run and not spin then
			spin = RunService.RenderStepped:Connect(step)
		elseif not run and spin then
			spin:Disconnect()
			spin = nil
		end
	end

	-- Every frame up to the gui, rebuilt only when the button moves between the
	-- rail and the phone's dock.
	local function rewatch()
		for _, connection in ipairs(watch) do
			connection:Disconnect()
		end
		table.clear(watch)
		local node: Instance? = box
		while node do
			if node:IsA("GuiObject") then
				table.insert(watch, node:GetPropertyChangedSignal("Visible"):Connect(refresh))
			elseif node:IsA("LayerCollector") then
				table.insert(watch, node:GetPropertyChangedSignal("Enabled"):Connect(refresh))
				break
			end
			node = node.Parent
		end
		refresh()
	end

	box:GetPropertyChangedSignal("AbsolutePosition"):Connect(refresh)
	box:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
	box.AncestryChanged:Connect(rewatch)
	local setting = if player
		then player:GetAttributeChangedSignal("SeedAfterimageQuality"):Connect(refresh)
		else nil
	box.Destroying:Connect(function()
		if spin then
			spin:Disconnect()
			spin = nil
		end
		for _, connection in ipairs(watch) do
			connection:Disconnect()
		end
		table.clear(watch)
		if setting then
			setting:Disconnect()
		end
	end)
	step()
	rewatch()
	return rim
end

--==============================================================================
-- A WORD UNDER THE PICTURE UNTIL IT LOADS (2026-10-09, the owner: "some
-- buttons are invisible like the garden and inventory")
--
-- A bare or art button is a transparent square with a picture in it, so a
-- picture that did not load here -- a fetch that fails, a CDN hiccup, an
-- upload held in moderation -- left nothing to see or to find: Garden and the
-- Bag were gone. Such a button now stands its plain word on a slate plate
-- UNDER its pictures (GameConfig.Rail.Words), hidden once one of them has
-- loaded HERE and is shown -- its own (a bare button's Icon, an art button's
-- Art) or a railPicture over it -- and kept for good if none ever does. Not
-- Active, so the press is still the button's; under the badge.
--
-- LOADED IS WRITTEN DOWN WHEN IT IS ANSWERED. UIKit.whenPictureLoads answers
-- it; the picture keeps the id that loaded (RailLoaded) and is asked about
-- once per id (RailWatching), so a relayout never piles up watches and a
-- picture given a new id is asked about again.
--==============================================================================
local FALLBACK_NAME = "WordFallback"
local LOADED_ATTR = "RailLoaded"
local WATCH_ATTR = "RailWatching"

--==============================================================================
-- ASKED A MOMENT AFTER THE ID IS SET
--
-- Right after an ImageLabel's id changes, IsLoaded still answers for the
-- picture it had: measured in Play 2026-10-09, the live Garden icon switched
-- to an id that never loads read IsLoaded true at once and false 0.6 s later
-- -- so asking at once took a failed picture for a loaded one and hid the
-- word over nothing. The first question waits this long; a spec sets it to 0.
--==============================================================================
UIKit.PictureSettleSeconds = 0.3

local function pictureLoaded(picture: ImageLabel): boolean
	return picture.Image ~= "" and picture:GetAttribute(LOADED_ATTR) == picture.Image
end

local function watchPicture(picture: ImageLabel, onLoaded: () -> ())
	local image = picture.Image
	if image == "" or pictureLoaded(picture) or picture:GetAttribute(WATCH_ATTR) == image then
		return
	end
	picture:SetAttribute(WATCH_ATTR, image)
	local function ask()
		-- Given another id meanwhile: that one's own watch asks.
		if picture.Image ~= image then
			return
		end
		UIKit.whenPictureLoads(picture, function(loaded: boolean)
			if loaded and picture.Image == image then
				picture:SetAttribute(LOADED_ATTR, image)
				onLoaded()
			end
		end)
	end
	local settle = UIKit.PictureSettleSeconds
	if settle > 0 then
		task.delay(settle, ask)
	else
		ask()
	end
end

-- A picture of the button's that draws over its word: loaded, and shown with
-- the box it stands in (if any).
local function coversWord(picture: Instance?, box: Instance?): boolean
	if not (picture and picture:IsA("ImageLabel")) then
		return false
	end
	if box and box:IsA("GuiObject") and not box.Visible then
		return false
	end
	return picture.Visible and pictureLoaded(picture)
end

local function refreshFallback(button: GuiObject)
	local plate = button:FindFirstChild(FALLBACK_NAME)
	if not (plate and plate:IsA("GuiObject")) then
		return
	end
	local artBox = button:FindFirstChild("ArtBox")
	local art = if artBox then artBox:FindFirstChild("Art") else nil
	local pictureBox = button:FindFirstChild("PictureBox")
	plate.Visible = not (coversWord(button:FindFirstChild("Icon"), nil)
		or coversWord(art, artBox)
		or coversWord(if pictureBox then pictureBox:FindFirstChild("Picture") else nil, pictureBox))
	-- The Shop's rim turns behind its picture's cut band; with no picture it is a
	-- rainbow square over the word (seen in Edit), so it waits for the picture.
	local rim = if artBox then artBox:FindFirstChild("Rim") else nil
	if rim and rim:IsA("GuiObject") and art and art:IsA("ImageLabel") then
		rim.Visible = pictureLoaded(art)
	end
end

-- The plate and its word, under a bare or art button's pictures. railButton
-- calls it for `fallback`; found rather than rebuilt if called again.
function UIKit.railFallback(button: GuiObject, word: string): Frame
	local plate = button:FindFirstChild(FALLBACK_NAME)
	if not (plate and plate:IsA("Frame")) then
		local made = Instance.new("Frame")
		made.Name = FALLBACK_NAME
		made.Size = UDim2.fromScale(1, 1)
		made.BackgroundColor3 = WHITE
		made.BorderSizePixel = 0
		made.Active = false
		made.ZIndex = 1
		made.Parent = button
		UIKit.corner(made, RAIL.Radius)
		UIKit.stroke(made, RAIL.Outline, RAIL.FallbackOutline)
		UIKit.gradient(made, RAIL.TileTop, RAIL.TileBottom)
		local label = UIKit.outlined(made, "Word", RAIL.FallbackTextMax, WHITE, 1.5)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.new(1, -6, 0.6, 0)
		label.TextScaled = true
		label.Active = false
		label.ZIndex = 1
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = RAIL.FallbackTextMax
		fit.MinTextSize = RAIL.FallbackTextMin
		fit.Parent = label
		-- The button's own picture: a bare button's Icon, an art button's Art.
		local artBox = button:FindFirstChild("ArtBox")
		local own = button:FindFirstChild("Icon") or (if artBox then artBox:FindFirstChild("Art") else nil)
		if own and own:IsA("ImageLabel") then
			local function refresh()
				refreshFallback(button)
			end
			watchPicture(own, refresh)
			-- An id swapped later is asked about again.
			own:GetPropertyChangedSignal("Image"):Connect(function()
				watchPicture(own, refresh)
				refresh()
			end)
		end
		plate = made
	end
	local frame = plate :: Frame
	local label = frame:FindFirstChild("Word")
	if label and label:IsA("TextLabel") then
		label.Text = word
	end
	refreshFallback(button)
	return frame
end

function UIKit.railButton(playerGui: Instance, options: RailOptions): ImageButton
	local wide = options.wide ~= false
	local size = if wide then RAIL.WideSize else RAIL.SquareSize

	local layer = UIKit.railLayer(playerGui)
	-- Recursive: on a phone the previous button may be standing in the dock.
	local previous = layer:FindFirstChild(options.name, true)
	if previous then
		previous:Destroy()
	end

	--==========================================================================
	-- THREE KINDS OF BUTTON, ONE BUILDER
	--
	-- A SLAB is the original: a coloured face, a gradient, a lattice, a rounded
	-- corner and a black outline, with the icon riding on it and a word beside
	-- it.
	--
	-- A BARE button has none of that. The artwork is the button -- no background,
	-- not inside a square -- so it is a transparent ImageButton and the icon
	-- fills the whole footprint. Garden and the Bag are these.
	--
	-- An ART button is bare too, but its picture is a WHOLE button -- outline,
	-- face, icon and word in one square image -- so nothing of ours is drawn with
	-- it: no icon, no label, no plate. Index and Shop are these (2026-09-24).
	--
	-- SAME FOOTPRINT EVERY WAY. 130x50 and 50x50 as they have always been, so
	-- the buttons sit where they were and a bare button's touch target is no
	-- smaller than the plate it replaced. An icon is already easier to miss than
	-- a slab; shrinking the target with it would be two regressions for one
	-- change.
	--
	-- UIKit.slab carries its own UIKit.clicks, so only the bare branch has to ask
	-- for the click cue.
	--==========================================================================
	local button: ImageButton
	if options.bare or options.art then
		button = Instance.new("ImageButton")
		button.Size = UDim2.fromOffset(size.X, size.Y)
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Parent = layer
		UIKit.clicks(button)
	else
		button = UIKit.slab(layer, {
			size = UDim2.fromOffset(size.X, size.Y),
			face = options.face,
			shade = options.shade,
			radius = RAIL.Radius,
			latticeSpacing = 18,
			latticeSize = size,
		})
	end
	button.Name = options.name

	if options.art then
		--======================================================================
		-- THE PICTURE, IN A SQUARE THAT STAYS SQUARE
		--
		-- The layout hands this button a 50 x 50 square nearly everywhere, but a
		-- short phone's dock gives its tiles 44 of height. The box is the largest
		-- square that fits, centred, so the artwork is never stretched; the rim,
		-- when there is one, is placed in the same box so it always meets the
		-- picture's band exactly. Neither takes input: the button does.
		--======================================================================
		local box = Instance.new("Frame")
		box.Name = "ArtBox"
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromScale(1, 1)
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.Active = false
		box.ZIndex = 2
		box.Parent = button
		local square = Instance.new("UIAspectRatioConstraint")
		square.AspectRatio = 1
		square.Parent = box

		local art = Instance.new("ImageLabel")
		art.Name = "Art"
		art.Size = UDim2.fromScale(1, 1)
		art.BackgroundTransparency = 1
		art.BorderSizePixel = 0
		art.Image = options.art
		art.ScaleType = Enum.ScaleType.Fit
		art.Active = false
		art.ZIndex = 4
		art.Parent = box

		if options.rim then
			UIKit.rainbowRim(box)
		end
		if options.fallback then
			UIKit.railFallback(button, options.fallback)
		end

		hoverPop(button)
		return button
	end

	local iconSize = if options.bare then RAIL.IconBare else RAIL.IconSize
	if options.icon then
		UIKit.railIcon(button, options.icon, iconSize)
	end
	if options.bare and options.fallback then
		UIKit.railFallback(button, options.fallback)
	end

	if options.label then
		--======================================================================
		-- The word keeps its own outline, which is now the only thing keeping it
		-- readable -- there is no plate behind it. That is the same bet CashUI
		-- makes with the cash and speed numbers, and for the same reason: a
		-- 2.5px black stroke reads on grass, dirt and sky without a panel.
		--======================================================================
		local label = UIKit.outlined(button, "Label", RAIL.LabelSize, WHITE, 2.5)
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.new(1, -10, 0.5, 1)
		label.Size = UDim2.new(1, -(iconSize + 24), 0, RAIL.LabelSize + 6)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = options.label
		label.ZIndex = 3
	end

	--==========================================================================
	-- Every rail button gets the pop, from here rather than from four call
	-- sites. One place to wire it is one place it can be wired twice.
	--==========================================================================
	hoverPop(button)

	return button
end

--==============================================================================
-- A FACE WITH ITS FOOT (2026-10-04, the global UI pass)
--
-- The lit face top to bottom, then a darker foot -- the bottom FootShare -- in
-- ONE gradient, so rounded corners stay exact and no extra frame stands at the
-- edge. Every button of the family is drawn with it (MenuKit.faceColours is
-- this, by another name).
--==============================================================================
function UIKit.footColours(top: Color3, bottom: Color3, edge: Color3): ColorSequence
	local foot = bottom:Lerp(edge, 0.38)
	local cut = 1 - GameConfig.BagLook.FootShare
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(cut - 0.02, bottom),
		ColorSequenceKeypoint.new(cut, foot),
		ColorSequenceKeypoint.new(1, foot),
	})
end

--==============================================================================
-- A STUDDED CARD (2026-10-04, the owner's six colourful uploads; BagLook.Studs)
--
-- Behind a card's content: a solid fallback in the upload's own colours, and
-- over it the picture -- which draws nothing until it has loaded, so the
-- fallback is what shows until then, or for good if it never loads.
--
-- CROPPED, NEVER STRETCHED OR TILED. The picture's ImageRect is a window with
-- the card's own aspect, `pitch` / StudCardPitch picture px per gui px (one
-- stud size on every card, whatever the upload's own spacing), clamped to the
-- picture and centred; a `wide` one (the rainbow) shows its whole width.
-- Worked out in the card's own gui units -- its size undone of every UIScale
-- over it -- so a hover pop, a panel opening or the menu size scales the studs
-- WITH the card rather than sliding them.
--
-- Under the content (`z`, the face's own) and never interactive. `set(nil)`
-- hides both, and the card's own plain face shows. Answers the spec in use.
--==============================================================================
export type StudCard = {
	set: (key: string?) -> any,
	image: ImageLabel,
	fallback: Frame,
}

local function unscaledSize(object: GuiObject): Vector2
	local k = 1
	local node: Instance? = object
	while node do
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("UIScale") then
				k *= child.Scale
			end
		end
		if node:IsA("LayerCollector") then
			break
		end
		node = node.Parent
	end
	return object.AbsoluteSize / math.max(k, 1e-3)
end

function UIKit.studCard(face: GuiObject, radius: number, z: number): StudCard
	local LOOK = GameConfig.BagLook
	local specs: { [string]: any } = LOOK.Studs :: any
	local fallback = Instance.new("Frame")
	fallback.Name = "StudsFallback"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundColor3 = WHITE
	fallback.BorderSizePixel = 0
	fallback.Active = false
	fallback.Visible = false
	fallback.ZIndex = z
	fallback.Parent = face
	UIKit.corner(fallback, radius)
	local shade = Instance.new("UIGradient")
	shade.Parent = fallback

	local image = Instance.new("ImageLabel")
	image.Name = "Studs"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Active = false
	image.Visible = false
	image.ScaleType = Enum.ScaleType.Stretch
	image.ZIndex = z
	image.Parent = face
	UIKit.corner(image, radius)

	local current: string? = nil
	local function window()
		local spec = if current then specs[current] else nil
		if not spec then
			return
		end
		local size = unscaledSize(face)
		if size.X < 1 or size.Y < 1 then
			return
		end
		local source = LOOK.StudSource
		local k = if spec.wide then source / size.X else spec.pitch / LOOK.StudCardPitch
		k = math.min(k, source / size.X, source / size.Y)
		local w, h = math.floor(size.X * k), math.floor(size.Y * k)
		local rect = Vector2.new(w, h)
		if image.ImageRectSize ~= rect then
			image.ImageRectSize = rect
			image.ImageRectOffset = Vector2.new(math.floor((source - w) / 2), math.floor((source - h) / 2))
		end
	end
	face:GetPropertyChangedSignal("AbsoluteSize"):Connect(window)

	local function set(key: string?): any
		local spec = if key then specs[key] else nil
		current = if spec then key else nil
		fallback.Visible = spec ~= nil
		image.Visible = spec ~= nil
		if not spec then
			return nil
		end
		local stops = spec.stops
		if stops then
			local points = {}
			for i, c in ipairs(stops) do
				table.insert(points, ColorSequenceKeypoint.new((i - 1) / (#stops - 1), c))
			end
			shade.Color = ColorSequence.new(points)
			shade.Rotation = 0
		else
			shade.Color = ColorSequence.new(spec.top, spec.bottom)
			shade.Rotation = 90
		end
		-- Not loaded yet, it draws nothing and the fallback under it shows; no
		-- watch is needed (a closed panel's picture may only load once shown).
		if image.Image ~= spec.image then
			image.Image = spec.image
		end
		window()
		return spec
	end

	return { set = set, image = image, fallback = fallback }
end

--==============================================================================
-- THE HUD'S PLATE BUTTON (2026-10-04, the global UI pass)
--
-- TELEPORT TO PLOT, OBBY, BIOMES and the obby's RETURN TO PLOT were the same
-- plate written four times -- and each one's thick black outline never drew:
-- a UIStroke on a TextLabel with no text strokes the (empty) TEXT. One builder
-- now: a Frame plate with the outline on its BORDER, the family's darker foot
-- in its gradient, the thin inner rim, an icon (an uploaded picture, or an
-- empty box the caller draws into) and the outlined word. The caller keeps
-- its button (the touch area), its colours and where it stands.
--==============================================================================
export type HudPlateOptions = {
	top: Color3,
	bottom: Color3,
	rim: Color3,
	image: string?,
	text: string,
	textSize: number?,
}

export type HudPlate = {
	plate: Frame,
	scale: UIScale,
	rim: Frame,
	icon: GuiObject,
	label: TextLabel,
	gradient: UIGradient,
}

function UIKit.hudPlate(button: GuiObject, o: HudPlateOptions): HudPlate
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.fromScale(1, 1)
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.Parent = button
	UIKit.corner(plate, 12)
	local edge = UIKit.stroke(plate, BLACK, 2.5)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradient = UIKit.gradient(plate, o.top, o.bottom)
	gradient.Color = UIKit.footColours(o.top, o.bottom, BLACK)
	local scale = Instance.new("UIScale")
	scale.Parent = plate

	local rim = Instance.new("Frame")
	rim.Name = "Rim"
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.fromScale(0.5, 0.5)
	rim.Size = UDim2.new(1, -5, 1, -5)
	rim.BackgroundTransparency = 1
	rim.BorderSizePixel = 0
	rim.Active = false
	rim.Parent = plate
	UIKit.corner(rim, 10)
	UIKit.stroke(rim, o.rim, 1.5, 0.2)

	local icon: GuiObject
	if o.image and o.image ~= "" then
		local picture = Instance.new("ImageLabel")
		picture.Image = o.image
		picture.ScaleType = Enum.ScaleType.Fit
		icon = picture
	else
		icon = Instance.new("Frame")
	end
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.Size = UDim2.fromOffset(28, 28)
	icon.BackgroundTransparency = 1
	icon.Active = false
	icon.Parent = plate

	local size = o.textSize or 16
	local label = UIKit.outlined(plate, "Label", size, WHITE, 2)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 42, 0.5, 1)
	label.Size = UDim2.new(1, -50, 0, 22)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Text = o.text
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = size
	fit.MinTextSize = 10
	fit.Parent = label
	return { plate = plate, scale = scale, rim = rim, icon = icon, label = label, gradient = gradient }
end

--==============================================================================
-- THE FAMILY'S PRESS, FOR ANY BUTTON (2026-10-04, the global UI pass)
--
-- A small grow under the mouse and a sink under a press or a touch, through a
-- UIScale on the target itself (cardPop) -- the one response every HUD button
-- and menu control shares; still under reduced motion. Answers the pop.
--==============================================================================
function UIKit.pressPop(target: GuiObject, hover: number?, press: number?): CardPop
	local scale = target:FindFirstChild("PressPop")
	if not (scale and scale:IsA("UIScale")) then
		local made = Instance.new("UIScale")
		made.Name = "PressPop"
		made.Parent = target
		scale = made
	end
	return UIKit.cardPop(target, scale :: UIScale, { hoverScale = hover or 1.05, pressScale = press or 0.95,
		sound = false })
end

--==============================================================================
-- ONE RAIL BUTTON, TWO SHAPES
--
-- HudLayout decides which and where; the owner applies it, through this. A wide
-- button carries its word and keeps its icon at the left, where railIcon put
-- it. A square one -- every button in the compact top row -- drops the word and
-- centres the icon. Nothing is rebuilt: the slab's lattice follows its own
-- size, and the badge, the hover pop and the click are the same instances in
-- both shapes, so a relayout cannot duplicate any of them.
--
-- `iconSize` is for the bare Settings gear, which fills its button on the
-- desktop and sits on a plate in compact.
--
-- A THIRD SHAPE ON A PHONE: THE DOCK'S TILE. `tile` puts a plate of its own
-- colours over the button's face -- slate for Index and Settings, emerald for
-- the Shop -- the icon at its top and the word under it. The plate and the
-- word are children made the first time and only hidden after, so a slab keeps
-- its face, lattice and outline untouched underneath, and a screen that stops
-- being touch gets back exactly the button it had.
--==============================================================================
export type RailTile = {
	-- The word under the icon.
	label: string,
	-- The plate, top to bottom, and its thin edge.
	top: Color3,
	bottom: Color3,
	edge: Color3,
}

function UIKit.railShape(button: GuiObject, size: Vector2, iconSize: number?, tile: RailTile?)
	button.Size = UDim2.fromOffset(size.X, size.Y)
	local plate = button:FindFirstChild("Tile")
	local word = button:FindFirstChild("TileLabel")
	-- An art button's picture is its own tile: never a plate or a word over it.
	if tile and not button:FindFirstChild("ArtBox") then
		local DOCK = HudLayout.Config.Dock
		if not (plate and plate:IsA("Frame")) then
			local made = Instance.new("Frame")
			made.Name = "Tile"
			made.Size = UDim2.fromScale(1, 1)
			made.BorderSizePixel = 0
			made.Active = false
			made.ZIndex = 2
			made.Parent = button
			UIKit.corner(made, RAIL.Radius)
			UIKit.stroke(made, tile.edge, 1.5)
			UIKit.gradient(made, tile.top, tile.bottom)
			plate = made
		end
		if not (word and word:IsA("TextLabel")) then
			local made = UIKit.outlined(button, "TileLabel", DOCK.Label, WHITE, 1.5)
			made.Font = Enum.Font.FredokaOne
			made.AnchorPoint = Vector2.new(0.5, 1)
			made.Position = UDim2.new(0.5, 0, 1, -3)
			made.Size = UDim2.new(1, -4, 0, DOCK.Label + 2)
			made.TextScaled = true
			made.ZIndex = 3
			local fit = Instance.new("UITextSizeConstraint")
			fit.MaxTextSize = DOCK.Label
			fit.MinTextSize = 7
			fit.Parent = made
			word = made
		end
		local tilePlate = plate :: Frame
		local tileWord = word :: TextLabel
		tilePlate.Visible = true
		local stroke = tilePlate:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = tile.edge
		end
		local tint = tilePlate:FindFirstChildOfClass("UIGradient")
		if tint then
			tint.Color = ColorSequence.new(tile.top, tile.bottom)
		end
		tileWord.Text = tile.label
		tileWord.Visible = true
		local tileIcon = button:FindFirstChild("Icon")
		if tileIcon and tileIcon:IsA("GuiObject") then
			-- Remembered once, so the icon goes back to its own size after.
			if button:GetAttribute("RailIconSize") == nil then
				button:SetAttribute("RailIconSize", tileIcon.Size.X.Offset)
			end
			local side = math.min(DOCK.Icon, size.Y - DOCK.Label - 12)
			tileIcon.AnchorPoint = Vector2.new(0.5, 0)
			tileIcon.Position = UDim2.new(0.5, 0, 0, 4)
			tileIcon.Size = UDim2.fromOffset(side, side)
		end
		local own = button:FindFirstChild("Label")
		if own and own:IsA("GuiObject") then
			own.Visible = false
		end
		return
	end
	if plate and plate:IsA("GuiObject") then
		plate.Visible = false
	end
	if word and word:IsA("GuiObject") then
		word.Visible = false
	end
	local wide = size.X > size.Y
	local icon = button:FindFirstChild("Icon")
	if icon and icon:IsA("GuiObject") then
		if wide then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 10, 0.5, 0)
		else
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
		end
		local rest = iconSize or tonumber(button:GetAttribute("RailIconSize"))
		if rest then
			icon.Size = UDim2.fromOffset(rest, rest)
		end
	end
	local label = button:FindFirstChild("Label")
	if label and label:IsA("GuiObject") then
		label.Visible = wide
	end
end

--==============================================================================
-- A WHOLE-BUTTON PICTURE (2026-10-05, the owner's studded Shop, Index and
-- Settings on a phone)
--
-- The picture IS the button -- outline, studded face, icon and word -- so while
-- it shows nothing of ours is drawn with it: the art box, the icon, the tile
-- and every word a rail button can carry are hidden, and the picture stands in
-- a box of its own `aspect`, centred and as large as fits, never stretched. It
-- draws under the badge (6) and is not Active: the press is still the
-- button's. `image` nil puts the button back as railShape left it -- the
-- picture hidden, the art box and the icon shown -- so call it after railShape.
--
-- ONLY ONCE IT HAS LOADED HERE (2026-10-09, the owner: "some buttons are
-- invisible like the garden and inventory"). Hiding everything of ours the
-- moment an id was set left a button whose picture never loaded with nothing
-- on it at all. Until the picture has loaded (UIKit.whenPictureLoads, written
-- down by watchPicture) the button keeps what railShape and its owner drew,
-- and its word if it has one, with the picture over them drawing nothing yet
-- -- never hidden, because a hidden picture is never loaded. Never loaded,
-- they stay.
--==============================================================================
local PICTURE_Z = 5

function UIKit.railPicture(button: GuiObject, image: string?, aspect: number?)
	local box = button:FindFirstChild("PictureBox")
	if not image then
		if box and box:IsA("GuiObject") then
			box.Visible = false
		end
		for _, name in ipairs({ "ArtBox", "Icon", "GearDrawn" }) do
			local child = button:FindFirstChild(name)
			if child and child:IsA("GuiObject") then
				child.Visible = true
			end
		end
		refreshFallback(button)
		return
	end
	if not (box and box:IsA("Frame")) then
		local made = Instance.new("Frame")
		made.Name = "PictureBox"
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Position = UDim2.fromScale(0.5, 0.5)
		made.Size = UDim2.fromScale(1, 1)
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.Active = false
		made.ZIndex = PICTURE_Z
		made.Parent = button
		local shape = Instance.new("UIAspectRatioConstraint")
		shape.Parent = made
		local picture = Instance.new("ImageLabel")
		picture.Name = "Picture"
		picture.Size = UDim2.fromScale(1, 1)
		picture.BackgroundTransparency = 1
		picture.BorderSizePixel = 0
		picture.ScaleType = Enum.ScaleType.Fit
		picture.Active = false
		picture.ZIndex = PICTURE_Z
		picture.Parent = made
		box = made
	end
	local frame = box :: Frame
	frame.Visible = true
	local shape = frame:FindFirstChildOfClass("UIAspectRatioConstraint")
	if shape then
		shape.AspectRatio = aspect or 1
	end
	-- Everything of ours under the picture, once it has loaded and while it is
	-- still the button's picture.
	local function hideOurs()
		if not frame.Visible then
			return
		end
		for _, name in ipairs({ "ArtBox", "Icon", "GearDrawn", "Label", "Tile", "TileLabel", "Plate" }) do
			local child = button:FindFirstChild(name)
			if child and child:IsA("GuiObject") then
				child.Visible = false
			end
		end
		refreshFallback(button)
	end
	local picture = frame:FindFirstChild("Picture")
	if picture and picture:IsA("ImageLabel") then
		picture.Image = image
		watchPicture(picture, hideOurs)
		if pictureLoaded(picture) then
			hideOurs()
		end
	end
	refreshFallback(button)
end

--==============================================================================
-- THE BADGE, HANGING OR TUCKED
--
-- Half off the corner is the desktop look and stays it. The compact rows sit
-- 8 px under the topbar with 6 px between buttons, and a badge hung half off
-- would reach 13 px past both -- up out of the safe area and over the next
-- button -- so there it hangs HudLayout.Config.BadgeHang past the corner
-- instead: on the glass, clear of its neighbour, on the corner a player reads.
-- `side` is the corner it belongs to: Index's is its right, Garden's its right
-- too since Garden stands at the left edge (2026-10-09; its left before).
-- `flush` keeps it level with the button's top (HudLayout.badges).
--
-- `pill`: A PHONE'S SMALL PILL (the owner, 2026-10-09: "shrink the badges" so
-- the pictures show). HudLayout.Config.Phone.Badge: Size px tall with its
-- Stroke, as wide as its count needs at Text px -- never under its height, so
-- two digits widen it rather than shrink under the drawn-size floor -- on the
-- button's top-RIGHT corner, Over px past it, growing leftward. Anything else
-- puts the round 26-px badge back as UIKit.badge made it.
--==============================================================================
local PILL_PAD, PILL_MIN = "PillPad", "PillMin"

function UIKit.railBadge(badge: GuiObject, compact: boolean, side: string, flush: boolean?, pill: boolean?)
	local right = side == "right"
	local edge = if right then 1 else 0
	local count = badge:FindFirstChild("Count")
	local line = badge:FindFirstChildOfClass("UIStroke")
	local round = badge:FindFirstChildOfClass("UICorner")
	local pad = badge:FindFirstChild(PILL_PAD)
	local least = badge:FindFirstChild(PILL_MIN)
	if pill then
		local PB = HudLayout.Config.Phone.Badge
		local inner = PB.Size - PB.Stroke * 2
		if not (pad and pad:IsA("UIPadding")) then
			local made = Instance.new("UIPadding")
			made.Name = PILL_PAD
			made.Parent = badge
			pad = made
		end
		if not (least and least:IsA("UISizeConstraint")) then
			local made = Instance.new("UISizeConstraint")
			made.Name = PILL_MIN
			made.Parent = badge
			least = made
		end
		local padding = pad :: UIPadding
		padding.PaddingLeft = UDim.new(0, PB.Pad)
		padding.PaddingRight = UDim.new(0, PB.Pad)
		local floor = least :: UISizeConstraint
		floor.MinSize = Vector2.new(inner, inner)
		floor.MaxSize = Vector2.new(math.huge, inner)
		badge.AutomaticSize = Enum.AutomaticSize.X
		badge.Size = UDim2.fromOffset(inner, inner)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, PB.Over - PB.Stroke, 0, if flush then PB.Stroke else PB.Stroke - PB.Over)
		if line then
			line.Thickness = PB.Stroke
		end
		if round then
			round.CornerRadius = UDim.new(0, inner / 2)
		end
		if count and count:IsA("TextLabel") then
			count.TextSize = PB.Text
			count.AutomaticSize = Enum.AutomaticSize.X
			count.Size = UDim2.new(0, 0, 1, 0)
			count.Position = UDim2.fromOffset(0, 1)
		end
		return
	end
	if pad then
		pad:Destroy()
	end
	if least then
		least:Destroy()
	end
	badge.AutomaticSize = Enum.AutomaticSize.None
	badge.Size = UDim2.fromOffset(26, 26)
	if line then
		line.Thickness = 2.5
	end
	if round then
		round.CornerRadius = UDim.new(0, 13)
	end
	if count and count:IsA("TextLabel") then
		count.TextSize = 15
		count.AutomaticSize = Enum.AutomaticSize.None
		count.Size = UDim2.fromScale(1, 1)
		count.Position = UDim2.fromOffset(0, 1)
	end
	if compact then
		local hang = HudLayout.Config.BadgeHang
		badge.AnchorPoint = Vector2.new(edge, 0)
		-- Flush: its 2.5-px stroke (UIKit.badge) drawn level with the top, not over it.
		badge.Position = UDim2.new(edge, if right then hang else -hang, 0, if flush then 2.5 else -hang)
	else
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.new(edge, 0, 0, 0)
	end
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
	setSubPill: (boolean?, Color3?) -> (),
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
--==============================================================================
-- SPECIES-SPECIFIC CAMERA NUDGES
--
-- A two-axis fit gets almost everything right on its own, so this table is
-- deliberately nearly empty -- a nudge is an admission that the general rule
-- failed, and every entry needs a reason.
--
-- A value above 1 pulls the camera BACK (smaller); below 1 pushes it IN.
-- Keyed on the form name the caller already passes to setModel.
--==============================================================================
--==============================================================================
-- HOW MUCH OF THE FRAME THE CREATURE TAKES
--
-- 0.86 -- the middle of the 80-90% the art direction asks for, with enough
-- margin left that a leaf tip or a horn does not touch the glass.
--
-- NOT `CARD.CameraFill`, which is 1.02 and is not a fill fraction at all: in the
-- old formula it scaled 0.54 of the bounding DIAGONAL, so reading it as "fill
-- this much of the frame" overflows by 2%. CameraFill is left alone in
-- GameConfig -- it has no other consumer, but it also has no business being
-- silently redefined.
--
-- A creature that is wider than it is tall lands BELOW this on height, because
-- the width is what ran out of room first. That is the shape's business, not a
-- miss: see the measurements in KB/HANDOFF.md.
--==============================================================================
local FRAME_FILL = 0.86

local FRAME_NUDGE: { [string]: number } = {
	-- A bell's silhouette is its skirt, and the fit centres on the whole solid
	-- -- which puts the hem against the frame edge. A hair back keeps the rim.
	bell = 1.04,
	-- A ready pod is a shell with nothing to read but its outline, and it looks
	-- wrong pressed against the glass.
	ready = 1.08,
	pod = 1.08,
}

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

--==============================================================================
-- FRAME A MODEL IN A VIEWPORT, ONCE, AND LEAVE IT THERE
--
-- The camera solve on its own: distance off the model's own bounding diagonal
-- and the camera's field of view, so a five-stud bat and a nine-stud paddle both
-- fill their card without a per-item number to keep in step.
--
-- This existed as a private `frameModel` that nothing called -- plantCard grew
-- its own `setupCamera` when it needed to ORBIT, and the plain version was left
-- behind. It is exported now rather than deleted, because the weapon cards want
-- exactly this and a second copy of a camera solve in a client script is how
-- two panels end up framing the same object two different ways.
--
-- `offset` overrides the authored three-quarter direction. Plants face -Z and
-- want CARD.CameraOffset; a weapon stands up +Y and wants to be looked at from
-- the side, so it passes its own.
--==============================================================================
function UIKit.frameViewport(hero: ViewportFrame, model: Model,
	offset: Vector3?, fill: number?): Camera
	local pivot, size = model:GetBoundingBox()
	local extent = math.max(size.Magnitude, 0.1)
	local dir = (offset or CARD.CameraOffset)
	if dir.Magnitude < 1e-4 then
		dir = CARD.CameraOffset
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	local distance = (extent * (fill or CARD.CameraFill) * 0.54)
		/ math.tan(math.rad(camera.FieldOfView * 0.5))
	local focus = pivot.Position + Vector3.new(0, size.Y * (CARD.CameraRise * 0.88), 0)
	camera.CFrame = CFrame.lookAt(focus + dir.Unit * distance, focus)
	camera.Parent = hero
	hero.CurrentCamera = camera
	return camera
end

--==============================================================================
-- WHAT THE CAMERA IS ACTUALLY LOOKING AT
--
-- `model:GetBoundingBox()` was the old input and it is the wrong box twice
-- over. It includes the invisible `Base` plate -- every creature carries one
-- at ground level purely as a pivot -- and it includes the Pedestal this
-- file adds underneath. Framing to that put a margin of nothing around every
-- plant, which is why the previews read as distant.
--
-- This walks the DRAWN parts instead: anything fully transparent is skipped,
-- and so is the pedestal, which is card furniture rather than creature.
--==============================================================================
local function drawnBounds(model: Model): (Vector3?, Vector3?, { Vector3 })
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local found = false
	-- Kept, because the FIT is done against the real corners rather than
	-- against the box that contains them: a creature does not reach its own
	-- bounding corners, so fitting the box leaves it visibly small.
	local points: { Vector3 } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1
			and not d:IsDescendantOf(model:FindFirstChild("Pedestal") or model) then
			found = true
			local h = d.Size * 0.5
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						points[#points + 1] = q
						lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
						hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
					end
				end
			end
		end
	end
	if not found then
		return nil, nil, points
	end
	return lo, hi, points
end

--==============================================================================
-- FRAME A PLANT THE WAY A CARD DOES
--
-- The plant card's camera solve, lifted out of UIKit.plantCard unchanged so the
-- Index's shelf and showcase frame a creature with exactly the arithmetic the
-- Garden and the Bag use, rather than growing a second copy -- see
-- UIKit.frameViewport for how a second copy lets two panels drift apart.
--
-- Adds the soil pedestal unless the model already has a child named
-- "Pedestal": a caller that wants a different base builds it first, and it is
-- left out of the fit either way. `formName` picks a FRAME_NUDGE. `fill`
-- replaces FRAME_FILL for a stage that should show more air around the plant.
--
-- Returns the camera, and the distance and focus it settled on.
--==============================================================================
function UIKit.framePlant(hero: ViewportFrame, model: Model, formName: string?,
	fill: number?): (Camera, number, Vector3)
	local pivot, size = model:GetBoundingBox()
	addPedestal(model, pivot, size)

	local lo, hi, points = drawnBounds(model)
	if not (lo and hi) then
		-- Nothing drawn: keep the old behaviour rather than divide by zero.
		pivot, size = model:GetBoundingBox()
		lo = pivot.Position - size * 0.5
		hi = pivot.Position + size * 0.5
	end
	local centre = ((lo :: Vector3) + (hi :: Vector3)) * 0.5
	local span = (hi :: Vector3) - (lo :: Vector3)
	--==========================================================================
	-- THE MODEL IS NOT MOVED. THE CAMERA MOVES.
	--
	-- An earlier pass set the pivot to the drawn centre and then PivotTo'd
	-- the model onto it -- which TRANSLATES the creature, because a
	-- creature's pivot is the Base plate at its feet and the drawn centre is
	-- half its height above that. The camera was then aimed at bounds that
	-- no longer described where the model was, and a Supernovus lost its
	-- crown, brow horn, orbital arcs and comet off the top of the frame:
	-- measured at -0.389 in viewport space, 39% above the glass.
	--
	-- The builder put the creature where it wants it. Nothing here has any
	-- business moving it.
	--==========================================================================

	local camera = Instance.new("Camera")
	camera.FieldOfView = 38

	--==========================================================================
	-- FIT BOTH AXES, NOT THE DIAGONAL
	--
	-- The old distance came off `size.Magnitude` -- the bounding box's
	-- DIAGONAL -- which is larger than either the height or the width and
	-- therefore always pushed the camera back further than it needed to be.
	-- The diagonal of a tall thin spire is dominated by its height and the
	-- diagonal of a broad crown by its width, so one number could never suit
	-- both.
	--
	-- Solved twice instead: the distance that makes the height fill FILL of
	-- the frame, and the distance that makes the width fill it, then take
	-- whichever is further. The plant is then as close as it can be without
	-- either axis spilling.
	--
	-- The viewport is 0.98 wide by 0.74 of a 1:1.30 card -- so very nearly
	-- square -- and the aspect is read off it rather than assumed, because
	-- the Index and the Garden are free to size their cards differently.
	--==========================================================================
	local FILL = fill or FRAME_FILL
	local nudge = FRAME_NUDGE[string.lower(formName or "")] or 1
	local half = math.tan(math.rad(camera.FieldOfView * 0.5))

	local box = hero.AbsoluteSize
	local aspect = if box.X > 0 and box.Y > 0 then box.X / box.Y else 1.019

	local distH = (span.Y * 0.5) / (FILL * half)
	-- Horizontal half-angle is the vertical one scaled by the aspect.
	local distW = (math.max(span.X, span.Z) * 0.5) / (FILL * half * aspect)
	local distance = math.max(distH, distW) * nudge

	--==========================================================================
	-- AIMED AT THE MIDDLE OF THE CREATURE, AND NOWHERE ELSE
	--
	-- `CARD.CameraRise` existed to correct an aim taken off a box that
	-- included the pedestal and the invisible base plate. The centre of the
	-- DRAWN box needs no correction, and applying the rise on top of it
	-- spent 8% of the frame's margin pushing the subject down -- which on a
	-- tall creature is the difference between keeping a crown and cropping
	-- it. The knob is left in GameConfig for the other viewport helper.
	--==========================================================================
	local focus = centre
	camera.CFrame = CFrame.lookAt(focus + CARD.CameraOffset.Unit * distance, focus)

	--==========================================================================
	-- ONE CORRECTIVE PASS, BECAUSE THE VIEW IS OBLIQUE
	--
	-- The estimate above treats the creature as a flat rectangle facing the
	-- lens. It is not: CameraOffset looks in at (0.66, 0.28, -1), so the box
	-- is seen corner-on and its CORNERS rotate into the frame. Measured, a
	-- box that should have filled 86% of the height actually filled 98% and
	-- a Supernovus lost a front foot off the bottom edge.
	--
	-- Rather than guess a fudge factor, the eight corners are projected
	-- through the camera that was just built and the distance is scaled by
	-- whatever it actually came out as. Projected size goes as 1/distance,
	-- so one pass lands within a percent -- and it is exact for any shape
	-- and any camera angle, which a constant never would be.
	--==========================================================================
	--==========================================================================
	-- MEASURE WHAT THE LENS ACTUALLY SEES, THEN CORRECT ONCE
	--
	-- The estimate above treats the creature as a flat rectangle facing the
	-- lens. It is not: CameraOffset looks in at (0.66, 0.28, -1), so the box
	-- is seen corner-on and its corners rotate into frame. Measured, a fit
	-- that should have filled 86% of the height filled 98%, and a Supernovus
	-- lost a front foot off the bottom edge.
	--
	-- So the REAL part corners -- not the bounding box's, which a creature
	-- never reaches -- are projected through the camera that was just built,
	-- and two things come back: how much of the frame they span, and where
	-- their middle sits. The distance is scaled by the first and the aim is
	-- nudged by the second, which is what stops an off-centre silhouette
	-- from being fitted as though it were centred.
	--
	-- Projected size goes as 1/distance, so one pass lands within a percent,
	-- and it is exact for any shape at any camera angle -- which no constant
	-- fudge factor could be.
	--==========================================================================
	local function survey(cf: CFrame): (number, number, number)
		local minU, maxU = math.huge, -math.huge
		local minV, maxV = math.huge, -math.huge
		for _, corner in ipairs(points) do
			local rel = cf:PointToObjectSpace(corner)
			if rel.Z < -0.01 then
				local u = rel.X / (-rel.Z * half * aspect)
				local v = rel.Y / (-rel.Z * half)
				minU = math.min(minU, u); maxU = math.max(maxU, u)
				minV = math.min(minV, v); maxV = math.max(maxV, v)
			end
		end
		if minU > maxU then
			return 0, 0, 0
		end
		-- NDC runs -1..1 across the frame, so a span of 1.72 is 86%.
		return math.max(maxU - minU, maxV - minV) * 0.5,
			(minU + maxU) * 0.5, (minV + maxV) * 0.5
	end

	local extent, offU, offV = survey(camera.CFrame)
	if extent > 0.001 then
		-- Slide the aim so the silhouette is centred, in the camera's own
		-- right/up axes rather than the world's.
		local right = camera.CFrame.RightVector
		local up = camera.CFrame.UpVector
		focus = focus
			+ right * (offU * distance * half * aspect)
			+ up * (offV * distance * half)
		distance *= extent / FILL
		camera.CFrame = CFrame.lookAt(focus + CARD.CameraOffset.Unit * distance, focus)
	end

	camera.Parent = hero
	hero.CurrentCamera = camera
	return camera, distance, focus
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

	--==========================================================================
	-- A PILL BEHIND THE SUBTITLE, FOR WHEN IT IS A RARITY
	--
	-- The sub line carries different things on different cards -- a rarity, a
	-- countdown, an instruction -- and only one of those is a LABEL worth
	-- boxing. So the pill is off by default and the caller turns it on for the
	-- line that is naming a thing rather than describing a state.
	--
	-- It sizes itself off the text rather than being given a width, because the
	-- words it wraps run from "RARE" to "UNDISCOVERED" and a fixed pill would
	-- either clip the long one or float around the short one. TextBounds is the
	-- rendered width and it changes with the text, so the resize rides that
	-- signal instead of every caller remembering to ask.
	--
	-- BEHIND, at Z_LABEL - 1. The sub keeps its own outline: on a busy plant
	-- portrait the stroke is still what makes the word legible, and the pill is
	-- there to group it, not to replace it.
	--==========================================================================
	local subPill = Instance.new("Frame")
	subPill.Name = "SubPill"
	subPill.AnchorPoint = Vector2.new(0.5, 1)
	subPill.Position = UDim2.new(0.5, 0, 1, -3)
	subPill.Size = UDim2.fromOffset(40, 17)
	subPill.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
	subPill.BackgroundTransparency = 0.26
	subPill.BorderSizePixel = 0
	subPill.Active = false
	subPill.Visible = false
	subPill.ZIndex = Z_LABEL - 1
	subPill.Parent = button
	UIKit.corner(subPill, 5)
	local subPillEdge = UIKit.stroke(subPill, WHITE, 1, 0.82)

	local function fitSubPill()
		-- TextBounds is drawn pixels; the Offset is in the gui's own units, which
		-- a TV or a larger menu size makes scaleOf times smaller.
		subPill.Size = UDim2.fromOffset(math.ceil(sub.TextBounds.X / UIKit.scaleOf(sub)) + 16, 17)
	end
	sub:GetPropertyChangedSignal("TextBounds"):Connect(fitSubPill)

	local function setSubPill(on: boolean?, colour: Color3?)
		if not on then
			subPill.Visible = false
			return
		end
		fitSubPill()
		-- The rarity tints the EDGE, not the fill. A filled pill in Mythic pink
		-- behind pink text is a smear; a dark pill with a coloured rim keeps the
		-- word readable and still says which band it is at a glance.
		subPillEdge.Color = colour or WHITE
		subPillEdge.Transparency = if colour then 0.25 else 0.82
		subPill.Visible = true
	end

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
	local isSelected: boolean = false
	--==========================================================================
	-- THE FORM NAME IS STILL TAKEN, AND IT STILL DOES SOMETHING
	--
	-- It used to pick an idle animation. Now it picks a CAMERA nudge: a bell is
	-- top-heavy and a spire is a needle, and a single fit that suits a cube
	-- leaves one of them small. See FRAME_NUDGE.
	--==========================================================================
	local currentFormType: string = ""

	--==========================================================================
	-- NOTHING HERE MOVES
	--
	-- What used to live in this space: a hover gate, an accumulated animation
	-- clock, a `parked` latch, a spin velocity and a yaw that orbited the
	-- camera. All of it is gone, and so is the loop that drove it. A card is a
	-- still photograph -- the pose and the camera are written once, when the
	-- model is built, and never again.
	--==========================================================================

	--==========================================================================
	-- THE CAMERA IS SOLVED BY UIKit.framePlant
	--
	-- The drawn bounds, the two-axis fit and the corrective survey that lived
	-- here moved to module level, unchanged, so the Index frames a creature with
	-- the same arithmetic. What stays is this card's record of the result.
	--==========================================================================
	local function setupCamera(model: Model)
		local camera, distance, focus = UIKit.framePlant(hero, model, currentFormType)
		modelBasePivot = model:GetPivot()
		cameraDistance = distance
		cameraFocus = focus
		activeCamera = camera

		-- WRITTEN ONCE. There is no loop to write it again, so the view a card
		-- is built with is the view it keeps for the life of the card.
	end

	local modelKey: string? = nil
	local function setModel(key: string, build: ((Instance) -> Model?)?, formName: string?)
		if modelKey == key then
			if formName then
				currentFormType = string.lower(formName)
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
		local model = build(hero)
		if model then
			currentModel = model
			-- setupCamera writes the camera AND the pose, once. Nothing writes
			-- either again.
			setupCamera(model)
		end
	end

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
	--==========================================================================
	-- AND IT SHAKES WHEN IT IS PRESSED
	--
	-- CardWrap, not `holder`. The holder is the grid cell and the layout writes
	-- its Position on every reflow; CardWrap sits inside it and nothing else
	-- touches where it sits.
	--==========================================================================
	UIKit.shakeOnClick(button, card)

	--==========================================================================
	-- HOVER POPS AGAIN
	--
	-- This was pinned at scale 1 -- stroke and sound only, no growth -- when the
	-- owner asked for idle card motion to be removed. That reading was too
	-- broad: what was asked for was the removal of motion the card makes BY
	-- ITSELF, the rotation and the drift that ran whether anybody was looking or
	-- not. A hover pop is not idle; it happens because the player moved the
	-- pointer onto it, and it is now wanted on every card in the game.
	--
	-- So the pin is gone and CARD.HoverScale applies. The stroke thickening and
	-- the hover cue stay exactly as they were.
	--==========================================================================
	local setHovered, setPopEnabled = UIKit.popOnHover(holder, scale,
		{ stroke = border })

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
		setSubPill = setSubPill,
		setProgress = setProgress,
		setReadyPulse = setReadyPulse,
		setStageTheme = setStageTheme,
		setEmpty = setEmpty,
	}
end

--==============================================================================
-- HOW AN ITEM IS POSED IN ITS OWN BOX
--
-- The shop worked this out and the inventory and the hotbar must not work it
-- out again differently -- three surfaces drawing the same bat at three angles
-- is exactly the "competing rendering implementations" the brief forbids. So
-- the posing and the camera live here, keyed on the item's category, and the
-- shop now calls this instead of its own copy. The numbers are the shop's own,
-- unchanged, so its approved appearance is preserved to the pixel.
--
--   bat    six studs tall and under two wide, so a square box framed on its
--          bounding diagonal is mostly empty air either side. Tipped 34 degrees
--          the box is nearly square and the weapon fills the card.
--   trap   already wider than it is tall. Left flat, looked at from higher up.
--   plant  a pod or a grown creature. Upright, framed a little looser because a
--          Colossal is four hundred studs of silhouette and a Tiny is three.
--==============================================================================
--==============================================================================
-- AND, WHEN ASKED, AS CLOSE AS THE SILHOUETTE ALLOWS
--
-- frameViewport stands the camera off the bounding box's DIAGONAL, and the box
-- includes the invisible Base plate every creature carries at its feet -- two
-- margins stacked, which is right for a shop card with room to breathe and why
-- a hotbar slot drew its item at about a third of the card.
--
-- With `fit`, the same pose and the same viewing direction are kept and only
-- the distance and aim are corrected: every corner of every DRAWN part is
-- projected through the lens, the aim slides to the silhouette's centre, and
-- the distance scales until the limiting axis spans exactly `fit` of the glass.
-- Twice, because at card distances perspective moves the answer a little
-- between passes. The whole silhouette is inside the frame by construction,
-- not by a margin somebody picked.
--
-- `aspect` is the glass's width over height, for a viewport that has not been
-- laid out yet and still reports a zero AbsoluteSize.
--==============================================================================
local function fitToSilhouette(hero: ViewportFrame, camera: Camera, model: Model,
	fit: number, aspectHint: number?)
	-- Not drawnBounds: that one excludes the plant card's Pedestal by asking
	-- `IsDescendantOf(Pedestal or model)`, which on a model with no pedestal is
	-- every part, and it would return nothing at all here.
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local points: { Vector3 } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local h = d.Size * 0.5
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						points[#points + 1] = q
						lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
						hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
					end
				end
			end
		end
	end
	if #points == 0 then
		return
	end
	local half = math.tan(math.rad(camera.FieldOfView * 0.5))
	local box = hero.AbsoluteSize
	local aspect = if box.X > 0 and box.Y > 0 then box.X / box.Y else (aspectHint or 1)
	local look = camera.CFrame.LookVector
	local focus = ((lo :: Vector3) + (hi :: Vector3)) * 0.5
	local distance = -camera.CFrame:PointToObjectSpace(focus).Z
	if distance < 0.01 then
		return
	end

	local function survey(cf: CFrame): (number, number, number)
		local minU, maxU = math.huge, -math.huge
		local minV, maxV = math.huge, -math.huge
		for _, corner in ipairs(points) do
			local rel = cf:PointToObjectSpace(corner)
			if rel.Z < -0.01 then
				local u = rel.X / (-rel.Z * half * aspect)
				local v = rel.Y / (-rel.Z * half)
				minU = math.min(minU, u); maxU = math.max(maxU, u)
				minV = math.min(minV, v); maxV = math.max(maxV, v)
			end
		end
		if minU > maxU then
			return 0, 0, 0
		end
		return math.max(maxU - minU, maxV - minV) * 0.5,
			(minU + maxU) * 0.5, (minV + maxV) * 0.5
	end

	local cf = CFrame.lookAt(focus - look * distance, focus)
	for _ = 1, 2 do
		local extent, offU, offV = survey(cf)
		if extent <= 0.001 then
			break
		end
		focus = focus
			+ cf.RightVector * (offU * distance * half * aspect)
			+ cf.UpVector * (offV * distance * half)
		distance *= extent / fit
		cf = CFrame.lookAt(focus - look * distance, focus)
	end
	camera.CFrame = cf
end

function UIKit.frameItem(hero: ViewportFrame, model: Model, kind: string,
	fit: number?, aspectHint: number?): Camera
	local camera
	if kind == "trap" then
		model:PivotTo(CFrame.new())
		camera = UIKit.frameViewport(hero, model, Vector3.new(0.45, 0.62, -1), 1.02)
	elseif kind == "plant" then
		model:PivotTo(CFrame.new())
		camera = UIKit.frameViewport(hero, model, Vector3.new(0.62, 0.30, -1), 1.06)
	else
		model:PivotTo(CFrame.Angles(0, 0, math.rad(-34)))
		camera = UIKit.frameViewport(hero, model, Vector3.new(0.55, 0.22, -1), 0.96)
	end
	if fit then
		fitToSilhouette(hero, camera, model, fit, aspectHint)
	end
	return camera
end

--==============================================================================
-- AN ITEM PREVIEW WITH NOTHING BEHIND IT
--
-- A ViewportFrame and nothing else: no plate, no fill, no gradient. The brief
-- asks for transparent previews everywhere outside the shop, and the reason is
-- worth writing down -- a solid backplate behind every item turns a bag into a
-- grid of tiles, and the thing a player is actually looking for is the SHAPE.
--
-- Readable on bright and dark scenes is the one thing transparency costs, and
-- it is bought back with an optional dark scrim at very low opacity plus the
-- viewport's own lighting, which is brighter than the world's. Not a plate: a
-- breath of shade under the silhouette.
--
-- `setModel` is keyed, so a hotbar slot that redraws sixty times a second
-- because its cooldown is ticking rebuilds its model zero times.
--==============================================================================
export type ItemPreviewOptions = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	-- A whisper of shade behind the item so a pale bat survives a pale sky.
	-- 1 is fully transparent; the default is nearly so.
	scrim: number?,
	-- Frame the drawn silhouette to this fraction of the glass instead of the
	-- default margins -- see UIKit.frameItem. nil keeps the shop's framing.
	fit: number?,
}

export type ItemPreview = {
	holder: Frame,
	hero: ViewportFrame,
	-- key, builder, category. A repeated key is a no-op.
	setModel: (string, ((Instance) -> Model?)?, string?) -> (),
}

function UIKit.itemPreview(parent: Instance, options: ItemPreviewOptions?): ItemPreview
	local opts: ItemPreviewOptions = options or {}

	local holder = Instance.new("Frame")
	holder.Name = opts.name or "ItemPreview"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = opts.size or UDim2.fromScale(1, 1)
	if opts.position then
		holder.Position = opts.position
	end
	if opts.anchorPoint then
		holder.AnchorPoint = opts.anchorPoint
	end
	holder.LayoutOrder = opts.layoutOrder or 0
	holder.ZIndex = 6
	holder.Parent = parent

	local scrim = Instance.new("Frame")
	scrim.Name = "Scrim"
	scrim.AnchorPoint = Vector2.new(0.5, 0.5)
	scrim.Position = UDim2.fromScale(0.5, 0.56)
	scrim.Size = UDim2.fromScale(0.82, 0.72)
	scrim.BackgroundColor3 = BLACK
	scrim.BackgroundTransparency = opts.scrim or 0.86
	scrim.BorderSizePixel = 0
	scrim.ZIndex = 6
	scrim.Parent = holder
	UIKit.corner(scrim, 24)

	local hero = Instance.new("ViewportFrame")
	hero.Name = "Hero"
	hero.Size = UDim2.fromScale(1, 1)
	-- THE WHOLE POINT. No fill, no image, nothing behind the model.
	hero.BackgroundTransparency = 1
	hero.BorderSizePixel = 0
	hero.Active = false
	hero.Ambient = CARD.Ambient
	hero.LightColor = CARD.LightColour
	hero.LightDirection = CARD.LightDirection
	hero.ZIndex = 7
	hero.Parent = holder

	local shownKey: string? = nil
	local function setModel(key: string, build: ((Instance) -> Model?)?, kind: string?)
		if shownKey == key then
			return
		end
		shownKey = key
		hero:ClearAllChildren()
		hero.CurrentCamera = nil
		if not build then
			return
		end
		local ok, model = pcall(build, hero)
		if ok and model then
			-- The aspect a laid-out holder will have, for the first frame after it
			-- is built, when AbsoluteSize can still read zero.
			local size = holder.Size
			local aspectHint = if size.Y.Offset > 0 and size.X.Scale == 0 and size.Y.Scale == 0
				then size.X.Offset / size.Y.Offset
				else nil
			pcall(UIKit.frameItem, hero, model, kind or "bat", opts.fit, aspectHint)
		end
	end

	return { holder = holder, hero = hero, setModel = setModel }
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
--==============================================================================
-- A THEME, FOR A PANEL THAT IS NOT THE HOUSE SOIL
--
-- Every field is optional and falls back to GameConfig.Panel, so a panel that
-- passes no theme builds exactly as it always has. The shop passes one: a
-- charcoal shell, a green header banner and a brighter close.
--
-- `headerTop` and `headerBottom` together add a coloured banner behind the title
-- bar; with either one missing there is no banner and the title sits on the
-- shell as before.
--==============================================================================
export type ModalTheme = {
	fill: Color3?,
	shade: Color3?,
	outline: Color3?,
	lattice: Color3?,
	latticeTransparency: number?,
	-- The shell sits at ZIndex 1 and the lattice builds at 0, so in a Global
	-- ZIndexBehavior ScreenGui the lattice draws UNDER the shell and is never
	-- seen (measured in the shop: invisible at 0, a clear lattice once lifted).
	-- A theme that wants its texture on screen lifts it here; nil keeps 0.
	latticeZIndex: number?,
	headerTop: Color3?,
	headerBottom: Color3?,
	headerRule: Color3?,
	titleStroke: Color3?,
	titleStrokeThickness: number?,
	closeTop: Color3?,
	closeBottom: Color3?,
	closeShade: Color3?,
	closeRadius: number?,
	--==========================================================================
	-- THE STUDDED RIM (2026-10-04, the global UI art pass)
	--
	-- `rim`: the header band becomes the owner's white rim -- `rimTop` to
	-- `rimBottom`, faint raised studs (UIKit.studs, `studs`), a keyline rule
	-- under it -- in place of the coloured banner.
	--
	-- `lift`: the visible shell starts this many px BELOW the panel's top, and
	-- the title row stands on its top edge -- the title, its icon and the close
	-- sit ON the rim, as in the reference, and still inside the panel's own
	-- rect (a CanvasGroup draws nothing outside it, and nothing may reach the
	-- topbar). The body keeps exactly the rect it had: only the rim's visible
	-- height gives the lift up.
	--
	-- `closeStuds`: the close's red plate wears studs of its own.
	--==========================================================================
	rim: boolean?,
	rimTop: Color3?,
	rimBottom: Color3?,
	studs: StudOptions?,
	lift: number?,
	closeStuds: StudOptions?,
	titleSize: number?,
	--==========================================================================
	-- THE STUDDED KIT'S BAND (2026-10-08, GameConfig.StuddedLook)
	--
	-- `band`: no lift and no rim. The header is the coloured banner
	-- (headerTop / headerBottom) with `texture` tiled over it; the body is
	-- `fill` with the same texture fainter; the close plate wears it too. `base`
	-- px of the outline colour stand under the shell as a solid foot (the
	-- shell is that much shorter). `closeEdge` is the close plate's own keyline
	-- and `closeMarkLine` its X's.
	--==========================================================================
	band: boolean?,
	texture: { image: string, tile: number, band: number, body: number }?,
	base: number?,
	closeEdge: Color3?,
	closeMarkLine: Color3?,
}

export type ModalOptions = {
	name: string,
	title: string,
	maxWidth: number?,
	maxHeight: number?,
	titleColour: Color3?,
	theme: ModalTheme?,
	-- A panel that is never placed under the rail (2026-10-03, the compact
	-- Index and Shop: between the rails on a desktop, or covering the rail
	-- layer with UIKit.coverRail while open): its header is never padded clear
	-- of a rail button, because none can be over it.
	fixedHeader: boolean?,
	-- Under reduced motion (the game's REDUCED FX "Off", or Roblox's own
	-- setting) the panel opens and shuts without its pop -- the fade only
	-- (2026-10-05, WHAT'S NEW; opt-in, so no other panel changes).
	stillWhenReduced: boolean?,
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
	-- The player's menu size on THIS panel, for one that cannot take it on its
	-- gui (see UIKit.menuGui). The caller keeps the footprint.
	setUserScale: (number) -> (),
	-- What the panel is drawn at on its own: 1 unless setUserScale said more
	-- (or, on a phone, less).
	userScale: () -> number,
	-- For a panel sharing its gui with HUD: take the menu size on the panel.
	followMenuSize: () -> (),
	-- For a panel sized by the screen's fractions alone: size it again, after
	-- its gui's scale changed (a phone: UIKit.menuScaleFor).
	fitScreen: () -> (),
	-- How tall content may be on this screen before fitContent has to cut the
	-- panel short. For a panel that can lay itself out smaller instead.
	contentRoom: () -> number,
	-- The studded rim's lift (theme.lift): a panel that lays its own shell out
	-- in fixed numbers takes it back off them (InventoryPanel). 0 without one.
	lift: number,
}

-- The dimmer's transparency while a panel is open: 1, see-through (the owner,
-- 2026-10-06: "remove the dimmer on any ui"; it was 0.45). It is still there,
-- a button over the world, so a tap outside the panel closes it and never
-- reaches the world behind.
local DIM = 1
local FADE = 0.16
-- What the shell puts round a panel's content: the title bar, the body's own
-- margins and the outline. fitContent adds it; contentRoom takes it off.
local MODAL_CHROME = 82

-- The studded kit's stud tile over a surface (a band theme's header, body and
-- close), rounded like the surface. Never takes a press.
local function studTexture(parent: GuiObject, texture: { image: string, tile: number }, transparency: number,
	radius: number, zIndex: number): ImageLabel
	local t = Instance.new("ImageLabel")
	t.Name = "StudTexture"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Image = texture.image
	t.ScaleType = Enum.ScaleType.Tile
	t.TileSize = UDim2.fromOffset(texture.tile, texture.tile)
	t.ImageTransparency = transparency
	t.Active = false
	t.ZIndex = zIndex
	t.Parent = parent
	UIKit.corner(t, radius)
	return t
end

function UIKit.modal(gui: ScreenGui, options: ModalOptions): Modal
	-- Every centre panel is drawn bigger on a TV (see UIKit.tenFoot).
	UIKit.tenFoot(gui)
	local outline = RAIL.OutlineThickness
	local theme: ModalTheme = options.theme or {}
	local fill = theme.fill or PANEL.Fill
	local shade = theme.shade or PANEL.Shade
	local keyline = theme.outline or PANEL.Outline

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
	-- Tapping it closes the panel; selecting it with a controller would put a
	-- selection frame round the whole screen. B closes the panel instead.
	dimmer.Selectable = false
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
	-- The player's menu size when it is carried on this panel rather than on its
	-- gui (setUserScale, below). Declared here: the header's padding reads it.
	local userScale = 1

	-- The share of the screen this panel's fractions are of: 1, except on a
	-- phone (2026-10-08, UIKit.phoneMenuScale), where the panel is drawn smaller
	-- -- on its gui (UIKit.menuGui) or on itself (followMenuSize) -- and takes
	-- that much less of the screen, so it keeps the room it had and stops short
	-- of the screen's edges. Never on a TV.
	local function share(): number
		if HudLayout.isTenFoot() then
			return 1
		end
		return math.min(1, HudLayout.scaleOf(gui) * userScale)
	end

	local shell = Instance.new("Frame")
	shell.Name = "Shell"
	-- A lifted rim (theme.lift) starts the shell that much lower; its foot stays.
	-- A band (the studded kit) has no lift; its solid base takes `base` px
	-- off the shell's foot instead.
	local lift = if theme.band then 0 else math.max(0, theme.lift or 0)
	local base = if theme.band then math.max(0, theme.base or 0) else 0
	if lift > 0 then
		shell.AnchorPoint = Vector2.new(0.5, 1)
		shell.Position = UDim2.new(0.5, 0, 1, -outline)
		shell.Size = UDim2.new(1, -outline * 2, 1, -outline * 2 - lift)
	elseif base > 0 then
		shell.AnchorPoint = Vector2.new(0.5, 0)
		shell.Position = UDim2.new(0.5, 0, 0, outline)
		shell.Size = UDim2.new(1, -outline * 2, 1, -outline * 2 - base)
	else
		shell.AnchorPoint = Vector2.new(0.5, 0.5)
		shell.Position = UDim2.fromScale(0.5, 0.5)
		shell.Size = UDim2.new(1, -outline * 2, 1, -outline * 2)
	end
	-- Overwritten by UIKit.gradient below, which needs the surface white to
	-- multiply against. Set anyway so the shell is never momentarily the
	-- default grey if the gradient is ever dropped.
	shell.BackgroundColor3 = fill
	shell.BorderSizePixel = 0
	--==========================================================================
	-- THIS ALONE DID NOT WORK, AND HERE IS WHY
	--
	-- `Active` was supposed to consume the click so tapping the panel did not
	-- reach the dimmer under it. It never did, and every panel in the game has
	-- been closing when you click its contents.
	--
	-- Two things combine. The ScreenGui is ZIndexBehavior = GLOBAL, where ZIndex
	-- is compared as a raw number across the whole tree instead of within each
	-- parent -- and Shell was left at 1, the same number the dimmer has, so it
	-- never sorted above it. And even level, an ACTIVE FRAME does not stop a
	-- GuiButton underneath from firing Activated; only another GuiButton does.
	--
	-- Raising Shell.ZIndex was tried and did not fix it. What fixes it is the
	-- blocker below. `Active` stays because it is still correct for the touch
	-- and hover paths.
	--==========================================================================
	shell.Active = true
	shell.Parent = group
	UIKit.corner(shell, 16)
	UIKit.stroke(shell, keyline, outline)
	UIKit.gradient(shell, fill, shade)

	-- THE STUDDED KIT'S BODY AND BASE: the stud tile faint over the body, and
	-- a solid foot in the keyline colour standing `base` px out under it (a
	-- child at ZIndex 0, which under GLOBAL ZIndexBehavior draws below the
	-- shell, so it moves and sizes with it).
	local texture = theme.texture
	if theme.band and texture then
		studTexture(shell, texture, texture.body, 16, 1)
	end
	if base > 0 then
		local foot = Instance.new("Frame")
		foot.Name = "Base"
		foot.Position = UDim2.fromOffset(0, base)
		foot.Size = UDim2.fromScale(1, 1)
		foot.BackgroundColor3 = keyline
		foot.BorderSizePixel = 0
		foot.Active = false
		foot.ZIndex = 0
		foot.Parent = shell
		UIKit.corner(foot, 16)
		UIKit.stroke(foot, keyline, outline)
	end

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
	-- The studded rim is the texture now: a rimmed panel's body stays clean, and
	-- a band's body wears the kit's studs instead.
	if not theme.rim and not theme.band then
		UIKit.lattice(shell, {
			spacing = PANEL.LatticeSpacing,
			thickness = 2,
			colour = theme.lattice or PANEL.Lattice,
			transparency = theme.latticeTransparency or PANEL.LatticeTransparency,
			inset = 6,
			zIndex = theme.latticeZIndex,
		})
	end

	--==========================================================================
	-- THE HEADER BANNER, WHEN A THEME ASKS FOR ONE
	--
	-- A coloured band across the top of the shell, behind the title bar and as
	-- tall as everything above the body. Its top corners are the panel's own;
	-- the bottom ones are squared off by a foot painted in the gradient's last
	-- colour, which is why that colour holds flat through the bottom third. A
	-- rule in the keyline colour closes it off from the body.
	--
	-- Not Active and not a button, so a press on it still lands on the click
	-- blocker and never closes the panel.
	--==========================================================================
	-- A lifted rim's visible band is the lift shorter; the body below keeps its rect.
	local HEADER_HEIGHT = 58 - lift
	local headerTop, headerBottom = theme.headerTop, theme.headerBottom
	if theme.rim then
		headerTop = theme.rimTop or WHITE
		headerBottom = theme.rimBottom or WHITE
	end
	if headerTop and headerBottom then
		local banner = Instance.new("Frame")
		banner.Name = "HeaderBanner"
		banner.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
		banner.BackgroundColor3 = WHITE
		banner.BorderSizePixel = 0
		banner.Active = false
		banner.ZIndex = 2
		banner.Parent = shell
		UIKit.corner(banner, 16)
		local tint = Instance.new("UIGradient")
		tint.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, headerTop),
			ColorSequenceKeypoint.new(0.7, headerBottom),
			ColorSequenceKeypoint.new(1, headerBottom),
		})
		tint.Rotation = 90
		tint.Parent = banner

		local foot = Instance.new("Frame")
		foot.Name = "Foot"
		foot.AnchorPoint = Vector2.new(0, 1)
		foot.Position = UDim2.fromScale(0, 1)
		foot.Size = UDim2.new(1, 0, 0, 16)
		foot.BackgroundColor3 = headerBottom
		foot.BorderSizePixel = 0
		foot.Active = false
		foot.ZIndex = 2
		foot.Parent = banner

		local rule = Instance.new("Frame")
		rule.Name = "Rule"
		rule.AnchorPoint = Vector2.new(0, 1)
		rule.Position = UDim2.fromScale(0, 1)
		rule.Size = UDim2.new(1, 0, 0, 3)
		rule.BackgroundColor3 = theme.headerRule or keyline
		rule.BorderSizePixel = 0
		rule.Active = false
		rule.ZIndex = 3
		rule.Parent = banner

		-- A band wears the kit's stud tile over its colour, under the rule.
		if theme.band and texture then
			studTexture(banner, texture, texture.band, 16, 2)
		end

		-- The rim's studs, quiet, clear of the rounded corners and the rule.
		local rimStuds = theme.studs
		if theme.rim and rimStuds then
			local studOptions = table.clone(rimStuds)
			studOptions.inset = studOptions.inset or 10
			studOptions.insetTop = studOptions.insetTop or 5
			studOptions.insetBottom = studOptions.insetBottom or 6
			studOptions.zIndex = 2
			UIKit.studs(banner, studOptions)
		end
	end

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, -24, 0, 40)
	-- On a lifted rim the row stands ON the rim's top edge: its middle 8 px
	-- below it, so the title, icon and close overhang into the lift.
	titleBar.Position = if lift > 0 then UDim2.fromOffset(12, 8 - 20) else UDim2.fromOffset(12, 10)
	titleBar.BackgroundTransparency = 1
	titleBar.ZIndex = 3
	titleBar.Parent = shell

	--==========================================================================
	-- THE HEADER STEPS CLEAR OF THE RAIL
	--
	-- The rail sits at DisplayOrder 40 against a panel's 31-34, deliberately: the
	-- Index and Shop buttons stay pressable while a panel is open, which is what
	-- lets a player move between panels without closing one first.
	--
	-- On a desktop that costs nothing, because a centred panel's header is
	-- hundreds of pixels below the rail. On a 735-wide phone the panel is 520
	-- across and its header lands squarely under the Index button -- the Bag's
	-- title read "AG", with the B behind a rail button.
	--
	-- So the header is PADDED, not the panel narrowed and not the rail moved.
	-- Narrowing the panel would take width from the cards, which are already at
	-- their minimum touch size; hiding the rail would remove the thing the
	-- DisplayOrder exists to protect. Padding costs a title a few pixels of a
	-- line it was not using.
	--
	-- BOTH SIDES, because the rail has two. The left pair are 130 wide and the
	-- right edge's column 50 (WHAT'S NEW in the corner, or EVENTS in compact,
	-- since Garden and the Bag moved to the left edge on 2026-10-09), and at
	-- narrower widths still it is the CLOSE BUTTON that meets it -- the same fix
	-- moves it in, because it is anchored to this bar's right edge.
	--
	-- COMPUTED, not measured off the rail's instances. This module is required
	-- by the rail as well as by every panel, and reaching across to another
	-- ScreenGui to measure it would make a panel depend on the rail having been
	-- built first. On a desktop it is the same GameConfig.Rail arithmetic it
	-- always was; in HudLayout's compact mode the rail is the two top rows, and
	-- the footprint is theirs.
	--
	-- IT ONLY APPLIES WHERE THEY ACTUALLY MEET. The vertical test is what keeps
	-- the desktop untouched: a centred panel on a tall screen has its header
	-- well below the rail band, the overlap is zero, and the padding stays zero.
	--==========================================================================
	local headerPad = Instance.new("UIPadding")
	headerPad.Parent = titleBar

	local HEADER_GAP = 8

	local function layoutHeader()
		if options.fixedHeader then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		-- In RAIL units: on a TV the rail is drawn `k` times larger (UIKit.tenFoot),
		-- 1 everywhere else -- and never the menu size, which the rail does not
		-- take. The title bar is read in those units below; the padding it needs
		-- is handed back in the panel's own, which a larger menu size makes
		-- `menu` times larger again (and a phone smaller: share).
		local k = if HudLayout.isTenFoot() then HudLayout.tenFootScale(camera.ViewportSize) else 1
		local menu = (if HudLayout.isTenFoot() then math.max(1, HudLayout.scaleOf(gui) / k)
			else HudLayout.scaleOf(gui)) * userScale
		local viewportX = camera.ViewportSize.X / k
		-- The rail's own footprint, in the same gui space AbsolutePosition uses.
		local railTop = RAIL.Inset
		local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
		local railLeftEdge = RAIL.Inset + RAIL.WideSize.X
		local railRightEdge = viewportX - RAIL.Inset - RAIL.SquareSize.X
		if gui.AbsoluteSize.X > 0 then
			local layout = HudLayout.solve(HudLayout.measure(gui))
			-- A TV's rail stands inside the title-safe frame, so it is read off
			-- the answer too.
			if layout.compact or layout.frame ~= nil then
				railTop = layout.railTop
				railBottom = layout.railBottom
				railLeftEdge = layout.railRight
				railRightEdge = layout.rightLeft
			end
		end

		-- UIPadding insets a frame's CHILDREN, never the frame, so these read
		-- the same whatever this function last set.
		local at, size = titleBar.AbsolutePosition / k, titleBar.AbsoluteSize / k
		local left, right = at.X, at.X + size.X
		local top, bottom = at.Y, at.Y + size.Y

		local padLeft, padRight = 0, 0
		if bottom > railTop and top < railBottom then
			padLeft = math.max(0, (railLeftEdge + HEADER_GAP) - left)
			padRight = math.max(0, right - (railRightEdge - HEADER_GAP))
		end
		headerPad.PaddingLeft = UDim.new(0, math.floor(padLeft / menu))
		headerPad.PaddingRight = UDim.new(0, math.floor(padRight / menu))
	end

	-- The panel moves for three reasons -- opening, the viewport changing, and
	-- fitContent resizing it -- and all three land on these two properties.
	titleBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(layoutHeader)
	titleBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutHeader)
	layoutHeader()

	local title = UIKit.outlined(titleBar, "Title", theme.titleSize or 26,
		options.titleColour or PANEL.Title, theme.titleStrokeThickness or 3)
	local titleStroke = theme.titleStroke
	if titleStroke then
		local titleLine = title:FindFirstChildOfClass("UIStroke")
		if titleLine then
			titleLine.Color = titleStroke
		end
	end
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Position = UDim2.new(0, 0, 0.5, 0)
	title.Size = UDim2.new(1, -52, 1, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = options.title
	title.ZIndex = 3

	--==========================================================================
	-- THE CLICK BLOCKER
	--
	-- An invisible button the size of the panel, behind everything in it. It has
	-- no handler and does nothing when pressed -- SWALLOWING THE CLICK IS THE
	-- ENTIRE JOB. Without it a click on any part of a panel that is not itself a
	-- button falls through to the dimmer, whose Activated closes the panel, so
	-- pressing a shop card or the empty space beside one shut the shop.
	--
	-- ZIndex 2, which is above the dimmer's 1 and below the content's 3. Under
	-- GLOBAL ZIndexBehavior those numbers are compared across the whole ScreenGui
	-- rather than per parent, so this is what decides it -- at 0 or 1 the blocker
	-- loses to the dimmer and the bug comes straight back.
	--
	-- It must be a GuiButton. An Active Frame in the same place does not stop the
	-- dimmer's Activated from firing; that was the original fix and it never
	-- worked.
	--==========================================================================
	local blocker = Instance.new("TextButton")
	blocker.Name = "ClickBlocker"
	blocker.Size = UDim2.fromScale(1, 1)
	blocker.BackgroundTransparency = 1
	blocker.BorderSizePixel = 0
	blocker.AutoButtonColor = false
	blocker.Text = ""
	blocker.ZIndex = 2
	-- A button only so it can swallow a stray tap; never somewhere a controller's
	-- selection should land (an invisible frame the size of the panel).
	blocker.Selectable = false
	blocker.Parent = shell

	--==========================================================================
	-- THE CLOSE BUTTON
	--
	-- Lit face, darker foot, shade bar under it, black keyline: the same four
	-- things the shop's price pills and the Bag's state buttons are made of, so
	-- the game has ONE button language rather than a special case in the corner
	-- of every panel.
	--
	-- It was a flat rgb(255,0,0) square with a bare white X on it. This shipped
	-- on the Bag first and is here now, which means Index, Shop, Garden, Bag and
	-- Marigold's stall all get it from one place -- five panels that would
	-- otherwise have drifted apart the first time one of them was touched.
	--
	-- THE X IS A CHILD LABEL, NOT THE BUTTON'S OWN TEXT. A UIStroke on a
	-- TextButton strokes its BORDER, and only one UIStroke per object is
	-- honoured, so there is no way to outline the glyph while the button still
	-- has its keyline. A label carries its own.
	--==========================================================================
	--==========================================================================
	-- THE BUTTON IS 44. THE PLATE IS STILL 38.
	--
	-- Roblox's own guidance is a 44-pixel minimum touch target, and this was
	-- authored at 38 -- comfortably under it on a phone, where the close X is
	-- the control a player reaches for most and the one nearest a screen edge.
	--
	-- Measured before touching it: at REST the button renders 38 x 38. An
	-- earlier note in HANDOFF recorded 35 and blamed a responsive UIScale; that
	-- was wrong and is corrected there. The 0.92 scale is the OPEN ANIMATION's
	-- starting value, tweening to 1 over 0.16s, so 35 was a measurement taken
	-- mid-tween. The shortfall was 6 pixels, not 9.
	--
	-- THE TARGET GROWS AND THE PLATE DOES NOT. The TextButton -- which is the
	-- hit area, and the thing every consumer connects Activated to -- is 44 and
	-- fully transparent. The red plate that was the button is now a Frame inside
	-- it at the authored 38, carrying the gradient, corner, stroke and shade
	-- exactly as before. Nothing about the appearance moves.
	--
	-- IT GROWS INWARD, not outward: AnchorPoint is still (1, 0.5) against the
	-- title bar's right edge, so the extra six pixels are taken from the panel's
	-- interior rather than from the outline, and the plate stays where it was.
	--==========================================================================
	local CLOSE_TARGET = 44
	local CLOSE_PLATE = 38

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, 0, 0.5, 0)
	close.Size = UDim2.fromOffset(CLOSE_TARGET, CLOSE_TARGET)
	close.BackgroundTransparency = 1
	close.BorderSizePixel = 0
	close.AutoButtonColor = false
	close.Text = ""
	close.ZIndex = 4
	UIKit.clicks(close)
	close.Parent = titleBar

	local closePlate = Instance.new("Frame")
	closePlate.Name = "Plate"
	closePlate.AnchorPoint = Vector2.new(0.5, 0.5)
	closePlate.Position = UDim2.fromScale(0.5, 0.5)
	closePlate.Size = UDim2.fromOffset(CLOSE_PLATE, CLOSE_PLATE)
	closePlate.BorderSizePixel = 0
	-- Not Active: it must not eat the press on its way to the button.
	closePlate.Active = false
	closePlate.Parent = close
	UIKit.corner(closePlate, theme.closeRadius or 10)
	UIKit.stroke(closePlate, theme.closeEdge or keyline, outline)
	UIKit.gradient(closePlate, theme.closeTop or PANEL.CloseTop,
		theme.closeBottom or PANEL.CloseBottom)
	-- A band's close wears the kit's stud tile, as its header does.
	local closeTexture: ImageLabel? = nil
	if theme.band and texture then
		closeTexture = studTexture(closePlate, texture, texture.band, theme.closeRadius or 10, closePlate.ZIndex)
	end

	local closeShade = Instance.new("Frame")
	closeShade.Name = "Shade"
	closeShade.AnchorPoint = Vector2.new(0.5, 1)
	closeShade.Position = UDim2.new(0.5, 0, 1, 0)
	closeShade.Size = UDim2.new(1, 0, 0, 5)
	closeShade.BackgroundColor3 = theme.closeShade or PANEL.CloseShade
	closeShade.BorderSizePixel = 0
	closeShade.Active = false
	closeShade.Parent = closePlate
	UIKit.corner(closeShade, theme.closeRadius or 10)

	-- The red plate's own studs (the reference's studded X), between the face
	-- and the X, clear of the foot.
	local closeStudsOptions = theme.closeStuds
	local closeStuds: Frame? = nil
	if closeStudsOptions then
		local o = table.clone(closeStudsOptions)
		o.inset = o.inset or 4
		o.insetTop = o.insetTop or 4
		o.insetBottom = o.insetBottom or 7
		closeStuds = UIKit.studs(closePlate, o)
	end

	local closeMark = UIKit.outlined(closePlate, "Mark", 22, WHITE, 2.5)
	closeMark.Size = UDim2.fromScale(1, 1)
	-- Two up, so the glyph is centred in the LIT face rather than in the whole
	-- plate including the shade it stands on.
	closeMark.Position = UDim2.new(0, 0, 0, -2)
	closeMark.Text = "X"
	if theme.outline or theme.closeMarkLine then
		local markLine = closeMark:FindFirstChildOfClass("UIStroke")
		if markLine then
			markLine.Color = theme.closeMarkLine or keyline
		end
	end

	--==========================================================================
	-- AND THE PLATE FOLLOWS THE BUTTON'S ZIndex
	--
	-- MarigoldShopUI raises `modal.close.ZIndex` to 8 to clear its own header,
	-- and under GLOBAL ZIndexBehavior a child does not inherit that -- the plate
	-- would have stayed at 5 and drawn UNDER the header the button was raised to
	-- clear. Following it keeps "set the close button's ZIndex" meaning what a
	-- caller expects, which is the only reason that override worked before the
	-- visuals moved off the button.
	--==========================================================================
	local function stackClose()
		closePlate.ZIndex = close.ZIndex + 1
		closeShade.ZIndex = close.ZIndex + 2
		closeMark.ZIndex = close.ZIndex + 3
		local tex = closeTexture
		if tex then
			tex.ZIndex = close.ZIndex + 1
		end
		local studField = closeStuds
		if studField then
			studField.ZIndex = close.ZIndex + 1
		end
	end
	stackClose()
	close:GetPropertyChangedSignal("ZIndex"):Connect(stackClose)

	-- The body keeps the panel-space rect it always had, lifted rim or not: the
	-- shell starts `lift` lower and is `lift` shorter, so both give it back.
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(12, 58 - lift)
	body.Size = UDim2.new(1, -24, 1, -70 + lift)
	body.BackgroundTransparency = 1
	body.ZIndex = 3
	body.Parent = shell

	--==========================================================================
	-- WHAT OVERHANGS THE RIM STILL HOLDS A PRESS
	--
	-- The title and its icon stand partly ABOVE the shell, where only the
	-- dimmer is under them -- and a press there would close the panel. A
	-- transparent button the height of the lift, across the panel, swallows it,
	-- exactly like the click blocker inside.
	--==========================================================================
	if lift > 0 then
		local overhang = Instance.new("TextButton")
		overhang.Name = "RimBlocker"
		overhang.AnchorPoint = Vector2.new(0, 1)
		overhang.Position = UDim2.fromOffset(0, 0)
		overhang.Size = UDim2.new(1, 0, 0, lift + outline)
		overhang.BackgroundTransparency = 1
		overhang.BorderSizePixel = 0
		overhang.AutoButtonColor = false
		overhang.Text = ""
		overhang.Selectable = false
		overhang.ZIndex = 2
		overhang.Parent = shell
	end

	local open = false

	--==========================================================================
	-- A PANEL THAT TAKES THE MENU SIZE ITSELF
	--
	-- The Bag lives in the hotbar's gui, so the size cannot go on the gui: it
	-- goes on this panel's own UIScale, the one the open and close pop through,
	-- and the caller sizes the panel `userScale` times smaller so it keeps its
	-- footprint (HudLayout.bag). 1 for every other panel, which is exactly the
	-- pop they always had.
	--==========================================================================
	local scaleTween: Tween? = nil
	local function setUserScale(s: number)
		if s ~= s or s <= 0 or s == userScale then
			return
		end
		userScale = s
		if open then
			if scaleTween then
				scaleTween:Cancel()
				scaleTween = nil
			end
			scale.Scale = s
		end
		layoutHeader()
	end

	--==========================================================================
	-- ON A COMPACT SCREEN OR A PHONE THE PANEL COVERS THE RAIL (2026-10-09)
	--
	-- Garden and the Bag stand at the left edge's middle since the owner moved
	-- them there, and a panel of 90% of a compact screen (most of a phone's)
	-- reaches under them, where the rail layer would draw them over its body
	-- and take its taps. So while it is open there the layer steps under the
	-- dimmer (UIKit.coverRail), as MenuLayout's panels already do on those
	-- screens -- MenuKit's own (fixedHeader) ask for that themselves. A
	-- desktop's panels stand between the rails and keep them pressable.
	--==========================================================================
	local coverKey = "modal:" .. tostring(options.name)
	local function coverRail(want: boolean)
		local playerGui = gui.Parent
		if options.fixedHeader or not playerGui then
			return
		end
		local covers = false
		if want and gui.AbsoluteSize.X > 0 then
			covers = HudLayout.solve(HudLayout.measure(gui)).compact == true
		end
		UIKit.coverRail(playerGui, coverKey, covers)
	end
	-- A script that re-runs (a Studio sync) builds its panel again shut: never
	-- a rail left under a panel that is gone.
	coverRail(false)

	local function setOpen(want: boolean)
		if open == want then
			return
		end
		open = want
		coverRail(want)
		-- Guarded by the equality check above, so a panel asked to open twice
		-- makes one sound. Two scripts both closing the same panel -- which is
		-- exactly what OpenPanel does when the Index and the Shop trade places
		-- -- is the case this protects.
		SoundKit.play(if want then "PanelOpen" else "PanelClose")
		-- The pop is motion; the fade is not (stillWhenReduced).
		local still = options.stillWhenReduced == true and (motionOff() or (select(2, pcall(function()
			return game:GetService("GuiService").ReducedMotionEnabled
		end)) == true))
		if still and scaleTween then
			scaleTween:Cancel()
			scaleTween = nil
		end
		if want then
			dimmer.Visible = true
			dimmer.BackgroundTransparency = 1
			group.GroupTransparency = 1
			scale.Scale = if still then userScale else 0.92 * userScale
			TweenService:Create(dimmer, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out), { BackgroundTransparency = DIM }):Play()
			TweenService:Create(group, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
			if not still then
				scaleTween = TweenService:Create(scale, TweenInfo.new(FADE, Enum.EasingStyle.Back,
					Enum.EasingDirection.Out), { Scale = userScale })
				scaleTween:Play()
			end
		else
			TweenService:Create(dimmer, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
				Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			if not still then
				scaleTween = TweenService:Create(scale, TweenInfo.new(FADE, Enum.EasingStyle.Quad,
					Enum.EasingDirection.In), { Scale = 0.92 * userScale })
				scaleTween:Play()
			end
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

	local lastContent: number? = nil
	local function fitContent(contentHeight: number)
		lastContent = contentHeight
		-- The gui's own units, which on a TV are its pixels / its TenFoot scale:
		-- of the share of the screen the panel takes (a phone's is less).
		local screen = gui.AbsoluteSize.Y / HudLayout.scaleOf(gui) * share()
		if screen <= 0 then
			return
		end
		-- Never taller than the screen allows, never taller than the cap, never
		-- shorter than a title bar and a row. A panel drawn at a menu size of its
		-- own (followMenuSize) is sized that many times smaller, so it is still
		-- no taller than the screen allows once it is drawn.
		local ceiling = math.min(limit.MaxSize.Y, math.floor(screen * 0.86 / userScale))
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
		local want = math.clamp(contentHeight + MODAL_CHROME, math.min(240, ceiling), ceiling)
		group.Size = UDim2.new(0.9 * share() / userScale, 0, 0, want)
	end

	--==========================================================================
	-- HOW MUCH CONTENT FITS, FOR A PANEL THAT CAN BE LAID OUT SMALLER
	--
	-- fitContent stops a panel at the ceiling whatever it holds, and a panel
	-- with more rows than that is cut off at the bottom -- on the shortest
	-- phones, a safe height of 302, the ceiling is 259 and the room 177. A
	-- confirmation cannot scroll its buttons out of sight, so it asks this
	-- first and picks the layout that fits. The same ceiling as fitContent's,
	-- in the same units; huge before the screen has a size.
	--==========================================================================
	local function contentRoom(): number
		local screen = gui.AbsoluteSize.Y / HudLayout.scaleOf(gui) * share()
		if screen <= 0 then
			return math.huge
		end
		return math.min(limit.MaxSize.Y, math.floor(screen * 0.86 / userScale)) - MODAL_CHROME
	end

	--==========================================================================
	-- A PANEL IN A GUI IT SHARES FOLLOWS THE MENU SIZE ON ITSELF
	--
	-- Sell and the offline card share their guis with pieces of HUD -- the sale
	-- notice, the coins that fly to the cash -- so the size goes on the panel:
	-- the largest of the chosen size that keeps its minimum inside 90% x 86% of
	-- the screen, with its fractional size divided by it so it stays inside the
	-- glass once drawn. Re-applied when the size or the screen changes.
	--==========================================================================
	local following = false
	local function applyFollow()
		local k = HudLayout.scaleOf(gui)
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		-- On a phone, the phone's scale times the chosen one (UIKit.menuScaleFor).
		local phone = UIKit.phoneMenuScale()
		local s = math.max(phone, math.min(UIKit.menuScale() * phone,
			(size.X / k) * 0.9 / limit.MinSize.X, (size.Y / k) * 0.86 / limit.MinSize.Y))
		setUserScale(s)
		local content = lastContent
		if content then
			fitContent(content)
		else
			local part = share()
			group.Size = UDim2.fromScale(0.9 * part / s, 0.82 * part / s)
		end
	end
	local function followMenuSize()
		if following then
			return
		end
		following = true
		UIKit.onMenuSize(applyFollow)
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyFollow)
		applyFollow()
	end

	-- A panel sized by the screen's fractions alone (no fitContent, no size of
	-- its caller's): those fractions again, of the share it takes now -- for a
	-- menu gui whose scale has just changed (a phone: UIKit.menuScaleFor).
	local function fitScreen()
		local part = share()
		group.Size = UDim2.fromScale(0.9 * part / userScale, 0.82 * part / userScale)
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
		setUserScale = setUserScale,
		userScale = function(): number
			return userScale
		end,
		followMenuSize = followMenuSize,
		fitScreen = fitScreen,
		contentRoom = contentRoom,
		lift = lift,
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

--==============================================================================
-- THE CYCLE BUTTON: ONE PRESS, THE NEXT CHOICE (2026-09-26)
--
-- The Garden's and the Bag's SORT and Settings' MENU SIZE, drawn once here so
-- they cannot drift apart.
--
-- A CYCLE, NOT A DROPDOWN. Both panels are CanvasGroups, and a list dropped past
-- a CanvasGroup's edge is clipped by it; a cycle is also the one control a
-- mouse, a thumb and a pad all press the same way. It reads as a button in the
-- panel's own language -- the Bag tabs' gradient, keyline and shade bar -- with
-- its caption (SORT, MENU SIZE) over the choice it is showing, so it says what
-- it is AND where it is. Plain words throughout: no arrow glyphs, which these
-- fonts may draw as boxes. The caller sizes and places it and says what each
-- press does.
--==============================================================================
export type CycleButton = {
	button: TextButton,
	set: (label: string) -> (),
}

function UIKit.cycleButton(parent: Instance, captionText: string, zIndex: number?): CycleButton
	local z = zIndex or 5
	local b = Instance.new("TextButton")
	b.Name = string.gsub(captionText, "%s", "")
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = z
	UIKit.clicks(b)
	b.Parent = parent
	UIKit.corner(b, 10)
	--==========================================================================
	-- THE SECONDARY FACE (2026-10-04, the global UI pass): sky blue with the
	-- family's darker foot in the same gradient and a dark keyline on the
	-- BORDER (a default stroke on this empty-text button outlined nothing), so
	-- it reads as a setting on the white rim, where the dark soil stood.
	--==========================================================================
	local look = GameConfig.BagLook
	local edge = UIKit.stroke(b, look.SkyEdge, 2)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIKit.gradient(b, look.SkyTop, look.SkyBottom)
	do
		local tint = b:FindFirstChildOfClass("UIGradient")
		local cut = 1 - look.FootShare
		if tint then
			tint.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, look.SkyTop),
				ColorSequenceKeypoint.new(cut - 0.02, look.SkyBottom),
				ColorSequenceKeypoint.new(cut, look.SkyBottom:Lerp(look.SkyEdge, 0.38)),
				ColorSequenceKeypoint.new(1, look.SkyBottom:Lerp(look.SkyEdge, 0.38)),
			})
		end
	end

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.BackgroundTransparency = 1
	caption.Position = UDim2.fromOffset(0, 3)
	caption.Size = UDim2.new(1, 0, 0, 11)
	caption.Font = Enum.Font.FredokaOne
	caption.TextSize = 10
	caption.TextColor3 = WHITE
	caption.Text = captionText
	caption.ZIndex = z + 1
	caption.Parent = b
	UIKit.stroke(caption, look.Ink, 1)

	local value = UIKit.outlined(b, "Value", 14, WHITE, 1.5)
	value.Position = UDim2.new(0, 5, 0, 13)
	value.Size = UDim2.new(1, -10, 1, -18)
	value.TextScaled = true
	value.ZIndex = z + 1
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = 8
	fit.Parent = value

	local pop = Instance.new("UIScale")
	pop.Parent = b
	UIKit.cardPop(b, pop, { hoverScale = 1.04, pressScale = 0.96, sound = false })

	return {
		button = b,
		set = function(label: string)
			value.Text = label
		end,
	}
end

return UIKit
