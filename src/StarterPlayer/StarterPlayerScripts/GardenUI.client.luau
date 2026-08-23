--!strict
-- Steal a Seed :: GardenUI
--
-- The right rail. What is in YOUR dirt, right now, one row per slot.
--
--==============================================================================
-- THE SHAPE IS THE CLIP'S ACTIVE LIST. THE CONTENT IS NOT.
--
-- At 0:58 of the reference recording the owner opens a right-docked panel: tall,
-- a collapse chevron on its inner edge, a `7/9 Active` header, one row per
-- occupant with a square thumbnail and a name and a rate, and a fat button at
-- the bottom. That SHAPE is what this borrows.
--
-- What it does not borrow is the idea underneath it. That panel is a LOADOUT --
-- nine slots, seven equipped, UNEQUIP and Equip Best and +1 EQUIP for $75M. This
-- game has no loadout. Plants go in the ground and stay there; there is nothing
-- to equip, nothing to bench, and nothing to buy a tenth slot for.
--
-- So the count means something different and better: `GARDEN 3/12` is three
-- things planted in twelve holes of actual dirt, and the empty rows are real
-- empty slots you can walk over and fill. The clip's 7/9 is inventory
-- management; this is a window onto a place.
--
-- Deliberately absent, all of it in the recording: UNEQUIP, Equip Best,
-- +1 EQUIP, Grow All, place-from-menu, sell, drag, wood-plank texture, paw and
-- egg icons.
--
--==============================================================================
-- WHY THIS IS NOT THE INDEX
--
-- Two panels, two jobs, and opening one does not close the other:
--
--   Index    (left)   every species in the biome, ??? until you have grown it.
--                     An almanac. It does not change while you watch it.
--   Garden   (right)  the twelve holes in front of you and what is in them
--                     this second, with the clocks still running.
--
-- The Index used to carry a one-line `Nubkin x2  Petalpip x1` footer, which was
-- a stopgap for exactly this panel. It is gone now that the real thing exists.
--
--==============================================================================
-- NO REMOTE, NO SERVER CALL
--
-- Everything on this panel is read off the plants themselves. PlantService tags
-- every model it renders and stamps SpeciesId, Stage, PlantedAt and SlotIndex on
-- it, and PlotService stamps the owner on the plot -- so the tag plus two
-- parents is the whole query. It cannot disagree with what is standing in the
-- ground, because it IS what is standing in the ground.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant

-- The same vocabulary as IndexUI, PromptUI, PlantUI and CashUI.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
local GHOST = Color3.fromRGB(120, 116, 124)
-- Red, for the same reason IndexUI's badge is red: it has to be the thing your
-- eye finds before you have decided to look at anything.
local BADGE = Color3.fromRGB(226, 76, 76)

local PANEL_WIDTH = 276
-- Mirrors IndexUI exactly: its button is at y = 12 and 46 tall, and its panel
-- hangs ten pixels under that. Two rails at the same height read as a pair.
local PANEL_TOP = 68
local SLIDE = 0.22
local BUTTON = 46

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedGarden")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedGarden"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency
	s.Parent = parent
end

--==============================================================================
-- THE BUTTON
--
-- Square and top-right, mirroring the Index button's 12px inset on the left. The
-- clip hangs an egg and a paw down that edge and a moon timer in the corner; we
-- have one button and nothing under it.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "GardenButton"
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -12, 0, 12)
button.Size = UDim2.fromOffset(BUTTON, BUTTON)
button.BackgroundColor3 = INK
button.BackgroundTransparency = 0.15
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Text = ""
button.Parent = gui
corner(button, 12)
stroke(button, ACCENT, 2, 0.35)

--==============================================================================
-- A SPROUT MADE OF RECTANGLES
--
-- Not a paw, not an egg, and not a glyph. Most of Gotham's symbol range renders
-- as tofu boxes in this engine -- SpeedFX paid for that with a trainer emoji and
-- IndexUI's book is drawn the same way. A stem and two rotated leaves is a
-- sprout on every device.
--==============================================================================
local sprout = Instance.new("Frame")
sprout.Name = "Sprout"
sprout.AnchorPoint = Vector2.new(0.5, 0.5)
sprout.Position = UDim2.fromScale(0.5, 0.5)
sprout.Size = UDim2.fromOffset(24, 24)
sprout.BackgroundTransparency = 1
sprout.Parent = button

local stem = Instance.new("Frame")
stem.Name = "Stem"
stem.AnchorPoint = Vector2.new(0.5, 1)
stem.Position = UDim2.new(0.5, 0, 1, 0)
stem.Size = UDim2.fromOffset(3, 15)
stem.BackgroundColor3 = ACCENT
stem.BorderSizePixel = 0
stem.Parent = sprout
corner(stem, 2)

for _, side in ipairs({ -1, 1 }) do
	local leaf = Instance.new("Frame")
	leaf.Name = if side < 0 then "LeafLeft" else "LeafRight"
	leaf.AnchorPoint = Vector2.new(0.5, 0.5)
	leaf.Position = UDim2.new(0.5, side * 6, 0, 8)
	leaf.Size = UDim2.fromOffset(12, 8)
	leaf.Rotation = side * 26
	leaf.BackgroundColor3 = ACCENT
	leaf.BorderSizePixel = 0
	leaf.Parent = sprout
	corner(leaf, 4)
end

--==============================================================================
-- THE BADGE COUNTS WHAT IS STILL COOKING
--
-- Hatching and growing plants only. A grown one does not badge: it is already
-- announcing itself in the world with a `+$N` popping off it every second, and a
-- badge that never clears is a badge you stop reading.
--
-- On the button's LEFT corner, not its right -- the button is already against
-- the right edge of the screen and a badge hung off that corner would be half
-- off it.
--==============================================================================
local badge = Instance.new("Frame")
badge.Name = "Badge"
badge.AnchorPoint = Vector2.new(0.5, 0.5)
badge.Position = UDim2.new(0, 0, 0, 0)
badge.Size = UDim2.fromOffset(24, 24)
badge.BackgroundColor3 = BADGE
badge.BorderSizePixel = 0
badge.Visible = false
badge.Parent = button
corner(badge, 12)
stroke(badge, INK, 2, 0.2)

local badgeLabel = Instance.new("TextLabel")
badgeLabel.Name = "Count"
badgeLabel.Size = UDim2.fromScale(1, 1)
badgeLabel.BackgroundTransparency = 1
badgeLabel.Font = Enum.Font.GothamBlack
badgeLabel.TextSize = 14
badgeLabel.TextColor3 = PAPER
badgeLabel.Text = ""
badgeLabel.Parent = badge

--==============================================================================
-- THE PANEL
--==============================================================================
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, PANEL_WIDTH + 24, 0, PANEL_TOP)
panel.Size = UDim2.new(0, PANEL_WIDTH, 1, -(PANEL_TOP + 12))
panel.BackgroundColor3 = INK
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 14)
stroke(panel, ACCENT, 2, 0.3)

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(PANEL_WIDTH, 260)
panelSize.MaxSize = Vector2.new(PANEL_WIDTH, 560)
panelSize.Parent = panel

local panelPad = Instance.new("UIPadding")
panelPad.PaddingLeft = UDim.new(0, 12)
panelPad.PaddingRight = UDim.new(0, 12)
panelPad.PaddingTop = UDim.new(0, 10)
panelPad.PaddingBottom = UDim.new(0, 10)
panelPad.Parent = panel

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 24)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack
header.TextSize = 17
header.TextColor3 = PAPER
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "GARDEN"
header.Parent = panel

--==============================================================================
-- THE COLLAPSE CHEVRON, ON THE INNER EDGE
--
-- Which for a right-docked panel is its LEFT edge, and the clip hangs it there
-- as a tab sticking out past the corner rather than as an X tucked inside. `>`
-- rather than an arrow glyph: the rotation arrows in this font are tofu, and
-- that is checked, not assumed.
--==============================================================================
local chevron = Instance.new("TextButton")
chevron.Name = "Collapse"
chevron.AnchorPoint = Vector2.new(1, 0.5)
chevron.Position = UDim2.new(0, -6, 0.5, 0)
chevron.Size = UDim2.fromOffset(22, 44)
chevron.BackgroundColor3 = INK
chevron.BackgroundTransparency = 0.08
chevron.BorderSizePixel = 0
chevron.AutoButtonColor = false
chevron.Font = Enum.Font.GothamBlack
chevron.TextSize = 16
chevron.TextColor3 = ACCENT
chevron.Text = ">"
chevron.Parent = panel
corner(chevron, 8)
stroke(chevron, ACCENT, 2, 0.35)

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Position = UDim2.fromOffset(0, 32)
list.Size = UDim2.new(1, 0, 1, -66)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = ACCENT
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel

local rows = Instance.new("UIListLayout")
rows.FillDirection = Enum.FillDirection.Vertical
rows.SortOrder = Enum.SortOrder.LayoutOrder
rows.Padding = UDim.new(0, 5)
rows.Parent = list

--==============================================================================
-- THE FOOTER IS A NUMBER, NOT A BUTTON
--
-- The clip's fat footer is `Equip Best`. There is nothing to equip, so the space
-- goes to the one number the panel is otherwise not saying out loud: what this
-- plot earns per second, all its grown plants added up.
--
-- Summed on the client from the same tagged models EconomyService pays from --
-- no remote, no second faucet. It is a readout of the server's arithmetic, not
-- a second copy of it.
--
-- Empty rather than `$0/s` when nothing has finished. Zero is a number; nothing
-- growing yet is an absence, and printing the first as the second makes a new
-- plot look broken.
--==============================================================================
local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 28)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamBlack
footer.TextSize = 18
footer.TextColor3 = ACCENT
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.TextYAlignment = Enum.TextYAlignment.Center
footer.Text = ""
footer.Parent = panel

--==============================================================================
-- ROWS
--
-- Pooled and refilled, never rebuilt. A tier-4 plot is thirty of these and the
-- panel refreshes once a second while open; rebuilding thirty frames a second
-- on a phone is the kind of thing that makes a menu feel cheap.
--==============================================================================
type Row = {
	frame: Frame,
	swatch: Frame,
	name: TextLabel,
	sub: TextLabel,
}

local pool: { Row } = {}

local function buildRow(index: number): Row
	local frame = Instance.new("Frame")
	frame.Name = "Slot" .. index
	frame.LayoutOrder = index
	frame.Size = UDim2.new(1, -6, 0, 44)
	frame.BackgroundColor3 = PAPER
	frame.BackgroundTransparency = 0.9
	frame.BorderSizePixel = 0
	frame.Parent = list
	corner(frame, 10)

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Position = UDim2.fromOffset(8, 8)
	swatch.Size = UDim2.fromOffset(28, 28)
	swatch.BorderSizePixel = 0
	swatch.Parent = frame
	corner(swatch, 8)

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(46, 5)
	name.Size = UDim2.new(1, -56, 0, 18)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextColor3 = PAPER
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = ""
	name.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.fromOffset(46, 23)
	sub.Size = UDim2.new(1, -56, 0, 16)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 13
	sub.TextColor3 = GHOST
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = ""
	sub.Parent = frame

	local row: Row = { frame = frame, swatch = swatch, name = name, sub = sub }
	pool[index] = row
	return row
end

local function rowAt(index: number): Row
	return pool[index] or buildRow(index)
end

--==============================================================================
-- READING THE DIRT
--==============================================================================
local function serverNow(): number
	-- pcall because GetServerTimeNow throws while the client is still syncing,
	-- which is exactly when this first runs. Same guard PlantUI uses.
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.time()
end

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
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

type Occupant = {
	species: SeedData.Species,
	plantedAt: number,
}

-- Everything of ours in the ground, keyed by the slot it is standing in.
local function occupants(plot: Model): { [number]: Occupant }
	local out: { [number]: Occupant } = {}
	local plants = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if not plants then
		return out
	end
	for _, model in ipairs(plants:GetChildren()) do
		if model:IsA("Model") and CollectionService:HasTag(model, GameConfig.Tags.Planted) then
			local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
			local plantedAt = model:GetAttribute("PlantedAt")
			local slot = model:GetAttribute("SlotIndex")
			if species and type(plantedAt) == "number" and type(slot) == "number" then
				out[slot] = { species = species, plantedAt = plantedAt }
			end
		end
	end
	return out
end

--==============================================================================
-- STAGE COMES FROM THE CLOCK, NOT THE ATTRIBUTE
--
-- PlantUI decides HATCHING / GROWING / done from PlantedAt and GrowSeconds, and
-- this does the identical sum -- so a row and the plate over the plant it names
-- can never show different clocks. Branching on the Stage attribute instead
-- would be authoritative but would disagree with the world for up to a tick,
-- and two numbers disagreeing on screen is worse than one being a second early.
--
-- The footer therefore leads EconomyService by at most one tick on the frame a
-- plant finishes. It is a display of a number that is changing anyway.
--==============================================================================
local STAGE_POD, STAGE_SPROUT, STAGE_GROWN = 1, 2, 3

local function stageOf(occupant: Occupant, now: number): (number, number)
	local total = SeedData.GrowSeconds(occupant.species)
	local elapsed = now - occupant.plantedAt
	local sproutAt = total * PLANTING.SproutAt
	if elapsed < sproutAt then
		return STAGE_POD, sproutAt - elapsed
	elseif elapsed < total then
		return STAGE_SPROUT, total - elapsed
	end
	return STAGE_GROWN, 0
end

--==============================================================================
-- HOW MANY HOLES
--==============================================================================
local plotTier = GameConfig.StartingPlotTier

local function slotCount(): number
	local tier = GameConfig.PlotTiers[math.clamp(plotTier, 1, #GameConfig.PlotTiers)]
	-- Never a hardcoded 12. A starting plot is 4 rows of BedColumns, and every
	-- tier after it is a different number of rows through the same function
	-- MapService builds the bed with.
	return GameConfig.plotSlotsFor(if tier then tier.rows else GameConfig.PlotTiers[1].rows)
end

--==============================================================================
-- PAINTING
--==============================================================================
local shownRows = 0
local open = false

local function setRowCount(n: number)
	for i = 1, math.max(n, shownRows) do
		local row = pool[i]
		if i <= n then
			row = rowAt(i)
			row.frame.Visible = true
		elseif row then
			row.frame.Visible = false
		end
	end
	shownRows = n
end

local function refresh(paint: boolean)
	local plot = myPlot()
	local now = serverNow()

	--== NO PLOT: the overflow queue still gets a panel that opens ==--
	if not plot then
		badge.Visible = false
		if not paint then
			return
		end
		header.Text = "GARDEN  —"
		footer.Text = ""
		setRowCount(1)
		local row = rowAt(1)
		row.swatch.BackgroundColor3 = PAPER
		row.swatch.BackgroundTransparency = 0.85
		row.name.Text = "No plot this server"
		row.name.TextColor3 = GHOST
		row.sub.Text = ""
		return
	end

	local here = occupants(plot)
	local slots = slotCount()
	local planted, waiting, rate = 0, 0, 0

	if paint then
		setRowCount(slots)
	end

	for index = 1, slots do
		local occupant = here[index]
		if occupant then
			planted += 1
			local stage, remaining = stageOf(occupant, now)
			if stage == STAGE_GROWN then
				rate += SeedData.IncomePerSecond(occupant.species)
			else
				waiting += 1
			end

			if paint then
				local row = rowAt(index)
				local species = occupant.species
				--==========================================================
				-- CROWN, NOT BODY
				--
				-- Body would put two identical cream squares next to each
				-- other for Toadcap and Bellchime, and two identical green
				-- ones for Nubkin and Petalpip -- four of five species
				-- reading as two. Crown is the cap, the petals or the buds,
				-- and across Greenhollow it is green / cream / pale green /
				-- red / pink: five distinguishable 28px squares.
				--
				-- While it is a POD the swatch is the RARITY colour instead,
				-- because that is genuinely what the thing in the ground
				-- looks like from across the plot, and the species is not
				-- supposed to be known yet.
				--==========================================================
				row.swatch.BackgroundTransparency = 0
				row.swatch.BackgroundColor3 = if stage == STAGE_POD
					then SeedData.PodColor(species)
					else species.Crown
				--==========================================================
				-- A POD IS NOT NAMED, HERE EITHER
				--
				-- This printed the species name at every stage and only ghosted
				-- its COLOUR while it waited, which spent the reveal in a list
				-- and made the whole pod-colour design pointless: two Commons
				-- are meant to arrive in identical shells so you cannot tell
				-- which one you got until it opens, and the Garden was simply
				-- telling you.
				--
				-- A SPROUT is named, though. By then the model in the ground is
				-- the creature at SPROUT_SCALE -- the shape is out there being
				-- looked at -- so withholding the word would be hiding
				-- something the world has already shown.
				--==========================================================
				row.name.Text = if stage == STAGE_POD then "???" else species.Name
				if stage == STAGE_GROWN then
					row.name.TextColor3 = GameConfig.RarityColor[species.Rarity] or PAPER
					row.sub.Text = "$" .. GameConfig.compact(
						SeedData.IncomePerSecond(species)) .. "/s"
					row.sub.TextColor3 = ACCENT
				else
					-- Ghosted until it finishes, so the reveal still happens
					-- out in the world rather than in a list.
					row.name.TextColor3 = GHOST
					row.sub.Text = (if stage == STAGE_POD then "HATCHING " else "GROWING ")
						.. clock(remaining)
					row.sub.TextColor3 = GHOST
				end
			end
		elseif paint then
			local row = rowAt(index)
			row.swatch.BackgroundColor3 = PAPER
			row.swatch.BackgroundTransparency = 0.88
			row.name.Text = "Empty"
			row.name.TextColor3 = GHOST
			row.sub.Text = ""
			row.sub.TextColor3 = GHOST
		end
	end

	badge.Visible = waiting > 0
	badgeLabel.Text = tostring(waiting)

	if paint then
		header.Text = string.format("GARDEN  %d/%d", planted, slots)
		footer.Text = if rate > 0 then "$" .. GameConfig.compact(rate) .. "/s" else ""
	end
end

--==============================================================================
-- THE PROFILE, FOR THE TIER ONLY
--
-- No Almanac writes from this file, and nothing here is trusted with cash. The
-- one field it wants is PlotTier, because that is how many holes there are.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.PlotTier) ~= "number" then
		return
	end
	local tier = math.floor(profile.PlotTier)
	if tier ~= plotTier then
		plotTier = tier
		refresh(open)
	end
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	-- WaitForChild, not FindFirstChild: the folder replicates before the events
	-- inside it, which is how CashUI once sat blank for a whole session.
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	else
		warn("[Seed/GardenUI] No ProfileUpdated; the garden will assume a starting plot.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

--==============================================================================
-- OPEN AND SHUT
--
-- Nothing here touches the Index. They dock on opposite rails and answer
-- different questions, and closing one to open the other would mean you cannot
-- check what a species is worth while looking at your own row for it.
--==============================================================================
local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		refresh(true)
		panel.Visible = true
		panel.Position = UDim2.new(1, PANEL_WIDTH + 24, 0, PANEL_TOP)
		TweenService:Create(panel, TweenInfo.new(SLIDE, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Position = UDim2.new(1, -12, 0, PANEL_TOP) }):Play()
	else
		local slideOut = TweenService:Create(panel, TweenInfo.new(SLIDE,
			Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, PANEL_WIDTH + 24, 0, PANEL_TOP) })
		slideOut:Play()
		slideOut.Completed:Connect(function()
			if not open then
				panel.Visible = false
			end
		end)
	end
end

button.Activated:Connect(function()
	setOpen(not open)
end)
chevron.Activated:Connect(function()
	setOpen(false)
end)

--==============================================================================
-- KEEPING UP
--
-- Once a second for the clocks, and immediately on a tag arriving or leaving.
-- PlantService destroys and rebuilds a model at every stage change, so without
-- the tag signals a row would sit on HATCHING for up to a second after the thing
-- it names had already become a sprout.
--
-- The BADGE is refreshed on the same tick whether the panel is open or not --
-- that is the whole point of a badge -- but the rows are only painted when
-- somebody is looking at them.
--==============================================================================
local since = 0

RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since < PLANTING.TickSeconds then
		return
	end
	since = 0
	refresh(open)
end)

local function onTagChanged()
	refresh(open)
end

CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(onTagChanged)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(onTagChanged)

refresh(false)
