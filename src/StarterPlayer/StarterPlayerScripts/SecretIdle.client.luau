--!strict
-- Steal a Seed :: SecretIdle (client)
--
-- Plays the secret plants' idle over every replayed rig in the world. One
-- RenderStepped over a tagged set, the shape ParentAnim and Ambience use; the
-- maths and the kinematic tree live in Shared/SecretIdle.
--
-- A rig is registered when its tag (SecretModel.RIG_TAG, added last by the
-- builder) lands and the model is in the Workspace: a hotbar or Index viewport
-- copy is not, and stays still. A reveal copy loses the tag to HatchFX's scrub
-- and stays still too. Parts that arrive late by streaming rebuild the tree.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SecretIdle = require(Shared:WaitForChild("SecretIdle"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))

local TAG = SecretModel.RIG_TAG
-- Only a planted Secret walks (2026-10-02): its legs step to the leg PlantService
-- gave it. A copy carried overhead or shown in a viewport moves with whoever
-- holds it, and its legs stay in the idle.
local PLANTED = GameConfig.Tags.Planted
-- Past this distance a rig steps every fourth frame; nobody can see a blink.
local NEAR = 260
local REBUILD_AFTER = 0.5

type Entry = {
	rig: SecretIdle.Rig?,
	dirtyAt: number?,
	watches: { RBXScriptConnection },
	skip: number,
}

local entries: { [Model]: Entry } = {}

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

local function consider(model: Instance)
	if not model:IsA("Model") or entries[model] or not model:IsDescendantOf(workspace) then
		return
	end
	local entry: Entry = { rig = nil, dirtyAt = os.clock(), watches = {}, skip = 0 }
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

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	for model, entry in pairs(entries) do
		--======================================================================
		-- NOT HERE YET IS NOT GONE (2026-10-01)
		--
		-- This used to DROP a model whose PrimaryPart was nil. A planted plant
		-- streams in part by part and its pivot can arrive a frame after its
		-- tag, so the plant was dropped on arrival and, its tag already there,
		-- never registered again: measured in Play, a planted Snarlbloom's vine
		-- bud travelled 13.1-13.6 studs from its base (PlantSway's lean alone)
		-- instead of the idle's 9.3-16.7, until it was re-tagged by hand.
		--
		-- So it waits, and the tree is built half a second after the pivot is
		-- there. Leaving for good is the ancestry and tag watches' to decide.
		--======================================================================
		if not model.PrimaryPart or not model:IsDescendantOf(workspace) then
			entry.rig = nil
			entry.dirtyAt = now
			continue
		end
		-- The tree is rebuilt half a second after the last part arrived or left,
		-- so a streamed-in limb joins and a streamed-out one is forgotten.
		local dirtyAt = entry.dirtyAt
		if dirtyAt and now - dirtyAt >= REBUILD_AFTER then
			entry.dirtyAt = nil
			entry.rig = SecretIdle.Rig(model)
		end
		local rig = entry.rig
		if rig then
			rig.walks = CollectionService:HasTag(model, PLANTED)
			local far = (model:GetPivot().Position - eye).Magnitude > NEAR
			entry.skip = if far then (entry.skip + 1) % 4 else 0
			if entry.skip == 0 then
				SecretIdle.Step(rig, now)
			end
		end
	end
end)
