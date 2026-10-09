--!strict
-- Steal a Seed :: OwnerTitleService
--
-- THE OWNER'S "ADMIN" TITLE (2026-10-01, the owner's ask; GameConfig.OwnerTitle)
--
-- One floating word over the head of the accounts that wear it, decided here on
-- the server by UserId (AdminService.HasTitle) -- never by a DisplayName or a
-- username. Until 2026-10-09 the owner's alone; since then (the owner: "add
-- admin title to michael", "yes, Teambarnze825 is Michael") Teambarnze825's
-- too -- the title only: he is not the owner (IsOwner), and the third admin,
-- TappedYou, and anybody else get none. Built on the Head of every new
-- character such an account gets, so it follows them and comes back after a
-- respawn; whatever title a character already carries is taken off first, so
-- there is only ever one; an old one goes with its old body.
--
-- Built HERE so every client receives it with the character; OwnerTitleUI only
-- turns its rainbow (on each viewer's own screen, still for reduced motion).
-- Cosmetic only: no attribute, permission, physics or rule changes. Nothing in
-- it can be touched, collided with or clicked.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))

local TITLE = GameConfig.OwnerTitle

local OwnerTitleService = {}
-- After AdminService (95), whose HasTitle decides.
OwnerTitleService.Priority = 96

local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/OwnerTitleService] " .. message)
end

-- Every title a character carries, wherever in it.
local function clear(character: Instance)
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == TITLE.Name then
			d:Destroy()
		end
	end
end

local function letters(parent: Instance, name: string, z: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	-- Bold and rounded, the broadcast's face.
	label.Font = Enum.Font.FredokaOne
	label.TextSize = TITLE.TextSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.RichText = false
	label.Text = TITLE.Text
	label.ZIndex = z
	label.Active = false
	label.Parent = parent
	return label
end

--==============================================================================
-- THE TITLE ON ONE CHARACTER: only a titled account's, only one
--
-- Returns the title it built, or nil -- for anybody without the title, or a
-- body with no Head yet. Clears the character either way.
--==============================================================================
function OwnerTitleService.Apply(player: any, character: Instance): BillboardGui?
	clear(character)
	if not AdminService.HasTitle(player) then
		return nil
	end
	local head = character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = TITLE.Name
	gui.Size = UDim2.fromOffset(TITLE.Size.X, TITLE.Size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, TITLE.Rise, 0)
	-- Raised by its own height too, so it sits over the countdown and the name
	-- -- and over a rebirth title when the character wears one (2026-10-08;
	-- RebirthService restacks it the other way round).
	gui.SizeOffset = Vector2.new(0, GameConfig.ownerTitleLift(head:FindFirstChild(GameConfig.Rebirth.Title.Name) ~= nil))
	gui.MaxDistance = TITLE.MaxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Active = false
	gui.Adornee = head
	--==========================================================================
	-- THE GLOW under the LETTERS: the same word twice in one box. The glow's
	-- edge is wide and half clear in the rainbow; the letters over it are
	-- filled with the rainbow and outlined dark -- the broadcast name's recipe,
	-- with the wheel's own rainbow (WheelDraw.rainbow), still until a viewer's
	-- OwnerTitleUI turns it.
	--==========================================================================
	local glow = letters(gui, "Glow", 1)
	local glowEdge = Instance.new("UIStroke")
	glowEdge.Color = Color3.new(1, 1, 1)
	glowEdge.Thickness = TITLE.GlowThickness
	glowEdge.Transparency = 0.55
	glowEdge.Parent = glow
	local glowRainbow = Instance.new("UIGradient")
	glowRainbow.Name = "Rainbow"
	glowRainbow.Color = WheelDraw.rainbow(0)
	glowRainbow.Parent = glowEdge
	local word = letters(gui, "Letters", 2)
	local edge = Instance.new("UIStroke")
	edge.Color = FloatingSign.Outline
	edge.Thickness = TITLE.EdgeThickness
	edge.Parent = word
	local fill = Instance.new("UIGradient")
	fill.Name = "Rainbow"
	fill.Color = WheelDraw.rainbow(0)
	fill.Parent = word
	CollectionService:AddTag(gui, TITLE.Tag)
	gui.Parent = head
	return gui
end

local function watch(player: Player)
	if not AdminService.HasTitle(player) then
		return
	end
	local function onCharacter(character: Model)
		-- Never waited for in Start: the Head comes a moment after the body.
		task.spawn(function()
			local head = character:WaitForChild("Head", 10)
			if head and character.Parent and player.Character == character then
				OwnerTitleService.Apply(player, character)
			end
		end)
	end
	table.insert(serviceConnections, player.CharacterAdded:Connect(onCharacter))
	if player.Character then
		onCharacter(player.Character)
	end
	log(string.format("%s (%d) is here; their ADMIN title follows them.",
		if AdminService.IsOwner(player) then "the owner" else "a titled admin", player.UserId))
end

function OwnerTitleService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	-- A re-run leaves nothing behind.
	for _, gui in ipairs(CollectionService:GetTagged(TITLE.Tag)) do
		gui:Destroy()
	end
end

function OwnerTitleService.Start()
	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	log("Ready. The ADMIN title, by UserId: the owner's and Teambarnze825's (AdminService.HasTitle).")
end

return OwnerTitleService
