--!strict
-- Steal a Seed :: ParentModel
--
-- The nest guardian, built to KB/biome1-parent.png. A hunched, fanged, mossy
-- brute that sleeps beside its pods until one is taken.
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
-- So it is a real Humanoid on real legs, and its WalkSpeed is a game balance
-- number rather than a decoration. That is the whole gate: the parent's speed
-- is what you must out-run, your speed comes off the treadmill, and the deeper
-- biomes hold faster parents. No abstract boundary check needed -- the monster
-- IS the check, and being too slow is something you feel rather than read.
--
--==============================================================================
-- JOINTS ONLY WHERE SOMETHING MOVES
--
-- Six Motor6Ds: head, jaw, two arms, two legs. Everything else is welded solid.
-- The rule is the same one the fairy taught -- the SERVER owns where it is
-- standing, each CLIENT owns what its limbs are doing, and the two never write
-- the same property.
--
-- The jaw is a joint because the snap is the whole character. A monster that
-- charges you with a closed mouth is a shrub in a hurry.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ParentModel = {}

-- Sampled from the reference sheet.
local BARK = Color3.fromRGB(84, 66, 50)
local BARK_DARK = Color3.fromRGB(62, 48, 38)
local FLESH = Color3.fromRGB(138, 154, 82)
local FLESH_LIT = Color3.fromRGB(164, 178, 98)
local MANE = Color3.fromRGB(88, 118, 60)
local MANE_DARK = Color3.fromRGB(68, 94, 48)
local THORN = Color3.fromRGB(214, 148, 140)
local TOOTH = Color3.fromRGB(242, 238, 220)
local EYE = Color3.fromRGB(224, 104, 104)
local CLAW = Color3.fromRGB(180, 192, 124)

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
	-- Humanoid needs to own its physics.
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

-- Solid attachment. Welds rather than Motor6Ds for everything that never moves
-- on its own -- a joint you never drive is a joint somebody later assumes is
-- animated.
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
--==============================================================================
function ParentModel.Build(cf: CFrame, height: number, biomeId: string, parent: Instance): Model
	local H = height
	local model = Instance.new("Model")
	model.Name = "Parent_" .. biomeId
	model:SetAttribute("BiomeId", biomeId)
	model:SetAttribute("Asleep", true)
	model.Parent = parent

	--== ROOT ==--
	-- Invisible, and the only part the Humanoid really cares about.
	local root = part({
		name = "HumanoidRootPart",
		size = Vector3.new(H * 0.30, H * 0.24, H * 0.22),
		cframe = cf * CFrame.new(0, H * 0.46, 0),
		color = BARK, transparency = 1, studs = false, parent = model,
	})
	model.PrimaryPart = root

	--==========================================================================
	-- PROPORTIONS COME OFF THE SHEET, AND THE SHEET IS TOP-HEAVY
	--
	-- First attempt built a normal humanoid: big torso, small head on top. It
	-- came out as a stack of green boxes with a pea for a face, because the
	-- reference is nothing like that. On the sheet the HEAD AND MANE ARE THE TOP
	-- THIRD of the creature and nearly as wide as the body, the mouth is open,
	-- and the legs are short. The silhouette is a triangle standing on stumps.
	--
	--   0.00 - 0.10   splayed root feet
	--   0.06 - 0.36   short thick legs, wide stance
	--   0.32 - 0.62   torso, bark with a mossy chest
	--   0.58 - 0.24   arms, hanging past the knee
	--   0.60 - 0.92   HEAD: lower jaw, open maw, heavy skull
	--   0.72 - 1.05   mane, fanning back and up
	--==========================================================================

	--== TORSO ==--
	local torsoY = H * 0.47
	local torso = part({
		name = "Torso",
		size = Vector3.new(H * 0.34, H * 0.30, H * 0.25),
		cframe = cf * CFrame.new(0, torsoY, 0),
		color = BARK, parent = model,
	})
	weldTo(root, torso)
	weldTo(torso, part({
		name = "Chest",
		size = Vector3.new(H * 0.19, H * 0.14, H * 0.09),
		cframe = cf * CFrame.new(0, torsoY + H * 0.04, -H * 0.11),
		color = FLESH, parent = model,
	}))
	weldTo(torso, part({
		name = "Hump",
		size = Vector3.new(H * 0.30, H * 0.16, H * 0.14),
		cframe = cf * CFrame.new(0, torsoY + H * 0.11, H * 0.06),
		color = MANE_DARK, parent = model,
	}))

	--== LEGS ==--
	for _, side in ipairs({ -1, 1 }) do
		local leg = part({
			name = if side < 0 then "LeftLeg" else "RightLeg",
			size = Vector3.new(H * 0.15, H * 0.30, H * 0.16),
			cframe = cf * CFrame.new(side * H * 0.13, H * 0.21, 0),
			color = BARK, parent = model,
		})
		motor(if side < 0 then "LeftHip" else "RightHip", torso, leg,
			CFrame.new(side * H * 0.13, -H * 0.26, 0))
		for i = -1, 1 do
			weldTo(leg, part({
				name = "Root",
				size = Vector3.new(H * 0.06, H * 0.08, H * 0.15),
				cframe = cf
					* CFrame.new(side * H * 0.13 + i * H * 0.055, H * 0.04, -H * 0.04)
					* CFrame.Angles(math.rad(-12), i * math.rad(20), 0),
				color = BARK_DARK, parent = model,
			}))
		end
	end

	--== ARMS ==--
	-- Upper arm plus a forearm angled forward, so they hang like the sheet's
	-- rather than lying flat against the body like sleeves.
	for _, side in ipairs({ -1, 1 }) do
		local shoulderY = H * 0.58
		local arm = part({
			name = if side < 0 then "LeftArm" else "RightArm",
			size = Vector3.new(H * 0.14, H * 0.22, H * 0.15),
			cframe = cf * CFrame.new(side * H * 0.24, shoulderY - H * 0.09, 0),
			color = FLESH, parent = model,
		})
		motor(if side < 0 then "LeftShoulder" else "RightShoulder", torso, arm,
			CFrame.new(side * H * 0.24, H * 0.02, 0))

		weldTo(arm, part({
			name = "Forearm",
			size = Vector3.new(H * 0.13, H * 0.20, H * 0.14),
			cframe = cf * CFrame.new(side * H * 0.25, shoulderY - H * 0.28, -H * 0.03)
				* CFrame.Angles(math.rad(-10), 0, 0),
			color = MANE, parent = model,
		}))

		weldTo(torso, part({
			name = "Pad",
			size = Vector3.new(H * 0.17, H * 0.13, H * 0.18),
			cframe = cf * CFrame.new(side * H * 0.24, shoulderY + H * 0.03, 0),
			color = FLESH_LIT, parent = model,
		}))
		for i = 0, 2 do
			weldTo(arm, part({
				name = "Thorn",
				size = Vector3.new(H * 0.04, H * 0.10, H * 0.04),
				cframe = cf
					* CFrame.new(side * H * 0.30, shoulderY + H * 0.04 - i * H * 0.11, 0)
					* CFrame.Angles(0, 0, side * math.rad(62)),
				color = THORN, parent = model,
			}))
		end
		for i = 0, 3 do
			weldTo(arm, part({
				name = "Claw",
				size = Vector3.new(H * 0.035, H * 0.13, H * 0.045),
				cframe = cf
					* CFrame.new(side * H * 0.25 + (i - 1.5) * H * 0.040,
						shoulderY - H * 0.44, -H * 0.06)
					* CFrame.Angles(math.rad(26), 0, (i - 1.5) * math.rad(10)),
				color = CLAW, parent = model,
			}))
		end
	end

	--== HEAD ==--
	-- Big, forward, and OPEN. The maw is built as a gap between a heavy skull
	-- and a hinged jaw, with a dark interior behind so it does not read as a
	-- hole punched through the model.
	-- HEAD HEIGHT IS LOAD-BEARING. At 0.82 the jaw bottom landed at 0.655H
	-- against a torso top of 0.62H -- overlapping it -- and the whole creature
	-- read as one green mass with a mouth in its chest. There has to be a
	-- visible gap of neck between the two.
	local headZ = -H * 0.10
	local skullY = H * 0.94
	local headW = H * 0.36

	local head = part({
		name = "Head",
		size = Vector3.new(headW, H * 0.20, H * 0.30),
		cframe = cf * CFrame.new(0, skullY, headZ),
		color = FLESH_LIT, parent = model,
	})
	motor("Neck", torso, head, CFrame.new(0, H * 0.47, headZ))

	weldTo(head, part({
		name = "Brow",
		size = Vector3.new(headW * 0.98, H * 0.05, H * 0.16),
		cframe = cf * CFrame.new(0, skullY + H * 0.08, headZ - H * 0.06)
			* CFrame.Angles(math.rad(-10), 0, 0),
		color = FLESH, parent = model,
	}))
	for _, side in ipairs({ -1, 1 }) do
		weldTo(head, part({
			name = "Eye",
			size = Vector3.new(H * 0.07, H * 0.028, H * 0.025),
			cframe = cf * CFrame.new(side * H * 0.08, skullY + H * 0.035, headZ - H * 0.145)
				* CFrame.Angles(0, 0, side * math.rad(14)),
			color = EYE, studs = false, parent = model,
		}))
	end

	-- The dark of the throat, filling the gap.
	weldTo(head, part({
		name = "Maw",
		size = Vector3.new(headW * 0.82, H * 0.10, H * 0.16),
		cframe = cf * CFrame.new(0, skullY - H * 0.12, headZ - H * 0.03),
		color = Color3.fromRGB(48, 30, 32), studs = false, parent = model,
	}))

	local jaw = part({
		name = "Jaw",
		size = Vector3.new(headW * 0.92, H * 0.09, H * 0.26),
		cframe = cf * CFrame.new(0, skullY - H * 0.20, headZ + H * 0.01),
		color = FLESH, parent = model,
	})
	motor("JawJoint", head, jaw, CFrame.new(0, -H * 0.20, H * 0.11))

	-- Teeth point INTO the gap from both sides: upper hang down, lower point up.
	for i = -2, 2 do
		local big = (i % 2 == 0)
		weldTo(head, wedge("Tooth",
			Vector3.new(H * 0.035, H * (big and 0.075 or 0.055), H * 0.035),
			cf * CFrame.new(i * H * 0.055, skullY - H * 0.10, headZ - H * 0.10)
				* CFrame.Angles(math.rad(180), 0, 0),
			TOOTH, model))
		weldTo(jaw, wedge("Tooth",
			Vector3.new(H * 0.035, H * (big and 0.055 or 0.075), H * 0.035),
			cf * CFrame.new(i * H * 0.055, skullY - H * 0.155, headZ - H * 0.10),
			TOOTH, model))
	end

	--== MANE ==--
	-- Sixteen long leaves fanned back and up from behind the skull. This is most
	-- of the silhouette and the only reason it reads as a plant rather than a
	-- bear -- the first pass made them a third this size and they vanished.
	for i = 1, 16 do
		local t = (i - 1) / 15
		local spread = (t - 0.5) * 2
		local reach = 1 - 0.30 * math.abs(spread)
		weldTo(head, part({
			name = "ManeLeaf",
			size = Vector3.new(H * 0.085, H * 0.42 * reach, H * 0.055),
			cframe = cf
				* CFrame.new(0, skullY + H * 0.04, headZ + H * 0.10)
				* CFrame.Angles(0, spread * math.rad(104), 0)
				* CFrame.new(0, H * 0.19 * reach, H * 0.12)
				* CFrame.Angles(math.rad(20 + 26 * math.abs(spread)), 0,
					spread * math.rad(16)),
			color = if i % 2 == 0 then MANE else MANE_DARK,
			parent = model,
		}))
	end

	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 1 do
			weldTo(head, part({
				name = "CheekSpike",
				size = Vector3.new(H * 0.035, H * 0.09, H * 0.035),
				cframe = cf
					* CFrame.new(side * H * 0.17, skullY - i * H * 0.09, headZ - H * 0.04)
					* CFrame.Angles(0, 0, side * math.rad(66)),
				color = THORN, parent = model,
			}))
		end
	end

	--== HUMANOID ==--
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- ASLEEP. WalkSpeed is set by the service when it wakes, not here -- a
	-- monster that spawns already able to run is a monster that will one day
	-- run before anything told it to.
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	humanoid.HipHeight = H * 0.34
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	-- It cannot be killed, shoved, or ragdolled by anything a player can do.
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	-- One collidable part, so it has physical presence without ten colliders
	-- catching on scenery.
	torso.CanCollide = true
	torso.Massless = false

	CollectionService:AddTag(model, GameConfig.Tags.NestParent)
	return model
end

return ParentModel
