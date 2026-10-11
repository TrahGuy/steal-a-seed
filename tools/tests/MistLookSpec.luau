--==============================================================================
-- MistLookSpec (2026-10-11, Enchanted Mist: the Look)
--
-- The enchanted night over the day (Shared/MistLook, EnchantedMistConfig.Look;
-- KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §3):
--
--   1. the arithmetic: nothing restored from a snapshot (compose at 0 is the
--      base itself), eased in and out, only while a Mist is active, the
--      decoration cut by Reduced FX and thinned on a touch screen
--   2. readable: lighter than the plain night, no fog, the engine's own
--      particle textures only (no invented upload), no sound
--   3. the owners: WorldClock lays the light (Lighting's one owner, the fog
--      still the phase's), Weather.client the wisps and fireflies over the
--      camera, EnchantedMistBerries.client the glints; no server reads it and
--      the Rain's lottery never hears of it; the Look built, the event off
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local MistLook = require(Shared:WaitForChild("MistLook"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local LOOK = EnchantedMistConfig.Look
local NIGHT = GameConfig.WorldCycle.Night

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function strip(src)
	return (string.gsub(src, "%-%-[^\n]*", ""))
end
local function luma(c: Color3): number
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The arithmetic")
	--==========================================================================
	local base = {
		ClockTime = 14, Brightness = 2.4, Ambient = Color3.fromRGB(140, 140, 150),
		OutdoorAmbient = Color3.fromRGB(150, 150, 160), EnvironmentDiffuseScale = 1, ExposureCompensation = 0,
	}
	local full = MistLook.compose(base, 1)
	local half = MistLook.compose(base, 0.5)
	check(MistLook.compose(base, 0) == base, "with no Mist the light IS the live one: nothing put back from a snapshot")
	check(full.ClockTime == LOOK.Light.ClockTime and full.Brightness == LOOK.Light.Brightness
			and full.Ambient == LOOK.Light.Ambient and full.OutdoorAmbient == LOOK.Light.OutdoorAmbient
			and full.ExposureCompensation == LOOK.Light.Exposure
			and math.abs(half.Brightness - (base.Brightness + LOOK.Light.Brightness) / 2) < 1e-9,
		"at full the Mist's night, in between a blend of the two")
	local m, steps = 0, 0
	while m < 1 and steps < 10000 do
		m = MistLook.step(m, 1, 1 / 60)
		steps += 1
	end
	local inSeconds = steps / 60
	steps = 0
	while m > 0 and steps < 10000 do
		m = MistLook.step(m, 0, 1 / 60)
		steps += 1
	end
	local outSeconds = steps / 60
	check(math.abs(inSeconds - LOOK.Light.FadeSeconds) < 0.05 and math.abs(outSeconds - LOOK.Light.FadeOutSeconds) < 0.05,
		"it comes in over FadeSeconds and goes over FadeOutSeconds", string.format("%.2f / %.2f", inSeconds, outSeconds))
	local S = EnchantedMistConfig.States
	check(MistLook.wanted(S.Active) == 1 and MistLook.wanted(S.Eligible) == 0 and MistLook.wanted(S.Cooldown) == 0
			and MistLook.wanted(S.Disabled) == 0 and MistLook.wanted(nil) == 0,
		"only while a Mist is active")
	check(MistLook.nightness(0, 0) == 0 and MistLook.nightness(1, 0) == 1 and MistLook.nightness(0, 1) == 1,
		"a rain in the Mist reads as a rainy night")
	local w, f = MistLook.rates(1, false, false)
	local tw, tf = MistLook.rates(1, true, false)
	local rw, rf = MistLook.rates(1, false, true)
	local nw, nf = MistLook.rates(0, false, false)
	check(w == LOOK.Wisps.Rate and f == LOOK.Fireflies.Rate and tw < w and tf < f and rw == 0 and rf == 0
			and nw == 0 and nf == 0,
		"the wisps and fireflies: fewer on a touch screen, none under Reduced FX or with no Mist")

	--==========================================================================
	say("2. Readable, and nothing invented")
	--==========================================================================
	local L = LOOK.Light
	check(L.Brightness >= NIGHT.Brightness and L.Exposure >= NIGHT.ExposureCompensation
			and luma(L.Ambient) >= luma(NIGHT.Ambient) and luma(L.OutdoorAmbient) >= luma(NIGHT.OutdoorAmbient)
			and L.Ambient.B > L.Ambient.G and L.Ambient.R > L.Ambient.G * 0.95,
		"a blue-violet night, never darker than the plain night the plots are tuned for")
	local textures = { LOOK.Wisps.Texture, LOOK.Fireflies.Texture, LOOK.Glints.Texture }
	local engine = true
	for _, t in ipairs(textures) do
		engine = engine and type(t) == "string" and string.sub(t, 1, 11) == "rbxasset://"
	end
	check(engine and (L :: any).Fog == nil and (LOOK :: any).Fog == nil and (LOOK :: any).Sound == nil,
		"the engine's own particle textures, no fog and no sound: no upload invented")

	--==========================================================================
	say("3. The owners")
	--==========================================================================
	local clock = strip(Scripts:WaitForChild("WorldClock").Source)
	local apply = string.match(clock, "local function applyLight%(t: number%)(.-)\nend\n") or ""
	check(string.find(clock, "MistLook", 1, true) ~= nil and string.find(apply, "MistLook.compose(", 1, true) ~= nil
			and string.find(apply, "applyFog(t)", 1, true) ~= nil and select(2, string.gsub(apply, "applyFog%(", "")) == 1
			and not string.find(clock, "FogEnd", 1, true) and not string.find(clock, "Atmosphere", 1, true)
			and string.find(clock, "MistLook.step(mist, MistLook.wanted(", 1, true) ~= nil,
		"WorldClock lays the light over the day/night blend; the fog banks stay the phase's alone")
	local weather = strip(Scripts:WaitForChild("Weather").Source)
	check(string.find(weather, "MistLook.rates(", 1, true) ~= nil and string.find(weather, "MistLook.step(", 1, true) ~= nil
			and string.find(weather, "StatusText.reducedMotion()", 1, true) ~= nil
			and string.find(weather, "\n\tstepMist(dt)\n", 1, true) ~= nil,
		"Weather.client draws the wisps and fireflies over the camera, eased, Reduced FX respected")
	local berries = strip(Scripts:WaitForChild("EnchantedMistBerries").Source)
	check(string.find(berries, "LOOK.Glints", 1, true) ~= nil and string.find(berries, "StatusText.reducedMotion()", 1, true)
			~= nil,
		"the berries glint (off under Reduced FX); the berries themselves never dim")
	local serverReads = {}
	for _, d in ipairs(Server:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and string.find(strip((d :: any).Source), "MistLook", 1, true) then
			table.insert(serverReads, d.Name)
		end
	end
	local weatherService = (Server:WaitForChild("WeatherService") :: any).Source
	check(#serverReads == 0 and not string.find(weatherService, "EnchantedMist", 1, true),
		"no server reads the look, and the Rain/Thunder lottery never hears of the Mist", table.concat(serverReads, ","))
	local service = Server:WaitForChild("EnchantedMistService")
	local built = string.match(strip((service :: any).Source), "Look = (%a+),")
	check(built == "true" and EnchantedMistConfig.Enabled == false and EnchantedMistConfig.ShowMosskeeper == false,
		"the Look is built; the event itself still off", built)
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMistLookSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
