--!strict
--==============================================================================
-- Steal a Seed :: VipService (2026-10-12, the owner's item 9: the VIP pass)
--
-- THE VIP'S GOLD NAME. A VIP's name over their head is ours, not the engine's:
-- their DisplayName in gold, in the HUD's outlined LuckiestGuy, a BillboardGui
-- on the Head where the engine's name stood (its own hidden: the Humanoid's
-- DisplayDistanceType None) -- under the ADMIN and REBIRTH titles, which stand
-- higher, at their own Rise, as they always did. Built with each character and
-- the moment PassService says the pass is owned; taken away, and the engine's
-- name given back, the moment it is not.
--
-- The [VIP] chat tag is VipChat.client's, keyed on the Vip attribute
-- PassService publishes; the +10% money is the pass row's `multiplier`
-- (PassService.CashMultiplier, beside x2 Money's).
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PassService = require(script.Parent:WaitForChild("PassService"))

local VipService = {}
-- After PassService (22), whose Changed it hears.
VipService.Priority = 23

local NAME = GameConfig.Pass.VipName
local connections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/VipService] " .. message)
end

--==============================================================================
-- ONE CHARACTER'S NAME: the gold one for a VIP, else the engine's own. Pure
-- enough for the specs: a stand-in character is a Model with a Head part and a
-- Humanoid. Answers the gold name it built, or nil.
--==============================================================================
function VipService.dress(character: Instance, displayName: string, vip: boolean): BillboardGui?
	local head = character:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild(NAME.Name)
		if old then
			old:Destroy()
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = if vip then Enum.HumanoidDisplayDistanceType.None
			else Enum.HumanoidDisplayDistanceType.Viewer
	end
	if not (vip and head and head:IsA("BasePart")) then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = NAME.Name
	gui.Size = UDim2.fromOffset(NAME.Size.X, NAME.Size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, NAME.Rise, 0)
	-- Under the titles by pixels, never by studs (GameConfig.Pass.VipName).
	gui.SizeOffset = Vector2.new(0, NAME.Drop)
	gui.MaxDistance = NAME.MaxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Active = false
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Name = "Words"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = NAME.Colour
	label.Text = displayName
	label.Active = false
	label.Parent = gui
	-- A long name shrinks to fit; never past the gold's own size.
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = NAME.TextSize
	fit.MinTextSize = 12
	fit.Parent = label
	local edge = Instance.new("UIStroke")
	edge.Color = NAME.Outline
	edge.Thickness = 2
	edge.Parent = label
	CollectionService:AddTag(gui, NAME.Tag)
	gui.Parent = head
	return gui
end

-- The player's current character, dressed as PassService answers now. The
-- Head comes a moment after the body, so it is waited for, never in Start.
local function apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	task.spawn(function()
		local head = character:WaitForChild("Head", 10)
		if head and character.Parent and player.Character == character then
			VipService.dress(character, player.DisplayName, PassService.IsVip(player))
		end
	end)
end

local function watch(player: Player)
	table.insert(connections, player.CharacterAdded:Connect(function()
		apply(player)
	end))
	apply(player)
end

function VipService.Init()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	-- A re-run leaves nothing behind.
	for _, gui in ipairs(CollectionService:GetTagged(NAME.Tag)) do
		gui:Destroy()
	end
end

function VipService.Start()
	table.insert(connections, Players.PlayerAdded:Connect(watch))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	-- Ownership known at a join, or bought in-game, or (a refund) gone.
	table.insert(connections, PassService.Changed.Event:Connect(function(player: Player)
		if player.Parent then
			apply(player)
		end
	end))
	log("Ready. A VIP's name is gold over their head; their [VIP] chat tag is the client's (VipChat).")
end

return VipService
