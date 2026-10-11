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
--==============================================================================
local MosskeeperIdle = {}

local sin, exp, abs, clamp = math.sin, math.exp, math.abs, math.clamp

MosskeeperIdle.LookRange = 26 -- he watches players inside this distance
MosskeeperIdle.GreetRange = 14 -- a player who walks inside this gets a wave
MosskeeperIdle.GreetCooldown = 14 -- seconds before he waves at the next newcomer

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

export type Input = {
	-- Every player's root position (the nearest is watched and greeted).
	players: { Vector3 },
	-- The local player is talking to him: he serves (bows, opens his satchel).
	serving: boolean,
	reducedFx: boolean,
}

export type Brain = {
	step: (t: number, input: Input) -> (),
	rest: () -> (),
	pose: { [string]: CFrame },
	lookYaw: number,
	busy: number,
	wave: number,
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
	local footing = model.PrimaryPart :: BasePart

	local brain = {} :: Brain
	brain.pose = {}
	brain.lookYaw, brain.busy, brain.wave = 0, 0, 0
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
		local dt = clamp(t - (lastT or (t - 1 / 60)), 1 / 240, 0.1)
		lastT = t
		local serving = input.serving

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
		local k = 1 - exp(-dt * 3.5)
		brain.lookYaw += (yawT - brain.lookYaw) * k
		lookPitch += (pitchT - lookPitch) * k
		local lookYaw = brain.lookYaw
		local watching = abs(yawT) > 0.001 or abs(pitchT) > 0.001
		brain.busy += ((if serving then 1 else 0) - brain.busy) * (1 - exp(-dt * 5))
		local bow = brain.busy

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

		-- Turning: the head and eyes lead, the body follows a little.
		local bodyYaw = clamp(lookYaw * 0.2, -0.2, 0.2)
		local rest = lookYaw - bodyYaw
		local neckYaw = clamp(rest * 0.3, -0.35, 0.35)
		local headYaw = clamp(rest - neckYaw, -0.8, 0.8)
		local eyeYaw = rest - neckYaw - headYaw
		local br = sin(t * 1.5)
		set("BodyJoint", CFrame.Angles(0, bodyYaw, 0.01 * sin(t * 1.1)))
		set("WaistJoint", CFrame.Angles(0.015 * br - 0.12 * bow, 0, 0))
		set("NeckJoint", CFrame.Angles(0, neckYaw, 0) * CFrame.Angles(0.012 * sin(t * 1.5 + 0.4) - 0.05 * bow
			+ lookPitch * 0.3, 0, 0))
		local idleLook = 0
		if not watching then
			idleLook = 0.25 * sin(t * 0.45) * (0.5 + 0.5 * sin(t * 0.21))
		end
		set("HeadJoint", CFrame.Angles(0, headYaw + idleLook, 0)
			* CFrame.Angles(0.02 * sin(t * 1.2) - 0.06 * bow + lookPitch * 0.6, 0, 0.025 * sin(t * 0.8) + 0.1 * wave))

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
		local lid = -0.37 * math.max(blink, 0.15 * wave)
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

		-- The free right arm: a relaxed sway, or the greeting wave.
		local wv = sin(9 * (t - waveStart))
		set("ShoulderRJoint", CFrame.Angles(0.03 * sin(t * 1.1), 0, -0.04 + 0.03 * sin(t * 1.3 + 1) - 1.9 * wave))
		set("ElbowRJoint", CFrame.Angles(0.08 + 0.03 * sin(t * 1.3), 0, (-1.2 + 0.3 * wv) * wave))
		set("WristRJoint", CFrame.Angles(0.04 * sin(t * 1.2), 0, 0.2 * wv * wave))
		set("FingerRJoint", CFrame.Angles(0.1 + 0.06 * sin(t * 1.0) + 0.1 * wv * wave, 0, 0))
		-- The staff arm holds still (the hand grips the staff); only the Dewdrop moves.
		set("ShoulderLJoint", CFrame.new())
		set("ElbowLJoint", CFrame.new())
		set("StaffJoint", CFrame.new())
		-- The turn is taken modulo a full circle in doubles first (a huge clock
		-- angle quantizes in CFrame.Angles).
		set("DewJoint", CFrame.new(0, 0.09 * sin(t * 1.8), 0) * CFrame.Angles(0, (t * 0.9) % (2 * math.pi), 0))

		-- The pod satchel swings; it opens for a customer.
		set("SatchelJoint", CFrame.Angles(0.02 * sin(t * 1.7 + 1), 0, 0.03 * sin(t * 1.3)))
		set("SatchelFlapJoint", CFrame.Angles(1.15 * bow + 0.03 * sin(t * 2.3) * bow, 0, 0))

		-- The glow: alive, or steady and still under Reduced FX.
		if lamp then
			if input.reducedFx then
				lamp.Brightness = 1.2
				lamp.Range = 14
			else
				lamp.Brightness = 1.2 + 0.25 * sin(t * 2.4) + 1.6 * bow
				lamp.Range = 14 + 4 * bow
			end
		end
		if sparkle then
			sparkle.Enabled = not input.reducedFx
			sparkle.Rate = 4 + 10 * bow
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
