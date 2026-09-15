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
-- not: it runs in the middle of a nest filling, a take, a bank. So the fetch
-- happens once, here, and every pod after that is a Clone.
--
--==============================================================================
-- IT NEVER HOLDS UP THE BOOT
--
-- The first version fetched in Init, and Init runs inline in ServerMain's boot:
-- about 1.5 seconds of every server start was spent waiting on two meshes. A
-- Play Solo player joins inside a wait like that, which put their plot handout
-- ahead of PlantService's listener -- their saved garden was never restored,
-- and the next thing they planted saved an empty bed over it. The owner lost
-- their garden to exactly that on 2026-09-15.
--
-- So the fetch runs on its own thread and Init returns at once, which puts the
-- boot back to the timing it had before this service existed. (PlotService now
-- replays assignments to late listeners as well, so a wait anywhere else in the
-- boot can no longer do the same damage.)
--
-- The one cost is that nests stock at Start, before a cold fetch finishes, so
-- the first Dustbowl pods can come out as part-built urns. When the templates
-- arrive, NestService rebuilds exactly those pods in place with the same roll.
--
--==============================================================================
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
-- instead, and the log says which.
--==============================================================================

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local NestService = require(script.Parent:WaitForChild("NestService"))

local PodMeshService = {}
-- Before NestService (40), CarryService (45) and PlantService (50), every one of
-- which builds pods. The order only decides who starts the fetch; nothing waits.
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

local function fetchTemplates(folder: Instance)
	local names = {}
	for name, spec in pairs(MESHES) do
		if type(spec) == "table" and (spec :: any).Mesh ~= nil then
			table.insert(names, name)
		end
	end
	table.sort(names)

	local ready, waiting, failed = {}, {}, {}
	local built = 0
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
				built += 1
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

	-- Anything a nest stocked before the fetch finished: a Dustbowl pod whose
	-- shell is still a Part.
	if built > 0 then
		local rebuilt = NestService.RebuildPods(function(pod: Model): boolean
			local species = SeedData.Get(tostring(pod:GetAttribute("SpeciesId")))
			local shell = pod.PrimaryPart
			return species ~= nil and species.Biome == "dustbowl"
				and shell ~= nil and not shell:IsA("MeshPart")
		end)
		if rebuilt > 0 then
			log(string.format("Rebuilt %d Dustbowl nest pod(s) stocked before the meshes arrived.",
				rebuilt))
		end
	end
end

function PodMeshService.Init()
	local folder = home()
	-- Its own thread: see IT NEVER HOLDS UP THE BOOT.
	task.spawn(fetchTemplates, folder)
end

return PodMeshService
