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
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
-- When a hatch's roll runs and when its plant may be shown: arithmetic only.
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
-- The starter pod and the first catch's words (2026-10-08).
local FirstMinute = require(Shared:WaitForChild("FirstMinute"))
-- The verb a server-worded notice rides on (Notice.ServerNotice).
local Notice = require(Shared:WaitForChild("Notice"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local PlantWander = require(script.Parent:WaitForChild("PlantWander"))
-- What frame a SAVED garden's X/Z are in, and plot 6's at Levels 6-7: arithmetic only.
local GardenFrame = require(script.Parent:WaitForChild("GardenFrame"))
-- What MY PLANTS' EQUIP BEST ranks and where its newcomers stand: arithmetic only.
local GardenPlan = require(Shared:WaitForChild("GardenPlan"))

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
	-- A GROWN creature's item id (2026-10-04, MY PLANTS): the id its row had in
	-- the Bag, kept while it stands here and handed back with it, so its hotbar
	-- shortcut and its heart are still its own. nil for a pod, and for a plant
	-- saved before ids were kept in the ground.
	item: string?,
	-- THE STARTER POD (2026-10-08, FirstMinute): true on the one pod the game
	-- planted for a brand-new profile, while it is still a pod. It carries no
	-- prompt -- it hatches by itself, in place (hatchStarter) -- and is nil
	-- from then on: the plant it becomes is an ordinary one. Not saved; a
	-- restore knows it again by the profile's StarterAt.
	starter: boolean?,
}

-- plot -> placementId -> Planted
local growing: { [Model]: { [number]: Planted } } = {}
local nextId: { [Model]: number } = {}
--==============================================================================
-- A BED IS NOT SAVED UNTIL ITS GARDEN HAS BEEN PUT BACK
--
-- plot -> the owner whose saved garden restore() has put into it. Until that
-- is true, persist() writes nothing and PlaceAt plants nothing: a bed nobody
-- has restored yet is not "an empty garden", it is a garden that has not
-- arrived, and saving it would erase the real one -- which is how the owner's
-- garden was lost on 2026-09-15, and what a 38 s load past restore's old 30 s
-- deadline would have done again. Cleared when the plot is released.
--==============================================================================
local restoredFor: { [Model]: Player } = {}
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
local MY_PLANTS = PLANTING.MyPlants
local INSTANT = PLANTING.InstantHatch
-- Pods hatch in the Bag (2026-10-09): its verbs, timings and words.
local BAG = GameConfig.HatchInBag

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
-- is broken. (A saved Instant Hatch is the exception: it sells nothing.) THIS IS A READINESS GATE, NOT A TIER GATE: with a real id, every
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
-- TWO OF THEM NOW REACH THE PLAYER TOO (2026-09-23): out of reach and a full
-- plot, the two a player can fix, go back as a toast from the click's handler
-- in Start. The log line below is unchanged and still covers all of them.
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
-- accidentally start allowing what it used to refuse. The code rides back out
-- beside it, so the click's handler can tell the player the two reasons that
-- are theirs to fix (ActionRefusal.fromPlacement) and say nothing about the rest.
local function refuse(player: Player, code: string): (boolean, string)
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
	return false, code
end

--==============================================================================
-- PLANT STORAGE FULL (2026-09-29)
--
-- The owner's decision: with the saved record full, "refuse the hatch and leave
-- the pod planted and ready until the player makes room", and say so with "a
-- clear, non-spamming" line.
--
-- CarryService refuses (GiveHatched, HeldRoom); this only SAYS it, after the
-- refusal, to the player who asked. ONE LINE PER PLAYER EVERY FEW SECONDS,
-- whichever door it came from -- a held prompt, the Instant Hatch key, a
-- receipt Roblox delivers again -- on top of the toast's own rule that a line
-- already on the screen only stays up longer.
--
-- `code` is ActionRefusal's: STORAGE_FULL for a hatch that cost nothing, a
-- pickup and the Instant Hatch key; STORAGE_FULL_READY for a receipt that made
-- its pod ready instead; STORAGE_FULL_CREDIT for a receipt that found no wait
-- left to end and was kept as a credit.
--
-- `always` is for the one line that is the answer to a PURCHASE: it is said
-- whatever was said a moment ago, because somebody who has just paid is told
-- what their money did.
--
-- `door` is what was refused, for the server log ("hatch refused", "pickup
-- refused"). The log counts the SAVED record, as the limit does, and names a
-- pod in the arms apart: that pod keeps a place without being on the record
-- yet (CarryService.HeldRoom), so 24 saved and a pod carried reads "24/24
-- saved, and a pod in the arms" rather than 25/24, and 23 saved and a pod
-- carried shows why 23 is full. No door, no log line: the caller has written
-- its own.
--==============================================================================
local STORAGE_QUIET_SECONDS = 2
local lastStorageNotice: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function storageFull(player: Player, code: string, door: string?, always: boolean?)
	local now = os.clock()
	if always ~= true and now - (lastStorageNotice[player] or -math.huge) < STORAGE_QUIET_SECONDS then
		return
	end
	lastStorageNotice[player] = now
	if door then
		-- The PLANT rows (2026-10-09): pods have a room of their own, and a pod in
		-- the arms keeps its place there, not here.
		local profile = PlayerDataService.Get(player)
		local saved = 0
		if profile and type(profile.Held) == "table" then
			for _, row in ipairs(profile.Held) do
				if type(row) == "table" and row.Hatched == true then
					saved += 1
				end
			end
		end
		log(string.format("%s: %s, plant storage full (%d/%d plants saved).", player.Name, door, saved,
			GameConfig.Save.MaxHeld))
	end
	ActionRefusal.send(player, code)
end

-- How many Instant Hatches this player has saved for later (see keepForLater).
local function creditsOf(player: Player): number
	local profile = PlayerDataService.Get(player)
	local n = if profile then tonumber(profile.InstantCredits) else nil
	return if n and n > 0 then math.floor(n) else 0
end

-- The count on the player, for the Bag's Instant Hatch button (2026-10-09): it
-- says FREE while a credit is saved. Told whenever a credit is granted or spent
-- (refreshInstantPrompts) and when the garden is restored. A spec's stand-in
-- player is a table and is left alone.
local function publishCredits(player: any)
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute(BAG.CreditsAttribute, creditsOf(player))
	end
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
	-- A secret POD stands at the fixed facing whatever its record says: face,
	-- the narrow side, to the gate (GameConfig.Secret.PodFacing, the owner's
	-- option 2). Which way it stands only -- never where it may. Every replayed
	-- pod (a species with a Pod form: the Secrets' and, from 2026-10-02, the
	-- Rain event's, whose Pod 3 has an eye; from 2026-10-05 its second family's
	-- seven sized shells) stands the same way.
	local facing = if entry.stage == CreatureModel.STAGE_POD and SeedData.PodFormOf(entry.species, entry.tier) ~= nil
		then GameConfig.Secret.PodFacing
		else entry.facing
	return CFrame.new(base.Position) * CFrame.Angles(0, math.rad(180), 0)
		* entry.plot:GetPivot().Rotation
		* CFrame.Angles(0, facing, 0)
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
	-- Which item it is (MY PLANTS): read by the panel, never trusted by the server.
	model:SetAttribute(GameConfig.Attributes.ItemId, entry.item)
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
--
-- X and Z IN THE FRONT SHAPE'S FRAME (2026-10-07): the same numbers as the
-- live offset on every plot at Levels 1-5 and on plots 1-5 at every level;
-- plot 6 at Levels 6-7 is another shape and converts (GardenFrame), so the
-- garden means the same ground whichever plot its owner is given next.
--==============================================================================
local function record(plot: Model): { any }
	local list = {}
	local byPlot = growing[plot]
	if byPlot then
		-- The level the soil was BUILT at (MapService stamps it with the
		-- geometry): the frame the live offsets are in.
		local level = tonumber(plot:GetAttribute("Level"))
		local plotId = tonumber(plot:GetAttribute(GameConfig.Attributes.PlotId))
		for _, entry in pairs(byPlot) do
			local saved = GardenFrame.ToSaved(level, plotId, entry.offset)
			table.insert(list, {
				SpeciesId = entry.species.Id,
				PlantedAt = entry.plantedAt,
				-- Saved, so a rejoin restores the same deadline rather than
				-- starting the wait again or applying today's ladder to it.
				HatchAt = entry.hatchAt,
				Tier = entry.tier,
				X = saved.X,
				Z = saved.Z,
				Stage = entry.stage,
				Facing = entry.facing,
				Item = if entry.stage == CreatureModel.STAGE_GROWN then entry.item else nil,
			})
		end
	end
	return list
end

-- Answers whether the garden was written: a purchase that changes a pod is not
-- acknowledged on a garden that was not (see InstantHatch).
local function persisted(plot: Model): boolean
	local owner = PlotService.OwnerOf(plot)
	-- Only once this owner's garden is in the bed -- see restoredFor.
	if owner and restoredFor[plot] == owner then
		return PlayerDataService.SetPlants(owner, record(plot)) == true
	end
	return false
end

local function persist(plot: Model)
	persisted(plot)
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

local hatch: (Player, Planted, boolean?) -> (boolean, string?)
local pickUp: (Player, Planted, boolean?) -> (boolean, string?)

local function attachHatchPrompt(entry: Planted)
	-- The starter pod hatches itself (hatchStarter): no prompt, free or paid.
	if entry.starter then
		return
	end
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
		PlantService.HatchByHand(player, entry.plot, entry.id)
	end))
end

--==============================================================================
-- THE HELD PROMPT, BY NAME
--
-- Everything the prompt above does when its hold completes, and the only thing
-- that calls it. It has a name so that a spec can do what the engine does -- a
-- ProximityPrompt cannot be triggered from a script -- and it is no way round
-- anything: hatch() makes every check it has always made, on whoever is named.
--
-- REFUSED FOR ROOM (2026-09-29), the pod stays as it is, planted and ready, and
-- the player is told what makes room. Every other refusal is as silent as it
-- was. The reason rides back beside the answer.
--==============================================================================
function PlantService.HatchByHand(player: Player, plot: Model, placementId: number): (boolean, string?)
	local byPlot = growing[plot]
	local entry = if byPlot then byPlot[placementId] else nil
	if not entry then
		return false, nil
	end
	local hatched, why = hatch(player, entry)
	if not hatched and why == "STORAGE_FULL" then
		storageFull(player, "STORAGE_FULL", "hatch refused")
	end
	return hatched, why
end

--==============================================================================
-- INSTANT HATCH
--
-- A pod that is still counting down carries a second prompt: F, INSTANT HATCH,
-- and a Robux price. Pressing it only ASKS Roblox for the purchase. Nothing
-- happens to the pod until the receipt reaches StoreService, which calls
-- InstantHatch below -- and that runs the same hatch() as the free prompt,
-- without the clock. The one exception: a player holding a saved Instant Hatch
-- (2026-09-30) sees no price, and the press itself hatches the pod.
--
-- THE SERVER OPENS THE DIALOG. MarketplaceService lets a server prompt a
-- purchase on a player's screen, so there is no remote here and nothing a client
-- can send. The press arrives as the prompt's Triggered, engine-stamped with who
-- pressed it; everything after that is decided on this side.
--
--==============================================================================
-- WHICH POD A RECEIPT HATCHES: THE ONE THAT WAS PRESSED, OR NONE
--
-- A receipt names a player and a product, never a pod. So the pod is written
-- down when the dialog opens -- its plot, its id and the planted pod itself --
-- and the receipt reads the note back. The owner's decision (2026-09-30): "the
-- purchase is for the pod the player pressed. If that pod becomes ready while
-- the purchase dialog is open, save one Instant Hatch credit -- even if other
-- pods are still growing. Do not use the purchase to hatch an already-ready
-- pod or silently switch it to another pod. If the selected pod is gone or its
-- target cannot be established safely, save a credit."
--
--   1. The pod they pressed hatches if it is still THAT pod -- the same planted
--      pod in their own plot, not a later one given its id after a rebuild --
--      and it is still counting down. With plant storage full it is made
--      ready instead (option A, unchanged).
--   2. Anything else keeps the purchase as ONE saved Instant Hatch
--      (keepForLater): no note (a receipt Roblox delivers again after a rejoin
--      or a crash), no garden in the world yet, the pod gone, or its wait
--      already over. No other pod is ever picked in its place.
--==============================================================================
-- UserId -> the pod that player last opened the purchase dialog for, and the
-- Planted it was then. Keyed by id rather than Player, and cleared when they
-- leave. A pod in the BAG (2026-10-09) is named by its item id instead
-- (`bagItem`): the receipt hatches that pod, still in the Bag and still
-- growing, or keeps the purchase as a credit -- the same rule, one door over.
type Wanted = { plot: Model?, id: number?, entry: Planted?, bagItem: string? }
local wanted: { [number]: Wanted } = {}
-- UserId -> os.clock() of the last dialog opened for them.
local lastOffer: { [number]: number } = {}
-- Said once per server, not once per press.
local warnedNoProduct = false
-- What opens the dialog, replaced only by a Studio test (usePrompt), so a Play
-- harness can press the real Instant Hatch key and mock the receipt without a
-- purchase dialog on anybody's screen (2026-09-30).
local promptFn: ((Player, number) -> ())? = nil

local function attachInstantPrompt(entry: Planted)
	local model = entry.model
	local handle = if model then model.PrimaryPart else nil
	if not (model and handle and INSTANT_ITEM) or entry.stage ~= CreatureModel.STAGE_POD then
		return
	end
	-- Nothing is sold to skip a free 30 s gift that hatches itself.
	if entry.starter then
		return
	end
	-- No product, no prompt: a dead button is worse than no button. Every tier is
	-- offered once an id exists; nothing here looks at the tier.
	--
	-- EXCEPT FOR A SAVED INSTANT HATCH (2026-09-30). An owner holding a credit
	-- is shown the free prompt whatever the product's state: that press opens no
	-- dialog, and a credit already paid for must not be stranded by the product
	-- going off sale. Found in review.
	local owner = PlotService.OwnerOf(entry.plot)
	local saved = owner ~= nil and creditsOf(owner) > 0
	if instantProductId() <= 0 and not saved then
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
	-- Offered to the owner only. That is courtesy -- PromptUI does not draw it
	-- for anybody else -- and OfferInstantHatch refuses a stranger either way.
	if owner then
		prompt:SetAttribute("ReservedFor", owner.UserId)
	end
	--==========================================================================
	-- A SAVED INSTANT HATCH SHOWS NO PRICE (2026-09-30)
	--
	-- An owner holding a credit (see keepForLater) is not charged by the next
	-- press, so the prompt says so: no price capsule -- PromptUI draws one only
	-- for a Robux attribute -- and the words for a free one. It is made again
	-- when a credit is granted or spent (refreshInstantPrompts).
	--==========================================================================
	if saved then
		prompt.ActionText = INSTANT.SavedActionText
		prompt:SetAttribute("SavedHatch", true)
	else
		-- That the prompt sells something, at the manifest's list price.
		-- PromptUI does NOT print this number: Roblox prices products by
		-- region, so the capsule shows what Roblox tells the client this player
		-- pays for RobuxProduct.
		prompt:SetAttribute("Robux", INSTANT_ITEM.robux)
		prompt:SetAttribute("RobuxProduct", instantProductId())
	end
	-- Drawn above the pod's HATCHING label rather than on top of it.
	prompt:SetAttribute("OverPodLabel", true)
	prompt.Parent = handle
	entry.instant = prompt

	-- Not kept in serviceConnections: the connection is disconnected when the
	-- prompt is destroyed, and every planted pod gets one of these.
	prompt.Triggered:Connect(function(player)
		PlantService.OfferInstantHatch(player, entry.plot, entry.id)
	end)
end

--==============================================================================
-- EVERY INSTANT HATCH PROMPT ON A PLAYER'S PODS, MADE AGAIN (2026-09-30)
--
-- A credit granted or spent changes whether the prompt shows a price (above).
-- Made again rather than edited: the engine hides the old prompt and shows the
-- new one, so the player sees the change at once, not the next time they walk
-- up to the pod.
--==============================================================================
local function refreshInstantPrompts(player: Player)
	-- And the Bag's Instant Hatch, which reads the count off the player.
	publishCredits(player)
	local plot = PlotService.PlotOf(player)
	local byPlot = if plot then growing[plot] else nil
	if not byPlot then
		return
	end
	for _, entry in pairs(byPlot) do
		if entry.instant then
			entry.instant:Destroy()
			entry.instant = nil
			attachInstantPrompt(entry)
		end
	end
end

--==============================================================================
-- A PURCHASE KEPT FOR LATER (2026-09-30)
--
-- A receipt that cannot hatch the pod it was bought for -- no note naming one,
-- no garden in the world yet, that pod gone, or its wait already over (see
-- WHICH POD A RECEIPT HATCHES) -- is
-- kept as ONE saved Instant Hatch, a credit, which the next hatch that succeeds
-- spends (OfferInstantHatch). The owner's decisions: "save one credit for that
-- purchase, acknowledge the receipt only after the credit is safely saved, and
-- make sure a duplicate receipt can't add a second credit", and for no pod at
-- all, "grant one saved Instant Hatch credit. Use the same safe
-- receipt-and-credit handling as the full-storage case".
--
-- So one credit is added with no yield before StoreService puts the purchase in
-- its ledger -- the two reach the same save or neither does -- and StoreService
-- acknowledges only once that save has landed. A second delivery of the same
-- receipt is stopped by the ledger before it reaches this; a separate purchase
-- has a receipt of its own, and a credit of its own. A profile that can never be
-- saved is given none, as it is given no bought spin: false, and the receipt
-- stays open. The caller says what happened; `why` is for the log.
--==============================================================================
local function keepForLater(player: Player, why: string): boolean
	if not PlayerDataService.IsPersistent(player) then
		return false
	end
	local held = PlayerDataService.AddInstantCredits(player, 1)
	if held == nil then
		return false
	end
	wanted[player.UserId] = nil
	refreshInstantPrompts(player)
	log(string.format("%s bought an instant hatch with %s: kept for later (%d saved).", player.Name, why, held))
	return true
end

--==============================================================================
-- THE PRESS: CHECK, WRITE THE NOTE, OPEN THE DIALOG
--
-- Takes the plot as well as the id because placement ids are only unique inside
-- a plot. Looking the id up in the PRESSER's plot would let a stranger's press
-- on pod 3 here open a dialog for their own pod 3 at home.
--==============================================================================
-- A Studio test answers the purchase dialog here instead of opening one; nil
-- puts the real one back. Studio only, as WheelService.usePrompt is. It changes
-- nothing else the press does: the checks, the note and the rate limit are the
-- same, and a receipt is still only what StoreService is handed.
function PlantService.usePrompt(fn: ((Player, number) -> ())?): boolean
	if not game:GetService("RunService"):IsStudio() then
		return false
	end
	promptFn = fn
	return true
end

--==============================================================================
-- A STUDIO TEST'S READY POD (2026-10-02): the test-only timestamp override the
-- owner asked for in place of ever shortening a production wait. Ends the wait
-- of every unhatched pod in this player's garden -- the same three writes the
-- storage-full instant hatch makes: the deadline, the save, the prompt -- and
-- answers how many. Studio only; nothing in a live server calls it, and no
-- remote reaches it.
--==============================================================================
function PlantService.DebugReady(player: Player): number
	if not game:GetService("RunService"):IsStudio() then
		return 0
	end
	local now = os.time()
	local count = 0
	for plot, byPlot in pairs(growing) do
		if PlotService.OwnerOf(plot) == player then
			for _, entry in pairs(byPlot) do
				if entry.stage == CreatureModel.STAGE_POD and not isReady(entry, now) then
					entry.hatchAt = now
					if entry.model then
						entry.model:SetAttribute("HatchAt", entry.hatchAt)
					end
					attachHatchPrompt(entry)
					count += 1
				end
			end
			if count > 0 then
				persisted(plot)
			end
		end
	end
	-- And every growing pod in their Bag (2026-10-09), row and Tool together.
	local profile = PlayerDataService.Get(player)
	if profile and type(profile.Held) == "table" then
		local items: { string } = {}
		for _, row in ipairs(profile.Held) do
			if type(row) == "table" and row.Hatched ~= true and type(row.Item) == "string"
				and (tonumber(row.HatchAt) or 0) > now then
				table.insert(items, row.Item)
			end
		end
		for _, item in ipairs(items) do
			if CarryService.SetPodDeadline(player, item, now) then
				count += 1
			end
		end
	end
	return count
end

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
	-- The starter pod is never offered one: it hatches itself.
	if entry.stage ~= CreatureModel.STAGE_POD or isReady(entry, os.time()) or entry.starter then
		return false
	end
	--==========================================================================
	-- NO ROOM, NO DIALOG (2026-09-29)
	--
	-- A hatch into a full record is refused, so a purchase of one is not
	-- offered: nobody is asked for Robux for something the game would then
	-- decline to do. Counted where the hatch itself counts (HeldRoom). A player
	-- with no record yet is not offered one either, and is told nothing: their
	-- save is still arriving, and a receipt would not be honoured until it has.
	--==========================================================================
	local room, _, known = CarryService.HeldRoom(player)
	if not known then
		return false
	end
	if room < 1 then
		storageFull(player, "STORAGE_FULL", "Instant Hatch not offered")
		return false
	end
	--==========================================================================
	-- A SAVED INSTANT HATCH IS SPENT, NOT SOLD (2026-09-30)
	--
	-- A player holding a credit (see keepForLater) is not asked for Robux: the
	-- press hatches this pod now, and the credit is taken only once the hatch
	-- has succeeded -- the owner's rule, "The credit should only be used when
	-- an eligible hatch actually succeeds." Eligible is everything checked
	-- above: their own pod, still counting down, a record with room. A hatch
	-- refused after all (the record will not take the row, the pod has gone)
	-- leaves the credit where it was. No note and no dialog: there is no
	-- receipt to wait for -- and so no product either: a credit is spent
	-- whatever the product's state, so going off sale strands none (found in
	-- review, 2026-09-30). The product is asked about below, for a sale.
	--==========================================================================
	if creditsOf(player) > 0 then
		local hatched = hatch(player, entry, true)
		if not hatched then
			return false
		end
		local left = PlayerDataService.AddInstantCredits(player, -1)
		if left == nil then
			warn(string.format("[Seed/PlantService] %s: a saved Instant Hatch hatched a pod and the credit "
				.. "could not be taken.", player.Name))
		end
		refreshInstantPrompts(player)
		log(string.format("%s spent a saved instant hatch on a %d tier pod (%s left).", player.Name,
			entry.tier, tostring(left)))
		ActionRefusal.send(player, "INSTANT_CREDIT_USED")
		return true
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
	wanted[player.UserId] = { plot = plot, id = placementId, entry = entry }
	local ok, err = pcall(function()
		local open = promptFn
		if open then
			open(player, productId)
		else
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end)
	if not ok then
		warn(string.format("[Seed/PlantService] Instant Hatch dialog for %s failed: %s",
			player.Name, tostring(err)))
		return false
	end
	return true
end

--==============================================================================
-- THE RECEIPT: THE POD THAT WAS PAID FOR, OR A CREDIT
--
-- Called by StoreService and nothing else, only once a receipt for the Instant
-- Hatch product has arrived. Returns whether the purchase was delivered -- the
-- pressed pod hatched, or made ready (plant storage full), or the purchase kept
-- as a credit (see WHICH POD A RECEIPT HATCHES, and keepForLater); false
-- leaves the receipt unacknowledged so Roblox tries again. A receipt already
-- fulfilled never gets this far: StoreService's ledger answers it first.
--==============================================================================
-- The receipt for a pod in the Bag (2026-10-09); defined with the Bag's hatch.
local instantBagReceipt: (Player, string) -> boolean

function PlantService.InstantHatch(player: Player): boolean
	local plot = PlotService.PlotOf(player)
	local byPlot = if plot then growing[plot] else nil
	local note = wanted[player.UserId]
	local now = os.time()
	-- A pod in the Bag was pressed (2026-10-09): that pod, or a credit.
	if note and note.bagItem then
		return instantBagReceipt(player, note.bagItem)
	end
	local entry: Planted? = nil
	if note and plot and byPlot and note.plot == plot then
		local named = if note.id then byPlot[note.id] else nil
		if named ~= nil and named == note.entry and named.stage == CreatureModel.STAGE_POD then
			entry = named
		end
	end
	if not entry or isReady(entry, now) then
		--======================================================================
		-- KEPT FOR LATER, AND SAID FOR WHAT IS IN THE GARDEN NOW
		--
		-- `why` is for the log. The line the player sees is picked by what they
		-- can do next: there is no pod to hatch; storage is full, so room comes
		-- first; a pod is ready, and hatches free; or pods are still growing,
		-- and the saved Instant Hatch will hatch any one of them.
		--======================================================================
		local why = if not (plot and byPlot) then "no garden in the world yet"
			elseif entry then "the pod it was bought for already ready"
			elseif note then "the pod it was bought for gone"
			else "no pod named by the purchase"
		if not keepForLater(player, why) then
			return false
		end
		local unhatched, waiting = false, false
		if byPlot then
			for _, candidate in pairs(byPlot) do
				if candidate.stage == CreatureModel.STAGE_POD then
					unhatched = true
					if not isReady(candidate, now) then
						waiting = true
					end
				end
			end
		end
		-- And the Bag's pods (2026-10-09), where every new pod grows now.
		local profile = PlayerDataService.Get(player)
		if profile and type(profile.Held) == "table" then
			for _, row in ipairs(profile.Held) do
				if type(row) == "table" and row.Hatched ~= true then
					unhatched = true
					if now < (tonumber(row.HatchAt) or 0) then
						waiting = true
					end
				end
			end
		end
		if not unhatched then
			ActionRefusal.send(player, "INSTANT_CREDIT_NO_POD")
		elseif CarryService.HeldRoom(player) < 1 then
			-- No door: keepForLater's line is this one's log.
			storageFull(player, "STORAGE_FULL_CREDIT", nil, true)
		elseif entry or not waiting then
			ActionRefusal.send(player, "INSTANT_CREDIT_READY")
		else
			ActionRefusal.send(player, "INSTANT_CREDIT_SAVED")
		end
		return true
	end
	local hatched, why = hatch(player, entry, true)
	if not hatched then
		--======================================================================
		-- PAID FOR, AND NO ROOM: THE POD IS MADE READY INSTEAD (2026-09-29)
		--
		-- The dialog is not opened for a full record, so this is the record
		-- filling AFTER it opened, or a receipt Roblox delivers again in a later
		-- session. The hatch is refused like any other, and the pod stays
		-- planted. The owner's decision for what the purchase then does: "the
		-- purchase should make its intended pod ready immediately and persist
		-- that state", the player is told "they can hatch the now-ready pod for
		-- free after making room", and the receipt is acknowledged "only after
		-- that benefit is safely recorded".
		--
		-- So the pod's wait is ended, the garden is written, and only a garden
		-- that WAS written answers true -- StoreService then puts the purchase
		-- in its ledger, saves, and acknowledges once the save has landed. A
		-- garden that could not be written puts the wait back as it was and
		-- answers false: not acknowledged, delivered again.
		--
		-- ONCE, HOWEVER OFTEN THE RECEIPT ARRIVES. A second delivery is stopped
		-- by the ledger before it reaches this, and the ledger entry and the
		-- pod's new deadline are written in the same step with no yield between
		-- them, so no save can hold one without the other.
		--
		-- A pressed pod whose wait is already over never gets here: it was kept
		-- as a credit above, with the storage-full line when storage is full.
		--======================================================================
		if why ~= "STORAGE_FULL" then
			return false
		end
		local was = entry.hatchAt
		entry.hatchAt = now
		if not persisted(entry.plot) then
			entry.hatchAt = was
			return false
		end
		if entry.model then
			entry.model:SetAttribute("HatchAt", entry.hatchAt)
		end
		attachHatchPrompt(entry)
		wanted[player.UserId] = nil
		log(string.format("%s bought an instant hatch with plant storage full: the %d tier pod is ready "
			.. "now, and hatches free once there is room.", player.Name, entry.tier))
		-- No door: the line above is this one's log.
		storageFull(player, "STORAGE_FULL_READY", nil, true)
		return true
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
		-- A part's Transparency does not reach its Textures and Decals (the
		-- owner's pods are studded with textures, 2026-10-09): they fade with it.
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Decal") then
				TweenService:Create(d, TweenInfo.new(fly, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }):Play()
			end
		end
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
		elseif d:IsA("Decal") then
			-- A stud texture (a Decal's kind) fades with its part (2026-10-09).
			TweenService:Create(d, TweenInfo.new(LIFT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }):Play()
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

-- The animation's one message, to every client. The starter pod's reveal is
-- sent through here ALONE: it is a gift the player did not hatch, so it earns
-- nothing a listener pays for a hatch (the hatch bonus) -- see hatchStarter.
local function revealToClients(payload: any)
	local channel = revealChannel
	if channel then
		-- pcall because a cosmetic message is never worth an error inside the
		-- call that just handed somebody a plant.
		pcall(function()
			channel:FireAllClients(HATCH.Action, payload)
		end)
	end
end

local function announceReveal(payload: any)
	for _, fn in ipairs(onRevealed) do
		local ok, err = pcall(fn, payload)
		if not ok then
			warn("[Seed/PlantService] reveal listener failed: " .. tostring(err))
		end
	end
	revealToClients(payload)
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
--   2. the Tool            -- in their Backpack and on their record (Held), and
--                             it is theirs from here
--   3. out of the garden   -- the authoritative table, and the anchor with it
--   4. saved               -- the profile knows before anything is drawn
--   5. Almanac, tutorial   -- and MarkSeen says whether this was a discovery
--   6. the payload         -- read off the pod while it still stands
--   7. the decoration      -- the shell bursts, the clients are told, and the
--                             roll runs where the pod stood (HatchRoll,
--                             2026-09-29)
--
-- NOT ONE YIELD ANYWHERE IN 1 TO 6. No wait, no animation, no remote round trip
-- and no client acknowledgement: a player who disconnects, dies or crashes at
-- any point during step 7 keeps the plant, because the plant was already theirs
-- before step 7 began. Step 7 is three seconds longer than it was; steps 1 to 6
-- are not a moment longer.
--==============================================================================
function hatch(player: Player, entry: Planted, early: boolean?): (boolean, string?)
	local byPlot = growing[entry.plot]
	if not byPlot or byPlot[entry.id] ~= entry then
		return false, nil
	end
	-- Yours. The prompt is drawn for anybody standing close enough, so this is
	-- the check that actually owns the pod.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false, nil
	end
	--==========================================================================
	-- THE CLOCK, UNLESS THE WAIT WAS BOUGHT
	--
	-- `early` comes from InstantHatch alone, and only once a receipt has landed.
	-- It skips the wait and nothing else: the pod still has to be an unhatched
	-- pod in this player's own plot.
	--==========================================================================
	if entry.stage ~= CreatureModel.STAGE_POD then
		return false, nil
	end
	-- The starter pod is nobody's to hatch: it hatches itself, in place, and
	-- into the garden rather than the Bag (hatchStarter).
	if entry.starter then
		return false, nil
	end
	if not early and not isReady(entry, os.time()) then
		return false, nil
	end
	--==========================================================================
	-- THE ROLL IS GIVEN ITS TIME BEFORE ANYTHING IS HANDED OVER (2026-09-29)
	--
	-- When this hatch's plant may be shown: three seconds from now, or now
	-- with the roll switched off. Every hatch has its own; none waits for
	-- another. It decides nothing about WHAT hatched -- `entry.species` and
	-- `entry.tier` were fixed when the pod was made, and nothing below reads
	-- them from anywhere else.
	--==========================================================================
	local now = Workspace:GetServerTimeNow()
	-- NO ROLL FOR THE RAIN EVENT'S PODS (the owner's rule, 2026-10-02): their
	-- creature is revealed and handed over straight away, exactly as a hatch
	-- with the roll switched off -- which every other pod still has on.
	local revealAt = if entry.species.SkipHatchRoll == true then now else HatchRoll.revealAt(now)
	local rolled = math.max(revealAt - now, 0)
	--==========================================================================
	-- THE EQUIP WAITS FOR THE REVEAL, THE TOOL DOES NOT
	--
	-- The Tool is created and owned NOW. Putting it in their hands is held back
	-- until the creature has finished coming up, because a plant in the hands
	-- is the plant named -- and CarryService does the waiting, with its own
	-- guards, because a hand is its department and not this one's.
	--
	-- WITH A ROLL the plant comes up at `revealAt` and takes the rise to do
	-- it. Until `revealAt` the Tool says so itself (its RevealAt attribute),
	-- which is what keeps the hotbar and the Bag from naming it -- and from
	-- that moment the player may take it in their hands themselves: nobody is
	-- made to wait for the hand that is given to them.
	--
	-- WITH IT SWITCHED OFF no attribute is written, and the hand is asked for
	-- after exactly the burst and the rise, as it has been since 2026-09-17.
	--==========================================================================
	local equipAfter = if rolled > 0
		then rolled + HATCH.Reveal.Seconds
		else BURST + HATCH.Reveal.Seconds + (if early then HATCH.Paid.PulseSeconds else 0)
	-- HANDED OVER AND PUT ON THE RECORD IN ONE CALL (the last argument), BEFORE
	-- THE POD LEAVES THE GARDEN. The Backpack's own watcher would write the row
	-- a moment later, after this function has returned -- and not at all while
	-- a body is being replaced. Asked for here, the profile never holds neither
	-- the pod nor the plant (CarryService.RecordHatched).
	--
	-- REFUSED WHEN THE RECORD HAS NO ROOM FOR IT (2026-09-29), before anything
	-- is built, and the reason rides back for the caller to say: the pod is
	-- still in the table, still in the garden, still ready, and nothing below
	-- this line has run.
	local given, why = CarryService.GiveHatched(player, entry.species, entry.tier, equipAfter,
		if rolled > 0 then revealAt else nil, true)
	if not given then
		return false, why
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
	-- TRUE only the first time this record has a hatch (the guide's hatch step;
	-- every load re-derives it from the Almanac, the bag and the garden): what
	-- the hatch bonus names a FIRST hatch rather than a welcome back (2026-10-01).
	local firstHatch = PlayerDataService.RecordTutorial(player, "hatch")
	-- THE FIRST CATCH COMING UP (FirstMinute): the pod taken while `steal` was
	-- not done, at the size it was taken at. True once, and only words ride on it.
	local firstCatch = PlayerDataService.TakeFirstCatch(player, entry.species.Id, entry.tier)

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
		firstHatch = firstHatch == true,
		-- "BIG! Your first catch." over the plant (HatchFX), in its size's word.
		firstCatch = firstCatch == true,
		-- Server time, so every client starts the same animation at the same
		-- moment without being told each frame.
		at = now,
		-- WHEN THE PLANT MAY BE SHOWN (HatchRoll.revealAt), in the same clock:
		-- until then the place where the pod stood turns silhouettes over, for
		-- everybody who can see it. The same as `at` with the roll off.
		revealAt = revealAt,
	})
	if model and model.Parent then
		burst(model, entry.tier)
	end
	return true, nil
end

--==============================================================================
-- THE STARTER POD, ON THE OWNER (2026-10-08; FirstMinute)
--
-- StarterHatchAt on the player while their starter pod is still a pod -- its
-- deadline, os.time() -- and nil otherwise. TutorialUI adds "Your first pod is
-- growing!" to the training steps while it is set. A spec's stand-in owner is
-- a table and is left alone.
--==============================================================================
local function publishStarter(player: any, hatchAt: number?)
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute(GameConfig.Attributes.StarterHatchAt, hatchAt)
	end
end

--==============================================================================
-- THE STARTER POD HATCHES ITSELF, WHERE IT STANDS (2026-10-08; FirstMinute)
--
-- Called by the tick once its 30 s are up. hatch()'s order, with the one
-- difference a gift needs: the creature stays IN THE GARDEN instead of going to
-- the Bag, because a player in their first minute has not been taught to place
-- one yet -- the point is to see it earning.
--
--   1. the guards      -- still the starter, still a pod, still in this garden,
--                         whose owner's garden is restored here
--   2. the plant       -- the same entry becomes the grown creature (Stage 3,
--                         an item id of its own) and is SAVED before anything is
--                         drawn; from here it earns like any other
--   3. the Almanac     -- a discovery is a discovery. No tutorial milestone.
--   4. the decoration  -- the shell bursts, the roll runs where it stood, the
--                         notice lands with the reveal, and the real creature
--                         stands up as the reveal's own fades out
--
-- NOTHING ELSE: no RecordTutorial, no Tool, and no OnRevealed listener -- the
-- hatch bonus belongs to the first hatch the player makes themselves.
-- Answers whether it hatched; a refusal leaves it a ready pod for the next tick.
--==============================================================================
local function hatchStarter(entry: Planted): boolean
	local byPlot = growing[entry.plot]
	if not (entry.starter and byPlot and byPlot[entry.id] == entry)
		or entry.stage ~= CreatureModel.STAGE_POD then
		return false
	end
	local owner = PlotService.OwnerOf(entry.plot)
	if not owner or restoredFor[entry.plot] ~= owner then
		return false
	end
	local item = PlayerDataService.MintItem(owner)
	if not item then
		return false
	end
	local now = Workspace:GetServerTimeNow()
	local revealAt = if entry.species.SkipHatchRoll == true then now else HatchRoll.revealAt(now)
	local rolled = math.max(revealAt - now, 0)

	-- 2. The plant, in the table and on the record, before a frame is drawn.
	stopWander(entry)
	local pod = entry.model
	entry.model = nil
	if entry.prompt then
		entry.prompt:Destroy()
		entry.prompt = nil
	end
	if entry.instant then
		entry.instant:Destroy()
		entry.instant = nil
	end
	dropAnchor(entry)
	entry.starter = nil
	entry.stage = CreatureModel.STAGE_GROWN
	entry.item = item
	persist(entry.plot)
	-- 3. Seen, never recorded.
	local discovered = PlayerDataService.MarkSeen(owner, entry.species.Id)
	publishStarter(owner, nil)
	local income = SeedData.IncomePerSecond(entry.species, entry.tier)
	log(string.format("%s's starter %s hatched by itself in their garden (+$%s/s).",
		tostring((owner :: any).Name), entry.species.Name, GameConfig.compact(income)))

	-- 4. The decoration, exactly as a hatch's, at the spot the pod stood on.
	revealToken += 1
	revealToClients({
		token = revealToken,
		species = entry.species.Id,
		tier = entry.tier,
		rarity = entry.species.Rarity,
		income = income,
		cf = standCF(entry),
		owner = owner,
		paid = false,
		discovery = discovered,
		firstHatch = false,
		starter = true,
		at = now,
		revealAt = revealAt,
	})
	if pod and pod.Parent then
		burst(pod, entry.tier)
	end
	-- When the plant comes up out of the roll (with the roll off: after the
	-- burst), as HatchFX draws it.
	local risen = (if rolled > 0 then rolled else BURST) + HATCH.Reveal.Seconds
	task.delay(risen, function()
		local channel = revealChannel
		if channel then
			-- pcall: a player who left in between is no error worth having.
			pcall(function()
				channel:FireClient(owner :: any, Notice.ServerNotice, {
					title = FirstMinute.HatchedTitle,
					detail = FirstMinute.hatchedDetail(income, GameConfig.compact),
					key = FirstMinute.NoticeKey,
				})
			end)
		end
	end)
	-- The real creature stands up as the reveal's label and figure fade, so the
	-- garden shows one plant, not two. Only if it is still this garden's plant:
	-- a pickup, a release or a second restore in between leaves nothing to show.
	task.delay(risen + HATCH.Label.Seconds + HATCH.Label.FadeSeconds, function()
		local live = growing[entry.plot]
		if live and live[entry.id] == entry and entry.stage == CreatureModel.STAGE_GROWN
			and not entry.model and entry.plot.Parent then
			render(entry)
		end
	end)
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
function pickUp(player: Player, entry: Planted, bagOnly: boolean?): (boolean, string?)
	local byPlot = growing[entry.plot]
	if not byPlot or byPlot[entry.id] ~= entry then
		return false, nil
	end
	-- Yours, and only yours. This is what stops a neighbour walking off with
	-- your garden -- the plant is visible to them, the action is not.
	if PlotService.OwnerOf(entry.plot) ~= player then
		return false, nil
	end
	if entry.stage ~= CreatureModel.STAGE_GROWN then
		return false, nil
	end
	-- Straight into their hands, as it always was: a pickup is not a reveal and
	-- there is nothing to wait for.
	--
	-- HANDED OVER AND RECORDED, OR NEITHER (2026-09-29): with no room on the
	-- saved record the plant used to leave the garden for a bag that would not
	-- remember it, and was gone at the next death or rejoin. The owner's rule:
	-- it "must not hand over an item that cannot be saved. Preserve the item in
	-- its prior safe state" -- so the plant STAYS PLANTED, earning as it was,
	-- and the reason rides back for the caller to say.
	--
	-- AS ITSELF (2026-10-04, MY PLANTS): its own item id goes back on the Tool, so
	-- the row the Bag writes for it is the row it had -- its shortcut and heart
	-- with it. `bagOnly` (the MY PLANTS panel) puts it in the Bag and not in the
	-- hands; the world's PICK UP still hands it over, as it always has.
	local given, why = CarryService.GiveHatched(player, entry.species, entry.tier,
		if bagOnly then -1 else nil, nil, true, entry.item)
	if not given then
		return false, why
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
	return true, nil
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
function PlantService.PickUpById(player: Player, placementId: number): (boolean, string?)
	local plot = PlotService.PlotOf(player)
	if not plot then
		return false, nil
	end
	local byPlot = growing[plot]
	if not byPlot then
		return false, nil
	end
	local entry = byPlot[placementId]
	if not entry then
		return false, nil
	end
	local picked, why = pickUp(player, entry)
	-- Refused for room: the plant stays where it stands, and the player is told
	-- what makes room. Every other refusal is as silent as it was.
	if not picked and why == "STORAGE_FULL" then
		storageFull(player, "STORAGE_FULL", "pickup refused")
	end
	return picked, why
end

--==============================================================================
-- PLANTING
--
-- One entry point for both things that can be in your hands: an unhatched pod,
-- which goes in the ground and starts a clock, and a hatched creature, which
-- goes in the ground already earning. The Tool says which.
--==============================================================================
function PlantService.PlaceAt(player: Player, worldPos: Vector3): (boolean, string?)
	local plot = PlotService.PlotOf(player)
	if not plot then
		-- A player whose profile has not finished loading has no plot either,
		-- and NO_PLOT would send somebody reading PlotService when the answer
		-- is upstream of it. Same refusal either way; different thing to fix.
		local code = if PlayerDataService.IsReady(player) then "NO_PLOT" else "NO_PROFILE"
		return refuse(player, code)
	end
	-- A plot whose saved garden is still on its way: planting here would be
	-- saved as the whole garden. The same refusal as no profile, because that is
	-- what it is waiting for.
	if restoredFor[plot] ~= player then
		return refuse(player, "NO_PROFILE")
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
	-- PODS HATCH IN THE BAG (2026-10-09, the owner's Phase 1)
	--
	-- A pod's wait runs in the Bag from the moment it is banked, and beds hold
	-- plants only, so a pod is never put in the ground: "Pods hatch in your Bag
	-- now" (ActionRefusal POD_IN_BAG, said from the click's handler). One path,
	-- so nobody is confused. Pods planted before this keep their beds and hatch
	-- where they stand.
	--==========================================================================
	if not hatched then
		return refuse(player, "POD")
	end

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

	--==========================================================================
	-- NOTHING ELSE IS ASKED (the owner's placement rule, 2026-10-02)
	--
	-- Every pod, plant and Secret is placed by its BASE: one small circle
	-- (GameConfig.Plant.BaseCircleStuds), the same for all, which the clamp
	-- above has already put on this player's own soil. How far the MODEL
	-- reaches is never asked -- it may overlap other plants, the owner's own
	-- fence, gate, signs and mill, and nothing is refused for that. A base can
	-- never stand on another player's plot, the road or the hub, because the
	-- point was pulled onto one of THIS plot's beds. No spacing rule takes the
	-- old footprint's place.
	--==========================================================================
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
		hatchAt = now + (if hatched then 0 else SeedData.GrowSecondsFor(species, tier)),
		stage = if hatched then CreatureModel.STAGE_GROWN else CreatureModel.STAGE_POD,
		-- Off the placement id, so consecutive plantings come out scattered.
		-- Re-placing a plant you picked up gives it a NEW bearing, which is the
		-- honest answer: you put it down again, facing a different way. A secret
		-- POD is the exception: its face, the narrow side, to the gate (the
		-- owner's option 2; standCF holds it).
		facing = if species.Pod ~= nil and not hatched then GameConfig.Secret.PodFacing else facingFor(id),
		model = nil,
		prompt = nil,
		-- The Tool's own item id, for a creature (MY PLANTS): it is the same item
		-- in the ground, and comes back to the Bag as itself.
		item = if hatched and type(tool:GetAttribute(GameConfig.Attributes.ItemId)) == "string"
			then tool:GetAttribute(GameConfig.Attributes.ItemId) :: string else nil,
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
	-- The guide's `place` (2026-10-09): a PLANT in the garden, after the hatch.
	PlayerDataService.RecordTutorial(player, "place")
	log(string.format("%s planted a %d tier %s.", player.Name, tier, species.Name))
	return true, nil
end

--==============================================================================
-- MY PLANTS (2026-10-04, the owner's menu)
--
-- EQUIPPED MEANS PLANTED: standing on the player's own plot, walking and
-- earning. STORED means a fully hatched creature in the Bag, earning nothing.
-- There is no second inventory, ownership table or income here: a creature is a
-- row in profile.Held (with its Tool) or an entry in this file's `growing`
-- (saved in profile.Plants), and these four verbs only move one between the two
-- the way placing and picking up always have -- by its own item id, so its
-- shortcut and its heart go with it.
--
--   PLANT        one stored creature, onto a spot of the player's own beds this
--                server picks (GardenPlan.spots, the small base circle only)
--   RETURN       one planted creature back to the Bag (pickUp, Bag only)
--   EQUIP BEST   GardenPlan.best: the highest earners stand, weaker planted
--                ones come back to the Bag, newcomers get spread-out spots;
--                kept plants never move; growing pods are never touched and
--                keep their slots
--   UNEQUIP ALL  every grown creature back to the Bag, or none
--
-- SAFE BY CONSTRUCTION, NOT BY CLEAN-UP:
--   * every check first -- the garden restored, the Bag's record armed (its
--     Tools are the record's), every newcomer's Tool found by its id and not
--     sealed by a running hatch roll, and the plot AND the Bag after the
--     whole change counted (a raid pod in the arms keeps its place) -- and a
--     change that does not fit is refused whole, before anything moves;
--   * then the moves, in the one order that never needs more room than there
--     is: newcomers INTO the ground first (their Bag rows come off, by id),
--     then the displaced OUT through pickUp, which hands a creature over
--     before it leaves the bed -- so a swap with a full Bag works, and a
--     creature the Bag would not take simply stays where it stood;
--   * no yield anywhere in a verb: nothing else (a hatch, a pickup, a sale, a
--     save) can run in the middle of one, and one player's requests are heard
--     at most once per MyPlants.Cooldown.
--==============================================================================
local MY = PLANTING.MyPlants
local ITEM_ID = GameConfig.Attributes.ItemId

-- The plant Tool that is item `item`, in the Backpack or in the hands.
local function toolOfItem(player: Player, item: string): Tool?
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs((container :: Instance):GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute(ITEM_ID) == item then
					return child
				end
			end
		end
	end
	return nil
end

type Stored = { item: string, species: SeedData.Species, tier: number, tool: Tool }

-- How many PLANT rows the Bag's record holds (2026-10-09): the room Save.MaxHeld
-- limits since pods got a room of their own.
local function plantRowsOf(player: Player): number
	local profile = PlayerDataService.Get(player)
	local n = 0
	if profile and type(profile.Held) == "table" then
		for _, row in ipairs(profile.Held) do
			if type(row) == "table" and row.Hatched == true then
				n += 1
			end
		end
	end
	return n
end

-- Every stored creature that may go into the ground: a Bag row that is hatched,
-- with its live Tool, the Tool itself a creature whose reveal is over.
local function storedGrown(player: Player): { Stored }
	local out: { Stored } = {}
	local profile = PlayerDataService.Get(player)
	if not (profile and type(profile.Held) == "table") then
		return out
	end
	for _, row in ipairs(profile.Held) do
		if type(row) == "table" and row.Hatched == true and type(row.Item) == "string" then
			local species = SeedData.Get(tostring(row.Id))
			local tool = toolOfItem(player, row.Item)
			if species and tool and tool:GetAttribute("Hatched") == true
				and tool:GetAttribute(HatchRoll.Attribute) == nil then
				local tier = math.clamp(math.floor(tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg))
					or tonumber(row.Tier) or 1), 1, SeedData.TierCount)
				table.insert(out, { item = row.Item, species = species, tier = tier, tool = tool })
			end
		end
	end
	return out
end

-- The player's own plot, with its saved garden back in it -- or why not.
local function ownGarden(player: Player): (Model?, string?)
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		return nil, "NO_PLOT"
	end
	if restoredFor[plot] ~= player or not soilOf(plot) then
		return nil, "NOT_READY"
	end
	return plot, nil
end

-- Every bed as a rectangle in the plot's frame (the main bed's object space),
-- the edge margin off, for GardenPlan.spots.
local function bedRects(plot: Model): { GardenPlan.Bed }
	local out: { GardenPlan.Bed } = {}
	local main = soilOf(plot)
	if not main then
		return out
	end
	for _, bed in ipairs(bedsOf(plot)) do
		local rel = main.CFrame:ToObjectSpace(bed.CFrame)
		local half = bed.Size * 0.5
		local hx = math.abs(rel.RightVector.X) * half.X + math.abs(rel.UpVector.X) * half.Y
			+ math.abs(rel.LookVector.X) * half.Z
		local hz = math.abs(rel.RightVector.Z) * half.X + math.abs(rel.UpVector.Z) * half.Y
			+ math.abs(rel.LookVector.Z) * half.Z
		table.insert(out, {
			cx = rel.Position.X,
			cz = rel.Position.Z,
			hx = math.max(0, hx - EDGE_MARGIN),
			hz = math.max(0, hz - EDGE_MARGIN),
		})
	end
	return out
end

-- `count` spread-out spots on this plot's beds, plot frame; never fewer (a bed
-- with no room left in its grid repeats its first spot -- overlap is allowed).
local function spotsFor(plot: Model, count: number): { Vector3 }
	local taken: { Vector2 } = {}
	for _, entry in pairs(growing[plot] or {}) do
		table.insert(taken, Vector2.new(entry.offset.X, entry.offset.Z))
	end
	local found = GardenPlan.spots(bedRects(plot), taken, count, MY.SpotStep)
	local out: { Vector3 } = {}
	for i = 1, count do
		local p = found[i] or found[1] or Vector2.zero
		table.insert(out, Vector3.new(p.X, 0, p.Y))
	end
	return out
end

-- A creature into the ground at `offset` (plot frame), as PlaceAt plants one --
-- a new placement id, a golden-angle bearing, rendered, its pickup marker on.
-- `later` (2026-10-09, a Bag hatch) leaves the model unbuilt: the caller stands
-- it up once the hatch's reveal has played there, as the starter pod's does.
local function plantCreature(plot: Model, species: SeedData.Species, tier: number, offset: Vector3,
	item: string, later: boolean?): Planted
	local byPlot = growing[plot]
	if not byPlot then
		byPlot = {}
		growing[plot] = byPlot
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
		hatchAt = now,
		stage = CreatureModel.STAGE_GROWN,
		facing = facingFor(id),
		model = nil,
		prompt = nil,
		item = item,
	}
	byPlot[id] = entry
	if not later then
		render(entry)
	end
	return entry
end

-- One request per player per cooldown; a second press inside it is not heard.
local lastMyPlants: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function grownEntries(plot: Model): ({ Planted }, number)
	local grown: { Planted } = {}
	local pods = 0
	for _, entry in pairs(growing[plot] or {}) do
		if entry.stage == CreatureModel.STAGE_GROWN then
			table.insert(grown, entry)
		else
			pods += 1
		end
	end
	table.sort(grown, function(a, b)
		return a.id < b.id
	end)
	return grown, pods
end

-- PLANT: one stored creature, by its item id.
function PlantService.PlantFromBag(player: Player, item: string): (boolean, string)
	local plot, why = ownGarden(player)
	if not plot then
		return false, why :: string
	end
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY"
	end
	if countIn(plot) >= capacityOf(plot) then
		return false, "PLOT_FULL"
	end
	local pick: Stored? = nil
	for _, s in ipairs(storedGrown(player)) do
		if s.item == item then
			pick = s
			break
		end
	end
	if not pick then
		return false, "NOT_STORED"
	end
	local s = pick :: Stored
	plantCreature(plot, s.species, s.tier, spotsFor(plot, 1)[1], s.item)
	persist(plot)
	-- Its Bag row comes off by its own id (A SNAPSHOT MAY ADD, a transaction takes).
	s.tool:Destroy()
	CarryService.SyncHeldNow(player, { s.tool })
	PlayerDataService.RecordTutorial(player, "place")
	log(string.format("%s planted a %d tier %s from MY PLANTS (item %s). %d/%d in the bed.", player.Name,
		s.tier, s.species.Name, s.item, countIn(plot), capacityOf(plot)))
	return true, "PLANTED"
end

-- RETURN TO BAG: one planted creature, by its placement id.
function PlantService.ReturnToBag(player: Player, placementId: number): (boolean, string)
	local plot, why = ownGarden(player)
	if not plot then
		return false, why :: string
	end
	local entry = (growing[plot] or {})[placementId]
	if not entry then
		return false, "NOT_PLANTED"
	end
	if entry.stage ~= CreatureModel.STAGE_GROWN then
		return false, "GROWING"
	end
	local ok, code = pickUp(player, entry, true)
	if not ok then
		return false, code or "NOT_RETURNED"
	end
	return true, "RETURNED"
end

-- EQUIP BEST. Answers ok, a code, how many went in and how many came out.
function PlantService.EquipBest(player: Player): (boolean, string, number, number)
	local plot, why = ownGarden(player)
	if not plot then
		return false, why :: string, 0, 0
	end
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY", 0, 0
	end
	local byPlot = growing[plot] or {}
	local grown, pods = grownEntries(plot)
	local candidates: { GardenPlan.Candidate } = {}
	for _, entry in ipairs(grown) do
		table.insert(candidates, {
			key = "p:" .. entry.id,
			income = SeedData.IncomePerSecond(entry.species, entry.tier),
			planted = true,
			item = entry.item,
			placementId = entry.id,
		})
	end
	local stored: { [string]: Stored } = {}
	for _, s in ipairs(storedGrown(player)) do
		stored[s.item] = s
		table.insert(candidates, {
			key = "i:" .. s.item,
			income = SeedData.IncomePerSecond(s.species, s.tier),
			planted = false,
			item = s.item,
			placementId = nil,
		})
	end
	local plan = GardenPlan.best(candidates, capacityOf(plot), pods)
	if not GardenPlan.changes(plan) then
		return true, "UNCHANGED", 0, 0
	end
	-- The Bag after the whole change, before anything moves: its PLANT room
	-- (2026-10-09). Pods have their own, and a pod in the arms keeps its place
	-- there, so neither is counted against these.
	if not GardenPlan.fits(plantRowsOf(player), false, #plan.plant, #plan.ret,
		GameConfig.Save.MaxHeld) then
		return false, "STORAGE_FULL", 0, 0
	end

	-- 1. Newcomers into the ground, at spread-out spots; their rows off the Bag.
	local spots = spotsFor(plot, #plan.plant)
	local consumed: { Instance } = {}
	local planted = 0
	for i, c in ipairs(plan.plant) do
		local s = stored[c.item :: string]
		if s and s.tool.Parent then
			local ok = pcall(plantCreature, plot, s.species, s.tier, spots[i], s.item)
			if ok then
				planted += 1
				s.tool:Destroy()
				table.insert(consumed, s.tool)
			else
				-- Never half in: a newcomer that would not build stays in the Bag.
				for id, entry in pairs(byPlot) do
					if entry.item == s.item and entry.model == nil then
						byPlot[id] = nil
					end
				end
			end
		end
	end
	persist(plot)
	if #consumed > 0 then
		CarryService.SyncHeldNow(player, consumed)
	end

	-- 2. The displaced out, weakest first, only as many as the newcomers that
	-- actually went in need room for. pickUp hands each over before it leaves.
	local need = math.max(0, #plan.ret - (#plan.plant - planted))
	local returned = 0
	for i = #plan.ret, 1, -1 do
		if returned >= need then
			break
		end
		local entry = byPlot[plan.ret[i].placementId :: number]
		if entry then
			local ok, picked = pcall(pickUp, player, entry, true)
			if ok and picked then
				returned += 1
			end
		end
	end
	persist(plot)
	local complete = planted == #plan.plant and returned == #plan.ret
	log(string.format("%s: EQUIP BEST put %d in and %d back in the Bag%s. %d/%d in the bed.", player.Name,
		planted, returned, if complete then "" else " (INCOMPLETE: nothing was lost; some stayed where they were)",
		countIn(plot), capacityOf(plot)))
	return complete, if complete then "EQUIPPED" else "INCOMPLETE", planted, returned
end

-- UNEQUIP ALL: every grown creature back to the Bag, or none.
function PlantService.UnequipAll(player: Player): (boolean, string, number)
	local plot, why = ownGarden(player)
	if not plot then
		return false, why :: string, 0
	end
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY", 0
	end
	local grown = grownEntries(plot)
	if #grown == 0 then
		return true, "NOTHING", 0
	end
	-- The PLANT room only (2026-10-09), as EQUIP BEST counts it.
	if not GardenPlan.fits(plantRowsOf(player), false, 0, #grown, GameConfig.Save.MaxHeld) then
		return false, "STORAGE_FULL_ALL", 0
	end
	local returned = 0
	for _, entry in ipairs(grown) do
		local ok, picked = pcall(pickUp, player, entry, true)
		if ok and picked then
			returned += 1
		end
	end
	persist(plot)
	local complete = returned == #grown
	return complete, if complete then "UNEQUIPPED" else "INCOMPLETE", returned
end

--==============================================================================
-- PODS HATCH IN THE BAG (2026-10-09, the owner's Phase 1, "More stealing, less
-- waiting"; GameConfig.HatchInBag, KB/STEAL-MORE-PLAN.md)
--
-- A pod's wait runs in the Bag from the moment it is banked (its row's HatchAt,
-- CarryService), so every stolen pod grows at once and none takes a bed. Once
-- ready it is hatched from the Bag: HATCH (one, by its item id, after the bed
-- prompt's own 1.1 s hold, held on the client) or HATCH ALL (every ready pod).
-- The plant goes straight into a free bed of the player's own garden, its hatch
-- moment playing there, or into the Bag when no bed is free. A growing pod in
-- the Bag offers Instant Hatch: the bed prompt's product, price and credits.
--
-- THE ORDER, the bed hatch's own (hatch, above), with the pod in the Bag:
--   1. the guards      -- the Bag's record armed, the pod still a pod in it (by
--                         its own id), and ready or paid for
--   2. the plant       -- into a free bed (in the table, and saved), else into
--                         the Bag (its Tool and its row, GiveHatched)
--   3. the pod off     -- its Tool destroyed and its row taken off by name
--                         (SyncHeldNow), in the same step
--   4. the records     -- the Almanac, the guide's "hatch" (and "place" for a
--                         bed), the first catch
--   5. the decoration  -- a shell bursts where the moment plays, the clients
--                         are told, and a bed's plant stands up as the reveal's
--                         own fades out (as the starter pod's does)
-- NOT ONE YIELD IN 1 TO 4: the plant is theirs, and saved, before any of 5.
--
-- WHERE THE MOMENT PLAYS: at the bed while the player stands within
-- RevealAtBedStuds of it, otherwise in front of them (FrontStuds, fanned for a
-- HATCH ALL), so it is never played where nobody sees it. A HATCH ALL's moments
-- follow one another AllGapSeconds apart; every plant is theirs at once.
--==============================================================================
local SHELLS_NAME = "SeedBagHatchShells"

-- The Bag pod that is item `item`: its saved row and its live Tool, both still
-- a pod; nil and nil otherwise.
local function bagPod(player: Player, item: string): (any, Tool?)
	local profile = PlayerDataService.Get(player)
	if not (profile and type(profile.Held) == "table") or type(item) ~= "string" then
		return nil, nil
	end
	local row: any = nil
	for _, r in ipairs(profile.Held) do
		if type(r) == "table" and r.Item == item and r.Hatched ~= true then
			row = r
			break
		end
	end
	local tool = if row then toolOfItem(player, item) else nil
	if not (row and tool and tool:GetAttribute("Hatched") ~= true) then
		return nil, nil
	end
	return row, tool
end

-- In front of the player, on whatever ground is there, facing them: where a Bag
-- hatch plays away from its bed. `slot` fans a HATCH ALL -- straight ahead, then
-- right, left, further right, further left -- and the next FanSlots stand a
-- shell's width further out.
local FAN = { 0, 1, -1, 2, -2 }

local function frontOf(player: Player, tier: number, slot: number): CFrame?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (character and root and root:IsA("BasePart")) then
		return nil
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, -1)
	local slots = math.clamp(math.floor(BAG.FanSlots), 1, #FAN)
	local widest = math.floor(slots / 2)
	local step = if widest > 0 then BAG.FanDegrees / widest else 0
	local ring = math.floor(slot / slots)
	local turn = math.rad(FAN[(slot % slots) + 1] * step)
	local dir = CFrame.Angles(0, turn, 0):VectorToWorldSpace(flat)
	local reach = BAG.FrontStuds + SeedData.PodDiameter(tier) * (1 + ring)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local feet = root.Position.Y - root.Size.Y * 0.5 - (if humanoid then humanoid.HipHeight else 2)
	local spot = Vector3.new(root.Position.X, feet, root.Position.Z) + dir * reach
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local hit = Workspace:Raycast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -24, 0), params)
	if hit then
		spot = hit.Position
	end
	local toward = Vector3.new(root.Position.X, spot.Y, root.Position.Z)
	if (toward - spot).Magnitude < 0.05 then
		return CFrame.new(spot)
	end
	return CFrame.lookAt(spot, toward)
end

-- The shell, where the moment plays: built as a planted pod is, and burst at
-- once -- the crack every hatch has. Decoration only: a shell that will not
-- build leaves the reveal to play without it.
local function burstShellAt(species: SeedData.Species, tier: number, where: CFrame)
	local folder = Workspace:FindFirstChild(SHELLS_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = SHELLS_NAME
		folder.Parent = Workspace
	end
	local ok, model = pcall(CreatureModel.Build, species, tier, CreatureModel.STAGE_POD, where, folder)
	if not ok or typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
		return
	end
	for _, d in ipairs((model :: Model):GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	burst(model :: Model, tier)
end

-- What a Bag hatch says once its plant has come up, `after` seconds from now: a
-- HATCH ALL of several, by where they went; one into the Bag; one planted while
-- its moment played away from its bed. A plant that came up in its own bed in
-- front of the player is not announced: they watched it land.
local function tellBagHatch(player: Player, planted: number, bagged: number, after: number)
	local W = BAG.Words
	local total = planted + bagged
	local title: string, detail: string
	if total > 1 then
		title = string.format(W.AllTitle, total)
		detail = if bagged == 0 then W.AllPlanted
			elseif planted == 0 then W.AllBagged
			else string.format(W.AllSplit, planted, bagged)
	elseif bagged > 0 then
		title, detail = W.BaggedTitle, W.BaggedDetail
	elseif planted > 0 then
		title, detail = W.PlantedTitle, W.PlantedDetail
	else
		return
	end
	task.delay(math.max(after, 0), function()
		local channel = revealChannel
		if channel and player.Parent == Players then
			-- pcall: a player who left in between is no error worth having.
			pcall(function()
				channel:FireClient(player, Notice.ServerNotice, { title = title, detail = detail, key = "bag-hatch" })
			end)
		end
	end)
end

--==============================================================================
-- ONE BAG POD, HATCHED
--
-- `early` is an Instant Hatch, paid or credited: it skips the wait and nothing
-- else. `slot` and `lead` are HATCH ALL's: the pod's place in the fan, and how
-- long after the press its moment plays; a HATCH ALL's plants that go to the Bag
-- are not put in the hands (a single hatch's is, after its reveal, as a bed's).
--
-- Answers ok, a code (why not), whether the plant went into a bed, whether its
-- moment played at that bed, and in how many seconds the plant has come up.
--==============================================================================
local function hatchOneFromBag(player: Player, item: string, early: boolean?, slot: number?,
	lead: number?): (boolean, string?, boolean, boolean, number)
	-- 1. The guards.
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY", false, false, 0
	end
	local row, tool = bagPod(player, item)
	local species = if row then SeedData.Get(tostring(row.Id)) else nil
	if not (row and tool and species) then
		return false, "NO_POD", false, false, 0
	end
	local s = species :: SeedData.Species
	local podTool = tool :: Tool
	local tier = math.clamp(math.floor(tonumber(row.Tier) or 1), 1, SeedData.TierCount)
	local due = tonumber(row.HatchAt)
	if due == nil then
		-- CarryService stamps every pod it makes; this only mends a row an older
		-- writer left without one, whose wait starts now.
		CarryService.SetPodDeadline(player, item, os.time() + SeedData.GrowSecondsFor(s, tier))
		return false, "NOT_READY", false, false, 0
	end
	if early ~= true and os.time() < due then
		return false, "NOT_READY", false, false, 0
	end
	-- When its moment plays (HATCH ALL's lead from now) and when the plant may be
	-- shown: the roll after that, none for the Rain pods -- a bed hatch's timing.
	local delay = math.max(tonumber(lead) or 0, 0)
	local at = Workspace:GetServerTimeNow() + delay
	local revealAt = if s.SkipHatchRoll == true then at else HatchRoll.revealAt(at)
	local rolled = math.max(revealAt - at, 0)
	local risen = delay + (if rolled > 0
		then rolled + HATCH.Reveal.Seconds
		else BURST + HATCH.Reveal.Seconds + (if early == true then HATCH.Paid.PulseSeconds else 0))

	-- 2. The plant: a free bed of their own garden, else the Bag.
	local plot = ownGarden(player)
	local entry: Planted? = nil
	if plot and countIn(plot) < capacityOf(plot) then
		local id = PlayerDataService.MintItem(player)
		if not id then
			return false, "NO_RECORD", false, false, 0
		end
		entry = plantCreature(plot, s, tier, spotsFor(plot, 1)[1], id, true)
		persist(plot)
	else
		local given, why = CarryService.GiveHatched(player, s, tier, if slot ~= nil then -1 else risen,
			if rolled > 0 then revealAt else nil, true)
		if not given then
			return false, why, false, false, 0
		end
	end

	-- 3. The pod off the Bag: its Tool, and its row by its own id.
	podTool:Destroy()
	CarryService.SyncHeldNow(player, { podTool })
	log(string.format("%s %s a %d tier %s in the Bag: %s.", player.Name,
		if early == true then "instantly hatched" else "hatched", tier, s.Name,
		if entry then "planted in a free bed" else "into the Bag, no bed free"))

	-- 4. The records, as a bed hatch keeps them.
	local discovered = PlayerDataService.MarkSeen(player, s.Id)
	local firstHatch = PlayerDataService.RecordTutorial(player, "hatch")
	if entry then
		PlayerDataService.RecordTutorial(player, "place")
	end
	local firstCatch = PlayerDataService.TakeFirstCatch(player, s.Id, tier)

	-- 5. The decoration. The plant is theirs and saved already.
	local where: CFrame? = nil
	local atBed = false
	if entry then
		local bedAt = standCF(entry)
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if bedAt and root and root:IsA("BasePart")
			and (root.Position - bedAt.Position).Magnitude <= BAG.RevealAtBedStuds then
			where = bedAt
			atBed = true
		end
	end
	if not where then
		where = frontOf(player, tier, slot or 0)
	end
	revealToken += 1
	local payload = {
		token = revealToken,
		species = s.Id,
		tier = tier,
		rarity = s.Rarity,
		income = SeedData.IncomePerSecond(s, tier),
		cf = where,
		owner = player,
		paid = early == true,
		discovery = discovered,
		firstHatch = firstHatch == true,
		firstCatch = firstCatch == true,
		at = at,
		revealAt = revealAt,
	}
	local function show()
		if where then
			burstShellAt(s, tier, where :: CFrame)
		end
		announceReveal(payload)
	end
	if delay > 0 then
		task.delay(delay, show)
	else
		show()
	end
	-- A bed's plant stands up as the reveal's label and figure fade, so the
	-- garden shows one plant, not two -- only while it is still that bed's plant.
	if entry then
		local planted = entry :: Planted
		task.delay(risen + HATCH.Label.Seconds + HATCH.Label.FadeSeconds, function()
			local live = growing[planted.plot]
			if live and live[planted.id] == planted and planted.stage == CreatureModel.STAGE_GROWN
				and not planted.model and planted.plot.Parent then
				render(planted)
			end
		end)
	end
	return true, nil, entry ~= nil, atBed, risen
end

-- HATCH: one ready Bag pod, by its item id. Answers ok and a code.
function PlantService.HatchFromBag(player: Player, item: string): (boolean, string?)
	local ok, code, bed, atBed, risen = hatchOneFromBag(player, item, false, nil, nil)
	if not ok then
		-- No free bed and no plant room: the pod stays in the Bag, ready, and the
		-- player is told what makes room. Every other refusal is silent.
		if code == "STORAGE_FULL" then
			storageFull(player, "STORAGE_FULL", "Bag hatch refused")
		end
		return false, code
	end
	if not bed then
		tellBagHatch(player, 0, 1, risen)
	elseif not atBed then
		tellBagHatch(player, 1, 0, risen)
	end
	return true, if bed then "PLANTED" else "BAGGED"
end

-- HATCH ALL: every ready Bag pod, the soonest due first. Answers ok, a code, and
-- how many were planted, how many went to the Bag, and how many are left ready.
function PlantService.HatchAllFromBag(player: Player): (boolean, string, number, number, number)
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY", 0, 0, 0
	end
	local profile = PlayerDataService.Get(player)
	if not (profile and type(profile.Held) == "table") then
		return false, "NOT_READY", 0, 0, 0
	end
	-- Gathered before any of them moves: each hatch writes the record anew.
	local now = os.time()
	local ready: { { item: string, due: number } } = {}
	for _, row in ipairs(profile.Held) do
		local due = if type(row) == "table" and row.Hatched ~= true then tonumber(row.HatchAt) else nil
		if due and now >= due and type(row.Item) == "string" then
			table.insert(ready, { item = row.Item, due = due })
		end
	end
	if #ready == 0 then
		return true, "NOTHING", 0, 0, 0
	end
	table.sort(ready, function(a, b)
		if a.due ~= b.due then
			return a.due < b.due
		end
		return a.item < b.item
	end)
	local planted, bagged, shown = 0, 0, 0
	local firstUp = 0
	local stopped = false
	for _, pod in ipairs(ready) do
		local ok, why, bed, _, risen = hatchOneFromBag(player, pod.item, false, shown, shown * BAG.AllGapSeconds)
		if ok then
			if shown == 0 then
				firstUp = risen
			end
			shown += 1
			if bed then
				planted += 1
			else
				bagged += 1
			end
		elseif why == "STORAGE_FULL" then
			-- No free bed and no plant room: every pod after this would be refused
			-- the same way. They stay in the Bag, ready.
			stopped = true
			break
		end
	end
	local left = #ready - planted - bagged
	if planted + bagged > 0 then
		tellBagHatch(player, planted, bagged, firstUp)
	end
	if stopped then
		storageFull(player, "STORAGE_FULL", "HATCH ALL stopped")
	end
	log(string.format("%s: HATCH ALL hatched %d of %d ready pod(s): %d planted, %d into the Bag%s.", player.Name,
		planted + bagged, #ready, planted, bagged, if left > 0 then string.format(", %d left ready", left) else ""))
	local code = if stopped then "STORAGE_FULL" elseif left > 0 then "INCOMPLETE" else "HATCHED"
	return planted + bagged > 0, code, planted, bagged, left
end

-- INSTANT HATCH on a growing Bag pod: a saved credit is spent, else the purchase
-- dialog opens for that pod (the receipt reads the note: instantBagReceipt).
-- Every rule of the bed prompt's (OfferInstantHatch) holds: no dialog for a ready
-- pod or for a hatch that would be refused for room, and a credit spent only
-- once the hatch has succeeded.
function PlantService.OfferInstantHatchBag(player: Player, item: string): (boolean, string?)
	if not CarryService.IsHeldRestored(player) then
		return false, "NOT_READY"
	end
	local row, tool = bagPod(player, item)
	if not (row and tool) then
		return false, "NO_POD"
	end
	if os.time() >= (tonumber(row.HatchAt) or 0) then
		-- A ready pod hatches free; nothing is sold for it.
		return false, "READY"
	end
	-- NO ROOM, NO DIALOG: a free bed, or room for one more plant in the Bag.
	local plot = ownGarden(player)
	if not (plot and countIn(plot) < capacityOf(plot)) then
		local room, _, known = CarryService.HeldRoom(player)
		if not known then
			return false, "NOT_READY"
		end
		if room < 1 then
			storageFull(player, "STORAGE_FULL", "Instant Hatch not offered")
			return false, "STORAGE_FULL"
		end
	end
	if creditsOf(player) > 0 then
		local ok, why, bed, atBed, risen = hatchOneFromBag(player, item, true, nil, nil)
		if not ok then
			return false, why
		end
		local left = PlayerDataService.AddInstantCredits(player, -1)
		if left == nil then
			warn(string.format("[Seed/PlantService] %s: a saved Instant Hatch hatched a Bag pod and the credit "
				.. "could not be taken.", player.Name))
		end
		refreshInstantPrompts(player)
		log(string.format("%s spent a saved instant hatch on a Bag pod (%s left).", player.Name, tostring(left)))
		ActionRefusal.send(player, "INSTANT_CREDIT_USED")
		if not bed then
			tellBagHatch(player, 0, 1, risen)
		elseif not atBed then
			tellBagHatch(player, 1, 0, risen)
		end
		return true, "CREDIT"
	end
	local productId = instantProductId()
	if productId <= 0 then
		if not warnedNoProduct then
			warnedNoProduct = true
			warn("[Seed/PlantService] Instant Hatch was pressed, but its Developer Product "
				.. "id is still 0. Create the product in the Creator Dashboard and fill its "
				.. "id into GameConfig.Store.InWorld.")
		end
		return false, "NO_PRODUCT"
	end
	local clock = os.clock()
	if clock - (lastOffer[player.UserId] or -math.huge) < INSTANT.OfferGapSeconds then
		return false, "WAIT"
	end
	lastOffer[player.UserId] = clock
	wanted[player.UserId] = { bagItem = item }
	local opened, err = pcall(function()
		local open = promptFn
		if open then
			open(player, productId)
		else
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end)
	if not opened then
		warn(string.format("[Seed/PlantService] Instant Hatch dialog for %s failed: %s",
			player.Name, tostring(err)))
		return false, "NO_DIALOG"
	end
	return true, "OFFERED"
end

--==============================================================================
-- THE RECEIPT FOR A BAG POD: THAT POD, OR A CREDIT (2026-10-09)
--
-- The bed receipt's rules (InstantHatch), for the pod the Bag's note names:
--   1. still in the Bag and still growing: it hatches, the wait skipped. With
--      no free bed and no plant room it is made READY instead (its deadline now,
--      row and Tool), and the player is told it hatches free once there is room;
--   2. gone, or already ready: the purchase is kept as ONE saved Instant Hatch.
-- False leaves the receipt unacknowledged, so Roblox delivers it again.
--==============================================================================
instantBagReceipt = function(player: Player, item: string): boolean
	local row, tool = bagPod(player, item)
	local now = os.time()
	if not (row and tool) or now >= (tonumber(row.HatchAt) or 0) then
		local why = if row then "the Bag pod it was bought for already ready" else "the Bag pod it was bought for gone"
		if not keepForLater(player, why) then
			return false
		end
		ActionRefusal.send(player, if row then "INSTANT_CREDIT_READY" else "INSTANT_CREDIT_SAVED")
		return true
	end
	local ok, why, bed, atBed, risen = hatchOneFromBag(player, item, true, nil, nil)
	if ok then
		wanted[player.UserId] = nil
		if not bed then
			tellBagHatch(player, 0, 1, risen)
		elseif not atBed then
			tellBagHatch(player, 1, 0, risen)
		end
		return true
	end
	if why ~= "STORAGE_FULL" then
		return false
	end
	-- PAID FOR, AND NO ROOM: the pod is made ready instead, as a bed's pod is.
	if not CarryService.SetPodDeadline(player, item, now) then
		return false
	end
	wanted[player.UserId] = nil
	log(string.format("%s bought an instant hatch with no bed and plant storage full: the Bag pod is ready "
		.. "now, and hatches free once there is room.", player.Name))
	storageFull(player, "STORAGE_FULL_READY", nil, true)
	return true
end

--==============================================================================
-- A STUDIO TEST'S OLD SAVE (2026-10-09): a pod planted the way PlaceAt planted
-- one before pods hatched in the Bag -- in a free bed of this player's own
-- garden, `seconds` from ready, with its prompts -- so a guarded Play can show
-- an old save's planted pod growing and hatching where it stands. Studio only,
-- like DebugReady; nothing in a live server calls it and no remote reaches it.
-- Answers whether it planted, and why not.
--==============================================================================
function PlantService.DebugOldPod(player: Player, speciesId: string, tier: number, seconds: number): (boolean, string?)
	if not game:GetService("RunService"):IsStudio() then
		return false, "NOT_STUDIO"
	end
	local plot, why = ownGarden(player)
	if not plot then
		return false, why
	end
	local species = SeedData.Get(speciesId)
	if not species then
		return false, "UNKNOWN_SPECIES"
	end
	if countIn(plot) >= capacityOf(plot) then
		return false, "BED_FULL"
	end
	local byPlot = growing[plot] or {}
	growing[plot] = byPlot
	local id = (nextId[plot] or 0) + 1
	nextId[plot] = id
	local now = os.time()
	local entry: Planted = {
		plot = plot,
		id = id,
		species = species,
		tier = math.clamp(math.floor(tonumber(tier) or 1), 1, SeedData.TierCount),
		offset = spotsFor(plot, 1)[1],
		plantedAt = now,
		hatchAt = now + math.max(0, math.floor(tonumber(seconds) or 0)),
		stage = CreatureModel.STAGE_POD,
		facing = facingFor(id),
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
	persist(plot)
	return true, nil
end

-- The Bag's verbs off the wire: every argument a claim, one request per cooldown.
local lastBagHatch: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function onBagHatch(player: Player, action: string, payload: any)
	local now = os.clock()
	if now - (lastBagHatch[player] or -math.huge) < BAG.Cooldown then
		return
	end
	lastBagHatch[player] = now
	local reply: { [string]: any } = { op = action }
	if action == BAG.Hatch or action == BAG.Instant then
		if type(payload) ~= "string" or #payload == 0 or #payload > 24 then
			return
		end
		reply.item = payload
		if action == BAG.Hatch then
			reply.ok, reply.code = PlantService.HatchFromBag(player, payload)
		else
			reply.ok, reply.code = PlantService.OfferInstantHatchBag(player, payload)
		end
	elseif action == BAG.HatchAll then
		reply.ok, reply.code, reply.planted, reply.bagged, reply.left = PlantService.HatchAllFromBag(player)
	else
		return
	end
	local channel = revealChannel
	if channel and player.Parent == Players then
		channel:FireClient(player, BAG.Reply, reply)
	end
end

-- The verbs off the wire: every argument a claim, one request per cooldown.
local function onMyPlants(player: Player, action: string, payload: any)
	local now = os.clock()
	if now - (lastMyPlants[player] or -math.huge) < MY.Cooldown then
		return
	end
	lastMyPlants[player] = now
	local reply: { [string]: any } = { op = action }
	if action == MY.Plant then
		if type(payload) ~= "string" or #payload == 0 or #payload > 24 then
			return
		end
		reply.ok, reply.code = PlantService.PlantFromBag(player, payload)
		reply.planted = if reply.ok then 1 else 0
	elseif action == MY.Return then
		if type(payload) ~= "number" or payload ~= payload or payload < 1 or payload > 1e9
			or math.floor(payload) ~= payload then
			return
		end
		reply.ok, reply.code = PlantService.ReturnToBag(player, payload)
		reply.returned = if reply.ok then 1 else 0
	elseif action == MY.Best then
		reply.ok, reply.code, reply.planted, reply.returned = PlantService.EquipBest(player)
	elseif action == MY.Clear then
		reply.ok, reply.code, reply.returned = PlantService.UnequipAll(player)
	else
		return
	end
	local channel = revealChannel
	if channel and player.Parent == Players then
		channel:FireClient(player, MY.Reply, reply)
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

--==============================================================================
-- THE STARTER POD GOES IN (2026-10-08; FirstMinute)
--
-- Into the garden of a profile FirstMinute.owed says is brand-new, once its
-- (empty) garden is restored: one Tiny Petalpip pod on the beds' first free
-- spot, on the ladder's normal Tiny wait, with no prompt -- it hatches itself
-- (hatchStarter). The flag goes on the record FIRST and in the same step as the
-- row (RecordStarter refuses a second), so a save holds both or neither: a
-- server that dies before saving owes the starter again, and one that saved
-- never gives another. The caller's persist() writes the row.
--==============================================================================
local function plantStarter(player: Player, plot: Model, profile: any): Planted?
	if not FirstMinute.owed(profile) then
		return nil
	end
	local species = FirstMinute.starter()
	local byPlot = growing[plot]
	if not (species and byPlot) or countIn(plot) >= capacityOf(plot) then
		return nil
	end
	local tier = FirstMinute.StarterTier
	local now = os.time()
	if not PlayerDataService.RecordStarter(player, now) then
		return nil
	end
	local id = (nextId[plot] or 0) + 1
	nextId[plot] = id
	local entry: Planted = {
		plot = plot,
		id = id,
		species = species,
		tier = tier,
		offset = spotsFor(plot, 1)[1],
		plantedAt = now,
		hatchAt = now + SeedData.GrowSecondsFor(species, tier),
		stage = CreatureModel.STAGE_POD,
		facing = facingFor(id),
		model = nil,
		prompt = nil,
		starter = true,
	}
	byPlot[id] = entry
	render(entry)
	log(string.format("%s is new: a starter %s pod is growing in their garden (%ds).",
		player.Name, species.Name, entry.hatchAt - now))
	return entry
end

local function restore(player: Player, plot: Model)
	task.spawn(function()
		-- For as long as they stay (GameConfig.Plot.RestorePatienceSeconds is
		-- the backstop). This gave up after 30 s, and a save has been measured
		-- at 38: the garden was then never put back, and restoredFor is what
		-- now stops the next planting saving that empty bed over it.
		local deadline = os.clock() + GameConfig.Plot.RestorePatienceSeconds
		while player.Parent == Players and not PlayerDataService.IsReady(player)
			and os.clock() < deadline do
			task.wait(0.25)
		end
		local profile = PlayerDataService.Get(player)
		if not profile or player.Parent ~= Players then
			if player.Parent == Players then
				warn(string.format("[Seed/PlantService] %s: the saved garden never arrived; "
					.. "their bed stays shut this session rather than be saved empty.", player.Name))
			end
			return
		end
		-- Still theirs? A long wait is long enough to have been reassigned.
		if PlotService.PlotOf(player) ~= plot then
			return
		end
		-- Their saved Instant Hatches, for the Bag's button (2026-10-09).
		publishCredits(player)

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
		-- Saved X/Z are the Front shape's (GardenFrame); this plot's own frame
		-- is the same but on plot 6 at Levels 6-7. The level the soil was built
		-- at, off the plot: resized to its owner's before this ever runs.
		local level = tonumber(plot:GetAttribute("Level"))
		local plotId = tonumber(plot:GetAttribute(GameConfig.Attributes.PlotId))
		-- When this profile's starter pod was planted, or 0 (FirstMinute).
		local starterAt = tonumber((profile :: any).StarterAt) or 0

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
			if x and z then
				local live = GardenFrame.FromSaved(level, plotId, Vector3.new(x, 0, z))
				x, z = live.X, live.Z
			else
				-- A slot index is this plot's own grid, already in its frame.
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
					item = if stage == CreatureModel.STAGE_GROWN and row and type(row.Item) == "string"
						then row.Item else nil,
					-- The starter pod still growing (FirstMinute): the row the
					-- game planted at the profile's StarterAt. It hatches itself
					-- on the next tick if its time is already up.
					starter = if stage == CreatureModel.STAGE_POD and starterAt > 0 and at == starterAt
						then true else nil,
				}
				byPlot[id] = entry
				render(entry)
				if entry.starter then
					-- No prompt of either kind: the tick hatches it.
				elseif isReady(entry, now) then
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
		-- The garden is in. From here the bed is this owner's to save and plant.
		restoredFor[plot] = player
		-- A brand-new profile's first garden: one pod, planted now (FirstMinute).
		plantStarter(player, plot, profile)
		local growingStarter: number? = nil
		for _, entry in pairs(byPlot) do
			if entry.starter then
				growingStarter = entry.hatchAt
			end
		end
		publishStarter(player, growingStarter)
		-- Write back, so anything dropped stops being carried forever and any
		-- migrated position is saved in the new shape.
		persist(plot)
		sweepAnchors(plot)
	end)
end

-- Whether a plot's owner has had their saved garden put back into it -- the
-- gate persist() and PlaceAt wait on. For specs and the leave/rejoin checks.
function PlantService.GardenRestored(plot: Model): boolean
	local owner = PlotService.OwnerOf(plot)
	return owner ~= nil and restoredFor[plot] == owner
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
			-- The rung it walks on: its own tier's, or its species' (a Secret walks
			-- the Colossal rung for its authored size, SeedData.WanderTierOf). Its
			-- legs step to the leg it is handed on every client (SecretIdle).
			local walkTier = SeedData.WanderTierOf(entry.species, entry.tier) or entry.tier
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
					+ SeedData.WanderPause(walkTier) * rng:NextNumber(0.7, 1.7)
				persist(plot)
			end

			if not entry.legEnd and srvNow >= (entry.restUntil or 0) then
				if not region then
					region = PlantWander.RegionFor(plot)
				end
				local to, how = PlantWander.Choose(region :: PlantWander.Region,
					entry.offset, walkTier, byPlot :: any, entry.id, rng)
				local fromW = wanderWorld(plot, entry.offset)
				local toW = wanderWorld(plot, to)
				if how == "stay" then
					-- Nowhere on the plot is a walk worth taking from here. Rest
					-- again rather than publish a leg that goes nowhere.
					entry.restUntil = srvNow + SeedData.WanderPause(walkTier)
				elseif fromW and toW then
					local dist = (toW - fromW).Magnitude
					local t0 = srvNow
					local t1 = t0 + PlantWander.LegSeconds(walkTier, dist)
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
-- A PROGRESS RESET: THE BED EMPTIED, AND NOTHING SAVED OUT OF IT
--
-- AdminService's Reset Player Progress. Everything standing on this plot goes --
-- models, anchors, the tracking, a pending Instant Hatch note -- the way a
-- released lease clears it, and NOTHING is persisted on the way out: the
-- profile is being reset, and writing the old garden into it is the one thing
-- this must not do. Any later persist of this plot finds an empty bed.
--==============================================================================
function PlantService.ClearGarden(player: Player, plot: Model): number
	local cleared = 0
	for _, entry in pairs(growing[plot] or {}) do
		if entry.model and entry.model.Parent then
			entry.model:Destroy()
		end
		dropAnchor(entry)
		cleared += 1
	end
	growing[plot] = nil
	nextId[plot] = nil
	carried[plot] = nil
	local folder = plot:FindFirstChild(PLOT.PlantsFolderName)
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			child:Destroy()
		end
	end
	wanted[player.UserId] = nil
	lastOffer[player.UserId] = nil
	-- A starter pod that was still growing went with the rest.
	publishStarter(player, nil)
	log(string.format("%s's garden was cleared for a progress reset (%d plant(s)).", player.Name,
		cleared))
	return cleared
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
	table.clear(restoredFor)
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
		-- Shut until the next owner's garden is in.
		restoredFor[plot] = nil
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
					-- Refused or not is PlaceAt's to decide, and it already has.
					-- Out of reach and a full plot are said to the player; every
					-- other guard is internal and stays as silent as it was.
					local placed, code = PlantService.PlaceAt(player, payload)
					if not placed then
						local reason = ActionRefusal.fromPlacement(code)
						-- A FULL PLOT SAYS WHAT CAN STILL MAKE ROOM (2026-09-27):
						-- only a grown plant can be picked up (pickUp), and only a
						-- plot below its top level can be upgraded. Same refusal,
						-- same moment; this only picks which next step to name.
						local plot = if reason == "PLOT_FULL" then PlotService.PlotOf(player) else nil
						if plot then
							local hasGrown = false
							for _, entry in pairs(growing[plot] or {}) do
								if entry.stage == CreatureModel.STAGE_GROWN then
									hasGrown = true
									break
								end
							end
							reason = ActionRefusal.plotFull(
								PlotService.LevelOf(plot) < #GameConfig.PlotTiers, hasGrown)
						end
						if reason then
							ActionRefusal.send(player, reason)
						end
					end
				elseif action == MY_PLANTS.Plant or action == MY_PLANTS.Return or action == MY_PLANTS.Best
					or action == MY_PLANTS.Clear then
					onMyPlants(player, action, payload)
				elseif action == BAG.Hatch or action == BAG.HatchAll or action == BAG.Instant then
					-- Pods hatch in the Bag (2026-10-09): HATCH, HATCH ALL and
					-- Instant Hatch on a Bag pod.
					onBagHatch(player, action, payload)
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
						if entry.starter then
							-- The starter pod: no prompt ever; its own hatch the
							-- moment its time is up (FirstMinute).
							if isReady(entry, now) then
								hatchStarter(entry)
							end
						elseif isReady(entry, now) then
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
		"Ready. Pods hatch in the Bag: hold HATCH %.1fs (an old save's planted pod: hold E). "
			.. "Click your soil to place a plant.",
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
