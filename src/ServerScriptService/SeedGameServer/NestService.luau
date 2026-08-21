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
	}
	for i = 1, biome.PodsPerNest do
		growPod(nest, i)
	end
	return nest
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

			-- WAKE, ON A DELAY. The delay is the head start, and it is the
			-- whole skill of a raid.
			if nest.state == "asleep" then
				nest.state = "waking"
				nest.stateUntil = os.clock() + P.WakeDelaySeconds
			end
			-- Always re-target: stealing from a parent already chasing somebody
			-- else should make it chase YOU, or two players could take turns
			-- feeding it a decoy.
			nest.target = thief
			return SeedData.Get(speciesId)
		end
	end
	return nil
end

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

	local walk = humanoid.WalkSpeed
	local jump = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.PlatformStand = true

	task.wait(P.GrabHoldSeconds)

	if player.Parent ~= Players or humanoid.Health <= 0 then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = walk
		humanoid.JumpPower = jump
		return
	end

	-- Range of a projectile launched at v with vertical component k*v is
	-- 2*k*v^2/g, so the speed that lands them the configured distance away is
	-- sqrt(R*g / 2k). Solved rather than tuned, so changing the distance in
	-- GameConfig actually changes the distance.
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
	-- PlatformStand STAYS ON THROUGH THE FLIGHT, and that is not cosmetic.
	--
	-- Releasing it before applying the velocity gives the Humanoid controller
	-- the assembly back, and it immediately damps whatever it was given: a
	-- throw solved for 60 studs measured NINE. With PlatformStand held the
	-- humanoid applies no movement forces of its own and the body keeps what it
	-- was thrown with.
	--
	-- It also looks right -- a thrown player should tumble, not jog through the
	-- air in a running pose.
	--==========================================================================
	root.AssemblyLinearVelocity = dir * speed + Vector3.new(0, speed * k, 0)

	--==========================================================================
	-- LAND THEM, DO NOT LET THEM SKID.
	--
	-- The arc itself is exact -- measured apex 6.6 studs against a predicted
	-- vy^2/2g of 6.76, and 0.52s of flight at 114 studs/sec is the configured
	-- 60. What broke the number was what happened AFTER touchdown: a
	-- PlatformStand body keeps its horizontal velocity and slides, and a
	-- controlled test measured 143 studs of travel for a 60-stud throw.
	--
	-- So the throw waits for the floor and then stops the slide. The distance in
	-- GameConfig is now the distance the player actually travels, which is the
	-- only reason to have the number there at all.
	--==========================================================================
	--
	-- TIMED, NOT FLOOR-DETECTED. The obvious landing check is
	-- `humanoid.FloorMaterial ~= Air`, and it can never become true here:
	-- PlatformStand switches the Humanoid's state machine off, and floor
	-- detection is part of it. FloorMaterial stays Air for the whole flight, so
	-- the poll ran to its timeout every time and the body skidded for two and a
	-- half seconds -- 143 studs for a 60-stud throw, twice.
	--
	-- The arc is exact, so its duration is exact. Wait it.
	local flight = 2 * (speed * k) / g
	task.wait(flight)

	if player.Parent ~= Players then
		return
	end
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 0), 0)
	humanoid.PlatformStand = false
	humanoid.WalkSpeed = walk
	humanoid.JumpPower = jump
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
	nest.humanoid.WalkSpeed = 0
	nest.parent:SetAttribute("Asleep", true)
end

local function step(nest: Nest, now: number)
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
			nest.humanoid.WalkSpeed = GameConfig.parentWalkSpeedFor(nest.biome.Order)
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
		nest.humanoid:MoveTo(pos)
		if flat.Magnitude > 1 then
			nest.root.CFrame = CFrame.lookAt(nest.root.Position,
				nest.root.Position + flat.Unit)
		end
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
	log(string.format("Ready. %d nest(s), %d pod(s). Parents sleep until robbed.",
		#nests, pods))

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
