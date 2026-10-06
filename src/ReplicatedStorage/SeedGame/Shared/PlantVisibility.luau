--!strict
--==============================================================================
-- Steal a Seed :: PlantVisibility (2026-10-05, the owner's OTHER PLANTS brief)
--
-- OTHER PLANTS: OFF, applied on THIS screen: other players' GROWN plants in
-- their plots -- the models, and with them their labels, income pops, idles and
-- effects -- are not drawn here. Everything else is: this player's own plants,
-- every pod still in the ground (a planted pod is not grown), carried and loose
-- pods, players, guardians, traps, plots and the map, and every viewport
-- preview (those are clones in a ViewportFrame, never tagged Planted).
--
-- A CLIENT DISPLAY PREFERENCE AND NOTHING ELSE. No server model is deleted,
-- moved or reparented here; no ownership, income, collision, pickup, spawn or
-- save changes; nobody else's screen changes. Hiding is LOCAL properties only,
-- each put back exactly as it was:
--
--   parts, decals, textures, LocalTransparencyModifier to 1 -- the engine's own
--   particles, beams, trails local "not on this screen". The own Transparency
--                            and Enabled are never touched, so a part that was
--                            invisible by design (the Base plate) stays so, an
--                            emitter keeps the rate and state its script gave it,
--                            and a fade another script runs goes on underneath;
--                            turning ON puts back the modifier each had.
--   lights                   PlantGlow's, which already owns every planted
--                            light's Enabled (night and authored) and captures the
--                            authored value on first sight -- so it is asked, not
--                            overruled: hidden is one more reason for off there.
--   the rest                 Enabled to false -- fire, sparkles, smoke,
--                            highlights, billboards, surface guis and prompts,
--                            which have no such modifier. What each was
--                            set to is REMEMBERED, and a script that switches one
--                            ON while it is hidden is remembered too, so turning
--                            OTHER PLANTS on restores the state it would have
--                            had, not "everything on". (A switch OFF of an effect
--                            already held off changes nothing the engine can
--                            report; the scripts that time plant effects ask
--                            isHidden instead of fighting over Enabled.)
--
-- THE ONE VALUE. The preference is a LOCAL attribute on the player
-- (GameConfig.OtherPlants.Attribute): OtherPlantsUI writes it, everything reads
-- it. A model this screen hides carries a LOCAL marker attribute (Marker) for as
-- long as it is hidden, so every script that draws something for a plant -- a
-- label, a pop, an idle -- asks one question of the model itself (isHidden) and
-- hears it change (the marker's own changed signal), and nothing reappears over
-- a hidden plant.
--
-- WHOSE IT IS comes from the replicated plot: the plant's nearest ancestor
-- tagged Plot, and that plot's OwnerUserId (PlotService). Never a name. A plot
-- with no owner yet (0, or the attribute not here yet) leaves its plants
-- visible until it has one.
--
-- NO SCANS. The planted models are the Planted tag's (CollectionService: its
-- list once, then its added and removed signals -- which streaming drives too);
-- each tracked model hears its own Stage, its new descendants, its move between
-- folders, and its plot's owner. A toggle walks the tracked models, never the
-- Workspace. A model that leaves takes its connections with it.
--==============================================================================

local CollectionService = game:GetService("CollectionService")

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local PlantVisibility = {}

local PREF = GameConfig.OtherPlants.Attribute
local TAGS = GameConfig.Tags
local OWNER = GameConfig.Attributes.OwnerUserId

-- The marker on a model while this screen hides it: a LOCAL attribute.
PlantVisibility.Marker = "OtherPlantHidden"
-- CreatureModel.STAGE_GROWN, held to it by the spec (CreatureModel is a heavy
-- require for a module every plant script reads).
PlantVisibility.GROWN = 3

--==============================================================================
-- THE PREFERENCE
--==============================================================================
function PlantVisibility.showOthers(player: Player): boolean
	return player:GetAttribute(PREF) ~= false
end

function PlantVisibility.setShowOthers(player: Player, on: boolean)
	player:SetAttribute(PREF, on == true)
end

--==============================================================================
-- THE RULE, PURE
--
-- Hidden only when every fact says so: the preference is OFF, the model is a
-- planted one standing in a plot, it is GROWN, its plot's owner is known, and
-- that owner is somebody else. Anything unknown answers visible.
--==============================================================================
export type Facts = {
	showOthers: boolean,
	planted: boolean,
	inPlot: boolean,
	stage: any,
	owner: any,
	viewer: number,
}

function PlantVisibility.hides(f: Facts): boolean
	if f.showOthers or not f.planted or not f.inPlot then
		return false
	end
	if f.stage ~= PlantVisibility.GROWN then
		return false
	end
	if type(f.owner) ~= "number" or f.owner == 0 or f.owner ~= f.owner then
		return false
	end
	return f.owner ~= f.viewer
end

-- The plot a model stands in: its nearest ancestor tagged Plot.
function PlantVisibility.plotOf(inst: Instance): Instance?
	local at = inst.Parent
	while at do
		if CollectionService:HasTag(at, TAGS.Plot) then
			return at
		end
		at = at.Parent
	end
	return nil
end

function PlantVisibility.factsFor(model: Instance, player: Player): Facts
	local plot = PlantVisibility.plotOf(model)
	return {
		showOthers = PlantVisibility.showOthers(player),
		planted = CollectionService:HasTag(model, TAGS.Planted),
		inPlot = plot ~= nil,
		stage = model:GetAttribute("Stage"),
		owner = if plot then plot:GetAttribute(OWNER) else nil,
		viewer = player.UserId,
	}
end

-- Is this model hidden on this screen right now? For whatever draws something
-- that belongs to a plant. Walks up from a part to its planted model.
function PlantVisibility.isHidden(inst: Instance?): boolean
	local at = inst
	while at do
		if at:GetAttribute(PlantVisibility.Marker) == true then
			return true
		end
		if CollectionService:HasTag(at, TAGS.Planted) then
			return false
		end
		at = at.Parent
	end
	return false
end

-- The planted model a part or an attachment belongs to, if any.
function PlantVisibility.plantOf(inst: Instance?): Instance?
	local at = inst
	while at do
		if CollectionService:HasTag(at, TAGS.Planted) then
			return at
		end
		at = at.Parent
	end
	return nil
end

--==============================================================================
-- HIDING ONE MODEL, REVERSIBLY
--
-- `Shade` is one model's record while it is hidden: each part's modifier as it
-- was, each effect's Enabled as it is MEANT to be, and the watchers that keep
-- those true while it stays hidden. Exposed for the spec (hideModel, showModel)
-- so it can be driven on stand-ins in Edit.
--==============================================================================
-- Hidden by Enabled: the classes with no LocalTransparencyModifier -- lights
-- excepted, which PlantGlow gates (it reads isHidden).
local EFFECTS = { "Fire", "Smoke", "Sparkles", "Highlight", "BillboardGui", "SurfaceGui", "ProximityPrompt" }

local function isEffect(inst: Instance): boolean
	for _, class in ipairs(EFFECTS) do
		if inst:IsA(class) then
			return true
		end
	end
	return false
end

-- Hidden by LocalTransparencyModifier (measured 2026-10-05: parts, decals and
-- textures, and ParticleEmitter, Beam and Trail all carry it).
local function isSurface(inst: Instance): boolean
	return inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("ParticleEmitter") or inst:IsA("Beam")
		or inst:IsA("Trail")
end

export type Shade = {
	model: Instance,
	surfaces: { [Instance]: number },
	effects: { [Instance]: boolean },
	watch: { [Instance]: RBXScriptConnection },
	conns: { RBXScriptConnection },
}

local function shadeOne(shade: Shade, inst: Instance)
	if isSurface(inst) then
		if shade.surfaces[inst] == nil then
			local surface = inst :: any
			shade.surfaces[inst] = surface.LocalTransparencyModifier
			surface.LocalTransparencyModifier = 1
		end
	elseif isEffect(inst) then
		if shade.effects[inst] == nil then
			local effect = inst :: any
			shade.effects[inst] = effect.Enabled == true
			effect.Enabled = false
			-- Somebody else switching it ON while it is hidden is what it is MEANT
			-- to be now; it stays off here until the plant is shown. Read when the
			-- signal arrives (deferred), so our own write of false -- heard late --
			-- is simply off and changes nothing.
			shade.watch[inst] = inst:GetPropertyChangedSignal("Enabled"):Connect(function()
				if (inst :: any).Enabled == true and shade.effects[inst] ~= nil then
					shade.effects[inst] = true;
					(inst :: any).Enabled = false
				end
			end)
		end
	end
end

local function unshadeOne(shade: Shade, inst: Instance)
	local was = shade.surfaces[inst]
	if was ~= nil then
		shade.surfaces[inst] = nil;
		(inst :: any).LocalTransparencyModifier = was
	end
	local meant = shade.effects[inst]
	if meant ~= nil then
		shade.effects[inst] = nil
		local w = shade.watch[inst]
		if w then
			w:Disconnect()
			shade.watch[inst] = nil
		end
		(inst :: any).Enabled = meant
	end
end

-- Hides `model` and keeps it hidden as it gains parts and effects. Answers the
-- record showModel needs to put everything back.
function PlantVisibility.hideModel(model: Instance): Shade
	local shade: Shade = { model = model, surfaces = {}, effects = {}, watch = {}, conns = {} }
	shadeOne(shade, model)
	for _, d in ipairs(model:GetDescendants()) do
		shadeOne(shade, d)
	end
	table.insert(shade.conns, model.DescendantAdded:Connect(function(d)
		shadeOne(shade, d)
	end))
	table.insert(shade.conns, model.DescendantRemoving:Connect(function(d)
		-- Leaving the plant (a part carried off, an effect done): it goes as it
		-- was, and the record lets it go.
		unshadeOne(shade, d)
	end))
	model:SetAttribute(PlantVisibility.Marker, true)
	return shade
end

function PlantVisibility.showModel(shade: Shade)
	for _, c in ipairs(shade.conns) do
		c:Disconnect()
	end
	table.clear(shade.conns)
	local all: { Instance } = {}
	for inst in pairs(shade.surfaces) do
		table.insert(all, inst)
	end
	for inst in pairs(shade.effects) do
		table.insert(all, inst)
	end
	for _, inst in ipairs(all) do
		unshadeOne(shade, inst)
	end
	shade.model:SetAttribute(PlantVisibility.Marker, nil)
end

--==============================================================================
-- THE WATCHER: ONE PER SESSION
--
-- Started by OtherPlantsUI. A second start (a re-run script) replaces the first
-- cleanly: every model shown again and every connection dropped, then built
-- afresh -- so there is never a second watcher fighting the first.
--==============================================================================
type Tracked = {
	model: Instance,
	shade: Shade?,
	plot: Instance?,
	conns: { RBXScriptConnection },
}

local running: { stop: () -> () }? = nil

function PlantVisibility.start(player: Player)
	local old = running
	if old then
		old.stop()
	end
	local tracked: { [Instance]: Tracked } = {}
	-- One owner watch per plot, shared by its plants.
	local plotWatch: { [Instance]: { conn: RBXScriptConnection, users: number } } = {}
	local top: { RBXScriptConnection } = {}

	local function apply(t: Tracked)
		local should = PlantVisibility.hides(PlantVisibility.factsFor(t.model, player))
		if should and not t.shade then
			t.shade = PlantVisibility.hideModel(t.model)
		elseif not should and t.shade then
			local shade = t.shade :: Shade
			t.shade = nil
			PlantVisibility.showModel(shade)
		end
	end

	local function releasePlot(plot: Instance?)
		if not plot then
			return
		end
		local w = plotWatch[plot]
		if w then
			w.users -= 1
			if w.users <= 0 then
				w.conn:Disconnect()
				plotWatch[plot] = nil
			end
		end
	end

	local function holdPlot(plot: Instance?)
		if not plot then
			return
		end
		local w = plotWatch[plot]
		if w then
			w.users += 1
			return
		end
		plotWatch[plot] = {
			users = 1,
			conn = plot:GetAttributeChangedSignal(OWNER):Connect(function()
				for _, t in pairs(tracked) do
					if t.plot == plot then
						apply(t)
					end
				end
			end),
		}
	end

	local function rehome(t: Tracked)
		local plot = PlantVisibility.plotOf(t.model)
		if plot ~= t.plot then
			releasePlot(t.plot)
			t.plot = plot
			holdPlot(plot)
		end
	end

	local function forget(model: Instance)
		local t = tracked[model]
		if not t then
			return
		end
		tracked[model] = nil
		for _, c in ipairs(t.conns) do
			c:Disconnect()
		end
		releasePlot(t.plot)
		local shade = t.shade
		if shade then
			t.shade = nil
			PlantVisibility.showModel(shade)
		end
	end

	local function track(model: Instance)
		if tracked[model] or not model:IsDescendantOf(game) then
			return
		end
		local t: Tracked = { model = model, shade = nil, plot = nil, conns = {} }
		tracked[model] = t
		rehome(t)
		table.insert(t.conns, model:GetAttributeChangedSignal("Stage"):Connect(function()
			apply(t)
		end))
		table.insert(t.conns, model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(game) then
				forget(model)
				return
			end
			rehome(t)
			apply(t)
		end))
		apply(t)
	end

	for _, model in ipairs(CollectionService:GetTagged(TAGS.Planted)) do
		track(model)
	end
	table.insert(top, CollectionService:GetInstanceAddedSignal(TAGS.Planted):Connect(track))
	table.insert(top, CollectionService:GetInstanceRemovedSignal(TAGS.Planted):Connect(forget))
	table.insert(top, player:GetAttributeChangedSignal(PREF):Connect(function()
		for _, t in pairs(tracked) do
			apply(t)
		end
	end))

	local me = {
		stop = function()
			for _, c in ipairs(top) do
				c:Disconnect()
			end
			table.clear(top)
			local models: { Instance } = {}
			for model in pairs(tracked) do
				table.insert(models, model)
			end
			for _, model in ipairs(models) do
				forget(model)
			end
		end,
	}
	running = me

	-- What the spec and a Play probe read: how many models are tracked and hidden,
	-- and how many plot watches stand. No instance leaves this module.
	PlantVisibility.census = function(): { tracked: number, hidden: number, plots: number }
		local n, h, p = 0, 0, 0
		for _, t in pairs(tracked) do
			n += 1
			if t.shade then
				h += 1
			end
		end
		for _ in pairs(plotWatch) do
			p += 1
		end
		return { tracked = n, hidden = h, plots = p }
	end
end

function PlantVisibility.stop()
	local me = running
	if me then
		running = nil
		me.stop()
	end
end

-- Until a watcher starts: nothing tracked.
PlantVisibility.census = function(): { tracked: number, hidden: number, plots: number }
	return { tracked = 0, hidden = 0, plots = 0 }
end

return PlantVisibility
