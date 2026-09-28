--!strict
-- Steal a Seed :: WheelModel
--
-- THE REWARD WHEEL THAT STANDS BY MARIGOLD (2026-09-27). NOT a *Service -- a
-- builder with no lifecycle, called by WheelService.Start, like ObbyCourse.
--
-- A botanical installation from primitives: a round wooden garden platform with
-- flower beds round its back half and its front left open; the wheel itself
-- upright on a sturdy post, a gold pointer at the top and a gold hub cap; a
-- wooden trellis arch framing it with vines and leaves climbing both posts and a
-- restrained garland along the beam; and "SPIN THE WHEEL!" above the beam in
-- rainbow letters with a dark outline. About ninety parts.
--
-- THE FACE IS DRAWN BY EACH CLIENT. Two invisible panels, FaceFront and
-- FaceBack, carry the wheel's plane; WheelUI builds WheelDraw's face on them
-- locally, so the world wheel and the panel are one drawing, and only the
-- spinning player's own copy turns while they spin -- nobody's spin shows on
-- anybody else's wheel.
--
-- Its own Persistent folder outside SeedMap, which MapService rebuilds on every
-- boot (the Bonus Chest's pattern). Decoration never collides, is never hit by
-- a ray and never fires a touch (MapDecor's rule 1); the platform, the wheel,
-- its post and the arch's posts are solid.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WheelData = require(ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared"):WaitForChild("WheelData"))

local WheelModel = {}

local WOOD = Color3.fromRGB(150, 104, 64)
local WOOD_DARK = Color3.fromRGB(104, 70, 42)
local STONE = Color3.fromRGB(128, 124, 116)
local GOLD = Color3.fromRGB(242, 196, 84)
local LEAF = Color3.fromRGB(80, 164, 76)
local LEAF_DARK = Color3.fromRGB(52, 124, 60)
local SOIL = Color3.fromRGB(96, 70, 48)
local PETALS = {
	Color3.fromRGB(255, 250, 240), Color3.fromRGB(255, 176, 200), Color3.fromRGB(255, 220, 110),
	Color3.fromRGB(196, 170, 255),
}

-- The wheel's size and height, in the model's own frame (y up from the deck).
WheelModel.WheelDiameter = 11.5
WheelModel.WheelCentre = Vector3.new(0, 8.2, 0)

local function make(parent: Instance, shape: string, name: string, size: Vector3, cf: CFrame, colour: Color3,
	material: Enum.Material, solid: boolean): BasePart
	local p = Instance.new("Part")
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = false
	p.CastShadow = solid
	p.Parent = parent
	return p
end

-- A leaf: a flat blade, tilted about its own width.
local function leaf(parent: Instance, at: CFrame, length: number, tilt: number, colour: Color3?)
	make(parent, "block", "Leaf", Vector3.new(length * 0.46, 0.14, length), at * CFrame.Angles(math.rad(tilt), 0, 0),
		colour or LEAF, Enum.Material.SmoothPlastic, false)
end

-- A flower: a round bloom with a gold heart.
local function flower(parent: Instance, at: Vector3, size: number, colour: Color3)
	make(parent, "ball", "Bloom", Vector3.new(size, size * 0.7, size), CFrame.new(at), colour,
		Enum.Material.SmoothPlastic, false)
	make(parent, "ball", "Heart", Vector3.one * size * 0.42, CFrame.new(at + Vector3.new(0, size * 0.28, 0)),
		Color3.fromRGB(255, 200, 70), Enum.Material.SmoothPlastic, false)
end

--==============================================================================
-- BUILD: destroys any wheel already standing and builds it again (safe to re-run)
--==============================================================================
function WheelModel.build(): Model?
	local old = Workspace:FindFirstChild(WheelData.FolderName)
	if old then
		old:Destroy()
	end
	if not WheelData.Enabled then
		return nil
	end
	local place = WheelData.Place
	local origin = CFrame.new(place.Position) * CFrame.Angles(0, math.rad(place.FacingDegrees), 0)
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local folder = Instance.new("Folder")
	folder.Name = WheelData.FolderName
	folder.Archivable = false
	local model = Instance.new("Model")
	model.Name = "RewardWheel"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	--== THE GARDEN PLATFORM ==--
	local deck = make(model, "cylinder", "Platform", Vector3.new(0.8, 14, 14),
		at(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), WOOD, Enum.Material.WoodPlanks, true)
	make(model, "cylinder", "StoneRim", Vector3.new(0.5, 15.2, 15.2),
		at(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, true)
	-- Flower beds round the back half (from the arch's feet behind the wheel),
	-- leaving the front, where a player walks up to it, open.
	for i = 0, 7 do
		local a = math.rad(118 + i * (124 / 7))
		local r = 6.2
		local x, z = math.sin(a) * r, math.cos(a) * r
		make(model, "cylinder", "Bed", Vector3.new(0.35, 2.2, 2.2), at(x, 0.95, z) * CFrame.Angles(0, 0, math.rad(90)),
			SOIL, Enum.Material.Ground, false)
		make(model, "ball", "Bush", Vector3.new(2.1, 1.5, 2.1), at(x, 1.7, z), if i % 2 == 0 then LEAF else LEAF_DARK,
			Enum.Material.Grass, false)
		local bloom = origin * Vector3.new(x + math.sin(a + 1.3) * 0.5, 2.5, z + math.cos(a + 1.3) * 0.5)
		flower(model, bloom, 0.62, PETALS[(i % #PETALS) + 1])
	end

	--== THE WHEEL ON ITS POST ==--
	local centre = WheelModel.WheelCentre
	make(model, "block", "Post", Vector3.new(1.3, centre.Y - 0.2, 1.3), at(0, (centre.Y + 0.6) / 2, -1.2),
		WOOD_DARK, Enum.Material.WoodPlanks, true)
	for _, side in ipairs({ -1, 1 }) do
		make(model, "block", "Brace", Vector3.new(0.7, 4.6, 0.7),
			at(side * 1.6, 2.6, -1.2) * CFrame.Angles(0, 0, math.rad(side * 32)), WOOD_DARK, Enum.Material.WoodPlanks, true)
	end
	local d = WheelModel.WheelDiameter
	-- The wheel's body: its axis along the model's Z (a Cylinder's own X), wood
	-- round its edge; the face panels sit just proud of it on both sides.
	make(model, "cylinder", "WheelBody", Vector3.new(0.9, d, d),
		at(centre.X, centre.Y, 0) * CFrame.Angles(0, math.rad(90), 0), WOOD, Enum.Material.WoodPlanks, true)
	make(model, "cylinder", "GoldBand", Vector3.new(0.3, d + 0.35, d + 0.35),
		at(centre.X, centre.Y, 0) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, false)
	for _, side in ipairs({ 1, -1 }) do
		local face = make(model, "block", if side == 1 then "FaceFront" else "FaceBack", Vector3.new(d, d, 0.05),
			CFrame.lookAt(at(centre.X, centre.Y, side * 0.5).Position, at(centre.X, centre.Y, side * 5).Position),
			WOOD, Enum.Material.SmoothPlastic, false)
		face.Transparency = 1
		-- The hub cap, on both faces.
		make(model, "cylinder", "HubCap", Vector3.new(0.35, 1.9, 1.9),
			at(centre.X, centre.Y, side * 0.62) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, false)
	end
	-- The pointer: a gold diamond at 12 o'clock with its tip on the rim, and a
	-- round cap above it, on the front where the prize is read.
	local top = centre.Y + d / 2
	make(model, "block", "Pointer", Vector3.new(1.25, 1.25, 0.45),
		at(0, top + 0.35, 0.72) * CFrame.Angles(0, 0, math.rad(45)), GOLD, Enum.Material.Metal, false)
	make(model, "ball", "PointerCap", Vector3.one * 0.95, at(0, top + 1.15, 0.72), GOLD, Enum.Material.Metal, false)
	leaf(model, at(-0.75, top + 1.35, 0.6) * CFrame.Angles(0, 0, math.rad(40)), 1.1, 10)
	leaf(model, at(0.75, top + 1.35, 0.6) * CFrame.Angles(0, 0, math.rad(-40)), 1.1, 10)
	-- A small warm light, so the wheel reads at night.
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 226, 170)
	glow.Brightness = 0.6
	glow.Range = 14
	glow.Shadows = false
	glow.Parent = deck

	--== THE TRELLIS ARCH ==--
	local archTop = 20
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 7.6
		make(model, "block", "ArchPost", Vector3.new(1, archTop - 0.8, 1), at(x, 0.8 + (archTop - 0.8) / 2, -1.6),
			WOOD, Enum.Material.WoodPlanks, true)
		make(model, "block", "ArchFoot", Vector3.new(1.6, 0.7, 1.6), at(x, 1.15, -1.6), STONE, Enum.Material.Slate, true)
		-- Vines up the post: leaves in a slow spiral, a bloom every few.
		for i = 0, 9 do
			local y = 2.2 + i * 1.75
			local around = i * 1.9
			local off = Vector3.new(math.cos(around) * 0.7, 0, math.sin(around) * 0.7)
			leaf(model, at(x + off.X, y, -1.6 + off.Z) * CFrame.Angles(0, around, math.rad(side * 25)), 1.3,
				if i % 2 == 0 then 18 else -18, if i % 3 == 0 then LEAF_DARK else LEAF)
			if i % 3 == 1 then
				flower(model, at(x + off.X * 1.2, y + 0.4, -1.6 + off.Z * 1.2).Position, 0.5,
					PETALS[(i % #PETALS) + 1])
			end
		end
	end
	make(model, "block", "ArchBeam", Vector3.new(17.4, 1.1, 1.2), at(0, archTop + 0.1, -1.6), WOOD,
		Enum.Material.WoodPlanks, true)
	make(model, "block", "ArchCap", Vector3.new(18.2, 0.4, 1.6), at(0, archTop + 0.85, -1.6), WOOD_DARK,
		Enum.Material.WoodPlanks, true)
	-- The garland along the beam: leaves hanging from it, blooms between.
	for i = -4, 4 do
		leaf(model, at(i * 1.8, archTop - 0.6, -1.0) * CFrame.Angles(0, 0, math.rad(90 + (i % 2) * 18)), 1.2, 0,
			if i % 2 == 0 then LEAF else LEAF_DARK)
		if i % 2 ~= 0 then
			flower(model, at(i * 1.8, archTop - 0.4, -0.75).Position, 0.55, PETALS[((i + 4) % #PETALS) + 1])
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		make(model, "block", "ArchBrace", Vector3.new(0.6, 3.4, 0.6),
			at(side * 6.4, archTop - 1.3, -1.6) * CFrame.Angles(0, 0, math.rad(side * -45)), WOOD_DARK,
			Enum.Material.WoodPlanks, true)
	end

	--== THE SIGN: "SPIN THE WHEEL!" ==--
	local signAnchor = make(model, "block", "SignAnchor", Vector3.one * 0.2, at(0, archTop + 3.4, -1.6), WOOD,
		Enum.Material.SmoothPlastic, false)
	signAnchor.Transparency = 1
	local board = Instance.new("BillboardGui")
	board.Name = "SpinSign"
	-- In studs: a fixed size in the world, so it shrinks with distance like the
	-- arch it stands on, and is gone past SignDistance.
	board.Size = UDim2.fromScale(15, 2.8)
	board.MaxDistance = place.SignDistance
	board.LightInfluence = 0
	board.AlwaysOnTop = false
	board.ResetOnSpawn = false
	board.Parent = signAnchor
	local words = Instance.new("TextLabel")
	words.Name = "Words"
	words.Size = UDim2.fromScale(1, 1)
	words.BackgroundTransparency = 1
	words.Font = Enum.Font.LuckiestGuy
	words.TextScaled = true
	words.Text = "SPIN THE WHEEL!"
	words.TextColor3 = Color3.fromRGB(255, 255, 255)
	words.Parent = board
	local rainbow = Instance.new("UIGradient")
	rainbow.Name = "Rainbow"
	rainbow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 92, 92)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 176, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 232, 80)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(110, 220, 110)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(90, 176, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 255)),
	})
	rainbow.Parent = words
	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(34, 24, 16)
	outline.Thickness = 2.5
	outline.Parent = words

	--== THE PROMPT, at the front of the platform ==--
	local promptAnchor = make(model, "block", "PromptAnchor", Vector3.one * 0.4, at(0, 2.8, 6.3), WOOD,
		Enum.Material.SmoothPlastic, false)
	promptAnchor.Transparency = 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WheelPrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Spin"
	prompt.ObjectText = "Reward Wheel"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- Opening a panel gives nothing, so no hold.
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = place.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptAnchor

	model.PrimaryPart = deck
	model:SetAttribute("RewardWheel", true)
	model.Parent = folder
	folder.Parent = Workspace
	return model
end

return WheelModel
