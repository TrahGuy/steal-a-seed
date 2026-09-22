--!strict
--==============================================================================
-- Steal a Seed :: ArtRedesignMockupRunner   (PREVIEW ONLY)
--
-- Stands the proposed pod families and the proposed Novaorb, Cosmospire and
-- Astralhorn (RedesignForms) beside the production models (CreatureModel) for
-- the owner to judge. Nothing here touches live data, tags, prompts or saves.
--
-- Same shape as PlantSizeMockupRunner: a module nothing calls, invoked from
-- the Command Bar in Edit --
--
--   local R = require(game.ServerScriptService.SeedGameServer.ArtRedesignMockupRunner)
--   R.Build()          -- the whole stage, and a printed report
--   R.Pose(0.25)       -- freeze every walker at one moment of its stride
--   R.Simulate(true)   -- walk them (Edit-mode Heartbeat, generation-guarded)
--   R.Effects(false)   -- lights and emitters off; Effects(true) puts them back
--   R.Night(true)      -- midnight lighting; Night(false) restores the clock
--   R.Clear()          -- everything gone, the clock and the walk with it
--
-- The stage floats off the map at ORIGIN; press Play and walk to it, or fly the
-- Edit camera there. Every part is non-collidable and non-queryable except the
-- floor, which a reviewer in Play has to stand on. The folder and everything
-- in it are non-archivable, so it can never reach the place file.
--==============================================================================

local ArtRedesignMockupRunner = {}

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local UIKit = require(Shared:WaitForChild("UIKit"))

-- Roblox's require cache keys on the ModuleScript INSTANCE and Rojo rewrites
-- Source in place, so RedesignForms is required from a fresh clone on every
-- Build (PlantSizeMockupRunner's freshModules), and the clone dies with the
-- stage. `RedesignForms` is therefore filled in by Build.
local RedesignForms: any = nil
local formsClone: Instance? = nil
local function freshForms(): any
	if formsClone then
		formsClone:Destroy()
		formsClone = nil
	end
	local src = Shared:FindFirstChild("RedesignForms")
	assert(src, "RedesignForms must be synced")
	local clone = (src :: ModuleScript):Clone()
	clone.Name = "RedesignFormsPreview"
	clone.Archivable = false
	clone.Parent = Shared
	formsClone = clone
	return require(clone)
end
local StarbloomMockupRunner = require(script.Parent:WaitForChild("StarbloomMockupRunner"))

local FOLDER_NAME = "ArtRedesignPreview"
-- Clear of the map, of PlantSizeMockup (1200, 200, -1200) and of the Starbloom
-- showroom (z = 70).
local ORIGIN = Vector3.new(-1300, 200, -900)

local BIOMES = { "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }
local PLANTS = { "novaorb", "cosmospire", "astralhorn" }
-- The real Level 5 planting cell, drawn under every plant.
local CELL_X, CELL_Z = 16.0, 13.7
local AVATAR = 5.2

local INK_OLD = Color3.fromRGB(255, 150, 120)
local INK_NEW = Color3.fromRGB(150, 240, 170)
local INK = Color3.fromRGB(240, 240, 240)

--==============================================================================
-- FURNITURE (the PlantSizeMockupRunner set)
--==============================================================================
local function part(name: string, size: Vector3, cf: CFrame, colour: Color3,
	parent: Instance, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(text: string, at: CFrame, parent: Instance, colour: Color3, wide: number)
	local a = part("Label", Vector3.new(0.2, 0.2, 0.2), at, colour, parent, 1)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(wide, wide * 0.30)
	b.AlwaysOnTop = true
	b.MaxDistance = 2000
	b.Parent = a
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = colour
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = b
end

local function cell(at: CFrame, parent: Instance, colour: Color3, sx: number, sz: number)
	local t = 0.16
	for _, side in ipairs({
		{ CFrame.new(0, 0, -sz * 0.5), Vector3.new(sx, t, t) },
		{ CFrame.new(0, 0, sz * 0.5), Vector3.new(sx, t, t) },
		{ CFrame.new(-sx * 0.5, 0, 0), Vector3.new(t, t, sz) },
		{ CFrame.new(sx * 0.5, 0, 0), Vector3.new(t, t, sz) },
	}) do
		part("CellRail", side[2] :: Vector3, at * (side[1] :: CFrame), colour, parent)
	end
end

-- Blocky R6 proportions at the real R15 standing height. Returns the frame a
-- HumanoidRootPart would have, for the carried-pod pose.
local function avatar(at: CFrame, parent: Instance, caption: string?): CFrame
	local skin = Color3.fromRGB(255, 204, 102)
	local shirt = Color3.fromRGB(60, 120, 220)
	local pants = Color3.fromRGB(52, 60, 80)
	local legH, torsoH, headH = 2.0, 2.0, 1.2
	part("RefLeg", Vector3.new(0.5, legH, 0.5), at * CFrame.new(-0.28, legH * 0.5, 0), pants, parent)
	part("RefLeg", Vector3.new(0.5, legH, 0.5), at * CFrame.new(0.28, legH * 0.5, 0), pants, parent)
	part("RefTorso", Vector3.new(1.6, torsoH, 0.8), at * CFrame.new(0, legH + torsoH * 0.5, 0), shirt, parent)
	part("RefArm", Vector3.new(0.5, torsoH, 0.5), at * CFrame.new(-1.05, legH + torsoH * 0.5, 0), skin, parent)
	part("RefArm", Vector3.new(0.5, torsoH, 0.5), at * CFrame.new(1.05, legH + torsoH * 0.5, 0), skin, parent)
	part("RefHead", Vector3.new(1.2, headH, 1.2), at * CFrame.new(0, legH + torsoH + headH * 0.5, 0), skin, parent)
	label(caption or "YOU (5.2)", at * CFrame.new(0, AVATAR + 1.4, 0), parent, INK, 7)
	return at * CFrame.new(0, legH + torsoH * 0.5, 0)
end

local function floor(centre: Vector3, sx: number, sz: number, parent: Instance)
	local f = part("StageFloor", Vector3.new(sx, 1, sz), CFrame.new(centre - Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(96, 104, 96), parent)
	-- The ONE collidable part on the stage: a reviewer in Play stands on it.
	f.CanCollide = true
end

--==============================================================================
-- BUILDING ONE THING, OLD OR PROPOSED
--
-- A proposed plant gets exactly what CreatureModel.BuildCreature gives a
-- Starbloom species: the invisible Base plate as PrimaryPart, the four
-- attributes, the frame height for its tier and the damped girth spread. The
-- girth formula is CreatureModel's own, copied so the preview scales as the
-- production path would.
--==============================================================================
local GIRTH_REF = SeedData.Girth(SeedData.BaseTier)
local function girthSpread(G: number): number
	return 1 + 0.16 * (G - GIRTH_REF) / GIRTH_REF
end

local function buildPlant(id: string, tier: number, at: CFrame, parent: Instance, proposed: boolean): Model
	local sp = SeedData.Get(id)
	assert(sp, "unknown species " .. id)
	if not proposed then
		return CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, at, parent)
	end
	local model = Instance.new("Model")
	model.Name = "Creature_" .. id
	model:SetAttribute("SpeciesId", id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Tier", tier)
	model:SetAttribute("Stage", CreatureModel.STAGE_GROWN)
	model:SetAttribute("Redesign", true)
	model.Parent = parent
	local H = SeedData.FrameHeight(sp, tier)
	local G = SeedData.Girth(tier)
	local stemW = H * 0.13 * G
	local base = part("Base", Vector3.new(stemW * 1.2, 0.06, stemW * 1.2), at * CFrame.new(0, 0.03, 0),
		sp.Soil, model, 1)
	local authored = RedesignForms.AuthoredHeight[id]
	assert(authored, "no proposed builder for " .. id)
	RedesignForms.Build(model, id, at, H / authored, girthSpread(G))
	model.PrimaryPart = base
	return model
end

local function speciesOf(biome: string): SeedData.Species
	local list = SeedData.InBiome(biome)
	assert(#list > 0, "no species in " .. biome)
	return list[1]
end

local function buildPod(biome: string, tier: number, at: CFrame, parent: Instance, proposed: boolean): Model
	local sp = speciesOf(biome)
	if proposed then
		return RedesignForms.BuildPod(sp, tier, at, parent)
	end
	return CreatureModel.BuildPod(sp, tier, at, parent)
end

--==============================================================================
-- MEASURE WHAT WAS BUILT, off the real parts
--==============================================================================
type Measure = {
	parts: number, wedges: number, balls: number, lights: number, emitters: number, leaves: number,
	height: number, width: number, depth: number, lowest: number, radial: number,
}

local function measure(m: Model, base: CFrame): Measure
	local minX, maxX, minZ, maxZ, maxY, lowest = math.huge, -math.huge, math.huge, -math.huge, -math.huge, math.huge
	local parts, wedges, balls, lights, emitters, leaves = 0, 0, 0, 0, 0, 0
	local centre = if m.PrimaryPart then m.PrimaryPart.Position else base.Position
	local radial = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			if d:IsA("WedgePart") then
				wedges += 1
			elseif d:IsA("Part") and d.Shape == Enum.PartType.Ball then
				balls += 1
			end
			if d.Name == "Base" then
				continue
			end
			local h = d.Size * 0.5
			if d:IsA("Part") and d.Shape == Enum.PartType.Ball then
				-- A rotated ball's box corners overshoot the sphere; measure it as one.
				local r = math.min(h.X, h.Y, h.Z)
				local c = d.Position
				minX = math.min(minX, c.X - r); maxX = math.max(maxX, c.X + r)
				minZ = math.min(minZ, c.Z - r); maxZ = math.max(maxZ, c.Z + r)
				maxY = math.max(maxY, c.Y + r); lowest = math.min(lowest, c.Y - r)
				local dx, dz = c.X - centre.X, c.Z - centre.Z
				radial = math.max(radial, math.sqrt(dx * dx + dz * dz) + r)
				continue
			end
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						minX = math.min(minX, q.X); maxX = math.max(maxX, q.X)
						minZ = math.min(minZ, q.Z); maxZ = math.max(maxZ, q.Z)
						maxY = math.max(maxY, q.Y); lowest = math.min(lowest, q.Y)
						local dx, dz = q.X - centre.X, q.Z - centre.Z
						radial = math.max(radial, math.sqrt(dx * dx + dz * dz))
					end
				end
			end
		elseif d:IsA("PointLight") then
			lights += 1
		elseif d:IsA("ParticleEmitter") then
			emitters += 1
		end
	end
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("BasePart") and c.Name == "Leaf" then
			leaves += 1
		end
	end
	return {
		parts = parts, wedges = wedges, balls = balls, lights = lights, emitters = emitters, leaves = leaves,
		height = maxY - base.Position.Y, width = maxX - minX, depth = maxZ - minZ,
		lowest = lowest - base.Position.Y, radial = radial,
	}
end

local function podLine(tag: string, m: Model, base: CFrame, tier: number): string
	local q = measure(m, base)
	local D = SeedData.PodDiameter(tier)
	return string.format("%-32s parts %2d (wedge %2d ball %2d) fx %d/%d | %.2fD wide %.2fD tall %.2fD deep | lowest %+.3f | radial %.2f of haul %.2f",
		tag, q.parts, q.wedges, q.balls, q.lights, q.emitters, q.width / D, q.height / D, q.depth / D,
		q.lowest, q.radial, D * 0.5 + (tonumber(GameConfig.Parent.HaulClearance) or 0.4))
end

local function plantLine(tag: string, m: Model, base: CFrame): string
	local q = measure(m, base)
	local rig = StarbloomMockupRunner.RigOf(m)
	local margin = math.huge
	for _, it in ipairs(rig.parts) do
		if it.margin then
			margin = math.min(margin, it.margin)
		end
	end
	return string.format("%-30s parts %2d (wedge %2d ball %2d) lights %d emitters %d leaves %d | h %5.1f w %5.1f d %5.1f | lowest %+.3f | legs %d (hip margin %s)",
		tag, q.parts, q.wedges, q.balls, q.lights, q.emitters, q.leaves, q.height, q.width, q.depth,
		q.lowest, #rig.hips, if margin < math.huge then string.format("%.2f:1", margin) else "-")
end

--==============================================================================
-- THE WALK, for the Edit datamodel
--
-- PlantSway never sees these models (no client, no Planted tag), so the runner
-- walks them itself the way StarbloomMockupRunner does: the legs through
-- RigOf/PoseLegs, which mirror PlantSway's hip rig, and the Leaf children
-- swung as arms by the side they sit on -- PlantSway's own rule.
--==============================================================================
local SWING_AMP = math.rad(19)
local walkers: { { model: Model, rest: CFrame, rig: any, leaves: { { part: BasePart, offset: CFrame, sign: number } } } } = {}
local simConnection: RBXScriptConnection? = nil
local generation = 0

local function registerWalker(model: Model)
	local pivot = model:GetPivot()
	local inverse = pivot:Inverse()
	local leaves = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Leaf" then
			local offset = inverse * d.CFrame
			table.insert(leaves, { part = d, offset = offset, sign = if offset.Position.X < 0 then -1 else 1 })
		end
	end
	table.insert(walkers, { model = model, rest = pivot, rig = StarbloomMockupRunner.RigOf(model), leaves = leaves })
end

local function poseWalker(w, target: CFrame, phase: number, amount: number)
	StarbloomMockupRunner.PoseLegs(w.model, w.rig, target, phase, amount)
	local swing = math.sin(phase) * SWING_AMP * amount
	for _, leaf in ipairs(w.leaves) do
		leaf.part.CFrame = target * leaf.offset * CFrame.Angles(swing * leaf.sign, 0, 0)
	end
end

function ArtRedesignMockupRunner.Pose(k: number?)
	ArtRedesignMockupRunner.Simulate(false)
	local turn = math.pi * 2 * (k or 0)
	for _, w in ipairs(walkers) do
		if w.model.Parent then
			poseWalker(w, w.rest, turn, if (k or 0) == 0 then 0 else 1)
		end
	end
	print(string.format("[Seed/ArtRedesignMockup] Posed %d walker(s) at k=%.2f", #walkers, k or 0))
end

function ArtRedesignMockupRunner.Simulate(enable: boolean)
	generation += 1
	if simConnection then
		simConnection:Disconnect()
		simConnection = nil
	end
	if not enable then
		return
	end
	local mine = generation
	local startTime = os.clock()
	simConnection = RunService.Heartbeat:Connect(function()
		if mine ~= generation or not workspace:FindFirstChild(FOLDER_NAME) then
			if simConnection then
				simConnection:Disconnect()
				simConnection = nil
			end
			return
		end
		local t = os.clock() - startTime
		for _, w in ipairs(walkers) do
			if w.model.Parent and w.model.PrimaryPart then
				-- A stroll scaled to the creature, on the same clock the legs step to.
				local reach = math.max(w.model:GetExtentsSize().Y, 1) * 0.22
				local a = t * 0.8
				local yaw = -a + math.pi * 0.5
				local bob = math.abs(math.sin(t * 3.5)) * reach * 0.04
				local target = w.rest * CFrame.new(math.cos(a) * reach, bob, math.sin(a) * reach) * CFrame.Angles(0, yaw, 0)
				poseWalker(w, target, t * 3.5, 1)
			end
		end
	end)
	print("[Seed/ArtRedesignMockup] Walking.")
end

--==============================================================================
-- EFFECTS AND LIGHTING, for the two views the brief asks for
--==============================================================================
function ArtRedesignMockupRunner.Effects(on: boolean)
	local root = workspace:FindFirstChild(FOLDER_NAME)
	if not root then
		return
	end
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("PointLight") then
			d.Enabled = on
			n += 1
		end
	end
	print(string.format("[Seed/ArtRedesignMockup] %d effect(s) %s", n, if on then "on" else "off"))
end

function ArtRedesignMockupRunner.Night(on: boolean)
	local root = workspace:FindFirstChild(FOLDER_NAME)
	if not root then
		return
	end
	if on then
		if root:GetAttribute("SavedClockTime") == nil then
			root:SetAttribute("SavedClockTime", Lighting.ClockTime)
		end
		Lighting.ClockTime = 0
	else
		local saved = root:GetAttribute("SavedClockTime")
		if type(saved) == "number" then
			Lighting.ClockTime = saved
			root:SetAttribute("SavedClockTime", nil)
		end
	end
end

function ArtRedesignMockupRunner.Clear()
	ArtRedesignMockupRunner.Simulate(false)
	table.clear(walkers)
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		local saved = existing:GetAttribute("SavedClockTime")
		if type(saved) == "number" then
			Lighting.ClockTime = saved
		end
		existing:Destroy()
	end
	if formsClone then
		formsClone:Destroy()
		formsClone = nil
	end
	-- A clone left by another require of this module (a fresh Command Bar
	-- session clearing an older session's stage).
	local stray = Shared:FindFirstChild("RedesignFormsPreview")
	if stray then
		stray:Destroy()
	end
	print("[Seed/ArtRedesignMockup] Cleared " .. FOLDER_NAME)
end

--==============================================================================
-- THE HOTBAR CARD BOARD
--
-- Eleven compact hotbar cards (54 x 76, the 50 x 42 preview glass) drawn on a
-- board through UIKit.itemPreview, the same viewport and framing the real
-- hotbar uses. Old plants above, proposed plants below, the proposed pods last.
--==============================================================================
local function cardBoard(at: CFrame, parent: Instance)
	local COLS, ROWS = 5, 3
	local CARD_W, CARD_H, GAP = 54, 76, 8
	local SCALE = 3
	local canvasW = (COLS * CARD_W + (COLS + 1) * GAP)
	local canvasH = (ROWS * CARD_H + (ROWS + 1) * GAP)
	local board = part("HotbarBoard", Vector3.new(canvasW / 12, canvasH / 12, 0.4), at, Color3.fromRGB(28, 32, 42), parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(canvasW * SCALE, canvasH * SCALE)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = board
	local scale = Instance.new("UIScale")
	scale.Scale = SCALE
	scale.Parent = gui

	local function card(col: number, row: number, name: string, build: (Instance) -> Model?, kind: string, tint: Color3)
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(CARD_W, CARD_H)
		f.Position = UDim2.fromOffset(GAP + (col - 1) * (CARD_W + GAP), GAP + (row - 1) * (CARD_H + GAP))
		f.BackgroundColor3 = Color3.fromRGB(21, 27, 36)
		f.BorderSizePixel = 0
		f.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = f
		local preview = UIKit.itemPreview(f, {
			name = "Preview",
			size = UDim2.fromOffset(50, 42),
			position = UDim2.fromOffset(2, 16),
			scrim = 1,
			fit = 0.97,
		})
		preview.setModel(name .. row, build, kind)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -6, 0, 14)
		t.Position = UDim2.new(0, 3, 0, 59)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextSize = 10
		t.TextColor3 = tint
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.Text = name
		t.Parent = f
	end

	for i, id in ipairs(PLANTS) do
		local sp = SeedData.Get(id) :: SeedData.Species
		card(i, 1, "OLD " .. sp.Name, function(p)
			return CreatureModel.Build(sp, 1, CreatureModel.STAGE_GROWN, CFrame.new(), p)
		end, "plant", INK_OLD)
		card(i, 2, "NEW " .. sp.Name, function(p)
			return buildPlant(id, 1, CFrame.new(), p, true)
		end, "plant", INK_NEW)
	end
	for i, biome in ipairs(BIOMES) do
		card(i, 3, "NEW " .. biome .. " pod", function(p)
			return buildPod(biome, 1, CFrame.new(), p, true)
		end, "plant", INK_NEW)
	end
	label("HOTBAR CARDS (54 x 76) -- old plants / proposed plants / proposed pods",
		at * CFrame.new(0, canvasH / 24 + 2, 0), parent, INK, 30)
end

--==============================================================================
-- BUILD
--==============================================================================
function ArtRedesignMockupRunner.Build(): (Folder, string)
	ArtRedesignMockupRunner.Clear()
	RedesignForms = freshForms()
	assert(#RedesignForms.PodFamilies == #BIOMES, "RedesignForms.PodFamilies changed; update BIOMES")

	local root = Instance.new("Folder")
	root.Name = FOLDER_NAME
	root.Archivable = false
	root:SetAttribute("PreviewOnly", true)
	root.Parent = workspace

	floor(ORIGIN + Vector3.new(70, 0, 190), 320, 520, root)
	label("ART REDESIGN PREVIEW -- PREVIEW ONLY, awaiting owner approval. Left: OLD (shipped). Right/below: PROPOSED.",
		CFrame.new(ORIGIN + Vector3.new(50, 26, -20)), root, INK, 60)

	local report: { string } = {}
	local function say(s: string)
		table.insert(report, s)
	end

	--==========================================================================
	-- AREA 1: THE FIVE POD FAMILIES
	--==========================================================================
	local POD_PITCH = 24
	local podRows = {
		{ z = 0, tier = 1, proposed = false, tag = "OLD  Tiny" },
		{ z = 16, tier = 1, proposed = true, tag = "NEW  Tiny" },
		{ z = 34, tier = 4, proposed = true, tag = "NEW  Mega" },
		{ z = 60, tier = 7, proposed = true, tag = "NEW  Colossal" },
		{ z = 92, tier = 7, proposed = false, tag = "OLD  Colossal" },
	}
	say("-- PODS (width/height/depth in D = PodDiameter; radial = furthest part from the Shell axis vs the haul clearance) --")
	for _, row in ipairs(podRows) do
		local ink = if row.proposed then INK_NEW else INK_OLD
		label(row.tag, CFrame.new(ORIGIN + Vector3.new(-22, 4, row.z)), root, ink, 16)
		for i, biome in ipairs(BIOMES) do
			local at = CFrame.new(ORIGIN + Vector3.new((i - 1) * POD_PITCH, 0, row.z))
			local group = Instance.new("Model")
			group.Name = string.format("Pod_%s_%s_T%d", if row.proposed then "NEW" else "OLD", biome, row.tier)
			group.Parent = root
			local m = buildPod(biome, row.tier, at, group, row.proposed)
			say(podLine(string.format("%s %s T%d", if row.proposed then "NEW" else "OLD", biome, row.tier), m, at, row.tier))
			if row.z == 0 then
				label(string.upper(biome), at * CFrame.new(0, -1, -8), root, INK, 12)
			end
		end
	end

	-- Contexts, one per biome: held, on the nest bedding, on soil, and the
	-- Colossal inside the guardian's haul clearance.
	local CTX_Z = 124
	label("CONTEXTS: held (Huge) | nest bedding (Giant) | soil (Big) | haul clearance (Colossal, the ring is D/2 + 0.4)",
		CFrame.new(ORIGIN + Vector3.new(30, 8, CTX_Z - 12)), root, INK_NEW, 50)
	for i, biome in ipairs(BIOMES) do
		local x = (i - 1) * POD_PITCH
		local group = Instance.new("Model")
		group.Name = "Context_" .. biome
		group.Parent = root

		-- Held by an avatar, at the real grip: the Shell welded to the root at
		-- (0, GripDrop, -GripForward).
		local heldAt = CFrame.new(ORIGIN + Vector3.new(x - 6, 0, CTX_Z))
		local rootCF = avatar(heldAt, group, "HELD")
		local held = buildPod(biome, 3, CFrame.new(), group, true)
		held:PivotTo(rootCF * CFrame.new(0, GameConfig.Carry.GripDrop, -SeedData.GripForward(3)))

		-- On the nest bedding: the 0.16-stud disc pods stand on, at the base.
		local bedAt = CFrame.new(ORIGIN + Vector3.new(x + 4, 0, CTX_Z))
		local disc = part("Bedding", Vector3.new(0.16, 12, 12), bedAt * CFrame.new(0, 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(88, 96, 70), group)
		disc.Shape = Enum.PartType.Cylinder
		buildPod(biome, 5, bedAt, group, true)

		-- On soil: a bed cell, the pod's base on the dirt.
		local soilAt = CFrame.new(ORIGIN + Vector3.new(x + 4, 0, CTX_Z + 16))
		part("Soil", Vector3.new(CELL_X * 0.6, 0.5, CELL_Z * 0.6), soilAt * CFrame.new(0, -0.25, 0), Color3.fromRGB(124, 76, 50), group)
		cell(soilAt, group, Color3.fromRGB(120, 110, 96), CELL_X * 0.6, CELL_Z * 0.6)
		buildPod(biome, 2, soilAt, group, true)

		-- The haul clearance: a Colossal inside the ring the guardian keeps clear.
		local haulAt = CFrame.new(ORIGIN + Vector3.new(x - 6, 0, CTX_Z + 30))
		local D = SeedData.PodDiameter(7)
		local ring = part("HaulRing", Vector3.new(0.2, D + 0.8, D + 0.8),
			haulAt * CFrame.new(0, D * 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 120, 120), group, 0.6)
		ring.Shape = Enum.PartType.Cylinder
		buildPod(biome, 7, haulAt, group, true)
	end

	--==========================================================================
	-- AREA 2: NOVAORB, COSMOSPIRE, ASTRALHORN
	--==========================================================================
	local PLANT_Z = 200
	local PLANT_PITCH = 30
	label("PLANTS: OLD row, then PROPOSED at Tiny, Mega and Colossal. Tiny and Mega rows walk: R.Simulate(true) / R.Pose(0.25)",
		CFrame.new(ORIGIN + Vector3.new(30, 12, PLANT_Z - 14)), root, INK_NEW, 56)
	say("-- PLANTS --")
	local plantRows = {
		{ z = 0, tier = 1, proposed = false, tag = "OLD  Tiny", pitch = PLANT_PITCH, walk = true },
		{ z = 24, tier = 1, proposed = true, tag = "NEW  Tiny", pitch = PLANT_PITCH, walk = true },
		{ z = 52, tier = 4, proposed = true, tag = "NEW  Mega", pitch = PLANT_PITCH + 6, walk = true },
		{ z = 100, tier = 7, proposed = true, tag = "NEW  Colossal", pitch = 64, walk = false },
	}
	for _, row in ipairs(plantRows) do
		local ink = if row.proposed then INK_NEW else INK_OLD
		label(row.tag, CFrame.new(ORIGIN + Vector3.new(-22, 4, PLANT_Z + row.z)), root, ink, 16)
		for i, id in ipairs(PLANTS) do
			local at = CFrame.new(ORIGIN + Vector3.new((i - 1) * row.pitch, 0, PLANT_Z + row.z))
			local group = Instance.new("Model")
			group.Name = string.format("Plant_%s_%s_T%d", if row.proposed then "NEW" else "OLD", id, row.tier)
			group.Parent = root
			cell(at, group, Color3.fromRGB(120, 110, 96), CELL_X, CELL_Z)
			if row.tier <= 4 then
				avatar(at * CFrame.new(-CELL_X * 0.5 - 2.5, 0, 0), group)
			end
			local m = buildPlant(id, row.tier, at, group, row.proposed)
			say(plantLine(string.format("%s %s T%d", if row.proposed then "NEW" else "OLD", id, row.tier), m, at))
			if row.walk then
				registerWalker(m)
			end
			if row.z == 0 then
				label(string.upper(id), at * CFrame.new(0, -1, -9), root, INK, 12)
			end
		end
	end

	-- Crowding: the proposed three at Big on the real cell pitch, with their
	-- Starbloom neighbours between them at Tiny.
	local CROWD_Z = PLANT_Z + 160
	label("CROWDING: proposed (Big) between shipped Voidpetal and Supernovus (Tiny), on the real 16 x 13.7 cell",
		CFrame.new(ORIGIN + Vector3.new(30, 8, CROWD_Z - 12)), root, INK_NEW, 50)
	local crowd = { { "novaorb", true }, { "voidpetal", false }, { "cosmospire", true }, { "supernovus", false }, { "astralhorn", true } }
	for i, entry in ipairs(crowd) do
		local id, proposed = entry[1] :: string, entry[2] :: boolean
		local at = CFrame.new(ORIGIN + Vector3.new((i - 1) * CELL_X, 0, CROWD_Z))
		local group = Instance.new("Model")
		group.Name = "Crowd_" .. id
		group.Parent = root
		cell(at, group, Color3.fromRGB(90, 80, 70), CELL_X, CELL_Z)
		local m = buildPlant(id, if proposed then 2 else 1, at, group, proposed)
		registerWalker(m)
	end
	avatar(CFrame.new(ORIGIN + Vector3.new(-14, 0, CROWD_Z)), root)

	-- The hotbar cards, on a board beside the plant rows.
	cardBoard(CFrame.new(ORIGIN + Vector3.new(-42, 12, PLANT_Z + 40)) * CFrame.Angles(0, math.rad(90), 0), root)

	local text = table.concat(report, "\n")
	print("[Seed/ArtRedesignMockup] built " .. FOLDER_NAME .. ":\n" .. text)
	return root, text
end

return ArtRedesignMockupRunner
