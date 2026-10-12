--!strict
--==============================================================================
-- Steal a Seed :: MistLook (2026-10-11, Enchanted Mist: the Look)
--
-- THE ENCHANTED NIGHT, LAID OVER THE DAY (KB/ENCHANTED-MIST-RESET-ALIGNED-
-- CLAUDE-PROMPT.md §3). While a Mist runs, the gameplay phase is still Day --
-- the biomes and the road open -- and every client draws a moonlit,
-- blue-violet night over it, through the owners that already exist:
--
--   * the LIGHT is WorldClock's (Lighting's one owner): one more eased
--     number, `mist`, laid over the day/night blend and under the rain and
--     the disco, with a soft violet tone of its own;
--   * the WISPS and FIREFLIES are Weather.client's (the weather's FX owner):
--     two emitters that follow the camera, low over the ground; and since
--     2026-10-12 (item 16E) the ROLLING GROUND MIST round the camera and the
--     HUB'S SWIRL round the grove and the deck's edge, all particles;
--   * the berries' GLINTS are EnchantedMistBerries.client's.
--
-- This file is the numbers' arithmetic those owners share (the numbers are
-- EnchantedMistConfig.Look), pure, so a spec can hold it. It touches no
-- Instance.
--
-- NOTHING IS PUT BACK FROM A SNAPSHOT: compose(base, 0) IS base. When the Mist
-- ends its number eases to 0 and the light is recomputed from whatever day,
-- night, rain or disco is live by then.
-- NO FOG: the biome fog banks ride the phase alone, and nothing here touches
-- Atmosphere or the fog distance -- the ground, the berries, the prompts and
-- the long road stay readable, the far biomes in colour.
-- NO GAMEPLAY: no server reads any of it. Reduced FX keeps the light (it is
-- the event's look, as the disco's is) and drops the wisps, fireflies and
-- glints; the berries themselves never dim.
--==============================================================================
local EnchantedMistConfig = require(script.Parent:WaitForChild("EnchantedMistConfig"))

local MistLook = {}

local LOOK = EnchantedMistConfig.Look
local L = LOOK.Light
local WHITE = Color3.new(1, 1, 1)

export type Light = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	EnvironmentDiffuseScale: number,
	ExposureCompensation: number,
}

-- 1 while a Mist is ACTIVE (EnchantedMistConfig.Attributes.State), else 0.
function MistLook.wanted(state: any): number
	return if state == EnchantedMistConfig.States.Active then 1 else 0
end

-- One frame of the eased number toward `want`: in over FadeSeconds, out over
-- FadeOutSeconds.
function MistLook.step(current: number, want: number, dt: number): number
	if current == want then
		return current
	end
	local seconds = if want > current then L.FadeSeconds else L.FadeOutSeconds
	local pace = dt / math.max(0.05, seconds)
	return if want > current then math.min(want, current + pace) else math.max(want, current - pace)
end

-- `base` (the phase's light) `m` of the way to the Mist's night; base itself
-- at 0. ClockTime moves the way the plain night's does (down toward 0).
function MistLook.compose(base: Light, m: number): Light
	if m <= 0 then
		return base
	end
	return {
		ClockTime = base.ClockTime + (L.ClockTime - base.ClockTime) * m,
		Brightness = base.Brightness + (L.Brightness - base.Brightness) * m,
		Ambient = base.Ambient:Lerp(L.Ambient, m),
		OutdoorAmbient = base.OutdoorAmbient:Lerp(L.OutdoorAmbient, m),
		EnvironmentDiffuseScale = base.EnvironmentDiffuseScale
			+ (L.EnvironmentDiffuseScale - base.EnvironmentDiffuseScale) * m,
		ExposureCompensation = base.ExposureCompensation + (L.Exposure - base.ExposureCompensation) * m,
	}
end

-- How night the rain's own day/night pair should read: the phase's night, or
-- the Mist's, whichever is more (a rain in the Mist is a rainy night).
function MistLook.nightness(t: number, m: number): number
	return t + (1 - t) * m
end

-- The Mist's tone at `m`: tint, saturation, contrast (white, 0, 0 at 0).
function MistLook.tone(m: number): (Color3, number, number)
	return WHITE:Lerp(L.Tint, m), L.Saturation * m, L.Contrast * m
end

-- The wisps' and fireflies' rates at `level`: none under Reduced FX or with
-- no Mist; a touch screen's lower rates.
function MistLook.rates(level: number, touch: boolean, reduced: boolean): (number, number)
	if reduced or level <= 0 then
		return 0, 0
	end
	local W, F = LOOK.Wisps, LOOK.Fireflies
	return (if touch then W.ReducedRate else W.Rate) * level, (if touch then F.ReducedRate else F.Rate) * level
end

-- MORE MIST (2026-10-12, item 16E): the ground mist's rate round the camera
-- and the hub's two rings' (the grove's swirl, the deck's edge) at `level` --
-- none under Reduced FX or with no Mist, a touch screen's lower rates, the
-- rings only while the camera is `nearHub` (LOOK.Hub.Range).
function MistLook.mistRates(level: number, touch: boolean, reduced: boolean, nearHub: boolean): (number, number, number)
	if reduced or level <= 0 then
		return 0, 0, 0
	end
	local G, H = LOOK.Ground, LOOK.Hub
	local ground = (if touch then G.ReducedRate else G.Rate) * level
	if not nearHub then
		return ground, 0, 0
	end
	return ground, (if touch then H.Grove.ReducedRate else H.Grove.Rate) * level,
		(if touch then H.Edge.ReducedRate else H.Edge.Rate) * level
end

return MistLook
