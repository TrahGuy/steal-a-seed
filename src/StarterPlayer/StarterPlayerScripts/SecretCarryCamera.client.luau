--!strict
-- Steal a Seed :: SecretCarryCamera
--
-- While the local player carries a secret pod or plant over their head
-- (SeedData Carry = "overhead"), the gameplay camera has to show the whole
-- thing: the models are 21 to 47 studs tall and the default 13-stud zoom sees
-- 18 studs of height. So this raises the camera's focus to the middle of the
-- stack (Humanoid.CameraOffset) and lifts the ZOOM FLOOR (CameraMinZoomDistance)
-- to the distance that fits it -- the player can still scroll OUT past it, and
-- the ceiling is raised only if it was below the floor. Nothing locks.
--
-- Everything is put back on release, on death and when the character goes:
-- the saved numbers also sit on the player as attributes so ThrowFX's own
-- capture (a throw mid-carry) restores the player's values, not this file's.
--
-- APPROVED AS A PROTOTYPE (the owner, 2026-10-01): walls and phone framing are
-- part of the test, not assumed.
--
-- 2026-10-03: a hatched plant built from the owner's supplied rigs is carried
-- overhead too (PlantForms.CarriedOverhead), at its tier's size, so the same
-- framing applies to it; its pod is not, and is left alone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local PlantForms = require(Shared:WaitForChild("PlantForms"))

local player = Players.LocalPlayer
local CARRYING_SPECIES = GameConfig.Attributes.CarryingSpecies
local ATTR_MIN = "SeedCarryCamMin"
local ATTR_MAX = "SeedCarryCamMax"
-- A little air above and below the stack.
local MARGIN = 1.12
-- The feet are about this far under the HumanoidRootPart.
local FEET = 3

type Saved = { min: number, max: number, offset: Vector3, humanoid: Humanoid }
local saved: Saved? = nil

-- How big the overhead carry in the player's hands is right now, or nil: a raid
-- pod by the player attributes, a Tool by its SpeciesId, Hatched and tier. A
-- secret or Rain form is its authored size; a rigged plant its tier's; the
-- Rain event's second family's pod its size's own supplied shell (2026-10-05).
local function carriedSize(character: Model?): Vector3?
	local id = player:GetAttribute(CARRYING_SPECIES)
	local hatched = false
	local tier: any = player:GetAttribute(GameConfig.Attributes.CarryingKg)
	if type(id) ~= "string" and character then
		for _, d in ipairs(character:GetChildren()) do
			if d:IsA("Tool") then
				id = d:GetAttribute("SpeciesId")
				hatched = d:GetAttribute("Hatched") == true
				tier = d:GetAttribute(GameConfig.Attributes.CarryingKg)
				break
			end
		end
	end
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	if not species or not PlantForms.CarriedOverhead(species, hatched) then
		return nil
	end
	-- A plant built from a supplied rig is its tier's size -- the second
	-- family's as much as the road's.
	if hatched and PlantForms.Has(species.Id) then
		return PlantForms.SizeAt(species.Id, SeedData.SizeScale(tonumber(tier)))
	end
	if (species :: any).Carry == "overhead" then
		local form = if hatched then species.Id else SeedData.PodFormOf(species, tonumber(tier))
		return if form then SecretModel.Size(form) else nil
	end
	return PlantForms.SizeAt(species.Id, SeedData.SizeScale(tonumber(tier)))
end

local function restore()
	local kept = saved
	if not kept then
		return
	end
	saved = nil
	player.CameraMinZoomDistance = kept.min
	player.CameraMaxZoomDistance = kept.max
	if kept.humanoid.Parent then
		kept.humanoid.CameraOffset = kept.offset
	end
	player:SetAttribute(ATTR_MIN, nil)
	player:SetAttribute(ATTR_MAX, nil)
end

local function fit(size: Vector3?, humanoid: Humanoid)
	if not size then
		restore()
		return
	end
	local camera = workspace.CurrentCamera
	local fov = if camera then camera.FieldOfView else 70
	local top = GameConfig.Carry.OverheadLift + size.Y
	local half = (top + FEET) * 0.5
	local centre = (top - FEET) * 0.5
	local distance = half / math.tan(math.rad(fov * 0.5)) * MARGIN + 2
	if not saved or saved.humanoid ~= humanoid then
		if saved then
			restore()
		end
		saved = {
			min = player.CameraMinZoomDistance,
			max = player.CameraMaxZoomDistance,
			offset = humanoid.CameraOffset,
			humanoid = humanoid,
		}
		player:SetAttribute(ATTR_MIN, saved.min)
		player:SetAttribute(ATTR_MAX, saved.max)
	end
	local kept = saved :: Saved
	if kept.max < distance then
		player.CameraMaxZoomDistance = distance
	end
	player.CameraMinZoomDistance = math.max(kept.min, distance)
	humanoid.CameraOffset = Vector3.new(0, centre, 0)
end

local function evaluate()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local size = carriedSize(character)
	if size and humanoid and humanoid.Health > 0 then
		fit(size, humanoid)
	else
		restore()
	end
end

player:GetAttributeChangedSignal(CARRYING_SPECIES):Connect(evaluate)

local function onCharacter(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(evaluate)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(evaluate)
		end
	end)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(restore)
	end
	evaluate()
end
player.CharacterRemoving:Connect(restore)
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end
