--!strict
-- Steal a Seed :: GardenUI
--
-- What is in YOUR dirt, right now, one row per slot. Its button is top-right;
-- the panel opens in the middle of the screen.
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
-- Two panels, two jobs:
--
--   Index    every species in the biome, ??? until you have grown it. An
--            almanac, and it does not change while you watch it.
--   Garden   the twelve holes in front of you and what is in them this second,
--            with the clocks still running.
--
-- They used to be allowed open at once, because one docked left and the other
-- docked right. Both open in the CENTRE now, so they take turns -- see OPEN AND
-- SHUT. What that costs is the side-by-side read; what it buys is one panel
-- shape instead of two and a phone screen that is not half panel.
--
-- The Index used to carry a one-line `Nubkin x2  Petalpip x1` footer, which was
-- a stopgap for exactly this panel. It is gone now that the real thing exists.
--
--==============================================================================
-- NO REMOTE, NO SERVER CALL
--
-- Everything on this panel is read off the plants themselves. PlantService tags
-- every model it renders and stamps SpeciesId, Stage, Kg, PlantedAt and
-- PlacementId on it, and PlotService stamps the owner on the plot -- so the tag
-- plus two
-- parents is the whole query. It cannot disagree with what is standing in the
-- ground, because it IS what is standing in the ground.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant
local PANEL_NAME = "Garden"

-- The same vocabulary as PromptUI, PlantUI and CashUI.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
local GHOST = Color3.fromRGB(120, 116, 124)

--==============================================================================
-- IT OPENS IN THE MIDDLE NOW, NOT OFF THE RIGHT EDGE
--
-- This docked on the right rail and the Index docked on the left, which is why
-- the two were allowed to be open at once. A modal has no side, so the argument
-- goes with it: all three panels share one rectangle and take turns. UIKit.modal
-- owns the geometry; this is only the cap it may grow to.
--==============================================================================
local MAX_WIDTH = 380
local MAX_HEIGHT = 560

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
--
-- Amber, so three buttons read as three things. There is no Garden button in the
-- owner's reference to crop even if cropping were still the plan, so this one
-- was always going to be drawn -- and now the other two are drawn beside it.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "GardenButton",
	face = RAIL.GardenFace,
	shade = RAIL.GardenShade,
	wide = false,
})
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -RAIL.Inset, 0, RAIL.Inset)

--==============================================================================
-- A SPROUT MADE OF RECTANGLES
--
-- Not a paw, not an egg, and not a glyph. Most of Gotham's symbol range renders
-- as tofu boxes in this engine, which is checked rather than assumed -- SpeedFX
-- paid for it with a trainer emoji. A stem and three leaves is a sprout on every
-- device.
--
-- In the BIOME'S stem and leaf, not the HUD's accent green. It is the only rail
-- icon that depicts something the game actually grows, so it may as well be the
-- colour the game grows it in.
--==============================================================================
UIKit.sproutIcon(button, 30, SeedData.Stem, SeedData.Leaf)

--==============================================================================
-- THE BADGE COUNTS WHAT IS STILL COOKING
--
-- Hatching plants only. A grown one does not badge: it is already announcing
-- itself in the world with a `+$N` popping off it every second, and a badge that
-- never clears is a badge you stop reading.
--
-- On the button's LEFT corner, not its right -- the button is already against
-- the right edge of the screen and a badge hung off that corner would be half
-- off it. Which is also why no slab clips its descendants.
--==============================================================================
local badge, badgeLabel = UIKit.badge(button, RAIL.Badge)
badge.Position = UDim2.new(0, 0, 0, 0)

--==============================================================================
-- THE PANEL
--
-- The collapse chevron is gone with the dock. It hung off the panel's inner edge
-- as a tab, which is a right-docked idea: a centred panel has no inner edge, and
-- the modal already carries the red X every other panel closes with.
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "GARDEN",
	maxWidth = MAX_WIDTH,
	maxHeight = MAX_HEIGHT,
})

local titleBar = modal.title.Parent :: Frame
UIKit.sproutIcon(titleBar, 30, SeedData.Stem, SeedData.Leaf).Position =
	UDim2.new(0, 24, 0.5, 0)
modal.title.Position = UDim2.new(0, 46, 0.5, 0)
modal.title.Size = UDim2.new(1, -98, 1, 0)

local header = modal.title

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(1, 0, 1, -32)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = ACCENT
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = 3
list.Parent = modal.body

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
local footer = UIKit.outlined(modal.body, "Footer", 19, ACCENT, 2.5)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 28)
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.TextYAlignment = Enum.TextYAlignment.Center
footer.ZIndex = 4

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
	frame.ZIndex = 3
	frame.Parent = list
	corner(frame, 10)

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Position = UDim2.fromOffset(8, 8)
	swatch.Size = UDim2.fromOffset(28, 28)
	swatch.BorderSizePixel = 0
	swatch.ZIndex = 4
	swatch.Parent = frame
	corner(swatch, 8)
	stroke(swatch, INK, 2, 0.35)

	local name = UIKit.outlined(frame, "Name", 15, PAPER, 2)
	name.Position = UDim2.fromOffset(46, 4)
	name.Size = UDim2.new(1, -56, 0, 19)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 4

	local sub = UIKit.outlined(frame, "Sub", 13, GHOST, 2)
	sub.Position = UDim2.fromOffset(46, 23)
	sub.Size = UDim2.new(1, -56, 0, 16)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.ZIndex = 4

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
	-- What THIS one weighs. Every row number that is not the name comes from
	-- here: the clock, the rate, and the colour the name is printed in. Two
	-- Nubkins in the same bed at 4 kg and 900 kg have to read as $4/s and
	-- $900/s, which they cannot if the sheet is consulted.
	kg: number,
	plantedAt: number,
	-- STAGE_POD or STAGE_GROWN, off the model. Not derived from the clock any
	-- more: a pod whose timer ran out an hour ago is STILL a pod until somebody
	-- hatches it, and a creature you placed a second ago is already grown.
	stage: number,
	-- Placement order, which is the only order there is now that plants do not
	-- live in numbered holes.
	id: number,
}

--==============================================================================
-- A LIST, NOT A GRID
--
-- This was keyed by slot index, and a row in the panel WAS slot N -- so an
-- empty row meant "hole N is free" and the panel was a map of the bed. There
-- are no holes any more; you put plants where you click.
--
-- So the rows are just what you own, in the order you planted it, and the empty
-- ones at the bottom are how much room is left. Same panel, and the number of
-- rows still equals the tier's capacity -- it has just stopped pretending to be
-- a floor plan.
--==============================================================================
local function occupants(plot: Model): { Occupant }
	local out: { Occupant } = {}
	local plants = plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if not plants then
		return out
	end
	for _, model in ipairs(plants:GetChildren()) do
		if model:IsA("Model") and CollectionService:HasTag(model, GameConfig.Tags.Planted) then
			local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
			local plantedAt = model:GetAttribute("PlantedAt")
			local kg = tonumber(model:GetAttribute("Kg"))
			local id = tonumber(model:GetAttribute("PlacementId"))
			local stage = tonumber(model:GetAttribute("Stage"))
			if species and kg and id and stage and type(plantedAt) == "number" then
				table.insert(out, {
					species = species,
					kg = kg,
					plantedAt = plantedAt,
					stage = stage,
					id = id,
				})
			end
		end
	end
	-- GetChildren is in creation order, which is close but not guaranteed, and a
	-- list that reshuffles itself between ticks would make the panel flicker.
	table.sort(out, function(a: Occupant, b: Occupant): boolean
		return a.id < b.id
	end)
	return out
end

--==============================================================================
-- WHAT IT IS COMES FROM THE SERVER; WHEN IT IS READY COMES FROM THE CLOCK
--
-- Those used to be one question and the clock answered both -- a plant's stage
-- WAS how far through its timer it was. Manual hatching split them: a pod whose
-- clock ran out an hour ago is still a pod, and the only thing that turns it
-- into a creature is somebody holding E. So the STAGE is read off the model and
-- the countdown is still computed here.
--
-- The countdown does the identical sum PlantUI does, so a row and the plate over
-- the plant it names can never show different clocks.
--
-- READY is a display state, not a server one -- there is no fourth stage. It is
-- simply a pod whose remaining time has reached zero, which is exactly when
-- PlantService hangs the prompt on it.
--==============================================================================
local STAGE_POD, STAGE_GROWN = 1, 3
local STAGE_READY = -1

local function stageOf(occupant: Occupant, now: number): (number, number)
	if occupant.stage ~= STAGE_POD then
		return STAGE_GROWN, 0
	end
	local remaining = SeedData.GrowSeconds(occupant.kg) - (now - occupant.plantedAt)
	if remaining > 0 then
		return STAGE_POD, remaining
	end
	return STAGE_READY, 0
end

--==============================================================================
-- HOW MANY THINGS FIT
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
				rate += SeedData.IncomePerSecond(occupant.kg)
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
				-- While it is a POD the swatch is the WEIGHT BAND instead,
				-- because that is genuinely what the thing in the ground
				-- looks like from across the plot -- the shell is coloured by
				-- what it weighs -- and the species is not supposed to be
				-- known yet.
				--==========================================================
				row.swatch.BackgroundTransparency = 0
				row.swatch.BackgroundColor3 = if stage == STAGE_GROWN
					then species.Crown
					else SeedData.ColorForKg(occupant.kg)
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
				-- A pod stays anonymous right up to the hatch, ready or not.
				-- The clock running out does not open the shell any more, so
				-- naming it at READY would spend the reveal on a timer -- which
				-- is the one thing manual hatching was meant to stop.
				--==========================================================
				row.name.Text = if stage == STAGE_GROWN then species.Name else "???"
				if stage == STAGE_GROWN then
					--======================================================
					-- TINTED BY WHAT IT WEIGHS, NOT BY WHAT SHAPE IT IS
					--
					-- The sheet's rarity is the FORM's drop rate now -- how
					-- often a cube turns up against a bell -- and it says
					-- nothing about the prize. Printing an 8,000 kg Nubkin
					-- in Common white would call the best thing in the
					-- garden ordinary.
					--======================================================
					row.name.TextColor3 = SeedData.ColorForKg(occupant.kg)
					row.sub.Text = "$" .. GameConfig.compact(
						SeedData.IncomePerSecond(occupant.kg)) .. "/s"
					row.sub.TextColor3 = ACCENT
				elseif stage == STAGE_READY then
					--======================================================
					-- THE ONE ROW THAT IS ASKING FOR SOMETHING
					--
					-- Everything else in this panel is a status. This is the
					-- only line that means GO AND DO SOMETHING, so it is the
					-- only ghosted row that lights up -- a full bed reads at a
					-- glance as "two of these want you".
					--
					-- Still ???: the name is the hatch's to give.
					--======================================================
					row.name.TextColor3 = SeedData.ColorForKg(occupant.kg)
					row.sub.Text = "READY  ·  HOLD E"
					row.sub.TextColor3 = ACCENT
				else
					-- Ghosted until it is hatched, so the reveal still happens
					-- out in the world rather than in a list.
					row.name.TextColor3 = GHOST
					row.sub.Text = "HATCHING " .. clock(remaining)
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
-- THE GARDEN IS IN THE MUTEX NOW. It used to be deliberately outside it: this
-- docked on the right rail, the Index and Shop docked on the left, and the whole
-- point of two rails was being able to read your own dirt while looking at a
-- price. A centred modal has no rail, so the three of them share one rectangle
-- and one at a time is the only arrangement left.
--
-- Each writes its own name to the OpenPanel attribute and closes itself on
-- seeing a name that is not its own, so no script has to know the others exist.
--==============================================================================
local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		-- Painted before it is shown: the clocks tick once a second and an
		-- unpainted first frame is a panel full of last minute's numbers.
		refresh(true)
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	modal.setOpen(want)
end

button.Activated:Connect(function()
	setOpen(not open)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
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
