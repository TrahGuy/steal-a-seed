--!strict
-- Steal a Seed :: PlantPlace
--
-- Turning a click on your own soil into a plant at that exact spot.
--
--==============================================================================
-- THE POSITION CAN ONLY COME FROM HERE
--
-- Tool.Activated fires on the server with no idea where the player was
-- pointing. ClickDetector does not carry a hit position either. A click point
-- exists on the client and nowhere else, so this raycasts and sends it.
--
-- Everything sent is a claim and the server treats it as one -- it re-checks
-- the plot, pulls the point onto the soil and measures the distance itself.
-- Nothing here is trusted, and nothing here needs to be.
--
--==============================================================================
-- NOT Tool.Activated, ON PURPOSE
--
-- The obvious wiring is to plant on the tool's own activation. It does not
-- work on a phone: the mobile tool button is a piece of UI in the corner, so
-- the tap that activates the tool is nowhere near the ground and the last
-- known cursor position is wherever they last touched.
--
-- Listening for the touch on the WORLD instead behaves identically on both --
-- you tap the spot you want, and the spot you tapped is the spot it lands.
-- MOBILE FIRST is a rule in this repo and this is what it costs.
--
--==============================================================================
-- YOU CAN PLANT THROUGH A PLANT
--
-- Overlap is allowed by design -- a garden is arranged, not slotted -- so the
-- ray deliberately ignores the Plants folder. Without that, a big Bellchime
-- would shadow the soil behind it and there would be a patch of your own bed
-- you could no longer reach.
--
-- For EVERYTHING, Secrets included (the owner's rule, 2026-10-02): an item is
-- placed by its BASE, one small circle the same for all, and how far the model
-- reaches -- over other plants, the owner's own fence, gate, signs or mill --
-- is never a reason to refuse it. See A DISC WHERE IT WILL LAND.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))

local Remotes = SeedGame:WaitForChild("Remotes")
local channel = Remotes:WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local player = Players.LocalPlayer
local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant

--==============================================================================
-- WHAT IS IN YOUR HANDS
--
-- A Tool with a SpeciesId is either a banked pod or a hatched creature, and
-- both are planted the same way. Anything else in the hotbar is not.
--==============================================================================
local function heldTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and type(tool:GetAttribute("SpeciesId")) == "string" then
		return tool
	end
	return nil
end

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model")
			and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

local function soilOf(plot: Model): BasePart?
	local soil = plot:FindFirstChild(GameConfig.Plot.PlanterName)
	return if soil and soil:IsA("BasePart") then soil else nil
end

--==============================================================================
-- WHERE THE CURSOR IS POINTING, IF IT IS POINTING AT YOUR BED
--
-- GetMouseLocation rather than the input's own position: it is reported without
-- the top-bar inset, which is the space ViewportPointToRay expects, and it is
-- the same call on a phone -- it returns the last touch. One code path for both.
--==============================================================================
-- What the bed is made of, beyond the planter itself. Named rather than
-- inferred: a click must land on the BED, not on a fence rail or a neighbour's
-- plot that happens to be behind it.
local BED_PARTS: { [string]: boolean } = {
	SoilRow = true,
	Clod = true,
	--==========================================================================
	-- BedWalk IS PART OF THE BED, EVEN THOUGH YOU CANNOT SEE IT
	--
	-- It is the invisible pad that stops a player standing ankle-deep in their
	-- own soil, and it shares its top surface exactly with SoilRow -- so a ray
	-- aimed at a row can land on either one. It is marked CanQuery = false,
	-- which is not enough on its own at an exact tie.
	--
	-- Leaving it out made the bed unclickable wherever the pad won: soilPoint
	-- returned nil, the ghost vanished, and nothing reached the server to
	-- explain why. Both parts mean the same thing -- the player clicked their
	-- bed -- and the server does not care which was hit, because clampToSoil
	-- projects the point into the planter and zeroes Y before placing anything.
	--==========================================================================
	BedWalk = true,
}

--==============================================================================
-- EVERY BED, AND WHICH ONE A POINT BELONGS TO -- THE SERVER'S RULE, MIRRORED
--
-- From Level 3 a plot has a second bed. This used to know only `Soil`, so the
-- disc was clamped into the MAIN bed's rectangle wherever the cursor was: aim at
-- the side bed and the circle sat pinned on the main bed's rim. Worse, the side
-- slab is not named Soil, so a click on its bare surface was dropped here and
-- never reached the server at all.
--
-- The server already decides with `bedsOf` + `pickBed` in PlantService: every
-- Planter-tagged child of the plot, main first, nearest clamped point wins.
-- These are copies of that rule for the PREVIEW only -- the server still picks
-- the bed from the raw point, and nothing here is sent as a claim.
--==============================================================================
local function bedsOf(plot: Model): { BasePart }
	local out: { BasePart } = {}
	local main = soilOf(plot)
	if main then
		table.insert(out, main)
	end
	for _, d in ipairs(plot:GetChildren()) do
		if d:IsA("BasePart") and d ~= main
			and CollectionService:HasTag(d, GameConfig.Tags.Planter) then
			table.insert(out, d)
		end
	end
	return out
end

local function pickBed(plot: Model, worldPos: Vector3): BasePart?
	local margin = PLANTING.EdgeMarginStuds
	local best, bestD = nil, math.huge
	for _, bed in ipairs(bedsOf(plot)) do
		local here = bed.CFrame:PointToObjectSpace(worldPos)
		local halfX = math.max(bed.Size.X * 0.5 - margin, 0)
		local halfZ = math.max(bed.Size.Z * 0.5 - margin, 0)
		local top = bed.CFrame * CFrame.new(
			math.clamp(here.X, -halfX, halfX), bed.Size.Y * 0.5,
			math.clamp(here.Z, -halfZ, halfZ))
		local d = (top.Position - worldPos).Magnitude
		if d < bestD then
			best, bestD = bed, d
		end
	end
	return best
end

-- `aim` is a viewport point; nil means the cursor (or the last touch). The third
-- result is whatever the ray stopped on, so a caller can say WHY it is not the
-- bed -- a neighbour's plot, the path, the sky.
local function soilPoint(aim: Vector2?): (Vector3?, BasePart?, Instance?)
	local camera = workspace.CurrentCamera
	local plot = myPlot()
	if not (camera and plot) then
		return nil, nil, nil
	end
	local soil = soilOf(plot)
	if not soil then
		return nil, nil, nil
	end

	local at = aim or UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(at.X, at.Y)

	local ignore: { Instance } = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	-- See the header: a planted creature must never shadow the bed it stands in.
	local plants = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if plants then
		table.insert(ignore, plants)
	end
	--==========================================================================
	-- AND NEITHER MAY YOUR OWN FENCE
	--
	-- MEASURED, standing at the edge of the bed with the camera behind the
	-- character: a sweep of the whole screen landed on Rail 168 times, BedFrame
	-- 24, Post 9 -- and on the bed ZERO times. Every click hit the fence first,
	-- this returned nil, and nothing reached the server, so planting took
	-- however many clicks it took to find a gap between two rails.
	--
	-- So every part of THIS plot that is not the bed is ignored, and the ray
	-- goes through the fence to the soil. The plot is flat -- posts, rails,
	-- frames and rows are all direct children -- so this is one pass over under
	-- a hundred children, cheap enough to do on every frame the ghost moves.
	-- The rest of the world still blocks the ray, and so does a neighbour's plot.
	--==========================================================================
	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("BasePart") and not BED_PARTS[child.Name]
			and not CollectionService:HasTag(child, GameConfig.Tags.Planter) then
			table.insert(ignore, child)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if not hit then
		return nil, soil, nil
	end
	--==================================================================
	-- THE BED IS MORE THAN ONE PART, AND THIS TEST STILL THOUGHT IT WAS
	--
	-- This required the ray to land on the single `Soil` planter. Then the bed
	-- was tilled: MapService now raises a SoilRow slab per row on top of that
	-- planter and scatters Clods in the furrows. Both sit ABOVE the planter, so
	-- a click aimed at a row hits the row -- and this returned nil.
	--
	-- The symptom was "I can only place on the ground, not on a soil row",
	-- which is exactly backwards from what a bed is for, and it never reached
	-- the server: the client gave up here, so not even a refusal code was
	-- logged. Every guard in PlaceAt was innocent.
	--
	-- Anything belonging to THIS plot's bed counts. The server does not care
	-- which one was hit: clampToSoil projects the point into the planter's
	-- object space and zeroes Y, so a row, a clod and the planter all flatten
	-- to the same plane before anything is placed.
	--==================================================================
	local instance = hit.Instance
	local onPlanter = instance:IsDescendantOf(plot)
		and CollectionService:HasTag(instance, GameConfig.Tags.Planter)
	if not onPlanter
		and not (BED_PARTS[instance.Name] and instance:IsDescendantOf(plot))
	then
		return nil, soil, instance
	end
	-- The bed the server will plant on, so the disc is clamped into THAT one.
	return hit.Position, pickBed(plot, hit.Position) or soil, instance
end

--==============================================================================
-- A DISC WHERE IT WILL LAND
--
-- Without this, "exactly where I clicked" is a claim the player has to take on
-- faith, and the one place it is NOT exact -- the rim of the bed, where the
-- server pulls the point inside -- would read as the click being ignored.
--
-- ONE SMALL CIRCLE, THE SAME FOR EVERYTHING (the owner's rule, 2026-10-02). It
-- marks where the BASE goes -- GameConfig.Plant.BaseCircleStuds across for a
-- pod, a plant or a Secret alike, whatever its species, rarity, size or model --
-- never how far the model will reach. It used to be sized to the thing's own
-- footprint, which made a big plant's disc look like a promise that it would
-- fit; nothing is refused for fitting any more. Tinted by what is in the hands
-- (PlantInfo.SizeColour: its weight band, or a Secret's rarity colour).
--==============================================================================
local BASE_CIRCLE = PLANTING.BaseCircleStuds

local ghost = Instance.new("Part")
ghost.Name = "PlantGhost"
ghost.Shape = Enum.PartType.Cylinder
ghost.Anchored = true
ghost.CanCollide = false
ghost.CanQuery = false
ghost.CanTouch = false
ghost.Material = Enum.Material.Neon
ghost.Transparency = 0.72
-- Set once: a cylinder's height runs along its X axis, its width is Y and Z.
ghost.Size = Vector3.new(0.12, BASE_CIRCLE, BASE_CIRCLE)
ghost.Parent = workspace

local function hideGhost()
	if ghost.Transparency < 1 then
		ghost.Transparency = 1
	end
end

--==============================================================================
-- PUTTING IT DOWN WITHOUT PLANTING IT
--
-- Hatching equips the creature, and a Tool in your hands is not droppable --
-- deliberately, because a plant you can knock out of somebody's arms is loot,
-- and a plant is not loot. The consequence was that the only way to empty your
-- hands was to plant the thing, so you could not hatch a second pod, could not
-- swap to a different plant in the hotbar, and could not run a raid.
--
-- Unequipping is none of those. It puts the Tool back in the Backpack with
-- everything about it intact -- same kg, same Hatched flag, same slot -- and
-- gives you your hands back. Nothing is placed, nothing is destroyed, nothing
-- is dropped on the floor for a neighbour.
--
-- Roblox's own toolbar click already does this and now actually works: the
-- reason it did not was a CarryWeld left joining a backpacked Handle to the
-- root, which CarryService now cuts on Unequipped. This is the second way in,
-- for anybody not looking at the hotbar.
--
-- BOUND ONLY WHILE SOMETHING IS HELD, because createTouchButton draws a button
-- on a phone and a button that does nothing is worse than no button. It
-- appears with the plant in your hands and goes when they are empty.
--
-- It cannot touch a raid carry. That pod is a Model welded to the root, not a
-- Tool, and UnequipTools does not know it exists -- which is exactly the
-- separation the two channels are supposed to have.
--==============================================================================
local UNEQUIP_ACTION = "SeedUnequip"
local bound = false

local function unequip(_name: string, state: Enum.UserInputState): Enum.ContextActionResult?
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid:UnequipTools()
	end
	return Enum.ContextActionResult.Sink
end

local function setBound(want: boolean)
	if want == bound then
		return
	end
	bound = want
	if want then
		ContextActionService:BindAction(UNEQUIP_ACTION, unequip, true, Enum.KeyCode.Q)
		ContextActionService:SetTitle(UNEQUIP_ACTION, "Put away")
	else
		ContextActionService:UnbindAction(UNEQUIP_ACTION)
	end
end

-- The same clamp the server applies, so the disc sits where the plant will
-- actually go rather than where the cursor happens to be. Two copies of one
-- rule is a risk; a disc that lies about the rim is a certainty.
local function landingOf(point: Vector3, soil: BasePart): CFrame
	local here = soil.CFrame:PointToObjectSpace(point)
	local halfX = math.max(soil.Size.X * 0.5 - PLANTING.EdgeMarginStuds, 0)
	local halfZ = math.max(soil.Size.Z * 0.5 - PLANTING.EdgeMarginStuds, 0)
	--==========================================================================
	-- ABOVE THE ROWS, NOT ABOVE THE SLAB
	--
	-- This used to sit at the slab's top plus 6 hundredths. The SoilRow strips
	-- lie ON that slab and stand another 0.18 proud of it, so the disc was a
	-- tenth of a stud INSIDE the soil it was meant to be lying on -- invisible
	-- everywhere except the bare furrows between rows.
	--
	-- Cleared over the rows instead. Over a furrow it now floats by the row
	-- height, which is the right way round for an indicator: slightly proud and
	-- readable beats flush and hidden.
	--
	-- This moves the PREVIEW only. Where the plant actually lands is decided by
	-- PlantService and is deliberately left alone -- every saved garden is
	-- anchored to that surface.
	--==========================================================================
	return soil.CFrame * CFrame.new(
		math.clamp(here.X, -halfX, halfX),
		soil.Size.Y * 0.5 + GameConfig.Plot.SoilRowRise + 0.06,
		math.clamp(here.Z, -halfZ, halfZ))
end

--==============================================================================
-- ON A CONTROLLER: AIM WITH THE CAMERA, RT TO PLANT, B TO PUT IT AWAY
--
-- A controller has no cursor, so the ray comes from the MIDDLE OF THE CAMERA
-- instead: the player turns the camera with the right stick exactly as they
-- always do, and wherever the middle of the screen lands on their bed is where
-- the disc sits. A reticle marks that middle, and says in words when the spot
-- is no good and why -- the same words the server would send, in the same
-- order PlaceAt checks them (reach, then room), because a refusal a player can
-- see coming is one they never have to hear.
--
-- RT asks the server to plant there -- the same request, carrying the same
-- raw point, that a click sends, so every rule the server enforces (the
-- sender's own plot, reach, room, which bed, the Tool in the hands and its
-- weight and hatch state) is enforced exactly as it is for a click. B puts the
-- plant away through the same UnequipTools the Q key and the phone's Put away
-- button use: back into the Backpack, whole, in its slot.
--
-- Only while a plant is in the hands, the last input was a controller, and no
-- panel is open. A press that lands while the player is steering a UI
-- selection is the UI's, never the world's.
--==============================================================================
local VALID = Color3.fromRGB(142, 220, 68)
local INVALID = Color3.fromRGB(255, 118, 100)
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(26, 24, 30)

local PAD_REASON: { [string]: string } = {
	AIM = "Aim at your garden bed.",
	NOT_YOURS = "That's not your plot.",
	PLANT_OUT_OF_RANGE = ActionRefusal.Text.PLANT_OUT_OF_RANGE,
	PLOT_FULL = ActionRefusal.Text.PLOT_FULL,
}

local playerGui = player:WaitForChild("PlayerGui")
local stalePad = playerGui:FindFirstChild("SeedPadPlace")
if stalePad then
	stalePad:Destroy()
end

local padGui = Instance.new("ScreenGui")
padGui.Name = "SeedPadPlace"
padGui.ResetOnSpawn = false
-- Window space, so the middle of this gui IS the middle of the camera.
padGui.IgnoreGuiInset = true
-- Over the world and the HUD, under every panel (they start at 30).
padGui.DisplayOrder = 22
padGui.Enabled = false
-- Bigger on a TV (HudLayout's TEN-FOOT PROFILE). Everything in it is placed in
-- fractions of the window from its centre, so it stays exactly on the ray.
UIKit.tenFoot(padGui)
padGui.Parent = playerGui

-- A dark halo behind a coloured ring, so it reads on pale soil and dark soil.
local halo = Instance.new("Frame")
halo.Name = "Halo"
halo.AnchorPoint = Vector2.new(0.5, 0.5)
halo.Position = UDim2.fromScale(0.5, 0.5)
halo.Size = UDim2.fromOffset(40, 40)
halo.BackgroundTransparency = 1
halo.Parent = padGui
UIKit.corner(halo, 20)
UIKit.stroke(halo, INK, 3, 0.25)

local ring = Instance.new("Frame")
ring.Name = "Reticle"
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromScale(0.5, 0.5)
ring.Size = UDim2.fromOffset(34, 34)
ring.BackgroundTransparency = 1
ring.Parent = padGui
UIKit.corner(ring, 17)
local ringStroke = UIKit.stroke(ring, VALID, 3)

local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(6, 6)
dot.BackgroundColor3 = VALID
dot.BorderSizePixel = 0
dot.Parent = padGui
UIKit.corner(dot, 3)
UIKit.stroke(dot, INK, 1.5)

local reasonLabel = UIKit.outlined(padGui, "Reason", 22, INVALID, 2)
reasonLabel.AnchorPoint = Vector2.new(0.5, 0)
reasonLabel.Position = UDim2.new(0.5, 0, 0.5, 30)
reasonLabel.Size = UDim2.fromOffset(460, 28)
reasonLabel.Visible = false

local hints = Instance.new("Frame")
hints.Name = "Hints"
hints.AnchorPoint = Vector2.new(0.5, 0)
hints.Position = UDim2.new(0.5, 0, 0.5, 64)
hints.Size = UDim2.fromOffset(460, 36)
hints.BackgroundTransparency = 1
hints.Parent = padGui
local hintsLayout = Instance.new("UIListLayout")
hintsLayout.FillDirection = Enum.FillDirection.Horizontal
hintsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hintsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hintsLayout.Padding = UDim.new(0, 22)
hintsLayout.SortOrder = Enum.SortOrder.LayoutOrder
hintsLayout.Parent = hints

type Hint = { key: Enum.KeyCode, glyph: ImageLabel, short: TextLabel, word: TextLabel }
local hintList: { Hint } = {}

local function hint(order: number, key: Enum.KeyCode, text: string): Hint
	local chip = Instance.new("Frame")
	chip.Name = "Hint" .. PadInput.short(key)
	chip.BackgroundTransparency = 1
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.Size = UDim2.fromOffset(0, 36)
	chip.LayoutOrder = order
	chip.Parent = hints
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 8)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = chip
	-- The controller's own art for the button; the letters stand in only when the
	-- engine has none for it.
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Glyph"
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromOffset(34, 34)
	glyph.LayoutOrder = 1
	glyph.Parent = chip
	local short = Instance.new("TextLabel")
	short.Name = "Short"
	short.BackgroundColor3 = INK
	short.BackgroundTransparency = 0.15
	short.Font = Enum.Font.GothamBlack
	short.TextColor3 = WHITE
	short.TextSize = 16
	short.Text = PadInput.short(key)
	short.Size = UDim2.fromOffset(40, 30)
	short.LayoutOrder = 1
	short.Parent = chip
	UIKit.corner(short, 8)
	local word = UIKit.outlined(chip, "Word", 20, WHITE, 2)
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromOffset(0, 28)
	word.Text = text
	word.LayoutOrder = 2
	local entry: Hint = { key = key, glyph = glyph, short = short, word = word }
	table.insert(hintList, entry)
	return entry
end

local placeHint = hint(1, Enum.KeyCode.ButtonR2, "PLANT")
hint(2, Enum.KeyCode.ButtonB, "PUT AWAY")

local function paintGlyphs()
	for _, h in ipairs(hintList) do
		local image = PadInput.glyph(h.key)
		h.glyph.Image = image
		h.glyph.Visible = image ~= ""
		h.short.Visible = image == ""
	end
end
paintGlyphs()
PadInput.Changed:Connect(function(onPad: boolean)
	if onPad then
		-- A different controller may have been picked up; its art may differ.
		paintGlyphs()
	end
end)

-- Written only when something changed: this runs every frame a plant is held.
local padShown = false
local padValid: boolean? = nil
local padReason: string? = nil

local function showPad(show: boolean, valid: boolean?, reason: string?)
	if show ~= padShown then
		padShown = show
		padGui.Enabled = show
	end
	if not show then
		return
	end
	if valid ~= padValid then
		padValid = valid
		local colour = if valid then VALID else INVALID
		ringStroke.Color = colour
		dot.BackgroundColor3 = colour
		-- PLANT greys out rather than disappearing: the player still learns which
		-- button it will be.
		placeHint.word.TextTransparency = if valid then 0 else 0.55
		placeHint.glyph.ImageTransparency = if valid then 0 else 0.55
	end
	if reason ~= padReason then
		padReason = reason
		-- The full-plot variants all read "Your plot is full." (ActionRefusal.Text).
		local words = if reason then (PAD_REASON[reason] or ActionRefusal.Text[reason]) else nil
		reasonLabel.Text = words or ""
		reasonLabel.Visible = words ~= nil
	end
end

local function padAim(): Vector2?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local size = camera.ViewportSize
	return Vector2.new(size.X * 0.5, size.Y * 0.5)
end

-- A neighbour's plot, so the reticle can say so rather than "aim at your bed".
-- The plot is flat -- every part of it is a direct child of the plot model.
local function onSomebodyElsesPlot(struck: Instance): boolean
	local parent = struck.Parent
	return parent ~= nil and parent:IsA("Model")
		and CollectionService:HasTag(parent, GameConfig.Tags.Plot)
		and parent:GetAttribute(ATTR.OwnerUserId) ~= player.UserId
end

-- PlaceAt's own capacity rule, read off the same replicated attributes.
local function capacityOf(plot: Model): number
	local cap = tonumber(plot:GetAttribute("Capacity"))
	if cap and cap == cap and cap > 0 then
		return math.floor(cap)
	end
	return GameConfig.plotCapacityForTier(tonumber(plot:GetAttribute("Level")))
end

local function plantedIn(plot: Model): number
	local folder = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if not folder then
		return 0
	end
	local n = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			n += 1
		end
	end
	return n
end

-- Why the server would refuse a plant at `landing`, in PlaceAt's order, or nil.
-- A preview of the answer, never the answer: the server checks it all again.
local function placeRefusal(landing: Vector3): string?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart")
		and (landing - root.Position).Magnitude > PLANTING.RangeStuds then
		return "PLANT_OUT_OF_RANGE"
	end
	local plot = myPlot()
	if plot and plantedIn(plot) >= capacityOf(plot) then
		-- Which next step the toast names, as the server picks it: a grown
		-- plant is the one carrying a pick-up anchor, and the plot's Level says
		-- whether an upgrade is left (ActionRefusal.plotFull).
		local runtime = plot:FindFirstChild(GameConfig.Plot.RuntimeFolderName)
		local anchors = if runtime then runtime:FindFirstChild(GameConfig.Plot.PickupAnchorsFolderName) else nil
		local level = tonumber(plot:GetAttribute("Level")) or GameConfig.StartingPlotTier
		return ActionRefusal.plotFull(level < #GameConfig.PlotTiers,
			anchors ~= nil and #anchors:GetChildren() > 0)
	end
	return nil
end

-- A UI press is not a world press: a panel is up, or the player is steering a
-- selection through the HUD.
local function uiHasTheButtons(): boolean
	return PadInput.panelOpen() or GuiService.SelectedObject ~= nil
end

local PAD_PLACE_ACTION = "SeedPadPlant"
local PAD_AWAY_ACTION = "SeedPadPutAway"
local padBound = false

local function padPlant(_name: string, state: Enum.UserInputState): Enum.ContextActionResult?
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if uiHasTheButtons() or not heldTool() then
		return Enum.ContextActionResult.Pass
	end
	local point, soil = soilPoint(padAim())
	if not (point and soil) then
		-- The reticle already says where to aim; nothing to send.
		return Enum.ContextActionResult.Sink
	end
	local refusal = placeRefusal(landingOf(point, soil).Position)
	if refusal then
		-- The same toast the server's refusal would raise, without the round trip.
		ActionRefusal.raise(refusal)
		return Enum.ContextActionResult.Sink
	end
	channel:FireServer(PLANTING.PlaceAction, point)
	return Enum.ContextActionResult.Sink
end

local function padPutAway(name: string, state: Enum.UserInputState): Enum.ContextActionResult?
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if uiHasTheButtons() then
		return Enum.ContextActionResult.Pass
	end
	return unequip(name, state)
end

local function setPadBound(want: boolean)
	if want == padBound then
		return
	end
	padBound = want
	if want then
		-- Above the engine's own RT-activates-the-tool, so planting is the whole
		-- of what the trigger does while a plant is in the hands.
		ContextActionService:BindActionAtPriority(PAD_PLACE_ACTION, padPlant, false,
			Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR2)
		ContextActionService:BindActionAtPriority(PAD_AWAY_ACTION, padPutAway, false,
			Enum.ContextActionPriority.Medium.Value, Enum.KeyCode.ButtonB)
	else
		ContextActionService:UnbindAction(PAD_PLACE_ACTION)
		ContextActionService:UnbindAction(PAD_AWAY_ACTION)
	end
end

player.CharacterRemoving:Connect(function()
	hideGhost()
	setBound(false)
	setPadBound(false)
	showPad(false)
end)

RunService.RenderStepped:Connect(function()
	local tool = heldTool()
	setBound(tool ~= nil)
	-- On a controller with a panel up, the panel has the buttons and the world
	-- shows nothing: no disc behind it, no reticle over it. The same while the
	-- selection is out on the HUD: RT and B are the UI's then, and a reticle
	-- still offering "RT PLANT" would be offering a press that does nothing.
	local pad = tool ~= nil and PadInput.active()
	if pad and uiHasTheButtons() then
		setPadBound(false)
		showPad(false)
		hideGhost()
		return
	end
	setPadBound(pad)
	if not tool then
		hideGhost()
		showPad(false)
		return
	end
	local species = SeedData.Get(tostring(tool:GetAttribute("SpeciesId")))
	if not species then
		hideGhost()
		showPad(false)
		return
	end
	local point, soil, struck = soilPoint(if pad then padAim() else nil)
	if not (point and soil) then
		hideGhost()
		if pad then
			showPad(true, false, if struck and onSomebodyElsesPlot(struck) then "NOT_YOURS" else "AIM")
		else
			showPad(false)
		end
		return
	end

	local tier = math.clamp(
		tonumber(tool:GetAttribute(ATTR.CarryingKg)) or species.Tier,
		1, SeedData.TierCount)
	local on = landingOf(point, soil)

	-- The one base circle, never resized: only where it lies and its tint change.
	-- A cylinder's height runs along its X axis, so it has to be tipped on its
	-- side to lie flat on the soil.
	ghost.CFrame = on * CFrame.Angles(0, 0, math.rad(90))
	ghost.Color = PlantInfo.SizeColour(species.Id, tier)
	ghost.Transparency = 0.72

	if pad then
		local refusal = placeRefusal(on.Position)
		showPad(true, refusal == nil, refusal)
	else
		showPad(false)
	end
end)

--==============================================================================
-- THE CLICK
--
-- gameProcessedEvent is what keeps a tap on the Shop panel from planting the
-- pod behind it. The server does the deciding; this only ever asks.
--==============================================================================
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not heldTool() then
		return
	end
	local point = soilPoint()
	if not point then
		return
	end
	channel:FireServer(PLANTING.PlaceAction, point)
end)
