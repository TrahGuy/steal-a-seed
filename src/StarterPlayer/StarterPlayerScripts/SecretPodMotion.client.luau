--!strict
-- Steal a Seed :: SecretPodMotion (client)
--
-- Plays the owner's biome secret pod scripts (Shared/SecretPodMotion, 2026-10-16)
-- where this screen should see them:
--
--   * Scourwheel's and Nebulisk's pods, on their cradle or loose (the SeedPod
--     tag): anchored, in the Workspace and within PodModels.Motion.Range of the
--     camera, on PodMotion's cadence. REDUCED FX puts them at rest. One that is
--     picked up gets its sizes, colours and lights back, and its parts are left
--     to the welds that now hold them.
--   * Grovemaw's pod in anyone's hands once it is READY TO HATCH (its Tool's
--     HatchAt has come): the lid swings open, and stays open. Under REDUCED FX it
--     opens at once.
--
-- A Bag, hotbar or panel picture is a viewport copy, not in the Workspace, and
-- stays still.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local BiomeSecretForms = require(Shared:WaitForChild("BiomeSecretForms"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local SecretPodMotion = require(Shared:WaitForChild("SecretPodMotion"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local M = GameConfig.PodModels.Motion
local SEED_POD = GameConfig.Tags.SeedPod
local HATCH_AT = GameConfig.HatchInBag.Attribute
-- A pod streamed or rebuilt is measured this long after its last part arrived.
local REBUILD_AFTER = 0.3

type Entry = {
	rig: SecretPodMotion.Rig?,
	dirtyAt: number?,
	watches: { RBXScriptConnection },
	-- Which frame of the cadence this pod steps on.
	slot: number,
}

local entries: { [Model]: Entry } = {}
local nextSlot = 0
local frame = 0

-- Its sizes, colours and lights back, wherever its parts now are.
local function settle(entry: Entry)
	local rig = entry.rig
	if rig and not rig.still then
		SecretPodMotion.Rest(rig, false)
	end
	entry.rig = nil
end

local function drop(model: Model)
	local entry = entries[model]
	if not entry then
		return
	end
	settle(entry)
	for _, c in ipairs(entry.watches) do
		c:Disconnect()
	end
	entries[model] = nil
end

local function consider(instance: Instance)
	if not instance:IsA("Model") or entries[instance] then
		return
	end
	local model = instance :: Model
	-- The form is written by the builder before the pod is parented and tagged.
	if not SecretPodMotion.HasIdle(model:GetAttribute(SecretModel.FORM_ATTRIBUTE)) then
		return
	end
	nextSlot += 1
	local entry: Entry = { rig = nil, dirtyAt = os.clock(), watches = {}, slot = nextSlot }
	entries[model] = entry
	local function dirty()
		entry.dirtyAt = os.clock()
	end
	table.insert(entry.watches, model.DescendantAdded:Connect(dirty))
	table.insert(entry.watches, model.DescendantRemoving:Connect(dirty))
	table.insert(entry.watches, model:GetPropertyChangedSignal("PrimaryPart"):Connect(dirty))
	table.insert(entry.watches, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(game) then
			drop(model)
		end
	end))
end

for _, model in ipairs(CollectionService:GetTagged(SEED_POD)) do
	consider(model)
end
CollectionService:GetInstanceAddedSignal(SEED_POD):Connect(consider)
CollectionService:GetInstanceRemovedSignal(SEED_POD):Connect(function(model)
	if model:IsA("Model") then
		drop(model)
	end
end)

--==============================================================================
-- GROVEMAW'S LID, IN THE HANDS
--==============================================================================
-- The species whose pod's lid opens when it is ready.
local lidSpecies: { [string]: boolean } = {}
for _, species in ipairs(SeedData.SecretSpecies) do
	if SecretPodMotion.HasLid(SeedData.PodFormOf(species, SeedData.SecretTier)) then
		lidSpecies[species.Id] = true
	end
end
local lidSpec = BiomeSecretForms.Pods.grovemawpod
local lidSeconds = if lidSpec and lidSpec.Owner and type(lidSpec.Owner.OpenDuration) == "number"
	then lidSpec.Owner.OpenDuration
	else SecretPodMotion.LidSeconds

type Opening = { lid: SecretPodMotion.Lid, from: number, startedAt: number, seconds: number }
local openings: { [Tool]: Opening } = {}

-- REDUCED FX (or Roblox's own reduced motion), looked at twice a second, with
-- every held pod.
local reduced = StatusText.reducedMotion()
local nextLook = 0

local function lookLids(now: number)
	local serverNow = Workspace:GetServerTimeNow()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		for _, child in ipairs(character:GetChildren()) do
			if not child:IsA("Tool") or openings[child] then
				continue
			end
			local id = child:GetAttribute("SpeciesId")
			local due = child:GetAttribute(HATCH_AT)
			if type(id) == "string" and lidSpecies[id] and child:GetAttribute("Hatched") ~= true
				and type(due) == "number" and due <= serverNow then
				local lid = SecretPodMotion.Lid(child)
				if lid then
					openings[child] = { lid = lid, from = lid.open, startedAt = now, seconds = if reduced then 0 else lidSeconds }
				end
			end
		end
	end
	for tool in pairs(openings) do
		if not tool:IsDescendantOf(game) then
			openings[tool] = nil
		end
	end
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	frame += 1
	if now >= nextLook then
		nextLook = now + 0.5
		reduced = StatusText.reducedMotion()
		lookLids(now)
	end
	for tool, o in pairs(openings) do
		if o.lid.open < 1 and tool:IsDescendantOf(Workspace) then
			SecretPodMotion.SetLid(o.lid, SecretPodMotion.LidAt(o.from, 1, now - o.startedAt, o.seconds))
		end
	end
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	for model, entry in pairs(entries) do
		local shell = model.PrimaryPart
		local live = shell ~= nil and shell.Anchored and model:IsDescendantOf(Workspace)
			and CollectionService:HasTag(model, SEED_POD)
		if not live then
			settle(entry)
			entry.dirtyAt = now
			continue
		end
		local dirtyAt = entry.dirtyAt
		if dirtyAt and now - dirtyAt >= REBUILD_AFTER then
			entry.dirtyAt = nil
			entry.rig = SecretPodMotion.Rig(model)
		end
		local rig = entry.rig
		if not rig then
			continue
		end
		local away = ((shell :: BasePart).Position - eye).Magnitude
		if away <= M.Range and not reduced then
			local every = if away <= M.NearStuds then M.NearEvery else M.FarEvery
			if (frame + entry.slot) % every == 0 or rig.still then
				SecretPodMotion.Step(rig, now)
			end
		elseif not rig.still then
			SecretPodMotion.Rest(rig, true)
		end
	end
end)
