--!strict
--==============================================================================
-- Steal a Seed :: ObbySign (2026-10-13, the owner's item 8)
--
-- "OBBY" with "Floating Garden" under it, floating over the Floating Garden's
-- entrance arch for every player: with the OBBY pill gone (item 7, SELL), this
-- is how the obby is found. ObbyData.Sign has its words, colours and sizes.
--
-- FloatingSign's family (LuckiestGuy, the dark outline, sized in studs, no
-- backing, nothing to press), on a local anchor in a folder of its own: never
-- streamed out, so it stands for a player anywhere on the map. Its bottom edge
-- stays BottomAbove the ground, over the arch's crown, so it never comes down
-- onto the Start prompt on the step under the arch. Shown to everybody, always.
--
-- READ FROM AFAR, NEVER HUGE UP CLOSE: after the camera moves, its size is
-- FloatingSign.clampScale's -- the header at least MinHeaderUnits tall on this
-- screen, at most MaxHeaderShare of it -- about that bottom edge, written only
-- when the scale moves. It draws out to MaxDistance (past every plot).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))

local SIGN = ObbyData.Sign

-- No obby, no sign (ObbyService builds nothing while it is switched off).
if not GameConfig.Obby.Enabled then
	return
end

-- A local folder of its own (the Mist sign's way): never streamed out.
local old = Workspace:FindFirstChild("SeedObbySign")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "SeedObbySign"
folder.Parent = Workspace

local tall = SIGN.Height + SIGN.SubHeight
local entrance = ObbyData.Entrance.At
local middle = Vector3.new(entrance.X, (GameConfig.Map :: any).GroundY + SIGN.BottomAbove + tall / 2, entrance.Z)
local sign = FloatingSign.new({
	name = "ObbySign",
	parent = folder,
	at = CFrame.new(middle),
	text = SIGN.Header,
	colour = SIGN.HeaderColour,
	width = SIGN.Width,
	height = SIGN.Height,
	subText = SIGN.Sub,
	subHeight = SIGN.SubHeight,
})
local sub = sign.sub :: TextLabel
sub.TextColor3 = SIGN.SubColour
sign.gui.MaxDistance = SIGN.MaxDistance
sign.setShown(true)

-- Its size after the camera has moved; a write only when the scale moves.
local scale = 1
RunService:BindToRenderStep("SeedObbySignClamp", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local want = FloatingSign.clampScale((middle - camera.CFrame.Position).Magnitude, SIGN.Height,
		camera.ViewportSize.Y, camera.FieldOfView, SIGN.MinHeaderUnits, SIGN.MaxHeaderShare)
	if math.abs(want - scale) > 0.004 then
		scale = want
		sign.gui.Size = UDim2.fromScale(SIGN.Width * want, tall * want)
		sign.gui.StudsOffsetWorldSpace = Vector3.new(0, (want - 1) * tall / 2, 0)
	end
end)
