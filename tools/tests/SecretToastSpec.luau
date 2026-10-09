--!nocheck
--==============================================================================
-- Steal a Seed :: SecretToastSpec (2026-10-05, the owner's follow-up)
--
-- "A SECRET EGG SPAWNED ON {BIOME}!" once per actual new Secret egg, to
-- everybody in the server: a road Secret's fresh spawn, and the Thunderstorm's
-- Pod 3 when its biome opens -- the console's storm and the automatic one
-- alike. Drives, in Edit:
--
--   * the words, the one weather egg named, and nothing else changed: Pod 3
--     still Divine, natural Secrets still off, a Colossal Rain pod no Secret
--   * the payload read, ONE notice per spawn id however often it is delivered,
--     a later spawn in the same biome shown, the biome by its display name and
--     never by its id
--   * the word's place in the headline wherever it stands -- the leading
--     "A ", lines broken for a narrow stack -- with a fixed measure, then the
--     real fonts on desktop, small-window and phone stacks for every biome
--   * the storm's egg waiting behind the storm's own opening toast only when
--     the stack has no room for both
--   * the REAL spawnSecret on a nest raised the way buildNest raises one: a
--     success announces once with its own id; a refusal, the confiscated pod
--     walked back, a rebuilt guardian and the ticks after announce nothing; a
--     later spawn announces again
--   * the REAL event nest: a thunderstorm's Pod 3 announced once at the
--     opening; a Rain (Colossal pods or not), an event ended before it opened,
--     a refused second nest, an unknown weather and a failed build announce
--     nothing
--   * WeatherService's real Step on its own clock: the egg's toast right after
--     the opening's, once, for a console storm and an automatic one; a refused
--     START and a biome that never built announce nothing
--
-- NOT here, seen in the guarded Play instead: the remote to a real client, the
-- toast on a real screen (the sheen, its alignment, a phone's wrapping).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local BiomeData = require(Shared.BiomeData)
local HudLayout = require(Shared.HudLayout)
local Notice = require(Shared.Notice)
local ParentModel = require(Server.ParentModel)
local NestService = require(Server.NestService)
local WeatherService = require(Server.WeatherService)

local T = GameConfig.Secret.Toast
local W = GameConfig.Weather

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
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	return if found then found.Source else ""
end
local function count(text, needle)
	local n, from = 0, 1
	while true do
		local a, b = string.find(text, needle, from, true)
		if not a then
			return n
		end
		n += 1
		from = b + 1
	end
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZSecretToastSpec"
scratch.Parent = Workspace

-- The client's own biome names (ActionToastUI's biomeName, held to its source below).
local function nameOf(id)
	if id == W.Biome.Id then
		return W.Biome.Label
	end
	for _, b in ipairs(BiomeData.Biomes) do
		if b.Id == id then
			return b.DisplayName
		end
	end
	return nil
end

local function biomeOf(id)
	for _, b in ipairs(BiomeData.Biomes) do
		if b.Id == id then
			return b
		end
	end
	return nil
end

-- A road nest raised the way buildNest raises one (GuardianRecoverySpec's
-- fixture): its own folder, the real rig, a ring of slots.
local HIGH = 4600
local raised = 0
local function raise(biome)
	raised += 1
	local at = Vector3.new(-38, HIGH, 900 + raised * 90)
	local folder = Instance.new("Folder")
	folder.Name = string.format("Nest_spec_%s_%02d", biome.Id, raised)
	folder.Parent = scratch
	local buildAt = CFrame.new(at) * CFrame.Angles(0, math.pi * 0.5, 0)
	local model = ParentModel.Build(buildAt, 15, biome.Id, folder)
	local slots = {}
	for i = 1, biome.PodsPerNest or 5 do
		local a = (i - 1) / (biome.PodsPerNest or 5) * math.pi * 2
		slots[i] = CFrame.new(at + Vector3.new(math.sin(a) * 16, 0, math.cos(a) * 16))
	end
	return {
		id = folder.Name, biome = biome, origin = at, homeCFrame = model.PrimaryPart.CFrame,
		parent = model, humanoid = model:FindFirstChildOfClass("Humanoid"), root = model.PrimaryPart,
		folder = folder, slots = slots, pods = {}, state = "asleep", target = nil, stateUntil = 0,
		busy = false, rage = 0, calmSince = 0, chaseSince = 0, haul = nil, sample = nil, thieves = {},
		secret = nil, marked = {}, buildAt = buildAt, rigId = biome.Id, lastSeen = model.PrimaryPart.Position,
		event = nil, route = nil, setDown = nil,
	}
end

local clock = 7000
local function tick(nest)
	clock += 0.12
	NestService.SpecStep(nest, clock)
end

local site = {
	centre = Vector3.new(0, 601.11, 2600),
	floorY = 600,
	route = { Vector3.new(-300, 600, 2600), Vector3.new(-150, 600, 2600) },
	setDown = Vector3.new(-300, 600, 2600),
	parent = scratch,
}

local told = {}
local function tell(id, biome, event)
	table.insert(told, { id = id, biome = biome, event = event })
end

local ok, err = pcall(function()
	pcall(NestService.CloseEventNest, nil)
	NestService.SpecAnnouncer(tell)

	--==========================================================================
	say("1. The words, the one weather egg, and nothing else changed")
	--==========================================================================
	check(T.Title == "A SECRET EGG SPAWNED ON %s!" and T.Word == "SECRET" and T.TitleNoName == "A SECRET EGG SPAWNED!",
		"the owner's words, and the word the renderer styles")
	local named = 0
	for _ in pairs(T.WeatherEggs) do
		named += 1
	end
	check(named == 1 and T.WeatherEggs.rainpod3 == true, "one weather egg gets the toast: the Thunderstorm's Pod 3")
	check(SeedData.RainPods.rainpod3.Rarity == "Divine" and SeedData.RainPods.rainpod1.Rarity == "Mythic"
		and SeedData.RainPods.rainpod2.Rarity == "Mythic" and SeedData.RainPods.rainpod3.Name == "Thunderstorm pod",
		"Pod 3 is still Divine and still the Thunderstorm pod; the Rain pods are untouched")
	check(GameConfig.Secret.Enabled == true, "natural Secret spawning is on (the owner, 2026-10-09); the toast itself adds no egg")
	local rng = Random.new(51005)
	local thunderOne, rainNone = true, true
	for _ = 1, 300 do
		local tIds, rIds = {}, {}
		for _, roll in ipairs(SeedData.RollRainBatch("thunder", rng)) do
			table.insert(tIds, roll.pod)
		end
		for _, roll in ipairs(SeedData.RollRainBatch("rain", rng)) do
			table.insert(rIds, roll.pod)
		end
		thunderOne = thunderOne and NestService.WeatherEggCount(tIds) == 1
		rainNone = rainNone and NestService.WeatherEggCount(rIds) == 0
	end
	check(thunderOne and rainNone and NestService.WeatherEggCount({ "rainpod2", "rainpod2", "rainpod2" }) == 0,
		"every thunderstorm batch has its one egg to tell; no Rain batch -- three Colossals included -- has any")

	--==========================================================================
	say("2. The payload, once per spawn, the biome by its name")
	--==========================================================================
	local R = Notice.readSecret
	local a = R({ id = "Nest_greenhollow_1:secret:1", biome = "greenhollow" })
	local b = R({ id = "event:7", biome = "rain", event = 7 })
	local legacy = R("greenhollow")
	check(a and a.id == "Nest_greenhollow_1:secret:1" and a.biome == "greenhollow" and a.event == nil
		and b and b.id == "event:7" and b.event == 7 and legacy and legacy.id == nil and legacy.biome == "greenhollow",
		"{ id, biome, event? } reads; an older server's bare biome id still reads")
	check(R(nil) == nil and R(5) == nil and R("") == nil and R({}) == nil and R({ id = "", biome = "x" }) == nil
		and R({ id = "x" }) == nil and R({ id = 5, biome = "x" }) == nil and R({ id = "x", biome = 3 }) == nil,
		"anything else reads as nothing")
	local seen = {}
	local first = Notice.secretPost(a, T, nameOf, seen)
	check(first and first.kind == "secret" and first.title == "A SECRET EGG SPAWNED ON GREENHOLLOW!"
		and first.key == "secret:Nest_greenhollow_1:secret:1" and first.quiet == true and Notice.valid(first),
		"a road Secret: A SECRET EGG SPAWNED ON GREENHOLLOW!, quiet, keyed by its spawn", first and first.title)
	check(Notice.secretPost(a, T, nameOf, seen) == nil
		and Notice.secretPost(R({ id = a.id, biome = "greenhollow" }), T, nameOf, seen) == nil,
		"the same spawn delivered again is not shown again")
	local later = Notice.secretPost(R({ id = "Nest_greenhollow_1:secret:2", biome = "greenhollow" }), T, nameOf, seen)
	check(later and later.title == first.title and later.key ~= first.key,
		"a later spawn in the same biome IS shown: its own id, its own notice")
	local storm = Notice.secretPost(b, T, nameOf, seen)
	check(storm and storm.title == "A SECRET EGG SPAWNED ON RAIN\u{00A0}BIOME!" and storm.key == "secret:event:7",
		"the storm's egg names the weather's biome by its label -- its two words held by a no-break space",
		storm and storm.title)
	local held = Notice.wordSpan(storm.title, "SECRET", 230, function(t)
		return #t * 10
	end)
	check(#held.lines == 2 and held.lines[2] == "RAIN\u{00A0}BIOME!",
		"so a headline too wide for one line breaks before the name, never inside it", table.concat(held.lines, " | "))
	local star = Notice.secretPost(R({ id = "s:1", biome = "starbloom" }), T, nameOf, seen)
	check(star and star.title == "A SECRET EGG SPAWNED ON STARBLOOM!", "upper case, whatever the name's case")
	local odd = Notice.secretPost(R({ id = "z:1", biome = "zz_internal" }), T, nameOf, seen)
	check(odd and odd.title == T.TitleNoName and not string.find(string.upper(odd.title), "ZZ", 1, true),
		"a biome with no name is told without one: no internal id on screen")
	local l1, l2 = Notice.secretPost(legacy, T, nameOf, seen), Notice.secretPost(legacy, T, nameOf, seen)
	check(l1 and l2 and l1.key == "secret:greenhollow" and seen.greenhollow == nil,
		"an older server's bare id has no spawn to remember: shown, keyed by its biome")

	--==========================================================================
	say("3. The word's place in the headline, wherever it stands")
	--==========================================================================
	local function m10(text)
		return #text * 10
	end
	-- A measure that drops trailing spaces, as some text measures do.
	local function trimmed(text)
		local cut = string.gsub(text, "%s+$", "")
		return #cut * 10
	end
	local S = Notice.wordSpan
	local title = "A SECRET EGG SPAWNED ON DUSTBOWL!"
	local one = S(title, "SECRET", 1000, m10)
	check(#one.lines == 1 and one.width == 330 and one.line == 1 and one.at == 3 and one.x == 20 and one.w == 60,
		"one line: SECRET starts after \"A \" -- 20 px in, 60 wide", string.format("%s %d %d", tostring(one.line), one.x, one.w))
	check(S(title, "SECRET", 1000, trimmed).x == 20,
		"measured as the words WITH the word less the word: the space counts even where a measure drops it")
	local lead = S("SECRET POD SPAWNED", "SECRET", 1000, m10)
	check(lead.line == 1 and lead.x == 0 and lead.at == 1, "a leading word still stands at the start")
	local two = S(title, "SECRET", 200, m10)
	check(#two.lines == 2 and two.lines[1] == "A SECRET EGG SPAWNED" and two.lines[2] == "ON DUSTBOWL!" and two.width == 200
		and two.line == 1 and two.x == 20,
		"too wide: broken at a space, as many words as fit; the word on the first line", table.concat(two.lines, " | "))
	local three = S(title, "SECRET", 130, m10)
	check(#three.lines == 3 and three.width == 120 and three.line == 1 and three.x == 20,
		"narrower again: three lines, the word still placed", table.concat(three.lines, " | "))
	local centred = S("A SECRET EXTRAORDINARILY", "SECRET", 120, m10)
	check(#centred.lines == 2 and centred.width == 150 and centred.line == 1 and centred.x == 55,
		"its line centred under a wider one: (150 - 80) / 2 + 20 = 55", centred.x)
	local whole = S("SECRETS ARE A SECRET", "SECRET", 1000, m10)
	check(whole.line == 1 and whole.at == 15 and whole.x == 140, "a whole word only: never inside SECRETS", whole.at)
	check(S("A HIDDEN EGG", "SECRET", 1000, m10).line == nil, "no such word: no place (the renderer draws plain)")

	-- The real fonts, at the sizes and stack widths the renderer uses. The
	-- metrics are ActionToastUI's (held to its source below).
	local FULL = { head = 26, headMin = 18, icon = 24 }
	local SMALL = { head = 21, headMin = 16, icon = 20 }
	local PHONE = { head = 18, headMin = 14, icon = 17 }
	local TOPBAR = 58
	local function screen(w, h, touch)
		return {
			safe = Vector2.new(w, h - TOPBAR),
			touch = touch,
			keyboard = not touch,
			viewport = Vector2.new(w, h),
			topbar = { x = 208, y = 0, w = w - 208, h = TOPBAR },
			insetTop = TOPBAR,
		}
	end
	local HEAD = Enum.Font.LuckiestGuy
	local function width(text, size)
		return TextService:GetTextSize(text, size, HEAD, Vector2.new(10000, 10000)).X
	end
	local italic = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
	local names = { W.Biome.Label }
	for _, biome in ipairs(BiomeData.Biomes) do
		table.insert(names, biome.DisplayName)
	end
	local screens = {
		{ "1920x1080 desktop", screen(1920, 1080, false) },
		{ "1280x720 desktop", screen(1280, 720, false) },
		{ "1024x600 small window", screen(1024, 600, false) },
		{ "932x430 phone", screen(932, 430, true) },
		{ "844x390 phone", screen(844, 390, true) },
		{ "667x375 phone", screen(667, 375, true) },
		{ "640x360 phone", screen(640, 360, true) },
	}
	local bad, wrappedOn, spill = {}, {}, 0
	for _, entry in ipairs(screens) do
		local L = HudLayout.solve(entry[2])
		local metrics = if L.sidebar or L.toastTop then PHONE elseif L.compact then SMALL else FULL
		local room = math.max(160, L.toast.w) - metrics.icon - 8
		for _, name in ipairs(names) do
			local text = string.format(T.Title, (string.gsub(string.upper(name), " ", "\u{00A0}")))
			local hs = metrics.head
			while hs > metrics.headMin and width(text, hs) > room do
				hs -= 1
			end
			local span = S(text, "SECRET", room, function(t)
				return width(t, hs)
			end)
			local fits = span.line == 1 and #span.lines <= 2 and span.x >= 0 and span.x + span.w <= span.width + 0.5
			for _, line in ipairs(span.lines) do
				fits = fits and width(line, hs) <= room
			end
			if not fits then
				table.insert(bad, string.format("%s/%s", entry[1], name))
			end
			if #span.lines > 1 then
				table.insert(wrappedOn, string.format("%s %s (%d px, room %d)", entry[1], name, hs, room))
			end
			-- The italic face is drawn centred on the headline's own word: how far
			-- past it either side, against the space between the words.
			local params = Instance.new("GetTextBoundsParams")
			params.Text = "SECRET"
			params.Font = italic
			params.Size = hs
			params.Width = 10000
			local okB, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			if okB then
				local over = (bounds.X - span.w) / 2
				local gap = width("A SECRET", hs) - width("A", hs) - width("SECRET", hs)
				spill = math.max(spill, over - math.max(gap, 0))
			end
		end
	end
	check(#bad == 0, string.format("every biome's headline fits on %d screens at the renderer's sizes: the word on the "
		.. "first line, at most two lines, each within the stack", #screens), table.concat(bad, "; "))
	say("        wrapped: " .. (if #wrappedOn == 0 then "none" else table.concat(wrappedOn, "; ")))
	check(spill <= 2,
		"the italic SECRET overhangs the headline's own word by no more than the space beside it (+2 px)",
		string.format("%.1f px", spill))

	--==========================================================================
	say("4. The storm's egg follows the storm's opening, only when there is no room for both")
	--==========================================================================
	local WA = Notice.waitAfter
	local function shown(key, hideAt)
		return { key = key, kind = "info", bornAt = 0, hideAt = hideAt, count = 1 }
	end
	check(WA({}, "rain:5", 1, 1) == 0 and WA({ shown("rain:5", 10) }, "rain:5", 1, 3) == 0,
		"nothing up, or room for both: straight up")
	check(WA({ shown("rain:5", 10) }, "rain:5", 1, 1) == 9,
		"a stack with room for one (a short phone): it waits the opening's 9 s out")
	check(WA({ shown("rain:5", 10), shown("other", 4) }, "rain:5", 1, 2) == 0
		and WA({ shown("rain:5", 4), shown("other", 10) }, "rain:5", 1, 2) == 3,
		"a full stack: it waits only when the opening is the one it would put out")
	check(WA({ shown("rain:5", 0.5) }, "rain:5", 1, 1) == 0, "an opening already leaving: no wait")
	local stack = { shown("rain:5", 10) }
	local wait = WA(stack, "rain:5", 1, 1)
	local verdict, _, evicted = Notice.step(stack, { kind = "secret", title = "A SECRET EGG SPAWNED!", key = "secret:x" },
		1 + wait, 1)
	check(verdict == "show" and #evicted == 0, "after its wait it goes up without putting anything out")
	check(Notice.valid({ kind = "secret", title = "X", after = "rain:5" }) and not Notice.valid({ kind = "secret", title = "X", after = 5 }),
		"`after` is a key or nothing")

	--==========================================================================
	say("5. The REAL road Secret: announced once per spawn")
	--==========================================================================
	local green = raise(biomeOf("greenhollow"))
	local okS = NestService.SpecSpawnSecret(green, "spec")
	local secret = green.secret
	check(okS and secret ~= nil and #told == 1 and told[1].id == secret.id and told[1].biome == "greenhollow"
		and told[1].event == nil and secret.pod and secret.pod:GetAttribute("SecretId") == secret.id,
		"a spawn that stood its pod announces once, with its own id and its biome", #told)
	local okAgain, whyAgain = NestService.SpecSpawnSecret(green, "spec")
	check(not okAgain and #told == 1, "a refused spawn (the spot is taken) announces nothing", whyAgain)
	local dust = raise(biomeOf("dustbowl"))
	local okDust = NestService.SpecSpawnSecret(dust, "spec")
	check(not okDust and #told == 1, "a biome with no Secret: refused, nothing announced")
	-- Confiscated: the guardian carries it home and its rig is lost on the way.
	local firstId = secret.id
	secret.pod:Destroy()
	secret.pod = nil
	green.haul = { speciesId = secret.speciesId, tier = SeedData.SecretTier, fromNest = green.id, model = nil,
		since = clock, secretId = secret.id }
	green.state = "hauling"
	local oldRig = green.parent
	oldRig:Destroy()
	tick(green)
	check(green.parent ~= oldRig and green.haul == nil and green.secret == secret and secret.pod ~= nil
		and secret.pod.Parent ~= nil and secret.pod:GetAttribute("SecretId") == firstId and #told == 1,
		"the guardian rebuilt and the confiscated pod walked back to its spot (same encounter): nothing announced", #told)
	for _ = 1, 12 do
		tick(green)
	end
	check(#told == 1, "and twelve more ticks announce nothing")
	secret.pod:Destroy()
	if secret.platform then
		secret.platform:Destroy()
	end
	green.secret = nil
	local okLater = NestService.SpecSpawnSecret(green, "spec")
	check(okLater and #told == 2 and told[2].id ~= firstId and told[2].biome == "greenhollow",
		"a LATER spawn at the same nest announces again, with a new id", told[2] and told[2].id)

	--==========================================================================
	say("6. The REAL event nest: the Thunderstorm's Pod 3, once, at the opening")
	--==========================================================================
	local base = #told
	check(NestService.OpenEventNest(71, "thunder", site) == 1 and #told == base,
		"laying the storm's nest announces nothing yet")
	check(NestService.AnnounceEventEgg(71) == true and #told == base + 1 and told[base + 1].id == "event:71"
		and told[base + 1].biome == W.Biome.Id and told[base + 1].event == 71,
		"asked at the opening: announced, as the event's spawn, in the weather's biome")
	check(NestService.AnnounceEventEgg(71) == false and #told == base + 1, "asked again: nothing")
	NestService.CloseEventNest(71)
	local rainLaid = NestService.OpenEventNest(72, "rain", site)
	local rainPods = {}
	for _, p in ipairs(NestService.EventNest().pods) do
		table.insert(rainPods, p.pod)
	end
	check(rainLaid == 3 and NestService.AnnounceEventEgg(72) == false and #told == base + 1,
		"a Rain's three pods announce nothing", table.concat(rainPods, ", "))
	NestService.CloseEventNest(72)
	NestService.OpenEventNest(73, "thunder", site)
	NestService.CloseEventNest(73)
	check(NestService.AnnounceEventEgg(73) == false and #told == base + 1,
		"a storm ended before its biome opened: its egg is never announced")
	check(NestService.OpenEventNest(74, "thunder", site) == 1 and NestService.OpenEventNest(75, "thunder", site) == 0
		and NestService.AnnounceEventEgg(75) == false and #told == base + 1,
		"a second nest refused while one stands: nothing to announce for it")
	check(NestService.AnnounceEventEgg(74) == true and #told == base + 2 and told[base + 2].id == "event:74",
		"a later storm's egg announces with its own id")
	NestService.CloseEventNest(nil)
	local okHail = pcall(NestService.OpenEventNest, 76, "hail", site)
	local okNil = pcall(NestService.OpenEventNest, 77, "thunder", nil)
	check(NestService.AnnounceEventEgg(76) == false and NestService.AnnounceEventEgg(77) == false and #told == base + 2,
		"an unknown weather and a nest with no site lay nothing and announce nothing",
		string.format("hail %s, no site %s", tostring(okHail), tostring(okNil)))
	pcall(NestService.CloseEventNest, nil)

	--==========================================================================
	say("7. WeatherService: right after the opening's toast, once, for the console's storm and the automatic one")
	--==========================================================================
	local now = 90000
	local order = {}
	local built = true
	WeatherService.useClock(function()
		return now
	end)
	WeatherService.usePlayers(function()
		return { { Name = "SpecPlayer", UserId = 0 } }
	end)
	WeatherService.useTerrain({
		build = function()
			if not built then
				return nil
			end
			local f = Instance.new("Folder")
			f.Name = "ZZStandInTerrain"
			f.Parent = scratch
			return f
		end,
		setEntry = function() end,
		destroy = function(terrain)
			if terrain then
				terrain:Destroy()
			end
		end,
	})
	WeatherService.useBroadcast(function(action)
		table.insert(order, tostring(action))
	end)
	WeatherService.useMover(function()
		return true
	end)
	-- The REAL nest at the spec's site, under WeatherService's own Step.
	WeatherService.useNest({
		open = function(id, mode, terrain)
			if not terrain then
				return 0
			end
			return (NestService.OpenEventNest(id, mode, site))
		end,
		close = function(id)
			return NestService.CloseEventNest(id)
		end,
		announce = function(id)
			local said = NestService.AnnounceEventEgg(id)
			table.insert(order, "announce:" .. tostring(id) .. "=" .. tostring(said))
			return said
		end,
	})
	WeatherService.Init()
	local function finishEvent()
		WeatherService.EndRain({ Name = "owner" })
		for _ = 1, 4 do
			now += W.ThickenSeconds + W.FadeSeconds + 1
			WeatherService.Step(now)
		end
	end
	local function lastAnnounce()
		for i = #order, 1, -1 do
			if string.sub(order[i], 1, 9) == "announce:" then
				return i
			end
		end
		return nil
	end

	-- The console's thunderstorm.
	local before = #told
	local okT = WeatherService.StartThunderstorm({ Name = "owner" }, 60)
	local id1 = WeatherService.State().id
	WeatherService.Step(now)
	check(okT and #told == before and lastAnnounce() == nil, "started and still opening: nothing announced")
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	local at = lastAnnounce()
	check(#told == before + 1 and told[#told].id == "event:" .. id1 and at ~= nil
		and order[at - 1] == W.Events.Opened and order[at] == "announce:" .. id1 .. "=true",
		"at the opening: the opening's toast, then the egg's -- once", table.concat(order, ", "))
	for _ = 1, 20 do
		now += 1
		WeatherService.Step(now)
	end
	local okRepeat = WeatherService.StartThunderstorm({ Name = "owner" }, 60)
	WeatherService.Step(now)
	check(not okRepeat and #told == before + 1, "twenty seconds on, and a repeated START refused: nothing more")
	finishEvent()
	check(WeatherService.State() == nil and NestService.EventNest() == nil, "(the storm over and cleared)")

	-- An ordinary Rain from the console.
	local okR = WeatherService.StartRain({ Name = "owner" }, 60)
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	local idR = WeatherService.State().id
	check(okR and #told == before + 1 and order[lastAnnounce()] == "announce:" .. idR .. "=false",
		"a Rain opens, is asked, and announces nothing")
	finishEvent()

	-- The automatic thunderstorm: the real settings, a scripted draw (a start
	-- needs a draw under 0.05; a mode draw from 0.9 is a Thunderstorm).
	local draws, used = { 0.01, 0.95 }, 0
	WeatherService.useRandom(function()
		used += 1
		return draws[used] or 0.99
	end)
	WeatherService.useAutoConfig(nil)
	now += 1
	WeatherService.AutoStep(now)
	now += W.Auto.CheckSeconds
	local what = WeatherService.AutoStep(now)
	local idA = WeatherService.State() and WeatherService.State().id
	check(what == "started:thunder" and idA ~= nil and #told == before + 1,
		"the scheduler starts a thunderstorm (draws 0.01 then 0.95); nothing announced yet", what)
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	WeatherService.AutoStep(now)
	check(#told == before + 2 and told[#told].id == "event:" .. tostring(idA) and told[#told].event == idA,
		"at its opening the same route announces its egg -- once", #told)
	for _ = 1, 20 do
		now += 1
		WeatherService.Step(now)
		WeatherService.AutoStep(now)
	end
	check(#told == before + 2, "and nothing more while it runs")
	finishEvent()

	-- A biome that never builds never opens: its egg is never announced.
	built = false
	local okF = WeatherService.StartThunderstorm({ Name = "owner" }, 60)
	for _ = 1, 40 do
		now += 1
		WeatherService.Step(now)
	end
	check(okF and #told == before + 2 and WeatherService.State().state == "opening",
		"a storm whose biome did not build stays shut: nothing announced", WeatherService.State().state)
	finishEvent()
	built = true

	--==========================================================================
	say("8. One route, no new channel")
	--==========================================================================
	local nestSrc = sourceOf(Server, "NestService")
	local weatherSrc = sourceOf(Server, "WeatherService")
	local toastSrc = sourceOf(StarterPlayer.StarterPlayerScripts, "ActionToastUI")
	check(count(nestSrc, "announceSecretEgg(") == 3 and count(nestSrc, '"SecretSpawned"') == 1
		and string.find(nestSrc, "\tannounceSecretEgg(secret.id, nest.biome.Id)\n", 1, true) ~= nil,
		"NestService: one announcer, called by spawnSecret (after its pod stood) and AnnounceEventEgg only")
	local standA = string.find(nestSrc, "local function standSecretPod", 1, true)
	local standB = standA and string.find(nestSrc, "\nend\n", standA, true)
	check(standA and standB and not string.find(string.sub(nestSrc, standA, standB), "announce", 1, true),
		"standing a pod (the route a confiscated pod walks back by) announces nothing")
	check(count(nestSrc, "eventEggs[eventId] = NestService.WeatherEggCount(laid)") == 1,
		"an event's egg is recorded in one place: OpenEventNest, after its nest stands")
	local openA = string.find(weatherSrc, "broadcast(EVENTS.Opened, event.id, nil)", 1, true)
	local askA = string.find(weatherSrc, "pcall(announce, event.id)", 1, true)
	check(count(weatherSrc, "pcall(announce, event.id)") == 1 and openA and askA and askA > openA
		and askA - openA < 400,
		"WeatherService asks in one place: the opening, right after the opening's broadcast")
	local callers = {}
	for _, inst in ipairs(game:GetService("ServerScriptService"):GetDescendants()) do
		if inst:IsA("LuaSourceContainer") and inst.Name ~= "NestService" then
			local n = count(inst.Source, "AnnounceEventEgg") + count(inst.Source, "SecretSpawned")
			if n > 0 then
				table.insert(callers, inst.Name)
			end
		end
	end
	check(#callers == 1 and callers[1] == "WeatherService", "no other server script announces", table.concat(callers, ", "))
	check(count(toastSrc, 'Instance.new("ScreenGui")') == 1 and count(toastSrc, "local seenSecrets") == 1
		and string.find(toastSrc, "Notice.secretPost(news, GameConfig.Secret.Toast, biomeName, seenSecrets)", 1, true) ~= nil
		and string.find(toastSrc, 'post.after = "rain:" .. tostring(event)', 1, true) ~= nil
		and string.find(toastSrc, 'key = "rain:" .. tostring(code),', 1, true) ~= nil
		and string.find(toastSrc, "Notice.waitAfter(stack, after, now, maxShown)", 1, true) ~= nil,
		"the client: the one toast gui, one record of shown spawns for the session, the storm's egg following "
			.. "the storm's own toast key")
	check(string.find(toastSrc, "if id == GameConfig.Weather.Biome.Id then\n\t\treturn GameConfig.Weather.Biome.Label", 1, true) ~= nil
		and string.find(toastSrc, "local FULL: Metrics = { head = 26, headMin = 18, detail = 15, detailMin = 12, icon = 24,", 1, true) ~= nil
		and string.find(toastSrc, "local SMALL: Metrics = { head = 21, headMin = 16, detail = 13, detailMin = 11, icon = 20,", 1, true) ~= nil
		and string.find(toastSrc, "local PHONE: Metrics = { head = 18, headMin = 14, detail = 12, detailMin = 11, icon = 17,", 1, true) ~= nil,
		"(this spec's names and sizes are the renderer's own)")
end)

NestService.SpecAnnouncer(nil)
WeatherService.useClock(nil)
WeatherService.usePlayers(nil)
WeatherService.useTerrain(nil)
WeatherService.useBroadcast(nil)
WeatherService.useMover(nil)
WeatherService.useNest(nil)
WeatherService.useRandom(nil)
WeatherService.useAutoConfig(nil)
WeatherService.Init()
pcall(NestService.CloseEventNest, nil)
scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("SecretToastSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
