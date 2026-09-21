--!strict
--==============================================================================
-- THE WEATHER TEASER: A BLACK SCREEN BESIDE THE ROAD
--
-- One cosmetic screen, built by MapService. No video asset, light, sound, remote
-- or weather gameplay. The server builds the board and paints its first frame;
-- WeatherTeaser.client.luau plays it locally at 15 Hz when it is on screen.
--
-- The brief is curiosity: the screen is black, says UPDATE SOON, and shows a
-- storm only in silhouette -- a dark cloud, rain, and a lightning double-flicker
-- twice a loop that lights the cloud for a moment. The flicker is the beat that
-- tells a player twenty studs away that this is a screen that PLAYS; everything
-- else is sized to be seen at walking distance, not at the pixel.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local Teaser = {}
Teaser.Name = "WeatherTeaser"
Teaser.Tag = "SeedWeatherTeaser"
-- Far enough that the flicker is seen from the hub and the near plots; the
-- words stop being legible well before this, the flash does not.
Teaser.Reach = 260
Teaser.Interval = 1 / 15
Teaser.Period = 14
Teaser.Drops = 16

local MAP = GameConfig.Map
local WHITE = Color3.fromRGB(231, 236, 242)
local MUTED = Color3.fromRGB(126, 142, 156)
local RAIN = Color3.fromRGB(118, 138, 164)
local CLOUD_DARK = Color3.fromRGB(22, 29, 39)
local CLOUD_LIT = Color3.fromRGB(70, 84, 104)
local BOLT = Color3.fromRGB(214, 228, 255)

-- Canvas geometry, shared by Build and Paint so the two cannot drift apart.
local CLOUD_X, CLOUD_Y = 282, 196
local CLOUD_SWAY = 24
local RAIN_TOP, RAIN_TRAVEL, RAIN_SPEED = 334, 60, 90 -- 90 x 14 s is 21 falls: seamless loop
local DROP_W, DROP_H, DROP_SLANT = 4, 24, 16
local SCAN_TOP, SCAN_TRAVEL = 172, 300
local TRACK_X, TRACK_W = 64, 832

--==============================================================================
-- WHERE IT STANDS: THE LEFT SIDE OF THE ROAD MOUTH, BECAUSE OF THE PLOTS
--
-- Codex first stood it on the right, 34 studs out from the corridor and 22 in
-- from the red line. That is clear of today's starter plots and NOT clear of a
-- fully upgraded Plot_06: from level 3 the plot grows a 40-stud wing, and plot
-- 6's wing points at the road mouth, reaching z -164 at level 5 -- its rail ran
-- 14.7 studs into the board's top trim (measured 2026-09-21, exact footprint
-- test). Plot_01 is the mirror position but its wing grows AWAY from the mouth,
-- so the same spot on the left keeps 25 studs from a level-5 Plot_01, 11.5
-- outside the night shutter and 7.6 behind the red line. WeatherTeaserSpec
-- checks all six plots at max level.
--
-- It faces the field between the hub and the mouth, so a player walking from
-- any plot toward the road sees its front.
--==============================================================================
function Teaser.Placement(): CFrame
	local pos = Vector3.new(-(MAP.CorridorWidth * 0.5 + 34), MAP.GroundY, -MAP.FieldFront + 22)
	return CFrame.lookAt(pos, Vector3.new(0, pos.Y, -MAP.FieldFront + 110))
end

--==============================================================================
-- THE STORM'S CLOCK
--
-- Two strikes a loop, each a double flicker: a short flash, a gap, a longer
-- one. Returns 0 (dark), 0.6 (first flicker) or 1 (the full flash) for a time
-- already wrapped into the loop. Pure, so the spec can sample the whole loop.
--==============================================================================
local STRIKES = { 2.6, 9.3 }
function Teaser.StrikeAt(t: number): number
	for _, s in ipairs(STRIKES) do
		local d = t - s
		if d >= 0 and d < 0.12 then
			return 0.6
		elseif d >= 0.2 and d < 0.44 then
			return 1
		end
	end
	return 0
end

local function rect(parent: Instance, name: string, x: number, y: number,
	w: number, h: number, color: Color3, transparency: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.Parent = parent
	return f
end

-- A straight bar from a to b, as a Frame rotated about its own centre.
local function bar(parent: Instance, name: string, a: Vector2, b: Vector2, width: number,
	color: Color3): Frame
	local d = b - a
	local length = d.Magnitude
	local centre = (a + b) * 0.5
	local f = rect(parent, name, centre.X - width * 0.5, centre.Y - length * 0.5, width, length, color)
	-- Rotation is clockwise; a downward bar swung clockwise moves its foot left.
	f.Rotation = math.deg(math.atan2(-d.X, d.Y))
	return f
end

local function label(parent: Instance, name: string, text: string, y: number,
	height: number, size: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(28, y)
	l.Size = UDim2.new(1, -56, 0, height)
	l.Font = Enum.Font.FredokaOne
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.ZIndex = 4
	l.Parent = parent
	return l
end

local function dropStart(i: number): (number, number)
	-- Spread across the cloud's underside, with a fixed per-drop phase so the
	-- sheet never falls in step.
	return 318 + (i - 1) * 21 + (i * 7) % 11, (i * 23) % RAIN_TRAVEL
end

export type ScreenState = {
	model: Model, screen: BasePart, gui: SurfaceGui, cloud: Frame, lobes: { Frame },
	rain: { Frame }, bolt: Frame, flash: Frame, scan: Frame, progress: Frame,
	mystery: TextLabel, lit: boolean?,
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
	local frame = Color3.fromRGB(28, 32, 39)
	part("FootLeft", Vector3.new(5, 0.7, 4), Vector3.new(-8, 0.35, 0), frame)
	part("FootRight", Vector3.new(5, 0.7, 4), Vector3.new(8, 0.35, 0), frame)
	part("PostLeft", Vector3.new(1.1, 6, 1.1), Vector3.new(-8, 3.7, 0), frame)
	part("PostRight", Vector3.new(1.1, 6, 1.1), Vector3.new(8, 3.7, 0), frame)
	local backing = part("Housing", Vector3.new(27, 15.2, 1.5), Vector3.new(0, 12.1, 0), frame)
	part("TopTrim", Vector3.new(27.8, 0.55, 1.9), Vector3.new(0, 19.8, 0), frame)
	local screen = part("Screen", Vector3.new(25.6, 14.4, 0.15), Vector3.new(0, 12.1, -0.83), Color3.new(0, 0, 0))
	screen.TopSurface = Enum.SurfaceType.Smooth
	model.PrimaryPart = backing

	local gui = Instance.new("SurfaceGui")
	gui.Name = "TeaserScreen"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(960, 540)
	-- A screen gives its own light: full brightness by day and by night.
	gui.LightInfluence = 0
	gui.Brightness = 1
	gui.AlwaysOnTop = false
	gui.MaxDistance = Teaser.Reach
	gui.Active = false
	gui.Parent = screen
	local canvas = rect(gui, "Canvas", 0, 0, 960, 540, Color3.fromRGB(3, 5, 8))
	canvas.ClipsDescendants = true
	rect(canvas, "TopRule", 36, 34, 888, 3, MUTED, 0.7)
	label(canvas, "Eyebrow", "SOMETHING IS COMING", 44, 34, 28, MUTED)
	label(canvas, "Title", "UPDATE SOON", 78, 90, 84, WHITE)

	-- A silhouette, not a reveal: broad rounded lobes a shade off black, lit
	-- only for the length of a flicker.
	local cloud = rect(canvas, "Cloud", CLOUD_X, CLOUD_Y, 396, 152, Color3.new(), 1)
	for i, box in ipairs({ {0, 64, 396, 66}, {45, 30, 140, 78}, {146, 0, 151, 130}, {280, 47, 87, 70} }) do
		local lobe = rect(cloud, "Lobe" .. i, box[1], box[2], box[3], box[4], CLOUD_DARK)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 28)
		corner.Parent = lobe
	end
	local rain = rect(canvas, "Rain", 0, 0, 960, 540, Color3.new(), 1)
	for i = 1, Teaser.Drops do
		local x, y = dropStart(i)
		local drop = rect(rain, "Drop" .. i, x, RAIN_TOP + y, DROP_W, DROP_H, RAIN, 0.5)
		drop.Rotation = DROP_SLANT
	end
	-- The bolt: three bars in a zig-zag, hidden except during a strike.
	-- Above the flash (3) so the flash never greys it out.
	-- Its foot stops 12 px above the hint line so the two never touch.
	local bolt = rect(canvas, "Bolt", 452, 318, 70, 94, Color3.new(), 1)
	bolt.ZIndex = 4
	bar(bolt, "Segment1", Vector2.new(44, 0), Vector2.new(25, 42), 11, BOLT).ZIndex = 4
	bar(bolt, "Segment2", Vector2.new(21, 40), Vector2.new(46, 46), 11, BOLT).ZIndex = 4
	bar(bolt, "Segment3", Vector2.new(44, 44), Vector2.new(24, 94), 10, BOLT).ZIndex = 4
	bolt.Visible = false
	-- The flash: the whole screen lifting for a frame or three, under the words.
	local flash = rect(canvas, "Flash", 0, 0, 960, 540, Color3.fromRGB(200, 215, 235), 1)
	flash.ZIndex = 3
	label(canvas, "Mystery", "???", 214, 116, 96, WHITE)
	label(canvas, "Hint", "THE SKY IS CHANGING...", 424, 40, 34, MUTED)
	rect(canvas, "Track", TRACK_X, 486, TRACK_W, 6, MUTED, 0.8)
	rect(canvas, "Progress", TRACK_X, 486, 40, 6, WHITE, 0.4).ZIndex = 2
	local scan = rect(canvas, "Scan", 0, SCAN_TOP, 960, 4, MUTED, 0.86)
	scan.ZIndex = 2
	CollectionService:AddTag(model, Teaser.Tag)

	-- The first frame is the still one, so Edit, a slow stream and Reduced FX all
	-- show exactly the same card.
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
	local cloud, rain, bolt = canvas:FindFirstChild("Cloud"), canvas:FindFirstChild("Rain"), canvas:FindFirstChild("Bolt")
	local flash, scan = canvas:FindFirstChild("Flash"), canvas:FindFirstChild("Scan")
	local progress, mystery = canvas:FindFirstChild("Progress"), canvas:FindFirstChild("Mystery")
	if not (cloud and cloud:IsA("Frame") and rain and bolt and bolt:IsA("Frame")
		and flash and flash:IsA("Frame") and scan and scan:IsA("Frame")
		and progress and progress:IsA("Frame") and mystery and mystery:IsA("TextLabel")) then return nil end
	local lobes: { Frame } = {}
	for i = 1, 4 do
		local lobe = cloud:FindFirstChild("Lobe" .. i)
		if not (lobe and lobe:IsA("Frame")) then return nil end
		table.insert(lobes, lobe)
	end
	local drops: { Frame } = {}
	for i = 1, Teaser.Drops do
		local d = rain:FindFirstChild("Drop" .. i)
		if not (d and d:IsA("Frame")) then return nil end
		table.insert(drops, d)
	end
	return { model = model, screen = screen, gui = gui, cloud = cloud, lobes = lobes,
		rain = drops, bolt = bolt, flash = flash, scan = scan, progress = progress,
		mystery = mystery, lit = nil }
end

--==============================================================================
-- ONE FRAME
--
-- Every property is a function of the wrapped time, so the loop is seamless and
-- any two clients show the same frame at the same server time. Reduced FX is the
-- still card: no flash, no scan, nothing moving.
--==============================================================================
function Teaser.Paint(state: ScreenState, time: number, reduced: boolean)
	local t = if reduced then 0 else time % Teaser.Period
	local strike = if reduced then 0 else Teaser.StrikeAt(t)
	state.cloud.Position = UDim2.fromOffset(
		CLOUD_X + math.sin(t / Teaser.Period * math.pi * 2) * CLOUD_SWAY, CLOUD_Y)
	local lit = strike > 0
	if state.lit ~= lit then
		state.lit = lit
		for _, lobe in ipairs(state.lobes) do
			lobe.BackgroundColor3 = if lit then CLOUD_LIT else CLOUD_DARK
		end
	end
	state.bolt.Visible = lit
	state.flash.BackgroundTransparency = if strike >= 1 then 0.84 elseif lit then 0.92 else 1
	state.scan.Visible = not reduced
	state.scan.Position = UDim2.fromOffset(0, SCAN_TOP + t / Teaser.Period * SCAN_TRAVEL)
	state.progress.Size = UDim2.fromOffset(40 + t / Teaser.Period * (TRACK_W - 40), 6)
	state.mystery.TextTransparency = if lit then 0
		else 0.1 + 0.15 * (1 + math.sin(t * math.pi / 3.5))
	local slant = math.tan(math.rad(DROP_SLANT))
	for i, drop in ipairs(state.rain) do
		local x, phase = dropStart(i)
		local fall = (phase + t * RAIN_SPEED) % RAIN_TRAVEL
		drop.Position = UDim2.fromOffset(x - fall * slant, RAIN_TOP + fall)
	end
end

return Teaser
