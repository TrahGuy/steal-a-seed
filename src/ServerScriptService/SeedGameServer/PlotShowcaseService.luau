--!strict
--==============================================================================
-- Steal a Seed :: PlotShowcaseService (2026-10-05, the owner's TOP CREATURES board)
--
-- WHAT EVERY PLOT'S BOARD SHOWS IS DECIDED HERE, AND ONLY HERE. The server holds
-- every planted model of every plot; a client may not -- Workspace streams, and
-- another owner's garden reaches a far client whole or not at all (Atomic,
-- PlantService.render). So each plot's grown creatures are ranked here
-- (PlotShowcase.top: income first, EQUIP BEST's order on a tie) and the best two
-- written as plain attributes on that plot's board (PlotShowcase.publish: each
-- slot's species id, tier and placement id). Every client draws from those and
-- from nothing else (PlotShowcaseUI).
--
-- EVENTS, NOT A LOOP. A plot is looked at again only when something in it
-- changes:
--   * a planted model arrives or leaves -- the Planted tag: a planting, a
--     pick-up, EQUIP BEST and UNEQUIP ALL, a garden restored, a hatch (it takes
--     the pod out of the bed and puts the creature in the hands), an upgrade's
--     re-render, a release when the owner leaves;
--   * one of its models changes what it is (Stage, Tier, SpeciesId);
--   * a board arrives (a map rebuild).
-- A burst -- EQUIP BEST moving five creatures, an upgrade re-laying a whole
-- garden -- folds into ONE publish PublishDelaySeconds after its first change,
-- and an unchanged answer writes nothing (PlotShowcase.publish compares first).
--
-- BOOSTS NEVER REORDER A GARDEN. The pass, the Bonus Chest, a sacrifice and the
-- rain multiply every plant in a plot alike (GameConfig.gardenIncomeMultiplier
-- is one factor per plot), so the order is the same and only the shown rate
-- moves -- which each client reads off the plot itself, as the overhead labels
-- do. Nothing here listens to a boost.
--
-- NOTHING A CLIENT SENDS REACHES THIS. No remote. It decides nothing about the
-- economy, the garden or the save: it only describes them.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))

local PlotShowcaseService = {}
-- After the map (the boards) and the gardens (PlantService, 50); it reads both
-- and changes neither.
PlotShowcaseService.Priority = 61

local SC = GameConfig.Plot.Showcase
local TAG_PLANTED = GameConfig.Tags.Planted
local TAG_BOARD = GameConfig.Tags.PlotShowcase
local TAG_PLOT = GameConfig.Tags.Plot
local PLOT_ID = GameConfig.Attributes.PlotId
-- What a planted model may change in place that would change its row.
local WATCHED = { "Stage", "Tier", "SpeciesId" }

local function log(message: string)
	print("[Seed/PlotShowcaseService] " .. message)
end

-- The plot each planted model stood in when it arrived: one that is leaving has
-- often left the tree already, so its plot cannot be found by walking up.
local plotOfModel: { [Instance]: Instance } = {}
local modelConns: { [Instance]: { RBXScriptConnection } } = {}
local pending: { [Instance]: boolean } = {}
local conns: { RBXScriptConnection } = {}
local running = false

--==============================================================================
-- WHERE THINGS ARE
--==============================================================================
-- The tagged plot a planted model stands in (PlantService puts it in the plot's
-- own Plants folder), or nil.
function PlotShowcaseService.PlotOf(model: Instance): Instance?
	local at = model.Parent
	while at and at ~= Workspace and at ~= game do
		if CollectionService:HasTag(at, TAG_PLOT) then
			return at
		end
		at = at.Parent
	end
	return nil
end

-- The board that carries a plot's two (MapService gives both the same PlotId).
function PlotShowcaseService.BoardFor(plot: Instance): Instance?
	local id = plot:GetAttribute(PLOT_ID)
	if id == nil then
		return nil
	end
	for _, board in ipairs(CollectionService:GetTagged(TAG_BOARD)) do
		if board:GetAttribute(PLOT_ID) == id then
			return board
		end
	end
	return nil
end

local function plotForBoard(board: Instance): Instance?
	local id = board:GetAttribute(PLOT_ID)
	if id == nil then
		return nil
	end
	for _, plot in ipairs(CollectionService:GetTagged(TAG_PLOT)) do
		if plot:GetAttribute(PLOT_ID) == id then
			return plot
		end
	end
	return nil
end

--==============================================================================
-- ONE PLOT'S ANSWER
--
-- Read fresh from the tagged models standing in it -- at most a few dozen across
-- the whole server, and only when something changed -- so no remembered list can
-- go stale.
--==============================================================================
function PlotShowcaseService.Rows(plot: Instance): { PlotShowcase.Row }
	local rows: { PlotShowcase.Row } = {}
	for _, model in ipairs(CollectionService:GetTagged(TAG_PLANTED)) do
		if PlotShowcaseService.PlotOf(model) == plot then
			local row = PlotShowcase.rowOf(model)
			if row then
				table.insert(rows, row)
			end
		end
	end
	return rows
end

-- Ranks the plot now and writes its board. Answers whether anything changed.
function PlotShowcaseService.Publish(plot: Instance): boolean
	local board = PlotShowcaseService.BoardFor(plot)
	if not board then
		return false
	end
	return PlotShowcase.publish(board, PlotShowcase.top(PlotShowcaseService.Rows(plot)))
end

-- One publish for a burst of changes, PublishDelaySeconds after the first.
local function schedule(plot: Instance?)
	if not plot or pending[plot] then
		return
	end
	pending[plot] = true
	task.delay(SC.PublishDelaySeconds, function()
		pending[plot] = nil
		if running and plot.Parent then
			local ok, err = pcall(PlotShowcaseService.Publish, plot)
			if not ok then
				warn("[Seed/PlotShowcaseService] publish failed: " .. tostring(err))
			end
		end
	end)
end

--==============================================================================
-- THE TAG'S COMINGS AND GOINGS
--==============================================================================
local function arrive(model: Instance)
	if plotOfModel[model] then
		return
	end
	local plot = PlotShowcaseService.PlotOf(model)
	if not plot then
		return
	end
	plotOfModel[model] = plot
	local list = {}
	for _, name in ipairs(WATCHED) do
		table.insert(list, model:GetAttributeChangedSignal(name):Connect(function()
			schedule(plot)
		end))
	end
	modelConns[model] = list
	schedule(plot)
end

local function leave(model: Instance)
	local plot = plotOfModel[model]
	if not plot then
		return
	end
	plotOfModel[model] = nil
	local list = modelConns[model]
	if list then
		for _, c in ipairs(list) do
			c:Disconnect()
		end
		modelConns[model] = nil
	end
	schedule(plot)
end

local function reset()
	running = false
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	table.clear(conns)
	for _, list in pairs(modelConns) do
		for _, c in ipairs(list) do
			c:Disconnect()
		end
	end
	table.clear(modelConns)
	table.clear(plotOfModel)
	table.clear(pending)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PlotShowcaseService.Init()
	-- A re-run in one Studio: nothing of a previous session's watchers survives.
	reset()
end

function PlotShowcaseService.Start()
	reset()
	running = true
	table.insert(conns, CollectionService:GetInstanceAddedSignal(TAG_PLANTED):Connect(arrive))
	table.insert(conns, CollectionService:GetInstanceRemovedSignal(TAG_PLANTED):Connect(leave))
	table.insert(conns, CollectionService:GetInstanceAddedSignal(TAG_BOARD):Connect(function(board)
		schedule(plotForBoard(board))
	end))
	for _, model in ipairs(CollectionService:GetTagged(TAG_PLANTED)) do
		arrive(model)
	end
	-- Every plot once, so a plot with nothing planted reads as empty from the
	-- start rather than never having been answered.
	for _, plot in ipairs(CollectionService:GetTagged(TAG_PLOT)) do
		schedule(plot)
	end
	log(string.format("Ready. Each plot's board shows its %d best grown creatures, published when its garden "
		.. "changes (%.2f s to fold a burst); no loop, no remote.", SC.Slots, SC.PublishDelaySeconds))
end

function PlotShowcaseService.Stop()
	reset()
end

return PlotShowcaseService
