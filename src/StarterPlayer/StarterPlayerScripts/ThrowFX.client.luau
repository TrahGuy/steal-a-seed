--!strict
-- Steal a Seed :: ThrowFX
--
-- Being hit by a nest parent, on the machine that actually owns the body.
--
--==============================================================================
-- THE LANDING IS NOT THE FLIGHT
--
-- Sixteen assemblies fixed the throw. It did not fix the END of the throw,
-- because settling, levelling and the camera were all still keyed off the
-- HumanoidRootPart -- the one part of this character nobody can see.
--
-- What the owner saw: the visible body arrives on the ground, the camera keeps
-- following something else, and then they teleport.
--
--   the camera        CameraSubject is the Humanoid, and a Humanoid tracks its
--                     root. The root is Transparency = 1 and, while limp, is
--                     its own assembly -- so the camera watches an empty box.
--   the settle        `root.AssemblyLinearVelocity` said "still flying" while
--                     the body was already down. The body can be at rest and
--                     the box still moving; they are not the same object.
--   the teleport      `PivotTo(r.Position + up)` pivoted the whole character
--                     onto the ROOT. Whatever the box had drifted to, the body
--                     was dragged there the instant joints came back.
--
-- The rule for all three: DO NOT YANK THE BODY TO THE ROOT. Put the root under
-- the body, then re-pose. The box comes to the body, never the other way.
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
-- How long to keep printing after the joints come back. The teleport used to
-- happen in this window, so this is the window that has to be watched.
local STANDUP_WATCH = 0.9
-- Waiting for the server's ragdollOff to arrive. Polled on the constraints
-- themselves rather than slept, because a sleep is a guess about the round trip.
local JOINTS_BACK_TIMEOUT = 1.5

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
		for _, d in ipairs(character:GetDescendants()) do
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

-- The part the player actually watches. R15 calls it UpperTorso, R6 calls it
-- Torso, and everything about the landing hangs off it.
local function torsoOf(character: Model): BasePart?
	local t = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return if t and t:IsA("BasePart") then t else nil
end

--==============================================================================
-- WHERE THE ROOT SITS ON A BODY THAT IS NOT BROKEN
--
-- Measured off a resting rig at spawn, not guessed at, and not measured mid
-- tumble -- during the tumble the root and the torso have drifted apart, which
-- is the whole bug. This is the offset that says "the box belongs HERE", and it
-- is what puts the box back on the body before the joints return.
--==============================================================================
local restOffset: CFrame? = nil

local function captureRest(character: Model)
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not (root and root:IsA("BasePart")) then
			return
		end
		-- Half a second of standing there: long enough that the rig is posed
		-- rather than still assembling.
		task.wait(0.5)
		local torso = torsoOf(character)
		if torso and root.Parent then
			local offset = torso.CFrame:ToObjectSpace(root.CFrame)
			restOffset = offset
			say(string.format("rest offset, root relative to %s: %s",
				torso.Name, tostring(offset.Position)))
		end
	end)
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
		local step = if type(clear) == "number" and clear > 0 then clear else 6
		character:PivotTo(character:GetPivot() + unit * step + Vector3.new(0, 3, 0))
		say(string.format("stepped %.1f studs clear along %s", step, tostring(unit)))

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

		--======================================================================
		-- AND IT FOLLOWS THE HEAD, NOT THE HUMANOID
		--
		-- CameraSubject defaults to the Humanoid, and a Humanoid tracks its
		-- HumanoidRootPart. That is fine on a character whose parts are welded
		-- into one assembly; on a limp one the root flies off on its own and the
		-- camera goes with it, watching an invisible box while the body lands
		-- somewhere else entirely. Measured: 148 studs of separation.
		--
		-- The Head is a part the owner can see. Restored to the Humanoid the
		-- moment the root is back underneath the body.
		--======================================================================
		local camera = workspace.CurrentCamera
		local wasSubject: Instance? = if camera then camera.CameraSubject else nil
		local headPart = character:FindFirstChild("Head")
		if camera and headPart and headPart:IsA("BasePart") then
			camera.CameraSubject = headPart
		end
		say(string.format("camera: mode %s -> %s | zoom %.1f..%.1f -> %.1f..%.1f | subject %s -> %s",
			tostring(wasMode), tostring(player.CameraMode), wasMin, wasMax,
			player.CameraMinZoomDistance, player.CameraMaxZoomDistance,
			tostring(wasSubject and wasSubject.Name),
			tostring(camera and camera.CameraSubject and camera.CameraSubject.Name)))

		--== 4. THROW EVERY PART WITH TUMBLE IMPULSE ==--
		local parts = bodyParts()
		local tumble = Vector3.new(math.random(-6, 6), math.random(-3, 3), math.random(-6, 6))
		for _, part in ipairs(parts) do
			part:ApplyImpulse(impulse * part.AssemblyMass)
			part.AssemblyLinearVelocity = impulse
			part.AssemblyAngularVelocity = tumble
		end
		say(string.format("first velocity applied to %d parts: %s (%.1f studs/sec)",
			#parts, tostring(impulse), impulse.Magnitude))

		-- Hold velocity for 0.35s to completely override any humanoid motor damping
		local holdUntil = os.clock() + 0.35
		while os.clock() < holdUntil do
			humanoid.PlatformStand = true
			for _, part in ipairs(bodyParts()) do
				part.AssemblyLinearVelocity = impulse
			end
			RunService.Heartbeat:Wait()
		end

		--======================================================================
		-- 5. WAIT UNTIL THE BODY HAS FLOWN AND STOPPED
		--======================================================================
		local head = character:FindFirstChild("Head")
		local torso = torsoOf(character)
		local settledFor = 0
		local flightStart = os.clock()
		local minFlightTime = 0.9 -- Guarantee minimum flight arc
		local deadline = os.clock() + GIVE_UP_AFTER

		while os.clock() < deadline do
			local r = rootOf()
			if not r then
				break
			end
			local bodySpeed = 0
			if head and head:IsA("BasePart") then
				bodySpeed = math.max(bodySpeed, head.AssemblyLinearVelocity.Magnitude)
			end
			if torso and torso.Parent then
				bodySpeed = math.max(bodySpeed, torso.AssemblyLinearVelocity.Magnitude)
			end

			-- Only allow settle check after minimum flight arc has elapsed
			local flightElapsed = os.clock() - flightStart
			if flightElapsed >= minFlightTime then
				if bodySpeed < SETTLE_SPEED then
					settledFor += SETTLE_STEP
					if settledFor >= SETTLE_HOLD then
						break
					end
				else
					settledFor = 0
				end
			end
			task.wait(SETTLE_STEP)
		end

		--======================================================================
		-- 6. BRING THE BOX TO THE BODY. NOT THE BODY TO THE BOX.
		--
		-- The joints are about to come back, and when they do the whole rig
		-- re-poses around the HumanoidRootPart. So whatever CFrame the root
		-- holds at that instant IS where the player ends up.
		--
		-- The old code pivoted the character onto `r.Position` -- the root, the
		-- invisible box, wherever its separate flight had left it. That is the
		-- teleport, in one line: the body landed, and then it was dragged to the
		-- box.
		--
		--   1. stop everything, all sixteen assemblies, so joints do not come
		--      back on a body that is still moving;
		--   2. seat the root on the TORSO at the measured rest offset, so the
		--      box is back inside the body it belongs to;
		--   3. stand that pair up where the torso is, feet on the ground the
		--      raycast found. The body does not travel; it stands up.
		--======================================================================
		local r = rootOf()
		local landedAt: Vector3? = nil
		local landedFrame: CFrame? = nil
		if r then
			for _, part in ipairs(bodyParts()) do
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end

			local body = torsoOf(character) or (if head and head:IsA("BasePart") then head else nil)
			if body then
				-- 2. the box comes to the body.
				local offset = restOffset or CFrame.identity
				local before = (body.Position - r.Position).Magnitude
				r.CFrame = body.CFrame * offset
				say(string.format("seated the root on %s: was %.2f studs away, now %.2f",
					body.Name, before, (body.Position - r.Position).Magnitude))

				-- 3. upright, at the body, on the floor. Height comes from the
				-- humanoid's own HipHeight rather than a hand-picked 1.6.
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { character }
				local down = workspace:Raycast(body.Position + Vector3.new(0, 2, 0),
					Vector3.new(0, -60, 0), params)
				local standY = if down
					then down.Position.Y + humanoid.HipHeight + r.Size.Y * 0.5
					else r.Position.Y
				local here = Vector3.new(body.Position.X, standY, body.Position.Z)
				landedFrame = CFrame.lookAt(here, here + unit)
				character:PivotTo(landedFrame)
				landedAt = here
				say(string.format("stood up at %s (ground %s, hip %.2f)",
					tostring(here),
					if down then string.format("%.2f", down.Position.Y) else "not found",
					humanoid.HipHeight))
			end
		end

		--======================================================================
		-- 7. GIVE THE CHARACTER BACK
		--
		-- Telling the server first: ragdollOff lives there, and the humanoid
		-- must not be handed a controller while the rig is still fifteen loose
		-- sockets. Waiting on the constraints themselves rather than sleeping a
		-- guessed round trip.
		--======================================================================
		if remote then
			pcall(function()
				(remote :: RemoteEvent):FireServer()
			end)
		end

		local watched: AnimationConstraint? = nil
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("AnimationConstraint") then
				watched = d
				break
			end
		end
		--======================================================================
		-- AND HOLD IT THERE WHILE THE ROUND TRIP HAPPENS
		--
		-- The pose built above is made of sixteen loose parts, and gravity does
		-- not pause for a RemoteEvent. A quarter of a second of round trip is
		-- six studs of free fall -- the body would scatter back out of the pose
		-- and the joints would come back on the mess, which is the snap all over
		-- again. So it is pinned, every frame, until the constraints answer.
		--======================================================================
		local jointDeadline = os.clock() + JOINTS_BACK_TIMEOUT
		while watched and not watched.Enabled and os.clock() < jointDeadline do
			if landedFrame and character.Parent then
				character:PivotTo(landedFrame)
				for _, part in ipairs(bodyParts()) do
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			RunService.Heartbeat:Wait()
		end
		say(string.format("joints back after %.2fs (%s)",
			JOINTS_BACK_TIMEOUT - (jointDeadline - os.clock()),
			if watched then tostring(watched.Enabled) else "no constraints to watch"))

		if humanoid.Parent then
			humanoid.PlatformStand = false
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		-- The camera goes back on the Humanoid only now, with the root seated
		-- under the body -- the two are the same place again, so there is
		-- nothing for it to jump to.
		if camera then
			-- A respawn mid-flight destroys the humanoid this started with, and
			-- pointing the camera at a destroyed instance is worse than leaving
			-- it where the engine put it.
			local subject: Instance? = if wasSubject and wasSubject.Parent
				then wasSubject
				else humanoid
			if subject and subject.Parent then
				camera.CameraSubject = subject :: any
			end
		end

		--======================================================================
		-- WATCH THE STAND-UP, BECAUSE THE TELEPORT USED TO LIVE HERE
		--
		-- gap stays around a stud and the camera distance stays flat: nothing
		-- moved. Either one jumping means the body is being pulled somewhere.
		--======================================================================
		local watchUntil = os.clock() + STANDUP_WATCH
		while os.clock() < watchUntil do
			local rr = rootOf()
			if not (rr and head and head:IsA("BasePart")) then
				break
			end
			local cam = workspace.CurrentCamera
			local camDist = if cam then (cam.CFrame.Position - head.Position).Magnitude else -1
			local drift = if landedAt then (head.Position - landedAt).Magnitude else -1
			say(string.format("  standing: gap %.2f | camera %.1f away | moved %.2f from the landing | %s",
				(head.Position - rr.Position).Magnitude, camDist, drift,
				tostring(humanoid:GetState())))
			task.wait(0.1)
		end

		player.CameraMinZoomDistance = wasMin
		player.CameraMaxZoomDistance = wasMax
		player.CameraMode = wasMode
		unbindVisible()

		throwing = false
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
-- It is also the one moment this script is guaranteed a rig standing in its
-- rest pose, which is where the root-to-torso offset has to be read.
player.CharacterAdded:Connect(function(character)
	throwing = false
	restOffset = nil
	unbindVisible()
	captureRest(character)
end)

local existing = player.Character
if existing then
	captureRest(existing)
end
