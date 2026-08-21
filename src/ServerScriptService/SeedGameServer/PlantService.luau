--!strict
-- Steal a Seed :: PlantService
--
-- Putting a banked pod into the ground, and growing it into the creature.
--
--==============================================================================
-- THIS IS WHERE THE RAID PAYS
--
-- Everything before it is risk: the walk out, the hold next to a sleeping
-- monster, the run home with a weight on your back. None of that pays anything.
-- Planting is the moment the trip turns into a thing you own and can see from
-- across the field.
--
-- Which is why growth is VISIBLE and staged rather than a timer with a number
-- on it. A pod, then a sprout, then the creature. A plot half way through is
-- readable at a glance -- by its owner, and by anybody walking past deciding
-- whether it is worth coming back to.
--
--==============================================================================
-- PLANTED WITH THE TOOL, NOT WITH A PROMPT
--
-- You are holding the thing. Clicking to plant it is the shortest possible
-- distance between intent and action, and it works unchanged on a phone, where
-- activating a tool is a tap.
--
-- A ProximityPrompt on every slot would have meant twelve prompts per plot, six
-- plots of them competing for the same keypress, and a player hunting for the
-- one that lights up.
--
--==============================================================================
-- GROWTH IS ABSOLUTE TIME, SO IT KEEPS GOING WHILE YOU ARE AWAY
--
-- PlantedAt is os.time(), not a countdown. A plant left overnight is grown when
-- you come back; a countdown would have paused the moment you logged off, which
-- turns a garden into a screensaver and quietly punishes anybody with a life.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(script.Parent:WaitForChild("CreatureModel"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PLOT = GameConfig.Plot

local PlantService = {}
-- After CarryService (45), which is what puts the Tool in the hotbar.
PlantService.Priority = 50

type Planted = {
	plot: Model,
	slot: number,
	species: SeedData.Species,
	-- os.time(), absolute.
	plantedAt: number,
	stage: number,
	model: Model?,
}

-- plot -> slotIndex -> Planted
local growing: { [Model]: { [number]: Planted } } = {}
local serviceConnections: { RBXScriptConnection } = {}
local hooked: { [Tool]: true } = {}
local running = false

-- All three live in GameConfig because THE CLIENT NEEDS THEM: the hatch timer
-- counts down to the next stage, so it has to compute the same thresholds this
-- does. Private constants here would have let the countdown and the transition
-- drift apart.
local PLANTING = GameConfig.Plant
local SPROUT_AT = PLANTING.SproutAt
local TICK = PLANTING.TickSeconds
local PLANT_RANGE = PLANTING.RangeStuds

local function log(message: string)
	print("[Seed/PlantService] " .. message)
end

--==============================================================================
-- SLOTS
--==============================================================================
local function slotsOf(plot: Model): { [number]: Attachment }
	local out: { [number]: Attachment } = {}
	local soil = plot:FindFirstChild(PLOT.PlanterName)
	local source: Instance = soil or plot
	for _, d in ipairs(source:GetDescendants()) do
		if d:IsA("Attachment") and CollectionService:HasTag(d, GameConfig.Tags.PlantSlot) then
			local index = d:GetAttribute("SlotIndex")
			if type(index) == "number" then
				out[index] = d
			end
		end
	end
	return out
end

local function plantsFolder(plot: Model): Instance
	local f = plot:FindFirstChild(PLOT.PlantsFolderName)
	if f then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = PLOT.PlantsFolderName
	made.Parent = plot
	return made
end

--==============================================================================
-- BUILDING WHAT IS IN THE GROUND
--==============================================================================
local function stageFor(entry: Planted, now: number): number
	local total = SeedData.GrowSeconds(entry.species)
	local elapsed = now - entry.plantedAt
	if elapsed >= total then
		return CreatureModel.STAGE_GROWN
	elseif elapsed >= total * SPROUT_AT then
		return CreatureModel.STAGE_SPROUT
	end
	return CreatureModel.STAGE_POD
end

local function render(entry: Planted, slot: Attachment)
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	local cf = slot.WorldCFrame
	-- Face the gate, so a plot reads as a row of creatures looking at whoever
	-- walks in rather than a row of backs.
	local model = CreatureModel.Build(entry.species, entry.stage,
		CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(180), 0)
			* entry.plot:GetPivot().Rotation, plantsFolder(entry.plot))
	model:SetAttribute("SlotIndex", entry.slot)
	model:SetAttribute("PlantedAt", entry.plantedAt)
	--==========================================================================
	-- HATCHING, NOT LOOT
	--
	-- At the POD stage this is the identical model a nest grows, so without this
	-- tag it is indistinguishable from something you are meant to steal --
	-- which is exactly what went wrong: CarryService put a Take prompt on it and
	-- taking it ran the raid alarm inside the safe zone.
	--
	-- Also the seam PlantUI watches to draw the hatch timer, so one tag both
	-- refuses the take and asks for the countdown.
	--==========================================================================
	CollectionService:AddTag(model, GameConfig.Tags.Planted)
	entry.model = model
end

local function record(plot: Model): { any }
	local list = {}
	local byPlot = growing[plot]
	if byPlot then
		for _, entry in pairs(byPlot) do
			table.insert(list, {
				SpeciesId = entry.species.Id,
				Slot = entry.slot,
				PlantedAt = entry.plantedAt,
			})
		end
	end
	return list
end

local function persist(plot: Model)
	local owner = PlotService.OwnerOf(plot)
	if owner then
		PlayerDataService.SetPlants(owner, record(plot))
	end
end

--==============================================================================
-- PLANTING
--==============================================================================
function PlantService.Plant(player: Player, species: SeedData.Species): boolean
	local plot = PlotService.PlotOf(player)
	if not plot then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end

	local slots = slotsOf(plot)
	local byPlot = growing[plot]
	if not byPlot then
		byPlot = {}
		growing[plot] = byPlot
	end

	-- The nearest FREE slot within reach. Nearest rather than lowest-numbered,
	-- so a plot fills up where the player is standing and planting a row feels
	-- like walking a row.
	local best, bestSlot, bestDist = nil, nil, PLANT_RANGE
	for index, attachment in pairs(slots) do
		if not byPlot[index] then
			local d = (attachment.WorldPosition - root.Position).Magnitude
			if d < bestDist then
				best, bestSlot, bestDist = attachment, index, d
			end
		end
	end
	if not (best and bestSlot) then
		return false
	end

	local entry: Planted = {
		plot = plot,
		slot = bestSlot,
		species = species,
		plantedAt = os.time(),
		stage = CreatureModel.STAGE_POD,
		model = nil,
	}
	byPlot[bestSlot] = entry
	render(entry, best)
	persist(plot)
	log(string.format("%s planted a %s in %s slot %d (%.0fs to grow).",
		player.Name, species.Name, plot.Name, bestSlot,
		SeedData.GrowSeconds(species)))
	return true
end

--==============================================================================
-- THE TOOL
--
-- Hooked once per Tool. Activated only fires while the tool is equipped, so
-- there is no need to track equipping separately.
--==============================================================================
local function hookTool(tool: Instance, player: Player)
	if not tool:IsA("Tool") or hooked[tool] then
		return
	end
	local speciesId = tool:GetAttribute("SpeciesId")
	if type(speciesId) ~= "string" then
		return
	end
	hooked[tool] = true

	-- TRACKED, like every other connection here. Init() clears `hooked` so a
	-- re-run re-hooks from scratch; if these two survived that, the tool would
	-- carry two Activated handlers and one click would plant twice -- the second
	-- handler still reads SpeciesId fine off the just-destroyed tool.
	table.insert(serviceConnections, tool.Activated:Connect(function()
		local species = SeedData.Get(tool:GetAttribute("SpeciesId") or "")
		if not species then
			return
		end
		if PlantService.Plant(player, species) then
			-- Consumed. Destroying the tool is what makes planting a decision
			-- rather than a duplication bug.
			tool:Destroy()
			hooked[tool] = nil
		end
	end))
	table.insert(serviceConnections, tool.Destroying:Connect(function()
		hooked[tool] = nil
	end))
end

local function watchPlayer(player: Player)
	local function scan(container: Instance)
		for _, c in ipairs(container:GetChildren()) do
			hookTool(c, player)
		end
		table.insert(serviceConnections, container.ChildAdded:Connect(function(c)
			hookTool(c, player)
		end))
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		scan(backpack)
	end
	table.insert(serviceConnections, player.ChildAdded:Connect(function(c)
		if c:IsA("Backpack") then
			scan(c)
		end
	end))
	-- Equipping moves the Tool into the character, so that is a second place a
	-- previously unseen Tool can appear.
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		scan(character)
	end))
	if player.Character then
		scan(player.Character)
	end
end

--==============================================================================
-- RESTORING
--
-- A plot is assigned the instant a player joins; their profile lands seconds
-- later. Restoring needs BOTH, so this waits for the profile rather than
-- assuming an order that is not guaranteed -- the exact ordering problem the
-- OnAssigned hook was built for.
--==============================================================================
local function restore(player: Player, plot: Model)
	task.spawn(function()
		local deadline = os.clock() + 30
		while not PlayerDataService.IsReady(player) and os.clock() < deadline do
			task.wait(0.25)
		end
		local profile = PlayerDataService.Get(player)
		if not profile or player.Parent ~= Players then
			return
		end
		-- Still theirs? Thirty seconds is long enough to have been reassigned.
		if PlotService.PlotOf(player) ~= plot then
			return
		end

		local slots = slotsOf(plot)
		local byPlot = {}
		growing[plot] = byPlot
		local restored, dropped = 0, 0

		for _, saved in ipairs(profile.Plants) do
			local species = if type(saved) == "table"
				then SeedData.Get(tostring(saved.SpeciesId))
				else nil
			local index = if type(saved) == "table" then tonumber(saved.Slot) else nil
			local at = if type(saved) == "table" then tonumber(saved.PlantedAt) else nil
			-- A slot can vanish between sessions -- a tier change rebuilds the
			-- bed with a different grid -- so every entry is re-validated rather
			-- than trusted.
			if species and index and at and slots[index] and not byPlot[index] then
				local entry: Planted = {
					plot = plot,
					slot = index,
					species = species,
					plantedAt = at,
					stage = CreatureModel.STAGE_POD,
					model = nil,
				}
				entry.stage = stageFor(entry, os.time())
				byPlot[index] = entry
				render(entry, slots[index])
				restored += 1
			else
				dropped += 1
			end
		end
		if restored > 0 or dropped > 0 then
			log(string.format("%s: restored %d plant(s)%s.", player.Name, restored,
				if dropped > 0 then string.format(", dropped %d that no longer fit", dropped)
				else ""))
		end
		-- Write back, so anything dropped stops being carried forever.
		persist(plot)
	end)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PlantService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for plot, byPlot in pairs(growing) do
		for _, entry in pairs(byPlot) do
			if entry.model and entry.model.Parent then
				entry.model:Destroy()
			end
		end
		growing[plot] = nil
	end
	table.clear(hooked)
end

function PlantService.Start()
	PlotService.OnAssigned(function(player, plot)
		restore(player, plot)
	end)
	PlotService.OnReleased(function(_player, plot)
		-- PlotService clears the Plants folder itself right after this; all that
		-- is needed here is to stop tracking what was in it.
		growing[plot] = nil
	end)

	table.insert(serviceConnections, Players.PlayerAdded:Connect(watchPlayer))
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	--== GROWTH ==--
	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			local now = os.time()
			for plot, byPlot in pairs(growing) do
				if not plot.Parent then
					growing[plot] = nil
				else
					local slots = nil
					for index, entry in pairs(byPlot) do
						local want = stageFor(entry, now)
						if want ~= entry.stage then
							slots = slots or slotsOf(plot)
							local slot = slots[index]
							if slot then
								entry.stage = want
								render(entry, slot)
							end
						end
					end
				end
			end
		end
	end)

	log(string.format("Ready. Equip a pod and click to plant; sprouts at %.0f%% grown.",
		SPROUT_AT * 100))
end

--==============================================================================
-- READ API, for EconomyService
--==============================================================================
-- Everything fully grown in this plot. Income is somebody else's job -- this
-- only says what is standing there.
function PlantService.GrownIn(plot: Model): { SeedData.Species }
	local out = {}
	local byPlot = growing[plot]
	if byPlot then
		for _, entry in pairs(byPlot) do
			if entry.stage == CreatureModel.STAGE_GROWN then
				table.insert(out, entry.species)
			end
		end
	end
	return out
end

function PlantService.Snapshot(): string
	local rows = {}
	for plot, byPlot in pairs(growing) do
		local n, grown = 0, 0
		for _, entry in pairs(byPlot) do
			n += 1
			if entry.stage == CreatureModel.STAGE_GROWN then
				grown += 1
			end
		end
		table.insert(rows, string.format("%s: %d planted, %d grown", plot.Name, n, grown))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nothing planted"
end

return PlantService
