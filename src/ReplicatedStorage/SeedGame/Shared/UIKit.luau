--!strict
-- Steal a Seed :: UIKit
--
-- The few pieces of screen furniture that more than one client builds.
--
--==============================================================================
-- WHY THIS EXISTS
--
-- Four surfaces wanted a studded texture and three wanted the same gold rail
-- button. Four hand-rolled stud grids is how the shop panel and the Index button
-- end up studded at different pitches, and three hand-rolled buttons is how one
-- of them quietly keeps a green stroke after the other two go gold.
--
-- Same reasoning as GameConfig.compact: the second copy of a thing is where the
-- drift starts, so there is one copy.
--
-- NOT a *Service, and not in GameConfig. GameConfig holds names, structure and
-- the curves; it does not build Instances. This does nothing but build them.
--==============================================================================

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local UIKit = {}

local RAIL = GameConfig.Rail

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
-- STUDS
--
-- A grid of small round frames, not a tiled image: nothing in this repo is
-- placed by hand and an asset id is a thing that can rot. The grid is sized for
-- the box it is given and CLIPPED by it, so a surface that turns out shorter
-- than expected simply shows fewer studs and nothing has to be rebuilt.
--
-- Built once and never touched again. There is no per-frame work here at all,
-- which is the half of Rule 8 that actually matters on a phone -- the instance
-- count is paid at login, once.
--
--==============================================================================
-- THE RIM IS WHAT MAKES IT READ AS A STUD
--
-- `rim` is optional and the difference between a stud and a dot. A pale disc on
-- a bright plate separates by almost nothing in LUMINANCE -- the rail's first
-- attempt measured a delta of 7 and the owner said, correctly, that it did not
-- look studded. A dark ring where the cylinder meets the plate is what an eye
-- catches, and on gold that is a delta of about 68.
--
-- Passed nil on dark surfaces, where a dark ring would add instances and no
-- contrast. The shop panel does that: it wants quiet texture behind cards, not
-- a moulded surface.
--==============================================================================
export type StudOptions = {
	pitch: number?,
	size: number?,
	colour: Color3?,
	transparency: number?,
	rim: Color3?,
	rimThickness: number?,
}

function UIKit.studs(parent: GuiObject, width: number, height: number,
	options: StudOptions?): Frame
	local opts: StudOptions = options or {}
	local studPitch = opts.pitch or RAIL.StudPitch
	local studSize = opts.size or RAIL.StudSize

	local field = Instance.new("Frame")
	field.Name = "Studs"
	field.Size = UDim2.fromScale(1, 1)
	field.BackgroundTransparency = 1
	-- Behind everything else in the parent, and never in the way of a click:
	-- a Frame is not Active, so it does not swallow input.
	field.ZIndex = 0
	field.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(studSize, studSize)
	grid.CellPadding = UDim2.fromOffset(studPitch - studSize, studPitch - studSize)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = field

	local pad = Instance.new("UIPadding")
	local inset = math.max(2, math.floor((studPitch - studSize) / 2))
	pad.PaddingLeft = UDim.new(0, inset)
	pad.PaddingTop = UDim.new(0, inset)
	pad.Parent = field

	local columns = math.max(1, math.ceil(width / studPitch))
	local rows = math.max(1, math.ceil(height / studPitch))
	for i = 1, columns * rows do
		local stud = Instance.new("Frame")
		stud.Name = "Stud"
		stud.LayoutOrder = i
		stud.BackgroundColor3 = opts.colour or RAIL.Stud
		stud.BackgroundTransparency = opts.transparency or RAIL.StudTransparency
		stud.BorderSizePixel = 0
		stud.ZIndex = 0
		stud.Parent = field
		UIKit.corner(stud, math.max(1, math.floor(studSize / 2)))
		if opts.rim then
			UIKit.stroke(stud, opts.rim, opts.rimThickness or 1,
				opts.transparency or RAIL.StudTransparency)
		end
	end

	return field
end

--==============================================================================
-- THE RAIL BUTTON
--
-- Every HUD navigation button is this: a gold plate, studded, black-outlined.
-- Index and Shop on the left, Garden on the right, all identical because they
-- all come out of here.
--
-- The gold is sampled, not invented. `rgb(255,238,119)` is the highlight off the
-- reference's gold coin and `rgb(255,216,0)` is the plus-badge gold off the HUD
-- shot. No darker lip under it: the reference's own gold card has none either --
-- the black outline is what gives it an edge, and a lip would be inventing depth
-- the source does not have.
--
-- Returns the button. Callers parent their own icon and label into it; anything
-- they add lands above the studs, which sit at ZIndex 0.
--==============================================================================
function UIKit.railButton(parent: Instance, width: number, height: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = "RailButton"
	button.Size = UDim2.fromOffset(width, height)
	button.BackgroundColor3 = RAIL.GoldTop
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = parent

	UIKit.corner(button, RAIL.CornerRadius)
	UIKit.gradient(button, RAIL.GoldTop, RAIL.GoldBottom)
	UIKit.stroke(button, RAIL.Outline, RAIL.OutlineThickness)

	--======================================================================
	-- THE STUDS GET THEIR OWN CLIPPED SURFACE
	--
	-- Not ClipsDescendants on the BUTTON. Both rail buttons that carry a
	-- badge hang it half outside their own corner on purpose, and clipping
	-- the button would cut it in half. So the clipping lives on an inner
	-- frame that only the studs are inside.
	--======================================================================
	local surface = Instance.new("Frame")
	surface.Name = "Surface"
	surface.Size = UDim2.fromScale(1, 1)
	surface.BackgroundTransparency = 1
	surface.ClipsDescendants = true
	surface.ZIndex = 0
	surface.Parent = button
	UIKit.corner(surface, RAIL.CornerRadius)
	UIKit.studs(surface, width, height, {
		rim = RAIL.StudRim,
		rimThickness = RAIL.StudRimThickness,
	})

	return button
end

return UIKit
