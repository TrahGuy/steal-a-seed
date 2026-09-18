--!strict
-- Steal a Seed :: PlantUI
--
-- The hatch timer over anything growing in a plot: two outlined words, no box.
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
-- wants off it is how long is left. That is worth a label. A grown creature is
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
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ReachPoint = require(Shared:WaitForChild("ReachPoint"))

local PLANTING = GameConfig.Plant

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==============================================================================
-- IT BELONGS TO THE POD, NOT TO THE HUD
--
-- The word and the clock were GothamBold and GothamBlack in paper and lime --
-- the same type as the cash readout in the corner of the screen. Nothing about
-- them said they belonged to the pod they were floating over. See
-- GameConfig.Labels.Pod for the face they wear instead (Arcade, since
-- 2026-09-15), and for why the clock changes colour as it runs down.
--==============================================================================
local POD = GameConfig.Labels.Pod
local PROMPT = GameConfig.Labels.Prompt

--==============================================================================
-- ON A TOUCH SCREEN THE TIMER IS DRAWN, NOT BILLBOARDED
--
-- MEASURED on 2026-09-18: a nubkin pod's label sat 3.6 studs above the soil at
-- Tiny and 15.6 at Colossal, as a BillboardGui -- and a billboard cannot be kept
-- on the screen. On a phone, whose landscape viewport is about half the height
-- of a desktop window, a tall pod's timer left the top of the screen for a
-- player standing beside it, and the Instant Hatch button PromptUI stacks above
-- it left first: PromptUI's tracker culls a panel whose centre goes above the
-- screen, and only ever clamped one that was partly on it.
--
-- Two changes, one per cause:
--
--   * THE HEIGHT IS CAPPED, on every device, at POD.MaxAboveSoil. Tiny, Big and
--     Huge keep exactly the height they had; the tall pods come down to eye
--     level. See ReachPoint.podLabelLift.
--   * ON TOUCH THE TIMER IS A LABEL IN A SCREEN LAYER, projected from the pod
--     once a frame and clamped onto the screen TOGETHER WITH the prompt above
--     it, through the same ReachPoint.stack PromptUI calls -- so they come down
--     together and can never land on each other.
--
-- A desktop keeps the billboard: it was never unreadable there, and a billboard
-- is positioned by the engine for free.
--==============================================================================
local TOUCH = UserInputService.TouchEnabled

-- The label's own range, measured from the camera -- the billboard's
-- MaxDistance. On touch it is also where the per-frame placement stops caring.
local DISPLAY_RANGE = 160

local LABEL_SIZE = Vector2.new(POD.Width, POD.Height)
-- The room reserved above the timer for a stacked prompt. Width does not matter
-- to the timer -- each clamps its own width -- only the height does.
local PROMPT_SLOT = Vector2.new(POD.Width, PROMPT.PanelHeight)

local BIND = "SeedPlantUI"

-- The only two things that stand in a bed. There is no sprout any more: nothing
-- grows in the ground, it hatches in your hands.
local STAGE_POD = 1
local STAGE_GROWN = 3

--==============================================================================
-- NO CONTAINER: EACH BILLBOARD STANDS IN PlayerGui ON ITS OWN, AND SURVIVES A DEATH
--
-- They used to live in a Folder here, and that Folder was the reason the
-- countdown vanished. MEASURED in Play on 2026-09-18: a respawn resets
-- PlayerGui, the reset deletes a plain Folder -- it has no ResetOnSpawn to say
-- otherwise -- and every billboard inside went with it. Nothing noticed:
-- `panels` still held the dead billboards, the once-a-second sweep saw a panel
-- for every pod and rebuilt none, and after ONE death the player had no timer
-- on any pod for the rest of the session. 14 planted pods, 0 billboards.
--
-- A BillboardGui is a LayerCollector and carries ResetOnSpawn itself, so each
-- one now sits directly in PlayerGui with it off -- the arrangement
-- PlantPickUI's PICK UP billboard has always had, and which survives.
--
-- RE-RUN SAFE: a new run removes every billboard of this name the last run left
-- behind, and the Folder too if a copy from before this change is still there.
--==============================================================================
local BILLBOARD_NAME = "SeedPlant"
do
	local legacy = playerGui:FindFirstChild("SeedPlantUI")
	if legacy then
		legacy:Destroy()
	end
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("BillboardGui") and child.Name == BILLBOARD_NAME then
			child:Destroy()
		end
	end
end

-- Unbound before anything else is, so a re-run replaces the update instead of
-- adding a second one beside it.
pcall(function()
	RunService:UnbindFromRenderStep(BIND)
end)

--==============================================================================
-- THE TOUCH LAYER
--
-- IgnoreGuiInset, like PromptUI's layer, so positions come straight out of
-- WorldToViewportPoint in window space with no inset arithmetic. DisplayOrder
-- 14 -- one under PromptUI's 15 -- so if a timer and a prompt ever touch, the
-- thing the finger presses is on top.
--==============================================================================
local touchLayer: ScreenGui? = nil
do
	local stale = playerGui:FindFirstChild("SeedPlantUITouch")
	if stale then
		stale:Destroy()
	end
	if TOUCH then
		local made = Instance.new("ScreenGui")
		made.Name = "SeedPlantUITouch"
		made.ResetOnSpawn = false
		made.IgnoreGuiInset = true
		made.DisplayOrder = 14
		made.Parent = playerGui
		touchLayer = made
	end
end

type Panel = {
	model: Model,
	-- The desktop draws a billboard; a touch screen draws `frame` in its layer.
	-- Exactly one of the two exists for any panel.
	billboard: BillboardGui?,
	frame: Frame?,
	-- The pod's anchor part, and how far above it the label's centre sits.
	anchor: BasePart,
	lift: number,
	-- Whether the label has something to say right now. On a desktop this IS
	-- billboard.Enabled; on touch the frame is only drawn while this is true
	-- AND the pod is on the screen and in range.
	showing: boolean,
	-- Last pixel position written on touch, so a pod that is not moving on the
	-- screen does not allocate a new UDim2 every frame.
	lastX: number,
	lastY: number,
	-- The server's Ready flag, heard the moment it lands -- see refresh.
	readyConn: RBXScriptConnection?,
	word: TextLabel,
	timer: TextLabel,
	species: SeedData.Species?,
	-- What THIS plant weighs. The clock is a function of weight, not of form:
	-- a 4 kg Nubkin hatches in half a minute and a 9,000 kg one takes five, and
	-- the two are the same species.
	tier: number,
	plantedAt: number,
	-- The server's own deadline for THIS pod, off the model. The plate counts down
	-- to it and works nothing out for itself; see WHAT IT SAYS.
	hatchAt: number,
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
	-- A pod built before the server stamped deadlines -- or a model seen in the
	-- one frame before the attribute replicates -- falls back to the ladder.
	local hatchAt = tonumber(model:GetAttribute("HatchAt"))
		or (plantedAt + SeedData.GrowSeconds(tier))

	--==========================================================================
	-- A FIXED GAP ABOVE THE REAL TOP -- UNDER A CEILING
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
	--
	-- THE CEILING, since 2026-09-18: never more than POD.MaxAboveSoil above the
	-- soil, which is where a player standing beside a Titan or a Colossal can
	-- actually see it. The soil is the box's lowest point, which ReachPoint reads
	-- off every axis, so the rolled pivot above cannot fool it. PromptUI asks the
	-- same function for the prompt it stacks above this, so the two agree.
	--==========================================================================
	local boxCF, boxSize = model:GetBoundingBox()
	local lift = ReachPoint.podLabelLift(GameConfig.topOfModel(model, anchor),
		anchor.Position.Y - ReachPoint.lowestY(boxCF, boxSize), POD.LiftStuds, POD.MaxAboveSoil)

	local billboard: BillboardGui? = nil
	local panel: Frame
	if not TOUCH then
		local made = Instance.new("BillboardGui")
		made.Name = BILLBOARD_NAME
		made.Adornee = anchor
		made.AlwaysOnTop = true
		-- In GameConfig rather than here, because PromptUI stacks the Instant
		-- Hatch prompt on top of this label and has to know where it ends.
		made.Size = UDim2.fromOffset(POD.Width, POD.Height)
		made.StudsOffset = Vector3.new(0, lift, 0)
		-- Camera-relative, unlike a prompt's activation range -- the lesson
		-- PromptUI paid for. Far enough to read a neighbour's plot from the road,
		-- which is the whole point of showing it to people who do not own it.
		made.MaxDistance = DISPLAY_RANGE
		--======================================================================
		-- BORN OFF, TURNED ON BY refresh()
		--
		-- A BillboardGui defaults to Enabled and both labels are built empty. So
		-- anything that stopped refresh() from running -- it threw once, on a
		-- signature change, and every plant in the game wore a blank dark
		-- rectangle for a session -- left a plate that was never written to and
		-- never switched off. Starting off means a plate is only ever visible
		-- because something actually put text in it.
		--======================================================================
		made.Enabled = false
		-- Not reset by a respawn -- see NO CONTAINER above.
		made.ResetOnSpawn = false
		made.Parent = playerGui
		billboard = made

		--======================================================================
		-- NO BOX
		--
		-- This was a dark rounded plate with a lime keyline, and the owner had
		-- it removed on 2026-09-15: the words stand over the pod on their own.
		-- The frame stays as the layout, fully transparent, with nothing drawn on
		-- it. Each label's own outline is what keeps it readable over sky, grass
		-- and soil.
		--======================================================================
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Size = UDim2.fromScale(1, 1)
		panel.BackgroundTransparency = 1
		panel.BorderSizePixel = 0
		panel.Parent = made
	else
		--======================================================================
		-- THE SAME TWO WORDS, IN THE TOUCH LAYER
		--
		-- Same size, same face, same outline, same transparent layout frame --
		-- only the thing that positions it is different. Born invisible and off
		-- the screen, and placed only by the frame update once it has something
		-- to say and somewhere on the screen to say it.
		--======================================================================
		panel = Instance.new("Frame")
		panel.Name = "SeedPlantTimer"
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Size = UDim2.fromOffset(POD.Width, POD.Height)
		panel.Position = UDim2.fromOffset(-1000, -1000)
		panel.BackgroundTransparency = 1
		panel.BorderSizePixel = 0
		panel.Visible = false
		panel.Parent = touchLayer
	end

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
		frame = if billboard then nil else panel,
		anchor = anchor,
		lift = lift,
		showing = false,
		lastX = -1,
		lastY = -1,
		readyConn = nil,
		word = word,
		timer = timer,
		species = species,
		tier = tier,
		plantedAt = plantedAt,
		hatchAt = hatchAt,
		stage = tonumber(model:GetAttribute("Stage")) or STAGE_POD,
		lastText = "",
	}
end

--==============================================================================
-- WHAT IT SAYS
--
-- Counted down to the DEADLINE THE SERVER STAMPED ON THE POD (HatchAt), which is
-- the same number isReady compares against -- so the plate and the prompt cannot
-- disagree, and a pod planted under an older, shorter timer shows the wait it was
-- actually given rather than today's.
--
-- The client works nothing out for itself and nothing is pushed across: the
-- attribute replicates with the model, so the plate is right on the first frame
-- after a rejoin.
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
	-- Re-read for the same reason Stage is: the server can restamp a pod in place.
	panel.hatchAt = tonumber(model:GetAttribute("HatchAt")) or panel.hatchAt
	panel.tier = tonumber(model:GetAttribute("Tier")) or panel.tier
	if not panel.species then
		panel.species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
	end

	local species = panel.species
	if not species then
		return
	end
	local function hide()
		if panel.showing then
			panel.showing = false
			if panel.billboard then
				panel.billboard.Enabled = false
			end
			if panel.frame then
				panel.frame.Visible = false
			end
			-- Cleared so a plate that is somehow shown again repaints from
			-- scratch rather than trusting a stale key.
			panel.lastText = ""
		end
	end

	if panel.stage ~= STAGE_POD then
		hide()
		return
	end
	local remaining = panel.hatchAt - now

	--==========================================================================
	-- READY. THE PROMPT TAKES IT FROM HERE -- AND THE SERVER SAYS WHEN.
	--
	-- The clock running out on THIS machine's tick and the server attaching its
	-- Hatch prompt on ITS tick are a second apart at worst, and for that second a
	-- timer reading 0:01 stood in the same spot as the prompt replacing it --
	-- the free Hatch prompt rides 2.4 studs above the same anchor. PlantService
	-- sets Ready on the model at the instant it attaches the prompt, so that is
	-- heard as well: whichever arrives first takes the timer down.
	--==========================================================================
	if remaining <= 0 or model:GetAttribute("Ready") == true then
		hide()
		return
	end

	local word, timer = POD.Hatching, clock(remaining)

	local key = word .. "\0" .. timer
	if key == panel.lastText and panel.showing then
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
	-- The pod's OWN full wait, not the ladder's: an old pod's plate has to ripen
	-- over the wait it was planted with.
	local total = math.max(panel.hatchAt - panel.plantedAt, 1)
	local ripeness = math.clamp(1 - remaining / total, 0, 1)
	panel.timer.TextColor3 = POD.ClockYoung:Lerp(POD.ClockReady, ripeness)

	-- Sizes are fixed at build(); nothing here resizes anything every tick. On
	-- touch the frame is drawn by the frame update, which reads `showing`.
	panel.showing = true
	if panel.billboard then
		panel.billboard.Enabled = true
	end
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
			-- One attribute listener per pod -- an event, not a loop -- so the
			-- timer is gone the instant the server says Ready.
			panel.readyConn = model:GetAttributeChangedSignal("Ready"):Connect(function()
				refresh(panel, serverNow())
			end)
			refresh(panel, serverNow())
		end
	end)
end

local function remove(instance: Instance)
	local panel = panels[instance :: Model]
	if panel then
		if panel.readyConn then
			panel.readyConn:Disconnect()
		end
		if panel.billboard then
			panel.billboard:Destroy()
		end
		if panel.frame then
			panel.frame:Destroy()
		end
		panels[instance :: Model] = nil
	end
end

for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Planted)) do
	add(instance)
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(add)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(remove)

--==============================================================================
-- ON TOUCH, WHERE EACH TIMER GOES THIS FRAME
--
-- Only a pod that has something to say, is in front of the camera and is within
-- the label's own range costs anything; the rest are hidden once and skipped.
-- The anchor projects along WORLD up -- the same axis PromptUI uses for the
-- prompt it stacks above this on touch -- and both go through ReachPoint.stack
-- with the same sizes, so the clamp that brings a tall pod's timer back onto the
-- screen brings its prompt down with it.
--==============================================================================
local function placeOnTouch(camera: Camera)
	local viewport = camera.ViewportSize
	local topInset = GuiService:GetGuiInset().Y
	local eye = camera.CFrame.Position
	for _, panel in pairs(panels) do
		local frame = panel.frame
		if not frame then
			continue
		end
		local drawn = false
		if panel.showing and panel.anchor.Parent then
			local world = panel.anchor.Position + Vector3.yAxis * panel.lift
			if (world - eye).Magnitude <= DISPLAY_RANGE then
				local at, inFront = camera:WorldToViewportPoint(world)
				if inFront then
					local centre = ReachPoint.stack(Vector2.new(at.X, at.Y), viewport, topInset,
						LABEL_SIZE, PROMPT_SLOT, PROMPT.StackGap, POD.ScreenMargin)
					local x, y = math.round(centre.X), math.round(centre.Y)
					if x ~= panel.lastX or y ~= panel.lastY then
						panel.lastX, panel.lastY = x, y
						frame.Position = UDim2.fromOffset(x, y)
					end
					drawn = true
				end
			end
		end
		if frame.Visible ~= drawn then
			frame.Visible = drawn
		end
	end
end

--==============================================================================
-- THE TICK, AND THE ONE PLACE ANYTHING HERE RUNS EVERY FRAME
--
-- Once a second for the words, which is all a m:ss clock can show, off an
-- accumulator so it cannot drift; refresh() skips the work entirely when the
-- text has not changed. The sweep below rides the same second.
-- GetInstanceRemovedSignal and GetInstanceAddedSignal only fire for changes this
-- client saw, and a model tagged during the join handshake can land before the
-- listener does -- so the tagged set is reconciled once a second rather than
-- trusted to have been announced. It is a table walk over plants already in the
-- bed; nothing is rebuilt for a model that already has a panel.
--
-- ONE BINDING FOR EVERY POD, as it always was one Heartbeat. It is a render step
-- now, bound just after the camera, because on touch it also places the timers,
-- and a label placed before the camera moves trails the pod it belongs to
-- whenever the player turns -- the lesson PromptUI paid for with its own
-- tracker. On a desktop the per-frame half does nothing at all.
--==============================================================================
local since = 0
RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	since += dt
	if since >= PLANTING.TickSeconds then
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
	end

	if TOUCH then
		local camera = Workspace.CurrentCamera
		if camera then
			placeOnTouch(camera)
		end
	end
end)
