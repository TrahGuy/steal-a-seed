--!strict
-- Steal a Seed :: NestService
--
-- Owns every nest on the road: the sleeping parent, the ring of pods around it,
-- and what happens when you take one.
--
--==============================================================================
-- A NEST IS A DECISION, NOT A PICKUP
--
-- Pods used to be dotted evenly along the walls, and a lone pod is just a
-- pickup -- you walk over it and keep going. Clustering them around a sleeping
-- parent turns the same objects into a question the player has to answer every
-- single time:
--
--     how many can I take before it wakes up?
--
-- That question is the whole reason the wake DELAY exists. Instant aggro would
-- delete it and leave a tax. With a delay, the near pod and the far pod are
-- different decisions, greed is punished by geometry rather than by a rule, and
-- a player creeps in and then sprints out instead of running in a straight line.
--
--==============================================================================
-- THE PARENT'S SPEED IS THE GATE
--
-- Its WalkSpeed comes from the biome, the player's comes off the treadmill via
-- the Speed curve, and the two are compared by a footrace rather than by a
-- check. Biome 1 runs at 19 against a fresh player's 16 -- you WILL be caught on
-- your first raid, and that is the lesson rather than a bug.
--
--==============================================================================
-- IT THROWS YOU OUT, TOWARD THE SAFE ZONE
--
-- This was deeper down the road at first, on the argument that throwing a
-- fleeing player homeward rewards them for being caught. That argument was
-- right about the direction and wrong about the punishment, because it assumed
-- you kept the pod.
--
-- You do not. Being ragdolled drops it (see CarryService), so LOSING THE POD IS
-- THE PUNISHMENT and the throw is just ejection -- get away from my nest. Doing
-- both would strand a player deep in a biome with nothing to show for the trip,
-- which is not a harder game, only a more tedious one.
--
-- So it throws toward safety. Home is +Z; the road runs to -Z.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
-- Which socket is the neck, and the word a victim's landing report carries.
local RagdollGate = require(Shared:WaitForChild("RagdollGate"))
local ParentModel = require(script.Parent:WaitForChild("ParentModel"))
-- No cycle: PlayerDataService requires GameConfig, SaveService, ProfileSchema
-- and BiomeData, and none of those has ever heard of a nest.
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))
-- No cycle: MapService knows nothing about nests, it only leaves the markers.
local MapService = require(script.Parent:WaitForChild("MapService"))
-- Pure: the contact sweep, the close-range lead and the thief memory.
local GuardianPursuit = require(script.Parent:WaitForChild("GuardianPursuit"))

local P = GameConfig.Parent

local NestService = {}
-- After MapService (1) leaves the site markers behind.
NestService.Priority = 40

type Nest = {
	id: string,
	biome: BiomeData.Biome,
	origin: Vector3,
	homeCFrame: CFrame,
	parent: Model,
	humanoid: Humanoid,
	root: BasePart,
	folder: Folder,
	--==========================================================================
	-- A SLOT IS FULL OR IT IS EMPTY UNTIL DAWN
	--
	-- There was a `regrowAt` here and a 22-second timer per slot, which meant a
	-- nest was never actually empty: take a pod, wait, take it again. Clearing a
	-- ring meant nothing, and the scarcity the whole road is built around
	-- existed on the map rather than in the game. Emptied stays emptied; the
	-- world cycle refills every slot at dawn and never in between.
	--
	-- EXCEPT IN A POD RUSH (2026-10-09, GameConfig.PodRush): a slot taken while
	-- one runs grows back RegrowSeconds later (`regrowAt`, by os.clock), for
	-- the rush only. Supply is the rush's whole point: one day's 16 pods would
	-- be gone in its first minute.
	--==========================================================================
	slots: { CFrame },
	pods: { [number]: Model? },
	regrowAt: { [number]: number }?,
	state: string,
	target: Player?,
	stateUntil: number,
	busy: boolean,
	-- How many times it has been robbed recently. Each one adds speed.
	rage: number,
	-- When it last settled. Rage fades this long after, rather than the instant
	-- it lies down -- see GameConfig.Parent.RageForgetSeconds.
	calmSince: number,
	-- When the CURRENT chase started. A guardian with a ramp profile reads it
	-- every tick; one without never looks at it.
	chaseSince: number,
	-- A chase handed straight on from a catch, in the same raid (2026-10-09, the
	-- owner): it runs at the ramp's top from its first tick, no opening restart.
	-- Cleared whenever a chase starts any other way.
	rampDone: boolean?,
	-- While a throw's victim is in the air and nobody else was there to turn on
	-- at the launch: the throw's own release, so a theft before it lands is
	-- chased at once (provoke) rather than after the flight.
	handOff: (() -> boolean)?,
	--==========================================================================
	-- WHAT IT TOOK OFF SOMEBODY, IF ANYTHING
	--
	-- Present only between the catch and the deposit, and only in the three
	-- biomes with a Confiscate profile. While this is set the guardian is
	-- holding the ONLY copy of that pod: it is off the player, out of the world
	-- and not yet back in a ring, so every path out of the haul has to put it
	-- somewhere. See depositHaul, which is the only way this is cleared.
	--==========================================================================
	haul: Haul?,
	--==========================================================================
	-- BOTH BODIES AT THE LAST CHASING TICK, AND WHO IS WAITING THEIR TURN
	-- (2026-10-01; GuardianPursuit)
	--
	-- `sample` is the guardian and its target, taken at the same moment, so the
	-- next tick can sweep the two of them moving together. It is the NEST's: two
	-- guardians after one thief each keep their own. Dropped whenever the
	-- target changes or a chase ends; a respawn, a teleport or a stale one is
	-- refused by GuardianPursuit.sampleUsable.
	--
	-- `thieves` is everybody who robbed this nest while it was busy with someone
	-- else, by when. Pruned every tick to those still eligible; the nearest is
	-- chased when the current chase ends. Cleared when it lies down.
	--==========================================================================
	sample: GuardianPursuit.Sample?,
	thieves: { [Player]: number },
	--==========================================================================
	-- THE SECRET ENCOUNTER (2026-10-01)
	--
	-- `secret` is the one encounter this nest may host at a time: its id rides
	-- on the pod through every rebuild (CarryService Held.secretId), so a drop, a
	-- re-take, a confiscation and a return are all the same pod and never a
	-- second platform or a second pod. Nil until the roll spawns one; nil again
	-- when the pod leaves the road (banked, forfeited) or dusk clears it.
	--
	-- `marked` is who this encounter is about: a thief who took the secret, or
	-- was caught carrying it and not relieved of it. A marked thief is chased
	-- whether or not they still carry anything -- "abandoning the pod must not
	-- abandon the thief" (the owner, 2026-10-01) -- until the usual exits:
	-- safety, death, leaving, the leash, the nest lying down. The guardian runs
	-- the biome's secret numbers (BiomeData Secret) after a marked target.
	--==========================================================================
	secret: Secret?,
	marked: { [Player]: boolean },
	--==========================================================================
	-- A BEGINNER'S FIRST RAID (2026-10-08, the owner's FIRST MINUTE)
	--
	-- The thief whose theft woke this nest from calm (rage 0) while their guide's
	-- `steal` step was not done -- on a biome that names a FirstRaidChaseSpeed
	-- (Greenhollow) and never for a Secret. While that thief is the target and
	-- the rage is still that one theft, the chase runs no faster than the named
	-- speed (firstRaidSpeedFor). Re-decided at every theft from calm.
	--==========================================================================
	firstRaid: Player?,
	-- How far its colliding body reaches from its root on the ground plane:
	-- what a wall has to be cleared by on the way home. Measured once, on the
	-- first walk home (bodyReach).
	reach: number?,
	--==========================================================================
	-- THE RAIN EVENT'S NEST (2026-10-02; OpenEventNest). Nil on every road nest.
	--
	-- `event` is the weather event it was raised for: its pods carry that id
	-- (EventId) and nothing restocks, clears or resets it but the event itself.
	-- `route` is its walk home -- the temporary biome's rooms from the entrance
	-- in, its own sleeping spot last -- in place of the road's mouth; `setDown`
	-- is where a body thrown out of the world is put back, in place of a road
	-- gate.
	--==========================================================================
	event: number?,
	route: { Vector3 }?,
	setDown: Vector3?,
	--==========================================================================
	-- THE RIG'S OWN RECIPE, AND A REBUILD IN PROGRESS (2026-10-04; see A LOST
	-- GUARDIAN IS REBUILT)
	--
	-- `buildAt` and `rigId` are what the nest was raised with, so a rebuild is
	-- the same guardian at the same spot; a record without them (a spec's, built
	-- by hand) is never rebuilt. `lastSeen` is its root at the last healthy
	-- tick, for the log. `recovery` is a loss being dealt with. `busySince` is
	-- when the throw in flight took the nest. `spec` marks a record a spec
	-- handed to SpecStep / SpecProvoke.
	--==========================================================================
	buildAt: CFrame?,
	rigId: string?,
	lastSeen: Vector3?,
	recovery: Recovery?,
	busySince: number?,
	spec: boolean?,
}

-- One loss, from the tick that found it to the rebuild that ends it.
type Recovery = {
	reason: string,
	-- The state and the root's last healthy position when it was found, for the log.
	previous: string,
	lastAt: Vector3?,
	since: number,
	-- Set once an awake guardian's chase has been let go of (target, sample, pursuit).
	settled: boolean,
	failures: number,
	nextAt: number,
	warnedAt: number,
	-- Why it will not be rebuilt (said once), or nil.
	refused: string?,
}

--==============================================================================
-- A CONFISCATED POD IS A RECORD, NOT A MODEL
--
-- The model welded to the guardian is decoration and is rebuilt on deposit --
-- the same choice `bank` makes in CarryService, and for the same reason: the
-- carried one is unanchored and welded to something, and a pod in a ring wants
-- to own itself. Losing the decoration to a stream-out or a dead guardian
-- therefore costs nothing, because this is the pod.
--==============================================================================
type Haul = {
	speciesId: string,
	tier: number,
	-- Which ring it came off, so it goes back into that one rather than into
	-- whichever nest happened to catch the thief.
	fromNest: string?,
	-- The decoration. Nil if the weld could not be made, which does not stop
	-- the haul -- an invisible pod still gets home.
	model: Model?,
	since: number,
	-- A confiscated SECRET goes back to its spot, not into a ring slot.
	secretId: string?,
}

type Secret = {
	id: string,
	speciesId: string,
	-- The pod standing on the spot, or nil while it is in somebody's arms, on
	-- the road or in a guardian's fist.
	pod: Model?,
	platform: Folder?,
	spawnedAt: number,
}

local nests: { Nest } = {}
local serviceConnections: { RBXScriptConnection } = {}

-- Where each chased player was at the previous tick used to live here, keyed by
-- player and holding the TARGET's position alone. It is `Nest.sample` now (both
-- bodies, one moment, per nest): see GuardianPursuit.
local running = false

--==============================================================================
-- WHAT CARRYING LOOKS LIKE FROM IN HERE
--
-- Two functions and no module. CarryService requires THIS file -- it is
-- Priority 45 to this one's 40, because the pods it takes are the ones grown
-- here -- so this file cannot require it back. The catch happens in this tick
-- though, and the pod being caught lives over there.
--
-- Handed over at Start rather than required, which also means the failure mode
-- is the honest one: if CarryService never starts, this is nil, nothing is ever
-- confiscated, and every catch falls through to the throw it always was.
--==============================================================================
--==============================================================================
-- WHAT THIS SERVICE IS ALLOWED TO ASK OF THE ONES ABOVE IT
--
-- CarryService (45) and CombatService (70) both require NestService (40), so it
-- cannot require them back. Each hands down the few functions the nests need,
-- exactly as CarryService has since the confiscation pass.
--
-- `RefreshWalkSpeed` and `ReleaseTrap` are here for one reason, and it is the
-- freeze written up over `restore()` below: a guardian must be able to hand a
-- player's movement back correctly, and it cannot do that by remembering a
-- number, only by asking the file that owns the number.
--==============================================================================
type CarryBridge = {
	-- (victim, guardianAlreadyHauling) -> (outcome, held?). The roll, the mark
	-- or the take, in one call that does not yield. See GuardianCatch.
	ResolveGuardianCatch: (Player, boolean) -> (string, any),
	SpawnLoose: (string, number, CFrame, string?) -> boolean,
	RefreshWalkSpeed: ((Player) -> ())?,
	-- Stops held-plant recording before a body swap. See the LoadCharacter below.
	FreezeHeld: ((Player) -> ())?,
	-- Which nest the pod in this player's arms came off, or nil when they carry
	-- nothing from any nest. Decides who is still a thief worth remembering.
	CarriedFrom: ((Player) -> string?)?,
	-- Which secret encounter the pod in this player's arms belongs to, or nil.
	CarriedSecret: ((Player) -> string?)?,
}

type CombatBridge = {
	-- Ends a trap restraint early, idempotently. Returns true if one was held.
	ReleaseTrap: (Player, string) -> boolean,
}

local combatBridge: CombatBridge? = nil

function NestService.SetCombatBridge(bridge: CombatBridge?)
	combatBridge = bridge
end

local carryBridge: CarryBridge? = nil

function NestService.SetCarryBridge(bridge: CarryBridge?)
	carryBridge = bridge
end

--==============================================================================
-- A POD RUSH IS ON (2026-10-09; PodRushService says so, GameConfig.PodRush)
--
-- While it is, a taken slot grows back RegrowSeconds later (TakePod, step) and
-- a theft builds no rage past its own stack (provoke). Switched off, every
-- slot still waiting is forgotten: the rush's supply ends with the rush.
--==============================================================================
local RUSH = GameConfig.PodRush
local rushOn = false

function NestService.SetRush(on: boolean)
	rushOn = on == true
	if not rushOn then
		for _, nest in ipairs(nests) do
			nest.regrowAt = nil
		end
	end
end

function NestService.RushOn(): boolean
	return rushOn
end

local PARENT_HEIGHT = 15
--==============================================================================
-- THE RING HAD TO GROW WITH THE PODS
--
-- Every pod rolls its own weight now, so any slot can hold a 10,000 kg one --
-- and that is 10 studs across where the old heaviest was 4.5. Five pods on a
-- radius-13 ring sit 2 * 13 * sin(36 deg) = 15.3 studs apart, which leaves two
-- heavy neighbours 5 studs from touching and no way to walk between them.
--
-- At 16 the spacing is 18.8 and the gap is 8.8 -- wide enough to step through,
-- which matters because taking a pod means standing next to it. The parent
-- still sleeps at the centre, 11 studs clear of the widest shell.
--
-- The nest sits at x = 38 with the corridor wall at 70, so a 16-stud arm still
-- has 16 studs of clearance to the wall and leaves the racing line alone.
--==============================================================================
local NEST_RADIUS = 16
local TICK = 0.12

local function log(message: string)
	print("[Seed/NestService] " .. message)
end

--==============================================================================
-- BUILDING A NEST
--==============================================================================
local function podCFrames(centre: Vector3, count: number, facing: number): { CFrame }
	local out = {}
	for i = 1, count do
		local a = facing + (i - 1) / count * math.pi * 2
		out[i] = CFrame.new(centre + Vector3.new(math.sin(a) * NEST_RADIUS, 0,
			math.cos(a) * NEST_RADIUS))
	end
	return out
end

--==============================================================================
-- A POD INTO A SLOT, WHOEVER DECIDED WHAT IT IS
--
-- Split out of growPod so that a pod coming BACK -- confiscated off a thief and
-- walked home -- lands in a ring by exactly the same route a rolled one does:
-- same tags, same attributes, same queryability. A second way to put a pod in a
-- slot is a second set of attributes to keep in step, and the one that gets
-- forgotten is the one that makes a pod untakeable.
--==============================================================================
local function placePod(nest: Nest, index: number, species: SeedData.Species, tier: number)
	local pod = CreatureModel.BuildPod(species, tier, nest.slots[index], nest.folder)
	-- Loot. CreatureModel deliberately does not decide this: the same model
	-- hatching in a plot must never be takeable.
	CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)
	pod:SetAttribute(GameConfig.Attributes.BiomeId, nest.biome.Id)
	pod:SetAttribute("NestId", nest.id)
	pod:SetAttribute("SlotIndex", index)
	-- A pod on the ground is something you can walk up to and take, so it needs
	-- to be queryable even though nothing else this project builds is.
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	nest.pods[index] = pod
end

local function growPod(nest: Nest, index: number)
	if nest.pods[index] then
		return
	end
	--==========================================================================
	-- TWO ROLLS, AND THEY ARE INDEPENDENT
	--
	-- FORM comes from the biome pool by drop weight -- how often a bell turns up
	-- against a cube. WEIGHT comes from RollKg, one curve shared by all five
	-- species. Nothing correlates them on purpose: that is what makes a nest
	-- worth walking into instead of pattern-matching on shape from the road.
	-- A 10,000 kg Nubkin is legal, and it looks like a Nubkin.
	--
	-- One rng for both, so a slot's whole outcome comes from one seed.
	--==========================================================================
	local rng = Random.new(
		math.floor(nest.origin.X * 31 + nest.origin.Z * 17 + index * 7 + os.clock() * 1000))
	local species = SeedData.Roll(nest.biome.Id, rng)
	if not species then
		return
	end
	-- Stamped on the model by BuildPod, which is where every later reader --
	-- CarryService on pickup, the billboard, the shell colour -- gets it from.
	local tier = SeedData.RollTier(rng, nest.biome.RarityBonus)
	placePod(nest, index, species, tier)
end

--==============================================================================
-- THE SERVER DRIVES ITS OWN GUARDIANS (2026-10-01)
--
-- A guardian is an unanchored Humanoid, and under automatic ownership Roblox
-- hands its physics to the nearest player -- in a chase, the very player it is
-- chasing. That player's client then simulates the guardian, and this file's
-- MoveTo stops being what it does. Measured in Studio on Dustbowl's guardian
-- (57) against a player circling it at 42: owned by the chased player it ran
-- about 80 degrees off its orders and circled at 11-15 studs for twelve seconds
-- without a hit; owned by the server it hit 0.13 s into the same chase. The
-- owner was also the one deciding where the server thought the guardian stood.
--
-- So the server owns it: at build, and again whenever a chase starts. Called on
-- the guardian's own root, pcall'd like every ownership call in this file -- an
-- assembly outside the Workspace cannot be given an owner, and that must never
-- be what breaks a nest. Player bodies are still never taken for the server.
--==============================================================================
local function pinToServer(nest: Nest)
	local root = nest.root
	if root.Parent and not root.Anchored then
		pcall(root.SetNetworkOwner, root, nil)
	end
end

--==============================================================================
-- THE SECRET POD -- 2026-10-01
--
-- Greenhollow and Starbloom each have one secret (SeedData.SecretByBiome): a
-- pod the owner inserted by hand, at its authored size, standing on a dedicated
-- spot ACROSS THE ROAD from the nest on a platform in the biome's colours. It is
-- an ADDITION to the ring: the ring's own pods, rolls and slots are untouched.
--
-- ONE ROLL PER NEST, at the nest's initial stocking and at each dawn restock
-- (StockAll), at BiomeData Secret.SpawnChance -- never per slot, per player,
-- per frame or when a confiscated pod comes back. Skipped while the spot is
-- occupied or the encounter unresolved, with no attempt carried over.
--
-- NOTHING ROLLS WHILE GameConfig.Secret.Enabled IS FALSE: the only spawn then is
-- the Studio-only DebugService action, through NestService.SpawnSecret.
--
-- The platform stays until the encounter resolves -- the pod banked or
-- forfeited (CarryService tells us), or dusk clearing the road -- including a
-- confiscated pod walked back and stood on the spot again. Then it goes, and
-- the ground is what it was.
--==============================================================================
local SECRET = GameConfig.Secret
local secretRng = Random.new()
local secretSerial = 0

local function secretConfig(nest: Nest): BiomeData.SecretEncounter?
	return (nest.biome :: any).Secret
end

-- The spot: across the road, SpotX from the centre line, facing the road.
local function secretSpot(nest: Nest): CFrame
	local cfg = secretConfig(nest)
	local spotX = if cfg then cfg.SpotX else 42
	local x = if nest.origin.X < 0 then spotX else -spotX
	local at = Vector3.new(x, nest.origin.Y, nest.origin.Z)
	return CFrame.lookAt(at, Vector3.new(0, nest.origin.Y, nest.origin.Z))
end

local function platformPart(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Enum.Material.Plastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = parent
	return part
end

-- A cradle in the biome's colours: a bedding disc, a lighter heart, and stones
-- on the wall-side arc only -- nothing tall ever stands toward the racing line.
local function buildPlatform(nest: Nest, spot: CFrame): Folder
	local cfg = SECRET.Platform
	local folder = Instance.new("Folder")
	folder.Name = "SecretPlatform"
	folder.Parent = nest.folder
	local ground, accent, wall = nest.biome.GroundColor, nest.biome.AccentColor, nest.biome.WallColor
	local dark = Color3.new(ground.R * 0.72, ground.G * 0.72, ground.B * 0.72)
	local heart = Color3.new(accent.R * 0.62, accent.G * 0.62, accent.B * 0.62)
	local at = spot.Position
	-- A Cylinder lies along X, so it is rolled flat.
	platformPart("Bedding", Vector3.new(cfg.Thickness, cfg.Radius * 2, cfg.Radius * 2),
		CFrame.new(at + Vector3.new(0, cfg.Thickness * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), dark,
		Enum.PartType.Cylinder, folder)
	platformPart("Heart", Vector3.new(cfg.Thickness + 0.02, cfg.Radius * 1.1, cfg.Radius * 1.1),
		CFrame.new(at + Vector3.new(0, (cfg.Thickness + 0.02) * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), heart,
		Enum.PartType.Cylinder, folder)
	-- Deterministic: the same nest dresses the same spot the same way.
	local rng = Random.new(#nest.id * 31 + math.floor(math.abs(nest.origin.Z)))
	local toWall = if at.X < 0 then -1 else 1
	local centre = if toWall > 0 then 0 else math.pi
	local r = cfg.Radius - 2.4
	for i = 1, cfg.Stones do
		local a = centre + (-1 + 2 * (i - 0.5) / cfg.Stones) * math.rad(70) + rng:NextNumber(-0.08, 0.08)
		local size = Vector3.new(rng:NextNumber(2.4, 3.6), rng:NextNumber(1.4, 2.4), rng:NextNumber(2.2, 3.2))
		local pos = Vector3.new(at.X + math.cos(a) * r, at.Y + size.Y * 0.45, at.Z + math.sin(a) * r)
		platformPart("Stone", size, CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), a + rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.12, 0.12)),
			wall, Enum.PartType.Block, folder)
	end
	return folder
end

--==============================================================================
-- THE SECRET EGG TOAST (2026-10-05): ONE ROUTE FOR EVERY ANNOUNCEMENT
--
-- "A SECRET EGG SPAWNED ON {BIOME}!" to everybody in THIS server, once per
-- actual new egg: a road Secret's fresh spawn (spawnSecret), and a weather
-- event's special egg (GameConfig.Secret.Toast.WeatherEggs, the Thunderstorm's
-- Pod 3) when its biome opens (AnnounceEventEgg, asked by WeatherService, so
-- the console's storms and the automatic ones are told alike). Each carries a
-- stable spawn id: a client shows a spawn once, and a later spawn in the same
-- biome still shows. Never on a confiscated pod walked back, a guardian rebuilt,
-- a pickup, a respawn or a refused START, and nothing is replayed to a late
-- joiner. The biome goes as its id; the client shows the display name.
--==============================================================================
local announcer: ((string, string, number?) -> ())? = nil

-- `eventId`: the weather event whose egg it is, so a client can hold the toast
-- back until that storm's own opening toast has been read (ActionToastUI).
local function announceSecretEgg(spawnId: string, biomeId: string, eventId: number?)
	local seam = announcer
	if seam then
		seam(spawnId, biomeId, eventId)
		return
	end
	local remotes = SeedGame:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if remote and remote:IsA("RemoteEvent") then
		pcall(function()
			remote:FireAllClients("SecretSpawned", { id = spawnId, biome = biomeId, event = eventId })
		end)
	end
end

-- Studio specs: catch the announcements instead of firing them.
function NestService.SpecAnnouncer(fn: ((string, string, number?) -> ())?)
	if not RunService:IsStudio() then
		return
	end
	announcer = fn
end

-- The pod on the spot: the species' own pod (SecretForms), the loot tag, the
-- nest's name, the encounter's id. The same route for a fresh spawn and for a
-- confiscated pod walked back.
local function standSecretPod(nest: Nest, secret: Secret): Model?
	local species = SeedData.Get(secret.speciesId)
	if not species then
		return nil
	end
	local spot = secretSpot(nest)
	-- At SeedData.SecretTier, the one weight every Secret has: the admin grant gives the same.
	local pod = CreatureModel.BuildPod(species, SeedData.SecretTier,
		spot * CFrame.new(0, SECRET.Platform.Thickness + 0.02, 0), nest.folder)
	CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)
	pod:SetAttribute(GameConfig.Attributes.BiomeId, nest.biome.Id)
	pod:SetAttribute("NestId", nest.id)
	pod:SetAttribute("SecretId", secret.id)
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	secret.pod = pod
	return pod
end

local function spawnSecret(nest: Nest, why: string): (boolean, string?)
	local cfg = secretConfig(nest)
	local speciesId = SeedData.SecretByBiome[nest.biome.Id]
	if not (cfg and speciesId) then
		return false, "no secret for " .. nest.biome.Id
	end
	if nest.secret then
		return false, "the spot is taken"
	end
	secretSerial += 1
	local secret: Secret = {
		id = string.format("%s:secret:%d", nest.id, secretSerial),
		speciesId = speciesId,
		pod = nil,
		platform = nil,
		spawnedAt = os.clock(),
	}
	secret.platform = buildPlatform(nest, secretSpot(nest))
	nest.secret = secret
	if not standSecretPod(nest, secret) then
		secret.platform:Destroy()
		nest.secret = nil
		return false, "unknown species " .. speciesId
	end
	announceSecretEgg(secret.id, nest.biome.Id)
	log(string.format("%s spawned its secret %s (%s): %s.", nest.id, speciesId, secret.id, why))
	return true, nil
end

-- The encounter is over: whatever is still on the spot goes, the platform goes,
-- the ground is the road again, and nobody is marked for it any more.
local function resolveSecret(nest: Nest, why: string)
	local secret = nest.secret
	if not secret then
		return
	end
	nest.secret = nil
	if secret.pod and secret.pod.Parent then
		secret.pod:Destroy()
	end
	if secret.platform then
		secret.platform:Destroy()
	end
	table.clear(nest.marked)
	log(string.format("%s's secret %s is over: %s.", nest.id, secret.id, why))
end

local function rollSecret(nest: Nest, why: string)
	if not SECRET.Enabled then
		return
	end
	local cfg = secretConfig(nest)
	if not cfg or nest.secret then
		return
	end
	if secretRng:NextNumber() < cfg.SpawnChance then
		spawnSecret(nest, why)
	end
end

-- The biome's secret numbers, while the guardian is after a marked thief.
local function secretPursuit(nest: Nest): BiomeData.SecretEncounter?
	local cfg = secretConfig(nest)
	local target = nest.target
	if cfg and target and nest.marked[target] then
		return cfg
	end
	return nil
end

local function buildNest(site: BasePart, biome: BiomeData.Biome): Nest?
	local index = site:GetAttribute("NestIndex")
	local folder = Instance.new("Folder")
	folder.Name = string.format("Nest_%s_%02d", biome.Id, index or 0)
	folder.Parent = site.Parent

	local centre = site.Position
	-- Facing the middle of the road: a nest against the left wall should have
	-- its parent looking out at traffic, not at the wall.
	local outward = if centre.X < 0 then math.pi * 0.5 else -math.pi * 0.5
	-- Kept on the nest: a lost guardian is rebuilt from exactly this.
	local buildAt = CFrame.new(centre) * CFrame.Angles(0, outward, 0)
	local parentModel = ParentModel.Build(buildAt, PARENT_HEIGHT, biome.Id, folder)
	local humanoid = parentModel:FindFirstChildOfClass("Humanoid")
	local root = parentModel.PrimaryPart
	if not (humanoid and root) then
		warn("[Seed/NestService] parent for " .. biome.Id .. " has no Humanoid or root.")
		folder:Destroy()
		return nil
	end

	local nest: Nest = {
		id = folder.Name,
		biome = biome,
		origin = centre,
		homeCFrame = root.CFrame,
		parent = parentModel,
		humanoid = humanoid,
		root = root,
		folder = folder,
		slots = podCFrames(centre, biome.PodsPerNest, outward),
		pods = {},
		state = "asleep",
		chaseSince = 0,
		target = nil,
		stateUntil = 0,
		busy = false,
		rage = 0,
		calmSince = 0,
		haul = nil,
		sample = nil,
		thieves = {},
		secret = nil,
		marked = {},
		buildAt = buildAt,
		rigId = biome.Id,
		lastSeen = root.Position,
	}
	for i = 1, biome.PodsPerNest do
		growPod(nest, i)
	end
	pinToServer(nest)
	-- The one roll of the initial stocking.
	rollSecret(nest, "the nest was stocked")
	return nest
end

--==============================================================================
-- BEING PROVOKED
--
-- One definition of "somebody stole from me", used by taking a pod off the nest
-- AND by picking one up again after it has been dropped. A pod that has been
-- knocked out of a thief's hands is still this nest's pod, and walking back to
-- collect it has to wake the parent again -- otherwise being caught once makes
-- the rest of the raid free.
--==============================================================================
--==============================================================================
-- WHAT THE THIEF HAS EARNED, OR NOTHING IF WE CANNOT TELL
--
-- The SCORE, not the walk speed. Walk speed is what the score becomes after the
-- curve AND the carry multiplier, and a player hauling 10,000 kg would read as
-- catastrophically underlevelled when they are merely loaded -- which is
-- already punished, and does not need punishing twice.
--
-- nil for a player with no profile, which parentWalkSpeedFor reads as "leave
-- the speed alone" rather than "assume the worst".
--==============================================================================
local function speedScoreOf(player: Player?): number?
	if not player then
		return nil
	end
	local profile = PlayerDataService.Get(player)
	return if profile then profile.Speed else nil
end

-- Base speed for the biome, scaled by how far short of it the thief is, plus
-- whatever the nest is currently furious about.
local function baseSpeedFor(nest: Nest): number
	-- After a marked thief, the biome's secret chase speed (Greenhollow: 19
	-- against its stated 15) -- under test, the owner's numbers.
	local secret = secretPursuit(nest)
	if secret and secret.ChaseSpeed then
		return secret.ChaseSpeed
	end
	--==========================================================================
	-- A BIOME MAY STATE ITS OWN CHASE SPEED, AND ONE DOES
	--
	-- Greenhollow sets GuardianChaseSpeed because the formula's answer there was
	-- faster than the beginner the tutorial produces (see BiomeData). Every
	-- other biome leaves it nil and gets parentWalkSpeedFor exactly as before,
	-- shortfall scaling included.
	--
	-- The override deliberately does NOT take the shortfall term: a biome that
	-- names a flat speed is naming the speed it wants, and Greenhollow's
	-- recommendation is 0 so there was never a shortfall to scale there anyway.
	--==========================================================================
	local stated = tonumber((nest.biome :: any).GuardianChaseSpeed)
	if stated and stated == stated and stated > 0 then
		return stated
	end
	return GameConfig.parentWalkSpeedFor(
		nest.biome.RecommendedSpeed,
		speedScoreOf(nest.target)
	)
end

local function speedFor(nest: Nest): number
	return baseSpeedFor(nest)
		+ math.min(nest.rage, P.MaxRageStacks) * P.RageSpeedPerTake
end

--==============================================================================
-- A GUARDIAN WITH A PROFILE, OR NOBODY
--
-- Keyed on the SPECIES the builder stamped on the model, because that is the
-- same key ParentAnim dispatches on and a guardian's speed and its gait have to
-- be talking about the same animal. Four of the five return nil here and are
-- untouched by everything below.
--==============================================================================
local function profileOf(nest: Nest): any
	return GameConfig.guardianProfile(nest.parent:GetAttribute("Species"))
end

--==============================================================================
-- THE CHASE THAT GETS WORSE
--
-- The profile replaces the biome's flat speed and keeps everything that was
-- stacked on top of it: rage, and the shortfall a player who turned up
-- undergeared already pays. The shortfall is recovered by asking the formula
-- twice -- once with the thief and once without -- rather than by copying the
-- expression, so the two can never drift apart.
--
-- Squared, so most of the acceleration happens in the second half of the ramp:
-- the opening is survivable and it is the third second that is frightening.
--==============================================================================
local function ruleSpeedFor(nest: Nest, now: number): number
	local prof = profileOf(nest)
	if not prof then
		return speedFor(nest)
	end
	local rage = math.min(nest.rage, P.MaxRageStacks) * P.RageSpeedPerTake
	local rec = nest.biome.RecommendedSpeed
	-- A stated chase speed wins over a species ramp too. No biome currently has
	-- both -- Greenhollow's guardian has no profile -- but a future one adding a
	-- profile must not silently un-do the override sitting in its own data.
	local secret = secretPursuit(nest)
	local stated = if secret and secret.ChaseSpeed then secret.ChaseSpeed else tonumber((nest.biome :: any).GuardianChaseSpeed)
	if stated and stated == stated and stated > 0 then
		return stated + rage
	end
	local shortfall = GameConfig.parentWalkSpeedFor(rec, speedScoreOf(nest.target))
		- GameConfig.parentWalkSpeedFor(rec)
	local since = if nest.chaseSince > 0 then now - nest.chaseSince else 0
	-- The secret encounter's ramp (Astralmaw: 86 / 104 / 2.4 s against the
	-- profile's 78 / 96 / 3.4 s), under test.
	local opening, top, ramp = prof.OpeningSpeed, prof.TopSpeed, prof.RampSeconds
	if secret and secret.OpeningSpeed then
		opening = secret.OpeningSpeed
		top = secret.TopSpeed or top
		ramp = secret.RampSeconds or ramp
	end
	-- A hand-off after a catch runs at the ramp's top (rampDone, the owner's
	-- 2026-10-09 fix): the raid is the same raid.
	local u = if nest.rampDone then 1 else math.clamp(since / math.max(ramp, 0.01), 0, 1)
	--==========================================================================
	-- A SCALED GUARDIAN RUNS THE WHOLE OF THAT, SCALED (2026-10-02)
	--
	-- Stormstrider's profile is Astralmaw's with its own SpeedScale (2.5 since
	-- 2026-10-02): the ramp, the rage and the shortfall it would have run
	-- against this very player, all times that -- the owner's "x the Starbloom
	-- guardian under equivalent player conditions". Every other profile has no
	-- SpeedScale and is 1.
	--==========================================================================
	local scale = tonumber(prof.SpeedScale) or 1
	return (opening + (top - opening) * u * u
		+ rage + shortfall) * scale
end

--==============================================================================
-- A BEGINNER'S FIRST RAID IS FAIR AT THE GUIDE'S TARGET (2026-10-08)
--
-- The guide now asks for 400 Speed, not 1,000, and 400 walks at 21.2. Its
-- promise -- train to the target and you get the pod home -- is kept HERE, for
-- exactly one chase: the theft that woke a calm nest (rage 0 before it) by a
-- thief whose `steal` step was not done, on a biome naming FirstRaidChaseSpeed
-- (Greenhollow: 19, against the 20 its first theft runs at; the arithmetic is
-- in BiomeData). The chase is CAPPED at that number, never raised to it.
--
-- EVERYTHING ELSE IS GREENHOLLOW AS IT WAS. A second theft before the nest
-- calms (rage 2, the same thief or anybody) runs at 25; anybody else is chased
-- at 20; a Secret's thief at the Secret's numbers; another biome or the weather
-- event's nest has no number to cap with. And the cap is a NUMBER, not the
-- thief's own speed less a margin: a player at Speed 0 walks 16 against 19 and
-- is still caught -- the lesson survives.
--
-- The guide's record is read through `stealDone` so a spec can say what it is
-- without a profile (SpecStealDone). nil -- no record yet -- is not a beginner.
--==============================================================================
local stealDoneFn: ((any) -> boolean?)? = nil

local function stealDone(player: any): boolean?
	local fn = stealDoneFn
	if fn then
		return fn(player)
	end
	if typeof(player) ~= "Instance" then
		return nil
	end
	return PlayerDataService.TutorialDone(player, "steal")
end

-- Whether a theft from calm by `thief` starts a beginner's first raid here.
local function startsFirstRaid(nest: Nest, thief: Player, secretId: string?): boolean
	local fair = tonumber((nest.biome :: any).FirstRaidChaseSpeed)
	if not (fair and fair == fair and fair > 0) then
		return false
	end
	if secretId ~= nil or nest.marked[thief] then
		return false
	end
	return stealDone(thief) == false
end

-- The cap, while it applies: the first raid's thief is the target, the rage is
-- still that one theft, and no Secret is being chased.
local function firstRaidSpeedFor(nest: Nest): number?
	local thief = nest.firstRaid
	if thief == nil or thief ~= nest.target or nest.rage > 1 or secretPursuit(nest) ~= nil then
		return nil
	end
	local fair = tonumber((nest.biome :: any).FirstRaidChaseSpeed)
	if not (fair and fair == fair and fair > 0) then
		return nil
	end
	return fair
end

local function chaseSpeedFor(nest: Nest, now: number): number
	local speed = ruleSpeedFor(nest, now)
	local fair = firstRaidSpeedFor(nest)
	return if fair then math.min(fair, speed) else speed
end

local function returnSpeedFor(nest: Nest): number
	local prof = profileOf(nest)
	if prof then
		return prof.ReturnSpeed
	end
	return speedFor(nest)
end

--==============================================================================
-- WRITE A WALKSPEED ONLY WHEN IT CHANGED
--
-- The ramp recomputes eight times a second and the Humanoid does not need to be
-- told the same number again; a property write that replicates is not free.
--==============================================================================
local function setWalk(nest: Nest, speed: number)
	if math.abs(nest.humanoid.WalkSpeed - speed) > 0.05 then
		nest.humanoid.WalkSpeed = speed
	end
end

--==============================================================================
-- HAS THIS THIEF EARNED A HEAD START
--
-- The biome's RecommendedSpeed stops being purely advisory at exactly one
-- moment: the instant a pod leaves the nest. Walking in, looking around and
-- walking out again is free at any Speed and stays free -- the road is open and
-- nothing here closes it.
--
-- GREENHOLLOW ALWAYS QUALIFIES. Its recommendation is 0, so there is nothing to
-- fall short of, and the tutorial biome must never be the one that teaches a
-- new player they are not allowed to play.
--
-- SO DOES A PLAYER WE CANNOT MEASURE. A nil score is a profile that has not
-- loaded, not a poor one; the same reading parentWalkSpeedFor already takes.
--
-- The score is the SERVER'S. Not a replicated attribute, not an afterimage
-- tier, not anything the client has touched -- those are all things a client
-- can be made to say.
--
-- AND DUSTBOWL GIVES IT TO EVERY THIEF WHO TAKES FROM THE NEST (2026-09-27).
-- A biome with HeadStartBelowRecommended gives the same delay to a thief below
-- its recommendation -- but only when `fromNest` says this is a pod taken out
-- of the nest itself. A dropped pod picked back up (NestService.Provoke) is
-- never a fresh theft, so it never earns a fresh head start, and a guardian
-- already awake never reaches this function at all. See BiomeData.
--==============================================================================
local function qualifiesForHeadStart(nest: Nest, thief: Player, fromNest: boolean): boolean
	local recommended = nest.biome.RecommendedSpeed
	if type(recommended) ~= "number" or recommended ~= recommended or recommended <= 0 then
		return true
	end
	local score = speedScoreOf(thief)
	if score == nil or score ~= score then
		return true
	end
	if score >= recommended then
		return true
	end
	return fromNest and (nest.biome :: any).HeadStartBelowRecommended == true
end

--==============================================================================
-- CARRYING SOMETHING IS NOT AN EXCUSE NOT TO CHASE YOU
--
-- This refused to retarget a guardian mid-haul, on the theory that dropping the
-- haul to chase a second thief is how one pod becomes zero. The theory was
-- fine and the behaviour was not: the walk home is ten to fifteen seconds of a
-- guardian that CANNOT respond, so stealing, getting caught, and then robbing
-- the ring while it trudges away was a free pod every time. Reported from the
-- first real session -- *"i took one again and it doesnt chase me this time"* --
-- and it is precisely the safe farm `rage` exists to prevent.
--
-- The haul does not need protecting from the chase, because the haul is not a
-- STATE, it is a field. It survives a chase the way it survives anything else,
-- and every road back to the nest goes through `goHome`, which returns to
-- `hauling` whenever there is still something to carry. A guardian that catches
-- you while already holding a pod simply cannot take a second one --
-- `confiscateFrom` sees its hands are full -- so you keep yours, and the throw
-- knocks it out of them onto the road exactly as Greenhollow's would.
--==============================================================================
-- Defined with the lifecycle, below. Declared here so a theft can publish the
-- wake the moment it happens instead of up to a tick later: the "WAKING" warning
-- is only worth anything inside the delay it is warning about.
local publishPursuit: () -> ()

local function targetPosition(player: Player?): Vector3?
	if not player or player.Parent ~= Players then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart") and humanoid.Health > 0) then
		return nil
	end
	return root.Position
end

-- Where a player stands if a guardian may chase them at all: here, alive, and
-- not in the Safe Zone. The same three things that end a chase in the tick.
local function chaseable(player: Player?): Vector3?
	local pos = targetPosition(player)
	if not pos or MapService.IsInSafeZone(pos) then
		return nil
	end
	return pos
end

-- A remembered thief is still one only while chaseable AND still carrying a pod
-- off THIS nest. Without a carry bridge there is no way to ask, and the first
-- three conditions decide alone.
local function eligibleThief(nest: Nest, player: Player): Vector3?
	local pos = chaseable(player)
	if not pos then
		-- Safety, death or leaving: the secret encounter lets go of them too.
		nest.marked[player] = nil
		return nil
	end
	-- A thief marked by the secret encounter is still one with empty hands.
	if nest.marked[player] then
		return pos
	end
	local bridge = carryBridge
	local carriedFrom = bridge and bridge.CarriedFrom
	if carriedFrom then
		local ok, from = pcall(carriedFrom, player)
		if not ok or from ~= nest.id then
			return nil
		end
	end
	return pos
end

-- `fromNest` is true only for a pod taken out of the nest itself (TakePod); a
-- dropped pod picked back up arrives through NestService.Provoke with false.
local function provoke(nest: Nest, thief: Player, fromNest: boolean, secretId: string?)
	-- Taking THIS nest's secret marks the thief for the encounter (see the Nest
	-- type): the secret numbers, and a chase that outlives the pod in their arms.
	if secretId and nest.secret and nest.secret.id == secretId then
		nest.marked[thief] = true
	end
	-- A BEGINNER'S FIRST RAID (firstRaidSpeedFor): decided by a theft from calm,
	-- and only there -- a theft into an angry nest is never one.
	if nest.rage <= 0 then
		nest.firstRaid = if startsFirstRaid(nest, thief, secretId) then thief else nil
		if nest.firstRaid then
			log(string.format("%s's first raid on %s: chased at no more than %s.",
				tostring((thief :: any).Name), nest.id, tostring((nest.biome :: any).FirstRaidChaseSpeed)))
		end
	end
	-- EVERY theft stacks, including picking a dropped pod back up. Losing a pod
	-- and strolling back for it is the obvious way to farm a nest safely, so the
	-- second attempt has to be harder than the first.
	--
	-- BUT NOT IN A POD RUSH (2026-10-09, the owner's call): guardians chase as
	-- usual -- every theft is chased as the first one is, at one stack -- and
	-- build no rage, or four stacks (+20 speed) would wall off a five-minute
	-- sprint.
	if rushOn then
		nest.rage = 1
	else
		nest.rage += 1
	end
	--==========================================================================
	-- ONE CHASE AT A TIME, AND NOBODY FORGOTTEN (2026-10-01)
	--
	-- This used to ALWAYS re-target: the newest thief took the chase and the one
	-- being chased walked away clean, forgotten -- and two players could swap a
	-- guardian back and forth between them by taking turns. Now a guardian busy
	-- with a target it can still chase keeps that target, and the new thief is
	-- REMEMBERED: when this chase ends -- a catch, a throw, the target reaching
	-- safety -- the nearest thief still eligible is next, before it goes home.
	-- A theft during a throw or a walk home is remembered the same way, because
	-- the target stays the person being thrown until the throw is over.
	--
	-- Rage still stacks above on every theft, remembered or not, and a chasing
	-- guardian still speeds up for it at once.
	--==========================================================================
	local current = nest.target
	if not GuardianPursuit.takesOver(current, thief, current ~= nil and chaseable(current) ~= nil) then
		nest.thieves[thief] = os.clock()
		-- A theft while the last victim is in the air, the guardian free of
		-- them since the launch (2026-10-09): chased now, not after the landing.
		local free = nest.handOff
		if free then
			free()
		end
		if nest.state == "chasing" then
			setWalk(nest, chaseSpeedFor(nest, os.clock()))
		end
		pcall(publishPursuit)
		return
	end
	nest.thieves[thief] = nil
	pinToServer(nest)
	-- WAKE, ON A DELAY. The delay is the head start, and it is the whole skill
	-- of a raid.
	if nest.state == "asleep" then
		--==================================================================
		-- THE ROAR, WHICH IS THE ONLY WARNING A THIEF GETS
		--
		-- Before 2026-09-17 a parent woke in silence: the head start was 1.2
		-- seconds of a monster standing up behind you with nothing to hear,
		-- and a raider facing away learned about it when it arrived. The
		-- sound does not change the rules -- the delay, the speed and the
		-- rage are all exactly as they were -- it just says out loud what
		-- already happened.
		--
		-- HERE, AND NOT AT THE Asleep FLIP. There are two ways out of this
		-- branch and only one of them clears Asleep in this tick; the other
		-- clears it 1.2 seconds later in the tick's waking -> chasing step.
		-- Both are the same event to a player, so the roar goes where the
		-- event is: the moment the nest was robbed. It is also why this sits
		-- above the branch rather than in each side of it.
		--
		-- ONE PER WAKE. `provoke` is called on every theft, but a nest that
		-- is already chasing, returning or hauling never enters this branch,
		-- so a second pod out of the same nest does not roar again.
		--
		-- Server-side, like every other one-shot tied to a moment the server
		-- owns: one Sound at the nest that everybody in earshot hears at the
		-- same instant, instead of a remote to each of them. See SoundKit.
		--==================================================================
		local roar = SoundKit.parentCue(nest.biome.Id, "Wake")
		if roar then
			SoundKit.emit(roar, nest.root)
		end
		if qualifiesForHeadStart(nest, thief, fromNest) then
			nest.state = "waking"
			-- A marked thief gets the secret encounter's shorter delay (0.6 s
			-- against 1.2), under test.
			local cfg = secretConfig(nest)
			local delay = if nest.marked[thief] and cfg then cfg.WakeDelaySeconds else P.WakeDelaySeconds
			nest.stateUntil = os.clock() + delay
		else
			--==============================================================
			-- UNDER-SPEED: THE DELAY IS WHAT IS TAKEN AWAY, NOT THE RULES
			--
			-- The parent is up and after them in the same tick, which is the
			-- whole of the penalty. It is not a second catch system and it is
			-- not an absurd WalkSpeed: it is the ONE chase, minus the 1.2
			-- seconds that make a raid winnable. parentWalkSpeedFor is
			-- already leaning on the same shortfall, so an under-levelled
			-- thief now meets a faster parent that also never overslept.
			--
			-- Asleep must be cleared HERE. It is normally cleared by the
			-- waking -> chasing transition in the tick, and skipping that
			-- state skips the clear -- which would leave the parent sprinting
			-- down the road while every client still drew it curled up
			-- asleep beside the nest.
			--==============================================================
			nest.state = "chasing"
			nest.chaseSince = os.clock()
			nest.rampDone = nil
			nest.stateUntil = 0
			nest.parent:SetAttribute("Asleep", false)
		end
	elseif nest.state == "returning" or nest.state == "hauling" then
		-- Already up and walking home, with or without a pod in its fist. No
		-- second delay -- it never went back to sleep, so it has nothing to wake
		-- up from. The haul rides along and `goHome` picks the walk back up.
		nest.state = "chasing"
		nest.chaseSince = os.clock()
		nest.rampDone = nil
	end
	-- Taking over: from nobody, from the same thief, or from a target that can no
	-- longer be chased. A new target starts a new sweep.
	if current ~= thief then
		nest.sample = nil
	end
	nest.target = thief
	if nest.state == "chasing" then
		-- Already running. Speed up mid-chase rather than waiting for the next
		-- state change, which might never come.
		setWalk(nest, chaseSpeedFor(nest, os.clock()))
	end
	-- WakingBy / PursuedBy on the thief, now. pcall for the same reason the tick
	-- wraps it: a warning must never be the thing that breaks a theft.
	pcall(publishPursuit)
end

--==============================================================================
-- TAKING A POD
--
-- The seam CarryService calls. Returns the species so the caller knows what it
-- is now holding, and nil if the pod was already gone -- two players reaching
-- the same pod in the same frame is a race this has to lose gracefully rather
-- than hand out two prizes.
--==============================================================================
-- A slot's pod leaves the ring: empty for the rest of the day -- unless a Pod
-- Rush is on, when it grows back RegrowSeconds from now (step). Never a weather
-- event's nest: its one batch is the event's.
local function takeSlot(nest: Nest, slot: number, pod: Model, thief: Player)
	nest.pods[slot] = nil
	pod:Destroy()
	if rushOn and nest.event == nil then
		local due = nest.regrowAt or {}
		nest.regrowAt = due
		due[slot] = os.clock() + RUSH.RegrowSeconds
	end
	provoke(nest, thief, true)
end

function NestService.TakePod(pod: Model, thief: Player): SeedData.Species?
	local nestId = pod:GetAttribute("NestId")
	local slot = pod:GetAttribute("SlotIndex")
	local speciesId = pod:GetAttribute("SpeciesId")
	local secretId = pod:GetAttribute("SecretId")
	--==========================================================================
	-- THE SECRET POD, OFF ITS SPOT. Not a slot: the encounter record is what
	-- says whether this pod is the one standing there, and the same frame-race
	-- rule applies. Taking it marks the thief (provoke).
	--==========================================================================
	if type(nestId) == "string" and type(secretId) == "string" and type(speciesId) == "string" then
		for _, nest in ipairs(nests) do
			if nest.id == nestId then
				local secret = nest.secret
				if not (secret and secret.id == secretId and secret.pod == pod) then
					return nil
				end
				secret.pod = nil
				pod:Destroy()
				provoke(nest, thief, true, secretId)
				return SeedData.Get(speciesId)
			end
		end
		return nil
	end
	if type(nestId) ~= "string" or type(slot) ~= "number" or type(speciesId) ~= "string" then
		return nil
	end

	for _, nest in ipairs(nests) do
		if nest.id == nestId then
			if nest.pods[slot] ~= pod then
				-- Somebody else already took it this frame.
				return nil
			end
			-- Empty for the rest of the day, outside a Pod Rush (takeSlot).
			takeSlot(nest, slot, pod, thief)
			return SeedData.Get(speciesId)
		end
	end
	return nil
end

--==============================================================================
-- THE RAGDOLL
--
-- What used to happen here was a ballistic HOP: solve a parabola, fire it, wait
-- the exact flight time, then zero the horizontal velocity on the way down. The
-- arc was mathematically perfect and it could never bounce, never clip a wall,
-- never do anything but land on its mark and stand up. A thrown player looked
-- like a thrown crate on rails.
--
-- Now: shove, let go of the pose, and let the world do the rest. Walls and the
-- floor bounce the body because they COLLIDE, not because anything in Lua
-- reflects a velocity vector.
--
--==============================================================================
-- DRIVE WHATEVER THE RIG ACTUALLY HAS
--
-- The same lesson CarryPose paid for. A modern Roblox avatar is a physics rig:
--
--     AnimationConstraint x15   BallSocketConstraint x14   Motor6D x0
--
-- The sockets are ALREADY THERE holding the skeleton together; what keeps it
-- standing in a pose is the AnimationConstraints driving each joint. Switch
-- those off and the sockets are all that is left, which is a ragdoll. A
-- Motor6D-only implementation would have found nothing to disable here and
-- silently produced the same rigid hop.
--
--==============================================================================
-- LIMBS HAVE TO COLLIDE OR THERE IS NO BOUNCE
--
-- If only the HumanoidRootPart collides, the body is a capsule on a string and
-- you are back to the hop with extra steps. Every body part's CanCollide is
-- captured and forced on, and put back exactly as it was on stand-up --
-- captured rather than assumed, because a character that stands up with the
-- wrong collision set is a character that falls through the road later.
--
-- Accessories are skipped on purpose: a hat that collides with the floor wedges
-- the head at a strange angle and stops the body settling at all.
--==============================================================================
--==============================================================================
-- THE SERVER MAKES THE BODY LIMP. THE OWNER THROWS IT.
--
-- A player's character is simulated by THAT PLAYER, and there is no way around
-- that worth having. An earlier version took the assembly with
-- SetNetworkOwner(nil) so the server's simulation would be the one that
-- replicated. On paper it worked -- 99% of ragdoll frames server-owned, a
-- measurable tumble, a measurable bounce. In play it was worse than the hop:
-- the victim stayed stuck inside the parent, saw nothing, and was then
-- teleported to wherever the server's copy had landed when ownership went back.
--
-- Everything measured about it was true and none of it was on the victim's
-- screen, because the thing being measured was never the body being rendered.
--
-- So the work is split by WHO OWNS WHAT:
--
--   SERVER   PlatformStand, the pod drop, WalkSpeed, limpness, collision --
--            all PROPERTIES, which replicate to everybody, so a watcher three
--            plots away sees a limp body rather than a jogging one.
--
--   OWNER    the impulse and the tumble. Its physics already replicate out to
--            the server and to every other client, for free.
--
-- Never take a player's character again.
--==============================================================================
type Loosened = {
	constraints: { AnimationConstraint },
	motors: { Motor6D },
	collides: { { part: BasePart, was: boolean } },
	-- Ball sockets whose joint friction a guardian throw let go of; empty for
	-- everything else. See slackenJoints.
	frictions: { { socket: BallSocketConstraint, was: number } },
	-- THE VICTIM SIMULATES THEIR OWN LIMP BODY; see pinOwnership. The player it
	-- was pinned to, each part's automatic-ownership flag from before, and
	-- whether the pin is still being held. Empty for a character no player owns.
	owner: Player?,
	autos: { { part: BasePart, auto: boolean } },
	pinning: boolean,
	character: Model,
	-- Holds the HumanoidRootPart to the LowerTorso while the Root joint is off;
	-- see THE ROOT RIDES WITH THE PELVIS.
	rootWeld: WeldConstraint?,
}

--==============================================================================
-- THE VICTIM SIMULATES THEIR OWN LIMP BODY, BY NAME RATHER THAN BY LUCK
--
-- The live defect that survived every Studio pass, found 2026-09-22 by putting
-- the published servers' logs next to Studio's:
--
--                              live (17 throws)      Studio (61 throws)
--     settled after            median 1.62 s         median 3.1 - 3.6 s
--                              15 of 17 at the       never under 2.2 s
--                              earliest possible
--     root to torso at settle  median 126 - 304      median 18 - 46 studs
--
-- On a published server the visible body stopped almost where it was hit while
-- the invisible root flew the whole launch -- on v966 as on v949, with every
-- constraint off and the friction at zero. The rig WAS limp. It was not being
-- simulated by the machine that threw it.
--
-- Measured in Studio, on the server, at the frame the constraints go off: the
-- HumanoidRootPart stays the victim's, and every one of the fifteen new body
-- assemblies starts out owned by the SERVER. Studio hands them back to the
-- victim 0.06 s later. A published server leaves the body with itself -- and
-- by the time it would look again, the root it judges "near the player" by is a
-- hundred studs away. So the victim's launch, spin and limb kicks were written
-- to parts it did not own, and the server dropped the body where it stood.
-- Forcing exactly that in Studio reproduced the live numbers: 54 studs of
-- travel instead of 210, settled at 1.75 s, root 140 studs off the torso.
--
-- So the victim is made the owner, explicitly, of every part of the body the
-- moment the joints let go -- and re-asserted for PIN_WINDOW, because the split
-- into assemblies and the engine's first assignment land within a frame or two
-- of this call. Pinned in Studio: 232 studs of travel, settled at 3.0 s.
--
-- THIS IS THE OPPOSITE OF WHAT THE BANNER ABOVE FORBIDS. That was taking the
-- body AWAY from its player with SetNetworkOwner(nil); this makes sure the
-- player keeps it. ragdollOff gives the parts back to automatic ownership once
-- the joints are on again -- a whole character is its player's either way.
--==============================================================================
local PIN_WINDOW = 0.5

-- Every loose part of the body onto `player`, MANUALLY: a part that is theirs
-- only by automatic assignment is exactly what a published server takes back
-- once the root has flown off. How many were not pinned yet.
local function pinOwnership(character: Model, player: Player): number
	local moved = 0
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not d.Anchored then
			local okOwner, owner = pcall(d.GetNetworkOwner, d)
			local okAuto, auto = pcall(d.GetNetworkOwnershipAuto, d)
			if not (okOwner and owner == player and okAuto and auto == false) then
				pcall(d.SetNetworkOwner, d, player)
				moved += 1
			end
		end
	end
	return moved
end

-- Which characters are limp right now, and the record that will stand them back
-- up. A guardian does not throw a body that something else is already
-- throwing: the second ragdollOn would find every constraint already off and
-- take an EMPTY record, and the first one's restore would switch the joints
-- back on in the middle of the second launch.
local ragdolled: { [Model]: Loosened } = {}
-- The weld ragdollOn hangs on the root; see THE ROOT RIDES WITH THE PELVIS.
local ROOT_WELD = "SeedRagdollRootWeld"

local function ragdollOn(character: Model): Loosened
	local out: Loosened = { constraints = {}, motors = {}, collides = {}, frictions = {},
		owner = nil, autos = {}, pinning = false, character = character, rootWeld = nil }

	--==========================================================================
	-- THE ROOT RIDES WITH THE PELVIS
	--
	-- The Root joint is an AnimationConstraint like the rest, and switching it
	-- off below turned the HumanoidRootPart into a free, colliding 2 x 2 x 1
	-- box -- a quarter of the body's mass, with no NoCollision against the
	-- LowerTorso. Measured in Play on 2026-09-26: a bat knockdown backed into a
	-- plot fence stopped the BODY at the rails while the root flew on 110 studs
	-- towards the hub; the camera, which follows the root on a bat hit, went
	-- with it, and snapped 115 studs back at recovery. The player's position,
	-- as the server reads it, went with it too.
	--
	-- So the root is welded to the pelvis for as long as the body is limp, and
	-- stops colliding: every joint still lets go, every limb still flops and
	-- RagdollGate still sees the rig come apart -- the root simply cannot leave
	-- the body it belongs to. Made before the joints go, so it holds the pose
	-- they stood in; ragdollOff takes it away before they come back.
	--==========================================================================
	local root = character:FindFirstChild("HumanoidRootPart")
	local pelvis = character:FindFirstChild("LowerTorso")
	if root and root:IsA("BasePart") and pelvis and pelvis:IsA("BasePart")
		and not root:FindFirstChild(ROOT_WELD) then
		local weld = Instance.new("WeldConstraint")
		weld.Name = ROOT_WELD
		weld.Part0 = root
		weld.Part1 = pelvis
		weld.Parent = root
		out.rootWeld = weld
		table.insert(out.collides, { part = root, was = root.CanCollide })
		root.CanCollide = false
	end

	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("AnimationConstraint") then
			if d.Enabled then
				d.Enabled = false
				table.insert(out.constraints, d)
			end
		elseif d:IsA("Motor6D") then
			-- Classic rigs only. Left ENABLED: without ball sockets to take over,
			-- disabling these does not ragdoll a character, it dismembers one.
			-- Such a rig tumbles rigidly, which still bounces.
			table.insert(out.motors, d)
		end
	end
	for _, d in ipairs(character:GetChildren()) do
		--======================================================================
		-- NOT THE HEAD, AND NOTHING INVISIBLE.
		--
		-- A colliding Head is what wedges a ragdoll against geometry and holds
		-- the camera inside a mesh; and the HumanoidRootPart is a Transparency=1
		-- box the player is not supposed to be able to touch the world with.
		-- Making either collidable turns the tumble into a body jammed in a wall
		-- with the camera inside its own skull.
		--======================================================================
		if d:IsA("BasePart") and d.Name ~= "Head" and d.Transparency < 1 then
			table.insert(out.collides, { part = d, was = d.CanCollide })
			d.CanCollide = true
		end
	end

	-- The body stays its player's to simulate: see THE VICTIM SIMULATES THEIR
	-- OWN LIMP BODY. Captured, pinned now, and held for PIN_WINDOW.
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		out.owner = player
		out.pinning = true
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") and not d.Anchored then
				local ok, auto = pcall(d.GetNetworkOwnershipAuto, d)
				table.insert(out.autos, { part = d, auto = ok and auto == true })
			end
		end
		pinOwnership(character, player)
		task.spawn(function()
			local deadline = os.clock() + PIN_WINDOW
			local steady = 0
			while out.pinning and os.clock() < deadline and character.Parent do
				task.wait()
				if not out.pinning then
					return
				end
				-- Two clean frames in a row: the split has happened and every new
				-- assembly came out the victim's.
				if pinOwnership(character, player) == 0 then
					steady += 1
					if steady >= 2 then
						return
					end
				else
					steady = 0
				end
			end
			if out.pinning and character.Parent then
				-- Bounded, and only when something is wrong: a body the engine keeps
				-- taking back is the live defect coming back.
				warn(string.format("[Seed/NestService] a ragdolled body did not stay with its player for %.1fs; " ..
					"its limbs may be simulated elsewhere.", PIN_WINDOW))
			end
		end)
	end

	ragdolled[character] = out
	return out
end

--==============================================================================
-- LOOSE MEANS LOOSE: THE JOINTS' OWN FRICTION, LET GO FOR A GUARDIAN'S THROW
--
-- Switching the AnimationConstraints off leaves the BallSocketConstraints, and
-- the engine builds those WITH FRICTION. Read off the rig 2026-09-22:
--
--     hips 14.7   elbows 18.3   shoulders 18.8   wrists 28.8   knees 35.1
--     neck 40.9   waist 43.7    ankles 52.3        (MaxFrictionTorque)
--
-- on limbs a fraction of a unit of mass each. So a rig with every constraint
-- off and sixteen loose assemblies still held each limb at whatever angle it
-- had: measured frame by frame on the victim, the joint angles sat on the same
-- eight numbers for a second of flight, and only the landing -- an impact big
-- enough to beat the friction -- bent anything. That is the owner's report from
-- a published server: "the body remains rigid instead of the limbs becoming
-- loose during the throw and landing."
--
-- For the throw it goes to LIMP_JOINT_FRICTION. The sockets' anatomical limits
-- stay exactly as the engine made them, so a knee still only bends one way.
-- Captured per socket into the same record the constraints and collisions go
-- in, and put back by ragdollOff with them -- once, on every exit restore()
-- covers.
--
-- A GUARDIAN THROW ONLY. CombatService's bat knockdown and the traps use the
-- same ragdollOn and get an empty list here, so their joints are as they were.
--==============================================================================
local LIMP_JOINT_FRICTION = 0

local function slackenJoints(loosened: Loosened, character: Model)
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BallSocketConstraint") and d.MaxFrictionTorque > LIMP_JOINT_FRICTION then
			table.insert(loosened.frictions, { socket = d, was = d.MaxFrictionTorque })
			d.MaxFrictionTorque = LIMP_JOINT_FRICTION
		end
	end
end

--==============================================================================
-- THE NECK TAKES ITS FRICTION BACK ONCE THE BODY IS DOWN
--
-- Loose joints are for the flight and the landing. Lying on the ground, a neck
-- with no friction at all is what the owner recorded on a published server
-- 2026-09-26: the head bobbing over a body that lay still, the camera going
-- with it, and every knockdown running to ThrowFX's five-second give-up.
-- Player log, v986, and the same in Studio 2026-09-28 once the head was made
-- non-colliding the way the live one reports itself -- with nothing driving it:
--
--     the head    circles the neck's limit: +-0.42 studs in the torso's space
--                 at 4.3 Hz, 7 studs a second, the same amplitude every turn
--     the torso   0.8 studs a second
--
-- Nothing takes that motion's energy out: the socket has no friction, the head
-- touches nothing, and sliding round a limit costs nothing. The landing starts
-- it and the stand-up is what ended it.
--
-- So once the torso is down the neck -- that socket only -- gets back the
-- friction slackenJoints took from it: the captured value, out of the same
-- record. Every other joint stays loose until ragdollOff, which still writes
-- all of them, the neck included, and is still what empties the record.
--
-- WHO WRITES IT: THE SERVER, LIKE EVERY OTHER PROPERTY OF A LIMP BODY. The
-- victim's machine simulates the body and is the only one that knows it has
-- landed, so it says so (acceptThrowAnswer, the landing report) and the server
-- writes the property, which replicates to the victim the way the zero did. The
-- victim never writes a joint's friction itself: two machines holding different
-- values for one property is the disagreement this avoids.
--==============================================================================
local function stiffenNeck(loosened: Loosened): boolean
	local neck = RagdollGate.neckSocket(loosened.character)
	if not (neck and neck.Parent) then
		return false
	end
	for _, entry in ipairs(loosened.frictions) do
		if entry.socket == neck then
			neck.MaxFrictionTorque = entry.was
			return true
		end
	end
	-- Not a guardian's record: a bat's and a trap's never let go of a joint.
	return false
end

local function ragdollOff(loosened: Loosened)
	loosened.pinning = false
	-- Before the joints: the Root joint takes the root back, not the weld.
	if loosened.rootWeld then
		loosened.rootWeld:Destroy()
		loosened.rootWeld = nil
	end
	for _, c in ipairs(loosened.constraints) do
		if c.Parent then
			c.Enabled = true
		end
	end
	for _, entry in ipairs(loosened.collides) do
		if entry.part.Parent then
			entry.part.CanCollide = entry.was
		end
	end
	for _, entry in ipairs(loosened.frictions) do
		if entry.socket.Parent then
			entry.socket.MaxFrictionTorque = entry.was
		end
	end
	-- After the joints, so the parts go back to automatic ownership as the one
	-- assembly they are again. A part that was pinned before this ragdoll -- by
	-- anything -- keeps its pin.
	for _, entry in ipairs(loosened.autos) do
		if entry.auto and entry.part.Parent then
			pcall(entry.part.SetNetworkOwnershipAuto, entry.part)
		end
	end
	-- Once: a second ragdollOff on the same record has nothing to give back.
	table.clear(loosened.frictions)
	table.clear(loosened.autos)
	if ragdolled[loosened.character] == loosened then
		ragdolled[loosened.character] = nil
	end
end

-- Whether a ragdoll that ragdollOn started is still holding this character.
local function isRagdolled(character: Model): boolean
	return ragdolled[character] ~= nil
end

--==============================================================================
-- THE RAGDOLL, UNDER A PUBLIC NAME
--
-- CombatService needs exactly this when a player's bat lands: the same sixteen
-- constraints off, the same head left non-collidable, the same restore. Two
-- thin aliases rather than a second copy, because the reasoning above them --
-- what a limp R15 actually is, and why the Head must not collide -- was paid
-- for once and must not be paid for again in another file.
--
-- ALIASES, NOT A MOVE. Every guardian call site still goes through the locals,
-- unchanged and un-renamed, so nothing about the guardian throw is touched by
-- this being here.
--==============================================================================
NestService.RagdollOn = ragdollOn
NestService.RagdollOff = ragdollOff
NestService.IsRagdolled = isRagdolled
-- Exposed for GuardianRagdollSpec; the guardian throw below is the only caller.
NestService.SlackenJoints = slackenJoints
NestService.StiffenNeck = stiffenNeck

-- The backstop. The victim's client reports when it has stopped; this is what
-- happens when it never does -- a body wedged in geometry, a client that left,
-- a client that simply does not answer. A character must always come back.
local THROW_TIMEOUT = 6

--==============================================================================
-- THE FLOOR OF THE WORLD, FOR A BODY THAT HAS LEFT IT
--
-- Every lane floor sits at Y = 0 and the road is a 140-stud corridor between
-- 46-stud walls. A profiled throw (Astralmaw: 300 studs a second, lift 0.55)
-- peaks near 75 studs, so any throw with a sideways component clears the wall
-- and comes down where there is no floor at all. Measured in the 2026-09-19
-- audit: the whole ragdoll crossed ground level 290 studs off the lane, fell
-- to FallenPartsDestroyHeight (-500), was destroyed, and the player died and
-- respawned at their plot. The older "lost its HumanoidRootPart" report is the
-- same fall with the root, its own assembly while limp, reaching -500 first.
--
--==============================================================================
-- THE BODY IS WHAT FELL, NOT THE BOX. AND IT FALLS BACK IN LIMP.
--
-- The first version of this watched `root.Position.Y` and, below VOID_Y, ended
-- the throw and stood the player up at the gate. Reported 2026-09-21 as "the
-- ragdoll when hit by a guardian is gone", and it had taken it away twice:
--
--   the box     the root is invisible and, while limp, an assembly of its own
--               that shares the launch but not the bounces: the rig has no
--               NoCollisionConstraint between it and the LowerTorso, and the
--               disabled Root joint was the only thing holding it. Measured on
--               Emberroot: the body hit the wall and lay on the road, the box
--               sailed over the wall 161 studs away and dropped under VOID_Y,
--               and a player lying on the road was stood up at the gate.
--   the body    when it really had left (Tanglemire, Starbloom), standing it up
--               the instant it crossed VOID_Y replaced the landing with a
--               teleport. The limp fall was the last ragdoll a deep-biome hit
--               had, and that went too.
--
-- So the VISIBLE body decides -- the torso, the part ThrowFX lands and stands
-- up -- and each escape gets its own answer:
--
--   the box alone   goes back over the body, moving with it. The throw goes on;
--                   ThrowFX seats it at the stand-up as it always has, and it
--                   never reaches -500 to take the character with it.
--   the body        goes back ABOVE the road at the biome's gate, still limp,
--                   and lands there. ThrowFX is still waiting for a landing, so
--                   it settles and stands up on the road like any other throw.
--
-- Standing up at the gate is what is left only if the body keeps leaving:
-- after MAX_SET_DOWNS the throw ends the way the first version ended it.
--==============================================================================
local VOID_Y = -40
-- Height over the road the limp body is put back at: a short fall, so it lands
-- and settles as a ragdoll instead of appearing already lying down.
local SET_DOWN_DROP = 8
-- And a slide toward home, studs a second. Dropped dead still, a body settles
-- the instant it lands -- measured: on the road for 0.35 s and straight up,
-- where a throw that stays in the lane lay there 0.65 to 1.6 s while it
-- skidded. With this slide: 0.6 to 0.7 s.
local SET_DOWN_SLIDE = 40
-- How much longer the throw waits for the victim's answer after a set-down.
-- ThrowFX gives up five seconds into the flight, and a body leaves the world
-- about two seconds in (measured 2.1 to 2.5), so the landing fits inside both.
local SET_DOWN_GRACE = 3
local MAX_SET_DOWNS = 2
-- How far out of the parent to move the victim before their limbs start
-- colliding. Contact happens INSIDE a collidable torso, and switching a body
-- to collidable while it overlaps another one either wedges it there or has
-- the solver fling it. Cheaper to step out of the way first.
local CLEAR_STUDS = 5

-- What the player watches land: UpperTorso on R15, Torso on R6, and the root
-- only for a rig that has neither.
local function visibleBody(character: Model, root: BasePart): BasePart
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return if torso and torso:IsA("BasePart") then torso else root
end

-- The road just outside the gate of the nest's own biome, at floor height on
-- the road's axis. The nest's Z if the lane has no Gate part.
local function gateSpot(nest: Nest): Vector3
	-- An off-road nest names its own (the Rain event's: its biome's entrance).
	local own = nest.setDown
	if own then
		return own
	end
	local map = Workspace:FindFirstChild(GameConfig.Map.FolderName)
	local lanes = map and map:FindFirstChild(GameConfig.Map.LanesFolderName)
	local lane = lanes and lanes:FindFirstChild(nest.biome.Id)
	local gate = lane and lane:FindFirstChild("Gate")
	local z = if gate and gate:IsA("BasePart") then gate.Position.Z + 10 else nest.root.Position.Z
	return Vector3.new(0, 0, z)
end

-- The box alone, back over the body it belongs to and moving with it. Over,
-- not inside: it collides with the LowerTorso, and a box put back inside one is
-- a box the solver throws out again.
local function bringRootBack(root: BasePart, body: BasePart)
	root.CFrame = CFrame.new(body.Position + Vector3.new(0, 3, 0))
	root.AssemblyLinearVelocity = body.AssemblyLinearVelocity
	root.AssemblyAngularVelocity = Vector3.zero
end

-- The whole limp body, by one transform so every socket stays where it was, to
-- SET_DOWN_DROP over `at`, turned the way it was falling. Its fall is traded for
-- SET_DOWN_SLIDE toward home (+Z, as the road runs), so it lands skidding; the
-- box goes back over it.
local function setDownLimp(character: Model, body: BasePart, root: BasePart, at: Vector3)
	local target = CFrame.new(at + Vector3.new(0, SET_DOWN_DROP, 0)) * body.CFrame.Rotation
	character:PivotTo(target * body.CFrame:Inverse() * character:GetPivot())
	local slide = Vector3.new(0, 0, SET_DOWN_SLIDE)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = slide
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	bringRootBack(root, body)
end

-- Victims currently mid-throw, and the flag their client sets by answering.
local throwDone: { [Player]: boolean } = {}

--==============================================================================
-- WHICH THROW AN ANSWER BELONGS TO
--
-- The answer used to carry nothing, so ANY "I have stopped" on this remote
-- ended the throw -- including a bat's, which comes down the same remote with
-- CombatService's own token. Each guardian throw now mints one, sends it with
-- the launch, and ends only on an answer that quotes it back; ThrowFX already
-- quotes whatever token a launch carried. The value is also the claim: set
-- before anything else happens, it is what keeps a second guardian off a body
-- this one is already throwing.
--==============================================================================
local throwToken: { [Player]: string } = {}
local throwSeq = 0

-- Whether an answer ends the throw it arrived for: one is waiting (`pending` is
-- false, not nil and not already true) and the answer quotes ITS token. A
-- stale token, a duplicate after the first, a bat's and a bare one all fail.
local function throwAnswerMatches(pending: boolean?, expected: string?, token: any): boolean
	return pending == false and type(token) == "string" and expected ~= nil and token == expected
end
NestService.ThrowAnswerMatches = throwAnswerMatches

--==============================================================================
-- "I HAVE LANDED" IS A SECOND WORD, AND IT NEVER ENDS A THROW
--
-- The victim's machine is the only one that knows its body is down (see THE
-- NECK TAKES ITS FRICTION BACK), so it reports that on the same remote, quoting
-- the same token, with RagdollGate.Landed after it. The report that the body
-- has STOPPED carries no second word and never has.
--
-- Anything with a second word is a report ABOUT the throw: it may give the neck
-- its friction back, once, and it returns before the rule that ends a throw is
-- even asked. So the worst a victim can do by lying is stiffen its own neck
-- early. `throwLimp` is this throw's own record, held from the launch until its
-- landing is reported or the throw ends, so a report can only ever reach the
-- body THIS throw loosened.
--==============================================================================
local throwLimp: { [Player]: Loosened } = {}

local function throwLandingMatches(pending: boolean?, expected: string?, token: any, what: any): boolean
	return what == RagdollGate.Landed and throwAnswerMatches(pending, expected, token)
end
NestService.ThrowLandingMatches = throwLandingMatches

--==============================================================================
-- WHO MAY REPORT, WHEN, AND HOW OFTEN
--
-- Every argument but the sender came off the wire (AGENTS.md, rule 4). The
-- sender is engine-stamped, and every lookup below is keyed on it, so:
--
--   from whom     only the player who was thrown. Anybody else quoting that
--                 token is looked up under their OWN name and finds no throw.
--   when          only while that player's own guardian throw is waiting for
--                 its answer, and only quoting the token that throw minted.
--   how often     once. The first landing report takes the throw's record out
--                 of `throwLimp`; a second finds nothing to write to.
--   otherwise     ignored, without a word and without touching anything.
--
-- It returns what it did -- RagdollGate.Landed, "stopped" or nil -- which the
-- remote discards and GuardianRagdollSpec reads.
--==============================================================================
local function acceptThrowAnswer(player: Player, token: any, what: any): string?
	if what ~= nil then
		if throwLandingMatches(throwDone[player], throwToken[player], token, what) then
			local limp = throwLimp[player]
			throwLimp[player] = nil
			if limp and stiffenNeck(limp) then
				return RagdollGate.Landed
			end
		end
		return nil
	end
	if throwAnswerMatches(throwDone[player], throwToken[player], token) then
		throwDone[player] = true
		return "stopped"
	end
	return nil
end

--==============================================================================
-- THE HANDLER, REACHABLE BY A SPEC
--
-- Only the engine can raise OnServerEvent, so a spec cannot send a report: the
-- problem CombatService has with Tool.Activated, and the same answer.
-- `AcceptThrowAnswer` IS the function the remote is connected to. `SpecThrow`
-- stands in for the lines of throwPlayer that open a throw's books -- the
-- token, the waiting flag, the limp record -- and closes them when it is given
-- no token. Server-only: no client can require this module and no remote
-- reaches either name.
--
-- AND `SpecThrow` IS STUDIO-ONLY. It writes a throw's books directly, so on a
-- live server it returns before writing anything: nothing there can open,
-- close or overwrite a real throw through it, whatever calls it.
--==============================================================================
NestService.AcceptThrowAnswer = acceptThrowAnswer

function NestService.SpecThrow(player: any, token: string?, limp: Loosened?)
	if not RunService:IsStudio() then
		return
	end
	throwToken[player] = token
	throwDone[player] = if token then false else nil
	throwLimp[player] = if token then limp else nil
end

-- Studio specs (2026-10-09, the guardian hand-off): the throw a player is in
-- the air for right now -- its token -- or nil once it has landed.
function NestService.SpecThrowState(player: any): string?
	if not RunService:IsStudio() then
		return nil
	end
	return throwToken[player]
end

--==============================================================================
-- THE GRAB
--
-- Spawned rather than run in the tick, because it holds for the better part of
-- a second and the other eleven nests must not stop while it does.
--==============================================================================
-- Resolved lazily: ServerMain builds the Remotes folder from GameConfig at
-- boot, and this module is required before that has necessarily happened.
local throwRemote: RemoteEvent? = nil
local throwRemoteConnected = false

local function resolveThrowRemote(): RemoteEvent?
	if throwRemote and throwRemote.Parent then
		return throwRemote
	end
	local seedGame = ReplicatedStorage:FindFirstChild("SeedGame")
	local remotes = seedGame and seedGame:FindFirstChild("Remotes")
	local found = remotes and remotes:FindFirstChild(GameConfig.Remotes.ThrowVictim)
	if found and found:IsA("RemoteEvent") then
		throwRemote = found
		if not throwRemoteConnected then
			throwRemoteConnected = true
			table.insert(serviceConnections, found.OnServerEvent:Connect(acceptThrowAnswer))
		end
		return found
	end
	return nil
end

-- `onLaunched` (2026-10-09, the owner's guardian fix) runs, on its own thread,
-- the moment the victim is launched -- before the flight it then waits out --
-- so the guardian may turn on the next thief while this one is in the air. Not
-- called when the throw never lands (a limp victim, a wind-up that misses).
local function throwPlayer(nest: Nest, player: Player, onLaunched: (() -> ())?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and root and root:IsA("BasePart")) then
		return
	end

	--==========================================================================
	-- ONE THROW AT A TIME, AND NEVER A LIMP BODY
	--
	-- A victim already limp -- mid another guardian's throw, or a bat's or a
	-- trap's knockback -- is not thrown again. The second ragdollOn would take
	-- an empty record (every constraint is already off) and the first
	-- system's restore would switch the joints back on in the middle of this
	-- launch: a rigid body in the air. Nothing has happened yet, so the hit
	-- simply does not land and the guardian goes home.
	--==========================================================================
	if isRagdolled(character) or throwToken[player] ~= nil then
		return
	end
	throwSeq += 1
	local token = string.format("g%d@%.2f", throwSeq, os.clock())
	throwToken[player] = token
	local function unclaim()
		if throwToken[player] == token then
			throwToken[player] = nil
		end
	end

	--==========================================================================
	-- RAGDOLL FIRST, CAPTURE SECOND. THE ORDER IS THE WHOLE FIX.
	--
	-- Setting PlatformStand is what makes CarryService drop the pod, and its
	-- drop calls RefreshWalkSpeed -- so the correct UNENCUMBERED speed only
	-- exists after this line. Capturing before it captured the CARRY speed, and
	-- restoring that after the flight left the player trudging at 95% with empty
	-- hands until something else happened to refresh them.
	--
	-- The task.wait() is not decoration: property-changed signals are deferred,
	-- so without it the capture would run before the drop handler and read the
	-- old value anyway.
	--==========================================================================
	--==========================================================================
	-- CONTACT, AND THEN THE LAUNCH A FIFTH OF A SECOND LATER
	--
	-- Two beats of one event, and they only read as one event if the first one
	-- is HERE -- at the line that actually makes contact -- rather than next to
	-- the throw. PlatformStand going true is the hit; everything below it is the
	-- consequence.
	--
	-- On the parent's root, so it comes from the monster. A hit sound on the
	-- victim would put the loudest cue in the game inside the ear of the one
	-- player who does not need to be told.
	--==========================================================================
	--==========================================================================
	-- A WIND-UP, IF ANY GUARDIAN EVER WANTS ONE. NONE DOES.
	--
	-- Astralmaw was given 0.32 seconds of anticipation here and it was WRONG,
	-- which only playing it showed: contact happened, nothing happened, and a
	-- third of a second later the victim went. It read as lag, not as a strike
	-- being loaded -- the chase is the anticipation, and stopping at the end of
	-- one to pose is a pause however good the pose is. It also handed the player
	-- a dodge: 150 walk speed covers 48 studs during the coil, past the range
	-- re-check below, so charging the monster beat it.
	--
	-- So every profile is at zero and this block does not run. It is left
	-- standing because the re-checks in it are the correct ones for any wind-up
	-- somebody adds later -- the victim can die, disconnect, reach the safe zone
	-- or get out of reach inside it, and all four have to cost the parent its
	-- hit rather than throwing a body that is no longer there.
	--==========================================================================
	local prof = profileOf(nest)
	local windup = if prof then (tonumber(prof.WindupSeconds) or 0) else 0
	if windup > 0 then
		nest.parent:SetAttribute("AttackWindup", windup)
		nest.parent:SetAttribute("AttackSwipe", workspace:GetServerTimeNow())
		task.wait(windup)
		-- Everything that could have changed while it was coiling.
		if player.Parent ~= Players or humanoid.Health <= 0 or not root.Parent
			or character.Parent == nil then
			unclaim()
			return
		end
		if MapService.IsInSafeZone(root.Position) then
			unclaim()
			return
		end
		if (root.Position - nest.root.Position).Magnitude > P.GrabStuds * 4 then
			-- They got out of reach during the wind-up. The swing misses.
			unclaim()
			return
		end
	end

	--==========================================================================
	-- THE SWING THAT LANDS, IN THIS BIOME'S VOICE
	--
	-- `Grab` is still the fallback and still the right sound for a hand closing
	-- on somebody, but Greenhollow and Tanglemire have a recording of their own
	-- now and every other biome gets the claw swipe. One line, because the
	-- choosing is data -- see GameConfig.Sfx.ParentVoices.
	--==========================================================================
	SoundKit.emit(SoundKit.parentCue(nest.biome.Id, "Hit") or "Grab", nest.root)
	-- Launch analytics: the swing landed, so the carrier's raid (if one is open)
	-- ends as captured here -- before the throw's ragdoll drops the pod.
	Metrics.guardianCaught(player)

	humanoid.PlatformStand = true
	task.wait()

	--==========================================================================
	-- THE CAPTURED SPEED IS ONLY A FALLBACK NOW
	--
	-- This used to be the restore value, and it is what froze players caught in
	-- a trap. WalkSpeed is 0 while a Bramblejaw holds somebody, so a guardian
	-- landing on a trapped player captured ZERO here and wrote it back four
	-- seconds later -- after the trap's own release had already put the correct
	-- speed back. Reported exactly that way: trapped, hit, immobile forever.
	--
	--     t 0.0  trapped                     WalkSpeed 0
	--     t 0.5  guardian hits, captures     walk = 0
	--     t 2.0  trap expires, recomputes    WalkSpeed 139
	--     t 5.5  throw ends, restore()       WalkSpeed = walk = 0   <- stuck
	--
	-- It is the same capture-and-replay trap HANDOFF recorded once before, when
	-- a thrown player kept their CARRY speed; that was fixed by moving the
	-- capture rather than by removing it, so the shape survived.
	--
	-- The fix is not to capture a better moment. It is to stop replaying a
	-- number at all: CarryService owns WalkSpeed because it is the product of a
	-- saved Speed score, a carry multiplier, a mill and now a trap, and no
	-- caller knows all four. `restore()` asks it to recompute. The capture stays
	-- only for the case where the bridge is absent, which is a server booting
	-- without CarryService and therefore without any of this mattering.
	--==========================================================================
	local walk = humanoid.WalkSpeed
	local jump = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- ONE restore, reached by every exit: success, early return, and error.
	-- Grabbing sets WalkSpeed to 0, so anything that can throw between here and
	-- the end can strand a player at zero permanently -- and a lock that only
	-- one path releases is not a lock, it is a trap.
	--
	-- The RAGDOLL goes through here too, for exactly the same reason. It was
	-- first written unwinding itself at the end of the happy path, which meant
	-- an error mid-flight left a player loose-jointed with collision forced on,
	-- forever. Joints and collides are as much a lock as WalkSpeed is.
	local loosened: Loosened? = nil
	local function restore()
		if loosened then
			ragdollOff(loosened)
			loosened = nil
		end
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid.JumpPower = jump
			--==================================================================
			-- RECOMPUTED, NOT REPLAYED. See the banner over the capture.
			--==================================================================
			local bridge = carryBridge
			local refresh = if bridge then bridge.RefreshWalkSpeed else nil
			if refresh then
				local okRefresh = pcall(refresh, player)
				if not okRefresh then
					humanoid.WalkSpeed = walk
				end
			else
				humanoid.WalkSpeed = walk
			end
		end
	end

	-- Set inside the wait below when the body is still leaving the world after
	-- MAX_SET_DOWNS; read after restore().
	local fellOut = false
	local ok, err = pcall(function()

	--==========================================================================
	-- NO HOLD. CONTACT IS THE HIT.
	--
	-- There used to be a GrabHoldSeconds pause here: the parent caught you,
	-- held you for the better part of a second, and then threw. It read as a
	-- cutscene -- the chase stopped dead, both bodies stood still, and the one
	-- moment the chase had been building to was a wait.
	--
	-- Now reaching you IS the hit. The parent does not catch and consider; it
	-- runs into you and you go.
	--==========================================================================
	if player.Parent ~= Players or humanoid.Health <= 0 then
		return
	end

	--==========================================================================
	-- THE CONFIGURED STUDS ARE IMPULSE STRENGTH NOW, NOT A LANDING COORDINATE.
	--
	-- The formula is unchanged and the numbers are unchanged -- range of a
	-- projectile launched at v with vertical component k*v is 2*k*v^2/g, so
	-- sqrt(R*g / 2k) is the speed for a clean R-stud arc. What changed is the
	-- PROMISE. A body that bounces off a wall does not land where a parabola
	-- says it will, and pretending otherwise would make the comment a lie.
	--
	-- So: bigger biome number, harder shove. Where they end up is the world's
	-- business.
	--
	-- A PROFILED GUARDIAN STATES ITS OWN TWO NUMBERS INSTEAD, because the arc it
	-- needs is not a function of its biome index -- it is a function of a wall.
	-- See GameConfig.Parent.Guardians.astralmaw.
	--==========================================================================
	local g = Workspace.Gravity
	local speed, k
	if prof then
		speed = tonumber(prof.ThrowSpeed) or 0
		k = tonumber(prof.ThrowLift) or P.ThrowLift
	else
		local R = GameConfig.parentThrowStudsFor(nest.biome.Order)
		k = P.ThrowLift
		speed = math.sqrt(R * g / (2 * k))
	end

	--==========================================================================
	-- WHICH WAY, AND WHY IT IS NOT (0, 0, 1)
	--
	-- AWAY FROM THE MONSTER, always: the flat vector from its root to the
	-- victim's, which is also the direction the arm just swung, so the launch
	-- and the strike agree. Overlapping exactly -- a hit landed from inside the
	-- torso -- falls back to the monster's own facing rather than dividing by a
	-- zero-length vector.
	--
	-- The second term is the road. The four unprofiled parents keep the literal
	-- +Z they shipped with, byte for byte, because that IS their tested
	-- behaviour. A profiled one derives it from its OWN nest instead: the flat
	-- direction to the hub pad in the safe field, which points up the corridor
	-- from wherever the nest happens to be, and would still point the right way
	-- if the road were rebuilt facing anywhere else.
	--
	-- Away outweighs it better than three to one on Astralmaw, which is what
	-- makes a hit taken beside a wall go OVER the wall rather than obediently
	-- down the middle of the road. Even with the road term pointing straight
	-- back, the sum keeps 70% of `away`, so no mixture of the two can throw a
	-- victim through the torso that hit them -- asserted below rather than
	-- assumed.
	--==========================================================================
	local diff = root.Position - nest.root.Position
	local flatDiff = Vector3.new(diff.X, 0, diff.Z)
	local facing = nest.root.CFrame.LookVector
	local flatFacing = Vector3.new(facing.X, 0, facing.Z)
	local awayDir
	if flatDiff.Magnitude > 0.1 then
		awayDir = flatDiff.Unit
	elseif flatFacing.Magnitude > 0.1 then
		awayDir = flatFacing.Unit
	else
		awayDir = Vector3.new(0, 0, 1)
	end

	--==========================================================================
	-- WHICH WAY IS HOME, AND HOW MUCH IT MATTERS
	--
	-- Two profiles can answer, and they are asked in order: the SPECIES speed
	-- profile first (Astralmaw), then the BIOME confiscate profile (the three
	-- that take pods back). A guardian in neither -- Greenhollow's and
	-- Brambleback's -- falls through to the legacy pair and to the hardcoded
	-- +Z, exactly as it always has.
	--
	-- The hardcoded axis is only correct because this map's road runs along Z;
	-- anything with a profile derives the direction from its OWN nest toward
	-- the hub instead, which is what makes it right for a nest placed anywhere.
	--==========================================================================
	local dprof: any = prof or GameConfig.confiscateProfile(nest.biome.Id)
	local roadOut = Vector3.new(0, 0, 1)
	if dprof then
		-- The hub's centre (Map.EventHub). It was the overflow spawn's marker,
		-- which stood there until it moved off the event plaza (2026-10-10).
		local hub = GameConfig.Map.EventHub.Centre - nest.origin
		local flatHub = Vector3.new(hub.X, 0, hub.Z)
		if flatHub.Magnitude > 1 then
			roadOut = flatHub.Unit
		end
	end
	local aw = if dprof then (tonumber(dprof.AwayWeight) or 1) else 0.7
	local rw = if dprof then (tonumber(dprof.RoadWeight) or 0) else 0.5
	local dir = awayDir * aw + roadOut * rw
	if dir.Magnitude < 0.1 then
		dir = awayDir
	else
		dir = dir.Unit
	end
	if dir:Dot(awayDir) <= 0 then
		--======================================================================
		-- THE GUARDIAN IS STANDING BETWEEN YOU AND HOME
		--
		-- Reachable, and it was throwing people the wrong way. The old fallback
		-- dropped to `awayDir` alone, and away-from-the-guardian in exactly this
		-- geometry is DEEPER INTO THE BIOME -- the direction the whole road
		-- weighting exists to avoid. Reported as *"theres a rare chance when i
		-- ragdoll on opposite direction"*, and rare is right: it needs the
		-- guardian roughly on the line between the victim and the hub, which the
		-- 60-stud chase overshoot produces every so often.
		--
		-- So the road is kept and only the SIDEWAYS part of away is used, which
		-- launches them home PAST the guardian rather than back over its
		-- shoulder. If they are dead on the line there is no sideways part and
		-- the road wins outright: being smashed past a guardian at 300 studs a
		-- second reads as the hit landing, and being fired back into the biome
		-- reads as a bug, because it was one.
		--======================================================================
		local lateral = awayDir - roadOut * awayDir:Dot(roadOut)
		if lateral.Magnitude > 0.05 then
			dir = (roadOut + lateral.Unit * 0.6).Unit
		else
			dir = roadOut
		end
	end

	local limp = ragdollOn(character)
	-- In the same frame as the constraints, so the client sees both arrive
	-- together; see LOOSE MEANS LOOSE.
	slackenJoints(limp, character)
	loosened = limp
	-- For the victim's landing report, which gives the neck its friction back.
	throwLimp[player] = limp
	-- nest.parent, not nest.model: the Nest type has no 'model' field, so this
	-- indexed nil and threw -- AFTER the ragdoll and BEFORE the FireClient that
	-- does the actual throwing. The victim went limp and was never flung.
	--
	-- A profiled guardian already stamped it at the START of its wind-up, and
	-- stamping again here would restart the animation at the impact frame --
	-- which is the bug the wind-up exists to fix.
	if windup <= 0 then
		nest.parent:SetAttribute("AttackWindup", 0)
		nest.parent:SetAttribute("AttackSwipe", workspace:GetServerTimeNow())
	end

	SoundKit.emit("Throw", nest.root)

	throwDone[player] = false
	local sent = false
	local rem = resolveThrowRemote()
	if rem then
		sent = pcall(function()
			-- The fifth argument is how long the client should HOLD the launch
			-- velocity. Omitted for the four unprofiled parents, which leaves
			-- them on the value ThrowFX has always used; zero for a profiled
			-- one, which asks for a single impulse and a real ballistic arc.
			--
			-- The sixth carries this throw's token (WHICH THROW AN ANSWER
			-- BELONGS TO) and nothing else a guardian did not already have:
			-- ThrowFX keys every bat difference off `emergency`, which a
			-- guardian never sends, so the flight is untouched.
			rem:FireClient(player, dir, speed, k, CLEAR_STUDS,
				if prof then 0 else nil, { token = token, kind = "guardian" })
		end)
	end
	if not sent then
		warn("[Seed/NestService] no ThrowVictim remote; the hit will look like a shove that never landed.")
	end

	-- Immediate physics impulse directly into solver momentum
	pcall(function()
		-- `k`, not P.ThrowLift: the server's own hint has to be the same arc it
		-- just described to the client, or the two disagree for the frame
		-- before the owner takes over.
		local impulse = dir * speed + Vector3.new(0, speed * k, 0)
		--==================================================================
		-- ONE OF THESE, NOT BOTH, WHEN THE CLIENT IS GOING TO LAUNCH IT
		--
		-- ApplyImpulse ADDS to the velocity and the line under it SETS it, so
		-- on a body the owning client is about to set as well the two stack.
		-- Measured: 467.6 out of a configured 235. The unprofiled parents keep
		-- both calls, because both is what they were tuned against.
		--==================================================================
		if not prof then
			root:ApplyImpulse(impulse * root.AssemblyMass)
		end
		root.AssemblyLinearVelocity = impulse
	end)
	-- LAUNCHED. The guardian's part of the catch is over; the flight below is
	-- the victim's (2026-10-09: a guardian turns on its next thief now).
	if onLaunched then
		task.spawn(onLaunched)
	end

	--==========================================================================
	-- WAIT FOR THE VICTIM TO SAY IT STOPPED
	--
	-- Not a server-side settle poll: the server's copy of a client-owned body is
	-- a replica, and polling a replica's velocity to decide when the real thing
	-- stopped is measuring the wrong body -- the mistake that produced a page of
	-- convincing numbers about a ragdoll nobody could see.
	--
	-- The timeout is the only thing that MUST be honoured; the client's answer
	-- is an optimisation on top of it.
	--==========================================================================
	local deadline = os.clock() + THROW_TIMEOUT
	local setDowns = 0
	while os.clock() < deadline do
		if throwDone[player] then
			break
		end
		if player.Parent ~= Players or not root.Parent or humanoid.Health <= 0 then
			break
		end
		-- See VOID_Y: the torso decides whether the BODY left; the box on its own
		-- is only brought back.
		local body = visibleBody(character, root)
		if body.Position.Y < VOID_Y then
			if setDowns >= MAX_SET_DOWNS then
				fellOut = true
				break
			end
			setDowns += 1
			setDownLimp(character, body, root, gateSpot(nest))
			deadline = math.max(deadline, os.clock() + SET_DOWN_GRACE)
			log(string.format("%s was thrown out of the world by %s; put back on the road at the %s gate, still limp.",
				player.Name, nest.id, nest.biome.Id))
		elseif root.Position.Y < VOID_Y then
			bringRootBack(root, body)
		end
		task.wait(0.1)
	end
	throwDone[player] = nil

	end)

	-- Before restore(): ragdollOff is about to empty this record, and a landing
	-- report that arrives late must find nothing to write to.
	throwLimp[player] = nil
	restore()
	-- An error inside the pcall skips its own last line, so the answer flag is
	-- cleared here as well; the claim goes with it.
	throwDone[player] = nil
	unclaim()
	if not ok then
		warn("[Seed/NestService] throw failed after the grab: " .. tostring(err))
	end

	--==========================================================================
	-- STOOD UP AT THE GATE, NOT DESTROYED AT -500 -- THE LAST RESORT
	--
	-- See VOID_Y. Only a body that left the world again after MAX_SET_DOWNS
	-- limp set-downs gets here. Joints and collisions are back (restore ran
	-- above), so the body is whole again; it is placed on the road just outside
	-- the biome it was thrown from, facing home, and stopped.
	--==========================================================================
	if fellOut then
		local body = player.Character
		local hum = body and body:FindFirstChildOfClass("Humanoid")
		local r = body and body:FindFirstChild("HumanoidRootPart")
		if body and hum and hum.Health > 0 and r and r:IsA("BasePart") then
			local at = gateSpot(nest) + Vector3.new(0, 6, 0)
			body:PivotTo(CFrame.lookAt(at, at + Vector3.zAxis))
			for _, part in ipairs(body:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			warn(string.format(
				"[Seed/NestService] %s, thrown by %s, left the world again after %d set-downs; stood up at the %s gate.",
				player.Name, nest.id, MAX_SET_DOWNS, nest.biome.Id))
		end
	end

	--==========================================================================
	-- A BODY WITH NO ROOT IS NOT A BODY, AND THIS IS WHERE IT LOSES ONE
	--
	-- The wait loop above already breaks on `not root.Parent`, so the case was
	-- known about; nothing acted on it. A ragdoll is seventeen separate
	-- assemblies and the root travels on its own -- measured 780 studs from its
	-- own torso on a Starbloom throw -- so it can cross
	-- `FallenPartsDestroyHeight` while the body it belongs to lands on the road.
	-- The Humanoid stays alive at full health with a Head and no root.
	--
	-- That body is finished: it cannot be carried on, cannot be thrown again,
	-- and made every later pod take destroy a pod for nothing. Nothing in Roblox
	-- repairs it, so the only way out is a new one.
	--
	-- LoadCharacter rather than Health = 0: they have just been thrown across
	-- the biome and lost the pod, and a death on top of that would be a second
	-- punishment for the engine's bookkeeping rather than for anything they did.
	--==========================================================================
	local body = player.Character
	local hum = body and body:FindFirstChildOfClass("Humanoid")
	if body and hum and hum.Health > 0 and not body:FindFirstChild("HumanoidRootPart") then
		warn(string.format(
			"[Seed/NestService] %s lost its HumanoidRootPart to the throw; respawning.",
			player.Name))
		-- The new body comes with a new, empty Backpack, and the held plants in the
		-- old one go with it. CarryService takes a last snapshot and stops
		-- recording until its rebuild has put them back, so the swap cannot be
		-- saved as the player owning nothing.
		local bridge = carryBridge
		if bridge and bridge.FreezeHeld then
			pcall(bridge.FreezeHeld, player)
		end
		pcall(function()
			player:LoadCharacter()
		end)
	end
end

--==============================================================================
-- ONE TICK OF ONE NEST
--==============================================================================
--==============================================================================
-- THE GRAB IS SWEPT, BECAUSE 150 STUDS A SECOND IS 18 STUDS A TICK
--
-- The catch is a distance test -- correct, and not a Touched -- but it was
-- sampled at the nest tick, and the two numbers do not fit each other:
--
--     GrabStuds  7        the radius a parent catches you inside
--     TICK       0.12s    how often that radius is tested
--     150 x 0.12 = 18     how far a capped player moves between two tests
--
-- So a fast player crossed the entire capture zone BETWEEN SAMPLES and was
-- never once measured inside it. Not a rare race: at max speed it is the
-- ordinary outcome, and it is worst exactly for the fast players the Speed
-- ladder exists to create.
--
-- The fix is not a faster tick -- that is the same bug with a smaller window and
-- eight times the cost. It is to stop testing a POINT and sweep the tick.
--
-- AND BOTH BODIES MOVE (2026-10-01). The first sweep put the parent's position
-- NOW against the player's whole path: two moments compared as one. It missed a
-- parent and a player crossing mid-tick, and it hit a player who had left a spot
-- before the parent got there. The sweep is of their RELATIVE motion now, from a
-- sample of both taken at the same tick (GuardianPursuit.closestApproach).
--==============================================================================
-- 150 WalkSpeed x 0.12s is 18 studs; double it so an ordinary hitch is still
-- treated as travel and only a discontinuity is thrown away.
local MAX_TICK_TRAVEL = 40
-- A sample older than this is a chase that stalled or stopped, not a tick.
local SAMPLE_MAX_AGE = 0.5

--==============================================================================
-- IT CARRIES IT WHERE IT MAKES SENSE TO CARRY IT
--
-- Welded to a real limb, so the client's animation carries the pod for free:
-- every cosmetic piece on these rigs is already a WeldConstraint onto the part
-- it belongs to, and ParentAnim moving a seam moves everything welded past it.
-- There is no second render loop here and nothing on the client is told a pod
-- is attached -- it is just more geometry hanging off a jaw or a fist.
--
-- WHERE IT SITS IS DERIVED, NOT CONFIGURED, and that is the whole reason this
-- function is longer than a weld. A pod is 1.66 studs across at Tiny and 9.04
-- at the top of the curve -- a factor of five -- on guardians that are 15 to 19
-- studs tall. Hand-tuned offsets were tried first and measured on the live
-- rigs: the same three numbers that looked right at Tiny buried Astralmaw's pod
-- 2.62 studs inside its own ChestNebula and hung Forgemaw's 8.55 studs below
-- the ground it was walking on.
--
-- So two things are solved from the rig instead, and both are one pass over the
-- parts, once, at the moment of the catch:
--
--   ABOVE THE GROUND. The lowest point of the body is where it stands, so the
--   pod's centre is never allowed below that plus its own radius. A clamp
--   rather than an offset: a small pod still hangs at the height of the limb
--   carrying it, and only a big one gets lifted.
--
--   OUT OF THE BODY. Starting AT the limb and pushed forward only as far as it
--   takes to stop overlapping anything. Clearing the front-most point of the
--   whole body was tried first and it is too blunt: Forgemaw's head reaches
--   8.47 studs forward of its root, so a 9-stud pod cleared to the front of
--   THAT ended up 13.4 out -- five studs past the nose and ten studs from the
--   fist it was welded to, which reads as a floating boulder rather than as
--   something being carried.
--
-- The push is iterative because moving out of one part can move into another,
-- and it converges in a handful of passes because each pass moves at least the
-- depth of the worst overlap. Eight is a ceiling, not an expectation.
--
-- The seam still decides WHICH limb it is welded to, and therefore how it
-- moves. Side is cosmetic and stays in the profile.
--
-- It is decoration and is built as decoration: untagged, so nothing can take
-- it; CanQuery and CanTouch false, so nothing can click or trip over it;
-- massless and non-colliding, so a 10,000 kg shell does not change how the
-- guardian walks. It never fails loudly -- a haul with no visible pod still
-- walks home and still deposits.
--==============================================================================
local function attachHaul(nest: Nest, haul: Haul): boolean
	local prof = GameConfig.confiscateProfile(nest.biome.Id)
	local species = SeedData.Get(haul.speciesId)
	if not (prof and species and nest.root.Parent) then
		return false
	end
	local seam = nest.parent:FindFirstChild(tostring(prof.Seam), true)
	if not (seam and seam:IsA("BasePart")) then
		warn(string.format("[Seed/NestService] %s has no %s to carry a pod on.",
			nest.id, tostring(prof.Seam)))
		return false
	end

	local radius = SeedData.PodDiameter(haul.tier) * 0.5
	local clear = tonumber(P.HaulClearance) or 0.4
	local rootCF = nest.root.CFrame
	local seamLocal = rootCF:ToObjectSpace(seam.CFrame).Position

	--== WHERE THE BODY IS, IN THE GUARDIAN'S OWN FRAME ==--
	-- Gathered once. The rotated half-extent along Y is the same corner reach
	-- the Starbloom limb work needed to put feet on the ground: a raked piece
	-- projects more than half its thickness.
	local boxes: { { cf: CFrame, half: Vector3 } } = {}
	local footY = 0
	for _, d in ipairs(nest.parent:GetDescendants()) do
		if d:IsA("BasePart") then
			local lp = rootCF:ToObjectSpace(d.CFrame)
			local half = d.Size * 0.5
			table.insert(boxes, { cf = lp, half = half })
			footY = math.min(footY, lp.Position.Y
				- (math.abs(lp.RightVector.Y) * half.X
					+ math.abs(lp.UpVector.Y) * half.Y
					+ math.abs(lp.LookVector.Y) * half.Z))
		end
	end

	local podX = seamLocal.X + (tonumber(prof.Side) or 0) * radius
	-- The limb's own height, unless that would drag it along the road.
	local podY = math.max(seamLocal.Y, footY + radius + clear)
	local podZ = seamLocal.Z

	for _ = 1, 8 do
		local at = Vector3.new(podX, podY, podZ)
		local worst = 0
		for _, b in ipairs(boxes) do
			-- Distance from the pod's centre to this box, zero inside it.
			local d = b.cf:PointToObjectSpace(at)
			local out = Vector3.new(
				math.max(math.abs(d.X) - b.half.X, 0),
				math.max(math.abs(d.Y) - b.half.Y, 0),
				math.max(math.abs(d.Z) - b.half.Z, 0))
			worst = math.max(worst, radius + clear - out.Magnitude)
		end
		if worst <= 0.01 then
			break
		end
		podZ -= worst
	end

	local centre = rootCF * CFrame.new(podX, podY, podZ)

	--==========================================================================
	-- PARENTED BESIDE THE GUARDIAN, NOT INSIDE IT
	--
	-- The weld is what carries it, and a WeldConstraint does not care which
	-- model each end lives in -- so the pod goes in the nest folder and the
	-- guardian's own descendant tree is left exactly as the builder made it.
	--
	-- That is not tidiness. ParentAnim's mireChannels NAME-SCANS every
	-- descendant BasePart of a Miremaw into one table and keeps the last of
	-- each name, then drives whatever it finds under the names in
	-- MiremawSleepSize and MiremawSleepTransparency. A pod hanging inside the
	-- model would be re-scanned on the next stream-in re-track, and a pod part
	-- that happened to share a name with a channel would either be resized by
	-- the sleep pose or, worse, REPLACE the real part in the channel and stop
	-- it animating. Keeping the pod outside the model makes that unreachable
	-- rather than unlikely.
	--==========================================================================
	-- BuildPod takes the BASE, not the centre. Same contract as everywhere else.
	local pod = CreatureModel.BuildPod(species, haul.tier,
		centre * CFrame.new(0, -radius, 0), nest.folder)
	pod.Name = "HauledPod"
	local primary = pod.PrimaryPart
	if not primary then
		pod:Destroy()
		return false
	end
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = primary
			end
		end
	end
	local hold = Instance.new("WeldConstraint")
	hold.Name = "HaulWeld"
	hold.Part0 = seam
	hold.Part1 = primary
	hold.Parent = primary

	haul.model = pod
	-- WHICH limb, not merely that there is one. The client steadies the seam it
	-- names, so the profile that chose the weld point also chooses the pose and
	-- ParentAnim needs no species table of its own.
	nest.parent:SetAttribute("Hauling", tostring(prof.Steady or "right"))
	return true
end

local function detachHaul(nest: Nest)
	local haul = nest.haul
	if haul and haul.model then
		if haul.model.Parent then
			haul.model:Destroy()
		end
		haul.model = nil
	end
	if nest.parent.Parent then
		nest.parent:SetAttribute("Hauling", nil)
	end
end

--==============================================================================
-- PUTTING IT BACK, AND THE THREE PLACES IT CAN GO
--
-- The only way a haul is ever cleared, and it is called from every exit: the
-- guardian arriving, the walk timing out, the guardian or its nest going away,
-- a reset, and settling down. That is deliberate -- while `haul` is set the
-- guardian holds the ONLY copy of that pod, so an exit that forgot to come
-- through here would delete it.
--
-- In order of preference:
--
--   1. AN EMPTY SLOT IN THE RING IT CAME OFF. The pod is back where it was
--      taken from, so the raid is genuinely undone: walk in again and it is
--      there. `fromNest` rather than this nest, because a thief can be caught
--      by a guardian whose ring the pod did not come from.
--   2. LOOSE ON THE GROUND at that nest's centre, through the same call a drop
--      makes -- tagged, prompted, on the same lifetime. This is the full-ring
--      case, and it is reachable: dawn restocks every slot, so a pod taken
--      yesterday has nowhere of its own to go back to.
--   3. A WARNING. Reachable only if the species has stopped existing AND the
--      ring is full AND CarryService never started. Loud rather than silent,
--      because a pod that quietly stops existing is the one failure in here
--      that nobody would ever notice.
--==============================================================================
local function depositHaul(nest: Nest, why: string): boolean
	local haul = nest.haul
	if not haul then
		return true
	end

	local home = nest
	if haul.fromNest then
		for _, n in ipairs(nests) do
			if n.id == haul.fromNest then
				home = n
				break
			end
		end
	end

	local placed = false
	local species = SeedData.Get(haul.speciesId)
	--==========================================================================
	-- A CONFISCATED SECRET GOES BACK TO ITS SPOT, the platform still under it,
	-- the same encounter id on it. Only if the encounter is still open; a
	-- secret whose encounter ended meanwhile takes the ring like any pod.
	--==========================================================================
	local secret = home.secret
	if species and haul.secretId and secret and secret.id == haul.secretId and not secret.pod then
		placed = standSecretPod(home, secret) ~= nil
	elseif species then
		for index = 1, home.biome.PodsPerNest do
			if not home.pods[index] then
				placePod(home, index, species, haul.tier)
				if home.pods[index] then
					placed = true
					break
				end
			end
		end
		if not placed and carryBridge then
			placed = carryBridge.SpawnLoose(haul.speciesId, haul.tier,
				CFrame.new(home.origin), home.id)
		end
	end

	detachHaul(nest)
	nest.haul = nil

	if placed then
		log(string.format("%s returned a %d tier %s to %s (%s).",
			nest.id, haul.tier, haul.speciesId, home.id, why))
	else
		warn(string.format(
			"[Seed/NestService] %s could not put a %d tier %s back anywhere (%s).",
			nest.id, haul.tier, haul.speciesId, why))
	end
	return placed
end

--==============================================================================
-- TAKING IT OFF THE PLAYER, ONCE
--
-- Returns whether there is now something to walk home with. Everything that
-- makes this safe is upstream of it: `ResolveGuardianCatch` does not yield, so
-- the read, the roll, the mark and the clear of that player's slot happen in
-- one resumption. Two guardians reaching the same person in the same frame
-- cannot both come away holding something -- the second sees an empty hand, or
-- a pod the first already left, and throws them exactly as Greenhollow's would.
--
-- The record is set BEFORE the weld is attempted, so a rig with a missing seam
-- costs the pod its picture and not its journey home.
--==============================================================================
local function confiscateFrom(nest: Nest, victim: Player): boolean
	if nest.haul then
		return true
	end
	if not GameConfig.confiscateProfile(nest.biome.Id) then
		return false
	end
	local bridge = carryBridge
	if not bridge then
		return false
	end
	--==========================================================================
	-- ROLL, MARK OR TAKE
	--
	-- A pod no guardian has left yet is rolled once, at
	-- GameConfig.Parent.Confiscate.LeaveBehindChance. On a leave -- or on a pod
	-- some guardian already left -- it stays in the victim's hands and `false`
	-- sends this catch down the plain throw, whose ragdoll drops it through
	-- CarryService.Drop with the flag still on, and the guardian goes home
	-- empty-handed. `nest.haul` is nil by the guard above, so "hauling" cannot
	-- come back from here.
	--==========================================================================
	local outcome, held = bridge.ResolveGuardianCatch(victim, false)
	if outcome ~= "confiscated" then
		if outcome == "left" or outcome == "abandoned" then
			log(string.format("%s left %s's pod behind (%s).", nest.id, victim.Name, outcome))
		end
		return false
	end
	if type(held) ~= "table" or not held.species or type(held.tier) ~= "number" then
		return false
	end

	local haul: Haul = {
		speciesId = held.species.Id,
		tier = held.tier,
		fromNest = held.fromNest,
		model = nil,
		since = os.clock(),
		secretId = held.secretId,
	}
	nest.haul = haul
	attachHaul(nest, haul)
	log(string.format("%s took a %d tier %s off %s.",
		nest.id, haul.tier, haul.speciesId, victim.Name))
	return true
end

local function sleep(nest: Nest)
	-- Defensive. Every path that sets `hauling` deposits before it reaches here,
	-- but settling down holding the only copy of a pod is the one outcome this
	-- state machine must never have.
	if nest.haul then
		depositHaul(nest, "settled")
	end
	nest.state = "asleep"
	nest.sample = nil
	nest.target = nil
	-- Asleep is forgetting. Anybody still remembered was chased before it got
	-- home (the walk back takes them first), so this only drops the ineligible.
	table.clear(nest.thieves)
	table.clear(nest.marked)
	-- Rage is NOT cleared here. It fades on a timer instead, because a parent
	-- settles within a couple of seconds of throwing somebody while the pod it
	-- was defending is still lying on the ground -- clearing on sleep made
	-- coming back for that pod free, which is the exact case this exists for.
	nest.calmSince = os.clock()
	nest.chaseSince = 0
	nest.rampDone = nil
	nest.handOff = nil
	nest.humanoid.WalkSpeed = 0
	nest.parent:SetAttribute("Asleep", true)
end

--==============================================================================
-- THE WALK BACK, WHICHEVER STATE ASKED FOR IT
--
-- True once it has arrived. Shared by `returning` and `hauling` so that a
-- guardian carrying something walks home exactly the way an empty-handed one
-- does -- same speed rule, same arrival radius, same MoveTo. The only thing
-- carrying changes is what happens at the end of it.
--
-- Slower going home than coming, and PROFILED ONLY: the other four have always
-- walked back at whatever the chase left them on, and that is not this pass's
-- to change.
--==============================================================================
--==============================================================================
-- THE ONE WAY BACK
--
-- Every exit from a chase comes through here rather than assigning "returning"
-- directly, because whether the walk home is a walk or a haul is not something
-- the four exits should each have to remember. Get it wrong in one of them and
-- the guardian strolls home holding the only copy of a pod and then sleeps on
-- it -- which `sleep` would recover from, but recovering is not the same as
-- being right.
--
-- The haul clock is restarted rather than carried, because it exists to stop a
-- WALK running forever and a chase is not that walk. A guardian dragged up and
-- down the road three times still gets its full ninety seconds to finish.
--==============================================================================
local function goHome(nest: Nest)
	if nest.haul then
		if nest.state ~= "hauling" then
			nest.haul.since = os.clock()
		end
		nest.state = "hauling"
	else
		nest.state = "returning"
	end
end

--==============================================================================
-- THE NEXT THIEF, BEFORE HOME (2026-10-01)
--
-- Asked when a chase ends and on every tick of a walk home, with or without a
-- haul, so a thief remembered during a throw or a return is chased once that is
-- over. Never from where the guardian may not chase: inside the Safe Zone or
-- past the leash it walks on, keeps its memory, and asks again a tick later --
-- the red line and the backstop end chases exactly as they did. One chase at a
-- time, no second guardian.
--==============================================================================
local function canChaseFrom(nest: Nest): boolean
	local at = nest.root.Position
	return not MapService.IsInSafeZone(at) and (at - nest.origin).Magnitude <= P.LeashStuds
end

-- `handOff` (2026-10-09, the owner's guardian fix): straight on from a catch,
-- in the same raid -- the chase runs at the ramp's top (rampDone).
local function takeNextThief(nest: Nest, handOff: boolean?): boolean
	if next(nest.thieves) == nil or nest.busy or not canChaseFrom(nest) then
		return false
	end
	-- Never a body still in the air: one being thrown (its claim is held to the
	-- end of the throw) or limp. Not dropped either (nextThief drops whoever it
	-- is told is ineligible): set aside, remembered, chased once on their feet.
	local aloft: { [Player]: number } = {}
	for player, since in pairs(nest.thieves) do
		local body = player.Character
		if throwToken[player] ~= nil or (body ~= nil and isRagdolled(body)) then
			aloft[player] = since
		end
	end
	for player in pairs(aloft) do
		nest.thieves[player] = nil
	end
	local thief = GuardianPursuit.nextThief(nest.thieves, nest.root.Position, function(player: Player): Vector3?
		return eligibleThief(nest, player)
	end)
	for player, since in pairs(aloft) do
		nest.thieves[player] = since
	end
	if not thief then
		return false
	end
	nest.target = thief
	nest.sample = nil
	nest.state = "chasing"
	nest.chaseSince = os.clock()
	nest.rampDone = if handOff then true else nil
	nest.stateUntil = 0
	pinToServer(nest)
	setWalk(nest, chaseSpeedFor(nest, os.clock()))
	log(string.format("%s turns on %s, who robbed it while it was busy.", nest.id, thief.Name))
	return true
end

-- Every end of a chase: the target goes, its sweep with it, and the walk home
-- starts -- unless somebody remembered is next.
-- `handOff`: the end of a catch's throw -- the next chase is the same raid.
local function endChase(nest: Nest, handOff: boolean?)
	nest.target = nil
	nest.sample = nil
	goHome(nest)
	takeNextThief(nest, handOff)
end

-- How far the guardian's colliding body reaches from its root, flat: measured
-- from the rig once and kept on the nest (a hauled pod is not counted -- it
-- rides in the fist, inside this).
local function bodyReach(nest: Nest): number
	local known = nest.reach
	if known then
		return known
	end
	local reach = 2
	local root = nest.root
	for _, part in ipairs(nest.parent:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			local rel = root.CFrame:PointToObjectSpace(part.Position)
			local size = part.Size
			reach = math.max(reach, math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
				+ 0.5 * math.sqrt(size.X * size.X + size.Z * size.Z))
		end
	end
	nest.reach = reach
	return reach
end

-- The next point along an off-road nest's route home: the far end of whichever
-- leg of it the guardian stands nearest, or the leg after that once it has all
-- but reached it. Rooms are wider than the corridors between them, so the line
-- from anywhere on a leg to its far end stays on the floor.
local function routeStep(route: { Vector3 }, at: Vector3): Vector3
	local flat = Vector3.new(at.X, 0, at.Z)
	local best, leg = math.huge, 1
	for i = 1, #route - 1 do
		local a = Vector3.new(route[i].X, 0, route[i].Z)
		local ab = Vector3.new(route[i + 1].X, 0, route[i + 1].Z) - a
		local t = math.clamp((flat - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
		local d = (a + ab * t - flat).Magnitude
		if d < best then
			best, leg = d, i
		end
	end
	local goal = route[math.min(leg + 1, #route)]
	if (Vector3.new(goal.X, 0, goal.Z) - flat).Magnitude < 12 and route[leg + 2] then
		goal = route[leg + 2]
	end
	-- BEHIND THE ROUTE'S FIRST POINT (2026-10-02): out on the bridge, where a
	-- chase that ran up to the safe line can carry a guardian (Stormstrider's,
	-- at 2.5 x, covers thirty to forty-five studs a tick), it walks back to that point first
	-- -- straight down the bridge it came up -- instead of cutting across the
	-- mouth room's rim towards the first leg's far end.
	if leg == 1 then
		local a = Vector3.new(route[1].X, 0, route[1].Z)
		local ab = Vector3.new(route[2].X, 0, route[2].Z) - a
		if (flat - a):Dot(ab) < 0 and (a - flat).Magnitude > 12 then
			goal = route[1]
		end
	end
	return Vector3.new(goal.X, at.Y, goal.Z)
end

local function walkHome(nest: Nest): boolean
	local home = Vector3.new(nest.origin.X, nest.root.Position.Y, nest.origin.Z)
	if (nest.root.Position - home).Magnitude < 6 then
		return true
	end
	if profileOf(nest) then
		setWalk(nest, returnSpeedFor(nest))
	end
	-- AN OFF-ROAD NEST WALKS ITS OWN ROUTE (the Rain event's, 2026-10-02): its
	-- biome is not the road, and the road's mouth is not on its way home.
	local route = nest.route
	if route and #route >= 2 then
		nest.humanoid:MoveTo(routeStep(route, nest.root.Position))
		return false
	end
	--==========================================================================
	-- THROUGH THE MOUTH, NEVER INTO A WALL'S END (2026-10-01)
	--
	-- Inside the corridor this is the straight line it always was. From the
	-- field -- where a guardian used to be carried by the chase's last order
	-- (see THE HIT ENDS THE CHASE'S LAST ORDER) -- it lines up in front of the
	-- mouth first, a body's width and a stud and a half clear of either wall,
	-- then walks in: GuardianPursuit.routeHome.
	--==========================================================================
	local map = GameConfig.Map
	local reach = bodyReach(nest)
	nest.humanoid:MoveTo(GuardianPursuit.routeHome(nest.root.Position, home, -map.FieldFront,
		map.CorridorWidth * 0.5 - reach - 1.5, reach + 4))
	return false
end

--==============================================================================
-- A LOST GUARDIAN IS REBUILT (2026-10-04)
--
-- The owner found a live server -- hours old, on the patch before -- with no
-- guardian at any nest, and a restart brought every one back. That is what
-- this file did: a guardian was built once, when its nest was raised, and
-- nothing rebuilt one whose rig went away. Dusk's ResetParents moves a guardian
-- home only while its root still exists, so a rig that fell out of the world
-- (the engine deletes parts under FallenPartsDestroyHeight), died or was
-- removed stayed gone until the server shut down. WHAT took them on that
-- server is not known: its own log is not on any machine we have.
--
-- So every tick checks the SERVER'S rig, never whether a client can see it:
--
--   gone     the model, its root or its Humanoid is no longer where the builder
--            put them (out of the Workspace counts)
--   dead     its Humanoid has died. Nothing in this game damages a guardian
--            (three rigs have unlimited health; Miremaw and Forgemaw keep the
--            default 100), but a Humanoid can still die, and a dead one never
--            moves again
--   fallen   its root is GameConfig.Parent.Recovery.FallStuds under its own
--            nest's floor, or somewhere no number can say
--
-- Far away, chasing, hauling, mid-throw and asleep are none of those, and a
-- guardian that is any of them is never touched.
--
-- WHAT A REBUILD IS, AND IS NOT
--
--   * ONLY THE RIG: the same builder (ParentModel.Build) at the same spot with
--     the same id the nest was raised with (`buildAt`, `rigId`). Never
--     buildNest, Start or OpenEventNest -- those roll pods. The pods, the secret
--     encounter and its serial, the rage and the event id are the nest's and are
--     not touched, so the one batch per weather cannot be broken from here.
--   * A HAUL GOES HOME FIRST, through depositHaul (the only way a haul ends):
--     the pod is a record on the nest, so it goes back to its ring, its secret
--     spot or the ground exactly once -- never lost, never twice, never rolled
--     again -- whether or not the rebuild then succeeds.
--   * ONE RIG PER NEST: the new one is built and checked; then any other
--     NestParent in the folder and the old rig are destroyed; then the record
--     points at the new one -- all without a yield.
--   * A CLEAN START: server ownership; no sweep sample (one taken from the old
--     body would be a line across the map, and a catch along it a teleport
--     catch); no target; not busy; the body's reach measured again. A guardian
--     that was up (waking, chasing, returning, hauling) starts `returning` at
--     its own nest: its last target is remembered as a thief while still
--     eligible, the thieves are pruned, and the walk home turns on the next one
--     or lies down -- the ordinary rules. One that was asleep stays asleep. The
--     pursuit counts are published at once, so nobody keeps a warning about a
--     guardian that is not there.
--   * THE WEATHER'S GUARDIAN ONLY WHILE ITS WEATHER STANDS: Stormstrider is
--     rebuilt only while its nest is registered, its terrain is in the world and
--     the weather still names its event as opening or active. Closing the
--     event, removing the terrain or stopping this service always wins.
--   * IDEMPOTENT, WITH A BACKOFF: a healthy rig is never rebuilt. A rebuild that
--     fails waits RetrySeconds (2, 4, 8 ... 60) and warns at most every
--     WarnEverySeconds; a refusal is said once.
--   * A THROW IN FLIGHT IS WAITED FOR: `busy` owns the nest until the throw lets
--     go (THROW_TIMEOUT). Past BusyCapSeconds a lost rig is rebuilt anyway.
--==============================================================================
local RECOVER = P.Recovery

-- The builder a rebuild calls. A spec may swap in one that fails (SpecRigBuilder).
local rigBuilder: (CFrame, number, string, Instance) -> Model = ParentModel.Build
-- A spec's weather, for the records it hands in (SpecWeather). Nil: closed.
local specWeather: ((any) -> boolean)? = nil

-- Pure: the weather publishes this event as standing.
function NestService.EventOpenFor(eventId: number?, publishedId: any, publishedState: any): boolean
	return eventId ~= nil and publishedId == eventId
		and (publishedState == "opening" or publishedState == "active")
end

local function eventStands(nest: Nest): boolean
	if nest.spec then
		local f = specWeather
		return f ~= nil and f(nest) == true
	end
	local W = GameConfig.Weather.Attributes
	return table.find(nests, nest) ~= nil
		and NestService.EventOpenFor(nest.event, Workspace:GetAttribute(W.EventId), Workspace:GetAttribute(W.State))
end

local function finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e7 and math.abs(v.Y) < 1e7 and math.abs(v.Z) < 1e7
end

-- Why this nest's guardian is lost, or nil when it is not.
local function lostGuardian(nest: Nest): string?
	local model: any = nest.parent
	if typeof(model) ~= "Instance" or not model:IsDescendantOf(Workspace) then
		return "its rig is gone"
	end
	local root: any = nest.root
	if typeof(root) ~= "Instance" or not root:IsDescendantOf(model) then
		return "its root is gone"
	end
	local humanoid: any = nest.humanoid
	if typeof(humanoid) ~= "Instance" or humanoid.Parent ~= model then
		return "its Humanoid is gone"
	end
	if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return "it died"
	end
	local at = root.Position
	if not finite(at) then
		return "its position is not a number"
	end
	if at.Y < nest.origin.Y - RECOVER.FallStuds then
		return string.format("it fell out of the world, %d studs under its nest", math.floor(nest.origin.Y - at.Y))
	end
	return nil
end

local function where(v: Vector3?): string
	return if v then string.format("(%d, %d, %d)", math.floor(v.X), math.floor(v.Y), math.floor(v.Z)) else "(unknown)"
end

local function refuseRebuild(nest: Nest, rec: Recovery, why: string)
	if rec.refused == why then
		return
	end
	rec.refused = why
	warn(string.format("[Seed/NestService] %s lost its guardian (%s; it was %s at %s%s) and will not rebuild it: %s.",
		nest.id, rec.reason, rec.previous, where(rec.lastAt),
		if nest.event ~= nil then string.format(", event %d", nest.event) else "", why))
end

-- True once a new rig stands in the record; false while deferred, refused or failed.
local function recoverGuardian(nest: Nest, reason: string, now: number): boolean
	local rec = nest.recovery
	if not rec then
		rec = {
			reason = reason,
			previous = nest.state,
			lastAt = nest.lastSeen,
			since = now,
			settled = false,
			failures = 0,
			nextAt = now,
			warnedAt = -math.huge,
			refused = nil,
		}
		nest.recovery = rec
	end
	local r = rec :: Recovery
	-- Nothing outlives its service, its nest or its weather.
	if not (running or nest.spec) then
		refuseRebuild(nest, r, "the nest service has stopped")
		return false
	end
	local folder: any = nest.folder
	if typeof(folder) ~= "Instance" or not folder:IsDescendantOf(Workspace) then
		refuseRebuild(nest, r, "its nest is gone")
		return false
	end
	if nest.event ~= nil and not eventStands(nest) then
		refuseRebuild(nest, r, string.format("its weather (event %d) is over", nest.event :: number))
		return false
	end
	-- A throw in flight owns the nest until it lets go.
	if nest.busy and now - (nest.busySince or now) < RECOVER.BusyCapSeconds then
		return false
	end
	-- The pod in its fist goes home now, whatever the rebuild does.
	if nest.haul then
		depositHaul(nest, "its guardian was lost")
	end
	-- Up when it went: it lets go of the chase now, so nobody is warned about a
	-- guardian that is not there. Its target is remembered, if still a thief.
	if not r.settled then
		r.settled = true
		if nest.state ~= "asleep" then
			local target = nest.target
			if target and eligibleThief(nest, target) then
				nest.thieves[target] = nest.thieves[target] or now
			end
			nest.target = nil
			nest.sample = nil
			nest.busy = false
			nest.busySince = nil
			nest.handOff = nil
			nest.state = "returning"
			nest.stateUntil = 0
			pcall(publishPursuit)
		end
	end
	if now < r.nextAt then
		return false
	end

	local ok, built = pcall(rigBuilder, nest.buildAt :: CFrame, PARENT_HEIGHT, nest.rigId :: string, folder)
	local model: Model? = if ok and typeof(built) == "Instance" and (built :: Instance):IsA("Model")
		then built :: Model else nil
	local humanoid = if model then model:FindFirstChildOfClass("Humanoid") else nil
	local root = if model then model.PrimaryPart else nil
	if not (model and humanoid and root) then
		if model then
			pcall(model.Destroy, model)
		end
		r.failures += 1
		local waits = RECOVER.RetrySeconds
		local pause = waits[math.min(r.failures, #waits)] or 60
		r.nextAt = now + pause
		if now - r.warnedAt >= RECOVER.WarnEverySeconds then
			r.warnedAt = now
			warn(string.format("[Seed/NestService] %s could not rebuild its guardian (%s, try %d): %s. Next try in %d s.",
				nest.id, tostring(nest.rigId), r.failures,
				if ok then "the rig had no Humanoid or root" else tostring(built), pause))
		end
		return false
	end

	-- One rig per nest: any stray, then the old rig, then the record.
	for _, child in ipairs(folder:GetChildren()) do
		if child ~= model and child:IsA("Model") and CollectionService:HasTag(child, GameConfig.Tags.NestParent) then
			child:Destroy()
		end
	end
	local old: any = nest.parent
	if typeof(old) == "Instance" and old ~= model and old.Parent then
		old:Destroy()
	end
	nest.parent = model
	nest.humanoid = humanoid
	nest.root = root
	nest.homeCFrame = root.CFrame
	nest.reach = nil
	nest.sample = nil
	nest.target = nil
	nest.busy = false
	nest.busySince = nil
	nest.stateUntil = 0
	GuardianPursuit.prune(nest.thieves, function(player: Player): Vector3?
		return eligibleThief(nest, player)
	end)
	if nest.state == "asleep" then
		humanoid.WalkSpeed = 0
		model:SetAttribute("Asleep", true)
	else
		nest.state = "returning"
		model:SetAttribute("Asleep", false)
	end
	pinToServer(nest)
	nest.lastSeen = root.Position
	nest.recovery = nil
	pcall(publishPursuit)
	log(string.format("%s (%s) lost its guardian -- %s; it was %s at %s%s. Rebuilt at its nest%s.",
		nest.id, nest.biome.Id, r.reason, r.previous, where(r.lastAt),
		if nest.event ~= nil then string.format(", event %d", nest.event :: number) else "",
		if r.failures > 0 then string.format(" after %d failed try(s)", r.failures) else ""))
	return true
end

-- Studio only: the builder a rebuild uses (nil puts ParentModel.Build back),
-- and the weather a spec's records answer to.
function NestService.SpecRigBuilder(fn: ((CFrame, number, string, Instance) -> Model)?)
	if not RunService:IsStudio() then
		return
	end
	rigBuilder = fn or ParentModel.Build
end

function NestService.SpecWeather(fn: ((any) -> boolean)?)
	if not RunService:IsStudio() then
		return
	end
	specWeather = fn
end

local function step(nest: Nest, now: number)
	--==========================================================================
	-- A LOST GUARDIAN FIRST (above). Only on a nest this file raised itself: a
	-- spec's hand-built record has no rig id and is left exactly as it was.
	--==========================================================================
	if nest.rigId ~= nil then
		local lost = lostGuardian(nest)
		if lost then
			if not recoverGuardian(nest, lost, now) then
				return
			end
		else
			nest.lastSeen = nest.root.Position
			nest.recovery = nil
		end
	end

	--==========================================================================
	-- THE STATE IS PUBLISHED, ONCE, WHENEVER IT CHANGES
	--
	-- `Asleep` was the only thing a client knew, and it cannot tell a chase from
	-- a walk home -- so a guardian that had just thrown somebody strolled back
	-- to its nest with the same hunting gait it arrived with.
	--
	-- Published HERE rather than at each of the nine places `state` is assigned:
	-- one writer, and it cannot go stale because the tick is the thing that owns
	-- the state machine. Written only on a change, so it is not eight property
	-- replications a second per nest.
	--==========================================================================
	if nest.parent:GetAttribute("ParentState") ~= nest.state then
		nest.parent:SetAttribute("ParentState", nest.state)
	end

	--== RAGE FADES ==--
	if nest.rage > 0 and nest.state == "asleep" and nest.calmSince > 0
		and now - nest.calmSince >= P.RageForgetSeconds then
		nest.rage = 0
		nest.calmSince = 0
	end

	--== A POD RUSH GROWS A TAKEN SLOT BACK (takeSlot; 2026-10-09) ==--
	-- Above the busy and asleep returns: a nest mid-throw or asleep regrows too.
	-- Only while the rush is on and it is day; normal pods, normal odds.
	local due = nest.regrowAt
	if due then
		for slot, at in pairs(due) do
			if now >= at then
				due[slot] = nil
				if rushOn and GameConfig.isDay() then
					growPod(nest, slot)
				end
			end
		end
	end

	-- Remembered thieves who reached safety, died, left or stopped carrying this
	-- nest's pod are dropped as soon as it happens, not when their turn comes.
	if next(nest.thieves) ~= nil then
		GuardianPursuit.prune(nest.thieves, function(player: Player): Vector3?
			return eligibleThief(nest, player)
		end)
	end

	if nest.busy then
		return
	end

	if nest.state == "asleep" then
		return

	elseif nest.state == "waking" then
		if now >= nest.stateUntil then
			nest.state = "chasing"
			nest.chaseSince = os.clock()
			nest.rampDone = nil
			setWalk(nest, chaseSpeedFor(nest, os.clock()))
			nest.parent:SetAttribute("Asleep", false)
		end
		return

	elseif nest.state == "chasing" then
		local pos = targetPosition(nest.target)
		-- Safety is safety. A parent that could be kited across the red line
		-- would make the one promise the map makes into a lie.
		if not pos or MapService.IsInSafeZone(pos) then
			-- Home, dead or gone: the secret encounter lets go of them.
			if nest.target then
				nest.marked[nest.target] = nil
			end
			endChase(nest)
			return
		end
		--==============================================================
		-- THE PARENT STOPS AT THE RED LINE, NOT AT A RADIUS
		--
		-- Checked against the PARENT rather than the target, and it is the
		-- guard that actually keeps the promise the map makes. The target is
		-- already checked above -- that ends the chase when the player is home
		-- -- but nothing stopped the monster itself crossing, and the radius
		-- that used to stand in for this ended every pursuit twenty studs
		-- before the chaser left its own biome.
		--==============================================================
		if MapService.IsInSafeZone(nest.root.Position) then
			endChase(nest)
			return
		end
		-- Backstop only. See GameConfig.Parent.LeashStuds: this is two segments,
		-- so a normal cross-biome chase never reaches it and a broken one cannot
		-- run forever.
		if (nest.root.Position - nest.origin).Magnitude > P.LeashStuds then
			-- The leash is an exit for a marked thief too.
			if nest.target then
				nest.marked[nest.target] = nil
			end
			endChase(nest)
			return
		end
		--==================================================================
		-- CONTACT. Not a grab -- there is no hold any more, reaching the
		-- player is the hit.
		--
		-- Measured across the whole tick, with BOTH bodies moving, flattened
		-- to the ground plane so a jump does not read as distance. See THE
		-- GRAB IS SWEPT above, and GuardianPursuit.closestApproach. Nothing
		-- waits on the guardian turning to face anybody: the tick that finds
		-- contact is the tick that hits.
		--==================================================================
		--==================================================================
		-- THE RAMP, RE-EVALUATED EVERY TICK -- AND ONLY FOR A PROFILE
		--
		-- Guarded rather than relying on chaseSpeedFor returning the same
		-- number for everybody else. It would, mostly, but not always: the
		-- unprofiled speed reads the thief's Speed SCORE, and the treadmill can
		-- raise that mid-chase. Those four parents lock their speed in at the
		-- state change and have always done so, and re-deriving it eight times
		-- a second would be a quiet behaviour change in four creatures this
		-- pass is not allowed to touch.
		--==================================================================
		if profileOf(nest) then
			setWalk(nest, chaseSpeedFor(nest, now))
		end

		--==============================================================
		-- A SAMPLE IS ONLY A SWEEP'S START IF NOTHING BROKE IN BETWEEN
		--
		-- The last sample can be stale -- a chase that ended and restarted,
		-- a respawn, a throw, a gate pushing somebody back, a new target.
		-- Sweeping from there to here would be a line across half the map,
		-- and everything it passed near would count as a hit. Refused
		-- samples (GuardianPursuit.sampleUsable) leave this tick the plain
		-- distance between the two bodies now, as it always was.
		--==============================================================
		local victimNow = nest.target :: Player
		local body = victimNow.Character
		local parentNow = nest.root.Position
		local last = nest.sample
		local reach: number
		local velocity: Vector3? = nil
		-- A guardian built faster than any player (a profile's SpeedScale --
		-- Stormstrider's 2.5) gets its OWN travel allowance widened by that
		-- factor, so its ordinary ticks still sweep; the target's stays
		-- MAX_TICK_TRAVEL, and every unscaled guardian is exactly as it was.
		local sweepProf = profileOf(nest)
		local parentTravel = MAX_TICK_TRAVEL * math.max(1, tonumber(sweepProf and sweepProf.SpeedScale) or 1)
		if last and GuardianPursuit.sampleUsable(last, victimNow, body, parentNow, pos, now,
			MAX_TICK_TRAVEL, SAMPLE_MAX_AGE, parentTravel) then
			reach = GuardianPursuit.closestApproach(last.parentAt, parentNow, last.targetAt, pos)
			velocity = GuardianPursuit.flat(pos - last.targetAt) / (now - last.at)
		else
			reach = GuardianPursuit.flat(pos - parentNow).Magnitude
		end
		nest.sample = { target = victimNow, body = body, parentAt = parentNow, targetAt = pos, at = now }
		if reach <= P.GrabStuds then
			local victim = nest.target
			nest.busy = true
			nest.busySince = now
			--==============================================================
			-- ONE BOLT PER CATCH, AND ONLY TO LOOK AT (2026-10-02)
			--
			-- A profile with CatchLightning (Stormstrider) stamps where and when
			-- this catch landed; every client draws one brief strike there
			-- (ParentAnim). Nothing else: no damage, no stun, no second effect
			-- -- the catch is the catch every guardian makes. Its sound is the
			-- StormstriderStrike emit below, ONCE here per confirmed catch (the
			-- clients' bolt is silent, so nothing plays it twice).
			--==============================================================
			local strikeProf = profileOf(nest)
			if strikeProf and strikeProf.CatchLightning == true then
				nest.parent:SetAttribute("CatchStrikeAt", pos)
				nest.parent:SetAttribute("CatchStrikeTime", Workspace:GetServerTimeNow())
				SoundKit.emit(GameConfig.Weather.Audio.StormstriderStrike, nest.root)
			end
			--==============================================================
			-- THE HIT ENDS THE CHASE'S LAST ORDER (2026-10-01)
			--
			-- That order is a point ChaseOvershootStuds PAST the thief (AIM
			-- PAST THEM, below), and while `busy` the tick returns before any
			-- order is given -- so nothing replaced it, and the guardian ran on
			-- at chase speed for the whole throw. Measured in Play: 44 to 62
			-- studs after the hit; at the road's mouth that is out of the
			-- corridor and into the Safe Zone, where the straight walk home
			-- then met a wall's end face head-on and stood there for good.
			--
			-- It stops where it hit instead, momentum and all; the next thief
			-- or the walk home gives the next order when the throw is over.
			--==============================================================
			nest.humanoid:MoveTo(nest.root.Position)
			local drift = nest.root.AssemblyLinearVelocity
			nest.root.AssemblyLinearVelocity = Vector3.new(0, drift.Y, 0)
			task.spawn(function()
				-- pcall'd because `busy` MUST be released. An error in here kills
				-- the thread and leaves the nest busy forever -- its parent frozen
				-- mid-grab, never chasing, never sleeping, never recovering. That
				-- is not hypothetical: a bad edit left `dir` undefined, throwPlayer
				-- threw on a nil index, and the nest went catatonic with no error
				-- anywhere near the thing that stopped working.
				local took = false
				--==============================================================
				-- FREE AT THE LAUNCH (2026-10-09, the owner: "we gotta fix
				-- guardians first")
				--
				-- The throw yields through the victim's flight -- the five-odd
				-- seconds -- and `busy` held the guardian standing for all of
				-- it while a second thief it remembered ran on: "seems stopping
				-- for a while then chase". Now the moment the victim leaves the
				-- ground, a remembered thief it can still chase is chased at
				-- once, at the ramp's top (takeNextThief's hand-off), and the
				-- flight finishes on its own. Nobody to turn on: it holds as it
				-- always did -- unless somebody robs it before the victim lands,
				-- which provoke hands straight to the same release
				-- (nest.handOff). Never the victim, who is in the air.
				--==============================================================
				local released = false
				local function handOff(): boolean
					if released or not nest.busy or not (nest.target == victim or nest.target == nil) then
						return false
					end
					nest.busy = false
					if takeNextThief(nest, true) then
						released = true
						if nest.handOff == handOff then
							nest.handOff = nil
						end
						nest.busySince = nil
						return true
					end
					nest.busy = true
					return false
				end
				local function launched()
					if not handOff() and not released and nest.busy then
						nest.handOff = handOff
					end
				end
				if victim then
					--==========================================================
					-- CONFISCATE FIRST, THEN THROW. THE ORDER IS THE FEATURE.
					--
					-- The throw sets PlatformStand, and CarryService turns that
					-- into a Drop -- which is how being caught has always put
					-- the pod on the road. Taking it first leaves that watcher
					-- with nothing to drop, so the pod goes home with the
					-- guardian instead of landing at the victim's feet.
					--
					-- Doing it the other way round would produce BOTH: a loose
					-- pod on the road and a hauled one, out of a single pod.
					--
					-- Also pcall'd, and outside the throw's pcall on purpose: a
					-- confiscation that threw would otherwise skip the throw,
					-- and being caught has to cost the distance whether or not
					-- the pod part of it worked.
					--==========================================================
					--==========================================================
					-- A TRAP LETS GO BEFORE A GUARDIAN THROWS
					--
					-- Required in its own right -- a player cannot be held by
					-- two things at once and the guardian's hit is the louder
					-- one -- and it is also the ordering that makes the freeze
					-- impossible rather than merely fixed: by the time
					-- `throwPlayer` touches WalkSpeed there is no trap holding
					-- it at zero.
					--
					-- Only on a CONFIRMED catch. This runs inside the contact
					-- branch, after the contact sweep has accepted the hit, so
					-- a miss or a chase that ends releases nothing.
					--
					-- The release grants the usual four seconds of trap immunity
					-- on its way out, so being caught in a trap by a guardian
					-- does not immediately re-arm the same trap on the victim.
					--==========================================================
					local combat = combatBridge
					if combat then
						pcall(combat.ReleaseTrap, victim, "a guardian caught them")
					end

					-- Read BEFORE the confiscation, which empties the hands.
					local carriedSecret: string? = nil
					local bridge = carryBridge
					if bridge and bridge.CarriedSecret then
						local okSecret, id = pcall(bridge.CarriedSecret, victim)
						carriedSecret = if okSecret and type(id) == "string" then id else nil
					end

					local tookOk, tookErr = pcall(confiscateFrom, nest, victim)
					if tookOk then
						took = tookErr :: any
					else
						warn("[Seed/NestService] confiscate failed: " .. tostring(tookErr))
					end
					--==========================================================
					-- A CATCH THAT DID NOT TAKE THE SECRET (2026-10-01)
					--
					-- The throw's ragdoll drops the pod, as it always has, and
					-- "POD LEFT BEHIND!" says so over the guardian's head. The
					-- thief is NOT left behind: marked and remembered, so when
					-- the throw is over endChase turns on them again with empty
					-- hands, and the secret numbers hold until safety, death,
					-- leaving or the leash.
					--==========================================================
					local secret = nest.secret
					if carriedSecret and secret and secret.id == carriedSecret and not took then
						nest.marked[victim] = true
						nest.thieves[victim] = os.clock()
						nest.parent:SetAttribute("LeftBehindAt", Workspace:GetServerTimeNow())
						log(string.format("%s left the secret behind with %s and keeps after them.", nest.id, victim.Name))
					end
					if took then
						--======================================================
						-- THE STATE CHANGES WITH THE POD, NOT AFTER THE THROW
						--
						-- throwPlayer YIELDS -- the ragdoll, the flight and the
						-- stand-up are seconds, not a frame -- and `busy` keeps
						-- the tick out for all of it. But the tick publishes
						-- ParentState BEFORE it checks busy, so leaving the
						-- assignment until afterwards left the guardian reading
						-- `chasing` while it was already holding the pod.
						--
						-- Measured on Forgemaw: 5.5 seconds of a hunting gait
						-- with a pod welded to its fist, which is exactly the
						-- tell that it is not really carrying anything.
						--
						-- Assigning here is safe precisely BECAUSE busy is set:
						-- no movement runs off this state until the throw is
						-- done, so this changes what the client draws and
						-- nothing else. The assignment below still stands for
						-- the empty-handed case.
						--======================================================
						nest.state = "hauling"
					end

					local ok, err = pcall(throwPlayer, nest, victim, launched)
					if not ok then
						warn("[Seed/NestService] throw failed: " .. tostring(err))
						-- Never leave somebody ragdolled because the throw broke,
						-- and never leave them claimed by a throw that is not
						-- running: nothing else would ever let them be thrown again.
						throwToken[victim] = nil
						throwDone[victim] = nil
						local character = victim.Character
						local humanoid = character
							and character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid.PlatformStand = false
						end
					end
				end
				--==========================================================
				-- SOMEBODY MAY HAVE ROBBED THE RING WHILE THIS ONE WAS IN
				-- THE AIR
				--
				-- `busy` keeps the TICK out of the nest for the five-odd
				-- seconds a throw lasts. It does not keep `provoke` out --
				-- `TakePod` never looks at it -- so a second thief during
				-- that window does everything it normally does: stacks rage,
				-- sets the state to chasing, points the target at itself and
				-- writes the new speed. Then these lines ran unconditionally
				-- and threw all of it away, and the guardian walked home past
				-- somebody who had just emptied a slot in front of it.
				--
				-- The same fault `provoke` was fixed for, narrowed from the
				-- whole walk back to the throw window -- rarer, and identical
				-- from the road, which is why it survived that fix.
				--
				-- So the nest is released only if it is still pointed at the
				-- person who was just thrown. Anything else means someone
				-- claimed it while this ran, `provoke` has already set the
				-- state and the speed, and the only correct thing to do here
				-- is leave both alone. Holding something still makes the walk
				-- home a different state, and an empty-handed catch that
				-- nobody interrupted is bit-for-bit the old one.
				--
				-- Since 2026-10-01 a thief during the throw does not take the
				-- target (the person being thrown is still a valid one): they
				-- are remembered, and endChase turns on the nearest of them
				-- here, before the walk home. The sweep sample goes either
				-- way -- the throw moved everybody.
				--==========================================================
				--
				-- Unless the launch already handed the guardian on (above):
				-- then this is the victim's landing and nothing more -- a late
				-- end of a throw never ends the chase that followed it.
				if nest.handOff == handOff then
					nest.handOff = nil
				end
				if not released then
					released = true
					nest.sample = nil
					nest.busy = false
					if nest.target == victim or nest.target == nil then
						endChase(nest, true)
					end
				end
			end)
			return
		end
		-- NO MANUAL FACING. This used to write root.CFrame every tick to look at
		-- the target, which did two bad things: it only ran while CHASING, so
		-- the walk home was done backwards, and it teleported a physics assembly
		-- eight times a second while the Humanoid was trying to move it.
		-- AutoRotate does it properly, in both directions.
		--==============================================================
		-- AIM PAST THEM, NEVER AT THEM
		--
		-- See GameConfig.Parent.ChaseOvershootStuds. Handing MoveTo the target's
		-- own position makes the Humanoid brake for an arrival that never
		-- happens, and it settles about thirteen studs back -- outside GrabStuds
		-- at every speed the game can produce. The parent looked like it was
		-- chasing and could not land a hit on anybody who kept running.
		--
		-- Flattened, because a target on higher ground would otherwise tilt the
		-- aim point into the sky or the floor and shorten the overshoot to
		-- nothing at exactly the moment it matters.
		--
		-- CLOSE IN, IT AIMS WHERE THEY WILL BE (2026-10-01). Within
		-- ChaseLeadStuds the line bends toward where the target will be when
		-- the next order goes out, one TICK on, from this sweep's own
		-- velocity -- an order aimed at where a strafing player WAS is a
		-- guardian trailing round behind them. At range, and whenever the
		-- sample was refused, it is the straight line it always was. Standing
		-- on top of them it keeps facing forward rather than divide by zero.
		--==============================================================
		local heading = GuardianPursuit.heading(nest.root.Position, pos, velocity, TICK,
			P.ChaseLeadStuds, nest.root.CFrame.LookVector)
		nest.humanoid:MoveTo(pos + heading * P.ChaseOvershootStuds)
		return

	elseif nest.state == "hauling" then
		--==================================================================
		-- WALKING HOME HOLDING THE ONLY COPY OF SOMETHING
		--
		-- Identical to `returning` except that it cannot simply end. Every
		-- way out of this state goes through depositHaul, including the ways
		-- that are not the guardian arriving, because the pod exists nowhere
		-- else while this is running.
		--
		-- Chasing is not one of those ways either, but not because it cannot
		-- happen: `provoke` retargets a hauler like anything else and the
		-- pod rides along in its fist. The chase does not END the haul, it
		-- interrupts it, and `goHome` puts the guardian back here afterwards
		-- with the clock restarted. This comment used to claim the opposite,
		-- and was wrong from the moment provoke stopped refusing.
		--==================================================================
		local haul = nest.haul
		if not haul then
			-- Deposited by something outside the tick. Finish as a plain walk.
			nest.state = "returning"
			return
		end
		-- The rig can go away underneath a haul: a nest rebuild, a dead
		-- guardian, a map reload. Checked every tick rather than at the end,
		-- because the end is the thing that would never arrive.
		if not (nest.parent.Parent and nest.root.Parent) then
			depositHaul(nest, "the guardian went away")
			nest.state = "returning"
			return
		end
		-- A thief remembered during the catch or the walk is chased first, the
		-- pod riding along exactly as it does when provoke interrupts a haul.
		if takeNextThief(nest) then
			return
		end
		-- A route that never completes must not hold a pod forever. Past the
		-- ceiling it goes back into the ring anyway -- depositHaul does not
		-- care where the guardian got to, and a pod in its slot is a better
		-- outcome than a pod beside a guardian wedged on a rock.
		if now - haul.since > P.HaulSeconds then
			depositHaul(nest, "the walk home timed out")
			sleep(nest)
			return
		end
		if walkHome(nest) then
			depositHaul(nest, "arrived")
			sleep(nest)
		end
		return

	else -- returning
		if takeNextThief(nest) then
			return
		end
		if walkHome(nest) then
			sleep(nest)
		end
	end
end

--==============================================================================
-- THE CHASE, REACHABLE BY A SPEC (2026-10-01)
--
-- `provoke` and one tick of `step`, on a nest record the spec builds itself, so
-- GuardianPursuitSpec drives the real memory, the real exits and the real
-- sweep without a map, a rig or a Play session. Studio-only, like SpecThrow:
-- on a live server both return before touching anything.
--==============================================================================
-- A record a spec built by hand predates the secret encounter's two fields;
-- buildNest always makes them, so only these entry points fill them in.
local function specRecord(nest: any)
	if nest.marked == nil then
		nest.marked = {}
	end
	-- A spec's record: its rebuilds (when it gives a rig id) answer to the spec's
	-- weather and need no running service. See A LOST GUARDIAN IS REBUILT.
	nest.spec = true
end

function NestService.SpecProvoke(nest: any, thief: any, fromNest: boolean?, secretId: string?)
	if not RunService:IsStudio() then
		return
	end
	specRecord(nest)
	provoke(nest, thief, fromNest == true, secretId)
end

function NestService.SpecStep(nest: any, now: number)
	if not RunService:IsStudio() then
		return
	end
	specRecord(nest)
	step(nest, now)
end

-- Studio specs (2026-10-09, POD RUSH): the slot take TakePod makes, on a
-- record the spec raised -- the pod destroyed, the regrowth a rush schedules,
-- the theft. False when the slot holds nothing.
function NestService.SpecTakeSlot(nest: any, slot: number, thief: any): boolean
	if not RunService:IsStudio() then
		return false
	end
	specRecord(nest)
	local pod = nest.pods[slot]
	if not pod then
		return false
	end
	takeSlot(nest, slot, pod, thief)
	return true
end

-- Studio specs (2026-10-08, FIRST MINUTE): what a thief's guide record says
-- about `steal` -- the stand-ins have no profile -- and the speed a nest would
-- chase at right now. nil puts the real record back.
function NestService.SpecStealDone(fn: ((any) -> boolean?)?)
	if not RunService:IsStudio() then
		return
	end
	stealDoneFn = fn
end

function NestService.SpecChaseSpeed(nest: any): number?
	if not RunService:IsStudio() then
		return nil
	end
	specRecord(nest)
	return chaseSpeedFor(nest, os.clock())
end

-- Studio specs: a fresh Secret at a nest the spec raised -- spawnSecret
-- itself, its refusals and its announcement (THE SECRET EGG TOAST).
function NestService.SpecSpawnSecret(nest: any, why: string?): (boolean, string?)
	if not RunService:IsStudio() then
		return false, "Studio only"
	end
	specRecord(nest)
	return spawnSecret(nest, why or "spec")
end

--==============================================================================
-- WHAT THE WORLD CYCLE DOES TO A NEST
--
-- Three calls, all from WorldCycleService and nowhere else. They are here rather
-- than there because a nest's pods, its parent's state machine and its rage all
-- live in this file, and a cycle service reaching into `nests` would be a second
-- owner of the same table.
--
-- None of them touch anything a PLAYER owns. A banked pod is a Tool in a
-- Backpack, a planted creature belongs to PlantService, and neither is reachable
-- from here -- which is the property that makes a nightly wipe safe to run.
--==============================================================================

--==============================================================================
-- DUSK: EVERYTHING IN THE RING GOES
--
-- Not hidden -- destroyed. The barrier at the road mouth is what stops anybody
-- SEEING down the corridor, and if pods were merely concealed behind it then
-- dawn would be a curtain going up on last night's leftovers, and a player who
-- cleared a nest at 06:59 would find it full again at 00:01 without a batch
-- having been rolled.
--==============================================================================
function NestService.ClearForNight(): number
	local removed = 0
	for _, nest in ipairs(nests) do
		-- A weather event's nest is the event's: it lays one batch and clears it
		-- itself (CloseEventNest). Dusk is the road's.
		if nest.event ~= nil then
			continue
		end
		--======================================================================
		-- A POD IN A GUARDIAN'S JAWS IS IN THE RING TOO
		--
		-- Destroyed with the rest of the batch rather than deposited, and this
		-- is the one place a haul ends without going back into the world. It is
		-- the night rule, not an exception to it: everything in the ring goes at
		-- dusk so that dawn is a fresh roll, and a confiscated pod is the nest's
		-- property by the time it is being carried. Depositing it here would
		-- also lose the race -- this runs BEFORE ResetParents and before the
		-- dawn restock, so the pod would sit in a slot the restock skips and
		-- survive a night nothing else survives.
		--
		-- The player already lost it at the catch. This decides only whether the
		-- nest keeps it until morning, and no other pod does.
		--======================================================================
		if nest.haul then
			detachHaul(nest)
			nest.haul = nil
			removed += 1
		end
		for slot, pod in pairs(nest.pods) do
			if pod and pod.Parent then
				pod:Destroy()
				removed += 1
			end
			nest.pods[slot] = nil
		end
		-- Nor does a Pod Rush's regrowth outlive the dusk.
		nest.regrowAt = nil
		-- The secret goes with the batch: its pod, its platform, its marks. Dawn
		-- is a fresh roll for the spot as for every slot.
		if nest.secret then
			resolveSecret(nest, "dusk")
			removed += 1
		end
	end
	return removed
end

--==============================================================================
-- DUSK: EVERY PARENT GOES HOME AND FORGETS
--
-- Put back at its ORIGIN rather than walked there: a parent halfway down the
-- road when the lights go out would spend the night pathing home past a barrier
-- it cannot cross, and a player standing in the field would watch a monster
-- jog at the wall all night.
--
-- Rage is cleared outright here, which is the one place that happens. It
-- normally FADES on a timer -- see GameConfig.Parent.RageForgetSeconds -- so
-- that coming back for the pod you dropped is not free. That fade is 45 s and
-- the night is 15 (since 2026-09-23), so without this line it would NOT have
-- finished by dawn -- and carrying yesterday's grudge into a freshly stocked
-- nest would punish the player who is first through the gate for something
-- that happened to somebody else.
--==============================================================================
function NestService.ResetParents(): number
	local reset = 0
	for _, nest in ipairs(nests) do
		-- Not a weather event's guardian: dusk is the road's (see ClearForNight).
		if nest.event ~= nil then
			continue
		end
		-- A reset outside dusk must not eat a pod. At dusk ClearForNight has
		-- already run and this finds nothing, so the night rule above still
		-- decides what happens on a night.
		if nest.haul then
			depositHaul(nest, "the parents were reset")
		end
		nest.busy = false
		nest.handOff = nil
		nest.sample = nil
		nest.target = nil
		table.clear(nest.thieves)
		table.clear(nest.marked)
		nest.rage = 0
		nest.calmSince = 0
		nest.state = "asleep"
		nest.stateUntil = 0
		if nest.root.Parent then
			nest.humanoid.WalkSpeed = 0
			nest.root.CFrame = nest.homeCFrame
			nest.root.AssemblyLinearVelocity = Vector3.zero
		end
		nest.parent:SetAttribute("Asleep", true)
		reset += 1
	end
	return reset
end

--==============================================================================
-- DAWN: ONE BATCH, EVERY SLOT, ONCE
--
-- Returns what it actually built so the caller can prove the batch exists before
-- it opens the road. "Stocked the nests" is a claim; "15 of 15" is a fact, and
-- the difference matters at the one moment the game is deciding whether players
-- are allowed back in.
--==============================================================================
function NestService.StockAll(): (number, number)
	local built, wanted = 0, 0
	for _, nest in ipairs(nests) do
		-- Never a weather event's: ONE batch per event, nothing restocks it.
		if nest.event ~= nil then
			continue
		end
		for index = 1, nest.biome.PodsPerNest do
			wanted += 1
			if not nest.pods[index] then
				growPod(nest, index)
			end
			if nest.pods[index] then
				built += 1
			end
		end
		-- The one roll of the restock, per nest, after its slots.
		rollSecret(nest, "the dawn restock")
	end
	return built, wanted
end

--==============================================================================
-- THE SECRET, FROM OUTSIDE
--==============================================================================
-- A spawn on demand, for the Studio-only debug action. The same spawn the roll
-- makes, refused for the same reasons.
function NestService.SpawnSecret(biomeId: string, why: string?): (boolean, string?)
	for _, nest in ipairs(nests) do
		if nest.biome.Id == biomeId then
			return spawnSecret(nest, why or "asked for")
		end
	end
	return false, "no nest in " .. tostring(biomeId)
end

-- CarryService says the pod left the road: banked into a Tool, or forfeited.
function NestService.SecretResolved(secretId: string, why: string?): boolean
	for _, nest in ipairs(nests) do
		local secret = nest.secret
		if secret and secret.id == secretId then
			resolveSecret(nest, why or "resolved")
			return true
		end
	end
	return false
end

-- What is standing where, for a Studio probe and the spec: nil when no secret.
function NestService.SecretState(biomeId: string): { id: string, onSpot: boolean, marked: number, platform: boolean }?
	for _, nest in ipairs(nests) do
		if nest.biome.Id == biomeId then
			local secret = nest.secret
			if not secret then
				return nil
			end
			local marked = 0
			for _ in pairs(nest.marked) do
				marked += 1
			end
			return { id = secret.id, onSpot = secret.pod ~= nil and secret.pod.Parent ~= nil, marked = marked,
				platform = secret.platform ~= nil and secret.platform.Parent ~= nil }
		end
	end
	return nil
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
--==============================================================================
-- WHO IS BEING CHASED, ON THE PLAYER
--
-- Counted after every nest has stepped, so the number is this tick's truth and
-- not a guardian's state from before its own step changed it. See
-- GameConfig.Attributes.PursuedBy for why it is a count on the player and not a
-- target on each guardian.
--
-- CHASING AND NOT BUSY. A busy nest is mid-throw: the catch has happened, and
-- the chase bed ending on the catch is the point. Waking is the head start --
-- the roar and the alarm own that second -- and hauling or walking home is a
-- guardian that has stopped being after anybody.
--
-- Written only on a change, like ParentState: most ticks write nothing.
--
-- AND WHO IS ABOUT TO BE (2026-09-27): WakingBy counts the guardians still in
-- their wake delay with this player as the target -- the head start AlertUI
-- calls "WAKING -- RUN!". Same rules, same tick, and the theft itself publishes
-- too (see provoke), so the warning starts with the delay rather than a tick
-- into it. A guardian leaves this count the same tick it joins PursuedBy.
--==============================================================================
publishPursuit = function()
	local chasing: { [Player]: number } = {}
	local waking: { [Player]: number } = {}
	for _, nest in ipairs(nests) do
		local target = nest.target
		if target and not nest.busy then
			if nest.state == "chasing" then
				chasing[target] = (chasing[target] or 0) + 1
			elseif nest.state == "waking" then
				waking[target] = (waking[target] or 0) + 1
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local count = chasing[player]
		if player:GetAttribute(GameConfig.Attributes.PursuedBy) ~= count then
			player:SetAttribute(GameConfig.Attributes.PursuedBy, count)
		end
		local wakes = waking[player]
		if player:GetAttribute(GameConfig.Attributes.WakingBy) ~= wakes then
			player:SetAttribute(GameConfig.Attributes.WakingBy, wakes)
		end
	end
end

function NestService.Init()
	running = false
	-- Nobody is chased by a nest table that is about to be emptied.
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute(GameConfig.Attributes.PursuedBy, nil)
		player:SetAttribute(GameConfig.Attributes.WakingBy, nil)
	end
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	-- The answer handler went with those connections; the next resolve connects
	-- a fresh one.
	throwRemote = nil
	throwRemoteConnected = false
	-- Rule 10. Sweep samples belong to a chase that no longer exists -- they
	-- live on the nests, and the nests go here.
	for _, nest in ipairs(nests) do
		if nest.folder.Parent then
			nest.folder:Destroy()
		end
	end
	table.clear(nests)
end

function NestService.Start()
	-- A player who leaves is nobody's sample and nobody's remembered thief. The
	-- chase itself ends on the next tick, when targetPosition finds them gone.
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		for _, nest in ipairs(nests) do
			nest.thieves[player] = nil
			nest.marked[player] = nil
			local sample = nest.sample
			if sample and sample.target == player then
				nest.sample = nil
			end
		end
	end))

	--==========================================================================
	-- THE VICTIM'S ANSWER
	--
	-- Rule 4: the sender is engine-stamped and cannot be forged, but everything
	-- else off the wire is a lie until checked. The one argument is the throw's
	-- token (acceptThrowAnswer): an answer ends only the throw it names, so a
	-- stale one, a duplicate or a bat's is ignored, and so is a client shouting
	-- it at any other time.
	--
	-- The worst a victim can do by lying is end their own ragdoll early, which
	-- is a punishment they are shortening for themselves; the timeout still
	-- bounds it either way.
	--
	-- resolveThrowRemote connects the handler, once. This used to connect a
	-- second copy of it here as well.
	--==========================================================================
	if not resolveThrowRemote() then
		warn("[Seed/NestService] No ThrowVictim remote. Throws will run to their timeout.")
	end

	local byId: { [string]: BiomeData.Biome } = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		byId[biome.Id] = biome
	end

	--==========================================================================
	-- WHICH BIOMES ACTUALLY RAISE A NEST
	--
	-- Two conditions, and they answer different questions.
	--
	-- NO SPECIES, NO NESTS. SeedData was deliberately Greenhollow-only until
	-- each biome had its own art, so the other four would otherwise raise nine
	-- parents -- roughly 800 parts of monster -- to stand guard over nothing at
	-- all. That test is automatic: art arrives, the biome wakes up.
	--
	-- AND THAT IS EXACTLY WHY THE FLAG HAS TO BE HERE TOO. Automatic is the
	-- wrong behaviour for a biome whose art has landed but is not FINISHED --
	-- adding five species rows silently opened Starbloom, because species
	-- presence was the only gate in the game. `LiveInPhaseA` was supposed to be
	-- the other one and was not read by anything: MapService wrote it to a
	-- `Live` attribute that no script has ever looked at. It is read here now,
	-- so the flag in BiomeData means what it says and a biome goes live when
	-- somebody decides it does.
	--
	-- ONLY THE NESTS. The segment, the road, the walls and the gate arch are
	-- built regardless -- you can still walk the whole corridor and look at
	-- where the game is going. What a not-yet-live biome has is no pods to steal
	-- and no parent standing over them.
	--
	-- Skipped and counted, never skipped silently: an empty biome is a thing
	-- somebody should notice, not discover.
	--==========================================================================
	local skipped: { [string]: number } = {}
	local held: { [string]: number } = {}

	for _, site in ipairs(CollectionService:GetTagged(GameConfig.Tags.NestSite)) do
		if site:IsA("BasePart") and site:IsDescendantOf(Workspace) then
			local biome = byId[site:GetAttribute(GameConfig.Attributes.BiomeId) or ""]
			if biome and #SeedData.InBiome(biome.Id) == 0 then
				skipped[biome.Id] = (skipped[biome.Id] or 0) + 1
				biome = nil
			elseif biome and biome.LiveInPhaseA ~= true then
				held[biome.Id] = (held[biome.Id] or 0) + 1
				biome = nil
			end
			if biome then
				local nest = buildNest(site, biome)
				if nest then
					table.insert(nests, nest)
				end
			end
		end
	end

	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			local now = os.clock()
			for _, nest in ipairs(nests) do
				local ok, err = pcall(step, nest, now)
				if not ok then
					warn("[Seed/NestService] " .. nest.id .. ": " .. tostring(err))
				end
			end
			local ok, err = pcall(publishPursuit)
			if not ok then
				warn("[Seed/NestService] pursuit: " .. tostring(err))
			end
		end
	end)

	local pods = 0
	for _, nest in ipairs(nests) do
		for _ in pairs(nest.pods) do
			pods += 1
		end
	end
	--==========================================================================
	-- REPORT WHAT THEY ACTUALLY RUN AT
	--
	-- This line used to print parentWalkSpeedFor(0) -- the formula's answer for a
	-- biome that recommends nothing -- and call it "parents run at N". Once
	-- Greenhollow started stating its own chase speed that became a boot message
	-- confidently reporting a number no guardian in the game was using.
	--==========================================================================
	local slowest, fastest = math.huge, 0
	for _, nest in ipairs(nests) do
		local base = baseSpeedFor(nest)
		slowest = math.min(slowest, base)
		fastest = math.max(fastest, base)
	end
	if slowest > fastest then
		slowest, fastest = GameConfig.parentWalkSpeedFor(0), GameConfig.parentWalkSpeedFor(0)
	end
	log(string.format(
		"Ready. %d nest(s), %d pod(s). Parents sleep until robbed, then run at %s (+%d per theft).",
		#nests, pods,
		(if math.abs(fastest - slowest) < 0.05
			then string.format("%d", slowest)
			else string.format("%d-%d by biome", slowest, fastest)),
		P.RageSpeedPerTake))

	local quiet = {}
	for id, n in pairs(skipped) do
		table.insert(quiet, string.format("%s (%d)", id, n))
	end
	if #quiet > 0 then
		table.sort(quiet)
		log("No species yet, so no nests built in: " .. table.concat(quiet, ", ")
			.. ". Those biomes are geometry until they have art.")
	end

	local waiting = {}
	for id, n in pairs(held) do
		table.insert(waiting, string.format("%s (%d)", id, n))
	end
	if #waiting > 0 then
		table.sort(waiting)
		log("Has art but is not live yet, so no nests built in: "
			.. table.concat(waiting, ", ")
			.. ". Flip LiveInPhaseA in BiomeData to open it.")
	end
end

-- For the console, and for CarryService to find what is near a player.
--==============================================================================
-- PROVOKING WITHOUT TAKING
--
-- For a pod that is already out of the nest: dropped on the ground and picked
-- up again. There is no slot to clear and nothing to destroy, only a parent to
-- annoy.
--==============================================================================
-- Not a theft from the nest: a dropped pod picked back up (CarryService) or a
-- Studio test poke (DebugService). It wakes and angers the guardian exactly as
-- before, and never grants a below-recommendation head start.
function NestService.Provoke(nestId: string, thief: Player, secretId: string?): boolean
	for _, nest in ipairs(nests) do
		if nest.id == nestId then
			-- A dropped secret picked back up marks the thief as the take did.
			provoke(nest, thief, false, secretId)
			return true
		end
	end
	return false
end

--==============================================================================
-- HOW MANY PODS ARE STANDING, AND HOW MANY SHOULD BE
--
-- Counted from the models rather than from the table, because the question being
-- asked is "what is in the world", and a table that disagreed with the world is
-- exactly the bug this would be used to find.
--==============================================================================
function NestService.PodCount(): (number, number)
	local live, capacity = 0, 0
	for _, nest in ipairs(nests) do
		-- The road's: a weather event's nest is counted by EventNest.
		if nest.event ~= nil then
			continue
		end
		capacity += nest.biome.PodsPerNest
		for _, pod in pairs(nest.pods) do
			if pod and pod.Parent then
				live += 1
			end
		end
	end
	return live, capacity
end

function NestService.NestCount(): number
	local count = 0
	for _, nest in ipairs(nests) do
		if nest.event == nil then
			count += 1
		end
	end
	return count
end

--==============================================================================
-- THE RAIN EVENT'S NEST (2026-10-02)
--
-- Raised by WeatherService when a weather event starts, at the temporary
-- biome's nest, and taken down when it ends. It IS a nest -- the same record,
-- the same tick, provoke, thief queue, contact sweep, throw and walk home -- so
-- its guardian (Stormstrider, StormstriderModel through ParentModel) is the
-- existing guardian system and not a second one. What differs is data:
--
--   biome    a stand-in "rain" biome carrying STARBLOOM'S recommendation (the
--            owner's "equivalent Starbloom conditions": the same shortfall and
--            the same no-head-start-below-it rule) and no Confiscate profile,
--            so a catch throws and the pod drops by the ordinary loose-pod path
--            for anybody to take; no secret.
--   pods     ONE batch, rolled here on the server (SeedData.RollRainBatch,
--            with this server's Random: for the rain three slots and ONE
--            Colossal draw, 5% a Rain since 2026-10-06 -- a hit makes one
--            slot, at random, Colossal (SeedData.RainBatches) -- one Pod 3 for
--            a thunderstorm; each pod's creature drawn when it is laid).
--            Stamped with the event's id. Never restocked
--            (StockAll), cleared at dusk (ClearForNight) or reset (ResetParents).
--   layout   the pods on the grown nest platform (GameConfig.Weather.EventNest:
--            a ring of PodRing studs, or its centre for one); the guardian
--            asleep beside it, across the way in.
--   home     its sleeping spot, walked to along the biome's own rooms (route);
--            a body thrown out of the world is set down at the biome's
--            entrance (setDown).
--==============================================================================
export type EventSite = {
	-- The nest's centre at the height its pods stand on (the platform's top).
	centre: Vector3,
	-- The floor the guardian sleeps on.
	floorY: number,
	-- The walk home through the biome: room centres, entrance first. The
	-- guardian's own spot is added last here.
	route: { Vector3 },
	setDown: Vector3,
	parent: Instance,
}

local EVENT_NEST_NAME = "Nest_rain_event"

-- Each event's special eggs still to be announced (laid by OpenEventNest, told
-- once by AnnounceEventEgg, forgotten by CloseEventNest).
local eventEggs: { [number]: number } = {}

-- How many of these laid pods are a weather egg the Secret toast names. Pure.
function NestService.WeatherEggCount(podIds: { string }): number
	local special: { [string]: boolean } = (GameConfig.Secret.Toast.WeatherEggs :: any) or {}
	local n = 0
	for _, id in ipairs(podIds) do
		if special[id] then
			n += 1
		end
	end
	return n
end

-- At the event's opening (WeatherService): announces its special egg, once.
-- Answers whether it announced. Nothing laid, nothing special, or said
-- already: nothing.
function NestService.AnnounceEventEgg(eventId: number): boolean
	local n = eventEggs[eventId]
	if not n or n <= 0 then
		return false
	end
	eventEggs[eventId] = nil
	announceSecretEgg("event:" .. tostring(eventId), GameConfig.Weather.Biome.Id, eventId)
	log(string.format("The event's special egg is announced (event %d).", eventId))
	return true
end

local function eventBiome(pods: number): BiomeData.Biome
	local starbloom = BiomeData.ById.starbloom
	return {
		Id = GameConfig.Weather.Biome.Id,
		DisplayName = GameConfig.Weather.Biome.Label,
		Mood = "",
		Order = if starbloom then starbloom.Order + 1 else #BiomeData.Biomes + 1,
		RecommendedSpeed = if starbloom then starbloom.RecommendedSpeed else 0,
		GroundColor = GameConfig.Weather.Biome.Colours.Floor,
		WallColor = GameConfig.Weather.Biome.Colours.Wall,
		AccentColor = GameConfig.Weather.Biome.Colours.Accent,
		Brightness = 1,
		Nests = 1,
		PodsPerNest = pods,
		RarityBonus = 1,
		LiveInPhaseA = true,
	} :: any
end

-- The batch for `mode` ("rain" or "thunder"), laid and guarded. Answers how
-- many pods were laid, or 0 and why not. Refused while an event nest stands.
function NestService.OpenEventNest(eventId: number, mode: string, site: EventSite): (number, string?)
	for _, nest in ipairs(nests) do
		if nest.event ~= nil then
			return 0, "an event nest is already standing"
		end
	end
	if not SeedData.RainBatches[mode] then
		return 0, "no batch for the weather " .. tostring(mode)
	end
	local cfg = GameConfig.Weather.EventNest
	local batch = SeedData.RollRainBatch(mode, Random.new())
	local bearing = math.rad(cfg.Guard.Bearing)
	local outward = Vector3.new(math.cos(bearing), 0, math.sin(bearing))
	local across = Vector3.new(-outward.Z, 0, outward.X)
	local home = Vector3.new(site.centre.X, site.floorY, site.centre.Z) + outward * cfg.Guard.Distance

	local folder = Instance.new("Folder")
	folder.Name = EVENT_NEST_NAME
	folder.Parent = site.parent
	-- Kept on the nest: a lost Stormstrider is rebuilt from exactly this, while its weather stands.
	local buildAt = CFrame.lookAt(home, home + across)
	local parentModel = ParentModel.Build(buildAt, PARENT_HEIGHT, "rain", folder)
	local humanoid = parentModel:FindFirstChildOfClass("Humanoid")
	local root = parentModel.PrimaryPart
	if not (humanoid and root) then
		folder:Destroy()
		return 0, "the guardian did not build"
	end

	-- The pods: a lone pod at the centre facing the way in, a batch round the
	-- ring with one behind the centre and two either side, each facing out.
	local slots: { CFrame } = {}
	local count = #batch
	for i = 1, count do
		local at, face
		if count == 1 then
			at, face = site.centre, outward
		else
			local a = bearing + math.pi + (i - 1) / count * 2 * math.pi
			face = Vector3.new(math.cos(a), 0, math.sin(a))
			at = site.centre + face * cfg.PodRing
		end
		slots[i] = CFrame.lookAt(at, at + face)
	end

	local route = table.clone(site.route)
	table.insert(route, home)
	local nest: Nest = {
		id = folder.Name,
		biome = eventBiome(count),
		origin = home,
		homeCFrame = root.CFrame,
		parent = parentModel,
		humanoid = humanoid,
		root = root,
		folder = folder,
		slots = slots,
		pods = {},
		state = "asleep",
		chaseSince = 0,
		target = nil,
		stateUntil = 0,
		busy = false,
		rage = 0,
		calmSince = 0,
		haul = nil,
		sample = nil,
		thieves = {},
		secret = nil,
		marked = {},
		event = eventId,
		route = route,
		setDown = site.setDown,
		buildAt = buildAt,
		rigId = "rain",
		lastSeen = root.Position,
	}
	local laid = {}
	for i, roll in ipairs(batch) do
		placePod(nest, i, roll.species, roll.tier)
		local pod = nest.pods[i]
		if pod then
			pod:SetAttribute("EventId", eventId)
			pod:SetAttribute("RainPod", roll.pod)
			table.insert(laid, roll.pod)
		end
	end
	pinToServer(nest)
	table.insert(nests, nest)
	eventEggs[eventId] = NestService.WeatherEggCount(laid)
	log(string.format("The %s event's nest is up (event %d): %d pod(s) [%s], guarded by %s.", mode, eventId,
		#laid, table.concat(laid, ", "), tostring(parentModel:GetAttribute("Species"))))
	return #laid, nil
end

-- Down with its event: the unclaimed pods still in the nest and the guardian
-- go; a pod in somebody's arms is theirs to bank. `eventId` nil takes any.
-- Answers how many pods went.
function NestService.CloseEventNest(eventId: number?): number
	local removed = 0
	-- An egg not yet announced is never announced once its event is down.
	if eventId == nil then
		table.clear(eventEggs)
	else
		eventEggs[eventId] = nil
	end
	for i = #nests, 1, -1 do
		local nest = nests[i]
		if nest.event ~= nil and (eventId == nil or nest.event == eventId) then
			for slot, pod in pairs(nest.pods) do
				if pod and pod.Parent then
					pod:Destroy()
					removed += 1
				end
				nest.pods[slot] = nil
			end
			if nest.haul then
				detachHaul(nest)
				nest.haul = nil
			end
			nest.target = nil
			nest.sample = nil
			table.clear(nest.thieves)
			table.clear(nest.marked)
			if nest.folder.Parent then
				nest.folder:Destroy()
			end
			table.remove(nests, i)
			log(string.format("The event nest (event %s) is down: %d unclaimed pod(s) and its guardian went with it.",
				tostring(nest.event), removed))
		end
	end
	pcall(publishPursuit)
	return removed
end

-- What the event nest holds, for the spec and a Studio probe; nil without one.
function NestService.EventNest(): { id: string, event: number, state: string, rage: number, target: Player?,
	thieves: number, origin: Vector3, pods: { { species: string, pod: string?, tier: number, model: Model } } }?
	for _, nest in ipairs(nests) do
		if nest.event ~= nil then
			local pods = {}
			for _, pod in pairs(nest.pods) do
				if pod and pod.Parent then
					table.insert(pods, {
						species = tostring(pod:GetAttribute("SpeciesId")),
						pod = pod:GetAttribute("RainPod") :: string?,
						tier = tonumber(pod:GetAttribute("Tier")) or 0,
						model = pod,
					})
				end
			end
			local thieves = 0
			for _ in pairs(nest.thieves) do
				thieves += 1
			end
			return { id = nest.id, event = nest.event :: number, state = nest.state, rage = nest.rage,
				target = nest.target, thieves = thieves, origin = nest.origin, pods = pods }
		end
	end
	return nil
end

function NestService.Snapshot(): string
	local rows = {}
	for _, nest in ipairs(nests) do
		local live = 0
		for _ in pairs(nest.pods) do
			live += 1
		end
		table.insert(rows, string.format("%s %s %d/%d pods",
			nest.id, nest.state, live, nest.biome.PodsPerNest))
	end
	return table.concat(rows, " | ")
end

return NestService
