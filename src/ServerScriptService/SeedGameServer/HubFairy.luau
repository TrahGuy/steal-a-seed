--!strict
-- Steal a Seed :: HubFairy
--
-- Builds Marigold, the fairy who runs the market stall: a real R6 Humanoid with
-- wings, so she can WALK rather than hover.
--
-- Geometry only. `FairyService` walks her, `Ambience.client.luau` flutters her
-- wings and swings her limbs, and the three meet at one CollectionService tag.
--
-- NOT NAMED "*Service" ON PURPOSE, same as MapDecor: ServerMain auto-starts
-- every ModuleScript in this folder whose name ends in Service, and this is a
-- builder with no lifecycle.
--
--==============================================================================
-- A RIG BUILT FROM PARTS, NOT FROM A HUMANOIDDESCRIPTION
--
-- `Players:CreateHumanoidModelFromDescription` is the usual way to make an NPC
-- and it is the wrong one here:
--
--   * It is a WEB CALL. It needs API access enabled, it can fail, and it makes
--     the map build depend on Roblox being reachable.
--   * It carries asset ids -- hair, faces, packages -- that live in somebody's
--     account and can 404 or be moderated away.
--   * The previous project on this machine hit a real trap with it: a fresh
--     `HumanoidDescription` defaults every body colour to BLACK, and the
--     BodyColors object rides along inside a `:Clone()` and repaints the rig the
--     moment it is parented. Its crew rendered as silhouettes until somebody
--     worked out why.
--
-- Fourteen parts and six Motor6Ds is the whole rig. It is in git, it matches the
-- blocky studded look everything else is built in, and it cannot 404.
--
-- The ONE external reference is the face, and it is `rbxasset://` -- shipped
-- inside the Roblox client rather than uploaded to an account, so it is exactly
-- as available as the engine is.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local HubFairy = {}

HubFairy.Name = "Marigold"

local SKIN = Color3.fromRGB(255, 220, 186)
local DRESS = Color3.fromRGB(240, 112, 168)
local DRESS_DARK = Color3.fromRGB(206, 82, 138)
local HAIR = Color3.fromRGB(250, 200, 96)
local WING = Color3.fromRGB(206, 240, 252)

local function limb(model: Instance, name: string, size: Vector3, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- Nothing on her collides. She stands on the stall floor by Humanoid
	-- physics, and a shopkeeper you cannot body-block into her own counter is
	-- worth more than one you can.
	p.CanCollide = false
	p.Parent = model
	return p
end

local function motor(parent: BasePart, name: string, p0: BasePart, p1: BasePart,
	c0: CFrame, c1: CFrame): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = parent
	return m
end

local function weld(to: BasePart, p: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
end

--==============================================================================
-- BUILD
--
-- `pivot` is where she stands, at floor level: the caller passes the ground and
-- this lifts her the 3 studs an R6 root sits above its own feet.
--==============================================================================
function HubFairy.build(pivot: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = HubFairy.Name

	local stand = pivot * CFrame.new(0, 3, 0)

	--== THE R6 SKELETON ==--
	-- NAMES MATTER. The Humanoid finds its limbs by exact string -- "Left Arm"
	-- with a space, "HumanoidRootPart" without one -- and a rig with a typo in a
	-- part name is a rig that silently refuses to walk.
	local root = limb(model, "HumanoidRootPart", Vector3.new(2, 2, 1), SKIN)
	root.Transparency = 1
	root.CFrame = stand
	model.PrimaryPart = root

	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), DRESS)
	local head = limb(model, "Head", Vector3.new(2, 1, 1), SKIN)
	local rightArm = limb(model, "Right Arm", Vector3.new(1, 2, 1), SKIN)
	local leftArm = limb(model, "Left Arm", Vector3.new(1, 2, 1), SKIN)
	local rightLeg = limb(model, "Right Leg", Vector3.new(1, 2, 1), SKIN)
	local leftLeg = limb(model, "Left Leg", Vector3.new(1, 2, 1), SKIN)

	-- The classic head shape. A bare 2x1x1 block reads as a brick; the Head mesh
	-- is what makes it a head, and it ships with the engine.
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.DisplayName = HubFairy.Name
	humanoid.WalkSpeed = 5
	humanoid.JumpPower = 0
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	--== JOINTS ==--
	-- Standard R6 offsets. These are not adjustable taste: they are what the
	-- Humanoid expects an R6 rig to be, and a rig assembled with different ones
	-- walks with its arms inside its legs.
	local HALF = math.pi * 0.5
	motor(root, "RootJoint", root, torso,
		CFrame.Angles(-HALF, 0, math.pi), CFrame.Angles(-HALF, 0, math.pi))
	motor(torso, "Neck", torso, head,
		CFrame.new(0, 1, 0) * CFrame.Angles(-HALF, 0, math.pi),
		CFrame.new(0, -0.5, 0) * CFrame.Angles(-HALF, 0, math.pi))
	motor(torso, "Right Shoulder", torso, rightArm,
		CFrame.new(1, 0.5, 0) * CFrame.Angles(0, HALF, 0),
		CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, HALF, 0))
	motor(torso, "Left Shoulder", torso, leftArm,
		CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -HALF, 0),
		CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -HALF, 0))
	motor(torso, "Right Hip", torso, rightLeg,
		CFrame.new(1, -1, 0) * CFrame.Angles(0, HALF, 0),
		CFrame.new(0.5, 1, 0) * CFrame.Angles(0, HALF, 0))
	motor(torso, "Left Hip", torso, leftLeg,
		CFrame.new(-1, -1, 0) * CFrame.Angles(0, -HALF, 0),
		CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -HALF, 0))

	--== THE DRESS ==--
	-- Welded, not jointed. A skirt never animates, so a Motor6D would only be a
	-- joint the walk cycle has to remember not to touch.
	local skirt = limb(model, "Skirt", Vector3.new(2.4, 1.3, 1.6), DRESS_DARK)
	skirt.CFrame = stand * CFrame.new(0, -1.2, 0)
	weld(torso, skirt)

	local collar = limb(model, "Collar", Vector3.new(2.1, 0.35, 1.15), DRESS_DARK)
	collar.CFrame = stand * CFrame.new(0, 0.85, 0)
	weld(torso, collar)

	--== HAIR ==--
	-- A cap plus a fall down the back. The back piece is what stops the cap
	-- reading as a hat.
	--
	-- +Z IS BEHIND. A CFrame's local -Z is the direction it faces, so the
	-- obvious-looking negative offset puts hair over the face -- which is
	-- exactly what an earlier version of this fairy did.
	local hairTop = limb(model, "HairTop", Vector3.new(2.2, 0.8, 1.2), HAIR)
	hairTop.CFrame = stand * CFrame.new(0, 2.05, 0)
	local hairBack = limb(model, "HairBack", Vector3.new(1.9, 1.8, 0.6), HAIR)
	hairBack.CFrame = stand * CFrame.new(0, 1.15, 0.62)
	weld(head, hairTop)
	weld(head, hairBack)

	--== WINGS ==--
	-- MOTOR6D, NOT WELDS, and that is the whole reason they can flutter. A
	-- WeldConstraint is rigid, and a client that moves the part fights it. A
	-- Motor6D has a `Transform` field designed to be written every frame, and a
	-- Transform written on a client is LOCAL ONLY.
	--
	-- So the wings flap on each player's machine at their own framerate, on a
	-- character the SERVER is walking, and neither half interferes with the
	-- other. It is the same server-builds / client-moves split the whole project
	-- uses, applied to one joint instead of one model.
	local wingSpecs = {
		{ name = "WingUL", size = Vector3.new(1.7, 2.4, 0.14), x = -0.55, y = 0.55, sweep = 30, tilt = 16 },
		{ name = "WingUR", size = Vector3.new(1.7, 2.4, 0.14), x = 0.55, y = 0.55, sweep = -30, tilt = -16 },
		{ name = "WingLL", size = Vector3.new(1.25, 1.7, 0.14), x = -0.45, y = -0.5, sweep = 36, tilt = 28 },
		{ name = "WingLR", size = Vector3.new(1.25, 1.7, 0.14), x = 0.45, y = -0.5, sweep = -36, tilt = -28 },
	}
	for _, spec in ipairs(wingSpecs) do
		local wing = limb(model, spec.name, spec.size, WING)
		wing.Transparency = 0.45
		wing.CanQuery = false

		local c0 = CFrame.new(spec.x, spec.y, 0.55)
			* CFrame.Angles(0, math.rad(spec.sweep), math.rad(spec.tilt))
		wing.CFrame = torso.CFrame * c0
		-- C1 offsets to the wing's INNER edge, so it hinges at the shoulder
		-- rather than spinning about its own middle like a propeller.
		motor(torso, spec.name .. "Joint", torso, wing, c0,
			CFrame.new(spec.x > 0 and -spec.size.X * 0.5 or spec.size.X * 0.5, 0, 0))
		wing:SetAttribute("Side", spec.x < 0 and -1 or 1)
	end

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Brightness = 1.6
	glow.Range = 15
	glow.Color = Color3.fromRGB(255, 190, 230)
	glow.Shadows = false
	glow.Parent = torso

	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.Fairy)
	return model
end

return HubFairy
