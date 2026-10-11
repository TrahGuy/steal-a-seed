--!nocheck
--==============================================================================
-- Steal a Seed :: MosskeeperMoodsSpec
--
-- The Mosskeeper's moods and moments (2026-10-11, the owner's item 7b):
-- Shared/MosskeeperIdle driven on a real build of him, and MosskeeperView read
-- for the wiring. Edit mode:
--
--   1. a late joiner: the mood set outright on a brain's first step
--   2. sleepy between Mists: the nod-off, the lean, the half-shut eyes, the dim
--      Dewdrop; a player who walks up wakes him, WakeHold after they leave he
--      dozes again
--   3. lively during a Mist: a beckon now and then, the brighter glow
--   4. the start: looks up, raises his staff, the Dewdrop flares (one burst),
--      the bow -- and over by its length
--   5. the end: the goodbye wave, the yawn
--   6. Reduced Motion (no moments), Reduced FX (no burst, no extra glow), a talk
--      begun mid-moment wins
--   7. nothing drifts in a mood
--   8. the wiring: the replicated MistState, live changes only, waiting out a talk
--
-- Not here, seen in the guarded Play: how the poses look.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local MosskeeperModel = require(Shared:WaitForChild("MosskeeperModel"))
local Idle = require(Shared:WaitForChild("MosskeeperIdle"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local stage = Instance.new("Folder")
stage.Name = "MosskeeperMoodsSpecStage"
stage.Parent = Workspace

-- His joint's pitch (up positive), whatever its turn; a joint's own angles.
local function pitch(brain, name)
	local cf = brain.pose[name]
	return if cf then math.asin(math.clamp(cf.LookVector.Y, -1, 1)) else 0
end
local function angles(brain, name)
	local cf = brain.pose[name]
	if not cf then
		return 0, 0, 0
	end
	return cf:ToEulerAnglesXYZ()
end
local function still()
	return 0.5
end
local function steps(brain, t0, frames, input)
	for i = 0, frames do
		brain.step(t0 + i / 60, input)
	end
end

local ok, err = pcall(function()
	local npc = MosskeeperModel.build(CFrame.new(700, 20, 700), stage)
	local pivot = npc:GetPivot()
	local lamp = npc:FindFirstChild("DewGlow", true)
	local motes = npc:FindFirstChild("DewSparkle", true)
	local halo = npc:FindFirstChild("DewHalo", true)
	local function quiet(mood, moment, extra)
		local input = { players = {}, serving = false, reducedFx = false, mood = mood, moment = moment,
			reducedMotion = false }
		for k, v in pairs(extra or {}) do
			input[k] = v
		end
		return input
	end

	--==========================================================================
	say("1. A late joiner")
	--==========================================================================
	local a = Idle.new(npc, still)
	a.step(5000, quiet("sleepy"))
	local b = Idle.new(npc, still)
	b.step(5000, quiet("lively"))
	local c = Idle.new(npc, still)
	c.step(5000, quiet(nil))
	check(a.sleepy == 1 and a.lively == 0 and b.lively == 1 and b.sleepy == 0 and c.sleepy == 0 and c.lively == 0,
		"the mood is set outright on a brain's first step: a late joiner sees him sleepy or lively at once; no mood, "
			.. "the classic idle", string.format("%.2f %.2f %.2f", a.sleepy, b.lively, c.sleepy))

	--==========================================================================
	say("2. Sleepy between Mists")
	--==========================================================================
	local s = Idle.new(npc, still)
	local P = Idle.NodPeriod
	local base = 7000 * P -- a nod cycle's start
	steps(s, base + 0.83 * P - 1, 60, quiet("sleepy"))
	local drooped, droopPitch = s.nod, pitch(s, "HeadJoint")
	local lidDown = s.pose.LidRJoint.Position.Y
	local dim = lamp.Brightness
	local haloAsleep = halo.Transparency
	local _, _, lean = angles(s, "BodyJoint")
	steps(s, base + 0.95 * P - 1, 60, quiet("sleepy"))
	local caught, caughtPitch = s.nod, pitch(s, "HeadJoint")
	check(drooped > 0.9 and caught < 0.05 and droopPitch < caughtPitch - 0.25,
		"asleep he nods off slowly over most of the cycle, then catches himself",
		string.format("nod %.2f -> %.2f, head %.2f -> %.2f", drooped, caught, droopPitch, caughtPitch))
	check(lidDown < -0.18 and lean > 0.03,
		"his eyes half shut and he leans on his staff", string.format("lid %.2f, lean %.2f", lidDown, lean))
	-- The classic idle's lamp at the very same moment: asleep it is well under it.
	local l = Idle.new(npc, still)
	steps(l, base + 0.83 * P - 1, 60, quiet(nil))
	local classic = lamp.Brightness
	check(dim < classic * 0.6 and haloAsleep > 0.9,
		"the Dewdrop dims asleep", string.format("lamp %.2f asleep, %.2f awake; halo %.2f", dim, classic, haloAsleep))
	-- A player walks up: he wakes and turns to them; WakeHold after they go, he dozes.
	local w = Idle.new(npc, still)
	local side = { (pivot * CFrame.new(-7, 3, -7)).Position }
	steps(w, 9000, 120, quiet("sleepy"))
	local asleep = w.sleepy
	steps(w, 9002, 90, quiet("sleepy", nil, { players = side }))
	local woke, turned = w.sleepy, w.lookYaw
	local gone = { (pivot * CFrame.new(0, 3, -60)).Position }
	steps(w, 9003.6, 150, quiet("sleepy", nil, { players = gone }))
	local held = w.sleepy
	steps(w, 9006.2, 600, quiet("sleepy", nil, { players = gone }))
	local dozed = w.sleepy
	check(asleep > 0.99 and woke < 0.1 and turned > 0.3 and held < 0.15 and dozed > 0.85,
		string.format("a player who walks up wakes him and he turns to them; %gs after they leave he dozes off again",
			Idle.WakeHold),
		string.format("%.2f -> %.2f (yaw %.2f), %.2f held, %.2f later", asleep, woke, turned, held, dozed))

	--==========================================================================
	say("3. Lively during a Mist")
	--==========================================================================
	local v = Idle.new(npc, still)
	local B = Idle.BeckonPeriod
	steps(v, 3000 * B + 1.0 - 1, 60, quiet("lively"))
	local beckon = angles(v, "ShoulderRJoint")
	steps(v, 3000 * B + 5.0 - 1, 60, quiet("lively"))
	local rest = angles(v, "ShoulderRJoint")
	check(beckon > 0.7 and math.abs(rest) < 0.1,
		"a beckon now and then while a Mist is on, the free arm at rest between",
		string.format("shoulder %.2f at the beckon, %.2f between", beckon, rest))
	local glow = npc:FindFirstChild("SatchelGlow", true)
	check(glow ~= nil and glow.Enabled and glow.Brightness > 1 and halo.Transparency < 0.8,
		"his satchel and the Dewdrop glow brighter", glow and string.format("%.2f, halo %.2f", glow.Brightness,
			halo.Transparency))

	--==========================================================================
	say("4. The start")
	--==========================================================================
	local st = Idle.new(npc, still)
	local m0 = 4000
	local start = { kind = "start", at = m0 }
	steps(st, m0 - 1, 60, quiet("lively", start))
	local calm = pitch(st, "HeadJoint")
	steps(st, m0 + 0.45 - 0.2, 12, quiet("lively", start))
	local lookUp = pitch(st, "HeadJoint")
	steps(st, m0 + 1.5 - 0.2, 12, quiet("lively", start))
	local raisedX = angles(st, "ShoulderLJoint")
	local lifted = st.pose.StaffJoint.Position.Y
	local flared, flareLamp = st.flare, lamp.Brightness
	steps(st, m0 + 2.85 - 0.2, 12, quiet("lively", start))
	local bowed = angles(st, "WaistJoint")
	steps(st, m0 + 3.6 - 0.2, 12, quiet("lively", start))
	check(lookUp > calm + 0.3, "he looks up at the sky", string.format("head %.2f -> %.2f", calm, lookUp))
	check(raisedX > 0.5 and lifted > 0.8, "he raises his staff: the staff lifts, his hand rising with it",
		string.format("shoulder %.2f, staff up %.2f", raisedX, lifted))
	check(flared > 0.95 and flareLamp > 5 and st.bursts == 1,
		"the Dewdrop flares with one mint burst", string.format("flare %.2f, lamp %.2f, bursts %d", flared, flareLamp,
			st.bursts))
	check(bowed < -0.3, "then a happy little bow toward the road", string.format("waist %.2f", bowed))
	check(st.moment == nil and st.bursts == 1 and math.abs(Idle.Moments.start - 3.48) < 0.05,
		"over by its length, the BEGINS clip's", tostring(st.moment))

	--==========================================================================
	say("5. The end")
	--==========================================================================
	local en = Idle.new(npc, still)
	local finish = { kind = "end", at = 6000 }
	steps(en, 6000 + 0.9 - 0.2, 12, quiet("sleepy", finish))
	local _, _, waveZ = angles(en, "ShoulderRJoint")
	steps(en, 6000 + 2.6 - 0.2, 12, quiet("sleepy", finish))
	local yawnHead = pitch(en, "HeadJoint")
	local yawnLid = en.pose.LidRJoint.Position.Y
	steps(en, 6000 + 4.2 - 0.2, 12, quiet("sleepy", finish))
	check(waveZ < -1.5, "he waves goodbye toward the road", string.format("shoulder %.2f", waveZ))
	check(yawnHead > 0.2 and yawnLid < -0.3, "then yawns, eyes shut", string.format("head %.2f, lid %.2f", yawnHead,
		yawnLid))
	check(en.moment == nil and en.sleepy > 0.99, "and settles into the sleepy idle", string.format("%.2f", en.sleepy))

	--==========================================================================
	say("6. Reduced Motion, Reduced FX, a talk")
	--==========================================================================
	local rm = Idle.new(npc, still)
	steps(rm, 7000 + 1.5 - 0.2, 12, quiet("lively", { kind = "start", at = 7000 }, { reducedMotion = true }))
	local rx = angles(rm, "ShoulderLJoint")
	check(rm.moment == nil and rm.bursts == 0 and math.abs(rx) < 1e-6 and rm.lively == 1,
		"Reduced Motion: the moods stay, the moments never play")
	local fx = Idle.new(npc, still)
	steps(fx, 7100 + 1.5 - 0.2, 12, quiet("lively", { kind = "start", at = 7100 }, { reducedFx = true }))
	check(fx.bursts == 0 and math.abs(lamp.Brightness - 1.2) < 1e-6 and not motes.Enabled
			and math.abs(halo.Transparency - 0.84) < 1e-3 and glow ~= nil and not glow.Enabled,
		"Reduced FX: no burst, no flare, the glow steady and the satchel's off",
		string.format("bursts %d, lamp %.2f, halo %.2f", fx.bursts, lamp.Brightness, halo.Transparency))
	local tk = Idle.new(npc, still)
	local talkStart = { kind = "start", at = 7200 }
	steps(tk, 7200 - 0.5, 60, quiet("lively", talkStart))
	steps(tk, 7201, 60, quiet("lively", talkStart,
		{ serving = true, players = { (pivot * CFrame.new(0, 3, -6)).Position } }))
	local txAfter = angles(tk, "ShoulderLJoint")
	check(math.abs(txAfter) < 0.08 and tk.busy > 0.9,
		"a talk begun mid-moment wins: the moment gives way as he turns to serve",
		string.format("staff arm %.2f, busy %.2f", txAfter, tk.busy))

	--==========================================================================
	say("7. Nothing drifts in a mood")
	--==========================================================================
	for _, mood in ipairs({ "sleepy", "lively" }) do
		local long = Idle.new(npc, still)
		steps(long, 20000, 18000, quiet(mood))
		local twin = MosskeeperModel.build(CFrame.new(900, 20, 900), stage)
		local fresh = Idle.new(twin, still)
		steps(fresh, 20300 - 1, 60, quiet(mood))
		local drift = 0
		for _, name in ipairs(Idle.JointNames) do
			if name ~= "LidRJoint" and name ~= "LidLJoint" then
				local x = (npc:FindFirstChild(name, true) :: Motor6D).Transform
				local y = (twin:FindFirstChild(name, true) :: Motor6D).Transform
				drift = math.max(drift, (x.Position - y.Position).Magnitude, (x.LookVector - y.LookVector).Magnitude,
					(x.UpVector - y.UpVector).Magnitude)
			end
		end
		twin:Destroy()
		check(drift < 1e-4, mood .. ": after five minutes his pose is a fresh one's at the same moment",
			string.format("%.2e", drift))
	end

	--==========================================================================
	say("8. The wiring (MosskeeperView)")
	--==========================================================================
	local view = StarterPlayer.StarterPlayerScripts.MosskeeperView.Source
	check(has(view, "local mistNow = Workspace:GetAttribute(MIST)")
			and has(view, "local pending: { kind: string, since: number }? = nil\n")
			and has(view, "if mistNow == ACTIVE and was ~= ACTIVE then\n\t\tpending = { kind = \"start\", since = os.clock() }")
			and has(view, "elseif was == ACTIVE and mistNow ~= ACTIVE then\n\t\tpending = { kind = \"end\", since = os.clock() }")
			and has(view, "mood = if mistNow == ACTIVE then \"lively\" else \"sleepy\","),
		"his mood from the replicated MistState; a moment only on a change this client sees, never at a join")
	check(has(view, "elseif not serving then\n\t\t\tmoment = { kind = due.kind, at = now }")
			and has(view, "if now - due.since > MOMENT_PATIENCE then"),
		"a moment waits out a talk, and one kept waiting too long is let go")
	check(has(view, "reducedFx = reduced,\n\t\treducedMotion = reduced,"),
		"Reduced FX and Reduced Motion: this game's one setting, passed as both")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
stage:Destroy()
say(string.format("\nMosskeeperMoodsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
