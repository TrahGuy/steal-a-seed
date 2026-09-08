--!strict
--==============================================================================
-- Steal a Seed :: PlantSizeMockupRunner
--
-- The seven-tier size ladder, proposed against shipped, built through the REAL
-- production builders so what is judged is what would ship.
--
-- PREVIEW ONLY. Nothing here changes live scaling. `SeedData.Tiers` on disk is
-- untouched; the candidate curve is injected into a THROWAWAY CLONE of SeedData
-- that exists for the length of one Build() call. Stop reading here if you were
-- looking for the live numbers -- they are in SeedData and this file cannot
-- reach them.
--
--==============================================================================
-- NOTHING CALLS THIS, AND THAT IS THE POINT
--
-- Same reasoning as MillMockupRunner and EmberrootRootMockupRunner, which this
-- is modelled on: a Script cannot run in Edit at all, so a `RunService:IsStudio`
-- gate on a `.server.luau` gates the published game and leaves playtests
-- building the gallery. As a module it is invoked deliberately:
--
--   require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Build()
--   require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Build({ live = true })
--   require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Clear()
--
--==============================================================================
-- TO SEE IT MOVE OR CRACKLE, PRESS PLAY -- AND BUILD IT WHILE STANDING IN IT
--
-- The sway and the Colossal aura are both CLIENT systems keyed on the `Planted`
-- tag, and Edit runs no client, so in Edit this stage is geometry. In Play it
-- animates -- but only if the client had the plants' PARTS when the tag arrived.
--
-- StreamingEnabled is on in this place and PlantSway waits five seconds for a
-- PrimaryPart before giving up on a model for good. A stage built 1,900 studs
-- from the character loses that race every time: the empty Model containers
-- replicate at once, their parts arrive much later, and nothing is ever indexed.
-- Measured, not guessed -- the first attempt showed 82 tagged models and zero of
-- them moving.
--
-- So: press Play, get to ORIGIN, and run Build() from there.
--
-- Build() clears the previous stage first, so it is safe to run repeatedly while
-- iterating on a curve.
--
--==============================================================================
-- HOW THE OVERRIDE WORKS, AND WHY IT IS A CLONE RATHER THAN A PARAMETER
--
-- Every horizontal and vertical dimension in a creature descends from ONE
-- number: `SeedData.Tiers[i].mul`, read through `SeedData.FrameHeight`. Adding a
-- scale argument to `CreatureModel.Build` would mean threading it through every
-- form builder in the file, and a preview that needs a modified production
-- builder is a preview of a build that does not exist.
--
-- So the production builders are used UNMODIFIED, and the one number they read
-- is changed underneath them: clone SeedData, rewrite the `mul` field on each
-- tier row in the clone's Source, clone CreatureModel and repoint its
-- `WaitForChild("SeedData")` at the patched copy. Both clones are destroyed
-- before Build() returns.
--
-- CreatureModel is the only Shared module that requires SeedData, so repointing
-- it is the whole job -- EmberrootForms, StarbloomForms and TanglemireForms
-- carry approved geometry and read no tier scale at all.
--==============================================================================

local PlantSizeMockupRunner = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "PlantSizeMockup"

--==============================================================================
-- THE CURVE THIS STAGE WAS BUILT TO PROVE, AND WHICH NOW SHIPS
--
-- Approved and applied to SeedData.Tiers on 2026-09-08. It is kept here for two
-- reasons: `Build({ live = true })` still stands the stage up on whatever
-- SeedData currently says, so the two can be compared after any future change,
-- and this table is the record of what was measured and agreed.
--
-- The ladder it replaced was 1 / 1.308 / 1.71 / 5 / 10 / 20 / 50 -- three
-- near-identical bottom tiers and then a 2.92x cliff at Huge -> Mega that put a
-- Colossal at 217 to 460 studs against a 46-stud wall.
--
--   x1.38  x1.38  x1.39  x1.40  x1.38  x1.49
--
-- Every step is a visible jump, none is a cliff, and Titan -> Colossal is the
-- biggest of them.
--==============================================================================
local PROPOSED: { [string]: number } = {
	Tiny = 1.00,
	Big = 1.38,
	Huge = 1.90,
	Mega = 2.65,
	Giant = 3.70,
	Titan = 5.10,
	Colossal = 7.60,
}

--==============================================================================
-- THE STAGE
--
-- Clear sky, well off the road. At the SHIPPED curve a Colossal Supernovus is
-- 460 studs tall and 382 studs across its own feet, so a stage built anywhere
-- near the map puts the camera inside somebody's shin -- which is the first
-- thing this preview has to be able to show without being ruined by it.
--==============================================================================
local ORIGIN = Vector3.new(1200, 200, -1200)

-- The real Level 5 planting cell: Plot.Width 48 over BedColumns 3, and depth
-- 96.2 over 7 rows. Drawn under every specimen so "does it fit" is a question
-- the eye can answer.
local CELL_X, CELL_Z = 16.0, 13.7
local WALL = 46          -- GameConfig.Map.WallHeight, the corridor canyon wall
local AVATAR = 5.2       -- a default R15 avatar, head to sole

--==============================================================================
-- FIVE SPECIES, CHOSEN TO BE AWKWARD IN DIFFERENT WAYS
--
-- Between them they cover the short/compact floor, the tall Greenhollow Epic
-- the brief names, a multi-legged Emberroot on freeform roots, a Starbloom
-- spire, and the broadest creature in the game.
--==============================================================================
local LADDER = {
	{ id = "nubkin", note = "shortest form -- the floor of the ladder" },
	{ id = "bellchime", note = "tall Greenhollow Epic" },
	{ id = "cinderpaw", note = "multi-legged, freeform Emberroot roots" },
	{ id = "cosmospire", note = "Starbloom spire -- tall and narrow" },
	{ id = "supernovus", note = "broadest creature in the game" },
}

--==============================================================================
-- PITCH IS SET BY THE BIGGEST THING ON THE STAGE, NOT BY TASTE
--
-- The widest Colossal on the candidate curve is Supernovus at 58 studs across
-- its own feet. Columns at 64 keep even that clear of its neighbour; rows at
-- 112 keep one species' Colossal off the next species' row. Anything tighter
-- and the preview would be showing an overlap the CURVE does not have.
--==============================================================================
--==============================================================================
-- THE AURA BENCH
--
-- One Colossal off each of the five roads, so the five palettes can be compared
-- in one glance, plus a Titan standing beside a Colossal of the SAME species --
-- which is the only view that proves the aura is a tier gate and not something
-- every big plant gets. Both stand in front of the ladder rather than in a
-- gallery of their own: the brief asks for the existing preview, not a second
-- showroom.
--
-- The arcs themselves are CLIENT-SIDE, so this bench is geometry only in Edit.
-- Press Play to see it crackle -- PlantSway drives PlantAura, and neither runs
-- in a datamodel with no client in it.
--==============================================================================
local AURA_BENCH = {
	{ id = "bellchime", biome = "greenhollow" },
	{ id = "suncrown", biome = "dustbowl" },
	{ id = "lanterncap", biome = "tanglemire" },
	{ id = "cinderpaw", biome = "emberroot" },
	{ id = "cosmospire", biome = "starbloom" },
}
local BENCH_PITCH = 76
local BENCH_Z = -190
local PAIR_Z = -320

local COL_PITCH = 64     -- along X, one tier per column
local ROW_PITCH = 112    -- along Z, one species per row

--==============================================================================
-- FRESH MODULES, PATCHED
--
-- Roblox's require cache keys on the ModuleScript INSTANCE and Rojo rewrites
-- Source in place, so a module required earlier keeps answering with its old
-- body however many times the file changes on disk. Cloning forces a re-run --
-- and gives somewhere safe to edit the tier table.
--==============================================================================
local function freshModules(curve: { [string]: number }?): (any, any, { Instance })
	local shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
	local temps: { Instance } = {}

	local cm = shared:FindFirstChild("CreatureModel")
	local sd = shared:FindFirstChild("SeedData")
	assert(cm and sd, "CreatureModel and SeedData must be synced")

	local sdClone = (sd :: ModuleScript):Clone()
	sdClone.Name = "SeedDataSizePreview"

	if curve then
		local source = sdClone.Source
		for name, mul in pairs(curve) do
			--==================================================================
			-- ANCHORED ON THE TIER'S NAME, not on a bare `mul = number`, because
			-- the file has other numbers and a loose pattern that silently
			-- matched none of them would produce a preview of the SHIPPED curve
			-- while claiming to be the candidate. Every replacement is counted
			-- and a miss is fatal.
			--==================================================================
			local pattern = '(name%s*=%s*"' .. name .. '"%s*,%s*mul%s*=%s*)[%d%.]+'
			local patched, hits = string.gsub(source, pattern,
				"%1" .. string.format("%.4f", mul))
			assert(hits == 1, string.format(
				"tier %q: expected exactly 1 mul to patch, found %d", name, hits))
			source = patched
		end
		sdClone.Source = source
	end
	sdClone.Parent = shared
	table.insert(temps, sdClone)

	local cmClone = (cm :: ModuleScript):Clone()
	cmClone.Name = "CreatureModelSizePreview"
	local repointed, hits = string.gsub(cmClone.Source,
		'WaitForChild%("SeedData"%)', 'WaitForChild("SeedDataSizePreview")')
	assert(hits >= 1, "CreatureModel no longer requires SeedData by that name")
	cmClone.Source = repointed
	cmClone.Parent = shared
	table.insert(temps, cmClone)

	return require(cmClone) :: any, require(sdClone) :: any, temps
end

--==============================================================================
-- FURNITURE
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

local function label(text: string, at: CFrame, parent: Instance, colour: Color3,
	wide: number)
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

-- Four rails rather than a filled square: a solid floor would hide the one
-- thing the cell is drawn to show, which is where the feet actually reach.
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

--==============================================================================
-- THE ONLY HONEST UNIT OF SCALE IS A PLAYER
--
-- Studs are abstract and a number beside a 60-stud creature means nothing until
-- there is a person next to it. Blocky R6 proportions at the real R15 standing
-- height, because what is being judged is "how big is that compared to me".
--==============================================================================
local function avatar(at: CFrame, parent: Instance)
	local skin = Color3.fromRGB(255, 204, 102)
	local shirt = Color3.fromRGB(60, 120, 220)
	local pants = Color3.fromRGB(52, 60, 80)
	local legH, torsoH, headH = 2.0, 2.0, 1.2
	part("RefLeg", Vector3.new(0.5, legH, 0.5),
		at * CFrame.new(-0.28, legH * 0.5, 0), pants, parent)
	part("RefLeg", Vector3.new(0.5, legH, 0.5),
		at * CFrame.new(0.28, legH * 0.5, 0), pants, parent)
	part("RefTorso", Vector3.new(1.6, torsoH, 0.8),
		at * CFrame.new(0, legH + torsoH * 0.5, 0), shirt, parent)
	part("RefArm", Vector3.new(0.5, torsoH, 0.5),
		at * CFrame.new(-1.05, legH + torsoH * 0.5, 0), skin, parent)
	part("RefArm", Vector3.new(0.5, torsoH, 0.5),
		at * CFrame.new(1.05, legH + torsoH * 0.5, 0), skin, parent)
	part("RefHead", Vector3.new(1.2, headH, 1.2),
		at * CFrame.new(0, legH + torsoH + headH * 0.5, 0), skin, parent)
	label("YOU (5.2)", at * CFrame.new(0, AVATAR + 1.4, 0), parent,
		Color3.fromRGB(255, 255, 255), 7)
end

-- A thin post at a stated height, for the two references a garden is read
-- against: the corridor wall, and whatever the shipped curve would have built.
local function post(at: CFrame, height: number, parent: Instance, colour: Color3,
	text: string)
	part("RefPost", Vector3.new(0.5, height, 0.5),
		at * CFrame.new(0, height * 0.5, 0), colour, parent, 0.35)
	label(text, at * CFrame.new(0, height + 2.5, 0), parent, colour, 16)
end

--==============================================================================
-- SOMETHING TO STAND ON
--
-- The stage floats at 200 studs so it clears the map, and a creature against
-- open sky has no size at all -- the eye needs a floor and a horizon before it
-- can judge 33 studs against 70. Plain, matte and unlit so it never competes
-- with the thing being judged.
--==============================================================================
local function floor(centre: Vector3, sx: number, sz: number, parent: Instance)
	local f = part("StageFloor", Vector3.new(sx, 1, sz),
		CFrame.new(centre - Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(96, 104, 96), parent)
	-- The ONE collidable part on the stage. Everything else is scenery and must
	-- not be walked into, but the stage floats at 200 studs and a reviewer who
	-- presses Play has to stand on it rather than fall through it.
	f.CanCollide = true
end

function PlantSizeMockupRunner.Clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	print("[Seed/PlantSizeMockup] Cleared " .. FOLDER_NAME .. " from Workspace")
end

--==============================================================================
-- MEASURE WHAT WAS ACTUALLY BUILT
--
-- Off the real parts of the real model, not recomputed from the curve. A
-- measurement derived from the same number the builder was given cannot catch
-- the builder ignoring it.
--==============================================================================
local LEGWORDS = { "Thigh", "Shin", "Sole", "Claw", "Toe", "Leg", "Foot", "Paw", "Root" }
local function measure(m: Model, baseY: number): { [string]: number }
	local minX, maxX, minZ, maxZ, maxY = math.huge, -math.huge, math.huge, -math.huge, -math.huge
	local gMinX, gMaxX, gMinZ, gMaxZ = math.huge, -math.huge, math.huge, -math.huge
	local bodyLow, baseW, parts = math.huge, 0, 0
	local rows: { { lowest: number, minX: number, maxX: number, minZ: number,
		maxZ: number, leg: boolean, name: string } } = {}

	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			if d.Name == "Base" then baseW = math.max(d.Size.X, d.Size.Z) end
			local h = d.Size * 0.5
			local lowest, aX, bX, aZ, bZ = math.huge, math.huge, -math.huge, math.huge, -math.huge
			for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
				local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
				minX = math.min(minX, q.X); maxX = math.max(maxX, q.X)
				minZ = math.min(minZ, q.Z); maxZ = math.max(maxZ, q.Z)
				maxY = math.max(maxY, q.Y); lowest = math.min(lowest, q.Y)
				aX = math.min(aX, q.X); bX = math.max(bX, q.X)
				aZ = math.min(aZ, q.Z); bZ = math.max(bZ, q.Z)
			end end end
			local leg = d:GetAttribute("GroundRoot") == true
			for _, w in ipairs(LEGWORDS) do
				if string.find(d.Name, w) then leg = true end
			end
			table.insert(rows, { lowest = lowest, minX = aX, maxX = bX, minZ = aZ,
				maxZ = bZ, leg = leg, name = d.Name })
		end
	end

	local height = maxY - baseY
	-- The FOOTPRINT is only what touches the floor. A crown 40 studs up may
	-- overhang a neighbour without taking their soil, and those are different
	-- problems with different answers.
	local band = baseY + math.max(height * 0.05, 0.4)
	for _, c in ipairs(rows) do
		if c.name ~= "Base" then
			if c.lowest <= band then
				gMinX = math.min(gMinX, c.minX); gMaxX = math.max(gMaxX, c.maxX)
				gMinZ = math.min(gMinZ, c.minZ); gMaxZ = math.max(gMaxZ, c.maxZ)
			end
			if not c.leg then bodyLow = math.min(bodyLow, c.lowest) end
		end
	end
	return {
		height = height,
		widthX = maxX - minX,
		depthZ = maxZ - minZ,
		footX = if gMaxX > -math.huge then gMaxX - gMinX else 0,
		footZ = if gMaxZ > -math.huge then gMaxZ - gMinZ else 0,
		base = baseW,
		clearance = if bodyLow < math.huge then bodyLow - baseY else 0,
		parts = parts,
	}
end

--==============================================================================
-- A GARDEN THAT LOOKS LIKE A GARDEN
--
-- Generous showroom spacing proves nothing about crowding, so the stage carries
-- two real Level 5 beds on the real 3-column pitch. One is a REALISTIC roll --
-- the tier weights are 53% Tiny and 0.52% Colossal, so a bed of twenty is
-- mostly small with a couple of trophies in it. The other is the worst case
-- nobody will ever roll, twenty Colossals, because "it is fine in the common
-- case" is not an answer to "does it erase the plot".
--==============================================================================
local REALISTIC = {
	1, 1, 1, 2, 1, 1, 3, 1, 2, 1,
	1, 4, 1, 1, 2, 5, 1, 1, 6, 7,
}

local function garden(at: CFrame, parent: Instance, CreatureModel: any, SeedData: any,
	tiers: { number }, title: string, colour: Color3)
	local ROWS, COLS = 7, 3
	local depth = 96.2
	-- The bed outline and the fence line, so overhang is visible as overhang.
	cell(at, parent, colour, 48, depth)
	label(title, at * CFrame.new(0, 3, -depth * 0.5 - 8), parent, colour, 26)
	avatar(at * CFrame.new(-30, 0, -depth * 0.5 + 4), parent)
	post(at * CFrame.new(-38, 0, 0), WALL, parent, Color3.fromRGB(255, 120, 120),
		string.format("CORRIDOR WALL %d", WALL))

	local ids = { "nubkin", "petalpip", "spiretip", "toadcap", "bellchime",
		"cinderpaw", "slagbloom", "cosmospire", "voidpetal", "supernovus" }
	local slot = 0
	for row = 1, ROWS do
		for col = 1, COLS do
			slot += 1
			if slot <= #tiers then
				local sp = SeedData.Get(ids[((slot - 1) % #ids) + 1])
				local x = (col - 2) * CELL_X
				local z = (row - (ROWS + 1) * 0.5) * (depth / ROWS)
				local spot = at * CFrame.new(x, 0, z)
				cell(spot, parent, Color3.fromRGB(90, 80, 70), CELL_X, CELL_Z)
				local m = CreatureModel.Build(sp, tiers[slot],
					CreatureModel.STAGE_GROWN, spot, parent)
				m.Name = string.format("Bed_%02d_%s_T%d", slot, sp.Name, tiers[slot])
			end
		end
	end
end

--==============================================================================
-- BUILD
--==============================================================================
function PlantSizeMockupRunner.Build(opts: { live: boolean? }?): Folder
	PlantSizeMockupRunner.Clear()

	local live = opts ~= nil and opts.live == true
	local CreatureModel, SeedData, temps = freshModules(if live then nil else PROPOSED)

	local root = Instance.new("Folder")
	root.Name = FOLDER_NAME
	-- Archivable = false is what keeps a scratch preview out of the .rbxl. This
	-- place has already lost a session to debris saved into the place file.
	root.Archivable = false
	root:SetAttribute("PreviewOnly", true)
	root:SetAttribute("Curve", if live then "SHIPPED" else "PROPOSED")
	root.Parent = workspace

	--==========================================================================
	-- The floor spans the ladder AND both beds, so the whole stage is one
	-- continuous piece of ground and nothing is judged against sky.
	--==========================================================================
	local spanX = 7 * COL_PITCH + 260
	-- Reaches from the tier-gate pair in front to the two beds behind.
	local spanZ = (5 * ROW_PITCH + 340) - PAIR_Z + 80
	floor(ORIGIN + Vector3.new(spanX * 0.5 - 150, 0,
		(PAIR_Z - 80 + 5 * ROW_PITCH + 340) * 0.5 - 150 + 150), spanX, spanZ, root)

	local ink = if live then Color3.fromRGB(255, 140, 120) else Color3.fromRGB(150, 240, 170)
	label(string.format("%s SIZE CURVE", if live then "LIVE (SeedData)" else "APPROVED TABLE"),
		CFrame.new(ORIGIN + Vector3.new(-70, 30, 0)), root, ink, 40)

	local report: { string } = {}

	--==========================================================================
	-- THE LADDER: one species per row, all seven tiers along it.
	--==========================================================================
	for r, entry in ipairs(LADDER) do
		local sp = SeedData.Get(entry.id)
		assert(sp, "unknown species " .. entry.id)
		local rowZ = (r - 1) * ROW_PITCH
		label(string.format("%s -- %s", string.upper(sp.Name), entry.note),
			CFrame.new(ORIGIN + Vector3.new(-46, 8, rowZ)), root, ink, 30)

		for tier = 1, SeedData.TierCount do
			local at = CFrame.new(ORIGIN + Vector3.new((tier - 1) * COL_PITCH, 0, rowZ))
			local group = Instance.new("Model")
			group.Name = string.format("Ladder_%s_T%d", sp.Name, tier)
			group.Parent = root

			cell(at, group, Color3.fromRGB(120, 110, 96), CELL_X, CELL_Z)
			avatar(at * CFrame.new(-CELL_X * 0.5 - 2.5, 0, 0), group)

			local m = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, at, group)
			m.Name = string.format("Plant_%s_T%d", sp.Name, tier)

			local q = measure(m, at.Position.Y)
			table.insert(report, string.format(
				"%-11s %-9s h %6.1f  wxd %6.1f x %6.1f  foot %6.1f x %6.1f  base %5.2f  clr %+5.2f",
				sp.Id, SeedData.TierName(tier), q.height, q.widthX, q.depthZ,
				q.footX, q.footZ, q.base, q.clearance))

			label(string.format("%s\n%.1f studs\n%.0f%% of a wall",
				string.upper(SeedData.TierName(tier)), q.height, q.height / WALL * 100),
				at * CFrame.new(0, -3.5, CELL_Z * 0.5 + 2), group, ink, 14)
		end

		-- The wall, and what the shipped curve would have put here, as posts.
		post(CFrame.new(ORIGIN + Vector3.new(7 * COL_PITCH - 10, 0, rowZ)), WALL, root,
			Color3.fromRGB(255, 120, 120), string.format("WALL %d", WALL))
	end

	--==========================================================================
	-- THE AURA BENCH: five biomes, then the tier gate.
	--==========================================================================
	label("AURA BENCH -- ONE COLOSSAL PER BIOME (arcs are client-side; press Play)",
		CFrame.new(ORIGIN + Vector3.new(-60, 14, BENCH_Z)), root, ink, 46)
	for i, pick in ipairs(AURA_BENCH) do
		local sp = SeedData.Get(pick.id)
		assert(sp, "unknown species " .. pick.id)
		local at = CFrame.new(ORIGIN + Vector3.new((i - 1) * BENCH_PITCH, 0, BENCH_Z))
		local group = Instance.new("Model")
		group.Name = string.format("Aura_%s_%s", pick.biome, sp.Name)
		group.Parent = root
		cell(at, group, Color3.fromRGB(120, 110, 96), CELL_X, CELL_Z)
		avatar(at * CFrame.new(-CELL_X * 0.5 - 2.5, 0, 0), group)
		local m = CreatureModel.Build(sp, SeedData.TierCount, CreatureModel.STAGE_GROWN,
			at, group)
		m.Name = string.format("Aura_%s_Colossal", sp.Name)
		label(string.format("%s\n%s", string.upper(pick.biome), string.upper(sp.Name)),
			at * CFrame.new(0, -3.5, CELL_Z * 0.5 + 2), group, ink, 15)
	end

	--==========================================================================
	-- TITAN BESIDE COLOSSAL, same species, same cell size. If the Titan ever
	-- crackles, the tier gate is broken and this is the view that says so.
	--==========================================================================
	label("TIER GATE -- TITAN (left) MUST STAY DARK, COLOSSAL (right) CRACKLES",
		CFrame.new(ORIGIN + Vector3.new(-60, 14, PAIR_Z)), root, ink, 46)
	for i, tier in ipairs({ SeedData.TierCount - 1, SeedData.TierCount }) do
		local sp = SeedData.Get("bellchime")
		local at = CFrame.new(ORIGIN + Vector3.new((i - 1) * BENCH_PITCH, 0, PAIR_Z))
		local group = Instance.new("Model")
		group.Name = string.format("Gate_%s", SeedData.TierName(tier))
		group.Parent = root
		cell(at, group, Color3.fromRGB(120, 110, 96), CELL_X, CELL_Z)
		avatar(at * CFrame.new(-CELL_X * 0.5 - 2.5, 0, 0), group)
		local m = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, at, group)
		m.Name = string.format("Gate_%s_T%d", sp.Name, tier)
		label(string.upper(SeedData.TierName(tier)),
			at * CFrame.new(0, -3.5, CELL_Z * 0.5 + 2), group, ink, 15)
	end

	--==========================================================================
	-- TWO REAL BEDS, on the real pitch, behind the ladder.
	--==========================================================================
	local bedZ = 5 * ROW_PITCH + 70
	garden(CFrame.new(ORIGIN + Vector3.new(0, 0, bedZ)), root, CreatureModel, SeedData,
		REALISTIC, "LEVEL 5 BED -- A REALISTIC ROLL (20 plants)",
		Color3.fromRGB(150, 240, 170))

	local worst = {}
	for i = 1, 20 do worst[i] = SeedData.TierCount end
	garden(CFrame.new(ORIGIN + Vector3.new(190, 0, bedZ)), root, CreatureModel, SeedData,
		worst, "LEVEL 5 BED -- TWENTY COLOSSALS (worst case, 0.52% each)",
		Color3.fromRGB(255, 190, 120))

	--==========================================================================
	-- TAG THEM AS PLANTED, WHICH IS THE WHOLE REASON THEY ANIMATE
	--
	-- `CreatureModel.Build` does NOT tag -- PlantService does, at the moment a
	-- pod becomes a plant in somebody's soil. That is a good gate and this file
	-- is not changing it: it is exactly what keeps the Colossal aura off carried
	-- Tools, shop viewports and inventory thumbnails, none of which are ever
	-- tagged.
	--
	-- But it means a preview built straight from the builder is inert: PlantSway
	-- never sees it, so nothing sways, nothing walks and no arc ever fires. So
	-- the stage tags its own grown specimens, which is what makes this a preview
	-- of a PLANTED plant rather than of a statue.
	--
	-- Checked rather than assumed: only models the builder actually stamped, and
	-- only at the grown stage.
	--==========================================================================
	local tagged = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("SpeciesId")
			and d:GetAttribute("Stage") == CreatureModel.STAGE_GROWN then
			CollectionService:AddTag(d, "Planted")
			tagged += 1
		end
	end

	for _, t in ipairs(temps) do
		t:Destroy()
	end

	print(string.format(
		"[Seed/PlantSizeMockup] %s built with the %s curve; %d specimen(s) tagged Planted.",
		FOLDER_NAME, if live then "LIVE" else "APPROVED", tagged))
	for _, line in ipairs(report) do
		print("  " .. line)
	end
	return root
end

--==============================================================================
-- THE CURVE AS A TABLE, for the handoff and for a sanity read before building.
--==============================================================================
function PlantSizeMockupRunner.Curve(): string
	local shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
	local SeedData = require(shared:WaitForChild("SeedData")) :: any
	local out = { string.format("%-9s %10s %10s %8s %8s", "tier", "live", "approved",
		"step", "match") }
	local prev: number? = nil
	for _, t in ipairs(SeedData.Tiers) do
		local want = PROPOSED[t.name]
		out[#out + 1] = string.format("%-9s %10.3f %10.3f %8s %7.2f%%",
			t.name, t.mul, want,
			if prev then string.format("x%.2f", want / prev) else "--",
			want / t.mul * 100)
		prev = want
	end
	return table.concat(out, "\n")
end

return PlantSizeMockupRunner
