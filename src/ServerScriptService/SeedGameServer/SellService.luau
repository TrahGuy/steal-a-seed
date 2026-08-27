--!strict
-- Steal a Seed :: SellService
--
--==============================================================================
-- THE SELL-ALL BOARD AT MARIGOLD'S STALL
--
-- One sign, one prompt, one press: everything in the bag becomes cash. The
-- money itself is not minted here -- EconomyService.SellHeld does that, because
-- Rule 6 says cash mints in one file and a stall is not an exception to it.
-- This service owns the FURNITURE and the interaction, nothing else.
--
--==============================================================================
-- WHY THIS IS ITS OWN SERVICE AND NOT A FEW LINES IN MapService
--
-- MapService builds the stall, so the sign would naturally go there -- and
-- MapService and ShopUI are the two files the shop pass is most likely to be
-- editing right now. A sign dropped into the middle of either is a merge
-- conflict waiting to happen over something that has no reason to live there.
--
-- So it goes where NestService already showed a prop with BEHAVIOUR can go: its
-- own service, finding the map's marker at Start and building beside it. The
-- map stays geometry; this stays a transaction.
--
--==============================================================================
-- SAFE TO RE-RUN
--
-- Rule 10. MapService destroys and rebuilds SeedMap, and the plugin rebuilds it
-- in Edit whenever it goes missing, so this has to survive being started against
-- a map that already has a sign standing in it. It destroys its own first.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local SellService = {}

-- After EconomyService (55), which it calls, and after the map is long built.
SellService.Priority = 65

local SIGN_NAME = "SellAllSign"

-- Studs. The board stands off the left end of the 24-wide stall floor, clear of
-- the counter so a player reading it is not standing where Marigold serves.
local SIDE_OFFSET = 15.5
local FRONT_OFFSET = -3.0

local POST_HEIGHT = 5.2
local BOARD_SIZE = Vector3.new(7.2, 3.0, 0.4)

local WOOD = Color3.fromRGB(120, 84, 52)
local BOARD_FACE = Color3.fromRGB(238, 226, 196)
local INK = Color3.fromRGB(58, 44, 32)
local COIN = Color3.fromRGB(250, 198, 48)

local connections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/SellService] " .. message)
end

local function part(name: string, size: Vector3, cf: CFrame, color: Color3,
	parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	p.Parent = parent
	return p
end

--==============================================================================
-- LETTERED ON BOTH FACES
--
-- The same lesson the mill sign and the biome arches both landed on: a player
-- walking up from the road and a player leaving the stall are looking at
-- opposite sides of the same board, and a blank back reads as scenery.
--==============================================================================
local function face(board: BasePart, which: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = which
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 64
	gui.AlwaysOnTop = false
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.52)
	title.Position = UDim2.fromScale(0, 0.06)
	title.Font = Enum.Font.GothamBlack
	title.Text = "SELL ALL"
	title.TextColor3 = INK
	title.TextScaled = true
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.fromScale(1, 0.3)
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Font = Enum.Font.GothamMedium
	-- The price is stated rather than implied. A player who cannot work out
	-- what they are about to be paid will read any number as a bad deal.
	sub.Text = string.format("your whole bag  ·  %ds of income each",
		math.floor(SeedData.SellSeconds))
	sub.TextColor3 = INK
	sub.TextScaled = true
	sub.TextTransparency = 0.25
	sub.Parent = gui
end

local function findStall(): BasePart?
	local map = Workspace:FindFirstChild("SeedMap")
	if not map then
		return nil
	end
	local floor = map:FindFirstChild("StallFloor", true)
	return if floor and floor:IsA("BasePart") then floor else nil
end

local function build(stall: BasePart): Model
	local model = Instance.new("Model")
	model.Name = SIGN_NAME
	-- Parented up front so the ground cast below can exclude it; the parts are
	-- added after, so there is nothing to hit yet either way.
	model.Parent = stall.Parent

	--==========================================================================
	-- FACING THE PEOPLE, NOT THE STALL
	--
	-- Derived from where the hub actually is rather than from the stall's own
	-- rotation: the stall is built with a pi turn baked into its CFrame, so
	-- "forward" there is not the direction a player arrives from. Pointing the
	-- board at the deck centre is true whichever way the stall is later turned.
	--==========================================================================
	local base = stall.CFrame * CFrame.new(-SIDE_OFFSET, 0, FRONT_OFFSET)

	--==========================================================================
	-- CAST DOWN FOR THE FLOOR, DO NOT ASSUME THE STALL'S
	--
	-- The board stands BESIDE the stall, which means it is not standing ON it:
	-- taking the stall floor's top as the ground buried the post's foot three
	-- tenths of a stud in the deck. Same rule CarryService already follows for a
	-- dropped pod -- nothing falls in this game, so anything placed has to be
	-- placed correctly.
	--==========================================================================
	local probe = RaycastParams.new()
	probe.FilterType = Enum.RaycastFilterType.Exclude
	probe.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(base.Position + Vector3.new(0, 24, 0),
		Vector3.new(0, -80, 0), probe)
	local floorY = if hit
		then hit.Position.Y
		else (stall.Position.Y + stall.Size.Y * 0.5)
	local ground = Vector3.new(base.Position.X, floorY, base.Position.Z)
	local towardDeck = Vector3.new(0, ground.Y, 0) - ground
	if towardDeck.Magnitude < 0.05 then
		towardDeck = stall.CFrame.LookVector
	end
	local stand = CFrame.lookAt(ground, ground + towardDeck.Unit)

	part("Post", Vector3.new(0.6, POST_HEIGHT, 0.6),
		stand * CFrame.new(0, POST_HEIGHT * 0.5, 0), WOOD, model)
	-- A foot, so the post reads as planted rather than dropped.
	part("Foot", Vector3.new(1.6, 0.4, 1.6), stand * CFrame.new(0, 0.2, 0), WOOD, model)

	local board = part("Board", BOARD_SIZE,
		stand * CFrame.new(0, POST_HEIGHT + BOARD_SIZE.Y * 0.4, 0), BOARD_FACE, model)
	board.TopSurface = Enum.SurfaceType.Smooth
	board.BottomSurface = Enum.SurfaceType.Smooth
	face(board, Enum.NormalId.Front)
	face(board, Enum.NormalId.Back)

	-- A coin on top. One saturated part is what makes it findable from the road
	-- without a billboard hanging in the sky.
	local coin = part("Coin", Vector3.new(1.5, 0.28, 1.5),
		stand * CFrame.new(0, POST_HEIGHT + BOARD_SIZE.Y + 0.35, 0), COIN, model)
	coin.Shape = Enum.PartType.Cylinder
	coin.CFrame = coin.CFrame * CFrame.Angles(0, 0, math.rad(90))

	model.PrimaryPart = board
	return model
end

local function attachPrompt(model: Model)
	local board = model.PrimaryPart
	if not board then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt in
	-- the game rather than in Roblox's default grey.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Sell All"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	--==========================================================================
	-- HELD, AND LONGER THAN A POD
	--
	-- Taking a pod is 0.7s. This empties an entire bag and cannot be undone, so
	-- it asks for a moment more -- long enough that nobody sells a raid by
	-- walking past with E down, short enough that clearing junk is not a chore.
	--==========================================================================
	prompt.HoldDuration = 1.1
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = board

	table.insert(connections, prompt.Triggered:Connect(function(player)
		local sold, paid = EconomyService.SellHeld(player)
		if sold > 0 then
			-- The game's existing "that transaction worked" cue. The stall pass
			-- can swap it for a till sound when one is wired; an unwired asset
			-- id would be silence with extra steps.
			SoundKit.emit("MillUpgrade", board)
		end
		log(string.format("%s pressed sell-all: %d item(s), %s",
			player.Name, sold, GameConfig.compact(paid)))
	end))
end

function SellService.Init()
	local map = Workspace:FindFirstChild("SeedMap")
	local existing = map and map:FindFirstChild(SIGN_NAME, true)
	if existing then
		existing:Destroy()
	end
end

function SellService.Start()
	local stall = findStall()
	if not stall then
		-- Not fatal: the hub is MapService's, and a map built without a stall is
		-- a MapService problem that should not stop the server booting.
		warn("[Seed/SellService] no StallFloor in the map; no sell board built")
		return
	end
	local model = build(stall)
	attachPrompt(model)
	log(string.format("Ready. Sell-all board standing at the stall, %.0f studs from the deck.",
		(model.PrimaryPart :: BasePart).Position.Magnitude))
end

function SellService.Stop()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
end

return SellService
