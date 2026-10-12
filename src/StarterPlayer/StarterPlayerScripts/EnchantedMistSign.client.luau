--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistSign (2026-10-11)
--
-- The shared ENCHANTED MIST timer above the Event Hub: the header, the truthful
-- state (EnchantedMistStatus -- COMING SOON, "Next Mist in", "Waiting for biome
-- reset" with an ESTIMATE, "Biomes resetting", "ACTIVE · Ends in"), and a note.
-- Every player in a server reads the same published state and deadline; the
-- countdown is worked out here from Workspace:GetServerTimeNow(), repainted at
-- most once a second -- nothing is sent to count down.
--
-- FloatingSign's family (LuckiestGuy, the dark outline, sized in studs, no
-- backing, no collision, nothing to press), over GameConfig.Map.EventHub's
-- centre at EnchantedMistConfig.Sign.Above over its floor. Never hidden behind a
-- quest, an owner check, OTHER PLANTS or Reduced FX. Off entirely without
-- EnchantedMistConfig.ShowSign (on since 2026-10-11).
--
-- READ FROM THE PLOTS (EnchantedMistConfig.Sign): past the distance where its
-- header would draw under Sign.MinHeaderUnits on this screen, it grows to hold
-- that size (EnchantedMistStatus.signScale), upward from its bottom edge; it
-- draws out to Sign.MaxDistance.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistStatus = require(Shared:WaitForChild("EnchantedMistStatus"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))

if not EnchantedMistConfig.ShowSign then
	return
end

local SIGN = EnchantedMistConfig.Sign
local ATTR = EnchantedMistConfig.Attributes
local HUB = (GameConfig.Map :: any).EventHub
local CYCLE = GameConfig.WorldCycle

-- A local folder of its own (the shop's words do the same): never streamed out.
local old = Workspace:FindFirstChild("SeedEnchantedMistSign")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "SeedEnchantedMistSign"
folder.Parent = Workspace

local centre: Vector3 = HUB.Centre
local middle = Vector3.new(centre.X, (GameConfig.Map :: any).GroundY + HUB.FloorY + SIGN.Above, centre.Z)
local sign = FloatingSign.new({
	name = "EnchantedMistSign",
	parent = folder,
	at = CFrame.new(middle),
	text = SIGN.Header,
	colour = SIGN.Colour,
	width = SIGN.Width,
	height = SIGN.Height,
	subText = SIGN.Words.Syncing,
	subHeight = SIGN.SubHeight,
	noteText = " ",
	noteHeight = SIGN.NoteHeight,
	noteColour = SIGN.NoteColour,
})
local sub = sign.sub :: TextLabel
local note = sign.note :: TextLabel
sub.TextColor3 = SIGN.SubColour
sign.gui.MaxDistance = SIGN.MaxDistance

local function view(): EnchantedMistStatus.View
	return {
		state = Workspace:GetAttribute(ATTR.State) :: string?,
		eligibleAt = Workspace:GetAttribute(ATTR.EligibleAt) :: number?,
		endsAt = Workspace:GetAttribute(ATTR.EndsAt) :: number?,
		worldPhase = Workspace:GetAttribute(GameConfig.Attributes.WorldPhase) :: string?,
		worldPhaseEndsAt = Workspace:GetAttribute(GameConfig.Attributes.WorldPhaseEndsAt) :: number?,
		nightPhase = CYCLE.PhaseNight,
		nightSeconds = CYCLE.NightSeconds,
	}
end

local function paint()
	local line, small = EnchantedMistStatus.describe(view(), Workspace:GetServerTimeNow())
	if sub.Text ~= line then
		sub.Text = line
	end
	local want = small or ""
	if note.Text ~= want then
		note.Text = want
	end
	note.Visible = small ~= nil
end

for _, name in ipairs({ ATTR.State, ATTR.EligibleAt, ATTR.EndsAt, GameConfig.Attributes.WorldPhase,
	GameConfig.Attributes.WorldPhaseEndsAt }) do
	Workspace:GetAttributeChangedSignal(name):Connect(paint)
end
paint()
-- Out of the way on this screen while this player talks to the Mosskeeper
-- (2026-10-12, the owner on a phone): his talk's camera looks into the hub,
-- where the sign stands over him.
local localPlayer = game:GetService("Players").LocalPlayer
local TALKING = EnchantedMistConfig.Mosskeeper.TalkingAttribute
local function showFor()
	sign.setShown(localPlayer == nil or localPlayer:GetAttribute(TALKING) ~= true)
end
if localPlayer then
	localPlayer:GetAttributeChangedSignal(TALKING):Connect(showFor)
end
showFor()

-- Its smallest size, after the camera has moved: a write only when the scale
-- moves (PlotOwnerLabels' clamp), none while the camera is near.
local scale = 1
RunService:BindToRenderStep("SeedMistSignClamp", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local want = EnchantedMistStatus.signScale((middle - camera.CFrame.Position).Magnitude, camera.ViewportSize.Y,
		camera.FieldOfView)
	if math.abs(want - scale) > 0.004 then
		scale = want
		local width, tall, lift = EnchantedMistStatus.signFrame(want)
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
