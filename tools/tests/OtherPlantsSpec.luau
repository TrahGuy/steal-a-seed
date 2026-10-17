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
--   * PERFORMANCE MODE (2026-10-11, the owner: the switch was OTHER PLANTS):
--     ON hides the other gardens through the same preference, inverted, and
--     holds Reduced FX on in the one value every effect reads; OFF gives the
--     player's own Reduced FX back, never switching off one they set; the
--     switch's words, its bolt, and Settings showing Reduced FX forced on
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
	-- ULTRA (2026-10-13): this player's own grown plants too; their pods never.
	local mineUltra = with("owner", ME)
	mineUltra.hideOwn = true
	local podUltra = table.clone(mineUltra)
	podUltra.stage = CreatureModel.STAGE_POD
	local othersShown = with("showOthers", true)
	othersShown.hideOwn = true
	check(H(mineUltra) == true and not H(podUltra) and not H(othersShown) and H(with("hideOwn", true)) == true,
		"ULTRA: this player's own grown plants hidden too, their pods in the beds never; others' by the preference")
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
	-- ULTRA (2026-10-13): this player's own grown plant hides too; their pod stays.
	local minePod = plant(plantsB, CreatureModel.STAGE_POD)
	PlantVisibility.setHideOwn(viewer, true)
	settle()
	check(mine:GetAttribute(MARK) == true and minePod:GetAttribute(MARK) == nil and grownA:GetAttribute(MARK) == true,
		"ULTRA: this player's own grown plant hidden too, their pod in the bed shown, the others' still hidden")
	PlantVisibility.setHideOwn(viewer, false)
	settle()
	check(mine:GetAttribute(MARK) == nil and grownA:GetAttribute(MARK) == true,
		"back to ON: their own plant shown again, the others' still hidden")
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
		and ui2:find("local nextLevel = PerformanceMode.nextLevel(PerformanceMode.level(player))\n"
			.. "\tPerformanceMode.setLevel(player, nextLevel)", 1, true) ~= nil
		and not ui2:find("FireServer", 1, true),
		"OtherPlantsUI steps the local preferences (through PerformanceMode) and starts the one watcher; nothing "
			.. "goes to the server")
	-- No invisible pick-ups (ULTRA, 2026-10-13): PlantPickUI passes a plant this
	-- screen hides, and lets a selection go when its plant hides.
	local pick = src(SPS, "PlantPickUI")
	check(pick:find("if marker and not PlantVisibility.isHidden(child) then", 1, true) ~= nil
			and pick:find("model:GetAttributeChangedSignal(PlantVisibility.Marker):Connect(function()\n"
				.. "\t\tif PlantVisibility.isHidden(model) then\n\t\t\tclearSelection()", 1, true) ~= nil,
		"PICK UP: a hidden plant is never under the pointer, and a selected one hidden is let go")
	local vis = src(Shared, "PlantVisibility")
	check(not vis:find(":Destroy()", 1, true) and not vis:find(".Parent = ", 1, true)
		and not vis:find("orkspace:GetDescendants", 1, true) and not vis:find("game:GetDescendants", 1, true)
		and not vis:find("Heartbeat", 1, true) and not vis:find("RenderStepped", 1, true) and not vis:find("FireServer", 1, true),
		"PlantVisibility never destroys or reparents, never scans the Workspace, runs no loop and sends nothing")

	--==========================================================================
	say("5. PERFORMANCE MODE: the switch, and Reduced FX with it")
	--==========================================================================
	-- Shared/PerformanceMode from its source, with this run's PlantVisibility,
	-- on a stand-in player (attributes on a real instance).
	local perfSrc = src(Shared, "PerformanceMode")
	local perfChunk = assert(loadstring(perfSrc, "=PerformanceMode"))
	setfenv(perfChunk, setmetatable({ script = Shared.PerformanceMode, require = function(m)
		if typeof(m) == "Instance" and m.Name == "PlantVisibility" then
			return PlantVisibility
		end
		return require(m)
	end }, { __index = getfenv(1) }))
	local Perf = perfChunk()
	local OP = GameConfig.OtherPlants
	local QUALITY = GameConfig.Afterimage.QualityAttribute
	local you = Instance.new("Configuration")
	you.Name = "PerformanceModeSpecPlayer"
	local function q()
		return you:GetAttribute(QUALITY)
	end
	check(Perf.isOn(you) == false and PlantVisibility.showOthers(you) and q() == nil,
		"a new session starts OFF: everything shown, as OTHER PLANTS: ON was -- nobody's view changes")
	Perf.set(you, true)
	check(Perf.isOn(you) and you:GetAttribute(OP.Attribute) == false and q() == "Off"
			and you:GetAttribute(OP.OwnQualityAttribute) == Perf.Unset and Perf.ownReduced(you) == false,
		"ON: the other gardens hidden (the one preference, inverted) and Reduced FX on; the player's own choice "
			.. "(none yet) put aside")
	Perf.set(you, true)
	check(you:GetAttribute(OP.OwnQualityAttribute) == Perf.Unset,
		"ON twice: the own choice is put aside once, never overwritten by Performance Mode's own Off")
	Perf.set(you, false)
	check(not Perf.isOn(you) and PlantVisibility.showOthers(you) and q() == Perf.deviceQuality()
			and you:GetAttribute(OP.OwnQualityAttribute) == nil,
		"OFF: everything shown; never chosen, Reduced FX goes back to the screen's default, as Settings gives it back",
		tostring(q()))
	you:SetAttribute(QUALITY, "Off")
	Perf.set(you, true)
	local ownWhileOn = Perf.ownReduced(you)
	Perf.set(you, false)
	check(ownWhileOn and q() == "Off",
		"a Reduced FX the player switched on themselves stays on when Performance Mode turns off", tostring(q()))
	you:SetAttribute(QUALITY, "Reduced")
	Perf.set(you, true)
	local whileOn = q()
	Perf.set(you, false)
	check(whileOn == "Off" and q() == "Reduced", "and a Reduced quality comes back as it was", tostring(q()))
	-- THE THREE LEVELS (2026-10-13): the cycle, and each level's preferences.
	check(Perf.nextLevel("off") == "on" and Perf.nextLevel("on") == "ultra" and Perf.nextLevel("ultra") == "off"
			and Perf.nextLevel("??") == "off" and #Perf.Levels == 3,
		"one press steps OFF, ON, ULTRA, then OFF again")
	Perf.setLevel(you, "ultra")
	local ultraOk = Perf.level(you) == "ultra" and Perf.isOn(you) and PlantVisibility.hideOwn(you)
		and not PlantVisibility.showOthers(you) and q() == "Off"
	Perf.setLevel(you, "on")
	local onOk = Perf.level(you) == "on" and not PlantVisibility.hideOwn(you) and not PlantVisibility.showOthers(you)
	Perf.setLevel(you, "ultra")
	Perf.setLevel(you, "off")
	local offOk = Perf.level(you) == "off" and not PlantVisibility.hideOwn(you) and PlantVisibility.showOthers(you)
		and q() == "Reduced"
	Perf.setLevel(you, "ultra")
	Perf.set(you, true)
	local setOnOk = Perf.level(you) == "on"
	check(ultraOk and onOk and offOk and setOnOk,
		"ULTRA: ON's work and this player's own plants hidden too; ON: theirs shown; OFF: everything, Reduced FX given "
			.. "back; set(true) is ON, never ULTRA")
	you:Destroy()
	-- The rule lives in the one value every Reduced-FX-aware effect reads.
	local statusText = src(Shared, "StatusText")
	check(statusText:find('player:GetAttribute(GameConfig.Afterimage.QualityAttribute) == "Off"', 1, true) ~= nil
			and perfSrc:find('player:SetAttribute(QUALITY, "Off")', 1, true) ~= nil,
		"reduced = own OR Performance Mode, kept in the quality attribute StatusText.reducedMotion and the effects read")
	-- The effects that built once and kept it now follow a live switch (an audit
	-- of every Reduced FX reader, 2026-10-11): the Pod Rush's nest rings rebuild
	-- breathing or still; RarityFX's step redraws both ways (RarityFXSpec).
	local rush = src(SPS, "PodRushUI")
	check(rush:find("local breathe = not ringsStill", 1, true) ~= nil
			and rush:find("if on == ringsOn and (not on or still == ringsStill) then", 1, true) ~= nil,
		"the Pod Rush's nest rings follow Reduced FX switched mid-Rush: built again, breathing or still")
	-- The switch.
	check(ui2:find("local level = PerformanceMode.level(player)", 1, true) ~= nil
			and ui2:find("label.Text = if inlineRow then OTHERS.RowLabel else OTHERS.Label\n", 1, true) ~= nil
			and ui2:find("bolt.Text = OTHERS.Icon", 1, true) ~= nil and ui2:find("bolt.Parent = thumb", 1, true) ~= nil
			and ui2:find("stateWord.Visible = not inlineRow and level ~= \"ultra\"", 1, true) ~= nil
			and ui2:find("local x = if level == \"ultra\" then trackW - thumbW elseif level == \"on\" then "
				.. "math.floor((trackW - thumbW - 1) / 2) else 0", 1, true) ~= nil,
		"the switch: PERFORMANCE MODE, the bolt riding its thumb at the left, middle or right; OFF or ON beside it off "
			.. "a phone's row, and no word for ULTRA (the owner: a spark instead)")
	check(ui2:find("aura.Size = UDim2.new(1, 2, 1, 2)", 1, true) ~= nil and ui2:find("auraLine.Thickness = 1.5", 1, true) ~= nil
			and ui2:find("track.Position = if right then UDim2.new(1, -3, 0, TRACK_Y) else UDim2.fromOffset(3, TRACK_Y)", 1,
				true) ~= nil
			and ui2:find("local wantSpark, still = level == \"ultra\", PerformanceMode.ownReduced(player)", 1, true) ~= nil
			and ui2:find("Enum.EasingDirection.InOut, -1, true, (i - 1) * OTHERS.Stagger), { Scale = 1 })", 1, true) ~= nil
			and ui2:find("s.scale.Scale = OTHERS.StillScale", 1, true) ~= nil and not ui2:find("ParticleEmitter", 1, true)
			and ui2:find("local ULTRA_FACE = OTHERS.UltraFace", 1, true) ~= nil and #OP.UltraFace == 3,
		"ULTRA's sparks: stars twinkling inside the thumb and an aura round it, inside the 3 px the track keeps from "
			.. "the switch's edge; still under Reduced Motion; no particles in the world")
	check(ui2:find("if nextLevel == \"ultra\" then\n\t\tNotice.post({ kind = \"info\", title = OTHERS.UltraNotice.Title", 1,
				true) ~= nil
			and OP.UltraNotice.Title == "YOUR SPROUTS ARE HIDDEN TOO" and OP.UltraNotice.Detail == "They still grow and earn.",
		"reaching ULTRA says once that the player's own plants are hidden too, and still grow and earn")
	-- OFF and ON fit beside the thumb where they are drawn (the rail's and
	-- compact's tracks), in LuckiestGuy at the word's size.
	local function num(name)
		return tonumber(string.match(ui2, "local " .. name .. " = (%d+)"))
	end
	local thumbW, wordSize = tonumber(string.match(ui2, "local THUMB = Vector2.new%((%d+),")), num("WORD_SIZE")
	local fits, worst = thumbW ~= nil and wordSize ~= nil, ""
	for _, trackW in ipairs({ num("TRACK_WIDE"), num("TRACK_NARROW") }) do
		if not (trackW and fits) then
			fits = false
			break
		end
		local off = game:GetService("TextService"):GetTextSize("OFF", wordSize, Enum.Font.LuckiestGuy, Vector2.new(400, 40)).X
		local on = game:GetService("TextService"):GetTextSize("ON", wordSize, Enum.Font.LuckiestGuy, Vector2.new(400, 40)).X
		local onRoom = trackW - math.floor((trackW - thumbW - 1) / 2) - thumbW - 2
		if off > trackW - thumbW - 2 or on > onRoom then
			fits = false
		end
		worst ..= string.format("%d: OFF %.1f/%d, ON %.1f/%d; ", trackW, off, trackW - thumbW - 2, on, onRoom)
	end
	check(fits, "OFF beside the left thumb and ON beside the middle one fit both tracks", worst)
	-- A phone's 128 x 28 row: the thumb alone (no word), its three places in the
	-- 40-px track, the aura (1 px and a 1.5-px line) inside the row's own pad.
	local ROW = require(Shared:WaitForChild("HudLayout")).Config.Phone.Switch
	check(ROW.W == 128 and ROW.H == 28 and ROW.Thumb < ROW.Track.X and ROW.PadRight >= 3
			and ROW.Thumb + 2 * 2.5 <= ROW.H,
		"a phone's row: the coloured thumb alone, left, middle or right, its sparks and aura inside the row",
		string.format("track %d x %d, thumb %d, pad %d", ROW.Track.X, ROW.Track.Y, ROW.Thumb, ROW.PadRight))
	check(OP.Label == "PERFORMANCE MODE" and OP.Icon == "\u{26A1}" and OP.OnText == "ON" and OP.OffText == "OFF",
		"its words: PERFORMANCE MODE, ON / OFF, and U+26A1 -- a colour emoji, seen drawing in LuckiestGuy in a capture")
	-- Settings: REDUCED FX shown forced on while Performance Mode holds it.
	local settings = src(SPS, "SettingsUI")
	check(settings:find("if forced then\n\t\treducedToggle.face.style(\"off\")", 1, true) ~= nil
			and settings:find("\"ON WHILE PERFORMANCE MODE IS ON\"", 1, true) ~= nil
			and settings:find("reducedToggle.button.Activated:Connect(function()\n\tif PerformanceMode.isOn(player) then\n\t\treturn", 1, true) ~= nil
			and settings:find("player:GetAttributeChangedSignal(GameConfig.OtherPlants.Attribute):Connect(paintReduced)", 1, true) ~= nil,
		"Settings: REDUCED FX shown ON and locked while Performance Mode holds it, saying why; the own choice untouched")
end)

PlantVisibility.stop()
fixture:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("OtherPlantsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
