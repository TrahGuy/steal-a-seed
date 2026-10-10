--!nocheck
--==============================================================================
-- Steal a Seed :: SecretWalkSpec
--
-- Snarlbloom and Petalfawn walk and roam their plot (2026-10-02): the server
-- hands them legs through the existing PlantWander system on the Colossal rung
-- of the walk ladder (their authored size); PlantSway moves and turns the whole
-- model along each leg; SecretIdle steps their own rigs, driven by how far the
-- model actually moved, over the idle they already had. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SecretWalkSpec"))
--
-- The walks here are simulated the way PlantSway draws one: the model's pivot is
-- carried along a straight line on a 20 Hz slice at the Colossal pace while
-- SecretIdle.Step runs every frame. Not here, seen in Play instead: real legs
-- from PlantService, PlantSway's turn, a pickup mid-walk.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local CreatureModel = require(Shared.CreatureModel)
local SecretIdle = require(Shared.SecretIdle)
local PlantWander = require(Server.PlantWander)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local FPS = 60
local SLICE = 3 -- PlantSway moves a model about every third frame (20 Hz)
local SPEED = SeedData.WanderSpeed(SeedData.TierCount)
-- PlantSway's damped Secret turn (SECRET_TURN_RATE, SECRET_TURN_MAX), pinned below.
local TURN_RATE, TURN_MAX = 2.2, 1.2

local scratch = Instance.new("Folder")
scratch.Name = "ZZSecretWalkSpec"
scratch.Parent = workspace

-- The part each leg's ankle joint moves: the foot or hoof.
local function footOf(rig, ankle)
	for _, node in ipairs(rig.nodes) do
		if node.motor == ankle then
			return node.part
		end
	end
	return nil
end

local function build(id)
	local model = CreatureModel.Build(SeedData.Get(id), SeedData.SecretTier, CreatureModel.STAGE_GROWN, CFrame.new(), scratch)
	return model, SecretIdle.Rig(model)
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The server walks them on the existing system, at their size")
	--==========================================================================
	for _, id in ipairs({ "snarlbloom", "petalfawn" }) do
		local sp = SeedData.Get(id)
		check(sp.WanderTier == SeedData.TierCount and sp.NoWander == nil
				and SeedData.WanderTierOf(sp, SeedData.SecretTier) == SeedData.TierCount,
			id .. " walks the Colossal rung (its authored size), not its internal tier's")
	end
	local listed = 0
	for _, sp in ipairs(SeedData.Species) do
		if sp.WanderTier ~= nil or SeedData.WanderTierOf(sp, 3) ~= 3 then
			listed += 1
		end
	end
	check(listed == 0, "every listed species still walks its own tier's rung", listed)
	local plantSrc = sourceOf(Server, "PlantService")
	check(string.find(plantSrc, "local walkTier = SeedData.WanderTierOf(entry.species, entry.tier) or entry.tier", 1, true)
			and string.find(plantSrc, "entry.offset, walkTier, byPlot :: any, entry.id, rng)", 1, true)
			and string.find(plantSrc, "PlantWander.LegSeconds(walkTier, dist)", 1, true)
			and string.find(plantSrc, "SeedData.WanderPause(walkTier) * rng:NextNumber(0.7, 1.7)", 1, true)
			and not string.find(plantSrc, "NoWander", 1, true),
		"PlantService publishes legs for a Secret -- chosen, timed and paused on its rung -- and holds none still")
	-- The movement base never leaves the plot: legs from anywhere on a Level-1
	-- and a Level-2 plot, on the Colossal rung.
	for _, level in ipairs({ 1, 2 }) do
		local region = PlantWander.RegionOf(GameConfig.plotDepthFor(GameConfig.plotRowsForTier(level)), 0, 0)
		local rng = Random.new(1000 + level)
		local legs, outside = 0, 0
		for _ = 1, 400 do
			local home = Vector3.new(rng:NextNumber(region.main.x0, region.main.x1), 0,
				rng:NextNumber(region.main.z0, region.main.z1))
			if PlantWander.Inside(region, home) then
				local to, how = PlantWander.Choose(region, home, SeedData.TierCount, {}, 1, Random.new(rng:NextInteger(1, 1e6)))
				if how ~= "stay" then
					legs += 1
					for k = 0, 20 do
						if not PlantWander.Inside(region, home:Lerp(to, k / 20)) then
							outside += 1
							break
						end
					end
				end
			end
		end
		check(legs > 100 and outside == 0,
			string.format("Level %d: %d Colossal-rung legs, every route inside the plot", level, legs), outside)
	end

	--==========================================================================
	say("2. The legs step to the distance walked, and a planted foot stays put")
	--==========================================================================
	for _, id in ipairs({ "snarlbloom", "petalfawn" }) do
		local model, rig = build(id)
		local home = model:GetPivot() -- where the authored pivot stands (its Base, a hair above the soil)
		local still, stillRig = build(id) -- the same idle, standing: the reference
		local carried, carriedRig = build(id) -- moved like a held copy: never planted
		local gait = rig and rig.gait
		check(gait ~= nil and #gait.legs == (if id == "snarlbloom" then 2 else 4),
			id .. ": the gait finds every leg on the authored rig", gait and #gait.legs)
		if not gait then
			continue
		end
		rig.walks = true
		stillRig.walks = true
		carriedRig.walks = false
		local feet = {}
		for i, leg in ipairs(gait.legs) do
			local part = footOf(rig, leg.ankle)
			feet[i] = { part = part, rest = part.Position.Y, down = nil, slip = 0, lift = 0, sink = 0, stances = 0 }
		end
		local frames = 10 * FPS
		local z, travelled, cycles, lastPhase = 0, 0, 0, gait.phase
		local reachedAt, idleSame, blinkSame, carriedStill = nil, true, true, true
		local others = if id == "snarlbloom" then { "UpperJaw", "LowerJaw", "EyeL", "EyeR", "VineL2", "Neck" }
			else { "Head", "EarL", "Tail3", "BackPetal", "Neck2" }
		for f = 1, frames do
			local now = f / FPS
			-- PlantSway's slice: the model moves every third frame, by three frames' worth.
			if f % SLICE == 0 then
				local step = SPEED * SLICE / FPS
				z -= step
				travelled += step
				model:PivotTo(home * CFrame.new(0, 0, z))
				carried:PivotTo(home * CFrame.new(40, 0, z))
			end
			local wasMoving = gait.moving
			SecretIdle.Step(rig, now)
			SecretIdle.Step(stillRig, now)
			SecretIdle.Step(carriedRig, now)
			-- Counted once it is under way: setting off re-times the stride once.
			if wasMoving then
				cycles += (gait.phase - lastPhase) % 1
			end
			lastPhase = gait.phase
			if not reachedAt and gait.weight >= 0.95 then
				reachedAt = now
			end
			-- Everything the walk does not drive is the idle's, exactly.
			for _, name in ipairs(others) do
				if rig.pose[name] ~= stillRig.pose[name] then
					idleSame = false
				end
			end
			for i, e in ipairs(rig.irises) do
				if e.part.Size ~= stillRig.irises[i].part.Size then
					blinkSame = false
				end
			end
			for i, e in ipairs(rig.eyes) do
				if e.part.Size ~= stillRig.eyes[i].part.Size then
					blinkSame = false
				end
			end
			if carriedRig.gait.weight > 0 then
				carriedStill = false
			end
			-- The feet, from the first step: a foot the gait says is down.
			do
				for i, leg in ipairs(gait.legs) do
					local foot = feet[i]
					local p = foot.part.Position
					if leg.down then
						if not foot.down then
							foot.down = p
							foot.stances += 1
						end
						foot.slip = math.max(foot.slip, Vector3.new(p.X - foot.down.X, 0, p.Z - foot.down.Z).Magnitude)
						foot.sink = math.max(foot.sink, math.abs(p.Y - foot.rest))
					else
						foot.down = nil
						foot.lift = math.max(foot.lift, p.Y - foot.rest)
					end
				end
			end
		end
		local want = travelled / gait.stride
		check(reachedAt ~= nil and reachedAt < 2.0,
			string.format("%s: the walk is all on within %.2f s of setting off", id, reachedAt or -1))
		check(math.abs(cycles - want) < 0.12 * want + 0.05,
			string.format("%s: %.2f strides for %.1f studs walked (%.2f expected): the steps follow the distance", id,
				cycles, travelled, want))
		local worstSlip, worstSink, leastLift, stances = 0, 0, math.huge, 0
		for _, foot in ipairs(feet) do
			worstSlip = math.max(worstSlip, foot.slip)
			worstSink = math.max(worstSink, foot.sink)
			leastLift = math.min(leastLift, foot.lift)
			stances += foot.stances
		end
		check(stances >= #feet * 2 and worstSlip < 0.12,
			string.format("%s: a planted foot stays where it was put (worst %.3f studs over %d stances)", id, worstSlip, stances))
		check(worstSink < 0.12, string.format("%s: and stays on the soil (worst %.3f studs off it)", id, worstSink))
		check(leastLift > 0.6 * gait.profile.lift,
			string.format("%s: every foot lifts clear when it steps (least %.2f studs)", id, leastLift))
		check(idleSame and blinkSame, id .. ": the blink, the jaw, the eyes, the head and the rest of the idle carry on, unchanged")
		check(carriedStill, id .. ": a copy that is not planted -- carried, or in a viewport -- never steps, however it moves")

		-- Stopping: the feet step home under the body, none slides there.
		local stopAt = frames / FPS
		local settledAt = nil
		local stopSlip, settleSteps, downAt = 0, 0, {}
		for f = 1, 4 * FPS do
			local now = stopAt + f / FPS
			SecretIdle.Step(rig, now)
			SecretIdle.Step(stillRig, now)
			if not settledAt and gait.weight == 0 then
				settledAt = f / FPS
			end
			if gait.legWeight > 0.98 then
				for i, leg in ipairs(gait.legs) do
					local p = feet[i].part.Position
					if leg.down then
						downAt[i] = downAt[i] or p
						stopSlip = math.max(stopSlip, Vector3.new(p.X - downAt[i].X, 0, p.Z - downAt[i].Z).Magnitude)
					else
						if downAt[i] then
							settleSteps += 1
						end
						downAt[i] = nil
					end
				end
			end
		end
		check(stopSlip < 0.12,
			string.format("%s: stopping, the feet step home under the body (%d step(s)) and none slides (worst %.3f studs)", id,
				settleSteps, stopSlip))
		local legsIdle = true
		for _, leg in ipairs(gait.legs) do
			for _, name in ipairs({ leg.hip, leg.knee, leg.ankle }) do
				if rig.pose[name] ~= stillRig.pose[name] then
					legsIdle = false
				end
			end
		end
		check(settledAt ~= nil and settledAt < 3 and legsIdle,
			string.format("%s: stopped, the walk fades out in %.2f s and the legs are the idle's again", id, settledAt or -1))

		-- Turning on the spot: the legs step it round, and a planted foot stays put
		-- while the body swings above it.
		local least, stepped = 1, false
		local turnFeet = {}
		for i in ipairs(gait.legs) do
			turnFeet[i] = { down = nil, slip = 0, stances = 0 }
		end
		-- PlantSway's own turn for a Secret, replayed on its 20 Hz slice: a damped
		-- swing of SECRET_TURN_RATE capped at SECRET_TURN_MAX, half a circle, about
		-- the centre of the model's footprint on the ground (its anchor) rather
		-- than the pivot, so the pivot swings round too. Measured from its first
		-- frame, while the walk is still fading in.
		local startCF = home * CFrame.new(0, 0, z)
		local lo, hi = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local h = d.Size * 0.5
				for sx = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, 0, h.Z * sz)).Position
						lo = Vector3.new(math.min(lo.X, q.X), 0, math.min(lo.Z, q.Z))
						hi = Vector3.new(math.max(hi.X, q.X), 0, math.max(hi.Z, q.Z))
					end
				end
			end
		end
		local anchor = CFrame.new((lo.X + hi.X) / 2, startCF.Position.Y, (lo.Z + hi.Z) / 2)
		local swing = (anchor.Position - startCF.Position).Magnitude
		local facing, turnVel, sliceDt = 0, 0, SLICE / FPS
		for f = 1, math.floor(4.0 * FPS) do
			local now = stopAt + 4 + f / FPS
			if f % SLICE == 0 then
				local delta = math.pi - facing
				turnVel = math.clamp(turnVel + (TURN_RATE * TURN_RATE * delta - 2 * TURN_RATE * turnVel) * sliceDt,
					-TURN_MAX, TURN_MAX)
				facing += turnVel * sliceDt
				model:PivotTo(anchor * CFrame.Angles(0, facing, 0) * anchor:Inverse() * startCF)
			end
			SecretIdle.Step(rig, now)
			least = math.min(least, gait.along)
			stepped = stepped or gait.weight > 0.5
			if f > 0 then
				for i, leg in ipairs(gait.legs) do
					local foot = turnFeet[i]
					local p = feet[i].part.Position
					if leg.down then
						if not foot.down then
							foot.down = p
							foot.stances += 1
						end
						foot.slip = math.max(foot.slip, Vector3.new(p.X - foot.down.X, 0, p.Z - foot.down.Z).Magnitude)
					else
						foot.down = nil
					end
				end
			end
		end
		local turnSlip, turnStances = 0, 0
		for _, foot in ipairs(turnFeet) do
			turnSlip = math.max(turnSlip, foot.slip)
			turnStances += foot.stances
		end
		check(stepped, string.format("%s: turning on the spot is stepped round, not slid (turned about a point %.1f studs off the pivot)",
			id, swing))
		check(turnStances >= #feet and turnSlip < 0.35,
			string.format("%s: and through the turn a planted foot stays put (worst %.3f studs over %d stances)", id,
				turnSlip, turnStances))
		local _ = least

		-- Nothing is resized or left out of place.
		model:PivotTo(home)
		SecretIdle.Rest(rig)
		local fresh = CreatureModel.Build(SeedData.Get(id), SeedData.SecretTier, CreatureModel.STAGE_GROWN, CFrame.new(), scratch)
		local a, b = {}, {}
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(a, d)
			end
		end
		for _, d in ipairs(fresh:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(b, d)
			end
		end
		local worst, sized = 0, true
		for i, d in ipairs(a) do
			local e = b[i]
			if e then
				worst = math.max(worst, (d.Position - e.Position).Magnitude)
				if d.Name ~= "Iris" and d.Name ~= "Eye" and d.Name ~= "Gullet" and d.Size ~= e.Size then
					sized = false
				end
			end
		end
		check(#a == #b and worst < 1e-3 and sized,
			string.format("%s: after walking, turning and stopping, at rest it is the authored model again (%.5f studs)", id,
				worst))
		fresh:Destroy()
		model:Destroy()
		still:Destroy()
		carried:Destroy()
	end

	--==========================================================================
	say("3. One owner per joint, and normal species as they were")
	--==========================================================================
	local swaySrc = sourceOf(Scripts, "PlantSway")
	check(string.find(swaySrc, "bob = if secretRig then 0 else math.min(headHeight * BOB_FRACTION, BOB_CEILING)", 1, true)
			and string.find(swaySrc, "if not entry.secret then\n\t\t\taz += math.sin(stride * math.pi * 2) * ROLL_AMP * moveT", 1, true)
			and string.find(swaySrc, "if not entry.pod and not entry.secret then\n\t\tentry.lookPhase", 1, true),
		"PlantSway moves and turns a Secret along its leg but draws no bob, roll or look-around of its own")
	check(string.find(swaySrc, "not entry.pod and not secretRig", 1, true) ~= nil,
		"PlantSway still never touches a Secret's leaves, legs, roots, gaze or lids")
	check(string.find(swaySrc, "local SECRET_TURN_RATE = " .. TURN_RATE, 1, true) ~= nil
			and string.find(swaySrc, "local SECRET_TURN_MAX = " .. TURN_MAX, 1, true) ~= nil
			and string.find(swaySrc, "entry.facing += delta * (1 - math.exp(-dt / TURN_TAU))", 1, true) ~= nil,
		"a Secret turns on PlantSway's damped, capped swing (the one replayed above); every other walker as before")
	local idleClient = sourceOf(Scripts, "SecretIdle")
	check(string.find(idleClient, "rig.walks = CollectionService:HasTag(model, PLANTED)", 1, true) ~= nil,
		"only a PLANTED Secret steps; the copy carried overhead does not")
	check(GameConfig.Secret.Enabled == false, "natural Secret spawning is off (the owner, 2026-10-10: \"turn off secrets for now\")")
end)

scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("SecretWalkSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
