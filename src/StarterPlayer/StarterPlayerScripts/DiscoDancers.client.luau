--!strict
-- Steal a Seed :: DiscoDancers
--
-- The disco's dancers on this screen (2026-10-03): while Ticket Disco or Disco
-- Only runs, about eighteen of the owner's eight dancer models (DancerForms)
-- stand round the hub and dance (DancerMoves) on the global event's beat.
--
--   WHO, WHERE, HOW BIG  picked from a Random seeded by the event's id and
--      GameConfig.MiniEvent.Dancers alone (see there), so every player of a
--      server sees the same troupe; a phone shows the first PhoneCount of the
--      same list. Each is built whole at one factor, 0.7-1.3x its authored size
--      -- parts, joints and stud textures together -- and stood on the ground
--      under its spot (a local ray, GroundY if it misses); while it dances it
--      is raised just enough that no foot cuts the floor.
--   ON THE BEAT  the dance is a function of (server time - MiniEventStartedAt)
--      x DanceBPM / 60, so a late joiner sees the troupe mid-dance at once and
--      nothing restarts the event. Faded in as they appear on this screen
--      (the start, or a join), out as the event ends.
--   NEVER IN THE WAY  every part anchored, CanCollide/CanTouch/CanQuery off,
--      in this client's own non-archivable folder; nothing is sent to the
--      server, nothing can be picked up, and nobody walks into a dancer --
--      their spots keep clear of the deck's stall, wheel, chests, pedestal and
--      spawn, the ticket band, the road, every plot's walk and the obby's way.
--
-- ONE TROUPE PER EVENT: rebuilt only when the event's id changes, so repeated
-- notices and attribute churn never duplicate a dancer or its loop. REDUCED
-- MOTION (Reduced FX, or Roblox's own) holds them still in their rest pose.
-- The dancers stop being moved when the event ends and are destroyed after
-- the fade; one RenderStepped connection serves them all and does nothing
-- while there are none.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local DancerForms = require(Shared:WaitForChild("DancerForms"))
local DancerMoves = require(Shared:WaitForChild("DancerMoves"))
local DancerPlacement = require(Shared:WaitForChild("DancerPlacement"))

local M = GameConfig.MiniEvent
local ATTR = M.Attributes
local CFG = M.Dancers
local MODES: { [string]: any } = M.Modes :: any

-- RE-RUN SAFE: a Rojo re-sync re-runs this while the old troupe is up.
local stale = Workspace:FindFirstChild(CFG.FolderName)
if stale then
	stale:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = CFG.FolderName
folder.Archivable = false
folder.Parent = Workspace

type Node = { part: BasePart, parent: number?, forward: boolean, c0: CFrame, c1: CFrame, motor: string? }

type Dancer = {
	id: string,
	model: Model,
	home: CFrame,
	rootRel: CFrame,
	k: number,
	bpm: number,
	energy: number,
	rate: number,
	nodes: { Node },
	order: { number },
	rootNode: number,
	-- The visible parts below the hips, and the height the rest pose stands on.
	feet: { DancerMoves.Foot },
	ground: number,
	parts: { BasePart },
	cframes: { CFrame },
	baseT: { [BasePart]: number },
	textures: { Texture },
	alpha: number,
	far: number,
}

type Pick = DancerPlacement.Pick

local troupe: { Dancer } = {}
local troupeId: string? = nil
-- When this screen built the troupe: the fade-in runs from here, so a start
-- that took the shared store a moment still fades, and so does a late join.
local builtAt = 0

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function discoNow(): boolean
	local mode = MODES[Workspace:GetAttribute(ATTR.Mode) or ""]
	return mode ~= nil and mode.Disco == true
end

--==============================================================================
-- BUILDING ONE: SecretModel's replay at the dancer's factor, then a joint tree
-- read off the data (the same maths SecretIdle uses on the plants)
--==============================================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function groundAt(at: Vector3, zone: any): number
	local map = Workspace:FindFirstChild("SeedMap")
	if map then
		rayParams.FilterDescendantsInstances = { map }
		local hit = Workspace:Raycast(Vector3.new(at.X, 80, at.Z), Vector3.new(0, -160, 0), rayParams)
		if hit and math.abs(hit.Position.Y - zone.GroundY) < 4 then
			return hit.Position.Y
		end
	end
	return zone.GroundY
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function scaled(c: CFrame, s: number): CFrame
	return CFrame.new(c.Position * s) * c.Rotation
end

local function build(pick: Pick, index: number): Dancer?
	local spec = DancerForms.Forms[pick.id]
	if not spec then
		return nil
	end
	local s = pick.scale
	local ground = groundAt(pick.at, pick.zone)
	local spot = Vector3.new(pick.at.X, ground, pick.at.Z)
	local facing = CFrame.lookAt(spot, Vector3.new(0, ground, 0))
	if (flat(spot)).Magnitude < 1e-3 then
		facing = CFrame.new(spot)
	end
	local home = facing * CFrame.Angles(0, pick.yaw, 0)
	local model = Instance.new("Model")
	model.Name = string.format("Dancer%02d_%s", index, pick.id)
	local parts = SecretModel.Replay(spec, home, model, nil, s)
	-- The data is the tree; the replayed joints between anchored parts move
	-- nothing, so they go.
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("JointInstance") then
			d:Destroy()
		end
	end
	-- Stud textures were grown with the model by the owner's Scale tool; they
	-- grow with this copy too.
	local textures: { Texture } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Texture") then
			d.StudsPerTileU *= s
			d.StudsPerTileV *= s
			d.OffsetStudsU *= s
			d.OffsetStudsV *= s
			table.insert(textures, d)
		end
	end
	local baseT: { [BasePart]: number } = {}
	for _, p in ipairs(parts) do
		baseT[p] = p.Transparency
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Anchored = true
	end
	local nodes: { Node } = table.create(#parts)
	for i, p in ipairs(parts) do
		nodes[i] = { part = p, parent = nil, forward = true, c0 = CFrame.identity, c1 = CFrame.identity, motor = nil }
	end
	local edges: { [number]: { { other: number, j: any, forward: boolean } } } = {}
	for _, j in ipairs(spec.Joints) do
		if parts[j.a] and parts[j.b] and j.a ~= j.b then
			edges[j.a] = edges[j.a] or {}
			edges[j.b] = edges[j.b] or {}
			table.insert(edges[j.a], { other = j.b, j = j, forward = true })
			table.insert(edges[j.b], { other = j.a, j = j, forward = false })
		end
	end
	local rootIndex = spec.Base
	local order = { rootIndex }
	local seen = { [rootIndex] = true }
	local head = 1
	while head <= #order do
		local at = order[head]
		head += 1
		for _, e in ipairs(edges[at] or {}) do
			if not seen[e.other] then
				seen[e.other] = true
				local node = nodes[e.other]
				node.parent = at
				node.forward = e.forward
				node.c0 = scaled(e.j.c0, s)
				node.c1 = scaled(e.j.c1, s)
				node.motor = if e.j.k == "Motor6D" then e.j.n else nil
				table.insert(order, e.other)
			end
		end
	end
	-- What can touch the floor: every visible part hung off a hip (all the
	-- visible parts, were a dancer ever to have no hips).
	local leg: { [number]: boolean } = {}
	for i = 2, #order do
		local node = nodes[order[i]]
		leg[order[i]] = node.motor == "HipL" or node.motor == "HipR" or leg[node.parent :: number] == true
	end
	local feet: { DancerMoves.Foot } = {}
	for _, index in ipairs(order) do
		if leg[index] and parts[index].Transparency < 0.999 then
			table.insert(feet, { index = index, half = parts[index].Size / 2 })
		end
	end
	if #feet == 0 then
		for _, index in ipairs(order) do
			if parts[index].Transparency < 0.999 then
				table.insert(feet, { index = index, half = parts[index].Size / 2 })
			end
		end
	end
	-- Parts no joint reaches (none in the eight) stay where the replay put them.
	local cframes = table.create(#parts)
	for i, p in ipairs(parts) do
		cframes[i] = p.CFrame
	end
	local bpm, energy, rate = DancerForms.Beat(pick.id)
	for _, p in ipairs(parts) do
		p.Transparency = 1
	end
	for _, t in ipairs(textures) do
		t.Transparency = 1
	end
	model.Parent = folder
	return {
		id = pick.id,
		model = model,
		home = home,
		rootRel = scaled(spec.Parts[rootIndex].cf, s),
		k = (spec.ModelScale or 1) * s,
		bpm = bpm,
		energy = energy,
		rate = rate,
		nodes = nodes,
		order = order,
		rootNode = rootIndex,
		feet = feet,
		ground = ground,
		parts = parts,
		cframes = cframes,
		baseT = baseT,
		textures = textures,
		alpha = 0,
		far = 0,
	}
end

--==============================================================================
-- ONE FRAME OF ONE DANCER
--==============================================================================
local TEXTURE_T = 0.15

local function setAlpha(d: Dancer, alpha: number)
	if math.abs(alpha - d.alpha) < 0.01 and alpha ~= 0 and alpha ~= 1 then
		return
	end
	if alpha == d.alpha then
		return
	end
	d.alpha = alpha
	for _, p in ipairs(d.parts) do
		local base = d.baseT[p] or 0
		p.Transparency = 1 - (1 - base) * alpha
	end
	for _, t in ipairs(d.textures) do
		t.Transparency = 1 - (1 - TEXTURE_T) * alpha
	end
end

local function pose(d: Dancer, beat: number?)
	local p = if beat then DancerMoves.Pose(d.id, beat, d.energy, d.k) else nil
	local joints = if p then p.joints else nil
	local nodes, cframes = d.nodes, d.cframes
	cframes[d.rootNode] = d.home * d.rootRel * (if p then p.root else CFrame.identity)
	for i = 2, #d.order do
		local index = d.order[i]
		local node = nodes[index]
		local parent = node.parent :: number
		local pcf = cframes[parent]
		local motor = node.motor
		local j = if motor and joints then (joints[motor] or CFrame.identity) else CFrame.identity
		if node.forward then
			cframes[index] = pcf * node.c0 * j * node.c1:Inverse()
		else
			cframes[index] = pcf * node.c1 * j:Inverse() * node.c0:Inverse()
		end
	end
	-- The hip roll's low foot stays planted (DancerMoves GROUND).
	if p then
		local lift = DancerMoves.Lift(cframes, d.feet, d.ground)
		if lift > 0 then
			local up = Vector3.new(0, lift, 0)
			for _, index in ipairs(d.order) do
				cframes[index] += up
			end
		end
	end
	Workspace:BulkMoveTo(d.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

--==============================================================================
-- THE EVENT: one troupe per event id, faded with the event
--==============================================================================
local function clearTroupe()
	for _, d in ipairs(troupe) do
		d.model:Destroy()
	end
	table.clear(troupe)
	troupeId = nil
end

local function phone(): boolean
	return UserInputService.TouchEnabled
end

local function sync()
	local state = Workspace:GetAttribute(ATTR.State)
	local eventId = Workspace:GetAttribute(ATTR.EventId)
	if state == nil or type(eventId) ~= "string" or not discoNow() then
		if troupeId ~= nil and state ~= "ending" then
			clearTroupe()
		end
		return
	end
	if troupeId == eventId then
		return
	end
	if state ~= "running" then
		-- Learned of it only as it ends: nothing to fade in.
		return
	end
	clearTroupe()
	troupeId = eventId
	builtAt = now()
	local picks = DancerPlacement.Picks(eventId)
	local budget = if phone() then math.min(CFG.PhoneCount, #picks) else #picks
	for i = 1, budget do
		local d = build(picks[i], i)
		if d then
			table.insert(troupe, d)
			pose(d, nil)
		end
	end
end

local frame = 0
RunService.RenderStepped:Connect(function()
	if #troupe == 0 then
		return
	end
	frame += 1
	local t = now()
	local startedAt = tonumber(Workspace:GetAttribute(ATTR.StartedAt)) or t
	local state = Workspace:GetAttribute(ATTR.State)
	-- In from when they appeared here, out over the event's fade once it ends.
	local alpha = math.clamp((t - builtAt) / math.max(0.05, CFG.FadeInSeconds), 0, 1)
	if state == "ending" then
		local endingAt = tonumber(Workspace:GetAttribute(ATTR.EndingAt)) or t
		alpha = math.min(alpha, math.clamp(1 - (t - endingAt) / math.max(0.05, M.FadeSeconds), 0, 1))
	elseif state == nil then
		clearTroupe()
		return
	end
	local calm = StatusText.reducedMotion()
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local elapsed = math.max(0, t - startedAt)
	for _, d in ipairs(troupe) do
		setAlpha(d, alpha)
		if calm then
			if d.far ~= -1 then
				d.far = -1
				pose(d, nil)
			end
			continue
		end
		local dist = (d.home.Position - eye).Magnitude
		local every = if dist <= CFG.NearStuds then 1 elseif dist <= CFG.FarStuds then 2 else 4
		d.far = every
		if frame % every == 0 then
			pose(d, elapsed * d.bpm / 60 * d.rate)
		end
	end
end)

for _, name in ipairs({ ATTR.State, ATTR.Mode, ATTR.EventId }) do
	Workspace:GetAttributeChangedSignal(name):Connect(sync)
end
sync()

folder.Destroying:Connect(function()
	table.clear(troupe)
	troupeId = nil
end)
