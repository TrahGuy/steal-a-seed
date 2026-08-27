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
local MillModel = require(Shared:WaitForChild("MillModel"))
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
-- Straight off the owner's photo: a warm rust soil inside a mid-brown border,
-- both a good deal more saturated than the washed-out pair they replace.
local BED_SOIL = Color3.fromRGB(158, 82, 52)
-- The furrow is the same earth in shadow rather than a second brown: same hue,
-- pulled down in value. A different brown would read as two materials.
local BED_FURROW = Color3.fromRGB(112, 56, 34)
-- And the clods are the same earth turned up to the light.
local BED_CLOD = Color3.fromRGB(184, 106, 70)
local BED_FRAME = Color3.fromRGB(124, 84, 56)
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
	-- Four sides with a GAP AT THE FRONT for the gate. The gate is the way in
	-- because it is now the ONLY way in -- this used to be walk-through, and the
	-- gap only SHOWED you the entrance rather than being it.
	--
	-- THE LOOK AND THE RULE ARE SEPARATE PARTS. The rails and posts you can see
	-- stay non-collidable; an invisible slab down the middle of each run is what
	-- actually stops anybody. A rail is 0.6 studs thick and a player at 150
	-- WalkSpeed covers 2.5 in a frame, so flipping CanCollide on the visible
	-- fence would give a wall that holds when you walk into it and lets you
	-- through when you sprint -- the fast players would find the hole and nobody
	-- would be able to reproduce it. Same split as the road's Nightfall barrier,
	-- for the same reason.
	--
	-- Built as segments between two coordinates rather than as four whole
	-- sides, because the front is two pieces and a special case for it would be
	-- a second copy of the same rail-and-post code.
	local function fenceRun(alongX: boolean, fixed: number, from: number, to: number)
		local length = math.abs(to - from)
		if length < 0.5 then
			return
		end
		local mid = (from + to) * 0.5

		--==================================================================
		-- THE SLAB THAT DOES THE WORK
		--
		-- CanQuery false as well as invisible: PlantPlace raycasts at the soil
		-- to decide where a click lands, and a solid pane around the bed would
		-- otherwise eat clicks aimed over the fence from outside.
		--==================================================================
		local wall = build({
			name = "FenceCollider",
			size = alongX
				and Vector3.new(length, PLOT.FenceColliderHeight, PLOT.FenceColliderThickness)
				or Vector3.new(PLOT.FenceColliderThickness, PLOT.FenceColliderHeight, length),
			cframe = cf * (alongX
				and CFrame.new(mid, PLOT.FenceColliderHeight * 0.5, fixed)
				or CFrame.new(fixed, PLOT.FenceColliderHeight * 0.5, mid)),
			color = FENCE,
			transparency = 1,
			studs = false,
			parent = model,
		})
		wall.CanQuery = false
		wall.CanTouch = false
		wall.CastShadow = false

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

	--== THE BED ==--
	--
	-- One soil rectangle inside a raised wooden border, matching the reference
	-- photo.
	--
	-- THE BORDER IS FOUR BARS, NOT ONE SLAB. A slab was the first attempt, on the
	-- reasoning that its middle would be hidden under the soil anyway. It is
	-- not: the border stands PROUD of the soil, so a solid slab's top face sits
	-- ABOVE the soil and covers it completely. The whole plot rendered as a
	-- wooden floor with no dirt anywhere in it.
	local plants = Instance.new("Folder")
	plants.Name = PLOT.PlantsFolderName
	plants.Parent = model

	local cols = PLOT.BedColumns
	local bedW = width - PLOT.BedInsetX * 2 - PLOT.BedFrameWidth * 2
	local bedSpan = rows * PLOT.RowDepth + (rows - 1) * PLOT.RowGap
	local fw = PLOT.BedFrameWidth
	local soilTop = PLOT.BedHeight
	local frameTop = soilTop + PLOT.BedFrameLip

	for _, bar in ipairs({
		-- Front and back run the full outer width so the corners close.
		{ Vector3.new(bedW + fw * 2, frameTop, fw), CFrame.new(0, 0, -(bedSpan + fw) * 0.5) },
		{ Vector3.new(bedW + fw * 2, frameTop, fw), CFrame.new(0, 0, (bedSpan + fw) * 0.5) },
		{ Vector3.new(fw, frameTop, bedSpan), CFrame.new(-(bedW + fw) * 0.5, 0, 0) },
		{ Vector3.new(fw, frameTop, bedSpan), CFrame.new((bedW + fw) * 0.5, 0, 0) },
	}) do
		build({
			name = "BedFrame",
			size = bar[1],
			cframe = cf * (bar[2] + Vector3.new(0, frameTop * 0.5, 0)),
			color = BED_FRAME,
			material = Enum.Material.WoodPlanks,
			collide = false,
			studs = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THIS SLAB IS THE FURROW FLOOR, AND IT MUST NOT MOVE
	--
	-- It was one flat brown -- a 34 x 121 stud rectangle at the biggest tier,
	-- the largest single surface in the game, with less going on than the grass
	-- beside it. It is the DARK earth now and the rows are built on top of it,
	-- so what shows between them is a furrow.
	--
	-- Its size and CFrame are load-bearing beyond the look: PlantService puts
	-- every plant at `soil.CFrame * CFrame.new(x, soil.Size.Y * 0.5, z)`, so
	-- changing either would lift or sink every garden that has ever been saved.
	-- Only the colour changed.
	--==========================================================================
	local soil = build({
		name = PLOT.PlanterName,
		size = Vector3.new(bedW, soilTop, bedSpan),
		cframe = cf * CFrame.new(0, soilTop * 0.5, 0),
		color = BED_FURROW,
		-- STUDDED, AND THEREFORE PLASTIC. Ground and Grass both render their own
		-- noise texture OVER the studs, so a bed set to TopSurface = Studs comes
		-- out looking smooth while the field beside it is visibly studded.
		-- Plastic is the material that actually shows them.
		material = Enum.Material.Plastic,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(soil, GameConfig.Tags.Planter)

	--==========================================================================
	-- THE BED IS TILLED
	--
	-- The rows already exist in the data -- RowDepth and RowGap have decided
	-- where plants stand since the first build -- and nothing ever drew them.
	-- Now they are mounded: a band of lighter earth per row, raised off the dark
	-- slab, with the slab showing through between them as the furrow.
	--
	-- Built off the SAME expression the slot grid below uses for a row centre,
	-- so the mounds and the planting cannot drift apart -- and if the rows are
	-- ever retuned, both follow.
	--
	-- DETERMINISTIC, never random. Two servers must build the same garden, and
	-- "the third bed looked wrong" has to mean something.
	--==========================================================================
	local rise = PLOT.SoilRowRise
	for row = 1, rows do
		local rowCentre = -bedSpan * 0.5 + (row - 0.5) * PLOT.RowDepth
			+ (row - 1) * PLOT.RowGap
		build({
			name = "SoilRow",
			size = Vector3.new(bedW, rise, PLOT.RowDepth),
			cframe = cf * CFrame.new(0, soilTop + rise * 0.5, rowCentre),
			color = BED_SOIL,
			material = Enum.Material.Plastic,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- CLODS, IN THE FURROWS AND NOWHERE ELSE
	--
	-- Plants stand in row CENTRES, on the mounds. A clod there would end up
	-- inside somebody's Bellchime, so they go in the gaps -- which is also where
	-- broken earth would actually collect.
	--
	-- Every other gap gets them. On all of them they read as gravel rather than
	-- as a tilled bed.
	--==========================================================================
	for gap = 1, rows - 1 do
		if gap % PLOT.SoilClodStride == 1 then
			local rowCentre = -bedSpan * 0.5 + (gap - 0.5) * PLOT.RowDepth
				+ (gap - 1) * PLOT.RowGap
			local furrowZ = rowCentre + PLOT.RowDepth * 0.5 + PLOT.RowGap * 0.5
			for c = 1, PLOT.SoilClodsPerFurrow do
				local across = (c - (PLOT.SoilClodsPerFurrow + 1) * 0.5)
					* (bedW / (PLOT.SoilClodsPerFurrow + 1))
				-- Nudged by the gap index so the scatter does not line up into a
				-- second grid.
				local jitter = ((gap * 7) % 5 - 2) * (bedW * 0.06)
				local size = PLOT.SoilClodSize * (1 + ((gap + c) % 3) * 0.18)
				build({
					name = "Clod",
					size = Vector3.new(size, size * 0.5, size),
					cframe = cf * CFrame.new(across + jitter, soilTop, furrowZ),
					color = BED_CLOD,
					material = Enum.Material.Plastic,
					collide = false,
					parent = model,
				})
			end
		end
	end

	--== PLANT SLOTS ==--
	-- An INVISIBLE grid on the soil. Attachments, so a slot costs nothing until
	-- something grows in it, and the reference's plain rectangle keeps its plain
	-- rectangle -- the layout is known without being drawn on the ground.
	--
	--==========================================================================
	-- NOTHING IS PLANTED INTO THESE ANY MORE
	--
	-- Planting is by click now: PlantService puts a plant exactly where the
	-- player pointed and stores an offset local to the soil. The grid is kept
	-- for ONE job -- a save written before that change carries a Slot index and
	-- no position, and this is the table that says where index N used to be. It
	-- is read once, on load, and the garden is written back out as offsets.
	--
	-- The tier still decides HOW MANY plants fit; it just no longer decides
	-- where they stand. GameConfig.plotSlotsFor is the count both sides use.
	--
	-- Delete these once no live profile can still carry a Slot -- and not
	-- before, because what they migrate is somebody's garden.
	--==========================================================================
	local slot = 0
	for row = 1, rows do
		local rowZ = -bedSpan * 0.5 + (row - 0.5) * PLOT.RowDepth
			+ (row - 1) * PLOT.RowGap
		for col = 1, cols do
			slot += 1
			local colX = (col - (cols + 1) * 0.5) * (bedW / cols)
			local a = Instance.new("Attachment")
			a.Name = string.format("Slot%02d", slot)
			a:SetAttribute("SlotIndex", slot)
			a:SetAttribute("Row", row)
			a:SetAttribute("Column", col)
			-- LOCAL to the soil, deliberately, and not WorldCFrame.
			-- WorldCFrame on an attachment with no parent yet is just CFrame, so
			-- setting it before parenting wrote a world coordinate into a local
			-- field and the soil's own CFrame was then applied on top -- every
			-- slot landed ~100 studs off the bed. Latent until PlantService
			-- became the first thing to read them.
			-- Soil sits at cf * CFrame.new(0, soilTop * 0.5, 0), so this puts the
			-- slot on its top face, independent of assignment order.
			a.CFrame = CFrame.new(colX, soilTop * 0.5, rowZ)
			a.Parent = soil
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
--==============================================================================
-- THE MILL IS BUILT BY MillModel NOW
--
-- What used to be here was one wood slab and a smooth grey belt, and it was the
-- same object on every plot forever. There are seven of them now and which one
-- a plot gets depends on what its owner has bought, so the geometry moved to a
-- shared builder that TreadmillService can call again when that changes.
--
-- The map still puts it THERE and stamps whose it is. Everything a mill needs to
-- be found by -- the model name, the PlotId, the tag on the belt -- is set here,
-- because those are the map's contract with the service and not part of the
-- look.
--
-- Built at the starting tier: MapService also runs in Edit for previewing the
-- layout, where nobody owns anything. TreadmillService rebuilds it at the
-- owner's real tier the moment a plot is claimed.
--==============================================================================
local function buildTreadmill(id: number, cf: CFrame, parent: Instance): Model
	local model, belt = MillModel.Build(GameConfig.Mill.StartingTier, cf, parent)
	model.Name = string.format("%s%02d", PLOT.TreadmillName, id)
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)

	--==========================================================================
	-- BESIDE THE FENCE, TURNED TO FACE WHOEVER IS COMING
	--
	-- Both numbers live in GameConfig.Mill.Sign, with the working for the yaw --
	-- it is the bearing from the sign to this plot's spawn pad, not a taste
	-- decision. Placed off the mill's own CFrame, so it swings round with the
	-- plot and needs no angle maths here.
	--==========================================================================
	local SIGN = GameConfig.Mill.Sign
	local sign = MillModel.BuildSign(
		cf * CFrame.new(SIGN.Offset) * CFrame.Angles(0, math.rad(SIGN.YawDegrees), 0), model)
	sign:SetAttribute(GameConfig.Attributes.PlotId, id)

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
	model:SetAttribute("RecommendedSpeed", biome.RecommendedSpeed)
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
	-- Non-collidable: this is an entrance marker, never an access wall.
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
	gate:SetAttribute("RecommendedSpeed", biome.RecommendedSpeed)
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

		--==================================================================
		-- THE NAME, AND THE RECOMMENDED SPEED
		--
		-- The arch is guidance, not a lock. Everyone can pass it during the day;
		-- the smaller second line says how much Speed makes the chase feel fair.
		--
		-- The number is small and under the name rather than beside it: the
		-- biome is what you are looking at, the recommendation is what you check.
		-- Greenhollow has no recommendation and gets no second line.
		--==================================================================
		local named = biome.RecommendedSpeed > 0

		local text = Instance.new("TextLabel")
		text.Size = if named then UDim2.fromScale(1, 0.62) else UDim2.fromScale(1, 1)
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

		if named then
			local need = Instance.new("TextLabel")
			need.Name = "Recommendation"
			need.AnchorPoint = Vector2.new(0.5, 1)
			need.Position = UDim2.fromScale(0.5, 1)
			need.Size = UDim2.fromScale(1, 0.34)
			need.BackgroundTransparency = 1
			need.Font = Enum.Font.GothamBlack
			-- The shared compactor, so the arch and the HUD spell the same
			-- number the same way.
			need.Text = "RECOMMENDED " .. GameConfig.compact(biome.RecommendedSpeed) .. " SPEED"
			need.TextScaled = true
			need.TextColor3 = Color3.fromRGB(255, 255, 255)
			need.Parent = sign

			local ns = Instance.new("UIStroke")
			ns.Thickness = 3
			ns.Color = Color3.fromRGB(38, 26, 16)
			ns.Parent = need
		end
	end

	--== NESTS ==--
	-- MapService only marks WHERE a nest goes. NestService builds what stands
	-- there -- the sleeping parent and the ring of pods around it -- because a
	-- nest has STATE and the map has none. MapService is destroy-and-rebuild
	-- geometry; a parent mid-chase is not something to rebuild under.
	local nests = Instance.new("Folder")
	nests.Name = "Nests"
	nests.Parent = model
	CollectionService:AddTag(nests, GameConfig.Tags.WildPatch)

	for index, nestCF in ipairs(BiomeData.NestCFrames(biome)) do
		local marker = build({
			name = string.format("NestSite%02d", index),
			size = Vector3.new(2, 0.2, 2),
			cframe = nestCF,
			color = biome.AccentColor,
			transparency = 1,
			collide = false,
			studs = false,
			parent = nests,
		})
		marker.CanQuery = false
		marker:SetAttribute(GameConfig.Attributes.BiomeId, biome.Id)
		marker:SetAttribute("NestIndex", index)
		CollectionService:AddTag(marker, GameConfig.Tags.NestSite)
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
-- THE NIGHTFALL BARRIER
--
-- One part across the mouth of the road, at the field's front edge, which is
-- also biome one's near plane. Invisible and walk-through by day; opaque and
-- solid at night.
--
-- A WALL RATHER THAN DARKNESS, because darkness is a LOOK and a look is not a
-- rule. A player can turn their graphics down, disable shadows, or simply have a
-- brighter monitor, and any of those would let them see down a corridor that is
-- supposed to be shut. This does not depend on how anybody has their settings.
--
-- It is deliberately NOT the only thing stopping them: BiomeGateService puts
-- anybody past the road mouth back in the field ten times a second AT NIGHT.
-- The barrier is what you can see; the server check is what prevents clipping.
--
-- BUILT WITH THE MAP, so it is re-run safe for free -- MapService.Init destroys
-- the whole SeedMap folder and builds it again, which is the project's answer
-- to Rule 10 everywhere else and needs no special case here.
--==============================================================================
local function buildNightBarrier(parent: Instance): BasePart
	local CYCLE = GameConfig.WorldCycle
	local B = CYCLE.Barrier
	local Y = MAP.GroundY
	local height = MAP.WallHeight + B.HeightPad

	local barrier = build({
		name = B.Name,
		size = Vector3.new(MAP.CorridorWidth + B.WidthPad, height, B.Thickness),
		--==================================================================
		-- IT ENDS ON THE PLANE, IT DOES NOT SIT ON IT
		--
		-- Centring it on -FieldFront put it EXACTLY where the biome arch already
		-- is -- the arch is built at the same nearZ, four studs deep, same as
		-- this -- so the two were coplanar and the gate's name plate z-fought
		-- its way through a wall that is supposed to be opaque. Seen in a
		-- playtest: "Greenhollow" legible in the middle of a black screen.
		--
		-- Offset by half its thickness toward the FIELD, so its far face lands
		-- on the plane and its near face is the first thing anybody meets. The
		-- gate rule is still the plane; this now fills the last two studs up to
		-- it and hides the arch behind it rather than fighting with it.
		--==================================================================
		cframe = CFrame.new(0, Y + height * 0.5, -MAP.FieldFront + B.Thickness * 0.5),
		color = B.Colour,
		material = Enum.Material.SmoothPlastic,
		studs = false,
		parent = parent,
	})
	-- Day is the state a fresh map is in, because a fresh server starts in Day.
	barrier.Transparency = 1
	barrier.CanCollide = false
	barrier.CanTouch = false
	barrier.CanQuery = false
	barrier.Anchored = true
	barrier.CastShadow = false
	CollectionService:AddTag(barrier, GameConfig.Tags.NightBarrier)
	return barrier
end

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
	--==========================================================================
	-- Archivable = false IS WHAT KEEPS THE MAP OUT OF THE PLACE FILE.
	--
	-- The map is code, so a copy of it saved into the .rbxl is the one thing
	-- this project exists not to have: the runtime build would then be fighting
	-- a stale duplicate on every boot. The rule used to be a human one -- "delete
	-- Workspace.SeedMap before saving" -- and a rule you have to remember is a
	-- rule that gets forgotten. Worse, obeying it left Studio looking EMPTY,
	-- which reads as something being broken and cost two rounds of "where did
	-- the map go".
	--
	-- Archivable = false is the engine's own answer: the instance is skipped
	-- when the place is saved AND when the datamodel is cloned. So the map can
	-- sit in Edit permanently for eyeballing, it never reaches the file, and
	-- pressing Play cannot carry an Edit-built copy into the session either.
	-- Nobody has to remember anything.
	--==========================================================================
	folder.Archivable = false
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
		-- HALF the thickness in, not a whole one, so the stripe's OUTER edge
		-- lands exactly on the field edge -- which is the boundary
		-- IsInSafeZone actually tests. At a full thickness the paint sat 1.25
		-- studs inside the real line, leaving a band where a player stood
		-- past the mark and was still counted safe. In a game whose central
		-- question is "am I safe yet", the paint and the check answering
		-- differently is the one disagreement that must not exist.
		cframe = CFrame.new(0, Y + 0.2, -MAP.FieldFront + MAP.SafeLineThickness * 0.5),
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

		-- DISPLAY TRAYS AT HER SIDES, NOT A SHELF OVER HER HEAD. The produce
		-- used to sit on a high back shelf, which put the whole display directly
		-- above Marigold -- so the thing the stall is selling and the person
		-- selling it competed for the same patch of screen, and she lost.
		--
		-- On the counter beside her, the goods are at the height a customer
		-- actually looks at and she has the middle to herself.
		local jarColors = {
			Color3.fromRGB(226, 96, 84), Color3.fromRGB(240, 190, 74),
			Color3.fromRGB(126, 198, 106), Color3.fromRGB(150, 130, 226),
			Color3.fromRGB(238, 140, 178), Color3.fromRGB(120, 200, 214),
		}
		for _, side in ipairs({ -1, 1 }) do
			build({ name = "Tray", size = Vector3.new(5.5, 0.5, 5),
				cframe = stallCF * CFrame.new(side * 6.6, 5.35, 0),
				color = WOOD_DARK, material = Enum.Material.WoodPlanks,
				collide = false, studs = false, parent = hub })
			for i = 1, 3 do
				local c = jarColors[((side < 0 and 0 or 3) + i)]
				build({ name = "Produce", size = Vector3.new(1.3, 1.3, 1.3),
					cframe = stallCF * CFrame.new(side * 6.6 + (i - 2) * 1.7, 6.2,
						(i % 2 == 0) and 0.9 or -0.9),
					color = c, material = Enum.Material.Plastic,
					collide = false, parent = hub })
			end
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

		-- BESIDE THE PLOT, NOT IN FRONT OF IT. It used to sit on the ring's
		-- inner walkway directly outside the gate, which is the one patch of
		-- ground every single run passes through -- an obstacle parked in your
		-- own doorway. Alongside the right-hand fence it is out of the way and
		-- still obviously yours.
		--
		-- Placed off the plot's own CFrame, so it swings round with the plot and
		-- needs no angle maths of its own.
		buildTreadmill(id, cf * CFrame.new(PLOT.Width * 0.5 + 11, 0.6, 0), plots)
	end

	--== FIELD DRESSING ==--
	-- After the plots, so the beds are placed around them rather than under.
	MapDecor.dressField(props)

	--== THE ROAD'S SHUTTER ==--
	-- After the props, so it is the last thing at the mouth and nothing dressed
	-- afterwards can be left standing in front of it.
	buildNightBarrier(props)

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

--==============================================================================
-- OPEN AND SHUT
--
-- Server-owned, both properties. The night LIGHTING is the client's job and is
-- animated there, but concealment is a rule and a rule cannot be left to
-- whoever is rendering it -- a client that skipped the fade would be a client
-- that could see down the road.
--==============================================================================
function MapService.SetNightBarrier(closed: boolean)
	local barrier = MapService.GetNightBarrier()
	if not barrier then
		return false
	end
	local B = GameConfig.WorldCycle.Barrier
	barrier.Transparency = if closed then B.NightTransparency else 1
	barrier.CanCollide = closed
	barrier.CanQuery = closed
	return true
end

function MapService.GetNightBarrier(): BasePart?
	for _, part in ipairs(CollectionService:GetTagged(GameConfig.Tags.NightBarrier)) do
		if part:IsA("BasePart") and part.Parent then
			return part
		end
	end
	return nil
end

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
