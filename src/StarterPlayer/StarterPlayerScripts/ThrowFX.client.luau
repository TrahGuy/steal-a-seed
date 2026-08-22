--!strict
-- Steal a Seed :: ThrowFX
--
-- Being hit by a nest parent, on the machine that actually owns the body.
--
--==============================================================================
-- A LIMP BODY IS SIXTEEN ASSEMBLIES, NOT ONE
--
-- This is the bug that survived three rewrites, and every one of them measured
-- clean because they all measured the HumanoidRootPart.
--
-- A posed R15 rig is held together by AnimationConstraints. Going limp means
-- disabling those, and what is left is BallSocketConstraints -- which are
-- CONSTRAINTS, not joints. They do not merge assemblies. Measured on a live
-- character the moment the fifteen constraints go off:
--
--     assembly roots while limp: Head, HumanoidRootPart, LeftFoot, LeftHand,
--       LeftLowerArm, LeftLowerLeg, LeftUpperArm, LeftUpperLeg, LowerTorso,
--       RightFoot, RightHand, RightLowerArm, RightLowerLeg, RightUpperArm,
--       RightUpperLeg, UpperTorso            -- sixteen, one part each
--
-- So `root.AssemblyLinearVelocity = impulse` threw the HumanoidRootPart. On its
-- own. A Transparency = 1 box, two studs by two by one, with the camera dutifully
-- following it into the distance while the body it belongs to stayed exactly
-- where it was hit:
--
--     invisible   the visible body never moved; the camera left with the box.
--                 Measured: 148 studs between camera and head, and the camera
--                 module never once asked to hide anything (LTM wanted 0.00).
--     stuck       because the body genuinely was still standing at the parent.
--     teleport    the joints come back on and the body snaps to wherever the
--                 box got to.
--
-- Every part gets the impulse now.
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

-- Every BasePart in the character. While limp each one is its own assembly, so
-- anything done to "the body" has to be done to all of them.
local function bodyParts(): { BasePart }
	local out: { BasePart } = {}
	local character = player.Character
	if character then
		for _, d in ipairs(character:GetChildren()) do
			if d:IsA("BasePart") then
				table.insert(out, d)
			end
		end
	end
	return out
end

local function rootOf(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--==============================================================================
-- KEEPING THE BODY ON SCREEN
--
-- Bound at RenderPriority.Last, not Camera + 1. The default camera module is
-- what sets LocalTransparencyModifier to hide a character the camera is close
-- to, and it does not do it from one predictable place -- binding just after
-- the camera is a guess about ordering. Last is the final callback before the
-- frame renders, so this write cannot be overwritten by anything.
--
--==============================================================================
-- AND IT RECORDS WHAT IT OVERWROTE
--
-- The previous build printed Head.LocalTransparencyModifier from the settle
-- loop and reported 0.00 every frame. That number was worthless: it was reading
-- back the value THIS binding had just written. A measurement of your own write
-- proves nothing about whether the camera wanted you hidden.
--
-- `observedLTM` is the value found BEFORE forcing it, which is the camera
-- module's actual intent -- if that reads 1.00 while the body is on screen,
-- the camera is inside a mesh and this override is the only reason anything is
-- visible at all.
--==============================================================================
local VISIBLE_BINDING = "SeedThrowVisible"
local visibleBound = false
local observedLTM = -1

local function keepVisible()
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		observedLTM = head.LocalTransparencyModifier
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
	observedLTM = -1
	RunService:BindToRenderStep(VISIBLE_BINDING,
		Enum.RenderPriority.Last.Value, keepVisible)
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

		--== 2. GET OUT OF THE PARENT -- THE WHOLE BODY, NOT THE ROOT ==--
		-- PivotTo moves every part. Writing root.CFrame would have stepped the
		-- invisible box out of the parent and left the body standing in it.
		local step = if type(clear) == "number" and clear > 0 then clear else 0
		if step > 0 then
			character:PivotTo(character:GetPivot() + unit * step)
			say(string.format("stepped %.1f studs clear along %s", step, tostring(unit)))
		end

		--======================================================================
		-- 3. THE CAMERA COMES OUT WITH US
		--
		-- Three separate things can keep a player from seeing their own body,
		-- and only one of them is LocalTransparencyModifier:
		--
		--   LockFirstPerson  the character is ALWAYS hidden. Raising the zoom
		--                    floor does nothing while this is set.
		--   MaxZoomDistance  a floor above the ceiling is ignored, so the
		--                    ceiling has to move first.
		--   MinZoomDistance  what actually pushes the camera out of the mesh.
		--
		-- All three are captured and restored.
		--======================================================================
		local wasMode = player.CameraMode
		local wasMin = player.CameraMinZoomDistance
		local wasMax = player.CameraMaxZoomDistance
		if wasMode == Enum.CameraMode.LockFirstPerson then
			player.CameraMode = Enum.CameraMode.Classic
		end
		if player.CameraMaxZoomDistance < THROW_ZOOM then
			player.CameraMaxZoomDistance = THROW_ZOOM
		end
		player.CameraMinZoomDistance = math.max(wasMin, THROW_ZOOM)
		bindVisible()

		local camera = workspace.CurrentCamera
		say(string.format("camera: mode %s -> %s | zoom %.1f..%.1f -> %.1f..%.1f | type %s | subject %s",
			tostring(wasMode), tostring(player.CameraMode), wasMin, wasMax,
			player.CameraMinZoomDistance, player.CameraMaxZoomDistance,
			tostring(camera and camera.CameraType),
			tostring(camera and camera.CameraSubject and camera.CameraSubject.Name)))

		--== 4. THROW EVERY PART, AND KEEP THROWING FOR A FEW FRAMES ==--
		local parts = bodyParts()
		for _, part in ipairs(parts) do
			part.AssemblyLinearVelocity = impulse
		end
		say(string.format("first velocity applied to %d parts: %s (%.1f studs/sec)",
			#parts, tostring(impulse), impulse.Magnitude))
		local holdUntil = os.clock() + HOLD_VELOCITY_FOR
		while os.clock() < holdUntil do
			-- Re-assert rather than trusting one write. A controller that is
			-- still winding down will zero this, and one frame of that is the
			-- difference between a throw and a twitch.
			for _, part in ipairs(bodyParts()) do
				part.AssemblyLinearVelocity = impulse
			end
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
				-- observedLTM is what the CAMERA wanted before this script
				-- overrode it, camDist says whether the camera is even near the
				-- body, and Transparency catches anything setting it outright.
				local camera = workspace.CurrentCamera
				local camDist = if camera then (camera.CFrame.Position - head.Position).Magnitude else -1
				-- headGap is the number that matters: the distance between the
				-- INVISIBLE root and the VISIBLE head. If that grows, the body
				-- has been left behind again.
				say(string.format("  rootY %.2f headY %.2f gap %.2f | vel %.1f | camera %.1f away | LTM wanted %.2f | %s",
					r.Position.Y, head.Position.Y, (head.Position - r.Position).Magnitude,
					r.AssemblyLinearVelocity.Magnitude, camDist,
					observedLTM, tostring(humanoid:GetState())))
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
			-- Every part, again: stopping only the root leaves fifteen limbs
			-- still drifting, and the joints come back on a moving body.
			for _, part in ipairs(bodyParts()) do
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
			local here = r.Position + Vector3.new(0, 1.6, 0)
			character:PivotTo(CFrame.lookAt(here, here + unit))
			say(string.format("settled and levelled at %s", tostring(r.Position)))
		end

		--== 7. GIVE THE CHARACTER BACK ==--
		player.CameraMinZoomDistance = wasMin
		player.CameraMaxZoomDistance = wasMax
		player.CameraMode = wasMode
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
