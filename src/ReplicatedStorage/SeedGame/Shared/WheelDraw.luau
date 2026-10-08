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
-- THE PRIZE ART (2026-10-04): coins on the cash slices, the owner's Speed
-- icon, real pod silhouettes, and the Titan and Colossal lettering -- see THE
-- PRIZE ART below. Decoration only: every prize, amount, weight and landing is
-- still WheelData's, untouched.
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
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SizedIcon = require(Shared:WaitForChild("SizedIcon"))
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

--==============================================================================
-- THE PRIZE ART (2026-10-04, the owner's spin-wheel brief)
--
-- Every picture below is drawn in frames, in the same outlined cartoon style as
-- the rest of the face, except the Speed icon, which is the owner's upload.
--
--   cash    small stacks of gold coins near the rim -- one stack for the small
--           prize, two for the middle one, three for the jackpot -- and a
--           scatter of muted coins across the slice behind the words
--           (coinLayout). Both grow with the amount; both are capped.
--   speed   GameConfig.SourceIcons.speed, the owner's plain Speed shoe that
--           the Shop also uses as the one Speed icon (its small version
--           wherever a picture draws at 40 px or less, SizedIcon): one for the
--           small prize, a tidy cluster of three for the large one. Decoration,
--           not a multiplier -- the amount is in the words. Until the picture
--           has loaded, the old bolt stands in, so a slice is never blank.
--   pods    black silhouettes of REAL game pods with an ivory rim, a soft
--           outline in the pod's size colour and one "?". The silhouettes are
--           the pool's own biomes (podCluster): a prize whose species come
--           from Greenhollow and Dustbowl shows those two pods, and the Rare
--           pod, whose pool spans all five biomes, shows three different ones
--           -- so no prize promises a biome it cannot give. A Titan's pods
--           wear the split crown, a Colossal's are cracked open with light
--           inside, as the models are. The creature is never shown.
--           POD BY POD, the owner's uploaded silhouette replaces the frames
--           wherever its biome has one (GameConfig.WheelPodArt: Greenhollow,
--           Tanglemire and Starbloom since 2026-10-04). Each picture carries
--           its own rim and "?", so none gets a second one; a biome with no
--           upload yet (Dustbowl) keeps its frames, never another's picture.
--
-- TITAN AND COLOSSAL LETTERING (prestige): warm red to gold with a slow light
-- travelling along it, and violet to gold with a brighter sheen and a soft
-- glow round the letters. The light is a precomputed list of colour frames
-- stepped by the CALLER (glint) -- nothing here runs per frame, and only the
-- words' own gradients change: the sector fills' gradients, which cut the
-- slices, are never touched. Reduced motion holds the plain ramp still.
--
-- KEEPING INSIDE THE SLICE. A decoration hangs on its sector's own arm, so it
-- turns with the sector and can never drift into a neighbour while the wheel
-- spins. Each one is laid out inside the wedge: clear of both dividers, of the
-- hub and of the rim (WheelArtSpec measures every frame against its wedge).
-- An icon that must stay readable turns over as a whole (Icon.upright) when
-- its sector passes through the lower half, like the words do.
--==============================================================================
local SPEED_ICON = GameConfig.SourceIcons.speed

-- How the art learns a picture has loaded: set by a client before it draws
-- (WheelUI hands in UIKit.whenPictureLoads). Nil on the server.
WheelDraw.whenLoaded = nil :: ((ImageLabel, (boolean) -> ()) -> ())?

-- Mockup units: the coloured fill ends 136.75 from the centre, the hub's gold
-- ring at 50; an icon stands at 116, its box 24 across; the words run from 54
-- to 104 along the middle; a divider is 2.5 wide.
local FILL_R = 136.75
local ICON_R = 116
local DIVIDER_HALF = 1.25
local EDGE_MARGIN = 0.9

local COIN = {
	Ink = rgb(107, 74, 0),
	Rim = rgb(214, 146, 30),
	Face = rgb(255, 206, 72),
	Top = rgb(255, 226, 120),
	Shine = rgb(255, 246, 204),
}

-- How rich a cash prize's art is: 1 the small prize, 2, 3 the jackpot.
function WheelDraw.cashTier(amount: number?): number
	local a = amount or 0
	if a >= 50000 then
		return 3
	elseif a >= 10000 then
		return 2
	end
	return 1
end

-- The background coins at most, and the coins in each stack, by cash tier.
WheelDraw.CoinPattern = { 6, 9, 12 }
WheelDraw.CoinStacks = { { 3 }, { 4, 3 }, { 3, 5, 4 } }

-- How many Speed icons: one for a small prize, three for a large one.
function WheelDraw.speedCount(amount: number?): number
	local a = amount or 0
	if a >= 10000 then
		return 3
	elseif a >= 5000 then
		return 2
	end
	return 1
end

--==============================================================================
-- WHERE A SLICE'S BACKGROUND COINS GO (pure; WheelArtSpec checks it)
--
-- A polar lattice inside the wedge: rows every 11 units out from the hub,
-- staggered, each coin kept a divider's half-width and a margin inside both
-- edges, clear of the icon's box. Coins clear of the words come first; only a
-- slice too narrow for that puts the rest behind the words, where the dark
-- outline of the amount keeps it readable. Then an even pick of `want`.
-- `r` and the lateral `x` are mockup units; `a` is degrees from the middle.
--==============================================================================
export type Coin = { r: number, x: number, a: number, d: number }

function WheelDraw.coinLayout(span: number, tier: number, wordsHalf: number?): { Coin }
	local t = math.clamp(tier, 1, 3)
	local want = WheelDraw.CoinPattern[t]
	local d = if t >= 3 then 6.2 else 7.2
	local step = d + 3.4
	local half = math.rad(span / 2)
	local wordsW = wordsHalf or 8
	local clear: { Coin } = {}
	local behind: { Coin } = {}
	local row = 0
	local r = 62
	while r + d / 2 <= FILL_R - 1.5 do
		row += 1
		local room = (d / 2 + DIVIDER_HALF + EDGE_MARGIN) / r
		if room < 1 and half > math.asin(room) then
			local lateral = r * math.sin(half - math.asin(room))
			local offset = if row % 2 == 0 then step / 2 else 0
			for j = -6, 6 do
				local x = offset + j * step
				if math.abs(x) <= lateral then
					local inIcon = r > ICON_R - 13 - d / 2 and r < ICON_R + 13 + d / 2 and math.abs(x) < 13 + d / 2
					if not inIcon then
						local coin = { r = r, x = x, a = math.deg(math.asin(x / r)), d = d }
						local inWords = r < 104 + d / 2 and r > 54 - d / 2 and math.abs(x) < wordsW + d / 2
						table.insert(if inWords then behind else clear, coin)
					end
				end
			end
		end
		r += 11
	end
	local function spread(list: { Coin }, n: number): { Coin }
		if #list <= n then
			return list
		end
		local out: { Coin } = {}
		for i = 1, n do
			table.insert(out, list[math.floor(1 + (i - 1) * (#list - 1) / math.max(1, n - 1) + 0.5)])
		end
		return out
	end
	local picked = spread(clear, want)
	if #picked < want then
		for _, c in ipairs(spread(behind, want - #picked)) do
			table.insert(picked, c)
		end
	end
	return picked
end

--==============================================================================
-- SMALL PIECES OF THE ART
--==============================================================================
-- A frame centred at (x, y) in the 24-unit icon box, `w` x `h` units, rounded
-- by `radius` units (math.huge: a pill or a circle), turned by `rot`.
local function blob(box: GuiObject, name: string, x: number, y: number, w: number, h: number, radius: number,
	rot: number, colour: Color3, z: number, transparency: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5 + x / 24, 0.5 + y / 24)
	f.Size = UDim2.fromScale(math.max(0.05, w) / 24, math.max(0.05, h) / 24)
	f.BackgroundColor3 = colour
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Active = false
	f.Rotation = rot
	f.ZIndex = z
	f.Parent = box
	if radius > 0 then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(math.min(0.5, radius / math.max(0.05, math.min(w, h))), 0)
		c.Parent = f
	end
	return f
end

-- One coin seen from the side, in a stack: its edge, its milled side and its
-- lit top, each coin drawn over the one under it.
local function stackCoin(box: GuiObject, x: number, y: number, w: number, z: number)
	local h = w * 0.46
	blob(box, "CoinEdge", x, y, w + 1.3, h + 1.3, math.huge, 0, COIN.Ink, z)
	blob(box, "CoinSide", x, y, w, h, math.huge, 0, COIN.Rim, z + 1)
	blob(box, "CoinTop", x, y - h * 0.16, w * 0.86, h * 0.56, math.huge, 0, COIN.Top, z + 2)
end

local function coinIcon(box: Frame, reward: WheelData.Reward, px: number)
	local tier = WheelDraw.cashTier(reward.amount)
	local stacks = WheelDraw.CoinStacks[tier]
	local w = 8.6
	local xs = if #stacks == 1 then { -2.6 } elseif #stacks == 2 then { -4.6, 4.6 } else { -7.6, 0, 7.6 }
	-- Where each stack sits in the drawing order: the middle one in front.
	local order = if #stacks == 3 then { 1, 3, 2 } else { 1, 2, 3 }
	local base = 6.4
	for rank, s in ipairs(order) do
		local n = stacks[s]
		if n then
			for i = 0, n - 1 do
				stackCoin(box, xs[s], base - i * 2.4, w, rank * 30 + i * 3)
			end
		end
	end
	if tier == 1 then
		-- One coin face-on beside the stack, a "$" on it.
		blob(box, "LooseEdge", 6.4, 2.6, 10, 10, math.huge, 0, COIN.Ink, 100)
		blob(box, "LooseFace", 6.4, 2.6, 8.2, 8.2, math.huge, 0, COIN.Face, 101)
		local mark = glyph(box, "$", 6.4, 3.0, 8, px, COIN.Ink)
		mark.ZIndex = 102
	elseif tier == 3 then
		-- The jackpot's glint: a four-point sparkle over the stacks.
		for i, rot in ipairs({ 0, 90 }) do
			blob(box, "Sparkle" .. i, 8.4, -6.6, 1.4, 7, 0.7, rot + 45, COIN.Shine, 120)
		end
		blob(box, "SparkleHeart", 8.4, -6.6, 2.4, 2.4, math.huge, 0, WHITE, 121)
	end
end

local function speedIcon(box: Frame, reward: WheelData.Reward)
	-- The bolt the wheel always had, until the owner's picture has loaded.
	local fallback = Instance.new("Frame")
	fallback.Name = "Fallback"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundTransparency = 1
	fallback.BorderSizePixel = 0
	fallback.Active = false
	fallback.ZIndex = 1
	fallback.Parent = box
	local fill, ink = rgb(255, 210, 63), rgb(107, 74, 0)
	shape(fallback, "BoltTop", -1.6, -4.4, 5.6, 15.4, fill, ink, 1.8, 0.8, 35)
	shape(fallback, "BoltLow", 1.6, 4.2, 5.6, 15.4, fill, ink, 1.8, 0.8, 32)

	local count = WheelDraw.speedCount(reward.amount)
	-- Back to front: x, y, size in units.
	local spots = if count >= 3 then { { -6.8, -3.6, 13 }, { 6.8, -3.6, 13 }, { 0, 2.6, 16.5 } }
		elseif count == 2 then { { 4.6, -2, 14 }, { -3.8, 1.8, 15.5 } }
		else { { 0, 0, 22 } }
	local pictures: { ImageLabel } = {}
	for i, spot in ipairs(spots) do
		local image = Instance.new("ImageLabel")
		image.Name = "Speed" .. i
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5 + spot[1] / 24, 0.5 + spot[2] / 24)
		image.Size = UDim2.fromScale(spot[3] / 24, spot[3] / 24)
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Fit
		image.Image = SPEED_ICON
		image.ZIndex = 10 + i
		image.Active = false
		image.Parent = box
		-- The owner's small shoe wherever this draws at 40 px or less.
		SizedIcon.follow(image)
		table.insert(pictures, image)
	end
	-- IsLoaded raises no change event to rely on, so a client hands in its
	-- watcher (WheelUI: UIKit.whenPictureLoads, which polls); without one, the
	-- bolt goes only if the picture is already here.
	local watch = WheelDraw.whenLoaded
	local left = #pictures
	for _, image in ipairs(pictures) do
		if image.IsLoaded then
			left -= 1
		elseif watch then
			watch(image, function(ok: boolean)
				if ok then
					left -= 1
					if left <= 0 then
						fallback.Visible = false
					end
				end
			end)
		end
	end
	if left <= 0 then
		fallback.Visible = false
	end
end

--==============================================================================
-- THE POD SILHOUETTES, FROM THE MODELS (CreatureModel.BuildPod)
--
-- Each in the 24-unit box with its base at y = 8.5, after the models and the
-- owner's approved reference silhouettes (output/imagegen/podnappers-spinwheel-
-- actual-pod-silhouettes-v2.png): `{ "c", x, y, d }` a circle, `{ "r", x, y, w,
-- h, radius, rot }` a rounded block. `bands` are drawn a lighter charcoal over
-- the black (a belt, a clay ring). `body` is where the "?" sits.
--
--   greenhollow  a squat ball, a belt round its waist, a bent stem on top
--   dustbowl     a squat clay urn: a ring round it, a neck, a lip, a jagged crown
--   tanglemire   two stacked lobes, a bulb, an angled plate and two little arms
--   emberroot    a furnace nut: chamber, flat collar, two shoulder facets
--   starbloom    a round seed with a second lobe, a bent antenna and its bulb,
--                and a rod out to each side
--
-- The two biomes the Titan and Colossal prizes come from have those tiers'
-- crowns too: split for a Titan, lifted off a glowing core for a Colossal.
--==============================================================================
type Shape = { any }
type Silhouette = {
	body: { number },
	common: { Shape },
	titan: { Shape }?,
	colossal: { Shape }?,
	core: { Shape }?,
	bands: { Shape }?,
}

local GREENHOLLOW_BODY: { Shape } = { { "r", 0, 1.4, 15.4, 14.2, 7.1, 0 }, { "r", 0, 2.8, 16.8, 2.6, 1.3, 0 } }
local DUSTBOWL_BODY: { Shape } = { { "r", 0, 3.6, 13.6, 9.8, 4.6, 0 }, { "r", 0, -2.4, 8.6, 4.6, 2, 0 } }

local function with(base: { Shape }, more: { Shape }): { Shape }
	local out = table.clone(base)
	for _, sh in ipairs(more) do
		table.insert(out, sh)
	end
	return out
end

local SILHOUETTES: { [string]: Silhouette } = {
	greenhollow = {
		body = { 0, 1.2, 13 },
		common = with(GREENHOLLOW_BODY, { { "r", 1.1, -7, 1.6, 4, 0.8, 22 }, { "r", -0.8, -9.3, 1.5, 4.2, 0.75, -58 } }),
		titan = with(GREENHOLLOW_BODY, { { "c", -3.4, -5.2, 5.4 }, { "c", 3.4, -5.2, 5.4 } }),
		colossal = with(GREENHOLLOW_BODY, { { "r", 1.8, -8.6, 9.6, 4.6, 2.3, 16 } }),
		core = { { "c", -0.2, -5.6, 4.6 } },
		bands = { { "r", 0, 2.8, 16.2, 1.5, 0.75, 0 } },
	},
	dustbowl = {
		body = { 0, 3.4, 10 },
		common = with(DUSTBOWL_BODY, {
			{ "r", 0, -4.9, 10.6, 2.2, 1.1, 0 }, { "r", -2.2, -7, 3.4, 3.4, 0.5, 45 }, { "r", 1, -7.4, 3, 3, 0.5, 30 },
		}),
		titan = with(DUSTBOWL_BODY, {
			{ "r", 0, -4.9, 10.6, 2.2, 1.1, 0 }, { "r", -3.6, -6.8, 5.2, 2, 1, -28 }, { "r", 3.6, -6.8, 5.2, 2, 1, 28 },
		}),
		colossal = with(DUSTBOWL_BODY, { { "r", 1.2, -8.6, 8.2, 2.6, 1.2, -12 } }),
		core = { { "c", 0, -5.8, 4.4 } },
		bands = { { "r", 0, 3.2, 13.8, 1.7, 0.85, 0 } },
	},
	tanglemire = {
		body = { 0.6, 2.6, 10.5 },
		common = {
			{ "c", 0.6, 2.5, 12 }, { "c", -0.6, -3.2, 9.4 }, { "c", -0.8, -8.6, 4.6 }, { "r", 4.6, -6.6, 4.6, 4.6, 0.5, 45 },
			{ "r", -7.2, 1.6, 1.6, 5.2, 0.8, 0 }, { "r", -7.2, -1.4, 2.8, 2.8, 0.6, 0 },
			{ "r", 7.4, 3.6, 1.6, 4.8, 0.8, 0 }, { "r", 7.4, 0.8, 2.8, 2.8, 0.6, 0 },
		},
	},
	emberroot = {
		body = { 0, 3, 10.5 },
		common = {
			{ "r", 0, 3, 12, 11, 4.8, 0 }, { "r", 0, -3, 9.4, 3.2, 1.4, 0 },
			{ "r", -4.6, -2, 3.6, 4, 0.8, -18 }, { "r", 4.6, -2, 3.6, 4, 0.8, 18 },
		},
		bands = { { "r", 0, 3, 12.2, 1.5, 0.75, 0 } },
	},
	starbloom = {
		body = { -0.4, 3, 10.5 },
		common = {
			{ "c", -0.4, 2.8, 11.4 }, { "c", 2.4, -1.4, 7.4 }, { "r", 2.6, -6.4, 1.5, 5.4, 0.75, 14 },
			{ "r", 4, -9.8, 1.2, 4, 0.6, -38 }, { "c", 5.4, -11.4, 3.6 },
			{ "r", 7.4, 1, 5.6, 1.4, 0.7, -8 }, { "c", 10.2, 0.6, 2.8 }, { "r", -7.4, 4.2, 5, 1.4, 0.7, 10 },
		},
	},
}

local POD = {
	Fill = rgb(24, 20, 28),
	Band = rgb(68, 60, 78),
	Rim = rgb(255, 247, 222),
	Core = rgb(255, 214, 120),
	Mark = rgb(255, 247, 222),
	RimUnits = 0.9,
	-- The size colour's outline round the ivory rim: thin, and opaque, so where
	-- two pods' outlines meet it stays one even band.
	GlowUnits = 2.2,
	GlowTransparency = 0,
}

-- Which biomes' pods a pod prize shows: the biomes its pool really draws from,
-- in the game's road order; more than three are spread to first, middle, last.
function WheelDraw.podBiomes(reward: WheelData.Reward): { string }
	local seen: { [string]: boolean } = {}
	for _, id in ipairs(WheelData.Pools[reward.pool or ""] or {}) do
		local species = SeedData.Get(id)
		if species and SILHOUETTES[species.Biome] then
			seen[species.Biome] = true
		end
	end
	local order: { string } = {}
	for _, biome in ipairs({ "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }) do
		if seen[biome] then
			table.insert(order, biome)
		end
	end
	if #order > 3 then
		order = { order[1], order[math.floor((#order + 1) / 2)], order[#order] }
	end
	return order
end

-- Back to front: { biome, x, y, scale }. The first biome stands in front.
function WheelDraw.podCluster(reward: WheelData.Reward): { { any } }
	local biomes = WheelDraw.podBiomes(reward)
	if #biomes == 0 then
		biomes = { "greenhollow" }
	end
	if #biomes == 1 then
		return { { biomes[1], 0, 0.4, 0.92 } }
	elseif #biomes == 2 then
		return { { biomes[2], 5, 0.4, 0.62 }, { biomes[1], -3.9, 1.4, 0.7 } }
	end
	return { { biomes[2], -6.8, 0.4, 0.56 }, { biomes[3], 6.4, 0.6, 0.56 }, { biomes[1], 0, 2.2, 0.62 } }
end

-- An uploaded pod picture, in the 24-unit box: its square's side at a member's
-- scale 1 (the pod fills about 88% of the square's height, so it stands as
-- tall as its frame-drawn silhouette), and how far above the member's point
-- its centre sits -- the frame silhouette's own middle, base at 8.5.
local POD_IMAGE_UNITS = 22
local POD_IMAGE_CENTRE: { [string]: number } = { greenhollow = -1.55, tanglemire = -1.2, starbloom = -2.35 }

local function podArtId(biome: string): string?
	local art = (GameConfig :: any).WheelPodArt
	local id = if type(art) == "table" then art[biome] else nil
	return if type(id) == "string" and string.match(id, "^rbxassetid://%d+$") then id else nil
end

local function podIcon(box: Frame, reward: WheelData.Reward, px: number)
	local tier = reward.tier or 2
	local variant = if tier >= 7 then "colossal" elseif tier == 6 then "titan" else "common"
	local glowColour = SeedData.ColorForTier(tier)
	local cluster = WheelDraw.podCluster(reward)

	local function drawShapes(target: GuiObject, shapes: { Shape }, ox: number, oy: number, s: number, grow: number,
		colour: Color3, z: number, transparency: number?, name: string)
		for _, sh in ipairs(shapes) do
			local x, y = ox + sh[2] * s, oy + sh[3] * s
			if sh[1] == "c" then
				local d = sh[4] * s + grow * 2
				blob(target, name, x, y, d, d, math.huge, 0, colour, z, transparency)
			else
				blob(target, name, x, y, sh[4] * s + grow * 2, sh[5] * s + grow * 2, sh[6] * s + grow, sh[7], colour, z,
					transparency)
			end
		end
	end
	-- One pod in frames: its rim, its black, its lighter bands, a Colossal's core.
	local function drawFrames(target: GuiObject, member: { any }, z: number)
		local sil = SILHOUETTES[member[1]]
		local shapes = (sil :: any)[variant] or sil.common
		drawShapes(target, shapes, member[2], member[3], member[4], POD.RimUnits, POD.Rim, z, nil, "Rim")
		drawShapes(target, shapes, member[2], member[3], member[4], 0, POD.Fill, z + 1, nil, "Shell")
		if sil.bands then
			drawShapes(target, sil.bands :: { Shape }, member[2], member[3], member[4], 0, POD.Band, z + 2, nil, "Band")
		end
		if variant == "colossal" and sil.core then
			drawShapes(target, sil.core :: { Shape }, member[2], member[3], member[4], 0, POD.Core, z + 3, nil, "Core")
		end
	end
	-- The "?" on the pod in front.
	local function drawMark(target: Frame, member: { any })
		local sil = SILHOUETTES[member[1]]
		local scale = member[4]
		local mark = glyph(target, "?", member[2] + sil.body[1] * scale, member[3] + sil.body[2] * scale + 0.6 * scale,
			sil.body[3] * scale * 0.95, px, POD.Mark)
		mark.Name = "Mark"
		mark.ZIndex = 40
	end
	local front = cluster[#cluster]

	-- The size's outline under every pod drawn in frames. An uploaded picture
	-- carries its own ivory rim, and nothing is drawn round it.
	for _, member in ipairs(cluster) do
		if not podArtId(member[1]) then
			local sil = SILHOUETTES[member[1]]
			local shapes = (sil :: any)[variant] or sil.common
			drawShapes(box, shapes, member[2], member[3], member[4], POD.GlowUnits, glowColour, 1, POD.GlowTransparency,
				"Glow")
		end
	end
	-- POD BY POD (2026-10-04): the owner's picture where the biome has one
	-- (GameConfig.WheelPodArt), the frames where it has not -- the Dustbowl urn
	-- beside an uploaded Greenhollow egg is one prize drawn both ways.
	for i, member in ipairs(cluster) do
		local z = 2 + i * 4
		local id = podArtId(member[1])
		if id then
			-- Its frames stand in until the picture has loaded, so a pod is never
			-- a blank; the picture goes over them, its transparent background kept.
			-- The front pod's frames carry their "?", which goes with them: the
			-- loaded picture shows its own.
			local fallback = Instance.new("Frame")
			fallback.Name = "Fallback"
			fallback.Size = UDim2.fromScale(1, 1)
			fallback.BackgroundTransparency = 1
			fallback.BorderSizePixel = 0
			fallback.Active = false
			fallback.ZIndex = z
			fallback.Parent = box
			drawFrames(fallback, member, 1)
			if member == front then
				drawMark(fallback, member)
			end
			local units = POD_IMAGE_UNITS * member[4]
			local image = Instance.new("ImageLabel")
			image.Name = "Pod_" .. member[1]
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Position = UDim2.fromScale(0.5 + member[2] / 24,
				0.5 + (member[3] + (POD_IMAGE_CENTRE[member[1]] or 0) * member[4]) / 24)
			image.Size = UDim2.fromScale(units / 24, units / 24)
			image.BackgroundTransparency = 1
			image.ScaleType = Enum.ScaleType.Fit
			image.Image = id
			image.ZIndex = z + 1
			image.Active = false
			image.Parent = box
			if image.IsLoaded then
				fallback.Visible = false
			else
				local watch = WheelDraw.whenLoaded
				if watch then
					watch(image, function(ok: boolean)
						if ok then
							fallback.Visible = false
						end
					end)
				end
			end
		else
			drawFrames(box, member, z)
		end
	end
	-- One "?" on the pod in front -- unless that pod is a picture, which has its
	-- own: never two on one pod.
	if not podArtId(front[1]) then
		drawMark(box, front)
	end
end

--==============================================================================
-- TITAN AND COLOSSAL LETTERING (prestige) -- see the header above
--==============================================================================
export type Glint = {
	gradient: UIGradient,
	frames: { ColorSequence },
	still: ColorSequence,
	seconds: number,
	shown: number,
}

type Ramp = { { any } }

-- A ramp's colour at t (0..1), between its stops.
local function rampAt(ramp: Ramp, t: number): Color3
	for i = 1, #ramp - 1 do
		local a, b = ramp[i], ramp[i + 1]
		if t <= b[1] then
			local span = b[1] - a[1]
			return (a[2] :: Color3):Lerp(b[2] :: Color3, if span > 0 then math.clamp((t - a[1]) / span, 0, 1) else 0)
		end
	end
	return ramp[#ramp][2]
end

-- Frame k puts a soft light toward `toward` k/count of the way along the ramp;
-- the light enters before one end and leaves past the other. Built once.
local function sheenFrames(ramp: Ramp, toward: Color3, lift: number, width: number, count: number): { ColorSequence }
	local out: { ColorSequence } = {}
	for k = 0, count - 1 do
		local at = -width + (1 + 2 * width) * (k / count)
		local times: { number } = {}
		for _, stop in ipairs(ramp) do
			table.insert(times, stop[1])
		end
		for _, t in ipairs({ at - width, at, at + width }) do
			if t > 0.002 and t < 0.998 then
				table.insert(times, t)
			end
		end
		table.sort(times)
		local keys: { ColorSequenceKeypoint } = {}
		local last = -1
		for _, t in ipairs(times) do
			if t - last > 0.001 then
				local glow = lift * math.max(0, 1 - math.abs(t - at) / width)
				table.insert(keys, ColorSequenceKeypoint.new(t, rampAt(ramp, t):Lerp(toward, glow)))
				last = t
			end
		end
		out[k + 1] = ColorSequence.new(keys)
	end
	return out
end

local function plainRamp(ramp: Ramp): ColorSequence
	local keys: { ColorSequenceKeypoint } = {}
	for _, stop in ipairs(ramp) do
		table.insert(keys, ColorSequenceKeypoint.new(stop[1], stop[2]))
	end
	return ColorSequence.new(keys)
end

local TITAN_RAMP: Ramp = { { 0, rgb(255, 92, 52) }, { 0.5, rgb(255, 150, 44) }, { 1, rgb(255, 214, 84) } }
local COLOSSAL_RAMP: Ramp = { { 0, rgb(180, 112, 255) }, { 0.5, rgb(228, 150, 255) }, { 1, rgb(255, 214, 96) } }

WheelDraw.Prestige = {
	titan = {
		frames = sheenFrames(TITAN_RAMP, rgb(255, 246, 214), 0.5, 0.16, 32),
		still = plainRamp(TITAN_RAMP),
		seconds = 2.8,
		lift = 0.5,
	},
	colossal = {
		frames = sheenFrames(COLOSSAL_RAMP, rgb(255, 250, 238), 0.62, 0.2, 32),
		still = plainRamp(COLOSSAL_RAMP),
		seconds = 3.4,
		lift = 0.62,
		-- The soft glow round the letters: a pale twin behind, edged in light.
		glow = rgb(226, 196, 255),
	},
}

-- Which lettering a prize's name wears: "titan", "colossal" or nil. By size
-- tier -- these are pod SIZES, not a rarity.
function WheelDraw.prestigeOf(reward: WheelData.Reward?): string?
	if reward and reward.kind == "pod" then
		if (reward.tier or 0) >= 7 then
			return "colossal"
		elseif reward.tier == 6 then
			return "titan"
		end
	end
	return nil
end

-- A glint for a gradient that already exists (WheelUI's line under the wheel).
function WheelDraw.glintOf(gradient: UIGradient, style: string): Glint?
	local p = (WheelDraw.Prestige :: any)[style]
	if not p then
		return nil
	end
	gradient.Color = p.still
	return { gradient = gradient, frames = p.frames, still = p.still, seconds = p.seconds, shown = 0 }
end

-- Puts a style's lettering on a label (its text white under the gradient; its
-- dark outline stays dark). `glow` adds Colossal's soft twin behind it, kept
-- on the label's size, place, words and visibility.
function WheelDraw.prestige(label: TextLabel, style: string, glow: boolean?): Glint?
	local p = (WheelDraw.Prestige :: any)[style]
	if not p then
		return nil
	end
	label.TextColor3 = WHITE
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Prestige"
	gradient.Color = p.still
	gradient.Parent = label
	if glow and p.glow then
		local twin = label:Clone()
		-- Its own light edge and no gradient; its size cap stays, so the twin
		-- is drawn at exactly the size the word is.
		for _, child in ipairs(twin:GetChildren()) do
			if child:IsA("UIStroke") or child:IsA("UIGradient") then
				child:Destroy()
			end
		end
		twin.Name = label.Name .. "Glow"
		twin.TextColor3 = p.glow
		twin.TextTransparency = 0.5
		twin.ZIndex = math.max(0, label.ZIndex - 1)
		local edge = Instance.new("UIStroke")
		edge.Color = p.glow
		edge.Thickness = math.max(2, label.TextSize * 0.2)
		edge.Transparency = 0.55
		edge.LineJoinMode = Enum.LineJoinMode.Round
		edge.Parent = twin
		twin.Parent = label.Parent
		for _, property in ipairs({ "Text", "TextSize", "Size", "Position", "Visible", "Rotation", "AnchorPoint" }) do
			label:GetPropertyChangedSignal(property):Connect(function()
				(twin :: any)[property] = (label :: any)[property]
			end)
		end
	end
	return { gradient = gradient, frames = p.frames, still = p.still, seconds = p.seconds, shown = 0 }
end

-- Steps every glint to time `t` (seconds); `still` holds the plain ramp. A
-- gradient is written only when its frame changes.
function WheelDraw.glint(list: { Glint }, t: number, still: boolean?)
	for _, g in ipairs(list) do
		local k = if still then 0 else math.floor(((t / g.seconds) % 1) * #g.frames) + 1
		if k ~= g.shown then
			g.shown = k
			g.gradient.Color = if k == 0 then g.still else g.frames[math.clamp(k, 1, #g.frames)]
		end
	end
end

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
		coinIcon(box, reward, px)
	elseif reward.kind == "speed" then
		speedIcon(box, reward)
	elseif reward.kind == "pod" then
		podIcon(box, reward, px)
	elseif reward.kind == "boost" and reward.boost == "training" then
		--======================================================================
		-- THE OWNER'S BOOSTED SHOE (2026-10-08, TREADMILL FUN addendum 1;
		-- GameConfig.SourceIcons.training), over the dumbbell the wheel always
		-- drew -- which stays, under it, until the picture has loaded, so the
		-- slice and the Reward list are never blank.
		--======================================================================
		local fallback = Instance.new("Frame")
		fallback.Name = "Fallback"
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.BorderSizePixel = 0
		fallback.Active = false
		fallback.Parent = box
		-- A dumbbell: a brown bar through two white plates.
		local ink = rgb(90, 59, 26)
		shape(fallback, "Bar", 0, 0, 20, 4, ink, nil, 0, 2)
		shape(fallback, "PlateL", -9.5, 0, 5, 14, WHITE, ink, 1.8, 2, nil, 1)
		shape(fallback, "PlateR", 9.5, 0, 5, 14, WHITE, ink, 1.8, 2, nil, 1)
		local shoe = Instance.new("ImageLabel")
		shoe.Name = "TrainingShoe"
		shoe.AnchorPoint = Vector2.new(0.5, 0.5)
		shoe.Position = UDim2.fromScale(0.5, 0.5)
		shoe.Size = UDim2.fromScale(1.15, 1.15)
		shoe.BackgroundTransparency = 1
		shoe.ScaleType = Enum.ScaleType.Fit
		shoe.Image = GameConfig.SourceIcons.training
		shoe.ZIndex = 11
		shoe.Active = false
		shoe.Parent = box
		local watch = WheelDraw.whenLoaded
		if shoe.IsLoaded then
			fallback.Visible = false
		elseif watch then
			watch(shoe, function(ok: boolean)
				if ok then
					fallback.Visible = false
				end
			end)
		end
	elseif reward.kind == "invite" then
		-- An invite plant (2026-10-08): a gift in the prize's own pink, its gold
		-- ribbon and bow. Drawn from frames, like every icon here.
		local ink = rgb(110, 30, 70)
		local gold = rgb(255, 214, 92)
		shape(box, "Box", 0, 3, 18, 13, rgb(255, 128, 190), ink, 1.8, 2)
		shape(box, "Lid", 0, -4.5, 21, 5, reward.colour, ink, 1.8, 2, nil, 1)
		shape(box, "Ribbon", 0, 1, 4, 20, gold, nil, 0, 1, nil, 2)
		shape(box, "BowL", -3.6, -8.6, 6.4, 4.6, gold, ink, 1.4, math.huge, -25, 3)
		shape(box, "BowR", 3.6, -8.6, 6.4, 4.6, gold, ink, 1.4, math.huge, 25, 3)
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
	-- Every icon turns over as a whole on the lower half of the wheel, so none
	-- is ever upside down -- the income arrow never points down (2026-10-04).
	table.insert(upright, box)
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
	-- The Titan and Colossal lettering's light at time `t` (seconds), or the
	-- plain ramp held still (`still`: reduced motion). The caller steps it --
	-- only while the wheel is open or near (WheelUI).
	setGlint: (t: number, still: boolean?) -> (),
	glints: { Glint },
	-- The world's hub, when the options asked for one.
	hub: Hub?,
}

export type Options = {
	-- Words on the sectors (default on).
	labels: boolean?,
	-- THIS player's words for a sector (2026-10-08, THE PRIZES SCALE WITH THE
	-- PLAYER: "$1.2M" for the amount the next spin pays), or the prize's own
	-- label when this is absent or answers nil.
	labelFor: ((WheelData.Reward) -> string?)?,
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

--==============================================================================
-- NARROW WORDS (2026-10-04): a word on a slice under 14 degrees -- COLOSSAL --
-- one line from 64 to 103 out, as thick as the wedge allows at its inner end
-- less a divider and a margin each side. Only where the letters would come out
-- at least MinPx tall at this wheel's size; otherwise the slice keeps its icon
-- alone, as the mockup drew it. `px` is in mockup units.
--==============================================================================
WheelDraw.NarrowWords = { Inner = 64, Outer = 103, MinPx = 9, Advance = 0.78 }

function WheelDraw.narrowWords(span: number, k: number, text: string): { r: number, length: number, thick: number, px: number }?
	local N = WheelDraw.NarrowWords
	local half = math.rad(span / 2)
	local thick = 2 * (N.Inner * math.tan(half) - DIVIDER_HALF - EDGE_MARGIN)
	local length = N.Outer - N.Inner
	if thick <= 2 then
		return nil
	end
	local px = math.min(thick - 1.5, length / math.max(1, #text * N.Advance))
	if px * k < N.MinPx then
		return nil
	end
	return { r = (N.Inner + N.Outer) / 2, length = length, thick = thick, px = thick - 1.5 }
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
	local glints: { Glint } = {}
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
		local text = (if opts.labelFor then opts.labelFor(reward) else nil) or reward.label
		local entry: Turning = { mid = sector.mid, words = nil, upright = {} }

		-- The icon near the rim, pointing out.
		local iconPx = 24 * k * (if reward.kind == "trail" then 1.05 else 0.95)
		local icon = WheelDraw.icon(arm, reward, iconPx)
		icon.box.Position = UDim2.new(0.5, 0, 0.5, -116 * k)
		for _, g in ipairs(icon.upright) do
			table.insert(entry.upright, g)
		end
		for _, g in ipairs(icon.rainbow) do
			table.insert(starGradients, g)
		end
		local style = WheelDraw.prestigeOf(reward)

		-- A cash slice's background coins, under its words and icon (THE PRIZE
		-- ART): muted toward the slice's own colour so the amount stays in front.
		if reward.kind == "cash" then
			local twoLines = select(2, splitWords(text)) ~= nil
			local wordsHalf = (if twoLines then 12.5 else 8) + 1
			local face = COIN.Face:Lerp(reward.colour, 0.15)
			local inner = COIN.Top:Lerp(reward.colour, 0.15)
			local ink = COIN.Ink:Lerp(reward.colour, 0.12)
			local shine = COIN.Shine:Lerp(reward.colour, 0.15)
			for i, coin in ipairs(WheelDraw.coinLayout(span, WheelDraw.cashTier(reward.amount), wordsHalf)) do
				local y = -math.sqrt(coin.r * coin.r - coin.x * coin.x)
				local holder = Instance.new("Frame")
				holder.Name = "Coin" .. i
				holder.AnchorPoint = Vector2.new(0.5, 0.5)
				holder.Position = UDim2.new(0.5, coin.x * k, 0.5, y * k)
				holder.Size = UDim2.fromOffset(coin.d * k, coin.d * k)
				holder.BackgroundTransparency = 1
				holder.BorderSizePixel = 0
				holder.Active = false
				holder.ZIndex = 0
				holder.Parent = arm
				disc(holder, "Edge", 1, ink, 1)
				disc(holder, "Face", 1 - 1.4 / coin.d, face, 2)
				disc(holder, "Inner", 1 - 3.4 / coin.d, inner, 3)
				disc(holder, "Shine", 0.22, shine, 4, -0.18, -0.18)
			end
		end

		-- The words toward the centre, along the radius, where the sector is wide
		-- enough to hold them. The two narrowest, the Colossal pod and the trail,
		-- are icon-only, as in the mockup -- except that COLOSSAL is set on its
		-- slice wherever the wheel is big enough (NARROW WORDS, 2026-10-04).
		if opts.labels ~= false and span >= 14 then
			local first, second = splitWords(text)
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
			local big = wordLine("Big", first, bigPx, 0)
			local small = if second then wordLine("Small", second, smallPx, bigPx + 1 * k) else nil
			if reward.kind == "cash" then
				-- The amount in front of its coins: a heavier outline.
				for _, l in ipairs({ big, small }) do
					local stroke = l and l:FindFirstChildOfClass("UIStroke")
					if stroke then
						stroke.Thickness = math.max(1, 2 * k)
					end
				end
			end
			if style then
				for _, l in ipairs({ big, small }) do
					if l then
						local g = WheelDraw.prestige(l, style, style == "colossal")
						if g then
							table.insert(glints, g)
						end
					end
				end
			end
			entry.words = holder
		elseif opts.labels ~= false and style == "colossal" then
			-- COLOSSAL on its own narrow slice, where the wheel is big enough to
			-- set it readably (NARROW WORDS): further out, one line, kept inside
			-- the wedge.
			local fit = WheelDraw.narrowWords(span, k, text)
			if fit then
				local holder = Instance.new("Frame")
				holder.Name = "Words"
				holder.AnchorPoint = Vector2.new(0.5, 0.5)
				holder.Position = UDim2.new(0.5, 0, 0.5, -fit.r * k)
				holder.Size = UDim2.fromOffset(fit.length * k, fit.thick * k)
				holder.BackgroundTransparency = 1
				holder.BorderSizePixel = 0
				holder.Active = false
				holder.ZIndex = 3
				holder.Parent = arm
				local l = words(holder, "Big", fit.px * k, WHITE, P.WordInk, 1.5 * k, 3)
				l.Text = text
				l.Size = UDim2.fromScale(1, 1)
				l.TextScaled = true
				local cap = Instance.new("UITextSizeConstraint")
				cap.MaxTextSize = math.max(6, math.floor(fit.px * k + 0.5))
				cap.MinTextSize = 6
				cap.Parent = l
				local g = WheelDraw.prestige(l, style, true)
				if g then
					table.insert(glints, g)
				end
				entry.words = holder
			end
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
	WheelDraw.glint(glints, 0, true)

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
		setGlint = function(t: number, still: boolean?)
			WheelDraw.glint(glints, t, still)
		end,
		glints = glints,
		hub = hub,
	}
end

return WheelDraw
