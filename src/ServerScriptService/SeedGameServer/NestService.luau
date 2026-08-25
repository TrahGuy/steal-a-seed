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
local ParentModel = require(script.Parent:WaitForChild("ParentModel"))
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
	parent: Model,
	humanoid: Humanoid,
	root: BasePart,
	folder: Folder,
	-- Pod slot -> the pod model standing in it, or nil while it regrows.
	slots: { CFrame },
	pods: { [number]: Model? },
	regrowAt: { [number]: number },
	state: string,
	target: Player?,
	stateUntil: number,
	busy: boolean,
	-- How many times it has been robbed recently. Each one adds speed.
	rage: number,
	-- When it last settled. Rage fades this long after, rather than the instant
	-- it lies down -- see GameConfig.Parent.RageForgetSeconds.
	calmSince: number,
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
-- How long a taken pod stays gone. Long enough that clearing a nest means
-- something, short enough that a player coming back finds it alive.
local REGROW_SECONDS = 22

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
	local kg = SeedData.RollKg(rng)
	local pod = CreatureModel.BuildPod(species, kg, nest.slots[index], nest.folder)
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
	nest.regrowAt[index] = 0
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
		parent = parentModel,
		humanoid = humanoid,
		root = root,
		folder = folder,
		slots = podCFrames(centre, biome.PodsPerNest, outward),
		pods = {},
		regrowAt = {},
		state = "asleep",
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
-- Base speed for the biome, plus whatever it is currently furious about.
local function speedFor(nest: Nest): number
	return GameConfig.parentWalkSpeedFor(nest.biome.Order)
		+ math.min(nest.rage, P.MaxRageStacks) * P.RageSpeedPerTake
end

local function provoke(nest: Nest, thief: Player)
	-- EVERY theft stacks, including picking a dropped pod back up. Losing a pod
	-- and strolling back for it is the obvious way to farm a nest safely, so the
	-- second attempt has to be harder than the first.
	nest.rage += 1
	-- WAKE, ON A DELAY. The delay is the head start, and it is the whole skill
	-- of a raid.
	if nest.state == "asleep" then
		nest.state = "waking"
		nest.stateUntil = os.clock() + P.WakeDelaySeconds
	elseif nest.state == "returning" then
		-- Already up and walking home. No second delay -- it never went back to
		-- sleep, so it has nothing to wake up from.
		nest.state = "chasing"
	end
	-- Always re-target: stealing from a parent already chasing somebody else
	-- should make it chase YOU, or two players could take turns feeding it a
	-- decoy.
	nest.target = thief
	if nest.state == "chasing" then
		-- Already running. Speed up mid-chase rather than waiting for the next
		-- state change, which might never come.
		nest.humanoid.WalkSpeed = speedFor(nest)
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
			nest.pods[slot] = nil
			nest.regrowAt[slot] = os.clock() + REGROW_SECONDS
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
local function resolveThrowRemote()
	local remotes = ReplicatedStorage:FindFirstChild("SeedGame")
	remotes = remotes and remotes:FindFirstChild("Remotes")
	local found = remotes and remotes:FindFirstChild(GameConfig.Remotes.ThrowVictim)
	if found and found:IsA("RemoteEvent") then
		throwRemote = found
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
	--==========================================================================
	local R = GameConfig.parentThrowStudsFor(nest.biome.Order)
	local k = P.ThrowLift
	local g = Workspace.Gravity
	local speed = math.sqrt(R * g / (2 * k))

	-- OUT, toward the safe zone. Home is +Z. The lateral term only nudges them
	-- off the wall they were probably hugging, so they land on the road rather
	-- than inside it.
	local lateral = (root.Position.X - nest.root.Position.X)
	local dir = Vector3.new(lateral * 0.02, 0, 1)
	if dir.Magnitude > 0 then
		dir = dir.Unit
	else
		dir = Vector3.new(0, 0, 1)
	end
	--==========================================================================
	-- THE STEP OUT OF THE PARENT IS THE CLIENT'S JOB, NOT THIS ONE'S
	--
	-- It used to happen here, as `root.CFrame = root.CFrame + dir * CLEAR_STUDS`.
	-- That is a server CFrame write on a body the owning client is simulating --
	-- the exact class of thing this rewrite exists to remove, and it fought the
	-- owner rather than moving them. The distance is sent along with the shove
	-- and the client applies it to a root it actually owns.
	--==========================================================================
	loosened = ragdollOn(character)

	--==========================================================================
	-- THE OWNER THROWS IT. THE SERVER JUST ASKS.
	--
	-- Writing AssemblyLinearVelocity here would be overwritten by the owning
	-- client's next physics update, which is the bug this whole rewrite exists
	-- to undo. The victim's client applies the impulse to a body it already
	-- owns, and its physics replicate outward on their own.
	--==========================================================================
	throwDone[player] = false
	local sent = false
	if throwRemote then
		sent = pcall(function()
			(throwRemote :: RemoteEvent):FireClient(player, dir, speed, P.ThrowLift,
				CLEAR_STUDS)
		end)
	end
	if not sent then
		warn("[Seed/NestService] no ThrowVictim remote; the hit will look like a shove that never landed.")
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
	nest.target = nil
	-- Rage is NOT cleared here. It fades on a timer instead, because a parent
	-- settles within a couple of seconds of throwing somebody while the pod it
	-- was defending is still lying on the ground -- clearing on sleep made
	-- coming back for that pod free, which is the exact case this exists for.
	nest.calmSince = os.clock()
	nest.humanoid.WalkSpeed = 0
	nest.parent:SetAttribute("Asleep", true)
end

local function step(nest: Nest, now: number)
	--== RAGE FADES ==--
	if nest.rage > 0 and nest.state == "asleep" and nest.calmSince > 0
		and now - nest.calmSince >= P.RageForgetSeconds then
		nest.rage = 0
		nest.calmSince = 0
	end

	--== REGROWTH ==--
	for slot, at in pairs(nest.regrowAt) do
		if at > 0 and now >= at and not nest.pods[slot] then
			growPod(nest, slot)
		end
	end

	if nest.busy then
		return
	end

	if nest.state == "asleep" then
		return

	elseif nest.state == "waking" then
		if now >= nest.stateUntil then
			nest.state = "chasing"
			nest.humanoid.WalkSpeed = speedFor(nest)
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
		if (nest.root.Position - nest.origin).Magnitude > P.LeashStuds then
			nest.state = "returning"
			nest.target = nil
			return
		end
		local flat = Vector3.new(pos.X - nest.root.Position.X, 0, pos.Z - nest.root.Position.Z)
		-- CONTACT. Not a grab -- there is no hold any more, reaching the player
		-- is the hit.
		if flat.Magnitude <= P.GrabStuds then
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
		nest.humanoid:MoveTo(pos)
		return

	else -- returning
		local home = Vector3.new(nest.origin.X, nest.root.Position.Y, nest.origin.Z)
		if (nest.root.Position - home).Magnitude < 6 then
			sleep(nest)
			return
		end
		nest.humanoid:MoveTo(home)
	end
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
	for _, nest in ipairs(nests) do
		if nest.folder.Parent then
			nest.folder:Destroy()
		end
	end
	table.clear(nests)
end

function NestService.Start()
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

	-- A BIOME WITH NO SPECIES GETS NO NESTS. SeedData is deliberately
	-- Greenhollow-only until each biome has its own art, so the other four would
	-- otherwise raise nine parents -- roughly 800 parts of monster -- to stand
	-- guard over nothing at all. Skipped and counted, never skipped silently:
	-- an empty biome is a thing somebody should notice, not discover.
	local skipped: { [string]: number } = {}

	for _, site in ipairs(CollectionService:GetTagged(GameConfig.Tags.NestSite)) do
		if site:IsA("BasePart") and site:IsDescendantOf(Workspace) then
			local biome = byId[site:GetAttribute(GameConfig.Attributes.BiomeId) or ""]
			if biome and #SeedData.InBiome(biome.Id) == 0 then
				skipped[biome.Id] = (skipped[biome.Id] or 0) + 1
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
		#nests, pods, GameConfig.parentWalkSpeedFor(1), P.RageSpeedPerTake))

	local quiet = {}
	for id, n in pairs(skipped) do
		table.insert(quiet, string.format("%s (%d)", id, n))
	end
	if #quiet > 0 then
		table.sort(quiet)
		log("No species yet, so no nests built in: " .. table.concat(quiet, ", ")
			.. ". Those biomes are geometry until they have art.")
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
