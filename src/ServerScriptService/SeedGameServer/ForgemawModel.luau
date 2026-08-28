--!strict
--==============================================================================
-- FORGEMAW -- THE EMBERROOT GUARDIAN
--
-- The approved mockup, lifted part for part and articulated across the seven
-- seams every nest parent must have. Nothing here decides what it looks like:
-- this file decides what MOVES, and the shape it moves is the shape that was
-- signed off in Edit.
--
-- Same contract as BramblebackModel, MiremawModel and AstralmawModel, and
-- deliberately not folded into any of them. Two guardians that look nothing
-- alike sharing one recoloured builder is how a biome stops being its own
-- place, which the Dustbowl pass already settled.
--
--==============================================================================
-- THE POSTURE IS THE POINT
--
-- A KNUCKLE-WALKER: mass carried forward on two long forelimbs planted on the
-- ground, short folded hind legs behind, head thrust out AHEAD OF and BELOW the
-- shoulders. None of the other three guardians stand like that, so Forgemaw is
-- told apart by POSTURE before colour or detail can help.
--
-- The pose is DERIVED, not hand-placed. Two points -- SHOULDER and HIP -- define
-- a spine, and the torso, back plates, chest and every limb take their angle
-- from it. That is what keeps a lunging stance a lunging stance while detail
-- changes underneath it.
--
--==============================================================================
-- IT MEASURES ITSELF INSTEAD OF CARRYING A MAGIC HEIGHT
--
-- Miremaw divides by a stored AUTHORED_HEIGHT because its geometry comes from a
-- frozen table and cannot change. Forgemaw's is procedural -- edit the two spine
-- vectors and every part moves -- so a stored height would silently rot the
-- first time somebody adjusted the pose, and the guardian would come out the
-- wrong size on the nest with nothing to indicate why.
--
-- So it builds at its authored scale, measures the true silhouette height over
-- the ROTATED corners, and conforms THAT to whatever NestService asked for. The
-- rotated corners matter: most of this animal is rotated, and an axis-aligned
-- half-extent over-reads a lunging creature badly.
--
--==============================================================================
-- THE SEVEN SEAMS
--
--   RootJoint, Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip
--
-- ParentAnim and SoundCues find them by those names and nothing may rename
-- them. Members are grouped onto their driver by name prefix rather than by an
-- explicit list, because this builder names every limb part with an L or R tag
-- already -- so a part added to the arm later arrives welded to the arm instead
-- of rigid on the torso, which is the failure an explicit list invites.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ForgemawModel = {}

local rad = math.rad

local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

-- Position scales; rotation does not. Subtracting a CFrame's own position
-- leaves the rotation-only CFrame. Identical arithmetic to BramblebackModel and
-- MiremawModel so all four guardians grow the same way.
local function scaled(c: CFrame, s: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s, p.Y * s, p.Z * s) * (c - p)
end

-- Pinned to 1. The mockup grew itself by a constant so the approval could be
-- judged at 21 studs; here the runtime measures and conforms instead. See the
-- banner above.
local SCALE = 1

-- The root sits inside the torso's mass rather than floating in the silhouette.
local ROOT_SIZE = Vector3.new(4.8, 3.6, 3.8)

local C = {
	Char      = Color3.fromRGB(26, 22, 22),
	Basalt    = Color3.fromRGB(48, 40, 40),
	-- Deliberately GREY, not brown. The first pass made every mid tone a warm
	-- brown and under this biome's orange light they collapsed into a single
	-- value; pulling the saturation out of the mids is what lets the ember
	-- channels stay the only warm thing on the animal.
	Kiln      = Color3.fromRGB(94, 84, 80),
	KilnPale  = Color3.fromRGB(142, 128, 122),
	Cinder    = Color3.fromRGB(132, 62, 36),
	Ash       = Color3.fromRGB(152, 142, 134),
	Ember     = Color3.fromRGB(255, 118, 44),
	EmberDeep = Color3.fromRGB(198, 68, 24),
	EmberPale = Color3.fromRGB(255, 166, 78),
	CoreEmber = Color3.fromRGB(255, 162, 62),
	Scab      = Color3.fromRGB(104, 34, 16),
	Tooth     = Color3.fromRGB(238, 228, 206),
	EyeGlow   = Color3.fromRGB(255, 222, 150),
}

type MkArgs = {
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	parent: Instance,
	material: Enum.Material?,
	shape: Enum.PartType?,
	smooth: boolean?,
	transparency: number?,
}

local function mk(a: MkArgs): BasePart
	local p: BasePart
	if a.shape then
		local q = Instance.new("Part")
		q.Shape = a.shape
		p = q
	else
		p = Instance.new("Part")
	end
	p.Name = a.name
	p.Size = a.size
	p.CFrame = a.cf
	p.Color = a.color
	p.Material = a.material or Enum.Material.Plastic
	p.Transparency = a.transparency or 0
	-- FREE, NOT ANCHORED. A guardian is walked by a Humanoid.
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	-- Massless everywhere; the root is the one exception and it is built
	-- below. A massless part cannot anchor an assembly, and letting one of
	-- these become the AssemblyRootPart is how a Humanoid ends up walking
	-- from its own elbow.
	p.Massless = true
	p.CastShadow = true
	local face = if a.smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
	for _, f in ipairs(STUD_FACES) do
		pcall(function()
			(p :: any)[f] = face
		end)
	end
	p.Parent = a.parent
	return p
end

local function alongY(v: Vector3): number
	return math.atan2(v.Z, v.Y)
end

-- A bone: a box running from `a` to `b`, `w` wide and `d` deep.
local function bone(m: Model, name: string, a: Vector3, b: Vector3,
	w: number, d: number, color: Color3, at: CFrame, roll: number?): BasePart
	local v = b - a
	local len = v.Magnitude
	local mid = a:Lerp(b, 0.5)
	return mk({ name = name, size = Vector3.new(w, len, d),
		cf = at * CFrame.new(mid) * CFrame.Angles(alongY(v), 0, rad(roll or 0)),
		color = color, parent = m })
end

local function buildGeometry(parent: Instance, at: CFrame): Model
	-- The nest decides when a guardian wakes; it is never built awake.
	local awake = false
	local m = Instance.new("Model")
	m.Name = "Parent_emberroot"
	m:SetAttribute("BiomeId", "emberroot")
	m:SetAttribute("Asleep", not awake)
	m.Parent = parent

	--== THE SPINE ==--
	-- Shoulders high and forward, hips low and back: a 46 degree lunge.
	local SHOULDER = Vector3.new(0, 10.4, -1.4)
	local HIP = Vector3.new(0, 6.8, 2.4)
	local spineDir = (HIP - SHOULDER).Unit          -- down and back
	local CHEST_N = Vector3.new(0, -spineDir.Z, spineDir.Y)  -- down and forward
	local BACK_N = -CHEST_N                                   -- up and back
	local BACK_PITCH = alongY(BACK_N)
	local TORSO_PITCH = alongY(-spineDir)

	local function onSpine(t: number, off: Vector3): Vector3
		return SHOULDER:Lerp(HIP, t) + off
	end

	--== HEAT CHANNELS ==--
	-- Asleep these are scabbed over and matte; awake they are Neon at full
	-- ember. Same parts in the same places -- only the surface changes, so the
	-- wake reads as this creature lighting up rather than as a second creature.
	local fissureColor = if awake then C.Ember else C.Scab
	local fissureMat = if awake then Enum.Material.Neon else Enum.Material.Slate
	local coreColor = if awake then C.CoreEmber else C.Scab
	local coreMat = if awake then Enum.Material.Neon else Enum.Material.Slate
	local eyeColor = if awake then C.EyeGlow else C.Char
	local eyeMat = if awake then Enum.Material.Neon else Enum.Material.Slate

	local function crack(name: string, size: Vector3, cf: CFrame)
		mk({ name = name, size = size, cf = cf, color = fissureColor,
			material = fissureMat, smooth = true, parent = m })
	end

	--==========================================================================
	-- ROOT AND TORSO
	--==========================================================================
	local rootPos = onSpine(0.42, Vector3.new(0, 0, 0))
	local root = mk({ name = "HumanoidRootPart", size = Vector3.new(4.8, 3.6, 3.8),
		cf = at * CFrame.new(rootPos), color = C.Basalt,
		transparency = 1, smooth = true, parent = m })
	m.PrimaryPart = root

	bone(m, "Torso", SHOULDER, HIP, 5.6, 4.6, C.Char, at)
	mk({ name = "Pelvis", size = Vector3.new(4.4, 2.8, 3.4),
		cf = at * CFrame.new(HIP + Vector3.new(0, 0.2, 0.5))
			* CFrame.Angles(rad(18), 0, 0),
		color = C.Basalt, parent = m })
	mk({ name = "Withers", size = Vector3.new(5.0, 2.2, 3.2),
		cf = at * CFrame.new(SHOULDER + Vector3.new(0, 0.5, 0.2))
			* CFrame.Angles(TORSO_PITCH, 0, 0),
		color = C.Basalt, parent = m })

	--==========================================================================
	-- THE FURNACE, AND THE TWO PLATES THAT SHUTTER IT
	--
	-- Because the body lunges, the chest normal points forward AND down, so the
	-- forge aims at whoever is standing in front of it rather than at the sky.
	--==========================================================================
	--
	-- WHERE THIS SITS, AND WHY IT MOVED
	--
	-- The forge first went on the mid chest, and from directly in front it could
	-- not be seen AT ALL: a lunging animal carries its head out ahead of its
	-- chest, so the head occluded the entire signature. The posture and the
	-- signature were fighting each other.
	--
	-- Resolved by separating them in HEIGHT rather than by weakening either. The
	-- head is now slung low, where a charging animal actually carries it, and
	-- the forge has risen to the crest of the chest -- so from in front you see
	-- the fire first and the head SILHOUETTED against it. That image is better
	-- than either half was alone, and it is only available because the body
	-- lunges.
	local forge = Vector3.new(0, 9.9, -3.5)

	-- Asleep the plates meet on the centreline. Awake they part and rotate
	-- outward, so the gap is a widening WEDGE rather than a sliding door -- a
	-- shutter that slides reads as machinery, and this is cooling rock that has
	-- cracked open.
	local plateGap = if awake then 0.62 else 0.03
	local plateTurn = if awake then 31 else 2
	for i = 0, 1 do
		local side = if i == 0 then -1 else 1
		mk({ name = if i == 0 then "ChestCrustL" else "ChestCrustR",
			size = Vector3.new(2.2, 3.0, 1.3),
			cf = at * CFrame.new(forge + Vector3.new(side * (1.72 + plateGap), -0.1, 0.15))
				* CFrame.Angles(rad(-8), side * rad(plateTurn), side * rad(-6)),
			color = C.Kiln, parent = m })
	end

	-- The mouth is a WIDE band, not a porthole: it has to stay legible over the
	-- head from straight in front, and a wide slot also lets the grate bars cut
	-- it into pieces, so the light reads as broken rather than as a lamp.
	mk({ name = "ForgeMouth",
		size = if awake then Vector3.new(3.3, 1.9, 0.9) else Vector3.new(3.1, 1.5, 0.85),
		cf = at * CFrame.new(forge) * CFrame.Angles(rad(-9), 0, rad(1)),
		color = coreColor, material = coreMat, smooth = true,
		transparency = if awake then 0 else 0.42, parent = m })

	local core = mk({ name = "FurnaceCore",
		size = if awake then Vector3.new(1.5, 1.5, 1.5) else Vector3.new(1.0, 1.0, 1.0),
		cf = at * CFrame.new(forge + Vector3.new(0, 0, 0.45)),
		color = coreColor, material = coreMat, shape = Enum.PartType.Ball,
		smooth = true, transparency = if awake then 0 else 0.3, parent = m })

	mk({ name = "ChestRim", size = Vector3.new(5.4, 0.75, 1.4),
		cf = at * CFrame.new(forge + Vector3.new(0, -1.35, 0.3))
			* CFrame.Angles(rad(-16), 0, rad(2)),
		color = C.Cinder, parent = m })
	mk({ name = "ChestLintel", size = Vector3.new(5.0, 0.65, 1.3),
		cf = at * CFrame.new(forge + Vector3.new(0, 1.35, 0.35))
			* CFrame.Angles(rad(-20), 0, rad(-3)),
		color = C.Cinder, parent = m })

	-- Grate bars across the mouth, uneven, so the light comes out broken.
	local bars = { { -0.86, 2.1, -9 }, { 0.02, 2.4, 5 }, { 0.92, 1.9, -6 } }
	for i, b in ipairs(bars) do
		mk({ name = "GrateBar" .. i,
			size = Vector3.new(0.3, b[2] :: number, 0.34),
			cf = at * CFrame.new(forge + Vector3.new(b[1] :: number, 0, -0.5))
				* CFrame.Angles(rad(-9), 0, rad(b[3] :: number)),
			color = C.Char, parent = m })
	end

	mk({ name = "BellyPlate", size = Vector3.new(3.8, 2.1, 2.7),
		cf = at * CFrame.new(onSpine(0.62, CHEST_N * 1.5))
			* CFrame.Angles(TORSO_PITCH, 0, 0),
		color = C.Char, parent = m })

	crack("FissureChest1", Vector3.new(0.24, 1.7, 0.18),
		at * CFrame.new(onSpine(0.30, CHEST_N * 1.9 + Vector3.new(-1.95, 0, 0)))
			* CFrame.Angles(TORSO_PITCH, 0, rad(26)))
	crack("FissureChest2", Vector3.new(0.2, 1.3, 0.16),
		at * CFrame.new(onSpine(0.02, CHEST_N * 1.9 + Vector3.new(2.05, 0, 0)))
			* CFrame.Angles(TORSO_PITCH, 0, rad(-20)))

	--==========================================================================
	-- BACK -- cooling slag stacked along the spine, leaking heat
	--==========================================================================
	local backs = {
		{ 0.08, 4.9, 1.35, 2.5, -7 },
		{ 0.34, 4.4, 1.25, 2.35, 10 },
		{ 0.60, 3.7, 1.15, 2.1, -13 },
		{ 0.86, 2.9, 1.0, 1.9, 8 },
	}
	for i, b in ipairs(backs) do
		mk({ name = "BackPlate" .. i,
			size = Vector3.new(b[2] :: number, b[3] :: number, b[4] :: number),
			cf = at * CFrame.new(onSpine(b[1] :: number, BACK_N * 1.75))
				* CFrame.Angles(BACK_PITCH, rad(b[5] :: number), rad((i % 2 == 0) and 5 or -4)),
			color = if i % 2 == 0 then C.Kiln else C.Basalt, parent = m })
	end
	crack("FissureBack1", Vector3.new(2.8, 0.24, 0.2),
		at * CFrame.new(onSpine(0.21, BACK_N * 1.7 + Vector3.new(-0.3, 0, 0)))
			* CFrame.Angles(BACK_PITCH, 0, rad(7)))
	crack("FissureBack2", Vector3.new(2.0, 0.2, 0.18),
		at * CFrame.new(onSpine(0.47, BACK_N * 1.6 + Vector3.new(0.4, 0, 0)))
			* CFrame.Angles(BACK_PITCH, 0, rad(-9)))

	--== SHOULDER VENT STACKS: the tallest thing on it ==--
	for i = 0, 1 do
		local side = if i == 0 then -1 else 1
		local lean = if i == 0 then 10 else -14
		local base = SHOULDER + Vector3.new(side * 2.3, 1.3, 0.7)
		bone(m, if i == 0 then "StackL" else "StackR",
			base, base + Vector3.new(side * 0.35, 3.0, 0.5), 1.2, 1.15, C.Kiln, at, lean)
		mk({ name = if i == 0 then "StackCapL" else "StackCapR",
			size = Vector3.new(1.55, 0.45, 1.45),
			cf = at * CFrame.new(base + Vector3.new(side * 0.4, 3.25, 0.55))
				* CFrame.Angles(rad(-8), 0, rad(lean)),
			color = C.Basalt, parent = m })
		mk({ name = if i == 0 then "StackVentL" else "StackVentR",
			size = Vector3.new(0.64, 0.22, 0.6),
			cf = at * CFrame.new(base + Vector3.new(side * 0.4, 3.5, 0.55)),
			color = fissureColor, material = fissureMat, smooth = true, parent = m })
	end

	--==========================================================================
	-- FORELIMBS -- long, planted forward, carrying the weight
	--
	-- Authored as joint positions. Shoulder to elbow to wrist to knuckle, and
	-- the knuckles are the ONLY things on the arm that touch the floor.
	--==========================================================================
	for i = 0, 1 do
		local side = if i == 0 then -1 else 1
		local tag = if i == 0 then "L" else "R"
		-- Asymmetry on purpose: one arm braced further out, so it never reads
		-- as a mirrored diagram.
		local flare = if i == 0 then 1.0 else 1.09

		local sh = Vector3.new(side * 3.35 * flare, SHOULDER.Y, SHOULDER.Z - 0.2)
		local elbow = Vector3.new(side * 3.6 * flare, 5.8, -2.9)
		local wrist = Vector3.new(side * 3.5 * flare, 1.5, -3.6)
		local knuckle = Vector3.new(side * 3.5 * flare, 0.45, -4.0)

		mk({ name = "Shoulder" .. tag, size = Vector3.new(2.7, 2.6, 2.7),
			cf = at * CFrame.new(sh) * CFrame.Angles(rad(-14), 0, side * rad(10)),
			color = C.Kiln, parent = m })
		mk({ name = "AshMantle" .. tag, size = Vector3.new(2.9, 0.62, 2.8),
			cf = at * CFrame.new(sh + Vector3.new(side * 0.15, 1.35, 0.15))
				* CFrame.Angles(rad(-11), 0, side * rad(12)),
			color = C.Ash, parent = m })

		bone(m, "UpperArm" .. tag, sh, elbow, 1.95, 2.0, C.Basalt, at, side * 5)
		bone(m, "Forearm" .. tag, elbow, wrist, 1.8, 1.85, C.Kiln, at, side * 2)
		-- Kiln, not Cinder. These are the two largest flat faces on the whole
		-- animal and in Cinder they read as bright orange shields, which made
		-- the forge compete with the limbs instead of owning the colour.
		mk({ name = "ForearmPlate" .. tag, size = Vector3.new(2.05, 2.5, 0.7),
			cf = at * CFrame.new(elbow:Lerp(wrist, 0.45) + Vector3.new(0, 0, -1.05))
				* CFrame.Angles(rad(6), 0, side * rad(3)),
			color = C.Kiln, parent = m })
		mk({ name = "Fist" .. tag, size = Vector3.new(2.35, 1.8, 2.7),
			cf = at * CFrame.new(knuckle + Vector3.new(0, 0.75, 0.25))
				* CFrame.Angles(rad(-7), side * rad(8), 0),
			color = C.Basalt, parent = m })
		for k = 0, 1 do
			mk({ name = string.format("Knuckle%s%d", tag, k + 1),
				size = Vector3.new(0.85, 0.75, 0.95),
				cf = at * CFrame.new(knuckle + Vector3.new(side * (-0.55 + k * 1.1), -0.1, -0.65 + k * 0.35))
					* CFrame.Angles(rad(-5), 0, side * rad(7)),
				color = C.Char, parent = m })
		end
		crack("FissureArm" .. tag, Vector3.new(0.22, 2.9, 0.18),
			at * CFrame.new(elbow:Lerp(wrist, 0.5) + Vector3.new(side * 1.0, 0, 0.2))
				* CFrame.Angles(rad(5), 0, side * rad(-6)))
	end

	--==========================================================================
	-- HIND LEGS -- short, folded, taking almost none of the weight
	--==========================================================================
	for i = 0, 1 do
		local side = if i == 0 then -1 else 1
		local tag = if i == 0 then "L" else "R"
		local hip = Vector3.new(side * 2.0, HIP.Y - 0.2, HIP.Z)
		local knee = Vector3.new(side * 2.1, 3.8, 3.5)
		local ankle = Vector3.new(side * 2.2, 1.0, 2.8)

		bone(m, "Thigh" .. tag, hip, knee, 2.3, 2.7, C.Basalt, at, side * -6)
		mk({ name = "Hock" .. tag, size = Vector3.new(1.6, 1.4, 1.6),
			cf = at * CFrame.new(knee) * CFrame.Angles(rad(-8), 0, 0),
			color = C.Char, parent = m })
		bone(m, "Shin" .. tag, knee, ankle, 1.6, 1.6, C.Kiln, at, side * 3)
		mk({ name = "Foot" .. tag, size = Vector3.new(1.95, 0.9, 3.2),
			cf = at * CFrame.new(side * 2.2, 0.45, 2.2)
				* CFrame.Angles(0, side * rad(-7), 0),
			color = C.Basalt, parent = m })
		crack("FissureLeg" .. tag, Vector3.new(0.2, 1.6, 0.16),
			at * CFrame.new(hip:Lerp(knee, 0.5) + Vector3.new(side * 1.15, 0, 0))
				* CFrame.Angles(rad(16), 0, side * rad(9)))
	end

	--==========================================================================
	-- NECK AND HEAD -- thrust AHEAD OF and BELOW the shoulders
	--
	-- This is the half of the posture the first attempt lost. The head sitting
	-- level with the shoulders is what made it a biped; carried out front and
	-- a stud and a half lower, the same parts read as an animal that walks on
	-- its hands.
	--==========================================================================
	local HEAD = Vector3.new(0, 6.25, -5.3)
	local neckA = SHOULDER + Vector3.new(0, -0.4, -0.9)
	local neckB = HEAD + Vector3.new(0, 0.7, 1.6)
	bone(m, "Neck1", neckA, neckA:Lerp(neckB, 0.55), 2.45, 2.45, C.Char, at)
	bone(m, "Neck2", neckA:Lerp(neckB, 0.45), neckB, 2.1, 2.1, C.Kiln, at)

	-- Awake it lifts its head to look at you; asleep it drops and turns away.
	-- One POSE difference, so the wake is not purely a lighting change.
	local headLift = if awake then 0.0 else -0.55
	local headPitch = if awake then 2 else 24
	local headTurn = if awake then 0 else 14
	local headCf = at * CFrame.new(HEAD + Vector3.new(0, headLift, 0))
		* CFrame.Angles(rad(headPitch), rad(headTurn), rad(-2))

	mk({ name = "Skull", size = Vector3.new(3.4, 2.7, 4.0),
		cf = headCf, color = C.Basalt, parent = m })
	mk({ name = "BrowRidge", size = Vector3.new(3.65, 0.9, 1.7),
		cf = headCf * CFrame.new(0, 1.1, -1.1) * CFrame.Angles(rad(-10), 0, 0),
		color = C.Cinder, parent = m })
	for i = 0, 1 do
		local side = if i == 0 then -1 else 1
		local tag = if i == 0 then "L" else "R"
		mk({ name = "Cheek" .. tag, size = Vector3.new(0.75, 1.6, 2.4),
			cf = headCf * CFrame.new(side * 1.75, -0.4, 0.1)
				* CFrame.Angles(0, 0, side * rad(7)),
			color = C.Kiln, parent = m })
		mk({ name = "Eye" .. tag, size = Vector3.new(0.66, 0.45, 0.36),
			cf = headCf * CFrame.new(side * 0.95, 0.45, -1.92),
			color = eyeColor, material = eyeMat, smooth = true, parent = m })
		-- Swept BACK along the jawline rather than up. Astralmaw owns the
		-- spires, and anything standing up off this skull would poke into the
		-- forge band and spoil the one clean silhouette the design has.
		mk({ name = "Horn" .. tag, size = Vector3.new(0.7, 1.5, 0.75),
			cf = headCf * CFrame.new(side * 1.55, 0.5, 1.15)
				* CFrame.Angles(rad(62), 0, side * rad(34)),
			color = C.Char, parent = m })
	end
	mk({ name = "Nostrils", size = Vector3.new(1.1, 0.32, 0.32),
		cf = headCf * CFrame.new(0, -0.08, -2.02),
		color = C.Char, parent = m })

	--== JAW -- underslung, and open when it is awake ==--
	local jawDrop = if awake then -1.0 else -0.2
	local jawPitch = if awake then 29 else 4
	local jawCf = headCf * CFrame.new(0, -1.2 + jawDrop, -0.35)
		* CFrame.Angles(rad(jawPitch), 0, 0)

	mk({ name = "LowerJaw", size = Vector3.new(3.05, 1.1, 3.2),
		cf = jawCf, color = C.Kiln, parent = m })
	mk({ name = "Chin", size = Vector3.new(2.3, 0.75, 0.9),
		cf = jawCf * CFrame.new(0, -0.32, -1.6) * CFrame.Angles(rad(10), 0, 0),
		color = C.KilnPale, parent = m })
	-- The throat only shows when the jaw is down, which is exactly when you
	-- want to see it.
	mk({ name = "Throat", size = Vector3.new(2.0, 0.55, 1.6),
		cf = jawCf * CFrame.new(0, 0.45, -0.2),
		color = coreColor, material = coreMat, smooth = true,
		transparency = if awake then 0 else 0.5, parent = m })
	local teeth = { { -0.9, true, 0.66 }, { 0.82, true, 0.58 }, { -0.55, false, 0.52 }, { 0.66, false, 0.6 } }
	for i, t in ipairs(teeth) do
		local upper = t[2] :: boolean
		local h = t[3] :: number
		mk({ name = "Tooth" .. i, size = Vector3.new(0.36, h, 0.36),
			cf = if upper
				then headCf * CFrame.new(t[1] :: number, -1.35, -1.45) * CFrame.Angles(rad(7), 0, rad(5))
				else jawCf * CFrame.new(t[1] :: number, 0.66, -1.3) * CFrame.Angles(rad(-8), 0, rad(-6)),
			color = C.Tooth, smooth = true, parent = m })
	end

	--==========================================================================
	-- THE LIGHT
	--==========================================================================
	--==========================================================================
	-- GROW
	--
	-- One pass, at the end, over the geometry only. Doing it here rather than
	-- threading SCALE through seventy call sites means the pose maths above
	-- stays readable and there is exactly one place a size bug can live.
	--
	-- Everything created AFTER this point -- the light, the emitter, the seven
	-- sockets -- takes SCALE into account itself, because none of them are
	-- BaseParts and none would be caught by this loop.
	--==========================================================================
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = at * scaled(at:ToObjectSpace(d.CFrame), SCALE)
			d.Size = d.Size * SCALE
		end
	end

	local light = Instance.new("PointLight")
	light.Name = "ForgeGlow"
	light.Color = C.Ember
	-- Range 26 lit the WHOLE animal orange and undid the grey mid tones the
	-- palette exists to provide. It should pool at the chest and fall off, so
	-- the fire is a place on the body rather than a coat of paint over it.
	-- The range scales with the animal, or a bigger body would out-grow its
	-- own glow and the forge would stop reaching the ground.
	light.Brightness = if awake then 1.9 else 0.2
	light.Range = (if awake then 14 else 5) * SCALE
	light.Shadows = false
	light.Parent = core

	if awake then
		-- Thin on purpose: this is a guardian, not the Mythic. Pyrelotus owns
		-- the dense aura and should keep owning it.
		local att = Instance.new("Attachment")
		att.Name = "ForgeAttachment"
		att.Parent = core
		local em = Instance.new("ParticleEmitter")
		em.Name = "Forge"
		em.Color = ColorSequence.new(C.EmberPale, C.EmberDeep)
		em.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15 * SCALE),
			NumberSequenceKeypoint.new(0.4, 0.58 * SCALE),
			NumberSequenceKeypoint.new(1, 0),
		})
		em.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		em.Lifetime = NumberRange.new(1.2, 2.0)
		em.Rate = 16
		em.Speed = NumberRange.new(1.0 * SCALE, 2.2 * SCALE)
		em.Drag = 1.4
		em.Acceleration = Vector3.new(0, 2.8 * SCALE, 0)
		em.SpreadAngle = Vector2.new(34, 34)
		em.LightEmission = 1
		em.LightInfluence = 0
		em.Parent = att
	end

	--==========================================================================
	-- THE SEVEN SOCKETS
	--==========================================================================
	-- Authored against the UNSCALED skeleton and grown by the same rule the
	-- parts were, so a socket cannot drift off the joint it names when SCALE
	-- changes. Getting this wrong is silent: the geometry would look right and
	-- the rig would bend in the wrong place.
	local jawLocal = at:ToObjectSpace(headCf * CFrame.new(0, -0.9, 0.5))
	local sockets = {
		{ "RootJoint", at * scaled(CFrame.new(rootPos), SCALE) },
		{ "Neck", at * scaled(CFrame.new(neckA), SCALE) },
		{ "JawJoint", at * scaled(jawLocal, SCALE) },
		{ "LeftShoulder", at * scaled(CFrame.new(-3.35, SHOULDER.Y, SHOULDER.Z - 0.2), SCALE) },
		{ "RightShoulder", at * scaled(CFrame.new(3.65, SHOULDER.Y, SHOULDER.Z - 0.2), SCALE) },
		{ "LeftHip", at * scaled(CFrame.new(-2.0, HIP.Y - 0.2, HIP.Z), SCALE) },
		{ "RightHip", at * scaled(CFrame.new(2.0, HIP.Y - 0.2, HIP.Z), SCALE) },
	}
	for _, s in ipairs(sockets) do
		local a = Instance.new("Attachment")
		a.Name = s[1] :: string
		-- PARENT FIRST. WorldCFrame on an unparented Attachment is just its
		-- local CFrame, so setting it before parenting stored the world value
		-- as local and then the root part's own transform was applied on top,
		-- putting every socket about twice as far out as it belonged -- 15 to
		-- 23 studs from the joint it names. Nothing looks wrong in the viewport
		-- when this happens, because Attachments do not render; it only shows
		-- up as a rig bending in the wrong place much later.
		a.Parent = root
		a.WorldCFrame = s[2] :: CFrame
	end
	m:SetAttribute("Seams", table.concat({
		"RootJoint", "Neck", "JawJoint", "LeftShoulder",
		"RightShoulder", "LeftHip", "RightHip",
	}, ","))

	return m
end

--==============================================================================
-- THE RIG
--==============================================================================
local function weldTo(anchor: BasePart, piece: BasePart)
	if piece == anchor or piece.Parent == nil then
		return
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = piece
	w.Parent = anchor
end

--==============================================================================
-- BOTH JOINT FRAMES COME FROM ONE SOCKET
--
-- C0 is the socket in Part0's space and C1 the same point in Part1's, both taken
-- from where the parts actually ended up. That is what makes the rest pose the
-- AUTHORED pose: ParentAnim composes onto C0, so a joint that starts wrong stays
-- wrong for the whole cycle and no amount of animation fixes it.
--==============================================================================
local function socketMotor(name: string, part0: BasePart, part1: BasePart,
	socket: CFrame): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(socket)
	m.C1 = part1.CFrame:ToObjectSpace(socket)
	m.Parent = part0
	return m
end

--==============================================================================
-- WHICH PARTS RIDE WHICH SEAM
--
-- Prefix rules, not a member list. Every limb part is already tagged L or R by
-- the builder, and the head and jaw groups are named for what they are, so the
-- rule reads the same way the geometry does -- and a part added later lands on
-- the right bone instead of rigid on the torso.
--
-- ORDER MATTERS: the jaw group is tested before the head group, because Chin
-- and Tooth belong to the jaw and would otherwise be swallowed by the head.
--==============================================================================
local GROUPS: { { seam: string, driver: string, part0: string, prefixes: { string } } } = {
	{ seam = "Neck", driver = "Skull", part0 = "Torso",
		prefixes = { "Neck1", "Neck2", "BrowRidge", "Cheek", "Eye", "Horn",
			"Nostrils", "Throat" } },
	{ seam = "JawJoint", driver = "LowerJaw", part0 = "Skull",
		prefixes = { "Chin", "Tooth" } },
	{ seam = "LeftShoulder", driver = "UpperArmL", part0 = "Torso",
		prefixes = { "ShoulderL", "AshMantleL", "ForearmL", "ForearmPlateL",
			"FistL", "KnuckleL", "FissureArmL" } },
	{ seam = "RightShoulder", driver = "UpperArmR", part0 = "Torso",
		prefixes = { "ShoulderR", "AshMantleR", "ForearmR", "ForearmPlateR",
			"FistR", "KnuckleR", "FissureArmR" } },
	{ seam = "LeftHip", driver = "ThighL", part0 = "Torso",
		prefixes = { "HockL", "ShinL", "FootL", "FissureLegL" } },
	{ seam = "RightHip", driver = "ThighR", part0 = "Torso",
		prefixes = { "HockR", "ShinR", "FootR", "FissureLegR" } },
}

--==============================================================================
function ForgemawModel.Build(cf: CFrame, height: number, parent: Instance): Model
	local model = buildGeometry(parent, cf)
	model:SetAttribute("Species", "forgemaw")
	model:SetAttribute("RigSeams",
		"Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip")

	--==========================================================================
	-- MEASURE, THEN CONFORM
	--
	-- The true silhouette height is the highest of the eight ROTATED corners of
	-- every part, not an axis-aligned half-extent: most of this animal is
	-- rotated and the cheap measurement over-reads a lunging pose badly.
	--==========================================================================
	local authored = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local corner = (d.CFrame
							* CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						authored = math.max(authored, corner.Y - cf.Position.Y)
					end
				end
			end
		end
	end
	local s = if authored > 0.001 then height / authored else 1
	model:SetAttribute("AuthoredHeight", authored)

	--== GROW. One pass, parts and sockets together, so a socket cannot drift
	--== off the joint it names.
	if math.abs(s - 1) > 1e-6 then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = cf * scaled(cf:ToObjectSpace(d.CFrame), s)
				d.Size = d.Size * s
			elseif d:IsA("Attachment") then
				d.WorldCFrame = cf * scaled(cf:ToObjectSpace(d.WorldCFrame), s)
			elseif d:IsA("PointLight") then
				d.Range = d.Range * s
			end
		end
	end

	--== THE PARTS THE RIG NEEDS ==--
	local built: { [string]: BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			built[d.Name] = d
		end
	end

	local root = built.HumanoidRootPart
	local torso = built.Torso
	if not (root and torso) then
		warn("[Seed/ForgemawModel] approved geometry has no "
			.. (if not root then "HumanoidRootPart" else "Torso")
			.. "; rig abandoned")
		return model
	end

	--==========================================================================
	-- THE ROOT IS THE ONE PART WITH MASS, AND THE TORSO THE ONE COLLIDER
	--
	-- Same call the other three guardians make, for the same reason: a guardian
	-- with a hundred collidable parts catches on every fence post and pod in the
	-- biome. One intentional collider, and everything else is silhouette.
	--==========================================================================
	root.Transparency = 1
	root.Massless = false
	root.CanCollide = false
	root.Size = ROOT_SIZE * s
	model.PrimaryPart = root
	torso.CanCollide = true

	--==========================================================================
	-- ROOTJOINT FIRST, SOCKETED AT THE MODEL ORIGIN
	--
	-- Not at the torso centre: a whole-body settle is a transform about the
	-- point the creature stands on, and socketing it anywhere else means the
	-- sleep pose has to be re-derived.
	--==========================================================================
	socketMotor("RootJoint", root, torso, cf)

	local claimed: { [BasePart]: boolean } = { [torso] = true, [root] = true }
	local madeSeams = 0
	for _, g in ipairs(GROUPS) do
		local part0 = built[g.part0]
		local driver = built[g.driver]
		if part0 and driver then
			-- The socket the mockup already declared for this seam, if it left
			-- one; otherwise the driver's own origin, which is what `motor`
			-- would have used anyway.
			local att = root:FindFirstChild(g.seam)
			local socket = if att and att:IsA("Attachment")
				then att.WorldCFrame
				else driver.CFrame
			socketMotor(g.seam, part0, driver, socket)
			claimed[driver] = true
			madeSeams += 1
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") and not claimed[d] then
					for _, prefix in ipairs(g.prefixes) do
						if d.Name:sub(1, #prefix) == prefix then
							weldTo(driver, d)
							claimed[d] = true
							break
						end
					end
				end
			end
		else
			warn(string.format(
				"[Seed/ForgemawModel] seam %q wants %s -> %s and one is missing",
				g.seam, g.part0, g.driver))
		end
	end

	-- Everything the rules did not claim rides the torso. Welding the remainder
	-- rather than listing it means a part added to the approved set later
	-- arrives rigid on the body instead of floating at the world origin.
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not claimed[d] then
			weldTo(torso, d)
		end
	end

	--==========================================================================
	-- THE HUMANOID
	--
	-- HipHeight is what holds the rig off the floor. Every part is
	-- CanCollide = false except the torso, so with no HipHeight the Humanoid
	-- sinks until that one collider rests on the ground and the legs bury.
	--
	-- WalkSpeed stays 0. NestService sets it when the nest wakes; a guardian
	-- that spawns able to run is one that eventually will.
	--==========================================================================
	local rootY = root.CFrame.Position.Y - cf.Position.Y
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = math.max(0, rootY - ROOT_SIZE.Y * 0.5 * s)
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	model:SetAttribute("RigScale", s)
	CollectionService:AddTag(model, GameConfig.Tags.NestParent)

	--==========================================================================
	-- COUNTED, NOT ASSUMED
	--
	-- This file is a transcription of approved art. A transcription that
	-- silently drops a toe is the kind of thing nobody notices until the
	-- silhouette looks subtly wrong weeks later.
	--==========================================================================
	local count = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			count += 1
		end
	end
	model:SetAttribute("MeasuredPartCount", count)
	if madeSeams ~= #GROUPS then
		warn(("[Seed/ForgemawModel] expected %d seams, made %d")
			:format(#GROUPS, madeSeams))
	end

	return model
end

return ForgemawModel
