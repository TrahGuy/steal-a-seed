--!strict
--==============================================================================
-- Steal a Seed :: PlantGlow
--
-- A planted creature's own lights burn at NIGHT and nowhere else.
--
--==============================================================================
-- WHY THIS EXISTS
--
-- A grown plant's glow is a PointLight scaled with the plant: a Colossal's
-- SolarGlow asks for a range of 16 x its height scale and the engine stops it at
-- 60. One of those is a warm pool on the soil. Six of them overlapping in a
-- garden at midday -- on top of Lighting.Brightness 2.4 -- washed the soil, the
-- plants and anybody standing in the bed out to white.
--
-- Night is where that light belongs. WorldClock drops the world to a blue night
-- for sixty seconds every eight minutes, and a garden of lit creatures is the
-- spectacle of it. So the lights are switched off by day and restored at dusk.
-- Nothing else about a plant changes: Neon accents stay Neon, emitters keep
-- emitting, colour and anatomy read exactly as authored.
--
--==============================================================================
-- DRIVEN BY THE PHASE, NOT BY Lighting.ClockTime
--
-- `Workspace.WorldPhase` is the one authoritative answer to "is it night", the
-- same attribute CarryService, the road gate and WorldClock already obey.
-- ClockTime is not an answer: WorldClock BLENDS it from 14 down to 0 over three
-- seconds, so any threshold on it is a guess about where inside that fade night
-- begins, and it would disagree with the rest of the game for up to three
-- seconds at every change. The caller reads the attribute and hands the result
-- to SetNight; this file has no clock and no timer.
--
--==============================================================================
-- CLIENT-LOCAL, AND IT OWNS NO LIFECYCLE
--
-- An `Enabled` written on the client does not replicate, so every client gates
-- its own copy and the server sends nothing per light per phase.
--
-- Like PlantAura, this is a mechanism rather than a system. PlantSway already
-- watches every `Planted` model for as long as it is tagged and in the game --
-- including the empty container of a plant that has not streamed in yet -- and
-- it hands this file the model's descendants as they arrive and leave. A second
-- index of the same bed is the one that leaks.
--
-- Scope is the `Planted` tag and nothing wider, which PlantService applies only
-- to a pod or creature in somebody's soil. Pods in nests, carried pods, shop,
-- bag and Almanac viewports, guardians, mills and the map are never handed to
-- this file and are never touched.
--
--==============================================================================
-- THE AUTHORED SWITCH IS KEPT ON THE LIGHT
--
-- Not every authored light has to be on, so the value is read before this file
-- ever writes, once per light instance, and stored as a client-local attribute
-- on the light itself. Two things follow from keeping it there:
--
--   * a light seen again -- its model tagged again, or this script re-run --
--     restores from what was authored, never from what this gate last wrote;
--   * the tables below hold only what is currently gated, so a light, a plant
--     or a tag going away leaves nothing behind in them.
--
-- A light that streams out and back in is a NEW instance, and is captured
-- fresh from what the server sent.
--
-- Brightness, Range, Color, Shadows and the parent are never read or written.
--==============================================================================

local PlantGlow = {}

-- Client-local and private to this file. Never set by the server.
local AUTHORED = "SeedGlowAuthored"

local night = false

-- model -> the lights this gate is holding for it. A model only gets an entry
-- once it actually has a light, so a bed of unlit Nubkins costs nothing here.
local held: { [Model]: { [Light]: true } } = {}
-- light -> its model, so a light can be dropped without searching every bed.
local ownerOf: { [Light]: Model } = {}

--==============================================================================
-- THE AUTHORED VALUE, CAPTURED BEFORE THE FIRST WRITE
--==============================================================================
local function authoredOf(light: Light): boolean
	local value = light:GetAttribute(AUTHORED)
	if type(value) == "boolean" then
		return value
	end
	local enabled = light.Enabled
	light:SetAttribute(AUTHORED, enabled)
	return enabled
end

local function apply(light: Light)
	-- Read FIRST and on its own line. `night and authoredOf(light)` short-
	-- circuits by day, so the capture would never happen before the first write
	-- and the next dusk would read back the `false` this file had just written --
	-- a plant that never lights again. PlantGlowSpec caught exactly that.
	local authored = authoredOf(light)
	local want = night and authored
	-- Only when it differs: an unconditional write on every light at every
	-- phase change is a property change the renderer has to process for nothing.
	if light.Enabled ~= want then
		light.Enabled = want
	end
end

--==============================================================================
-- WHAT PLANTSWAY CALLS
--==============================================================================

-- Anything that is not a Light is ignored, so DescendantAdded can be wired
-- straight through without a filter of its own. `Light` is the abstract base
-- of exactly PointLight, SpotLight and SurfaceLight.
function PlantGlow.Add(model: Model, instance: Instance)
	if not instance:IsA("Light") then
		return
	end
	local light = instance :: Light
	if ownerOf[light] then
		return
	end
	local set = held[model]
	if not set then
		set = {}
		held[model] = set
	end
	set[light] = true
	ownerOf[light] = model
	apply(light)
end

function PlantGlow.Remove(instance: Instance)
	local light = instance :: any
	local model = ownerOf[light]
	if not model then
		return
	end
	ownerOf[light] = nil
	local set = held[model]
	if set then
		set[light] = nil
		if next(set) == nil then
			held[model] = nil
		end
	end
end

-- One pass over what the model already has. Everything after this arrives
-- through Add.
function PlantGlow.Watch(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		PlantGlow.Add(model, d)
	end
end

--==============================================================================
-- LETTING GO OF A PLANT
--
-- The references go; the lights are LEFT AS THEY ARE. Every production path
-- that removes the `Planted` tag -- PlantService's burst on a hatch and its lift
-- on a pickup -- fades the model out and destroys it a quarter of a second
-- later. Restoring on the way out would switch a Colossal's light on across
-- daylit soil for the length of that fade, which is exactly the flash this file
-- exists to remove. At night the lights are already in their authored state,
-- so there is nothing to restore anyway.
--
-- Nothing is lost if a model is ever tagged again: the authored value is on the
-- light, not in these tables.
--==============================================================================
function PlantGlow.Release(model: Model)
	local set = held[model]
	if not set then
		return
	end
	held[model] = nil
	for light in pairs(set) do
		ownerOf[light] = nil
	end
end

--==============================================================================
-- THE PHASE
--
-- Walks what is held, which is the lights of tagged plants and nothing else --
-- never the workspace. No allocation: `pairs` over an existing table.
--==============================================================================
function PlantGlow.SetNight(isNight: boolean)
	if night == isNight then
		return
	end
	night = isNight
	for light in pairs(ownerOf) do
		if light.Parent then
			apply(light)
		else
			-- Gone without a removal reaching this file. Assigning nil to a key
			-- that is being traversed is allowed by `next`.
			PlantGlow.Remove(light)
		end
	end
end

function PlantGlow.IsNight(): boolean
	return night
end

--==============================================================================
-- FOR VERIFICATION, AND FOR A RE-RUN OF THE SCRIPT THAT DRIVES THIS
--
-- Reset drops the tables and leaves every light as it is. The copy of PlantSway
-- that replaces the old one watches the same models again and restores from the
-- attribute, so a day stays dark across the reload instead of flashing.
--==============================================================================
function PlantGlow.Stats(): (number, number, number)
	local models, lights, lit = 0, 0, 0
	for _ in pairs(held) do
		models += 1
	end
	for light in pairs(ownerOf) do
		lights += 1
		if light.Enabled then
			lit += 1
		end
	end
	return models, lights, lit
end

function PlantGlow.Reset()
	table.clear(held)
	table.clear(ownerOf)
end

return PlantGlow
