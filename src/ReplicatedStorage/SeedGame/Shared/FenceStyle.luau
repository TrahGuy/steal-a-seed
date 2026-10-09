--!strict
--==============================================================================
-- Steal a Seed :: FenceStyle (2026-10-08)
--
-- How a plot owner's rebirths dress their fence (GameConfig.Rebirth.Fence),
-- in one place for both of its users: RebirthService dresses the real fence
-- on the server, and RebirthUI's NEXT UNLOCKS shows the next tier on a short
-- sample of fence, built here from the real fence's own measurements -- so the
-- picture is exactly what the plot will wear.
--
-- Only the boards' and posts' colour and material change; the caps are new
-- parts nothing can touch, stand on or hit. Never a size, a place or a
-- collision (MapService, THE GAP IS SHUT TO THE BODY).
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))

local F = GameConfig.Rebirth.Fence

local FenceStyle = {}

-- The real fence's measurements (MapService: BOARDS, FENCE_THICK, FENCE_TOP;
-- a post is FENCE_TOP + 0.8 tall). RebirthSpec pins them against MapService.
FenceStyle.Boards = { { 1.1, 2.2 }, { 3.9, 2.2 } }
FenceStyle.Thick = 1.6
FenceStyle.Top = 5.0
FenceStyle.Wood = Color3.fromRGB(96, 66, 44)

local function cap(folder: Instance, name: string, size: Vector3, cframe: CFrame, colour: Color3,
	material: Enum.Material, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

-- Paints the boards and posts for `rebirths` and puts the tier's caps on the
-- posts, into `folder`. Answers the tier, and whether it has caps at all.
function FenceStyle.dress(rails: { BasePart }, posts: { BasePart }, folder: Instance, rebirths: number): (number, boolean)
	local fence = Rebirth.fence(rebirths)
	local style = fence.style
	for _, part in ipairs(rails) do
		part.Color = style.Colour
		part.Material = style.Material
	end
	for _, part in ipairs(posts) do
		part.Color = style.Colour
		part.Material = style.Material
	end
	if not style.Cap then
		return fence.tier, false
	end
	local capColour: Color3 = fence.trim or style.CapColour
	for _, post in ipairs(posts) do
		local top = post.CFrame * CFrame.new(0, post.Size.Y * 0.5, 0)
		if style.Cap == "point" then
			-- A picket's point: a block on its edge along the run.
			cap(folder, "Cap", Vector3.new(1.15, 1.15, post.Size.Z + 0.1), top * CFrame.new(0, 0.1, 0)
				* CFrame.Angles(0, 0, math.rad(45)), capColour, style.CapMaterial)
		elseif style.Cap == "moss" then
			cap(folder, "Cap", Vector3.new(post.Size.X + 0.5, 0.45, post.Size.Z + 0.5),
				top * CFrame.new(0, 0.22, 0), capColour, style.CapMaterial)
		elseif style.Cap == "tip" then
			cap(folder, "Cap", Vector3.new(1, 1, 1), top * CFrame.new(0, 0.45, 0), capColour, style.CapMaterial,
				Enum.PartType.Ball)
		elseif style.Cap == "planter" then
			cap(folder, "Cap", Vector3.new(post.Size.X + 0.3, 0.7, post.Size.Z + 0.3), top * CFrame.new(0, 0.35, 0),
				capColour, style.CapMaterial)
			cap(folder, "Flower", Vector3.new(1.2, 1.2, 1.2), top * CFrame.new(0, 1.15, 0), style.FlowerColour,
				Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		elseif style.Cap == "glow" then
			cap(folder, "Cap", Vector3.new(1.2, 1.2, 1.2), top * CFrame.new(0, 0.55, 0), capColour, style.CapMaterial,
				Enum.PartType.Ball)
		elseif style.Cap == "gem" then
			-- A cube stood on its corner.
			cap(folder, "Cap", Vector3.new(1, 1, 1), top * CFrame.new(0, 0.85, 0)
				* CFrame.Angles(math.rad(45), 0, math.rad(35.26)), capColour, style.CapMaterial)
		end
	end
	return fence.tier, true
end

-- A short run of the real fence -- two boards, the gap between them and three
-- posts, at the real fence's measurements -- dressed for `rebirths`. Built
-- detached (no parent): the caller places it. Its middle post is the
-- PrimaryPart; nothing in it can be touched, stood on or hit.
function FenceStyle.segment(rebirths: number, length: number): Model
	local model = Instance.new("Model")
	model.Name = "FenceSample"
	local rails: { BasePart } = {}
	local posts: { BasePart } = {}
	local function piece(name: string, size: Vector3, at: Vector3, transparency: number?): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = CFrame.new(at)
		part.Color = FenceStyle.Wood
		part.Material = Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = transparency or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end
	for _, board in ipairs(FenceStyle.Boards) do
		table.insert(rails, piece("Rail", Vector3.new(length, board[2], FenceStyle.Thick), Vector3.new(0, board[1], 0)))
	end
	local postTall = FenceStyle.Top + 0.8
	for i = -1, 1 do
		table.insert(posts, piece("Post", Vector3.new(1.6, postTall, 1.6), Vector3.new(i * length * 0.5, postTall * 0.5, 0)))
	end
	local decor = Instance.new("Folder")
	decor.Name = F.FolderName
	decor.Parent = model
	FenceStyle.dress(rails, posts, decor, rebirths)
	model.PrimaryPart = posts[2]
	return model
end

return FenceStyle
