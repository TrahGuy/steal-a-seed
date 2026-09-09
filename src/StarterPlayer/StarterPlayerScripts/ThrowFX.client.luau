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

--==============================================================================
-- WHICH LAUNCH IS THE LIVE ONE
--
-- This file used to open with `if throwing then return end` and drop the packet.
-- That is the right instinct -- two tumbles running at once would fight over one
-- body -- and it was the wrong answer, because the launch it threw away was a
-- legitimate hit the server had already committed to. The server had ragdolled
-- the victim, taken their walk speed and dropped their pod; the client just
-- never moved them. A player went limp on the spot and slid.
--
-- It was reachable on ordinary play, not on a race: the old client could not
-- finish inside the deadline it was given, so it was routinely still running
-- when the next hit landed.
--
-- THE NEWER LAUNCH WINS. A generation counter, bumped on arrival, and every
-- loop below checks it before it acts. The task that has been superseded
-- returns without restoring anything -- the camera, the flag, the pose are all
-- the new task's to own now, and an old task tidying up after itself would be
-- tidying up around a live throw.
--==============================================================================
local generation = 0

--==============================================================================
-- THE CAMERA VALUES ARE CAPTURED ONCE, NOT PER THROW
--
-- With one throw at a time it did not matter where these lived. It does now: a
-- second throw arriving mid-tumble would capture the ZOOM THIS FILE HAD JUST
-- SET as though it were the player's own setting, and hand it back to them at
-- the end. Two hits in a row and the player keeps a 12-stud zoom floor forever.
--
-- So they are captured by the first throw of a chain and restored by the last,
-- and a throw that is superseded restores nothing.
--==============================================================================
type Pristine = {
	mode: Enum.CameraMode,
	min: number,
	max: number,
	subject: Instance?,
}
local pristine: Pristine? = nil

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
--==============================================================================
-- HOW LONG THE LAUNCH VELOCITY IS HELD, AND WHY IT IS NOT ALWAYS 0.35
--
-- The loop below re-writes AssemblyLinearVelocity every frame for the hold, and
-- that does not "hold" a throw -- it CANCELS GRAVITY for the duration. Measured
-- on a Starbloom hit: a launch of 228.8 horizontal and 102.9 vertical, whose
-- ballistic apex is 27 studs, reached 73 and carried the victim 797 studs. No
-- number anybody configured described the arc that resulted.
--
-- What the hold is really for is real, though, and it is written up at the top
-- of this file: setting PlatformStand makes the humanoid state machine zero the
-- assembly's velocity on the following frame. So a hold of zero does not mean
-- "no guard" -- it means one impulse, and then a short watch that puts the
-- velocity back ONCE if it collapses, after which gravity owns the flight.
--
-- The four guardians that shipped with the old behaviour still get it, because
-- their server sends no hold at all and this falls through to the tested value.
--==============================================================================
local LEGACY_HOLD = 0.35
-- Long enough for the humanoid state machine to stop trying to stand up. Being
-- generous costs nothing, because the guard below tracks the PARABOLA rather
-- than the launch, so a frame that needs no correction does not get one.
local CLEAN_GUARD = 0.30
-- How far the real velocity may drift from the ballistic one before it counts
-- as the engine having eaten it rather than gravity having taken it.
local OFF_ARC_BY = 0.22

--==============================================================================
-- A PLAYER'S BAT USES THIS SAME PIPELINE, DIALLED DOWN
--
-- Everything expensive in this file was learned the hard way -- sixteen
-- assemblies, a local humanoid that eats the impulse, a camera following an
-- invisible box -- and none of it is any less true when the thing that hit you
-- is another player holding a club. So a bat comes down the same remote rather
-- than getting a second knockback system that would have to relearn all of it.
--
-- What a bat needs differently is presentation, and it is exactly three things:
-- it must not shove the body five studs and pop it three more before it starts,
-- it must not reframe the camera for a hit that is over in a second, and it
-- tumbles less. Those are this table, and NOTHING ELSE IN THIS FILE BRANCHES ON
-- IT.
--
-- IT IS OPTIONAL AND NIL FOR EVERY GUARDIAN. NestService sends five arguments
-- and always has; each field below falls back to the constant that was there
-- before this existed, so a guardian throw runs the identical code with the
-- identical numbers. That is the whole design of the change: the guardian path
-- is not modified, it is defaulted.
--==============================================================================
export type ThrowStyle = {
	-- Studs the body is lifted while it is stepped clear. 3 for a monster you
	-- are standing inside; a fraction of that for a swing at arm's length.
	up: number?,
	-- Whether to push the camera out and put it on the head. A guardian needs
	-- both; a bat hit ends before a camera move would finish reading as one.
	camera: boolean?,
	-- Scale on the random spin. 1 is the tested guardian tumble.
	tumble: number?,
	--==========================================================================
	-- AND THE FOUR THE PROTOCOL ADDED
	--
	-- All nil for a guardian, which is what keeps that path defaulted rather
	-- than branched. Every one of them falls back to the constant that was
	-- there before, so a throw with no style runs the identical code with the
	-- identical numbers.
	--==========================================================================
	-- What the server will accept back as "I have stopped". Nil means this
	-- launch has no handshake of its own -- a guardian -- and the report goes
	-- out with nothing to quote, exactly as it always has.
	token: string?,
	-- Free text for the log. The behaviour hangs off the three numbers, never
	-- off this: a branch on a name is a branch that lies the first time somebody
	-- adds a third kind of hit.
	kind: string?,
	-- The floor on visible helplessness, in seconds from the moment this
	-- machine unwraps the packet.
	minLimp: number?,
	-- When to stop waiting and stand up, as an absolute Workspace server time.
	deadline: number?,
}

local function onThrown(dir: Vector3, speed: number, lift: number, clear: number,
	hold: number?, style: ThrowStyle?)
	-- Everything here came off the wire. A malformed packet should do nothing
	-- rather than throw inside an event handler and leave the flag stuck.
	-- Read once, here, so every use below is a plain local and no branch has to
	-- remember that `style` might be absent.
	local styleTable: any = if type(style) == "table" then style else nil
	local token: string? = if styleTable and type(styleTable.token) == "string"
		then styleTable.token
		else nil

	--==========================================================================
	-- A PACKET THIS FILE CANNOT USE STILL HAS TO BE ANSWERED
	--
	-- These returns used to be silent, and silence costs the victim a full
	-- backstop of lying on the floor: the server has already gone limp, and it
	-- waits for a report that is never coming. Quoting the token back says "not
	-- happening" in the only vocabulary the handshake has, and the server
	-- restores them on the next tick instead of on a timeout.
	--
	-- A guardian throw has no token, so this is a plain return for them, which
	-- is what it always was.
	--==========================================================================
	local function refuse(why: string)
		say(why)
		if remote and token then
			pcall(function()
				(remote :: RemoteEvent):FireServer(token)
			end)
		end
	end

	if typeof(dir) ~= "Vector3" or type(speed) ~= "number" or type(lift) ~= "number" then
		refuse("bad payload, ignoring")
		return
	end
	if dir.Magnitude <= 0 or speed ~= speed or speed <= 0 then
		refuse("bad direction or speed, ignoring")
		return
	end

	--==========================================================================
	-- THE NEWER LAUNCH TAKES THE BODY
	--
	-- Bumped BEFORE anything else happens, so a task already running sees a
	-- generation it does not recognise at its very next await and lets go
	-- without touching the pose, the camera or the flag.
	--==========================================================================
	generation += 1
	local myGen = generation
	local function superseded(): boolean
		return generation ~= myGen
	end
	throwing = true

	local stepUp = 3
	local wantCamera = true
	local tumbleScale = 1
	if styleTable then
		local u = tonumber(styleTable.up)
		if u and u == u and u >= 0 then
			stepUp = u
		end
		if styleTable.camera == false then
			wantCamera = false
		end
		local t = tonumber(styleTable.tumble)
		if t and t == t and t >= 0 then
			tumbleScale = t
		end
	end

	--==========================================================================
	-- WHEN THIS ONE HAS TO BE OVER
	--
	-- Two instants, measured differently on purpose.
	--
	-- THE FLOOR IS MEASURED HERE, on this machine, from the moment the packet is
	-- unwrapped -- because it is a floor on what the VICTIM SEES, and what they
	-- see starts when their own machine starts drawing it. Measuring it from a
	-- server instant would make a laggy player's hit look shorter than a local
	-- one's, which is backwards.
	--
	-- THE DEADLINE IS SERVER TIME, converted once, here. It has to be: it is one
	-- half of an agreement with a backstop running on another machine, and a
	-- duration would start counting after the wire time -- which is exactly the
	-- error the agreement exists to absorb. Both sides read the same clock, so
	-- both sides mean the same instant.
	--
	-- CLAMPED, because it came off the wire. A deadline already in the past
	-- would stand the body up on the frame it was launched; one an hour out
	-- would be the five-second give-up under a new name. The floor is generous
	-- enough to still show a launch and the ceiling is the guardian give-up.
	--==========================================================================
	local hitAt = os.clock()
	local minStandAt: number? = nil
	local forcedStandAt: number? = nil
	if styleTable then
		local m = tonumber(styleTable.minLimp)
		if m and m == m and m >= 0 then
			minStandAt = hitAt + m
		end
		local d = tonumber(styleTable.deadline)
		if d and d == d then
			local remaining = d - workspace:GetServerTimeNow()
			forcedStandAt = hitAt + math.clamp(remaining, 0.35, GIVE_UP_AFTER)
		end
	end

	local flat = Vector3.new(dir.X, 0, dir.Z)
	local unit = if flat.Magnitude > 0 then flat.Unit else Vector3.new(0, 0, 1)
	local impulse = unit * speed + Vector3.new(0, speed * lift, 0)
	say(string.format("HIT received: %s dir %s speed %.1f lift %.2f clear %.1f%s",
		if styleTable and type(styleTable.kind) == "string"
			then tostring(styleTable.kind)
			else "guardian",
		tostring(unit), speed, lift,
		if type(clear) == "number" then clear else -1,
		if forcedStandAt
			then string.format(" | up by %.2fs, no earlier than %.2fs",
				forcedStandAt - hitAt,
				if minStandAt then minStandAt - hitAt else 0)
			else ""))

	task.spawn(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = rootOf()
		if not (humanoid and root) then
			refuse("no character to throw")
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
		character:PivotTo(character:GetPivot() + unit * step + Vector3.new(0, stepUp, 0))
		say(string.format("stepped %.1f studs clear (+%.1f up) along %s",
			step, stepUp, tostring(unit)))

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
		--==================================================================
		-- CAPTURED ONCE PER CHAIN, NOT ONCE PER HIT
		--
		-- See the banner on `pristine`: a second hit landing mid-tumble would
		-- otherwise record this file's own 12-stud zoom floor as the player's
		-- preference and give it back to them at the end.
		--==================================================================
		if not pristine then
			pristine = {
				mode = player.CameraMode,
				min = player.CameraMinZoomDistance,
				max = player.CameraMaxZoomDistance,
			}
		end
		local kept = pristine :: Pristine
		local wasMode = kept.mode
		local wasMin = kept.min
		local wasMax = kept.max
		--==================================================================
		-- A BAT DOES NOT TOUCH THE CAMERA
		--
		-- The three captures above still happen, because the restore at the
		-- end of this function is unconditional and putting back a value that
		-- was never captured is how a camera ends up stuck at a zoom floor.
		-- Only the WRITES are skipped: capturing and restoring the same three
		-- numbers is a no-op, and a no-op is the safest possible version of a
		-- branch that has to unwind.
		--==================================================================
		if wantCamera then
			if wasMode == Enum.CameraMode.LockFirstPerson then
				player.CameraMode = Enum.CameraMode.Classic
			end
			if player.CameraMaxZoomDistance < THROW_ZOOM then
				player.CameraMaxZoomDistance = THROW_ZOOM
			end
			player.CameraMinZoomDistance = math.max(wasMin, THROW_ZOOM)
			bindVisible()
		end

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
		-- Into `pristine` with the other three, and for the same reason: a
		-- second hit mid-tumble would capture the HEAD this file just pointed
		-- the camera at, and restore the player to it permanently.
		if camera and kept.subject == nil then
			kept.subject = camera.CameraSubject
		end
		local wasSubject: Instance? = kept.subject
		local headPart = character:FindFirstChild("Head")
		if wantCamera and camera and headPart and headPart:IsA("BasePart") then
			camera.CameraSubject = headPart
		end
		say(string.format("camera: mode %s -> %s | zoom %.1f..%.1f -> %.1f..%.1f | subject %s -> %s",
			tostring(wasMode), tostring(player.CameraMode), wasMin, wasMax,
			player.CameraMinZoomDistance, player.CameraMaxZoomDistance,
			tostring(wasSubject and wasSubject.Name),
			tostring(camera and camera.CameraSubject and camera.CameraSubject.Name)))

		--== 4. THE LAUNCH ==--
		local parts = bodyParts()
		local tumble = Vector3.new(math.random(-6, 6), math.random(-3, 3),
			math.random(-6, 6)) * tumbleScale
		local holdFor = if type(hold) == "number" and hold == hold and hold >= 0
			then hold
			else LEGACY_HOLD

		if holdFor > 0 then
			for _, part in ipairs(parts) do
				part:ApplyImpulse(impulse * part.AssemblyMass)
				part.AssemblyLinearVelocity = impulse
				part.AssemblyAngularVelocity = tumble
			end
			say(string.format("first velocity applied to %d parts: %s (%.1f studs/sec)",
				#parts, tostring(impulse), impulse.Magnitude))
		else
			--==============================================================
			-- ONE WRITE PER PART, AND EVERY PART IS ITS OWN ASSEMBLY
			--
			-- What was wrong with the loop above is not that it touches every
			-- part -- it has to. A ragdolled R15 character has had its Motor6Ds
			-- replaced with BallSocketConstraints, so the limbs are seventeen
			-- SEPARATE assemblies and the root's velocity moves the root alone.
			-- Setting it there and nowhere else was measured: the root flew its
			-- full 373 studs while the body it belongs to travelled a hundred,
			-- and ThrowFX had to drag the root back onto the torso.
			--
			-- What was wrong is ApplyImpulse ON TOP of the assignment. Impulse
			-- ADDS and the assignment SETS, so with a server that had already
			-- done both the body left at 467.6 and 291.9 out of a configured
			-- 235 and 141 -- exactly double -- and rose to an apex of 237. The
			-- number in the config was not the number the body got, so nothing
			-- downstream of it could be tuned.
			--
			-- So: every part, once, assignment only.
			--==============================================================
			for _, part in ipairs(parts) do
				part.AssemblyLinearVelocity = impulse
				part.AssemblyAngularVelocity = tumble
			end
			say(string.format("one impulse across %d parts: %s (%.1f studs/sec)",
				#parts, tostring(impulse), impulse.Magnitude))
		end

		if holdFor > 0 then
			-- The tested path, unchanged: hold the velocity outright.
			local holdUntil = os.clock() + holdFor
			while os.clock() < holdUntil do
				if superseded() then
					return
				end
				humanoid.PlatformStand = true
				for _, part in ipairs(bodyParts()) do
					part.AssemblyLinearVelocity = impulse
				end
				RunService.Heartbeat:Wait()
			end
			say(string.format("held the launch velocity for %.2fs", holdFor))
		else
			--==============================================================
			-- ONE IMPULSE. The watch below restores it only if the state
			-- machine wipes it, and never otherwise, so the flight is the
			-- parabola the server asked for and can be measured against it.
			--==============================================================
			--==============================================================
			-- THE GUARD FOLLOWS THE PARABOLA, NOT THE LAUNCH
			--
			-- Setting the velocity once is not enough on its own: the humanoid
			-- is still Running when it is set, and the state machine cancels the
			-- VERTICAL component on the next step while leaving the horizontal
			-- alone. Measured: a launch configured at 235 and 141 left at 234.7
			-- and 6.7, and the body slid forty studs along the floor.
			--
			-- The old hold fixed that by rewriting the whole velocity every
			-- frame, which also cancels gravity. This restores the velocity the
			-- launch SHOULD have at this instant -- impulse minus g*t -- so a
			-- correction puts the body back on its own arc instead of on a flat
			-- line, and a frame already on the arc is left alone.
			--==============================================================
			local guardUntil = os.clock() + CLEAN_GUARD
			local launchedAt = os.clock()
			local restored = 0
			local struck = false
			while os.clock() < guardUntil do
				if superseded() then
					return
				end
				humanoid.PlatformStand = true
				local r = character:FindFirstChild("HumanoidRootPart")
				if r and r:IsA("BasePart") then
					local flight = os.clock() - launchedAt
					local want = impulse - Vector3.new(0, workspace.Gravity * flight, 0)
					local have = r.AssemblyLinearVelocity

					--==================================================
					-- A WALL IS NOT THE STATE MACHINE, AND THE GUARD IS
					-- NOT ALLOWED TO ARGUE WITH ONE
					--
					-- To a magnitude test the two are the same event, and
					-- in the plane they are opposites. Measured, the state
					-- machine eats the VERTICAL and leaves the horizontal
					-- alone: 234.7 and 6.7 out of a launch of 235 and 141.
					-- A collision does the reverse -- it takes the
					-- horizontal, because the horizontal is the component
					-- that drove the body into the thing it hit.
					--
					-- Without this the guard reads a wall as interference
					-- and writes the full launch speed back into it, every
					-- frame for the rest of the window. That is how a part
					-- is pushed THROUGH geometry, and it puts back energy
					-- the collision had just taken out. It is reachable:
					-- the corridor walls are 46 studs and a 300/165 launch
					-- is still under them for the whole guard, at 40.7 when
					-- it ends, so anything thrown near a wall meets it
					-- while the guard is live.
					--
					-- Both wipe shapes still pass, because a wipe loses the
					-- vertical and a wall does not touch it.
					--==================================================
					local wantFlat = Vector3.new(want.X, 0, want.Z)
					local haveFlat = Vector3.new(have.X, 0, have.Z)
					local verticalOnArc = math.abs(have.Y - want.Y)
						<= math.abs(want.Y) * OFF_ARC_BY
					if verticalOnArc
						and haveFlat.Magnitude < wantFlat.Magnitude * (1 - OFF_ARC_BY) then
						struck = true
						break
					end

					if (have - want).Magnitude > want.Magnitude * OFF_ARC_BY then
						-- Every part again: they are separate assemblies, and a
						-- torso left behind is the 373-stud separation above.
						for _, part in ipairs(bodyParts()) do
							part.AssemblyLinearVelocity = want
						end
						restored += 1
					end
				end
				RunService.Heartbeat:Wait()
			end
			say(string.format("one impulse; put back on the arc %d time(s) in %.2fs%s",
				restored, CLEAN_GUARD,
				if struck then " (guard released early: hit something)" else ""))
		end

		--======================================================================
		-- 5. WAIT UNTIL THE BODY HAS FLOWN AND STOPPED
		--======================================================================
		local head = character:FindFirstChild("Head")
		local torso = torsoOf(character)
		local settledFor = 0
		local flightStart = os.clock()

		--======================================================================
		-- HOW LONG THIS IS ALLOWED TO TAKE
		--
		-- THIS LOOP IS WHERE THE BAT BUG LIVED. Its three constants are tuned
		-- for a guardian -- 0.9s of minimum flight, then 0.35s of stillness --
		-- so the earliest it could possibly break was 1.25 seconds after the
		-- guard ended, or about 1.55 from the hit. The server was restoring the
		-- rig at 1.1. It timed out on EVERY hit, and the two machines then
		-- fought over the body for the second it took this to finish.
		--
		-- Neither number was wrong. They were being asked to describe two
		-- different events: a guardian pitching you across a biome, and a player
		-- clubbing you two studs sideways. So the caller says now.
		--
		--   standNoEarlierThan   the floor. A bat lands almost immediately -- it
		--                        is a shove, not a flight -- and standing up the
		--                        instant it stops reads as a stumble rather than
		--                        a hit. So the floor is what actually produces
		--                        the visible second of helplessness, and it is
		--                        the ONLY thing in this file that does.
		--   mustStandBy          the ceiling, from the server's own clock. The
		--                        body stands up here wherever it is.
		--
		-- A GUARDIAN GETS EXACTLY WHAT IT GOT. No style means no floor and no
		-- deadline, so both fall back to the two lines under them -- the same
		-- 0.9 measured from the same flightStart, and the same GIVE_UP_AFTER.
		-- The arithmetic below is identical for them, variable names aside.
		--======================================================================
		local standNoEarlierThan = minStandAt or (flightStart + 0.9)
		local mustStandBy = forcedStandAt or (flightStart + GIVE_UP_AFTER)
		local settleHold = if forcedStandAt then 0.16 else SETTLE_HOLD
		local forced = false

		while true do
			if superseded() then
				return
			end
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

			-- Nothing counts as settled before the floor, however still the body
			-- is: a bat hit that ended the moment the body stopped moving would
			-- be over before the player registered it had started.
			if os.clock() >= standNoEarlierThan then
				if bodySpeed < SETTLE_SPEED then
					settledFor += SETTLE_STEP
					if settledFor >= settleHold then
						break
					end
				else
					settledFor = 0
				end
			end

			--==================================================================
			-- AND THE DEADLINE IS CHECKED AFTER THE SETTLE, NOT INSTEAD OF IT
			--
			-- A body that has genuinely come to rest should stand up because it
			-- has stopped, not because a clock ran out -- the two are the same
			-- pose but only one of them is worth reporting. `forced` is what
			-- separates them in the log.
			--==================================================================
			if os.clock() >= mustStandBy then
				forced = true
				break
			end
			task.wait(SETTLE_STEP)
		end
		say(string.format("settled after %.2fs%s", os.clock() - hitAt,
			if forced then " (forced: hit the deadline)" else ""))

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
		--==================================================================
		-- AND IT NAMES THE LAUNCH IT IS ANSWERING
		--
		-- Nil for a guardian, which is the report NestService has always taken
		-- and still takes -- its handler reads no arguments. CombatService
		-- requires a string that matches the launch that player is actually in,
		-- so this can only ever end the throw it belongs to.
		--==================================================================
		if remote then
			pcall(function()
				(remote :: RemoteEvent):FireServer(token)
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
			-- A hit landing while this is pinning the pose owns the body from
			-- that moment. Pinning it against a live launch is the one thing
			-- that would look exactly like the bug this file just fixed.
			if superseded() then
				return
			end
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
		--
		-- NINE LINES OF IT, AND A BAT DOES NOT GET THEM. This is a diagnostic
		-- for a throw that happens once a raid; a bat hit happens every few
		-- seconds in a fight, from every player at once, and nine prints each is
		-- how a console stops being readable at the exact moment somebody needs
		-- to read it. The measurement that matters for a bat -- how long the
		-- body was actually down -- is one line, and it is below.
		--
		-- It also ends the throw a second sooner, which is worth having on its
		-- own: `throwing` is what a preempting hit has to work around, and the
		-- less time it is true for reasons that are purely cosmetic, the less
		-- often anything has to be preempted at all.
		--======================================================================
		if not forcedStandAt then
			local watchUntil = os.clock() + STANDUP_WATCH
			while os.clock() < watchUntil do
				if superseded() then
					return
				end
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
		end

		--======================================================================
		-- THE LAST THROW OF A CHAIN PUTS THE CAMERA BACK
		--
		-- A superseded task has already returned long before here; this check
		-- catches the one remaining case -- a hit that arrived during the last
		-- few lines -- and leaves the camera to the launch that is now live.
		-- Restoring it here would hand the player their zoom back in the middle
		-- of a tumble.
		--======================================================================
		if superseded() then
			return
		end
		player.CameraMinZoomDistance = wasMin
		player.CameraMaxZoomDistance = wasMax
		player.CameraMode = wasMode
		pristine = nil
		unbindVisible()

		throwing = false
		say(string.format("done, told the server -- down for %.2fs", os.clock() - hitAt))
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
	--==========================================================================
	-- A RESPAWN CANCELS WHATEVER WAS RUNNING
	--
	-- Bumping the generation is what actually stops it. Clearing `throwing`
	-- alone never did: the task was not reading that flag, it was reading the
	-- character it had captured -- which is now a destroyed model it would go on
	-- pivoting, pinning and standing up for another second and a half.
	--
	-- `pristine` goes with it. A player who died mid-tumble has a camera the
	-- engine has already rebuilt around their new character, and handing them
	-- the old body's zoom floor is a setting they never chose.
	--==========================================================================
	generation += 1
	throwing = false
	pristine = nil
	restOffset = nil
	unbindVisible()
	captureRest(character)
end)

local existing = player.Character
if existing then
	captureRest(existing)
end
