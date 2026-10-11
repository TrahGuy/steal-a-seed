--!strict
--==============================================================================
-- THE WEATHER TEASER: THE NEXT EVENT'S CREATURES, BREATHING, BESIDE THE ROAD
--
-- One cosmetic screen, built by MapService. No video asset, light, sound, remote
-- or gameplay. The server builds the board and its first frame -- picture A at
-- rest with SOON -- and WeatherTeaser.client.luau plays it locally at 15 Hz
-- while it is on screen.
--
-- The owner's two teaser pictures (GameConfig.WeatherTeaser, 2026-10-06), each
-- drawn as its background plus one cut-out per creature at its recorded rect,
-- so at rest the screen IS the picture. Each creature breathes, leans and (the
-- one that floats) hovers about its own feet, on its own clock; A holds, fades
-- to B, B holds, fades back, and the creatures keep moving through the fade.
-- Calm and slow: nothing jumps or flashes.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local Teaser = {}
Teaser.Name = "WeatherTeaser"
Teaser.Tag = "SeedWeatherTeaser"
-- Far enough that the screen is seen from the hub and the near plots.
Teaser.Reach = 260
Teaser.Interval = 1 / 15

local MAP = GameConfig.Map
local CFG = GameConfig.WeatherTeaser
local CANVAS = Vector2.new(960, 540)

-- SOON, in canvas pixels. TextSize stops at 100, so a UIScale takes it past.
local SOON_SIZE, SOON_SCALE, SOON_BOTTOM = 100, 1.2, 6
local INK_THICKNESS = 4.5
-- The glow behind it: copies of the word with wide, half-clear rounded edges in
-- the picture's colour, widest first -- { edge in pixels, transparency }.
local SOON_GLOWS = { { 24, 0.88 }, { 16, 0.78 }, { 9, 0.64 } }
-- The haze over each "?" is this many white discs, widest first, so its edge
-- fades in steps too small to see rather than ending in a ring.
local GLOW_DISCS = 10
local DISC_ALPHA = 1 - (1 - CFG.GlowMax) ^ (1 / GLOW_DISCS)

--==============================================================================
-- WHERE IT STANDS: EAST OF THE ROAD MOUTH, BY THE FRONT FENCE (THE OWNER'S SPOT)
--
-- 2026-10-11: the owner moved the screen here in Studio -- its back to the
-- front fence, its front looking north up the field -- and it stays where they
-- put it. The numbers are read off their move (the Housing at (94.8, 12.1,
-- -164.905), turned 180 degrees). Never move it back: a spec that disagrees
-- with this spot changes, not the screen.
--
-- Before: the left side of the mouth, (-104, -148), facing the field between
-- the hub and the mouth; first the right side, 34 studs out from the corridor
-- and 22 in from the red line, which a level-5 Plot_06's wing ran 14.7 studs
-- into. WeatherTeaserSpec checks all six plots at max level.
--==============================================================================
function Teaser.Placement(): CFrame
	local pos = Vector3.new(94.8, MAP.GroundY, -164.905)
	return CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1))
end

--==============================================================================
-- THE CLOCK
--
-- Pure functions of the time, so any two clients show the same frame at the
-- same server time and the spec can sample them without a world.
--==============================================================================
local function smooth(x: number): number
	local u = math.clamp(x, 0, 1)
	return u * u * (3 - 2 * u)
end

-- How far the motion has eased in: 0 at time 0 (each picture exactly as drawn),
-- 1 from EaseIn on. The live clock is the server's, long past it.
function Teaser.Ease(t: number): number
	return smooth(t / CFG.EaseIn)
end

-- B's share of the screen: 0 while A holds, 1 while B holds, eased between. One
-- loop is Hold + Fade + Hold + Fade.
function Teaser.Mix(t: number): number
	local loop = 2 * (CFG.Hold + CFG.Fade)
	local u = t % loop
	if u < CFG.Hold then
		return 0
	elseif u < CFG.Hold + CFG.Fade then
		return smooth((u - CFG.Hold) / CFG.Fade)
	elseif u < 2 * CFG.Hold + CFG.Fade then
		return 1
	end
	return 1 - smooth((u - 2 * CFG.Hold - CFG.Fade) / CFG.Fade)
end

export type Pose = { ScaleX: number, ScaleY: number, Rotation: number, Lift: number, Glow: number }

-- A whole number of cycles is dropped before the angle is taken, so a server
-- clock of two billion seconds keeps its fraction.
local function wave(t: number, period: number, phase: number): number
	return ((t / period + phase) % 1) * 2 * math.pi
end

-- One creature's pose at time t. The breath runs 0 (rest) to 1 (the top) and
-- back; the lean swings either way on a longer cycle; the hover (the one that
-- floats) lifts and settles on a longer one still; the "?" glows with the
-- breath. Lift is a fraction of the creature's height, upward.
function Teaser.Pose(creature: any, t: number): Pose
	local ease = Teaser.Ease(t)
	local period, phase = creature.Period, creature.Phase
	local breath = (1 - math.cos(wave(t, period, phase))) * 0.5 * ease
	local lean = math.sin(wave(t, period * CFG.SwayPeriod, phase + 0.25)) * ease
	local hover = (1 - math.cos(wave(t, period * CFG.BobPeriod, phase))) * 0.5 * ease
	return {
		ScaleX = 1 + CFG.Breath * CFG.BreathX * breath,
		ScaleY = 1 + CFG.Breath * breath,
		Rotation = CFG.Sway * lean,
		Lift = (creature.Bob or 0) * hover,
		Glow = breath,
	}
end

--==============================================================================
-- THE BOARD
--==============================================================================
local function frame(parent: Instance, name: string, zIndex: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = zIndex
	f.Parent = parent
	return f
end

local function picture(parent: Instance, name: string, id: string, zIndex: number): ImageLabel
	local l = Instance.new("ImageLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Image = id
	l.ZIndex = zIndex
	l.Parent = parent
	return l
end

local function word(parent: Instance, name: string, zIndex: number, colour: Color3, edge: Color3,
	thickness: number, transparency: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.LuckiestGuy
	l.Text = CFG.Words.Soon
	l.TextSize = SOON_SIZE
	l.TextColor3 = colour
	l.ZIndex = zIndex
	l.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = edge
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	return l
end

-- One creature: its cut-out at its rect, anchored at its feet, with the "?"
-- haze inside it so the haze breathes, leans and hovers with it.
local function creature(parent: Instance, index: number, c: any, hidden: boolean): ImageLabel
	local source = CFG.Source
	local x, y, w, h = c.Rect[1], c.Rect[2], c.Rect[3], c.Rect[4]
	local label = picture(parent, "Creature" .. index, c.Image, index)
	label.ScaleType = Enum.ScaleType.Stretch
	label.AnchorPoint = Vector2.new((c.Feet[1] - x) / w, (c.Feet[2] - y) / h)
	label.Position = UDim2.fromScale(c.Feet[1] / source.X, c.Feet[2] / source.Y)
	label.Size = UDim2.fromScale(w / source.X, h / source.Y)
	label.ImageTransparency = if hidden then 1 else 0
	local reach = CFG.GlowReach * (c.Badge[3] - 8)
	for k = 1, GLOW_DISCS do
		local d = 2 * reach * (GLOW_DISCS + 1 - k) / GLOW_DISCS
		local disc = Instance.new("Frame")
		disc.Name = "Glow" .. k
		disc.AnchorPoint = Vector2.new(0.5, 0.5)
		disc.Position = UDim2.fromScale((c.Badge[1] - x) / w, (c.Badge[2] - y) / h)
		disc.Size = UDim2.fromScale(d / w, d / h)
		disc.BackgroundColor3 = Color3.new(1, 1, 1)
		disc.BackgroundTransparency = 1
		disc.BorderSizePixel = 0
		disc.ZIndex = k
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = disc
		disc.Parent = label
	end
	return label
end

type CreatureState = {
	label: ImageLabel, discs: { Frame }, config: any,
	-- At rest, in canvas pixels; the feet as fractions of the canvas.
	width: number, height: number, feet: Vector2,
}
type SceneState = { creatures: { CreatureState }, hidden: boolean? }
export type ScreenState = {
	model: Model, screen: BasePart, gui: SurfaceGui, backs: { ImageLabel }, scenes: { SceneState },
	glows: { TextLabel }, words: TextLabel, glow: Color3?,
}

function Teaser.Build(parent: Instance): Model
	local previous = parent:FindFirstChild(Teaser.Name)
	if previous then previous:Destroy() end
	local model = Instance.new("Model")
	model.Name = Teaser.Name
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local base = Teaser.Placement()
	local function part(name: string, size: Vector3, position: Vector3, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = base * CFrame.new(position)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local frameColour = Color3.fromRGB(28, 32, 39)
	part("FootLeft", Vector3.new(5, 0.7, 4), Vector3.new(-8, 0.35, 0), frameColour)
	part("FootRight", Vector3.new(5, 0.7, 4), Vector3.new(8, 0.35, 0), frameColour)
	part("PostLeft", Vector3.new(1.1, 6, 1.1), Vector3.new(-8, 3.7, 0), frameColour)
	part("PostRight", Vector3.new(1.1, 6, 1.1), Vector3.new(8, 3.7, 0), frameColour)
	local backing = part("Housing", Vector3.new(27, 15.2, 1.5), Vector3.new(0, 12.1, 0), frameColour)
	part("TopTrim", Vector3.new(27.8, 0.55, 1.9), Vector3.new(0, 19.8, 0), frameColour)
	local screen = part("Screen", Vector3.new(25.6, 14.4, 0.15), Vector3.new(0, 12.1, -0.83), Color3.new(0, 0, 0))
	screen.TopSurface = Enum.SurfaceType.Smooth
	model.PrimaryPart = backing

	local gui = Instance.new("SurfaceGui")
	gui.Name = "TeaserScreen"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = CANVAS
	-- A screen gives its own light: full brightness by day and by night.
	gui.LightInfluence = 0
	gui.Brightness = 1
	gui.AlwaysOnTop = false
	gui.MaxDistance = Teaser.Reach
	gui.Active = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = screen
	local canvas = frame(gui, "Canvas", 1)
	canvas.BackgroundTransparency = 0
	canvas.BackgroundColor3 = Color3.fromRGB(3, 5, 8)
	canvas.ClipsDescendants = true

	-- Back to front: A's background, B's over it (clear while A holds), A's
	-- creatures, B's creatures, SOON. Each picture's cut-outs left to right, the
	-- order they were made in.
	for s, scene in ipairs(CFG.Scenes) do
		local back = picture(canvas, "Back" .. s, scene.Background, s)
		back.Size = UDim2.fromScale(1, 1)
		back.ScaleType = Enum.ScaleType.Crop
		back.ImageTransparency = if s == 1 then 0 else 1
	end
	for s, scene in ipairs(CFG.Scenes) do
		local layer = frame(canvas, "Scene" .. s, #CFG.Scenes + s)
		for i, c in ipairs(scene.Creatures) do
			creature(layer, i, c, s ~= 1)
		end
	end
	local soon = frame(canvas, "Soon", 2 * #CFG.Scenes + 1)
	soon.AnchorPoint = Vector2.new(0.5, 1)
	soon.Position = UDim2.new(0.5, 0, 1, -SOON_BOTTOM)
	soon.Size = UDim2.fromOffset(CANVAS.X / SOON_SCALE, SOON_SIZE + 10)
	local scale = Instance.new("UIScale")
	scale.Scale = SOON_SCALE
	scale.Parent = soon
	local first = CFG.Scenes[1].Glow
	for i, g in ipairs(SOON_GLOWS) do
		word(soon, "Glow" .. i, i, first, first, g[1], g[2])
	end
	word(soon, "Words", #SOON_GLOWS + 1, Color3.new(1, 1, 1), CFG.Ink, INK_THICKNESS, 0)
	CollectionService:AddTag(model, Teaser.Tag)

	-- The first frame is picture A at rest, so Edit, a slow stream and Reduced
	-- FX all show exactly the same card.
	local state = Teaser.Bind(model)
	if state then
		Teaser.Paint(state, 0, true)
	end
	model.Parent = parent
	return model
end

function Teaser.Bind(model: Model): ScreenState?
	local screen = model:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("TeaserScreen")
	local canvas = gui and gui:FindFirstChild("Canvas")
	if not (screen and screen:IsA("BasePart") and gui and gui:IsA("SurfaceGui") and canvas) then return nil end
	local source = CFG.Source
	local backs: { ImageLabel } = {}
	local scenes: { SceneState } = {}
	for s, scene in ipairs(CFG.Scenes) do
		local back = canvas:FindFirstChild("Back" .. s)
		local layer = canvas:FindFirstChild("Scene" .. s)
		if not (back and back:IsA("ImageLabel") and layer) then return nil end
		table.insert(backs, back)
		local creatures: { CreatureState } = {}
		for i, c in ipairs(scene.Creatures) do
			local label = layer:FindFirstChild("Creature" .. i)
			if not (label and label:IsA("ImageLabel")) then return nil end
			local discs: { Frame } = {}
			for k = 1, GLOW_DISCS do
				local disc = label:FindFirstChild("Glow" .. k)
				if not (disc and disc:IsA("Frame")) then return nil end
				table.insert(discs, disc)
			end
			table.insert(creatures, {
				label = label, discs = discs, config = c,
				width = c.Rect[3] / source.X * CANVAS.X, height = c.Rect[4] / source.Y * CANVAS.Y,
				feet = Vector2.new(c.Feet[1] / source.X, c.Feet[2] / source.Y),
			})
		end
		table.insert(scenes, { creatures = creatures, hidden = nil })
	end
	local soon = canvas:FindFirstChild("Soon")
	if not soon then return nil end
	local glows: { TextLabel } = {}
	for i = 1, #SOON_GLOWS do
		local g = soon:FindFirstChild("Glow" .. i)
		if not (g and g:IsA("TextLabel") and g:FindFirstChildOfClass("UIStroke")) then return nil end
		table.insert(glows, g)
	end
	local words = soon:FindFirstChild("Words")
	if not (words and words:IsA("TextLabel")) then return nil end
	return { model = model, screen = screen, gui = gui, backs = backs, scenes = scenes,
		glows = glows, words = words, glow = nil }
end

-- Every picture on the board, backgrounds first: what a client preloads and a
-- load check waits on.
function Teaser.Pictures(state: ScreenState): { ImageLabel }
	local out = table.clone(state.backs)
	for _, scene in ipairs(state.scenes) do
		for _, c in ipairs(scene.creatures) do
			table.insert(out, c.label)
		end
	end
	return out
end

-- A creature's label for a pose: sized about its feet (the AnchorPoint), lifted,
-- then turned. The engine turns a GuiObject about its CENTRE, so the label is
-- shifted by exactly what brings the feet back to where they stood. Scale, not
-- offsets: offsets are whole pixels, and a breath is a fraction of one a frame.
local function place(c: CreatureState, pose: Pose)
	local w, h = c.width * pose.ScaleX, c.height * pose.ScaleY
	local anchor = c.label.AnchorPoint
	local dx, dy = (anchor.X - 0.5) * w, (anchor.Y - 0.5) * h
	local r = math.rad(pose.Rotation)
	local cs, sn = math.cos(r), math.sin(r)
	local shiftX = dx - (dx * cs - dy * sn)
	local shiftY = dy - (dx * sn + dy * cs) - pose.Lift * c.height
	c.label.Size = UDim2.fromScale(w / CANVAS.X, h / CANVAS.Y)
	c.label.Position = UDim2.fromScale(c.feet.X + shiftX / CANVAS.X, c.feet.Y + shiftY / CANVAS.Y)
	c.label.Rotation = pose.Rotation
end

--==============================================================================
-- ONE FRAME
--
-- Everything is a function of the time. A picture with no share of the screen
-- is set clear once and then left alone. Reduced FX is the still card: picture
-- A at rest, B clear and at rest under it -- the server's own first frame.
--==============================================================================
function Teaser.Paint(state: ScreenState, time: number, reduced: boolean)
	local t = if reduced then 0 else time
	local mix = Teaser.Mix(t)
	state.backs[2].ImageTransparency = 1 - mix
	for s, scene in ipairs(state.scenes) do
		local share = if s == 1 then 1 - mix else mix
		if share <= 0 and scene.hidden and not reduced then continue end
		scene.hidden = share <= 0
		for _, c in ipairs(scene.creatures) do
			c.label.ImageTransparency = 1 - share
			local pose = Teaser.Pose(c.config, t)
			place(c, pose)
			local haze = 1 - DISC_ALPHA * pose.Glow * share
			for _, disc in ipairs(c.discs) do
				disc.BackgroundTransparency = haze
			end
		end
	end
	local glow = CFG.Scenes[1].Glow:Lerp(CFG.Scenes[2].Glow, mix)
	if glow ~= state.glow then
		state.glow = glow
		for _, g in ipairs(state.glows) do
			g.TextColor3 = glow
			local stroke = g:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = glow end
		end
	end
end

-- Two pictures, the loop's shape; checked on load like the other configs.
do
	assert(#CFG.Scenes == 2, "the teaser crossfades exactly two pictures")
	assert(CFG.Hold > 0 and CFG.Fade > 0 and CFG.EaseIn > 0, "teaser times must be positive")
end

return Teaser
