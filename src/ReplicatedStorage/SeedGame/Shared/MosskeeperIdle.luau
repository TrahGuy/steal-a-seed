--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperIdle (2026-10-11, Enchanted Mist stage 3)
--
-- MOSSKEEPER'S LIFE, ported from the owner's own builder's brain
-- (D:/KAPE/Mosskeeper/mosskeeper_npc_paste.luau, runMosskeeper): he breathes,
-- blinks, sways his beard, hood tail, cloak and mantle, bobs and turns his
-- Dewdrop, watches the nearest player (head and eyes first, a little of the
-- body; the feet stay put), waves when somebody walks up, and bows, opens his
-- satchel and spreads his mantle while serving. The same motion, the same
-- numbers. Left out: the builder's speech bubble and its lines, and its prompt
-- (the dialogue is MosskeeperUI's; "serving" is the local player's open
-- dialogue).
--
-- RUN ON EACH CLIENT, NEVER THE SERVER (MosskeeperView). Every pose is set
-- ABSOLUTELY from the clock -- Motor6D.Transform, never a delta on the last
-- frame -- so nothing drifts however long it runs; the only state carried is
-- the eased look and bow, which converge on their targets. Reduced FX keeps
-- the motion and stills the decorative glow: the Dewdrop's light holds steady
-- and its motes stop.
--
-- MOODS AND MOMENTS (the owner, 2026-10-11; MosskeeperView reads the
-- replicated MistState on each client, so a late joiner sees the right mood):
--   mood "sleepy"  between Mists: he nods off on a slow cycle, leans on his
--                  staff, breathes slower, eyes half shut, the Dewdrop dim. A
--                  player who walks up (GreetRange) or talks wakes him: he
--                  turns and faces them, and WakeHold seconds after they leave
--                  he dozes off again.
--   mood "lively"  a Mist on: a cheerful sway, a beckon now and then, the
--                  Dewdrop and his satchel glowing brighter.
--   moment "start" a Mist beginning (a live change only): he looks up at the
--                  sky, raises his staff, the Dewdrop flares mint, then a happy
--                  little bow toward the road (his front) -- the BEGINS clip's
--                  length.
--   moment "end"   a Mist ending: he waves goodbye toward the road, yawns and
--                  settles into the sleepy idle.
-- All absolute from the clock like the rest; a mood comes in eased, but on a
-- brain's first step it is set outright. Reduced Motion keeps the moods without
-- the moments; Reduced FX drops the flare, the burst and the extra glow. No
-- mood: the classic idle above, unchanged.
--==============================================================================
local MosskeeperIdle = {}

local sin, exp, abs, clamp = math.sin, math.exp, math.abs, math.clamp

MosskeeperIdle.LookRange = 26 -- he watches players inside this distance
MosskeeperIdle.GreetRange = 14 -- a player who walks inside this gets a wave
MosskeeperIdle.GreetCooldown = 14 -- seconds before he waves at the next newcomer
MosskeeperIdle.WakeHold = 4 -- seconds awake after the last player near him leaves or stops talking
MosskeeperIdle.NodPeriod = 7 -- seconds, one nod-off and its catch
MosskeeperIdle.BeckonPeriod = 9 -- seconds, a beckon now and then while a Mist is on
-- The moments' lengths, seconds: the start the BEGINS clip's 3.48.
MosskeeperIdle.Moments = { start = 3.5, ["end"] = 4 }

-- The builder's joint axes for the new moves, read off Edit previews (2026-10-11).
-- His staff hangs from his pelvis, not his hand: raising it lifts the staff
-- itself, the arm rising with it so the hand stays on it.
local LEAN = 0.06 -- BodyJoint roll: toward the staff
local BECKON_X, BECKON_ELBOW = 0.9, 1.2 -- the free arm forward, its forearm up: "come here"
local RAISE_X = 0.95 -- ShoulderLJoint pitch: the staff hand up the staff
local STAFF_LIFT = 1.2 -- studs, the staff up with it
local YAWN_REACH = 2.5 -- the free arm overhead in a stretch

MosskeeperIdle.JointNames = { "BodyJoint", "WaistJoint", "NeckJoint", "HeadJoint", "EyeRJoint", "EyeLJoint",
	"LidRJoint", "LidLJoint", "BeardJoint", "BeardTipJoint", "HoodTailJoint", "MantleRJoint", "MantleLJoint",
	"CloakJoint", "CloakLowJoint", "ShoulderRJoint", "ElbowRJoint", "WristRJoint", "FingerRJoint", "ShoulderLJoint",
	"ElbowLJoint", "SatchelJoint", "SatchelFlapJoint", "StaffJoint", "DewJoint" }

-- The angle of the direction (x, y), measured from +x.
local function atan2(y: number, x: number): number
	if x > 0 then
		return math.atan(y / x)
	elseif x < 0 then
		if y >= 0 then
			return math.atan(y / x) + math.pi
		end
		return math.atan(y / x) - math.pi
	elseif y > 0 then
		return math.pi / 2
	elseif y < 0 then
		return -math.pi / 2
	end
	return 0
end

-- 0 up to a, eased up to 1 by b, 1 until c, eased back to 0 by d.
local function env(x: number, a: number, b: number, c: number, d: number): number
	if x <= a or x >= d then
		return 0
	elseif x < b then
		local u = (x - a) / (b - a)
		return u * u * (3 - 2 * u)
	elseif x <= c then
		return 1
	end
	local u = (d - x) / (d - c)
	return u * u * (3 - 2 * u)
end
MosskeeperIdle.env = env

export type Moment = { kind: string, at: number }

export type Input = {
	-- Every player's root position (the nearest is watched and greeted).
	players: { Vector3 },
	-- The local player is talking to him: he serves (bows, opens his satchel).
	serving: boolean,
	reducedFx: boolean,
	-- "sleepy" (between Mists) or "lively" (a Mist on); nil: the classic idle.
	mood: string?,
	-- A moment ("start" / "end") from `at` on this clock; nil: none.
	moment: Moment?,
	-- No moments at all (the moods stay).
	reducedMotion: boolean?,
}

export type Brain = {
	step: (t: number, input: Input) -> (),
	rest: () -> (),
	pose: { [string]: CFrame },
	lookYaw: number,
	busy: number,
	wave: number,
	-- How far into each mood he is (0..1), the moment playing now (nil: none),
	-- the Dewdrop's flare and the nod (0..1): for specs and MosskeeperView.
	sleepy: number,
	lively: number,
	moment: string?,
	flare: number,
	nod: number,
	-- How many mint bursts the flare has thrown (one a start).
	bursts: number,
}

-- `model` is a MosskeeperModel; `random` (0..1) is the blink jitter, a
-- stand-in's in a spec.
function MosskeeperIdle.new(model: Model, random: (() -> number)?): Brain
	local rng = random or math.random
	local J: { [string]: Motor6D } = {}
	for _, n in ipairs(MosskeeperIdle.JointNames) do
		local j = model:FindFirstChild(n, true)
		if j and j:IsA("Motor6D") then
			J[n] = j
		end
	end
	local lamp = model:FindFirstChild("DewGlow", true) :: PointLight?
	local sparkle = model:FindFirstChild("DewSparkle", true) :: ParticleEmitter?
	local halo = model:FindFirstChild("DewHalo", true) :: BasePart?
	-- The halo's own transparency, kept on it the first time: a later brain on
	-- the same him reads the builder's, not whatever the last one left.
	local haloRest = 0.84
	if halo then
		local kept = halo:GetAttribute("RestTransparency")
		if type(kept) ~= "number" then
			kept = halo.Transparency
			halo:SetAttribute("RestTransparency", kept)
		end
		haloRest = kept :: number
	end
	local footing = model.PrimaryPart :: BasePart
	-- His satchel's glow while a Mist is on: a light made here, on this client.
	local satchelGlow: PointLight? = nil
	local clasp = model:FindFirstChild("PodClasp", true)
	if clasp and clasp:IsA("BasePart") then
		local made = clasp:FindFirstChild("SatchelGlow")
		if not (made and made:IsA("PointLight")) then
			local light = Instance.new("PointLight")
			light.Name = "SatchelGlow"
			light.Color = Color3.fromRGB(150, 255, 196)
			light.Range = 7
			light.Brightness = 0
			light.Shadows = false
			light.Enabled = false
			light.Parent = clasp
			made = light
		end
		satchelGlow = made :: PointLight
	end

	local brain = {} :: Brain
	brain.pose = {}
	brain.lookYaw, brain.busy, brain.wave = 0, 0, 0
	brain.sleepy, brain.lively, brain.flare, brain.nod, brain.bursts = 0, 0, 0, 0, 0
	local awakeUntil = -math.huge
	local burstFor: number? = nil
	local lookPitch = 0
	local waveStart, waveUntil = 0, 0
	local greetReady, greetNear = 0, false
	local blinkAt, blinkT0 = 2.5, -10
	local lastT: number? = nil

	local function set(name: string, cf: CFrame)
		brain.pose[name] = cf
		local j = J[name]
		if j then
			j.Transform = cf
		end
	end

	function brain.step(t: number, input: Input)
		local first = lastT == nil
		local dt = clamp(t - (lastT or (t - 1 / 60)), 1 / 240, 0.1)
		lastT = t
		local serving = input.serving
		brain.busy += ((if serving then 1 else 0) - brain.busy) * (1 - exp(-dt * 5))
		local bow = brain.busy

		-- Who is near? (positions in his own frame: -Z is his front)
		local fInv = footing.CFrame:Inverse()
		local nd, nlp = 1e9, nil :: Vector3?
		for _, at in ipairs(input.players) do
			local lp = fInv * at
			local d = math.sqrt(lp.X * lp.X + lp.Z * lp.Z)
			if d < nd then
				nd, nlp = d, lp
			end
		end

		-- AWAKE: a player near him or talking, and WakeHold after. THE MOODS:
		-- eased in (sleep slowly, waking quickly), outright on a first step.
		if serving or (nlp and nd < MosskeeperIdle.GreetRange) then
			awakeUntil = t + MosskeeperIdle.WakeHold
		end
		local mood = input.mood
		local sleepyT = if mood == "sleepy" and t >= awakeUntil then 1 else 0
		local livelyT = if mood == "lively" then 1 else 0
		if first then
			brain.sleepy, brain.lively = sleepyT, livelyT
		else
			brain.sleepy += (sleepyT - brain.sleepy) * (1 - exp(-dt * (if sleepyT < brain.sleepy then 4 else 0.7)))
			brain.lively += (livelyT - brain.lively) * (1 - exp(-dt * 1.5))
		end
		local sleepy, lively = brain.sleepy, brain.lively

		-- THE MOMENT playing, from its own start on this clock.
		local m = input.moment
		local mt = if m and not input.reducedMotion then t - m.at else -1
		local kind = if m and mt >= 0 and mt <= (MosskeeperIdle.Moments[m.kind] or 0) then m.kind else nil
		brain.moment = kind
		local up, raise, flare, cheer, bye, yawn = 0, 0, 0, 0, 0, 0
		-- A talk that begins mid-moment wins: the moment gives way as he turns to serve.
		local give = 1 - bow
		if kind == "start" then
			up = env(mt, 0, 0.5, 1.4, 1.9) * give
			raise = env(mt, 0.5, 1.1, 1.9, 2.5) * give
			flare = exp(-((mt - 1.5) / 0.35) ^ 2) * give
			cheer = env(mt, 2.3, 2.7, 3.05, 3.5) * give
		elseif kind == "end" then
			bye = env(mt, 0, 0.35, 1.5, 1.85) * give
			yawn = env(mt, 1.85, 2.35, 2.9, 3.5) * give
		end
		brain.flare = flare
		local inMoment = math.max(up, raise, cheer, bye, yawn)

		-- Where he looks: the nearest player in range (while the local player
		-- talks to him they are the one standing there).
		local yawT, pitchT = 0, 0
		if nlp and (nd < MosskeeperIdle.LookRange or serving) then
			local ang = atan2(-nlp.X, -nlp.Z)
			if abs(ang) < 2.4 then
				yawT = ang
				pitchT = clamp(atan2(nlp.Y + 1.5 - 4.4, math.max(nd, 1)), -0.5, 0.5)
			end
		end
		-- Asleep he watches nobody; looking up at the sky, nobody either.
		local watchable = (1 - sleepy) * (1 - up)
		yawT, pitchT = yawT * watchable, pitchT * watchable
		local k = 1 - exp(-dt * 3.5)
		brain.lookYaw += (yawT - brain.lookYaw) * k
		lookPitch += (pitchT - lookPitch) * k
		local lookYaw = brain.lookYaw
		local watching = abs(yawT) > 0.001 or abs(pitchT) > 0.001

		-- The greeting: a newcomer walks inside GreetRange.
		if nlp and nd < MosskeeperIdle.GreetRange then
			if not greetNear then
				greetNear = true
				if t >= greetReady and not serving then
					greetReady = t + MosskeeperIdle.GreetCooldown
					waveStart = t
					waveUntil = t + 2.8
				end
			end
		elseif not nlp or nd > MosskeeperIdle.GreetRange + 4 then
			greetNear = false
		end
		if serving then
			waveUntil = math.min(waveUntil, t + 0.25)
		end
		local wave = 0
		if t < waveUntil then
			wave = clamp(math.min(1, (t - waveStart) / 0.4) * math.min(1, (waveUntil - t) / 0.4), 0, 1)
		end
		brain.wave = wave
		-- Goodbye is the same wave, from the moment's own start.
		local waving = math.max(wave, bye)
		local waveFrom = if bye > wave and m then m.at else waveStart

		-- The nod-off: drooping slowly over most of the cycle, a quick catch at
		-- its end. The beckon: now and then while a Mist is on, the free arm
		-- idle. Neither while a moment plays.
		local phase = (t % MosskeeperIdle.NodPeriod) / MosskeeperIdle.NodPeriod
		local droop = if phase < 0.85 then env(phase, 0, 0.85, 0.85, 1) else math.max(0, 1 - (phase - 0.85) / 0.08)
		local nod = sleepy * (1 - inMoment) * droop
		brain.nod = nod
		local beck = lively * (1 - inMoment) * (1 - math.max(waving, bow))
			* env(t % MosskeeperIdle.BeckonPeriod, 0, 0.35, 1.7, 2.1)

		-- Turning: the head and eyes lead, the body follows a little.
		local bodyYaw = clamp(lookYaw * 0.2, -0.2, 0.2)
		local rest = lookYaw - bodyYaw
		local neckYaw = clamp(rest * 0.3, -0.35, 0.35)
		local headYaw = clamp(rest - neckYaw, -0.8, 0.8)
		local eyeYaw = rest - neckYaw - headYaw
		-- Asleep he breathes slower and deeper.
		local br = (1 - sleepy) * sin(t * 1.5) + sleepy * 1.3 * sin(t * 0.8)
		set("BodyJoint", CFrame.Angles(0, bodyYaw, 0.01 * sin(t * 1.1) + LEAN * sleepy + 0.035 * sin(t * 1.8) * lively))
		set("WaistJoint", CFrame.Angles(0.015 * br - 0.12 * bow - 0.06 * sleepy + 0.02 * sin(t * 3.6) * lively
			- 0.35 * cheer + 0.1 * yawn, 0, 0))
		set("NeckJoint", CFrame.Angles(0, neckYaw, 0) * CFrame.Angles(0.012 * sin(t * 1.5 + 0.4) - 0.05 * bow
			+ lookPitch * 0.3 - 0.12 * nod + 0.2 * up + 0.1 * yawn - 0.05 * cheer, 0, 0))
		local idleLook = 0
		if not watching then
			idleLook = 0.25 * sin(t * 0.45) * (0.5 + 0.5 * sin(t * 0.21)) * (1 - sleepy) * (1 - up)
		end
		set("HeadJoint", CFrame.Angles(0, headYaw + idleLook, 0)
			* CFrame.Angles(0.02 * sin(t * 1.2) - 0.06 * bow + lookPitch * 0.6 - 0.38 * nod + 0.45 * up + 0.3 * yawn
				- 0.1 * cheer, 0, 0.025 * sin(t * 0.8) + 0.1 * waving + 0.06 * sin(t * 1.8) * lively))

		-- Eyes: slide in their sockets toward what he watches; blink now and then.
		local ex, ey = 0.025 * sin(t * 0.7 + 1), 0.01 * sin(t * 0.9)
		if watching then
			ex = clamp(-eyeYaw * 0.2, -0.06, 0.06)
			ey = clamp(lookPitch * 0.1, -0.04, 0.04)
		end
		set("EyeRJoint", CFrame.new(ex, ey, 0))
		set("EyeLJoint", CFrame.new(ex, ey, 0))
		if t >= blinkAt then
			blinkT0 = t
			blinkAt = t + 2.6 + rng() * 3.4
		end
		local bt = t - blinkT0
		local blink = if bt < 0.17 then sin(math.pi * bt / 0.17) else 0
		local lid = -0.37 * math.max(blink, 0.15 * waving, sleepy * (0.55 + 0.45 * nod), yawn)
		set("LidRJoint", CFrame.new(0, lid, 0))
		set("LidLJoint", CFrame.new(0, lid, 0))

		-- Beard, hood tail, cloak and mantle sway; the mantle puffs open when he serves.
		set("BeardJoint", CFrame.Angles(0.03 * sin(t * 1.5), 0, 0.02 * sin(t * 1.1)))
		set("BeardTipJoint", CFrame.Angles(0.07 * sin(t * 2.0 + 1), 0, 0.08 * sin(t * 1.4)))
		set("HoodTailJoint", CFrame.Angles(0.04 * sin(t * 1.2 + 0.5) + 0.04 * bow, 0, 0))
		set("CloakJoint", CFrame.Angles(0.02 * sin(t * 0.9) + 0.03 * bow, 0, 0))
		set("CloakLowJoint", CFrame.Angles(0.04 * sin(t * 1.1 + 0.7), 0, 0.015 * sin(t * 0.8)))
		local puff = 0.02 * br + 0.2 * bow
		set("MantleRJoint", CFrame.Angles(0, 0, -puff))
		set("MantleLJoint", CFrame.Angles(0, 0, puff))

		-- The free right arm: a relaxed sway, the greeting wave (or goodbye),
		-- a beckon while a Mist is on, a stretch in the yawn.
		local wv = sin(9 * (t - waveFrom))
		local curl = 0.5 + 0.5 * sin(t * 7)
		set("ShoulderRJoint", CFrame.Angles(0.03 * sin(t * 1.1) + BECKON_X * beck, 0, -0.04 + 0.03 * sin(t * 1.3 + 1)
			- 1.9 * waving - YAWN_REACH * yawn))
		set("ElbowRJoint", CFrame.Angles(0.08 + 0.03 * sin(t * 1.3) + beck * (BECKON_ELBOW + 0.35 * sin(t * 7)), 0,
			(-1.2 + 0.3 * wv) * waving - 0.6 * yawn))
		set("WristRJoint", CFrame.Angles(0.04 * sin(t * 1.2), 0, 0.2 * wv * waving))
		set("FingerRJoint", CFrame.Angles(0.1 + 0.06 * sin(t * 1.0) + 0.1 * wv * waving + 0.5 * beck * curl, 0, 0))
		-- The staff arm holds still (the hand grips the staff) but for the start's
		-- raise; only the Dewdrop moves, a little higher in its flare.
		set("ShoulderLJoint", CFrame.Angles(RAISE_X * raise, 0, 0))
		set("ElbowLJoint", CFrame.new())
		set("StaffJoint", CFrame.new(0, STAFF_LIFT * raise, 0))
		-- The turn is taken modulo a full circle in doubles first (a huge clock
		-- angle quantizes in CFrame.Angles).
		set("DewJoint", CFrame.new(0, 0.09 * sin(t * 1.8) + 0.12 * flare, 0)
			* CFrame.Angles(0, (t * 0.9) % (2 * math.pi), 0))

		-- The pod satchel swings; it opens for a customer.
		set("SatchelJoint", CFrame.Angles(0.02 * sin(t * 1.7 + 1), 0, 0.03 * sin(t * 1.3)))
		set("SatchelFlapJoint", CFrame.Angles(1.15 * bow + 0.03 * sin(t * 2.3) * bow, 0, 0))

		-- The glow: alive -- brighter in a Mist and in the start's flare, dim
		-- asleep -- or steady and still under Reduced FX.
		if lamp then
			if input.reducedFx then
				lamp.Brightness = 1.2
				lamp.Range = 14
			else
				lamp.Brightness = (1.2 + 0.25 * sin(t * 2.4) + 1.6 * bow + 0.9 * lively + 5 * flare) * (1 - 0.6 * sleepy)
				lamp.Range = 14 + 4 * bow + 4 * lively + 8 * flare
			end
		end
		if sparkle then
			sparkle.Enabled = not input.reducedFx
			sparkle.Rate = (4 + 10 * bow + 6 * lively) * (1 - 0.8 * sleepy)
			-- The flare's mint burst: once a start, at its peak.
			if kind == "start" and m and mt >= 1.45 and burstFor ~= m.at and not input.reducedFx then
				burstFor = m.at
				brain.bursts += 1
				sparkle:Emit(24)
			end
		end
		if halo then
			halo.Transparency = if input.reducedFx then haloRest
				else clamp(haloRest - 0.5 * flare - 0.1 * lively + 0.12 * sleepy, 0.2, 0.97)
		end
		if satchelGlow then
			satchelGlow.Enabled = not input.reducedFx and lively > 0.02
			satchelGlow.Brightness = 1.4 * lively
		end
	end

	-- Back to the builder's rest pose (every Transform identity).
	function brain.rest()
		for name, j in pairs(J) do
			j.Transform = CFrame.new()
			brain.pose[name] = CFrame.new()
		end
	end

	return brain
end

return MosskeeperIdle
