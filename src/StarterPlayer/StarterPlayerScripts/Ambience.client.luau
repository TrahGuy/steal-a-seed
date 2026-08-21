--!strict
-- Steal a Seed :: Ambience
--
-- Everything in the world that MOVES for decoration moves here, on each
-- player's own machine.
--
--==============================================================================
-- ONE LOOP, OVER A TAG
--
-- The server builds a thing and tags it; this walks the tagged set once per
-- frame. Not one script per object, not one connection per object -- one
-- Heartbeat over a flat table, so twenty fairies cost twenty table lookups
-- rather than twenty coroutines.
--
-- Nothing here is authoritative and nothing here replicates. Two players see
-- the fairy in slightly different places, which for a decoration nobody can
-- touch is not a difference either of them can observe -- and it buys a
-- position stream per object per frame that would otherwise run forever.
--
-- See HubFairy for the server half and the full argument.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

--==============================================================================
-- FAIRIES
--==============================================================================
local FAIRY_TAG = GameConfig.Tags.Fairy

type Wing = { part: BasePart, offset: CFrame, side: number }
type Fairy = {
	model: Model,
	root: BasePart,
	home: Vector3,
	facing: Vector3,
	wings: { Wing },
	-- Per-fairy phase, so two fairies in one place never bob in lockstep.
	phase: number,
	parts: { { part: BasePart, offset: CFrame } },
}

local fairies: { [Model]: Fairy } = {}

-- Derived from the model's name and position rather than random, so a fairy
-- looks the same on every client -- the point of a shared world is that two
-- players describing it agree.
local function phaseFor(model: Model, home: Vector3): number
	local h = 0
	for i = 1, #model.Name do
		h += string.byte(model.Name, i) * i
	end
	h += math.floor(math.abs(home.X) + math.abs(home.Z))
	return (h % 628) / 100
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not (root and root:IsA("BasePart")) then
		return
	end

	local home = Vector3.new(
		model:GetAttribute("HomeX") or root.Position.X,
		model:GetAttribute("HomeY") or root.Position.Y,
		model:GetAttribute("HomeZ") or root.Position.Z)

	-- Every part's REST offset from the root, captured once. Recomputing this
	-- from live CFrames each frame is how a model slowly comes apart: each
	-- frame's rounding feeds into the next.
	local parts: { { part: BasePart, offset: CFrame } } = {}
	local wings: { Wing } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local offset = root.CFrame:ToObjectSpace(d.CFrame)
			if d:GetAttribute("Side") then
				-- A full CFrame, because the rest pose carries the wing's SWEEP
				-- as well as its position and a Vector3 cannot say "angled back
				-- 28 degrees".
				local rest = d:GetAttribute("RestOffset")
				table.insert(wings, {
					part = d,
					offset = (typeof(rest) == "CFrame") and rest or offset,
					side = d:GetAttribute("Side") or 1,
				})
			else
				table.insert(parts, { part = d, offset = offset })
			end
		end
	end

	local fx = model:GetAttribute("FaceX")
	local fz = model:GetAttribute("FaceZ")
	local facing = (fx and fz and (math.abs(fx) + math.abs(fz)) > 0)
		and Vector3.new(fx, 0, fz).Unit or Vector3.new(0, 0, -1)

	fairies[model] = {
		model = model,
		root = root,
		home = home,
		facing = facing,
		wings = wings,
		parts = parts,
		phase = phaseFor(model, home),
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
-- Orbit slowly, bob quickly, flap much faster, and face where she is going.
-- Three different rates on purpose: matched rates read as one mechanical
-- motion, and the whole point of a fairy is that she does not look driven by a
-- clock.
--==============================================================================
local ORBIT_RADIUS = 1.9
local ORBIT_RATE = 0.55
local BOB_HEIGHT = 0.55
local BOB_RATE = 2.1
local FLAP_RATE = 21
local FLAP_ANGLE = math.rad(34)

RunService.Heartbeat:Connect(function()
	if next(fairies) == nil then
		return
	end
	local t = os.clock()

	for model, f in pairs(fairies) do
		if not f.root.Parent then
			-- Despawned without the removed signal firing. Drops out here so the
			-- table cannot grow without bound.
			fairies[model] = nil
		else
			local a = t * ORBIT_RATE + f.phase
			local pos = f.home + Vector3.new(
				math.sin(a) * ORBIT_RADIUS,
				math.sin(t * BOB_RATE + f.phase) * BOB_HEIGHT,
				math.cos(a) * ORBIT_RADIUS)

			-- FIXED FACING. She drifts and bobs but keeps looking the way the
			-- stall does -- see HubFairy. Facing the orbit tangent instead meant
			-- she spent half of every circuit with her back to the counter.
			local cf = CFrame.lookAt(pos, pos + f.facing)
			f.root.CFrame = cf

			for _, entry in ipairs(f.parts) do
				entry.part.CFrame = cf * entry.offset
			end

			local flap = math.sin(t * FLAP_RATE + f.phase) * FLAP_ANGLE
			for _, w in ipairs(f.wings) do
				-- Rotated about the BODY, not about the wing's own centre, so it
				-- hinges at the shoulder the way a wing does rather than
				-- spinning like a propeller.
				w.part.CFrame = cf
					* CFrame.Angles(0, 0, flap * w.side)
					* w.offset
			end
		end
	end
end)
