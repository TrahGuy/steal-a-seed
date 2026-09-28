--!strict
-- Steal a Seed :: PlotOwnerLabels
--
-- Who holds each plot, and what their garden holds, for every viewer.
--
--   THE BADGE       the owner's Roblox headshot in a round frame, their
--                   username under it, floating high over the gate. The
--                   viewer's own plot wears an accent ring.
--   THE PLAQUE      plants and income on a small board just outside the
--                   entrance, across the gate from the upgrade board.
--   UNCLAIMED       a free plot keeps one small word at the gate and nothing
--                   else.
--
--==============================================================================
-- THE BADGE REPLACED THE NAMEPLATE (owner, 2026-09-26)
--
-- The low YOUR BASE / display-name plate over the gate is gone, not kept
-- alongside: one answer to "whose is this", and it is a face. The garden's two
-- lines that briefly hung under that plate moved to the plaque, because a block
-- of numbers floating over every plot is clutter the hub does not need.
--
--==============================================================================
-- NONE OF IT IS THE CLIENT'S DECISION
--
-- Who holds a plot is the OwnerUserId PlotService stamps on it: set on
-- assignment, zeroed on release, set again for the next owner. The numbers are
-- what EconomyService pays from and publishes (GameConfig.Attributes.GardenGrown
-- and friends), cleared with the owner. This only listens. No remote, nothing
-- selectable, nothing that takes a click or a touch.
--
-- STREAMING. A plot's PARTS come and go with distance; the tagged Model and its
-- attributes stay. So everything here hangs off local Attachments in Terrain
-- and a local plaque, placed from the plot's PlotCF and Depth -- never off a
-- part that could stream out from under it -- and moved whenever an upgrade
-- changes either.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local ATTR = GameConfig.Attributes
local BADGE = GameConfig.Plot.OwnerBadge
local FREE = GameConfig.Plot.UnclaimedTag
local SIGN = GameConfig.Plot.StatsSign
local TAG = GameConfig.Tags.Plot
local PREFIX = "SeedPlotLabel_"
local SIGN_FOLDER = "SeedPlotPlaques"

-- The upgrade board's wood, so the two boards either side of a gate match.
local OAK = Color3.fromRGB(126, 88, 54)
local OAK_DARK = Color3.fromRGB(92, 62, 38)
local PLANK = Color3.fromRGB(72, 54, 40)

type PlaqueFace = {
	plants: TextLabel,
	hatching: TextLabel,
	earning: TextLabel,
	boosted: TextLabel,
}

type Plate = {
	anchor: Attachment,
	board: BillboardGui,
	ring: Frame,
	face: ImageLabel,
	initial: TextLabel,
	name: TextLabel,
	tagAnchor: Attachment,
	tag: BillboardGui,
	plaque: Model,
	faces: { PlaqueFace },
	placed: boolean,
	-- Which owner the face on this badge belongs to, and the load in flight for
	-- them. A load that finishes after the plot has changed hands checks the
	-- token and does nothing: the previous owner's face never lands on the next.
	shownFor: number?,
	token: number,
	-- The size clamp's last factor for the badge and the tag (see THE SIZE CLAMP).
	badgeFactor: number,
	tagFactor: number,
	conns: { RBXScriptConnection },
}

local plates: { [Model]: Plate } = {}

--==============================================================================
-- RE-RUN SAFE
--
-- A Rojo sync re-runs this with the last run's badges still hanging in Terrain
-- and its plaques still standing, and two of each a hair apart read as a
-- rendering fault.
--==============================================================================
for _, old in ipairs(Workspace.Terrain:GetChildren()) do
	if string.sub(old.Name, 1, #PREFIX) == PREFIX then
		old:Destroy()
	end
end
local oldFolder = Workspace:FindFirstChild(SIGN_FOLDER)
if oldFolder then
	oldFolder:Destroy()
end
local plaqueFolder = Instance.new("Folder")
plaqueFolder.Name = SIGN_FOLDER
plaqueFolder.Archivable = false
plaqueFolder.Parent = Workspace

--==============================================================================
-- HEADSHOTS, CACHED
--
-- The image itself is an rbxthumb:// id the engine fetches and caches, so
-- nothing here yields for it. What is cached here is the ANSWER -- whether that
-- owner's face has loaded or failed -- so a second badge for the same player,
-- or the same badge after a respawn of this script, skips straight to it.
--==============================================================================
local faceState: { [number]: string } = {}

local function outlined(parent: Instance, name: string, font: Enum.Font, colour: Color3,
	stroke: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextScaled = true
	label.TextColor3 = colour
	label.Text = ""
	label.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.new(0, 0, 0)
	edge.Thickness = stroke
	edge.Parent = label
	return label
end

local function circle(frame: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
end

--==============================================================================
-- THE PLAQUE
--
-- A short post and a small board, lettered on both faces the way the upgrade
-- board is: players read it walking in and walking out. Every part is anchored,
-- non-colliding, untouchable and not queryable -- it cannot stop a runner, and
-- a planting click's raycast passes straight through it.
--==============================================================================
local function woodPart(name: string, size: Vector3, colour: Color3, material: Enum.Material,
	parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildPlaque(): (Model, { PlaqueFace })
	local model = Instance.new("Model")
	model.Name = "Plaque"
	local post = woodPart("Post", Vector3.new(0.5, SIGN.PostHeight, 0.5), OAK_DARK,
		Enum.Material.Wood, model)
	post.CFrame = CFrame.new(0, SIGN.PostHeight * 0.5, 0)
	local board = woodPart("Board", SIGN.BoardSize, PLANK, Enum.Material.WoodPlanks, model)
	board.CFrame = CFrame.new(0, SIGN.PostHeight + SIGN.BoardSize.Y * 0.5 - 0.3, 0)
	local rim = woodPart("Rim", SIGN.BoardSize + Vector3.new(0.3, 0.3, -0.1), OAK,
		Enum.Material.Wood, model)
	rim.CFrame = board.CFrame

	local faces: { PlaqueFace } = {}
	for _, which in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local surface = Instance.new("SurfaceGui")
		surface.Name = if which == Enum.NormalId.Front then "Face" else "FaceBack"
		surface.Face = which
		surface.CanvasSize = Vector2.new(300, 134)
		surface.LightInfluence = 0
		surface.MaxDistance = SIGN.MaxDistance
		surface.Active = false
		surface.Parent = board

		local plants = outlined(surface, "Plants", Enum.Font.LuckiestGuy, SIGN.Plants, 2.5)
		plants.Position = UDim2.fromOffset(8, 6)
		plants.Size = UDim2.new(1, -16, 0, 36)
		local hatching = outlined(surface, "Hatching", Enum.Font.GothamBold, SIGN.Muted, 1.5)
		hatching.Position = UDim2.fromOffset(8, 42)
		hatching.Size = UDim2.new(1, -16, 0, 20)
		local earning = outlined(surface, "Income", Enum.Font.LuckiestGuy, SIGN.Income, 2.5)
		earning.Position = UDim2.fromOffset(8, 66)
		earning.Size = UDim2.new(1, -16, 0, 38)
		local boosted = outlined(surface, "Boost", Enum.Font.GothamBold, SIGN.Muted, 1.5)
		boosted.Position = UDim2.fromOffset(8, 106)
		boosted.Size = UDim2.new(1, -16, 0, 20)
		table.insert(faces, { plants = plants, hatching = hatching, earning = earning, boosted = boosted })
	end
	-- Pivot at the post's FOOT, so PivotTo(ground) stands it on the ground. A
	-- pivot at the post's centre is how the mill's board once climbed -- or here,
	-- sank half a post into the grass.
	model.WorldPivot = CFrame.new()
	return model, faces
end

--==============================================================================
-- WHERE EVERYTHING STANDS
--
-- The badge and the tag over the middle of the gate, the plaque just outside
-- the fence at +OffsetX. The gate does not move when a plot grows -- ResizePlot
-- keeps it and grows the plot backwards -- but PlotCF and Depth both change, so
-- all three are placed again whenever either does.
--==============================================================================
local function place(plot: Model, plate: Plate)
	local cf = plot:GetAttribute("PlotCF")
	local depth = plot:GetAttribute("Depth")
	if typeof(cf) ~= "CFrame" or type(depth) ~= "number" then
		plate.placed = false
		return
	end
	plate.placed = true
	-- CFrame, not WorldCFrame: Terrain sits at the origin, so the two are the
	-- same number, and this one does not care whether an anchor is parented yet.
	local gate = (cf :: CFrame) * CFrame.new(0, 0, -(depth :: number) * 0.5)
	plate.anchor.CFrame = gate * CFrame.new(0, BADGE.HeightStuds, 0)
	plate.tagAnchor.CFrame = gate * CFrame.new(0, FREE.HeightStuds, 0)
	plate.plaque:PivotTo(gate * CFrame.new(SIGN.OffsetX, SIGN.GroundY, -SIGN.Standoff))
end

local function capacityOf(plot: Model): number
	local n = tonumber(plot:GetAttribute("Capacity"))
	if n and n == n and n > 0 then
		return n
	end
	return GameConfig.plotCapacityForTier(tonumber(plot:GetAttribute("Level")))
end

--==============================================================================
-- THE NUMBERS
--
-- Standing only while the plot is claimed AND its numbers exist: an owner whose
-- garden is still being restored gets a badge and no plaque, which is true,
-- rather than 0/10, which is not. Taken out of the world when there is nothing
-- to say, so a free plot has no blank board by its gate either.
--==============================================================================
local function paintStats(plot: Model, plate: Plate)
	local owner = plot:GetAttribute(ATTR.OwnerUserId)
	local plants, hatching, earning, boosted = GameConfig.plotStatsText(
		plot:GetAttribute(ATTR.GardenGrown), plot:GetAttribute(ATTR.GardenPods),
		capacityOf(plot), plot:GetAttribute(ATTR.GardenIncome), plot:GetAttribute(ATTR.GardenBoost))
	local show = plate.placed and type(owner) == "number" and owner > 0 and plants ~= nil
	plate.plaque.Parent = if show then plaqueFolder else nil
	if not show then
		return
	end
	for _, face in ipairs(plate.faces) do
		face.plants.Text = plants :: string
		face.hatching.Text = hatching :: string
		face.earning.Text = earning :: string
		face.boosted.Text = boosted :: string
	end
end

--==============================================================================
-- THE FACE
--
-- Set at once from the id, so there is no request whose answer could arrive
-- for the wrong owner. While it loads -- and for good, if it never does -- the
-- round frame shows the owner's initial on the badge fill instead of a blank.
--==============================================================================
local function paintFace(plate: Plate, ownerId: number, name: string)
	plate.token += 1
	local token = plate.token
	plate.face.Image = GameConfig.avatarHeadshot(ownerId)
	plate.initial.Text = if name ~= "" then string.upper(string.sub(name, 1, 1)) else "?"
	local known = faceState[ownerId]
	if known then
		plate.initial.Visible = known == "failed"
		return
	end
	plate.initial.Visible = true
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ plate.face })
		end)
		-- A newer owner, or a release, took this badge while it loaded.
		if plate.token ~= token then
			return
		end
		local loaded = plate.face.IsLoaded
		faceState[ownerId] = if loaded then "loaded" else "failed"
		plate.initial.Visible = not loaded
	end)
end

local function paint(plot: Model, plate: Plate)
	local raw = plot:GetAttribute(ATTR.OwnerUserId)
	local ownerId = if type(raw) == "number" then raw else nil
	-- The owner is in this server by definition -- plots belong to its players --
	-- so their Player carries the username. OwnerName is the fallback for the
	-- moment the attribute lands before the Player does.
	local owner = if ownerId and ownerId > 0 then Players:GetPlayerByUserId(ownerId) else nil
	local stamped = plot:GetAttribute(ATTR.OwnerName)
	local username = if owner then owner.Name elseif type(stamped) == "string" then stamped else nil
	local kind, name = GameConfig.plotBadgeFor(ownerId, player.UserId, username)
	local claimed = kind ~= "free"
	plate.board.Enabled = claimed and plate.placed
	plate.tag.Enabled = (not claimed) and plate.placed
	if claimed then
		plate.ring.BackgroundColor3 = if kind == "mine" then BADGE.RingMine else BADGE.RingTheirs
		plate.name.Text = name
		if plate.shownFor ~= ownerId then
			plate.shownFor = ownerId
			paintFace(plate, ownerId :: number, name)
		end
	else
		-- Released: whatever was loading was somebody who no longer holds it.
		plate.shownFor = nil
		plate.token += 1
		plate.face.Image = ""
		plate.name.Text = ""
	end
	paintStats(plot, plate)
end

local function build(instance: Instance)
	if not instance:IsA("Model") or plates[instance :: Model] then
		return
	end
	local plot = instance :: Model
	local id = tostring(plot:GetAttribute(ATTR.PlotId) or plot.Name)

	local anchor = Instance.new("Attachment")
	anchor.Name = PREFIX .. id
	anchor.Archivable = false

	--==========================================================================
	-- THE BADGE
	--
	-- Studs, clamped below (THE SIZE CLAMP): never bigger than it looks from
	-- NearStuds, never smaller than from FarStuds, gone past MaxDistance.
	-- Behind whatever stands in front of it, like any sign, and inert to every
	-- input.
	--==========================================================================
	local board = Instance.new("BillboardGui")
	board.Name = "OwnerBadge"
	board.Size = UDim2.new(BADGE.WidthStuds, 0, BADGE.TallStuds, 0)
	board.MaxDistance = BADGE.MaxDistance
	-- Read, not lit: the day/night cycle must not take the face off the gate.
	board.LightInfluence = 0
	-- In the world, behind whatever stands in front of it -- it labels a place
	-- and must never draw over a chase happening between you and it.
	board.AlwaysOnTop = false
	board.ResetOnSpawn = false
	board.Active = false
	board.Enabled = false
	board.Parent = anchor

	-- The frame: an accent disc with the headshot inset by the ring's width, so
	-- the ring scales with the badge instead of being a fixed pixel stroke.
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.fromScale(0.5, 0)
	ring.Size = UDim2.fromScale(1, BADGE.FaceShare)
	ring.BorderSizePixel = 0
	ring.BackgroundColor3 = BADGE.RingTheirs
	ring.Active = false
	ring.Parent = board
	circle(ring)
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = ring

	local face = Instance.new("ImageLabel")
	face.Name = "Headshot"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1 - BADGE.RingShare * 2, 1 - BADGE.RingShare * 2)
	face.BackgroundColor3 = BADGE.Fill
	face.BorderSizePixel = 0
	face.ScaleType = Enum.ScaleType.Crop
	face.Image = ""
	face.Active = false
	face.Parent = ring
	circle(face)

	local initial = outlined(face, "Initial", Enum.Font.LuckiestGuy, BADGE.Name, 2)
	initial.AnchorPoint = Vector2.new(0.5, 0.5)
	initial.Position = UDim2.fromScale(0.5, 0.52)
	initial.Size = UDim2.fromScale(0.6, 0.6)

	local name = outlined(board, "Username", Enum.Font.GothamBlack, BADGE.Name, 2)
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.fromScale(0.5, 1)
	name.Size = UDim2.fromScale(1, 1 - BADGE.FaceShare - 0.03)

	--==========================================================================
	-- UNCLAIMED: ONE SMALL WORD, LOWER DOWN, AND ONLY FROM NEARBY
	--==========================================================================
	local tagAnchor = Instance.new("Attachment")
	tagAnchor.Name = PREFIX .. id .. "_Free"
	tagAnchor.Archivable = false
	local tag = Instance.new("BillboardGui")
	tag.Name = "Unclaimed"
	tag.Size = UDim2.new(FREE.WidthStuds, 0, FREE.TallStuds, 0)
	tag.MaxDistance = FREE.MaxDistance
	tag.LightInfluence = 0
	tag.AlwaysOnTop = false
	tag.ResetOnSpawn = false
	tag.Active = false
	tag.Enabled = false
	tag.Parent = tagAnchor
	local word = outlined(tag, "Word", Enum.Font.LuckiestGuy, FREE.Colour, 1.5)
	word.Size = UDim2.fromScale(1, 1)
	word.Text = "Unclaimed"
	word.TextTransparency = 0.1

	local plaque, faces = buildPlaque()
	plaque.Name = "Plaque_" .. id

	local plate: Plate = {
		anchor = anchor, board = board, ring = ring, face = face, initial = initial, name = name,
		tagAnchor = tagAnchor, tag = tag, plaque = plaque, faces = faces,
		placed = false, shownFor = nil, token = 0, badgeFactor = 1, tagFactor = 1, conns = {},
	}
	plates[plot] = plate
	for _, attr in ipairs({ ATTR.OwnerUserId, ATTR.OwnerName, ATTR.Claimed }) do
		table.insert(plate.conns, plot:GetAttributeChangedSignal(attr):Connect(function()
			paint(plot, plate)
		end))
	end
	for _, attr in ipairs({ "PlotCF", "Depth" }) do
		table.insert(plate.conns, plot:GetAttributeChangedSignal(attr):Connect(function()
			place(plot, plate)
			paint(plot, plate)
		end))
	end
	-- The numbers, and the capacity they are out of: an upgrade changes Y.
	for _, attr in ipairs({ ATTR.GardenGrown, ATTR.GardenPods, ATTR.GardenIncome,
		ATTR.GardenBoost, "Capacity", "Level" }) do
		table.insert(plate.conns, plot:GetAttributeChangedSignal(attr):Connect(function()
			paintStats(plot, plate)
		end))
	end
	anchor.Parent = Workspace.Terrain
	tagAnchor.Parent = Workspace.Terrain
	place(plot, plate)
	paint(plot, plate)
end

local function forget(instance: Instance)
	local plot = instance :: Model
	local plate = plates[plot]
	if not plate then
		return
	end
	plates[plot] = nil
	plate.token += 1
	for _, c in ipairs(plate.conns) do
		c:Disconnect()
	end
	plate.anchor:Destroy()
	plate.tagAnchor:Destroy()
	plate.plaque:Destroy()
end

local function repaintAll()
	for plot, plate in pairs(plates) do
		paint(plot, plate)
	end
end

--==============================================================================
-- THE SIZE CLAMP
--
-- A stud-sized billboard grows without limit as the camera closes in -- 408 px
-- of face at 8 studs, measured -- and BillboardGui's DistanceLowerLimit and
-- DistanceUpperLimit were MEASURED to change nothing about that. So it is done
-- here: between NearStuds and FarStuds the badge is its stud size and shrinks
-- like a sign; nearer, its studs shrink with the distance so it stops growing;
-- farther, they grow with it so it stops shrinking. The Unclaimed word gets the
-- same so it stays small at the gate.
--
-- After the camera has moved, over at most one badge and one tag per plot,
-- writing Size only when the factor moves -- a handful of subtractions a frame,
-- and no write at all while the camera sits in the middle band.
--==============================================================================
local function clampFactor(distance: number): number
	return distance / math.clamp(distance, BADGE.NearStuds, BADGE.FarStuds)
end

RunService:BindToRenderStep("SeedPlotBadgeClamp", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	for _, plate in pairs(plates) do
		if plate.board.Enabled then
			local f = clampFactor((plate.anchor.WorldPosition - eye).Magnitude)
			if math.abs(f - plate.badgeFactor) > 0.004 then
				plate.badgeFactor = f
				plate.board.Size = UDim2.new(BADGE.WidthStuds * f, 0, BADGE.TallStuds * f, 0)
			end
		end
		if plate.tag.Enabled then
			local f = clampFactor((plate.tagAnchor.WorldPosition - eye).Magnitude)
			if math.abs(f - plate.tagFactor) > 0.004 then
				plate.tagFactor = f
				plate.tag.Size = UDim2.new(FREE.WidthStuds * f, 0, FREE.TallStuds * f, 0)
			end
		end
	end
end)

for _, plot in ipairs(CollectionService:GetTagged(TAG)) do
	build(plot)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(build)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(forget)
-- A username arrives with its Player, which can land a beat after the plot's
-- OwnerUserId does; and a player leaving is a badge about to change.
Players.PlayerAdded:Connect(repaintAll)
Players.PlayerRemoving:Connect(function()
	task.defer(repaintAll)
end)
