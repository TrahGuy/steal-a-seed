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
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant
local PANEL_NAME = "Garden"

--==============================================================================
-- THE ONE MESSAGE THIS PANEL SENDS
--
-- Everything else here is read straight off the tagged models in the world. The
-- unequip cannot be: the server owns ownership and the economy (Rule 3), so all
-- the client may do is name a plant and ask.
--
-- GameEvent already existed and already carries PlantAt. Same remote, second
-- verb -- see GameConfig.Plant.PickUpAction.
--==============================================================================
local gameEvent: RemoteEvent? = nil

local function fire(action: string, payload: any)
	if gameEvent then
		gameEvent:FireServer(action, payload)
	end
end

-- The same vocabulary as PromptUI, PlantUI and CashUI.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
local GHOST = Color3.fromRGB(150, 148, 154)
-- No card fill here any more: UIKit.plantCard owns the stage a plant stands on,
-- and this file owns what the card says. See IndexUI for why the flat rectangle
-- went.

--==============================================================================
-- IT OPENS IN THE MIDDLE NOW, NOT OFF THE RIGHT EDGE
--
-- This docked on the right rail and the Index docked on the left, which is why
-- the two were allowed to be open at once. A modal has no side, so the argument
-- goes with it: all three panels share one rectangle and take turns. UIKit.modal
-- owns the geometry; this is only the cap it may grow to.
--==============================================================================
local MAX_WIDTH = 480
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

local FOOTER_HEIGHT = 32

-- The cards carry a rotated lattice, which a ScrollingFrame will not clip -- a
-- half-scrolled card was drawing its diamonds straight over the footer below.
-- See UIKit.rotationSafeClip.
local clip = UIKit.rotationSafeClip(modal.body, "SlotsClip",
	UDim2.new(1, 0, 1, -FOOTER_HEIGHT))

local list = Instance.new("ScrollingFrame")
list.Name = "Slots"
list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = GameConfig.Panel.Edge
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = 3
list.Parent = clip

local grid = Instance.new("UIGridLayout")
grid.FillDirection = Enum.FillDirection.Horizontal
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = list

--==============================================================================
-- THREE COLUMNS WHEN THERE IS ROOM, TWO ON A PHONE
--
-- Measured off the panel rather than typed, the same way the Index measures its
-- almanac -- the modal is a fraction of the screen with a cap, so one script has
-- to lay out at 248 pixels and at 480.
--
-- Never one column. A single stack of cards is the row list this panel just
-- stopped being.
--==============================================================================
local GUTTER = 8
local CARD_ASPECT = 1.30
local shownSlots = 0

local function relayout()
	local width = list.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local columns = if width >= 400 then 3 else 2
	local cell = math.floor((width - GUTTER * (columns - 1) - 6) / columns)
	local cellHeight = math.floor(cell * CARD_ASPECT)
	grid.CellSize = UDim2.fromOffset(cell, cellHeight)
	grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)

	local rows = math.max(1, math.ceil(math.max(shownSlots, 1) / columns))
	modal.fitContent(rows * cellHeight + (rows - 1) * GUTTER + FOOTER_HEIGHT)
end

--==============================================================================
-- FORWARD DECLARED, BECAUSE THE SCROLL HANDLER IS ABOVE THE SELECTION
--
-- The layout is built before the cards are, so this connection exists a couple
-- of hundred lines before `clearSelection` does. A `local function` declared
-- later is not in scope here -- the name compiles to a global, which is nil,
-- and the only symptom is a scroll that quietly fails to drop the selection
-- while an error goes to the log. Same shape of bug PlantService documents on
-- `attachPickup`, and the same fix.
--==============================================================================
local clearSelection: () -> ()

list:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
-- Scrolling away from a selected card drops it: a button that has slid half out
-- of the list is a button nobody meant to be aiming at.
list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	clearSelection()
end)

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
-- MINI CARDS, IN THE PANEL AND NOWHERE ELSE
--
-- These were 44-pixel rows with a 28-pixel coloured square. The square had to be
-- the species CROWN because Body put two identical creams side by side, which is
-- a workaround for the fact that a swatch cannot show a plant. A card can: the
-- same still 3D CreatureModel the Index shows and the plot builds, so a
-- Bellchime in your bed, on your card and in the almanac are one thing.
--
-- IN THE PANEL. Grown plants in the plot still carry NO billboard -- what they
-- earn is the `+$N` popping off them, and twelve name cards stacked over one
-- patch of dirt is the wall the owner cut. This is the panel you open, not
-- something bolted to the world.
--
-- WHAT A CARD SAYS IS NOT WHAT AN INDEX CARD SAYS. The almanac lists shapes and
-- spells the FORM rarity; this lists the twelve holes in front of you and tints
-- by ColorForKg, the WEIGHT band. Same drawing, different question, and the two
-- vocabularies never cross.
--
--==============================================================================
-- POOLED AND REFILLED, AND THE ART IS KEYED
--
-- A tier-4 plot is thirty cards and the panel refreshes once a second while
-- open. The frames were always pooled; the PORTRAIT has to be too, or every
-- second would tear down thirty plants of thirty frames each and build them
-- again. `drawn` holds what the art currently depicts and the portrait is only
-- rebuilt when that string changes -- which is a hatch, a pickup or a plant,
-- not a clock tick.
--==============================================================================
type Slot = UIKit.PlantCard

local pool: { Slot } = {}

--==============================================================================
-- ONE CARD AT A TIME, AND IT SAYS WHAT THE WORLD SAYS
--
-- The clip this panel borrowed its shape from unequips into an inventory. This
-- game has no inventory: plants live in the dirt and the only place they can go
-- is your hands.
--
-- So the button says PICK UP, which is exactly what the prompt on the plant
-- says out in the field, because it is exactly the same act -- the same server
-- call, handing over the same Tool the hatch does. It read UNEQUIP for a pass
-- and that was a word borrowed from a game with a loadout: two names for one
-- action is how a player ends up looking for the difference between them.
--
-- WHICH CARDS OFFER IT
--
--   grown, your plot   yes
--   pod / hatching     no. That is HATCH, and it happens in the world.
--   ready              no, for the same reason.
--   empty              no.
--   no plot            no.
--
-- SELECTING IS NOT DOING. A click selects; only the button underneath acts.
-- Anything that would make the selection stale -- another card, the dimmer, a
-- scroll, the panel closing, or the slot's own contents changing -- drops it.
--==============================================================================
local selectedId: number? = nil
local selectedSlot: Slot? = nil

function clearSelection()
	if selectedSlot then
		selectedSlot.setSelected(false)
	end
	selectedSlot = nil
	selectedId = nil
end

local function selectSlot(slot: Slot, placementId: number?)
	if selectedSlot == slot then
		clearSelection()
		return
	end
	clearSelection()
	selectedSlot = slot
	selectedId = placementId
	slot.setSelected(true, if placementId then "PICK UP" else nil)
end

--==============================================================================
-- WHAT A CARD IS OFFERING, IF ANYTHING
--
-- Set by the painter every time it fills a card in. nil means this card cannot
-- be picked up -- an empty hole, a pod, somebody's missing plot.
--==============================================================================
local offers: { [number]: number? } = {}

local function buildSlot(index: number): Slot
	local slot = UIKit.plantCard(list, {
		name = "Slot" .. index,
		layoutOrder = index,
		nameSize = 14,
		subSize = 12,
	})
	pool[index] = slot

	slot.button.Activated:Connect(function()
		local placementId = offers[index]
		selectSlot(slot, placementId)
	end)

	slot.action.Activated:Connect(function()
		local placementId = offers[index]
		if not placementId or selectedId ~= placementId then
			return
		end
		--==================================================================
		-- THE SERVER TAKES THE PLANT OUT, NOT THIS
		--
		-- Nothing is destroyed here and nothing is assumed. The plant leaves
		-- the bed when PlantService says it does, and PlantService only says
		-- so after CarryService has actually put the Tool in the backpack --
		-- so a full hotbar leaves the plant standing where it was.
		--
		-- The panel finds out the same way it finds out about everything
		-- else: the Planted tag disappears and refresh() repaints. There is
		-- no reply to wait for and no local copy to keep in step.
		--==================================================================
		fire(PLANTING.PickUpAction, placementId)
		clearSelection()
	end)

	return slot
end

local function slotAt(index: number): Slot
	return pool[index] or buildSlot(index)
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
	tier: number,
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
			local tier = tonumber(model:GetAttribute("Tier"))
			local id = tonumber(model:GetAttribute("PlacementId"))
			local stage = tonumber(model:GetAttribute("Stage"))
			if species and tier and id and stage and type(plantedAt) == "number" then
				table.insert(out, {
					species = species,
					tier = tier,
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
	local remaining = SeedData.GrowSeconds(occupant.tier) - (now - occupant.plantedAt)
	if remaining > 0 then
		return STAGE_POD, remaining
	end
	return STAGE_READY, 0
end

--==============================================================================
-- HOW MANY THINGS FIT
--==============================================================================
local plotTier = GameConfig.StartingPlotTier

--==============================================================================
-- CAPACITY, AND WHERE IT IS READ FROM
--
-- The PLOT is asked first and the profile is the fallback. Both are written by
-- the server and they agree in the steady state, but they do not update in the
-- same instant: an upgrade rebuilds the plot immediately and the profile packet
-- that carries the new PlotTier follows up to a quarter second later. Reading
-- the plot means the panel grows the moment the bed does.
--
-- It used to be plotSlotsFor(rows) -- the invisible planting grid. That has not
-- equalled the number of plants a level holds since the ladder was re-cut, and
-- reading it here would have drawn 21 rows for a level that holds 7.
--==============================================================================
local function capacityOf(plot: Model?): number
	if plot then
		local n = tonumber(plot:GetAttribute("Capacity"))
		if n and n == n and n > 0 then
			return math.floor(n)
		end
	end
	return GameConfig.plotCapacityForTier(plotTier)
end

--==============================================================================
-- PAINTING
--==============================================================================
local open = false

local function setSlotCount(n: number)
	for i = 1, math.max(n, shownSlots) do
		local slot = pool[i]
		if i <= n then
			slot = slotAt(i)
			slot.holder.Visible = true
		elseif slot then
			slot.holder.Visible = false
		end
	end
	if shownSlots ~= n then
		shownSlots = n
		-- The panel is as tall as the bed it is showing, so a tier change is a
		-- resize as well as a repaint.
		relayout()
	end
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
		setSlotCount(1)
		local slot = slotAt(1)
		slot.setEmpty(true)
		slot.setModel("noplot", nil)
		slot.setBackdrop(nil)
		offers[1] = nil
		slot.name.Text = "No Plot"
		slot.name.TextColor3 = GHOST
		slot.sub.Text = "Claim one first"
		slot.sub.TextColor3 = GHOST
		return
	end

	local here = occupants(plot)
	local capacity = capacityOf(plot)

	--==========================================================================
	-- EVERY PLANT GETS A ROW, EVEN THE ONES THAT DO NOT FIT
	--
	-- A garden can legitimately hold more than its level's capacity: the ladder
	-- was re-cut under live saves, so an old profile migrates in over its new
	-- limit and PlantService restores all of it rather than discarding the
	-- overflow. Capacity blocks PLANTING, not owning.
	--
	-- So the row count is whichever is larger. Drawing only `capacity` rows
	-- would hide plants the player owns, can see standing in their own bed, and
	-- cannot select or pick up from the one panel that lists them -- which reads
	-- as the game having eaten them.
	--
	-- Below capacity the extra rows are empty and mean "room left". There are
	-- none beyond it: at or over capacity the list stops at the last real plant.
	--==========================================================================
	local rows = math.max(capacity, #here)
	local planted, waiting, rate = 0, 0, 0

	if paint then
		setSlotCount(rows)
	end

	for index = 1, rows do
		local occupant = here[index]
		if occupant then
			planted += 1
			local stage, remaining = stageOf(occupant, now)
			if stage == STAGE_GROWN then
				rate += SeedData.IncomePerSecond(occupant.species, occupant.tier)
			else
				waiting += 1
			end

			if paint then
				local slot = slotAt(index)
				local species = occupant.species
				--==========================================================
				-- TINTED BY WHAT IT WEIGHS, NOT BY WHAT SHAPE IT IS
				--
				-- The sheet's rarity is the FORM's drop rate -- how often a
				-- cube turns up against a bell -- and it says nothing about
				-- the prize. Printing an 8,000 kg Nubkin in Common white
				-- would call the best thing in the garden ordinary.
				--
				-- This is the Garden, so it is ColorForKg on the name AND on
				-- the border. FormColor belongs to the Index and stays there.
				--==========================================================
				local band = SeedData.ColorForTier(occupant.tier)
				local kgFormatted = GameConfig.compact(occupant.tier) .. " tier"

				if stage == STAGE_GROWN then
					slot.setEmpty(false)
					slot.setStageTheme("grown")
					slot.setReadyPulse(false)
					slot.setProgress(nil)
					slot.setWeightTag(kgFormatted, band)
					slot.setStatusTag("+$" .. GameConfig.compact(
						SeedData.IncomePerSecond(occupant.species, occupant.tier)) .. "/s",
						Color3.fromRGB(142, 220, 68), Color3.fromRGB(20, 36, 16))

					slot.setModel("grown:" .. species.Id, function(into)
						return CreatureModel.Build(species, occupant.tier,
							CreatureModel.STAGE_GROWN, CFrame.new(), into)
					end, species.Form or species.Id)
					slot.setBackdrop(species.Id)
					slot.border.Color = band

					offers[index] = occupant.id
					slot.name.Text = species.Name
					slot.name.TextColor3 = band
					slot.sub.Text = string.upper(SeedData.RarityForTier(occupant.tier))
					slot.sub.TextColor3 = Color3.fromRGB(220, 218, 225)
				else
					slot.setEmpty(false)
					slot.setModel("pod:" .. SeedData.RarityForTier(occupant.tier),
						function(into)
							return CreatureModel.BuildPod(species, occupant.tier,
								CFrame.new(), into)
						end, if stage == STAGE_READY then "ready" else "pod")
					slot.setBackdrop(nil)
					slot.border.Color = band
					offers[index] = nil
					slot.setWeightTag(kgFormatted, band)

					if stage == STAGE_READY then
						slot.setStageTheme("ready")
						slot.setReadyPulse(true)
						slot.setProgress(1.0, Color3.fromRGB(255, 215, 0))
						slot.setStatusTag("READY!", Color3.fromRGB(255, 235, 80), Color3.fromRGB(48, 40, 12))

						slot.name.Text = "Ready to Hatch"
						slot.name.TextColor3 = band
						slot.sub.Text = "HOLD [E] IN FIELD"
						slot.sub.TextColor3 = ACCENT
					else
						slot.setStageTheme("pod")
						slot.setReadyPulse(false)
						local totalSec = SeedData.GrowSeconds(occupant.tier)
						local frac = if totalSec > 0 then math.clamp(1 - (remaining / totalSec), 0, 1) else 0
						slot.setProgress(frac, band)
						slot.setStatusTag("⏱ " .. clock(remaining), Color3.fromRGB(250, 205, 75))

						slot.name.Text = "Hatching..."
						slot.name.TextColor3 = GHOST
						slot.sub.Text = string.format("%d%% Grown", math.floor(frac * 100))
						slot.sub.TextColor3 = GHOST
					end
				end
			end
		elseif paint then
			local slot = slotAt(index)
			slot.setEmpty(true)
			slot.setModel("empty", nil)
			slot.setBackdrop(nil)
			offers[index] = nil
			slot.name.Text = "Empty Slot"
			slot.name.TextColor3 = GHOST
			slot.sub.Text = "+ Plant"
			slot.sub.TextColor3 = Color3.fromRGB(130, 175, 95)
		end
	end

	--==========================================================================
	-- A SELECTION THAT NO LONGER NAMES ANYTHING IS DROPPED
	--
	-- The plant may have been picked up, stolen, or grown out from under the
	-- card while the panel was open. Rather than trust the click that made it,
	-- the selection is re-tested against what the bed actually holds on every
	-- repaint -- so the button can never outlive the plant it would act on.
	--==========================================================================
	if paint and selectedId then
		local stillThere = false
		for _, id in pairs(offers) do
			if id == selectedId then
				stillThere = true
				break
			end
		end
		if not stillThere then
			clearSelection()
		end
	end

	badge.Visible = waiting > 0
	badgeLabel.Text = tostring(waiting)

	if paint then
		-- Reads "GARDEN 8/10" normally and "GARDEN 23/20" for a migrated garden
		-- that is over its level. The second one looks wrong and is not: it is
		-- the honest description of a bed holding more than it can be planted
		-- with, and hiding it would not make the plants go away.
		header.Text = string.format("GARDEN  %d/%d", planted, capacity)
		footer.Text = if rate > 0 then "PLOT INCOME:  +$" .. GameConfig.compact(rate) .. "/s" else ""
		footer.TextColor3 = Color3.fromRGB(145, 235, 75)
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
	if not want then
		clearSelection()
	end
	modal.setOpen(want)
end

--==============================================================================
-- THE PANEL BACKGROUND DELIBERATELY DOES NOT CLEAR THE SELECTION
--
-- It did for one pass, on shell.InputBegan, and that is a race: InputBegan is
-- mouse-DOWN and Activated is mouse-UP, so a press on UNEQUIP cleared the
-- selection a frame before the button it was pressed on could act on it. The
-- guard in the handler then read a nil selection and did nothing. It happened
-- to work in testing, which is the worst way for a race to behave.
--
-- Nothing is lost. A selection is dropped by the things that actually make it
-- stale -- the same card again, another card, an empty one, a scroll, the panel
-- closing, or the plant no longer being there -- and the dimmer closes the
-- panel, which is already one of those.
--==============================================================================

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

do
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local channel = if remotes
		then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
		else nil
	if channel and channel:IsA("RemoteEvent") then
		gameEvent = channel
	else
		warn("[Seed/GardenUI] No GameEvent remote; UNEQUIP will do nothing.")
	end
end

local function onTagChanged()
	refresh(open)
end

CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(onTagChanged)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(onTagChanged)

refresh(false)
