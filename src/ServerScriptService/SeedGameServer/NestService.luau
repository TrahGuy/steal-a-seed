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
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local ParentModel = require(script.Parent:WaitForChild("ParentModel"))
-- No cycle: PlayerDataService requires GameConfig, SaveService, ProfileSchema
-- and BiomeData, and none of those has ever heard of a nest.
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
-- No cycle: MapService knows nothing about nests, it only leaves the markers.
local MapService = require(script.Parent:WaitForChild("MapService"))

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
	--==========================================================================
	slots: { CFrame },
	pods: { [number]: Model? },
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
}

local nests: { Nest } = {}
local serviceConnections: { RBXScriptConnection } = {}
local running = false

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

local function buildNest(site: BasePart, biome: BiomeData.Biome): Nest?
	local index = site:GetAttribute("NestIndex")
	local folder = Instance.new("Folder")
	folder.Name = string.format("Nest_%s_%02d", biome.Id, index or 0)
	folder.Parent = site.Parent

	local centre = site.Position
	-- Facing the middle of the road: a nest against the left wall should have
	-- its parent looking out at traffic, not at the wall.
	local outward = if centre.X < 0 then math.pi * 0.5 else -math.pi * 0.5
	local parentModel = ParentModel.Build(
		CFrame.new(centre) * CFrame.Angles(0, outward, 0),
		PARENT_HEIGHT, biome.Id, folder)
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
	}
	for i = 1, biome.PodsPerNest do
		growPod(nest, i)
	end
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
local function speedFor(nest: Nest): number
	return GameConfig.parentWalkSpeedFor(
			nest.biome.RecommendedSpeed,
			speedScoreOf(nest.target)
		)
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
local function chaseSpeedFor(nest: Nest, now: number): number
	local prof = profileOf(nest)
	if not prof then
		return speedFor(nest)
	end
	local rage = math.min(nest.rage, P.MaxRageStacks) * P.RageSpeedPerTake
	local rec = nest.biome.RecommendedSpeed
	local shortfall = GameConfig.parentWalkSpeedFor(rec, speedScoreOf(nest.target))
		- GameConfig.parentWalkSpeedFor(rec)
	local since = if nest.chaseSince > 0 then now - nest.chaseSince else 0
	local u = math.clamp(since / math.max(prof.RampSeconds, 0.01), 0, 1)
	return prof.OpeningSpeed + (prof.TopSpeed - prof.OpeningSpeed) * u * u
		+ rage + shortfall
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
--==============================================================================
local function qualifiesForHeadStart(nest: Nest, thief: Player): boolean
	local recommended = nest.biome.RecommendedSpeed
	if type(recommended) ~= "number" or recommended ~= recommended or recommended <= 0 then
		return true
	end
	local score = speedScoreOf(thief)
	if score == nil or score ~= score then
		return true
	end
	return score >= recommended
end

local function provoke(nest: Nest, thief: Player)
	-- EVERY theft stacks, including picking a dropped pod back up. Losing a pod
	-- and strolling back for it is the obvious way to farm a nest safely, so the
	-- second attempt has to be harder than the first.
	nest.rage += 1
	-- WAKE, ON A DELAY. The delay is the head start, and it is the whole skill
	-- of a raid.
	if nest.state == "asleep" then
		if qualifiesForHeadStart(nest, thief) then
			nest.state = "waking"
			nest.stateUntil = os.clock() + P.WakeDelaySeconds
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
			nest.stateUntil = 0
			nest.parent:SetAttribute("Asleep", false)
		end
	elseif nest.state == "returning" then
		-- Already up and walking home. No second delay -- it never went back to
		-- sleep, so it has nothing to wake up from.
		nest.state = "chasing"
		nest.chaseSince = os.clock()
	end
	-- Always re-target: stealing from a parent already chasing somebody else
	-- should make it chase YOU, or two players could take turns feeding it a
	-- decoy.
	nest.target = thief
	if nest.state == "chasing" then
		-- Already running. Speed up mid-chase rather than waiting for the next
		-- state change, which might never come.
		setWalk(nest, chaseSpeedFor(nest, os.clock()))
	end
end

--==============================================================================
-- TAKING A POD
--
-- The seam CarryService calls. Returns the species so the caller knows what it
-- is now holding, and nil if the pod was already gone -- two players reaching
-- the same pod in the same frame is a race this has to lose gracefully rather
-- than hand out two prizes.
--==============================================================================
function NestService.TakePod(pod: Model, thief: Player): SeedData.Species?
	local nestId = pod:GetAttribute("NestId")
	local slot = pod:GetAttribute("SlotIndex")
	local speciesId = pod:GetAttribute("SpeciesId")
	if type(nestId) ~= "string" or type(slot) ~= "number" or type(speciesId) ~= "string" then
		return nil
	end

	for _, nest in ipairs(nests) do
		if nest.id == nestId then
			if nest.pods[slot] ~= pod then
				-- Somebody else already took it this frame.
				return nil
			end
			-- Empty for the rest of the day. Nothing schedules it back.
			nest.pods[slot] = nil
			pod:Destroy()
			provoke(nest, thief)
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
}

local function ragdollOn(character: Model): Loosened
	local out: Loosened = { constraints = {}, motors = {}, collides = {} }
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

	return out
end

local function ragdollOff(loosened: Loosened)
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
end

-- The backstop. The victim's client reports when it has stopped; this is what
-- happens when it never does -- a body wedged in geometry, a client that left,
-- a client that simply does not answer. A character must always come back.
local THROW_TIMEOUT = 6
-- How far out of the parent to move the victim before their limbs start
-- colliding. Contact happens INSIDE a collidable torso, and switching a body
-- to collidable while it overlaps another one either wedges it there or has
-- the solver fling it. Cheaper to step out of the way first.
local CLEAR_STUDS = 5

-- Victims currently mid-throw, and the flag their client sets by answering.
local throwDone: { [Player]: boolean } = {}

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
			table.insert(serviceConnections, found.OnServerEvent:Connect(function(player)
				if throwDone[player] == false then
					throwDone[player] = true
				end
			end))
		end
		return found
	end
	return nil
end

local function throwPlayer(nest: Nest, player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) then
		return
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
			return
		end
		if MapService.IsInSafeZone(root.Position) then
			return
		end
		if (root.Position - nest.root.Position).Magnitude > P.GrabStuds * 4 then
			-- They got out of reach during the wind-up. The swing misses.
			return
		end
	end

	SoundKit.emit("Grab", nest.root)

	humanoid.PlatformStand = true
	task.wait()

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
			humanoid.WalkSpeed = walk
			humanoid.JumpPower = jump
		end
	end

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

	local roadOut = Vector3.new(0, 0, 1)
	if prof then
		local hub = MapService.GetOverflowCFrame().Position - nest.origin
		local flatHub = Vector3.new(hub.X, 0, hub.Z)
		if flatHub.Magnitude > 1 then
			roadOut = flatHub.Unit
		end
	end
	local aw = if prof then (tonumber(prof.AwayWeight) or 1) else 0.7
	local rw = if prof then (tonumber(prof.RoadWeight) or 0) else 0.5
	local dir = awayDir * aw + roadOut * rw
	if dir.Magnitude < 0.1 then
		dir = awayDir
	else
		dir = dir.Unit
	end
	if dir:Dot(awayDir) <= 0 then
		-- Cannot happen with the weights above; it would mean a launch back
		-- through the creature that threw it, and that is worth a line in the
		-- log rather than a shrug.
		warn(string.format(
			"[Seed/NestService] %s throw resolved back toward the parent; using away only",
			tostring(nest.parent:GetAttribute("Species"))))
		dir = awayDir
	end

	loosened = ragdollOn(character)
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
			rem:FireClient(player, dir, speed, k, CLEAR_STUDS,
				if prof then 0 else nil)
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
	while os.clock() < deadline do
		if throwDone[player] then
			break
		end
		if player.Parent ~= Players or not root.Parent or humanoid.Health <= 0 then
			break
		end
		task.wait(0.1)
	end
	throwDone[player] = nil

	end)

	restore()
	if not ok then
		warn("[Seed/NestService] throw failed after the grab: " .. tostring(err))
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
-- eight times the cost. It is to stop testing a POINT and test the SEGMENT the
-- player actually travelled: closest approach between the parent and the line
-- from where the player was to where they are now. Exact at any speed, and it is
-- one dot product.
--==============================================================================
local function distanceToSegment(point: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		-- Standing still: the segment is a point and this is the old test.
		return (point - a).Magnitude
	end
	local t = math.clamp((point - a):Dot(ab) / len2, 0, 1)
	return (point - (a + ab * t)).Magnitude
end

-- Where each chased player was at the previous tick. Keyed by player rather than
-- by nest: a player can only be chased by one parent at a time, and this is
-- cleared the moment they stop being a target.
local lastTargetAt: { [Player]: Vector3 } = {}
-- 150 WalkSpeed x 0.12s is 18 studs; double it so an ordinary hitch is still
-- treated as travel and only a discontinuity is thrown away.
local MAX_TICK_TRAVEL = 40

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

local function sleep(nest: Nest)
	nest.state = "asleep"
	if nest.target then
		lastTargetAt[nest.target] = nil
	end
	nest.target = nil
	-- Rage is NOT cleared here. It fades on a timer instead, because a parent
	-- settles within a couple of seconds of throwing somebody while the pod it
	-- was defending is still lying on the ground -- clearing on sleep made
	-- coming back for that pod free, which is the exact case this exists for.
	nest.calmSince = os.clock()
	nest.chaseSince = 0
	nest.humanoid.WalkSpeed = 0
	nest.parent:SetAttribute("Asleep", true)
end

local function step(nest: Nest, now: number)
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

	if nest.busy then
		return
	end

	if nest.state == "asleep" then
		return

	elseif nest.state == "waking" then
		if now >= nest.stateUntil then
			nest.state = "chasing"
			nest.chaseSince = os.clock()
			setWalk(nest, chaseSpeedFor(nest, os.clock()))
			nest.parent:SetAttribute("Asleep", false)
		end
		return

	elseif nest.state == "chasing" then
		local pos = targetPosition(nest.target)
		-- Safety is safety. A parent that could be kited across the red line
		-- would make the one promise the map makes into a lie.
		if not pos or MapService.IsInSafeZone(pos) then
			nest.state = "returning"
			nest.target = nil
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
			nest.state = "returning"
			nest.target = nil
			return
		end
		-- Backstop only. See GameConfig.Parent.LeashStuds: this is two segments,
		-- so a normal cross-biome chase never reaches it and a broken one cannot
		-- run forever.
		if (nest.root.Position - nest.origin).Magnitude > P.LeashStuds then
			nest.state = "returning"
			nest.target = nil
			return
		end
		--==================================================================
		-- CONTACT. Not a grab -- there is no hold any more, reaching the
		-- player is the hit.
		--
		-- Measured against the whole path the player covered since the last
		-- tick, flattened to the ground plane so a jump does not read as
		-- distance. See distanceToSegment above for why the point test was
		-- not enough.
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

		local here = Vector3.new(pos.X, 0, pos.Z)
		local was = lastTargetAt[nest.target :: Player] or here
		--==============================================================
		-- A SEGMENT THIS LONG WAS NOT ONE TICK OF RUNNING
		--
		-- The last sample can be stale -- a chase that ended and restarted,
		-- a respawn, a throw, a gate pushing somebody back. Sweeping from
		-- there to here would be a line across half the map, and everything
		-- it passed near would count as a hit.
		--
		-- The ceiling is the furthest a capped player can cover in a tick,
		-- with room to spare. Past it the sample is discarded and this tick
		-- is the plain point test it always was.
		--==============================================================
		if (here - was).Magnitude > MAX_TICK_TRAVEL then
			was = here
		end
		lastTargetAt[nest.target :: Player] = here
		local parentFlat = Vector3.new(nest.root.Position.X, 0, nest.root.Position.Z)
		if distanceToSegment(parentFlat, was, here) <= P.GrabStuds then
			local victim = nest.target
			nest.busy = true
			task.spawn(function()
				-- pcall'd because `busy` MUST be released. An error in here kills
				-- the thread and leaves the nest busy forever -- its parent frozen
				-- mid-grab, never chasing, never sleeping, never recovering. That
				-- is not hypothetical: a bad edit left `dir` undefined, throwPlayer
				-- threw on a nil index, and the nest went catatonic with no error
				-- anywhere near the thing that stopped working.
				if victim then
					local ok, err = pcall(throwPlayer, nest, victim)
					if not ok then
						warn("[Seed/NestService] throw failed: " .. tostring(err))
						-- Never leave somebody ragdolled because the throw broke.
						local character = victim.Character
						local humanoid = character
							and character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid.PlatformStand = false
						end
					end
				end
				nest.state = "returning"
				nest.target = nil
				nest.busy = false
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
		--==============================================================
		local here3 = nest.root.Position
		local toTarget = Vector3.new(pos.X - here3.X, 0, pos.Z - here3.Z)
		local heading = toTarget
		if heading.Magnitude > 0.05 then
			heading = heading.Unit
		else
			-- Standing on top of them. The grab test above has already fired in
			-- every real case; keep facing forward rather than divide by zero.
			local look = nest.root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			heading = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, -1)
		end
		nest.humanoid:MoveTo(pos + heading * P.ChaseOvershootStuds)
		return

	else -- returning
		local home = Vector3.new(nest.origin.X, nest.root.Position.Y, nest.origin.Z)
		if (nest.root.Position - home).Magnitude < 6 then
			sleep(nest)
			return
		end
		-- Slower going home than coming. A guardian that walks back at hunting
		-- speed reads as still hunting. Profiled only: the other four have
		-- always walked home at whatever the chase left them on.
		if profileOf(nest) then
			setWalk(nest, returnSpeedFor(nest))
		end
		nest.humanoid:MoveTo(home)
	end
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
		for slot, pod in pairs(nest.pods) do
			if pod and pod.Parent then
				pod:Destroy()
				removed += 1
			end
			nest.pods[slot] = nil
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
-- jog at the wall for a minute.
--
-- Rage is cleared outright here, which is the one place that happens. It
-- normally FADES on a timer -- see GameConfig.Parent.RageForgetSeconds -- so
-- that coming back for the pod you dropped is not free. A night is long enough
-- that the fade would have finished anyway, and carrying yesterday's grudge
-- into a freshly stocked nest would punish the player who is first through the
-- gate at dawn for something that happened to somebody else.
--==============================================================================
function NestService.ResetParents(): number
	local reset = 0
	for _, nest in ipairs(nests) do
		nest.busy = false
		if nest.target then
			lastTargetAt[nest.target] = nil
		end
		nest.target = nil
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
		for index = 1, nest.biome.PodsPerNest do
			wanted += 1
			if not nest.pods[index] then
				growPod(nest, index)
			end
			if nest.pods[index] then
				built += 1
			end
		end
	end
	return built, wanted
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function NestService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	-- Rule 10. Sweep samples belong to a chase that no longer exists.
	table.clear(lastTargetAt)
	for _, nest in ipairs(nests) do
		if nest.folder.Parent then
			nest.folder:Destroy()
		end
	end
	table.clear(nests)
end

function NestService.Start()
	-- A player who leaves mid-chase would otherwise hold a Vector3 forever.
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		lastTargetAt[player] = nil
	end))

	--==========================================================================
	-- THE VICTIM'S ANSWER
	--
	-- Rule 4: the sender is engine-stamped and cannot be forged, but everything
	-- else off the wire is a lie until checked. There are no arguments to check
	-- here -- the message IS "I stopped" -- so the check is that this player is
	-- actually mid-throw. A client shouting it at any other time is ignored.
	--
	-- The worst a victim can do by lying is end their own ragdoll early, which
	-- is a punishment they are shortening for themselves; the timeout still
	-- bounds it either way.
	--==========================================================================
	local remote = resolveThrowRemote()
	if remote then
		table.insert(serviceConnections, remote.OnServerEvent:Connect(function(player)
			if throwDone[player] == false then
				throwDone[player] = true
			end
		end))
	else
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
		end
	end)

	local pods = 0
	for _, nest in ipairs(nests) do
		for _ in pairs(nest.pods) do
			pods += 1
		end
	end
	log(string.format(
		"Ready. %d nest(s), %d pod(s). Parents sleep until robbed, then run at %d (+%d per theft).",
		#nests, pods, GameConfig.parentWalkSpeedFor(0), P.RageSpeedPerTake))

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
function NestService.Provoke(nestId: string, thief: Player): boolean
	for _, nest in ipairs(nests) do
		if nest.id == nestId then
			provoke(nest, thief)
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
	return #nests
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
