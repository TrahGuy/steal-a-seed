--!strict
-- Steal a Seed :: ParentModel
--
-- The nest guardian, built to the orthographic sheet in
-- KB/biome1-parent-ortho.png. A hunched, fanged, mossy brute that sleeps beside
-- its pods until one is taken.
--
-- NOT a *Service. Geometry only, like CreatureModel and HubFairy.
--
--==============================================================================
-- IT HAS A HUMANOID, AND THAT IS THE POINT
--
-- The little creatures are anchored models that never move, which is what made
-- 72 of them affordable. This is the opposite and deliberately so: there are a
-- handful of parents in a server, they CHASE, and a chase has to be
-- server-simulated or every player sees the monster somewhere different.
--
-- So it is a real Humanoid on real legs, and its WalkSpeed is a balance number
-- rather than a decoration. That is the whole gate: the parent's speed is what
-- you must out-run, your speed comes off the treadmill, and the deeper biomes
-- hold faster parents. No abstract boundary check needed -- the monster IS the
-- check, and being too slow is something you feel rather than read.
--
--==============================================================================
-- JOINTS ONLY WHERE SOMETHING MOVES
--
-- Six Motor6Ds: neck, jaw, two shoulders, two hips. Everything else is welded
-- solid. Same rule the fairy taught -- the SERVER owns where it is standing,
-- each CLIENT owns what its limbs are doing, and the two never write the same
-- property.
--
-- The jaw is a joint because the snap is the whole character. A monster that
-- charges you with a closed mouth is a shrub in a hurry.
--
-- IF THE BLENDER MESH REPLACES THIS, keep those six bone names and everything
-- that drives them keeps working. Only this file changes.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ParentModel = {}

local BramblebackModel = require(script.Parent:WaitForChild("BramblebackModel"))
local MiremawModel = require(script.Parent:WaitForChild("MiremawModel"))
local ForgemawModel = require(script.Parent:WaitForChild("ForgemawModel"))
local AstralmawModel = require(script.Parent:WaitForChild("AstralmawModel"))

-- Sampled from the sheet.
local BARK = Color3.fromRGB(96, 76, 54)
local BARK_DARK = Color3.fromRGB(68, 54, 40)
local FLESH = Color3.fromRGB(140, 158, 78)
local FLESH_LIT = Color3.fromRGB(170, 184, 96)
local MANE = Color3.fromRGB(84, 116, 56)
local MANE_DARK = Color3.fromRGB(62, 90, 44)
local THORN = Color3.fromRGB(206, 146, 128)
local TOOTH = Color3.fromRGB(244, 240, 224)
local EYE = Color3.fromRGB(226, 108, 104)
local CLAW = Color3.fromRGB(178, 192, 116)

local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

type Opts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	studs: boolean?,
	transparency: number?,
}

local function part(o: Opts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Shape = o.shape or Enum.PartType.Block
	p.Transparency = o.transparency or 0
	-- UNANCHORED, unlike everything else this project builds. It walks, so the
	-- Humanoid owns its physics.
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	local studded = o.studs ~= false
	p.Material = if studded then Enum.Material.Plastic else Enum.Material.SmoothPlastic
	local surface = if studded then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	for _, face in ipairs(STUD_FACES) do
		(p :: any)[face] = surface
	end
	p.Parent = o.parent
	return p
end

local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3,
	parent: Instance): BasePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	for _, face in ipairs(STUD_FACES) do
		pcall(function()
			(p :: any)[face] = Enum.SurfaceType.Studs
		end)
	end
	p.Parent = parent
	return p
end

-- Welds for anything that never moves on its own. A joint you never drive is a
-- joint somebody later assumes is animated.
local function weldTo(anchor: BasePart, piece: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = piece
	w.Parent = anchor
end

--==============================================================================
-- THE SEVENTH SEAM: RootJoint
--
-- Part0 = HumanoidRootPart, Part1 = Torso, and its socket is the MODEL ORIGIN
-- -- not the torso's centre. That is the whole trick: the approved sleep pose
-- was authored as a transform of the creature about the point it stands on, so
-- putting the socket anywhere else would need the pose re-derived. With the
-- socket at the origin, the preview's body CFrame drops in unchanged.
--
--   C0 = root.CFrame:ToObjectSpace(socket)
--   C1 = torso.CFrame:ToObjectSpace(socket)
--
-- Both derived from the parts' built positions rather than written as
-- literals, so they follow the rig if it ever moves and they scale for free.
--
-- IT REPLACES A WELD. Torso used to be welded rigid to the root; a part cannot
-- be welded and motored at once without the two fighting over it.
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

local function motor(name: string, part0: BasePart, part1: BasePart, c0: CFrame): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = c0
	m.C1 = CFrame.new()
	m.Parent = part0
	return m
end

--==============================================================================
-- BUILD
--
-- `cf` is where its FEET go, matching the contract CreatureModel uses: every
-- builder in this project takes the base, never the centre.
--
--==============================================================================
-- PROPORTIONS ARE MEASURED OFF THE ORTHOGRAPHIC SHEET, NOT GUESSED
--
-- Fractions of total height, feet at 0, mane tip at 1:
--
--     0.00 - 0.33   legs, short and thick, wide stance
--     0.33 - 0.57   torso: bark trunk under green leaf plates
--     0.56          shoulders
--     0.56 - 0.20   arms, hanging nearly to the knee
--     0.58 - 0.83   head, jutting forward
--     0.68 - 1.00   mane
--
-- THE LEGS ARE ONLY A THIRD OF IT, and that one number is what makes the
-- silhouette squat and heavy rather than humanoid. Both earlier attempts made
-- them half and got a man in a costume.
--==============================================================================
--==============================================================================
-- ONE PARENT PER BIOME, DISPATCHED HERE
--
-- `biomeId` used to do nothing but name the model, so every biome raised THIS
-- creature -- a mossy bark ogre sampled off KB/biome1-parent-ortho.png, standing
-- on Dustbowl sand in Greenhollow green. It was only ever Greenhollow's.
--
-- Brambleback is biome 2's, approved and locked separately, and it is big
-- enough to deserve its own file. Everything below this line is still
-- Greenhollow's and should stay that way; biomes 3-5 join the table when they
-- have art, and until then they fall through to the brute, which is the honest
-- placeholder.
--
-- NestService gates on species, not on this: a biome with no entries in
-- SeedData raises no nest at all. So adding a biome's species is what turns its
-- nest ON -- and if the parent is not dispatched here first, that nest gets a
-- Greenhollow monster.
--==============================================================================
local BY_BIOME: { [string]: (CFrame, number, Instance) -> Model } = {
	dustbowl = BramblebackModel.Build,
	tanglemire = MiremawModel.Build,
	emberroot = ForgemawModel.Build,
	starbloom = AstralmawModel.Build,
}

function ParentModel.Build(cf: CFrame, height: number, biomeId: string, parent: Instance): Model
	local specific = BY_BIOME[biomeId]
	if specific then
		return specific(cf, height, parent)
	end
	local H = height
	local model = Instance.new("Model")
	model.Name = "Parent_" .. biomeId
	model:SetAttribute("BiomeId", biomeId)
	model:SetAttribute("Asleep", true)
	model.Parent = parent

	--== ROOT ==--
	local root = part({
		name = "HumanoidRootPart",
		size = Vector3.new(H * 0.32, H * 0.25, H * 0.24),
		cframe = cf * CFrame.new(0, H * 0.45, 0),
		color = BARK, transparency = 1, studs = false, parent = model,
	})
	model.PrimaryPart = root

	--== TORSO & JAGGED MOSS-BARK CARAPACE ==--
	local torsoY = H * 0.46
	local torso = part({
		name = "Torso",
		size = Vector3.new(H * 0.34, H * 0.28, H * 0.26),
		cframe = cf * CFrame.new(0, torsoY, 0) * CFrame.Angles(math.rad(-6), 0, 0),
		color = BARK_DARK, parent = model,
	})
	socketMotor("RootJoint", root, torso, cf)

	-- Spiked 3-Tier Chest & Abdominal Plates
	weldTo(torso, part({
		name = "ChestPlateUpper",
		size = Vector3.new(H * 0.25, H * 0.12, H * 0.08),
		cframe = cf * CFrame.new(0, torsoY + H * 0.08, -H * 0.12) * CFrame.Angles(math.rad(-8), 0, 0),
		color = FLESH, parent = model,
	}))
	weldTo(torso, part({
		name = "ChestPlateMid",
		size = Vector3.new(H * 0.21, H * 0.10, H * 0.07),
		cframe = cf * CFrame.new(0, torsoY - H * 0.01, -H * 0.13) * CFrame.Angles(math.rad(-4), 0, 0),
		color = FLESH_LIT, parent = model,
	}))
	weldTo(torso, part({
		name = "AbPlate",
		size = Vector3.new(H * 0.16, H * 0.09, H * 0.06),
		cframe = cf * CFrame.new(0, torsoY - H * 0.09, -H * 0.12) * CFrame.Angles(math.rad(4), 0, 0),
		color = FLESH, parent = model,
	}))

	-- Jagged Lateral Bark Ribs
	for _, s in ipairs({ -1, 1 }) do
		for r = 0, 2 do
			weldTo(torso, wedge("BarkRib" .. r .. "_" .. s,
				Vector3.new(H * 0.04, H * 0.08, H * 0.09),
				cf * CFrame.new(s * H * 0.16, torsoY + H * (0.07 - r * 0.07), -H * 0.07)
					* CFrame.Angles(0, (s < 0 and 0 or math.pi), s * math.rad(-18)),
				BARK, model))
		end
	end

	-- 4 Layered Dorsal Spine Plates
	for i = 0, 3 do
		weldTo(torso, part({
			name = "BackPlate" .. i,
			size = Vector3.new(H * (0.28 - i * 0.045), H * 0.085, H * 0.06),
			cframe = cf * CFrame.new(0, torsoY + H * (0.12 - i * 0.08), H * 0.12) * CFrame.Angles(math.rad(-12), 0, 0),
			color = if i % 2 == 0 then MANE else MANE_DARK, parent = model,
		}))
		weldTo(torso, wedge("SpinalThorn" .. i,
			Vector3.new(H * 0.035, H * 0.09, H * 0.035),
			cf * CFrame.new(0, torsoY + H * (0.16 - i * 0.08), H * 0.16) * CFrame.Angles(math.rad(-22), 0, 0),
			THORN, model))
	end

	--== LEGS & ROOT CLAW TALONS ==--
	for _, side in ipairs({ -1, 1 }) do
		local legName = if side < 0 then "LeftLeg" else "RightLeg"
		local hipX = side * H * 0.12
		local leg = part({
			name = legName,
			size = Vector3.new(H * 0.15, H * 0.22, H * 0.16),
			cframe = cf * CFrame.new(hipX, H * 0.24, 0) * CFrame.Angles(math.rad(6), 0, side * math.rad(-6)),
			color = BARK, parent = model,
		})
		motor(if side < 0 then "LeftHip" else "RightHip", torso, leg,
			CFrame.new(hipX, -H * 0.22, 0))

		weldTo(leg, part({
			name = "ThighArmor",
			size = Vector3.new(H * 0.12, H * 0.15, H * 0.06),
			cframe = cf * CFrame.new(hipX, H * 0.26, -H * 0.08) * CFrame.Angles(math.rad(8), 0, 0),
			color = FLESH, parent = model,
		}))
		weldTo(leg, part({
			name = "Shin",
			size = Vector3.new(H * 0.14, H * 0.16, H * 0.15),
			cframe = cf * CFrame.new(hipX + side * H * 0.015, H * 0.10, -H * 0.01),
			color = BARK_DARK, parent = model,
		}))
		-- 4 Splayed Root Claws per Foot
		for i = 1, 4 do
			local toeX = hipX + (i - 2.5) * H * 0.038
			weldTo(leg, wedge("RootClaw" .. i,
				Vector3.new(H * 0.035, H * 0.06, H * 0.13),
				cf * CFrame.new(toeX, H * 0.03, -H * 0.05)
					* CFrame.Angles(math.rad(-14), (i - 2.5) * math.rad(12), 0),
				CLAW, model))
		end
		weldTo(leg, part({
			name = "AnkleLeaf",
			size = Vector3.new(H * 0.12, H * 0.05, H * 0.06),
			cframe = cf * CFrame.new(hipX, H * 0.065, -H * 0.055) * CFrame.Angles(math.rad(28), 0, 0),
			color = MANE, parent = model,
		}))
	end

	--== MASSIVE SPIKED ARMS & FEROCIOUS ROOT CLAWS ==--
	local shoulderY = H * 0.58
	for _, side in ipairs({ -1, 1 }) do
		local armName = if side < 0 then "LeftArm" else "RightArm"
		local armX = side * H * 0.22
		local arm = part({
			name = armName,
			size = Vector3.new(H * 0.13, H * 0.20, H * 0.14),
			cframe = cf * CFrame.new(armX, shoulderY - H * 0.10, 0) * CFrame.Angles(math.rad(-8), 0, side * math.rad(-8)),
			color = FLESH, parent = model,
		})
		motor(if side < 0 then "LeftShoulder" else "RightShoulder", torso, arm,
			CFrame.new(armX, H * 0.04, 0))

		-- Heavy Forearm
		weldTo(arm, part({
			name = "Forearm",
			size = Vector3.new(H * 0.12, H * 0.22, H * 0.13),
			cframe = cf * CFrame.new(armX + side * H * 0.02, shoulderY - H * 0.28, -H * 0.03) * CFrame.Angles(math.rad(-14), 0, 0),
			color = FLESH_LIT, parent = model,
		}))

		-- Spiked Heavy Pauldron
		weldTo(torso, part({
			name = "Pauldron",
			size = Vector3.new(H * 0.16, H * 0.13, H * 0.17),
			cframe = cf * CFrame.new(armX, shoulderY + H * 0.03, 0) * CFrame.Angles(0, 0, side * math.rad(-16)),
			color = BARK_DARK, parent = model,
		}))
		for p = 1, 3 do
			weldTo(torso, wedge("PauldronThorn" .. p,
				Vector3.new(H * 0.035, H * 0.09, H * 0.035),
				cf * CFrame.new(armX + side * H * (0.06 + p * 0.02), shoulderY + H * (0.08 - p * 0.02), 0)
					* CFrame.Angles(0, 0, side * math.rad(65)),
				THORN, model))
		end

		-- Arm Thorns down triceps and outer forearm
		for i = 0, 5 do
			weldTo(arm, wedge("ArmThorn" .. i,
				Vector3.new(H * 0.03, H * 0.085, H * 0.03),
				cf * CFrame.new(armX + side * H * 0.075, shoulderY + H * 0.02 - i * H * 0.07, -H * 0.01)
					* CFrame.Angles(0, 0, side * math.rad(68)),
				THORN, model))
		end

		-- 4 Heavy Curved Root Claws per Hand
		for i = 1, 4 do
			local clawX = armX + side * H * 0.02 + (i - 2.5) * H * 0.034
			local clawLen = (i == 2 or i == 3) and 0.15 or 0.12
			weldTo(arm, wedge("Claw" .. i,
				Vector3.new(H * 0.032, H * clawLen, H * 0.042),
				cf * CFrame.new(clawX, shoulderY - H * 0.42, -H * 0.05)
					* CFrame.Angles(math.rad(24), 0, (i - 2.5) * math.rad(10)),
				CLAW, model))
		end
	end

	--== FIERCE PREDATORY SKULL & SNAPPING JAW ==--
	local headZ = -H * 0.10
	local skullY = H * 0.80
	local headW = H * 0.34

	local head = part({
		name = "Head",
		size = Vector3.new(headW, H * 0.18, H * 0.26),
		cframe = cf * CFrame.new(0, skullY, headZ) * CFrame.Angles(math.rad(-6), 0, 0),
		color = FLESH_LIT, parent = model,
	})
	motor("Neck", torso, head, CFrame.new(0, H * 0.34, headZ))

	-- Heavy Angled Brow Ridge
	weldTo(head, part({
		name = "Brow",
		size = Vector3.new(headW * 1.05, H * 0.055, H * 0.15),
		cframe = cf * CFrame.new(0, skullY + H * 0.07, headZ - H * 0.05) * CFrame.Angles(math.rad(-15), 0, 0),
		color = FLESH, parent = model,
	}))

	-- Glowing Predatory Red Neon Eyes with Ambient Light
	for _, side in ipairs({ -1, 1 }) do
		local eyePart = part({
			name = "Eye",
			size = Vector3.new(H * 0.065, H * 0.032, H * 0.028),
			cframe = cf * CFrame.new(side * H * 0.082, skullY + H * 0.028, headZ - H * 0.13) * CFrame.Angles(0, 0, side * math.rad(18)),
			color = EYE, material = Enum.Material.Neon, studs = false, parent = model,
		})
		weldTo(head, eyePart)
		local eyeLight = Instance.new("PointLight", eyePart)
		eyeLight.Color, eyeLight.Brightness, eyeLight.Range = EYE, 1.8, H * 0.6
	end

	-- Dark Cavernous Gullet
	local maw = part({
		name = "Maw",
		size = Vector3.new(headW * 0.85, H * 0.09, H * 0.16),
		cframe = cf * CFrame.new(0, skullY - H * 0.095, headZ - H * 0.03),
		color = Color3.fromRGB(80, 24, 28), studs = false, parent = model,
	})
	weldTo(head, maw)

	-- Articulated Fanged Lower Jaw
	local jaw = part({
		name = "Jaw",
		size = Vector3.new(headW * 0.92, H * 0.085, H * 0.24),
		cframe = cf * CFrame.new(0, skullY - H * 0.16, headZ + H * 0.01),
		color = FLESH, parent = model,
	})
	motor("JawJoint", head, jaw, CFrame.new(0, -H * 0.16, H * 0.08))

	-- 14 Interlocking Serrated Fangs with Oversized Sabre Tusks
	for i = 1, 7 do
		local tx = (i - 4) * H * 0.044
		local bigTusk = (i == 2 or i == 6)
		local tLen = bigTusk and 0.075 or 0.048
		weldTo(head, wedge("UpperTooth" .. i,
			Vector3.new(H * 0.032, H * tLen, H * 0.032),
			cf * CFrame.new(tx, skullY - H * 0.078, headZ - H * 0.10) * CFrame.Angles(math.pi, 0, 0),
			TOOTH, model))
		weldTo(jaw, wedge("LowerTooth" .. i,
			Vector3.new(H * 0.032, H * tLen, H * 0.032),
			cf * CFrame.new(tx, skullY - H * 0.125, headZ - H * 0.095),
			TOOTH, model))
	end

	-- Radiating Cheek Thorns
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 2 do
			weldTo(head, wedge("CheekSpike" .. i,
				Vector3.new(H * 0.03, H * 0.08, H * 0.03),
				cf * CFrame.new(side * H * 0.17, skullY + H * 0.035 - i * H * 0.055, headZ - H * 0.03)
					* CFrame.Angles(0, 0, side * math.rad(72)),
				THORN, model))
		end
	end

	--== 3-TIER DENSE BRIAR MANE ==--
	local maneOrigin = cf * CFrame.new(0, skullY + H * 0.02, headZ + H * 0.06)
	for _, ring in ipairs({
		{ count = 9, pitch = 68, len = 0.34, spread = 95, out = 0.08 },
		{ count = 11, pitch = 35, len = 0.30, spread = 125, out = 0.12 },
		{ count = 9, pitch = 10, len = 0.26, spread = 140, out = 0.15 },
	}) do
		for i = 1, ring.count do
			local t = (i - 1) / (ring.count - 1)
			local yaw = (t - 0.5) * 2 * ring.spread
			local reach = 1 - 0.24 * math.abs((t - 0.5) * 2)
			local len = H * ring.len * reach
			weldTo(head, part({
				name = "ManeLeaf",
				size = Vector3.new(H * 0.075, len, H * 0.048),
				cframe = maneOrigin
					* CFrame.Angles(0, math.rad(yaw), 0)
					* CFrame.new(0, 0, H * ring.out)
					* CFrame.Angles(math.rad(90 - ring.pitch), 0, 0)
					* CFrame.new(0, len * 0.5, 0),
				color = if i % 2 == 0 then MANE else MANE_DARK,
				parent = model,
			}))
		end
	end

	--== HUMANOID ==--
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- ASLEEP. WalkSpeed is set by the service when it wakes, never here: a
	-- monster that spawns already able to run is a monster that will one day run
	-- before anything told it to.
	humanoid.WalkSpeed = 0
	-- AUTOROTATE ON. It was off, with NestService writing root.CFrame every tick
	-- to face the target -- which only ran while CHASING, so the walk home was
	-- done facing backwards. It also meant the server teleporting a physics
	-- assembly eight times a second, fighting the very Humanoid moving it.
	-- Letting the Humanoid turn itself fixes the moonwalk and removes the fight.
	humanoid.AutoRotate = true
	humanoid.HipHeight = H * 0.33
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	--==========================================================================
	-- THE HUMANOIDROOTPART MUST HAVE MASS, OR AutoRotate DOES NOTHING
	--
	-- Every part here is Massless so the rig cannot out-weigh its own Humanoid
	-- -- and the root was too, which quietly made the TORSO the assembly root,
	-- because a massless part cannot root an assembly. Roblox rotates an
	-- assembly about its root, so the Humanoid dutifully turned a
	-- HumanoidRootPart that was not steering anything and the creature walked
	-- home backwards with AutoRotate switched on.
	--
	-- Verified: Humanoid.RootPart said HumanoidRootPart while
	-- root.AssemblyRootPart said Torso. Those disagreeing is the bug.
	--==========================================================================
	root.Massless = false

	-- One collidable part, so it has physical presence without ten colliders
	-- catching on scenery. Massless now: the root carries the weight.
	torso.CanCollide = true
	torso.Massless = true

	CollectionService:AddTag(model, GameConfig.Tags.NestParent)
	return model
end

return ParentModel
