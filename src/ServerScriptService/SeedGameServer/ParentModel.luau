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
		size = Vector3.new(H * 0.28, H * 0.22, H * 0.20),
		cframe = cf * CFrame.new(0, H * 0.45, 0),
		color = BARK, transparency = 1, studs = false, parent = model,
	})
	model.PrimaryPart = root

	--== TORSO ==--
	-- Green leaf plates over a bark trunk, which is the sheet's read: brown
	-- underneath, mossy armour laid on top of it.
	local torsoY = H * 0.45
	local torso = part({
		name = "Torso",
		size = Vector3.new(H * 0.30, H * 0.24, H * 0.22),
		cframe = cf * CFrame.new(0, torsoY, 0),
		color = BARK, parent = model,
	})
	weldTo(root, torso)
	weldTo(torso, part({
		name = "ChestPlate",
		size = Vector3.new(H * 0.20, H * 0.11, H * 0.07),
		cframe = cf * CFrame.new(0, torsoY + H * 0.06, -H * 0.10),
		color = FLESH, parent = model,
	}))
	weldTo(torso, part({
		name = "AbPlate",
		size = Vector3.new(H * 0.13, H * 0.10, H * 0.06),
		cframe = cf * CFrame.new(0, torsoY - H * 0.07, -H * 0.10),
		color = FLESH_LIT, parent = model,
	}))
	-- The back view is almost entirely leaf, so the back is armoured too.
	for i = 0, 2 do
		weldTo(torso, part({
			name = "BackPlate",
			size = Vector3.new(H * (0.24 - i * 0.04), H * 0.08, H * 0.05),
			cframe = cf * CFrame.new(0, torsoY + H * (0.08 - i * 0.08), H * 0.10),
			color = if i % 2 == 0 then MANE else MANE_DARK, parent = model,
		}))
	end

	--== LEGS ==--
	-- Thigh and shin as separate blocks with a plate over the thigh. One
	-- tapering column reads as a table leg.
	for _, side in ipairs({ -1, 1 }) do
		local leg = part({
			name = if side < 0 then "LeftLeg" else "RightLeg",
			size = Vector3.new(H * 0.13, H * 0.19, H * 0.14),
			cframe = cf * CFrame.new(side * H * 0.105, H * 0.235, 0),
			color = BARK, parent = model,
		})
		motor(if side < 0 then "LeftHip" else "RightHip", torso, leg,
			CFrame.new(side * H * 0.105, -H * 0.215, 0))
		weldTo(leg, part({
			name = "Shin",
			size = Vector3.new(H * 0.12, H * 0.14, H * 0.13),
			cframe = cf * CFrame.new(side * H * 0.105, H * 0.10, 0),
			color = BARK, parent = model,
		}))
		weldTo(leg, part({
			name = "ThighPlate",
			size = Vector3.new(H * 0.10, H * 0.12, H * 0.05),
			cframe = cf * CFrame.new(side * H * 0.105, H * 0.25, -H * 0.07),
			color = FLESH, parent = model,
		}))
		for i = -1, 1 do
			weldTo(leg, part({
				name = "RootClaw",
				size = Vector3.new(H * 0.05, H * 0.055, H * 0.11),
				cframe = cf
					* CFrame.new(side * H * 0.105 + i * H * 0.042, H * 0.028, -H * 0.03)
					* CFrame.Angles(math.rad(-10), i * math.rad(22), 0),
				color = BARK_DARK, parent = model,
			}))
		end
		weldTo(leg, part({
			name = "AnkleLeaf",
			size = Vector3.new(H * 0.11, H * 0.045, H * 0.055),
			cframe = cf * CFrame.new(side * H * 0.105, H * 0.062, -H * 0.045)
				* CFrame.Angles(math.rad(26), 0, 0),
			color = MANE, parent = model,
		}))
	end

	--== ARMS ==--
	-- Shoulder at 0.56, claws down at 0.20. On the sheet they nearly reach the
	-- knee, and that length is most of why it reads as a brute rather than a man.
	local shoulderY = H * 0.56
	for _, side in ipairs({ -1, 1 }) do
		local arm = part({
			name = if side < 0 then "LeftArm" else "RightArm",
			size = Vector3.new(H * 0.105, H * 0.17, H * 0.115),
			cframe = cf * CFrame.new(side * H * 0.195, shoulderY - H * 0.09, 0),
			color = FLESH, parent = model,
		})
		motor(if side < 0 then "LeftShoulder" else "RightShoulder", torso, arm,
			CFrame.new(side * H * 0.195, H * 0.02, 0))

		weldTo(arm, part({
			name = "Forearm",
			size = Vector3.new(H * 0.095, H * 0.17, H * 0.105),
			cframe = cf * CFrame.new(side * H * 0.205, shoulderY - H * 0.25, -H * 0.01),
			color = FLESH_LIT, parent = model,
		}))
		weldTo(torso, part({
			name = "Pad",
			size = Vector3.new(H * 0.13, H * 0.10, H * 0.14),
			cframe = cf * CFrame.new(side * H * 0.195, shoulderY + H * 0.025, 0),
			color = FLESH_LIT, parent = model,
		}))
		-- Thorns march down the shoulder and the outer forearm.
		for i = 0, 4 do
			weldTo(arm, part({
				name = "Thorn",
				size = Vector3.new(H * 0.028, H * 0.07, H * 0.028),
				cframe = cf
					* CFrame.new(side * H * 0.25, shoulderY + H * 0.035 - i * H * 0.075, 0)
					* CFrame.Angles(0, 0, side * math.rad(64)),
				color = THORN, parent = model,
			}))
		end
		for i = 0, 3 do
			weldTo(arm, part({
				name = "Claw",
				size = Vector3.new(H * 0.026, H * 0.10, H * 0.034),
				cframe = cf
					* CFrame.new(side * H * 0.205 + (i - 1.5) * H * 0.030,
						shoulderY - H * 0.38, -H * 0.02)
					* CFrame.Angles(math.rad(16), 0, (i - 1.5) * math.rad(8)),
				color = CLAW, parent = model,
			}))
		end
	end

	--== HEAD ==--
	-- SKULL HEIGHT IS LOAD-BEARING, and 0.735 was still a hair too low: the jaw
	-- bottom landed at 0.548H against a torso top of 0.570H and clipped into the
	-- chest. Pushing the head forward instead would need headZ past -0.225H to
	-- clear, which detaches it from the body entirely -- so it goes up, not out.
	--
	--     jaw bottom = skullY - 0.152 - 0.035, and must exceed 0.570.
	local headZ = -H * 0.08
	local skullY = H * 0.78
	local headW = H * 0.30

	local head = part({
		name = "Head",
		size = Vector3.new(headW, H * 0.15, H * 0.23),
		cframe = cf * CFrame.new(0, skullY, headZ),
		color = FLESH_LIT, parent = model,
	})
	motor("Neck", torso, head, CFrame.new(0, H * 0.33, headZ))

	weldTo(head, part({
		name = "Brow",
		size = Vector3.new(headW * 1.02, H * 0.045, H * 0.13),
		cframe = cf * CFrame.new(0, skullY + H * 0.058, headZ - H * 0.045)
			* CFrame.Angles(math.rad(-12), 0, 0),
		color = FLESH, parent = model,
	}))
	for _, side in ipairs({ -1, 1 }) do
		weldTo(head, part({
			name = "Eye",
			size = Vector3.new(H * 0.058, H * 0.026, H * 0.022),
			cframe = cf * CFrame.new(side * H * 0.068, skullY + H * 0.022, headZ - H * 0.113)
				* CFrame.Angles(0, 0, side * math.rad(15)),
			color = EYE, studs = false, parent = model,
		}))
	end
	-- The dark of the throat, so an open maw is not a hole through the model.
	weldTo(head, part({
		name = "Maw",
		size = Vector3.new(headW * 0.80, H * 0.075, H * 0.13),
		cframe = cf * CFrame.new(0, skullY - H * 0.092, headZ - H * 0.02),
		color = Color3.fromRGB(96, 44, 44), studs = false, parent = model,
	}))

	local jaw = part({
		name = "Jaw",
		size = Vector3.new(headW * 0.90, H * 0.07, H * 0.20),
		cframe = cf * CFrame.new(0, skullY - H * 0.152, headZ + H * 0.012),
		color = FLESH, parent = model,
	})
	motor("JawJoint", head, jaw, CFrame.new(0, -H * 0.152, H * 0.082))

	for i = -2, 2 do
		local big = (i % 2 == 0)
		weldTo(head, wedge("Tooth",
			Vector3.new(H * 0.030, H * (big and 0.058 or 0.042), H * 0.030),
			cf * CFrame.new(i * H * 0.046, skullY - H * 0.076, headZ - H * 0.082)
				* CFrame.Angles(math.rad(180), 0, 0),
			TOOTH, model))
		weldTo(jaw, wedge("Tooth",
			Vector3.new(H * 0.030, H * (big and 0.042 or 0.058), H * 0.030),
			cf * CFrame.new(i * H * 0.046, skullY - H * 0.120, headZ - H * 0.082),
			TOOTH, model))
	end
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 2 do
			weldTo(head, part({
				name = "CheekSpike",
				size = Vector3.new(H * 0.026, H * 0.065, H * 0.026),
				cframe = cf
					* CFrame.new(side * H * 0.145, skullY + H * 0.028 - i * H * 0.055,
						headZ - H * 0.028)
					* CFrame.Angles(0, 0, side * math.rad(70)),
				color = THORN, parent = model,
			}))
		end
	end

	--==========================================================================
	-- THE MANE
	--
	-- TWO RINGS ON A SPHERE, not a fan. Both earlier builds swept the leaves
	-- through one flat arc and produced a mohawk; the SIDE view shows a crest
	-- wrapping the whole back of the skull and carrying on down over the
	-- shoulders. It has to radiate in PITCH as well as in yaw.
	--
	-- This is most of the silhouette, and the only reason the thing reads as a
	-- plant rather than as a bear.
	--==========================================================================
	local maneOrigin = cf * CFrame.new(0, skullY + H * 0.02, headZ + H * 0.06)
	for _, ring in ipairs({
		{ count = 9, pitch = 62, len = 0.30, spread = 96, out = 0.09 },
		{ count = 11, pitch = 20, len = 0.26, spread = 130, out = 0.12 },
	}) do
		for i = 1, ring.count do
			local t = (i - 1) / (ring.count - 1)
			local yaw = (t - 0.5) * 2 * ring.spread
			local reach = 1 - 0.26 * math.abs((t - 0.5) * 2)
			local len = H * ring.len * reach
			weldTo(head, part({
				name = "ManeLeaf",
				size = Vector3.new(H * 0.070, len, H * 0.045),
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
