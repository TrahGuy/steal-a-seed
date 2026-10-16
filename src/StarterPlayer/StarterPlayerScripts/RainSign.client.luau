--!strict
--==============================================================================
-- Steal a Seed :: RainSign (2026-10-16, the owner: "add a Huge Rain Text biome
-- with a timer")
--
-- "RAIN BIOME" over the foot of the rain bridge for every player, always, with
-- the line under it from Shared/RainSign: "Next rain in 42:10" to the next
-- mark of the hourly weather (WeatherService), "OPEN · Closes in 2:31" while
-- the biome is open. Every player in a server reads the same published state,
-- deadline and mark; the countdown is worked out here from
-- Workspace:GetServerTimeNow(), repainted on a change and once a second --
-- nothing is sent to count down. GameConfig.Weather.Sign has its words,
-- colours and sizes.
--
-- FloatingSign's family on a local anchor in a folder of its own (the OBBY
-- sign's way): never streamed out, so it stands for a player anywhere on the
-- map. After the camera moves, its size is FloatingSign.clampScale's
-- (RainSign.scale) -- the header at least MinHeaderUnits tall on this screen,
-- at most MaxHeaderShare of it -- growing upward from its bottom edge, which
-- stays over the gate's top; written only when the scale moves. It draws out
-- to Sign.MaxDistance.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local RainSign = require(Shared:WaitForChild("RainSign"))

local W = GameConfig.Weather
local SIGN = W.Sign
local ATTR = W.Attributes
local NEXT_AT = W.Auto.NextAtAttribute

-- A local folder of its own: never streamed out.
local old = Workspace:FindFirstChild("SeedRainSign")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "SeedRainSign"
folder.Parent = Workspace

local middle = RainSign.at()
local sign = FloatingSign.new({
	name = "RainSign",
	parent = folder,
	at = CFrame.new(middle),
	text = SIGN.Header,
	colour = SIGN.HeaderColour,
	width = SIGN.Width,
	height = SIGN.Height,
	subText = " ",
	subHeight = SIGN.SubHeight,
})
local sub = sign.sub :: TextLabel
sub.TextColor3 = SIGN.SubColour
sign.gui.MaxDistance = SIGN.MaxDistance
sign.setShown(true)

local function paint()
	local line = RainSign.describe({
		state = Workspace:GetAttribute(ATTR.State) :: string?,
		endsAt = Workspace:GetAttribute(ATTR.EndsAt) :: number?,
		nextAt = Workspace:GetAttribute(NEXT_AT) :: number?,
	}, Workspace:GetServerTimeNow())
	local want = line or ""
	if sub.Text ~= want then
		sub.Text = want
	end
	sub.Visible = line ~= nil
end

for _, name in ipairs({ ATTR.State, ATTR.EndsAt, NEXT_AT }) do
	Workspace:GetAttributeChangedSignal(name):Connect(paint)
end
paint()

-- Its size after the camera has moved; a write only when the scale moves.
local scale = 1
RunService:BindToRenderStep("SeedRainSignClamp", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local want = RainSign.scale((middle - camera.CFrame.Position).Magnitude, camera.ViewportSize.Y,
		camera.FieldOfView)
	if math.abs(want - scale) > 0.004 then
		scale = want
		local width, tall, lift = RainSign.frame(want)
		sign.gui.Size = UDim2.fromScale(width, tall)
		sign.gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	end
end)

-- Once a second: the countdown's only clock.
task.spawn(function()
	while folder.Parent do
		task.wait(1)
		paint()
	end
end)
