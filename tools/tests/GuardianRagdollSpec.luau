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
-- FIVE LAYERS, all against REAL rigs built here -- Edit mode maintains
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
-- NOT HERE, measured in Play instead (see KB/HANDOFF.md): who owns the body in
-- flight, the limbs actually swinging, the torso tumbling, the landing and the
-- stand-up.
--==============================================================================
local Workspace = game:GetService("Workspace")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local RagdollGate = require(Shared.RagdollGate)
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
