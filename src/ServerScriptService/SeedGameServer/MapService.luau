--!strict
-- Steal a Seed :: MapService
--
-- Builds the entire map from code, every boot, from GameConfig.Map and
-- BiomeData. Nothing in this game is placed by hand.
--
--==============================================================================
-- WHY THE MAP IS CODE
--
-- Both other Roblox projects on this machine carry the same open item in their
-- handoffs, months apart: the map exists only inside a .rbxl and cannot be
-- reproduced. One of them still lists a 3,204-part hand-built map as "the only
-- remaining unreproducible artifact".
--
-- The cost is that it will never look hand-crafted. The return is that the map
-- is in git, diffable, identical on every server, survives losing the place
-- file, and moving the whole thing is one number. For a blocky studded
-- simulator that is the right trade every time.
--
-- REBUILT, NOT PATCHED. Init destroys any previous SeedMap and builds fresh, so
-- there is no reconcile step and no way for an old shape to survive a config
-- change. Rojo syncs the code, this rebuilds from it, and the two never
-- disagree.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
-- Dressing, not layout. Deliberately not a "*Service" so ServerMain does not
-- try to start it -- MapService calls it during its own build.
local MapDecor = require(script.Parent:WaitForChild("MapDecor"))

local MapService = {}
-- First. Every other service reads the world this builds.
MapService.Priority = 1

local MAP = GameConfig.Map
local PLOT = GameConfig.Plot
local Y = MAP.GroundY

local mapFolder: Folder? = nil

local function log(message: string)
	print("[Seed/MapService] " .. message)
end

--==============================================================================
-- THE ONE PART HELPER
--
-- Every part goes through here, which keeps the studded plastic look consistent
-- and stops a stray SmoothPlastic appearing because one call site forgot.
--==============================================================================
type PartOpts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?,
	parent: Instance,
	studs: boolean?,
}

local function build(o: PartOpts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Material = o.material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = o.collide ~= false
	p.Transparency = o.transparency or 0
	p.TopSurface = (o.studs ~= false) and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = o.parent
	return p
end

-- Flat text painted ON the ground. The reference game's SAFE ZONE marking is a
-- floor decal, and that is the whole reason it works: it is readable at thirty
-- studs while sprinting, from any angle, with no billboard turning to face you.
local function floorText(part: BasePart, text: string, color: Color3, size: number)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "FloorText"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = gui

	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = size
	cap.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(28, 22, 26)
	stroke.Transparency = 0.25
	stroke.Parent = label
	return label
end

--==============================================================================
-- A PLOT
--
-- PLAIN DIRT AND A WOODEN FENCE. That is the whole thing, and the restraint is
-- the point: this is a game about growing, so a plot has to read as SOIL --
-- somewhere empty and waiting -- and everything that is not soil competes with
-- the plants that will eventually stand in it.
--
-- The first version was a coloured deck with a planter box, a treadmill and a
-- rim. Six of those side by side read as a row of arcade cabinets, not a row of
-- gardens, and every one of those props would have been visual noise behind the
-- thing the player actually cares about.
--
-- THE WHOLE PLOT IS THE PLANTER. There is no separate box to walk up to: a seed
-- goes into the ground it was carried home to. That removes an object, removes
-- a step, and is what "plant it in your plot" should have meant from the start.
--
-- THE FENCE IS NOT COLLIDABLE, deliberately. A player sprinting home at
-- WalkSpeed 150 who clips a fence post and stops dead has been robbed by the
-- scenery. It is a property line, not a wall.
--==============================================================================
local DIRT = Color3.fromRGB(106, 74, 50)
local DIRT_DARK = Color3.fromRGB(88, 60, 40)
local WOOD = Color3.fromRGB(128, 88, 52)
local WOOD_DARK = Color3.fromRGB(96, 64, 38)

local function buildPlot(id: number, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = string.format("%s%02d", PLOT.NamePrefix, id)
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.Plot)

	local size = PLOT.Size
	local half = size * 0.5

	--== THE SOIL ==--
	-- Ground material, no studs. Studs are right for the grass field because it
	-- is a floor you walk on; soil is a thing you dig in, and a studded plot
	-- reads as plastic decking.
	local floor = build({
		name = PLOT.FloorName,
		size = Vector3.new(size, 2.5, size),
		cframe = cf * CFrame.new(0, 1.25, 0),
		color = DIRT,
		material = Enum.Material.Ground,
		studs = false,
		parent = model,
	})
	model.PrimaryPart = floor
	-- Tagged as the planter, because it IS the planter. Anything looking for
	-- somewhere to put a seed finds the plot's own ground.
	CollectionService:AddTag(floor, GameConfig.Tags.Planter)

	-- Two tilled furrows. Two parts, and they are what stop a flat brown square
	-- reading as mud rather than as a garden bed waiting to be planted.
	for _, offset in ipairs({ -10, 10 }) do
		build({
			name = "Furrow",
			size = Vector3.new(size - 10, 0.4, 5),
			cframe = cf * CFrame.new(0, 2.6, offset),
			color = DIRT_DARK,
			material = Enum.Material.Ground,
			-- Non-collidable. It is a mark on the soil, not a step -- and a
			-- 0.4-stud lip across the plot is exactly the sort of thing that
			-- catches a player running in at speed.
			collide = false,
			studs = false,
			parent = model,
		})
	end

	--== THE FENCE ==--
	-- Post and rail, three sides. The side facing the field stays open: that is
	-- the side the owner sprints in through, and a gate they have to aim at is a
	-- gate they will miss at speed.
	local sides = {
		{ axis = "z", sign = 1 },   -- back
		{ axis = "x", sign = -1 },  -- left
		{ axis = "x", sign = 1 },   -- right
	}
	for _, side in ipairs(sides) do
		local along = (side.axis == "x") and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
		local outward = (side.axis == "x")
			and Vector3.new(side.sign, 0, 0) or Vector3.new(0, 0, side.sign)

		-- Two rails.
		for _, h in ipairs({ 2.9, 5.0 }) do
			local railSize = (side.axis == "x")
				and Vector3.new(0.7, 0.7, size) or Vector3.new(size, 0.7, 0.7)
			build({
				name = "Rail",
				size = railSize,
				cframe = cf * CFrame.new(outward.X * half, h, outward.Z * half),
				color = WOOD,
				material = Enum.Material.Wood,
				collide = false,
				studs = false,
				parent = model,
			})
		end

		-- Posts. Three a side, corners shared with the neighbouring run -- which
		-- is a doubled post at each corner, and a doubled post looks like a
		-- corner post, so it costs nothing to leave.
		for _, t in ipairs({ -1, 0, 1 }) do
			local p = along * (t * half)
			build({
				name = "Post",
				size = Vector3.new(1.3, 6.4, 1.3),
				cframe = cf * CFrame.new(
					outward.X * half + p.X, 3.2, outward.Z * half + p.Z),
				color = WOOD_DARK,
				material = Enum.Material.Wood,
				collide = false,
				studs = false,
				parent = model,
			})
		end
	end

	--== OWNER SIGN ==--
	-- The one thing on the plot that is not soil or fence, and it earns its
	-- place: without it nobody can tell whose garden they are standing in, and
	-- "UNCLAIMED" is how a new player finds a free one.
	build({
		name = "SignPost",
		size = Vector3.new(1.2, 7, 1.2),
		cframe = cf * CFrame.new(-half + 6, 3.5, -half - 1),
		color = WOOD_DARK,
		material = Enum.Material.Wood,
		collide = false,
		studs = false,
		parent = model,
	})
	local board = build({
		name = PLOT.SignName,
		size = Vector3.new(15, 4.5, 0.6),
		cframe = cf * CFrame.new(-half + 6, 8.4, -half - 1),
		color = WOOD,
		material = Enum.Material.Wood,
		collide = false,
		studs = false,
		parent = model,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = PLOT.SignLabelName
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = PLOT.UnclaimedText
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 247, 230)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(48, 32, 20)
	stroke.Parent = label

	--== SPAWN ==--
	-- INVISIBLE. A SpawnLocation has to exist so Player.RespawnLocation has
	-- something to point at, but a glowing neon pad in the middle of a dirt plot
	-- is exactly the kind of prop this pass is removing. It is a hook, not
	-- scenery.
	local pad = Instance.new("SpawnLocation")
	pad.Name = PLOT.SpawnPadName
	pad.Size = Vector3.new(10, 1, 10)
	pad.CFrame = cf * CFrame.new(0, 2.5, -half + 9)
	pad.Transparency = 1
	pad.CanCollide = false
	pad.Anchored = true
	pad.Neutral = true
	-- Only the owner's is enabled, by PlotService. Every pad live would let
	-- Roblox's own respawn logic drop anybody on anybody's plot.
	pad.Enabled = false
	pad.Duration = 0
	pad.Parent = model
	CollectionService:AddTag(pad, GameConfig.Tags.PlotSpawn)

	--== PLANT SLOTS ==--
	-- Attachments, not parts. A slot costs nothing until something grows in it,
	-- and PlantService only needs a CFrame.
	local plants = Instance.new("Folder")
	plants.Name = PLOT.PlantsFolderName
	plants.Parent = model
	local slots = PLOT.StartingPlantSlots
	for slot = 1, slots do
		local a = Instance.new("Attachment")
		a.Name = string.format("Slot%02d", slot)
		a:SetAttribute("SlotIndex", slot)
		local col = ((slot - 1) % 3) - 1
		local row = math.floor((slot - 1) / 3)
		-- On the two furrows, which is why the furrows are where they are.
		a.WorldCFrame = cf * CFrame.new(col * 14, 2.6, row == 0 and -10 or 10)
		a.Parent = floor
		CollectionService:AddTag(a, GameConfig.Tags.PlantSlot)
	end

	local runtime = Instance.new("Folder")
	runtime.Name = PLOT.RuntimeFolderName
	runtime.Parent = model

	return model
end

--==============================================================================
-- A TREADMILL
--
-- Moved OFF the plot by the same pass that stripped it back to dirt and fence.
-- It still belongs to a plot -- one each, parked on the grass directly in front
-- of its owner's fence -- which is also where the reference game puts them.
--
-- Low and collidable, unlike almost everything else on the field: you stand on
-- this one, so it is the exception to the "nothing catches a runner" rule, and
-- at 1.5 studs high it is a step rather than an obstacle.
--==============================================================================
local function buildTreadmill(id: number, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = string.format("%s%02d", PLOT.TreadmillName, id)
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	model.Parent = parent

	local frame = build({
		name = "Frame",
		size = Vector3.new(11, 1.2, 19),
		cframe = cf,
		color = WOOD,
		material = Enum.Material.Wood,
		studs = false,
		parent = model,
	})
	model.PrimaryPart = frame

	local belt = build({
		name = PLOT.TreadmillName,
		size = Vector3.new(8, 1.4, 16),
		cframe = cf * CFrame.new(0, 0.4, 0),
		color = Color3.fromRGB(58, 52, 48),
		material = Enum.Material.SmoothPlastic,
		studs = false,
		parent = model,
	})
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)

	for _, side in ipairs({ -1, 1 }) do
		build({
			name = "Handrail",
			size = Vector3.new(0.7, 5, 0.7),
			cframe = cf * CFrame.new(side * 4.6, 3, -7),
			color = WOOD_DARK,
			material = Enum.Material.Wood,
			collide = false,
			studs = false,
			parent = model,
		})
	end
	build({
		name = "HandrailTop",
		size = Vector3.new(10, 0.7, 0.7),
		cframe = cf * CFrame.new(0, 5.3, -7),
		color = WOOD_DARK,
		material = Enum.Material.Wood,
		collide = false,
		studs = false,
		parent = model,
	})

	return model
end

--==============================================================================
-- A BIOME SEGMENT
--
-- One stretch of the single road. Floor, two wall runs, a gate arch at the near
-- end, and pods along both walls.
--
-- The walls are CONTINUOUS down the whole corridor and only change COLOUR at a
-- boundary, which is deliberate: standing at the safe line you can see the
-- ground and walls change five times into the distance, and that is the entire
-- progression of the game visible in one glance with no UI at all.
--==============================================================================
local function buildSegment(biome: BiomeData.Biome, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = biome.Id
	model:SetAttribute(GameConfig.Attributes.BiomeId, biome.Id)
	model:SetAttribute("SpeedGate", biome.SpeedGate)
	model:SetAttribute("Live", biome.LiveInPhaseA)
	model:SetAttribute("DistanceFromSafety", BiomeData.DistanceFromSafety(biome))
	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.Lane)

	local nearZ, farZ = BiomeData.SegmentBounds(biome)
	local midZ = (nearZ + farZ) * 0.5
	local W = MAP.CorridorWidth
	local L = MAP.SegmentLength
	local wallH, wallT = MAP.WallHeight, MAP.WallThickness

	--== FLOOR ==--
	local floor = build({
		name = "Floor",
		size = Vector3.new(W, MAP.FieldThickness, L),
		cframe = CFrame.new(0, Y - MAP.FieldThickness * 0.5, midZ),
		color = biome.GroundColor,
		parent = model,
	})
	model.PrimaryPart = floor

	--== WALLS ==--
	for _, side in ipairs({ -1, 1 }) do
		build({
			name = side < 0 and "WallLeft" or "WallRight",
			size = Vector3.new(wallT, wallH, L),
			cframe = CFrame.new(side * (W * 0.5 + wallT * 0.5), Y + wallH * 0.5, midZ),
			color = biome.WallColor,
			parent = model,
		})
	end

	--== THE FAR WALL ==--
	-- Only the last biome gets one. Everything else opens into the next.
	if biome.Order == #BiomeData.Biomes then
		build({
			name = "EndWall",
			size = Vector3.new(W + wallT * 2, wallH, wallT),
			cframe = CFrame.new(0, Y + wallH * 0.5, farZ - wallT * 0.5),
			color = biome.WallColor,
			parent = model,
		})
	end

	--== THE GATE ==--
	-- An arch across the road at the boundary, carrying the biome's name.
	-- Non-collidable: it is signage until Phase C gives it a Speed check, and a
	-- solid gate now would make the whole road impassable.
	local gate = build({
		name = "Gate",
		size = Vector3.new(W + wallT * 2, 10, 4),
		cframe = CFrame.new(0, Y + wallH - 5, nearZ),
		color = biome.AccentColor,
		collide = false,
		studs = false,
		parent = model,
	})
	gate:SetAttribute(GameConfig.Attributes.BiomeId, biome.Id)
	gate:SetAttribute("SpeedGate", biome.SpeedGate)
	CollectionService:AddTag(gate, GameConfig.Tags.BiomeGate)

	-- Named on BOTH faces. You read it going out, and going home it tells you
	-- how much further there is to run.
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sign = Instance.new("SurfaceGui")
		sign.Name = "GateSign"
		sign.Face = face
		sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sign.PixelsPerStud = 36
		sign.LightInfluence = 0
		sign.Parent = gate

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		-- ONE WORD AND A FACE. See the note at the top of BiomeData.
		text.Text = biome.DisplayName .. " " .. biome.Mood
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 226, 96)
		text.Parent = sign

		local ts = Instance.new("UIStroke")
		ts.Thickness = 4
		ts.Color = Color3.fromRGB(38, 26, 16)
		ts.Parent = text
	end

	--== PODS ==--
	local pods = Instance.new("Folder")
	pods.Name = "Pods"
	pods.Parent = model
	CollectionService:AddTag(pods, GameConfig.Tags.WildPatch)

	for index, podCF in ipairs(BiomeData.PodCFrames(biome)) do
		local pod = build({
			name = string.format("Pod%02d", index),
			size = Vector3.new(7, 6, 7),
			cframe = podCF * CFrame.new(0, 3, 0),
			color = biome.AccentColor,
			material = Enum.Material.Slate,
			parent = pods,
		})
		pod:SetAttribute(GameConfig.Attributes.BiomeId, biome.Id)
		pod:SetAttribute("PodIndex", index)
		pod:SetAttribute(GameConfig.Attributes.SeedInstanceId, "")
		CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)

		local mount = Instance.new("Attachment")
		mount.Name = "Mount"
		mount.Position = Vector3.new(0, 4, 0)
		mount.Parent = pod
	end

	--== DRESSING ==--
	-- Last, so the decorator can claim the pod positions and place nothing on
	-- top of them.
	MapDecor.dressSegment(biome, model)

	--== LIGHT ==--
	-- Darkness is the cheapest atmosphere there is, but a segment you cannot
	-- see across is a segment you cannot be chased through. One non-casting
	-- PointLight at the middle, per segment, not per pod.
	if biome.Brightness < 0.9 then
		local light = Instance.new("PointLight")
		light.Name = "SegmentGlow"
		light.Brightness = 2.5
		light.Range = 90
		light.Color = biome.AccentColor
		light.Shadows = false
		light.Parent = floor
	end

	return model
end

--==============================================================================
-- BUILD
--==============================================================================
--==============================================================================
-- LIGHTING
--
-- Part of the map, therefore part of the code. A blank place defaults to a
-- gloomy evening and the first build of this map rendered almost black --
-- which looks like a bug and is not one.
--
-- Set here rather than by hand in the Lighting service for the same reason
-- everything else is: a value only stored in the .rbxl is a value nobody can
-- diff, and one that quietly differs between the place and a fresh build.
--
-- Technology is DELIBERATELY NOT TOUCHED. It is not scriptable -- assigning it
-- throws, and even reading it can error -- so it stays a manual place setting
-- and every read of it is wrapped.
--==============================================================================
local function applyLighting()
	local Lighting = game:GetService("Lighting")
	-- Midday. The reference game is relentlessly bright, and for a game whose
	-- read-at-a-glance elements are a red floor line and coloured plots, bright
	-- is not a style choice -- it is legibility.
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 12
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(112, 112, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(146, 152, 162)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.ExposureCompensation = 0
	Lighting.GlobalShadows = true
	-- NOTHING MAY OBSCURE THE ROAD. Being able to stand at the safe line and see
	-- all five biomes receding into the distance IS the progression display --
	-- it is why the map is one corridor rather than five lanes. Haze at 1,500
	-- studs deletes that, and it deletes seeing who is chasing you.
	--
	-- Two separate systems can do it, and both have to be shut off. FogEnd is
	-- the legacy one. Atmosphere is a real Instance a blank place often ships
	-- with, and its Density will happily grey out the far end regardless of
	-- what FogEnd says.
	Lighting.FogEnd = 100000
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze = 0
	end

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
end

function MapService.Init()
	applyLighting()

	local existing = workspace:FindFirstChild(MAP.FolderName)
	if existing then
		existing:Destroy()
	end

	-- The stock baseplate and spawn from a blank place. Removed because this
	-- service owns the ground and PlotService owns spawning; leaving them means
	-- a grey plate poking through the field and Roblox dropping players at the
	-- origin before a plot is assigned.
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local stock = workspace:FindFirstChild(name)
		if stock then
			stock:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = MAP.FolderName
	folder.Parent = workspace
	mapFolder = folder

	local props = Instance.new("Folder")
	props.Name = MAP.PropsFolderName
	props.Parent = folder

	--== THE FIELD ==--
	local field = build({
		name = MAP.FieldName,
		size = Vector3.new(MAP.FieldWidth, MAP.FieldThickness, MAP.FieldDepth),
		cframe = CFrame.new(0, Y - MAP.FieldThickness * 0.5, 0),
		color = Color3.fromRGB(112, 200, 84),
		parent = folder,
	})
	CollectionService:AddTag(field, GameConfig.Tags.SafeZone)

	--== THE RED LINE ==--
	-- The single most important piece of communication in the map. See the note
	-- in GameConfig.Map: painted flat, no dome, no billboard.
	local line = build({
		name = "SafeLine",
		size = Vector3.new(MAP.FieldWidth, 0.4, MAP.SafeLineThickness),
		cframe = CFrame.new(0, Y + 0.2, -MAP.FieldDepth * 0.5 + MAP.SafeLineThickness),
		color = MAP.SafeLineColor,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		studs = false,
		parent = props,
	})
	line.CanQuery = false

	local plate = build({
		name = "SafeLineText",
		size = Vector3.new(150, 0.3, 22),
		cframe = CFrame.new(0, Y + 0.15, -MAP.FieldDepth * 0.5 + 16),
		color = Color3.fromRGB(112, 200, 84),
		collide = false,
		transparency = 1,
		studs = false,
		parent = props,
	})
	plate.CanQuery = false
	floorText(plate, "SAFE ZONE", Color3.fromRGB(255, 255, 255), 90)

	--== OVERFLOW SPAWN ==--
	-- Where a player goes when every plot is taken. Named and findable rather
	-- than a hardcoded coordinate in a service, because the day the map moves a
	-- hardcoded fallback is the one thing left behind.
	local overflow = build({
		name = MAP.OverflowSpawnName,
		size = Vector3.new(10, 1, 10),
		cframe = CFrame.new(0, Y + 0.5, 0),
		color = Color3.fromRGB(255, 255, 255),
		collide = false,
		transparency = 1,
		studs = false,
		parent = props,
	})
	overflow.CanQuery = false

	--== THE SELL STALL ==--
	-- UPPER LEFT OF THE FIELD, not the middle. In the middle it sat on the exact
	-- line every player runs between their plot and the road, which is the one
	-- strip of ground that has to stay clear -- a shop should be somewhere you
	-- choose to go, not something you have to run around twice a lap.
	--
	-- A real stall rather than a red box: counter, posts, striped awning. It is
	-- the only building in the safe zone, so it is the only thing that can make
	-- the field read as a market garden rather than a lawn.
	do
		local sx = -(MAP.FieldWidth * 0.5) + 46
		local sz = -(MAP.FieldDepth * 0.5) + 30
		local stallCF = CFrame.new(sx, Y, sz) * CFrame.Angles(0, math.rad(28), 0)

		local stall = Instance.new("Model")
		stall.Name = MAP.SellStandName
		stall.Parent = props

		local counter = build({
			name = "Counter",
			size = Vector3.new(20, 6, 7),
			cframe = stallCF * CFrame.new(0, 3, 0),
			color = WOOD,
			material = Enum.Material.Wood,
			studs = false,
			parent = stall,
		})
		stall.PrimaryPart = counter

		build({
			name = "CounterTop",
			size = Vector3.new(22, 0.8, 9),
			cframe = stallCF * CFrame.new(0, 6.4, 0),
			color = WOOD_DARK,
			material = Enum.Material.Wood,
			studs = false,
			parent = stall,
		})

		for _, side in ipairs({ -1, 1 }) do
			build({
				name = "Post",
				size = Vector3.new(1.2, 13, 1.2),
				cframe = stallCF * CFrame.new(side * 10, 6.5, -3.5),
				color = WOOD_DARK,
				material = Enum.Material.Wood,
				collide = false,
				studs = false,
				parent = stall,
			})
		end

		-- Striped awning. Alternating slats rather than one part with a texture,
		-- because a texture is an asset id that lives in somebody's account and
		-- this has to survive without one.
		for i = 0, 6 do
			build({
				name = "Awning",
				size = Vector3.new(3.2, 0.6, 11),
				cframe = stallCF * CFrame.new(-9.6 + i * 3.2, 13.6, -1.5)
					* CFrame.Angles(math.rad(-16), 0, 0),
				color = (i % 2 == 0) and Color3.fromRGB(226, 74, 74)
					or Color3.fromRGB(248, 244, 236),
				material = Enum.Material.SmoothPlastic,
				collide = false,
				studs = false,
				parent = stall,
			})
		end

		local sign = Instance.new("SurfaceGui")
		sign.Face = Enum.NormalId.Back
		sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sign.PixelsPerStud = 30
		sign.LightInfluence = 0
		sign.Parent = counter
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.Text = "SELL"
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 248, 232)
		t.Parent = sign
		local ss = Instance.new("UIStroke")
		ss.Thickness = 4
		ss.Color = Color3.fromRGB(72, 34, 22)
		ss.Parent = t
	end

	--== PLOTS ==--
	local plots = Instance.new("Folder")
	plots.Name = MAP.PlotsFolderName
	plots.Parent = folder

	local n = GameConfig.MaxPlots
	local z = MAP.FieldDepth * 0.5 - PLOT.InsetFromEdge
	for id = 1, n do
		local x = (id - (n + 1) * 0.5) * PLOT.Pitch
		-- Facing the lanes, which is the direction every run comes home from.
		buildPlot(id, CFrame.new(x, Y, z), plots)
		-- On the grass in front of its own plot, clear of the fence.
		buildTreadmill(id, CFrame.new(x, Y + 0.6, z - PLOT.Size * 0.5 - 16), plots)
	end

	--== FIELD DRESSING ==--
	-- After the plots, so the beds are placed around them rather than under.
	MapDecor.dressField(props)

	--== LANES ==--
	local lanes = Instance.new("Folder")
	lanes.Name = MAP.LanesFolderName
	lanes.Parent = folder

	for _, biome in ipairs(BiomeData.Biomes) do
		buildSegment(biome, lanes)
	end

	--== SANITY ==--
	-- Three independent numbers decide whether the plots fit on the field, and
	-- nothing stops a future edit to one of them pushing a plot off the edge.
	-- Arithmetic that can catch it belongs in the build, not in a comment.
	local plotSpan = (n - 1) * PLOT.Pitch + PLOT.Size
	if plotSpan > MAP.FieldWidth then
		warn(string.format(
			"[Seed/MapService] %d plots at pitch %d span %d studs but the field is only %d wide. " ..
			"Raise FieldWidth or lower Plot.Pitch.",
			n, PLOT.Pitch, plotSpan, MAP.FieldWidth))
	end
	if MAP.CorridorWidth > MAP.FieldWidth then
		warn(string.format(
			"[Seed/MapService] The corridor is %d wide against a %d-wide field. Its mouth will " ..
			"hang off the edge.", MAP.CorridorWidth, MAP.FieldWidth))
	end
	-- The biomes must be in an unbroken 1..N run, or SegmentBounds leaves a gap
	-- in the road and players fall through it.
	local seen: { [number]: boolean } = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		if seen[biome.Order] then
			warn(string.format("[Seed/MapService] Two biomes share Order %d. The road will overlap itself.",
				biome.Order))
		end
		seen[biome.Order] = true
	end
	for order = 1, #BiomeData.Biomes do
		if not seen[order] then
			warn(string.format("[Seed/MapService] No biome has Order %d. There will be a hole in the road.",
				order))
		end
	end

	local parts = 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	local last = BiomeData.Biomes[#BiomeData.Biomes]
	log(string.format("Built %s: %d plots, %d biomes, %d parts. Road is %d studs end to end.",
		MAP.FolderName, n, #BiomeData.Biomes, parts,
		last and BiomeData.DistanceFromSafety(last) or 0))
end

--==============================================================================
-- READ API
--==============================================================================
function MapService.GetMap(): Folder?
	return mapFolder
end

function MapService.GetPlotsFolder(): Folder?
	local f = mapFolder
	if not f then return nil end
	local plots = f:FindFirstChild(MAP.PlotsFolderName)
	return if plots and plots:IsA("Folder") then plots else nil
end

function MapService.GetOverflowCFrame(): CFrame
	local f = mapFolder
	local props = if f then f:FindFirstChild(MAP.PropsFolderName) else nil
	local marker = if props then props:FindFirstChild(MAP.OverflowSpawnName) else nil
	if marker and marker:IsA("BasePart") then
		return marker.CFrame * CFrame.new(0, 5, 0)
	end
	return CFrame.new(0, Y + 6, 0)
end

-- Is this position inside the safe field? One definition, so the HUD, the steal
-- check and the combat rules can never disagree about where safety ends.
function MapService.IsInSafeZone(position: Vector3): boolean
	local halfW = MAP.FieldWidth * 0.5
	local halfD = MAP.FieldDepth * 0.5
	return position.X >= -halfW and position.X <= halfW
		and position.Z >= -halfD and position.Z <= halfD
end

return MapService
