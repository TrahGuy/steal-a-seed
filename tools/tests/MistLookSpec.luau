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
	-- MORE MIST (2026-10-12, the owner's item 16E): the ground mist round the
	-- camera and the hub's two rings, the same rules, the rings only near it.
	local G, H = LOOK.Ground, LOOK.Hub
	local g, gr, ed = MistLook.mistRates(1, false, false, true)
	local tg, tgr, ted = MistLook.mistRates(1, true, false, true)
	local fg, fgr, fed = MistLook.mistRates(1, false, false, false)
	local rg, rgr, red = MistLook.mistRates(1, false, true, true)
	local ng, ngr, ned = MistLook.mistRates(0, false, false, true)
	local hg, hgr, hed = MistLook.mistRates(0.5, false, false, true)
	check(g == G.Rate and gr == H.Grove.Rate and ed == H.Edge.Rate and tg < g and tgr < gr and ted < ed
			and fg == g and fgr == 0 and fed == 0 and rg + rgr + red == 0 and ng + ngr + ned == 0
			and hg == g / 2 and hgr == gr / 2 and hed == ed / 2,
		"MORE MIST: the ground mist and the hub's rings ease with the Mist, fewer on a touch screen, none under "
			.. "Reduced FX, the rings only near the hub")
	local W = LOOK.Wisps
	check(W.Size[1] >= 10 and W.Lifetime[1] >= 8 and W.Lifetime[2] <= 12 and W.Transparency >= 0.55
			and (W.Drift or 0) > 0 and LOOK.Wind.Speed > 0 and LOOK.Wind.Speed <= 2,
		"the wisps are big, see-through puffs floating past on a gentle wind, 8-12 s each")
	-- Tuned in the Play's captures (2026-10-12): thicker than 0.55 washed the
	-- field out (a berry on the grass got hard to see), much fainter read as
	-- nothing at all.
	check(G.Above <= 2 and G.Transparency >= 0.55 and G.Transparency <= 0.75 and G.Squash < 0 and G.Area <= 200
			and H.Range <= 300 and H.Grove.Turn ~= 0 and H.Edge.Radius >= GameConfig.Map.HubRadius
			and H.Grove.Transparency >= 0.55 and H.Edge.Transparency >= 0.55,
		"the ground mist stays at knee height and flat, round the camera only, never so thick the field washes out; "
			.. "the hub's swirl turns, its band along the deck's edge, drawn only near the hub")

	--==========================================================================
	say("2. Readable, and nothing invented")
	--==========================================================================
	local L = LOOK.Light
	check(L.Brightness >= NIGHT.Brightness and L.Exposure >= NIGHT.ExposureCompensation
			and luma(L.Ambient) >= luma(NIGHT.Ambient) and luma(L.OutdoorAmbient) >= luma(NIGHT.OutdoorAmbient)
			and L.Ambient.B > L.Ambient.G and L.Ambient.R > L.Ambient.G * 0.95,
		"a blue-violet night, never darker than the plain night the plots are tuned for")
	local textures = { LOOK.Wisps.Texture, LOOK.Fireflies.Texture, LOOK.Glints.Texture, LOOK.Ground.Texture,
		LOOK.Hub.Texture }
	local engine = true
	for _, t in ipairs(textures) do
		engine = engine and type(t) == "string" and string.sub(t, 1, 11) == "rbxasset://"
	end
	check(engine and (L :: any).Fog == nil and (LOOK :: any).Fog == nil and (LOOK :: any).Sound == nil,
		"the engine's own particle textures (the ground mist and the hub's swirl too), no fog setting and no sound: "
			.. "no upload invented")

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
	check(string.find(weather, "MistLook.mistRates(mistLevel, UserInputService.TouchEnabled, StatusText.reducedMotion(), "
				.. "nearHub)", 1, true) ~= nil
			and string.find(weather, "local nearHub = camera ~= nil and (camera.CFrame.Position - HUB_AT).Magnitude <= "
				.. "HUB.Range", 1, true) ~= nil
			and string.find(weather, "mist.LockedToPart = true", 1, true) ~= nil
			and string.find(weather, "groundAnchor.CFrame = CFrame.lookAt(at, at + windDir)", 1, true) ~= nil
			and not string.find(weather, "FogEnd", 1, true) and not string.find(weather, "Atmosphere", 1, true),
		"MORE MIST (2026-10-12): Weather.client rolls the ground mist downwind round the camera and turns the hub's "
			.. "rings only near it, eased and Reduced FX respected -- particles only, no Atmosphere and no fog distance")
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
	-- ShowMosskeeper on since 2026-10-11 (the owner: the hub set stands always);
	-- the look stays the Mist's own.
	check(built == "true" and EnchantedMistConfig.Enabled == true and EnchantedMistConfig.ShowMosskeeper == true,
		"the Look is built; the event's schedule on (the owner, 2026-10-12), Mosskeeper's hub set on", built)
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMistLookSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
