--!strict
-- Steal a Seed :: PodMotion (client)
--
-- Plays the owner's pods' idles (Shared/PodMotion) over every pod PodModel
-- built that this screen should see move. One RenderStepped over a tagged set,
-- the shape SecretIdle uses.
--
-- WHICH PODS MOVE: in the Workspace; anchored (a carried, held or hauled copy
-- is welded and unanchored, and writing its parts would move the body or the
-- guardian holding it); a nest's or a loose pod (SeedPod), a planted one
-- (Planted) or one on a stand (GameConfig.PodModels.Motion.ShowcaseAttribute);
-- and within Range studs of the camera. A Bag, hotbar or panel picture is in a
-- viewport, not the Workspace, and stays still.
--
-- HOW OFTEN: moving anchored parts costs about 5 us a part a frame, so a pod
-- steps every NearEvery frames within NearStuds and every FarEvery beyond, each
-- on its own frame of the cadence (GameConfig.PodModels.Motion).
--
-- A POD THAT STOPS QUALIFYING IS NOT WRITTEN AGAIN. A burst takes the Planted
-- tag off first and tweens the parts from the server; a pick-up welds them; a
-- Bag hatch's shell carries neither tag. Whoever has it now owns its parts. One
-- that leaves range, or every pod when REDUCED FX goes on, is put back at rest
-- once and left.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PodModel = require(Shared:WaitForChild("PodModel"))
local PodMotion = require(Shared:WaitForChild("PodMotion"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local M = GameConfig.PodModels.Motion
local TAG = PodModel.TAG
local SEED_POD = GameConfig.Tags.SeedPod
local PLANTED = GameConfig.Tags.Planted
local SHOWCASE = M.ShowcaseAttribute
-- A pod streamed or rebuilt is measured this long after its last part arrived.
local REBUILD_AFTER = 0.3
-- One long frame (a hitch, a tab-out) never throws an idle forward; a pod
-- stepped every fourth frame at 15 fps still keeps time.
local MAX_STEP = 0.3

type Entry = {
	rig: PodMotion.Rig?,
	dirtyAt: number?,
	watches: { RBXScriptConnection },
	-- Which frame of the cadence this pod steps on, and when it last stepped.
	slot: number,
	lastStep: number,
}

local entries: { [Model]: Entry } = {}
local nextSlot = 0
local frame = 0

local function drop(model: Model)
	local entry = entries[model]
	if not entry then
		return
	end
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
	nextSlot += 1
	local entry: Entry = { rig = nil, dirtyAt = os.clock(), watches = {}, slot = nextSlot, lastStep = os.clock() }
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

for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	consider(model)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(consider)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(model)
	if model:IsA("Model") then
		drop(model)
	end
end)

-- REDUCED FX (or Roblox's own reduced motion), looked at twice a second.
local reduced = StatusText.reducedMotion()
local nextLook = 0

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	frame += 1
	if now >= nextLook then
		nextLook = now + 0.5
		reduced = StatusText.reducedMotion()
	end
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	for model, entry in pairs(entries) do
		local shell = model.PrimaryPart
		local live = shell ~= nil and shell.Anchored and model:IsDescendantOf(Workspace)
			and (CollectionService:HasTag(model, SEED_POD) or CollectionService:HasTag(model, PLANTED)
				or model:GetAttribute(SHOWCASE) == true)
		if not live then
			-- Nothing written: whoever has it now owns its parts. Measured again
			-- if it ever qualifies again.
			entry.rig = nil
			entry.dirtyAt = now
			continue
		end
		local dirtyAt = entry.dirtyAt
		if dirtyAt and now - dirtyAt >= REBUILD_AFTER then
			entry.dirtyAt = nil
			entry.rig = PodMotion.Rig(model)
		end
		local rig = entry.rig
		if not rig then
			continue
		end
		local away = ((shell :: BasePart).Position - eye).Magnitude
		if away <= M.Range and not reduced then
			-- On this pod's own frame of the cadence: every NearEvery frames close
			-- up, every FarEvery further off. The step covers the time since its last.
			local every = if away <= M.NearStuds then M.NearEvery else M.FarEvery
			if (frame + entry.slot) % every == 0 or rig.still then
				PodMotion.Step(rig, now, math.min(now - entry.lastStep, MAX_STEP), model:GetAttribute("Ready") == true)
				entry.lastStep = now
			end
		elseif not rig.still then
			PodMotion.Rest(rig)
		end
	end
end)
