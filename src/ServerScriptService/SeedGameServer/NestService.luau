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
local CreatureModel = require(script.Parent:WaitForChild("CreatureModel"))
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
local NEST_RADIUS = 13
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
	local species = SeedData.Roll(nest.biome.Id, Random.new(
		math.floor(nest.origin.X * 31 + nest.origin.Z * 17 + index * 7 + os.clock() * 1000)))
	if not species then
		return
	end
	local pod = CreatureModel.BuildPod(species, nest.slots[index], nest.folder)
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
-- AND THE SERVER HAS TO OWN THE BODY, OR NOBODY SEES ANY OF IT
--
-- A player's character is network-owned by THAT PLAYER. Their client simulates
-- it and tells the server where it went. So everything above -- the impulse,
-- the tumble, the bounce -- was being computed on the server and then quietly
-- overwritten by the owning client's version of a character that was, as far as
-- it knew, standing still.
--
-- The ragdoll was real, correct, measurable from the server, and INVISIBLE.
--
-- SetNetworkOwner(nil) takes the assembly for the duration, so the server's
-- simulation is the one that replicates -- to the victim and to everyone
-- watching. Handed back on stand-up with SetNetworkOwnershipAuto(), which
-- returns a player character to its player.
--==============================================================================
type Loosened = {
	constraints: { AnimationConstraint },
	motors: { Motor6D },
	collides: { { part: BasePart, was: boolean } },
	root: BasePart?,
}

-- Claiming the assembly. Kept separate because WHEN it happens matters: see
-- the comment at the bottom of ragdollOn.
local function claim(root: BasePart?): boolean
	if not (root and root.Parent) then
		return false
	end
	-- pcall: SetNetworkOwner throws on an anchored part or one outside
	-- Workspace, and a throw here would strand the victim mid-ragdoll.
	return (pcall(function()
		(root :: BasePart):SetNetworkOwner(nil)
	end))
end

local function ragdollOn(character: Model): Loosened
	local out: Loosened = { constraints = {}, motors = {}, collides = {}, root = nil }
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
		if d:IsA("BasePart") then
			table.insert(out.collides, { part = d, was = d.CanCollide })
			d.CanCollide = true
		end
	end

	--==========================================================================
	-- CLAIMED LAST, AND THAT ORDERING IS THE WHOLE FIX.
	--
	-- Claiming it FIRST looked right and did not work: ownership flipped to the
	-- server and was back with the player 0.05 seconds later, every time.
	--
	-- Disabling fifteen constraints and flipping sixteen CanCollide flags
	-- RE-FORMS THE ASSEMBLY, and a freshly formed assembly gets auto ownership
	-- -- which for a player's character means the player. So the claim was
	-- being made and then immediately thrown away by the next two loops.
	--
	-- Claim after the shape has finished changing. The settle loop re-asserts
	-- it as well, because anything that reshapes the assembly mid-flight would
	-- take it back the same way.
	--==========================================================================
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and claim(root) then
		out.root = root
	end
	return out
end

local function ragdollOff(loosened: Loosened)
	if loosened.root and loosened.root.Parent then
		-- Auto rather than SetNetworkOwner(player): Roblox hands a character
		-- back to its own player, and this does not need to know who that is.
		pcall(function()
			(loosened.root :: BasePart):SetNetworkOwnershipAuto()
		end)
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
end

-- How still counts as settled, and how long it has to stay that still. Short
-- enough that a body wedged against a wall is not held down for a second after
-- it stops, long enough that the top of a bounce -- where horizontal speed dips
-- through zero -- is not mistaken for the end of one.
local SETTLE_SPEED = 3.5
local SETTLE_HOLD = 0.35
local SETTLE_STEP = 0.1
-- The backstop. A body that never settles -- wedged in geometry, thrown off the
-- road -- must still get its character back.
local THROW_TIMEOUT = 6

--==============================================================================
-- THE GRAB
--
-- Spawned rather than run in the tick, because it holds for the better part of
-- a second and the other eleven nests must not stop while it does.
--==============================================================================
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
	-- PlatformStand STAYS ON, and that is not cosmetic.
	--
	-- Releasing it before applying the velocity gives the Humanoid controller
	-- the assembly back, and it immediately damps whatever it was given: a
	-- throw solved for 60 studs measured NINE. With PlatformStand held the
	-- humanoid applies no movement forces of its own and the body keeps what it
	-- was thrown with.
	--==========================================================================
	loosened = ragdollOn(character)
	root.AssemblyLinearVelocity = dir * speed + Vector3.new(0, speed * k, 0)

	--==========================================================================
	-- WAIT FOR IT TO SETTLE, NOT FOR AN ARC.
	--
	-- The old code waited the parabola's exact duration and then wiped the
	-- horizontal velocity, which is what made this a hop: the body could not
	-- bounce, because the one moment a bounce would start was the moment its
	-- speed was set to zero.
	--
	-- Nothing here predicts where the body goes. It polls until the thing has
	-- actually stopped moving sideways for a beat, or until the backstop fires.
	--
	-- FloorMaterial is not usable for this, and that is not a guess: it is part
	-- of the Humanoid state machine, PlatformStand switches that machine off, so
	-- FloorMaterial reads Air for the entire ragdoll no matter where the body
	-- is. An earlier version polled it and ran to its timeout every single time.
	--==========================================================================
	local settledFor = 0
	local deadline = os.clock() + THROW_TIMEOUT
	while os.clock() < deadline do
		if player.Parent ~= Players or not root.Parent or humanoid.Health <= 0 then
			break
		end
		-- Hold the claim. Anything that reshapes the assembly hands it back to
		-- the player, and a body simulated by its owner is a body nobody else
		-- watching the chase can see move.
		if root:GetNetworkOwner() ~= nil then
			claim(root)
		end
		local v = root.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude < SETTLE_SPEED then
			settledFor += SETTLE_STEP
			if settledFor >= SETTLE_HOLD then
				break
			end
		else
			settledFor = 0
		end
		task.wait(SETTLE_STEP)
	end

	--==========================================================================
	-- STAND UP LEVEL, OR THE SOLVER LAUNCHES YOU.
	--
	-- Re-enabling the joints while limbs are half inside the floor makes the
	-- physics solver resolve the overlap the only way it can -- by throwing the
	-- body out of it. Measured: settled at Y 0.5, then a 12.6 stud pop on
	-- stand-up and a second fall.
	--
	-- So the body is levelled and stilled BEFORE the joints come back: keep
	-- where it landed, drop the pitch and roll, lift it clear of the ground, and
	-- zero the velocity.
	--
	-- This is NOT the old landing wipe. That one fired on first ground contact
	-- and is what made the throw a hop. This fires after the body has already
	-- stopped moving, which is the one moment killing velocity costs nothing.
	--==========================================================================
	if root.Parent then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		-- Facing the way they were thrown, which is home.
		root.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.6, 0))
			* CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)
	end

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
