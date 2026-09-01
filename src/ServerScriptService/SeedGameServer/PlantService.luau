--!strict
-- Steal a Seed :: PlantService
--
-- Putting a banked pod in the ground, hatching it by hand, and planting what
-- comes out.
--
--==============================================================================
-- THIS IS WHERE THE RAID PAYS
--
-- Everything before it is risk: the walk out, the hold next to a sleeping
-- monster, the run home with a weight on your back. None of that pays anything.
-- Planting is the moment the trip turns into a thing you own and can see from
-- across the field.
--
--==============================================================================
-- YOU PUT IT WHERE YOU CLICK
--
-- The bed used to be an invisible three-by-N grid, and planting snapped to the
-- nearest free cell within reach. That made a plot a form to fill in: there was
-- exactly one arrangement and everybody's was the same.
--
-- Now the click decides. A plot is a garden you lay out, which is the only
-- reason to walk into somebody else's and look at it.
--
-- The grid attachments still exist in MapService. They are no longer positions
-- anything is placed into -- they are the lookup table that says where a save
-- written BEFORE free placement lands, once, on load.
--
--==============================================================================
-- NOTHING HATCHES ON ITS OWN
--
-- A planted pod counts down and then STOPS, sitting there ready with a prompt
-- on it. Hold E and it shakes itself apart and hands you the creature.
--
-- That is the whole reason the change is worth making: growth used to be a
-- thing that happened to you while you watched. Now the end of the clock is an
-- invitation rather than an event, the pod is a thing on your land that you
-- come back for, and the moment the shell breaks is something you did.
--
-- The sprout stage is gone with it. It existed to make a bed look busy halfway
-- through, and it had no decision in it.
--
--==============================================================================
-- THE CREATURE GOES IN YOUR HANDS, NOT IN THE HOLE
--
-- Hatching does not leave the plant where the egg was. It puts it in your
-- hotbar and you carry it, and then you click where you actually want it.
-- Where an egg happened to sit is not where the thing that comes out of it
-- belongs, and a garden you arrange twice is a garden you arranged.
--
-- Only a placed creature earns. A pod in the ground is a promise.
--
--==============================================================================
-- GROWTH IS ABSOLUTE TIME, SO IT KEEPS GOING WHILE YOU ARE AWAY
--
-- PlantedAt is os.time(), not a countdown. A pod left overnight is ready when
-- you come back; a countdown would have paused the moment you logged off, which
-- turns a garden into a screensaver and quietly punishes anybody with a life.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local PLOT = GameConfig.Plot

local PlantService = {}
-- After CarryService (45), which is what puts a Tool in the hotbar and what
-- hatching hands the creature to.
PlantService.Priority = 50

type Planted = {
	plot: Model,
	-- Unique within the plot, and only an identity -- it says nothing about
	-- WHERE, which is what `offset` is for. It replaced the slot index, which
	-- was both at once and could therefore not survive free placement.
	id: number,
	species: SeedData.Species,
	-- What THIS one weighs, rolled when its pod spawned. Everything measured
	-- about the plant -- size, hatch time, payout -- comes from here, never from
	-- species.Kg.
	tier: number,
	-- Where it stands, LOCAL to the soil part, Y always zero. Local rather than
	-- world because a plot is rebuilt at a different place and rotation every
	-- time its tier changes, and a world position saved through that would put
	-- somebody's garden in the road.
	offset: Vector3,
	-- os.time(), absolute.
	plantedAt: number,
	-- STAGE_POD (unhatched) or STAGE_GROWN (a creature you placed). Nothing in
	-- the ground is ever a sprout any more.
	stage: number,
	-- Which way it stands, in radians, on top of the plot's own rotation. Saved
	-- rather than derived, so a garden you arranged looks the same tomorrow --
	-- placement ids are handed out again on every load and would shuffle every
	-- plant's facing with them.
	facing: number,
	model: Model?,
	prompt: ProximityPrompt?,
}

-- plot -> placementId -> Planted
local growing: { [Model]: { [number]: Planted } } = {}
local nextId: { [Model]: number } = {}
local serviceConnections: { RBXScriptConnection } = {}
local running = false

-- These live in GameConfig because THE CLIENT NEEDS THEM: the hatch timer
-- counts down to the same instant this does, and the click that asks to plant
-- has to name the same verb this listens for.
local PLANTING = GameConfig.Plant
local TICK = PLANTING.TickSeconds
local PLANT_RANGE = PLANTING.RangeStuds
local EDGE_MARGIN = PLANTING.EdgeMarginStuds
local HATCH_HOLD = PLANTING.HatchHoldSeconds
local BURST = PLANTING.BurstSeconds
local PLACE_ACTION = PLANTING.PlaceAction
local PICKUP_ACTION = PLANTING.PickUpAction

local function log(message: string)
	print("[Seed/PlantService] " .. message)
end

--==============================================================================
-- WHY A REFUSED PLACEMENT SAYS NOTHING, AND WHAT THIS DOES ABOUT IT
--
-- PlaceAt has seven guards and the client sends its click on a RemoteEvent, so
-- it never learns which one stopped it. No plot, no soil, no character, no
-- equipped tool, an unknown species, out of range and a full bed are all the
-- same nothing: the pod stays in your hands and the game says why.
--
-- That is indistinguishable from a bug, and it cost a round of "pods and plants
-- cannot be placed on plots" that turned out not to be a placement fault at all.
--
-- DIAGNOSTIC ONLY. Same guards, same order, same `return false`, no new remote
-- and no change to what is or is not allowed. The only difference is that the
-- server now says which guard fired.
--
-- RATE LIMITED PER PLAYER AND CODE. Placing is a click, and a player who cannot
-- plant will click ten times: ten identical lines a second buries the one line
-- that matters. The table has weak keys so a player who leaves is collected
-- without a lifecycle hook to forget.
--==============================================================================
local REFUSE_QUIET_SECONDS = 3
local lastRefusal: { [Player]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any

-- Peeked rather than required: the earliest guards fire before PlaceAt has
-- looked at a tool, and a refusal that cannot name the species is worth less.
local function heldSpeciesId(player: Player): string
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	local id = if tool then tool:GetAttribute("SpeciesId") else nil
	return if id ~= nil then tostring(id) else "none"
end

-- Always returns false, so each guard reads `return refuse(...)` and cannot
-- accidentally start allowing what it used to refuse.
local function refuse(player: Player, code: string): boolean
	local now = os.clock()
	local seen = lastRefusal[player]
	if not seen then
		seen = {}
		lastRefusal[player] = seen
	end
	if now - (seen[code] or -math.huge) >= REFUSE_QUIET_SECONDS then
		seen[code] = now
		log(string.format("%s placement refused: %s (species %s)",
			player.Name, code, heldSpeciesId(player)))
	end
	return false
end

--==============================================================================
-- THE BED
--==============================================================================
local function soilOf(plot: Model): BasePart?
	local soil = plot:FindFirstChild(PLOT.PlanterName)
	return if soil and soil:IsA("BasePart") then soil else nil
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

-- How many things this plot may hold. Free placement removed the POSITIONS but
-- not the limit: a tier still buys you more plants, it just no longer tells you
-- where to put them. Same function GardenUI counts rows with.
local function capacityOf(plot: Model): number
	local rows = tonumber(plot:GetAttribute("Rows"))
	return GameConfig.plotSlotsFor(rows or GameConfig.PlotTiers[1].rows)
end

local function countIn(plot: Model): number
	local byPlot = growing[plot]
	if not byPlot then
		return 0
	end
	local n = 0
	for _ in pairs(byPlot) do
		n += 1
	end
	return n
end

--==============================================================================
-- WHERE A CLICK LANDS
--
-- The position arrives from the client and is a claim, not a fact. It is pulled
-- into the soil rectangle rather than refused: "exactly where I clicked" should
-- stop being exact only at the very rim, and a click that silently does nothing
-- reads as the game being broken rather than as a rule.
--
-- The reach check is the one that actually matters, and it is done on the
-- CLAMPED point -- so a claim of "I clicked a thousand studs that way" becomes
-- a point on the edge of the bed, which then fails the distance test honestly.
--==============================================================================
local function clampToSoil(soil: BasePart, worldPos: Vector3): Vector3
	local here = soil.CFrame:PointToObjectSpace(worldPos)
	local halfX = math.max(soil.Size.X * 0.5 - EDGE_MARGIN, 0)
	local halfZ = math.max(soil.Size.Z * 0.5 - EDGE_MARGIN, 0)
	return Vector3.new(
		math.clamp(here.X, -halfX, halfX),
		0,
		math.clamp(here.Z, -halfZ, halfZ))
end

local function topOf(soil: BasePart, offset: Vector3): CFrame
	return soil.CFrame * CFrame.new(offset.X, soil.Size.Y * 0.5, offset.Z)
end

--==============================================================================
-- WHICH WAY IT STANDS
--
-- Every plant used to face the plot gate, on purpose: a bed read as a crowd
-- watching whoever walked in. In practice it read as a PARADE -- twelve
-- identical bearings in a rectangle, which is the one arrangement free
-- placement was supposed to stop being able to happen by accident.
--
-- So each gets its own. The GOLDEN ANGLE rather than a random number: 137.5
-- degrees is the rotation that never lands near a previous one for any count,
-- so ten plants placed in a row come out visibly scattered instead of
-- occasionally paired. Random would clump about a third of the time and the
-- clumps are exactly what this is for.
--
--     1 -> 137.5   2 -> 275.0   3 ->  52.5   4 -> 190.0   5 -> 327.5
--
-- It is a starting bearing, not a fixed one. PlantSway turns each plant a
-- little on its own while it is standing still -- see the look-around there.
--==============================================================================
local GOLDEN_ANGLE = math.pi * (3 - math.sqrt(5))

local function facingFor(index: number): number
	return (index * GOLDEN_ANGLE) % (math.pi * 2)
end

--==============================================================================
-- BUILDING WHAT IS IN THE GROUND
--==============================================================================
-- render() hangs the pick-up prompt on anything grown, and the prompt builders
-- need render() to have run. One forward declaration breaks the knot, rather
-- than shuffling three functions into an order that reads worse than it works.
local attachPickup: (Planted) -> ()

local function render(entry: Planted)
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	entry.model = nil
	entry.prompt = nil
	local soil = soilOf(entry.plot)
	if not soil then
		return
	end

	-- The gate is still the reference -- the 180 turns a plant to look back down
	-- its own plot rather than out of the fence -- and each plant's own bearing
	-- is added on top of it. Applied LAST, so it is a turn about the plant's own
	-- up axis whatever the plot's rotation on the ring happens to be.
	local base = topOf(soil, entry.offset)
	local model = CreatureModel.Build(entry.species, entry.tier, entry.stage,
		CFrame.new(base.Position) * CFrame.Angles(0, math.rad(180), 0)
			* entry.plot:GetPivot().Rotation
			* CFrame.Angles(0, entry.facing, 0), plantsFolder(entry.plot))
	-- IDENTITY, not position. PlantSway phases its idle off this so a bed is not
	-- a chorus line, and GardenUI keys its rows on it.
	model:SetAttribute("PlacementId", entry.id)
	model:SetAttribute("PlantedAt", entry.plantedAt)
	--==========================================================================
	-- HATCHING, NOT LOOT
	--
	-- At the POD stage this is the identical model a nest grows, so without this
	-- tag it is indistinguishable from something you are meant to steal --
	-- which is exactly what went wrong: CarryService put a Take prompt on it and
	-- taking it ran the raid alarm inside the safe zone.
	--
	-- Also the seam PlantUI watches to draw the hatch clock and PlantSway
	-- watches to shake it, so one tag does all three.
	--==========================================================================
	CollectionService:AddTag(model, GameConfig.Tags.Planted)
	entry.model = model

	--==========================================================================
	-- A CREATURE IN THE GROUND HAS ALREADY BEEN REVEALED
	--
	-- The Almanac is written at the HATCH now, because that is where the reveal
	-- moved: until the shell breaks you do not know which species you have --
	-- pods are coloured by weight and two Commons arrive identical.
	--
	-- This stays as the backfill for the one path that produces a grown plant
	-- without a hatch happening in front of anybody: a garden restored from a
	-- save that was already finished when the player left.
	--==========================================================================
	if entry.stage == CreatureModel.STAGE_GROWN then
		local owner = PlotService.OwnerOf(entry.plot)
		if owner then
			PlayerDataService.MarkSeen(owner, entry.species.Id)
		end
		-- A grown plant can always be taken back off your own farm, so the
		-- prompt goes on the moment it is standing there. Declared above
		-- because the prompt builders need render() and render() needs them.
		attachPickup(entry)
	end
end

--==============================================================================
-- SAVING
--
-- X and Z rather than a slot index, because there are no slots any more. Stage
-- as well, because a planted thing is no longer derivable from its clock: a pod
-- whose timer finished an hour ago is still a pod until somebody hatches it.
--==============================================================================
local function record(plot: Model): { any }
	local list = {}
	local byPlot = growing[plot]
	if byPlot then
		for _, entry in pairs(byPlot) do
			table.insert(list, {
				SpeciesId = entry.species.Id,
				PlantedAt = entry.plantedAt,
				Tier = entry.tier,
				X = entry.offset.X,
				Z = entry.offset.Z,
				Stage = entry.stage,
				Facing = entry.facing,
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
-- READY, AND THE PROMPT THAT SAYS SO
--==============================================================================
local function isReady(entry: Planted, now: number): boolean
	return entry.stage == CreatureModel.STAGE_POD
		and (now - entry.plantedAt) >= SeedData.GrowSeconds(entry.tier)
end

local hatch: (Player, Planted) -> boolean
local pickUp: (Player, Planted) -> boolean

local function attachHatchPrompt(entry: Planted)
	local model = entry.model
	local handle = if model then model.PrimaryPart else nil
	if not (model and handle) or entry.prompt then
		return
	end
	-- Read by PlantUI, which drops its countdown plate the moment this appears:
	-- a clock at 0:00 sitting next to a prompt that says HATCH is two things
	-- saying the same thing, and the prompt is the one you can act on.
	model:SetAttribute("Ready", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HatchPrompt"
	-- Custom, like every prompt in the game: PromptUI draws them all.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Hatch"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = HATCH_HOLD
	prompt.MaxActivationDistance = PLANT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = handle
	entry.prompt = prompt

	--==========================================================================
	-- THE SHAKE IS AN ATTRIBUTE, NOT A LOOP HERE
	--
	-- The pod is anchored and server-owned, so jittering it from this script
	-- would push a CFrame down the wire every frame for every hatching pod on
	-- the server. The attribute replicates once and PlantSway -- which already
	-- moves every planted model, every frame, on each client -- does the motion
	-- locally and for free.
	--==========================================================================
	table.insert(serviceConnections, prompt.PromptButtonHoldBegan:Connect(function()
		if entry.model then
			entry.model:SetAttribute("Hatching", true)
		end
	end))
	table.insert(serviceConnections, prompt.PromptButtonHoldEnded:Connect(function()
		if entry.model then
			entry.model:SetAttribute("Hatching", false)
		end
	end))
	table.insert(serviceConnections, prompt.Triggered:Connect(function(player)
		hatch(player, entry)
	end))
end

--==============================================================================
-- AND THE ONE THAT TAKES IT BACK
--
-- A grown plant is not furniture. You put it somewhere, you change your mind,
-- you move it -- and until now the only way to free a place in the bed was to
-- have never used it.
--
-- IT IS NOT A TAKE, AND IT IS NOT A HATCH. Both of those words already mean
-- something else in this game: Take is what you do to somebody's nest and it
-- runs the raid alarm, Hatch is what opens a shell. This is neither -- nothing
-- is stolen and nothing is revealed, the thing simply comes back to your hands.
--
-- The owner check is server-side and it is the only thing standing between a
-- neighbour and your garden. The prompt itself is drawn for anybody who walks
-- close enough -- a ProximityPrompt has no per-player visibility -- so a
-- stranger can see a Pick Up on your plant and get nothing for holding it.
-- Worth fixing in PromptUI one day; not worth trusting the client over.
--==============================================================================
function attachPickup(entry: Planted)
	local model = entry.model
	local handle = if model then model.PrimaryPart else nil
	if not (model and handle) or entry.prompt then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	-- Custom, like every prompt in the game: PromptUI draws them all.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = HATCH_HOLD
	prompt.MaxActivationDistance = PLANT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = handle
	entry.prompt = prompt
	table.insert(serviceConnections, prompt.Triggered:Connect(function(player)
		pickUp(player, entry)
	end))
end

--==============================================================================
-- THE SHELL COMES APART
--
-- Tweened rather than unanchored: these parts are anchored, CanCollide is off
-- across the whole game, and letting the engine simulate a dozen shards per
-- hatch on a mobile-first project buys nothing you can see.
--
-- The tag comes off FIRST, so PlantUI's plate and PlantSway's idle let go of it
-- before it starts flying -- otherwise the sway fights the burst for the same
-- pivot and the pieces snap back to centre every frame.
--==============================================================================
local function burst(model: Model)
	CollectionService:RemoveTag(model, GameConfig.Tags.Planted)
	local origin = model:GetPivot().Position
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
			local away = d.Position - origin
			-- A part sitting exactly on the pivot has no direction of its own,
			-- so it goes straight up rather than nowhere.
			local dir = if away.Magnitude > 0.05 then away.Unit else Vector3.new(0, 1, 0)
			local goal = d.CFrame + (dir * 3.4 + Vector3.new(0, 2.6, 0))
			TweenService:Create(d,
				TweenInfo.new(BURST, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = goal * CFrame.Angles(math.rad(55), math.rad(40), math.rad(25)),
					Transparency = 1,
				}):Play()
		end
	end
	task.delay(BURST + 0.05, function()
		if model.Parent then
			model:Destroy()
		end
	end)
end

--==============================================================================
-- AND A GENTLER ONE FOR A PLANT YOU ARE TAKING BACK
--
-- Same rules as the burst -- tag off first so the sway lets go of the pivot,
-- prompts and plates destroyed now rather than in a quarter of a second -- but
-- it lifts and fades instead of coming apart. Nothing broke; you picked it up.
--
-- A plant that simply vanished mid-frame reads as a deletion bug, and this is
-- the one action in the game whose whole point is that nothing was lost.
--==============================================================================
local LIFT = 0.25

local function lift(model: Model)
	CollectionService:RemoveTag(model, GameConfig.Tags.Planted)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
			TweenService:Create(d,
				TweenInfo.new(LIFT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = d.CFrame + Vector3.new(0, 2.2, 0),
					Transparency = 1,
				}):Play()
		end
	end
	task.delay(LIFT + 0.05, function()
		if model.Parent then
			model:Destroy()
		end
	end)
end

--==============================================================================
-- HATCHING
--
-- The creature is handed over BEFORE the pod is destroyed. The other order
-- loses the whole raid if the player has no Backpack at that instant -- dying
-- with the prompt held is enough -- and a prize that evaporates because of a
-- frame is the worst bug this game can have.
--==============================================================================
function hatch(player: Player, entry: Planted): boolean
	local byPlot = growing[entry.plot]
	if not byPlot or byPlot[entry.id] ~= entry then
		return false
	end
	-- Yours. The prompt is drawn for anybody standing close enough, so this is
	-- the check that actually owns the pod.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false
	end
	if not isReady(entry, os.time()) then
		return false
	end
	if not CarryService.GiveHatched(player, entry.species, entry.tier) then
		return false
	end
	-- Said here rather than in CarryService, which also hands a Tool over for a
	-- pickup and for a rejoin and cannot tell the three apart.
	log(string.format("%s hatched a %d tier %s.", player.Name, entry.tier,
		entry.species.Name))

	byPlot[entry.id] = nil
	local model = entry.model
	entry.model = nil
	entry.prompt = nil
	if model and model.Parent then
		burst(model)
	end
	persist(entry.plot)
	-- THE REVEAL IS THE HATCH. Until the shell breaks you do not know which
	-- species you had, so this is the moment the Almanac learns it.
	PlayerDataService.MarkSeen(player, entry.species.Id)
	log(string.format("%s hatched a %d tier %s.", player.Name, entry.tier, entry.species.Name))
	return true
end

--==============================================================================
-- TAKING A GROWN PLANT BACK OFF YOUR OWN FARM
--
-- The same Tool the hatch hands over -- same species, same kg, same Hatched
-- flag -- so a plant that has been moved is indistinguishable from one that has
-- never been placed. There is no second kind of creature in the hotbar.
--
-- Handed over BEFORE the plant is removed, for the same reason hatching is:
-- if the Backpack is not there at that instant, the right answer is that
-- nothing happened, not that the plant is gone.
--
-- The freed capacity is not bookkeeping -- it is the point. A full bed used to
-- be permanent.
--==============================================================================
function pickUp(player: Player, entry: Planted): boolean
	local byPlot = growing[entry.plot]
	if not byPlot or byPlot[entry.id] ~= entry then
		return false
	end
	-- Yours, and only yours. This is what stops a neighbour walking off with
	-- your garden -- the prompt is visible to them, the action is not.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false
	end
	if entry.stage ~= CreatureModel.STAGE_GROWN then
		return false
	end
	if not CarryService.GiveHatched(player, entry.species, entry.tier) then
		return false
	end

	byPlot[entry.id] = nil
	local model = entry.model
	entry.model = nil
	entry.prompt = nil
	if model and model.Parent then
		lift(model)
	end
	persist(entry.plot)
	log(string.format("%s picked up a %d tier %s. %d/%d in the bed.",
		player.Name, entry.tier, entry.species.Name, countIn(entry.plot),
		capacityOf(entry.plot)))
	return true
end

--==============================================================================
-- THE SAME PICKUP, ASKED FOR BY NAME
--
-- The prompt in the world hands `pickUp` an entry it already had. A panel has
-- only an id, so this is the lookup -- and the lookup is itself a check.
--
-- IT LOOKS IN THE CALLER'S OWN PLOT AND NOWHERE ELSE. `growing` is keyed by
-- plot, so asking for a neighbour's placement id finds nothing: their plants
-- are not in your table. That is the first guard and it is structural rather
-- than conditional. `pickUp` then re-tests ownership, stage and the handover
-- anyway, because a guard you can only see by reading two functions is a guard
-- somebody will delete.
--
-- Returns false rather than erroring on every bad id. A client that sends
-- nonsense gets nothing done, not a stack trace on the server.
--==============================================================================
function PlantService.PickUpById(player: Player, placementId: number): boolean
	local plot = PlotService.PlotOf(player)
	if not plot then
		return false
	end
	local byPlot = growing[plot]
	if not byPlot then
		return false
	end
	local entry = byPlot[placementId]
	if not entry then
		return false
	end
	return pickUp(player, entry)
end

--==============================================================================
-- PLANTING
--
-- One entry point for both things that can be in your hands: an unhatched pod,
-- which goes in the ground and starts a clock, and a hatched creature, which
-- goes in the ground already earning. The Tool says which.
--==============================================================================
function PlantService.PlaceAt(player: Player, worldPos: Vector3): boolean
	local plot = PlotService.PlotOf(player)
	if not plot then
		-- A player whose profile has not finished loading has no plot either,
		-- and NO_PLOT would send somebody reading PlotService when the answer
		-- is upstream of it. Same refusal either way; different thing to fix.
		local code = if PlayerDataService.IsReady(player) then "NO_PLOT" else "NO_PROFILE"
		return refuse(player, code)
	end
	local soil = soilOf(plot)
	if not soil then
		return refuse(player, "NO_SOIL")
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (character and root and root:IsA("BasePart")) then
		-- NOT a profile check, whatever it looks like from outside: this is the
		-- character being absent or mid-respawn.
		return refuse(player, "NO_CHARACTER")
	end

	-- The EQUIPPED tool. A Tool sitting in the Backpack is not in your hands and
	-- clicking the ground should not plant it.
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return refuse(player, "NO_TOOL")
	end
	local species = SeedData.Get(tostring(tool:GetAttribute("SpeciesId")))
	if not species then
		return refuse(player, "UNKNOWN_SPECIES")
	end
	-- The weight travelled with the pod: CarryService stamps it on the Tool when
	-- the pod is banked and again when a creature is hatched. Falling back to
	-- the species sheet would plant a 9,000 kg Nubkin as a 2 kg one.
	local tier = math.clamp(
		tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg)) or species.Tier,
		1, SeedData.TierCount)
	local hatched = tool:GetAttribute("Hatched") == true

	local offset = clampToSoil(soil, worldPos)
	if (topOf(soil, offset).Position - root.Position).Magnitude > PLANT_RANGE then
		return refuse(player, "OUT_OF_RANGE")
	end

	local byPlot = growing[plot]
	if not byPlot then
		byPlot = {}
		growing[plot] = byPlot
	end
	if countIn(plot) >= capacityOf(plot) then
		return refuse(player, "BED_FULL")
	end

	local id = (nextId[plot] or 0) + 1
	nextId[plot] = id
	local entry: Planted = {
		plot = plot,
		id = id,
		species = species,
		tier = tier,
		offset = offset,
		plantedAt = os.time(),
		stage = if hatched then CreatureModel.STAGE_GROWN else CreatureModel.STAGE_POD,
		-- Off the placement id, so consecutive plantings come out scattered.
		-- Re-placing a plant you picked up gives it a NEW bearing, which is the
		-- honest answer: you put it down again, facing a different way.
		facing = facingFor(id),
		model = nil,
		prompt = nil,
	}
	byPlot[id] = entry
	render(entry)
	if isReady(entry, os.time()) then
		attachHatchPrompt(entry)
	end
	persist(plot)
	-- Consumed. Destroying the tool is what makes planting a decision rather
	-- than a duplication bug.
	tool:Destroy()
	CarryService.SyncHeldNow(player)

	if hatched then
		log(string.format("%s planted a %d tier %s.", player.Name, tier, species.Name))
	else
		log(string.format("%s buried a %d tier %s pod (%.0fs until it can be hatched).",
			player.Name, tier, species.Name, SeedData.GrowSeconds(tier)))
	end
	return true
end

--==============================================================================
-- RESTORING
--
-- A plot is assigned the instant a player joins; their profile lands seconds
-- later. Restoring needs BOTH, so this waits for the profile rather than
-- assuming an order that is not guaranteed -- the exact ordering problem the
-- OnAssigned hook was built for.
--==============================================================================
-- WHERE A PRE-FREE-PLACEMENT SAVE LANDS
--
-- Saves written against the old grid carry a Slot index and no position. The
-- grid attachments are still on the soil for exactly this: look the index up,
-- take its local offset, and the garden comes back where its owner left it.
-- After one load it is written out as X and Z like everything else.
--==============================================================================
local function slotOffsets(plot: Model): { [number]: Vector3 }
	local out: { [number]: Vector3 } = {}
	local soil = soilOf(plot)
	if not soil then
		return out
	end
	for _, d in ipairs(soil:GetDescendants()) do
		if d:IsA("Attachment") and CollectionService:HasTag(d, GameConfig.Tags.PlantSlot) then
			local index = d:GetAttribute("SlotIndex")
			if type(index) == "number" then
				-- Already local to the soil -- MapService writes CFrame, not
				-- WorldCFrame, and that distinction cost a day once.
				local p = d.CFrame.Position
				out[index] = Vector3.new(p.X, 0, p.Z)
			end
		end
	end
	return out
end

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

		local soil = soilOf(plot)
		if not soil then
			return
		end
		local legacy = slotOffsets(plot)
		local byPlot = {}
		growing[plot] = byPlot
		nextId[plot] = 0
		local cap = capacityOf(plot)
		local restored, dropped = 0, 0
		local now = os.time()

		for _, saved in ipairs(profile.Plants) do
			local row = if type(saved) == "table" then saved else nil
			local species = if row then SeedData.Get(tostring(row.SpeciesId)) else nil
			local at = if row then tonumber(row.PlantedAt) else nil
			--==============================================================
			-- A SAVE FROM BEFORE WEIGHTS WERE ROLLED HAS NO Kg
			--
			-- A row written before tiers existed has no Tier at all, and the
			-- species sheet no longer carries a fallback either -- both were
			-- weights, and weight is gone. So it lands on the BASE tier.
			--
			-- That is deliberate rather than a shrug: re-rolling would be worse,
			-- because a garden left full of big plants would come back worth
			-- something different every rejoin, which is a slot machine and not
			-- a save. Everyone starts these at Tiny and grows them again.
			--
			-- Without the BaseTier fallback this crashed outright on the first
			-- load of any pre-tier save: clamp got nil and the whole restore
			-- died with it.
			--==============================================================
			local tier = math.clamp(
				(if row then tonumber(row.Tier) else nil) or SeedData.BaseTier,
				1, SeedData.TierCount)

			local x = if row then tonumber(row.X) else nil
			local z = if row then tonumber(row.Z) else nil
			if not (x and z) then
				local index = if row then tonumber(row.Slot) else nil
				local off = if index then legacy[index] else nil
				if off then
					x, z = off.X, off.Z
				end
			end

			--==============================================================
			-- A SAVE FROM BEFORE MANUAL HATCHING HAS NO Stage
			--
			-- Under the old rules a plant's stage WAS its clock, so anything
			-- whose timer had run out was already a creature standing in the
			-- ground and earning. Restoring those as unhatched pods would take
			-- a finished garden away and ask for it to be hatched again, so
			-- they come back as the creatures they already were. Anything
			-- mid-clock comes back as a pod with its clock still running,
			-- which is what it was.
			--==============================================================
			local stage = if row then tonumber(row.Stage) else nil
			if not stage and species and at then
				stage = if (now - at) >= SeedData.GrowSeconds(tier)
					then CreatureModel.STAGE_GROWN
					else CreatureModel.STAGE_POD
			end
			-- A sprout is not a thing any more. Anything saved as one was
			-- halfway through a clock, so it goes back to being a pod.
			if stage == CreatureModel.STAGE_SPROUT then
				stage = CreatureModel.STAGE_POD
			end

			--==============================================================
			-- A SAVE FROM BEFORE PLANTS FACED DIFFERENT WAYS HAS NO Facing
			--
			-- Every one of them was pointed at the gate. Restoring them that
			-- way would hand somebody back the parade this change exists to
			-- get rid of, so they are scattered ONCE on load off their
			-- position in the save and written back out. After that the
			-- bearing is the plant's own and never moves again.
			--==============================================================
			local facing = if row then tonumber(row.Facing) else nil

			if species and at and x and z and stage and restored < cap then
				local id = nextId[plot] + 1
				nextId[plot] = id
				local entry: Planted = {
					plot = plot,
					id = id,
					species = species,
					tier = tier,
					offset = clampToSoil(soil, (soil.CFrame * CFrame.new(x, 0, z)).Position),
					plantedAt = at,
					stage = stage,
					facing = facing or facingFor(id),
					model = nil,
					prompt = nil,
				}
				byPlot[id] = entry
				render(entry)
				if isReady(entry, now) then
					attachHatchPrompt(entry)
				end
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
		-- Write back, so anything dropped stops being carried forever and any
		-- migrated position is saved in the new shape.
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
	table.clear(nextId)
end

function PlantService.Start()
	PlotService.OnAssigned(function(player, plot)
		restore(player, plot)
	end)
	PlotService.OnReleased(function(_player, plot)
		-- PlotService clears the Plants folder itself right after this; all that
		-- is needed here is to stop tracking what was in it.
		growing[plot] = nil
		nextId[plot] = nil
	end)

	--==========================================================================
	-- THE CLICK ARRIVES OVER A REMOTE, BECAUSE IT CANNOT ARRIVE ANY OTHER WAY
	--
	-- Tool.Activated fires on the server with no idea where the player was
	-- pointing, and ClickDetector does not carry a position either. So the
	-- client raycasts and sends the point -- and everything it sends is treated
	-- as a claim: the plot has to be theirs, the point is pulled onto their own
	-- soil, and they have to be standing next to it.
	--
	-- No new remote. GameEvent has existed in GameConfig.Remotes since the
	-- first boot, and it now carries the second verb too -- the Garden panel's
	-- UNEQUIP, which is this same service's pickUp asked for by placement id.
	--==========================================================================
	local remotes = SeedGame:FindFirstChild("Remotes")
	local channel = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if channel and channel:IsA("RemoteEvent") then
		table.insert(serviceConnections, channel.OnServerEvent:Connect(
			function(player: Player, action: any, payload: any)
				if action == PLACE_ACTION then
					if typeof(payload) ~= "Vector3" then
						return
					end
					-- NaN survives every comparison and would sail straight
					-- through the clamp; a huge finite number would not, but
					-- there is no reason to do the arithmetic on it either.
					if payload ~= payload or payload.Magnitude > 1e6 then
						return
					end
					PlantService.PlaceAt(player, payload)
				elseif action == PICKUP_ACTION then
					--==========================================================
					-- AN ID IS A CLAIM TOO
					--
					-- Rule 4: the sender is engine-stamped and everything else
					-- came off the wire. A placement id has to be a real,
					-- finite, whole, positive number before it is worth a table
					-- lookup -- NaN indexes nothing but sails through <= and >=,
					-- and a float key would silently miss an integer one.
					--==========================================================
					if type(payload) ~= "number" or payload ~= payload then
						return
					end
					if payload < 1 or payload > 1e9
						or math.floor(payload) ~= payload then
						return
					end
					PlantService.PickUpById(player, payload)
				end
			end))
	else
		warn("[Seed/PlantService] No GameEvent remote. Nothing can be planted.")
	end

	--==========================================================================
	-- THE CLOCK ONLY EVER OPENS THE PROMPT
	--
	-- It used to promote pods to sprouts and sprouts to creatures. Now the only
	-- thing time does is decide when a pod may be hatched -- the shell does not
	-- open until somebody opens it.
	--==========================================================================
	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			local now = os.time()
			for plot, byPlot in pairs(growing) do
				if not plot.Parent then
					growing[plot] = nil
					nextId[plot] = nil
				else
					for _, entry in pairs(byPlot) do
						if not entry.prompt and isReady(entry, now) then
							attachHatchPrompt(entry)
						end
					end
				end
			end
		end
	end)

	log(string.format(
		"Ready. Click your soil to plant; hold E on a ready pod for %.1fs to hatch it.",
		HATCH_HOLD))
end

--==============================================================================
-- READ API, for EconomyService
--==============================================================================
-- Everything standing in this plot that EARNS -- which is placed creatures, and
-- never a pod. A pod in the ground is a promise, and a promise pays nothing.
--
-- YIELDS THE WEIGHT, NOT JUST THE SPECIES. EconomyService pays from this;
-- handing back only the species would leave it no choice but to read species.Kg
-- and every plant in the game would earn its form's fallback rate.
--==============================================================================
export type Grown = { species: SeedData.Species, tier: number }

function PlantService.GrownIn(plot: Model): { Grown }
	local out: { Grown } = {}
	local byPlot = growing[plot]
	if byPlot then
		for _, entry in pairs(byPlot) do
			if entry.stage == CreatureModel.STAGE_GROWN then
				table.insert(out, { species = entry.species, tier = entry.tier })
			end
		end
	end
	return out
end

function PlantService.Snapshot(): string
	local rows = {}
	local now = os.time()
	for plot, byPlot in pairs(growing) do
		local n, grown, ready = 0, 0, 0
		for _, entry in pairs(byPlot) do
			n += 1
			if entry.stage == CreatureModel.STAGE_GROWN then
				grown += 1
			elseif isReady(entry, now) then
				ready += 1
			end
		end
		table.insert(rows, string.format("%s: %d in the ground, %d earning, %d ready to hatch",
			plot.Name, n, grown, ready))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nothing planted"
end

return PlantService
