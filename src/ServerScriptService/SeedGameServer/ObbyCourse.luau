--!strict
--==============================================================================
-- Steal a Seed :: ObbyCourse
--
-- Builds the Floating Garden from ObbyData. NOT a *Service on purpose (the
-- MapDecor rule): ServerMain starts every "*Service" beside it, and this has no
-- lifecycle of its own -- ObbyService calls Build once, at its Start. Nothing
-- is placed by hand: every island, platform, sign and flower is here,
-- deterministic, and rebuilt whole on a rerun.
--
--==============================================================================
-- WHAT THE CLIENTS AND THE SERVER FIND IN IT
--
--   Workspace.SeedObby                    Archivable = false, like SeedMap
--     tagged ObbyMover     a drifting pad: attributes ObbyRest (CFrame),
--                          ObbyAxis, ObbyAmp, ObbyPeriod, ObbyPhase
--     tagged ObbySpinner   a turning log: ObbyRest, ObbyDegPerSecond, ObbyPhase
--     tagged ObbyCrumble   a falling leaf (each client crumbles its own copy):
--                          ObbyRest, ObbyShake (its warning, in seconds)
--     tagged ObbyLaunch    a spring cap: ObbyStage + ObbyIndex name its spec
--     Entrance.StartStep.StartPrompt
--     Entrance.RewardSign.Board           the preview (each client writes its own)
--     Finish.ReplayPlinth.ReplayPrompt / Finish.ReturnPlinth.ReturnPrompt
--     Finish.ResultSign.Board             the last result (each client its own)
--
-- THE SERVER NEVER MOVES A PLATFORM. Every client moves its own copy from
-- workspace:GetServerTimeNow(), so all of them agree without a single
-- replicated CFrame (ObbyUI). A moving piece is therefore ONE assembly -- an
-- anchored walk surface with its trim welded on -- in an ATOMIC model: moved
-- by one CFrame write, and streamed in whole, never half a leaf at its rest
-- pose beside half at the client's (the PlantSway lesson).
--
--==============================================================================
-- WHAT YOU STAND ON NEVER LOOKS LIKE WHAT YOU DO NOT
--
-- Walk surfaces are broad, flat, studded on every face and in the stage's pad
-- colour. Every decoration is smooth, off the line, and CanCollide, CanQuery
-- and CanTouch false (MapDecor's rule 1) -- nothing to catch a foot, a camera
-- or a ray. The spring caps are the one teal thing on the course.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local ObbyDecor = require(script.Parent:WaitForChild("ObbyDecor"))

local ObbyCourse = {}

ObbyCourse.FolderName = ObbyData.FolderName
ObbyCourse.Tags = ObbyData.Tags

local WHITE = Color3.fromRGB(250, 248, 240)
local WOOD = Color3.fromRGB(150, 102, 64)
local WOOD_DARK = Color3.fromRGB(104, 70, 46)
local VINE = Color3.fromRGB(70, 140, 70)
local VINE_DARK = Color3.fromRGB(52, 108, 60)
local GOLD = Color3.fromRGB(255, 214, 92)
-- The spring caps' colour, and nothing else on the course is this colour.
local SPRING = Color3.fromRGB(72, 206, 214)

local STUDS = Enum.SurfaceType.Studs
local SMOOTH = Enum.SurfaceType.Smooth

--==============================================================================
-- THE PART HELPER: solid and studded unless told it is trim
--==============================================================================
type PartOpts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	material: Enum.Material?,
	-- false: trim -- no collision, no query, no touch, smooth, no shadow.
	solid: boolean?,
}

local function part(o: PartOpts): Part
	local p = Instance.new("Part")
	p.Name = o.name
	if o.shape then
		p.Shape = o.shape
	end
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Material = o.material or Enum.Material.Plastic
	p.Anchored = true
	local solid = o.solid ~= false
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = solid
	p.CastShadow = solid
	local face = if solid then STUDS else SMOOTH
	p.TopSurface = face
	p.BottomSurface = face
	p.FrontSurface = face
	p.BackSurface = face
	p.LeftSurface = face
	p.RightSurface = face
	p.Parent = o.parent
	return p
end

local function trim(name: string, parent: Instance, size: Vector3, cf: CFrame, color: Color3,
	shape: Enum.PartType?): Part
	return part({ name = name, size = size, cframe = cf, color = color, parent = parent, shape = shape,
		solid = false })
end

-- A vertical cylinder whose TOP is at `top`. A Cylinder's axis runs along X, so
-- a quarter turn about Z stands it up.
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local function disc(name: string, parent: Instance, top: Vector3, diameter: number, height: number,
	color: Color3, solid: boolean): Part
	return part({
		name = name,
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, diameter, diameter),
		cframe = CFrame.new(top - Vector3.new(0, height / 2, 0)) * UPRIGHT,
		color = color,
		parent = parent,
		solid = solid,
	})
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function model(name: string, parent: Instance, atomic: boolean?): Model
	local m = Instance.new("Model")
	m.Name = name
	if atomic then
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
	m.Parent = parent
	return m
end

-- Trim that has to travel with a moving piece: unanchored, massless and
-- welded, so one CFrame write on the anchored root carries all of it.
local function carry(root: BasePart, p: BasePart)
	p.Anchored = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
end

local function palette(id: string): ObbyData.Palette
	return ObbyData.Palettes[id] or ObbyData.Palettes.sunpetal
end

-- A small deterministic wobble: the same island always gets the same rocks.
local function wobble(seed: number, i: number): number
	local x = math.sin(seed * 12.9898 + i * 78.233) * 43758.5453
	return x - math.floor(x)
end

--==============================================================================
-- A FLOATING ISLAND: the turf you stand on, and the clod it grows from
--
-- The turf is a disc with five lobes round its rim, every one of them solid
-- and flush with the top -- the outline is a lawn's, not a coin's, and all of
-- it is ground you can stand on (nothing that looks walkable here is not). The
-- lobes reach at most a stud or two past the radius, so no gap on the course
-- gets wider, and none of them reaches a moving piece's sweep. Everything
-- under the turf is ObbyDecor's: soil lip, rock, roots.
--==============================================================================
local function island(parent: Instance, pal: ObbyData.Palette, spec: any, seed: number): Model
	local top = ObbyData.world(spec.at)
	local r = spec.radius
	local m = model("Island", parent)
	disc("Grass", m, top, r * 2, 2, pal.grass, true)
	local lobes = 5
	for i = 1, lobes do
		local a = (i - 1) / lobes * math.pi * 2 + wobble(seed, i) * 0.9
		local w = r * (0.42 + wobble(seed, i + 10) * 0.18)
		local d = r * 0.3
		local centre = top + Vector3.new(math.cos(a) * (r - d * 0.3), -1, math.sin(a) * (r - d * 0.3))
		part({
			name = "Turf",
			size = Vector3.new(w, 2, d),
			cframe = CFrame.new(centre) * CFrame.Angles(0, -a + math.pi / 2, 0),
			color = pal.grass:Lerp(if i % 2 == 0 then Color3.new(1, 1, 1) else Color3.new(0, 0, 0), 0.05),
			parent = m,
		})
	end
	ObbyDecor.islandBody(m, spec, pal, Random.new(seed * 7919))
	return m
end

--==============================================================================
-- WHAT YOU STAND ON
--==============================================================================
-- A leaf: a broad flat blade with a lighter midrib and a stem curling off the
-- back edge. `moving` welds the trim on so the whole leaf travels as one.
local function leaf(parent: Instance, spec: any, name: string, color: Color3, moving: boolean): Part
	local top = ObbyData.world(spec.at)
	local t = ObbyData.PadThickness
	local cf = CFrame.new(top - Vector3.new(0, t / 2, 0)) * CFrame.Angles(0, math.rad(spec.yaw or 0), 0)
	local holder = if moving then model(name, parent, true) else parent
	local blade = part({ name = name, size = Vector3.new(spec.size.X, t, spec.size.Y), cframe = cf,
		color = color, parent = holder })
	-- Flush with the top, so it can never trip anybody.
	local rib = trim("Midrib", holder, Vector3.new(spec.size.X * 0.9, 0.2, 0.5),
		cf * CFrame.new(0, t / 2 + 0.05, 0), color:Lerp(WHITE, 0.35))
	local stem = trim("Stem", holder, Vector3.new(0.6, 3, 0.6),
		cf * CFrame.new(-spec.size.X / 2 - 0.2, -1.4, 0) * CFrame.Angles(0, 0, math.rad(-30)), VINE_DARK)
	if moving then
		carry(blade, rib)
		carry(blade, stem)
		local whole = holder :: Model
		whole.PrimaryPart = blade
	end
	return blade
end

-- A root walkway: a broad flat root in bark, rounded along both long edges by
-- a half-sunk barrel of trim (flush with the top, so nothing to trip on), with
-- a rootlet hanging off each end. Static.
local function rootWalk(parent: Instance, pal: ObbyData.Palette, spec: any): Part
	local top = ObbyData.world(spec.at)
	local t = ObbyData.PadThickness
	local cf = CFrame.new(top - Vector3.new(0, t / 2, 0)) * CFrame.Angles(0, math.rad(spec.yaw or 0), 0)
	local walk = part({ name = "Root", size = Vector3.new(spec.size.X, t, spec.size.Y), cframe = cf,
		color = pal.pad, parent = parent })
	for _, side in ipairs({ -1, 1 }) do
		trim("Bark", walk, Vector3.new(spec.size.X + 0.6, 1.6, 1.6),
			cf * CFrame.new(0, t / 2 - 0.8, side * (spec.size.Y / 2 - 0.35)) * UPRIGHT * CFrame.Angles(0, 0, math.rad(90)),
			pal.accent, Enum.PartType.Cylinder)
	end
	for _, side in ipairs({ -1, 1 }) do
		local from = (cf * CFrame.new(side * spec.size.X / 2, -t / 2, 0)).Position
		local tip = from + Vector3.new(side * 1.2, -3.2, 0.6)
		trim("Rootlet", walk, Vector3.new(0.6, 0.6, (tip - from).Magnitude), CFrame.lookAt((from + tip) / 2, tip),
			pal.soil)
	end
	return walk
end

-- A lily pad: a disc with a notch and a lighter rim, always moving.
local function lilyPad(parent: Instance, pal: ObbyData.Palette, spec: any): Part
	local top = ObbyData.world(spec.at)
	local d = math.max(spec.size.X, spec.size.Y)
	local holder = model("LilyPad", parent, true)
	local pad = disc("Pad", holder, top, d, ObbyData.PadThickness, pal.pad, true)
	local rim = trim("Rim", holder, Vector3.new(0.25, d + 0.5, d + 0.5),
		CFrame.new(top - Vector3.new(0, ObbyData.PadThickness * 0.7, 0)) * UPRIGHT,
		pal.pad:Lerp(WHITE, 0.3), Enum.PartType.Cylinder)
	local notch = trim("Notch", holder, Vector3.new(0.3, 1.8, d * 0.35),
		CFrame.new(top + Vector3.new(0, -0.3, d * 0.33)), pal.pad:Lerp(Color3.new(0, 0, 0), 0.25))
	carry(pad, rim)
	carry(pad, notch)
	holder.PrimaryPart = pad
	return pad
end

-- A log turning about its centre: a flat-topped deck in bark, a round cap in
-- the heartwood colour at each end.
local function logSpinner(parent: Instance, pal: ObbyData.Palette, spec: any): Part
	local top = ObbyData.world(spec.at)
	local holder = model("Log", parent, true)
	local deck = part({ name = "Deck", size = Vector3.new(spec.length, 2.4, spec.width),
		cframe = CFrame.new(top - Vector3.new(0, 1.2, 0)), color = pal.pad, parent = holder })
	for _, side in ipairs({ -1, 1 }) do
		local cap = trim("Cap", holder, Vector3.new(0.6, spec.width + 0.6, spec.width + 0.6),
			CFrame.new(top + Vector3.new(side * (spec.length / 2 + 0.2), -1.2, 0)),
			pal.accent:Lerp(WHITE, 0.25), Enum.PartType.Cylinder)
		carry(deck, cap)
	end
	holder.PrimaryPart = deck
	return deck
end

-- A spring mushroom: a squat stem and a flat teal cap with white spots, the
-- cap the trigger -- and a white ring round its rim, the same on every one.
local function springMushroom(parent: Instance, spec: any, stageId: string, index: number): Part
	local base = ObbyData.world(spec.at)
	local rise = ObbyData.LaunchCapRise
	local m = model("SpringMushroom", parent)
	trim("Stem", m, Vector3.new(0.8, spec.radius * 1.1, spec.radius * 1.1),
		CFrame.new(base + Vector3.new(0, rise - 0.6, 0)) * UPRIGHT, WHITE:Lerp(SPRING, 0.2),
		Enum.PartType.Cylinder)
	local cap = disc("Cap", m, base + Vector3.new(0, rise, 0), spec.radius * 2, 0.6, SPRING, true)
	trim("Ring", m, Vector3.new(0.3, spec.radius * 2 + 0.4, spec.radius * 2 + 0.4),
		CFrame.new(base + Vector3.new(0, rise - 0.45, 0)) * UPRIGHT, WHITE, Enum.PartType.Cylinder)
	for i = 1, 4 do
		local a = i * math.pi / 2 + 0.4
		trim("Spot", m, Vector3.new(0.12, spec.radius * 0.45, spec.radius * 0.45),
			CFrame.new(base + Vector3.new(math.cos(a) * spec.radius * 0.55, rise + 0.02,
				math.sin(a) * spec.radius * 0.55)) * UPRIGHT, WHITE, Enum.PartType.Cylinder)
	end
	cap:SetAttribute("ObbyStage", stageId)
	cap:SetAttribute("ObbyIndex", index)
	CollectionService:AddTag(cap, ObbyCourse.Tags.Launch)
	m.PrimaryPart = cap
	return cap
end

--==============================================================================
-- A CHECKPOINT: a flower totem beside the landing that says so
--==============================================================================
local function label(board: BasePart, lines: { string }, headline: Color3?)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Face"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = board
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui
		local share = if #lines == 1 then 0.9 else 0.84 / #lines
		for i, line in ipairs(lines) do
			local text = Instance.new("TextLabel")
			text.Name = "Line" .. i
			text.LayoutOrder = i
			text.Size = UDim2.new(0.92, 0, if i == 1 and #lines > 1 then share * 1.4 else share, 0)
			text.BackgroundTransparency = 1
			text.Font = if i == 1 then Enum.Font.LuckiestGuy else Enum.Font.GothamBold
			text.TextScaled = true
			text.TextColor3 = if i == 1 then (headline or Color3.fromRGB(255, 236, 170))
				else Color3.fromRGB(250, 244, 226)
			text.Text = line
			text.Parent = gui
			local edge = Instance.new("UIStroke")
			edge.Color = Color3.fromRGB(40, 26, 16)
			edge.Thickness = 1.5
			edge.Parent = text
		end
	end
end

local function checkpoint(parent: Instance, pal: ObbyData.Palette, at: Vector3, id: string)
	local base = ObbyData.world(at) + Vector3.new(0, 0, 6)
	local m = model("Checkpoint_" .. id, parent)
	part({ name = "Post", size = Vector3.new(1, 6, 1), cframe = CFrame.new(base + Vector3.new(0, 3, 0)),
		color = WOOD, parent = m, solid = false })
	disc("Bloom", m, base + Vector3.new(0, 7.4, 0), 3.4, 0.8, pal.flower, false)
	trim("Heart", m, Vector3.new(1.4, 1.4, 1.4), CFrame.new(base + Vector3.new(0, 7.3, 0)), GOLD,
		Enum.PartType.Ball)
	local board = trim("Board", m, Vector3.new(5.5, 1.4, 0.3),
		CFrame.new(base + Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, math.rad(90), 0), WOOD_DARK)
	label(board, { "CHECKPOINT" })
end

--==============================================================================
-- A SIGN: a small wooden board on two posts
--==============================================================================
local function sign(parent: Instance, name: string, at: Vector3, facing: number, width: number,
	lines: { string }, headline: Color3?): Part
	local m = model(name, parent)
	local cf = CFrame.new(at) * CFrame.Angles(0, math.rad(facing), 0)
	for _, side in ipairs({ -1, 1 }) do
		trim("Post", m, Vector3.new(0.7, 5.4, 0.7), cf * CFrame.new(side * (width / 2 - 0.6), 2.7, 0), WOOD_DARK)
	end
	local board = trim("Board", m, Vector3.new(width, 2.6, 0.4), cf * CFrame.new(0, 4.3, 0), WOOD)
	label(board, lines, headline)
	return board
end

--==============================================================================
-- A FLOWER: a stem, five petals round a heart. Trim, never collidable.
--==============================================================================
local function flower(parent: Instance, at: Vector3, height: number, petal: Color3, seed: number)
	trim("Stem", parent, Vector3.new(0.4, height, 0.4), CFrame.new(at + Vector3.new(0, height / 2, 0))
		* CFrame.Angles(math.rad((wobble(seed, 1) - 0.5) * 16), 0, math.rad((wobble(seed, 2) - 0.5) * 16)), VINE)
	local head = at + Vector3.new(0, height, 0)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + wobble(seed, 3)
		trim("Petal", parent, Vector3.new(1.3, 0.35, 0.8),
			CFrame.new(head + Vector3.new(math.cos(a) * 0.7, 0, math.sin(a) * 0.7)) * CFrame.Angles(0, -a, math.rad(-18)),
			petal)
	end
	trim("Heart", parent, Vector3.new(0.8, 0.8, 0.8), CFrame.new(head + Vector3.new(0, 0.15, 0)), GOLD,
		Enum.PartType.Ball)
end

--==============================================================================
-- THE ENTRANCE: a vine arch, flowers, the sign, the reward board, the prompt,
-- and a trail of petals rising toward the first island
--==============================================================================
local PETALS = { Color3.fromRGB(255, 196, 214), Color3.fromRGB(255, 236, 140), Color3.fromRGB(190, 160, 240) }

local function entrance(root: Instance)
	local E = ObbyData.Entrance
	local m = model("Entrance", root)
	-- Faces +X (FacingDegrees -90): local +X is world +Z, local -Z is world +X.
	local base = CFrame.new(E.At) * CFrame.Angles(0, math.rad(E.FacingDegrees), 0)
	for _, side in ipairs({ -1, 1 }) do
		part({ name = "Pillar", size = Vector3.new(1.8, 11, 1.8), cframe = base * CFrame.new(side * 6, 5.5, 0),
			color = VINE_DARK, parent = m })
	end
	for i = -2, 2 do
		local a = i / 2 * math.rad(62)
		trim("ArchVine", m, Vector3.new(3.6, 1.6, 1.8),
			base * CFrame.new(math.sin(a) * 6.4, 11 + math.cos(a) * 2.2, 0) * CFrame.Angles(0, 0, -a),
			if i % 2 == 0 then VINE else VINE_DARK)
	end
	-- Flowers climbing the pillars, and a bed at their feet (ObbyDecor's).
	for i = 1, 4 do
		local side = if i % 2 == 0 then 1 else -1
		flower(m, (base * CFrame.new(side * 7.4, 2 + (i - 1) * 2.1, 0.6)).Position, 0.6, PETALS[(i % 3) + 1], i)
	end
	ObbyDecor.entrance(m, base)
	sign(m, "Sign", (base * CFrame.new(-11, 0, -2)).Position, E.FacingDegrees + 180 + 20, 8.5,
		{ "SPEED CHALLENGE", "The Floating Garden" })
	sign(m, "RewardSign", (base * CFrame.new(11, 0, -2)).Position, E.FacingDegrees + 180 - 20, 8.5,
		{ "YOUR REWARD", "", "" }, Color3.fromRGB(150, 226, 255))
	-- The prompt, on a stone step under the arch. Custom, so PromptUI draws it
	-- in the same chrome as every other prompt in the game.
	local step = part({ name = "StartStep", size = Vector3.new(8, 0.6, 5), cframe = base * CFrame.new(0, 0.3, 0),
		color = Color3.fromRGB(180, 170, 150), parent = m })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StartPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Start"
	prompt.ObjectText = "Speed Challenge"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = E.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = step
	-- The link to the islands: petals rising from the arch toward the start
	-- island, spaced wide and non-collidable -- a trail for the eye, not a path.
	local from = (base * CFrame.new(0, 9, -3)).Position
	local to = ObbyData.world(ObbyData.Start.at) + Vector3.new(-14, -1, 0)
	for i = 1, 7 do
		local t = i / 8
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 8, (wobble(3, i) - 0.5) * 6)
		trim("TrailPetal", m, Vector3.new(1.6, 0.3, 1.1), CFrame.new(p) * CFrame.Angles(math.rad(20), i * 0.7,
			math.rad(15)), PETALS[(i % 3) + 1])
	end
end

--==============================================================================
-- THE FINISH: a flower-roofed pavilion, the result board, Replay and Return
--==============================================================================
local function finish(root: Instance)
	local F = ObbyData.Finish
	local pal = palette("summit")
	local m = model("Finish", root)
	local center = ObbyData.world(F.at)
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local p = center + Vector3.new(math.cos(a) * 6, 0, math.sin(a) * 6)
		part({ name = "Pillar", size = Vector3.new(1, 10, 1), cframe = CFrame.new(p + Vector3.new(0, 5, 0)),
			color = WHITE, parent = m })
		trim("Vine", m, Vector3.new(1.3, 8, 0.4), CFrame.new(p + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, a,
			math.rad(8)), VINE)
	end
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		trim("RoofPetal", m, Vector3.new(7, 0.6, 4.2), CFrame.new(center + Vector3.new(math.cos(a) * 3.2, 10.6,
			math.sin(a) * 3.2)) * CFrame.Angles(0, -a, math.rad(-22)),
			if i % 2 == 0 then pal.flower else pal.accent:Lerp(WHITE, 0.3))
	end
	trim("RoofHeart", m, Vector3.new(3, 3, 3), CFrame.new(center + Vector3.new(0, 11.6, 0)), GOLD, Enum.PartType.Ball)
	disc("FinishMark", m, center + Vector3.new(0, 0.12, 0), 9, 0.2, pal.accent:Lerp(WHITE, 0.45), false)
	ObbyDecor.pavilion(m, center)
	sign(m, "ResultSign", center + Vector3.new(9, 0, 0), 90, 8.5, { "FLOATING GARDEN", "Reach the pavilion", "" },
		Color3.fromRGB(255, 196, 214))
	for _, choice in ipairs({ { "Replay", F.replayAt, "Run it again" }, { "Return", F.returnAt, "Back to your plot" } }) do
		local plinth = part({ name = choice[1] .. "Plinth", size = Vector3.new(3, 1, 3),
			cframe = CFrame.new(ObbyData.world(choice[2]) + Vector3.new(0, 0.5, 0)), color = pal.rock, parent = m })
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = choice[1] .. "Prompt"
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.ActionText = choice[1]
		prompt.ObjectText = choice[3]
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = plinth
	end
end

--==============================================================================
-- BUILD, WHOLE, EVERY TIME
--==============================================================================
function ObbyCourse.Remove()
	local old = Workspace:FindFirstChild(ObbyCourse.FolderName)
	if old then
		old:Destroy()
	end
end

function ObbyCourse.Build(): Folder
	ObbyCourse.Remove()
	local root = Instance.new("Folder")
	root.Name = ObbyCourse.FolderName
	root.Archivable = false

	for index, stage in ipairs(ObbyData.Stages) do
		local pal = palette(stage.palette)
		local sf = folder("Stage_" .. stage.id, root)
		sf:SetAttribute("StageName", stage.name)
		for i, spec in ipairs(stage.islands) do
			island(sf, pal, spec, index * 10 + i)
		end
		for _, spec in ipairs(stage.pads or {}) do
			if stage.id == "rootgrove" then
				rootWalk(sf, pal, spec)
			else
				leaf(sf, spec, "Leaf", pal.pad, false)
			end
		end
		for _, spec in ipairs(stage.movers or {}) do
			local pad = if stage.id == "challengeA" then leaf(sf, spec, "SwayLeaf", pal.pad, true)
				else lilyPad(sf, pal, spec)
			pad:SetAttribute("ObbyRest", pad.CFrame)
			pad:SetAttribute("ObbyAxis", spec.axis)
			pad:SetAttribute("ObbyAmp", spec.amplitude)
			pad:SetAttribute("ObbyPeriod", spec.period)
			pad:SetAttribute("ObbyPhase", spec.phase)
			CollectionService:AddTag(pad, ObbyCourse.Tags.Mover)
		end
		for _, spec in ipairs(stage.spinners or {}) do
			local log = logSpinner(sf, pal, spec)
			log:SetAttribute("ObbyRest", log.CFrame)
			log:SetAttribute("ObbyDegPerSecond", spec.degPerSecond)
			log:SetAttribute("ObbyPhase", spec.phase)
			CollectionService:AddTag(log, ObbyCourse.Tags.Spinner)
		end
		for _, spec in ipairs(stage.crumbles or {}) do
			local blade = leaf(sf, spec, "FallingLeaf", pal.pad, true)
			blade:SetAttribute("ObbyRest", blade.CFrame)
			blade:SetAttribute("ObbyShake", stage.crumbleShake or ObbyData.Crumble.ShakeSeconds)
			CollectionService:AddTag(blade, ObbyCourse.Tags.Crumble)
		end
		for i, spec in ipairs(stage.launches or {}) do
			springMushroom(sf, spec, stage.id, i)
		end
		if stage.checkpoint then
			checkpoint(sf, pal, ObbyData.Respawns[stage.checkpoint.id].at, stage.checkpoint.id)
		end
		ObbyDecor.dress(stage.id, sf)
	end

	-- The challenge route's sign, at the branch on the second checkpoint island.
	sign(root, "ChallengeSign", ObbyData.world(ObbyData.ChallengeSign.at), 0, 10,
		{ "CHALLENGE ROUTE", "EXTRA SPEED", "Fall and you're back here" }, Color3.fromRGB(150, 226, 255))

	entrance(root)
	finish(root)
	root.Parent = Workspace
	return root
end

return ObbyCourse
