--!strict
-- Steal The Artifact :: MapService
--
-- Builds the entire map from code, every boot, from GameConfig.Map and
-- ZoneData. Nothing in this game is placed by hand.
--
--==============================================================================
-- WHY THE MAP IS CODE
--
-- Both predecessor projects on this machine have the same open item in their
-- handoff, years of work apart: the map exists only inside a .rbxl and cannot
-- be reproduced. Cloud Cafe's audit calls it "the thing a lost file would
-- destroy"; Steal the Ore and Forge still lists its 3,204-part foundry as "the
-- only remaining unreproducible artifact".
--
-- The cost of building in code is that it will never look hand-crafted. The
-- return is that the map is in git, diffable, identical on every server, and
-- moving the whole island is one number. For a blocky studded simulator that is
-- a trade worth making every time.
--
-- REBUILT, NOT PATCHED. Init destroys any previous ArtifactMap and builds a
-- fresh one, so there is no reconcile step, no half-migrated map, and no way for
-- an old shape to survive a config change. Rojo syncs code, this rebuilds from
-- it, and the two never disagree.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ZoneData = require(Shared:WaitForChild("ZoneData"))

local MapService = {}
-- First. Every other service reads the world this builds.
MapService.Priority = 1

local MAP = GameConfig.Map
local BASE = GameConfig.Base
local Y = MAP.BaseY

local mapFolder: Folder? = nil

local function log(message: string)
	print("[Artifact/MapService] " .. message)
end

--==============================================================================
-- THE ONE PART HELPER
--
-- Every part in the map goes through here, which is what keeps the studded
-- plastic look consistent and stops a stray SmoothPlastic appearing because one
-- call site forgot. Anchored and non-collidable by default are both deliberate:
-- a map part that is accidentally unanchored falls through the world, and one
-- that is accidentally collidable blocks a player somewhere you will not find
-- for a week.
--==============================================================================
type PartOpts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
	parent: Instance,
}

local function build(opts: PartOpts): BasePart
	local p = Instance.new("Part")
	p.Name = opts.name
	p.Size = opts.size
	p.CFrame = opts.cframe
	p.Color = opts.color
	p.Material = opts.material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = opts.collide ~= false
	p.Transparency = opts.transparency or 0
	if opts.shape then
		p.Shape = opts.shape
	end
	-- The classic look the brief asks for. Studs on top, smooth everywhere else
	-- so vertical faces do not turn into a texture soup at distance.
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = opts.parent
	return p
end

--==============================================================================
-- A BASE
--
-- Every component the blueprint names is built now, even the ones no phase uses
-- yet. A CoinCollector that exists as an inert pad in Phase 1 is a thing Phase 4
-- attaches behaviour to; one that does not exist is a thing Phase 4 has to
-- design, place and re-test the map for.
--==============================================================================
local BASE_COLORS = {
	Color3.fromRGB(232, 92, 92),
	Color3.fromRGB(238, 152, 66),
	Color3.fromRGB(240, 206, 76),
	Color3.fromRGB(118, 206, 106),
	Color3.fromRGB(88, 194, 196),
	Color3.fromRGB(92, 146, 232),
	Color3.fromRGB(158, 116, 226),
	Color3.fromRGB(232, 116, 182),
}

local function buildBase(id: number, cframe: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = string.format("%s%02d", BASE.NamePrefix, id)
	model:SetAttribute(GameConfig.Attributes.BaseId, id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model.Parent = parent

	local tint = BASE_COLORS[((id - 1) % #BASE_COLORS) + 1]
	local size = BASE.Size

	local floor = build({
		name = "Base",
		size = Vector3.new(size, BASE.FloorThickness, size),
		cframe = cframe * CFrame.new(0, -BASE.FloorThickness * 0.5, 0),
		color = tint,
		parent = model,
	})
	model.PrimaryPart = floor

	-- A low rim, so the edge of a base reads from the ground rather than only
	-- from above. Four thin parts beats a hollow union.
	local half = size * 0.5
	for _, spec in ipairs({
		{ Vector3.new(size, 2, 2), CFrame.new(0, 1, -half) },
		{ Vector3.new(size, 2, 2), CFrame.new(0, 1, half) },
		{ Vector3.new(2, 2, size), CFrame.new(-half, 1, 0) },
		{ Vector3.new(2, 2, size), CFrame.new(half, 1, 0) },
	}) do
		build({
			name = "Rim",
			size = spec[1],
			cframe = cframe * spec[2],
			color = Color3.fromRGB(250, 250, 250),
			collide = false,
			parent = model,
		})
	end

	--== SPAWN ==--
	-- A real SpawnLocation, not a marker, so Roblox's own respawn machinery can
	-- be pointed at it via Player.RespawnLocation. Neutral = false with a
	-- unique TeamColor would auto-assign teams we do not have; Neutral stays
	-- true and BaseService assigns RespawnLocation explicitly.
	local pad = Instance.new("SpawnLocation")
	pad.Name = BASE.SpawnPadName
	pad.Size = Vector3.new(12, 1, 12)
	pad.CFrame = cframe * CFrame.new(0, 0.5, half - 12)
	pad.Color = tint
	pad.Material = Enum.Material.Neon
	pad.Anchored = true
	pad.CanCollide = true
	pad.Neutral = true
	pad.Enabled = false -- BaseService turns on only the owner's, via RespawnLocation
	pad.Duration = 0
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.Parent = model
	CollectionService:AddTag(pad, GameConfig.Tags.BaseSpawn)

	--== ARTIFACT DISPLAY ==--
	-- The museum. A plinth plus one pedestal per starting slot; Phase 4 grows
	-- the count when the base is upgraded.
	local display = Instance.new("Model")
	display.Name = BASE.DisplayName
	display.Parent = model
	CollectionService:AddTag(display, GameConfig.Tags.ArtifactDisplay)

	local plinth = build({
		name = "Plinth",
		size = Vector3.new(size - 16, 2, 10),
		cframe = cframe * CFrame.new(0, 1, -half + 10),
		color = Color3.fromRGB(238, 238, 242),
		parent = display,
	})
	display.PrimaryPart = plinth

	local slots = BASE.StartingDisplaySlots
	for slot = 1, slots do
		local fx = (slot - (slots + 1) * 0.5) * 8
		local pedestal = build({
			name = string.format("Slot%02d", slot),
			size = Vector3.new(5, 3, 5),
			cframe = cframe * CFrame.new(fx, 3.5, -half + 10),
			color = Color3.fromRGB(206, 206, 214),
			parent = display,
		})
		pedestal:SetAttribute("SlotIndex", slot)
		pedestal:SetAttribute(GameConfig.Attributes.ArtifactInstanceId, "")
	end

	--== COIN COLLECTOR ==--
	local collector = build({
		name = BASE.CollectorName,
		size = Vector3.new(9, 6, 9),
		cframe = cframe * CFrame.new(-half + 11, 3, 0),
		color = Color3.fromRGB(240, 206, 76),
		material = Enum.Material.Neon,
		parent = model,
	})
	CollectionService:AddTag(collector, GameConfig.Tags.CoinCollector)

	--== UPGRADE AREA ==--
	local upgrade = build({
		name = BASE.UpgradeAreaName,
		size = Vector3.new(9, 6, 9),
		cframe = cframe * CFrame.new(half - 11, 3, 0),
		color = Color3.fromRGB(118, 206, 106),
		material = Enum.Material.Neon,
		parent = model,
	})
	CollectionService:AddTag(upgrade, GameConfig.Tags.UpgradeArea)

	--== OWNER SIGN ==--
	local post = build({
		name = BASE.SignName,
		size = Vector3.new(14, 6, 1),
		cframe = cframe * CFrame.new(0, 11, -half + 4),
		color = Color3.fromRGB(52, 48, 62),
		parent = model,
	})

	local surface = Instance.new("SurfaceGui")
	surface.Name = "SignFace"
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 48
	surface.LightInfluence = 0
	surface.Parent = post

	local label = Instance.new("TextLabel")
	label.Name = BASE.SignOwnerLabelName
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = BASE.UnclaimedText
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = surface

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(24, 20, 30)
	stroke.Parent = label

	--== PROTECTION ZONE ==--
	-- Invisible, non-collidable, and TAGGED. Phase 3's combat rules read the
	-- tag; nothing before then touches it. It is built now because a safe zone
	-- retro-fitted to a map is a safe zone whose edges do not line up with the
	-- base it is meant to protect.
	local shield = build({
		name = BASE.ProtectionZoneName,
		size = Vector3.new(size + 8, 40, size + 8),
		cframe = cframe * CFrame.new(0, 20, 0),
		color = Color3.fromRGB(120, 220, 255),
		collide = false,
		transparency = 1,
		parent = model,
	})
	shield.CanQuery = false
	CollectionService:AddTag(shield, GameConfig.Tags.ProtectionZone)

	--== RUNTIME ==--
	-- Everything a session creates on this base goes in here, so releasing the
	-- base is one folder clear rather than a hunt for stray instances.
	local runtime = Instance.new("Folder")
	runtime.Name = BASE.RuntimeFolderName
	runtime.Parent = model

	return model
end

--==============================================================================
-- A ZONE
--==============================================================================
local function buildZone(zone: ZoneData.Zone, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = zone.Id
	model:SetAttribute("ZoneId", zone.Id)
	model:SetAttribute("DisplayName", zone.DisplayName)
	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.ArtifactZone)

	local floor = build({
		name = "Ground",
		size = Vector3.new(zone.Size.X, 3, zone.Size.Z),
		cframe = CFrame.new(zone.Position) * CFrame.new(0, -1.5, 0),
		color = zone.Color,
		parent = model,
	})
	model.PrimaryPart = floor

	for index, cf in ipairs(ZoneData.PedestalCFrames(zone)) do
		local pedestal = build({
			name = string.format("Pedestal%02d", index),
			size = Vector3.new(6, 5, 6),
			cframe = cf * CFrame.new(0, 2.5, 0),
			color = Color3.fromRGB(226, 222, 210),
			parent = model,
		})
		pedestal:SetAttribute("ZoneId", zone.Id)
		pedestal:SetAttribute("PedestalIndex", index)
		pedestal:SetAttribute(GameConfig.Attributes.ArtifactInstanceId, "")
		CollectionService:AddTag(pedestal, GameConfig.Tags.ArtifactPedestal)

		-- The spot an artifact model sits on. An Attachment rather than a
		-- marker part: it costs no physics, no rendering and no part budget,
		-- and Phase 2 only needs a CFrame.
		local mount = Instance.new("Attachment")
		mount.Name = "Mount"
		mount.Position = Vector3.new(0, 3.4, 0)
		mount.Parent = pedestal
	end

	return model
end

--==============================================================================
-- BUILD
--==============================================================================
function MapService.Init()
	local existing = workspace:FindFirstChild(MAP.FolderName)
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = MAP.FolderName
	folder.Parent = workspace
	mapFolder = folder

	local environment = Instance.new("Folder")
	environment.Name = MAP.EnvironmentFolderName
	environment.Parent = folder

	--== THE SAFE SPAWN ISLAND ==--
	local island = build({
		name = MAP.SpawnName,
		size = Vector3.new(MAP.SpawnRadius * 2, 4, MAP.SpawnRadius * 2),
		cframe = CFrame.new(0, Y - 2, 0),
		color = Color3.fromRGB(244, 240, 228),
		parent = environment,
	})
	CollectionService:AddTag(island, GameConfig.Tags.ProtectionZone)

	-- Where a player goes when every base is taken. Named and findable rather
	-- than a hardcoded coordinate in a service, because the day the map moves,
	-- a hardcoded fallback is the one thing that stays behind.
	local overflow = build({
		name = MAP.OverflowSpawnName,
		size = Vector3.new(10, 1, 10),
		cframe = CFrame.new(0, Y + 0.5, 0),
		color = Color3.fromRGB(255, 255, 255),
		collide = false,
		transparency = 1,
		parent = environment,
	})
	overflow.CanQuery = false

	--== THE BASES ==--
	local bases = Instance.new("Folder")
	bases.Name = MAP.BasesFolderName
	bases.Parent = folder

	-- HALF A STEP OF ROTATION. With eight bases at 45 degrees apart starting at
	-- zero, two of them sit dead on the Z axis -- directly in front of a zone,
	-- with a materially shorter run home than the other six. Offsetting the
	-- whole ring by half a step puts every base the same distance off-axis, so
	-- no spawn is a better spawn.
	local step = math.pi * 2 / GameConfig.MaxBases
	for id = 1, GameConfig.MaxBases do
		local angle = (id - 1) * step + step * 0.5
		local x = math.sin(angle) * MAP.BaseRingRadius
		local z = math.cos(angle) * MAP.BaseRingRadius
		-- Facing the middle, so every owner sign is readable from the spawn
		-- island and every base's display faces the traffic.
		local facing = CFrame.lookAt(Vector3.new(x, Y, z), Vector3.new(0, Y, 0))
		buildBase(id, facing, bases)
	end

	--== THE ZONES ==--
	local zones = Instance.new("Folder")
	zones.Name = MAP.ZonesFolderName
	zones.Parent = folder

	for _, zone in ipairs(ZoneData.Zones) do
		buildZone(zone, zones)
	end

	--== CLEARANCE CHECK ==--
	-- The geometry has three independent numbers -- BaseRingRadius, Base.Size
	-- and each zone's Size.Z -- and nothing stops a future edit to one of them
	-- driving a zone floor through the base ring. It happened once already at
	-- ZoneDistance 250 and it was only caught by looking at a screenshot.
	-- Arithmetic that could have caught it belongs in the build.
	local baseReach = MAP.BaseRingRadius + BASE.Size * 0.5
	for _, zone in ipairs(ZoneData.Zones) do
		local nearEdge = math.abs(zone.Position.Z) - zone.Size.Z * 0.5
		if nearEdge < baseReach then
			warn(string.format(
				"[Artifact/MapService] Zone '%s' overlaps the base ring by %.1f studs. " ..
				"Its near edge is at %.1f and a base reaches %.1f. " ..
				"Raise GameConfig.Map.ZoneDistance or shrink the zone.",
				zone.Id, baseReach - nearEdge, nearEdge, baseReach))
		end
	end

	local parts = 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	log(string.format("Built %s: %d bases, %d zones, %d parts, ground Y=%d.",
		MAP.FolderName, GameConfig.MaxBases, #ZoneData.Zones, parts, Y))
end

--==============================================================================
-- READ API
--==============================================================================
function MapService.GetMap(): Folder?
	return mapFolder
end

function MapService.GetBasesFolder(): Folder?
	local folder = mapFolder
	if not folder then
		return nil
	end
	local bases = folder:FindFirstChild(MAP.BasesFolderName)
	return if bases and bases:IsA("Folder") then bases else nil
end

function MapService.GetOverflowCFrame(): CFrame
	local folder = mapFolder
	local environment = if folder then folder:FindFirstChild(MAP.EnvironmentFolderName) else nil
	local marker = if environment then environment:FindFirstChild(MAP.OverflowSpawnName) else nil
	if marker and marker:IsA("BasePart") then
		return marker.CFrame * CFrame.new(0, 5, 0)
	end
	return CFrame.new(0, Y + 6, 0)
end

return MapService
