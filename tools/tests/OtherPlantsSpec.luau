--!nocheck
--==============================================================================
-- Steal a Seed :: OtherPlantsSpec (2026-10-05, the owner's OTHER PLANTS brief)
--
-- PlantVisibility in Edit, on stand-ins in a Workspace fixture far from the map:
--
--   * the rule: hidden only when OFF, planted, in a plot, GROWN, the plot's
--     owner known and somebody else; anything unknown answers visible
--   * one model hidden and shown again exactly as it was: each part's own
--     Transparency untouched (an invisible-by-design Base stays invisible), the
--     local modifier each part, decal, emitter, beam and trail had put back, and
--     every Enabled effect -- billboards, surface guis, prompts, highlights -- as
--     it was MEANT to be, including one another script switched on while hidden
--   * lights left to PlantGlow, which reads the marker: off while hidden, back
--     to night-and-authored when shown -- a light first seen while hidden keeps
--     its authored value
--   * new parts and effects while hidden are hidden; ones that leave go as they
--     were
--   * the watcher, through the tag's own signals: the preference toggled back
--     and forth, a pod that becomes grown, an owner arriving, changing and
--     leaving, a plant moved to another plot, a model streamed out and back --
--     and no connection left behind (the census)
--
-- NOT here, seen in the guarded Play: real plots and plants from PlantService,
-- the labels and pops that follow the marker, the switch on a real screen.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local CreatureModel = require(Shared.CreatureModel)
local PlantGlow = require(Shared.PlantGlow)

--==============================================================================
-- THIS RUN'S OWN PLANTED TAG
--
-- A watcher that a deliberately broken copy of the module once left running
-- in this Studio session (the mutant that keeps two watchers) listens for the
-- real tag for as long as Studio is open, and would hide this run's stand-ins
-- under it. So this run loads PlantVisibility from its own source with a
-- GameConfig whose Planted tag is this run's alone -- every other value is the
-- real one -- and its stand-ins carry that tag. The game's tag, and the frozen
-- GameConfig, are untouched.
--==============================================================================
local TAGS = setmetatable({ Planted = string.format("ZZPlantedSpec_%d", math.floor(os.clock() * 1000) % 100000000) },
	{ __index = GameConfig.Tags })
local SpecConfig = setmetatable({ Tags = TAGS }, { __index = GameConfig })
local VIS_SOURCE = Shared.PlantVisibility.Source
local PlantVisibility
do
	local target = Shared.PlantVisibility
	local chunk = assert(loadstring(VIS_SOURCE, "=PlantVisibility"))
	setfenv(chunk, setmetatable({
		script = target,
		require = function(m)
			if typeof(m) == "Instance" and m.Name == "GameConfig" then
				return SpecConfig
			end
			return require(m)
		end,
	}, { __index = getfenv(1) }))
	PlantVisibility = chunk()
end
local OWNER = GameConfig.Attributes.OwnerUserId
local PREF = GameConfig.OtherPlants.Attribute
local MARK = PlantVisibility.Marker

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end

local function near(a, b)
	return math.abs(a - b) < 1e-4
end

-- Deferred signals arrive after the write: give them a beat.
local function settle()
	task.wait()
	task.wait()
end

local fixture = Instance.new("Folder")
fixture.Name = "ZZOtherPlantsSpec"
fixture.Parent = Workspace

-- A stand-in for the local player: attributes on a real instance, a user id.
local holder = Instance.new("Configuration")
holder.Parent = fixture
local ME = 1001
local viewer = {
	UserId = ME,
	GetAttribute = function(_, k)
		return holder:GetAttribute(k)
	end,
	SetAttribute = function(_, k, v)
		holder:SetAttribute(k, v)
	end,
	GetAttributeChangedSignal = function(_, k)
		return holder:GetAttributeChangedSignal(k)
	end,
}

local function plot(owner)
	local m = Instance.new("Model")
	m.Name = "SpecPlot"
	m:SetAttribute(OWNER, owner)
	local plants = Instance.new("Folder")
	plants.Name = GameConfig.Plot and GameConfig.Plot.PlantsFolderName or "Plants"
	plants.Parent = m
	m.Parent = fixture
	CollectionService:AddTag(m, TAGS.Plot)
	return m, plants
end

-- A plant the way CreatureModel builds one: an invisible Base, a body, a decal,
-- and the effects a plant can carry.
local function plant(parent, stage)
	local m = Instance.new("Model")
	m.Name = "SpecPlant"
	m:SetAttribute("Stage", stage)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Transparency = 1
	base.Anchored = true
	base.Parent = m
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Transparency = 0.25
	body.Anchored = true
	body.Position = Vector3.new(0, 6000, 0)
	body.Parent = m
	local decal = Instance.new("Decal")
	decal.Parent = body
	local att = Instance.new("Attachment")
	att.Parent = body
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = true
	emitter.Parent = att
	local beam = Instance.new("Beam")
	beam.Parent = body
	local light = Instance.new("PointLight")
	light.Enabled = true
	light.Parent = body
	local dim = Instance.new("SurfaceGui")
	dim.Enabled = false
	dim.Parent = body
	local label = Instance.new("BillboardGui")
	label.Enabled = true
	label.Parent = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.Enabled = true
	prompt.Parent = body
	local glow = Instance.new("Highlight")
	glow.Enabled = true
	glow.Parent = m
	-- Off by its author, and never switched: must come back off.
	local quiet = Instance.new("BillboardGui")
	quiet.Enabled = false
	quiet.Parent = body
	m.Parent = parent
	CollectionService:AddTag(m, TAGS.Planted)
	return m, { base = base, body = body, decal = decal, emitter = emitter, beam = beam, light = light, dim = dim,
		label = label, prompt = prompt, glow = glow, quiet = quiet }
end

local ok, err = pcall(function()
	PlantVisibility.stop()

	--==========================================================================
	say("1. The rule")
	--==========================================================================
	local H = PlantVisibility.hides
	local base = { showOthers = false, planted = true, inPlot = true, stage = 3, owner = 2002, viewer = ME }
	local function with(k, v)
		local f = table.clone(base)
		f[k] = v
		return f
	end
	check(PlantVisibility.GROWN == CreatureModel.STAGE_GROWN, "GROWN is CreatureModel's own stage number")
	check(H(base) == true, "OFF, planted, in a plot, grown, somebody else's: hidden")
	check(not H(with("showOthers", true)), "ON: never")
	check(not H(with("owner", ME)), "this player's own: never")
	check(not H(with("stage", CreatureModel.STAGE_POD)) and not H(with("stage", nil)) and not H(with("stage", "3")),
		"a pod in the ground, or no stage yet: never")
	check(not H(with("owner", 0)) and not H(with("owner", nil)) and not H(with("owner", 0 / 0)) and not H(with("owner", "2002")),
		"an owner not known yet (0, nil, NaN, a string): visible until it is")
	check(not H(with("planted", false)) and not H(with("inPlot", false)),
		"not tagged Planted (a pod on the road, a carried one, a viewport clone), or not in a plot: never")
	check(H(with("owner", -2)) == true, "a Studio test player's negative id is a real owner")
	check(PlantVisibility.showOthers(viewer) == true, "the preference starts ON (no attribute)")
	PlantVisibility.setShowOthers(viewer, false)
	check(PlantVisibility.showOthers(viewer) == false and holder:GetAttribute(PREF) == false, "OFF is the attribute false")
	PlantVisibility.setShowOthers(viewer, true)
	check(PlantVisibility.showOthers(viewer) == true and holder:GetAttribute(PREF) == true, "and ON true")

	--==========================================================================
	say("2. One model hidden, and shown again exactly as it was")
	--==========================================================================
	local _, plants = plot(2002)
	local m, p = plant(plants, 3)
	p.body.LocalTransparencyModifier = 0.4
	local shade = PlantVisibility.hideModel(m)
	settle()
	check(p.base.LocalTransparencyModifier == 1 and p.body.LocalTransparencyModifier == 1 and p.decal.LocalTransparencyModifier == 1
		and p.emitter.LocalTransparencyModifier == 1 and p.beam.LocalTransparencyModifier == 1,
		"parts, decals, the emitter and the beam: the local modifier at 1")
	check(p.base.Transparency == 1 and p.body.Transparency == 0.25 and p.emitter.Enabled == true,
		"their own Transparency and the emitter's Enabled untouched")
	check(not p.dim.Enabled and not p.label.Enabled and not p.prompt.Enabled and not p.glow.Enabled,
		"the billboard, the surface gui, the prompt and the highlight off")
	check(p.light.Enabled == true, "the light is left as it is: PlantGlow's to switch")
	check(m:GetAttribute(MARK) == true and PlantVisibility.isHidden(m) and PlantVisibility.isHidden(p.emitter)
		and PlantVisibility.plantOf(p.emitter) == m, "the model carries the marker; isHidden answers from any part of it")
	-- Somebody switches the surface gui on while it is hidden.
	p.dim.Enabled = true
	settle()
	check(p.dim.Enabled == false, "a gui another script switches on while hidden stays off here")
	-- New pieces while hidden.
	local late = Instance.new("Part")
	late.Anchored = true
	late.Parent = m
	local lateGui = Instance.new("SurfaceGui")
	lateGui.Enabled = true
	lateGui.Parent = late
	settle()
	check(late.LocalTransparencyModifier == 1 and lateGui.Enabled == false, "a part and a gui added while hidden are hidden")
	local leaving = Instance.new("PointLight")
	leaving.Enabled = true
	leaving.Parent = p.body
	settle()
	leaving.Parent = fixture
	settle()
	check(leaving.Enabled == true, "an effect that leaves the plant goes as it was")
	leaving:Destroy()
	PlantVisibility.showModel(shade)
	settle()
	check(p.base.LocalTransparencyModifier == 0 and near(p.body.LocalTransparencyModifier, 0.4) and p.decal.LocalTransparencyModifier == 0
		and p.emitter.LocalTransparencyModifier == 0 and late.LocalTransparencyModifier == 0,
		"shown: each modifier back as it was (the body's 0.4 too)", p.body.LocalTransparencyModifier)
	check(p.base.Transparency == 1 and p.body.Transparency == 0.25, "the invisible Base is still invisible")
	check(p.light.Enabled and p.label.Enabled and p.prompt.Enabled and p.glow.Enabled and lateGui.Enabled,
		"what was on is on")
	check(p.quiet.Enabled == false, "and what its author left off is still off: nothing blindly enabled")
	check(p.dim.Enabled == true, "the gui switched on while hidden comes on: what it was MEANT to be")
	check(m:GetAttribute(MARK) == nil and not PlantVisibility.isHidden(m), "the marker goes")
	local extra = Instance.new("Part")
	extra.Parent = m
	settle()
	check(extra.LocalTransparencyModifier == 0, "and nothing is hidden any more after it")
	m:Destroy()

	--==========================================================================
	say("2b. The lights: PlantGlow's switch, which reads the marker")
	--==========================================================================
	PlantGlow.Reset()
	PlantGlow.SetNight(true)
	local lit, litParts = plant(plants, 3)
	PlantGlow.Watch(lit)
	check(litParts.light.Enabled == true, "at night an authored-on light is on")
	local litShade = PlantVisibility.hideModel(lit)
	PlantGlow.Refresh(lit) -- PlantSway does this on the marker's own signal
	check(litParts.light.Enabled == false, "hidden: PlantGlow switches it off")
	local freshLight = Instance.new("PointLight")
	freshLight.Enabled = true
	freshLight.Parent = litParts.body
	PlantGlow.Add(lit, freshLight)
	check(freshLight.Enabled == false and freshLight:GetAttribute("SeedGlowAuthored") == true,
		"a light first seen while hidden: off, and its authored ON captured -- not the off it is shown with")
	PlantVisibility.showModel(litShade)
	PlantGlow.Refresh(lit)
	check(litParts.light.Enabled == true and freshLight.Enabled == true, "shown at night: both back on")
	PlantGlow.SetNight(false)
	check(litParts.light.Enabled == false and freshLight.Enabled == false, "and by day both off, as ever")
	PlantGlow.Reset()
	lit:Destroy()

	--==========================================================================
	say("3. The watcher: the preference, the stage, the owner, the plot, streaming")
	--==========================================================================
	local plotA, plantsA = plot(2002)
	local plotB, plantsB = plot(ME)
	local grownA, partsA = plant(plantsA, 3)
	local podA = plant(plantsA, CreatureModel.STAGE_POD)
	local mine = plant(plantsB, 3)
	PlantVisibility.setShowOthers(viewer, true)
	PlantVisibility.start(viewer)
	settle()
	local c = PlantVisibility.census()
	check(c.tracked == 3 and c.hidden == 0 and c.plots == 2, "ON: three plants tracked, none hidden, one owner watch per plot",
		string.format("%d/%d/%d", c.tracked, c.hidden, c.plots))
	PlantVisibility.setShowOthers(viewer, false)
	settle()
	check(grownA:GetAttribute(MARK) == true and podA:GetAttribute(MARK) == nil and mine:GetAttribute(MARK) == nil
		and partsA.body.LocalTransparencyModifier == 1,
		"OFF: only the other player's grown plant hides -- their pod and this player's own plant stay")
	podA:SetAttribute("Stage", 3)
	settle()
	check(podA:GetAttribute(MARK) == true, "their pod grown while OFF: hidden the moment it is")
	local fresh = plant(plantsA, 3)
	settle()
	check(fresh:GetAttribute(MARK) == true and PlantVisibility.census().tracked == 4, "a plant built while OFF: hidden on arrival")
	plotA:SetAttribute(OWNER, 0)
	settle()
	check(grownA:GetAttribute(MARK) == nil and fresh:GetAttribute(MARK) == nil, "the owner leaves (0): shown, nothing unknown is hidden")
	plotA:SetAttribute(OWNER, 3003)
	settle()
	check(grownA:GetAttribute(MARK) == true, "a new owner arrives: hidden again")
	plotA:SetAttribute(OWNER, ME)
	settle()
	check(grownA:GetAttribute(MARK) == nil and partsA.body.LocalTransparencyModifier == 0, "the plot becomes this player's: shown")
	plotA:SetAttribute(OWNER, 2002)
	settle()
	grownA.Parent = plantsB
	settle()
	check(grownA:GetAttribute(MARK) == nil and PlantVisibility.census().plots == 2,
		"moved into this player's plot: shown, and the owner watches follow it")
	grownA.Parent = plantsA
	settle()
	check(grownA:GetAttribute(MARK) == true, "moved back: hidden")
	-- Streamed out (out of the DataModel) and back in.
	fresh.Parent = nil
	settle()
	check(PlantVisibility.census().tracked == 3 and fresh:GetAttribute(MARK) == nil,
		"streamed out: forgotten, and put back as it was on the way out")
	fresh.Parent = plantsA
	settle()
	check(PlantVisibility.census().tracked == 4 and fresh:GetAttribute(MARK) == true, "streamed back in: tracked and hidden again")
	-- Back and forth, and nothing piles up.
	local before = PlantVisibility.census()
	for _ = 1, 25 do
		PlantVisibility.setShowOthers(viewer, true)
		settle()
		PlantVisibility.setShowOthers(viewer, false)
		settle()
	end
	local after = PlantVisibility.census()
	check(after.tracked == before.tracked and after.hidden == before.hidden and after.plots == before.plots,
		"twenty-five toggles: the same models tracked, hidden and watched", string.format("%d/%d/%d", after.tracked, after.hidden, after.plots))
	PlantVisibility.setShowOthers(viewer, true)
	settle()
	check(PlantVisibility.census().hidden == 0 and partsA.body.LocalTransparencyModifier == 0 and partsA.light.Enabled
		and partsA.label.Enabled and partsA.prompt.Enabled,
		"ON: every model back, each as it was")
	-- A second start replaces the first: one watcher.
	PlantVisibility.setShowOthers(viewer, false)
	settle()
	PlantVisibility.start(viewer)
	settle()
	local again = PlantVisibility.census()
	check(again.tracked == 4 and again.hidden == 3, "a second start keeps one watcher, the same answer",
		string.format("%d/%d", again.tracked, again.hidden))
	PlantVisibility.stop()
	settle()
	check(PlantVisibility.census().tracked == 0 and grownA:GetAttribute(MARK) == nil and partsA.body.LocalTransparencyModifier == 0,
		"stopped: everything shown, nothing tracked")
	plotA:Destroy()
	plotB:Destroy()

	--==========================================================================
	say("4. The scripts that draw for a plant ask the marker")
	--==========================================================================
	local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
	local function src(parent, name)
		local found = parent:FindFirstChild(name)
		return if found then found.Source else ""
	end
	local sway, ui, pop, idle = src(SPS, "PlantSway"), src(SPS, "PlantUI"), src(SPS, "CashPop"), src(SPS, "SecretIdle")
	local glow, aura = src(Shared, "PlantGlow"), src(Shared, "PlantAura")
	check(sway:find("model:GetAttributeChangedSignal(HIDDEN):Connect(function()\n\t\t\t\tPlantGlow.Refresh(model)", 1, true) ~= nil
		and sway:find("elseif entry.model:GetAttribute(HIDDEN) == true then", 1, true) ~= nil
		and sway:find("wake[model] = true", 1, true) ~= nil and sway:find("table.clear(wake)", 1, true) ~= nil,
		"PlantSway: a hidden plant is passed by in the slice, its lights refreshed on the marker, and posed at once when shown")
	check(glow:find("local want = night and authored and not (model ~= nil and model:GetAttribute(HIDDEN) == true)", 1, true) ~= nil,
		"PlantGlow: hidden is one more reason for off")
	check(aura:find("pulse.state.model:GetAttribute(HIDDEN) == true then", 1, true) ~= nil
		and aura:find("if model:GetAttribute(HIDDEN) == true then\n\t\t\t\tstate.nextAt", 1, true) ~= nil,
		"PlantAura: a hidden Colossal's arc ends, and none starts")
	check(idle:find("if rig and model:GetAttribute(HIDDEN) == true then\n\t\t\tcontinue", 1, true) ~= nil,
		"SecretIdle: a hidden rig does not step")
	check(ui:find("if not panel.selected and not panel.hidden and panel.anchor.Parent then", 1, true) ~= nil
		and ui:find("model:GetAttributeChangedSignal(HIDDEN):Connect(function()", 1, true) ~= nil,
		"PlantUI: a hidden plant's label is off -- its rarity light and the height CashPop reads with it")
	check(pop:find("model:GetAttribute(PlantVisibility.Marker) ~= true", 1, true) ~= nil
		and pop:find("if not anchor.Parent or PlantVisibility.isHidden(anchor) then", 1, true) ~= nil,
		"CashPop: no pop over a hidden plant, and one in the air over it is put away")
	local ui2 = src(SPS, "OtherPlantsUI")
	check(ui2:find("PlantVisibility.start(player)", 1, true) ~= nil
		and ui2:find("PlantVisibility.setShowOthers(player, not PlantVisibility.showOthers(player))", 1, true) ~= nil
		and not ui2:find("FireServer", 1, true),
		"OtherPlantsUI flips the one local preference and starts the one watcher; nothing goes to the server")
	local vis = src(Shared, "PlantVisibility")
	check(not vis:find(":Destroy()", 1, true) and not vis:find(".Parent = ", 1, true)
		and not vis:find("orkspace:GetDescendants", 1, true) and not vis:find("game:GetDescendants", 1, true)
		and not vis:find("Heartbeat", 1, true) and not vis:find("RenderStepped", 1, true) and not vis:find("FireServer", 1, true),
		"PlantVisibility never destroys or reparents, never scans the Workspace, runs no loop and sends nothing")
end)

PlantVisibility.stop()
fixture:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("OtherPlantsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
