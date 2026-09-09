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

--==============================================================================
-- WAITING FOR THE BODY TO ACTUALLY BE LIMP BEFORE THROWING IT
--
-- This is the bug two real players found, and it is a RACE nothing in this file
-- could see from one machine.
--
-- CombatService disables the fifteen AnimationConstraints and then fires this
-- remote in the same frame. Those are two different channels -- a property
-- replication and a RemoteEvent -- and nothing orders them. The event usually
-- wins. So the impulse was landing on a rig the animator was still holding in
-- its standing pose: one rigid assembly, posed, upright. It slid. It did not
-- fall, it did not tumble, and the clock then stood it up.
--
-- WHY THE GUARDIAN NEVER SHOWED THIS. Its legacy branch re-writes the velocity
-- every frame for 0.35 seconds, so by the time the constraints arrive it is
-- still being pushed and goes limp mid-flight; and its settle is a second
-- longer again. The guardian was absorbing the race, not avoiding it.
--
-- So a bat waits -- briefly, and on evidence rather than on a sleep. Measured
-- in a real session and printed on every hit, because if this ever starts
-- timing out the symptom is exactly the one that was rejected.
local RAGDOLL_READY_TIMEOUT = 0.4

--==============================================================================
-- WHAT COUNTS AS HAVING LANDED
--
-- SETTLE_SPEED alone was never enough, and on a bat it was actively wrong: a
-- body that has not been launched at all is also below it.
--
--   GROUND_PROBE   how far under the visible torso to look for floor. Generous,
--                  because a body on its side sits lower than one on its back.
--   FALLEN_UP      the torso's up-vector against world up. 1.00 is standing;
--                  this is about 57 degrees off vertical, which no standing rig
--                  reaches and every fallen one passes through.
--   LANDING_STEP   how often the landing is polled. Finer than SETTLE_STEP: it
--                  is looking for a CONTACT, and a contact can be missed.
local GROUND_PROBE = 3.0
local FALLEN_UP = 0.55
local LANDING_STEP = 0.05

--==============================================================================
-- A BAT HIT IS GUARANTEED TO TOPPLE THE BODY
--
-- This is the second thing two players were seeing, and it took measuring all
-- six bats to find it. The random tumble is built from `math.random(-6, 6)`,
-- which is an INTEGER draw -- so both of the axes that tip a standing body can
-- come out ZERO, or near it, on the same hit.
--
-- A guardian never noticed. It throws hard enough and high enough that the body
-- is airborne and rotating whatever the draw was. A bat with a flat launch has
-- nothing else to tip it, and the Cactus Club has the lowest lift on the shelf
-- at 0.35. Measured, that combination produced:
--
--     cactus_club   touched down 0.63s, lowest torso up 0.86, EMERGENCY at 3.02s
--
-- 0.86 is a body still standing. It went limp, it slid eighteen studs along the
-- ground on its feet, and it never fell over -- so the landing test correctly
-- refused to call it a landing and waited for the emergency. The old code did
-- not refuse: it stood the body up at 1.1s and called it a hit, which is
-- precisely the report.
--
-- So the spin about the horizontal axes is no longer a draw that can be zero.
-- It is a random DIRECTION with a guaranteed MAGNITUDE, which is what a topple
-- actually needs. 8 to 12 radians a second is one and a bit revolutions -- past
-- horizontal inside a fifth of a second, from any starting pose.
--
-- IT DOES NOT MOVE THE BODY. Angular velocity is not linear velocity; the
-- measured travel is unchanged (rootwood 11.8 -> 12.0 studs), so the locked
-- power ladder and launch distances are untouched.
--
-- GUARDIANS KEEP THE INTEGER DRAW. Their tuning is signed off and their throws
-- do not depend on it.
local TOPPLE_MIN = 8
local TOPPLE_MAX = 12
-- A body that landed and stayed grounded and slow but never went past FALLEN_UP
-- has slid rather than fallen. It should not happen now, and if it does this
-- bounds it well short of the emergency instead of leaving somebody sliding for
-- three seconds.
local SLIDE_GRACE = 0.6

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
-- IS THIS RIG ACTUALLY LIMP YET, ON THIS MACHINE?
--
-- Two questions, and the second one is the one that matters.
--
-- THE PROPERTY: every AnimationConstraint disabled. That is what the server
-- did, and it is what has to arrive here.
--
-- THE PHYSICAL TRUTH: the rig has come APART into separate assemblies. This
-- file's own banner measured it -- a posed R15 is one assembly, and the moment
-- the fifteen constraints go off it is sixteen, one part each. So a torso whose
-- AssemblyRootPart is still the HumanoidRootPart is a torso that is still being
-- held in the standing pose, whatever any property says.
--
-- Both are checked because they can disagree in the frame between: the property
-- can be through while the physics assembly has not yet been rebuilt, and
-- throwing on that frame is throwing a rigid body.
--==============================================================================
local function ragdollState(character: Model): (boolean, number, number, boolean)
	local total, off = 0, 0
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("AnimationConstraint") then
			total += 1
			if not d.Enabled then
				off += 1
			end
		end
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local split = false
	if root and root:IsA("BasePart") and torso and torso:IsA("BasePart") then
		split = torso.AssemblyRootPart ~= root.AssemblyRootPart
	end
	-- A rig with no AnimationConstraints at all is a classic Motor6D one, which
	-- ragdollOn deliberately leaves jointed -- it tumbles rigidly and that is
	-- the documented behaviour, so there is nothing here to wait for.
	local ready = (total == 0) or (off >= total and split)
	return ready, off, total, split
end

--==============================================================================
-- AND HAS IT LANDED?
--
-- Ground contact is a downward ray from the VISIBLE TORSO, not from the root
-- and not from the humanoid. The root is an invisible box that flies off on its
-- own while limp -- measured at 148 studs of separation -- and Humanoid
-- FloorMaterial reads nothing useful in the Physics state. The torso is the
-- thing the player is watching hit the floor, so it is the thing that is asked.
--==============================================================================
local function landingState(character: Model): (boolean, number)
	local torso = torsoOf(character)
	if not (torso and torso.Parent) then
		return false, 1
	end
	local up = torso.CFrame.UpVector:Dot(Vector3.yAxis)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	local hit = workspace:Raycast(torso.Position, Vector3.new(0, -GROUND_PROBE, 0), params)
	return hit ~= nil, up
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
	-- THE TERMS OF THIS LANDING
	--
	-- `forcedStandAt` used to be a DEADLINE: the moment this file stopped
	-- waiting and stood the body up wherever it was. Two real players rejected
	-- exactly that. A clock started at the hit does not know whether the victim
	-- has fallen, and it expired just as happily on one who never did.
	--
	-- It is EMERGENCY containment now. What ends a bat ragdoll is the landing --
	-- see the loop below -- and these three only bound it:
	--
	--   minStandAt    the floor, measured HERE on this machine, from the moment
	--                 the packet is unwrapped, because it is a floor on what the
	--                 VICTIM SEES and what they see starts when their own
	--                 machine starts drawing it.
	--   groundHold    how long the body stays limp after it TOUCHES DOWN. Not an
	--                 instant, because the instant is not known yet: it starts
	--                 at a contact that has not happened.
	--   emergencyAt   server time, converted once, here. It has to be server
	--                 time: it is one half of an agreement with a backstop on
	--                 another machine, and a duration would start counting after
	--                 the wire time, which is the error the agreement absorbs.
	--
	-- CLAMPED, because it came off the wire. Its floor is generous enough that a
	-- body always has time to fall, and its ceiling is the guardian give-up.
	--==========================================================================
	local hitAt = os.clock()
	local minStandAt: number? = nil
	local groundHold = 0
	local emergencyAt: number? = nil
	if styleTable then
		local m = tonumber(styleTable.minLimp)
		if m and m == m and m >= 0 then
			minStandAt = hitAt + m
		end
		local g = tonumber(styleTable.groundHold)
		if g and g == g and g >= 0 then
			groundHold = g
		end
		local e = tonumber(styleTable.emergency)
		if e and e == e then
			local remaining = e - workspace:GetServerTimeNow()
			emergencyAt = hitAt + math.clamp(remaining, 1.0, GIVE_UP_AFTER)
		end
	end
	-- One discriminator, read once. Everything a bat does differently hangs off
	-- this, and a guardian -- which sends no style at all -- never sets it.
	local isBat = emergencyAt ~= nil

	local flat = Vector3.new(dir.X, 0, dir.Z)
	local unit = if flat.Magnitude > 0 then flat.Unit else Vector3.new(0, 0, 1)
	local impulse = unit * speed + Vector3.new(0, speed * lift, 0)
	say(string.format("HIT received: %s dir %s speed %.1f lift %.2f clear %.1f%s",
		if styleTable and type(styleTable.kind) == "string"
			then tostring(styleTable.kind)
			else "guardian",
		tostring(unit), speed, lift,
		if type(clear) == "number" then clear else -1,
		if emergencyAt
			then string.format(" | floor %.2fs, ground hold %.2fs, emergency %.2fs",
				if minStandAt then minStandAt - hitAt else 0,
				groundHold, emergencyAt - hitAt)
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

		--==================================================================
		-- 1b. AND WAIT FOR THE BODY TO ACTUALLY BE LIMP
		--
		-- The race described at RAGDOLL_READY_TIMEOUT: the server disables the
		-- constraints and fires this remote in the same frame, on two channels
		-- nothing orders, and the event usually wins. Launching there throws a
		-- rigid standing avatar, which is what the owner saw and rejected.
		--
		-- BAT ONLY, DELIBERATELY. A guardian is not gated, because a guardian
		-- was never broken: its 0.35s velocity hold keeps pushing the body until
		-- long after the constraints arrive, so it goes limp mid-flight on its
		-- own. Adding a wait there would change tuning that is signed off, to
		-- fix a problem it does not have.
		--
		-- ON TIMEOUT IT LAUNCHES ANYWAY, and that is safe rather than a
		-- compromise: the constraints are already on their way -- the server set
		-- them before it sent this -- so the body goes limp a moment into the
		-- flight, exactly as a guardian's does. Recovery waits for a real
		-- landing regardless, so a late limp still produces a real fall. The
		-- wait makes the hit TIGHTER; the landing loop is what makes it CORRECT.
		--==================================================================
		local readyAfter = 0
		if isBat then
			local waitUntil = os.clock() + RAGDOLL_READY_TIMEOUT
			local ready, off, total, split = ragdollState(character)
			while not ready and os.clock() < waitUntil do
				if superseded() then
					return
				end
				RunService.Heartbeat:Wait()
				ready, off, total, split = ragdollState(character)
			end
			readyAfter = os.clock() - hitAt
			say(string.format(
				"ragdoll ready after %.3fs: %d/%d constraints off, rig %s%s",
				readyAfter, off, total,
				if split then "split into loose assemblies" else "STILL ONE ASSEMBLY",
				if ready then "" else "  <- TIMED OUT, launching a body that is not limp yet"))
		end

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
		--==================================================================
		-- THE SPIN THAT PUTS THEM ON THE FLOOR
		--
		-- See the TOPPLE_MIN banner: the guardian's integer draw can be zero on
		-- both tipping axes, and a bat has no lift to spare when it is.
		--==================================================================
		local tumble
		if isBat then
			local axis = math.random() * math.pi * 2
			local tip = TOPPLE_MIN + math.random() * (TOPPLE_MAX - TOPPLE_MIN)
			tumble = Vector3.new(
				math.cos(axis) * tip,
				math.random(-3, 3),
				math.sin(axis) * tip) * tumbleScale
		else
			tumble = Vector3.new(math.random(-6, 6), math.random(-3, 3),
				math.random(-6, 6)) * tumbleScale
		end
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
		--   standNoEarlierThan   the floor. Even a body that lands instantly is
		--                        held down to here, so a hit reads as a hit.
		--   mustStandBy          the ceiling. For a guardian this is the
		--                        five-second give-up it has always had; for a
		--                        bat it is EMERGENCY containment and reaching it
		--                        means the landing was never detected.
		--
		-- A GUARDIAN GETS EXACTLY WHAT IT GOT. No style means no floor, no
		-- ground hold and no emergency, so `isBat` is false, every branch below
		-- falls through to the constants under it -- the same 0.9 from the same
		-- flightStart, the same SETTLE_HOLD, the same GIVE_UP_AFTER -- and the
		-- arithmetic is identical, variable names aside.
		--======================================================================
		local standNoEarlierThan = minStandAt or (flightStart + 0.9)
		local mustStandBy = emergencyAt or (flightStart + GIVE_UP_AFTER)
		local emergency = false

		--======================================================================
		-- A BAT RECOVERS FROM A LANDING. IT DOES NOT RECOVER FROM A CLOCK.
		--
		-- This is the whole repair, and it is here because this loop is where
		-- the rejected behaviour actually came from. It used to break on "the
		-- body is slow" plus "a deadline passed", and BOTH of those are true of
		-- a victim who never fell over: a rigid standing avatar is slow, and the
		-- deadline arrives regardless.
		--
		-- So four things have to have HAPPENED, and none of them is a duration:
		--
		--   touched   a downward ray from the visible torso found floor. Not the
		--             root -- while limp the root is an invisible box that flies
		--             off on its own, measured once at 148 studs away, and it is
		--             not what the player watched land.
		--   fell      the torso's up-vector went past FALLEN_UP at some point.
		--             Tracked as the LOWEST value reached rather than sampled at
		--             the end, because a body can land hard, roll, and come to
		--             rest half-propped against a wall -- it fell, and the frame
		--             it settles on does not say so.
		--   held      it stayed down for the ground hold, timed from the CONTACT
		--             and not from the hit, because the contact is the moment the
		--             player sees. This is what makes it read as a knockdown
		--             rather than a stumble.
		--   slow      still true, still necessary, no longer sufficient.
		--
		-- A GUARDIAN SKIPS ALL OF IT and keeps the old two-term test, because
		-- the old test describes the guardian correctly and its tuning is signed
		-- off. `isBat` is the only gate.
		--======================================================================
		local touchedAt: number? = nil
		local lowestUp = 1
		local landedSpeed = -1
		local slid = false

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

			if isBat then
				local touching, up = landingState(character)
				lowestUp = math.min(lowestUp, up)
				if touching and touchedAt == nil and bodySpeed < SETTLE_SPEED * 3 then
					-- First contact. Recorded once: a body that bounces has
					-- still landed, and restarting the hold on every bounce
					-- would let a lively tumble run to the emergency.
					touchedAt = os.clock()
					landedSpeed = bodySpeed
					say(string.format(
						"touched down %.2fs after the hit, at %.1f studs/sec, torso up %.2f",
						touchedAt - hitAt, bodySpeed, up))
				end
				local restedFor = if touchedAt then os.clock() - touchedAt else 0
				local heldLongEnough = touchedAt ~= nil
					and restedFor >= groundHold
					and os.clock() >= standNoEarlierThan
				if heldLongEnough and touching and bodySpeed < SETTLE_SPEED then
					if lowestUp <= FALLEN_UP then
						break
					elseif restedFor >= groundHold + SLIDE_GRACE then
						--======================================================
						-- IT LANDED WITHOUT FALLING OVER
						--
						-- With a guaranteed topple this should be unreachable,
						-- and it is kept because "should be unreachable" is
						-- exactly what was assumed about the shove. A body
						-- wedged upright against a wall is grounded, slow, and
						-- never past FALLEN_UP -- and standing it up here is
						-- both better than three seconds of sliding and worth
						-- knowing about.
						--======================================================
						slid = true
						break
					end
				end
			else
				-- The guardian test, unchanged.
				if os.clock() >= standNoEarlierThan then
					if bodySpeed < SETTLE_SPEED then
						settledFor += SETTLE_STEP
						if settledFor >= SETTLE_HOLD then
							break
						end
					else
						settledFor = 0
					end
				end
			end

			--==================================================================
			-- AND THE CEILING IS CHECKED AFTER, NOT INSTEAD OF
			--
			-- A body that has genuinely landed should get up because it landed,
			-- not because a clock ran out -- the two produce the same pose but
			-- only one of them is worth reporting. For a bat, reaching this is a
			-- FAILURE and is logged as one.
			--==================================================================
			if os.clock() >= mustStandBy then
				emergency = true
				break
			end
			task.wait(if isBat then LANDING_STEP else SETTLE_STEP)
		end

		if isBat then
			say(string.format(
				"LANDING: ready %.2fs | touched %s | lowest torso up %.2f | %s after %.2fs",
				readyAfter,
				if touchedAt then string.format("%.2fs at %.1f/sec",
					touchedAt - hitAt, landedSpeed) else "NEVER",
				lowestUp,
				if emergency then "EMERGENCY RECOVERY"
					elseif slid then "landed WITHOUT toppling -- slid upright"
					else "settled naturally",
				os.clock() - hitAt))
			if slid then
				warn(string.format("[Seed/ThrowFX] the body never fell over " ..
					"(lowest torso up %.2f). It slid upright and was stood up " ..
					"after %.2fs.", lowestUp, os.clock() - hitAt))
			end
			if emergency then
				--==============================================================
				-- CONTAINMENT, NOT ANIMATION
				--
				-- Reaching here means the body never landed, never fell, or
				-- never went limp -- and the recovery below is written to be
				-- safe in all three: it zeroes the velocities, finds real ground
				-- under the VISIBLE torso, seats the root there and stands the
				-- body on it. Nothing about that assumes a fall happened.
				--
				-- It is a warn rather than a print because a bat reaching its
				-- emergency is the symptom the owner rejected, and it must not
				-- be something a person has to go looking for.
				--==============================================================
				warn(string.format("[Seed/ThrowFX] emergency recovery after %.2fs " ..
					"-- touched %s, lowest up %.2f. The body did not land.",
					os.clock() - hitAt, tostring(touchedAt ~= nil), lowestUp))
			end
		else
			say(string.format("settled after %.2fs%s", os.clock() - hitAt,
				if emergency then " (forced: hit the give-up)" else ""))
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
		if not isBat then
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
