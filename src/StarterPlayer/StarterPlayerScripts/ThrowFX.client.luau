--!strict
-- Steal a Seed :: ThrowFX
--
-- Being hit by a nest parent, on the machine that actually owns the body.
--
--==============================================================================
-- WHY THIS EXISTS AT ALL
--
-- A player's character is simulated by THAT PLAYER. The server can decide the
-- hit happened, make the body limp, drop the pod and take the walk speed away
-- -- those are properties, and properties replicate. What it cannot do is throw
-- the thing: an AssemblyLinearVelocity written on the server is overwritten by
-- the owner's next physics update.
--
-- An earlier version got around that by taking the assembly with
-- SetNetworkOwner(nil). It measured beautifully and played terribly: the victim
-- stayed stuck inside the parent, saw nothing at all, and was then teleported
-- to wherever the server's copy had ended up when ownership went back. Every
-- number written about it was true of a body nobody was looking at.
--
-- So the server asks, and the owner throws. The owner's physics replicate out
-- to everyone else for free, which is the same reason nobody has to be told
-- where a walking player is.
--
--==============================================================================
-- IT REPORTS BACK, AND THE SERVER DOES NOT DEPEND ON IT
--
-- Telling the server "I have stopped" lets it stand the character up the moment
-- the tumble is really over rather than at the end of a fixed timeout. If this
-- client never answers -- it left, it hung, it is lying -- the server's timeout
-- ends the ragdoll anyway. The answer is an optimisation, never a requirement.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer

-- Matched to the server's own idea of stopped. Short enough that a body wedged
-- against a wall is not held down after it stops, long enough that the top of a
-- bounce -- where horizontal speed passes through zero -- is not mistaken for
-- the end of one.
local SETTLE_SPEED = 3.5
local SETTLE_HOLD = 0.35
local SETTLE_STEP = 0.08
-- Shorter than the server's backstop, so in the normal case the answer arrives
-- first and the server never has to fall back on the timeout.
local GIVE_UP_AFTER = 5

local throwing = false
-- Declared before onThrown so the handler closes over it; assigned once the
-- remote has replicated, below.
local remote: RemoteEvent? = nil

local function rootOf(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function onThrown(dir: Vector3, speed: number, lift: number, _clear: number)
	-- Everything here came off the wire. The server is not hostile, but a
	-- malformed packet should do nothing rather than throw inside an event
	-- handler and leave the flag stuck.
	if typeof(dir) ~= "Vector3" or type(speed) ~= "number" or type(lift) ~= "number" then
		return
	end
	if dir.Magnitude <= 0 or speed ~= speed or speed <= 0 then
		return
	end
	if throwing then
		return
	end
	throwing = true

	task.spawn(function()
		local root = rootOf()
		if root then
			-- THE ACTUAL THROW. This is a body this machine owns, so the impulse
			-- sticks and replicates outward on its own.
			root.AssemblyLinearVelocity = dir.Unit * speed + Vector3.new(0, speed * lift, 0)
		end

		--== WAIT UNTIL IT HAS REALLY STOPPED ==--
		local settledFor = 0
		local deadline = os.clock() + GIVE_UP_AFTER
		while os.clock() < deadline do
			root = rootOf()
			if not root then
				break
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

		--======================================================================
		-- LEVEL IN PLACE, WHERE THIS SIMULATION ACTUALLY STOPPED
		--
		-- Not at a position anybody computed. The old server-side version wrote
		-- a CFrame at the end of ITS arc, a hundred and sixty studs from where
		-- this client still had the body, and that write was the teleport.
		--
		-- What the levelling is for: the server is about to switch the joints
		-- back on, and re-enabling them while limbs are half inside the floor
		-- leaves the solver one way to resolve the overlap -- by flinging the
		-- body out of it. Measured at 12.6 studs before this existed.
		--
		-- Zero the velocity, drop the pitch and roll, lift clear of the ground,
		-- and stay exactly where the tumble ended.
		--======================================================================
		root = rootOf()
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			local flat = Vector3.new(dir.X, 0, dir.Z)
			local facing = if flat.Magnitude > 0 then flat.Unit else Vector3.new(0, 0, 1)
			root.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 1.6, 0),
				root.Position + Vector3.new(0, 1.6, 0) + facing)
		end

		throwing = false
		if remote then
			pcall(function()
				(remote :: RemoteEvent):FireServer()
			end)
		end
	end)
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local found = remotes:WaitForChild(GameConfig.Remotes.ThrowVictim, 20)
	if found and found:IsA("RemoteEvent") then
		remote = found
		found.OnClientEvent:Connect(onThrown)
	else
		-- WaitForChild, not FindFirstChild: the Remotes FOLDER replicates before
		-- the events inside it, and a FindFirstChild here would silently never
		-- connect. CashUI sat blank for a whole session on exactly that.
		warn("[Seed/ThrowFX] No ThrowVictim remote; the parent's hit will not throw.")
	end
end

-- A respawn cancels any tumble in progress: the body it belonged to is gone.
player.CharacterAdded:Connect(function()
	throwing = false
end)
