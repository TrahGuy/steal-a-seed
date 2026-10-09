--!strict
--==============================================================================
-- Steal a Seed :: MarigoldSign (2026-10-08)
--
-- "BAT SHOP!" over Marigold's stall, so a new player can tell from across the
-- square where bats are sold. The owner: "new players dont know about where to
-- buy bats, we will add a shop text above marigold like spinwheel".
--
-- FloatingSign draws it the way the hub's other floating words are drawn, from
-- GameConfig.Weapon.FloatingWords. Each client's own; shown to every player
-- all the time, because anyone can buy. The stall never moves, so the words are
-- placed once, off its counter (MapService builds the stall; Marigold, who
-- carries the shop prompt, wanders behind it).
--
-- STREAMING: the hub model is not Persistent, so the anchor lives in a local
-- folder of its own, not under a part that could stream out and take it along.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))

local MAP = GameConfig.Map
local W = GameConfig.Weapon.FloatingWords

local found = Workspace:WaitForChild(MAP.FolderName, math.huge):WaitForChild(MAP.PropsFolderName, math.huge)
	:WaitForChild("Hub", math.huge):WaitForChild(MAP.SellStandName, math.huge)
if not found:IsA("BasePart") then
	return
end
local counter = found :: BasePart

-- Over the counter's middle and toward the customers: the counter's back face
-- (its "SHOP" side) is the one the square walks up to, so that way is -Look.
local at = counter.Position + Vector3.yAxis * W.Above - counter.CFrame.LookVector * W.Front
local folder = Instance.new("Folder")
folder.Name = "SeedMarigoldSign"
folder.Parent = Workspace

local sign = FloatingSign.new({
	name = "MarigoldShopWords",
	parent = folder,
	at = CFrame.new(at),
	text = W.Text,
	colour = W.Colour,
	width = W.Width,
	height = W.Height,
	subText = W.SubText,
	subHeight = W.SubHeight,
})
sign.setShown(true)
