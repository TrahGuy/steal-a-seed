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
--
--==============================================================================
-- AND THE DEADLINE IS WRITTEN ONCE, NOT WORKED OUT AGAIN EVERY BOOT
--
-- A pod carries HatchAt: the os.time() it becomes ready, decided when it goes in
-- the ground from SeedData.GrowSeconds and then never recomputed. It is saved
-- with the plant, restored with it, and stamped on the model for the clock over
-- the pod to read.
--
-- BECAUSE THE LADDER MOVED. The wait used to come out of a curve that topped out
-- at five minutes; on 2026-09-17 the owner replaced it with a ladder that ends at
-- 75 minutes. Anything that recomputed the wait on load would have added over an
-- hour to every Colossal already in the ground -- so a saved pod with no deadline
-- of its own is grandfathered through SeedData.LegacyGrowSeconds instead, which
-- is the promise it was planted under, and the result is written back as its
-- deadline. One migration, on first load, and never again.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
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
local PlantWander = require(script.Parent:WaitForChild("PlantWander"))

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
	-- os.time() this pod becomes ready, absolute and decided ONCE: at planting
	-- from the ladder, or on the first load of an old save from the curve it was
	-- planted under. Meaningless for a grown plant, which is already out.
	hatchAt: number,
	-- STAGE_POD (unhatched) or STAGE_GROWN (a creature you placed). Nothing in
	-- the ground is ever a sprout any more.
	stage: number,
	-- Which way it stands, in radians, on top of the plot's own rotation. Saved
	-- rather than derived, so a garden you arranged looks the same tomorrow --
	-- placement ids are handed out again on every load and would shuffle every
	-- plant's facing with them.
	facing: number,
	model: Model?,
	-- The HatchPrompt on a ready pod, and nothing else. A grown plant has no
	-- prompt at all -- see THERE IS NO PICKUP PROMPT.
	prompt: ProximityPrompt?,
	-- The InstantHatchPrompt on a pod that is still counting down. Replaced by
	-- `prompt` the moment the clock runs out; see INSTANT HATCH.
	instant: ProximityPrompt?,
	--==========================================================================
	-- WHERE IT IS WALKING, IN THE PLOT'S OWN FRAME
	--
	-- `offset` above is the COMMITTED position -- what a save writes down. These
	-- are the leg in progress. `legTo` becomes `offset` the moment the creature
	-- arrives, which is what "commit at waypoint completion" means: at most one
	-- leg of error in a save, and no profile write per frame.
	--
	-- `legEnd` and `restUntil` are Workspace:GetServerTimeNow() stamps, the same
	-- clock the client interpolates against.
	--==========================================================================
	legFrom: Vector3?,
	legTo: Vector3?,
	legStart: number?,
	legEnd: number?,
	restUntil: number?,
	-- Seeded off the placement id, so a garden restored on join does not send
	-- every creature off on the same tick.
	rng: Random?,
	-- The invisible part that marks a grown plant as yours to pick up, and how
	-- far above the walking point it rides. See "THE MARKER RIDES WHERE THE
	-- PLANT IS".
	anchor: BasePart?,
	anchorLift: number?,
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
local HATCH = PLANTING.Hatch
local PLACE_ACTION = PLANTING.PlaceAction
local PICKUP_ACTION = PLANTING.PickUpAction
local INSTANT = PLANTING.InstantHatch

-- The Robux product the Instant Hatch prompt sells, off the store manifest.
-- Found by kind rather than by key, so renaming the key cannot quietly cut the
-- prompt off from its receipt.
local INSTANT_ITEM: any = nil
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		INSTANT_ITEM = item
		break
	end
end

--==============================================================================
-- A PRICE WITH NO PRODUCT BEHIND IT IS NOT AN OFFER
--
-- Read live, never cached, because a spec swaps the manifest's id under this
-- service and a cached copy would test nothing.
--
-- product = 0 means the owner has not created the Developer Product yet. The
-- prompt is then not drawn AT ALL -- see attachInstantPrompt -- because a tester
-- pressing a 99 Robux button that cannot open a dialog learns only that the game
-- is broken. THIS IS A READINESS GATE, NOT A TIER GATE: with a real id, every
-- growing tier from Tiny to Colossal carries the prompt at the same price.
--==============================================================================
local function instantProductId(): number
	return if INSTANT_ITEM then tonumber(INSTANT_ITEM.product) or 0 else 0
end

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
--==============================================================================
-- THE MAIN BED, WHICH IS ALSO THE PLOT'S FRAME OF REFERENCE
--
-- Every saved plant is stored as an X/Z offset in THIS part's object space, and
-- has been since the first save. The main bed is centred on the plot and shares
-- its rotation, so that frame is the PLOT's frame in all but name -- which is
-- what lets a creature stand on the side bed, or on the grass between the two,
-- without the save format changing by a single field. The offset simply stops
-- being confined to the rectangle it is measured against.
--
-- That is why this is not "the bed you are standing on". It is the ruler.
--==============================================================================
local function soilOf(plot: Model): BasePart?
	local soil = plot:FindFirstChild(PLOT.PlanterName)
	return if soil and soil:IsA("BasePart") then soil else nil
end

--==============================================================================
-- EVERY SURFACE YOU MAY PLANT ON, MAIN FIRST
--
-- From Level 3 a plot has two. Found by the Planter tag rather than by name, so
-- a third bed would need no change here -- and MAIN FIRST, because that is the
-- fallback for anything that has to pick one without being told.
--
-- ONE HELPER, and every caller uses it. The alternative -- placement looking up
-- `Soil` and wandering looking up something else -- is how the two end up
-- disagreeing about where the garden is.
--==============================================================================
local function bedsOf(plot: Model): { BasePart }
	local out: { BasePart } = {}
	local main = soilOf(plot)
	if main then
		table.insert(out, main)
	end
	for _, d in ipairs(plot:GetChildren()) do
		if d:IsA("BasePart") and d ~= main
			and CollectionService:HasTag(d, GameConfig.Tags.Planter) then
			table.insert(out, d)
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
-- HOW MANY THINGS THIS PLOT MAY HOLD
--
-- Off the plot's own Capacity attribute, which MapService stamps when it builds
-- or resizes it. It used to be `rows * BedColumns` -- the invisible planting
-- grid doubling as the gameplay limit -- which tied how DEEP a plot looks to
-- how MANY plants it holds. Level 5 is seven rows for twenty plants precisely
-- because those two had to come apart.
--
-- The fallback is the LEVEL's capacity, not a row count: a plot whose attribute
-- has not replicated yet must not silently answer with a different number than
-- the one the player was sold.
--==============================================================================
local function capacityOf(plot: Model): number
	local cap = tonumber(plot:GetAttribute("Capacity"))
	if cap and cap == cap and cap > 0 then
		return math.floor(cap)
	end
	return GameConfig.plotCapacityForTier(tonumber(plot:GetAttribute("Level")))
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
-- WHICH BED A CLICK LANDS ON, AND THE SERVER DECIDES
--
-- THE CLIENT NEVER NAMES A BED. It sends a world point, exactly as it always
-- has, and the server works out which planting surface that point belongs to.
-- A bed id crossing the wire would be a claim worth forging: name the side bed
-- while clicking your own doorstep and you would be planting through a wall.
--
-- Nearest surface wins, measured to the clamped point on each -- so a click
-- inside a bed picks that bed at distance zero, and a click on the grass
-- between them picks whichever is genuinely closer. There is no tie to break
-- that matters: the two beds do not touch.
--==============================================================================
local function pickBed(plot: Model, worldPos: Vector3): (BasePart?, Vector3?)
	local best, bestOffset, bestD = nil, nil, math.huge
	for _, bed in ipairs(bedsOf(plot)) do
		local offset = clampToSoil(bed, worldPos)
		local d = (topOf(bed, offset).Position - worldPos).Magnitude
		if d < bestD then
			best, bestOffset, bestD = bed, offset, d
		end
	end
	return best, bestOffset
end

--==============================================================================
-- ONE PLOT-LOCAL POINT, WHICHEVER BED IT CAME FROM
--
-- Converts a world point to the main bed's frame, which is where every saved
-- plant lives. A plant on the side bed is stored the same way as one on the
-- main bed -- as a distance across and along the PLOT -- so nothing downstream
-- has to know which surface it stands on.
--==============================================================================
local function plotOffsetOf(plot: Model, worldPos: Vector3): Vector3?
	local main = soilOf(plot)
	if not main then
		return nil
	end
	local here = main.CFrame:PointToObjectSpace(worldPos)
	return Vector3.new(here.X, 0, here.Z)
end

--==============================================================================
-- WHERE A CREATURE MAY WALK
--
-- The whole fenced interior -- the main rectangle, the wing when the level has
-- one, clear of the fence and out of the gateway. The shape and every rule about
-- it live in PlantWander, which is also what picks each walk; this is the one
-- door PlantService uses to make a point legal.
--
-- Returns the clamped PLOT-LOCAL point. Used where a position has to BECOME
-- legal, which today is a garden rebased onto a smaller plot. Walks are never
-- clamped: PlantWander.Choose only ever picks a destination whose whole straight
-- route is already inside.
--==============================================================================
local function clampToPlotRegion(plot: Model, local_: Vector3): Vector3
	return PlantWander.Clamp(PlantWander.RegionFor(plot), local_)
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
-- render() puts the pick-up marker on anything grown, and the marker builder
-- needs render() to have run. One forward declaration breaks the knot, rather
-- than shuffling three functions into an order that reads worse than it works.
--==============================================================================
-- THE MARKER RIDES WHERE THE PLANT IS, NOT WHERE IT WAS PLANTED
--
-- MEASURED: a grown plant is walked by every CLIENT from four wander attributes,
-- and the server never moves its parts. The pick-up prompt this part used to
-- carry hung off the model's PrimaryPart first, so on the server it stayed at
-- the planting spot while the plant walked away -- 7.5 studs from the player on
-- screen, 63.0 studs on the server, against a 26-stud prompt.
--
-- So there is ONE small invisible part per grown plant, kept OUTSIDE the model
-- and moved by the server on its existing tick to the same
-- `wanderWorld(currentOffset())` point the leg is authored from. The prompt is
-- gone (see THERE IS NO PICKUP PROMPT); the part stays, because it is what
-- PlantPickUI reads to know a plant is grown and yours. Nothing else moves:
-- creature parts are not replicated, not made queryable, and the model's
-- bounding box, part count and client PivotTo are untouched. Outside the model
-- because PlantSway pivots the whole model every frame and would carry a child
-- anchor along a second time.
--
-- WHERE THEY LIVE: plot/Runtime/PickupAnchors, one part per placement id. Runtime
-- survives a plot resize (MapService's keep list) and is emptied when a plot is
-- released (PlotService.clearPlot), so the folder can never outlive the garden.
--==============================================================================
local function anchorsFolder(plot: Model): Instance
	local runtime = plot:FindFirstChild(PLOT.RuntimeFolderName)
	if not runtime then
		runtime = Instance.new("Folder")
		runtime.Name = PLOT.RuntimeFolderName
		runtime.Parent = plot
	end
	local folder = runtime:FindFirstChild(PLOT.PickupAnchorsFolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PLOT.PickupAnchorsFolderName
		folder.Parent = runtime
	end
	return folder
end

-- Destroys the anchor. Also forgets the prompt references -- a ready pod's
-- HatchPrompt and a growing pod's InstantHatchPrompt -- which every caller was
-- already clearing by hand. Both live on the model, so whatever is dropping the
-- anchor is dropping them too.
local function dropAnchor(entry: Planted)
	local anchor = entry.anchor
	entry.anchor = nil
	entry.anchorLift = nil
	entry.prompt = nil
	entry.instant = nil
	if anchor and anchor.Parent then
		anchor:Destroy()
	end
end

--==============================================================================
-- NO ANCHOR WITHOUT A LIVING OWNER
--
-- Every anchor in the folder must be the exact instance a live grown entry is
-- holding. Anything else -- a restore that replaced a table, a rebuild that
-- raced a pickup -- is destroyed here, so repeated rebuilds cannot accumulate.
--==============================================================================
local function sweepAnchors(plot: Model)
	local runtime = plot:FindFirstChild(PLOT.RuntimeFolderName)
	local folder = runtime and runtime:FindFirstChild(PLOT.PickupAnchorsFolderName)
	if not folder then
		return
	end
	local live: { [Instance]: boolean } = {}
	for _, entry in pairs(growing[plot] or {}) do
		if entry.anchor then
			live[entry.anchor] = true
		end
	end
	for _, child in ipairs(folder:GetChildren()) do
		if not live[child] then
			child:Destroy()
		end
	end
end

-- Defined with the wander, which is where currentOffset and wanderWorld live.
local placeAnchor: (Planted, number) -> ()

local attachPickup: (Planted) -> ()
-- Same knot as attachPickup: render() destroys the model a leg was published
-- on, and stopWander is defined with the rest of the wander further down.
local stopWander: (Planted) -> ()

--==============================================================================
-- WHERE A PLANTED THING STANDS
--
-- The soil under its offset, turned to face back down its own plot, plus its own
-- bearing. ONE definition, because render() builds the model from it and the
-- hatch reveal has to put the creature in exactly the same place -- and the
-- obvious shortcut, reading the pod model's pivot, is wrong twice: a pod's pivot
-- is its shell's CENTRE rather than its base, and the shell is a cylinder that
-- was rolled ninety degrees to stand up, so its frame's "down" points sideways.
--==============================================================================
local function standCF(entry: Planted): CFrame?
	local soil = soilOf(entry.plot)
	if not soil then
		return nil
	end
	local base = topOf(soil, entry.offset)
	return CFrame.new(base.Position) * CFrame.Angles(0, math.rad(180), 0)
		* entry.plot:GetPivot().Rotation
		* CFrame.Angles(0, entry.facing, 0)
end

local function render(entry: Planted)
	--==========================================================================
	-- A REBUILT MODEL HAS NO LEG
	--
	-- render() destroys and recreates the model, which takes the four wander
	-- attributes with it -- so the leg they described has to go too, or the
	-- entry would claim to be walking a route no client can see. The next tick
	-- issues a fresh one.
	--
	-- This is also the hatch path: a pod becomes a creature here, and a creature
	-- is the thing that is allowed to walk.
	--==========================================================================
	stopWander(entry)
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	entry.model = nil
	dropAnchor(entry)
	-- The gate is the reference -- the 180 in standCF turns a plant to look back
	-- down its own plot rather than out of the fence -- and each plant's own
	-- bearing is added on top of it there.
	local where = standCF(entry)
	if not where then
		return
	end
	local model = CreatureModel.Build(entry.species, entry.tier, entry.stage,
		where, plantsFolder(entry.plot))
	local owner = PlotService.OwnerOf(entry.plot)
	--==========================================================================
	-- IT STREAMS AS ONE THING, AND ITS OWNER NEVER LOSES IT
	--
	-- MEASURED 2026-09-23, Play with StreamingEnabled: a garden taken out of range
	-- (a run to Starbloom) and back came home with whole clusters of parts 4 to
	-- 65 studs from their plants -- a Toadcap's cap over the fence, a Nubkin's
	-- body standing apart from its face, a Petalpip's six petals in the air.
	--
	-- The engine default streams a model PART BY PART. The server never moves
	-- these parts (see THE MARKER RIDES WHERE THE PLANT IS), so every part that
	-- comes back arrives at the spot this line built it on, while PlantSway has
	-- walked the plant somewhere else and moves it by the RELATIVE PivotTo that
	-- keeps whatever offset each part already has. Two shapes, both logged:
	-- parts that left and returned while the Base stayed (the model is never
	-- re-measured), and a Base that left and returned while other parts stayed
	-- (the model is re-measured from half a server pose and half a walked one).
	-- Either way the offset is frozen in for the rest of the session.
	--
	-- PlantSway's contract is that a plant arrives and leaves WHOLE -- the Base
	-- arriving builds the walk, the Base leaving forgets it -- and this makes the
	-- engine keep it. For every other player the model is Atomic, all of it or
	-- none of it; for the owner it is persistent, because GardenUI reads the
	-- garden off these models and an Atomic garden would go blank on a raid.
	--
	-- Only a real Player can be persistent; the specs' stand-in owners are
	-- tables, and those plots still get the Atomic half.
	--==========================================================================
	model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	if typeof(owner) == "Instance" and owner:IsA("Player") then
		model:AddPersistentPlayer(owner)
	end
	-- IDENTITY, not position. PlantSway phases its idle off this so a bed is not
	-- a chorus line, and GardenUI keys its rows on it.
	model:SetAttribute("PlacementId", entry.id)
	model:SetAttribute("PlantedAt", entry.plantedAt)
	-- THE ONE NUMBER THE CLOCK OVER THE POD IS ALLOWED TO USE. PlantUI, GardenUI
	-- and the tutorial all draw the time left as this minus now, so the panel and
	-- the prompt can never disagree about when a pod is ready. PlantedAt stays for
	-- identity and for the progress ring's full length.
	model:SetAttribute("HatchAt", entry.hatchAt)
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
		if owner then
			PlayerDataService.MarkSeen(owner, entry.species.Id)
		end
		-- A grown plant can always be taken back off your own farm, so the
		-- marker goes on the moment it is standing there. Declared above
		-- because the marker builder needs render() and render() needs it.
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
				-- Saved, so a rejoin restores the same deadline rather than
				-- starting the wait again or applying today's ladder to it.
				HatchAt = entry.hatchAt,
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
--
-- One comparison against the pod's own deadline. Nothing here reads the ladder:
-- a pod that was planted under a different one keeps the wait it was given.
--==============================================================================
local function isReady(entry: Planted, now: number): boolean
	return entry.stage == CreatureModel.STAGE_POD and now >= entry.hatchAt
end

local hatch: (Player, Planted, boolean?) -> boolean
local pickUp: (Player, Planted) -> boolean

local function attachHatchPrompt(entry: Planted)
	-- The clock has run out, so there is no wait left to pay for. The free
	-- prompt replaces the paid one rather than standing beside it.
	if entry.instant then
		entry.instant:Destroy()
		entry.instant = nil
	end
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
-- INSTANT HATCH
--
-- A pod that is still counting down carries a second prompt: F, INSTANT HATCH,
-- and a Robux price. Pressing it only ASKS Roblox for the purchase. Nothing
-- happens to the pod until the receipt reaches StoreService, which calls
-- InstantHatch below -- and that runs the same hatch() as the free prompt,
-- without the clock.
--
-- THE SERVER OPENS THE DIALOG. MarketplaceService lets a server prompt a
-- purchase on a player's screen, so there is no remote here and nothing a client
-- can send. The press arrives as the prompt's Triggered, engine-stamped with who
-- pressed it; everything after that is decided on this side.
--
--==============================================================================
-- WHICH POD A RECEIPT HATCHES
--
-- A receipt names a player and a product, never a pod. So the pod is written
-- down when the dialog opens, and the receipt reads the note back:
--
--   1. The pod they pressed, if it is still an unhatched pod in their own plot.
--      That holds even if its clock ran out while the dialog was open, because
--      that is the pod they paid for.
--   2. Otherwise, the unhatched pod in their plot with the longest wait left.
--      This is the no-note case: a receipt Roblox re-delivers after a rejoin.
--   3. Otherwise nothing, and the receipt is NOT acknowledged. Roblox delivers
--      it again later, so a purchase never lands on an empty bed and vanishes.
--==============================================================================
-- UserId -> the pod that player last opened the purchase dialog for. Keyed by
-- id rather than Player, and cleared when they leave.
local wanted: { [number]: { plot: Model, id: number } } = {}
-- UserId -> os.clock() of the last dialog opened for them.
local lastOffer: { [number]: number } = {}
-- Said once per server, not once per press.
local warnedNoProduct = false

local function attachInstantPrompt(entry: Planted)
	local model = entry.model
	local handle = if model then model.PrimaryPart else nil
	if not (model and handle and INSTANT_ITEM) or entry.stage ~= CreatureModel.STAGE_POD then
		return
	end
	-- No product, no prompt: a dead button is worse than no button. Every tier is
	-- offered once an id exists; nothing here looks at the tier.
	if instantProductId() <= 0 then
		return
	end
	if entry.instant and entry.instant.Parent then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InstantHatchPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = INSTANT.ActionText
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = INSTANT.Key
	prompt.GamepadKeyCode = INSTANT.GamepadKey
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = PLANT_RANGE
	prompt.RequiresLineOfSight = false
	-- What PromptUI prints in the capsule. Roblox charges the Dashboard's price;
	-- this is the manifest's copy of it, exactly as a shop tile is.
	prompt:SetAttribute("Robux", INSTANT_ITEM.robux)
	-- Drawn above the pod's HATCHING label rather than on top of it.
	prompt:SetAttribute("OverPodLabel", true)
	-- Offered to the owner only. That is courtesy -- PromptUI does not draw it
	-- for anybody else -- and OfferInstantHatch refuses a stranger either way.
	local owner = PlotService.OwnerOf(entry.plot)
	if owner then
		prompt:SetAttribute("ReservedFor", owner.UserId)
	end
	prompt.Parent = handle
	entry.instant = prompt

	-- Not kept in serviceConnections: the connection is disconnected when the
	-- prompt is destroyed, and every planted pod gets one of these.
	prompt.Triggered:Connect(function(player)
		PlantService.OfferInstantHatch(player, entry.plot, entry.id)
	end)
end

--==============================================================================
-- THE PRESS: CHECK, WRITE THE NOTE, OPEN THE DIALOG
--
-- Takes the plot as well as the id because placement ids are only unique inside
-- a plot. Looking the id up in the PRESSER's plot would let a stranger's press
-- on pod 3 here open a dialog for their own pod 3 at home.
--==============================================================================
function PlantService.OfferInstantHatch(player: Player, plot: Model, placementId: number): boolean
	local byPlot = growing[plot]
	local entry = if byPlot then byPlot[placementId] else nil
	if not entry then
		return false
	end
	-- Yours. The prompt is only DRAWN for the owner, but a key press reaches it
	-- from anybody in range, and nobody may be sold a hatch of somebody else's pod.
	if PlotService.OwnerOf(plot) ~= player then
		return false
	end
	-- A ready pod hatches for free on E. The tick swaps this prompt out within a
	-- second of the clock running out, so this only catches a press in between.
	if entry.stage ~= CreatureModel.STAGE_POD or isReady(entry, os.time()) then
		return false
	end
	local productId = instantProductId()
	if productId <= 0 then
		if not warnedNoProduct then
			warnedNoProduct = true
			warn("[Seed/PlantService] Instant Hatch was pressed, but its Developer Product "
				.. "id is still 0. Create the product in the Creator Dashboard and fill its "
				.. "id into GameConfig.Store.InWorld.")
		end
		return false
	end
	local now = os.clock()
	if now - (lastOffer[player.UserId] or -math.huge) < INSTANT.OfferGapSeconds then
		return false
	end
	lastOffer[player.UserId] = now
	wanted[player.UserId] = { plot = plot, id = placementId }
	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	if not ok then
		warn(string.format("[Seed/PlantService] Instant Hatch dialog for %s failed: %s",
			player.Name, tostring(err)))
		return false
	end
	return true
end

--==============================================================================
-- THE RECEIPT: HATCH THE POD THAT WAS PAID FOR
--
-- Called by StoreService and nothing else, only once a receipt for the Instant
-- Hatch product has arrived. Returns whether a pod actually hatched; false leaves
-- the receipt unacknowledged so Roblox tries again.
--==============================================================================
function PlantService.InstantHatch(player: Player): boolean
	local plot = PlotService.PlotOf(player)
	local byPlot = if plot then growing[plot] else nil
	if not (plot and byPlot) then
		return false
	end
	local note = wanted[player.UserId]
	local entry: Planted? = if note and note.plot == plot then byPlot[note.id] else nil
	if not (entry and entry.stage == CreatureModel.STAGE_POD) then
		entry = nil
		local now = os.time()
		local longest = -math.huge
		for _, candidate in pairs(byPlot) do
			if candidate.stage == CreatureModel.STAGE_POD then
				local left = candidate.hatchAt - now
				-- Ties go to the lower id, so the same bed always picks the same pod.
				if left > longest or (left == longest and entry and candidate.id < entry.id) then
					longest = left
					entry = candidate
				end
			end
		end
	end
	if not entry then
		return false
	end
	if not hatch(player, entry, true) then
		return false
	end
	wanted[player.UserId] = nil
	return true
end

--==============================================================================
-- AND THE MARK THAT SAYS IT CAN COME BACK
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
-- neighbour and your garden. `pickUp` re-tests it on every route in, and there
-- is exactly one route in: PickUpAction -> PickUpById, which PlantPickUI's
-- button and the Garden panel both send.
--
--==============================================================================
-- THERE IS NO PICKUP PROMPT
--
-- There was one, hung on this part and "disarmed" by setting its keyboard and
-- gamepad keys to KeyCode.Unknown. That did not disarm it. It armed it for the
-- MOUSE: a mouse button's InputObject carries that same empty KeyCode, so the
-- engine matched every mouse press against the prompt's key -- and with a zero
-- hold, the prompt fired on the press and the press was spent.
--
-- MEASURED in Play, standing 8.6 studs from a grown plant: two left clicks and
-- a right click each fired PromptTriggered on PickupPrompt and reached
-- UserInputService with gameProcessedEvent = true. From further away than the
-- 26-stud range the same clicks arrived unprocessed. So anywhere inside your own
-- plot -- which is always within 26 studs of something grown -- the mouse
-- stopped reaching the game: PlantPlace dropped every click on the soil, a
-- hotbar slot heard the press and never the release, the PICK UP button never
-- fired, and the right button the camera turns with arrived already handled.
--
-- A prompt nobody is allowed to press has no reason to exist, so the marker is
-- now only the part. Nothing on it can take input.
--==============================================================================
function attachPickup(entry: Planted)
	local model = entry.model
	local handle = if model then model.PrimaryPart else nil
	if not (model and handle) or entry.anchor then
		return
	end

	--==========================================================================
	-- ONE INVISIBLE PART, NOT THE MODEL'S HANDLE
	--
	-- Every property that could make it matter is off: invisible, anchored, no
	-- collision, no touch, no query -- so bats, placement rays and PlantPickUI's
	-- box test all go straight through it -- and no shadow. It rides at the
	-- handle's height above the walking point.
	--
	-- PlantPickUI looks it up by placement id under the player's OWN plot, so a
	-- neighbour's plant never resolves and ownership on the client stays
	-- structural. Its existence is the whole message: grown, and yours.
	--==========================================================================
	local soil = soilOf(entry.plot)
	local groundY = if soil then topOf(soil, entry.offset).Position.Y else handle.Position.Y
	local anchor = Instance.new("Part")
	anchor.Name = tostring(entry.id)
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Locked = true
	anchor:SetAttribute("PlacementId", entry.id)
	anchor.CFrame = CFrame.new(handle.Position)
	local folder = anchorsFolder(entry.plot)
	local stale = folder:FindFirstChild(anchor.Name)
	if stale then
		stale:Destroy()
	end
	anchor.Parent = folder
	entry.anchor = anchor
	entry.anchorLift = handle.Position.Y - groundY
	placeAnchor(entry, Workspace:GetServerTimeNow())
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
--==============================================================================
-- IT COMPRESSES BEFORE IT LETS GO
--
-- A shell that only flies apart reads as a deletion with extra steps. A shell
-- that squeezes first, flashes from inside, and THEN comes apart reads as
-- something breaking out of it -- which is the event. Three tenths of a second
-- either way; the difference is entirely in the order.
--
-- SPREAD IS THE POD'S OWN DIAMETER, not a fixed 3.4 studs. That number was
-- right for a 1.66-stud Tiny and threw a Colossal's pieces across the bed and
-- through the fence.
--
-- NOTHING HERE IS PHYSICS. Every piece stays anchored and stops being queryable
-- the moment the tag comes off, so a burst can neither push a player nor be
-- clicked. The whole model is destroyed a frame after the burst ends.
--==============================================================================
local function burst(model: Model, tier: number)
	CollectionService:RemoveTag(model, GameConfig.Tags.Planted)
	local B = HATCH.Burst
	local origin = model:GetPivot().Position
	local diameter = SeedData.PodDiameter(tier)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end

	-- The flash lives on the shell and dies with it, so there is no light to
	-- clean up and nothing to leak if this model is destroyed early.
	local host = model.PrimaryPart
	if host then
		local flash = Instance.new("PointLight")
		flash.Name = "HatchFlash"
		flash.Color = SeedData.ColorForTier(tier)
		flash.Brightness = B.FlashBrightness
		flash.Range = B.FlashRange
		flash.Shadows = false
		flash.Parent = host
		TweenService:Create(flash,
			TweenInfo.new(BURST, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Brightness = 0 }):Play()
	end

	local pieces = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
			d.CanCollide = false
			d.CanTouch = false
			table.insert(pieces, d)
		end
	end

	local squeeze = BURST * B.CompressShare
	local fly = math.max(BURST - squeeze, 0.05)
	for _, d in ipairs(pieces) do
		local toward = origin + (d.Position - origin) * B.Compress
		TweenService:Create(d,
			TweenInfo.new(squeeze, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(toward) * (d.CFrame - d.Position),
				Size = d.Size * B.Compress,
			}):Play()
	end

	task.delay(squeeze, function()
		for _, d in ipairs(pieces) do
			if d.Parent then
				local away = d.Position - origin
				-- A part sitting exactly on the pivot has no direction of its
				-- own, so it goes straight up rather than nowhere.
				local dir = if away.Magnitude > 0.05 then away.Unit else Vector3.new(0, 1, 0)
				local goal = d.CFrame
					+ (dir * diameter * B.SpreadPerDiameter + Vector3.new(0, B.Lift, 0))
				TweenService:Create(d,
					TweenInfo.new(fly, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = goal * CFrame.Angles(math.rad(55), math.rad(40), math.rad(25)),
						Transparency = 1,
					}):Play()
			end
		end
	end)
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
-- THE REVEAL IS ANNOUNCED ONCE, AND IT OWNS NOTHING
--
-- One message per hatch, to every client, carrying what the reveal needs to draw
-- itself: which species, which tier, what it pays, where the pod stood, who owns
-- it, whether it was paid for, whether it was a first discovery, and the SERVER
-- TIME it happened. Each nearby client animates locally from that; no CFrame is
-- streamed and no client is asked to confirm anything.
--
-- SENT AFTER THE REWARD IS BANKED AND SAVED, always. Nothing below is allowed to
-- decide whether a hatch happened -- if this message is never sent, or every
-- client drops it, the player still has the plant and the garden is still saved.
--
-- OnRevealed is for the server side of the same event: SoundCues and HatchFX
-- live on the client, but a service that wants to know a hatch happened should
-- not have to listen to a remote it does not own. The spec uses it too.
--==============================================================================
local revealChannel: RemoteEvent? = nil
local onRevealed: { (any) -> () } = {}
local revealToken = 0

function PlantService.OnRevealed(fn: (any) -> ()): () -> ()
	table.insert(onRevealed, fn)
	return function()
		local i = table.find(onRevealed, fn)
		if i then
			table.remove(onRevealed, i)
		end
	end
end

local function announceReveal(payload: any)
	for _, fn in ipairs(onRevealed) do
		local ok, err = pcall(fn, payload)
		if not ok then
			warn("[Seed/PlantService] reveal listener failed: " .. tostring(err))
		end
	end
	local channel = revealChannel
	if channel then
		-- pcall because a cosmetic message is never worth an error inside the
		-- call that just handed somebody a plant.
		pcall(function()
			channel:FireAllClients(HATCH.Action, payload)
		end)
	end
end

--==============================================================================
-- HATCHING
--
-- The creature is handed over BEFORE the pod is destroyed. The other order
-- loses the whole raid if the player has no Backpack at that instant -- dying
-- with the prompt held is enough -- and a prize that evaporates because of a
-- frame is the worst bug this game can have.
--
--==============================================================================
-- THE ORDER, WHICH IS NOT NEGOTIABLE
--
--   1. the guards          -- yours, a pod, ready or paid for
--   2. the Tool            -- in their Backpack, and it is theirs from here
--   3. out of the garden   -- the authoritative table, and the anchor with it
--   4. saved               -- the profile knows before anything is drawn
--   5. Almanac, tutorial   -- and MarkSeen says whether this was a discovery
--   6. the payload         -- read off the pod while it still stands
--   7. the decoration      -- the shell bursts, the clients are told
--
-- NOT ONE YIELD ANYWHERE IN 1 TO 6. No wait, no animation, no remote round trip
-- and no client acknowledgement: a player who disconnects, dies or crashes at
-- any point during step 7 keeps the plant, because the plant was already theirs
-- before step 7 began.
--==============================================================================
function hatch(player: Player, entry: Planted, early: boolean?): boolean
	local byPlot = growing[entry.plot]
	if not byPlot or byPlot[entry.id] ~= entry then
		return false
	end
	-- Yours. The prompt is drawn for anybody standing close enough, so this is
	-- the check that actually owns the pod.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false
	end
	--==========================================================================
	-- THE CLOCK, UNLESS THE WAIT WAS BOUGHT
	--
	-- `early` comes from InstantHatch alone, and only once a receipt has landed.
	-- It skips the wait and nothing else: the pod still has to be an unhatched
	-- pod in this player's own plot.
	--==========================================================================
	if entry.stage ~= CreatureModel.STAGE_POD then
		return false
	end
	if not early and not isReady(entry, os.time()) then
		return false
	end
	--==========================================================================
	-- THE EQUIP WAITS FOR THE REVEAL, THE TOOL DOES NOT
	--
	-- The Tool is created and owned NOW. Putting it in their hands is held back
	-- until the creature has finished coming up, because equipping mid-burst
	-- replaces the reveal with a first-person view of the same plant -- and
	-- CarryService does the waiting, with its own guards, because a hand is its
	-- department and not this one's.
	--==========================================================================
	local equipAfter = BURST + HATCH.Reveal.Seconds
		+ (if early then HATCH.Paid.PulseSeconds else 0)
	if not CarryService.GiveHatched(player, entry.species, entry.tier, equipAfter) then
		return false
	end
	-- Said here rather than in CarryService, which also hands a Tool over for a
	-- pickup and for a rejoin and cannot tell the three apart.
	log(string.format("%s %s a %d tier %s.", player.Name,
		if early then "instantly hatched" else "hatched", entry.tier, entry.species.Name))

	-- STOPS WALKING BEFORE IT LEAVES THE TABLE. The model outlives this call by
	-- the length of a burst or a lift, and a model still carrying a leg is a
	-- model every client keeps walking toward a destination nobody owns.
	stopWander(entry)
	byPlot[entry.id] = nil
	local model = entry.model
	entry.model = nil
	dropAnchor(entry)
	persist(entry.plot)
	-- THE REVEAL IS THE HATCH. Until the shell breaks you do not know which
	-- species you had, so this is the moment the Almanac learns it. It answers
	-- TRUE only the first time, which is exactly what the label needs to know.
	local discovered = PlayerDataService.MarkSeen(player, entry.species.Id)
	PlayerDataService.RecordTutorial(player, "hatch")

	-- Everything from here is decoration. The plant is theirs and the garden is
	-- saved; step 7 of the order above.
	-- WHERE THE REVEAL STANDS: the same CFrame render() built the pod on, which is
	-- the soil under it and the way it was facing. See standCF.
	local where = standCF(entry)
	revealToken += 1
	announceReveal({
		token = revealToken,
		species = entry.species.Id,
		tier = entry.tier,
		rarity = entry.species.Rarity,
		-- The same figure the garden panel and the pop print, from the same
		-- function, so a reveal cannot advertise a rate the plant will not pay.
		income = SeedData.IncomePerSecond(entry.species, entry.tier),
		cf = where,
		owner = player,
		paid = early == true,
		discovery = discovered,
		-- Server time, so every client starts the same animation at the same
		-- moment without being told each frame.
		at = Workspace:GetServerTimeNow(),
	})
	if model and model.Parent then
		burst(model, entry.tier)
	end
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
	-- your garden -- the plant is visible to them, the action is not.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false
	end
	if entry.stage ~= CreatureModel.STAGE_GROWN then
		return false
	end
	-- Straight into their hands, as it always was: a pickup is not a reveal and
	-- there is nothing to wait for.
	if not CarryService.GiveHatched(player, entry.species, entry.tier) then
		return false
	end

	-- STOPS WALKING BEFORE IT LEAVES THE TABLE. The model outlives this call by
	-- the length of a burst or a lift, and a model still carrying a leg is a
	-- model every client keeps walking toward a destination nobody owns.
	stopWander(entry)
	byPlot[entry.id] = nil
	local model = entry.model
	entry.model = nil
	dropAnchor(entry)
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
-- THIS IS THE ONLY WAY IN. A prompt used to hand `pickUp` an entry it already
-- had; there is no pickup prompt any more, so every pickup in the game -- the
-- Garden panel's and the PICK UP button's -- arrives here with an id and goes
-- through this lookup, and the lookup is itself a check.
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

	--==========================================================================
	-- WHICH BED, DECIDED HERE AND NOWHERE ELSE
	--
	-- The click is still a claim and still gets clamped rather than refused.
	-- What is new is that there may be two surfaces to clamp against, and the
	-- SERVER picks: nearest planting surface to the point the client sent.
	--
	-- The reach test then runs on the clamped point, so "I clicked a thousand
	-- studs that way" becomes a point on the rim of the nearer bed and fails
	-- the distance check honestly -- including the case where the forged point
	-- names a bed on somebody else's plot, because `plot` was resolved from the
	-- SENDER before any of this and the beds are read off that plot only.
	--==========================================================================
	local bed, bedOffset = pickBed(plot, worldPos)
	if not (bed and bedOffset) then
		return refuse(player, "NO_SOIL")
	end
	local landing = topOf(bed, bedOffset).Position
	if (landing - root.Position).Magnitude > PLANT_RANGE then
		return refuse(player, "OUT_OF_RANGE")
	end
	-- Stored in the PLOT's frame, whichever bed it landed on.
	local offset = plotOffsetOf(plot, landing)
	if not offset then
		return refuse(player, "NO_SOIL")
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
	local now = os.time()
	local entry: Planted = {
		plot = plot,
		id = id,
		species = species,
		tier = tier,
		offset = offset,
		plantedAt = now,
		-- The whole wait, once, off the approved ladder. A grown plant gets the
		-- same field with the time already past, because nothing reads it.
		hatchAt = now + (if hatched then 0 else SeedData.GrowSeconds(tier)),
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
	if isReady(entry, now) then
		attachHatchPrompt(entry)
	else
		-- On the pod the moment it is in the ground, not a tick later.
		attachInstantPrompt(entry)
	end
	persist(plot)
	-- Consumed. Destroying the tool is what makes planting a decision rather
	-- than a duplication bug -- and naming it to SyncHeldNow is what takes it,
	-- and only it, off the saved bag.
	tool:Destroy()
	CarryService.SyncHeldNow(player, { tool })
	PlayerDataService.RecordTutorial(player, if hatched then "plant" else "place")

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
		-- A plot restored twice must not leave the first garden's anchors behind.
		for _, old in pairs(growing[plot] or {}) do
			dropAnchor(old)
		end
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
			-- A SAVE FROM BEFORE THE LADDER HAS NO DEADLINE
			--
			-- Its pod was planted under the old curve, which never asked for more
			-- than five minutes. Handing it today's ladder would add up to seventy
			-- more to a pod somebody left in the ground last night, so the old
			-- promise is worked out once, here, and from then on the pod carries
			-- the deadline in its save like every new one.
			--
			-- A pod whose old wait is already over comes back READY, because it
			-- was ready: the deadline is in the past and isReady says so.
			--==============================================================
			local deadline = if row then tonumber(row.HatchAt) else nil
			if (not deadline or deadline <= 0) and at then
				deadline = at + SeedData.LegacyGrowSeconds(tier)
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
			if not stage and species and at and deadline then
				stage = if now >= deadline
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

			--==============================================================
			-- EVERY VALID ROW COMES BACK, EVEN OVER CAPACITY
			--
			-- This used to read `and restored < cap`, and persist() below then
			-- wrote the shortened list back to the profile -- so a garden that
			-- ended up over its plot's capacity lost the overflow PERMANENTLY,
			-- on the next join, with no message and nothing to undo.
			--
			-- A player can be over capacity honestly: the ladder was re-cut and
			-- an old save legitimately holds more than its migrated level. The
			-- limit belongs on PLACING a new plant, which is where it now lives
			-- and nowhere else. Restoration is not the place to enforce it --
			-- the plants already exist and they are already theirs.
			--==============================================================
			if species and at and x and z and stage then
				local id = nextId[plot] + 1
				nextId[plot] = id
				local entry: Planted = {
					plot = plot,
					id = id,
					species = species,
					tier = tier,
					-- Clamped to the PLOT, not to the main bed. A creature that
					-- wandered onto the side bed or across the grass saved a
					-- perfectly legal offset that the main bed's rectangle
					-- would drag it back out of.
					--
					-- An old save has no idea any of this happened: its X/Z are
					-- in this same frame and land exactly where they always
					-- did, on the main bed.
					offset = clampToPlotRegion(plot, Vector3.new(x, 0, z)),
					plantedAt = at,
					hatchAt = deadline or at,
					stage = stage,
					facing = facing or facingFor(id),
					model = nil,
					prompt = nil,
				}
				byPlot[id] = entry
				render(entry)
				if isReady(entry, now) then
					attachHatchPrompt(entry)
				else
					attachInstantPrompt(entry)
				end
				restored += 1
			else
				dropped += 1
			end
		end
		if restored > 0 or dropped > 0 then
			-- `dropped` now only ever counts rows that were not valid plants at
			-- all -- a species that no longer exists, a missing timestamp. It no
			-- longer counts anything that merely did not fit.
			local over = restored - cap
			log(string.format("%s: restored %d plant(s)%s%s.", player.Name, restored,
				if dropped > 0 then string.format(", %d unreadable row(s) skipped", dropped) else "",
				if over > 0 then string.format(" -- %d over the level's capacity of %d, kept",
					over, cap) else ""))
		end
		-- Write back, so anything dropped stops being carried forever and any
		-- migrated position is saved in the new shape.
		persist(plot)
		sweepAnchors(plot)
	end)
end

--==============================================================================
-- WANDERING
--
-- A GROWN creature walks its owner's plot. A POD DOES NOT MOVE -- it sits where
-- it was planted until somebody hatches it, because a seed that strolled off is
-- a seed you cannot find again.
--
-- The server owns every decision: whether a plant may move, where it is, where
-- it is going, when it set off and when it arrives. It publishes those as four
-- attributes and nothing else crosses the wire -- no CFrames, no per-frame
-- anything. Clients interpolate the same four numbers against the same server
-- clock, so a creature is in the same place on every screen. The version this
-- replaced rolled dice on each client, which was cheap and disagreed with
-- itself the moment two people looked at one garden.
--
-- Cost: four attribute writes per creature per leg, and a leg lasts five to
-- twelve seconds. Twenty creatures on a full plot is under two writes a second.
--==============================================================================
--==============================================================================
-- WHERE A CREATURE IS RIGHT NOW, MID-STRIDE
--
-- `offset` is the last COMMITTED position -- the start of the current leg, or
-- wherever it last arrived. That is the right thing to save and the wrong thing
-- to answer with when something needs to know where the creature is standing.
--
-- Eased with the SAME smoothstep the client draws with. Two different curves
-- would put the server's idea of the creature and the player's picture of it in
-- different places, which is the one thing a shared clock was supposed to stop.
--==============================================================================
local function currentOffset(entry: Planted, srvNow: number): Vector3
	local from, to = entry.legFrom, entry.legTo
	local t0, t1 = entry.legStart, entry.legEnd
	if not (from and to and t0 and t1) or t1 <= t0 then
		return entry.offset
	end
	local raw = math.clamp((srvNow - t0) / (t1 - t0), 0, 1)
	local eased = raw * raw * (3 - 2 * raw)
	return from:Lerp(to, eased)
end

local function wanderWorld(plot: Model, offset: Vector3): Vector3?
	local main = soilOf(plot)
	if not main then
		return nil
	end
	return topOf(main, offset).Position
end

--==============================================================================
-- THE ANCHOR, AT THE AUTHORITATIVE POINT
--
-- The same currentOffset() and wanderWorld() the leg is published from, so the
-- marker stands where every client is drawing the plant, give or take one tick
-- of travel: GameConfig.Plant.TickSeconds (1 s) at the fastest walk on the
-- ladder, a Tiny's 2.05 studs/s -- 3.1 at the middle of a leg, where the
-- smoothstep peaks at one and a half times the average.
--
-- Skipped when it would move less than a twentieth of a stud, so a resting
-- garden writes nothing at all.
--==============================================================================
local ANCHOR_EPSILON = 0.05

function placeAnchor(entry: Planted, srvNow: number)
	local anchor = entry.anchor
	if not (anchor and anchor.Parent) then
		return
	end
	local world = wanderWorld(entry.plot, currentOffset(entry, srvNow))
	if not world then
		return
	end
	local at = world + Vector3.new(0, entry.anchorLift or 0, 0)
	if (at - anchor.Position).Magnitude >= ANCHOR_EPSILON then
		anchor.CFrame = CFrame.new(at)
	end
end

local function trackAnchors(byPlot: { [number]: Planted }, srvNow: number)
	for _, entry in pairs(byPlot) do
		if entry.anchor then
			placeAnchor(entry, srvNow)
		end
	end
end

--==============================================================================
-- PUBLISH A LEG
--
-- The four facts, and the only thing that ever crosses the wire. World points,
-- so a client needs no plot frame to draw the walk.
--==============================================================================
local function publishLeg(entry: Planted, fromW: Vector3, toW: Vector3,
	t0: number, t1: number)
	local model = entry.model
	if not (model and model.Parent) then
		return
	end
	model:SetAttribute("WanderFrom", fromW)
	model:SetAttribute("WanderTo", toW)
	model:SetAttribute("WanderT0", t0)
	model:SetAttribute("WanderT1", t1)
end

--==============================================================================
-- PARK IT WHERE IT NOW STANDS
--
-- A degenerate leg -- nowhere to nowhere, already finished. Published after a
-- rebuild instead of simply clearing the attributes, because clearing them only
-- tells a client to STOP; it does not tell it where the server thinks the
-- creature is.
--
-- That gap was visible. On a shrink the server pulls a creature that no longer
-- fits back onto the smaller plot, while every client carries on drawing it at
-- the old spot until the next leg arrives half a second later -- and then it
-- jumps. Measured before this: 17.3 studs on the server in the rebuild frame,
-- and up to 72 studs of client-side disagreement across the same upgrade.
--
-- Parking closes it in the same frame: the record and the picture move together.
--==============================================================================
local function parkAt(entry: Planted, atW: Vector3, srvNow: number)
	entry.legFrom = nil
	entry.legTo = nil
	entry.legStart = nil
	entry.legEnd = nil
	entry.restUntil = srvNow
	publishLeg(entry, atW, atW, srvNow - 0.1, srvNow)
end

--==============================================================================
-- ONE STEP OF THE WANDER, FOR ONE PLOT
--
-- Called on the service's existing tick. Between legs this does nothing at all
-- for a plant: it looks at one number and moves on.
--
-- WHERE TO GO is PlantWander.Choose: a destination between the tier's minimum
-- leg and its reach (SeedData.WanderLadder), along a straight line that stays
-- inside the plot the whole way, preferring wherever nobody else is standing or
-- headed. The region is read off the plot once per step, and only if some plant
-- on it actually needs a new leg.
--==============================================================================
local function stepWander(plot: Model, byPlot: { [number]: Planted }, srvNow: number)
	local owner = PlotService.OwnerOf(plot)
	if not owner then
		return
	end
	local region: PlantWander.Region? = nil
	for _, entry in pairs(byPlot) do
		local model = entry.model
		if entry.stage == CreatureModel.STAGE_GROWN and model and model.Parent then
			local rng = entry.rng
			if not rng then
				-- Seeded off the placement id so a plot restored on join does
				-- not set every creature off on the same tick.
				rng = Random.new(entry.id * 7919 + 13)
				entry.rng = rng
			end

			local arriving = entry.legEnd and srvNow >= entry.legEnd
			if arriving then
				--==========================================================
				-- ARRIVED: COMMIT, THEN REST
				--
				-- This is the only place the saved position moves. A creature
				-- mid-stride has no position worth writing down, and a profile
				-- write per frame is exactly what this design exists to avoid.
				--==========================================================
				entry.offset = entry.legTo or entry.offset
				entry.legEnd = nil
				entry.restUntil = srvNow
					+ SeedData.WanderPause(entry.tier) * rng:NextNumber(0.7, 1.7)
				persist(plot)
			end

			if not entry.legEnd and srvNow >= (entry.restUntil or 0) then
				if not region then
					region = PlantWander.RegionFor(plot)
				end
				local to, how = PlantWander.Choose(region :: PlantWander.Region,
					entry.offset, entry.tier, byPlot :: any, entry.id, rng)
				local fromW = wanderWorld(plot, entry.offset)
				local toW = wanderWorld(plot, to)
				if how == "stay" then
					-- Nowhere on the plot is a walk worth taking from here. Rest
					-- again rather than publish a leg that goes nowhere.
					entry.restUntil = srvNow + SeedData.WanderPause(entry.tier)
				elseif fromW and toW then
					local dist = (toW - fromW).Magnitude
					local t0 = srvNow
					local t1 = t0 + PlantWander.LegSeconds(entry.tier, dist)
					entry.legFrom = entry.offset
					entry.legTo = to
					entry.legStart = t0
					entry.legEnd = t1

					--==================================================
					-- THE ONLY THING THAT CROSSES THE WIRE
					--
					-- World points, so a client needs no plot frame to draw
					-- the walk -- and re-stamped on a resize, because a
					-- rebuilt plot moves the soil these were measured off.
					--==================================================
					publishLeg(entry, fromW, toW, t0, t1)
				end
			end
		end
	end
end

--==============================================================================
-- STOP WALKING, NOW
--
-- Picked up, put away, sold, released, destroyed. Clears the leg AND the
-- attributes, so a client that still holds the model parks it instead of
-- interpolating toward a destination nothing is going to honour.
--==============================================================================
function stopWander(entry: Planted)
	entry.legFrom = nil
	entry.legTo = nil
	entry.legStart = nil
	entry.legEnd = nil
	entry.restUntil = nil
	local model = entry.model
	if model and model.Parent then
		model:SetAttribute("WanderFrom", nil)
		model:SetAttribute("WanderTo", nil)
		model:SetAttribute("WanderT0", nil)
		model:SetAttribute("WanderT1", nil)
	end
end

--==============================================================================
-- MOVING THE SOIL OUT FROM UNDER A LIVING GARDEN
--
-- A plot upgrade rebuilds the bed further from the hub, so the soil part is
-- destroyed and a new one appears at a new CFrame. Every entry's `offset` is
-- SOIL-LOCAL, so doing nothing would teleport the whole garden outward by half
-- the depth change -- the plants would appear to slide backwards as the fence
-- grew past them.
--
-- So the transaction captures each plant's WORLD point first, and rebases the
-- offsets against the new soil afterwards. The models are not recreated and not
-- moved: they are already standing in the right place, and the rebase is only
-- teaching the record where that place is in the new frame.
--
-- THE SERVER'S OFFSETS ARE THE AUTHORITY, never a client animation CFrame.
-- PlantSway pivots these models continuously; reading a live pivot would
-- capture a plant mid-stride and bake its walk into the save.
--==============================================================================
-- Held only between OnResizing and OnResized, which are fired one after the
-- other in the same frame. A plot released mid-resize would leave a stale entry,
-- so OnReleased clears it too.
local carried: { [Model]: { [number]: Vector3 } } = {}

function PlantService.CaptureWorld(plot: Model): { [number]: Vector3 }
	local out: { [number]: Vector3 } = {}
	local byPlot = growing[plot]
	local soil = soilOf(plot)
	if not (byPlot and soil) then
		return out
	end
	--==========================================================================
	-- A WALKING CREATURE IS COMMITTED WHERE IT STANDS, NOT WHERE IT SET OFF
	--
	-- Without this a resize captured the START of whatever leg was in progress,
	-- so a creature halfway across its plot was rebased as though it had never
	-- left -- and the client, still interpolating its own copy of the leg, drew
	-- it somewhere else entirely. Measured: after a Level 5 -> 1 shrink the
	-- garden did not visibly move at all, because the records had been dragged
	-- into the small bed while every model carried on walking the old route.
	--
	-- Committing first makes the capture the truth, and stopWander below makes
	-- the client agree with it.
	--==========================================================================
	local srvNow = Workspace:GetServerTimeNow()
	for id, entry in pairs(byPlot) do
		entry.offset = currentOffset(entry, srvNow)
		out[id] = topOf(soil, entry.offset).Position
	end
	return out
end

--==============================================================================
-- PUT THEM BACK WHERE THEY WERE, IN THE NEW FRAME
--
-- On a GROW -- which is every upgrade, and the only thing the shop can do --
-- the clamp is a no-op and not one model moves. The plants are already standing
-- in the right place; all that changes is the frame their offsets are measured
-- in, so the record follows the soil and the world is untouched.
--
-- A SHRINK is the other direction, and it is the one that needs care. The new
-- bed can be shorter than where a plant is standing, and then the clamp pulls
-- its OFFSET onto the soil while the MODEL stays out in the field. Measured on
-- a live L5 -> L1: two of five plants ended up 23 studs behind the new back
-- edge, record and model disagreeing, and the plant would have jumped forward
-- on the owner's next login with nothing to explain it.
--
-- So a plant the clamp actually moved is moved for real. Its facing is kept --
-- a garden somebody arranged should not spin because the bed changed size --
-- and only the position is rewritten.
--
-- Nothing in normal play shrinks an occupied plot: the shop only sells upward,
-- and a released plot is emptied before it is reset. This is for the debug
-- action, for a rolled-back purchase, and for whatever wants to shrink a bed
-- later without having to rediscover why it broke.
--==============================================================================
function PlantService.RebaseTo(plot: Model, captured: { [number]: Vector3 }): number
	local byPlot = growing[plot]
	local soil = soilOf(plot)
	if not (byPlot and soil) then
		return 0
	end
	local rebased, relocated = 0, 0
	for id, world in pairs(captured) do
		local entry = byPlot[id]
		if entry then
			entry.offset = clampToPlotRegion(plot,
				plotOffsetOf(plot, world) or Vector3.zero)
			rebased += 1

			local target = topOf(soil, entry.offset).Position
			if (target - world).Magnitude > 0.01 then
				local model = entry.model
				if model and model.Parent then
					-- Position only. The rotation it is standing at already
					-- carries the plot's bearing and the plant's own facing.
					model:PivotTo(CFrame.new(target) * model:GetPivot().Rotation)
					relocated += 1
				end
			end
		end
	end
	--==========================================================================
	-- NO LEG SURVIVES A REBUILD, AND EVERY CREATURE IS TOLD WHERE IT IS
	--
	-- The published leg is a pair of WORLD points and the plot has just moved
	-- underneath them, so none of them may stand. But clearing alone leaves each
	-- client holding its own last picture, which after a shrink is a creature
	-- standing somewhere its plot no longer reaches.
	--
	-- So every entry is PARKED at its rebased position instead. One publish per
	-- creature per rebuild -- the same cost as clearing -- and the picture and
	-- the record agree in the frame the plot changed rather than half a second
	-- later.
	--==========================================================================
	local parkNow = Workspace:GetServerTimeNow()
	for _, entry in pairs(byPlot) do
		local atW = wanderWorld(plot, entry.offset)
		if atW then
			parkAt(entry, atW, parkNow)
		else
			stopWander(entry)
		end
		-- The soil moved; the marker goes where the record now says the plant is.
		placeAnchor(entry, parkNow)
	end
	sweepAnchors(plot)
	if rebased > 0 then
		persist(plot)
	end
	if relocated > 0 then
		log(string.format("%s shrank under %d plant(s); they were moved onto the new bed.",
			plot.Name, relocated))
	end
	return rebased
end

-- What the plot may hold, and what is standing in it. Public because
-- PlotUpgradeService and the HUD both have to answer "is this full" and neither
-- may re-derive it.
function PlantService.CapacityOf(plot: Model): number
	return capacityOf(plot)
end

function PlantService.CountIn(plot: Model): number
	return countIn(plot)
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
			dropAnchor(entry)
		end
		growing[plot] = nil
	end
	table.clear(nextId)
	table.clear(wanted)
	table.clear(lastOffer)
	warnedNoProduct = false
end

function PlantService.Start()
	PlotService.OnAssigned(function(player, plot)
		restore(player, plot)
	end)
	PlotService.OnReleased(function(_player, plot)
		-- PlotService clears the Plants folder itself right after this; all that
		-- is needed here is to stop tracking what was in it. The anchors are
		-- dropped explicitly rather than trusted to that clear.
		for _, entry in pairs(growing[plot] or {}) do
			dropAnchor(entry)
		end
		growing[plot] = nil
		nextId[plot] = nil
		carried[plot] = nil
	end)
	-- A note about which pod to hatch means nothing once its writer has gone: a
	-- receipt for somebody who is not here is never processed (StoreService), and
	-- one re-delivered after they rejoin falls back to their longest wait.
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(leaving)
		wanted[leaving.UserId] = nil
		lastOffer[leaving.UserId] = nil
	end))

	--==========================================================================
	-- AN UPGRADE MOVES THE SOIL OUT FROM UNDER THE GARDEN
	--
	-- Plant offsets are stored SOIL-LOCAL, and a bigger plot puts its soil at a
	-- new CFrame further from the hub. Left alone, every plant in the bed would
	-- appear to slide backwards by half the depth change the instant the player
	-- bought the upgrade -- the plot growing out from under them.
	--
	-- So the world points are taken while the old soil still stands, and the
	-- offsets are rebased once the new one is in place. The plant MODELS are
	-- never touched: they are already standing in the right spot in the world,
	-- and what changes is only the frame the record measures them in.
	--
	-- Registered as PlotService listeners rather than called from the upgrade
	-- service, so that EVERY resize is covered -- including any future one that
	-- has nothing to do with the shop.
	--==========================================================================
	PlotService.OnResizing(function(_player, plot)
		carried[plot] = PlantService.CaptureWorld(plot)
	end)
	PlotService.OnResized(function(_player, plot)
		local snapshot = carried[plot]
		carried[plot] = nil
		if snapshot then
			PlantService.RebaseTo(plot, snapshot)
		end
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
		-- The same channel carries the reveal outward; see announceReveal.
		revealChannel = channel
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
			local srvNow = Workspace:GetServerTimeNow()
			for plot, byPlot in pairs(growing) do
				if not plot.Parent then
					growing[plot] = nil
					nextId[plot] = nil
				else
					for _, entry in pairs(byPlot) do
						if isReady(entry, now) then
							-- Also takes the Instant Hatch prompt off.
							if not entry.prompt then
								attachHatchPrompt(entry)
							end
						elseif entry.stage == CreatureModel.STAGE_POD then
							-- Only builds when one is missing: a pod whose
							-- model was rebuilt lost its prompt with it.
							attachInstantPrompt(entry)
						end
					end
					-- The garden takes a step. Pods are skipped inside.
					stepWander(plot, byPlot, srvNow)
					-- And every pickup marker follows it, on this same tick.
					trackAnchors(byPlot, srvNow)
				end
			end
		end
	end)

	log(string.format(
		"Ready. Click your soil to plant; hold E on a ready pod for %.1fs to hatch it.",
		HATCH_HOLD))
	if not INSTANT_ITEM then
		warn("[Seed/PlantService] GameConfig.Store.InWorld has no \"hatch\" product, "
			.. "so no pod offers Instant Hatch.")
	elseif instantProductId() <= 0 then
		log(string.format("Instant Hatch (%d Robux) is HIDDEN on every tier: its "
			.. "Developer Product id is still 0. Nobody sees a dead offer.",
			INSTANT_ITEM.robux))
	else
		log(string.format("Instant Hatch is live on all %d tiers at %d Robux (product %d).",
			SeedData.TierCount, INSTANT_ITEM.robux, instantProductId()))
	end
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
