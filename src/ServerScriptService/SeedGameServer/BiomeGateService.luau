--!strict
-- Steal a Seed :: BiomeGateService
--
-- The gates gate.
--
--==============================================================================
-- THEY HAVE BEEN SIGNAGE SINCE THE FIRST WEEK
--
-- MapService has built an arch at every biome boundary from the beginning,
-- carrying the biome's name and a SpeedGate attribute, and NOTHING HAS EVER READ
-- EITHER. Its own comment says so: "signage until Phase C gives it a Speed
-- check". The whole Speed ladder -- 167M, 800M, 3B, 10B -- was a number on a
-- board that a player at zero could walk straight past.
--
--==============================================================================
-- A PLANE, NOT A PART
--
-- The obvious build is Touched on the arch. It is the wrong one twice over.
--
-- The arch is 4 studs deep and NON-COLLIDABLE, and a player at 150 WalkSpeed
-- covers 2.5 studs in a frame -- so a Touched on it is a coin flip at exactly
-- the speeds the gates exist to reward. The faster you get, the more likely you
-- are to pass a gate that should have stopped you, which is precisely backwards.
--
-- And the arch is DECORATION. It can be restyled, moved, or replaced by whoever
-- is making the road look better, and a rule hanging off a decoration is a rule
-- that disappears in an art pass.
--
-- So the check is geometry. Biome N owns one 300-stud segment, "which biome is
-- this position in" is one division, and a player deeper than they are allowed
-- is put back. That cannot be missed at any speed, in any frame rate, through
-- any amount of lag, because it does not depend on catching a moment -- it is a
-- statement about where somebody IS, tested ten times a second forever.
--
--==============================================================================
-- THE RECORD IS PERMANENT AND THE SCORE IS NOT
--
-- The gate opens on Speed and the unlock is written to HighestBiomeOrder, and
-- from then on the gate reads the RECORD. Those must be different fields: a
-- future rebirth sets Speed back to zero, and a gate reading the live score
-- would confiscate every biome the player had already earned at the exact moment
-- the game asked them to start over. That would make rebirth a punishment.
--
-- Nothing here lowers the record. PlayerDataService.RaiseHighestBiome refuses to.
--
--==============================================================================
-- THE CLIENT IS NEVER ASKED
--
-- No remote, in either direction. The server reads its own profile for the
-- score, its own workspace for the position, and writes its own record. The
-- client is TOLD -- via a replicated attribute -- so the HUD can grey out a gate
-- it cannot pass, and that attribute is a readout, never an input.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local BiomeGateService = {}
-- After PlayerDataService (20), which owns the record this reads and raises.
-- Before nothing in particular; it only needs profiles to exist.
BiomeGateService.Priority = 25

local MAP = GameConfig.Map
local GATE = GameConfig.Gate
local ATTR = GameConfig.Attributes

local running = false
local serviceConnections: { RBXScriptConnection } = {}
local lastNotice: { [Player]: number } = {}

local function log(message: string)
	print("[Seed/BiomeGateService] " .. message)
end

--==============================================================================
-- WHICH SEGMENT A POSITION IS IN
--
-- The road runs into NEGATIVE Z from the field's front edge, 300 studs per
-- biome. Anything at or in front of the mouth is the field -- the safe zone, the
-- plots, the hub -- and is order 0: not a biome, and never gated.
--
--     biome 1  -170 .. -470      biome 4  -1070 .. -1370
--     biome 2  -470 .. -770      biome 5  -1370 .. -1670
--     biome 3  -770 .. -1070
--
-- Derived from the same two numbers BiomeData.SegmentBounds uses, so the check
-- and the geometry cannot drift apart.
--==============================================================================
function BiomeGateService.OrderAt(position: Vector3): number
	local depth = -position.Z - MAP.FieldFront
	if depth < 0 then
		return 0
	end
	local order = math.floor(depth / MAP.SegmentLength) + 1
	return math.min(order, #BiomeData.Biomes)
end

--==============================================================================
-- WHERE THE PLANE FOR A GIVEN ORDER SITS
--
-- The near edge of segment `order`, which is the boundary you cross to ENTER it.
--==============================================================================
local function planeZFor(order: number): number
	return -MAP.FieldFront - (order - 1) * MAP.SegmentLength
end

--==============================================================================
-- WHAT THE SCORE HAS EARNED
--
-- The highest biome whose gate this score meets. Walked from the top so the
-- answer is the deepest one rather than the first.
--==============================================================================
function BiomeGateService.EarnedBy(speedScore: number): number
	if type(speedScore) ~= "number" or speedScore ~= speedScore then
		return 1
	end
	local earned = 1
	for _, biome in ipairs(BiomeData.Biomes) do
		if speedScore >= biome.SpeedGate then
			earned = math.max(earned, biome.Order)
		end
	end
	return earned
end

--==============================================================================
-- ONE PLAYER, ONE TICK
--
-- Unlock first, then enforce. A player who has just this second earned Dustbowl
-- and is standing on its threshold should walk through, not be shoved back and
-- let through on the next poll.
--==============================================================================
local function step(player: Player, now: number)
	local profile = PlayerDataService.Get(player)
	if not profile then
		return
	end

	--==========================================================================
	-- EARNING IT IS ENOUGH. YOU DO NOT HAVE TO BE STANDING THERE.
	--
	-- Checked wherever the player is, because the alternative -- unlock only
	-- when you touch the arch -- means a player who crossed the threshold while
	-- standing on their own mill has to walk 300 studs to be told. The gate is a
	-- requirement, not a ceremony.
	--==========================================================================
	local earned = BiomeGateService.EarnedBy(profile.Speed)
	if PlayerDataService.RaiseHighestBiome(player, earned) then
		local biome = BiomeData.Biomes[earned]
		log(string.format("%s unlocked %s permanently (Speed %s >= %s).",
			player.Name, if biome then biome.DisplayName else tostring(earned),
			GameConfig.compact(profile.Speed),
			GameConfig.compact(if biome then biome.SpeedGate else 0)))
	end

	local allowed = math.floor(profile.HighestBiomeOrder or 1)
	if player:GetAttribute(ATTR.HighestBiomeOrder) ~= allowed then
		player:SetAttribute(ATTR.HighestBiomeOrder, allowed)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootInstance = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and humanoid.Health > 0 and rootInstance and rootInstance:IsA("BasePart")) then
		-- Dead or mid-respawn. Shoving a corpse achieves nothing and shoving a
		-- character that is being rebuilt fights the spawn.
		return
	end
	local root = rootInstance :: BasePart

	local order = BiomeGateService.OrderAt(root.Position)
	if order <= allowed then
		return
	end

	--==========================================================================
	-- PUSHED BACK, NOT SENT HOME
	--
	-- Losing a pod and a two-minute walk for brushing a gate would make these
	-- the most hated thing in the game. The smallest correction that works:
	-- back across the plane they crossed, still holding everything, still
	-- facing the road.
	--
	-- The velocity is zeroed as well as the position. A player arrives at a gate
	-- at a sprint and that momentum lives in the assembly -- without this they
	-- are replaced and immediately carried back through, ten times a second, and
	-- the gate reads as a stutter rather than a wall.
	--
	-- A server CFrame write on a client-simulated character is normally the
	-- wrong tool -- NestService has a whole comment about it. It is right here
	-- for the same reason TreadmillService's mount uses it: this is a
	-- DISCONTINUITY, not a force. The owning client accepts a jump and resumes
	-- from it; what it overrides is a velocity you try to set alongside its own.
	--==========================================================================
	local plane = planeZFor(allowed + 1)
	local stop = plane + GATE.PushBackStuds
	local at = root.Position
	root.CFrame = CFrame.lookAt(
		Vector3.new(at.X, at.Y, stop),
		Vector3.new(at.X, at.Y, stop + 1))
	root.AssemblyLinearVelocity = Vector3.zero

	local last = lastNotice[player] or 0
	if now - last >= GATE.NoticeCooldown then
		lastNotice[player] = now
		local biome = BiomeData.Biomes[allowed + 1]
		if biome then
			log(string.format("%s turned back at %s: needs %s Speed, has %s.",
				player.Name, biome.DisplayName,
				GameConfig.compact(biome.SpeedGate),
				GameConfig.compact(profile.Speed)))
		end
	end
end

--==============================================================================
-- READ API
--==============================================================================
function BiomeGateService.AllowedFor(player: Player): number
	local profile = PlayerDataService.Get(player)
	return if profile then math.floor(profile.HighestBiomeOrder or 1) else 1
end

function BiomeGateService.CanEnter(player: Player, order: number): boolean
	return order <= BiomeGateService.AllowedFor(player)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function BiomeGateService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastNotice)
	-- Rule 10. A restart must not leave a stale allowance on anybody; it is
	-- re-published on the first tick from the profile, which is the truth.
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute(ATTR.HighestBiomeOrder, nil)
	end
end

function BiomeGateService.Start()
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		lastNotice[player] = nil
	end))

	running = true
	task.spawn(function()
		while running do
			task.wait(GATE.PollSeconds)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(step, player, now)
				if not ok then
					warn("[Seed/BiomeGateService] " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)

	local gates = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.SpeedGate > 0 then
			table.insert(gates, string.format("%s %s",
				biome.DisplayName, GameConfig.compact(biome.SpeedGate)))
		end
	end
	log(string.format("Ready. %d gate(s) enforced by position every %.2fs: %s. "
		.. "Unlocks are permanent and are never read off the client.",
		#gates, GATE.PollSeconds, table.concat(gates, ", ")))
end

function BiomeGateService.Snapshot(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		table.insert(rows, string.format("%s: allowed %d, standing in %d, Speed %s",
			player.Name, BiomeGateService.AllowedFor(player),
			if root and root:IsA("BasePart")
				then BiomeGateService.OrderAt(root.Position) else 0,
			GameConfig.compact(if profile then profile.Speed else 0)))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody on the road"
end

return BiomeGateService
