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
-- A WORD AND A CLOCK, AND NOTHING ELSE
--
--   HATCHING   it is still a pod
--   GROWING    it is a sprout
--   <name>     it is done -- and this is the only place the species is ever
--              named, which is the point: pods are coloured by RARITY, so the
--              two Commons arrive identical and which one you actually got
--              stays hidden until it finishes. The reveal is free content at
--              the end of every run home.
--
-- No rarity, no weight, no owner. The model's colour is its rarity and its size
-- is its weight, exactly as at the nest -- repeating either in text would be a
-- caption on a photograph, which is the same rule PromptUI follows.
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

local STAGE_POD = 1
local STAGE_SPROUT = 2
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
	billboard: BillboardGui,
	word: TextLabel,
	timer: TextLabel,
	stroke: UIStroke,
	species: SeedData.Species?,
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
	if not (species and type(plantedAt) == "number") then
		return nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SeedPlant"
	billboard.Adornee = anchor
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(124, 40)
	-- Measured off the MODEL, not the anchor: PrimaryPart is the pod shell at
	-- one stage and the soil mound at the next, so a fixed offset would sit on
	-- top of a pod and inside a creature's chest.
	local _, size = model:GetBoundingBox()
	billboard.StudsOffset = Vector3.new(0, size.Y * 0.5 + 1.4, 0)
	-- Camera-relative, unlike a prompt's activation range -- the lesson
	-- PromptUI paid for. Far enough to read a neighbour's plot from the road,
	-- which is the whole point of showing it to people who do not own it.
	billboard.MaxDistance = 160
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
	word.Size = UDim2.new(1, 0, 0, 15)
	word.BackgroundTransparency = 1
	word.Font = Enum.Font.GothamBold
	word.TextSize = 13
	word.TextColor3 = PAPER
	word.Text = ""
	word.Parent = panel

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.LayoutOrder = 2
	timer.Size = UDim2.new(1, 0, 0, 17)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.GothamBlack
	timer.TextSize = 17
	timer.TextColor3 = ACCENT
	timer.Text = ""
	timer.Parent = panel

	return {
		billboard = billboard,
		word = word,
		timer = timer,
		stroke = stroke,
		species = species,
		plantedAt = plantedAt,
		stage = tonumber(model:GetAttribute("Stage")) or STAGE_POD,
		lastText = "",
	}
end

--==============================================================================
-- WHAT IT SAYS
--
-- Recomputed from the same two numbers the server uses -- PlantedAt and the
-- species' grow time -- rather than from anything pushed across. Nothing to
-- replicate, and it is already correct on the first frame after a rejoin.
--==============================================================================
local function refresh(panel: Panel, now: number)
	local species = panel.species
	if not species then
		return
	end
	local total = SeedData.GrowSeconds(species)
	local elapsed = now - panel.plantedAt
	local sproutAt = total * PLANTING.SproutAt

	local word, timer
	if elapsed < sproutAt then
		word, timer = "HATCHING", clock(sproutAt - elapsed)
	elseif elapsed < total then
		word, timer = "GROWING", clock(total - elapsed)
	else
		-- Done. The name, and no clock -- a timer reading 0:00 forever is worse
		-- than no timer, and the creature standing there already says it grew.
		word, timer = string.upper(species.Name), ""
	end

	local key = word .. "\0" .. timer
	if key == panel.lastText then
		return
	end
	panel.lastText = key
	panel.word.Text = word
	panel.timer.Text = timer

	local grown = timer == ""
	-- Quieter once it is finished. A full plot is twelve of these, and twelve
	-- lit panels over a bed that needs nothing from you is noise.
	panel.timer.Size = if grown then UDim2.new(1, 0, 0, 0) else UDim2.new(1, 0, 0, 17)
	panel.word.TextColor3 = if grown then ACCENT else PAPER
	panel.stroke.Transparency = if grown then 0.75 else 0.3
	panel.billboard.Size = if grown then UDim2.fromOffset(124, 26)
		else UDim2.fromOffset(124, 40)
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
	task.spawn(function()
		local deadline = os.clock() + 5
		while not model.PrimaryPart and model.Parent and os.clock() < deadline do
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
--==============================================================================
local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since < PLANTING.TickSeconds then
		return
	end
	since = 0
	local now = serverNow()
	for model, panel in pairs(panels) do
		if not model.Parent then
			remove(model)
		else
			refresh(panel, now)
		end
	end
end)
