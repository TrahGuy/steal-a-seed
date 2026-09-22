--!strict
-- Steal a Seed :: RagdollGate
--
-- Whether a character is actually limp on THIS machine, and a bounded wait for
-- it. ThrowFX asks before every launch -- a guardian's and a bat's alike -- and
-- only launches a body this has seen come apart.
--
--==============================================================================
-- WHY THIS IS ITS OWN MODULE
--
-- It used to be `ragdollState`, a local inside ThrowFX, asked by the bat path
-- only. The guardian path skipped it on the theory that its 0.35 s velocity hold
-- "absorbed the race" between the server disabling the constraints and the
-- ThrowVictim remote arriving. Reported from a published server 2026-09-22: the
-- guardian hit knocks the player away, and the body stays rigid. A rule that
-- decides whether a throw is allowed to start has to be something a spec can
-- drive, so it lives here now and ThrowFX calls it.
--
--==============================================================================
-- WHAT COUNTS AS LIMP
--
-- THE PROPERTY: every AnimationConstraint disabled. That is what the server's
-- ragdollOn did, and it is what has to have arrived here.
--
-- THE PHYSICAL TRUTH: the rig has come apart. A posed R15 is one assembly; with
-- the fifteen constraints off it is sixteen, one part each. The old test only
-- asked whether the torso had left the HumanoidRootPart's assembly -- which is
-- also true of a rig that let go of the Root joint and nothing else: a rigid
-- mannequin with its invisible box floating away. So the torso must be apart
-- from the root AND from every limb that exists.
--
-- Both are checked because they can disagree in the frame between: the property
-- can be through while the physics assembly has not yet been rebuilt, and
-- launching on that frame is launching a rigid body.
--
-- A RIG THIS CANNOT LOOSEN IS NEVER "READY". One with no AnimationConstraints
-- is a classic Motor6D rig (or not a character at all), which ragdollOn leaves
-- jointed. This used to call that ready at once -- zero of zero constraints
-- off -- so a Motor6D body would fly rigid while every log line said ragdoll.
-- Now `supported` is false, the wait returns immediately rather than spending
-- its timeout on something that cannot happen, and ThrowFX says plainly that it
-- launched a body it could not loosen. The published game's avatars are
-- AnimationConstraint rigs (measured live 2026-09-22: 15 of 15 off, 16
-- assemblies), so this is the honest answer for a rig it does not have.
--==============================================================================

local RagdollGate = {}

-- The parts that must each be out of the torso's assembly for the limbs to be
-- loose. A rig missing one is not held back by it.
RagdollGate.Limbs = { "Head", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }

export type State = {
	ready: boolean,
	-- "animation" (the AnimationConstraint rig ragdollOn loosens), "motor6d"
	-- (a classic rig it leaves jointed) or "none". Only the first is supported.
	rig: string,
	supported: boolean,
	motors: number,
	-- AnimationConstraints disabled, and how many there are.
	off: number,
	total: number,
	-- The torso's assembly holds neither the root nor any limb.
	split: boolean,
	-- Distinct assemblies among the character's own BaseParts.
	assemblies: number,
	-- BallSocketConstraints still carrying joint friction.
	gripping: number,
}

--==============================================================================
-- `needFree`: A GUARDIAN'S THROW ALSO WAITS FOR THE JOINTS TO LET GO
--
-- NestService zeroes every ball socket's MaxFrictionTorque for a guardian throw
-- in the same frame it disables the constraints (see its LOOSE MEANS LOOSE):
-- the engine builds those sockets with friction, and with it on, loose joints
-- still hold each limb where it was. Measured on one hit of four, the client's
-- first limp frame had 55 of the 421 friction still to arrive -- so a guardian
-- launch asks for it too. A bat's knockdown keeps its friction and does not.
--==============================================================================
function RagdollGate.state(character: Model, needFree: boolean?): State
	local total, off, gripping, motors = 0, 0, 0, 0
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("AnimationConstraint") then
			total += 1
			if not d.Enabled then
				off += 1
			end
		elseif d:IsA("BallSocketConstraint") and d.MaxFrictionTorque > 0 then
			gripping += 1
		elseif d:IsA("Motor6D") then
			motors += 1
		end
	end
	local rig = if total > 0 then "animation" elseif motors > 0 then "motor6d" else "none"
	local supported = rig == "animation"

	local seen: { [BasePart]: boolean } = {}
	local assemblies = 0
	for _, d in ipairs(character:GetChildren()) do
		if d:IsA("BasePart") then
			local r = d.AssemblyRootPart
			if r and not seen[r] then
				seen[r] = true
				assemblies += 1
			end
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local split = false
	if root and root:IsA("BasePart") and torso and torso:IsA("BasePart") then
		local torsoRoot = torso.AssemblyRootPart
		split = torsoRoot ~= nil and torsoRoot ~= root.AssemblyRootPart
		if split then
			for _, name in ipairs(RagdollGate.Limbs) do
				local limb = character:FindFirstChild(name)
				if limb and limb:IsA("BasePart") and limb.AssemblyRootPart == torsoRoot then
					split = false
					break
				end
			end
		end
	end

	return {
		ready = supported and off >= total and split and (not needFree or gripping == 0),
		rig = rig,
		supported = supported,
		motors = motors,
		off = off,
		total = total,
		split = split,
		assemblies = assemblies,
		gripping = gripping,
	}
end

--==============================================================================
-- THE WAIT: ON EVIDENCE, BOUNDED, CANCELLABLE
--
-- Polls `state` once per `step` until it is ready or `timeout` seconds of `now`
-- have passed. `cancelled` ends it early -- a newer launch has taken the body --
-- and says so in the third return, so the caller can let go without launching.
--
-- The clock and the step are parameters so a spec can run the whole wait on a
-- fake clock against a real rig; ThrowFX passes os.clock and a Heartbeat.
--==============================================================================
function RagdollGate.await(character: Model, timeout: number, step: () -> (),
	now: () -> number, cancelled: (() -> boolean)?, needFree: boolean?): (State, number, boolean)
	local started = now()
	local s = RagdollGate.state(character, needFree)
	-- An unsupported rig will not come apart however long this waits.
	while not s.ready and s.supported and now() - started < timeout do
		if cancelled and cancelled() then
			return s, now() - started, true
		end
		step()
		s = RagdollGate.state(character, needFree)
	end
	return s, now() - started, false
end

return RagdollGate
