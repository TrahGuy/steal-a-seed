--!strict
-- Steal a Seed :: CarryService
--
-- Picking a pod up, carrying it home, and losing it when it goes wrong.
--
--==============================================================================
-- ONE POD. THAT IS THE WHOLE RULE.
--
-- An earlier build let you stack them and summed the weight. One is better, and
-- for a reason worth keeping: with a stack, a raid is an optimisation problem --
-- how many can I grab before it wakes. With one, it is a COMMITMENT. You picked
-- that pod, you are carrying that pod, and the walk home is about that pod.
--
-- It also makes the weight legible. A single number on your back, a single
-- number off your speed, and a player learns the whole economy by carrying two
-- different things.
--
--==============================================================================
-- GETTING CAUGHT COSTS YOU THE POD, NOT JUST THE WALK
--
-- Being ragdolled drops it. Any ragdoll, not just the parent's throw -- the
-- trigger is Humanoid.PlatformStand going true, so anything that ever knocks a
-- player down takes their cargo with it and no future system has to remember to
-- call anything.
--
-- That is what makes the parent frightening. The throw alone costs distance,
-- which is recoverable; losing the pod at the same time is what makes you creep
-- rather than sprint.
--
--==============================================================================
-- THIS SERVICE IS THE ONLY WRITER OF WalkSpeed
--
-- Base comes from the profile's Speed through GameConfig's curve, and carry
-- weight is the LAST multiplier applied to it. Something has to have the final
-- say or two systems fight over the property every frame, and the one holding
-- the last multiplier is the one that must own it. A future TreadmillService
-- raises the Speed SCORE and calls RefreshWalkSpeed; it never touches WalkSpeed.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))
local GuardianCatch = require(script.Parent:WaitForChild("GuardianCatch"))
local CarryGuard = require(script.Parent:WaitForChild("CarryGuard"))

local ATTR = GameConfig.Attributes
local SAVE = GameConfig.Save
-- On a hatched plant's Tool while its roll runs: the server time its plant may
-- be shown (HatchRoll). Never saved: rowOf reads three attributes and this is
-- not one of them.
local REVEAL_AT: string = GameConfig.Plant.Hatch.Roll.Attribute

local CarryService = {}
-- After NestService (40), which owns the pods being taken.
CarryService.Priority = 45

export type Held = {
	species: SeedData.Species,
	-- What this pod weighs. Rolled where it spawned, carried through every drop
	-- and pick-up, and stamped on the Tool when it is banked. The species sheet
	-- has nothing to say about it.
	tier: number,
	model: Model,
	-- Which nest it came off, carried through a drop so that picking it back up
	-- can annoy the same parent again.
	fromNest: string?,
	--==========================================================================
	-- WHOSE POD THIS IS, IF IT BELONGS TO SOMEBODY
	--
	-- Set only on a beginner's reserved pod (see TutorialPodService). Carried
	-- through a drop for the same reason `fromNest` is: the thing that comes
	-- back out of a drop has to be the same thing that went in, or a beginner
	-- who fumbles their one pod watches a stranger walk off with it.
	--==========================================================================
	reservedFor: number?,
	--==========================================================================
	-- A CONFISCATING GUARDIAN ALREADY CHOSE TO LEAVE THIS POD BEHIND
	--
	-- Permanent, and the POD's rather than the player's: carried through every
	-- drop, bat knock, re-take and change of hands exactly like `fromNest`, so
	-- no confiscating guardian takes it and none rolls it again. Mirrored onto
	-- the carried model and the loose pod as ATTR.GuardianAbandoned. Not carried
	-- past banking, where the pod stops being on the road at all.
	--==========================================================================
	guardianAbandoned: boolean?,
	--==========================================================================
	-- WHICH SECRET ENCOUNTER THIS POD IS (2026-10-01)
	--
	-- Set on a pod NestService spawned at a secret spot, and carried through
	-- every drop, re-take, confiscation and return exactly like `fromNest`, so
	-- the nest can tell the one pod of an encounter from any rebuild of it and
	-- never raises a second platform or a second pod for it. Mirrored onto the
	-- carried model and the loose pod as the `SecretId` attribute. Ends when the
	-- pod leaves the road: banked, forfeited, or cleared at dusk.
	--==========================================================================
	secretId: string?,
	--==========================================================================
	-- WHICH WEATHER EVENT LAID THIS POD (2026-10-02)
	--
	-- Set on a pod the Rain event's nest laid (NestService's event nest, the
	-- `EventId` attribute), and carried through every drop and re-take exactly
	-- like `fromNest`, so the pod on the ground is still that event's: the
	-- event's own cleanup finds it and dusk leaves it alone while the event
	-- runs. Gone at banking, where the pod stops being on the road.
	--==========================================================================
	eventId: number?,
}

-- The attribute a Rain event pod carries, on the nest, in the arms and on the
-- ground: the event's id (the value of GameConfig.Weather.Attributes.EventId).
local EVENT_ID = "EventId"

local carried: { [Player]: Held } = {}
-- Every carrier's travel budget; see CarryGuard and checkCarrier.
local guards: { [Player]: CarryGuard.State } = {}
-- When each player's last carry ended, for CarryGuard.SlackCooldownSeconds.
local guardEnded: { [Player]: number } = {}
local lastGuardWarn: { [Player]: number } = {}
local serviceConnections: { RBXScriptConnection } = {}
local perPlayer: { [Player]: { RBXScriptConnection } } = {}
local prompted: { [Model]: true } = {}
local running = false

-- How far above the head it floats. High enough to read across the road --
-- everybody can see what you are carrying, which is what makes a carrier a
-- target the moment PvP is switched on.
-- CARRY_HEIGHT used to be 3.0 and welded the pod to the HEAD, which floated it
-- above the skull like a halo -- readable at distance, but it made a raid look
-- like a delivery quest rather than somebody hauling something heavy.
--
-- The numbers now live in GameConfig.Carry because the CLIENT needs them too,
-- to aim the arms at the pod. Same values, one home.
-- A pod on the ground is fair game for anybody, and stands until the night sweeps
-- it -- see spawnLoose for why the forty-five second lifetime that used to be
-- here is gone.
-- The attribute naming a pod's owner. Read by TryTake, by TutorialPodService and
-- by the beginner guide's arrow trail.
local RESERVED_FOR = "ReservedFor"
-- How close you must be. The PROMPT is not a security boundary -- it is a
-- courtesy drawn on a client, and a client can call InputHoldBegin on a prompt
-- from anywhere -- so the server measures the distance itself.
local TAKE_RANGE = 11
-- Slack for latency: the client saw them in range a moment ago and the take
-- lands a moment later. Tight enough to stop a reach across the road.
local RANGE_SLACK = 5
-- How often the crossing is checked. Five times a second is finer than a player
-- can cross a line and notice.
local SAFE_CHECK_SECONDS = 0.2

local function log(message: string)
	print("[Seed/CarryService] " .. message)
end

--==============================================================================
-- STATE THE CLIENT CAN SEE
--
-- An ATTRIBUTE ON THE PLAYER, because attributes replicate on their own and the
-- prompt UI has to know instantly whether to draw itself. A remote would be a
-- round trip to answer a question the client asks every frame it renders a
-- prompt.
--==============================================================================
local function publish(player: Player)
	local held = carried[player]
	player:SetAttribute(ATTR.CarryingSpecies, if held then held.species.Id else nil)
	player:SetAttribute(ATTR.CarryingKg, if held then held.tier else nil)
end

function CarryService.IsCarrying(player: Player): boolean
	return carried[player] ~= nil
end

--==============================================================================
-- INTO FREE HANDS, OR NOT AT ALL (2026-10-02)
--
-- The hatch's delayed equip, as one function the admin console's EQUIP NOW asks
-- too. Never over a raid pod (two channels, one pair of hands), never over
-- anything already in the hands -- that was the player's choice, and nothing
-- is ever unequipped for this -- and never on a body that is gone. A refusal
-- leaves the Tool in the Backpack, where the hotbar and the Bag show it, and
-- the reason rides back: NO_TOOL, NO_CHARACTER, CARRYING, HANDS_FULL or FAILED.
--==============================================================================
function CarryService.EquipIfFree(player: Player, tool: Tool): (boolean, string?)
	if tool.Parent == nil or tool.Parent ~= player:FindFirstChildOfClass("Backpack") then
		return false, "NO_TOOL"
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not (character and humanoid) or humanoid.Health <= 0 then
		return false, "NO_CHARACTER"
	end
	if CarryService.IsCarrying(player) then
		return false, "CARRYING"
	end
	if character:FindFirstChildOfClass("Tool") then
		return false, "HANDS_FULL"
	end
	local ok = pcall(function()
		humanoid:EquipTool(tool)
	end)
	if not ok or tool.Parent ~= character then
		return false, "FAILED"
	end
	return true, nil
end

function CarryService.TotalKg(player: Player): number
	local held = carried[player]
	return if held then held.tier else 0
end

--==============================================================================
-- A MOVE THE SERVER MADE (2026-10-02)
--
-- The Rain event puts a carrier back on the island when its biome closes. The
-- travel budget would read that as a teleport and put them back on terrain
-- that is about to go, so the mover says so here: the guard is re-anchored at
-- the new spot with no slack, exactly as a correction leaves it. Nothing else
-- about the carry changes -- the pod is still in their arms.
--==============================================================================
function CarryService.NoteServerMove(player: Player, at: Vector3)
	local state = guards[player]
	if state then
		CarryGuard.reset(state, at)
	end
end

function CarryService.RefreshWalkSpeed(player: Player)
	--==========================================================================
	-- WHAT THE WEIGHT IS DOING TO THEM, PUBLISHED
	--
	-- The SAME multiplier this function applies to WalkSpeed, on the player as an
	-- attribute, so every client can see how loaded every other player is without
	-- being handed a profile and without ever being asked.
	--
	-- IT MUST BE THIS NUMBER AND NOT A RE-DERIVED ONE. A client that computed it
	-- from a replicated CarryingKg would be a client that could lie about it, and
	-- the whole point is that the visuals cannot be talked out of slowing down.
	--
	-- Published FIRST, above the mount check, because a mounted player is still
	-- holding whatever they were holding -- and coming off the belt must not be
	-- the moment their weight suddenly starts counting again.
	--
	-- Written only on a real change: this runs on every carry event and every
	-- respawn, and an unchanged attribute rewritten is replication for nothing.
	--==========================================================================
	--==========================================================================
	-- POD 3 IS HALF SPEED, EXACTLY (the owner's rule, 2026-10-02)
	--
	-- An UNBANKED Thunderstorm pod in the arms -- the raid carry, never the bag
	-- -- makes the multiplier exactly its species' CarrySpeedFactor (0.5) IN
	-- PLACE OF the ordinary weight multiplier, never on top of it. Everything
	-- below still applies after it as it does to everybody: a trap's slow, Walk
	-- Mode's cap, a mill, the obby. Nothing is stored: banking, a drop, a death
	-- or any carry ending clears `carried` and refreshes, and the earned speed
	-- comes straight back. The ordinary multiplier is untouched for every other
	-- pod (its tier/weight conversion is a separate, deferred question).
	--==========================================================================
	local held = carried[player]
	local factor = if held then (held.species :: any).CarrySpeedFactor else nil
	local multiplier = if type(factor) == "number" and factor > 0 and factor <= 1
		then factor
		else GameConfig.carryMultiplierFor(CarryService.TotalKg(player))
	if player:GetAttribute(ATTR.CarrySpeedMultiplier) ~= multiplier then
		player:SetAttribute(ATTR.CarrySpeedMultiplier, multiplier)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	--==========================================================================
	-- A MOUNTED PLAYER IS PARKED, AND THIS IS STILL THE ONLY WRITER
	--
	-- TreadmillService catches a player as they cross their own belt and needs
	-- them to stop dead. It sets an attribute and asks; it does not write
	-- WalkSpeed itself, because the entire reason this function exists is that
	-- WalkSpeed is the product of two things no single caller knows.
	--
	-- Checked BEFORE the carry multiplier rather than multiplied into it: a
	-- mounted player is at zero regardless of what they are holding, and zero
	-- times a multiplier is a zero that stops being obviously deliberate.
	--==========================================================================
	--==========================================================================
	-- HELD BY A TRAP, AND THIS IS STILL THE ONLY WRITER
	--
	-- Checked FIRST, above the mill, because a trap is something done TO a
	-- player and a mill is something they chose -- and because the two can never
	-- both be true anyway: a mill stands on a plot, every plot is inside the
	-- safe field, and CombatService refuses to place a trap anywhere in it.
	--
	-- THIS IS WHY THE TRAP IS AN ATTRIBUTE AND NOT A CAPTURED NUMBER.
	-- CombatService never reads WalkSpeed, never stores it and never puts one
	-- back; it sets this, calls RefreshWalkSpeed, clears it, and calls again --
	-- so a release recomputes from the truth of the moment it happens. The
	-- alternative is the bug written up over throwPlayer: capture a speed,
	-- something else changes it while the player is held, and the restore hands
	-- back a number that was true two seconds ago and is now wrong. A trap
	-- firing on somebody who picks up a pod while held would do exactly that.
	--
	-- Jumping is NOT handled here. CombatService disables the Jumping state at
	-- the two edges of the restraint and nowhere else, because this function
	-- runs on every carry event and every respawn -- and a system that wrote
	-- "jumping is allowed" a hundred times a session would eventually be the
	-- thing that re-enabled it underneath somebody else's hold.
	--==========================================================================
	if player:GetAttribute(GameConfig.Attributes.Trapped) == true then
		humanoid.WalkSpeed = 0
		return
	end
	if player:GetAttribute(GameConfig.Attributes.MillMounted) == true then
		humanoid.WalkSpeed = 0
		return
	end
	--==========================================================================
	-- ON THE FLOATING GARDEN, EVERYBODY RUNS AT THE COURSE'S SPEED
	--
	-- A run tests the course, not the treadmill, so its gaps are cut for one
	-- fixed speed (ObbyData). The same shape as the two states above: ObbyService
	-- sets an attribute and asks; this answers from it; clearing it and asking
	-- again recomputes the earned speed from the profile -- nothing was stored,
	-- so nothing stale can be put back. Weight and Walk Mode do not apply up
	-- there: nobody can carry a raided pod onto the course, and a walk cap would
	-- make the jumps impossible.
	--==========================================================================
	if player:GetAttribute(ObbyData.Attributes.Course) == true then
		humanoid.WalkSpeed = ObbyData.WalkSpeed
		return
	end
	local profile = PlayerDataService.Get(player)
	local base = GameConfig.walkSpeedFor(if profile then profile.Speed else 0)
	local speed = base * multiplier

	--==========================================================================
	-- A TRAP THAT SLOWS RATHER THAN STOPS
	--
	-- A FRACTION of what they would otherwise be doing, multiplied in here at the
	-- end, for the same reason `Trapped` is an attribute and not a captured
	-- number: CombatService sets it, asks for a recompute, clears it, and asks
	-- again. Nothing is stored and nothing is put back, so a player who picks up a
	-- pod, steps onto a mill or turns Walk Mode on WHILE slowed gets the right
	-- answer at every one of those moments rather than a stale one at the end.
	--
	-- Guarded to 0..1. A trap may slow a player and may never speed one up, and
	-- the assert that enforces it lives in WeaponData -- this is the belt.
	--==========================================================================
	local slow = tonumber(player:GetAttribute(GameConfig.Attributes.TrapSlow))
	if slow and slow == slow and slow >= 0 and slow < 1 then
		speed *= slow
	end

	--==========================================================================
	-- AND WALK MODE IS A CEILING, THE LAST THING APPLIED
	--
	-- min(speed, 16). LAST, so it caps the product of everything above it -- the
	-- Speed score, the weight, a snare -- and MIN, so it can only ever take speed
	-- away. A player at 12 because they are carrying a Titan pod stays at 12 when
	-- they ask to walk; a player at 90 becomes 16; and turning it off recomputes
	-- from here rather than restoring a number somebody wrote down.
	--
	-- The stronger states above have already returned by this line: rooted and
	-- mounted are zero, and zero is not something a walk cap has an opinion about.
	--==========================================================================
	if player:GetAttribute(GameConfig.Attributes.WalkMode) == true then
		speed = math.min(speed, GameConfig.WalkMode.CapStuds)
	end
	humanoid.WalkSpeed = speed
end

--==============================================================================
-- CARRYING
--==============================================================================
--==============================================================================
-- THERE IS NO WEIGHT BILLBOARD ANY MORE
--
-- A `CarryWeight` BillboardGui used to hang over the raid carry AND over the
-- banked Tool, printing "6110Kg". Both are gone, and neither is missed:
--
--   ON A POD it was the same fact a third time. A shell is COLOURED by its
--   weight band and SIZED by its weight, so the slab of UI beside the player's
--   head from the nest to the red line was telling them what the thing in their
--   arms was already telling them, twice.
--
--   ON A HATCHED CREATURE it was measured wrong and could not easily be
--   measured right. The offset was `PodDiameter(kg) * 0.5 + 1.1` -- a SHELL's
--   radius -- which put the label inside the chest of a plant. Sizing it off
--   the creature instead would have hung it thirty-four studs up on a heavy
--   Bellchime, off the top of the screen, which is not better.
--
-- Nothing functional went with it. `CarryingKg` is still on the player and on
-- the Tool -- the walk speed, the payout and the planting all read it -- and
-- the weight is still legible in three places: the shell's colour, the
-- placement disc PlantPlace tints while you hold something, and the Tool's own
-- ToolTip.
--==============================================================================

-- Where a pod sits relative to a HumanoidRootPart. One function, so the raid
-- carry and the banked Tool cannot drift into two different grips.
local function gripFor(tier: number, species: SeedData.Species?): CFrame
	-- A secret (SeedData Carry = "overhead") rides over the head in both hands:
	-- its BASE a quarter-stud above the raised hands, nothing in front of the
	-- chest. Its PrimaryPart is at its base for exactly this (SecretModel).
	if species and (species :: any).Carry == "overhead" then
		return CFrame.new(0, GameConfig.Carry.OverheadLift, 0)
	end
	-- -Z is forward in a root's frame. Offset by the pod's OWN RADIUS, because
	-- pods are 1.3 to 10 studs across: a fixed offset either buries a heavy one
	-- in the ribs or leaves a light one hovering clear of the hands.
	return CFrame.new(0, GameConfig.Carry.GripDrop, -SeedData.GripForward(tier))
end

--==============================================================================
-- IT RIDES IN FRONT OF THE TORSO, IN BOTH ARMS
--
-- Welded to HumanoidRootPart, not the head. The root is the part that turns
-- with the body, so the pod stays in front of the player through every turn
-- instead of swinging with a head that looks around independently.
--
-- Offset by the pod's OWN RADIUS, because pods are 1.3 to 10 studs across now --
-- weight is rolled per pod and any species can be either -- so a fixed offset
-- either buries a heavy one in the ribs or leaves a light one hovering a stud
-- clear of the hands.
--==============================================================================
local function attachInFront(model: Model, root: BasePart, tier: number, species: SeedData.Species?)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = primary
			end
		end
	end
	local grip = gripFor(tier, species)
	primary.CFrame = root.CFrame * grip
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = primary
	weld.C0 = grip
	weld.Parent = primary
	-- NO WEIGHT TAG. The shell's colour is its weight band and its diameter is
	-- its weight; a billboard would be the same fact a third time, floating
	-- beside the player's head from the nest to the red line.
end

--==============================================================================
-- PROMPTS
--
-- Style = Custom, so the look is drawn by PromptUI.client.luau rather than by
-- Roblox's default chrome. ActionText is still set because the client reads it
-- for the label, and ObjectText is deliberately EMPTY: the prompt shows "Take"
-- and a key, nothing else.
--==============================================================================
local function attachPrompt(pod: Model)
	if prompted[pod] or not pod:IsA("Model") then
		return
	end
	local primary = pod.PrimaryPart
	if not primary then
		return
	end
	prompted[pod] = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakePrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Take"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = GameConfig.Carry.TakeHoldSeconds
	prompt.MaxActivationDistance = TAKE_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	prompt.Triggered:Connect(function(player)
		-- Logged BEFORE the attempt, and unconditionally. A hold that
		-- completes and then refuses looks identical, from the player's
		-- side, to a hold whose input never reached the server at all --
		-- and those have nothing in common to fix.
		log(string.format("%s completed a take hold on %s", player.Name, pod.Name))
		CarryService.TryTake(player, pod)
	end)
end

--==============================================================================
-- DROPPED PODS SIT ON THE GROUND, NOT IN THE AIR
--
-- Pods are anchored, and a dropped one was placed at the player's ROOT
-- position -- which is about three studs up. It hung there. Nothing falls in
-- this game, so anything placed has to be placed correctly: cast down and put
-- its base on whatever it finds.
--==============================================================================
local function groundUnder(position: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(position + Vector3.new(0, 4, 0),
		Vector3.new(0, -60, 0), params)
	if hit then
		return hit.Position
	end
	-- Nothing beneath. The field surface is the honest fallback -- better a pod
	-- on the floor of the world than one hanging where the player happened to be.
	return Vector3.new(position.X, GameConfig.Map.GroundY, position.Z)
end

-- A dropped pod becomes a loose pod anybody can take. Declared before TryTake
-- because taking one that then cannot be attached has to put it back.
-- `kg` travels with it. A dropped pod that fell back on the species sheet would
-- be a way to launder a 9,000 kg cube into a 2 kg one by dropping it, and the
-- player who picked it up would be robbed by the physics rather than by anyone.
local function spawnLoose(species: SeedData.Species, tier: number, at: CFrame,
	parent: Instance, fromNest: string?, reservedFor: number?, keep: boolean?,
	abandoned: boolean?): Model
	local pod = CreatureModel.BuildPod(species, tier, at, parent)
	-- Loot, explicitly. This is the whole point of a loose pod.
	CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)
	--==========================================================================
	-- THE ONE PLACE A POD IS MARKED AS SOMEBODY'S
	--
	-- On the MODEL rather than in a table, because the model is the thing that
	-- survives being dropped, re-taken and streamed, and because the client
	-- needs to read it to point its arrow trail at the right pod. It is not a
	-- permission -- TryTake is -- it is the fact the permission is checked
	-- against.
	--==========================================================================
	if reservedFor then
		pod:SetAttribute(RESERVED_FOR, reservedFor)
	end
	if fromNest then
		-- Not "NestId": that would make TryTake route it back through TakePod,
		-- which would look for a slot this pod no longer occupies. It only says
		-- WHICH PARENT TO ANNOY.
		pod:SetAttribute("FromNestId", fromNest)
	end
	-- Nothing to do with `keep`, which is lifetime. This is who may take it home.
	if abandoned then
		pod:SetAttribute(ATTR.GuardianAbandoned, true)
	end
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	attachPrompt(pod)
	--==========================================================================
	-- IT LANDS, AND THE ROAD HEARS IT LAND
	--
	-- Every way a pod reaches the ground comes through here -- a carrier's own
	-- drop, a bat hit, a guardian's confiscation, a haul that could not go back
	-- in its ring, the beginner's reserved pod -- so the thud is one line rather
	-- than five, and no path can be forgotten.
	--
	-- On the POD, not on whoever dropped it: the sound belongs to the object
	-- that hit the dirt, and a player thrown off a ledge is somewhere else by
	-- the time it plays.
	--==========================================================================
	local landed = pod.PrimaryPart
	if landed then
		SoundKit.emit("PodDrop", landed)
	end
	--==========================================================================
	-- A POD ON THE ROAD STANDS UNTIL NIGHT, AND NOT A SECOND LESS
	--
	-- Every loose pod used to destroy itself forty-five seconds after it landed,
	-- so that the road did not fill with litter. The owner rejected that on
	-- 2026-09-17, and they are right: forty-five seconds is shorter than the walk
	-- from a deep nest, so a pod dropped by a bat hit, a guardian's confiscation
	-- or a player's own hands could be GONE before its owner got back to it --
	-- and a prize that evaporates while you run toward it is the worst kind of
	-- loss in this game, because nobody took it from you.
	--
	-- THE COLLECTOR IS THE NIGHT. WorldCycleService.toNight already sweeps every
	-- pod tagged SeedPod off the map at dusk -- see clearLoosePods -- so the road
	-- is empty again once per cycle, and it is empty for a reason a player can
	-- see rather than on a timer nobody can.
	--
	-- `keep` is what a reserved beginner's pod passes, and it no longer has a
	-- timer to skip. It stays in the signature because TutorialPodService reads
	-- the same flag for its own bookkeeping and the argument order is shared with
	-- `abandoned`; nothing here branches on it any more.
	--==========================================================================
	return pod
end

--==============================================================================
-- VALIDATE EVERYTHING, THEN MUTATE. NOT THE OTHER WAY ROUND.
--
-- This used to call TakePod first and check for a Head afterwards, and TakePod
-- is not a query: it clears the nest slot, starts the wake timer and DESTROYS
-- the pod. So a player with no Head -- mid-respawn, or dying in the same frame
-- -- left the parent waking up over an empty slot with the pod gone and nobody
-- holding it. The prize evaporated.
--
-- Everything that can refuse is checked before anything is touched, and the one
-- step that still cannot be pre-checked -- attaching to the character -- puts
-- the species back on the ground rather than dropping it out of the world.
--==============================================================================
--==============================================================================
-- A REFUSED TAKE NAMES ITS GUARD
--
-- TryTake has ten guards and every one of them used to return a bare `false`.
-- That is silent by design at the player -- there is nothing useful to say to
-- somebody holding E at a pod they cannot have -- but it was silent in the LOG
-- too, which left "I can't take the pod" with ten candidate causes and no way
-- to tell them apart.
--
-- Same fix PlantService got in 704b04b, and the same rate limit: a player who
-- cannot take a pod will hold E at it repeatedly, and ten identical lines a
-- second bury the one line that matters. Weak keys so a player who leaves is
-- collected without a lifecycle hook to forget them.
--==============================================================================
local TAKE_QUIET_SECONDS = 3
local lastTakeRefusal: { [Player]: { [string]: number } } =
	setmetatable({}, { __mode = "k" }) :: any

-- Always returns false, so each guard reads `return refuseTake(...)` and cannot
-- accidentally start allowing what it used to refuse.
local function refuseTake(player: Player, pod: Model, code: string): boolean
	local now = os.clock()
	local seen = lastTakeRefusal[player]
	if not seen then
		seen = {}
		lastTakeRefusal[player] = seen
	end
	if now - (seen[code] or -math.huge) >= TAKE_QUIET_SECONDS then
		seen[code] = now
		log(string.format("%s take refused: %s (%s)", player.Name, code, pod.Name))
	end
	return false
end

--==============================================================================
-- PLANT STORAGE FULL, SAID FROM HERE (2026-09-29)
--
-- The two refusals this file makes for room: a pod that may not be TAKEN, and
-- one that may not be BANKED (see HeldRoom). Said once and then left alone --
-- a take is a held key and a bank is asked for five times a second, so each
-- line has its own quiet time and nothing is said twice inside it. PlantService
-- says the same line for a hatch and a pickup, by the same rule.
--==============================================================================
local STORAGE_QUIET_SECONDS = 2
-- A refused bank is not something the player pressed: it is asked again every
-- fifth of a second for as long as they stand there. One line, and a reminder
-- no sooner than this.
local BANK_QUIET_SECONDS = 30
local lastStorageLine: { [Player]: { [string]: number } } =
	setmetatable({}, { __mode = "k" }) :: any

local function tellStorageFull(player: Player, code: string, quiet: number): boolean
	local now = os.clock()
	local seen = lastStorageLine[player]
	if not seen then
		seen = {}
		lastStorageLine[player] = seen
	end
	if now - (seen[code] or -math.huge) < quiet then
		return false
	end
	seen[code] = now
	log(string.format("%s: refused for room (%s), plant storage full.", player.Name, code))
	ActionRefusal.send(player, code)
	return true
end

--==============================================================================
-- A POD IN BOTH ARMS PUTS THE PLANT AWAY
--
-- A held plant rides in front of the torso in the same two-handed grip a raid
-- pod uses, so taking a pod while holding one drew both: the shell, and a plant
-- through it. The hatch already knew this -- "two channels, one pair of hands"
-- -- and refuses to equip a creature onto a carry. Taking a pod did not.
--
-- So a take moves every PLANT Tool out of the hands and into the Backpack. The
-- plant is not dropped, sold or lost; it is put away, exactly where the hotbar
-- would have put it. And while the pod is carried, a plant arriving in the hands
-- from anywhere -- the hotbar, the number row, a modified client -- is put back
-- a frame later.
--
-- PLANTS ONLY. A bat is a one-hand grip beside the body, and whether a carrier
-- may swing one is a combat rule this does not get to change.
--==============================================================================
local function isPlantTool(child: Instance): boolean
	return child:IsA("Tool") and type(child:GetAttribute("SpeciesId")) == "string"
end

local function putPlantsAway(player: Player): number
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not (character and backpack) then
		return 0
	end
	local moved = 0
	for _, child in ipairs(character:GetChildren()) do
		if isPlantTool(child) then
			-- Reparenting IS the unequip: the engine drops the grip, and the
			-- Tool's own Unequipped handler cuts the CarryWeld (see giveTool).
			child.Parent = backpack
			moved += 1
		end
	end
	return moved
end

CarryService.PutPlantsAway = putPlantsAway

function CarryService.TryTake(player: Player, pod: Model): boolean
	if player.Parent ~= Players then
		return refuseTake(player, pod, "NO_PLAYER")
	end
	--==========================================================================
	-- NOTHING IS TAKEN AFTER DARK
	--
	-- FIRST, above every other refusal, because this is the one that has to win
	-- a race. Dusk sets the phase before it closes the road or clears the nests,
	-- so a hold that completes on the exact frame the lights go out is refused
	-- here rather than half-succeeding into a world that is being torn down
	-- around it -- which is how a player ends up holding a pod that no longer
	-- has a nest, a slot, or a parent to annoy.
	--
	-- Covers loose pods as well as nest pods, because both arrive here. That is
	-- deliberate: a wild pod lying on the road at dusk is about to be destroyed,
	-- and letting somebody scoop it at 00:00 would be a free pod for standing in
	-- the right place rather than for making the run.
	--==========================================================================
	--
	-- A RAIN EVENT'S POD IS THE ONE EXCEPTION (2026-10-02): the event runs on
	-- the owner's clock, its biome is not the road and dusk neither closes nor
	-- clears it, so its pods stay takeable for as long as the event lays them.
	if not GameConfig.isDay() and not CarryService.IsLiveEventPod(pod) then
		return refuseTake(player, pod, "NIGHT")
	end
	-- THE SERVER IS THE AUTHORITY. The client hides the prompt while you are
	-- carrying, and this refuses anyway: hiding a prompt is a courtesy, not a
	-- rule, and a rule enforced only on the client is not a rule.
	--
	-- Hidden is not gone, though: the engine still answers the prompt's key, so
	-- a player who presses E at a nest with a pod already in their arms lands
	-- here having genuinely tried. They are told why; the refusal is unchanged.
	if carried[player] then
		ActionRefusal.send(player, "CARRYING_POD")
		return refuseTake(player, pod, "ALREADY_CARRYING")
	end
	if not pod.Parent then
		return refuseTake(player, pod, "POD_GONE")
	end
	--==========================================================================
	-- SOMEBODY ELSE'S POD IS SOMEBODY ELSE'S
	--
	-- THE SERVER REFUSES. TutorialPodService may also hide the prompt, and that
	-- is a courtesy exactly like the carrying check above says: a rule enforced
	-- only on the client is not a rule, and a forged prompt press arrives here
	-- like any other.
	--
	-- Above the line where the world starts changing, with the other refusals,
	-- so a refused take cannot half-destroy a pod on its way out.
	--==========================================================================
	local owner = tonumber(pod:GetAttribute(RESERVED_FOR))
	if owner and owner ~= player.UserId then
		return refuseTake(player, pod, "RESERVED")
	end
	--==========================================================================
	-- A PLOT PLANT IS NOT LOOT
	--
	-- Checked here, at the top, with everything else that refuses -- above the
	-- line where the world starts changing. Reaching the take path at all would
	-- destroy the plant, set CarryingSpecies (the client's RUN alarm), and then
	-- clear it again the moment the safe-zone poll ran (SAFE) -- the full raid
	-- alarm, in the safe zone, for a pod the player carried home themselves.
	--
	-- TWO INDEPENDENT CHECKS, deliberately. The tag is the fact; the folder is
	-- WHERE THE THING LIVES, which no amount of tag drift can fake. A stale
	-- prompt on a plant must still refuse, and one of these will always catch it.
	--==========================================================================
	if CollectionService:HasTag(pod, GameConfig.Tags.Planted) then
		return refuseTake(player, pod, "IS_PLANTED")
	end
	if pod.Parent.Name == GameConfig.Plot.PlantsFolderName then
		return refuseTake(player, pod, "IN_PLOT")
	end
	local anchor = pod.PrimaryPart
	if not anchor then
		return refuseTake(player, pod, "NO_ANCHOR")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not (humanoid and humanoid.Health > 0) then
		return refuseTake(player, pod, "NO_CHARACTER")
	end
	if not (head and head:IsA("BasePart")) then
		return refuseTake(player, pod, "NO_HEAD")
	end
	--==========================================================================
	-- AND THE ROOT, WHICH IS NOT THE SAME QUESTION AS THE HEAD
	--
	-- This guard was missing, and its absence was not harmless -- it was the
	-- most destructive bug in the file. Below this line `TryTake` builds the
	-- carried pod at `root.CFrame`, and a nil root threw INSIDE the pcall, by
	-- which point NestService.TakePod had already destroyed the pod and emptied
	-- the slot. So the failure handler did what it is supposed to do and put the
	-- species back on the floor a stud in the air, where it despawned in 45
	-- seconds. Reported as "the pods couldn't be taken and floating, it seems
	-- like I'm carrying an invisible pod, the pods despawned too" -- which is
	-- four symptoms of this one line not existing.
	--
	-- A LIVING CHARACTER REALLY CAN HAVE NO ROOT, and the other three guards all
	-- pass while it does. A ragdolled R15 body is seventeen separate assemblies,
	-- so a thrown root goes its own way -- ThrowFX has measured it 780 studs
	-- from the body it belongs to -- and `FallenPartsDestroyHeight` is -500. The
	-- root crosses the plane alone and is destroyed; the Head, the Humanoid and
	-- its Health are all still there on the road. Verified by reading a live
	-- character in Play: HRP=false, Head=true, Health=100.
	--
	-- Refusing rather than falling back to the Head is deliberate. A fallback
	-- would hand a pod to a body that cannot carry it; refusing costs the player
	-- one prompt press and costs the world nothing. NestService respawns the
	-- body that got into this state -- see the end of throwPlayer.
	--==========================================================================
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return refuseTake(player, pod, "NO_ROOT")
	end
	if (head.Position - anchor.Position).Magnitude > TAKE_RANGE + RANGE_SLACK then
		return refuseTake(player, pod, "OUT_OF_RANGE")
	end
	--==========================================================================
	-- NOTHING IS TAKEN THAT COULD NOT BE BANKED (2026-09-29)
	--
	-- The owner's rule: a pod must not be handed over into a record that has no
	-- room to save it. The refusal that enforces it is at the red line (bank),
	-- and it is made HERE FIRST, because a pod refused at the line stays in the
	-- arms -- and a player with a pod in their arms can plant nothing and sell
	-- no single plant, and is shown no prompt at all. They would be carrying a
	-- pod they can neither bank nor put down. Refused at the nest, the pod
	-- stays where it was, and what makes room is still theirs to do.
	--
	-- With the refusals, above the line where the world starts changing: the
	-- pod is untouched and its parent is not woken.
	--
	-- A PLAYER WHOSE SAVE HAS NOT ARRIVED IS REFUSED TOO, AND TOLD NOTHING
	-- (2026-09-30). Until the record is here nobody knows whether the pod could
	-- be banked, and a pod taken into a record that then arrives full could be
	-- neither banked nor put down -- the very thing this block is for. Found in
	-- review. It is not "full", so nothing is said; the take works the moment
	-- the save is in.
	--==========================================================================
	local room, _, known = CarryService.HeldRoom(player)
	if not known then
		return refuseTake(player, pod, "NO_RECORD")
	end
	if room < 1 then
		tellStorageFull(player, "STORAGE_FULL", STORAGE_QUIET_SECONDS)
		return refuseTake(player, pod, "STORAGE_FULL")
	end

	--== EVERYTHING BELOW THIS LINE CHANGES THE WORLD ==--
	-- Read before the take: TakePod destroys the pod, and its attributes with it.
	-- The pod's own rolled weight, read here for the same reason the nest id is:
	-- TakePod destroys the model and its attributes go with it. Falling back to
	-- the species sheet would turn a 9,000 kg cube into a 2 kg one at the moment
	-- of pickup, which is the one moment the player is watching the number.
	local podTier = tonumber(pod:GetAttribute("Tier"))
	local nestId = pod:GetAttribute("NestId")
	local fromNest: string? = if type(nestId) == "string"
		then nestId
		else (if type(pod:GetAttribute("FromNestId")) == "string"
			then pod:GetAttribute("FromNestId") :: string
			else nil)

	-- Read with the others, above the take, for the reason stated there: the
	-- pod and its attributes are about to be destroyed.
	local reservedFor = tonumber(pod:GetAttribute(RESERVED_FOR))
	--==========================================================================
	-- A POD THAT ASKS FOR ITS OWN PICKUP SOUND
	--
	-- CreatureModel stamps PickupSound on a pod whose coming-free is an event in
	-- itself. Today that is the COLOSSAL and nothing else -- a 0.5% roll -- and
	-- the attribute has sat on those pods UNREAD since the tier shipped, because
	-- there was no recording to point it at.
	--
	-- Read here with the rest, for the reason given above them: this attribute
	-- dies with the pod a few lines down, and the sound plays after that.
	--==========================================================================
	local pickupCue = pod:GetAttribute("PickupSound")
	-- Only ever on a loose pod. A nest pod is always a fresh attempt.
	local abandoned = pod:GetAttribute(ATTR.GuardianAbandoned) == true
	-- A secret encounter's identity rides with its pod (see Held.secretId).
	local secretAttr = pod:GetAttribute("SecretId")
	local secretId: string? = if type(secretAttr) == "string" then secretAttr else nil
	-- So does a Rain event's (Held.eventId).
	local eventAttr = pod:GetAttribute(EVENT_ID)
	local eventId: number? = if type(eventAttr) == "number" then eventAttr else nil

	-- A NEST theft (not a dropped pod picked back up) is what starts a raid for
	-- the launch analytics; read now, before the pod is gone.
	local nestTheft = pod:GetAttribute("NestId") ~= nil
	local species: SeedData.Species?
	if pod:GetAttribute("NestId") then
		-- Nest-owned: NestService decides, because taking one is what wakes the
		-- parent, and it is the only thing that can lose the race between two
		-- players reaching for the same pod -- it checks pods[slot] ~= pod, so
		-- only one of them can win.
		species = NestService.TakePod(pod, player)
	else
		species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
		if species then
			pod:Destroy()
			-- Picking a dropped pod back up wakes the parent it came from. Being
			-- caught once must not make the rest of the raid free.
			--
			-- Uses the value read BEFORE the destroy: reading an attribute off a
			-- destroyed instance happens to work today and is not something to
			-- build on.
			if fromNest then
				NestService.Provoke(fromNest, player, secretId)
			end
		end
	end
	if not species then
		return false
	end

	local taken = species :: SeedData.Species
	local takenTier = math.clamp(podTier or taken.Tier, 1, SeedData.TierCount)
	local ok, err = pcall(function()
		-- Found and checked above, not re-found and cast here. The `:: BasePart`
		-- that used to be on this line asserted away exactly the nil that was
		-- destroying pods.
		local model = CreatureModel.BuildPod(taken, takenTier, root.CFrame, character)
		attachInFront(model, root, takenTier, taken)
		-- CarriedPod ONLY. It used to inherit SeedPod from the builder as well,
		-- so the pod on your own head wore a Take prompt.
		CollectionService:AddTag(model, GameConfig.Tags.CarriedPod)
		if abandoned then
			model:SetAttribute(ATTR.GuardianAbandoned, true)
		end
		if secretId then
			model:SetAttribute("SecretId", secretId)
		end
		if eventId then
			model:SetAttribute(EVENT_ID, eventId)
		end
		carried[player] = {
			species = taken,
			tier = takenTier,
			model = model,
			fromNest = fromNest,
			reservedFor = reservedFor,
			guardianAbandoned = abandoned,
			secretId = secretId,
			eventId = eventId,
		}
	end)

	if not ok or not carried[player] then
		-- The pod is already out of the world and the parent may already be
		-- waking. Losing the species here would make a raid randomly worthless,
		-- so it goes back on the ground where anybody can pick it up.
		warn("[Seed/CarryService] could not attach " .. taken.Id .. ": " .. tostring(err))
		carried[player] = nil
		local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
		if map then
			local loose = spawnLoose(taken, takenTier,
				CFrame.new(anchor.Position + Vector3.new(0, 1, 0)), map,
				nil, nil, nil, abandoned)
			-- A secret keeps its encounter on the way back to the ground, and an
			-- event pod its event.
			if secretId then
				loose:SetAttribute("SecretId", secretId)
			end
			if eventId then
				loose:SetAttribute(EVENT_ID, eventId)
			end
		end
		return false
	end

	-- The travel budget starts HERE, at the nest, not at the next check: a carrier
	-- who teleports in the same frame as the take is measured from where they
	-- took it. No slack if they were carrying moments ago. See CarryGuard.
	guards[player] = CarryGuard.new(root.Position,
		os.clock() - (guardEnded[player] or -math.huge) < CarryGuard.SlackCooldownSeconds)
	-- Only the pod in both arms: a plant that was being held goes to the Backpack.
	putPlantsAway(player)
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	--==========================================================================
	-- THE SHELL COMING FREE, NOT THE BUTTON
	--
	-- On the THIEF rather than on the pod, because the pod that was on the
	-- ground has just been destroyed and the one in their hands is welded to
	-- their head -- either way the sound is coming from the same place, and the
	-- root is the one that is certain to still exist a frame from now.
	--
	-- Positional, so a player raiding a nest thirty studs away is audible. The
	-- whole road is one corridor and everybody walks down it; hearing somebody
	-- else's raid is the point.
	--==========================================================================
	local thiefRoot = character:FindFirstChild("HumanoidRootPart")
	if thiefRoot and thiefRoot:IsA("BasePart") then
		-- The pod's own cue if it named one AND that row exists, the ordinary
		-- shell otherwise. A pod naming a cue nobody wired sounds like every
		-- other pod, which is exactly what it did yesterday.
		SoundKit.emit(if type(pickupCue) == "string" and SoundKit.has(pickupCue)
			then pickupCue
			else "TakePod", thiefRoot)
	end
	PlayerDataService.RecordTutorial(player, "steal")
	if nestTheft then
		local profile = PlayerDataService.Get(player)
		Metrics.raidStarted(player, taken.Biome, if profile then profile.Speed else 0)
	end
	return true
end

--==============================================================================
-- DROPPING
--
-- A dropped pod becomes a loose pod anybody can take. That is the PvP hook
-- waiting to be switched on: the moment a carrier can be made to drop, what
-- they are carrying stops being a prize and becomes a target.
--==============================================================================
function CarryService.Drop(player: Player, at: Vector3?): boolean
	local held = carried[player]
	if not held then
		return false
	end
	carried[player] = nil

	local where = at
	if not where then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		where = if root and root:IsA("BasePart") then root.Position else nil
	end
	if held.model.Parent then
		held.model:Destroy()
	end
	local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
	if where and map then
		local character = player.Character
		-- Only the character. Excluding the map would exclude the ground, which
		-- is the one thing the cast is looking for.
		local ground = groundUnder(where, if character then { character } else {})
		-- Still theirs on the floor. A dropped ordinary pod is fair game and
		-- stays that way; a dropped RESERVED one keeps its owner, so the run
		-- back for it is a recovery rather than a race.
		local loose = spawnLoose(held.species, held.tier, CFrame.new(ground + Vector3.new(0, 0.05, 0)),
			map, held.fromNest, held.reservedFor, nil, held.guardianAbandoned)
		-- The encounter's identity stays with the pod on the ground, and so
		-- does the weather event that laid it.
		if held.secretId then
			loose:SetAttribute("SecretId", held.secretId)
		end
		if held.eventId then
			loose:SetAttribute(EVENT_ID, held.eventId)
		end
	end

	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- CROSSING THE RED LINE BANKS IT
--
-- Reaching the safe zone is the moment a raid PAYS, and until now nothing
-- marked it -- you simply stopped being chased. Stepping over the line converts
-- the pod on your head into a Tool in your hotbar: it stops being a thing that
-- can be knocked out of your hands and becomes a thing you own.
--
-- That is also what finally makes the walk home mean something. Everything
-- between the nest and the line is at risk; everything past it is banked.
--
-- The test is MapService.IsInSafeZone, the same one the whole game uses, so the
-- line painted on the grass and the line the code checks are the same line.
--==============================================================================
--==============================================================================
-- ONE WAY TO PUT SOMETHING IN A PLAYER'S HANDS
--
-- Two things end up in the hotbar and they must not be carried two different
-- ways: a pod you banked, and the creature that comes out when you hatch one.
-- This is everything they share -- the Handle weld, the weight tag, and the
-- fight with the engine's own grip -- so the only thing a caller decides is
-- WHAT the model is and HOW FAR OUT it rides.
--
-- The model handed in is consumed: its PrimaryPart becomes the Handle and every
-- other part is welded to it.
--==============================================================================
local function giveTool(player: Player, model: Model, species: SeedData.Species,
	tier: number, grip: CFrame, hatched: boolean, revealAt: number?): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	local handle = model.PrimaryPart
	if not (backpack and handle) then
		model:Destroy()
		return nil
	end

	--==========================================================================
	-- A BANKED POD IS STILL ANONYMOUS
	--
	-- This named the slot after the species, so crossing the red line printed
	-- NUBKIN in the toolbar before the shell had opened -- and the whole design
	-- rests on that not happening. Pods are coloured by WEIGHT, so two Commons
	-- arrive in identical shells and which one you got is not knowable until it
	-- hatches. The Garden says ??? on a buried pod for exactly this reason, and
	-- the hotbar was quietly undoing it one slot along.
	--
	-- The HATCH is the reveal. Until then the slot says what the Index says.
	--
	-- SpeciesId stays on the Tool -- planting has to know what to build. The
	-- player just cannot read it off the toolbar.
	--==========================================================================
	local tool = Instance.new("Tool")
	tool.Name = if hatched then species.Name else "???"
	--==========================================================================
	-- THE TOOLTIP MUST NOT SAY A RARITY IT DOES NOT MEAN
	--
	-- This printed SeedData.RarityForTier(kg) -- the WEIGHT band. There are two
	-- vocabularies in this game and they share four words:
	--
	--     FORM rarity    Common Uncommon Rare Epic          how often a shape
	--                                                       turns up. The Index
	--                                                       spells this one.
	--     WEIGHT band    Common .. Epic .. Mythic .. Divine what THIS one
	--                                                       weighs. The pod
	--                                                       wears this as its
	--                                                       COLOUR.
	--
	-- So the hotbar was calling a 1,937 kg Petalpip "Mythic" while the Index
	-- called Petalpip "Common", and a 5 kg Bellchime "Common" while the Index
	-- called it "Epic". Both true, both about different things, and the player
	-- has no way to tell which -- so the word was simply wrong twice over.
	--
	-- The design already settled who owns what: the WORD belongs to the form
	-- and the COLOUR belongs to the weight. This is the one place they crossed.
	--
	--     hatched     the form's rarity, which is exactly what the Index says
	--     unhatched   no rarity word at all
	--
	-- Not the form's rarity on an unhatched pod either, and not because of
	-- tidiness: Epic means Bellchime in Greenhollow, so printing it would name
	-- the species through the back door on the one item that must stay ???.
	-- Its weight band is still legible -- it is the colour of the shell in the
	-- player's hands.
	--==========================================================================
	-- A Secret has its rarity and no size tier (the owner's rule, 2026-10-02):
	-- its tier is implementation-only (SeedData.SecretTier) and never shown.
	-- A Rain pod names its POD and that pod's rarity, never the creature
	-- inside; Pod 1 and Pod 3 have no size tier, Pod 2 shows its own.
	local rainPod = SeedData.RainPodOf(species)
	tool.ToolTip = if species.Secret == true
		then (if hatched then "Secret" else "Secret pod")
		elseif rainPod and not hatched then (if rainPod.Sized
			then string.format("%s  ·  %s  ·  %d tier", rainPod.Name, rainPod.Rarity, tier)
			else string.format("%s  ·  %s", rainPod.Name, rainPod.Rarity))
		elseif hatched and SeedData.Unsized(species) then species.Rarity
		elseif hatched then string.format("%s  ·  %d tier", species.Rarity, tier)
		else string.format("Unhatched pod  ·  %d tier", tier)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("SpeciesId", species.Id)
	tool:SetAttribute(ATTR.CarryingKg, tier)
	-- WHICH OF THE TWO THIS IS. A pod goes in the ground and starts a clock; a
	-- hatched creature goes in the ground already earning. PlantService reads
	-- this to know which, and it is the only difference between them.
	tool:SetAttribute("Hatched", hatched)
	--==========================================================================
	-- A HATCH'S PLANT IS A SECRET UNTIL ITS ROLL IS OVER (2026-09-29)
	--
	-- Stamped BEFORE the Tool is parented, so no client ever sees this Tool
	-- without it: the hotbar and the Bag draw it as the pod it came out of
	-- until the time written here (HatchRoll.sealed). It is the Tool's name
	-- and species that are kept off the screen, not the Tool that is kept from
	-- the player -- it is theirs, and on their record, from this moment.
	--==========================================================================
	if hatched and revealAt then
		tool:SetAttribute(REVEAL_AT, revealAt)
	end

	handle.Name = "Handle"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			d.CanQuery = false
			if d ~= handle then
				local w = Instance.new("WeldConstraint")
				w.Part0 = handle
				w.Part1 = d
				w.Parent = handle
				d.Parent = tool
			end
		end
	end
	handle.Parent = tool
	model:Destroy()

	--==========================================================================
	-- THE SAME GRIP AFTER THE LINE AS BEFORE IT
	--
	-- A Tool is welded to the right HAND by a weld Roblox makes on equip, which
	-- holds the pod out in one fist. That is a different game from the
	-- two-handed haul the raid uses, and a pod you own should not be carried
	-- differently from a pod you are stealing.
	--
	--==========================================================================
	-- THE ENGINE PARENTS THAT WELD TO THE HAND, NOT TO THE CHARACTER
	--
	-- Measured on a live equipped Tool in a real session:
	--
	--   joint "RightGrip" (Weld) parented to RightHand | Part0=RightHand  Part1=Handle
	--   joint "CarryWeld" (Weld) parented to Handle    | Part0=RootPart   Part1=Handle
	--
	-- BOTH of them, at once. This used to look for the hand weld with
	-- `character:FindFirstChild("RightGrip")`, which searches DIRECT CHILDREN
	-- only -- so it never found it, never destroyed it, and the pod ended up
	-- rigidly welded to the fist and to the root simultaneously. Measured 0.22
	-- studs from the right hand: over-constrained, with the hand winning.
	--
	-- Two fixes, because there were two ways to lose:
	--
	--   WHERE   scan the character's DESCENDANTS for anything jointed to this
	--           handle that is not ours, rather than guessing a parent.
	--   WHEN    the engine builds that weld asynchronously after Equipped fires,
	--           so one deferred destroy can also simply be early. A
	--           DescendantAdded watch stays live for as long as the tool is held
	--           and re-asserts the root weld if a hand weld turns up later.
	--==========================================================================
	local function fitToRoot(character: Model)
		if handle.Parent ~= tool then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		-- Anything holding this handle that we did not make.
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("JointInstance") and d.Name ~= "CarryWeld" and d.Part1 == handle then
				d:Destroy()
			end
		end
		if not handle:FindFirstChild("CarryWeld") then
			-- Placed before the weld exists, exactly as attachInFront does, so
			-- it arrives in front of the chest rather than snapping there.
			handle.CFrame = root.CFrame * grip
			local weld = Instance.new("Weld")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = handle
			weld.C0 = grip
			weld.Parent = handle
		end
	end

	local watching: RBXScriptConnection? = nil

	table.insert(serviceConnections, tool.Equipped:Connect(function()
		local character = tool.Parent
		if not (character and character:IsA("Model")) then
			return
		end
		local asModel = character :: Model
		if watching then
			watching:Disconnect()
		end
		watching = asModel.DescendantAdded:Connect(function(d)
			-- Part0/Part1 are not necessarily assigned yet when this fires, so
			-- the test is deliberately loose and the real check happens inside
			-- fitToRoot a frame later.
			if d:IsA("JointInstance") and d.Name ~= "CarryWeld" then
				task.defer(fitToRoot, asModel)
			end
		end)
		fitToRoot(asModel)
		task.defer(fitToRoot, asModel)
	end))

	--==========================================================================
	-- UNEQUIPPING HAS TO CUT THE ROOT WELD, OR THE TOOL NEVER LEAVES
	--
	-- CarryWeld joins the Handle to the HumanoidRootPart, and it is parented to
	-- the Handle -- so it goes to the Backpack with it and keeps pointing at a
	-- root that is still in the workspace. Two things went wrong with that:
	--
	--   NOW    a joint between a part in the Backpack and a part in the world is
	--          not a thing the engine has a sensible answer for, and the pod
	--          could stay drawn in front of a player who had put it away.
	--   LATER  fitToRoot only builds a weld `if not handle:FindFirstChild
	--          ("CarryWeld")`. The stale one is still there on re-equip, so it
	--          is never rebuilt -- and after a respawn its Part0 is a root that
	--          no longer exists. Equip, die, equip again, and the tool is held
	--          by nothing.
	--
	-- So the weld is cut here and rebuilt from scratch on the next Equipped.
	-- Nothing else about the tool changes: it is still in the hotbar, still
	-- carries its kg and its Hatched flag, and is still not droppable.
	--==========================================================================
	table.insert(serviceConnections, tool.Unequipped:Connect(function()
		if watching then
			watching:Disconnect()
			watching = nil
		end
		local weld = handle:FindFirstChild("CarryWeld")
		if weld then
			weld:Destroy()
		end
	end))
	tool.Parent = backpack
	return tool
end

--==============================================================================
-- A ROLL THAT OUTLIVES THE BODY (2026-09-29)
--
-- A hatched plant is a secret until its roll is over, and the secret is written
-- on its Tool. A death, a reset or a LoadCharacter destroys that Tool, and the
-- rebuild that follows makes a new one from the record -- which would come back
-- named, in the hotbar, while the roll it belongs to is still running.
--
-- So the time is kept here as well, by player, and a rebuilt plant of the same
-- species and tier is given what is left of it.
--
-- IT DECIDES NOTHING ABOUT WHAT IS BUILT. That is the record's (profile.Held),
-- and this is never saved: a time that has passed is dropped, and a player who
-- leaves takes the whole list with them.
--==============================================================================
local Sealed = {}
Sealed.byPlayer = {} :: { [Player]: { { id: string, tier: number, at: number } } }

-- A hatch's plant, and the server time it may be shown.
function Sealed.note(player: Player, id: string, tier: number, at: number)
	local now = workspace:GetServerTimeNow()
	local list = Sealed.byPlayer[player] or {}
	for i = #list, 1, -1 do
		if list[i].at <= now then
			table.remove(list, i)
		end
	end
	table.insert(list, { id = id, tier = math.floor(tier), at = at })
	Sealed.byPlayer[player] = list
end

-- For a plant being rebuilt: the time it is still a secret until, taken off the
-- list -- or nil, when it never was one or its time has come.
function Sealed.take(player: Player, id: string, tier: number): number?
	local list = Sealed.byPlayer[player]
	if not list then
		return nil
	end
	local now = workspace:GetServerTimeNow()
	local found: number? = nil
	for i = #list, 1, -1 do
		local row = list[i]
		if row.at <= now then
			table.remove(list, i)
		elseif found == nil and row.id == id and row.tier == math.floor(tier) then
			found = row.at
			table.remove(list, i)
		end
	end
	if #list == 0 then
		Sealed.byPlayer[player] = nil
	end
	return found
end

--==============================================================================
-- A HATCHED CREATURE IS CARRIED, NOT LEFT IN THE GROUND
--
-- Hatching does not put the creature where the pod was. It hands it to you and
-- you choose where it goes, which is the whole reason placement is by click --
-- the spot the egg happened to sit in is not the spot you want the plant.
--
-- HELD BY THE BASE, AND HELD LOW. A creature's PrimaryPart is a flat invisible
-- plate at its ground contact, so the weld lands at the bottom of the thing and
-- it stands up out of your hands rather than hanging from its middle. It is
-- axis-aligned, which is what keeps it standing: this used to be a cylinder
-- rolled ninety degrees and the plant was carried on its side. The drop puts that base near your
-- feet: at the top of the weight range this is a thirty-stud plant, and welding
-- its middle to your chest would fill the screen with stem.
--
-- The reach is measured off the MODEL rather than off PodDiameter, because a
-- creature is a different shape from the pod it came out of -- a Bellchime's
-- skirt is far wider than its shell ever was.
--==============================================================================
--==============================================================================
-- AND WHY IT MAY BE ASKED TO WAIT
--
-- `equipAfter` is the hatch's, and nothing else passes it. A hatch now plays a
-- reveal over the pod's grave -- the real creature, coming up out of the glow --
-- and equipping the Tool the instant it is created replaces that with the same
-- plant held at arm's length in front of the camera. So the hatch asks for the
-- hand a second later, and the Tool is theirs the whole time.
--
-- EVERY OTHER CALLER IS UNCHANGED: nil means equip now, which is what a pickup
-- and a rejoin have always done.
--
-- `revealAt` is the hatch's too (2026-09-29): the server time the plant may be
-- shown, written on the Tool until then and taken off when it comes. A pickup
-- and a rejoin pass none, and their Tools say what they are at once. The one
-- other caller that passes it is the rebuild after a death, for a plant whose
-- roll was still running when its Tool went with the body (see Sealed).
--
-- `onRecord` is the hatch's and the pickup's: write this plant's row now
-- (RecordHatched).
--
--==============================================================================
-- A PLANT IS HANDED OVER AND RECORDED, OR IT IS NEITHER (2026-09-29)
--
-- The owner's decisions, for a record that is full: "refuse the hatch and leave
-- the pod planted and ready until the player makes room", and a pickup "must
-- not hand over an item that cannot be saved. Preserve the item in its prior
-- safe state" -- the plant stays planted.
--
-- So with `onRecord` the answer is no BEFORE anything is built -- no record to
-- write on, or no room on it (HeldRoom) -- and the reason rides back beside it,
-- for PlantService to say to the player. And when the row cannot be written
-- after all, the Tool that was just made is taken back: nothing is left in the
-- hands that is on nobody's record.
--
-- A HATCH AND A PICKUP ARE COUNTED; A REBUILD IS NOT. A rebuild passes no
-- `onRecord` and is handed over as it always was: it is the record being put
-- back, and refusing it would be the record losing a plant.
--==============================================================================
function CarryService.GiveHatched(player: Player, species: SeedData.Species,
	tier: number, equipAfter: number?, revealAt: number?, onRecord: boolean?): (boolean, string?)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false, nil
	end
	if onRecord == true then
		local room, _, known = CarryService.HeldRoom(player)
		if not known then
			return false, "NO_RECORD"
		end
		if room < 1 then
			return false, "STORAGE_FULL"
		end
	end
	local model = CreatureModel.BuildCreature(species, tier,
		CreatureModel.STAGE_GROWN, CFrame.new(), backpack)

	--==========================================================================
	-- FULL SIZE. A PLANT IS THE SAME PLANT IN YOUR HANDS AS IN THE GROUND.
	--
	-- This briefly scaled heavy creatures down to something a person could
	-- plausibly hold, and that was the wrong fix for a real problem. Weight is
	-- the whole game and SIZE IS HOW WEIGHT IS READ -- shrinking a 9,000 kg
	-- plant to the same silhouette as a 200 kg one at the exact moment the
	-- player is deciding where to put it takes the number away from them at the
	-- worst possible moment. A plant you pick up must be the plant you put down.
	--
	-- What was actually wrong was the DROP, below: the base sat at foot level,
	-- so the thing read as standing on the ground beside the player rather than
	-- being carried. That is fixed there, and it is fixed at every size.
	--
	-- Do not reintroduce a carried scale. If a 35-stud Bellchime is unwieldy in
	-- the hands, that is the cost of a 35-stud Bellchime, and the player chose
	-- it when they hauled a 10,000 kg pod home.
	--==========================================================================
	local size = model:GetExtentsSize()
	local halfWidth = math.max(size.X, size.Z) * 0.5
	local reach = GameConfig.Carry.GripForwardBase + halfWidth
	--==========================================================================
	-- HELD AT THE HIP, NOT AT THE ANKLE
	--
	-- THIS is what made carrying feel wrong. The old drop of -2.2 put the base
	-- at roughly foot level, so the plant stood on the floor next to the player
	-- and read as a separate object that happened to follow them around -- and
	-- on a small one it looked dropped rather than held.
	--
	-- One stud below the chest puts the base at about hip height, which is the
	-- one arrangement that reads as CARRIED at every size: a 1.5-stud Nubkin is
	-- at chest level in front of you, and a 35-stud Bellchime is visibly lifted
	-- clear of the ground rather than planted in it.
	--==========================================================================
	-- A secret plant goes over the head like its pod (gripFor); every other
	-- creature is held low in front, by its base.
	local grip = if (species :: any).Carry == "overhead"
		then CFrame.new(0, GameConfig.Carry.OverheadLift, 0)
		else CFrame.new(0, GameConfig.Carry.GripDrop - 1.0, -reach)
	-- Read as a claim, like everything that is a time: not a number, already
	-- past, or further off than any roll runs, and there is no secret to keep.
	local sealedUntil = tonumber(revealAt)
	if sealedUntil then
		local left = sealedUntil - workspace:GetServerTimeNow()
		if left ~= left or left <= 0 or left > GameConfig.Plant.Hatch.Roll.MaxHideSeconds then
			sealedUntil = nil
		end
	end
	local tool = giveTool(player, model, species, tier, grip, true, sealedUntil)
	if not tool then
		return false, nil
	end
	-- `onRecord` is the hatch's and the pickup's: this plant is new to the
	-- hands, and its row is written now, in the same call that made its Tool. A
	-- rebuild passes none -- a rebuilt plant is on the record already, which is
	-- where it was rebuilt from.
	--
	-- NOT WRITTEN, NOT GIVEN. The room was counted before the Tool was built, so
	-- this is the write itself failing -- the profile gone in between -- and the
	-- Tool goes back before anybody has been told a plant hatched.
	if onRecord == true and not CarryService.RecordHatched(player, species, tier) then
		tool:Destroy()
		return false, "NOT_RECORDED"
	end
	-- The secret runs out on the server's clock: the attribute comes off, which
	-- is the change every hotbar and Bag repaints on. A Tool that has gone by
	-- then -- planted, sold, lost with a body -- has nothing to take off.
	if sealedUntil then
		Sealed.note(player, species.Id, tier, sealedUntil)
		task.delay(math.max(sealedUntil - workspace:GetServerTimeNow(), 0), function()
			if tool.Parent and tool:GetAttribute(REVEAL_AT) ~= nil then
				tool:SetAttribute(REVEAL_AT, nil)
			end
		end)
	end
	--==========================================================================
	-- THE REACH IS WRITTEN DOWN, BECAUSE CarryPose CANNOT DERIVE IT
	--
	-- CarryPose aims the arms at whatever is being carried, and for a raid pod
	-- it works that out from SeedData.GripForward(kg) -- which is a POD's
	-- radius. A creature is a completely different shape from the shell it came
	-- out of -- a Bellchime's skirt is four times its pod's diameter -- so the
	-- pod formula points the arms at empty air.
	--
	-- One number, measured once here where the model still exists, and read
	-- straight off the Tool there.
	--==========================================================================
	tool:SetAttribute("GripReach", reach)
	--==========================================================================
	-- PUT IT IN THEIR HANDS, NOT JUST IN THE BAG
	--
	-- The shell has just burst in front of them and the thing that came out is
	-- what they have been waiting for. Landing it silently in slot four and
	-- making them go and find it throws away the only moment in the loop that
	-- is a reveal.
	--
	-- Equipping is best-effort: mid-respawn there is no Humanoid to equip with,
	-- and a creature sitting safely in the hotbar is a far better failure than
	-- one that was never handed over.
	--==========================================================================
	--
	-- NOT WHILE THEY ARE RUNNING A RAID POD HOME, though. That pod is welded to
	-- the same root at the same grip -- two channels, one pair of hands -- and
	-- equipping on top of it would stack two objects in the same place. The
	-- creature still lands in the hotbar; it just waits until their hands are
	-- their own again.
	--
	-- AND IT IS STILL BEST-EFFORT WHEN IT WAITS. Held back for a reveal, every
	-- one of those conditions can have changed by the time the hand is free:
	-- they may have died, left, picked up a raid pod, opened their own hotbar and
	-- chosen something else, or planted the thing already. Each is checked again
	-- at the moment of the equip, and any of them simply leaves the plant in the
	-- hotbar -- which is where the player can see it.
	--
	-- NOTHING IS EVER UNEQUIPPED for this. A player who chose a bat during the
	-- reveal keeps the bat.
	-- The checks live in EquipIfFree (2026-10-02), which the admin console's
	-- EQUIP NOW asks too: the same rules for both, unchanged here.
	local function equipNow()
		CarryService.EquipIfFree(player, tool)
	end

	local wait = tonumber(equipAfter) or 0
	if wait < 0 then
		-- Not equipped at all: into the Bag only. The admin console's grant with
		-- EQUIP NOW off (2026-10-02) is the only caller that asks for this.
	elseif wait > 0 then
		task.delay(wait, equipNow)
	else
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid and not CarryService.IsCarrying(player) then
			pcall(function()
				humanoid:EquipTool(tool)
			end)
		end
	end
	--==========================================================================
	-- NO LOG HERE. THIS FUNCTION DOES NOT KNOW WHY IT WAS CALLED.
	--
	-- It said "hatched a N kg X", and it is called by three different things:
	-- the hatch, the Garden's PICK UP, and the restore that puts a saved hotbar
	-- back on join. Two of those never hatched anything -- a pickup logged
	-- "hatched" immediately followed by "picked up", and a rejoin claimed five
	-- hatches that never happened.
	--
	-- Handing over a Tool is all this does. The caller knows what it means and
	-- says so itself.
	--==========================================================================
	return true, nil
end

local function bank(player: Player): boolean
	local held = carried[player]
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not (held and character and backpack) then
		return false
	end
	--==========================================================================
	-- NOT BANKED INTO A RECORD THAT CANNOT HOLD IT (2026-09-29)
	--
	-- A banked pod is a Tool, and a Tool the record has no row for is gone at
	-- the next death or rejoin. The owner's rule: it "must not hand over an item
	-- that cannot be saved. Preserve the item in its prior safe state" -- so the
	-- pod STAYS IN THE ARMS, exactly as it was a step before the line, and this
	-- is asked again a fifth of a second later for as long as they stand in the
	-- Safe Zone. The moment there is room it is banked, with nothing pressed.
	--
	-- A take is refused at the nest for the same reason (TryTake), and a pod in
	-- the arms keeps its place against a hatch, a pickup and a pod given
	-- (HeldRoom), so this is the backstop: the record filling some other way on
	-- the run home, such as a save that already held more than the limit.
	--
	-- No record yet -- the save still arriving -- is not room either: the pod
	-- waits in the arms for it, and nothing is said.
	--==========================================================================
	local room, _, known = CarryService.HeldRoom(player, true)
	if not known then
		return false
	end
	if room < 1 then
		tellStorageFull(player, "STORAGE_FULL_BANK", BANK_QUIET_SECONDS)
		return false
	end

	local species = held.species
	local tier = held.tier
	-- Built fresh as the Tool's handle rather than reusing the carried model:
	-- that one is welded to a head and unanchored, and a Tool wants a part named
	-- Handle that it owns outright.
	local pod = CreatureModel.BuildPod(species, tier, CFrame.new(), backpack)
	local tool = giveTool(player, pod, species, tier, gripFor(tier, species), false)
	if not tool then
		return false
	end
	-- ON THE RECORD, OR NOT HANDED OVER: the row is written now, in the call
	-- that made the Tool, and a row that cannot be written takes the Tool back
	-- and leaves the pod in the arms.
	if not CarryService.RecordPod(player, species, tier) then
		tool:Destroy()
		return false
	end
	-- The same number CarryPose reads off a hatched creature. A pod's reach IS
	-- derivable from its weight, but having two ways to answer one question is
	-- how the arms and the object drift apart.
	tool:SetAttribute("GripReach", SeedData.GripForward(tier))
	-- A secret banked is a secret encounter over: the spot and its platform
	-- are free again (NestService).
	if held.secretId then
		pcall(NestService.SecretResolved, held.secretId, "banked by " .. player.Name)
	end

	-- Consumed, not dropped: it is in the hotbar now, not on the floor.
	if held.model.Parent then
		held.model:Destroy()
	end
	carried[player] = nil
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	-- Tell the client it MADE IT. Dropping and banking both end with
	-- CarryingSpecies going nil, so without this the alert has no way to tell a
	-- success from a mugging.
	player:SetAttribute(ATTR.BankedCount,
		(player:GetAttribute(ATTR.BankedCount) or 0) + 1)
	log(string.format("%s banked a %s (%d tier).", player.Name, species.Name, tier))
	PlayerDataService.RecordTutorial(player, "bank")
	Metrics.raidEnded(player, "banked")
	return true
end

-- Exposed for the spec, which cannot stand a stand-in player on the red line;
-- nothing else calls it. The poll in Start is the only thing that banks a pod
-- in the game, and it asks where the carrier is standing first.
CarryService.Bank = bank

--==============================================================================
-- THE NIGHT EJECTION FORFEIT
--
-- A player caught inside a biome at nightfall is moved to the safe side of the
-- road entrance. Without this, that is a FREE EXTRACTION: stand deep in
-- Starbloom holding a 9,000 kg pod, wait for the clock, and the game carries you
-- home past every parent and every rival on the road. The run is the price of
-- the pod, and a night that paid it for you would make the last minute of every
-- day the only sensible time to raid.
--
-- SCOPED AS NARROWLY AS IT IS POSSIBLE TO SCOPE IT. It destroys ONE thing: the
-- pod model welded to this player right now. It does not touch the Backpack, so
-- every banked pod and every hatched creature is untouched; it does not touch
-- the plot, so nothing planted is at risk; and it cannot run at all on somebody
-- who is not carrying. Those are the three kinds of property a player can lose
-- for real, and none of them is reachable from here.
--
-- Returns what was forfeited so the caller can say so rather than guess.
--==============================================================================
--==============================================================================
-- TAKING IT OFF THEM, WITHOUT PUTTING IT ANYWHERE
--
-- The one mutation shared by the nightfall forfeit and a guardian's
-- confiscation: clear the slot, destroy the model welded to this body, publish,
-- re-derive the walk speed. What the caller does with the returned record is
-- the only thing that differs between them.
--
-- IT MUST NOT YIELD, and every line here is chosen so that it does not. That is
-- the whole of the race protection: `carried[player]` is read and cleared
-- inside one resumption, so two guardians reaching the same player in the same
-- frame cannot both come away with a pod, and a player planting or banking in
-- that frame either got there first or did not.
--==============================================================================
local function takeAway(player: Player): Held?
	local held = carried[player]
	if not held then
		return nil
	end
	carried[player] = nil
	if held.model and held.model.Parent then
		held.model:Destroy()
	end
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return held
end

function CarryService.ForfeitCarry(player: Player, why: string?): (string?, number)
	local held = takeAway(player)
	if not held then
		return nil, 0
	end
	-- A forfeited secret leaves the road for good: the encounter is over.
	if held.secretId then
		pcall(NestService.SecretResolved, held.secretId, "forfeited: " .. (why or "nightfall"))
	end
	log(string.format("%s forfeited a %d tier %s: %s.", player.Name, held.tier, held.species.Name,
		why or "caught inside a biome at nightfall"))
	-- Nightfall is the forfeit with no reason given; anything else (an admin
	-- progress reset) is "other".
	Metrics.raidEnded(player, if why == nil then "night" else "other")
	return held.species.Id, held.tier
end

--==============================================================================
-- CONFISCATED. IT IS THE GUARDIAN'S NOW.
--
-- Being caught in the last three biomes does not scatter the pod on the road --
-- the guardian takes it and walks it home. So this deliberately does NOT drop:
-- CarryService.Drop would put a takeable pod on the floor at the moment of the
-- hit, which is the behaviour this replaces, and for one frame there would be
-- two of them.
--
-- Ordering matters at the call site and is worth stating here, because it is
-- not obvious from either end: the throw sets PlatformStand, and the ragdoll
-- watcher below turns that into a Drop. Confiscating BEFORE the throw leaves
-- that watcher with nothing to drop, which is why the pod does not land on the
-- road as well as going home. Confiscating after would produce both.
--
-- Returns the whole record rather than an id and a weight, because the haul has
-- to know which nest the pod came off to put it back in the right ring.
--==============================================================================
function CarryService.Confiscate(player: Player): Held?
	local held = takeAway(player)
	if not held then
		return nil
	end
	log(string.format("%s lost a %d tier %s: confiscated by a guardian.",
		player.Name, held.tier, held.species.Name))
	Metrics.raidEnded(player, "captured")
	return held
end

--==============================================================================
-- A CONFISCATING GUARDIAN'S CATCH, RESOLVED IN ONE RESUMPTION
--
-- GuardianCatch decides; this applies the decision to the one pod concerned.
-- NOTHING HERE YIELDS, so the read of `carried[player]`, the roll, the mark and
-- the take all happen before any other thread runs. Two guardians reaching the
-- same carrier in the same frame therefore cannot both roll or both take:
--
--   first "confiscated" -> hand emptied -> second sees "none", throws only
--   first "left"        -> pod marked   -> second sees "abandoned", no roll
--
-- On "left" and "abandoned" the pod stays in the victim's hands ON PURPOSE. The
-- guardian's throw sets PlatformStand, and the watcher in onCharacterAdded turns
-- that into the one canonical Drop, which makes the one loose pod and carries
-- the flag onto it. Nothing here drops, so nothing here can drop twice.
--
-- `hauling` is asked first and returns before the pod is even read: a guardian
-- whose hands are full can never roll or mark somebody else's pod.
--
-- `roll` is for specs. Play tests force it through SetGuardianRollOverride,
-- which DebugService's ForceGuardianRoll reaches.
--==============================================================================
local catchRandom = Random.new()
local rollOverride: number? = nil

-- Forces every roll until cleared with nil. Refuses anything outside [0, 1).
function CarryService.SetGuardianRollOverride(value: number?): boolean
	if value == nil then
		rollOverride = nil
		return true
	end
	if type(value) ~= "number" or value ~= value or value < 0 or value >= 1 then
		return false
	end
	rollOverride = value
	return true
end

function CarryService.ResolveGuardianCatch(player: Player, hauling: boolean,
	roll: number?): (string, Held?)
	local held = carried[player]
	local outcome = GuardianCatch.Resolve(held, hauling == true, function(): number
		return roll or rollOverride or catchRandom:NextNumber()
	end, GameConfig.Parent.Confiscate.LeaveBehindChance)

	if outcome == GuardianCatch.Confiscated then
		return outcome, CarryService.Confiscate(player)
	end
	if outcome == GuardianCatch.Left and held then
		if held.model and held.model.Parent then
			held.model:SetAttribute(ATTR.GuardianAbandoned, true)
		end
		log(string.format("%s keeps a %d tier %s: the guardian left it behind for good.",
			player.Name, held.tier, held.species.Name))
	end
	return outcome, nil
end

--==============================================================================
-- PUTTING ONE BACK ON THE GROUND, FROM OUTSIDE
--
-- The recovery path for a haul that cannot be deposited in a ring -- the nest
-- was full, or the guardian died holding it. It is the SAME loose pod a drop
-- makes: tagged, prompted, and on the same lifetime, because a second kind of
-- recoverable pod is a second thing to reason about and there is no reason for
-- one to exist.
--==============================================================================
function CarryService.SpawnLoose(speciesId: string, tier: number, at: CFrame,
	fromNest: string?, reservedFor: number?, keep: boolean?, abandoned: boolean?): Model?
	local species = SeedData.Get(speciesId)
	local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
	if not (species and map) then
		return nil
	end
	return spawnLoose(species, tier, at, map, fromNest, reservedFor, keep, abandoned)
end

--==============================================================================
-- A RAIN EVENT'S PODS ON THE GROUND (2026-10-02)
--
-- `IsLiveEventPod`: the pod was laid by the weather event that is running NOW
-- (its EventId is the workspace's), which is what dusk and the dark rule ask.
-- `ClearEventPods`: the event's own cleanup -- every loose pod of that event,
-- wherever it lies, goes with it. A pod in somebody's ARMS is never in this set
-- (CarriedPod, not SeedPod); the evacuation banks it at the landing first.
--==============================================================================
function CarryService.IsLiveEventPod(pod: Instance): boolean
	local id = pod:GetAttribute(EVENT_ID)
	return type(id) == "number" and id == workspace:GetAttribute(GameConfig.Weather.Attributes.EventId)
end

function CarryService.ClearEventPods(eventId: number): number
	local removed = 0
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod.Parent and pod:GetAttribute(EVENT_ID) == eventId and pod:GetAttribute("NestId") == nil then
			pod:Destroy()
			removed += 1
		end
	end
	return removed
end

-- Who a pod belongs to, or nil for the ordinary kind everybody may take.
function CarryService.ReservedFor(pod: Model): number?
	return tonumber(pod:GetAttribute(RESERVED_FOR))
end

--==============================================================================
-- READ API, for PlantService
--==============================================================================
function CarryService.GetCarried(player: Player): Held?
	return carried[player]
end

-- Consumes the pod without dropping it. Planting is the only thing that should
-- take a carried pod off a player and leave nothing on the ground.
function CarryService.Consume(player: Player): SeedData.Species?
	local held = carried[player]
	if not held then
		return nil
	end
	carried[player] = nil
	if held.model.Parent then
		held.model:Destroy()
	end
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	Metrics.raidEnded(player, "other")
	return held.species
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function forget(player: Player)
	local conns = perPlayer[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		perPlayer[player] = nil
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- A new body carries nothing: whatever the old one had is on the ground
	-- where it fell.
	carried[player] = nil
	publish(player)

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	local conns = perPlayer[player] or {}
	perPlayer[player] = conns

	CarryService.RefreshWalkSpeed(player)

	--==========================================================================
	-- AND AGAIN WHEN THE PROFILE LANDS
	--
	-- The body spawns immediately. The profile is a DataStore round trip behind
	-- it, so the call above reads `nil` and falls back to walkSpeedFor(0) --
	-- BASE speed, 16 -- for a player whose saved score is worth eighty.
	--
	-- Nothing re-ran it. The only other callers of RefreshWalkSpeed are taking
	-- a pod, dropping one, banking one and earning on the mill, so a player who
	-- joined and just ran was stuck at base until they happened to touch a pod.
	-- Reported as "the speed I have doesn't work, I need to take pods to
	-- recover", and that is exactly what it was.
	--
	-- Same shape as PlantService's restore: wait for the profile rather than
	-- assume an order that is not guaranteed.
	--==========================================================================
	if not PlayerDataService.IsReady(player) then
		task.spawn(function()
			local deadline = os.clock() + 30
			while not PlayerDataService.IsReady(player) and os.clock() < deadline do
				task.wait(0.25)
			end
			-- Still this body? A respawn inside thirty seconds has already
			-- started a wait of its own, and two of them refreshing is one of
			-- them writing on behalf of a character that no longer exists.
			if player.Parent ~= Players or player.Character ~= character then
				return
			end
			if PlayerDataService.IsReady(player) then
				CarryService.RefreshWalkSpeed(player)
			end
		end)
	end

	-- RAGDOLLED MEANS DROPPED, and watching the PROPERTY rather than the event
	-- that caused it means every future knockdown gets this for free -- nothing
	-- has to remember to call Drop.
	table.insert(conns, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		if humanoid.PlatformStand then
			local root = character:FindFirstChild("HumanoidRootPart")
			if CarryService.Drop(player,
				if root and root:IsA("BasePart") then root.Position else nil) then
				-- A guardian's catch ended the raid a moment ago (NestService);
				-- anything else that knocks a carrier flat is "knocked".
				Metrics.raidEnded(player, "knocked")
			end
		end
	end))

	table.insert(conns, humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		if CarryService.Drop(player,
			if root and root:IsA("BasePart") then root.Position else nil) then
			Metrics.raidEnded(player, "died")
		end
	end))

	-- WHILE A POD IS CARRIED, A PLANT THAT ARRIVES IN THE HANDS GOES BACK. After a
	-- frame, so the equip that brought it has finished moving it first -- the
	-- Backpack it came from is still the right place for it. See putPlantsAway.
	table.insert(conns, character.ChildAdded:Connect(function(child)
		if carried[player] and isPlantTool(child) then
			task.defer(function()
				if carried[player] and child.Parent == character then
					putPlantsAway(player)
				end
			end)
		end
	end))
end

local function watch(player: Player)
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		forget(player)
		onCharacterAdded(player, character)
	end))
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

-- The per-body watchers, exposed for the spec.
CarryService.WatchBody = onCharacterAdded

--==============================================================================
-- THE HOTBAR SURVIVES LOGGING OUT
--
-- It did not, and the omission ate plants. The bed was saved from the first day
-- and the hands were not, so a plant taken out of your own dirt and still held
-- when you left stopped existing -- gone from the bed AND gone from the hotbar.
-- The Garden's PICK UP made that a one-click mistake, which is how it was found,
-- but the world prompt had always done the same thing.
--
-- A Tool is three attributes -- SpeciesId, CarryingKg, Hatched -- and those
-- three are the whole of it. Save them and a restored Tool is not a copy of what
-- was lost, it is the same object rebuilt from its own definition.
--==============================================================================
-- The row a plant Tool is saved as, or nil for anything that is not one (a bat,
-- a trap). Still readable off a Tool that has just been destroyed.
local function rowOf(tool: Instance): { any }?
	if not tool:IsA("Tool") then
		return nil
	end
	local id = tool:GetAttribute("SpeciesId")
	local tier = tonumber(tool:GetAttribute(ATTR.CarryingKg))
	if type(id) == "string" and SeedData.Get(id) and tier and tier >= 1 then
		return {
			Id = id,
			Tier = math.floor(tier),
			Hatched = tool:GetAttribute("Hatched") == true,
		}
	end
	return nil
end

local function heldSnapshot(player: Player): { any }
	local rows = {}

	--==========================================================================
	-- BOTH PLACES A TOOL CAN BE
	--
	-- Equipping MOVES a Tool out of the Backpack and into the Character, so a
	-- snapshot that only reads the Backpack loses whatever the player happens to
	-- be holding -- which is the single most likely thing to be lost, because it
	-- is the thing they just picked up.
	--==========================================================================
	local function collect(container: Instance?)
		if not container then
			return
		end
		for _, tool in ipairs(container:GetChildren()) do
			local row = rowOf(tool)
			if row and #rows < SAVE.MaxHeld then
				table.insert(rows, row)
			end
		end
	end

	collect(player:FindFirstChildOfClass("Backpack"))
	collect(player.Character)
	return rows
end

--==============================================================================
-- RECORDED WHEN IT CHANGES, AND NEVER BLANKED BY A TEARDOWN
--
-- The guard is the whole trick. A hotbar legitimately becomes empty only when
-- the player plants or uses the last thing in it -- and they are alive, present
-- and holding a Backpack when that happens.
--
-- No Backpack means we are not looking at a live hotbar at all: the player is
-- still joining, or the session is being pulled down around them. An empty
-- snapshot taken in either of those moments is not evidence that they own
-- nothing, and writing it would destroy whatever they were carrying. So it is
-- not written, and the last thing that WAS true stands.
--==============================================================================
--==============================================================================
-- NOTHING IS RECORDED UNTIL WHAT WAS SAVED HAS BEEN PUT BACK
--
-- This lost a real bag. 2026-09-11: a Studio session's profile claim landed
-- 38 s after the server started. restoreHeld gave up at its old 20 s cap
-- WITHOUT A WORD, so nine saved plants were never rebuilt -- and the next thing
-- that touched the Backpack took a snapshot of it, found no plants, and SetHeld
-- wrote that empty list over the save. The DataStore still had all nine in the
-- version before; the live profile had none.
--
-- So a snapshot is refused outright until this player's restore has run. The
-- save a player arrived with is the truth until the world has been made to match
-- it, and an empty Backpack before that moment is not evidence of anything.
--==============================================================================
--==============================================================================
-- AND ONLY FOR THE BACKPACK AND THE BODY THAT WERE PUT BACK
--
-- 9a007b6 gated the first snapshot behind the join restore, and dying still
-- erased the bag. A death or a reset destroys the Character and the Backpack
-- with every Tool in them, and the engine hands over a new, empty Backpack --
-- whose ChildAdded, and the new body's CharacterAdded, both asked for a snapshot
-- while the gate was still open. The snapshot found nothing, and SetHeld wrote
-- nothing over the save.
--
-- So the gate is no longer a flag. It is ARMED for one Backpack instance and one
-- Character instance -- the pair the last rebuild put the plants into -- and a
-- snapshot is refused the moment either is not the one the player has now. That
-- makes the ORDER the engine tears things down in irrelevant: a deferred sync
-- that lands after the old body is gone, or before the new one has its Tools, is
-- looking at a different pair and writes nothing. Only the rebuild re-arms it,
-- after the saved plants are back.
--==============================================================================
type Armed = { backpack: Backpack, character: Model? }
local armed: { [Player]: Armed } = {}

local function armedFor(player: Player): boolean
	local record = armed[player]
	if not record then
		return false
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	return backpack ~= nil and backpack == record.backpack
		and player.Character == record.character
end

--==============================================================================
-- A SNAPSHOT MAY ADD TO THE RECORD. ONLY A TRANSACTION MAY TAKE FROM IT.
--
-- MEASURED 2026-09-23, Play: a player holding a Petalpip jumped off the map. At
-- -500 the engine removed the plant Tool from the still-living body -- 20 ms
-- BEFORE Humanoid.Died and 3.6 s before CharacterRemoving -- and this file's
-- own ChildRemoved sync, still armed for that body, recorded a bag without it.
-- The respawn rebuild then put back exactly what the record said, which no
-- longer had the plant in it. Owned, saved, gone.
--
-- A snapshot cannot tell a Tool that was SOLD from one the void ate: both are
-- simply not there. So a snapshot may only ADD -- a banked pod, a bought one, a
-- hatch, a pickup -- and never remove. The record shrinks one way: SyncHeldNow
-- with the Tools a transaction has just destroyed (planting, SELL ALL, SELL ONE,
-- the Studio ClearBag), and it removes exactly one row for each of THOSE --
-- never "whatever is missing", or a sale made while the void still had a plant
-- would take that plant off too. Anything that merely saw a Tool disappear --
-- the void, a body torn down, a deferred sync out of an old Backpack -- can no
-- longer cost a plant, and the respawn rebuild builds what the record has and
-- the containers lack, exactly once.
--
-- Rows are counted per (species, tier, hatched): two identical plants are two
-- rows, and the merge keeps whichever count is larger, saved or live.
--
-- THE LIMIT STOPS A ROW BEING ADDED. IT NEVER TAKES ONE OFF (2026-09-29). Every
-- row already on the record is kept, however many there are: the owner's rule
-- is that a record past the limit is not to be cut down to it, silently or
-- otherwise. SAVE.MaxHeld is only ever asked of a row that is not there yet.
--==============================================================================
local function heldKey(id: string, tier: number, hatched: boolean): string
	return id .. ":" .. tostring(tier) .. ":" .. tostring(hatched)
end

local function mergeHeld(saved: { any }?, live: { any }): { any }
	local merged = {}
	local owed: { [string]: number } = {}
	if type(saved) == "table" then
		for _, row in ipairs(saved) do
			if type(row) == "table" then
				table.insert(merged, row)
				local key = heldKey(tostring(row.Id), math.floor(tonumber(row.Tier) or 0), row.Hatched == true)
				owed[key] = (owed[key] or 0) + 1
			end
		end
	end
	for _, row in ipairs(live) do
		local key = heldKey(row.Id, row.Tier, row.Hatched)
		if (owed[key] or 0) > 0 then
			owed[key] -= 1
		elseif #merged < SAVE.MaxHeld then
			table.insert(merged, row)
		end
	end
	return merged
end

local function syncHeld(player: Player, consumed: { Instance }?)
	local profile = PlayerDataService.Get(player)
	local saved = if profile then profile.Held else nil
	--==========================================================================
	-- WHAT A TRANSACTION CONSUMED COMES OFF, ARMED OR NOT
	--
	-- A sale or a planting has already happened by the time this runs; skipping
	-- the record because a respawn happens to be under way would let the rebuild
	-- hand the sold plant back.
	--==========================================================================
	if consumed and #consumed > 0 and type(saved) == "table" then
		local kept = table.clone(saved)
		for _, tool in ipairs(consumed) do
			local row = rowOf(tool)
			if row then
				local key = heldKey(row.Id, row.Tier, row.Hatched)
				for i, r in ipairs(kept) do
					if type(r) == "table"
						and heldKey(tostring(r.Id), math.floor(tonumber(r.Tier) or 0), r.Hatched == true) == key then
						table.remove(kept, i)
						break
					end
				end
			end
		end
		saved = kept
		if not armedFor(player) then
			PlayerDataService.SetHeld(player, kept)
			return
		end
	end
	if not armedFor(player) then
		return
	end
	PlayerDataService.SetHeld(player, mergeHeld(saved, heldSnapshot(player)))
end

function CarryService.IsHeldRestored(player: Player): boolean
	return armedFor(player)
end

--==============================================================================
-- ONE SNAPSHOT AFTER THE DUST SETTLES, NOT ONE PER EVENT
--
-- Equipping does not copy a Tool, it REPARENTS it -- Backpack to Character --
-- and equipping a second one unequips the first. A single click therefore fires
-- several ChildAdded and ChildRemoved events, and for part of that sequence a
-- Tool is parented to neither container.
--
-- Snapshotting straight off the event caught exactly that gap: two plants went
-- in, the one that happened to be mid-move was invisible, and only the other
-- came back. Deferring to the end of the frame and collapsing the burst into
-- one snapshot means the hotbar is only ever read when it is whole.
--==============================================================================
local syncPending: { [Player]: boolean } = {}

-- THE ONE CALL THAT MAY SHRINK THE RECORD, and only by `consumed`: the plant
-- Tools the calling transaction has just destroyed (see A SNAPSHOT MAY ADD).
-- Called without them it only catches the record up, adding.
function CarryService.SyncHeldNow(player: Player, consumed: { Instance }?)
	syncPending[player] = nil
	syncHeld(player, consumed)
end

-- Catch the record up with the hands, now. Adds; never removes.
local function recordHeld(player: Player)
	syncPending[player] = nil
	syncHeld(player, nil)
end

--==============================================================================
-- HOW MUCH ROOM THE RECORD HAS (2026-09-29)
--
-- THE ONE PLACE THE LIMIT IS COUNTED, for anything that must not hand over what
-- it cannot record: a hatch and a pickup (GiveHatched, with `onRecord`), a pod
-- taken at a nest (TryTake) and banked at the red line (bank), and the Instant
-- Hatch prompt, which does not open a purchase for a hatch that would be
-- refused (PlantService.OfferInstantHatch).
--
-- A POD GIVEN is counted here too (2026-09-30): GivePod, which a wheel prize
-- and a paid pod product call, gives only into room and writes the row in the
-- same call. The beginner's tutorial pod is not given: it is laid on the road
-- (SpawnLoose) and taken like any other pod, so TryTake counts it.
--
-- WHAT IS COUNTED IS THE RECORD -- profile.Held, pods and plants alike, which is
-- what a death or a rejoin rebuilds from -- after it has been caught up with the
-- hands. That catch-up is the snapshot the Backpack's watcher takes at the end
-- of every frame, taken now: it adds what is held and not yet written down, and
-- takes nothing off. Between bodies no snapshot is allowed, and the record
-- alone is counted: it is what the new body will be given.
--
-- A POD IN THE ARMS HAS ITS PLACE KEPT. It was taken with room for it (TryTake
-- counts here), and it is on its way to the record: until it is banked or
-- dropped it counts as one, so that nothing hatched or picked up on the run
-- home can take the place it was taken for. `own` is that pod itself asking, at
-- the red line: its own place is not counted against it.
--
-- FULL ALREADY, and nothing is caught up: a snapshot only ever adds, so it
-- cannot make room, and a record that is asked about five times a second by a
-- pod waiting at the line is not written five times a second to be told no.
--
-- Answers how many more rows fit, how many there are, and whether there is a
-- record at all -- a player whose profile has not arrived has room for nothing,
-- and that is not "full".
--==============================================================================
function CarryService.HeldRoom(player: Player, own: boolean?): (number, number, boolean)
	local profile = PlayerDataService.Get(player)
	if not profile then
		return 0, 0, false
	end
	local kept = if carried[player] ~= nil and own ~= true then 1 else 0
	local count = (if type(profile.Held) == "table" then #profile.Held else 0) + kept
	if count < SAVE.MaxHeld and armedFor(player) then
		recordHeld(player)
		profile = PlayerDataService.Get(player)
		if not profile then
			return 0, 0, false
		end
		count = (if type(profile.Held) == "table" then #profile.Held else 0) + kept
	end
	return math.max(SAVE.MaxHeld - count, 0), count, true
end

--==============================================================================
-- A HATCH GOES ON THE RECORD AS IT HAPPENS (2026-09-29)
--
-- One row for one plant, asked for by the hatch itself, before the pod leaves
-- the garden -- so the profile never holds neither the pod nor the plant.
--
-- ARMED, this is the snapshot the Backpack's own watcher would take a moment
-- later, taken now. DISARMED -- a body is being replaced, and a receipt can land
-- at any moment of that -- no snapshot is allowed, and the hatch used to be a
-- Tool on nobody's record: gone with the old Backpack, the pod gone with the
-- hatch, and nothing to rebuild the plant from. So the row is added directly.
--
-- ADDING A ROW IS SAFE IN EVERY STATE. The merge counts rows against Tools by
-- (species, tier, hatched): the snapshot that follows finds this Tool already
-- has its row and adds nothing, and the rebuild after the death builds what the
-- record has and the containers lack -- this plant, once, if its Tool went.
--
-- It cannot go past SAVE.MaxHeld. False when the plant is not on the record
-- after the call -- and a hatch whose plant is not on the record is refused:
-- GiveHatched counts the room first (HeldRoom) and takes the Tool back if this
-- answers false.
--
-- ON THE RECORD MEANS A ROW FOR EVERY TOOL OF ITS KIND. Not "the record grew":
-- a snapshot adds whatever is held and not written down, and the row it added
-- need not be this plant's -- and a record that did NOT grow may have this plant
-- on it all the same, when it holds a row whose Tool has gone (the void takes a
-- Tool and leaves its row; see A SNAPSHOT MAY ADD). So what is asked is what
-- the next body would be built from: as many rows of this species, size and
-- kind as there are Tools of it, this one included.
--==============================================================================
local function toolsOfKind(player: Player, key: string): number
	local n = 0
	local function count(container: Instance?)
		if not container then
			return
		end
		for _, tool in ipairs(container:GetChildren()) do
			local row = rowOf(tool)
			if row and heldKey(row.Id, row.Tier, row.Hatched) == key then
				n += 1
			end
		end
	end
	count(player:FindFirstChildOfClass("Backpack"))
	count(player.Character)
	return n
end

local function recordOne(player: Player, species: SeedData.Species, tier: number, hatched: boolean): boolean
	local profile = PlayerDataService.Get(player)
	if not profile then
		return false
	end
	if armedFor(player) then
		recordHeld(player)
		local after = PlayerDataService.Get(player)
		if not (after and type(after.Held) == "table") then
			return false
		end
		local key = heldKey(species.Id, math.floor(tier), hatched)
		local rows = 0
		for _, row in ipairs(after.Held) do
			if type(row) == "table"
				and heldKey(tostring(row.Id), math.floor(tonumber(row.Tier) or 0), row.Hatched == true) == key then
				rows += 1
			end
		end
		return rows >= 1 and rows >= toolsOfKind(player, key)
	end
	local kept = if type(profile.Held) == "table" then table.clone(profile.Held) else {}
	if #kept >= SAVE.MaxHeld then
		return false
	end
	table.insert(kept, { Id = species.Id, Tier = math.floor(tier), Hatched = hatched })
	return PlayerDataService.SetHeld(player, kept) == true
end

function CarryService.RecordHatched(player: Player, species: SeedData.Species, tier: number): boolean
	return recordOne(player, species, tier, true)
end

-- The same, for a pod that has just been banked or given: its row is written as
-- its Tool is made, and the bank or the gift is refused if it cannot be (see
-- bank and GivePod).
function CarryService.RecordPod(player: Player, species: SeedData.Species, tier: number): boolean
	return recordOne(player, species, tier, false)
end

local function requestSync(player: Player)
	if syncPending[player] then
		return
	end
	syncPending[player] = true
	task.defer(function()
		if syncPending[player] then
			syncPending[player] = nil
			syncHeld(player, nil)
		end
	end)
end

-- Forward: the watchers below start it, and it lives with the builders further
-- down. A bare `function rebuildHeld` there would be a global.
local rebuildHeld: (Player) -> ()

local function watchHeld(player: Player)
	local function bind(container: Instance)
		table.insert(serviceConnections, container.ChildAdded:Connect(function()
			requestSync(player)
		end))
		table.insert(serviceConnections, container.ChildRemoved:Connect(function()
			requestSync(player)
		end))
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		bind(backpack)
	end
	-- Equipping MOVES a Tool from the Backpack into the Character, so both ends
	-- have to be watched or the hotbar looks empty for as long as something is
	-- in the player's hands.
	if player.Character then
		bind(player.Character)
	end
	--==========================================================================
	-- A NEW BODY IS A REBUILD, NOT A SNAPSHOT
	--
	-- This used to ask for a snapshot, and the snapshot of a body that has just
	-- spawned is empty. The rebuild puts the saved plants back first and takes
	-- the snapshot itself once they are there.
	--==========================================================================
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		bind(character)
		rebuildHeld(player)
	end))
	-- The old body is about to take its Tools with it. Disarm now rather than
	-- trust anything that tries to record while it goes.
	table.insert(serviceConnections, player.CharacterRemoving:Connect(function()
		armed[player] = nil
		syncPending[player] = nil
	end))

	--==========================================================================
	-- THE BACKPACK IS REPLACED ON EVERY RESPAWN
	--
	-- Roblox destroys it and makes a new one, so the connections above are to an
	-- object that will not exist after the first death. Without this, dying once
	-- silently stops the hotbar being recorded for the rest of the session.
	--
	-- And a new Backpack is EMPTY: the Tools it replaces died with the old one.
	-- Asking for a snapshot here is what erased held plants on every death, so it
	-- is a rebuild, the same as a new body.
	--==========================================================================
	table.insert(serviceConnections, player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			bind(child)
			rebuildHeld(player)
		end
	end))
end

-- The real watchers, exposed for the spec so a respawn can be played through them.
CarryService.WatchHeld = watchHeld

--==============================================================================
-- PUTTING THEM BACK
--
-- The same two builders the live game uses, so a restored pod is a pod and a
-- restored creature is a creature -- there is no third kind of thing that only
-- exists after a rejoin.
--
-- NOT EQUIPPED. The hatch equips because a shell has just burst in front of the
-- player and that is a moment; a rejoin is not, and forcing a 30-stud Bellchime
-- into their hands at the spawn point is not a welcome.
--==============================================================================
-- A pod's Tool in the bag: the same builder, grip and reach as every other pod.
-- Answers the Tool, or nil with nothing left behind.
local function givePodTool(player: Player, species: SeedData.Species, tier: number): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end
	local pod = CreatureModel.BuildPod(species, tier, CFrame.new(), backpack)
	local tool = giveTool(player, pod, species, tier, gripFor(tier, species), false)
	if not tool then
		return nil
	end
	-- The same number CarryPose reads off a banked pod anywhere else.
	tool:SetAttribute("GripReach", SeedData.GripForward(tier))
	return tool
end

local function restoreOne(player: Player, species: SeedData.Species, tier: number,
	hatched: boolean): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false
	end
	if hatched then
		-- A plant whose roll a death interrupted is still a secret (see Sealed):
		-- it comes back hidden, and into the hands no sooner than it may be shown.
		local sealedUntil = Sealed.take(player, species.Id, tier)
		-- One answer: GiveHatched's reason is for a hatch, not a rebuild.
		local given: boolean
		if sealedUntil then
			given = CarryService.GiveHatched(player, species, tier,
				math.max(sealedUntil - workspace:GetServerTimeNow(), 0.05), sealedUntil)
		else
			given = CarryService.GiveHatched(player, species, tier)
		end
		return given
	end
	return givePodTool(player, species, tier) ~= nil
end

--==============================================================================
-- A POD FROM OUTSIDE THE ROAD
--
-- Everything else in this file puts a pod in the hotbar because the player
-- carried it home. A pod won on the wheel or bought has no journey behind it,
-- so it needs a way in that is not the red line -- but it must be the SAME pod
-- when it gets there: same builder, same Tool, same grip, same GripReach the
-- pose reads (givePodTool, which a rebuild uses too).
--
-- COUNTED AND WRITTEN DOWN, OR NOT GIVEN (2026-09-30). This used to hand the pod
-- over whatever the saved record held, and past its limit the pod had no row --
-- gone at the next death or rejoin. The owner's rule: "Ordinary player actions
-- must respect storage capacity without losing or duplicating a pod." So the
-- room is counted first (HeldRoom, which keeps a place for a pod being carried
-- home), the row is written in the same call that made the Tool (RecordPod),
-- and a row that cannot be written takes the Tool back.
--
-- False for any of it, and for no backpack -- a player can be mid-respawn when
-- a receipt lands -- so each caller can tell "not now" from "done": the wheel
-- keeps its prize owed, and a paid pod's receipt stays open.
--==============================================================================
function CarryService.GivePod(player: Player, speciesId: string, tier: number): boolean
	local species = SeedData.Get(speciesId)
	if not species then
		return false
	end
	local n = tonumber(tier)
	if n == nil or n ~= n then
		return false
	end
	local size = math.clamp(math.floor(n), 1, SeedData.TierCount)
	local room, _, known = CarryService.HeldRoom(player)
	if not known or room < 1 then
		return false
	end
	local tool = givePodTool(player, species, size)
	if not tool then
		return false
	end
	if not CarryService.RecordPod(player, species, size) then
		tool:Destroy()
		return false
	end
	return true
end

--==============================================================================
-- WAIT FOR THE PROFILE AS LONG AS THE PLAYER IS HERE
--
-- The save is a DataStore round trip, and it is not always a second or two: it
-- was measured at 38 s in Studio, and a throttled live server can be slower.
-- The old 20 s cap ended the wait silently while the player was still in the
-- game, which is what let an empty snapshot overwrite their bag (see above).
--
-- The wait now lasts while the player stays. `HeldRestorePatience` is a backstop
-- against a thread that could otherwise spin for a whole session; if it ever
-- runs out the gate simply stays CLOSED -- this session records nothing, and the
-- bag the player joined with is still the bag in their save.
--
-- EVERY TIME THE BODY OR THE BACKPACK IS REPLACED, not once per player: the
-- join, and every death, reset and LoadCharacter after it. A pass counts what is
-- already in the Backpack and the hands and builds only what the save has and
-- they do not -- so a respawn that kept its Tools builds nothing, and nothing is
-- ever built twice. A call that lands while a pass is running asks for one more
-- pass when it finishes, rather than a second pass alongside it.
--==============================================================================
CarryService.HeldRestorePatience = 600

local rebuilding: { [Player]: boolean } = {}
local rebuildAgain: { [Player]: boolean } = {}

-- One pass. False if it gave up or the player left; true once the Backpack and
-- the body the player has now are armed.
local function rebuildOnce(player: Player): boolean
	local deadline = os.clock() + CarryService.HeldRestorePatience
	local function gaveUp(why: string): boolean
		if os.clock() < deadline then
			return false
		end
		warn(string.format("[Seed/CarryService] %s: %s; held plants were not restored, "
			.. "and the saved bag will not be overwritten this session.", player.Name, why))
		return true
	end

	while player.Parent == Players and not PlayerDataService.IsReady(player) do
		if gaveUp("the profile never arrived") then
			return false
		end
		task.wait(0.25)
	end
	-- The Backpack is made by the engine as the body spawns, and a Tool cannot
	-- be handed over before it exists.
	while player.Parent == Players and not player:FindFirstChildOfClass("Backpack") do
		if gaveUp("no Backpack appeared") then
			return false
		end
		task.wait(0.1)
	end
	local profile = PlayerDataService.Get(player)
	if player.Parent ~= Players or not profile then
		return false
	end
	if armedFor(player) then
		-- Nothing has been torn down since the last pass armed this pair.
		return true
	end
	armed[player] = nil

	--== WHAT IS ALREADY HERE, SO NOTHING IS BUILT TWICE ==--
	local backpack = player:FindFirstChildOfClass("Backpack") :: Backpack
	local present: { [string]: number } = {}
	for _, container in ipairs({ backpack, player.Character }) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local id = tool:GetAttribute("SpeciesId")
					local tier = tonumber(tool:GetAttribute(ATTR.CarryingKg))
					if type(id) == "string" and tier then
						local key = heldKey(id, math.floor(tier), tool:GetAttribute("Hatched") == true)
						present[key] = (present[key] or 0) + 1
					end
				end
			end
		end
	end

	local restored, kept, dropped = 0, 0, 0
	if type(profile.Held) == "table" then
		for _, row in ipairs(profile.Held) do
			local species = if type(row) == "table" then SeedData.Get(tostring(row.Id)) else nil
			local tier = if type(row) == "table" then tonumber(row.Tier) else nil
			if species and tier and tier >= 1 then
				local key = heldKey(species.Id, math.floor(tier), row.Hatched == true)
				if (present[key] or 0) > 0 then
					present[key] -= 1
					kept += 1
				elseif restoreOne(player, species, tier, row.Hatched == true) then
					restored += 1
				else
					dropped += 1
				end
			else
				dropped += 1
			end
		end
	end
	if restored > 0 or dropped > 0 then
		log(string.format("%s: restored %d held plant(s)%s%s.", player.Name, restored,
			if kept > 0 then string.format(", %d were still here", kept) else "",
			if dropped > 0 then string.format(", %d could not be rebuilt", dropped) else ""))
	end

	-- The world matches the save now, so recording may begin: armed for exactly
	-- this Backpack and this body, then one snapshot -- which also records
	-- anything banked or bought while the pass was waiting.
	armed[player] = { backpack = backpack, character = player.Character }
	recordHeld(player)
	return true
end

rebuildHeld = function(player: Player)
	if rebuilding[player] then
		rebuildAgain[player] = true
		return
	end
	rebuilding[player] = true
	task.spawn(function()
		repeat
			rebuildAgain[player] = nil
			local done = rebuildOnce(player)
		until not done or not rebuildAgain[player]
		rebuilding[player] = nil
	end)
end

-- The join path and the respawn path are the same call. Exposed for the spec.
CarryService.RestoreHeld = rebuildHeld

--==============================================================================
-- STOP RECORDING BEFORE SOMETHING REPLACES THE BODY
--
-- NestService calls this through the carry bridge right before LoadCharacter,
-- which is the one place in the game that swaps a body on purpose. A last
-- snapshot first; then nothing is recorded until the rebuild after the swap has
-- put the plants back and re-armed. That snapshot ADDS only: the body being
-- replaced is often one that fell off the map, and the void may already have
-- taken the plant in its hands.
--==============================================================================
function CarryService.FreezeHeld(player: Player)
	if armedFor(player) then
		recordHeld(player)
	end
	armed[player] = nil
	syncPending[player] = nil
end

function CarryService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for player in pairs(perPlayer) do
		forget(player)
	end
	table.clear(carried)
	table.clear(prompted)
	table.clear(Sealed.byPlayer)
end

--==============================================================================
-- THE CARRY GUARD, APPLIED
--
-- CarryGuard holds the rule: a pod cannot travel faster than its carrier's own
-- server-set WalkSpeed allows. This applies it every frame to every carrier,
-- and once more right before a pod is banked, so a teleport into the safe zone
-- is caught even if it landed between two frames of the check.
--
-- THE CORRECTION IS TO PUT THEM BACK, NOT TO PUNISH. The carrier is moved to
-- the last place the server saw them honestly, still holding the pod, with no
-- saved travel (CarryGuard.reset). An exploiter gains nothing and can try
-- forever; an honest player whose connection stalled longer than
-- CarryGuard.CapSeconds loses a few steps, not a pod. The one server move this can undo is PlotService placing a queued
-- carrier on a newly freed plot -- which would otherwise bank the pod for free,
-- so putting them back on the road is the right answer there too.
--
-- Returns false when it had to put the carrier back.
--==============================================================================
local function checkCarrier(player: Player, dt: number): boolean
	if not carried[player] then
		if guards[player] then
			guards[player] = nil
			guardEnded[player] = os.clock()
		end
		return true
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not (character and root and root:IsA("BasePart") and humanoid) then
		return true
	end
	local state = guards[player]
	if not state then
		guards[player] = CarryGuard.new(root.Position)
		return true
	end
	local ok, moved = CarryGuard.step(state, root.Position, humanoid.WalkSpeed, dt)
	if ok then
		return true
	end
	local back = state.at
	local body = character :: Model
	local part = root :: BasePart
	pcall(function()
		body:PivotTo(CFrame.new(back) * part.CFrame.Rotation)
		part.AssemblyLinearVelocity = Vector3.zero
	end)
	CarryGuard.reset(state, back)
	-- Named in the server log, at most every five seconds per player, so the
	-- owner can see who is trying without an exploiter flooding the console.
	local now = os.clock()
	if now - (lastGuardWarn[player] or -math.huge) >= 5 then
		lastGuardWarn[player] = now
		warn(string.format(
			"[Seed/CarryService] %s moved %.0f studs while carrying, more than WalkSpeed %.0f "
				.. "allows; put back where the server last saw them.",
			player.Name, moved, humanoid.WalkSpeed))
	end
	return false
end

-- Exposed for the spec and for a Studio probe; nothing else calls it.
CarryService.CheckCarrier = checkCarrier

function CarryService.Start()
	--==========================================================================
	-- THE SEAM POINTS THIS WAY BECAUSE THE REQUIRE DOES
	--
	-- NestService is Priority 40 and this is 45: this module requires it, so it
	-- cannot require this one back without a cycle. But the CATCH happens in its
	-- tick, and the pod being caught lives here.
	--
	-- So the dependency stays one-way and the capability is handed over instead.
	-- NestService holds two functions and knows nothing else about carrying;
	-- if this service never starts, it holds nothing and confiscation simply
	-- does not happen -- the catch falls through to the throw it always did.
	--==========================================================================
	NestService.SetCarryBridge({
		-- The whole catch in one call that does not yield: roll, mark, or take.
		ResolveGuardianCatch = CarryService.ResolveGuardianCatch,
		SpawnLoose = CarryService.SpawnLoose,
		-- So a guardian's throw can hand movement back by RECOMPUTING it rather
		-- than by replaying a number it captured before the throw -- which is
		-- what froze players who were caught while a trap held them at zero.
		RefreshWalkSpeed = CarryService.RefreshWalkSpeed,
		-- So NestService's LoadCharacter cannot record the empty Backpack it makes.
		FreezeHeld = CarryService.FreezeHeld,
		-- So a guardian knows a secret encounter's pod in a thief's arms.
		CarriedSecret = function(player: Player): string?
			local held = carried[player]
			return if held then held.secretId else nil
		end,
		-- So a guardian remembers a thief only while they still carry its pod.
		CarriedFrom = function(player: Player): string?
			local held = carried[player]
			return if held then held.fromNest else nil
		end,
	})

	--==========================================================================
	-- THE WALK MODE SWITCH, ON THE REMOTE THIS GAME ALREADY HAS
	--
	-- It lands HERE and not in a settings service because this is the file that
	-- owns WalkSpeed: the switch is one more input to RefreshWalkSpeed, and the
	-- service that applies a movement rule should be the service that hears the
	-- request for it.
	--
	-- NO NEW REMOTE. GameEvent already carries the Garden's UNEQUIP, the plant
	-- click, the mill upgrade and the plot upgrade, and it is a RemoteEvent that
	-- takes a verb and a payload. One more verb is not a new surface.
	--
	-- RULE 4. The sender is engine-stamped; the payload came off the wire. It has
	-- to be a boolean before it is anything else, and PlayerDataService.SetWalkMode
	-- checks the type again on its own side -- a client may ask, and may not
	-- describe the state it is in.
	--
	-- THE CLIENT IS NOT THE TRUTH. This writes the profile, the profile stamps the
	-- attribute, and the HUD draws the attribute. A client that sets the attribute
	-- locally changes its own label for one frame and nothing about its speed,
	-- because the speed is computed on this side from the profile.
	--==========================================================================
	do
		local remotes = SeedGame:FindFirstChild("Remotes")
		local channel = if remotes
			then remotes:FindFirstChild(GameConfig.Remotes.GameEvent)
			else nil
		if channel and channel:IsA("RemoteEvent") then
			table.insert(serviceConnections, channel.OnServerEvent:Connect(
				function(player: Player, action: any, payload: any)
					if action ~= GameConfig.WalkMode.Action then
						return
					end
					if type(payload) ~= "boolean" then
						return
					end
					if PlayerDataService.SetWalkMode(player, payload) then
						-- Recomputed immediately, from the truth of right now: a
						-- player who turns it off mid-carry, mid-snare or on a belt
						-- gets the speed those states say they should have, not one
						-- captured before the switch was flipped.
						CarryService.RefreshWalkSpeed(player)
						log(string.format("%s set walk mode %s.", player.Name,
							if payload then "on" else "off"))
					end
				end))
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		rebuildHeld(player)
		watchHeld(player)
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(function(player)
		rebuildHeld(player)
		watchHeld(player)
	end))

	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("Model") then
			attachPrompt(pod)
		end
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			if pod:IsA("Model") then
				attachPrompt(pod)
			end
		end))
	table.insert(serviceConnections,
		CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			prompted[pod :: Model] = nil
		end))

	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player)
		forget(player)
		-- A pod carried out of the server goes with the character, as it always
		-- has. A SECRET's encounter ends with it, so its platform does not wait
		-- for dusk over an empty spot.
		local leaving = carried[player]
		if leaving and leaving.secretId then
			pcall(NestService.SecretResolved, leaving.secretId, player.Name .. " left the server carrying it")
		end
		carried[player] = nil
		guards[player] = nil
		guardEnded[player] = nil
		lastGuardWarn[player] = nil
		-- The gate closes with the session. PlayerDataService writes the last
		-- snapshot that was allowed; nothing after this may add to it.
		armed[player] = nil
		rebuilding[player] = nil
		rebuildAgain[player] = nil
		syncPending[player] = nil
		Sealed.byPlayer[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end

	--== THE LINE ==--
	-- A poll rather than a Touched event on the stripe: the stripe is a thin
	-- non-collidable decal that a player at WalkSpeed 150 can cross between two
	-- frames without ever touching, and the safe zone is a REGION rather than a
	-- part.
	running = true
	-- Every carrier, every frame. Six players at most, a handful of vector maths
	-- each; carriers who stopped carrying drop out of the table here.
	table.insert(serviceConnections, RunService.Heartbeat:Connect(function(dt: number)
		for player in pairs(carried) do
			checkCarrier(player, dt)
		end
		for player in pairs(guards) do
			if not carried[player] then
				guards[player] = nil
				guardEnded[player] = os.clock()
			end
		end
	end))
	task.spawn(function()
		while running do
			task.wait(SAFE_CHECK_SECONDS)
			for player in pairs(carried) do
				-- The guard first, with no new travel: a carrier who arrived
				-- faster than they can run is put back on the road, and the
				-- position below is then the corrected one.
				if checkCarrier(player, 0) then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart")
						and MapService.IsInSafeZone(root.Position) then
						local ok, err = pcall(bank, player)
						if not ok then
							warn("[Seed/CarryService] banking failed: " .. tostring(err))
						end
					end
				end
			end
		end
	end)

	log("Ready. One pod at a time, dropped when ragdolled, banked at the red line.")
end

function CarryService.Snapshot(): string
	local rows = {}
	for player, held in pairs(carried) do
		table.insert(rows, string.format("%s: %s %d tier -> %.1f%% speed",
			player.Name, held.species.Name, held.tier,
			GameConfig.carryMultiplierFor(held.tier) * 100))
	end
	return if #rows > 0 then table.concat(rows, " | ") else "nobody carrying"
end

return CarryService
