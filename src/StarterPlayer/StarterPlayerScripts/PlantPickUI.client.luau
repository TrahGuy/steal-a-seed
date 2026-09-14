--!strict
--==============================================================================
-- PICKING YOUR OWN PLANT BACK UP
--
-- Click, or tap, a grown plant in your own bed. It is outlined, and a small
-- PICK UP button floats above it. Press the button and the plant comes back to
-- your hands. That is the whole feature.
--
-- There is no floating proximity prompt, no key, and no button pinned to the
-- bottom of the screen. The button lives over the plant it belongs to, so there
-- is never any doubt which plant it will take.
--
--==============================================================================
-- WHAT THIS FILE MUST NEVER DO, BECAUSE AN EARLIER VERSION OF IT DID
--
--   GET IN THE WAY OF PLANTING. While a plant Tool is in your hands, PlantPlace
--   owns every click -- it plants on the press. This file ignores input
--   completely in that state, before it even looks at where the click landed.
--   An earlier version tried to be clever and select plants under the pointer
--   while planting; it turned putting a plant down into several clicks.
--
--   GET IN THE WAY OF THE CAMERA. Only a clean click counts: a press and a
--   release in nearly the same place, quickly. A drag is the camera and is left
--   alone. And input is never marked handled here, so nothing downstream ever
--   loses a press to this file.
--
--==============================================================================
-- WHAT IT DOES NOT DO
--
-- It does not pick anything up or decide who owns anything. It asks the server
-- with PickUpAction -- the same verb the Garden panel has always used -- and
-- PlantService.PickUpById re-tests ownership, growth and the bag itself.
--
-- What says a plant is grown and yours is an invisible part the server keeps
-- per grown plant under your plot's Runtime/PickupAnchors, named by placement
-- id. It is only a part. There is deliberately no ProximityPrompt on it any more:
-- a "disarmed" one with an empty key matched every mouse press, and inside your
-- own plot it swallowed every click -- see THERE IS NO PICKUP PROMPT in
-- PlantService.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local Remotes = SeedGame:WaitForChild("Remotes")
local channel = Remotes:WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ATTR = GameConfig.Attributes
local PANEL = GameConfig.Panel
local PLANTING = GameConfig.Plant

local CREAM = Color3.fromRGB(242, 238, 206)
local BLACK = Color3.fromRGB(0, 0, 0)
local LIME = Color3.fromRGB(150, 220, 96)

-- A clean click: ten pixels and half a second. Anything that moves further or
-- lasts longer is a camera drag and is none of this file's business.
local TAP_SLOP = 10
local TAP_SECONDS = 0.5

-- How far away a plant can still be clicked. Generous, because a grown plant
-- wanders its bed and a player looking straight at one expects the click to
-- answer.
local SELECT_RANGE = 60

-- Long enough that a double press cannot ask twice.
local PRESS_DEBOUNCE = 0.4

-- How often a selection checks that its plant is still there and still near.
local POLL_SECONDS = 1 / 3

--==============================================================================
-- THE OUTLINE
--
-- One Highlight for the whole game, reparented to whichever plant is selected.
-- Occluded rather than AlwaysOnTop, so a plant hidden behind something is not
-- lit up through it.
--==============================================================================
local highlight = Instance.new("Highlight")
highlight.Name = "SeedPlantPick"
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.FillTransparency = 1
highlight.OutlineColor = LIME
highlight.OutlineTransparency = 0

--==============================================================================
-- THE BUTTON ABOVE THE PLANT
--
-- A BillboardGui in PlayerGui, adorned to the selected plant's base and lifted
-- above its top in WORLD space, so it stays straight up however the plant sways
-- and follows it as it wanders. Pixel-sized rather than stud-sized, so it is the
-- same small button whether the plant is a Tiny or a Colossal.
--
-- It must live in PlayerGui, not in the workspace: a button on a billboard only
-- receives clicks from there.
--==============================================================================
local billboard = Instance.new("BillboardGui")
billboard.Name = "SeedPlantPickButton"
billboard.AlwaysOnTop = true
billboard.Active = true
billboard.LightInfluence = 0
billboard.MaxDistance = 250
billboard.ResetOnSpawn = false
billboard.Size = UDim2.fromOffset(112, 40)
billboard.Enabled = false
billboard.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "PickUp"
button.Size = UDim2.fromScale(1, 1)
button.AutoButtonColor = false
button.BorderSizePixel = 0
button.BackgroundTransparency = 0.12
button.Text = ""
button.Parent = billboard
UIKit.corner(button, 10)
UIKit.gradient(button, PANEL.Fill, PANEL.Shade)
UIKit.stroke(button, BLACK, 2.5)

local ring = Instance.new("Frame")
ring.Name = "Ring"
ring.Position = UDim2.fromOffset(3, 3)
ring.Size = UDim2.new(1, -6, 1, -6)
ring.BackgroundTransparency = 1
ring.Parent = button
UIKit.corner(ring, 8)
UIKit.stroke(ring, LIME, 1.5)

local label = UIKit.outlined(button, "Word", 16, CREAM, 2)
label.Size = UDim2.fromScale(1, 1)
label.Text = "PICK UP"

--==============================================================================
-- WHAT IS SELECTED
--
-- `watching` holds the connections that belong to THIS selection and is emptied
-- every time it is cleared. `generation` stops a poll started for an old
-- selection the moment a new one begins.
--==============================================================================
type Selection = {
	model: Model,
	marker: BasePart,
}

local selected: Selection? = nil
local watching: { RBXScriptConnection } = {}
local generation = 0
local pressedAt = 0

--==============================================================================
-- SMALL QUESTIONS
--==============================================================================
local function holdingAPlant(): boolean
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return tool ~= nil and type(tool:GetAttribute("SpeciesId")) == "string"
end

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model") and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

-- The server's marker for a plant, if that plant is grown and in MY plot.
-- Looked up by placement id under my own plot, so a neighbour's plant never
-- resolves.
local function markerFor(model: Instance): BasePart?
	if not (model:IsA("Model") and CollectionService:HasTag(model, GameConfig.Tags.Planted)) then
		return nil
	end
	local id = model:GetAttribute("PlacementId")
	local plot = myPlot()
	local runtime = if plot then plot:FindFirstChild(GameConfig.Plot.RuntimeFolderName) else nil
	local anchors = if runtime
		then runtime:FindFirstChild(GameConfig.Plot.PickupAnchorsFolderName)
		else nil
	local marker = if anchors and type(id) == "number"
		then anchors:FindFirstChild(tostring(id))
		else nil
	if marker and marker:IsA("BasePart") then
		return marker
	end
	return nil
end

local function distanceTo(model: Model): number
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (root and root:IsA("BasePart")) then
		return math.huge
	end
	return (model:GetPivot().Position - root.Position).Magnitude
end

--==============================================================================
-- WHICH PLANT IS UNDER THE POINTER
--
-- Plants are CanQuery = false, so a raycast passes straight through them. The
-- ray is tested against each plant's own bounding box instead, padded by a stud
-- all round so a click near a petal still counts.
--
-- One ordinary raycast decides what is IN THE WAY, and it ignores the
-- character and the player's own plot -- the fence round your garden is not a
-- thing your garden hides behind. Anything else in the world still blocks.
--
-- `at` is an InputObject position, which pairs with ScreenPointToRay.
--==============================================================================
local function rayHitsBox(origin: Vector3, dir: Vector3, boxCF: CFrame, size: Vector3): number?
	local o = boxCF:PointToObjectSpace(origin)
	local d = boxCF:VectorToObjectSpace(dir)
	local half = size * 0.5
	local tmin, tmax = -math.huge, math.huge
	for _, axis in ipairs({ "X", "Y", "Z" }) do
		local oi = (o :: any)[axis] :: number
		local di = (d :: any)[axis] :: number
		local hi = (half :: any)[axis] :: number
		if math.abs(di) < 1e-7 then
			if oi < -hi or oi > hi then
				return nil
			end
		else
			local t1 = (-hi - oi) / di
			local t2 = (hi - oi) / di
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			tmin = math.max(tmin, t1)
			tmax = math.min(tmax, t2)
			if tmin > tmax then
				return nil
			end
		end
	end
	if tmax < 0 then
		return nil
	end
	return math.max(tmin, 0)
end

local function plantUnder(at: Vector2): (Model?, BasePart?)
	local camera = Workspace.CurrentCamera
	local plot = myPlot()
	local plants = if plot then plot:FindFirstChild("Plants") else nil
	if not (camera and plants) then
		return nil, nil
	end
	local ray = camera:ScreenPointToRay(at.X, at.Y)
	local origin, dir = ray.Origin, ray.Direction.Unit

	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	if plot then
		table.insert(ignore, plot)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local solid = Workspace:Raycast(origin, dir * 600, params)
	local reach = if solid then (solid.Position - origin).Magnitude else 600

	local bestModel: Model? = nil
	local bestMarker: BasePart? = nil
	local bestAt = math.huge
	for _, child in ipairs(plants:GetChildren()) do
		local marker = markerFor(child)
		if marker then
			local model = child :: Model
			if distanceTo(model) <= SELECT_RANGE then
				local boxCF, boxSize = model:GetBoundingBox()
				local t = rayHitsBox(origin, dir, boxCF, boxSize + Vector3.new(2, 2, 2))
				if t and t <= reach and t < bestAt then
					bestAt = t
					bestModel = model
					bestMarker = marker
				end
			end
		end
	end
	return bestModel, bestMarker
end

--==============================================================================
-- SELECTING AND LETTING GO
--
-- Every way out of a selection comes through clearSelection -- the plant going
-- away, the player walking off, a panel opening, a plant coming into the hands.
--==============================================================================
local function clearSelection()
	generation += 1
	for _, c in ipairs(watching) do
		c:Disconnect()
	end
	table.clear(watching)
	selected = nil
	highlight.Parent = nil
	billboard.Enabled = false
	billboard.Adornee = nil
end

local function select(model: Model, marker: BasePart)
	clearSelection()
	local base = model.PrimaryPart
	if not base then
		return
	end
	selected = { model = model, marker = marker }

	highlight.Parent = model

	-- Lifted clear of the plant's top, measured once: plants wander and sway
	-- but they do not grow taller while you are looking at them.
	local height = model:GetExtentsSize().Y
	billboard.Adornee = base
	billboard.StudsOffsetWorldSpace = Vector3.new(0, height + 0.8, 0)
	billboard.Enabled = true
	SoundKit.play("CardClick")

	table.insert(watching, model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearSelection()
		end
	end))
	-- The server drops the marker the moment the plant stops being yours to
	-- pick up: picked up, hatched over, or rebuilt.
	table.insert(watching, marker.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearSelection()
		end
	end))

	local mine = generation
	task.spawn(function()
		while mine == generation do
			task.wait(POLL_SECONDS)
			if mine ~= generation then
				return
			end
			if not (model.Parent and marker.Parent)
				or distanceTo(model) > SELECT_RANGE then
				clearSelection()
				return
			end
		end
	end)
end

--==============================================================================
-- THE BUTTON
--
-- The server decides. A refused pickup -- a full bag, say -- still spends the
-- selection, so the button does not sit there inviting another press.
--==============================================================================
local function press()
	local current = selected
	if not current then
		return
	end
	local now = os.clock()
	if now - pressedAt < PRESS_DEBOUNCE then
		return
	end
	pressedAt = now
	local id = current.model:GetAttribute("PlacementId")
	if type(id) ~= "number" then
		clearSelection()
		return
	end
	SoundKit.play("UIClick")
	channel:FireServer(PLANTING.PickUpAction, id)
	clearSelection()
end

button.Activated:Connect(press)

--==============================================================================
-- THE CLICK
--
-- Decided on RELEASE, because a press that has just landed could still become a
-- camera drag. Pressing the PICK UP button is a GUI press, arrives `processed`,
-- and is ignored here -- the button's own Activated handles it.
--==============================================================================
type Pending = {
	input: InputObject,
	at: Vector2,
	began: number,
}

local pending: Pending? = nil

local function isPointer(kind: Enum.UserInputType): boolean
	return kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if not isPointer(input.UserInputType) then
		return
	end
	if pending then
		-- A second finger: a pinch or a camera move, never a tap on a plant.
		pending = nil
		return
	end
	-- PLANTING OWNS THIS CLICK. Checked first and checked here, at the press,
	-- so nothing about a planting click is ever looked at by this file.
	if processed or holdingAPlant() then
		return
	end
	pending = {
		input = input,
		at = Vector2.new(input.Position.X, input.Position.Y),
		began = os.clock(),
	}
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	local waiting = pending
	if not waiting or input ~= waiting.input then
		return
	end
	pending = nil
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if (at - waiting.at).Magnitude > TAP_SLOP then
		return
	end
	if os.clock() - waiting.began > TAP_SECONDS then
		return
	end
	-- A plant Tool equipped, or a pod picked up, in the middle of the click.
	if holdingAPlant() or player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		clearSelection()
		return
	end
	local model, marker = plantUnder(waiting.at)
	if model and marker then
		local current = selected
		if current and current.model == model then
			return
		end
		select(model, marker)
	else
		clearSelection()
	end
end)

--==============================================================================
-- EVERYTHING ELSE THAT ENDS A SELECTION
--==============================================================================
player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(function()
	if player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		clearSelection()
	end
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if player:GetAttribute(ATTR.OpenPanel) ~= nil then
		clearSelection()
	end
end)
player:GetAttributeChangedSignal(ATTR.Trapped):Connect(clearSelection)

local humanoidConn: RBXScriptConnection? = nil
local toolConn: RBXScriptConnection? = nil

local function watchCharacter(character: Model)
	clearSelection()
	if humanoidConn then
		humanoidConn:Disconnect()
		humanoidConn = nil
	end
	if toolConn then
		toolConn:Disconnect()
		toolConn = nil
	end
	-- Picking a plant up to plant it ends any selection, so the outline and the
	-- button are never showing while PlantPlace has the clicks.
	toolConn = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and type(child:GetAttribute("SpeciesId")) == "string" then
			clearSelection()
		end
	end)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoidConn = humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Physics
			or new == Enum.HumanoidStateType.FallingDown
			or new == Enum.HumanoidStateType.Dead then
			clearSelection()
		end
	end)
end

if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(clearSelection)

clearSelection()
