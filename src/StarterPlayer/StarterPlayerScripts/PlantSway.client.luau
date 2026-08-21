--!strict
-- Steal a Seed :: PlantSway
--
-- The idle sway on anything growing in a plot. Grown creatures and sprouts were
-- statues: a bed of twelve looked like a shelf of ornaments rather than a row of
-- living things.
--
--==============================================================================
-- THEY ARE ROOTED, AND THAT IS THE WHOLE DESIGN
--
-- No Humanoid, no pathfinding, no leaving the slot. A plant that WALKS is a
-- performance bug wearing a costume -- seventy-two Humanoids on a full server,
-- each running a state machine and a floor raycast, to move things that are
-- supposed to be planted in the ground.
--
-- So the motion is a LEAN, not a step. The model is pivoted about its own base
-- by a couple of degrees. It never leaves the slot because the pivot IS the
-- slot.
--
--==============================================================================
-- CLIENT ONLY, SAME SPLIT AS THE FAIRY
--
-- The server builds the plant, tags it, and never moves it again. Every client
-- leans its own local copy. Plant parts are ANCHORED, so a CFrame written here
-- is local to this machine and there is nothing for the server to fight with --
-- exactly the arrangement Ambience uses for Marigold's wings.
--
--==============================================================================
-- ONE PivotTo PER PLANT, AND NOT EVERY PLANT EVERY FRAME
--
-- A grown creature is fifteen-odd parts. Writing every part's CFrame would be a
-- thousand property writes a frame on a full server, which is exactly the kind
-- of thing the mobile-first rule exists to stop.
--
-- Instead: one PivotTo per plant -- a single engine call that moves the whole
-- model -- and the set is walked in SLICES, so each plant updates about twenty
-- times a second rather than sixty. The sway has a six-to-ten second period; at
-- 20 Hz each step is a fraction of a degree and nothing looks stepped.
--
--==============================================================================
-- HEAVY THINGS MOVE LESS, AND SLOWER
--
-- A 2 kg Nubkin leans ~2.8 degrees on a ~6 second cycle. A 110 kg Bellchime
-- leans ~1.4 on a ~10 second one. That is the same fact the silhouette now
-- carries -- weight -- said a second way, so a heavy plant reads as heavy even
-- in the corner of your eye.
--
-- Never enough to look like it will fall over. This is breathing, not toppling.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local PLANTED = GameConfig.Tags.Planted

-- Pods do not sway. A pod is an egg lying on the soil; the sway is a stem
-- leaning, and a thing with no stem leaning reads as a wobble.
local STAGE_SPROUT = 2

-- Roughly how often each plant is refreshed. The set is walked in slices to
-- hit this, whatever the frame rate and however many plants there are.
local TARGET_HZ = 20

type Sway = {
	model: Model,
	rest: CFrame,
	-- Radians, and small.
	amp: number,
	speed: number,
	phase: number,
}

-- Both an array (to walk in slices) and a map (to find one by model on removal).
local list: { Sway } = {}
local index: { [Model]: number } = {}

local connections: { RBXScriptConnection } = {}
local clock = 0
local cursor = 1

--==============================================================================
-- REGISTERING
--==============================================================================
local function forget(instance: Instance)
	local model = instance :: Model
	local at = index[model]
	if not at then
		return
	end
	-- Put it back where the server built it, so a plant that stops swaying does
	-- not freeze mid-lean.
	local entry = list[at]
	if entry.model.Parent then
		pcall(function()
			entry.model:PivotTo(entry.rest)
		end)
	end
	-- Swap-remove: order does not matter and this keeps removal O(1) rather
	-- than shuffling a table that can hold seventy-two entries.
	local last = #list
	list[at] = list[last]
	index[list[at].model] = at
	list[last] = nil
	index[model] = nil
	if cursor > #list then
		cursor = 1
	end
end

local function remember(instance: Instance)
	if not instance:IsA("Model") or index[instance :: Model] then
		return
	end
	local model = instance :: Model
	task.spawn(function()
		-- The model can be tagged before its parts have replicated, which is
		-- when PrimaryPart is still nil. ParentAnim drew nothing for a whole
		-- session by reading it once and giving up.
		local deadline = os.clock() + 5
		while not model.PrimaryPart and model.Parent and os.clock() < deadline do
			task.wait(0.1)
		end
		if not (model.Parent and model.PrimaryPart) then
			return
		end
		if not CollectionService:HasTag(model, PLANTED) or index[model] then
			return
		end
		local stage = tonumber(model:GetAttribute("Stage")) or 0
		if stage < STAGE_SPROUT then
			return
		end
		local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
		if not species then
			return
		end

		local kg = math.max(species.Kg, 0.001)
		local entry: Sway = {
			model = model,
			rest = model:GetPivot(),
			-- Both curves are gentle powers of weight rather than ratios, for
			-- the same reason every other curve here is: 110 kg is fifty-five
			-- times 2 kg and nothing should be fifty-five times anything.
			amp = math.clamp(0.055 / (kg ^ 0.18), 0.012, 0.06),
			speed = math.clamp(1.1 / (kg ^ 0.12), 0.35, 1.4),
			-- PHASED BY SLOT, so a bed is not a chorus line. Irrational-ish
			-- multiplier so twelve slots do not land on a common period.
			phase = (tonumber(model:GetAttribute("SlotIndex")) or 0) * 0.9,
		}
		local at = #list + 1
		list[at] = entry
		index[model] = at
	end)
end

--==============================================================================
-- THE LEAN
--
-- Two axes at different rates, so the top traces a slow lopsided oval instead of
-- swinging flat like a metronome. Nothing is allocated here: the CFrames are
-- temporaries the VM reuses, and there is not an Instance.new in sight.
--==============================================================================
local function apply(entry: Sway, now: number)
	local t = now * entry.speed + entry.phase
	local ax = entry.amp * math.sin(t)
	-- 0.73 rather than 0.5 or 2.0: a rational ratio would close the oval into a
	-- repeating figure and the eye picks that up as machinery.
	local az = entry.amp * 0.62 * math.sin(t * 0.73 + entry.phase * 1.3)
	entry.model:PivotTo(entry.rest * CFrame.Angles(ax, 0, az))
end

for _, instance in ipairs(CollectionService:GetTagged(PLANTED)) do
	remember(instance)
end
table.insert(connections, CollectionService:GetInstanceAddedSignal(PLANTED):Connect(remember))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(PLANTED):Connect(forget))

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	clock += dt
	local n = #list
	if n == 0 then
		return
	end
	-- How many to touch this frame to give every plant ~TARGET_HZ. Rounded up so
	-- a small bed still updates every plant every frame rather than none of them.
	local slice = math.min(n, math.max(1, math.ceil(n * TARGET_HZ * dt)))
	for _ = 1, slice do
		if cursor > #list then
			cursor = 1
		end
		local entry = list[cursor]
		if not entry then
			break
		end
		if not entry.model.Parent then
			-- Destroyed without the tag signal arriving first.
			forget(entry.model)
		else
			apply(entry, clock)
			cursor += 1
		end
	end
end))

--==============================================================================
-- RE-RUN SAFE
--
-- A LocalScript re-running would otherwise leave the old Heartbeat and both tag
-- signals connected, and two loops pivoting the same plants against two
-- different rest poses is a plant that shakes.
--==============================================================================
script.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, entry in ipairs(list) do
		if entry.model.Parent then
			pcall(function()
				entry.model:PivotTo(entry.rest)
			end)
		end
	end
	table.clear(list)
	table.clear(index)
end)
