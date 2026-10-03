--!strict
-- Steal a Seed :: StormstriderModel
--
-- The Rain event's guardian (2026-10-02): the owner's supplied "Stormstrider
-- GUARDIAN", replayed part for part from RainForms at the size it was supplied
-- (SecretModel.Replay, loose), and put on the contract every guardian in this
-- game keeps (AstralmawModel's):
--
--   * an invisible, unanchored HumanoidRootPart the Humanoid moves, joined to
--     the supplied Body by a RootJoint Motor6D at rest;
--   * every supplied part unanchored, massless and non-colliding, its own
--     Motor6Ds and Welds replayed verbatim -- ParentAnim poses those Motor6Ds on
--     every client (C0 = rest * pose), as it does every guardian's seams;
--   * ONE collidable part, the supplied Body, at its supplied size -- nothing
--     enlarged, nothing added to reach further;
--   * a Humanoid at WalkSpeed 0 with infinite health and AutoRotate, its
--     HipHeight measured off the supplied geometry so the paws stand on the
--     ground under the root;
--   * BiomeId "rain", Species "stormstrider", Asleep, tagged NestParent last.
--
-- The owner's StormstriderRun script is not copied into the place: ParentAnim's
-- stormstrider branch plays its gallop, its sleep and its strikes on the
-- clients, from this model's own attributes.
--
-- NOT a *Service. Geometry only; NestService (through ParentModel) is the one
-- caller.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RainForms = require(Shared:WaitForChild("RainForms"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))

local StormstriderModel = {}

StormstriderModel.SPECIES = "stormstrider"
StormstriderModel.BIOME = "rain"

-- The root: a box over the body's centre, invisible. Its bottom is what the
-- Humanoid holds HipHeight above the floor.
local ROOT_SIZE = Vector3.new(6, 6, 12)

-- `cf` is the guardian's BASE: the ground under the body's centre, facing the
-- way it should face (the supplied model looks down its -Z, like every rig).
-- `height` is the shared guardian argument and is not used: one size.
function StormstriderModel.Build(cf: CFrame, _height: number, parent: Instance): Model
	local spec = RainForms.Guardian
	local model = Instance.new("Model")
	model.Name = "Parent_" .. StormstriderModel.BIOME
	model:SetAttribute("BiomeId", StormstriderModel.BIOME)
	model:SetAttribute("Species", StormstriderModel.SPECIES)
	model:SetAttribute("Asleep", true)
	model.Parent = parent

	local parts = SecretModel.Replay(spec, cf, model, true)
	-- The demo the supplied script ran (laps round where it spawned) is the
	-- script's own and is off here; the run is what NestService moves.
	model:SetAttribute("AutoRun", false)

	local body = parts[spec.Base or 1]
	assert(body, "StormstriderModel: the supplied rig has no body part")

	--== ROOT ==--
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE
	root.CFrame = CFrame.new(body.Position) * cf.Rotation
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = false
	root.Parent = model
	model.PrimaryPart = root

	local joint = Instance.new("Motor6D")
	joint.Name = "RootJoint"
	joint.Part0 = root
	joint.Part1 = body
	joint.C0 = CFrame.identity
	joint.C1 = body.CFrame:ToObjectSpace(root.CFrame)
	joint.Parent = root

	--== THE ONE COLLIDER: the supplied body, as supplied ==--
	body.CanCollide = true

	--== HUMANOID CONTRACT ==--
	local lowest = math.huge
	for _, p in ipairs(parts) do
		local h = p.Size * 0.5
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					lowest = math.min(lowest, (p.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position.Y)
				end
			end
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = true
	humanoid.HipHeight = (root.Position.Y - ROOT_SIZE.Y * 0.5) - lowest
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	-- One body for streaming: a guardian half streamed in is a guardian with
	-- its legs missing.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	CollectionService:AddTag(model, GameConfig.Tags.NestParent)
	return model
end

return StormstriderModel
