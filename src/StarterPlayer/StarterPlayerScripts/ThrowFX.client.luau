--!strict
-- Steal a Seed :: ThrowFX
--
-- Being hit by a nest parent, on the machine that actually owns the body.
--
--==============================================================================
-- THE LOCAL HUMANOID EATS THE THROW UNLESS YOU STOP IT FIRST
--
-- This is the bug that survived two rewrites, and neither of them was visible
-- from a server-side probe.
--
-- `PlatformStand = true` set on the SERVER replicates as a property, but it does
-- not put the OWNER'S humanoid into the Physics state. That humanoid stays in
-- Running / GettingUp, its controller runs every frame on this machine, and it
-- zeroes AssemblyLinearVelocity the frame after the impulse is applied. So the
-- body never leaves contact:
--
--     invisible   the camera is inside the parent's mesh, and Roblox's own
--                 LocalTransparencyModifier hides your character when that
--                 happens. Transparency itself stays 0, which is why measuring
--                 Transparency said everything was fine.
--     stuck       because the body genuinely never moved.
--     teleport    the server times out, restore() runs, and the character snaps.
--
-- So before the impulse, on this machine: ChangeState(Physics), PlatformStand
-- locally, and then hold the velocity for several frames so a controller that
-- is still winding down cannot swallow it.
--
--==============================================================================
-- WHY ANY OF THIS IS CLIENT-SIDE
--
-- A player's character is simulated by that player. The server decides the hit
-- happened, makes the body limp, drops the pod and takes the walk speed away --
-- those are properties and they replicate. It cannot throw the thing, and it
-- must not try: an earlier version took the assembly with SetNetworkOwner(nil)
-- and produced exactly the same three symptoms from the other direction.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer

-- Matched to the server's idea of stopped. Short enough that a body wedged
-- against a wall is not held down after it stops, long enough that the top of a
-- bounce -- where horizontal speed passes through zero -- is not the end of one.
local SETTLE_SPEED = 3.5
local SETTLE_HOLD = 0.35
local SETTLE_STEP = 0.08
-- Shorter than the server's backstop, so the answer normally arrives first.
local GIVE_UP_AFTER = 5
-- How long to keep re-asserting the impulse. The humanoid controller does not
-- stop dead on ChangeState; a handful of frames of insistence is the difference
-- between a throw and a twitch.
local HOLD_VELOCITY_FOR = 0.2
-- Push the camera out so it cannot sit inside the parent -- or inside the
-- player's own head once the body is horizontal.
local THROW_ZOOM = 12

local throwing = false
local remote: RemoteEvent? = nil

local function say(message: string)
	print("[Seed/ThrowFX] " .. message)
end

local function rootOf(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--==============================================================================
-- KEEPING THE BODY ON SCREEN
--
-- Bound ABOVE the camera's own render step, because the default camera module
-- is what sets LocalTransparencyModifier to hide a character the camera is
-- close to. Setting it earlier in the frame just gets overwritten.
--==============================================================================
local VISIBLE_BINDING = "SeedThrowVisible"
local visibleBound = false

local function keepVisible()
	local character = player.Character
	if not character then
		return
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = 0
		end
	end
end

local function bindVisible()
	if visibleBound then
		return
	end
	visibleBound = true
	RunService:BindToRenderStep(VISIBLE_BINDING,
		Enum.RenderPriority.Camera.Value + 1, keepVisible)
end

local function unbindVisible()
	if not visibleBound then
		return
	end
	visibleBound = false
	pcall(function()
		RunService:UnbindFromRenderStep(VISIBLE_BINDING)
	end)
end

--==============================================================================
-- THE HIT
--==============================================================================
local function onThrown(dir: Vector3, speed: number, lift: number, clear: number)
	-- Everything here came off the wire. A malformed packet should do nothing
	-- rather than throw inside an event handler and leave the flag stuck.
	if typeof(dir) ~= "Vector3" or type(speed) ~= "number" or type(lift) ~= "number" then
		say("bad payload, ignoring")
		return
	end
	if dir.Magnitude <= 0 or speed ~= speed or speed <= 0 then
		say("bad direction or speed, ignoring")
		return
	end
	if throwing then
		return
	end
	throwing = true

	local flat = Vector3.new(dir.X, 0, dir.Z)
	local unit = if flat.Magnitude > 0 then flat.Unit else Vector3.new(0, 0, 1)
	local impulse = unit * speed + Vector3.new(0, speed * lift, 0)
	say(string.format("HIT received: dir %s speed %.1f lift %.2f clear %.1f",
		tostring(unit), speed, lift, if type(clear) == "number" then clear else -1))

	task.spawn(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = rootOf()
		if not (humanoid and root) then
			say("no character to throw")
			throwing = false
			return
		end

		--== 1. STOP THE LOCAL CONTROLLER ==--
		humanoid.PlatformStand = true
		local changed = pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end)
		say(string.format("ChangeState(Physics) ok=%s -> state now %s",
			tostring(changed), tostring(humanoid:GetState())))

		--== 2. GET OUT OF THE PARENT, on a root this machine owns ==--
		local step = if type(clear) == "number" and clear > 0 then clear else 0
		if step > 0 then
			root.CFrame = root.CFrame + unit * step
			say(string.format("stepped %.1f studs clear along %s", step, tostring(unit)))
		end

		--== 3. THE CAMERA COMES OUT WITH US ==--
		local wasZoom = player.CameraMinZoomDistance
		player.CameraMinZoomDistance = math.max(wasZoom, THROW_ZOOM)
		bindVisible()

		--== 4. THROW, AND KEEP THROWING FOR A FEW FRAMES ==--
		root.AssemblyLinearVelocity = impulse
		say(string.format("first velocity applied: %s (%.1f studs/sec)",
			tostring(impulse), impulse.Magnitude))
		local holdUntil = os.clock() + HOLD_VELOCITY_FOR
		while os.clock() < holdUntil do
			local r = rootOf()
			if not r then
				break
			end
			-- Re-assert rather than trusting one write. A controller that is
			-- still winding down will zero this, and one frame of that is the
			-- difference between a throw and a twitch.
			r.AssemblyLinearVelocity = impulse
			RunService.Heartbeat:Wait()
		end

		--== 5. WAIT UNTIL IT HAS REALLY STOPPED ==--
		local head = character:FindFirstChild("Head")
		local settledFor = 0
		local deadline = os.clock() + GIVE_UP_AFTER
		while os.clock() < deadline do
			local r = rootOf()
			if not r then
				break
			end
			-- Per-frame, as asked: this is the number that says whether the
			-- player can actually see themselves.
			if head and head:IsA("BasePart") then
				say(string.format("  Y %.2f  vel %.1f  Head LTM %.2f  state %s",
					r.Position.Y, r.AssemblyLinearVelocity.Magnitude,
					head.LocalTransparencyModifier, tostring(humanoid:GetState())))
			end
			local v = r.AssemblyLinearVelocity
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
		-- 6. LEVEL IN PLACE, WHERE THIS SIMULATION ACTUALLY STOPPED
		--
		-- Not at a position anybody computed. The server is about to switch the
		-- joints back on, and re-enabling them while limbs are half inside the
		-- floor leaves the solver one way to resolve the overlap -- by flinging
		-- the body out of it. Measured at 12.6 studs before this existed.
		--======================================================================
		local r = rootOf()
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			local here = r.Position + Vector3.new(0, 1.6, 0)
			r.CFrame = CFrame.lookAt(here, here + unit)
			say(string.format("settled and levelled at %s", tostring(r.Position)))
		end

		--== 7. GIVE THE CHARACTER BACK ==--
		player.CameraMinZoomDistance = wasZoom
		unbindVisible()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		throwing = false
		if remote then
			pcall(function()
				(remote :: RemoteEvent):FireServer()
			end)
		end
		say("done, told the server")
	end)
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	-- WaitForChild, not FindFirstChild: the Remotes FOLDER replicates before the
	-- events inside it, and a FindFirstChild here would silently never connect.
	-- CashUI sat blank for a whole session on exactly that.
	local found = remotes:WaitForChild(GameConfig.Remotes.ThrowVictim, 20)
	if found and found:IsA("RemoteEvent") then
		remote = found
		found.OnClientEvent:Connect(onThrown)
		say("listening on " .. GameConfig.Remotes.ThrowVictim)
	else
		warn("[Seed/ThrowFX] No ThrowVictim remote; the parent's hit will not throw.")
	end
else
	warn("[Seed/ThrowFX] No Remotes folder; the parent's hit will not throw.")
end

-- A respawn cancels any tumble in progress: the body it belonged to is gone.
player.CharacterAdded:Connect(function()
	throwing = false
	unbindVisible()
end)
