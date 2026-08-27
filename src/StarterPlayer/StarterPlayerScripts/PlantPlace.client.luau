--!strict
-- Steal a Seed :: PlantPlace
--
-- Turning a click on your own soil into a plant at that exact spot.
--
--==============================================================================
-- THE POSITION CAN ONLY COME FROM HERE
--
-- Tool.Activated fires on the server with no idea where the player was
-- pointing. ClickDetector does not carry a hit position either. A click point
-- exists on the client and nowhere else, so this raycasts and sends it.
--
-- Everything sent is a claim and the server treats it as one -- it re-checks
-- the plot, pulls the point onto the soil and measures the distance itself.
-- Nothing here is trusted, and nothing here needs to be.
--
--==============================================================================
-- NOT Tool.Activated, ON PURPOSE
--
-- The obvious wiring is to plant on the tool's own activation. It does not
-- work on a phone: the mobile tool button is a piece of UI in the corner, so
-- the tap that activates the tool is nowhere near the ground and the last
-- known cursor position is wherever they last touched.
--
-- Listening for the touch on the WORLD instead behaves identically on both --
-- you tap the spot you want, and the spot you tapped is the spot it lands.
-- MOBILE FIRST is a rule in this repo and this is what it costs.
--
--==============================================================================
-- YOU CAN PLANT THROUGH A PLANT
--
-- Overlap is allowed by design -- a garden is arranged, not slotted -- so the
-- ray deliberately ignores the Plants folder. Without that, a big Bellchime
-- would shadow the soil behind it and there would be a patch of your own bed
-- you could no longer reach.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local Remotes = SeedGame:WaitForChild("Remotes")
local channel = Remotes:WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local player = Players.LocalPlayer
local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant

--==============================================================================
-- WHAT IS IN YOUR HANDS
--
-- A Tool with a SpeciesId is either a banked pod or a hatched creature, and
-- both are planted the same way. Anything else in the hotbar is not.
--==============================================================================
local function heldTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and type(tool:GetAttribute("SpeciesId")) == "string" then
		return tool
	end
	return nil
end

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model")
			and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

local function soilOf(plot: Model): BasePart?
	local soil = plot:FindFirstChild(GameConfig.Plot.PlanterName)
	return if soil and soil:IsA("BasePart") then soil else nil
end

--==============================================================================
-- WHERE THE CURSOR IS POINTING, IF IT IS POINTING AT YOUR BED
--
-- GetMouseLocation rather than the input's own position: it is reported without
-- the top-bar inset, which is the space ViewportPointToRay expects, and it is
-- the same call on a phone -- it returns the last touch. One code path for both.
--==============================================================================
-- What the bed is made of, beyond the planter itself. Named rather than
-- inferred: a click must land on the BED, not on a fence rail or a neighbour's
-- plot that happens to be behind it.
local BED_PARTS: { [string]: boolean } = {
	SoilRow = true,
	Clod = true,
}

local function soilPoint(): (Vector3?, BasePart?)
	local camera = workspace.CurrentCamera
	local plot = myPlot()
	if not (camera and plot) then
		return nil, nil
	end
	local soil = soilOf(plot)
	if not soil then
		return nil, nil
	end

	local at = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(at.X, at.Y)

	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	-- See the header: a planted creature must never shadow the bed it stands in.
	local plants = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if plants then
		table.insert(ignore, plants)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if not hit then
		return nil, soil
	end
	--==================================================================
	-- THE BED IS MORE THAN ONE PART, AND THIS TEST STILL THOUGHT IT WAS
	--
	-- This required the ray to land on the single `Soil` planter. Then the bed
	-- was tilled: MapService now raises a SoilRow slab per row on top of that
	-- planter and scatters Clods in the furrows. Both sit ABOVE the planter, so
	-- a click aimed at a row hits the row -- and this returned nil.
	--
	-- The symptom was "I can only place on the ground, not on a soil row",
	-- which is exactly backwards from what a bed is for, and it never reached
	-- the server: the client gave up here, so not even a refusal code was
	-- logged. Every guard in PlaceAt was innocent.
	--
	-- Anything belonging to THIS plot's bed counts. The server does not care
	-- which one was hit: clampToSoil projects the point into the planter's
	-- object space and zeroes Y, so a row, a clod and the planter all flatten
	-- to the same plane before anything is placed.
	--==================================================================
	local instance = hit.Instance
	if instance ~= soil
		and not (BED_PARTS[instance.Name] and instance:IsDescendantOf(plot))
	then
		return nil, soil
	end
	return hit.Position, soil
end

--==============================================================================
-- A DISC WHERE IT WILL LAND
--
-- Without this, "exactly where I clicked" is a claim the player has to take on
-- faith, and the one place it is NOT exact -- the rim of the bed, where the
-- server pulls the point inside -- would read as the click being ignored.
--
-- Sized to the thing's own footprint and tinted by its weight band, so the disc
-- is also the answer to "will this fit here" and "what have I got".
--==============================================================================
local ghost = Instance.new("Part")
ghost.Name = "PlantGhost"
ghost.Shape = Enum.PartType.Cylinder
ghost.Anchored = true
ghost.CanCollide = false
ghost.CanQuery = false
ghost.CanTouch = false
ghost.Material = Enum.Material.Neon
ghost.Transparency = 0.72
ghost.Size = Vector3.new(0.12, 2, 2)
ghost.Parent = workspace

-- How wide the thing in your hands will stand. A pod is its shell; a creature
-- is its head, which is the widest part of every form the builder makes.
local function footprint(species: SeedData.Species, kg: number, hatched: boolean): number
	if not hatched then
		return SeedData.PodDiameter(kg)
	end
	return SeedData.FrameHeight(species, kg) * 0.46 * SeedData.Girth(kg) * 1.5
end

local function hideGhost()
	if ghost.Transparency < 1 then
		ghost.Transparency = 1
	end
end

--==============================================================================
-- PUTTING IT DOWN WITHOUT PLANTING IT
--
-- Hatching equips the creature, and a Tool in your hands is not droppable --
-- deliberately, because a plant you can knock out of somebody's arms is loot,
-- and a plant is not loot. The consequence was that the only way to empty your
-- hands was to plant the thing, so you could not hatch a second pod, could not
-- swap to a different plant in the hotbar, and could not run a raid.
--
-- Unequipping is none of those. It puts the Tool back in the Backpack with
-- everything about it intact -- same kg, same Hatched flag, same slot -- and
-- gives you your hands back. Nothing is placed, nothing is destroyed, nothing
-- is dropped on the floor for a neighbour.
--
-- Roblox's own toolbar click already does this and now actually works: the
-- reason it did not was a CarryWeld left joining a backpacked Handle to the
-- root, which CarryService now cuts on Unequipped. This is the second way in,
-- for anybody not looking at the hotbar.
--
-- BOUND ONLY WHILE SOMETHING IS HELD, because createTouchButton draws a button
-- on a phone and a button that does nothing is worse than no button. It
-- appears with the plant in your hands and goes when they are empty.
--
-- It cannot touch a raid carry. That pod is a Model welded to the root, not a
-- Tool, and UnequipTools does not know it exists -- which is exactly the
-- separation the two channels are supposed to have.
--==============================================================================
local UNEQUIP_ACTION = "SeedUnequip"
local bound = false

local function unequip(_name: string, state: Enum.UserInputState): Enum.ContextActionResult?
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid:UnequipTools()
	end
	return Enum.ContextActionResult.Sink
end

local function setBound(want: boolean)
	if want == bound then
		return
	end
	bound = want
	if want then
		ContextActionService:BindAction(UNEQUIP_ACTION, unequip, true, Enum.KeyCode.Q)
		ContextActionService:SetTitle(UNEQUIP_ACTION, "Put away")
	else
		ContextActionService:UnbindAction(UNEQUIP_ACTION)
	end
end

player.CharacterRemoving:Connect(function()
	hideGhost()
	setBound(false)
end)

RunService.RenderStepped:Connect(function()
	local tool = heldTool()
	setBound(tool ~= nil)
	if not tool then
		hideGhost()
		return
	end
	local species = SeedData.Get(tostring(tool:GetAttribute("SpeciesId")))
	if not species then
		hideGhost()
		return
	end
	local point, soil = soilPoint()
	if not (point and soil) then
		hideGhost()
		return
	end

	local kg = math.clamp(
		tonumber(tool:GetAttribute(ATTR.CarryingKg)) or species.Kg,
		1, GameConfig.Carry.MaxKg)
	local hatched = tool:GetAttribute("Hatched") == true
	local width = footprint(species, kg, hatched)

	-- The same clamp the server applies, so the disc sits where the plant will
	-- actually go rather than where the cursor happens to be. Two copies of one
	-- rule is a risk; a disc that lies about the rim is a certainty.
	local here = soil.CFrame:PointToObjectSpace(point)
	local halfX = math.max(soil.Size.X * 0.5 - PLANTING.EdgeMarginStuds, 0)
	local halfZ = math.max(soil.Size.Z * 0.5 - PLANTING.EdgeMarginStuds, 0)
	local on = soil.CFrame * CFrame.new(
		math.clamp(here.X, -halfX, halfX),
		soil.Size.Y * 0.5 + 0.06,
		math.clamp(here.Z, -halfZ, halfZ))

	ghost.Size = Vector3.new(0.12, width, width)
	-- A cylinder's height runs along its X axis, so it has to be tipped on its
	-- side to lie flat on the soil.
	ghost.CFrame = on * CFrame.Angles(0, 0, math.rad(90))
	ghost.Color = SeedData.ColorForKg(kg)
	ghost.Transparency = 0.72
end)

--==============================================================================
-- THE CLICK
--
-- gameProcessedEvent is what keeps a tap on the Shop panel from planting the
-- pod behind it. The server does the deciding; this only ever asks.
--==============================================================================
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not heldTool() then
		return
	end
	local point = soilPoint()
	if not point then
		return
	end
	channel:FireServer(PLANTING.PlaceAction, point)
end)
