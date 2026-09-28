--!strict
-- Steal a Seed :: WheelDraw
--
-- THE WHEEL'S FACE, DRAWN ONCE FOR THE PANEL AND THE WORLD. Redrawn 2026-09-27
-- to the owner's approved mockup ("Podnappers Spin Wheel Mockup"): the twelve
-- sectors laid out as WheelData.displaySectors, an icon near the rim and the
-- words toward the centre, cream dividers, the dark wood ring with its studded
-- gold rim, and -- on the world's face -- the green SPIN hub. Built into any
-- GuiObject: a ScreenGui (WheelUI's panel) or a SurfaceGui (the wheel behind
-- Marigold's stall). One drawing, so the two can never disagree about which
-- prize is where.
--
-- DRAWN FOR SIBLING ZIndexBehavior. WheelUI's gui and the face's SurfaceGuis
-- both are, so every ZIndex here orders siblings and nothing else.
--
-- EVERY MEASUREMENT IS THE MOCKUP'S. Its wheel is 296 across (the outer
-- circle's radius is 148) and its icons are drawn in a 24-unit box, so a
-- length below is written in those units and scaled to the size asked for.
--
--==============================================================================
-- HOW A SECTOR OF ANY ANGLE IS DRAWN WITHOUT AN IMAGE
--
-- The engine has no pie slice and no conic gradient, and a clipping frame does
-- not clip a ROTATED child (UIKit's lattice note, measured). So nothing here is
-- rotated inside a clip:
--
--   * The face is two still, unrotated halves -- right (0..180 degrees
--     clockwise from 12 o'clock) and left (180..360) -- each ClipsDescendants.
--   * A sector is painted as a HALF-DISC: a circle (UICorner 0.5) whose
--     UIGradient is fully opaque on one side of its middle and fully clear on
--     the other. Only the GRADIENT turns -- Rotation = start - 180 shows the half
--     from `start` clockwise to `start + 180` (calibrated in Studio: 0 shows the
--     left half, 90 the top, 180 the right, 270 the bottom).
--   * Within a half, the sub-sectors are painted in the order they start, each
--     over the last, so each shows from its own start to where the next begins;
--     the half's clip cuts what would spill into the other half.
--
-- TURNING THE WHEEL repaints rather than rotates: setAngle recomputes the
-- sub-sectors for the new angle and moves at most a couple of dozen gradients;
-- the dividers, icons, words and studs sit on one unclipped overlay that does
-- rotate. Measured in Studio 2026-09-27: exact sectors down to a 1.4-degree
-- sliver, in a ScreenGui and in a SurfaceGui alike.
--
--==============================================================================
-- NO WORD IS EVER UPSIDE DOWN
--
-- A sector's words run along its radius: outward on the right half of the
-- screen, inward on the left (the mockup's rule). Which half a sector is on
-- changes as the wheel turns, so setAngle asks again and turns a word over
-- only when its sector crosses 12 or 6 o'clock -- a property write per
-- crossing, nothing more. The "$" on a note and the "?" on the Colossal pod
-- are turned the same way.
--
--==============================================================================
-- THE RAINBOW IS COLOUR ONLY
--
-- The Bloomrunner Trail's sector and star cycle the mockup's rainbow.
-- setRainbow(shift) turns the hue of the gradients' COLOUR keys and nothing
-- else: a sector's gradient Rotation is what cuts its shape, and moving it (or
-- the Offset) would move the sector. WheelUI calls it from the one
-- RenderStepped it keeps only while its panel is open; the world's face never
-- does, so its rainbow stands still.
--==============================================================================

local Shared = script.Parent
local WheelData = require(Shared:WaitForChild("WheelData"))

local WheelDraw = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local WHITE = rgb(255, 255, 255)

-- The mockup's palette, by its own hex.
local P = {
	Wood = rgb(94, 58, 26), -- #5e3a1a  outer ring, hub border
	Gold = rgb(226, 179, 60), -- #e2b33c  rim, hub ring
	Divider = rgb(255, 246, 220), -- #fff6dc
	Stud = rgb(255, 243, 194), -- #fff3c2
	StudEdge = rgb(138, 90, 28), -- #8a5a1c
	WordInk = rgb(27, 42, 24), -- #1b2a18  the sector words' outline
	Ink = rgb(43, 26, 11), -- #2b1a0b  every other outline
	Cream = rgb(255, 243, 194), -- #fff3c2
	HubGreen = rgb(67, 176, 79), -- #43b04f
	HubFoot = rgb(138, 90, 28), -- #8a5a1c
	HubGrey = rgb(124, 127, 120), -- #7c7f78
	HubGreyRing = rgb(184, 154, 85), -- #b89a55
	HubGreyFoot = rgb(110, 74, 24), -- #6e4a18
	HubGreyText = rgb(238, 238, 234), -- #eeeeea
}
WheelDraw.Palette = P

--==============================================================================
-- THE RAINBOW: the mockup's six stops for a surface, and its four for the star
--==============================================================================
type HSV = { h: number, s: number, v: number }

local function hsvOf(list: { Color3 }): { HSV }
	local out: { HSV } = {}
	for _, c in ipairs(list) do
		local h, s, v = c:ToHSV()
		table.insert(out, { h = h, s = s, v = v })
	end
	return out
end

local SURFACE = hsvOf({ rgb(255, 77, 109), rgb(255, 165, 58), rgb(255, 233, 74), rgb(78, 227, 122),
	rgb(63, 183, 255), rgb(168, 107, 255) })
local STAR = hsvOf({ rgb(255, 77, 109), rgb(255, 233, 74), rgb(63, 183, 255), rgb(199, 125, 255) })

-- The rainbow with every hue turned by `shift` (0..1, a whole turn at 1), its
-- stops spread from `from` to `to` along the gradient and held flat past them.
function WheelDraw.rainbow(shift: number, from: number?, to: number?, star: boolean?): ColorSequence
	local stops = if star then STAR else SURFACE
	local a = math.clamp(from or 0, 0, 0.98)
	local b = math.clamp(to or 1, a + 0.01, 1)
	local function at(i: number): Color3
		local s = stops[i]
		return Color3.fromHSV((s.h + shift) % 1, s.s, s.v)
	end
	local keys = {}
	if a > 0 then
		table.insert(keys, ColorSequenceKeypoint.new(0, at(1)))
	end
	for i = 1, #stops do
		table.insert(keys, ColorSequenceKeypoint.new(a + (b - a) * (i - 1) / (#stops - 1), at(i)))
	end
	if b < 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, at(#stops)))
	end
	return ColorSequence.new(keys)
end

--==============================================================================
-- SMALL BUILDERS
--==============================================================================
local function disc(parent: Instance, name: string, diameter: number, colour: Color3, z: number,
	x: number?, y: number?): Frame
	-- `diameter` and the offset are fractions of the parent.
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5 + (x or 0), 0.5 + (y or 0))
	f.Size = UDim2.fromScale(diameter, diameter)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = z
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	return f
end

-- LuckiestGuy with an outline, the face every word on the wheel and its
-- buttons is set in. Sized and placed by the caller.
local function words(parent: Instance, name: string, px: number, colour: Color3, ink: Color3, inkPx: number,
	z: number): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextSize = math.max(6, math.floor(px + 0.5))
	t.TextColor3 = colour
	t.Text = ""
	t.Active = false
	t.ZIndex = z
	t.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = ink
	s.Thickness = math.max(1, inkPx)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	return t
end
WheelDraw.words = words

--==============================================================================
-- THE ICONS, the mockup's shapes in frames
--
-- Each is drawn in a square box of `px` pixels standing for the mockup's
-- 24 units, centred on the box. A shape with a stroke is two frames -- the
-- stroke's colour grown by the stroke underneath, the fill shrunk by it on
-- top -- and every underneath layer of an icon sits below every fill, so a
-- stroke only ever shows round the outside of the whole shape, never where two
-- pieces of it meet (a lightning bolt of two bars reads as one bolt).
--==============================================================================
export type Icon = {
	box: Frame,
	-- Glyphs that must never read upside down on a turning wheel.
	upright: { GuiObject },
	-- The gradients carrying the rainbow (the trail's star).
	rainbow: { UIGradient },
}

local function shape(box: Frame, name: string, x: number, y: number, w: number, h: number, fill: Color3,
	stroke: Color3?, sw: number, radius: number?, rot: number?, layer: number?)
	-- Mockup units: centre (x, y) from the icon's middle, size w x h measured to
	-- the stroke's middle, as an SVG does; `radius` in units too (math.huge for
	-- a pill or a circle).
	local base = (layer or 0) * 2
	local function frame(n: string, fw: number, fh: number, colour: Color3, r: number?, z: number): Frame
		local f = Instance.new("Frame")
		f.Name = n
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5 + x / 24, 0.5 + y / 24)
		f.Size = UDim2.fromScale(fw / 24, fh / 24)
		f.BackgroundColor3 = colour
		f.BorderSizePixel = 0
		f.Active = false
		f.Rotation = rot or 0
		f.ZIndex = z
		f.Parent = box
		if r and r > 0 then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(math.min(0.5, r / math.min(fw, fh)), 0)
			c.Parent = f
		end
		return f
	end
	if stroke and sw > 0 then
		frame(name .. "Edge", w + sw, h + sw, stroke, if radius then radius + sw / 2 else nil, base + 1)
		return frame(name, math.max(0.1, w - sw), math.max(0.1, h - sw), fill,
			if radius then math.max(0, radius - sw / 2) else nil, base + 2)
	end
	return frame(name, w, h, fill, radius, base + 2)
end

local function glyph(box: Frame, text: string, x: number, y: number, units: number, px: number, colour: Color3,
	font: Enum.Font?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = "Glyph"
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5 + x / 24, 0.5 + y / 24)
	t.Size = UDim2.fromScale(units / 24 * 1.3, units / 24 * 1.3)
	t.BackgroundTransparency = 1
	t.Font = font or Enum.Font.LuckiestGuy
	t.TextSize = math.max(6, math.floor(units / 24 * px + 0.5))
	t.Text = text
	t.TextColor3 = colour
	t.Active = false
	t.ZIndex = 20
	t.Parent = box
	return t
end

-- Pod shells: the plain pod is the mockup's green seed; the Rare pod lilac for
-- the species it promises, the Titan warm gold against its red sector.
local POD_SHELL: { [string]: { Color3 } } = {
	pod_common = { rgb(199, 240, 138), rgb(52, 81, 26) },
	pod_rare = { rgb(236, 206, 255), rgb(75, 31, 102) },
	pod_titan = { rgb(255, 212, 130), rgb(107, 42, 18) },
}

function WheelDraw.icon(parent: Instance, reward: WheelData.Reward, px: number): Icon
	local box = Instance.new("Frame")
	box.Name = "Icon"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Size = UDim2.fromOffset(px, px)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Active = false
	box.Parent = parent
	local upright: { GuiObject } = {}
	local rainbow: { UIGradient } = {}

	if reward.kind == "cash" then
		-- A note with a "$" on it; the jackpot's is gold.
		local gold = reward.id == "cash_jackpot"
		local fill = if gold then rgb(255, 222, 120) else rgb(223, 245, 200)
		local ink = if gold then rgb(107, 74, 0) else rgb(29, 90, 44)
		shape(box, "Note", 0, 0, 22, 14, fill, ink, 2, 3)
		table.insert(upright, glyph(box, "$", 0, 0.6, 11, px, ink))
	elseif reward.kind == "speed" then
		-- The lightning bolt: two slanted bars meeting in the middle.
		local fill, ink = rgb(255, 210, 63), rgb(107, 74, 0)
		shape(box, "BoltTop", -1.6, -4.4, 5.6, 15.4, fill, ink, 1.8, 0.8, 35)
		shape(box, "BoltLow", 1.6, 4.2, 5.6, 15.4, fill, ink, 1.8, 0.8, 32)
	elseif reward.kind == "pod" and reward.id == "pod_colossal" then
		-- A dark pod with a white "?": the species is the hatch's to reveal.
		shape(box, "Shell", 0, 0, 23, 30, rgb(18, 11, 24), rgb(185, 163, 214), 1.6, math.huge)
		table.insert(upright, glyph(box, "?", 0, 0.8, 16, px, WHITE))
	elseif reward.kind == "pod" then
		local colours = POD_SHELL[reward.id] or POD_SHELL.pod_common
		shape(box, "Shell", 0, 0, 17, 22, colours[1], colours[2], 2, math.huge)
		shape(box, "Vein", 0, 0.5, 1.6, 13, colours[2], nil, 0, math.huge, nil, 1)
	elseif reward.kind == "boost" and reward.boost == "training" then
		-- A dumbbell: a brown bar through two white plates.
		local ink = rgb(90, 59, 26)
		shape(box, "Bar", 0, 0, 20, 4, ink, nil, 0, 2)
		shape(box, "PlateL", -9.5, 0, 5, 14, WHITE, ink, 1.8, 2, nil, 1)
		shape(box, "PlateR", 9.5, 0, 5, 14, WHITE, ink, 1.8, 2, nil, 1)
	elseif reward.kind == "boost" then
		-- Income: a gold coin with an arrow going up.
		local ink = rgb(107, 74, 0)
		shape(box, "Coin", 0, 0, 20, 20, rgb(255, 210, 63), ink, 2, math.huge)
		shape(box, "Shaft", 0, 0.4, 2.2, 10, ink, nil, 0, math.huge, nil, 1)
		shape(box, "HeadL", -1.9, -3.1, 2.2, 5.9, ink, nil, 0, math.huge, 45, 1)
		shape(box, "HeadR", 1.9, -3.1, 2.2, 5.9, ink, nil, 0, math.huge, -45, 1)
	else
		-- The Bloomrunner Trail: a rainbow star with a white edge in a soft glow.
		local halo = glyph(box, "★", 0, 0, 30, px, rgb(255, 240, 150))
		halo.Name = "Glow"
		halo.TextTransparency = 0.35
		halo.ZIndex = 18
		local haloEdge = Instance.new("UIStroke")
		haloEdge.Color = rgb(255, 233, 74)
		haloEdge.Thickness = math.max(1.5, px * 0.1)
		haloEdge.Transparency = 0.55
		haloEdge.LineJoinMode = Enum.LineJoinMode.Round
		haloEdge.Parent = halo
		local star = glyph(box, "★", 0, 0, 25, px, WHITE)
		star.Name = "Star"
		local edge = Instance.new("UIStroke")
		edge.Color = WHITE
		edge.Thickness = math.max(1, px * 0.06)
		edge.LineJoinMode = Enum.LineJoinMode.Round
		edge.Parent = star
		local g = Instance.new("UIGradient")
		g.Color = WheelDraw.rainbow(0, 0.15, 0.85, true)
		g.Parent = star
		table.insert(rainbow, g)
	end
	return { box = box, upright = upright, rainbow = rainbow }
end

--==============================================================================
-- THE HUB: the mockup's SPIN button
--
-- A green face in a dark wood border inside a gold ring, standing on a darker
-- foot, "SPIN" over the count; grey with "0 / SPINS" when there is nothing to
-- spin. `diameter` is the gold ring's. Nothing here is a button: WheelUI lays
-- one over it, and the world's face just shows it.
--==============================================================================
export type Hub = {
	root: Frame,
	-- "ready" (with the count), "empty" (0 spins) or "plain" (the world's: no
	-- words, because WheelModel's gold hub cap stands in front of its middle).
	setState: (state: string, count: number?) -> (),
}

function WheelDraw.hub(parent: Instance, diameter: number): Hub
	local d = diameter
	local root = Instance.new("Frame")
	root.Name = "Hub"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(d, d)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = false
	root.Parent = parent

	-- The mockup's button is 92 across with a 5 px border, ringed 4 px in gold
	-- (100 in all), on a foot dropped 5 px.
	local foot = disc(root, "Foot", 1, P.HubFoot, 1, 0, 0.05)
	local ring = disc(root, "Ring", 1, P.Gold, 2)
	disc(root, "Border", 0.92, P.Wood, 3)
	local face = disc(root, "Face", 0.82, P.HubGreen, 4)

	local function line(name: string): (TextLabel, TextLabel)
		local drop = words(root, name .. "Drop", 10, P.Ink, P.Ink, d * 0.02, 5)
		drop.AnchorPoint = Vector2.new(0.5, 0.5)
		local top = words(root, name, 10, WHITE, P.Ink, d * 0.02, 6)
		top.AnchorPoint = Vector2.new(0.5, 0.5)
		return top, drop
	end
	local big, bigDrop = line("Top")
	local small, smallDrop = line("Count")

	local function place(label: TextLabel, drop: TextLabel, centre: number, size: number, text: string,
		colour: Color3)
		for _, l in ipairs({ label, drop }) do
			l.Text = text
			l.TextSize = math.max(6, math.floor(d * size + 0.5))
			l.Size = UDim2.fromScale(0.9, size * 1.3)
		end
		label.Position = UDim2.fromScale(0.5, centre)
		drop.Position = UDim2.new(0.5, 0, centre, math.max(1, math.floor(d * 0.03 + 0.5)))
		label.TextColor3 = colour
	end

	local function setState(state: string, count: number?)
		local grey = state == "empty"
		face.BackgroundColor3 = if grey then P.HubGrey else P.HubGreen
		ring.BackgroundColor3 = if grey then P.HubGreyRing else P.Gold
		foot.BackgroundColor3 = if grey then P.HubGreyFoot else P.HubFoot
		local plain = state == "plain"
		for _, l in ipairs({ big, bigDrop, small, smallDrop }) do
			l.Visible = not plain
		end
		if grey then
			place(big, bigDrop, 0.42, 0.32, "0", P.HubGreyText)
			place(small, smallDrop, 0.67, 0.13, "SPINS", P.HubGreyText)
		elseif not plain then
			place(big, bigDrop, 0.4, 0.27, "SPIN", WHITE)
			place(small, smallDrop, 0.65, 0.16, "×" .. tostring(count or 0), P.Cream)
		end
	end
	setState("ready", 0)
	return { root = root, setState = setState }
end

--==============================================================================
-- THE WHEEL
--==============================================================================
export type Drawn = {
	root: Frame,
	-- Turn the whole wheel `deg` degrees clockwise from how it was drawn. To bring
	-- the wheel's point `a` (WheelData's display angles) under the pointer at the
	-- top, setAngle(-a).
	setAngle: (deg: number) -> (),
	angle: () -> number,
	-- The rainbow's hue, turned by `shift` (0..1): the trail's sector and star.
	setRainbow: (shift: number) -> (),
	-- The world's hub, when the options asked for one.
	hub: Hub?,
}

export type Options = {
	-- Words on the sectors (default on).
	labels: boolean?,
	-- The still green hub, without words (the world's face, round WheelModel's
	-- gold cap; the panel lays its own SPIN button over WheelDraw.hub).
	hub: boolean?,
}

type Sub = { start: number, finish: number, reward: WheelData.Reward }
type Turning = { mid: number, words: GuiObject?, upright: { GuiObject } }

local WHITE_SEQUENCE = ColorSequence.new(WHITE)

-- Two lines where the sector's words have a space: the amount big over the word
-- small ("+1,000" / "SPEED"), as the mockup sets them.
local function splitWords(label: string): (string, string?)
	local first, rest = string.match(label, "^(%S+)%s+(.+)$")
	if first and rest then
		return first, rest
	end
	return label, nil
end

function WheelDraw.build(parent: Instance, size: number, options: Options?): Drawn
	local opts: Options = options or {}
	local sectors = WheelData.displaySectors()
	-- Pixels per mockup unit.
	local k = size / 296

	local root = Instance.new("Frame")
	root.Name = "Wheel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(size, size)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = false
	root.Parent = parent

	-- The wood ring, the gold rim, and the cream line where the sectors end.
	disc(root, "Wood", 1, P.Wood, 1)
	disc(root, "Gold", 144 / 148, P.Gold, 2)
	disc(root, "SectorEdge", 139.25 / 148, P.Divider, 3)

	-- The two still halves and their pools of half-discs, inside the cream line.
	local inner = 136.75 / 148 * size
	local innerR = inner / 2
	local pools: { { Frame } } = { {}, {} }
	for h = 1, 2 do
		local half = Instance.new("Frame")
		half.Name = if h == 1 then "RightHalf" else "LeftHalf"
		half.BackgroundTransparency = 1
		half.BorderSizePixel = 0
		half.ClipsDescendants = true
		half.AnchorPoint = Vector2.new(if h == 1 then 0 else 1, 0.5)
		half.Position = UDim2.fromScale(0.5, 0.5)
		half.Size = UDim2.fromOffset(innerR, inner)
		half.ZIndex = 4
		half.Parent = root
		-- One more disc than prizes: a sector can be split where the half ends.
		for i = 1, #sectors + 1 do
			local d = Instance.new("Frame")
			d.Name = "Fill" .. i
			d.Size = UDim2.fromOffset(inner, inner)
			d.Position = UDim2.fromOffset(if h == 1 then -innerR else 0, 0)
			d.BorderSizePixel = 0
			d.Visible = false
			d.ZIndex = i
			d.Parent = half
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = d
			local gradient = Instance.new("UIGradient")
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4999, 0),
				NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1),
			})
			gradient.Parent = d
			pools[h][i] = d
		end
	end

	-- The overlay that turns: dividers, icons, words and the rim's studs.
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromOffset(size, size)
	face.BackgroundTransparency = 1
	face.BorderSizePixel = 0
	face.Active = false
	face.ZIndex = 5
	face.Parent = root

	local function spoke(name: string, angle: number, z: number): Frame
		-- A full-size holder turned about the wheel's centre (a GuiObject turns
		-- about its own middle); what it holds sits straight up from the centre,
		-- so it ends up along `angle`.
		local holder = Instance.new("Frame")
		holder.Name = name
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Active = false
		holder.Rotation = angle
		holder.ZIndex = z
		holder.Parent = face
		return holder
	end

	local turning: { Turning } = {}
	local starGradients: { UIGradient } = {}
	local lineW = math.max(2, math.floor(2.5 * k + 0.5))

	for _, sector in ipairs(sectors) do
		local divider = spoke("Divider", sector.start, 1)
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.AnchorPoint = Vector2.new(0.5, 1)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = UDim2.fromOffset(lineW, 138 * k)
		line.BackgroundColor3 = P.Divider
		line.BorderSizePixel = 0
		line.Active = false
		line.Parent = divider

		local reward = sector.reward
		local span = sector.finish - sector.start
		local arm = spoke("Sector_" .. reward.id, sector.mid, 2)
		local entry: Turning = { mid = sector.mid, words = nil, upright = {} }

		-- The icon near the rim, pointing out.
		local iconPx = 24 * k * (if reward.kind == "trail" then 1.05 elseif reward.id == "pod_colossal" then 1 else 0.95)
		local icon = WheelDraw.icon(arm, reward, iconPx)
		icon.box.Position = UDim2.new(0.5, 0, 0.5, -116 * k)
		for _, g in ipairs(icon.upright) do
			table.insert(entry.upright, g)
		end
		for _, g in ipairs(icon.rainbow) do
			table.insert(starGradients, g)
		end

		-- The words toward the centre, along the radius, where the sector is wide
		-- enough to hold them (the two narrowest, the Colossal pod and the trail,
		-- are icon-only, as in the mockup).
		if opts.labels ~= false and span >= 14 then
			local first, second = splitWords(reward.label)
			local bigPx = (if second then 12.5 else 14) * k
			local smallPx = 10.5 * k
			local thick = if second then bigPx + smallPx + 2 * k else bigPx + 2 * k
			local length = 50 * k
			local holder = Instance.new("Frame")
			holder.Name = "Words"
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.new(0.5, 0, 0.5, -79 * k)
			holder.Size = UDim2.fromOffset(length, thick)
			holder.BackgroundTransparency = 1
			holder.BorderSizePixel = 0
			holder.Active = false
			holder.ZIndex = 3
			holder.Parent = arm
			local function wordLine(name: string, text: string, px: number, y: number): TextLabel
				local l = words(holder, name, px, WHITE, P.WordInk, 1.5 * k, 3)
				l.Text = text
				l.Position = UDim2.fromOffset(0, y)
				l.Size = UDim2.new(1, 0, 0, px + 1)
				l.TextScaled = true
				local fit = Instance.new("UITextSizeConstraint")
				fit.MaxTextSize = math.max(6, math.floor(px + 0.5))
				fit.MinTextSize = 6
				fit.Parent = l
				return l
			end
			wordLine("Big", first, bigPx, 0)
			if second then
				wordLine("Small", second, smallPx, bigPx + 1 * k)
			end
			entry.words = holder
		end
		table.insert(turning, entry)
	end

	-- The studs round the gold rim: 24, cream with a brown edge.
	for i = 0, 23 do
		local holder = spoke("Stud", i * 15, 4)
		disc(holder, "StudEdge", 6.2 / 296, P.StudEdge, 1, 0, -144 / 296)
		disc(holder, "Stud", 4.2 / 296, P.Stud, 2, 0, -144 / 296)
	end

	local hub: Hub? = nil
	if opts.hub then
		local h = WheelDraw.hub(root, size * 100 / 296)
		h.root.ZIndex = 6
		h.setState("plain")
		hub = h
	end

	--==========================================================================
	-- PAINTING AT AN ANGLE
	--==========================================================================
	local current = 0
	local shift = 0
	-- The discs painting the rainbow sector right now, and each one's arc; and
	-- every disc whose gradient still carries it, to be put back to plain white.
	local rainbowDiscs: { { disc: Frame, span: number } } = {}
	local tinted: { [Frame]: boolean } = {}

	local function tintRainbow()
		for _, r in ipairs(rainbowDiscs) do
			local g = r.disc:FindFirstChildOfClass("UIGradient")
			if g then
				-- Across the wedge at the rim: from its far edge to its start line.
				local width = math.sin(math.rad(math.min(r.span, 90))) / 2
				g.Color = WheelDraw.rainbow(shift, 0.5 - width, 0.5)
			end
		end
	end

	local function paint(angle: number)
		local subs: { { Sub } } = { {}, {} }
		local function add(s: number, e: number, reward: WheelData.Reward)
			-- [s, e) with 0 <= s < e <= 360, split where the halves meet.
			if s < 180 then
				table.insert(subs[1], { start = s, finish = math.min(e, 180), reward = reward })
			end
			if e > 180 then
				table.insert(subs[2], { start = math.max(s, 180), finish = e, reward = reward })
			end
		end
		for _, sector in ipairs(sectors) do
			local s = (sector.start + angle) % 360
			local e = s + (sector.finish - sector.start)
			if e <= 360 then
				add(s, e, sector.reward)
			else
				add(s, 360, sector.reward)
				add(0, e - 360, sector.reward)
			end
		end
		table.clear(rainbowDiscs)
		for h = 1, 2 do
			local list = subs[h]
			table.sort(list, function(a: Sub, b: Sub): boolean
				return a.start < b.start
			end)
			for i, d in ipairs(pools[h]) do
				local sub = list[i]
				if sub then
					d.Visible = true
					d.ZIndex = i
					local gradient = d:FindFirstChildOfClass("UIGradient")
					if gradient then
						gradient.Rotation = sub.start - 180
					end
					if sub.reward.rainbow then
						d.BackgroundColor3 = WHITE
						tinted[d] = true
						-- To where the next sector begins, which is what shows.
						local nextSub = list[i + 1]
						local stop = if nextSub then nextSub.start else (if h == 1 then 180 else 360)
						table.insert(rainbowDiscs, { disc = d, span = stop - sub.start })
					else
						d.BackgroundColor3 = sub.reward.colour
						if tinted[d] and gradient then
							gradient.Color = WHITE_SEQUENCE
							tinted[d] = nil
						end
					end
				else
					d.Visible = false
				end
			end
		end
		tintRainbow()
		face.Rotation = angle
		-- Keep every word and glyph the right way up for where it now is.
		for _, t in ipairs(turning) do
			local onScreen = (t.mid + angle) % 360
			local w = t.words
			if w then
				local want = if onScreen < 180 then -90 else 90
				if w.Rotation ~= want then
					w.Rotation = want
				end
			end
			local flip = if onScreen > 90 and onScreen < 270 then 180 else 0
			for _, g in ipairs(t.upright) do
				if g.Rotation ~= flip then
					g.Rotation = flip
				end
			end
		end
	end

	paint(0)

	return {
		root = root,
		setAngle = function(deg: number)
			current = deg % 360
			paint(current)
		end,
		angle = function(): number
			return current
		end,
		setRainbow = function(s: number)
			shift = s % 1
			tintRainbow()
			local star = WheelDraw.rainbow(shift, 0.15, 0.85, true)
			for _, g in ipairs(starGradients) do
				g.Color = star
			end
		end,
		hub = hub,
	}
end

return WheelDraw
