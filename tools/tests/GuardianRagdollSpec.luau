--!strict
--==============================================================================
-- Steal a Seed :: GuardianRagdollSpec
--
-- A guardian throw must never start on a body that has not come loose. Run with
-- the shared runner, Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("GuardianRagdollSpec"))
--
-- WHAT IT STANDS ON. Reported from a published server 2026-09-22: a guardian hit
-- knocked the player away and the body stayed rigid. Measured on the victim's
-- machine, the rig had come apart (sixteen assemblies, every constraint off) and
-- still flew as a mannequin, for two reasons this spec pins:
--
--   the joints    the engine builds the R15 BallSocketConstraints WITH friction
--                 (14.7 to 52.3), which held every limb where it was. The
--                 guardian throw now zeroes it (NestService.SlackenJoints) and
--                 ragdollOff gives it back, once.
--   the gate      the guardian path launched without asking whether the rig was
--                 loose -- only bats waited. RagdollGate is now asked by every
--                 launch, and for a guardian it also waits for the friction.
--
-- AND THEN THE LIVE ONE, the same day, after both of those had shipped: on a
-- published server the loose body was simulated by the SERVER, not by the
-- victim who launched it -- measured in Studio, every new body assembly starts
-- out server-owned the frame the constraints go off. ragdollOn now pins the body
-- to its player (Play-verified; Edit has no Player, so this spec pins the code
-- that does it and the bookkeeping around it).
--
-- SIX LAYERS, all against REAL rigs built here -- Edit mode maintains
-- assemblies for AnimationConstraints, so disabling one really splits the rig:
--
--   RULE      RagdollGate.state on that rig, including the case the old rule
--             passed (a rig that let go of its Root joint and nothing else) and
--             the one it passed vacuously: a rig with NO AnimationConstraints --
--             Motor6D or none at all -- is unsupported and never "ready".
--   WAIT      RagdollGate.await on a fake clock, where the test decides the
--             step on which the rig comes apart. It must not report ready one
--             step sooner, must time out honestly, must let go when a newer
--             launch cancels it, and must not wait at all on a rig it cannot
--             loosen.
--   JOINTS    The shipped NestService's RagdollOn / SlackenJoints / RagdollOff
--             round trip: friction to zero, then back to the exact values,
--             exactly once; a bat's record never touches friction; the rig is
--             registered limp exactly while it is, and a rig no player owns is
--             never pinned.
--   ANSWERS   NestService.ThrowAnswerMatches: only the waiting throw's own
--             token ends it -- not a stale one, a duplicate, a bat's or none.
--   ORDER     ThrowFX's and NestService's own source, kept to the lines that
--             ARE the regressions: the launch after the gate, the pin inside
--             ragdollOn, the token on the guardian's launch and its answer, the
--             refusal to throw a body that is already limp, and no server
--             takeover of the body anywhere.
--
-- AND THE ONE THE OWNER RECORDED 2026-09-26, reproduced in Studio 2026-09-28: a
-- frictionless, non-colliding head circling the neck over a body that lay
-- still, the camera on it, and every live knockdown running to the give-up.
--
--   LYING DOWN  the sixth layer. The neck gets its captured friction back on the
--               victim's landing report and nothing else does; that report is
--               taken only from the player who was thrown, only during their
--               own waiting throw, once, and never ends it; a guardian's rest
--               is judged on the torso and the pelvis whatever the head is
--               doing; the camera follows the torso, then the root, then the
--               head; the three numbers that time a knockdown are the ones
--               they were; and none of it reaches a bat's or a trap's
--               knockdown.
--
-- NOT HERE, measured in Play instead (see KB/HANDOFF.md): who owns the body in
-- flight, the limbs actually swinging, the torso tumbling, the landing and the
-- stand-up, and the head coming to rest once the neck grips.
--==============================================================================
local Workspace = game:GetService("Workspace")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local RagdollGate = require(Shared.RagdollGate)
local WeaponData = require(Shared.WeaponData)
local NestService = require(game:GetService("ServerScriptService").SeedGameServer.NestService)

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string, detail: any?)
	if ok then
		pass += 1
	else
		table.insert(fails, label .. if detail ~= nil then " (" .. tostring(detail) .. ")" else "")
	end
end

--==============================================================================
-- THE RIG: the parts and seams RagdollGate and ragdollOn look at
--==============================================================================
local fixture = Instance.new("Folder")
fixture.Name = "GuardianRagdollSpecFixture"
fixture.Parent = Workspace

-- The engine's own numbers for these joints, read off a live character.
local FRICTION = { Waist = 43.7, Neck = 40.9, LeftShoulder = 18.8, RightShoulder = 18.8,
	LeftHip = 14.7, RightHip = 14.7 }

-- "constraints" is the AnimationConstraint + BallSocket rig the published game
-- spawns; "motors" is a classic Motor6D rig; "welds" is a model with neither.
local function buildRig(kind: string): Model
	local withConstraints = kind == "constraints"
	local rig = Instance.new("Model")
	rig.Name = "SpecRig"
	local function part(name: string, size: Vector3, at: Vector3, invisible: boolean?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = Vector3.new(0, 900, 0) + at
		p.Anchored = false
		p.CanCollide = name == "UpperTorso" or name == "LowerTorso" or name == "HumanoidRootPart"
		p.Transparency = if invisible then 1 else 0
		p.Parent = rig
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), true)
	local lower = part("LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.8, 0))
	local upper = part("UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.2, 0))
	local head = part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0))
	local larm = part("LeftUpperArm", Vector3.new(1, 1.4, 1), Vector3.new(-1.5, 0.3, 0))
	local rarm = part("RightUpperArm", Vector3.new(1, 1.4, 1), Vector3.new(1.5, 0.3, 0))
	local lleg = part("LeftUpperLeg", Vector3.new(1, 1.6, 1), Vector3.new(-0.5, -1.8, 0))
	local rleg = part("RightUpperLeg", Vector3.new(1, 1.6, 1), Vector3.new(0.5, -1.8, 0))
	rig.PrimaryPart = root

	local function seam(p0: BasePart, p1: BasePart, name: string)
		local socket = CFrame.new((p0.Position + p1.Position) / 2)
		if kind == "motors" then
			local motor = Instance.new("Motor6D")
			motor.Name = name
			motor.Part0 = p0
			motor.Part1 = p1
			motor.C0 = p0.CFrame:ToObjectSpace(socket)
			motor.C1 = p1.CFrame:ToObjectSpace(socket)
			motor.Parent = p1
			return
		end
		if not withConstraints then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = p0
			weld.Part1 = p1
			weld.Parent = p1
			return
		end
		local a0 = Instance.new("Attachment")
		a0.Name = name .. "RigAttachment"
		a0.CFrame = p0.CFrame:ToObjectSpace(socket)
		a0.Parent = p0
		local a1 = Instance.new("Attachment")
		a1.Name = name .. "RigAttachment"
		a1.CFrame = p1.CFrame:ToObjectSpace(socket)
		a1.Parent = p1
		local ac = Instance.new("AnimationConstraint")
		ac.Name = name
		ac.IsKinematic = true
		ac.Attachment0 = a0
		ac.Attachment1 = a1
		ac.Parent = p1
		local friction = FRICTION[name]
		if friction then
			local bs = Instance.new("BallSocketConstraint")
			bs.Name = name .. "BallSocket"
			bs.Attachment0 = a0
			bs.Attachment1 = a1
			bs.LimitsEnabled = true
			bs.MaxFrictionTorque = friction
			bs.Parent = p1
		end
	end
	seam(root, lower, "Root")
	seam(lower, upper, "Waist")
	seam(upper, head, "Neck")
	seam(upper, larm, "LeftShoulder")
	seam(upper, rarm, "RightShoulder")
	seam(lower, lleg, "LeftHip")
	seam(lower, rleg, "RightHip")
	rig.Parent = fixture
	return rig
end

local function constraints(rig: Model): { AnimationConstraint }
	local out: { AnimationConstraint } = {}
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("AnimationConstraint") then
			table.insert(out, d)
		end
	end
	return out
end

local function sockets(rig: Model): { BallSocketConstraint }
	local out: { BallSocketConstraint } = {}
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BallSocketConstraint") then
			table.insert(out, d)
		end
	end
	return out
end

local function setAll(rig: Model, enabled: boolean)
	for _, c in ipairs(constraints(rig)) do
		c.Enabled = enabled
	end
end

local function setFriction(rig: Model, value: number?)
	for _, s in ipairs(sockets(rig)) do
		local joint = string.gsub(s.Name, "BallSocket$", "")
		s.MaxFrictionTorque = if value then value else FRICTION[joint] or 0
	end
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE RULE
	--==========================================================================
	local rig = buildRig("constraints")
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local torso = rig:FindFirstChild("UpperTorso") :: BasePart
	task.wait()

	local s = RagdollGate.state(rig)
	check(s.rig == "animation" and s.supported, "the published rig is the supported kind", s.rig)
	check(s.total == 7 and s.off == 0, "a posed rig: seven constraints, none off", s.off)
	check(not s.split and not s.ready, "a posed rig is not limp")
	check(s.assemblies == 1, "a posed rig is one assembly", s.assemblies)
	check(s.gripping == 6, "and all six sockets carry friction", s.gripping)

	-- The case the old rule passed: the Root joint let go, nothing else.
	local rootJoint = rig:FindFirstChild("Root", true) :: AnimationConstraint
	rootJoint.Enabled = false
	task.wait()
	s = RagdollGate.state(rig)
	local oldRule = torso.AssemblyRootPart ~= root.AssemblyRootPart
	check(oldRule, "with only the Root joint off, the torso HAS left the root's assembly " ..
		"-- which is all the old rule asked")
	check(not s.split and not s.ready,
		"and RagdollGate still says NOT limp: the limbs share the torso's assembly")

	setAll(rig, false)
	task.wait()
	s = RagdollGate.state(rig)
	check(s.off == 7 and s.split, "every constraint off: the rig has come apart")
	check(s.assemblies == 8, "into eight assemblies, one per part", s.assemblies)
	check(s.ready, "which is limp for a bat")
	check(not RagdollGate.state(rig, true).ready,
		"but NOT for a guardian while the sockets still grip", RagdollGate.state(rig, true).gripping)
	setFriction(rig, 0)
	check(RagdollGate.state(rig, true).ready, "and limp for a guardian once they let go")

	-- The vacuous pass: zero of zero constraints off used to read as limp.
	local motors = buildRig("motors")
	task.wait()
	local ms = RagdollGate.state(motors, true)
	check(ms.rig == "motor6d" and ms.motors == 7 and ms.total == 0,
		"a classic rig is recognised as Motor6D", ms.rig)
	check(not ms.supported and not ms.ready and not RagdollGate.state(motors).ready,
		"and is NEVER ready -- for a guardian or a bat -- because nothing here loosens it")
	local welded = buildRig("welds")
	task.wait()
	local ws = RagdollGate.state(welded)
	check(ws.rig == "none" and not ws.supported and not ws.ready,
		"a model with no joints of either kind is not ready either", ws.rig)
	local clock = 0
	local mst, mwaited, mgone = RagdollGate.await(motors, 0.4, function()
		clock += 1 / 60
	end, function(): number
		return clock
	end, nil, true)
	check(not mst.ready and not mgone and mwaited == 0,
		"and the wait gives up on it at once instead of spending its timeout", mwaited)
	motors:Destroy()
	welded:Destroy()

	--==========================================================================
	-- 2. THE WAIT, ON A FAKE CLOCK
	--
	-- `loosenAt` is the step on which the rig comes apart. The wait may not
	-- answer ready on any step before it -- that is the regression.
	--==========================================================================
	local function drive(loosenAt: number?, frictionAt: number?, cancelAt: number?,
		needFree: boolean?): (RagdollGate.State, number, boolean, number)
		setAll(rig, true)
		setFriction(rig, nil)
		task.wait()
		local clock, steps = 0, 0
		local state, waited, gone = RagdollGate.await(rig, 0.4, function()
			steps += 1
			clock += 1 / 60
			if loosenAt and steps == loosenAt then
				setAll(rig, false)
				task.wait()
			end
			if frictionAt and steps == frictionAt then
				setFriction(rig, 0)
			end
		end, function(): number
			return clock
		end, function(): boolean
			return cancelAt ~= nil and steps >= cancelAt
		end, needFree)
		return state, waited, gone, steps
	end

	local st, waited, gone, steps = drive(3, 3, nil, true)
	check(st.ready and not gone, "the wait answers once the rig comes apart")
	check(steps == 3, "on the very step it does, not one sooner", steps)
	check(math.abs(waited - 3 / 60) < 1e-9, "and reports how long it waited", waited)

	st, waited, gone, steps = drive(nil, nil, nil, true)
	check(not st.ready and not gone, "a rig that never comes apart times out not-ready")
	-- 24 sixtieths sum to a hair under 0.4 in floating point, so the 25th step
	-- is the one that crosses it: at least the whole timeout, at most one step on.
	check(waited >= 0.4 and waited < 0.4 + 1 / 60 + 1e-9,
		"after the whole 0.4 s and no more than one step past it", string.format("%.4f", waited))

	st, _, gone, steps = drive(10, 10, 2, true)
	check(gone and not st.ready and steps == 2,
		"a newer launch cancels the wait, and it lets go before the rig is limp", steps)

	st, _, gone, steps = drive(2, 5, nil, true)
	check(st.ready and not gone and steps == 5,
		"a guardian's wait holds past the constraints until the friction arrives", steps)

	st, _, gone, steps = drive(2, 5, nil, false)
	check(st.ready and not gone and steps == 2,
		"a bat's wait does not ask about friction", steps)

	--==========================================================================
	-- 3. THE JOINTS: THE SHIPPED NESTSERVICE
	--==========================================================================
	setAll(rig, true)
	setFriction(rig, nil)
	task.wait()
	local collides: { [BasePart]: boolean } = {}
	for _, d in ipairs(rig:GetChildren()) do
		if d:IsA("BasePart") then
			collides[d] = d.CanCollide
		end
	end
	local before: { [BallSocketConstraint]: number } = {}
	for _, b in ipairs(sockets(rig)) do
		before[b] = b.MaxFrictionTorque
	end

	check(not NestService.IsRagdolled(rig), "a standing rig is not registered limp")
	local record = NestService.RagdollOn(rig)
	local allOff = true
	for _, c in ipairs(constraints(rig)) do
		allOff = allOff and not c.Enabled
	end
	check(allOff, "RagdollOn switches every constraint off")
	-- 2026-09-26: with the Root joint off the HumanoidRootPart was a free, colliding
	-- box; a knockdown into a fence stopped the body and the root flew 110 studs on,
	-- taking a bat victim's camera with it. It rides the pelvis now, and does not
	-- collide, for as long as the body is limp.
	local rigRoot = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local rigPelvis = rig:FindFirstChild("LowerTorso") :: BasePart
	local weld = rigRoot:FindFirstChild("SeedRagdollRootWeld")
	check(weld ~= nil and weld:IsA("WeldConstraint") and (weld :: WeldConstraint).Part0 == rigRoot
			and (weld :: WeldConstraint).Part1 == rigPelvis and record.rootWeld == weld
			and not rigRoot.CanCollide,
		"while limp the root is welded to the pelvis and does not collide -- it cannot leave the body")
	check(NestService.IsRagdolled(rig), "and registers the rig as limp, so no second throw starts on it")
	-- No Player owns this rig, so there is nobody to pin it to: the record says
	-- so rather than pinning to nothing.
	check(record.owner == nil and #record.autos == 0 and not record.pinning,
		"a rig no player owns is never pinned")
	check(#record.frictions == 0, "and on its own touches no friction -- a bat's knockdown is as it was")
	local untouched = true
	for b, was in pairs(before) do
		untouched = untouched and b.MaxFrictionTorque == was
	end
	check(untouched, "the sockets keep their friction until a guardian asks")

	NestService.SlackenJoints(record, rig)
	local zeroed = true
	for b in pairs(before) do
		zeroed = zeroed and b.MaxFrictionTorque == 0
	end
	check(#record.frictions == 6 and zeroed, "SlackenJoints lets go of all six", #record.frictions)

	NestService.RagdollOff(record)
	local allOn = true
	for _, c in ipairs(constraints(rig)) do
		allOn = allOn and c.Enabled
	end
	check(allOn, "RagdollOff switches every constraint back on")
	check(not NestService.IsRagdolled(rig), "and takes the rig off the limp register")
	local restored = true
	for b, was in pairs(before) do
		restored = restored and b.MaxFrictionTorque == was
	end
	check(restored, "and puts back every socket's EXACT friction")
	local sameCollide = true
	for p, was in pairs(collides) do
		sameCollide = sameCollide and p.CanCollide == was
	end
	check(sameCollide, "and every part's collision as it was")
	check(rigRoot:FindFirstChild("SeedRagdollRootWeld") == nil and record.rootWeld == nil,
		"and the root's weld is gone, so the Root joint alone holds it again")

	-- Once: something else changes a socket afterwards, and a second restore on
	-- the same record must not overwrite it with the old value.
	local probe = sockets(rig)[1]
	probe.MaxFrictionTorque = 1.25
	NestService.RagdollOff(record)
	check(probe.MaxFrictionTorque == 1.25 and #record.frictions == 0,
		"a second RagdollOff on the same record gives nothing back twice")

	-- A newer ragdoll's registration is not cleared by an older record.
	local first = NestService.RagdollOn(rig)
	local second = NestService.RagdollOn(rig)
	NestService.RagdollOff(first)
	check(NestService.IsRagdolled(rig), "an older record's restore does not unregister a newer ragdoll")
	NestService.RagdollOff(second)
	check(not NestService.IsRagdolled(rig), "the newer one's does")
	setAll(rig, true)

	--==========================================================================
	-- 4. THE ANSWERS: ONLY THE WAITING THROW'S OWN TOKEN ENDS IT
	--==========================================================================
	local matches = NestService.ThrowAnswerMatches
	check(matches(false, "g7@1.00", "g7@1.00"), "the waiting throw's own token ends it")
	check(not matches(false, "g7@1.00", "g6@0.50"), "a stale token from an earlier throw does not")
	check(not matches(true, "g7@1.00", "g7@1.00"), "nor a duplicate after it has already ended")
	check(not matches(nil, "g7@1.00", "g7@1.00"), "nor any answer when no throw is waiting")
	check(not matches(false, "g7@1.00", "b3@2.00"), "nor a bat's answer on the same remote")
	check(not matches(false, "g7@1.00", nil) and not matches(false, "g7@1.00", 7),
		"nor an answer that quotes nothing, or not a string")
	check(not matches(false, nil, "g7@1.00"), "nor one for a player with no throw claimed")

	--==========================================================================
	-- 5. THE ORDER, IN THROWFX AND NESTSERVICE
	--==========================================================================
	local throwFX = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ThrowFX")
	local source = if throwFX and throwFX:IsA("LocalScript") then throwFX.Source else ""
	check(#source > 0, "ThrowFX's source is readable")
	local gateAt = string.find(source, "1b. AND WAIT FOR THE BODY", 1, true) or 0
	local stepAt = string.find(source, "2. GET OUT OF THE PARENT", 1, true) or 0
	local block = if gateAt > 0 and stepAt > gateAt then string.sub(source, gateAt, stepAt) else ""
	check(string.find(block, "RagdollGate.await(", 1, true) ~= nil,
		"the launch is preceded by RagdollGate.await")
	-- A BLOCK `if isBat then` on a line of its own is what used to fence the wait;
	-- the one-line expression form in the log line beside it chooses a word.
	check(string.find(block, "\n%s*if isBat then%s*\n") == nil,
		"and the wait is not fenced to bats -- a guardian waits too")
	check(string.find(block, "superseded, not isBat)", 1, true) ~= nil,
		"and a guardian's wait asks for the friction as well")
	local awaitAt = string.find(source, "RagdollGate.await(", 1, true) or math.huge
	local launchAt = string.find(source, "articulate(body, rootOf(), impulse, tumble)", 1, true) or 0
	check(launchAt > awaitAt, "the articulated launch comes after the wait, never before")
	check(string.find(source, "holdCentre(body, rootOf(), impulse)", 1, true) ~= nil,
		"and the legacy hold holds the centre, not every part")
	check(string.find(source, "ownershipNote(character)", 1, true) ~= nil,
		"and every throw's log says whether this machine was the one moving the body")

	-- NestService, with its comments stripped so a banner that NAMES the thing it
	-- forbids does not count as doing it.
	local nestSource = game:GetService("ServerScriptService").SeedGameServer.NestService.Source
	local codeLines: { string } = {}
	for line in string.gmatch(nestSource, "[^\n]+") do
		if not string.match(line, "^%s*%-%-") then
			table.insert(codeLines, (string.gsub(line, "%s*%-%-.*$", "")))
		end
	end
	local code = table.concat(codeLines, "\n")
	local onAt = string.find(code, "local function ragdollOn(", 1, true) or 0
	local onEnd = string.find(code, "\nend\n", onAt, true) or 0
	local onBody = string.sub(code, onAt, onEnd)
	-- Twice: at once, and again in the PIN_WINDOW loop that holds it while the
	-- split and the engine's first assignment land.
	local _, pins = string.gsub(onBody, "pinOwnership%(character, player%)", "")
	check(pins >= 2, "ragdollOn pins the loose body to its own player at once, and holds the pin", pins)
	check(string.find(code, "SetNetworkOwner(nil)", 1, true) == nil,
		"and nothing in NestService takes a player's body for the server")
	check(string.find(code, "SetNetworkOwnershipAuto", 1, true) ~= nil,
		"and ragdollOff hands it back to automatic ownership")
	check(string.find(code, "{ token = token, kind = \"guardian\" }", 1, true) ~= nil,
		"a guardian launch carries its own token")
	check(string.find(code, "throwAnswerMatches(throwDone[player], throwToken[player], token)", 1, true) ~= nil,
		"and only an answer quoting it ends the throw")
	check(string.find(code, "if isRagdolled(character) or throwToken[player] ~= nil then", 1, true) ~= nil,
		"and a body that is already limp, or already being thrown, is not thrown again")
	local _, handlers = string.gsub(code, "OnServerEvent:Connect%(acceptThrowAnswer%)", "")
	local _, anyAnswer = string.gsub(code, "if throwDone%[player%] == false then", "")
	check(handlers == 1 and anyAnswer == 0,
		"one answer handler, and no path left that accepts any answer at all", handlers)

	--==========================================================================
	-- 6. LYING DOWN: THE NECK, THE REST RULE, THE CAMERA -- AND NOT A BAT'S
	--==========================================================================
	-- The neck, on the shipped NestService.
	setAll(rig, true)
	setFriction(rig, nil)
	task.wait()
	local was: { [BallSocketConstraint]: number } = {}
	for _, b in ipairs(sockets(rig)) do
		was[b] = b.MaxFrictionTorque
	end
	local neck = RagdollGate.neckSocket(rig) :: BallSocketConstraint
	check(neck ~= nil and neck.Name == "NeckBallSocket",
		"the neck is the socket with an end on the Head", if neck then neck.Name else "none")

	local bat = NestService.RagdollOn(rig)
	check(not NestService.StiffenNeck(bat) and neck.MaxFrictionTorque == was[neck] and #bat.frictions == 0,
		"a bat's record gives the neck nothing, because nothing was taken from it")
	NestService.RagdollOff(bat)

	local limp = NestService.RagdollOn(rig)
	NestService.SlackenJoints(limp, rig)
	check(neck.MaxFrictionTorque == 0, "a guardian's throw lets the neck go with every other joint")
	check(NestService.StiffenNeck(limp), "and its landing gives the neck its friction back")
	check(neck.MaxFrictionTorque == was[neck] and was[neck] > 40,
		"the value slackenJoints captured, exactly -- not a new number", neck.MaxFrictionTorque)
	local othersLoose = true
	for _, b in ipairs(sockets(rig)) do
		if b ~= neck then
			othersLoose = othersLoose and b.MaxFrictionTorque == 0
		end
	end
	check(othersLoose, "every other joint stays loose until the stand-up")
	check(#limp.frictions == 6, "the record still holds all six, for RagdollOff", #limp.frictions)
	check(NestService.StiffenNeck(limp) and neck.MaxFrictionTorque == was[neck],
		"a second landing report changes nothing")
	NestService.RagdollOff(limp)
	local allBack = true
	for b, value in pairs(was) do
		allBack = allBack and b.MaxFrictionTorque == value
	end
	check(allBack and #limp.frictions == 0,
		"RagdollOff still puts back every socket's exact friction, once, the neck included")
	check(not NestService.StiffenNeck(limp), "and a landing reported after the stand-up finds nothing to write")
	setAll(rig, true)

	-- The report: a second word, from the waiting throw only, and never the end.
	local landing = NestService.ThrowLandingMatches
	local word = RagdollGate.Landed
	check(landing(false, "g7@1.00", "g7@1.00", word), "the waiting throw's own token and the word: it has landed")
	check(not landing(false, "g7@1.00", "g6@0.50", word), "a stale token's landing is not taken")
	check(not landing(true, "g7@1.00", "g7@1.00", word), "nor one for a throw that has already ended")
	check(not landing(nil, "g7@1.00", "g7@1.00", word), "nor one when no throw is waiting")
	check(not landing(false, "g7@1.00", "b3@2.00", word), "nor one quoting a bat's token")
	check(not landing(false, "g7@1.00", "g7@1.00", "stopped") and not landing(false, "g7@1.00", "g7@1.00", true)
			and not landing(false, "g7@1.00", "g7@1.00", nil),
		"nor any other second word, or none")
	local handlerAt = string.find(code, "local function acceptThrowAnswer(", 1, true) or 0
	local handlerEnd = string.find(code, "\nend\n", handlerAt, true) or 0
	local handler = string.sub(code, handlerAt, handlerEnd)
	local wordAt = string.find(handler, "if what ~= nil then", 1, true) or math.huge
	local returnAt = string.find(handler, "\n%s+return nil%s*\n%s+end%s*\n", wordAt) or math.huge
	local endsAt = string.find(handler, "throwAnswerMatches(throwDone[player], throwToken[player], token)", 1, true) or 0
	check(wordAt < returnAt and returnAt < endsAt,
		"a report with a second word returns before the rule that ends a throw is asked")
	local doneAt = string.find(handler, "throwDone[player] = true", 1, true) or 0
	local _, dones = string.gsub(handler, "throwDone%[player%] = true", "")
	check(dones == 1 and doneAt > endsAt,
		"so only the report with no second word can end one", dones)

	--==========================================================================
	-- THE HANDLER ITSELF: FROM WHOM, WHEN, HOW OFTEN -- AND OTHERWISE NOTHING
	--
	-- `AcceptThrowAnswer` is the function the remote is connected to, and its
	-- first argument is the sender the engine stamps. Two stand-ins here: the
	-- player who was thrown, and somebody else in the same server.
	--==========================================================================
	local accept = NestService.AcceptThrowAnswer :: any
	local thrown = Instance.new("Folder")
	thrown.Name = "SpecThrownPlayer"
	local other = Instance.new("Folder")
	other.Name = "SpecOtherPlayer"
	local otherRig = buildRig("constraints")
	task.wait()
	local otherNeck = RagdollGate.neckSocket(otherRig) :: BallSocketConstraint

	local flying = NestService.RagdollOn(rig)
	NestService.SlackenJoints(flying, rig)
	check(accept(thrown, "g7@1.00", word) == nil and neck.MaxFrictionTorque == 0,
		"with no throw on the books, a landing report is ignored")

	NestService.SpecThrow(thrown, "g7@1.00", flying)
	check(accept(other, "g7@1.00", word) == nil and neck.MaxFrictionTorque == 0,
		"another player quoting the thrown player's token is ignored")
	local otherFlying = NestService.RagdollOn(otherRig)
	NestService.SlackenJoints(otherFlying, otherRig)
	NestService.SpecThrow(other, "g8@2.00", otherFlying)
	check(accept(other, "g7@1.00", word) == nil and neck.MaxFrictionTorque == 0
			and otherNeck.MaxFrictionTorque == 0,
		"even one who is mid-throw themselves: neither neck is touched")
	check(accept(thrown, "g8@2.00", word) == nil and neck.MaxFrictionTorque == 0
			and otherNeck.MaxFrictionTorque == 0,
		"and the thrown player cannot report for somebody else's throw")
	check(accept(thrown, "g6@0.50", word) == nil and accept(thrown, nil, word) == nil
			and accept(thrown, 7, word) == nil and accept(thrown, { "g7@1.00" }, word) == nil
			and neck.MaxFrictionTorque == 0,
		"a stale token, none, a number or a table is ignored")
	check(accept(thrown, "g7@1.00", "stopped") == nil and accept(thrown, "g7@1.00", true) == nil
			and accept(thrown, "g7@1.00", 1) == nil and accept(thrown, "g7@1.00", {}) == nil
			and neck.MaxFrictionTorque == 0,
		"any second word but the one is ignored")
	check(accept(thrown, "g7@1.00", word) == word and neck.MaxFrictionTorque == was[neck],
		"the thrown player, during their own waiting throw, quoting its token: the neck grips again")
	check(otherNeck.MaxFrictionTorque == 0, "and only their own: the other body's neck is still loose")
	neck.MaxFrictionTorque = 0
	check(accept(thrown, "g7@1.00", word) == nil and neck.MaxFrictionTorque == 0,
		"once per throw: a second landing report writes nothing")
	check(accept(thrown, "g7@1.00") == "stopped",
		"none of those ended the throw: the report that the body has stopped still does")
	check(accept(thrown, "g7@1.00") == nil and accept(thrown, "g7@1.00", word) == nil
			and neck.MaxFrictionTorque == 0,
		"and after it, neither report is taken again")
	NestService.SpecThrow(thrown, "g9@3.00", flying)
	check(accept(thrown, "g7@1.00", word) == nil and neck.MaxFrictionTorque == 0,
		"the next throw does not take the last throw's token")
	check(accept(thrown, "g9@3.00", word) == word and neck.MaxFrictionTorque == was[neck],
		"and takes its own, once")
	NestService.SpecThrow(thrown, nil, nil)
	NestService.SpecThrow(other, nil, nil)
	neck.MaxFrictionTorque = 0
	check(accept(thrown, "g9@3.00", word) == nil and accept(other, "g8@2.00", word) == nil
			and neck.MaxFrictionTorque == 0 and otherNeck.MaxFrictionTorque == 0,
		"once a throw is over, a late landing report is ignored")
	NestService.RagdollOff(flying)
	NestService.RagdollOff(otherFlying)
	check(neck.MaxFrictionTorque == was[neck], "and the stand-up puts the neck back whatever was reported")
	otherRig:Destroy()
	thrown:Destroy()
	other:Destroy()
	setAll(rig, true)

	-- The rest rule, on a rig that has really come apart.
	setAll(rig, false)
	task.wait()
	local rigHead = rig:FindFirstChild("Head") :: BasePart
	local rigTorso = rig:FindFirstChild("UpperTorso") :: BasePart
	local rigHips = rig:FindFirstChild("LowerTorso") :: BasePart
	rigHead.AssemblyLinearVelocity = Vector3.new(9, 0, 0)
	rigTorso.AssemblyLinearVelocity = Vector3.new(0, 0, 0.5)
	rigHips.AssemblyLinearVelocity = Vector3.new(0, 1.5, 0)
	check(rigHead.AssemblyLinearVelocity.Magnitude > 8.9, "the fixture's head is moving at 9 studs a second",
		rigHead.AssemblyLinearVelocity.Magnitude)
	check(math.abs(RagdollGate.restSpeed(rig) - 1.5) < 1e-3,
		"a guardian's rest is the faster of the torso and the pelvis", RagdollGate.restSpeed(rig))
	check(RagdollGate.restSpeed(rig) < 3.5, "so a head swinging over a still body does not hold it down")
	rigTorso.AssemblyLinearVelocity = Vector3.new(0, 0, 6)
	check(math.abs(RagdollGate.restSpeed(rig) - 6) < 1e-3, "and a torso that is still moving does",
		RagdollGate.restSpeed(rig))
	for _, p in ipairs({ rigHead, rigTorso, rigHips }) do
		p.AssemblyLinearVelocity = Vector3.zero
	end
	setAll(rig, true)

	-- What the camera follows.
	check(RagdollGate.cameraPart(rig) == rigTorso and RagdollGate.cameraPart(rig) ~= rigHead,
		"the camera follows the torso, not the head")
	local classic = Instance.new("Model")
	local classicHead = Instance.new("Part")
	classicHead.Name = "Head"
	classicHead.Parent = classic
	local classicTorso = Instance.new("Part")
	classicTorso.Name = "Torso"
	classicTorso.Parent = classic
	classic.Parent = fixture
	check(RagdollGate.cameraPart(classic) == classicTorso, "on a classic rig too")
	-- The fallback, in order: a body with no torso at its root, then at its head.
	local bare = buildRig("constraints")
	task.wait()
	local bareRoot = bare:FindFirstChild("HumanoidRootPart") :: BasePart
	local bareHead = bare:FindFirstChild("Head") :: BasePart;
	(bare:FindFirstChild("UpperTorso") :: BasePart):Destroy()
	check(RagdollGate.cameraPart(bare) == bareRoot,
		"a body with no UpperTorso is followed at its root")
	bareRoot:Destroy()
	check(RagdollGate.cameraPart(bare) == bareHead,
		"and with no root either, at its head: the last resort")
	bareHead:Destroy()
	check(RagdollGate.cameraPart(bare) == nil, "a character with none of the three is given nothing")
	bare:Destroy()
	classic:Destroy()

	-- ThrowFX: where it points the camera, what it settles on, what it reports.
	check(string.find(source, "local followPart = RagdollGate.cameraPart(character)", 1, true) ~= nil
			and string.find(source, "camera.CameraSubject = followPart", 1, true) ~= nil,
		"ThrowFX points the camera at the part RagdollGate names")
	check(string.find(source, "CameraSubject = head", 1, true) == nil,
		"and nowhere at the head")
	check(string.find(source, "kept.subject = camera.CameraSubject", 1, true) ~= nil
			and string.find(source, "if camera and kept.subject == nil then", 1, true) ~= nil,
		"the player's own subject is still captured once per chain of hits, and restored from there")
	local loopAt = string.find(source, "5. WAIT UNTIL THE BODY HAS FLOWN AND STOPPED", 1, true) or 0
	local boxAt = string.find(source, "6. BRING THE BOX TO THE BODY", 1, true) or 0
	local loop = if loopAt > 0 and boxAt > loopAt then string.sub(source, loopAt, boxAt) else ""
	check(#loop > 0, "the settle loop is where it was")
	check(string.find(loop, "else%s+bodySpeed = RagdollGate%.restSpeed%(character%)%s+end") ~= nil,
		"a guardian's settle asks RagdollGate for the body's speed")
	check(string.find(loop, "if isBat then%s+if head and head:IsA%(\"BasePart\"%) then%s+"
			.. "bodySpeed = math%.max%(bodySpeed, head%.AssemblyLinearVelocity%.Magnitude%)") ~= nil,
		"a bat's and a trap's is still judged on the head and the torso, inside its own branch")
	local reportAt = string.find(loop, "FireServer(token, RagdollGate.Landed)", 1, true) or 0
	local guardianAt = string.find(loop, "-- The guardian test", 1, true) or math.huge
	local ceilingAt = string.find(loop, "AND THE CEILING IS CHECKED AFTER", 1, true) or 0
	check(guardianAt < reportAt and reportAt < ceilingAt, "the landing is reported from the guardian's branch")
	-- As an argument, which is where a report is made; the banner beside it
	-- names the word too.
	local _, reports = string.gsub(source, ", RagdollGate%.Landed%)", "")
	check(reports == 1, "and from nowhere else", reports)
	check(string.find(source, "MaxFrictionTorque%s*=[^=]") == nil,
		"ThrowFX never writes a joint's friction: the server took it and the server returns it")
	check(string.find(source, "\nlocal SETTLE_SPEED = 3.5\n", 1, true) ~= nil
			and string.find(source, "\nlocal SETTLE_HOLD = 0.35\n", 1, true) ~= nil
			and string.find(source, "\nlocal GIVE_UP_AFTER = 5\n", 1, true) ~= nil,
		"the settle speed, the hold and the give-up are the numbers they were")
	check(string.find(code, "\nlocal THROW_TIMEOUT = 6\n", 1, true) ~= nil
			and string.find(code, "\nlocal LIMP_JOINT_FRICTION = 0\n", 1, true) ~= nil,
		"and so are the server's backstop and the flight's joint friction")
	check(string.find(source, "\"rest check, last", 1, true) ~= nil
			and string.find(source, "\"rest rig: ", 1, true) ~= nil
			and string.find(source, "\"rest trace (", 1, true) ~= nil,
		"the rest check, rest rig and rest trace lines are still printed")

	-- And a bat's or a trap's knockdown has none of it.
	local style = WeaponData.BatThrowStyle("b1@0.00", 0)
	check(style.camera == false and style.emergency ~= nil and style.kind == "bat",
		"a bat's launch still takes no camera and carries its own emergency")
	check(not WeaponData.AcceptsAck("b3@2.00", "g7@1.00") and not WeaponData.AcceptsAck(nil, "g7@1.00"),
		"a guardian's report means nothing to the bat's handler on the same remote")
	local combat = game:GetService("ServerScriptService").SeedGameServer.CombatService.Source
	check(#combat > 0 and string.find(combat, "StiffenNeck", 1, true) == nil
			and string.find(combat, "SlackenJoints", 1, true) == nil
			and string.find(combat, "MaxFrictionTorque", 1, true) == nil
			and string.find(combat, "RagdollGate", 1, true) == nil,
		"and CombatService touches no joint's friction and asks RagdollGate nothing")
end)

fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("GuardianRagdollSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return ("GuardianRagdollSpec: %d passed, 0 failed"):format(pass)
