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
local HubFairy = require(script.Parent:WaitForChild("HubFairy"))

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
-- Built to the owner's reference sketch: a fenced square of GRASS with two
-- raised bed blocks standing on it, each divided into rows.
--
-- The version before this was a solid dirt rectangle, and the sketch is better
-- for a reason worth keeping: a slab of dirt is one shape, whereas two framed
-- blocks divided into rows is a GRID. A grid tells the player how many things
-- fit and exactly where they go before a single plant exists -- and it gives
-- expansion something to SAY, because another tier is visibly more rows.
--
-- A ROW IS A SLOT, so there is no slot count to keep in step with the geometry.
--
-- THE FENCE ENCLOSES ALL FOUR SIDES, which an earlier version deliberately did
-- not: it left the road-facing side open so nobody had to aim at a gate at
-- speed. That reasoning was wrong about its own code. The fence is
-- NON-COLLIDABLE -- you run straight through it -- so closing the fourth side
-- costs nothing and reads far better as "this ground is claimed".
--==============================================================================
local GRASS = Color3.fromRGB(112, 200, 84)
local BED_SOIL = Color3.fromRGB(168, 104, 70)
local BED_FRAME = Color3.fromRGB(112, 68, 44)
local FENCE = Color3.fromRGB(96, 66, 44)
local WOOD = Color3.fromRGB(128, 88, 52)
local WOOD_DARK = Color3.fromRGB(96, 64, 38)

local function buildPlot(id: number, cf: CFrame, rows: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = string.format("%s%02d", PLOT.NamePrefix, id)
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.Plot)

	local width = PLOT.Width
	local depth = GameConfig.plotDepthFor(rows)
	local halfW, halfD = width * 0.5, depth * 0.5
	model:SetAttribute("Rows", rows)
	model:SetAttribute("Depth", depth)

	--== THE PLOT HAS NO GROUND OF ITS OWN ==--
	--
	-- It used to: a 2-stud grass slab that sat ON TOP of the field, so every
	-- plot was a platform you stepped up onto. Asked to make them mix into the
	-- ground instead, and the right answer turned out to be removing the slab
	-- rather than sinking it.
	--
	-- Sinking it flush would z-fight with the field, and raising it a hair would
	-- not: plots are ROTATED to face the hub, so their stud grid runs at an
	-- angle to the field's. A rotated studded patch laid on a studded field
	-- shows a seam at every plot no matter how thin it is.
	--
	-- With no slab at all, the field's studs run continuously under the fence
	-- and the beds, which is exactly "they should mix". The FENCE is what marks
	-- the plot now, which is what a fence is for.
	--
	-- This part survives as an invisible footprint: PrimaryPart for GetPivot,
	-- and the rectangle every fit check measures. It is never seen.
	local floor = build({
		name = PLOT.FloorName,
		size = Vector3.new(width, 0.2, depth),
		cframe = cf * CFrame.new(0, 0.1, 0),
		color = GRASS,
		transparency = 1,
		collide = false,
		studs = false,
		parent = model,
	})
	floor.CanQuery = false
	model.PrimaryPart = floor

	--== THE FENCE ==--
	--
	-- Four sides with a GAP AT THE FRONT for the gate. Non-collidable
	-- throughout, so the gap is not what lets you in -- you could always walk
	-- through the rails. It is what SHOWS you the way in, and a sealed
	-- rectangle read as a pen rather than as a garden.
	--
	-- Built as segments between two coordinates rather than as four whole
	-- sides, because the front is now two pieces and a special case for it
	-- would be a second copy of the same rail-and-post code.
	local function fenceRun(alongX: boolean, fixed: number, from: number, to: number)
		local length = math.abs(to - from)
		if length < 0.5 then
			return
		end
		local mid = (from + to) * 0.5

		for _, h in ipairs({ 3.2, 5.4 }) do
			build({
				name = "Rail",
				size = alongX and Vector3.new(length, 0.6, 0.6)
					or Vector3.new(0.6, 0.6, length),
				cframe = cf * (alongX and CFrame.new(mid, h, fixed)
					or CFrame.new(fixed, h, mid)),
				color = FENCE,
				material = Enum.Material.Wood,
				collide = false,
				studs = false,
				parent = model,
			})
		end

		-- Roughly one post per bed row, which is what gives the sketch its
		-- rhythm. Minimum two so a short segment still has an end at each end.
		local postCount = math.max(2, math.floor(length / 11) + 1)
		for i = 1, postCount do
			local p = from + (to - from) * ((i - 1) / (postCount - 1))
			build({
				name = "Post",
				size = Vector3.new(1.1, 7, 1.1),
				cframe = cf * (alongX and CFrame.new(p, 3.5, fixed)
					or CFrame.new(fixed, 3.5, p)),
				color = FENCE,
				material = Enum.Material.Wood,
				collide = false,
				studs = false,
				parent = model,
			})
		end
	end

	local gateHalf = PLOT.GateWidth * 0.5
	fenceRun(true, halfD, -halfW, halfW)      -- back
	fenceRun(false, -halfW, -halfD, halfD)    -- left
	fenceRun(false, halfW, -halfD, halfD)     -- right
	fenceRun(true, -halfD, -halfW, -gateHalf) -- front, left of the gate
	fenceRun(true, -halfD, gateHalf, halfW)   -- front, right of the gate

	--== THE GATEPOSTS ==--
	-- Taller than the fence and capped. Two posts standing proud of the line
	-- is the whole signal -- it reads as an entrance from across the field,
	-- with no arch to build and nothing to walk into.
	for _, side in ipairs({ -1, 1 }) do
		build({
			name = "GatePost",
			size = Vector3.new(1.6, 10, 1.6),
			cframe = cf * CFrame.new(side * gateHalf, 5, -halfD),
			color = FENCE,
			material = Enum.Material.Wood,
			collide = false,
			studs = false,
			parent = model,
		})
		build({
			name = "GateCap",
			size = Vector3.new(2.6, 0.8, 2.6),
			cframe = cf * CFrame.new(side * gateHalf, 10.3, -halfD),
			color = WOOD,
			material = Enum.Material.Wood,
			collide = false,
			studs = false,
			parent = model,
		})
	end

	--== THE BEDS ==--
	local plants = Instance.new("Folder")
	plants.Name = PLOT.PlantsFolderName
	plants.Parent = model

	local cols = PLOT.BedColumns
	local usableW = width - PLOT.BedInsetX * 2
	local blockW = (usableW - PLOT.BedCentreGap * (cols - 1)) / cols
	local bedSpan = rows * PLOT.RowDepth + (rows - 1) * PLOT.RowGap

	local slot = 0
	for col = 1, cols do
		-- Centres of `cols` blocks laid across usableW with the aisle between.
		local blockX = (col - (cols + 1) * 0.5) * (blockW + PLOT.BedCentreGap)

		-- ONE FRAME PER BLOCK, sitting a little proud of the soil. The reference
		-- sketch's beds have a continuous dark border round the whole block with
		-- the rows divided inside it -- not a border per row -- and that is what
		-- makes it read as a raised bed rather than as tiles on a floor.
		build({
			name = "BedFrame",
			-- Bottom at ground level, because there is no deck under it any
			-- more -- the bed stands directly on the field.
			size = Vector3.new(blockW + 1.6, 2.2, bedSpan + 1.6),
			cframe = cf * CFrame.new(blockX, 1.1, 0),
			color = BED_FRAME,
			material = Enum.Material.Wood,
			collide = false,
			studs = false,
			parent = model,
		})

		for row = 1, rows do
			slot += 1
			-- Rows run front to back, so row 1 is the one nearest the gate and
			-- new rows appear at the BACK when a plot is expanded.
			local rowZ = -bedSpan * 0.5 + (row - 0.5) * PLOT.RowDepth
				+ (row - 1) * PLOT.RowGap

			local bed = build({
				name = string.format("Bed%02d", slot),
				size = Vector3.new(blockW, 1.6, PLOT.RowDepth),
				-- Recessed a little below the frame's lip, so the frame reads as
				-- a raised edge holding soil in rather than as a mat under it.
				cframe = cf * CFrame.new(blockX, 1.2, rowZ),
				color = BED_SOIL,
				-- STUDDED, AND THEREFORE PLASTIC. Ground was the obvious material
				-- for soil and it is the wrong one: its noise texture renders
				-- OVER the studs, so a bed set to TopSurface = Studs came out
				-- looking smooth while the grass around it was visibly studded.
				-- Plastic is the material that actually shows them, which is the
				-- whole classic Roblox look this game is built in.
				material = Enum.Material.Plastic,
				collide = false,
				parent = model,
			})
			bed:SetAttribute("SlotIndex", slot)
			bed:SetAttribute("Row", row)
			bed:SetAttribute("Column", col)
			CollectionService:AddTag(bed, GameConfig.Tags.Planter)

			-- Where a plant stands. On the bed rather than on the plot floor,
			-- so a plant is rooted in soil and moves if the bed ever does.
			local a = Instance.new("Attachment")
			a.Name = string.format("Slot%02d", slot)
			a:SetAttribute("SlotIndex", slot)
			a.Position = Vector3.new(0, 0.8, 0)
			a.Parent = bed
			CollectionService:AddTag(a, GameConfig.Tags.PlantSlot)
		end
	end

	--== NO OWNER SIGN ==--
	-- There was an UNCLAIMED board here and it has been removed. It existed so a
	-- new player could find a free plot, and that is not a thing anybody does:
	-- PlotService assigns a vacant plot the moment you spawn, so nobody ever
	-- shops for one and every sign in the row would read as somebody's name.
	--
	-- If in-world ownership is ever wanted, the gate is where it goes -- a
	-- nameplate over the entrance, seen on the way in, rather than a board
	-- facing an empty field.

	--== SPAWN ==--
	-- Invisible. It exists so Player.RespawnLocation has something to point at.
	-- Just inside the gate, on the grass aisle between the beds -- so a respawn
	-- puts you where you walk in and never drops you standing inside a bed.
	local pad = Instance.new("SpawnLocation")
	pad.Name = PLOT.SpawnPadName
	pad.Size = Vector3.new(6, 1, 6)
	pad.CFrame = cf * CFrame.new(0, 0.6, -halfD + 3)
	pad.Transparency = 1
	pad.CanCollide = false
	pad.Anchored = true
	pad.Neutral = true
	pad.Enabled = false
	pad.Duration = 0
	pad.Parent = model
	CollectionService:AddTag(pad, GameConfig.Tags.PlotSpawn)

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
		-- Offset, because the field is no longer centred on the origin: it
		-- reaches further back than forward to reserve room for plot growth.
		cframe = CFrame.new(0, Y - MAP.FieldThickness * 0.5, MAP.FieldCenterZ),
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
		cframe = CFrame.new(0, Y + 0.2, -MAP.FieldFront + MAP.SafeLineThickness),
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
		cframe = CFrame.new(0, Y + 0.15, -MAP.FieldFront + 16),
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

	--== THE HUB ==--
	--
	-- The market square: a low deck, one dressed stall, and the fairy who runs
	-- it. NO FENCE. It had a ring of posts and rails around it, and a fence
	-- around a shop says "keep out" -- the opposite of what a shop is for. The
	-- deck marks the square instead, which is a floor you walk onto rather than
	-- a barrier you walk through.
	do
		local hub = Instance.new("Model")
		hub.Name = "Hub"
		hub.Parent = props

		local R = MAP.HubRadius

		-- One cylinder for the whole square. A ring of straight segments would
		-- be a dozen parts to say the same thing, and a cylinder never shows the
		-- polygon.
		local deck = Instance.new("Part")
		deck.Name = "Deck"
		deck.Shape = Enum.PartType.Cylinder
		deck.Size = Vector3.new(0.9, R * 2, R * 2)
		deck.CFrame = CFrame.new(0, Y + 0.45, 0) * CFrame.Angles(0, 0, math.rad(90))
		deck.Color = Color3.fromRGB(206, 178, 132)
		deck.Material = Enum.Material.Sand
		deck.Anchored = true
		deck.TopSurface = Enum.SurfaceType.Smooth
		deck.BottomSurface = Enum.SurfaceType.Smooth
		deck.Parent = hub

		-- A darker rim, so the square has an edge without needing a fence.
		local rim = deck:Clone()
		rim.Name = "DeckRim"
		rim.Size = Vector3.new(0.6, R * 2 + 5, R * 2 + 5)
		rim.CFrame = CFrame.new(0, Y + 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
		rim.Color = Color3.fromRGB(150, 120, 84)
		rim.Parent = hub

		--== THE STALL ==--
		local stallCF = CFrame.new(0, Y, 15) * CFrame.Angles(0, math.pi, 0)

		build({ name = "StallFloor", size = Vector3.new(24, 0.6, 14),
			cframe = stallCF * CFrame.new(0, 0.3, -2), color = WOOD_DARK,
			material = Enum.Material.WoodPlanks, studs = false, parent = hub })

		-- A RAISED DECK BEHIND THE COUNTER, and it is not decoration. Marigold
		-- is five studs tall and her head came out exactly level with the
		-- counter top, so she was invisible from the customer side -- a
		-- shopkeeper you cannot see is not a shopkeeper.
		--
		-- Lowering the counter instead would have made it ankle-high on the
		-- players who walk up to it. Standing the keeper up is what a real market
		-- stall does, and it only raises the ground she actually walks on: the
		-- customer side stays flush with the square, so nobody has a step to
		-- climb to reach the shop.
		build({ name = "StallRiser", size = Vector3.new(22, 2, 7),
			cframe = stallCF * CFrame.new(0, 1, -5.5), color = WOOD,
			material = Enum.Material.WoodPlanks, studs = false, parent = hub })

		-- 3.6 TALL, NOT 5.4. The first counter was chest-height on a five-stud
		-- character and Marigold disappeared entirely behind her own shop. A
		-- shopkeeper you cannot see is not a shopkeeper.
		local counter = build({ name = MAP.SellStandName, size = Vector3.new(20, 3.6, 6),
			cframe = stallCF * CFrame.new(0, 2.4, 0), color = WOOD,
			material = Enum.Material.WoodPlanks, studs = false, parent = hub })
		build({ name = "CounterTop", size = Vector3.new(22.5, 0.9, 8),
			cframe = stallCF * CFrame.new(0, 4.65, 0), color = WOOD_DARK,
			material = Enum.Material.WoodPlanks, studs = false, parent = hub })

		-- Back shelf with produce on it, which is what turns a counter into a
		-- shop. Jars are one part each and are the cheapest possible "somebody
		-- works here".
		build({ name = "Shelf", size = Vector3.new(18, 0.7, 3),
			cframe = stallCF * CFrame.new(0, 7.2, -6.5), color = WOOD_DARK,
			material = Enum.Material.WoodPlanks, collide = false, studs = false, parent = hub })
		local jarColors = {
			Color3.fromRGB(226, 96, 84), Color3.fromRGB(240, 190, 74),
			Color3.fromRGB(126, 198, 106), Color3.fromRGB(150, 130, 226),
			Color3.fromRGB(238, 140, 178), Color3.fromRGB(120, 200, 214),
		}
		for i, c in ipairs(jarColors) do
			build({ name = "Jar", size = Vector3.new(1.5, 2, 1.5),
				cframe = stallCF * CFrame.new(-7.5 + (i - 1) * 3, 8.5, -6.5),
				color = c, material = Enum.Material.Glass,
				collide = false, studs = false, parent = hub })
		end

		for _, side in ipairs({ -1, 1 }) do
			build({ name = "Post", size = Vector3.new(1.2, 13, 1.2),
				cframe = stallCF * CFrame.new(side * 10.5, 6.5, -3),
				color = WOOD_DARK, material = Enum.Material.Wood,
				collide = false, studs = false, parent = hub })
			-- A crate of produce either side of the counter.
			build({ name = "Crate", size = Vector3.new(4, 3.4, 4),
				cframe = stallCF * CFrame.new(side * 13, 1.7, 1) * CFrame.Angles(0, side * 0.3, 0),
				color = WOOD, material = Enum.Material.WoodPlanks,
				collide = false, studs = false, parent = hub })
			build({ name = "Produce", size = Vector3.new(3.2, 1, 3.2),
				cframe = stallCF * CFrame.new(side * 13, 3.7, 1) * CFrame.Angles(0, side * 0.3, 0),
				color = Color3.fromRGB(214, 96, 88), material = Enum.Material.Plastic,
				collide = false, studs = false, parent = hub })
			-- A lantern hung off each post.
			build({ name = "Lantern", size = Vector3.new(1.4, 1.8, 1.4),
				cframe = stallCF * CFrame.new(side * 10.5, 11.4, -1),
				color = Color3.fromRGB(255, 214, 130), material = Enum.Material.Neon,
				collide = false, studs = false, parent = hub })
		end

		-- Striped awning. Alternating slats rather than a texture, because a
		-- texture is an asset id that lives in one account.
		for i = 0, 6 do
			build({ name = "Awning", size = Vector3.new(3.4, 0.6, 12),
				cframe = stallCF * CFrame.new(-10.2 + i * 3.4, 13.4, -1.5)
					* CFrame.Angles(math.rad(-17), 0, 0),
				color = (i % 2 == 0) and Color3.fromRGB(226, 74, 74)
					or Color3.fromRGB(248, 244, 236),
				material = Enum.Material.SmoothPlastic,
				collide = false, studs = false, parent = hub })
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

		--== THE SHOPKEEPER ==--
		-- Behind her own counter, at head height. Built here and MOVED on each
		-- client -- see HubFairy for why that split.
		-- Between the counter and the shelf, at head height. Forward of the
		-- jars rather than level with them, or she reads as one more jar.
		-- She is a walking Humanoid now, so this is a spot on the FLOOR rather
		-- than a hover point: on the riser behind her own counter.
		-- HubFairy lifts her the 3 studs an R6 root sits above its feet, and
		-- FairyService wanders her either side of here.
		--
		-- Rotated to look out over the counter, which is the direction the SELL
		-- face points and the side every customer walks up from.
		HubFairy.build(stallCF * CFrame.new(0, 2, -5.5) * CFrame.Angles(0, math.pi, 0), hub)
	end

	--== PLOTS ==--
	local plots = Instance.new("Folder")
	plots.Name = MAP.PlotsFolderName
	plots.Parent = folder

	local n = GameConfig.MaxPlots
	local tier = GameConfig.PlotTiers[GameConfig.StartingPlotTier]
	local depth = GameConfig.plotDepthFor(tier.rows)

	-- ANGLES ARE MEASURED FROM +Z, WHICH IS AWAY FROM THE ROAD. So 180 degrees
	-- points straight up the road, and that is precisely the arc left empty.
	--
	-- The plots are spread evenly across whatever is left, which means the gaps
	-- between neighbours are equal AND nothing is ever placed in the road's
	-- mouth -- rather than placing six evenly round the full circle and hoping
	-- none of them lands in the way.
	local gap = math.rad(MAP.RoadGapDegrees)
	local usable = math.pi * 2 - gap
	local step = usable / n
	local start = math.pi + gap * 0.5   -- the near edge of the empty arc

	for id = 1, n do
		local angle = start + (id - 0.5) * step
		-- The GATE sits on the ring, at the same radius for every plot and at
		-- every tier. The plot centre is half its depth further out, so growth
		-- moves the back edge and never the gate.
		local gateR = MAP.PlotRingInner
		local centreR = gateR + depth * 0.5
		local pos = Vector3.new(math.sin(angle) * centreR, Y, math.cos(angle) * centreR)
		-- lookAt points local -Z at the hub, and local -Z is where buildPlot puts
		-- the gate -- so every gate faces the middle and every plot grows
		-- outward, with no per-plot rotation maths.
		local cf = CFrame.lookAt(pos, Vector3.new(0, Y, 0))
		buildPlot(id, cf, tier.rows, plots)

		-- Just outside the gate, on the ring's inner walkway. Placed off the
		-- GATE radius rather than off the plot, so it stays put when the plot
		-- behind it grows.
		local millR = gateR - 15
		buildTreadmill(id, CFrame.lookAt(
			Vector3.new(math.sin(angle) * millR, Y + 0.6, math.cos(angle) * millR),
			Vector3.new(0, Y + 0.6, 0)), plots)
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
	--== DO THE PLOTS FIT ON THE RING ==--
	-- The tightest point is the INNER edge, where the radius is smallest and the
	-- same 48-stud width subtends the widest angle. If they clear there they
	-- clear everywhere, at every tier -- which is the property that makes
	-- outward expansion safe.
	local step = (math.pi * 2 - math.rad(MAP.RoadGapDegrees)) / n
	local arcAtGate = step * MAP.PlotRingInner
	if arcAtGate < PLOT.Width + 8 then
		warn(string.format(
			"[Seed/MapService] %d plots leave only %.0f studs of arc at the gate radius for a " ..
			"%d-stud plot. Raise PlotRingInner or lower MaxPlots.",
			n, arcAtGate, PLOT.Width))
	end

	-- Nothing may reach into the road's mouth.
	local reach = PLOT.MaxReach
	if reach + 20 > MAP.FieldBack then
		warn(string.format(
			"[Seed/MapService] Tier %d plots reach %.0f studs from the hub but the field only " ..
			"extends %d back. Raise FieldBack.",
			#GameConfig.PlotTiers, reach, MAP.FieldBack))
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
	return position.X >= -halfW and position.X <= halfW
		and position.Z >= -MAP.FieldFront and position.Z <= MAP.FieldBack
end

return MapService
