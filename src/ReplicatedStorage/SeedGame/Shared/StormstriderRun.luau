--!strict
-- Steal a Seed :: StormstriderRun
--
-- The owner's StormstriderRun script -- supplied inside the "Stormstrider
-- GUARDIAN" model, 2026-10-02 -- ported to the guardian contract. ParentAnim
-- (client) calls Step every frame with the speed it measured off the root and
-- the server's Asleep, and this writes Motor6D.C0 = rest * pose -- never
-- Transform, for the reasons in ParentAnim's banner -- with the script's own
-- joints, swings, folds and phases: the gallop's legs, spine flex and neck
-- bob, the standing breath, snarl, look-round, ear flicks and tail swish, the
-- mane, tail and streamers streaming back, the jaw panting, the cloud lagging,
-- the paw sparks and light trails while it runs, and every 6.5 s the bolt from
-- its cloud onto its back. Asleep, it blends over about a second into the
-- authored sleeping pose (RainForms' Pose), eyes shut, glow dimmed, breathing
-- slowly, "z"s rising.
--
-- WHAT IS THE GAME'S, NOT THE SCRIPT'S:
--   * The body lowers through the RootJoint the builder made (the server's
--     Humanoid holds the root, where the script moved the whole model) -- by a
--     MEASURED drop, not the pose's authored DropStuds. See THE SLEEPING BODY
--     MEETS THE FLOOR below.
--   * The stride lengthens with speed past a cadence of CADENCE strides a
--     second, so a hundred-stud-a-second chase is a gallop and not a blur (the
--     script's 12-stud stride was for its 30-stud demo laps).
--   * The demo laps (AutoRun) are not played: NestService moves it.
--   * Strike: a catch's one visual lightning bolt (NestService stamps
--     CatchStrikeAt/CatchStrikeTime), which the script never had.
--==============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RainForms = require(Shared:WaitForChild("RainForms"))

local StormstriderRun = {}

export type Pulse = { part: BasePart, phase: number }

export type Storm = {
	model: Model,
	root: BasePart,
	motors: { [string]: Motor6D },
	rest: { [Motor6D]: CFrame },
	rootJoint: Motor6D?,
	rootRest: CFrame,
	pose: { [string]: CFrame },
	-- How far the body lowers at full sleep, this frame (Step).
	drop: number,
	-- In the root's frame: the standing rig's lowest point (the floor the
	-- Humanoid's HipHeight was measured to); the sleeping silhouette's lowest
	-- point at each of BREATH_SAMPLES points through the sleeping breath, and
	-- the lowest of them; the floor this lie-down measured.
	restLow: number,
	breathLow: { number },
	sleepLow: number,
	floor: number,
	-- Whether this lie-down has had its floor measured yet.
	measured: boolean,
	unit: number,
	pawSparks: { ParticleEmitter },
	trails: { Trail },
	cloudSparks: ParticleEmitter?,
	rain: ParticleEmitter?,
	rainBase: number,
	heart: PointLight?,
	heartBase: number,
	mouth: PointLight?,
	mouthBase: number,
	strike: PointLight?,
	veins: { Pulse },
	bolts: { Pulse },
	eyes: { BasePart },
	lids: { BasePart },
	dims: { BasePart },
	snore: BillboardGui?,
	zs: { TextLabel },
	-- The run's own state.
	phase: number,
	speedS: number,
	sleep: number,
	lastStrike: number,
	lastPos: Vector3,
	struckAt: number,
}

local rad, sin, cos, pi, exp, max = math.rad, math.sin, math.cos, math.pi, math.exp, math.max
local IDENTITY = CFrame.identity
-- Strides a second at most: past this the stride grows instead.
local CADENCE = 3.2
-- The script's stride at a walk, in studs.
local STRIDE = 12

--==============================================================================
-- THE SLEEPING BODY MEETS THE FLOOR (2026-10-02 fix)
--
-- It slept hovering. The authored SleepPose lowers the body by DropStuds =
-- 1.32 studs, but the body stands with its underside about ten studs above the
-- paws: folding the legs never brought it down, so it lay down in mid-air. The
-- drop is now MEASURED, both ends of it:
--
--   * the SLEEPING SILHOUETTE: the joint tree posed exactly as Step poses it at
--     full sleep (C0 = rest * pose; welds as built), walked from the body, and
--     its lowest visible point found, in the root's frame (sleepLow);
--   * the FLOOR: a ray straight down from the root when it lies down -- the
--     nest's ground or whatever it sleeps on, after the first stream-in and
--     after every walk home -- or, if nothing answers, the standing rig's
--     lowest point, which is where the Humanoid's HipHeight holds the paws
--     (restLow).
--
-- The body lowers by the difference, less CLEARANCE: the lowest sleeping part
-- rests on the floor, nothing below it, nothing hovering. Only the RootJoint
-- moves (the model, its size and its joints are as supplied), the drop rides
-- the same sleep blend as the pose, so waking lifts it as smoothly as it went
-- down, and the floor is re-measured only while the guardian is fully awake or
-- at the first frame of a lie-down, so a new value never jumps a body already
-- down.
--
-- AND IT BREATHES ON THE FLOOR. The owner's sleeping breath tilts the spine
-- (2.5 + 2 degrees), which on a 73-stud body lifts its far end about a stud and
-- a half every breath. So the silhouette's lowest point is tabulated once at
-- BREATH_SAMPLES points across the breath, and each frame the body lowers by
-- the value for the breath it is drawing: the contact stays planted and the
-- rest of the body heaves -- the breath as authored, grounded.
--==============================================================================
local CLEARANCE = 0.05
local FLOOR_PROBE = 80
local BREATH_SAMPLES = 13
-- The sleeping breath, exactly as Step draws it (-1..1, period 4.2 s).
local BREATH_PERIOD = 4.2

local function corners(cf: CFrame, size: Vector3, low: number): number
	local h = size * 0.5
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				low = math.min(low, (cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end
		end
	end
	return low
end

-- Every part's frame in the ROOT's frame, the joint tree walked from the body:
-- a joint's far part is near * C0 * C1^-1 (or back the other way), with each
-- motor's C0 from `c0Of`.
local function posed(rootJoint: Motor6D, rootRest: CFrame, joints: { JointInstance },
	c0Of: (JointInstance) -> CFrame): { [BasePart]: CFrame }
	local placed: { [BasePart]: CFrame } = {}
	local body = rootJoint.Part1
	if not body then
		return placed
	end
	placed[body] = rootRest * rootJoint.C1:Inverse()
	local byPart: { [BasePart]: { JointInstance } } = {}
	for _, j in ipairs(joints) do
		for _, p in ipairs({ j.Part0, j.Part1 }) do
			if p then
				byPart[p] = byPart[p] or {}
				table.insert(byPart[p], j)
			end
		end
	end
	local queue = { body }
	local head = 1
	while head <= #queue do
		local part = queue[head]
		head += 1
		for _, j in ipairs(byPart[part] or {}) do
			local p0, p1 = j.Part0, j.Part1
			if p0 == part and p1 and not placed[p1] then
				placed[p1] = placed[part] * c0Of(j) * j.C1:Inverse()
				table.insert(queue, p1)
			elseif p1 == part and p0 and not placed[p0] then
				placed[p0] = placed[part] * j.C1 * c0Of(j):Inverse()
				table.insert(queue, p0)
			end
		end
	end
	return placed
end

-- The floor under the root, in the root's frame; nil if nothing answers. The
-- guardian itself and every character are left out (a thief can stand close).
local function floorUnder(storm: Storm): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = { storm.model }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(skip, player.Character)
		end
	end
	params.FilterDescendantsInstances = skip
	params.RespectCanCollide = true
	local from = storm.root.Position
	local hit = Workspace:Raycast(from, Vector3.new(0, -FLOOR_PROBE, 0), params)
	if not hit then
		return nil
	end
	return storm.root.CFrame:PointToObjectSpace(hit.Position).Y
end

local function measureDrop(storm: Storm)
	storm.floor = floorUnder(storm) or storm.restLow
	storm.measured = true
end

-- The sleeping silhouette's lowest point at breath `b` (-1..1), between the
-- tabulated samples.
local function lowAtBreath(storm: Storm, b: number): number
	local samples = storm.breathLow
	local n = #samples
	if n < 2 then
		return samples[1] or storm.sleepLow
	end
	local x = (math.clamp(b, -1, 1) + 1) / 2 * (n - 1) + 1
	local i = math.clamp(math.floor(x), 1, n - 1)
	local f = x - i
	return samples[i] + (samples[i + 1] - samples[i]) * f
end

StormstriderRun.CLEARANCE = CLEARANCE

-- The world height of the lowest visible part as the joints stand NOW (every
-- C0 as Step last wrote it, the RootJoint's drop included), walked from the
-- root -- what a running client draws, worked out without the engine's solve
-- (a spec in Edit has none).
function StormstriderRun.Lowest(storm: Storm): number
	local rootJoint = storm.rootJoint
	if not rootJoint then
		return storm.root.Position.Y + storm.restLow
	end
	local joints: { JointInstance } = {}
	for _, d in ipairs(storm.model:GetDescendants()) do
		if d:IsA("JointInstance") and d ~= rootJoint then
			table.insert(joints, d)
		end
	end
	local placed = posed(rootJoint, rootJoint.C0, joints, function(j: JointInstance): CFrame
		return j.C0
	end)
	local low = math.huge
	for part, cf in pairs(placed) do
		if part.Transparency < 0.99 then
			low = corners(storm.root.CFrame * cf, part.Size, low)
		end
	end
	return low
end

-- The rig, read once off a whole model (it streams atomically); nil until its
-- joints are there.
function StormstriderRun.Rig(model: Model): Storm?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local motors: { [string]: Motor6D } = {}
	local rest: { [Motor6D]: CFrame } = {}
	local rootJoint: Motor6D? = nil
	local welds: { JointInstance } = {}
	local pawSparks: { ParticleEmitter }, trails: { Trail } = {}, {}
	local cloudSparks: ParticleEmitter?, rain: ParticleEmitter? = nil, nil
	local heart: PointLight?, mouth: PointLight?, strike: PointLight? = nil, nil, nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			if d.Name == "RootJoint" then
				rootJoint = d
			else
				motors[d.Name] = d
				rest[d] = d.C0
			end
		elseif d:IsA("JointInstance") then
			table.insert(welds, d)
		elseif d:IsA("ParticleEmitter") then
			if d.Name == "PawSparks" then
				table.insert(pawSparks, d)
			elseif d.Name == "CloudSparks" then
				cloudSparks = d
			elseif d.Name == "Rain" then
				rain = d
			end
		elseif d:IsA("Trail") then
			table.insert(trails, d)
		elseif d:IsA("PointLight") then
			if d.Name == "HeartLight" then
				heart = d
			elseif d.Name == "MouthLight" then
				mouth = d
			elseif d.Name == "StrikeLight" then
				strike = d
			end
		end
	end
	if next(motors) == nil then
		return nil
	end
	local veins: { Pulse }, bolts: { Pulse } = {}, {}
	local eyes: { BasePart }, lids: { BasePart }, dims: { BasePart } = {}, {}, {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			if p.Name == "CloudVein" then
				table.insert(veins, { part = p, phase = tonumber(p:GetAttribute("Phase")) or 0 })
			elseif p.Name == "StrikeBolt" then
				table.insert(bolts, { part = p, phase = tonumber(p:GetAttribute("Phase")) or 0 })
			elseif p.Name == "Eye" then
				table.insert(eyes, p)
			elseif p.Name == "EyeClosed" then
				table.insert(lids, p)
			end
			if p:GetAttribute("Dim") then
				table.insert(dims, p)
			end
		end
	end
	local head = model:FindFirstChild("Head")
	local snoreGui = if head then head:FindFirstChild("SnoreZ") else nil
	local snore: BillboardGui? = if snoreGui and snoreGui:IsA("BillboardGui") then snoreGui else nil
	local zs: { TextLabel } = {}
	if snore then
		for _, l in ipairs(snore:GetChildren()) do
			if l:IsA("TextLabel") then
				table.insert(zs, l)
			end
		end
	end
	local pose: { [string]: CFrame } = {}
	local drop = 0
	local authored = RainForms.Guardian.Pose
	if authored then
		for name, v in pairs(authored) do
			if typeof(v) == "CFrame" then
				pose[name] = v
			elseif name == "DropStuds" and type(v) == "number" then
				drop = v
			end
		end
	end
	-- The silhouettes, in the root's frame (THE SLEEPING BODY MEETS THE FLOOR):
	-- standing, every part (the HipHeight's own measure); lying, every visible
	-- part, at BREATH_SAMPLES points through Step's sleeping breath.
	local unit = tonumber(model:GetAttribute("Unit")) or 1
	local restLow, sleepLow = 0, 0
	local breathLow: { number } = {}
	if rootJoint then
		local joints: { JointInstance } = table.clone(welds)
		for _, motor in pairs(motors) do
			table.insert(joints, motor)
		end
		local standing = posed(rootJoint, rootJoint.C0, joints, function(j: JointInstance): CFrame
			return j.C0
		end)
		restLow = math.huge
		for part, cf in pairs(standing) do
			restLow = corners(cf, part.Size, restLow)
		end
		sleepLow = math.huge
		for k = 1, BREATH_SAMPLES do
			local b = -1 + 2 * (k - 1) / (BREATH_SAMPLES - 1)
			local lying = posed(rootJoint, rootJoint.C0, joints, function(j: JointInstance): CFrame
				if not j:IsA("Motor6D") then
					return j.C0
				end
				local sp = pose[j.Name] or IDENTITY
				if j.Name == "Spine1" then
					sp = sp * CFrame.new(0, 0.015 * unit * b, 0) * CFrame.Angles(rad(2.5) * b, 0, 0)
				elseif j.Name == "Spine2" then
					sp = sp * CFrame.Angles(rad(2) * b, 0, 0)
				end
				return j.C0 * sp
			end)
			local low = math.huge
			for part, cf in pairs(lying) do
				if part.Transparency < 0.99 then
					low = corners(cf, part.Size, low)
				end
			end
			if low < math.huge then
				breathLow[k] = low
				sleepLow = math.min(sleepLow, low)
			end
		end
		if #breathLow ~= BREATH_SAMPLES then
			table.clear(breathLow)
		end
		if restLow == math.huge then
			restLow = 0
		end
		if sleepLow == math.huge then
			sleepLow = restLow
		end
	end
	local asleep = model:GetAttribute("Asleep") ~= false
	local struck = model:GetAttribute("CatchStrikeTime")
	local storm: Storm = {
		model = model,
		root = root,
		motors = motors,
		rest = rest,
		rootJoint = rootJoint,
		rootRest = if rootJoint then rootJoint.C0 else IDENTITY,
		pose = pose,
		drop = drop,
		restLow = restLow,
		breathLow = breathLow,
		sleepLow = sleepLow,
		floor = restLow,
		measured = false,
		unit = unit,
		pawSparks = pawSparks,
		trails = trails,
		cloudSparks = cloudSparks,
		rain = rain,
		rainBase = if rain then rain.Rate else 0,
		heart = heart,
		heartBase = if heart then heart.Brightness else 0,
		mouth = mouth,
		mouthBase = if mouth then mouth.Brightness else 0,
		strike = strike,
		veins = veins,
		bolts = bolts,
		eyes = eyes,
		lids = lids,
		dims = dims,
		snore = snore,
		zs = zs,
		phase = 0,
		speedS = 0,
		sleep = if asleep then 1 else 0,
		lastStrike = -1,
		lastPos = root.Position,
		struckAt = if type(struck) == "number" then struck else 0,
	}
	measureDrop(storm)
	return storm
end

local function lerp(a: number, b: number, f: number): number
	return a + (b - a) * f
end

-- One frame. `speed` is studs a second over the ground; `asleep` the server's
-- Asleep; `quiet` the player's reduced motion (the sparks stop and the "z"s
-- hold still; nothing else changes).
function StormstriderRun.Step(storm: Storm, dt: number, now: number, speed: number, asleep: boolean, quiet: boolean)
	dt = math.min(dt, 0.1)
	local t = now
	local unit = storm.unit
	local want = if asleep then 1 else 0
	-- A lie-down measures the floor under it at its first frame (still fully
	-- awake, so the new drop moves nothing yet); fully awake forgets it, so the
	-- next one -- home after a chase -- measures afresh.
	if asleep and not storm.measured and storm.sleep < 0.01 then
		measureDrop(storm)
	elseif not asleep and storm.sleep <= 0 then
		storm.measured = false
	end
	storm.sleep = lerp(storm.sleep, want, 1 - exp(-2.5 * dt))
	if math.abs(storm.sleep - want) < 0.003 then
		storm.sleep = want
	end
	local sleep = storm.sleep
	local awake = 1 - sleep

	-- How fast it runs, smoothed; how much it is "running"; the gallop's phase.
	storm.speedS = lerp(storm.speedS, speed * awake, 1 - exp(-6 * dt))
	local speedS = storm.speedS
	local run = math.clamp(speedS / 6, 0, 1)
	local stand = 1 - run
	local stride = math.max(STRIDE, speedS / CADENCE)
	storm.phase += dt * 2 * pi * (speedS / stride)
	local p = storm.phase
	local breath = sin(t * 2 * pi / 2.6)

	local tf: { [string]: CFrame } = {}
	local function set(name: string, cf: CFrame)
		tf[name] = cf
	end

	-- the spine flexes with the gallop and bobs
	local up = 0.04 * unit * run * (0.5 + 0.5 * sin(p + 1.2))
	set("Spine1", CFrame.new(0, up, 0) * CFrame.Angles(rad(7) * sin(p + 1.2) * run + rad(1) * breath * stand, 0, 0))
	set("Spine2", CFrame.Angles(rad(6) * sin(p + 1.8) * run + rad(1) * breath * stand, 0, 0))

	-- the legs swing about the hip or shoulder, fold the lower leg, keep the paw flat
	local function leg(joint0: string, joint1: string, joint2: string, pp: number, swing: number, fold: number)
		local th = rad(swing) * sin(pp) * run
		local kn = -rad(fold) * max(0, cos(pp)) * run
		set(joint0, CFrame.Angles(th, 0, 0))
		set(joint1, CFrame.Angles(kn, 0, 0))
		set(joint2, CFrame.Angles(-0.5 * (th + kn), 0, 0))
	end
	leg("HipL", "KneeL", "AnkleL", p, 34, 55)
	leg("HipR", "KneeR", "AnkleR", p + 0.6, 34, 55)
	leg("ShoulderL", "ElbowL", "WristL", p + 2.2, 38, 60)
	leg("ShoulderR", "ElbowR", "WristR", p + 2.8, 38, 60)

	-- the neck bobs against the spine; the head stays steady, and looks round standing
	set("Neck1", CFrame.Angles(-rad(5) * sin(p + 1.8) * run + rad(2) * sin(t * 1.7) * stand, rad(6) * sin(t * 0.9) * stand, 0))
	set("Neck2", CFrame.Angles(-rad(4) * sin(p + 2.2) * run + rad(1.5) * sin(t * 1.7 + 0.5) * stand,
		rad(5) * sin(t * 0.9 + 0.4) * stand, 0))
	set("Head", CFrame.Angles(-0.5 * (rad(5) * sin(p + 1.2) + rad(5) * sin(p + 1.8)) * run,
		rad(8) * sin(t * 0.9 + 1) * stand, rad(3) * sin(t * 1.3) * stand))
	-- the jaw hangs a little open, and pants in time with the gallop
	local open = rad(3) + rad(3) * (1 + sin(t * 1.3)) / 2 * stand + (rad(8) + rad(5) * sin(2 * p)) * run
	set("Jaw", CFrame.Angles(-open, 0, 0))
	-- the ears lay back running and flick standing; the horns sway
	set("EarL", CFrame.Angles(rad(22) * run + rad(6) * sin(t * 2.1) * stand, 0, 0))
	set("EarR", CFrame.Angles(rad(22) * run + rad(6) * sin(t * 2.1 + 1.3) * stand, 0, 0))
	set("HornL", CFrame.Angles(0, 0, rad(2) * sin(t * 1.5)))
	set("HornR", CFrame.Angles(0, 0, -rad(2) * sin(t * 1.5 + 1.0)))

	-- the mane streams back and flutters
	for i = 1, 3 do
		local flutL = rad(6) * sin(t * 14 + i * 1.3) * run + rad(4) * sin(t * 2 + i) * stand
		local flutR = rad(6) * sin(t * 14 + i * 1.3 + 1.1) * run + rad(4) * sin(t * 2 + i + 0.7) * stand
		set("ManeL" .. i, CFrame.Angles(-rad(10) * run + flutL, 0, rad(3) * sin(t * 9 + i) * run))
		set("ManeR" .. i, CFrame.Angles(-rad(10) * run + flutR, 0, -rad(3) * sin(t * 9 + i + 1) * run))
	end

	-- the tail whips in a wave: a swish standing, streaming back running
	for i = 1, 6 do
		set("Tail" .. i, CFrame.Angles(
			rad(5) * sin(p * 2 - i * 0.7) * run - rad(2) * run + rad(1.5) * sin(t * 1.4 - i * 0.5) * stand,
			rad(12) * sin(t * 1.8 - i * 0.8) * stand + rad(6) * sin(p - i * 0.6) * run, 0))
	end

	-- the streamers fly back off the shoulders and ripple
	for i = 1, 3 do
		local liftL = -rad(8) * run * i * 0.4
		set("StreamerL" .. i, CFrame.Angles(liftL, 0, rad(14) * sin(t * 10 - i * 0.9) * run + rad(5) * sin(t * 1.8 - i * 0.7) * stand))
		set("StreamerR" .. i, CFrame.Angles(liftL, 0,
			-(rad(14) * sin(t * 10 - i * 0.9 + 1) * run + rad(5) * sin(t * 1.8 - i * 0.7 + 1) * stand)))
	end

	-- the cloud lags behind a little running, and churns
	set("Cloud", CFrame.new(0.015 * unit * sin(t * 1.9), 0.03 * unit * sin(t * 2.6) + 0.02 * unit * run,
		0.14 * unit * run + 0.015 * unit * sin(t * 1.5)) * CFrame.Angles(0, rad(8) * sin(t * 2.0), rad(3) * sin(t * 3.0)))

	-- the sleeping pose blended in: it breathes slowly, an ear twitches now and then
	local breathZ = sin(t * 2 * pi / BREATH_PERIOD)
	local twitch = max(0, sin(t * 0.8)) ^ 24
	for name, motor in pairs(storm.motors) do
		local cf = tf[name] or IDENTITY
		if sleep > 0.001 then
			local sp = storm.pose[name] or IDENTITY
			if name == "Spine1" then
				sp = sp * CFrame.new(0, 0.015 * unit * breathZ, 0) * CFrame.Angles(rad(2.5) * breathZ, 0, 0)
			elseif name == "Spine2" then
				sp = sp * CFrame.Angles(rad(2) * breathZ, 0, 0)
			elseif name == "EarL" then
				sp = sp * CFrame.Angles(rad(10) * twitch, 0, 0)
			end
			cf = cf:Lerp(sp, sleep)
		end
		motor.C0 = storm.rest[motor] * cf
	end
	-- the body lowers onto the floor as it lies down, its lowest part kept on the
	-- floor through the breath (THE SLEEPING BODY MEETS THE FLOOR)
	local rootJoint = storm.rootJoint
	if rootJoint then
		storm.drop = max(0, lowAtBreath(storm, breathZ) - storm.floor - CLEARANCE)
		rootJoint.C0 = storm.rootRest * CFrame.new(0, -storm.drop * sleep, 0)
	end

	-- the eyes shut and the glow dims as it sleeps; the veins crackle
	local shut = sleep > 0.4
	for _, e in ipairs(storm.eyes) do
		e.Transparency = if shut then 1 else 0
	end
	for _, l in ipairs(storm.lids) do
		l.Transparency = if shut then 0 else 1
	end
	for _, d in ipairs(storm.dims) do
		d.Transparency = 0.75 * sleep
	end
	for _, v in ipairs(storm.veins) do
		v.part.Transparency = if sin(t * 23 + v.phase * 7) > 0.7 and sleep < 0.5 then 0 else 0.65
	end

	-- every 6.5 s a bolt cracks from the cloud onto its back (not asleep)
	local k = t % 6.5
	local window = k < 0.35 and sleep < 0.3
	local cycle = math.floor(t / 6.5)
	if window and cycle ~= storm.lastStrike then
		storm.lastStrike = cycle
		local sparks = storm.cloudSparks
		if sparks and not quiet then
			pcall(function()
				sparks:Emit(24)
			end)
		end
	end
	for _, b in ipairs(storm.bolts) do
		b.part.Transparency = if window and sin(t * 61 + b.phase * 5) > -0.2 then 0 else 1
	end
	local strike = storm.strike
	if strike then
		strike.Brightness = if window then 3 * (0.5 + 0.5 * sin(t * 47)) else 0
	end
	local heart = storm.heart
	if heart then
		heart.Brightness = storm.heartBase * (1 + 0.3 * sin(t * 3.2) + (if window then 1.5 else 0)) * (1 - 0.8 * sleep)
	end
	local mouth = storm.mouth
	if mouth then
		mouth.Brightness = storm.mouthBase * (1 - sleep)
	end
	local rain = storm.rain
	if rain then
		rain.Rate = storm.rainBase * (1 - 0.5 * sleep)
	end

	-- the paws throw sparks and the trails switch on as it runs
	for _, e in ipairs(storm.pawSparks) do
		e.Rate = if quiet then 0 else run * 14
	end
	for _, tr in ipairs(storm.trails) do
		tr.Enabled = run > 0.3
	end

	-- little "z"s float up from its head while it sleeps
	local snore = storm.snore
	if snore then
		snore.Enabled = sleep > 0.7
		for i, l in ipairs(storm.zs) do
			local ph = if quiet then (i - 1) / 3 else (t * 0.45 + (i - 1) / 3) % 1
			l.Position = UDim2.fromOffset(34 + ph * 34 + i * 6, 86 - ph * 66)
			l.TextTransparency = 1 - 0.9 * sin(ph * pi)
			l.TextSize = math.floor(16 + 12 * ph)
		end
	end
end

--==============================================================================
-- A CATCH'S ONE BOLT (2026-10-02): from high over the catch straight down onto
-- it, jagged, for a moment, with a flash of light -- VISUAL ONLY; the catch is
-- every guardian's. Faint and with no flash under reduced motion. Built under
-- the camera, so it never replicates.
--==============================================================================
local STRIKE = GameConfig.Weather.EventNest.Strike

function StormstriderRun.Strike(at: Vector3, quiet: boolean)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local rng = Random.new(math.floor(at.X * 7 + at.Z * 13))
	local folder = Instance.new("Folder")
	folder.Name = "SeedCatchStrike"
	local top = at + Vector3.new(0, STRIKE.Height, 0)
	local from = top
	local last: BasePart? = nil
	for i = 1, STRIKE.Parts do
		local u = i / STRIKE.Parts
		local jitter = if i == STRIKE.Parts then Vector3.zero
			else Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5))
		local to = top:Lerp(at, u) + jitter
		local seg = Instance.new("Part")
		seg.Name = "Bolt"
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = STRIKE.Color
		seg.Transparency = if quiet then 0.6 else 0
		seg.Size = Vector3.new(1.1, 1.1, (to - from).Magnitude)
		seg.CFrame = CFrame.lookAt((from + to) / 2, to)
		seg.Parent = folder
		from = to
		last = seg
	end
	if last and not quiet then
		local light = Instance.new("PointLight")
		light.Color = STRIKE.Color
		light.Range = 40
		light.Brightness = 6
		light.Parent = last
	end
	folder.Parent = camera
	task.delay(STRIKE.Seconds, function()
		folder:Destroy()
	end)
end

return StormstriderRun
