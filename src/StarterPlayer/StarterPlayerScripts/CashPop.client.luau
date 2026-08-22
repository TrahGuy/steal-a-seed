--!strict
-- Steal a Seed :: CashPop
--
-- The lime `+$N` that rises off every grown plant, once a second, for as long as
-- it is standing there.
--
--==============================================================================
-- COSMETIC. THE CLIENT DOES NOT MINT ANYTHING.
--
-- Rule 6 says cash mints in EconomyService and nowhere else, and this does not
-- bend it: nothing here calls AddCash, nothing here is trusted, and a player who
-- edits this script gets prettier numbers and not one extra coin. It reads the
-- same two facts the server pays from -- what is planted, and whether it is
-- grown -- and says them out loud.
--
--==============================================================================
-- IT IS NOT DRIVEN BY WATCHING profile.Cash
--
-- Which would have been easy, and is what SpeedFX does for Speed. It cannot work
-- here. profile.Cash is the SUM of a whole plot: a Nubkin and a Petalpip in the
-- ground together move it by 7, and 7 cannot be aimed at either of them. The
-- point of these pops is that a Bellchime pops +$110 and the Nubkin beside it
-- pops +$2, so you can see which square of dirt is carrying you.
--
-- Nor a remote. A remote per plant per second is 72 packets a second on a full
-- server to say something both ends already know.
--
--==============================================================================
-- EVERYBODY SEES THEM, INCLUDING PEOPLE WHO ARE NOT PAID
--
-- Same reasoning as PlantUI's billboard, which is also drawn for passers-by. A
-- plot is a target, and what a stranger most wants to know from the road is
-- which one of these is worth the walk. Watching somebody else's Bellchime pop
-- +$110 every second is that answer, and it costs them nothing to show you.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INK = Color3.fromRGB(26, 24, 30)
local ACCENT = Color3.fromRGB(142, 196, 62)

-- STAGE_GROWN, as CreatureModel numbers it. Read off the model's own attribute
-- rather than recomputed from PlantedAt: PlantService rebuilds the model at
-- every stage change and stamps the stage on it, so the attribute IS the
-- server's answer and a second calculation here could only ever disagree.
local STAGE_GROWN = 3

-- One second, matching EconomyService's TICK. Not shared through GameConfig
-- because they are two different facts that happen to agree -- one is how often
-- the faucet runs, the other how often a label blinks -- and welding them would
-- mean a pacing change to one silently retimes the other.
local TICK = GameConfig.Plant.TickSeconds

--==============================================================================
-- THE POP STARTS ABOVE THE PLATE, NOT THROUGH IT
--
-- It used to start at top + 0.5, which was under a two-line plate centred at
-- top + 1.2 -- so every pop rose straight through the label. At three lines the
-- plate is 64px tall and that stopped being survivable.
--
-- HONEST LIMITATION: a BillboardGui's SIZE is in PIXELS and its OFFSET is in
-- STUDS, so no single stud value clears a fixed-pixel plate at every distance.
-- Far away the plate is still 64px while 1.2 studs has shrunk to nothing. This
-- is tuned for the range you actually read a plot at; at fifty studs they will
-- still touch, and the alternative is scaling the offset by camera distance
-- every frame for forty billboards.
--==============================================================================
local POP_START_ABOVE = 2.4
local RISE_STUDS = 2.5
local POP_SECONDS = 1.15
-- Same as SpeedFX. Camera-relative, so it is the distance at which you stop
-- being able to read it anyway.
local POP_RANGE = 90

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedCashPop")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedCashPop"
gui.ResetOnSpawn = false
gui.DisplayOrder = 24
gui.Parent = playerGui

--==============================================================================
-- THE POOL
--
-- SpeedFX pools five for one treadmill. This has to serve every grown plant in
-- range at once -- six plots of twelve -- so it is a FREE LIST rather than
-- SpeedFX's round robin. Round robin is fine when pops are seconds apart; here
-- forty can be in flight together and slot 1 coming back around would yank a
-- billboard out from under a tween that is still running.
--
-- Grown on demand up to a cap rather than all built at boot, because a player
-- who never walks near a plot should not pay for forty billboards.
--==============================================================================
local POOL_CAP = 40

local free: { BillboardGui } = {}
local made = 0
-- Billboard -> the part it is currently riding, so a plant destroyed mid-tween
-- can be noticed and its slot handed back rather than left enabled on a corpse.
local active: { [BillboardGui]: BasePart } = {}

local function build(): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Pop"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(96, 30)
	billboard.MaxDistance = POP_RANGE
	billboard.Enabled = false
	billboard.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = ACCENT
	label.Text = ""
	label.Parent = billboard

	-- The heavy ink outline is what makes lime legible over grass, which is the
	-- one colour it would otherwise vanish into. Same thickness as SpeedFX's.
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = INK
	stroke.Parent = label

	return billboard
end

local function release(billboard: BillboardGui)
	if active[billboard] == nil then
		return
	end
	active[billboard] = nil
	billboard.Enabled = false
	billboard.Adornee = nil
	table.insert(free, billboard)
end

local function acquire(): BillboardGui?
	local billboard = table.remove(free)
	if billboard then
		return billboard
	end
	if made >= POOL_CAP then
		return nil
	end
	made += 1
	return build()
end

--==============================================================================
-- WHAT IS PLANTED
--
-- The same tag PlantUI watches, and for the same reason: PlantService destroys
-- and rebuilds the model at every stage change, so the tag leaving and arriving
-- again is the stage change. Nothing here has to be kept in step by hand.
--==============================================================================
type Tracked = {
	anchor: BasePart,
	species: SeedData.Species,
	-- How far above the anchor the top of the plant is. Measured once, because
	-- a rooted plant does not change shape without being rebuilt.
	top: number,
}

local tracked: { [Model]: Tracked } = {}

local function add(instance: Instance)
	if not instance:IsA("Model") or tracked[instance] then
		return
	end
	local model = instance :: Model
	task.spawn(function()
		-- A model can be tagged before its parts have replicated, which is how
		-- ParentAnim once drew nothing for a whole session.
		local deadline = os.clock() + 5
		while not model.PrimaryPart and model.Parent and os.clock() < deadline do
			task.wait(0.1)
		end
		local anchor = model.PrimaryPart
		local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
		if not (anchor and species and model.Parent) then
			return
		end
		if not CollectionService:HasTag(model, GameConfig.Tags.Planted) then
			return
		end
		if tracked[model] then
			return
		end
		tracked[model] = {
			anchor = anchor,
			species = species,
			-- The shared world-space measure, NOT GetBoundingBox -- which reports
			-- in the pivot's frame on these models and hands back the width where
			-- the height should be. PlantUI's name plate uses the same call, so
			-- the pop and the label cannot disagree about where a plant ends.
			top = GameConfig.topOfModel(model, anchor),
		}
	end)
end

local function remove(instance: Instance)
	tracked[instance :: Model] = nil
end

for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Planted)) do
	add(instance)
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(add)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(remove)

--==============================================================================
-- THE POP
--==============================================================================
local rng = Random.new()

local function pop(entry: Tracked)
	local billboard = acquire()
	if not billboard then
		return
	end
	local label = billboard:FindFirstChild("Label") :: TextLabel
	local stroke = label:FindFirstChildOfClass("UIStroke")

	label.Text = "+$" .. GameConfig.compact(SeedData.IncomePerSecond(entry.species))
	label.TextTransparency = 0
	if stroke then
		stroke.Transparency = 0
	end

	-- Sideways jitter, so twelve plants in a bed are not one illegible column of
	-- numbers climbing the screen. Random rather than by pool slot, because the
	-- slot a plant gets changes every second and a jitter derived from it would
	-- make each plant's pops wander.
	local drift = (rng:NextNumber() - 0.5) * 1.7
	local start = Vector3.new(drift, entry.top + POP_START_ABOVE, 0)
	billboard.Adornee = entry.anchor
	billboard.StudsOffset = start
	billboard.Enabled = true
	active[billboard] = entry.anchor

	TweenService:Create(billboard, TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), { StudsOffset = start + Vector3.new(0, RISE_STUDS, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(POP_SECONDS), { TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(POP_SECONDS), { Transparency = 1 }):Play()
	end

	task.delay(POP_SECONDS + 0.05, function()
		release(billboard)
	end)
end

--==============================================================================
-- THE TICK
--
-- Heartbeat with an accumulator rather than a task.wait loop, so it cannot
-- drift -- the same shape PlantUI's clock uses.
--
-- Range-gated before the pool is touched. A pop nobody can read is a pool slot
-- taken away from one they can, and MaxDistance alone would only hide it AFTER
-- it had claimed the billboard.
--==============================================================================
local since = 0

RunService.Heartbeat:Connect(function(dt)
	-- Hand back anything whose plant was destroyed mid-flight. Cheap: `active`
	-- holds only what is in the air right now.
	for billboard, anchor in pairs(active) do
		if not anchor.Parent then
			release(billboard)
		end
	end

	since += dt
	if since < TICK then
		return
	end
	since = 0

	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else nil

	for model, entry in pairs(tracked) do
		if not (model.Parent and entry.anchor.Parent) then
			tracked[model] = nil
		elseif model:GetAttribute("Stage") == STAGE_GROWN then
			-- Pods and sprouts pop nothing. They are not earning yet.
			if not eye or (entry.anchor.Position - eye).Magnitude <= POP_RANGE then
				pop(entry)
			end
		end
	end
end)
