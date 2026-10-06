--!strict
-- Steal a Seed :: TrailFX
--
-- THE BLOOMRUNNER TRAIL (2026-09-27; the jackpot look 2026-10-04), the reward
-- wheel's rarest prize, drawn only while its wearer is running:
--
--   * two ribbons at leg height behind the runner -- one mint, one warm gold --
--     weaving gently round each other, with a slow band of light travelling
--     along each, like sun on silk;
--   * gold and mint petals that flutter, turn and fade behind them;
--   * now and then a small flower that opens on the wake, sheds its petals and
--     is gone.
--
-- The look and every number in it -- weave, shimmer, rates, caps, curves -- is
-- BloomTrail's (Shared), checked in Edit by BloomTrailSpec. This script owns the
-- instances and the one loop. PURELY COSMETIC: nothing reads it, and nothing it
-- touches changes speed, reach, rewards, ownership or anything else.
--
-- Every client draws it for every player whose SeedTrail attribute names it --
-- WheelService publishes that from the saved profile on join and on every
-- change -- the way SpeedFX draws the Speed afterimage, and by SpeedFX's rules:
--
--   * FULL FX draws all of it; REDUCED FX -- or Roblox's reduced motion -- draws
--     one shorter, still ribbon with no weave, no shimmer, no petals and no
--     flowers; OFF builds nothing at all;
--   * never for somebody more than RemoteMaxStuds away, never on the frame a
--     body teleports (and what was in the air is cleared, so no ribbon is drawn
--     across the map), never while ragdolled, seated or dead;
--   * only while the body really covers ground: standing still, pushing into a
--     wall or riding a mill shows nothing and lays nothing, however long;
--   * never behind a runner on the Floating Garden, where it would lie over the
--     next jump (2026-09-29; NOT ON THE COURSE, below) -- worn all the same;
--   * built per body, and everything goes with the body: on death, respawn,
--     taking the trail off, leaving -- and a body that vanishes on its own is
--     noticed by the next frame and its pieces destroyed.
--
-- THE BUDGET. Everything a wearer can show is built once, when the trail goes on
-- a body: Full is two Trails and a pool of 24 small parts (12 petals, and two
-- flowers of five petals and a heart); Reduced is one Trail. The one Heartbeat
-- below moves what is in the air and makes nothing -- no Instance, connection
-- or tween is created while anybody runs, and a petal or flower wanted while
-- the pool is all in the air is simply not drawn. Built only for wearers, so a
-- server of forty people with none of them wearing it costs nothing but the
-- attribute watch.
--==============================================================================

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local BloomTrail = require(Shared:WaitForChild("BloomTrail"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local WheelData = require(Shared:WaitForChild("WheelData"))
-- Only for ObbyData.onCourse: not drawn behind a runner (NOT ON THE COURSE, below).
local ObbyData = require(Shared:WaitForChild("ObbyData"))

local player = Players.LocalPlayer
local FX = GameConfig.Afterimage
local TRAIL = WheelData.Trail
local ATTR = WheelData.Attributes.Trail
local LOOK = BloomTrail.Look

local MODE_FULL = "Full"
local MODE_OFF = "Off"

-- How quickly the measured speed, the energy and a turn's swing follow what
-- the body does (per second): quick enough to answer a start or a stop, slow
-- enough that one jerky frame changes nothing.
local SPEED_EASE = 12
local ENERGY_EASE = 3
local SWING_EASE = 8
-- No run, boost or knockback covers ground faster than this: a step that would
-- need more is a teleport, however short (TELEPORTS, below).
local RUN_LIMIT = GameConfig.Speed.MaxWalkSpeed * 1.6

-- The colours, all made once. The two ribbons' shimmer frames (THE SHIMMER,
-- BloomTrail): mint fading to leaf, gold fading to an olive gold.
local MINT, GOLD, LEAF = TRAIL.Mint, TRAIL.Gold, TRAIL.Leaf
local MINT_FRAMES = BloomTrail.shimmerFrames(MINT, LEAF, LOOK.ShimmerFrames)
local GOLD_FRAMES = BloomTrail.shimmerFrames(GOLD, GOLD:Lerp(LEAF, 0.35), LOOK.ShimmerFrames)
local STILL_COLOUR = BloomTrail.stillColour(MINT, GOLD, LEAF)
local RIBBON_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(0.5, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
local RIBBON_TAPER = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.7, 0.65),
	NumberSequenceKeypoint.new(1, 0.15),
})
-- Loose petals take these in turn; a flower is mint with two gold petals and a
-- gold heart.
local PETAL_TINTS = { GOLD, MINT, GOLD:Lerp(LEAF, 0.2), MINT:Lerp(LEAF, 0.25) }
local FLOWER_GOLD = GOLD:Lerp(MINT, 0.3)

type Ribbon = {
	trail: Trail,
	low: Attachment,
	high: Attachment,
	which: number,
	-- The shimmer frames (Full only) and the one on show.
	frames: { ColorSequence }?,
	shown: number,
	phase: number,
}

type Petal = {
	part: BasePart,
	live: boolean,
	born: number,
	life: number,
	from: Vector3,
	puff: Vector3,
	sway: Vector3,
	tilt: CFrame,
	spin: Vector3,
	flutter: number,
}

type FlowerPetal = {
	part: BasePart,
	mesh: SpecialMesh,
	around: number,
}

type Bloom = {
	live: boolean,
	born: number,
	at: CFrame,
	size: number,
	heart: BasePart,
	heartMesh: SpecialMesh,
	petals: { FlowerPetal },
}

type Entry = {
	character: Model,
	root: BasePart,
	humanoid: Humanoid,
	pieces: { Instance },
	-- The folder holding this wearer's petals and flowers (Full only).
	home: Folder?,
	mode: string,
	-- The first ribbon (mint; Reduced's only one), and all of them.
	ribbon: Trail,
	ribbons: { Ribbon },
	petals: { Petal },
	blooms: { Bloom },
	emitter: BloomTrail.Emitter,
	lastPos: Vector3?,
	lastYaw: number?,
	-- Whether its wearer was on the Floating Garden last frame (NOT ON THE COURSE).
	onCourse: boolean,
	-- Not dead, ragdolled or seated, as of the last look.
	upright: boolean,
	-- Measured horizontal speed, and the eased scalars the drawing follows.
	speed: number,
	presence: number,
	energy: number,
	swing: number,
	-- Road covered while drawn, wrapped to one weave: the weave's phase.
	road: number,
	-- How high this body's root stands off the floor, and that over 3.
	lift: number,
	scale: number,
	-- Petals and flowers in the air, and petals laid (for their tints).
	live: number,
	laid: number,
	ignore: { Instance },
}

local tracked: { [Player]: Entry } = {}
local rng = Random.new()
-- What this client draws: Full, Reduced or Off (BloomTrail.mode).
local mode = BloomTrail.mode(player:GetAttribute(FX.QualityAttribute), StatusText.reducedMotion())

-- A flower opens on the floor under the wake or not at all. Real floors only:
-- RespectCanCollide skips zones and other see-through parts.
local probe = RaycastParams.new()
probe.FilterType = Enum.RaycastFilterType.Exclude
probe.RespectCanCollide = true
probe.IgnoreWater = true

-- What the loop moves this frame, sent to the engine in one BulkMoveTo. The
-- lists are emptied, not remade, each frame.
local frameParts: { BasePart } = {}
local frameSpots: { CFrame } = {}

-- A folder this client makes: it exists on this machine and nowhere else.
local folder: Folder? = nil
local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = "SeedBloomTrail"
	made.Parent = Workspace
	folder = made
	return made
end

local function untrack(who: Player)
	local entry = tracked[who]
	tracked[who] = nil
	if entry then
		for _, piece in ipairs(entry.pieces) do
			if piece.Parent then
				piece:Destroy()
			end
		end
	end
end

local function wears(who: Player): boolean
	return who:GetAttribute(ATTR) == TRAIL.Id
end

-- How high a root's centre stands off the floor.
local function rootLift(humanoid: Humanoid, root: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y * 0.5
	end
	return 2 + root.Size.Y * 0.5
end

local function newRibbon(root: BasePart, name: string, which: number, pieces: { Instance }): Ribbon
	local low = Instance.new("Attachment")
	low.Name = name .. "Low"
	low.Parent = root
	local high = Instance.new("Attachment")
	high.Name = name .. "High"
	high.Parent = root
	local frames = if mode == MODE_FULL then (if which == 1 then MINT_FRAMES else GOLD_FRAMES) else nil
	local trail = Instance.new("Trail")
	trail.Name = name
	trail.Attachment0 = low
	trail.Attachment1 = high
	trail.FaceCamera = true
	trail.MinLength = 0.1
	trail.Lifetime = (LOOK.RibbonSeconds :: any)[mode]
	trail.MaxLength = (LOOK.RibbonMaxLength :: any)[mode]
	trail.LightEmission = 0.25
	trail.Color = if frames then frames[1] else STILL_COLOUR
	trail.Transparency = RIBBON_FADE
	trail.WidthScale = RIBBON_TAPER
	trail.Enabled = false
	trail.Parent = root
	table.insert(pieces, low)
	table.insert(pieces, high)
	table.insert(pieces, trail)
	return {
		trail = trail,
		low = low,
		high = high,
		which = which,
		frames = frames,
		shown = 1,
		-- The gold one's light runs half a pass behind the mint one's.
		phase = if which == 2 then LOOK.ShimmerSeconds * 0.5 else 0,
	}
end

-- One part of the pool: an ellipsoid, hidden, touching nothing.
local function poolPart(home: Instance, name: string, size: Vector3, colour: Color3): (BasePart, SpecialMesh)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Material = Enum.Material.Neon
	part.Color = colour
	part.Size = size
	part.Transparency = 1
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	part.Parent = home
	return part, mesh
end

local function build(who: Player, character: Model, root: BasePart, humanoid: Humanoid): Entry
	local budget = (BloomTrail.Budget :: any)[mode]
	local lift = rootLift(humanoid, root)
	local scale = math.clamp(lift / 3, 0.5, 2)
	local pieces: { Instance } = {}
	local ribbons = { newRibbon(root, "BloomrunnerMint", 1, pieces) }
	if budget.Ribbons >= 2 then
		table.insert(ribbons, newRibbon(root, "BloomrunnerGold", 2, pieces))
	end
	local petals: { Petal } = {}
	local blooms: { Bloom } = {}
	local home: Folder? = nil
	if budget.Petals > 0 or budget.Blooms > 0 then
		local made = Instance.new("Folder")
		made.Name = "Bloomrunner_" .. who.Name
		made.Parent = holder()
		table.insert(pieces, made)
		home = made
		for i = 1, budget.Petals do
			local part = poolPart(made, "Petal", LOOK.PetalSize * scale, PETAL_TINTS[(i - 1) % #PETAL_TINTS + 1])
			petals[i] = {
				part = part,
				live = false,
				born = 0,
				life = 1,
				from = Vector3.zero,
				puff = Vector3.zero,
				sway = Vector3.zero,
				tilt = CFrame.identity,
				spin = Vector3.zero,
				flutter = 0,
			}
		end
		for b = 1, budget.Blooms do
			local heart, heartMesh = poolPart(made, "FlowerHeart", Vector3.one * (LOOK.BloomHeart * scale), GOLD)
			local ring: { FlowerPetal } = {}
			for k = 1, budget.BloomPetals do
				local part, mesh = poolPart(made, "FlowerPetal", LOOK.BloomPetalSize * scale,
					if k == 2 or k == 4 then FLOWER_GOLD else MINT)
				ring[k] = { part = part, mesh = mesh, around = (k - 1) / budget.BloomPetals * math.pi * 2 }
			end
			blooms[b] = {
				live = false,
				born = 0,
				at = CFrame.identity,
				size = 1,
				heart = heart,
				heartMesh = heartMesh,
				petals = ring,
			}
		end
	end
	return {
		character = character,
		root = root,
		humanoid = humanoid,
		pieces = pieces,
		home = home,
		mode = mode,
		ribbon = ribbons[1].trail,
		ribbons = ribbons,
		petals = petals,
		blooms = blooms,
		emitter = BloomTrail.newEmitter(rng:NextNumber()),
		lastPos = nil,
		lastYaw = nil,
		onCourse = false,
		upright = true,
		speed = 0,
		presence = 0,
		energy = 0,
		swing = 0,
		road = 0,
		lift = lift,
		scale = scale,
		live = 0,
		laid = 0,
		ignore = { character },
	}
end

local function track(who: Player)
	untrack(who)
	local character = who.Character
	if mode == MODE_OFF or not character or not wears(who) then
		return
	end
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 5)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not (root and humanoid and root:IsA("BasePart") and humanoid:IsA("Humanoid")) then
			return
		end
		-- The body waited for may no longer be the current one (SpeedFX's note).
		if not character.Parent or who.Character ~= character or not wears(who) or tracked[who]
			or mode == MODE_OFF then
			return
		end
		tracked[who] = build(who, character, root, humanoid)
	end)
end

local function running(entry: Entry): boolean
	local humanoid = entry.humanoid
	local upright = humanoid.Health > 0 and not humanoid.PlatformStand and not humanoid.Sit
	if upright then
		local state = humanoid:GetState()
		upright = state ~= Enum.HumanoidStateType.Dead and state ~= Enum.HumanoidStateType.Physics
			and state ~= Enum.HumanoidStateType.Seated and state ~= Enum.HumanoidStateType.Ragdoll
			and state ~= Enum.HumanoidStateType.FallingDown
	end
	entry.upright = upright
	-- Road measured frame to frame, not the velocity the body reports: a wall
	-- or a mill's belt holds a body in place while its legs still run.
	return upright and entry.speed > FX.MinGroundSpeed
end

--==============================================================================
-- THE AIR: PETALS AND FLOWERS
--==============================================================================
local function hideAir(entry: Entry)
	for _, p in ipairs(entry.petals) do
		if p.live then
			p.live = false
			p.part.Transparency = 1
		end
	end
	for _, b in ipairs(entry.blooms) do
		if b.live then
			b.live = false
			b.heart.Transparency = 1
			for _, fp in ipairs(b.petals) do
				fp.part.Transparency = 1
			end
		end
	end
	entry.live = 0
end

-- Everything this wearer has in the air, gone at once: the way onto the course,
-- and a teleport (TELEPORTS, below).
local function clearAir(entry: Entry)
	for _, r in ipairs(entry.ribbons) do
		r.trail:Clear()
		r.trail.Enabled = false
	end
	entry.presence = 0
	entry.swing = 0
	entry.lastYaw = nil
	hideAir(entry)
end

-- Out of range: nothing drawn and nothing worked out, so what was in the air is
-- put back in the pool rather than left hanging unstepped.
local function rest(entry: Entry)
	for _, r in ipairs(entry.ribbons) do
		if r.trail.Enabled then
			r.trail.Enabled = false
		end
	end
	entry.presence = 0
	hideAir(entry)
end

local function spawnPetal(entry: Entry, now: number)
	local free: Petal? = nil
	for _, p in ipairs(entry.petals) do
		if not p.live then
			free = p
			break
		end
	end
	if not free then
		return
	end
	local cf = entry.root.CFrame
	local s = entry.scale
	local right = cf.RightVector
	free.from = cf * Vector3.new(rng:NextNumber(-0.45, 0.45) * s,
		(LOOK.RibbonHeight + rng:NextNumber(-0.25, 0.25)) * s,
		(LOOK.RibbonBehind + rng:NextNumber(0.2, 0.6)) * s)
	free.puff = -cf.LookVector * rng:NextNumber(LOOK.PetalPuff[1], LOOK.PetalPuff[2])
		+ right * rng:NextNumber(-LOOK.PetalSideways, LOOK.PetalSideways)
		+ Vector3.new(0, rng:NextNumber(LOOK.PetalLift[1], LOOK.PetalLift[2]), 0)
	free.sway = right * (LOOK.PetalFlutter * s)
	free.tilt = CFrame.Angles(rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, math.pi * 2), 0)
	free.spin = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * LOOK.PetalSpin
	free.flutter = rng:NextNumber(0, math.pi * 2)
	free.life = rng:NextNumber(LOOK.PetalLife[1], LOOK.PetalLife[2])
	free.born = now
	entry.laid += 1
	free.part.Color = PETAL_TINTS[entry.laid % #PETAL_TINTS + 1]
	free.live = true
	entry.live += 1
end

local function spawnBloom(entry: Entry, now: number)
	local free: Bloom? = nil
	for _, b in ipairs(entry.blooms) do
		if not b.live then
			free = b
			break
		end
	end
	if not free then
		return
	end
	local root = entry.root
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	flat = flat.Unit
	local s = entry.scale
	local spot = root.Position - flat * (LOOK.BloomBehindStuds * s)
		+ Vector3.new(-flat.Z, 0, flat.X) * (rng:NextNumber(-0.5, 0.5) * s)
	probe.FilterDescendantsInstances = entry.ignore
	local hit = Workspace:Raycast(spot, Vector3.new(0, -(entry.lift + 2.5 * s), 0), probe)
	if not hit then
		return
	end
	-- Never on somebody: a body under the wake is not a floor.
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return
	end
	free.at = CFrame.new(spot.X, hit.Position.Y + LOOK.BloomFloorHeight * s, spot.Z)
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	free.size = rng:NextNumber(0.9, 1.1)
	free.born = now
	free.live = true
	entry.live += 1
end

local function stepPetal(entry: Entry, p: Petal, now: number)
	local age = now - p.born
	local u = age / p.life
	if u >= 1 then
		p.live = false
		p.part.Transparency = 1
		entry.live -= 1
		return
	end
	local drift, fall = BloomTrail.petalTravel(age)
	local at = p.from + p.puff * drift + p.sway * math.sin(p.flutter + age * LOOK.PetalFlutterRate)
		- Vector3.new(0, fall, 0)
	table.insert(frameParts, p.part)
	table.insert(frameSpots, CFrame.new(at) * p.tilt * CFrame.Angles(p.spin.X * age, p.spin.Y * age, p.spin.Z * age))
	p.part.Transparency = BloomTrail.petalFade(u)
end

local function stepBloom(entry: Entry, b: Bloom, now: number)
	local age = now - b.born
	local open, shed, over = BloomTrail.bloomPhase(age)
	if over then
		b.live = false
		b.heart.Transparency = 1
		for _, fp in ipairs(b.petals) do
			fp.part.Transparency = 1
		end
		entry.live -= 1
		return
	end
	-- The pool's parts are already this body's size; `grow` and `b.size` are
	-- the flower's own, through the meshes.
	local s = entry.scale * b.size
	local base = b.at * CFrame.Angles(0, age * LOOK.BloomSpin, 0) + Vector3.new(0, LOOK.BloomRise * s * open, 0)
	local heart = b.size * (0.45 + 0.55 * open) * (1 - shed)
	b.heartMesh.Scale = Vector3.new(heart, heart, heart)
	b.heart.Transparency = 0.1 + 0.9 * shed
	table.insert(frameParts, b.heart)
	table.insert(frameSpots, base)
	local tilt = LOOK.BloomClosedTilt + (LOOK.BloomOpenTilt - LOOK.BloomClosedTilt) * open - 0.6 * shed
	local grow = b.size * (0.5 + 0.5 * open)
	local reach = LOOK.BloomPetalSize.Z * entry.scale * grow * 0.5
	local fade = 0.15 + 0.85 * shed
	for _, fp in ipairs(b.petals) do
		local hinge = base * CFrame.Angles(0, fp.around, 0) * CFrame.new(0, 0, -LOOK.BloomHeart * 0.35 * s)
		local cf = hinge * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, 0, -reach)
		if shed > 0 then
			-- Shedding: each petal lets go outward and down, turning as it falls.
			cf = (cf + hinge.LookVector * (LOOK.BloomShedOut * s * shed)
				- Vector3.new(0, LOOK.BloomShedFall * s * shed * shed, 0)) * CFrame.Angles(0, 0, shed * 2.5)
		end
		fp.mesh.Scale = Vector3.new(grow, b.size, grow)
		fp.part.Transparency = fade
		table.insert(frameParts, fp.part)
		table.insert(frameSpots, cf)
	end
end

--==============================================================================
-- ONE WEARER, ONE FRAME
--
-- `road` is the horizontal ground covered since last frame, `want` whether the
-- trail is drawn at all. Starting grows the ribbons in from nothing; stopping
-- narrows them away while what is already laid fades by its own lifetime; a
-- turn swings them a little to its outside. Petals and flowers are laid by road
-- (BloomTrail.emit), and only while running.
--==============================================================================
local function drive(entry: Entry, want: boolean, road: number, dt: number, now: number)
	if want then
		entry.presence = math.min(1, entry.presence + dt * LOOK.PresenceIn)
	elseif entry.upright then
		entry.presence = math.max(0, entry.presence - dt * LOOK.PresenceOut)
	else
		-- Ragdolled, seated or dead: off at once, not narrowed away.
		entry.presence = 0
	end
	local full = entry.mode == MODE_FULL
	entry.energy += (BloomTrail.energy(entry.speed) - entry.energy) * math.min(1, dt * ENERGY_EASE)
	local look = entry.root.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local turn = 0
	local lastYaw = entry.lastYaw
	if lastYaw ~= nil then
		turn = ((yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi) / dt
	end
	entry.lastYaw = yaw
	local swing = if full and want then BloomTrail.swing(turn) else 0
	entry.swing += (swing - entry.swing) * math.min(1, dt * SWING_EASE)
	if want then
		entry.road = (entry.road + road) % LOOK.WeaveStuds
	end

	local show = entry.presence > 0
	local s = entry.scale
	for _, r in ipairs(entry.ribbons) do
		if r.trail.Enabled ~= show then
			r.trail.Enabled = show
		end
		if show then
			local centre, half = BloomTrail.weave(entry.road, entry.presence, entry.energy, r.which, not full)
			local x, y, z = centre.X * s + entry.swing, centre.Y * s, centre.Z * s
			r.low.Position = Vector3.new(x, y - half * s, z)
			r.high.Position = Vector3.new(x, y + half * s, z)
			local frames = r.frames
			if frames then
				local k = BloomTrail.shimmerIndex(now + r.phase, #frames)
				if k ~= r.shown then
					r.shown = k
					r.trail.Color = frames[k]
				end
			end
		end
	end

	if want and full then
		local petals, bloom = BloomTrail.emit(entry.emitter, road, now, entry.energy, entry.mode, rng:NextNumber())
		if petals > 0 then
			spawnPetal(entry, now)
		end
		if bloom then
			spawnBloom(entry, now)
		end
	end
	if entry.live > 0 then
		for _, p in ipairs(entry.petals) do
			if p.live then
				stepPetal(entry, p, now)
			end
		end
		for _, b in ipairs(entry.blooms) do
			if b.live then
				stepBloom(entry, b, now)
			end
		end
	end
end

RunService.Heartbeat:Connect(function(dt: number)
	if mode == MODE_OFF or next(tracked) == nil then
		return
	end
	local now = os.clock()
	local frame = math.clamp(dt, 1 / 240, 0.1)
	local mine = player.Character
	local mineRoot = if mine then mine:FindFirstChild("HumanoidRootPart") else nil
	local here = if mineRoot and mineRoot:IsA("BasePart") then mineRoot.Position else nil
	for who, entry in pairs(tracked) do
		local home = entry.home
		if not (entry.character.Parent and entry.root.Parent and entry.ribbon.Parent)
			or (home ~= nil and home.Parent == nil) then
			untrack(who)
		else
			local at = entry.root.Position
			local last = entry.lastPos
			local teleported = false
			local road = 0
			if last then
				local dx, dz = at.X - last.X, at.Z - last.Z
				road = math.sqrt(dx * dx + dz * dz)
				teleported = (at - last).Magnitude > FX.TeleportStuds or road > RUN_LIMIT * math.max(dt, 1 / 240) + 0.5
				if teleported then
					road = 0
				end
			end
			entry.lastPos = at
			entry.speed += (road / frame - entry.speed) * math.min(1, frame * SPEED_EASE)
			local near = who == player or (here ~= nil and (at - here).Magnitude <= FX.RemoteMaxStuds)
			--==================================================================
			-- NOT ON THE COURSE (2026-09-29)
			--
			-- A runner on the Floating Garden wears it and shows none of it: the
			-- camera sits behind the body there, and a ribbon at leg height lies
			-- over the next jump. Drawn again the moment the server says the run
			-- is over (ObbyData.onCourse), by the rules above.
			--
			-- ONLY THE DRAWING. The SeedTrail attribute, the profile's Cosmetics
			-- and EquippedTrail, and the Bag's WEARING card are not touched --
			-- nothing is taken off, so nothing has to be put back on, and no way
			-- out of the course (Return, Exit, a death, leaving and rejoining)
			-- can leave it stuck either way. What is already in the air is
			-- cleared on the way in.
			--==================================================================
			local onCourse = ObbyData.onCourse(who)
			if onCourse ~= entry.onCourse then
				entry.onCourse = onCourse
				if onCourse then
					clearAir(entry)
				end
			end
			--==================================================================
			-- TELEPORTS (2026-10-04)
			--
			-- A jump of more than TeleportStuds in one frame, or any step faster
			-- than RUN_LIMIT -- a teleport, a respawn, a plot trip, the server
			-- putting a body back a few studs -- is never running: the ribbons
			-- are cleared, not just paused, so the next segment cannot join the
			-- old one across the gap, and the petals and flowers left at the old
			-- spot go too. (Play, 2026-10-04: a 20-stud reposition under the old
			-- 24-stud rule drew a ribbon across it and laid a flower.)
			--==================================================================
			if teleported then
				clearAir(entry)
			end
			local want = near and not onCourse and not teleported and running(entry)
			if near then
				drive(entry, want, road, frame, now)
			elseif entry.presence > 0 or entry.live > 0 then
				rest(entry)
			end
		end
	end
	if #frameParts > 0 then
		-- Protected, so that one bad frame cannot leave the lists to grow.
		pcall(Workspace.BulkMoveTo, Workspace, frameParts, frameSpots, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(frameParts)
		table.clear(frameSpots)
	end
end)

local function watch(who: Player)
	who.CharacterAdded:Connect(function()
		track(who)
	end)
	who.CharacterRemoving:Connect(function()
		untrack(who)
	end)
	who:GetAttributeChangedSignal(ATTR):Connect(function()
		track(who)
	end)
	track(who)
end

-- The Settings panel's REDUCED FX, as SpeedFX reads it, and Roblox's reduced
-- motion: a change of what this client draws rebuilds every wearer.
local function setMode()
	local want = BloomTrail.mode(player:GetAttribute(FX.QualityAttribute), StatusText.reducedMotion())
	if want == mode then
		return
	end
	mode = want
	for _, who in ipairs(Players:GetPlayers()) do
		track(who)
	end
end
player:GetAttributeChangedSignal(FX.QualityAttribute):Connect(setMode)
-- An engine without the property has no switch to follow.
pcall(function()
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(setMode)
end)

for _, who in ipairs(Players:GetPlayers()) do
	watch(who)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(untrack)
