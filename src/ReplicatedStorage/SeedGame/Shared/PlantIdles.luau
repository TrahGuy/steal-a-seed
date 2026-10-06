--!strict
-- Steal a Seed :: PlantIdles
--
-- The ordinary plants' idles and walks (2026-10-03): the twenty-five rigs in
-- PlantForms, played on the CLIENT by SecretIdle's kinematic tree -- the same
-- animator, tag and maths as the Secrets and the Rain event's forms. This file
-- is only their numbers: what each one's joints do while it stands, and how
-- its legs are laid out for the walk.
--
--==============================================================================
-- THE IDLES ARE THE OWNER'S SCRIPTS, PORTED
--
-- Every supplied model came with a demo Script. None of them runs: they are in
-- the backups, not in the game. Their idle motion is ported here joint for
-- joint -- the same periods, lags, amplitudes, blinks, glows and displays --
-- with three things changed, all because the game now owns what the scripts
-- owned on their own:
--
--   WALKING   The AutoWaddle scripts circled their model round a fixed point,
--             and the Movement scripts path-found their own routes. Here the
--             server's legs move the model (PlantService / PlantSway) and
--             SecretIdle's gait steps the legs by the distance actually
--             travelled. What the scripts did WHILE walking -- ears flapping,
--             arms swinging, a tail wagging twice a stride -- is kept, driven
--             by the gait's own stride phase and weight.
--   DISTANCE  A translation the scripts wrote in studs (a lid's drop) or in
--             their `Unit` is taken at THIS copy's size: the authored number,
--             times the scale the owner's Scale tool left the model at
--             (spec.ModelScale -- several were rescaled after their scripts
--             were written), times the tier's build factor (RigScale).
--   SLEEP     The AutoWaddle scripts could sleep. Nothing in the game puts a
--             plant to sleep, so the awake half is ported and the rest is not.
--
-- Blinks were random in the AutoWaddle scripts (math.random); here each copy
-- blinks on its own fixed period in the same range, so a bed of them never
-- blinks together and the motion is the same on every client.
--==============================================================================

local PlantIdles = {}

local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi
local clamp = math.clamp

-- The same rest attributes SecretIdle keeps, so a copy rebuilt mid-blink or
-- mid-glow never takes the blinked size or the glowing colour for its rest.
local REST_SIZE = "SeedRestSize"
local REST_COLOR = "SeedRestColor"

type Sized = { part: BasePart, size: Vector3 }
type Tinted = { part: BasePart, base: Color3 }
type Glow = { part: BasePart, base: Color3, hot: Color3 }
type Lamp = { light: PointLight, base: number }

export type Plant = {
	-- The authored-to-built factor for a distance written in studs, and the
	-- scripts' `unit` at this size.
	k: number,
	u: number,
	eyes: { Sized },
	shines: { BasePart },
	glows: { Glow },
	lamps: { Lamp },
	tints: { [string]: { Tinted } },
	emitters: { [string]: ParticleEmitter },
	outward: { [string]: Vector3 },
	-- This copy's own blink period (seconds), off its phase.
	blink: number,
	-- Parts an idle resizes (the Emberquill's flame), at the size this copy
	-- was BUILT, and each Motor6D's Part1 `Side` attribute by joint name
	-- (the Emberquill's back quills fan by it). 2026-10-03.
	sized: { Sized },
	sides: { [string]: number },
}

local function wave(t: number, period: number, lag: number?): number
	return sin(t * 2 * pi / period - (lag or 0))
end

local function ease(x: number): number
	return x * x * (3 - 2 * x)
end

-- The scripts' `display()`: 0 until `rise`, up to 1 by `full`, held until
-- `hold`, back to 0 by `done`, every `period` seconds.
local function display(t: number, period: number, rise: number, full: number, hold: number, done: number): number
	local k = t % period
	if k < rise then
		return 0
	elseif k < full then
		return ease((k - rise) / (full - rise))
	elseif k < hold then
		return 1
	elseif k < done then
		return 1 - ease((k - hold) / (done - hold))
	end
	return 0
end

-- The Movement scripts' reveal: one half sine every `period` seconds.
local function reveal(t: number, period: number, from: number, length: number): number
	return sin(pi * clamp((t % period - from) / length, 0, 1))
end

local function set(rig: any, name: string, cf: CFrame)
	rig.pose[name] = cf
end

-- How much of the walk is showing, and the stride's phase in radians -- what
-- the AutoWaddle scripts called moveFactor and walkPhase x their step rate.
local function walkOf(rig: any): (number, number)
	local gait = rig.gait
	if not gait then
		return 0, 0
	end
	return gait.weight, gait.phase * 2 * pi
end

--==============================================================================
-- BLINKS, GLOWS, LIGHTS, TINTS, EMITTERS
--==============================================================================
-- Eyes squashed to `factor` of their height while `closed`, shines hidden.
local function blinkEyes(rig: any, closed: boolean, factor: number)
	local plant: Plant = rig.plant
	for _, e in ipairs(plant.eyes) do
		e.part.Size = Vector3.new(e.size.X, e.size.Y * (if closed then factor else 1), e.size.Z)
	end
	for _, p in ipairs(plant.shines) do
		p.Transparency = if closed then 1 else 0
	end
end

-- The scripts' clock blink: closed between `from` and `to` of every `period`.
local function clockBlink(t: number, period: number, from: number, to: number): boolean
	local b = t % period
	return b > from and b < to
end

-- An AutoWaddle lid blink: 0 to 1 and back over a tenth of a second, once per
-- this copy's period (2.5 to 5.5 s, the scripts' range).
local function lidClose(rig: any, t: number): number
	local b = t % rig.plant.blink
	if b < 0.05 then
		return b / 0.05
	elseif b < 0.1 then
		return (0.1 - b) / 0.05
	end
	return 0
end

-- Both eyelid motors slid down by `drop` (authored studs) x `close`.
local function lids(rig: any, closeL: number, closeR: number, drop: number)
	local k = rig.plant.k
	set(rig, "LeftEyelid", CFrame.new(0, closeL * drop * k, 0))
	set(rig, "RightEyelid", CFrame.new(0, closeR * drop * k, 0))
end

local function glowAll(rig: any, amount: number)
	for _, g in ipairs(rig.plant.glows) do
		g.part.Color = g.base:Lerp(g.hot, amount)
	end
end

local function lampAll(rig: any, factor: number)
	for _, l in ipairs(rig.plant.lamps) do
		l.light.Brightness = l.base * factor
	end
end

local function tint(rig: any, set_: string, toward: Color3, amount: number)
	for _, p in ipairs(rig.plant.tints[set_] or {}) do
		p.part.Color = p.base:Lerp(toward, amount)
	end
end

local function rate(rig: any, name: string, value: number)
	local e = rig.plant.emitters[name]
	if e then
		e.Rate = value
	end
end

-- A one-off puff of `count` particles from the named emitter (the scripts'
-- `emitter:Emit(n)`).
local function burst(rig: any, name: string, count: number)
	local e = rig.plant.emitters[name]
	if e then
		pcall(function()
			e:Emit(count)
		end)
	end
end

--==============================================================================
-- WHAT EACH IDLE BLINKS AND TINTS BESIDES ITS `Blink` / `HideOnBlink` /
-- `HotColor` PARTS: the Movement scripts named theirs.
--==============================================================================
local EYES: { [string]: { string } } = {
	raincup = { "EyeL", "EyeR" },
	suncrown = { "EyeL", "EyeR" },
	gloomlotus = { "EyeL", "EyeR" },
	pyrelotus = { "EyeLens" },
	-- The owner's new Emberquill (2026-10-03): its script blinked every part
	-- named Eye or Pupil.
	emberquill = { "Eye", "Pupil" },
}
local SHINES: { [string]: { string } } = {
	raincup = { "EyeShineL", "EyeShineR" },
	pyrelotus = { "Iris" },
}
-- Parts an idle resizes from their built size (the EmberquillIdle script grew
-- the parts carrying a BaseSize attribute; that attribute was written before
-- the owner's Scale tool, so the port takes the size the copy was built at).
local SIZED: { [string]: { string } } = {
	emberquill = { "Flame", "FlameCore" },
}
local function names(prefix: string, n: number, extra: { string }?): { string }
	local out = {}
	for i = 1, n do
		table.insert(out, prefix .. i)
	end
	for _, e in ipairs(extra or {}) do
		table.insert(out, e)
	end
	return out
end
local TINTS: { [string]: { [string]: { string } } } = {
	raincup = {
		pools = { "BasinWater", "PoolCore", "PoolArm1", "PoolArm2", "PoolArm3", "PoolArm4" },
		ripple1 = { "Ripple1" }, ripple2 = { "Ripple2" }, ripple3 = { "Ripple3" }, ripple4 = { "Ripple4" },
	},
	gloomlotus = {
		veins = names("HoodVein", 4, names("DrapeVein", 6, { "ForeheadMark" })),
	},
	pyrelotus = {
		embers = names("OuterGlow", 8, names("InnerGlow", 6, { "StemSeam1", "StemSeam2", "EyeLens", "EmberBud" })),
	},
	supernovus = {
		glows = names("OuterGlow", 12, names("InnerGlow", 6, { "StemSeam1", "StemSeam2", "StemSeam3", "CrystalCore", "CrystalTip" })),
	},
}

local function restSize(part: BasePart): Vector3
	local seen = part:GetAttribute(REST_SIZE)
	if typeof(seen) ~= "Vector3" then
		seen = part.Size
		part:SetAttribute(REST_SIZE, seen)
	end
	return seen :: Vector3
end

local function restColor(part: BasePart): Color3
	local seen = part:GetAttribute(REST_COLOR)
	if typeof(seen) ~= "Color3" then
		seen = part.Color
		part:SetAttribute(REST_COLOR, seen)
	end
	return seen :: Color3
end

-- Everything an idle touches besides joints, found once per tree build.
-- `unit` and `modelScale` are the spec's; `rigScale` the factor it was built at.
function PlantIdles.Scan(form: string, model: Model, parts: { BasePart }, unit: number, modelScale: number,
	rigScale: number, seed: number): Plant
	local k = modelScale * rigScale
	local plant: Plant = {
		k = k,
		u = unit * k,
		eyes = {},
		shines = {},
		glows = {},
		lamps = {},
		tints = {},
		emitters = {},
		outward = {},
		blink = 2.5 + (seed % 31) / 31 * 3,
		sized = {},
		sides = {},
	}
	local eyeNames, shineNames, sizedNames = {}, {}, {}
	for _, n in ipairs(SIZED[form] or {}) do
		sizedNames[n] = true
	end
	for _, n in ipairs(EYES[form] or {}) do
		eyeNames[n] = true
	end
	for _, n in ipairs(SHINES[form] or {}) do
		shineNames[n] = true
	end
	local tintOf: { [string]: string } = {}
	for setName, list in pairs(TINTS[form] or {}) do
		plant.tints[setName] = {}
		for _, n in ipairs(list) do
			tintOf[n] = setName
		end
	end
	for _, part in ipairs(parts) do
		if part:GetAttribute("Blink") == true or eyeNames[part.Name] then
			table.insert(plant.eyes, { part = part, size = restSize(part) })
		end
		if part:GetAttribute("HideOnBlink") == true or shineNames[part.Name] then
			table.insert(plant.shines, part)
		end
		if sizedNames[part.Name] then
			table.insert(plant.sized, { part = part, size = restSize(part) })
		end
		local hot = part:GetAttribute("HotColor")
		if typeof(hot) == "Color3" then
			local base = part:GetAttribute("BaseColor")
			table.insert(plant.glows, {
				part = part,
				base = if typeof(base) == "Color3" then base else restColor(part),
				hot = hot,
			})
		end
		local setName = tintOf[part.Name]
		if setName then
			table.insert(plant.tints[setName], { part = part, base = restColor(part) })
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") and not plant.emitters[d.Name] then
			plant.emitters[d.Name] = d
		elseif d:IsA("PointLight") then
			local base = d:GetAttribute("BaseBrightness")
			if type(base) ~= "number" then
				base = d:GetAttribute(REST_SIZE)
				if type(base) ~= "number" then
					base = d.Brightness
					d:SetAttribute(REST_SIZE, base)
				end
			end
			table.insert(plant.lamps, { light = d, base = base :: number })
		elseif d:IsA("Motor6D") then
			local out = d:GetAttribute("Outward")
			if typeof(out) == "Vector3" then
				plant.outward[d.Name] = out
			end
			local side = d.Part1 and d.Part1:GetAttribute("Side")
			if type(side) == "number" then
				plant.sides[d.Name] = side
			end
		end
	end
	return plant
end

--==============================================================================
-- THE AUTOWADDLE SEVEN (Nubkin, Petalpip, Spiretip, Toadcap, Dunebud,
-- Paddlehop, Bogbonnet). Hips are the gait's; everything else is the script's.
--==============================================================================
local IDLES: { [string]: (any, number) -> () } = {}

IDLES.nubkin = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	set(rig, "Neck", CFrame.Angles(sin(t * 2.0) * 0.05 * idle + sin(2 * wp) * 0.08 * mf, 0, sin(wp) * 0.05 * mf))
	local twitch = sin(t * 14) * clamp(sin(t * 0.9) - 0.75, 0, 1) * 3
	set(rig, "LeftEar", CFrame.Angles(sin(t * 2.2) * 0.08 * idle + twitch * idle - cos(wp) * 0.28 * mf, 0,
		sin(wp) * 0.12 * mf))
	set(rig, "RightEar", CFrame.Angles(sin(t * 1.7 + 0.8) * 0.09 * idle + cos(wp + 0.6) * 0.22 * mf, 0,
		-sin(wp) * 0.12 * mf))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.35 * mf + sin(t * 2.5) * 0.12 * idle, 0))
	local c = lidClose(rig, t)
	lids(rig, c, c, -0.16)
	rate(rig, "PollenSpore", idle * 1.5 + mf * 3.5)
end

IDLES.petalpip = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	local sway, breathe = sin(wp) * 0.22 * mf, sin(t * 2.0) * 0.05 * idle
	set(rig, "ShoulderL", CFrame.Angles(sway + breathe, 0, 0))
	set(rig, "ShoulderR", CFrame.Angles(-sway + breathe, 0, 0))
	set(rig, "Neck", CFrame.Angles(sin(t * 2.0) * 0.04 * idle + sin(2 * wp) * 0.07 * mf, 0, sin(wp) * 0.05 * mf))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.3 * mf + sin(t * 2.5) * 0.1 * idle, 0))
	local c = lidClose(rig, t)
	lids(rig, c, c, -0.14)
	rate(rig, "NectarGlow", idle * 2.5 + mf * 4.5)
end

IDLES.spiretip = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	local swing, breathe = sin(wp) * 0.35 * mf, sin(t * 1.8) * 0.05 * idle
	set(rig, "ShoulderL", CFrame.Angles(-swing + breathe, 0, 0))
	set(rig, "ShoulderR", CFrame.Angles(swing + breathe, 0, 0))
	set(rig, "Neck", CFrame.Angles(sin(t * 1.8) * 0.03 * idle + sin(2 * wp) * 0.06 * mf, 0, sin(wp) * 0.04 * mf))
	set(rig, "SpireTipJoint", CFrame.Angles(-sin(wp + 0.4) * 0.18 * mf + sin(t * 1.5) * 0.06 * idle, 0,
		-sin(wp) * 0.08 * mf))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.28 * mf + sin(t * 2.2) * 0.08 * idle, 0))
	local c = lidClose(rig, t)
	lids(rig, c, c, -0.14)
	rate(rig, "PineSpores", idle * 2.2 + mf * 3.8)
end

IDLES.toadcap = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	local bob, breathe = sin(wp) * 0.2 * mf, sin(t * 1.6) * 0.04 * idle
	set(rig, "ShoulderL", CFrame.Angles(bob + breathe, 0, 0))
	set(rig, "ShoulderR", CFrame.Angles(-bob + breathe, 0, 0))
	set(rig, "Neck", CFrame.Angles(sin(t * 1.6) * 0.04 * idle + sin(2 * wp) * 0.06 * mf, 0, sin(wp) * 0.04 * mf))
	-- The cap lags the plod, a jelly wobble.
	set(rig, "CapJoint", CFrame.Angles(-sin(wp + 0.3) * 0.14 * mf + sin(t * 1.6) * 0.03 * idle, 0,
		-cos(wp) * 0.08 * mf))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.25 * mf + sin(t * 2.0) * 0.06 * idle, 0))
	local c = lidClose(rig, t)
	lids(rig, c, c, -0.15)
	rate(rig, "MushroomSpores", idle * 2.8 + mf * 4.8)
end

IDLES.dunebud = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	set(rig, "Neck", CFrame.Angles(sin(t * 1.8) * 0.04 * idle + sin(2 * wp) * 0.07 * mf, 0, sin(wp) * 0.04 * mf))
	set(rig, "FlowerJoint", CFrame.Angles(-cos(wp) * 0.22 * mf + sin(t * 2.2) * 0.08 * idle, 0, 0))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.3 * mf + sin(t * 2.0) * 0.1 * idle, 0))
	local c = lidClose(rig, t)
	lids(rig, c, c, -0.14)
	rate(rig, "DesertPollen", idle * 2.0 + mf * 4.0)
end

IDLES.paddlehop = function(rig, t)
	local mf, wp = walkOf(rig)
	local idle = 1 - mf
	local flap, pump, breath = sin(wp) * 0.4 * mf, cos(wp) * 0.25 * mf, sin(t * 1.8) * 0.06 * idle
	set(rig, "ShoulderL", CFrame.Angles(pump, 0, flap - breath))
	set(rig, "ShoulderR", CFrame.Angles(-pump, 0, -flap + breath))
	set(rig, "Neck", CFrame.Angles(sin(2 * wp) * 0.08 * mf + sin(t * 1.8) * 0.05 * idle, 0, sin(wp) * 0.05 * mf))
	set(rig, "TailJoint", CFrame.Angles(0, sin(2 * wp) * 0.35 * mf + sin(t * 2.2) * 0.1 * idle, 0))
	-- About one blink in three is a wink: the right eye stays open.
	local c = lidClose(rig, t)
	local n = math.floor(t / rig.plant.blink)
	local wink = (n * 7919 % 100) < 35
	lids(rig, c, if wink then 0 else c, -0.14)
	rate(rig, "DesertSpores", idle * 2.2 + mf * 4.4)
end

IDLES.bogbonnet = function(rig, t)
	local mf, wp = walkOf(rig)
	local breath = sin(t * 1.8)
	set(rig, "Neck", CFrame.Angles(breath * 0.05, sin(t * 1.14) * 0.15 * (1 - mf * 0.5), 0))
	-- The heavy cap tips with delayed momentum as it waddles.
	set(rig, "CapJoint", CFrame.Angles(cos(2 * wp - 0.4) * 0.08 * mf + breath * 0.04, 0,
		sin(wp - 0.4) * 0.12 * mf + cos(t * 1.8) * 0.03))
	set(rig, "TailJoint", CFrame.Angles(0, sin(wp * 1.5) * 0.2 * mf + breath * 0.08, 0))
	local shut = if (t % 4.2) < 0.18 then 1 else 0
	lids(rig, shut, shut, -0.15)
end

--==============================================================================
-- THE IDLE SCRIPTS (Bellchime, Thornwhorl, Crookreed, Snapmoss, Lanterncap,
-- Cinderpaw, Emberquill, Slagbloom, Kilnhusk, Novaorb, Cosmospire, Voidpetal,
-- Astralhorn), as written. `u` is their `unit` at this size.
--==============================================================================
IDLES.bellchime = function(rig, t)
	local open = display(t, 10, 6, 6.6, 8, 9)
	local chime = sin(((t % 10) - 6.6) * 2 * pi * 1.4) * open
	set(rig, "Root", CFrame.Angles(rad(1.2) * wave(t, 4.4), 0, rad(1.5) * wave(t, 7.1)))
	set(rig, "Stem2", CFrame.Angles(rad(2) * wave(t, 4.4, 0.5), 0, rad(1.5) * wave(t, 7.1, 0.6)))
	set(rig, "Head", CFrame.Angles(rad(2) * wave(t, 5.2), rad(7) * wave(t, 9.3), rad(2) * wave(t, 6.2) + rad(8) * chime))
	set(rig, "Clapper", CFrame.Angles(rad(4) * wave(t, 3.8), 0, -rad(18) * chime))
	for i = 1, 8 do
		set(rig, "Flare" .. i, CFrame.Angles(-rad(1.5) * wave(t, 4.4, i * 0.5) - rad(7) * open, 0, 0))
	end
	for i = 1, 6 do
		set(rig, "Collar" .. i, CFrame.Angles(rad(3) * wave(t, 4.4, i * 0.65) + rad(8) * open, 0, 0))
	end
	for _, side in ipairs({ "L", "R" }) do
		local sign = if side == "L" then 1 else -1
		set(rig, "Shoulder" .. side, CFrame.Angles(rad(3) * wave(t, 4.8, sign * 0.4), 0,
			sign * rad(3) * wave(t, 5.7) + sign * rad(4) * chime))
		set(rig, "Hand" .. side, CFrame.Angles(rad(5) * wave(t, 4.8, sign * 0.4 + 0.9), 0, sign * rad(6) * wave(t, 5.7, 0.8)))
	end
	glowAll(rig, 0.12 + 0.16 * (0.5 + 0.5 * wave(t, 3.4)) + 0.55 * open)
	lampAll(rig, 1 + 0.12 * wave(t, 3.4) + 1.3 * open)
	blinkEyes(rig, clockBlink(t, 4.9, 4.64, 4.8) and open < 0.5, 0.18)
end

IDLES.thornwhorl = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	local u = rig.plant.u
	set(rig, "Root", CFrame.Angles(rad(0.6) * wave(t, 5.9), 0, rad(0.8) * wave(t, 7.2)))
	set(rig, "Spine2", CFrame.Angles(rad(0.8) * wave(t, 5.9, 0.5), 0, rad(1) * wave(t, 7.2, 0.6)))
	set(rig, "Spine3", CFrame.Angles(rad(0.8) * wave(t, 5.9, 1), 0, rad(1.1) * wave(t, 7.2, 1.2)))
	set(rig, "Spine4", CFrame.Angles(rad(0.6) * wave(t, 5.9, 1.5), rad(2) * wave(t, 9), rad(0.8) * wave(t, 7.2, 1.8)))
	for i = 1, 8 do
		local out = rig.plant.outward["Guard" .. i] or Vector3.zero
		set(rig, "Guard" .. i, CFrame.new(out * (0.012 * u * open))
			* CFrame.Angles(0, rad(2) * wave(t, 5.5, i * 0.55) + rad(4) * open, 0))
	end
	for i = 1, 3 do
		set(rig, "Crown" .. i, CFrame.Angles(rad(3) * wave(t, 4.8, i * 0.7) + rad(3) * open, 0, 0))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.crookreed = function(rig, t)
	-- Sway from the shared root attachment; the branching feet stay put.
	set(rig, "Root", CFrame.Angles(rad(1.3) * wave(t, 5.1), 0, rad(1.8) * wave(t, 6.7)))
	set(rig, "Stem2", CFrame.Angles(rad(2) * wave(t, 5.1, 0.65), 0, rad(2.5) * wave(t, 6.7, 0.7)))
	set(rig, "Neck", CFrame.Angles(rad(3) * wave(t, 5.1, 1.2), rad(3) * wave(t, 9), rad(2) * wave(t, 6.7, 1.4)))
	set(rig, "Head", CFrame.Angles(rad(2.5) * wave(t, 5.2), rad(8) * wave(t, 10), rad(2) * wave(t, 7.4)))
	for _, side in ipairs({ "L", "R" }) do
		local sign = if side == "L" then 1 else -1
		set(rig, "Shoulder" .. side, CFrame.Angles(rad(3) * wave(t, 4.7, sign * 0.4), 0, sign * rad(3) * wave(t, 6)))
		set(rig, "Leaf" .. side, CFrame.Angles(rad(5) * wave(t, 4.7, sign * 0.4 + 0.7), 0, rad(2) * wave(t, 6, 0.8)))
	end
	set(rig, "Crest", CFrame.Angles(rad(4) * wave(t, 3.9), 0, rad(4) * wave(t, 5.4, 0.5)))
	blinkEyes(rig, clockBlink(t, 5.7, 5.42, 5.58), 0.18)
end

IDLES.snapmoss = function(rig, t)
	local open = display(t, 8, 5.0, 5.8, 6.5, 6.7)
	-- A rise only; the hips cancel it so every foot stays on the ground.
	local bob = 0.006 * rig.plant.u * (0.5 + 0.5 * wave(t, 4.2))
	set(rig, "Root", CFrame.new(0, bob, 0))
	for _, tag in ipairs({ "FrontL", "FrontR", "BackL", "BackR" }) do
		set(rig, "Hip" .. tag, CFrame.new(0, -bob, 0))
	end
	-- The snout rises as the jaw opens, keeping it clear of the floor.
	set(rig, "Head", CFrame.Angles(rad(1.2) * wave(t, 4.2, 0.6) + rad(8) * open,
		rad(5) * wave(t, 9.5) * (1 - 0.8 * open), rad(0.6) * wave(t, 7)))
	set(rig, "Jaw", CFrame.Angles(-rad(22) * open, 0, 0))
	set(rig, "Tail1", CFrame.Angles(0, rad(6) * wave(t, 5.8), 0))
	set(rig, "Tail2", CFrame.Angles(0, rad(8) * wave(t, 5.8, 0.8), 0))
	for i = 1, 6 do
		local sign = if i <= 3 then -1 else 1
		set(rig, "Moss" .. i, CFrame.Angles(rad(2) * wave(t, 3.9, i * 0.5), 0, sign * rad(4) * wave(t, 4.7, i * 0.6)))
	end
	blinkEyes(rig, clockBlink(t, 5.1, 4.84, 4.98) and open < 0.5, 0.18)
end

IDLES.lanterncap = function(rig, t)
	local open = display(t, 17, 10, 11.2, 12.8, 15)
	set(rig, "Root", CFrame.Angles(rad(0.4) * wave(t, 7), 0, rad(0.5) * wave(t, 8)))
	set(rig, "Stem2", CFrame.Angles(rad(0.5) * wave(t, 7, 0.5), 0, rad(0.6) * wave(t, 8, 0.5)))
	set(rig, "Stem3", CFrame.Angles(rad(0.5) * wave(t, 7, 1), 0, rad(0.6) * wave(t, 8, 1)))
	set(rig, "Arch", CFrame.Angles(rad(0.5) * wave(t, 7, 1.5), 0, 0))
	set(rig, "Cap", CFrame.Angles(rad(0.6) * wave(t, 8) + rad(2) * open, rad(1) * wave(t, 12), 0))
	set(rig, "Pendant", CFrame.Angles(rad(2.5) * wave(t, 5.9), 0, rad(2) * wave(t, 7.3)))
	set(rig, "Lantern", CFrame.Angles(0, rad(3) * wave(t, 9), rad(1) * wave(t, 7.3, 0.7)))
	for i = 1, 8 do
		set(rig, "Gill" .. i, CFrame.Angles(rad(0.35) * wave(t, 8, i * 0.4), 0, 0))
	end
	for i = 1, 2 do
		set(rig, "Vine" .. i, CFrame.Angles(rad(1.5) * wave(t, 7, i), 0, 0))
		set(rig, "Curl" .. i, CFrame.Angles(0, 0, rad(2) * wave(t, 7, i + 0.7)))
	end
	blinkEyes(rig, clockBlink(t, 6.1, 5.8, 5.98), 0.18)
	glowAll(rig, 0.10 + 0.13 * (wave(t, 8) + 1) / 2 + 0.25 * open)
end

IDLES.cinderpaw = function(rig, t)
	local u = rig.plant.u
	local breath = wave(t, 3.2)
	-- Body breathing counter-translated at the hips: the paws stay planted.
	local rise = 0.008 * u * breath
	set(rig, "Root", CFrame.new(0, rise, 0))
	for _, tag in ipairs({ "FrontL", "FrontR", "BackL", "BackR" }) do
		set(rig, "Hip" .. tag, CFrame.new(0, -rise, 0))
	end
	-- A small front-left paw knead once a cycle, back to the floor.
	local k = t % 7.5
	local knead = if k > 5.2 and k < 6.2 then sin((k - 5.2) * pi) else 0
	set(rig, "HipFrontL", CFrame.new(0, -rise + 0.025 * u * knead, 0) * CFrame.Angles(rad(-5) * knead, 0, 0))
	set(rig, "KneeFrontL", CFrame.Angles(rad(7) * knead, 0, 0))
	set(rig, "AnkleFrontL", CFrame.Angles(rad(-2) * knead, 0, 0))
	set(rig, "Neck", CFrame.Angles(rad(2) * wave(t, 3.2, 0.3), rad(9) * wave(t, 8), rad(3) * wave(t, 5.4)))
	local f = t % 6.1
	local twitch = if f > 4.5 and f < 4.8 then sin((f - 4.5) / 0.3 * pi) else 0
	set(rig, "EarL", CFrame.Angles(rad(3) * wave(t, 4.7), 0, rad(-9) * twitch))
	set(rig, "EarR", CFrame.Angles(rad(3) * wave(t, 4.7, 0.7), 0, rad(3) * wave(t, 5.3)))
	set(rig, "Tail1", CFrame.Angles(rad(3) * wave(t, 4), rad(10) * wave(t, 4.8), 0))
	set(rig, "Tail2", CFrame.Angles(rad(4) * wave(t, 4, 0.7), rad(8) * wave(t, 4.8, 0.8), 0))
	set(rig, "Bud", CFrame.Angles(rad(2) * wave(t, 3.2, 0.8), 0, rad(2) * wave(t, 4.5)))
	-- A tiny radial flex: it stays a closed bud.
	for i = 1, 4 do
		local a = (i - 1) * pi / 2
		local flex = rad(2) * (0.5 + 0.5 * breath)
		set(rig, "Sepal" .. i, CFrame.Angles(cos(a) * flex, 0, -sin(a) * flex))
	end
	local heat = 0.5 + 0.5 * wave(t, 2.7)
	glowAll(rig, 0.35 * heat)
	lampAll(rig, 0.85 + 0.30 * heat)
	blinkEyes(rig, clockBlink(t, 4.6, 4.36, 4.5), 0.13)
end

--==============================================================================
-- EMBERQUILL, THE OWNER'S NEW RIG (2026-10-03): its EmberquillIdle script, as
-- written. It stands sentry -- breathes, looks one way, holds, looks the other
-- -- its ears flick, paws fidget, back quills ripple, the tail sways, the wick
-- flame flickers, and it blinks every 4.3 s. Every 8 s it BRISTLES: draws
-- itself up, every quill snaps up and fans out with its tip flaring white-hot,
-- the arms spread, the tail lifts and the wick flares with a burst of embers.
-- Three things are the game's, not the script's: the legs belong to the gait
-- (the script held them still, and so does the idle -- it never sets them);
-- the flame grows from the size this copy was built at (SIZED, not the stale
-- BaseSize); and its `unit` is taken at this copy's size, like every idle's.
--==============================================================================
local function bristleAt(k: number): number
	if k < 0.25 then
		return sin(k / 0.25 * pi / 2)
	elseif k < 1.3 then
		return 1
	elseif k < 2.3 then
		return (1 + cos((k - 1.3) * pi)) / 2
	end
	return 0
end

IDLES.emberquill = function(rig, t)
	local plant: Plant = rig.plant
	local breath = wave(t, 3.2)
	local k = t % 8
	local f = bristleAt(k)
	local shiver = if k > 0.2 and k < 1.3 then rad(2.5) * sin(t * 40) else 0
	local cycle = math.floor(t / 8)
	if k < 0.3 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "Embers", 18)
	end
	-- The body breathes and sways; on the bristle it draws itself up.
	set(rig, "Waist", CFrame.Angles(rad(1.5) * breath + rad(5) * f, rad(5) * wave(t, 8.0) * (1 - f),
		rad(1.5) * wave(t, 5.1)))
	-- Sentry look: turn, hold, turn the other way; on the bristle, chin up.
	local look = clamp(1.7 * wave(t, 9.5), -1, 1)
	set(rig, "Neck", CFrame.Angles(rad(1.5) * breath + rad(4) * f, rad(32) * look * (1 - f), rad(5) * wave(t, 6.3)))
	-- Ear flicks, ears pinned back on the bristle.
	local flick = if (t % 5.3) < 0.25 then sin((t % 5.3) / 0.25 * pi) else 0
	local flick2 = if ((t + 2.1) % 6.1) < 0.25 then sin(((t + 2.1) % 6.1) / 0.25 * pi) else 0
	set(rig, "EarL", CFrame.Angles(0, 0, -rad(16) * flick - rad(12) * f))
	set(rig, "EarR", CFrame.Angles(0, 0, rad(16) * flick2 + rad(12) * f))
	-- The quills: a slow ripple; on the bristle they snap up and fan out.
	for i = 1, 2 do
		local s = if i % 2 == 0 then 1 else -1
		set(rig, "Crest" .. i, CFrame.Angles(-rad(2) * wave(t, 2.7, i) - rad(18) * f + shiver, 0, -s * rad(7) * f))
	end
	for i = 1, 5 do
		local s = plant.sides["Back" .. i] or 0
		local lift = if i == 1 then 0.45 else 1 -- the top one stays clear of the head quills
		set(rig, "Back" .. i, CFrame.Angles(-rad(3) * wave(t, 2.5, i * 0.6) - rad(22) * f * lift + shiver, 0,
			-s * rad(9) * f))
	end
	set(rig, "Wick", CFrame.Angles(rad(2) * wave(t, 2.9) - rad(6) * f, 0, rad(2) * wave(t, 3.7)))
	-- The flame flickers and flares, grown from the bottom so it rises out of
	-- its cup instead of sinking into it.
	local flicker = 0.5 * sin(t * 11.3) + 0.3 * sin(t * 17.9 + 1) + 0.2 * sin(t * 29.1 + 2)
	local grow = 1 + 0.10 * flicker + 0.6 * f
	set(rig, "WickFlame", CFrame.new(0, 0.05 * plant.u * (grow - 1), 0)
		* CFrame.Angles(rad(5) * sin(t * 7.1), rad(20) * sin(t * 3.3), rad(6) * flicker))
	for _, fl in ipairs(plant.sized) do
		fl.part.Size = Vector3.new(fl.size.X * (1 + 0.3 * f), fl.size.Y * grow, fl.size.Z * (1 + 0.3 * f))
	end
	lampAll(rig, 1 + 0.15 * flicker + 1.6 * f)
	glowAll(rig, math.max(f, 0.12 * (1 + flicker) / 2))
	-- Paws fidget at the chest; they spread on the bristle.
	set(rig, "ShoulderL", CFrame.Angles(rad(4) * wave(t, 2.8), 0, rad(26) * f))
	set(rig, "ShoulderR", CFrame.Angles(rad(4) * wave(t, 2.8, 1.1), 0, -rad(26) * f))
	set(rig, "ElbowL", CFrame.Angles(rad(6) * wave(t, 1.9) - rad(10) * f, 0, 0))
	set(rig, "ElbowR", CFrame.Angles(rad(6) * wave(t, 1.9, 0.9) - rad(10) * f, 0, 0))
	-- The tail sways; it lifts on the bristle.
	set(rig, "Tail1", CFrame.Angles(-rad(10) * f, rad(5) * wave(t, 3.6), 0))
	set(rig, "Tail2", CFrame.Angles(-rad(5) * wave(t, 2.2) - rad(10) * f, rad(12) * wave(t, 3.6, 0.7), 0))
	-- A blink every few seconds: eyes and pupils squashed to 15 %.
	blinkEyes(rig, clockBlink(t, 4.3, 0, 0.12), 0.15)
end

IDLES.slagbloom = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.4) * wave(t, 7), 0, rad(0.5) * wave(t, 8)))
	set(rig, "Stem", CFrame.Angles(rad(0.6) * wave(t, 7, 0.5), 0, rad(0.7) * wave(t, 8, 0.6)))
	set(rig, "Head", CFrame.Angles(rad(1) * wave(t, 7, 1), rad(2) * wave(t, 10), 0))
	for i = 1, 8 do
		set(rig, "Petal" .. i, CFrame.Angles(rad(0.4) * wave(t, 7, i * 0.3) + rad(3) * open, 0, 0))
	end
	for i = 1, 2 do
		set(rig, "Arm" .. i, CFrame.Angles(rad(2) * wave(t, 6, i), 0, 0))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.kilnhusk = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.3) * wave(t, 8), 0, rad(0.3) * wave(t, 9)))
	set(rig, "Head", CFrame.Angles(rad(0.6) * wave(t, 8, 0.7), rad(3) * wave(t, 12), 0))
	for i = 1, 2 do
		local s = if i == 1 then -1 else 1
		set(rig, "UpperArm" .. i, CFrame.Angles(rad(1) * wave(t, 8, i), 0, rad(s * 2) * open))
		set(rig, "Forearm" .. i, CFrame.Angles(rad(1) * wave(t, 8, i + 0.4) - rad(5) * open, 0, 0))
		set(rig, "Hand" .. i, CFrame.Angles(rad(1.5) * wave(t, 7, i) - rad(2) * open, 0, 0))
	end
	for i = 1, 7 do
		set(rig, "Crown" .. i, CFrame.Angles(rad(0.6) * wave(t, 9, i * 0.3), 0, 0))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.novaorb = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.7) * wave(t, 5.5), 0, rad(0.8) * wave(t, 6.2)))
	set(rig, "Head", CFrame.Angles(rad(1) * wave(t, 5.5, 0.6), rad(3) * wave(t, 9), 0))
	set(rig, "Tail", CFrame.Angles(0, rad(4) * wave(t, 5.5), 0))
	for i = 1, 2 do
		local s = if i == 1 then -1 else 1
		set(rig, "Arm" .. i, CFrame.Angles(rad(2) * wave(t, 5.5, i), 0, rad(s) * wave(t, 6)))
		set(rig, "Ear" .. i, CFrame.Angles(rad(2) * wave(t, 6, i), 0, rad(s * 2) * wave(t, 6.5, i) + rad(s * 4) * open))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.cosmospire = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.5) * wave(t, 7), 0, rad(0.7) * wave(t, 8)))
	set(rig, "Spine2", CFrame.Angles(rad(0.6) * wave(t, 7, 0.5), 0, rad(0.8) * wave(t, 8, 0.5)))
	set(rig, "Spine3", CFrame.Angles(rad(0.6) * wave(t, 7, 1), 0, rad(0.8) * wave(t, 8, 1)))
	set(rig, "Head", CFrame.Angles(rad(1) * wave(t, 7, 1.5), rad(3) * wave(t, 11), 0))
	for i = 1, 4 do
		local s = if i % 2 == 1 then -1 else 1
		set(rig, "Leaf" .. i, CFrame.Angles(rad(1) * wave(t, 6, i), 0, rad(s) * wave(t, 7, i * 0.4) - rad(s * 4) * open))
	end
	for i = 1, 2 do
		set(rig, "Crown" .. i, CFrame.Angles(rad(1) * wave(t, 7, i), 0, rad(0.8) * wave(t, 8, i)))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.voidpetal = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.5) * wave(t, 6.5), 0, rad(0.5) * wave(t, 7.2)))
	set(rig, "Head", CFrame.Angles(rad(0.8) * wave(t, 6.5, 0.6), rad(2.5) * wave(t, 10), 0))
	set(rig, "Tail", CFrame.Angles(0, rad(3) * wave(t, 6), 0))
	for i = 1, 6 do
		set(rig, "Petal" .. i, CFrame.Angles(rad(1) * wave(t, 6.5, i * 0.4) - rad(4) * open, 0, 0))
	end
	for i = 1, 2 do
		set(rig, "Arm" .. i, CFrame.Angles(rad(1.5) * wave(t, 6, i), 0, 0))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

IDLES.astralhorn = function(rig, t)
	local open = display(t, 11, 7.3, 8, 9, 10.2)
	set(rig, "Root", CFrame.Angles(rad(0.4) * wave(t, 7), 0, rad(0.4) * wave(t, 8)))
	set(rig, "Neck", CFrame.Angles(rad(0.6) * wave(t, 7, 0.6) + rad(3) * open, 0, 0))
	set(rig, "Head", CFrame.Angles(rad(0.7) * wave(t, 7, 1), rad(2.5) * wave(t, 11), 0))
	set(rig, "Tail", CFrame.Angles(0, rad(3) * wave(t, 6), 0))
	for i = 1, 4 do
		set(rig, "Armour" .. i, CFrame.Angles(0, 0, rad(0.7) * wave(t, 7, i * 0.4)))
	end
	for i = 1, 2 do
		set(rig, "HornLower" .. i, CFrame.Angles(rad(0.5) * wave(t, 8, i), 0, 0))
		set(rig, "HornUpper" .. i, CFrame.Angles(rad(0.4) * wave(t, 8, i + 0.5), 0, 0))
		set(rig, "HornFork" .. i, CFrame.Angles(rad(0.3) * wave(t, 8, i + 1), 0, 0))
		set(rig, "Ear" .. i, CFrame.Angles(rad(2) * wave(t, 6, i), 0, 0))
	end
	blinkEyes(rig, clockBlink(t, 5.6, 5.32, 5.48), 0.18)
end

--==============================================================================
-- THE MOVEMENT SCRIPTS (Raincup, Suncrown, Gloomlotus, Pyrelotus, SuperNovus):
-- their standing motion. Their walking bob is the gait's.
--==============================================================================
local function stemBody(rig: any, t: number)
	set(rig, "Root", CFrame.new(0, 0.004 * rig.plant.u * sin(t * 1.8), 0) * CFrame.Angles(0, 0, rad(0.8) * sin(t * 2)))
end

local POOL = Color3.fromRGB(140, 249, 238)
IDLES.raincup = function(rig, t)
	stemBody(rig, t)
	set(rig, "Stem", CFrame.Angles(rad(0.7) * sin(t * 1.3), 0, 0))
	set(rig, "Cup", CFrame.Angles(rad(0.7) * sin(t * 1.1), 0, rad(0.5) * sin(t * 0.8)))
	-- Every pool shimmers from the core's own colour, as the script did.
	local core = rig.plant.tints.pools
	local poolColor = nil
	for _, p in ipairs(core or {}) do
		if p.part.Name == "PoolCore" then
			poolColor = p.base
		end
	end
	if poolColor then
		local shimmer = 0.07 + 0.05 * sin(t * 1.7)
		for _, p in ipairs(core) do
			p.part.Color = poolColor:Lerp(POOL, shimmer)
		end
		for i = 1, 4 do
			for _, r in ipairs(rig.plant.tints["ripple" .. i] or {}) do
				r.part.Color = r.base:Lerp(poolColor, 0.25 + 0.2 * sin(t * 2 - i * 0.5))
			end
		end
	end
	for i = 1, 2 do
		set(rig, "LeafJoint" .. i, CFrame.Angles(rad(2) * sin(t * 2 + i), 0, 0))
	end
	blinkEyes(rig, t % 5.7 > 5.54, 0.16)
end

IDLES.suncrown = function(rig, t)
	stemBody(rig, t)
	set(rig, "Stem", CFrame.Angles(rad(1.4) * sin(t * 1.6), 0, 0))
	set(rig, "Blossom", CFrame.Angles(0, rad(2) * sin(t * 0.75), rad(1.1) * sin(t * 1.2)))
	local flare = reveal(t, 13, 9.5, 2.2)
	for i = 1, 12 do
		set(rig, "RayJoint" .. i, CFrame.Angles(rad(2.5) * flare, 0, 0))
	end
	for i = 1, 6 do
		set(rig, "SepalJoint" .. i, CFrame.Angles(rad(1.2) * flare, 0, 0))
	end
	for i = 1, 2 do
		set(rig, "LeafJoint" .. i, CFrame.Angles(rad(2) * sin(t * 2 + i), 0, 0))
	end
	blinkEyes(rig, t % 5.7 > 5.54, 0.16)
end

local VEIN = Color3.fromRGB(214, 194, 245)
IDLES.gloomlotus = function(rig, t)
	local mf = walkOf(rig)
	stemBody(rig, t)
	set(rig, "Stem", CFrame.Angles(rad(0.8) * sin(t * 1.3), 0, 0))
	set(rig, "Blossom", CFrame.Angles(0, rad(1.8) * sin(t * 0.7), rad(0.6) * sin(t * 1.0)))
	local open = reveal(t, 14, 10, 2.4)
	for i = 1, 8 do
		set(rig, "OuterJoint" .. i, CFrame.Angles(rad(1.5) * sin(t * 1.3 + i * 0.4), 0, 0))
	end
	for i = 1, 4 do
		set(rig, "HoodJoint" .. i, CFrame.Angles(rad(4) * open, 0, 0))
	end
	-- The drapes trail further while it walks.
	local trailing = rad(1.0 + 1.8 * mf)
	for i = 1, 6 do
		set(rig, "DrapeJoint" .. i, CFrame.Angles(trailing * sin(t * 1.7 + i * 0.8), 0, rad(1.0) * sin(t * 1.2 + i)))
		set(rig, "HemJoint" .. i, CFrame.Angles(rad(2.2) * sin(t * 1.7 + i * 0.8 - 0.6), 0, 0))
	end
	tint(rig, "veins", VEIN, 0.06 + 0.07 * open)
	blinkEyes(rig, t % 5.7 > 5.54, 0.16)
end

local EMBER = Color3.fromRGB(255, 176, 78)
IDLES.pyrelotus = function(rig, t)
	stemBody(rig, t)
	set(rig, "Stem", CFrame.Angles(rad(1.0) * sin(t * 1.4), 0, 0))
	set(rig, "Blossom", CFrame.Angles(0, rad(1.2) * sin(t * 0.7), rad(0.5) * sin(t * 1.1)))
	local unfurl = reveal(t, 12, 8.8, 2.4)
	for i = 1, 8 do
		set(rig, "OuterJoint" .. i, CFrame.Angles(rad(5) * unfurl, 0, 0))
	end
	for i = 1, 6 do
		set(rig, "InnerJoint" .. i, CFrame.Angles(rad(7) * unfurl, 0, 0))
	end
	tint(rig, "embers", EMBER, 0.04 + 0.02 * sin(t * 1.8) + 0.10 * unfurl)
	-- The lens squints and the iris goes with it.
	blinkEyes(rig, t % 5.7 > 5.54, 0.16)
end

local STAR = Color3.fromRGB(228, 253, 255)
IDLES.supernovus = function(rig, t)
	stemBody(rig, t)
	set(rig, "Stem", CFrame.Angles(rad(0.8) * sin(t * 1.2), 0, 0))
	set(rig, "Stem2", CFrame.Angles(0, 0, rad(0.6) * sin(t * 1.0 + 0.6)))
	set(rig, "Blossom", CFrame.Angles(rad(0.6) * sin(t * 0.8), rad(1.2) * sin(t * 0.6), 0))
	local unfurl = reveal(t, 16, 10, 3)
	for i = 1, 12 do
		set(rig, "OuterJoint" .. i, CFrame.Angles(rad(6) * unfurl, 0, 0))
	end
	for i = 1, 6 do
		set(rig, "InnerJoint" .. i, CFrame.Angles(rad(8) * unfurl, 0, 0))
		set(rig, "CoronaJoint" .. i, CFrame.Angles(rad(3) * unfurl, 0, 0))
	end
	set(rig, "Crystal", CFrame.Angles(rad(1.2) * sin(t * 0.9), 0, rad(0.7) * sin(t * 1.1)))
	tint(rig, "glows", STAR, 0.05 + 0.03 * sin(t * 1.5) + 0.16 * unfurl)
	-- No eyes: SuperNovus does not blink.
end

PlantIdles.Idles = IDLES

--==============================================================================
-- THE WALKS, AS NUMBERS (SecretIdle's WalkProfile; every distance is in the
-- supplied model's own studs and grows with the build factor)
--
-- Five kinds of leg, by how each rig was built:
--
--   foot    one joint, the foot itself carried to each step: the AutoWaddle
--           feet hung off the body, and the root feet hung off the base
--           (Crookreed, Slagbloom). Voidpetal's and Astralhorn's
--           feet are welded to the base and their legs grow UP from them, so
--           the weld is what steps and the leg is BRACED -- turned at its foot
--           to keep leaning toward where its top stood.
--   swing   one joint at the hip, the leg turned to put its sole on the step
--           (Spiretip, Toadcap) and its ankle turned back flat (Snapmoss,
--           Kilnhusk).
--   chain   hip, knee and ankle, solved (Cinderpaw; the Emberquill biped,
--           2026-10-03; the five root-legged lotus forms, whose joints are
--           authored at an angle and posed through their own frames).
--   none    the five with no legs (Bellchime, Thornwhorl, Lanterncap, Novaorb,
--           Cosmospire) hop: the whole rig rises and leans twice a stride.
--
-- Strides are about three tenths of the creature's height, so the cadence is
-- the same at every size: a Tiny trots, a Colossal plods.
--==============================================================================
local function foot(name: string, offset: number, brace: string?, top: string?): any
	return { foot = name, offset = offset, brace = brace, top = top }
end
local function swing(hip: string, offset: number, ankle: string?): any
	return { swing = hip, ankle = ankle, offset = offset }
end
local function chain(hip: string, knee: string, ankle: string, offset: number): any
	return { hip = hip, knee = knee, ankle = ankle, offset = offset }
end

-- A walk with every field filled from `over`.
local function walk(over: { [string]: any }): any
	local profile = {
		legs = {},
		virtual = false,
		duty = 0.6,
		reach = 0.3,
		lift = 0.2,
		footSwing = 0,
		crouch = 0,
		bob = 0,
		bobPeak = 0.3,
		roll = 0,
		rollPeak = 0.3,
		lean = 0,
		arms = {},
		nod = nil,
	}
	for k, v in pairs(over) do
		profile[k] = v
	end
	return profile
end

-- The AutoWaddle body: rides on its feet, rises over each step (crouch is the
-- negative of bob, so it bobs UP from rest, as the scripts' |sin| did).
local function waddle(legs: { any }, reach: number, lift: number, bob: number, roll: number, lean: number?): any
	return walk({
		legs = legs, virtual = true, duty = 0.6, reach = reach, lift = lift,
		crouch = -bob, bob = bob, bobPeak = 0.3, roll = roll, rollPeak = 0.3, lean = lean or -rad(3),
	})
end

local FEET = { foot("HipL", 0), foot("HipR", 0.5) }
local SWINGS = { swing("HipL", 0), swing("HipR", 0.5) }

-- The lotus forms' four root legs: the owner's trot pairs (1 with 4, 2 with 3).
local function rootLegs(): { any }
	return {
		chain("Hip1", "Knee1", "Ankle1", 0), chain("Hip2", "Knee2", "Ankle2", 0.5),
		chain("Hip3", "Knee3", "Ankle3", 0.5), chain("Hip4", "Knee4", "Ankle4", 0),
	}
end
local function lotus(reach: number, lift: number, bob: number): any
	return walk({
		legs = rootLegs(), duty = 0.62, reach = reach, lift = lift, crouch = bob * 0.4, bob = bob,
		bobPeak = 0.25, roll = rad(0.8), rollPeak = 0.25,
	})
end

-- No legs: a hop, twice a stride.
local function hop(reach: number, bob: number, lean: number): any
	return walk({
		virtual = true, duty = 0.5, reach = reach, lift = 0, crouch = -bob, bob = bob, bobPeak = 0,
		roll = rad(3), rollPeak = 0.25, lean = lean,
	})
end

PlantIdles.Walks = {
	nubkin = waddle(FEET, 0.36, 0.2, 0.1, 0.12),
	petalpip = waddle(FEET, 0.34, 0.2, 0.15, 0.09),
	spiretip = waddle(SWINGS, 0.6, 0.3, 0.14, 0.07, -rad(2)),
	toadcap = waddle(SWINGS, 0.62, 0.3, 0.17, 0.1, -rad(2)),
	dunebud = waddle(FEET, 0.28, 0.17, 0.095, 0.11),
	paddlehop = waddle(FEET, 0.32, 0.25, 0.16, 0.12),
	bogbonnet = waddle(FEET, 0.33, 0.18, 0.06, 0.08),

	bellchime = hop(0.45, 0.1, -rad(4)),
	thornwhorl = hop(0.45, 0.09, -rad(3)),
	lanterncap = hop(0.4, 0.07, -rad(3)),
	novaorb = hop(0.55, 0.12, -rad(4)),
	cosmospire = hop(0.9, 0.15, -rad(3)),

	cinderpaw = walk({
		-- The lateral sequence: back left, front left, back right, front right.
		legs = {
			chain("HipBackL", "KneeBackL", "AnkleBackL", 0), chain("HipFrontL", "KneeFrontL", "AnkleFrontL", 0.25),
			chain("HipBackR", "KneeBackR", "AnkleBackR", 0.5), chain("HipFrontR", "KneeFrontR", "AnkleFrontR", 0.75),
		},
		duty = 0.66, reach = 0.5, lift = 0.3, footSwing = -rad(15), crouch = 0.05, bob = 0.05, bobPeak = 0.2,
		roll = rad(1), rollPeak = 0.45, nod = { joint = "Neck", amp = rad(2) },
	}),
	snapmoss = walk({
		legs = {
			swing("HipBackL", 0, "AnkleBackL"), swing("HipFrontL", 0.25, "AnkleFrontL"),
			swing("HipBackR", 0.5, "AnkleBackR"), swing("HipFrontR", 0.75, "AnkleFrontR"),
		},
		duty = 0.66, reach = 0.5, lift = 0.3, bob = 0.04, roll = rad(1), rollPeak = 0.45,
	}),
	kilnhusk = walk({
		legs = { swing("Leg1", 0, "Foot1"), swing("Leg2", 0.5, "Foot2") },
		duty = 0.62, reach = 1.1, lift = 0.5, bob = 0.08, roll = rad(2), lean = -rad(2),
	}),
	crookreed = walk({
		legs = { foot("Foot1", 0), foot("Foot2", 0.25), foot("Foot3", 0.5), foot("Foot4", 0.75) },
		duty = 0.7, reach = 0.2, lift = 0.06, bob = 0.03, roll = rad(2), lean = -rad(3),
	}),
	-- The owner's new Emberquill (2026-10-03) stands on two legs, hip, knee and
	-- ankle, every joint frame square: Snarlbloom's kind of biped walk -- the
	-- weight rolling onto the standing leg, a small lean into the walk, the paws
	-- swinging a little against the legs. Its script never walked.
	emberquill = walk({
		legs = { chain("HipL", "KneeL", "AnkleL", 0), chain("HipR", "KneeR", "AnkleR", 0.5) },
		duty = 0.62, reach = 0.7, lift = 0.4, footSwing = rad(10), crouch = 0.1, bob = 0.08, bobPeak = 0.31,
		roll = rad(2), rollPeak = 0.31, lean = -rad(2),
		arms = { { joint = "ShoulderL", leg = 1, gain = -0.4 }, { joint = "ShoulderR", leg = 2, gain = -0.4 } },
	}),
	slagbloom = walk({
		legs = { foot("Foot1", 0), foot("Foot2", 0.5), foot("Foot3", 0.5), foot("Foot4", 0) },
		reach = 0.6, lift = 0.3, bob = 0.06, roll = rad(1.5), lean = -rad(1.5),
	}),
	voidpetal = walk({
		legs = {
			foot("Hold_RootFoot1", 0, "LowerLeg1", "UpperLeg1"), foot("Hold_RootFoot2", 0.5, "LowerLeg2", "UpperLeg2"),
			foot("Hold_RootFoot3", 0.5, "LowerLeg3", "UpperLeg3"), foot("Hold_RootFoot4", 0, "LowerLeg4", "UpperLeg4"),
		},
		reach = 0.3, lift = 0.15, bob = 0.03, roll = rad(1.5),
	}),
	astralhorn = walk({
		legs = {
			foot("Hold_RootFoot3", 0, "LowerLeg3", "UpperLeg3"), foot("Hold_RootFoot1", 0.25, "LowerLeg1", "UpperLeg1"),
			foot("Hold_RootFoot4", 0.5, "LowerLeg4", "UpperLeg4"), foot("Hold_RootFoot2", 0.75, "LowerLeg2", "UpperLeg2"),
		},
		duty = 0.66, reach = 0.5, lift = 0.25, bob = 0.04, roll = rad(1), rollPeak = 0.45,
		nod = { joint = "Neck", amp = rad(1.5) },
	}),

	raincup = lotus(0.59, 0.34, 0.054),
	suncrown = lotus(0.97, 0.56, 0.09),
	gloomlotus = lotus(0.59, 0.34, 0.054),
	pyrelotus = lotus(1.05, 0.61, 0.097),
	supernovus = lotus(0.59, 0.34, 0.054),

	--==========================================================================
	-- THE RAIN EVENT'S SECOND FAMILY (2026-10-05, the owner's choice: "walk on
	-- their own legs"). The supplied models carried no scripts, so these are
	-- built from each rig's OWN joints, in the kinds above, and nothing else is
	-- added: no idle, no face. Thundershell has no legs to step -- it moves on
	-- its sole, as a snail does, and has no walk here.
	--
	-- NO `arms` AND NO `nod` ON THESE. The walk lays both on top of whatever the
	-- joint was last frame, and every other rig's idle writes those joints
	-- afresh each frame; these have no idle, so a nod accumulated instead --
	-- measured 2026-10-05 in Edit: a walking Colossal Monsoad's head pitched
	-- -45 degrees and put its tongue three studs into the soil.
	--==========================================================================
	-- Two legs, each one bone from the hip with its foot welded on: a swing.
	squallsnapper = walk({
		legs = { swing("HipL", 0), swing("HipR", 0.5) },
		duty = 0.6, reach = 0.32, lift = 0.2, bob = 0.06, bobPeak = 0.31, roll = rad(2), rollPeak = 0.31,
		lean = -rad(2),
	}),
	-- Four legs, hip / knee / ankle behind and shoulder / elbow / wrist in front:
	-- the lateral sequence Cinderpaw walks, back left first.
	monsoad = walk({
		legs = {
			chain("HipL", "KneeL", "AnkleL", 0), chain("ShoulderL", "ElbowL", "WristL", 0.25),
			chain("HipR", "KneeR", "AnkleR", 0.5), chain("ShoulderR", "ElbowR", "WristR", 0.75),
		},
		duty = 0.66, reach = 0.5, lift = 0.3, crouch = 0.05, bob = 0.05, bobPeak = 0.2,
		roll = rad(1), rollPeak = 0.45,
	}),
	-- Six tentacles, three joints each: two tripods, front and back of one side
	-- with the middle of the other.
	torrentacle = walk({
		legs = {
			chain("HipFL", "KneeFL", "AnkleFL", 0), chain("HipSR", "KneeSR", "AnkleSR", 0),
			chain("HipBL", "KneeBL", "AnkleBL", 0), chain("HipFR", "KneeFR", "AnkleFR", 0.5),
			chain("HipSL", "KneeSL", "AnkleSL", 0.5), chain("HipBR", "KneeBR", "AnkleBR", 0.5),
		},
		duty = 0.6, reach = 0.3, lift = 0.18, crouch = 0.03, bob = 0.04, bobPeak = 0.25, roll = rad(1),
		rollPeak = 0.3,
	}),
} :: { [string]: any }

--==============================================================================
-- THE INVITE A FRIEND FORMS (2026-10-06): ONE IDLE, FOUR CHARACTERS
--
-- Dustthorn, Thornbrute, Pharaothorn and Heliothorn are one rig family (see
-- InviteForms' banner) and came with no idle of their own -- only Heliothorn's
-- aura script, ported below as written. So one idle plays all four, and every
-- number that makes them differ is InviteForms.Profiles': a heavier, slower
-- breath and sway as the form evolves, Heliothorn the grandest.
--
-- EVERY POSE IS ABSOLUTE. Each joint this touches is written from its rest
-- every frame -- never added to last frame's pose -- so nothing accumulates
-- (the Rain Event 2 creatures' walk nod did, on rigs whose idle never wrote
-- their necks). The walk's arm swing and neck nod are laid over the shoulders
-- and the neck this writes afresh each frame.
--==============================================================================
local InviteForms = require(script.Parent:WaitForChild("InviteForms"))

-- 0 at rest, 1 at the top of the breath, eased both ways.
local function breathOf(t: number, period: number): number
	return 0.5 - 0.5 * cos(t * 2 * pi / period)
end

--==============================================================================
-- HELIOTHORN'S AURA: THE OWNER'S HeliothornAura SCRIPT, PORTED AS WRITTEN
--
-- The sphere breathes and fades, the sun disc turns, the rays slide out and
-- in, the four sunstones orbit, bob and tumble, every glowing part pulses
-- (staggered, so it ripples) and the lights flicker; every 7 seconds it FLARES
-- -- the sphere swells and brightens, the rays shoot out, the sun and the
-- stones speed up, the lights surge and a burst of sparks flies out. Same
-- periods, amplitudes and cycle. Three things changed, because the game owns
-- what the script owned on its own:
--
--   DISTANCE  its unit U (the model's `Scale` attribute, 4) was written before
--             the owner's Scale tool took the model to x2.84, so a distance is
--             U x that scale (the scan's `u`), and the sphere's rest size is
--             the size it was BUILT at, not its stale BaseSize attribute (10.8
--             against the 30.65 it stands at -- the script would have shrunk it).
--   SPINS     the script added each frame's turn to a running angle; this works
--             the same total out from the clock (flareArea), so every client
--             agrees and nothing piles up.
--   PULSES    a looping colour tween per part became the same sine, from the
--             clock, each part a fixed 0.13 s behind the one before.
--==============================================================================
local AURA_CYCLE = 7

local function flareAt(t: number): number
	local k = t % AURA_CYCLE
	if k < 0.7 then
		return ease(k / 0.7)
	elseif k < 1.6 then
		return 1
	elseif k < 2.8 then
		return 1 - ease((k - 1.6) / 1.2)
	end
	return 0
end

-- The integral of `ease` from 0 to x.
local function easeArea(x: number): number
	return x * x * x - x * x * x * x / 2
end
-- How long, in flare-seconds, one whole cycle flares: 0.35 rising, 0.9 held,
-- 0.6 falling.
local FLARE_AREA = 0.7 * 0.5 + 0.9 + 1.2 * 0.5

-- The flare summed from 0 to t: what the script's per-frame `dt * flare` adds up to.
local function flareArea(t: number): number
	local cycles = math.floor(t / AURA_CYCLE)
	local k = t - cycles * AURA_CYCLE
	local part: number
	if k < 0.7 then
		part = 0.7 * easeArea(k / 0.7)
	elseif k < 1.6 then
		part = 0.35 + (k - 0.7)
	elseif k < 2.8 then
		local y = (k - 1.6) / 1.2
		part = 1.25 + 1.2 * (y - easeArea(y))
	else
		part = FLARE_AREA
	end
	return cycles * FLARE_AREA + part
end
PlantIdles.flareArea = flareArea
PlantIdles.flareAt = flareAt

type AuraState = {
	sphere: Sized?,
	transparency: number,
	glows: { Glow },
}

-- The sphere and the glowing parts, found once per tree build. The glows are
-- ordered by name and height so the ripple runs the same way on every client
-- (a client's descendant order is replication's).
local function auraState(rig: any): AuraState
	local state = rig.inviteAura
	if state then
		return state
	end
	local plant: Plant = rig.plant
	local sphere: Sized? = nil
	local transparency = 0.65
	for _, d in ipairs(rig.model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Aura" then
			sphere = { part = d, size = restSize(d) }
			local base = d:GetAttribute("BaseTransparency")
			transparency = if type(base) == "number" then base else d.Transparency
			break
		end
	end
	local glows = table.clone(plant.glows)
	local pivot = rig.model:GetPivot()
	table.sort(glows, function(a: Glow, b: Glow): boolean
		if a.part.Name ~= b.part.Name then
			return a.part.Name < b.part.Name
		end
		return pivot:PointToObjectSpace(a.part.Position).Y < pivot:PointToObjectSpace(b.part.Position).Y
	end)
	local made: AuraState = { sphere = sphere, transparency = transparency, glows = glows }
	rig.inviteAura = made
	return made
end

local function aura(rig: any, t: number)
	local state = auraState(rig)
	local U = rig.plant.u
	local flare = flareAt(t)
	local cycle = math.floor(t / AURA_CYCLE)
	if flare > 0.95 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "AuraBurst", 40)
	end
	-- The sphere breathes, and swells and brightens in a flare.
	local sphere = state.sphere
	if sphere then
		sphere.part.Transparency = clamp(state.transparency + 0.08 * sin(t * 1.7) - 0.22 * flare, 0.2, 0.95)
		sphere.part.Size = sphere.size * (1 + 0.03 * sin(t * 1.7) + 0.10 * flare)
	end
	-- The sun disc turns (the rays ride on it), faster in a flare.
	local area = flareArea(t)
	set(rig, "Sun", CFrame.Angles(0, 0, -(0.35 * t + 0.8 * area)))
	for k = 1, 8 do
		local a = (k - 1) * pi / 4
		local reach = if k % 2 == 0 then 1 else 0.6
		local ext = (0.04 + 0.015 * sin(t * 2.4 + k) + 0.10 * flare * reach) * U
		set(rig, "Ray" .. k, CFrame.new(cos(a) * ext, sin(a) * ext, 0))
	end
	-- The sunstones orbit, bob and tumble; they speed up in a flare.
	set(rig, "Orbit", CFrame.Angles(0, 0.7 * t + 1.1 * area, 0))
	for i = 1, 4 do
		local bob = sin(t * 1.3 + i * 1.7) * 0.10 * U
		set(rig, "Orbiter" .. i, CFrame.new(0, bob, 0) * CFrame.Angles(t * 1.5 + i, t * 1.1, 0))
	end
	-- Every glowing part pulses between its colour and its hot colour, staggered.
	for i, g in ipairs(state.glows) do
		local delay = (i * 0.13) % 1.4
		g.part.Color = g.base:Lerp(g.hot, 0.5 - 0.5 * cos(pi * (t - delay) / 1.4))
	end
	-- The lights flicker and surge.
	lampAll(rig, 1 + 0.2 * sin(t * 2.2) + 1.4 * flare)
end

-- The one idle, played with one form's numbers (InviteForms.IdleProfile).
local function thorn(rig: any, t: number, idle: InviteForms.IdleProfile)
	local mf, wp = walkOf(rig)
	local still = 1 - mf
	local function cycle(period: number, lag: number?): number
		return sin(t * 2 * pi / period - (lag or 0))
	end
	-- THE BREATH AND THE SWAY, on the chest -- or the whole body, its hips
	-- turned back by the same so the feet stay put (the walk takes both over
	-- as it fades in).
	local b = breathOf(t, idle.breath.period)
	local sway = idle.sway
	local chest = CFrame.Angles(idle.breath.pitch * b, sway.yaw * cycle(sway.period) * still,
		sway.roll * cycle(sway.period, 1.3) * still)
	set(rig, idle.chest, chest)
	if idle.chest == "Root" then
		local back = chest.Rotation:Inverse()
		set(rig, "HipL", back)
		set(rig, "HipR", back)
	end
	-- THE HEAD looks about, level against the breath, and tilts a little.
	local look = idle.look
	local lookYaw = look.yaw * (0.7 * cycle(look.period) + 0.3 * cycle(look.period * 0.37, 2))
	set(rig, "Neck", CFrame.Angles(look.pitch * cycle(look.period * 1.3, 1) - idle.breath.pitch * b * 0.7,
		lookYaw * (0.4 + 0.6 * still), 0))
	set(rig, "Head", CFrame.Angles(0, 0, look.tilt * cycle(look.period * 0.8, 0.5)))
	-- THE JAW eases open with each breath (negative: the jaw's tip drops).
	set(rig, "Jaw", CFrame.Angles(-idle.breath.jaw * b, 0, 0))
	-- THE ARMS hang and sway, opposite each other, and spread with the breath.
	local arms = idle.arms
	local spread = idle.breath.spread * b
	set(rig, "ShoulderL", CFrame.Angles(arms.swing * cycle(arms.period) * still, 0, -spread))
	set(rig, "ShoulderR", CFrame.Angles(arms.swing * cycle(arms.period, pi) * still, 0, spread))
	-- THE TAIL swings down its length, each segment behind and wider than the
	-- last, and wags twice a stride while it walks.
	local tail = idle.tail
	local wag = tail.yaw * sin(2 * wp) * mf
	set(rig, "Tail1", CFrame.Angles(tail.pitch * cycle(tail.period * 2, 0.4),
		tail.yaw * cycle(tail.period) * still + wag, 0))
	set(rig, "Tail2", CFrame.Angles(0, (tail.yaw * cycle(tail.period, tail.lag) * still + wag) * tail.grow, 0))
	set(rig, "Tail3", CFrame.Angles(0, (tail.yaw * cycle(tail.period, 2 * tail.lag) * still + wag)
		* tail.grow * tail.grow, 0))
	-- THE FLOWER OR CROWN nods on its stem.
	local crown = idle.crown
	set(rig, "Stem", CFrame.Angles(crown.sway * cycle(crown.period), 0,
		crown.sway * 0.6 * cycle(crown.period * 0.83, 1)))
	-- THE HEADDRESS: the lappets lift outward with a slow breath of their own,
	-- and the back pyramid tilts.
	local lift = idle.lappet.lift * breathOf(t, idle.lappet.period)
	set(rig, "LappetL", CFrame.Angles(0, 0, -lift))
	set(rig, "LappetR", CFrame.Angles(0, 0, lift))
	local pyramid = idle.pyramid
	set(rig, "Pyramid", CFrame.Angles(pyramid.tilt * cycle(pyramid.period), 0,
		pyramid.tilt * 0.6 * cycle(pyramid.period * 0.7, 2)))
	if idle.aura then
		aura(rig, t)
	end
end

-- The joints the shared idle poses: a spec's list, so a rig's joints can be
-- checked against what its profile moves.
PlantIdles.InviteJoints = {
	"Root", "Waist", "HipL", "HipR", "Neck", "Head", "Jaw", "ShoulderL", "ShoulderR",
	"Tail1", "Tail2", "Tail3", "Stem", "LappetL", "LappetR", "Pyramid",
	"Sun", "Ray1", "Ray2", "Ray3", "Ray4", "Ray5", "Ray6", "Ray7", "Ray8",
	"Orbit", "Orbiter1", "Orbiter2", "Orbiter3", "Orbiter4",
}

for id, profile in pairs(InviteForms.Profiles) do
	local idle, w = profile.idle, profile.walk
	IDLES[id] = function(rig, t)
		thorn(rig, t, idle)
	end
	-- Two legs, hip, knee and ankle: the Secrets' and Emberquill's chain walk;
	-- the arms swing against the legs and the neck nods (InviteForms.WalkNumbers).
	PlantIdles.Walks[id] = walk({
		legs = { chain("HipL", "KneeL", "AnkleL", 0), chain("HipR", "KneeR", "AnkleR", 0.5) },
		duty = w.duty, reach = w.reach, lift = w.lift, footSwing = w.footSwing, crouch = w.crouch,
		bob = w.bob, bobPeak = 0.31, roll = w.roll, rollPeak = 0.31, lean = w.lean,
		arms = { { joint = "ShoulderL", leg = 1, gain = w.armGain }, { joint = "ShoulderR", leg = 2, gain = w.armGain } },
		nod = if w.nod > 0 then { joint = "Neck", amp = w.nod } else nil,
	})
end

return PlantIdles
