--!strict
-- Steal a Seed :: PlotShowcaseUI (2026-10-05, the owner's TOP CREATURES board)
--
-- Every plot's TOP CREATURES board, drawn on THIS screen from what the server
-- publishes and nothing else:
--
--   WHAT    the board's own attributes (PlotShowcaseService writes them;
--           PlotShowcase.read) at the OWNER's rate -- the plot's published
--           GardenBoost and the rain, GameConfig.gardenIncomeMultiplier --
--           through PlotShowcaseView, whose every word is PlantLabel.content.
--   WHERE   each face is a SurfaceGui in THIS player's PlayerGui, adorned to
--           the board's plank: one under the Workspace draws no ViewportFrame
--           at all (a Roblox rule; see PlotShowcaseView), which is how the
--           first published board showed its cards with no creature in them.
--   WHEN    a board is drawn while this client holds it (it streams as one
--           Atomic model: its tag arrives and leaves with it) and repainted
--           when one of its attributes, its plot's owner, garden or boost, or
--           the rain changes. Nothing is asked of the server and nothing is
--           re-read on a timer.
--   SHOWN   only on a CLAIMED plot whose garden is KNOWN (EconomyService has
--           published GardenGrown) -- the plaque's own rule, so a garden still
--           being restored never reads NO CREATURES YET. A free plot keeps one
--           word at its gate and nothing else (PlotOwnerLabels), so its board
--           is hidden: every part's LocalTransparencyModifier, the face off.
--   NEAR    its two pictures and its rarity light exist only while the camera
--           is within PreviewNearStuds, and are FREED past PreviewFarStuds --
--           checked every CheckSeconds, never a frame. A TITAN or COLOSSAL
--           word's light is stepped each frame on a near board that has one,
--           the way PlantUI steps the labels'.
--
-- No remote, nothing selectable, nothing that takes a click or a touch.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))
local PlotShowcaseView = require(Shared:WaitForChild("PlotShowcaseView"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SC = GameConfig.Plot.Showcase
local ATTR = GameConfig.Attributes
local TAG_BOARD = GameConfig.Tags.PlotShowcase
local TAG_PLOT = GameConfig.Tags.Plot
local RAIN = GameConfig.Weather.Attributes.Factor
-- What on the plot changes what its board says or whether it stands.
local PLOT_WATCH = { ATTR.OwnerUserId, ATTR.GardenGrown, ATTR.GardenBoost }

type Entry = {
	model: Model,
	plank: BasePart?,
	view: PlotShowcaseView.View?,
	plot: Instance?,
	conns: { RBXScriptConnection },
	plotConns: { RBXScriptConnection },
	shown: boolean,
	near: boolean,
}

local entries: { [Instance]: Entry } = {}

--==============================================================================
-- RE-RUN SAFE
--
-- A Rojo sync re-runs this with the last run's faces still in the PlayerGui
-- (and, from the first build, on the planks) and its hidden boards still
-- hidden: all of it is put back before anything is built.
--==============================================================================
for _, old in ipairs(playerGui:GetChildren()) do
	if old:IsA("SurfaceGui") and old.Name == PlotShowcaseView.GuiName then
		old:Destroy()
	end
end
for _, board in ipairs(CollectionService:GetTagged(TAG_BOARD)) do
	for _, d in ipairs(board:GetDescendants()) do
		if d:IsA("SurfaceGui") and d.Name == PlotShowcaseView.GuiName then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.LocalTransparencyModifier = 0
		end
	end
end

--==============================================================================
-- WHOSE BOARD
--==============================================================================
local function plotFor(model: Instance): Instance?
	local id = model:GetAttribute(ATTR.PlotId)
	if id == nil then
		return nil
	end
	for _, plot in ipairs(CollectionService:GetTagged(TAG_PLOT)) do
		if plot:GetAttribute(ATTR.PlotId) == id then
			return plot
		end
	end
	return nil
end

-- Claimed, and its garden's numbers published: the plaque's rule.
local function standing(plot: Instance?): boolean
	if not plot then
		return false
	end
	local owner = plot:GetAttribute(ATTR.OwnerUserId)
	return type(owner) == "number" and owner > 0 and type(plot:GetAttribute(ATTR.GardenGrown)) == "number"
end

-- The board's wood shown or hidden on this screen only (its parts are the
-- model's own children: PlotShowcase.build).
local function setWood(model: Model, on: boolean)
	local want = if on then 0 else 1
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.LocalTransparencyModifier ~= want then
			d.LocalTransparencyModifier = want
		end
	end
end

--==============================================================================
-- PAINTING
--==============================================================================
local function paint(e: Entry)
	local view = e.view
	if not view then
		return
	end
	local show = standing(e.plot)
	e.shown = show
	setWood(e.model, show)
	PlotShowcaseView.setShown(view, show)
	if not show then
		e.near = false
		return
	end
	PlotShowcaseView.paint(view, PlotShowcase.read(e.model), GameConfig.gardenIncomeMultiplier(e.plot))
	PlotShowcaseView.setPreviews(view, e.near)
	PlotShowcaseView.setActive(view, e.near)
end

-- The face, once the plank is here (an Atomic board arrives whole, so this is
-- at once; ChildAdded is the backstop).
local function attach(e: Entry)
	if e.view then
		return
	end
	local plank = e.model:FindFirstChild("Board")
	if not plank or not plank:IsA("BasePart") then
		return
	end
	e.plank = plank
	-- In the PlayerGui, adorned to the plank: never under the Workspace, where
	-- no ViewportFrame draws.
	e.view = PlotShowcaseView.new(plank, playerGui)
	-- A face outliving its plank would hang in the PlayerGui adorned to
	-- nothing: the plank leaving the world takes the face with it, and the
	-- board arriving again builds a new one.
	table.insert(e.conns, plank.AncestryChanged:Connect(function()
		local view = e.view
		if view and not plank:IsDescendantOf(Workspace) then
			PlotShowcaseView.destroy(view)
			e.view = nil
			e.plank = nil
			e.near = false
		end
	end))
	paint(e)
end

local function watchPlot(e: Entry)
	for _, c in ipairs(e.plotConns) do
		c:Disconnect()
	end
	table.clear(e.plotConns)
	local plot = plotFor(e.model)
	e.plot = plot
	if not plot then
		return
	end
	for _, name in ipairs(PLOT_WATCH) do
		table.insert(e.plotConns, plot:GetAttributeChangedSignal(name):Connect(function()
			paint(e)
		end))
	end
end

local function add(instance: Instance)
	if entries[instance] or not instance:IsA("Model") then
		return
	end
	local model = instance :: Model
	local e: Entry = {
		model = model,
		plank = nil,
		view = nil,
		plot = nil,
		conns = {},
		plotConns = {},
		shown = false,
		near = false,
	}
	entries[model] = e
	watchPlot(e)
	for _, name in ipairs(PlotShowcase.attributeNames()) do
		table.insert(e.conns, model:GetAttributeChangedSignal(name):Connect(function()
			paint(e)
		end))
	end
	table.insert(e.conns, model.ChildAdded:Connect(function()
		attach(e)
	end))
	attach(e)
end

local function remove(instance: Instance)
	local e = entries[instance]
	if not e then
		return
	end
	entries[instance] = nil
	for _, c in ipairs(e.conns) do
		c:Disconnect()
	end
	for _, c in ipairs(e.plotConns) do
		c:Disconnect()
	end
	local view = e.view
	if view then
		PlotShowcaseView.destroy(view)
		e.view = nil
	end
end

local function repaintAll()
	for _, e in pairs(entries) do
		paint(e)
	end
end

--==============================================================================
-- NEAR AND FAR
--
-- The distance every CheckSeconds, with the gap between PreviewNearStuds and
-- PreviewFarStuds as the hysteresis; each frame only a near board's TITAN /
-- COLOSSAL light, and a board with none does nothing at all.
--==============================================================================
local since = 0
RunService.Heartbeat:Connect(function(dt: number)
	since += dt
	local check = since >= SC.CheckSeconds
	if check then
		since = 0
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local t = os.clock()
	for _, e in pairs(entries) do
		local view = e.view
		if view and e.shown then
			if check then
				local plank = e.plank
				local d = if plank and plank.Parent then (plank.Position - eye).Magnitude else math.huge
				local near = if e.near then d <= SC.PreviewFarStuds else d <= SC.PreviewNearStuds
				if near ~= e.near then
					e.near = near
					PlotShowcaseView.setPreviews(view, near)
					PlotShowcaseView.setActive(view, near)
				end
			end
			if e.near and PlotShowcaseView.hasGlint(view) then
				PlotShowcaseView.step(view, t)
			end
		end
	end
end)

for _, board in ipairs(CollectionService:GetTagged(TAG_BOARD)) do
	add(board)
end
CollectionService:GetInstanceAddedSignal(TAG_BOARD):Connect(add)
CollectionService:GetInstanceRemovedSignal(TAG_BOARD):Connect(remove)
-- A plot that replicated after its board: find it and start listening.
CollectionService:GetInstanceAddedSignal(TAG_PLOT):Connect(function()
	for _, e in pairs(entries) do
		if not e.plot or not e.plot.Parent then
			watchPlot(e)
			paint(e)
		end
	end
end)
-- The rain starting or stopping changes every garden's rate at once.
Workspace:GetAttributeChangedSignal(RAIN):Connect(repaintAll)
