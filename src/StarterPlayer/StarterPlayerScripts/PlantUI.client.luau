--!strict
-- Steal a Seed :: PlantUI
--
-- The hatch timer over anything growing in a plot.
--
--==============================================================================
-- WHY THIS EXISTS AT ALL
--
-- A planted pod and a nest pod are the SAME MODEL. That is deliberate -- it is
-- the thing you carried home, standing where you put it -- but it meant a plant
-- read as loot, and for a while it literally was: CarryService hung a Take
-- prompt on it and taking one ran the whole raid alarm, RUN and then SAFE,
-- inside the safe zone, for a pod the player had carried home themselves.
--
-- The tag stops that. This is the other half: if a plant is not a thing you
-- TAKE, it has to visibly be a thing you WAIT FOR. Otherwise a plot of pods is
-- just a plot of objects that ignore you.
--
--==============================================================================
-- A CLOCK WHILE IT WAITS, AND NOTHING ONCE IT IS DONE
--
--   HATCHING   it is still a pod      + m:ss
--   GROWING    it is a sprout         + m:ss
--   <grown>    no billboard at all
--
-- The label on a FINISHED plant went through three shapes -- name + rate, then
-- rate alone, then rarity + name + rate off the uncorrupted reference clip --
-- and the owner cut it at the sight of a real bed. The reason is arithmetic: a
-- starting plot is twelve holes, so a full one was twelve three-line cards
-- stacked over one patch of dirt, with a `+$N` rising through each of them. In a
-- screenshot one card looks good. Twelve is a wall.
--
-- So a grown plant now carries no plate. What it earns is said by the `+$N`
-- popping off it every second, which is the loud element in the reference
-- footage too, and WHAT IT IS is said by the Garden panel on the right rail --
-- a row per slot, name, rarity, rate, without walking the bed.
--
-- The billboard is DISABLED rather than destroyed. Stage is recomputed from the
-- clock every tick, so a sprout crosses into grown here a moment before the
-- server rebuilds the model, and this has to be able to switch off mid-life.
--
--==============================================================================
-- THE WAIT STILL GETS A LABEL, AND ONLY THE WAIT
--
-- A pod or a sprout is the one case where the world genuinely has nothing to
-- say for itself: it is a shell, it is not paying, and the only fact anybody
-- wants off it is how long is left. That is worth a plate. A grown creature is
-- already a distinct silhouette doing a visible thing.
--
-- No rarity word here either, at any stage. A pod is COLOURED by rarity, so the
-- word would be a caption on a photograph -- and worse, it would spend the
-- reveal early, since two Commons arrive in identical shells. The word lives in
-- the Index; the Garden tints a grown row's name with the colour.
--==============================================================================
--
--==============================================================================
-- THE CLOCK IS THE SERVER'S, NOT THIS MACHINE'S
--
-- PlantedAt is an absolute os.time() stamp, so the countdown has to be measured
-- against the same clock the server grows things on. GetServerTimeNow() is that
-- clock; a client's own os.time() can sit seconds off and the timer would hit
-- 0:00 while the pod sat there, or the pod would change shape with 0:04 still
-- showing -- either one reads as broken.
--
--==============================================================================
-- IT IS DRAWN FOR EVERYBODY, NOT JUST THE OWNER
--
-- Deliberately no ownership filter. A plot half way through is meant to be
-- readable by whoever walks past deciding whether this one is worth coming back
-- to -- that is what makes a garden a target, and the game is about theft.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local PLANTING = GameConfig.Plant

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- The same three colours PromptUI uses. One vocabulary, so a hatch timer and a
-- Take prompt read as belonging to the same game.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)
--==============================================================================
-- IT IS A SEED PACKET NOW, NOT THE HUD IN MINIATURE
--
-- The word and the clock were GothamBold and GothamBlack in paper and lime --
-- the same type as the cash readout in the corner of the screen. Nothing about
-- them said they belonged to the pod they were floating over. See
-- GameConfig.Labels.Pod for what they are instead, and for why the clock
-- changes colour as it runs down.
--==============================================================================
local POD = GameConfig.Labels.Pod

-- The only two things that stand in a bed. There is no sprout any more: nothing
-- grows in the ground, it hatches in your hands.
local STAGE_POD = 1
local STAGE_GROWN = 3

--==============================================================================
-- ONE CONTAINER, DESTROYED FIRST
--
-- So a re-run of this script cannot leave a second set of billboards behind --
-- the same re-run rule the server files follow.
--==============================================================================
local existing = playerGui:FindFirstChild("SeedPlantUI")
if existing then
	existing:Destroy()
end

local container = Instance.new("Folder")
container.Name = "SeedPlantUI"
container.Parent = playerGui

type Panel = {
	model: Model,
	billboard: BillboardGui,
	word: TextLabel,
	timer: TextLabel,
	species: SeedData.Species?,
	-- What THIS plant weighs. The clock is a function of weight, not of form:
	-- a 4 kg Nubkin hatches in half a minute and a 9,000 kg one takes five, and
	-- the two are the same species.
	tier: number,
	plantedAt: number,
	stage: number,
	lastText: string,
}

local panels: { [Model]: Panel } = {}

local function serverNow(): number
	-- pcall because GetServerTimeNow throws if the client has not finished
	-- syncing yet, which is precisely when this script first runs.
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.time()
end

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

--==============================================================================
-- THE PANEL
--==============================================================================
local function build(model: Model): Panel?
	local anchor = model.PrimaryPart
	if not anchor then
		return nil
	end

	local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
	local plantedAt = model:GetAttribute("PlantedAt")
	local tier = tonumber(model:GetAttribute("Tier"))
	if not (species and tier and type(plantedAt) == "number") then
		return nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SeedPlant"
	billboard.Adornee = anchor
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(124, 40)
	--==========================================================================
	-- A FIXED GAP ABOVE THE REAL TOP
	--
	-- Measured off the MODEL, not the anchor: PrimaryPart is the pod shell at one
	-- stage and the creature's base plate at the next, so a fixed offset would sit on top of
	-- a pod and inside a creature's chest.
	--
	-- And measured in WORLD SPACE, not off GetBoundingBox. This was
	-- `bbox.Y * 0.5 + 1.4`, and bbox.Y on these models is the WIDTH -- the pivot
	-- is a cylinder rolled ninety degrees, so X and Y come back swapped. It put a
	-- Bellchime's name plate 3.56 studs up on a plant 6.19 studs tall: buried in
	-- its own head, on the most valuable species in the biome. A Nubkin happened
	-- to land close enough to look correct, which is why it survived.
	--==========================================================================
	billboard.StudsOffset = Vector3.new(0,
		GameConfig.topOfModel(model, anchor) + 1.2, 0)
	-- Camera-relative, unlike a prompt's activation range -- the lesson
	-- PromptUI paid for. Far enough to read a neighbour's plot from the road,
	-- which is the whole point of showing it to people who do not own it.
	billboard.MaxDistance = 160
	--==========================================================================
	-- BORN OFF, TURNED ON BY refresh()
	--
	-- A BillboardGui defaults to Enabled and both labels are built empty. So
	-- anything that stopped refresh() from running -- it threw once, on a
	-- signature change, and every plant in the game wore a blank dark rectangle
	-- for a session -- left a plate that was never written to and never switched
	-- off. Starting off means a plate is only ever visible because something
	-- actually put text in it.
	--==========================================================================
	billboard.Enabled = false
	billboard.Parent = container

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.18
	panel.BorderSizePixel = 0
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.Parent = panel

	local column = Instance.new("UIListLayout")
	column.FillDirection = Enum.FillDirection.Vertical
	column.HorizontalAlignment = Enum.HorizontalAlignment.Center
	column.VerticalAlignment = Enum.VerticalAlignment.Center
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Parent = panel

	local word = Instance.new("TextLabel")
	word.Name = "Word"
	word.LayoutOrder = 1
	word.Size = UDim2.new(1, 0, 0, POD.WordSize + 2)
	word.BackgroundTransparency = 1
	word.Font = POD.Font
	word.TextSize = POD.WordSize
	word.TextColor3 = POD.Word
	word.Text = ""
	word.Parent = panel

	local wordEdge = Instance.new("UIStroke")
	wordEdge.Color = POD.Outline
	wordEdge.Thickness = POD.OutlineThickness
	wordEdge.Parent = word

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.LayoutOrder = 2
	timer.Size = UDim2.new(1, 0, 0, POD.ClockSize + 1)
	timer.BackgroundTransparency = 1
	timer.Font = POD.Font
	timer.TextSize = POD.ClockSize
	timer.TextColor3 = POD.ClockYoung
	timer.Text = ""
	timer.Parent = panel

	local timerEdge = Instance.new("UIStroke")
	timerEdge.Color = POD.Outline
	timerEdge.Thickness = POD.OutlineThickness
	timerEdge.Parent = timer

	return {
		model = model,
		billboard = billboard,
		word = word,
		timer = timer,
		species = species,
		tier = tier,
		plantedAt = plantedAt,
		stage = tonumber(model:GetAttribute("Stage")) or STAGE_POD,
		lastText = "",
	}
end

--==============================================================================
-- WHAT IT SAYS
--
-- Recomputed from the same two numbers the server uses -- PlantedAt and the
-- hatch time for THIS POD'S WEIGHT -- rather than from anything pushed across.
-- Nothing to replicate, and it is already correct on the first frame after a
-- rejoin. Reading the species sheet instead would run a 9,000 kg pod's clock at
-- a 2 kg pod's speed and finish it four and a half minutes early.
--
-- ONLY AN UNHATCHED POD HAS ANYTHING TO SAY. Two things stand in a bed now and
-- neither of the others wants a plate:
--
--   A PLACED CREATURE has no clock at all. It was hatched somewhere else and
--   put here already earning, so counting down from its PlantedAt would invent
--   a wait nobody is having.
--
--   A READY POD has a prompt on it that says HATCH. A countdown frozen at 0:00
--   beside it is the same fact twice, and the prompt is the half you can act
--   on -- so the plate gets out of the way the moment the clock runs out.
--
-- THE ATTRIBUTES ARE RE-READ HERE, NOT CACHED AT build(). A pod becomes a
-- creature in place: the server rewrites Stage on the model it already tagged,
-- and a panel holding the value it saw at build time would count down forever
-- on a plant that had already hatched.
--==============================================================================
local function refresh(panel: Panel, now: number)
	local model = panel.model
	if not model or not model.Parent then
		return
	end
	panel.stage = tonumber(model:GetAttribute("Stage")) or panel.stage
	local pa = model:GetAttribute("PlantedAt")
	if type(pa) == "number" then
		panel.plantedAt = pa
	end
	panel.tier = tonumber(model:GetAttribute("Tier")) or panel.tier
	if not panel.species then
		panel.species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
	end

	local species = panel.species
	if not species then
		return
	end
	local function hide()
		if panel.billboard.Enabled then
			panel.billboard.Enabled = false
			-- Cleared so a plate that is somehow shown again repaints from
			-- scratch rather than trusting a stale key.
			panel.lastText = ""
		end
	end

	if panel.stage ~= STAGE_POD then
		hide()
		return
	end
	local remaining = SeedData.GrowSeconds(panel.tier) - (now - panel.plantedAt)

	-- Ready. The prompt takes it from here.
	if remaining <= 0 then
		hide()
		return
	end

	local word, timer = POD.Hatching, clock(remaining)

	local key = word .. "\0" .. timer
	if key == panel.lastText and panel.billboard.Enabled then
		return
	end
	panel.lastText = key
	panel.word.Text = word
	panel.timer.Text = timer

	--==========================================================================
	-- THE CLOCK RIPENS
	--
	-- Amber when it has just gone in, green when it is nearly out. The number
	-- already says how long is left; the colour says it WITHOUT BEING READ, so a
	-- player walking their own bed can tell which square is nearly ready without
	-- stopping at any of them.
	--
	-- Written in the same block that is already guarded by the text having
	-- changed, so this costs one Color3 assignment per second per pod rather
	-- than one per frame.
	--==========================================================================
	local total = SeedData.GrowSeconds(panel.tier)
	local ripeness = if total > 0 then math.clamp(1 - remaining / total, 0, 1) else 1
	panel.timer.TextColor3 = POD.ClockYoung:Lerp(POD.ClockReady, ripeness)

	-- Sizes are fixed at build(); nothing here resizes anything every tick.
	panel.billboard.Enabled = true
end

--==============================================================================
-- WATCHING
--
-- PlantService destroys and rebuilds the model at every stage change, so the
-- tag leaves and arrives again on its own and there is nothing here to keep in
-- step -- the panel is rebuilt with the thing it labels.
--==============================================================================
local function add(instance: Instance)
	if not instance:IsA("Model") or panels[instance] then
		return
	end
	local model = instance :: Model
	-- The model can be tagged before its parts have finished replicating, in
	-- which case PrimaryPart is not there yet. ParentAnim learned this the hard
	-- way and silently drew nothing for a whole session.
	--
	-- The wait covers the ATTRIBUTES too, not just the pivot. They replicate
	-- separately from the parts, so a model that had its PrimaryPart already
	-- could still answer nil to SpeciesId -- and a panel built from that has no
	-- species, no clock, and no way to get one.
	task.spawn(function()
		local deadline = os.clock() + 5
		while model.Parent and os.clock() < deadline do
			local anchor = model.PrimaryPart
			local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
			local plantedAt = model:GetAttribute("PlantedAt")
			local tier = tonumber(model:GetAttribute("Tier"))
			if anchor and species and tier and type(plantedAt) == "number" then
				break
			end
			task.wait(0.1)
		end
		if not (model.Parent and CollectionService:HasTag(model, GameConfig.Tags.Planted)) then
			return
		end
		if panels[model] then
			return
		end
		local panel = build(model)
		if panel then
			panels[model] = panel
			refresh(panel, serverNow())
		end
	end)
end

local function remove(instance: Instance)
	local panel = panels[instance :: Model]
	if panel then
		panel.billboard:Destroy()
		panels[instance :: Model] = nil
	end
end

for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Planted)) do
	add(instance)
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(add)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(remove)

--==============================================================================
-- THE TICK
--
-- Once a second, which is all a m:ss clock can show. Heartbeat with an
-- accumulator rather than a task.wait loop so it cannot drift, and the work is
-- skipped entirely by refresh() when the text has not changed -- which for a
-- grown plant is every tick, forever.
--
-- The sweep below rides the same second. GetInstanceRemovedSignal and
-- GetInstanceAddedSignal only fire for changes this client saw, and a model
-- tagged during the join handshake can land before the listener does -- so the
-- tagged set is reconciled once a second rather than trusted to have been
-- announced. It is a table walk over plants already in the bed; nothing is
-- rebuilt for a model that already has a panel.
--==============================================================================
local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since < PLANTING.TickSeconds then
		return
	end
	since = 0
	local now = serverNow()

	-- Periodically sweep any tagged models that might have missed initial signal
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Planted)) do
		if instance:IsA("Model") and not panels[instance] then
			add(instance)
		end
	end

	for model, panel in pairs(panels) do
		if not model.Parent then
			remove(model)
		else
			refresh(panel, now)
		end
	end
end)
