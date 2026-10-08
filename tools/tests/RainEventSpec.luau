--!nocheck
--==============================================================================
-- Steal a Seed :: RainEventSpec
--
-- The Rain event (2026-10-02; WeatherService, RainBiome, the console's WEATHER
-- category): any of the three admin accounts may start or end it (the owner's
-- alone until 2026-10-07), nobody else may, and a malformed
-- request starts nothing; one event at a time, a second START changes nothing
-- and a second END is harmless; exactly one x1.25 on online planted income,
-- on top of the pass and the temporary boosts, gone the moment it ends, and
-- nothing else -- sale, base rate, offline -- changed; the opening toast waits
-- for its delay AND the terrain, is sent once, and never after an early end;
-- a late joiner reads the right state; the deadline ends it; those on the
-- terrain, and only those, are put down on clear island ground at the
-- entrance, apart from each other, and the terrain goes only after them. The
-- bridge, the landing and the biome keep clear of every plot at its top
-- level and of the obby. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RainEventSpec"))
--
-- The event is walked on the spec's own clock through WeatherService's seams:
-- stand-in players with a part for a body, a counting terrain, a recording
-- remote and mover. Not here, seen in Play instead: the real console's
-- buttons, the rain, the fog, the walk across the bridge, a carried pod.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local HudLayout = require(Shared.HudLayout)
local ObbyData = require(Shared.ObbyData)
local WeatherService = require(Server.WeatherService)
local RainBiome = require(Server.RainBiome)
local AdminService = require(Server.AdminService)
local EconomyService = require(Server.EconomyService)
local MapService = require(Server.MapService)
local PlotService = require(Server.PlotService)
local PlantService = require(Server.PlantService)
local PassService = require(Server.PassService)
local BonusChestService = require(Server.BonusChestService)
local SacrificeService = require(Server.SacrificeService)
local OfflineEarnings = require(Server.OfflineEarnings)
local CarryService = require(Server.CarryService)

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
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function count(text, plain)
	local n, at = 0, 1
	while true do
		local s, e = string.find(text, plain, at, true)
		if not s then
			return n
		end
		n += 1
		at = e + 1
	end
end

local W = GameConfig.Weather
local ATTR = W.Attributes
local EVENTS = W.Events
local B = W.Biome
local OWNER_ID, OTHER_ADMIN_ID = 4119740186, 11607308004

local scratch = Instance.new("Folder")
scratch.Name = "ZZRainEventSpec"
scratch.Parent = Workspace

-- A stand-in player: a name, a UserId and a body with a root part.
local function standIn(name, userId, position)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root
	model.Parent = scratch
	return { Name = name, UserId = userId, Character = model }
end

-- The seams.
local now = 100000
local players = {}
local builds, destroys, entries, sent, moves = 0, 0, {}, {}, {}
local buildReady = true
local function reset()
	builds, destroys, entries, sent, moves = 0, 0, {}, {}, {}
end
WeatherService.useClock(function()
	return now
end)
WeatherService.usePlayers(function()
	return players
end)
WeatherService.useTerrain({
	build = function(parent)
		builds += 1
		if not buildReady then
			return nil
		end
		local f = Instance.new("Folder")
		f.Name = "ZZFakeRainTerrain"
		f.Parent = scratch
		return f
	end,
	setEntry = function(terrain, open)
		table.insert(entries, open)
	end,
	destroy = function(terrain)
		destroys += 1
		if terrain then
			terrain:Destroy()
		end
	end,
})
WeatherService.useBroadcast(function(action, payload, to)
	table.insert(sent, { action = action, payload = payload, to = to })
end)
local function recordingMover(player, cf)
	table.insert(moves, { player = player, cf = cf })
	player.Character:PivotTo(cf)
	return true
end
WeatherService.useMover(recordingMover)
local function sentOf(action)
	local list = {}
	for _, s in ipairs(sent) do
		if s.action == action then
			table.insert(list, s)
		end
	end
	return list
end

local realInterval = AdminService.Config.MinInterval
AdminService.Config.MinInterval = 0
local owner = standIn("Owner", OWNER_ID, Vector3.new(0, 3, 0))
local otherAdmin = standIn("OtherAdmin", OTHER_ADMIN_ID, Vector3.new(4, 3, 0))
local stranger = standIn("Stranger", 42, Vector3.new(8, 3, 0))

local plots, plants, passes = PlotService, PlantService, PassService
local chest, sacrifice = BonusChestService, SacrificeService
local real = {
	PlotOf = plots.PlotOf, OwnerOf = plots.OwnerOf, GrownIn = plants.GrownIn,
	CashMultiplier = passes.CashMultiplier, Chest = chest.Multiplier, Sacrifice = sacrifice.Multiplier,
}

local ok, err = pcall(function()
	WeatherService.Init()
	--==========================================================================
	say("1. Every admin account, nobody else, and nothing malformed starts anything")
	--==========================================================================
	local function ask(who, verb, seconds)
		return AdminService.Handle(who, "Weather", verb, seconds, nil)
	end
	local r = ask(stranger, "start", 60)
	check(r.ok == false and r.message == "Not authorized." and WeatherService.State() == nil and builds == 0,
		"a stranger's request is refused before anything is looked at, and no event exists", r.message)
	-- Every admin's since 2026-10-07: the OTHER allowlisted account is admitted.
	-- Asked here without making an event (the event below is the owner's):
	-- its zero-second START is refused for the duration alone, and its END
	-- with nothing running is the harmless one.
	r = ask(otherAdmin, "start", 0)
	check(r.ok == false and string.find(r.message, "Duration must be", 1, true) ~= nil and WeatherService.State() == nil
			and builds == 0,
		"the OTHER allowlisted admin is admitted -- the weather is every admin's: its zero-second START is refused "
			.. "for the duration alone", r.message)
	r = ask(otherAdmin, "end", nil)
	check(r.ok == true and string.find(r.message, "No rain or thunderstorm", 1, true) ~= nil
			and WeatherService.State() == nil,
		"...and may end it too (with nothing running, the harmless END)", r.message)
	local refused = 0
	local bad = { "60", 0 / 0, 2.5, 0, -30, W.MinSeconds - 1, W.MaxSeconds + 1, 1e12, true, {} }
	for _, seconds in ipairs(bad) do
		local reply = ask(owner, "start", seconds)
		if reply.ok == false and WeatherService.State() == nil then
			refused += 1
		end
	end
	local nilReply = ask(owner, "start", nil)
	check(refused == #bad and nilReply.ok == false and builds == 0 and WeatherService.State() == nil,
		"a string, NaN, a fraction, zero, a negative, below the floor, above the ceiling, huge, a boolean, a table "
			.. "and nil are each refused with no event and no terrain", refused .. " of " .. #bad)
	r = ask(owner, "bogus", 60)
	check(r.ok == false and WeatherService.State() == nil, "an unknown verb is refused", r.message)
	r = ask(owner, "start", 60)
	local s = WeatherService.State()
	check(r.ok == true and s ~= nil and s.state == "opening" and s.id == 1 and s.endsAt == now + 60 and builds == 1
			and entries[1] == false and s.ready == true,
		"the owner's START makes the one event: opening, a deadline, the terrain built once with its entrance SHUT",
		r.message)
	check(Workspace:GetAttribute(ATTR.State) == "opening" and Workspace:GetAttribute(ATTR.EventId) == 1
			and Workspace:GetAttribute(ATTR.EndsAt) == now + 60
			and Workspace:GetAttribute(ATTR.Factor) == SeedData.Rain.IncomeFactor,
		"and publishes it: state, id, deadline and the factor, as every client reads them")

	--==========================================================================
	say("2. One event at a time: a second START changes nothing, a second END is harmless")
	--==========================================================================
	r = ask(owner, "start", 90)
	s = WeatherService.State()
	check(r.ok == false and string.find(r.message, "already falling", 1, true) ~= nil and s.id == 1
			and s.endsAt == now + 60 and builds == 1,
		"a second START is refused: same event, same deadline, no second terrain, no restart", r.message)
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	s = WeatherService.State()
	check(s.state == "active" and entries[#entries] == true and #sentOf(EVENTS.Opened) == 1
			and sentOf(EVENTS.Opened)[1].payload == 1 and sentOf(EVENTS.Opened)[1].to == nil,
		"after the delay the entrance opens and everyone here is told once, by the event's id")
	WeatherService.Step(now + 0.5)
	WeatherService.Step(now + 1)
	check(#sentOf(EVENTS.Opened) == 1 and WeatherService.IncomeFactor() == SeedData.Rain.IncomeFactor,
		"more steps announce nothing more, and the bonus stays exactly the one factor")
	r = ask(owner, "start", 60)
	check(r.ok == false and builds == 1 and #sentOf(EVENTS.Opened) == 1,
		"a START while it is open is refused too: no stacking of the bonus, no second toast")
	now += 1
	r = ask(owner, "end", nil)
	s = WeatherService.State()
	check(r.ok == true and s.state == "closing" and s.closingAt == now and entries[#entries] == false
			and Workspace:GetAttribute(ATTR.Factor) == 1 and WeatherService.IncomeFactor() == 1,
		"END closes it: the entrance shut again and the bonus off at once", r.message)
	local before = #entries
	r = ask(owner, "end", nil)
	check(r.ok == true and string.find(r.message, "already ending", 1, true) ~= nil and #entries == before
			and WeatherService.State().state == "closing" and destroys == 0,
		"a second END is harmless: nothing restarts, nothing is torn down early", r.message)
	r = ask(owner, "start", 60)
	check(r.ok == false and string.find(r.message, "still clearing", 1, true) ~= nil and builds == 1,
		"a START while it closes is refused: the biome finishes fading first")
	now += W.ThickenSeconds + W.FadeSeconds + 0.5
	WeatherService.Step(now)
	check(WeatherService.State() == nil and destroys == 1 and Workspace:GetAttribute(ATTR.State) == nil
			and Workspace:GetAttribute(ATTR.Factor) == nil and Workspace:GetAttribute(ATTR.EventId) == nil,
		"after the fade the terrain is removed exactly once and every attribute is cleared")
	r = ask(owner, "end", nil)
	check(r.ok == true and string.find(r.message, "No rain", 1, true) ~= nil and destroys == 1,
		"END with no rain is harmless", r.message)

	--==========================================================================
	say("3. Exactly +25% on online planted income, once, and gone the moment it ends")
	--==========================================================================
	reset()
	local payer = { Name = "Payer", UserId = 9001 }
	local plot = Instance.new("Model")
	local grown = { { species = SeedData.Get("nubkin"), tier = 7 } }
	local passMul, chestMul, sacrificeMul = 1, 1, 1
	plots.PlotOf = function(p)
		return if p == payer then plot else nil
	end
	plots.OwnerOf = function(m)
		return if m == plot then payer else nil
	end
	plants.GrownIn = function(m)
		return if m == plot then grown else {}
	end
	passes.CashMultiplier = function()
		return passMul
	end
	chest.Multiplier = function()
		return chestMul
	end
	sacrifice.Multiplier = function()
		return sacrificeMul
	end
	local base = SeedData.IncomePerSecond(SeedData.Get("nubkin"), 7)
	local dry = EconomyService.RateFor(payer)
	check(dry == base and base == 9500, "with no rain the faucet pays the base rate ($9,500/s for a Colossal Nubkin)", dry)
	ask(owner, "start", 60)
	local wet = EconomyService.RateFor(payer)
	check(wet == base * SeedData.Rain.IncomeFactor and wet == 11875,
		"while it rains, exactly x1.25: $11,875/s", wet)
	check(GameConfig.rainIncomeFactor() == SeedData.Rain.IncomeFactor,
		"the display's factor is the same number, read off the attribute the server published")
	chestMul = 1.25
	check(EconomyService.RateFor(payer) == base * 1.25 * SeedData.Rain.IncomeFactor,
		"a chest's +25% still applies as before, and the rain multiplies the result once", EconomyService.RateFor(payer))
	chestMul, sacrificeMul = 1.25, 1.5
	check(EconomyService.RateFor(payer) == base * 1.75 * SeedData.Rain.IncomeFactor,
		"chest and sacrifice still ADD to +75%; the rain multiplies that", EconomyService.RateFor(payer))
	chestMul, sacrificeMul, passMul = 1, 1, 2
	check(EconomyService.RateFor(payer) == base * 2 * SeedData.Rain.IncomeFactor,
		"the x2 pass still doubles, and the rain multiplies that: $23,750/s", EconomyService.RateFor(payer))
	grown = { { species = SeedData.Get("snarlbloom"), tier = 1 } }
	check(EconomyService.RateFor(payer) == 155000 * 2 * SeedData.Rain.IncomeFactor,
		"a Secret's fixed rate gets the same one factor ($387,500/s under the pass)", EconomyService.RateFor(payer))
	passMul = 1
	grown = { { species = SeedData.Get("nubkin"), tier = 7 } }
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	check(EconomyService.RateFor(payer) == wet, "it pays the same with the entrance open")
	ask(owner, "end", nil)
	check(EconomyService.RateFor(payer) == base and GameConfig.rainIncomeFactor() == 1
			and Workspace:GetAttribute(ATTR.Factor) == 1,
		"the moment it ends the rate is the base again, before the biome has faded", EconomyService.RateFor(payer))
	now += 10
	WeatherService.Step(now)
	check(EconomyService.RateFor(payer) == base and WeatherService.State() == nil, "...and after the fade")
	plot:Destroy()
	-- Nothing else moved.
	ask(owner, "start", 60)
	local offline = OfflineEarnings.garden({ { SpeciesId = "nubkin", Tier = 7, Stage = 3 } })
	check(offline.rate == base and SeedData.SellPrice(SeedData.Get("nubkin"), 7) == base * SeedData.SellSeconds
			and SeedData.IncomePerSecond(SeedData.Get("nubkin"), 7) == base,
		"while it rains the offline rate, the sale price and the base rate are untouched")
	local economySrc = sourceOf(Server, "EconomyService")
	check(count(economySrc, "WeatherService.IncomeFactor()") == 1
			and string.find(economySrc, "return withPass(player, rate) * temporaryBoost(player) * WeatherService.IncomeFactor()", 1, true) ~= nil,
		"EconomyService multiplies by the weather exactly once, on RateFor's last line -- sales and the offline claim never see it")
	check(string.find(sourceOf(Server, "OfflineEarnings"), "Weather", 1, true) == nil
			and string.find(sourceOf(Shared, "GameConfig"), "* GameConfig.rainIncomeFactor()", 1, true) ~= nil,
		"the offline arithmetic knows no weather; the display multiplier is the same product")
	ask(owner, "end", nil)
	now += 10
	WeatherService.Step(now)

	--==========================================================================
	say("4. The opening toast waits for its delay AND the terrain, once; never after an early end")
	--==========================================================================
	reset()
	buildReady = false
	ask(owner, "start", 60)
	WeatherService.Step(now + 1)
	WeatherService.Step(now + W.ToastDelaySeconds)
	WeatherService.Step(now + 10)
	s = WeatherService.State()
	check(s.state == "opening" and #sentOf(EVENTS.Opened) == 0 and s.ready == false,
		"with the terrain not ready, three seconds pass and nothing is announced: no toast for an entrance that is not there")
	WeatherService.TerrainReady()
	now += 10.5
	WeatherService.Step(now)
	check(WeatherService.State().state == "active" and #sentOf(EVENTS.Opened) == 1,
		"the moment it is ready, the entrance opens and the toast goes out -- once")
	buildReady = true
	ask(owner, "end", nil)
	now += 10
	WeatherService.Step(now)
	reset()
	ask(owner, "start", 60)
	WeatherService.Step(now + 1)
	ask(owner, "end", nil)
	now += 1
	WeatherService.Step(now + W.ToastDelaySeconds)
	WeatherService.Step(now + 10)
	check(#sentOf(EVENTS.Opened) == 0 and WeatherService.State() == nil and destroys == 1,
		"ended before it opened: no opening toast ever, the terrain removed after the fade")
	now += 10

	--==========================================================================
	say("5. A late joiner reads the right state; the deadline ends it")
	--==========================================================================
	reset()
	ask(owner, "start", 30)
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	-- A client joining now reads these and nothing is sent to it.
	check(Workspace:GetAttribute(ATTR.State) == "active" and Workspace:GetAttribute(ATTR.EndsAt) - now == 27
			and Workspace:GetAttribute(ATTR.Factor) == SeedData.Rain.IncomeFactor
			and Workspace:GetAttribute(ATTR.OpenedAt) == now and #sentOf(EVENTS.Opened) == 1,
		"a late joiner finds the state, the time left, the factor and when it opened on the attributes; the toast went only to those here then")
	now += 27 - W.WarnSeconds
	WeatherService.Step(now)
	check(#sentOf(EVENTS.Warning) == 0 and WeatherService.State().state == "active",
		"the warning before a timed end goes to those inside; with nobody inside, nothing is sent")
	now += W.WarnSeconds
	WeatherService.Step(now)
	s = WeatherService.State()
	check(s.state == "closing" and s.closingAt == now and WeatherService.IncomeFactor() == 1,
		"at the deadline it closes on its own: the bonus off, the entrance shut")
	now += W.ThickenSeconds + W.FadeSeconds + 0.3
	WeatherService.Step(now)
	check(WeatherService.State() == nil and destroys == 1, "and the terrain is removed after the fade")

	--==========================================================================
	say("6. Who is on the terrain, and a safe evacuation to the entrance")
	--==========================================================================
	local inside = {
		{ "the ramp", Vector3.new(250, 3, 70), true },
		{ "the deck", Vector3.new(280, 12, 70), true },
		{ "the mouth", Vector3.new(362, 3, 104), true },
		{ "the approach", Vector3.new(450, 3, 140), true },
		{ "the pond room", Vector3.new(540, 3, 174), true },
		{ "the hollow", Vector3.new(720, 3, 146), true },
		{ "the nest clearing", Vector3.new(872, 3, 186), true },
		{ "the landing grass", Vector3.new(232, 3, 70), false },
		{ "the hub", Vector3.new(0, 3, 0), false },
		{ "south of the approach, off its floor", Vector3.new(450, 3, 20), false },
		{ "past the clearing's end", Vector3.new(1000, 3, 186), false },
		{ "far above the corridor", Vector3.new(450, 100, 140), false },
		{ "fallen below it", Vector3.new(450, -20, 140), false },
	}
	local wrong = {}
	for _, c in ipairs(inside) do
		if RainBiome.Contains(c[2]) ~= c[3] then
			table.insert(wrong, c[1])
		end
	end
	check(#wrong == 0, "on the terrain: the ramp, the deck, the corridors, the pond room and the clearing; not the landing "
		.. "grass, the hub, beside the garden, past the end, far above or fallen below", table.concat(wrong, ", "))
	reset()
	local a = standIn("Inside1", 1001, Vector3.new(450, 3, 140))
	local b = standIn("Inside2", 1002, Vector3.new(560, 3, 160))
	local c = standIn("OnBridge", 1003, Vector3.new(282, 12, 70))
	local d = standIn("OnIsland", 1004, Vector3.new(120, 3, 40))
	players = { owner, a, b, c, d }
	ask(owner, "start", 60)
	now += W.ToastDelaySeconds
	WeatherService.Step(now)
	local occupants = WeatherService.Occupants()
	check(#occupants == 3, "three of five are on the terrain", #occupants)
	ask(owner, "end", nil)
	check(#moves == 3 and #sentOf(EVENTS.Evacuated) == 3,
		"END moves exactly those three, and tells each once", #moves)
	local landed, apart, grounded, offTerrain, inSafe = 0, true, true, true, true
	local field = Workspace:FindFirstChild(GameConfig.Map.FolderName)
	field = field and field:FindFirstChild(GameConfig.Map.FieldName)
	for i, m in ipairs(moves) do
		local p = m.cf.Position
		landed += 1
		if RainBiome.Contains(p) or p.X >= B.Ramp.X0 then
			offTerrain = false
		end
		if not MapService.IsInSafeZone(p) then
			inSafe = false
		end
		for j, other in ipairs(moves) do
			if j ~= i and (other.cf.Position - p).Magnitude < 4 then
				apart = false
			end
		end
		if field then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { field }
			if not Workspace:Raycast(p, Vector3.new(0, -12, 0), params) then
				grounded = false
			end
		end
	end
	check(landed == 3 and offTerrain and inSafe and apart,
		"each lands on the island's own ground before the ramp -- never the bridge or the floor -- at least 4 studs from the others")
	check(field == nil or grounded, if field then "and the field is under every landing spot (the built map)"
		else "(no built map in this Edit session: the ground probe was not run)")
	check(d.Character:GetPivot().Position.X == 120, "the player on the island was not moved")
	local moved = 0
	for _, m in ipairs(moves) do
		if m.player == d then
			moved += 1
		end
	end
	check(moved == 0, "...and was not told anything", moved)
	-- Somebody gets back onto the terrain during the fade: put back again, and
	-- the terrain waits for them.
	a.Character:PivotTo(CFrame.new(320, 3, 70))
	now += W.ThickenSeconds + W.FadeSeconds + 0.5
	WeatherService.Step(now)
	check(WeatherService.State() ~= nil and destroys == 0 and #moves == 4 and #sentOf(EVENTS.Evacuated) == 3,
		"a straggler on the bridge at the end of the fade is put back again (told only once) and the terrain is "
			.. "kept for one more tick", string.format("moves %d, destroys %d", #moves, destroys))
	now += 0.5
	WeatherService.Step(now)
	check(WeatherService.State() == nil and destroys == 1, "the next tick, with nobody on it, the terrain goes")
	-- The real mover: a body is pivoted to the spot with its momentum taken off.
	WeatherService.useMover(nil)
	players = { owner, a }
	a.Character:PivotTo(CFrame.new(400, 3, 70))
	ask(owner, "start", 60)
	now += 1
	ask(owner, "end", nil)
	local where = a.Character:GetPivot().Position
	check(where.X < B.Ramp.X0 and math.abs(where.Z - B.Landing.Z) <= B.Landing.Spread * 3 + 0.01,
		"the real mover pivots the body to a landing spot", tostring(where))
	WeatherService.useMover(recordingMover)
	now += 10
	WeatherService.Step(now)
	local weatherSrc = sourceOf(Server, "WeatherService")
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(weatherSrc, "CarryService.NoteServerMove(player :: Player, cf.Position)", 1, true) ~= nil
			and string.find(carrySrc, "function CarryService.NoteServerMove(player: Player, at: Vector3)", 1, true) ~= nil
			and string.find(carrySrc, "CarryGuard.reset(state, at)", 1, true) ~= nil,
		"a carrier moved by the server keeps the pod: the travel guard is re-anchored, never undone")
	local okNote = pcall(CarryService.NoteServerMove, a, Vector3.new(232, 3, 70))
	check(okNote, "telling the guard about a player who carries nothing is a no-op")
	players = {}

	--==========================================================================
	say("7. The bridge, the landing and the biome keep clear of every plot and the obby")
	--==========================================================================
	-- The plots' TOP-LEVEL footprints, in each plot's gate frame (x across, z
	-- into the plot): the lot, the wing and the mill, measured off the built map
	-- in the retired footprint study (2026-10-02) and held by it then.
	local MAP = GameConfig.Map
	local zones = {
		{ x0 = -24, x1 = 24, z0 = 0, z1 = 96.2 },
		{ x0 = 24, x1 = 64, z0 = 25.4, z1 = 96.2 },
		{ x0 = 21.3, x1 = 50.7, z0 = 0.2, z1 = 23.6 },
	}
	local function gateFrame(plotId)
		local gap = math.rad(MAP.RoadGapDegrees)
		local step = (math.pi * 2 - gap) / GameConfig.MaxPlots
		local angle = math.pi + gap * 0.5 + (plotId - 0.5) * step
		local ix, iz = math.sin(angle), math.cos(angle)
		return { ox = ix * MAP.PlotRingInner, oz = iz * MAP.PlotRingInner, rx = iz, rz = -ix, ix = ix, iz = iz }
	end
	-- World x/z into a plot's frame.
	local function toPlot(f, x, z)
		local dx, dz = x - f.ox, z - f.oz
		return dx * f.rx + dz * f.rz, dx * f.ix + dz * f.iz
	end
	local boxes = {
		{ "the landing grid", B.Landing.X - (B.Landing.Rows - 1) * B.Landing.Spread - 2, B.Landing.X + 2,
			B.Landing.Z - (B.Landing.Columns - 1) / 2 * B.Landing.Spread - 2,
			B.Landing.Z + (B.Landing.Columns - 1) / 2 * B.Landing.Spread + 2 },
		{ "the ramp and the gate", B.Ramp.X0, B.Deck.X0, B.Deck.Z - B.Gate.Width / 2, B.Deck.Z + B.Gate.Width / 2 },
		{ "the bridge", B.Deck.X0, B.Descent.X1, B.Deck.Z - B.Deck.Width / 2, B.Deck.Z + B.Deck.Width / 2 },
	}
	-- Every room and corridor of the route, walls included.
	local southmost = math.huge
	for _, fp in ipairs(RainBiome.Footprints()) do
		table.insert(boxes, { fp.name, fp.x0, fp.x1, fp.z0, fp.z1 })
		southmost = math.min(southmost, fp.z0)
	end
	local MARGIN = 8
	local nearest, worst = math.huge, ""
	for _, box in ipairs(boxes) do
		for plotId = 1, GameConfig.MaxPlots do
			local f = gateFrame(plotId)
			for _, zone in ipairs(zones) do
				-- Sample the box's edge every two studs; the distance to the zone's
				-- rectangle in the plot's own frame.
				local x0, x1, z0, z1 = box[2], box[3], box[4], box[5]
				local function sample(x, z)
					local px, pz = toPlot(f, x, z)
					local dx = math.max(zone.x0 - px, 0, px - zone.x1)
					local dz = math.max(zone.z0 - pz, 0, pz - zone.z1)
					local dist = math.sqrt(dx * dx + dz * dz)
					if dist < nearest then
						nearest, worst = dist, string.format("%s vs plot %d", box[1], plotId)
					end
				end
				for x = x0, x1, 2 do
					sample(x, z0)
					sample(x, z1)
				end
				for z = z0, z1, 2 do
					sample(x0, z)
					sample(x1, z)
				end
			end
		end
	end
	check(nearest >= MARGIN, string.format("every piece keeps at least %d studs from every plot at its top level "
		.. "(nearest %.1f: %s)", MARGIN, nearest, worst))
	-- The obby: its entrance arch on the island, and its floating course.
	local arch = ObbyData.Entrance.At
	local archClear = math.huge
	for _, box in ipairs(boxes) do
		local dx = math.max(box[2] - arch.X, 0, arch.X - box[3])
		local dz = math.max(box[4] - arch.Z, 0, arch.Z - box[5])
		archClear = math.min(archClear, math.sqrt(dx * dx + dz * dz))
	end
	local maxZ = -math.huge
	local function walk(t, depth)
		if type(t) ~= "table" or depth > 6 then
			return
		end
		for k, v in pairs(t) do
			if typeof(v) == "Vector3" and (k == "at" or k == "At" or k == "replayAt" or k == "returnAt") then
				maxZ = math.max(maxZ, v.Z)
			elseif type(v) == "table" then
				walk(v, depth + 1)
			end
		end
	end
	walk(ObbyData, 0)
	-- Its widest piece is 18 studs long (ObbyData's spinners): 9 either side of
	-- its anchor, and a few more for luck.
	local courseZ = ObbyData.Origin.Z + maxZ + 12
	local courseAbove = ObbyData.Origin.Y - (GameConfig.Map.GroundY + B.WallHeight)
	-- The course keeps clear sideways (it stays south of the route's walls) or
	-- overhead; since the walls stand the road's 46 studs, it is sideways.
	check(archClear >= 40 and (courseZ <= southmost - MARGIN or courseAbove >= MARGIN),
		string.format("the obby's entrance is %.0f studs from the nearest piece; its course reaches no further "
			.. "north than z %.0f, %.0f studs short of the route's southernmost wall (and %.0f studs over the walls' top)",
			archClear, courseZ, southmost - courseZ, courseAbove))
	-- The landing grid on the built map: clear spots to put people down on.
	if field then
		local clear = 0
		for i = 1, RainBiome.LandingCount() do
			if RainBiome.SpotClear(RainBiome.LandingSpot(i), {}) then
				clear += 1
			end
		end
		check(clear >= 6, string.format("%d of the %d landing spots are clear on the built map (nothing solid in them, "
			.. "the field under them)", clear, RainBiome.LandingCount()))
	else
		say("  (no built map in this Edit session: the landing spots' clearance was not probed)")
	end

	--==========================================================================
	say("7b. The route: as long as two biomes, gently bent, four sections, a floor the whole way, an open lane, a nest")
	--==========================================================================
	local target = 2 * GameConfig.Map.SegmentLength
	local length = RainBiome.RouteLength()
	check(length >= target * 0.95 and length <= target * 1.15,
		string.format("the walk from the ramp's foot to the nest is %.0f studs, against %d for Greenhollow and Dustbowl together",
			length, target))
	local segs = RainBiome.Segments()
	local worstBend = 0
	for i = 2, #segs do
		local dot = segs[i - 1].dir:Dot(segs[i].dir)
		worstBend = math.max(worstBend, math.deg(math.acos(math.clamp(dot, -1, 1))))
	end
	local sections = {}
	for _, n in ipairs(B.Route) do
		sections[n.section] = true
	end
	local closes = true
	for j, n in ipairs(B.Route) do
		if j > 1 and n.r <= segs[j - 1].hw + 0.5 then
			closes = false
		end
		if j < #B.Route and n.r <= segs[j].hw + 0.5 then
			closes = false
		end
	end
	check(#segs == 3 and worstBend <= 30 and sections.Entrance and sections.Garden and sections.Passage and sections.Nest
		and closes, string.format("three corridors bending at most %.0f degrees through the four sections, every room wider "
		.. "than its corridors' walls", worstBend))
	-- The road's own usable width, the clear floor between a biome's walls.
	local roadWidth = GameConfig.Map.CorridorWidth
	local allRoad = true
	for j = 1, #B.Route - 1 do
		if B.Route[j].w ~= roadWidth then
			allRoad = false
		end
	end
	check(roadWidth == 140 and RainBiome.CorridorWidth() == roadWidth and allRoad and B.Deck.Width >= 40
		and B.Gate.Width > B.Deck.Width and B.WallHeight == GameConfig.Map.WallHeight,
		string.format("every corridor is %d studs clear, the road's own width between its walls, under the road's %d-stud walls; "
			.. "the bridge is %d wide under a %d-wide gate", roadWidth, B.WallHeight, B.Deck.Width, B.Gate.Width))
	-- Built here, walked, and taken down again.
	local built = RainBiome.Build(scratch)
	local okBuilt, errBuilt = pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { built }
		-- The lane: walls, pillars and scenery stay out of it (the bridge's own
		-- descent lands at its first step, so the bridge is not in the sweep).
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Include
		overlap.FilterDescendantsInstances = { built:FindFirstChild("Terrain"), built:FindFirstChild("Scenery") }
		overlap.RespectCanCollide = true
		local line = RainBiome.Centreline(6)
		local holes, blocked = 0, 0
		for _, p in ipairs(line) do
			for _, u in ipairs({ 0, p.half - 2, -(p.half - 2) }) do
				local from = p.at + p.side * u + Vector3.new(0, 4, 0)
				if not Workspace:Raycast(from, Vector3.new(0, -8, 0), params) then
					holes += 1
				end
			end
			local mid = p.at + Vector3.new(0, 7, 0)
			local hits = Workspace:GetPartBoundsInBox(CFrame.lookAt(mid, mid + p.side), Vector3.new(6, 12, 56), overlap)
			if #hits > 0 then
				blocked += 1
			end
		end
		check(holes == 0, string.format("floor under every step down the middle of the route and along both edges (%d steps, %d holes)",
			#line, holes))
		check(blocked == 0, string.format("nothing solid in a 56-wide, 12-tall lane down the middle (%d of %d steps blocked)",
			blocked, #line))
		-- The scenery: never solid (but the nest's platform), never collectible,
		-- in four sections, and off the lane -- only puddles, runoff pools and
		-- the arches overhead come near the middle.
		local scenery = built:FindFirstChild("Scenery")
		local solid, sceneryParts, crowding, podTagged, crowded = {}, 0, 0, 0, {}
		-- Flat things and the arches overhead may come near the middle; the nest's
		-- own dressing is where the middle ends.
		local flat = { Puddle = true, Pond = true, Runoff = true, VineArch = true, NestDressing = true }
		for _, d in ipairs(scenery:GetDescendants()) do
			if d:IsA("BasePart") then
				sceneryParts += 1
				if d.CanCollide and d.Name ~= "NestPlatform" then
					table.insert(solid, d:GetFullName())
				end
				if CollectionService:HasTag(d, GameConfig.Tags.SeedPod) then
					podTagged += 1
				end
				if not flat[d.Parent.Name] and d.Name ~= "NestPlatform" then
					local nearest = math.huge
					for _, p in ipairs(line) do
						local dx, dz = d.Position.X - p.at.X, d.Position.Z - p.at.Z
						nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
					end
					if nearest < 30 then
						crowding += 1
						table.insert(crowded, string.format("%s/%s at (%.0f, %.0f), %.1f off", d.Parent.Parent.Name, d.Parent.Name,
							d.Position.X, d.Position.Z, nearest))
					end
				end
			end
		end
		check(#solid == 0 and podTagged == 0 and sceneryParts >= 600,
			string.format("%d parts of scenery: none solid but the nest's platform, none tagged as a pod", sceneryParts),
			table.concat(solid, ", "))
		check(crowding == 0, string.format("every plant, stone, root and reed stands at least 30 studs off the middle of the route "
			.. "(%d too close)", crowding), table.concat(crowded, "; "))
		local counts = {}
		for _, name in ipairs({ "Entrance", "Garden", "Passage", "Nest" }) do
			local f = scenery:FindFirstChild(name)
			counts[name] = f and #f:GetChildren() or 0
		end
		check(counts.Entrance >= 25 and counts.Garden >= 30 and counts.Passage >= 25 and counts.Nest >= 50,
			string.format("the four sections are dressed: entrance %d, garden %d, passage %d, nest clearing %d props",
				counts.Entrance, counts.Garden, counts.Passage, counts.Nest))
		-- The nest: a visible, empty, steppable platform at the clearing's
		-- CENTRE, the reserved site's marker at its own centre.
		local platform = scenery:FindFirstChild("NestPlatform", true)
		local site = built:FindFirstChild(B.EncounterSiteName, true)
		local nestAt = Vector3.new(B.Nest.X, GameConfig.Map.GroundY, B.Nest.Z)
		local clearing = B.Route[#B.Route]
		check(platform ~= nil and platform.CanCollide and math.abs(platform.Position.Y + platform.Size.X / 2 - (nestAt.Y + 1)) < 0.01
			and (platform.Position - nestAt).Magnitude < 1.01 and platform.Size.Y == B.Nest.Radius * 2
			and B.Nest.X == clearing.x and B.Nest.Z == clearing.z and B.Nest.ClearRing.Outer < clearing.r - 8,
			"the nest is a one-stud moss platform at the clearing's centre")
		check(site ~= nil and site:GetAttribute("Reserved") == true and site.Transparency == 1 and not site.CanCollide
			and (site.Position * Vector3.new(1, 0, 1) - nestAt * Vector3.new(1, 0, 1)).Magnitude < 0.01
			and CollectionService:HasTag(site, W.Tags.Site),
			"the EncounterSite marker stands at the nest's centre, reserved, invisible and tagged")
		-- The ring of floor round the nest, past its own foliage and short of
		-- the rim's dressing, holds nothing but puddles: the guardian's room.
		local ringCrowd = 0
		for _, d in ipairs(scenery:GetDescendants()) do
			if d:IsA("BasePart") and not flat[d.Parent.Name] and d.Name ~= "NestPlatform" then
				local dx, dz = d.Position.X - clearing.x, d.Position.Z - clearing.z
				local dist = math.sqrt(dx * dx + dz * dz)
				if dist > B.Nest.ClearRing.Inner and dist < B.Nest.ClearRing.Outer then
					ringCrowd += 1
				end
			end
		end
		check(ringCrowd == 0, string.format("the ring of floor round the nest, %d to %d studs out, is open ground for the guardian",
			B.Nest.ClearRing.Inner, B.Nest.ClearRing.Outer), ringCrowd)
		-- Everything fades and goes: every part tagged, the budget kept, nothing archivable.
		local untagged, total = 0, 0
		for _, d in ipairs(built:GetDescendants()) do
			if d:IsA("BasePart") then
				total += 1
				if not (CollectionService:HasTag(d, W.Tags.Terrain) or CollectionService:HasTag(d, W.Tags.Fog)
					or CollectionService:HasTag(d, W.Tags.Gate) or CollectionService:HasTag(d, W.Tags.Site)) then
					untagged += 1
				end
			end
		end
		check(untagged == 0 and total <= B.PartBudget and built.Archivable == false,
			string.format("all %d parts carry a fade tag, within the budget of %d, in a folder no save can carry", total, B.PartBudget))
		check(RainBiome.IsEntryOpen(built) == false and built.Gate.CanCollide, "and it is built with its entrance shut")
	end)
	built:Destroy()
	if not okBuilt then
		error(errBuilt)
	end

	--==========================================================================
	say("8. The weather's icon over the hotbar (2026-10-04; it was the chip)")
	--==========================================================================
	-- The "+25% INCOME · 2:59" chip became ONE icon in BoostIconsUI's row: the
	-- Rain's picture or the Thunderstorm's, the same +25%, the time left and what
	-- to do in its popover. The row's own placing is BoostIconsSpec's.
	local BoostIcons = require(Shared.BoostIcons)
	local function weather(state, mode)
		local list = BoostIcons.entries({ now = 100, rainState = state, rainMode = mode, rainStartedAt = 40,
			rainEndsAt = 220 })
		return list[1]
	end
	local pct = math.round((SeedData.Rain.IncomeFactor - 1) * 100)
	local opening, active, thunder, closing = weather("opening", "rain"), weather("active", "rain"),
		weather("active", "thunder"), weather("closing", "rain")
	check(opening ~= nil and active ~= nil and thunder ~= nil and closing == nil
			and active.id == "weather" and active.source == "rain" and thunder.source == "thunder"
			and thunder.title == "Thunderstorm" and active.title == "Rain"
			and string.find(active.effect, "+" .. pct .. "%", 1, true) ~= nil
			and active.effect == thunder.effect and active.total == 180 and active.endsAt == 220,
		"ONE weather icon while the rain pays (opening or open): the rain's picture or the thunder's, the same +"
			.. pct .. "%, its whole run for the ring; none while it closes")
	check(opening.hint ~= active.hint and string.find(active.hint, "open", 1, true) ~= nil,
		"its popover says whether the biome is about to open or open now")

	--==========================================================================
	say("9. Wiring")
	--==========================================================================
	local adminSrc = ""
	do
		local okRead, src = pcall(function()
			return Server.AdminService.Source
		end)
		adminSrc = if okRead and type(src) == "string" then src else ""
	end
	local handleAt = string.find(adminSrc, "function AdminService.Handle(", 1, true)
	local gateAt = handleAt and string.find(adminSrc, "if not AdminService.IsAdmin(sender) then", handleAt, true)
	check(gateAt ~= nil and string.find(adminSrc, 'if action == "Weather" then', gateAt, true) ~= nil
			and string.find(adminSrc, "Weather = true,", 1, true) ~= nil,
		"AdminService routes the Weather action after checking the sender is on the allowlist, on the server")
	local consoleSrc = sourceOf(Server.AdminService, "AdminConsoleUI")
	local consoleModelSrc = sourceOf(Server.AdminService, "ConsoleModel")
	-- Its WEATHER section in the WORLD tab (the 2026-10-07 redesign: Rain / Thunderstorm / Stop, each asked in
	-- place); what the buttons send is ConsoleModel's (AdminConsoleSpec).
	check(string.find(consoleSrc, '{ { "StartRain", "START RAIN" },\n\t\t{ "StartThunder", "THUNDERSTORM" }, { "EndRain", "STOP" } }',
				1, true) ~= nil
			and string.find(consoleSrc, "ui.rainBox.Text = tostring(WEATHER.DefaultSeconds)", 1, true) ~= nil
			and string.find(consoleSrc, "Model.args.weather(verb, if verb == \"end\" then nil else seconds(ui.rainBox))", 1, true) ~= nil
			and string.find(consoleModelSrc, 'return args("Weather", verb, seconds, nil)', 1, true) ~= nil
			and string.find(consoleSrc, 'ui.rainLabel, ui.rainDot = build.state(wCard, "Rain")', 1, true) ~= nil
			and string.find(consoleSrc, 'setAsking("weather", verb)', 1, true) ~= nil,
		"the console has a WEATHER section: START RAIN, THUNDERSTORM, STOP (each confirmed in place), an editable "
			.. "duration starting at the default, and the state line")
	check(W.DefaultSeconds == 180 and W.MinSeconds <= 20 and W.ToastDelaySeconds == 3,
		"180 s is the default, adjustable from 20 s; the toast comes 3 s in")
	local toastSrc = sourceOf(Scripts, "ActionToastUI")
	check(string.find(toastSrc, "action == GameConfig.Weather.Events.Opened", 1, true) ~= nil
			and string.find(toastSrc, 'key = "rain:" .. tostring(code)', 1, true) ~= nil
			and string.find(toastSrc, "GetAttributeChangedSignal(GameConfig.BoostIcons.Attribute):Connect(place)", 1, true) ~= nil,
		"ActionToastUI shows the opening toast once per event id and re-solves its line when the icon row changes")
	local clockSrc = sourceOf(Scripts, "WorldClock")
	check(string.find(clockSrc, "local kept = RAIN.Brightness + (RAIN.NightBrightness - RAIN.Brightness) * t", 1, true) ~= nil
			and string.find(clockSrc, "* (1 - (1 - kept) * r)", 1, true) ~= nil
			and string.find(clockSrc, "+ RAIN.Exposure * r", 1, true) ~= nil
			and string.find(clockSrc, "if changed then\n\t\tapplyLight(blend)", 1, true) ~= nil
			and count(clockSrc, "Lighting.Brightness = ") == 1,
		"WorldClock lays the rain's dimming over its own day/night blend: one owner of Lighting, nothing restored by hand")
	local weatherClient = sourceOf(Scripts, "Weather")
	check(weatherClient ~= "" and string.find(weatherClient, "StatusText.reducedMotion()", 1, true) ~= nil
			and string.find(weatherClient, "UserInputService.TouchEnabled", 1, true) ~= nil
			and string.find(weatherClient, "anchor.Parent = camera", 1, true) ~= nil,
		"the client's rain respects reduced motion, is lighter on a touch screen, and lives under the camera")
	check(Scripts:FindFirstChild("WeatherUI") == nil,
		"the chip's own script is gone: the weather is an icon in BoostIconsUI's row")

	--==========================================================================
	say("10. The white clouds, the overcast sky and the rain everywhere")
	--==========================================================================
	local RainClouds = require(Shared.RainClouds)
	local CL = W.Clouds
	local MAPC = GameConfig.Map
	local banksList = RainClouds.banks()
	local sides, zones = {}, {}
	local insideIsland, onRoad, onLanding, inMouth, low = 0, 0, 0, 0, 0
	local halfW = MAPC.FieldWidth / 2
	local landing = { x0 = B.Landing.X - (B.Landing.Rows - 1) * B.Landing.Spread - 6, x1 = B.Landing.X + 6,
		z0 = B.Landing.Z - (B.Landing.Columns - 1) / 2 * B.Landing.Spread - 6,
		z1 = B.Landing.Z + (B.Landing.Columns - 1) / 2 * B.Landing.Spread + 6 }
	for _, bk in ipairs(banksList) do
		sides[bk.name] = (sides[bk.name] or 0) + 1
		zones[bk.zone] = (zones[bk.zone] or 0) + 1
		local x, z = bk.at.X, bk.at.Z
		if math.abs(x) < halfW - 4 and z > -MAPC.FieldFront + 4 and z < MAPC.FieldBack - 4 then
			insideIsland += 1
		end
		if z < -MAPC.FieldFront and math.abs(x) < MAPC.CorridorWidth / 2 + MAPC.WallThickness then
			onRoad += 1
		end
		if x > landing.x0 and x < landing.x1 and z > landing.z0 and z < landing.z1 then
			onLanding += 1
		end
		if bk.name == "South" and math.abs(x) < MAPC.CorridorWidth / 2 + 24 then
			inMouth += 1
		end
		if bk.zone == "biome" and bk.at.Y < MAPC.GroundY + B.WallHeight + 4 then
			low += 1
		end
	end
	check((sides.North or 0) >= 5 and (sides.South or 0) >= 4 and (sides.East or 0) >= 5 and (sides.West or 0) >= 5
		and (zones.road or 0) >= 10 and (zones.biome or 0) >= 8 and (zones.entrance or 0) >= 1,
		string.format("banks on every side of the island (N %d, S %d, E %d, W %d), down the road (%d), along the biome (%d) "
			.. "and at the entrance (%d)", sides.North or 0, sides.South or 0, sides.East or 0, sides.West or 0,
			zones.road or 0, zones.biome or 0, zones.entrance or 0))
	check(insideIsland == 0 and onRoad == 0 and onLanding == 0 and inMouth == 0 and low == 0,
		string.format("none over the island, the road, the landing grid or the road's mouth, and the biome's all above its walls "
			.. "(%d/%d/%d/%d/%d)", insideIsland, onRoad, onLanding, inMouth, low))
	local badPuffs, loose = 0, 0
	for _, bk in ipairs(banksList) do
		if #bk.puffs < CL.Puffs.Min + 1 or #bk.puffs > CL.Puffs.Max + 2 then
			badPuffs += 1
		end
		for i, p in ipairs(bk.puffs) do
			if p.diameter < 6 or p.diameter > 44 then
				badPuffs += 1
			end
			local touching = false
			for j, q in ipairs(bk.puffs) do
				if i ~= j and (p.offset - q.offset).Magnitude < (p.diameter + q.diameter) / 2 then
					touching = true
					break
				end
			end
			if not touching then
				loose += 1
			end
		end
	end
	check(badPuffs == 0 and loose == 0, string.format("%d banks of 6-9 balls each, 6-44 studs across, every ball overlapping "
		.. "another (%d odd, %d loose)", #banksList, badPuffs, loose))
	check(RainClouds.count() <= CL.PartBudget, string.format("%d balls on a client, within %d", RainClouds.count(), CL.PartBudget))
	local o0 = RainClouds.targets("opening", 0)
	local o1 = RainClouds.targets("opening", W.ToastDelaySeconds)
	local a0 = RainClouds.targets("active", 0)
	local a1 = RainClouds.targets("active", CL.EmergeSeconds)
	local c1 = RainClouds.targets("closing", W.ThickenSeconds)
	local c2 = RainClouds.targets("closing", W.ThickenSeconds + W.FadeSeconds)
	local none = RainClouds.targets(nil, 0)
	check(o0.biome <= 0.2 and o0.entrance <= 0.35 and o0.perimeter == CL.Perimeter and o1.entrance >= 0.75 and o1.biome <= 0.2,
		"while it opens the biome is hidden in cloud and the entrance clears before the gate lifts")
	check(a0.biome <= 0.2 and a1.biome == CL.Biome and a1.entrance == CL.Entrance,
		"once open the biome emerges from the cloud over EmergeSeconds")
	check(math.abs(c1.biome - CL.Thick) < 1e-6 and c1.perimeter == CL.Perimeter and c1.gone == 0,
		"closing: the cloud thickens over the biome, nowhere else, before anything fades")
	check(c2.biome == 1 and c2.perimeter == 1 and c2.road == 1 and c2.entrance == 1 and c2.gone == 1
		and none.perimeter == 1 and none.gone == 0,
		"then the biome and every cloud fade away together, and with no rain there is nothing")
	local dayLook, nightLook = RainClouds.look(false), RainClouds.look(true)
	local function lum(c)
		return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
	end
	check(dayLook.Material == Enum.Material.SmoothPlastic and nightLook.Material == Enum.Material.Neon
		and lum(nightLook.Color) < lum(dayLook.Color) and lum(nightLook.Color) > 0.3,
		"clouds are lit white plastic by day and a dim self-lit grey by night: readable, not glaring")
	local weatherSrc = sourceOf(Scripts, "Weather")
	check(string.find(weatherSrc, 'require(Shared:WaitForChild("RainClouds"))', 1, true) ~= nil
			and string.find(weatherSrc, 'folder.Name = "SeedRainClouds"', 1, true) ~= nil
			and string.find(weatherSrc, "if not still then", 1, true) ~= nil
			and string.find(weatherSrc, 'streaks(farAnchor, "RainFar"', 1, true) ~= nil
			and string.find(weatherSrc, "far = rates.FarRate * level", 1, true) ~= nil
			and string.find(weatherSrc, "if raining(Workspace:GetAttribute(ATTR.State)) then\n\tlevel = 1", 1, true) ~= nil,
		"Weather.client builds the clouds from RainClouds, bobs them only with motion on, rains near and far, and starts at full "
			.. "for a late joiner")
	local clockSrc2 = sourceOf(Scripts, "WorldClock")
	check(string.find(clockSrc2, "Lighting.ShadowSoftness = baseShadow", 1, true) ~= nil
			and string.find(clockSrc2, 'Instance.new("ColorCorrectionEffect")', 1, true) ~= nil
			and string.find(clockSrc2, 'Instance.new("Clouds")', 1, true) ~= nil
			and string.find(clockSrc2, "RAIN.Ambient:Lerp(RAIN.NightAmbient, t)", 1, true) ~= nil
			and string.find(clockSrc2, "else RAIN.FadeOutSeconds", 1, true) ~= nil
			and string.find(clockSrc2, 'rain = if state == "opening" or state == "active" then 1 else 0', 1, true) ~= nil
			and count(clockSrc2, "Lighting.Brightness = ") == 1,
		"WorldClock alone composes the overcast look -- shadows, tone, the sky's clouds, a night pair -- fades it out with the "
			.. "clouds, and starts at full for a late joiner")
	check(W.Light.FadeOutSeconds == W.ThickenSeconds + W.FadeSeconds, "the light goes as the clouds and the biome go")
	check(string.find(sourceOf(Server, "RainBiome"), "buildFog", 1, true) == nil, "the server builds no fog any more")
	check(GameConfig.Secret.Enabled == false, "natural Secret spawning is still switched off")
	check(Workspace:FindFirstChild(B.FolderName) == nil, "no event terrain is left in the workspace")
end)

plots.PlotOf, plots.OwnerOf, plants.GrownIn = real.PlotOf, real.OwnerOf, real.GrownIn
passes.CashMultiplier, chest.Multiplier, sacrifice.Multiplier = real.CashMultiplier, real.Chest, real.Sacrifice
AdminService.Config.MinInterval = realInterval
WeatherService.useClock(nil)
WeatherService.usePlayers(nil)
WeatherService.useTerrain(nil)
WeatherService.useBroadcast(nil)
WeatherService.useMover(nil)
WeatherService.Init()
scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("RainEventSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
