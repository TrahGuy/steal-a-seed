--!strict
-- Steal a Seed :: Ambience
--
-- Everything in the world that moves for DECORATION moves here, on each
-- player's own machine.
--
--==============================================================================
-- ONE LOOP, OVER A TAG
--
-- The server builds a thing and tags it; this walks the tagged set once per
-- frame. Not one script per object, not one connection per object -- one
-- Heartbeat over a flat table.
--
-- Nothing here is authoritative and nothing here replicates. It composes each
-- joint's `C0` against a rest pose captured once, and a C0 written on a client
-- is local to that client. So the SERVER owns where Marigold is standing and
-- each CLIENT owns what her wings and limbs are doing, and the two never touch
-- the same property.
--
-- NOT `Motor6D.Transform`, which is the field Roblox's own animator uses and
-- was the obvious choice. Two problems: it is consumed and reset by the
-- animation step, so it does nothing at all outside a running simulation and
-- cannot be checked in Edit; and if the Humanoid ever gains an Animator, that
-- Animator overwrites it every frame and the wings silently stop. C0 is a plain
-- joint property that stays where it is put.
--
-- That split is the whole design: see FairyService for the server half.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FAIRY_TAG = GameConfig.Tags.Fairy

-- Rest poses are captured ONCE and every frame composes against them. Reading a
-- joint's current C0 to derive the next one feeds each frame's rounding into the
-- next, which is how a limb slowly walks off the body.
type Joint = { motor: Motor6D, rest: CFrame, side: number }

type Fairy = {
	model: Model,
	root: BasePart,
	wings: { Joint },
	-- Named limbs, or nil if this rig is missing one. Nothing here assumes a
	-- complete R6: a rig with no left arm should walk with one arm, not throw
	-- sixty times a second.
	rightShoulder: Joint?,
	leftShoulder: Joint?,
	rightHip: Joint?,
	leftHip: Joint?,
	-- Per-fairy phase, so two of them in one place never move in lockstep.
	phase: number,
	-- How far through her stride she is. Advanced by DISTANCE COVERED rather
	-- than by wall-clock, which is what keeps a foot on the ground: a clock-
	-- driven cycle slides when she is slow and sprints on the spot when she
	-- stops.
	stride: number,
	-- HOW FAR THE WALK IS FADED IN, 0 to 1. It lived in a separate table keyed
	-- by Model, which leaked: the tag-removed handler cleared `fairies` and
	-- could not clear `blend`, because `blend` was declared twenty lines below
	-- it and would have been a nil global there. On the record there is only one
	-- table to forget to clean, and it is already cleaned.
	blend: number,
}

local fairies: { [Model]: Fairy } = {}

local function phaseFor(model: Model): number
	local h = 0
	for i = 1, #model.Name do
		h += string.byte(model.Name, i) * i
	end
	local root = model.PrimaryPart
	if root then
		h += math.floor(math.abs(root.Position.X) + math.abs(root.Position.Z))
	end
	return (h % 628) / 100
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local torso = model:FindFirstChild("Torso")
	if not torso then
		return
	end

	local wings: { Joint } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 and d.Part1:GetAttribute("Side") then
			table.insert(wings, {
				motor = d, rest = d.C0, side = d.Part1:GetAttribute("Side") or 1,
			})
		end
	end

	local function joint(name: string): Joint?
		local m = torso:FindFirstChild(name)
		if m and m:IsA("Motor6D") then
			return { motor = m, rest = m.C0, side = 1 }
		end
		return nil
	end

	fairies[model] = {
		model = model,
		root = root,
		wings = wings,
		rightShoulder = joint("Right Shoulder"),
		leftShoulder = joint("Left Shoulder"),
		rightHip = joint("Right Hip"),
		leftHip = joint("Left Hip"),
		phase = phaseFor(model),
		stride = 0,
		blend = 0,
	}
end

for _, m in ipairs(CollectionService:GetTagged(FAIRY_TAG)) do
	track(m)
end
CollectionService:GetInstanceAddedSignal(FAIRY_TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(FAIRY_TAG):Connect(function(m)
	fairies[m] = nil
end)

--==============================================================================
-- THE LOOP
--
-- Wings flap constantly and fast. Limbs swing only while she is actually
-- moving, and settle back to rest when she stops -- a walk cycle that keeps
-- running on a stationary character is the single most obvious tell that an NPC
-- is faked.
--==============================================================================
local FLAP_RATE = 19
local FLAP_ANGLE = math.rad(32)
-- Radians of limb swing per stud walked. Tuned against WalkSpeed 5: a whole
-- stride every ~2.6 studs, which is roughly a step per leg length.
local SWING_PER_STUD = 0.62
local SWING_ANGLE = math.rad(26)
local ARM_SHARE = 0.7
-- How fast the swing fades in and out. Without it, arms snap to rest the frame
-- she stops.
local BLEND_RATE = 6

RunService.Heartbeat:Connect(function(dt)
	if next(fairies) == nil then
		return
	end
	local t = os.clock()

	for model, f in pairs(fairies) do
		if not f.root.Parent then
			-- Despawned without the removed signal firing, so the table cannot
			-- grow without bound.
			fairies[model] = nil
		else
			--== WINGS ==--
			local flap = math.sin(t * FLAP_RATE + f.phase) * FLAP_ANGLE
			for _, w in ipairs(f.wings) do
				-- About local Z, also measured: X does nothing at all on a wing
				-- (it spins the panel about its own long axis) and Y sweeps it
				-- flat sideways. Z is the one that beats up and down.
				--
				-- Composed AFTER the rest pose, so the beat happens about the
				-- wing's own hinge rather than about the torso -- the sweep the
				-- rest pose carries stays intact.
				w.motor.C0 = w.rest * CFrame.Angles(0, 0, flap * w.side)
			end

			--== WALK ==--
			-- Speed from the ROOT'S VELOCITY, not from Humanoid.MoveDirection:
			-- MoveDirection is intent and stays set while she is wedged against
			-- something, which would leave her walking on the spot.
			local speed = Vector3.new(
				f.root.AssemblyLinearVelocity.X, 0,
				f.root.AssemblyLinearVelocity.Z).Magnitude

			f.stride += speed * dt * SWING_PER_STUD
			local target = speed > 0.4 and 1 or 0
			f.blend += (target - f.blend) * math.min(1, dt * BLEND_RATE)

			local swing = math.sin(f.stride) * SWING_ANGLE * f.blend
			-- ABOUT LOCAL Z, AND THAT WAS MEASURED RATHER THAN GUESSED. R6 bakes
			-- a 90-degree yaw into every shoulder and hip C0, so the joint's axes
			-- are not the torso's and the obvious X is wrong: rotating a shoulder
			-- about X slides the arm SIDEWAYS (dX -0.50, dZ 0.00), while Z swings
			-- it forward and back (dZ -0.35). The first version used X and she
			-- walked doing star jumps.
			local function pose(j: Joint?, amount: number)
				if j then
					j.motor.C0 = j.rest * CFrame.Angles(0, 0, amount)
				end
			end
			-- BOTH SIDES TAKE THE SAME SIGN, which looks wrong and is right.
			-- R6 mirrors its left joints with a -90 degree yaw in C0 against the
			-- right's +90, so the two sides' local Z axes ALREADY point opposite
			-- ways in the world. Passing opposite signs cancels that mirroring
			-- out and both legs swing forward together -- measured, and it walked
			-- doing star jumps.
			pose(f.rightHip, swing)
			pose(f.leftHip, swing)
			-- Arms counter the legs, which is what walking is.
			pose(f.rightShoulder, -swing * ARM_SHARE)
			pose(f.leftShoulder, -swing * ARM_SHARE)
		end
	end
end)

--==============================================================================
-- TREADMILL BELTS
--
-- Same contract as everything else in this file: the server built the arrows and
-- tagged them, and this scrolls each client's own copies. A belt whose arrows
-- everybody sees at a different offset is still a belt; sixty parts moving on
-- the SERVER would be sixty parts of replication a second, for paint.
--
-- They scroll toward the BACK of the belt, which is the direction the surface
-- would travel under somebody running forward on it.
--==============================================================================
local CHEVRON_TAG = GameConfig.Tags.MillChevron
--==============================================================================
-- THE BELT NO LONGER HAS A SPEED OF ITS OWN
--
-- It scrolled at a flat 5.5 studs a second whatever was happening, which is how
-- a player ended up sprinting on a surface that crawled. The number now comes
-- off the belt itself -- TreadmillService writes BeltSpeed when somebody steps
-- on or off -- and SpeedFX divides the SAME number by Roblox's 16-stud run
-- cycle to set the animation speed.
--
-- One number, two consumers. They cannot drift because there is nothing to
-- drift from.
--==============================================================================
local IDLE_STUDS = GameConfig.Mill.IdleStuds

local function beltSpeed(belt: BasePart): number
	return tonumber(belt:GetAttribute("BeltSpeed")) or IDLE_STUDS
end

-- How hard each belt is working, 0 to 1, eased. Filled in by refreshBelts far
-- below and declared up here because the emitter pass needs it too -- a mill's
-- particles and a mill's paint are answering the same question and must not
-- answer it from two different numbers.
local beltWork: { [BasePart]: number } = {}

type Chevron = {
	part: BasePart,
	belt: BasePart,
	--==========================================================================
	-- WHERE IT SITS, SPLIT FROM WHICH WAY IT FACES
	--
	-- One CFrame was enough while the only thing that ever changed was Z. The
	-- ladder moves arrows sideways in Y and rakes them about X, and a rake
	-- composed onto a CFrame that already carries the arm's 28-degree yaw pitches
	-- it about its OWN axis -- so the left arm of a pair dips while the right one
	-- rises and the V comes apart. Held separately, the rake happens in the
	-- belt's frame and both arms lean the same way.
	--==========================================================================
	restPos: Vector3,
	restRot: CFrame,
	span: number,
	phase: number,
	-- Which arrow this is in the running order, 0..1. The chase lights them by
	-- ORDER, which is not the same question as where one currently is.
	slot: number,
	-- Its built colour. Every tint is a lerp away from this, so nothing
	-- accumulates frame over frame.
	base: Color3,
	-- A T7 spectrum strip. Not a chevron: it is a piece of the rainbow the belt
	-- is made of. Lies flat and opaque on the plate and takes neither the bob nor
	-- the rake -- one that left the surface would stop being the surface.
	spectrum: boolean,
}

local chevrons: { Chevron } = {}
local chevronIndex: { [BasePart]: number } = {}

local function forgetChevron(instance: Instance)
	local part = instance :: BasePart
	local at = chevronIndex[part]
	if not at then
		return
	end
	local last = #chevrons
	chevrons[at] = chevrons[last]
	chevronIndex[chevrons[at].part] = at
	chevrons[last] = nil
	chevronIndex[part] = nil
end

local function rememberChevron(instance: Instance)
	if not instance:IsA("BasePart") or chevronIndex[instance :: BasePart] then
		return
	end
	local part = instance :: BasePart
	local belt = part.Parent and part.Parent.Parent
	if not (belt and belt:IsA("BasePart")) then
		return
	end
	local span = tonumber(part:GetAttribute("ChevronSpan")) or belt.Size.Z
	local index = tonumber(part:GetAttribute("ChevronIndex")) or 1
	local count = math.max(tonumber(part:GetAttribute("SlatCount")) or 3, 1)
	local rest = (belt :: BasePart).CFrame:ToObjectSpace(part.CFrame)
	local entry: Chevron = {
		part = part,
		belt = belt :: BasePart,
		restPos = rest.Position,
		restRot = rest - rest.Position,
		span = span,
		-- Evenly spaced along the belt by index. The divisor is however many
		-- share this belt -- which the builder stamps, because a seven-arrow
		-- tier and a two-arrow one have to wrap from the same line.
		phase = ((index - 1) / count) * span,
		slot = (index - 1) / count,
		base = part.Color,
		spectrum = part:GetAttribute("BeltBand") == true,
	}
	chevrons[#chevrons + 1] = entry
    chevronIndex[part] = #chevrons
end

--==============================================================================
-- TREADS SCROLL ON THE SAME LIST AS THE ARROWS
--
-- A slat and a chevron are the same problem: a thing that rides the belt and
-- wraps at its ends. They differ in what they look like and in nothing else, so
-- they share the list, the clock and the arithmetic rather than getting a second
-- copy of all three.
--
-- Spacing comes off the slat count now instead of the hardcoded five the arrows
-- assumed -- a fourteen-tread belt and a three-arrow one wrap correctly from the
-- same line.
--==============================================================================
local SLAT_TAG = GameConfig.Tags.MillSlat

for _, tag in ipairs({ CHEVRON_TAG, SLAT_TAG }) do
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		rememberChevron(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(rememberChevron)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(forgetChevron)
end

--==============================================================================
-- ROLLERS, WHEELS AND LEAVES
--
-- Everything else on a mill that turns. Tagged by the builder and moved here
-- for the same reason the chevrons are: the server has no business animating
-- decoration, and six mills of spinning parts replicated every frame would cost
-- more than the entire rest of the map.
--
-- Most of these live on the premium tiers, which is the point -- a tier-7 mill
-- is visibly BUSIER than a tier-1 one, not just a different colour.
--==============================================================================
local ROLLER_TAG = GameConfig.Tags.MillRoller
local WHEEL_TAG = GameConfig.Tags.MillWheel
local LEAF_TAG = GameConfig.Tags.MillLeaf

local spinRest: { [BasePart]: CFrame } = {}
local spinAngle: { [BasePart]: number } = {}

local function beltOf(part: Instance): BasePart?
	local curr: Instance? = part
	while curr do
		if curr:IsA("Model") then
			local belt = curr:FindFirstChild(GameConfig.Plot.TreadmillName)
			if belt and belt:IsA("BasePart") then
				return belt
			end
		end
		curr = curr.Parent
	end
	return nil
end

local GEAR_TAG = GameConfig.Tags.MillGear
local CRANK_TAG = GameConfig.Tags.MillCrank
local BANNER_TAG = GameConfig.Tags.MillBanner
local PULSE_TAG = GameConfig.Tags.MillPulse

--==============================================================================
-- EVERYTHING ELSE THAT MOVES
--
-- All of it off the one belt speed, all of it client-side, and all of it in the
-- single Heartbeat that was already running for the arrows. The rule from the
-- chevrons holds: the server builds it and tags it, each client animates it, and
-- nothing about a spinning gear is ever replicated.
--
-- IDLE AND ACTIVE HAVE TO READ DIFFERENTLY. Belt speed already separates them --
-- 1.6 studs a second against 13 to 27 -- so gears crawl, the crank barely
-- creeps and the pulse goes slow and shallow the moment somebody steps off. The
-- steam is the one thing that is binary, because a vent either is venting or is
-- not.
--==============================================================================
local millClock = 0

local function animateExtras(dt: number)
	millClock += dt

	for _, instance in ipairs(CollectionService:GetTagged(GEAR_TAG)) do
		local gear = instance :: BasePart
		if gear.Parent then
			if not spinRest[gear] then
				spinRest[gear] = gear.CFrame
				spinAngle[gear] = 0
			end
			local belt = beltOf(gear)
			local speed = if belt then beltSpeed(belt) else IDLE_STUDS
			-- The second gear of a pair turns the other way and faster, which is
			-- what a smaller gear meshed to a bigger one does.
			local index = tonumber(gear:GetAttribute("GearIndex")) or 1
			local ratio = if index % 2 == 0 then -1.55 else 1
			spinAngle[gear] = (spinAngle[gear] or 0) + dt * speed * 0.42 * ratio
			gear.CFrame = spinRest[gear] * CFrame.Angles(spinAngle[gear], 0, 0)
		else
			spinRest[gear] = nil
			spinAngle[gear] = nil
		end
	end

	for _, instance in ipairs(CollectionService:GetTagged(CRANK_TAG)) do
		local crank = instance :: BasePart
		if crank.Parent then
			if not spinRest[crank] then
				spinRest[crank] = crank.CFrame
				spinAngle[crank] = 0
			end
			local belt = beltOf(crank)
			local speed = if belt then beltSpeed(belt) else IDLE_STUDS
			spinAngle[crank] = (spinAngle[crank] or 0) + dt * speed * 0.30
			local a = spinAngle[crank]
			-- Round a throw rather than back and forth: an arm on a crank pin
			-- traces a circle, and doing it as two sines is what makes it read
			-- as driven instead of wobbling.
			crank.CFrame = spinRest[crank]
				* CFrame.new(math.cos(a) * 0.9, math.sin(a) * 0.9, 0)
				* CFrame.Angles(0, 0, -a)
		else
			spinRest[crank] = nil
			spinAngle[crank] = nil
		end
	end

	for _, instance in ipairs(CollectionService:GetTagged(BANNER_TAG)) do
		local banner = instance :: BasePart
		if banner.Parent then
			if not spinRest[banner] then
				spinRest[banner] = banner.CFrame
			end
			local side = tonumber(banner:GetAttribute("SwaySide")) or 1
			-- Its own slow cycle, not the belt's: cloth in a garden moves
			-- because there is weather, not because somebody is training.
			local sway = math.sin(millClock * 1.3 + side) * 0.22
			banner.CFrame = spinRest[banner] * CFrame.Angles(0, 0, sway)
		else
			spinRest[banner] = nil
		end
	end

	for _, instance in ipairs(CollectionService:GetTagged(PULSE_TAG)) do
		local lamp = instance :: BasePart
		if lamp.Parent then
			local belt = beltOf(lamp)
			local speed = if belt then beltSpeed(belt) else IDLE_STUDS
			local working = speed > IDLE_STUDS * 2
			-- Quick and bright under load, slow and shallow when empty.
			-- Never fully opaque. Neon at transparency 0.06 does not read as
			-- "lit", it reads as a hole cut in the world with a torch behind it,
			-- and every surface near it loses its edges to the bloom.
			local rate = if working then 5.2 else 1.5
			local depth = if working then 0.20 else 0.12
			local base = if working then 0.22 else 0.38
			lamp.Transparency = base + depth * (0.5 + 0.5 * math.sin(millClock * rate))
		end
	end
end

--==============================================================================
-- PARTICLES THAT ONLY HAPPEN WHILE SOMEBODY IS ON IT
--
-- Any emitter on a mill carrying WhenWorking is off until the belt is being
-- driven, and its Rate rides the same eased work value the belt's paint does --
-- so a mill spins its dust up and lets it die away instead of snapping between
-- nothing and everything.
--
-- AN ATTRIBUTE RATHER THAN A LIST OF NAMES. This used to test `Name == "Steam"`,
-- which meant every new effect had to come back here and add itself to a string
-- comparison in another file -- and the one time something did, it did it by
-- appending an `or` to the condition. The emitter that wants gating now says so
-- itself, at the point where it is built.
--
-- Emitters WITHOUT the attribute are left alone on purpose: tier 7's pollen is
-- meant to drift over an empty mill, because a Heartroot is alive whether or not
-- anybody is using it.
--==============================================================================
local function updateEmitters()
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if instance:IsA("BasePart") and instance.Parent then
			local belt = instance :: BasePart
			local work = beltWork[belt]
			if work == nil then
				-- Before refreshBelts has seen this belt, fall back to the raw
				-- reading rather than treating it as idle.
				work = if beltSpeed(belt) > IDLE_STUDS * 2 then 1 else 0
			end
			local live = work > 0.05
			for _, d in ipairs((belt.Parent :: Instance):GetDescendants()) do
				if d:IsA("ParticleEmitter") and d:GetAttribute("WhenWorking") == true then
					if d.Enabled ~= live then
						d.Enabled = live
					end
					if live then
						local base = tonumber(d:GetAttribute("BaseRate")) or d.Rate
						d.Rate = base * work
					end
				end
			end
		end
	end
end

local HACKER_LOGS_A = {
	"> INITIATING_QUANTUM_CORE_V10...",
	"> BYPASSING_GRAVITY_MATRIX [OK]",
	"> 0x7F4A :: TACHYON_FLOW = 99.8%",
	"> DECRYPTING_SINGULARITY_KEY...",
	"> OVERCLOCKING_HYPERDRIVE: 160/S",
	"> [ROOT@COSMOS] sudo inject_flux",
	"> 0x88B2A90F :: CORE_LOCK [ACTIVE]",
	"> ANTIMATTER_RESONANCE = 1.000",
	"> PARSING_COORDINATES: (42, 99, 160)",
	"> MEMORY_DUMP: 0xDEAD -> 0x00FF88",
	"> GRAVITATIONAL_SINGULARITY: OK",
	"> HYPERLANE_TRAJECTORY_STABLE",
}

local HACKER_LOGS_B = {
	"> 0x8F 0x3B 0xA1 0xFE 0x00 0x9C",
	"> 01000001 01010011 01010100 0101",
	"> 0x7A4F 0x99B1 0x001C 0xFF4D",
	"> FLUX_DENSITY: 12.884 TeV [MAX]",
	"> NODE_0: CONNECTED [127.0.0.1]",
	"> 0xCAFE :: BUFFER_OVERFLOW [OK]",
	"> STAR_MAP: ANDROMEDA_LOCKED",
	"> 0x994F8A :: QUANTUM_KEY_SYNC",
	"> SECTOR_EPSILON: MATRIX_ACTIVE",
	"> EMITTER_GRID: 100% NOMINAL",
}

local TICKERS = {
	"> root@cosmos: bypass_gravity --speed 160",
	"> quantum_inject --flux 12.4TeV [ACTIVE]",
	"> sudo override_physics --force-warp",
	"> singularity_lock: 0x88B2A90F [ONLINE]",
}

local function spinMillParts(dt: number)
	for _, tag in ipairs({ ROLLER_TAG, WHEEL_TAG }) do
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do
			local part = instance :: BasePart
			if part.Parent then
				if not spinRest[part] then
					spinRest[part] = part.CFrame
					spinAngle[part] = 0
				end
				local belt = beltOf(part)
				local speed = if belt then beltSpeed(belt) else IDLE_STUDS
				--==========================================================
				-- A ROLLER TURNS AT THE SPEED OF THE SURFACE ON IT
				--
				-- v / r radians a second, with the radius taken off the part
				-- -- so a small roller spins and a six-stud waterwheel turns
				-- slowly, from the one belt speed and no second constant.
				--==========================================================
				local radius = math.max(part.Size.Y, part.Size.Z) * 0.5
				local turn = if tag == WHEEL_TAG
					then speed / math.max(radius, 1) * 0.35
					else speed / math.max(radius, 0.4)
				spinAngle[part] = (spinAngle[part] or 0) + dt * turn
				part.CFrame = spinRest[part] * CFrame.Angles(spinAngle[part], 0, 0)
			else
				spinRest[part] = nil
				spinAngle[part] = nil
			end
		end
	end

	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillJaw)) do
		local jaw = instance :: BasePart
		if jaw.Parent then
			if not spinRest[jaw] then
				spinRest[jaw] = jaw.CFrame
				spinAngle[jaw] = 0
			end
			local belt = beltOf(jaw)
			local speed = if belt then beltSpeed(belt) else IDLE_STUDS
			spinAngle[jaw] = (spinAngle[jaw] or 0) + dt * math.max(speed * 0.22, 2.5)
			-- Demonic jaw opens and closes in an aggressive snarl/chomp
			local chomp = (math.sin(spinAngle[jaw]) + 1) * 0.5
			local chompAngle = math.rad(4 + chomp * 24)
			jaw.CFrame = spinRest[jaw] * CFrame.Angles(-chompAngle, 0, 0)
		else
			spinRest[jaw] = nil
			spinAngle[jaw] = nil
		end
	end

	--==========================================================================
	-- TIER 10 HOLOGRAPHIC CYBER SCREENS DYNAMIC REACTIVE ANIMATION
	--==========================================================================
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillHolo or "MillHolo")) do
		local pane = instance :: BasePart
		if pane.Parent then
			local belt = beltOf(pane)
			local work = if belt then (beltWork[belt] or (if beltSpeed(belt) > IDLE_STUDS * 2 then 1 else 0)) else 1
			local live = work > 0.05

			pane.Transparency = if live then (0.35 + 0.12 * math.sin(millClock * 3.5)) else 0.88

			for _, sg in ipairs(pane:GetChildren()) do
				if sg:IsA("SurfaceGui") then
					sg.Enabled = true
					local frame = sg:FindFirstChildWhichIsA("Frame")
					if frame then
						frame.BackgroundTransparency = if live then 0.55 else 0.95

						-- 1. Dynamic Speed Readout
						local speedVal = frame:FindFirstChild("SpeedVal", true) :: TextLabel?
						if speedVal and belt then
							local curSpeed = math.floor(beltSpeed(belt) * (0.8 + 0.2 * work))
							speedVal.Text = string.format("%d STUDS/S", curSpeed)
						end

						-- 2. Dynamic Equalizer Waveform Bars
						local eqHolder = frame:FindFirstChild("EqHolder", true)
						if eqHolder then
							for i, bar in ipairs(eqHolder:GetChildren()) do
								if bar:IsA("Frame") then
									local h = if live then (0.25 + 0.75 * math.abs(math.sin(millClock * 6.0 + i * 0.7))) else 0.12
									bar.Size = UDim2.new(bar.Size.X.Scale, bar.Size.X.Offset, h, 0)
								end
							end
						end

						-- 3. Dynamic Hacker Command Line Ticker
						local ticker = frame:FindFirstChild("HackerTicker", true) :: TextLabel?
						if ticker then
							if live then
								local tickIdx = math.floor((millClock * 0.75) % #TICKERS) + 1
								local cursor = if (math.floor(millClock * 3) % 2 == 0) then "_" else ""
								ticker.Text = TICKERS[tickIdx] .. cursor
								ticker.TextColor3 = Color3.fromRGB(0, 255, 170)
							else
								local cursor = if (math.floor(millClock * 1.5) % 2 == 0) then "_" else ""
								ticker.Text = "> WAITING_FOR_OPERATOR..." .. cursor
								ticker.TextColor3 = Color3.fromRGB(0, 180, 130)
							end
						end

						-- 4. Dynamic Multi-Line Streaming Hacker Terminal Logs
						local term = frame:FindFirstChild("HackerTerminal", true) :: TextLabel?
						if term then
							local list = if pane.Name:find("Left") then HACKER_LOGS_A else HACKER_LOGS_B
							if live then
								local stepTime = if belt then math.max(0.25, 2.0 / math.max(beltSpeed(belt), 10)) else 0.4
								local step = math.floor(millClock / stepTime)
								local lines = {}
								for l = 0, 4 do
									local itemIdx = ((step + l) % #list) + 1
									table.insert(lines, list[itemIdx])
								end
								term.Text = table.concat(lines, "\n")
							else
								term.Text = "> SYSTEM_STANDBY\n> CORE_READY: 100%\n> WAITING_FOR_RUNNER...\n> 0x0000 -> IDLE"
							end
						end
					end
				end
			end
		end
	end

	--==========================================================================
	-- TIER 9 ANGEL WINGS SLOW MAJESTIC FLAPPING ANIMATION
	--==========================================================================
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillWing or "MillWing")) do
		local wing = instance
		local rootPart = if wing:IsA("Model") then wing.PrimaryPart else (if wing:IsA("BasePart") then wing else nil)
		if rootPart and rootPart.Parent then
			if not spinRest[wing] then
				spinRest[wing] = if wing:IsA("Model") then wing:GetPivot() else rootPart.CFrame
				spinAngle[wing] = 0
			end
			local belt = beltOf(rootPart)
			local work = if belt then (beltWork[belt] or (if beltSpeed(belt) > IDLE_STUDS * 2 then 1 else 0)) else 1
			local side = tonumber(wing:GetAttribute("WingSide")) or 1

			-- Flap frequency accelerates gracefully under work
			local flapSpeed = if work > 0.05 then (2.8 + work * 2.0) else 1.2
			spinAngle[wing] = (spinAngle[wing] or 0) + dt * flapSpeed

			-- Flapping stroke angles (pitch, yaw, and broad majestic roll)
			local flapAmp = if work > 0.05 then math.rad(28 * (0.6 + 0.4 * work)) else math.rad(14)
			local stroke = math.sin(spinAngle[wing])
			local rollAngle = stroke * flapAmp * side
			local yawAngle = math.cos(spinAngle[wing]) * (flapAmp * 0.4) * side
			local pitchAngle = -math.abs(stroke) * (flapAmp * 0.35)

			local targetCF = spinRest[wing] * CFrame.Angles(pitchAngle, yawAngle, rollAngle)
			if wing:IsA("Model") then
				wing:PivotTo(targetCF)
			else
				rootPart.CFrame = targetCF
			end
		else
			spinRest[wing] = nil
			spinAngle[wing] = nil
		end
	end

	for _, instance in ipairs(CollectionService:GetTagged(LEAF_TAG)) do
		local part = instance :: BasePart
		if part.Parent then
			if not spinRest[part] then
				spinRest[part] = part.CFrame
				spinAngle[part] = 0
			end
			local belt = beltOf(part)
			local speed = if belt then beltSpeed(belt) else IDLE_STUDS
			local index = tonumber(part:GetAttribute("OrbitIndex")) or 1
			local count = tonumber(part:GetAttribute("OrbitCount")) or 5
			spinAngle[part] = (spinAngle[part] or 0) + dt * speed * 0.12
			local a = spinAngle[part] + (index / count) * math.pi * 2
			part.CFrame = spinRest[part]
				* CFrame.new(math.cos(a) * 2.6, math.sin(a * 0.7) * 0.8, math.sin(a) * 2.6)
				* CFrame.Angles(0, -a, 0)
		else
			spinRest[part] = nil
			spinAngle[part] = nil
		end
	end
end

--==============================================================================
-- ONE CLOCK PER BELT, NOT ONE FOR THE WORLD
--
-- Six mills can be at six different speeds -- different tiers, and only some of
-- them occupied -- so a single shared clock cannot describe them. Each belt
-- advances its own, at its own BeltSpeed, and the arrows read from it.
--==============================================================================
local beltClocks: { [BasePart]: number } = {}
local steamClock = 0

--==============================================================================
-- THE LADDER
--
-- Seven belts, each the one below it plus one behaviour, spelled out in
-- GameConfig.Mill.Belt so the whole progression can be read down a column. This
-- is the half that runs it.
--
-- EVERY AMPLITUDE IS MULTIPLIED BY WORK. That is the load-bearing idea and not a
-- detail: "animate as the player uses it" means an empty tier-7 mill is a slow
-- green drift and a ridden one is a rainbow. A mill that performed to nobody
-- would spend nearly all its life spending its best moment on an empty garden --
-- and the upgrade somebody just paid a hundred and fifty million for would be a
-- thing they had already been watching for an hour.
--
-- Work eases rather than snaps, because BeltSpeed is a step function -- it
-- changes the instant a foot lands -- and a belt going from dead to full rainbow
-- in one frame reads as a fault in the lighting.
--==============================================================================
local LADDER = GameConfig.Mill.Belt
local EDGE_FADE = GameConfig.Mill.BeltEdgeFade
type BeltStyle = typeof(LADDER[1])

-- Parallel tables rather than one record per belt per frame: this runs sixty
-- times a second over every mill in the map, and a table allocated inside that
-- loop is garbage made for nothing.
local beltStyleOf: { [BasePart]: BeltStyle } = {}
local beltBase: { [BasePart]: Color3 } = {}

local function refreshBelts(dt: number)
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if instance:IsA("BasePart") and instance.Parent then
			local belt = instance :: BasePart
			local model = belt.Parent
			local stamped = if model then model:GetAttribute("MillTier") else nil
			local tier = math.clamp(
				math.floor(if typeof(stamped) == "number" then stamped else 1),
				1, #LADDER)
			local style = LADDER[tier]
			local spec = GameConfig.Mill.Tiers[tier]
			local run = if spec then spec.beltStuds else GameConfig.Mill.RunCycleStuds

			local target = math.clamp(
				(beltSpeed(belt) - IDLE_STUDS) / math.max(run - IDLE_STUDS, 1), 0, 1)
			local work = beltWork[belt] or 0
			work += (target - work) * math.min(dt * 2.5, 1)

			beltWork[belt] = work
			beltStyleOf[belt] = style
			if beltBase[belt] == nil then
				beltBase[belt] = belt.Color
			end
			if beltClocks[belt] == nil then
				beltClocks[belt] = 0
			end

			--==================================================================
			-- 6 AND 7 PAINT THE PLATE ITSELF
			--
			-- A belt is one part, so there is no varying anything ALONG it: a
			-- travelling band on the surface is not available at any price. What
			-- is available is the whole plate changing at once, which is why
			-- these two rungs are a glint and a hue cycle rather than a sweep --
			-- both of those read correctly on a single flat colour.
			--==================================================================
			local base = beltBase[belt]
			if style.Rainbow > 0 then
				local hue = (millClock * 0.10) % 1
				belt.Color = base:Lerp(
					Color3.fromHSV(hue, 0.55, 0.95), style.Rainbow * work)
			elseif style.Shimmer > 0 then
				local glint = 0.5 + 0.5 * math.sin(millClock * 2.1)
				belt.Color = base:Lerp(
					Color3.new(1, 1, 1), style.Shimmer * work * glint * 0.5)
			elseif belt.Color ~= base then
				belt.Color = base
			end
		end
	end

	for belt in pairs(beltStyleOf) do
		if not belt.Parent then
			beltStyleOf[belt] = nil
			beltWork[belt] = nil
			beltBase[belt] = nil
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	refreshBelts(dt)
	for belt, clock in pairs(beltClocks) do
		if belt.Parent then
			beltClocks[belt] = clock + dt * beltSpeed(belt)
		else
			beltClocks[belt] = nil
		end
	end
	for i = #chevrons, 1, -1 do
		local c = chevrons[i]
		if not (c.part.Parent and c.belt.Parent) then
			forgetChevron(c.part)
		else
			local clock = beltClocks[c.belt]
			if not clock then
				clock = 0
				beltClocks[c.belt] = 0
			end
			local style = beltStyleOf[c.belt] or LADDER[1]
			local work = beltWork[c.belt] or 0

			-- Wrap within the belt's length. Modulo rather than a reset test, so
			-- a dropped frame cannot leave an arrow stranded off the end. `u` is
			-- that same number as a fraction -- 0 at the back, 1 at the front --
			-- and every rung below is written against it.
			local u = ((c.phase + clock) % c.span) / c.span
			local z = u * c.span - c.span * 0.5

			--==============================================================
			-- RUNGS 4 AND 6 MOVE IT
			--
			-- Rake is a constant lean scaled by work, so how hard a mill is
			-- being driven is legible from the arrows alone. Bob is a wave
			-- along the belt, and it is what stops tiers 6 and 7 reading as
			-- tier 5 in a different colour.
			--==============================================================
			local bob = 0
			if style.Bob > 0 and not c.spectrum then
				bob = style.Bob * work
					* math.sin(u * math.pi * 4 + millClock * 2.4)
			end
			c.part.CFrame = c.belt.CFrame
				* CFrame.new(c.restPos.X, c.restPos.Y + bob, z)
				* CFrame.Angles((if c.spectrum and style.Rainbow > 0 then 0 else style.Rake) * work, 0, 0)
				* c.restRot

			local vis = math.clamp(math.min(u, 1 - u) / EDGE_FADE, 0, 1)

			if c.spectrum and style.Rainbow > 0 then
				--==========================================================
				-- RUNG 7 IS MADE OF THESE
				--
				-- A belt is one part, so its colour is one colour: a plate
				-- that cycles hues is lilac, and then is blue, and a rainbow
				-- is every hue AT ONCE, in order. These strips are how the
				-- surface gets to be all of them.
				--
				-- Hue comes from where a strip IS and not from which strip it
				-- is, so the spectrum stays laid out in the world while the
				-- strips travel through it. Keyed the other way it would be
				-- nine coloured sticks going round, which is the version that
				-- looks cheap.
				--
				-- Unlike every other rung this does NOT fade out when the mill
				-- is empty. The rainbow is what the tier IS; it only gets
				-- brighter when somebody is on it.
				--==========================================================
				local hue = (u * 0.75 + millClock * 0.20) % 1
				c.part.Color = Color3.fromHSV(hue, 1, 0.55 + 0.45 * work)
				c.part.Transparency = 1 - vis * 0.82
			else
				--==========================================================
				-- RUNGS 2, 3 AND 5 ARE ALL ONE NUMBER
				--
				-- Breathe, chase and bloom differ in what they vary WITH --
				-- time, running order, and position along the belt -- and
				-- agree on what they vary. Stacking them into a single
				-- brightness is what lets one tier wear all three without
				-- the third fighting the first over the same property.
				--==========================================================
				local lit = 0.45
				if style.Breathe > 0 then
					lit += style.Breathe * work
						* (0.55 + 0.45 * math.sin(millClock * 1.7))
				end
				if style.Chase > 0 then
					-- A short flare per arrow, staggered by running order, so
					-- the light travels the row instead of blinking all at once.
					local t = (millClock * 0.9 - c.slot) % 1
					lit += style.Chase * work * math.max(0, 1 - t * 4)
				end
				if style.Bloom > 0 then
					-- A band sweeping the SURFACE that arrows pass through.
					-- Keyed to position and not to which arrow it is, which is
					-- what makes it read as light on the belt rather than as
					-- more chase.
					local band = math.cos((u - (millClock * 0.35) % 1) * math.pi * 2)
					lit += style.Bloom * work * math.max(0, band) ^ 3
				end

				if style.Rainbow > 0 then
					--======================================================
					-- RUNG 7
					--
					-- Hue runs along the belt AND advances with time, so the
					-- spectrum crawls forward underneath arrows that are
					-- themselves moving forward. Two speeds, which is the whole
					-- difference between a rainbow and a row of coloured sticks.
					--
					-- A quarter of it survives at rest, so an idle Heartroot
					-- still reads as the tier somebody paid for.
					--======================================================
					local hue = (u * 0.75 + millClock * 0.20) % 1
					local value = math.clamp(lit, 0.35, 1)
					c.part.Color = c.base:Lerp(
						Color3.fromHSV(hue, 0.9, value),
						style.Rainbow * math.max(work, 0.25))
				else
					c.part.Color = c.base:Lerp(
						Color3.new(1, 1, 1), math.clamp(lit - 0.45, 0, 1) * 0.9)
				end

				--==========================================================
				-- AND THE WRAP FADE, ON EVERY TIER
				--
				-- Not a rung. An arrow teleports from the front of the belt to
				-- the back once a lap, and unfaded that blink reads as a broken
				-- mill rather than as a humble one.
				--==========================================================
				c.part.Transparency = 1 - vis
			end
		end
	end
	spinMillParts(dt)
	animateExtras(dt)

	--==========================================================================
	-- EMITTERS ARE CHECKED FOUR TIMES A SECOND, NOT SIXTY
	--
	-- Walking every mill's descendants every frame to find out whether a rate
	-- changed would cost more than everything else on this Heartbeat put
	-- together, and nobody can see a particle rate update faster than this.
	--==========================================================================
	steamClock += dt
	if steamClock > 0.25 then
		steamClock = 0
		updateEmitters()
	end
end)
