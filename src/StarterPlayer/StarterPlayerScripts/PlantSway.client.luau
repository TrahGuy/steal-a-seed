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
-- Sized in STUDS OF HEAD TRAVEL, not in degrees. Degrees are the wrong unit for
-- a set of models that run from 1.7 to 6.4 studs tall: the same angle is a
-- twitch on one and a swing on the other. So the travel is chosen and the angle
-- solved from it -- travel = 2 * h * sin(amp).
--
-- A 2 kg Nubkin's head covers about 0.67 studs a cycle, a 110 kg Bellchime's
-- about 0.35 and more slowly. That is the same fact the silhouette carries --
-- weight -- said a second way.
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
	-- Where the model was, so it can be put back exactly.
	rest: CFrame,
	-- AN UPRIGHT FRAME AT THE BASE. Pure translation, so its axes are the
	-- world's: tipping about X or Z is a lean, and nothing is a twist. See the
	-- block above apply().
	anchor: CFrame,
	-- The model's rest pose expressed in the anchor's frame, so the lean can be
	-- applied about the anchor and the model put back on top of it.
	offset: CFrame,
	-- Radians.
	amp: number,
	speed: number,
	phase: number,
	-- Studs from the base to the highest part, which is what turns an angle
	-- into visible movement.
	headHeight: number,
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

		--==================================================================
		-- MEASURE THE THING, THEN SIZE THE MOTION TO IT
		--
		-- World-space extents from every part's own corners. GetBoundingBox
		-- reports in the PIVOT's frame and this model pivots on a rolled
		-- cylinder, so it returns axes that are not the world's -- the same
		-- trap that made the creature-size numbers wrong the first time.
		--==================================================================
		local lo = Vector3.new(math.huge, math.huge, math.huge)
		local hi = -lo
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local h = d.Size * 0.5
				for sx = -1, 1, 2 do
					for sy = -1, 1, 2 do
						for sz = -1, 1, 2 do
							local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
							lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
							hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
						end
					end
				end
			end
		end
		local headHeight = math.max(hi.Y - lo.Y, 0.5)
		-- The base of the model, dead centre. This is the soil, and it is what
		-- a plant leans about.
		local anchor = CFrame.new((lo.X + hi.X) * 0.5, lo.Y, (lo.Z + hi.Z) * 0.5)
		local rest = model:GetPivot()

		--==================================================================
		-- THE AMPLITUDE IS DERIVED FROM HOW FAR THE HEAD SHOULD TRAVEL
		--
		-- Not from a fixed angle. A Nubkin is 1.7 studs tall and a Bellchime
		-- 6.4, so one angle gives them wildly different motion -- and the old
		-- fixed ~3 degrees moved a Nubkin's head about five hundredths of a
		-- stud, which is why a bed of them read as furniture.
		--
		-- Pick the TRAVEL, then solve for the angle: travel = 2 * h * sin(amp).
		-- Heavier travels less, which is the same fact the silhouette carries.
		--==================================================================
		local travel = math.clamp(0.75 / (kg ^ 0.16), 0.30, 0.75)
		local amp = math.clamp(travel / (2 * headHeight), 0.006, math.rad(14))

		local entry: Sway = {
			model = model,
			rest = rest,
			anchor = anchor,
			offset = anchor:Inverse() * rest,
			amp = amp,
			-- Heavier is slower. A gentle power of weight, like every other
			-- curve here: 110 kg is fifty-five times 2 kg and nothing should be
			-- fifty-five times anything.
			speed = math.clamp(1.1 / (kg ^ 0.12), 0.35, 1.4),
			-- PHASED BY SLOT, so a bed is not a chorus line. Irrational-ish
			-- multiplier so twelve slots do not land on a common period.
			phase = (tonumber(model:GetAttribute("SlotIndex")) or 0) * 0.9,
			headHeight = headHeight,
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
	-- ABOUT THE ANCHOR, NOT THE PIVOT. `rest * CFrame.Angles(ax, 0, az)` reads
	-- like a lean and is not one: the model's pivot is the Mound, which
	-- upright() builds as a cylinder rolled 90 degrees, so the pivot's local X
	-- IS WORLD UP. Measured on a live Bellchime:
	--
	--     6 deg about pivot-local X -> highest part moves 0.0821 studs
	--     6 deg about pivot-local Z -> highest part moves 0.6224 studs
	--
	-- The dominant `ax` term was spinning the plant about its own stem, which on
	-- a round head is invisible, and the only real lean was the 0.62x term at a
	-- degree or two. A bed of these was measurably swaying and visibly still.
	--
	-- The anchor is a pure translation at the base, so its axes are the world's:
	-- X and Z both tip, nothing twists.
	entry.model:PivotTo(entry.anchor * CFrame.Angles(ax, 0, az) * entry.offset)
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
