--!strict
-- Steal a Seed :: IndexUI
--
-- The left rail. One button, and the panel it opens: what Greenhollow has, and
-- which of it you have actually grown.
--
-- The ALMANAC, and only that. What is in your dirt right now is GardenUI, on the
-- right rail.
--
--==============================================================================
-- ONE BUTTON. NOT A RAIL OF THEM.
--
-- The reference clip stacks Shop above Index, and everything else it hangs off
-- the edges -- Rebirth, Growing Eggs, Grow All, a paw, a hotbar, a moon timer,
-- Friend Boost, Robux packs. None of that is here and most of it never will be.
-- There is no shop, so there is no Shop button; an empty one is a promise the
-- game has not made.
--
--==============================================================================
-- THE RARITY WORD LIVES HERE
--
-- Nowhere in the world says it. A pod is COLOURED by rarity, so the word out
-- there would be a caption on a photograph -- and it would spend the reveal
-- early, since two Commons arrive in identical shells. A grown plant carries no
-- plate at all any more. The Garden panel tints a finished row's NAME with the
-- rarity colour, which is a hint rather than a statement.
--
-- So this is the one surface that spells Common / Uncommon / Rare / Epic out,
-- and it is also the only one that shows WEIGHT, and the only one that shows a
-- row for a species you have never grown.
--
--==============================================================================
-- SEEN MEANS GROWN, ON A PLOT YOU OWNED
--
-- Not carried, not stolen, not sprouted. Pods are coloured by rarity, so the two
-- Commons arrive identical and which one you got stays unknown until it
-- finishes -- the grow-up IS the reveal, and PlantService writes the Almanac at
-- exactly that moment. Filling a row in for a pod would spend the reveal before
-- it happened.
--
--==============================================================================
-- NO NEW REMOTE
--
-- Almanac rides down inside the profile that ProfileUpdated already pushes four
-- times a second, and ProfileReady announces the first one. Same rule CashUI and
-- SpeedFX follow.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- The same three PromptUI, PlantUI and CashUI use.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
-- Grey paper: an unseen row is present but not lit.
local GHOST = Color3.fromRGB(120, 116, 124)
--==============================================================================
-- THE BADGE IS RED, AND THAT IS DELIBERATE
--
-- It is the second thing in this game allowed outside ink / paper / accent --
-- SpeedFX's blue shoe is the first, for the same reason. A green badge on a
-- green-stroked button is a decoration; the whole job of this one is to be the
-- thing your eye goes to before you have decided to look at anything, and red is
-- what "there is something you have not seen" means everywhere else.
--==============================================================================
local BADGE = Color3.fromRGB(226, 76, 76)

--==============================================================================
-- GREENHOLLOW ONLY, AND THE DENOMINATOR IS COUNTED NOT TYPED
--
-- The other four biomes are geometry with no species in them yet -- NestService
-- says so at boot -- so an Index listing them would be four empty shelves. When
-- they get their art they get their rows, and `#SPECIES` picks that up without
-- anybody editing a header string.
--==============================================================================
local BIOME = "greenhollow"
local SPECIES = SeedData.InBiome(BIOME)

local PANEL_WIDTH = 268
-- Directly under the button: it sits at y = 12 and is 46 tall, so this leaves a
-- ten pixel gap. One constant, because the resting position, the size and both
-- ends of the slide all have to agree about it.
local PANEL_TOP = 68
local SLIDE = 0.22

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedIndex")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedIndex"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

--==============================================================================
-- SMALL BUILDERS
--==============================================================================
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
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "IndexButton"
button.Position = UDim2.new(0, 12, 0, 12)
button.Size = UDim2.fromOffset(152, 46)
button.BackgroundColor3 = INK
button.BackgroundTransparency = 0.15
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Text = ""
button.Parent = gui
corner(button, 12)
stroke(button, ACCENT, 2, 0.35)

--==============================================================================
-- A DOCUMENT MADE OF RECTANGLES
--
-- Not a glyph. Most of Gotham's symbol range renders as tofu boxes in this
-- engine -- SpeedFX already paid for that lesson with a trainer emoji, and its
-- shoe is drawn the same way. A book made of frames is a book on every device.
--==============================================================================
local icon = Instance.new("Frame")
icon.Name = "Icon"
icon.Position = UDim2.fromOffset(12, 11)
icon.Size = UDim2.fromOffset(20, 24)
icon.BackgroundColor3 = PAPER
icon.BorderSizePixel = 0
icon.Parent = button
corner(icon, 3)

local spine = Instance.new("Frame")
spine.Name = "Spine"
spine.Size = UDim2.fromOffset(5, 24)
spine.BackgroundColor3 = ACCENT
spine.BorderSizePixel = 0
spine.Parent = icon
corner(spine, 2)

for i = 1, 3 do
	local line = Instance.new("Frame")
	line.Name = "Line" .. i
	line.Position = UDim2.fromOffset(9, 4 + (i - 1) * 6)
	line.Size = UDim2.fromOffset(8, 2)
	line.BackgroundColor3 = INK
	line.BackgroundTransparency = 0.35
	line.BorderSizePixel = 0
	line.Parent = icon
end

local buttonLabel = Instance.new("TextLabel")
buttonLabel.Name = "Label"
buttonLabel.Position = UDim2.fromOffset(42, 0)
buttonLabel.Size = UDim2.new(1, -52, 1, 0)
buttonLabel.BackgroundTransparency = 1
buttonLabel.Font = Enum.Font.GothamBold
buttonLabel.TextSize = 18
buttonLabel.TextColor3 = PAPER
buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
buttonLabel.Text = "Index"
buttonLabel.Parent = button

local badge = Instance.new("Frame")
badge.Name = "Badge"
badge.AnchorPoint = Vector2.new(0.5, 0.5)
badge.Position = UDim2.new(1, 0, 0, 0)
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
panel.Position = UDim2.new(0, -PANEL_WIDTH - 24, 0, PANEL_TOP)
panel.Size = UDim2.new(0, PANEL_WIDTH, 1, -(PANEL_TOP + 12))
panel.BackgroundColor3 = INK
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 14)
stroke(panel, ACCENT, 2, 0.3)

local panelHeight = Instance.new("UISizeConstraint")
panelHeight.MinSize = Vector2.new(PANEL_WIDTH, 260)
panelHeight.MaxSize = Vector2.new(PANEL_WIDTH, 520)
panelHeight.Parent = panel

local panelPad = Instance.new("UIPadding")
panelPad.PaddingLeft = UDim.new(0, 12)
panelPad.PaddingRight = UDim.new(0, 12)
panelPad.PaddingTop = UDim.new(0, 10)
panelPad.PaddingBottom = UDim.new(0, 10)
panelPad.Parent = panel

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -30, 0, 24)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBlack
header.TextSize = 17
header.TextColor3 = PAPER
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "INDEX"
header.Parent = panel

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, 0, 0, 0)
close.Size = UDim2.fromOffset(26, 26)
close.BackgroundColor3 = PAPER
close.BackgroundTransparency = 0.85
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.TextColor3 = PAPER
close.Text = "X"
close.Parent = panel
corner(close, 8)

--== THE ROWS ==--
local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Position = UDim2.fromOffset(0, 32)
-- Full height under the header now that nothing is pinned to the bottom.
list.Size = UDim2.new(1, 0, 1, -36)
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
rows.Padding = UDim.new(0, 6)
rows.Parent = list

--==============================================================================
-- THE PLOT FOOTER IS GONE. GardenUI IS WHAT IT WAS STANDING IN FOR.
--
-- There was a one-line `Nubkin x2  Petalpip x1` along the bottom of this panel,
-- added because "see what you are running" had nowhere else to live. It now has
-- somewhere else to live: a right-docked panel with a row per SLOT, the clocks
-- still ticking, and the empty holes shown as empty.
--
-- A count of species was never the right shape for that question anyway -- it
-- could tell you that you had two Nubkins and could not tell you that seven of
-- your twelve holes were empty.
--
-- This panel goes back to being one thing: the almanac.
--==============================================================================
-- ONE ROW PER SPECIES, BUILT ONCE
--
-- The rows never change shape, only their contents, so they are built at start
-- and refilled. Rebuilding five frames every time a profile packet lands -- four
-- times a second -- would be four rebuilds a second of a panel nobody has open.
--==============================================================================
type Row = {
	swatch: Frame,
	name: TextLabel,
	sub: TextLabel,
	rate: TextLabel,
}

local built: { [string]: Row } = {}

for index, species in ipairs(SPECIES) do
	local row = Instance.new("Frame")
	row.Name = species.Id
	row.LayoutOrder = index
	row.Size = UDim2.new(1, -6, 0, 46)
	row.BackgroundColor3 = PAPER
	row.BackgroundTransparency = 0.9
	row.BorderSizePixel = 0
	row.Parent = list
	corner(row, 10)

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Position = UDim2.fromOffset(8, 9)
	swatch.Size = UDim2.fromOffset(28, 28)
	swatch.BorderSizePixel = 0
	swatch.Parent = row
	corner(swatch, 8)

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(46, 6)
	name.Size = UDim2.new(1, -110, 0, 19)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 15
	name.TextColor3 = PAPER
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = ""
	name.Parent = row

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.fromOffset(46, 24)
	sub.Size = UDim2.new(1, -110, 0, 16)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 12
	sub.TextColor3 = GHOST
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = ""
	sub.Parent = row

	local rate = Instance.new("TextLabel")
	rate.Name = "Rate"
	rate.AnchorPoint = Vector2.new(1, 0.5)
	rate.Position = UDim2.new(1, -10, 0.5, 0)
	rate.Size = UDim2.fromOffset(64, 22)
	rate.BackgroundTransparency = 1
	rate.Font = Enum.Font.GothamBlack
	rate.TextSize = 15
	rate.TextColor3 = ACCENT
	rate.TextXAlignment = Enum.TextXAlignment.Right
	rate.Text = ""
	rate.Parent = row

	built[species.Id] = { swatch = swatch, name = name, sub = sub, rate = rate }
end

--==============================================================================
-- FILLING IT IN
--==============================================================================
local almanac: { [string]: boolean } = {}

local function paint()
	local seen = 0
	for _, species in ipairs(SPECIES) do
		local row = built[species.Id]
		if row then
			if almanac[species.Id] then
				seen += 1
				row.swatch.BackgroundColor3 = SeedData.PodColor(species)
				row.swatch.BackgroundTransparency = 0
				row.name.Text = species.Name
				row.name.TextColor3 = PAPER
				row.sub.Text = string.format("%s  ·  %s kg", species.Rarity,
					GameConfig.compact(species.Kg))
				row.sub.TextColor3 = GameConfig.RarityColor[species.Rarity] or GHOST
				row.rate.Text = "$" .. GameConfig.compact(SeedData.IncomePerSecond(species)) .. "/s"
			else
				-- A silhouette: the row is the right shape and the swatch is the
				-- right size, so you can see there IS a fifth thing without
				-- being told what it earns. No rate and no weight -- those are
				-- the reward for growing one.
				row.swatch.BackgroundColor3 = PAPER
				row.swatch.BackgroundTransparency = 0.82
				row.name.Text = "???"
				row.name.TextColor3 = GHOST
				row.sub.Text = "Undiscovered"
				row.sub.TextColor3 = GHOST
				row.rate.Text = ""
			end
		end
	end

	header.Text = string.format("INDEX  %d/%d", seen, #SPECIES)

	local missing = #SPECIES - seen
	badge.Visible = missing > 0
	badgeLabel.Text = tostring(missing)
end

paint()

--==============================================================================
-- THE PROFILE
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local incoming = profile.Almanac
	if type(incoming) ~= "table" then
		return
	end
	local changed = false
	for id, value in pairs(incoming) do
		if value == true and type(id) == "string" and not almanac[id] then
			almanac[id] = true
			changed = true
		end
	end
	if changed then
		paint()
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
		warn("[Seed/IndexUI] No ProfileUpdated; the Index will stay unfilled.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
else
	warn("[Seed/IndexUI] No Remotes folder; the Index will stay unfilled.")
end

--==============================================================================
-- OPEN AND SHUT
--
-- Nothing here touches the Garden. They dock on opposite rails and answer
-- different questions -- what a species is worth, and what is in your dirt --
-- and closing one to open the other would mean you cannot read the first while
-- looking at the second.
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		panel.Visible = true
		panel.Position = UDim2.new(0, -PANEL_WIDTH - 24, 0, PANEL_TOP)
		TweenService:Create(panel, TweenInfo.new(SLIDE, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Position = UDim2.new(0, 12, 0, PANEL_TOP) }):Play()
	else
		local slideOut = TweenService:Create(panel, TweenInfo.new(SLIDE,
			Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0, -PANEL_WIDTH - 24, 0, PANEL_TOP) })
		slideOut:Play()
		slideOut.Completed:Connect(function()
			-- Only if nothing re-opened it during the slide.
			if not open then
				panel.Visible = false
			end
		end)
	end
end

button.Activated:Connect(function()
	setOpen(not open)
end)
close.Activated:Connect(function()
	setOpen(false)
end)

-- No tick. Nothing on this panel changes on its own: the almanac only moves when
-- a profile packet says a species has been discovered, and `receive` repaints
-- on that. GardenUI is the one with clocks to keep.
