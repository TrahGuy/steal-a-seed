--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistSign (2026-10-11)
--
-- The shared ENCHANTED MIST timer above the Event Hub: the header, the truthful
-- state (EnchantedMistStatus -- COMING SOON, "Eligible in", "Waiting for biome
-- reset" with an ESTIMATE, "Biomes resetting", "ACTIVE · Ends in"), and a note.
-- Every player in a server reads the same published state and deadline; the
-- countdown is worked out here from Workspace:GetServerTimeNow(), repainted at
-- most once a second -- nothing is sent to count down.
--
-- FloatingSign's family (LuckiestGuy, the dark outline, sized in studs, no
-- backing, no collision, nothing to press), over GameConfig.Map.EventHub's
-- centre at EnchantedMistConfig.Sign.Above over its floor. Never hidden behind a
-- quest, an owner check, OTHER PLANTS or Reduced FX. Off entirely until
-- EnchantedMistConfig.ShowSign.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local sign = FloatingSign.new({
	name = "EnchantedMistSign",
	parent = folder,
	at = CFrame.new(centre.X, HUB.FloorY + SIGN.Above, centre.Z),
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
sign.setShown(true)

-- Once a second: the countdown's only clock.
task.spawn(function()
	while folder.Parent do
		task.wait(1)
		paint()
	end
end)
