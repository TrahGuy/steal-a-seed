--!nocheck
--==============================================================================
-- SUNCROWN MESH PREVIEW -- a Studio inspection tool for the AI-generated mesh
--
-- Not game code; nothing in the game loads it. Run it in EDIT mode:
--
--     loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/art/suncrown_mesh_preview.luau", true))()
--
-- (with `python -m http.server 8731` running at the repo root), or paste the
-- whole file into the Command Bar. Options are optional and go in a global
-- before the run:
--
--     _G.SuncrownMeshPreview = { tier = 1, fit = "frame" }
--
--   tier    the size tier to compare at. Tier 1 is the base tier, and the only
--           one whose frame height is the sheet's 6.51; tier 4 (Mega) frames at
--           17.25
--   fit     "frame" scales the mesh to that tier's frame height -- the sheet's
--           number. "procedural" scales it to the height the current
--           procedural Suncrown actually stands at that tier, which is not the
--           frame: 5.28 at tier 1, 18.70 at tier 4
--   origin  where the pair stands. The world origin is the Hub's sell deck, so
--           the default is open sky over a temporary ground slab
--   source  the name of the import to use, ahead of the defaults below
--   json    where to build a stand-in from when nothing has been imported (see
--           below); false turns that off
--   turn    degrees about Y applied to JSON vertices. 180 by default: the
--           generator's front is +Z and a plant's is -Z
--   rebuild true to rebuild the JSON stand-in even if one is already standing
--
-- WHERE THE MESH COMES FROM
--   1. An import in Workspace or ReplicatedStorage.Assets, named
--      SuncrownMeshPreview or suncrownmeshgenerated. A real import -- one with
--      an uploaded MeshId -- wins over a stand-in.
--      Observed on 2026-09-11: the 3D Importer took the 121,500-triangle FBX
--      down to 19,999 triangles by itself, read its centimetres as studs (it
--      stood 190 studs tall) and left the part unanchored.
--   2. Otherwise a stand-in: a triangle list served as JSON ({positions,
--      triangles}, in metres, Y up), built into an EditableMesh and made a
--      MeshPart with AssetService:CreateMeshPartAsync. That tests a mesh with
--      no importer at all. It is NOT an asset: it does not save with the place
--      and cannot be published until it is uploaded, so it is marked
--      Archivable = false. The default JSON is a Blender collapse decimation
--      of the FBX to 19,500 triangles, kept beside the FBX and not in git.
--
-- WHAT IT DOES
--   * works on a CLONE of the import, so the import is never moved, scaled or
--     reparented;
--   * reports the import: size, lowest point, MeshParts, triangles, textures,
--     SurfaceAppearance and any unanchored parts;
--   * sits the clone's lowest point on the ground, gives it the invisible 0.06
--     `Base` pivot every CreatureModel plant has, and scales it;
--   * builds the procedural Suncrown beside it through CreatureModel.Build at
--     the same tier, from fresh module Source, because Studio caches require;
--   * measures both, prints the comparison and points the camera at the pair.
--
-- Everything the comparison builds lives in Workspace.SuncrownMeshComparison,
-- Archivable = false and rebuilt on every run.
--==============================================================================

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local options = if typeof(_G.SuncrownMeshPreview) == "table" then _G.SuncrownMeshPreview else {}
local TIER = options.tier or 1
local FIT = options.fit or "frame"
local ORIGIN = options.origin or Vector3.new(900, 150, -600)
local IMPORT_AT = options.importAt or (ORIGIN + Vector3.new(60, 0, 0))
local JSON_URL = if options.json == nil
	then "http://127.0.0.1:8731/AI%20mesh%20generated/suncrownmesh_decimated_19k.json"
	else options.json
local TURN = math.rad(options.turn or 180)
local STUDS_PER_METRE = 100 / 28
local FOLDER_NAME = "SuncrownMeshComparison"
local IMPORT_NAME = "SuncrownMeshPreview"
-- Roblox's per-mesh ceiling, for imported meshes and EditableMeshes alike.
local TRIANGLE_LIMIT = 20000

local report = {}
local function say(fmt, ...)
	local line = string.format(fmt, ...)
	print(line)
	table.insert(report, line)
end

--------------------------------------------------------------------------------
-- Studio evaluates a ModuleScript once per datamodel and keeps the result, so
-- a plain require here can hand back a CreatureModel from before the latest
-- sync. This is tools/tests/run.luau's loader: every module in the tree comes
-- fresh from its Source, memoised for the run.
--------------------------------------------------------------------------------
local cache, loading = {}, {}
local function freshRequire(target)
	if typeof(target) ~= "Instance" or not target:IsA("ModuleScript") then
		return require(target)
	end
	if cache[target] ~= nil then
		return cache[target]
	end
	assert(not loading[target], "circular require through " .. target:GetFullName())
	loading[target] = true
	local chunk, err = loadstring(target.Source, "=" .. target.Name)
	assert(chunk, target:GetFullName() .. ": " .. tostring(err))
	setfenv(chunk, setmetatable({ script = target, require = freshRequire }, { __index = getfenv(1) }))
	local value = chunk()
	loading[target] = nil
	cache[target] = value
	return value
end

local function eachPart(root, fn)
	if root:IsA("BasePart") then
		fn(root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			fn(d)
		end
	end
end

-- World extents over every part's rotated corners. A MeshPart's Size is its
-- mesh's box, so an unrotated one reports its true lowest vertex.
local function bounds(root, skipBase)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	eachPart(root, function(p)
		if skipBase and p.Name == "Base" then
			return
		end
		local h = p.Size * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local q = (p.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
					lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
					hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
				end
			end
		end
	end)
	return lo, hi
end

-- Triangles. A stand-in is backed by its EditableMesh and is counted directly;
-- an uploaded mesh is opened through EditableMesh, which Studio only allows for
-- meshes the signed-in user may edit. nil means "read it off the 3D Importer",
-- not zero.
local function triangleCount(mp)
	local ok, n = pcall(function()
		local content = mp.MeshContent
		if content.SourceType == Enum.ContentSourceType.Object and content.Object then
			return #content.Object:GetFaces()
		end
		local editable = AssetService:CreateEditableMeshAsync(Content.fromUri(mp.MeshId))
		local faces = #editable:GetFaces()
		editable:Destroy()
		return faces
	end)
	return if ok then n else nil
end

-- A copy of something that may be marked Archivable = false, which Clone
-- refuses: the flags are lifted for the copy and put straight back.
local function cloneOf(inst)
	local lifted = {}
	local function lift(x)
		if not x.Archivable then
			x.Archivable = true
			table.insert(lifted, x)
		end
	end
	lift(inst)
	for _, d in ipairs(inst:GetDescendants()) do
		lift(d)
	end
	local copy = inst:Clone()
	for _, x in ipairs(lifted) do
		x.Archivable = false
	end
	return copy
end

local function meshOf(inst)
	return if inst:IsA("MeshPart") then inst else inst:FindFirstChildWhichIsA("MeshPart", true)
end

-- An uploaded import has a MeshId; a stand-in built here has none.
local function isStandIn(inst)
	local mesh = meshOf(inst)
	return mesh ~= nil and mesh.MeshId == ""
end

local function lookup(name)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local found = workspace:FindFirstChild(name) or (assets and assets:FindFirstChild(name))
	return if found and (found:IsA("Model") or found:IsA("BasePart")) then found else nil
end

local function findImport()
	if options.source then
		return lookup(options.source)
	end
	local standIn = nil
	for _, name in ipairs({ IMPORT_NAME, "suncrownmeshgenerated", "SuncrownMesh" }) do
		local found = lookup(name)
		if found then
			if not isStandIn(found) then
				return found
			end
			standIn = standIn or found
		end
	end
	return standIn
end

-- The stand-in: vertices turned to face -Z, scaled at 28 cm a stud, and
-- centred on their own box, so the MeshPart's box and its geometry agree
-- whether or not the engine re-centres a mesh.
local function buildFromJson(url)
	local data = HttpService:JSONDecode(HttpService:GetAsync(url, true))
	local positions, triangles = data.positions, data.triangles
	local vertexCount, triangleTotal = #positions // 3, #triangles // 3
	assert(triangleTotal <= TRIANGLE_LIMIT,
		string.format("%d triangles; a mesh may carry at most %d", triangleTotal, TRIANGLE_LIMIT))

	local c, s = math.cos(TURN), math.sin(TURN)
	local points = table.create(vertexCount)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for i = 0, vertexCount - 1 do
		local x, y, z = positions[i * 3 + 1], positions[i * 3 + 2], positions[i * 3 + 3]
		local p = Vector3.new(x * c + z * s, y, -x * s + z * c) * STUDS_PER_METRE
		points[i + 1] = p
		lo = Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z))
		hi = Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z))
	end
	local centre = (lo + hi) * 0.5

	local editable = AssetService:CreateEditableMesh()
	assert(editable, "the editable memory budget is exhausted")
	local ids = table.create(vertexCount)
	for i = 1, vertexCount do
		ids[i] = editable:AddVertex(points[i] - centre)
	end
	for t = 0, triangleTotal - 1 do
		editable:AddTriangle(ids[triangles[t * 3 + 1] + 1], ids[triangles[t * 3 + 2] + 1],
			ids[triangles[t * 3 + 3] + 1])
	end
	-- New vertices carry automatically computed normals: smooth shading.

	local part = AssetService:CreateMeshPartAsync(Content.fromObject(editable), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Automatic,
	})
	part.Name = "SuncrownMesh"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	-- The FBX carries no texture, so one flat colour stands in for it.
	part.Color = Color3.fromRGB(226, 178, 72)
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = CFrame.new(IMPORT_AT + Vector3.new(0, (hi.Y - lo.Y) * 0.5, 0))
	part.Archivable = false

	local model = Instance.new("Model")
	model.Name = IMPORT_NAME
	model.Archivable = false
	part.Parent = model
	model.Parent = workspace
	say("Built the stand-in %s from %s: %d vertices, %d triangles, turned %d degrees", model:GetFullName(), url,
		vertexCount, triangleTotal, math.round(math.deg(TURN)))
	return model
end

-- Moves a model so its footprint is centred over `at` and its lowest point is
-- exactly at `at.Y`.
local function seat(model, at)
	local lo, hi = bounds(model, true)
	local centre = (lo + hi) * 0.5
	model:PivotTo(model:GetPivot() + Vector3.new(at.X - centre.X, at.Y - lo.Y, at.Z - centre.Z))
end

--==============================================================================
-- 1. THE IMPORT
--==============================================================================
local source = findImport()
if source and options.rebuild and JSON_URL and isStandIn(source) then
	source:Destroy()
	source = nil
end
if not source and JSON_URL then
	source = buildFromJson(JSON_URL)
end
assert(source, "No imported Suncrown mesh in Workspace or ReplicatedStorage.Assets, and no JSON to build one "
	.. "from. Import the FBX with the 3D Importer and name the result SuncrownMeshPreview.")

local rawLo, rawHi = bounds(source, false)
local rawSize = rawHi - rawLo
say("=== Suncrown mesh, as imported: %s ===", source:GetFullName())
say("Size: %.2f W x %.2f H x %.2f D", rawSize.X, rawSize.Y, rawSize.Z)
say("Ground offset: lowest point at Y = %.4f", rawLo.Y)

local meshParts, counted, unreadable, textured, appearances, heaviest, loose = 0, 0, 0, 0, 0, 0, 0
eachPart(source, function(p)
	if not p.Anchored then
		loose += 1
	end
	if not p:IsA("MeshPart") then
		return
	end
	meshParts += 1
	local n = triangleCount(p)
	if n then
		counted += n
		heaviest = math.max(heaviest, n)
	else
		unreadable += 1
	end
	local appearance = p:FindFirstChildOfClass("SurfaceAppearance")
	if p.TextureID ~= "" then
		textured += 1
	end
	if appearance then
		appearances += 1
	end
	say("  %s: %.2f x %.2f x %.2f, %s triangles, RenderFidelity %s, CollisionFidelity %s, TextureID %s%s",
		p.Name, p.Size.X, p.Size.Y, p.Size.Z, if n then tostring(n) else "?", p.RenderFidelity.Name,
		p.CollisionFidelity.Name, if p.TextureID ~= "" then p.TextureID else "none",
		if appearance then ", SurfaceAppearance" else "")
end)
say("%d MeshPart(s); %d triangles counted%s; %d with a TextureID, %d with a SurfaceAppearance",
	meshParts, counted,
	if unreadable > 0 then string.format(", %d MeshPart(s) not readable here", unreadable) else "",
	textured, appearances)
if heaviest > TRIANGLE_LIMIT then
	say("WARNING: one MeshPart carries %d triangles, over the %d a mesh may have.", heaviest, TRIANGLE_LIMIT)
end
if loose > 0 then
	say("WARNING: %d part(s) of the import are unanchored, so in Play they fall. Anchor the import or keep it "
		.. "in ReplicatedStorage.Assets.", loose)
end

--==============================================================================
-- 2. THE STAGE, AND THE PROCEDURAL SUNCROWN AT THE SAME TIER
--==============================================================================
local old = workspace:FindFirstChild(FOLDER_NAME)
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = FOLDER_NAME
folder.Archivable = false
folder.Parent = workspace

local ground = Instance.new("Part")
ground.Name = "PreviewGround"
ground.Anchored = true
ground.Color = Color3.fromRGB(196, 164, 112)
ground.Material = Enum.Material.SmoothPlastic
ground.Parent = folder

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = freshRequire(Shared:WaitForChild("SeedData"))
local CreatureModel = freshRequire(Shared:WaitForChild("CreatureModel"))
local species = SeedData.Get("suncrown")
assert(species, "SeedData has no suncrown")
local frameHeight = SeedData.FrameHeight(species, TIER)

local procedural = CreatureModel.Build(species, TIER, CreatureModel.STAGE_GROWN, CFrame.new(ORIGIN), folder)
procedural.Name = "Suncrown_Procedural_Tier" .. TIER
local pLo, pHi = bounds(procedural, true)
local proceduralSize = pHi - pLo
local proceduralParts = 0
eachPart(procedural, function()
	proceduralParts += 1
end)

--==============================================================================
-- 3. THE MESH CANDIDATE: A CLONE, SEATED, GIVEN A BASE, AND SCALED
--==============================================================================
local candidate
if source:IsA("Model") then
	candidate = cloneOf(source)
else
	candidate = Instance.new("Model")
	local copy = cloneOf(source)
	assert(copy, "the import could not be cloned")
	copy.Parent = candidate
end
assert(candidate, "the import could not be cloned")
candidate.Name = "Suncrown_Mesh_Candidate"
candidate.Archivable = false
eachPart(candidate, function(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Archivable = false
end)

-- The pivot four systems reach for by name: CreatureModel's is a 0.06 slab with
-- its underside on the soil.
local base = candidate:FindFirstChild("Base")
if not (base and base:IsA("BasePart")) then
	base = Instance.new("Part")
	base.Name = "Base"
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Archivable = false
	base.Parent = candidate
end
local function placeBase(at)
	base.Size = Vector3.new(2, 0.06, 2)
	base.CFrame = CFrame.new(at + Vector3.new(0, 0.03, 0))
end
candidate.Parent = folder
seat(candidate, ORIGIN)
placeBase(ORIGIN)
candidate.PrimaryPart = base

local _, seatedHi = bounds(candidate, true)
local importedHeight = seatedHi.Y - ORIGIN.Y
local targetHeight = if FIT == "procedural" then proceduralSize.Y else frameHeight
local factor = targetHeight / importedHeight
candidate:ScaleTo(candidate:GetScale() * factor)
seat(candidate, ORIGIN)
placeBase(ORIGIN)

--==============================================================================
-- 4. SIDE BY SIDE, MEASURED
--==============================================================================
local mLo, mHi = bounds(candidate, true)
local meshSize = mHi - mLo
local gap = math.max(proceduralSize.X, meshSize.X) * 0.5 + 1.5
-- Procedural on +X and the mesh on -X, as the brief lays them out.
procedural:PivotTo(procedural:GetPivot() + Vector3.new(gap, 0, 0))
candidate:PivotTo(candidate:GetPivot() + Vector3.new(-gap, 0, 0))
mLo, mHi = bounds(candidate, true)
pLo, pHi = bounds(procedural, true)

local tallest = math.max(proceduralSize.Y, meshSize.Y)
local deepest = math.max(proceduralSize.Z, meshSize.Z)
local span = gap * 2 + math.max(proceduralSize.X, meshSize.X)
ground.Size = Vector3.new(span + 8, 1, deepest + 12)
ground.CFrame = CFrame.new(ORIGIN - Vector3.new(0, 0.5, 0))

say("=== Side by side at tier %d; frame height %.2f studs ===", TIER, frameHeight)
say("Procedural (on +X): %d parts, %.2f W x %.2f H x %.2f D, lowest %.4f",
	proceduralParts, proceduralSize.X, proceduralSize.Y, proceduralSize.Z, pLo.Y - ORIGIN.Y)
say("Mesh (on -X): imported %.2f tall, scaled x%.4f to the %s height %.2f -> %.2f W x %.2f H x %.2f D, lowest %.4f",
	importedHeight, factor, FIT, targetHeight, meshSize.X, meshSize.Y, meshSize.Z, mLo.Y - ORIGIN.Y)
say("Mesh against procedural: width %.0f%%, height %.0f%%, depth %.0f%%",
	meshSize.X / proceduralSize.X * 100, meshSize.Y / proceduralSize.Y * 100, meshSize.Z / proceduralSize.Z * 100)
say("Spawned the side-by-side comparison in Workspace.%s. Target height: %.2f studs.", FOLDER_NAME, targetHeight)

-- The front of a plant is -Z: stand the camera there, raised and a little to
-- the side. An Edit camera moves only when Focus moves with it.
local camera = workspace.CurrentCamera
local focus = ORIGIN + Vector3.new(0, tallest * 0.5, 0)
camera.CFrame = CFrame.lookAt(focus + Vector3.new(span * 0.30, tallest * 0.35, -span * 1.15), focus)
camera.Focus = CFrame.new(focus)

return table.concat(report, "\n")
