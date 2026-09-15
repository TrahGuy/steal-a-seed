--!strict
--==============================================================================
-- Steal a Seed :: PodMeshService
--
-- Builds the MeshPart templates Dustbowl's pods are cloned from.
--
--==============================================================================
-- WHY A SERVICE AT ALL
--
-- A script can only give a MeshPart its mesh through
-- AssetService:CreateMeshPartAsync, and that yields. CreatureModel.BuildPod must
-- not: it runs in the middle of a nest filling, a take, a bank. So the wait
-- happens once, here, in Init -- before NestService (40) fills a single nest --
-- and every pod after that is a Clone.
--
-- IN REPLICATEDSTORAGE, because clients build pods too: the hotbar's bag cards
-- and the Garden panel both draw one in a viewport, from the same template.
--
-- A TEMPLATE ALREADY THERE WINS. If the owner imports a mesh and drops it at
-- ReplicatedStorage.Assets.Pods by hand, that part is used as it is and nothing
-- is created over it. The id in GameConfig.PodMeshes is still the way this is
-- meant to be wired, because a hand-placed part lives only in the place file.
--
-- NOTHING HERE IS FATAL. An id of 0, a failed load or an asset this experience
-- may not use leaves the template missing, CreatureModel builds the part urn
-- instead, and the boot line says which.
--==============================================================================

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PodMeshService = {}
-- Before NestService (40), CarryService (45) and PlantService (50), every one of
-- which builds pods.
PodMeshService.Priority = 15

local MESHES = GameConfig.PodMeshes

local function log(message: string)
	print("[Seed/PodMeshService] " .. message)
end

-- ReplicatedStorage.Assets.Pods, made if it is missing. ReplicatedStorage's root
-- ignores unknown instances in the Rojo project, so this is never synced away.
local function home(): Instance
	local node: Instance = ReplicatedStorage
	for _, step in ipairs(MESHES.Path) do
		local child = node:FindFirstChild(step)
		if not child then
			child = Instance.new("Folder")
			child.Name = step
			child.Parent = node
		end
		node = child
	end
	return node
end

function PodMeshService.Init()
	local folder = home()
	local names = {}
	for name, spec in pairs(MESHES) do
		if type(spec) == "table" and (spec :: any).Mesh ~= nil then
			table.insert(names, name)
		end
	end
	table.sort(names)

	local ready, waiting, failed = {}, {}, {}
	for _, name in ipairs(names) do
		local existing = folder:FindFirstChild(name)
		local id = tonumber((MESHES :: any)[name].Mesh) or 0
		if existing and existing:IsA("MeshPart") then
			table.insert(ready, name .. " (placed by hand)")
		elseif id <= 0 then
			table.insert(waiting, name)
		else
			local ok, result = pcall(function()
				return AssetService:CreateMeshPartAsync("rbxassetid://" .. tostring(id), {
					-- Box: nothing collides with a pod, and a take is a prompt,
					-- not a raycast against the shell's outline.
					CollisionFidelity = Enum.CollisionFidelity.Box,
					RenderFidelity = Enum.RenderFidelity.Automatic,
				})
			end)
			if ok and typeof(result) == "Instance" and result:IsA("MeshPart") then
				result.Name = name
				result.Anchored = true
				result.CanCollide = false
				result.CanQuery = false
				result.CanTouch = false
				result.Parent = folder
				table.insert(ready, string.format("%s (%d)", name, id))
			else
				table.insert(failed, string.format("%s (%d: %s)", name, id, tostring(result)))
			end
		end
	end

	if #ready > 0 then
		log("Ready: " .. table.concat(ready, ", ") .. ".")
	end
	if #waiting > 0 then
		log("Waiting for a mesh id, so these pods stay part-built: "
			.. table.concat(waiting, ", ") .. ". Import the FBX in art/ai generated pods/ "
			.. "with Studio's 3D Importer and put the mesh id in GameConfig.PodMeshes.")
	end
	if #failed > 0 then
		warn("[Seed/PodMeshService] Could not build " .. table.concat(failed, ", ")
			.. ". Those pods stay part-built.")
	end
end

return PodMeshService
