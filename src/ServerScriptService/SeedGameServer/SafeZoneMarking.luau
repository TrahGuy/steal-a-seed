--!strict
--==============================================================================
-- Steal a Seed :: SafeZoneMarking (2026-10-04, the owner's reference picture)
--
-- THE SAFE ZONE MARKING at the field's entrance, flat on the grass: "SAFE ZONE"
-- in big white LuckiestGuy with a thick dark outline, a two-tone blue heater
-- shield on each side (white rim, the left half lighter), and no plate -- the
-- grass shows round the letters. Dressing only, so not a "*Service": MapService
-- builds it beside the red line during its own build. The red line, the zone's
-- bounds, its tag and every rule about who is safe are MapService's, unchanged.
--
--==============================================================================
-- WHY THE OLD WORDS RAN ALONG THE ROAD
--
-- A SurfaceGui on a part's TOP face lays its canvas out with the canvas's
-- WIDTH along the part's Z axis and its height along X (measured 2026-10-04: a
-- 150 x 22 plate gave a 528 x 3600 canvas at 24 px a stud). The old plate was
-- 150 wide in X and 22 deep in Z, so its words ran 22 studs ALONG the road,
-- and its "90" capped them at 90 px -- 3.75 studs tall. The 90 was that
-- TextSize cap, never a rotation.
--
-- SO THE PLATE IS TURNED, NOT THE WORDS. The canvas reads toward the plate's
-- -Z and its letters stand toward -X (measured: the old words read toward -Z,
-- the hub's side last). A quarter turn about Y points the reading direction at
-- world -X and the letters' tops at +Z: left to right, upright, for a player
-- walking IN from the road toward the hub. The plate's own Z now runs across
-- the entrance, parallel to the red line. MapService's other ground labels are
-- not touched (the rain biome builds its own).
--
-- TextSize stops at 100 px whatever the label's box, so the canvas is coarse
-- for big letters: 7 px a stud makes 100 px fourteen studs of line.
--==============================================================================
local TextService = game:GetService("TextService")

local SafeZoneMarking = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local CONFIG = {
	Name = "SafeLineText",
	Text = "SAFE ZONE",
	Font = Enum.Font.LuckiestGuy,
	-- The engine's ceiling for TextSize.
	TextSize = 100,
	PixelsPerStud = 7,
	Fill = WHITE,
	Ink = Color3.fromRGB(16, 14, 18),
	Stroke = 7,
	-- A shield, in canvas pixels: its box, the dark outline and the white rim
	-- inside it, and the face's two blues, split down the middle.
	Shield = {
		W = 70,
		H = 86,
		Outline = 5,
		Rim = 6,
		Light = Color3.fromRGB(96, 178, 255),
		Dark = Color3.fromRGB(40, 108, 220),
	},
	-- Between a shield and the words, and round the whole canvas (the outline
	-- stands outside the letters and must not reach the canvas's clipped edge).
	Gap = 26,
	MarginX = 20,
	MarginY = 14,
	-- What TextService answered in Studio, should it ever not answer.
	FallbackWidth = 464,
}
SafeZoneMarking.Config = CONFIG

-- The words' width at TextSize, measured for the font rather than guessed, so
-- the label is never narrower than its letters (no clipping, no squeezing).
local function wordsWidth(): number
	local ok, size = pcall(function()
		return TextService:GetTextSize(CONFIG.Text, CONFIG.TextSize, CONFIG.Font, Vector2.new(5000, 1000))
	end)
	if ok and typeof(size) == "Vector2" and size.X > 0 then
		return math.ceil(size.X)
	end
	return CONFIG.FallbackWidth
end

-- The canvas, in pixels: shield, gap, words, gap, shield, with the margins.
function SafeZoneMarking.canvas(textWidth: number): (number, number)
	local S = CONFIG.Shield
	local label = textWidth + CONFIG.Stroke * 2
	local w = CONFIG.MarginX * 2 + S.W * 2 + CONFIG.Gap * 2 + label
	local h = math.max(CONFIG.TextSize + CONFIG.Stroke * 2, S.H) + CONFIG.MarginY * 2
	return w, h
end

local function piece(parent: Instance, name: string, cx: number, cy: number, w: number, h: number,
	colour: Color3, z: number, rotation: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(cx, cy)
	f.Size = UDim2.fromOffset(w, h)
	f.Rotation = rotation
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

-- The face's two blues with a hard edge down the shield's middle. `rotation`
-- turns the gradient back by the piece's own turn, so the edge stays upright.
local function twoTone(f: Frame, rotation: number)
	local S = CONFIG.Shield
	f.BackgroundColor3 = WHITE
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, S.Light),
		ColorSequenceKeypoint.new(0.5, S.Light),
		ColorSequenceKeypoint.new(0.501, S.Dark),
		ColorSequenceKeypoint.new(1, S.Dark),
	})
	g.Rotation = rotation
	g.Parent = f
end

--==============================================================================
-- A HEATER SHIELD OUT OF TWO PIECES PER LAYER
--
-- A straight-sided body from the top to the shoulder, and under it a square
-- turned 45 degrees about the shoulder's middle, whose lower half is the
-- point. Three layers, each inset from the last: the dark outline, the white
-- rim, the two-tone face. The point's half-diagonal is inset by the same
-- amount as the sides, so the sides and the point meet without a step (the
-- rim is a little thinner along the point's slants).
--==============================================================================
local function shield(parent: Instance, name: string, x: number, y: number)
	local S = CONFIG.Shield
	local box = Instance.new("Frame")
	box.Name = name
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Position = UDim2.fromOffset(x, y)
	box.Size = UDim2.fromOffset(S.W, S.H)
	box.Parent = parent
	local half = S.W / 2
	local shoulder = S.H - half
	local layers: { { inset: number, colour: Color3?, z: number } } = {
		{ inset = 0, colour = CONFIG.Ink, z = 2 },
		{ inset = S.Outline, colour = WHITE, z = 3 },
		{ inset = S.Outline + S.Rim, colour = nil, z = 4 },
	}
	for _, layer in ipairs(layers) do
		local e = layer.inset
		local colour = layer.colour or WHITE
		local bodyH = shoulder - e
		local body = piece(box, "Body", half, e + bodyH / 2, S.W - e * 2, bodyH, colour, layer.z, 0)
		local side = (half - e) * math.sqrt(2)
		local point = piece(box, "Point", half, shoulder, side, side, colour, layer.z, 45)
		if not layer.colour then
			twoTone(body, 0)
			twoTone(point, -45)
		end
	end
end

--==============================================================================
-- THE MARKING: an invisible, untouchable plate, turned a quarter, and the
-- canvas on its top. `at` is the marking's centre on the ground (its plate's
-- centre), unturned; the quarter turn is this module's.
--==============================================================================
function SafeZoneMarking.build(parent: Instance, at: CFrame): BasePart
	local P = CONFIG.PixelsPerStud
	local textWidth = wordsWidth()
	local w, h = SafeZoneMarking.canvas(textWidth)

	local plate = Instance.new("Part")
	plate.Name = CONFIG.Name
	-- The plate's X is the canvas's height (along the road), its Z the canvas's
	-- width (across the entrance once turned).
	plate.Size = Vector3.new(h / P, 0.3, w / P)
	plate.CFrame = at * CFrame.Angles(0, math.rad(90), 0)
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanQuery = false
	plate.CanTouch = false
	plate.CastShadow = false
	plate.Transparency = 1
	plate.TopSurface = Enum.SurfaceType.Smooth
	plate.BottomSurface = Enum.SurfaceType.Smooth
	plate.Parent = parent

	local gui = Instance.new("SurfaceGui")
	gui.Name = "SafeZoneMarking"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = P
	gui.LightInfluence = 0
	gui.Parent = plate

	local S = CONFIG.Shield
	local labelW, labelH = textWidth + CONFIG.Stroke * 2, CONFIG.TextSize + CONFIG.Stroke * 2
	local x = CONFIG.MarginX
	shield(gui, "ShieldLeft", x, math.floor((h - S.H) / 2))
	x += S.W + CONFIG.Gap

	local label = Instance.new("TextLabel")
	label.Name = "Words"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(x, math.floor((h - labelH) / 2))
	label.Size = UDim2.fromOffset(labelW, labelH)
	label.Font = CONFIG.Font
	label.Text = CONFIG.Text
	label.TextSize = CONFIG.TextSize
	label.TextScaled = false
	label.TextColor3 = CONFIG.Fill
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 5
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = CONFIG.Stroke
	stroke.Color = CONFIG.Ink
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	x += labelW + CONFIG.Gap

	shield(gui, "ShieldRight", x, math.floor((h - S.H) / 2))
	return plate
end

return SafeZoneMarking
