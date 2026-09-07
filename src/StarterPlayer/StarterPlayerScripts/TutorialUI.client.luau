--!strict
--==============================================================================
-- MARIGOLD'S FIRST GARDEN -- shown, not read.
--
-- Version 1 was an objective card: a title, a paragraph, a bearing and a
-- distance. It was accurate and nobody looked at it, because a paragraph is a
-- thing you stop to read and this is a game you play while running.
--
-- So the card is gone. What replaced it is a trail of arrows on the ground, a
-- highlight on the thing to touch, and four words over it. The player should
-- know the next action from the SHAPE of the screen, and the words should only
-- confirm what the arrows already said.
--
--==============================================================================
-- EVERYTHING HERE IS LOCAL AND ADVISORY
--
-- The server is the only thing that decides a step is done. This file draws
-- where to go; it never claims arrival, never grants anything, and never sends
-- a milestone. The only three things it may say are snapshot / skip / resume.
--
-- Every world object it makes is created on the CLIENT, so it exists on this
-- screen and nobody else's -- that is what makes "visible only to the relevant
-- player" a property of where the code runs rather than a filter to maintain.
-- All of it is anchored, non-colliding, non-query, non-touch and non-archivable.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Data = require(Shared:WaitForChild("TutorialData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = SeedGame:WaitForChild("Remotes")
local channel = remotes:WaitForChild(Config.Remotes.GameEvent) :: RemoteEvent

local ATTR = Config.Attributes
local PLOT = Config.Plot

--== the HUD's own palette, so the guide is the same voice ====================
local GOLD = Color3.fromRGB(255, 211, 105)
local CREAM = Color3.fromRGB(255, 246, 220)
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

--== bounded costs, all of them ===============================================
--==============================================================================
-- THE TRAIL IS A CHAIN OF FLOWING ARROW BEAMS
--
-- One Beam per leg of the route, each carrying the standard flowing-arrow
-- texture. The texture scrolls ITSELF from TextureSpeed, so the animation costs
-- no Lua at all -- there is no per-frame trail work in this file any more.
--
-- CHAINED RATHER THAN ONE LONG BEAM, because a single beam from the player to
-- the objective is a straight line and would run through fences, the mill and
-- the plot wall. The legs are the pathfinding waypoints, so the arrows bend
-- around the things a straight beam would cut through.
--==============================================================================
local TRAIL_NODES = 24       -- the whole pool; spacing stretches to fit a route
local MIN_SPACING = 7
local ARROW_TEXTURE = "rbxassetid://18518488457"
local ARROW_HEIGHT = 1.6     -- studs above the walked surface
-- Tuned by eye down a real 245-stud route home, not guessed: at 3.2 studs the
-- arrows read as a dotted line from any distance worth guiding over.
local ARROW_WIDTH = 5.0
local ROUTE_EVERY = 0.7      -- seconds between pathfinding attempts
local ROUTE_MOVED = 9        -- ...or sooner if the player has moved this far
local TICK = 0.2             -- state refresh, 5Hz

local existing = playerGui:FindFirstChild("SeedBeginnerGuide")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedBeginnerGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 30 -- menus and the raid alarm still take priority
gui.Parent = playerGui

local connections: { RBXScriptConnection } = {}
local alive = true
local progress: Data.Progress? = nil
local hidden = false
local confirmSkip = false
local celebrated = false
local hintUntil = 0
--==============================================================================
-- THE SPEED SCORE COMES FROM THE PROFILE PACKET, NOT AN ATTRIBUTE
--
-- There deliberately is no SpeedScore attribute: GameConfig publishes only
-- SpeedVisualTier, "one small integer... every OTHER client needs to know which
-- ghost to draw, not how rich you are". The real score is owner-only and rides
-- the profile, which replicates every 0.25s while it is dirty -- so training
-- updates this four times a second, which is live enough to count with.
--==============================================================================
local speedScore = 0

--==============================================================================
-- THE INSTRUCTION. NO PLATE, EVER.
--
-- CashUI's note applies word for word: "The outline IS the readability. There is
-- no plate behind these, so it is the only thing keeping a lime number legible
-- on lime grass." Same font, same black stroke, same reasoning -- a big opaque
-- panel would be the objective card coming back wearing different colours.
--==============================================================================
local function outlined(parent: Instance, name: string, size: number,
	colour: Color3, thickness: number): TextLabel
	local label = UIKit.outlined(parent, name, size, colour, thickness)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	return label
end

local banner = Instance.new("Frame")
banner.Name = "Instruction"
banner.BackgroundTransparency = 1
banner.AnchorPoint = Vector2.new(.5, 0)
banner.Position = UDim2.new(.5, 0, 0, 84)
banner.Size = UDim2.fromOffset(560, 84)
banner.Visible = false
banner.Parent = gui

local instruction = outlined(banner, "Line", 34, CREAM, 3)
instruction.Size = UDim2.new(1, 0, 0, 42)
local subline = outlined(banner, "Sub", 19, GOLD, 2.5)
subline.Position = UDim2.fromOffset(0, 42)
subline.Size = UDim2.new(1, 0, 0, 24)
local counter = outlined(banner, "Counter", 15, Color3.fromRGB(196, 219, 173), 2)
counter.Position = UDim2.fromOffset(0, 64)
counter.Size = UDim2.new(1, 0, 0, 18)

-- Small, off to the side, and never over a gameplay button.
local skip = Instance.new("TextButton")
skip.Name = "Skip"
skip.Text = "Skip guide"
skip.Font = Enum.Font.GothamBold
skip.TextSize = 12
skip.TextColor3 = Color3.fromRGB(214, 205, 184)
skip.BackgroundTransparency = 1
skip.AutoButtonColor = false
skip.AnchorPoint = Vector2.new(.5, 0)
skip.Position = UDim2.new(.5, 0, 0, 168)
skip.Size = UDim2.fromOffset(150, 20)
skip.Visible = false
skip.Parent = gui
UIKit.stroke(skip, BLACK, 2)

local resume = Instance.new("TextButton")
resume.Name = "Resume"
resume.Text = "GUIDE"
resume.Font = Enum.Font.LuckiestGuy
resume.TextSize = 16
resume.TextColor3 = GOLD
resume.BackgroundTransparency = 1
resume.AutoButtonColor = false
resume.AnchorPoint = Vector2.new(.5, 0)
resume.Position = UDim2.new(.5, 0, 0, 84)
resume.Size = UDim2.fromOffset(150, 26)
resume.Visible = false
resume.Parent = gui
UIKit.stroke(resume, BLACK, 2.5)

--==============================================================================
-- THE UI POINTER
--
-- Anchored to whatever is actually on screen -- the real Speed label, the real
-- hotbar slot -- by reading its AbsolutePosition and AbsoluteSize. Nothing here
-- knows a desktop coordinate, so GUI inset, phone widths and UIScale are all
-- somebody else's problem and it still lands on the thing.
--==============================================================================
local pointer = Instance.new("Frame")
pointer.Name = "UIPointer"
pointer.BackgroundTransparency = 1
pointer.Size = UDim2.fromOffset(230, 46)
pointer.Visible = false
pointer.ZIndex = 5
pointer.Parent = gui
local pointerArrow = outlined(pointer, "Arrow", 30, GOLD, 3)
pointerArrow.Size = UDim2.fromOffset(34, 46)
pointerArrow.Text = "\u{25B6}" -- solid right-pointing triangle; renders in this font
local pointerText = outlined(pointer, "Text", 22, CREAM, 3)
pointerText.Position = UDim2.fromOffset(36, 0)
pointerText.Size = UDim2.fromOffset(194, 46)
pointerText.TextXAlignment = Enum.TextXAlignment.Left

--==============================================================================
-- THE CELEBRATION
--
-- Transparent text, a pop that overshoots and settles, a short burst of colour
-- and one existing cue. It never locks movement and never covers a button: it
-- is drawn high on the screen and it goes away by itself.
--==============================================================================
local party = Instance.new("Frame")
party.Name = "Celebration"
party.BackgroundTransparency = 1
party.AnchorPoint = Vector2.new(.5, .5)
party.Position = UDim2.new(.5, 0, .34, 0)
party.Size = UDim2.fromOffset(620, 150)
party.Visible = false
party.ZIndex = 8
party.Parent = gui
local partyScale = Instance.new("UIScale")
partyScale.Scale = 0.2
partyScale.Parent = party
local bigLine = outlined(party, "Big", 52, GOLD, 4)
bigLine.Size = UDim2.new(1, 0, 0, 66)
bigLine.Text = "CONGRATULATIONS!"
bigLine.ZIndex = 9
local smallLine = outlined(party, "Small", 26, CREAM, 3)
smallLine.Position = UDim2.fromOffset(0, 68)
smallLine.Size = UDim2.new(1, 0, 0, 34)
smallLine.Text = "You hatched your first plant!"
smallLine.ZIndex = 9

--==============================================================================
-- WORLD OBJECTS
--
-- One folder, a fixed pool, and nothing that can ever be saved into the place.
--==============================================================================
local world = Instance.new("Folder")
world.Name = "SeedGuideVisuals"
world.Archivable = false
world.Parent = workspace

--==============================================================================
-- A FIXED POOL OF NODES, AND ONE BEAM BETWEEN EACH NEIGHBOURING PAIR
--
-- Built once at login and reused for every route for the rest of the session.
-- Nothing is created or destroyed while the guide is running.
--==============================================================================
local nodes: { Attachment } = {}
local legs: { Beam } = {}
for i = 1, TRAIL_NODES do
	local part = Instance.new("Part")
	part.Name = "TrailNode" .. i
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Archivable = false
	part.Parent = world
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	nodes[i] = attachment
	if i > 1 then
		local beam = Instance.new("Beam")
		--==================================================================
		-- ATTACHMENT0 IS THE NODE FURTHER ALONG, AND THAT IS NOT A TYPO
		--
		-- The arrow glyph in this texture points from Attachment1 TOWARD
		-- Attachment0 -- the opposite of what reading the property names
		-- suggests. Built the obvious way round, the trail was a neat line of
		-- chevrons all pointing back the way the player had come, which is
		-- worse than no trail. Checked by photographing it from the side
		-- against known geometry rather than by reasoning about it.
		--
		-- TextureSpeed is then NEGATIVE so the flow also travels toward the
		-- objective instead of away from it. Speed sets the motion; the
		-- attachment order sets which way the arrowheads face.
		--==================================================================
		beam.Attachment0 = attachment
		beam.Attachment1 = nodes[i - 1]
		beam.Texture = ARROW_TEXTURE
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 9
		beam.TextureSpeed = -1.4
		beam.Width0 = ARROW_WIDTH
		beam.Width1 = ARROW_WIDTH
		beam.FaceCamera = true      -- readable from any angle, like a HUD arrow
		beam.LightInfluence = 0
		beam.Brightness = 3
		beam.Color = ColorSequence.new(GOLD)
		beam.Segments = 1           -- each leg is already a straight line
		beam.Enabled = false
		beam.Parent = attachment
		legs[i - 1] = beam
	end
end
local legCount = 0

local highlight = Instance.new("Highlight")
highlight.Name = "GuideTarget"
highlight.FillColor = GOLD
highlight.FillTransparency = 0.72
highlight.OutlineColor = CREAM
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = gui

-- The bouncing marker over a destination, and the pointing hand over soil. Both
-- are billboards on a tiny invisible anchor part; neither is ever a real object.
local function billboardOn(name: string, glyph: string, colour: Color3, size: number)
	local anchor = Instance.new("Part")
	anchor.Name = name .. "Anchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Archivable = false
	anchor.Parent = world
	local bb = Instance.new("BillboardGui")
	bb.Name = name
	bb.Adornee = anchor
	bb.AlwaysOnTop = true
	-- Studs, not pixels: a waypoint has to stay readable from across a lane, and
	-- an offset-sized billboard shrinks with distance until it is a speck.
	bb.Size = UDim2.fromScale(4, 4)
	bb.LightInfluence = 0
	bb.Enabled = false
	--==========================================================================
	-- THESE TWO ARE NOT IN THE SCREENSHOTS, AND THAT IS THE TOOLING
	--
	-- Parented the way CashPop and PromptUI already do it -- BillboardGui inside
	-- the ScreenGui, Adornee on the world part -- because both of those ship and
	-- work.
	--
	-- They cannot be photographed here. Studio's MCP screen_capture does not
	-- include BillboardGui layers at all: proven by standing next to a pod with
	-- the game's OWN `SeedPrompt` enabled and adorned, and getting a picture with
	-- no prompt in it. So the beacon and the finger below are verified by state
	-- -- enabled, adorned, positioned, sized -- and NOT by a picture, and nobody
	-- should read their absence from a capture as them being broken.
	--==========================================================================
	bb.Parent = gui
	local label = outlined(bb, "Glyph", size, colour, 3)
	label.Size = UDim2.fromScale(1, 1)
	label.Text = glyph
	return anchor, bb
end
-- Down-pointing triangle and a pointing hand. Both were already in use in this
-- project's UI, which is the only reason they are trusted to render.
local beaconAnchor, beacon = billboardOn("Beacon", "\u{25BC}", GOLD, 58)
local fingerAnchor, finger = billboardOn("Finger", "\u{25BC}", Color3.fromRGB(120, 255, 140), 64)

--==============================================================================
-- WHAT THE GUIDE IS LOOKING AT
--==============================================================================
local function myPlot(): Model?
	for _, model in CollectionService:GetTagged(Config.Tags.Plot) do
		if model:IsA("Model") and model:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return model
		end
	end
	return nil
end

-- The belt is the tagged part; its PARENT model carries the plot id. Matching on
-- that is what makes this YOUR mill and not the one next door.
local function myBelt(plot: Model?): BasePart?
	if not plot then
		return nil
	end
	local id = plot:GetAttribute(ATTR.PlotId)
	if type(id) ~= "number" then
		return nil
	end
	for _, belt in CollectionService:GetTagged(Config.Tags.Treadmill) do
		if belt:IsA("BasePart") and belt.Parent and belt.Parent:GetAttribute(ATTR.PlotId) == id then
			return belt
		end
	end
	return nil
end

-- Where a player actually stands to train: the top face of the belt, not the
-- model's pivot, which on a mill sits inside the housing.
local function beltStand(belt: BasePart): Vector3
	return (belt.CFrame * CFrame.new(0, belt.Size.Y * 0.5 + 0.5, 0)).Position
end

local function toolOf(hatched: boolean): Tool?
	local function find(container: Instance?): Tool?
		if not container then
			return nil
		end
		for _, tool in container:GetChildren() do
			if tool:IsA("Tool") and SeedData.Get(tool:GetAttribute("SpeciesId"))
				and (tool:GetAttribute("Hatched") == true) == hatched then
				return tool
			end
		end
		return nil
	end
	return find(player.Character) or find(player:FindFirstChildOfClass("Backpack"))
end

local function plantsFolder(plot: Model): Instance?
	return plot:FindFirstChild(PLOT.PlantsFolderName)
end

local function podIn(plot: Model): Model?
	local folder = plantsFolder(plot)
	local earliest: Model? = nil
	local best = math.huge
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Stage") == 1 then
				local ready = (tonumber(m:GetAttribute("PlantedAt")) or os.time())
					+ SeedData.GrowSeconds(m:GetAttribute("Tier"))
				if ready < best then
					best = ready
					earliest = m
				end
			end
		end
	end
	return earliest
end

--==============================================================================
-- A FREE SPOT ON YOUR OWN SOIL
--
-- Sampled on the soil's own top face and rejected against whatever is already
-- planted, so a full or rearranged bed produces NO spot rather than a finger
-- hovering over an occupied hole. The server still clamps and validates the real
-- placement; this only has to be honest about where there is room.
--==============================================================================
local function freeSpot(plot: Model, soil: BasePart, from: Vector3): Vector3?
	local folder = plantsFolder(plot)
	local taken: { Vector3 } = {}
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") then
				taken[#taken + 1] = m:GetPivot().Position
			end
		end
	end
	local half = soil.Size * 0.5
	local top = half.Y + 0.05
	local best: Vector3? = nil
	local bestScore = math.huge
	for gx = -2, 2 do
		for gz = -2, 2 do
			local point = (soil.CFrame * CFrame.new(
				half.X * (gx / 3) * 1.5, top, half.Z * (gz / 3) * 1.5)).Position
			local clear = true
			for _, other in taken do
				if (Vector3.new(other.X, 0, other.Z) - Vector3.new(point.X, 0, point.Z)).Magnitude < 4.5 then
					clear = false
					break
				end
			end
			if clear then
				local score = (point - from).Magnitude
				if score < bestScore then
					bestScore = score
					best = point
				end
			end
		end
	end
	return best
end

--==============================================================================
-- THE TRAIL
--
-- A real route, not a straight line: AgentCanJump is false, so the path goes
-- through the plot's gateway rather than over its fence, and around the mill
-- rather than across it. If pathfinding cannot answer, NOTHING is drawn -- a
-- straight line of arrows through a wall is worse than no arrows, because the
-- player trusts it and walks into the wall.
--==============================================================================
local routePoints: { Vector3 } = {}
local routeAt = 0
local routeFrom = Vector3.zero
local routeTo = Vector3.zero
local routeBusy = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function hideTrail()
	for i = 1, #legs do
		legs[i].Enabled = false
	end
	legCount = 0
end

local function layTrail(points: { Vector3 })
	local character = player.Character
	rayParams.FilterDescendantsInstances = { world, character or world }

	-- Total length first, so the fixed pool can be stretched to cover the whole
	-- route instead of running out partway down a long one.
	local total = 0
	for i = 1, #points - 1 do
		total += (points[i + 1] - points[i]).Magnitude
	end
	if total < 4 then
		hideTrail()
		return
	end
	--==========================================================================
	-- The pool STRETCHES to cover whatever it is given: a 245-stud run home gets
	-- the same 24 nodes a 30-stud walk to the mill does, just further apart. A
	-- fixed spacing would have run out partway down the long one.
	--==========================================================================
	local spacing = math.max(MIN_SPACING, total / (TRAIL_NODES - 1))

	local used = 0
	local travelled = 0
	local nextMark = 0
	local function placeNode(point: Vector3)
		-- Sat on whatever the player will actually walk over, then lifted --
		-- following the ground rather than the straight line between waypoints.
		local hit = workspace:Raycast(point + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), rayParams)
		local y = (if hit then hit.Position.Y else point.Y) + ARROW_HEIGHT
		used += 1
		nodes[used].Parent.Position = Vector3.new(point.X, y, point.Z)
	end

	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local segment = b - a
		local length = segment.Magnitude
		if length > 0.001 then
			local direction = segment / length
			while nextMark <= travelled + length and used < TRAIL_NODES do
				placeNode(a + direction * (nextMark - travelled))
				nextMark += spacing
			end
		end
		travelled += length
	end
	-- Always finish ON the objective, so the last arrow points at the thing
	-- rather than stopping a spacing short of it.
	if used < TRAIL_NODES and used > 0 then
		placeNode(points[#points])
	end

	for i = 1, #legs do
		legs[i].Enabled = i < used
	end
	legCount = math.max(0, used - 1)
end

local function requestRoute(from: Vector3, to: Vector3)
	if routeBusy then
		return
	end
	local now = os.clock()
	local moved = (from - routeFrom).Magnitude > ROUTE_MOVED or (to - routeTo).Magnitude > 3
	if now - routeAt < ROUTE_EVERY and not moved then
		return
	end
	routeAt = now
	routeFrom, routeTo = from, to
	routeBusy = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2.6,
			AgentHeight = 5.5,
			AgentCanJump = false,
			WaypointSpacing = 6,
		})
		local ok = pcall(function()
			path:ComputeAsync(from, to)
		end)
		if alive and ok and path.Status == Enum.PathStatus.Success then
			local points: { Vector3 } = { from }
			for _, wp in path:GetWaypoints() do
				points[#points + 1] = wp.Position
			end
			routePoints = points
			layTrail(points)
		elseif alive then
			-- Honest failure: no trail rather than a wrong one.
			routePoints = {}
			hideTrail()
		end
		routeBusy = false
	end)
end

--==============================================================================
-- FINDING A REAL RENDERED HUD ELEMENT
--
-- By name, and nil if it is not on screen -- during streaming, or before the HUD
-- has built itself, the pointer simply does not appear.
--==============================================================================
local function hudSpeedLabel(): GuiObject?
	local cash = playerGui:FindFirstChild("SeedCash")
	local corner = cash and cash:FindFirstChild("Corner")
	local label = corner and corner:FindFirstChild("Speed")
	return if label and label:IsA("GuiObject") then label else nil
end

local function hotbarSlotFor(tool: Tool?): GuiObject?
	local loadout = playerGui:FindFirstChild("SeedLoadout")
	local hotbar = loadout and loadout:FindFirstChild("Hotbar")
	if not (hotbar and hotbar:IsA("GuiObject")) then
		return nil
	end
	if tool then
		local want = string.upper(tool.Name)
		for _, slot in hotbar:GetChildren() do
			if slot:IsA("GuiObject") and slot.Visible then
				for _, kid in slot:GetDescendants() do
					if kid:IsA("TextLabel") and string.upper(kid.Text) == want then
						return slot
					end
				end
			end
		end
	end
	return hotbar
end

-- Sits to the LEFT of the target and points right at it, unless that would run
-- off screen, in which case it sits to the right and points left.
local function pointAt(target: GuiObject?, text: string)
	if not target then
		pointer.Visible = false
		return
	end
	local pos, size = target.AbsolutePosition, target.AbsoluteSize
	--==========================================================================
	-- MEASURE THE GLYPHS, NOT THE BOX
	--
	-- The HUD's Speed label is a 260px box holding about 110px of text, because
	-- it has to fit "139.88T" as well as "620". Anchoring to the box put the
	-- pointer a finger-width of empty space away from the number it was pointing
	-- at. TextBounds is what is actually on screen.
	--==========================================================================
	if target:IsA("TextLabel") and target.TextBounds.X > 4 then
		local glyphs = math.min(size.X, target.TextBounds.X + 6)
		if target.TextXAlignment == Enum.TextXAlignment.Left then
			size = Vector2.new(glyphs, size.Y)
		elseif target.TextXAlignment == Enum.TextXAlignment.Right then
			pos = Vector2.new(pos.X + size.X - glyphs, pos.Y)
			size = Vector2.new(glyphs, size.Y)
		else
			pos = Vector2.new(pos.X + (size.X - glyphs) * 0.5, pos.Y)
			size = Vector2.new(glyphs, size.Y)
		end
	end
	local camera = workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local midY = pos.Y + size.Y * 0.5 - 23
	local left = pos.X - pointer.AbsoluteSize.X - 6
	if left < 8 then
		pointer.Position = UDim2.fromOffset(math.min(pos.X + size.X + 6, screen.X - 236), midY)
		pointerArrow.Text = "\u{25C0}"
		pointerArrow.Position = UDim2.fromOffset(0, 0)
		pointerText.Position = UDim2.fromOffset(36, 0)
		pointerText.TextXAlignment = Enum.TextXAlignment.Left
	else
		pointer.Position = UDim2.fromOffset(left, midY)
		pointerArrow.Text = "\u{25B6}"
		pointerArrow.Position = UDim2.fromOffset(196, 0)
		pointerText.Position = UDim2.fromOffset(0, 0)
		pointerText.TextXAlignment = Enum.TextXAlignment.Right
	end
	pointerText.Text = text
	pointer.Visible = true
end

--==============================================================================
-- CLEARING UP
--
-- Called on every step change and every reason the guide stops pointing at
-- something: death, respawn, skip, completion and teardown all land here.
--==============================================================================
local function clearWorld()
	hideTrail()
	routePoints = {}
	routeAt = 0
	routeFrom = Vector3.new(1e6, 1e6, 1e6)
	highlight.Enabled = false
	highlight.Adornee = nil
	beacon.Enabled = false
	finger.Enabled = false
	pointer.Visible = false
end

--==============================================================================
-- THE CELEBRATION, ONCE
--==============================================================================
local function confetti()
	local colours = { GOLD, CREAM, Color3.fromRGB(120, 255, 140), SPEED_BLUE }
	for i = 1, 14 do
		local bit = Instance.new("Frame")
		bit.BackgroundColor3 = colours[(i % #colours) + 1]
		bit.BorderSizePixel = 0
		bit.AnchorPoint = Vector2.new(.5, .5)
		bit.Position = UDim2.new(.5, 0, .5, 0)
		bit.Size = UDim2.fromOffset(10, 10)
		bit.Rotation = i * 26
		bit.ZIndex = 7
		bit.Parent = party
		UIKit.corner(bit, 2)
		local angle = math.rad(i * (360 / 14))
		local dx, dy = math.cos(angle) * 260, math.sin(angle) * 150 - 40
		TweenService:Create(bit, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(.5, dx, .5, dy),
			Rotation = bit.Rotation + 180,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(4, 4),
		}):Play()
		task.delay(1.3, function()
			bit:Destroy()
		end)
	end
end

local function celebrate()
	if celebrated then
		return
	end
	celebrated = true
	party.Visible = true
	partyScale.Scale = 0.2
	-- Overshoot then settle: Back/Out is the pop, and it is a tween rather than
	-- a per-frame loop so it costs nothing after it finishes.
	TweenService:Create(partyScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	confetti()
	if SoundKit.has("RevealLegendary") then
		SoundKit.play("RevealLegendary")
	end
	task.delay(3.4, function()
		if not alive then
			return
		end
		local out = TweenService:Create(partyScale,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.1 })
		out:Play()
		out.Completed:Wait()
		party.Visible = false
	end)
	-- The hint that follows is optional, brief, and never places anything.
	hintUntil = os.clock() + 45
end

--==============================================================================
-- SERVER STATE
--==============================================================================
local function receive(state: any)
	if type(state) ~= "table" or type(state.Done) ~= "table" then
		return
	end
	local before = if progress then (select(1, Data.Current(progress))) else nil
	progress = state :: Data.Progress
	local now = select(1, Data.Current(progress :: Data.Progress))
	local finished = now > #Data.Steps
	if before and before <= #Data.Steps and finished and not state.Skipped then
		-- Crossed the line THIS SESSION. A player who joins already finished
		-- takes the branch below and gets no fanfare for old news.
		clearWorld()
		celebrate()
	elseif not before and finished then
		celebrated = true
		hidden = true
	end
end

local function receiveProfile(profile: any)
	if type(profile) == "table" then
		if type(profile.Speed) == "number" then
			speedScore = profile.Speed
		end
		receive(profile.Tutorial)
	end
end

table.insert(connections, (remotes:WaitForChild(Config.Remotes.ProfileUpdated) :: RemoteEvent)
	.OnClientEvent:Connect(receiveProfile))
table.insert(connections, (remotes:WaitForChild(Config.Remotes.ProfileReady) :: RemoteEvent)
	.OnClientEvent:Connect(function(ok: any, profile: any)
		if ok == true then
			receiveProfile(profile)
		end
	end))
table.insert(connections, channel.OnClientEvent:Connect(function(action: any, state: any)
	if action == Data.Action then
		receive(state)
	end
end))
table.insert(connections, skip.Activated:Connect(function()
	if confirmSkip then
		channel:FireServer(Data.Action, "skip")
		confirmSkip = false
		clearWorld()
	else
		confirmSkip = true
	end
end))
table.insert(connections, resume.Activated:Connect(function()
	if progress and progress.Skipped then
		channel:FireServer(Data.Action, "resume")
	end
	hidden = false
	confirmSkip = false
end))

--==============================================================================
-- ONE PASS OF THE STATE MACHINE
--==============================================================================
local lastStep = ""

local function refresh()
	local state = progress
	if not state then
		return
	end
	local index = select(1, Data.Current(state))
	local complete = index > #Data.Steps

	local menu = player:GetAttribute(ATTR.OpenPanel)
	local obstructed = type(menu) == "string" and menu ~= ""
	local biomeGui = playerGui:FindFirstChild("SeedBiomeGuide")
	local biomeBanner = biomeGui and biomeGui:FindFirstChildWhichIsA("Frame")
	if biomeBanner and biomeBanner.Visible then
		obstructed = true
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local live = root and root:IsA("BasePart") and humanoid and humanoid.Health > 0

	local showing = not hidden and not state.Skipped and not obstructed and not complete
	banner.Visible = showing
	skip.Visible = showing and not complete
	skip.Text = if confirmSkip then "Tap again to skip" else "Skip guide"
	resume.Visible = (state.Skipped or hidden) and not obstructed and not complete

	--== the optional post-tutorial nudge ====================================
	if complete then
		clearWorld()
		local hatchling = toolOf(true)
		if hatchling and os.clock() < hintUntil and not obstructed then
			banner.Visible = true
			instruction.Text = "Plant it to earn cash!"
			subline.Text = "Equip it, then tap your soil."
			counter.Text = ""
			local plot = myPlot()
			local soil = plot and plot:FindFirstChild(PLOT.PlanterName)
			if plot and soil and soil:IsA("BasePart") and live then
				local spot = freeSpot(plot, soil, (root :: BasePart).Position)
				if spot then
					fingerAnchor.Position = spot + Vector3.new(0, 4.2, 0)
					finger.Enabled = true
				end
			end
			pointAt(hotbarSlotFor(hatchling), "This one")
		end
		return
	end

	if not showing then
		clearWorld()
		return
	end

	local step = Data.Steps[index]
	if step.Id ~= lastStep then
		-- Every step change starts from nothing on screen.
		clearWorld()
		lastStep = step.Id
	end

	instruction.Text = step.Title
	subline.Text = ""
	counter.Text = "STEP " .. index .. " / " .. #Data.Steps
	if confirmSkip then
		instruction.Text = "Skip the guide?"
		subline.Text = "Your finished steps stay saved."
		clearWorld()
		return
	end
	if not live then
		instruction.Text = step.Title
		subline.Text = "Your progress is safe -- back in a moment."
		clearWorld()
		return
	end
	local here = (root :: BasePart).Position

	local plot = myPlot()
	if not plot then
		subline.Text = "Waiting for your plot..."
		clearWorld()
		return
	end
	local soil = plot:FindFirstChild(PLOT.PlanterName)
	local id = step.Id

	--== 1 and 2: the mill, then the number =================================
	if id == "train" or id == "speed" then
		local belt = myBelt(plot)
		if not belt then
			subline.Text = "Looking for your treadmill..."
			clearWorld()
			return
		end
		local stand = beltStand(belt)
		highlight.Adornee = belt
		highlight.Enabled = true
		beaconAnchor.Position = stand + Vector3.new(0, 5.2, 0)
		beacon.Enabled = true
		if id == "speed" then
			-- Point at the REAL speed readout and count toward the target.
			--==============================================================
			-- The CURRENT value uses the HUD's own compactor, so it reads the
			-- same way the number it is pointing at does. The TARGET is written
			-- out in full: compact() turns 1000 into "1K", and "620 / 1K" is a
			-- worse goal to read than "620 / 1,000" -- which is also the number
			-- the step title just said out loud.
			--==============================================================
			pointAt(hudSpeedLabel(), Config.compact(speedScore) .. " / 1,000 SPEED")
			subline.Text = "Keep running on your mill."
		else
			pointer.Visible = false
		end
		if (here - stand).Magnitude > 12 then
			requestRoute(here, stand)
		else
			hideTrail()
		end
		return
	end

	--== 3: a real, available Greenhollow pod ================================
	if id == "steal" then
		--======================================================================
		-- WHEN THERE IS NOTHING TO TAKE, SAY SO AND SAY WHEN
		--
		-- Greenhollow is ONE nest of FIVE pods and a taken slot does NOT regrow
		-- during the day -- the 22-second regrow was removed on purpose, because
		-- a nest that refills itself is a nest with no scarcity in it. Only dawn
		-- restocks. On a busy server a new player can therefore reach this step
		-- and find the biome genuinely stripped, with up to a full day to wait.
		--
		-- That is a normal state of the game, not an error, so the guide has to
		-- have an answer for it: what happened, when it clears, and something
		-- worth doing until then. Standing in an empty biome reading "Heading to
		-- Greenhollow..." while walking to a place with no pods in it is the
		-- worst version of every one of those.
		--
		-- Training is the right thing to suggest. It is the only faucet for
		-- Speed, and Speed is exactly what decides whether the theft this step is
		-- waiting for actually gets home.
		--======================================================================
		local function dawnIn(): number?
			local endsAt = tonumber(workspace:GetAttribute(ATTR.WorldPhaseEndsAt))
			if not endsAt then
				return nil
			end
			local left = endsAt - workspace:GetServerTimeNow()
			-- At night the next phase change IS dawn. In the day it is dusk, and
			-- the restock lands a whole night after that.
			if workspace:GetAttribute(ATTR.WorldPhase) ~= "Night" then
				left += Config.WorldCycle.NightSeconds
			end
			return math.max(0, left)
		end

		local function waitAtTheMill(headline: string)
			instruction.Text = headline
			local left = dawnIn()
			subline.Text = if left
				then string.format("Pods return at dawn in %ds -- train while you wait!", math.ceil(left))
				else "Pods return at dawn -- train while you wait!"
			local belt = myBelt(plot)
			if belt then
				local stand = beltStand(belt)
				highlight.Adornee = belt
				highlight.Enabled = true
				beaconAnchor.Position = stand + Vector3.new(0, 5.2, 0)
				beacon.Enabled = true
				if (here - stand).Magnitude > 12 then
					requestRoute(here, stand)
				else
					hideTrail()
				end
			else
				clearWorld()
			end
		end

		if workspace:GetAttribute(ATTR.WorldPhase) == "Night" then
			waitAtTheMill("The nests are closed for the night!")
			return
		end
		local best: Model? = nil
		local bestPos: Vector3? = nil
		local bestDist = math.huge
		for _, m in CollectionService:GetTagged(Config.Tags.SeedPod) do
			local species = SeedData.Get(m:GetAttribute("SpeciesId"))
			if species and species.Biome == "greenhollow" and m:IsDescendantOf(workspace)
				and not CollectionService:HasTag(m, Config.Tags.Planted)
				and m:FindFirstChildWhichIsA("ProximityPrompt", true) then
				local point = if m:IsA("Model") then m:GetPivot().Position else nil
				if point then
					local d = (point - here).Magnitude
					if d < bestDist then
						best, bestPos, bestDist = m :: Model, point, d
					end
				end
			end
		end
		if not (best and bestPos) then
			--==================================================================
			-- EMPTY, OR JUST NOT LOADED YET? THE ANSWER IS WHERE THEY STANDING
			--
			-- Streaming can take the pods out of a distant player's world, and
			-- telling somebody stood in the safe field that the nest is stripped
			-- would often be a lie. So distance decides: from far away, walk
			-- them to the biome and retarget the moment a pod appears -- from
			-- inside it, with nothing found, the nest really is empty.
			--==================================================================
			local nestFar = math.abs(here.Z + Config.Map.FieldFront) < 90
			if nestFar then
				subline.Text = "Heading to Greenhollow..."
				highlight.Enabled = false
				beacon.Enabled = false
				requestRoute(here, Vector3.new(0, Config.Map.GroundY, -Config.Map.FieldFront - 60))
			else
				waitAtTheMill("Greenhollow is picked clean!")
			end
			return
		end
		highlight.Adornee = best
		highlight.Enabled = true
		beaconAnchor.Position = bestPos + Vector3.new(0, 5, 0)
		beacon.Enabled = true
		requestRoute(here, bestPos)
		return
	end

	--== 4: home, through the real banking boundary ==========================
	if id == "bank" then
		local carrying = type(player:GetAttribute(ATTR.CarryingSpecies)) == "string"
		if not carrying then
			subline.Text = if toolOf(false) then "Head to your soil." else "Go and take another pod."
		end
		-- Aim at the player's own plot spawn: it is inside the field, past the
		-- red line, so the route crosses the boundary that does the banking.
		local goal: Vector3? = nil
		for _, m in plot:GetDescendants() do
			if m:IsA("BasePart") and CollectionService:HasTag(m, Config.Tags.PlotSpawn) then
				goal = m.Position + Vector3.new(0, 2, 0)
				break
			end
		end
		goal = goal or (plot:GetPivot().Position + Vector3.new(0, 2, 0))
		beaconAnchor.Position = goal + Vector3.new(0, 5, 0)
		beacon.Enabled = true
		requestRoute(here, goal)
		return
	end

	--== 5: a free spot on your own soil =====================================
	if id == "place" then
		if not (soil and soil:IsA("BasePart")) then
			subline.Text = "Looking for your soil..."
			clearWorld()
			return
		end
		local pod = toolOf(false)
		if not pod then
			-- Never point at soil with nothing to put in it.
			if type(player:GetAttribute(ATTR.CarryingSpecies)) == "string" then
				instruction.Text = "Bring it to your plot!"
				subline.Text = "Cross the red line to bank it."
			else
				instruction.Text = "Take a pod!"
				subline.Text = "Your pod is gone -- grab another from Greenhollow."
			end
			clearWorld()
			return
		end
		local spot = freeSpot(plot, soil :: BasePart, here)
		if not spot then
			subline.Text = "Your plot is full -- hatch or lift a plant to make room."
			clearWorld()
			return
		end
		fingerAnchor.Position = spot + Vector3.new(0, 4.2, 0)
		finger.Enabled = true
		highlight.Adornee = soil
		highlight.Enabled = true
		if not pod.Parent or pod.Parent ~= player.Character then
			pointAt(hotbarSlotFor(pod), "Equip this")
		else
			pointer.Visible = false
		end
		if (here - spot).Magnitude > 14 then
			requestRoute(here, spot)
		else
			hideTrail()
		end
		return
	end

	--== 6: the pod they planted =============================================
	if id == "hatch" then
		local pod = podIn(plot)
		if not pod then
			instruction.Text = if toolOf(false) then "Place your pod here!" else "Take a pod!"
			subline.Text = "Nothing is growing yet."
			clearWorld()
			return
		end
		local point = pod:GetPivot().Position
		highlight.Adornee = pod
		highlight.Enabled = true
		beaconAnchor.Position = point + Vector3.new(0, 4.6, 0)
		beacon.Enabled = true
		local ready = (tonumber(pod:GetAttribute("PlantedAt")) or os.time())
			+ SeedData.GrowSeconds(pod:GetAttribute("Tier"))
		local left = math.max(0, math.ceil(ready - os.time()))
		if left > 0 then
			subline.Text = "Ready in " .. left .. "s"
		else
			subline.Text = "Hold the Hatch prompt."
		end
		if (here - point).Magnitude > 14 then
			requestRoute(here, point)
		else
			hideTrail()
		end
		return
	end
end

--==============================================================================
-- TWO LOOPS: STATE AT 5Hz, MOTION EVERY FRAME
--
-- The per-frame half only reads a clock and writes transparencies and one
-- position on a fixed pool. It never searches the world, allocates or rebuilds
-- a path -- that is the 5Hz half's job, and even there the route is throttled
-- again on top.
--==============================================================================
local since = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since >= TICK then
		since = 0
		local ok, err = pcall(refresh)
		if not ok then
			warn("[Seed/TutorialUI] " .. tostring(err))
		end
	end
	local clock = os.clock()
	-- The trail animates itself: the arrow texture scrolls from TextureSpeed, so
	-- there is deliberately nothing here for it.
	if beacon.Enabled then
		beacon.StudsOffset = Vector3.new(0, math.sin(clock * 3.4) * 0.42, 0)
	end
	if finger.Enabled then
		finger.StudsOffset = Vector3.new(0, math.abs(math.sin(clock * 3.1)) * 0.7, 0)
	end
end))

local function onCharacter()
	clearWorld()
	lastStep = ""
end
table.insert(connections, player.CharacterAdded:Connect(onCharacter))
table.insert(connections, player.CharacterRemoving:Connect(onCharacter))

gui.Destroying:Connect(function()
	alive = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	-- The billboards live under `gui` and go with it; the anchors and the
	-- trail node pool lives under `world` and has to be taken down by hand.
	world:Destroy()
end)

task.spawn(function()
	while alive and not progress do
		channel:FireServer(Data.Action, "snapshot")
		task.wait(2)
	end
end)
