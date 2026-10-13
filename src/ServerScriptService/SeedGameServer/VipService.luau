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
--
-- NAME BADGES (2026-10-13, GameConfig.NameBadges): the badge a player wears is
-- decided here, by UserId and then VIP, and published on the player
-- (NameBadges.Attribute). Their name carries it: the square sits in room kept
-- on the name's right, hidden until NameBadgeUI puts it against the last letter
-- as each screen draws it. A wearer who is not a VIP gets the same name in
-- white, the engine's own hidden.
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
-- ONE CHARACTER'S NAME: the gold one for a VIP, a white one for a name badge's
-- wearer, else the engine's own. `badge` is a NameBadges key or nil; a badge
-- rides in the name. Pure enough for the specs: a stand-in character is a Model
-- with a Head part and a Humanoid. Answers the name it built, or nil.
--==============================================================================
function VipService.dress(character: Instance, displayName: string, vip: boolean, badge: string?): BillboardGui?
	local head = character:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild(NAME.Name)
		if old then
			old:Destroy()
		end
	end
	local key = GameConfig.nameBadgeKey(badge)
	local ours = vip or key ~= nil
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = if ours then Enum.HumanoidDisplayDistanceType.None
			else Enum.HumanoidDisplayDistanceType.Viewer
	end
	if not (ours and head and head:IsA("BasePart")) then
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
	label.TextColor3 = if vip then NAME.Colour else NAME.PlainColour
	label.Text = displayName
	label.Active = false
	label.Parent = gui
	-- A long name shrinks to fit; never past the gold's own size.
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = NAME.TextSize
	fit.MinTextSize = 12
	fit.Parent = label
	local edge = Instance.new("UIStroke")
	edge.Color = if vip then NAME.Outline else NAME.PlainOutline
	edge.Thickness = 2
	edge.Parent = label
	if key then
		-- THE BADGE: its room kept on the name's right, so the name and its
		-- badge stand centred as one -- its square and gap for a name as tall
		-- as this box, which is what a billboard draws (TextBounds 19.8 high in
		-- Play, 2026-10-13, under the 15-px cap a screen gui holds to). Hidden
		-- until NameBadgeUI puts it against the last letter as drawn: a long
		-- name shrinks to fit, and only a screen knows by how much.
		local side, _, gap = GameConfig.nameBadgeBox("LuckiestGuy", NAME.Size.Y)
		label.Size = UDim2.new(1, -(side + gap), 1, 0)
		local mark = Instance.new("ImageLabel")
		mark.Name = "Badge"
		mark.BackgroundTransparency = 1
		mark.Image = GameConfig.NameBadges.Images[key]
		mark.ScaleType = Enum.ScaleType.Fit
		mark.Size = UDim2.fromOffset(side, side)
		mark.Visible = false
		mark.Active = false
		mark.Parent = gui
		gui:SetAttribute("Badge", key)
	end
	CollectionService:AddTag(gui, NAME.Tag)
	gui.Parent = head
	return gui
end

-- The badge this player wears now: their own by UserId, else VIP's.
local function badgeOf(player: Player): string?
	return GameConfig.nameBadgeFor(player.UserId, PassService.IsVip(player))
end

-- The player's badge published, and their current character dressed as
-- PassService answers now. The Head comes a moment after the body, so it is
-- waited for, never in Start.
local function apply(player: Player)
	player:SetAttribute(GameConfig.NameBadges.Attribute, badgeOf(player))
	local character = player.Character
	if not character then
		return
	end
	task.spawn(function()
		local head = character:WaitForChild("Head", 10)
		if head and character.Parent and player.Character == character then
			VipService.dress(character, player.DisplayName, PassService.IsVip(player), badgeOf(player))
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
	log("Ready. A VIP's name is gold over their head; their [VIP] chat tag is the client's (VipChat). Name badges by "
		.. "UserId, then VIP: after the name (NameBadgeUI places them).")
end

return VipService
